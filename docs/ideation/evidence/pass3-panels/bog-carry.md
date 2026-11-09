# Bog folk, pass 3: the Diva (carry and answers)

9 Nov 2026. A pass 3 designer for Track C, on the **carry and answers** angle. Read: owner notes 09a, 09c, 09d and 08e; `fundamentals.md` §1 and §3; `plan-scale-rework.md` (Step 1, Track C); rulebook §8–9 and the BRAMBLE ideation rules (Mire waits, Bitter hits first); the shared mechanics on `ideation/mechanics` (percent Bitter, biggest-enemy selector, proportional gains); `wording-guide.md`; `content/bog-folk.md`, `pass2-b.md`, `pass2-bog.md`; the Bog audit. I had no price list. Every number is a first guess, sized against the target shape at rounds 6, 9, 12 and 15 with a hand model (`bog-carry-model.py`, output in `bog-carry-model.out.txt`). The lever sweep sets the rates.

**In one line.** The bog keeps what it takes. Every bite into a Bitter toad loses a quarter of its Attack, and Soak toads keep that quarter as permanent stats. One toad, the **Diva**, collects it all. Their carry must come to her, and arrives smaller each time.

---

## 1. Why this shape

**The problem (audit and pass 2).**
- 9 of 13 Bog payoffs lasted one fight. Permanent growth was the Toad (capped at +3/+3), Ranocchio (+1/+1 once a fight) and Tiddy (+1/+1 twice a fight).
- Bitter, Jenny and Hopkin were flat (−2 Attack, +2 Attack). They fade as stats grow.
- Bog had no way to pick, grow or protect a carry, and no gold-to-stats channel.
- The audit's lean: Bog as the answer tribe, plus an engine of its own.

**The idea.** One mechanism does both jobs. Bitter takes a share of each biter's Attack before it hits: that is the answer. Soak keeps the share as permanent stats: that is the engine. Mire decides who bites whom: that is the placement decision. The bigger their carry, the more it shrinks and the more your Diva drinks.

| Finding (fundamentals §1) | What the design does |
|---|---|
| Concentration wins only when the carry holds its stats. | The Diva holds three ways. Bitter shrinks every biter first. Soak's gain lands before the damage, so a bite costs her about half. Mire chooses who bites her. |
| Holding keywords are worth more than stats (−2 damage +24.5 points). | Bitter-plus-Soak is a proportional holding keyword that works at any scale. |
| Flat answers fade; proportional answers grow. | Every Bog answer is proportional: Bitter (a quarter), Bufo (half), Hopkin and Sal (shares of the Diva's Attack), Jenny (the biggest enemy, any row). |
| Answers aimed "across" land by layout luck. | Most Bog answers still aim across, on purpose: that is the placement game. One card, Jenny, reaches the biggest enemy in any row, and she moves up to tier 5 so she is rarer. |
| Payoffs must be permanent and visible. | Soak, Tiddy's funnel, Ranocchio and the Prince are permanent and show in the shop. The combat-only cards are the answers and one finisher. |
| No size caps; growth must compound. | No caps. Takes scale with the field, so Bog compounds with it, and the funnel, the Peat King and the echoes multiply it. |

**Bog's clock.** Behind at once (rounds 1–8, today's bodies and small takes), level by round 11, clearly ahead from round 12 once the Peat King lands. Tribes may have different clocks; Bog's is a slow start and a strong end.

---

## 2. Rules and keywords

Two keywords kept (Mire, Snap), one changed (Bitter), one new keyword (Soak) and one new term (Diva).

