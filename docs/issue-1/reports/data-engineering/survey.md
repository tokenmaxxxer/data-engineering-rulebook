---
subject: issue-1
role: data-engineering
---

# Current-state survey — data-engineering plugin

## Plugin tree

- `data-engineering/.claude-plugin/plugin.json` — plugin manifest, untouched by this issue.
- `data-engineering/hooks/hooks.json` — `SessionStart` only, invokes `directive.sh`. No
  `PreToolUse` gates live in this repo (core canon already fires the shared
  `record-fields-gate.sh` / `handbook-trigger-gate.sh` / `trailer-gate.sh` globally per
  issue #2's already-merged transition — confirmed via `git log`: PR #4 removed this
  role's local copies of those three gate scripts and the `PreToolUse` block).
- `data-engineering/hooks/directive.sh` — sources core's `role-directive.sh` and calls
  `core_role_directive` with four values:
  - `YOU DECIDE`: "파이프라인이 데이터를 안정적으로 이동·변환하는가"
  - `USE_WHEN`: "파이프라인 신설/변경이 걸릴 때"
  - `PRODUCES (required record fields)`: **"pipeline design, data-quality check list,
    failure-handling plan"**
  - `WRITE_SCOPE`: `[]` (report-only role) + `HAND-OFF`: schema design → data-modeling

## Gap this issue is about

The three `PRODUCES` fields (pipeline design / data-quality check list / failure-handling
plan) are **named but not specified** — no methodology is pinned down for what a
conforming "pipeline design" or "data-quality check list" or "failure-handling plan"
must contain, and no analogous methodology exists yet for what a *phase-1 proposal
document* in this role must contain (section shape, evidence format). This issue's
job is to pin both down, based on domain research rather than guesswork, and record a
plugin-reflection plan (which directive/record-field/gate wiring encodes the result).

## Unknowns going into scouting

1. What do real design-doc/RFC processes require as mandatory sections, and in what
   evidence format — this shapes the **phase-1 proposal norm**.
2. What do real data-quality frameworks (dbt, Great Expectations, data contracts)
   treat as non-negotiable components — this shapes the **data-quality check list**
   sub-component of phase-2 norms.
3. What do real pipeline-reliability/incident practices require of a failure-handling
   plan — shapes the **failure-handling plan** sub-component.
4. Whether "pipeline design" as a deliverable has an established documentation shape
   (vs. ad hoc) — shapes the **pipeline design** sub-component.

## Constraints already fixed (not open to re-decide)

- `WRITE_SCOPE: []` — this role never writes outside its own record; any norm this
  issue adopts must fit inside `docs/issue-<n>/reports/data-engineering.md`, not new
  file trees.
- No canon script copies — `warrant-hunter`/gate scripts stay core-canon references
  per issue #2/#5's already-landed recalls; this issue must not reintroduce local
  copies.
- Record discipline (existing reinforced clauses) is preserved as-is per this issue's
  own constraints section.
