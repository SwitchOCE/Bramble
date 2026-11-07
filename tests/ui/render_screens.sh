#!/usr/bin/env bash
# Renders every UI screen from real core state under xvfb at desktop and phone sizes, and writes
# native-size JPEGs (quality 80) to build/screens/. tests/ui/render_screens.sh publish then copies
# the JPEGs into docs/ideation/evidence/ui/ (kept under 5 MB).
#   SCREEN_SIZES="1688x780" tests/ui/render_screens.sh [screen ...]
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
GODOT="${GODOT:-godot}"
# Mesa llvmpipe starts a render thread per core; the machine is shared (CLAUDE.md: half the cores).
export LP_NUM_THREADS="${LP_NUM_THREADS:-1}"
# The project venv may omit Pillow; use the system interpreter when its image codec is available.
PYTHON="${PYTHON:-python3}"
if ! "$PYTHON" -c 'from PIL import Image; Image.new("RGB", (1, 1))' >/dev/null 2>&1; then
  if /usr/bin/python3 -c 'from PIL import Image; Image.new("RGB", (1, 1))' >/dev/null 2>&1; then
    PYTHON=/usr/bin/python3
  else
    echo "Pillow with working image codecs is required to render screenshots" >&2
    exit 1
  fi
fi
OUT_PNG=build/screens
OUT_JPG=build/screens/jpg
mkdir -p "$OUT_PNG" "$OUT_JPG"
if [ "${1:-}" = publish ]; then
  mkdir -p docs/ideation/evidence/ui
  rm -f docs/ideation/evidence/ui/*.jpg
  for jpg in "$OUT_JPG"/*.jpg; do
    "$PYTHON" -c "import sys; from PIL import Image; im=Image.open(sys.argv[1]).convert('RGB'); im.thumbnail((1280, 1280), Image.LANCZOS); im.save(sys.argv[2], quality=45, optimize=True, progressive=True)" \
      "$jpg" "docs/ideation/evidence/ui/$(basename "$jpg")"
  done
  du -sh docs/ideation/evidence/ui
  exit 0
fi
SCREENS=("$@")
[ "${#SCREENS[@]}" -gt 0 ] || SCREENS=(menu menu_records settings pause guide_1 guide_2 guide_3 guide_4 guide_5 guide_6 guide_7 guide_8 guide_9 guide_10 guide_11 guide_12 commit_bonus commit_harvest commit_mrs_jay scout_lanes scout_lanes_select recruit_poached combat_lanes combat_lanes_after recruit recruit_select recruit_triple recruit_late recruit_frozen recruit_held recruit_held_ooze recruit_held_bird scout_held combat_held scout_live scout_live_select recruit_spells discover hero_choice recruit_slice scout pass_drag ghost_next dev combat_mid combat_end sandbox sandbox_scenarios sandbox_fight game_over)
read -r -a SIZES <<< "${SCREEN_SIZES:-1920x1080 1688x780}"
for size in "${SIZES[@]}"; do
  for screen in "${SCREENS[@]}"; do
    # Cards from test fixtures are labelled by the file's name: they aren't what a player sees.
    prefix=""
    case "$screen" in recruit_spells | discover | hero_choice | recruit_slice | scout | scout_long_name | pass_drag | ghost_next) prefix="fixture_" ;; esac
    png="$OUT_PNG/${prefix}${screen}_${size}.png"
    timeout 120 xvfb-run -a -s "-screen 0 2560x1440x24" "$GODOT" --rendering-driver opengl3 \
      --audio-driver Dummy -s res://tests/ui/shots/screenshot.gd -- "$screen" "$size" "$png" \
      >"$OUT_PNG/${screen}_${size}.log" 2>&1 || { echo "FAILED $screen $size"; tail -n 20 "$OUT_PNG/${screen}_${size}.log"; exit 1; }
    # Quitting mid-fight leaves a resource held at exit; only the shot tool does that.
    if grep -E "SCRIPT ERROR|^ERROR|Parse Error" "$OUT_PNG/${screen}_${size}.log" | grep -v "resources still in use at exit"; then
      echo "errors while rendering $screen $size"; exit 1
    fi
    "$PYTHON" -c "import sys; from PIL import Image; Image.open(sys.argv[1]).convert('RGB').save(sys.argv[2], quality=80)" \
      "$png" "$OUT_JPG/${prefix}${screen}_${size}.jpg"
    echo "ok $OUT_JPG/${prefix}${screen}_${size}.jpg"
  done
done
