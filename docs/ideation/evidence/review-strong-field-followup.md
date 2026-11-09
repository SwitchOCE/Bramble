# Strong-field follow-up review: 9cfe2ec..0f6d6c3 (scope reviewer, 10 Nov 2026)

## Follow-up scope review: `ideation/strong-field`, `9cfe2ec..0f6d6c3`

All scope inputs were given: the range, the owner's words (now including notes 09h and 09i), the plan, and the "Strong-field review: calls" entry in DECISIONS. Per 09i, I judged the strength result as a measurement only.

**Counts:** 23 keep, 0 cut, 0 simplify, 2 ask.

**Does it move the original problem?** Yes, further than before.
- Against the top-four field, a Hard bot in the human seat averages place 5.10, against 3.95 in the normal bot lobby (+1.15 places, roughly +0.08 to +2.22). I recomputed both from the committed raw rows.
- It also lasts fewer rounds: 13.8 against 15.9.
- Trajectory switches drop 58%.
- The board reveal is gone.

But no build the owner can play has the mode yet. And round-12 field boards are about 114 Attack + Health, against the 759 reference; that is the pool's scale, not something this mode can fix.

**Cuts:** none. Both earlier cuts are fixed:
- Scouting now shows the rival's previous-round board, and nothing in round 1.
- The 9d reading now matches what the owner said. One nit: the quote says "compared to", while the record says "than on".

**Asks:**
1. **Field mode is off in every player build, and no library is committed or shipped.** This departs from your call 2 ("works on Android, with the library shipped in exports"). It also leaves plan step 2 (strong-field mode in build 8a for the owner) and checkpoint 2 ("against the strong field") without the mode. Which build turns the flag on, and who recaptures the library for it? Please log the call.
2. **The library is not compressed** (your call 5 said "stored compressed"). Starting one game from the 48 MB measurement library took 2.6 s plus 1.9 s on this desktop. It added 609 MB of memory and peaked at 1.17 GB, because the file is parsed and fully validated twice. That needs fixing before the feature ships to Android: shrink it, compress it, or parse it once.

**Clear to merge after the harness?** Not as it stands. Two fixes are needed:
- **One text conflict, the same against local `ideation/main` and against `ideation/harness`.** It's in `src/core/game_config.gd`: the harness adds `pass3_content` and `pass3_loop_guards`, this branch adds the three field keys. Keep both sets. Main plus harness merges cleanly.
- **One test fails after the merge: `test_field_normal_regression`.** All four 9af89c2 game fingerprints differ, and its extra-key check rejects the harness's new keys. It fails the same way on the harness tip with no strong-field code (496 failed asserts in both runs), so the harness's wave 1 changes cause it, not this branch. Fix: re-pin `tests/fixtures/field/normal-9af89c2.json` to the harness tip, and allow that tip's config keys.

With those two fixes, the other 34 of 35 field tests pass on the merged tree, including the harness's own field tests.

**What a player build would show today:**
- No field option and no library. Normal games are unchanged (fingerprinted against 9af89c2 at this branch's head).
- Settings loses its decorative tray of six portraits. The declutter audit already marks it "cut", but the tray is now hidden, leaving an empty area.
- If a game fails to start, a "Could not start game" dialog appears.
- Player packs now include `content/levers/*.json`, which goes unused unless levers are set.
- Launching a player build with `--field-library` gets "Strong field is not enabled in this build".

**Before the feature ships** (not visible to players now):
- The load cost in ask 2.
- A field ghost is labelled "A ghost" in combat (`app.gd:274`).
- The combat plaque drops the "Rival N" prefix.
- The scout heading overlaps the Last Stand strip (both noted in the doc).
- The packed export probe runs the editor binary, which counts as an editor build, so it can't test the command-line refusal.

---

### Each earlier finding

| Earlier finding | Status | Evidence |
|---|---|---|
| Cut 1: board reveal | Fixed | `scout()` reads `previous_frames` and returns {} in round 1; Egg bird stats and timers are stripped; test at `test_field_mode.gd:154` |
| Cut 2: 9d quote | Fixed | `strong-field.md`, "Readings" section (wording nit above) |
| G1: ghost copied Rival 1 | Fixed | The ghost is dealt from the remaining pool like a seat; switches skip trajectories in use (`_occupied`); tests at `:316` and `:343` |
| G2: shared trajectories | Fixed | Dealt without replacement; test runs 200 deals with 8 distinct trajectories each |
| G3: no portal launch | Replaced by a flag | Off in all presets, library excluded; see ask 1. The loader now fails loudly (`field_library.gd:100-129`; test at `v2:47`) |
| G4: board jumps at switches | Improved | Switches per game: 4.10 with all finishes, 1.725 with top four |
| G5: no strength evidence | Measured | Raw rows reproduce 3.95 / 3.60 / 5.10 |
| G6: untested paths | Tested | Normal-mode fingerprints at 9af89c2 (needs re-pinning, as above); the settings, App and CorePort path (`test_field_settings.gd`) |
| Ask: pool reservation | Kept | Your call |
| Ask: out-of-lobby tribes | Fixed | A rival's whole source lobby must fit the current lobby (`eligible()`; test at `v2:66`) |
| Ask: manifest breaks on text edits | Fixed | The manifest hashes gameplay fields only, with GDScript and Python matching (`v2:7, :33`). I checked that stripping `source` is safe: pool membership reads `set` and `pool` |
| Ask: unread standings keys | Removed | `field_rounds` is kept in the game log |
| Simplify: 10 MB cap | Cap removed | Compression not done; see ask 2 |

### New items in the range (all keep)
- The `field_strength` dial (`top4`/`all`) and its save pinning.
- The check that refuses a game when the library has fewer than 8 eligible distinct trajectories.
- The synthetic test library built from current content.
- The frozen 9af89c2 content snapshot.
- The Opponents setting behind the `strong_field` flag.
- The per-game config reset in `CorePort`. Only `main.gd` and the playthrough tool call `setup()` without a config, so normal play is unchanged.
- The start-game error dialog.
- The export preset and export smoke changes.
- `recapture_field.sh`, the comparison and report tools, and the UI evidence driver.

**Nits:**
- `recapture_field.sh` checks its logs with `rg`. If `rg` is missing, the check silently passes; `grep -E` would avoid that.
- `strong-field.md:411` and `:417` still point at the deleted `tests/fixtures/field/baseline.json`.

### What I ran
All Godot runs held the shared lock with the 3 GB cap, in temp copies made from git trees (since deleted).
- **Merge check:** read-only `git merge-tree` of main + harness, then strong-field on top. I resolved the conflict by keeping both key sets, imported, and ran the `test_field_` scripts.
- **Attribution check:** the normal-mode regression alone on the harness tip.
- **Load probe:** the 48 MB measurement library from the worktree's `build/` folder, on the head tree.

**Not run:** the full suite on the merged tree (the branch's own recorded gate shows 1,726 Godot tests passing), a real export, and screenshots.
