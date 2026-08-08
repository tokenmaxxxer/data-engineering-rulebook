# Scout brief — issue #19

Mode: batched-sequential fallback (single session, no parallel
subagent/tool fan-out) — noted explicitly per scout-directive's
fallback-disclosure requirement. Reason: this deliverable is a
non-product, internal rulebook-alignment task; comparable systems are
the repo's own prior gate-remediation cycles, not external products, so
one internal-precedent pass covers the field. Stages used: 1
(survey-gap-directed internal read, no deepening needed — saturation hit
immediately: reading issue-13 and issue-16's proposals already gave a
converging pattern with no open question a second round would resolve).

## Comparable systems (internal, same rulebook, same PRODUCES shape)

- `docs/issue-13/proposals/2026-08-01-gate-remediation-a-plus.md` — A+
  remediation of the three gates. Must-be: fixes route through
  `produces-sections.py`/`gate-lib.*` as the single shared point, never
  duplicated per-gate. Pattern adopted: extend the shared regex module,
  not each gate file independently.
- `docs/issue-16/proposals/data-engineering.md` +
  `docs/issue-16/reports/data-engineering.md` — prior phase-1/phase-2
  cycle on these same three gates. Must-be: content-shape tightening
  stays scoped to one gate's own labeled section
  (`section_slice`/`*_LABEL_RE`); cross-gate leakage is treated as a
  defect class, not an acceptable simplification.
- `docs/handbooks/data-engineering/methodology.md` itself — the
  rulebook's own stated norm: "do not silently drop a sub-field... never
  just absent" and "do not adopt new tooling as a dependency — cite as
  source of shape only". Performance axis this rulebook already competes
  on: proportionality (N/A + reason) over rigid mandatory fields.

Sources: docs/issue-13/proposals/2026-08-01-gate-remediation-a-plus.md,
docs/issue-16/proposals/data-engineering.md,
docs/issue-16/reports/data-engineering.md,
docs/handbooks/data-engineering/methodology.md,
data-engineering/hooks/lib/produces-sections.py.

## Gap line

Field vocabulary the spec adds (`model_name`, `column_name`, `data_type`,
`constraint`, `verdict`) has no existing rulebook analog by name — the
current data-quality sub-field already covers the *concept* space
("schema: columns/types/formats") but not the literal tokens, and
`verdict` (a per-check pass/fail judgment) has no analog at all, not
even conceptually. `loop_state` vocabulary is a bigger gap: the file
that should declare it
(`docs/specs/record-fields-terminal-states.json`) does not exist yet in
this repo.

## Adopt / skip

- Adopt: strengthen data-quality-gate's content-shape check with the
  spec's schema-field vocabulary, inside its own labeled section —
  matches issue-13/16 precedent of scoped, non-duplicated tightening.
- Adopt: create `docs/specs/record-fields-terminal-states.json` fresh,
  scoped to the `data-engineering` kind only.
- Skip: adding a fourth gate plugin for `verdict` — no precedent in this
  rulebook for a fourth PRODUCES sub-field, and the spec does not name
  a fourth pipeline concern, only a field; `verdict` reads as a
  per-check output belonging inside the existing data-quality sub-field,
  not a new deliverable of its own.
