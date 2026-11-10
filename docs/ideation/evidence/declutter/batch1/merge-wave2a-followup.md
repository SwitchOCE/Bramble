# Declutter follow-up after wave 2a integration

## Part 1: merged-tree soundness

Input merge: `55e0d8b0`. No source changes were required. The first local compile
used stale global-class metadata; a worker-slot editor import refreshed it. The
subsequent `tools/checks/compile_all.gd` run loads **596 files, zero failures**.
All fourteen targeted UI files below pass with the strict hook, no risky/pending
tests or script errors. No tests were loosened or word-chip assertions changed:
these wave 2a chip tests exercise recruit cards, whose chips remain available.

| Targeted UI test file | Tests passed | GUT time |
| --- | ---: | ---: |
| `test_combat_declutter.gd` | 28 | 4.222s |
| `test_combat_face.gd` | 8 | 0.396s |
| `test_combat_pockets.gd` | 2 | 0.378s |
| `test_combat_relocate.gd` | 4 | 1.952s |
| `test_cards.gd` | 16 | 3.381s |
| `test_lane_display.gd` | 9 | 6.488s |
| `test_nest_tile.gd` | 5 | 0.439s |
| `test_review_tribes56_log.gd` | 9 | 4.004s |
| `test_followup_tribes56.gd` | 7 | 0.586s |
| `test_pass3_ui.gd` | 10 | 2.722s |
| `test_pass3_bog_ui.gd` | 5 | 0.972s |
| `test_review_bog_preview.gd` | 5 | 9.566s |
| `test_pending_gains_ui.gd` | 7 | 2.505s |
| `test_review_lender_tags.gd` | 6 | 1.255s |

Each file ran in a separate Godot process, sequentially, under
`GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://build/declutter/<file>.json`.
Each generated config has empty `dirs`, one `tests` path, `should_exit:true`, and
`post_run_script:res://tools/checks/gut_strict_hook.gd`. Compilation and tests ran
in detached `bramble-declutter-merge-targeted2.service`. Logs are
`build/declutter/merge2-{compile,<test-file>}.log`; the job log ends
`merge_targeted_complete`. No full gate or cold reader was run.

## Part 2: four visual fixes

- Aura now waits for the summoned recipient's arrival to settle before choosing its
  destination. Its travelling source-to-stat route has an arrival arrowhead and a
  held ring on the recipient's changed bead, rather than only a ring on its source.
- Only joint (Pack) attacks use the deeper 0.35-height lunge. Every other attack
  retains the original 0.85-height overlap. The joint attack has a 0.48-second minimum
  approach so both are visible before contact, including at ×4. Reduce motion uses
  an instantaneous, held 42-pixel attack pose for each partner instead of travel.
  Separate damage contributions and the real retaliation target are retained.
- A dead unit's permanent reward travels to a retained recruit portrait outside the
  fighting pockets. Its numeric pending pair lands briefly, then the portrait fades
  and is freed. It has no current combat stats and creates no standing reserve.
  The narrow follow-up below supersedes the earlier persistent version.
- Counter's self-gain finishes before a red sword transfer goes from the answering
  unit to the attacker it answers. The attack then follows. The former simultaneous
  gold link stays removed, preserving the unambiguous self-source of the stat gain.

Changed files: `src/ui/screens/combat_motion.gd`, `combat_special_motion.gd`,
`combat_screen.gd`, `tests/ui/test_combat_declutter.gd`, and this evidence note.
The existing dead-reward test now requires a persistent reserve landing instead of
an expiring echo. New tests check both Pack poses at ×1/×4/reduce, directed Aura and
its recipient landing, and Counter's ordered self-gain/answer cue.
Targeted `test_combat_declutter.gd`: **31/31, 273 assertions, 5.06 s**;
strict hook passes (`build/declutter/motion4d-test_combat_declutter.log`). Production source
formatting/lint passed; the full test-directory lint was not run at that checkpoint. No rule text was added to the resting board.

## Part 3: wordless wave 2a state and source cues

Kiss pips read the configured period, initial nested counters and replayed shared
count, with modulo progress. The reader keeps the exact cumulative count/period.
Pending gains use a folded hourglass mark on a live combat card, with colored
Attack/Health dots and a source-to-tag transfer. A dead recipient gets a transient
portrait landing; its exact queued pair remains in the reader. Recruit's numeric
tag is unchanged in this batch.
Bog Toll travels from its source to that side's hero and pulses on arrival, then
fades. No badge or running total remains on the plaque. The hero reader retains
the exact total, and end-of-fight damage still includes Toll. Replay rebuilds motion.

