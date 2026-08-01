"""produces-sections.py: shared N/A-exemption and section-scoping helpers
for the three data-engineering PRODUCES gates (pipeline-design-gate,
data-quality-gate, failure-handling-gate). Issue #16 re-audit finding:
`NA_RE`, the three-way label regex triple, and `section_slice()` were
byte-identical across all three gates' `.py` payloads — three
independently-editable copies of the same exemption/section-boundary
logic, exactly the drift the canon reference-not-copy discipline
(docs/handbooks/canon-scripts.md) exists to prevent. Extracted here, owned
by data-engineering itself (this is PRODUCES sub-field semantics, not a
generic gate-house concern core owns).

Loaded via importlib by each gate's own Python payload, the same pattern
gate-lib.py already uses:

    import importlib.util, os
    _spec = importlib.util.spec_from_file_location(
        "produces_sections",
        os.path.join(os.path.dirname(os.path.abspath(__file__)),
                      "..", "..", "data-engineering", "hooks", "lib",
                      "produces-sections.py"),
    )
    produces_sections = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(produces_sections)

Reference only, never copy.
"""
import re

NA_RE = re.compile(r"(N/A|해당\s*없음)\s*[,:\-—]?\s*(\S.{2,})")

# One label regex per PRODUCES sub-field, per directive.sh's literal
# sub-field names ("pipeline design", "data-quality check list",
# "failure-handling plan"), matched case-insensitively as a line-leading
# label.
PIPELINE_DESIGN_LABEL_RE = re.compile(
    r"^\s*(?:pipeline\s*design|파이프라인\s*설계)\s*[:：]", re.IGNORECASE
)
DATA_QUALITY_LABEL_RE = re.compile(
    r"^\s*(?:data[- ]quality(?:\s+check\s*list)?|데이터\s*품질(?:\s*체크\s*리스트)?)\s*[:：]",
    re.IGNORECASE,
)
FAILURE_HANDLING_LABEL_RE = re.compile(
    r"^\s*(?:failure[- ]handling(?:\s+plan)?|장애\s*(?:처리|대응)(?:\s*계획)?)\s*[:：]",
    re.IGNORECASE,
)


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
