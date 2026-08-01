#!/usr/bin/env bash
# data-quality-gate: thin bash entrypoint. Installs the canonical
# fail-closed EXIT trap, checks the kill switch before Python even starts,
# and execs the Python payload (data-quality-gate.py) which holds the
# actual scope/content/semantic checks. Sources core/hooks/lib/gate-lib.sh
# by reference, never copies it (docs/handbooks/canon-scripts.md).
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${DATA_ENGINEERING_DATA_QUALITY_GATE_OFF:-}" || { trap - EXIT; exit 0; }
exec python3 "$(dirname "${BASH_SOURCE[0]}")/data-quality-gate.py"
