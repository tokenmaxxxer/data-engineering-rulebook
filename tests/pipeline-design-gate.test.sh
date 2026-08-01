#!/usr/bin/env bash
# pipeline-design-gate.sh cases. Sourced by run-gate-tests.sh.

assert_gate "pipeline-design-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Pipeline design: source -> transform -> sink. Owner: data-eng team. Change-control: reviewed on every schema bump, stays current via PR review."

assert_gate "pipeline-design-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Pipeline design: source -> transform -> sink. No ownership or update process mentioned."

assert_gate "pipeline-design-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Pipeline design: N/A, scope is a single non-breaking field add."

assert_gate "pipeline-design-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Pipeline design: N/A"

# --- issue-13 mandatory cases (Edit/MultiEdit/replace_all/malformed-JSON/kill-switch/absolute-path) ---

# ./-prefixed relative path still matches (defect #1, dot-segment leg)
assert_gate "pipeline-design-gate.sh" 2 \
  "./docs/issue-10/proposals/data-engineering-thing.md" \
  "Pipeline design: source -> transform -> sink. No ownership or update process mentioned."

# absolute path anchors identically to the relative-path fixture above (defect #1)
assert_gate_abs "pipeline-design-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Pipeline design: source -> transform -> sink. No ownership or update process mentioned."

# Edit, replace_all: true — both placeholders become "source", pushing
# FLOW_RE's match count to >= 2; replace_all: false leaves only one
# replaced and the gate still denies (proves every occurrence is honored,
# not just the first — the issue-72-confirmed replace_all bug).
PD_SEED="Pipeline design: FLOWWORD -> FLOWWORD. Owner: data-eng team. Change-control: reviewed regularly."
assert_gate_tool "pipeline-design-gate.sh" 0 "Edit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","old_string":"FLOWWORD","new_string":"source","replace_all":true}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$PD_SEED"

assert_gate_tool "pipeline-design-gate.sh" 2 "Edit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","old_string":"FLOWWORD","new_string":"source","replace_all":false}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$PD_SEED"

# MultiEdit, mixed replace_all true/false edits in one call
PD_MULTI_SEED="Pipeline design: source -> transform -> sink. OWNERPLACE. CHANGEPLACE CHANGEPLACE."
assert_gate_tool "pipeline-design-gate.sh" 0 "MultiEdit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","edits":[{"old_string":"OWNERPLACE","new_string":"Owner: data-eng team.","replace_all":false},{"old_string":"CHANGEPLACE","new_string":"change-control","replace_all":true}]}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$PD_MULTI_SEED"

# Malformed JSON: truncated, non-object, and empty stdin all deny
assert_gate_raw "pipeline-design-gate.sh" 2 '{"tool_name": "Write", "tool_in'
assert_gate_raw "pipeline-design-gate.sh" 2 '"just a string"'
assert_gate_raw "pipeline-design-gate.sh" 2 ''

# Kill switch: unrecognized value stays ACTIVE (fail-closed); a recognized
# on-spelling disables the gate.
export DATA_ENGINEERING_PIPELINE_DESIGN_GATE_OFF="maybe"
assert_gate "pipeline-design-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Pipeline design: source -> transform -> sink. No ownership or update process mentioned."
export DATA_ENGINEERING_PIPELINE_DESIGN_GATE_OFF="true"
assert_gate "pipeline-design-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Pipeline design: source -> transform -> sink. No ownership or update process mentioned."
unset DATA_ENGINEERING_PIPELINE_DESIGN_GATE_OFF
