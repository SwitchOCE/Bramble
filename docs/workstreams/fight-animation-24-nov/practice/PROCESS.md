# How a motion change is made (draft, 24 Nov 2026)

**Draft for the owner.** Step 2 of [PLAN-animation-practice.md](../PLAN-animation-practice.md). The rules it checks against are [GUIDELINES.md](GUIDELINES.md). Nothing here binds agents until the owner says so.

**What counts as a motion change:** anything that changes how or when something moves, pops, lights up or plays a sound, and any new drawn effect. Changes to fight ordering and holds count too.

**The one fact behind every step:** no agent can watch motion at speed ([AGENT-BLIND-SPOTS.md](../../../AGENT-BLIND-SPOTS.md) §1). Agents measure and film; the owner feels. The two cases the owner liked (the triple, drag feel) went brief → build → owner plays → tune on his words, within a day ([look-back.md](look-back.md), lesson 1).

## The steps

| # | Step | What it produces | Done when |
|---|---|---|---|
| 1 | **Brief** | The brief (template below) | The owner's words are quoted, the bar is one moment, every limit is named |
| 2 | **Reference study** | 3–5 clips, all of the same moment, measured at 60 fps | Each reference has a per-frame table: position, angle, scale, opacity, light. Each number is marked M (measured) or G (guess). |
| 3 | **Beat spec in frames** | One table per option (below) | Every beat has frames, a token, a marker and its sound cue |
| 4 | **Picture first** for any new visual element | Pictures at real size, from a full design pass | The owner said yes to that picture, in his own words |
| 5 | **Build** | One tuning file per animation; tokens only; game time only | Headless tests pass; every effect ends at rest (S2) |
| 6 | **Film** with `tools/feel` | Film, per-frame log, strips, speed chart | The check is shown to fail on the old or broken version |
| 7 | **Check** against the guidelines | A rule table: pass, fail, or not checkable | Every relevant rule has a result; the report opens with what no check could see |
| 8 | **Compare viewer** | Two options, one difference, aligned on the moment | The difference is visible at real speed; the viewer slows and steps frames |
| 9 | **Windows build** on the owner's PC | A zip by Taildrop | It runs on his GPU with sound. This is the last check. |
| 10 | **The owner judges** | His verdict, quoted, in the motion list | He has played it; his note becomes the next round's brief |

Then merge, through the gate below.

### 1. The brief

Fill this in. A Codex worker gets it as written; open, taste-led calls stay with Claude or the owner (`codex-workers` skill).

```
Moment:        the one event, e.g. "one unit takes Thorns damage back"
Owner's words: quoted, dated
Bar:           a feeling plus one reference moment ("the same sense of excitement" as X)
Ordering:      when it plays in the queue, and what it waits on or overlaps
Limits:        each limit, its source, and what it squeezes; "reopen if lifted"
New pieces:    any new drawn element (goes to step 4 first)
Out of scope:  what, and why it isn't the real fault
Done when:     film + log checks + compare clip + owner's verdict
Claims:        what the worker may claim (table below)
Disk report:   what it wrote outside its checkout, sizes, what can go
```

- **Check ordering first.** If the fault is when something plays (a frozen attacker, a trigger in its own 0.3 s step), fix that before tuning the motion (LB 6).
- **A limit is a design choice.** Write down what it squeezes. Brief 10's frozen holds produced the 4-frame wind-up, and nobody reopened it (LB 2).

### 2. Reference study

- **Few, and all of the same moment.** The triple's five clips all showed three-become-one; brief 10's eleven spanned five games (LB 8).
- **Measured at 60 fps**, frame by frame, with angle and scale as well as position (LB 7). Save every measured column; Battlegrounds' angle "was searched but never saved".
- **Not only Battlegrounds** when the owner says it does a thing badly (buffs, 24 Nov). Card games and fighting games are both fair sources.
- **Our own build is measured the same way**, as the "before".
- Video stays out of Git: `/data/fight-anim-ref/` on the Optiplex, or R2 through `tools/assets/`.

