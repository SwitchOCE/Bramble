# Costing pass 1: Hedgerow, Fairies, neutrals, spells, heroes

Rough, for flagging big misses before simulation. Read-only review. Scripts behind the arithmetic: `reach.py`, `rush.py` in this scratchpad.

**How to read it.** Value = body SP + text SP, against V(t) = 5 / 7 / 8 / 10 / 12 / 14 (power-budget 2.1). Spells: value against cost × S(t), S = 4 at tier 1, 5 above (4.5). `[g]` means the number rests on a guess: a guess-grade class in the budget, or my estimate of firings. Band: ±15% plain, ±25% for recruit triggers, gold, scaling, slots. Row-bound bodies count Attack at 0.75 in the back (6.1). Heroes have no budget (E85), so I use a guessed yardstick of about 1 gold a turn or 5 SP a turn.

**Prices leaned on most.** c(t) = 3.9 / 3.7 / 3.5 / 3.1 / 2.6 / 2.6. Growth caps per turn 0.8 / 1.3 / 1.7 / 2.5 / 3.8. Recurring gold 5.1 / 4.2 / 4.1 / 2.2 per gold at tiers 3-6, none allowed at 1-2. One-off gold: T1 2.4 then 0.6, T2 4.6 then 1.0, cap 2 a trigger at T1-2. Late gold 2.0 SP. An Acorn is worth 1 to 1.67 gold (2.2 if it ends in a Hoard).

## Hedgerow

| Card | T | Stats | Costing | Value / V | % | Verdict | Change that keeps the idea |
|---|---|---|---|---|---|---|---|
| Mrs Burdock | 1 | 1/2 | 3 + Kit 2 or Acorn about 2.8 | 5.4 / 5 | +8 | fine | Stop Kits tripling (see rule flags) |
| Mr Crumb | 1 | 1/2 | 3 + two +1/+1 at 0.9 = 3.6 | 6.6 / 5 | +32 | over, small | 1/1 (5.6, +12%) |
| The Sleeping Partner | 1 | 1/3 | 4 + 5 gold (3.0 + 3 × 0.6 = 4.8) | 8.8 / 5 | +76 | **over** | 1/2, Snug 3: 2 Acorns (6.0, +20%). Golden 3 Acorns, which is a Stash |
| Miss Prickett | 1 | 1/3 | 4 + Bristle 0.7 + feed 1.3 [g] | 6.0 / 5 | +20 | over, small | 1/2 (5.0) |
| Choirboy Tobias | 1 | 2/1 | 3 + 1.15 + Stash odds 0.6 [g] | 4.8 / 5 | -4 | fine | |
| Mrs Sorrel | 2 | 2/3 | 5 + 0.75 Acorns a fight × 1.67 × 5.1 = 6.4 [g] | 11.4 / 7 | +63 | **over**; recurring gold at T2 is above the cap, and no limit per fight | 1/2, "first attack each fight" (about 9.4, +34%). Sim it, the back-row seat costs her attacks |
| Mr Pym | 2 | 2/3 | 5 + s 0.9 SP × 3.7 [g] | 8.5 / 7 | +21 | fine | Watch with Mast |
| The Absent Almoner | 2 | 2/2 | 4 + 1.33 gold a turn × 5.1 × 0.7 [g] | 8.8 / 7 | +26 | over, edge. 3 gaps give 5-6.7 gold a turn | Buried Acorn returns as 2 Acorns, or matures in 4 turns |
| Old Delver | 2 | 2/5 | 7 + Hunker 2.5 [g] + Tunnel 0.5 | 10 / 7 | +43 | over | 1/4 (7.5) |
| Alderman Dozey | 3 | 2/5 | 7 + double ≥ 7 (E06). Eats at 2×: 4.8 SP a gold, about spell rate | 14+ / 8 | +75 | **over**. Hand-Me-Downs onto a fresh Alderman doubles again | 1/3 (8 total at wake). Hand-Me-Downs can't target a Snug unit, or sim it |
| Sergeant-at-Conkers | 3 | 3/3 | 6 + Stash: 15 × 0.85 less 10 SP of gold = 2.75 | 8.8 / 8 | +9 | fine, sim | Golden 30 per Stash is fine: it is one slot |
| Dr Urchin | 3 | 2/6 | 8 + Bristle 1.4 + feed 2 [g] | 11.4 / 8 | +43 | over | 2/3 (8.4) |
| The Honorary Treasurer | 4 | 3/6 | 9 + 2 SP per gold held and not spent. Stash 19; Hoard 49 | 19-49 / 10 | +90 to +390 | **over**. She pays the full sink rate on gold you still have | 2/4, +1/+1 per 2 gold. Stash +2/+2, Hoard +10/+10 (10-26 SP) |
| Beadle Warrenby | 4 | 3/5 | 8 + Acorns 7 × 0.6 tribe + stats 1.2 [g] | 13.4 / 10 | +34 | over; no limit per fight | 2/4, "up to 2 Spills a fight" (about 11) |
| The Standing Committee | 5 | 4/7 | 11 + full Line +7 Attack × 7: front 28, back 22 | 61 / 12 | +408 | **over**. Quadratic. Golden +14 each | 2/4, +1 Attack to the Line, +2 if all 7 are linked (13-20, +8 to +67, with a logged reason: a gap-free Line is the ask) |
| Old Mother Mast | 6 | 5/9 | 14 + 5 gold a turn at s=3 × 2.2 = 11, compounding [g] | 25-39+ / 14 | +80 to +180 and geometric | **over**. Cap is 2 gold a turn. See loops | 5/5, "Start of turn: an Acorn if you hold a Stash or Hoard, 2 if a Hoard" (about 17, +21%). Hoard counts as one |

