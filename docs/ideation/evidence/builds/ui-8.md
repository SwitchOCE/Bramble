# Build 8 final UI run — 10 Nov 2026

**PASS: the fresh requested batch exited 0; four full games and both late checks
have zero problems and zero engine errors. No rerun substitution.**

Command: `tests/ui/full_ui_run.sh 2 1000`.
Game/harness source: `5c050a4ccaee3631330acfe80735e198b37ba01d`, including review
merge `2ef29af4` and the corrected desktop hand reader. The batch ran with the
normal engine clock, six LP threads, the shared Godot slot/3 GB cap, per-game
900-second timeout and 40-minute outer limit. No layout/font threshold changed.

| Size | Seed | Player | Place | Turns | Ghosts | Top tier | Problems | Errors | Exit |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|
| 1920×1080 | 1000 | skilled | 8 | 11 | 0 | 6 | 0 | 0 | 0 |
| 1920×1080 | 1001 | skilled, cap 3 | 8 | 12 | 0 | 6 | 0 | 0 | 0 |
| 1688×780 | 1100 | skilled | 6 | 13 | 1 | 6 | 0 | 0 | 0 |
| 1688×780 | 1101 | skilled, cap 3 | 4 | 14 | 1 | 6 | 0 | 0 | 0 |

Both forced late checks used seed 1000 and completed five rounds, at tier 6 with
a full seven-unit board and ten-card hand: **0 problems, 0 errors, exit 0** at
both sizes. The phone floor and smallest desktop text were **31 canvas units**.
The 20-game depth bar was not judged: this is the requested short run. Three
full games reached round 12, none reached 15, no game was won, and two ghost
fights occurred. The old `naive` table label is a legacy harness flag; the port
uses the current single shipping bot strength. This is not a bot-strength verdict.

Scout, opponent identity, shop and board click-effect assertions all pass.
There is no remaining Lamp Moth label overflow. Earlier harness corrections
check the live portrait controls, hit-test exposed points, move the real pointer,
and check a ghost's initial identity reader rather than an absent hero portrait.
Those causes and their commit SHAs are in [the fix map](bug-fixes-8.md).

Raw fresh logs: `build/ui-run/`; shell output: `build/ui-final-batch.log`.
The [generated batch receipt](../ui-run.md) is the unamended all-green invocation.
The earlier source-48fbedd0 batch needed phone reruns for ghost-harness assertions;
its historical receipt is retained at `cabede12:docs/ideation/evidence/builds/ui-8.md`.
It is superseded by this complete fresh run. The original source-ff1da4e8 failure
log remains at [ui-8-blocker.log](ui-8-blocker.log).

## Reader and review regressions

**402/402 tests, 18,986 assertions across 47 UI scripts pass**, including
`test_hand_fan.gd`, `test_recruit_actions_motion.gd`, other recruit-layout and
CardDetail users, and the merged freed combat/drag regressions. Strict hook
passes. Exact scope and output: `build/reader-fix.gut.json`, `build/reader-fix.log`.
At 1920×1080 with ten cards, selection and hover readers remain left of the
entire fan and above every board destination. Portrait/rules share the available
shop space horizontally; reminders fit inside the reader and full-size action
buttons occupy the right economy column. None of the three requested rules was
given up. Screenshot visually checked: `build/reader-preview.png`.

The original result-return timing and Skip tests also pass. Ruff check/format,
gdlint and gdformat --check pass. No full Godot suite was run; the orchestrator
retains that cloud gate. No real phone or physical touch was tested.

## Actual finished-game log

The real final-source desktop seed-1000 game wrote [this record](game-log-8-1000.json):
57 accepted actions, placement 8, build `5c050a4ccaee3631330acfe80735e198b37ba01d`.
`tools/play/play.sh replay-log` exited 0 and reproduced its final state hash:
`55f8da2ca1c19244f9fcdd08afd44f56106f8a32ce305599c701e57fb0da1f31`.
Raw replay output: `build/ui-record-final-replay.log`.
Replay was checked while HEAD matched the record's build; replaying the retained
sample later requires that recorded source commit, as the verifier intends.
The final-source export and six-sample memory result have separate receipts.
