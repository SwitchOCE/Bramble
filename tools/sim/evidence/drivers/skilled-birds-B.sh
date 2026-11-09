#!/usr/bin/env bash
# Current shipped B Birds (2x/2x), source f9;32 fixed seeds per arm.
set -euo pipefail
source /opt/bramble/env.sh
SKILLED_ROOT="$(git rev-parse --show-toplevel)"
SKILLED_OUT="$SKILLED_ROOT/build/sim/skilled-birds-B"
SKILLED_TREE="$(python3 -c 'import json; print(json.load(open("build/sim/skilled-birds-B/plan.json"))["runtime_tree"])')"
if [[ "${1:-}" == preflight ]]; then
  timeout --kill-after=10s 900 ./scripts/check.sh > "$SKILLED_OUT/gate.log" 2>&1
  printf '0\n' > "$SKILLED_OUT/gate.exit"
  timeout --kill-after=5s 300 godot --headless --path "$SKILLED_TREE" --editor --import > "$SKILLED_OUT/import.log" 2>&1
  timeout --kill-after=5s 300 godot --headless --path "$SKILLED_TREE" -s res://addons/gut/gut_cmdln.gd \
    -gconfig="$SKILLED_OUT/gut-focused.json" -gtest=res://tests/core/test_skilled_birds.gd -gexit > "$SKILLED_OUT/focused.log" 2>&1
  rg -q 'gut_strict: ok' "$SKILLED_OUT/focused.log"
  printf 'passed\n' > "$SKILLED_OUT/preflight.complete"
  exit 0
fi
python3 - <<'PY'
import hashlib,json
from pathlib import Path
b=Path('build/sim/skilled-birds-B');p=json.loads((b/'plan.json').read_text())
for name,expected in p['helpers'].items():assert hashlib.sha256((Path(p['runtime_tree'])/'tools/sim'/name).read_bytes()).hexdigest()==expected
assert hashlib.sha256(Path('tools/sim/skilled_birds.py').read_bytes()).hexdigest()==p['driver_sha256']
focused={'dirs':[],'include_subdirs':False,'should_exit':True,'log_level':1,'hide_orphans':False,'post_run_script':'res://tools/checks/gut_strict_hook.gd'}
(b/'gut-focused.json').write_text(json.dumps(focused)+'\n')
# A genuine short all-line simulation verifies the driver-level banned-card capture.
(b/'ban-smoke-plan.json').write_text(json.dumps({'seeds':p['seeds'][:1],'overrides':{'max_rounds':4},'banned_cards':{'line_birds_homecoming':['mr_redbreast']}})+'\n')
PY
flock -w 1800 /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G \
  timeout --kill-after=10s 1700 bash tools/sim/evidence/drivers/skilled-birds-B.sh preflight
flock -w 1800 /tmp/bramble-harness-godot.lock systemd-run --user --scope -q -p MemoryMax=3G \
  timeout --kill-after=5s 300 godot --headless --path "$SKILLED_ROOT" -s res://tools/sim/wave1_baseline.gd -- \
  run "$SKILLED_OUT/ban-smoke-plan.json" "$SKILLED_OUT/ban-smoke.jsonl" > "$SKILLED_OUT/ban-smoke.log" 2>&1
python3 - <<'PY'
import json,sys
from pathlib import Path
sys.path.insert(0,'tools/sim');from wave1_baseline import parse_chunk
b=Path('build/sim/skilled-birds-B');p=json.loads((b/'plan.json').read_text())
parse_chunk(b/'ban-smoke.jsonl',p['seeds'][:1],p['config'],with_diagnostics=True,banned_cards={'line_birds_homecoming':['mr_redbreast']})
(b/'ban-smoke.complete').write_text('passed\n')
PY
for skilled_arm in control aggressive; do
  flock -w 1800 /tmp/bramble-harness-godot.lock systemd-run --user --scope -q -p MemoryMax=3G \
    timeout --kill-after=10s 600 godot --headless --path "$SKILLED_TREE" -s res://tools/sim/skilled_birds.gd -- \
    run "$SKILLED_OUT/$skilled_arm-plan.json" "$SKILLED_OUT/$skilled_arm.jsonl" > "$SKILLED_OUT/$skilled_arm.log" 2>&1
  printf 'complete\n' > "$SKILLED_OUT/$skilled_arm.complete"
done
python3 tools/sim/skilled_birds.py report --plan "$SKILLED_OUT/plan.json" \
  --control "$SKILLED_OUT/control.jsonl" --aggressive "$SKILLED_OUT/aggressive.jsonl" --output "$SKILLED_OUT/report.json"
printf 'complete\n' > "$SKILLED_OUT/job.complete"
