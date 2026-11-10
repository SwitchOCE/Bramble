# Play tools (S5): evidence and calls

Branch `ideation/c-play-tools`, brief `docs/ideation/briefs/play-tools.md`. Usage is in `tools/play/README.md`.

## What was built
- **S5a, blind variants:** `play.sh new --variant X|Y` reads the map named by `BRAMBLE_VARIANT_MAP`. The save seals the preset (base64), so it replays without the map. `play.sh <save> reveal` opens the seal and `play.sh <save> hash` prints the state hash. Code: `tools/play/play_variant.gd`, plus small edits to `play_game.gd`, `play.gd`, `play.sh` and `play_view.gd`.
- **Render tool:** `tools/play/render.sh <save> [--turn N | --all]` steps the save through `PlayTurns` (`tools/play/play_turns.gd`) and draws each moment with the real `App` on a `CorePort` whose session is the replayed one (`tools/play/render.gd`). Each turn gets its start, its end (drawn before `end` runs) and a 6-frame fight strip, plus the game-over screen. The tool writes PNGs at 1688×780 and 1920×1080, `manifest_<size>.json` and `index.md` (`render_index.py`).
- **Game log writer:** `src/ui/game_record_log.gd` (`GameRecordLog`), read back by `play.sh replay-log <file>`.

## Tests
- `tests/play/test_play_tools.gd`: 9 tests, 141 asserts, all passing. They cover:
  - a variant replays to the same state hash with no map and with a changed map;
  - X equals a plain game on its preset;
  - the screen, `log` and `--json` contain neither "preset" nor the preset's letter as a word;
  - the save holds the preset only sealed;
  - a damaged seal is refused;
  - the turn walker gives the same moments and hashes twice, and each fight's result equals the log's;
  - a scripted game played through the real `CorePort` with random legal actions (seeded) and recorded via `GameRecordLog.words` replays to the same final state hash;
  - every word conversion matches the tools/play grammar.
- `tools/play/test_render.sh` (needs xvfb, so it isn't in GUT) rendered the same 2-turn game twice, 17 files per size per render, in 5.5 minutes. It passed: both renders agree on hashes and file lists, and both strips match `log`. Probed: a changed hash fails it, and so does a changed `log` result.
- One mistake was found and fixed during the work: the turn-end shot was first drawn after `end` had run.

## Calls made (for the orchestrator to log)
1. **The seal is obfuscation, not secrecy.** Testers drive the game through commands. A tester who decodes their own save can read the preset. The README says so.
2. **A map entry may also name a field library** (`{"preset", "field_library", "field_strength"}`), because A5 plays the strong field with throwaway B and C libraries. A library whose recorded preset differs from the mapped one is refused, without naming either.
3. **`--json`'s end-of-game summary drops `field_source` and `field_switches` in blind games,** since the source config can name the preset.
4. **The state hash** is SHA-256 of the player's `get_state()`, serialised with sorted keys. Nothing defined one before.
5. **Game logs also carry the field library path, Ask for kin and the placement.** Replaying needs Ask for kin, since it changes the config. Saves carry `ask_for_kin` only when it's on, so older saves are unchanged.
6. **The new test file is outside my ownership** (`tests/play/`): GUT only collects under `tests/`. It is a new file, and no existing file was changed.
7. **Dev-panel actions are recorded by name and refused on replay,** rather than being supported.

## For the UI hook (S2, w5)
Record in `CorePort`, as `tools/play/README.md` ("Game logs from the UI") describes:
- before each game-changing call, take `before = get_state()`;
- when the call returns `""`, append `GameRecordLog.words(method, args, before)`;
- at game over, call `GameRecordLog.write(port, actions)` once.

## Not done
- `play.sh --tutorial`: later, per the brief.
- Speed: a turn takes about 30 seconds per size on one Mesa thread, so a 15-turn game at both sizes takes about 15 minutes. `LP_NUM_THREADS` can raise it.

## Gate
After merging ideation/main (e32bfd8e), every static step passed: tools, versions, shell, python, content, format, lint (src, tools, tests), import, compile and parity. The single-process tests step timed out at its 1,200 s cap in this 4-core cloud container. Run as `./scripts/check.sh --shard i/4`, all 4 shards passed: 545 + 578 + 644 + 559 = 2,326 tests, with 0 failing, 0 risky and 0 pending. That is ideation/main's 2,317 plus the 9 new ones. `ruff check` and `ruff format --check` pass on `tools/play/*.py`.

## S5b review follow-ups (10 Nov 2026)

All seven simplifies from `review-play-tools.md` are implemented:

- **S1:** `reveal` is absent from the CLI usage; the orchestrator's README instructions remain.
- **S2:** `_start --variant` refuses any explicit `--field-library`, for both string and object map entries. The map alone selects the library.
- **S3:** the README uses neutral `x.json` filenames and explains the diagnostic/path leak. Blind saves now seal the field reference (path, SHA-256 and strength) as well as the preset; older plain field references still load.
- **S4:** the UI hook list includes all four dev calls; recorded dev words are still refused on replay.
- **S5:** `GameRecordLog.dir` is a static variable, read at write time. Render redirects it to `user://render_games`; the writer test redirects it and restores it.
- **S6:** the render index's dirty mark uses `git status --porcelain -- src content assets tools/play project.godot`, including untracked assets.
- **S7:** a wrong screenshot size exits 1; the draw loop cannot subsequently overwrite that result with success.

**A1:** `test_render.sh` obtains `play.sh <save> hash`. The checker compares it with the last moment in every manifest from both renders. Three Python tests cover a match, agreeing-but-wrong render hashes, and a missing final moment. The real render run exposed the retired `_fight_name` label; render now checks the name held by the current fight screen's hero reader/log.

**A2:** each log records `final_state_hash` and `build` (full commit SHA). `replay-log` refuses a different or missing build, a changed final hash, a changed placement, or a different hero. Tests reach game over for the final checks; another replays a field log with a relocated library and refuses changed library bytes. Source-tree logs resolve Git HEAD. Exported builds must supply `application/config/build_commit` or `BRAMBLE_BUILD_COMMIT`; there is no exporter change in this owned scope. A replay without an identifiable build is refused.

**A3:** the checkpoint brief uses X/Y only, drops the preset sizes/names, and forbids `reveal`, opening saves, reading `content/pass3/rates.json` and reading the variant map. The seal remains obfuscation for good-faith testers.

**Gaps:** the blind scrub test now plays a synthetic current-content field library through game over, confirms the unsanitized summary contains the source/switch keys, and checks screen/log/JSON and the save for preset/path leaks. It also replays the sealed field save to the same hash. The changed-map assertion that could not fail is removed. An explicit round trip compares direct API calls with `PlayGame.run(GameRecordLog.words(...))` on equal hand-built states for choose, buy, buy_spell, play, play_item (no target, board target and shop target), swallow (hand, board and shop), power (targeted and untargeted), sell, move, refresh, Ask for kin, freeze, tier up and end. CLI `_start --variant`, `_from_log` and the library/preset mismatch refusal have direct tests.

Focused validation: **14 play tests / 324 assertions**, **2 cache tests / 12 assertions**, and **3 render-checker Python tests** pass. Whole-game replay and combat smoke tests also passed their focused run (48 tests / 859 assertions). The final full-suite/static/render counts are recorded in the S5b/S10b hand-back.

**A4 remains the scheduled build-8/A7 prerequisite:** this follow-up's render check does not replace the requested strong-field render on the eventual build-8 commit.
