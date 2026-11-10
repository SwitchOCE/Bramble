*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov: `ideation/c-play-tools` `eaea0e05..06ba4bbe` (S5). Calls: DECISIONS (ideation/main) "Play tools (S5): review calls".]*

# Scope review: `origin/ideation/c-play-tools`, `eaea0e05..06ba4bbe` (S5 play tools)

All three inputs were present: the owner's words (08a, 09e), the approved plan line (plan-to-done.md:205) and the brief (`docs/ideation/briefs/play-tools.md`). I read the brief and the worker's notes as proposals. I did not run Godot. I did run a Python probe of `render_check.py` and `render_index.py` on made-up manifests in the scratch dir.

## Summary

- **Counts:** 20 keep, 0 cut, 7 simplify, 4 ask.
- **Does it move the original problem? Partly.**
  - **A5 (blind testers):** S5a removes this stream's blocker. A5 still waits on A4's B and C libraries and W-c's brief. The blinding covers the preset's name only.
  - **A7 (testers with renders):** the render tool removes this stream's blocker. A7 still waits on A6 and W-d. The render has only been tested on a 2-turn bots game, and that test is outside every gate.
  - **Owner's logged games (08a):** the writer and the replayer exist, but nothing in the game writes a log yet. The UI hook is S2's job, and A6 needs it.
  - **Tutorial (09e):** not moved. There is no `content/tutorial` at eaea0e05, so putting it off is justified.
