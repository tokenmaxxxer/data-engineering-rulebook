---
proposal: docs/issue-19/proposals/2026-08-09-spec-alignment.md
---

# Hunt record — spec-alignment

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — the proposed token-presence strengthening (checking that `model_name`/`column_name`/`data_type`/`constraint`/`verdict` appear as literal words in the section) is satisfied by writing the five field names as a bare sentence with no actual schema content, exactly like the existing SCHEMA_RE/THRESHOLD_RE/ENFORCE_RE checks it extends are already bypassed today.
Kind: design-error
Seed: docs/issue-19/proposals/2026-08-09-spec-alignment.md §"What will be done" item 1 (data-quality-gate content-shape strengthening), evaluated against data-quality-gate/hooks/data-quality-gate.py and data-engineering/hooks/lib/produces-sections.py
cap_seconds: 60
tier: default
diff_stat_lines: 3 files added (proposal, survey, scout-brief), no code changed yet
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:01:30Z

### Reproduce
```
python3 - <<'PY'
import importlib.util, re
spec = importlib.util.spec_from_file_location('sections', 'data-engineering/hooks/lib/produces-sections.py')
sections = importlib.util.module_from_spec(spec); spec.loader.exec_module(sections)
SCHEMA_RE = re.compile(r'schema|column|dtype|data type|format|스키마|컬럼|타입|포맷', re.IGNORECASE)
THRESHOLD_RE = re.compile(r'(completeness|uniqueness|accuracy|volume|완전성|고유성|정확성|볼륨)[^\n]{0,40}?[0-9]|[0-9][^\n]{0,40}?(%|percent|건|개)', re.IGNORECASE)
ENFORCE_RE = re.compile(r'enforc|check\b|stage|검증|단계|모니터링|monitor', re.IGNORECASE)
content = "Data quality: model_name column_name data_type constraint verdict, completeness 1%, enforced at check stage."
section = sections.section_slice(content, sections.DATA_QUALITY_LABEL_RE, [sections.PIPELINE_DESIGN_LABEL_RE, sections.FAILURE_HANDLING_LABEL_RE])
print(bool(SCHEMA_RE.search(section)), bool(THRESHOLD_RE.search(section)), bool(ENFORCE_RE.search(section)))
PY
```

### Observed
`True True True` — the existing content-shape checks the proposal says it will extend already pass on a single throwaway sentence that just names the required concepts as bare words, with zero real column names, zero real data types, and zero real per-entry structure. The proposal's plan ("require the data-quality section to name, per schema entry, all of `model_name`/`column_name`/`data_type`/`constraint`... as required tokens inside the existing label, not a new labeled sub-section") describes the same literal-substring-presence mechanism, not a per-entry structural parse, so a payload like `"Data quality: model_name=x column_name=x data_type=x constraint=x verdict=x"` would satisfy the strengthened gate exactly once, regardless of how many real schema entries exist or whether the four/five tokens are ever associated with each other.

### Expected
A content-shape gate whose stated purpose is "require ... per schema entry" should not be satisfiable by a single flat mention of the five field names; the proposal does not specify any per-entry grouping/repetition check (e.g. one token-set per bullet/row), so as written it inherits — and does not close — the exact "write the required word once, satisfy the gate" bypass this class of regex-presence check already has today.
