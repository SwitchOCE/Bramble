#!/usr/bin/env bash
# Red's kept version against blue's, as a paired ghost match on the climbing field (the daily
# report's gap between the teams). A reading, not a climbing decision.
# usage: head_to_head.sh RED_TAG BLUE_TAG [GAMES]
# env: FIELD, OUT_ROOT, TREE, CORES, THREADS as in climb_match.sh
set -euo pipefail
[[ $# -ge 2 && $# -le 3 ]] || { sed -n 2,6p "$0" >&2; exit 2; }
red_tag=$1 blue_tag=$2 games=${3:-1000}
field=${FIELD:-/data/third-run/field-fa1d51ec}
out_root=${OUT_ROOT:-/data/third-run/matches}
tree=${TREE:-/data/third-run/match-tree}
cores=${CORES:-2-5}
threads=${THREADS:-4}
lg=$tree/tools/league
out=$out_root/$red_tag-vs-$blue_tag
[[ ! -e $out ]] || { echo "$out exists" >&2; exit 1; }

git -C "$tree" checkout -q -- tools/league
git -C "$tree" clean -fdq -- tools/league/bots
for c in red blue; do
  t=$([[ $c == red ]] && echo "$red_tag" || echo "$blue_tag")
  find "$lg/bots/$c" -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +
  git -C "/home/alex/league/$c" archive "$t" "tools/league/bots/$c" | tar -x -C "$tree" --exclude="tools/league/bots/$c/tools"
done

# Forced rebuild: see climb_match.sh step 4.
cd "$lg"
mkdir -p "$out_root"
marker=$(mktemp "$out_root/.build-marker.XXXXXX")
sleep 1
find bots/red bots/blue -type f -exec touch {} +
CARGO_BUILD_JOBS=4 timeout -k 10 1200 taskset -c "$cores" cargo build -q --offline --release -p league
for crate in red blue; do
  [[ -n $(find target -name "lib${crate}-*.rlib" -newer "$marker" -print -quit) ]] \
    || { echo "crate $crate was not recompiled" >&2; rm -f "$marker"; exit 1; }
done
rm -f "$marker"

mkdir -p "$out"
python3 -c "import secrets; print('\n'.join(str(secrets.randbits(62)) for _ in range($games // 2)))" > "$out/seeds.txt"
secret=$(python3 -c "import secrets; print(secrets.token_hex(16))")
timeout -k 10 7200 taskset -c "$cores" target/release/league ghost-match --red red --blue blue \
  --red-label "$red_tag" --blue-label "$blue_tag" --field "$field" --games "$games" --seeds "$out/seeds.txt" \
  --clock-ms 1000 --threads "$threads" --out "$out" --secret "$secret" > "$out/run.log" 2>&1
target/release/league analyze "$out" > "$out/analyze.log" 2>&1
python3 proof/check_ghost_match.py "$out" "$games" > "$out/check.log" 2>&1
python3 - "$out" "$red_tag" "$blue_tag" "$games" <<'EOF'
import json, sys, pathlib
out, red, blue, games = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3], int(sys.argv[4])
a = json.load(open(out / "analysis.json"))["score"]
line = (f"{red} vs {blue}: games {games}, red {a['red_avg_place']:.3f} blue {a['blue_avg_place']:.3f}, "
        f"gap {a['gap_red_minus_blue']:+.3f} ± {a['gap_ci95']:.3f} (red minus blue; lower is better)")
(out / "verdict.txt").write_text(line + "\n")
print(line)
EOF
