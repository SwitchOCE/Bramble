#!/usr/bin/env bash
# The film tool's own check (about 30 s): film the demo, see that the mp4 holds every frame at
# 60 fps, and that the scene got the input (the red rectangle on its place, the blue one home).
# Exits 77, filming nothing, where xvfb-run, ffmpeg or ffprobe is missing: skipped, not passed.
# Usage: tools/feel/check.sh [out dir]   (default: a temporary folder, removed after)
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIPPED=77
for tool in xvfb-run ffmpeg ffprobe; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "feel check SKIPPED: $tool is not installed (tools/feel/README.md)"
    exit "$SKIPPED"
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
# The demo's steps last 1.5 s (90 frames); the runner adds 5 settling frames before them and a
# 0.5 s tail (30) after, and the movie writer one more: 126, every time.
want=126
read -r frames rate < <(ffprobe -v error -count_frames -select_streams v:0 \
  -show_entries stream=nb_read_frames,r_frame_rate -of csv=p=0 "$out/demo.mp4" |
  awk -F, '{print $2, $1}')
events=$(wc -l <"$out/demo.events")
report=$(tr -d ' \n' <"$out/demo.report.json")
fail=""
[ "$rate" = "60/1" ] || fail+=" rate $rate, not 60/1;"
[ "$frames" -eq "$want" ] || fail+=" $frames frames, not $want;"
[ "$events" -eq 4 ] || fail+=" $events events, not 4;"
case "$report" in *'"box:0":"place:0"'*) ;; *) fail+=" red not on its place;" ;; esac
case "$report" in *'"box:1":"home"'*) ;; *) fail+=" blue not home;" ;; esac
if [ -n "$fail" ]; then
  echo "feel check FAILED:$fail report $report"
  exit 1
fi
echo "feel check: the demo filmed $frames frames at 60 fps; the scene took the drag and the drop"
