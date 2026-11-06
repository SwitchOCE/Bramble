#!/usr/bin/env bash
# Whole games through the real UI at PC and phone sizes, one Godot process a game, so a crash costs
# one game and shows as one. Every game passes the layout checks at every turn
# (tests/ui/layout_check.gd). tests/ui/shots/playthrough.gd's header lists what is clicked for real
# and what isn't, and each press's effect is checked too. Writes docs/ideation/evidence/ui-run.md.
#   tests/ui/full_ui_run.sh [games per size, default 10] [first seed, default 1000]
# The two sizes play different seeds. After the games, one short --late run a size: tier 6 and a
# full board and hand, forced through the dev panel. Exit 0 only with every run finished, no problem
# anywhere, and (at 10 games a size) the depth bar met: at least 10 of the 20 games reach turn 12, 3
# reach turn 15, one is won, 3 ghost fights happen, and tiers 5 and 6 are reached in play.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 2
GODOT="${GODOT:-godot}"
GAMES="${1:-10}"
FIRST_SEED="${2:-1000}"
GAME_TIMEOUT="${GAME_TIMEOUT:-900}"
# Mesa llvmpipe starts a render thread per core; the machine is shared (CLAUDE.md).
export LP_NUM_THREADS="${LP_NUM_THREADS:-2}"
OUT=build/ui-run
REPORT=docs/ideation/evidence/ui-run.md
# shellcheck source=scripts/godot_log.sh
. scripts/godot_log.sh
godot_log_init "$OUT"
# Slot by slot: the lobby, and how the scripted player plays. The report says why. Trials: Naive
# skilled wins by turn 14, cap3 and cap4 reach 15-18 or are out by turn 9, and Easy and up end the
# player by turn 9. A seed and slot repeat exactly, so a different first seed may miss the bar.
SLOTS=(
  "naive skilled" "naive cap3" "easy skilled" "naive cap4" "normal skilled"
  "naive skilled" "naive cap4" "hard skilled" "naive cap3" "naive random"
)
mkdir -p "$OUT"
rm -f "$OUT"/*.log
: >build/.gdignore

play() { # size log args...
  local size="$1" log="$2"
  shift 2
  timeout "$GAME_TIMEOUT" xvfb-run -a -s "-screen 0 2560x1440x24" "$GODOT" --rendering-driver opengl3 \
    --audio-driver Dummy -s res://tests/ui/shots/playthrough.gd -- "$size" "$@" >"$log" 2>&1
}

# Quitting a script leaves resources and objects held at exit; that's the tool, not the game.
log_errors() {
  godot_log_problems "$1" | grep -vcE 'resources still in use at exit|instances were leaked at exit'
}

smallest_in() { # size
  cat "$OUT/$1"_*.log | sed -n 's/.*smallest text \([0-9]*\).*/\1/p' | sort -n | head -n 1
}

rows=""
failed=0
played=0
at_12=0
at_15=0
wins=0
ghosts=0
top5=0
top6=0
first_seed_for=$FIRST_SEED
for size in 1920x1080 1688x780; do
  for ((i = 0; i < GAMES; i++)); do
    game_seed=$((first_seed_for + i))
    read -r level style <<<"${SLOTS[$((i % ${#SLOTS[@]}))]}"
    log="$OUT/${size}_${game_seed}.log"
    start=$SECONDS
    flags=(--level "$level")
    case "$style" in
      skilled) flags+=(--skilled) ;;
      cap*) flags+=(--skilled --cap "${style#cap}") ;;
    esac
    play "$size" "$log" "${flags[@]}" "$game_seed"
    code=$?
    seconds=$((SECONDS - start))
    game_line=$(grep -m1 '^GAME seed' "$log" || true)
    finish=$(grep -c '^PLAYTHROUGH' "$log")
    place=$(echo "$game_line" | sed -n 's/.*place \([0-9]*\) after.*/\1/p')
    turns=$(echo "$game_line" | sed -n 's/.*after \([0-9]*\) turns.*/\1/p')
    fights=$(echo "$game_line" | sed -n 's/.*ghosts \([0-9]*\),.*/\1/p')
    tier=$(echo "$game_line" | sed -n 's/.*top tier \([0-9]*\),.*/\1/p')
    problems=$(grep -c '^PROBLEM' "$log")
    errors=$(log_errors "$log")
    verdict=ok
    if [ "$code" -ne 0 ] || [ -z "$game_line" ] || [ "$finish" -eq 0 ] || [ "$problems" -gt 0 ] || [ "$errors" -gt 0 ]; then
      verdict=FAILED
      failed=$((failed + 1))
    fi
    played=$((played + 1))
    [ "${turns:-0}" -ge 12 ] && at_12=$((at_12 + 1))
    [ "${turns:-0}" -ge 15 ] && at_15=$((at_15 + 1))
    [ "${place:-0}" = 1 ] && wins=$((wins + 1))
    ghosts=$((ghosts + ${fights:-0}))
    [ "${tier:-0}" -ge 5 ] && top5=$((top5 + 1))
    [ "${tier:-0}" -ge 6 ] && top6=$((top6 + 1))
    rows+="| $size | $game_seed | $level | $style | ${place:-none} | ${turns:-none} | ${fights:-none} | ${tier:-none} | $problems | $errors | $code | $seconds | $verdict |"$'\n'
    echo "$size seed $game_seed $level $style: place ${place:-none}, turns ${turns:-none}, ghosts ${fights:-none}, tier ${tier:-none}, problems $problems, errors $errors, exit $code, ${seconds}s, $verdict"
  done
  first_seed_for=$((first_seed_for + 100))
