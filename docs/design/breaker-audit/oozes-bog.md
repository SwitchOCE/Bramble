# Breaker audit: Oozes and Bog folk

Snapshot: `/home/alex/code/Bramble-ideation-rules` (ideation/design-hard-rules), preset B, loop guards on. Everything below was read from the code (`src/core/pass3_oozes.gd`, `held_units.gd`, `combat/pass3_ooze_combat.gd`, `pass3_bog.gd`, `combat/pass3_bog_*.gd`, `recruit_rules.gd`). Nothing was run. The maths is by hand; comparisons with "a normal board" are my estimate, not measured.

## Top findings (worst first)

1. **Stone Soup (tier 1) closes an exponential loop with eating. Rule break.** Soup's shop bonus (a fifth of your biggest Ooze) is locked onto the meal and eaten. Biggest Ooze: S -> 1.2 S per meal; x1.56 per meal behind Aunt Aspic; x1.92 behind a golden Aspic. The four-card version (Soup, Dollop, Nell, Aspic, all tier 1-3) is about x2.4 a turn.
2. **Cut-and-Come-Again's Slice is the same loop.** A Slice (a fifth of the biggest Ooze, not an Ooze) can be swallowed from hand for free and digested: x1.2 a turn, x1.56 with Aspic, and Elder hands every other Ooze the Slice too. Rule break. Three Slices also triple into a golden Slice with a Triple Reward (the code forgot `plain_copy`).
3. **Elder Ooze turns the Soup loop from one carry into the whole board:** every other Ooze gains a fifth of the carry per meal. Elder is fine once 1 and 2 are fixed.
4. **His Highness / The Prince: "every third kiss, double the Bog folk beside this" has no cap.** x2 every 3 turns (golden x3) on two units, forever. Slow (about x1.26 a turn) but it is repeated multiplication. Rule break.
5. **The flat eat rate is very high and is probably what the owner felt.** A non-Ooze meal gives 7x its printed stats (2.8x that behind Aspic): a 2-gold tier-1 meal is about +35 stats on turn 2-3, about +98 with Aspic. Not a rule break; a dial (`oozes_eat_printed_multiplier` 7, `oozes_aspic_bonus` 1.8).
6. **Oozes + Hedgerow:** any board unit can be fed to a Digest Ooze for free. A Mallow-tripled Hedgerow unit eaten behind Aspic gives the carry 2.8x its stats and, with Elder, 1x to every other Ooze. Oozes cash in Mallow's exponential; fixing Mallow fixes this.
7. **Frumenty copies whichever engine piece it last ate** (Mallow, Dozey, Monarch, Elder, His Highness). Fine by itself; it doubles any exponential card left in the pool. Two Elders stack (no guard).
8. **Loophole the rules miss: growth that reads the opponent.** Hasty Pudding (gain all of the biggest enemy), Soak, Ranocchio, Tiddy and Nan are linear against a normal lobby, but two such boards facing each other every turn (last two players) feed each other: about x2 a turn for Hasty mirrors.

## Table

