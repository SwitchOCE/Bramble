#!/usr/bin/env bash
# Proves the soak turns red: runs it with each planted fault and fails unless every run fails
# with the violation that fault should cause. A soak that can't fail proves nothing.
#   scripts/soak_plant.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
# plant name -> text its violation must contain
declare -A expect=(
  [pool_leak]="copies accounted for"
  [empty_library]="no fight had units on both sides"
  [heap_dup]="events account for"
)
ok=0
for plant in "${!expect[@]}"; do
  out="$(SOAK_LOG="$ROOT/build/check/soak-plant-$plant.log" "$ROOT/scripts/soak.sh" 3 "plant=$plant")"
  status=$?
  if [ "$status" -eq 1 ] && grep -q "VIOLATION.*${expect[$plant]}" <<<"$out"; then
    echo "soak_plant: $plant turned the soak red, as it should"
  else
    echo "soak_plant: FAILED: $plant gave exit $status without '${expect[$plant]}'"
    echo "$out" | tail -5
    ok=1
  fi
done
exit "$ok"
