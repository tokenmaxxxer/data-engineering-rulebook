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
- `data-engineering/hooks/hooks.json` — SessionStart wiring
- `data-engineering/hooks/directive.sh` — SessionStart role directive
  (facet-depth `PRODUCES` text, phase 1 vs phase 2 — see
  `docs/handbooks/data-engineering/methodology.md`)
- `docs/handbooks/data-engineering/methodology.md` — fuller methodology prose
  behind the directive's compressed `PRODUCES` pointer
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

### Methodology gate plugins (issue #10)

One methodology sub-field = one independent, self-contained **plugin** —
own `.claude-plugin/plugin.json`, own `hooks/hooks.json`, own hook script,
own kill switch, own test file, own marketplace entry. Each installs and
toggles independently of `data-engineering` and of the other two gates; all
three fire on both facet write surfaces (phase-1 proposal, phase-2 record).

| Plugin | Hook script | Kill switch | Tests |
|---|---|---|---|
| pipeline-design-gate | `pipeline-design-gate/hooks/pipeline-design-gate.sh` | `DATA_ENGINEERING_PIPELINE_DESIGN_GATE_OFF` | `tests/pipeline-design-gate.test.sh` |
| data-quality-gate | `data-quality-gate/hooks/data-quality-gate.sh` | `DATA_ENGINEERING_DATA_QUALITY_GATE_OFF` | `tests/data-quality-gate.test.sh` |
| failure-handling-gate | `failure-handling-gate/hooks/failure-handling-gate.sh` | `DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF` | `tests/failure-handling-gate.test.sh` |

Each gate is a thin **bash entrypoint** (`<gate>-gate.sh`, ~10 lines) that
sources `core/hooks/lib/gate-lib.sh` from the sibling `core` plugin
(`${CLAUDE_PLUGIN_ROOT_CORE}`, same resolution `data-engineering/hooks/directive.sh`
already uses for `role-directive.sh`), installs the fail-closed EXIT trap,
checks the kill switch, then execs a same-named **Python payload**
(`<gate>-gate.py`) holding the actual scope/content/semantic checks. The
Python payload in turn loads the sibling `core/hooks/lib/gate-lib.py` via
the `GATE_LIB_PY` env var `gate-lib.sh` exports, for absolute/relative/
`./`-prefixed path normalization, malformed-JSON deny, and
Edit/MultiEdit/`replace_all`/NotebookEdit content reconstruction — none of
that is reimplemented per-gate (`docs/handbooks/canon-scripts.md`'s
reference-not-copy rule; `core/hooks/tests/compliance-check.sh` machine-checks
this). `tests/run-gate-tests.sh` fetches `gate-lib.sh`/`gate-lib.py` from
`tokenmaxxxer-core`'s `main` branch into a gitignored `.muster-cache/`
directory and points `CLAUDE_PLUGIN_ROOT_CORE` at it for the duration of the
test run, mirroring the sibling-plugin layout the gates assume in
production.

Combination behavior (all three vs. an out-of-scope write, vs. a single
denying plugin) is covered by `tests/produces-combination.test.sh`;
`tests/gate-lib-compliance.test.sh` runs `core/hooks/tests/compliance-check.sh`
against each gate's `hooks/` directory. Run the whole suite with
`bash tests/run-gate-tests.sh`. Design rationale:
`docs/issue-10/proposals/methodology-gate-and-directive-depth.md`,
`docs/issue-13/proposals/2026-08-01-gate-remediation-a-plus.md`.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
