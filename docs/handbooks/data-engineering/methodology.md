# data-engineering methodology (phase 1 / phase 2 facets)

Formalizes issue-1's adopted `PRODUCES` shape
(`docs/issue-1/proposals/methodology-norms.md`) into per-facet text, mirroring
`pricing-rulebook`'s own `docs/handbooks/pricing/methodology.md` (canon
reference only — no copy). `directive.sh`'s `PRODUCES` argument carries the
compressed pointer + sub-field summary; this file is the fuller prose home.

## Phase 1 — proposal (기획서)

Steps, in order:

1. State the triggering pipeline change in plain terms, no prior context
   assumed.
2. Propose pipeline design: source -> transform -> sink + ownership.
3. Propose a data-quality check list.
4. Propose a failure-handling plan.
5. State consequences/trade-offs, scaled to change size.

Judgment criteria: a trivial, non-breaking change may write "N/A, <reason>"
for any sub-field instead of filling it out in full — proportionality is a
judgment call, not mechanically gated (prose, not a parseable token; matches
issue-1's own proportionality must-be). A bare "N/A" with no reason is denied
by the mechanical gate regardless of triviality.

Prohibitions: do not adopt new tooling (dbt/Great Expectations/etc.) as a
dependency — cite as source of shape only, per issue-1 (c). Do not expand
`WRITE_SCOPE` beyond the single record file.

## Phase 2 — record (산출물), per sub-field

- **Pipeline design**: name source -> transform -> sink explicitly, name
  dataset ownership, and state how the design stays current (a
  change-control note, not write-once).
- **Data-quality check list**: name schema (columns/types/formats), state
  concrete numeric thresholds (completeness/uniqueness/accuracy/volume — not
  "should be good"), and name where each threshold is enforced (which check,
  which pipeline stage).
- **Failure-handling plan**: name failure modes, and per mode: a
  first-check/diagnostic step, an escalation path, a recovery/rollback step,
  and a recovery-time target scaled to the dataset's actual business impact
  (not a uniform number across all datasets).

Prohibitions: do not write outside `docs/issue-<n>/reports/data-engineering.md`
(`WRITE_SCOPE: []`). Do not silently drop a sub-field — an inapplicable
sub-field states why, it is never just absent.

## Mechanical enforcement

Three independent, top-level **plugins**, one per sub-field above — each its
own `.claude-plugin/plugin.json` + `hooks/hooks.json` + hook script, none
living inside the `data-engineering` plugin or depending on the other two's
internals:
`pipeline-design-gate/hooks/pipeline-design-gate.sh`,
`data-quality-gate/hooks/data-quality-gate.sh`,
`failure-handling-gate/hooks/failure-handling-gate.sh`, and their own
`DATA_ENGINEERING_*_GATE_OFF` kill switches. Each plugin fires on both facet
write surfaces (`docs/issue-<n>/proposals/*data-engineering*.md` and
`docs/issue-<n>/reports/data-engineering.md`) and accepts either its own
content-shape heuristic or an "N/A, <reason>" pattern; a bare "N/A" always
denies. No fourth "combination" plugin exists — the three are installed and
run side by side (each own `PreToolUse` entry in its own `hooks.json`,
registered independently in `.claude-plugin/marketplace.json`); see
`docs/issue-10/proposals/methodology-gate-and-directive-depth.md` section 2
for the full design rationale.

### Gate-house standard (issue #13, referencing core issue #72)

Each `<gate>-gate.sh` is a thin bash entrypoint (fail-closed EXIT trap,
kill-switch check, then exec) in front of a same-named `<gate>-gate.py`
payload; both source/import `core/hooks/lib/gate-lib.sh`/`gate-lib.py`
from the sibling `core` plugin (`${CLAUDE_PLUGIN_ROOT_CORE}`) for path
normalization, malformed-JSON deny, and `Edit`/`MultiEdit`/`replace_all`
content reconstruction (`gate-lib.py` additionally supports `NotebookEdit`
reconstruction, but none of the three gates' `hooks.json` matchers include
`NotebookEdit` — see the matcher/code coverage table in `README.md` for the
current coverage decision) — reference only, never copied
(`docs/handbooks/canon-scripts.md`). The "N/A, <reason>" exemption and
each gate's content-shape check are **scoped to that gate's own PRODUCES
sub-field section** (delimited by the other two gates' canonical labels —
"Pipeline design:", "Data-quality check list:", "Failure-handling
plan:"), not the whole document: an "N/A" or a keyword written for one
sub-field no longer waives or satisfies another gate's independent check.
Full remediation detail: `docs/issue-13/proposals/2026-08-01-gate-remediation-a-plus.md`,
`docs/issue-13/reports/data-engineering.md`.
