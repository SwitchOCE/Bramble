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
