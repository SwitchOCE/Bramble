# Economy and what it makes players want (reader: economy)

Scratch tables for the orchestrator. Scripts: econ_pace.py, econ_pace2.py in this folder (python3 -I). Raw output: econ_pace_tables.txt, econ_pace2_out.txt.

## Data used

The task named `.free_choice_plain.0.*.csv` as still appending. Those files are gone. The run finished: `build/sim/pass2-followup/progress.json` says stage complete, stamp `66afe50 400`. I used the finished files `free_choice_plain.{rounds,players,cards}.csv`: 400 lobbies, 3,200 players, 48,773 player-rounds. No row had missing fields; none dropped. Code commit of the run: c50f6c8 (RESUME.md).

Columns: `bank` = gold at turn start (carry + income + next-turn gold), `spent` = all gold spent (units, spells, refreshes, climbs), `gold_left` = carried to next turn, `larder` = gold value of Acorn items in hand (tools/sim/bench.gd:306-345). Board stats are recruit-phase totals, before Start of Combat.

## 1. Pace, verified

| Round | Alive | Median tier | Share at T6 | Median bank | Median spent | Median carried | Median paid refreshes | Median board stats | Stats per unit |
|---|---|---|---|---|---|---|---|---|---|
| 3 | 3200 | 2 | 0 | 8 | 7 | 1 | 0 | 19 | 5.3 |
| 6 | 3200 | 3 | 0 | 10 | 9 | 1 | 1 | 52 | 7.6 |
| 8 | 3200 | 3 | 0 | 12 | 13 | 1 | 2 | 80 | 11.7 |
| 9 | 3200 | 4 | 0 | 12 | 12 | 1 | 1 | 92 | 13.5 |
| 11 | 3141 | 4 | 0 | 12 | 11 | 1 | 2 | 121 | 17.9 |
| 12 | 2869 | 5 | 0 | 12 | 11 | 1 | 1 | 133 | 19.7 |
| 14 | 1874 | 5 | 0.47 | 11 | 12 | 0 | 1 | 155 | 23.4 |
| 15 | 1549 | 6 | 0.92 | 11 | 11 | 0 | 1 | 162 | 25.0 |
| 18 | 951 | 6 | 1.0 | 10 | 11 | 0 | 2 | 200 | 31.0 |
| 20 | 428 | 6 | 1.0 | 10 | 10.5 | 0 | 2 | 220 | 34.4 |

First round at each tier (all players / winners): T2 3/3, T3 6/6, T4 9/9, T5 12/12, T6 14/14. Spread is tiny: T4 p25 = p75 = 9; T6 p25 14, p75 15, minimum 13.

- Reached tier 6: 1,570 of 3,200 (49.1%). Places 1-3: 99-100%. Place 4: 77%. Place 5: 15%. Places 6-8: 0-1.5%.
- Players who never reach tier 6 die at a median of round 13; only 1.8% of them live past round 15.
- Winners play a median of 19.5 rounds (p10 18, p90 21).
- Battlegrounds standard curve per our research: tiers 2/3/4/5/6 on turns 2/4/6/8/10 (docs/design/power-budget-review.md:69). Bramble bots are 1, 2, 3, 4 and 4 turns behind it.
- Our own power budget prices cards as if tiers open on turns 1/2/4/6/8/9 (docs/design/power-budget.md:119) and as if a game has 6-8 rounds after tier 6 (economy-bounding.md:450). Real: 1/3/6/9/12/14, and about 6 rounds after tier 6 for the top half only.

### What sets the pace

