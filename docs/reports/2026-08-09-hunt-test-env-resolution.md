---
proposal: docs/issue-22/proposals/2026-08-09-test-env-resolution.md
---

# Hunt record — test-env-resolution

## after-proposal — stance 0: assume the gate/contract just written is bypassable — find the bypass

Verdict: FINDING — the plan's SKIP-state propagation from run-gate-tests.sh into gate-lib-compliance.test.sh is unreachable dead code, because run-gate-tests.sh's own SKIP path (exit 75 inside setup_core_lib) terminates the process before the `for f in tests/*.test.sh; do source "$f"; done` loop that sources gate-lib-compliance.test.sh ever runs.
Kind: design-error
Seed: docs/issue-22/proposals/2026-08-09-test-env-resolution.md ("What will be done" bullets 2-3); tests/run-gate-tests.sh; tests/gate-lib-compliance.test.sh
cap_seconds: 60
tier: default
diff_stat_lines: docs-only proposal+survey (small)
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:01:00Z

### Reproduce
Read tests/run-gate-tests.sh control flow:
```
setup_core_lib   # line ~28, currently: on unrecoverable failure -> exit 1 (top-level, unconditional call before the loop)
export CLAUDE_PLUGIN_ROOT_CORE=...
...
for f in "$ROOT_DIR"/tests/*.test.sh; do   # line 148
  source "$f"                              # line 150 — this is where gate-lib-compliance.test.sh's
                                            # top-level curl-fetch code actually executes
done
```
The proposal states (What will be done, bullet 2) that on SKIP, `run-gate-tests.sh`'s own resolution logic "print[s] the convention's SKIP message to stderr, and the overall test run exits `75`" directly from `setup_core_lib`/its call site — i.e. before the `for` loop at line 148 is ever reached. Bullet 3 then separately proposes that `gate-lib-compliance.test.sh`'s own fetch-failure path "check[s] whether the run is already in SKIP state (propagated from run-gate-tests.sh) and, if so, skip rather than fail." But `gate-lib-compliance.test.sh` only executes at all via the line-148/150 `source` loop — a loop the process never reaches once it has exited 75. There is no execution path in which `gate-lib-compliance.test.sh`'s SKIP-state check can ever run, because by the time it would run, the interpreter has already terminated.

### Observed
The plan describes a runtime check ("if so, skip rather than fail") inside a file whose only entry point is unreachable in exactly the scenario (SKIP) the check exists to handle. As specified, this is either (a) dead code that can never execute, giving a false sense that the compliance file has its own SKIP handling, or (b) evidence that `run-gate-tests.sh` must NOT actually exit 75 immediately in setup_core_lib and must instead defer to the loop with a propagated flag variable — but the proposal's "How you'll know it worked" section explicitly asserts `run-gate-tests.sh` itself "exits 75" with "no PASS/FAIL line implying a real gate assertion ran," which is only true if it exits before sourcing any `*.test.sh` file (since those files run assertions and print PASS/FAIL, e.g. gate-lib-compliance.test.sh's `assert_compliance` calls at the bottom of the file, and other sourced `*.test.sh` files' own PASS/FAIL-producing assertions).

### Expected
The proposal should specify one consistent control-flow: either (1) run-gate-tests.sh detects SKIP and exits immediately, in which case gate-lib-compliance.test.sh's "check whether already in SKIP state" logic is unreachable and should not be described as a real safeguard (and should instead be deleted/simplified since it can never fire), or (2) run-gate-tests.sh sets a shell-visible SKIP flag and continues through the sourcing loop so each sourced `*.test.sh` file (not just gate-lib-compliance.test.sh) can check it and skip its own assertions before exiting 75 only at the very end — but then the "no PASS/FAIL line" guarantee in "How you'll know it worked" is at risk unless every other `*.test.sh` file (pipeline-design-gate.test.sh, data-quality-gate.test.sh, failure-handling-gate.test.sh, missing-core.test.sh, bash-write-coverage.test.sh, produces-combination.test.sh) is also modified to check the same flag — none of which the proposal's file list or "What will be done" section mentions.

## before-landing — stance 4: assume the write set cannot carry this work — find the path the build will need that the proposal does not list

Verdict: FINDING — gate-lib-compliance.test.sh's hardcoded network fetch of compliance-check.sh (path `.muster-cache/core-lib/hooks/tests/compliance-check.sh`) is excluded from the proposal's write set on the theory that "reaching that line already implies core resolved successfully", but with the new resolver core can now resolve via a sibling checkout with zero network access — so a fully offline dev environment that has a sibling core checkout (exactly the scenario the resolver exists to serve) resolves core fine, then hits this untouched file's bare `curl ... || exit 1` and the whole run FAILs (exit 1), not SKIPs (75), contradicting the convention's SKIP contract this proposal is adopting.
Kind: design-error
Seed: docs/issue-22/proposals/2026-08-09-test-env-resolution.md; tests/run-gate-tests.sh diff (setup_core_lib rewrite); tests/gate-lib-compliance.test.sh (untouched, out of write set per proposal lines 80-93)
cap_seconds: 180
tier: default
diff_stat_lines: 392 insertions (6 files changed per `git diff --cached --stat`)
started_at: 2026-08-09T09:51:33+09:00
ended_at: 2026-08-09T09:54:02+09:00

