#!/usr/bin/env bash
# Plays the real game by commands. See tools/play/README.md.
#   tools/play/play.sh new --seed 5 --difficulty hard     prints the save's path
#   tools/play/play.sh <save> buy 2
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_BIN="${GODOT:-godot}"
args=("$@")
if [ "${1:-}" = "new" ]; then
  # A save path unless one was given: build/play/game-<seed>-<difficulty>[-n].json
  seed="" level="normal" given=""
  for ((i = 1; i < $#; i++)); do
    next="${args[$i]}"
    value="${args[$((i + 1))]:-}"
    case "$next" in
      --seed) seed="$value" ;;
      --difficulty) level="$value" ;;
      --save) given="$value" ;;
    esac
  done
  if [ -z "$seed" ]; then
    seed="$RANDOM"
    args+=(--seed "$seed")
  fi
  if [ -z "$given" ]; then
    mkdir -p "$ROOT/build/play"
    path="$ROOT/build/play/game-$seed-$level.json"
    n=2
    while [ -e "$path" ]; do
      path="$ROOT/build/play/game-$seed-$level-$n.json"
      n=$((n + 1))
    done
    args+=(--save "$path")
  fi
elif [ $# -gt 0 ]; then
  args[0]="$(realpath -m "$1")"
fi
cd "$ROOT" || exit 1
"$GODOT_BIN" --headless -s res://tools/play/play.gd -- "${args[@]}" 2>&1 | grep -v '^Godot Engine'
exit "${PIPESTATUS[0]}"
