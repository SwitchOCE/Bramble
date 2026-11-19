#!/usr/bin/env bash
# Refresh the GDScript reference corpus and the committed Rust proof fixtures.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/../.." && pwd)"
data="$(realpath -m "${1:-${LEAGUE_DATA:-/home/alex/engine-data/dev-level}}")"
jobs="${JOBS:-8}"
godot="${GODOT:-godot}"
live="$(realpath -m /home/alex/league)"

# The live league's data can be in use by a match. Check resolved paths as well.
for destination in "$data" "$data/records" "$data/records/gd" "$data/proof"; do
  resolved="$(realpath -m "$destination")"
  if [[ "$resolved/" == "$live/"* || "$live/" == "$resolved/"* ]]; then
    echo "refresh_reference: choose a directory separate from $live" >&2
    exit 2
  fi
done
for destination in "$data"/records/gd/c{0,1,2} "$data/records/tribe-gd" "$data/records/standin" "$data/fights" \
    "$data/proof/r2g-seeds.txt"; do
  if [[ -L "$destination" ]]; then
    echo "refresh_reference: expected a regular output path at $destination" >&2
    exit 2
  fi
done

if [[ ! "$jobs" =~ ^[1-8]$ ]]; then
  echo "refresh_reference: JOBS must be between 1 and 8" >&2
  exit 2
fi
mkdir -p "$data"
stage="$(mktemp -d "$data/.refresh-XXXXXX")"
mkdir -p "$stage/logs" "$stage/records/gd"/c{0,1,2} "$stage/records/tribe-gd" "$stage/records/standin" "$stage/fixtures"
cd "$repo"
# shellcheck source=scripts/godot_log.sh
. scripts/godot_log.sh
godot_log_init "$stage/logs"
echo "refresh_reference: staging data and logs in $stage"

run_godot() {
  local name=$1 seconds=$2
  shift 2
  local log="$stage/logs/$name.log"
  if ! timeout -k 10 "$seconds" "$godot" --headless --log-file "$log.engine" "$@" > "$log" 2>&1 \
      || godot_log_problems "$log"; then
    echo "refresh_reference: $name failed, see $log" >&2
    return 1
  fi
}

if [[ ! -f .godot/global_script_class_cache.cfg ]]; then
  run_godot import 120 --import
fi

# Six mixed-bot shards cover seeds 1–1000. Two TribeBot shards cover seeds 1–200.
pids=()
while read -r group games seed; do
  script=res://tools/checks/records.gd
  if [[ "$group" == tribe-gd ]]; then
    script=res://tools/league/gd/tribe_records.gd
  fi
  run_godot "${group##*/}-$seed" 3600 -s "$script" -- "games=$games" "first_seed=$seed" \
    "directory=$stage/records/$group" &
  pids+=("$!")
done <<'RECORDS'
gd/c0 167 1
gd/c0 167 168
gd/c1 167 335
gd/c1 167 502
gd/c2 166 669
gd/c2 166 835
tribe-gd 100 1
tribe-gd 100 101
RECORDS
failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || failed=1
done
if (( failed )); then exit 1; fi
run_godot standin 120 -s res://tools/league/gd/standin_records.gd -- games=3 seed=1 \
  "out=$stage/records/standin"

# Name the records by seed so process scheduling cannot affect corpus sampling order.
python3 - "$stage" <<'PY'
import json
import sys
from pathlib import Path

records = Path(sys.argv[1]) / "records"
for group, start, stop in [
    ("gd/c0", 1, 335), ("gd/c1", 335, 669), ("gd/c2", 669, 1001), ("tribe-gd", 1, 201),
]:
    directory = records / group
    by_seed = {}
    for path in directory.glob("*.jsonl"):
        with path.open(encoding="utf-8") as stream:
            seed = int(json.loads(stream.readline())["seed"])
        if seed in by_seed:
            sys.exit(f"{group}: duplicate record seed {seed}")
        by_seed[seed] = path
    if set(by_seed) != set(range(start, stop)):
        sys.exit(f"{group}: expected {stop - start} record seeds in {start}..{stop - 1}")
    for seed, path in by_seed.items():
        path.rename(directory / f"seed-{seed:04d}.jsonl")
PY

while read -r script output; do
  run_godot "$script" 120 -s "res://tools/league/gd/$script.gd" -- "out=$stage/fixtures/$output"
