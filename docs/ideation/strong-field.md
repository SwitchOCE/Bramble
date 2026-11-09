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

## Smoke-game rival progression

These are **logged board sizes**, the sum of Attack + Health across the active
units in each rival's `game_log.players[].rounds[].board`, taken directly from the
[seed-71 smoke result](evidence/strong-field-smoke.result.json). They include the
captured combat-start aura stats shown by the log; they exclude off-board reserves.
The trajectory selector's size metric additionally includes held bodies and uses
the pre-aura fight input, so this table is a visible-board continuity check rather
than a reconstruction of that selector's score. A dash means the rival was already
eliminated and has no board logged for that round.

| Round | Rival 1 | Rival 2 | Rival 3 | Rival 4 | Rival 5 | Rival 6 | Rival 7 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 0 | 0 | 0 | 0 | 3 | 5 | 0 |
| 2 | 14 | 4 | 8 | 10 | 8 | 9 | 4 |
| 3 | 18 | 15 | 13 | 15 | 13 | 16 | 15 |
| 4 | 18 | 26 | 19 | 20 | 17 | 26 | 26 |
| 5 | 25 | 29 | 31 | 30 | 22 | 26 | 29 |
| 6 | 31 | 42 | 37 | 38 | 26 | 33 | 42 |
| 7 | 31 | 66 | 37 | 54 | 39 | 47 | 66 |
| 8 | 34 | 78 | 37 | 58 | 49 | 66 | 78 |
| 9 | 87 | 85 | 69 | 86 | 45 | 71 | 85 |
| 10 | — | 93 | 78 | 93 | 72 | 79 | 93 |
| 11 | — | 101 | — | 99 | 97 | 87 | 101 |
| 12 | — | 103 | — | 117 | 97 | 87 | 103 |

**Switch assessment:** `field_switches` is empty in this smoke. Every recorded
rival/ghost selection keeps its original line, trajectory and requested source
round. Consequently there are **no jumps or shrinks at a trajectory switch to
assess here**; this smoke does not establish continuity when switching occurs.
There are changes within trajectories: Rival 1 grows from 34 to 87 at R8→R9
(+53, approximately 156%), and Rival 5 shrinks from 49 to 45 at R8→R9
(−4, approximately 8%). Neither change is caused by a switch. Rivals 2 and 7 use
the same sampled trajectory, so their board-size columns match while their Health
and seat histories remain independent. The existing forced-switch regression tests
cover nearest-size selection; they are separate evidence from this smoke.

## Real-UI evidence (9 November 2026)

Captured against **`9cfe2ec`**, with production behaviour unchanged during review.
The evidence driver `tests/ui/shots/strong_field.gd` boots the actual
`src/main/main.tscn`; its real `CorePort` reads the native `--field-library` launch
flag. It clicks New game, the first offered hero, Scout/Close, End turn, Skip and
Continue through the viewport. As in the existing UI playthrough tool, the menu
callback pins the game seed instead of choosing a random one, and the first-game
guide is skipped using isolated proof settings. Hard automates the human's **legal
recruit actions** through the existing rules; it does not fill or alter boards,
Health, pairings or results. Shopping is automated at the rules boundary, rather
than being proof of each shop gesture. Combat playback is paused on the first
attack for the fight screenshots.

The [reachability probe](evidence/strong-field/reachability.log) found no human
ghost in seed 71, then a **natural round-14 Field ghost pairing in seed 72**.
The screenshots replay seed 72 from the menu. **No test scene or forced ghost was
used.** Rival screenshots are round 8, against Rival 4 / Brother Bracken. The
additional ghost scout screenshot shows the Field ghost identity and hero effects
before its real fight. Every human fight input is recorded, and the capture driver
asserts that the opponent board passed to combat equals that round's field board.

| Screen | 1688×780 |
| --- | --- |
| Round 8: seven rival lobby plaques | [PNG](evidence/strong-field/lobby_1688x780.png) |
| Round 8: scouting Rival 4 | [PNG](evidence/strong-field/scout_1688x780.png) |
| Round 8: fighting Rival 4 | [PNG](evidence/strong-field/rival-fight_1688x780.png) |
| Round 14: scouting the Field ghost and its power | [PNG](evidence/strong-field/ghost-scout_1688x780.png) |
| Round 14: natural Field ghost fight | [PNG](evidence/strong-field/ghost-fight_1688x780.png) |

[Phone capture log](evidence/strong-field/ui-1688x780.log) and
[phone states, fight inputs and layout observations](evidence/strong-field/ui-1688x780.json).
Native PNG dimensions were retained; the evidence is not a fixture rendering.
The phone run reports zero missed clicks and zero automated layout observations.

Unlike the seed-71 smoke, the **seed-72 UI game actually switches** at round 13:
both Rival 1 and the independent ghost move within `line_hunters_engine`, from
trajectory `20261113:0:4` to `20261115:0:2`. Rival 1's continuity around that switch:

| Round | Logged active-board Attack + Health | Selector size (pre-aura, including held bodies) | Switch? |
| --- | ---: | ---: | --- |
| 12 | 93 | 69 | No |
| 13 | 127 | 127 | Yes |
| 14 | 133 | 133 | No |

The switch therefore **jumps**: +34 visible stats (approximately 37%), or +58 in
the selector's size measure (approximately 84%). Nearest available size does not
guarantee a small jump: in this sample, only two same-line trajectories reach
round 13. This observation is from the UI game, not the original smoke, and no
behaviour was changed to smooth it. The source library and per-round provenance
in the UI report make the comparison repeatable.

Observed display issues, left unchanged for the reviewer:

- The scouting heading still says **“last fight”** for both a rival and the Field
  ghost, although it is displaying the **current round's** field board. See the
  scout screenshots; the combat-boundary equality checks confirm the data.
- The natural Field ghost is labelled **“A ghost”** in combat rather than
  **“Field ghost”**, while its recruit scouting card has the correct Field ghost
  identity and power. `App.side_names` only preserves a passed ghost name when it
  begins with `Ghost`; `Field ghost` falls through to the ordinary label.
- At 1688×780 the combat plaque's name fitting drops the rival seat prefix; the
  vertical board tag retains `Rival 4`. This makes the short fight plaque less
  useful for distinguishing rivals sharing a hero. The seven lobby plaques retain
  their seat numbers.

To reproduce the probe and screenshots, run one Godot process at a time:

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout 180 godot --headless -s res://tests/ui/shots/strong_field.gd -- \
  --probe --seed 71 --field-library res://tests/fixtures/field/baseline.json
export LP_NUM_THREADS=1
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout 240 xvfb-run -a -s '-screen 0 2560x1440x24' godot \
  --rendering-driver opengl3 --audio-driver Dummy \
  -s res://tests/ui/shots/strong_field.gd -- --size 1688x780 --seed 72 \
  --field-library res://tests/fixtures/field/baseline.json \
  --out res://docs/ideation/evidence/strong-field
```

Use `--size 1920x1080` for the other requested resolution. The software renderer's
V-Sync warning is expected under Xvfb; engine/script errors are not ignored.

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
