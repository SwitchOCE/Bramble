# Batch 1 evidence: fights read by motion

Baseline source: `1ecbce6` (`ideation/main`). Implementation branch: `ideation/declutter`.
All Bramble captures are native viewport images; no third-party screenshots are committed.

**Current checkpoint:** after the orchestrator's integration merge `55e0d8b0`,
`7b7a5fb7` fixes directed Aura, both Pack lunges, retained gains and Counter answers;
`8bc24d65` ports wave 2a state into wordless combat cues. The merged-tree compile
loads 596 files with zero failures. Targeted tests and their individual times are
recorded in [the four-part integration follow-up](merge-wave2a-followup.md).
No full gate or new cold reader was run. The orchestrator will gate the tip in CI
and independently read only the selected moments.

The [latest independent answers](cold-reader-third-repair-answers.md) and
[score](cold-reader-third-repair-score.md) for `28c873e3`/`f6713034` are copied
verbatim. The orchestrator's DECISIONS call separates four visual repairs from
Batch 4 rule-knowledge inputs. The current reshoot is under
[`strips/four-visual-fixes/`](strips/four-visual-fixes/): rival 025 and combat_mid
036/045/069/075 at ×1, ×4 and reduce motion, **15 sheets / 120 native frames**.
Every captured frame has **0–3 ancillary text nodes (cap 10)**. Earlier strips and
matched pairs remain unchanged; they are historical evidence for their recorded
checkpoints. The next independent source/effect result is pending.

Files changed since the integration merge are listed per part in the follow-up.
New files beyond the inventory below are `src/ui/screens/combat_wave_motion.gd`
and its `.uid`, `tests/ui/test_combat_wave2a.gd` and its `.uid`, the follow-up note,
and the new six-run strip packet (15 JPEGs, six manifests and `runs.json`).

**Previous checkpoint:** `28c873e3` addresses the three remaining requested readings:
relay transit, Mire wait and Counter's self-stat source. The detached targeted UI
gate passes **396/396 tests**, 51 scripts and 14,006 assertions, with the strict hook
passing (`build/declutter/attribution-ui.log`). No new cold reader or scoring was run;
the orchestrator will read these strips independently. Batch 1 remains open. The
1,919-test full gate and third independent read below are historical results for
the preceding checkpoint, not validation of this follow-up. The full gate belongs
on the orchestrator's merged tree.

## Requested attribution follow-up

The relay now has a faint complete source-to-destination route while its mote is
in flight, with a stronger moving trail. Its arrowhead and recipient flash appear
only on arrival; the recipient's gained-status drawing also waits until then.
Crossing an intermediate pocket therefore produces no landing cue there. Reduce
motion keeps a static route and likewise delays the landing cue.

Mire wait clears the previous attack frame and waits for the preceding hit and
reward to settle. It then has its own 0.9-second action beat: a self-pulse and a
crossed-sword stamp, with a short windup/settle in normal motion and a held static
stamp under reduce motion. Counter's self-stat change likewise waits for the hit
to settle, starts with its own pulse, then takes an outside-card loop to its own
changed bead (0.12-second source lead, 0.35-second transfer, then number roll).
Counter's immediate-attack declaration no longer draws an inter-card gold link;
its subsequent attack still has the ordinary attacker cue and lunge. Last-death
settlement retains the existing automatic-return timing constraint.

Only six matched after images were reshot: `combat_mid`, `combat_reminder` and
`rival-fight`, each at 1688×780 and 1920×1080. Their resting pixels and label counts
are unchanged. Five strip runs were reshot: `combat_mid-x1`, `combat_mid-x4`,
`combat_mid-x1-reduce`, `rival-fight-x1` and `rival-fight-x4`: 124 sheets / 992 frames.
Before captures and
both homecoming runs are retained. The previous independent C/W findings remain
below as history; this follow-up makes no new cold-reader PASS claim.

Key affected sheets are `rival-fight-x1/opening-event-009.jpg` and its ×4 counterpart
(relay), and `combat_mid-*/attack-045.jpg`, `attack-069.jpg` and `attack-075.jpg`
(wait and self-stat changes). All paths are under `strips/`; the complete opening,
attack and result sheets remain available for context.

Files changed in this follow-up: `src/ui/widgets/combat_effect_path.gd`,
`src/ui/screens/combat_motion.gd`, `src/ui/screens/combat_special_motion.gd`,
`src/ui/screens/combat_screen.gd`, `tests/ui/test_combat_declutter.gd`,
`tests/ui/shots/declutter_frames.gd`, `tests/ui/shots/declutter_stills.gd`, this README,
`after/pairs.json`, and the five selected strip directories' JPEGs/manifests. The
complete batch inventory remains below. Four UI tests cover intermediate transit,
the separate wait beat, Counter's self-source, and status drawing/flash at arrival.

