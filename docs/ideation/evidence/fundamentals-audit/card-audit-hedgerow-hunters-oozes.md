# Card audit: Hedgerow folk, Hunters, Oozes, neutrals (pass 2 slice)

9 Nov 2026. Read-only reader. Cards: `/home/alex/code/Bramble-ideation-balance/content/units/*.json`, `"set": "slice"` (identical to `ideation/main` after merge 97f8d49; `diff -rq` shows no difference). Content unchanged since the benchmark's code commit c50f6c8 (`git diff --stat c50f6c8 HEAD -- content/` is empty).

Bot data: `/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/free_choice_plain.{rounds,players,cards}.csv`. The `.0.` files named in the brief do not exist; the run is complete (`progress.json` stage "complete", 400 seeds, 3200 player rows, 48,773 round rows, 0 rows with missing fields). Scripts: `bot_stats.py`, `bot_cards.py` in this folder; outputs `bot_stats.txt`, `bot_cards.txt`.

Measurement caveats:
- `rounds.csv` attack/health are **board units only, recruit phase** (`tools/sim/bench.gd:383` `_board_stats`). They exclude units inside Bellies, combat auras (Lollop, Committee, Isegrim, Laird) and combat growth. Oozes are understated most.
- `cards.csv` lists the **final** board only. T6 cards correlate with surviving (survivor bias). No per-unit stats are logged, so "biggest unit" below is hand-estimated from card text.
- `players.csv` `acorns` counts only Acorns won in combat (`bench.gd:149-158`), not recruit-phase Acorns.
- Per the owner (2026-11-09d), bot data is a sanity check only. Bots barely run the Hoard: Hedgerow larder p90 = 2 gold at R8 and 1 at R12.

## Assumptions for the round-10 estimates

Tier 4 (bot mean 4.1 at R10), 6.7 units, about 16 SP a unit (bot p50 15.7), so 7/9 bodies. A front unit is hit about 2 times a fight. Take rate 0.55 per quarry Hunter per fight (costing-3, used by `pass2-costing.md`). Stash rate 0.3–0.4 a turn on a Hoard board (costing guess). SP = Attack + Health.

## Key rules that shape the numbers

- **Pass** (`rulebook.md` 12.1.6, `board_geometry.gd:122`): lands on the last occupied slot in F1-B1-F2-B2-F3-B3-F4. On a full board that is **F4, a front unit**. To keep a Pass carry safe in B3 you must leave F4 empty, which costs a body and breaks "all 7 touch".
- **Touching** (`board_geometry.gd:107`): the unbroken zigzag run. **Any gapless full board has all 7 touching**, so Committee's and Lollop's bonus is near-unconditional late.
- **Permanent-buff ceiling** (`rulebook.md` 12.1.1a): Dozey only (`alderman_dozey.json:54`, +12/+12, golden +24/+24), covering feeding, doubling, Pass and triples. Bridge Toad has +3/+3. No other unit has one.
- **Combat-only by default** (12.1.2): Glutton and Laird call `combat.buff` without `permanent` (`mechanics/glutton.gd`, `mechanics/laird.gd`); Wick and Lodger likewise (`combat/combat_hunt.gd:124-133`). Grizel passes `permanent=true` (`combat_hunt.gd:160`). Dr Urchin's Pass is combat-only (`combat_moves.gd:12`).
- **Take**: a Hunter's quarry dies, by any cause (`combat/combat_lanes.gd:250-266`). Quarry is marked only at the bell (`combat_lanes.gd:108-115`), so **each Hunter gets at most one Take a fight**. Laird lends Quarry to non-Hunters, but only Hunters can Take (line 255).
- **Acorn items**: Acorn 1 gold, Stash 5, Great Hoard 16; three combine into the next size (`content/spells/acorn.json`, `stash.json`, `great_hoard.json`). Combining 3 Acorns gives +67% value; combining 3 Stashes gives +7%.

## Per-card table

Columns: condition | payoff (R10 estimate) | permanence | breadth | growth | cap (binds before R12?) | enabler for | concentrates. "Bot" = final boards holding it (all tribes) and mean place with vs without among players of that tribe.

### Hedgerow folk (16 in pool)

