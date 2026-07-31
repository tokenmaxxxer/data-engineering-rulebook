---
subject: issue-5
role: implementation
---

# Record — recall vendored stub-check.sh (core #69 canon, phase 2)

## What was done

Executed the approved proposal (`docs/issue-5/proposals/2026-07-31-stub-check-canon-recall.md`) item-for-item:

1. Deleted `data-engineering/hooks/tests/stub-check.sh` (vendored copy, no role-unique content) and the now-empty `data-engineering/hooks/tests/` directory.
2. `hooks.json` — confirmed unchanged: no entry ever registered `stub-check.sh` as a hook, so there was nothing to remove there.
3. Ran the core-installed reference copy of `stub-check.sh` against `data-engineering/`, by reference — not re-vendored.

## Why

Core #69 makes `stub-check.sh` canon: run from the core-installed copy (`core/hooks/tests/stub-check.sh`), never vendored per rulebook. This repo's copy was a verbatim duplicate of that canon script, so keeping it was pure drift risk with no role-unique value.

## Upstream basis

Core issue #69 (stub-check.sh canonicalization), read via the core-installed copy of `hooks/tests/stub-check.sh` used to run the verification below.

## Verification

`stub-check.sh` run by reference (core-installed copy) against `data-engineering/`:

```
stub-check: ok — no vendored 'trailer-gate.sh' under data-engineering
stub-check: ok — no vendored 'record-fields-gate.sh' under data-engineering
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under data-engineering
stub-check: ok — no vendored 'parse-check.sh' under data-engineering
stub-check: ok — data-engineering/hooks/directive.sh is a role-directive stub
```

All checks pass (exit 0).

## Preserved unchanged

- `data-engineering/hooks/directive.sh`.
- `data-engineering/hooks/hooks.json`'s `SessionStart` entry.

## Open findings

None outstanding.

## Next steps

None — this recall item is complete.

loop_state: landed
