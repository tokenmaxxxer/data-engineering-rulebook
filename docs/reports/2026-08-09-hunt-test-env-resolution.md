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
