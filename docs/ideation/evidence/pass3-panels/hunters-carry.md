# Hunters, pass 3: the Alpha and the hunt (carry-and-answers angle)

9 Nov 2026. One designer of the Hunters panel (Track C, `docs/ideation/plan-scale-rework.md`), angle **carry and answers**. Written on paper. Nothing here has been played or simulated in Godot. The numbers come from a hand model (section 5) against the target shape. There is no price list.

**In short:** the pack feeds one chosen Hunter, the **Alpha**. It strikes from inside the pack, so it takes no hits back. Its growth compounds from round 8. The same pack aims that carry at the enemy's biggest unit.

## 0. What changes and why

| Today (pass 2) | Pass 3 | Owner direction it answers |
|---|---|---|
| 10 of 13 payoffs reset after each fight (Pack, Pounce, Glutton, Laird, Isegrim) | 9 of 16 cards give **permanent** stats, through one visible currency (Titbits). Five fight-only cards remain, and all of them hold or answer a carry | "Main payoffs permanent and visible" (fundamentals §1.7) |
| Growth is +1/+1 a Take, at most one Take per Hunter per fight. Linear and small | The Titbit's size grows **this game** (Grizel), and feeds come from Takes, joins, pounces and gold. That growth is cubic: about ×1.5 a round from round 8 to 15 | "power budgeting … very, very much too low" (9a) |
| No way to pick a carry. Concentration is only offensive (Pack, focus fire) | You **pick** the Alpha (a collar you move), **grow** it with Titbits, and **protect** it with Pack-joining, Shield and flanks that grow. Concentration pays because the carry holds its stats | "concentrating stats is always better … doubly if you have units that hold stats" (9a) |
| Answers aim at the enemy across, which lands by layout luck | Two any-row hunters aim at **the biggest enemy**: Old Lutra (one strike a fight) and Old Isegrim (all Hunters). Sable copies half her quarry's Attack, so she scales with the field | "answers must exist and be able to reach a carry sometimes" (9d: "beatable with scam units") |
| Placement: whom each Hunter marks | Whom each Hunter marks, plus where the Alpha sits, who flanks it, who leads it into the fight, and whether Old Brock or the Alpha gets B2 | "Make placement a real decision" (brief) |
| Combat-only Laird and Isegrim, one finisher per route | The Laird spreads Titbits wide (the non-carry route). Isegrim is the hunt for their carry (the answer route) | Tribe identity: focus fire |

Kept: Quarry, Take, Pack and Pounce, all 16 creatures, names and portraits, and the 3/3/3/3/2/2 tier spread. **Grizel and Grey Agnes swap tiers** (Grizel 5 → 4, Agnes 4 → 5). Grizel is the engine, and compounding has to start by round 8, which is tier 4 on a normal climb. Agnes's flank sharing only matters once the Alpha is big.

## 1. The engine: the Alpha and Titbits

### Alpha (new status)

*Reminder: your chosen Hunter. "Your Alpha" text grows it. Move it freely while recruiting.*

- You have one Alpha. Your first Hunter gets it. It shows as a collar on the unit, in the shop, in hand and on the scout.
- During the Recruit Phase, tap a Hunter and choose **Make Alpha**. This is free and has no limit. **Stats it has gained stay on the old Alpha.** Only new Titbits follow the collar.
- If the Alpha is sold, the collar goes to your Hunter with the most stats. With no Hunter, you have no Alpha, and Titbits are lost.
- Only Hunters can wear it. A non-Hunter player who splashes Grizel or Brother Wolf gets nothing from them. That keeps tribe payoffs in the tribe (fundamentals §2, Lollop lesson).
- *Why a collar and not "your biggest Hunter":* auto-picking the biggest locks the carry forever, so a later golden Glutton could never take over. *Why not a slot:* a fixed den slot leaves no placement decision. The collar gives two decisions, **which** unit and **when to switch**, and the switch costs you everything the old Alpha earned.

### Titbit (new keyword)

*Reminder: your Alpha gains +1/+1. Some cards make your Titbits bigger.*

- A Titbit is a stat packet. Its size starts at **+1/+1** and only grows: Grizel adds +1/+1 at each End of Turn, this game. The hero panel shows it live ("Titbit +8/+8"), the way Battlegrounds shows Blood Gem size.
- "Give your Alpha a Titbit" is **permanent**. In a fight, a living Alpha gains it at once and keeps it. A fainted Alpha still gets it on the recruit board. Engine: write it back after the fight, as Grizel does today.
- "Your Hunters each gain a Titbit" (the Laird) and "units beside your Alpha" (Agnes) use the same packet.
- **Similar to:** Battlegrounds' Quilboar Blood Gems, and "your Blood Gems give an extra +1/+1 this game" (Fearless Foodie, Sanguine Champion). The difference is that Hunters' gems all go to one chosen animal.

### Kept keywords, unchanged rules (`docs/ideation/content/hunters.md`)

- **Quarry:** the enemy across at the bell is marked. The mark is on the unit, and this attacks it whenever it can.
- **Take:** the quarry faints while this is on the board. One Take per death. Only Hunters make Takes.
- **Pack:** joins an attack beside it. Only the leader takes the counter-hit. No chains.
- **Pounce:** after a neighbour's quarry is hit, this attacks it at once, in any row, once a cycle.
- One rule is added for Pack on the Alpha: **an Alpha with Pack waits for a unit beside it to lead**. This is Brother Wolf's old behaviour, in Details. So it never leads while a partner can.

