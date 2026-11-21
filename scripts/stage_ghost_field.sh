#!/usr/bin/env bash
# Copy a field into an imported export project and validate the exact files that will ship.
# Usage: stage_ghost_field.sh <imported-project> <field>
set -euo pipefail

project="$(realpath "${1:?expected the project folder}")"
source_field="$(realpath "${2:?expected the ghost field folder}")"
field="$project/ghosts/field"
if [[ ! -d "$source_field/runs" || ! -f "$source_field/index.jsonl" ]]; then
  echo "FAIL ghost field: $source_field needs runs/ and index.jsonl" >&2
  exit 1
fi
mkdir -p "$project/ghosts"
mkdir "$field"
cp -RL -- "$source_field/runs" "$source_field/index.jsonl" "$field/"

rules_output="$(timeout -k 10 60 "${GODOT:-godot}" --headless --path "$project" \
  -s res://tools/checks/ghost_field_rules.gd)"
rules_hash="$(sed -n 's/^ghost field rules: //p' <<<"$rules_output")"
if [[ ! "$rules_hash" =~ ^[a-f0-9]{64}$ ]]; then
  echo "FAIL ghost field: could not read RecordBuild.identity() from $project" >&2
  exit 1
fi

cd "$project/tools/league"
CARGO_TARGET_DIR="$(realpath -m "${CARGO_TARGET_DIR:-target}")"
export CARGO_TARGET_DIR
timeout -k 10 600 cargo build --offline --locked --release -p bramble-ghosts
timeout -k 10 120 "$CARGO_TARGET_DIR/release/bramble-ghosts" verify --store "$field" --rules-hash "$rules_hash"
