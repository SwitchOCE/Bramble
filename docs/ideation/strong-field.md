# Strong-field mode

**Status: development experiment, excluded from player exports.** The `strong_field`
feature flag is off in every current export preset. The plain **Bots / Strong field**
setting is present only when that flag is enabled; saved field preferences fall back
to Bots when it is off. A player export also rejects a command-line field launch.
No shipped library is committed now. **V3 step 5** recaptures it from the full
pass 3 pool, using top-four source trajectories; the checkpoint 1 build then turns
the feature on. This follow-up does not enable it or recapture that library.

The normal bot lobby remains the default. Field mode keeps seven real rival seats,
Health, Armor, Last Stand, normal matchmaking, rival-versus-rival fights, damage,
eliminations and placements. Its recruit boards come from captured trajectories;
the human recruits normally. No card or combat rule was changed for this mode.

## Information and persistence

Scouting follows the ordinary information policy: **the previous-round board, with
nothing in round one**. The previous slots and nests are shown; current public hero
effects and tier remain public. Private Egg bird stats/timers, Larder and ammo are
not disclosed. The 8 November DECISIONS call keeps the real-board reveal off.
The field board used for combat is still the exact current-round capture.

Rival trajectories are dealt without replacement. The ghost receives its own
trajectory, distinct from every living rival, and also advances through the field.
A switch cannot take a trajectory currently held by another living rival or by
the ghost. Distinct trajectories can coincidentally contain the same board; the
mode guarantees independent trajectories, not eight different opening boards.

`field_strength = "top4"` is the default: candidates finished first through fourth
in their source lobby. `"all"` permits every recorded finish. The full source
`lobby_tribes` set from the players CSV must fit this lobby, both at the deal and
when switching. Filtering only a line's primary tribe would admit illegal splash
tribes from another source lobby. Tribe-group dealing still spreads commitments.

When a trajectory ends, choose a same-line candidate reaching the round with the
closest captured Attack + Health, including next-combat bonuses and held bodies.
If that whole line is extinct, prefer its tribe, then the compatible eligible field.
If the entire available field ends, use its latest available source round. All
choices respect the strength, source-lobby and active-trajectory exclusions.
The seat, Health, Armor and Last Stand usage persist; the captured hero follows
the replacement. Nearest available size does not guarantee a small power change.

Rivals cannot adapt their purchases, greed, answers or layout to this live game.
They do not recruit against its actual economy or shared pool: their boards and
combat resources follow the source seat instead. Captured line policies remain
scripts over Hard, rather than elite human play. Selecting successful source seats
improves this measured baseline, but does not establish strength against skilled
people or the future pool. Switching can replace both the whole board and hero.

Pool reservation is retained. Visible units, held units and nesting birds reserve
copies before the human's next shop; golden units reserve three. Reservations are
released between rounds, including eliminated seats. Hidden hands and shops are
not reserved; created/transformed origin and independent-source over-subscription
remain approximations. Only available copies are reserved, and ghosts reserve none.

Playtest reports keep `field_source`, `field_switches` and `field_rounds` in the game
log, with each source line, trajectory and round. The unread standings copies have
been removed. The main screen adds no field-mode reminders or disclosures. A Field
ghost is named; its Who card contains the actual power text, not a generic lesson.

## Library and content changes

The generator `tools/sim/field_library.py` accepts all-line fight JSONL plus its
players CSV. Version 2 stores complete per-side combat inputs: units and stats,
keywords/grants, held bodies, layout, slot effects, hero effects, tier and fight
rules, along with hero identity, source placement and source lobby tribes.
Configuration, source revision, input hashes and sampling provenance are recorded.
Sampling is stratified by line, source rotation and strength, retaining whole
trajectories and enough winners to deal eight distinct seats where captures permit.
`--strength top4` exports winners only; `--strength all` retains both groups for the
strength dial and comparisons. Default output is deterministic standard gzip JSON
(`.json.gz`), with no 10 MB cap. Plain JSON remains supported for diagnostics.