The existing capture commands accept an optional final comma-separated scenario
filter. For this follow-up append `combat_mid,combat_reminder,rival-fight` to the
stills command and `combat_mid,rival-fight` to the frames command. The latter emits
×1 and ×4 for both fights plus reduced-motion `combat_mid`. Selective stills merge
only the selected entries into `after/pairs.json`; all checkpoints/seeds, fixed-step
sampling and sheet assembly are as documented below. Logs are
`build/declutter/attribution-{pairs,frames,assembly}.log`; the detached job log is
`build/declutter/attribution-job3.log`.

The targeted gate uses a UI-only GUT configuration (all UI subdirectories and the
strict post-run hook). To rerun it detached after sourcing `/opt/bramble/env.sh`:

```sh
mkdir -p build/declutter
cat >build/declutter/ui.gutconfig.json <<'JSON'
{"dirs":["res://tests/ui"],"include_subdirs":true,"prefix":"test_","suffix":".gd","should_exit":true,"log_level":1,"hide_orphans":false,"post_run_script":"res://tools/checks/gut_strict_hook.gd"}
JSON
nohup /tmp/bramble-godot-slot systemd-run --user --scope -q -p MemoryMax=3G godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://build/declutter/ui.gutconfig.json >build/declutter/attribution-ui.log 2>&1 &
```

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
double-counting. Raw counts include numbers; custom drawn digits are not text nodes.
The revised budget is **at most 10 ancillary visible text nodes**: unit Attack/Health
and hero Health are excluded, and every other visible text node counts, including
held counts, Hex/trap numbers, names and transient damage numbers. Primary labels
are explicitly tagged rather than excluded by whether their text looks numeric.
`test_combat_declutter.gd` enforces this definition and checks that pocket and held
numbers still count. The after runner prints raw before/after and ancillary counts
for each pair and writes `after/pairs.json`.

All eight regenerated pairs pass the revised 10-node budget. The raw totals remain
visible alongside the budgeted counts; both requested viewport sizes give the same counts.
The baseline recount only added primary-stat metadata: all eight before PNG SHA-256
hashes are unchanged from the committed baseline.

| Scenario | Original scripted source / seed | Raw before → after | Ancillary before → after (cap 10) |
| --- | --- | --- | --- |
| `wording2/combat_mid` | `screenshot.gd`, `20261104` plus first surviving offset, six bot rounds | 88 → 28 | 61 → 0 |
| `reminder/combat_reminder` | same driver and seed, first keyword reminder | 89 → 28 | 62 → 0 |
| `wave1/homecoming-following-combat` | `wave1_evidence.gd`, seed `109` (first mixed shop from 101–140), controlled production actions | 82 → 24 | 59 → 0 |
| strong-field `rival-fight` | committed seed `72`, round `8` boundary input replay | 91 → 27 | 66 → 1 |

The rival's extra raw label is its recovered player hero Health; the remaining
ancillary label is the Ooze's held-unit count. Neither number is hidden to meet the budget.
The full-board UI test retains all 28 unit stats and both hero Health labels, with
0 ancillary labels on desktop and phone.

## Reproduce the captures

Each job runs Godot processes sequentially in a 3 GiB scope. Recorded runs used
its original single shared lock. Following the new orchestration rule, reruns below
use `/tmp/bramble-godot-slot` to select either of the two Godot slots; the
`systemd-run --user --scope -q -p MemoryMax=3G` command stays inside the wrapper.
Launch long jobs detached and inspect `build/declutter/*.log` with short commands.

```sh
source /opt/bramble/env.sh
mkdir -p build/declutter
nohup bash -c '/tmp/bramble-godot-slot systemd-run --user --scope -q -p MemoryMax=3G bash tests/ui/shots/declutter_baselines.sh /tmp/bramble-declutter-baseline "$PWD/docs/ideation/evidence/declutter/batch1"' >build/declutter/baselines.log 2>&1 &
```

The baseline runner archives `1ecbce6` to `/tmp`, injects only an evidence hook into the
existing shot scripts and a passive observer into the isolated UI adapter, imports
and compiles that project, then renders both requested sizes. The observer only
records input and chains any original observer; it changes no rules or outcomes.
It does not check out, merge, rebase or push any branch. Individual process logs are in
`build/declutter/baseline-logs/`.

After the baseline finishes:

```sh
nohup bash -c 'export LP_NUM_THREADS=1; /tmp/bramble-godot-slot systemd-run --user --scope -q -p MemoryMax=3G xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 -s res://tests/ui/shots/declutter_stills.gd -- res://docs/ideation/evidence/declutter/batch1/before res://docs/ideation/evidence/declutter/batch1/after' >build/declutter/after.log 2>&1 &
```

## Cold-reader criterion for this batch