### 3. Beat spec in frames

| Beat | Frames | Who moves (lead, support, decoration, still) | Token | Marker | Sound cue | Reduced-motion version | M or G |
|---|---|---|---|---|---|---|---|

"Who moves" is Emil Kowalski's casting idea (`choreograph`, credited in [agent-skills-survey.md](agent-skills-survey.md)): give each moving thing a role, then say for each pair whether they move together, overlap or wait.

### 4. Picture first

The owner's rules of 22 Nov:
- A new visual element is its own design job: a reference study, an art director who answers the craft questions in writing, generated art (the `bramble-art` skill), assembly at the real on-screen size, and a review. Never crop existing assets.
- A change to the card face or screen needs a picture and an explicit yes. A blanket approval doesn't cover it.

Motion that uses only existing pieces can be filmed while the pictures wait. Nothing is filmed with a new piece before the yes (pass 2, thread 3).

### 6. Film

- `tools/feel/film` on a fixture that reaches the moment. Add a fixture if none exists (the result, hero damage and elimination have none, INV).
- **Per-frame log**: every card's position, turn, scale and opacity on `RenderingServer.frame_pre_draw`, plus event markers (`windup_start`, `contact`, `hit_shown`, `home` …). Today it lives in the fight compare fixture on `review/fight-animation-clips` (`tests/screens/feel/fight_compare/`), not in `tools/feel`.
- **Speed chart** (`speed_chart.py`, same place) and **strips** at the markers.
- Film at fight speed 1 and the fastest speed. Film with reduced motion once the game has the setting.
- **Prove the check bites**: run it on the old version or a deliberately broken one and show it fails (LB 9).
- Cheap first pass: ffmpeg `freezedetect` and per-frame difference show where to look before reading strips (survey).

### 7. Check

The report has a table with one row per rule from GUIDELINES.md that applies, giving the measured value, the start number and pass, fail or not checkable. It opens with one line on what no check saw: feel, real frame pacing, sound sync, real input.

### 8. Compare viewer

- **Two options, one difference**, played side by side, aligned on the moment, slowed or sped, stepped frame by frame. The owner, 24 Nov: "a tool that lets me pick just two animations to compare, and I can slow or speed them up."
- **A real choice.** If the two can't be told apart at real speed, widen the difference or drop the decision. A 4 f against a 6 f wind-up wasn't a real choice (LB 4).
- A reference clip may be one side.
- The viewer is on the phase page (`page/README.md`); its clips are cut by `clips.py` on the clip branch.

### 9. Windows build

`scripts/build_windows.sh`, then Taildrop the zip to the owner's PC. It is the only check with a real GPU, the real frame rate and sound. The PC is off from about midnight to 8 a.m.; don't send then.

### 10. The owner judges

- Quote his verdict in the motion list, dated.
- His reactions are directions, not decisions (owner note `2026-11-02i`). "These aren't a firm steering. I don't know what's right" (24 Nov). Tune on what he says is wrong; push back with a film when the evidence says otherwise.
- Keep rounds short: the next build the same day if possible.

## What an agent may claim

| An agent may claim | Only the owner judges |
|---|---|
| Frame counts, timings and curves from the log | Whether it feels good, weighty, clear or exciting |
| That pixels changed on the frames the spec says (strips, pixel difference) | Whether it fits lead and stained glass |
| Pass or fail on each guideline that has a Log, Film or Code check | Which of two options is better |
| That the flash count is within limits (A1) | Whether sound lands on the hit, on real hardware |
| That the build matches its beat spec within ±1 f | Whether a new drawn piece is right (picture first) |
| That the check failed on the broken version | Whether a "keep" is good |

Never claim "it feels better", "smooth" or "parity". Don't use a council or an agent play-test as a feel gate: they catch rules, data and labelling faults (LB 9).

## Sound cues when a timing moves

