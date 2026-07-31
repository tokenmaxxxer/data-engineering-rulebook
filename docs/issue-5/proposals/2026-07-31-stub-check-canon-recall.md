---
subject: issue-5
role: implementation
---

# Proposal — recall vendored stub-check.sh (core #69 canon)

Phase 1 only. No execution in this PR. Survey: `docs/issue-5/reports/implementation/survey.md`.

## Scope

1. Delete `data-engineering/hooks/tests/stub-check.sh` (and the
   `hooks/tests/` directory itself, now empty). It is a verbatim vendored
   copy with no role-unique content — core #69 makes `stub-check.sh`
   canon, run by reference from the core-installed copy
   (`core/hooks/tests/stub-check.sh`), never vendored per rulebook.

2. `hooks.json` — no change needed. Survey confirms no entry references
   `stub-check.sh`; the file was only ever invoked directly (as a script
   path), never registered as a hook.

3. Phase 2 will run `core/hooks/tests/stub-check.sh data-engineering`
   (from the core-installed copy, by reference — not re-vendored) against
   this repo's `data-engineering/` tree and record the pass in
   `docs/issue-5/reports/implementation.md`, per the issue's instruction.

## Preserved unchanged

- `data-engineering/hooks/directive.sh`, `hooks.json`'s `SessionStart`
  entry — untouched, unrelated to this recall.

## Open question for the approver

None. The removal target and the reference-execution replacement are both
fully determined by the issue text and core #69's canon; no design choice
is open.
