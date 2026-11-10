# Breaker audit: Hedgerow folk, neutrals, Hive

Snapshot: `Bramble-ideation-rules`, preset B. Judged from the code (`pass3_hedgerow.gd`, `pass3_neutrals.gd`, `combat/pass3_hedge_combat.gd`). Maths by hand; nothing run.

## Top findings (worst first)

1. **Mrs Mallow (T3) breaks rule 1 on her own.** With exactly two other Hedgerow units she triples both every turn: 3^t. No combo needed, about turn 5, in 5 of 6 lobbies.
2. **Alderman Dozey (T4) breaks rules 1 and 2 on his own.** He triples himself every 3 turns for ever (x1.44 a turn), on top of fed stats.
3. **Standing Committee (T5) breaks rule 1 on its own.** The smallest unit is among the receivers, so it gains a quarter of itself each turn: x1.25 a turn (golden x1.5).
4. **Charcoal Burner (neutral T4, every lobby) breaks rule 1.** 6 gold a turn buys x1.3 a turn on one or two units, uncapped. A gold cost is not a cap.
5. **Squire Lollop (T6) breaks rule 1 by leapfrog.** The biggest is skipped, but a receiver overtakes it and becomes the next source: about x1.1 a turn (golden x1.2). Slow, but exponential.
6. **These five multiply each other.** Mallow + Committee is about x2 to x2.6 a turn; Dozey behind a Burner is x1.9 a turn; Lollop spreads any of them to the whole board.
7. **Mr Crumb and Mrs Clover are fine today but defeat any "catch-up" cap:** they move or copy current stats, so a capped Mallow plus a Crumb pipeline still doubles the biggest unit each turn.
8. **Treasurer, Hayward, Beadle, Mast, Sergeant, Click Beetle are power fantasies and obey the rules,** but rule 2's wording ("a fixed amount each turn") would wrongly kill Treasurer and Hayward.

## Table

| Card | Tier | Growth class | Verdict | Reason |
|---|---|---|---|---|
| Mrs Mallow | 3 | exponential (x3/turn) | breaks rule 1 | Triples current stats every turn, no cap |
| Alderman Dozey | 4 | exponential (x3 per 3 turns) | breaks rules 1, 2 | Multiplies itself for ever |
| Standing Committee | 5 | exponential (x1.25/turn) | breaks rule 1 | Smallest feeds itself |
| Charcoal Burner | 4 neutral | exponential (x1.3/turn) | breaks rule 1 | Paid, but repeatable and uncapped |
| Squire Lollop | 6 | exponential (~x1.1/turn) | breaks rule 1 | Leapfrog makes receivers the source |
| Mr Crumb | 1 | flat alone | fine now; loophole | "When sold: Pass its stats" moves multiplied stats |
| Mrs Clover | 2 | flat copy | power fantasy | Every summon is born Clover-sized; no self-feed |
| Honorary Treasurer | 4 | polynomial (with Mast) | power fantasy | +2/+2 per Larder gold; the Larder is hand-capped |
| Goodman Hayward | 5 | linear | power fantasy | +1/+1 tribe-wide per gold of items played |
| Old Mother Mast | 6 | linear (capped 5) | fine | The cap is what stops x1.2 a turn; keep it |
| Sleeping Partner | 1 | flat | fine | Up to 12 Acorns per 3 turns |
| Beadle Warrenby | 4 | linear | fine | +2/+2 per Acorn got; about +10 to +20 a turn |
| Mr Pym | 2 | flat | fine | +3/+3 per Stash |
| Sergeant-at-Conkers | 3 | one-shot per fight | power fantasy | A Great Hoard turns the enemy across to 0/1; costs the Hoard |
| Mrs Burdock | 1 | flat | fine | See Click Beetle note |
| Mrs Sorrel | 2 | flat | fine | A Shrewlet or an Acorn per attack |
| Dr Urchin | 3 | flat | fine | Bristle and Hunker |
| Click Beetle | 5 neutral | flat doubling of on-plays | power fantasy | No multiplier on-plays in my group; one gold-neutral Burdock line |
| Pipistrelle Echo | 5 neutral | flat (x3 spell value) | fine | No multiplying spell can be aimed at it |
| Money Spider | 3 neutral | flat gold | fine | +1 gold a turn |
| Sexton Beetle | 3 neutral | flat gold | fine | Up to 2 gold a turn |
| Cricket Busker | 2 neutral | flat gold | fine | 1 gold a turn |
| Pennywort Snail | 1 neutral | capped | fine | Up to 3 turns |
| Lamp Moth | 1 neutral | flat | fine | Tier-up discount |
| Ichneumon Wasp | 4 neutral | flat | fine | A wanted answer to one giant unit |
| Whirligig Beetle | 6 neutral | one-shot per fight | fine | -10% Health once |
| Ballooning Spider, Shieldbug, Turnip Scarecrow, Pill Bug, Earwig Mother | 1-3 neutral | flat | fine | Combat utility |
| Worker Bee (Hive) | 1, not in pool | flat | fine | Swarm, combat only |
| Vanilla units, tokens and other not-in-pool Hedgerow and neutral units (Field Vole, Kit, Shrewlet, Hoglets, Dormouse, Marmot and so on) | - | flat | fine | No growth text |