The gameplay manifest excludes display names, text, details, overlay wording,
provenance notes and portrait paths. Unit keywords, mechanics, numerical parameters
and operational counter/slot-effect `name` IDs remain gameplay. Missing directories,
unreadable or invalid JSON, empty content folders, wrong manifests and incompatible
configurations return explicit errors; validation cannot silently succeed in an
export missing `content/levers`. Every export includes the lever JSON files.

**Tests do not depend on a shipped library or a frozen current-content manifest.**
`tests/core/field_test_data.gd` builds a small synthetic fixture from current card
and hero definitions, all current lobby rotations, and the current manifest once
per test process. Its output is ignored under `build/`. Historical combat replay
uses the frozen `9af89c2` content snapshot. The normal regression is now pinned to
merged revision `0946909`, with a separate small frozen content snapshot, so
subsequent content edits cannot invalidate its expected outcomes. Both sets of old
`9af89c2` files remain intact. These fixtures test plumbing and code parity; they
make no strength claim.

**Do not recapture after intermediate content merges.** At v3 step 5, after the
full pass 3 pool and adopted levers are committed, the person landing the final
pool runs the one-command recapture:

```sh
tools/sim/recapture_field.sh --strength top4 --config path/to/adopted-levers.json
```

Omit `--config` for the committed defaults. The script sources `/opt/bramble/env.sh`,
requires committed gameplay source, runs import and capture sequentially under the
shared lock and 3G cap, and emits `content/fields/baseline.json.gz`. Defaults are 120
lobbies, seeds 20262000–20262119, per-stratum limit 64, sample seed 91407. Before
shipping, enable the `strong_field` custom feature, include the final library in the
export presets, and change the export smoke from exclusion checks to positive
field-game launch checks. Until then every player preset excludes `content/fields/*`.

For development, an explicit source-tree UI launch with `--field-library <path>`
opts into the experiment. With the feature enabled, the same plain setting works
through touch input and requires no command line; `CorePort` resets its config on
each new game so a later Bots game cannot inherit field rules. Invalid starts show
a start-game error rather than failing silently. Tests cover this actual settings →
App → CorePort path, saved preferences, touch target sizes and feature-off behavior.

`tools/play/play.sh new --seed 71 --field-library <path> --field-strength top4`
starts a development command game. `--field-strength all` selects all recorded seats.
The save pins the path, SHA-256 and strength choice; changed/missing libraries are
rejected before replay. Every Godot invocation must still use the shared lock,
`systemd-run --user --scope -p MemoryMax=3G`, a timeout, and the sourced environment.

## Merged-tree load follow-up

Normal regression fingerprints now cover the normal mode at merged revision
`0946909`, including the current `pass3_content` / `pass3_loop_guards` config keys.
All four complete games (seeds 3, 17, 71, 20261109) were captured directly from
that tree. A frozen merged-content snapshot keeps ordinary content edits from
breaking this code regression; the historical replay still uses frozen `9af89c2`.

UI and tools/play starts now call `FieldLibrary.prepare`, retain its validated
snapshot and pass it into `GameSession.create`. Direct callers without a prepared
snapshot still load normally. Configuration compatibility and deal eligibility
are checked at game creation. A regression removes the file after preparation and
checks that the session retains the same object; it also rejects a changed config.
There is no process-wide cache that could silently reuse an old library.

The merge introduced gameplay defaults in `content/pass3/rates.json`. The runtime
manifest and generator now hash that folder, the merged frozen fixture saves and
restores its defaults cache, and every export includes the rate file. Export smoke
checks its presence. No authored rates or combat rules were changed.

The generator and one-command recapture default to `.json.gz`. The loader reports
missing/unreadable files, invalid gzip headers, decompression failure, JSON parse
errors and validation failures explicitly. It frees the compressed and inflated
byte buffers before parsing, but retains the expanded trajectory graph for play.

