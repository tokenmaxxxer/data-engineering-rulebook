---
code_under_review:
  - tests/lib/test_env_resolve.py
  - tests/lib/test_test_env_resolve.py
  - tests/run-gate-tests.sh
  - docs/specs/test-env-resolution.md
  - docs/handbooks/data-engineering/methodology.md
  - tests/gate-lib-compliance.test.sh
type: feature
breaking: false
verdict: N/A
loop_state: landed
---

# Implementation record: issue #22

## Summary of work
Vendored the on-the-record canonical test-env resolution convention
(`docs/specs/test-env-resolution.md`, issue #551) into this repo per the
approved proposal `docs/issue-22/proposals/2026-08-09-test-env-resolution.md`:
- `tests/lib/test_env_resolve.py` — verbatim reference resolver + CLI.
- `tests/lib/test_test_env_resolve.py` — verbatim accompanying unit test.
- `tests/run-gate-tests.sh` — `setup_core_lib()` now tries the module's
  resolution order first (env var, then sibling candidates), and only
  falls back to the existing network-fetch extension when the module
  reports SKIP; if the network-fetch also fails, the whole run exits `75`
  with the convention's SKIP message instead of `exit 1`.
- `docs/specs/test-env-resolution.md` — repo-local copy of the convention
  doc, header-noted with its origin.
- `docs/handbooks/data-engineering/methodology.md` — cross-reference note.

### Follow-up: gate-lib-compliance.test.sh SKIP-contract gap (this continuation)
A live check (running every script under `tests/` with
`CLAUDE_PLUGIN_ROOT_CORE` unset) confirmed the before-landing hunt finding
above: `tests/gate-lib-compliance.test.sh` fetches
`compliance-check.sh` over the network with a bare
`curl ... || { echo ...; exit 1; }`, so a sibling-checkout resolution
(core reachable, no network needed for core itself) that still can't
reach the network for this one file FAILed (exit 1) instead of SKIPping
(75) — a real defect, not something to mask. Fixed by giving that fetch
failure the same SKIP contract: on curl failure it now prints
`SKIP: compliance-check.sh unreachable — unverifiable outside spawn env`
to stderr and exits `75` (`EX_TEMPFAIL`), instead of `exit 1`. No
assertion that runs when the fetch succeeds was touched.
Verified: reran the hunt's own repro (sibling-checkout core, network
`curl` stubbed to fail) — now exits `75` with the SKIP message instead of
`1`; reran the full suite with real network access (`tests/run-gate-tests.sh`,
`CLAUDE_PLUGIN_ROOT_CORE` unset) — unchanged `74 passed, 0 failed`.

A before-landing warrant hunt on that fix (stance 3, same hunt record)
caught a second problem the first fix introduced: `gate-lib-compliance.test.sh`
is `source`d into `run-gate-tests.sh`'s own shell alongside every other
`*.test.sh` file, so its `exit 75` terminated the *entire* runner —
discarding PASS/FAIL counts already accumulated by earlier-sourced files
and silently skipping every file still to come
(`missing-core.test.sh`, `pipeline-design-gate.test.sh`,
`produces-combination.test.sh`), with no final summary line ever
printed. Fixed by changing `exit "$EX_TEMPFAIL"` to `return 0` (valid
since the file is sourced, not executed) plus a new `SKIPPED` counter
(incremented by 3, one per compliance case) that `run-gate-tests.sh`
reports in its final summary line when non-zero
(`"$PASS passed, $FAIL failed, $SKIPPED skipped (unverifiable outside
spawn env)"`) instead of silently dropping those cases from the count.
Verified with a `curl` stub that fails only the compliance-check.sh URL
(real `gate-lib.sh`/`gate-lib.py` fetched and resolved normally): all 71
other real assertions still ran and passed, the 3 compliance cases
skipped and were reported (`71 passed, 0 failed, 3 skipped`), overall
exit `0` — no more whole-run termination, no assertion weakened. Real
network path re-verified unchanged (`74 passed, 0 failed`).

## Why
Basis: `docs/issue-22/proposals/2026-08-09-test-env-resolution.md`,
approved via issue comment `APPROVE issue-22/implementation`
(2026-08-09, JiwonJung94, listed in `docs/specs/approvers.md`).

## Upstream
docs/issue-22/proposals/2026-08-09-test-env-resolution.md

## What did not work
None.

### Amendment: bash-write-coverage.test.sh standalone-execution defect (record-only, unfixed)
A live check running `bash tests/bash-write-coverage.test.sh` directly
(core reachable, no env issue) fails with `assert_gate_tool: command not
found` at every `assert_gate_tool` call in the file. This is a real,
pre-existing defect, not an environment artifact: `assert_gate_tool` is
defined only in `tests/run-gate-tests.sh` (see line ~92 there), and
`tests/bash-write-coverage.test.sh` is written to be `source`d by that
runner, not executed on its own — but nothing in the file states that
constraint, so a standalone invocation fails hard instead of failing
clearly or refusing to run standalone. Confirmed `bash
tests/run-gate-tests.sh` (the intended entry point) still passes clean
(`74 passed, 0 failed`), so this is specific to standalone execution of
the sourced fixture file. Left unfixed here: out of this record's frozen
`code_under_review:` write set, and the fix (either a sourced-only guard
or a doc comment) is a design choice for the owning proposal, not a
one-line follow-up like the gate-lib-compliance fix above. Not masked or
worked around.

## Open findings
- `tests/bash-write-coverage.test.sh` fails when executed standalone
  (`assert_gate_tool: command not found`) because it depends on being
  sourced by `tests/run-gate-tests.sh` for that function's definition,
  with no guard or doc note preventing/explaining standalone execution.
  See amendment subsection above. Real defect, not env-specific.

## Resolution path
The standalone-execution defect in `tests/bash-write-coverage.test.sh`
needs a follow-up proposal (new issue or phase-1 addendum) to decide the
fix shape — either a `[[ "${BASH_SOURCE[0]}" == "$0" ]]` guard that
errors with a clear "must be sourced by run-gate-tests.sh" message, or a
header comment plus CI/test-runner enforcement. Not resolved in this
record; `tests/run-gate-tests.sh` (the real entry point) is unaffected
and still passes.

## Next steps
File a follow-up issue for the `bash-write-coverage.test.sh`
standalone-execution defect noted above; the previously-open
`tests/gate-lib-compliance.test.sh` finding remains resolved (see
follow-up subsection above).

## Rationale for deviations
This continuation session was explicitly directed (by the issue owner,
same branch/PR) to close the gap this record's earlier revision left as
an open finding rather than opening a fresh phase-1 proposal for a
one-file, already-diagnosed fix. `tests/gate-lib-compliance.test.sh` is
therefore added to `code_under_review:` beyond the original proposal's
frozen list — a deliberate widening authorized by the issue owner for
this specific, previously-identified gap, not a mid-build scope
expansion discovered on its own.
