# Batch 1 evidence: fights read by motion

Baseline source: `1ecbce6` (`ideation/main`). Implementation branch: `ideation/declutter`.
All Bramble captures are native viewport images; no third-party screenshots are committed.

## Matched stills and label counts

`before/` holds fresh captures from an isolated `git archive 1ecbce6` checkout.
The capture hook also saves the complete combat event stream, side names, bottom side,
opponent Health, exact `next_index`, full combat result, post-fight state, exact before/after hero Health and exact
floor marks observed at the fight-input boundary. `declutter_stills.gd` replays that saved checkpoint
through the new UI for the corresponding `after/` image. Rules and RNG are never rerun
between the two sides of a pair. The reminder pair's after image has the reader closed,
so that the resting combat state is visible; the reader interaction is tested separately.

The `*.json` beside each before image records every visible nonempty `Label`,
`RichTextLabel` and text-bearing `Button` in the combat subtree. Hidden ancestors exclude
their descendants. Canvas text below 0.05 opacity is excluded. Buttons whose semantic
text is hidden behind a `drawn_face` count only their rendered child labels, avoiding
double-counting. Numbers count as labels. Custom drawn digits are not text nodes.
The after runner prints `labels before=N after=M` for every pair and writes `after/pairs.json`.
The combat budget is 30. All eight pairs pass; the largest after count is 28.

| Scenario | Original scripted source / seed | Before / after labels |
| --- | --- | --- |
| `wording2/combat_mid` | `screenshot.gd`, `20261104` plus first surviving offset, six bot rounds | 88 → 28 (both sizes) |
| `reminder/combat_reminder` | same driver and seed, first keyword reminder | 89 → 28 (both sizes) |
| `wave1/homecoming-following-combat` | `wave1_evidence.gd`, seed `109` (first mixed shop from 101–140), controlled production actions | 82 → 24 (both sizes) |
| strong-field `rival-fight` | committed seed `72`, round `8` boundary input replay | 91 → 26 (both sizes) |

## Reproduce the captures

All Godot processes run sequentially under the shared lock and 3 GiB scope.
Launch long jobs detached and inspect `build/declutter/*.log` with short commands.

```sh
source /opt/bramble/env.sh
mkdir -p build/declutter
nohup bash -c 'flock /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G bash tests/ui/shots/declutter_baselines.sh /tmp/bramble-declutter-baseline "$PWD/docs/ideation/evidence/declutter/batch1"' >build/declutter/baselines.log 2>&1 &
```

The baseline runner archives `1ecbce6` to `/tmp`, injects only an evidence hook into the
existing shot scripts and a passive observer into the isolated UI adapter, imports
and compiles that project, then renders both requested sizes. The observer only
records input and chains any original observer; it changes no rules or outcomes.
It does not check out, merge, rebase or push any branch. Individual process logs are in
`build/declutter/baseline-logs/`.

After the baseline finishes:

```sh
nohup bash -c 'export LP_NUM_THREADS=1; flock /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 -s res://tests/ui/shots/declutter_stills.gd -- res://docs/ideation/evidence/declutter/batch1/before res://docs/ideation/evidence/declutter/batch1/after' >build/declutter/after.log 2>&1 &
```

## Cold-reader criterion for this batch

The owner confirmed a **source/effect** check for Batch 1. A cold reader should be
able to identify who moved or flashed, who received the hit or change, and what
visibly happened, including the visible cause of a death. It is not required to
reconstruct an unstated unit ability or name an unfamiliar keyword from the strip.
The same source/effect standard applies to ×4 and reduce motion. The refreshed-image
check **passes** under this owner-approved criterion; no source/effect uncertainty
remains in the reviewed attacks.

The [cold-reader audit](cold-reader-review.md) records the original observations
and four unresolved source attributions that prompted the final motion fixes. Its
refreshed-image addendum confirms the source/effect fixes. The review also exposed
Rules/tutorial input for Batch 4:

- Snap, Quarry and Swoop targeting exceptions, including the surviving-front-row case.
- Which units qualify to join a Pack attack and when their attack is spent.
- Take rewards, growth and acorn cues.
- Counter's temporary Attack changes.
- Sable and Pounce trigger conditions.
- Belly release and Aura stat changes.

These rule explanations belong in the tutorial, Rules pages and reader. The combat
screen communicates their sources and effects through motion without adding text.

## Frame strips

