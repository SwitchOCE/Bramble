# Review: round 4 (0cb68b3..93c1a50 on ideation/round4)

Fresh cloud reviewer, 7 Nov 2026. Method: `CLOUD.md`, "How a cloud reviewer reviews". No code changed; two temporary mutations were reverted.

**Counts:** 6 changes reviewed. Keep 3, ask 2, cut 2 (fix before merge), simplify 0.

**Does it move the problem?** Mostly yes. Guide order, geometry, Shy, the bugs and the finish items from `playtest-3.md` are fixed. The ladder moved but overshot: Easy is now no harder than random play. The toll shortens games by about 3 rounds, but it doesn't touch the stall itself: ties went up and spare gold stayed the same, as the worker says.

**Cut (fix before merge):**
- C1. Guide page 10 and the toll text overstate the toll and misstate the cap. The guide says "Early-round caps limit big hits" and "Early caps still apply". In the game config, though, the cap stays at 12 for the rest of the game (`SLICE_DAMAGE_CAPS` is clamped to its last entry, `damage_cap_off_at_alive` is 0). Late losses already reach 12, so a toll of 7 adds nothing. Even so, the result panel says "Includes round toll 7", and End turn says "Loss/draw toll: 7".
- C2. `DECISIONS.md`: the five new entries were pasted inside the `Format:` line, splitting it in two (`Format: \`### 8 Nov 2026 — Round 4…` … `### date — the question\`, then **Picked**…`). Put them under the format line.

**Ask (orchestrator's call):**
- A1. Easy has overshot: measured, it plays like Naive (4.07 ± 0.75 among Naive), and a board left untouched from round 7 still came 2nd. Loosen Easy by one notch (for example simple placement instead of random, or tier 5), then aim for a measured gap between Easy and Naive.
- A2. The toll is a clock, not a mistake signal. Keep it only if C1's wording is fixed. The 56-gold stall needs its own fix (a gold sink or late shop) after the tribe round.

## 1. Ladder: ask (A1)

Played (`tools/play/play.sh`, real rules):

| Game | Level, seed | How I played | Result |
|---|---|---|---|
| E1 | Easy 711, Mousewife | By hand to round 7 (Rainbow, 7 bands), then a greedy driver (tier up, buy the highest-tier unit) | **1st, 16-0, never lost a fight, finished on 40/40** |
| E1-lazy | Same save from round 8 | Pressed End only, 11 rounds, tier 3 board, 125 gold unspent | **2nd** |
| E2 | Easy 912, Bracken | Greedy driver from round 1, no plan | **1st**, lost rounds 4 and 5 only, unbeaten from round 6 |
| H1 | Hard 333, Mousewife | By hand: Oozes, Mire, mixed | **6th**, 6-1 to round 6, then five straight losses (8, 6, 11, 10, 12), out in round 11 |

Bench, my run on the target commit (`tools/sim/bench.sh --cores 4 --seed 501 hard_naive=40 hard_normal=60 easy_naive=30`):

| Suite | Games | Avg place | Win | Top 4 | PLAN bar |
|---|---:|---:|---:|---:|---|
| Hard among Naive | 40 | 1.00 | 100% | 100% | top 4 ≥85%, win ≥45%: **pass** |
| Hard among Normal | 60 | 2.57 ± 0.40 | 33% | 87% | ≤3.5: **pass**, upper bound 2.97 |
| Easy among Naive | 30 | 4.07 ± 0.75 | 13% | 57% | no bar; 4.5 is chance |

- Hard among Normal meets PLAN on a fair sample: 2.63 ± 0.62 over 30 (worker) and 2.57 ± 0.40 over 60 (mine, different seeds). Both upper bounds clear 3.5. Hard among Naive passes easily. Hard among Easy at 1.00 has no bar.
- Easy is now trivial. Easy bots place at random, stop at tier 4, buy no spells or economy cards and replace one unit a turn. Measured, they are indistinguishable from Naive. That matches the worker's numbers (Normal among Easy 1.00; the plain policy 1.70).
- Is "how far can I get" still a three-level ladder? Two rungs, not three. Any plan wins Easy, so its record means nothing after game one. Hard is a real wall, like playtest 3. I didn't play Normal; the bench puts it well above Easy, so the gap between Easy and Normal is wide. The newcomer's "ten straight losses on Easy" is fixed, at the cost of the bottom rung.
- Not run: Hard among a Hard lobby (the lobby a human meets on Hard), and Normal among Naive.

## 2. Round toll: ask (A2), with cut C1

- The rule, `maxi(1, round - 7)`, is added before the cap, as the docs say. When I changed it to `round - 8`, the pacing test failed, so the rule is tested.
- Fair? Early on it's mild and clear: rounds 1–2 draws cost 1, early losses +1. From round 9 it turns medium losses into near-cap hits. In H1, rounds 9 and 10 cost 11 and 10. Being down to 1 health after round 10 felt like the timer, not a misplay.
- Explained? The guide puts it at the end of page 10, the densest page. End turn shows "Loss/draw toll: N" in small type. The fight result adds "Includes round toll N (before any cap)". With a permanent 12 cap, that line is wrong in most late losses (C1). When I removed the toll line from the result panel, every round-4 UI test still passed, so it's untested.
- Mistake or clock? A clock. It is the same for everyone and doesn't respond to anything you chose. It shortens games, but it raised the tie rate (12.6%→13.7%, 12.9%→15.2%) and left spare gold unchanged (worker's own table). The playtest-3 stall of 56 gold with nothing to buy wasn't reproduced and isn't addressed.

