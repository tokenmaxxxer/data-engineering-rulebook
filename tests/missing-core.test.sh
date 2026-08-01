#!/usr/bin/env bash
# Missing-core mandatory cases (issue #16 requirement 3, per core issue #75's
# source-guard mandate): point CLAUDE_PLUGIN_ROOT_CORE at a directory with no
# gate-lib.sh so each gate's `. "..." || { ... exit 2; }` guard fires and the
# gate denies (fail-closed) instead of crashing open. Sourced by
# run-gate-tests.sh, one case per gate.

MISSING_CORE_DIR="$ROOT_DIR/.muster-cache/missing-core"
rm -rf "$MISSING_CORE_DIR"

assert_gate_tool "pipeline-design-gate.sh" 2 "Write" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","content":"Pipeline design: source -> transform -> sink."}' \
  "" "" "CLAUDE_PLUGIN_ROOT_CORE=$MISSING_CORE_DIR"

assert_gate_tool "data-quality-gate.sh" 2 "Write" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","content":"Data-quality check list: schema + 99% completeness, enforced at ingest."}' \
  "" "" "CLAUDE_PLUGIN_ROOT_CORE=$MISSING_CORE_DIR"

assert_gate_tool "failure-handling-gate.sh" 2 "Write" \
  '{"file_path":"docs/issue-10/proposals/data-engineering-thing.md","content":"Failure-handling plan: ingest timeout, diagnose via logs, escalate to on-call, recover in 30 minutes."}' \
  "" "" "CLAUDE_PLUGIN_ROOT_CORE=$MISSING_CORE_DIR"
