#!/usr/bin/env bash
# Plays the league's final bots (bots/red = red-m2, bots/blue = blue-m2), unchanged, on the
# current engine: 200 games on the normal 1 s clock. Fails on any clock-out, panic, fault or
# refused action. Run after every rules port, beside recheck.sh.
# Usage: tools/league/proof/smoke_final_bots.sh [out-dir]
#   seeds: $LEAGUE_DATA/proof/red-blue-seeds.txt (100 lines, 2 games each); made if missing.
# A few minutes on 8 threads. Long: run it in the background with a time limit.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
data="$(realpath -m "${LEAGUE_DATA:-/home/alex/engine-data/dev-level}")"
threads="${JOBS:-8}"
out="$(realpath -m "${1:-$data/proof/smoke-$(date +%Y%m%d-%H%M%S)}")"
seeds="$data/proof/red-blue-seeds.txt"
export PATH="$HOME/.cargo/bin:$PATH"
cd "$here"
if [[ ! -f "$seeds" ]]; then
  mkdir -p "$(dirname "$seeds")"
  python3 -c 'import random; r = random.Random(20261119); print("\n".join(str(r.randrange(1, 2**31)) for _ in range(100)))' > "$seeds"
fi
CARGO_BUILD_JOBS="$threads" cargo build --offline --locked --release -p league
rm -rf -- "$out"
target/release/league match --red red --blue blue --games 200 --seeds "$seeds" \
  --clock-ms 1000 --threads "$threads" --out "$out"
python3 - "$out/games.jsonl" <<'PY'
import json, sys
games = [json.loads(line) for line in open(sys.argv[1])]
seats = [seat for game in games for seat in game["seats"]]
bad = {
    "clock-outs": sum(seat["clock_out"] is not None for seat in seats),
    "panics": sum(seat["panic"] is not None for seat in seats),
    "faults": sum(seat["fault"] is not None for seat in seats),
    "refused actions": sum(seat["refused"] for seat in seats),
}
print(f"smoke: {len(games)} games, " + ", ".join(f"{v} {k}" for k, v in bad.items()))
sys.exit(1 if len(games) != 200 or any(bad.values()) else 0)
PY
