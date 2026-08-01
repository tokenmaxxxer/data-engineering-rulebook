# Issue #13 current-state survey (phase 1)

Scope: the three PRODUCES gate plugins (`pipeline-design-gate`,
`data-quality-gate`, `failure-handling-gate`), their shared test harness
(`tests/run-gate-tests.sh` + per-gate `.test.sh` files), and `README.md`,
against the 2026-08-01 audit's four defect classes.

## 1. Relative-path anchor doesn't fire on absolute paths

Every gate's `in_scope()` regex-matches `tool_input.file_path` verbatim
against `^docs/issue-[0-9]+/...`. Claude Code can pass an absolute
`file_path` (and does, per issue-72's own survey of this exact defect class
across core). An absolute path never matches the `^docs/` anchor, so
`in_scope()` returns `False` and the gate silently allows — fail-open on
the write it exists to catch. Confirmed in all three gates
(`pipeline-design-gate/hooks/pipeline-design-gate.sh:25-26`,
`data-quality-gate/hooks/data-quality-gate.sh:30-31`,
`failure-handling-gate/hooks/failure-handling-gate.sh:29-30`). No test
exercises an absolute or `./`-prefixed path today.

## 2. Deny reason lost on stdout

`deny()` in all three gates prints a `{"decision": "block", "reason": ...}`
JSON blob to **stdout**, then `sys.exit(2)`. The house convention
(`gate-lib.sh`'s `gate_deny`, adopted uniformly across core after
issue-72) is stderr-only: `echo "...: refused — ..." >&2; exit 2`. Whether
Claude Code's PreToolUse hook surfaces a stdout JSON payload or only
consumes the exit code is exactly the ambiguity issue-72's audit flagged
core's own gates for before standardizing on stderr — the current
data-engineering gates never resolved it and inherited the same exposure.

## 3. One-line N/A exempts the whole document

`NA_RE = re.compile(r"(N/A|해당\s*없음)\s*[,:\-—]?\s*(\S.{2,})")` is
searched against the **entire file content**, not scoped to the specific
sub-field it is meant to exempt. A single `"N/A, trivial"` line anywhere in
a multi-field proposal (e.g. inside the pipeline-design paragraph)
satisfies `NA_RE.search(content)` and short-circuits `check()` for
*every* gate that scans the same file — the data-quality and
failure-handling gates read the identical whole-content `content` string,
so one N/A note written for one sub-field silently waives all three.
Confirmed by reading `check()` in all three gates: `na_match` gates the
entire function, no section/heading scoping.

## 4. Zero Edit/MultiEdit/malformed-JSON/kill-switch test coverage

`tests/*.test.sh` and `tests/run-gate-tests.sh`'s `assert_gate` helper only
ever construct a `Write` tool-call payload
(`run-gate-tests.sh:29-34`, hardcoded `"tool_name": "Write"`). No test
sends `Edit`, `MultiEdit`, malformed JSON, or a kill-switch env var. This
matches the audit's "Edit/킬스위치/malformed 테스트 0" finding exactly.

Underlying code defect this coverage gap was hiding: `resolve_content()`'s
`Edit`/`MultiEdit` branches always call
`current.replace(old, new, 1)` (first occurrence only) regardless of
`tool_input.get("replace_all")` — the identical `replace_all`-ignored bug
issue-72's survey found in core's own `record-fields-gate.sh` before that
migration. `MultiEdit` also raises `ValueError` (→ fail-closed deny, at
least not fail-open) whenever any edit's `old_string` is absent, but never
honors a true `replace_all: true` edit's intent to replace every
occurrence. `NotebookEdit` is not handled at all (falls to the generic
`raise ValueError(f"unsupported tool_name...")`, which — because the
`main()` outer `try/except` denies on any exception — is at least
fail-closed, just untested and undocumented).

Kill-switch check itself (`os.environ.get(KILL_SWITCH, "").lower() in
("1","true","on")`) already matches the *correct* fixed convention
direction (only recognized on-spellings disable) — unlike core's
pre-issue-72 bug, this one is not inverted. But it is a hand-rolled
duplicate of `gate_kill_switch_active`, missing the `yes` on-spelling
`gate_kill_switch_active` recognizes, and has no test asserting an
*unrecognized* value stays active.

