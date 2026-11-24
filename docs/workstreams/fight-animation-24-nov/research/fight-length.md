# Fight length: late fights today and under the proposal (24 Nov 2026)

**Why.** A playtester the owner trusts, a top Battlegrounds player: "fast mode, the fights are pretty slow so a button to toggle it to be really fast could be cool." The owner: "a speed toggle would be good for fights, but hopefully, animations fixes that, right? The idea is that we don't need a speed toggle because animations will be in a better spot." A clearer wind-up adds time, so this page puts numbers on it.

Frames (f) at 60 fps. "To the result" runs from the fight screen's first frame to the frame the result shows; the result's own hold (1.5 s today, 90 f in the proposal, and the game's 2.5 s after-fight wait over it) is the same in every row and left out. Nothing here has been watched by a person (`docs/AGENT-BLIND-SPOTS.md` 1 and 4).

## The answer

- **The proposal makes late fights shorter, not longer: median 30.7 s today, 18.0 s under `best` (−41 %).** It is shorter in every one of the 400 fights (between 25 % and 95 % of today's length). Rule 7 accounts for 0.5 s of that (18.5 s without it).
- **Today's late fights are slow because of triggers, not attacks.** Trigger steps take 15.2 s of a mean late fight today, half its length. The proposal plays them in 3.7 s. The clearer wind-up costs about 1.3 s a fight (CB1 "today" 16.7 s against best's 18.0 s), because in a busy fight the next attacker's lift hides under the queue.
- **18 s is still slow next to Battlegrounds as the tester plays it now.** Our fights at Battlegrounds' measured normal pace would run about 26 s; Battlegrounds speeds long fights up to about twice that pace, about 13 s.
- **Target: a median late fight of 12 s or less to the result, with the 90th percentile at 15 s or less.** That is our fights at Battlegrounds' own long-fight pace, a little faster, and 60 % under the length the tester called slow.
- **What gets there:** a fight-wide speed-up from the 5th attack (Battlegrounds 31.6's rule), plus grouping beats. The best measured combination gives 12.1 s median (p90 14.4 s). Rule 7 alone, even made stronger, cannot: it saves at most 1.5 s.
- **The toggle:** with the target met, no toggle is needed to fix "slow". Experts who know every card will likely still want one, as in Slay the Spire, Super Auto Pets and Balatro. Today's Skip (Space) already covers "show me the result". That choice is the owner's.

## The fights

- **Source:** the league's final bots, red and blue (labels `red` and `blue` only, not the climb checkpoints), from the ghost field `/data/third-run/field-fa1d51ec`. Its rules hash, fa1d51ec, is this build's. These are the strongest bots we have (the soak's SimpleBot and RandomBot boards are not typical late boards).
- **How a fight is made:** for each round 8 to 12, 80 random pairs of runs still playing at that round (seed 2411). Each pair's recorded boards for that round fight each other in the rules core, as an async game fights a ghost (`GameSession._fight`), side 0 live as the player's. Every one of the 400 had seven units a side, so none was dropped.
- **How busy they are (median per fight):** 10 attacks (3 to 17), 28 triggers (2 to 52), 18 deaths, 6 summons, 41 damage events, 132 log events. 99 % of attacks have a death or a trigger before the next attack.
- **Saved:** `/data/fight-anim-work/fight-length/fights/<name>.json`, each with its spec (run IDs, round, fight seed: enough to fight it again) and its full log. `lengths.json` beside them has every fight's numbers.

## How each length is counted

- **Today:** `FightReplay.build`, the game's own steps and holds, each held as `FightScreen` holds it (one 1/60 s frame at a time until its wait reaches 0).
- **Best and its options:** `best_timeline.gd`, the schedule `best_screen.gd` plays, built from the same log. Each contested branch is an option. CB2, CB3 and CB4 don't change length and were left out. CB7's options other than `best` run without rule 7, as in the CB7 clips.
- **What-ifs**, not in the proposal: R7 (rule 7's numbers: x2 top speed; "early", over 60 f of queue and from its 30th frame; both), and G2 or G3 (up to 2 or 3 single beats in a row start together, plan B's "up to 3 different triggers at once"). A speed-up after N attacks and a speed toggle are computed from each schedule's own cycles (every frame of a cycle divided by that cycle's speed). They are upper bounds: the floors in GUIDELINES.md (lift 6, hold 9, falls 10) would keep some frames.
- **Checked against real frames.** The headless count gives the same frame as every existing film of the comparison fight and of CB7's fight: today 689 to the result and 780 in all (film 689, 780), `best` 634 and 724, and every CB1, CB5, CB6, CB7 and CB8 option. Late fights filmed for this page are in the table below.

## Lengths (seconds to the result)

| | Median | 90th pct | Longest | Median vs today |
|---|---|---|---|---|
| **today** | **30.7** | **40.4** | **55.3** | |
| **best** (rule 7 on) | **18.0** | **22.2** | **28.1** | −41 % |
| best without rule 7 | 18.5 | 22.8 | 28.6 | −40 % |
| CB1 wind-up: today's (4 f, no hold) | 16.7 | 20.9 | 26.9 | −46 % |
| CB1: A (10 + 18 f) | 18.3 | 22.6 | 28.4 | −40 % |
| CB1: B (8 + 14 f) | 17.3 | 21.4 | 27.5 | −44 % |
| CB1: C (10 + 14 f) | 17.7 | 21.9 | 27.8 | −42 % |
| CB5 fall: B (C+14) | 16.1 | 19.7 | 24.6 | −48 % |
| CB5: C (C+24) | 17.2 | 21.3 | 26.8 | −44 % |
| CB5: Battlegrounds (C+60) | 22.3 | 27.5 | 34.4 | −27 % |
| CB6 next lift: B (C+8) | 17.1 | 21.2 | 27.3 | −44 % |
| CB6: A (C+36) | 17.5 | 21.5 | 27.3 | −43 % |
| CB6: Battlegrounds (C+40) | 17.7 | 21.7 | 27.3 | −42 % |
| CB7 combo: Battlegrounds (one at a time) | 20.1 | 28.0 | 38.7 | −35 % |
| CB7: A | 18.6 | 23.0 | 29.0 | −39 % |
| CB7: B | 18.2 | 22.5 | 27.9 | −41 % |
| CB7: C | 18.5 | 22.8 | 28.6 | −40 % |
| CB8 staggered falls: b (4 f, cap 24) | 17.4 | 21.5 | 27.5 | −43 % |
| CB8: c (10, 7, 5, 4 …, cap 30) | 17.8 | 22.1 | 27.9 | −42 % |
| CB8: d (12 f, no cap) | 17.9 | 22.3 | 28.0 | −42 % |

CB8's staggers come out a little shorter than "all at once", because each death's gain lands with its own fall and not after the group.

By round, the median is 27.7 s today at round 8 and 32.9 s at round 12. Under `best` it stays between 17.4 and 18.5 s at every round. In the busiest third of fights (31 triggers or more) today's median is 37.6 s and best's 20.2 s; in the quietest third (23 or fewer) 24.5 s and 16.3 s.

## Where the time goes

The mean late fight, in seconds. Each frame is counted once, under the first of: an attacker's lift, least hold, strike or return (attack); a beat, from its pulse to the next one (trigger); a fall (death); an arrival (summon). Today's steps are counted by kind; a splash or change after a trigger is the trigger's.

| | today | best |
|---|---|---|
| Start hold | 0.7 | 0.5 |
| Attacks | 9.1 | 7.7 |
| Trigger beats | 15.2 | 3.7 |
| Deaths | 3.9 | 2.4 |
| Summons | 2.1 | 0.5 |
| Pauses with nothing moving (numbers being read, between the return home and the next lift) | — | 3.1 |
| Aura and other changes with no trigger | 0.2 | 0.0 |
| After the last event, to the result | — | 0.4 |
| **Total** | **31.2** | **18.3** |

(The means are a little above the medians.) Under `best`, attacks are 42 % of a late fight and the 16 f pause after each return another 17 %. Triggers, the thing that made today slow, fall to 20 %.

**One attack cycle** (an attacker's first motion to the next attacker's): median 2.6 s today and 1.65 s under `best`; 90th percentile 4.8 s and 2.5 s; each fight's longest cycle has a median of 5.0 s and 2.6 s.

**The longest single cycle** is the same attack in both: fight `r12-015`, attack 2, a Famine-caller hit that sets off a Locust wipe (13 deaths, 13 Gleans, 5 death-damage-to-all, 5 Plagues, 2 Molts, 44 damage events). Today it takes **22.6 s**; `best` takes **7.1 s**, and 9.5 s without rule 7. This is the case the owner described on 18 Nov ("one attack could take … 3 or 4 seconds"); the proposal's combo and rule 7 still leave it at 7 s.

## Against Battlegrounds

The research has cycle times, not whole-fight lengths (`battlegrounds.md`): a plain attack every 76 to 83 f, one with a death 150 to 165 f, and late in long 2026 fights an attack every 34 to 50 f with chains about twice as fast (T3, T4). Patch 31.6: "Combat animations will now accelerate as the battle rages on and then slow down towards the end, for a dramatic finish." So the figures below are our 400 fights' attacks played at those cycle times, a model:

| Our late fights at | Median | 90th pct | Longest |
|---|---|---|---|
| Battlegrounds' normal pace (80 f plain, 157 f with a death or trigger) | 26.2 | 34.0 | 44.5 |
| the same, at its long-fight ~2× | 13.1 | 17.0 | 22.2 |
| its sped-up attack alone (40 f each; no chains, a lower bound) | 6.7 | 8.7 | 11.3 |
| today | 30.7 | 40.4 | 55.3 |
| best | 18.0 | 22.2 | 28.1 |

Today is a little slower than Battlegrounds at its normal pace. `best` sits between Battlegrounds' normal pace and its long-fight pace. The model's 157 f is the low end for a busy attack (Battlegrounds' chains run 100 to 550 f), so real Battlegrounds fights like these would be longer than the model says.

## The target, and what gets there

**Target: median late fight ≤ 12 s to the result (about 13.5 s with the result), 90th percentile ≤ 15 s, no fight over 20 s.** Why:
- The tester plays Battlegrounds today, where long fights speed up. Our fights at that pace are about 13 s. Meeting it, or doing slightly better, is the least an expert won't call slow.
- 12 s is 60 % under today's 30.7 s, the length he called slow: a change big enough to notice.
- It leaves room for the clear wind-up. Attacks alone take about 7.7 s of a late fight at the proposal's pace, and their share has to shrink with everything else.

| What-if (seconds to the result) | Median | 90th pct | Longest | Saves on best's median |
|---|---|---|---|---|
| best | 18.0 | 22.2 | 28.1 | |
| rule 7 at x2 top speed | 17.8 | 22.0 | 27.8 | 0.2 |
| rule 7 early (over 60 f, from 30 f) and x2 | 16.5 | 20.2 | 25.7 | 1.5 |
| group up to 2 single beats | 16.5 | 20.3 | 25.4 | 1.5 |
| group up to 3 single beats | 16.2 | 19.8 | 24.8 | 1.8 |
| group 3 + rule 7 early x2 | 15.3 | 18.9 | 23.4 | 2.7 |
| best, everything x1.5 from attack 5 | 14.5 | 17.3 | 21.7 | 3.5 |
| best, everything x2 from attack 5 | 12.9 | 14.9 | 18.5 | 5.1 |
| best, rising x1 → x2 over attacks 2–6, last attack x1 | 12.6 | 14.6 | 18.7 | 5.4 |
| **group 3 + rule 7 early x2, everything x1.5 from attack 5** | **12.1** | **14.4** | **18.0** | **5.9** |
| group 3 + rule 7 early x2, rising x1 → x2 over attacks 2–6, last attack x1 | 10.6 | 12.4 | 15.8 | 7.4 |
| best with a speed toggle x1.5 | 12.0 | 14.8 | 18.7 | 6.0 |
| best with a speed toggle x2 | 9.0 | 11.1 | 14.0 | 9.0 |
| today with a speed toggle x2 | 15.4 | 20.2 | 27.7 | |

What each rule is worth:
- **A fight-wide speed-up after N attacks** (Battlegrounds 31.6) is the rule that matters: 3.5 to 5.4 s. It is the only rule that touches the attacks and pauses, now 60 % of a late fight. At x1.5 the wind-up stays above the guideline's floor (lift 6.7 f, hold 10.7 f); at x2 it falls below it (5 and 8 f), so x2 would need the floors kept, which saves less than the table says.
- **Grouping single beats** (up to 3 different triggers at once): 1.5 to 1.8 s. It cuts trigger time, already small. It needs a look the owner hasn't seen: two or three sources pulsing at once.
- **A faster rule 7**: 0.2 to 1.5 s. Rule 7 only acts on queues over 120 f, about 1.2 attacks a fight. Moving its threshold to 60 f helps; raising its top speed alone does not.
- **CB picks that cut length:** CB5 "b" (fall at C+14) saves 1.9 s and CB6 "b" (lift at C+8) 0.9 s, but the proposal rejected both for clarity. CB1's wind-up costs 1.3 s against today's 4 f; A's longer hold costs 0.3 s more.

## The speed toggle

- **Without more speed-up rules,** the proposal leaves late fights at 18 s, about 40 % over the Battlegrounds long-fight pace. An expert would likely still ask for a toggle.
- **With a fight-wide speed-up after attack 5, and grouping,** the median is about 12 s, the target. Then a toggle isn't needed to fix "slow".
- **Experts may still want one.** Players who know every card skip the reading time: Slay the Spire's Fast Mode, Super Auto Pets' Fast button (lit in every fight in R2's footage), Balatro's game speed. A x2 toggle on top of the target would put a late fight at about 6 s. The fight screen already has a playback speed (`FightScreen.speed`), but sound cue delays run on the wall clock (best.md section 7), so a toggle needs that fixed. Skip (Space) already jumps to the result.
- So the toggle is a convenience for experts, not the fix. Whether to have one is the owner's call.

## Filmed checks

The films play the late fights through the real fight screen (`fight_compare.tscn`, `"fight": "spec:<path>"`), at a true 60 fps (`tools/feel/film`). Frames below are counted from the fight screen's first frame. The film itself adds 3 frames before it.

| Fight | Why this one | today: headless / film (to the result, all) | best: headless / film |
|---|---|---|---|
| `r10-074` | the median today (11 attacks, 25 triggers) | 1844, 1935 / 1844, 1935 | 1054, 1144 / 1054, 1144 |
| `r12-025` | the 90th percentile today (12 attacks, 34 triggers) | 2422, 2513 / 2422, 2513 | 1348, 1438 / 1348, 1438 |
| `r12-015` | the longest single cycle (4 attacks, 39 triggers) | 2022, 2113 / 2022, 2113 | 798, 888 / 798, 888 |

All six agree to the frame. Every film's last board equals the rules core's (`core_matches`). In the `r12-015` best film the Locust wipe's attacker starts at film frame 190 and the next at 614: 424 f, the 7.1 s above. The films are in `/data/fight-anim-work/fight-length/films/`.

## What this can't show

- **Whether any of it reads as slow or fast.** No one has watched these schedules. A 12 s fight that a person can't follow is not the goal.
- **Bot boards, not players' boards.** The league bots fill all seven slots by round 8. Players' boards may be busier or quieter. A human fights a ghost, which these pairs reproduce, but the pairing here is random within a round, not by the matchmaker's health bands.
- **Timeline bends.** 161 times across the 400 `best` schedules (0.4 a fight), `best_timeline.gd` had to show an event later than planned to keep the board true. That moves when a number shows, not the fight's length.
- **Sound.** Cue delays are wall-clock time (`delay_s`) and won't follow a speed-up. Silent films.
- **The speed-up what-ifs are upper bounds** (floors not modelled). Rule 7's ramp and the "after N attacks" rule are guesses (G), as best.md says of rule 7.

## Re-run

```bash
godot --headless res://tests/screens/feel/fight_compare/fight_length.tscn -- \
  field=/data/third-run/field-fa1d51ec out=/data/fight-anim-work/fight-length   # ~5 min, one core
python3 tests/screens/feel/fight_compare/fight_length.py /data/fight-anim-work/fight-length
godot --headless res://tests/screens/feel/fight_compare/fight_length.tscn -- fights=compare  # the fixture check
tools/feel/film /data/fight-anim-work/fight-length/films/r12-015-best.json /data/fight-anim-work/fight-length/films/r12-015-best.mp4
```

`fight_length.py` writes `summary.json` beside `lengths.json`.