## Detail

### Mrs Mallow, Feeding Them Up (T3, 2/5) - breaks rule 1
Text: "End of Turn: triple your two smallest other Hedgerow units' stats." Golden: four smallest.

Code: the multiplier is 3.0 at preset B (the JSON says 2.0). It reads base + permanent + **tribe layer** and adds the result permanently, so Hayward's tribe bonus gets baked in and multiplied too. One firing per turn (loop guard).

- **Best use:** keep exactly two other Hedgerow units and fill the other four slots with off-tribe utility. Both are tripled every turn.
- **Growth:** s0 x 3^t each. Bought turn 5 with two 5/5s: 405/405 each by turn 9, 3,645 by turn 11. The run-1 target is a 900 board at round 12. With six other Hedgerow units the triples rotate: each unit x3 every 3 turns, board x1.44 a turn. Still exponential.
- **Combos:** Committee (below). A tripled Crumb sold Passes it all to F4. A tripled Clover makes every Kit that size. Burner in front: x3.9 a turn. Lollop spreads a tenth to everyone.
- **Fantasy or degenerate:** degenerate. One T3 card and any two tribe units; nothing in the pool out-scales 3^t, and Sergeant or the Wasp answer one unit, not two.
- **Frequency:** T3, 13 copies, Hedgerow in 5 of 6 lobbies. Most players in those lobbies see one by turn 6 or 7. Nearly every Hedgerow game.
- **Smallest change (pick one):**
  - A. "End of Turn: triple your two smallest other Hedgerow units' stats, but never past your biggest unit." Keeps the tripling and the "feed the runts" story; the runts catch up fast and then stop. Needs the Crumb fix below.
  - B. "End of Turn: your two smallest other Hedgerow units gain +4/+4." Safe and plain; loses the thrill.

### Alderman Dozey (T4, 3/6) - breaks rules 1 and 2
Text: "Larder items played on this: +2/+2 per gold. Every 3 turns in this slot: triple its stats."

- **Best use:** park him, feed Stashes and Hoards just before each wake.
- **Growth:** S(next wake) = 3 x (S + 2 x gold fed). Bought turn 7, fed 20 gold per window: 129 at turn 10, 507 at turn 13, 1,641 at turn 16. x1.44 a turn from his own stats.
- **Combos:** behind a Charcoal Burner x1.9 a turn; Lollop passes a tenth of him to the board each turn; Hayward also fires on each item he eats.
- **Fantasy or degenerate:** one unit, so Sergeant and the Ichneumon Wasp answer him. But one T4 card, no assembly.
- **Frequency:** T4, 11 copies; common.
- **Smallest change:** "Every 3 turns in this slot: gain again everything Larder items gave it since it last woke, twice over." Food eaten in the window counts triple. The timing game (feed him before he wakes) survives, and growth is linear in gold fed. "Up to three times a game" is legal under rule 1 but still makes a 1,600-stat unit.