## 5. Fail-closed trap: absent, and matters

None of the three gates install any trap. `main()` is called inside a
top-level `try/except Exception` that denies on any exception, which
covers most in-process failures — but does not cover a Python-level
`SyntaxError`/import failure before `main()` even starts, or the process
being killed by a signal. `gate-lib.sh`'s `gate_trap_fail_closed` exists
precisely to remap "the hook process exited some way other than 0 or 2"
(which Claude Code treats as non-blocking / fail-open) to exit 2. These
gates are pure Python invoked directly via shebang (no bash wrapper), so
there is currently no place to install a shell-level EXIT trap at all —
adopting `gate_trap_fail_closed` requires introducing a thin bash
entrypoint per gate (see proposal).

## 6. Semantic checks are bare substring/regex hits

All three `check()` functions independently `re.search`/`re.findall` a
keyword-ish pattern anywhere in the whole document
(`SCHEMA_RE`/`THRESHOLD_RE`/`ENFORCE_RE`,
`FAILURE_MODE_RE`/`DIAG_ESC_RECOVERY_RE`/`RECOVERY_TARGET_RE`,
`ARROW_RE`/`FLOW_RE`/`OWNER_RE`/`CHANGE_RE`). A document that mentions
"schema" once in an unrelated sentence and a number anywhere else passes
`data-quality-gate` with no schema actually specified next to a threshold
— word-mention, not structural adjacency. This is the issue's "시맨틱 검사를
부분문자열에서 섹션/인접성/구조 검사로 상향" requirement; addressed in the
proposal's semantic-upgrade section.

## 7. README ghost content

`README.md`'s table and layout section match the actual plugin directory
names, hook filenames, and kill-switch env vars 1:1 against a fresh
listing (`pipeline-design-gate/`, `data-quality-gate/`,
`failure-handling-gate/`, `tests/*.test.sh`, `tests/run-gate-tests.sh`,
`tests/produces-combination.test.sh` all exist and match). **No ghost
files found** in the current README — this defect class was already
clean going into issue #13. The proposal still needs to add the
gate-lib.sh/gate-lib.py adoption + new mandatory test cases to keep the
README in sync going forward (issue requirement 4 is forward-looking:
"실물과 정합화" after the fixes land, not a currently-broken pointer).

## Precondition check: core issue #72 landing

Confirmed landed on `tokenmaxxxer/tokenmaxxxer-core` `main`:
`core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py`,
`docs/handbooks/gate-house-standard.md`,
`docs/handbooks/role-gates-tests.md`. Fetched and read in full; contents
summarized in the proposal's adoption section. `gate-lib.sh` exposes
`gate_trap_fail_closed`, `gate_kill_switch_active`, `gate_deny`,
`gate_allow`, `gate_bash_write_targets` (bash). `gate-lib.py` exposes
`gate_parse_json_or_deny`, `gate_normalize_path`, `gate_reconstruct_write`
(Python, loaded via `importlib` against `$GATE_LIB_PY`, which
`gate-lib.sh` exports when sourced). Both files carry an explicit
"reference only, never copy" contract enforced by core's own
`stub-check.sh`/`canon-manifest.txt` — the proposal must not vendor a copy
into this repo.

## Scout skip record

Skip condition: the issue and its precondition (core issue #72) name a
specific, already-landed shared library that must be referenced, not
reimplemented — this forecloses the external-field survey scout normally
runs (there is no competing "best-in-class" implementation to compare
against; the one correct answer is the named canon). The only design
freedom left (how to structure the section/adjacency semantic-check
upgrade) is internal methodology-grading detail, not a product category
with external exemplars. Scouting is skipped per the "spec leaves no
design decision open" condition for the adoption axis; the semantic-check
design is worked directly in the proposal from this repo's own PRODUCES
shape (`docs/issue-1`, `docs/issue-10` decisions), not from an external
sweep.
