# Build 8 UI blocker — 10 Nov 2026

**Blocked; the run stopped on a real runtime bug, as the brief requires.**

Command: `tests/ui/full_ui_run.sh 2 1000`, through `scripts/godot_slot.sh`,
with the sourced `/opt/bramble/env.sh`, a 3 GB systemd scope, Xvfb and a 40-minute
outer timeout. Source: `ff1da4e8879575dde4df61f8c777ae4edec0c889`.
The Soup preset change does not change any UI code.

The first desktop game, 1920×1080, seed 1000, recorded 6 script errors and
22 problem lines before being terminated during round 6. No game finished;
the other three games and the two late checks did not run. This is an aborted
failure, not a completed four-game result. The existing `evidence/ui-run.md`
was not overwritten and describes an older run.

The exact runtime error is `Trying to assign invalid previously freed instance.`
It occurs in `src/ui/screens/recruit_action_motion.gd`:

- `finish()`, line 221: assigning `pulse["target"]` to a typed `Control` fails
  before the following `is_instance_valid()` check can run.
- `advance()`, line 184: the same failure on `track.get("target")`.

The stack traces show normal hand play through `_tap_without_swallow`,
`_act_placed`, `_act`, `_after_change`, `present`, and the motion process;
`_on_end_turn` also reaches the failing `finish()`.
The log additionally reports Scout, Who?, shop and board click misses and a
Lamp Moth label outside the window at x = −20.16. Their causes were not diagnosed.
No UI or gameplay bug was fixed in this task.

The complete retained first-game log is [ui-8-blocker.log](ui-8-blocker.log).
SHA-256: `d2aaa8df314c7e6a5a56482c6f98f6a1f08b043fdab10cf48ea6695bd6d8ed86`.

## Work stopped and retained

- The old recapture was terminated after the blocker; its partial raw capture is
  under `build/strong-field/recapture/`. No final library was generated, so there
  is no library size or SHA to report. Never use that partial capture: it also
  predates the newly requested Soup change.
- Step 0 is committed separately as `3336f79e202579c21528050513cb298fc509f845`: B Soup share 0.3 → 0.2,
  normal/golden generated faces and their authored mechanic value updated;
  C and every other rate are unchanged. The requested arm is
  `ooze-cut-soup-fifth-20261110` (orchestrator-supplied measurements: engine R12
  789 / 1,554 / 59,334; R15 ÷ R12 5.5; tempo R12 685 / 993 / 5,474).
- Step 0 validation: 48/48 tests and 6,126 assertions across
  `test_pass3_path`, `test_pass3_dial_behaviour`, `test_pass3_ooze_content`;
  strict GUT hook passes. Raw log: `build/soup-targeted.log`.
- Ruff check and format, gdlint and gdformat --check passed; the full Godot
  suite did not run. The orchestrator retains the cloud gate.
- Memory measurement: not run. Dry-run export: not run, no folder.
  Soak: not submitted, no sim id or result. An unsubmitted config remains at
  `build/soak200-build8-20261110.json` with 200 seeds, 8 shards, preset B and
  `library: res://content/fields/baseline.json.gz`.
- The PLAYTEST build 8 addition is retained above build 7's older notes; older
  sections are unchanged. Its Ooze gap uses the orchestrator's latest wording.

Resume only after the UI blocker is resolved or the orchestrator explicitly
changes the stop condition. Recapture from the resulting final source commit,
commit library provenance, then run the memory/export checks and library-based
soak; repeat the requested UI run on that source. No real export or push occurred.