Measured on the **same 960 trajectories** from the earlier 48 MB baseline library:

| Load path | Library bytes | Load/adopt | Session creation | Total | Peak process RSS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before: JSON, two parses/validations | 50,349,022 | 2.609 s | 1.942 s | 4.551 s | 1,150.8 MiB |
| After: gzip, one retained snapshot | 2,078,965 | 2.291 s | 0.008 s | 2.299 s | 1,147.8 MiB |

Startup time is about halved and disk size falls about 96%. **Peak memory is
essentially unchanged:** the expanded JSON/Variant graph still dominates. This
is a measurement, with no new performance bar. Each row is one fresh local process
with a warm OS file cache, no fights, the shared lock and 3G cap. Timings begin
after base content loading; `/usr/bin/time -v` measures the whole process peak.

The old library's manifest no longer matches merged content. The benchmark copy
under `build/strong-field/load-review/` refreshes only that manifest and missing
config defaults; all trajectory data compares equal to the original. Godot JSON
serialization changes its byte count to 50.35 MB. **This is a profiling-only copy,
not a recapture or a library for play.** Neither large file is committed.
[Raw timings/RSS and provenance](evidence/strong-field/load-followup/load-report.json),
[before log](evidence/strong-field/load-followup/before.log),
[before RSS](evidence/strong-field/load-followup/before.time),
[after log](evidence/strong-field/load-followup/after-final.log), and
[after RSS](evidence/strong-field/load-followup/after-final.time).

Use `tools/sim/profile_field_load.gd -- library=<path> mode=legacy|prepared` under
the shared lock and `/usr/bin/time -v` to repeat a load-only measurement. The
legacy option deliberately reproduces the former discarded-snapshot path.

The small presentation fixes are implemented: Field ghost keeps its combat title;
combat plaques retain the Rival number while shortening the hero name; the scout
heading and mini-shop clear the Last Stand strip; Settings reserves no area for
the cut tray when the feature is off. Tests cover the phone and desktop shapes.
No on-screen explanations were added.

## Strength and switch measurement

These are **pre-merge baseline measurements**, not a new strength sweep of the
merged pass 3 pool. That library is deferred to v3 step 5.

The predeclared comparison uses 40 games per arm, evaluation seeds **1000–1039**:
normal lobby, field `all`, and field `top4`, with Hard in the human seat. The field
sample is a separate **120 all-line lobbies**, source seeds **20262000–20262119**,
captured from original harness revision `9af89c2`, without levers or content edits.
It contains 960 real trajectories, with 64–104 top-four candidates per lobby rotation.
The 48 MB compact library and raw capture remain only under `build/`; neither is
committed or shipped. Its source seeds are disjoint from the evaluation seeds.

The normal arm ran original `9af89c2` code in an isolated archive under this
worktree's ignored build directory. Its pre-merge regression verified normal mode
against that revision. The current regression instead pins merged tree `0946909`,
as described above. Every comparison game
runs to all eight placements; switch counts include the independent ghost, with
rivals and ghost also reported separately. `all` versus `top4` holds the new scouting,
source-lobby filtering and uniqueness rules fixed, isolating the strength filter's
persistence effect rather than mixing several code changes.

All **120 evaluation games completed**, 40 in each arm, on review implementation
`04e87b3`. Higher mean placement means a harder opponent field for Hard.

| Opponents | Mean Hard place (95% interval) | Rival switches/game | Ghost switches/game | Total switches/game |
| --- | --- | ---: | ---: | ---: |
| Normal bot lobby | 3.95 [3.20, 4.70] | 0 | 0 | 0 |
| Field, all source finishes | 3.60 [3.04, 4.16] | 2.60 | 1.50 | 4.10 |
| Field, top-four source finishes | 5.10 [4.34, 5.86] | 1.00 | 0.725 | 1.725 |

