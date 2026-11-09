#!/usr/bin/env bash
# Retry only the rejected zero-lobby attempt, with recorded archive compatibility.
set -euo pipefail
source /opt/bramble/env.sh
REBASE_ROOT="$(git rev-parse --show-toplevel)"
REBASE_OUT="$REBASE_ROOT/build/sim/wave1-rebase"
if [[ "${1:-}" == native-preflight ]]; then
  for rebase_preset in B C; do
    rebase_tree="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["runtime_tree"])' "$REBASE_OUT/$rebase_preset/plan.json")"
    timeout --kill-after=5s 300 godot --headless --path "$rebase_tree" --editor --import > "$REBASE_OUT/$rebase_preset/compatibility-import.log" 2>&1
  done
  rebase_tree="$(python3 -c 'import json; print(json.load(open("build/sim/wave1-rebase/B/plan.json"))["runtime_tree"])')"
  timeout --kill-after=5s 300 godot --headless --path "$rebase_tree" -s res://check_peat_counter.gd > "$REBASE_OUT/counter-check.log" 2>&1
  rg -q '^PEAT_COUNTER_KNOWN_ANSWER_PASS' "$REBASE_OUT/counter-check.log"
  printf 'passed\n' > "$REBASE_OUT/counter-check.complete"
  timeout --kill-after=5s 300 godot --headless --path "$rebase_tree" -s res://check_wave1_archive_lines.gd > "$REBASE_OUT/line-compatibility-check.log" 2>&1
  rg -q '^MEASUREMENT_LINE_ARCHIVE_COMPATIBILITY_PASS' "$REBASE_OUT/line-compatibility-check.log"
  printf 'passed\n' > "$REBASE_OUT/line-compatibility-check.complete"
  exit 0
fi
for rebase_preset in B C; do
  python3 tools/sim/wave1_baseline.py prepare --source-tree "$REBASE_ROOT" --commit d5b5b4f8 \
    --preset "$rebase_preset" --overrides "tools/sim/evidence/wave1-rebase-$rebase_preset-overrides.json" \
    --probe "$REBASE_OUT/rejected-unconfigured-line-policy/$rebase_preset/probe.json" \
    --output "$REBASE_OUT/$rebase_preset" --max-lobbies 320
done
python3 - <<'PY'
import hashlib,json
from pathlib import Path
r=Path('build/sim/wave1-rebase')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
control=json.loads(Path('tools/sim/evidence/wave1-baseline-shipped-plan.json').read_text())
record={'reason':'Harness operator reused native probes after verifying unchanged draw/config/content dependencies; only measurement-line compatibility changes.', 'presets':{}}
for label in ['B','C']:
 old=r/'rejected-unconfigured-line-policy'/label
 plan=json.loads((r/label/'plan.json').read_text())
 oldplan=json.loads((old/'plan.json').read_text())
 before=old/('source-'+oldplan['source_commit'][:12])
 after=Path(plan['runtime_tree'])
 assert before.resolve()!=after.resolve(), 'probe proof requires distinct actual old and new archives'
 assert plan['seeds']==control['seeds'] and len(plan['seeds'])==320
 assert plan['overrides']=={'pass3_preset':label}
 assert plan['config']['card_size_caps'] and plan['config']['card_rate_limits']
 files=sorted(str(p.relative_to(before)) for folder in ['src','content'] for p in (before/folder).rglob('*') if p.is_file() and str(p.relative_to(before))!='src/core/bots/bot_pass3.gd')
 hashes={}
 for name in files:
  assert sha(before/name)==sha(after/name), 'probe dependency changed: '+name
  hashes[name]=sha(after/name)
 assert sha(old/'probe.json')==sha(r/label/'probe.json')
 record['presets'][label]={'reused_probe_sha256':sha(old/'probe.json'),'old_runtime_tree':str(before.resolve()),'new_runtime_tree':str(after.resolve()),'unchanged_dependency_sha256':hashes}
(r/'probe-reuse.json').write_text(json.dumps(record,indent=2)+'\n')
PY
REBASE_TREE="$(python3 -c 'import json; print(json.load(open("build/sim/wave1-rebase/B/plan.json"))["runtime_tree"])')"
cp tools/sim/evidence/drivers/check_peat_counter.gd.txt "$REBASE_TREE/check_peat_counter.gd"
cp tools/sim/evidence/drivers/check_wave1_archive_lines.gd.txt "$REBASE_TREE/check_wave1_archive_lines.gd"
flock -w 1800 /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G \
  timeout --kill-after=10s 1200 bash tools/sim/evidence/drivers/wave1-rebase-corrected.sh native-preflight
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
