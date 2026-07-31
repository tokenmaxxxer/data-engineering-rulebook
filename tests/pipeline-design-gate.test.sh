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
