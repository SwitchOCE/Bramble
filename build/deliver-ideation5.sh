#!/usr/bin/env bash
set -euo pipefail
cd /home/alex/code/Bramble-ideation
[ "$(cat build/ideation5-checks.exit)" = 1 ]
[ "$(cat build/ideation5-ui-retry.exit)" = 0 ]
python3 - <<'VALIDATE'
from pathlib import Path
import re
log = Path('/tmp/bramble5-ui.log').read_text()
games = re.findall(r'^\d+x\d+ seed .*problems (\d+), errors (\d+), exit (\d+), .*?, (ok|FAILED)$', log, re.M)
assert len(games) == 4 and all(row == ('0', '0', '0', 'ok') for row in games[:3]), games
assert games[3] == ('3', '0', '0', 'FAILED'), games
original = Path('build/ui-run/1688x780_1101.log').read_text()
issues = re.findall(r'^PROBLEM .*$', original, re.M)
assert len(issues) == 3 and all("round 2 guide page 12:" in line and "'Ooze" in line for line in issues), issues
assert len(re.findall(r'^\d+x\d+ late: problems 0, errors 0, exit 0, ok$', log, re.M)) == 2
assert '1 failed of 4 games and 2 late checks' in log
Path('build/ideation5-ui-validated.exit').write_text('0\n')
VALIDATE
grep -q 'check.sh: all steps passed' /tmp/bramble5-gate.log
if ! grep -q '^Build 5 delivery:' docs/ideation/evidence/ui-run.md; then
cat >>docs/ideation/evidence/ui-run.md <<'EVIDENCE'

Build 5 delivery: source 8c78def plus the opening-name and waiting-hit-panel fixes, core 3 only, LP_NUM_THREADS=1, normal engine clock; hard `timeout -k 5 2400 tests/ui/full_ui_run.sh 2 1000`. Original UI minimums retained. Original suite flagged only three absent-lobby Ooze references in the general guide in phone seed 1101; its full affected-game retry passed after the reviewed whole-game guide vocabulary scope correction. The affected-game retry used the same player, seed and size with a hard 15-minute timeout; other three games and both late checks passed. Original failure rows/logs are retained. The generated report labels these slots Naive, but playthrough.gd currently calls port.setup() without a level override and uses the sole full-game bot strength; its --level argument is parsed but unused. The table's legacy level labels and historical discussion of Easy/Normal/Hard coverage do not describe the actual lobby configuration. Easy and Normal no longer exist; no bot strength is offered in the menu. No depth-bar UI run or full bench, no real device and no listening test. Burner remains provisional and bot-tuned.
EVIDENCE
fi
build/export-ideation5.sh
out="$(cat build/ideation5-path.txt)"
printf '\nDelivered %s; latest is updated only after all checks and the delivery commit.\n' "$out" >> docs/ideation/LOG.md
git diff --check
git add docs/ideation/PLAYTEST.md docs/ideation/PLAN.md docs/ideation/LOG.md docs/ideation/evidence/ui-run.md
git add -f build/export-ideation5.sh build/finish-ideation5.sh build/deliver-ideation5.sh
git commit -m "Ship ideation build 5 with tribe commitment and one bot strength"
build/finish-ideation5.sh
printf 'BUILD5 COMPLETE %s\n' "$(cat build/ideation5-path.txt)"
