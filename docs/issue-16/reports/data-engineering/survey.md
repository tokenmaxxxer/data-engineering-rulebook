---
subject: issue-16
role: data-engineering
phase: 1-survey
---

# Survey — re-audit residual defects (issue #16)

## Scope

This survey covers only the `data-engineering` role's own plugins in this
checkout: `data-engineering/` (directive-only), `pipeline-design-gate/`,
`data-quality-gate/`, `failure-handling-gate/`, `tests/`, `README.md`,
`docs/handbooks/data-engineering/methodology.md`. It builds on the prior
audit trail (`docs/issue-13/proposals/2026-08-01-gate-remediation-a-plus.md`,
`docs/issue-13/reports/data-engineering.md`), which landed the bash+Python
split, `gate-lib` delegation, section-scoped N/A, and 30 mandatory test
cases and left one item explicitly deferred to approver attention:
Bash-tool write coverage (`hooks.json` matcher unchanged at
`Write|Edit|MultiEdit`).

## Repo layout found

- `data-engineering/.claude-plugin/plugin.json`, `data-engineering/hooks/hooks.json`
  (SessionStart only), `data-engineering/hooks/directive.sh` — no
  PreToolUse/PostToolUse gate of its own; `WRITE_SCOPE: []`.
- `pipeline-design-gate/`, `data-quality-gate/`, `failure-handling-gate/` —
  three independent plugins, each `<gate>-gate.sh` (bash entrypoint) +
  `<gate>-gate.py` (payload), `hooks.json` with one `PreToolUse` entry
  matching `Write|Edit|MultiEdit`.
- `tests/{pipeline-design-gate,data-quality-gate,failure-handling-gate}.test.sh`,
  `tests/produces-combination.test.sh`, `tests/gate-lib-compliance.test.sh`,
  `tests/run-gate-tests.sh` (shared harness + core-lib fetch).
- No `core/` plugin directory exists in this checkout. `CLAUDE_PLUGIN_ROOT_CORE`
  is resolved at runtime to a sibling `core` plugin directory that is assumed
  to exist in production installs, or fetched into a local test cache
  (`.muster-cache/core-lib/`) from `tokenmaxxxer-core`'s `main` branch in
  `tests/run-gate-tests.sh`. **Gap/assumption**: core issue #75's
  gate-lib source-guard mandate, compliance-check detection,
  missing-core mandatory test, and `gate_bash_write_targets.py` port are
  not present in this repo (they live in `tokenmaxxxer-core`, a separate
  repo not checked out here). This survey does not fabricate their
  contents; the proposal treats them abstractly as: (a) a source guard at
  the top of each gate's bash entrypoint/py payload that fails closed if
  `gate-lib.sh`/`gate-lib.py` cannot be sourced/imported, (b) a
  `compliance-check.sh` detector already referenced here
  (`tests/gate-lib-compliance.test.sh`), (c) a "missing-core" test case
  (core lib absent/unreachable → gate must still deny, never silently
  allow) which is **not present** in this repo's test suite today, and
  (d) a shared `gate_bash_write_targets.py`-style helper for detecting
  write-capable `Bash` invocations, referenced by name only
  (`docs/issue-13/reports/data-engineering.md`'s "Open item deferred").

## Defect hunt

### (a) N/A exemption logic reproduced in bullet-label documentation

Confirmed, byte-for-byte, across all three gate `.py` payloads. Each of
`pipeline-design-gate/hooks/pipeline-design-gate.py`,
`data-quality-gate/hooks/data-quality-gate.py`,
`failure-handling-gate/hooks/failure-handling-gate.py` independently
defines the identical `NA_RE`, `OWN_LABEL_RE`/`OTHER_LABEL_RES` triples,
and an identical `section_slice()` function (docstring included) — see
e.g. `pipeline-design-gate.py:26,41-53,77-98` vs.
`data-quality-gate.py:26,46-56` vs.
`failure-handling-gate.py:27,45-55` (label regex only permuted per gate's
own label vs. the other two). `docs/issue-13/reports/data-engineering.md`
already flags this explicitly as *not* delegated to core: "a new
`section_slice()` helper duplicated per gate payload — the section split
is data-engineering's own PRODUCES semantics, out of core's scope per the
proposal." The re-audit finding is that this duplication (three
independent copies of exemption/section logic) is itself a defect,
regardless of whose "scope" it nominally sits in — it violates the
canon reference-not-copy discipline applied everywhere else in these
gates (`docs/handbooks/canon-scripts.md`).

