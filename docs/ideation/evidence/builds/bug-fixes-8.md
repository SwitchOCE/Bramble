# Build 8 bug fixes and verification — 10 Nov 2026

These are fixes found while preparing build 8, after the orchestrator explicitly
extended the brief to fix bugs. No game rule or rate changed after the separately
requested Soup cut. The full Godot suite remains the orchestrator's cloud gate.

| Commit | Cause and resulting behavior | Evidence |
|---|---|---|
| `3336f79e` | Requested balance exception: B Soup share 0.3 → 0.2. Both generated faces and the authored mechanic say a fifth; C and every other rate are unchanged. | 48/48 targeted path, dial-behavior and Ooze content tests, 6,126 assertions; `build/soup-targeted.log`. |
| `eb52a95f` | A freed node stored in an animation Dictionary/Array failed assignment to a typed Control before its validity guard. `ViewData.control(Variant)` checks validity before narrowing. Action/feedback tracks, pulses, end-of-turn glyphs, combat lookups and retained fan cards use it. | Regressions free target, overlay and pulse nodes mid-motion, then advance and finish; feedback and end-of-turn cases also pass. |
| `7e6846a9` (merged by `419d3402`) | The first fight event could be an aura/setup event, rather than combat_start. Readers now find the actual start and validate player_ids; new fight logs suppress setup transitions before the initial snapshot. | The other worker's fix was merged before the accepted UI run and before the soak; no source conflict remains. |
| `4cdc395b` | The desktop hand reader covered board destinations. It now occupies the right column below gold, leaving the whole board and fan visible for placement. | A regression requires the visible hand reader not to intersect any of the board area; both desktop full games pass. |
| `c731bff5` | Combat/recruit numeral rolls replaced text without refitting the font. A large old/intermediate value could overflow a bead sized for a small final value. Each animated value now uses the same fitting/compaction rules as a static stat. | 229 → 1 is checked at start, midpoint and end against the actual bead width, retaining the minimum 31 font. |
| `26c50eae` | The game-log writer existed but the real UI never collected actions or called it. CorePort now records successful actions using the pre-action index space; App writes one finished-game record. New games clear the list, refusals are excluded and dev actions remain identifiable. | A real completed App game writes one record and replays to the same final hash; reopening game over does not rewrite it. `build/log-hook-final.log`: 1/1 test, 21 assertions. Existing replay/writer checks also passed. |
| `91a376c8`, `48fbedd0`, `9abcef79` | The 1-second automatic result return could cut off about 1.1 seconds of final motion. Return now waits for unfinished tween loops and paints the settled result before switching screens. | The return regression waits for the last tween, reaches its exact destination and emits once. `9abcef79` retains immediate Skip and the original 1.6-second tail budget by overlapping final rewards with the death fade; it changes no individual motion duration. The real recorded round-9 fight (UI label round 10) overlaps at model completion but has no layout problem after motion/deletion flushing: `build/combat-r9-frames.log`. |

Harness corrections are separate commits:

- `6d5019f5`: Scout/Who moved to portraits, while the old hidden buttons remained
  in the script. The shop is checked after closing Scout, when it is visible.
  Overlapping fan/reader geometry is clicked at an exposed, hit-tested point.
  Resting bounds are sampled after the decorative hover lift retires.
- `99ed6998`: injected button positions did not move the real window pointer;
  the floating reader followed a stale position. The driver warps the pointer
  and processes input. Recruit settling no longer delays checks on a combat
  screen that may have been freed by its automatic return.
- `5cec35b4`, `b1b26cdd`, `3146a31f`: model completion, Skip's immediate result,
  and animation completion are checked separately. Finished paused Tweens can
  remain valid and retained; the checker counts unfinished loops instead of
  requiring an empty reference array. Every fight must get a settled end check.

- `f25a6dc5`: ghosts have no scouting hero portrait. Their identity reader is
  checked when Scout opens; both affected phone seeds then reran with zero problems.

No layout threshold, font minimum or click-effect assertion was lowered.
The scripted player's old `naive` labels remain harness labels: the production
port uses the current single bot strength; these four games do not judge bot
strength or the 20-game depth bar.

Final targeted UI checks: **63/63 tests, 3,015 assertions**, strict
hook passes (`build/return-final-passed.log`). This includes the freed-target,
reader-clearance, numeral-fit and automatic-return regressions. Ruff check and
format, gdlint and gdformat --check pass on the final changed-file scope.
The original failure log remains at [ui-8-blocker.log](ui-8-blocker.log).
