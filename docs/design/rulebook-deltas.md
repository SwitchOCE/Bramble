# Rulebook deltas

Every rule in [rulebook.md](rulebook.md) (v0.7 draft, 12 Nov 2026, baseline HSBG patch 36.6.3) that is not plain Battlegrounds, in one place. Rule numbers point into the rulebook, where each rule has its full text and reasons.

- **PROPOSED**: a gap Bramble's differences create. A default is filled in; it needs your yes or a change.
- **OPEN**: undecided, no default.
- **BRAMBLE**: your decision, already recorded. Listed so you can check the wording.
- **EXAMPLE**: an HSBG or Galaxy mechanic kept to show what the rules must handle. Not a Bramble mechanic, and nothing to decide ([N9](owner-notes/2026-11-02e-mechanics-are-examples.md)).

Counts: 101 [BG], 42 [BRAMBLE], 47 [PROPOSED], 11 [OPEN], 26 [EXAMPLE]. v0.7 (12 Nov) sets the economy from the owner's decisions in chat (rulebook source C13): income 5, +2 a turn up to 15, then +1; units cost tier + 1 and sell for half their tier, rounded up; 10 refreshes at 1 gold; tier-ups 8/12/16/19/26 with a discount of 1, 2, 3, 4, 5 for each turn waited; a shop of 5 units and 2 spells. The evidence is in [../research/economy/](../research/economy/README.md). v0.6 (12 Nov) sets damage and starting health from the owner's decision in chat (rulebook source C12): 40 health, a small loss of the round + 1 up to 10, and +3 for a big loss. v0.5 (8 Nov) applies the owner's notes [N11](owner-notes/2026-11-08-autobattler-systems-thoughts.md), [N12](owner-notes/2026-11-08b-taste-answers.md) and [N13](owner-notes/2026-11-08c-rulebook-go-ahead-and-scaling.md): new damage system, stat scale, fixed shop size, and open questions on starting health, pool, tier weighting, shop-slot upgrades and multiple-copy strategies. The 27 Oct decisions are folded in (owner notes [d](owner-notes/2026-10-27d-combat-shape-decisions.md), [e](owner-notes/2026-10-27e-economy-decisions.md) and [f](owner-notes/2026-10-27f-power-budget-decisions.md)), and the 2 Nov no-timer decision ([N7](owner-notes/2026-11-02-pre-development-design-pass.md)). v0.4 makes HSBG and Galaxy mechanics examples instead of Bramble mechanics, and adds slot effects ([N9](owner-notes/2026-11-02e-mechanics-are-examples.md)).

**Most in need of a decision:**
- **The power-budget rescale** for 1.2.5, before any content is costed.

The rest are edge cases with sensible defaults, or open questions to settle by experiment.

**Docs that cite superseded v0.4 rules.** These still describe the old values and are not yet updated:
- HSBG damage caps (old 10.1.4): [archetypes.md](archetypes.md) row ECO, and the Wager entry in the mechanics library ("early bets are cheap because of the damage caps").
- Tier-based damage (old 10.1.1): the Changeling entries.
- Shop sizes of 4–7 cards (old 6.1.1): the back-row "aisles" entry, and the tier-6 frame in [economy-bounding.md](economy-bounding.md) (6 units + 1 spell).
- The pre-v0.7 economy (old 4.1.1, 4.2.1, 4.3.3, 4.4.3, 4.6.2–4.6.3: income 3 to 10, units at 3 gold, sale for 1, 15 refreshes at 1 gold, HSBG tier-up costs):
  - [economy-bounding.md](economy-bounding.md) throughout;
  - [power-budget.md](power-budget.md): buys a turn as gold ÷ 3, the income model, and E51 "maximum gold", which now raises income under 4.1.4;
  - [power-budget-review.md](power-budget-review.md) §"Gold" and §"Buying";
  - the mechanics library and ideas files where they quote 3-gold units.

