---
status: proposed
files:
  - README.md
  - data-engineering/hooks/directive.sh
  - docs/handbooks/data-engineering/methodology.md
  - data-engineering/hooks/lib/produces-sections.py
  - data-quality-gate/hooks/data-quality-gate.py
  - tests/data-quality-gate.test.sh
  - docs/specs/record-fields-terminal-states.json
---

## Request

Align this rulebook's vocabulary with the realized marketplace spec
`roles/specs/data-engineering.spec.json` (referenced by issue #19; the
file itself is an external on-the-record artifact not present in this
tree, so the issue body's stated field/state lists are used as the
source of truth): layer the spec's five required deliverable fields
(`model_name`, `column_name`, `data_type`, `constraint`, `verdict`) and
its five-state `loop_state` vocabulary (`contracting`, `landed`,
`model-unreachable`, `schema-undeclared`, `testing`) onto the existing
rulebook docs/hooks/gates, strengthening what exists rather than
deleting any current methodology.

## Constraints

- No deletion of existing PRODUCES methodology (pipeline design,
  data-quality check list, failure-handling plan) — issue #19 says
  "strengthening existing content, never deleting."
- No new top-level gate plugin — the rulebook's established shape is
  three independent PRODUCES sub-field gates (issue #1, remediated
  #13/#16); adding a fourth changes the architecture, which issue #19
  does not ask for.
- Every spec field must end up grep-visible in `docs/` or `README.md`
  (acceptance criterion), and every field must have a stated rulebook
  home, even if that home is "no natural home, here is why."
- `loop_state` vocabulary must match the spec set exactly — no stale
  state left in and no extra state invented.
- Test suite is `tests/*.sh`, not `pytest` (this repo has no `pytest`
  test files) — acceptance criterion's `pytest` branch does not apply;
  run `tests/*.sh` / `bash tests/run-gate-tests.sh` instead, per
  survey §"Gaps," item 4.

## Rationale

**Where the four schema fields (`model_name`, `column_name`,
`data_type`, `constraint`) live**: considered creating a new
`schema-gate` plugin (fourth PRODUCES sub-field, mirroring
`pipeline-design-gate`/`data-quality-gate`/`failure-handling-gate`'s
existing pattern) — rejected. The rulebook's `data-quality-gate`
already owns "schema (columns/types/formats)" as a documented
sub-concept of the data-quality check list; the spec's four fields are
that same concept made literal (model = dataset/table name, column_name
+ data_type + constraint = the schema entries themselves). A fourth
gate would duplicate `data-quality-gate`'s existing scope rather than
add new scope, and issue-13/16 precedent (survey §"Precedent") treats
scope duplication across gates as a defect, not a feature. Strengthening
`data-quality-gate`'s existing content-shape check to require these
literal tokens keeps one sub-field owning one concept.

**Where `verdict` lives**: considered giving it no home and stating
"no natural home" per the issue's own escape hatch — rejected, because
a home does exist: `data-quality-gate` already requires "numeric
thresholds" and "where each threshold is enforced" per schema entry: a
pass/fail `verdict` per threshold check is the natural third leg of
that existing structure (schema entry -> threshold -> verdict), not an
unrelated new concept. Using the escape hatch here would be
under-mapping a field that does fit, which the issue's empty-state
clause exists to prevent, not invite.

**`loop_state` vocabulary — new file vs. extending an existing one**:
considered adding the five states as prose inside
`docs/handbooks/data-engineering/methodology.md` instead of a JSON
terminal-states file — rejected, because contract v3 s19 already names
`docs/specs/record-fields-terminal-states.json` (a `{kind: [states]}`
JSON object) as the sanctioned mechanism for a repo to declare a kind's
loop_state set, and the file does not exist yet in this repo (survey
confirms). Using the sanctioned mechanism means the terminal-state gate
that already knows to read that file picks this up with no separate
enforcement code to write; prose in the handbook would be
unenforceable and would duplicate what the JSON file is for.

## What will be done

1. **`data-quality-gate` content-shape strengthening**
   (`data-quality-gate/hooks/data-quality-gate.py`,
   `data-engineering/hooks/lib/produces-sections.py`): require the
   data-quality section to name, per schema entry, all of
   `model_name`/`column_name`/`data_type`/`constraint`, plus a
   `verdict` (pass/fail) per threshold check — as an extension of the
   section's existing content-shape check, scoped to
   `DATA_QUALITY_LABEL_RE`'s own section via the existing
   `section_slice` helper (no new label regex needed; these are
   required tokens inside the existing label, not a new labeled
   sub-section). The existing "N/A, `<reason>`" proportionality
   exemption continues to apply at the whole-sub-field level, unchanged.
   `tests/data-quality-gate.test.sh` gains cases for the five tokens
   (positive: all present passes; negative: each missing token denies).
2. **Doc/directive updates** (`README.md`, `directive.sh`,
   `methodology.md`): restate the data-quality check list's phase-1 and
   phase-2 text to name the five literal field tokens explicitly
   (replacing/extending the current generic "schema
   (columns/types/formats)" phrasing), satisfying the grep-visibility
   acceptance criterion in all three canonical restatement locations.
3. **`docs/specs/record-fields-terminal-states.json`** (new file):
   `{"data-engineering": ["landed"]}` — declares `landed` as the sole
   terminal state for this kind (matches every existing landed record,
   survey confirms zero exceptions) and, by the file's own
   `{kind: [states]}` contract, implicitly leaves `contracting`,
   `model-unreachable`, `schema-undeclared`, `testing` as the
   non-terminal states in the kind's vocabulary. `methodology.md` gains
   a short paragraph naming all five states and one line each on when a
   data-engineering record would carry each non-terminal one (e.g.
   `schema-undeclared` when the data-quality sub-field's schema is not
   yet named; `model-unreachable` when the pipeline's source cannot be
   reached to validate against; `testing` while a check is being run
   but not yet verdicted; `contracting` while pipeline design's
   source/sink ownership is still being negotiated).

## Out of scope

- Making the new token check semantically bind each field to its own
  schema entry (e.g. requiring `column_name`/`data_type`/`constraint`
  to co-occur per-row rather than anywhere in the section). The
  after-proposal warrant hunt (stance 0, `docs/reports/2026-08-09-hunt-spec-alignment.md`)
  confirmed a bare-presence check is satisfiable by a single throwaway
  sentence naming all five tokens with no real schema content — but
  this is the same keyword-presence limitation `SCHEMA_RE`/
  `THRESHOLD_RE`/`ENFORCE_RE` already have today (mechanical,
  deterministic regex gates, per `gate-house-standard.md`, do not do
  semantic content judgment). Closing it rulebook-wide is a
  gate-architecture change bigger than issue #19's field-vocabulary
  alignment ask; the new tokens inherit the existing gate's accepted
  limitation rather than introduce a new one.
- Creating the `data-modeling` plugin the rulebook's own `HAND-OFF` line
  names — it does not exist (survey confirms) and issue #19 does not
  ask for it; noted as a pre-existing gap, not this issue's job to fix.
- Any change to `pipeline-design-gate` or `failure-handling-gate`'s
  content-shape checks — none of the five spec fields maps onto pipeline
  design or failure-handling; only data-quality-gate is touched.
- A fourth PRODUCES gate plugin (rejected in Rationale).
- Retrofitting `loop_state` values into already-landed records
  (`docs/issue-1`, `-10`, `-13`, `-16` reports) — those are historical
  and stay as `landed`.

## How you'll know it worked

- `grep -ri 'model_name\|column_name\|data_type\|constraint\|verdict' docs/ README.md`
  returns hits for all five terms (acceptance criterion, literal).
- `docs/specs/record-fields-terminal-states.json` exists, is valid JSON,
  and its `data-engineering` entry is exactly `["landed"]` — the
  non-terminal four (`contracting`, `model-unreachable`,
  `schema-undeclared`, `testing`) appear in `methodology.md` prose, not
  duplicated into the JSON (which only lists terminal states per its own
  contract).
- `bash tests/run-gate-tests.sh` passes, including the new
  `data-quality-gate.test.sh` cases for the five required tokens.
- No pipeline-design-gate or failure-handling-gate test regresses (they
  are untouched).