The orchestrator selected a **source/effect** check for Batch 1. A cold reader should be
able to identify who moved or flashed, who received the hit or change, and what
visibly happened, including the visible cause of a death. It is not required to
reconstruct an unstated unit ability or name an unfamiliar keyword from the strip.
The same source/effect standard applies to ×4 and reduce motion. The initial internal
check reported **PASS** under this orchestrator-selected criterion. That claim is
superseded by the independent **FAIL** described below; it is retained as review history.

The [cold-reader audit](cold-reader-review.md) records the original observations
and four unresolved source attributions that prompted the first motion fixes. Its
refreshed-image addendum claimed those fixes passed; the independent review found
remaining failures. The review also exposed
Rules/tutorial input for Batch 4:

- Snap, Quarry, Swoop and Mire targeting exceptions, including back-row reach while a front unit survives.
- Which units qualify to join a Pack attack and when their attack is spent.
- Take rewards, growth and acorn cues.
- Counter's temporary Attack changes.
- Sable and Pounce trigger conditions.
- Belly release and Aura stat changes.

These rule explanations belong in the tutorial, Rules pages and reader. The combat
screen communicates their sources and effects through motion without adding text.

## Independent result at `4f50d944`

The [independent blind reader and event-based score](independent-review-4f50d944.md)
**fails** Batch 1 at ×1 and under reduce motion; ×4 passes. Every hitter and death
cause was right, but trigger attribution and reduced-motion direction failed. This
supersedes the earlier internal PASS. The independent report includes frame-level
causes. The six requested repairs were implemented and independently retested as
the first repair attempt below; that attempt also failed. A further repair and new
capture/retest are in progress.
The criterion was the orchestrator's call, not a statement attributed to the owner.

## First repair attempt: independent-style FAIL

The frozen [first-repair event score](cold-reader-first-repair-score.md) assesses
UI through `ec6d7575` with capture method `204c14cc`. Three fresh readers received
only the packet and one fight's strips each; a separate scorer checked their frozen
answers against the manifests. Raw answers remain in
[cold-reader-first-repair-combat-mid.md](cold-reader-first-repair-combat-mid.md),
[cold-reader-first-repair-homecoming.md](cold-reader-first-repair-homecoming.md) and
[cold-reader-first-repair-rival.md](cold-reader-first-repair-rival.md).

This attempt **fails** source/effect attribution: 50/57 attack initiators are right
and seven cannot be established. All 57 damage pairs and all 62 attack-caused death
pairs are right. Held reduced-motion attackers, separate Pack hits, attached damage
pops, the attack-death fade and actual hero Health read correctly. Opening effects
still have uncertain or wrong sources; Take's acorn landing is obscured by hero art;
some overlapping source pulses confuse attribution; the dead-unit reward is visible
without a settled landing account. Eight whole-opening frames undersample several
successive effects. These are source/effect failures, not requests to infer rule text.

That revision passed the full runtime gate (**1,913/1,913 tests**, 182 scripts,
42,296 assertions; `build/declutter/gate-review.log`). Passing the gate did not repair
its failed visual read. Both the gate and the frozen score are historical: the newer
motion changes below require another detached gate and a fresh blind score.

## Repairs after the independent review

Each requested repair has its own local commit:

1. Reduce motion holds an unmistakable attacker frame and direction mark through
   the attack, including joiners. Pack damage pops remain separate.
2. Trigger sources pulse and send source-to-effect motes. Take starts at the hunter,
   claims its actual quarry and routes the acorn through the hunter to its hero.
   Self-trigger effects reach the changed stat or immediate-attack target.
3. Dead-unit rewards identify their source with a temporary portrait echo and show
   both carried stat gains landing, without returning a live unit to the board.
4. Damage pops are children of their recipient, so counter-damage follows the
   attacking unit back to its own pocket.
5. Death cancels any outstanding lunge return and fades the unit in its own pocket.
6. Capture continues through the result and settled hero Health. Historical rival
   Health comes from the recorded round history, with a replay-result check.

The scope-review cuts are also separate commits: remove the tile mud bar that
crossed stats; restore pre-Batch-1 occupied Nest drawing; correct review attribution.
Combat sparks are now limited to rules that can fire during a fight. Dead panels,
yarn, row tags, `show_note` and unused Pack overlay handling are removed. Hero views
load once; replay retains the original ghost name; the phone reader clears the
playback control row. None of these changes alters combat rules.

A second repair, through `f09e453c`, `80dd61fb` and `532e298d`, addresses those
remaining observations. Held attacker frames now also identify normal-motion
initiators between samples. Temporary directional effect traces connect the pulsed
source to its recipient, with arrow tips outside stat numerals. Stats/statuses hold
for 0.4 seconds before the next independent effect; Take's larger acorn lands below
the hero artwork. Null-source hero buffs originate at the most recent explicit
`side_trigger`; Ring gains remain pocket effects, with no invented UID-zero caster.
Mire wait has a pause route to its affected unit. Opening captures now add focused
cause-group sheets rather than relying on one eight-frame overview.