Shared keywords used (Track B, `ideation/mechanics`): **Shield** ("Prevents the first damage this would take each fight") and **Cleave** ("Attacks also hit the units beside the target"). Pass 3 extends Cleave to Pack joins (section 7).

### Why this holds a carry, in our combat model

The audit's carry test (`build/orchestrator/fundamentals/carry.txt`) found that a lone carry among small units loses to an even board of the same total. Overkill is wasted, and every small body soaks a whole exchange. "Takes no damage while attacking" was worth **+20.5 points** on Dozey, Shield +13.3 and Cleave +11.0 (`keywords.txt`). Pack-joining *is* "takes no damage while attacking", for as long as a partner leads. So a Hunter Alpha in B2, between two leaders, behind a standing front row:
- is not attacked while their front row lives;
- takes no counter-hits while B1 or B3 leads;
- has a Shield (Young Brock) against the first thing that does reach it;
- cleaves three enemies a join, if it is the Glutton.

It loses that cover in a set order:
1. its leaders die;
2. their front row dies;
3. an answer reaches the back row.

That order is the matchup the opponent has to solve.

## 2. The 16 cards

Payoff numbers assume a typical carry-line board. The Titbit size is **+3/+3 at round 9, +7/+7 at round 12 and +13/+13 at round 15**: one Grizel from round 8, a second from round 11 (section 5). "A turn" means one Recruit Phase and its fight. Bodies at tiers 4–6 move up to par where today's are hollow. If Track B rescales printed bodies, these follow it.

### Tier 1

**Little Nip** (fox cub). Tier 1, 2/3. *Kept body.*
- **Text:** Quarry. Take: give your Alpha a Titbit.
- **Golden (4/6):** Quarry. Take: give your Alpha two Titbits.
- **Condition:** his quarry (the enemy across) faints while he stands. About 0.6 a fight.
- **Payoff:** about +2/+2 a turn at R9, +4/+4 at R12, +8/+8 at R15. Cumulative from R1: about +7/+7, +17/+17, +39/+39. If he is your first Hunter he *is* the Alpha and feeds himself, which is today's Nip.
- **Permanence:** permanent.
- **Enabler:** Take count (the Laird, Russet), and an early Alpha to triple.
- **Concentrates:** yes.

**Wick** (least weasel). Tier 1, 2/3. *Kept body.*
- **Text:** Pack. After this joins an attack: give your Alpha a Titbit.
- **Golden (4/6):** Pack. After this joins an attack: give your Alpha two Titbits.
- **Condition:** a unit beside him leads an attack. About 1.5 joins a fight, win or lose.
- **Payoff:** +5/+5 a turn at R9, +11/+11 at R12, +20/+20 at R15. Cumulative about +16/+16, +42/+42, +96/+96. This is the tribe's steadiest feeder.
- **Permanence:** permanent.
- **Enabler:** feeds any Alpha. Pairs with any leader: Sable, Nip, Young Brock.
- **Concentrates:** yes.
- **Change:** "+1 Attack this fight" became a permanent feed.

**Young Brock** (badger heir). Tier 1, 2/3. *Kept body.*
- **Text:** Start of Combat: your Alpha gains Shield.
- **Golden (4/6):** Start of Combat: your Alpha gains two Shields.
- **Condition:** none, as long as you have an Alpha.
- **Payoff:** blocks one whole hit a fight on the carry. That is about 15 damage at R9, 50–125 at R12 and 200–400 at R15, so it scales with the field for free. It also lets an Alpha that has to lead survive one counter-hit, or Lutra's prey's first swing.
- **Permanence:** fight-only. It protects permanent stats.
- **Enabler:** Brother Wolf (Pack covers counters; Shield covers the first enemy attack or random hit), Old Brock (a pouncing Alpha takes counters).
- **Concentrates:** holds the carry.
- **Change:** lending a quarry moved to Old Brock and the Laird. A T1 badger now guards the den.

### Tier 2

**Sable** (stoat, of the Ermine Court). Tier 2, 2/3. *Kept body.*
- **Text:** Quarry. Start of Combat: gain half its quarry's Attack.
- **Golden (4/6):** Quarry. Start of Combat: gain its quarry's Attack.
- **Condition:** something big stands across her at the bell (or anywhere, with Isegrim).
- **Payoff:** about +7 Attack across a 15-Attack front unit at R9, +60 across a 125/125 carry at R12, +200 across a 400/400 at R15. It is proportional, so it never falls behind the curve.
- **Permanence:** fight-only (an answer).
- **Enabler:** the best leader for a Pack Alpha. Her hit plus the Alpha's join can kill a carry twice her size, and only Sable takes the counter.
- **Concentrates:** no. She is the answer.
- **Change:** a flat "+3 Attack if bigger" became proportional.

**The Toll-Bard** (pine marten). Tier 2, 2/4. *Kept body.*
- **Text:** Quarry. After its quarry attacks: get 1 gold next turn. Twice a fight.
- **Golden (4/8):** Quarry. After its quarry attacks: get 2 gold next turn. Twice a fight.
- **Condition:** his quarry lives long enough to swing. It pays best when you are behind.
- **Payoff:** about 1.7 gold a fight. Through Ermeline that is +5/+5 at R9, +12/+12 at R12 and +22/+22 at R15 on the Alpha.
- **Permanence:** economy (permanent once spent).
- **Enabler:** Madame Ermeline, saving, climbing.
- **Concentrates:** indirectly.
- **Change:** the flat Attack drain is dropped; the gold is now twice a fight. Twice a fight is the one rate limit, because gold feeds the engine loop.