The source-cue test covers Mire patch, Take, legacy Poach, native Russet's trigger,
Pack's trigger, Pounce, Counter, Quarry marked, Kiss, Prince transform and Bog
hit-back in both motion modes. Mire makers, Kiss frogs and transforming Princes
now also receive held source rings. Existing generic trigger pulses cover native
Hunter/Bog observers. Pack leader/joiner poses are covered by Part 2. Pounce timing
and the definitions of Pack/Mire remain Batch 4 Rules/tutorial inputs, following
the orchestrator's DECISIONS call; the board adds no rule captions.

Changed files: `src/ui/screens/combat_wave_motion.gd` (+UID), `combat_motion.gd`,
`combat_screen.gd`, `src/ui/widgets/card_view.gd`, `combat_face.gd`, `card_detail.gd`,
`tests/ui/test_combat_wave2a.gd` (+UID), `test_combat_face.gd`,
`test_pending_gains_ui.gd`, and this note. Combat pending-gain tests previously
asserted the numeric tag: they now require the visible hourglass, hidden numeric
combat tag, exact queued state, clear stat badges and exact open-reader values.
Dying-card checks likewise assert the mark and reader. Recruit chip/numeric-tag
checks remain intact; no word-chip check was weakened to mere absence.

All following targeted files pass, with the strict hook and no script errors or
risky/pending tests. Logs: `build/declutter/wave3-<file>.log`; detached job log:
`build/declutter/wave3-targeted-job.log` (`wave_targeted_complete`).

| Targeted UI test file | Tests passed | GUT time |
| --- | ---: | ---: |
| `test_combat_wave2a.gd` | 4 | 1.771s |
| `test_combat_face.gd` | 11 | 0.44s |
| `test_pending_gains_ui.gd` | 7 | 2.506s |
| `test_combat_declutter.gd` | 31 | 5.073s |
| `test_pass3_bog_ui.gd` | 5 | 0.981s |
| `test_review_bog_preview.gd` | 5 | 10.105s |
| `test_pass3_ui.gd` | 10 | 2.768s |
| `test_cards.gd` | 16 | 3.533s |
| `test_review_tribes56_log.gd` | 9 | 4.072s |

## Part 4: only the requested moments

Production UI source: `8bc24d65`. The selected capture reuses the serialized
baseline fight and its complete event stream; it does not rerun combat rules/RNG.
It discovers and replays the whole fight at fixed 1/120-second timesteps, verifies
identical event/attack ticks, automatic return and final hero Health, and saves
only the selected attack windows. Each has eight evenly spaced native 1688×780
viewport frames, assembled without scaling into a 6752×1640 sheet. This is the
same actual attack-to-next-attack interval sampling as the earlier packet. No
opening, focus, result or unrelated attack sheets were reshot in this packet.

| Run under `strips/four-visual-fixes/` | Sheets | Ancillary labels per frame |
| --- | ---: | ---: |
| `rival-fight-x1/attack-025.jpg` | 1 | 0–3 |
| `rival-fight-x4/attack-025.jpg` | 1 | 0–3 |
| `rival-fight-x1-reduce/attack-025.jpg` | 1 | 0–3 |
| `combat_mid-x1/attack-{036,045,069,075}.jpg` | 4 | 0–3 |
| `combat_mid-x4/attack-{036,045,069,075}.jpg` | 4 | 0–3 |
| `combat_mid-x1-reduce/attack-{036,045,069,075}.jpg` | 4 | 0–3 |

All **15 sheets / 120 frames** pass dimensions, eight-sample spacing (adjacent gaps
differ by at most one fixed tick), original event-stream equality and timing-pass
checks. The capture asserts the 10-node ancillary budget on every saved frame;
raw and budgeted counts are stored beside each frame in its manifest. Unit stats
and hero Health remain excluded, all other text nodes count. No text is hidden
for the budget. All before, earlier strips, matched stills, homecoming and verbatim
independent-review files remain unchanged. No new cold reader/scorer or full gate
was run. The orchestrator owns those next checks.

