# Hunters, pass 3: "You are what you hunt" (identity and delight)

9 Nov 2026. One designer of the Track C Hunters panel (`docs/ideation/plan-scale-rework.md`, step 1), on the identity-and-delight angle. Paper design: no Godot runs. The numbers come from a growth calculator, not a combat sim: `build/orchestrator/pass3/hunters-wild-model.py`. Run `python3 -I hunters-wild-model.py`, `… sweep` or `… rolls`. No price list was used.

## The pitch in three lines

1. **A Hunter grows by what it kills.** When its quarry falls, it takes half the quarry's stats, permanently. A fox cub that brings down a 300/340 carry walks home a 150/170 fox.
2. **The bigger the prey, the bigger the trophy.** Aim at something you can surely kill, or at something worth killing. That choice comes up every turn, and the scout shows its price: "Take: +12/+15".
3. **The lobby's runaway is the Hunters' best meal.** The pack aims at carries and gets paid most for killing them. A big lead in the lobby feeds the Hunters.

**What Battlegrounds doesn't have:** a tribe whose power is a share of the enemy units it chose and killed. Its scale comes from the lobby, not from its own loops. Battlegrounds' scale comes from "this game" and doubler text that compounds on your own board. The closest things in other games:
- Hearthstone's devour cards (Void Terror eats friendly neighbours);
- Galaxy's Hunt, which pays the unit that struck the blow;
- Battlegrounds' Quilboar Blood Gems, which are like Ermeline's Pelts below.

None of these takes its stats from a target the player marked before the fight.

## Why this fixes what the audit found

| The audit found (`fundamentals.md`, the Hunters card audit) | Pass 3 |
|---|---|
| 10 of 13 Hunter payoffs reset after each fight | 10 of 16 cards pay permanent stats. The other six aim, join or multiply those payoffs. No main payoff resets. |
| Growth is flat: +1/+1 a Take, +1 Attack a pack kill | Every share is a fraction of an enemy unit. When the field compounds about ×1.5 a round, Hunter growth does too. |
| No concentration; the biggest Hunter is a 10/11 Nip at R12 | Three ways to concentrate: the Glutton takes half of every Take, Ermeline's Pelts go where you play them, and Young Brock inherits any Hunter sold beside him. Pack joiners and leaders hold their stats. |
| Answers aim "across", so they land by layout luck | Sable trades with any front unit across from her. Old Isegrim's gang hunts the biggest enemy in either row. Killing a carry is now the biggest reward in the tribe. |
| Caps and limiters | None. The only limits are structural: one quarry each a fight, one Take per death, one pounce a cycle. |

**Answers become power.** No other tribe gets bigger by answering a carry, so the variance budget and the engine pull the same way.

---

## Tribe rules (pass 3)

**Quarry** (kept). Reminder: *"Start of Combat: marks the enemy across as its quarry. Attacks it when it can."* Below it: *"Hunt: take that enemy as quarry."*
- The exact rules in `docs/ideation/content/hunters.md` are unchanged:
  - the bell step;
  - the mark follows the animal;
  - one quarry each;
  - own Quarry beats a lent one;
  - legal targets unless "wherever it stands";
  - no new marks after the bell.

**Take** (kept). Reminder: *"Its quarry dies while this is on the board."*
- If both die in the same exchange, it still counts.
- Only Hunters make Takes.
- One Take per death: if Hunters share a quarry, the first in reading order makes it.

**Shares** (new rule, no new keyword). "Half the quarry's stats", "a quarter of the target's stats":
- They read the enemy's Attack and Health **as the fight began**: the combat-start snapshot, the numbers the scout showed. They never read buffs gained in the fight, so nothing loops inside a fight.
- Rounded down, at least +1/+1. That keeps early Takes at today's +1/+1 and tames the early lead (see Boards).
- "Permanently" applies at once in the fight and stays on the recruit board.
- **The shares are the tribe's rate parameter** (below). Cards print "half" and "a quarter", and the sweep moves them together.

**Pelt** (new token, from Madame Ermeline). A 0-gold spell, Created: *"Give a unit +X/+Y permanently,"* where X/Y is a quarter of that quarry's stats. It shows the prey's portrait ("Pelt of Mrs Jay, +15/+16").
- It arrives in hand after the fight. With a full hand it waits on the doorstep, as Birds do.
- Reminder on "Pelt": *"A 0-gold spell: give a unit a quarter of that quarry's stats."*

**Pack** and **Pounce** are kept, with the rules in `hunters.md`. A pack **kill** is a pack attack whose damage kills its target. Its attackers are the leader and the joiners.

**Dropped:** flat +1 Attack grants (Young Brock, Old Brock, Old Isegrim), the Toll-Bard's Attack loss, Ermeline's tier-up discount and Russet's 1-gold discount.

---

## The 16 Hunters

The tier spread is 3/3/3/3/2/2, as now. Every creature, name and portrait is kept. Four cards change role:
- Young Brock: from lender to heir.
- Madame Ermeline: from tier-up discount to Pelts.
- The Laird: from +1/+1 a Take to the Take doubler.
- Old Isegrim: from +3 a join to the biggest-enemy hunt.

T3–T6 bodies are a little larger. Body scale is the scale build's call (plan step 2).

