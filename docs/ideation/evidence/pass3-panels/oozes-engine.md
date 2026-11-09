# Oozes, pass 3: the Back Burner (engine-first design)

9 Nov 2026. A Track C designer, angle **engine first**. Read: owner notes 09a, 09c, 09d and 08e; `fundamentals.md` §1 and §3; `plan-scale-rework.md` (Step 1, Track C); rulebook §8–9 and the ideation rules; `wording-guide.md`; `content/oozes.md`, `content/pass2-b.md`; the 16 slice Ooze cards; `card-audit-hedgerow-hunters-oozes.md`; `reference-curves.md`; the Track B mechanics on `ideation/mechanics`. No price list was used. Numbers come from a small board model (§11), not from fights.

**In short.** Oozes keep their Bellies. In the back row, an Ooze's Belly now **simmers**: at End of Turn, whatever is inside gains half its stats. A unit you put on the back burner at round 5 fights at round 12 as a 63/94. Every 3 gold asks the same question: a body for the front row that fights now, or dough for the back row that fights later, half as big again every turn. All 16 creatures, names and portraits stay, at the same 3/3/3/3/2/2 tier spread.

---

## 1. The engine: Simmer

**Simmer** (keyword, on 5 cards). *Reminder: End of Turn, in the back row: what's inside this gains half its stats.*

- **Why this engine.**
  - It grows what the tribe already has: the unit inside a Belly.
  - It compounds by itself. A share of the stats a turn is the target shape (×1.5 a round). Gold buys the seed; time does the rest.
  - It's permanent and visible. The unit inside shows its stats on the card in the shop, on the board and in the scout.
  - It's neutral on distribution. Every unit inside grows by the same share, so carry or wide is a fighting choice, not an efficiency trap.
  - It uses the 4-3 board. The back row is the back burner. Three slots fit three ovens, and the front row has to protect them.
- **Rate parameter: r**, the share gained per Simmer. Default **½**. Sweep 0.4, 0.5 and 0.6.
  - The card must say a plain fraction (a third, half, two thirds). If the sweep lands between two of them, keep the nearer fraction and move the rest into Granny's multiplier or the oven count.
  - Rounding is down, as Track B's `stat_fraction` already does. So a 1/1 never grows, and small dough starts slowly, which helps make the engine "behind at once".
