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

`today` is `fight_treatment.gd` itself: `today_motion.gd` and `FightReplay.build`. Since 25 Nov
the game's `FightMotion` turns every attacker toward its target (plan step 1a,
`docs/workstreams/fight-animation-24-nov/PLAN-implement.md`), so `today_motion.gd` keeps the
game's motion from before that, a full copy that later changes to `src/` don't reach: `today`,
`pilot` and the rotation switch film what they filmed before the port. Refilmed on seed 22 after
the port, `today`'s `cards.csv` equals the one filmed before it, frame for frame.

`game` (`game.gd`, scenario `fight-compare-game.json`) is the game's own fight screen on the same
fight: it plays the schedule (`src/screens/fight/fight_timeline.gd`), which is `recommended`
with the owner's picks and both late-fight speed-ups, minus CB13 c (plan steps 1b, 3 to 5;
`{"ROTATE": "off", "CB9": "aim_lean", "CB13": "none", "FAST": "a5", "GROUP": 3}`; recommended
adds CB2 b, CB3 mild, CB8 c and CB14 c itself), frame for frame
(`tests/screens/test_fight_timeline.gd`). `"CB13": "none"` leaves recommended's single death out.
The game's stat gains are logged to `<stem>.buffs.csv` as `buffs` logs them. `compare_screen.gd`
keeps the game's step playback from before 1b (b94a8021), so every other treatment plays as it did.
`buff_screen.gd` draws the gains from the schedule's clock (`_t`), which is the drawn frame except
under FAST.
Beyond the fixture, the game turns every jab toward its target (the turn's numbers, over the
jab's frames), so on film the two `cards.csv` differ only in `rotation`, on the jabs' frames;
`test_fight_timeline.gd` checks the rest pose for pose. The game also plays three best.md rules
the fixture leaves out: Start of Combat as beats after the 30 f rest, an attacker whose target
died before the hit settling back unstruck (8 f), and pilers jabbing 5 f apart.

Sound cues that moved with the schedule (nothing retimed by hand; seed 22 and `r10-074`):

- **Hit**: at its burst (contact + 2), not when the splash step showed: the first at 1.08 s
  (today 0.93 s). Thorns sounds at its own landing (3.03 s) instead of sharing the exchange's
  splash (3.32 s). Seed 22 has 6 light hits against today's 8.
- **Trigger**: at each source's pulse. Old Brock's six gains sound six times (8.15 to 8.95 s;
  today once, as identical steps were dropped): seed 22 has 10 against today's 5.
- **Start of Combat**: each trigger at its beat after the rest (`r10-074`: 0.5, 0.8, 1.1 s;
  today 0.7, 1.3, 2.0 s).
- **Death** at the fall's start (an exchange kill at contact + 30), **summon** at the arrival,
  **result** as it shows (seed 22: 10.57 s, today 11.48 s; `r10-074`: 18.1 s, today 30.7 s).
- **Skip** plays only the result.

`turn_check.py` reads the logs: `same` (two films' `cards.csv` frame for frame, `--except` some
columns), `turns` (every attacker turned toward its target by the game's numbers at contact, and
the core check), `sounds` (the cues at the same frames) and `cut` (the picks page's whole-fight
crop and scale):

```bash
tools/feel/film tests/screens/feel/fight-compare-game.json /data/fight-anim-work/game-2/films/game.mp4
# recommended-picks.json: "treatment": "recommended", "options": {"ROTATE": "off",
#   "CB9": "aim_lean", "CB13": "none", "FAST": "a5", "GROUP": 3}
tools/feel/film recommended-picks.json /data/fight-anim-work/game-2/films/recommended-picks.mp4
python3 tests/screens/feel/fight_compare/turn_check.py same /data/fight-anim-work/game-2/films/game /data/fight-anim-work/game-2/films/recommended-picks --except rotation
```

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

## The amount of turn and the tip's strength (CB15, CB17)

Two more clip groups of CB9 options, like CB10 and CB11 (every film at stop B and the quad
ease-in, the same four attacks, lined up at C). The owner, 24 Nov: rotation is in, the lean alone
out ("Where's the rotate amount?"), and a small lean in the turn's direction may be nice.

- **CB15, the amount of turn**, each with the medium tip: `tip_half` (half the path's angle),
  `tip_3q` (three-quarters), `tip_medium` (95 %, CB9's amount) and `tip_cap30` (95 %, the full
  turn no more than 30 degrees; 90 % of it is left at contact, as for every option).
- **CB17, the tip's strength**, each with the aim at 95 %: `aim` (no tip), `aim_lean` (no tip,
  plus the proposal's 4-degree in-plane lean, the same way as the turn: full through the hold,
  gone by contact; the owner: "A small lean, like four degrees, might be excellent"), `tip_small` (length
  0.965, keystone 0.97: about 15 degrees, since the length is the dip's cosine), `tip_medium`
  (0.85 and 0.94: about 32) and `tip` (0.75 and 0.9: about 41, CB9's).

```bash
python3 tests/screens/feel/fight_compare/clips.py scenarios /data/fight-anim-work/treatments/scenarios CB15 CB17
python3 tests/screens/feel/fight_compare/clips.py compare /data/fight-anim-work/treatments/films /data/fight-anim-work/treatments/compare 0.38 --only CB15 CB17
python3 tests/screens/feel/fight_compare/clips.py cut /data/fight-anim-work/treatments/films /data/fight-anim-work/treatments/clips CB15 CB17
```

## Late-fight speed-ups (CB16, `speed_clips.py`)

One real late fight filmed whole: `r10-074`, the median late fight in `research/fight-length.md`
(11 attacks, 25 triggers), today, `best`, and `best` with the length what-ifs stacked one by one.
Every `best` pane turns (`speed_clips.py` `ROTATE`: `tip_medium`, CB9's timing, and CB11's mild
strike), which moves no frame; `today` is the game's own motion with `"ROTATE": "on"`. The what-ifs:
`"FAST": "a5"` (a fight-wide speed-up, x1.5 from the 5th attack's lift to the result, as
Battlegrounds 31.6 does), then `"GROUP": 3` (up to 3 different triggers at once), then
`"R7": "early_x2"` (rule 7 over 60 f of queue, from its 30th frame, to x2): the page's best
combination. FAST is a clock, not a new schedule: `best_screen.gd` moves the schedule
`best_timeline.gd` `speed_at()` frames each drawn frame (`advance()`), so every pose, burst, glow
and step plays 1.5 times faster, the card keeper's own tweens (falls, rolling numbers) take the
step's speed times 1.5, and the contact pop holds one drawn frame (`clock_step`). The result
lands on its own frame and its hold plays at x1. The plan's frames in the report are the
schedule's, so after FAST starts they are not film frames (`plan.fast` has its start). `best`
plays no sound cues, so FAST has none to speed up.

```bash
python3 tests/screens/feel/fight_compare/speed_clips.py scenarios /data/fight-anim-work/treatments/scenarios/speed
tools/feel/film /data/fight-anim-work/treatments/scenarios/speed/cb16r-fast.json /data/fight-anim-work/treatments/films/speed/cb16r-fast.mp4
python3 tests/screens/feel/fight_compare/speed_clips.py measure /data/fight-anim-work/treatments/films/speed
python3 tests/screens/feel/fight_compare/speed_clips.py compare /data/fight-anim-work/treatments/films/speed /data/fight-anim-work/treatments/compare
python3 tests/screens/feel/fight_compare/speed_clips.py cut /data/fight-anim-work/treatments/films/speed /data/fight-anim-work/treatments/clips
```

`measure` prints each film's length to the result (the report's `result_at`, the figure
`fight-length.md` uses) beside the headless count it should match (`lengths.json`, with FAST as
the clock plays it) and the core check; `compare` keeps the same numbers, and the sound cues
started, in `CB16.json`.
The clips are the whole fight from its first step (F+0) at the usual 0.38, in a taller crop
(`speed_clips.py` `CROP`), since a late fight's back rows fall outside the comparison fight's; a
shorter pane holds its last frame.

## `buffs`: how a stat gain shows (CB14)

`buffs.gd` plays CB14 (`docs/workstreams/fight-animation-24-nov/buff-look/DESIGN.md`, section 2)
on top of `best` (every other branch at its pick, CB8 at "a"): `"treatment": "buffs", "options":
{"CB14": "a"}`. Every gain beat (a trigger whose effect is a buff) is scheduled by DESIGN.md's
beats in `buff_timeline.gd`; `buff_screen.gd` draws it. `"none"` is `best` unchanged (the test
checks it).

- **A, swell and count:** only the changed disc swells, x2.0 at L, held to L+2, back by L+14; its
  digits count from old to new over 8 f in the green "up" colour (`buff_disc.gd` draws the card's
  own setting and number scaled, over the card; the card itself never scales). L is 6 f into a
  gain to itself, 12 f into a gain to another card (after today's jab).
- **B, running total:** A plus a "+N" tag over each changed disc, its centre 38 px above the
  disc's top: in at L-2 at x0.5, x1.25 at L+2, x1.0 by L+6; each later gain re-pops it from x1.35
  with the running total; it sinks from the last L+30 (25 px down, to x0.4, fading) and is gone at
  L+36. The queue goes on once the discs settle (the last L+14): the tag's tail runs under what plays
  next, as DESIGN.md's one-gain case says.
- **C, carried total:** B, with each gain's tags born at their cause and flying 10 f on a low arc
  (at most 0.15 h) into the tally, which pins at the first landing (no L-2 entry); the disc flares
  for 8 f at each landing. A death's gain is born at the dead unit's empty slot, at the disc's
  place, as its fall ends; a giver's at f4 of its beat (a gain to itself rises 8 f).
- **Old Brock x6 (moment e):** beats at F+0, 18, 32, 42, 50, 56 (F: the six falls' end; gaps 18
  x 0.75^k, each rounded, floor 5; no rule 7 speed-up), landing 6 f in (A, B) or 10 f in (C). The
  k-th gain's cause is that side's k-th death in the log. Brock lights at F and stays lit (A to
  L+14 after the last; B and C to 2 f after the tally is gone).
- **Stand-ins** (the owner approved filming B and C with them, 24 Nov; no new art): the tag is the
  recruit screen's green gain pill (`RecruitTurnStart._gain_tag`), the flight its arc and arrive
  curve (`_arc_point`, `_arrive`), the flare its amber ring (`_ring`), stepped so it lasts 8 f in
  place of its own 0.38 s. They come from a `RecruitTurnStart` made with no recruit screen.

The log adds `<stem>.buffs.csv` (every piece drawn per frame: `key, what, stat, x, y, scale,
alpha, value, text`; `what` is `disc`, `tag`, `flight` or `flare`) and markers `gain_land`,
`tag_born`, `disc_rest`, `tally_appear`, `tally_sink`, `tally_gone`. Brock's card counts with
its disc, so `numbers` markers show every step of the count.

```bash
python3 tests/screens/feel/fight_compare/buff_clips.py scenarios /data/fight-anim-work/treatments/scenarios/buffs
tools/feel/film /data/fight-anim-work/treatments/scenarios/buffs/cb14-c.json /data/fight-anim-work/treatments/films/buffs/cb14-c.mp4
python3 tests/screens/feel/fight_compare/buff_clips.py measure /data/fight-anim-work/treatments/films/buffs/cb14-c
python3 tests/screens/feel/fight_compare/buff_clips.py compare /data/fight-anim-work/treatments/films/buffs /data/fight-anim-work/treatments/compare
python3 tests/screens/feel/fight_compare/buff_clips.py cut /data/fight-anim-work/treatments/films/buffs /data/fight-anim-work/treatments/clips
```

`measure` writes `<stem>.buffs.json`: G (the first frame Brock's drawn numbers rise in moment
e), F, the landings, the discs' scales and counts, the tags, the flights, and each check against
DESIGN.md's beats, pass or fail. On `today` and `best` the CB14 checks fail (no landings), which
shows they bite. `compare` writes `compare/CB14/<option>.mp4` (today, best, a, b, c) and
`compare/CB14.json`, lined up on G, cropped to your board (`CROP`, x0.6, so the digits show).

Readings of DESIGN.md it does not spell out: "38 px above the disc" is the tag's centre above the
disc's top at rest; C's tags fly to the tally's place, not the disc's centre, so the first pair
becomes the tally; C's tally sinks at the last L+30 like B's (DESIGN.md's Brock line says F+88,
L+24, against its own "sinks at L+30"); the flare runs with the swell from L; a dead unit's slot
uses Old Brock's disc places.

## Rotation everywhere (`rotate.gd`) and `recommended`

The owner, 24 Nov: "Every animation, I want to have the rotation included ... Even today can be
modified as if it had rotation." `"options": {"ROTATE": "on"}` turns it on in any treatment:

- `rotate.gd` `SET` holds the numbers every film uses until the owner picks CB15 and CB17: aim at
  95 % of the path, a medium lean (keystone 0.94, length 0.85). Change them there.
- `"ROTATE": "lean"` plays `rotate.gd` `SET_LEAN` instead: the owner's answer of 25 Nov (CB17
  `aim_lean`), the same aim with the 4-degree in-plane lean the same way as the turn (up with the
  lift, gone by contact), no tip, no shortening, from the numbers the game plays
  (`fight_motion.gd` `TURN_*`). Its test compares it with `FightMotion`'s own attack, which the
  game no longer plays in a fight since step 1b (the schedule turns the cards).
- `best`, `buffs`: `best_timeline.gd` `_rotation()` plays `SET` in place of CB9's option (CB9's
  timing, as before).
- `today`, `pilot`: `rotate_motion.gd`, today's motion exactly (its 6-degree cock, 12-frame
  attack, 2 frames at contact, 11-frame return, straightening while it waits at contact) with the
  turn and lean added on top, on CB9's timing as far as today's attack allows: the turn ramps from
  the lift's first frame and is full as the 4-frame lift ends (today has no hold, so it can't be full
  at C-12), 90 % at contact, held through a wait at contact, unwound over 25 frames from the
  return's start. `pilot_motion.gd` extends it, so CB13's options turn too.
