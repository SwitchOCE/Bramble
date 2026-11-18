#!/usr/bin/env bash
# The referee's practice match (brief 7a; run-notes "Practice match").
# Loads each team's tag into the referee's match tree, checks it, builds, plays and prints
# the score. A team with no tag, a diff outside its folder, or a failed crate check plays
# as FlowBot, and the reason is printed.
#
# usage: practice_match.sh <label> <games> [<cores> [<threads>]]
#   e.g. practice_match.sh s1 1000          tags red-s1 / blue-s1, output matches/s1
# Run it in the background with a time limit; it uses the referee's cores only (4,5).
set -u
label=$1; games=$2; cores=${3:-4,5}; threads=${4:-2}
export PATH="$HOME/.cargo/bin:$PATH"
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ref=/home/alex/league/ref
out=/home/alex/league/matches/$label
[ -e "$out" ] && { echo "refusing: $out already exists"; exit 2; }
cd "$ref/tools/league" || exit 2

declare -A bot
for c in red blue; do
  clone=/home/alex/league/$c; tag=$c-$label; bot[$c]=$c
  if ! git -C "$clone" rev-parse -q --verify "refs/tags/$tag^{commit}" >/dev/null; then
    echo "$c: no tag $tag, FlowBot plays"; bot[$c]=flow; continue
  fi
  outside=$(git -C "$clone" diff --name-only league-engine-v1 "$tag" | grep -v "^tools/league/bots/$c/" | head -3)
  if [ -n "$outside" ]; then
    echo "$c: $tag changes files outside its folder ($(echo $outside)), FlowBot plays"; bot[$c]=flow; continue
  fi
  find "bots/$c" -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +
  git -C "$clone" archive "$tag" "tools/league/bots/$c" | tar -x -C "$ref" --exclude="tools/league/bots/$c/tools"
  echo "$c: loaded $tag ($(git -C "$clone" log -1 --format='%h, committed %cd' --date=format:%H:%M "$tag"))"
done

# Force both bot crates to rebuild: cargo goes by file time, and a tag unpacked from git
# carries its commit time, which can be older than the last build here.
cargo clean --offline --release -p red -p blue >/dev/null 2>&1
taskset -c "$cores" env CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p league 2>&1 | tail -3
build=${PIPESTATUS[0]}
for c in red blue; do
  [ "${bot[$c]}" = flow ] && continue
  if [ "$build" -ne 0 ] || ! taskset -c "$cores" target/release/league check-crate "bots/$c" --name "$c" >"/tmp/check-$c-$label.txt" 2>&1; then
    echo "$c: build or check-crate failed, FlowBot plays:"; tail -5 "/tmp/check-$c-$label.txt" 2>/dev/null
    bot[$c]=flow
    # put the stub back so the workspace builds
    find "bots/$c" -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +
    git -C "$ref" checkout -q -- "tools/league/bots/$c"
  fi
  rm -f "/tmp/check-$c-$label.txt"
done
if [ "$build" -ne 0 ]; then
  taskset -c "$cores" env CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p league 2>&1 | tail -3 || exit 1
fi

seeds=/home/alex/league/matches/$label.seeds
python3 -c "import secrets,sys; print('\n'.join(str(secrets.randbelow(2**31)) for _ in range((int(sys.argv[1])+1)//2)))" "$games" > "$seeds"
echo "playing $games games: red=${bot[red]} blue=${bot[blue]}"
taskset -c "$cores" target/release/league match --red "${bot[red]}" --blue "${bot[blue]}" --games "$games" \
  --seeds "$seeds" --clock-ms 1000 --threads "$threads" --out "$out" \
  --red-label "red-$label" --blue-label "blue-$label" >/dev/null || { echo "match failed, exit $?"; exit 1; }
taskset -c "$cores" target/release/league analyze "$out" | head -8
python3 "$here/analysis/winscore.py" "$out"
