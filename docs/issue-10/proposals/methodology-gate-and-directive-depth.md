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
`directive.sh` into (a) facet-level directive text and (b) a set of three
independent mechanical gate plugins, one per adopted methodology sub-field,
combined per facet (phase-1 기획서 vs phase-2 산출물) rather than fused into
one script — structurally mirroring `pricing-rulebook`'s single-shot
content-gate template per plugin (canon reference only, per this issue's own
constraint — no copy). Revised after reviewer FEEDBACK on PR #11 requesting
the plugin-set restructure; see section 2 for the explicit plugin list.

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

## 2. Methodology gate — plugin-set, not a single monolithic script

Reviewer feedback on the prior revision (PR #11): a single fused gate script
covering all three `PRODUCES` sub-fields does not satisfy issue #10's actual
required shape. The required shape is a **plugin set**: one methodology = one
independent plugin (this repo's own `data-engineering` plugin then hosts
several such independent units, the same way a single rulebook can host many
independent freelunch-style plugins rather than one fused script — freelunch's
completeness comes from each unit being independently addressable, testable,
and toggleable, not from one script that does everything). Phase-1 (기획서)
and phase-2 (산출물) norms are each expressed as a **combination** of these
same independent plugins, not as separate logic.

### 2.1 Independent plugin list (required, explicit)

Each row is one methodology = one independent plugin: its own hook script,
own kill switch, own test cases, own deny-message vocabulary. None depends on
another's internals — they can be added, removed, or reordered independently.

| Plugin name | Methodology owned | Components (per plugin) | Combines into |
|---|---|---|---|
| `pipeline-design-gate` | Pipeline design (source → transform → sink + ownership + change-control), from issue #1's adopted `dbt`/lineage-doc shape | Hook script `data-engineering/hooks/pipeline-design-gate.sh`; kill switch `DATA_ENGINEERING_PIPELINE_DESIGN_GATE_OFF`; heuristic check: arrow token (`→`/`->`) near source/transform/sink language + ownership mention + change-control mention, OR N/A-with-reason; own test cases in `tests/pipeline-design-gate.test.sh` | Phase-1 proposal combination (2.2) + phase-2 record combination (2.2) |
| `data-quality-gate` | Data-quality check list (schema + numeric thresholds + enforcement point), from issue #1's adopted Great-Expectations-shape norm | Hook script `data-engineering/hooks/data-quality-gate.sh`; kill switch `DATA_ENGINEERING_DATA_QUALITY_GATE_OFF`; heuristic check: schema-shape language + numeric threshold + enforcement-point mention, OR N/A-with-reason; own test cases in `tests/data-quality-gate.test.sh` | Phase-1 proposal combination (2.2) + phase-2 record combination (2.2) |
| `failure-handling-gate` | Failure-handling plan (failure modes + diagnostics + escalation + recovery target), from issue #1's adopted SRE-workbook shape | Hook script `data-engineering/hooks/failure-handling-gate.sh`; kill switch `DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF`; heuristic check: named failure mode + diagnostic/escalation/recovery language + recovery-time-target mention, OR N/A-with-reason; own test cases in `tests/failure-handling-gate.test.sh` | Phase-1 proposal combination (2.2) + phase-2 record combination (2.2) |

Three plugins total — one per `PRODUCES` sub-field issue #1 already adopted.
No fourth "meta" gate is added: the combination logic in 2.2 is a thin
dispatcher, not a fourth independent methodology, so it is not listed as a
plugin in its own right (see 2.3).

All three share the same structural template, mirroring
`pricing/hooks/methodology-gate.sh` (canon reference only, per this issue's
own constraint — no copy): `PreToolUse` on `Write|Edit|MultiEdit`, resolve the
resulting file content the same way pricing's gate does (Write's full
`content`; Edit/MultiEdit's `old_string`→`new_string` applied against current
content, denying if unresolvable), fail-closed (top-of-file `trap`, python
try/except) on unparseable payload / unreadable file / internal error, deny
(exit 2) naming exactly which element(s) of *that plugin's own* methodology
are missing. N/A-with-reason is recognized identically across all three: "N/A"
(or "해당 없음") immediately followed by a reason clause; a bare "N/A" with no
reason still denies.

### 2.2 Plugin combination — how 기획서 (phase 1) and 산출물 (phase 2) norms are expressed

Neither the phase-1 proposal norm nor the phase-2 record norm is its own
plugin. Each is a **combination**: the same three write-surface-scoped
dispatch, running all three independent plugins against the write's content,
differing only in which facet-scoping regex feeds them and what "present"
means for that facet (proportionality N/A permitted at phase 1, required
concrete content at phase 2 — same distinction as section 1's directive
depth).

