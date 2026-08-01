---
subject: issue-16
role: data-engineering
---

# Record — Gate A+ final closeout, residual defect remediation (issue #16)

## Why

Phase 2, opened by the approver's issue comment `APPROVE
issue-16/data-engineering` (single-account mode, `docs/specs/approvers.md`)
on `docs/issue-16/proposals/data-engineering.md` (upstream basis). Reason:
the 2026-08-01 re-audit graded the three PRODUCES gate plugins B+ and
required fixing every residual defect, resyncing `hooks.json`
matcher/code coverage, adding a missing-core test case, passing
compliance-check, and confirming zero stale role names/ghost files — all
gated on core issue #75 (source-guard mandate, compliance-check detection,
`gate_bash_write_targets.py`) confirmed landed on `tokenmaxxxer-core`
`main` before this pass started (verified by fetching `gate-lib.sh`/
`gate-lib.py`/`compliance-check.sh` directly; core #75 shows `closed` on
GitHub).

## What was done

No pipeline design, data-quality check list, or failure-handling plan
applies to this delivery itself — remediating existing gate scripts is not
a pipeline source/transform/sink change:

- Pipeline design: N/A, this record documents fixing the gate plugins'
  internal correctness, not a pipeline change.
- Data-quality check list: N/A, same reason — no dataset or schema touched.
- Failure-handling plan: N/A, same reason — the fail-closed behavior fixed
  here is the gate scripts' own PreToolUse posture, not a pipeline failure
  mode.

### Defect-to-fix map (per `docs/issue-16/proposals/data-engineering.md`)

| # | Defect | Fix |
|---|---|---|
| 1 | `NA_RE`/`OWN_LABEL_RE`/`OTHER_LABEL_RES`/`section_slice()` byte-identical across all three gate payloads | Extracted into new `data-engineering/hooks/lib/produces-sections.py`, loaded by each gate via `importlib.util.spec_from_file_location` against a path resolved relative to the gate's own directory, mirroring `gate-lib.py`'s load pattern. Each gate `.py` now keeps only its own gate-specific regexes (`ARROW_RE`/`FLOW_RE`/`OWNER_RE`/`CHANGE_RE`, etc.) and imports the shared `NA_RE`, per-sub-field label regexes, and `section_slice()` |
| 2 | README/methodology overstated `NotebookEdit` as covered | `README.md` and `docs/handbooks/data-engineering/methodology.md` corrected to state the narrower true claim (`Edit`/`MultiEdit`/`replace_all` reconstruction only; `NotebookEdit` support exists in `gate-lib.py` but no matcher includes it) and cross-reference the new coverage table |
| 3 | `.muster-cache` documented as "gitignored" with no `.gitignore` anywhere in the repo | Added repo-root `.gitignore` containing `.muster-cache/` (proposal's primary remedy) — the documented claim is now true |
| 4 (hooks.json parity, `Bash`) | Bash-tool writes bypassed all three gates entirely (deferred since issue #13) | All three `hooks.json` matchers changed `Write\|Edit\|MultiEdit` → `Write\|Edit\|MultiEdit\|Bash` in lockstep with code: each gate's `main()` gained a `tool_name == "Bash"` branch calling `gate_lib.gate_bash_write_targets(command)` (core #75's Python port) and denying unconditionally if any extracted token falls in-scope — content from an arbitrary shell command can't be deterministically reconstructed, so this is a fail-closed deny, not a best-effort check |
| 4 (hooks.json parity, `NotebookEdit`) | `NotebookEdit` code-reachable via `gate_reconstruct_write` but unmatched | Left unmatched by design (proposal's chosen remedy): no established workflow authors PRODUCES docs via NotebookEdit; adding the matcher without real fixtures would just relocate the overstatement. Documented as an explicit, deferred gap in README's coverage table, not silently dropped |
| core #75 source-guard (issue #16 common precondition) | All three `<gate>-gate.sh` sourced `gate-lib.sh` with no `\|\|` guard — `compliance-check.sh`'s new detector flags this as fail-open-on-unreachable-core | Added `\|\| { echo "<gate>.sh: cannot source gate-lib.sh" >&2; exit 2; }` to each `<gate>-gate.sh`'s source line, per `gate-lib.sh`'s own updated usage docstring |
| Missing-core test case | No test exercised "core lib absent → gate must still deny" | New `tests/missing-core.test.sh`: one case per gate, `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent directory, asserts exit 2 (not a crash, not exit 0) |
| Old role names / ghost files (requirement 4) | Phase-1 survey found no stale role names or dangling file references, but noted this checkout has no canonical 43-role taxonomy list to mechanically cross-check `data-modeling` against | No taxonomy source appeared during phase 2 either — manual re-scan of `README.md` and all four `.claude-plugin/plugin.json` manifests in this pass confirms the same result: only `data-engineering` (self) and `data-modeling` (hand-off target) appear as role names, and every file path `README.md` documents is present on disk. This remains a stated gap (not a fabricated clean bill of health), unchanged from the phase-1 survey — see "Open findings" below |

