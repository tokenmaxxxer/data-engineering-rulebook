#!/usr/bin/env python3
"""pipeline-design-gate: mechanical PreToolUse gate for the pipeline-design
sub-field of issue-1's adopted PRODUCES shape (source -> transform -> sink +
ownership + change-control). One methodology = one independent plugin, per
issue-10's plugin-set requirement. Fail-closed: any unparseable payload,
unreadable file, or internal error denies rather than allows.

Invoked as the Python payload of pipeline-design-gate.sh, which has already
installed the fail-closed EXIT trap and checked the kill switch (both via
core/hooks/lib/gate-lib.sh) before this file ever runs. This file loads the
sibling core/hooks/lib/gate-lib.py via the GATE_LIB_PY env var that
gate-lib.sh exports, per that library's own usage docstring.
"""
import importlib.util
import os
import re
import sys

_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate_lib)

GATE_NAME = "pipeline-design-gate"
PROPOSAL_RE = re.compile(r"^docs/issue-[0-9]+/proposals/.*data-engineering.*\.md$")
RECORD_RE = re.compile(r"^docs/issue-[0-9]+/reports/data-engineering\.md$")
NA_RE = re.compile(r"(N/A|해당\s*없음)\s*[,:\-—]?\s*(\S.{2,})")

ARROW_RE = re.compile(r"(→|->)")
FLOW_RE = re.compile(r"source|transform|sink|소스|변환|싱크", re.IGNORECASE)
OWNER_RE = re.compile(r"owner|ownership|오너|담당", re.IGNORECASE)
CHANGE_RE = re.compile(
    r"change[- ]control|change control|stays current|변경\s*관리|현행화", re.IGNORECASE
)

# Section labels for all three PRODUCES sub-fields, per directive.sh's
# literal sub-field names ("pipeline design", "data-quality check list",
# "failure-handling plan"), matched case-insensitively as a line-leading
# label. Used to scope each gate's checks to its own section slice
# (defect #3: an N/A or a keyword mention in one sub-field's paragraph no
# longer bleeds into another gate's independent check).
OWN_LABEL_RE = re.compile(
    r"^\s*(?:pipeline\s*design|파이프라인\s*설계)\s*[:：]", re.IGNORECASE
)
OTHER_LABEL_RES = [
    re.compile(
        r"^\s*(?:data[- ]quality(?:\s+check\s*list)?|데이터\s*품질(?:\s*체크\s*리스트)?)\s*[:：]",
        re.IGNORECASE,
    ),
    re.compile(
        r"^\s*(?:failure[- ]handling(?:\s+plan)?|장애\s*(?:처리|대응)(?:\s*계획)?)\s*[:：]",
        re.IGNORECASE,
    ),
]


def in_scope(file_path, cwd):
    tail = gate_lib.gate_normalize_path(cwd, file_path)
    if tail is None:
        return False
    return bool(PROPOSAL_RE.match(tail) or RECORD_RE.match(tail))


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


def section_slice(content, own_re, other_res):
    """Slice `content` down to this gate's own PRODUCES sub-field section:
    from its label line to the next recognized label line (this gate's or
    a sibling gate's) or EOF. If no recognized label exists anywhere in the
    document, falls back to treating the whole document as the section
    (old, pre-remediation behavior) — this is what stops *cross-gate*
    leakage while still tolerating an informal, unlabeled document that
    only concerns this one gate's scope."""
    lines = content.splitlines(keepends=True)
    label_starts = []
    for i, line in enumerate(lines):
        if own_re.match(line):
            label_starts.append((i, True))
        elif any(r.match(line) for r in other_res):
            label_starts.append((i, False))
    if not label_starts:
        return content
    own_idx = next((i for i, is_own in label_starts if is_own), None)
    if own_idx is None:
        return ""
    next_idx = next((i for i, _is_own in label_starts if i > own_idx), len(lines))
    return "".join(lines[own_idx:next_idx])


def check(content):
    section = section_slice(content, OWN_LABEL_RE, OTHER_LABEL_RES)
    na_match = NA_RE.search(section)
    if na_match:
        return True, None
    missing = []
    if not ARROW_RE.search(section):
        missing.append("flow arrow (→/->)")
    if len(FLOW_RE.findall(section)) < 2:
        missing.append("source/transform/sink language (need at least 2 of the 3)")
    if not OWNER_RE.search(section):
        missing.append("dataset ownership mention")
    if not CHANGE_RE.search(section):
        missing.append("change-control / stays-current note")
    if missing:
        return False, missing
    return True, None


def deny(reason):
    sys.stderr.write(f"{GATE_NAME}: refused — {reason}\n")
    sys.exit(2)


def main():
    raw = sys.stdin.read()
    payload = gate_lib.gate_parse_json_or_deny(raw, deny)
    cwd = os.getcwd()
    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {})
    if not isinstance(tool_input, dict):
        tool_input = {}
    file_path = tool_input.get("file_path", "")
    if not in_scope(file_path, cwd):
        sys.exit(0)
    content = resolve_content(tool_name, tool_input, cwd)
    ok, missing = check(content)
    if not ok:
        deny(
            "missing pipeline-design element(s): "
            + "; ".join(missing)
            + " (or state N/A immediately followed by a reason)"
        )
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # fail-closed: any internal error denies
        deny(f"internal error, failing closed: {exc}")