### The Standing Committee (T5, 5/7) - breaks rule 1
Text: "End of Turn: Hedgerow folk touching this gain a quarter of the smallest one's stats." Golden: half.

Code: "touching" is the unbroken zigzag run and **includes the Committee itself**. The smallest is one of the receivers.

- **Growth alone:** smallest m becomes 1.25m and stays smallest (everyone gains the same amount), so m(t) = m0 x 1.25^t and every unit gains m(t) - m0. x9.3 after 10 turns; golden x57. Up to 7 units.
- **With Mallow:** Mallow keeps lifting the smallest, which is the number the Committee reads. Committee + Mallow + 2 others: about x2.6 a turn; with a full run about x1.9. This is the brief's known case and I confirm it.
- **With Lollop:** see below; the pair couples.
- **Frequency:** T5, 9 copies; needs only a Hedgerow board. Roughly one game in three or four for a Hedgerow player who reaches T5.
- **Smallest change:** "End of Turn: Hedgerow folk touching this gain +2/+2 for each Hedgerow folk touching this." Up to +14/+14 on seven units a turn: big, linear, still about one unbroken run. The "never past your biggest unit" cap also works here and keeps the text.
- Excluding the smallest is not enough: with Lollop it is then a coupled pair growing x1.16 a turn.

### Charcoal Burner (neutral T4, 4/6) - breaks rule 1
Text: "End of Turn: burn up to 6 of your gold above 5. The units behind this gain a twentieth of their stats per gold." Golden: 12.

Code: gold carries over, so bank 5 once, then burn 6 of the 10 income each turn. Reads base + permanent only (no tribe layer, no Rings). At F2 or F3 two units sit behind it.

- **Growth:** x1.3 a turn on two units; x8.2 over 8 turns. Golden x1.6. Two Burners at F2 and F3 both hit B2: x1.69 for 12 gold.
- **Combos:** Mast's Acorns pay for it. Dozey, Treasurer or Mallow's runts behind it.
- **Fantasy or degenerate:** the cost is real (60% of income) and alone it feels fair, but it is in every lobby, needs no partner, and is uncapped repeated multiplication. By the rule it must change.
- **Smallest change:** "The units behind this gain +2/+2 per gold burned" (+12/+12 on two units for 6 gold). Or keep the share and add "never past your biggest unit".

### Squire Lollop (T6, 6/8) - breaks rule 1 (slowly)
Text: "Start of Turn: Hedgerow folk touching this, except your biggest, gain a tenth of its stats." Golden: a fifth.

- **Growth alone:** receivers within 10% of the biggest overtake it and become next turn's source. Six equal units: all but one gain 10% each turn, for ever. About x1.1 a turn, x2.1 in 8 turns. Arrives late, so weak in practice, but it is the banned pattern.
- **Combos:** it spreads any exponential unit (Dozey, a Burner target) to the whole run, 10% a turn.
- **Smallest change:** "...gain a tenth of its stats, but never past it." No leapfrog: the manor lifts everyone toward the lord and stops. Bounded by the biggest unit.

### Mr Crumb (T1) and Mrs Clover (T2) - keep, with one guard
- **Crumb:** "When played: Pass +1/+1. When sold: Pass its stats." Alone: a 3-gold courier, flat. The danger is only as a converter: anything that inflates Crumb (Mallow today, a capped Mallow tomorrow) is cashed onto the biggest unit by selling him. With cap fix A and a queue of Crumbs, the biggest unit doubles each turn. Guard: "When sold: Pass the stats it was given by Passes." The courier idea stays.
- **Clover:** "After you summon a Hedgerow unit: give it all this unit's stats" (golden: twice). No per-turn limit in the pass-3 code. Best line: grow Clover with Passes, then buy a Burdock each turn for a permanent Clover-sized Kit; in fights every Sorrel Shrewlet is Clover-sized. Growth is +X per summon with X fixed by other cards: linear. Nothing she summons can feed her. Real assembly, and a strong board still beats it. Keep.