- **Ask items, one line each:**
  - A1. `play.sh <save> hash` (play.gd:119-120): nothing reads it. Either make test_render.sh compare the last render hash with it, or drop it.
  - A2. The game log's `placement` (game_record_log.gd:93): nothing reads it. Record a final state hash and the build/commit too, and have replay-log compare them. Today a replay that drifts is caught only if the hero differs (play.gd:159-162).
  - A3. Blinding works only if testers don't look. The seal is plain base64 (play_variant.gd:72-73), `reveal` needs no map, and the README documents both (the checkpoint brief points testers to it). `--json` also carries values that differ by preset. Accept this, and have W-c's brief forbid `reveal`, opening saves and reading rates.json?
  - A4. Who runs `test_render.sh`, and when? It is in no gate, has never drawn a field-library save (build 8's default), and reads UI internals that S2 keeps changing (render.gd:121 reads `_fight_name`). Run it on the build 8 commit with a field save before A7?
- **Cut items:** none.

## Report (inventory, no judgment)

The net diff against eaea0e05 is 20 files, +1,264 / −12. The two merges of ideation/main bring nothing else in, because eaea0e05 is the last ideation/main the branch merged.

**3. Features**
- **Blind variants.**
  - What: `new --variant X|Y` looks up the preset in the JSON file named by `BRAMBLE_VARIANT_MAP` (play_variant.gd:17-44, play.gd:57-76). With no map it refuses (play_variant.gd:21-22). The save stores `variant` plus a base64 seal (play_variant.gd:84-89). Replay reads the seal and never the map (play_variant.gd:93-107).
  - Used by: A5. Reason: brief §1 ("S5a").
- **`reveal`.**
  - What: prints "Variant X plays preset C" and the field library (play_variant.gd:111-124, play.gd:117). Reason: brief §1.
- **`hash`.**
  - What: prints the state hash (play.gd:119-120). Used by: nothing. Reason: none stated.
- **Map entry may name a field library.**
  - What: an entry can carry its own field library and strength (play_variant.gd:35-39). Giving `--field-library` as well is refused (play.gd:69-74).
  - Used by: A5 ("blind against the strong field"). Reason: worker's call 2, proposed.
- **Library/preset mismatch refusal.**
  - What: refuses a library captured on another preset, without naming either (play_game.gd:192-195). Reason: worker's call 2.
- **End-of-game scrub.**
  - What: `--json` drops `field_source` and `field_switches` in blind games (play_variant.gd:132-138, play_view.gd:55). Reason: worker's call 3.
- **Render tool.**
  - What: render.sh/render.gd step the save through `PlayTurns` and draw the real `App` on a `CorePort` whose session is the replayed one (render.gd:52-62). It shoots start, end, a 6-frame fight strip and game over per size. Output: `manifest_<size>.json`, plus `index.md` written by render_index.py.
  - Used by: A7. Reason: brief §2.
- **Render test.**
  - What: test_render.sh plus render_check.py. It renders twice and compares hashes, file lists and each strip against `log`.
  - Used by: manual runs only. Reason: brief §2 "Test".
- **Game log writer.**
  - What: `GameRecordLog.words/write/make/to_save/hero_id` (game_record_log.gd:29-130).
  - Used by: `replay-log` (play.gd:150-163) and the test. Nothing in src/ui calls it. Reason: brief §3, plan §1.11.
- **`replay-log`.**
  - What: replays a log, checks the hero, and keeps a save (play.gd:125-163, play.sh:34-47). Reason: brief §3.
- **Extra fields in logs and saves.**
  - What: logs and saves carry `ask_for_kin` (play_game.gd:77,123-124,175; game_record_log.gd:85,120). Logs carry the library path and the placement (game_record_log.gd:82,93).
  - Used by: replay reads `ask_for_kin` and the path. Nothing reads `placement`. Reason: worker's call 5.
- **Dev calls in logs.**
  - What: recorded under their own names and refused on replay (game_record_log.gd:52-55). Reason: worker's call 7.

**5. Config**
- `BRAMBLE_VARIANT_MAP`: no default, and `--variant` refuses without it. play.sh turns it into an absolute path (play.sh:51-55).
- `RENDER_SIZES`: default "1688x780 1920x1080".
- `RENDER_TIMEOUT`: 900 s per size.
- `LP_NUM_THREADS`: 1 (render.sh:30-34).

**6. Public interfaces**
- New commands: `new --variant`, `<save> reveal`, `<save> hash`, `replay-log <file> [--save] [--field-library]`, `render.sh <save> [--turn N|--all]`.
- New functions: `PlayGame.start(..., rates_preset, blind_variant)` (play_game.gd:42-62) and `PlayGame.state_hash()` (play_game.gd:149-153), which is SHA-256 of sorted-key `get_state()`. `PlayView.player_name` (play_view.gd:604).

**7. Internal machinery**
- `PlayTurns`, a turn walker (play_turns.gd).
- `PlayVariant` (play_variant.gd).
- The manifest JSON per size.

**None:** Schema, Scheduled, External, Deleted.

**Unrequested** (no stated reason, or nothing reads it): `hash`, `placement`, the field-library map form, the scrub, `ask_for_kin` in logs, dev calls by name. All but `hash` and `placement` were proposed by the worker for a reason that holds; see the table.

## Checking the worker's claims

- **Blind variants: true as far as the preset's name goes.**
  - The refusal with no map is at play_variant.gd:21-22.
  - Replay without the map is tested (test_play_tools.gd:52-61).
  - The save path is `game-<seed>.json` (play.sh:26).
- **Render tool: the structure is as described.** 17 files per size for a 2-turn game is consistent: 1+1+6 per turn, twice, plus the next start. I could not check the timing.
- **Game log writer: true, and the hook is not wired.** The only callers are the test and play.gd.
- **2,326 tests: consistent.**
  - 545+578+644+559 = 2,326.
  - The tip has 2,326 `func test_` lines.
  - DECISIONS.md:63 records 2,317 on ideation/main, and the new file adds 9.
  - The full single-process `check.sh` that the brief asked for did not finish (1,200 s cap). The shard tool finds every `tests/**/test_*.gd` (test_shards.py:29-37), so `tests/play` is covered.
- **The one file outside its ownership is `tests/play/test_play_tools.gd` (and its .uid).**
  - It's justified: `.gutconfig.json` lists only `res://tests`, it is a new file, and no existing test changed.
  - Apart from that, only `docs/ideation/evidence/play-tools.md` was touched, which the brief asked for.
  - No file in `src/ui` changed except the new `game_record_log.gd`.

## Could a blind tester learn the preset?

**By name, no.** The screen, `log`, `--json` and the save path don't contain it. The test checks this, and so does the code: `get_state()` has no preset key.

**There are five other ways in:**
1. **`reveal`.** It needs no map, and the usage text a tester sees advertises it (play.gd:20). → S1, A3.
2. **The seal.** It is base64, and README:58 says so. The checkpoint brief sends testers to the README (checkpoint1-playtest.md:19). → A3.
3. **Numbers in `--json`.**
   - `--json` state carries values that differ by preset (game_session.gd:202-206).
   - For example, `birds_homecoming_multiplier` is 2.5 on C and 2.0 on B (rates.json base 2.0, C overrides 2.5).
   - Anyone who compares with `content/pass3/rates.json` can tell which is which. Card numbers on the screen differ for the same reason; that comes with testing two presets. → A3.
4. **The field library path.**
   - The save stores it in clear (play_game.gd:119).
   - A missing library prints it at `new` ("Field library does not exist: %s", field_library.gd:32).
   - Both leak if the file is named after its preset, as README:53's `res://build/fields/c.json` is. → S3.
5. **A probe.** With a plain-string map entry, `--variant X --field-library <lib>` is refused only when the library's preset differs from X's (play.gd:69-74, play_game.gd:193-195). → S2.

Separately, W-c's current draft brief names B and C and their totals ("about 900 … about 1,800", checkpoint1-playtest.md:7-10,20). That has to change for X/Y.

## Do replay-log and render agree with the live game?

- **Live UI vs replay-log: good evidence for bots games.**
  - test_play_tools.gd:147-184 plays seed 29 to round 6 through the real `CorePort` with seeded random legal moves. It records each move with `words()`, and the replay matches the live final state hash.
  - The configs match:
    - `CorePort.new_game` uses `full_game()`, whose bots are `BotLobby.seats(HARD)` (game_config.gd:134), plus Settings' `ask_for_kin` (core_port.gd:56-57).
    - `PlayGame._begin` uses the same `full_game()`, `BotLobby.seats()` and `ask_for_kin`, and `top4`, which is also the UI's only strength.
  - Not tested: field-library logs (build 8's default), `ask_for_kin` logs, and play.gd's `_from_log` (the hero check and `--field-library` override). In real use, nothing would notice a log that replays to a different game (A2).
- **Render vs tools/play: the same by construction.**
  - render.gd draws the session `PlayTurns` replayed (render.gd:52-61).
  - The GUT test shows the walker's last hash equals the save's (test_play_tools.gd:126).
  - Nothing checks that drawing leaves the session unchanged. render_check compares two renders with each other (render_check.py:40), not with `play.sh <save> hash`. The risk is low: every game-changing port call in recruit_screen.gd is a click handler. → A1.

## Table

| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| 1 | Blind variants: map lookup, seal, load/store | keep | play_variant.gd:17-107; play.gd:57-76; brief §1 | none |
| 2 | Map entry names a field library | keep | play_variant.gd:35-39; plan A4 "throwaway B and C libraries for the checkpoint testers". Without it, the tester picks the library and so learns the preset | none |
| 3 | Library/preset mismatch refusal | keep | play_game.gd:192-195. An orchestrator map mistake would otherwise play the wrong preset silently. Untested | add a test (gap) |
| 4 | `reveal` | keep | brief §1 "a separate command, `play.sh <save> reveal`" | see S1 |
| 5 | `state_hash` | keep | play_game.gd:149-153; the brief's tests and index.md need a hash | none |
| 6 | `scrub_game_log` | keep | play_variant.gd:132-138. `field_source` lists capture paths (tools/sim/field_library.py:283-286). Untested (G1) | test it |
| 7 | play.sh exports an absolute map path | keep | play.sh:51-55; play.sh `cd`s to ROOT (line 56) | none |
| 8 | `PlayTurns` walker | keep | play_turns.gd; used by render.gd:52 and test_play_tools.gd:135 | none |
| 9 | render.gd and render.sh | keep | brief §2 | none |
| 10 | render_index.py and the manifests | keep | brief "index.md that names the commit…" | none |
| 11 | render_check.py and test_render.sh | keep | brief §2 "Test". The probe confirms a changed hash fails (exit 1) and a changed log result fails | see A4 |
| 12 | RENDER_SIZES, RENDER_TIMEOUT, LP_NUM_THREADS | keep | render.sh:30-34. Speed and quick checks only; the defaults meet §1.7 | none |
| 13 | `GameRecordLog` | keep | game_record_log.gd:29-130; plan §1.11; read by replay-log | see S4, S5 |
| 14 | `replay-log` | keep | play.gd:125-163; brief §3 | none |
| 15 | Hero check on replay | keep | play.gd:159-162; the only drift check. Untested | test it |
| 16 | `ask_for_kin` in saves and logs | keep | Without it, a UI game played with the Settings toggle on can't replay: `ask_for_kin` is only legal when the config enables it (game_session.gd:174) | none |
| 17 | Dev calls recorded by name | keep | game_record_log.gd:52-55 | see S4 |
| 18 | `PlayView.player_name` wrapper | keep | play_view.gd:604; used by play_turns.gd:107 | none |
| 19 | tests/play/test_play_tools.gd (outside ownership) | keep | .gutconfig.json `"dirs": ["res://tests"]`; new file | none |
| 20 | evidence/play-tools.md | keep | the brief asks for it | none |
| S1 | `reveal` in the usage text | simplify | play.gd:20 shows "reveal (orchestrator: a blind save's preset)" to anyone who runs `play.sh` bare | drop the line; keep README's orchestrator section |
| S2 | `--field-library` allowed with a plain-string variant | simplify | play.gd:69-74 refuses only when the map names a library. With a string entry, the mismatch refusal (play_game.gd:193-195) answers "is X's preset this library's?" | refuse `--field-library` whenever `--variant` is given |
| S3 | README example names the preset | simplify | README.md:53 `res://build/fields/c.json`; the save stores the path in clear (play_game.gd:119); field_library.gd:32 prints it | use neutral names (x.json) and say why |
| S4 | Hook list leaves out dev calls | simplify | README.md:97 lists only game calls, but README.md:100 promises dev calls are "recorded… and replay refuses them". A hook built to the list records nothing for `dev_*` | add `dev_add_gold`, `dev_spawn_to_hand`, `dev_set_tier`, `dev_skip_turn` to the list |
| S5 | Log directory is a `const` | simplify | game_record_log.gd:14. render.gd:25 already moves `Records.path` aside, but can't move a const. Once S2 calls `write()` on game over, every render and UI test that reaches game over writes a log into `user://games` | make it a `static var` like `Records.path` and `Settings.path`; set it in render.gd |
| S6 | Uncommitted-change mark in index.md skips `assets/` and new files | simplify | render.sh:48 checks only `src content tools/play project.godot`, yet the UI loads 16 `res://assets/` paths. `git diff` ignores untracked files | use `git status --porcelain -- src content assets tools/play project.godot` |
| S7 | Wrong image size doesn't fail | simplify | render.gd:130-131 only prints an error; render.sh:41 greps only SCRIPT ERROR/Parse Error. §1.7 requires 1688×780 and 1920×1080 | `quit(1)` on a size mismatch |
| A1 | `hash` command | ask | play.gd:119-120; nothing reads it | have test_render.sh compare the last moment's hash with `play.sh <save> hash`, or drop it |
| A2 | `placement` in the log; no final hash or build | ask | game_record_log.gd:93; nothing reads it. A log replayed on another commit, or with an unrecorded call, drifts with no warning unless the hero differs | record the final state hash and build id; replay-log compares them and the placement |
| A3 | Blinding by name only | ask | play_variant.gd:9-10,72-73; README.md:58,63; game_session.gd:202-206 | accept, and W-c's brief forbids `reveal`, opening saves, reading rates.json and the map, and drops the B/C sizes |
| A4 | test_render.sh outside every gate, never run on a field save | ask | needs xvfb; test_render.sh:13 plays a bots game; render.gd:90-122 reads `CombatScreen` internals owned by S2 | run it on the build 8 commit with a strong-field save before A7 |

## Gaps (missing or untested in-scope behaviour)

- **Tests that pass vacuously:**
  - test_play_tools.gd:79-93 never reaches game over, so the `game_log` key that `scrub_game_log` acts on is absent (play_view.gd:54). It also uses no field library. Its save check `'"C"'` would pass with `res://build/fields/c.json` in clear. So it can't see the leaks that matter for A5's setup.
  - test_play_tools.gd:63-65 ("a changed map doesn't change the game") can't fail: `from_save` never reads the map.
  - test_play_tools.gd:187-209 compares `words()` with strings the worker wrote by hand and never runs them through `PlayGame.run`. The round trip asserts only choose, buy, play and end. buy_spell, play_item, swallow and power are replayed only if seed 29 happens to take them.
- **Untested paths:** play.gd `_start` (the CLI `--variant` path), `_from_log`, the library/preset mismatch, and replay-log or render of field-library games.
- **Not built:**
  - Tutorial mode: deferred, no data yet. B4's gate will also need render.gd to draw the tutorial and the coach slip, which it doesn't do.
  - The UI hook: S2's job, and A6 waits on it.
- **For A7's brief (W-d):** `play.sh new` defaults to the bot lobby, but build 8's default is strong field on the default preset. §1.7's "default settings" means testers must pass `--field-library res://content/fields/baseline.json.gz` (field_library.gd:9).

## Open questions for the orchestrator

1. A3: is name-only blinding enough for A5, given cloud testers can read the repo?
2. A2: should owner logs carry a final hash and build id before A6, so W-g can trust what it replays?
