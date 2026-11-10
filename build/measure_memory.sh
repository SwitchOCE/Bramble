#!/usr/bin/env bash
# Measure actual GUI starts on a dry-run Linux export; Xvfb/time/xdotool are outside the measured process.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$(realpath "${1:?usage: build/measure_memory.sh <dry-run-folder>}")"
[ -x "$out/linux/bramble.x86_64" ]
only_mode="${2:-all}"
only_run="${3:-all}"
for mode in normal field; do
  if [ "$only_mode" != all ] && [ "$mode" != "$only_mode" ]; then continue; fi
  for run in 1 2 3; do
    if [ "$only_run" != all ] && [ "$run" != "$only_run" ]; then continue; fi
    work="$out/memory/$mode-$run"
    mkdir -p "$work/data/godot/app_userdata/Bramble" "$work/config"
    opponents=bots
    [ "$mode" = normal ] || opponents=field
    cat >"$work/data/godot/app_userdata/Bramble/settings.cfg" <<SETTINGS
[guide]
seen=true
[game]
opponents="$opponents"
SETTINGS
    # shellcheck disable=SC2016
    GODOT_SLOT_CLASS=worker "$ROOT/scripts/godot_slot.sh" \
      xvfb-run -a -s '-screen 0 1920x1080x24' bash -c '
        set -euo pipefail
        export XDG_DATA_HOME="$1/data" XDG_CONFIG_HOME="$1/config" LP_NUM_THREADS=6
        /usr/bin/time -v -o "$1/time.txt" "$2/linux/bramble.x86_64" \
          --audio-driver Dummy --rendering-method gl_compatibility --resolution 1920x1080 \
          --position 0,0 --max-fps 30 --quit-after 600 >"$1/start.log" 2>&1 &
        timed_pid=$!
        window=$(timeout 20 xdotool search --sync --name "Bramble")
        sleep 2
        xdotool mousemove --window "$window" 1620 284 click 1
        sleep 6
        xdotool mousemove --window "$window" 640 350 click 1
        sleep 4
        import -window "$window" "$1/start.png"
        wait "$timed_pid"
      ' bash "$work" "$out"
    grep -qxF 'boot: main scene ready' "$work/start.log"
    if grep -E 'SCRIPT ERROR|^ERROR:|Parse Error' "$work/start.log"; then exit 1; fi
    grep 'Maximum resident set size' "$work/time.txt"
  done
done
python3 - "$out" <<'PY'
import json, re, statistics, sys
from pathlib import Path
out = Path(sys.argv[1])
result = {}
for mode in ('normal', 'field'):
    values = [int(re.search(r'Maximum resident set size \(kbytes\): (\d+)',
              (out / f'memory/{mode}-{i}/time.txt').read_text())[1]) for i in (1,2,3)]
    result[mode] = {'peak_rss_kib': values, 'median_kib': statistics.median(values)}
result['median_delta_bytes'] = (result['field']['median_kib'] - result['normal']['median_kib']) * 1024
result['within_300_mb'] = result['median_delta_bytes'] <= 300_000_000
(out / 'memory/results.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
PY
