# Scope review: strong-field mode (9af89c2..9cfe2ec)

Fresh scope-reviewer, 9 Nov 2026. Saved by the orchestrator from the reviewer's hand-back.

## Summary (scope review of `9af89c2..9cfe2ec`, `ideation/strong-field`)

All three scope inputs were given: the target, the owner's words and the approved plan.

**Counts:** 19 keep, 2 cut, 1 simplify, 4 ask.

**Does it move the original problem?** Partly. The machinery works:
- rivals keep their seats and are really eliminated;
- captured fights replay exactly;
- normal mode is unchanged;
- field games start from both tools/play and the UI flag.

It doesn't yet give the owner a stronger opponent. With a Hard bot in the human seat on the bundled library:

| Opponents | Mean place |
|---|---|
| Field, without the reveal | 4.12 |
| Normal bot lobby | 4.30 |
| Field as shipped | 3.62 |

Lower is better for the human seat. The owner also can't start it from a portal build.

**Cut:**
1. Field scouting shows the exact board the rival will fight this round. That is the reveal DECISIONS kept off on 8 Nov. Show the rival's previous-round board instead.
2. `strong-field.md:175` credits the 9d note with "a human playing bots is only a common-sense check". The owner said that about "observational bot play and self-play data".

**Ask:**
1. Pool reservation for rival boards was the orchestrator's proposal. Keep it? I lean keep.
2. Rivals field tribes that aren't in the lobby: 3 of 7 rivals in the smoke game had Oozes in a lobby without Oozes. Filter them using `lobby_tribes` from the players CSV?
3. Any edit to a content JSON file, text included, breaks every field test and the bundled library until someone recaptures. Who recaptures at each content merge (wave 1, Track B)?
4. The new standings `field_*` keys and the game-log keys `field_source`, `field_switches` and `field_rounds`: nothing reads them. Who will?

**Gaps to fix:**
- The ghost copies Rival 1's trajectory in 200 of 200 deals.
- 19% of games seat two rivals on the same trajectory.
- There is no way to launch a field game from a portal build, and exported builds skip validation silently.

**Clear to merge after the harness?** No. Fix the 2 cuts and those 3 gaps first.

---

## Full output

### Probes I ran

**Setup.** Every Godot run used `flock /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G timeout 900` (1500 for the strength run), in temp copies made with `git archive`. The copies were at `/home/alex/.cache/scope-review-sf.K07q`, because the scratchpad volume hit its quota; I deleted them afterwards. One of my own probes hung after a compile error. I killed it by PID after checking its cwd was my temp copy.

1. **Normal mode is unchanged.**
   - Method: four seeds (3, 17, 71, 20261109), a Hard human in the `BotLobby` lobby, base against head.
   - Result: fight inputs and results, standings and game logs are byte-identical.
   - The raw fight-capture hashes do differ, but only because every capture embeds the full config, which now has two more keys.
2. **Exact re-fight.**
   - Method: a mutant that drops a rival's `hero_effects` inside `FieldRivals.side`.
   - Result: `test_captured_fight_matches_the_harness_at_the_field_game_boundary` fails on "every result and event matches" and on `hero_effects`.
   - My two earlier mutants failed to compile under strict typing, so I don't count them.
3. **Tests.** The three `test_field_*` GUT scripts pass 16/16; the generator's Python tests pass 8/8.
4. **Determinism.** 40 field games came out identical across two separate runs.
5. **Dealing, 200 seeds.**
   - 38 games seat two rivals on the same trajectory.
   - The ghost's trajectory is Rival 1's in all 200.
   - 17% of rival seats are `hard` or `line_fast`.
6. **40 full field games.**
   - 138 trajectory switches, all in rounds 11–19.
   - 49 of 4,647 seat-rounds (1%) borrowed a board from another line; none ran past the library's last round.
   - In 96 of 142 ghost rounds, the ghost's board equalled a living rival's board.
   - At a switch, a rival's board size moves by −21% to +34% in one round. Its own normal growth is a few points.