| Rule | Status | Bramble rule | HSBG equivalent | Decision needed |
|---|---|---|---|---|
| 1.2.5 | BRAMBLE | Stat scale about 2× HSBG (working value); room to tune upgraded and scaling effects | Base scale | Decided 8 Nov (N12, N13); power budget needs rescaling |
| 2.2.5 | BRAMBLE | Starting health 40 by default; heroes may differ for balance (direction open: maybe only upward) | 30 | Decided 12 Nov (C12) |
| 5.1.4 | OPEN | Keep a copy-count pool, or draw by set chances in async play | Shared pool | Decide (N11 §5.5) |
| 6.1.1 | BRAMBLE | Shop shows 5 units and 2 spells at every tier; tiers change only the odds | 4–7 cards, growing with tier | Decided 12 Nov (C13); check the shop layout |
| 6.1.6 | OPEN | Extra shop slots as a separately bought upgrade | Slots come with tier | Decide (N11 §5.3) |
| 6.1.7 | OPEN | Shop draws flat by copies, or weighted toward your tier | Flat by copies | Decide (N11 §5.4) |
| 7.3.8 | OPEN | Multiple-copy strategies (TFT stars) or HSBG's single triple | Single triple | Decide (N11 §5.6) |
| 10.1.1 | BRAMBLE | Small loss if the loser killed at least half the winner's starting units; otherwise a big loss, +3; tiers don't count | Winner's tier + tiers of surviving units | Decided 12 Nov (C12), replacing the 8 Nov rule |
| 10.1.2 | PROPOSED | Starting units: on board when combat begins; killed unless alive on the winner's side at the end; summons never count; returns count | — | Accept |
| 10.1.3 | BRAMBLE | Small loss = round + 1, up to 10; big loss 3 more. Intent: spend gold early; tunable, with fallbacks listed | Caps 5/10/15 | Decided 12 Nov (C12) |
| 10.1.4 | PROPOSED | No cap beyond 10.1.3's cap of 10 (most a loss can deal: 13) | 5/10/15 by turn, off at top 4 | Accept |
| 1.2.3 | PROPOSED | One board order, F1–F4 then B1–B3, for every "left to right" resolution | Left to right in one row | Accept reading order everywhere |
| 1.2.4 | PROPOSED | Integer stats, clamp at 1,000,000,000, condensed display | Condensed display only | Accept clamp value |
| 2.1.3 | PROPOSED | Game ends after round 50; place by health + armor | Turn limit exists, value unknown | Accept 50 or set a value |
| 2.1.4 | BRAMBLE | No turn timer; fights are against snapshots of other players' boards. Duos and bots out of v0 | Live 8-player lobby | Decided 2 Nov (N7) |
| 2.1.5 | OPEN | Lobby size, snapshot matching, ghosts and game end under async play | Live lobby rules | Needs a proposal |
| 3.1.1 | BRAMBLE | Players take Recruit Phases independently | Simultaneous | Decided 2 Nov (N7) |
| 3.1.2 | BRAMBLE | No recruit timer; only refresh cost escalates; most long turns around 20 shops, tuned by playtesting | 60–120 s timer | Decided 2 Nov (N7, N8) |
| 3.2.1 | PROPOSED | Start of turn: gold, upgrade discount, refresh reset, shop refill, triggers | Order undocumented | Accept order |
| 3.4.1 | PROPOSED | End of turn: End of Turn triggers, "this turn" ends, shop returns, gold kept, board copied | Order undocumented | Accept order |
| 4.1.4 | PROPOSED | "Maximum gold" effects change income by that amount (there is no income ceiling) | Max gold = refill and cap | Accept |
| 4.3.2 | BRAMBLE | Units drawn from the pool by effects (Discover, Triple Reward) count as Created and sell for 0 | All units sell for 1 | Decided 27 Oct (N5) |
| 4.3.6 | PROPOSED | Origin sticks; a Created unit made golden by an effect (not a triple) stays Created | — | Accept |
| 4.4.3 | BRAMBLE | Paid refreshes 1–10 cost 1, then +1 gold every 5 (11–15 cost 2, 16–20 cost 3, ...), no cap | Always 1 | Decided 12 Nov (C13), replacing 2 Nov (N8) |
| 4.6.6 | PROPOSED | After 5 turns waited the upgrade discount stays at 5 a turn | 1 a turn | Accept |
| 4.4.5 | BRAMBLE | Free refreshes cost 0 and don't count toward the thresholds | Free refreshes just cost 0 | Decided 27 Oct (N5) |
| 4.4.7 | BG + note | No refresh cap of any kind; free-refresh loops are prevented by content design (guardrail G1) | No cap | Decided 27 Oct (N6) |
| 4.4.6 | PROPOSED | Card effects that reroll the shop don't count toward the thresholds | — | Accept |
| 5.2.3 | PROPOSED | Text naming a type matches any unit with that type on its line | Dual types match either | Accept |
| 5.3.5 | PROPOSED | Selling a golden returns one pool copy per pool-sourced copy in it | Unknown (maybe 3) | Accept |
| 5.3.7 | PROPOSED | Pool units destroyed, consumed or transformed away return their copies | Unknown | Accept |
| 6.1.3 | PROPOSED | Shop draws one copy uniformly from all eligible copies left | Weighted by copies; exact rule unknown | Accept as v0 algorithm |
| 6.1.4 | PROPOSED | No eligible copies left: shop slot stays empty | Unknown | Accept |
| 6.2.3 | PROPOSED | Discover with fewer than 3 eligible units offers what exists | Unknown | Accept |
| 7.3.5 | BRAMBLE | Golden doubles every effect number; thresholds unchanged | Per-card golden text | Decided 27 Oct (N6) |
| 7.3.7 | PROPOSED | Triple with full hand and all copies on board: golden goes to first vacated slot | Unknown | Accept |
| 8.2.2 | PROPOSED | Adjacent = next slot in the same row; doesn't skip gaps | Left/right neighbour | Accept |
| 8.2.3 | PROPOSED | Neighbour = adjacent + in front + behind (up to 4) | — | Accept the term |
| 8.2.4 | PROPOSED | Relations belong to slots; a unit entering a slot becomes the related unit | — | Accept |
| 8.2.5 | BRAMBLE | Leftmost/rightmost are per row; card text must name the row | First/last in the row | Decided 27 Oct (N4) |
| 8.2.6 | PROPOSED | "Across from" = enemy slot with the same label | — | Accept |
| 8.3.3 | PROPOSED | Recruit Phase: move to any empty slot or swap, free, unlimited | Free reordering | Accept |
| 8.3.5 | PROPOSED | Units move only by player moves or effects; move into a full slot fails unless "swap" | — | Accept |
| 8.4.1 | BRAMBLE | A dying unit's first summon takes its slot | Summons appear where the minion died | Decided 27 Oct (N4) |
| 8.4.2 | BRAMBLE | Other summons: nearest empty slot, same row first, ties go right | Next to source, usually right | Decided 27 Oct (N4) |
| 8.4.3 | PROPOSED | Summons with no source slot: first empty slot in reading order | — | Accept |
| 8.4.4 | PROPOSED | Multiple summons placed one at a time | — | Accept |
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
| 4.3.3 | BRAMBLE | Bought sells for half its tier, rounded up; Created for 0 (C13, replacing N1 §2.2) | All sell for 1 | — |
| 4.3.4 | BRAMBLE | Tripled golden sells for 4.3.3's value per Bought copy; Created copies add nothing (C13, replacing N3) | Sells for 1 | — |
| 4.3.5 | BRAMBLE | Any merge with a Bought unit is Bought (N3) | — | — |
| 4.4.2 | BRAMBLE | Refresh cost rises with paid refreshes in a turn, no cap (N1 §2.3; N8) | Always 1 | — |
| 4.4.4 | BRAMBLE | Refresh count resets each turn (N2 §3) | — | — |
| 4.6.2 | BRAMBLE | Upgrade base costs 8, 12, 16, 19, 26 (C13) | 5, 7, 8, 11, 11 | Recheck once real units set the power gap between tiers |
| 4.6.3 | BRAMBLE | Upgrade discount grows each turn waited: 1, 2, 3, 4, 5 (C13) | 1 a turn | — |
| 5.2.1 | BRAMBLE | Units have an MTG-style type line (N1 §5) | 0–2 tribes | — |
| 7.2.1 | BRAMBLE | Play a unit into any empty slot (BLO; N3) | Position in one packed row | — |
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
