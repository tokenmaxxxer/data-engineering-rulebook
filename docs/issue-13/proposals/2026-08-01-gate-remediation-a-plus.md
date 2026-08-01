# Issue #13 proposal: A+ remediation for the three data-engineering gates

Phase 1 proposal only — no implementation in this PR. Current-state
findings: `docs/issue-13/reports/data-engineering/survey.md`.

## 0. Adoption stance

`core/hooks/lib/gate-lib.sh` + `gate-lib.py` (core issue #72, landed on
`tokenmaxxxer-core` `main`) are referenced, never reimplemented, per
`docs/handbooks/canon-scripts.md`'s reference-not-copy rule and
`gate-house-standard.md`'s per-repo migration checklist. Every fix below
maps to a `gate_*` call from that library, not a hand-rolled equivalent.

## 1. Structural change: Python payload gains a thin bash entrypoint

Today each `<name>-gate.sh` file *is* Python (shebang-only, no bash
layer), so there is no shell frame to install
`gate_trap_fail_closed`'s EXIT trap. Proposed shape, one per gate:

```
<gate>/hooks/<gate>-gate.sh          # bash entrypoint (new, ~10 lines)
<gate>/hooks/<gate>-gate.py          # existing Python payload, moved
```

`hooks.json`'s `command` keeps pointing at `.../hooks/<gate>-gate.sh`
(no `hooks.json` change). The new `.sh`:

```bash
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${DATA_ENGINEERING_<NAME>_GATE_OFF:-}" || { trap - EXIT; exit 0; }
exec python3 "$(dirname "${BASH_SOURCE[0]}")/<gate>-gate.py"
```

This gives every gate the canonical fail-closed EXIT trap (defect #5) and
moves the kill-switch check (currently hand-rolled Python, missing the
`yes` on-spelling — defect from survey §4) to `gate_kill_switch_active`
before Python even starts. `${CLAUDE_PLUGIN_ROOT_CORE}` resolution mirrors
`data-engineering/hooks/directive.sh`'s existing sibling-plugin pattern —
no new resolution convention introduced.

The Python payload keeps its own top-level `try/except` (defense in
depth: a Python-internal exception still denies via `gate_deny`-equivalent
stdout removed / stderr added, see §2), but no longer needs to duplicate
the kill-switch check.

## 2. Deny reason: stdout JSON → stderr

Replace each gate's `deny()`:

```python
def deny(reason):
    sys.stderr.write(f"{GATE_NAME}: refused — {reason}\n")
    sys.exit(2)
```

matching `gate_deny`'s exact stderr protocol (`"<name>: refused — <msg>"`,
exit 2) so the Python payload and the bash `gate_deny`/`gate_allow`
convention stay byte-for-byte consistent even though the check logic
itself stays in Python. `GATE_NAME` is the existing per-gate string
literal already used in each `deny()` call site.

## 3. Absolute-path anchor: `gate_normalize_path`

`in_scope()` changes from a raw regex match on `tool_input.file_path` to:

```python
import importlib.util, os
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

def in_scope(file_path, cwd):
    tail = gate_lib.gate_normalize_path(cwd, file_path)
    if tail is None:
        return False
    return bool(PROPOSAL_RE.match(tail) or RECORD_RE.match(tail))
```

`cwd` is `os.getcwd()` at gate invocation (the project root Claude Code
runs the hook from — matches how `tests/run-gate-tests.sh` already `cd`s
into a synthetic worktree before invoking the gate). `PROPOSAL_RE`/
`RECORD_RE` keep matching the root-relative tail
(`gate_normalize_path` strips the root and returns a relative,
forward-slash path), so both a relative `docs/issue-N/...` and an
absolute `<cwd>/docs/issue-N/...` normalize to the identical tail and
match identically (defect #1 fixed) — including `./`-prefixed input,
since `gate_normalize_path` runs `posixpath.normpath` on both sides.

## 4. `replace_all` / MultiEdit / NotebookEdit: `gate_reconstruct_write`

`resolve_content()` is replaced with a direct call:

```python
def resolve_content(tool_name, tool_input, cwd):
    file_path = tool_input.get("file_path", "")
    current = None
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            current = f.read()
    elif tool_name != "Write":
        current = ""
    text, ok = gate_lib.gate_reconstruct_write(tool_name, tool_input, current)
    if not ok:
        raise ValueError(f"cannot reconstruct {tool_name} result deterministically")
    return text
```

This fixes the confirmed `replace_all`-ignored bug identically to
issue-72's `record-fields-gate.sh` fix (survey §4): `Edit`'s
`replace_all: true` now replaces every occurrence via
`gate_reconstruct_write`'s `_apply_replace`, `MultiEdit` honors each
edit's own flag independently, and `NotebookEdit` (currently: hard
`ValueError` / unsupported) gets real handling — the edited cell's
`new_source` on `insert`/`replace` modes, `ok=False` (→ deny, fail-closed,
same posture as today) otherwise. `gate_lib`'s `import`/`exec_module` is
the load boilerplate from `gate-lib.py`'s own usage comment, one copy per
gate payload (the copy is the *loader stanza*, not the library — the
library file itself is never vendored, consistent with
`canon-scripts.md`).