7. **Strength.** A Hard bot in the human seat, seeds 1000–1039:
   - field as shipped: mean place 3.62, 9 wins;
   - field with previous-round scouting: 4.12, 6 wins;
   - normal lobby: 4.30, 4 wins in 20 games (seeds 1000–1019).
   - The paired effect of the reveal is −0.5 places (95% CI about −1.2 to +0.2). That doesn't settle it on its own; cut 1 rests on the logged rule, not on this number.
8. **UI flag.** `CorePort.setup()` then `new_game(5)`, with `-- --field-library res://tests/fixtures/field/baseline.json`, starts a session in field mode.
9. **Export simulation.**
   - Method: remove `content/levers`, which the export filters omit, then call `FieldLibrary.read`.
   - Result: it logs "Cannot call method 'get_files' on a null value" and returns `error=''`, so every check is silently skipped.
10. **Committed evidence, read in Python.**
    - In the smoke game, Rivals 2 and 7 replay the same trajectory (`20261113:0:5`).
    - The ghost replays Rival 1's trajectory (`20261110:0:7`), and keeps playing it after Rival 1 is out in round 9.

**Not run:**
- the full `check.sh` (the worker's recorded log passes);
- a real export or APK;
- rendered-UI screenshots;
- my own tools/play CLI run (I relied on the committed smoke log and `test_field_launch.gd`);
- a larger library.

**Files I left behind.** I extracted `smoke.json` and `baseline.json` from 9cfe2ec into `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/`. The scratchpad holds many other sessions' files. If a `baseline.json` was already there, I overwrote it.

### Inventory (pr-report)

Size: 26 files, +1,989 −23. Items per section: schema/data 7, features 10, config 3, interfaces 4, internal machinery 7, all others 0.

**1. Schema / data**
- **Field library JSON v1.** Written by `tools/sim/field_library.py:179-218`, read by `src/core/field_library.gd:16-31`. Used by `FieldRivals` and `GameSession.create` (`game_session.gd:72-81`). Reason: plan step 2, "held as persistent rival seats".
- **`tests/fixtures/field/baseline.json`.** 1.96 MB: 13 lines, 38 trajectories, 12 lobbies of today's pool. Used by the tests and the documented launch commands. Reason (worker): "functionality/smoke sample" (`strong-field.md:40`).
- **`tests/fixtures/field/replay.json`.** Used by `test_field_mode.gd:52-90`. Reason (worker): the exact-replay regression.
- **tools/play save keys** `field_library` and `field_library_sha256` (`play_game.gd:89-111`). Used by `from_save`. Reason (worker): replay refuses a missing or changed library.
- **State key `opponents`** (`game_session.gd:220-221`). Read by `recruit_view.gd:141-180` and `play_view.gd:517`.
- **Standings keys** `field_line`, `field_source_line`, `field_source_round` (`game_session.gd:391-394`). Used by nothing yet. Reason (worker doc only).
- **Game-log keys** `opponents`, `field_source`, `field_switches`, `field_rounds` (`game_session.gd:493-499`). Nothing reads them in code. Reason (worker doc only).

**3. Features**
- **Rival seats.** Seven rivals replay captured seat trajectories, with real Health, Armor, Last Stand, eliminations and placements. Recruit rules and carry are skipped for them. `field_rivals.gd:14-108`, `game_session.gd:518-530, 848`. Reason: plan step 2.
- **Seat dealing.** A tribe-group deck, then a random line, then a random trajectory (`field_rivals.gd:15-48`). Reason: none stated for the method; the plan says "with tribes".
- **Switching.** When a trajectory runs out, switch to the same line's trajectory closest in size, without healing (`field_rivals.gd:110-157`). Proposed by the orchestrator.
- **Fallbacks.** Same tribe, then the whole field, then the library's last round (`field_rivals.gd:160-190`). Proposed by the worker.
- **Field ghost.** Copied from seat 1 at setup (`field_rivals.gd:49-51`); its hero is shown via `game_session.gd:355-356`. Reason: plan, "Ghosts become field boards".
- **Scouting.** Shows the board the rival will fight this round (`game_session.gd:729-730`, `field_rivals.gd:228-245`). Reason: none stated.
- **Pool reservation.** Reserves the rivals' visible units, held bodies and nest birds; goldens take 3 copies (`field_rivals.gd:54-57, 104-107, 212-219`). Proposed by the orchestrator ("if simple").
- **Field-ghost and rival naming** in the UI and tools/play (`recruit_view.gd:141-189`, `ui_theme.gd:261-262`, `play_view.gd:517-539`). Proposed by the worker.
- **UI flag `--field-library`** (`core_port.gd:27-55`). Proposed by the orchestrator.
- **tools/play `new --field-library`**, with saves pinned to the library (`play.gd:38-44`, `play_game.gd:34-147`). Proposed by the orchestrator.

**5. Config**
- `opponents`: default "bots"; "field" turns field mode on (`game_config.gd:35`).
- `field_library`: default "" (`game_config.gd:36`).
- Generator options: `--per-line 4`, `--seed 91407`, `--source-commit` required. Constants: `VERSION`, `CONFIG_VERSION`, and a 10 MB cap (`field_library.gd:7-10`, `field_library.py:23-24, 240`).

**6. Public interfaces**
- `FieldLibrary.read`, `configure`, `config_problem`, `canonical`.
- `FieldRivals.side`: static, and now used for every fight in both modes.
- `PlayGame.start(seed, field_path)`.
- The generator CLI.

**7. Internal machinery**
- The loader's checks: version, content manifest, config key and type, structure (`field_library.gd:59-161`).
- Adopting the library's config (`field_library.gd:35-45`).
- The direct-caller config check: `create` returns null on a mismatch (`game_session.gd:72-81`).
- `_fight` refactored through `side` (`game_session.gd:807-821`).
- `_deal_heroes` gives the hero offer to the human only (`game_session.gd:663`).
- Display units built for rival boards (`field_rivals.gd:89-103`).
- The generator's provenance record and its rejections (`field_library.py:108-218`).

**None:** scheduled or background jobs, external dependencies, deletions.

**Unrequested (nothing asked for it, or nothing uses it yet):** the scouting reveal, the fallbacks, content hashing, the 10 MB cap, the tribe-group deal, the standings and log keys. Pool reservation, switching and launch were the orchestrator's proposals.

### Verdict table

| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| 1 | Rival seats: replay, real Health, Armor, Last Stand, eliminations, placements | keep | plan step 2; `field_rivals.gd:54-107`, `game_session.gd:518-530`; `test_field_mode.gd:22-49` reaches a winner with places 1–8 | — |
| 2 | Tribe-group seat dealing | keep | plan "with tribes"; `field_rivals.gd:31-44` | Fix gap G2 |
| 3 | Same-line closest-size switching | keep | supports "persistent"; `test_field_mode.gd:93-134` | See gap G4 |
| 4 | Fallback ladder | keep | without it, a seat has no board once its line dies out; used in 1% of seat-rounds | — |
| 5 | Field ghost | keep | plan "Ghosts become field boards"; `field_rivals.gd:49-51` | Fix gap G1 |
| 6 | Scouting shows this round's exact fight board | **cut** | `field_rivals.gd:228-245` returns `frames[id]`, which is the fight input (`:265-268`). DECISIONS@9af89c2:443 values "show the real enemy board" at "+14 a fight against +4 from the scout"; `:487-489`: "The reveal stays off" | Scout the previous round's frame ({} in round 1); update `test_field_mode.gd:137-153`, `play_view.gd:539` and `strong-field.md:76` |
| 7 | Pool reservation | **ask** | orchestrator's proposal; not in the plan; pools hold 9–15 copies per unit | Orchestrator decides; I lean keep, since a real lobby contends for copies |
| 8 | Out-of-lobby tribes on rival boards | **ask** | `strong-field.md:52`; smoke game: Oozes on Rivals 2, 5 and 7 in a lobby without Oozes; `bench.gd:113` writes `lobby_tribes` to the players CSV the generator already reads | Filter trajectories by source lobby, or accept it and log the call |
| 9 | Library format, structure checks, version check | keep | `test_field_mode.gd:156-178` | — |
| 10 | Content manifest hashes every content JSON | **ask** | `field_library.gd:64-75`; any content edit fails `_session()` in every field test; wave 1 and Track B both edit content | Decide who recaptures at each content merge, or have the tests build their manifest from current content |
| 11 | Config adoption and direct-caller check | keep | the capture's config must match for exact replay; tested at `:168-174` | — |
| 12 | 10 MB cap | **simplify** | none stated (`field_library.gd:10, 22`, `field_library.py:240`); the bundled library is 1.96 MB for 38 trajectories, so the plan's 64-board field from rounds 6–16 runs into it | Drop the cap, or gzip as the harness did for its progress JSON |
| 13 | `opponents` and `field_library` config keys | keep | the only switch into field mode; non-default only through `configure` | — |
| 14 | `_fight` through `FieldRivals.side` | keep | normal mode identical on 4 seeds (my probe 1) | — |
| 15 | Human-only hero offer | keep | without it a rival's offer would become the human's (rivals are removed from `_bots`) | — |
| 16 | Display units for rival boards | keep | feed the standings, game log and UI | — |
| 17 | Standings `field_*` and game-log `field_*` keys | **ask** | nothing reads them (searched `src`, `tools` and `tests`) | Who reads them, and when? I'd keep `field_rounds` for playtest reports and drop the standings copies |
| 18 | UI `--field-library` flag | keep | `main.gd:17-18` calls `setup()`; my probe 8 shows it works | See gap G3 |
| 19 | Field-ghost and rival naming | keep | `test_field_mode.gd:257-278` | — |
| 20 | tools/play flag and pinned saves | keep | each tools/play call replays the save; `test_field_launch.gd` | — |
| 21 | Generator, provenance and rejections | keep | 8 Python tests; planted-card captures exist (harness test 3) | — |
| 22 | Fixtures | keep | used by the tests | See ask 10 |
| 23 | Tests | keep | 16/16 GUT and 8/8 Python pass | — |
| 24 | `strong-field.md` | keep | — | Fix the claims at `:72-74` and `:76` |
| 25 | Owner reading at `strong-field.md:174-175` | **cut** | 9d says: "rely far more on empirical simulation data than on observational bot play and self-play data … a common-sense check" | Quote it that way |
| 26 | Evidence files | keep | the smoke and gate records | — |

### Cut
1. **Remove the scouting reveal.** Store each seat's previous frame and scout that, as normal mode does; tests and wording as in row 6.
2. **Correct the 9d owner reading** at `strong-field.md:175`.

### Simplify
- Drop the 10 MB cap in both the loader and the generator, or gzip the library.

### Gaps
- **G1. The ghost replays Rival 1's trajectory** (200 of 200 deals).
  - In 96 of 142 ghost rounds, its board equalled a living rival's.
  - It keeps playing Rival 1's trajectory after Rival 1 is eliminated, which contradicts `strong-field.md:72-74`.
  - Fix: deal the ghost a trajectory of its own.
- **G2. Two rivals can share a trajectory.** 38 of 200 games; in the smoke game, Rivals 2 and 7 are identical all game. Fix: deal without replacement.
- **G3. No portal-build launch.**
  - Field mode starts only from a command-line flag, and Android has no command line.
  - The library lives in `tests/`, which every export excludes (`export_presets.cfg:11`).
  - The export include list has no `content/levers`, so the loader silently skips validation (probe 9).
  - Plan step 2 puts both 8a variants "on the portal for the owner", and step 4 makes field mode the default.
- **G4. Persistence weakens from round 11 on the bundled library.** About 3.5 switches a game. Each one replaces the rival's whole board and hero, and moves its size by −21% to +34% in a round. A bigger library fixes this, which the cap limits.
- **G5. No strength evidence.** On this library the field is no harder than the normal bot lobby (probe 7). The 8a library has to be captured on the lever build.
- **G6. Two behaviours aren't tested by the change.** The same-seed test (`test_field_mode.gd:22-49`) compares two field games, so it doesn't prove normal mode is unchanged. The `CorePort` flag path has no test. My probes cover both for now.

### Original problem
Partly moved. The rivals are persistent and placement still means something. But on this library they are no stronger than the bot lobby, the reveal makes them easier, and the owner can't launch the mode from a portal build.

### Open questions (orchestrator's calls)
Asks 7, 8, 10 and 17 in the table.
