---
subject: issue-10
role: data-engineering
---

# Proposal — directive depth + mechanical methodology gate for data-engineering

Phase 1 only. No execution in this PR. Survey:
`docs/issue-10/reports/data-engineering/survey.md`. Scout brief:
`docs/issue-10/reports/data-engineering/scout-brief.md`.

This issue formalizes enforcement of the sub-field shape issue #1 already
adopted (`docs/issue-1/proposals/methodology-norms.md`). It does not redesign
that shape — it turns the one-line `PRODUCES` parenthetical already in
`directive.sh` into (a) facet-level directive text and (b) a mechanical gate,
mirroring `pricing-rulebook/pricing/hooks/methodology-gate.sh` (canon
reference only, per this issue's own constraint — no copy).

## 1. Directive depth (phase 1 / phase 2, per facet)

Replace the current single `PRODUCES` line in `directive.sh` with facet-level
text. Design, not yet wired (phase 2 does the wiring):

**Phase 1 (proposal) facet:**
- Steps: state the triggering pipeline change in plain terms first (no prior
  context assumed) → propose pipeline design (source → transform → sink +
  ownership) → propose data-quality check list → propose failure-handling plan
  → state consequences/trade-offs, scaled to change size.
- Judgment criteria: a trivial, non-breaking change may write "N/A, scope is
  a single non-breaking field add" for any sub-field instead of filling it —
  proportionality is a judgment call this issue does not gate mechanically
  (prose, not a parseable token; matches issue-1's own proportionality
  must-be).
- Prohibitions: do not adopt new tooling (dbt/Great Expectations/etc.) as a
  dependency — cite as source of shape only, per issue-1 (c). Do not expand
  `WRITE_SCOPE` beyond the single record file.

**Phase 2 (record) facet, per sub-field:**
- Pipeline design: must name source → transform → sink explicitly, name
  dataset ownership, and state how the design stays current (change-control
  note, not write-once).
- Data-quality check list: must name schema (columns/types/formats), state
  concrete thresholds (completeness/uniqueness/accuracy/volume — numeric, not
  "should be good"), and name where each threshold is enforced (which check,
  which pipeline stage).
- Failure-handling plan: must name failure modes, and per mode: a first-check/
  diagnostic step, an escalation path, a recovery/rollback step, and a
  recovery-time target scaled to the dataset's actual business impact (not a
  uniform number across all datasets).
- Prohibitions: do not write outside `docs/issue-<n>/reports/data-engineering.md`
  (WRITE_SCOPE: []). Do not silently drop a sub-field — an inapplicable
  sub-field states why (see proportionality above), it is never just absent.

This text is what phase 2 will insert into `directive.sh` (replacing the
current parenthetical), plus a matching addition to this repo's (currently
absent) `docs/handbooks/data-engineering/methodology.md`, mirroring
pricing-rulebook's own `docs/handbooks/pricing/methodology.md` — a fuller
prose home for the facet text above than a `SessionStart` banner can hold,
with `directive.sh` keeping only the compressed pointer + sub-field summary it
already carries today.

## 2. Methodology gate (mechanical, PreToolUse)

New `data-engineering/hooks/methodology-gate.sh`, structurally mirroring
`pricing/hooks/methodology-gate.sh` (see scout-brief "must-bes"):