Each fight cue is asked for at a step (`tests/sound/test_sound.gd` checks which). When a beat moves:
- List every cue tied to a moved beat in the beat spec: `fight.hit`, `fight.destroy`, `fight.trigger` (at step start), `fight.death`, `fight.summon`, and the result's `fight.win`, `fight.lose`, `fight.tie`.
- Move the cue with its marker, not with a fixed delay. Today's `delay_s` runs on the wall clock and ignores fight speed (INV inconsistency 5).
- Update `test_sound.gd` for the new step or marker.
- The film is silent. The owner hears sync on the Windows build (GUIDELINES T11). A game-time sound log would let agents check it; it doesn't exist yet.

## A card or keyword gets its own animation

- **When:** an effect that isn't an attack (Thorns, effect damage, death damage), a keyword whose meaning motion can carry, or a rare signature card (tier 3). Whether card- and keyword-specific animations are in scope now is open for the owner.
- **How:** it belongs to a family in the vocabulary (GUIDELINES §1), uses the shared tokens and has its own tuning file. It goes through all ten steps. Its new pieces go to step 4.
- **Hook** (proposal): the card's data names an animation; with none, the family's default plays. Content stays data (`src/content`).
- **Map first:** before the second keyword animation, write the short map of which effects need their own language (pass 2, thread 9), so buffs, combos and Thorns stay one family.

## Where the quality bar hooks in

| Hook | What it adds |
|---|---|
| The brief | The template in step 1; no motion brief without the owner's words, one moment and named limits |
| Handoff | `design-handoff`'s Motion table in frames, with beats, markers, sound cues, the reduced-motion version and who decided |
| **Gate before merge** | A motion change merges only with its film, log check table, compare clip, and either the owner's verdict or the motion list marked "accepted, not yet judged". The scope reviewer's brief asks for these. |

## The motion list

One living list of every animation, with its state: **not reviewed · proposed · accepted · built · owner-liked**, plus the owner's latest words and what limit, if any, held it back. Start from [inventory.md](inventory.md).

- **Accepted but unbuilt** stays on the list until it is built or the owner drops it. Damage to the player was accepted on 21 Nov and fell out when the fight batch never started (LB 10).
- **New faults found by watching** go on the list the same day (buffs and staggered deaths came up only when the owner watched clips).
- **Reopen when a limit lifts.** Each limit lists what it blocked. When the owner lifts it, every row it blocked goes back to "proposed".

**"Keep" means someone judged it good against a reference.** If no one did, the row says "not reviewed". A blanket yes doesn't turn "not reviewed" into "keep" (LB 3).

## Where each part should live (proposal for the owner)

Extend what exists. One new skill only where nothing fits.

| Part | Proposed home | Change |
|---|---|---|
| Vocabulary, tokens, rules (GUIDELINES.md) | `docs/design/motion/GUIDELINES.md`; `design-system`'s Motion line points to it and lists the tokens | Edit `design-system` |
| Beat spec and handoff fields | `design-handoff`'s Animation / Motion table | Frames not ms; add marker, sound cue, reduced-motion version, check |
| Per-frame log, speed chart, clip cutter, viewer | `tools/feel/`, generalised from `tests/screens/feel/fight_compare/` | Extend `tools/feel/README.md` |
| Flashing and reduced-motion checks | `accessibility-review`'s Motion and Sensory section | Add A1 and A2 as checks |
| The brief template | `codex-workers`' "Briefing a worker" points to it | Edit `codex-workers` |
| New drawn pieces | `bramble-art` already covers the picture batch | No change; PROCESS points to it |
| Fight timing rule | `docs/design/owner-notes/2026-11-18b-fight-timing-and-grouping.md` | No change; GUIDELINES cites it |
| The process (PROCESS.md) and the motion list | `docs/design/motion/PROCESS.md` and `docs/design/motion/list.md` | New files |
| Routing an agent to all of the above | A short `bramble-motion` skill, like `bramble-art`: when to use it, what to read, the ten steps | **New skill**: nothing else covers a request from brief to merge |

Open for the owner: whether these rules bind agents; the pilot (damage to the player and a single death) now or later; whether the practice extends the existing skills or becomes its own.