The animation runner uses `manual_playback=true` and calls `advance_playback(1/120)`
with an explicit fixed timestep. It listens to `attack_started(index, duration)` and
captures eight viewport frames at ticks nearest to `j * duration * 120 / 7`, for `j=0..7`.
This includes the first and final attack frame; the exact ticks are recorded in the manifest.
Each run starts from the same serialized fight stream at ×1 and ×4, with no wall-clock
sleep driving the animation. The viewport is always `1688×780`. Original frames remain
in `build/declutter/frames/`; committed contact strips contain those native-size frames.
There are 11 attacks in the wording fight, four in homecoming and eight in the rival
fight, each at ×1 and ×4, plus 11 wording attacks under reduce motion: 57 sheets
and 456 viewport frames across seven runs.
The runner also captures a reduce-motion replay of one of the same three fights.
Run the strip capture and assembly after the stills (one Godot process at a time):

```sh
nohup bash -c 'export LP_NUM_THREADS=1; flock /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 -s res://tests/ui/shots/declutter_frames.gd -- res://docs/ideation/evidence/declutter/batch1/before res://build/declutter/frames' >build/declutter/frames.log 2>&1 &
```

Wait for `all deterministic frame captures complete` in `frames.log`, then assemble:

```sh
/usr/bin/python3 tests/ui/shots/declutter_strips.py build/declutter/frames docs/ideation/evidence/declutter/batch1/strips
```

`declutter_after.sh` also runs compilation, stills, frames and assembly sequentially
when launched under the same detached lock/scope wrapper.
Each attack sheet contains four columns by two rows of native-size frames; the small
outer captions identify only frame number and elapsed time. Event manifests are kept
separate from the blind cold-reader input. They contain the source events for checking
the reader's answers after it has read the strips.

**Renderer adaptation:** Godot's `--headless` display uses a dummy renderer and cannot
provide viewport pixels. These are unattended fixed-step runs under Xvfb with the real
OpenGL renderer. This preserves deterministic simulation and native viewport capture.

## Baseline capture adaptations

Scripted scenarios and seeds are unchanged. Each fight is generated once, then the
archived UI applies events synchronously with animation disabled to the saved exact
checkpoint. Two rendered frames settle layout. This captures resting presentation
without spending hundreds of software-rendered frames advancing to the checkpoint.
Both sizes and their after images reuse that same complete event stream. The
reminder snapshot opens the original card's first keyword reminder.

The wave1 driver uses the current Cluricaun growth (`ring_size > 1`) and checks the
Swallow's returned stats against its recorded preflight stats times two. Its old
literal `1.25` growth assertion no longer holds on `1ecbce6`; the `14`/`16`
return checks are also expressed from actual preflight stats instead of assumed stats.
The unchanged mixed-shop search selects seed `109` on this revision.
All original gameplay actions remain; only the required homecoming image
is rendered. Unrelated reader word-count audits are omitted from this capture job.

If an earlier checkpoint lacks raw boundary metadata, `declutter_seed_input.gd`
runs the same seed and six bot rounds without rendering, requires canonical
identity of the complete event stream, then attaches the exact captured input,
floor marks and before/after hero Health. It refuses to repair a different fight.

## Spec rows adapted or skipped

- **Strong-field baseline:** the old `rival-fight` screenshots used a v1 field library
  that the current code rejects, and no current bundled player library exists. Rather
  than synthesize opponents or use the profiling-only measurement library, the shot
  replays the committed seed-72 round-8 combat boundary record through `1ecbce6`'s
  current combat rules, restoring both RNG states, slots, hero effects and side rules.
  The `field_mode_enabled` flag is on. The exact generated stream is reused for after.
- **Headless strips:** Xvfb plus the real renderer replaces Godot's dummy `--headless`
  renderer for viewport capture; timing remains an explicit fixed timestep.
- **Hex slip:** the current engine can maintain both flat and percentage Hex totals
  on one pocket. The combat corner stacks `−3` and `−25%` beside one sigil, at
  `MIN_FONT`, instead of collapsing them into the spec's single `−N`.

- **Speed token:** one, two or four chevrons replace `×1`/`×2`/`×4` text. Tap still
  cycles 1/2/4 and saves `Settings.fight_speed`; the numeric value remains in Settings.
  This keeps a full 14-unit board at 28 stat labels plus two hero Health labels = 30,
  while retaining both hero Health values.