1. **The bot's script, not gold.** Hard bots climb on hand-set curves: `HARD_CURVE = [4, 7, 9, 12, 14]` (src/core/bots/bot_level.gd:20-21, comment "tempo beats tiers in this slice"), and per-strategy curves in content/bots/strategies/*.json (fastest [3,5,7,9,11]). DECISIONS.md:538: "Strategy curves were slowed by hand". In rounds where a bot at tier 2, 3 or 4 did not climb, it had the gold for the next climb at turn start in 100%, 99% and 100% of them (econ_pace2_out.txt). So gold never held back the mid-game climb.
2. **The last climb costs 13, not 11** (src/core/game_config.gd:21, provisional, DECISIONS.md:598-599). At tier 5, only 68% of non-climbing rounds had the gold. Most players spend 2-3 rounds at tier 5 (gap 2: 603 players, gap 3: 599).
3. **Flat income.** Everyone spends about 10 gold a round, whatever the tribe (9.7-10.1 per round by final tribe; Hedgerow, the Acorn tribe, 9.98). Extra start-of-turn gold is 0.5-2.4 a round, in-turn gold 0.4-2.1. There is no engine that speeds anyone up.
4. **40 Health and a slow early damage table** (0/0/0/1/1/2/2/3/4/5/7/9/11/13 + survivors, game_config.gd:25) keep games to about 20 rounds, while the bottom half dies in rounds 11-14 before tier 6.

Affordability check (arithmetic): under Bramble's costs and income, BG's 2/4/6/8/10 curve is affordable while buying 13 units by turn 10 (1 unit on most climb turns). With no buys, tier 6 on turn 7. So the economy allows a BG pace; the bots don't take it.

Tempo against tier, now (confounded: ahead bots climb a turn early, low-health bots a turn late, bot_brain.gd:262-280):
- Tier 3 first at round 3 (all 147 are March Hare): mean place 3.24; at round 6: 4.69.
- Tier 5 first at round 11: 2.94; round 12: 3.53; round 13: 4.56.
- March Hare (climbs two tiers for +4) is the second-best hero, 3.57. The "tempo beats tiers" reason for slow curves may be stale.

## 2. Gold behaviour

- Carry-over is barely used. Median gold carried per turn 1 (p90 3, p99 6, max 11). The most a player ever carried in a game: median 3, p90 6.
- Acorn gold held (larder): median max per player 1, p90 5, max 22.
- Paid refreshes per turn: 0 in 47% of turns; 1: 24%; 2: 17%; 3: 8%; 4+: 4%. Maximum 9 in 48,773 turns. The refresh price step after 15 (rulebook 4.4.3) never fired. The "around 20 shops in long turns" of rulebook 3.1.2 never happened.
- Share of gold spent on climbs through round 14: about 17% (plain discount model). The rest goes on units, spells and about 1-2 refreshes a turn.
- Realised late value of gold (board stats gained per gold spent, sum over players): rounds 3-6 1.32, 6-9 1.09, 9-12 1.11, 12-15 0.75, 15-20 0.91. The power budget prices all gold on a late sink of 2.0 SP per gold (power-budget.md:360).

## 3. Heroes (each bends one economy system)

| Hero | n | Mean place | Reached T6 | Bends |
|---|---|---|---|---|
| Brother Bracken | 378 | 2.70 | 93% | ≤5 units: +1/+1 per tier, up to +5/+5 (concentration) |
| March Hare | 308 | 3.57 | 65% | climbs 2 tiers for +4 |
| Old Mother Mousewife | 374 | 3.99 | 56% | summons |
| Pipkin | 290 | 4.36 | 50% | +2 shop cards, 2 buys a turn |
| Little King Wren | 398 | 4.49 | 49% | combat |
| Hob Mumblecrust | 398 | 5.12 | 37% | borrow 3 |
| Dame Hoolet | 379 | 5.31 | 31% | back row first |
| Jill Down the Tree | 298 | 5.38 | 29% | tier down for 2 gold |
| Dame Farthing | 377 | 5.53 | 30% | 1 gold per 4 carried, up to 5 (interest) |

Bracken: 5 units, fewer recorded stats than others (round 8: 73 vs 81; round 12: 110 vs 136) but 14.6 vs 11.6 stats per unit, plus about +30 at Start of Combat. Wins 91.4% of fights before round 9 and 60.7% after (others 44.5% and 51.2%). First place only 13%: the flat bonus stops at +5/+5 and fades late.

## 4. Goldens