- CB12 B's striking portrait turns toward the loser on the same timing (`pilot_hero_damage.gd`
  `_aim`: full at C-12, held between a big loss's two strikes) and shortens along that line. It
  has no keystone: the portrait is a `GlassBox`, drawn by its own shader material, which
  `tip.gdshader` would replace (filmed, it drew a white square). B's own 8-degree lift lean stays.
- Off, every treatment is as it was (the tests check `today` is still `today_motion.gd`).

`recommended.gd` plays every pick on the picks page in one fight: `buffs` with `ROTATE` on, CB11
"mild" (CB2 "b", CB3 "mild"), CB8 "c", CB14 "c", and CB13 "c"'s death (the light goes out and it
sinks: `pilot_motion.gd`, drawn from `recommended_screen.gd`'s game clock) for a unit the schedule
drops alone (not one of CB8's staggered six). The pilot's other half of CB13, the killing number
held on through the death, is today's step screen's (`pilot_screen.gd`); here the number is the
best proposal's burst. A scenario's own options win over the picks.

`picks_rot.py` films and cuts the picks page's pairs with rotation on in both panes, and the whole
fight (today with rotation against `recommended`, both filmed with the same wait so the panes have
the same frames):

```bash
python3 tests/screens/feel/fight_compare/picks_rot.py scenarios /data/fight-anim-work/picks-rot/scenarios
tools/feel/film /data/fight-anim-work/picks-rot/scenarios/best.json /data/fight-anim-work/picks-rot/films/best.mp4
python3 tests/screens/feel/fight_compare/picks_rot.py measure /data/fight-anim-work/picks-rot/films
python3 tests/screens/feel/fight_compare/picks_rot.py cut /data/fight-anim-work/picks-rot/films /data/fight-anim-work/picks-rot/v
```

`cut` writes `v/<branch>-<option>.mp4` (`whole-today.mp4`, `whole-best.mp4` for the whole fight),
each pair lined up and cut as `clips.py compare` and its siblings do, at their compare scale, and
`v/pairs.json`: each pair's two files, labels, frames and film frames, and the whole fight's
victory times.

## What the logs can't show

- The film is silent. Sound rows are the cues the sound player started, at the frame they
  started; a cue with a delay is timed by the wall clock, so its frame in a slow film is early.
- The report's contact is geometric (the attacker's nearest point to where its target stood),
  not a rule; `clips.py measure` uses the `best` plan's contact instead, since an attacker that
  stops past the centre (CB2 "galaxy") is nearest the centre before it stops.
- Everything else in `tools/feel/README.md` ("What it cannot do"): software rendering, one size.
