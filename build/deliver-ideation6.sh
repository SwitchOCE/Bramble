#!/usr/bin/env bash
set -euo pipefail
cd /home/alex/code/Bramble-ideation
[ "$(cat build/ideation6-checks.exit)" = 0 ]
python3 - <<'VALIDATE'
from pathlib import Path
import re
log = Path('/tmp/bramble6-ui.log').read_text()
games = re.findall(r'^\d+x\d+ seed .*problems (\d+), errors (\d+), exit (\d+), .*?, (ok|FAILED)$', log, re.M)
assert len(games) == 4 and all(row == ('0', '0', '0', 'ok') for row in games), games
assert len(re.findall(r'^\d+x\d+ late: problems 0, errors 0, exit 0, ok$', log, re.M)) == 2
assert '0 failed of 4 games and 2 late checks' in log
Path('build/ideation6-ui-validated.exit').write_text('0\n')
VALIDATE
grep -q 'check.sh: all steps passed' /tmp/bramble6-gate.log
cat >>docs/ideation/evidence/ui-run.md <<'EVIDENCE'

Build 6 delivery: c8693ae, core 2 only, LP_NUM_THREADS=1, normal engine clock; hard `timeout -k 5 2400 tests/ui/full_ui_run.sh 2 1000`. All four games and both forced late checks passed with original UI minimums retained. The report's legacy Naive slot labels are not the actual lobby configuration: playthrough.gd uses the game's sole bot strength, unchanged from build 5. No depth-bar UI run, full bench, real device or listening test. Burner remains provisional and bot-tuned.
EVIDENCE
build/export-ideation6.sh
out="$(cat build/ideation6-path.txt)"
printf '\nDelivered %s; latest is updated only after all checks and the delivery commit.\n' "$out" >> docs/ideation/LOG.md
git diff --check
git add docs/ideation/PLAYTEST.md docs/ideation/PLAN.md docs/ideation/LOG.md docs/ideation/evidence/ui-run.md
git add -f build/export-ideation6.sh build/finish-ideation6.sh build/deliver-ideation6.sh build/run-ideation6-checks.sh
git commit -m "Ship ideation build 6 with Last Four, Last Stand and Last Blow"
build/finish-ideation6.sh
printf 'BUILD6 COMPLETE %s\n' "$(cat build/ideation6-path.txt)"
