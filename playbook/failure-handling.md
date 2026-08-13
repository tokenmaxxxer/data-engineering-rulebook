---
axis: failure-handling
rule_count_floor: 10
---

# Failure handling — decision rules

Condition → choice → source. Each rule is `addition` or `**REMOVAL**`.

1. When a failure is transient (network timeout, HTTP 429/503), retry
   with exponential backoff (e.g. 2^attempt seconds) rather than either
   failing immediately or retrying at a fixed interval. **addition**
   source: [Confluent — Kafka Dead Letter Queue guide](https://www.confluent.io/learn/kafka-dead-letter-queue/), [OneUptime — DLQ pattern in Dataflow pipelines](https://oneuptime.com/blog/post/2026-02-17-how-to-implement-a-dead-letter-queue-pattern-in-dataflow-pipelines/view)

2. When a failure is permanent (schema violation, malformed record,
   business-rule violation), route the record straight to a dead-letter
   queue instead of retrying it — retrying a permanent failure just
   burns time and delays the rest of the batch. **addition**
   source: [OneUptime — DLQ pattern in Dataflow pipelines](https://oneuptime.com/blog/post/2026-02-17-how-to-implement-a-dead-letter-queue-pattern-in-dataflow-pipelines/view)

3. When an error's transient-vs-permanent classification is ambiguous,
   retry once or twice with a short backoff and, if it still fails,
   treat it as permanent and route to the DLQ — don't retry indefinitely
   on an unclassified error. **addition**
   source: [FlowFuse — Stop silent pipeline failures with DLQ and retries](https://flowfuse.com/blog/2026/03/how-to-implement-dlq-and-retries/)

4. When a record fails processing, write it to the DLQ and continue
   processing the rest of the batch, rather than stopping the whole
   pipeline on one bad record — one malformed record should not block
   the other 99.9%. **addition**
   source: [Medium — Dead Letter Queues and Retry Queues](https://medium.com/@vinay.georgiatech/dead-letter-queues-and-retry-queues-the-safety-net-for-distributed-systems-b961c718e6a0)

5. When DLQ volume for a source exceeds ~5% of that source's main
   traffic volume, alert on it as a systemic-issue signal, not just log
   it — a rising DLQ rate usually means an upstream contract broke, not
   that individual records are randomly bad. **addition**
   source: [FlowFuse — Stop silent pipeline failures with DLQ and retries](https://flowfuse.com/blog/2026/03/how-to-implement-dlq-and-retries/)

6. When a DLQ message has sat unprocessed past its retention window
   (e.g. 24 hours), alert on it separately from the volume-spike alert —
   an aging DLQ message means it will be lost, not just delayed.
   **addition**
   source: [FlowFuse — Stop silent pipeline failures with DLQ and retries](https://flowfuse.com/blog/2026/03/how-to-implement-dlq-and-retries/)

7. When diagnosing a pipeline failure, check reprocessing/replay success
   rate after a fix (e.g. alert if replay success < 80%), not just
   whether the DLQ drained — a low replay success rate means the fix
   didn't actually address the root cause. **addition**
   source: [FlowFuse — Stop silent pipeline failures with DLQ and retries](https://flowfuse.com/blog/2026/03/how-to-implement-dlq-and-retries/)

8. When setting a recovery-time target for a failure mode, scale it to
   business impact: business-critical/aggregation-sensitive pipelines
   (billing, fraud detection, inventory) get a tight RTO (minutes-to-
   low-single-digit-hours) with paged escalation; non-critical batch
   pipelines get a looser RTO (next business day) with ticket-only
   escalation — don't apply one blanket RTO to every pipeline.
   **addition**
   source: [Medium — Common failure points in data pipelines](https://medium.com/@krthiak/common-failure-points-in-data-pipelines-and-how-to-handle-them-9fd6121b735c)

9. When recovering from a bad load, roll back by re-running the
   idempotent load for the affected partition/window (per the
   pipeline-design axis's overwrite-partition or upsert pattern) rather
   than hand-patching the destination table — hand-patches drift from
   what the pipeline would actually produce on rerun. **addition**
   source: [Airbyte — Idempotency in Data Pipelines](https://airbyte.com/data-engineering-resources/idempotency-in-data-pipelines)

10. When cascading failures spike DLQ write volume far above normal
    (e.g. 500x), route that overflow to dedicated DLQ partitions/
    consumer groups instead of overloading the shared DLQ path — a
    shared under-provisioned DLQ becomes the next outage. **addition**
    source: [FlowFuse — Stop silent pipeline failures with DLQ and retries](https://flowfuse.com/blog/2026/03/how-to-implement-dlq-and-retries/)

11. When an escalation runbook step exists for a failure mode that a
    later idempotency/DLQ fix made structurally impossible (e.g. a
    manual "re-run by hand" step for a failure class now auto-recovered
    by replay), delete that runbook step instead of leaving it as dead
    instructions an on-call engineer might still follow. **REMOVAL**
    source: [Adams, Converse, Hales & Klotz — People systematically overlook subtractive changes, *Nature* 592 (2021)](https://www.nature.com/articles/s41586-021-03380-y)

12. When a retry policy has accumulated more retry tiers than the error
    taxonomy actually distinguishes (e.g. 3 separate retry configs for
    what is really one transient-error class), collapse them to one
    policy per real error class rather than keeping the extra tiers
    "for safety." **REMOVAL**
    source: [Adams, Converse, Hales & Klotz — People systematically overlook subtractive changes, *Nature* 592 (2021)](https://www.nature.com/articles/s41586-021-03380-y)
