# Rulebook deltas

Every rule in [rulebook.md](rulebook.md) (v0.10 draft, 19 Nov 2026, baseline HSBG patch 36.6.3) that is not plain Battlegrounds, in one place. Rule numbers point into the rulebook, where each rule has its full text and reasons.

- **PROPOSED**: a gap Bramble's differences create. A default is filled in; it needs your yes or a change.
- **OPEN**: undecided, no default.
- **BRAMBLE**: your decision, already recorded. Listed so you can check the wording.
- **EXAMPLE**: an HSBG or Galaxy mechanic kept to show what the rules must handle. Not a Bramble mechanic, and nothing to decide ([N9](sources/2026-11-02e-mechanics-are-examples.md)).

Counts: 85 [BG], 70 [BRAMBLE], 54 [PROPOSED], 10 [OPEN], 26 [EXAMPLE]. v0.11 (19 Nov) lets Created units that are real cards (Discover, Triple Reward, copies) sell for money, like Bought ones; tokens still sell for 0 (rulebook source C17). The rework answers of 19 Nov add Bramble's own keywords in 11.7: Active, Charge, Supply, Renown, Reserve's limit, Pile on N and Hand-me-down, with a golden doubling Charge N and Pile on N but not Supply N (7.3.5, 7.3.5a) (rulebook source N14). v0.10 (19 Nov) removes the shared pool, so every card has a fixed chance in the shop, and sets the async rules: a game is the player and 7 recorded runs, which also fight each other (rulebook source C16). v0.9 (17 Nov) lets units move freely between hand and board and sell from either, and moves play triggers to recruiting (rulebook source C15). v0.8 (16 Nov) sets the hand limit to 7 (rulebook source C14). v0.7 (12 Nov) sets the economy from the owner's decisions in chat (rulebook source C13): income 5, +2 a turn up to 15, then +1; units cost tier + 1 and sell for half their tier, rounded up; 10 refreshes at 1 gold; tier-ups 8/12/16/19/26 with a discount of 1, 2, 3, 4, 5 for each turn waited; a shop of 5 units and 2 spells. The evidence is in [../research/economy/](../research/economy/README.md). v0.6 (12 Nov) sets damage and starting health from the owner's decision in chat (rulebook source C12): 40 health, a small loss of the round + 1 up to 10, and +3 for a big loss. v0.5 (8 Nov) applies the owner's notes [N11](sources/2026-11-08-autobattler-systems-thoughts.md), [N12](sources/2026-11-08b-taste-answers.md) and [N13](sources/2026-11-08c-rulebook-go-ahead-and-scaling.md): new damage system, stat scale, fixed shop size, and open questions on starting health, pool, tier weighting, shop-slot upgrades and multiple-copy strategies. The 27 Oct decisions are folded in (owner notes [d](sources/2026-10-27d-combat-shape-decisions.md), [e](sources/2026-10-27e-economy-decisions.md) and [f](sources/2026-10-27f-power-budget-decisions.md)), and the 2 Nov no-timer decision ([N7](sources/2026-11-02-pre-development-design-pass.md)). v0.4 makes HSBG and Galaxy mechanics examples instead of Bramble mechanics, and adds slot effects ([N9](sources/2026-11-02e-mechanics-are-examples.md)).

The proposed defaults and open rules are edge cases with sensible defaults, or open questions to settle by experiment.

**Docs that cite superseded v0.4 rules.** These still describe the old values and are not yet updated:
- HSBG damage caps (old 10.1.4): [archetypes.md](archetypes.md) row ECO, and the Wager entry in the mechanics library ("early bets are cheap because of the damage caps").
- Tier-based damage (old 10.1.1): the Changeling entries.
- Selling only from the board, and no way back to hand (old 4.3.7 and 8.3.3): [economy-bounding.md](economy-bounding.md), "Clicks and time", and `tools/research/budget_model.py`. Both count a play and a sell to clear each Created unit from the hand.
- The hand of 10 (old 7.1.1): [economy-bounding.md](economy-bounding.md), "Clicks and time" and "Hand and board clutter", and `tools/research/budget_model.py`.
- Shop sizes of 4–7 cards (old 6.1.1): the back-row "aisles" entry, and the tier-6 frame in [economy-bounding.md](economy-bounding.md) (6 units + 1 spell).
- The pre-v0.7 economy (old 4.1.1, 4.2.1, 4.3.3, 4.4.3, 4.6.2–4.6.3: income 3 to 10, units at 3 gold, sale for 1, 15 refreshes at 1 gold, HSBG tier-up costs):
  - [economy-bounding.md](economy-bounding.md) throughout;
  - [power-budget.md](../archive/power-budget/power-budget.md): buys a turn as gold ÷ 3, the income model, and E51 "maximum gold", which now raises income under 4.1.4;
  - [power-budget-review.md](../archive/power-budget/power-budget-review.md) §"Gold" and §"Buying";
  - the mechanics library and ideas files where they quote 3-gold units.

