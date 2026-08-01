#!/usr/bin/env bash
# hooks.json matcher / code coverage parity for the Bash tool (issue #16
# requirement 2, defect: Bash writes previously bypassed all three gates
# entirely). Each gate now matches Bash and denies when a heredoc/redirect
# write-target token (via gate_lib.gate_bash_write_targets) falls in its own
# in-scope PRODUCES path — content can't be deterministically reconstructed
# from an arbitrary shell command, so any in-scope target denies
# unconditionally. Sourced by run-gate-tests.sh, one case per gate plus one
# shared out-of-scope pass-through case.

assert_gate_tool "pipeline-design-gate.sh" 2 "Bash" \
  '{"command":"cat > docs/issue-10/proposals/data-engineering-thing.md <<EOF\nPipeline design: source -> transform -> sink.\nEOF"}'

assert_gate_tool "data-quality-gate.sh" 2 "Bash" \
  '{"command":"echo x >> docs/issue-10/reports/data-engineering.md"}'

assert_gate_tool "failure-handling-gate.sh" 2 "Bash" \
  '{"command":"cat > docs/issue-10/proposals/data-engineering-thing.md <<EOF\nFailure-handling plan: ...\nEOF"}'

# Out-of-scope Bash write (not a PRODUCES proposal/record path) still passes.
assert_gate_tool "pipeline-design-gate.sh" 0 "Bash" \
  '{"command":"echo hi > /tmp/unrelated-file.txt"}'
