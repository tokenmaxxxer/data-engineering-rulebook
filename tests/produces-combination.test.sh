#!/usr/bin/env bash
# produces-combination cases: the three independent plugins run together
# against the same write, per proposal section 2.2's dispatch. Sourced by
# run-gate-tests.sh (reuses its assert_gate helper and HOOKS_DIR/PASS/FAIL).

# Section labels use the canonical PRODUCES sub-field names directive.sh
# establishes ("pipeline design", "data-quality check list",
# "failure-handling plan") so each gate's section-slice scoping (issue-13
# defect #3 fix) sees a labeled section instead of falling through to
# whole-document matching.
GOOD_CONTENT="Pipeline design: source -> transform -> sink. Owner: data-eng team. Change-control: reviewed on every schema bump, stays current via PR review.
Data-quality check list: schema has columns id (int), ts (timestamp). Completeness threshold: 99.5%. Enforced at the ingest check stage.
Failure-handling plan: failure mode upstream source outage. First-check: latency dashboard. Escalation: page on-call. Recovery: rollback to last good snapshot. Recovery-time target: 30 minutes."

ONE_MISSING_CONTENT="Pipeline design: source -> transform -> sink. Owner: data-eng team. Change-control: reviewed on every schema bump, stays current via PR review.
Data-quality check list: data should be good quality, no specific numbers given.
Failure-handling plan: failure mode upstream source outage. First-check: latency dashboard. Escalation: page on-call. Recovery: rollback to last good snapshot. Recovery-time target: 30 minutes."

# out-of-scope path: none of the three plugins fire, all allow
assert_gate "pipeline-design-gate.sh" 0 "src/unrelated.py" "no methodology content at all here"
assert_gate "data-quality-gate.sh" 0 "src/unrelated.py" "no methodology content at all here"
assert_gate "failure-handling-gate.sh" 0 "src/unrelated.py" "no methodology content at all here"

# phase-1 proposal write: all three pass
assert_gate "pipeline-design-gate.sh" 0 "docs/issue-10/proposals/data-engineering-x.md" "$GOOD_CONTENT"
assert_gate "data-quality-gate.sh" 0 "docs/issue-10/proposals/data-engineering-x.md" "$GOOD_CONTENT"
assert_gate "failure-handling-gate.sh" 0 "docs/issue-10/proposals/data-engineering-x.md" "$GOOD_CONTENT"

# phase-1 proposal write: exactly one plugin (data-quality-gate) denies
assert_gate "pipeline-design-gate.sh" 0 "docs/issue-10/proposals/data-engineering-x.md" "$ONE_MISSING_CONTENT"
assert_gate "data-quality-gate.sh" 2 "docs/issue-10/proposals/data-engineering-x.md" "$ONE_MISSING_CONTENT"
assert_gate "failure-handling-gate.sh" 0 "docs/issue-10/proposals/data-engineering-x.md" "$ONE_MISSING_CONTENT"

# phase-2 record write: same allow/deny pair
assert_gate "pipeline-design-gate.sh" 0 "docs/issue-10/reports/data-engineering.md" "$GOOD_CONTENT"
assert_gate "data-quality-gate.sh" 0 "docs/issue-10/reports/data-engineering.md" "$GOOD_CONTENT"
assert_gate "failure-handling-gate.sh" 0 "docs/issue-10/reports/data-engineering.md" "$GOOD_CONTENT"

assert_gate "pipeline-design-gate.sh" 0 "docs/issue-10/reports/data-engineering.md" "$ONE_MISSING_CONTENT"
assert_gate "data-quality-gate.sh" 2 "docs/issue-10/reports/data-engineering.md" "$ONE_MISSING_CONTENT"
assert_gate "failure-handling-gate.sh" 0 "docs/issue-10/reports/data-engineering.md" "$ONE_MISSING_CONTENT"
