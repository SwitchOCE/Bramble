# Build 8 bug fixes and verification — 10 Nov 2026

These are fixes found while preparing build 8, after the orchestrator explicitly
extended the brief to fix bugs. No game rule or rate changed after the separately
requested Soup cut. The full Godot suite remains the orchestrator's cloud gate.

| Commit | Cause and resulting behavior | Evidence |
|---|---|---|
| `3336f79e` | Requested balance exception: B Soup share 0.3 → 0.2. Both generated faces and the authored mechanic say a fifth; C and every other rate are unchanged. | 48/48 targeted path, dial-behavior and Ooze content tests, 6,126 assertions; `build/soup-targeted.log`. |
| `eb52a95f` | A freed node stored in an animation Dictionary/Array failed assignment to a typed Control before its validity guard. `ViewData.control(Variant)` checks validity before narrowing. Action/feedback tracks, pulses, end-of-turn glyphs, combat lookups and retained fan cards use it. | Regressions free target, overlay and pulse nodes mid-motion, then advance and finish; feedback and end-of-turn cases also pass. |
| `7e6846a9` (merged by `419d3402`) | The first fight event could be an aura/setup event, rather than combat_start. Readers now find the actual start and validate player_ids; new fight logs suppress setup transitions before the initial snapshot. | The other worker's fix was merged before the accepted UI run and before the soak; no source conflict remains. |
| `4cdc395b`, corrected by `5c050a4c` | The hand reader covered board destinations. Moving it right cleared the board but broke the existing rule that a full desktop fan uses a reader on its left. The corrected reader spans the shop space above the board and left of the fan; portrait and scrollable rules sit beside each other, with full-size actions in the right economy column. All three rules hold at 1920×1080. Shop offers under the open reader are temporarily covered. | The unchanged left-side/fan assertions plus added board, hover, rules and keyword-reminder checks pass with ten cards. Visual check: `build/reader-preview.png`. |
| `c731bff5` | Combat/recruit numeral rolls replaced text without refitting the font. A large old/intermediate value could overflow a bead sized for a small final value. Each animated value now uses the same fitting/compaction rules as a static stat. | 229 → 1 is checked at start, midpoint and end against the actual bead width, retaining the minimum 31 font. |
| `26c50eae` | The game-log writer existed but the real UI never collected actions or called it. CorePort now records successful actions using the pre-action index space; App writes one finished-game record. New games clear the list, refusals are excluded and dev actions remain identifiable. | A real completed App game writes one record and replays to the same final hash; reopening game over does not rewrite it. `build/log-hook-final.log`: 1/1 test, 21 assertions. Existing replay/writer checks also passed. |
| `91a376c8`, `48fbedd0`, `9abcef79` | The 1-second automatic result return could cut off about 1.1 seconds of final motion. Return now waits for unfinished tween loops and paints the settled result before switching screens. | The return regression waits for the last tween, reaches its exact destination and emits once. `9abcef79` retains immediate Skip and the original 1.6-second tail budget by overlapping final rewards with the death fade; it changes no individual motion duration. The real recorded round-9 fight (UI label round 10) overlaps at model completion but has no layout problem after motion/deletion flushing: `build/combat-r9-frames.log`. |


Review fixes from `ideation/build8-fixes` tip `4fe19ea6` were merged cleanly by
`2ef29af4` before the final UI batch and dry-run export:

| Commit | Cause and resulting behavior | Evidence |
|---|---|---|
| `f9f66121` | Combat death/transfer cleanup could narrow freed references before checking validity. Validate retained values before casting; skip freed cards and pictures during cleanup. | Freed death cards cover next attack, Skip and replay; delayed cleanup is tested with transfer pictures freed mid-motion. |
| `86e4393f` | Drag reach previews retained freed card keys and a running lean tween across board clearing. Retire the tween and validate keys before restoring positions. | Drag preview regression frees a card, changes the candidate and clears the board; no engine error. |
| `d6594d53` | A fight missing the player's combat-start identity returned without refreshing recruit. The error path now returns to a fresh recruit screen. | App/combat-start and screen tests are in the 47-file targeted run. |
| `4fe19ea6` | A test deliberately printed an engine error, conflicting with the cloud strict hook. Removed that deliberately erroring test. | No engine error is deliberately emitted by the final targeted run. |

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

Final targeted UI checks after the review merge and reader repair: **402/402
tests, 18,986 assertions across 47 scripts**, strict hook passes
(`build/reader-fix.log`; exact test list: `build/reader-fix.gut.json`). This
includes `test_hand_fan.gd`, `test_recruit_actions_motion.gd`, other UI tests
loading recruit screens/layout or CardDetail, and both review regression files.
Ruff check/format (37 Python files), gdlint and gdformat --check (34 changed
GDScript files) pass. No full Godot suite ran.
The original failure log remains at [ui-8-blocker.log](ui-8-blocker.log).