| T | Card | Stats | Text | Golden |
|---|---|---|---|---|
| 1 | Little Nip | 2/3 | Quarry. Take: gain half the quarry's stats permanently. | 4/6. …gain the quarry's stats… |
| 1 | Wick | 2/3 | Pack. After this joins a kill: gain a quarter of the target's stats permanently. | 4/6. …half the target's stats… |
| 1 | Young Brock | 2/3 | When a Hunter beside this is sold: gain its stats permanently. | 4/6. …gain double its stats… |
| 2 | Sable | 2/3 | Quarry. Start of Combat: gain its quarry's Attack. Take: gain half the quarry's stats permanently. | 4/6. …double its quarry's Attack… gain the quarry's stats… |
| 2 | The Toll-Bard | 2/4 | Quarry. After its quarry attacks: get 1 gold next turn. Twice a fight. | 4/8. …get 2 gold… |
| 2 | Mistress Russet | 3/3 | Quarry. Take: your next shop has a copy, with half its buffs. | 6/6. …with all its buffs. |
| 3 | Brother Wolf | 3/5 | Pack. Units beside this attack first; this joins both. | 6/10. Same text. |
| 3 | The Lodger | 4/4 | Pounce. After this pounces: gain a quarter of the quarry's stats permanently. | 8/8. …half… |
| 3 | Old Lutra | 3/5 | Quarry, wherever it stands. Take: gain half the quarry's stats permanently. | 6/10. …gain the quarry's stats… |
| 4 | Madame Ermeline | 3/7 | After each Take: get a Pelt of the quarry. | 6/14. …get two Pelts… |
| 4 | Old Brock | 3/6 | Units next to this have Pounce and hunt the enemy across from this, wherever it stands. | 6/12. Same text; golden Details: they pounce twice a cycle. |
| 4 | Grey Agnes | 4/6 | Pack. Your pack leaders take half damage. | 8/12. …take a quarter of the damage. |
| 5 | Grizel | 5/8 | Pack. After your pack kills: its attackers gain a quarter of the target's stats permanently. | 10/16. …half… |
| 5 | The Mountain Glutton | 5/7 | Pack. Cleave. After each Take: gain half the quarry's stats permanently. | 10/14. …gain the quarry's stats… |
| 6 | The Laird of the Sett | 6/9 | All your units have Quarry. Your Takes trigger twice. | 12/18. …three times. |
| 6 | Old Isegrim | 7/10 | Pack. Start of Combat: this and units beside it hunt the biggest enemy, wherever it stands. | 14/20. …units next to it… |

**Text length:** median 11 words, longest 16. That is inside the guide's 11 / 17 / 22.

**Details lines** (muted, on the slip):
- Shares: "Reads its stats as the fight began. Rounded down, at least +1/+1."
- Young Brock: "Its current stats, without the tribe bonus."
- Russet: "A pool copy of the quarry's card, your tier or lower. It isn't golden. Unbought, it goes back at End of Turn."
- Brother Wolf: "Joins each once a cycle. Doesn't lead while one of them can."
- Agnes: "Only the counter-hit of the attack they lead."
- The Laird: "'Take:' text fires twice. 'After each Take' text fires once. A unit with a quarry keeps it."
- Isegrim: "Biggest: most Attack plus Health at Start of Combat; ties in reading order. A unit with its own quarry keeps it."

### Reading the per-card lines

**Rough stats** come from the calculator at the default shares, on the two typical lines below. The tiers are:
- Pack line: T4 on R6, T5 on R8, T6 on R11.
- Open Season line: T4 on R7, T5 on R9, T6 on R11.

**The prey** is the field at the target shape: level with today's bots to R7, then ×1.5 a round. From R7 the field's carry holds a third of the board.

| Round | Median field board | A typical other enemy unit | The enemy carry |
|---|---|---|---|
| R9 | 144 | 16 (7/9) | 48 (22/26) |
| R12 | 486 | 54 (24/30) | 162 (73/89) |
| R15 | 1,640 | 182 (82/100) | 547 (246/301) |

So half a typical quarry is about +4/+4 at R9, +12/+15 at R12 and +41/+50 at R15. Half a carry is +11/+13, +36/+44 and +123/+150.

---

### Tier 1

**Little Nip** (2/3). *Fox Cub, Errand-Runner.* Quarry. Take: gain half the quarry's stats permanently.
- **Condition:** the enemy across at the bell dies while Nip stands, or in the same exchange.
- **Payoff:** half the quarry, every fight he Takes.
  - About +4/+4 a Take at R9, +12/+15 at R12, +41/+50 at R15.
  - On a typical board he is 12/15 at R9, 30/40 at R12 and 120/150 at R15.
  - Golden, he takes the whole quarry. That is the tribe's highroll card (moment 1 below).
- **Permanence:** permanent. The scout previews it on each enemy.
- **Enables:** Takes for the Glutton, Ermeline and the Laird. A grown body for Young Brock to inherit.
- **Concentrates:** yes, on himself. The first lesson in "big prey or sure prey".
- *Hook: he did all of it himself. Ask anyone. Don't ask anyone.*

**Wick** (2/3). *Least Weasel, Runner for the Pack.* Pack. After this joins a kill: gain a quarter of the target's stats permanently.
- **Condition:** he joins a pack attack that kills its target. He needs a leader beside him, before him in reading order.
- **Payoff:**
  - A quarter of the kill: +2/+2 at R9, +6/+7 at R12, +20/+25 at R15, at 0.7–0.9 joined kills a fight.
  - He is 9/11 at R9, 25/30 at R12 and 77/93 at R15.
  - He joins, so the target never hits him back.
- **Permanence:** permanent.
- **Enables:** the Pack line's first growth, before Grizel. With Grizel he gains twice from every kill.
- **Concentrates:** partly, on himself. The weasel steals scraps and never gets bitten.

**Young Brock** (2/3). *Badger, Heir to the Sett.* When a Hunter beside this is sold: gain its stats permanently.
- **Condition:** you sell a Hunter in a slot beside him, in the same row. Move it there first.
- **Payoff:**
  - Nothing is lost when you upgrade a slot.
  - On the engine line he inherits the Toll-Bard (R7) and Russet (R11): 7/9 at R9 and 11/13 at R12.
  - When a 60/75 Nip is sold for a second tier 6 on R13, he is about 70/90 at R15.
  - Golden, he gains double: a stat doubler you pay for with a unit.
- **Permanence:** permanent.
- **Enables:** concentration by selling. Late-game slot upgrades stop wasting trophies.
- **Concentrates:** yes. He is the heir, and he collects.
- *Hook: will inherit four hundred years of tunnels and a family of foxes who have never paid rent.*

### Tier 2

