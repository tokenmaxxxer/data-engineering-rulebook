---
subject: issue-2
role: implementation
---

# Proposal — transition to core canon references (core #63/#66 rollout)

Phase 1 only. No execution in this PR. Survey: `docs/issue-2/reports/implementation/survey.md`.

## Scope

Issue #2's five items, mapped 1:1 to this repo's `data-engineering/` tree.

1. Delete `data-engineering/agents/warrant-hunter.md`. It is an unfilled
   skeleton (no role-unique stance set was ever written in), superseded by
   the canon `warrant/agents/warrant-hunter.md` shipped by core's
   standalone `warrant` plugin (installed at session/harness level,
   confirmed by this session's own transcript already carrying `warrant`-
   adjacent directives). Nothing role-unique to preserve — the file's
   header even says "adapted from implementation-rulebook... skeleton."

2. Delete `data-engineering/hooks/trailer-gate.sh`,
   `data-engineering/hooks/record-fields-gate.sh`,
   `data-engineering/hooks/handbook-trigger-gate.sh`. Replace
   `data-engineering/hooks/hooks.json`'s `PreToolUse` block, currently:

   ```json
   "PreToolUse": [
     { "matcher": "Write|Edit|MultiEdit|NotebookEdit",
       "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/record-fields-gate.sh" }] },
     { "matcher": "Bash",
       "hooks": [
         { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/handbook-trigger-gate.sh" },
         { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/trailer-gate.sh" }
       ] }
   ]
   ```

   with no `PreToolUse` block at all — core's `core/hooks/hooks.json`
   (`matcher: ".*"`) already fires all three globally for every session
   with `core` installed, which this repo does not itself gate (matches
   the shape of every other core-canon-registered rulebook). `SessionStart`
   stays, pointing at the (rewritten) `directive.sh`.

3. Replace `data-engineering/hooks/directive.sh` with a stub sourcing
   `core/hooks/lib/role-directive.sh` and calling `core_role_directive`
   with this role's four unique values, per the shape core's own
   `role-directive.sh` header documents:

   ```bash
   #!/usr/bin/env bash
   trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
   set -uo pipefail
   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
   core_role_directive \
     "YOU DECIDE: 파이프라인이 데이터를 안정적으로 이동·변환하는가" \
     "USE_WHEN: 파이프라인 신설/변경이 걸릴 때" \
     "PRODUCES (required record fields): pipeline design, data-quality check list, failure-handling plan" \
     "WRITE_SCOPE: [] (report-only role — no code/doc write outside the record itself)
   HAND-OFF: 스키마 설계 자체는 → data-modeling"
   ```

   The `trap`/`set -uo pipefail` pair stays outside the sourced function
   per core issue #66's own record (a trap inside a sourced function does
   not catch the sourcing script's abnormal exit). `WRITE_SCOPE: []` has
   no dedicated slot in `core_role_directive`'s four-argument signature
   (`you_decide, use_when, produces, hand_off`); folding it into the
   `hand_off` argument as a second line is the only lossless placement,
   since each argument is echoed verbatim on its own line and no fifth
   slot exists. `core_role_directive` already emits the
   `RECORD: docs/issue-<n>/reports/${role}.md, phase-gated per contract
   v3 s19` closing line automatically — this role's current file's near-
   identical closing line is dropped, not preserved, since keeping it
   would duplicate the line the lib now owns (this repo's copy differs
   from the lib's only in appending "(phase-1 homes only pre-Approve;
   this record is phase-2 output)" — that clause is restated protocol,
   not role-unique content, and is already implied by contract v3 s19,
   which every role session already has loaded).

4. `RECORD_FIELDS_TERMINAL_STATES` — not needed. Per the survey, this
   role's directive names no `loop_state` other than the core default
   (`landed`) as terminal. No override recorded in
   `data-engineering/hooks/hooks.json`.

5. Once items 1-4 land (phase 2), run
   `core/hooks/tests/stub-check.sh data-engineering` (dropped into this
   repo alongside the existing tree, called the way core's own record
   describes distributing it — same mechanism as `parse-check.sh`) and
   record its pass in `docs/issue-2/reports/implementation.md`.

## Preserved (role-unique, unchanged)

- `data-engineering/.claude-plugin/plugin.json` — untouched.
- The four directive values themselves (YOU DECIDE / USE_WHEN / PRODUCES /
  WRITE_SCOPE+HAND-OFF text) — carried into the new stub verbatim.
- `data-engineering/hooks/hooks.json`'s `SessionStart` entry — untouched.

## Open question for the approver

None — the shape is fully determined by core issue #63/#66's own
transition-path notes (read from the sibling `tokenmaxxxer-core` checkout).
Flagging one packaging choice for visibility rather than as a blocker:
`stub-check.sh` is not yet vendored into this repo (item 5 needs it
present to run). Phase 2 will copy it in from
`core/hooks/tests/stub-check.sh` the same way `parse-check.sh` is already
distributed to rulebooks per that file's own header — no alternative
placement considered, since the file's own doc comment prescribes this
exact distribution mechanism.

## Order constraint

Per the issue: this transition must land before this repo's own
"rulebook maturation" phase 2 touches `directive.sh` or a gate file.
Noted for the approver's sequencing, not enforced mechanically in this PR.
