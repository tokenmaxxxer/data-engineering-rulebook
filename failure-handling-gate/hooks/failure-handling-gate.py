#!/usr/bin/env python3
"""failure-handling-gate: mechanical PreToolUse gate for the
failure-handling-plan sub-field of issue-1's adopted PRODUCES shape (failure
modes + diagnostics + escalation + recovery target). One methodology = one
independent plugin, per issue-10's plugin-set requirement. Fail-closed: any
unparseable payload, unreadable file, or internal error denies rather than
allows.

Invoked as the Python payload of failure-handling-gate.sh, which has already
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

# Shared N/A-exemption + section-scoping logic, extracted (issue #16) out of
# three byte-identical per-gate copies into one data-engineering-owned
# module. Loaded by relative path, mirroring gate-lib.py's own load pattern.
_sections_spec = importlib.util.spec_from_file_location(
    "produces_sections",
    os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "..", "..", "data-engineering", "hooks", "lib", "produces-sections.py",
    ),
)
produces_sections = importlib.util.module_from_spec(_sections_spec)
_sections_spec.loader.exec_module(produces_sections)

GATE_NAME = "failure-handling-gate"
PROPOSAL_RE = re.compile(r"^docs/issue-[0-9]+/proposals/.*data-engineering.*\.md$")
RECORD_RE = re.compile(r"^docs/issue-[0-9]+/reports/data-engineering\.md$")
NA_RE = produces_sections.NA_RE

FAILURE_MODE_RE = re.compile(r"failure|mode|장애|실패", re.IGNORECASE)
DIAG_ESC_RECOVERY_RE = re.compile(
    r"diagnos|first[- ]check|escalat|recover|rollback|진단|에스컬레이션|복구|롤백",
    re.IGNORECASE,
)
RECOVERY_TARGET_RE = re.compile(
    r"RTO|recovery time|recovery[- ]time[- ]target|목표\s*시간|[0-9]+\s*(min|minute|hour|시간|분)",
    re.IGNORECASE,
)

OWN_LABEL_RE = produces_sections.FAILURE_HANDLING_LABEL_RE
OTHER_LABEL_RES = [
    produces_sections.PIPELINE_DESIGN_LABEL_RE,
    produces_sections.DATA_QUALITY_LABEL_RE,
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


section_slice = produces_sections.section_slice


def check(content):
    section = section_slice(content, OWN_LABEL_RE, OTHER_LABEL_RES)
    na_match = NA_RE.search(section)
    if na_match:
        return True, None
    missing = []
    if not FAILURE_MODE_RE.search(section):
        missing.append("named failure mode")
    if not DIAG_ESC_RECOVERY_RE.search(section):
        missing.append("diagnostic/escalation/recovery step")
    if not RECOVERY_TARGET_RE.search(section):
        missing.append("recovery-time target")
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
    if tool_name == "Bash":
        command = tool_input.get("command", "")
        targets = gate_lib.gate_bash_write_targets(command)
        if any(in_scope(t, cwd) for t in targets):
            deny(
                "Bash command may write to an in-scope PRODUCES path; "
                "this gate cannot deterministically verify Bash-written "
                "content — write via Write/Edit/MultiEdit instead"
            )
        sys.exit(0)
    file_path = tool_input.get("file_path", "")
    if not in_scope(file_path, cwd):
        sys.exit(0)
    content = resolve_content(tool_name, tool_input, cwd)
    ok, missing = check(content)
    if not ok:
        deny(
            "missing failure-handling element(s): "
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