Goldens on the final board, mean: 1st 3.58, 2nd 2.87, 3rd 2.12, 4th 1.71, 5th 1.62, 6th 1.53, 7th 1.34, 8th 1.05. 29.7% of all final-board units are golden. Golden doubling is the biggest multiplier players actually reach.

## 5. Systems and the motivations they create

| System | Each turn the player wants to | Longer tension |
|---|---|---|
| Income 3→10, flat from turn 8 | Spend it all: about 3 buys and a roll | Gold is equal for everyone late (about 10 a round), so it can't separate players; power differences must come from the board |
| Carry-over, no cap, no interest | Hold only for a lump: a discounted climb, Hiring Fair (6), Market Stall (4), Last Orders, Beltane Bonfire, Charcoal Burner | Banking costs tempo now and pays nothing, except that the climb gets 1 cheaper each turn you wait. Bots don't bank; the interest hero is last |
| Buy 3; Bought sells 1, Created 0 | Replace the weakest unit for 2 net gold | Slots are the scarce thing. Created-for-0 stops churn loops but also means generated units are only worth keeping |
| Refresh 1, rising after 15 | Roll with the 1-2 gold left after buys, or to finish a triple | The rising price is the infinite-turn backstop; it never binds in play |
| Freeze (5 toggles) | Keep a pair's third copy or a key unit for next turn | A frozen shop blocks fresh offers; pairs with banking for a big next turn |
| Climb 5/7/8/11/13, -1 a turn | Wait for the discount, climb when cheap | Tempo now against better shops later. The discount is the only reward for waiting |
| Shop 4/4/4/5/5/6 + 1 spell, odds weighted to your tier | Climb to see more and better units (tier-6 shop: 40% tier 6) | At high tier, low-tier triples dry up (5% tier 1 at tier 6) |
| Pool 15/15/13/13/11/9 copies, 5 of 6 tribes | Take a tribe others aren't taking | Contested tribes starve triples |
| Triples, golden doubles numbers, Triple Reward | Hold pairs, hunt the third (Figgy Duff, Mistress Russet, Cut-and-Come-Again help) | Pairs in hand cost board tempo; the reward is a tier jump |
| Discover (Hiring Fair, Triple Reward) | Pay a lump for a chosen high-tier unit | Created, so it sells for 0 |
| Tavern spells (1-6 gold, flat price) | Spend leftovers on 1-5 stats per gold, or on economy | A flat, low rate makes late gold worth little and linear |
| Harvest Supper (+1/+1 a tribe, cap +3/+3) | Commit to one tribe | The cap ends the reward after three casts |
| Heroes | Lean into the hero's system | Tempo and concentration heroes win; economy heroes lose |
| Opening spells (Rainy Day, A Leg Up) | Round 1-2: unit, gold or climb | Rainy Day pays 3 for a loss against 1 for a win (plus 1 Spoils). With 0 base damage in rounds 1-3, an early loss costs only the survivor count |
| Early Spoils (+1 per win, rounds 1-4) | Win early fights | Small; a winner's rich-get-richer |
| 40 Health, slow early damage | Play greedy early | The late game decides; the bottom half dies before tier 6 |

## 6. Compounding loops in pass 2 and what caps them

Gold that makes gold:
- Acorn ladder: 3 Acorns (3 gold) → Stash (5); 3 Stashes (15) → Great Hoard (16). Nine Acorns become 16 gold, +78%. Capped by sources: Sleeping Partner (2 per 3 turns, 3 times in all), Old Mother Mast (once a turn, 1, or 2 with a Hoard), Mrs Jay (1 per flight), Squirrel Away (2 per cast).
- Dame Farthing: 1 gold per 4 carried, up to 5 a turn. The only true interest in the game; rulebook 4.1.3 says no interest.
- Money Spider +1 a turn (2 if you carried 3+). One Swallow +1 per homecoming, sped by Mrs Stork (per 6 gold spent), Old Tern, Mrs Dunnock; bounded by "has missed a fight".
- Small one-offs: Hungry Gap (+1 net), Rainy Day, Cricket Busker (+1 once a turn), Prince Restored (-1 on first spell), Market Day, Little Dollop, Market Stall (+1 shop unit, at most 2), Madame Ermeline, Early Spoils, next-turn gold on combat events (Peat Cutter 3 in all, Toll-Bard, Young Pretender, Old Lutra, Sexton twice a fight, Sixpenny Pie), Pennywort Snail and Rainbow Chaser sell values.
- No card raises the income ceiling of 10.

