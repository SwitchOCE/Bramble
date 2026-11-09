# Hunters, pass 3 synthesis: "You are what you hunt"

9 Nov 2026. This is the synthesis for the Track C Hunters panel (`docs/ideation/plan-scale-rework.md`, step 1). It starts from the best-ranked design, Wild (`hunters-wild.md`). It takes the best ideas from Engine (`hunters-engine.md`) and Carry (`hunters-carry.md`), and it fixes the breaker's points (`hunters-breaker.md`) that I accept. The Hunters–Bog overlap is settled together with the Bog synthesis (`bog-pass3.md`).

This is a paper design: nothing ran in Godot, and no price list was used. The numbers come from a fought growth model, `build/orchestrator/pass3/hunters-pass3-model.py`:
- Run `python3 -I hunters-pass3-model.py` (about 25 seconds). The saved output is `hunters-pass3-model.out.txt`.
- It extends the breaker's probe (`hunters-breaker-probe.py`): reading order, pointer and flags, back-row protection and the simultaneous exchange, plus Quarry, Take, Pack and Sable. It adds this design's lent hunts, Agnes, the Lodger, the Glutton, the Laird and Pelts.
- It plays two scripted lines and fights each round's board against a field of plain boards: lognormal stats (σ 0.45), half Battlegrounds-shaped with the carry in the back row 75% of the time, half spread at random.
- **Each board is measured before it fights**, the breaker's first must-fix. All growth is what those fights produced, averaged over 200–400 games. So Takes fall when a board is behind and rise when it's ahead.

The target, as the brief and the breaker use it: level with today's boards to R7, then about ×1.5 a round. Median boards are 50 / 158 / 532 / 1,794 at R6 / 9 / 12 / 15. A strong board is 1.35× the median, about 717 at R12. In Battlegrounds the biggest unit holds about 34% of the board.

## The pitch in three lines

1. **A Hunter grows by what it kills.** When its quarry falls, it takes half the quarry's stats, permanently. A fox cub that brings down a 239/292 carry gains +119/+146.
2. **Big prey or sure prey.** Aim at something you can surely kill, or at something worth killing. The scout shows each enemy's price: "Take: +36/+44".
3. **The lobby's runaway is the Hunters' best meal.** The pack aims at carries and gets paid most for killing them. You can lose the fight and still eat their carry.

**What a player sees:**
- In the scout, a paw print on each enemy with its price.
- In the fight, a "+36/+44" badge pops on the Hunter when its quarry falls. It rides the Hunter to the end of the fight.
- In the next shop, the badge lands as stats. Madame Ermeline's Pelt arrives in hand with the prey's portrait.

**What Battlegrounds doesn't have:** a tribe whose power is a share of the enemy units it chose and killed. Its scale comes from the lobby, not from its own loops. The closest things elsewhere:
- Hearthstone's devour cards (Void Terror eats friendly neighbours);
- Galaxy's Hunt, which pays the unit that struck the blow;
- Battlegrounds' Quilboar Blood Gems, which look like Ermeline's Pelts.

None of these takes its stats from a target the player marked before the fight.

## What I took from each design

| From | Kept | Changed |
|---|---|---|
| **Wild** (base) | The Take as the engine: each Taker gains its own share of its own quarry. The scout's price preview. Sable's proportional strike. Young Brock the heir. Russet's poached copy. Ermeline's Pelts. Brother Wolf, Wick, Grizel, Lutra, Isegrim's gang. The highroll stories | **Trophies land after the fight**, not during it (new, below). **No Cleave** on the Glutton. **The Laird only doubles** 'Take:' text; the all-Quarry half is cut. Pounce leaves the slice. Nip and Wick are 2/2. Ermeline's Pelt comes once a fight. Russet copies permanent buffs only. Golden Young Brock reaches further instead of doubling |
| **Engine** | **Old Brock's sett:** a protected enabler that makes placement matter around one card. He lends a positional hunt with reach. **Pounce retired**, its code kept. The meal shown on each paw print | No Feast keyword. Its one good use, a pooled feeder, becomes the Lodger: he takes half of his neighbours' Takes. Isegrim's Health cut is kept as a dial, not the default |
| **Carry** | **Hunt or harvest at tier 6** (Isegrim or the Laird). **B2 is contested** (Old Brock, the Glutton or Agnes). **Lutra leads the Glutton** into their biggest unit. The Toll-Bard's twice a fight | No Alpha, no collar, no Titbits, no Cleave on joins, no Shield on Young Brock (reasons in the breaker table) |

**Why trophies land after the fight** (my call; the designs and the breaker didn't raise it):
- **In Wild, a Take grew the Hunter at once, in the fight.** So the first Take of a fight made the next one easier. The model found this was worth more than stats: line A's R12 board beat plain boards up to about **1.7× its size** (88% Battlegrounds-shaped, 68% even).
- **Landing after the fight**, the same board beats plain boards only to about **1.3×** (at 1.35× it wins 5% and 0%). That is a normal keyword's worth, and it brings stat totals back to meaning something, the breaker's point about Cleave.
- **It matches Bog.** Bog's Soak lands on the recruit copy at the next Start of Turn, and shows as a pending badge in the fight. Hunters use the same queue and the same badge, so one rule covers both tribes.
- **It is easier to read.** Nothing changes size mid-fight, so the scout and the fight agree. The badge shows the meal as it happens.

## Why this fixes what the audit found

| The audit found (`fundamentals.md`, the Hunters card audit) | Pass 3 |
|---|---|
| 10 of 13 Hunter payoffs reset after each fight | 10 of 16 cards pay permanent stats or copies. The other six aim, join, hold, multiply or pay gold. No main payoff resets |
| Growth is flat: +1/+1 a Take, +1 Attack a pack kill | Every share is a fraction of an enemy unit. When the field compounds about ×1.5 a round, Hunter growth does too (the mirror runs at ×1.59–1.86) |
| No concentration; the biggest Hunter is a 10/11 Nip at R12 | The Glutton takes half of every Take: 74/90 at R12 and 308–342 Attack at R15 (28–40% of the board). Pelts go where you play them. Young Brock inherits a sold Hunter |
| Answers aim "across", so they land by layout luck | Isegrim's gang hunts the biggest enemy in either row. Old Brock reaches their B2. Sable trades with a front unit across from her. Killing a carry is the biggest reward in the tribe |
| Caps and limiters | None. The limits are structural: one quarry each a fight, one Take per death, trophies land after the fight |

**Answers become power.** No other tribe gets bigger by answering a carry, so the variance budget and the engine pull the same way.

---

## Tribe rules (pass 3)

**Quarry** (kept). Reminder: *"Start of Combat: marks the enemy across as its quarry. Attacks it when it can."* Below it: *"Hunt: take that enemy as quarry."*
- The exact rules in `docs/ideation/content/hunters.md` are unchanged:
  - the bell step;
  - the mark follows the animal;
  - one quarry each;
  - own Quarry beats a lent hunt;
  - legal targets only, unless "wherever it stands";
  - no new marks after the bell.
- **Marking order:** first each unit's own text (Quarry, Isegrim's biggest enemy), then lent hunts in reading order (Isegrim's gang, Old Brock's neighbours), only to units that still have no quarry.

**Take** (kept). Reminder: *"Its quarry dies while this is on the board."*
- If both die in the same exchange, it still counts.
- Only Hunters make Takes.
- One Take per death. If Hunters share a quarry, the first in reading order makes it. The front row reads first, so a front-row Taker beats a back-row Isegrim to the Take. The scout preview shows who will make it.

**Shares** (no new keyword). "Half the quarry's stats", "a quarter of the target's stats":
- They read the enemy's Attack and Health **at the bell**: the numbers the scout showed. They never read buffs gained in the fight, so nothing loops inside a fight.
- Rounded down, at least +1/+1. That keeps early Takes near today's +1/+1.
- **They land after the fight**, on the recruit copy, at the next Start of Turn. That includes a Hunter that fainted after making its Take. In the fight they show as a pending badge. Bog's Soak uses the same queue.
- **The shares are the tribe's rate parameter, s** (below). Cards print "half" and "a quarter", and the sweep moves them together.

