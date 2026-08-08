# Issue #19 survey — current state vs. the realized spec

Subject: issue-19. `roles/specs/data-engineering.spec.json` is not present
in this working tree or reachable filesystem (on-the-record artifact,
external) — the issue body is the authoritative source for the spec's
required-field and loop_state sets, and is used as such below.

## Spec, as stated in the issue

- Required deliverable fields: `model_name`, `column_name`, `data_type`,
  `constraint`, `verdict`.
- `loop_state` vocabulary: `contracting`, `landed`, `model-unreachable`,
  `schema-undeclared`, `testing`.

## Rulebook current state

### PRODUCES shape (unchanged since issue #1, remediated #13/#16)

Three independent phase-2 record sub-fields, each behind its own gate
plugin (`pipeline-design-gate`, `data-quality-gate`,
`failure-handling-gate`), all writing into the single
`docs/issue-<n>/reports/data-engineering.md` record:

- **Pipeline design**: source -> transform -> sink + ownership + a
  change-control note. (`data-engineering/hooks/directive.sh`,
  `docs/handbooks/data-engineering/methodology.md`)
- **Data-quality check list**: schema (columns/types/formats), numeric
  thresholds (completeness/uniqueness/accuracy/volume), and where each
  threshold is enforced.
- **Failure-handling plan**: failure modes, each with a diagnostic step,
  escalation path, recovery/rollback step, and a recovery-time target.

`README.md`'s `produces:` line and `directive.sh`'s literal `PRODUCES`
text are the two canonical restatements of this shape; both currently use
only "schema (columns/types/formats)" as a generic phrase — no literal
`model_name` / `column_name` / `data_type` / `constraint` / `verdict`
tokens appear anywhere under `docs/` or `README.md` today (`grep -ri`
confirms zero hits for all five).

### loop_state vocabulary — no vocabulary file exists

`docs/specs/record-fields-terminal-states.json` — the file contract v3
s19 says a repo uses to override a kind's terminal states — does not
exist in this repo. Every landed data-engineering record so far
(`docs/issue-1/reports/data-engineering.md`,
`docs/issue-10/reports/data-engineering.md`,
`docs/issue-13/reports/data-engineering.md`,
`docs/issue-16/reports/data-engineering.md`) uses exactly one
`loop_state` value: `landed`. No record has ever used a non-terminal
state, so there is no existing precedent for what a
mid-flight/blocked data-engineering record's `loop_state` should read —
this is new vocabulary, not a rename of existing values.

### Gate mechanics relevant to field placement

`produces-sections.py`'s `NA_RE` / label regexes
(`PIPELINE_DESIGN_LABEL_RE`, `DATA_QUALITY_LABEL_RE`,
`FAILURE_HANDLING_LABEL_RE`) scope each gate's check to the text between
its own canonical label line and the next label line. Any new field
tightened into an existing gate's content-shape check must live inside
that gate's own labeled section, or the gate's `section_slice` will not
see it. `docs/handbooks/canon-scripts.md`'s reference-not-copy rule
applies to `core/hooks/lib/gate-lib.*` only, not to
`produces-sections.py`, which is owned by `data-engineering` itself and
is the correct place to extend shared regex/label logic if a new field
needs its own label pattern.

### `data-modeling` hand-off target does not exist

`README.md` and `directive.sh` both state
`HAND-OFF: 스키마 설계 자체는 → data-modeling`, but no `data-modeling`
plugin, directory, or handbook exists anywhere in this repo or in the
reachable `roles/` trees. `model_name` / `column_name` / `data_type` /
`constraint` are schema-shaped concepts that the rulebook's own hand-off
line already assigns elsewhere — they cannot be redirected to a
nonexistent role, so must find a home inside this rulebook's own
existing sub-fields (most naturally: data-quality check list, which
already names "schema (columns/types/formats)").

## Precedent for this kind of change (internal, since no external
## product category applies to an internal rulebook-alignment task)

Issue #13 (`docs/issue-13/proposals/2026-08-01-gate-remediation-a-plus.md`)
and issue #16
(`docs/issue-16/proposals/data-engineering.md`) are the two prior
phase-1-then-phase-2 gate-remediation cycles in this exact rulebook.
Both: (a) kept the three-gate/three-plugin split intact rather than
merging or renaming sub-fields, (b) extended `produces-sections.py`'s
shared regex module rather than duplicating logic per gate, and (c)
scoped every content-shape tightening to a gate's own labeled section.
This issue's mapping follows the same shape: strengthen existing
sub-field content-shape checks with the spec's field vocabulary, do not
introduce a fourth gate or rename the three existing ones.

## Gaps the proposal must resolve

1. Where do `model_name`, `column_name`, `data_type`, `constraint` live —
   which existing PRODUCES sub-field, and does the gate's content-shape
   check need new required tokens?
2. `verdict` has no existing analog anywhere in the rulebook (the gates
   check for presence of a well-formed section, not a pass/fail
   judgment per check). Needs a stated home or an explicit "no natural
   home" statement per the issue's acceptance criterion.
3. `docs/specs/record-fields-terminal-states.json` must be created (it
   does not exist) to declare the loop_state set for the
   `data-engineering` kind, matching the spec's five states exactly, no
   more no less — replacing the currently-implicit "only `landed` is
   ever used" state of affairs.
4. Test suite: `tests/*.test.sh` + `tests/run-gate-tests.sh` exist and
   are runnable (`pytest` is not used in this repo — no `.py` test
   files under `tests/`, all are `.sh`). The acceptance criterion's
   `pytest` branch does not apply; `tests/*.sh` does.
