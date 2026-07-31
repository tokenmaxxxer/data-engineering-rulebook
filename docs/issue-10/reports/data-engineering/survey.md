---
subject: issue-10
role: data-engineering
---

# Current-state survey — data-engineering plugin (issue #10)

## What issue #1 already adopted (canon source for this issue)

`docs/issue-1/proposals/methodology-norms.md` (merged, PR #9) pinned:
- phase-1 proposal shape: background / proposed pipeline design / data-quality
  check list / failure-handling plan / consequences.
- phase-2 record sub-field shape for the three `PRODUCES` fields: pipeline design
  (flow + ownership + change-control note), data-quality check list (schema +
  thresholds + enforcement point), failure-handling plan (failure modes +
  diagnostics + escalation + recovery target).
- Explicit decision at the time: **no mechanical gate** — "the sub-fields are
  prose shape, not parseable tokens... judged by the human approver," relying on
  core canon's generic `record-fields-gate.sh` (presence-only, not shape).

`data-engineering/hooks/directive.sh` already carries the sub-field text inline
(landed by issue #1 phase 2, PR #9) — the directive-depth half of issue #1's own
reflection plan is done. What's missing per issue #10:

1. **Directive depth beyond the one-line PRODUCES summary** — issue #10 wants
   phase-1 vs phase-2 each broken into steps/judgment-criteria/prohibitions per
   facet, not just the sub-field parenthetical already in `directive.sh`.
2. **A mechanical methodology gate** — issue #1 declined one; issue #10 requires
   it, explicitly modeled on `pricing/hooks/methodology-gate.sh` (a `PreToolUse`
   heuristic-keyword gate on the role's own proposal/record write surfaces).
3. **Order constraint, if any** — issue #10 asks whether the methodology implies
   a sequence (조사→근거→채택) that a single-shot content gate can't enforce and
   that needs session state tracking instead.
4. **Gate tests at repo root** (`tests/`) — this repo currently has none.
5. **Agents/checklist**, only if the methodology has a repeating procedure.

## Plugin tree (current)

- `data-engineering/hooks/hooks.json` — `SessionStart` only. No `PreToolUse`
  block in this role's own plugin (core canon's global `record-fields-gate.sh`
  already fires for every role per issue #2/#4's landed core-canon-reference
  switch — confirmed via `git log` in this repo's own history).
- `data-engineering/hooks/directive.sh` — sources core's `role-directive.sh`;
  carries `PRODUCES` sub-fields (see above) and `WRITE_SCOPE: []`.
- No `docs/handbooks/` entry for data-engineering methodology exists in this
  repo (pricing-rulebook has one at `docs/handbooks/pricing/methodology.md`;
  this role has none — the norm lives only in `docs/issue-1/proposals/`).
- No repo-root `tests/` directory.

## Reference implementations examined (not copied — canon reference only)

- `pricing-rulebook/pricing/hooks/methodology-gate.sh` (231 lines): a
  `PreToolUse(Write|Edit|MultiEdit)` gate. Resolves the write target, restricts
  itself to the role's own proposal/record path regexes, reconstructs the
  resulting file content for Write/Edit/MultiEdit, then runs heuristic
  keyword/regex checks for the methodology's required elements against that
  content; denies (exit 2) naming exactly which element(s) are missing.
  Fail-closed on unparseable payload/unreadable file/internal error (`trap` +
  try/except pattern). Single-shot content check — no session state, because
  pricing's adopted elements (method name, family name, inputs, gate-check
  result, labeled numbers, residual list) have no required sequence.
- `implementation-rulebook/coding/hooks/coding-progress-gate.sh` (178 lines) +
  `hunt-state.sh` (47 lines): shows the *other* shape — a gate that reads
  cross-file state (another role's verify record) to decide, and a paired
  state-maintenance script (lock/reset) for when a single content check cannot
  express the constraint. Confirms: state tracking is reserved for constraints
  a single write's content cannot decide alone.
- `implementation-rulebook/tests/run-gate-tests.sh`: repo-root test harness —
  spawns the gate as a real subprocess against a synthetic git worktree +
  synthetic tool-call JSON on stdin, asserts exit code (0=allow/2=deny) per
  case. This is the pattern issue #10's "게이트 테스트" item points at.

## Unknowns going into scouting

1. Whether the three PRODUCES sub-fields (pipeline design / data-quality check
   list / failure-handling plan) have an implied *build order* the methodology
   sources (dbt, Great Expectations, SRE workbook — already cited in issue-1's
   scout-brief) actually require, or whether they are independently checkable
   the way pricing's six elements are (no order).
2. What heuristic keyword/element checks per sub-field would faithfully mirror
   issue-1's pinned shape without inventing new methodology (canon-reference
   constraint: only formalize what issue-1 already adopted).

## Constraints already fixed (not open to re-decide)

- `WRITE_SCOPE: []` stays — any new gate script and its tests live in the
  plugin's own `hooks/` and this repo's root `tests/`, never new write targets
  for the role's own record content beyond `docs/issue-<n>/reports/data-engineering.md`.
- No canon script copies (core's `record-fields-gate.sh` etc. stay
  canon-referenced, per issue #2/#5).
- Sub-field shape itself (from issue #1) is not open to re-litigate — this
  issue formalizes enforcement of that shape, it does not redesign the shape.