**Sable** (2/3). *Stoat, of the Ermine Court, in Summer Brown.* Quarry. Start of Combat: gain its quarry's Attack. Take: gain half the quarry's stats permanently.
- **Condition:**
  - Her quarry is in the front row, or the front row has fallen.
  - She lives to her swing, or her quarry swings at her: the exchange is simultaneous, so she still trades.
- **Payoff:**
  - In the fight, her Attack is her own plus her quarry's. She kills anything across whose Health is at or below that, and a mutual kill still counts as a Take.
  - Permanently, half of what she hunted: about +5/+6 at R9 (+11/+13 off a carry), +17/+21 at R12 (+36/+44), +57/+70 at R15 (+123/+150).
  - She is 16/20 to 22/27 at R9, 47/58 at R12 and about 165/200 at R15.
- **Permanence:** the Attack gain lasts the fight; the trophy is permanent.
- **Enables:**
  - The tribe's answer to a front-row carry.
  - The best Pelt target before the Glutton.
  - The best pack leader with Grey Agnes, who halves her counter-hit.
- **Concentrates:** yes. A stoat really does kill rabbits ten times her size.
- *Hook: the Court's summer assassins dress in brown. They are counting the days to ermine.*

**The Toll-Bard** (2/4). *Pine Marten, Keeper of the Lane Songs.* Quarry. After its quarry attacks: get 1 gold next turn. Twice a fight.
- **Condition:** his quarry lives long enough to swing twice.
- **Payoff:**
  - 1–2 gold a turn (golden 2–4), mostly R2–R8: about 6–8 gold over the early game.
  - That gold buys the rolls that find Sable and Nip triples.
- **Permanence:** economy.
- **Enables:** early triples (golden Hunters double their shares), and the climb to T4 on time.
- **Concentrates:** no.
- **Why he stays:** he is the one Hunter who wants his quarry alive, so he fights your Takers for lanes. Put him across their wall. The twice-a-fight limit stops a Windfury-style enemy from paying a fortune.
- *Hook: any traveller may pass. Each pays in verse, or failing verse, in coin.*

**Mistress Russet** (3/3). *Fox, Poacher, Licensed After a Fashion.* Quarry. Take: your next shop has a copy, with half its buffs.
- **Condition:** a Take on a card of your tier or lower.
- **Payoff:**
  - A body for 3 gold: the base card plus half its buffs.
  - Off a typical quarry: 11 stats at R9, about 30 (14/16) at R12, about 95 (43/52) at R15.
  - Off a carry: about 25, 84 and 277.
  - The copy comes out of the pool, so it also denies their triple.
