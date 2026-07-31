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