| Card | T, body | Condition | Payoff at R10 | Perm. | Breadth | Growth | Cap | Enabler | Conc. | Bot |
|---|---|---|---|---|---|---|---|---|---|---|
| Mr Crumb | T1 1/2 | Played or sold; another unit on board (Pass reads the board at EOT) | +1/+1 played, +1/+1 sold: +2/+2 per copy cycled (3 gold in, 1 back). R10: about 0, as a T4 shop shows T1 10% of the time | Permanent | One unit (last in zigzag) | Per trigger | None (Dozey's cap if it lands on Dozey) | Feeds the carry; Dozey | Yes | 2 boards |
| Mrs Burdock | T1 1/2 | Played; room behind, else Spill gives an Acorn | 1/1 Kit (2 SP), or 1 Acorn (1 gold); golden 2 Kits | Permanent body / economy | Summons | One-shot | None | Clover (summon), Mallow (smallest), Beadle and Pym (Acorn) | No | 6 boards |
| The Sleeping Partner | T1 1/2 | Stays 3 turns in one slot | 2 Acorns every 3 turns, about 0.67 gold a turn (golden 4) | Economy | – | Linear, every 3 turns | Three times in all. Bought R1–3, it fires R4, R7, R10: **binds at R10** | Beadle, Pym, Treasurer, Dozey, Sergeant, Hayward | No (via Dozey) | 3 boards |
| Mr Pym | T2 2/4 | You get a Stash (3 Acorns combine, or a whole one) | Pass +2/+2 per Stash. At 0.3–0.4 Stashes a turn, about 1.2–1.6 SP a turn (golden 2.4–3.2) | Permanent | One unit | Per trigger | None | Turns every Acorn source into carry stats | Yes | 207 boards; 5.75 vs 3.27 |
| Mrs Clover | T2 2/4 | You summon a unit, any tribe, either phase | +1/+1 to the first 2 summons a turn: about 2–4 SP a turn on a token board | Recruit summons permanent; fight summons this fight | Summons | Per trigger | Twice a turn (binds with Sorrel or Wobbly) | Burdock, Sorrel, Earwig Mother, Wobbly, Mousewife hero | No | 173; 5.94 vs 3.39 |
| Mrs Sorrel | T2 2/3 | Attacks | 1/1 Shrewlet behind per attack (fight only), or **an Acorn if there is no room**: about 1–2 Acorns a fight on a full board | Fight body / economy | Summons | Per trigger | None | The tribe's best Acorn engine: Beadle, Pym, Treasurer, Dozey, Sergeant; Clover | No | 52; 5.69 vs 3.63 |
| Alderman Dozey | T3 2/5 | Acorn items played on it; 3 turns in slot | Acorn +1/+1, Stash +3/+3, Great Hoard +8/+8; one double, up to +8/+8 | Permanent | Self | One-shot double + per trigger | **+12/+12 all permanent sources** (golden +24/+24): max 14/17 (+3/+3 Supper). R9 fixture is already at +8/+11 (`pass2-followup-boards.md`, hedgerow_low): **binds R10–12** | The end point for Partner, Sorrel, Mast and every Pass | Yes, capped | 291; 4.90 vs 3.58 (Hedgerow players: 4.07 with, 3.58 without) |
| Dr Urchin | T3 2/5 | Hit by an enemy attack | Bristle 2 per hit; Pass +1 Attack per prick (fight only). About 2–3 hits: 4–6 thorn damage, +2–3 Attack on the last unit | Fight only | Self + one unit | Per trigger | None | Feeds the carry in the fight; punishes big attackers | Partly | 116; 5.86 vs 3.13 |
| Sergeant-at-Conkers | T3 3/3 | Holds an Acorn item; an enemy across | Throws the smallest item for 3 damage a gold: Acorn 3, Stash 15, Great Hoard 48. The item is spent | One-shot a fight | One enemy | Per trigger | One throw a fight | **An answer to a big unit (scam)**. Competes with Hayward, Pym, Treasurer, Dozey for the same items | n/a (removal) | 54; 6.44 vs 3.55 |
| Beadle Warrenby | T4 2/4 | You get an Acorn | Pass +1/+1, once a turn: about 2 SP a turn with Mast, Sorrel or Squirrel Away | Permanent | One unit | Linear a turn | Once a turn (binds as soon as one Acorn a turn arrives) | Feeds the carry | Yes | 25; 5.96 vs 3.61 |
| The Honorary Treasurer | T4 3/5 | Holding Acorn items | +1/+1 per 3 gold held: a Stash +1/+1, a Great Hoard +5/+5; most +8/+8 at 24 gold | Static aura; lost when items are spent | Self | Flat, follows the larder | +8/+8 (`honorary_treasurer.json:18`). Doesn't bind before R12 (24 gold of items needed) | Rewards holding; opposes Hayward, Dozey, Sergeant | Yes (self) | 142; 5.63 vs 3.18 |
| Mrs Mallow | T4 3/5 | End of Turn | Smallest unit +1/+1: 2 SP a turn | Permanent | One unit, always the smallest | Linear a turn | None | Grows tokens; any tribe | **No: anti-concentration by design** | 157; 5.18 vs 3.32 |
| Goodman Hayward | T5 4/7 | Play (cash or feed) a Stash or Great Hoard | Hedgerow folk touching this +1/+1 per item: 14 SP per Stash on a full Hedgerow board; about 4–6 SP a turn at 0.3–0.4 Stashes | Permanent | Zigzag run of Hedgerow folk (up to 7) | Per trigger | None | Payoff for all Acorn sources; Dozey feeding counts | No | 247; 4.82 vs 3.62 |
| The Standing Committee | T5 5/7 | Start of Combat; gapless full board for the bonus | +1/+1 to touching, or +2/+1 to all 7: **21 SP a fight** | Fight only, every fight | Whole board, any tribe | Flat | Bonus needs all 7 | Everyone; tribe-agnostic | No | 664 boards (523 not Hedgerow); 4.01 vs 4.61 |
| Old Mother Mast | T6 6/8 | First unit bought each turn | 1 Acorn, or 2 while holding a Great Hoard: 1–2 gold a turn | Economy | – | Linear; doubles once a Great Hoard is held | Once a turn | Beadle trigger, Pym, Treasurer, Dozey, Sergeant, Hayward | No | 447; Hedgerow players 2.62 with vs 5.40 without |
| Squire Lollop | T6 6/8 | Start of Combat; gapless full board for the bonus | +1/+1 to touching, or +2/+2 to all 7: **28 SP a fight** (golden 56). Copies stack | Fight only, every fight | Whole board, any tribe | Flat | Bonus needs all 7 | Everyone; tribe-agnostic | No | **568 boards (422 not Hedgerow); 70 of 71 Hedgerow wins; 206 of 336 winners in lobbies with Hedgerow**; win rate with it 0.36, golden 1.53 mean place |

### Hunters (16 in pool)

| Card | T, body | Condition | Payoff at R10 | Perm. | Breadth | Growth | Cap | Enabler | Conc. | Bot |
|---|---|---|---|---|---|---|---|---|---|---|
| Little Nip | T1 2/3 | Its quarry (enemy across at the bell) dies | +1/+1 per Take; at most 1 a fight; at 0.55, about 1.1 SP a turn (golden 2.2) | Permanent | Self | Linear a fight, **depends on winning trades** | One Take a fight (structural) | Is a Take for Glutton, Laird, Ermeline; helped by Young and Old Brock | Yes (slow) | 779 boards; 3.73 vs 4.44 |
| Wick | T1 2/3 | Joins a pack attack | +1 Attack per join, this fight: +1–2 | Fight only | Self | Per trigger | None | Gives a leader a joiner | Partly | 162; 5.20 vs 3.78 |
| Young Brock | T1 1/3 | Start of Combat; units beside it | +1 Attack to 2 adjacent this fight; they mark the enemy across Brock as quarry | Fight only | Adjacent | Flat | Units with a quarry keep theirs | **Focus fire**: makes Takes happen for Nip, Lutra, Glutton, Laird | No | 26; 5.92 vs 3.85 |
| Mistress Russet | T2 3/3 | Take of a quarry at or below your tier | Next shop shows a copy 1 gold cheaper: about 0.5 a fight | Economy (triples) | – | Per trigger | One quarry a fight | Triples (golden Nip) | No | 175; 5.64 vs 3.65 |
| Sable | T2 2/3 | Start of Combat; quarry has more Attack (almost always late) | +3 Attack this fight | Fight only | Self | Flat | None | Good pack leader | Partly (Attack) | 70; 5.96 vs 3.75 |
| The Toll-Bard | T2 2/4 | Its quarry attacks | Quarry −1 Attack twice a fight; +1 gold next turn once | Fight debuff + economy | One enemy | Per trigger | Twice / once a fight | Pays the climb | No | 165; 5.35 vs 3.73 |
| Brother Wolf | T3 3/4 | Units beside it attack | Joins each neighbour's attack once a cycle: +3 damage on up to 2 attacks a cycle, joiners take no counter-hit (`pass2-a.md:35`) | Fight only | Damage onto one target | Per trigger | Once per neighbour a cycle | Isegrim (+3 a join), Grizel | **Offensive concentration** | 195; 5.29 vs 3.66 |
| The Lodger | T3 4/4 | Pounces (a neighbour's quarry is hit) | +2/+1 per pounce this fight: +2–4/+1–2 | Fight only | Self | Per trigger | Once a cycle | Needs Old Brock or a quarry neighbour | Partly | 472; 5.28 vs 3.51 |
| Old Lutra | T3 3/4 | Its quarry dies (reach: any row) | +1/+1 per Take; +1 gold next turn in back | Permanent + economy | Self | Linear a fight | One Take a fight | A Take source | Yes (slow) | 420; 3.94 vs 4.07 |
| Grey Agnes | T4 2/5 | The next slot in her row is occupied | That unit has Pack and +1 Attack | Fight aura | One unit | Flat | – | Pack: Grizel, Isegrim, Wick | No | 164; 5.17 vs 3.64 |
| Madame Ermeline | T4 3/6 | Takes in the fight | Next Tier up −1 per Take (up to 3); at T6, up to 2 gold | Economy (tempo) | – | Per fight | 3 Takes; 2 gold | Faster T5–6. **Positive feedback: winning makes Takes** | No | 531; 5.10 vs 3.45 |
| Old Brock | T4 2/5 | Neighbours | Neighbours get +1 Attack, Pounce, and the enemy across Brock as quarry (reach) | Fight aura | Up to 4 neighbours | Flat | Existing quarries kept | Pounce (Lodger), focus fire | No | 160; 5.31 vs 3.62 |
| Grizel | T5 5/6 | A pack attack kills | Leader and joiners +1 Attack permanently: about 1–2 pack kills a fight, +2–6 Attack a turn over 2–3 units | Permanent (Attack only) | Pack group | Linear a fight; Grizels stack | Once an attack | Pack payoff | Partly | 576; 3.79 vs 4.29 |
| The Mountain Glutton | T5 4/5 | Any Hunter makes a Take | +2/+2 this fight per Take: 2–4 Takes, +4–8/+4–8 | Fight only | Self | Per trigger | None | Laird multiplies it | Yes, but resets every fight | 199; 4.25 vs 3.80 |
| The Laird of the Sett | T6 3/5 | Takes | All your units get Quarry; each Take gives Hunters +1/+1 this fight: 3–5 Takes × ~6 Hunters ≈ 36–60 SP mid-fight | Fight only | Tribe | Per trigger | None | **Multiplier** for Nip, Lutra, Russet, Ermeline, Glutton | No | 102; 2.65 vs 4.08 |
| Old Isegrim | T6 6/8 | Your units join attacks | +3 Attack per joiner per join: 4–6 joins, +12–18 damage a fight | Fight only | Joiners | Per trigger | None | Pack payoff | Offensive concentration | 736 (119 of 124 Hunter wins); 2.72 vs 5.73 |

### Oozes (16 in pool)

| Card | T, body | Condition | Payoff at R10 | Perm. | Breadth | Growth | Cap | Enabler | Conc. | Bot |
|---|---|---|---|---|---|---|---|---|---|---|
| Little Dollop | T1 1/2 | Buy a unit straight into it | That buy costs 1 less; Belly 1 holds a reserve | Economy | – | Per trigger | Belly 1 | A Belly fill for Soup; Figgy | No | 80; 4.84 vs 4.73 |
| Mrs Posset | T1 2/1 | Dies | 3 damage to the enemy across | One-shot | One enemy | One-shot | – | – | n/a (removal) | 86; 5.20 vs 4.77 |
| Wee Wobbly | T1 1/4 | Survives a hit | The unit inside comes out, or a 1/1 Drip: twice a fight | Fight only | Summons | Per trigger | Twice a fight | Elder (+1/+1), Syllabub, Clover | No | 697; 5.24 vs 4.02 |
| Dishwater Nell | T2 1/2 | Start of Turn; +1 gold if 2+ tiers up and touching an Ooze | Shop's lowest-tier unit becomes one of your tier | Economy, shop quality | – | Linear | Only the first Nell pays | Finds tier cards; Figgy | No | 12; 6.25 vs 4.71 |
| Moss Ooze | T2 2/4 | A spell gives your Ooze stats | What's inside gains the same | Same as the spell | Held units | Per trigger | Supper is a separate layer and doesn't count (5.2.9) | **Spell multiplier** (Pinch, Cordial, Bread, Stand Behind Me, Last Orders) | Partly | 185; 5.69 vs 4.59 |
| Stone Soup | T2 1/3 | You put a unit in any Belly | +1/+1 permanently, once a turn: up to 2 SP a turn | Permanent | Self | Linear a turn | Once a turn (binds only with 2+ fills a turn) | – | Yes (slow) | 217; 4.77 vs 4.91 |
| Aunt Aspic | T3 1/3 | End of Turn; the Oozes in front hold units | Held units of the 2 Oozes in front +1/+1: about 4 SP a turn | Permanent | Held units (2–4) | Linear a turn | None | Bigger reserves | No | 9 boards |
| Bubble and Squeak | T3 3/4 | Survives a hit | Splits half its stats into a copy, once a fight: no new stats | Fight only | Summons | One-shot a fight | Once a fight (golden twice) | Spreads | **No: splits** | 450; 5.08 vs 4.55 |
| The Sixpenny Pie | T3 1/4 | Dies and something comes out | +1 gold next turn; Belly 2 | Economy | – | Once a fight | Dies once | – | No | 113; 4.19 vs 4.92 |
| Figgy Duff | T4 3/5 | A bought unit inside, and one more copy bought | Golden with 2 copies instead of 3, then a Triple Reward | Card quality | One unit | Every other turn | Every other turn | **Triple engine** | Yes (via goldens) | 261; 4.95 vs 4.57 |
| Frumenty | T4 2/3 | A unit inside | Has that unit's text | Depends | Depends | Depends | Belly 1 | **Doubles any text**: a second Lollop, Mast, Isegrim | Depends | 34; 5.56 vs 4.69 |
| Mr Syllabub | T4 3/6 | A unit comes out of your Oozes | Its Start of Combat fires | Fight only | Depends | Per trigger | – | Multiplier for Start of Combat text (Brock, Sable, Committee, Lollop, Hasty) | No | 342; 5.62 vs 4.03 |
| Elder Ooze | T5 3/7 | Units come out of your Oozes | +1/+1 this fight to each: about 2–4 units | Fight only | Summons | Per trigger | None | Wobbly Drips | No | 172; 3.85 vs 5.09 |
| Hasty Pudding | T5 2/8 | Start of Combat; room in its Belly | Swallows the enemy across until Pudding dies, 3 of your units die, or its side is empty | Fight only | One enemy | One-shot | Belly 1 | **Answer to a big unit (scam)** | n/a | 125; 4.72 vs 4.84 |
| Cut-and-Come-Again | T6 4/4 | A non-Ooze inside | A base copy every other turn: about 1.5 gold a turn | Economy | – | Every other turn | Every other turn | Triples with Figgy | No | 23; 2.43 vs 4.94 |
| Granny Stir-Up | T6 4/8 | Start of Combat; touching Oozes | They go inside; she gains their total Attack this fight (×2 golden). 4 Oozes at 5 Attack: 24/8 | Fight only | Self | Flat a fight, scales with Ooze Attack | None | **Piles the whole board's Attack on one body** (but 8 Health, and the bodies leave the fight until she dies) | Yes (Attack only) | 169 (23 of 26 Ooze wins); 2.80 vs 5.80 |

### Neutral units (13 in pool; Mouse, Egg, Nymph are tokens)

| Card | T, body | Condition | Payoff | Perm. | Breadth | Growth | Cap | Notes | Conc. | Bot (boards; place with vs all without) |
|---|---|---|---|---|---|---|---|---|---|---|
| Lamp Moth | T1 1/2 | Played | Next Tier up −1 | Economy | – | One-shot | – | Tempo | No | 14; 6.43 vs 4.49 |
| Pennywort Snail | T1 1/3 | On board, up to 3 turns | +1 Health and +1 sell gold a turn | Permanent / economy | Self | Linear | 3 turns (binds R4–6) | Savings | No | 119; 5.78 |
| Pill Bug | T1 1/4 | Attacked | Units behind +1 Attack this fight, per hit | Fight only | 1–2 behind | Per trigger | – | Front wall | No | 149; 5.64 |
| Cricket Busker | T2 2/3 | Cast a spell | +1 gold, once a turn | Economy | – | Linear | Once a turn | Spell economy | No | 39; 5.77 |
| Earwig Mother | T2 1/2 | Dies | Two 1/1 Nymphs | Fight only | Summons | One-shot | – | Clover | No | 1 |
| Turnip Scarecrow | T2 0/4 | Enemy across | It skips its first attack | Fight only | One enemy | Flat | – | Answer to a big attacker | n/a | 17 |
| Ballooning Spider | T3 4/3 | In back row | Attacks the enemy back row | – | Self | Flat | – | Reaches back carries | n/a | 130; 6.12 |
| Money Spider | T3 1/3 | Start of Turn | +1 gold | Economy | – | Linear | – | – | No | 2 |
| Sexton Beetle | T3 2/4 | Friendly deaths | +1 gold next turn, twice a fight | Economy | – | Per fight | Twice a fight | – | No | 44; 5.68 |
| Charcoal Burner | T4 4/6 | End of Turn; gold above 5 | Burns up to 6 gold; units behind +1/+1 per 2 burned: up to +3/+3 on 2 units = 12 SP for 6 gold | Permanent | 1–2 units behind | Linear a turn | 6 gold a turn (golden 12) | **Gold to stats at 2 SP a gold, onto 1–2 units** | Partly | 88; 7.09 |
| Ichneumon Wasp | T4 2/3 | Damages an enemy | That enemy dies after its next attack | Fight only | One enemy | Per trigger | – | **Answer to a big unit (scam)** | n/a | 0 boards |
| Pipistrelle Echo | T5 3/6 | Spells aimed at it | Also hit both neighbours in its row (×3 a Pinch) | As the spell | Adjacent | Per trigger | Last Orders repeats give nothing | Spell multiplier | No | 14 |
| Whirligig Beetle | T6 6/8 | Start of Combat | Swaps the enemy rows; each moved enemy takes 2 (up to 14) | Fight only | Enemy board | Flat | – | Exposes back carries | n/a | 350; 3.00 vs 4.68 |

### Spells and heroes that give stats or economy (short)

- **Stats, concentrated:** Last Orders (T5, 1 gold: spend all gold, +1/+1 per 2 spent on one unit, uncapped: 1 SP a gold, the pool's only uncapped single-unit dump). Pinch of Dust (T1, 1 gold, +1/+1: 2 SP a gold). Elderflower Cordial (T1, 1 gold, +1/+2 or +2/+1). Cold Frame (T2, 2 gold, +3/+3 after 2 turns in slot).
- **Stats, spread:** Harvest Supper (T3, 3 gold: tribe +1/+1 now and later, once a turn, **capped at +3/+3**; about 14 SP a cast on a 7-unit tribe board, the best rate in the pool). Bread from the Back / Stand Behind Me (2 gold: 2 units +1/+1, or +2/+2 if sharing a tribe: 4–8 SP). Beltane Bonfire (T6, 2 gold: a row +1/+1 per 4 gold spent: about 2 SP a gold on 4 units). Rings: Spore Cloud (+2/+2), Boundary Stone (+3/+3), **Ring cap +4/+4** (8.5.4).
- **Economy:** Squirrel Away (2 gold → 2 Acorns: gold-neutral Beadle/Pym/Dozey triggers), Hungry Gap (+2 gold, one less shop unit), Rainy Day, A Leg Up, Market Day, Market Stall, Hiring Fair.
- **Heroes:** Dame Farthing (+1 gold per 4 carried, **up to 5 a turn**: the game's only interest, a real compounding loop, capped at a 20-gold bank). Brother Bracken (≤5 units: +1/+1 per tier up to +5/+5 at Start of Combat; rewards fewer, bigger units). Old Mother Mousewife (Mouse with stats = tier, twice a fight). Hob Mumblecrust (borrow 3), Jill (tier down for 2 gold), March Hare (double tier steps), Pipkin (2 more cards, 2 buys).

## Tribe summaries

### Counts

| | Stat payoffs | Concentrating (yes / partly) | Spreading | Permanent | Fight-only | Static aura | Economy/quality cards | Answers to big units |
|---|---|---|---|---|---|---|---|---|
| Hedgerow | 13 | 5 / 1 (Crumb, Pym, Dozey, Beadle, Treasurer / Urchin) | 7 (Burdock, Clover, Sorrel, Mallow, Hayward, Committee, Lollop) | **8** (Crumb, Burdock, Pym, Clover, Dozey, Beadle, Mallow, Hayward) | 4 (Sorrel, Urchin, Committee, Lollop) | 1 (Treasurer) | 3 (Partner, Mast, Sorrel/Burdock spill) | Sergeant, Urchin (Bristle) |
| Hunters | 13 | 3 / 3 (Nip, Lutra, Glutton / Wick, Sable, Lodger) + offensive concentration (Wolf, Isegrim, Pack, focus fire) | 6 (Young Brock, Agnes, Old Brock, Grizel, Laird, Isegrim) | **3** (Nip, Lutra, Grizel Attack only) | **10** | 0 | 4 (Russet, Toll-Bard, Ermeline, Lutra gold) | Toll-Bard (−2 Attack) |
| Oozes | 7 (+Frumenty) | 2 / 1 (Soup, Granny Attack / Moss) | 4 (Wobbly, Aspic, Bubble, Elder) | 2 (Soup, Aspic) + Moss as the spell | 4 | 0 | 5 (Dollop, Nell, Pie, Figgy, Cut-and-Come) | Posset, Hasty Pudding |

### Core condition, payoffs, enablers

- **Hedgerow.** Core condition: get Acorn items (Partner, Mast, Sorrel/Burdock Spill, Squirrel Away) and keep a full, gapless board. Payoffs: Pass onto one carry (Crumb, Pym, Beadle, Urchin), Dozey, Treasurer, Hayward; full-board auras (Committee, Lollop); Mallow. Enablers: Sorrel and Mast make Acorns; Partner; Clover grows summons. Most growth fires in the Recruit Phase and **does not need fight wins**.
- **Hunters.** Core condition: Takes (your quarry dies) and pack geometry (who stands beside whom). Payoffs: Nip/Lutra/Grizel permanent; Glutton, Laird, Isegrim, Sable, Lodger, Wick fight-only. Enablers: Young Brock and Old Brock (focus fire, Pounce), Agnes (grants Pack), Laird (quarry for all). Growth **needs winning trades**, so it is a positive feedback loop, but almost all of it resets after the fight.
- **Oozes.** Core condition: units inside Bellies, and survived hits. Payoffs: Soup, Aspic (held units), Elder (emerging units), Granny (Attack pile), Bubble (split). Enablers and multipliers dominate the tribe: Moss (spells), Frumenty (text), Syllabub (Start of Combat), Figgy and Cut-and-Come (copies and goldens), Nell (shop). Much of its power is reserve bodies that the bench does not count.

### Compounding and caps

- **Hedgerow:** item value compounds (3 Acorns 3 → Stash 5, +67%; Mast doubles with a Great Hoard). Pym and Hayward fire on Stash events, so holding then combining pays twice. Dozey's double is the only stat multiplier, and is capped (+8/+8, inside the +12/+12 ceiling). Pass turns several linear sources into one growing body. Caps that bind before R12: Dozey ceiling (R10–12), Partner's three times (R10), Beadle once a turn. Treasurer's +8/+8 does not bind in practice.
- **Hunters:** Laird multiplies Takes into stats, and Ermeline turns Takes into tier tempo; both are fight- or win-gated. Nothing compounds across turns except Nip/Lutra (+1/+1 a fight at most) and Grizel (+1 Attack per pack kill). Caps: one quarry each a fight (structural), Ermeline 3 Takes / 2 gold.
- **Oozes:** card quality compounds (Figgy goldens → Triple Rewards, Cut-and-Come copies, Nell). Stats do not compound. Caps: Figgy and Cut-and-Come every other turn, Soup once a turn, Belly sizes 1–2.
- **Neutral:** Charcoal Burner and Last Orders turn a bank into stats; Dame Farthing pays interest up to 5 a turn. With carry-over gold these are the only bank-to-stats loops.

### Board estimates (SP a unit, and the biggest unit)

Typical = bot p50 recruit stats per unit (`bot_stats.txt`), plus fight auras where the tier makes them likely. Highroll = everything lines up, by card math; checked against bot p99 per unit. Biggest unit = hand estimate.

| Tribe | R8 typical | R8 highroll | R12 typical | R12 highroll | R16 typical | R16 highroll |
|---|---|---|---|---|---|---|
| Hedgerow | 12/unit (bot 80 / 6.74); biggest Dozey after waking ~8/11 (19) | ~17/unit (bot p99 117); golden Pym + Partner + fed Dozey ~13/19 (32) | 21/unit recruit (bot 139 / 6.72), ~24 in the fight with Committee; biggest capped Dozey ~15/18 (33) | ~29/unit recruit (bot p99 196), ~38 in the fight with golden Lollop + Committee; biggest golden Dozey 28/34 + Supper ≈ 31/37 (68) | 27/unit (bot 175 / 6.54), ~31 in the fight with Lollop; biggest capped Dozey 17/20 or a Pass carry ~16/20 | ~40/unit (bot p99 259), ~50 in the fight; biggest uncapped Pass carry (2 golden Pyms + golden Beadle + Mast with a Great Hoard: ~+12/+12 a turn from R10) ~70/75 (145), rare |
| Hunters | 13/unit (bot 87 / 6.73); biggest Nip ~6/7 after 3 Takes | ~18/unit (bot p99 122); golden Nip ~12/14 (26) | 21/unit (bot 144 / 6.71); fight adds Isegrim +3 per join; biggest Nip ~10/11 (21) or a Grizel-grown leader | ~30/unit (bot p99 200); golden Laird + golden Glutton add ~+8/+8 a Hunter mid-fight; biggest recruit golden Nip ~22/24 (46), fight Glutton ~30/30 for one fight | 30/unit (bot 195 / 6.42); biggest Nip ~14/15 | ~45/unit (bot p99 289); biggest golden Nip ~35/37 (72) |
| Oozes | 11/unit on board (bot 72 / 6.73) plus 1–3 held bodies of ~7; biggest Soup ~6/8 | ~15/unit (bot p99 97); Soup 7/9 (fixture oozes_high) | 18/unit on board (bot 118 / 6.70); biggest Soup ~10/12 (22); Granny in a fight ~24/8 | ~24/unit (bot p99 159); golden Granny with 6 Oozes at ~6 Attack: ~80/16 for one fight; golden Soup ~22/26 | 23/unit (bot 146 / 6.32); Granny ~40/10 in a fight | ~30/unit (bot p99 190); golden Granny 100+/16 in a fight |

## Owner hypotheses, measured honestly

1. **"Hedgerow is fundamentally fine; its overperformance hints the other tribes are too weak."** Bot evidence: Hedgerow first rate 25% (95% CI 21–30%), mean place 3.75; Hunters 18%, Bog 13%, Oozes 9%, Birds 5% (`free_choice_plain.summary.csv`). **But Hedgerow does not have more stats**: R12 per-unit recruit p50 is 20.6 (Hedgerow) vs 21.4 (Hunters); R16 26.3 vs 30.0. **The edge runs through one tribe-agnostic card**: 70 of 71 Hedgerow wins had Squire Lollop; Hedgerow players with Lollop or Committee place 2.78 vs 5.99 without; Hunters with Lollop win 46%. The Hoard route the owner pointed at is barely played (larder p90 2 gold), and Dozey does not predict wins (Hedgerow players 4.07 with, 3.58 without; 16 of 71 wins). So: **incomplete**. Other tribes' late payoffs are weaker than Lollop (right), but Hedgerow's lead is mostly a generic full-board aura sitting in its tribe, not the tribe's structure.
2. **"Concentrating stats beats spreading them."** Right for plain trades. **Incomplete under our rules**: Pack, Brother Wolf, Isegrim and Pounce let spread units hit one target together without the joiners taking the counter-hit; quarry focus does the same. And the pool has answers to a big unit: Sergeant (3 damage a gold), Ichneumon Wasp, Hasty Pudding, Posset, Turnip Scarecrow, Whirligig, Toll-Bard, Bristle, Bitter.
3. **"Most effects buff many units by small amounts."** **Right** for Hunters and Oozes: their permanent single-unit growth is Nip, Lutra (+1/+1 a fight, at most one Take each) and Soup (+1/+1 a turn). Hedgerow is the exception (Pass, Dozey), and it is capped where it grows fastest (Dozey +12/+12).
4. **"Our numbers are too small."** **Right.** Winners' final boards are about 33–39 SP a unit at round 19–20 (`bot_stats.txt`); typical R16 boards are about 13/14 a unit. Every fast single-unit grower has a ceiling: Dozey +12/+12, Treasurer +8/+8, Supper +3/+3, Ring +4/+4, Bridge Toad +3/+3. A flat +2/+2 board aura (Lollop) decides most games because units are only ~13/14.
5. **"Watch the shape of the curve; rare highrolls are fine."** In bot play the curve is very narrow: total board stats p99/p50 = 1.43 at R12 (190 / 133) and 1.52 at R16 (265 / 174); max/p50 = 1.70 and 1.83. The owner accepts top 1% at 10×. We are far from snowballing; if anything the reward tail is too thin. Bots under-play greedy lines, so constructed sims are needed to test the real tail.

## Bot tables

See `bot_stats.txt` (per-round curves, place distributions, fight win share by round band, bank and larder) and `bot_cards.txt` (card presence and placement).

Fight win share by round band (wins / decided fights): Hedgerow 0.48 → 0.53 → 0.56 → 0.60 → 0.70 (R1–4, 5–8, 9–12, 13–16, 17+). Hunters 0.52 → 0.55 → 0.59 → 0.58 → 0.56. Oozes 0.53 → 0.45 → 0.47 → 0.55 → 0.51. Among tribes with enough seats, Hedgerow is the only one whose win share climbs every band (Fairies also climb, on 29 players).