### (b) NotebookEdit README overstatement

`README.md:54` and `docs/handbooks/data-engineering/methodology.md:73-74`
both state that `core/hooks/lib/gate-lib.sh`/`gate-lib.py` are used for
"`Edit`/`MultiEdit`/`replace_all`/`NotebookEdit` content reconstruction."
This is true of `gate-lib.py`'s general capability, but none of the three
gates' `hooks.json` matchers include `NotebookEdit`
(`pipeline-design-gate/hooks/hooks.json:5`,
`data-quality-gate/hooks/hooks.json:5`,
`failure-handling-gate/hooks/hooks.json:5` — all
`"matcher": "Write|Edit|MultiEdit"`). A `NotebookEdit` write to a
proposal/record path never reaches any of these gates, so the
`gate_reconstruct_write` NotebookEdit branch, even if present in
`gate-lib.py`, is dead code from this plugin's perspective. README/handbook
prose reads as advertising enforced NotebookEdit coverage that does not
exist in production wiring — the overstatement.

### (c) `.muted-cache` gitignore description error

No file named `.gitignore` exists anywhere in this repository
(`find . -iname ".gitignore"` returns nothing). `README.md:58`,
`tests/run-gate-tests.sh:23,25`, and
`tests/gate-lib-compliance.test.sh:11` all describe the local test-time
core-lib fetch cache (`.muster-cache/core-lib/`) as "gitignored." It is
not — there is no `.gitignore` entry anywhere ignoring `.muster-cache/`
(or any other path). (Issue #16's body spells this `.muted-cache`; no
occurrence of that exact string exists in the repo — it appears to be the
re-auditor's rendering of `.muster-cache`. Treating them as the same
finding: the description is wrong either way, since the directory is
called `.muster-cache` in every file that mentions it, and it is not
actually gitignored.) Practical effect: `bash tests/run-gate-tests.sh`
run from a checkout would leave `.muster-cache/` as an untracked
directory that `git status`/`git add -A` would pick up, contradicting the
documented "gitignored, re-fetched per run, never vendored" claim.

### (d) hooks.json matcher / code coverage parity

All three gates: `hooks.json` matcher is `Write|Edit|MultiEdit`, and each
gate's `resolve_content()` delegates to `gate_lib.gate_reconstruct_write`,
which (per README/handbook) also handles `NotebookEdit`. Findings:

- `NotebookEdit`: code-reachable via `gate_reconstruct_write` (per its
  documented capability) but **not advertised/matched** in any of the
  three `hooks.json` files — an unreachable-in-production branch, same
  root cause as (b).
- `Bash`: **not matched** by any gate's `hooks.json`, and no gate code
  path handles `tool_name == "Bash"` at all (`resolve_content()` and
  `in_scope()` in all three `.py` files only look at `tool_input.file_path`
  / `os.path.exists(file_path)`, which assumes a Write/Edit/MultiEdit-shaped
  payload). This is `docs/issue-13/reports/data-engineering.md`'s
  explicitly deferred open item — a proposal/record write via
  `cat > docs/issue-N/proposals/...-data-engineering....md <<EOF` (heredoc)
  or `echo >>` bypasses all three gates entirely today. Core issue #75's
  `gate_bash_write_targets.py` is referenced by name as the intended
  shared mechanism for detecting write-capable Bash invocations, but is
  not present in this repo to inspect directly (see gap note above).
- `Write`/`Edit`/`MultiEdit`: matched and code-reachable in all three
  gates — no parity gap here.

### (e) Old role names / ghost files

