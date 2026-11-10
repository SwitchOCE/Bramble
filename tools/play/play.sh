#!/usr/bin/env bash
# Plays the real game by commands. See tools/play/README.md.
#   tools/play/play.sh new --seed 5     prints the save's path
#   tools/play/play.sh <save> buy 2
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_BIN="${GODOT:-godot}"
args=("$@")
if [ "${1:-}" = "new" ]; then
  # A save path unless one was given: build/play/game-<seed>[-n].json
  seed="" given=""
  for ((i = 1; i < $#; i++)); do
    next="${args[$i]}"
    value="${args[$((i + 1))]:-}"
    case "$next" in
      --seed) seed="$value" ;;
      --save) given="$value" ;;
    esac
  done
  if [ -z "$seed" ]; then
    seed="$RANDOM"
    args+=(--seed "$seed")
  fi
  if [ -z "$given" ]; then
    mkdir -p "$ROOT/build/play"
    path="$ROOT/build/play/game-$seed.json"
    n=2
    while [ -e "$path" ]; do
      path="$ROOT/build/play/game-$seed-$n.json"
      n=$((n + 1))
    done
    args+=(--save "$path")
  fi
elif [ "${1:-}" = replay-log ]; then
  # The log file, and a save path unless one was given: build/play/replay-<log stem>.json
  [ $# -ge 2 ] && args[1]="$(realpath -m "$2")"
  given=""
  for ((i = 1; i < $#; i++)); do
    case "${args[$i]}" in
      --save) given="${args[$((i + 1))]:-}" ;;
    esac
  done
  if [ -z "$given" ] && [ $# -ge 2 ]; then
    mkdir -p "$ROOT/build/play"
    stem="$(basename "$2" .json)"
    args+=(--save "$ROOT/build/play/replay-$stem.json")
  fi
elif [ $# -gt 0 ] && [ "$1" != help ]; then
  args[0]="$(realpath -m "$1")"
fi
# The variant map is read after the cd below.
if [ -n "${BRAMBLE_VARIANT_MAP:-}" ]; then
  BRAMBLE_VARIANT_MAP="$(realpath -m "$BRAMBLE_VARIANT_MAP")"
  export BRAMBLE_VARIANT_MAP
fi
cd "$ROOT" || exit 1
# A fresh checkout has no class cache, and the scripts can't find each other without one.
if ! grep -q 'PlayGame' .godot/global_script_class_cache.cfg 2>/dev/null; then
  "$GODOT_BIN" --headless --import >/dev/null 2>&1
fi
"$GODOT_BIN" --headless -s res://tools/play/play.gd -- "${args[@]}" 2>&1 | grep -v '^Godot Engine'
exit "${PIPESTATUS[0]}"
