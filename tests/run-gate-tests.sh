#!/usr/bin/env bash
# Shared subprocess-harness runner for the data-engineering gate plugins.
# Sets up a synthetic git worktree, feeds synthetic Write/Edit tool-call JSON
# on stdin to a gate script, and asserts the exit code.
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOOKS_DIR="$ROOT_DIR/data-engineering/hooks"

PASS=0
FAIL=0

# assert_gate <script> <expect_code> <file_path> <content>
assert_gate() {
  local script="$1" expect="$2" file_path="$3" content="$4"
  local tmp
  tmp="$(mktemp -d)"
  local payload
  payload="$(python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]},
}))
' "$file_path" "$content")"
  local actual
  echo "$payload" | (cd "$tmp" && "$HOOKS_DIR/$script") >/dev/null 2>&1
  actual=$?
  rm -rf "$tmp"
  if [ "$actual" -eq "$expect" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $script expected exit $expect, got $actual for $file_path"
  fi
}

for f in "$ROOT_DIR"/tests/*.test.sh; do
  # shellcheck source=/dev/null
  source "$f"
done

echo "gate tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