**Pelt** (new token, from Madame Ermeline). A 0-gold spell, Created. Reminder: *"A 0-gold spell: give a Hunter a quarter of that unit's stats permanently."* (13 words)
- It shows the prey's portrait: "Pelt of Mrs Jay, +15/+16".
- It arrives in hand after the fight. With a full hand it waits on the doorstep, as Birds do.
- It aims at a Hunter only. So a Hunter–Fairy board can't use it to thank a Shy unit.

**Pack** (kept, rules in `hunters.md`). A pack **kill** is a pack attack whose damage kills its target. Its attackers are the leader and the joiners.
- **Pack joins never cleave** (new, logged for Track B). A joiner takes no hit back. With Cleave it would also kill three, the strongest pairing the breaker found.

**Biggest** means the most Attack plus Health at the bell. On a tie, the first in reading order.

**"Beside" and "next to"** follow the wording guide: "beside" is left or right in the same row (`adjacent`), "next to" adds the slots in front and behind (`neighbours`).

**Dropped:**
- Pounce leaves the slice (its code stays for experiments).
- Cleave is on no Hunter.
- The flat +1 Attack grants (Young Brock, Old Brock, Old Isegrim).
- The Toll-Bard's Attack loss, Ermeline's tier-up discount and Russet's 1-gold discount.

---

## The 16 Hunters

The tier spread stays 3/3/3/3/2/2, and every creature, name and portrait is kept. Five cards change role:
- Young Brock: from lender to heir.
- The Lodger: from Pounce to his neighbours' Takes.
- Madame Ermeline: from tier-up discount to Pelts.
- The Laird: from +1/+1 a Take to the Take doubler.
- Old Isegrim: from +3 a join to the biggest-enemy hunt.

| T | Card | Stats | Text | Golden |
|---|---|---|---|---|
| 1 | Little Nip | 2/2 | Quarry. Take: gain half the quarry's stats permanently. | 4/4. …gain the quarry's stats… |
| 1 | Wick | 2/2 | Pack. After this joins a kill: gain a quarter of the target's stats permanently. | 4/4. …half the target's stats… |
| 1 | Young Brock | 2/3 | When a Hunter beside this is sold: gain its stats permanently. | 4/6. When a Hunter next to this… |
| 2 | Sable | 2/3 | Quarry. Start of Combat: gain its quarry's Attack. Take: gain half the quarry's stats permanently. | 4/6. …double its quarry's Attack… gain the quarry's stats… |
| 2 | The Toll-Bard | 2/4 | Quarry. After its quarry attacks: get 1 gold next turn. Twice a fight. | 4/8. …get 2 gold… |
| 2 | Mistress Russet | 3/3 | Quarry. Take: your next shop has a copy, with half its buffs. | 6/6. …with all its buffs. |
| 3 | Brother Wolf | 3/5 | Pack. Units beside this attack first; this joins both. | 6/10. Same text. |
| 3 | The Lodger | 4/4 | After a Take beside this: gain half the quarry's stats permanently. | 8/8. …gain the quarry's stats… |
| 3 | Old Lutra | 3/5 | Quarry, wherever it stands. Take: gain half the quarry's stats permanently. | 6/10. …gain the quarry's stats… |
| 4 | Madame Ermeline | 3/7 | After each fight: get a Pelt of your biggest quarry. | 6/14. …get two Pelts… |
| 4 | Old Brock | 3/6 | Units next to this hunt the enemy across from this, wherever it stands. | 6/12. Same text. |
| 4 | Grey Agnes | 4/6 | Pack. Your pack leaders take half the hit back. | 8/12. …a quarter of the hit back. |
| 5 | Grizel | 5/8 | Pack. After your pack kills: its attackers gain a quarter of the target's stats permanently. | 10/16. …half… |
| 5 | The Mountain Glutton | 5/7 | Pack. After each Take: gain half the quarry's stats permanently. | 10/14. …gain the quarry's stats… |
| 6 | The Laird of the Sett | 6/9 | Your 'Take:' text triggers twice. | 12/18. …three times. |
| 6 | Old Isegrim | 7/10 | Start of Combat: this and units beside it hunt the biggest enemy, wherever it stands. | 14/20. …units next to it… |

**Text length:**
- Median 11 words, p90 15, longest 15 (Sable, Grizel, Isegrim). The guide asks for 11 or less, 17 or less and 22.
- The Pelt reminder is 13 words. The Take reminder is 9.
- Brother Wolf's and Old Brock's goldens break guide rule 7 (golden text doubles the numbers): they have no number to double. Each is a plain body at double stats. The other option for Old Brock is "Units next to this, even with their own Quarry, hunt…", which I haven't modelled.

**Details lines** (muted, on the slip):
- Shares: "Reads its stats at the bell. Rounded down, at least +1/+1. Lands after the fight."
- Young Brock: "Its current stats, without the tribe bonus."
- Russet: "Permanent buffs only. A pool copy of the quarry's card, your tier or lower. It isn't golden. Unbought, it goes back at End of Turn."
- Brother Wolf: "Joins each once a cycle. Doesn't lead while one of them can."
- The Lodger: "A Take made by a unit beside this."
- Ermeline: "Your biggest quarry: the biggest enemy your units marked at the bell, killed or not."
- Old Brock and Isegrim: "A unit with its own quarry keeps it."
- Agnes: "The hit back is the counter-hit of an attack they lead."
- The Laird: "'After each Take' text fires once. Two Lairds don't stack."
- Isegrim: "Biggest: most Attack plus Health at the bell; ties in reading order."

**Bodies.** T1 is a little smaller than Wild's (2/2 Nip and Wick, the breaker's early-lead fix). T3–T6 bodies are a little larger than today's. Body scale is the scale build's call (plan step 2). Each card's tier-up reward is its payoff, not its body.

### Reading the per-card lines
- Numbers come from the model's two lines (boards below), at the default s = ½.
  - **Line A, the Pack:** tempo, then Grizel, the Glutton and Isegrim. Tier-ups T2 R2, T3 R4, T4 R6, T5 R8, T6 R11.
  - **Line B, Open Season:** Takers, Pelts, the Glutton and the Laird. Tier-ups T2 R2, T3 R5, T4 R7, T5 R9, T6 R11.
- Stats are combat-start stats at that round, with the Harvest Supper bonus (+1/+1 at R7, R9 and R11).
- The prey is the field: a typical other enemy unit is about 7/9 at R9, 24/30 at R12 and 82/100 at R15. Their carry is about a third of their board.

### Tier 1

**Little Nip** (2/2). *Fox Cub, Errand-Runner.* Quarry. Take: gain half the quarry's stats permanently.
- **Condition:** the enemy across at the bell dies while Nip stands, or in the same exchange.
- **Payoff:** half the quarry, every fight he Takes.
  - Line A: 14/16 at R9, 42/50 at R12, 126/153 at R15.
  - Line B: 14/16, 46/55 and 215/261 (late Pelts land on him).
  - Golden, he takes the whole quarry. That is the tribe's highroll card (moment 1 below).
- **Permanence:** permanent. The scout previews it on each enemy.
- **Enabler:** Takes for the Glutton, the Lodger, Ermeline and the Laird. A grown body for Young Brock to inherit.
- **Concentrates:** yes, on himself. The first lesson in "big prey or sure prey".
- *Hook: he did all of it himself. Ask anyone. Don't ask anyone.*

**Wick** (2/2). *Least Weasel, Runner for the Pack.* Pack. After this joins a kill: gain a quarter of the target's stats permanently.
- **Condition:** he joins a pack attack that kills its target. He needs a leader beside him, before him in reading order.
- **Payoff:** a quarter of each kill he joins. Line A: 11/11 at R9, 26/31 at R12, 70/84 at R15. He joins, so the target never hits him back.
- **Permanence:** permanent.
- **Enabler:** needs Brother Wolf or another leader beside him. With Grizel he gains twice from every kill. The Pack line's first growth, before Grizel.
- **Concentrates:** partly, on himself. The weasel steals scraps and never gets bitten.

