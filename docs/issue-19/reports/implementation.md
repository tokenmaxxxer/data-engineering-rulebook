---
code_under_review:
  - README.md
  - data-engineering/hooks/directive.sh
  - docs/handbooks/data-engineering/methodology.md
  - data-quality-gate/hooks/data-quality-gate.py
  - tests/data-quality-gate.test.sh
  - tests/produces-combination.test.sh
type: feature
breaking: false
verdict: pass
loop_state: landed
---

# Implementation record — issue #19 spec alignment

## What was done

Implementing the approved phase-1 proposal
(`docs/issue-19/proposals/2026-08-09-spec-alignment.md`, approved via
`APPROVE issue-19/implementation` from `JiwonJung94`, an approvers.md
account, exact string match): layering the marketplace spec's five
required deliverable fields (`model_name`, `column_name`, `data_type`,
`constraint`, `verdict`) and its five-state `loop_state` vocabulary
(`contracting`, `landed`, `model-unreachable`, `schema-undeclared`,
`testing`) onto `data-quality-gate`'s content-shape check and the
rulebook's docs, per the proposal's `## What will be done`.

## Why

Basis: `docs/issue-19/proposals/2026-08-09-spec-alignment.md` (approved
phase-1 proposal), itself built from
`docs/issue-19/reports/implementation/survey.md`. Reason: issue #19 asks
this rulebook's vocabulary to match the realized marketplace spec
`roles/specs/data-engineering.spec.json`, strengthening existing
methodology rather than deleting or duplicating it.

## Upstream

Based on: docs/issue-19/proposals/2026-08-09-spec-alignment.md

## What did not work

- Expected: `docs/specs/record-fields-terminal-states.json` keyed
  `{"data-engineering": ["landed"]}` (proposal item 3) would be accepted
  by `record-fields-gate.sh` as a valid per-kind override. Actual: the
  gate refused it — `record-fields-gate.sh` validates JSON keys against
  contract §2's fixed 9-value kind enumeration (`coding-record`,
  `feasibility-record`, `ops-record`, `product-record`, `qa-record`,
  `reflect-record`, `review-record`, `ux-design-record`,
  `verify-record`); `"data-engineering"` is not one of them, and the
  mechanism has no way to register a wholly new kind. Rekeying to the
  closest existing kind (`coding-record`) was considered and rejected:
  `coding-record`'s own vocabulary
  (`coding, commit-unreachable, committing, landed, scope-undeclared`)
  is different from this rulebook's five spec states
  (`contracting, landed, model-unreachable, schema-undeclared,
  testing`) — overriding `coding-record`'s terminal set with this
  vocabulary would silently corrupt the shared kind for every other
  role that also uses `coding-record` (including this very record).
  Removed the JSON file from the write set; kept the five-state
  vocabulary as prose-only in `methodology.md` (already written,
  ungated).

## Rationale for deviations

Proposal item 3 ("`docs/specs/record-fields-terminal-states.json` (new
file)") could not be executed as approved: the file's `{kind: [states]}`
contract, as enforced by `record-fields-gate.sh`, only accepts contract
§2's fixed role-kind vocabulary as keys — it is not a mechanism for a
repo to register an arbitrary new kind, contrary to what the proposal's
Rationale assumed ("the sanctioned mechanism ... picks this up with no
separate enforcement code to write"). This was discoverable only by
attempting the write (the gate's kind whitelist is not documented in
`docs/specs/record-fields-terminal-states.json`'s own contract text).
Delivered instead: the same five-state vocabulary, documented in
`docs/handbooks/data-engineering/methodology.md` under a new
`### loop_state vocabulary (issue #19)` heading, naming `landed` as the
sole terminal state in prose (matching the proposal's intended content)
without the JSON override. All four other `## What will be done` items
(1, 2, and the doc/grep-visibility restatements) landed as approved,
including the `tests/produces-combination.test.sh` fixture fix
(one-line token addition, mechanically required by item 1's
strengthening, not a new design decision).

## Doc placement outcomes

- [x] `docs/handbooks/data-engineering/methodology.md` — five spec field
  tokens named in the data-quality check list description; five
  `loop_state` values with one line each on when a record carries them
  (JSON mechanism deviation above; prose-only, matches proposal intent).
- [x] `README.md` — five spec field tokens grep-visible.
- [x] `data-engineering/hooks/directive.sh` — phase-2 PRODUCES directive
  text restated with the five field tokens.
- [x] `data-quality-gate/hooks/data-quality-gate.py` — content-shape
  check strengthened with the five literal spec-field tokens.
- [x] `tests/data-quality-gate.test.sh` — positive/negative cases for
  the five tokens added.
- [x] `tests/produces-combination.test.sh` — pre-existing fixture
  updated so the strengthened check doesn't regress it (deviation:
  outside the proposal's literal `files:` list, one-line mechanical
  fix).

## Open findings

None. After-proposal hunt finding (stance 0, bare-token-presence
bypass) accepted as an inherited, unchanged limitation per the
proposal's `## Out of scope`. Before-landing hunt (stance 2, malformed
input silently passing) returned NO FINDING
(`docs/reports/2026-08-09-hunt-spec-alignment.md`).

## Next steps

None — record is terminal (`landed`). Commit, push, open PR with
`Closes #19`.

## Resolution path

N/A — no open finding blocking this record.
