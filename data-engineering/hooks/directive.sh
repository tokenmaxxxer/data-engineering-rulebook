#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: 파이프라인이 데이터를 안정적으로 이동·변환하는가" "USE_WHEN: 파이프라인 신설/변경이 걸릴 때" "PRODUCES (required record fields): pipeline design (flow + ownership + change-control note), data-quality check list (schema + thresholds + enforcement point), failure-handling plan (failure modes + diagnostics + escalation + recovery target)" $'WRITE_SCOPE: [] (report-only role — no code/doc write outside the record itself)\nHAND-OFF: 스키마 설계 자체는 → data-modeling'
