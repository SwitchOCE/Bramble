#!/usr/bin/env bash
# Screenshots a mock-up page at 1920 x 1080 with headless Edge.
#   tools/art/mockups/shot.sh <page.html> "<query>" <out.png> [height]
set -e
EDGE="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
page=$(cygpath -m "$(realpath "$1")"); out=$(cygpath -w "$(realpath -m "$3")"); h=${4:-1080}
"$EDGE" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
  --virtual-time-budget=6000 --window-size=1920,$h --screenshot="$out" "file:///$page?shot&$2" 2>/dev/null
