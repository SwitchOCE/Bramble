# Step 2 measurements

These commands are for the owner's local machine, not a portable/cloud reproduction recipe.
The `/opt` toolchain, systemd user bus, release-template path and example output paths
are machine-specific. Source the machine's toolchain (`source /opt/bramble/env.sh`). On the shared machine,
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
  --report build/sim/step2/free-choice.md --seed 1 --timeout 86400 free_choice=400 free_choice_plain=400
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

`free_choice_plain` uses the same free-choice Hard policy but bypasses buy/keep hints,
including `text_value`'s keep hint. Generic text value falls back to 1.5 × tier; printed
stats and live mechanic evaluation remain. Other hints (flight, larder, spells,
heroes and placement) remain, so
this is a controlled removal of buy/keep hints, not a policy-independent strength estimate.

The player CSV's `final_tribe` is a strict majority of occupied slots in the last
fight's starting board (`PlayerState.fought_specs`), independent of declared build.
Golden units count as one slot. All `source.kind=token` units, including Eggs, are
excluded from numerator and denominator. Neutral non-token units still count;
away Birds and Belly contents add no slots. `plurality_tribe` names the largest tribe
(or all tied leaders joined by `+`); `plurality_share` divides by eligible slots.
Mixed, tied, neutral, tokens-only and empty boards are `no_tribe`; `no_tribe_reason`
and the summary breakdown distinguish those groups by reason and plurality.
`lobby_tribes` lists the offered rotation joined by `+` (empty means all tribes).
Pick rate uses all seats; lobby pick rate uses seats where the tribe was offered.
Mean placement and first rate use seats bearing that majority label. Summary CSVs
retain unpicked tribes with missing outcomes. Every main-table metric includes a
95% t interval from lobby-clustered ratio residuals (delta method), so seats in one
lobby are not treated as independent. These are exploratory intervals, without
multiple-comparison correction. Boundary rates use a conservative Wilson bound
with one trial per informative lobby. Fewer than two informative lobbies have no
interval; sparse results need more lobbies.

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
tribe mismatch, including unexpected tribes, once content parity is required. `check.sh` has a TODO to make strict the default
when pass 2 merges.

For long runs, the existing `build_release_bench.py` can pack the same scripts into
an official release template. Use the guarded editor wrapper when building the
pack, and guard the generated `bench-godot` shim with the same flock/systemd scope
when running it. **Use absolute output paths:** release templates change their
working directory to the executable directory. For this baseline, seed 1's player,
round and card CSVs matched the editor byte for byte before all 400 lobbies were
run in release. The evidence provenance records the pack and source hashes.

```bash
python3 tools/sim/build_release_bench.py \
  /opt/godot-data/godot/export_templates/4.7.2.stable/linux_release.x86_64 \
  build/sim/step2/release --godot "$GODOT"
# Set GODOT to a guarded wrapper around the generated release/bench-godot shim.
GODOT="$GODOT" tools/sim/bench.sh --cores 1 --out "$PWD/build/sim/step2" \
  --report "$PWD/build/sim/step2/free-choice.md" --seed 1 --timeout 86400 free_choice=400 free_choice_plain=400
```