Changed files for Part 4: `tests/ui/shots/declutter_frames.gd`,
`tests/ui/shots/declutter_strips.py`, this note, `README.md`, plus these exact new
paths under `docs/ideation/evidence/declutter/batch1/strips/four-visual-fixes/`:

- `runs.json`
- `rival-fight-x1/manifest.json`, `attack-025.jpg`
- `rival-fight-x4/manifest.json`, `attack-025.jpg`
- `rival-fight-x1-reduce/manifest.json`, `attack-025.jpg`
- `combat_mid-x1/manifest.json`, `attack-036.jpg`, `attack-045.jpg`, `attack-069.jpg`, `attack-075.jpg`
- `combat_mid-x4/manifest.json`, `attack-036.jpg`, `attack-045.jpg`, `attack-069.jpg`, `attack-075.jpg`
- `combat_mid-x1-reduce/manifest.json`, `attack-036.jpg`, `attack-045.jpg`, `attack-069.jpg`, `attack-075.jpg`

The runner adds optional selected attack indices and `reduce-all`; omitting them
preserves the existing full-run behavior. The assembler accepts these explicitly
marked partial manifests. Synthetic complete/partial assembler checks, Python
compilation, source formatting/lint and whitespace checks pass. Successful real
renders exercise both selected invocation forms. No extra UI tests were added for
the reversible capture filtering.

Rerun from the worktree root after sourcing `/opt/bramble/env.sh`; the detached
shell runs its two Godot processes sequentially through the worker wrapper, with
no outer lock. The wrapper supplies the 3 GiB scope. Use a fresh output directory
to keep historical full-run evidence intact:

```sh
mkdir -p build/declutter
nohup bash -c '
set -e
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
scripts/godot_slot.sh xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 -s res://tests/ui/shots/declutter_frames.gd -- res://docs/ideation/evidence/declutter/batch1/before res://build/declutter/four-visual-frames rival-fight 25 reduce-all
scripts/godot_slot.sh xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 -s res://tests/ui/shots/declutter_frames.gd -- res://docs/ideation/evidence/declutter/batch1/before res://build/declutter/four-visual-frames combat_mid 36,45,69,75 reduce-all
python3 tests/ui/shots/declutter_strips.py build/declutter/four-visual-frames docs/ideation/evidence/declutter/batch1/strips/four-visual-fixes
' >build/declutter/four-visual-rerun.log 2>&1 &
```

Recorded detached service: `bramble-declutter-four-visual-capture.service`, exit 0.
Logs: `build/declutter/four-visual-{job,rival,combat,assembly}.log`; completion line:
`four visual capture: complete`. The screenshots use Xvfb and the real OpenGL
renderer because Godot's dummy headless renderer cannot supply viewport pixels.

## Part 5: narrow scope follow-up — transient kept gains

Orchestrator scope call (10 Nov): a dead recipient's retained recruit portrait is
an arrival cue, not a standing reserve. The gain travels to its portrait, lands,
holds briefly, then fades and is freed. There is one landing position per side;
simultaneous landings retire the preceding visible cue instead of forming columns.
The portrait reads `portrait_id`, falling back to `def_id`. Skip-to-end creates no
portrait on either `gain_pending` or `permanent_reward` paths. Exact queued state
remains in the model and reader. The two prior persistence assertions now require
fade/free; a 14-recipient stress test counts every ancillary label throughout the
sequence against the 10-label cap. Runtime results are recorded below once run.

### Lunge scope correction

The deeper overlap is restricted to joint attacks; ordinary lunges use factor
0.85. The Part 2 description above now states that scope explicitly.

### Bog Toll scope correction

The splash is transient and wordless; its arrival pulses the hero, then both
travel and landing cues fade. The total stays in the hero reader and final damage.
The regression checks both motion modes and verifies no plaque badge exists.

### Zero-gain Counter

Counter records its answering unit along with the previous attacker. That unit
starting its next attack clears the pending answer target, even when no stat gain
was emitted. A later unrelated gain cannot launch a stale red sword. A new test
checks this in normal and reduce motion; existing ordered self-gain tests remain.

### Pounce attack handoff

Pounce now uses the same directed red-sword answer cue as Counter and transfers
the gold attacker frame immediately to the pouncing unit. Its following real
attack event supplies the snap lunge (or source flash under reduce motion).
The test checks that the former attacker loses its frame and the pouncer moves.