- **Permanence:** a permanent body (it doesn't grow).
- **Enables:** tempo bodies at par from R5, and Young Brock's sales. Golden, she copies the whole thing. With the Laird, two copies.
- **Concentrates:** no. It's a new body.
- *Hook: it was already out of its pen. She was only showing it the way.*

### Tier 3

**Brother Wolf** (3/5). *Wolf, Under a Vow.* Pack. Units beside this attack first; this joins both.
- **Condition:** leaders on both sides of him in the row. F2 or F3 is best.
- **Payoff:**
  - Combat: 3+ Attack lands on two aimed targets a cycle, and he never takes a counter-hit.
  - His growth comes from Grizel. Joining twice a cycle, he is in more kills than anyone: 7/10 at R9, 30/38 at R12, 145/175 at R15.
- **Permanence:** the joins last the fight; his Grizel shares are permanent.
- **Enables:** pack kills for Grizel, Wick and Agnes. The Pack line's best holder.
- **Concentrates:** partly. Stats pile up on the wolf who never gets hit back.
- *Hook: he swore on the old oak never to strike first. He does not consider this striking first.*

**The Lodger** (4/4). *Fox, Lodger in a Badger Sett, Pays No Rent.* Pounce. After this pounces: gain a quarter of the quarry's stats permanently.
- **Condition:** your side damages the quarry of a unit next to him, and he pounces once a cycle.
- **Payoff:**
  - A bite of someone else's prey, kill or not: +2/+2 a pounce at R9, +6/+7 at R12, +20/+25 at R15.
  - At about 1.5 pounces a fight (2 beside Old Brock) he is 12/13 at R9, about 22/27 at R12 and 65/80 at R15.
- **Permanence:** permanent.
- **Enables:** Old Brock's sett; back-row reach onto a protected quarry. He needs Quarry neighbours.
- **Concentrates:** yes, on himself. In B2 he has four neighbours' prey to eat from.

**Old Lutra** (3/5). *Otter, Runner of the Reed Channels.* Quarry, wherever it stands. Take: gain half the quarry's stats permanently.
- **Condition:** his quarry dies while he stands. He reaches it in either row, so place him across their back-row engine or carry.
- **Payoff:**
  - Back-row prey is usually bigger: about +5/+6 a Take at R9, +18/+22 at R12, +61/+75 at R15.
  - He is 12/15 at R9, 31/38 to 46/56 at R12 and 120–190 at R15. The top of each range takes spread Pelts.
- **Permanence:** permanent.
- **Enables:** back-row Takes for the Glutton and Pelts. An answer to a back carry, aimed by the scout.
- **Concentrates:** yes.
- *Hook: the heron customs men have searched him nine times. They have never once looked under the water.*

### Tier 4

**Madame Ermeline** (3/7). *Stoat, Court Dressmaker.* After each Take: get a Pelt of the quarry.
- **Condition:** any of your Hunters makes a Take, about 3–4 times a fight.
- **Payoff:** a quarter of each quarry, as a spell you place.
  - About 11 stats of Pelts a fight at R9 (two of about 2/3).
  - About 37 at R12 (three of about 6/7).
  - About 125 at R15 (three or four of about 20/25).
- **Permanence:** permanent once played. You can keep a Pelt in hand for the turn the carry lands.
- **Enables:** the carry (Pelts on the Glutton), or an even board (Pelts on the smallest Hunter). Pelts are spells, so spell payoffs from other tribes see them.
- **Concentrates:** yes, wherever you choose.
- *Hook: her trims are the finest in the Court. She will not say where the ribbons come from.*

**Old Brock** (3/6). *Badger, Squire of the Sett.* Units next to this have Pounce and hunt the enemy across from this, wherever it stands.
- **Condition:**
  - Units with no quarry of their own next to him: the Lodger, the Glutton, Wick, Brother Wolf, Agnes.
  - Something worth killing across from him. In B2, that's their B2.
- **Payoff:**
  - Four units hit their B2 from the first cycle, wherever it stands, and pounce on every hit.
  - The Take on it is worth 15–48 stats of prey at R9, 49–162 at R12 and 166–547 at R15. That is a carry or an engine, to the Glutton and the Pelts.
- **Permanence:** a fight aura. What it feeds is permanent.
- **Enables:** the Lodger, the Glutton's biggest meals, and an answer to a back carry.
- **Concentrates:** no. It focuses fire.
- *Hook: the foxes are frightful, of course. But one must have somebody to dinner.*

**Grey Agnes** (4/6). *She-wolf of the Pack.* Pack. Your pack leaders take half damage.
- **Condition:** pack attacks: a leader with Pack units beside it.
- **Payoff:**
  - The only counter-hit a pack attack takes is halved.
  - Leaders live to make their Takes: Sable's mutual trades become wins. Taking less damage is the strongest stat-holder the audit's model measured.
  - She is about 6/10 at R9 and 20/25 at R12, with Grizel.
- **Permanence:** a fight aura.
- **Enables:** Sable and Nip as pack leaders, and every Take a leader makes. The decision is who leads and who joins.
- **Concentrates:** it lets a leader carry hold its stats.

### Tier 5

**Grizel** (5/8). *Wolf, Mother of the Pack.* Pack. After your pack kills: its attackers gain a quarter of the target's stats permanently.
- **Condition:** a pack attack kills, about 2–3 times a fight.
- **Payoff:**
  - Every wolf in the kill takes a quarter: about 23 stats a fight across the pack at R9, 120 at R12 and 410 at R15.
  - Her own body is 8/12 at R9, 17/21 at R12 and 43/53 at R15. Most of her value sits on the others.
- **Permanence:** permanent.
- **Enables:** the Pack line's engine. Brother Wolf, Wick, Agnes, the Glutton and every pack leader grow.
- **Concentrates:** no. It spreads evenly, and at equal totals even bodies win under our rules.
- *Hook: raised every cub in the valley, half of them not wolves. They all still call her on Sundays.*

**The Mountain Glutton** (5/7). *Wolverine, Saga Mercenary, Here for the Food.* Pack. Cleave. After each Take: gain half the quarry's stats permanently.
- **Condition:** any of your Hunters makes a Take while it is on the board.
- **Payoff:**
  - Half of every Take: about +22 a fight at R9, +74 at R12 and +250 at R15.
  - It is bought as 5/7 on R9, about 68/83 at R12 (31% of the board) and about 300/365 at R15 (36%).
  - On the Pack line, bought R10, it is 55/68 at R12 and about 365/445 at R15.
  - It grows mid-fight too, so the wolverine visibly swells with each Take.
- **Permanence:** permanent.
- **Enables:** it is the carry. Pelts go on it until it holds about 35% of the board.
- **Concentrates:** yes. It holds its stats three ways:
  - Pack: it joins B1's attack from B2, so it is never hit back.
  - The back row protects it.
  - Cleave spends its overkill on the units beside its target.
- *Hook: signed on for the plunder. Is now mostly there for the catering.*

### Tier 6

**The Laird of the Sett** (6/9). *Badger, Keeper of the Old Rights.* All your units have Quarry. Your Takes trigger twice.
- **Condition:** Takes. With him, every unit marks the enemy across, so Hunters with no quarry of their own make Takes too.
- **Payoff:**
  - Every "Take:" line fires twice. Nip, Sable and Lutra take the whole quarry; Russet puts two copies in the shop.
  - That is about +60 stats a fight at R12 and +200 at R15 on the Open Season line.
  - The extra Takes feed the Glutton and Ermeline once each.
- **Permanence:** what it doubles is permanent.
- **Enables:** the Open Season finish: seven lanes, seven questions. It works like Battlegrounds' Brann Bronzebeard for Take.
- **Concentrates:** no. It multiplies the Takers.
- *Hook: the old rights are clear. Everyone faces whoever stands opposite. He has the papers somewhere.*

**Old Isegrim** (7/10). *Wolf, Constable of the Wold.* Pack. Start of Combat: this and units beside it hunt the biggest enemy, wherever it stands.
- **Condition:** units beside him that have no quarry of their own. The Glutton and Brother Wolf are best.
- **Payoff:**
  - His gang goes for their carry from the first cycle, in either row. It falls about 65% of the time on a level board.
  - At R12 a 162-stat carry is a Take worth +36/+44 to the Glutton, and +18/+22 to each gang member with Grizel.
  - At R15 a 547-stat carry is worth +123/+150 to the Glutton and +61/+75 to each member.
  - His own body is 22/27 at R12 and about 110/135 at R15.
- **Permanence:** the hunt lasts the fight; its feed is permanent.
- **Enables:** one of the pool's two or three answers that ignore rows (`fundamentals.md` question 2). It is the Pack finisher.
- **Concentrates:** no. It focuses fire on theirs. Wolves really do take down a moose.
- The wolf of the Reynard fables. Reynard's foxes (Nip, Russet, the Lodger) still get the credit.

---

## The tribe

### Engine and rate parameter

**The engine is the trophy: every payoff is a share of the enemy units your Hunters chose and killed.** It has three feeds:
- **Takes** (Nip, Sable, Lutra, the Glutton, Ermeline, the Laird);
- **pack kills** (Wick, Grizel, Isegrim's gang);
- **pounces** (the Lodger).

**Rate parameter: s, the share. Default ½.** Cards print it as "half". The other prints are tied to it:
- "a quarter" is s/2: Wick, the Lodger, Grizel, the Pelts;
- the Glutton takes s;
- golden doubles s.

So one knob moves the whole tribe. The sweep should try 0.33 to 0.67. The board totals below are against the target (1.00 = the median field board):

| s | Pack line, R9 / R12 / R15 | Open Season line, R9 / R12 / R15 | Open Season carry's share, R12 / R15 |
|---|---|---|---|
| 0.33 | 0.89 / 0.74 / 0.84 | 0.87 / 0.65 / 0.56 | 31% / 35% |
| 0.40 | 0.96 / 0.86 / 1.04 | 0.94 / 0.78 / 0.75 | 33% / 36% |
| **0.50** | **1.07 / 1.05 / 1.38** | **1.06 / 1.00 / 1.12** | **31% / 36%** |
| 0.60 | 1.19 / 1.25 / 1.76 | 1.18 / 1.25 / 1.61 | 32% / 36% |

Secondary knobs if one piece runs hot:
- the Laird's multiplier (×2; ×1 gives 0.92 / 0.84 at R12 / R15 on Open Season, ×3 gives 1.07 / 1.46);
- the Glutton's share (s; s/2 gives 0.84 / 0.82);
- Isegrim's gang size (beside, or only one unit);
- the Lodger's and Wick's quarters.

**Why it reaches the shape by construction.** The Hunter board is a sum of shares of enemy units. When the field grows ×1.5 a round, the shares do too. So Hunters keep the field's slope, and s sets their level against it.

Two checks:
- **An all-Hunter lobby** has no other engine. Shares are copies, not transfers, so each board still gains about s × 2.5 Takes of prey a fight: about ×1.25 a round before the T5s, and ×1.5–1.6 with the Glutton, Ermeline and Grizel out.
- **Ceiling on a runaway.** A Hunter board can gain at most its total share of the enemy board in one fight (about 1.25 × the enemy board without the Laird). Its lead over the field converges instead of running away:
  - about 1.25× the field when it Takes half the enemy;
  - about 2.5× even when everything it fights dies.

  The Hunters' tail comes from eating someone else's tail.

**What the sweep must know.** Hunters follow the field. On today's flat pool (the step 2 lever sweep) their shares stay flat, because their prey is flat. Measure them against a compounding field: the wave 2 field, or the synthetic engine dial applied to the other seats.

### When it comes online

- **R1–R4: level.** The bodies are par, and Takes on 2/3s give +1/+1 (rounded down, at least +1/+1), today's rate.
- **R5–R7: ahead, 1.15–1.3× in the calculator.** A fixed share of every kill is large while the field still grows by buying bodies. Rounding down takes about a third off the early gains, which brings the calculator's 1.29 near 1.15. Watch R4–R8 win rates in the sweep (lever table below).
- **Pack line, online R8.** Grizel turns every pack kill into growth for the whole pack.
- **Open Season, online R7–R9.** Ermeline's Pelts arrive R7 and the Glutton R9. Field units pass 15 stats then, so a Take is worth +4/+5 to the Taker, half again to the Glutton and a quarter as a Pelt.
- **Both peak on a T6 at R11.** The Laird doubles the Takers; Isegrim's gang eats the carry.

The engine cards are behind at once, level in a few turns and clearly ahead after:

| Card | Bought | Behind | Level | Ahead |
|---|---|---|---|---|
| The Glutton | R9 as 5/7 (median unit ~20) | R9 | R10 (~35) | R12, 2.8× the median unit |
| Madame Ermeline | R7 as 3/7 | R7–R8 | Her Pelts have paid her slot back by R9 | From R10 |
| The Laird | R11 as 6/9 | Body only | Doubling repays the slot in one fight | From R12 |
| Grizel | R8 as 5/8 | R8 | R9 (+23 a fight to the pack) | From R10 |

Hunters are an early-steady clock with a late lift that comes from the prey, not a slow-start engine. Birds and Fairies can own the slow-start clock.

### The decision it creates

Every turn the main question is **big prey or sure prey?**
- A trophy is half the quarry, so a bigger quarry pays more. It's also less likely to fall while your Hunter stands.
- You read the scout and match Takers to lanes:
  - Sable to the biggest Attack in front (she trades with it);
  - Nip to the biggest unit he can kill;
  - Lutra to their best back-row unit;
  - Russet to the card you want to own or deny;
  - the Toll-Bard to their wall, which none of the others want.
- The scout prices each choice: hover a Hunter and every enemy shows "Take: +12/+15".

Around that:
- **Who wears the Pelt.** Concentrate on the carry, or keep the board even. Under our rules a carry above about 35% of the board starts losing fights.
- **Who leads, who joins.** A joiner gives up its own quarry, but never takes a counter-hit. Agnes halves the leader's counter-hit.
- **Who to sell into the heir.** Move the Hunter beside Young Brock, then sell: no stats are wasted.
- **The Laird's seven lanes.** With him, every slot is a matching question.

### Carry route: the Glutton

- **Build:** the Open Season Takers (Nip, Sable, Lutra) with Ermeline. Every Take feeds the wolverine half and makes a Pelt.
- **Placement:** in B2 with Pack, joining B1's attack, so it is never hit back and is protected by the front row. Cleave uses the overkill. It is also the best joiner for a Taker's signature play (below).
- **Pelts** go on it until it holds about 35% of the board.
- **Size:** about 68/83 at R12 and 300/365 at R15 on a typical roll. A strong roll reaches 160/196 and about 890/1,090.
- **Before R9** the carry is Sable, fed by Pelts.
- **Second route:** Young Brock as an heir-carry. Sell trophied Hunters beside him as slots are upgraded. Golden, he doubles them.

### Non-carry route: the Pack

- Wolves in pairs: leader, joiner, leader, joiner. Brother Wolf goes between two leaders, and Agnes halves the leaders' counter-hits.
- Grizel feeds every attacker in every kill, so the board grows evenly. At R15 the units run 77/93 to 365/445, and no unit holds more than 36%.
- Isegrim's gang goes for the enemy carry every fight.
- Answers that halve or swap one unit do little against it.

### Answers to other tribes' carries

- **Sable.** She gains her quarry's Attack, so she trades 1-for-1 with any front-row carry across from her, then takes half of it. Counter: a Shield or damage reduction on the carry, a decoy across her, or the carry in back.
- **Old Isegrim.** His gang hunts the biggest enemy in either row. This is the tribe's one row-ignoring answer, and it fails about a third of the time on a level board.
- **Old Brock.** Four units hit their B2 with reach, and pounce on every hit.
- **Old Lutra.** He reaches the back-row unit across from him.
- **Mistress Russet.** She steals a half-buffed copy of the carry and a pool copy of its card, denying the triple.
- **The trophy itself.** Killing the lobby's runaway is the biggest meal Hunters can get, so the tribe is always shopping for the answer. Bots must buy and aim it (bot needs below).

### Weak points

- **Shield and damage reduction on a carry.** Sable's one big hit is wasted and she dies alone. Isegrim's gang needs two or three hits.
- **Walls across your lanes.** Quarry is mandatory, so a Hunker or Bristle unit across a Taker wastes it. Pack leaders eat every prick.
- **No prey.** Empty lanes, Nests and Eggs (Eggs can't be quarry), Hasty Pudding swallowing your quarry, a Changeling swap.
- **Small prey.** Ghosts, wide token boards and small lobbies give small trophies. Hunters can't outgrow a flat lobby.
- **Losing badly.** A Take needs the Hunter alive. A board that is far behind makes few Takes, though Sable's mutual trades still count.
- **Being read.** Lanes show in the scout. Moving doesn't shake the mark, but walling does.
- **Tiny enablers.** Ermeline, Old Brock and the Laird stay near their printed bodies (6/9 to 9/12 at R15), so they are dead slots in a fight. The back row hides them until the front falls.
- **Capstone dependence.** Without a T6, Open Season falls to 0.82× at R12 and 0.64× at R15. Without Isegrim, the Pack line falls to 0.88× and 0.86×.

### Two highroll moments

1. **The fox cub that ate the moose.**
   - Round 13. The lobby leader's carry, a 270/330 Mrs Jay, stands in their F2.
   - You put your golden Little Nip, 70/85, in F2 across from her: she is his quarry. Brother Wolf (110/130) goes in F1 and the Glutton (160/195) in F3.
   - Nip leads; the wolf and the wolverine join. 340 damage lands on her in one exchange. Only Nip takes the counter-hit, and he falls with her, which still counts as a Take.
   - Golden Nip takes the whole quarry. **Next turn he is 340/415. A tier 1 fox cub is the biggest unit in the lobby.**
   - The Glutton eats +135/+165, and a Pelt of Mrs Jay (67/82) lands in your hand.
   - With the Laird, Nip's Take fires twice: 610/745.
   - It needs a golden T1, a grown pack and a lobby runaway to eat: a top-1% game, which the owner accepts (9d).
2. **I bought their carry.**
   - Round 12. The Hedgerow player's golden Alderman Dozey, 150/170, sits in their F3. Mistress Russet goes in F3 across from him, with Brother Wolf and the Glutton beside her.
   - She leads; they join; about 280 damage lands in one exchange. He falls, and so does she, which still counts: her Take.
   - Next turn your shop has an extra card with a fox's paw on it: **Alderman Dozey, 75/85, for 3 gold**, out of the pool, so their next copy is gone too.
   - Golden Russet offers the full 148/165. With the Laird, two of them.

**The signature play** in both: the Taker leads, the pack lands the blow, and only the Taker is hit back. A Take counts even when the Taker falls in the same exchange.

*The everyday surprise:* a 2/3 stoat walks up to their 60/58 bruiser and swings for 62. Both fall, and she comes home 32/32.

---

## Boards (typical rolls, s = ½)

Targets are ~52 / ~144 / ~486 / ~1,640 at R6 / R9 / R12 / R15. The field is level with today's bots to R7, then ×1.5 a round. Board = Attack + Health over the 7 units, with the Harvest Supper bonus.

**Line 1, the Pack (tempo, then Grizel and Isegrim).** Tier 2 R2, T3 R4, T4 R6, T5 R8, T6 R11.

| Round | Board | vs target | Biggest | On the board |
|---|---|---|---|---|
| R6 | 67 | 1.29 | Sable 7/8 | Wick 4/5, Nip 6/7, Sable, Young Brock 2/3, Brother Wolf 3/5, Lodger 6/6, Agnes 3/6 |
| R9 | 154 | 1.07 | Sable 16/20 (23%) | Wick 9/11, Nip 12/15, Sable, Brother Wolf 7/10, Lodger 12/13, Agnes 6/10, Grizel 8/12 |
| R12 | 509 | 1.05 | Glutton 55/68 (24%) | Wick 25/30, Nip 36/43, Sable 47/58, Brother Wolf 30/38, Grizel 17/21, Glutton, Isegrim 22/27 |
| R15 | 2,262 | 1.38 | Glutton 364/445 (36%) | Wick 77/93, Nip 121/148, Sable 164/200, Brother Wolf 144/176, Grizel 43/53, Glutton, Isegrim 109/134 |

Layout from R12:
```
F1 Sable (leads)   F2 Brother Wolf (joins both)   F3 Little Nip (leads)   F4 Wick (joins F3)
       B1 Old Isegrim (leads at the biggest)   B2 The Mountain Glutton (joins B1)   B3 Grizel (leads)
```

**Line 2, Open Season (engine and the Glutton carry).** Tier 2 R2, T3 R5, T4 R7, T5 R9, T6 R11.

| Round | Board | vs target | Biggest | On the board |
|---|---|---|---|---|
| R6 | 67 | 1.28 | Nip 6/8 | Nip, Young Brock 2/3, Sable 6/8, Toll-Bard 2/4, Russet 3/3, a poached copy 6/7, Lutra 5/6 |
| R9 | 152 | 1.06 | Sable 22/27 (32%) | Nip 12/14, Young Brock 7/9, Sable, Russet 5/5, Lutra 12/15, Ermeline 5/8, Glutton 7/9 |
| R12 | 484 | 1.00 | Glutton 68/83 (31%) | Nip 32/39, Young Brock 11/13, Sable 47/57, Lutra 46/56, Ermeline 6/9, Glutton, Laird 9/12 |
| R15 | 1,845 | 1.12 | Glutton 298/364 (36%) | Nip 151/185, Young Brock 11/13, Sable 164/201, Lutra 192/234, Ermeline 6/9, Glutton, Laird 9/12 |

Layout from R12:
```
F1 Sable          F2 Little Nip          F3 Young Brock (heir to F2 and F4)          F4 Old Lutra
       B1 Madame Ermeline      B2 The Mountain Glutton (joins B1)      B3 The Laird of the Sett
```
The enablers want the protected back row. When their carry sits in their back row and is worth more than a turn of Pelts, swap Lutra into B1 and Ermeline into F4: Lutra then hunts their B1, wherever it stands.

**Strong roll.** Every tier a round early, a golden Sable from R6, a golden Glutton from R11:
- R9: 220 (1.53×).
- R12: 937 (1.93×), Glutton 160/196 (38%).
- R15: 4,264 (2.60×), Glutton 889/1,087 (46%).

Add a golden Laird for a top-1% roll: R12 1,106 (2.28×), R15 5,087 (3.10×). Battlegrounds' p90/p50 is about 2.5 at turn 12, so Hunter strong rolls sit near its p90.

Hunters reach 10× only by eating a 10× board. That's the tail shape the owner wants: rare, and borrowed from someone else's highroll.

**Reading:**
- Both lines sit at the target from R9 to R12.
- The Pack line is clearly ahead at R15, because Isegrim's gang eats a third of the enemy board each fight.
- Both run 1.15–1.3× early. Take the early levers first if the sweep shows Hunters winning R4–R8 too often.
- This is a calculator: Take chance, kill counts and pounces are expected values set from costing-3's 0.55 Take rate. It should be checked against the harness's field fights.

---

## Where it could run away, and the lever for each

| Risk | Why | Lever, in order |
|---|---|---|
| Early lead (R5–R7, 1.15–1.3×) | A fixed share of each kill is big while the field grows only by buying | Shares round down (already in). Then Nip and Wick to 2/2. Then shares count from R4. |
| Laird + Glutton + Ermeline on a 6-Take fight | Each Take pays the Taker ×2, the Glutton ½ and a Pelt ¼ | The Laird doubles "Take:" lines only (already in). Then ×2 becomes "and half again". |
| Isegrim's gang eats the carry every fight | A third of the enemy board, shared out each fight | His gang becomes the one unit beside him; or his first pack attack only. |
| Golden Young Brock doubles what is sold | A doubler you pay for with a unit; Pelts on a cheap Hunter, then sell | Golden becomes "gain its stats and 2 gold". |
| Golden Russet: full copies every fight | A median-size body for 3 gold each turn | Golden becomes three quarters of its buffs. |
| Sable trades with every front carry | An answer in every T2 shop | "If its quarry has more Attack" (pass 2's condition), then half its quarry's Attack. |
| The Glutton above 45% of the board | Overkill waste under our rules | Line policy spreads Pelts (already in). Then the Glutton's share s → s/2. |
| Pelts flood the hand | Up to 7 a fight | The doorstep rule. If hand space binds, Pelts merge: two Pelts of the same quarry stack. |

**No per-card size caps.** The rate limits are structural and were already in the tribe:
- one quarry each a fight, marked at the bell;
- one Take per death;
- one pounce a cycle.

The only new limit is the Toll-Bard's "twice a fight". It's a loop guard against repeat-attack enemies paying gold without end.

---

## Harness line policies

Card ids are as in `content/units/`. The new token is `pelt`.

### `hunters_pack` (tempo, then Grizel and Isegrim)

- **Buy and keep, in order:** old_isegrim, grizel, mountain_glutton, brother_wolf, sable, grey_agnes, little_nip, wick, lodger, old_lutra, old_brock, young_brock, mistress_russet, toll_bard, madame_ermeline, laird_of_sett.
- **Rounds 1–5 override:** wick, little_nip, sable, young_brock (a par body), then brother_wolf from T3.
- **Sell first:**
  - young_brock (R8, unless a Hunter beside him is about to be sold);
  - then lodger (R10, for the Glutton);
  - then grey_agnes (R11, for Isegrim, once the Glutton and Isegrim give the back row Pack);
  - wick last.
- **Climb:** T2 R2, T3 R4, T4 R6, T5 R8, T6 R11. Climb a round early when the last fight was won and the gold is there.
- **Save:** spend out on R1–R6. Bank 2–3 gold on R7 for T5 on R8, and 3–4 on R10 for T6 on R11. Otherwise spend out.
- **Placement (engine flag):**
  - Front row: leader, joiner, leader, joiner. Brother Wolf goes between two leaders (F2).
  - Back row: Isegrim leads at the biggest enemy from B1, and the Glutton joins him from B2, so both hit it with reach. Grizel leads from B3.
  - Quarry leaders go across the scouted enemy they can kill (Nip) or the biggest front Attack (Sable).

### `hunters_open_season` (engine and carry: Takes, Pelts, the Glutton, the Laird)

- **Buy and keep, in order:** laird_of_sett, mountain_glutton, madame_ermeline, sable, old_lutra, little_nip, mistress_russet, old_brock (only when the scout shows a carry or an engine in their B2), lodger (only beside two Quarry Hunters), young_brock, toll_bard, a poached copy (when it's bigger than your smallest unit), old_isegrim, grizel, grey_agnes, wick, brother_wolf.
- **Rounds 1–4 override:** little_nip, young_brock, sable, toll_bard, mistress_russet.
- **Sell first, always from the slot beside Young Brock:**
  - toll_bard (R7, for Ermeline);
  - then poached copies (from R9);
  - then mistress_russet (R11, for the Laird);
  - then little_nip for a second T6;
  - young_brock last.
- **Climb:** T2 R2, T3 R5, T4 R7, T5 R9, T6 R11. Stay at T5 on R10 unless the Glutton is already on the board.
- **Save:**
  - Spend out on R1–R6. The Toll-Bard's gold goes into rolls for Sable and Nip triples.
  - Bank 2–3 gold on R8 for T5 on R9, and 3–4 on R10 for T6 on R11.
  - Play every Pelt the turn it arrives, unless the carry is about to be bought next turn.
- **Lane policy (engine flag), from the scouted board, in this order:**
  1. Sable across the front enemy with the most Attack.
  2. Old Lutra in the back row across their biggest back-row unit when it's bigger than anything in front; otherwise in front, across the front unit no Taker wants.
  3. Little Nip across the biggest enemy whose Health is at most 1.5× his Attack; else the smallest.
  4. Mistress Russet across their best card at or below your tier (the carry if there is one).
  5. The Toll-Bard across their sturdiest wall, never across a Taker's target.
  6. Old Brock in B2 when their B2 holds a carry or an engine.
- **Pelts:** on the Glutton until it holds 35% of the board, then on the smallest Quarry Hunter. Before the Glutton, on Sable.
- **Poached copies:** buy one when it's bigger than your smallest unit and you have a slot. Sell it first.

### Bot needs for both lines

The bots need five things:
- a lane-assignment step on the scouted board (greedy is enough, using the "Take: +X/+Y" preview);
- a Pelt target;
- the heir move-then-sell;
- the poached-copy buy;
- a rule to buy and aim an answer (Sable, Isegrim, Old Brock) when the scout shows a carry.

Opponent bots must hold their carries still, or Quarry measures as noise (`hunters.md`, scouting).

---

## Engine support needed

**Exists** (pass 2 or Track B):
- the bell step;
- the `quarry`, `reach` and `lend_quarry` selectors;
- `on_take` and the per-fight Take count;
- the Pack joint attack, Pounce and the Glutton's `after_any_take`;
- Poach's extra shop slot;
- the `gold` effect with `next_turn`;
- granted keywords;
- Track B's biggest-enemy selector, damage reduction, Cleave and proportional buffs.

**Changed or new:**
1. **Bell snapshot of stats.** Every unit's Attack and Health at combat start, for shares to read. Track A's combat-start snapshots already plan this.
2. **`share` buff.** A permanent buff of ⌊fraction × snapshot stats of another unit⌋ to Attack and Health, at least +1/+1. It applies in the fight and on the recruit board. The fraction comes from config (the lever) and doubles on golden. Users:
   - `on_take` (Nip, Sable, Lutra);
   - `after_join_kill` (Wick);
   - `after_pack_kill`, to every attacker (Grizel);
   - `after_pounce` (Lodger);
   - `after_any_take` (Glutton).
3. **`after_join_kill` and `after_pack_kill` triggers.** A pack attack whose damage kills its target. Its attackers are the leader and the joiners.
4. **Pelt.** A Created token spell carrying stats (like an Acorn with a payload). Ermeline's `after_any_take` adds one to hand after the fight, with the Birds doorstep rule when the hand is full. The card shows the prey's portrait.
5. **Poach v3.** The copy is the base card plus ⌊½ × (snapshot − base)⌋ as permanent buffs (golden: all). Not golden, from the pool, tier at most yours.
6. **Heir.** `on_sold` of a Hunter in an adjacent slot: Young Brock gains its current stats (golden: double).
7. **Sable.** Start of Combat, after the bell: Attack += her quarry's Attack (golden ×2), this fight.
8. **Laird.** A trigger multiplier on `on_take` "Take:" text: ×2, golden ×3. `after_any_take` is not multiplied. Plus the existing lend-all.
9. **Isegrim.** `lend_quarry` with the biggest-enemy selector and reach, over self and adjacent (golden: neighbours).
10. **Agnes.** Damage reduction ½ on the counter-hit of a pack attack the unit leads (golden ¼).
11. **Small edits:**
    - Old Brock loses +1 Attack.
    - The Glutton gains Pack and Cleave.
    - The Toll-Bard pays 1 gold per quarry attack, twice a fight.

**UI:**
- **Trophy preview.** Hovering a Hunter in the scout shows "Take: +X/+Y" on each enemy it could mark.
- **Trophy marks.** A Hunter's frame shows a small pelt for each Take. Its details list them ("Mrs Jay, R11: +60/+70").
- **In the fight**, a Take pops its numbers on the Hunter, and the Glutton swells.
- **Pelts** show the prey's portrait and their numbers.
- **The poached copy** carries a fox's paw and "from your last opponent".

**Ghosts:** nothing special. Shares read the ghost's snapshot.

---

## Variations, if the panel wants another shape

- **Trophy as a keyword.** If "gain half the quarry's stats permanently" ends up on four or more cards, write "Quarry. Trophy." with the reminder *"Take: gains half the quarry's stats, permanently."* It saves six words a card. Golden would go to Details (wording guide rule 7), which is why it isn't used here.
- **Pelts for every Take, no on-unit trophies.** A tribe-wide Pelt economy like Quilboar Blood Gems. Every Take gives a Pelt worth half and the player places them all. That means more concentration choice and more actions per turn; Ermeline would then make Pelts bigger.
- **The Wild Hunt** (an Isegrim alternative). "Pack. After your pack kills: it attacks again." A combat chain on kills. Each kill feeds Grizel. It's more spectacle and less of an answer.
- **Bounty** (a Hunter hero, or a lobby system). The lobby's biggest unit is Wanted, and a Take on it pays double. The lobby screen shows the poster. Everyone sees who the runaway is, and the Hunters see dinner.
- **Run Down.** "After a Take: the biggest enemy becomes its quarry, once a fight." One more Take a fight for one card. Try it on Nip if Open Season runs short.