| Rule | Status | Bramble rule | HSBG equivalent | Decision needed |
|---|---|---|---|---|
| 1.2.5 | BRAMBLE | Stat scale about 2× HSBG (working value); room to tune upgraded and scaling effects | Base scale | Decided 8 Nov (N12, N13); power budget needs rescaling |
| 2.2.5 | BRAMBLE | Starting health 40 by default; heroes may differ for balance (direction open: maybe only upward) | 30 | Decided 12 Nov (C12) |
| 5.1.1 | BRAMBLE | No shared pool: nothing is taken out or returned | Shared pool with copy counts | Decided 19 Nov (C16) |
| 5.1.2 | BRAMBLE | Every card has a fixed weight by tier (15, 15, 13, 11, 9, 7, 5; spells 5, 7, 9, 11, 9, 7), never running down | Copies left | Decided 19 Nov (C16) |
| 6.1.1 | BRAMBLE | Shop shows 5 units and 2 spells at every tier; tiers change only the odds | 4–7 cards, growing with tier | Decided 12 Nov (C13); size settled 13 Nov; check the shop layout |
| 6.1.6 | OPEN | Extra shop slots as a separately bought upgrade | Slots come with tier | Decide (N11 §5.3) |
| 6.1.7 | OPEN | Shop draws flat by the fixed weights, or weighted toward your tier | Flat by copies | Decide (N11 §5.4) |
| 7.3.8 | OPEN | Multiple-copy strategies (TFT stars) or HSBG's single triple | Single triple | Decide (N11 §5.6) |
| 10.1.1 | BRAMBLE | Small loss if the loser killed at least half the winner's starting units; otherwise a big loss, +3; tiers don't count | Winner's tier + tiers of surviving units | Decided 12 Nov (C12), replacing the 8 Nov rule |
| 10.1.2 | PROPOSED | Starting units: on board when combat begins; killed unless alive on the winner's side at the end; summons never count; returns count | — | Accept |
| 10.1.3 | BRAMBLE | Small loss = round + 1, up to 10; big loss 3 more. Intent: spend gold early; tunable, with fallbacks listed | Caps 5/10/15 | Decided 12 Nov (C12) |
| 10.1.4 | PROPOSED | No cap beyond 10.1.3's cap of 10 (most a loss can deal: 13) | 5/10/15 by turn, off at top 4 | Accept |
| 1.2.3 | PROPOSED | One board order, F1–F4 then B1–B3, for every "left to right" resolution | Left to right in one row | Accept reading order everywhere |
| 1.2.4 | PROPOSED | Integer stats, clamp at 1,000,000,000, condensed display | Condensed display only | Accept clamp value |
| 2.1.3 | PROPOSED | Game ends after round 50; place by health + armor | Turn limit exists, value unknown | Accept 50 or set a value |
| 2.1.1 | BRAMBLE | 8 players: the player and 7 recorded runs | 8 live players | Decided 19 Nov (C16) |
| 2.1.4 | BRAMBLE | No turn timer (N7). Each round you fight a recorded run's board from the same turn; the runs also fight each other, so damage, elimination and placement work as in a live lobby | Live lobby | Decided 19 Nov (C16) |
| 2.1.5 | BRAMBLE | A run whose own game ended keeps its last board | — | Decided 19 Nov (C16) |
| 2.1.6 | BRAMBLE | The 7 runs are picked at game start: same rules version, similar strength, never one already met that session | — | Decided 19 Nov (C16) |
| 2.1.7 | BRAMBLE | You see who your next opponent is and their health, not their board | Uncertain (2.3.3) | Decided 19 Nov (C16) |
| 2.1.8 | BRAMBLE | During development, the runs are made by bots and remade after every change | — | Decided 19 Nov (C16) |
| 2.1.9 | OPEN | Recorded runs across patches in the live game, with no bots in ranked | — | Research, then decide |
| 2.1.10 | BRAMBLE | After the live player is out, the run seats fight on until the game ends; all 8 are placed | — | From decision 3b (C16) |
| 2.1.11 | PROPOSED | Changes a fight makes to a run seat expire after that fight | — | Accept or change |
| 2.1.12 | PROPOSED | The ghost of an eliminated run seat copies the board it last fought with | Ghost of last eliminated live player | Accept or change |
| 3.1.1 | BRAMBLE | Players take Recruit Phases independently | Simultaneous | Decided 2 Nov (N7) |
| 3.1.2 | BRAMBLE | No recruit timer; only refresh cost escalates; most long turns around 20 shops, tuned by playtesting | 60–120 s timer | Decided 2 Nov (N7, N8) |
| 3.2.1 | PROPOSED | Start of turn: gold, upgrade discount, refresh reset, shop refill, triggers | Order undocumented | Accept order |
| 3.2.2 | BRAMBLE | Effects that use the last fight (Grudge, Relic Seeker, Old Campaigner) pay at the owner's next turn start, win or lose, even if the unit died | After the fight | Your delegation, 20 Nov |
| 3.4.1 | PROPOSED | End of turn: End of Turn triggers, "this turn" ends, unfrozen shop cleared, gold kept, board copied | Order undocumented | Accept order |
| 4.1.4 | PROPOSED | "Maximum gold" effects change income by that amount (there is no income ceiling) | Max gold = refill and cap | Accept |
| 4.3.2 | BRAMBLE | Units given by effects (Discover, Triple Reward) count as Created, and sell like Bought units; tokens sell for 0 | All units sell for 1 | Decided 27 Oct (N5); sell for 0 removed 19 Nov (C17) |
| 4.3.6 | PROPOSED | Origin sticks; a Created unit made golden by an effect (not a triple) stays Created | — | Accept |
| 4.4.3 | BRAMBLE | Paid refreshes 1–10 cost 1, then +1 gold every 5 (11–15 cost 2, 16–20 cost 3, ...), no cap | Always 1 | Decided 12 Nov (C13), replacing 2 Nov (N8) |
| 4.6.6 | PROPOSED | After 5 turns waited the upgrade discount stays at 5 a turn | 1 a turn | Accept |
| 4.4.5 | BRAMBLE | Free refreshes cost 0 and don't count toward the thresholds | Free refreshes just cost 0 | Decided 27 Oct (N5) |
| 4.4.7 | BG + note | No refresh cap of any kind; free-refresh loops are prevented by content design (guardrail G1) | No cap | Decided 27 Oct (N6) |
| 4.4.6 | PROPOSED | Card effects that reroll the shop don't count toward the thresholds | — | Accept |
| 5.2.3 | PROPOSED | Text naming a type matches any unit with that type on its line | Dual types match either | Accept |
| 6.1.2 | BRAMBLE | Shop units of your tier or lower, drawn by the fixed weights | Fewer copies left, less often | Decided 19 Nov (C16) |
| 6.1.3 | BRAMBLE | Each shop offer is an independent draw by the fixed weights; a shop can show a unit twice | Weighted by copies; exact rule unknown | Decided 19 Nov (C16) |
| 6.1.4 | PROPOSED | No eligible unit: shop slot stays empty (only possible in a lobby with no units at your tier or lower) | Unknown | Accept |
| 6.2.3 | PROPOSED | Discover with fewer than 3 eligible units offers what exists | Unknown | Accept |
| 7.3.5 | BRAMBLE | Golden doubles stats and its signature: a number doubles, an action happens twice, "twice" becomes "three times"; thresholds, costs, Supply and caps stay; a keyword's number doubles, Charge N and Pile on N included, but a golden never changes how a keyword works; a card may break it for the rule of cool. Per-card values in card data | Per-card golden text | Your delegation, 20 Nov (the orchestrator's rule); Charge N and Pile on N doubling is your own ruling, 20 Nov ("Double them too") |
| 7.3.5a | PROPOSED | A golden keeps Supply N as printed; a triple adds the copies' Supply. Charge N and Pile on N double (7.3.5, owner 20 Nov). Costs never double | Per-card golden text | Open with you: should Supply double too? |
| 7.3.7 | PROPOSED | Triple with full hand and all copies on board: golden goes to first vacated slot | Unknown | Accept |
| 8.2.2 | PROPOSED | Adjacent = next slot in the same row; doesn't skip gaps | Left/right neighbour | Accept |
| 8.2.3 | PROPOSED | Neighbour = adjacent + in front + behind (up to 4) | — | Accept the term |
| 8.2.4 | PROPOSED | Relations belong to slots; a unit entering a slot becomes the related unit | — | Accept |
| 8.2.5 | BRAMBLE | Leftmost/rightmost are per row; card text must name the row | First/last in the row | Decided 27 Oct (N4) |
| 8.2.6 | PROPOSED | "Across from" = enemy slot with the same label | — | Accept |
| 8.3.3 | PROPOSED | Recruit Phase: move on the board to any empty slot or swap, free, unlimited; triggers nothing | Free reordering | Accept |
| 8.3.5 | PROPOSED | Units move only by player moves or effects; move into a full slot fails unless "swap" | — | Accept |
| 8.4.1 | BRAMBLE | A dying unit's first summon takes its slot | Summons appear where the minion died | Decided 27 Oct (N4) |
| 8.4.2 | BRAMBLE | Other summons: nearest empty slot, same row first, ties go right | Next to source, usually right | Decided 27 Oct (N4) |
| 8.4.3 | PROPOSED | Summons with no source slot: first empty slot in reading order | — | Accept |
| 8.4.4 | PROPOSED | Multiple summons placed one at a time | — | Accept |
| 8.4.5 | PROPOSED | With no empty slot each Hopper gives Tide +1 immediately, in either phase. Other summons are lost | Summon lost by default | Owner's pick, 20 Nov 2026 |
| 8.4.6 | PROPOSED | Text naming a slot overrides placement; fails if full | — | Accept |
| 8.4.7 | PROPOSED | Same placement rules in Recruit Phase and combat | — | Accept |
| 8.5.1 | PROPOSED | A slot can hold effects that apply to whatever unit is in it; they stay when the unit changes | No slot effects | Accept (N9) |
| 8.5.2 | PROPOSED | Slot effects are copied into combat and into snapshots; combat changes last that combat unless permanent | — | Accept |
| 8.5.3 | PROPOSED | Slot effects last as their text says; with no duration, the game | — | Accept |
| 9.4.5 | PROPOSED | Attack pointer: lowest unflagged slot attacks; attacking flags all lower slots | Left-of-pointer rule (simulator) | Accept algorithm |
| 9.4.7 | PROPOSED | Empty slots are skipped in attack order | No gaps exist | Accept |
| 9.4.8 | BRAMBLE | Summon below pointer waits; into the attacker's slot attacks next; above attacks in order | Token takes right neighbour's status | Decided 27 Oct (N4) |
| 9.4.9 | PROPOSED | A unit moved in combat keeps its attacked flag | — | Accept |
| 9.5.3 | PROPOSED | An all-untargetable front row loses that protection; back row stays protected | Simulator clears Stealth | Accept |
| 9.5.4 | PROPOSED | Must-be-attacked works within the attackable row; a back-row one protects the other back-row units once the back row can be attacked. From your 27 Oct Taunt ruling (N4 §7) | Taunt across whole board | Accept for any must-be-attacked effect (N9, N10) |
| 9.5.6 | BRAMBLE | Random single-target effects choose from both rows; protection and must-be-attacked apply only to attacks | Any enemy minion | Decided 27 Oct (N4) |
| 9.7.1 | PROPOSED | Dying units leave their slots before any trigger | — | Accept |
| 9.7.3 | PROPOSED | Active side's deaths resolve first, then reading order | Side order unknown (simulator: random) | Accept |
| 9.8.3 | PROPOSED | A returning unit goes to its own slot, else nearest empty | Reborn returns where it died | Accept |
| 9.10.1 | PROPOSED | Combat ends as a tie after 200 attacks | Client limit unknown | Accept value; tie or other result |
| 9.10.2 | PROPOSED | Tie after 10,000 triggers in combat; 1,000 per Recruit-Phase action | Per-card loop caps | Accept values |
| 9.10.3 | PROPOSED | A unit can return at most 5 times per combat | 30-loop cap on two cards | Accept value |
| 10.2.2 | PROPOSED | Same-round eliminations placed by health after damage | Unknown | Accept |
| 11 | EXAMPLE | Chapter 11 is example mechanics: HSBG keywords (11.2–11.4) and Galaxy's Support, Sneak, Farewell, Recruit, Hunt, slot buffs and Paint (11.6). Worked two-row versions kept for Taunt, Stealth, Cleave, Magnetic and Reborn's slot. 11.5.1–11.5.2 cut | Adopted keywords | Decided 2 Nov (N9, N10) |
| 11.2.7a | BRAMBLE | Cleave also damages one unit next to the target, not both | Both neighbours | Decided 19 Nov (owner, Balance Pass One) |
| 11.2.7b | PROPOSED | Cleave's one unit is picked at random | — | Accept |
| 11.7.1 | BRAMBLE | Active: a gold cost and a colon, "{1}: effect", as a gold coin with the number (0 free); no keyword word; any tribe; replaces Orders | Activate (X) | Decided 19 Nov (N14) |
| 11.7.2 | PROPOSED | An Active is used in the Recruit Phase, from the board, once a turn for each unit; golden doubles the effect, not the cost | Once a turn | Accept |
| 11.7.3 | BRAMBLE | Charge N: N uses, all back at the start of every fight; replaces "(N a fight)" | Per-card text | Decided 19 Nov (N14) |
| 11.7.4 | BRAMBLE | Supply N: N uses in the whole game | — | Decided 19 Nov (N14) |
| 11.7.5 | PROPOSED | Charge and Supply go in front of the effect; Supply left is on the unit; a triple adds the copies' Supply; a given golden starts full | — | Accept |
| 11.7.6 | BRAMBLE | Renown: a permanent number on a slot; +1/+1 a point only for the unit that starts the fight there and for reservists; gains in a fight count from the next fight | No slot effects | Decided 19 Nov (N14) |
| 11.7.7 | PROPOSED | Renown is borrowed: read by Attack and Health readers, left out by copiers (ruling 43); shown on the recruit board | — | Accept |
| 11.7.8 | BRAMBLE | Reserve: a unit in hand steps into a slot a friendly unit died in; at most 2 from hand a fight, raised by cards | — | Decided 19 Nov (N14) |
| 11.7.9 | PROPOSED | Reservists fill the Guard post, then the most Renown, then reading order; leftmost in hand first | — | Accept |
| 11.7.10 | PROPOSED | A Private that steps in is a reservist with Renown, outside the limit, after hand reservists, only into a still-empty slot | — | Accept |
| 11.7.11 | BRAMBLE | Pile on N: the first N times a neighbour attacks each fight, this hits the target first | — | Decided 19 Nov (N14) |
| 11.7.12 | BRAMBLE | Hand-me-down: when this dies, the nearest friendly Mouse gains its Attack this fight | — | Decided 19 Nov (N14) |
| 11.7.13 | PROPOSED | Hand-me-down passes own Attack only; nothing with no Mouse; nearest = fewest neighbour steps, ties in reading order | — | Accept |
| 11.7.14 | BRAMBLE | Grudge N: at turn start, +N Health and +N/+N more per unit you were outnumbered by last fight | — | Your delegation, 20 Nov |
| 12.2.2 | PROPOSED | "Your units" = board only; row scopes defined | "Your minions" = board | Accept |
| 12.2.3 | PROPOSED | Death triggers use the dying unit's last-known slot | — | Accept |
| 13.1.1 | PROPOSED | Seasonal systems (Trinkets, Dark Gifts, Quests, Anomalies…) not in v0 core | Trinkets and Dark Gifts live | Confirm |
| 13.1.2 | PROPOSED | No v0 system grants Tier 7 | Seasonal routes to Tier 7 | Confirm |
| 2.2.3 | OPEN | Extra hero choices or rerolls, and whether paid | 2 heroes, 4 with paid pass; token rerolls | Decide |
| 5.2.2 | OPEN | Which types on the type line are tribes | Tribes are the only types | Decide |
| 5.2.5 | OPEN | Tribes in rotation and per lobby | 5 of 10 | Decide once tribes exist |
| 5.2.8 | OPEN | TFT-style traits (leaning no) | None | Decide |
| 8.3.2 | OPEN | Minimum front-row count (1-front "fortress" boards) | No rows | Decide after testing |
| 11.5.3 | OPEN | Effects that reach the back row (splash; Galaxy's Sneak as an example) | No rows | Decide when Bramble's own mechanics are designed |
| 4.1.2 | BRAMBLE | Unspent gold carries over (N1 §2.1) | Lost at end of turn | — |
| 4.1.3 | BRAMBLE | No gold cap, no interest (N2 §3) | Reset to max 10 each turn | — |
| 4.3.1 | BRAMBLE | Every unit is Bought or Created (N1 §2.2) | No distinction | — |
| 4.1.1 | BRAMBLE | Income 5 on turn 1, +2 a turn until 15, then +1 a turn, no ceiling (C13) | 3, +1 a turn, max 10 | — |
| 4.2.1 | BRAMBLE | A unit costs its tier + 1 (C13) | Always 3 | — |
| 4.3.3 | BRAMBLE | Every real card sells for half its tier, rounded up, Bought or Created; tokens for 0 (C13, replacing N1 §2.2; C17) | All sell for 1 | — |
| 4.3.4 | BRAMBLE | Tripled golden sells for 4.3.3's value per real-card copy; tokens add nothing (C13, C17, replacing N3) | Sells for 1 | — |
| 4.3.5 | BRAMBLE | Any merge with a Bought unit is Bought (N3) | — | — |
| 4.3.7 | BRAMBLE | A unit sells from the board or from the hand, for the same value (C15) | Board only | — |
| 4.4.2 | BRAMBLE | Refresh cost rises with paid refreshes in a turn, no cap (N1 §2.3; N8) | Always 1 | — |
| 4.4.4 | BRAMBLE | Refresh count resets each turn (N2 §3) | — | — |
| 4.6.2 | BRAMBLE | Upgrade base costs 8, 12, 16, 19, 26 (C13) | 5, 7, 8, 11, 11 | Recheck once real units set the power gap between tiers |
| 4.6.3 | BRAMBLE | Upgrade discount grows each turn waited: 1, 2, 3, 4, 5 (C13) | 1 a turn | — |
| 4.6.4 | BRAMBLE | The discount resets to 0 at each upgrade; several upgrades a turn allowed (C13) | Cost resets to the next tier's base | — |
| 5.2.1 | BRAMBLE | Units have an MTG-style type line (N1 §5) | 0–2 tribes | — |
| 7.1.1 | BRAMBLE | Hand limit 7 (C14) | 10 | — |
| 7.2.1 | BRAMBLE | Play a unit into any empty slot (BLO; N3) | Position in one packed row | — |
| 7.2.3 | BRAMBLE | Play triggers resolve when the unit is recruited (bought), not when played; replaying from hand repeats nothing (C15) | Battlecry on play | — |
| 7.2.5 | BRAMBLE | No moving back to a full hand; a unit keeps stats, buffs and origin when it moves (C15) | — | — |
| 7.2.6 | BRAMBLE | A recruit effect also resolves for a unit gained without buying (C15) | — | — |
| 7.3.6 | BRAMBLE | The Triple Reward comes when the triple forms, not when the golden is played (C15) | On playing the golden | — |
| 7.2.4 | BRAMBLE | A unit moves from the board back to hand and is played again, free, unlimited (C15) | A played minion stays on the board | — |
| 8.1.1 | BRAMBLE | 7 slots in two rows, F1–F4 and B1–B3 (N1 §3; N2 §1) | 7 in one row | — |
| 8.1.2 | BRAMBLE | 4 front / 3 back is the working cap (N2 §1; N3) | — | Confirm after experiments |
| 8.1.3 | BRAMBLE | Rows staggered like bricks (N1 §3; N2 §1) | — | — |
| 8.2.1 | BRAMBLE | In front of / behind = diagonal neighbours (N2 §1) | — | — |
| 8.2.7 | BRAMBLE | Front row F1–F4, back row B1–B3 (N1 §3) | — | — |
| 8.3.1 | BRAMBLE | Gaps allowed, empty front row legal (BLO) | Packed | — |
| 8.3.4 | BRAMBLE | No packing, ever (BLO; N3) | Minions slide left | — |
| 9.1.2 | BRAMBLE | Units start combat in their recruit slots (BLO) | — | — |
| 9.4.2 | BRAMBLE | Attack order front L→R, then back L→R, repeat (N1 §3; N2 §1) | One row, L→R | — |
| 9.4.4 | BRAMBLE | Rows set only order and targeting; empty front row is no special case (N3) | — | — |
| 9.5.1 | BRAMBLE | Back row can't be attacked while any front unit lives (N2 §1) | Any enemy minion | — |

**Tuning watch-list** (not rules): the v0.7 upgrade costs (4.6.2–4.6.3) were tuned in simulated lobbies whose results rest on guessed unit power, scaling and economy units. Recheck them with real units and playtests, together with damage: the same sims ran about 16 fights a game against 10.1.3's aim of 13–14 ([../research/economy/README.md](../research/economy/README.md)).