Top-four minus normal is **+1.15 places**, approximate 95% interval **+0.08 to
+2.22**. Filtering to top four reduces total switches by about **58%**, and rival
switches by about **62%**, compared with all finishes under the same current rules.
These full-lobby counts include play after the human dies. Counts before human
elimination are retained separately in the raw results.

For size versus the existing scale reference, the captured **round-12 active
combat-start boards** have these totals (Attack + Health, excluding held bodies):

| Source seats reaching round 12 | Boards | Mean board stats | Median board stats |
| --- | ---: | ---: | ---: |
| All finishes | 800 | 111.2 | 111 |
| Top-four finishes | 480 | 114.4 | 115 |
| September 2025 reference in `fundamentals.md` | — | 759 | — |

This counts each source seat once, rather than weighting by the evaluation games'
rival survival or switches. It describes the available field boards, not a new
size requirement. The baseline field remains far smaller than the scale reference;
choosing stronger seats does not repair the underlying pool's scale. Following
owner note 09i, these are measurements, with no added evaluation bars.

[Machine-readable report](evidence/strong-field/strength-report.json) includes the
library SHA-256, size population and interval method. Raw seed results:
[normal](evidence/strong-field/comparison-normal-40.jsonl),
[all](evidence/strong-field/comparison-all-40.jsonl), and
[top4](evidence/strong-field/comparison-top4-40.jsonl).
Mean-place intervals use independent-game standard errors and Student t(39).
Difference intervals use an unpaired approximation with the conservative t(39)
critical value; identical numeric seeds do not promise matched shop RNG. They are
conditional on this fixed captured pool, not estimates of uncertainty across
future content configurations.

Re-run an arm after generating an all-seat development library, in restartable
10-game shards. Use a different output path for each shard and concatenate them in
seed order for the report. Each Godot invocation holds the shared lock:

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout 300 godot --headless -s res://tools/sim/strong_field_compare.gd -- \
  arm=top4 first_seed=1000 games=10 \
  library=res://build/strong-field/measurement-library.json \
  out=build/strong-field/top4-1000.jsonl