**Mistress Russet** (fox poacher). Tier 2, 3/3. *Kept.*
- **Text:** Quarry. Take: your next shop has a copy of its card, 1 gold cheaper.
- **Golden (6/6):** Quarry. Take: your next shop has a copy of its card, 2 gold cheaper.
- **Details:** your tier or lower; from the pool.
- **Condition:** a Take on a card you want, or one you want them not to have.
- **Payoff:** about 0.5 cheap copies a fight. It is selection and **denial of their carry's triple**: steal the second copy of their Dozey or Granny. Stats only if you buy.
- **Permanence:** economy.
- **Enabler:** your triples, and denial against tall boards.
- **Concentrates:** no. It answers by starving their carry.

### Tier 3

**Brother Wolf** (wolf under a vow). Tier 3, 3/4. *Kept body.*
- **Text:** Pack. Your Alpha has Pack.
- **Golden (6/8):** Pack. Your Alpha has Pack, and joins both units beside it.
- **Details:** your Alpha waits for a unit beside it to lead. Golden: it joins each one once a cycle.
- **Condition:** the Alpha has a living leader beside it in its row.
- **Payoff:** the hold. At R12 a 130/130 Alpha joins 2–4 attacks a fight and takes 0 counter-damage, which saves about 100–200 Health a fight. Golden doubles its joins.
- **Permanence:** fight-only. It protects permanent stats.
- **Enabler:** every leader (Wick, Sable, Lutra, Nip); the Glutton's Cleave; Agnes's flanks.
- **Concentrates:** yes. This is what makes concentration win under our rules.
- **Change:** his own two-join rule moved to the Alpha, and to the golden.

**The Lodger** (fox lodger). Tier 3, 4/4. *Kept body.*
- **Text:** Pounce. After this pounces: give your Alpha a Titbit.
- **Golden (8/8):** Pounce. After this pounces: give your Alpha two Titbits.
- **Condition:** a neighbour's quarry is hit. About 1 pounce a fight with one quarry Hunter next to him.
- **Payoff:** +3/+3 a turn at R9, +7/+7 at R12, +13/+13 at R15. Each pounce also adds damage in any row onto the marked unit, so next to Lutra he pounces their carry.
- **Permanence:** permanent (the Titbit).
- **Enabler:** Lutra, Old Brock, Isegrim (every quarry is the same unit, so every hit sets him off).
- **Concentrates:** yes.

**Old Lutra** (otter). Tier 3, 3/4. *Kept body.*
- **Text:** Quarry: the biggest enemy, in any row. Take: give your Alpha 3 Titbits.
- **Golden (6/8):** Quarry: the biggest enemy, in any row. Take: give your Alpha 6 Titbits.
- **Details:** "biggest" is the most Attack plus Health at the bell. An Egg is never a quarry.
- **Condition:** she attacks first in the back row and needs no clear front. Her Take needs their biggest unit to faint while she stands, about 0.3 a fight.
- **Payoff:** about +3/+3 a turn at R9, +6/+6 at R12, +12/+12 at R15 in feeds. The main payoff is the strike: placed beside a Pack Alpha, she leads it **into their carry in cycle one**. A 130 Attack join at R12 kills most 250-stat carries before they swing twice.
- **Permanence:** permanent (feeds) and fight-only (the strike).
- **Enabler:** Brother Wolf (the Alpha joins her), the Lodger (pounces the same target), Isegrim (every Hunter then hunts her target).
- **Concentrates:** yes, and it answers.
- **Change:** "the enemy across, reaching it anywhere" became "the biggest enemy". This is one of the pool's rare any-row answers (section 4).

### Tier 4

