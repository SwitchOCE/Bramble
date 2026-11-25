#!/usr/bin/env bash
# The card report for one played ghost match: steps 1 and 2 of the card-power ladder
# (docs/workstreams/card-power/definitions.md). Step 1 reads the games as played (pick rate,
# bought against passed, stat growth). Step 2 refights the recorded fights with one thing changed
# (text off, stat worth, keyword off, Overrun swings). It ends with one row per card and the cards worth a look.
# A match without records gets step 1's shop readings only. Run it before records are deleted.
#
# usage: card_report.sh <match dir> [--out <dir>] [--left-out <left_out.csv>] [--threads 4]
#                       [--keywords badger_overrun,cleave,badger_fury] [--league <binary>]
# Tables land in <match dir>/card-report unless --out is given.
set -euo pipefail
usage() { sed -n '8,10p' "${BASH_SOURCE[0]}" | cut -c3- >&2; exit 2; }
[ $# -ge 1 ] || usage
match=$(cd "$1" && pwd); shift
out=$match/card-report; left=; threads=4; keywords=badger_overrun,cleave,badger_fury; league=
while [ $# -gt 0 ]; do
  [ $# -ge 2 ] || usage
  case $1 in
    --out) out=$2 ;; --left-out) left=$2 ;; --threads) threads=$2 ;;
    --keywords) keywords=$2 ;; --league) league=$2 ;; *) usage ;;
  esac
  shift 2
done
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
A=$here/analysis
mkdir -p "$out"
step() { echo "== $*"; }

step "pick rate and bought against passed"
python3 "$A/bought_passed.py" "$match" --out "$out/bought_passed.csv"

if compgen -G "$match/records/game-*.jsonl" > /dev/null; then
  if [ -z "$league" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
    (cd "$here" && cargo build --offline --locked --release -p league 2>&1 | tail -1)
    league=${CARGO_TARGET_DIR:-$here/target}/release/league
  fi
  step "stat growth"
  python3 "$A/stat_growth.py" "$match" --out "$out/stat_growth.csv"
  step "text off and stat worth (every card)"
  "$league" refight --match "$match" --out "$out/refight" --stat-worth --threads "$threads"
  # Keywords are read in thirds by the enemy's Health, so they need more fights than a card does.
  step "keyword off and Overrun swings"
  "$league" refight --match "$match" --out "$out/refight-keywords" --keyword-off "$keywords" \
    --overrun-swings --cap 3000 --threads "$threads"
  mv "$out/refight-keywords/keyword_off.jsonl" "$out/refight-keywords/overrun_swings.jsonl" "$out/refight/"
  python3 "$A/fight_text.py" "$out/refight" --out "$out"
  rm -r "$out/refight" "$out/refight-keywords"
else
  echo "no records in $match: the fight tests and stat growth are skipped"
  # Tables left by an earlier report in the same folder would be read as this match's.
  rm -f "$out/text_cards.csv" "$out/stat_growth.csv" "$out/keywords.csv" "$out/overrun_swings.csv"
fi

step "one row per card"
python3 "$A/card_summary.py" "$match" "$out" ${left:+--left-out "$left"}
