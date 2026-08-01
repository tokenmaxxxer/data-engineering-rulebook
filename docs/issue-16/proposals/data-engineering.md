---
subject: issue-16
role: data-engineering
phase: 1-proposal
---

# Proposal — Gate A+ final closeout, residual defect remediation (issue #16)

## Why (triggering change, plain terms)

The 2026-08-01 re-audit graded the three PRODUCES gate plugins B+ and
found four residual defects surviving the issue #13 A+ remediation:
duplicated N/A/section-scoping logic across the three gates, an
NotebookEdit-coverage overstatement in the README, a gitignore
description that doesn't match reality, and (per the issue's general
requirements) an unresolved `hooks.json`/code parity gap and a missing
"missing-core" test case. This proposal is **phase 1 only**: a written
remediation design for `data-engineering`'s own plugins. No gate code,
test code, or README text is changed in this pass; no approval is
granted; this record does not touch `docs/issue-16/reports/data-engineering.md`
(phase 2, locked).

This is not a pipeline change in the PRODUCES sense (no source/transform/
sink is affected) — the sub-field structure below is applied by analogy,
per `docs/handbooks/data-engineering/methodology.md`'s phase-1 steps, with
each sub-field re-scoped to "gate design" rather than "data pipeline
design," as `docs/issue-13/reports/data-engineering.md` already did for
its own gate-remediation delivery.

## Pipeline-design analog: gate design proposal

### Defect 1 — N/A exemption logic reproduced in bullet-label documentation

**Current state**: `NA_RE`, `OWN_LABEL_RE`, `OTHER_LABEL_RES`, and
`section_slice()` are defined identically (module docstring included) in
`pipeline-design-gate/hooks/pipeline-design-gate.py`,
`data-quality-gate/hooks/data-quality-gate.py`, and
`failure-handling-gate/hooks/failure-handling-gate.py` — only the
per-gate label pattern differs. `docs/issue-13/reports/data-engineering.md`
recorded this as intentionally "out of core's scope," but three
independently-maintained copies of exemption/section-boundary logic is
exactly the kind of drift the canon reference-not-copy discipline
(`docs/handbooks/canon-scripts.md`) exists to prevent — a fix to the N/A
grammar or a label regex in one gate can silently diverge from the other
two.