**Grizel** (wolf, Mother of the Pack). **Tier 4** (was 5), 4/6.
- **Text:** Pack. End of Turn: your Titbits give +1/+1 more this game.
- **Golden (8/12):** Pack. End of Turn: your Titbits give +2/+2 more this game.
- **Condition:** none; she fires every turn, win or lose.
- **Payoff:** **the engine.** Each turn she makes every later Titbit +1/+1 bigger. On the typical line she is about 85% of the Alpha's growth after round 9. The Alpha reaches about 39/39 at R9, 130/130 at R12 and 400/400 at R15; without her (low roll) it is 22, 35 and 72. A second copy doubles the rate. Track B's Second Helping (End of Turn effects fire again) doubles it too.
- **Permanence:** permanent and visible (the hero panel's Titbit size).
- **Enabler:** every feeder: Nip, Wick, Lodger, Lutra, Ermeline, the Laird and Agnes.
- **Concentrates:** yes.
- **Rate:** her +1/+1 is the tribe's rate parameter *k* (section 3).
- **Change:** a combat Attack bonus on pack kills became a "this game" improvement. She moved down a tier so compounding starts at round 8.

**Madame Ermeline** (stoat, Court Dressmaker). Tier 4, 3/6. *Kept body.*
- **Text:** After you pay to refresh: give your Alpha a Titbit.
- **Golden (6/12):** After you pay to refresh: give your Alpha two Titbits.
- **Condition:** you spend gold on refreshes. Free refreshes don't count (guardrail G1).
- **Payoff:** turns gold into carry stats at 2 × the Titbit size per gold: 6 stats a gold at R9, 14 at R12 and 26 at R15 (Battlegrounds converts about 28 a gold at turn 12). At 2, 3 and 5 refreshes a turn: +6/+6, +21/+21 and +65/+65 a turn. **It is the biggest feeder from round 12 and needs no wins.**
- **Permanence:** permanent.
- **Enabler:** the Toll-Bard's gold, banked gold, Grizel (a Titbit tomorrow is bigger than today).
- **Concentrates:** yes.
- **Change:** the Tier-up discount per Take was win-gated tempo. She is now the tribe's gold sink.

**Old Brock** (badger, Squire of the Sett). Tier 4, **3/6** (was 2/5).
- **Text:** Units next to this have Pounce and the enemy across from this as quarry, in any row.
- **Golden (6/12):** Units next to this have Pounce twice a cycle and the enemy across from this as quarry, in any row.
- **Details:** a unit with its own quarry keeps it.
- **Condition:** something stands across him. In B2 that is their B2, the classic back-row carry slot. Up to four neighbours hunt it.
- **Payoff:** a positional answer to a back-row carry. Next to him, a pouncing Alpha hits their B2 out of turn, in any row, at the price of a counter-hit (Shield helps). At R12: four hits plus pounces into their B2, about 200+ damage with a 130 Alpha.
- **Permanence:** fight-only.
- **Enabler:** the Lodger, a Shielded Alpha, other tribes' bodies (they hunt too, without Takes).
- **Concentrates:** no. It answers.
- **Change:** the +1 Attack is dropped; the body goes to par.
- **The B2 decision:** Brock wants B2 for four neighbours. So does a Pack Alpha, for two leaders. You choose: the Alpha in B2 with the strongest hold, or the Alpha in B1 or B3 next to Brock, pouncing their back row and losing a Pack partner.

### Tier 5

**Grey Agnes** (she-wolf). **Tier 5** (was 4), **4/8** (was 2/5).
- **Text:** Pack. Units beside your Alpha also get its Titbits.
- **Golden (8/16):** Pack. Units beside your Alpha get its Titbits twice.
- **Details:** they get the Titbit's base size, not the Glutton's double.
- **Condition:** units beside the Alpha in its row. Two at most, in B2 or F2/F3.
- **Payoff:** the Alpha's two flanks grow with it from the turn she lands. Bought at R10–11, each flank is about +40/+40 by R12 and +300/+300 by R15. Those flanks are the Alpha's Pack leaders, so they survive counter-hits and keep the Alpha joining. The result is "three 10/11s", the owner's own example (9a).
- **Permanence:** permanent.
- **Enabler:** Brother Wolf (leaders that live keep the hold), Sable and Lutra as flanks (bigger leaders, bigger strikes).
- **Concentrates:** into a core of three. It also spreads the risk against answers that pick one biggest unit.
- **Change:** granting Pack to the next unit became sharing feeds with the flanks.

**The Mountain Glutton** (wolverine). Tier 5, **5/7** (was 4/5).
- **Text:** Cleave. Titbits give this double.
- **Golden (10/14):** Cleave. Titbits give this four times as much.
- **Condition:** it wears the collar (or gets Titbits from Agnes or the Laird).
- **Payoff:** the designed carry. Moved to Alpha at R10, it passes a 60/60 Nip Alpha by R11–12 and reaches about 190/190 at R12 and 730/730 at R15. Cleave on joins cuts three enemies a swing, so it answers wide boards. Golden (a third copy at R13) is a top-few-percent moment: about 1,300/1,300 by R15 on typical feeders, three times a typical carry, and more with a golden Grizel.
- **Permanence:** permanent.
- **Enabler:** every feeder; Brother Wolf (a Cleave join takes no counter); Agnes (flanks).
- **Concentrates:** strongly.
- **Engine shape:** this is the "behind at once, level in about two turns, ahead after" engine applied to the pick.
- **Change:** combat-only "+2/+2 per Take" became the carry body.

### Tier 6

**The Laird of the Sett** (badger, Keeper of the Old Rights). Tier 6, **6/9** (was 3/5).
- **Text:** All your units have Quarry. After a Take: your Hunters each gain a Titbit.
- **Golden (12/18):** All your units have Quarry. After a Take: your Hunters each gain two Titbits.
- **Condition:** Takes. Every unit now marks the enemy across, so 3–5 Takes a fight.
- **Payoff:** wide, permanent growth: about +28/+28 per Hunter a fight at R12 (+390 board stats with seven Hunters) and +52/+52 each at R15 (+730). This is the non-carry route's capstone.
- **Permanence:** permanent.
- **Enabler:** Nip, Russet and the Toll-Bard (more Quarry lanes), Grizel (size).
- **Concentrates:** no. It spreads: wide boards shrug off "hit the biggest" answers.
- **Change:** a combat-only +1/+1 per Take became permanent Titbits.

**Old Isegrim** (wolf, Constable of the Wold). Tier 6, 6/8. *Kept body.*
- **Text:** Your Hunters' quarry is the biggest enemy, in any row.
- **Golden (12/16):** Your Hunters' quarry is one of the two biggest enemies, in any row.
- **Details:** marked at the bell. Golden: front-row Hunters take the biggest, back-row Hunters the second biggest.
- **Condition:** their board has one unit worth hunting.
- **Payoff:** the hue and cry. Every Hunter, every Pack join and every pounce goes into their carry from cycle one; then the marks drop and everyone attacks as usual.
  - At R12, a 250-stat carry takes Sable's half-Attack hit, a 130 Alpha join and pounces in the first cycle.
  - At R15, the same against a 900-stat carry.
  - **Cost:** only one Take, so no Laird and fewer Nip or Russet payouts. It is weak against even boards; golden splits the marks to answer two carries.
- **Permanence:** fight-only.
- **Enabler:** Sable (half of their carry's Attack), the Lodger, Lutra's Take (+3 Titbits), Brother Wolf.
- **Concentrates:** no. It is the tribe's hard answer.
- **Change:** "+3 Attack while joining" (combat) became the answer finisher. The Pack identity lives on in Brother Wolf, Wick and the Alpha.

### Card counts

- **Permanent payoffs (9):** Nip, Wick, Lodger, Lutra's feed, Grizel, Ermeline, Agnes, the Glutton, the Laird.
- **Economy (2):** the Toll-Bard, Russet.
- **Fight-only (5):** Young Brock, Sable, Brother Wolf, Old Brock, Isegrim. Every one either holds the carry or answers theirs.

**Text length:** median 10 words, longest 17 (Old Brock), all inside the wording guide's limits. New terms: Alpha and Titbit, each on six or more cards.

## 3. The tribe

### Engine and its rate parameter

**The engine:** Titbits into one Alpha. Two numbers multiply each turn:
- **how many Titbits** the board makes: about 2 at R4, 6 at R9, 7 at R12 and 9 at R15. They come from Takes, joins, pounces and paid refreshes.
- **how big each Titbit is:** +1/+1, plus Grizel's growth.

The count grows with board quality and gold. The size grows by a fixed step every turn. Their product makes the Alpha's stats roughly cubic in rounds. That is **about ×1.5 a round from round 9 to 15 (×1.46 on the typical line)**, and it naturally levels off later, which fits winners finishing by rounds 14–16.

**Rate parameter *k*:** Grizel's step, the "+k/+k more this game" at each End of Turn. The default is k = 1. The lever sweep should try k ∈ {0 (null), 1, 2}:

| k | Typical Alpha R9 / R12 / R15 | Growth R12→R15 a round | Read |
|---|---|---|---|
| 0 | about 32 / 53 / 80 | ×1.15 | today's flat game; the null arm |
| 1 | about 39 / 130 / 400 | ×1.46 | the September 2025 target |
| 2 | about 45 / 206 / 720 | ×1.52 | steeper variant (between Sep 2025 and Nov 2026) |

**Secondary levers**, only if the sims ask for them:
1. **Titbit floor:** "+1/+1 bigger each time you Tier up", built into the keyword. Use it if the line depends too much on finding Grizel (the low-roll R12 Alpha under 0.25× typical; today about 0.27×).
2. **Ermeline's rate:** a Titbit per paid refresh, against one per two refreshes. Use the slower rate if gold-to-stats outruns the field from round 12.
3. **Grizel's tier:** 4 or 5. Moving her up delays the online turn by about two rounds.

### When it comes online

- **Rounds 1–4:** feeders on par bodies (Nip, Wick, Young Brock). The Alpha is the first Hunter, about 8/9 by round 4. It shows from round 2 and fights as a par-plus unit.
- **Rounds 5–7, the hold:** Brother Wolf (T3) gives the Alpha Pack; the Lodger and Lutra add feeds and aim. Alpha about 16/17 at round 6, level with the target's biggest unit (about 22 stats).
- **Round 8, the build comes online:** Grizel and Ermeline at T4 start compounding.
  - Behind at once: Grizel is a 4/6 that changes nothing on the turn she lands.
  - Level by rounds 9–10.
  - **Clearly ahead from round 10:** the Alpha is about 60/60 against a target median unit of about 22/22.
- **Rounds 10–12:** the Glutton switch or Agnes's flanks. Then a T6 finisher: Isegrim (answer) or the Laird (wide).

### The decisions the engine creates

1. **Who wears the collar, and when to switch.** Moving the collar to a fresh Glutton gives up the old Alpha's growth. Example: a 60/60 Nip is passed by the Glutton in about two turns, then left far behind. Switching too late is the common mistake; switching onto a golden is the common highroll.
2. **Feed now or bank for bigger Titbits.** Grizel makes tomorrow's Titbit +1/+1 bigger, so 8 gold of Ermeline refreshes next turn beats 8 today by about 1/S (12% at S = 8). But today's refreshes also find cards and win today's fight. This is the save decision the audit found missing (bots bank 5+ gold in under 10% of turns).
3. **Placement, every round,** read from the scout:
   - **Where the Alpha sits.** B2 is the safest, with two leaders. F2 or F3 hits earlier but is attacked.
   - **Who flanks it.** The flanks are its leaders; their quarry is where its damage goes. With Agnes they also grow.
   - **Lutra beside the Alpha,** so its first join goes into their biggest unit.
   - **Old Brock or the Alpha in B2.**
   - **Sable across their biggest front attacker;** the Toll-Bard across a long-lived swinger; Nip across something he can kill.
4. **Hunt or harvest** (T6). Isegrim sends every Hunter at their carry (one Take). The Laird marks every lane (3–5 Takes, wide growth). With both, Isegrim's mark wins and the Laird's Takes dry up, so most boards run one.

### Carry route: the Alpha (main line)

- **Pieces:** Wick, Nip and Young Brock; Brother Wolf, Lutra and the Lodger; Grizel and Ermeline; the Glutton and Agnes; Isegrim.
- **Board at round 12:**

```
F1 Young Brock      F2 Sable           F3 Toll-Bard        F4 Little Nip
       B1 Old Lutra      B2 ALPHA (Glutton)      B3 Wick
```

- **How a fight goes.** The front row holds and marks. In the back row, Lutra leads into their biggest unit and the Alpha joins (no counter); Wick leads and the Alpha joins again if golden Brother Wolf is in. The Lodger, if on board, pounces.
- **Wins by:** one held carry deleting a unit per swing, plus a cycle-one strike on their carry.
- **Share of the board:** Alpha about 50% at R12 (Battlegrounds median 34%), falling to about 35% once Agnes's flanks grow.

### Non-carry route: Open Season (wide)

- **Pieces:** many Quarry Hunters (Nip, Sable, Russet, the Toll-Bard, Lutra); Old Brock; Grizel for Titbit size; then the Laird spreads Titbits to every Hunter.
- **Before the Laird** it is a tempo board of par bodies with good aim and gold. It is online at rounds 11–12, when it finds the Laird.
- **Board at round 15:** about seven Hunters at 60–130/60–130, with no unit above 40% of the board.
- **Why run it:**
  - it shrugs off "biggest enemy" answers and Mire on one unit;
  - Russet and the Toll-Bard keep paying;
  - against other Hunters' Isegrim, there is no single prey.

### Answers to other tribes' carries

| Their carry | Hunter answer | How it lands |
|---|---|---|
| A back-row Pass carry (Hedgerow, last slot) or Dozey | Old Lutra; Isegrim | Any row, cycle one. Lutra's Take feeds 3 Titbits |
| A big front attacker (Granny Stir-Up's one-fight pile, a Lodger-sized brawler) | Sable across it; the Shield takes its first hit | Sable gains half of its Attack, the Alpha joins her, and only Sable takes the counter |
| Their B2 engine | Old Brock in B2 | Four neighbours hunt it with reach; pounces pile on |
| A carry built from triples | Mistress Russet | Takes a copy of the piece out of the pool, cheaper, into your shop |
| A wide board of equals | the Glutton's Cleave; the Laird | Cleave joins hit three; wide Titbits keep pace |

Hunters answer a carry mostly **with their own carry**, aimed. A small Hunter board can't kill a 900/900 unit. It can make the 900/900 fight its own Alpha in cycle one, on Hunter terms (no counter-hit). That keeps "answers exist" without a cheap delete: Lutra alone does 3 damage.

### Weak points

1. **Mire (Bog folk).** A Mired Alpha can join only attacks on the toad, so the hold breaks. Hasty Pudding swallowing the unit across B2 takes the Alpha out of the fight. **This is the tribe's worst matchup, by design:** Bog is the answer tribe.
2. **Proportional "biggest enemy" answers** (Track B's answer dial and neutrals): they cut the Alpha first, and a half-board carry loses half its strength. Agnes's flanks are the hedge.
3. **Back-row reach:** Swoop, Ballooning Spider, Whirligig's row swap and random-target effects reach B2.
4. **Killing the leaders.** Once B1 and B3 fall, the Alpha must lead and takes counter-hits.
5. **Even boards blunt Lutra and Isegrim:** their "biggest" is just one seventh of the board.
6. **Missing Grizel.** The low roll stays flat (Alpha 35/35 at R12). See the Titbit-floor lever.
7. **Takes need trades.** Nip, Lutra and the Laird pay less while losing. About 80% of the carry line's growth (Wick, the Lodger, Ermeline, Grizel) is not win-gated, so this is a minor brake.

### Highroll moments a player will remember

1. **"The collar moves"** (the switch is common; the golden finish is rare, a guess of 1 Hunter game in 20). Round 10: your Alpha is a 60/60 Nip and you find the Mountain Glutton. You move the collar to a 5/7 and feel foolish for a turn. Round 12 it is 190/190, cleaving three enemies a join from B2. Round 13 your third Glutton arrives: golden, four times the Titbits. By round 15 it is about 1,300/1,300 on ordinary feeders, three times a typical carry, and with a golden Grizel as well it passes 2,500/2,500. That is the rare top-1% game the owner accepts (9d).
2. **"The hue and cry" (common late, against a tall opponent).** Round 13: their Hedgerow carry is 700/700 in B3, and you have just found Isegrim. At the bell every Hunter marks it, and Sable gains 350 Attack. In cycle one Sable leads into it and your 450/450 Alpha joins: 800 damage, and it faints before it swings. Lutra was standing, so her Take feeds 3 Titbits (+42/+42). Their board is six support units against yours.
3. **"Bank and feast."** Round 12, with Ermeline and the Toll-Bard: you skip a buy, bank 14 gold, and next turn (Titbit one size bigger) pay 14 refreshes. That is +14 Titbits, about +140/+140 in one turn, and refresh 9 shows Isegrim.

## 4. Calls that deviate from defaults (for DECISIONS.md if adopted)

1. **Grizel to tier 4, Grey Agnes to tier 5.** The tier counts stay 3/3/3/3/2/2. Compounding must start by round 8 (target shape), and the improver is the engine. Agnes only pays once the Alpha is big.
2. **Two any-row "biggest enemy" Hunters,** Old Lutra (T3) and Old Isegrim (T6), against the pool-wide default of two or three such cards in total (fundamentals §4 Q2). Reasons:
   - this angle's brief is answers;
   - Lutra is one strike a fight, because she dies to the counter-hit, and it lands only if your Alpha is big enough;
   - Isegrim is a T6 that trades away most Takes.
   - Pool-wide, this argues for at most one more any-row answer outside Hunters (Bog or neutral). The carry-against-answer sim decides.
3. **One rate limit kept:** the Toll-Bard's twice a fight. Gold feeds Titbits, a loop. No size caps anywhere.
4. **Alpha needs a recruit action** ("Make Alpha"), the first new player action since Fly South. Section 7 lists the work.

## 5. Numbers: the hand model

Script: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/alpha_model.py` (scratch; rerun it to check).

**Assumptions:**
- Titbits a fight: Nip 0.6 (the costing-3 Take rate, 0.55), Wick 1.5 joins, the Lodger 1.0 pounce, Lutra 0.3 Takes × 3. Ermeline: 2 paid refreshes a turn at R8–9, 3 at R10–12 and 5 from R13.
- Takes a fight: 1, 2, 3 and 4 by round band.
- **Typical buys:** Nip R1, Wick R2, the Lodger R5, Lutra R6, Grizel and Ermeline R8, a second Grizel R11.
- **High roll:** golden Wick R4, Grizel R7 and R9, golden Grizel R11, collar on the Glutton from R9.
- **Low roll:** no Ermeline, Grizel only at R11.
- **Wide:** one Grizel, the Laird from R12.
- Supports are at printed bodies plus Agnes flanks where bought.

No spells, heroes or Rings. No fights were simulated.

| Round | Target: Sep 2025 mean board | Typical carry line: board (Alpha) | High roll | Low roll | Wide (Laird R12) |
|---|---|---|---|---|---|
| 6 | 53 | ~70 (Alpha 33) | ~85 (41) | ~60 (25) | ~65 (31) |
| 9 | 194 | ~130 (77) | ~170 (100) | ~90 (43) | ~110 (55) |
| 12 | 759 | ~470 (260) | ~1,200 (810) | ~130 (70) | ~300 (129, +20/+20 a Hunter a fight) |
| 15 | ~2,600 (×1.5 from T14's 1,751) | ~2,100 (800) | ~3,700 (2,450) | ~250 (143) | ~1,800 (260; Hunters ~110/110 each) |

**Reading:**
- **The carry matches the target.**
  - The Alpha is 39/39 at R9, 130/130 at R12 and 400/400 at R15, growing ×1.46 a round.
  - It is 50–60% of the board at R12, against the target's biggest unit of about a third of 759.
  - Board totals trail the mean by about 35% at R9–12 and catch up by R15, once Agnes's flanks grow.
  - This is deliberate concentration. Under our rules a held carry beats an even total (`carry.txt`, `keywords.txt`). Field sims must confirm it beats even boards of the round's median. If not, the first fix is Agnes back to T4, not a bigger k.
- **The tail:**
  - High roll about 1.8× typical at R15.
  - A golden Glutton with a golden Grizel is about 3–6×. That is the rare top end the owner accepts, not a common one.
  - The low roll is about 0.27× typical at R12, similar to Battlegrounds' p10/p50 at turn 12 (629/2,598 = 0.24).
- **Snowball check:** about 80% of carry-line growth (Wick, the Lodger, Ermeline, Grizel) is not win-gated. Only Nip, Lutra and the Laird pay more for winning. So a lead buys tempo and Health, not a faster engine. That is the opposite of today's Take-only Hunters.
- **Stats per gold** through Ermeline: 6 / 14 / 26 at R9 / 12 / 15. Bramble buys bodies at 1.4 today; Battlegrounds is at 28 by turn 12.

## 6. Harness lines (proposals for `tools/sim/line_profiles.json` on `ideation/harness`)

Format as in `line_profiles.tuned.json`. `priority` is buy-and-keep order, best first. `climb_schedule` lists the rounds to reach tiers 2 to 6. The `alpha`, `placement` and `refresh_feed` fields are **new policy fields** the line brain needs (section 7). Until they exist, the default (collar on the biggest Hunter, Alpha in B2) is a fair stand-in.

```json
{
  "line_hunters_tempo": {
    "tribe": "Hunters", "base_strategy": "hunters_open_season", "engine": false,
    "priority": ["laird_of_sett", "grizel", "sable", "brother_wolf", "lodger", "old_lutra",
                 "wick", "little_nip", "old_brock", "mountain_glutton", "grey_agnes",
                 "toll_bard", "mistress_russet", "young_brock", "old_isegrim", "madame_ermeline"],
    "climb_schedule": [4, 6, 8, 10, 12],
    "save_threshold": 0, "save_until": 8,
    "alpha": "biggest_hunter",
    "placement": "quarry_lanes_then_pack",
    "refresh_feed": "leftover_only"
  },
  "line_hunters_engine": {
    "tribe": "Hunters", "base_strategy": "hunters_pact", "engine": true,
    "priority": ["grizel", "madame_ermeline", "mountain_glutton", "brother_wolf", "wick",
                 "old_lutra", "little_nip", "lodger", "young_brock", "grey_agnes",
                 "old_isegrim", "sable", "toll_bard", "laird_of_sett", "mistress_russet", "old_brock"],
    "climb_schedule": [3, 5, 7, 10, 12],
    "save_threshold": 2, "save_until": 7,
    "alpha": "first_hunter_then_glutton",
    "placement": "alpha_b2_lutra_b1",
    "refresh_feed": "all_spare_from_8"
  }
}
```

**Tempo line (Open Season, wide).**
- **Buy:** buy the best body by the priority list each turn and keep every Quarry Hunter. Sell Ermeline, Isegrim and Young Brock first.
- **Climb:** the standard curve. Don't skip T3 (Brother Wolf and the Lodger) or T4 (Grizel).
- **Save:** never. Spend to the last gold; spare gold refreshes.
- **Collar:** the biggest Hunter.
- **Place:** Quarry Hunters across what they want (Sable across the biggest front Attack, Nip across the smallest, the Toll-Bard across their most frequent attacker in the last fight). Pack units just after a leader.
- **Finisher:** the Laird.

**Engine line (the Alpha).**
- **Buy:** buy and keep the priority list. Climb fast to T4 by round 7 for Grizel and Ermeline, then T5 at 10 (the Glutton, Agnes) and T6 at 12 (Isegrim).
- **Save:**
  - Keep 2 gold in rounds 5–7, so round 7 is a Tier up plus a buy.
  - From round 8 with Ermeline, spend all spare gold on paid refreshes and keep 1.
  - From round 11, with Grizel on board and no buy scored above two Titbits, bank everything every other turn and refresh it all next turn (bank and feast).
- **Collar:**
  - First Hunter bought.
  - Move to the Mountain Glutton the turn it is bought if the Alpha has under three turns of feed (Alpha stats < 3 × last turn's Alpha gain). Otherwise the Glutton flanks.
  - Always move it onto a golden Glutton.
- **Place:**
  - Alpha B2, Old Lutra B1, Wick or Sable B3. Young Brock and the walls in front; Sable across their biggest front attacker.
  - Old Brock takes B2 only with no Brother Wolf on board; otherwise he goes front.
  - With Isegrim, put Sable beside the Alpha.

## 7. Engine needs

| Need | For | What |
|---|---|---|
| **Alpha** state | Every "your Alpha" card | Per-player `alpha_uid`. It defaults to the first Hunter played. Recruit action `set_alpha` (free, unlimited). On a sale it passes to the Hunter with most stats. Only Hunters. Copied into snapshots and ghosts. UI: a collar badge on card views and the scout, and a **Make Alpha** button in card detail. |
| **Titbit** | Feeders, Grizel, Agnes, Glutton, Laird | Per-player `titbit` {attack, health}, default 1/1, shown on the hero panel. Effect `titbit` {count, to: `alpha` / `hunters` / `beside_alpha`}: permanent, applied at once to living combat units and written back to the recruit board after the fight, even if the Alpha fainted. Effect `improve_titbit` {attack, health}. Unit flag `titbit_multiplier` (Glutton 2, golden 4). |
| **Grant Pack to the Alpha** | Brother Wolf | The Alpha gets Pack plus the existing Brother Wolf "waits while a neighbour can lead" rule. Golden: the existing once-per-neighbour-per-cycle join. |
| **Cleave on joins** | Glutton, any Cleave joiner | Track B Cleave applies to a joiner's damage step too, with no collateral counter-damage. |
| **Shield grant and charges** | Young Brock | Start of Combat grant of Track B `shield` to the Alpha. Golden needs `charges: 2`. |
| **Quarry selector** | Lutra, Isegrim | Quarry with `select: biggest_enemy` (Track B selector) and `reach`. Eggs excluded. Isegrim overrides every friendly Hunter's mark at the bell; golden assigns front-row Hunters the biggest and back-row Hunters the second biggest. |
| **Proportional gain from quarry** | Sable | Track B `stat_fraction` `gain` with a quarry source: half (golden all) of the quarry's Attack, at Start of Combat after the bell. |
| **Paid-refresh trigger** | Ermeline | `on_refresh` with `paid: true`. Free and effect refreshes excluded (4.4.5–4.4.6, guardrail G1). |
| **Take to all Hunters** | Laird | `on_take` then `titbit` {to: `hunters`}. |
| **Golden Pounce rate** | Old Brock | Pounce `per_cycle: 2`. |
| **Bots and lines** | All | Collar policy, placement policy and refresh-feed policy (section 6). The Hard brain needs to value a Titbit at 2 × current size × the turns left. |
| **Harness metric** | Concentration | Combat-start snapshot already records the biggest unit. Add the Alpha's share and Titbit size per round. |

## 8. What critics should try to break

1. **Ermeline with no recruit timer.** Is gold-to-stats from round 12 the only right play, and does it crowd out buying? Lever: one Titbit per two paid refreshes.
2. **Early carry deletion.** Lutra plus Brother Wolf at T3 (rounds 6–8): does a 20/20 Alpha joining Lutra delete other tribes' young carries before they matter? Run the carry-against-answer sim at R7.
3. **All-in risk.** The Alpha is half the board, so one "biggest enemy" answer swings a Hunter fight hard. Is that good variance (the upsets the plan wants) or a coin flip?
4. **Bog matchup.** Mire breaks the hold. Is Hunters versus Bog worse than about 35% for the Hunter line? If so, give the Alpha's Pack "Mire can't stop this joining".
5. **Hunter mirror.** Isegrim against Isegrim: is it first strike wins?
6. **Grizel dependence.** If the low roll at R12 is under 0.25× typical in line lobbies, switch on the Titbit floor.
7. **Distribution.** Do Agnes's flanks make the Alpha route too safe against answers? They are the hedge on purpose; watch the field win rate.
