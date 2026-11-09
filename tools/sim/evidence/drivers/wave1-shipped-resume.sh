#!/usr/bin/env bash
# User-approved lock-only continuation. Frozen seeds/dials and accepted chunks stay unchanged.
set -euo pipefail
source /opt/bramble/env.sh
BASELINE_OUTPUT="$(git rev-parse --show-toplevel)/build/sim/wave1-shipped-baseline"
for baseline_preset in shipped checkpoint; do
  python3 tools/sim/wave1_baseline.py run --plan "$BASELINE_OUTPUT/$baseline_preset/plan.json"
  python3 tools/sim/wave1_baseline.py report --plan "$BASELINE_OUTPUT/$baseline_preset/plan.json" \
    --out "tools/sim/evidence/wave1-baseline-$baseline_preset.json" \
    --markdown "docs/ideation/evidence/wave1-baseline-$baseline_preset.md"
done
python3 tools/sim/wave1_baseline_compare.py
printf 'complete\n' > "$BASELINE_OUTPUT/comparison.complete"
printf 'complete\n' > "$BASELINE_OUTPUT/job.complete"
