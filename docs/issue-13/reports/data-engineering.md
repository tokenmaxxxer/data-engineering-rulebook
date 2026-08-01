---
subject: issue-13
role: data-engineering
---

# Record — A+ remediation of the three gate plugins (issue #13)

## Why

Phase 2, opened by the approver's issue comment `APPROVE
issue-13/data-engineering` (single-account mode, `docs/specs/approvers.md`)
on `docs/issue-13/proposals/2026-08-01-gate-remediation-a-plus.md`
(upstream basis). Reason: issue #13's real-code audit graded the three
gate plugins B- and required fixing every listed defect (dead relative-path
anchor, stdout-lost deny reasons, whole-document N/A exemption, zero
Edit/kill-switch/malformed-JSON test coverage), upgrading semantic checks
from substring to section/adjacency/structure, adding the mandatory test
cases, and resyncing the README — all gated on core issue #72's shared
gate-house library landing first (confirmed landed on
`tokenmaxxxer-core` `main` before implementation started).

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

Concrete artifacts delivered:

1. **Structural split**: each gate directory now holds a bash entrypoint
   (`<gate>-gate.sh`, ~10 lines: sources `core/hooks/lib/gate-lib.sh`,
   installs `gate_trap_fail_closed`, checks `gate_kill_switch_active`,
   execs the payload) plus the existing logic moved to `<gate>-gate.py`.
   `hooks.json` unchanged (filename identical).
2. Every defect from the survey fixed via `gate-lib` calls, not
   reimplementation — see the defect-map table and structural-change
   section below for the full detail (kept here rather than duplicated
   twice: absolute-path anchor via `gate_normalize_path`, stderr deny via
   `gate_deny`'s protocol, `replace_all`/MultiEdit/NotebookEdit via
   `gate_reconstruct_write`, malformed-JSON deny via
   `gate_parse_json_or_deny`, section-scoped N/A and semantic checks via a
   new `section_slice()` helper duplicated per gate payload — the section
   split is data-engineering's own PRODUCES semantics, out of core's
   scope per the proposal).
3. **Test additions**: 10 new mandatory cases per gate (30 total) covering
   `./`-prefixed and absolute paths, `Edit`/`MultiEdit` with mixed
   `replace_all`, three malformed-JSON shapes, and kill-switch
   recognized-vs-unrecognized values — plus a new
   `tests/gate-lib-compliance.test.sh` running core's
   `compliance-check.sh` against each gate's `hooks/` directory.
   `tests/run-gate-tests.sh` gained `assert_gate_tool`, `assert_gate_raw`,
   and `assert_gate_abs` harness helpers and now fetches `gate-lib.sh`/
   `gate-lib.py` into a gitignored `.muster-cache/core-lib/` cache,
   exporting `CLAUDE_PLUGIN_ROOT_CORE` at it for the test run.
   `tests/produces-combination.test.sh`'s fixtures were relabeled with the
   canonical PRODUCES sub-field labels the new section-scoping requires.
4. `README.md` resynced: documents the bash+Python pair per plugin, the
   `CLAUDE_PLUGIN_ROOT_CORE`/`GATE_LIB_PY` dependency on the sibling `core`
   plugin, and the new `gate-lib-compliance.test.sh` file.

### Defect-to-fix map

| # | Survey defect (`reports/data-engineering/survey.md`) | Fix |
|---|---|---|
| 1 | Absolute-path anchor never matches `^docs/...` — fail-open on absolute/`./`-prefixed writes | `in_scope()` now calls `gate_lib.gate_normalize_path(cwd, file_path)` in all three gates; relative, absolute, and `./`-prefixed paths normalize to the same root-relative tail |
| 2 | Deny reason written to stdout, not stderr | `deny()` in all three gates now writes `"<gate>: refused — <msg>"` to stderr and exits 2, matching `gate_deny`'s protocol byte-for-byte |
| 3 | One `N/A` line anywhere waives all three gates (whole-document `NA_RE.search`) | Added `section_slice()` per gate: scopes `NA_RE` and all element checks to the gate's own PRODUCES sub-field section, never the whole document |
| 4 | Zero Edit/MultiEdit/malformed-JSON/kill-switch coverage; `replace_all` silently ignored | `resolve_content()` replaced with `gate_lib.gate_reconstruct_write(...)` in all three gates — honors `replace_all` on `Edit` and per-edit on `MultiEdit`, adds `NotebookEdit` handling. 10 new mandatory test cases added per gate |
| 5 | No fail-closed EXIT trap; gates were pure-Python (no bash frame) | Each gate split into a bash entrypoint installing `gate_trap_fail_closed`/`gate_kill_switch_active` before Python starts |
| 6 | Semantic checks were bare substring/regex hits anywhere in the document | Section-slice scoping (defect #3's fix) plus each gate's element checks now operate within that slice only |
| 7 | README ghost content | None found in phase 1 (already clean); README now documents the bash+Python pair and new test file (forward sync) |

Kill-switch handling moved from each gate's hand-rolled
`os.environ.get(...).lower() in ("1","true","on")` (missing the `yes`
on-spelling) to `gate_kill_switch_active`, which recognizes
`1/true/yes/on` (case-insensitive) as the only disabling values — any
other value, including unrecognized garbage, stays active (fail-closed).

**Open item deferred, per the proposal's explicit flag**:
`gate_bash_write_targets` (Bash-tool write coverage) requires a
`hooks.json` matcher change (`Write|Edit|MultiEdit` → `+ |Bash`) the
proposal flagged for approver attention rather than pre-deciding — not
implemented in this pass; `hooks.json` is unchanged.

## Verification

`compliance-check.sh` run directly against each gate's `hooks/` directory,
post-migration:

```
=== pipeline-design-gate ===
compliance-check: ok — pipeline-design-gate/hooks/pipeline-design-gate.sh
rc=0
=== data-quality-gate ===
compliance-check: ok — data-quality-gate/hooks/data-quality-gate.sh
rc=0
=== failure-handling-gate ===
compliance-check: ok — failure-handling-gate/hooks/failure-handling-gate.sh
rc=0
```

No pre-migration baseline was captured: `compliance-check.sh` scans for
`*-gate.sh` bash-entrypoint files, which did not exist before this
migration (the pre-remediation gates were pure-Python shebang scripts with
no bash frame for the detector to scan).

Full suite, `bash tests/run-gate-tests.sh`:

```
gate tests: 60 passed, 0 failed
```

60 = 27 pre-existing cases (`produces-combination.test.sh` fixtures
relabeled as noted above, count unchanged) + 30 new mandatory cases (10
per gate) + 3 `gate-lib-compliance.test.sh` cases.

## Constraints honored

- Canon reference only: `core/hooks/lib/gate-lib.sh`/`gate-lib.py` and
  `core/hooks/tests/compliance-check.sh` are referenced (sourced/imported/
  fetched at test time into a gitignored cache), never vendored into this
  repo.
- `WRITE_SCOPE: []` unchanged — this record plus the gate/test/README
  assets it documents are this role's own plugin/test/doc surface, not a
  new write target.
- `hooks.json` matcher scope (`Write|Edit|MultiEdit`) left unchanged per
  the proposal's explicit deferral of the Bash-tool-coverage open question
  to approver attention rather than unilateral decision.

## Loop state

loop_state: landed

All four issue requirements (defect fixes, semantic-check upgrade,
mandatory test cases with full-suite green, README resync) implemented
and verified; no further phase-2 steps remain from the approved proposal.

## Open findings

None carried from the proposal. One scope decision was deliberately left
unimplemented rather than resolved unilaterally: Bash-tool write coverage
via `gate_bash_write_targets` needs a `hooks.json` matcher change the
proposal flagged for approver attention — noted above, not a defect in
this delivery, a follow-up the approver may choose to open as a new issue.
