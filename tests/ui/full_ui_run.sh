#!/usr/bin/env bash
# Whole games through the real UI at PC and phone sizes, one Godot process a game, so a crash costs
# one game and shows as one. Every game passes the layout checks at every turn (tests/ui/layout_check.gd),
# with scouting opened and the guide, settings and pause visited; buttons and tiles are real mouse
# clicks, and a click that doesn't reach its target is a failure. Combats are watched at 4x.
# Drags go through the screen's own drop handlers. Writes docs/ideation/evidence/ui-run.md.
#   tests/ui/full_ui_run.sh [games per size, default 10] [first seed, default 1000]
# After the games, one short --late run a size: tier 6 and a full board and hand, forced through the
# dev panel, because a scripted player rarely gets that far. They count in the problems, not the 20.
# Exit 0 only with every game finished and no problem anywhere.
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
LEVELS=(naive easy normal hard)
mkdir -p "$OUT"
rm -f "$OUT"/*.log
: >build/.gdignore
rows=""
failed=0
played=0
smallest=9999
for size in 1920x1080 1688x780; do
  for ((i = 0; i < GAMES; i++)); do
    game_seed=$((FIRST_SEED + i))
    level="${LEVELS[$((i % 4))]}"
    log="$OUT/${size}_${game_seed}.log"
    start=$SECONDS
    timeout "$GAME_TIMEOUT" xvfb-run -a -s "-screen 0 2560x1440x24" "$GODOT" --rendering-driver opengl3 \
      --audio-driver Dummy -s res://tests/ui/shots/playthrough.gd -- "$size" --level "$level" "$game_seed" >"$log" 2>&1
    code=$?
    seconds=$((SECONDS - start))
    game_line=$(grep -m1 '^GAME seed' "$log" || true)
    place=$(echo "$game_line" | sed -n 's/.*place \([0-9]*\) after.*/\1/p')
    turns=$(echo "$game_line" | sed -n 's/.*after \([0-9]*\) turns.*/\1/p')
    problems=$(grep -c '^PROBLEM' "$log")
    # Quitting leaves resources held at exit; that's the tool, not the game.
    errors=$(grep -E 'SCRIPT ERROR|^ERROR|Parse Error' "$log" | grep -vc 'resources still in use at exit')
    text=$(sed -n 's/.*smallest text \([0-9]*\).*/\1/p' "$log" | tail -n 1)
    [ -n "$text" ] && [ "$text" -lt "$smallest" ] && smallest="$text"
    verdict=ok
    if [ "$code" -ne 0 ] || [ -z "$game_line" ] || [ "$problems" -gt 0 ] || [ "$errors" -gt 0 ]; then
      verdict=FAILED
      failed=$((failed + 1))
    fi
    played=$((played + 1))
    rows+="| $size | $game_seed | $level | ${place:-none} | ${turns:-none} | $problems | $errors | $code | $seconds | $verdict |"$'\n'
    echo "$size seed $game_seed $level: place ${place:-none}, turns ${turns:-none}, problems $problems, errors $errors, exit $code, ${seconds}s, $verdict"
  done
done
late_rows=""
for size in 1920x1080 1688x780; do
  log="$OUT/${size}_late.log"
  timeout "$GAME_TIMEOUT" xvfb-run -a -s "-screen 0 2560x1440x24" "$GODOT" --rendering-driver opengl3 \
    --audio-driver Dummy -s res://tests/ui/shots/playthrough.gd -- "$size" --late "$FIRST_SEED" >"$log" 2>&1
  code=$?
  problems=$(grep -c '^PROBLEM' "$log")
  verdict=ok
  if [ "$code" -ne 0 ] || [ "$problems" -gt 0 ]; then
    verdict=FAILED
    failed=$((failed + 1))
  fi
  late_rows+="| $size | $FIRST_SEED | $problems | $code | $verdict |"$'\n'
  echo "$size late: problems $problems, exit $code, $verdict"
done
{
  echo "# Scripted full UI run"
  echo
  echo "Made by \`tests/ui/full_ui_run.sh $GAMES $FIRST_SEED\` on $(git rev-parse --short HEAD) ($(git rev-parse --abbrev-ref HEAD)$(git diff --quiet -- src tests || echo ', with uncommitted changes')), $(date -u +%Y-%m-%d)."
  echo
  echo "**$failed failed out of $played games and 2 late-game checks.** Smallest text on screen: $smallest canvas units (the phone minimum is 31)."
  echo
  echo "What a game does: starts from the menu state, picks a hero, plays every turn to game over with a seeded scripted player. Buttons and tiles are real mouse clicks, and a click that doesn't reach its target is a problem. Drags go through the screen's own drop handlers. Each turn it opens Scout, taps their unit and a small shop tile, checks the layout before and after its actions and with a card selected, and watches the fight at 4x. Once a game it visits every guide page, settings and pause. Words on screen are checked for bot numbers, raw ids and tribes not in the lobby."
  echo
  echo "What it isn't: a real phone or a real finger. Agents can only measure layouts at phone size. The UI sees mouse input, which Godot also uses for touch."
  echo
  echo "| Size | Seed | Bots | Place | Turns | Problems | Errors | Exit | Seconds | Verdict |"
  echo "|---|---|---|---|---|---|---|---|---|---|"
  printf '%s' "$rows"
  echo
  echo "Late-game layout, forced to tier 6 with a full board and hand:"
  echo
  echo "| Size | Seed | Problems | Exit | Verdict |"
  echo "|---|---|---|---|---|"
  printf '%s' "$late_rows"
  if grep -hs '^PROBLEM' "$OUT"/*.log >/dev/null; then
    echo
    echo "## Problems seen (first 40)"
    echo
    grep -hs '^PROBLEM' "$OUT"/*.log | head -n 40 | sed 's/^PROBLEM /- /'
  fi
} >"$REPORT"
echo "wrote $REPORT: $failed failed of $played games and 2 late checks"
[ "$failed" -eq 0 ]
