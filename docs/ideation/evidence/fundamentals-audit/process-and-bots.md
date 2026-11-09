# Reader: design, balance and delegation process, and the bots (9 Nov 2026)

Read-only. Checkouts: `/home/alex/code/Bramble-ideation` (ideation/main 2b95328; pass 2 is already merged there at 97f8d49) and `/home/alex/code/Bramble-ideation-balance` (ideation/pass2 c233260). Lobby data: `build/sim/pass2-followup/lobbies/free_choice_plain.{players,rounds,cards}.csv` (stamp `66afe50 400`, finalised 13:18; 400 complete lobbies, 3,200 seats, 48,773 round rows, no rows dropped). Scripts and raw tables: `scripts/bots_lobby.py`, `bots_lobby_tables.txt`, `plain_rank.txt`, `units_hints.txt` in this folder.

## 1. Local fixes to systemic problems

Each row is a case where a whole-game signal (scale too small, growth linear, no answers, bots that can't plan) got a fix on one card or one number. Line numbers are `docs/ideation/DECISIONS.md`.

| Date | What dominated or failed | Local fix | DECISIONS line |
|---|---|---|---|
| 7 Nov | Hard bots: "tempo beats tiers" | Strategy curves slowed by hand; `HARD_CURVE` [4,7,9,12,14] ("Hard climbs slower", `bot_level.gd:20-21`) | 564 |
| 7 Nov | Dozey on 70–96% of final boards | Doubling capped at +8/+8 | 586 |
| 7 Nov | Hedge Witch Hex to −45 | Hex stops at −8 | 586 |
| 7 Nov | Mast: Treasury won 44.6% | Mast pays after a buy, once a turn | 601, 622 |
| 7 Nov | Spend Late won 29.2% | Last climb 5→6 costs 13, not 11, "provisional… hand play decides". Still 13 (`game_config.gd:21`) | 624-625 |
| 7 Nov | Sleeping Partner | 3 payments in a unit's life | 631 |
| 7 Nov | Sixpenny Pie | At most three payments | 527 |
| 7 Nov | Hoarding | Great Hoard 16 gold; Treasurer +8/+8 cap; Dozey eats per 2 gold | 499-501 |
| 7 Nov | Money Spider | Per 3 gold, 2-gold ceiling | 496 |
| 7 Nov | Dozey largest in every sample | +12/+12 permanent-bonus ceiling | 475, 708 |
| 8 Nov | Whistlers 84/168 stats | Flat 1/1 | 322 |
| 8 Nov | Burner: 1 buyer in 240 seats, 0 gold burned | Cap 6/12, moved to tier 4, bot banking policy | 298-306 |
| 8 Nov | Birds routes weak in the spread | Bot route priors cut (Passage 3, Summer 1) | 295 |
| 9 Nov | Ring piles | Ring cap +4/+4 | 159 |
| 9 Nov | Hex 8 at tier 1 | Hex capped at your tier | 128, 158 |
| 9 Nov | Rainbow Chaser | Sale 1 gold per 2 painted slots | 130, 151 |
| 9 Nov | Toll-Bard, Bracken, Money Spider | Once a fight; up to +5/+5; T3 at 1 gold | 152-154 |
| 9 Nov | Pass 2 costing: 10 cuts, mostly "growth above the per-tier caps" | Lollop halved, Mallow "smallest unit", Beadle and Stone Soup "once a turn", Ranocchio "once a fight", Pie, Figgy, Elder trimmed. All 10 cuts taken | 76-121 |
| 9 Nov | Bridge Toad, Peat Cutter | Up to +3/+3 covering every buff; "three times in all" | 10, 44, 47 |

Result in the pool: 24 of 109 slice-pool units (22%) carry an explicit cap or limiter. Counting only per-turn and per-fight limiters, it's 17 of 109 (16%). Our own taxonomy says Battlegrounds limiters went from 0% to 5% of the pool (`docs/design/power-budget.md:224`, `effect-taxonomy.md:261`). On top of those there are global caps: Ring +4/+4, Supper +3/+3, Hex at your tier.

The orchestrator named the pattern itself on 9 Nov (DECISIONS:27): "Caps added after each dominance … treated a system problem as card problems."

Splits between reviewers: in pass 2, all three costing-against-triage splits went to costing: Tiddy Mun (45), Cut-and-Come-Again (98) and Mrs Stork (112).

## 2. Process assumptions

| Assumption | Where | Explicit? | Risk |
|---|---|---|---|
| Stats add up: 1 Attack = 1 Health = 1 SP, and a 20/20 is worth two 10/10s | power-budget SP unit; `bot_eval.gd:36-55` keep = A+H+hint; `bot_brain.gd:270-279` pressure by stat sum | explicit in the budget; implicit in the bots | high |
| Growth is linear; compounding only if it's once a turn and can't retrigger | power-budget.md:205-206 (B4, E06/E08) | explicit | high |
| The per-tier growth caps (0.8/1.3/1.7/2.5/3.8 SP a turn) are grounds to cut | power-budget.md:125; pass2-costing.md:3 | explicit | high |
| Scale target "about 13/13 by turn 12" | DECISIONS:792 (`lobby-pace`); budget c(t) assumes 180 SP turn-12 boards (power-budget.md:203) | explicit, never re-derived | high |
| Designers get no budget, but a budget reviewer can cut | CLAUDE.md; DECISIONS:200 | explicit | high: the budget comes back as a veto |
| Buy-moment costing: a card must be a sensible pick on its own when bought | birds-case-study.md §3A | explicit | medium: it penalises engines that pay off later |
| Parity of 16 cards per tribe at 3/3/3/3/2/2 is fair competition | DECISIONS:184 | explicit (owner) | medium: neutrals and spells are outside it; tiers were moved to fit the parity (Figgy T6→T4, Burner T4) |
| A tally of 3+ reports is a must-fix | birds-case-study §3E; triage-audit §1 | explicit | high: "one huge unit decides games" (11 reports) drove the caps; the owner says concentration is natural |
| The plain free-choice arm is the per-tribe bar | DECISIONS:69 | explicit | high |
| Bot priors and hints tuned after bench results stay in the "best" bot | DECISIONS:568, 576; bots/README "These values let their text compete…" | explicit | medium-high: the results encode our own tuning |
| Fixed R9 boards spending a common 62 ±3 gold, one growth layer each, no T6 | DECISIONS:62; pass2-followup-boards.md:3 | explicit | medium-high: equal spend removes economy and compounding by construction |
| One fresh scope reviewer per merge is enough | PLAN.md:91; CLOUD.md | explicit | medium: the reviewer sees only the step's range and checks it against the orchestrator's plan |
| Bot-vs-bot head-to-head gains are bot improvement | BOTS.md step 2 | explicit | medium: carrier +0.048 places is relative to a bot that can't plan either |
| "When a strategy keeps winning, improve the bots first" versus rule F, "fix the cards, not the bot routing" | BOTS.md; birds-case-study §3C/F | explicit, and the two conflict | medium |
| Agents that judge designs can't run the engine (no Godot in workflow agents); sims run only through Sol builders | DECISIONS:25; CLOUD.md | explicit | high: it forces costing by hand estimate ("Hand estimates, no sims", pass2-costing.md:3) |

## 3. Bots: how they decide (best policy, `src/core/bots/`)

- **Value:** a unit is worth Attack + Health + a text hint (a hand-set `keep`/`buy` number in `content/bots/cards.json`, otherwise 1.5 × tier), ×2 for golden, plus build bonus, triple bonus 18 + 2 × tier and pair bonus 3 (`bot_eval.gd:5-10,36-91`). BotEval takes no round or turns-left input. Only a few cards are modelled live: Burner forecast, Grizel with a fixed 2.5-fight horizon (`bot_carrier.gd:159`), Peat King, Redwing and Tom Tit, Owl, Lamp Moth, Horseshoe, Supper, and touching Start of Combat buffs.
- **Plain arm** (the tribe bar): `tools/sim/plain_eval.gd` replaces every keep/buy hint with 1.5 × tier, and `tools/sim/free_choice.gd` sets strategy `{}`. Inside a tier, units are then ranked by printed stats alone (`plain_rank.txt`): Changeling and Ichneumon Wasp come last at T4, Money Spider and Aunt Aspic last at T3.
- **Buy:** take the best (gain − burn loss) per gold while gain > 0 (`bot_brain.gd:307-345`). Gain is worth minus the weakest unit's keep value minus a margin of 3 (`:349-371`). No lookahead over shops or fights.
- **Level:** climb when the round reaches the curve (strategy curve, or `HARD_CURVE` [4,7,9,12,14]), one round early with gold left over. The climb is valued at 100, so it always happens when due (`:237-257`). The plan shifts by one round for health ≤ 12 or for a scout ratio below 0.7 or above 1.3 (`:261-280`).
- **Roll:** refresh only when nothing is worth buying and a unit is still affordable afterwards (`:283-302`, `:435-442`). The cap is 30, or 1 with a gold-banking unit.
- **Freeze:** only for a third copy, or an offer worth 12 or more points it can't pay for (`:841-850`).
- **Sell:** to make room (keep difference above 3), Rainbow at band thresholds, Fly South, cashing Acorns. No other pivot sales.
- **Save:** only strategy or hero `save` tables plus next-turn climb money (`:487-512`). In the plain arm strategy is `{}`, so it never saves.
- **Build choice:** best strategy fit with 1.3× stickiness, locked from round 9 (`:14,219-233`).
- **Place:** rule layout (`bot_placer.gd`). With 4+ units and a stat ratio of 0.6–1.7 against the scout, it runs a 20-fight search against the next opponent's **last-round** board (`:64-76`, `:418-450`). Generic carries stay pinned "as landmarks for the next opponent's scout" (`:453-460`). Stay bonuses: ROW_STAY 3, STAY_BONUS 0.2 (`:16-18`).
- **Scout:** at round start every player gets the next opponent's last fought board, slots, hero and tier (`game_session.gd:672-706`). Bots use it for placement, the ±1 tier shift, Bird flights, Peat King, Horseshoe and lanes. **They never use it to choose buys, and never predict the opponent's change.** The reveal rule (show the real board) is off (DECISIONS:418, 464).
- **Ghost:** the last eliminated player's board at elimination, with Eggs and without Horseshoe (`game_session.gd:853-869`). It has no hero, never changes, and deals damage. It fights whoever is the odd one out (`matchmaking.gd`). Its scout *is* the board it fights with.

### What the bots did in 400 plain lobbies (`bots_lobby_tables.txt`)

| Round | Mean gold left | Left ≥5 | Paid refreshes | Mean tier (sd) |
|---|---|---|---|---|
| 4 | 0.79 | 0.0% | 0.02 | 2.08 (0.31) |
| 6 | 1.52 | 3.5% | 1.08 | 2.54 (0.50) |
| 8 | 1.55 | 4.5% | 2.05 | 3.24 (0.49) |
| 9 | 1.76 | 9.9% | 0.99 | 4.04 (0.38) |
| 12 | 1.37 | 3.6% | 1.16 | 4.69 (0.47) |
| 14 | 0.70 | 0.4% | 1.04 | 5.47 (0.50) |

- **First round at each tier, p10/p50/p90:** T2 2/3/4; T3 5/6/7; T4 8/9/9 (sd 0.52); T5 9/12/13; T6 13/14/15. Only 49% of seats reach T6. That is `HARD_CURVE` less the one-round "leftover" climb: one scripted curve for every seat.
- **Board stat totals across seats (p50, p90, p99, max):** R8 80/98/116/129; R12 133/163/191/226. The lobby leader against the lobby median: p50 1.22, p99 1.60, max 1.63 at R12.
- **Ghost fights:** 1,461 of 48,773 player-fights (3.0%), about 3.65 rounds per lobby.
- **Losses in R1–6 against place:**

| Losses in R1–6 | Top 4 | First |
|---|---|---|
| 0 | 88% | 14% |
| 1 | 73% | 19% |
| 2 | 55% | 16% |
| 3 | 46% | 13% |
| 4 | 32% | 7% |

  45.5% of lobby winners lost 3 or more of their first 6 fights. An early record predicts top 4 strongly but first place weakly.
- **Answers and low-stat payoffs on final boards:** Changeling 0/3,200 and Ichneumon Wasp 0/3,200. Fairy Monarch 0.5% (holders' mean place 1.67, n=15), Cut-and-Come-Again 0.7% (2.43), Laird 3.2% (2.65), Money Spider 0.1%, Old Moth Annis 0.5%, Hob 0.1%, Lob 0.0%.
- **Tribe pick rate follows printed early stats:** Hunters (T1 mean 4.7 stats) are picked by 22% of seats; Fairies (T1 3.0, T2 4.0) by 0.9%, though they take first in 31% of the 29 seats that pick them. 37% of seats end with no tribe.
- **Goldens:** 30% of final-board cards are golden, and 88% of seats hold at least one.

## 4. Evidence bars and their blind spots

| Bar | Measures | Blind spots |
|---|---|---|
| Benchmark boards, hand guesses (8 Nov) | One agent's ranking of a stated average, high and low roll at R3/6/9/12 | All guesses; one author's assumptions; no frequency |
| Fixed-board round robin (pass 2, fair R9) | Fight win rate of hand-built boards at a common spend | Equal spend and one growth layer remove economy and compounding; no T6; results come out near 0% or 100%, so it's a threshold test; +1/+1 per unit moves 22–68 points (review-pass2-followup.md:9); heroes ignored; boards are not reachable-by-probability |
| Free-choice plain lobbies | Pick, mean place and first rate per tribe under one identical policy | One curve, no saving, all gold spent, text valued at 1.5 × tier, no answers bought, buys don't read the scout. Swings with small changes (Birds first 13.5% → 4.9%, DECISIONS:13). Hinted and plain arms disagree (Birds 21.1% vs 1.3% picked, DECISIONS:67). Can't show snowball frequency or skill expression |
| Spread bar (pinned strategies) | 5+ hand-written strategies at 6–25% | Pinned bots buy their tribe regardless; 19 strategies passed while Bird routes sat at 1.4% and 2.5% (birds-case-study §2.3); curves and priors were hand-tuned |
| Placing bar | Searched layout against the **real** opponent board minus the rule layout (+23.8, placing-bar.md) | Uses the exact board, not the scout: a decoy search scores only +6.4 (DECISIONS:230). By eye, readers gained +1.9 without one obvious screen (DECISIONS:464). Boards come from bot games |
| Bot head-to-head | Candidate against incumbent bot | Bot against bot; gains of about 0.05 places; can't show a gap against strong human lines |
| Reviewer playtests and tally | Readability, felt decisions, complaints | Agents, not elite players; small n; complaints about concentration were treated as defects; rule E (3+ reports) turns taste into must-fixes |
| Buy-moment costing | A card's SP against V(t) 5/7/8/10/12/14 and the growth caps | Linear, additive stats; no sims; cuts compounding; V(3) = 8 is a 4/4 body, below the owner's "very low" 5/5 example |
| Soak | Rule violations | Not balance |

## 5. Delegation map

| Role | Sees | Doesn't see, or doesn't own |
|---|---|---|
| Orchestrator (one local session) | Everything; writes plans, briefs and DECISIONS; picks splits; merges | Not independent of its own briefs; the plan is the yardstick reviewers use |
| Designers (cloud, now workflow agents) | Owner quotes, triage skill, audit, benchmark boards, their group's tribe docs | Budget (by design), bot code, sims (no Godot), the other groups' work until the merge step (LEARNINGS 9 Nov) |
| Costing reviewer | Designs, the budget method, the growth caps | Sims ("hand estimates, no sims"); its cuts are all taken, and it wins the splits |
| Triage reviewer | Designs, the triage skill, the pool | Sims |
| Sol/Codex builders | Code, gate, sims | Design ownership, yet they set bot hints (Toad 4→6, Committee 14→12, with no plan line: review-pass2-followup ask 3), fixtures and numeric trials (Burner C1–C5) |
| Scope reviewers | The step's commit range, the owner's words, the orchestrator's plan entry | Cumulative drift across steps, such as caps piling up; whole-game health |
| Playtester agents | The build via `tools/play` | Elite-level play; scale |
| Bot workers | Bots against bots | Whether the bot model is right for engines, concentration or answers |

Nobody owns:
- the stat scale and power curve (set on 6 Nov, never re-tested against fun);
- the bot valuation model (hints added card by card to get cards bought);
- whether an instrument measures the game rather than the bot (bars get replaced after failures: the placing bar on 8 Nov, the promotion floor on 8 Nov);
- the cumulative cap count;
- neutrals and spells, which sit outside parity.