- **2.1 stored counter pips:** current combat snapshots expose held counts but not
  recruit's stored Hex/ammo/Bitter values. The face accepts those fields when supplied;
  it omits unknown counters. Authored rules remain in the reader and the actual effect
  changes the stat bead. Supplying exact changing stored values needs a future view
  boundary extension; the UI does not infer rules or invent initial values.
- **Initial kisses:** combat snapshots do not expose an initial kiss count. The face
  shows the three pips once an event supplies a known count, rather than displaying
  invented progress. The pre-event initial-count portion of this row is not supplied
  by the current UI boundary.
- **Ring/Nest input metadata:** old ordinary combat results omitted some floor state.
  The UI adapter now observes the exact existing fight boundary and attaches floor
  marks, without changing core events or rules. The baseline runner installs the same
  passive observation in its isolated copy, so no marks are guessed from stat totals.
- **Historical rival Health:** the committed field boundary records hero identities
  and fight inputs, but not both heroes' pre-round-8 Health. The opponent's `40` is
  a fixed UI capture parameter used in both before and after, not a claim of observed
  round-8 Health. The unknown own Health stays hidden. Ordinary production and the
  other matched scenarios use exact before-fight Health observed at the combat boundary.

- **Animation 28 / no room:** the event can describe a held release, Bird, Nest or
  Peatling as well as a Mouse. The refused summon uses its actual `def_id` portrait
  for the same pop, tray bump and puff, instead of always showing a Mouse.
- **Animation 25 / cancelled:** some cancel events provide only the cancelled
  attacker's UID. The mote goes to the current defender when known, otherwise to
  the cancelled unit's last model pocket, then fizzles.

- **2.1 zone scope and names:** this batch changes combat faces. The counterpart
  recruit/shop tile chips, names and tier treatment remain for Batch 2. Combat names
  are removed even for shared portraits to meet this batch's explicit wordless-rest
  requirement; a tap/hover reader retains the name and full text.
- **2.6 log identity:** names are the default. Slot suffixes are added only where
  same-named units need disambiguation; the full-height log supplies the brick legend.
- **Animations 7–8, 10–11 and 13:** the shared existing burst/spark/fang/puff/leaf
  vocabulary carries damage, Shield breaks, Bristle, reduction and death. Bursts fade
  in place rather than drifting 16 px, and Bristle uses the directional fang graphic
  rather than a new three-thorn particle. This keeps the smaller Health-bead cue and
  visible cause without introducing another effect asset system.
- **Animations 2 and 7 / Pack damage:** Pack joiners keep their staggered motion,
  but damage to the same recipient uses one accumulating burst. Separate starbursts
  at the same bead obscured the total; the combined pop shows the received amount.
  Core hits and joiner order remain unchanged. Peck strikes retain separate pops.
- **Animation 14:** source glyph pulses/hops and target motes use the existing acorn
  colour vocabulary rather than new per-tribe colours or a separate whole-board
  ripple. Source-to-recipient travel and bead changes remain the causal cue. Aura changes
  use the actual UID sources supplied in `causes`; those sources flash and send
  motes. Self changes pulse the source glyph and body. The first attack waits for
  pending stat rolls so the visible Attack value agrees with the attack.
- **Animation 16:** the custom-drawn status layer appears in its end state and the
  tile flashes in the status colour, rather than independently scaling every mark.
  The layer deliberately supports simultaneous statuses without extra slip nodes.
- **Animations 17–19:** the existing bell/paw/splash icons supply compact event cues:
  bell glint rather than a twice-swinging bell, one travelling paw rather than three
  print stamps, and splash-to-mud rather than a separately animated mud mesh.
  The resulting paw and mud remain state, with no links or words.
- **Animation 21:** the stake appears when the slot is marked and the normal damage
  pop shows a trap hit. There is no separate stake-spring tween; the existing event
  stream supplies a marked slot followed by damage rather than a distinct trap-entry
  presentation event.
- **Animation 23:** a spark travels between the victim and taker glyph positions;
  the rules update removes/replaces the victim glyph. The shared mote represents
  transfer instead of peeling a separate copy of the exact glyph texture.
- **Animation 29:** arrivals share source-origin growth/travel, using the source's
  retained model pocket when its tile has died and the tray edge when no source is
  supplied. Borrowed units use the actual relocate events into and out of the enemy
  tray. This avoids inventing a source that the event does not identify.