done
late_rows=""
for size in 1920x1080 1688x780; do
  log="$OUT/${size}_late.log"
  play "$size" "$log" --late "$FIRST_SEED"
  code=$?
  problems=$(grep -c '^PROBLEM' "$log")
  errors=$(log_errors "$log")
  finish=$(grep -c '^LATE seed .*stopped' "$log")
  verdict=ok
  if [ "$code" -ne 0 ] || [ "$finish" -eq 0 ] || [ "$problems" -gt 0 ] || [ "$errors" -gt 0 ]; then
    verdict=FAILED
    failed=$((failed + 1))
  fi
  late_rows+="| $size | $FIRST_SEED | $problems | $errors | $code | $verdict |"$'\n'
  echo "$size late: problems $problems, errors $errors, exit $code, $verdict"
done
bar=met
if [ "$GAMES" -ge 10 ]; then
  { [ "$at_12" -ge 10 ] && [ "$at_15" -ge 3 ] && [ "$wins" -ge 1 ] && [ "$ghosts" -ge 3 ] && [ "$top5" -ge 2 ] && [ "$top6" -ge 2 ]; } || bar="NOT MET"
else
  bar="not judged: under 10 games a size"
fi
{
  echo "# Scripted full UI run"
  echo
  echo "Made by \`tests/ui/full_ui_run.sh $GAMES $FIRST_SEED\` on $(git rev-parse --short HEAD) ($(git rev-parse --abbrev-ref HEAD)$(git diff --quiet -- src tests || echo ', with uncommitted changes')), $(date -u +%Y-%m-%d)."
  echo
  echo "**$failed failed out of $played games and 2 late-game checks. Depth bar: $bar.**"
  echo
  echo "| Depth | Needed | Got |"
  echo "|---|---|---|"
  echo "| Games reaching turn 12 | 10 | $at_12 |"
  echo "| Games reaching turn 15 | 3 | $at_15 |"
  echo "| Games won | 1 | $wins |"
  echo "| Ghost fights | 3 | $ghosts |"
  echo "| Games reaching tier 5 in play | 2 | $top5 |"
  echo "| Games reaching tier 6 in play | 2 | $top6 |"
  echo
  echo "Smallest text on screen: phone size $(smallest_in 1688x780) canvas units (the minimum is 31); desktop size $(smallest_in 1920x1080), where tile rules and lobby names may go down to 22."
  echo
  echo "Clicked for real, with the effect of each press checked: New game, a difficulty leaf, the recruit screen's buttons and tiles, Scout, Who?, Close, the pause menu, Settings and its Back, the guide's pages, the speed token, Watch again, Skip, Continue and Main menu. Not clicked: drags and drops, which go through the screen's own drop handlers; the dev panel, used only by the late checks; Leave game and Quit. The difficulty leaf's signal is caught so a game uses this run's seed and lobby, so the first-game guide and random seeds aren't run. A Naive lobby starts from the Easy leaf, since the menu has no Naive. To test the test, Scout, Who?, Continue and Main menu were unhooked by hand once (hard lobby, seed 1003): the run reported each."
  echo
  echo "Each turn also opens Scout, taps their unit, a small shop tile and sometimes buys from it, and checks the layout before and after its actions and with a card selected. It watches each fight at 4x. Once a game it visits every guide page, settings and pause, and replays one fight. Words on screen are checked for bot numbers, raw ids and tribes not in the lobby."
  echo
  echo "How the games are set up: \`skilled\` climbs on a schedule, buys the biggest units and sells the weakest; \`cap3\` and \`cap4\` do the same with at most that many units, which makes longer games; \`random\` buys at random. Most slots are Naive lobbies because this is the only level the scripted player outlasts: in trials it was out by turn 9 at Easy, Normal and Hard even when skilled, so those three levels are covered but shallow. That's a limit of the scripted player, not a measure of the bots."
  echo
  echo "What it isn't: a real phone or a real finger. Agents can only measure layouts at phone size. The UI sees mouse input, which Godot also uses for touch."
  echo
  echo "| Size | Seed | Bots | Player | Place | Turns | Ghost fights | Top tier | Problems | Errors | Exit | Seconds | Verdict |"
  echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|"
  printf '%s' "$rows"
  echo
  echo "Late-game layout, forced to tier 6 with a full board and hand:"
  echo
  echo "| Size | Seed | Problems | Errors | Exit | Verdict |"
  echo "|---|---|---|---|---|---|"
  printf '%s' "$late_rows"
  if grep -hs '^PROBLEM' "$OUT"/*.log >/dev/null; then
    echo
    echo "## Problems seen (first 40)"
    echo
    grep -hs '^PROBLEM' "$OUT"/*.log | head -n 40 | sed 's/^PROBLEM /- /'
  fi
} >"$REPORT"
echo "wrote $REPORT: $failed failed of $played games and 2 late checks; depth bar $bar"
[ "$failed" -eq 0 ] && [ "$bar" != "NOT MET" ]
