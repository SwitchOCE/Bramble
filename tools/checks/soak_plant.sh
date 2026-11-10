#!/usr/bin/env bash
# Proves the soak can fail: plants one fault per check (tools/checks/soak.gd _plant_fault) and
# wants each run red, with that check's message. Usage: tools/checks/soak_plant.sh [games=7]
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1
GAMES="${1:-7}"
# fault|the text its violation must show
PLANTS=(
  "copies|pool copies not conserved"
  "spell_copies|spell copies not conserved"
  "hero_repeat|went to two players"
  "pending|choice left over"
  "hand_items|hand over the limit"
  "armor|armor -1"
  "gold|gold -1"
  "iid|twice"
  "slots|slot lists"
  "discover_repeat|offered .* twice"
  "discover_tier|at tier"
  "log|log places player"
  "no_set|which has no set"
)
failed=0
for entry in "${PLANTS[@]}"; do
  fault="${entry%%|*}"
  want="${entry#*|}"
  out="$(timeout 120 "${GODOT:-godot}" --headless -s res://tools/checks/soak.gd -- "games=$GAMES" "plant=$fault" "synthetic=2" 2>&1)"
  status=$?
  if [ "$status" -ne 0 ] && echo "$out" | grep -E "VIOLATION.*$want" >/dev/null; then
    echo "soak_plant: $fault: caught"
  else
    echo "soak_plant: $fault: NOT CAUGHT (exit $status, wanted '$want')"
    failed=1
  fi
done
[ "$failed" -eq 0 ] && echo "soak_plant: every planted fault went red"
exit "$failed"