### Mire wait target

The wait stamp now has a short-lived line from the waiting unit toward the exact
unit named by `mire_wait.target`. It appears with the stamp and fades within the
existing wait beat, in normal and reduce motion. The regression checks both
identities and that the line is freed. Mire's rule explanation stays for batch 4.

### Earlier cues at the next attack

The event queue was on time. In rival ×1, Sable's stat event 23 applies at tick
991 and its mote lands near 1048, but the route's hold/fade lasts until about
1138. The old barrier allowed attack 25 at 1075, so sample 1109 still showed
Sable's loop. The stats barrier now includes the complete route lifetime:
arrival delay plus 0.75 s of hold/fade. When multiple sources include the target,
the longer self-loop delay wins, regardless of source order. A new targeted file
requires the prior route, mote and landing to settle before the next attack at
×1, ×4 and reduce motion. Final-death settlement keeps its existing bypass.
This adds at most 0.6 s after the last stat cue; speed scaling remains batch 3.

### Narrow follow-up validation

Accepted validation runs use `GODOT_SLOT_CLASS=worker scripts/godot_slot.sh`, one process at a
time, with the strict post-run hook and writable temporary XDG directories.
Clean editor import and all five targeted files pass with no script/runtime errors:

| File | Tests | Assertions | GUT time |
| --- | ---: | ---: | ---: |
| `test_combat_declutter.gd` | 34 | 316 | 6.109 s |
| `test_combat_wave2a.gd` | 7 | 473 | 2.371 s |
| `test_combat_face.gd` | 11 | 179 | 0.439 s |
| `test_pending_gains_ui.gd` | 7 | 75 | 2.590 s |
| `test_combat_cue_lifetime.gd` (new) | 3 | 45 | 1.371 s |

Logs: `build/declutter/narrow4-*.log` and `narrow4cue-*.log`. GUT reports 1,173
orphans in the existing recruit-replay and simultaneous-Take tests; the new tests
report none. Scoped formatting/lint and whitespace checks passed. Full test-directory lint later found
the duplicate preload described below. No full gate or new cold
reader was run here. The committed reshoot cold-reader files are the orchestrator's
verbatim input on the earlier packet, not a claim about these new strips.

### Bog moments and final reshoots

`strips/bog-followup/` records one designed native-card fight generated once on
**d400831e**, seed **23**, and replayed unchanged before and after. Bridge Toad
(8/24) and The Prince Restored (3/20), recruit iids 41/42, face three Field Voles
(8/10, 2/3, 1/3). The 35-event stream contains real core events:

- **Bog Toll**, event 23 in attack window 017: the Prince sends 1 Toll to its hero,
  cumulative total 3.
- **Queued Soak gain**, `gain_pending` event 24 in window 017: the Prince queues
  +2/+2 while its fighting stats stay unchanged.
- **Kiss**, event 29 in attack window 025: the Prince gains its first of three pips
  after the Mired Field Vole dies.

Both heads have six sheets / 48 frames: those two windows at ×1, ×4 and reduce
motion. Their complete event-stream SHA-256 is identical, and each discovery pass
matches its own fixed-step render pass. Timing is allowed to change between heads.
Hero Health settles to 30/28 in every run. Manifests and `capture-report.json`
retain the moments, hashes, label counts, event ticks and source provenance.

`strips/narrow-followup/` contains the final requested ×1 and reduce-motion
reshoots: **rival 025** (Pounce handoff), **combat_mid 045** (Mire wait target), and
**rival 033**, explicitly labelled adjacent context showing Pounce's actual lunge.
Its six sheets / 48 frames replay the existing original saved fight streams.
The earlier packets are preserved. Every new sheet is 6752×1640, assembled from
eight native 1688×780 viewport samples spaced evenly at 1/120 s. Every saved frame
passes the 10-ancillary-label cap; unit stats and hero Health remain counted in
raw totals and excluded only from the established ancillary budget. No text is
hidden for capture. A fresh cold reader of this final packet remains the
orchestrator's next check.

Reproduce with `tests/ui/shots/declutter_bog_capture.sh` and
`declutter_bog_narrow_capture.sh`; both run Godot sequentially through the worker
wrapper and use the same discovery/replay/assembly path as the preceding strips.

