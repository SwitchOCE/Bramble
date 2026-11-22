#!/usr/bin/env bash
# The stopping test's reference field (third-run brief, section 3.3): the current kept versions
# played live against each other, cut into a fresh field and frozen for one stopping test.
# The teams never read it.
#
# usage: ref_field.sh RED_TAG BLUE_TAG OUT_FIELD [GAMES]
#   GAMES  even, default 1500 (about 12,000 runs)
# env: TREE (default /data/third-run/match-tree), CORES (default 2-5), THREADS (default 4)
#
# It uses the match tree, so it must not run while a climbing match does.
set -euo pipefail
[[ $# -ge 3 && $# -le 4 ]] || { sed -n 2,10p "$0" >&2; exit 2; }
red_tag=$1 blue_tag=$2 field=$(realpath -m -- "$3") games=${4:-1500}
(( games % 2 == 0 )) || { echo "games must be even" >&2; exit 2; }
tree=${TREE:-/data/third-run/match-tree}
cores=${CORES:-2-5}
threads=${THREADS:-4}
lg=$tree/tools/league
[[ ! -e $field ]] || { echo "$field exists" >&2; exit 1; }

git -C "$tree" checkout -q -- tools/league
git -C "$tree" clean -fdq -- tools/league/bots
for c in red blue; do
  t=$([[ $c == red ]] && echo "$red_tag" || echo "$blue_tag")
  find "$lg/bots/$c" -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +
  git -C "/home/alex/league/$c" archive "$t" "tools/league/bots/$c" | tar -x -C "$tree" --exclude="tools/league/bots/$c/tools"
done

# Forced rebuild: see climb_match.sh step 4.
cd "$lg"
work=$(mktemp -d "$(dirname "$field")/.ref-field-match.XXXXXXXX")
marker=$work/.build-marker
touch "$marker"
sleep 1
find bots/red bots/blue -type f -exec touch {} +
cargo clean -q -p red -p blue -p league-bots -p league
CARGO_BUILD_JOBS=4 timeout -k 10 1200 taskset -c "$cores" cargo build -q --offline --release -p league -p bramble-ghosts
for crate in red blue; do
  [[ -n $(find target -name "lib${crate}-*.rlib" -newer "$marker" -print -quit) ]] \
    || { echo "crate $crate was not recompiled" >&2; exit 1; }
done
rules_hash=$(python3 -c 'import json; print(json.load(open("league/build.json"))["rules_hash"])')

python3 -c "import secrets; print('\n'.join(str(secrets.randbits(62)) for _ in range($games // 2)))" > "$work/seeds.txt"
start=$SECONDS
timeout -k 10 7200 taskset -c "$cores" target/release/league match --red red --blue blue \
  --red-label "$red_tag" --blue-label "$blue_tag" --games "$games" --seeds "$work/seeds.txt" --clock-ms 1000 --threads "$threads" --out "$work/match" > "$work/run.log" 2>&1
echo "ref_field: live match ($red_tag vs $blue_tag, $games games) took $((SECONDS - start))s"
mkdir "$field"
timeout -k 10 1200 target/release/bramble-ghosts cut --match "$work/match" \
  --store "$field" --repo-root "$tree" --made "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
timeout -k 10 1800 target/release/bramble-ghosts index --store "$field"
timeout -k 10 300 target/release/bramble-ghosts verify --store "$field" --rules-hash "$rules_hash"
python3 - "$field" "$red_tag" "$blue_tag" <<'EOF'
import collections, json, pathlib, sys
f, red, blue = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
rows = [json.loads(l) for l in open(f / "index.jsonl")]
print("ref_field:", len(rows), "runs", dict(collections.Counter(r["label"] for r in rows)))
EOF
cp "$work/seeds.txt" "$field.seeds.txt"
rm -rf "${work:?}"
