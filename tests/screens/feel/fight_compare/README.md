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

## What the logs can't show

- The film is silent. Sound rows are the cues the sound player started, at the frame they
  started; a cue with a delay is timed by the wall clock, so its frame in a slow film is early.
- Contact is geometric (the attacker's nearest point to where its target stood), not a rule: a
  treatment whose attacker passes through or overshoots its target needs its own definition.
- Everything else in `tools/feel/README.md` ("What it cannot do"): software rendering, one size.
