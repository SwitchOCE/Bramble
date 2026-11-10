#!/usr/bin/env bash
# Prints the check.sh lines that explain a failed gate run, from its log on stdin: FAIL and failed:
# lines, the tests step's own failure messages, and GUT's Run Summary (each failing script and
# test, then the totals). Reads `gh run view <id> --log-failed` (job<TAB>step<TAB>time line, and
# then prefixes each line with its job) or a plain job log (time line).
#   gh run view <id> --log-failed | scripts/gate_failures.sh
set -uo pipefail

sed $'s/\e\\[[0-9;]*m//g; s/\r$//' | awk -F'\t' '
  {
    line = $NF
    sub(/^\xef\xbb\xbf/, "", line)
    sub(/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z ?/, "", line)
    job = (NF >= 3) ? "[" $1 "] " : ""
  }
  line ~ /= Run Summary/ { summary = 1; next }
  summary && line ~ /^(res:\/\/|- |[ \t]+\[(Failed|Pending|Risky)\]|Totals|Scripts |Tests |Passing Tests|Failing Tests|Risky|Pending)/ {
    print job line
  }
  summary && line ~ /^Time / { print job line; summary = 0; next }
  line ~ /^(FAIL |failed: |GUT exited|GUT logged|shard .* ran |no tests ran|test run logged|risky\/pending hook|gut_strict: )/ {
    print job line
  }
'
