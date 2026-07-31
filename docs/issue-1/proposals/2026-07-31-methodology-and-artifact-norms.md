---
subject: issue-1
role: data-engineering
---

# Proposal — phase-1 proposal norm & phase-2 artifact norm for data-engineering

Phase 1 only. No execution in this PR. Survey: `docs/issue-1/reports/data-engineering/survey.md`.
Scout brief: `docs/issue-1/reports/data-engineering/scout-brief.md`.

## (a) Phase-1 proposal norm — methodology, required sections, evidence format

Methodology: lightweight RFC/design-doc convention (background → proposal →
consequences), scaled down to match this role's `WRITE_SCOPE: []` — one record file,
not a document tree.

Required sections for a data-engineering phase-1 proposal:
1. **Background** — the triggering change/issue, written so a reader with no prior
   context can follow it (per Angle 1's must-be).
2. **Proposed pipeline design** — data flow stated as source → transform → sink,
   plus ownership of the affected dataset(s) (Angle 4).
3. **Data-quality check list** (see (b) for internal shape) — proposed, not yet
   enforced.
4. **Failure-handling plan** (see (b) for internal shape) — proposed, not yet
   enforced.
5. **Consequences / trade-offs** — what changes for consumers, and effort scaled to
   the change's complexity (Angle 1's proportionality must-be: trivial pipeline
   tweaks may state "N/A, scope is a single non-breaking field add" rather than
   filling every sub-field).

Evidence format: each of sections 2-4 cites *why* the design meets the stated need —
inline reasoning, not a separate rationale document (matches this role's report-only
scope; matches the sibling issue-2/issue-5 proposals' own inline-rationale style
already in this repo).

## (b) Phase-2 artifact norm — methodology, required components

The phase-2 record (`docs/issue-<n>/reports/data-engineering.md`) is the same three
`PRODUCES` fields already named in `directive.sh`, now with a pinned internal shape
per field:

- **Pipeline design**: data flow (source → transform → sink) stated explicitly +
  dataset ownership + a note on how the design stays current (change-control, not
  write-once) — per Angle 4.
- **Data-quality check list**: schema (columns/types/formats) + concrete thresholds
  for completeness/uniqueness/accuracy/volume (numbers, not "should be good") + where
  each threshold is enforced (which check, which stage) — per Angle 2.
- **Failure-handling plan**: named failure modes, each with a first-check/diagnostic
  step, an escalation path, a recovery/rollback step, and a recovery-time target
  scaled to the dataset's actual business impact (not a uniform number across all
  datasets) — per Angle 3.

Methodology: same lightweight report-file convention as (a) — no new tooling
adoption (Great Expectations/dbt/etc. are cited as the source of the sub-field shape,
not adopted as dependencies; this role is report-only).

## (c) Rationale for each adoption

- RFC-derived phase-1 shape: background/proposal/consequences is the one structure
  that recurs across every design-doc source surveyed regardless of company
  (Pragmatic Engineer's cross-company survey), so it is the shape least likely to be
  idiosyncratic to one org's fashion — a defensible default for a proposal template
  meant to generalize across every future data-engineering issue.
- Data-quality sub-fields (schema + thresholds + enforcement point) generalize the
  common structure across dbt data contracts and Great Expectations — both
  independently converge on "checkable rule + where it's checked," which is the
  minimum a *check list* can mean without becoming vague ("data should be clean").
- Failure-handling sub-fields (failure mode → diagnostic → escalation → recovery
  target) match Google SRE's own data-processing workbook and industry runbook
  practice (dbt Labs, Monte Carlo) converging on the same shape — adopting a
  structure two independent lineages agree on lowers the risk this is one vendor's
  house style dressed up as a standard.
- None of this proposes adopting the tools themselves (dbt, Great Expectations,
  specific SRE tooling) — this role's `WRITE_SCOPE: []` and report-only nature means
  the norm borrows *documentation shape* from these sources, not their tech stack.

## (d) Plugin reflection plan

Phase 2 of this issue (post-Approve) will:

1. Extend `directive.sh`'s `PRODUCES` argument from the current flat list
   ("pipeline design, data-quality check list, failure-handling plan") to name the
   pinned sub-fields inline, e.g.:
   `"PRODUCES (required record fields): pipeline design (flow + ownership +
   change-control note), data-quality check list (schema + thresholds + enforcement
   point), failure-handling plan (failure modes + diagnostics + escalation +
   recovery target)"`
   — kept as one string per `core_role_directive`'s existing four-argument
   signature; no new argument slot needed or available.
2. No new gate script — this repo already relies on core canon's global
   `record-fields-gate.sh` (per issue #2/#4's landed transition) to enforce the
   required-fields *presence*; this issue only changes what "presence" must contain,
   which is a documentation-shape requirement judged by the human approver at
   phase-2 record time, not something a mechanical gate can verify (the sub-fields
   are prose shape, not parseable tokens). Recording this as an explicit non-gate
   decision so phase 2 does not silently attempt one.
3. `WRITE_SCOPE: []` stays unchanged — the phase-1 proposal norm from (a) applies to
   this and every future phase-1 proposal this role writes; the phase-2 artifact norm
   from (b) applies to `docs/issue-<n>/reports/data-engineering.md` going forward.
4. No canon script copies introduced — consistent with this issue's own constraint
   and with issue #2/#5's already-landed core-canon-reference recalls.

## Open question for the approver

None — the RFC-derived phase-1 shape and the SRE/data-contract-derived phase-2 shape
are both fully determined by the scout brief's converging must-bes; no alternative
shape was left undecided.
