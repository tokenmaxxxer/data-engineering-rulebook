#!/usr/bin/env bash
# data-quality-gate.sh cases. Sourced by run-gate-tests.sh.

assert_gate "data-quality-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Schema: columns id (int), ts (timestamp). Completeness threshold: 99.5%. Enforced at the ingest check stage."

assert_gate "data-quality-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Data should be good quality, no specific numbers given."

assert_gate "data-quality-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Data-quality check list: N/A, scope is a single non-breaking field add."

assert_gate "data-quality-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Data-quality check list: N/A"

# --- issue-13 mandatory cases (Edit/MultiEdit/replace_all/malformed-JSON/kill-switch/absolute-path) ---

# ./-prefixed relative path still matches (defect #1, dot-segment leg)
assert_gate "data-quality-gate.sh" 2 \
  "./docs/issue-10/proposals/data-engineering-thing.md" \
  "Data should be good quality, no specific numbers given."

# absolute path anchors identically to the relative-path fixture above (defect #1)
assert_gate_abs "data-quality-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Data should be good quality, no specific numbers given."

# Edit, replace_all — the load-bearing placeholder (the one adjacent to
# "percent") sits second in the document; .replace(old, new, 1) fixes only
# the FIRST (irrelevant, schema-section) occurrence, so replace_all: false
# must still deny while replace_all: true allows (proves every occurrence
# is honored, not just the first — the issue-72-confirmed replace_all bug).
DQ_SEED="Schema: PLACEHOLDER columns id int ts timestamp. More filler text here to add distance so the placeholder is far from any percent sign padding padding padding padding padding. Completeness threshold PLACEHOLDER percent. Enforced at the ingest check stage."
assert_gate_tool "data-quality-gate.sh" 0 "Edit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","old_string":"PLACEHOLDER","new_string":"99.5","replace_all":true}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$DQ_SEED"

assert_gate_tool "data-quality-gate.sh" 2 "Edit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","old_string":"PLACEHOLDER","new_string":"99.5","replace_all":false}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$DQ_SEED"

# MultiEdit, mixed replace_all true/false edits in one call
DQ_MULTI_SEED="Data-quality check list: SCHEMAPLACE. THRESHOLDPLACE THRESHOLDPLACE ENFORCEPLACE."
assert_gate_tool "data-quality-gate.sh" 0 "MultiEdit" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","edits":[{"old_string":"SCHEMAPLACE","new_string":"schema columns id (int)","replace_all":false},{"old_string":"THRESHOLDPLACE","new_string":"completeness 99%","replace_all":true},{"old_string":"ENFORCEPLACE","new_string":"enforced at ingest check stage","replace_all":false}]}' \
  "docs/issue-10/proposals/data-engineering-thing.md" "$DQ_MULTI_SEED"

# Malformed JSON: truncated, non-object, and empty stdin all deny
assert_gate_raw "data-quality-gate.sh" 2 '{"tool_name": "Write", "tool_in'
assert_gate_raw "data-quality-gate.sh" 2 '"just a string"'
assert_gate_raw "data-quality-gate.sh" 2 ''

# Kill switch: unrecognized value stays ACTIVE (fail-closed); a recognized
# on-spelling disables the gate.
export DATA_ENGINEERING_DATA_QUALITY_GATE_OFF="maybe"
assert_gate "data-quality-gate.sh" 2 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Data should be good quality, no specific numbers given."
export DATA_ENGINEERING_DATA_QUALITY_GATE_OFF="true"
assert_gate "data-quality-gate.sh" 0 \
  "docs/issue-10/proposals/data-engineering-thing.md" \
  "Data should be good quality, no specific numbers given."
unset DATA_ENGINEERING_DATA_QUALITY_GATE_OFF