Permanent stats that accumulate:
- Tribe bonus: cap +3/+3 a tribe (src/core/tribe_bonus.gd:6).
- Rings: cap +4/+4 a slot (src/core/board_upkeep.gd:8); Fairy Monarch +1/+1 more; Reel-Mistress moves past the cap.
- End-of-turn growers, uncapped but linear and 1-2 targets: Mrs Mallow, Old Moth Annis, Hob-in-the-Hearth, Lob-Lie, Aunt Aspic, The Cuckoo (+2/+2), Sally Spore, Stone Soup, Pennywort Snail (3 turns).
- Fight-to-permanent: Ranocchio (once a fight), Tiddy Mun (twice a fight), Grizel, Little Nip, Old Lutra, Bridge Toad (cap +3/+3), Chiffchaff per replay.
- Alderman Dozey: Acorn feeding and one doubling; doubling up to +8/+8, all permanent buffs up to +12/+12.
- Queen of Elfland: every third End of Turn, sacrifices the units behind and shares their stats to Fairies.
- Gold to stats: Last Orders (+1/+1 per 2 gold, one unit), Beltane Bonfire (a row +1/+1 per 4), Charcoal Burner (up to 6 gold above 5).
Trigger counts that grow with gold spent: only Mrs Stork. Multipliers: golden doubling, Figgy Duff (golden from 2 bought copies), Cut-and-Come-Again (free copies), Dozey ×2 once, Moss Ooze, Pipistrelle Echo (×3 on aimed spells), Mr Syllabub, copy-text units (Frumenty, Mag Pye, Cradle Fetch). No general recruit-trigger doubler. Spells that grow: none; only Hedge Witch's Hex grows, up to your tier.

Scale of growth text:
- Pass 2: 35 of 127 pooled cards have stat-growth text. The largest buff per trigger on any pooled card sums to 6 (+3/+3). Every grower makes about 1-8 stats a turn. This is what power-budget.md:743-746 asks for: per-turn growth at most 0.8/1.3/1.7/2.5/3.8 SP by tier, "Linear growth only".
- Battlegrounds current solo pool (273 minions, data/minions.json): 15 texts give +5/+5 or more per trigger, e.g. En-Djinn Blazer (T4) +10/+10 per refresh this game, Deft Deserter Activate (1) +8/+8 to every shop minion, Maritime Extortionist +7/+7 per golden played, Stone Age Slab (T7) +20/+20 and double. 45 texts carry "this game / permanently / wherever" scaling (crude regex).
- Galaxy: all buffs permanent, legendaries "into the hundreds or thousands" (docs/research/galaxy/design-notes.md §3). Galaxy polices loops and pace, not numbers.

## 7. Board scale against the owner's claim

- Bramble winners' final board: median 242 stats over 7 units, about 35 per unit (p90 312, max 486).
- The owner: BG late units over 100/100, mid-game 150/150 in many metas: about 1,400 stats a board, about 6× ours.
- Our research holds no measured BG board totals. The "Battlegrounds-like" 270 SP at turn 12 (power-budget-review.md:293) is a model scenario, marked as a design target. Indirect support for the owner: the printed per-trigger sizes above, and BG's Tyrael "set to 50/50" counting as a scam (strategy-eras.md:223), which only works if late boards exceed 50/50.
- Concentration: power-budget.md:471 treats stats as interchangeable ("no data that spread stats are worth less than stats on one unit"). Evidence for the owner's view: Bracken (above); Dozey at 96/94 was on 70-96% of final boards before his cap (DECISIONS.md:560). Not a clean test: Bracken also adds raw stats.