### Test additions

`tests/missing-core.test.sh` (3 cases) and `tests/bash-write-coverage.test.sh`
(4 cases: one deny per gate on an in-scope Bash write, plus one pass-through
on an out-of-scope Bash write) — 7 new cases total.

## Verification

`compliance-check.sh` run directly against each gate's `hooks/` directory,
post-remediation:

```
compliance-check: ok — pipeline-design-gate/hooks/pipeline-design-gate.sh
compliance-check: ok — data-quality-gate/hooks/data-quality-gate.sh
compliance-check: ok — failure-handling-gate/hooks/failure-handling-gate.sh
```

Full suite, `bash tests/run-gate-tests.sh`:

```
gate tests: 67 passed, 0 failed
```

67 = 60 pre-existing (issue #13 baseline, unchanged) + 3 missing-core cases
+ 4 Bash-write-coverage cases. `tests/gate-lib-compliance.test.sh`'s 3
existing `assert_compliance` cases (included in the 60) now also cover the
source-guard structural check core #75 added to `compliance-check.sh`, with
no code change needed in this repo for that detection rule itself.

## Constraints honored

- Canon reference only: `core/hooks/lib/gate-lib.sh`/`gate-lib.py` and
  `core/hooks/tests/compliance-check.sh` are referenced (sourced/imported/
  fetched at test time into a gitignored cache), never vendored into this
  repo. `gate_bash_write_targets` is called through `gate_lib`, not
  reimplemented.
- The new `produces-sections.py` extraction is owned by `data-engineering`
  (this role's own PRODUCES sub-field semantics), not miscategorized as
  core's responsibility, per the proposal's explicit scoping.
- `WRITE_SCOPE: []` unchanged — this record plus the gate/test/README/lib
  assets it documents are this role's own plugin/test/doc surface, not a
  new write target.
- `hooks.json` matcher changes (`+ Bash`) landed strictly in lockstep with
  the corresponding code branch in all three gates — no matcher advertises
  a tool the code cannot handle, no code branch exists for a tool
  `hooks.json` doesn't route to it.

## Loop state

loop_state: landed

All four issue #16 requirements (residual defects fixed, `hooks.json`
matcher/code parity, missing-core case with full-suite green, README/
manifest hygiene) implemented and verified against the approved proposal;
no further phase-2 steps remain.

## Open findings

- Canonical 43-role taxonomy source still absent from this checkout: the
  `data-modeling` hand-off reference cannot be mechanically cross-checked
  from within this repo alone (carried forward unchanged from the phase-1
  survey, not a new finding). Recommend a lightweight follow-up by a role
  with access to the taxonomy source.
- `NotebookEdit` hooks.json coverage remains an explicit, documented gap
  (proposal's chosen remedy, not a defect) — a future issue should scope
  matcher change + real fixtures if NotebookEdit-authored PRODUCES
  documents become a real workflow.
