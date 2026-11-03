#!/usr/bin/env bash
# Renders every UI screen from real core state under xvfb at desktop and phone sizes, and writes
# native-size JPEGs (quality 85) to docs/prototype/screens/. PNGs stay in build/screens/.
#   tests/ui/render_screens.sh [screen ...]
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
GODOT="${GODOT:-godot}"
# Mesa llvmpipe starts a render thread per core; the machine is shared (CLAUDE.md: half the cores).
export LP_NUM_THREADS="${LP_NUM_THREADS:-2}"
OUT_PNG=build/screens
OUT_JPG=docs/prototype/screens
mkdir -p "$OUT_PNG" "$OUT_JPG"
SCREENS=("$@")
[ "${#SCREENS[@]}" -gt 0 ] || SCREENS=(menu recruit recruit_select recruit_triple dev combat_mid combat_end sandbox sandbox_fight game_over)
for size in 1920x1080 1688x780; do
  for screen in "${SCREENS[@]}"; do
    png="$OUT_PNG/${screen}_${size}.png"
    timeout 120 xvfb-run -a -s "-screen 0 2560x1440x24" "$GODOT" --rendering-driver opengl3 \
      --audio-driver Dummy -s res://tests/ui/shots/screenshot.gd -- "$screen" "$size" "$png" \
      >"$OUT_PNG/${screen}_${size}.log" 2>&1 || { echo "FAILED $screen $size"; tail -n 20 "$OUT_PNG/${screen}_${size}.log"; exit 1; }
    if grep -E "SCRIPT ERROR|^ERROR|Parse Error" "$OUT_PNG/${screen}_${size}.log"; then
      echo "errors while rendering $screen $size"; exit 1
    fi
    python3 -c "import sys; from PIL import Image; Image.open(sys.argv[1]).convert('RGB').save(sys.argv[2], quality=85)" \
      "$png" "$OUT_JPG/${screen}_${size}.jpg"
    echo "ok $OUT_JPG/${screen}_${size}.jpg"
  done
done