**Proposed fix**: extract `NA_RE`, the three-way label regex triple, and
`section_slice()` into one shared module owned by `data-engineering`
itself — not core (this is data-engineering's own PRODUCES sub-field
semantics, not a generic gate-house concern core issue #75 covers) — at
a new file, e.g. `data-engineering/hooks/lib/produces-sections.py`,
loaded by each gate's payload the same way `gate_lib.py` is loaded today
(`importlib.util.spec_from_file_location` against a path resolved
relative to each gate's own directory, e.g.
`../../data-engineering/hooks/lib/produces-sections.py`, or via a new
`DATA_ENGINEERING_PRODUCES_LIB_PY`-style env var set by each
`<gate>-gate.sh` entrypoint, mirroring `GATE_LIB_PY`'s existing pattern).
Each gate's `.py` payload keeps only its own gate-specific regexes
(`ARROW_RE`, `FLOW_RE`, `THRESHOLD_RE`, etc.) and calls the shared
`section_slice(content, own_label, other_labels)` /
`na_exempt(section)` functions. This is a design proposal only; no file
is created in this pass.

**Why this resolves the finding**: collapses three independently-editable
copies into one, removing the drift risk the re-audit flagged, while
keeping the split correctly scoped to `data-engineering` rather than
miscategorizing it as core's responsibility.

### Defect 2 — NotebookEdit README overstatement

**Current state**: `README.md:54` and
`docs/handbooks/data-engineering/methodology.md:73-74` state that
`gate-lib.py` is used for "`Edit`/`MultiEdit`/`replace_all`/`NotebookEdit`
content reconstruction," implying NotebookEdit writes are covered. All
three `hooks.json` matchers are `Write|Edit|MultiEdit` — `NotebookEdit`
is never invoked.

**Proposed fix**: correct both files to state the true, narrower claim.
`README.md:54` and `methodology.md:73-74`: replace "Edit/MultiEdit/
`replace_all`/NotebookEdit content reconstruction" with "Edit/MultiEdit/
`replace_all` content reconstruction (`gate-lib.py` additionally supports
NotebookEdit reconstruction, but none of the three gates' `hooks.json`
matchers currently include `NotebookEdit` — see Defect 4/hooks.json
parity below for the coverage decision)." This makes the overstatement
correction and the parity gap (Defect 4) read as one linked fact instead
of two unrelated-looking edits.

**Why this resolves the finding**: the README no longer implies
enforcement that does not exist in production wiring.

### Defect 3 — `.muster-cache`/`.muted-cache` gitignore description error

**Current state**: no `.gitignore` file exists anywhere in this repo.
`README.md:58`, `tests/run-gate-tests.sh:23,25`, and
`tests/gate-lib-compliance.test.sh:11` all describe `.muster-cache/`
(the test-time `tokenmaxxxer-core` fetch cache) as "gitignored." It is
not.

**Proposed fix**: two-part, and the approver should pick one primary
remedy (both are compatible, so both can land together):

1. Add a `.gitignore` at repo root containing `.muster-cache/`, making
   the existing documentation accurate.
2. Correct the wording in `README.md:58` and the comment in
   `tests/run-gate-tests.sh:23` to describe the cache accurately as
   "test-scratch, re-fetched per run, not committed" rather than
   asserting "gitignored" as a currently-true fact, in case the approver
   prefers not to introduce a repo-root `.gitignore` in this pass.

This proposal recommends (1) as the primary fix — it is the smaller,
more direct correction (one new file, no prose rewrite needed) and
actually delivers the behavior the documentation already promises,
rather than just softening the promise. (2) is offered as a fallback if
the approver wants to avoid adding `.gitignore` in this specific PR.

**Why this resolves the finding**: after (1), the documented claim
("gitignored") becomes true; a `git status`/`git add -A` in a checkout
that has run the test suite no longer surfaces `.muster-cache/` as
untracked, matching the "re-fetched per run, never vendored" intent
already stated in three places.

## Data-quality-check-list analog: what validates the gate fixes

- **hooks.json matcher / code coverage parity (issue #16 requirement 2)**:
  - `NotebookEdit`: proposed decision — **do not add** `NotebookEdit` to
    the three matchers in this pass. Rationale: PRODUCES proposals/records
    are prose documents; there is no established workflow for authoring
    them via NotebookEdit, and adding the matcher without a corresponding
    test/fixture would just relocate the "advertised but unverified"
    problem rather than close it. Instead, Defect 2's fix removes the
    overstated claim. If a future need for NotebookEdit-authored
    proposals emerges, that should be its own scoped follow-up (matcher
    change + fixtures + `gate-lib`'s NotebookEdit reconstruction path
    exercised by a real test), not bundled into this closeout.
  - `Bash`: propose closing this gap, referencing core issue #75's
    `gate_bash_write_targets.py` port by name (per issue #16's
    instruction to apply core #75's finalized guard/rules by reference,
    not reimplement). Plan: once `gate_bash_write_targets.py` (or
    equivalent shared helper) is available via `CLAUDE_PLUGIN_ROOT_CORE`,
    each `<gate>-gate.sh` entrypoint's kill-switch check is followed by a
    Bash-target check (using the shared helper to determine whether the
    invoked `Bash` command's write targets fall in this gate's
    `in_scope()` path pattern before handing off to the Python payload —
    or the Python payload's `in_scope()`/`resolve_content()` gains a
    `tool_name == "Bash"` branch that calls the shared helper to extract
    candidate written paths and their resulting content, using the same
    `gate_reconstruct_write`-style contract). `hooks.json` matcher changes
    from `Write|Edit|MultiEdit` to `Write|Edit|MultiEdit|Bash` in all
    three gates in lockstep with the code change — never one without the
    other, so no matcher ever advertises a tool the code cannot yet
    handle, and no code branch exists for a tool `hooks.json` doesn't
    route to it. This mirrors `docs/issue-13/reports/data-engineering.md`'s
    own deferred-item language and now un-defers it, contingent on core
    #75 being available as a reference.
  - `Write`/`Edit`/`MultiEdit`: already at parity; no change proposed.

- **Missing-core test case (issue #16 requirement 3)**: propose adding
  one new mandatory test case per gate (3 total, or 1 shared case
  invoked per gate via the existing `script_path()` dispatch in
  `tests/run-gate-tests.sh`) to `tests/gate-lib-compliance.test.sh` or a
  new `tests/missing-core.test.sh`: point `CLAUDE_PLUGIN_ROOT_CORE` at an
  empty/nonexistent directory for the duration of one `assert_gate_tool`
  call per gate and assert exit code 2 (deny), not a crash/exit-0. This
  directly exercises core #75's "gate-lib source guard mandate" from this
  plugin's side — the guard itself lives in `gate-lib.sh`/the bash
  entrypoint (core's responsibility per #75), but this plugin's test
  suite should assert the guard actually fires when invoked through
  data-engineering's own gate scripts, since that is the integration
  point re-audited here.

- **Compliance-check passing**: `tests/gate-lib-compliance.test.sh`
  already runs `tokenmaxxxer-core`'s `compliance-check.sh` against each
  gate's `hooks/` directory and treats any non-zero exit as a failure.
  Once core #75's compliance-check additions (source-guard detection)
  land upstream, this plugin's existing `assert_compliance` calls pick
  them up automatically on the next `curl` fetch — no code change needed
  in this repo for that part, only for the missing-core test case above
  and the `produces-sections.py` extraction (Defect 1), both of which
  should themselves pass `compliance-check.sh` unmodified (they follow
  the same bash-entrypoint + Python-payload + `gate-lib` delegation
  shape already in place).

## Failure-handling analog: what happens if compliance-check still fails after fixes

- **Failure mode**: `compliance-check.sh` (fetched from
  `tokenmaxxxer-core` main) flags one or more gates after the Defect 1
  extraction or the Bash-coverage addition (e.g. because the new
  `produces-sections.py` loader pattern doesn't match what the detector
  expects, or the Bash-handling branch reintroduces a hand-rolled check
  the detector flags as non-delegated).
  - **First-check/diagnostic step**: run
    `bash tests/gate-lib-compliance.test.sh`'s underlying
    `compliance-check.sh <hooks_dir>` directly (not just via the full
    suite) against the specific gate's `hooks/` directory to get the
    detector's own stderr output, which names the specific pattern it
    flagged.
  - **Escalation path**: if the flag is a false positive against a
    legitimately-scoped data-engineering-only helper (e.g. the new
    `produces-sections.py` loader), raise it against `tokenmaxxxer-core`
    (core #75's tracking issue) rather than working around the detector
    locally — working around a compliance detector inside the audited
    repo defeats its purpose.
  - **Recovery/rollback step**: revert the specific change (Defect 1
    extraction or Bash-coverage matcher+code pair) independently; each
    proposed fix above is structured to land as its own isolated commit
    so a revert of one does not require reverting the others.
  - **Recovery-time target**: no production traffic depends on these
    gates' fail-closed posture changing mid-incident — target is "before
    the next approver review cycle," not an operational SLA; scaled down
    from a live-pipeline RTO because this is dev-tooling, not a running
    pipeline.
- **Failure mode**: full suite (`bash tests/run-gate-tests.sh`) regresses
  below the current 60-passed baseline after the missing-core test
  addition.
  - **Diagnostic step**: the new test's `assert_gate_tool` call already
    reports `script`/`expect`/`actual` on failure (existing harness
    behavior) — read that line first.
  - **Escalation/recovery**: same as above — isolate to the specific
    added test/case; do not adjust unrelated existing cases to compensate.
  - **Recovery-time target**: same as above.

## Consequences / trade-offs

- Extracting shared N/A/section logic (Defect 1) adds one new
  data-engineering-owned library file and a load-path convention
  (`DATA_ENGINEERING_PRODUCES_LIB_PY` or directory-relative resolution)
  that every future data-engineering gate must also adopt — a small
  ongoing discipline cost in exchange for removing the three-way drift
  risk.
- Declining to add `NotebookEdit` to the matchers (Defect 2's chosen
  remedy) means NotebookEdit-authored PRODUCES documents remain
  ungated indefinitely until a future issue scopes that properly — an
  explicit, documented gap rather than a silent one.
- Adding `Bash` coverage (Defect 4) depends on core #75 landing
  `gate_bash_write_targets.py` first; this proposal cannot be executed
  until that dependency is available for reference, consistent with
  issue #16's own framing of core #75 as a prerequisite.
- Adding a `.gitignore` (Defect 3) is the first `.gitignore` in this
  repo — worth flagging to the approver since it's a repo-wide file, not
  scoped to `data-engineering` alone, even though its only current
  entry serves this plugin's test harness.

## Requirement 4 — old role names / ghost files

Manual survey (`docs/issue-16/reports/data-engineering/survey.md`)
found no stale role names or references to nonexistent files in
`README.md` or any of the four `.claude-plugin/plugin.json` manifests —
the only role names present are `data-engineering` (self) and
`data-modeling` (hand-off target), and every file `README.md`'s
"Layout"/"Methodology gate plugins" sections list was confirmed present
on disk. However, no canonical 43-role taxonomy list exists in this
checkout to cross-check `data-modeling` against — **N/A, cannot be
mechanically confirmed clean from this repo alone**; propose the
approver (or a role with access to the taxonomy source, e.g.
`on-the-record` or wherever `docs/issue-160/proposals/role-taxonomy.md`'s
successor now lives) cross-checks `data-modeling` against the current
43-role list as a lightweight follow-up, rather than this proposal
asserting a clean bill of health it cannot actually verify.

## Explicitly out of scope for this proposal

- No gate `.py`/`.sh` code is modified in this pass (role-handoff
  contract v3 s19, phase 1 = proposal only).
- No `hooks.json` file is modified in this pass.
- No approval is granted or implied by this document.
- `docs/issue-16/reports/data-engineering.md` is not touched (phase 2,
  locked per task scope).
