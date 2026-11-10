#!/usr/bin/env bash
# Renders a tools/play save on the real UI, at 1688x780 and 1920x1080, under xvfb and Mesa.
#   tools/play/render.sh <save> [--turn N | --all]     (default --all)
# Writes PNGs and index.md (commit, state hash per turn, every file) to build/render/<save stem>/.
#   RENDER_SIZES="1688x780" tools/play/render.sh <save>   one size only
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_BIN="${GODOT:-godot}"
[ $# -ge 1 ] || { sed -n '2,5s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; exit 2; }
save="$(realpath -m "$1")"
shift
[ -f "$save" ] || { echo "No save at $save"; exit 1; }
pick=(--all)
case "${1:-}" in
  --turn)
    [[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "--turn needs a turn number"; exit 2; }
    pick=(--turn "$2")
    ;;
  --all | "") ;;
  *) echo "unknown option: $1 (use --turn N or --all)"; exit 2 ;;
esac
out="$ROOT/build/render/$(basename "$save" .json)"
rm -rf "$out"
mkdir -p "$out"
cd "$ROOT"
if ! grep -q 'PlayTurns' .godot/global_script_class_cache.cfg 2>/dev/null; then
  "$GODOT_BIN" --headless --import >/dev/null 2>&1
fi
# Mesa llvmpipe starts a render thread per core; one is plenty for still frames.
export LP_NUM_THREADS="${LP_NUM_THREADS:-1}"
read -r -a sizes <<< "${RENDER_SIZES:-1688x780 1920x1080}"
for size in "${sizes[@]}"; do
  log="$out/render_$size.log"
  if ! timeout "${RENDER_TIMEOUT:-900}" xvfb-run -a -s "-screen 0 2560x1440x24" "$GODOT_BIN" --rendering-driver opengl3 \
    --audio-driver Dummy -s res://tools/play/render.gd -- "$save" "$size" "$out" "${pick[@]}" \
    >"$log" 2>&1; then
    echo "render failed at $size:"
    tail -n 20 "$log"
    exit 1
  fi
  if grep -E "SCRIPT ERROR|Parse Error" "$log"; then
    echo "errors while rendering at $size (full log: $log)"
    exit 1
  fi
  grep '^render:' "$log" || true
done
commit="$(git rev-parse HEAD)"
[ -z "$(git status --porcelain -- src content assets tools/play project.godot)" ] || commit="$commit (with uncommitted changes)"
python3 "$ROOT/tools/play/render_index.py" "$out" "$save" "$commit" "${pick[*]}"
echo "Index: $out/index.md"