- **기획서 combination (phase-1 proposal)**: write-surface scope
  `^docs/issue-[0-9]+/proposals/.*data-engineering.*\.md$`. Runs
  `pipeline-design-gate` + `data-quality-gate` + `failure-handling-gate`
  against the proposal's own facet text; each plugin accepts either its
  content-shape check or an explicit N/A-with-reason (proportionality clause,
  section 1). All three must pass (or N/A-with-reason) for the write to be
  allowed — a fourth combination step, in `data-engineering/hooks/hooks.json`,
  simply invokes all three in sequence and denies on the first failing one,
  naming which plugin denied.
- **산출물 combination (phase-2 record)**: write-surface scope
  `^docs/issue-[0-9]+/reports/data-engineering\.md$`. Runs the same three
  plugins, but N/A-with-reason is only accepted where section 1's phase-2
  prohibitions already allow it ("do not silently drop a sub-field" — an
  inapplicable sub-field still states why, exactly as today); otherwise each
  plugin requires its full content-shape check.
- The combination step itself (which regex feeds which plugins, in what
  order) lives in `hooks.json`'s wiring, not in a new script — there is no
  separate "combination gate" binary, only configuration that combines the
  three independent, reusable plugins differently per facet. This is what
  keeps the three plugins independent: swapping how they combine (e.g., a
  future issue that gates only `data-quality-gate` on some narrower record)
  needs a `hooks.json` change only, never a change to the plugins themselves.

### 2.3 Why not a fourth "meta" plugin

A combination dispatcher was considered as its own plugin (`produces-gate`
wrapping the other three) and rejected: it would not own a methodology of its
own — it owns no content-shape check, only routing — so counting it as a
fourth "methodology plugin" would misrepresent issue #10's "방법론 1개 = 독립
플러그인 1개" requirement (there are exactly three adopted methodologies,
issue #1's three `PRODUCES` sub-fields; not four). The routing lives in
`hooks.json`'s existing `PreToolUse` array (multiple entries, one per plugin,
each independently scoped by its own facet regex) — no new script, no new
plugin identity.

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

## 4. Gate tests (repo root) — one test file per plugin, plus one combination file

New `tests/run-gate-tests.sh` as the shared subprocess-harness runner
(following `implementation-rulebook/tests/run-gate-tests.sh`'s pattern:
synthetic git worktree + synthetic `Write` tool-call JSON on stdin, asserting
exit code 0/2), invoking three per-plugin case files plus one combination
case file — kept separate so each plugin's tests stay independent of the
others', matching the plugin-set structure in section 2:

- `tests/pipeline-design-gate.test.sh`: one allow case (all required elements
  present), one deny case (one element missing), one allow case for
  proportionality N/A-with-reason, one deny case for a bare N/A with no
  reason.
- `tests/data-quality-gate.test.sh`: same four-case shape for its own
  elements.
- `tests/failure-handling-gate.test.sh`: same four-case shape for its own
  elements.
- `tests/produces-combination.test.sh`: one allow case for an out-of-scope
  path (foreign file, none of the three plugins fire), one allow case where
  all three plugins pass on a phase-1 proposal write, one deny case where
  exactly one plugin denies a phase-1 proposal write (asserts the deny names
  that plugin only), one allow/deny pair repeating the same two checks for a
  phase-2 record write.
- Minimum 12 deny/allow cases per-plugin (4 × 3) + minimum 4 combination
  cases = 16 total.

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
- `WRITE_SCOPE: []` unchanged — the three gate scripts and their tests are the
  role's own plugin/test assets, not new record write targets.
- Role boundary unchanged — each plugin only fires on this role's own write
  surfaces (section 2.2's two facet regexes), never a broader one.

## Plugin reflection plan (phase 2, post-Approve)

1. Add the three independent plugins from section 2.1:
   `data-engineering/hooks/pipeline-design-gate.sh`,
   `data-engineering/hooks/data-quality-gate.sh`,
   `data-engineering/hooks/failure-handling-gate.sh`.
2. Add three `PreToolUse` entries to `data-engineering/hooks/hooks.json`, one
   per plugin, each carrying its own facet-scoping regex — this is the
   combination step from section 2.2 (기획서 vs 산출물), expressed purely as
   wiring, not as a fourth script (section 2.3).
3. Replace `directive.sh`'s `PRODUCES` line with the facet-depth text from
   section 1 (kept as one string per `core_role_directive`'s four-argument
   signature — newline-joined within the `PRODUCES` argument, same technique
   already used for the existing `WRITE_SCOPE`+`HAND-OFF` multi-line arg).
4. Add `docs/handbooks/data-engineering/methodology.md` holding the fuller
   facet prose.
5. Add `tests/run-gate-tests.sh` plus the four per-plugin/combination test
   files from section 4.
6. Record this reflection as done in `docs/issue-10/reports/data-engineering.md`
   (phase-2 record, gated on Approve like any other phase-2 output).

## Open question for the approver

None — every element above traces to issue #1's already-adopted shape or to
the two exemplar gate patterns already landed elsewhere in this ecosystem
(pricing's content gate, implementation's stateful gate + test harness); no
alternative shape was left undecided.
