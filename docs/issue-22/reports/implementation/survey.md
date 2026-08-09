# Survey: adopt test-env resolution convention (issue #22)

## Scout skip record
Skip condition: spec leaves no design decision open. The convention doc
(on-the-record `docs/specs/test-env-resolution.md`, issue #551) fixes the
resolution order, the SKIP contract (message + exit 75), and the
per-consumer-shape adoption pattern (this repo is the named "Bash test
runner" shape). Adoption is applying a fixed spec, not choosing a design —
no product/library scouting applies.

## Convention doc (fetched via `gh api repos/tokenmaxxxer/on-the-record/contents/docs/specs/test-env-resolution.md`)
- Resolution order: `$CLAUDE_PLUGIN_ROOT_CORE` (if it contains a non-empty
  `hooks/lib/gate-lib.sh`) -> first caller-supplied sibling-checkout
  candidate with a non-empty `hooks/lib/gate-lib.sh` -> SKIP.
- SKIP contract: print `SKIP: core plugin unreachable — unverifiable
  outside spawn env` to stderr, exit `75` (`EX_TEMPFAIL`), distinct from a
  gate's own 0/1/2 exits.
- Reference implementation: `gates/test_env_resolve.py` in the
  on-the-record repo (`resolve_core()` + CLI wrapper). Not vendored
  anywhere in this repo currently.
- Bash test runner adoption: invoke as
  `python3 -m gates.test_env_resolve <candidates...>`, branch on exit
  code (0 = resolved path on stdout, 75 = skip whole run).
- Convention explicitly calls out a "network-fetch fallback (as one
  rulebook's ad hoc script does)" as a repo-local extension a consumer
  MAY layer on top of step 2 — not part of the canonical SKIP contract.
  This repo's `tests/run-gate-tests.sh` is that ad hoc script.
- Empty-state exception: a test suite with no core dependency at all is
  out of scope for the convention (none of this repo's suites are like
  that — every gate test needs `gate-lib.sh`).

## This repo's current-state (write set candidates)
- `tests/run-gate-tests.sh`: `setup_core_lib()` unconditionally `curl -fsS`
  fetches `gate-lib.sh`/`gate-lib.py` from
  `raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core` into
  `.muster-cache/core-lib`, sets `CLAUDE_PLUGIN_ROOT_CORE` to that cache,
  and on curl failure prints an error and `exit 1` — an ordinary FAIL, not
  a SKIP. On a plain checkout with no network reachable to
  raw.githubusercontent.com, this is the misleading failure the issue
  describes (looks like a delivery regression, is actually environment).
  No `CLAUDE_PLUGIN_ROOT_CORE`-set / sibling-checkout path is tried before
  reaching for the network.
- `tests/gate-lib-compliance.test.sh`: separately `curl -fsS` fetches
  `compliance-check.sh` from the same GitHub raw host into
  `.muster-cache/core-lib/hooks/tests/`, with the same `exit 1`-on-failure
  shape. Sourced by `run-gate-tests.sh` after `setup_core_lib` has already
  run, so by the time this file's curl fires, `CLAUDE_PLUGIN_ROOT_CORE` is
  already set (successfully or not) by the caller.
- `tests/missing-core.test.sh`: does NOT touch core resolution — it
  deliberately points `CLAUDE_PLUGIN_ROOT_CORE` at an empty directory to
  exercise each gate's own fail-closed guard. Out of scope; unaffected by
  this convention (it is testing the opposite path, "core resolved to
  something without gate-lib.sh").
- `tests/{data-quality,pipeline-design,failure-handling}-gate.test.sh`,
  `tests/produces-combination.test.sh`, `tests/bash-write-coverage.test.sh`:
  no core-resolution logic of their own — all call the `assert_gate*`
  helpers defined in `run-gate-tests.sh`, which already has
  `CLAUDE_PLUGIN_ROOT_CORE` exported by the time they run. No changes
  needed in these files themselves.
- No repo-local copy of `gates/test_env_resolve.py` exists yet. The three
  gate hook scripts (`pipeline-design-gate/hooks/*.sh`,
  `data-quality-gate/hooks/*.sh`, `failure-handling-gate/hooks/*.sh`,
  `data-engineering/hooks/directive.sh`) already do their own
  `CLAUDE_PLUGIN_ROOT_CORE`-based source-or-exit-2 guard at gate-invocation
  time — that is production fail-closed behavior, not test-env resolution,
  and is explicitly out of scope per the issue body ("Do not weaken any
  assertion that runs when core IS reachable" / this is about the test
  scripts, not the gates themselves).

## Alternatives considered (for the coming proposal's Rationale)
- **A: Vendor `gates/test_env_resolve.py` verbatim into this repo**
  (e.g. `tests/lib/test_env_resolve.py`) and call it as the doc's "Bash
  test runner" shape prescribes.
- **B: Re-implement the same order+SKIP contract directly in bash inside
  `run-gate-tests.sh`**, without vendoring the Python reference module.
- **C: Do nothing beyond adding a `docs/specs/test-env-resolution.md`
  pointer/copy and leave `run-gate-tests.sh`'s network-fetch as the only
  resolution path**, since the convention allows a network-fetch
  extension.

Option C fails the issue's explicit acceptance checks (SKIP contract on a
plain checkout without network/env, zero misleading failures) so it is
not viable as the primary path — network reachability is not "core
resolved," and per the doc a network fetch is explicitly not part of the
canonical SKIP contract. Decision between A and B belongs in the
proposal's Rationale section.
