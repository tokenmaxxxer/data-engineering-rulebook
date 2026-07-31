---
subject: issue-1
role: data-engineering
---

# Record — 룰북 성숙화: 방법론/산출물 규범 반영 (phase 2)

## What was done

Executed item 1 of the approved proposal's plugin reflection plan
(`docs/issue-1/proposals/2026-07-31-methodology-and-artifact-norms.md`, section (d)):
extended `data-engineering/hooks/directive.sh`'s `PRODUCES` argument from the flat list
("pipeline design, data-quality check list, failure-handling plan") to name each
field's pinned sub-shape inline:

`"PRODUCES (required record fields): pipeline design (flow + ownership +
change-control note), data-quality check list (schema + thresholds + enforcement
point), failure-handling plan (failure modes + diagnostics + escalation + recovery
target)"`

Kept as one string argument, unchanged four-argument `core_role_directive` call
signature — no new argument slot added or needed.

## Why

The proposal's phase-1 survey found no mechanical way to verify documentation *shape*
(prose sub-fields, not parseable tokens), so the norm's enforcement point is the
directive text itself — read by whoever authors a future phase-2 record for this
role — plus human approver judgment at record time, not a new gate script.

## Plugin reflection plan — item-by-item disposition

1. **`directive.sh` `PRODUCES` string** — done (above).
2. **No new gate script** — confirmed no gate added. This repo already defers to
   core canon's global `record-fields-gate.sh` (landed via issue #2/#4's core-canon
   reference transition) for required-*field-presence* enforcement; this issue only
   changes what "presence" must contain, which the gate cannot parse. Recorded here
   as the explicit non-gate decision the proposal called for, so no gate was
   silently attempted.
3. **`WRITE_SCOPE: []`** — left unchanged. The phase-1 proposal norm ((a) in the
   proposal) applies to this and future phase-1 proposals this role writes; the
   phase-2 artifact norm ((b)) applies to `docs/issue-<n>/reports/data-engineering.md`
   going forward, starting with this record.
4. **No canon script copies introduced** — confirmed; only `directive.sh`'s existing
   string literal was edited, no vendoring added.

## Verification

`stub-check.sh` (referenced from the sibling `tokenmaxxxer-core` checkout, run
in-place — not copied into this repo, per the issue's canon-reference-only
constraint) against `data-engineering/`:

```
stub-check: ok — no vendored 'trailer-gate.sh' under .../data-engineering
stub-check: ok — no vendored 'record-fields-gate.sh' under .../data-engineering
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under .../data-engineering
stub-check: ok — no vendored 'parse-check.sh' under .../data-engineering
stub-check: ok — no vendored 'stub-check.sh' under .../data-engineering
stub-check: ok — .../data-engineering/hooks/directive.sh is a role-directive stub
```

All checks pass (exit 0) — the longer `PRODUCES` string still fits the accepted
single-line stub shape (shebang, source line, one single-line `core_role_directive`
call).

## Preserved unchanged

- `data-engineering/.claude-plugin/plugin.json`.
- `YOU DECIDE` / `USE_WHEN` / `WRITE_SCOPE`+`HAND-OFF` directive values.
- `data-engineering/hooks/hooks.json`'s `SessionStart` entry.
- No `record-fields-gate.sh` (or any gate) added or vendored, per item 2 above.

## Open findings

None outstanding.

## Next steps

None — this issue's phase 2 is complete. Any future phase-1 proposal or phase-2
record this role produces should follow the norms fixed in
`docs/issue-1/proposals/2026-07-31-methodology-and-artifact-norms.md` sections (a)
and (b).

loop_state: landed
