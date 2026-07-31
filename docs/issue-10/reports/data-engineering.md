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

1. Three independent, self-contained gate plugins (proposal section 2.1),
   each its own hook script + kill switch + test file, none depending on
   another's internals:
   - `data-engineering/hooks/pipeline-design-gate.sh` /
     `DATA_ENGINEERING_PIPELINE_DESIGN_GATE_OFF` /
     `tests/pipeline-design-gate.test.sh`
   - `data-engineering/hooks/data-quality-gate.sh` /
     `DATA_ENGINEERING_DATA_QUALITY_GATE_OFF` /
     `tests/data-quality-gate.test.sh`
   - `data-engineering/hooks/failure-handling-gate.sh` /
     `DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF` /
     `tests/failure-handling-gate.test.sh`

   Each resolves Write/Edit/MultiEdit content the same way, checks the write
   path against the two facet-scoping regexes
   (`^docs/issue-[0-9]+/proposals/.*data-engineering.*\.md$` and
   `^docs/issue-[0-9]+/reports/data-engineering\.md$`), denies (exit 2)
   naming its own missing element(s) or allows an N/A-with-reason pattern,
   and fails closed (denies) on any unparseable payload, unreadable file, or
   internal error.

2. Combination wiring (section 2.2/2.3): all three plugins registered as
   independent `PreToolUse` entries in `data-engineering/hooks/hooks.json` —
   no fourth "combination" plugin, since routing owns no methodology of its
   own.

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
   marketplace registration (`.claude-plugin/marketplace.json`) already
   covers the single `data-engineering` plugin that hosts these three gates
   — no new marketplace entry needed since no new plugin identity was
   created (section 2.3).

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