An initial failed fixture probe survived an attempted cancellation until its timeout
and briefly overlapped regeneration. The accepted render passes ran sequentially;
`strips/bog-followup/process-history.md` records the exact overlap and timing.
No Godot process remains.


## Gate correction: complete test-directory lint

The earlier 'lint passes' wording referred to scoped source/file checks. Running
`(cd tests && gdlint .)` found a duplicate inline preload of `combat_attack_cue.gd`
in the Pounce regression (line 863), already used at line 497. Both now use one
`AttackCue` constant at the top of the file. No behavior or evidence changes.
The full requested static-check results are recorded with this follow-up below.

## Cue retirement replaces the added stats wait

The stats tail barrier is restored from arrival + 0.75 s to arrival + 0.15 s.
At the next animated attack or Mire wait, every older animation callback is
cancelled. Existing transient pictures are frozen in a separate retirement layer
and fade in **0.08 s**, without holding up the new action. This covers all old
routes and motes, including Toll and pending gains, source rings, dead-source
portraits and old damage pops. Canonical model state is synced into surviving
cards before the new action; queued rewards never become fighting stats.
Restart/skip clear the retiring layer too. No long-tail speed scaling change.

`test_combat_cue_lifetime.gd`: **8/8, 1162 assertions, 6.457 s**, strict hook clean,
no script errors or orphan warnings. The original three assertions remain, with
30 real cause/boundary/motion cases checking frozen routes/motes, the visible
half fade, deletion inside 0.1 s, no late Toll/pending callbacks and exact state;
18 cadence cases ensure the long tail adds no wait. Logs are in
`build/declutter/retire-test_combat_cue_lifetime.log` (or the focused lifetime log).
Before/cleanup-only/final-reader timing measurements are recorded separately so
new reader cues do not get attributed to this pacing correction.


### Whole-fight timing, before and after cue retirement

Two deterministic 120 Hz passes per case, measured at `62c6cc76` (old barrier)
and `bda3f1d2` (cleanup only), including automatic return:

| Fight | Speed | Before | Cleanup only | Saved |
| --- | --- | ---: | ---: | ---: |
| Bog | ×1 | 9.833333 s | 9.725000 s | 0.108333 s |
| Bog | ×4 | 6.558333 s | 5.641667 s | 0.916666 s |
| combat_mid | ×1 | 27.333333 s | 25.766667 s | 1.566666 s |
| combat_mid | ×4 | 22.000000 s | 20.200000 s | 1.800000 s |

Source events, their order, final model hashes and final hero Health match in
every pair. `strips/cue-retirement/before-timings.json` and
`after-cleanup-timings.json` preserve these measurements independently of the
subsequent reader-cue changes. The accepted d400831e before images are unchanged.


### Reader 5 follow-up: amounts, destinations and waiting actor

The orchestrator supplied the independent `reader5/score.md` and `answers.md`
from `ideation/main`. Its Toll, queued gain, kiss and Mire answers failed at ×1
and reduce motion. The moving cues now address those specific ambiguities:

- Toll carries its event amount, then briefly pops it at the hero. This distinguishes
  the current `+1` from the cumulative Toll retained in the hero reader.
- Pending gain launches one short beat after Toll and briefly shows the pending
  total on the live tag (`+2/+2` in Bog 017). Fighting stats remain unchanged.
  The rulebook already says “A fight shows the amounts pending”; no second wording
  change was needed. These labels disappear with the event and add no standing mark.
- A kiss begins at the dead unit's canonical board pocket, including when death
  interrupts a lunge. Its heart lands on the newly filled crown pip, which pulses.
  Travel fits the existing kiss beat at ×1/×4; the full portrait no longer pulses.
- Mire wait puts the gold frame on the waiting actor and uses the standard directed
  route with a destination arrowhead. The short line and stamp fade within the beat.
- Death clears that actor's gold frame, including direct/skip playback, while
  preserving any surviving joint actor's frame.
- Toll routes, pending sparks/amounts and Prince pip rings all use the screen's
  deterministic overlay clock. The next attack or Mire wait retires them in 0.08 s.
  No additional scheduler barrier or wait was introduced for these reader fixes.

Focused coverage is in `test_combat_wave2a.gd`, `test_combat_reader5_motion.gd`
and `test_combat_cue_lifetime.gd`; final results and reshot manifests follow below.