The [second repair score](cold-reader-second-repair-score.md) identifies all 57
attacker/contributor sets and all 62 attack death causes correctly. Remaining gaps
were reduced-motion directed effects, normal wait self-action, some exact hit values,
a neighbour quarry source, and homecoming's final hero Health. The reader also reported
an unsupported rival B3 transformation; all eight source images show unchanged fox 4/4.
The detached second-repair gate **passed 1,916/1,916 tests**, 182 scripts and 42,307
assertions (`build/declutter/gate-motion.log`). This is a passing software gate with
a partial cold read, not a Batch 1 PASS.

The third repair is committed through `c2abbbe2`, with reshot evidence in `f30bf12f`.
Its detached full gate **passes 1,919/1,919 tests**, 182 scripts and 42,330 assertions;
all eleven checks and the strict hook pass (`build/declutter/gate-third.log`).
Three new fresh readers received only the packet and the `f30bf12f` JPEGs. A separate scorer
checked their frozen answers against the manifests in the
[third independent score](cold-reader-final-score.md).

| Fight | ×1 | ×4 | Reduce motion |
| --- | --- | --- | --- |
| `combat_mid` | C | C | C |
| `homecoming-following-combat` | C | R | — |
| `rival-fight` | W | W | — |

R means the reviewed source/effect account is right; C retains a source/action ambiguity;
W retains an incorrect extra recipient. All 57 attack contributor sets, all damage
pairs and all 62 attack-caused deaths are R. Actual final hero Health is R in all
seven runs. Combat ×4 additionally omits the selected initiator in 045 while identifying
both hitters correctly; that is a report coverage gap, not evidence of a missing cue.

**Findings at `f30bf12f` (before the current follow-up):** combat 045's waiting action remains unidentified in every mode;
combat 069/075's 2→4→2 Attack changes are read but their self-source is not settled.
Rival opening 009's travelling route is read as an additional B2→bottom F2 landing,
although its actual destination is top B1. Homecoming ×1 has one localized ambiguous
relay-source sentence in 005. Exact retained dead-fox gain values also remain unclear
in ×1/reduce, while the dead-self reward and acorn route are correctly observed.
These are retained findings; the batch is not marked complete.

Those findings requested a visual pass to isolate self-stat causation from the simultaneous Counter
attack trace, show a waiting action rather than relying on a pause stamp, and distinguish
in-flight transit from an actual landing. A concrete relay improvement is to show an
arrowhead only on arrival, so crossing an intermediate pocket does not look like a
second recipient. Printed rule conditions and ability names remain Batch 4 inputs. Wave2a/Bog integration is
deferred until the user's merge; no merge or Bog port is included here.

## Frame strips

The animation runner uses `manual_playback=true` and calls `advance_playback(1/120)`
with an explicit fixed timestep in two passes. The first pass records the actual
start tick of every attack, every applied event tick, the result tick and automatic
return tick. The second replays the identical serialized fight and captures eight
viewport frames evenly across each actual attack-to-next-attack interval: sample
`j=0..7` is `start + round(j * (end-start) / 7)`. `end` is the tick before the next
attack; for the final attack it is `result_tick - 1`. This includes trigger effects
between attacks instead of stopping at a predicted lunge duration, while preserving
eight attack frames without stretching the final attack across the whole result.
A separate eight-frame result sheet covers `result_tick` through automatic return,
after hero Health settles.

An eight-frame opening overview remains. Additional `opening-event-NNN.jpg` sheets
capture eight frames for each opening cause group. The first pass starts a group at
a new trigger, side trigger, quarry mark or changed source. Recipients of the same
caster remain together; sources emitted on the same tick share a sheet because real
playback has no separate interval to sample. Null-source hero recipients remain with
their side trigger. Manifests record every group's `event_indices` and `causes`, so a
scorer can audit coverage without supplying that truth to the reader. These focus
sheets supplement the actual opening sequence; they do not add gameplay pauses.

The capture asserts identical attack starts, applied event ticks, return tick and
final Health across both passes. Every sample tick and source-event hash is recorded
in the manifest; expected final hero Health must match the displayed values. Each
run starts from the same saved fight stream at ×1 and ×4, with no wall-clock sleep
driving animation. The viewport is always `1688×780`. Original frames remain in
`build/declutter/frames/`; committed contact strips contain those native-size frames.
There are 11 attacks in the wording fight, four in homecoming and eight in the rival
fight, each at ×1 and ×4, plus 11 wording attacks under reduce motion: 57 attack
sheets and 14 opening/result sheets across seven runs, plus cause-group focus sheets.
The reshoot contains 85 focus sheets, hence **156 sheets and 1,248 frames**, recorded
in `strips/runs.json` and committed as `dfffd6dc`. All seven event streams match their
serialized baseline; both timing passes agree, and all frames have native dimensions.
The prior repair produced 71 sheets/568 frames before these focus sheets were added.
Run the strip capture and assembly after the stills (one Godot process at a time):