## 3. Guide: keep, with C1

I rendered all ten pages at 1688×780 (`tests/ui/shots/screenshot.gd guide_1..guide_10`). No overlap and no clipped text. Order: buy and place → income → tier up, refresh, freeze, sell → hero and spells → growth and triples → brick-wall geometry → front row takes hits → attack order → Scout → damage, toll and elimination. That is the right order for a newcomer, and it answers playtest 3's B2 list (gold, tiering, refresh, freeze, spells, heroes, growth). The keyword survey is gone, which is good.
- Page 1's picture shows three shop cards but no hand or board. The text says "drag it from your hand to an empty slot", and the picture doesn't show that.
- Page 10 reuses page 7's "Can be hit / Safe for now" picture. It is the only page about winning, losing and Health, and it's the densest. Its cap wording is wrong (C1). A picture of the health bar and the damage sum would teach it.

## 4. Geometry and Shy: keep

- `round4-geometry.jpg`: with Queen on F2 selected, B1 and B2 get gold strips, and the reader says "Highlighted: B1 and B2". Clear. At the same time, empty slots show the green move hints ("in front of B1", "before B2 & B3"). Two highlight systems on one screen is a little busy, but the read is right.
- Shy: the warning appears only when a forecast says a Shy unit will leave. Repeating the same action confirms. A changed state warns again. The forecast doesn't mutate state (tests). When I made `_allow_shy` always return true, `test_shy_action_warns_before_mutation_and_repeat_confirms` failed, so the guard is tested. It isn't annoying, because it only fires when something would actually leave. The one cost: a player who wants the Shy walk-out for its 2 gold has to act twice every time. The toast sits over lobby plaques 2–5 (`round4-shy.jpg`). That's minor.

## 5. Bugs and finish: keep