**Young Brock** (2/3). *Badger, Heir to the Sett.* When a Hunter beside this is sold: gain its stats permanently.
- **Condition:** you sell a Hunter in a slot beside him. Move it there first.
- **Payoff:** the sold Hunter's whole stats. On line B he inherits Russet at R9 (7/8). Later, selling a 46/55 Nip beside him to make room keeps all 101 stats.
  - Golden, he reaches every slot next to him (up to four), but doesn't double. This is the breaker's fix: golden T1s are the commonest goldens, and doubling a sold 300/365 Glutton was a free ×2.
- **Permanence:** permanent.
- **Enabler:** turns a slot change into no loss. It makes the Glutton or a grown Taker movable onto a better card.
- **Concentrates:** yes. Two grown Hunters become one.
- *Hook: will inherit four hundred years of tunnels and a family of foxes who have never paid rent.*

### Tier 2

**Sable** (2/3). *Stoat, of the Ermine Court, in Summer Brown.* Quarry. Start of Combat: gain its quarry's Attack. Take: gain half the quarry's stats permanently.
- **Condition:** a quarry across her. Her strike is her own Attack plus its Attack, for this fight.
- **Payoff:** she trades up. At R9 a 17/21 Sable across their 24/29 carry swings for 41.
  - Line A: 7/8 at R6, 17/21 at R9, 53/65 at R12, 171/211 at R15.
  - Line B: 20/25, 57/70 and 221/270. She is the biggest unit on both lines until the Glutton passes her at R11–R12.
  - The breaker's note holds: alone she rarely kills a Health-heavy unit. With a joiner or Agnes, the trade works. Her scout preview shows "trades alone" or "needs a joiner".
  - A half strike was tested: line B R12 1.12× → 1.04×, R15 1.36× → 1.24×. Keep full Attack.
- **Permanence:** the strike lasts the fight; the Take is permanent.
- **Enabler:** a Take every fight from tier 2. The usual Pelt target before the Glutton.
- **Concentrates:** yes, early. The everyday surprise: a 2/3 stoat swings for 26.
- *Hook: the Court's summer assassins dress in brown. They are counting the days to ermine.*

**The Toll-Bard** (2/4). *Pine Marten, Keeper of the Lane Songs.* Quarry. After its quarry attacks: get 1 gold next turn. Twice a fight.
- **Condition:** his quarry attacks anyone. A big quarry swings early, so it pays.
- **Payoff:** about 1–2 gold a turn. Not on the model's lines, so not measured.
- **Permanence:** economy.
- **Enabler:** gold for tier-ups and Russet's copies. His quarry is chosen for economy, not for a trophy, which is a lane decision.
- **Concentrates:** no.
- **Kept although flat** (breaker, Engine "five flat cards"): gold buys units whose size rises with tier, so its value doesn't fall behind the field as a flat +1/+1 does.
- *Hook: any traveller may pass. Each pays in verse, or failing verse, in coin.*

**Mistress Russet** (3/3). *Fox, Poacher, Licensed After a Fashion.* Quarry. Take: your next shop has a copy, with half its buffs.
- **Condition:** her own quarry dies, and she makes the Take (first in reading order).
- **Payoff:** a copy of the quarry's card in your next shop, with half its **permanent** buffs. You still pay for it.
  - Early, copies are near base size: 3/4 to 4/6 by R8, about 0.6 a fight.
  - Late: about 36 stats for 3 gold on average at R12, about 107 at R15, and about 305 when the quarry was their carry.
  - Placed across their front-row carry at R12 (80/97), she makes the Take in 52% of fights. The copy is about 42/51 for 3 gold. A median unit then is about 76 stats.
  - Golden: all its buffs. With the Laird: two copies.
- **Permanence:** a permanent unit, if you buy it.
- **Enabler:** denies their triple (the copy comes out of the pool), and finds triples for you.
- **Concentrates:** no; it's an answer that pays.
- **The model reports her copies but doesn't buy them**, so line B's numbers leave this out.
- *Hook: it was already out of its pen. She was only showing it the way.*

### Tier 3

**Brother Wolf** (3/5). *Wolf, Under a Vow.* Pack. Units beside this attack first; this joins both.
- **Condition:** units beside him.
- **Payoff:** his neighbours lead and he joins each, so he never takes a hit back. With Grizel he gains from both kills: line A 7/10 at R9, 26/32 at R12, 84/104 at R15.
- **Permanence:** the order is a fight effect; Grizel's gains are permanent.
- **Enabler:** turns Nip and Sable into pack leaders, which gives Wick and Grizel their joins and lets Agnes halve the Takers' hit back.
- **Concentrates:** partly: two focused attacks a cycle.
- *Hook: he swore on the old oak never to strike first. He does not consider this striking first.*

**The Lodger** (4/4). *Fox, Lodger in a Badger Sett, Pays No Rent.* After a Take beside this: gain half the quarry's stats permanently.
- **Condition:** a unit beside him makes a Take. He doesn't need to attack, or to survive the fight.
- **Payoff:** half of each neighbour's meal. In line B's F3, between Nip and Ermeline, he is 4/4 at R6, 14/15 at R9, 29/34 at R12 and 81/98 at R15.
  - At a quarter: line B R15 1.35× → 1.26×.
- **Permanence:** permanent.
- **Enabler:** two Quarry Takers beside him. This is Engine's pooled feeder (Feast) on one card, the breaker's suggestion.
- **Concentrates:** yes, on himself.
- **The breaker's loop is gone:** he no longer pounces, so he gains only when something dies, once per death.

