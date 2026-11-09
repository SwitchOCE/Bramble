#!/usr/bin/env bash
# Exact authored B/C at d5b5b4f8; no source worktree is modified.
set -euo pipefail
source /opt/bramble/env.sh
REBASE_ROOT="$(git rev-parse --show-toplevel)"
REBASE_OUT="$REBASE_ROOT/build/sim/wave1-rebase"
for rebase_preset in B C; do
  python3 tools/sim/wave1_baseline.py prepare --source-tree "$REBASE_ROOT" --commit d5b5b4f8 \
    --preset "$rebase_preset" --overrides "tools/sim/evidence/wave1-rebase-$rebase_preset-overrides.json" \
    --output "$REBASE_OUT/$rebase_preset" --max-lobbies 320
 done
python3 - <<'PY'
import json
from pathlib import Path
r=Path('build/sim/wave1-rebase')
old=json.loads(Path('tools/sim/evidence/wave1-baseline-shipped-plan.json').read_text())
for name in ['B','C']:
 p=json.loads((r/name/'plan.json').read_text())
 assert p['seeds']==old['seeds'], 'eligible sample changed'
 assert p['config']['card_size_caps'] and p['config']['card_rate_limits']
 assert p['config']['pass3_content'] and p['config']['pass3_loop_guards']
 assert p['config']['tribes_per_lobby']==5
PY
REBASE_TREE="$(python3 -c 'import json; print(json.load(open("build/sim/wave1-rebase/B/plan.json"))["runtime_tree"])')"
cp tools/sim/evidence/drivers/check_peat_counter.gd.txt "$REBASE_TREE/check_peat_counter.gd"
flock -w 1800 /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G \
  timeout --kill-after=5s 300 godot --headless --path "$REBASE_TREE" -s res://check_peat_counter.gd \
  > "$REBASE_OUT/counter-check.log" 2>&1
rg -q '^PEAT_COUNTER_KNOWN_ANSWER_PASS' "$REBASE_OUT/counter-check.log"
# The target-only checker is outside the frozen source manifest and is not runtime content.
printf 'passed\n' > "$REBASE_OUT/counter-check.complete"
for rebase_preset in B C; do
  python3 tools/sim/wave1_baseline.py run --plan "$REBASE_OUT/$rebase_preset/plan.json"
  python3 tools/sim/wave1_baseline.py report --plan "$REBASE_OUT/$rebase_preset/plan.json" \
    --out "tools/sim/evidence/wave1-rebase-$rebase_preset.json" \
    --markdown "docs/ideation/evidence/wave1-rebase-$rebase_preset.md"
done
python3 tools/sim/wave1_rebase_compare.py \
  --b tools/sim/evidence/wave1-rebase-B.json --c tools/sim/evidence/wave1-rebase-C.json \
  --out tools/sim/evidence/wave1-rebase-comparison.json \
  --markdown docs/ideation/evidence/wave1-rebase.md
printf 'complete\n' > "$REBASE_OUT/job.complete"