- **The decision it creates (invest now or tempo now).**
  1. **Each 3 gold:** a body for the front row, which fights now, or dough for a back-row oven, which fights only once the front row falls but grows by half every turn.
  2. **Each oven, each turn:** keep it in the back (it simmers, and its riser fights late) or move it to the front (its riser fights as soon as the shell dies, but it doesn't grow that turn).
  3. **Each Belly:** dough (invest), a spare life (tempo), or empty for Hasty Pudding (answer).
  4. **At tier 6:** one giant (Granny doubles it) or many slices (Cut-and-Come-Again).
- **When it comes online.**
  - **Round 5:** first oven (Aunt Aspic, tier 3) plus dough. The board is a little behind: 43 against a target of 55 at round 6.
  - **Rounds 8–9:** level (157 against 150 at round 9).
  - **Rounds 11–12:** clearly ahead once Granny or Elder lands (689 against 500 at round 12).
  - The tempo line has the opposite clock: ahead from round 6, folding into Simmer through Elder Ooze at round 9.
- **Nearest relatives.** Compound interest. Battlegrounds has no stored unit that grows. Its End of Turn doubler (Drakkari Enchanter) is the closest feel, and Track B's synthetic doubler copies it.

### The shape against the target (board model, r = ½)

Board stats = units on the board plus units inside Bellies, at combat start. "Target" means about 100 at round 8, then ×1.5 a round (the September 2025 shape).

| Round | 6 | 9 | 12 | 15 |
|---|---|---|---|---|
| Target median | 55 | 150 | 500 | 1,700 |
| Today's bots (median, insides not counted) | 52 | 92 | 133 | about 165 |
| **Ooze tempo line, typical** | 61 (1.1×) | 196 (1.3×) | 589 (1.2×) | 2,232 (1.3×) |
| **Ooze engine line, typical** | 43 (0.8×) | 157 (1.05×) | 689 (1.4×) | 2,037 (1.2×) |
| Ooze engine line, strong (golden Aspic, Granny at round 10) | 43 | 219 (1.5×) | 971 (1.9×) | 2,948 (1.7×) |
| Highroll: strong line plus the neutral End of Turn doubler from round 12 | 43 | 219 | 1,378 | 14,122 (8.3×) |

- The biggest unit is about 57% of the typical engine board at round 12 and 65% at round 15. On the tempo board it's 50% and 44%. Battlegrounds is about 34%. See the risk in §10.
- **r = 0.4:** the typical engine falls behind late (468 at round 12, 1,074 at round 15).
- **r = 0.6:** it runs at 1.8–1.9× (883 and 3,223). So ½ is the reasoned default.
- **Rejected: Granny "Simmer twice".** It reaches 2.8× the median by round 15, with the carry holding 85% of the board. That's a perfect-game level for a common line. Granny doubles a unit once instead (§2, card 15).

---

## 2. The 16 cards

| Tier | Card | A/H | Text |
|---|---|---|---|
| 1 | Little Dollop | 2/2 | Belly 1. Buying into a Belly costs 1 less. Once a turn. |
| 1 | Wee Wobbly | 1/4 | Belly 1. After this survives a hit: summon a 1/1 Drip. Twice a fight. |
| 1 | Mrs Posset | 2/1 | Belly 1. When this dies: the enemy across loses half its Health. |
| 2 | Dishwater Nell | 1/3 | Start of Turn: put your shop's lowest-tier unit into a Belly. |
| 2 | Moss Ooze | 2/4 | Belly 1. Your spells on an Ooze also reach what's inside. |
| 2 | Stone Soup | 2/3 | Belly 1. After you put a unit into a Belly: gain +1/+1 permanently. |
| 3 | Aunt Aspic | 2/4 | Belly 1. **Simmer.** |
| 3 | The Sixpenny Pie | 2/5 | Belly 2. When this dies: get 1 gold next turn per unit that comes out. |
| 3 | Bubble and Squeak | 3/4 | Belly 1. After you sell a unit: what's inside this gains its stats. |
| 4 | Frumenty | 2/4 | Belly 1. **Simmer.** This has the text of what's inside it. |
| 4 | Figgy Duff | 3/5 | Belly 1. What's inside goes golden with one more copy. Once every other turn. |
| 4 | Mr Syllabub | 3/6 | When a unit comes out of your Oozes: it gains **Shield**. |
| 5 | Elder Ooze | 4/8 | Belly 1. This and the Oozes beside it **Simmer** in any row. |
| 5 | Hasty Pudding | 2/8 | Belly 1. Start of Combat: if this has room, swallow the biggest enemy. |
| 6 | Granny Stir-Up | 6/10 | Belly 1. **Simmer.** After a unit goes into this: double its stats. Once per unit. |
| 6 | Cut-and-Come-Again | 4/7 | Belly 1. **Simmer.** Every other Start of Turn: get a half-stat copy of what's inside. |

Token: **Drip**, Ooze, 1/1, no text (unchanged).

**Word count.** The median is 12.5 words, p90 is 15 and the longest is 15, against the guide's median of 11 or less. "Belly N." costs 2 words on 13 cards; without it the median is about 11. I'm flagging this rather than cutting a condition (guide rule 8).

The rough stats in each card's **payoff** line are on a typical board of its line at rounds 9, 12 and 15, r = ½ (§11).

### Tier 1

**1. Little Dollop** (Custard Ooze), 2/2, front.
- **Golden (4/4):** Belly 2. Buying into a Belly costs 2 less. Once a turn.
- **Condition:** you buy a unit straight into any Belly.
- **Payoff:** 1 gold off one dough a turn. That's about 4 gold saved by round 9, 7 by round 12 and 10 by round 15: one extra dough every three turns. It also gives a front body and a spare life (a tier 1 unit, about 2/3).
- **Permanence:** economy, every turn.
- **Enables:** every oven (cheaper dough), Stone Soup (each buy is a feed), Figgy Duff (a copy waiting inside).
- **Concentrates:** no.
- **Change:** the discount was for "into this", with no limit. It now covers any Belly once a turn, so stacked Dollops can't make dough free.

**2. Wee Wobbly** (Junket Ooze), 1/4, front.
- **Golden (2/8):** Belly 2. After this survives a hit: summon a 2/2 Drip. Twice a fight.
- **Condition:** it survives an enemy hit.
- **Payoff:** two extra bodies a fight, each soaking one whole enemy attack: about 15 damage at round 9, 70 at round 12 and 250 at round 15. Then its spare life comes out.
- **Permanence:** the Drips last the fight; the spare life is permanent.
- **Enables:** Mr Syllabub (Shielded Drips soak two hits each), Elder Ooze (Drips count as coming out, as ruled for Elder in 12.1.2b).
- **Concentrates:** no.
- **Change:** the early release is dropped to shorten the text (19 words down to 13). Its Belly now opens normally.

**3. Mrs Posset** (Hot Milk Ooze), 2/1, front, across a scouted target.
- **Golden (4/2):** Belly 2. When this dies: the enemy across and those beside it lose half their Health. (Fractions don't double on golden, per Track B, so golden widens the reach instead.)
- **Condition:** she dies, and an enemy stands across.
- **Payoff:** half that enemy's Health, as a stat change that ignores Shield. That's about 8 at round 9, 40–60 at round 12 (a 100-stat unit) and 150–300 at round 15 (a carry).
- **Permanence:** fight only.
- **Enables:** Hasty Pudding (one takes the biggest enemy, the other halves the second), Bodies (a halved carry dies to fewer chumps).
- **Concentrates:** no (an answer).
- **Change:** 3 damage becomes half its Health. A tier 1 unit becomes scam that still matters at round 15, but it aims across, so it lands only where you placed it after scouting.

### Tier 2

**4. Dishwater Nell** (Scullery Slime), 1/3, back.
- **Golden (2/6):** Start of Turn: put your shop's two lowest-tier units into Bellies.
- **Details:** the first Belly with room, in reading order (front row first). The unit is Created. With no room, nothing happens.
- **Condition:** a Belly with room at Start of Turn.
- **Payoff:** a free unit, worth a 3-gold buy, about 0.6 turns in 1. That's about 3 units by round 9, 5 by round 12 and 7 by round 15. One that lands in an empty oven at round 8 is about 30 stats by round 12 and 100 by round 15.
- **Permanence:** economy; the units are permanent.
- **Enables:** Stone Soup (every free unit is a feed), Figgy Duff (free copies), front Bellies (spare lives), ovens (free dough).
- **Concentrates:** no.
- **Change:** "swap the lowest unit and maybe get 1 gold" had three conditions. Now she just eats the leftovers into your Bellies. Keeping the front Bellies full makes her feed the ovens: a placement puzzle.

**5. Moss Ooze**, 2/4, either row.
- **Golden (4/8):** Belly 2. Your spells on an Ooze also reach what's inside, twice over.
- **Condition:** you cast a stat spell on an Ooze that holds something.
- **Payoff:** the spell's stats also land inside, and from there they simmer. A +2/+2 on a riser at round 8 is +4/+4 by round 9, +15/+15 by round 12 and +51/+51 by round 15. Last Orders at round 12 with 20 gold (+10/+10) becomes +34/+34 by round 15. Group spells (Bread from the Back, Stand Behind Me, Beltane Bonfire) reach every Ooze they hit.
- **Permanence:** permanent.
- **Enables:** heat for every oven; the gold-to-stats spells.
- **Concentrates:** partly (aim at the carry's oven).
- **Change:** it gains Belly 1, so it's a tier 2 Belly for Nell, and casting on Moss reaches its own inside.

**6. Stone Soup** (Broth Ooze), 2/3, front.
- **Golden (4/6):** Belly 2. After you put a unit into a Belly: gain +2/+2 permanently.
- **Details:** a unit from the shop, your hand or your board counts. Its own Belly counts.
- **Condition:** any unit goes into any Belly (Recruit Phase).
- **Payoff:** +1/+1 a feed, about 1–2 a turn early and fewer late. It's about 7/8 at round 9, 10/11 at round 12 and 12/13 at round 15, plus its spare life.
- **Permanence:** permanent.
- **Enables:** it's the bridge. Investing in dough also gives a little tempo up front. Nell and Dollop feed it. Late, an emptied Soup is fine dough itself.
- **Concentrates:** yes, slowly (itself).
- **Change:** the once-a-turn limit is removed. Belly room already bounds the feeds.

### Tier 3

**7. Aunt Aspic** (Savoury Jelly), 2/4, **back**. The first oven.
- **Golden (4/8):** Belly 2. Simmer. That's two risers in one back slot.
- **Condition:** she's in the back row with a unit inside at End of Turn.
- **Payoff:** a 3/4 dough at round 5 is 19/28 at round 9, 63/94 at round 12 and 211/316 at round 15. With light heat it's 76/108 at round 12. Her riser is the tribe's natural carry: in an exponential engine the oldest investment is the biggest.
- **Permanence:** permanent and visible.
- **Enables:** every heat card, Granny (the riser to double), Mr Syllabub (it comes out Shielded).
- **Concentrates:** yes.
- **Change:** she used to feed the Bellies in front of her +1/+1. She's now the plain engine piece, which is why the text is three words.

**8. The Sixpenny Pie** (Pudding Ooze, Very Full), 2/5, front.
- **Golden (4/10):** Belly 4. When this dies: get 1 gold next turn per unit that comes out. (The gold stays at 1 a unit; the doubled Belly already doubles the most it can pay, to 4.)
- **Details:** a unit with no room to come out doesn't count.
- **Condition:** it dies in a fight, holding units, with room for them.
- **Payoff:** up to 2 gold a fight, about 1.5 on average. That's about 6 gold by round 9, 10 by round 12 and 15 by round 15, plus two spare lives. Beside Elder Ooze those two insides simmer while they fight: 13/19 and 19/19 at round 12, 42/63 and 63/63 at round 15.
- **Permanence:** economy and permanent spare lives.
- **Enables:** gold for dough; Figgy Duff (two copies waiting for the third); Elder Ooze (two insides for one lamp).
- **Concentrates:** no.
- **Change:** this is pass 2's per-unit gold. "When the pie was opened, the birds began to sing."

**9. Bubble and Squeak** (Two Oozes, Barely), 3/4, either row.
- **Golden (6/8):** Belly 2. After you sell a unit: what's inside this gains its stats. (Both insides gain them, so golden creates stats rather than moving them.)
- **Condition:** you sell any unit.
- **Payoff:** each sold unit's current stats move into its inside. That's about +15 by round 9, +50 by round 12 and +150 by round 15 before any Simmer. Beside Elder Ooze the pot compounds: about 108/126 at round 12 and 364/424 at round 15.
- **Permanence:** permanent.
- **Enables:** it turns the late game's board churn into a carry; it feeds Granny (the pot is ready dough).
- **Concentrates:** yes. Base B&S moves stats and doesn't create them, which is the owner's "concentrating beats spreading" as a card.
- **Change:** splitting becomes eating the leftovers, which is what bubble and squeak is.

### Tier 4

**10. Frumenty** (Porridge Ooze, Cook's Taster), 2/4, **back**. The second oven.
- **Golden (4/8):** Belly 2. Simmer. This has the text of what's inside it.
- **Condition:** in the back row with a unit inside, to simmer; any row for the text.
- **Payoff:** a 3/6 put in at round 7 is 9/19 at round 9, 28/63 at round 12 and 94/211 at round 15. Its text works from Frumenty's slot the whole time it grows.
- **Permanence:** permanent.
- **Enables:**
  - any tribe's text unit as dough, so its body grows while its text works;
  - Granny, who doubles the grown riser.
  - It can't lend Belly, Fly South, Shy, or on-play, on-sell or homecoming text (existing rulings).
- **Concentrates:** yes (the second riser).
- **Change:** it now has Simmer. Porridge is the dish that simmers.

**11. Figgy Duff** (Boiled Ooze, Sees Double), 3/5, back.
- **Golden (6/10):** Belly 2. What's inside goes golden with one more copy. Once a turn.
- **Details:** the golden goes to your hand. Copies from Cut-and-Come-Again don't count.
- **Condition:** a unit inside it plus one more copy anywhere.
- **Payoff:** a golden plus a Triple Reward (a Discover from the tier above) every other turn. That's about 1 by round 9, 3 by round 12 and 4 by round 15. A golden oven holds two risers in one back slot; golden dough starts twice as big.
- **Permanence:** permanent.
- **Enables:** ovens (golden Belly 2), Nell (free copies), the Pie (copies waiting).
- **Concentrates:** no.
- **Change:** the "bought" copy condition is gone, so the text is shorter. The every-other-turn limit is a loop guard, because Nell feeds it free copies.

**12. Mr Syllabub** (Whipped Ooze, Light Sleeper), 3/6, back.
- **Golden (6/12):** When a unit comes out of your Oozes: it gains Shield and Damage Reduction 25%.
- **Condition:** units come out in a fight: shell deaths, and Wobbly's Drips.
- **Payoff:** each one comes out with **Shield** (Track B), so the first hit on it is free. On a typical board about 5 a fight come out, wasting about 5 enemy hits: about 60 damage at round 9, 300 at round 12 and 1,000 at round 15. The carry's first hit is free.
- **Permanence:** fight only, every fight.
- **Enables:** every Belly; a carry that holds its stats. In the audit's model a Shield is worth about 13 points.
- **Concentrates:** partly (it lets the carry keep its stats).
- **Change:** "its Start of Combat fires" (the Rude Awakening puzzle) is dropped for an engine that needs its risers to survive. It's kept below as a variation.

### Tier 5

**13. Elder Ooze**, 4/8, **front** (F2 or F3). The lamp.
- **Golden (8/16):** Belly 2. This and the Oozes next to it Simmer in any row. ("Next to" also covers the slots in front and behind.)
- **Condition:** Oozes holding units stand beside it.
- **Payoff:** up to three front Bellies simmer while they fight. Its own 5/8 dough is 22/40 at round 12 and 73/135 at round 15. Two lamped neighbours add about 70 by round 12 and 230 by round 15, more with the Pie's two insides. This is the wide route's engine.
- **Permanence:** permanent.
- **Enables:** the Pie, Bubble and Squeak, Stone Soup, Wobbly, Posset and Dollop (all front Bellies); Mr Syllabub.
- **Concentrates:** no.
- **Change:** "units coming out gain +1/+1" was too small for the new scale and lasted one fight.

**14. Hasty Pudding** (Steamed Ooze), 2/8, either row; the back keeps it alive longer.
- **Golden (4/16):** Belly 2. Start of Combat: if this has room, swallow the two biggest enemies.
- **Details:**
  - The unit goes back when this dies, after 3 of your units die, or when its side has nobody else.
  - If the biggest enemy is inside an Ooze, this swallows that Ooze.
- **Condition:** an empty Belly at Start of Combat. That costs a dough slot.
- **Payoff:** the enemy's biggest unit sits out for about a third of the fight: about 50 stats at round 9, 300–400 at round 12 and 1,000+ at round 15.
- **Permanence:** fight only.
- **Enables:** Posset (halve the next biggest). One anti-synergy: Drips that die count toward its release.
- **Concentrates:** n/a (an answer).
- **Change:** "the enemy across" becomes "the biggest enemy" (Track B's selector, any row). This is one of the two or three cards in the pool the plan allows to reach a back-row carry.

### Tier 6

**15. Granny Stir-Up** (Christmas Pudding, Everybody In), 6/10, **back**. The carry capstone.
- **Golden (12/20):** Belly 2. Simmer. After a unit goes into this: double its stats. Once per unit.
- **Details:** a unit any Granny has doubled shows a stir mark and can't be doubled again.
- **Condition:** you put a unit into her, usually your oldest riser, moved from its old oven by selling that oven.
- **Payoff:** a one-time ×2, then Simmer from there. Aspic's riser (34/48 after round 10) becomes 165/228 at round 12 and 555/769 at round 15. Without her it would be 76/108 and 256/364.
- **Permanence:** permanent and visible: the doubling shows the turn you do it.
- **Enables:** Aspic, Frumenty and B&S pots (ready-made carries); Mr Syllabub (the giant comes out Shielded).
- **Concentrates:** yes.
- **Change:** "touching Oozes go inside; gain their Attack" was a one-fight pile. Stir-up Sunday is one big stir.
- **Rate limit:** "once per unit" is a loop guard against sell-and-rebuy. It isn't a size cap.

**16. Cut-and-Come-Again** (The Pudding That Is Never Finished), 4/7, **back**. The wide capstone.
- **Golden (8/14):** Belly 2. Simmer. Every other Start of Turn: get a half-stat copy of each unit inside.
- **Details:** copies are Created. They can't triple or count for Figgy Duff, and selling one is final.
- **Condition:** a unit inside; the back row, to simmer.
- **Payoff:** Simmer plus a half-size copy of the riser every other turn. With a riser moved in at round 12 (139/154), the copies are about 70/77 at round 13 and 156/173 at round 15, and the riser itself is 468/519 at round 15. Copies put into ovens simmer too.
- **Permanence:** permanent.
- **Enables:** ovens (the copies are seeds); Granny (a copy put into a second Granny doubles back to full size).
- **Concentrates:** no. It turns one carry into many.
- **Change:** it used to make a base copy of a non-Ooze. A copy of the riser's current stats now matches the new scale; "every other turn" sets its rate.

### Variations to try (engine level)
1. **Simmer in any row.** Simpler and stronger. It loses the place-it-back-or-front decision, and Elder Ooze would need a new job.
2. **Simmer only if this didn't open last fight.** It ties growth to winning trades. More feedback, and so more snowball.
3. **Keep Mr Syllabub's old text** ("its Start of Combat fires") instead of Shield, if the judges value the Rude Awakening puzzle over carry survival. A Hasty Pudding inside a front Ooze then swallows the biggest enemy mid-fight.

---

## 3. Routes

**Carry route: one riser, doubled.**
1. Aunt Aspic at round 5 with the best dough.
2. Heat on that riser: Moss Ooze plus spells, Bubble and Squeak's pot, Harvest Supper when the dough is an Ooze.
3. At tier 6, sell Aspic and put her riser into Granny Stir-Up, which doubles it.
4. Keep Granny in the back. The carry fights whenever the front row falls, and Syllabub Shields it as it comes out.
5. Bring Granny forward only when Health is low.

Typical carry: 19/28 at round 9, 165/228 at round 12, 555/769 at round 15.

**Non-carry route: a wall of warm Bellies.**
1. Front Belly walls: the Pie, Stone Soup, Bubble and Squeak and Wobbly, with Elder Ooze in F2 or F3 so their insides simmer while they fight.
2. Mr Syllabub in the back Shields everything that comes out.
3. Cut-and-Come-Again turns the biggest riser into copies, which go into the empty ovens.

Typical board: 12–14 bodies, with the biggest at 44–50% of the stats. A carry needs about 19 swings to clear it: 14 bodies plus about 5 Shields.

Both routes use the same engine. They differ in where the heat goes and in which tier 6 card you take.

## 4. Answers and weak points

**Answers to other tribes' carries.**
- **Hasty Pudding:** swallows the biggest enemy in any row until the Pudding dies or 3 of yours die.
- **Mrs Posset:** the enemy across loses half its Health. It's scam that still matters at round 15, aimed by placement after scouting.
- **Bodies and Shields:** one giant swing only ever kills one pudding. Each Belly body and each Shield costs the carry a swing, and overkill is wasted.
- **Wee Wobbly:** two chump Drips a fight.

**Weak points.**
- **Rounds 4–8.** Gold sits in the back as dough; the shells are 2/4; the front row is thin. The engine line is at 0.8× the target at round 6.
- **Evenly sized boards.** A riser holding over half the board loses to an even board of the same total, because of wasted overkill (the audit: 9–20 points). Oozes need the total lead or the Shields.
- **Cleave.** It kills shells in pairs, so fewer exchanges are absorbed.
- **Soft damage.** Units inside are never starting survivors (10.1.4a), so Ooze wins hit for little. Games run long, with more ghost rounds.
- **Changeling.** It steals an oven, riser included, for a fight.
- **Hex.** Hex on the slot a riser comes out into.
- **The see-through rule (§9).** If adopted, biggest-enemy answers shrink a riser even while it's inside.
- **Hand pressure.** Selling an oven sends what was inside it to the hand (10 at most).
- **Pressure.** Being forced to fight with risers in front stops their growth, and so the engine's rate.

## 5. Two highroll moments

1. **"The pudding opens."** It's round 11. Your front row is gone, their 300-stat carry swings at Granny in B2, and out steps the hedgehog she doubled: 165/228 and Shielded. It eats their back row. You've watched that hedgehog swell since round 5.
2. **"Second Helping on the stove."** This is rare and late. The neutral End of Turn doubler makes every oven Simmer twice, so three risers grow ×2.25 a turn: 60/90, then 135/200, 300/450 and 680/1,000. The board passes 8× the median by round 15. This is the owner's top-1% tail; the sweep must check it stays that rare (§10).

---

## 6. Harness lines (`line_profiles` format)

**Climb schedule:** the rounds for tiers 2 to 6.
**Belly policy:** what the line brain needs on top of Hard's swallow logic. Without it the tribe looks weak for the wrong reason.

### Tempo: `line_oozes_tempo` ("Second Helpings")
```json
{
  "tribe": "Oozes",
  "priority": ["elder_ooze", "sixpenny_pie", "mr_syllabub", "wee_wobbly", "stone_soup",
               "mrs_posset", "bubble_and_squeak", "moss_ooze", "aunt_aspic", "hasty_pudding",
               "cut_and_come_again", "granny_stir_up", "little_dollop", "frumenty",
               "figgy_duff", "dishwater_nell"],
  "climb_schedule": [3, 5, 7, 9, 12],
  "save_threshold": 0,
  "save_until": 10,
  "engine": false,
  "engine_pieces": ["elder_ooze", "sixpenny_pie", "mr_syllabub", "cut_and_come_again"]
}
```
- **Save gold:** never before round 10. At rounds 10–11, keep 3+ for the tier 6 climb at round 12. After tier 6, spend everything.
- **Belly policy:**
  - Fill front Bellies first; the last in is the biggest body.
  - From round 9, put Elder Ooze in F2 or F3 with full Bellies beside it, the Pie first.
  - From round 8, put Aunt Aspic in the back with the biggest spare body.
  - Keep Hasty Pudding empty when the scout shows a unit at least 2× our biggest.
  - At round 12, Cut-and-Come-Again takes the biggest riser; its copies go into empty ovens.

### Engine or carry: `line_oozes_engine` ("Back Burner")
```json
{
  "tribe": "Oozes",
  "priority": ["aunt_aspic", "granny_stir_up", "frumenty", "little_dollop", "dishwater_nell",
               "stone_soup", "figgy_duff", "cut_and_come_again", "mr_syllabub", "moss_ooze",
               "sixpenny_pie", "hasty_pudding", "elder_ooze", "bubble_and_squeak",
               "wee_wobbly", "mrs_posset"],
  "climb_schedule": [2, 4, 6, 8, 10],
  "save_threshold": 2,
  "save_until": 10,
  "engine": true,
  "engine_pieces": ["aunt_aspic", "frumenty", "granny_stir_up", "cut_and_come_again", "little_dollop"]
}
```
- **Save gold:**
  - None at rounds 1–4 (climb at rounds 2 and 4).
  - At rounds 5–7, hold 2 when the turn can't buy an oven and its dough together.
  - At rounds 8–9, bank toward the tier 6 climb at round 10.
  - After tier 6, spend everything, except 6 for Hiring Fair if Granny isn't on the board by round 11.
- **Belly policy:**
  - Dough is the biggest unit on offer (golden, then an Ooze with Supper, then the highest tier), bought straight into an empty back-row oven with Dollop's discount.
  - Ovens stay in the back row.
  - Keep one front Belly open, so Nell's free units land in front rather than in an oven.
  - The turn Granny is bought, sell the oldest oven and put its riser into her.
  - Move the biggest oven to the front only when Health is 12 or less, or after two lost fights in a row.

---

## 7. Levers for the sweep

| Lever | Default | Try | Why |
|---|---|---|---|
| **r**, Simmer's share a turn | ½ | 0.4, 0.6 | The tribe's growth rate. The card keeps a plain fraction (§1). |
| Granny | ×2 once per unit | ×3 once; Simmer twice | "Twice" overshoots (2.8× median at round 15); ×3 once is the safe step up if the carry line is weak. |
| Cut-and-Come-Again | half-stat, every other turn | a quarter; every turn | Sets the wide capstone's pace. |
| Elder Ooze's reach | beside | next to | Sets how wide the lamp reaches. |
| The Sixpenny Pie | 1 gold per unit out (2 at most) | 1 gold if anything comes out | The economy guard. |
| Dishwater Nell | every turn | every other turn | The economy guard. |
| Figgy Duff | every other turn | once a turn | The golden rate. |
| See-through rule (§9) | on | off | Whether answers can reach an Ooze carry. |

## 8. Engine support needed

1. **Simmer.** An End of Turn trigger with a back-row condition, the `inside` selector (as Aunt Aspic uses now) and Track B's `stat_fraction` gain, with r from config.
2. **Elder Ooze.** An aura that gives itself and the Oozes beside it "Simmer in any row" (golden: next to).
3. **Granny.** The `into_belly` trigger on her own Belly, doubling the entering unit, plus a per-unit "stirred" flag kept in saves, snapshots and fight copies.
4. **Cut-and-Come-Again.**
   - An every-other-turn counter (exists).
   - A copy of what's inside at ½ its current stats, sent to hand (new: copy with a stat fraction).
   - A copy flag that blocks triples and Figgy Duff.
5. **Dishwater Nell.** The shop's lowest-tier unit goes to the first Belly with room, in reading order: a new destination for `eat_shop`. Created; doesn't count as a refresh.
6. **Little Dollop.** `belly_discount` for any Belly, once a turn.
7. **Bubble and Squeak.** An "after you sell a unit" trigger; what's inside this gains the sold unit's current stats.
8. **Mr Syllabub.** On coming out, grant Shield (Track B); golden also grants Damage Reduction 25%.
9. **Hasty Pudding.**
   - The `biggest_enemy` selector for swallowing.
   - If the biggest enemy is inside an Ooze, swallow that Ooze.
10. **Mrs Posset.** When this dies: `stat_fraction` reduce Health ½ on the enemy across (golden adds those beside it).
11. **Data-only changes:**
    - Moss Ooze gains Belly 1.
    - The Pie takes pass 2's text, with its golden exception.
    - Wee Wobbly loses its early release.
    - The new bodies (§2).
12. **Interface.**
    - Back-row ovens show the next Simmer gain ("+31/+47 at End of Turn").
    - Stats inside a Belly show in the shop, on the board and in the scout.
    - A stir mark on doubled units.
    - The back row reads as "on the stove".
13. **Harness.**
    - Combat-start snapshots count Belly contents (Track A already plans this).
    - The Belly policy in §6 goes into the Ooze line brains.

## 9. Proposed rule: see-through

*Effects that pick the biggest enemy also see units inside enemy Bellies. A unit inside can be shrunk or debuffed there, but not swallowed or moved.*

- **Why:** without it, an Ooze carry hides from the two or three biggest-enemy answers the plan puts in the pool. The audit wants answers that can reach a carry sometimes.
- It's also the tribe's own flavour: you can always see the startled hedgehog floating inside.
- **Engine support:** a stat effect's `biggest_enemy` candidates include Belly contents.
- Hasty Pudding's swallow rule (§2, card 14) is the mirror case.

## 10. Risks to watch

- **Concentration.**
  - The typical engine board puts 57% of its stats in one unit at round 12. Battlegrounds averages about 34%.
  - Under our rules a carry that big loses to an even board of the same total.
  - Watch the field win rate of the carry line against wide boards. If it falls short, move heat to the wide route rather than add stats.
- **The doubler tail.** Simmer is End of Turn text, so Track B's End of Turn doubler squares the rate (×2.25). The sweep must show Oozes with the doubler in about the top 1% of games, not as a common line.
- **Economy.** The Pie, Nell, Dollop and Figgy together could make Ooze gold a common snowball. Compare Ooze gold per round with the other tribes'.
- **Fight length.** 14–15 bodies a side plus Shields. Watch the 200-attack limit and how long fights take.
- **Game length.** Soft Ooze damage may drag games past rounds 14–16.
- **Posset.** A tier 1 card that halves a carry's Health may be strong where it lands. The fallback is "a quarter".

## 11. The model behind the numbers

- **Script:** `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/final_model.py`, with variants in `lines_model.py`, `granny_variants.py` and `card_numbers.py` in the same folder.
- **Method:** a deterministic buy plan per line: income 3 to 10, Battlegrounds tier costs with the discount, units at 3 gold and Dollop's discount. Simmer rounds down. Harvest Supper gives +1/+1 a cast to Oozes. "Heat" stands for spells through Moss and the sells B&S eats.
- **Typical plans:**
  - **Engine:** Aspic at round 5, Frumenty and the Pie at round 7, Granny and a second Aspic at round 11, Elder at round 12.
  - **Tempo:** Wobbly, Posset and Soup by round 3, the Pie at round 6, Aspic at round 8, Elder at round 9, Cut-and-Come-Again at round 12.
- **Strong plan:** a golden Aspic by round 7 and Granny from Hiring Fair at round 10.
- **Not modelled:** fights, opponents, the pool or shop luck. It sizes the shape; the harness's field fights decide strength.
- **Insides:** they count in every Ooze total. Today's bench left them out, so today's Ooze boards read low.
