# data-engineering-rulebook

Rulebook for the `data-engineering` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 파이프라인이 데이터를 안정적으로 이동·변환하는가
- **use_when**: 파이프라인 신설/변경이 걸릴 때
- **produces**: pipeline design, data-quality check list, failure-handling plan
- **write_scope**: []
- **hand-off**: 스키마 설계 자체는 → data-modeling

## Install

```
claude plugin marketplace add tokenmaxxxer/data-engineering-rulebook
claude plugin install data-engineering
```

## Layout

- `data-engineering/.claude-plugin/plugin.json` — plugin manifest
- `data-engineering/hooks/hooks.json` — SessionStart + PreToolUse wiring
- `data-engineering/hooks/directive.sh` — SessionStart role directive
  (facet-depth `PRODUCES` text, phase 1 vs phase 2 — see
  `docs/handbooks/data-engineering/methodology.md`)
- `docs/handbooks/data-engineering/methodology.md` — fuller methodology prose
  behind the directive's compressed `PRODUCES` pointer
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

### Methodology gate plugins (issue #10)

One methodology sub-field = one independent, self-contained gate — own hook
script, own kill switch, own test file. All three run on both facet write
surfaces (phase-1 proposal, phase-2 record) via `hooks.json`'s `PreToolUse`
wiring; none depends on another's internals.

| Plugin | Hook script | Kill switch | Tests |
|---|---|---|---|
| pipeline-design-gate | `data-engineering/hooks/pipeline-design-gate.sh` | `DATA_ENGINEERING_PIPELINE_DESIGN_GATE_OFF` | `tests/pipeline-design-gate.test.sh` |
| data-quality-gate | `data-engineering/hooks/data-quality-gate.sh` | `DATA_ENGINEERING_DATA_QUALITY_GATE_OFF` | `tests/data-quality-gate.test.sh` |
| failure-handling-gate | `data-engineering/hooks/failure-handling-gate.sh` | `DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF` | `tests/failure-handling-gate.test.sh` |

Combination behavior (all three vs. an out-of-scope write, vs. a single
denying plugin) is covered by `tests/produces-combination.test.sh`. Run the
whole suite with `bash tests/run-gate-tests.sh`. Design rationale:
`docs/issue-10/proposals/methodology-gate-and-directive-depth.md`.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
