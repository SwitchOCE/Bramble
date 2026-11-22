#!/usr/bin/env bash
# Run a stopping test's plan, one match at a time under the cores lock, skipping matches already
# done. Each finished match is pruned to its verdict and summaries.
#
# usage: stop_test.sh COLOUR BASE_TAG TEST_DIR
#   TEST_DIR holds plan.tsv (label <tab> games <tab> knob lines) and gets one folder per match
#   and results.txt.
# env: BASE_KNOBS (the test version's knob lines), FIELD (the reference field), as stop_match.sh
set -euo pipefail
[[ $# -eq 3 ]] || { sed -n 2,8p "$0" >&2; exit 2; }
colour=$1 base=$2 dir=$3
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
lock=/data/third-run/cores.lock
: "${FIELD:?set FIELD}"
while IFS=$'\t' read -r label games knobs; do
  [[ -z $label || $label == \#* ]] && continue
  out=$dir/$label
  [[ -s $out/verdict.txt ]] && continue
  rm -rf "${out:?}"
  NEW_KNOBS=$knobs flock "$lock" "$here/stop_match.sh" "$colour" "$base" "$label" "$games" "$out" < /dev/null \
    > "$dir/$label.log" 2>&1 || { echo "$label: FAILED, see $dir/$label.log" | tee -a "$dir/results.txt"; continue; }
  cat "$out/verdict.txt" >> "$dir/results.txt"
  find "$out" -mindepth 1 -maxdepth 1 ! -name verdict.txt ! -name analysis.json ! -name summary.json \
    ! -name timing.json ! -name 'knobs-*.txt' ! -name seeds.txt ! -name check.log -exec rm -rf {} +
  rm -f "$dir/$label.log"
done < "$dir/plan.tsv"
echo "stop_test: plan done" >> "$dir/results.txt"
