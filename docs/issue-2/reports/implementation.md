---
subject: issue-2
role: implementation
---

# Record — core canon reference transition (phase 2)

## What was done

Executed the approved proposal (`docs/issue-2/proposals/2026-07-31-core-canon-reference-transition.md`) item-for-item:

1. Deleted `data-engineering/agents/warrant-hunter.md` (unfilled skeleton, superseded by canon `warrant/agents/warrant-hunter.md`).
2. Deleted `data-engineering/hooks/trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`. Removed their `PreToolUse` block from `data-engineering/hooks/hooks.json`, leaving only the `SessionStart` → `directive.sh` entry.
3. Replaced `data-engineering/hooks/directive.sh` with a stub that sources `core/hooks/lib/role-directive.sh` (via `${CLAUDE_PLUGIN_ROOT_CORE:-...}` fallback) and calls `core_role_directive` with the four role-unique values, `WRITE_SCOPE: []` folded into the `hand_off` argument as a second line (`$'...\n...'` literal, since `hand_off` is echoed verbatim by the lib).
4. `RECORD_FIELDS_TERMINAL_STATES` — confirmed not needed; this role names no terminal `loop_state` beyond the core default (`landed`).
5. Vendored `core/hooks/tests/stub-check.sh` into `data-engineering/hooks/tests/stub-check.sh` and ran it against `data-engineering/`.

## Why

Core landed a single canon for the warrant-hunter agent (core issue #63) and the three role-agnostic gates plus the shared `role-directive.sh` boilerplate (core issue #66). Every rulebook's vendored copy is now drift by definition — this repo's own copies were unfilled skeletons that never carried role-unique logic, so removing them loses nothing while collapsing 43 near-duplicate implementations to one.

## Deviation from the proposal

The proposal's draft stub (item 3) kept a `trap ... EXIT` / `set -uo pipefail` pair ahead of the `source` line, attributed to "core issue #66's own record." Running the vendored `stub-check.sh` against that draft failed:

```
stub-check: FAIL — .../data-engineering/hooks/directive.sh: has non-stub line(s), looks like regrown boilerplate: trap 'rc=$?; ...' EXIT
```

Cross-checked against core's own test fixture for a passing stub (`core/hooks/tests/run-role-gates-tests.sh`, the `real stub directive.sh passes` case): the accepted shape has no shebang, no `trap`, no `set` — only the `source` line and a single-line `core_role_directive` call. `stub-check.sh`'s structural check (`core/hooks/tests/stub-check.sh`) is line-based and rejects any line beyond those two forms, including backslash-continued call arguments. Built the actual stub to that fixture's shape instead: shebang, source line, and one single-line `core_role_directive` call (the multi-value `hand_off` argument uses `$'...\n...'` to keep the whole call on one physical source line while still emitting two output lines).

## Upstream basis

Core issue #63 (warrant canon), core issue #66 (role-agnostic gates + `role-directive.sh` promotion), both read from the sibling `tokenmaxxxer-core` checkout, plus `core/hooks/tests/run-role-gates-tests.sh`'s passing-stub fixture (used to resolve the deviation above, since the proposal's inferred shape did not match the actual test harness).

## Verification

`stub-check.sh` run against `data-engineering/`:

```
stub-check: ok — no vendored 'trailer-gate.sh' under .../data-engineering
stub-check: ok — no vendored 'record-fields-gate.sh' under .../data-engineering
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under .../data-engineering
stub-check: ok — no vendored 'parse-check.sh' under .../data-engineering
stub-check: ok — .../data-engineering/hooks/directive.sh is a role-directive stub
```

All checks pass (exit 0).

## Preserved unchanged

- `data-engineering/.claude-plugin/plugin.json`.
- The four directive values (YOU DECIDE / USE_WHEN / PRODUCES / WRITE_SCOPE+HAND-OFF text), carried into the stub verbatim.
- `data-engineering/hooks/hooks.json`'s `SessionStart` entry.

## Open findings

None outstanding.

## Next steps

None — this transition item is complete. Per the issue's order constraint, this repo's own "rulebook maturation" phase 2 may now proceed to touch `directive.sh` / gate files.

loop_state: landed
