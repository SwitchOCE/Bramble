#!/usr/bin/env bash
# The third run's climbing match (third-run brief, section 5): a team's new tag against its
# current kept version, as a paired ghost match on the climbing field.
#
# usage: climb_match.sh COLOUR NEW CUR [GAMES]
#   COLOUR  red or blue
#   NEW     the team's new tag in its clone (e.g. red-c1)
#   CUR     the current kept version's tag (e.g. red-m2)
#   GAMES   even, default 1000 (500 pairs)
# env: FIELD (default /data/third-run/field-fa1d51ec), OUT_ROOT (default /data/third-run/matches),
#      TREE (the build worktree, default /data/third-run/match-tree), CORES (default 2-5),
#      THREADS (default 4)
#
# It prints one verdict line and writes it to OUT/verdict.txt. Lower placement is better, so the
# new version is better when gap (new minus current) + ci95 < 0. Keeping, cutting into the field
# and pruning are separate steps (see the run notes).
set -euo pipefail
[[ $# -ge 3 && $# -le 4 ]] || { sed -n 2,17p "$0" >&2; exit 2; }
colour=$1 new=$2 cur=$3 games=${4:-1000}
[[ $colour == red || $colour == blue ]] || { echo "colour must be red or blue" >&2; exit 2; }
(( games % 2 == 0 )) || { echo "games must be even" >&2; exit 2; }
clone=/home/alex/league/$colour
field=${FIELD:-/data/third-run/field-fa1d51ec}
out_root=${OUT_ROOT:-/data/third-run/matches}
tree=${TREE:-/data/third-run/match-tree}
cores=${CORES:-2-5}
threads=${THREADS:-4}
checker=/data/third-run/referee-tree/tools/league/target/release/league
lg=$tree/tools/league
out=$out_root/$new-vs-$cur
[[ ! -e $out ]] || { echo "$out exists" >&2; exit 1; }

# 1. A tag made in the third run may touch only the team's bot folder. The m2 tags predate the
#    engine merge; only their bot folder is used.
for t in "$new" "$cur"; do
  git -C "$clone" rev-parse -q --verify "refs/tags/$t" >/dev/null || { echo "no tag $t in $clone" >&2; exit 1; }
  if [[ $t != "$colour-m2" ]]; then
    bad=$(git -C "$clone" diff --name-only third-run-engine-v1 "$t" -- . ":(exclude)tools/league/bots/$colour")
    [[ -z $bad ]] || { echo "$t changes files outside its bot folder:" >&2; echo "$bad" >&2; exit 1; }
  fi
done

# 2. The build tree: the engine with NEW as `$colour` and CUR as `$colour-cur`.
git -C "$tree" checkout -q -- tools/league
git -C "$tree" clean -fdq -- tools/league/bots
find "$lg/bots/$colour" -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} +
git -C "$clone" archive "$new" "tools/league/bots/$colour" | tar -x -C "$tree" --exclude="tools/league/bots/$colour/tools"
mkdir "$lg/bots/$colour-cur"
git -C "$clone" archive --prefix=x/ "$cur" "tools/league/bots/$colour" \
  | tar -x -C "$lg/bots/$colour-cur" --strip-components=5 --exclude="x/tools/league/bots/$colour/tools"
sed -i "s/^name = \"$colour\"$/name = \"$colour-cur\"/" "$lg/bots/$colour-cur/Cargo.toml"
grep -q "^name = \"$colour-cur\"$" "$lg/bots/$colour-cur/Cargo.toml"
sed -i "s|^    \"bots/blue\",$|    \"bots/blue\",\n    \"bots/$colour-cur\",|" "$lg/Cargo.toml"
sed -i "s|^blue = { path = \"../blue\" }$|blue = { path = \"../blue\" }\n$colour-cur = { path = \"../$colour-cur\" }|" "$lg/bots/registry/Cargo.toml"
sed -i "s|^        (\"blue\", blue::new_bot),$|        (\"blue\", blue::new_bot),\n        (\"$colour-cur\", ${colour}_cur::new_bot),|" "$lg/bots/registry/src/lib.rs"
grep -q "$colour-cur" "$lg/Cargo.toml" "$lg/bots/registry/Cargo.toml" "$lg/bots/registry/src/lib.rs"

# 3. The crate rules for the new tag, before anything of it is built.
"$checker" check-crate "$lg/bots/$colour" --name "$colour"

# 4. A forced rebuild of both team crates. Cargo rebuilds by file time, `git archive` stamps files
#    with the commit time, and with cargo 1.100's build-dir layout `cargo clean -p` leaves the
#    artifacts in place. So touch every bot file, then check both crates were really recompiled.
cd "$lg"
mkdir -p "$out_root"
marker=$(mktemp "$out_root/.build-marker.XXXXXX")
sleep 1
find "bots/$colour" "bots/$colour-cur" -type f -exec touch {} +
cargo update -q --offline --workspace
cargo clean -q -p "$colour" -p "$colour-cur" -p league-bots -p league
CARGO_BUILD_JOBS=4 timeout -k 10 1200 taskset -c "$cores" cargo build -q --offline --release -p league
for crate in "$colour" "${colour}_cur"; do
  [[ -n $(find target -name "lib${crate}-*.rlib" -newer "$marker" -print -quit) ]] \
    || { echo "crate $crate was not recompiled" >&2; rm -f "$marker"; exit 1; }
done
rm -f "$marker"

# 5. Fresh seeds and secret, kept with the match.
mkdir -p "$out"
python3 -c "import secrets; print('\n'.join(str(secrets.randbits(62)) for _ in range($games // 2)))" > "$out/seeds.txt"
secret=$(python3 -c "import secrets; print(secrets.token_hex(16))")
echo "$secret" > "$out/secret.txt"
start=$SECONDS
timeout -k 10 7200 taskset -c "$cores" target/release/league ghost-match --red "$colour" --blue "$colour-cur" \
  --red-label "$new" --blue-label "$cur" --field "$field" --games "$games" --seeds "$out/seeds.txt" \
  --clock-ms 1000 --threads "$threads" --out "$out" --secret "$secret" > "$out/run.log" 2>&1
echo "ghost-match took $((SECONDS - start))s" >> "$out/run.log"

# 6. The decision inputs.
target/release/league analyze "$out" > "$out/analyze.log" 2>&1
python3 proof/check_ghost_match.py "$out" "$games" > "$out/check.log" 2>&1
python3 - "$out" "$new" "$cur" "$games" <<'EOF'
import json, sys, hashlib, pathlib
out, new, cur, games = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3], int(sys.argv[4])
a = json.load(open(out / "analysis.json"))["score"]
s = json.load(open(out / "summary.json"))
s = s.get("summary", s)
gap, ci = a["gap_red_minus_blue"], a["gap_ci95"]
better = gap + ci < 0
sha = hashlib.sha256((out / "seeds.txt").read_bytes()).hexdigest()[:12]
line = (f"{new} vs {cur}: games {games}, gap {gap:+.3f} ± {ci:.3f} (new minus current; lower is better), "
        f"new {s['red_avg_place']:.3f} current {s['blue_avg_place']:.3f}, rules {s['rules_hash'][:8]}, "
        f"seeds {sha}: {'NEW BETTER' if better else 'not better'}")
(out / "verdict.txt").write_text(line + "\n")
print(line)
EOF
