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
