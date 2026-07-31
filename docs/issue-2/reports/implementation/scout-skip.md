---
subject: issue-2
role: implementation
---

# Scout skip record

Scouting skipped. Reason: the spec (issue #2, and the transition-path
sections of core issue #63/#66's own implementation records) leaves no open
design decision — it names the exact files to delete, the exact stub shape
(`core_role_directive` call form checked mechanically by
`core/hooks/tests/stub-check.sh`), and the exact escape hatch
(`RECORD_FIELDS_TERMINAL_STATES`) already. This is the per-rulebook
mechanical follow-up those two core issues explicitly deferred, not a
product-shaped decision to scout best-in-class exemplars for.
