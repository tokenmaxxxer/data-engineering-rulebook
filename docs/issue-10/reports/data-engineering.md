---
subject: issue-10
role: data-engineering
---

# Record — plugin-set delivery for issue #10

## Why

Phase 2, opened by the approver's issue comment `APPROVE
issue-10/data-engineering` on
`docs/issue-10/proposals/methodology-gate-and-directive-depth.md` (upstream
basis). Reason: that proposal requires formalizing enforcement of issue #1's
already-adopted `PRODUCES` sub-fields as a **plugin set** — one methodology =
one independent plugin, each self-contained (hook + kill switch + tests),
combined per facet (phase-1 proposal vs phase-2 record) via thin `hooks.json`
wiring rather than one fused script (reviewer feedback on PR #11, restated in
the approved proposal's revision note).

## What was done

No pipeline design, data-quality check list, or failure-handling plan
applies to this delivery itself — this issue formalizes enforcement of an
already-adopted methodology, it does not change a pipeline:

- Pipeline design: N/A, this record documents building the methodology gate
  infrastructure itself, not a pipeline source/transform/sink change.
- Data-quality check list: N/A, same reason — no dataset or schema is
  touched by this delivery.
- Failure-handling plan: N/A, same reason — the "failure modes" here are the
  gate scripts' own fail-closed behavior, covered below, not a pipeline
  failure mode.

Concrete artifacts delivered:

1. Three independent, self-contained gate **plugins** — each its own
   top-level plugin directory with its own `.claude-plugin/plugin.json`,
   own `hooks/hooks.json`, own hook script, own kill switch, own test file,
   none depending on another's internals or on the `data-engineering`
   plugin's internals:
   - `pipeline-design-gate/` (`hooks/pipeline-design-gate.sh` /
     `DATA_ENGINEERING_PIPELINE_DESIGN_GATE_OFF` /
     `tests/pipeline-design-gate.test.sh`)
   - `data-quality-gate/` (`hooks/data-quality-gate.sh` /
     `DATA_ENGINEERING_DATA_QUALITY_GATE_OFF` /
     `tests/data-quality-gate.test.sh`)
   - `failure-handling-gate/` (`hooks/failure-handling-gate.sh` /
     `DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF` /
     `tests/failure-handling-gate.test.sh`)

   Each resolves Write/Edit/MultiEdit content the same way, checks the write
   path against the two facet-scoping regexes
   (`^docs/issue-[0-9]+/proposals/.*data-engineering.*\.md$` and
   `^docs/issue-[0-9]+/reports/data-engineering\.md$`), denies (exit 2)
   naming its own missing element(s) or allows an N/A-with-reason pattern,
   and fails closed (denies) on any unparseable payload, unreadable file, or
   internal error.

   Revised after reviewer FEEDBACK on this PR (structure check): the first
   pass of this delivery put all three gates inside `data-engineering/hooks/`
   as an internal branch of the single `data-engineering` plugin. That is
   not the plugin-set the approved proposal specifies — "one methodology =
   one independent plugin" means each gate is its own top-level plugin,
   independently addable/removable/toggleable via marketplace registration,
   not a script living inside another plugin's directory. Moved accordingly;
   `data-engineering/hooks/` now holds only `directive.sh` (its own
   `SessionStart` concern, unrelated to the three gates).

2. Combination wiring (section 2.2/2.3): each plugin registers its own
   independent `PreToolUse` entry in its own `hooks/hooks.json` — no fourth
   "combination" plugin, since routing owns no methodology of its own. The
   phase-1/phase-2 facet combination is expressed structurally: all three
   plugins share the same two facet-scoping regexes baked into each gate
   script, so any write matching either regex passes through all three
   independently-installed plugins.

3. Directive-depth text (section 1): `data-engineering/hooks/directive.sh`'s
   `PRODUCES` argument replaced with facet-level (phase 1 / phase 2) text,
   plus the fuller prose home `docs/handbooks/data-engineering/methodology.md`
   (mirroring `pricing-rulebook`'s own methodology handbook — canon
   reference only, no copy).

4. Test harness (section 4): `tests/run-gate-tests.sh` (synthetic-worktree
   subprocess runner) plus one test file per plugin (4 cases each: allow,
   deny, N/A-with-reason allow, bare-N/A deny) and one combination test file
   `tests/produces-combination.test.sh` (out-of-scope allow, all-pass allow,
   one-plugin-deny, phase-2 allow/deny pair) — 27 cases total, all passing
   (`bash tests/run-gate-tests.sh`).

5. `README.md` updated with the plugin table and test-run instructions;
   marketplace registration (`.claude-plugin/marketplace.json`) now lists
   four plugin entries — `data-engineering` plus the three independent gate
   plugins (`pipeline-design-gate`, `data-quality-gate`,
   `failure-handling-gate`), each with its own `source` pointing at its own
   top-level directory.

## Constraints honored

- Canon reference only: pricing's `methodology-gate.sh` structural template
  and its own `methodology.md` handbook are referenced, not copied; no
  canon script or file content was duplicated into this repo.
- `WRITE_SCOPE: []` unchanged — this record file is the only write target;
  the gate scripts, tests, handbook, and README are the role's own
  plugin/test/doc assets, not new record write targets.
- Role boundary unchanged — each plugin only fires on this role's own two
  facet write surfaces, never a broader one.

## Loop state

loop_state: landed

Plugin set implemented, wired, tested (27/27 passing), documented; no
further phase-2 steps remain from the approved proposal's reflection plan.

## Open findings

None. Every element traces to the approved proposal; no open question was
left for the approver in that proposal, and none surfaced during
implementation.
