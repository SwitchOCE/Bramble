# The comparison fight (fight animation treatments)

One fixed fight, filmed once per animation treatment, so every clip shows the same moments and
compares like for like. Exploratory (`ideation/fight-animation`): nothing here reaches the game.

```bash
tools/feel/film tests/screens/feel/fight-compare-today.json /data/fight-anim-work/fixture/today.mp4
python3 tests/screens/feel/fight_compare/speed_chart.py /data/fight-anim-work/fixture/today
```

The film takes about 3 minutes here (817 frames). Beside `today.mp4` it writes:

- `today.report.json`: the treatment, every attack's frames (`start_frame`, `contact_frame`,
  `burst_frame`, `end_frame`), the five moments below with their frames and seconds, the planned
  seconds, and `core_matches` (the board on screen at the end equals the rules core's).
- `today.cards.csv`: every drawn frame, every card: `frame, t, step, key, card_id, side, slot,
  x, y, scale, rotation, alpha, attack, health, state`. `x, y` is the card's centre in film pixels;
  `attack, health` are the numbers drawn on it; `state` is `kept` or `leaving` (dying). Bursts
  (the damage stars) are rows with `card_id` `burst`.
- `today.markers.csv`: `frame, t, step, marker, key, detail`, one row per `step` (kind and hold),
  `attack_start`, `contact` (the attacker nearest where its target stood), `burst` (new damage
  stars, `side:slot:amount`), `numbers` (a card's drawn Attack/Health changing), `card_in`,
  `card_out` and `sound` (each cue as the sound player started it, or why it dropped it).
- `today.speed.png` (from `speed_chart.py`): the attacker's speed per attack, frame by frame,
  with contact and the first burst marked.

`frame` is the film's own frame number (0 = the first frame of the mp4), so
`ffmpeg -i today.mp4 -vf "select='eq(n\,515)'" -frames:v 1 out.png` shows that row's frame.

## The fight

Shipped tribe cards with their art, the rules core's own fight (seed 22), the real fight screen.
You (lower board): Sentry, Horde-runner, Green Recruit, Old Brock in the front row; Sentry,
Horde-runner, Private behind. The opponent: Prophet of the Dust, Nettle Sprout (Thorns 2),
Orchard Stripper. Seven attacks; Victory at 11.5 s; the film is 13.6 s.

| Moment | Attack | Cards | `today`: starts, contact, first burst, next attack (film s) |
|---|---|---|---|
| (a) plain, straight across | 0 | Sentry (slot 0) on Prophet of the Dust (slot 0) | 0.75, 0.93, 0.98, 1.70 |
| (b) plain, diagonal target | 1 | Prophet of the Dust (slot 0) on Old Brock (slot 3) | 1.70, 1.88, 1.93, 2.82 |
| (c) effect before the hit | 2 | Horde-runner on Nettle Sprout: Thorns 2 hits the attacker first; the attacker waits at contact through the trigger step | 2.82, 3.00, 3.37, 4.08 |
| (d) kill whose death summons | 4 | Green Recruit on Nettle Sprout: Thorns kills it before the exchange; its death summons a Hopper in its slot; Old Brock triggers once | 5.03, 5.22, 5.58, 7.47 |
| (e) one trigger many times | 5 | Orchard Stripper on Old Brock: the Stripper dies, deals 5 to all seven of yours (7 bursts at 8.58), six die together (9.15), Old Brock triggers six times (9.47) | 7.47, 7.65, 7.70, 10.10 |

Attack 3 (Nettle Sprout on Sentry) and attack 6 (Old Brock on Nettle Sprout, Thorns again,
the last kill) are plain filler between and after. In `today`, Old Brock's six trigger-and-buff
pairs show as one trigger step and one change step (0.62 s): the replay drops a step that looks
the same as the one before, so repeats by one unit collapse; repeats by different units would
not. Thorns' damage to the attacker lands in the same burst step as the exchange.
`tests/screens/test_fight_compare.gd` fails if a card change moves any of these moments.

## Adding a treatment

1. A script in this folder extending `fight_treatment.gd`, overriding only what it changes:
   - `make_motion(cards)`: a `FightMotion` subclass (attack, hit, death, burst motion);
   - `make_replay(base, events, catalog, damage)`: the steps, their order and holds: change the
     steps of `FightReplay.build(...)`'s result, or return a `FightReplay` subclass with
     `replay_with(script, ...)`;
   - `screen_script()`: a subclass of `compare_screen.gd`, for changes to how the screen plays
     steps.
2. One line in `treatments.gd`, for example
   `"overlap": preload("res://tests/screens/feel/fight_compare/overlap.gd"),`
3. A scenario beside `fight-compare-today.json` with `"treatment": "overlap"` and a `wait` long
   enough for the treatment's fight (the film ends 0.5 s after it).

`today` is `fight_treatment.gd` itself: `FightMotion` and `FightReplay.build`, exactly as the
game plays them (the test checks both).

## `best`: the best proposal, and its contested branches

`best.gd` plays the best proposal's attack and ordering
(`docs/workstreams/fight-animation-24-nov/plans/best.md`, sections 2 and 3). `best_timeline.gd`
schedules every change, motion, burst and glow by frame from the log; `best_screen.gd` plays that
frame by frame instead of FightScreen's steps (no change in `src/`). Each contested branch
(best.md section 6) is a parameter: `"options": {"CB2": "c"}` in the scenario; `best_timeline.gd`
lists every option's numbers. A branch not named plays the proposal's pick.

```bash
python3 tests/screens/feel/fight_compare/clips.py scenarios /data/fight-anim-work/treatments/scenarios
tools/feel/film /data/fight-anim-work/treatments/scenarios/cb2-c.json /data/fight-anim-work/treatments/films/cb2-c.mp4
python3 tests/screens/feel/fight_compare/clips.py measure /data/fight-anim-work/treatments/films/cb2-c
python3 tests/screens/feel/fight_compare/clips.py cut /data/fight-anim-work/treatments/films /data/fight-anim-work/treatments/clips
python3 tests/screens/feel/fight_compare/clips.py compare /data/fight-anim-work/treatments/films /data/fight-anim-work/treatments/compare 0.38
```

`compare` writes one unlabelled clip per option (`compare/<branch>/<option>.mp4`, the panes' frames
and crop at 0.38 scale) and `compare/manifest.json`: per branch (and `whole`, the two whole fights)
its title, frame count, segments, and each option's label, film frames and measured numbers.

`cut` lines every pane up at the branch's moment, each from its own film: the attack's first
motion (CB1, counter `S`), contact (CB2–CB6, `C`; `T`, Thorns landing, for CB6's attacker killed
before it strikes), the first combo pulse (CB7, `P`), or the first of several falls (CB8, `F`). Each pane counts frames from there.
`speed_chart.py STEM --ymax 7000` draws every film's chart on one y axis.

`measure` writes `<stem>.timing.json`: each attack's claimed, planned and measured numbers (lift,
hold, strike, stop gap, contact pop, frames held at contact, the first return frame's px, return,
numbers, falls, next lift) and the mismatches. C is the plan's contact (the geometric contact,
kept beside it, is not C when the attacker stops past the centre). The report's `plan` holds the
schedule (`frame_offset` turns its frames into film frames).

