#!/usr/bin/env bash
# failure-handling-gate.sh cases. Sourced by run-gate-tests.sh.

assert_gate "failure-handling-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Failure mode: upstream source outage. First-check: latency dashboard. Escalation: page on-call. Recovery: rollback to last good snapshot. Recovery-time target: 30 minutes."

assert_gate "failure-handling-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "If something breaks we will fix it."

assert_gate "failure-handling-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Failure-handling plan: N/A, scope is a single non-breaking field add."

assert_gate "failure-handling-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Failure-handling plan: N/A"

# --- issue-13 mandatory cases (Edit/MultiEdit/replace_all/malformed-JSON/kill-switch/absolute-path) ---

# ./-prefixed relative path still matches (defect #1, dot-segment leg)
assert_gate "failure-handling-gate.sh" 2 \
  "./docs/issue-10/proposals/data-engineering-thing.md" \
  "If something breaks we will fix it."

# absolute path anchors identically to the relative-path fixture above (defect #1)
assert_gate_abs "failure-handling-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "If something breaks we will fix it."

# Edit, replace_all — "30 minutes" (the only recovery-time-target source)
# occurs twice; replace_all: true must remove BOTH (denies, the target is
# gone), while replace_all: false removes only the first, leaving the
# second intact (still allows) — proves the flag actually governs how
# many occurrences are touched, not just whether any are.
FH_SEED="Failure mode: upstream source outage. First-check: latency dashboard. Escalation: page on-call. Recovery: rollback to last good snapshot within 30 minutes typically, restored fully in about 30 minutes."
assert_gate_tool "failure-handling-gate.sh" 2 "Edit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","old_string":"30 minutes","new_string":"soon","replace_all":true}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$FH_SEED"

assert_gate_tool "failure-handling-gate.sh" 0 "Edit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","old_string":"30 minutes","new_string":"soon","replace_all":false}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$FH_SEED"

# MultiEdit, mixed replace_all true/false edits in one call
FH_MULTI_SEED="Failure mode: MODEPLACE. DIAGPLACE. Recovery-time target: TARGETPLACE."
assert_gate_tool "failure-handling-gate.sh" 0 "MultiEdit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","edits":[{"old_string":"MODEPLACE","new_string":"upstream source outage","replace_all":false},{"old_string":"DIAGPLACE","new_string":"first-check latency dashboard, escalation page on-call, recovery rollback","replace_all":true},{"old_string":"TARGETPLACE","new_string":"30 minutes","replace_all":false}]}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$FH_MULTI_SEED"

# Malformed JSON: truncated, non-object, and empty stdin all deny
assert_gate_raw "failure-handling-gate.sh" 2 '{"tool_name": "Write", "tool_in'
assert_gate_raw "failure-handling-gate.sh" 2 '"just a string"'
assert_gate_raw "failure-handling-gate.sh" 2 ''

# Kill switch: unrecognized value stays ACTIVE (fail-closed); a recognized
# on-spelling disables the gate.
export DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF="maybe"
assert_gate "failure-handling-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "If something breaks we will fix it."
export DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF="true"
assert_gate "failure-handling-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "If something breaks we will fix it."
unset DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF
