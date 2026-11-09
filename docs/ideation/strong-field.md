# Strong-field mode

Implemented on `ideation/strong-field`. The normal lobby remains the default.
Field games replace the seven rival recruit turns with captured seat trajectories,
while retaining normal matchmaking, real fights between every paired seat, damage,
Armor, Last Stand, Health, eliminations and placements. The human recruits normally.

## Library and provenance

`tools/sim/field_library.py` converts `suite=lines capture=on` fight JSONL and its
companion `.players.csv` into compact version-1 JSON. The CSV supplies the actual
seat hero; hero effects alone do not identify a hero. Each line contains whole seat
trajectories, with contiguous rounds starting at one. Each round preserves the
complete board specs (including keywords/grants, held bodies and counters), layout,
slot effects, hero effects, tier and fight rules. Captured combat-start views supply
scouting, including aura-adjusted stats. No fight input is rebuilt from visible stats.

The file records its complete source config, explicit source commit, capture/CSV
SHA-256 hashes, population counts, sample seed and sampling method. Its content
manifest hashes every unit, spell, hero, lever and effect-schema JSON at the source commit. Format and
config schema versions are checked, along with the current content manifest and
runtime gameplay config. Seat-control keys are excluded from config comparisons.
Launchers deliberately adopt the recorded config, including lever settings;
direct `GameSession.create` callers must supply a matching config or receive null.
Changing the capture/config contract requires bumping `CONFIG_VERSION` in both
loader and generator. The file does not bundle a historical combat engine.

Sampling retains one longest trajectory per line, then a seeded uniform sample of
other whole trajectories. It never independently samples rounds. Output above
10 MB is refused; reduce `--per-line` or split the source population. Plain compact
JSON is sufficient for the bundled sample, without a decompressor or import step.
Synthetic planted cards, mixed gameplay configs, non-blind layouts, missing seat
heroes, duplicate boards and incomplete trajectories are rejected.

The bundled baseline is `tests/fixtures/field/baseline.json`: today's
`GameConfig.full_game()` v0.5 damage, default committed line policies, 12 all-line
lobbies, seeds **20261109–20261120**, no levers or content changes, sample seed
91407, up to three trajectories per line. It contains **13 policies and 38
trajectories**, approximately **1.96 MB**, with source rounds extending to 21.
This is a functionality/smoke sample, not a strength or balance measurement.
Only observed policies are exported; this small sample omits `line_hedgerow_tempo`.
Captured on implementation checkpoint **`1537175`**. Its full source commit is recorded in `source.commit`; the matching raw capture and
companion CSV hashes are in the same object. `replay.json` is one original raw
round-eight harness fight for the exact replay regression.

## Rival selection and finite source coverage

A separate seed-derived RNG deals eligible tribe groups without replacement,
refilling when necessary, then chooses a line within each group and a trajectory.
Neutral lines form one group. This spreads rival commitments across the lobby's
available tribes; it does not reproduce the harness's exact two-Hard/three-engine/
two-tempo/one-fast eight-seat weighting. Captured secondary tribes can occur on
rival boards even when that tribe is absent from the human's shop pool.

A rival keeps its seat, Health, Armor, Last Stand usage and opponent history.
It follows its selected trajectory until that trajectory lacks the requested round.
It then selects a same-line trajectory reaching that round with the closest total
captured Attack + Health, including next-combat bonuses and held bodies. Ties use
trajectory ID, so switching is deterministic. The displayed hero follows the replacement trajectory while the visible
Rival N seat label stays fixed; switching never reassigns starting Armor or
restores Health. Heroes may repeat because independent source seats may share one.

A finite capture cannot promise a survivor from every line in every possible
future round. If the entire line has no board for a round, the mode first borrows a
current-round board from the same tribe, then from the wider field. Beyond the
entire library's horizon it uses the latest available field round. These exceptions
are exposed as `field_source_line`/`field_source_round` in standings and recorded
per seat and round in `get_game_log().field_rounds`, together with switches and
source provenance. Regenerate a larger/longer-lived field to reduce these fallbacks.
No units or growth are fabricated and the game's normal round limit is unchanged.

A separate persistent field trajectory supplies ghosts and advances each round.
It carries all captured hero effects, slots, tier and fight rules. It is independent
of which player most recently died; dead boards in the current game never supply
field ghosts. The UI and tools/play name these **Field ghost**, disclose their hero
effects and do not mark an eliminated seat as their owner. Scouting shows this round's current field board, including round one,
rather than the ordinary mode's previous-fight snapshot.

Visible rival board units, held units and nesting birds reserve shared-pool copies
before the human's shop refreshes. Golden units reserve three copies. Reservations
are released and rebuilt each round; dead rivals release theirs. This is an
approximation: hidden hands and rival shops/spells are not reserved, capture data
cannot distinguish bought/transformed/created copies at the fight boundary, and
independent source seats can collectively demand more copies than exist. Only
available copies are reserved; the pool never becomes negative. Ghosts reserve none.

## Generate and launch

Run Godot sequentially under the required lock and memory cap. Capture **clean,
committed** source code, and pass that exact revision to the generator. For example:

```sh
source /opt/bramble/env.sh
mkdir -p build/strong-field
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout 360 godot --headless -s res://tools/sim/bench.gd -- \
  suite=lines games=12 first_seed=20261109 capture=on \
  out=build/strong-field/baseline
python3 tools/sim/field_library.py build/strong-field/baseline.fights.jsonl \
  --source-commit "$(git rev-parse HEAD)" --per-line 3 --seed 91407 \
  --out build/strong-field/library.json
```

For a lever library add `config=path/to/overrides.json` to the capture command.
Multiple capture paths and repeated `--players` paths support shards. Alternative
line tables use the existing `lines=...` bench option; the generator currently reads
tribe metadata from the source commit's default profile table, so keep policy IDs
and their tribes aligned with that table.

The real UI supports a launch flag (choose Play normally once it opens):

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout 3600 godot --path . -- --field-library res://tests/fixtures/field/baseline.json
```

For tools/play, use a Godot wrapper so **every** command obeys the same execution rule:

```sh
cat > /tmp/bramble-field-godot <<'WRAPPER'
#!/usr/bin/env bash
source /opt/bramble/env.sh
exec flock /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G \
  timeout 120 godot "$@"
WRAPPER
chmod +x /tmp/bramble-field-godot
export GODOT=/tmp/bramble-field-godot
tools/play/play.sh new --seed 71 --field-library res://tests/fixtures/field/baseline.json
tools/play/play.sh build/play/game-71.json choose 0
tools/play/play.sh build/play/game-71.json end
tools/play/play.sh build/play/game-71.json log
```

The save stores the library path and SHA-256. Replay refuses a missing or changed
library before executing actions. Keep the file at that path while continuing a
save. Existing ordinary saves retain their existing behavior. In code, set
`opponents = "field"` and `field_library = <path>` on a matching `GameConfig`, or
call `FieldLibrary.configure(config, library, path)` before creating a session.

## Verification and interpretation

Regression tests cover exact harness result and every event hash through a
field-mode `GameSession._fight`, unchanged fight RNG derivation, a complete lobby
with all eight placements and a winner, full same-seed fight-stream equality,
same-line closest-size switching without healing, coverage fallbacks, current-round
field ghosts/scouting, pool release, content/config/version rejection, and pinned
tools/play save replay. Generator tests check preservation, seeded whole-seat
sampling, provenance and invalid input rejection.

The final locked `./scripts/check.sh` gate passed every step on 9 November 2026,
including **1,710 Godot tests** and **65 Python tests**.
[Recorded gate output](evidence/strong-field-gate.log).

The saved tools/play smoke used seed **71** and the bundled baseline. It reached
`game_over` after **56 legal actions**, at round **12**, with the human in **6th**
place (tier 6). Two rivals had already been eliminated. All 91 recorded rival/ghost
round selections used their requested round and original line; this smoke used no
coverage fallback. This is a smoke check, not a playtest rating of strength or fun.

- [Command transcript and tools/play log](evidence/strong-field-smoke.log)
- [Replayable tools/play save](evidence/strong-field-smoke.game.json)
- [Final state, fight and complete game log](evidence/strong-field-smoke.result.json)

Replay the final view or log using the same Godot wrapper:

```sh
tools/play/play.sh docs/ideation/evidence/strong-field-smoke.game.json show --json
tools/play/play.sh docs/ideation/evidence/strong-field-smoke.game.json log
```

Readings used:

- Owner notes `2026-11-09d-simulation-over-bot-play.md`: simulation is the main
  evidence, and a human playing bots is only a common-sense check.
- Owner notes `2026-11-09c-fun-over-balance.md`: progression and fun guide playtests.
- `plan-scale-rework.md`, step 2: persistent seats, Health and eliminations keep
  placement meaningful while opponents come from round fields.
- `tools/sim/HARNESS.md`, `fight_capture.gd`, `bench.gd`, line policies, and the
  live session/ghost path: exact capture boundary and its replay limits.

Rivals cannot scout and react, buy an answer to the human, greed in response to
Health, change placement to counter a board, or incorporate permanent rewards from
this game's fights into later source boards. Their future progression was earned
in another lobby with another shop/pool history. This mode is a persistent
simulation-backed playtest opponent, not a claim of elite adaptive bot play or a
new balance/strength result. No combat rules, cards, or existing harness measurement
code were changed.