| Card | Tier | Growth class | Verdict | Reason |
|---|---|---|---|---|
| **Oozes** | | | | |
| Stone Soup | 1 | exponential with any eater | breaks a hard rule | shop bonus is a share of S and gets eaten back into S |
| Little Dollop | 1 | linear alone | fine | one meal a turn; the loop is Soup's |
| Mrs Posset | 1 | flat (combat) | fine | halves the killer for this fight only |
| Wee Wobbly | 1 | flat | fine | releases contents or a Drip |
| Dishwater Nell | 2 | linear (free meal a turn) | fine, dial | about +35 stats a turn free at tier 2; extra loop step with Soup |
| Moss Ooze | 2 | flat | fine | Shield on release |
| Aunt Aspic | 3 | multiplier on consumed food | power fantasy | 2.8x (golden 4.6x) per meal; only breaks via Soup/Slice |
| Bubble and Squeak | 3 | linear; split is combat-only | power fantasy | a Soup carry that also splits in two |
| The Sixpenny Pie | 3 | flat gold (2 a turn, golden 4) | fine | pays only if contents find room |
| Figgy Duff | 4 | linear cards | power fantasy | golden from two copies plus a Triple Reward, no per-turn limit |
| Frumenty | 4 | copies another card's class | power fantasy | see finding 7 |
| Mr Syllabub | 4 | flat | fine | each unit's Start of Combat once on release |
| Elder Ooze | 5 | linear alone; spreads the loop | power fantasy | others gain the meal's own stats (not the 7x) |
| Hasty Pudding | 5 | linear in the enemy | power fantasy, watch | permanent +100% of biggest enemy each fight, and removes it for 3 deaths |
| Cut-and-Come-Again | 6 | exponential when Slice is eaten | breaks a hard rule | Slice is a share of S and is edible |
| Granny Stir-Up | 6 | flat (combat) | fine | gains Attack this fight only |
| Dewdrop, Drip, Bramble, Bog, Great Ooze | 1-5 | flat | fine | vanilla fillers, not in pool |
| **Bog folk** | | | | |
| Bridge Toad | 1 | linear in enemy Attack | fine | Soak: +0.75x the hitter's Attack per hit |
| Warty Nan | 1 | linear in enemy Attack | fine | smallest gains half the Toll |
| Young Pretender | 1 | flat gold | fine, add a cap | 1 gold per Mired kill, no "twice a fight" unlike its peers |
| Madame Bufo | 2 | flat | fine | halves killer's Attack |
| The Peat Cutter | 2 | flat gold | fine | once a fight |
| Vaulting Hopkin | 2 | flat | fine | borrows a quarter of Attack |
| Gideon | 3 | linear | fine | Soak plus hit back |
| Natterjack Chorus | 3 | linear | fine | lends Mire and Soak; strongest only |
| Spitfire Sal | 3 | flat | fine | Toll as damage |
| His Highness / Prince Restored | 4 | exponential, x2 per 3 turns | breaks a hard rule | uncapped repeated doubling |
| Signor Ranocchio | 4 | linear in enemy Attack | fine | half the target's Attack per attack |
| Tiddy Mun | 4 | linear in enemy Attack | fine | 0.75 Toll split between neighbours |
| Jenny Greenteeth | 5 | linear | fine | pull plus Soak |
| The Prima Donna | 5 | linear | fine | three patches |
| The Lantern Man | 6 | linear | fine | Mire the biggest |
| The Peat King | 6 | flat (combat) | power fantasy | two Peatlings with the dead enemy's stats, this fight |
| Marsh Frog, Peatling, Mudwallow, Common Toad, Crested Newt, Bitter Toad | 1-5 | flat | fine | fillers, not in pool |

## Detail

### Stone Soup (T1 2/3): breaks rules 1 and 2
Text: "Shop units gain a fifth of your biggest Ooze's stats, rounded up." Golden: a fifth of your two biggest Oozes combined.

What the code does: `prepare()` puts the bonus on every shop unit live. On buying into a Belly (`HeldUnits.swallow`) or when Nell feeds, `commit_shop()` makes the bonus permanent on the meal. `eat()` then gives the eater `(meal's own stats + 6 x printed) x (1 + Aspic)`. Own stats include the Soup bonus. After every meal `board_changed()` recomputes the bonus, so Nell's meal reads the already-grown carry.

