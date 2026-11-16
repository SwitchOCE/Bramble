#!/usr/bin/env bash
# The film tool's own check (about 15 s): film the demo and see that the mp4 holds every frame at
# 60 fps. Exits 0 with a note, filming nothing, where xvfb-run, ffmpeg or ffprobe is missing.
# Usage: tools/feel/check.sh [out dir]   (default: a temporary folder, removed after)
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for tool in xvfb-run ffmpeg ffprobe; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "feel check skipped: $tool is not installed (tools/feel/README.md)"
    exit 0
  fi
done
if [ $# -ge 1 ]; then
  out="$1"
  mkdir -p "$out"
else
  out="$(mktemp -d)"
  trap 'rm -rf "$out"' EXIT
fi
"$here/film" "$here/demo/demo.json" "$out/demo.mp4" >/dev/null
# The demo's steps last 1.5 s; the runner adds 5 settling frames and a 0.5 s tail: 126 frames.
want=126
read -r frames rate < <(ffprobe -v error -count_frames -select_streams v:0 \
  -show_entries stream=nb_read_frames,r_frame_rate -of csv=p=0 "$out/demo.mp4" |
  awk -F, '{print $2, $1}')
events=$(wc -l <"$out/demo.events")
if [ "$rate" != "60/1" ] || [ "$frames" -lt $((want - 2)) ] || [ "$frames" -gt $((want + 2)) ] ||
  [ "$events" -ne 4 ]; then
  echo "feel check FAILED: $frames frames at $rate, $events events (want $want at 60/1, 4 events)"
  exit 1
fi
echo "feel check: the demo filmed $frames frames at 60 fps, 4 presses and releases logged"
