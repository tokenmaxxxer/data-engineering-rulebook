---
subject: issue-1
role: data-engineering
---

# Scout brief

Mode: parallel WebSearch, 4 angles, one sweep round, no deepening round run —
judge point: the sweep's combined results map 1:1 onto the survey's four unknowns
and this role's existing three `PRODUCES` fields (pipeline design / data-quality
check list / failure-handling plan), so another round would not change a build
decision. Stopped at 1 stage.

## Angle 1 — design-doc/RFC methodology (→ phase-1 proposal norm)
Must-bes: background/problem statement thorough enough for a reader with no prior
context; explicit proposed-solution section; consequences/trade-offs section; effort
proportionate to complexity (not every section fires for small changes). Freeform
beyond that core — orgs add sections but these three are the converging core.

## Angle 2 — data quality frameworks / data contracts (→ data-quality check list)
Must-bes: schema (columns/formats/types), verifiable thresholds for completeness /
uniqueness / accuracy / volume, and an enforcement point (dbt model contracts run
preflight checks; Great Expectations = Expectations + Suites + Checkpoints). Adopt:
"schema + concrete thresholds + where it's enforced" as the three sub-fields. Skip:
full framework adoption (Great Expectations/dbt itself) — out of scope, this role is
report-only and produces a checklist, not tooling.

## Angle 3 — pipeline reliability / incident practice (→ failure-handling plan)
Must-bes: named failure modes with diagnostic/first-check steps, an escalation path,
a recovery/rollback step, and an RTO tied to business impact (per-dataset, not
uniform). Google SRE data-processing workbook and dbt Labs/Monte Carlo converge on
the same shape: failure modes → detection → escalation → recovery target.

## Angle 4 — lineage/schema documentation (→ pipeline design)
Must-bes: sources/sinks and transformation steps named explicitly, ownership per
dataset, and change control (living document, not write-once). Confirms "pipeline
design" needs at minimum: data flow (source → transform → sink), ownership, and a
note on how the design is kept current.

## Gap line
Current state (survey.md) names the three `PRODUCES` fields but pins no internal
shape for any of them, and has no phase-1 proposal-document norm at all. All four
angles' must-bes are additions, not confirmations of something already specified.

## Segment fit
This role is a lightweight, report-only advisory role (`WRITE_SCOPE: []`), not a
full data platform team — norms are adopted as **minimum required sub-fields inside
a single record file**, not as separate documents or tooling adoption.

Sources:
- https://blog.pragmaticengineer.com/rfcs-and-design-docs/
- https://newsletter.pragmaticengineer.com/p/rfcs-and-design-docs
- https://www.datacamp.com/blog/data-contracts
- https://www.datadoghq.com/blog/dbt-data-quality-testing/
- https://www.getdbt.com/blog/data-slas-best-practices
- https://sre.google/workbook/data-processing/
- https://montecarlodata.com/how-to-conduct-incident-management-on-your-data-pipelines
- https://datadef.io/guides/en/data-pipeline-documentation
- https://datadef.io/guides/en/data-lineage-best-practices
- https://agility-at-scale.com/ai/data/data-lineage-and-metadata-management/
