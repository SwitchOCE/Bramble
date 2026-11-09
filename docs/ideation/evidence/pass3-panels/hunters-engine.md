# Hunters, pass 3: the Feast (engine-first design)

One designer's entry for the Hunters panel (Track C, `docs/ideation/plan-scale-rework.md`). Angle: **engine first.** Paper design only: nothing here has been played or run in Godot. Board numbers come from a rough paper model in this folder, `hunters-engine-model.py` (`python3 -I hunters-engine-model.py s=0.1667 units=1 per_feast=1`). It scripts two lines against a lobby that follows the target shape. It fights nothing, so read its numbers as the size of the curve, not as measurements.

**In short:** every Hunter still picks its prey at Start of Combat; now, when the prey faints, the whole pack shares its lunch, so Hunters grow by a share of what they bring down.

## The pitch

Hunters keep Quarry and the Take. What changes is what a Take pays. Units with **Feast** permanently gain **a sixth of the quarry's stats** whenever any of your Hunters makes a Take. The Lodger, a fox who pays no rent, feasts on everyone's kills from tier 3. Old Brock, the badger squire, makes his sett a dining hall: at tier 4 he and every unit next to him feast. The Mountain Glutton cleaves through the front row and eats the lot. Grizel lets the wolves feast. Old Isegrim hunts the biggest enemy on the board, and when it falls, everyone eats big.

The engine is a product: **(Feast on your board) × (Takes a fight) × (size of the prey).** You assemble the first two. The lobby supplies the third, so the engine grows when the lobby grows, and the biggest meals are other players' carries.

*Similar to:* Hearthstone's Scavenging Hyena, turned outward (it grows when prey falls, not friends), and Galaxy's Hunt (you gain from a kill), but sized by the prey and shared by the whole pack. Nothing in Battlegrounds grows by a share of the enemy it killed.

*The fiction:* nobody dies in the woodland. The quarry faints, and the pack eats its packed lunch.

## Why this fixes what's wrong now