## 5. Malformed-JSON deny: `gate_parse_json_or_deny`

`main()`'s `payload = json.load(sys.stdin)` is replaced with:

```python
raw = sys.stdin.read()
payload = gate_lib.gate_parse_json_or_deny(raw, deny)
```

covering empty payload, non-JSON, and non-object top level uniformly
(today's bare `json.load` only denies via the outer catch-all
`except Exception`, which works but is untested — see §7's mandatory
case list).

## 6. N/A scoping: section-local, not whole-document

Defect #3 (a single N/A line anywhere waives every sub-field across all
three gates, because all three regex-search the same whole-file
`content`) is not something `gate-lib.sh`/`gate-lib.py` covers — it is
data-engineering's own PRODUCES-shape semantics, out of core's scope.
Proposed fix, applied identically in all three `check()` functions:

1. Split `content` into sections by the existing PRODUCES sub-field
   labels the methodology directive already establishes as the write
   contract (`directive.sh`'s literal sub-field names: "pipeline design",
   "data-quality check list", "failure-handling plan" — matched
   case-insensitively as a line-leading label, e.g.
   `^\s*(?:pipeline design|파이프라인\s*설계)\s*[:：]`, one such pattern
   per gate for its own sub-field).
2. A gate's `NA_RE` search is scoped to **that gate's own section slice**
   (from its label line to the next recognized label line or end of
   file), never the full document. A document with no recognized section
   labels at all (a proposal too small/informal to have split its
   sub-fields into labeled paragraphs) falls back to whole-document N/A
   matching **only when the document contains exactly one sub-field's
   worth of content for that gate's scope** — in practice, this means:
   if section labels are absent, treat the whole file as the section (old
   behavior) but only for the gate whose kill-switch fires; the section
   split is what stops *cross-gate* leakage, not single-gate scanning.
3. Net effect: `"N/A, trivial"` written once inside the pipeline-design
   paragraph no longer satisfies `data-quality-gate`'s or
   `failure-handling-gate`'s independent `NA_RE.search`, because each
   gate now searches its own section slice, and the pipeline-design
   section is not part of either other gate's slice.

This is the proportionality escape hatch the directive already documents
("A trivial non-breaking change may write 'N/A, <reason>' per sub-field")
— the fix makes "per sub-field" actually mean per sub-field.

## 7. Semantic checks: substring → section/adjacency/structure

Issue requirement 2. Each gate's keyword regexes currently `search()` the
whole document independent of position; upgraded to check **adjacency
within the gate's own section slice** (§6's slice), not just presence
anywhere in the file:

- `pipeline-design-gate`: `ARROW_RE` (`→`/`->`) must occur **within the
  same section slice** as at least 2 of the 3 `FLOW_RE` terms
  (source/transform/sink language), not merely both present somewhere in
  the document — an arrow used in an unrelated sentence elsewhere no
  longer satisfies the flow requirement.
- `data-quality-gate`: `THRESHOLD_RE`'s existing pattern already requires
  a number adjacent (within ~40 chars) to a named dimension
  (completeness/uniqueness/accuracy/volume) or vice versa — this
  adjacency is already correct in isolation; the upgrade is scoping the
  *whole check* (schema + threshold + enforcement) to the section slice
  so a schema mention in the pipeline-design section can't satisfy the
  data-quality gate's schema requirement by whole-document bleed.
