---
axis: data-quality
rule_count_floor: 10
---

# Data quality — decision rules

Condition → choice → source. Each rule is `addition` or `**REMOVAL**`.

1. When a column feeds a join key, primary key, or dedup logic, enforce
   a uniqueness check on it (e.g. GX `ExpectColumnValuesToBeUnique`)
   rather than only checking null-rate — duplicates on a join key break
   downstream fan-out even when completeness looks fine. **addition**
   source: [Great Expectations — Data quality use cases](https://docs.greatexpectations.io/docs/reference/learn/data_quality_use_cases/dq_use_cases_lp/)

2. When a column is required by a downstream consumer contract, enforce
   a completeness (not-null) check on it (e.g. GX
   `ExpectColumnValuesToNotBeNull`) with an explicit numeric threshold
   (e.g. ≥ 99%), not a bare "should usually be populated" comment.
   **addition**
   source: [OvalEdge — Data Quality Dimensions](https://www.ovaledge.com/blog/data-quality-dimensions)

3. When a field represents a real-world measured quantity (price,
   quantity, timestamp of an event), validate accuracy via a bounded-
   range or cross-source reconciliation check, not just type-checking —
   type-valid data can still be wrong. **addition**
   source: [OvalEdge — Data Quality Dimensions](https://www.ovaledge.com/blog/data-quality-dimensions)

4. When a downstream job depends on data landing by a fixed time
   (e.g. hourly dashboard refresh), enforce a freshness/timeliness check
   against the max(event/load timestamp) rather than only checking that
   the job "ran" — a job can succeed while the data it produced is
   stale. **addition**
   source: [Great Expectations — Validate data freshness](https://docs.greatexpectations.io/docs/reference/learn/data_quality_use_cases/freshness/)

5. When defining what "correct" volume looks like for a load, set a
   row-count/byte-volume threshold band (e.g. ±20% of the trailing
   7-day average) and fail the load outside that band, rather than
   accepting any non-zero row count as success — silent partial loads
   are the most common volume defect. **addition**
   source: [Datafold — 8 dimensions of data quality](https://www.datafold.com/blog/data-quality-dimensions/)

6. When a dataset crosses a team boundary (producer team ≠ consumer
   team), formalize the schema/thresholds as a data contract (explicit
   producer/consumer agreement on shape and quality, per the Data
   Contract Specification) instead of an implicit "read the producer's
   code" arrangement. **addition**
   source: [Data Contract Specification](https://github.com/datacontract/datacontract-specification), [Great Expectations — The 3 phases of data contracts](https://greatexpectations.io/blog/the-3-phases-of-data-contracts/)

7. When a business rule spans multiple columns (e.g. `end_date >=
   start_date`, `sum(line_items) == order_total`), encode it as an
   explicit multi-column/business-logic expectation, not just per-column
   checks — per-column checks alone miss cross-column defects.
   **addition**
   source: [Great Expectations — Defining data contracts to work everywhere](https://greatexpectations.io/blog/defining-data-contracts-to-work-everywhere/)

8. When a threshold check first goes live on a noisy or seasonal metric,
   start with a fixed critical threshold (e.g. 99% completeness) and
   only move to a dynamic/rolling-average baseline once you have enough
   history to trust it — don't start with a dynamic baseline on day one
   with no history to calibrate against. **addition**
   source: [Great Expectations — Your back-pocket guide to data quality](https://greatexpectations.io/blog/your-back-pocket-guide-to-data-quality/)

9. When recording a threshold check's outcome, record a per-check
   pass/fail verdict against the numeric threshold (not just an
   aggregate "quality score") so a downstream consumer or reviewer can
   see exactly which dimension failed. **addition**
   source: [Great Expectations — Data quality use cases](https://docs.greatexpectations.io/docs/reference/learn/data_quality_use_cases/dq_use_cases_lp/)

10. When a check was added defensively for a source system that has
    since been decommissioned or a column that has since been dropped
    upstream, delete the now-meaningless check rather than leaving it
    in place (a stale check either always passes vacuously or fails
    noisily — both erode trust in the checklist). **REMOVAL**
    source: [Adams, Converse, Hales & Klotz — People systematically overlook subtractive changes, *Nature* 592 (2021)](https://www.nature.com/articles/s41586-021-03380-y)

11. When two checks assert overlapping constraints on the same column
    (e.g. a not-null check and a stricter "always populated with valid
    enum" check that subsumes it), keep only the stricter check and
    remove the redundant weaker one instead of running both. **REMOVAL**
    source: [Adams, Converse, Hales & Klotz — People systematically overlook subtractive changes, *Nature* 592 (2021)](https://www.nature.com/articles/s41586-021-03380-y)

12. When a dataset's normal shape can shift in ways no one anticipated
    when authoring threshold checks (an unannounced schema change, a
    volume shift, a freshness lag with no prior rule written for it),
    run an unsupervised anomaly monitor alongside the authored
    threshold checks, not instead of them — authored checks (items
    1-9) catch the failure modes someone thought to write a rule for;
    an anomaly monitor catches the ones nobody did yet. Record its
    findings with the same per-check verdict discipline as item 9,
    not as a separate unstructured alert stream. **addition**
    source: [Monte Carlo — 61 data observability use cases](https://montecarlo.ai/blog-data-observability-use-cases/)

13. When verifying a transform step (by a human or an AI agent), treat a
    successful compile/build as necessary but not sufficient — run the
    actual query/model and inspect a sample of its real output against
    the expected shape, rather than declaring the step done once it
    parses and executes without error; a step can compile and run
    cleanly while producing the wrong rows. **addition**
    source: [AltimateAI — data-engineering-skills, 118 GitHub stars](https://github.com/AltimateAI/data-engineering-skills) (measured: dbt-model-creation accuracy improved 40%→65% on ADE-bench's 43-task suite when the verify-actual-output step was enforced), independently corroborated by [rmoff.net — Evaluating Claude's dbt skills](https://rmoff.net/2026/03/13/evaluating-claudes-dbt-skills-building-an-eval-from-scratch/) (deterministic output checks plus LLM-judge scoring catch defects compile-only validation misses; even so, no trial reached production quality unassisted — an agent is a companion, not a replacement for engineer review)