Maths (S = biggest Ooze, P = meal's printed stats, about 5 at tier 1):
- Soup + any Digest Ooze as the carry: S' = 1.2 S + 7P per meal. Exponential, slow (flat part dominates until S is about 175).
- Add Aunt Aspic behind the carry: S' = 1.56 S + 19.6P per meal.
- Add Nell next to the carry: two meals a turn, about x2.43 a turn. From S = 10: 276, 923, 2,500, 6,300, 15,600 over five turns.
- Ceiling: golden Dollop (Belly 2) at F2, golden Aspic at B1, three Nells at F1, F3, B2: five meals a turn at +0.92 S each, roughly x20 a turn. Golden Soup with Elder (second-biggest is close to S) nearly doubles the share again.
- Elder Ooze: each meal the carry eats gives every other Ooze the meal's own stats, which include 0.2 S. Whole board follows the carry.

Assembly: Soup (T1) + Dollop (T1) is the loop. Nell (T2) and Aspic (T3) make it fast. No high-tier card, no triple. Low tiers hold the most copies (15 each). A player who commits to Oozes should have the two-card loop in most games by turn 4 and the four-card version in something like a third to a half. That is common, not a chase.

Beatable? Early, yes (it is one carry on a tier 1-3 board). By five or six turns after assembly the carry is in the tens of thousands and Elder or plain Soup purchases (every bought unit arrives with 0.2 S) fill the board. I don't see a normal board keeping up. Mrs Posset-style halving and Hasty Pudding are the only answers, and Hasty is an Ooze.

Verdict: degenerate and a rule break. Smallest change that keeps "the pot feeds the shop": **Soup's bonus is not food.** Bought to the board, a shop unit keeps the bonus; eaten, the eater gets the meal without it (in code: Digest and Nell skip `commit_shop`, or `eat()` subtracts it). Soup then makes big bodies from a big carry (0.2 S each, no feedback) and stops feeding the carry. Alternative: Soup counts meals eaten this game (+1/+1 per meal), which is linear by construction.

### Cut-and-Come-Again (T6 4/6): breaks rules 1 and 2
Text: "Start of Turn: get a Slice with a fifth of your biggest Ooze's stats." Golden: two Slices.

Slice is a 1/1 with no tribe, carrying 0.2 S as permanent stats. A Digest Ooze can swallow from hand for free. Eaten by the carry: +0.2 S a turn (x1.2); behind Aspic x1.56; golden Aspic x1.92; golden Cut doubles the Slices. Slice is a non-Ooze, so Elder gives every other Ooze 0.2 S a turn as well.

Second problem: the Slices are not marked `plain_copy`, so three of them combine into a golden Slice and hand out a Triple Reward. That is a free tier-6 discover every three turns (every 1.5 with a golden Cut), on top of the stats.

Tier 6 makes it rarer and later than Soup, but it needs only Cut + one Digest Ooze. Verdict: rule break. Smallest change: **a Slice can't be eaten** (or it is an Ooze token and Oozes gain nothing from eating one), and mark it `plain_copy`. A Slice stays what the name promises: a free fifth-size body every turn, bounded by seven slots.

### Aunt Aspic (T3 2/4): power fantasy, keep
"Oozes in front of this gain 180% more from eating non-Oozes." Golden: 4.6 times as many. Guards already stop two Aspics adding and stop the bonus on Ooze meals. Alone it is a conversion rate on food that is used up: +98 instead of +35 per tier-1 meal. It only compounds when the food is made from Ooze stats (Soup, Slice). Fix those and Aspic is an honest "build around me" card. The number is large; that is a dial, see finding 5.

### Elder Ooze (T5 4/8): power fantasy, keep
"After your biggest Ooze eats a non-Ooze: your other Oozes gain all its stats." Reads the meal's own stats (not the 7x), so with shop meals it is about +5 to six Oozes per meal: flat. Best use is feeding the carry something big from another tribe: a unit of size X becomes 2.8 X on the carry (with Aspic) and X on each of five other Oozes, about 7.8 X in total, once, and the fodder is gone. That is the Hedgerow combo the owner hit: Mallow triples the two smallest Hedgerow units every turn, an Ooze board keeps exactly two, and eats one whenever it is fat. The exponential part is Mallow's. Also: two Elders (or Elder + Frumenty that ate an Elder) both fire; there is no guard. That is linear, but worth a "strongest only" guard for consistency.

### Hasty Pudding (T5 3/9): power fantasy, watch
"Belly 1. Start of Combat: if empty, swallow the biggest enemy. Your biggest Ooze permanently gains all of it." Golden: two biggest.

Each fight: the enemy's best unit is gone until three of your units die, and your carry permanently gains 100% of it (preset B share 1.0; fallback is a fifth). Growth is whatever the lobby's biggest unit is, per fight. That is in family with Hunters (Take: five sixths to nine eighths of the quarry) so I am not calling it a break. Two things to watch: it both removes the carry and banks it, which no Hunter does; and two Hasty boards meeting every turn double each other (S_A' = S_A + S_B). Smallest change if it proves too much: keep the swallow, bank half.

### Figgy Duff (T4 3/5): power fantasy, keep
"Belly 1. What's inside goes golden when you buy another copy." Pass 3 dropped the every-other-turn cooldown, and the pair earns a Triple Reward. So a golden costs two copies, and you can do it as often as you find pairs. Linear, costs real gold and a board slot. Fine; if it runs hot, restore "once a turn".

### Frumenty (T4 2/3): power fantasy, keep
"Belly 1. Digest. This has the text of its last meal." Feed it once, then stop feeding it. It becomes a second Mallow, Dozey ("every 3 turns: triple its stats", now on an Ooze), Monarch, Elder or His Highness. It is exactly as broken as the best card it can eat, so it needs no change of its own once those are fixed. Keep it in every future breaker check as "and what if Frumenty eats this?".

### Bubble and Squeak, Peat King: power fantasy, keep
Both make copies inside one fight only (split in two once; two Peatlings with the dead enemies' starting stats). Nothing carries over. Bubble as the Soup carry is the scary case and that is Soup's fault.

### His Highness, Allegedly / The Prince Restored (T4 3/5 -> 6/7): breaks rule 1
Text: "Snap. Every third kiss: double the Bog folk beside this. First time: become the Prince." Golden: triple.

Code: kisses belong to the player, at most one per fight (a Mired enemy dies while the frog is there), and every third one multiplies the permanent stats of each adjacent Bog folk by 2. One doubling per unit per turn. The Prince keeps the ability, so it repeats for the rest of the game.

Growth: x2 every 3 turns = about x1.26 a turn, golden about x1.44. Best board: frogs at F2, F3 and B2 double six of seven units (adjacent frogs double each other). It multiplies whatever Soak, Tiddy and Ranocchio have added, so the total is (linear lobby-driven growth) x 2^(t/3). From turn 8 to turn 17 that is x8, golden x27.

Assembly: one tier-4 card and any Mire unit. Cheap. Slow enough that it won't feel broken in most games, but it is uncapped repeated multiplication, the exact thing rule 1 names, and it gets worse the longer the game goes.

Smallest change keeping the fairy tale: **"Once per unit"** (same as Golden Egg's "once per Bird"), or "up to three times a game". Each Bog folk gets its one kiss-doubling; new units can still be doubled, so the card keeps working all game without compounding.

### Young Pretender (T1 3/2): fine, tidy up
"After this kills a Mired enemy: get 1 gold next turn" (golden 2). Peat Cutter, Lane-Bard and Sexton Beetle all say "once/twice a fight"; this doesn't. Gold is bounded by kills, so it's not a break, but a buffed golden Pretender with Snap could make 6-10 gold a fight. Add "Twice a fight".

### Soak, Tiddy Mun, Warty Nan, Ranocchio: fine
All read the enemy's Attack (Toll = Attack that Bitter removed last fight; Soak keeps 3 per point taken, golden 6). None reads your own stats, so against a normal lobby they are linear and track how strong the lobby is. See the loophole below.

## Rule wording problems

1. **Rule 1 as written would kill Aunt Aspic and the eat multiplier.** "Gain 180% more from eating" is a multiplier that fires every turn with no cap. It is harmless because the food is consumed and (after the fixes) never comes from the eater. Suggested wording: "No loop. A multiplier may not act, turn after turn, on stats that already include its own earlier output. Multiplying something that is used up (a meal, a sold unit, printed stats) is fine, provided that thing was not itself made from the stats being grown."
2. **Rule 2's "a share of a unit's current stats is multiplication" would wrongly kill Stone Soup and Slice as bodies.** A fifth-size shop unit or Slice that just stands on the board never feeds back. The rule should say "a share of current stats that returns to the unit it was measured from (directly or through another card)". That is the test Soup and Cut fail today, only because of eating.
3. **Missed loophole: opponent-fed growth.** "Gain X% of an enemy's stats permanently" (Hasty, Soak, Ranocchio, Toll cards; also Hunters' Take and Jack Daw) is linear against a normal lobby, but two such boards that fight each other every turn compound each other, and any of them compounds off an opponent's exponential board. Suggested line: "Permanent gains that read enemy stats must total under 100% of the enemy unit per fight, or be capped per fight."
4. **Missed loophole: copied text.** Frumenty, Mag Pye and Cradle Fetch can put a "once per X" or timed multiplier on a new body. Caps should be counted per player (as kisses already are), not per card, and the breaker check should always ask "what if a copier holds this?".
5. **Missed loophole: tokens that triple.** Any created token with a fixed id (Slice here) can triple for a Triple Reward unless marked `plain_copy`. Suggested rule: "Created tokens never count for triples unless the card says so."
6. **Guards live in code, not on cards.** "Strongest only" (Aspic, Soup, Soak) and "Ooze meals get no bonus" are all behind `pass3_loop_guards`. Elder has no such guard. The hard rules should say which stacking is intended so a missing guard reads as a bug.

Outside my group, seen while checking combos: Charcoal Burner (neutral T4) gives the units behind it +5% of their stats per gold burned, up to 6 gold: x1.3 a turn, uncapped, on any carry including an Ooze one.
