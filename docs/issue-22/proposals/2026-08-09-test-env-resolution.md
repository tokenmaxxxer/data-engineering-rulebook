---
status: proposed
files:
  - tests/lib/test_env_resolve.py
  - tests/lib/test_test_env_resolve.py
  - tests/run-gate-tests.sh
  - docs/specs/test-env-resolution.md
  - docs/handbooks/data-engineering/methodology.md
---

## Request
Adopt the canonical test-env resolution convention landed at
on-the-record `docs/specs/test-env-resolution.md` (issue #551) across
this rulebook's gate-test scripts: apply its resolution order
(`CLAUDE_PLUGIN_ROOT_CORE` -> caller-supplied sibling candidates -> SKIP)
and SKIP contract (stderr message, exit `75`) so that on a plain
checkout without core reachable, tests SKIP with an explicit message
instead of failing misleadingly — without weakening any assertion that
runs when core is reachable.

## Constraints
- SKIP contract exit code must be `75` (`EX_TEMPFAIL`), distinct from a
  gate's own 0/1/2 exits, per the convention doc.
- Every previously-passing assertion (with core reachable) must still
  pass unchanged.
- Scripts must reference the convention doc (grep-able for
  `test-env-resolution`).
- The module never clones over the network as part of the canonical
  SKIP path (convention doc, "Reference implementation" section) — a
  network-fetch fallback may only be layered on top as a repo-local
  extension, never substituted as the resolution mechanism itself.
- No CLAUDE_PLUGIN_ROOT_CORE-reachable behavior may regress:
  `gate-lib-compliance.test.sh`'s and `run-gate-tests.sh`'s existing
  compliance/harness assertions must be unchanged when core resolves.

## Rationale
Considered vendoring `gates/test_env_resolve.py` verbatim
(survey option A) vs. re-implementing the same order+SKIP contract
directly in bash inside `run-gate-tests.sh` (survey option B). Chose A:
vendor the reference module verbatim under `tests/lib/`, invoked as the
doc's prescribed "Bash test runner" CLI shape
(`python3 -m gates.test_env_resolve <candidates...>`, branch on exit
code). Rejected B because re-deriving the same logic in bash duplicates
a spec that already has a tested Python reference implementation and an
existing unit-test suite (`test_test_env_resolve.py`) covering five
named cases (env hit, sibling hit, env-set-but-missing-gate-lib
fallthrough, empty-stub-not-counted, SKIP outcome) — hand-rolling it in
bash means re-writing and re-verifying those same five cases with no
reference to check drift against, and the convention doc's own adoption
guidance for this exact consumer shape says to invoke the module, not
reimplement it. A third option (leave `run-gate-tests.sh`'s
network-fetch as the only resolution path, survey option C) was
rejected outright: it does not satisfy the issue's SKIP-contract
acceptance check on a plain checkout with no network, and the convention
doc explicitly places network-fetch outside its canonical contract.

## What will be done
- Vendor the convention's reference implementation verbatim as
  `tests/lib/test_env_resolve.py` (module path adjusted to be
  importable/runnable as `python3 -m tests.lib.test_env_resolve` from
  the repo root, or via direct `PYTHONPATH`-relative invocation from
  `run-gate-tests.sh` — mechanical packaging detail decided during
  build, not a design choice) together with its accompanying unit test
  `tests/lib/test_test_env_resolve.py`, both carrying a header comment
  naming their source (`on-the-record docs/specs/test-env-resolution.md`,
  issue #551) so the provenance is traceable and grep-able.
- Change `tests/run-gate-tests.sh`'s `setup_core_lib()`: first try
  resolution via the vendored module with candidates including the
  existing `.muster-cache/core-lib` path and any other plausible sibling
  checkout path (e.g. `../tokenmaxxxer-core/core`). If resolved (exit 0),
  use that path for `CLAUDE_PLUGIN_ROOT_CORE` and skip the network fetch
  entirely. If the module reports SKIP (exit 75) AND the existing
  network-fetch extension also cannot reach
  raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core (curl
  failure), print the convention's SKIP message to stderr, and the
  overall test run exits `75` — the whole run is reported skipped, not
  failed. The network-fetch stays as the repo-local extension the
  convention permits, tried only after direct resolution reports SKIP,
  never as a substitute for it.
- `tests/gate-lib-compliance.test.sh` is `source`d by `run-gate-tests.sh`
  only *after* `setup_core_lib()` returns (tests/run-gate-tests.sh:39,
  148-150); if `setup_core_lib()` exits `75` on SKIP, the `source` loop
  is never reached and `gate-lib-compliance.test.sh` never runs at all —
  so its own `curl` fetch cannot execute and needs no SKIP-state check
  of its own. It stays as-is: a bare `exit 1` on fetch failure is
  correct there, because reaching that line at all already implies core
  resolved successfully (this file's own network dependency for
  `compliance-check.sh` is not part of the core-resolution SKIP contract,
  and a genuine fetch failure there — e.g. upstream file
  moved/renamed — is a real defect, not masked). Consequently
  `tests/gate-lib-compliance.test.sh` is dropped from this proposal's
  write set; the SKIP contract is enforced once, centrally, in
  `run-gate-tests.sh`, before any `*.test.sh` file is sourced, so none
  of the six sourced test files need their own SKIP-awareness.
- Add a repo-local copy of `docs/specs/test-env-resolution.md`
  (mirroring the on-the-record source, with a header note naming its
  origin) so `grep -r test-env-resolution` succeeds locally per the
  issue's acceptance check, and cross-reference it from
  `docs/handbooks/data-engineering/methodology.md` under a short
  "test-env resolution" note (env var/setup-step-shaped, per the
  doctrine ladder — this is a testing convention affecting how
  contributors run tests locally).
- `tests/missing-core.test.sh` and the other `*.test.sh` files that only
  call the existing `assert_gate*` helpers are left untouched — the
  survey found no core-resolution logic in them to change.

## Out of scope
- Any change to the three gate hook scripts' own production
  `CLAUDE_PLUGIN_ROOT_CORE`-source-or-exit-2 guard (fail-closed at
  gate-invocation time) — that is production behavior, not test-env
  resolution, and the issue explicitly requires it stay unweakened.
- Adopting the convention in any other rulebook repo — out of scope per
  the convention doc itself ("separate work per repo").
- Changing `tests/missing-core.test.sh`'s deliberate empty-core-dir
  fixture, or any of the `assert_gate*` helper functions' signatures.
- Modifying the reference `gates/test_env_resolve.py` implementation's
  logic — it is vendored verbatim, not adapted.

## How you'll know it worked
- `CLAUDE_PLUGIN_ROOT_CORE` unset, no network reachable to
  raw.githubusercontent.com (simulate via an unreachable/blocked host or
  an invalid cache path): `tests/run-gate-tests.sh` exits `75` and its
  stderr contains the convention's exact SKIP message — no PASS/FAIL
  line implying a real gate assertion ran.
- With `CLAUDE_PLUGIN_ROOT_CORE` pointed at a real core checkout (or the
  existing network-fetch succeeding), all currently-passing assertions
  in `run-gate-tests.sh` and `gate-lib-compliance.test.sh` still pass
  with unchanged PASS/FAIL counts.
- `grep -r test-env-resolution tests/ docs/` returns hits in the changed
  test scripts and the repo-local spec copy.
- `python3 -m pytest tests/lib/test_test_env_resolve.py -q` passes
  (vendored unit test, run standalone).
