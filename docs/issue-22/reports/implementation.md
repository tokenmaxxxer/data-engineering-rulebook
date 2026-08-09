---
code_under_review: N/A
type: feature
breaking: false
verdict: N/A
loop_state: committing
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

## Why
Basis: `docs/issue-22/proposals/2026-08-09-test-env-resolution.md`,
approved via issue comment `APPROVE issue-22/implementation`
(2026-08-09, JiwonJung94, listed in `docs/specs/approvers.md`).

## Upstream
docs/issue-22/proposals/2026-08-09-test-env-resolution.md

## What did not work
None.

## Open findings
None.

## Resolution path
N/A — no open findings.

## Next steps
Open a follow-up proposal covering `tests/gate-lib-compliance.test.sh`'s
SKIP-contract coverage gap (see Open findings / Resolution path above).

## Rationale for deviations
Scope-exceeded stop: the before-landing warrant hunt surfaced a real
SKIP-contract coverage gap in `tests/gate-lib-compliance.test.sh`, a file
outside this proposal's frozen `files:` write set. Per the
scope-exceeded rule, this session finished exactly what the proposal
covers and did not widen the write set to fix it mid-build; it is
recorded as an open finding with a resolution path (next proposal)
instead.