## Fairies

| Card | T | Stats | Costing | Value / V | % | Verdict | Change |
|---|---|---|---|---|---|---|---|
| Toadstool Pixie | 1 | 2/1 | 3 + Ring 2.2 | 5.2 / 5 | +4 | fine | |
| Hob-in-the-Hearth | 1 | 1/3 | 4 + 2 Health × 0.9 × 3.9 = 7 | 11 / 5 | +120 | **over**; s 1.8 against cap 0.8 | Tier 2, 1/1 (2 + 6.3 = 8.3, +19%). Or T1 1/1 with one target |
| Mothwing Pixie | 1 | 2/2 | 4 + 1.5 × 0.75 × 3.9 = 4.4 | 8.4 / 5 | +68 | **over**; cap | Tier 2, 2/2 (8.2, +17%). Keeps the puzzle with the Hob |
| Rainbow Chaser | 1 | 1/2 | 3 + 12 gold × 2.0 = 24 at T7; 5 gold = 10 at T5 | 13-27 / 5 | +160 to +440 | **over**, the worst gold in the set. Cap 2 a trigger | 1/1. 1 gold per 2 Bands, 5 for all seven. Still outside; keep with a logged reason (7 plays, a held slot). Golden 10 |
| Hedge Witch | 1 | 1/2 | 3 + Hex 1.4 + 1 a spell at 2.6 [g] | 7 / 5 | +40 | over | 1/1 (6, +20%) |
| Leaf-Gold Sprite | 2 | 2/3 | 5 + 4 gold (7.6) × 0.7 Fairy × 0.7 fill [g] | 8.7 / 7 | +24 | fine on average, +40% on turns 2-4 | 2/2 if the bench shows turn-3 spikes. Flip nets +2 on an open board |
| Crossroads Hob | 2 | 3/2 | 7.2 buff + 2 of body + 1 sell. Debt dodged by free moves | 10.2 / 7 | +46 | over | +3/+3 (8.4, +20%) |
| Spore Sprite | 2 | 1/3 | 4 + 2.2 a turn × 3.7 × 0.7 | 9.7 / 7 | +39 | over; s above cap | 1/2 (8.7, +24%) |
| Dustwing Moth | 3 | 2/4 | 5.5 + 2.2 × 1-2 casts × 0.7 × 3.5 | 11-16 / 8 | +40 to +100 | **over** | 1/3, once a turn (8.6) |
| Cradle Fetch | 3 | 1/1 | 2 + copy of mean unit 10; 40+ on a carry (E31) | 12-40+ / 8 | +50 to +400 | **over**, no ceiling | Copies printed stats and text, not buffs. Golden keeps +4/+4 |
| Cluricaun | 3 | 3/4 | 7 + 7 Attack × 0.9 × survival [g] | 12.6 / 8 | +58 | over | 2/2 (9.6, +20%) |
| Changeling | 4 | 2/2 | 4 + 2 × aimed unit about 9 [g] | 22+ / 10 | +120 and uncapped | **over** | Borrowed Child (designer's option 1): swap back after it attacks once. If still over, tier 5 |
| Will-o'-the-Wisp | 4 | 2/5 | 6.5 + 3 Wisps × 1.6 [g] | 11.3 / 10 | +13 | fine | Sim with Spore |
| Reel-Mistress | 5 | 3/7 | 10 + 6 Ring Attack × 5 extra attackers × 0.6 = 18 [g]. Designer's own: 11 Attack a pass becomes 63 | 28 / 12 | +133 | **over** | 3/5, each Ring dances once a fight (about 14). Attack-only dance if not enough |
| Belladonna Sprite | 5 | 3/7 | 9.75 + 2 halved fronts about 7 [g], more against tall | 16.75 / 12 | +40 | over, sim | 2/4 (12.5) |
| Queen of Elfland | 6 | 7/7 | 14 + tithe 14 SP to 5 others: 56 net per 3 turns, s 19 against cap 3.8, × 2.6 | 63 / 14 | +350, geometric | **over** | Destroyed stats are **split** among the others. Conservation plus focus. Golden doubles the pool |

## Neutral units

| Card | T | Stats | Costing | Value / V | % | Verdict | Change |
|---|---|---|---|---|---|---|---|
| Pennywort Snail | 1 | 1/3 | 4 + 3 extra sell gold 3.6 | 7.6 / 5 | +52 | **over** | 1/2, up to 2 turns (6, +20%) |
| Lamp Moth | 1 | 1/2 | 2.75 + 1.9 (measured) | 4.65 / 5 | -7 | fine | |
| Pill Bug | 1 | 1/4 | 5 + 1.3 [g] | 6.3 / 5 | +26 | over, small | 1/3 (5.3) |
| Earwig Mother | 2 | 1/2 | 3 + 3.2 | 6.2 / 7 | -11 | fine | |
| Cricket Busker | 2 | 2/2 | 4 + 1 gold × 5.1 × 0.7 | 7.6 / 7 | +8 | fine | Golden 4 gold a turn: cap it at 2 a turn |
| Turnip Scarecrow | 2 | 0/4 | 4 + one attack × 0.7 aim [g] | 7 / 7 | 0 | fine, sim | |
| Ballooning Spider | 3 | 3/2 | 4.25 + reach 2.5 [g] | 6.75 / 8 | -16 | fine, sim | 3/3 if weak |
| Sexton Beetle | 3 | 2/3 | 5 + 1.8 gold a turn × 5.1 [g]. Mean 4.5 deaths a fight, so the limit of two nearly always fills | 14 / 8 | +75 | **over**; cap 1 at T3; moves the tier clock | 1/3, once a fight (8.6). Golden +2 |
| Mole Cricket | 4 | 3/4 | 7 + 5 [g] | 12 / 10 | +20 | over, small | 2/4 |
| Larder Spider | 4 | 2/5 | 7 + 2 SP a turn × 3.1 × 0.7 + 1.1 | 12.4 / 10 | +24 | fine, edge | |
| Ichneumon Wasp | 4 | 1/3 | 4 + delayed Venomous 2.5 [g] | 6.5 / 10 | -35 | under on price; sim, since it kills any size | 1/5 after a sim |
| Charcoal Burner | 5 | 4/5 | 9 + about 2 [g] | 11 / 12 | -8 | fine | |
| Pipistrelle Echo | 5 | 3/6 | 9 + each spell × 2.43 on a full row: 12 SP a gold, cap 3.8 a turn | far over [g] | +200 or more | **over**; B8 limit is about 8 SP a gold | 2/5, once a turn, adjacent units get half (about 8.6 SP a gold) |
| Whirligig Beetle | 6 | 5/7 | 12 + 12 damage × 0.85 + scramble 8 [g] | 30 / 14 | +114 | **over**, sim | 3/5, no damage (16, +14%) |

## Tavern spells

| Spell | T | Cost | Budget | Value | % | Verdict | Change |
|---|---|---|---|---|---|---|---|
| Pinch of Dust | 1 | 1 | 4 | 2 | -50 | under | +2/+2 |
| Spore Cloud | 2 | 2 | 10 | 4.4 | -56 | under | +4/+4 (8.8) |
| Glamour | 3 | 1 | 5 | 0.5 alone [g] | sim | same card as Turned Cloak | Cut one |
| Fool's Bargain | 3 | 1 | gold parity | +3 net, debt dodged by aiming at an empty or junk slot | far over | **over** | Gain 3, pay 4 in 3 turns, or your highest-Attack unit loses half |
| Rainbow's End | 3 | 1 | parity | +11 net at 7 Bands | far over | **over** | Cost 2, and the Chaser's new pot (net +3) |
| Elderflower Cordial | 1 | 1 | 4 | 4 | 0 | fine | |
| Rainy Day | 1 | 1 | at most +1 net | 0 or +2, about +1 | 0 | fine | |
| Hungry Gap | 1 | 1 | at most +1 net | +2 now, -1 unit next turn. Tier 2 on turn 1 (3 - 1 + 3 = 5) | over | **over** | Cost 2 (+1 net, no turn-1 tier). Doesn't stack |
| Shake the Tree | 2 | 1 | about 2.3 + keep | fine | | fine. b about 0.04, G1 clean | Hand can bank 10; note it |
| Changing of the Guard | 2 | 1 | 5 | 2-4 [g] | -40 | under, sim | |
| Cold Frame | 2 | 2 | 10 | 9 | -10 | fine | |
| Bread from the Back | 2 | 2 | 10 | 6 | -40 | under | Cost 1 (+20%) |
| Stand Behind Me | 3 | 2 | 10 | 5.6-7.5 | -25 to -44 | under | +2/+3 (9 on two) |
| Hand-Me-Downs | 3 | 2 | 10 | sim | | sim; see Alderman | |
| Poacher's Path | 3 | 2 | 10 | 3-5 [g] | -60 | under | Cost 1 |
| Pawn Ticket | 3 | 1 | parity | +5 on a Created T6, +2 on a bought T6, +3 with Market Day | far over | **over** | Half the tier, rounded up: T6 pays 3, T5 pays 3, T4 pays 2 |
| Turned Cloak | 3 | 1 | 5 | as Glamour | sim | duplicate | |
| Boundary Stone | 4 | 3 | 15 | 4.4 | -70 | **under** | Cost 2, +4/+4 (8.8) |
| Wormwood Charm | 4 | 2 | 10 | 5-9 [g] | -30 | fine, sim | |
| Market Day | 4 | 3 | | saves 1 per buy, 1-3 net | fine alone | fine | State that the refresh schedule's surcharge is added after the set price |
| Harvest Supper | 5 | 3 | 15 | 18.5 | +23 | over, small | Cost 4 |
| All-In Ale | 5 | 1 | sink 2.0 SP a gold | 1 SP a gold | -50 | under | +1/+1 per gold. Nettle and Echo must not double it |
| Beltane Bonfire | 6 | 2 | sink 2.0 | 1.5 SP a gold | -25 | edge, fine | |

## Heroes (yardstick about 1 gold or 5 SP a turn [g])

| Hero | Value | Verdict | Change |
|---|---|---|---|
| Dame Hoolet | changes back Attack value (0.75 to more); can't price | sim | |
| Jack-in-the-Green | can't price | sim | |
| The March Hare | Total upgrades 30, against 42. T6 on turn 6 with 2 buys, turn 7 with 6 | **over**, breaks the target | +4, not +2 (T7 with 4 buys, same as econ-heavy) |
| Jill Down-the-Tree | +2 a turn for up to 5 turns, 10 gold, shrinking shop | fine | State that dropping sets upgrade cost to base |
| Tuppence | 2 net gold per 1 card seen, against 1 gold per 6: about 12× worse looks | **under** | A buy refills the **whole** shop. Keep the schedule on buys |
| Pipkin | +2 cards, 2 buys a turn | fine, maybe under late | |
| Keeper Greaves | 1, 2, 3... gold per ban | fine | |
| Mistress Burdock | a slot, a safe Snug or Mast | fine, sim. **Name clashes:** Mrs Burdock; "Larder" is a Hedgerow word | Rename hero and her slot |
| Aunt Dormer | a golden every 3 turns. Golden Chaser: 25 gold by turn 7 | **over** | One bed only, sleep 4 turns, tier ≤ your tier - 1 |
| Goody Nettle | Hungry Gap casts for +6 on 1 gold; Fool's Bargain +8 | **over**, breaks proposed G6 | "Not gold or X spells" |
| Hob Mumblecrust | +3 once, then -1 a turn. T2 on turn 1. Income always covers 4 from turn 2, so Health is never paid | fine; the text is mostly inert | Let the player choose Health |
| Dame Farthing | +3 a turn at a 15 bank (T6 unit cap 2). T6 on turn 8 | over, small | Up to 2 |
| Reynard the Fence | T5-6 flips free; triple hunting costs only refreshes | fine with fixed wording | "A Bought tier 5-6 unit sells for 3", never "at tiers" |
| Marketwife Sorrel | +1-2 gold a turn early; T6 on turn 7-9 | over early | Only one discount a turn |
| Little King Wren | scales with the enemy; about 5-10 SP | fine, sim | |
| Mother Snare | | fine, sim | |
| Brother Bracken | Turn 1: +4/+4 on one unit. Turn 3: +8/+8 on a 15 SP board | **over** early | Same-row neighbours only (max +2) |
| Hazel Oldroot | 7 units rotate: 2.3 plants a turn × 4.4 = 10 SP a turn | **over** | One plant a turn at most, +1/+1 |
| Mistress Fidget | r 0.25-0.5. Burdock line breaks even (loops) | fine | |
| Old Mother Mousewife | Mice only fill gaps that cost a unit; even trade | fine | |

## Loops

**Nothing goes infinite with the cards as worded, provided Reynard is read by the unit's tier.** Every gold-positive line needs paid refreshes to find its pieces, and the price passes what it returns.

| Line | Arithmetic | Result |
|---|---|---|
| Reynard + Market Day | T6 shop: 6 units × 11% tier 5-6 (592-copy pool). +1 each = 0.67 gold a shop, against price 1. Tier 3-4 flip at 0 | Finite. Median shops, from 12 / 30 / 60 gold: 18 / 26 / 34 (sim). At 25% density: 27 / 33 / 40 |
| Reynard read as tavern tier | Every unit buy 2, sell 3: +6 a shop. Positive until price 6, refresh 41. About 125 gold | **74 shops from 12 gold.** Fix the wording |
| Reynard + Market Day + Chaser | Chaser hit every 6.6 shops (15%): buy 2, sell 13, +11 = 1.67 a shop. Plus 0.67 = 2.33 a shop. Free moves let one empty slot paint all seven | **Gold-positive to refresh 20, about +22 gold**, then falling. About 37 shops from 12 gold, 41 from 30. Finite, above the owner's 20-30. Chaser fix drops it to 1.43 a shop (positive through refresh 15 only) |
| Market Day + Chaser, no Reynard | 5 net per Chaser ÷ 6.6 shops = 0.76 a shop | Finite, Λ about 0.76 |
| Tuppence | Every look costs at least 1 net (Market Day: 2 - 1). Best case: Burdock, Chaser in the mix, about -0.64 a look at tier 4 | Finite by gold alone. If Market Day's "cost 2" overrides the surcharge, the schedule is void, still finite. State the order |
| Great Hoard | 9 Acorns = 20 gold, 2.22 an Acorn. Burdock flip: 3 - 1 - 2.22 = -0.22 | No loop. Eats +25/+25 = 2.5 SP a gold, top of the sink window |
| Almoner + Burdock | 3 buried = 15 + 5 = 20 gold, 6.67 an Acorn. Burdock flip +4.67, but one bury a turn, one gap each, 3 turns | Per-turn limit, no loop. Up to about 5 gold a turn at T2 |
| Fidget + back-row Burdock | Buy, play, sell, play Acorn = 4 actions, +1. Return 3 on 3. With Stash: 9 spent, 10.5 back | Gold-positive per Burdock; hit rate 0.23 a shop at T1 gives 0.12 against net price 0.75. Finite |
| The Pot and Rainbow's End | 7 flips at -2 = -14 for 12. With Market Day and a Cluricaun: -7 + 11 = +4 a cast; one Rainbow's End per 20 shops | Finite |
| Mast | s Stashes make s Acorns: s × 4/3 a turn. 20 gold (s=3) becomes 106 in 6 turns, 142 in 7. Golden 245 in 5 | **Per-turn compounding, no end within a game.** Not a within-turn loop, so no schedule touches it. Capped at 3 Acorns: 60 in 6 |
| Nettle + Gap at tier 1 | Gap hit 25% a shop = 4 gold for 1 Gap; returns 6 next turn. 5 copies, shop shrinks | r 1.2 across turns. Finite |
| Kit triple | 3 Burdocks flipped: 6 net gold, sell golden Kit +1 = 5 gold for a free Triple Reward. Hold the Burdocks: 2 rewards for 9 gold by turn 3 | No loop; real bargain |

## Tier 6 and the economy

Base rules already reach tier 6 on turn 7 with 2 units bought, and turn 8 with 5 (`rush.py`: most units bought with T6 on that turn). So the honest test is the board you have on arrival.

| Line | T6 turn 6 | Turn 7 | Turn 8 |
|---|---|---|---|
| Base rules | none | 2 | 5 |
| Econ-heavy (the settled ceiling) | 0 | 4 | 9 |
| High-roll (meant to be out of reach) | 3 | 8 | 13 |
| Partner T1 | none | 3 | 7 |
| Two Partners | 2 | 5 | 9 |
| Partner + Sexton | none | 5 | 10 |
| Hare +2 | 2 | 6 | 9 |
| Hare + Partner | 4 | 7 | 11 |
| Gap + Partner + Chaser + Sexton | 4 (overstated: few Bands) | **8** | 12 |
| All four, after fixes | none | 5 | 9 |
| Hare at +4 | 0 | 4 | 7 |

**Finding: yes, the set breaks it.** Four cards reach turn 7 with 8 buys, which equals high-roll, and two cards reach turn 7 with 5. Worst pieces: Partner, Sexton, Chaser, Hungry Gap, Hare. Also, Hungry Gap or the Hob's loan gives tier 2 on turn 1; under the model's own buying policy that shifts the whole curve a turn (1/3/5/7/9). The fixes bring single cards back near base and the four-card line near econ-heavy (5 against 4). A slightly-over turn-7 line remains, so re-check on the bench. If it matters, raise upgrade to T6 from 11 to 12.

Fool's Bargain and Rainy Day barely change T6 turns alone; they add bodies.

## Rule and wording flags

- **Reynard:** "at tiers" must mean the unit's tier.
- **Market Day and the surcharge:** step price first, then additions, then reductions (economy-bounding delta 5). "Cost 2" needs to fit that.
- **Tokens tripling:** Kits as written give Triple Rewards. Suggest "tokens triple, with no Triple Reward".
- **Does playing an Acorn count as a "play"** for Mistress Fidget, and for "play" triggers?
- **Name clashes:** Mrs/Mistress Burdock, Mrs/Marketwife Sorrel, Larder (keyword and hero slot). Glamour and Turned Cloak are one card.
- **Fool's Bargain aim:** any slot means an empty one.
- **Hedgerow Stash and hand limit:** 10; Mast fills quickly below Hoard size, a small natural brake.

## Can't price without a sim. What the bench should measure

| Cards | Measure |
|---|---|
| Changeling, Cradle Fetch, Whirligig, Belladonna, Ichneumon, Scarecrow, Wormwood | Win-rate delta by placement, with and without seeing the next opponent's last board. Share of fights where the aim hits |
| Reel-Mistress | Attack per pass and survival, by Ring count; deaths when a Ring leaves |
| Standing Committee, Line cards | Mean Line length at fight start, by turn |
| Queen | Board SP by turn with a tithing policy, max board |
| Dame Hoolet, Jack-in-the-Green | Row value of back Attack under each order; win rate |
| Treasurer, Mast, Sergeant, Eats | Cash-or-hold bot: mean Larder by turn, SP per gold against the 8 SP limit (B8) |
| Spill and Acorn sources | Acorns per fight and per turn, by build; gold per turn against the caps |
| Bands | Turn the Pot fills; gold per Chaser |
| Economy overall | Histogram of T6 turn and units on board on arrival. Share under turn 8 |
| Turn length | Shops per turn p50 and p90 at banks of 12, 30, 60 for Reynard + Market + Chaser, Tuppence, Fidget + Burdock (G10) |
| Spells as a whole | Late sink SP per gold, which must stay at 1.8-2.5 for the gold table to hold |