### Reproduce
```
cd /home/jwjung/.tokenmaxxxer/work/data-engineering-rulebook-issue-22-implementation
rm -rf .muster-cache
mkdir -p /tmp/fakecore/hooks/lib /tmp/fakebin
printf '#!/usr/bin/env bash\n' > /tmp/fakecore/hooks/lib/gate-lib.sh   # non-empty stub, size>0
printf 'x=1\n' > /tmp/fakecore/hooks/lib/gate-lib.py
chmod +x /tmp/fakecore/hooks/lib/gate-lib.sh
printf '#!/bin/bash\necho "curl: could not resolve host" >&2\nexit 6\n' > /tmp/fakebin/curl   # simulate offline
chmod +x /tmp/fakebin/curl
CLAUDE_PLUGIN_ROOT_CORE=/tmp/fakecore PATH=/tmp/fakebin:/usr/bin:/bin:/usr/local/bin bash tests/run-gate-tests.sh
echo "EXIT:$?"
```

### Observed
```
...
curl: could not resolve host
gate-lib-compliance.test.sh: failed to fetch compliance-check.sh
EXIT:1
```
Core resolved via the sibling-checkout candidate (`CLAUDE_PLUGIN_ROOT_CORE=/tmp/fakecore`, no network call made for gate-lib.sh/py — only one curl invocation occurred, for compliance-check.sh), yet the run terminates with exit 1 (a real FAIL), not exit 75 (SKIP) with the convention's SKIP message.

### Expected
Per docs/specs/test-env-resolution.md's SKIP contract (and this proposal's own "How you'll know it worked" criterion: "no network reachable ... run-gate-tests.sh exits 75"), any network-unreachability that blocks the gate-house test suite from producing a meaningful PASS/FAIL should SKIP (exit 75), not FAIL (exit 1) — the compliance-check.sh fetch path in tests/gate-lib-compliance.test.sh needed to be brought under the same resolution/SKIP contract (or SKIP-aware) but was left out of the proposal's write set based on a since-invalidated assumption (that reaching that line implies network was already proven reachable, which is no longer true once core-resolution can succeed without any network access).

## before-landing — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the just-added `exit 75` in tests/gate-lib-compliance.test.sh terminates the entire run-gate-tests.sh process instead of skipping just that one test file, because run-gate-tests.sh sources every `*.test.sh` file with `source "$f"` in the same shell (no subshell/exec), so any `exit` inside a sourced file exits the whole runner — silently discarding all FAIL counts accumulated so far and skipping every remaining test file in the glob (missing-core.test.sh, pipeline-design-gate.test.sh, produces-combination.test.sh alphabetically after gate-lib-compliance.test.sh), with no summary line ever printed.
Kind: composition
Seed: git diff HEAD -- tests/gate-lib-compliance.test.sh docs/issue-22/reports/implementation.md
cap_seconds: 90
tier: default (size:small)
diff_stat_lines: ~15
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:05:00Z

### Reproduce
```
mkdir -p /tmp/claude-1000/fakebin /tmp/claude-1000/fakecore/hooks/lib
printf '#!/bin/bash\nexit 7\n' > /tmp/claude-1000/fakebin/curl
chmod +x /tmp/claude-1000/fakebin/curl
printf '#!/bin/bash\ntrue\n' > /tmp/claude-1000/fakecore/hooks/lib/gate-lib.sh
printf '# stub\n' > /tmp/claude-1000/fakecore/hooks/lib/gate-lib.py

export CLAUDE_PLUGIN_ROOT_CORE=/tmp/claude-1000/fakecore
export PATH="/tmp/claude-1000/fakebin:$PATH"
cd /home/jwjung/.tokenmaxxxer/work/data-engineering-rulebook-issue-22-implementation
rm -rf .muster-cache
bash tests/run-gate-tests.sh
echo "RUNNER EXIT: $?"
```

### Observed
run-gate-tests.sh accumulates 26 `FAIL: ...` lines from bash-write-coverage/data-quality-gate/failure-handling-gate.test.sh, then prints `SKIP: compliance-check.sh unreachable — unverifiable outside spawn env` and the process exits with code 75. The `for f in "$ROOT_DIR"/tests/*.test.sh; do source "$f"; done` loop never reaches missing-core.test.sh, pipeline-design-gate.test.sh, or produces-combination.test.sh, and the final `echo "gate tests: $PASS passed, $FAIL failed"` / `[ "$FAIL" -eq 0 ]` never runs — the 26 accumulated FAILs are never reported as a nonzero exit, they simply vanish.

### Expected
A SKIP raised from inside one `*.test.sh` file should skip only that file's assertions (e.g. by `return` from the sourced file, or the runner trapping/catching a distinguished exit code per file in a subshell) and let the loop continue to the remaining test files, with the aggregate PASS/FAIL summary and exit status still reflecting every other file's real results. As written, the fix silently converts "compliance-check.sh is unreachable" into "abandon the rest of the test suite and hide any failures already found," which is worse than the FAIL(1) it replaced from a suite-correctness standpoint.
