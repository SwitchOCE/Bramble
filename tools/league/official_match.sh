#!/usr/bin/env bash
# The referee's official match (brief 7b; run-notes "Official match").
# Takes each team's hand-in as a commit id, captured by the referee at the deadline, so a tag
# moved afterwards changes nothing. A team with no hand-in, a diff outside its folder, or a
# failed crate check plays as FlowBot, and the reason is printed.
#
# usage: official_match.sh <label> <red-commit|none> <blue-commit|none> load|smoke|counted
#   load     check both hand-ins, load them into the referee's match tree, build
#   smoke    20 games that don't count, into matches/<label>-smoke
#   counted  1,000 games with fresh seeds, into matches/<label>
# Run load, then smoke, then counted. Teams are paused, so it uses 5 threads on all cores.
set -u
label=$1; declare -A ref=([red]=$2 [blue]=$3); step=$4
cores=${CORES:-0-5}; threads=${THREADS:-5}
export PATH="$HOME/.cargo/bin:$PATH"
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=/home/alex/league/ref
state=/home/alex/league/matches/$label.bots
cd "$tree/tools/league" || exit 2

if [ "$step" = load ]; then
  declare -A bot
  for c in red blue; do
    clone=/home/alex/league/$c; r=${ref[$c]}; bot[$c]=$c
    if [ "$r" = none ] || ! git -C "$clone" rev-parse -q --verify "$r^{commit}" >/dev/null; then
      echo "$c: no hand-in, FlowBot plays"; bot[$c]=flow
    else
      outside=$(git -C "$clone" diff --name-only league-engine-v1 "$r" | grep -v "^tools/league/bots/$c/" | head -3)
      if [ -n "$outside" ]; then
        echo "$c: $r changes files outside its folder ($(echo $outside)), FlowBot plays"; bot[$c]=flow
      fi
    fi
    find "bots/$c" -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +
    if [ "${bot[$c]}" = flow ]; then
      git -C "$tree" checkout -q -- "tools/league/bots/$c"
    else
      git -C "$clone" archive "$r" "tools/league/bots/$c" | tar -x -C "$tree" --exclude="tools/league/bots/$c/tools"
      echo "$c: loaded $(git -C "$clone" log -1 --format='%h, committed %cd' --date=format:'%d %b %H:%M:%S' "$r")"
    fi
  done
  for c in red blue; do
    [ "${bot[$c]}" = flow ] && continue
    if ! taskset -c "$cores" target/release/league check-crate "bots/$c" --name "$c" >"/tmp/check-$c-$label.txt" 2>&1; then
      echo "$c: check-crate failed, FlowBot plays:"; tail -5 "/tmp/check-$c-$label.txt"
      bot[$c]=flow
      find "bots/$c" -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +
      git -C "$tree" checkout -q -- "tools/league/bots/$c"
    else
      tail -1 "/tmp/check-$c-$label.txt" | cut -c1-120
    fi
    rm -f "/tmp/check-$c-$label.txt"
  done
  taskset -c "$cores" env CARGO_BUILD_JOBS=4 cargo build --offline --locked --release -p league 2>&1 | tail -2
  [ "${PIPESTATUS[0]}" -eq 0 ] || { echo "BUILD FAILED"; exit 1; }
  echo "red=${bot[red]} blue=${bot[blue]}" > "$state"
  echo "ready: $(cat "$state")"
  exit 0
fi

[ -f "$state" ] || { echo "run 'load' first"; exit 2; }
eval "$(cat "$state")"
play() { # <out> <games>
  local out=$1 games=$2 seeds=$1.seeds
  [ -e "$out" ] && { echo "refusing: $out already exists"; exit 2; }
  python3 -c "import secrets,sys; print('\n'.join(str(secrets.randbelow(2**31)) for _ in range((int(sys.argv[1])+1)//2)))" "$games" > "$seeds"
  echo "playing $games games: red=$red blue=$blue, $threads threads"
  taskset -c "$cores" target/release/league match --red "$red" --blue "$blue" --games "$games" \
    --seeds "$seeds" --clock-ms 1000 --threads "$threads" --out "$out" \
    --red-label "red-$label" --blue-label "blue-$label" >/dev/null
  local rc=$?
  [ $rc -eq 0 ] || { echo "MATCH FAILED, exit $rc (3 = a bot call never returned and the watchdog stopped the match)"; exit $rc; }
  taskset -c "$cores" target/release/league analyze "$out" | head -8
}
case "$step" in
  smoke)   play "/home/alex/league/matches/$label-smoke" 20 ;;
  counted) play "/home/alex/league/matches/$label" 1000
           python3 "$here/analysis/winscore.py" "/home/alex/league/matches/$label" ;;
  *) echo "unknown step $step"; exit 2 ;;
esac
