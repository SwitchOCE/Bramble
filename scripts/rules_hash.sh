#!/usr/bin/env bash
# The rules hash: what RecordBuild.identity() gives for the rules files (src/core, src/content,
# src/game/game_content.gd, src/game/data/stand_in_units.json). Ghost fields, records and
# builds are tied to it, so the quality gate fails when it moves without the expected hash
# in tools/checks/rules_hash.txt moving with it.
#   ./scripts/rules_hash.sh            print the current hash
#   ./scripts/rules_hash.sh --check    compare it with tools/checks/rules_hash.txt
#   ./scripts/rules_hash.sh --update   write it there (a rules change on purpose; commit the file with it)
# Needs an imported project (godot --headless --import). GODOT=/path/to/godot as in check.sh.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
EXPECTED_FILE=tools/checks/rules_hash.txt
RULES_PATHS=(src/core src/content src/game/game_content.gd src/game/data/stand_in_units.json)

current() {
  local out hash
  out="$(timeout 300 "${GODOT:-godot}" --headless -s res://tools/checks/ghost_field_rules.gd 2>&1)"
  hash="$(sed -n 's/^ghost field rules: \([0-9a-f]\{64\}\)$/\1/p' <<<"$out")"
  if [ -z "$hash" ]; then
    echo "rules_hash: could not read the rules hash from Godot:" >&2
    tail -n 10 <<<"$out" >&2
    return 1
  fi
  echo "$hash"
}

case "${1:-}" in
  "")
    current
    ;;
  --update)
    hash="$(current)" || exit 1
    echo "$hash" >"$EXPECTED_FILE"
    echo "rules_hash: $EXPECTED_FILE now holds $hash; commit it with the rules change"
    ;;
  --check)
    hash="$(current)" || exit 1
    expected=""
    [ -f "$EXPECTED_FILE" ] && expected="$(tr -d '[:space:]' <"$EXPECTED_FILE")"
    if [ "$hash" = "$expected" ]; then
      echo "rules_hash: $hash, as expected"
      exit 0
    fi
    echo "rules_hash: the rules hash moved"
    echo "  expected ($EXPECTED_FILE): ${expected:-<missing>}"
    echo "  now:                       $hash"
    since="$(git log -1 --format=%H -- "$EXPECTED_FILE" 2>/dev/null)"
    changed=""
    if [ -n "$since" ]; then
      # Only .gd and .json files count toward the hash (RecordBuild._collect).
      changed="$({ git diff --name-only "$since" -- "${RULES_PATHS[@]}"
        git ls-files --others --exclude-standard -- "${RULES_PATHS[@]}"; } | grep -E '\.(gd|json)$' | sort -u)"
    fi
    if [ -n "$changed" ]; then
      echo "Rules files changed since $EXPECTED_FILE was last set (${since:0:8}), committed or not:"
      while IFS= read -r file; do echo "  $file"; done <<<"$changed"
    elif [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
      echo "This is a shallow clone, so the changed files can't be listed; run this check locally."
    fi
    echo "If this is an accident, undo those changes. If the rules change on purpose, run"
    echo "./scripts/rules_hash.sh --update and commit $EXPECTED_FILE with the change: ghost fields"
    echo "cut at the old hash no longer load, and the league's proof pins need refreshing (tools/league/PORTING.md)."
    echo "A card or keyword change is not finished until it is measured again: the card-step skill"
    echo "(.claude/skills/card-step/SKILL.md) says whom to tell before it merges and what to run after."
    exit 1
    ;;
  *)
    echo "usage: rules_hash.sh [--check | --update]" >&2
    exit 2
    ;;
esac