done <<'ORACLES'
dump_fields core_fields.json
prove_util util_vectors.json
prove_planted planted_vectors.json
prove_recipes recipe_headers.jsonl
prove_content content_states.json
prove_recruit_actions recruit_action_vectors.json
prove_recruit recruit_context_vectors.json
prove_session session_vectors.json
ORACLES
for seed in 1 42 -8172 9223372036854775807; do
  run_godot "initial_$seed" 120 -s res://tools/league/gd/dump_state.gd -- \
    "seed=$seed" "out=$stage/fixtures/initial_$seed.json"
done

python3 - "$stage" <<'PY'
import json
import random
import sys
from pathlib import Path

stage = Path(sys.argv[1])
fixtures = stage / "fixtures"
for name, prefix, filename in [
    ("prove_content", "BRAMBLE_CONTENT_VECTORS=", "content_vectors.json"),
    ("prove_recruit", "PROOF=", "recruit_context_vectors.json"),
]:
    lines = (stage / "logs" / f"{name}.log").read_text(encoding="utf-8").split("\n")
    vector = next(json.loads(line[len(prefix):]) for line in lines if line.startswith(prefix))
    (fixtures / filename).write_text(json.dumps(vector, indent=2, sort_keys=True) + "\n")
planted = fixtures / "planted_vectors.json"
planted.write_bytes(planted.read_bytes().rstrip(b"\n") + b"\n")
# The utility oracle deliberately includes a raw control character in a string.
util = fixtures / "util_vectors.json"
vector = json.loads(util.read_text(encoding="utf-8"), strict=False)
util.write_text(json.dumps(vector, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
prefix = "session_oracle: "
lines = (stage / "logs/prove_session.log").read_text(encoding="utf-8").split("\n")
checkpoints = [json.loads(line[len(prefix):]) for line in lines if line.startswith(prefix + "{")]
if len(checkpoints) != 9:
    sys.exit("session oracle did not emit all nine checkpoints")
(fixtures / "session_vectors.json").write_text(
    json.dumps({item["label"]: item["hash"] for item in checkpoints}, indent=2, sort_keys=True) + "\n"
)
with (fixtures / "recipe_headers.jsonl").open() as recipes:
    build = json.loads(recipes.readline())["build"]
(fixtures / "build.json").write_text(json.dumps(build, separators=(",", ":")) + "\n")
seeds = random.Random(20261119).sample(range(1, 2**31), 25)
(stage / "r2g-seeds.txt").write_text("".join(f"{seed}\n" for seed in seeds))
PY

# Preserve the published record paths in the fight corpus and its source manifest.
publish_dir() {
  local source=$1 destination=$2
  if [[ -e "$destination" ]]; then
    mv -T -- "$destination" "$stage/previous/${source##*/}"
  fi
  mv -T -- "$source" "$destination"
}
mkdir -p "$data/records/gd" "$data/proof" "$stage/previous"
for group in gd/c0 gd/c1 gd/c2 tribe-gd standin; do
  publish_dir "$stage/records/$group" "$data/records/$group"
done

timeout -k 10 14400 python3 "$here/fights/make_cases.py" \
  --records "$data"/records/gd/c{0,1,2} --count 100000 --jobs "$jobs" --godot "$godot" \
  --out "$stage/fights/cases.jsonl" --results "$stage/fights/gd.jsonl" \
  > "$stage/logs/fights.log" 2>&1 || { tail -n 8 "$stage/logs/fights.log" >&2; exit 1; }
tail -n 2 "$stage/logs/fights.log"
mv -- "$stage/fights/cases.work/rejected.jsonl" "$stage/fights/rejected.jsonl"
rm -rf -- "$stage/fights/cases.work"
publish_dir "$stage/fights" "$data/fights"
mv -T -- "$stage/r2g-seeds.txt" "$data/proof/r2g-seeds.txt"

for fixture in core_fields.json util_vectors.json planted_vectors.json recipe_headers.jsonl \
    content_vectors.json recruit_action_vectors.json recruit_context_vectors.json session_vectors.json; do
  cp -- "$stage/fixtures/$fixture" "$here/gd/$fixture"
done
cp -- "$stage/fixtures"/initial_*.json "$here/bramble-engine/tests/fixtures/"
cp -- "$stage/fixtures/build.json" "$here/league/build.json"
rm -rf -- "$stage/previous"
echo "refresh_reference: refreshed 1,000 mixed-bot records, 200 TribeBot records, 100,000 fights, 25 seeds and Rust fixtures"