- **Animation 31:** all survivor sparks launch together; production Health uses the
  exact boundary observations. Starting-side identity survives temporary loans, so
  those sparks represent the correct starting survivors. A zero round base sends no
  base spark. Rewards after the final death coalesce into the outro; a timing test
  keeps return within 1.6 seconds of that death. Last Stand is a gold ring flash
  rather than snapping an already-visible ready ring on the compact combat plaque.
  Return remains automatic and tappable; no result text or Continue step is restored.
- **2.6 Watch again:** replay from the recruit plaque's reader reuses the last fight
  without appending the round to `round_log` again. Watching cannot duplicate history
  or the game-over record.

The remaining fight rows use their proposed functional cue: 1 lunge; 2 staggered
joiners; 3 immediate snap; 4 Cleave sweep; 5 per-strike Peck jabs; 6 real target;
9 berry then Health loss; 12 Bitter before contact; 15 rolling/popping beads;
20 Hex transfer; 22 gulp; 24 whistle; 26 skip/Bide; 27 tray dip;
30 heart/pips/flip; and 32 reward coin. The three sampled fights do not exercise
every rare cue, so the strips are evidence for those fights rather than a claim
that every row has been independently cold-read.

## Changed files

Every changed or added file relative to `1ecbce6`, including generated UID sidecars
and each evidence image/manifest, is listed below. Ignored local comparison images
and build logs are excluded from git.

