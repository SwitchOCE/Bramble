#!/usr/bin/env bash
# Continue only already prepared and natively checked plans; no source/sample edits.
set -euo pipefail
source /opt/bramble/env.sh
REBASE_ROOT="$(git rev-parse --show-toplevel)"
REBASE_OUT="$REBASE_ROOT/build/sim/wave1-rebase"
test "$(cat "$REBASE_OUT/counter-check.complete")" = passed
test "$(cat "$REBASE_OUT/line-compatibility-check.complete")" = passed
rg -q '^PEAT_COUNTER_KNOWN_ANSWER_PASS' "$REBASE_OUT/counter-check.log"
rg -q '^MEASUREMENT_LINE_ARCHIVE_COMPATIBILITY_PASS' "$REBASE_OUT/line-compatibility-check.log"
python3 - <<'PY'
import json
from pathlib import Path
control=json.loads(Path('tools/sim/evidence/wave1-baseline-shipped-plan.json').read_text())
for label in ['B','C']:
 p=json.loads(Path(f'build/sim/wave1-rebase/{label}/plan.json').read_text())
 assert p['seeds']==control['seeds'] and len(p['seeds'])==320
 assert p['overrides']=={'pass3_preset':label}
 assert p['config']['card_size_caps'] and p['config']['card_rate_limits']
 assert p['source_commit'].startswith('d5b5b4f8')
PY
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
python3 tools/sim/evidence/drivers/finalize-wave1-rebase.py
