# Step 2 measurements

Source the machine's toolchain (`source /opt/bramble/env.sh`). On the shared machine,
point `GODOT` at a wrapper that serializes every process and applies the owner's cap:

```bash
#!/usr/bin/env bash
exec flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G -- godot "$@"
```

Save that outside the repository, make it executable, and export its absolute path
as `GODOT`. The sandbox needs permission to use the host systemd user bus.

```bash
"$GODOT" --headless --import
GODOT="$GODOT" tools/sim/bench.sh --cores 1 --out build/sim/step2 \
  --report build/sim/step2/free-choice.md --seed 1 --timeout 86400 free_choice=400
"$GODOT" --headless -s res://tools/sim/benchmark_run.gd -- \
  seeds=200 first_seed=1 out=build/sim/step2/benchmark
GODOT="$GODOT" ./scripts/check.sh
```

`free_choice` seats eight bots without the normal lobby build deal, named routes,
unit/tribe route bonuses, or measured power priors. All tribe priors are zero.
The existing Hard policy values current bodies, card text, pairs, the shop,
permanent tribe investment, spells and placement. Card hints are retained, so this
measures that policy as well as the cards. Weak tribe results must not be repaired
by adjusting routing. Ordinary games and their bots are unchanged.

The player CSV's `final_tribe` is a strict majority of occupied slots in the last
fight's starting board (`PlayerState.fought_specs`), independent of declared build.
Golden units count as one slot. Eggs occupy slots but have no tribe in the current
library; away Birds and Belly contents add no extra slots. Mixed, tied, neutral and
empty boards are `no_tribe`. Pick rate uses all seats, including games where that
tribe was absent from the normal five-tribe rotation. Mean placement and first
rate use seats bearing that label. The report and `.summary.csv` retain unpicked
tribes, showing missing placement/first observations rather than zero rates.

The benchmark loads the original 72 JSON snapshots and fights all 180 unordered
cross-tribe pairs within the same round and roll. Each seed runs both orientations:
200 seeds produce 72,000 fights, 2,000 per board. `.boards.csv` reports strict wins,
draws and ranks by wins plus half draws, alongside the original guessed rank.
Supplied body stats are totals, including golden/permanent buffs. Reconstructed
standing auras are removed before setup and reapplied by the real combat engine
so they are not counted twice. No recruit phase or heroes are simulated.

`.limitations.json` lists missing auxiliary state per board; `.translated.json`
retains exactly what entered the engine. Missing Ring layouts, away Bird data,
paint identities and unspecified counters cannot be recovered from stat totals.
Read those limitations when interpreting the benchmark as balance evidence.
Raw fights, player rows and transient reports remain in `build/sim/step2/`.

The gate's parity table uses `UnitLibrary.pool_units(GameConfig.full_game().card_set())`
before lobby rotation. Each tribe targets 16 cards at 3/3/3/3/2/2; neutrals are
reported without a target. Default behavior warns. `PARITY_STRICT=1` fails on any
tribe mismatch, including unexpected tribes, once content parity is required.
