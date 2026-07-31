#!/usr/bin/env python3
"""failure-handling-gate: mechanical PreToolUse gate for the
failure-handling-plan sub-field of issue-1's adopted PRODUCES shape (failure
modes + diagnostics + escalation + recovery target). One methodology = one
independent plugin, per issue-10's plugin-set requirement. Fail-closed: any
unparseable payload, unreadable file, or internal error denies rather than
allows."""
import json
import os
import re
import sys

KILL_SWITCH = "DATA_ENGINEERING_FAILURE_HANDLING_GATE_OFF"
PROPOSAL_RE = re.compile(r"^docs/issue-[0-9]+/proposals/.*data-engineering.*\.md$")
RECORD_RE = re.compile(r"^docs/issue-[0-9]+/reports/data-engineering\.md$")
NA_RE = re.compile(r"(N/A|해당\s*없음)\s*[,:\-—]?\s*(\S.{2,})")

FAILURE_MODE_RE = re.compile(r"failure|mode|장애|실패", re.IGNORECASE)
DIAG_ESC_RECOVERY_RE = re.compile(
    r"diagnos|first[- ]check|escalat|recover|rollback|진단|에스컬레이션|복구|롤백",
    re.IGNORECASE,
)
RECOVERY_TARGET_RE = re.compile(
    r"RTO|recovery time|recovery[- ]time[- ]target|목표\s*시간|[0-9]+\s*(min|minute|hour|시간|분)",
    re.IGNORECASE,
)


def in_scope(path):
    return bool(PROPOSAL_RE.match(path) or RECORD_RE.match(path))


def resolve_content(tool_name, tool_input):
    file_path = tool_input.get("file_path", "")
    if tool_name == "Write":
        return tool_input.get("content", "")
    current = ""
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            current = f.read()
    if tool_name == "Edit":
        old = tool_input.get("old_string", "")
        new = tool_input.get("new_string", "")
        if old and old not in current:
            raise ValueError("old_string not found in current file content")
        return current.replace(old, new, 1) if old else current + new
    if tool_name == "MultiEdit":
        for edit in tool_input.get("edits", []):
            old = edit.get("old_string", "")
            new = edit.get("new_string", "")
            if old and old not in current:
                raise ValueError("old_string not found in current file content")
            current = current.replace(old, new, 1) if old else current + new
        return current
    raise ValueError(f"unsupported tool_name {tool_name!r}")


def check(content):
    na_match = NA_RE.search(content)
    if na_match:
        return True, None
    missing = []
    if not FAILURE_MODE_RE.search(content):
        missing.append("named failure mode")
    if not DIAG_ESC_RECOVERY_RE.search(content):
        missing.append("diagnostic/escalation/recovery step")
    if not RECOVERY_TARGET_RE.search(content):
        missing.append("recovery-time target")
    if missing:
        return False, missing
    return True, None


def deny(reason):
    print(
        json.dumps(
            {
                "decision": "block",
                "reason": f"failure-handling-gate: {reason}",
            }
        )
    )
    sys.exit(2)


def main():
    if os.environ.get(KILL_SWITCH, "").lower() in ("1", "true", "on"):
        sys.exit(0)
    payload = json.load(sys.stdin)
    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {})
    file_path = tool_input.get("file_path", "")
    if not in_scope(file_path):
        sys.exit(0)
    content = resolve_content(tool_name, tool_input)
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