```sh
nohup bash -c 'export LP_NUM_THREADS=1; /tmp/bramble-godot-slot systemd-run --user --scope -q -p MemoryMax=3G xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 -s res://tests/ui/shots/declutter_frames.gd -- res://docs/ideation/evidence/declutter/batch1/before res://build/declutter/frames' >build/declutter/frames.log 2>&1 &
```

Wait for `all deterministic frame captures complete` in `frames.log`, then assemble:

```sh
/usr/bin/python3 tests/ui/shots/declutter_strips.py build/declutter/frames docs/ideation/evidence/declutter/batch1/strips
```

`declutter_after.sh` also runs compilation, stills, frames and assembly sequentially
when launched under the same detached lock/scope wrapper.
Each attack, opening, focus or result sheet contains four columns by two rows of
native-size frames; the small
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
  A full 14-unit board still carries all 28 unit stat labels and both hero Health
  labels. Those primary labels are excluded from the revised ancillary budget.
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
- **Historical rival Health:** the field boundary omits hero Health, so the capture
  repairs its metadata from the same committed game's round history and checks that
  the replay damage agrees. No unknown Health is rendered as `−1`; production and
  the ordinary pairs use exact fight-boundary observations.

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
- **Animations 2 and 7 / Pack damage:** the earlier accumulating burst failed the
  independent review because it hid the joiner's contribution. It is replaced with
  separate, staggered and vertically offset pops at the recipient's Health bead.
  The recipient carries those pops while moving. Core hit order is unchanged.
- **Animation 14:** source glyph pulses/hops and target motes use the existing acorn
  colour vocabulary rather than new per-tribe colours or a separate whole-board
  ripple. Source-to-recipient travel and bead changes remain the causal cue. Aura changes
  use the actual UID sources supplied in `causes`; those sources flash and send
  motes. Self changes pulse the source glyph and body and send a mote to the exact
  changed bead. Out-of-turn attacks receive a source-to-target spark. The second
  repair adds temporary directional traces because pulses and moving motes alone
  still left source/recipient attribution unclear between samples. A normal trace
  reveals during travel (usually 0.35 seconds), holds for 0.6 seconds and fades for
  0.15 seconds; reduce motion shows the direction statically, with held source/target icons. Traces disappear after their effect
  and are absent at rest. Their arrow tips stop outside the stat numerals.
  A dead source uses a temporary portrait echo and its reward visibly lands. The
  first attack waits for pending stat rolls so the visible Attack value agrees with
  the attack. Hero-origin bonuses use the most recent explicit side trigger; Ring
  gains route from the pocket instead of inventing a unit source.
- **Animation 16:** the custom-drawn status layer appears in its end state and the
  tile flashes in the status colour, rather than independently scaling every mark.
  The layer deliberately supports simultaneous statuses without extra slip nodes.
- **Animations 17–19:** the existing bell/paw/splash icons supply compact event cues:
  bell glint rather than a twice-swinging bell, one travelling paw rather than three
  print stamps, and splash-to-mud rather than a separately animated mud mesh.
  The resulting paw and mud remain state, with no standing links or words. Take's
  acorn is enlarged to 88 canvas pixels and lands below the hero portrait, with a
  longer brief hold, because the first repair's acorn disappeared into the artwork.
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
  or the game-over record. Cached side names retain that fight's ghost identity instead
  of labelling it with the next recruit pairing.

- **Animation 15 / dead carried reward:** a dead unit has no live stat bead whose
  absolute value can roll. Its temporary portrait echo shows the recorded Attack/Health
  deltas landing on matching beads, without inventing absolute stats or resurrecting it.
  These two brief, echo-anchored delta labels adapt the appendix's no-`+X` gain-pop
  call, use `MIN_FONT` and count toward the 10-node ancillary budget. Live-unit gains
  still pop and roll their existing beads.
- **2.1 Mired status:** the tile's mud bar is removed because it crossed Attack/Health.
  The existing pocket mud strip carries the Mired state; the Mire maker retains reeds.
- **2.2 occupied Nest:** the twig ring drawn over an occupied card was early Batch 2
  work and crossed stats. It is reverted to pre-Batch-1 behaviour. The proper inside-edge
  pocket rim remains Batch 2 work; empty Nest presentation is unchanged.