- `docs/ideation/DECISIONS.md`
- `docs/ideation/evidence/declutter/batch1/README.md`
- `docs/ideation/evidence/declutter/batch1/after/combat_mid_1688x780.png`
- `docs/ideation/evidence/declutter/batch1/after/combat_mid_1920x1080.png`
- `docs/ideation/evidence/declutter/batch1/after/combat_reminder_1688x780.png`
- `docs/ideation/evidence/declutter/batch1/after/combat_reminder_1920x1080.png`
- `docs/ideation/evidence/declutter/batch1/after/homecoming-following-combat_1688x780.png`
- `docs/ideation/evidence/declutter/batch1/after/homecoming-following-combat_1920x1080.png`
- `docs/ideation/evidence/declutter/batch1/after/pairs.json`
- `docs/ideation/evidence/declutter/batch1/after/rival-fight_1688x780.png`
- `docs/ideation/evidence/declutter/batch1/after/rival-fight_1920x1080.png`
- `docs/ideation/evidence/declutter/batch1/before/combat_mid_1688x780.json`
- `docs/ideation/evidence/declutter/batch1/before/combat_mid_1688x780.png`
- `docs/ideation/evidence/declutter/batch1/before/combat_mid_1920x1080.json`
- `docs/ideation/evidence/declutter/batch1/before/combat_mid_1920x1080.png`
- `docs/ideation/evidence/declutter/batch1/before/combat_reminder_1688x780.json`
- `docs/ideation/evidence/declutter/batch1/before/combat_reminder_1688x780.png`
- `docs/ideation/evidence/declutter/batch1/before/combat_reminder_1920x1080.json`
- `docs/ideation/evidence/declutter/batch1/before/combat_reminder_1920x1080.png`
- `docs/ideation/evidence/declutter/batch1/before/homecoming-following-combat_1688x780.json`
- `docs/ideation/evidence/declutter/batch1/before/homecoming-following-combat_1688x780.png`
- `docs/ideation/evidence/declutter/batch1/before/homecoming-following-combat_1920x1080.json`
- `docs/ideation/evidence/declutter/batch1/before/homecoming-following-combat_1920x1080.png`
- `docs/ideation/evidence/declutter/batch1/before/rival-fight_1688x780.json`
- `docs/ideation/evidence/declutter/batch1/before/rival-fight_1688x780.png`
- `docs/ideation/evidence/declutter/batch1/before/rival-fight_1920x1080.json`
- `docs/ideation/evidence/declutter/batch1/before/rival-fight_1920x1080.png`
- `docs/ideation/evidence/declutter/batch1/cold-reader-packet.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-review.md`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-021.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-026.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-031.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-036.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-045.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-054.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-058.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-062.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-069.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-075.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/attack-080.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-021.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-026.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-031.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-036.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-045.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-054.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-058.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-062.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-069.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-075.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/attack-080.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-021.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-026.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-031.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-036.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-045.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-054.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-058.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-062.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-069.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-075.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/attack-080.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/attack-020.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/attack-026.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/attack-030.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/attack-033.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/attack-020.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/attack-026.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/attack-030.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/attack-033.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-025.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-033.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-039.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-043.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-047.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-054.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-058.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-062.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-025.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-033.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-039.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-043.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-047.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-054.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-058.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-062.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/runs.json`
- `src/ui/adapter/core_port.gd`
- `src/ui/app.gd`
- `src/ui/screens/combat_lanes_view.gd`
- `src/ui/screens/combat_log.gd`
- `src/ui/screens/combat_model.gd`
- `src/ui/screens/combat_motion.gd`
- `src/ui/screens/combat_motion.gd.uid`
- `src/ui/screens/combat_screen.gd`
- `src/ui/screens/combat_special_motion.gd`
- `src/ui/screens/combat_special_motion.gd.uid`
- `src/ui/screens/fight_log_page.gd`
- `src/ui/screens/fight_log_page.gd.uid`
- `src/ui/screens/how_to_play.gd`
- `src/ui/screens/recruit_layout.gd`
- `src/ui/screens/recruit_screen.gd`
- `src/ui/screens/settings_screen.gd`
- `src/ui/widgets/board_view.gd`
- `src/ui/widgets/card_view.gd`
- `src/ui/widgets/combat_face.gd`
- `src/ui/widgets/combat_face.gd.uid`
- `src/ui/widgets/icons.gd`
- `src/ui/widgets/lane_overlay.gd`
- `src/ui/widgets/pause_menu.gd`
- `src/ui/widgets/slot_marks.gd`
- `src/ui/widgets/slot_view.gd`
- `tests/ui/shots/declutter_after.sh`
- `tests/ui/shots/declutter_baseline_replay.gd`
- `tests/ui/shots/declutter_baseline_replay.gd.uid`
- `tests/ui/shots/declutter_baselines.sh`
- `tests/ui/shots/declutter_capture.gd`
- `tests/ui/shots/declutter_capture.gd.uid`
- `tests/ui/shots/declutter_compare.py`
- `tests/ui/shots/declutter_frames.gd`
- `tests/ui/shots/declutter_frames.gd.uid`
- `tests/ui/shots/declutter_rival.gd`
- `tests/ui/shots/declutter_rival.gd.uid`
- `tests/ui/shots/declutter_seed_input.gd`
- `tests/ui/shots/declutter_seed_input.gd.uid`
- `tests/ui/shots/declutter_stills.gd`
- `tests/ui/shots/declutter_stills.gd.uid`
- `tests/ui/shots/declutter_strips.py`
- `tests/ui/shots/playthrough.gd`
- `tests/ui/shots/strong_field.gd`
- `tests/ui/test_cards.gd`
- `tests/ui/test_combat_declutter.gd`
- `tests/ui/test_combat_declutter.gd.uid`
- `tests/ui/test_combat_face.gd`
- `tests/ui/test_combat_face.gd.uid`
- `tests/ui/test_combat_pockets.gd`
- `tests/ui/test_combat_pockets.gd.uid`
- `tests/ui/test_combat_relocate.gd`
- `tests/ui/test_engines.gd`
- `tests/ui/test_feedback5_log.gd`
- `tests/ui/test_field_presentation.gd`
- `tests/ui/test_followup_tribes56.gd`
- `tests/ui/test_lane_display.gd`
- `tests/ui/test_pass2_ui.gd`
- `tests/ui/test_phone_layout.gd`
- `tests/ui/test_playthrough.gd`
- `tests/ui/test_review_tribes56_log.gd`
- `tests/ui/test_round4_finish.gd`
- `tests/ui/test_round4_guide.gd`
- `tests/ui/test_scale_feedback.gd`

## Validation

- Baselines: all eight native viewport images and serialized checkpoints complete; isolated compile: 534 files, zero failures.
- After pairs: all eight complete; counts 28/28/24/26 at both sizes, all within the 30-node budget.
- Main compile preflight: 543 files, zero failures.
- Final UI preflight: 374/374 tests pass across 50 scripts, 13,854 assertions; no
  script errors, failed tests or GUT warnings appear in the log.
- Strips: seven complete runs, 57 attack sheets, 456 native frames. All eight samples per attack match the scheduled ticks exactly; adjacent gaps differ by at most one 1/120-second tick due to rounding. All frame dimensions verified at 1688×780.
- Cold-reader source/effect check: **PASS** under the owner-approved criterion; the
  refreshed-image check leaves no source/effect uncertainty. Reviewers received only
  the packet and image strips. The original review and refreshed observations are
  retained in [cold-reader-review.md](cold-reader-review.md); Batch 4 rule inputs remain above.
- Full gate `./scripts/check.sh`: **PASS**. All eleven steps pass: tools, versions,
  shell, Python, content, format, lint, import, compile, parity and tests. The final
  GUT run passes **1,901/1,901 tests across 181 scripts, 42,217 assertions**; its strict
  hook reports no risky or pending tests. Log: `build/declutter/gate-final.log`.
  Final line: `check.sh: all steps passed`.

## Local commits before the final evidence commit

- `a7970ef0 test(ui): add reproducible declutter baseline capture`
- `ecd2c3de feat(ui): add wordless combat tile faces`
- `cce4fa21 feat(ui): replace combat pocket labels with state marks`
- `ef6d50c2 feat(ui): cut standing reminders and expose last fight from reader`
- `ae362300 feat(ui): make combat read through motion and return automatically`
- `83892383 fix(ui): align combat cues with causes and reader state`
- `274efdce test(ui): capture matched declutter baselines and deterministic replay tools`
- `14e671d4 fix(ui): keep fight log identity details on demand`
- `6fafc073 fix(ui): make effect origins and combined hits readable`
- `eb54936d test(ui): keep animation assertions strictly typed`

## Standing comparison sheet (local only)

The reference cache used by the earlier [visual comparison](../visual-comparison.md)
is still available. The same-phase primary sheet puts Bramble's after combat beside
Battlegrounds combat and Once Upon a Galaxy combat. Hearthstone action and a TFT board
are secondary panels; the TFT image has a marketing mascot overlay and its phase is
uncertain, so it is not treated as an exact combat comparison. The Battlegrounds full
combat image is an older 2023 capture; it is a layout reference, not a claim about the
current patch. No new visual-tier score is assigned in Batch 1 (the spec schedules that
after Batches 2 and 4).

Generate the sheet outside tracked evidence:

```sh
/usr/bin/python3 tests/ui/shots/declutter_compare.py docs/ideation/evidence/declutter/batch1/after/combat_mid_1688x780.png /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual build/declutter/comparison-local.jpg
```

Only the script, written observations and source links are committed. The composite
and all third-party images stay in ignored `build/` or `/tmp`.

| Reference | Visible structure relevant to Batch 1 | Source |
| --- | --- | --- |
| Battlegrounds combat | Eight unit tokens with two stats each; two hero portraits; no target links or combat prose panel; temporary hit stars | [Combat Phase screenshot](https://hearthstone.wiki.gg/images/Combat_Phase.png) |
| Once Upon a Galaxy combat | Ten unit faces with stats, names and small keyword tags; damage stars; one large inspector beside the board | [Steam combat screenshot](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/3062740/fd83f857e6552aaab5264488a156dccb12a584be/ss_fd83f857e6552aaab5264488a156dccb12a584be.1920x1080.jpg) |
| Hearthstone action | Five unit tokens, two stats each; visible spell effects and compact history icons; no standing target arrows or log prose | [App Store screenshot](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/17/2d/11/172d11da-8a89-5c59-2d2c-ed56edb1ea00/ef332d11-0726-4b38-9341-b1bce4661ab0_HS_AppStore_Updates_Screenshot_6_2688x1242_RN01.jpg/1600x739bb.jpg) |
| TFT board (secondary) | Eight visible champions with Health bars and item/star marks; no names on the board; mascot overlay obscures part of the HUD | [App Store screenshot](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/8f/4a/c7/8f4ac724-1720-cac4-f295-6d529d760215/TFT_ST1826_ASO_ScreenshotUpdates_04_2208x1242_UPDATED_v002_SCha.png/1600x900bb.jpg) |

The Bramble after sheet shows 13 unit faces, 26 stat beads, two hero portraits with
Health, and four icon controls. The counter reports 28 visible numeric text nodes.
There are no words, relation links, keyword glossary or hit/log prose panels on the
resting combat board. This directly removes the standing explanation layer that
occupied the earlier comparison's left side. The existing art and wood palette stay
consistent; the motion strips, rather than this still, judge attack causes.
The prior comparison estimated about 30 visible labels in
Battlegrounds combat and about 55 in Galaxy combat. Those were manual screenshot
estimates; Bramble's new gate measures actual visible text nodes, so the numbers are
reported separately rather than treated as identical instruments.