| Problem now (audit, `fundamentals.md`) | Pass 3 answer |
|---|---|
| 10 of 13 Hunter payoffs reset after each fight (Glutton, Laird, Isegrim, Lodger, Wick, Sable…) | Every main payoff is permanent: Feast, Nip, Wick, gold, Poach, tier discounts. The five fight-only cards are aimers, joiners and answers |
| Growth is +1/+1 steps, at most one Take per Hunter a fight; nothing compounds | A Take pays a **share** of the prey, so its size grows with the lobby (×1.5 a round), and assembly multiplies it |
| "Stats are not equal": Hunters spread small buffs | Feast stacks. The unit with the most Feast becomes the carry (Old Brock's sett), and it sits in the protected back row |
| Answers aim "across" and land by layout luck | Isegrim hunts the biggest enemy in any row and cuts its Health; Sable copies half her quarry's Attack; Old Lutra reaches the back row. Each answer that lands is also the biggest meal |
| Payoffs invisible in the shop | Feast is a printed number on the card; the scout shows how big each meal will be |
| Keyword load | Still four: Quarry (with Take), Pack, **Feast** (new), Pounce **retired** from the slice |

## The engine

### Rules (new or changed)

- **Feast** (new keyword). *Reminder:* "After your Hunters make a Take, permanently gains a sixth of the quarry's stats."
  - *Details:* the meal uses the quarry's Attack and Health when it was marked, each rounded up. **Feast 2** gains two sixths. Feast from several sources adds up. Only units on the board when the Take happens gain. Golden doubles the number (Feast → Feast 2).
  - The gain is permanent and lands at once, so a Feaster grows during the fight, and its added Health keeps it alive longer.
  - Feasters needn't be Hunters (Old Brock can feed a Hedgerow unit beside him), but only Hunters make Takes, so the engine never works without Hunters.
- **Take** is unchanged: it fires when a Hunter's quarry dies while that Hunter is on the board, whoever struck the blow. One Take per death.
- **Quarry** is unchanged, with one new form: "Quarry: the biggest enemy" (Isegrim) marks the living enemy with the highest Attack + Health at the bell, in either row (the shared "biggest enemy" selector).
- **Pounce leaves the slice.** The Lodger and Old Brock lose it. Its code stays for experiments.

### How it compounds

- Each fight, every Feast point on your board gains about **T × s × 0.8 U**: T is your Takes, s the share and U the lobby's average unit.
- U grows ×1.5 a round in the target shape, so each meal grows ×1.5 a round with no help.
- You raise the other two factors: Feast points (Lodger, Old Brock, Glutton, Grizel, Laird, Isegrim) and Takes (more Quarry Hunters, focus fire, Agnes, Cleave, the Laird).
- Growth tracks the prey, not your own size. A Hunter that is far ahead eats relatively smaller meals, so its lead settles at a ratio instead of running away. That ratio rises as you assemble more Feast and more Takes. This is the tribe's built-in brake on common snowballs.
- Its highrolls come from the prey: a golden Old Brock, or bringing down a 10× outlier carry.

### The rate parameter: **s = the Feast share**

- Default **a sixth, rounded up**. The sweep should try an eighth, a sixth, a fifth and a quarter.
- Rounding is the clock dial. Rounded up, every meal is at least +1/+1, and the engine comes online at round 8. Rounded down, small prey gives nothing and the engine starts about round 10.
- What the model gives:

| s (rounded up) | Engine line R9 / R12 / R15, against the typical board | Tempo line R9 / R12 / R15 |
|---|---|---|
| an eighth | 1.00× / 1.10× / 1.49× | 0.95× / 1.00× / 1.23× |
| **a sixth** | **1.10× / 1.37× / 1.93×** | **1.01× / 1.24× / 1.59×** |
| a fifth | 1.20× / 1.55× / 2.24× | 1.07× / 1.38× / 1.83× |
| a quarter | 1.42× / 1.94× / 2.82× | 1.24× / 1.72× / 2.31× |

"Typical" is the target shape's median board: 158, 531 and 1,793 at rounds 9, 12 and 15. A strong board is about 1.35× that, near Battlegrounds' September 2025 means (759 at turn 12). At a sixth, the engine line sits on the strong board at round 12 (729, about 52/52 a unit) and 1.4× it at round 15. That's my pick: an engine line should beat the field's strong board once it is assembled. If round 15 runs hot in the sweep, cut the Laird's Feast first, then Old Brock's reach (below), before lowering s.

### The turn it comes online

**Round 8:** the first fight with Old Brock in B2 and at least three Quarry Hunters in front.
- Before that, a meal is +1/+1 or +2/+2 and only the Lodger eats it.
- From round 8, six Feast points eat every Take.
- The engine line is behind at round 6 (0.88× typical), level at round 9 (1.10×) and clearly ahead from round 12.
- The tempo line runs on a different clock: ahead early on bodies and Pack, level in the middle, ahead late once Grizel feeds the wolves.

### The decision it creates, every turn: feed or fight

1. **Aim.** The scout shows your next opponent's board. Each Quarry Hunter goes across one of their units. Either:
   - across prey it will surely kill: a sure meal for every Feast point (invest); or
   - across what you must beat to win this fight, often their biggest unit (tempo). If it falls, that's the biggest meal of the game.
2. **Buy.** At round 10, at a sixth:
   - a new Quarry Hunter adds about 0.6 Takes × 6 Feast × a 6-stat meal ≈ **22 stats a fight**, rising ×1.5 a round;
   - a new Feaster adds 3 Takes × 6 ≈ **18 a fight** plus its body;
   - the best tempo body adds about 10 stats now and never grows.
   - So the engine buy wins after two fights. The tempo buy wins only if this fight decides your Health.
   - Before round 8 the meals are tiny and the tempo buy wins, which is why the engine comes online there.
3. **The rule of thumb.** The engine is Feast × Takes. If you have more Feast points than Quarry Hunters, buy a hunter; otherwise buy a mouth.

## The 16 cards

Tier spread kept at 3/3/3/3/2/2. Every creature, name and portrait is kept. Grey Agnes and Old Isegrim still have no portraits (`content/portraits_pending.json`).

**How to read the payoffs.** Numbers are at a sixth, rounded up, for a typical board in the target shape.
- One Feast point eats about **4** a Take at round 9, **11** at round 12 and **36** at round 15.
- Every Take feeds the whole board one meal per Feast point: about **24** stats at round 9, **77** at round 12 and **290** at round 15.
- One Feast point held from round 8 adds about **20**, **104** and **450** stats by rounds 9, 12 and 15.

### Tier 1

**Little Nip** · *Fox Cub, Errand-Runner* · T1 · 2/3
- **Text:** Quarry. Take: gain +1/+1 permanently.
- **Golden (4/6):** Quarry. Take: gain +2/+2 permanently.
- **Condition:** its quarry (the enemy across at the bell) dies while Nip stands.
- **Payoff:** +1/+1 a Take, about 0.6 a fight: about 7/8 by R9, 9/10 by R12, 11/12 by R15. In F2 or F3 next to Old Brock he feasts too: about 60/60 by R12.
- **Permanence:** permanent.
- **Enabler:** fuel. Each of his Takes is a meal for every Feaster (Lodger, Old Brock's sett, Glutton, Grizel's wolves). A Taker for Ermeline.
- **Concentrates:** slowly, on himself. Unchanged from pass 2.

**Young Brock** · *Badger, Heir to the Sett* · T1 · 2/3
- **Text:** Quarry. Units beside this share its quarry and have +1 Attack.
- **Golden (4/6):** Quarry. Units beside this share its quarry and have +2 Attack.
- **Details:** a unit with its own quarry keeps it, without the Attack.
- **Condition:** units beside him, and an enemy across.
- **Payoff:** three units on one target make a Take likely on something bigger than any of them. Worth about one board meal a fight when it converts: about 24 stats at R9, 77 at R12 and 290 at R15. The +1 Attack lasts the fight.
- **Permanence:** fight only (an aimer).
- **Enabler:** Takes for every Feaster; aims Wick, wolves, Lodgers and other tribes' units. Only Hunters make Takes, so a lent quarry on a non-Hunter still pays through Brock's own Take.
- **Concentrates:** damage, not stats. *Changed:* he now has Quarry himself.

**Wick** · *Least Weasel, Runner for the Pack* · T1 · 2/3
- **Text:** Pack. After this joins a kill: gain +1/+1 permanently.
- **Golden (4/6):** Pack. After this joins a kill: gain +2/+2 permanently.
- **Details:** a kill counts when the attack it joined kills the target.
- **Condition:** a unit beside him attacks, and the target dies.
- **Payoff:** about +1.5/+1.5 a fight, so about 9/10 by R9. With Grizel's Feast from R8: about 18/18 by R9, 71/71 by R12 and 290/290 by R15.
- **Permanence:** permanent.
- **Enabler:** a joiner for any Quarry leader (Sable, Young Brock, Agnes), so their quarry dies; a Pack body for Grizel.
- **Concentrates:** slowly, on himself. *Changed:* his growth was fight-only.

### Tier 2

**Sable** · *Stoat, of the Ermine Court, in Summer Brown* · T2 · 2/3
- **Text:** Quarry. Start of Combat: gain half its quarry's Attack.
- **Golden (4/6):** Quarry. Start of Combat: gain its quarry's Attack.
- **Condition:** she has a quarry.
- **Payoff:** a hit that scales with the enemy. Against a typical front unit she fights at about 6/3 at R9, 17/3 at R12 and 50/3 at R15, and twice that across a carry. In F2 or F3 next to Old Brock she feasts too: about 54/55 by R12 and 228/228 by R15.
- **Permanence:** fight only (an answer).
- **Enabler:** the "aim big" piece: a Pack leader whose joiners finish what she chunks. Bigger quarries are bigger meals.
- **Concentrates:** damage onto one target. *Changed:* was a flat +3 when the quarry had more Attack.

**The Toll-Bard** · *Pine Marten, Keeper of the Lane Songs* · T2 · 2/4
- **Text:** Quarry. After its quarry attacks: get 1 gold next turn. Once a fight.
- **Golden (4/8):** Quarry. After its quarry attacks: get 2 gold next turn. Once a fight.
- **Condition:** his quarry lives long enough to swing, which happens in nearly every fight.
- **Payoff:** about 0.9 gold a turn: about 8 gold by R12 and 11 by R15. If the quarry then dies, it is a Take as usual.
- **Permanence:** economy.
- **Enabler:** pays for refreshes that find Old Brock and Lodger copies. The tribe's one income that doesn't need winning trades.
- **Concentrates:** no. *Changed:* the 1-Attack toll is gone; once a fight stays as a loop guard on gold.

**Mistress Russet** · *Fox, Poacher, Licensed After a Fashion* · T2 · 3/3
- **Text:** Quarry. Take: your next shop has a copy of the quarry, 1 gold cheaper.
- **Golden (6/6):** Quarry. Take: your next shop has a copy of the quarry, 2 gold cheaper.
- **Details:** only cards of your tier or lower. The copy comes from the shared pool.
- **Condition:** a Take on a quarry at or below your tier.
- **Payoff:** about 0.5 discounted cards a turn, taken out of the opponent's triples. In F3 next to Old Brock she feasts: about 55/55 by R12 and 228/228 by R15.
- **Permanence:** card economy.
- **Enabler:** triples (a golden Lodger or Old Brock is the tribe's best highroll), and denial against carry tribes.
- **Concentrates:** no. *Changed:* wording only.

### Tier 3

**The Lodger** · *Fox, Lodger in a Badger Sett, Pays No Rent* · T3 · 3/4
- **Text:** Feast.
- **Golden (6/8):** Feast 2.
- **Condition:** your Hunters make Takes while he is on the board.
- **Payoff:** on his own, about 15/16 by R9, 58/59 by R12 and 231/233 by R15. Beside Old Brock in B1 (Feast 2 from R8): about 25/25, 103/103 and 438/438. He is the engine line's carry, about 28% of the board.
- **Permanence:** permanent and visible.
- **Enabler:** none. He is the payoff every Taker feeds.
- **Concentrates:** yes. *Changed:* was Pounce at 4/4. He is 3/4 now because the engine's seed should cost tempo when you buy it.

**Old Lutra** · *Otter, Runner of the Reed Channels* · T3 · 3/4
- **Text:** Quarry, wherever it stands. Take: get 1 gold next turn.
- **Golden (6/8):** Quarry, wherever it stands. Take: get 2 gold next turn.
- **Condition:** his quarry, often a protected back-row unit, dies while he stands.
- **Payoff:** about 0.4 Takes and 0.4 gold a fight. His Takes land on their back row, where engines and carries sit, so each one is a meal about twice the usual: about 48 board stats at R9, 154 at R12 and 576 at R15. In B3 next to Old Brock he feasts: about 13/13 by R9.
- **Permanence:** economy, plus the meal.
- **Enabler:** reaches the one slot their front row protects. Big meals for every Feaster.
- **Concentrates:** no. *Changed:* the +1/+1 is gone, and the gold now comes from either row.

**Brother Wolf** · *Wolf, Under a Vow* · T3 · 3/4
- **Text:** Pack. Units beside this attack first; this joins each once a cycle.
- **Golden (6/8):** the same text.
- **Condition:** two leaders beside him.
- **Payoff:** his Attack lands twice a cycle and he takes no hit back while his leaders live. With Feast from Grizel or Old Brock: about 13/13 by R9, 63/64 by R12 and 282/282 by R15. He is the tribe's stat-holding joiner.
- **Permanence:** fight only. His growth comes from Feast.
- **Enabler:** Takes for the leaders' quarries; the Pack line's safest Feaster.
- **Concentrates:** damage onto two targets. Unchanged.

### Tier 4

**Old Brock** · *Badger, Squire of the Sett* · T4 · 2/6
- **Text:** Feast. Units next to this have Feast.
- **Golden (4/12):** Feast 2. Units next to this have Feast 2.
- **Details:** the grant ends if Old Brock dies. Meals already eaten stay.
- **Condition:** units next to him, and Takes. In B2 he has four neighbours: F2, F3, B1 and B3.
- **Payoff:** five Feast points from one card. The board gains about 60 stats a fight at R9, 190 at R12 and 810 at R15. Brock himself is about 12/16 by R9, 54/58 by R12 and 227/231 by R15.
- **Permanence:** permanent and visible.
- **Enabler:** turns his neighbours into Feasters: the Lodger's second Feast, F2 and F3 Takers that keep pace, and the Glutton's second Feast.
- **Concentrates:** he spreads Feast five ways, but it stacks on the carry next to him.
- **The engine's heart.** It must be protected: B2 is safe while the front stands. *Changed:* was Pounce, reach and +1 Attack for his neighbours.

**Madame Ermeline** · *Stoat, Court Dressmaker* · T4 · 3/6
- **Text:** After each fight: your next Tier up costs 1 less per Take. At tier 6: gold instead.
- **Golden (6/12):** After each fight: your next Tier up costs 2 less per Take. At tier 6: gold instead.
- **Details:** counts up to 3 Takes. At tier 6, up to 2 gold (golden 3).
- **Condition:** Takes, used next turn or lost.
- **Payoff:** about 3 gold off your next Tier up, then about 2 gold a turn at tier 6.
- **Permanence:** economy (tempo).
- **Enabler:** the climb to the Glutton (T5) and the Laird and Isegrim (T6). The tempo half of "feed or fight".
- **Concentrates:** no. *Changed:* wording only. The caps stay as loop guards on tier and gold.

**Grey Agnes** · *She-wolf, Keeper of the Den* · T4 · 2/7
- **Text:** Quarry. Units behind this have Pack and join its attacks.
- **Golden (4/14):** Quarry. Units behind and beside this have Pack and join its attacks.
- **Details:** they join once a cycle, as Pack does. Only Agnes takes the hit back. The grant ends if she dies.
- **Condition:** units behind her. In F2 those are B1 and B2; in F3, B2 and B3.
- **Payoff:** the back row strikes in the first cycle without taking damage. At R12, with a 103-Attack Lodger and a 54-Attack Old Brock behind her, she hits her quarry for about 160 every cycle. That's a near-sure Take on their best front unit, and the carry holds its stats until the front falls.
- **Permanence:** fight only. In F2 next to Old Brock she feasts too.
- **Enabler:** a way for the carry to hold its stats; Takes; Pack bodies for Grizel.
- **Concentrates:** damage, onto her quarry. *Changed:* was "the unit after this in the row has Pack and +1 Attack". Her epithet changes so it no longer repeats Grizel's.

### Tier 5

**The Mountain Glutton** · *Wolverine, Saga Mercenary, Here for the Food* · T5 · 4/6
- **Text:** Feast. Cleave.
- **Golden (8/12):** Feast 2. Cleave.
- **Condition:** Takes, and front-row enemies to cleave.
- **Payoff:** on his own, about 38/38 by R12 and 210/212 by R15. In B3 next to Old Brock (Feast 2): about 68/68 by R12 and 403/403 by R15. Every swing hits three front enemies, so the quarries of your living Takers fall faster and more Takes land.
- **Permanence:** permanent.
- **Enabler:** raises Takes; turns overkill into kills.
- **Concentrates:** yes. He is the second carry, and the one that holds its stats (Cleave, back row, mid-fight growth). *Changed:* was +2/+2 a Take, fight only.

**Grizel** · *Wolf, Mother of the Pack* · T5 · 5/6
- **Text:** Pack. Your units with Pack have Feast.
- **Golden (10/12):** Pack. Your units with Pack have Feast 2.
- **Condition:** Pack units (Wick, Brother Wolf, Grizel herself, Agnes's back row), and Takes by your Quarry leaders.
- **Payoff:** four or five Feast points: the board gains about 50 stats a fight at R9, 170 at R12 and 730 at R15. Grizel is about 15/15 by R9, 65/66 by R12 and 284/284 by R15.
- **Permanence:** permanent.
- **Enabler:** the Pack line's version of Old Brock. Every joiner grows, and joiners take no hit back, so the pack holds its stats.
- **Concentrates:** no: an even pack. *Changed:* was +1 Attack on pack kills.

### Tier 6

**The Laird of the Sett** · *Badger, Keeper of the Old Rights* · T6 · 4/8
- **Text:** Feast. All your units have Quarry.
- **Golden (8/16):** Feast 2. All your units have Quarry.
- **Details:** a unit that already has a quarry keeps it.
- **Condition:** a full board, and a scout to aim from.
- **Payoff:**
  - About one more Take a fight: your back-row Feasters now hunt their back row once it opens.
  - That's one more meal for every Feast point: about +100 stats a fight at R13 and +290 at R15.
  - His own Feast makes him about 179/179 by R15.
  - Every lane becomes a matchup to solve from the scout.
- **Permanence:** permanent (Feast) and fight (Quarry).
- **Enabler:** the answer when your mouths outnumber your hunters: every mouth becomes a hunter.
- **Concentrates:** no. *Changed:* the combat +1/+1 per Take becomes Feast. His body is 4/8 (was 3/5).

**Old Isegrim** · *Wolf, Constable of the Wold* · T6 · 6/8
- **Text:** Feast. Quarry: the biggest enemy, wherever it stands. Start of Combat: it loses a quarter of its Health.
- **Golden (12/16):** Feast 2. Quarry: the biggest enemy, wherever it stands. Start of Combat: it loses half its Health.
- **Details:** the biggest enemy is the one with the most Attack plus Health at the bell. The meal uses its stats from before the cut.
- **Condition:** their carry falls while Isegrim stands, or as he falls. Pack units beside him join his attacks on it.
- **Payoff:**
  - When it falls (I guess about half the fights from R12), every Feast point eats a sixth of their carry.
  - That's about +200 board stats at R12 and +800 at R15, in one Take.
  - He fights it from the first cycle, wherever it hides.
  - He is about 48/48 by R12 and 266/267 by R15.
- **Permanence:** the Health cut lasts the fight; the meal and his Feast are permanent.
- **Enabler:** the tribe's main answer to other carries, and its biggest meal.
- **Concentrates:** damage onto their biggest unit.
- **The pool's back-row exception.** He is one of the two or three cards the default allows to reach any row (`fundamentals.md` question 2). *Changed:* was +3 Attack for joiners.

### Wording check

- Card text: median 9.5 words, longest 17 (Isegrim). That's inside the guide's median 11, p90 17 and max 22.
- New reminder: Feast, 13 words. Pounce's reminder leaves the slice.
- Every golden doubles a number or a share, except Agnes's (her grant reaches further) and Brother Wolf's (unchanged).

## The tribe

### Engine and rate

- **The Feast:** Takes × Feast × prey.
- **Rate parameter:** s, the Feast share. Default a sixth, rounded up; sweep an eighth to a quarter.
- **Second dials, if the sweep needs them:**
  - Old Brock's reach: "next to" (four units) or "beside" (two).
  - The Laird's own Feast.
  - Rounding: up for an earlier clock, down for a later one.

### Carry route: the Sett

- Old Brock in B2. The Lodger in B1 (Feast 2), later the Glutton in B3 (Feast 2, Cleave). Sturdy Quarry Hunters in F2 and F3 feast and keep pace.
- The carry is the unit with the most Feast. At round 12 the Lodger is about 206 (28% of the board), with the Glutton second at about 136.
- **It holds its stats four ways:**
  - the back row is safe while the front stands;
  - it grows during the fight as Takes land;
  - Agnes lets it strike from behind without taking a hit back;
  - the Glutton's Cleave turns overkill into kills.
- **Highroll:** golden Old Brock or a golden Lodger.

### Non-carry route: the Pack

- Quarry leaders (Sable, Young Brock, Agnes, Isegrim) with Pack joiners beside them (Wick, Brother Wolf, Grizel).
- Grizel gives every Pack unit Feast. The board ends up even: the biggest unit is 20–25% of it.
- It wins with joins: the joiners take no hit back, and several separate hits beat Shield and Shell.
- Isegrim's hunt brings down their carry.
- It climbs faster and leads early.

### Answers to other tribes' carries

- **Old Isegrim:** hunts the biggest enemy in any row, cuts its Health by a quarter, and his Pack neighbours join his swings. When it falls, everyone feasts on it.
- **Sable:** gains half her quarry's Attack, so her hit scales with whatever she faces. Put her across their carry with wolves beside her.
- **Old Lutra:** reaches one chosen back-row slot from the first cycle.
- **Focus fire:** Young Brock, Agnes and Pack put several separate hits on one target. Shield stops only the first and Shell caps each hit, so these break both.
- **Golden Laird:** every lane gets a hunter, so a carry has nowhere to stand unmarked.
- **The incentive:** Hunters are the tribe that wants to kill carries, because a carry is the biggest meal.

### Weak points

- **No Take, no meal.**
  - Walls across your Takers: high Health, Hunker, Bristle on a Pack leader, a Shield that eats the killing hit.
  - Empty lanes: Birds away, Eggs, gaps.
  - Swallows: Hasty Pudding takes a quarry, so nobody gets the Take.
  - Side swaps (Changeling).
- **Small prey.** Wide token boards feed little, and units summoned during the fight are never quarries.
- **A readable, stationary sett.**
  - Whirligig Beetle swaps rows and pulls Old Brock into the front.
  - Back-row attackers and "biggest enemy" answers find the Lodger or the Glutton.
  - Killing Old Brock ends his grants for the fight.
- **Losing streaks.** Fewer Takes means slower growth. Only the Toll-Bard pays when you're behind.
- **The early clock.** Before round 8 a meal is a point or two, and the engine line is about 0.88× the typical board at round 6.
- **It eats the lobby.** In a flat lobby (today's pool) the engine is far stronger than its peers. In a steep one it is only as good as its Takes.

### Two highroll moments a player will remember

1. **The sett goes gold (rounds 9–10).** Russet poaches your third Old Brock.
   - Golden, he gives Feast 2 to himself and his four neighbours, so the golden Lodger in B1 has Feast 4.
   - Next fight, every Take feeds the Lodger two thirds of the quarry, and the whole back row with it.
   - The Lodger goes from about 40 to about 97 in one fight. The fight log scrolls with Feast lines.
2. **Isegrim brings down the carry (round 13).** Their Hedgerow carry, 260/280 and hidden in B2, is the biggest enemy.
   - Isegrim marks it from F1 and cuts its Health to 210. Brother Wolf and Grizel join his first swing, and it faints in cycle one.
   - That one Take feeds every Feast point 44/47. With eight on the board, that's about +730 stats mid-fight.
   - The Glutton then cleaves through the rest of their front row.

## Boards at rounds 6, 9, 12 and 15

These come from the paper model at a sixth, rounded up. Units are listed as Attack + Health. Each line's typical schedule is set out under Harness lines below.

**Engine line (the Sett).** T3 R5, T4 R7, T5 R10, T6 R12.

| Round | Board (biggest first) | Total | Against the typical board |
|---|---|---|---|
| 6 | Lodger 11, Nip 9, Lutra 7, Russet 6, Toll-Bard 6, Sable 5 (6 units) | 46 | 0.88× (behind at once) |
| 9 | Lodger 50, Old Brock 28, Lutra 26, Russet 26, Sable 24, Nip 15, Toll-Bard 6 | 174 | 1.10× |
| 12 | Lodger 206, Glutton 136, Old Brock 112, Russet 110, Sable 109, Lutra 44, Laird 12 (just bought) | 729 (about 52/52 a unit) | 1.37× (about the strong board) |
| 15 | Lodger 876, Glutton 806, Old Brock 458, Russet 456, Sable 456, Laird 358, Lutra 44 | 3,456 (about 247/247 a unit) | 1.93× (1.4× the strong board) |

Layout at round 12:
```
F1 Old Lutra        F2 Sable           F3 Mistress Russet     F4 Little Nip
       B1 The Lodger       B2 Old Brock          B3 The Mountain Glutton
```
At round 13 the Laird replaces Nip in F1, or Agnes goes to F2 when the scout shows a wall.

**Tempo line (the Pack).** T3 R4, T4 R6, T5 R8, T6 R11.

| Round | Board | Total | Against the typical board |
|---|---|---|---|
| 6 | Wick 12, Lodger, Agnes, Brother Wolf, Nip, Sable, Young Brock | 60 | 1.16× |
| 9 | Wick 36, Lodger 36, Grizel 30, Brother Wolf 26, Nip 15, Agnes 9, Lutra 7 | 160 | 1.01× |
| 12 | Wick 142, Lodger 136, Grizel 131, Brother Wolf 127, Isegrim 96, Nip 18, Lutra 7 | 657 | 1.24× |
| 15 | Wick 582, Lodger 572, Grizel 568, Brother Wolf 564, Isegrim 533, Nip 22, Lutra 7 | 2,848 | 1.59× |

On real tempo boards the small Nip and Lutra slots would hold more Pack units behind Agnes, so the late board should be more even than this.

**Against the target.** Both lines are level with today's game to round 7. After that:
- From round 8 the engine line grows about ×1.6 a round and the tempo line about ×1.55. That's slightly steeper than the lobby's ×1.5, because late pieces add Feast and Takes.
- The biggest unit is 25–29% of the board on the engine line and 20–25% on the tempo line. Battlegrounds is about a third.
- The top 1%: a golden Old Brock, a golden Glutton, the Laird and Isegrim by round 12 make about 16 Feast points and five Takes a fight. That reaches about three to five times the typical board by round 15, inside the owner's 10×.

**Model limits.**
- It doesn't fight, so Takes are a schedule (2 at R6, 3 at R9, 3.5 at R12, 4.5 at R15 with the Laird), not an outcome.
- Prey is assumed to be typical front units.
- Gold, refreshes and the Health race are ignored.
- The harness should replace every one of these assumptions.

## Harness lines

Card ids are the `content/units/*.json` ids.

**Aim rule, both lines.** After scouting, place each Quarry Hunter across the enemy that maximises P(kill) × that enemy's stats. Then:
- the Toll-Bard goes across a sturdy enemy that will swing and live;
- Mistress Russet goes across the card you most want a copy of;
- Old Isegrim goes in F1.

### Line 1: `hunters_tempo` (the Pack)

- **Engine flag:** off. **Committed tribe:** Hunters.
- **Buy and keep, best first:** `grizel`, `old_isegrim`, `brother_wolf`, `wick`, `grey_agnes`, `sable`, `young_brock`, `lodger`, `old_brock`, `little_nip`, `laird_of_sett`, `mountain_glutton`, `mistress_russet`, `madame_ermeline`, `old_lutra`, `toll_bard`.
- **Sell first when full:** `toll_bard`, `old_lutra`, `mistress_russet`, `little_nip`, then the smallest unit without Pack.
- **Climb:** T2 R2, T3 R4, T4 R6, T5 R8, T6 R10–11 (Battlegrounds' standard curve).
- **Save gold:** spend out every turn, except to keep what the next scheduled Tier up needs. Refresh at most twice a turn, more only to find `grizel` at T5 or `old_isegrim` at T6.
- **Placement:**
  - Quarry leaders (`sable`, `young_brock`, `old_isegrim`) in F1 and F3.
  - Pack units right after them in the row (F2, F4).
  - `brother_wolf` between two leaders.
  - `grey_agnes` in F2 with Pack units in B1 and B2.

### Line 2: `hunters_sett` (engine and carry)

- **Engine flag:** on.
- **Buy and keep, best first:** `old_brock`, `lodger`, `mountain_glutton`, `laird_of_sett`, `grey_agnes`, `old_isegrim`, `sable`, `mistress_russet`, `little_nip`, `old_lutra`, `young_brock`, `toll_bard`, `madame_ermeline`, `grizel`, `brother_wolf`, `wick`.
- **Mouths and hunters:** among offers of similar rank, buy a Quarry Hunter if the board's Feast points exceed its Quarry Hunters; otherwise buy a Feaster. Always buy a second `lodger` or `old_brock` copy toward a triple.
- **Rounds 1–4:** any Quarry Hunters (`little_nip`, `mistress_russet`, `sable`, `toll_bard`, `young_brock`).
- **Climb:** T2 R2, T3 R5, T4 R7, then stay at T4 through R8–R9 to finish the sett. Then T5 R10 and T6 R12.
- **Save gold:**
  - R1–R5: spend out.
  - R6: end with 2 or more gold, so R7 pays both the T4 climb and `old_brock`.
  - R7–R9: refresh up to three times a turn for `old_brock`, `lodger` copies and Quarry Hunters.
  - R9: end with enough for T5 on R10.
  - R10–R11: once `mountain_glutton` is placed, bank toward T6 on R12. Until then, refresh for it first.
- **Placement:**
  - `old_brock` in B2.
  - The unit with the most Feast in B1; the second Feaster in B3.
  - The sturdiest Quarry Hunters in F2 and F3 (they gain Feast).
  - `grey_agnes` in F2 when the carry is in B1.
  - `little_nip` and `toll_bard` in F1 and F4.
  - `old_lutra` in B3 until the Glutton arrives, then in front.

## Risks, loop guards and what the sweep should test

- **Riskiest card: Old Brock.**
  - Five Feast points at tier 4 is the whole engine. If the sett runs hot, change "next to" to "beside": only B1 and B3, two protected Feasters.
  - Test Brock in B2 against fields with and without Whirligig Beetle or back-row reach.
- **Second: Grey Agnes.**
  - Back-row carries that strike without taking hits may be untouchable until the front dies.
  - If so, let only the unit directly behind her join, or make the carry take the hit back on its join.
- **Third: Old Isegrim.**
  - An answer that deletes carries. Count upsets from his hunt separately (plan Step 2).
  - Dial: the Health cut (a quarter, then none).
- **The Laird.** He adds both Takes and Feast late. Cut his own Feast first if round 15 is hot.
- **The flat-lobby trap.** Feast is sized by the prey. On today's flat pool, Hunters will look dominant relative to their peers. Sweep them against a field at the target shape.
- **Snowball check.**
  - Growth follows the lobby, not the Hunter's own size, so a lead settles at a ratio.
  - Report the share of R12 Hunter boards at 2× the field median or more.
  - Report Takes a fight in the field. Below about 2, the engine stalls.
- **Ghosts.** Ghosts lose 93% of fights, so they feed Hunters well. Count ghost meals separately.
- **Loop guards.** None are new. Takes are bounded at one per quarry, and a quarry is marked once a fight. The Toll-Bard's once a fight and Ermeline's 3 Takes and 2 gold stay, as gold and tempo loops. There are no size caps.

## Engine support needed

| Need | For | What |
|---|---|---|
| `feast` mechanic (n) | Lodger, Old Brock, Glutton, Laird, Isegrim | A side-wide `on_take` listener. Every living unit with Feast n gains, permanently, the share × n of the quarry's marked Attack and Health, each rounded (config `feast_share` as numerator/denominator, `feast_round` up or down). It applies in the fight at once and goes back to the recruit board (Grizel's permanent-buff path). |
| Marked stats | Feast meals | `quarry_marked` records the quarry's Attack and Health at the bell. |
| Keyword grants that add up | Old Brock (`neighbours`), Grizel (`has_keyword: Pack`, including granted Pack), golden values | A live `grant_keyword` aura that adds to n and ends when its source dies. |
| Cross-row joining | Grey Agnes | A joint attack whose joiner set includes the units behind the leader, using Pack's once-a-cycle flag and counter-hit rule. Those units have Pack while she lives. |
| Biggest-enemy quarry with reach | Old Isegrim | A quarry selector `biggest_enemy` at the bell (the shared selector), with `reach`. Then `stat_fraction` reduce Health 25% on its own quarry at Start of Combat. |
| A fraction of another unit's stat | Sable | `stat_fraction` gain with `source: quarry`. Today it reads only the target's own stats. |
| `after_join_kill` | Wick | Fires when an attack this unit joined kills its target. Permanent buff. |
| Own Quarry plus a lend | Young Brock | Existing `quarry` and `lend_quarry` (adjacent). |
| Pounce out of the slice | Lodger, Old Brock | Data only. |
| UI | All | Feast n on the card face. On the scout, each paw print shows its meal ("+5/+6 each") and the total Feast on your board. Old Brock's grant lights his four slots. The fight log shows "Feast +5/+6 ×7". |
| Bots and harness | Lines | The aim rule (P(kill) × stats), the placement rules and the mouths-and-hunters buy rule above. Telemetry: Takes a fight, Feast points, meal size, and the Hunter board against the field median. |

No Godot was run for this design.

## What changed from pass 2

- **New:** Feast. **Retired from the slice:** Pounce.
- **Rewritten:**
  - the Lodger (Pounce 4/4 → Feast 3/4);
  - Old Brock (Pounce and reach lend 2/5 → the Feast sett 2/6);
  - the Mountain Glutton (fight-only +2/+2 a Take → Feast and Cleave 4/6);
  - Grizel (+1 Attack on pack kills → Pack units feast);
  - the Laird (fight-only +1/+1 a Take → Feast, 4/8);
  - Old Isegrim (+3 for joiners → hunts the biggest enemy, Feast);
  - Grey Agnes (Pack to the next unit → the back row joins her, 2/7).
- **Tuned:**
  - Sable (flat +3 → half her quarry's Attack);
  - Young Brock (gains Quarry);
  - Wick (fight-only Attack → permanent +1/+1 per joined kill);
  - the Toll-Bard (no Attack toll; 1 gold once a fight);
  - Old Lutra (gold from either row, no +1/+1).
- **Unchanged:** Little Nip, Brother Wolf, Mistress Russet and Madame Ermeline. Russet's and Ermeline's wording is shortened.
- **Payoffs that reset after each fight:** 10 of 13 before. Now the five fight-only cards are all aimers, joiners or answers, and every growth payoff lasts.