- **2.1 trigger glyph:** only fight-capable trigger rules earn a spark in combat.
  End of Turn, Start of Turn and after-cast-only rules retain their recruit/reader
  presentation and have no combat spark. Mixed rules retain their fight cue.
- **Animation 1 / attacker identity:** the held pocket frame and direction mark now
  applies during normal motion as well as reduce motion. Seven first-repair attack
  initiators fell between samples despite correct damage pairs. The frame remains
  temporary, clears at the next attack/result and adds no words or standing links.
- **Appendix reduce motion:** a held static attacker frame and direction mark supplements
  flashes because a short tint fell between samples. Static transfer directions and held
  source/target icons mark effect landings without travelling motion; no explanatory
  text is added. Mire wait holds a crossed-sword mark on the waiting unit.
- **Section 6 / cue pacing:** stats and statuses hold for 0.4 seconds before the next
  independent effect so its source does not overlap the preceding stat landing.
  Normal traces remain briefly after their moving mote as described under animation 14;
  this passive hold does not block input. The last-death-to-return timing test remains required.
- **Appendix flash-only call / third repair:** paired flashes and held icons still
  left Take, growth and Counter sources unreadable in the second blind reduced-motion
  run. Trigger transfers therefore retain a temporary static direction trace. This is
  an explicit adaptation to the flash-only proposal: ordinary attack declarations
  remain unit frames, and all transfer traces clear after their effects. No words or
  permanent relation links are added.
- **Animation 7 / hit readability:** held attacker frames surround the portrait above
  the numeric badges. A dying body's children fade while its anchored hit numerals
  keep their own opacity/lifetime, preventing the body's fade from hiding the amount.
- **Animations 13/29 / self replacement:** a positive-Health self-death receives a brief
  bones mark before its replacement arrives. This distinguishes self-removal from a
  simple portrait flip without adding a rule caption.
- **Animation 14/15 / bead landings:** the arrow ends at the changed bead while its
  spark rests just above the numeral, leaving the rolling value readable.
- **Animations 18/32 / relays:** a lent quarry declaration stages maker→hunter, then
  hunter→quarry, with a 0.4-second declaration slot. Take follows hunter→quarry→hunter→hero;
  its composite reward sequence holds 0.9 seconds before the next independent source,
  so the quarry's returning acorn cannot be mistaken for the subsequent self-growth.
  The three travelling legs are 0.18, 0.18 and 0.22 seconds.
- **Animations 19/26 / wait:** the current follow-up replaces the ambiguous pause stamp
  with an 88 px crossed-sword stamp in its own 0.9-second action beat, after the prior
  hit/reward settles. Normal motion adds a windup/settle; reduce motion holds the
  stamp. The unit it waits for is a rule condition in the reader.
- **Animations 14/18/32 / transit and self-source:** the current follow-up shows a
  complete faint route during travel and reserves arrowheads, status drawing and
  recipient flashes for arrival. Self-stat gains start with a self-pulse and an
  outside-card loop to their own bead; Counter has no misleading inter-card buff
  link. These temporary paths adapt the flash-only proposal to the retained C/W
  findings, without standing links or new text. The three requested readings have
  been addressed in code and strips; the orchestrator's next independent read is pending.
- **Animation 31 / final Health:** converging transfer effects clear at 0.7 seconds;
  the impact pop settles by 0.82 seconds, leaving the final two result samples readable
  before return. Early Spoils uses a larger acorn below its hero artwork.
- **Section 6 / opening coverage:** the whole-phase opening overview undersampled
  several effects in the first repair. Eight-frame cause-group focus sheets now
  supplement it; the last attack stops before the separate eight-frame result sheet.
  Same-tick sources stay coalesced to preserve actual playback and manifest provenance.
- **Section 7 label budget:** the user's scope-review call replaces 30 total labels
  with 10 ancillary labels, excluding unit Attack/Health and hero Health. Raw totals
  remain reported so the comparison is not silently changed.
- **Section 6 cold reader:** the orchestrator selected source/effect attribution rather
  than inferring printed rule text. Mire back-row reach belongs in the Rules/reader
  and is a Batch 4 input, not a new failure criterion for this batch.
- **Wave2a/Bog:** kiss count/period, the pending-gain tag and Bog's Toll are deferred
  until the user's integration merge. No speculative port is included.

The remaining fight rows use their proposed functional cue: 1 lunge; 2 staggered
joiners; 3 immediate snap; 4 Cleave sweep; 5 per-strike Peck jabs; 6 real target;
9 berry then Health loss; 12 Bitter before contact; 15 rolling/popping beads;
20 Hex transfer; 22 gulp; 24 whistle; 26 skip/Bide; 27 tray dip;
30 heart/pips/flip; and 32 reward coin. The three sampled fights do not exercise
every rare cue, so the strips are evidence for those fights rather than a claim
that every row has been independently cold-read.