No canonical 43-role taxonomy list exists in this checkout
(`docs/specs/` contains only `approvers.md`; no `role-taxonomy.md` or
similar was found anywhere under `docs/`) — this is a **gap**, not a
clean bill of health: this survey cannot machine-verify role names
against the canonical list from within this repo alone. Manual scan of
`README.md`, all four `.claude-plugin/plugin.json` manifests, and
`docs/handbooks/data-engineering/methodology.md` found:

- Role self-references: `data-engineering` (this role, consistent
  everywhere) and one hand-off target, `data-modeling`
  (`README.md:11`, `data-engineering/hooks/directive.sh`,
  `data-engineering/.claude-plugin/plugin.json`) — no other role names
  appear. No evidence of a stale/pre-taxonomy name (e.g. an old
  "etl-engineer"/"data-pipeline" label) in any file surveyed.
- No dangling references to files that do not exist: `README.md`'s
  "Layout" and "Methodology gate plugins" sections list files that were
  all confirmed present on disk (`find` cross-check against README
  claims — see file list above).

Recommendation for the proposal: flag the missing canonical-taxonomy
cross-reference as a process gap and propose confirming `data-modeling`
against the taxonomy once available, rather than asserting compliance
without a source to check against.

## Test suite / compliance-check status

- Test files present: `pipeline-design-gate.test.sh`,
  `data-quality-gate.test.sh`, `failure-handling-gate.test.sh`,
  `produces-combination.test.sh`, `gate-lib-compliance.test.sh`, run via
  `tests/run-gate-tests.sh`. Per the issue-13 record, prior full-suite run
  was "60 passed, 0 failed" (not independently re-run here — would
  require network fetch of `tokenmaxxxer-core`'s `gate-lib.sh`/`.py`/
  `compliance-check.sh`, which this phase-1 survey does not attempt,
  consistent with "no code changes" scope; a dry read-only
  `bash -n` syntax check of each shell script and `python3 -m py_compile`
  of each Python payload would be safe to run in phase 2 verification).
- **No "missing-core" test case exists** in any test file: every test in
  `run-gate-tests.sh`'s harness (`assert_gate*`) runs against a
  `CLAUDE_PLUGIN_ROOT_CORE` that `setup_core_lib` has always freshly
  populated with a real `gate-lib.sh`/`gate-lib.py`. No case exercises
  "core lib absent/unreadable" and asserts the gate still denies
  (fail-closed) rather than crashing open or erroring past `set -uo
  pipefail`/the EXIT trap in an unverified way.
- `tests/gate-lib-compliance.test.sh` exists and runs core's
  `compliance-check.sh` (fetched from `tokenmaxxxer-core` main) against
  each gate's `hooks/` directory — this is the "compliance-check passing"
  mechanism referenced by issue #16's requirement 3; its detection rules
  live in the external `tokenmaxxxer-core` repo, not in this checkout.

## Summary table

| Defect | Confirmed in this repo? | Files |
|---|---|---|
| N/A exemption logic reproduced in bullet-label docs | Yes — 3x duplicated `NA_RE`/`OWN_LABEL_RE`/`OTHER_LABEL_RES`/`section_slice()` | `pipeline-design-gate/hooks/pipeline-design-gate.py`, `data-quality-gate/hooks/data-quality-gate.py`, `failure-handling-gate/hooks/failure-handling-gate.py` |
| NotebookEdit README overstatement | Yes | `README.md:54`, `docs/handbooks/data-engineering/methodology.md:73-74` vs. all three `hooks.json` |
| `.muted-cache`/`.muster-cache` gitignore description error | Yes — no `.gitignore` file exists at all | `README.md:58`, `tests/run-gate-tests.sh:23,25`, `tests/gate-lib-compliance.test.sh:11` |
| hooks.json matcher/code parity (Bash) | Yes — Bash unmatched and unhandled, deferred since issue #13 | all three `hooks.json` + `.py` `in_scope()`/`resolve_content()` |
| hooks.json matcher/code parity (NotebookEdit) | Yes — same root as README overstatement | all three `hooks.json` |
| Old role names / ghost files | Not found, but taxonomy source absent from repo (gap, not a clean pass) | `README.md`, 4x `plugin.json` |
| Missing-core test case | Confirmed absent | `tests/*.test.sh`, `tests/run-gate-tests.sh` |