**Old Lutra** (3/5). *Otter, Runner of the Reed Channels.* Quarry, wherever it stands. Take: gain half the quarry's stats permanently.
- **Condition:** the enemy across from her dies, even in their back row.
- **Payoff:** half the quarry. Line A 14/18 at R9 (B1, then out for Isegrim at R11). Line B 10/13 at R9, 49/60 at R12, 240/296 at R15, the second biggest unit.
- **Permanence:** permanent.
- **Enabler:** a back-row Taker. In B1 she hunts their B1, and leads the Glutton beside her into it (Carry's idea).
- **Concentrates:** yes.
- **Her reach is positional**, so it doesn't count against the any-row budget.
- *Hook: the heron customs men have searched him nine times. They have never once looked under the water.*

### Tier 4

**Madame Ermeline** (3/7). *Stoat, Court Dressmaker.* After each fight: get a Pelt of your biggest quarry.
- **Condition:** any fight. The biggest quarry your units marked counts, killed or not, so a losing board still gets its Pelt.
- **Payoff:** one Pelt a fight, a quarter of that unit. Line B: +3/+4 at R9, +13/+15 at R12, +45/+55 at R15.
  - Golden, two Pelts. With Isegrim, the biggest quarry is their carry, so a Pelt is a quarter of their carry.
- **Permanence:** permanent, on the Hunter you choose.
- **Enabler:** the tribe's growth that isn't win-gated (the breaker's "Takes depend on standing"). It feeds whichever Hunter needs it.
- **Concentrates:** yes, where you play it.
- **Her own body stays small** (6/10 at R15). Her reward is the Pelt.
- *Hook: her trims are the finest in the Court. She will not say where the ribbons come from.*

**Old Brock** (3/6). *Badger, Squire of the Sett.* Units next to this hunt the enemy across from this, wherever it stands.
- **Condition:** units next to him with no quarry of their own.
- **Payoff:** his neighbours gang up on the enemy across from him, with reach. In B2 that is their B2, where a back-row carry often stands.
  - The model, line B's R12 board against a strong field with their carry in B2: their carry is Taken in 0% of fights as built, and 45% with Brock in B2 (win 21% → 23%).
- **Permanence:** the hunt lasts the fight; the Takes it makes are permanent.
- **Enabler:** a positional answer, from Engine's sett. B2 is contested: Brock, the Glutton or Agnes.
- **Concentrates:** no: it focuses fire on theirs.
- **Splash:** he lends only the hunt. A non-Hunter next to him hunts but makes no Take.
- *Hook: the foxes are frightful, of course. But one must have somebody to dinner.*

**Grey Agnes** (4/6). *She-wolf of the Pack.* Pack. Your pack leaders take half the hit back.
- **Condition:** pack attacks: a leader with Pack units beside it.
- **Payoff:** a leader takes half the counter-hit, so it lives to make its Take. Sable's even trades become wins. Line A, B2 from R7 to R9 (7/9), then the Glutton takes her slot.
- **Permanence:** a fight aura.
- **Enabler:** Sable and Nip as leaders beside Brother Wolf or Wick.
- **Concentrates:** it lets a leader carry hold its stats.
- *Hook: raised every cub in the valley, half of them not wolves. They all still call her on Sundays.*

### Tier 5

**Grizel** (5/8). *Wolf, Mother of the Pack.* Pack. After your pack kills: its attackers gain a quarter of the target's stats permanently.
- **Condition:** a pack kill. Every attacker in it gains, the leader and each joiner.
- **Payoff:** Brother Wolf, Wick and Isegrim grow from her: 84/104, 70/84 and 52/65 at R15 on line A.
  - Line A's low roll, without Grizel and with Isegrim late, is 0.79× at R12 and 0.60× at R15 (0.98× and 1.06× with both).
  - At half, line A runs hot: 1.36× at R12, 1.69× at R15.
- **Permanence:** permanent.
- **Enabler:** the Pack line's engine.
- **Concentrates:** no: she spreads growth across the pack.
- **Her own body stays small** (8/11). Her reward is the pack's growth.

**The Mountain Glutton** (5/7). *Wolverine, Saga Mercenary, Here for the Food.* Pack. After each Take: gain half the quarry's stats permanently.
- **Condition:** any of your Takes, while the Glutton is on the board. He doesn't need to attack.
- **Payoff:** half of every meal: the carry.

  | Line | Bought | Next round | Two rounds on | R15 |
  |---|---|---|---|---|
  | A | R10, 7/9 | 30/37 | 66/81 (28%, biggest) | 357/438 (40%) |
  | B | R9, 7/9 | 22/28 | 42/52 (26%, biggest) | 309/379 (28%) |

  (A 200-game run; the board tables use the saved 400-game output.)

  - **No Cleave** (the breaker's top must-fix). With Cleave on joins, line A's R12 board beat the strong Battlegrounds-shaped field 70% instead of 4%. Leading from B1 with Cleave, 21%.
  - Golden: the whole quarry. Line A's strong roll (a round early, golden Sable R6, golden Glutton R11) is 1.51× at R12 and 1.85× at R15, with the Glutton at 52%.
- **Permanence:** permanent.
- **Enabler:** Takers, and Lutra or Isegrim beside him to give him a fight to join.
- **Concentrates:** yes. The tribe's carry.
- *Hook: signed on for the plunder. Is now mostly there for the catering.*

### Tier 6

**The Laird of the Sett** (6/9). *Badger, Keeper of the Old Rights.* Your 'Take:' text triggers twice.
- **Condition:** your Takes, on cards whose text starts "Take:" (Nip, Sable, Russet, Lutra).
- **Payoff:** each Taker gains its share twice; Russet gives two copies. "After each Take" text (the Glutton, the Lodger) fires once, and the words now say so.
  - Line B with him: 1.12× at R12, 1.20× at R13, 1.36× at R15. Without him: 1.00× and 0.93×.
  - The all-Quarry half alone: 1.10×, 1.16×, 1.24×, with the Glutton at 47% of the board. Both halves (Wild): 1.22×, 1.41×, 1.71×. So I kept the doubling only.
- **Permanence:** permanent (it doubles permanent shares).
- **Enabler:** the Brann of the tribe. Hunt or harvest: he is the harvest.
- **Concentrates:** no: it spreads across the Takers.
- **His own body stays small** (9/12 at R15). A Pelt can fix that.
- *Hook: the old rights are clear. Everyone faces whoever stands opposite. He has the papers somewhere.*

**Old Isegrim** (7/10). *Wolf, Constable of the Wold.* Start of Combat: this and units beside it hunt the biggest enemy, wherever it stands.
- **Condition:** units beside him with no quarry of their own. The Glutton is best.
- **Payoff:** his gang goes for their carry from the first cycle, in either row.
  - Against plain boards their carry falls every fight (line A at R12 and R15). It doesn't win the fight alone: line A beats the strong Battlegrounds-shaped field 2% at R12 and 39% at R15.
  - Each kill is a Take for the Glutton, a Pelt for Ermeline, and a pack kill for Grizel. His own body is 13/17 at R12 and 52/65 at R15 (Grizel's quarters).
  - No Health cut (Engine's idea): a ¼ cut lifts those wins to 36% and 100%. That is a lever, not the default.
- **Permanence:** the hunt lasts the fight; its feed is permanent.
- **Enabler:** the tribe's one any-row answer (`fundamentals.md` question 2). Hunt or harvest: he is the hunt.
- **Concentrates:** no: it focuses fire on theirs. Wolves really do take down a moose.

---

## The tribe

### Engine and rate parameter

**The engine is the Take.** A Hunter gains a share of the enemy it marked and killed. The share is a fraction of the field, so Hunters grow at the field's rate, and faster when they eat the lobby leader.
- Each Taker eats its own lane, so lanes differ (Nip half, Wick a quarter of his joins).
- The Glutton adds half of every Take on one unit: the carry.
- Ermeline's Pelts add growth that doesn't need a win.
- The Laird doubles the Takers' shares.

**Rate parameter: s, the Take share. Default ½ ("half"). The quarter cards (Wick, Grizel, Pelts) are s/2.** Sweep ⅓ to 0.6 in the harness; the card words follow what wins.

| s | A R6 | A R9 | A R12 | A R15 | B R6 | B R9 | B R12 | B R15 |
|---|---|---|---|---|---|---|---|---|
| ⅓ | 0.98 | 0.94 | 0.71 | 0.65 | 1.00 | 0.91 | 0.73 | 0.74 |
| 0.4 | 1.01 | 0.98 | 0.79 | 0.78 | 1.03 | 0.97 | 0.86 | 0.97 |
| **½ (default)** | **1.08** | **1.09** | **0.98** | **1.06** | **1.09** | **1.09** | **1.12** | **1.36** |
| 0.6 | 1.12 | 1.18 | 1.12 | 1.32 | 1.11 | 1.18 | 1.34 | 1.65 |

(Board ÷ the target median.) The response is gentler than an internal doubler's: a step of 0.1 in s moves R15 by about 1.2–1.4×. Early rounds barely move, because the +1/+1 floor sets early Takes.

**Secondary dials**, in the order to turn them (model, line ÷ target at R12 / R15):

| Dial | Default | Tested | Result |
|---|---|---|---|
| The Glutton's share | ½ | ⅓ / the whole | A 0.91 / 0.88 at ⅓ (biggest 30%), 1.26 / 1.58 at the whole (58%). B 1.01 / 1.17, and 1.39 / 1.76 |
| Grizel's share | ¼ | ½ | A 1.36 / 1.69 (B unchanged) |
| The Laird | ×2 | ×1.5 / none | B 1.06 / 1.12 at ×1.5, 1.00 / 0.93 with none |
| The Lodger's share | ½ | ¼ | B 1.05 / 1.26 |
| Wick's share | ¼ | ½ | A 1.09 / 1.22 |
| Nip's share | ½ | ⅓ | A 0.87 / 0.91, B 1.03 / 1.22 |
| Sable's strike | full | half | B 1.04 / 1.24 |
| Isegrim's Health cut | none | ¼ | wins against strong Battlegrounds-shaped boards: 2% → 36% (R12), 39% → 100% (R15) |

Differences under about 10% are path noise; the lines are scripted.

### When it comes online (board ÷ target)

| Line | R3 | R4 | R5 | R6 | R7 | R8 | R9 | R10 | R11 | R12 | R13 | R14 | R15 | R16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A, the Pack | 0.93 | 0.84 | 1.20 | 1.08 | 1.35 | 1.13 | 1.10 | 1.00 | 0.96 | 1.00 | 1.03 | 1.08 | 1.10 | 1.13 |
| B, Open Season | 0.94 | 1.02 | 0.87 | 1.09 | 1.31 | 1.09 | 1.09 | 1.02 | 1.03 | 1.09 | 1.18 | 1.27 | 1.35 | 1.40 |

(From a 200-game run; the saved output, at 400 games, differs by up to 0.04.)

- **The Take is on from turn 1, but small.** The +1/+1 floor keeps Hunters level to R6.
- **R7 is high** (1.31–1.35×). Most of that is Harvest Supper landing at R7: with Supper at R9, line A's R7 is 1.22×. The harness should check the round 8 leader bar here.
- **The engine piece is behind at once, level the next turn, clearly ahead after.** The Glutton arrives as a 7/9, smaller than a median unit. He passes one the next round, and two rounds after he's bought he is the biggest unit on the board (R11 on line B, R12 on line A).
- **Line B is clearly ahead from R13** (1.18× → 1.40×); line A stays level (1.00–1.13×). The tempo line levels; the engine line pulls ahead.

### The decision it creates

Every turn: **big prey or sure prey, lane by lane.**
- **Each Taker gets its own lane's share.** The scout shows each enemy's price ("Take: +36/+44") and whether the Taker trades alone. Put Nip across a unit he can kill with a joiner; put Sable across a bigger one she can trade with. Put Russet across the unit whose copy you'd buy.
- **Reading order.** The first Hunter in reading order makes the Take. Takers stand in the front row, ahead of Isegrim.
- **B2 is contested.** Old Brock there reaches their B2 carry. The Glutton there joins Isegrim or Lutra. Agnes there halves the leaders' hit back.
- **Hunt or harvest at tier 6.** Isegrim answers their carry and feeds the Glutton. The Laird doubles every Taker. Both fit, but a seven-slot board has room for few enablers.
- **Where the Pelt goes.** The Glutton while he holds under about a third of the board; after that, a Taker that will meet big prey next fight.
- **Who to sell beside Young Brock.** Moving a grown Hunter beside him before you sell it keeps all its stats.
- **Whether to buy Russet's copy.** Their carry's copy at half its buffs, or the shop's tier piece.

### Carry route: the Glutton behind the Pack (line A)

- Sable, Brother Wolf, Nip and Wick lead and join in the front. Grizel feeds every pack attacker. Agnes holds the leaders mid-game.
- At T6, Isegrim's gang (Isegrim and the Glutton beside him) hunts their carry every fight.
- The Glutton takes half of every Take: 28% of the board at R12, 40% at R15.
- Holders: the back row (protected while the front stands), Pack joins (no hit back), Agnes.
- **Line A:** 519 at R12 (0.98×), 1,902 at R15 (1.06×). It beats median boards 100% and the strong field 0–4% at R12 and 19–46% at R15.

### Non-carry route: Open Season (line B)

- Four Takers (Sable, Nip, Lutra, Russet early) eat their own lanes. The Lodger eats half of his neighbours' meals. Ermeline's Pelts spread where they're needed. The Laird doubles the Takers.
- No unit is over 30%: at R15 the Glutton, Lutra, Sable and Nip hold 476–685 stats each (20–28%).
- **Line B:** 600 at R12 (1.13×), 2,406 at R15 (1.34×). It beats median boards 100%, the strong field 27–34% at R12 and 100% at R15.

### Answers to other tribes' carries

- **Old Isegrim:** his gang hunts the biggest enemy in either row. It is the tribe's one any-row answer.
- **Old Brock:** his neighbours reach the enemy across from him, usually their B2. Positional.
- **Old Lutra:** reaches the enemy across from her in their back row. Positional.
- **Sable:** her strike adds her quarry's Attack, so she trades with a big front unit.
- **Mistress Russet:** copies their carry and takes the card out of the pool, which denies the triple.
- **Every answer pays.** Killing their carry is a Take worth half of it to the Glutton.

### Weak points

- **Low rolls.** Line A without Grizel and with Isegrim at R13: 0.79× at R12, 0.60× at R15. Line B without the Lodger and with the Glutton at R12: 0.69× and 1.02×. Within an order of magnitude, which meets the owner's fun-first bar (09c).
- **Late pieces.** Every piece two rounds late: 0.70–0.97×. A round early: 1.17–1.47×. The shape holds.
- **Three enablers stay small:** Grizel 8/11, Ermeline 6/10 and the Laird 9/12 at R15, when a median unit is about 256. Their payoff is what they give. The harness should judge them by payoff, not body, as Birds asked.
- **Health-heavy and shielded boards.** A Take needs a kill. A Shield on their carry delays the kill by a hit, and a wall of Health starves Nip. Pelts and the Lodger keep growing.
- **Against Bog.** A Mired Hunter bites the toad, not its quarry (Bog's own note), so its lane's Take is lost.
- **The mirror.** Two Hunter boards eat each other: line A grows ×1.59 a round, line B ×1.86, against the field's ×1.5. The lever is the Laird at ×1.5 (mirror ×1.74).
- **The parasitic risk.** Hunters grow at the field's rate. If the harness's field compounds slower than the target, Hunters fall with it, and if it runs hot they run hot. Measure them against the harness's field, not against this model's.
- **Supply.** A second Hunter player takes Gluttons and Sables.

### Highroll moments

1. **The fox cub that ate the moose.**
   - Round 13, line A on a good roll: golden Little Nip is 131/158 in F3, with Brother Wolf beside him.
   - The lobby leader's carry, 239/292, stands across from Nip. It is also the biggest enemy, so Isegrim's gang hunts it too.
   - Nip leads, Brother Wolf joins, and the carry falls. Nip is first in reading order, so it's his Take. Golden, he takes the whole quarry: he lands at 370/450.
   - The golden Glutton takes the whole quarry too. In the model he goes from 283/346 to 511/625 the next round.
   - The board goes from 1,509 (1.89× the median) to 2,464 the next round (2.06×).
2. **"I bought their carry."**
   - R12: their 80/97 carry stands in F3, across Mistress Russet. Brother Wolf joins her, and she makes the Take in about half of fights.
   - Next shop: a copy of their carry's card with half its permanent buffs, about 42/51, for 3 gold. Its card is out of the pool, so their triple waits.
   - Golden Russet copies all its buffs. With the Laird you get two copies.
3. **The hue and cry** (common late, line A).
   - R13: line A meets a lobby leader 1.35× its size. It wins only 14% of those fights.
   - Isegrim's gang Takes their 161/198 carry in every fight. The Glutton gains +120 to +300 that fight, win or lose.
   - Against a leader 1.6× its size it wins none, and still eats their carry every time.

**The everyday surprise is Sable.** A 2/3 stoat across a 24/30 unit swings for 26, and with a joiner it comes home 14/18.

**The tail.** No common line runs away: across 400 games a line, no board reaches 2× its line's median. The highest is 2.33× the target at R15, 1.8× its line's median. Scripted strong rolls reach 1.5–2.1× the target, and the model's top 1% (golden Nip at R5, Sable R6, Glutton R10, Laird R11) reaches 2.45× at R12 and 3.14× at R15. The owner allows a rare top 1% at up to 10× (09d). If the harness wants a longer tail, the first lever is the golden Glutton at the whole quarry with two Takes doubled (it's already 1.85× on a strong roll).

---

## Boards at R6 / R9 / R12 / R15

The board is 7 slots. Win rates are against four plain fields: **median even** (seven equal units), **median BG** (Battlegrounds-shaped, a 34% carry), and the same two at **strong** (1.35×). R6 shows the win rate against the mixed field.

### Line A, the Pack (`line_hunters_tempo`)

Arrivals: Wick R1, Nip R2, Sable R3, Brother Wolf and Lutra R5 (Wick to F4), Agnes and Young Brock R7, Grizel R8, the Glutton R10 (Agnes out), Isegrim R11 (Lutra out). Tier-ups T2 R2, T3 R4, T4 R6, T5 R8, T6 R11.

| Round | Board (×target) | Biggest | On the board | Wins: median even / BG / strong even / BG |
|---|---|---|---|---|
| R6 | 54 (1.08) | Sable 7/8, 28% | Sable, Nip 5/6, Wick 5/5, Lutra 4/6, Brother Wolf 3/5 | 67% (mixed field) |
| R9 | 173 (1.10) | Sable 17/21, 22% | Sable, Lutra 14/18, Nip 14/16, Wick 11/11, Brother Wolf 7/10, Grizel 7/10, Agnes 7/9 | 100 / 100 / 53 / 57% |
| R12 | 519 (0.98) | Glutton 65/80, 28% | Glutton, Sable 53/65, Nip 42/50, Brother Wolf 26/32, Wick 26/31, Isegrim 13/17, Grizel 8/11 | 100 / 100 / 0 / 4% |
| R15 | 1,902 (1.06) | Glutton 342/420, 40% | Glutton, Sable 171/211, Nip 126/153, Brother Wolf 84/104, Wick 70/84, Isegrim 52/65, Grizel 8/11 | 100 / 100 / 19 / 46% |

Final layout: F1 Sable, F2 Brother Wolf, F3 Nip, F4 Wick; B1 Isegrim, B2 the Glutton, B3 Grizel. Takes: 2.6–2.9 a fight.

### Line B, Open Season (`line_hunters_engine`)

Arrivals: Nip R1, Young Brock R2, Sable R3, Russet R4, the Lodger and Lutra R6, Ermeline R7, the Glutton R9 (Russet sold beside Young Brock), the Laird R11 (Young Brock out). Tier-ups T2 R2, T3 R5, T4 R7, T5 R9, T6 R11. Harvest Supper at R7, R9 and R11 on both lines.

| Round | Board (×target) | Biggest | On the board | Wins: median even / BG / strong even / BG |
|---|---|---|---|---|
| R6 | 55 (1.09) | Sable 7/9, 28% | Sable, Nip 6/6, Lodger 4/4, Lutra 3/5, Russet 3/3, Young Brock 2/3 | 61% (mixed field) |
| R9 | 171 (1.09) | Sable 20/25, 26% | Sable, Nip 14/16, Lodger 14/15, Lutra 10/13, Glutton 7/9, Young Brock 7/8, Ermeline 5/9 | 100 / 100 / 0 / 80% |
| R12 | 600 (1.13) | Glutton 74/90, 27% | Glutton, Sable 57/70, Lutra 49/60, Nip 46/55, Lodger 29/34, Laird 9/12, Ermeline 6/10 | 100 / 100 / 34 / 27% |
| R15 | 2,406 (1.34) | Glutton 308/377, 28% | Glutton, Lutra 240/296, Sable 221/270, Nip 215/261, Lodger 81/98, Laird 9/12, Ermeline 6/10 | 100 / 100 / 100 / 100% |

Final layout: F1 Sable, F2 Nip, F3 the Lodger, F4 Ermeline; B1 Lutra, B2 the Glutton, B3 the Laird. Takes: 2.8–3.0 a fight. Pelts a turn: +3/+4 at R9 (on the Glutton), +13/+15 at R12 and +45/+55 at R15 (on Nip).

### The other lines and checks (board ÷ target at R6 / R9 / R12 / R15)

| Line or check | A | B |
|---|---|---|
| Low roll (A: no Grizel, Isegrim R13; B: no Lodger, Glutton R12) | 1.08 / 0.91 / 0.79 / 0.60 | 1.05 / 0.91 / 0.69 / 1.02 |
| Strong roll (a round early; golden Sable R6, golden Glutton R11) | 1.51 / 1.38 / 1.51 / 1.85 | 1.46 / 1.41 / 1.73 / 2.07 |
| Top 1% (golden Nip R5, Sable R6, Grizel or Glutton R9–R10, Glutton or Laird R11) | 1.67 / 1.66 / 2.08 / 2.66 | 1.64 / 1.64 / 2.45 / 3.14 |
| Every piece from R5 a round early | 1.41 / 1.25 / 1.17 / 1.21 | 1.36 / 1.24 / 1.32 / 1.47 |
| A round late | 1.04 / 0.95 / 0.80 / 0.93 | 0.77 / 0.92 / 0.86 / 1.12 |
| Two rounds late | 0.72 / 0.86 / 0.70 / 0.77 | 0.77 / 0.82 / 0.72 / 0.97 |
| Spread across 400 games, R15 (p10 / p50 / p90; max) | 0.70 / 1.01 / 1.34; 1.93 | 0.96 / 1.27 / 1.69; 2.33 |

**Standing** (the breaker's "Takes depend on standing"):
- **Takes are nearly flat.** Line B's R12 board against fields of 0.67×, 1.0× and 1.5× its own strength makes 2.42, 2.83 and 2.94 Takes a fight (wins 39%, 71%, 93%). Takes come early in the fight, and trophies land whether the Hunter survives or not.
- **Behind at R8** (boards cut to 0.75×): A goes 0.87 → 0.96 by R15, B 0.85 → 1.26. Deficits recover; no losing spiral.
- **Ahead at R8** (1.3×): A goes 1.41 → 1.13, B 1.37 → 1.37. A lead settles; it doesn't run away.
- So a round 8 lead doesn't decide the game (`fundamentals.md` §1.11). The harness should still check the round 8 leader's win share.

---

## Where it could run away, and the lever for each

| Risk | Why it's bounded | Lever if the harness shows it |
|---|---|---|
| Trophies snowballing inside a fight | They land after the fight; the break-even plain multiple fell from about 2× to about 1.3× | — (the rule is the fix) |
| Cleave on the carry deciding fights | No Hunter has Cleave; joins never cleave | — |
| The Glutton over 40% late on line A | Line B keeps him at 28%, because the Pelts spread | Glutton at ⅓ (A R15 30%, 0.88×) |
| Line B 1.3–1.4× late | It is the engine line: "clearly ahead after" is the brief. Strong rolls reach 2.1× | The Laird at ×1.5 (1.12× at R15); then s at 0.4 |
| The Hunter mirror at ×1.86 a round | Two Hunter boards eat each other's growth | The Laird at ×1.5 (×1.74); then s |
| Isegrim always killing the carry | It feeds, but doesn't win alone (2% / 39% against strong) | Gang size: "beside" stays; golden "next to" is the only widening |
| Russet's copy as stats for gold | Permanent buffs only, half; a slot and 3 gold; one copy (two with the Laird) | Copy at a third; or no copies of golden units |
| Pelts flooding a hand | One a fight (two golden) | Merge Pelts of one quarry into one card |
| Young Brock stacking a sold carry | It moves stats, it doesn't add them | — |
| The R7 bump (1.31–1.35×) | Mostly Supper timing; it settles by R9 | Supper at R8 for Hunters lines; then Sable 2/2 |

---

## Harness line policies

Card ids are `content/units/*.json` ids; `pelt` is the new token spell and `harvest_supper` the existing spell. The required fields match `tools/sim/line_profiles.json` on `ideation/harness`. The extra fields are the bot policies these lines need. The current loader ignores them, and the bot needs them built (below).

**The two lines swap today's base strategies:** the tempo line becomes the Pack (`hunters_pact`), and the engine line becomes Open Season (`hunters_open_season`). Today it's the other way round.

```json
{
  "line_hunters_tempo": {
    "tribe": "Hunters",
    "base_strategy": "hunters_pact",
    "engine": false,
    "priority": ["old_isegrim", "mountain_glutton", "grizel", "sable", "brother_wolf", "little_nip", "wick",
                 "grey_agnes", "old_lutra", "young_brock", "madame_ermeline", "laird_of_sett", "lodger",
                 "mistress_russet", "toll_bard", "old_brock"],
    "climb_schedule": [2, 4, 6, 8, 11],
    "save_threshold": 0,
    "save_until": 0,
    "priority_weight": 14,
    "tribe_weight": 4,
    "save_rule": "Spend out every turn. A climb turn before R7 leaves one unit unbought; there is no held reserve.",
    "harvest_supper_rounds": [7, 9, 11],
    "keep": ["mountain_glutton", "old_isegrim", "grizel", "sable", "brother_wolf", "little_nip", "wick"],
    "sell_first": ["young_brock", "grey_agnes", "old_lutra"],
    "placement": {
      "front": "sable F1, brother_wolf F2, little_nip F3, wick F4. Takers across the scouted enemy they can kill: sable across the biggest front enemy where her Attack plus its Attack reaches its Health, little_nip across one he kills with a joiner",
      "back": "old_isegrim B1, mountain_glutton B2 beside him, grizel B3. Before R11: old_lutra B1, grey_agnes B2",
      "reading_order": "Takers stand ahead of old_isegrim, so their Take comes first"
    },
    "heir": "before selling a grown Hunter, move it beside young_brock",
    "pelt_target": "none (no Ermeline on this line)"
  },
  "line_hunters_engine": {
    "tribe": "Hunters",
    "base_strategy": "hunters_open_season",
    "engine": true,
    "priority": ["laird_of_sett", "mountain_glutton", "madame_ermeline", "sable", "little_nip", "old_lutra",
                 "lodger", "mistress_russet", "young_brock", "old_isegrim", "old_brock", "grizel", "brother_wolf",
                 "toll_bard", "wick", "grey_agnes"],
    "climb_schedule": [2, 5, 7, 9, 11],
    "save_threshold": 0,
    "save_until": 0,
    "priority_weight": 14,
    "tribe_weight": 4,
    "save_rule": "Spend out every turn. A climb turn before R7 leaves one unit unbought; there is no held reserve. Play every Pelt the turn it arrives.",
    "harvest_supper_rounds": [7, 9, 11],
    "keep": ["mountain_glutton", "laird_of_sett", "madame_ermeline", "sable", "little_nip", "old_lutra", "lodger"],
    "sell_first": ["young_brock", "mistress_russet"],
    "placement": {
      "front": "sable F1, little_nip F2, lodger F3 between two Takers, madame_ermeline F4 (mistress_russet F4 until R8). Takers across the scouted enemy they can kill, as line_hunters_tempo",
      "back": "old_lutra B1 across their B1, mountain_glutton B2 beside her, laird_of_sett B3 (young_brock B3 until R10)",
      "old_brock": "if bought and their carry stands in their B2: old_brock B2, mountain_glutton B3, laird_of_sett to F4"
    },
    "heir": "at R9 sell mistress_russet beside young_brock; later, sell a grown Hunter only beside him",
    "pelt_target": "mountain_glutton while it holds under 35% of the board; otherwise the smallest of little_nip, sable and old_lutra",
    "poach": "buy the copy when its stats are at least 1.5x the best unit in the shop, or it completes a triple; the model reports copies but never buys them"
  }
}
```

**Bot needs for both lines:** scouted Quarry placement (who stands across whom), the reading-order rule for Takers, the Pelt target, the heir sale and the poach buy. Without scouted placement Hunters look weak for the wrong reason: Old Brock's B2 placement alone moved their carry's Take rate from 0% to 45%.

**The sims to ask the harness for** (the breaker's list, plus mine):
1. Takes a fight by standing, and the round 8 leader's win share for both lines.
2. Trophies during against after the fight, on the real engine.
3. The Glutton with and without Cleave, and joins that cleave or don't, at R12 and R15.
4. The Hunter mirror with and without the Laird.
5. The s sweep at ⅓, 0.4, ½ and 0.6.
6. Isegrim's gang against boards that move their carry.

---

## The breaker's points: accepted and rejected

| Breaker point | Call | How or why |
|---|---|---|
| Shared, must fix: Cleave on the carry decides fights | **Accepted** | No Hunter has Cleave. Measured: line A's R12 board against the strong Battlegrounds-shaped field wins 4% without Cleave, 70% if joins cleave, 21% leading from B1 with Cleave |
| Shared, must fix: does Cleave work while joining? | **Accepted, decided: joins never cleave** | The breaker's lean. Logged for Track B: its `CombatDamage.cleave` currently runs over joiner hits too (`combat.gd` on `ideation/mechanics`) |
| Shared, must fix: models report boards after their own fight | **Accepted** | This model measures every board before it fights, and its Takes come from those fights |
| Shared, must fix: Hunters and Bog share one mechanic | **Accepted, settled with Bog** | Hunters grow from the kill; Bog grows from the bite (Soak). Both syntheses say so. Both land gains at the next Start of Turn with a pending badge |
| Shared, should fix: the any-row budget | **Accepted** | Isegrim is the only any-row Hunter. Old Brock and Lutra are positional |
| Shared, should fix: Takes depend on standing | **Accepted, measured** | 2.42 / 2.83 / 2.94 Takes at 0.67× / 1.0× / 1.5×. Ermeline's Pelt isn't win-gated. Boards behind at R8 recover |
| Shared, note: T4–T6 enablers stay paper | **Accepted, partly** | Isegrim grows (52/65) and the Glutton is the carry. Grizel, Ermeline and the Laird stay small; their payoffs are listed with their measured worth. A Pelt can grow any of them |
| Wild, must fix: the Laird's text says the opposite of its ruling | **Accepted, changed** | "Your 'Take:' text triggers twice." The all-Quarry half is cut: alone it pushed the Glutton to 47% for less growth (1.24× at R15), and with the doubling it reached 1.71× |
| Wild, must fix: the Lodger's every-cycle pounce | **Accepted, fixed another way** | Pounce leaves the slice (Engine's call). The Lodger gains half of a neighbour's Take: once per death, only when something dies |
| Wild, should fix: Agnes's text is wider than her rule | **Accepted** | "Your pack leaders take half the hit back" |
| Wild, should fix: early lead with win-gated growth | **Accepted** | Nip and Wick at 2/2. R6 is 1.08–1.09× (Wild had 1.28–1.29×). R7 is still 1.31–1.35×, mostly Supper timing. Lead checks above; the harness checks the round 8 bar |
| Wild, should fix: Russet copies buffs that were never permanent | **Accepted** | Permanent buffs only, the Queen of Elfland's rule (12.1.5). Half; golden all |
| Wild, should fix: golden Young Brock doubles your carry | **Accepted, fixed another way** | Golden reaches every slot next to him and doesn't double. Not the breaker's "and 2 gold": reach keeps the card's job and is still worth a triple |
| Wild, should fix: Pelts are free spells | **Accepted, partly** | One Pelt a fight now (it was one a Take). They aim at Hunters only. The Fairies synthesis removed Hex, so no live conflict. The cross-tribe synthesis should rule on Created spells before any "per spell cast" payoff comes back |
| Wild, note: Sable alone rarely kills | **Accepted** | Kept at full Attack (half: −7% at R12, −9% at R15). The preview shows whether she trades alone |
| Wild, note: the mirror with the Laird | **Accepted** | Measured: ×1.59 (A) and ×1.86 (B) a round against the field's ×1.5. Lever: the Laird at ×1.5 |
| Engine, must fix: behind until R15 when corrected | **N/A, lesson taken** | No Feast. This model has the breaker's correction built in |
| Engine, must fix: Feast stacks to a knife-edge | **N/A** | No Feast and no keyword grants on grants. The Lodger is the one pooled feeder |
| Engine, should fix: Agnes makes the back row untouchable | **N/A** | This Agnes grants nothing to the back row |
| Engine, should fix: five flat payoffs | **Accepted, except the Toll-Bard** | Nip, Wick, Russet and Ermeline pay shares. The Toll-Bard keeps gold, which doesn't fall behind the field |
| Engine, should fix: the aim decision is pooled | **Accepted** | Each Taker has its own share, so lanes differ |
| Engine, note: keyword chains need a layer order | **N/A** | No chain |
| Engine, note: Old Brock can be splashed | **Accepted, harmless** | He lends a hunt, not a payoff: a non-Hunter makes no Take |
| Breaker's synthesis: Isegrim's Health cut, meal read before the cut | **Rejected as default; kept as the first Isegrim lever** | With the cut, line A beats the strong field 100% at R15 (39% without). The gang already Takes the carry every fight; the cut would make it win the fight too |
| Breaker's synthesis: Feast on one or two cards | **Taken as a share, not a keyword** | The Lodger: half of a neighbour's Take |
| Carry, must fix: the engine needs 9–10 slots | **N/A** | Both lines fit seven slots; layouts above |
| Carry, must fix: the hold doesn't win; Cleave does | **Accepted** | No Cleave. The Glutton wins by size against median boards (100%), not by Cleave |
| Carry, must fix: Ermeline's refresh loop | **N/A** | No Titbits. Ermeline pays one Pelt a fight |
| Carry, should fix: the collar is a free cursor | **N/A** | No collar |
| Carry, should fix: Blood Gems five times over | **Accepted** | No Titbit, no tribe number |
| Carry, should fix: Isegrim aims everyone | **Accepted** | His gang only; a unit with its own quarry keeps it |
| Carry, note: four hidden rulings on the Alpha | **N/A** | No Alpha |
| Breaker's synthesis: Young Brock's Shield on the carry | **Rejected** | Young Brock stays the heir, the tribe's only "sell to concentrate" card. "Your carry gains Shield" needs a carry picker; the Bog and Hunters reviewers rejected auto-picked carries. The Glutton holds without it against median boards. Listed as a variation on Agnes |

---

## Cross-tribe notes

- **Hunters own the kill; Bog owns the bite.** Nothing in Hunters reads a bite; nothing in Bog reads a dead enemy's stats except the Peat King's fight-only copies (`bog-pass3.md`).
- **One pending-gain queue.** Hunters' trophies and Bog's Soak both land on the recruit copy at the next Start of Turn, with a pending badge in the fight. The engine should build it once.
- **Cleave and joins.** "Pack joins never cleave" is a combat rule, not a Hunter rule. Track B's Cleave currently cleaves joiner hits. Hunters have no Cleave, but any tribe with Cleave and a joiner would meet it.
- **"Triggers twice."** The Laird is the pool's only "triggers twice" card (the Bog synthesis has none). Keep it that way, and the mirror stays readable.
- **The any-row budget.** Hunters spend one (Isegrim). Old Brock and Lutra are positional.
- **Spells.** Pelts are Created 0-gold spells, aimed at Hunters only. The Fairies synthesis removed Hex. Any future "each spell you cast" payoff must say whether Created spells count.
- **Names.** Bog's new term "the Toll" sits close to the Toll-Bard. The wording guide forbids two cards sharing a name, not a card and a term. I keep the Toll-Bard; rename one if playtesters mix them up.
- **Parasitic engines.** Hunters' Take and Bog's Soak grow from the field. Both must be measured against a field that compounds, or they look weaker than they are.
- **Nothing auto-picks our carry.** "Biggest" on Hunter cards reads the enemy (Isegrim) or your quarry (Ermeline), never your own units. No tribe number, no collar.

---

## Engine support needed

**Exists** (pass 2): Quarry marking at the bell, lent quarries, Take, Pack with leaders and joiners, Pounce (kept as data only), the Russet poach, `harvest_supper`.

**Changed or new:**
1. **Share gains.** "Gain a fraction of a unit's bell snapshot", floored, at least +1/+1, written to the permanent layer through the pending-gain queue (with Bog).
2. **After-the-fight landing.** Gains made in the fight apply at the next Start of Turn, to the recruit copy, even if the unit fainted. The fight shows a pending badge.
3. **Triggers:** `after_join_kill` (Wick), `after_pack_kill` with its attackers (Grizel), `on_take` by an adjacent unit (the Lodger), `on_any_take` (the Glutton).
4. **Pelt token** (`pelt`): a 0-gold Created spell carrying a quarry's snapshot and portrait, Hunter targets only. Ermeline's `after_fight` picks the biggest marked quarry.
5. **Poach v3:** copy permanent buffs only, at a fraction (half; golden all). Two copies under the Laird.
6. **The heir:** on sell, an adjacent Young Brock gains the sold Hunter's current stats without the tribe bonus. Golden: neighbours.
7. **Sable:** Start of Combat, gain the quarry's Attack for the fight.
8. **The Laird:** a multiplier on 'Take:' effects only. Copies don't stack; golden ×3.
9. **Isegrim's lend:** at marking, his own quarry is the biggest enemy, with reach; he lends it to adjacent units without a quarry (golden: neighbours).
10. **Old Brock's lend:** at marking, his neighbours without a quarry take the enemy across from him, with reach.
11. **Agnes:** pack leaders take half the counter-hit (golden: a quarter).
12. **The Glutton:** data only (Pack plus `on_any_take`), no Cleave.
13. **Pounce:** removed from the slice's cards; the code stays.
14. **Combat rule:** joiner hits never cleave.
15. **Bodies:** the new stats in the card table.

**UI:**
- The scout: a paw print on each enemy with its Take price, and "trades alone" or "needs a joiner" on Sable's lane.
- The fight: a pending "+36/+44" badge on the Hunter when its Take happens.
- The Pelt: the prey's portrait and its size ("Pelt of Mrs Jay, +15/+16").
- The shop: Russet's copy marked "poached".

---

## Variations, if the panel wants another shape

- **Wild's Laird as the golden** ("All your units have Quarry. 'Take:' text triggers three times"). Both halves reached 1.71× at R15 on line B, so this is a highroll, not a default.
- **Young Brock's Shield on Agnes's golden** (Carry): "Your pack leaders take a quarter of the hit back. Your biggest Hunter has Shield." Not modelled.
- **Isegrim's Health cut** (Engine): "…and cut its Health by a quarter." The first lever if the harness's field moves its carry and Isegrim stops feeding.
- **The Glutton with Cleave when he leads only.** Line A's R12 board then beats the strong field 21%. Joins still never cleave.
- **Grizel at half** (A 1.69× at R15): the lever if the Pack line falls behind in the harness.

## Calls for the orchestrator to log

1. Trophies land after the fight, at the next Start of Turn, through the queue Bog's Soak uses. In the fight they show as a pending badge.
2. No Cleave on any Hunter, and Pack joins never cleave (a combat rule for Track B).
3. The Laird doubles 'Take:' text only; the all-Quarry grant is cut.
4. Pounce leaves the slice; the Lodger feeds on his neighbours' Takes.
5. Hunters grow from the kill; Bog from the bite (with the Bog synthesis).
6. Isegrim has no Health cut; it stays a dial.
7. Young Brock stays the heir; golden reaches further instead of doubling. Carry's Shield isn't taken.
8. Nip and Wick are 2/2.
9. Ermeline gives one Pelt a fight, of the biggest quarry, killed or not.
10. The harness's Hunter lines swap base strategies: tempo is the Pack, engine is Open Season.

## Model limits

- Scripted arrivals stand in for the shop, so lines are path-sensitive. Differences under about 10% are noise.
- The climb's gold is approximate: one unit fewer on climb turns before R7.
- Russet's copies are reported, not bought. The Toll-Bard and Old Brock aren't on either line; Brock is tested only as a board.
- The field boards are plain: no text, no Shields, no auras. They never move their carry away from Isegrim or Sable.
- It is not a lobby: no pool depletion, no second Hunter player, no hero Health, no Spoils gold.
- Combat is deterministic, so stat ratios decide fights: a board 1.35× ahead almost always wins. Real fights with text will be noisier.