## Changed files

Every changed, added or deleted file relative to `1ecbce6`, including UID sidecars
and every evidence image/manifest, is listed below. Ignored local comparisons and
build logs are excluded from git.

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
- `docs/ideation/evidence/declutter/batch1/cold-reader-final-combat-mid.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-final-homecoming.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-final-rival.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-final-score.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-first-repair-combat-mid.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-first-repair-homecoming.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-first-repair-rival.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-first-repair-score.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-packet.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-review.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-second-repair-combat-mid.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-second-repair-homecoming.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-second-repair-rival.md`
- `docs/ideation/evidence/declutter/batch1/cold-reader-second-repair-score.md`
- `docs/ideation/evidence/declutter/batch1/independent-review-4f50d944.md`
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
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-000.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-003.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-004.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-005.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-006.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-008.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-010.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-011.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-012.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-013.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-014.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-016.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening-event-019.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/opening.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1-reduce/result.jpg`
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
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-000.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-003.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-004.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-005.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-006.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-008.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-010.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-011.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-012.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-013.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-014.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-016.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening-event-019.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/opening.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x1/result.jpg`
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
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-000.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-003.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-004.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-005.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-006.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-008.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-010.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-011.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-012.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-013.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-014.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-016.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening-event-019.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/opening.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/combat_mid-x4/result.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/attack-020.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/attack-026.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/attack-030.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/attack-033.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-000.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-003.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-004.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-005.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-006.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-008.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-009.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-013.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-015.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening-event-017.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/opening.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x1/result.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/attack-020.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/attack-026.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/attack-030.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/attack-033.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-000.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-003.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-004.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-005.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-006.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-008.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-009.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-013.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-015.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening-event-017.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/opening.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/homecoming-following-combat-x4/result.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-025.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-033.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-039.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-043.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-047.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-054.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-058.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/attack-062.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-000.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-003.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-004.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-006.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-007.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-008.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-009.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-010.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-011.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-013.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-014.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-020.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening-event-022.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/opening.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x1/result.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-025.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-033.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-039.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-043.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-047.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-054.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-058.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/attack-062.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/manifest.json`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-000.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-003.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-004.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-006.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-007.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-008.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-009.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-010.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-011.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-013.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-014.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-020.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening-event-022.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/opening.jpg`
- `docs/ideation/evidence/declutter/batch1/strips/rival-fight-x4/result.jpg`
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
- `src/ui/widgets/attack_yarn.gd`
- `src/ui/widgets/attack_yarn.gd.uid`
- `src/ui/widgets/board_view.gd`
- `src/ui/widgets/card_view.gd`
- `src/ui/widgets/combat_attack_cue.gd`
- `src/ui/widgets/combat_attack_cue.gd.uid`
- `src/ui/widgets/combat_effect_path.gd`
- `src/ui/widgets/combat_effect_path.gd.uid`
- `src/ui/widgets/combat_face.gd`
- `src/ui/widgets/combat_face.gd.uid`
- `src/ui/widgets/hit_panel.gd`
- `src/ui/widgets/hit_panel.gd.uid`
- `src/ui/widgets/icons.gd`
- `src/ui/widgets/lane_overlay.gd`
- `src/ui/widgets/pause_menu.gd`
- `src/ui/widgets/row_tag.gd`
- `src/ui/widgets/row_tag.gd.uid`
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
- `tests/ui/test_declutter_capture.gd`
- `tests/ui/test_declutter_capture.gd.uid`
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

**Current follow-up (`28c873e3`):** targeted UI gate **PASS**, 396/396 tests,
51 scripts, 14,006 assertions, no risky/pending tests or script errors. The five
selected runs contain 124 sheets / 992 frames; both timing passes agree and source
events remain identical to their saved baseline. Before and homecoming evidence is
unchanged. The six selected stills were rerun at both sizes; their resting images
are byte-identical and ancillary counts remain 0/0/1. No current cold read or full
gate was run, by request; both are reserved for the orchestrator.

**Historical second repair:** source/effect read remains partial; all
57 attacker/contributor sets and 62 attack death causes are right. Full gate passes
1,916/1,916 tests, 182 scripts, 42,307 assertions, with the strict hook clean.
**Third repair:** reshoot verified (156 sheets/1,248 frames), full gate **PASS**:
1,919/1,919 tests across 182 scripts, 42,330 assertions, no risky or pending tests.
All eleven checks pass; `build/declutter/gate-third.log` ends `check.sh: all steps passed`.
Fresh cold-reader score remains **partial**, with the per-run table/findings above.
Resting ancillary counts remain 0/0/0/1 at both sizes.

