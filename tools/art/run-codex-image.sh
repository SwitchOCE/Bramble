#!/usr/bin/env bash
# Runs one Codex image batch: tools/art/run-codex-image.sh <prompt-file> <out-dir> [reference-image ...]
# Linux port of run-codex-image.ps1. Stdin must be /dev/null or codex exec hangs.
# ART_TIMEOUT: seconds for the whole batch (default 1200; about 45 s per image).
set -euo pipefail
[ "$#" -ge 2 ] || {
  echo "usage: $0 <prompt-file> <out-dir> [reference-image ...]"
  exit 2
}
prompt_file="$(realpath "$1")"
out_dir="$2"
shift 2
mkdir -p "$out_dir"
out_dir="$(realpath "$out_dir")"
refs=()
for ref in "$@"; do
  refs+=(-i "$(realpath "$ref")")
done
timeout "${ART_TIMEOUT:-1200}" codex exec --skip-git-repo-check -s workspace-write -C "$out_dir" \
  "${refs[@]}" -- "$(cat "$prompt_file")" </dev/null 2>&1 | tail -n 15
