#!/usr/bin/env bash
# Shared subprocess-harness runner for the data-engineering gate plugins.
# Sets up a synthetic git worktree, feeds synthetic tool-call JSON on
# stdin to a gate script, and asserts the exit code.
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# Each gate now lives in its own independent plugin (issue #10 FEEDBACK:
# plugin-set restructure, not a single fused data-engineering script).
script_path() {
  case "$1" in
    pipeline-design-gate.sh) echo "$ROOT_DIR/pipeline-design-gate/hooks/$1" ;;
    data-quality-gate.sh) echo "$ROOT_DIR/data-quality-gate/hooks/$1" ;;
    failure-handling-gate.sh) echo "$ROOT_DIR/failure-handling-gate/hooks/$1" ;;
    *) echo "unknown gate script: $1" >&2; exit 1 ;;
  esac
}

# Resolve core's plugin root per the canonical test-env resolution
# convention (docs/specs/test-env-resolution.md, issue #551, adopted here
# per issue #22): try $CLAUDE_PLUGIN_ROOT_CORE, then sibling-checkout
# candidates, via the vendored reference resolver. Only if that reports
# SKIP do we fall back to the network-fetch cache below (a repo-local
# extension the convention permits, never a substitute for it) — and if
# the network fetch also fails, the whole run SKIPs (exit 75) instead of
# FAILing, per the convention's SKIP contract.
CORE_LIB_CACHE="$ROOT_DIR/.muster-cache/core-lib"
EX_TEMPFAIL=75
SKIP_MESSAGE="SKIP: core plugin unreachable — unverifiable outside spawn env"

resolve_core_via_module() {
  python3 "$ROOT_DIR/tests/lib/test_env_resolve.py" \
    "$CORE_LIB_CACHE" \
    "$ROOT_DIR/../core" \
    "$ROOT_DIR/../tokenmaxxxer-core/core"
}

fetch_core_lib_over_network() {
  mkdir -p "$CORE_LIB_CACHE/hooks/lib"
  local base="https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/core/hooks/lib"
  for f in gate-lib.sh gate-lib.py; do
    if [ ! -s "$CORE_LIB_CACHE/hooks/lib/$f" ]; then
      curl -fsS "$base/$f" -o "$CORE_LIB_CACHE/hooks/lib/$f" || return 1
    fi
  done
  chmod +x "$CORE_LIB_CACHE/hooks/lib/gate-lib.sh"
  return 0
}

setup_core_lib() {
  local resolved
  if resolved="$(resolve_core_via_module)"; then
    CLAUDE_PLUGIN_ROOT_CORE="$resolved"
    return 0
  fi
  if fetch_core_lib_over_network; then
    CLAUDE_PLUGIN_ROOT_CORE="$CORE_LIB_CACHE"
    return 0
  fi
  echo "$SKIP_MESSAGE" >&2
  exit "$EX_TEMPFAIL"
}
setup_core_lib
export CLAUDE_PLUGIN_ROOT_CORE

PASS=0
FAIL=0
SKIPPED=0

# assert_gate <script> <expect_code> <file_path> <content>
# Write-tool convenience wrapper, kept for existing per-gate cases.
assert_gate() {
  local script="$1" expect="$2" file_path="$3" content="$4"
  local tool_input
  tool_input="$(python3 -c '
import json, sys
print(json.dumps({"file_path": sys.argv[1], "content": sys.argv[2]}))
' "$file_path" "$content")"
  assert_gate_tool "$script" "$expect" "Write" "$tool_input"
}

# assert_gate_tool <script> <expect_code> <tool_name> <tool_input_json> [seed_rel_path] [seed_content] [extra_env]
# General harness: optionally seeds a file (for Edit/MultiEdit fixtures)
# at a path relative to the synthetic cwd before invoking the gate, then
# feeds the given tool_name/tool_input as the PreToolUse payload.
# `tool_input_json` may contain the literal token {TMP}, substituted with
# the synthetic cwd's absolute path at run time — used by absolute-path
# fixtures, whose file_path must be an absolute path under that cwd.
# `extra_env` (optional), if non-empty, is passed as one "NAME=value" pair
# to `env` around the gate invocation — used by kill-switch cases.
assert_gate_tool() {
  local script="$1" expect="$2" tool_name="$3" tool_input="$4"
  local seed_rel="${5:-}" seed_content="${6:-}" extra_env="${7:-}"
  local tmp
  tmp="$(mktemp -d)"
  if [ -n "$seed_rel" ]; then
    mkdir -p "$tmp/$(dirname "$seed_rel")"
    printf '%s' "$seed_content" > "$tmp/$seed_rel"
  fi
  local resolved_tool_input="${tool_input//\{TMP\}/$tmp}"
  local payload
  payload="$(python3 -c '
import json, sys
print(json.dumps({"tool_name": sys.argv[1], "tool_input": json.loads(sys.argv[2])}))
' "$tool_name" "$resolved_tool_input")"
  local actual
  if [ -n "$extra_env" ]; then
    echo "$payload" | (cd "$tmp" && env "$extra_env" "$(script_path "$script")") >/dev/null 2>&1
  else
    echo "$payload" | (cd "$tmp" && "$(script_path "$script")") >/dev/null 2>&1
  fi
  actual=$?
  rm -rf "$tmp"
  if [ "$actual" -eq "$expect" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $script expected exit $expect, got $actual (tool=$tool_name)"
  fi
}

# assert_gate_raw <script> <expect_code> <raw_stdin>
# Lowest-level harness for malformed-payload cases (non-JSON, empty, etc.)
# that cannot be expressed as a well-formed tool_name/tool_input pair.
assert_gate_raw() {
  local script="$1" expect="$2" raw="$3"
  local tmp
  tmp="$(mktemp -d)"
  local actual
  printf '%s' "$raw" | (cd "$tmp" && "$(script_path "$script")") >/dev/null 2>&1
  actual=$?
  rm -rf "$tmp"
  if [ "$actual" -eq "$expect" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $script expected exit $expect, got $actual (raw payload)"
  fi
}

# assert_gate_abs <script> <expect_code> <rel_path> <content> [prefix]
# Absolute-path (defect #1) harness: writes to a file_path that is the
# synthetic cwd's absolute path joined with rel_path (optionally prefixed
# with "./" first, to also cover the ./-prefix bypass), instead of the
# bare relative path assert_gate uses.
assert_gate_abs() {
  local script="$1" expect="$2" rel_path="$3" content="$4" prefix="${5:-}"
  local tmp
  tmp="$(mktemp -d)"
  local abs_path="$tmp/${prefix}${rel_path}"
  local tool_input
  tool_input="$(python3 -c '
import json, sys
print(json.dumps({"file_path": sys.argv[1], "content": sys.argv[2]}))
' "$abs_path" "$content")"
  local payload
  payload="$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": json.loads(sys.argv[1])}))
' "$tool_input")"
  local actual
  echo "$payload" | (cd "$tmp" && "$(script_path "$script")") >/dev/null 2>&1
  actual=$?
  rm -rf "$tmp"
  if [ "$actual" -eq "$expect" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $script expected exit $expect, got $actual (absolute path $rel_path)"
  fi
}

for f in "$ROOT_DIR"/tests/*.test.sh; do
  # shellcheck source=/dev/null
  source "$f"
done

if [ "$SKIPPED" -gt 0 ]; then
  echo "gate tests: $PASS passed, $FAIL failed, $SKIPPED skipped (unverifiable outside spawn env)"
else
  echo "gate tests: $PASS passed, $FAIL failed"
fi
[ "$FAIL" -eq 0 ]