```

Repeat with first seeds 1010, 1020 and 1030. Each completed game flushes a JSONL row;
progress is also printed to stdout. Keep long runs in a background job with a log.

Use `arm=all` or `arm=normal` for the other arms. The reporting command is
`python3 tools/sim/report_strong_field.py <results-dir> --library <library> --out <report.json>`.

## Verification

Targeted tests cover same-seed complete field games, real eliminations, exact
historical re-fight, 200 distinct eight-seat deals, independent ghosts and switch
exclusion, previous-round scouting, private Egg data, source tribes/top-four filters,
manifest failures, save pinning, the strength dial, and the real UI choice path.
Normal-mode fingerprints include every fight input/result/event, standings and game
log for seeds 3, 17, 71 and 20261109, captured directly on merged revision `0946909`; the old `9af89c2`
normal fixture remains as historical data and is no longer the regression target.

The export smoke builds real Linux, Windows and available Android targets. It checks
that every pack includes levers and excludes the deferred library. The exported
Linux binary boots the main scene. An editor process loads the exported PCK and
exercises its packed settings/CorePort code: the field option is absent and a saved
field preference starts Bots. This probe is distinct from a player-template boot:
the pinned stock templates disable `--script` overrides, so an external script
cannot run inside them ([Godot command-line reference](https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html)). The source tests exercise the enabled UI choice path.

The pre-merge `6278c4a` shared-lock, 3G-capped **full gate passed: 1,726 Godot
tests and 69 Python tests**, with all format, lint, content, import, compile and
parity checks.
[Gate log](evidence/strong-field/review-gate.log) and
[verification/provenance manifest](evidence/strong-field/review-verification.json).
At that pre-merge revision, gameplay content, `combat.gd` and the existing harness
`bench.gd` were unchanged against `9af89c2`. The owner has since merged wave 1 and
the harness at `0946909`. No large library is tracked in Git.

## Current review smoke

On `6278c4a`, seed **71**, `field_strength=top4`, using the measured baseline
library: a fresh **tools/play game reached `game_over` in round 10, eighth place**.
The driver took 34 legal choose/buy/play/tier/end actions after game creation. It
filled the board, tiered and ended turns through `tools/play/play.sh`; it did not
alter boards or recruit through a bot shortcut. This is a launch/save/replay smoke,
not another Hard strength measurement.

[Action log](evidence/strong-field/review-smoke.log),
[pinned save](evidence/strong-field/review-smoke.game.json), and
[complete result and game log](evidence/strong-field/review-smoke.result.json).
The save refers to the uncommitted measurement library, whose hash is in the
comparison report; retain or regenerate that exact library to replay it.

A small progression table from that log (all rivals are also in the
[CSV](evidence/strong-field/review-smoke-board-sizes.csv)):

| Round | Rival 1 active Attack + Health | Switch |
| --- | ---: | --- |
| 1 | 3 | No |
| 2 | 7 | No |
| 3 | 15 | No |
| 4 | 26 | No |
| 5 | 34 | No |
| 6 | 51 | No |
| 7 | 59 | No |
| 8 | 91 | No |
| 9 | 103 | No |
| 10 | 115 | No |

There are **no trajectory switches for any rival or the ghost in this smoke**,
so there is no switch-associated jump or shrink to assess here. The historical
seed-72 example below records an actual switch and its size jump. Current forced
switch tests cover selection, exclusions and persistent Health; the 40-game table
above measures how often switches occur under the new strength filter.

The corrected [export smoke](evidence/strong-field/review-export.log) passed Linux,
Windows and Android APK exports. All packs include levers and exclude field
libraries. The [packed UI probe](evidence/strong-field/review-packed-ui.log) passed
manifest validation and feature-off preference fallback. The **actual Windows
executable booted under Wine and exited 0** after reaching the main scene:
[Windows boot log](evidence/strong-field/review-windows-boot.log). This is a headless
runtime smoke, not a Windows screenshot or a field-game launch in a player build.
The initial APK attempt hit a temporary-file disk quota; the successful run used
worktree-local temporary/cache directories. The first unsupported template-script
probe was replaced with the explicit packed-editor probe described above.

## Readings

The owner asks us to “rely far more on empirical simulation data than on
observational bot play and self-play data” (9d); observational bot play and self-play
are a common-sense check. This is not a statement that human play against bots is
the main evaluation method. Owner note 9e puts teaching in the tutorial and assumes
players already know the rules on the main screen. Step 2 of `plan-scale-rework.md`
provides the persistent-seat/Health/placement purpose; DECISIONS keeps reveal off.

## Historical v1 evidence

The following seed-71 smoke and seed-72 screenshots are historical evidence from
`9cfe2ec` and the two UI-proof commits. They precede this review's changes: they
include the now-cut scouting reveal and ghost explanation, use the removed v1
library, and are **not** evidence of the current feature-gated player export.
Restore the matching old revision to replay those old pinned saves. The original
small board-size table is retained so the earlier report remains auditable.

## Smoke-game rival progression

These are **logged board sizes**, the sum of Attack + Health across the active
units in each rival's `game_log.players[].rounds[].board`, taken directly from the
[seed-71 smoke result](evidence/strong-field-smoke.result.json). They include the
captured combat-start aura stats shown by the log; they exclude off-board reserves.
The trajectory selector's size metric additionally includes held bodies and uses
the pre-aura fight input, so this table is a visible-board continuity check rather
than a reconstruction of that selector's score. The same values are available as
[CSV](evidence/strong-field/smoke-board-sizes.csv). A dash means the rival was already
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

| Screen | 1688×780 | 1920×1080 |
| --- | --- | --- |
| Round 8: seven rival lobby plaques | [PNG](evidence/strong-field/lobby_1688x780.png) | [PNG](evidence/strong-field/lobby_1920x1080.png) |
| Round 8: scouting Rival 4 | [PNG](evidence/strong-field/scout_1688x780.png) | [PNG](evidence/strong-field/scout_1920x1080.png) |
| Round 8: fighting Rival 4 | [PNG](evidence/strong-field/rival-fight_1688x780.png) | [PNG](evidence/strong-field/rival-fight_1920x1080.png) |
| Round 14: scouting the Field ghost and its power | [PNG](evidence/strong-field/ghost-scout_1688x780.png) | [PNG](evidence/strong-field/ghost-scout_1920x1080.png) |
| Round 14: natural Field ghost fight | [PNG](evidence/strong-field/ghost-fight_1688x780.png) | [PNG](evidence/strong-field/ghost-fight_1920x1080.png) |

[Phone capture log](evidence/strong-field/ui-1688x780.log) and
[phone states, fight inputs and layout observations](evidence/strong-field/ui-1688x780.json).
[Desktop capture log](evidence/strong-field/ui-1920x1080.log) and
[desktop states, fight inputs and layout observations](evidence/strong-field/ui-1920x1080.json).
Native PNG dimensions were retained; all ten images have the exact requested
sizes. Both runs report zero missed clicks and zero automated layout observations.
Their complete game logs and human fight inputs match **exactly across resolutions**.
Every screenshot was visually inspected; the automated layout check does not catch
the semantic and label-overlap issues listed below.
[Verification manifest](evidence/strong-field/verification.json) records native
dimensions, image/driver hashes, cross-resolution equality and unchanged production
`src`, `tools` and `content` Git trees. The full locked quality gate was rerun
after adding the capture driver: every step passed, including 1,710 Godot tests
and 65 Python tests; [evidence gate log](evidence/strong-field/gate.log).

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
round 13 (selector sizes 127 and 128, against the previous 69). The selected 127
is the closer of those two candidates. This observation is from the UI game, not
the original smoke, and no
behaviour was changed to smooth it. The source library and per-round provenance
in the UI report make the comparison repeatable.

Historical display issues in the old images (the load follow-up above fixes the
ghost title, rival prefix and scout overlap in current code):

- The scouting heading still says **“last fight”** for both a rival and the Field
  ghost, although it is displaying the **current round's** field board. See the
  scout screenshots; the combat-boundary equality checks confirm the data.
- The natural Field ghost is labelled **“A ghost”** in combat rather than
  **“Field ghost”**, while its recruit scouting card has the correct Field ghost
  identity and power. `App.side_names` only preserves a passed ghost name when it
  begins with `Ghost`; `Field ghost` falls through to the ordinary label.
- At both resolutions the combat plaque's name fitting drops the rival seat
  prefix (`· Brother Bracken` on phone; `Bracken` on desktop), while the vertical
  board tag retains `Rival 4`. This makes the short fight plaque less useful for
  distinguishing rivals sharing a hero. The seven lobby plaques retain their
  seat numbers.
- In the round-14 ghost scouting view, the scouting heading overlaps the
  `Last Stand: ready` strip beneath Rival 4 at both sizes. The screenshot records
  the overlap even though the existing automated layout checker reports none.

The old images require the original revision and v1 library. To use the driver
on current code, supply a genuine current-content capture at the example path
`build/strong-field/development.json.gz`; the profiling-only copy is unsuitable.
Run one Godot process at a time:

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout 180 godot --headless -s res://tests/ui/shots/strong_field.gd -- \
  --probe --seed 71 --field-library res://build/strong-field/development.json.gz
export LP_NUM_THREADS=1
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout 240 xvfb-run -a -s '-screen 0 2560x1440x24' godot \
  --rendering-driver opengl3 --audio-driver Dummy \
  -s res://tests/ui/shots/strong_field.gd -- --size 1688x780 --seed 72 \
  --field-library res://build/strong-field/development.json.gz \
  --out res://docs/ideation/evidence/strong-field
```

Use `--size 1920x1080` for the other requested resolution. The software renderer's
V-Sync warning is expected under Xvfb; engine/script errors are not ignored.
