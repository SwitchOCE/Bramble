# Build 8 UI run and reruns — 10 Nov 2026

**Accepted coverage: 4 full games and 2 late checks; zero remaining problems or errors.**

The requested `tests/ui/full_ui_run.sh 2 1000` completed all four games and both
late checks on game-code source `48fbedd0dd3f674fc00aa1141771424915b87ecf`, with a
normal engine clock, six LP threads, the shared Godot slot/3 GB cap, per-game
900-second timeout and 40-minute outer limit. No layout/font threshold changed.

Its original shell exit was 1: both phone games reached a ghost and the harness
tried to click the absent hero portrait. Those eight assertions were harness
failures, not game runtime errors. The corrected harness checks the ghost
identity shown when Scout opens; living opponents still require a real portrait
click. Both affected phone games were rerun in full with the same seed, size and
player style. Unchanged desktop cases were retained instead of replayed.

| Size | Seed | Player | Place | Turns | Ghosts | Top tier | Problems | Errors | Exit |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| 1920×1080 | 1000 | skilled | 8 | 11 | 0 | 6 | 0 | 0 | 0 |
| 1920×1080 | 1001 | skilled, cap 3 | 8 | 12 | 0 | 6 | 0 | 0 | 0 |
| 1688×780 | 1100 | skilled, rerun | 6 | 13 | 1 | 6 | 0 | 0 | 0 |
| 1688×780 | 1101 | skilled, cap 3, rerun | 4 | 14 | 1 | 6 | 0 | 0 | 0 |

Both forced late checks used seed 1000 and completed five rounds, at tier 6 with
a full seven-unit board and ten-card hand: **0 problems, 0 errors, exit 0** at
both sizes. The phone floor and smallest desktop text were **31 canvas units**.
The 20-game depth bar was not judged: this is the requested short run. Three
full games reached round 12, none reached 15, no game was won, and two ghost
fights occurred. The old `naive` table label is a legacy harness flag; the port
uses the current single shipping bot strength. This is not a bot-strength verdict.

The reruns use the same scoped command as the batch's `play()` function, through
`scripts/godot_slot.sh`, Xvfb and the same normal renderer/audio setup:

```sh
godot --rendering-driver opengl3 --audio-driver Dummy   -s res://tests/ui/shots/playthrough.gd -- 1688x780 --level naive --skilled 1100
godot --rendering-driver opengl3 --audio-driver Dummy   -s res://tests/ui/shots/playthrough.gd -- 1688x780 --level naive --skilled --cap 3 1101
```

Raw original logs: `build/ui-run/`. Accepted phone logs:
`build/ui-1100-fixed.log`, `build/ui-1101-fixed.log`. The original generated
[batch receipt](../ui-run.md) is retained with a follow-up note; it is not
mislabelled as an all-green fresh invocation. The harness-only ghost correction
is `f25a6dc5`. Gameplay source, content, rates and line policies are unchanged.

## Fixes and targeted checks

See [the commit/cause map](bug-fixes-8.md). The final timing compatibility fix
`9abcef79` retains the original 0.1-second Skip return and 1.6-second last-death
budget. Final rewards start during the death fade; individual motion durations
are unchanged. It polls unfinished motion on the next frame and paints one
settled frame. **63/63 targeted UI tests and 3,015 assertions pass**, including
the existing Skip and timing tests and the new freed-node, reader and numeral
regressions (`build/return-final-passed.log`). No full Godot suite ran.

## Actual finished-game log

The real desktop seed-1000 game wrote [this record](game-log-8-1000.json):
57 accepted actions, placement 8, build `48fbedd0dd3f674fc00aa1141771424915b87ecf`.
`tools/play/play.sh replay-log` exited 0 and reproduced its final state hash:
`55f8da2ca1c19244f9fcdd08afd44f56106f8a32ce305599c701e57fb0da1f31`.
Raw replay output: `build/ui-record-1000-replay.log`.
Replay was checked while HEAD matched the record's build; replaying the retained
sample later requires that recorded source commit, as the verifier intends.

The original source-ff1da4e8 failure was fixed, and its exact log is retained at
[ui-8-blocker.log](ui-8-blocker.log). No real phone or physical touch was tested.