- Hero collisions: no duplicate heroes in my three lobbies.
- Portraits stay on long shop cards (Hedge Witch, Sexton Beetle, Natterjack in the worker's render and in mine). Natterjack's name is clear. End turn shows the toll. Spell cost, Whirligig wording and Echo wording are covered by `test_round4_bugs`/`test_round4_finish`. I didn't check them in the UI myself.
- Mag Pye: not reproducible without the lost transcript. No power change was made, which is the right call.

## Gate and soak

- `./scripts/check.sh`: all ten steps passed, **1,175/1,175**, strict hook ok.
- `tools/checks/soak.sh 100 81`: **100 games (seeds 81–180), 1,530 rounds, 4,812 fights, 0 violations, exit 0**, 70 s. 3 `no_attacks` endings, none a violation. Not reached this run: `on_summon`, `on_home`, `on_swallow`.
- Not done: Normal play, real device, Hard among a Hard lobby, the full 2,000-game bars, a UI check of the Whirligig and Echo text.

## In short

Five of six items land: the guide is in the right order, geometry and Shy are clear and tested, the bugs and finish items are fixed, gate 1,175/1,175 and soak clean. Hard passes both PLAN bars (2.57 ± 0.40 among Normal over 60; 100% wins among Naive). But Easy now plays like a random bot (4.07 among Naive). I won both Easy games, one undefeated on 40 health, and a board left alone from round 7 still came 2nd. That's two rungs, not three. The toll shortens games but works as a clock, and its text claims effects the permanent 12 cap cancels. Fix C1 and C2, and loosen Easy one notch.

## Follow-up review: 93c1a50..ede4f80 (7 Nov 2026)

Same reviewer, same method; code unchanged by me (one temporary mutation, reverted).

**Counts:** C1 fixed, C2 fixed, A1 resolved. New: cut 0, ask 2.
- A3. Normal's lift is a blunt handicap: no shop spells before round 12, so early Normal shops less than Easy. Fine for now, but replace it with a skill limit later and record it as such.
- A4. Easy's one-replacement rule with an 8-point margin shows as stupid on Scout: a tier-5 Easy bot keeps a 1/2 Little Dollop in front from round 5 to round 15. Let Easy replace its weakest unit once it is two tiers behind.

### C1 toll and cap text: fixed
- Guide page 10 (rendered at 1688×780) now says no fight deals more than 12, the cap reaches 12 in round 10 and stays there, and Armor applies first. It fits with no overlap. It's still the densest page and still reuses page 7's picture; that's minor, not a cut.
- End turn shows "Toll: up to 1; hit cap 9" (my recruit render). The numbers are true. "hit cap" can read as "you hit the cap"; "Loss: +1, max 9" would be plainer.
- The result and log now report the damage the toll actually added after the cap (`round_toll_added`). This time, removing the result-panel toll line fails `test_toll_result_and_hint_show_cap_limited_damage`, so the line that was untested before is now covered.

### C2 DECISIONS format: fixed
The `Format:` line is whole again, and every entry sits below it. The "owner will merge" wording was also corrected to the orchestrator, outside my items; that's harmless.

### A1 ladder
I reran it on fresh seeds (3001+), 4 cores, same code:

| Suite | Worker, seeds 2001–2100 | Mine, seeds 3001+ |
|---|---:|---:|
| plain among Easy | 3.11 ± 0.56 (100) | 3.25 ± 0.93 (40), 60% wins, 65% top 4 |
| Easy among Naive | 1.48 ± 0.18 (100) | 1.60 ± 0.37 (40) |
| Normal among Easy | 2.33 ± 0.46 (100) | 2.93 ± 0.68 (60) |
| Hard among Normal | 1.57 ± 0.15 (100), 100% top 4 | 1.53 ± 0.16 (60), 100% top 4 |

My results reproduce the worker's. Normal among Easy comes out a little weaker on my seeds, inside the margin.

Same greedy driver as my first review ("tier up, buy the highest-tier unit"), seed 912, at each level:

| Level | Before (93c1a50) | Now (ede4f80) |
|---|---|---|
| Easy | 1st, unbeaten from round 6 | **2nd**: four straight losses (rounds 4–7), then won |
| Normal | — | **4th**, out in round 12 |
| Hard | — | **8th**, out in round 9 |

**Did Normal improve through real skill or a boring handicap?** A handicap. The orchestrator's brief says "from round 6", but the code (`spell_from_round = 12`) blocks Normal's shop spells, including opening plans like A Leg Up, until round 12. The worker's own probe P18 (from round 6) gave 1.20, and their decision entry says they chose measured behaviour over making each level a superset of the one below. The cost is an inversion: Easy may buy one spell a turn from round 1, while Normal buys none until round 12. Players rarely notice spell buys, so it won't look odd, but it's a tuning knob, not a skill. Ask A3.

**Hard among Normal at 1.57 with 100% top 4: ladder or wall?** For a plain player, a steep but real ladder: the same driver on the same seed went 2nd, then 4th, then 8th. The bot gaps aren't even. Normal among Easy is 2.3–2.9, a gentle step. Hard among Normal is 1.5 with no bottom-half finishes, a big step. So the biggest jump sits at the top, which is acceptable for "how far can I get". In playtest 3, a keen newcomer learned enough to come 2nd on Normal by their fourth game. My hand-played Hard game in the first review, on the old Normal and Hard settings (Hard itself is unchanged), came 6th. A keen player should climb Easy → Normal within a few games and find Hard a long-term goal. Not measured: the plain policy among Normal or Hard lobbies, or Hard among a Hard lobby. That needs a new bench suite; worth adding before final reviews.

**Do Easy's limits show as poor play or stupid play?** Mostly poor, with one exception. From the seed 912 Easy log:
- Easy bots reach tier 3–5 with mixed boards. They now cast spells, so their stats grow (Tom Tit 3/2 to 7/7). That reads as a weak human.
- The stupid-looking part is boards that never change while gold is spent. Jill and Hoolet keep the same seven tier-1 units from round 5 to round 9. Farthing reaches tier 5 with Little Dollop 1/2 still in F1 from round 5 to round 15. On Scout that looks like a bot that stopped thinking. Ask A4.

### Gate
My `./scripts/check.sh` on ede4f80: all steps passed, **1,180/1,180**. I didn't rerun the soak; the worker reports seeds 41–140 clean, and no rules changed.

### In short (follow-up)
C1 and C2 are fixed and now tested. The ladder exists and reproduces on fresh seeds: plain play lands about 3rd on Easy, and one driver went 2nd, 4th and 8th across the three levels. Normal's tuning is a no-spells-before-round-12 handicap, not a skill (A3). Easy's frozen boards look silly on Scout (A4). Cut 0, ask 2.