| Term | Reminder (≤ 16 words) | Rules |
|---|---|---|
| **Mire** (kept) | Start of Combat: the enemy across must attack this while this lives. This waits once. | Unchanged (9.4.5a). One patch per slot, first in reading order wins. The reminder is trimmed from 17 words to 15; the meaning is the same. |
| **Bitter** (changed) | When an enemy attacks this, it first loses a quarter of its Attack. | Was a flat number. A quarter of current Attack, **rounded up**, never below 1 Attack. Applied at declaration, as now (9.6.0). **One Bitter per unit:** own and lent Bitter don't stack. **On a golden unit, or lent by one, it takes half.** |
| **Soak** (new) | Bitter. This also gains +1/+1 permanently for each Attack its Bitter takes. | The gain lands at the same moment as Bitter, before the damage. It is kept even if the hit kills this. |
| **Snap** (kept) | Attacks the Mired enemy with the most Attack. | Unchanged. |
| **Diva** (new) | Your Bog folk unit with the most Health. Ties: first in reading order. | Chosen from base and permanent stats (auras don't count). Fixed at Start of Combat; she keeps gaining even after she dies in that fight. A crown badge marks her on the board, in the shop and in the scout. |

**Why a quarter, rounded up.** Rounded up, a quarter takes 1 from any 2–4 Attack unit, which is today's Bitter 1. So the early game stays level with today. From round 8 it grows with the field: about 8 a bite from the round 9 carry, 29 from round 12's, 97 from round 15's.

**Keyword budget.** Soak is on five cards (Bridge Toad, Gideon, the Prima Donna, the Peat King, and the Chorus's neighbours) and turns a 12-word sentence into one word each time. Diva is on three cards (Tiddy, Sal and the Prince), names the crown badge, and saves "your Bog folk unit with the most Health" each time.

**Tier changes.** The spread stays 3/3/3/3/2/2. Two cards swap: **Tiddy Mun 5 → 4** and **Jenny Greenteeth 4 → 5**.
- Tiddy is the funnel. At tier 5 the Diva has nothing to collect until round 9, and the model's carry board sits at 0.47 of the field there. At tier 4 (found about round 7) it sits at 0.77.
- Jenny is the one answer that ignores rows. At tier 5 she is rarer, which is the owner-default "rarely" for row-ignoring answers (fundamentals §4, Q2).

---

## 3. The sixteen

Every creature, name and portrait is kept. The Prince Restored stays a token. The Peatling token is unused and kept in reserve (section 12).

**Typical board for the payoff numbers.** The carry line with average shops: Bridge Toad round 1, Madame Bufo 3, Gideon and Warty Nan 5, Tiddy Mun and Vaulting Hopkin 7, His Highness 8 (Prince from 11), the Prima Donna 9, the Peat King 11. Keep rate 1, Bitter a quarter. Stats are at the start of that round's fight, before Harvest Suppers. "No King" and "King" give the range.

**Opponent, from the target curve** (carry 33% of the board, six even supports, 45% of stats in Attack):

| Round | Field board | Their carry | Their support |
|---|---|---|---|
| 6 | 53 | 8/10 | 3/3 |
| 9 | 194 | 29/35 | 10/12 |
| 12 | 759 | 113/138 | 38/47 |
| 15 | 2,600 | 386/472 | 131/160 |

### Tier 1

**Bridge Toad.** *Common Toad, Bridge-Keeper.* Tier 1, **1/3** (unchanged).
- **Text:** Mire. Soak.
- **Golden (2/6):** Mire. Soak. *(Golden Soak takes half.)*
- **Condition:** an enemy attacks it. Mire makes sure the enemy across does.
- **Payoff:** +1/+1 a bite early (a toll for every crossing). If it is your Diva when Tiddy arrives, it collects everything: **41/43 at round 9, 186–196/188–198 at round 12, 692–773/694–775 at round 15.** As a plain support across a mid enemy: about 13/15, 40/45, 180/185.
- **Permanence:** permanent.
- **Enabler:** your first Diva; a patch for Snap, Sal and Hopkin; takes for Tiddy and the Lantern Man.
- **Concentrates:** yes. The T1 that can become the star.

**Warty Nan.** *Toad Wet-Nurse.* Tier 1, **1/3** (unchanged).
- **Text:** Bitter. Your units beside this have Bitter.
- **Golden (2/6):** same. *(Her Bitter, and the Bitter she lends, take half.)*
- **Condition:** she or a unit beside her is attacked.
- **Payoff:** about 3 bites a fight on her and her neighbours lose a quarter each: roughly 9, 30 and 100 enemy Attack taken a fight at rounds 9, 12 and 15. With Tiddy, every point is +1/+1 on the Diva.
- **Permanence:** combat only (the funnel it feeds is permanent).
- **Enabler:** Tiddy's funnel and the Lantern Man; makes frogs, neutrals and other tribes' walls Bitter. Put her beside units that lack Bitter.
- **Concentrates:** no.

**Young Pretender.** *Frog, Claimant to the Lily Throne.* Tier 1, **3/2** (unchanged).
- **Text:** Snap. After this kills a Mired enemy: get 1 gold next turn.
- **Golden (6/4):** Snap. After this kills a Mired enemy: get 2 gold next turn.
- **Condition:** it kills what is stuck. Bitter and Hopkin leave stuck enemies low.
- **Payoff:** tempo (3 Attack at the biggest stuck enemy from turn 1) and about 0.5 gold a fight early, 0.3 late. Sold by round 9 on most boards.
- **Permanence:** economy.
- **Enabler:** gold for early tier-ups.
- **Concentrates:** no.

### Tier 2

**Madame Bufo.** *Toad Diva.* Tier 2, **1/4** (unchanged).
- **Text:** Mire. Bitter. If its Mired enemy kills this, halve its Attack.
- **Golden (2/8):** Mire. Bitter. If its Mired enemy kills this, halve its Attack twice. *(Golden Bitter takes half.)*
- **Condition:** she is across their carry, and it bites her.
- **Payoff:** their carry fights on at about three eighths of its Attack: **29 → 10 at round 9, 113 → 42 at round 12, 386 → 144 at round 15.** The cheapest carry answer in the game, and it never goes out of date.
- **Permanence:** combat only.
- **Enabler:** shrinks the carry for Snap frogs and the Lantern Man. **Anti-synergy by design:** a halved giant gives your Diva half the drink (section 4).
- **Concentrates:** no.

**Vaulting Hopkin.** *Frog Acrobat.* Tier 2, **3/1** (unchanged).
- **Text:** Snap. In your back row, attacks first with half the highest Attack in front.
- **Golden (6/2):** Snap. In your back row, attacks first with the highest Attack in front.
- **Condition:** back row, behind a big front unit (B1 vaults off F1/F2, B2 off F2/F3, B3 off F3/F4), and a Mired enemy to Snap.
- **Payoff:** one strike at the biggest stuck enemy before anything else moves, with half your Diva's Attack: **about 20 at round 9, 93–98 at round 12, 350–390 at round 15.** That nearly kills their carry before it swings. *(Uses its own Attack if that is higher. It usually dies to the hit back.)*
- **Permanence:** combat only.
- **Enabler:** expresses the carry a second time; sets up Pretender and Ranocchio kills.
- **Concentrates:** yes, it spends the carry's size.

**The Peat Cutter.** *Palmate Newt, Labourer.* Tier 2, **2/4** (unchanged).
- **Text:** Mire. After a Mired enemy dies: get 1 gold next turn. Once a fight.
- **Golden (4/8):** Mire. After a Mired enemy dies: get 2 gold next turn. Once a fight.
- **Condition:** any Mired enemy dies, by any hand, in a win or a loss.
- **Payoff:** about 0.9 gold a fight: roughly 5, 8 and 11 gold in all by rounds 9, 12 and 15. "Three times in all" is gone.
- **Permanence:** economy.
- **Enabler:** the carry line's save for tier 5 and tier 6 (section 9).
- **Concentrates:** no. "Once a fight" stays: it guards an economy loop (more patches, more gold, more patches).

### Tier 3

**The Natterjack Chorus.** *Natterjack Choir.* Tier 3, **3/4** (unchanged).
- **Text:** Your Bog folk beside this have Mire and Soak.
- **Golden (6/8):** same. *(The Soak it lends takes half.)*
- **Condition:** Bog folk beside it in the same row.
- **Payoff:** two more patches and two more growers. Jenny beside it, always bitten by the biggest, Soaks about +8/+8, +29/+29 and +97/+97 a bite at rounds 9, 12 and 15. Bufo beside it Soaks about +3/+3, +10/+10 and +33/+33 a fight.
- **Permanence:** permanent (lent Soak gains are permanent).
- **Enabler:** patches for Sal, Snap and kisses; Soak for the Peat King to double. The Swamp route's engine.
- **Concentrates:** no: it spreads growth. Tribe word, because Soak is a payoff.

**Gideon, Basso Profundo.** *Toad Bass.* Tier 3, **2/6** (unchanged).
- **Text:** Mire. Soak. After its Mired enemy attacks this: attack it back.
- **Golden (4/12):** Mire. Soak. After its Mired enemy attacks this: attack it back twice. *(Golden Soak takes half.)*
- **Condition:** its Mired enemy bites it.
- **Payoff:** each bite grows him and buys an extra exchange. As a support: **about 12/16 at round 9, 40–54/44–58 at round 12, 134–242/138–246 at round 15.** As the Diva, he is the counter-punching kind: every bite on him is answered at once.
- **Permanence:** permanent growth; the counter is combat.
- **Enabler:** the second Diva candidate (6 Health at tier 3). Feeds Tiddy and the Lantern Man.
- **Concentrates:** yes (self).

**Spitfire Sal.** *Fire Salamander, Pyrotechnist.* Tier 3, **1/3** (unchanged).
- **Text:** Start of Combat: deal half your Diva's Attack, split among Mired enemies.
- **Golden (2/6):** Start of Combat: deal your Diva's Attack, split among Mired enemies.
- **Condition:** a Diva with Attack, and patches with enemies on them. She fires after Mire is laid.
- **Payoff:** across four Mired enemies, **about 5 each at round 9, 24 at round 12, 96 at round 15.** Chip on a normal board, a sweep on a token board. *(Split evenly, rounded down.)*
- **Permanence:** combat only.
- **Enabler:** Bog's answer to wide boards, its worst matchup. Leaves stuck enemies low for Snap frogs.
- **Concentrates:** yes, it spends the carry's size.

### Tier 4

**Tiddy Mun.** *Fen Spirit.* **Tier 4** (was 5), **3/5** (was 3/6).
- **Text:** Your Diva permanently gains +1/+1 per Attack your other units' Bitter takes.
- **Golden (6/10):** Your Diva permanently gains +2/+2 per Attack your other units' Bitter takes.
- **Condition:** your other Bitter units are bitten. On a Bog front row that is most enemy attacks.
- **Payoff:** the funnel. **About +30/+30 to the Diva from the round 9 fight, +107/+107 from round 12's, +352/+352 from round 15's.** The water rises, and what stands in it gets taller.
- **Permanence:** permanent.
- **Enabler:** turns every Bitter unit on the board, any tribe, into food for one carry. Nan and the Chorus become carry cards.
- **Concentrates:** yes: the tribe's concentrator. Plain words, not Soak, so the Peat King doesn't double it.

**His Highness, Allegedly.** *Frog Pretender.* Tier 4, **3/5** (unchanged).
- **Text:** Snap. After a Mired enemy dies: get a kiss, once a fight. Third kiss: become the Prince Restored.
- **Golden (6/10):** Snap. After a Mired enemy dies: get a kiss, once a fight. Third kiss: become a golden Prince Restored.
- **Condition:** three fights with a Mired death (almost every fight on a Bog board).
- **Payoff:** the Prince Restored, a second big unit that grows with the Diva (below).
- **Permanence:** permanent transform.
- **Enabler:** turns the Diva's size into a second body.
- **Concentrates:** yes, it copies the carry.

> **The Prince Restored** (token, `pool: false`). *Frog, Rightful Prince of the Bog* (Bog folk). **6/7.**
> - **Text:** Snap. Has extra Attack and Health equal to half your Diva's.
> - **Golden (12/14):** Snap. Has extra Attack and Health equal to your Diva's.
> - **Payoff:** a standing echo, visible in the shop: **63/65 at round 11, 98–104/100–106 at round 12, 351–392/353–394 at round 15.** *(Doesn't count when choosing the Diva; if he is somehow the Diva, his echo is 0.)* The spell discount is gone: at scale it was noise.

**Signor Ranocchio.** *Frog, Tenor.* Tier 4, **3/4** (unchanged).
- **Text:** Snap. After this attacks a Mired enemy: permanently gain +1/+1 per 4 of its Attack.
- **Golden (6/8):** Snap. After this attacks a Mired enemy: permanently gain +2/+2 per 4 of its Attack.
- **Condition:** he Snaps a stuck enemy (the one with the most Attack, so usually their carry).
- **Payoff:** the frogs' growth, about 1.5 Snaps a fight: **about 10/12 at round 9, 52/54 at round 12, 214/216 at round 15.** He gains even if the hit back kills him.
- **Permanence:** permanent.
- **Enabler:** the Swamp route's grower; a frog that eats what the toads hold.
- **Concentrates:** yes (self). "Once a fight" is gone.

### Tier 5

**The Prima Donna.** *Toad Diva Assoluta.* Tier 5, **2/8** (unchanged).
- **Text:** Mire the slot across and the slots beside it. Soak.
- **Golden (4/16):** same. *(Golden Soak takes half.)*
- **Condition:** three patches, three biters. In B2 she drags their whole back row, where carries hide, onto her.
- **Payoff:** about 3.3 bites a fight. As a support: **2/8 when bought at round 9, 77–113/83–119 at round 12, 341–641/347–647 at round 15.** As the Diva, the strongest one: she gets the most bites and pulls the carry wherever it hides in the row.
- **Permanence:** permanent.
- **Enabler:** three Mired enemies for Sal, Snap, kisses and the Peat Cutter; three biters for the Lantern Man.
- **Concentrates:** yes. "Once per enemy" is gone.

**Jenny Greenteeth.** *Bog Hag.* **Tier 5** (was 4), **4/7** (was 3/5).
- **Text:** Mire the biggest enemy instead of the one across. Bitter.
- **Golden (8/14):** Mire the two biggest enemies instead of the one across. Bitter. *(Golden Bitter takes half.)*
- **Condition:** none. Her patch goes under the biggest enemy in either row, before any other patch.
- **Payoff:** their carry, wherever it hides, must bite her first and loses a quarter: **29 → 21 at round 9, 113 → 84 at round 12, 386 → 289 at round 15.** From then on it is Mired, so Hopkin vaults into it, Snap frogs reach it, Sal burns it and the Lantern Man hunts it. With the Chorus beside her, she Soaks that bite.
- **Permanence:** combat only.
- **Enabler:** the reach card that makes every other answer land. The one Bog card the carry owner can't dodge by placement.
- **Concentrates:** no.

### Tier 6

**The Peat King.** *Toad, Old as the Moss.* Tier 6, **5/9** (unchanged).
- **Text:** Mire. Soak. Your Bog folk Soak double.
- **Golden (10/18):** Mire. Soak. Your Bog folk Soak triple.
- **Condition:** your Soak units are bitten.
- **Payoff:** the doubler. The carry board goes from 1.14 to 1.34 times the field at round 12 and from 1.25 to 1.72 at round 15. He grows himself to about 23/27 by round 12 and 164/168 by round 15.
- **Permanence:** permanent.
- **Enabler:** every Soak unit, lent Soak included. Not Tiddy's funnel.
- **Concentrates:** partly. He doubles the Diva's own Soak and every support's, so the board fills in behind her (biggest share 0.43 → 0.35).

**The Lantern Man.** *Will-o'-the-Wisp.* Tier 6, **4/8** (unchanged).
- **Text:** Snap. Has +1/+1 for each Attack your Bitter has taken.
- **Golden (8/16):** Snap. Has +2/+2 for each Attack your Bitter has taken.
- **Condition:** Bitter takes during this fight. *(Counts as they happen; starts at 0 each fight.)*
- **Payoff:** the Swamp's finisher. When he first attacks, about +50/+50 at round 12 and +170/+170 at round 15; double that by his second cycle. He hunts the biggest stuck enemy.
- **Permanence:** combat only.
- **Enabler:** pays for wide Bitter (Nan, the Chorus, many toads) on a board without a Diva pile.
- **Concentrates:** yes, within a fight.

---

## 4. The engine and its rate

**The engine: the bog keeps what it takes.**
1. **Condition:** an enemy attacks a Bitter unit. Mire makes the enemy across do it; the Bog front row is all Bitter, so most other attacks do too.
2. **Payoff:** Bitter takes a quarter of the biter's Attack. Soak units keep it as +1/+1 per point. Tiddy sends every take on the board to the Diva too. The Peat King doubles Soak.
3. **Enablers:** patches (Mire, the Prima Donna, the Chorus, Jenny) decide how many bites; Bitter sources (Nan, Bufo, Jenny) add takes for the funnel; echoes (the Prince, Hopkin, Sal) turn the Diva's size into more power.

**How it compounds.** Takes are a share of the enemy's Attack, so Bog's growth per fight scales with the field (×1.5 a round). The number of bites grows as Bog adds patches and Bitter. The funnel and the Peat King multiply both. In the model the Diva passes the field's carry at round 9 and the board passes the field at round 11.

**The rate parameter: the keep, k.** Soak and the funnel give +k/+k per Attack taken. Default **k = 1** ("+1/+1 for each Attack"). Suggested sweep grid: 0.5 ("+1/+1 for every 2 Attack"), 0.75, 1, 1.25.

Secondary dials, in the order I would turn them:
- Bitter's share b: default a quarter, rounded up. It moves the answer and the engine together. Grid ⅕, ¼, ⅓.
- The Peat King's multiplier: default ×2. Grid ×1.5, ×2.
- Hopkin's share (½), Sal's share (½), the Prince's echo (½), Ranocchio's divisor (4).

**Boards against the target** (model: keep 1, Bitter ¼; totals include the Prince's echo):

| Round | Field | Carry line, no King | Carry line, with King | Diva (no King / King) | Biggest share | Swamp line (hand estimate) |
|---|---|---|---|---|---|---|
| 6 | 53 | ~48 (0.9) | same | Bridge Toad 7/9 | 0.43 | ~55 (1.0) |
| 9 | 194 | ~150 (0.77) | same | 41/43 | 0.57 | ~150 (0.77) |
| 12 | 759 | ~860 (1.14) | ~1,020 (1.34) | 186/188 / 196/198 | 0.43 / 0.39 | ~520 (0.68), Lantern in the fight |
| 15 | 2,600 | ~3,240 (1.25) | ~4,460 (1.72) | 692/694 / 773/775 | 0.43 / 0.35 | ~2,100 (0.8) |

That matches the brief's shape. The strong round 12 board averages about 60/60 a unit, with the Diva at about 190/190. Battlegrounds keeps 33–35% of the board in its biggest unit; Bog keeps 35–43%. The model is generous: every find arrives on time, and 90% of enemy attacks land on Bitter units. Read these numbers as a ceiling for an average shop.

**Why it can't snowball often.**
- Takes come from the enemy's Attack, not Bog's lead. A Bog player who is ahead faces opponents of normal size and drinks a normal amount.
- Soak fires in losses as well as wins, so winning doesn't speed it up.
- Bog's board converges to a fixed multiple of the field (about 1.25× without the King, 1.75× with), and the multiple is set by k. It can't run away from the field.
- The tail comes from goldens: golden Soak takes half, golden Tiddy pays double, a golden King triples. That needs triples of tier 4–6 cards, so it is rare.
- The flip side: against a weak lobby or a ghost, Bog grows slowly. Bog can't feast on a small field.

**When the build comes online.**
- **Carry line:** round 9 (Tiddy's second fight; the Diva is bigger than their carry). Level on board total at round 11. Clearly ahead from round 12 with the King.
- **Swamp line:** round 6 (Gideon, the Chorus, Bufo and Nan: four patches and Bitter across the whole front row).

**The decision the engine creates: is their carry food or a threat?** Each round the scout shows their biggest unit. You can:
- **feed on it:** put the Diva across it. She drinks a quarter of its Attack each bite, the biggest drink on offer, but she takes its hits;
- **fell it:** put Madame Bufo across it, or let Jenny and Hopkin kill it before it swings. That's safer, but a halved or dead giant gives the Diva half the drink or none;
- **leave it free:** lock their supports instead, and let your Bitter front row take its hits.

On top of that: the Diva in front (more bites, and Hopkin vaults off her) or in the back (the Prima Donna pulls their back row, and she's protected); and who wears the crown when Tiddy arrives.

---

## 5. Routes

### The Diva (the carry route)

- **Pick.** The Diva is your Bog folk unit with the most Health. Before Tiddy arrives (about round 7), steer the crown. The Toad that has Soaked since round 1, or Gideon at 6 Health, or a Health spell on the one you want. Ties go to reading order, so placement can crown her. After Tiddy, the funnel keeps her on top.
- **Grow.** Soak on her own bites; Tiddy's funnel from every other Bitter unit; the Peat King doubles her Soak; across their biggest for the biggest drink.
- **Protect.** Bitter shrinks every biter first. Soak's gain lands before the hit, so each bite costs her about half its Attack. Mire picks her biters. The back row (the Prima Donna in B2) keeps the rest off her.
- **Express.** Hopkin vaults with half her Attack; Sal fires half her Attack as fireworks; the Prince carries half her stats; Jenny makes their carry the target for all of it.
- **Core cards:** Bridge Toad, Gideon, Madame Bufo, Vaulting Hopkin, Tiddy Mun, His Highness, the Prima Donna, Jenny, the Peat King.
- **Loses to:** Health-halving on the Diva (Nightshade), destroy or shrink-the-biggest answers at Start of Combat, and boards of many small hitters that give her little to drink.

### The Swamp (the non-carry route)

- **Shape.** Bitter on every front unit (Nan, Bufo, Jenny, the Chorus), several Soak toads growing evenly (Bridge Toad, Gideon, the Chorus's neighbours, the Prima Donna), and frogs that reach the stuck (Pretender, Ranocchio, His Highness). It ends with the Lantern Man, who swings with everything the bog has taken this fight.
- **Wins by:** shrinking every enemy that bites a toad by a quarter, again on each bite, and sniping what's stuck. It is stat-light (about 0.7 of the field at round 12) and answer-heavy.
- **Best against:** lobbies full of carries; Bellies (units emerge onto patches).
- **Pivot:** take Tiddy late and the biggest Soak toad becomes a Diva.

---

## 6. Placement is the decision

The 4–3 board gives Bog six real choices each round. Each one has a cost.

| Choice | Option A | Option B |
|---|---|---|
| Who is across their biggest | The Diva: biggest drink, biggest risk | Bufo: their carry at three eighths, but a smaller drink later |
| The Diva's row | Front (F2/F3): Mires their front, takes extra bites, and Hopkin vaults off her | Back (B2, the Prima Donna): pulls their whole back row, protected from the rest |
| Hopkin's slot | Behind a front-row Diva: half her Attack, first | With the Diva in the back: behind Gideon or the King, for a smaller vault |
| Nan and the Chorus | Beside units without Bitter (frogs, neutrals, Jenny, Bufo) | Beside toads that already have it: wasted |
| Reading order | Sturdiest mirer first, so it claims the patch | A fragile mirer first loses the lock when it dies |
| Crown ties | Put the toad you want crowned earlier in reading order | |

**A worked round 12.** The scout shows their carry, 113/138, in B2, behind a 38/47 front row.
```
F1 Gideon 54/58      F2 Bridge Toad, Diva 196/198      F3 Madame Bufo 1/4      F4 The Peat King 23/27
          B1 Vaulting Hopkin 3/1      B2 The Prima Donna 113/119      B3 Tiddy Mun 3/5
```
- The Prima Donna in B2 bogs their B1, B2 and B3. Their carry must bite her: it loses 29, and she Soaks +58/+58 with the King before an 84 hit. She lives and hits back for 171.
- Hopkin in B1 vaults first off the Diva in F2, for 98, into their carry. It is at 40 before it ever swings.
- Their front four swing into Bitter toads and lose a quarter each. Tiddy sends every point to the Diva.
- **The alternative:** the Diva in B2 instead of the Prima Donna. She drinks the carry's bite herself (+29/+29 on top of the funnel), but nobody vaults off her and the front row is thinner. That's the round's real decision.

**The opponent's side.** Against Bog, a back-row carry gets dragged into a Prima Donna, and a front-row carry gets Mired by front toads and vaulted. Jenny finds it anywhere. So the counter to Bog is to spread stats, or to carry a unit with more Health than the Diva has Attack. That's a meta check the owner asked for: answers that sometimes reach a carry.

---

## 7. Answers to other tribes' carries, and weak points

**What Bog brings, by reach:**
- **Across (placement):** Bitter on every bite, Bufo's halving, the Diva's drink, Gideon's counter. These land when the scout reads right.
- **Mired anywhere:** Snap frogs, Hopkin's vault, Sal's fireworks, the Lantern Man. They need the carry on a patch.
- **Any row:** Jenny Greenteeth, tier 5. She puts the patch under the biggest enemy, so everything above lands.

**By tribe (as their pass 3 carries look so far):**
- **Hedgerow (Pass carry in the last slot, F4 on a full board; Hunker walls).** A mirer in F4 finds the Pass carry. Bufo halves it, or the Diva drinks it. Hunker walls are slow food: they hit softly and halve the Diva's hits. Grind them with Sal and the counter.
- **Birds (the Chick; Eggs).** The Chick hunts the biggest enemy, so it bites the Diva, and she drinks it. Eggs have no Attack, so Mire on a Nest is wasted: put a cheap unit across it. A flown Chick dodges every patch for two fights.
- **Hunters (Pack and focus fire).** A Mired Hunter must bite its toad, and Pack joins only at the maker. **Weak point:** Pack joiners keep their Attack (9.6.0), so a Pack bite gets past Bitter.
- **Oozes (Bellies).** Every unit out of a Belly lands on the patch, is Mired and gets split by Sal. Hasty Pudding swallowing a mirer ends its lock.
- **Fairies (a Queen-fed Fairy; Rings).** Jenny and Bufo answer the single pile. **Weak points:** the Changeling swaps with a mirer and takes its side, and Nightshade on the Diva halves her Health every bite.

**Weak points overall:**
1. **Wide and token boards.** Small bites mean small drinks, and a patch holds one unit of seven. Sal is the patch.
2. **Damage that isn't an attack.** Start of Combat shots, Mother Goose's strikes and cleave splash skip Bitter and Soak entirely.
3. **Low-Attack walls** (Hunker, Shell, Eggs). Nothing to drink, slow to kill.
4. **Health-halving and side-swapping:** Nightshade, the Changeling, and any "shrink the biggest" answer at Start of Combat. The Diva holds 35–43% of the board, so answers hurt Bog most.
5. **A weak field.** Bog grows with its opponents, so ghosts and small boards starve it.
6. **Rounds 8–10 on the carry line.** About 0.75 of the field before the funnel builds. The tempo line covers this window.
7. **Scouting.** Across answers are only as good as the read. Harness field fights use blind layouts, which is the honest test.

---

## 8. Two highroll moments

**1. She drank their giant.** Round 13. A golden Prima Donna is your Diva in B2, and the Peat King is on the board. Their Hedgerow carry, 400/480 and twice the field's, sits in their B2 and must bite her. Golden Bitter takes half: it swings at 200. Before the hit lands she Soaks +400/+400 (half, doubled by the King). She takes 200, hits back for over 700, and it dies. The next shop shows her at about 700/720, permanently, and the Prince beside her is 356/367. *Needs: a triple of a tier 5, the King, and a giant across. Top-percent rare.*

**2. The frog was a prince.** A golden His Highness (a tier 4 triple by round 8) gets his third kiss in the round 10 fight. In the next shop the golden Prince Restored has his own 12/14 plus the Diva's full stats: about 127/131. By round 12 he is about 198–208/202–212 and growing with her, a second carry from a frog nobody believed. *Needs: three copies of a tier 4 and a Bog board that kills Mired enemies. Rare, and the owner's "rewards give power" moment.*

---

## 9. Harness lines

Card ids are the content ids. Both lines commit to Bog folk. "Keep" means don't sell while it can stay.

### Line T, `line_bog_tempo`: the Swamp

```json
{
  "tribe": "Bog folk",
  "priority": ["prima_donna", "peat_king", "lantern_man", "gideon", "natterjack_chorus",
               "signor_ranocchio", "jenny_greenteeth", "madame_bufo", "his_highness",
               "spitfire_sal", "bridge_toad", "young_pretender", "warty_nan",
               "peat_cutter", "vaulting_hopkin", "tiddy_mun"],
  "climb_schedule": [3, 5, 7, 9, 12],
  "save_threshold": 0,
  "save_until": 0,
  "engine": false
}
```
- **Plan:** a full board from round 5, Bitter on every front unit by round 6, four patches by round 7. Buy every turn; never save.
- **Keep:** every Soak unit and the Chorus. Sell order: Pretender (round 6), Peat Cutter, Nan, Hopkin.
- **Late:** the Lantern Man over the Peat King if both show. Tiddy last: the line pivots to a Diva only from round 11.

### Line C, `line_bog_engine`: the Diva

```json
{
  "tribe": "Bog folk",
  "priority": ["tiddy_mun", "prima_donna", "peat_king", "gideon", "bridge_toad",
               "jenny_greenteeth", "his_highness", "vaulting_hopkin", "madame_bufo",
               "natterjack_chorus", "spitfire_sal", "warty_nan", "signor_ranocchio",
               "lantern_man", "peat_cutter", "young_pretender"],
  "climb_schedule": [2, 4, 6, 9, 11],
  "save_threshold": 4,
  "save_until": 10,
  "engine": true
}
```
- **Plan:** Bridge Toad round 1. Tier 2 on round 2 (4 gold). Bufo round 3. Tier 3 round 4. Gideon and Nan round 5. Tier 4 round 6. Tiddy and Hopkin round 7. His Highness round 8. Tier 5 and the Prima Donna round 9. Tier 6 and the Peat King round 11.
- **Save:** end rounds 7–8 with 4 gold, so round 9 can tier up (8) and buy the Prima Donna (3). End round 10 with 4, so round 11 can tier up (11) and buy the King (3). The harness holds the reserve from the first round with 3 units on the board, so it also saves a little on rounds 5–6; an optional `save_from: 7` field would match the plan exactly.
- **Keep:** never sell the Diva. Keep Bridge Toad from round 1 if nothing passes its Health by round 7. Sell order: Pretender, Peat Cutter, Nan, Ranocchio, then Hopkin when the King needs his slot.
- **Placement hints for the placer:** the Diva or Bufo across the scouted biggest enemy; the Prima Donna in B2 when their carry is in the back row; Hopkin in the back slot behind the Diva; Nan and the Chorus beside units without Bitter; Jenny anywhere, away from the Diva's patch.

---

## 10. Engine support needed

| Need | For | What | Size |
|---|---|---|---|
| Proportional Bitter | All Bitter and Soak | Track B's `percent` on Bitter, plus: round **up**; golden or golden-lent takes half; one Bitter per unit (keep the strongest). | Small |
| Soak | Bridge Toad, Gideon, the Prima Donna, the Peat King, lent by the Chorus | At Bitter's declaration, the owner gains +k/+k permanently per Attack taken, before damage, kept on death. Jack Daw's "gains exactly the Attack removed" is the pattern. | Small |
| Soak multiplier | The Peat King | Your Bog folk's Soak × (1 + 1 per King, +2 if golden). Additive, never recursive. | Small |
| Diva selector | Tiddy, Sal, the Prince | A friendly selector: Bog folk with the most base + permanent Health, ties in reading order, fixed at Start of Combat. Crown badge in board, shop and scout. | Small, plus UI |
| Funnel | Tiddy Mun | After a friendly unit other than the Diva has Bitter take Attack: the Diva gains +1/+1 permanently per point (golden +2/+2). Not Soak. | Small |
| Borrowed Attack | Vaulting Hopkin | Its attack uses half (golden: all) the highest Attack among the units in front of it, if higher than its own. Attack-only override. | Small |
| Biggest-enemy patch | Jenny | Lay the patch on `biggest_enemy`'s slot (golden: the two biggest), before every other patch in the Mire step. | Small–medium |
| Split damage | Spitfire Sal | Start of Combat, after Mire: half (golden: all) of the Diva's Attack, split evenly among Mired enemies, rounded down. | Small |
| Proportional gain from the target | Signor Ranocchio | After attacking a Mired enemy: +1/+1 permanently per 4 of its Attack (`stat_fraction` gain from the target). | Data |
| Echo aura | The Prince Restored | A standing aura of half (golden: all) the Diva's current Attack and Health. It doesn't count when choosing the Diva. | Small–medium |
| Fight counter | The Lantern Man | +1/+1 (golden +2/+2) per Attack your Bitter has taken this fight, live. | Small |
| Remove caps | Data | Bridge Toad's `permanent_buff_cap`, the Prima Donna's once-per-enemy, the Peat Cutter's lifetime, Ranocchio's once a fight, His Highness's spell discount. | Data |
| Tier swaps | Data | Tiddy to tier 4 at 3/5; Jenny to tier 5 at 4/7. | Data |
| Screens | UI | Crown badge; Soak totals in the fight summary ("Bridge Toad soaked +38/+38"); the tray shows each mirer's patch and the take it would make from the scouted enemy. | UI |

---

## 11. Loops and runaway checks

| Risk | Check |
|---|---|
| **Soak against Soak** (a Bog mirror). Each bite grows the bitten. | It converges: a bite deals three quarters and gives back one quarter. Two 100/200 Soak toads trade three bites and both are dead. The 200-attack limit backs it up. |
| **The engine running away.** | Takes come from the enemy's Attack, so Bog converges to a multiple of the field (model: 1.25× without the King, 1.75× with). Turn k first, then the King's multiplier. |
| **Answer stacking** (Bitter + Bufo + Hopkin + Sal + Jenny). | Measure it with the plan's answer bar: a common board with one answer must still sometimes beat a carry. If Bog wins too often, the first lever is Bitter at a fifth, the second Hopkin back to a quarter. |
| **Hopkin, Jenny and a front Diva** killing the field's carry before it swings. | At half the Diva's Attack it leaves the carry at about 30% (round 12). Full share (golden) kills it, which is a golden reward. |
| **The Prince's echo.** | It can't read itself, and the Diva is chosen without auras. |
| **Two Peat Kings.** | Multipliers add (×3), never multiply. |
| **The Peat Cutter's gold.** | "Once a fight" stays as an economy loop guard: patches → gold → patches. |
| **Bitter on tiny attackers.** | Never below 1 Attack, so a 1-Attack token gives nothing. Two Bitter units facing each other still trade. |
| **Five digits.** | Typical Divas reach 4 digits by round 15 (about 700–775). Five digits need golden Soak plus the King around rounds 15–16: top-percent only. Track B's phone check says five digits clip, so the UI needs its badge layout before that era. |
| **Field-proportional design under the sweep.** | On today's flat pool, Bog stays flat too. The sweep must measure Bog against a field that compounds, or its numbers will read low. |

---

## 12. What changed from pass 2

| Card | Was | Now |
|---|---|---|
| Bitter (rule) | Loses N Attack, flat | Loses a quarter, rounded up; one per unit; golden takes half |
| Soak, Diva | — | New keyword and new term |
| Bridge Toad | Mire; +1/+1 after its Mired enemy attacks, up to +3/+3 | Mire. Soak. No cap |
| Warty Nan | Bitter 1, lends Bitter 1 | Bitter, lends Bitter (proportional) |
| Young Pretender | Same | Same |
| Madame Bufo | Mire, Bitter 2, halves her killer | Mire, Bitter (proportional), halves her killer |
| Vaulting Hopkin | Snap; back row, first, +2 Attack | Snap; back row, first, with half the highest Attack in front |
| The Peat Cutter | Gold on a Mired death, once a fight, three times in all | Same without "three times in all" |
| The Natterjack Chorus | Lends Mire and Bitter 1 to any units | Lends Mire and Soak to Bog folk |
| Gideon | Mire; counter with +2 Attack | Mire, Soak; counter at his own Attack |
| Spitfire Sal | 2 damage to each Mired enemy | Half the Diva's Attack, split among Mired enemies |
| Tiddy Mun | T5 3/6; +1/+1 to the unit hit, twice a fight | **T4** 3/5; the Diva gains +1/+1 per Attack any other Bitter takes |
| His Highness | Kisses → Prince 6/7 with a spell discount | Kisses → Prince with half the Diva's stats as extra |
| Signor Ranocchio | +1/+1 after attacking a Mired enemy, once a fight | +1/+1 per 4 of that enemy's Attack, every attack |
| Jenny Greenteeth | T4 3/5; Mire, −2 Attack, a neighbour strikes | **T5** 4/7; Mire the biggest enemy, any row; Bitter |
| The Prima Donna | Mire three slots; Bitter 2 once per enemy | Mire three slots; Soak |
| The Peat King | Mire; Peatlings on Mired deaths, twice a fight | Mire, Soak; your Bog folk Soak double |
| The Lantern Man | Snap; +3 Attack per Mired enemy | Snap; +1/+1 per Attack your Bitter has taken this fight |
| Peatling (token) | Summoned by the Peat King | Unused, kept in reserve. Variation: "Peat King: after a Mired enemy dies, a Peatling with Soak rises in the nearest empty slot", if the King's doubler proves too strong or too quiet |

**Payoffs that last one fight:** 9 of 13 before; now the six that are answers or a finisher (Nan, Bufo, Hopkin, Sal, Jenny, the Lantern Man). Every engine and carry payoff is permanent and shows in the shop.

---

## 13. Calls for the judges and the critic

1. **Soak before or after the damage.** Before makes the Diva a real holding carry (a bite costs her about half). After is simpler, but she dies to carries her own size. I chose before; the sweep can test both.
2. **The Diva by most Health, or a crown the player places.** Most Health needs no new control and reads at a glance. A placed crown is a cleaner decision but adds UI. I chose most Health, with reading order breaking ties.
3. **Jenny at tier 5.** The only row-ignoring Bog answer. At tier 4 she would make every Bog board a reliable carry-killer from round 7.
4. **Tiddy at tier 4.** It moves the Diva online from round 11 to round 9. If the carry line is too strong at rounds 9–11, move it back.
5. **The engine mirrors the field.** It's the answer tribe's nature, and the anti-snowball property I'd defend hardest. The cost: Bog can't make its own tail without goldens. If the judges want Bog to be a tail-maker too, the fix is a self-proportional capstone (for example, the Peat King: "End of Turn: your Diva gains a tenth of her stats"), tested against the snowball bar.
