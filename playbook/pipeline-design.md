---
axis: pipeline-design
rule_count_floor: 10
---

# Pipeline design — decision rules

Condition → choice → source. Each rule is `addition` or `**REMOVAL**`.

1. When the destination warehouse/lakehouse has enough spare compute to
   run transforms in-place and the team's strongest skill is SQL, choose
   ELT (land raw, transform in the warehouse) over ETL. **addition**
   source: [Fivetran — Data Pipeline vs. ETL](https://www.fivetran.com/learn/data-pipeline-vs-etl), [Stripe — ETL vs ELT Pipelines](https://stripe.com/resources/more/etl-vs-elt-pipelines)

2. When the destination system has limited compute, or a regulation
   (GDPR/HIPAA/CCPA-class) requires masking/validation before data is
   persisted, choose ETL (transform before load) over ELT. **addition**
   source: [Domo — ETL Pipeline vs Data Pipeline](https://www.domo.com/learn/article/etl-pipeline-vs-data-pipeline)

3. When some source domains need strict pre-load validation (PII,
   financial) and others don't, split the pipeline: run ETL for the
   regulated domains and ELT for the rest, rather than forcing one
   pattern across the whole pipeline. **addition**
   source: [Domo — ETL Pipeline vs Data Pipeline](https://www.domo.com/learn/article/etl-pipeline-vs-data-pipeline)

4. When a task can be retried by an orchestrator (network blip, timeout,
   restart — the normal case for any scheduled pipeline), design the
   transform/sink step to be idempotent (same input twice = same
   downstream state) rather than relying on "this won't run twice."
   **addition**
   source: [Airbyte — Idempotency in Data Pipelines](https://airbyte.com/data-engineering-resources/idempotency-in-data-pipelines)

5. When idempotency is needed for a batch load, prefer overwrite-the-
   whole-partition (replace the complete partition for the period being
   processed) over row-level dedup logic — it is the simplest pattern
   that is provably correct under retries. **addition**
   source: [Airbyte — Idempotency in Data Pipelines](https://airbyte.com/data-engineering-resources/idempotency-in-data-pipelines)

6. When idempotency is needed for a streaming/incremental sink, prefer
   upsert-on-primary-key (MERGE / ON CONFLICT) at the destination over
   building custom duplicate-suppression logic in the pipeline code.
   **addition**
   source: [Airbyte — Idempotency in Data Pipelines](https://airbyte.com/data-engineering-resources/idempotency-in-data-pipelines)

7. When the use case is aggregation-sensitive or business-critical
   (fraud detection, inventory counts, billing), require exactly-once
   *effective* semantics (via idempotent upsert, not a literal
   exactly-once delivery guarantee, which distributed systems rarely
   provide) — do not settle for plain at-least-once with no dedup layer.
   **addition**
   source: [Airbyte — Idempotency in Data Pipelines](https://airbyte.com/data-engineering-resources/idempotency-in-data-pipelines)

8. When a dataset has more than one plausible owning team, name exactly
   one accountable data owner (decision authority) plus a data steward
   (day-to-day quality/definitions) before the pipeline ships — per
   DAMA-DMBOK's owner/steward/custodian split — rather than leaving
   ownership implicit in "whoever built it." **addition**
   source: [OvalEdge — DAMA-DMBOK Data Governance Framework](https://www.ovaledge.com/blog/dama-dmbok-data-governance-framework)

9. When a pipeline change alters a downstream-consumed schema or
   semantics, route it through the named data owner as a change-control
   decision (not a silent deploy) — DAMA-DMBOK treats governance as
   control-plus-planning, not a one-time design artifact. **addition**
   source: [OvalEdge — DAMA-DMBOK Data Governance Framework](https://www.ovaledge.com/blog/dama-dmbok-data-governance-framework)

10. When a transform step or intermediate table exists only because an
    earlier design assumed a downstream consumer that no longer reads
    it, drop the step/table rather than keeping it "in case something
    still needs it" — an unused hop is pure risk (a place data can go
    stale or leak) with no offsetting benefit. **REMOVAL**
    source: [Adams, Converse, Hales & Klotz — People systematically overlook subtractive changes, *Nature* 592 (2021)](https://www.nature.com/articles/s41586-021-03380-y) (people default to additive fixes and under-consider removing the unneeded hop)

11. When a hybrid ETL/ELT pipeline has accreted pre-load validation
    steps that duplicate checks the warehouse-side data-quality gate
    already enforces, remove the duplicated pre-load check rather than
    keeping both — duplicated validation is an additive habit, not
    evidence of extra safety. **REMOVAL**
    source: [Adams, Converse, Hales & Klotz — People systematically overlook subtractive changes, *Nature* 592 (2021)](https://www.nature.com/articles/s41586-021-03380-y)