- Trigger: `PreToolUse` on `Write|Edit|MultiEdit`.
- Write-surface scope (fail-open outside these — "not this gate's business",
  matching pricing's own `sys.exit(0)` early-out): paths matching
  `^docs/issue-[0-9]+/proposals/.*data-engineering.*\.md$` (phase-1 proposals)
  or `^docs/issue-[0-9]+/reports/data-engineering\.md$` (phase-2 record).
- For an in-scope write: resolve the resulting file content (Write's full
  `content`; Edit/MultiEdit's `old_string`→`new_string` applied against
  current content, denying if the resulting content can't be determined — same
  as pricing's gate) and run heuristic checks:
  - **Pipeline design present** when the write is a phase-2 record write or a
    phase-1 proposal that reaches this sub-field at all: requires an arrow
    token (`→` or `->`) near "source"/"transform"/"sink" language, plus an
    ownership mention (e.g. "owner", "owned by"), plus a change-control
    mention (e.g. "change-control", "living document", "kept current") — OR an
    explicit N/A-with-reason per the proportionality clause.
  - **Data-quality check list present**: requires schema-shape language
    (column/type/format terms) AND at least one numeric threshold AND an
    enforcement-point mention (which check/stage) — OR N/A-with-reason.
  - **Failure-handling plan present**: requires a named failure mode AND
    diagnostic/escalation/recovery language AND a recovery-time-target mention
    — OR N/A-with-reason.
  - N/A-with-reason recognized the same way as any sub-field content: the
    heuristic accepts "N/A" (or "해당 없음") immediately followed by a reason
    clause; a bare "N/A" with no reason still denies.
- Deny (exit 2) naming exactly which sub-field(s)/element(s) are missing, same
  message shape as pricing's gate. Fail-closed (top-of-file `trap`, python
  try/except) on unparseable payload, unreadable existing file, or any
  internal error — never fail-open on an exception.
- Kill switch: `DATA_ENGINEERING_METHODOLOGY_GATE_OFF=1` (mirrors pricing's
  `PRICING_METHODOLOGY_GATE_OFF`).

## 3. Order constraint — explicit non-adoption

No session-state ordering gate. Per scout-brief: none of the methodology
sources issue #1 already adopted (RFC/design-doc convention, dbt/Great
Expectations, SRE data-processing workbook, lineage docs) impose a required
write-order across the three `PRODUCES` sub-fields — each is independently
checkable from final content, the same way pricing's six elements are (no
state file, no lock). Inventing an order requirement now would exceed this
issue's scope (formalizing adopted methodology, not authoring new
methodology). If a future issue adopts a methodology that does require
sequence (e.g., "profile before proposing thresholds"), that issue should
follow `implementation-rulebook`'s coding-progress-gate.sh + hunt-state.sh
pattern — a paired state-maintenance script keyed to lifecycle hooks — not
this one.

## 4. Gate tests (repo root)

New `tests/run-gate-tests.sh`, following
`implementation-rulebook/tests/run-gate-tests.sh`'s subprocess-harness
pattern: for each sub-field, one allow case (all required elements present)
and one deny case (one element missing) against a synthetic git worktree +
synthetic `Write` tool-call JSON on stdin, asserting exit code 0/2. Plus: one
allow case for an out-of-scope path (foreign file, gate must not fire), one
allow case for a proportionality N/A-with-reason, and one deny case for a
bare N/A with no reason. Minimum 8 cases (2 per sub-field × 3, + 2 scope
cases).

## 5. Agents / checklist

Not needed. The methodology has no repeating multi-step procedure beyond
"write the record, gate checks it" — no agent or checklist item issue #1's
adopted norm requires that a mechanical gate + directive text don't already
cover.

## Constraints honored

- Canon reference only: `record-fields-gate.sh` and any core lib stay
  core-referenced; the new gate is additive, not a replacement, exactly as
  pricing's own gate is additive to core's (per its own header comment).
- No canon script copies introduced.
- `WRITE_SCOPE: []` unchanged — the new gate script and its tests are the
  role's own plugin/test assets, not new record write targets.
- Role boundary unchanged — gate only fires on this role's own write surfaces.

## Plugin reflection plan (phase 2, post-Approve)

1. Add `data-engineering/hooks/methodology-gate.sh` per section 2.
2. Add `PreToolUse` block to `data-engineering/hooks/hooks.json` wiring it.
3. Replace `directive.sh`'s `PRODUCES` line with the facet-depth text from
   section 1 (kept as one string per `core_role_directive`'s four-argument
   signature — newline-joined within the `PRODUCES` argument, same technique
   already used for the existing `WRITE_SCOPE`+`HAND-OFF` multi-line arg).
4. Add `docs/handbooks/data-engineering/methodology.md` holding the fuller
   facet prose.
5. Add `tests/run-gate-tests.sh` per section 4.
6. Record this reflection as done in `docs/issue-10/reports/data-engineering.md`
   (phase-2 record, gated on Approve like any other phase-2 output).

## Open question for the approver

None — every element above traces to issue #1's already-adopted shape or to
the two exemplar gate patterns already landed elsewhere in this ecosystem
(pricing's content gate, implementation's stateful gate + test harness); no
alternative shape was left undecided.
