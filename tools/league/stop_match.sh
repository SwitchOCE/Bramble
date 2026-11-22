#!/usr/bin/env bash
# One stopping-test match (third-run brief, section 6): the version taken into the test with some
# knob lines changed, against that version unchanged, as a paired ghost match on the reference
# field.
#
# usage: stop_match.sh COLOUR BASE_TAG LABEL GAMES OUT_DIR
#   BASE_TAG  the tag the test version is built from
#   LABEL     the neighbour's name, e.g. swap_margin+ or idea-c4 or tribe-Badger
# env: BASE_KNOBS  knob lines, separated by ';', appended to both versions (the test version)
#      NEW_KNOBS   knob lines appended to the neighbour only
#      FIELD (the reference field, required), TREE (default /data/third-run/match-tree),
#      CORES (default 2-5), THREADS (default 4)
#
# A knob line appended later wins over the same knob earlier in data/knobs.txt. Run it under
# `flock /data/third-run/cores.lock`, like every match on cores 2-5.
set -euo pipefail
[[ $# -eq 5 ]] || { sed -n 2,15p "$0" >&2; exit 2; }
colour=$1 base=$2 label=$3 games=$4 out=$5
[[ $colour == red || $colour == blue ]] || { echo "colour must be red or blue" >&2; exit 2; }
(( games % 2 == 0 )) || { echo "games must be even" >&2; exit 2; }
field=${FIELD:?set FIELD to the reference field}
tree=${TREE:-/data/third-run/match-tree}
cores=${CORES:-2-5}
threads=${THREADS:-4}
clone=/home/alex/league/$colour
lg=$tree/tools/league
[[ ! -e $out ]] || { echo "$out exists" >&2; exit 1; }
bad=$(git -C "$clone" diff --name-only third-run-engine-v1 "$base" -- . ":(exclude)tools/league/bots/$colour")
[[ -z $bad ]] || { echo "$base changes files outside its bot folder" >&2; exit 1; }

git -C "$tree" checkout -q -- tools/league
git -C "$tree" clean -fdq -- tools/league/bots
find "$lg/bots/$colour" -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +
git -C "$clone" archive "$base" "tools/league/bots/$colour" | tar -x -C "$tree" --exclude="tools/league/bots/$colour/tools"
mkdir "$lg/bots/$colour-cur"
git -C "$clone" archive --prefix=x/ "$base" "tools/league/bots/$colour" \
  | tar -x -C "$lg/bots/$colour-cur" --strip-components=5 --exclude="x/tools/league/bots/$colour/tools"
sed -i "s/^name = \"$colour\"$/name = \"$colour-cur\"/" "$lg/bots/$colour-cur/Cargo.toml"
sed -i "s|^    \"bots/blue\",$|    \"bots/blue\",\n    \"bots/$colour-cur\",|" "$lg/Cargo.toml"
sed -i "s|^blue = { path = \"../blue\" }$|blue = { path = \"../blue\" }\n$colour-cur = { path = \"../$colour-cur\" }|" "$lg/bots/registry/Cargo.toml"
sed -i "s|^        (\"blue\", blue::new_bot),$|        (\"blue\", blue::new_bot),\n        (\"$colour-cur\", ${colour}_cur::new_bot),|" "$lg/bots/registry/src/lib.rs"
grep -q "$colour-cur" "$lg/Cargo.toml" "$lg/bots/registry/Cargo.toml" "$lg/bots/registry/src/lib.rs"

# The knob lines. Both get the test version's lines; the neighbour gets its own on top.
append() { # file, ';'-separated lines
  [[ -n $2 ]] || return 0
  printf '\n# stopping test (referee)\n' >> "$1"
  tr ';' '\n' <<< "$2" | sed 's/^ *//' >> "$1"
}
append "$lg/bots/$colour/data/knobs.txt" "${BASE_KNOBS:-}"
append "$lg/bots/$colour-cur/data/knobs.txt" "${BASE_KNOBS:-}"
append "$lg/bots/$colour/data/knobs.txt" "${NEW_KNOBS:-}"
mkdir -p "$out"
cp "$lg/bots/$colour/data/knobs.txt" "$out/knobs-new.txt"
cp "$lg/bots/$colour-cur/data/knobs.txt" "$out/knobs-cur.txt"

# Forced rebuild: see climb_match.sh step 4.
cd "$lg"
marker=$out/.build-marker
touch "$marker"
sleep 1
find "bots/$colour" "bots/$colour-cur" -type f -exec touch {} +
cargo update -q --offline --workspace
cargo clean -q -p "$colour" -p "$colour-cur" -p league-bots -p league
CARGO_BUILD_JOBS=4 timeout -k 10 1200 taskset -c "$cores" cargo build -q --offline --release -p league
for crate in "$colour" "${colour}_cur"; do
  [[ -n $(find target -name "lib${crate}-*.rlib" -newer "$marker" -print -quit) ]] \
    || { echo "crate $crate was not recompiled" >&2; exit 1; }
done
rm -f "$marker"

python3 -c "import secrets; print('\n'.join(str(secrets.randbits(62)) for _ in range($games // 2)))" > "$out/seeds.txt"
secret=$(python3 -c "import secrets; print(secrets.token_hex(16))")
echo "$secret" > "$out/secret.txt"
start=$SECONDS
timeout -k 10 7200 taskset -c "$cores" target/release/league ghost-match --red "$colour" --blue "$colour-cur" \
  --red-label "$label" --blue-label "$base" --field "$field" --games "$games" --seeds "$out/seeds.txt" \
  --clock-ms 1000 --threads "$threads" --out "$out" --secret "$secret" > "$out/run.log" 2>&1
echo "ghost-match took $((SECONDS - start))s" >> "$out/run.log"
target/release/league analyze "$out" > "$out/analyze.log" 2>&1
python3 proof/check_ghost_match.py "$out" "$games" > "$out/check.log" 2>&1
python3 - "$out" "$label" "$games" <<'EOF'
import json, sys, pathlib
out, label, games = pathlib.Path(sys.argv[1]), sys.argv[2], int(sys.argv[3])
a = json.load(open(out / "analysis.json"))["score"]
s = json.load(open(out / "summary.json"))
s = s.get("summary", s)
gap, ci = a["gap_red_minus_blue"], a["gap_ci95"]
word = "BEATS" if gap + ci < 0 else ("worse" if gap - ci > 0 else "no clear difference")
line = (f"{label}: games {games}, gap {gap:+.3f} ± {ci:.3f} (neighbour minus test version), "
        f"neighbour {s['red_avg_place']:.3f} test version {s['blue_avg_place']:.3f}: {word}")
(out / "verdict.txt").write_text(line + "\n")
print(line)
EOF
