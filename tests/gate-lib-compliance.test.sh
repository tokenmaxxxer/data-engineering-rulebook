#!/usr/bin/env bash
# gate-house standard compliance cases (issue-72's compliance-check.sh,
# tokenmaxxxer-core main). Runs the core detector against each gate's own
# hooks/ directory and asserts a clean pass — machine evidence that no
# gate hand-rolls a kill-switch case statement or an Edit/MultiEdit
# .replace(...) call instead of calling through gate-lib. Sourced by
# run-gate-tests.sh, which has already fetched gate-lib.sh/gate-lib.py
# into CLAUDE_PLUGIN_ROOT_CORE — this file fetches the sibling
# compliance-check.sh into the same cache.
#
# Core resolving (env var or sibling checkout, per
# docs/specs/test-env-resolution.md, issue #551 / #22) does not imply
# network reachability: compliance-check.sh has no sibling-checkout
# candidate of its own here, only a network fetch. When that fetch fails,
# this file's own cases are unverifiable outside the spawn env — SKIP,
# not FAIL (warrant hunt before-landing stance 4,
# docs/reports/2026-08-09-hunt-test-env-resolution.md). This file is
# `source`d into run-gate-tests.sh's shell alongside every other
# *.test.sh file, so an `exit` here would terminate the whole runner —
# discarding PASS/FAIL already accumulated by earlier files and skipping
# every file still to come (warrant hunt before-landing stance 3, same
# record). `return` instead, so only this file's 3 compliance cases are
# skipped and every other *.test.sh file still runs and reports for
# real.
COMPLIANCE_CHECK_CACHE="$ROOT_DIR/.muster-cache/core-lib/hooks/tests/compliance-check.sh"
mkdir -p "$(dirname "$COMPLIANCE_CHECK_CACHE")"
if [ ! -s "$COMPLIANCE_CHECK_CACHE" ]; then
  curl -fsS \
    "https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/core/hooks/tests/compliance-check.sh" \
    -o "$COMPLIANCE_CHECK_CACHE" || {
    echo "SKIP: compliance-check.sh unreachable — unverifiable outside spawn env" >&2
    SKIPPED=$((SKIPPED + 3))
    return 0
  }
  chmod +x "$COMPLIANCE_CHECK_CACHE"
fi

assert_compliance() {
  local hooks_dir="$1"
  if "$COMPLIANCE_CHECK_CACHE" "$hooks_dir" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: compliance-check.sh flagged $hooks_dir"
    "$COMPLIANCE_CHECK_CACHE" "$hooks_dir" >&2
  fi
}

assert_compliance "$ROOT_DIR/pipeline-design-gate/hooks"
assert_compliance "$ROOT_DIR/data-quality-gate/hooks"
assert_compliance "$ROOT_DIR/failure-handling-gate/hooks"