### Honorary Treasurer + Old Mother Mast - power fantasy
Treasurer: "End of Turn: gain +2/+2 per gold in your Larder." Mast: "Start of Turn: get an Acorn per 5 gold in your Larder. Up to 5."

- **Best use:** hoard items (3 Acorns make a 5 Stash, 3 Stashes a 16 Hoard). Hand limit 10 caps the Larder; a realistic rich Larder is 40 to 60 gold, so +80 to +120 a turn on one unit. With Mast the Larder grows about 9 gold a turn, so the gain is quadratic until the hand fills, then linear.
- **Cost:** every gold in the Larder is gold not spent. One unit, so Sergeant and the Wasp answer it.
- **Watch:** several Treasurers all read the same Larder for free. Still linear.
- **Mast:** without "Up to 5" the Larder would grow x1.2 a turn. The cap only applies while `card_rate_limits` is on.

### Goodman Hayward and Sergeant-at-Conkers - power fantasies
- **Hayward:** "After you play a Larder item: your Hedgerow folk have +1/+1 per gold this game." A played Hoard is +16/+16 on up to seven units; with Mast about +9/+9 tribe-wide a turn. Linear. The one danger, Mallow multiplying the tribe layer, goes with her fix.
- **Sergeant:** "Start of Combat: throw your smallest Larder item across. That enemy loses a tenth of its stats per gold." Hold only Hoards and the enemy across becomes 0/1, at 16 gold a fight. One shot per fight, so rule 1 allows it. It is the pool's best answer to a tall board; keep it.

### Click Beetle - power fantasy
"Your When played effects trigger twice." No on-play in my group multiplies stats. One line to know: with a full board, Burdock's Kits Spill into Acorns, so buy (3), two Acorns (2), sell (1) is gold-neutral, and each loop gives Beadle two Passes and Hayward +2/+2 tribe-wide. Golden Beetle makes it +1 gold a loop. Bounded by Burdocks in the shop and reroll cost: a big turn, not an endless loop. Birds reviewer: check Beetle with Mother Goose (two Golden Eggs per homecoming).

## Rule wording problems

1. **Rule 2 would wrongly kill Treasurer, Hayward and Beadle.** "Adds a fixed amount each turn" is too tight: their amount varies with gold, items or counts. Suggested wording: "A card's gain each turn may depend on gold, items, counts, tier or printed stats, but never on any unit's current stats, its own or another's."
2. **A cost is not a cap.** Charcoal Burner pays 6 gold a turn, and income renews. Say so in rule 1: "A gold or card cost does not count as a cap."
3. **"Every 3 turns" is still "again and again".** Dozey shows it. Add: "A period does not count as a cap."
4. **Excluding the source is not enough.** Lollop skips the biggest and still compounds by leapfrog; Committee-minus-smallest plus Lollop compounds as a pair although each alone would be linear. Test to add to the breaker review: "Can any receiver ever become, or feed, the unit being read? If yes, it is multiplication."
5. **Movers and copiers are the loophole.** Crumb's sale and Clover's copy are not growth, so the rules pass them, yet they turn any catch-up cap into growth of the biggest unit. Add: "An effect that moves or copies current stats is checked together with every multiplier in the pool."
6. **A cap type worth allowing by name:** "never past your biggest unit". It lets Mallow, Lollop, Committee and Burner keep their share-based text, and bounds the board at 7 x the biggest unit, which must then grow by linear means. Rule 1's examples of a cap ("up to three times a game") don't obviously cover it.
7. **Goldens count.** Golden Committee (half), Mallow (four targets), Burner (12 gold), Lollop (a fifth) all double the rate. The rules should say the golden text is judged too.
8. **Text and code disagree.** Mallow and Dozey JSON say x2, preset B says x3; "touching" includes the card itself; Mallow multiplies the tribe layer; Committee and Treasurer are not guarded against an End of Turn doubler (the `scale_doubler` lever; no pool card has it).
