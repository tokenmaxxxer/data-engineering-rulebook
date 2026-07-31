---
subject: issue-10
role: data-engineering
---

# Scout brief

Mode: sequential local-file read (not web search, not parallel fan-out) — the
comparable "field" for this deliverable is not an external market but the
sibling rulebooks in this same tokenmaxxxer ecosystem that already built the
exact artifact this issue asks for (a methodology-enforcing hook machine). The
issue itself names one exemplar (`pricing-rulebook`'s `methodology-gate.sh`);
one sweep angle (grep the other landed rulebooks for `*-gate.sh` / `tests/`)
was enough to find both exemplar shapes and the test harness in one round — a
second, parallel round would not change which shape to adopt. Stopped at 1
stage after judge point 1.

## Must-bes across the two exemplar gate shapes found
- Single-shot content gate (pricing): resolve write target → restrict to the
  role's own proposal/record path regex → reconstruct resulting file content
  for Write/Edit/MultiEdit → heuristic keyword/regex check per required
  element → deny naming exactly which element(s) are missing → fail-closed
  (trap + try/except) on anything unparseable.
- Stateful gate (coding): reserved only for constraints a single write's
  content cannot decide alone (cross-file / cross-session state); paired with
  a small state-maintenance script keyed to lifecycle hooks (SessionStart /
  SubagentStop), not invented ad hoc.
- Repo-root test harness (implementation-rulebook): spawns the gate as a real
  subprocess against a synthetic git worktree + synthetic tool-call JSON,
  asserts exit code (0=allow, 2=deny) per case — never mocks the gate's own
  logic.

## Adopt / skip for this issue
- Adopt: pricing's single-shot content-gate shape for all three data-engineering
  sub-fields — issue-1's scout already found the three fields have no build-
  order dependency (schema/thresholds/enforcement; failure-modes/diagnostics/
  escalation/recovery; flow/ownership/change-control are each self-contained
  prose requirements, not a pipeline of steps that must occur in sequence).
- Skip: a stateful ordering gate — no methodology source cited in issue-1's
  own scout-brief (dbt, Great Expectations, SRE workbook, lineage docs) imposes
  a cross-write sequence on these three fields; inventing one now would not be
  formalizing an adopted methodology, it would be adding new methodology this
  issue is not scoped to invent. Recorded as an explicit non-adoption, per this
  issue's own "필요 시" qualifier.
- Adopt: implementation-rulebook's subprocess test-harness pattern for the
  repo-root `tests/` deliverable.

## Gap line
Current state (survey.md) has the sub-field shape (issue #1) and the directive
text, but zero mechanical enforcement and zero repo-root tests. Every item in
"adopt" above is an addition; nothing already exists.

## Segment fit
This role is report-only (`WRITE_SCOPE: []`) — the gate's write-surface regex
must match only `docs/issue-<n>/proposals/*data-engineering*.md` and
`docs/issue-<n>/reports/data-engineering.md`, mirroring pricing's own scoping,
never a broader surface.

Sources:
- /home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh
- /home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh
- /home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/hunt-state.sh
- /home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh
- docs/issue-1/proposals/methodology-norms.md (this repo, merged PR #9)
