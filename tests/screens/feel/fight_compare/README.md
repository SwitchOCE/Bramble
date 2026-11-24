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
  x, y, scale, rotation, alpha, attack, health, state, scale_y, keystone, lead`. `x, y` is the
  card's centre in film pixels; `attack, health` are the numbers drawn on it; `state` is `kept`
  or `leaving` (dying); `scale_y` is the scale along the card's own length (`scale` is across
  it); `keystone` is its leading edge's width over its trailing edge's (1 when flat) and `lead`
  the edge that leads (1 top, -1 bottom, 0 flat), both from `tip.gdshader` (CB9). Bursts (the
  damage stars) are rows with `card_id` `burst`.
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

**The lean's sign (fixed 24 Nov).** The proposal's 4-degree lean now tips the leading point
toward the target on both sides; before, it turned clockwise for any target to the right, so
their cards tipped their bottom point away. Clips filmed before the fix still carry the old lean:
CB1 and CB3 to CB8, `best` and today-vs-best. CB2 was refilmed whole (its `best` pane is the film
`cb2-best`, so every pane has the new lean), and so were CB9 `none` and CB10 `a`. CB2's `a`
(shallow) now stops 0.70 h far with no back-row rule (plan A's 0.45 far and 0.35 back row stopped
deeper than `b`), so it is shallower than `b` at every distance; CB10's `a` uses it too.

CB9, rotation (`docs/workstreams/fight-animation-24-nov/research/rotation.md`): `none` is the
proposal's 4-degree lean; `length` is the aim and the shortening below without the keystone, to
show whether the shader adds anything; `aim` turns the card in its own plane so the point facing the target
leads (the top of yours, the bottom of theirs), to 95 % of the path's angle, on Galaxy's timing:
from the lift's first frame (sine out), full at C-12 when the hold is its least (it holds
through a longer one), 90 % at C, unwound from the return's start over 25 f (smootherstep), so the
card lands home still turned and straightens there. `tip` adds the leading end tipping away from
the viewer: `tip.gdshader` draws a true perspective keystone (leading edge 0.9 of the trailing
edge's width, texture sampled perspective-correct so the lead lines stay straight), ramped and
held with the turn and gone 10 f after the return starts; and the card shortens along its own
length to 0.75 at C (its `scale.y`, as `src/screens/card_carry.gd` pitches a carried card; scale
applies before the turn, so it never shears), shortening with the strike's travel and back to
full by C+8. 0.75 reads as a tip of about 41 degrees. The aim replaces the lean. The shadows
(the card's child nodes) stay flat; the keystone moves the drawn card's middle a few px toward
its trailing end, which the log (the node's centre) doesn't see. `CB3: gentle` is an ease-in of
power 1.3. CB10 (stop A or B) and CB11 (quad, mild, gentle) are clip groups, not parameters: each
option is a set of CB2, CB3 and CB9 (`clips.py` `FILM_OPTIONS`); every CB9-CB11 film runs at stop
B and the quad ease-in except the one thing its group varies, since the owner ruled out constant
speed. They show attacks 0 (yours, straight), 1 (theirs, far corner), 3 (theirs, diagonal down)
and 6 (Old Brock, yours, diagonal up), lined up at C. `clips.py measure` adds each attack's
`rotation` (turn at C-12, C, C+10, C+25; path angle; length and keystone at C and C+8), and
`clips.py compare ... --only CB9 CB10 CB11` writes just those branches, each entry in its own
`compare/<branch>.json`, leaving `manifest.json` alone.

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

## `pilot`: the animation pilot's cheap options (CB12, CB13)

`pilot.gd` plays the pilot's options made from existing pieces only
(`docs/workstreams/fight-animation-24-nov/pilot/player-damage.md` and `death.md`, section 4), on
top of `today`, not `best`: `"treatment": "pilot", "options": {"CB12": "b"}`. A decision not named
plays today's.

- **CB12, damage to the player:** `b` the winner's portrait strikes; `c` in place, no travel.
  Both show the old Health on the result and land the loss later (the pilot's ordering change).
  Every number is in `pilot_hero_damage.gd`, by frame after R; `pilot_screen.gd` draws it from
  its own game-time clock and plays the stand-in `fight.hit.heavy` at each contact.
- **CB13, a single death:** `b` tip and fall; `c` the light goes out (`pilot_motion.gd`). Only a
  unit that dies alone plays it (`pilot.gd` `solo`); the six at once in moment (e) keep today's
  fall (CB8 owns them). The killing number stays on through the death, and the result's
  `settle()` lets the last death finish.
- **New tokens** (`pilot_tokens.gd`): `stop.hit`, `shake.dir`, `count.roll`, `fall.gravity`,
  beside the guidelines' easing curves.

CB12 needs fights that end in a loss. `"fight"` in a scenario: `lose-small` (their Hopper and your
Private kill each other: round + 1), `lose-big` (their Sentry kills your Private: round + 1 + 3),
`lose-out` (as small, your Health 5: it reaches 0). The loss is the core's `Rules.loss_damage` for
the round on the screen (turn 7: 8, or 11). The comparison fight is the win (the fixture's 7).
`"speed": 2` plays the fight screen at twice the speed.

The log adds `<stem>.heroes.csv` (both portraits per frame: centre, scale, turn, light, the Health
drawn, the badge's scale, the stage's offset, the "-N" on that portrait), a `light` column in
`cards.csv` (modulate's red channel), and markers `result_shown`, `hero_windup`, `hero_launch`,
`hero_contact`, `hero_burst`, `health_count_start`, `hero_contact_2`, `health_count_end`,
`hero_home`, `death_tip`, `death_dark`, `death_gone`.

```bash
python3 tests/screens/feel/fight_compare/pilot_clips.py scenarios /data/fight-anim-work/treatments/scenarios/pilot
tools/feel/film /data/fight-anim-work/treatments/scenarios/pilot/cb12-b-lose-big.json /data/fight-anim-work/treatments/films/pilot/cb12-b-lose-big.mp4
python3 tests/screens/feel/fight_compare/pilot_clips.py measure /data/fight-anim-work/treatments/films/pilot/cb12-b-lose-big
python3 tests/screens/feel/fight_compare/pilot_clips.py compare /data/fight-anim-work/treatments/films/pilot /data/fight-anim-work/treatments/compare 0.38
python3 tests/screens/feel/fight_compare/pilot_clips.py cut /data/fight-anim-work/treatments/films/pilot /data/fight-anim-work/treatments/clips
```

`measure` writes `<stem>.pilot.json`: the beats read off the log, and each check (the filming
plans' checks, and the beat spec's frames within 1 f) as pass or fail. `compare` writes
`compare/CB12/<option>.mp4`, `compare/CB13/<option>.mp4` and `compare/CB12.json`, `CB13.json` (a
manifest branch each; it leaves `manifest.json` alone). The killing number is also checked from
pixels: how red a 40 px box round it is (mean of r minus the larger of g and b), held over half its
level to the spec's last full frame and over a tenth to the card's last. A warm card under it adds
red, so today's reads early. The D1 trace check is listed as n/a: B and C have no trace.

CB12's clips are the whole screen (its `crop`), one segment per fight, lined up on the result (R,
as the spec says), so B's travel shows as how much later its hit lands than C's. CB13's are the usual board crop, one segment per death, lined up on the killing hit (H;
the death starts at H+34 in every option): Prophet of the Dust killed attacking (moment b, the
death the pilot names) and the last kill, into the result.

Readings of the pilot's specs that they do not spell out: a strike's frames are its in-between
frames and contact is the frame after (B's C = R+47); on a big loss the first landing shakes 12 px
and counts the base, the second 18 px and the last 3; the first count is squeezed to end before
the second contact when that comes first (B: C+15, C: C+16, against the spec's C+20); C's knock
"into the loser's window" is down for yours and up for theirs; the landing's light returns to 1.0;
B's tip turns round the bottom corner on the side its death direction points to; B's striker
flies onto the loser's portrait, and the Health badge and the "−N" are drawn above it, instead of
the striker stopping on the far side of the disc (E6). The spec's
totals for a big loss (B R+79, C R+68) do not follow from its own beat tables (R+72, R+58); the
tables are what is built.

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
