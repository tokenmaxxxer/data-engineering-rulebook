---
subject: issue-5
role: implementation
---

# Current-state survey — stub-check.sh canon recall (core #69)

## This repo's current tree

| File | Status |
|---|---|
| `data-engineering/hooks/tests/stub-check.sh` | Vendored copy of the drift-recurrence detector. Byte content matches the version this repo's own issue-2 work vendored in (`docs/issue-2/reports/implementation.md` item 5), which at the time was the prescribed distribution mechanism (same as `parse-check.sh`). Per core #69, `stub-check.sh` is now itself canon: run by reference from the core installed copy (`core/hooks/tests/stub-check.sh`), not vendored per rulebook. This copy is the recall target. |
| `data-engineering/hooks/hooks.json` | Contains only a `SessionStart` entry pointing at `directive.sh`. No `PreToolUse` or any other entry references `stub-check.sh` — grep confirms no `stub-check` string anywhere in `hooks.json`. Nothing to remove here. |
| `data-engineering/hooks/directive.sh` | Unrelated to this issue (already converted to the core-lib-call stub form under issue #2). Not touched. |
| `docs/handbooks/canon-scripts.md` | Referenced by the issue text as the canon statement's location, but does not exist in this repo (searched `docs/` recursively — only `docs/issue-2/...` and `docs/specs/approvers.md` exist). The canon statement is core's own document (in the sibling `tokenmaxxxer-core` checkout, not fetched here since phase 1 does not require executing/verifying against it — only proposing the removal). |

## Gap line

- Present in this repo, now drift per core #69: the vendored
  `data-engineering/hooks/tests/stub-check.sh` copy itself.
- Already absent (nothing to do): any `hooks.json` registration of
  `stub-check.sh` — grep found none.
- No role-unique content in the vendored file to preserve — it is a
  verbatim distributed copy, not role-authored.

## Deletion target for phase 2

- `data-engineering/hooks/tests/stub-check.sh` (and the now-empty
  `hooks/tests/` directory, if nothing else lives there — checked: it is
  empty after this file's removal).