- `failure-handling-gate`: `RECOVERY_TARGET_RE` (a number + time unit)
  must occur in the same section slice as `DIAG_ESC_RECOVERY_RE`
  (diagnostic/escalation/recovery language) — a recovery-time number
  belonging to an unrelated SLA mention elsewhere in the document no
  longer satisfies the recovery-target requirement.

Structure requirement (issue's "구조 검사"): each gate additionally
requires its 2-3 element checks to appear **in the same section slice as
each other**, not scattered across the whole file — this is the
mechanical form of "섹션/인접성/구조", implemented as slice-scoping (§6)
plus intra-slice regex adjacency (this section), both derived from
regexes the gates already carry — no new NLP/parsing dependency, keeping
the "no new tooling as a dependency" constraint `directive.sh` already
states.

## 8. Mandatory test cases (issue requirement 3)

Added to each gate's `tests/<gate>.test.sh` plus a new
`tests/gate-lib-compliance.test.sh` adapted from
`gate-house-standard.md`'s six-case list, scoped to what applies to a
Python-payload gate (cases 1-4 directly; cases 5-6 via `assert_gate`'s
existing `Write`-only harness extended to build `Edit`/`MultiEdit`/
`Bash` payloads — `run-gate-tests.sh`'s `assert_gate` needs a
`tool_name`/`tool_input` parameterization, currently hardcoded to
`Write`):

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string` — asserts every occurrence replaced, not just the first.
2. `MultiEdit` with mixed `replace_all: true`/`false` edits in one call.
3. Malformed JSON: truncated, non-object (`"just a string"`), and empty
   stdin — all three deny.
4. Kill-switch set to an unrecognized value (e.g. `DATA_ENGINEERING_
   PIPELINE_DESIGN_GATE_OFF=maybe`) — asserts the gate stays **active**
   (this is the exact bug class issue-72 found and fixed; a data-engineering
   gate that duplicates the old inverted logic must be caught here).
5. Absolute `file_path` reaching the same scope a relative-path fixture
   already covers, plus a `./`-prefixed variant.
6. A `Bash`-tool file write reaching the same target a `Write`-tool call
   would hit (via `gate_bash_write_targets`, if bash-tool coverage is
   adopted — see open question below).
7. (data-engineering-specific, beyond the core six) N/A scoped to one
   sub-field's section: asserts the *other two* gates still deny on the
   same document (regression test for defect #3/§6).

All existing `tests/*.test.sh` cases plus these additions must be green at
delivery time (issue requirement 3's "배송 상태에서 전 스위트 green"),
verified in phase 2, not phase 1.

## 9. README resync (issue requirement 4)

Add to `README.md`'s plugin table/layout section once phase 2 lands: the
new `<gate>-gate.py` payload file per plugin, the `GATE_LIB_PY`/
`gate-lib.sh` dependency on the sibling `core` plugin (mirroring
`directive.sh`'s existing `CLAUDE_PLUGIN_ROOT_CORE` note), and the new
`gate-lib-compliance.test.sh` file. Per the survey, no ghost files exist
today, so this is forward maintenance, not a current-state fix.

## Open question for phase 2

`gate_bash_write_targets` (test case 6 / defect-class parity with
`approval-gate.sh`/`board-gate.sh`) requires the gate to also match on
the `Bash` tool, but `hooks.json`'s current matcher is
`"Write|Edit|MultiEdit"` only — extending to catch a `Bash`-tool write
targeting `docs/issue-N/proposals/...` needs a `hooks.json` matcher
change (`Write|Edit|MultiEdit|Bash`) plus token-scanning dispatch logic
in each gate, not just a library call. Proposed for phase 2 scope, listed
here so it isn't silently dropped, per the issue's full-defect-list
requirement — flag for approver attention rather than pre-deciding
matcher scope expansion unilaterally in this proposal.

## Compliance-check gate (forward reference)

`core/hooks/tests/compliance-check.sh` (issue-72's detector) is designed
to be run against `docs/issue-13/proposals/` or `hooks/` directories per
`gate-house-standard.md`'s migration checklist step 1/4. Phase 2 runs it
before and after migration and records both outputs as evidence in
`docs/issue-13/reports/data-engineering.md`; not run in this phase-1
proposal since it evaluates the migrated code, which doesn't exist yet.
