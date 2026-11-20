#!/usr/bin/env bash
# Compare the engine's store, matchmaker and player runs with the Rust implementation.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/../.." && pwd)"
data="${1:?usage: ghost_core.sh <data folder>}"
godot="${GODOT:-godot}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$here/target}"
export TMPDIR="${TMPDIR:-$data/tmp}"
mkdir -p "$data" "$CARGO_TARGET_DIR" "$TMPDIR"
out="$(mktemp -d "$(realpath "$data")/ghost-core-XXXXXX")"
CARGO_TARGET_DIR="$(realpath "$CARGO_TARGET_DIR")"
TMPDIR="$(realpath "$TMPDIR")"
echo "ghost_core: $out"
export XDG_DATA_HOME="$out/xdg-data"
export XDG_CONFIG_HOME="$out/xdg-config"
export XDG_CACHE_HOME="$out/xdg-cache"

cd "$here"
timeout -k 10 600 cargo build --offline --locked --release -p bramble-ghosts --bin bramble-ghosts --example store_parity
cli="$CARGO_TARGET_DIR/release/bramble-ghosts"
parity="$CARGO_TARGET_DIR/release/examples/store_parity"
mkdir "$out/records"

cd "$repo"
# shellcheck source=scripts/godot_log.sh
. scripts/godot_log.sh
godot_log_init "$out"
timeout -k 10 300 "$godot" --headless --import >"$out/import.log" 2>&1
if godot_log_problems "$out/import.log"; then exit 1; fi
if [[ -n ${2:-} ]]; then
    cp -R -- "$2" "$out/rust-field"
else
    bash "$here/proof/current_async_field.sh" "$out/rust-field"
fi
"$cli" index --store "$out/rust-field"
if ! timeout -k 10 600 "$godot" --headless -s res://tools/league/proof/ghost_core.gd -- "$out" >"$out/godot.log" 2>&1; then
    cat "$out/godot.log" >&2
    exit 1
fi
cat "$out/godot.log"
if godot_log_problems "$out/godot.log"; then exit 1; fi

"$parity" "$out/rust-field" "$out/cases.json" >"$out/rust-picks.json"
"$parity" "$out/gd-field" "$out/cases.json" >"$out/rust-picks-from-gd.json"
cmp "$out/rust-field/index.jsonl" "$out/gd-field/index.jsonl"
diff -r "$out/rust-field/runs" "$out/gd-field/runs"
cmp "$out/rust-picks.json" "$out/rust-picks-from-gd.json"
# Godot's file has no final line break, while the Rust example prints one.
diff -u "$out/rust-picks.json" <(cat "$out/gd-picks.json"; printf '\n')
echo "ghost_core: PASS eight cross-readable runs and byte-identical indexes; four matchmaker cases"

timeout -k 10 600 "$cli" cut --match "$out" --store "$out/rust-players" \
    --ghost-store "$out/rust-field" --made 2026-11-20T12:00:00Z
"$cli" verify --store "$out/gd-players"
cmp "$out/rust-players/index.jsonl" "$out/gd-players/index.jsonl"
diff -r "$out/rust-players/runs" "$out/gd-players/runs"
count="$(find "$out/gd-players/runs" -name '*.json' | wc -l)"
[[ "$count" -ge 20 ]]
echo "ghost_core: PASS $count byte-identical async player runs (including SHA-256 IDs and indexes)"