**First repair:** the frozen blind event score fails; its full runtime gate passed
1,913/1,913 tests across 182 scripts with 42,296 assertions
(`build/declutter/gate-review.log`). That gate predates the second motion repair.

The following metrics describe the superseded `4f50d944` evidence only.


- Baselines: all eight native viewport images and serialized checkpoints complete; isolated compile: 534 files, zero failures.
- After pairs: all eight complete; counts 28/28/24/26 at both sizes, all within the 30-node budget.
- Main compile preflight: 543 files, zero failures.
- Final UI preflight: 374/374 tests pass across 50 scripts, 13,854 assertions; no
  script errors, failed tests or GUT warnings appear in the log.
- Strips: seven complete runs, 57 attack sheets, 456 native frames. All eight samples per attack match the scheduled ticks exactly; adjacent gaps differ by at most one 1/120-second tick due to rounding. All frame dimensions verified at 1688×780.
- Initial internal cold-reader check: **PASS claimed**, superseded by the independent
  **FAIL** at ×1 and reduce motion (`4f50d944`); ×4 passed. Reviewers received only
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

## Local commits since the independent review

These precede the final documentation commit named in the handback.

- `23b427dc fix(ui): hold reduced-motion attackers and separate Pack hits`
- `4373afe5 fix(ui): remove mud overlay from combat stat beads`
- `bbc2290f fix(ui): restore occupied Nest rendering to pre-batch behavior`
- `84bb92a6 docs(ui): correct review attribution and record independent failure`
- `95c6e767 fix(ui): connect live trigger sources to their effects`
- `8a1802b0 fix(ui): restrict combat glyphs to fight-capable triggers`
- `84889adc perf(ui): cache hero views across fights`
- `a20d614b fix(ui): show dead-source rewards landing on stat echoes`
- `baadba92 refactor(ui): delete retired combat panels and Pack overlay`
- `5cec0d8c fix(ui): anchor counter-damage pops to their recipient`
- `0e246923 fix(ui): fade defeated units in their own pockets`
- `0c5c60fa fix(ui): keep the original ghost identity when replaying`
- `fdbdb296 test(ui): enforce ten ancillary combat labels excluding primary stats`
- `50f80d0e fix(ui): keep the phone fight reader above playback controls`
- `48b75205 docs(ui): record independent failures and repaired evidence method`
- `ec6d7575 fix(ui): avoid cue helper shadowing under strict compilation`
- `82c7118f fix(ui): capture complete combat result phases`
- `204c14cc test(ui): count baseline ancillary combat labels`
- `75f97f1a test(ui): type baseline metadata assertions for strict Godot checks`
- `75f4c3a1 docs(ui): recount unchanged baseline captures with ancillary budget`
- `46dbade7 fix(ui): capture each opening effect group`
- `5f2a8465 docs(ui): preserve the first repair cold-reader failure`
- `f09e453c fix(ui): hold effect routes and separate competing trigger cues`
- `80dd61fb fix(ui): keep pocket rewards distinct from hero effect sources`
- `532e298d fix(ui): end directional effect traces clear of stat numerals`
- `aca35fb2 fix(ui): retain paired reduced-motion marks without yarn`
- `e15833ba docs(ui): preserve failed repair score and describe focused recapture`
- `dfffd6dc test(ui): reshoot repaired fight motion and opening effect strips`
- `64a7549d docs(ui): preserve the second repair blind-reader score`
- `99dd492e fix(ui): keep held attacker frames clear of damage numerals`
- `512794e0 fix(ui): hold static trigger transfer directions under reduced motion`
- `4b05cddf fix(ui): separate Take relays and make unit waits explicit`
- `1187c152 fix(ui): clear result transfers so final hero Health stays readable`
- `2c503aff fix(ui): mark self-death before a replacement arrives`
- `13b9b5c1 fix(ui): keep anchored hit numbers opaque while bodies fade`
- `aba243fa test(ui): verify hit numerals remain readable through death fades`
- `edcb4542 fix(ui): preserve each quarry relay declaration at fast speed`
- `c2abbbe2 fix(ui): land stat motes above their rolling numerals`
- `f30bf12f test(ui): capture static reduced effects and readable final results`
- `0974e43b docs(ui): record partial cold-reader result and passing full gate`

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
Health, and four icon controls. The original counter reports 28 raw visible numeric text nodes (0 ancillary under the revised definition).
There are no words, relation links, keyword glossary or hit/log prose panels on the
resting combat board. This directly removes the standing explanation layer that
occupied the earlier comparison's left side. The existing art and wood palette stay
consistent; the motion strips, rather than this still, judge attack causes.
The prior comparison estimated about 30 visible labels in
Battlegrounds combat and about 55 in Galaxy combat. Those were manual screenshot
estimates; Bramble's new gate measures actual visible text nodes, so the numbers are
reported separately rather than treated as identical instruments.