CB7 plays its own short fixed fight (`"fight": "cb7"` in the scenario; `fight_compare.gd`
`CB7_YOU`, `CB7_THEM`): your first Gleaner kills the Orchard Stripper, five of yours die to its
damage, and the two Gleaners left hit King Speck ten times, so the combo's 9th and 10th land
together and the burst re-pops with the running total. Two Health values are set for the fixture
(the Stripper 1, King Speck 60). Every CB7 pane runs without rule 7's speed-up except the last,
"best" (the proposal with rule 7); `best_no7` is the proposal without it. The comparison fight
and its test are unchanged.

CB8, several deaths at once (`docs/workstreams/fight-animation-24-nov/research/mass-deaths.md`),
staggers moment (e)'s six falls, display order only: `a` all at once (the proposal), `b` 4 f apart
within 24 f, `c` 10, 7, 5, 4, 4 within 30 f, `d` 12 f apart, no cap (Galaxy's pace). The order is
rulebook 9.7.3 (the active side's dying units, then the other side's, each in reading order).
In b to d each of Old Brock's gains lands as its own death's fall ends (15 f after it starts), not
after the group: `best_timeline.gd` `reorder()` moves the log's gains beside their deaths (the k-th
gain is that side's k-th death in the log) and recounts the numbers if their order changes; the
board at the end is the core's. A group whose following beats are not one per friendly death (a
death effect among them) staggers its falls and plays what follows after the last. Staggered
falls run 15 f, without rule 7's speed-up.

Rules this treatment follows: the return moves from C+1 (no frame held at contact) and is home at
C+12/14/16; what plays after the hit starts at max(C+14, home). CB4 "freeze" is today's order:
Thorns flares while the attacker waits at contact, and its change shows with the exchange's at
C+22. CB4 "after" plays a reordered log (`best_timeline.gd` `reorder()`), so the exchange's
numbers show first (Health 5 to 3) and Thorns' at its landing (3 to 1); lethal Thorns can't play
"after" (the attacker never strikes). CB2 "galaxy" stops 0.3 h past the target's centre.

Stand-ins (each new look needs an art pass and the owner's yes): the cause-to-target line is
today's jab; the xN counter is the burst re-popping with the running total (option
`CB7: best_xn` adds a plain-text "xN" marked as a placeholder); C's crack and shatter are today's
fall; C's rim glow is today's lunge glow. `best` plays no sound cues. Readings of best.md that it
does not spell out: what plays before the hit waits for the previous queue's end; a beat from a
dead source has no pulse but still lands 12 f after it starts; rule 7's speed-up rises from x1 at
60 f of queue to x1.5 at 120 f; an attacker killed by Thorns stays raised until it falls (no
strike).

## Late fights and their length (`fight_length.gd`)

`fight_length.tscn` makes late fights from the league bots' ghost runs (two runs' boards for the
same round, rounds 8 to 12) and counts each one's frames to the result, headless: today (each
`FightReplay` step held as `FightScreen` holds it) and `best` with each contested option and the
what-ifs (`"R7"`, rule 7's numbers; `"GROUP"`, up to N single beats in a row starting together;
both in `best_timeline.gd`, neither a contested branch). It also splits each fight's time by kind
from `best_timeline.gd`'s `spans`. `fight_length.py` summarises it. A saved fight plays on the
screen with `"fight": "spec:<path>"` in a scenario. `fights=compare` measures the comparison and
CB7 fights, whose films match it to the frame. Findings and commands:
`docs/workstreams/fight-animation-24-nov/research/fight-length.md`.

## What the logs can't show

- The film is silent. Sound rows are the cues the sound player started, at the frame they
  started; a cue with a delay is timed by the wall clock, so its frame in a slow film is early.
- The report's contact is geometric (the attacker's nearest point to where its target stood),
  not a rule; `clips.py measure` uses the `best` plan's contact instead, since an attacker that
  stops past the centre (CB2 "galaxy") is nearest the centre before it stops.
- Everything else in `tools/feel/README.md` ("What it cannot do"): software rendering, one size.
