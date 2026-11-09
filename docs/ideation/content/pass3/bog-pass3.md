# Bog folk, pass 3: the synthesis ("The bog keeps what bites it")

9 Nov 2026. The synthesizer for the Bog folk panel (Track C, `docs/ideation/plan-scale-rework.md`, Step 1). I read the owner's notes 09a, 09c, 09d and 08e, `fundamentals.md` §1 and §3, the plan, rulebook §8–9 and the BRAMBLE ideation rules, the wording guide, the three designs (`bog-wild.md`, `bog-carry.md`, `bog-engine.md`), then the breaker's critique (`bog-breaker.md`), and the Hunters breaker where it overlaps.

**No price list was used.** Every number is sized against the brief's shape: today's boards to round 7, then about ×1.5 a round. A paper model backs the sizes: `bog-pass3-model.py` next to this file (`python3 -I bog-pass3-model.py`, output saved in `bog-pass3-model.out.txt`). It counts permanent stats only and fights nothing, so read its numbers as directions. Nothing ran in Godot.

**In one line.** Every bite into a Bog folk loses a quarter of its Attack, and the toad that was bitten keeps it. Tiddy Mun pours the bog's whole Toll into the toads beside her, the frog prince doubles whoever stands beside him every third kiss, and the Peat King raises the drowned to fight for you.

---

## 0. What this is built from

The breaker ranked **Wild** first (moments, the matching puzzle, folklore), **Carry** second (the only Bog-only engine) and **Engine** third. I start from Wild's frame: its sixteen roles, its routes, its frog prince, Peatlings, Nan the leveller, Jenny's one-row pull and the Lantern's lure. Then I swap its engine.

**Why the engine changes.** Wild's Swell ("gain half of the enemy this Mires when it dies") is the Hunters' Take ("gain half the quarry's stats"). Both breakers said so independently. Both said Hunters are the better home for growth from the kill ("you are what you hunt"), and that Bog should grow from being bitten. When independent reviewers agree, we act on it. So Bog's engine is the Carry design's **Soak**: Bitter takes a quarter of every bite, and Soak keeps it.

| Piece | From | Changed in the synthesis |
|---|---|---|
| Card roles, routes, "who eats whom" against the scout, the tray preview | Wild | Re-expressed in bites instead of kills |
| Soak: one keyword that is both answer and engine | Carry | The gain lands at Start of Turn, never mid-fight; it counts bites from the enemies a unit Mires |
| Proportional Bitter (a quarter, rounded up) | Carry, Engine | Golden never changes the share |
| "Food or threat" placement, Bufo's halving as a cost to your own drink | Carry | Kept |
| The funnel (Tiddy feeds the carry) | Carry | Positional: Tiddy feeds the units beside her. No crown, no auto-pick |
| The frog prince's curse break, doubling the units beside him | Wild | Counts kisses (one a fight), shared by all your frogs; a unit is doubled once a turn |
| Warty Nan as the leveller | Wild | Fed by the Toll, not by kills |
| Peatlings: their dead rise for you | Wild | Kept on the Peat King, twice a fight |
| Jenny's one-row pull | Wild | Skips the Lantern's target |
| The Lantern Man lures the biggest, anywhere | Wild, Engine | Soak instead of Swell; no halving |
| "Frogs or walls", the Soak log line, tier-scaled growth | Engine | Kept; higher tiers drink more by having more or bigger patches |
| Spitfire Sal | Carry's idea (Sal expresses Bog's size) | Sal deals the Toll, split among Mired enemies: Bog's answer to wide boards |
| Signor Ranocchio | Carry | Kept as written |
| The Peat (a gold-fed tribe number), Turfs, Brann on the King | Engine | Not taken (section 9) |

---

## 1. The pitch

**The bog keeps what bites it.**

Bog folk still decide who fights whom. At Start of Combat each toad lays mud under the enemy across, and that enemy must bite it. Every bite into Bog folk is **Bitter**: the biter loses a quarter of its Attack before it lands, and stays smaller for the fight. A toad with **Soak** keeps what its Bitter took from the enemy it holds, as permanent stats, at the start of the next turn. Bite a Bog toad with an 80-Attack boar and the toad is +20/+20 bigger for the rest of the game, and the boar is a 60.

- **The answer tribe and the engine are one keyword.** The more their carry bites, the smaller it gets and the more your toad keeps. Answering a carry is how Bog grows.
- **It rides the lobby.** Takes are a share of the enemy's Attack, so Bog tracks whatever curve the other tribes reach. It never needs its own price table to keep up.
- **It can't run away on its own.** A Bog board far ahead still faces opponents of normal size and drinks a normal amount. It grows the same in a loss as in a win.
- **The swamp opera pays off.** Tiddy Mun, the fen spirit, raises the water for whoever stands beside her. Every frog claims to be a prince, and one of them is telling the truth: on his third kiss the curse breaks mid-fight, the units beside him double on the spot, and he stands up the Prince. The Peat King raises whatever drowns as a Peatling on your side. The Lantern Man leads their biggest across the board into the mud.

**Familiar shapes.** Soak is close to a lifesteal that pays out as permanent stats, and to Galaxy's "gain the Attack you removed". Tiddy's funnel is a positional cousin of Battlegrounds' "your X give extra". The curse break is a doubler on a counter, like an Avenge (X) that counts fights. Peatlings are Hearthstone's "resurrect it for you". Mire is Magic's Provoke.

**What a player sees.** The mud patch and the reed-line stay. New: each bite on a Soak toad pops a small "+20" badge that rides the toad to the end of the fight, then lands as stats in the next shop ("Gideon soaked +27/+27"). The Bog folk tribe icon shows the **Toll** from your last fight. His Highness wears three lily-pad hearts that fill one a fight. The tray shows each Soak toad's expected drink against the scouted board ("Across their Boar: +20 a bite").

---

## 2. Rules and keywords

### Keywords and terms

| Word | Reminder (≤ 16 words) | On |
|---|---|---|
| **Mire** (kept) | Start of Combat: the enemy across must attack this while this lives. This waits once. | 8 cards and the Prince |
| **Mired** (kept) | Must attack the unit that mired it. | status |
| **Snap** (kept) | Attacks the Mired enemy with the most Attack. | 4 cards |
| **Bitter** (changed) | When an enemy attacks this, it first loses a quarter of its Attack. | Nan, Bufo, every Soak unit, Peatlings |
| **Soak** (new) | Bitter. Start of Turn: gains +1/+1 per Attack its Bitter took from its Mired enemies. | 7 cards, the Chorus lends it, the Prince |
| **the Toll** (new term) | The Attack your Bitter took in your last fight. | Nan, Tiddy, Sal; shown on the tribe icon |
| **Sink** (new trigger) | After a Mired enemy dies. | Peat Cutter, Peat King, the kiss |
| **kiss** (kept from pass 2) | One each fight with a Sink. Your frogs share them. | His Highness and the Prince |

Two words left the tribe: Wild's **Swell** and **Sink (X)**. Swell is now Soak. Sink (X) counted deaths across fights; kisses count fights, which tokens can't speed up.

### Rulings (Details and the rulebook)

- **Bitter** keeps its timing (9.6.0): at declaration, before damage. The loss is **a quarter of current Attack, rounded up**, never below 1 Attack, and it lasts the fight. **A unit has Bitter once** (own and lent don't stack). **Golden never changes the share.** Track B's percent Bitter floors fractions, so it needs a round-up option.
  - *Why round up:* a 2–4 Attack hit still loses 1, which is today's Bitter 1, so the early answer is unchanged. Rounding down makes Bitter do nothing before round 4, and the model puts Bog at 0.65× the median at round 6.
- **Soak** counts what this unit's Bitter took from enemies on **its own patches** (its Mired enemies). Bites from free enemies still go into the Toll. The gain lands at the next **Start of Turn**, on the recruit copy, even if the unit died, and is shown during the fight as a pending badge. It never grows a unit mid-fight.
  - *Why only its Mired enemies:* on a small early board every enemy bites the one toad, and an uncapped Toad reached 16/18 by round 6 (1.22× the median). Counting its own patch keeps round 6 level (0.98×) and makes every toad's growth a placement decision.
  - *Why Start of Turn:* no in-fight gain means no in-fight loop. The carry design's must-fix (golden Soak plus the King making the Diva unkillable) can't happen in any combination.
  - Golden Soak keeps +2/+2 per Attack (golden Details; Soak has no number to double).
- **The Toll** is every Attack your Bitter took in your last fight, from any biter, Peatlings and lent Soak included. It shows on the Bog folk tribe icon and in the fight summary.
- **Kisses.** You get one kiss in each fight where a Mired enemy dies (a Sink), while His Highness or the Prince is on your board. **The count is yours, not each frog's:** every frog shows it, and every frog acts on the same kiss. "Every third kiss" fires on kisses 3, 6, 9 and so on. Holding His Highness in hand pauses the count if no other frog is out.
- **Doubling** gives a unit its base plus permanent stats again, permanently. The fighting copy gains the same amount at once. Combat-only buffs (Rings, auras, Bitter losses) are never doubled. **A unit is doubled at most once a turn**, so two frogs beside one unit double it once. Golden frogs triple, and the biggest multiplier applies.
- **Jenny's pull** happens at Start of Combat, before patches are laid. She swaps the biggest enemy in the row across into the slot across from her, then the patches go down. She skips the enemy the Lantern Man lures. Rings and other slot effects stay on their slots (8.5.1), so a pulled Fairy carry leaves its Ring behind: a feature.
- **The Lantern Man's patch** is laid first, under the biggest enemy (Track B's selector, Attack plus Health), in any row. A mirer across that slot lays nothing there (one patch per slot).
- **Peatlings** rise in the empty slot nearest the Peat King (8.4.2), with the sunk enemy's starting stats and no text but Bitter. Combat only. With no empty slot, the summon fails (8.4.5).
- **Caps removed** (owner, 9a and 9d): Bridge Toad's +3/+3 ceiling, the Peat Cutter's "three times in all", Ranocchio's "once a fight", Tiddy's "twice a fight", the Prima Donna's "once per enemy". **Four rate limits stay, each guarding a loop:** the Peat Cutter's once a fight (gold → patches → gold), the Peat King's twice a fight (summon flood), one kiss a fight (the counter), and doubled once a turn (copies).

### Tier changes

The spread stays 3/3/3/3/2/2. Two cards swap, as the carry design proposed:
- **Tiddy Mun 5 → 4, at 3/5.** She is the funnel. At tier 4 the court comes online about round 7–8; at tier 5 the typical line sits at 0.68× the median through rounds 9–12 (the model's lowroll line).
- **Jenny Greenteeth 4 → 5, at 4/7.** Her pull makes her the best drinker in the tribe. At tier 5 she arrives with the Prima Donna as the late upgrade, which is the tier-up reward the engine design said was missing.

### Reference: what a bite is worth

The brief's median board, biggest unit a third of it, 47% of stats in Attack. Every payoff below uses this table.

| | R9 | R12 | R15 |
|---|---|---|---|
| Median enemy board | 146 | 494 | 1,666 |
| Their biggest | 23/26 | 77/87 | 261/294 |
| Each other unit | 8/9 | 26/29 | 87/98 |
| Bitter's take from their biggest: first bite, second bite | 6, 5 | 20, 15 | 66, 49 |
| Bitter's take from another unit | 2 | 7 | 22 |
| **Soak across their biggest, a fight** (1.5 bites) | **+8/+8** | **+27/+27** | **+90/+90** |
| Soak across another unit, a fight (1.4 bites) | +3/+3 | +9/+9 | +29/+29 |
| The Toll, a fight (model) | ~20 | ~70 | ~240 |

---

## 3. The sixteen

Every creature, name and portrait is kept. Both tokens are kept: the Prince Restored and the Peatling.

### Tier 1

**Bridge Toad.** *Common Toad, Bridge-Keeper.* Tier 1, **1/3** (unchanged).
- **Text:** Mire. Soak.
- **Golden (2/6):** Mire. Soak. *(Golden Details: its Soak keeps +2/+2.)*
- **Condition:** the enemy across bites it. Mire makes sure it does.
- **Payoff:** a toll for every crossing. Across a middling enemy, +3/+3, +9/+9 and +29/+29 a fight at R9, R12 and R15; across their biggest, +8, +27 and +90. On the model's typical board it is 11/13 at R9, 24/26 at R12 and 59/61 at R15. Beside Tiddy it can be your first Diva.
- **Permanence:** permanent, shown in the shop.
- **Enabler:** a patch for Snap, Sal, the Sink cards and the kiss; Bitter for the Toll.
- **Concentrates:** partly. The tier 1 that still matters at R15, but it drinks from one patch, so it can't outgrow the tier 5s that drink from three.
- **From:** Carry's text; Wild's role.

**Warty Nan.** *Toad Wet-Nurse.* Tier 1, **1/3** (unchanged). *The wet-nurse feeds the little ones first.*
- **Text:** Bitter. Start of Turn: your smallest Bog folk gains a quarter of the Toll.
- **Golden (2/6):** Bitter. Start of Turn: your smallest Bog folk gains half the Toll.
- **Condition:** your Bitter took something last fight. On a Bog board that is every fight.
- **Payoff:** +5/+5, +18/+18 and +60/+60 a turn at R9, R12 and R15, always to whoever is smallest, so it climbs the low end of the board one unit at a time.
- **Permanence:** permanent.
- **Enabler:** keeps Bufo, Hopkin, Sal, the Cutter and the Chorus from being dead weight by R9. Her own Bitter adds to the Toll.
- **Concentrates:** **no, she levels.** The even-board engine (the Swamp).
- **From:** Wild's leveller, fed by the Toll. *Breaker fix:* her golden widens the share instead of halving bites.

**Young Pretender.** *Frog, Claimant to the Lily Throne.* Tier 1, **3/2** (unchanged).
- **Text:** Snap. After this kills a Mired enemy: get 1 gold next turn.
- **Golden (6/4):** Snap. After this kills a Mired enemy: get 2 gold next turn.
- **Condition:** it lands the kill on something stuck.
- **Payoff:** tempo, and about 0.3–0.5 gold a fight early.
- **Permanence:** economy.
- **Enabler:** gold for the early climb; Sinks for the Cutter and the kiss.
- **Concentrates:** no. Sell it by R7–R8.

### Tier 2

**Madame Bufo.** *Toad Diva.* Tier 2, **1/4** (unchanged).
- **Text:** Mire. Bitter. If its Mired enemy kills this, halve its Attack.
- **Golden (2/8):** Mire. Bitter. If its Mired enemy kills this, halve its Attack twice.
- **Condition:** she is across their carry, and it bites her and kills her.
- **Payoff:** their carry fights on at three eighths: 23 → 17 → 9 at R9, 77 → 58 → 29 at R12, 261 → 196 → 98 at R15. The cheapest carry answer in the game, at every scale. Her take goes into the Toll.
- **Permanence:** combat only (an answer). Nan keeps her body growing.
- **Enabler:** shrinks the carry for Snap frogs, Hopkin and the Lantern Man.
- **Concentrates:** no. **This is the core decision:** fell their giant with Bufo, or feed it to a Soak toad. A halved giant gives every toad behind it half the drink.

**Vaulting Hopkin.** *Frog Acrobat.* Tier 2, **3/1** (unchanged).
- **Text:** Snap. In the back row: attacks first, using a quarter of the highest Attack in front.
- **Golden (6/2):** Snap. In the back row: attacks first, using half the highest Attack in front.
- **Details:** uses his own Attack if it is higher. "In front" is the two front slots before his back slot (8.2.1).
- **Condition:** back row, behind a big front unit, and a Mired enemy to Snap.
- **Payoff:** one strike at the biggest stuck enemy before anything else moves. Behind the typical court's Diva: about 7 at R9, 47 at R12 and 210 at R15.
- **Permanence:** combat only.
- **Enabler:** expresses the carry a second time; sets up Pretender and Ranocchio.
- **Concentrates:** it spends the carry's size. **"Frogs or walls":** a vault that kills their carry before it bites costs your toads their drink.
- *Breaker fix:* a quarter, not half. Two Hopkins behind a Diva leave the field's carry at about 30%.

**The Peat Cutter.** *Palmate Newt, Labourer.* Tier 2, **2/4** (unchanged).
- **Text:** Mire. Sink: get 1 gold next turn. Once a fight.
- **Golden (4/8):** Mire. Sink: get 2 gold next turn. Once a fight.
- **Condition:** any Mired enemy dies, by any hand, in a win or a loss.
- **Payoff:** about 0.9 gold a fight, all game.
- **Permanence:** economy.
- **Enabler:** the climb to tier 5 and 6; rolls for triples.
- **Concentrates:** no. "Once a fight" stays: it guards a loop (more patches → more gold → more patches).

### Tier 3

**Gideon, Basso Profundo.** *Toad Bass.* Tier 3, **2/6** (unchanged).
- **Text:** Mire. Soak. After its Mired enemy attacks this: hit it back.
- **Golden (4/12):** Mire. Soak. After its Mired enemy attacks this: hit it back twice. *(Golden Details: Soak keeps +2/+2.)*
- **Details:** the hit back deals his Attack; it doesn't hit back.
- **Condition:** his Mired enemy bites him.
- **Payoff:** across their biggest, +8, +27 and +90 a fight, plus a free exchange per bite. As the court's Diva (beside Tiddy and the frog) on the typical line: 17/21 at R9, 187/195 at R12, 831/847 at R15.
- **Permanence:** permanent; the hit back is combat only.
- **Enabler:** the usual Diva (6 Health at tier 3). The hit back makes their carry sink sooner, which feeds the kiss.
- **Concentrates:** **yes, he is the tribe's carry until the tier 5s arrive.** He holds his stats through Bitter on every bite, the hit back, and Mire choosing his biter.

**The Natterjack Chorus.** *Natterjack Choir.* Tier 3, **3/4** (unchanged).
- **Text:** Your Bog folk beside this have Mire and Soak.
- **Golden (6/8):** same. *(Golden Details: the Soak it lends keeps +2/+2.)*
- **Condition:** Bog folk beside it in its row.
- **Payoff:** two more patches and two more drinkers. Bufo and Nan beside it each Soak +3, +9 and +29 a fight across a middling enemy.
- **Permanence:** the gains are permanent; the lend is an aura.
- **Enabler:** patches for Snap, Sal, the Cutter and the kiss; Soak for the Swamp.
- **Concentrates:** no, it spreads. Tribe-only, because Soak is the payoff.

**Spitfire Sal.** *Fire Salamander, Pyrotechnist.* Tier 3, **1/3** (unchanged).
- **Text:** Start of Combat: deal the Toll, split among Mired enemies.
- **Golden (2/6):** Start of Combat: deal twice the Toll, split among Mired enemies.
- **Details:** split evenly, rounded down.
- **Condition:** your last fight took something, and patches hold enemies now.
- **Payoff:** across about five Mired enemies, 4, 14 and 48 each at R9, R12 and R15. That clears tokens and halves a middling unit; it chips a carry by about a sixth.
- **Permanence:** combat only.
- **Enabler:** Bog's answer to wide boards, its worst matchup. Leaves stuck enemies low for Snap and the Pretender. Also "frogs or walls": a token that burns doesn't bite.
- **Concentrates:** no.
- *Changed from Wild* (a quarter of every Mired enemy's Health): that piled onto the carry-answer stack (breaker, shared problem 2). The Toll version hits wide boards hardest and carries least.

### Tier 4

**Tiddy Mun.** *Fen Spirit.* **Tier 4** (was 5), **3/5** (was 3/6). *The water rises for whoever stands beside her.*
- **Text:** Start of Turn: the units beside this split half the Toll.
- **Golden (6/10):** Start of Turn: the units beside this split the Toll.
- **Condition:** units beside her in her row. At a row's end she has one neighbour, who gets it all.
- **Payoff:** the funnel. With one neighbour: +10/+10, +35/+35 and +120/+120 a turn at R9, R12 and R15, on top of that unit's own Soak. With two, half each.
- **Permanence:** permanent.
- **Enabler:** turns every Bitter unit on the board (Nan, Bufo, Peatlings, lent Soak) into food for the court. The unit beside her is your Diva: move her, and the water moves.
- **Concentrates:** **yes, by your choice.** At the end of a row she concentrates; in the middle she feeds two.
- *Breaker fix:* no crown and no auto-pick. The carry design's "most Health" Diva locked onto the Toad forever, and the pool already has two auto-picked carries (Birds' Chick, the Hunters' Alpha). Moving Tiddy is the placed crown, with no new control.

**His Highness, Allegedly.** *Frog Pretender.* Tier 4, **3/5** (unchanged).
- **Text:** Snap. Every third kiss: double the units beside this. First time: become the Prince.
- **Golden (6/10):** Snap. Every third kiss: triple the units beside this. First time: become a golden Prince.
- **Condition:** three fights with a Sink while a frog is on your board (almost every fight).
- **Payoff:** bought at R9 on the typical line, the curse breaks in the R11 fight: the Diva beside him (about 90/95) doubles on the spot, and so does his other neighbour. Then every third kiss again as the Prince: R14, R17.
- **Permanence:** permanent.
- **Enabler:** the court's doubler. It pays to put your carry beside him.
- **Concentrates:** **yes**, two units at a time, by placement.
- **Decision:** **hold or play.** He doesn't count kisses in hand. Play him now for an early double, or hold him until the unit beside his slot is worth doubling.
- *Breaker fixes:* kisses count fights, so tokens can't speed the curse. Kisses are shared and a unit is doubled once a turn, so two frogs beside one carry double it once. The model: two frogs with the fix give 1.04× / 1.35× (rounds 11–13 / 14–16); without it, 1.17× / 2.13×.

> **The Prince Restored** (token, `pool: false`). *Frog, Rightful Prince of the Bog* (Bog folk). **6/7**, keeping His Highness's permanent buffs and slot.
> - **Text:** Mire. Soak. Every third kiss: double the units beside this.
> - **Golden (12/14):** Mire. Soak. Every third kiss: triple the units beside this.
> - The spell discount is gone.

**Signor Ranocchio.** *Frog, Tenor.* Tier 4, **3/4** (unchanged).
- **Text:** Snap. After this attacks a Mired enemy: permanently gain +1/+1 per 4 of its Attack.
- **Golden (6/8):** Snap. After this attacks a Mired enemy: permanently gain +2/+2 per 4 of its Attack.
- **Condition:** he Snaps something stuck, usually their carry, about 1.6 times a fight from the back row.
- **Payoff:** +8, +27 and +94 a fight at R9, R12 and R15. He gains even if the hit back kills him. On the Swamp model board he is the biggest unit: 77/78 at R12, 293/294 at R15.
- **Permanence:** permanent.
- **Enabler:** the frogs' carry, safe in the back row. More patches mean more targets.
- **Concentrates:** yes (self). Not Bitter and not in the Toll, so Tiddy can't double him: the slower, safer carry.
- **From:** Carry, unchanged. *(Wild's "gain half of what he kills" was the Hunters' Take.)*

### Tier 5

**The Prima Donna.** *Toad Diva Assoluta.* Tier 5, **2/8** (unchanged).
- **Text:** Mire the slot across and the slots beside it. Soak.
- **Golden (4/16):** same. *(Golden Details: Soak keeps +2/+2.)*
- **Condition:** three patches, three biters.
- **Payoff:** with their biggest on one patch, +14, +45 and +148 a fight at R9, R12 and R15; three middling patches give +8, +27 and +86. In B2 she Mires their whole back row, where carries hide.
- **Permanence:** permanent.
- **Enabler:** three Mired enemies for Sal, Snap, the kiss and the Cutter; three Bitter takes for the Toll.
- **Concentrates:** yes. Move Tiddy beside her and she becomes the late Diva: she drinks three times as many bites as a Toad.

**Jenny Greenteeth.** *Bog Hag.* **Tier 5** (was 4), **4/7** (was 3/5). *"Stay off the duckweed, dears."*
- **Text:** Mire. Soak. Start of Combat: pull the biggest enemy in the row across to face this.
- **Golden (8/14):** same. *(Golden Details: Soak keeps +2/+2.)*
- **Condition:** she stands in the row where their biggest is. The player reads the scout and picks her row.
- **Payoff:** she holds the biggest in her row and drinks it: +8, +27 and +90 a fight. In the back row she drags their back-row carry onto her patch, in reach of every Snap.
- **Permanence:** permanent; the pull is combat only.
- **Enabler:** steers the biggest drink; makes their carry Mired for Snap, Sal, Hopkin and the Peatlings.
- **Concentrates:** yes, a second carry or the late Diva.
- **Reach:** "sometimes". One row, a scout that may be stale, and the pull alone kills nothing.

### Tier 6

**The Peat King.** *Toad, Old as the Moss.* Tier 6, **5/9** (unchanged).
- **Text:** Mire. Soak. Sink: it rises for you as a Peatling. Twice a fight.
- **Golden (10/18):** Mire. Soak. Sink: it rises for you as a Peatling. Four times a fight.
- **Condition:** Mired enemies sink, and you have an empty slot (as your own units die).
- **Payoff:** the first two enemies to sink each fight rise on your side with their starting stats: about 2 × 26/29 at R12 and 2 × 87/98 at R15. When their carry sinks, you get their carry: 77/87 at R12, 261/294 at R15. His own Soak adds +9 and +29 a fight.
- **Permanence:** his Soak is permanent; Peatlings are combat only.
- **Enabler:** Peatlings have Bitter, so they feed the Toll; they refill the Swamp mid-fight.
- **Concentrates:** no.
- **Tier-up reward:** the fight changes the moment he lands, at the field's own size. His body is small (5/9); his payoff is not.
- **Peatling** (token, Bog folk, combat only): the sunk enemy's starting stats. **Text:** Bitter.

**The Lantern Man.** *Will-o'-the-Wisp.* Tier 6, **4/8** (unchanged). *The light over the fen comes for whoever strays.*
- **Text:** Mire the biggest enemy, wherever it stands. Soak.
- **Golden (8/16):** Mire the two biggest enemies, wherever they stand. Soak.
- **Condition:** none. The lure always lands.
- **Payoff:** their biggest must bite him first, from any row. He drinks +8, +27 and +90 a fight from it, and it fights on three quarters smaller. Every Snap, Sal's fire, Hopkin's vault and the Peat King's raising now find it. He arrives small and dies to the first bite, but keeps what he took, so he catches up in two or three fights (sooner beside Tiddy).
- **Permanence:** permanent (Soak); the lure is combat only.
- **Enabler:** points the whole tribe's answers at their carry.
- **Concentrates:** yes, the late carry or the second one.
- **Reach:** Bog's one "biggest enemy in any row" card, at tier 6 only.
- *Not taken:* the engine design's halving. With Bitter on every bite, Bufo and a lure, a halving piled the answer stack higher (breaker, shared problem 2).

### Word counts

Card texts run 2–16 words, median 11, p90 15, longest 16 (Jenny). Guide: median ≤ 11, p90 ≤ 17, max 22. Every reminder is 16 words or fewer.

### Counts against the audit

| | Pass 2 | Pass 3 synthesis |
|---|---|---|
| Payoffs that last one fight only | 9 of 13 | 3 of 16 (Bufo, Hopkin, Sal) plus the King's Peatlings |
| Permanent payoff cards | 4, capped | 11 (Toad, Nan, Gideon, Chorus, Tiddy, His Highness, Ranocchio, Prima Donna, Jenny, King, Lantern) |
| Payoffs that scale with the game | Bufo's halving | All Bitter and Soak, the Toll cards, Hopkin, Ranocchio, the curse, Peatlings |
| Caps and limiters | 5 | 4 rate limits, each guarding a loop |
| Any-row answers | 0 | 1 (the Lantern Man) |
| "Triggers twice" cards | 0 | 0 |

---

## 4. The tribe

### The engine and its rate

**The engine: the bog keeps what bites it.**
1. **Condition:** an enemy bites a Bitter unit. Mire picks who bites whom.
2. **Payoff:** Bitter takes a quarter of the biter's Attack. Soak keeps its own takes as +1/+1 each. The Toll (everything your Bitter took) feeds Tiddy's neighbours (half) and your smallest unit (a quarter), and Sal's opening fire.
3. **Enablers:** patches (Mire, the Prima Donna, the Chorus, Jenny, the Lantern) set how many bites you drink; Bitter units without Soak (Nan, Bufo, Peatlings) add to the Toll; the frog prince doubles whoever stands beside him.

**How it compounds.** Takes are a share of the enemy's Attack, so Bog's growth a fight is a fixed share of the field: it compounds at the lobby's ×1.5. On top of that the frog doubles his neighbours every third fight, which is self-compounding at about ×1.26 a round (×1.44 golden). Both are below the field's ×1.5 on their own, so neither can run away from the lobby.

**The rate parameter: k, the keep.** Soak and the Toll cards pay +k/+k per Attack Bitter took. **Default k = 1.** Sweep 0.5, 1, 1.5 in the harness. Ship at 1 and tune with the printable shares below, so the card always says "+1/+1 per Attack".

Secondary dials, in the order I would turn them:
1. **Tiddy's share** (half the Toll). A quarter or a third if the court is too tall; the whole Toll is too much (1.38× / 1.76×, biggest unit 75–78%).
2. **Bitter's share s** (a quarter). It moves the answer and the engine together. A fifth or a third.
3. **The frog's repeat** (every third kiss). Every fourth gives 0.94× / 1.02×; a single break gives 0.82× / 0.82×, so the repeat carries the late shape.
4. **Nan's share** (a quarter). Half lifts round 6 to 1.16×.

**Boards against the target** (model defaults; board at the fight ÷ the brief's median; biggest unit's share in brackets; R11–13 and R14–16 are geometric means, which smooth the frog's jumps):

| Line | R6 | R9 | R12 | R15 | R11–13 | R14–16 |
|---|---|---|---|---|---|---|
| Median board | 50 | 146 | 494 | 1,666 | | |
| The court, strong (pieces on time) | 1.18 (0.23) | 0.98 (0.44) | 1.09 (0.58) | 1.18 (0.57) | **1.30** | **1.37** |
| The court, typical (a round or two late) | 0.98 (0.28) | 0.82 (0.32) | 1.20 (0.65) | 1.47 (0.68) | **1.04** | **1.24** |
| The court, spread (Tiddy and the frog between supports) | 0.98 | 0.82 (0.27) | 1.03 (0.42) | 1.19 (0.46) | 0.95 | 1.07 |
| Lowroll (Tiddy at R10, no frog) | 0.98 (0.28) | 0.68 (0.24) | 0.70 (0.43) | 0.79 (0.49) | 0.67 | 0.78 |
| The Swamp, typical | 1.03 (0.26) | 0.83 (0.20) | 0.92 (0.34) | 1.01 (0.35) | 0.93 | 0.99 |
| Highroll (strong, golden frog R8, golden Gideon R7) | 1.18 | 1.07 | 1.53 | 1.87 | **2.04** | **2.50** |

In stats, the typical court is 49 / 120 / 592 / 2,449 at R6 / R9 / R12 / R15, with the Diva at 187/195 at R12. Against the strong (September 2025) field the same line is 745 at R12 (0.98× that board) and 3,534 at R15 (1.36×): Bog drinks more from a stronger lobby.

**Reading it.**
- **Level to R7:** 0.98–1.18 at R6.
- **A dip at R8–R11** on typical lines (0.82–0.87), while Tiddy and the frog arrive. Lowrolls stay there (0.67–0.78).
- **Ahead from R12** on the court: about 1.0–1.3× on typical and strong lines, 1.24–1.37× by R14–16.
- **The Swamp sits at the median** all game in stats and wins with its answers, which the model can't count.
- **The tail is modest:** the highroll is 2.0–2.5×, inside Battlegrounds' "13–23% of boards at twice the median", nowhere near 10×. That is Bog's nature as the brake tribe (section 9, question 3).

**Why it can't snowball often.**
- Takes come from the opponent's Attack, not Bog's lead. Soak pays in losses too, so winning doesn't speed it up.
- The frog is the only self-compounding piece, at most ×2 every three fights. Two frogs can't double one unit twice (the fix above).
- Goldens add k, never the Bitter share, so no golden makes a unit gain more than it loses from a bite.
- Every probe of the breaker's routes stays under 2× by R14–16 except two goldens together: golden His Highness 1.74×, golden Tiddy 1.62×, golden Gideon 1.47×, golden Toad 1.30×, golden Nan 1.29×.

### When it comes online
- **The court:** Tiddy at R6–R8 (tier 4), the frog at R7–R9, and the curse breaks two fights later (R9–R11). Clearly ahead from R12 on a typical game, R11 on a strong one.
- **The Swamp:** level from R1 on mirers and Bitter; online at R9–R10, when Tiddy and the Prima Donna land.
- **Each Soak toad:** behind when bought (a small body), level after two or three fights of drinking, ahead after that, because its drinks grow with the lobby.

### The decision the engine creates: is their carry food or a threat?

Each round the scout shows their biggest unit, and the tray shows what each of your toads would drink from it.
- **Feed on it:** put your Diva (the unit beside Tiddy) across it. She takes the biggest drink on offer, a quarter of a giant every bite, but she takes its hits.
- **Fell it:** put Bufo across it, or let Hopkin vault and Ranocchio Snap it first. Safer, but a halved or dead giant gives your toads half the drink or none.
- **Leave it free:** lock their supports, and let a Bitter wall take its bites for the Toll.

Three slower decisions sit on top:
1. **The court.** Who stands beside Tiddy, and who beside the frog. One Diva fed and doubled (taller, 0.6+ of the board) or two units sharing (wider, 0.4).
2. **Hold or play the frog.** He counts kisses only on the board.
3. **Frogs or walls.** Hopkin, Sal and the Snap frogs kill early and win tempo, but every enemy that dies before it bites is a drink your toads don't get.

### The court (carry route)
- **Pick.** The unit beside Tiddy is your Diva: Gideon or Bridge Toad early, the Prima Donna or Jenny late. Move Tiddy and the water moves; nothing is locked.
- **Grow.** Her own Soak across their biggest (+27 a fight at R12), half the Toll from Tiddy (+35), and the frog's doubling every third kiss.
- **Hold.** Every bite on her is a quarter smaller, and the biter stays smaller for the fight. Mire picks her biter. Gideon hits back on every bite. In the back row (the Prima Donna in B2) she is protected from everything she doesn't Mire.
- **Express.** Hopkin vaults off her with a quarter of her Attack. The Lantern drags their carry onto a patch. The Peat King raises it when it sinks.
- **Core cards:** Gideon, Tiddy Mun, His Highness, Bridge Toad, Madame Bufo, Vaulting Hopkin, the Prima Donna, Jenny, the Lantern Man.
- **Loses to:** "biggest enemy" answers at Start of Combat, Health-halving on the Diva (Nightshade), cleave and Start of Combat shots (they skip Bitter), and boards with no big hitters to drink from.

### The Swamp (non-carry route)
- **Shape.** Bitter on every front unit, Soak on most (the Chorus lends it to Nan and Bufo), Nan lifting the smallest, Tiddy in the middle sharing half the Toll, Ranocchio draining their carry from the back row, Sal burning the Mired with the Toll, the Peat King raising the drowned.
- **Wins by:** under our rules, evenly bigger bodies beat the same total spread unevenly (audit, point 6). Every enemy that bites a toad shrinks by a quarter, again on each bite, and the first two that sink fight for you.
- **Best against:** lobbies of carries; Oozes (every body out of a Belly lands on a patch and bites a toad).
- **Pivot:** move Tiddy to a row's end and a fat Soak toad becomes a Diva.

### Placement is the decision

| Choice | Option A | Option B |
|---|---|---|
| Who is across their biggest | The Diva: biggest drink, biggest risk | Bufo: their carry at three eighths, a smaller drink for everyone |
| Tiddy's slot | A row's end: one Diva gets it all | A middle slot: two units share |
| The frog's slot | Beside the Diva: she doubles | Between two supports: the board widens |
| The Diva's row | Front: Mires their front, takes extra bites, Hopkin vaults off her | Back (B2): pulls their back row, protected from the rest |
| Jenny's row | Their biggest's row | — |
| Reading order | Sturdiest mirer first, so it claims the patch | A fragile mirer first loses the lock when it dies |

**A worked round 12 (typical court).** The scout shows their carry, 77/87, in F2, behind nothing.
```
F1 Tiddy Mun 10/12     F2 Gideon (Diva) 187/195     F3 The Prince Restored 16/17     F4 Bridge Toad 24/26
          B1 Warty Nan 8/10      B2 The Prima Donna 32/38      B3 The Peat King 7/11
```
- Gideon in F2 Mires their carry. Its first bite loses 20 (to 57); he takes 57, hits back for 187, and it sinks. That is a kiss. Your board is full, so the King can't raise it; the next enemy to sink after one of yours falls rises as a Peatling (hence the line's open slot beside him).
- The Prima Donna in B2 Mires their B1, B2 and B3, which must cross the board to bite her, each a quarter smaller.
- Next shop: Gideon has soaked +20 and Tiddy hands him half the Toll (+35). Nan lifts the King, her smallest.
- **The alternative:** Bufo across their carry. It ends the fight at 29 Attack, but Gideon drinks only from a support (+7). That is the round's real decision.

**The opponent's side.** A front-row carry gets Mired and drunk; a back-row carry gets dragged by the Prima Donna, pulled by Jenny or lured by the Lantern. So the counter to Bog is to spread stats, to carry Health rather than Attack, or to answer the Diva at Start of Combat. That is the meta the owner asked for: answers that reach a carry sometimes, in both directions.

### Answers to other tribes' carries

**By reach:**
- **On every bite:** Bitter takes a quarter and keeps it off for the fight.
- **Across (placement):** Bufo's halving, the Diva's drink, Gideon's hit back.
- **Mired anywhere:** Snap frogs, Hopkin's vault, Sal's fire, Peatlings.
- **One row:** Jenny (tier 5).
- **Any row:** the Lantern Man (tier 6).

**By tribe (their pass 3 drafts):**
- **Hedgerow** (Pass carry in the last slot; Hunker walls). A mirer in F4 or the Lantern finds the Pass carry. Hunker walls hit softly, so they are slow food: grind them with Sal and the hit back.
- **Birds** (Eggs, Nests). A Mired Egg has no Attack, so nothing to drink: put a cheap unit across a Nest. Birds are Bog's hardest matchup.
- **Hunters** (Quarry, Pack). A Mired Hunter bites the toad, not its quarry. Pack joiners keep their Attack (9.6.0), so a Pack bite gets past Bitter: a real weak point.
- **Oozes** (Bellies). Every body that comes out lands on the patch, is Mired, and bites a toad. Bog's best matchup.
- **Fairies** (a Queen-fed carry on a Ring). Jenny's pull strips it off its Ring. The Changeling swaps with a mirer, and Nightshade on the Diva halves her Health every bite.

### Weak points
1. **Wide token boards.** Small bites mean small drinks, and a patch holds one unit of seven. Sal is the answer.
2. **Damage that isn't an attack:** Start of Combat shots, Mother Goose's strikes and cleave splash skip Bitter.
3. **Low-Attack walls** (Hunker, Shell, Eggs): nothing to drink.
4. **"Biggest enemy" answers.** The court's Diva holds 0.55–0.68 of the board, the biggest share in the pass.
5. **A weak field.** Bog grows with its opponents, so a lobby of small boards and ghosts starves it.
6. **R8–R11 on typical lines** (0.82–0.87). The Swamp and the answers have to carry this window.
7. **Scouting.** Placement answers are only as good as the read; the harness's blind layouts are the honest test.

---

## 5. Highroll moments

**1. The curse breaks mid-fight.** Round 11. Gideon, 90/95, holds their boar in F2. Tiddy sits beside him in F1 and His Highness in F3, two hearts full. Sal's fire opens the fight. The boar bites Gideon and loses a quarter; he hits it back and it sinks. The third heart fills, the crown lights, and Gideon jumps to 180/190 in the middle of the fight. He and the Toad beside the frog wipe a board that was winning, and after the fight the frog stands up a Prince. A golden frog triples instead, and does it again every third kiss. *Needs: Tiddy and His Highness by R9. Common enough to plan for, and the owner's "rewards give power" moment.*

**2. The Lantern brings their carry home.** Round 13. Their 300/320 carry hides in B3. The Lantern's light settles on it and it must cross the board to bite him: it loses 75 before the hit. He dies, but keeps the 75. Hopkin vaults off the Diva for 100, Ranocchio's tongue finds it, and it sinks. The Peat King raises it as a 300/320 Peatling on your side to finish the fight. Next shop, the Lantern is 79/83 and still growing. *Needs: both tier 6s. Rare.*

**3. The bog drinks a giant.** Round 15, against the lobby's top board. Their 1,500/1,500 carry bites your Prima Donna, who holds their back row in B2 beside a golden Tiddy. Bitter takes 375 on the first bite and 281 on the second; she dies. Next shop she is +656/+656 from her own Soak, and golden Tiddy hands her the whole Toll on top. The bigger they are, the more the bog keeps: a comeback written into the tribe. *Needs: a golden Tiddy and a giant across. Top-percent rare.*

---

## 6. Harness lines

Card ids are the content ids. Both lines commit to Bog folk and buy Harvest Supper with spare gold once their units are bought. `save_rounds` lists the turns that end with at least `save_threshold` gold; if the harness only has `save_until`, use 3 from round 5 to 10 for the court and 0 for the Swamp. Placement hints go to the placer.

```json
{
  "line_bog_court": {
    "tribe": "Bog folk",
    "engine": true,
    "priority": ["tiddy_mun", "his_highness", "gideon", "prima_donna", "jenny_greenteeth",
                 "lantern_man", "peat_king", "bridge_toad", "madame_bufo", "warty_nan",
                 "vaulting_hopkin", "signor_ranocchio", "natterjack_chorus", "spitfire_sal",
                 "peat_cutter", "young_pretender"],
    "triples": ["gideon", "his_highness", "tiddy_mun"],
    "climb_schedule": [2, 4, 6, 9, 11],
    "save_threshold": 3,
    "save_rounds": [5, 8, 10],
    "hold": {"his_highness": "hold in hand until a unit beside his slot has at least twice your median unit's stats, or round 10"},
    "sell_order": ["young_pretender", "peat_cutter", "spitfire_sal", "vaulting_hopkin",
                   "warty_nan", "madame_bufo"],
    "keep": ["the unit beside tiddy_mun", "units beside his_highness"],
    "placement": [
      "lantern_man anywhere; he lures their biggest",
      "the Diva (the unit beside tiddy_mun) across their biggest enemy the Lantern doesn't take",
      "madame_bufo across their biggest instead when it has more than twice the Diva's Health",
      "tiddy_mun at the end of the Diva's row, beside her only",
      "his_highness on the Diva's other side while she holds under 45% of your stats; otherwise between your next two biggest",
      "vaulting_hopkin in a back slot behind the Diva",
      "prima_donna in B2 when two of their top three are in the back row, else F2 or F3",
      "jenny_greenteeth in the row holding their biggest unit that isn't Mired",
      "Soak units across real attackers, never across Eggs, empty slots or 0 Attack",
      "with six units, leave the empty slot beside peat_king"
    ]
  },
  "line_bog_swamp": {
    "tribe": "Bog folk",
    "engine": false,
    "priority": ["prima_donna", "peat_king", "signor_ranocchio", "gideon", "natterjack_chorus",
                 "tiddy_mun", "jenny_greenteeth", "lantern_man", "warty_nan", "madame_bufo",
                 "bridge_toad", "spitfire_sal", "peat_cutter", "young_pretender",
                 "vaulting_hopkin", "his_highness"],
    "triples": ["natterjack_chorus", "warty_nan"],
    "climb_schedule": [2, 5, 7, 9, 12],
    "save_threshold": 2,
    "save_rounds": [8, 11],
    "sell_order": ["young_pretender", "vaulting_hopkin", "peat_cutter", "spitfire_sal",
                   "bridge_toad", "madame_bufo"],
    "keep": ["warty_nan", "natterjack_chorus", "every Soak unit"],
    "placement": [
      "tiddy_mun in a middle slot (F2, F3 or B2) between two Soak units",
      "natterjack_chorus between two Bog folk without Soak (warty_nan, madame_bufo)",
      "madame_bufo across their biggest enemy",
      "signor_ranocchio and spitfire_sal in the back row",
      "prima_donna in B2 when two of their top three are in the back row, else F2 or F3",
      "lantern_man anywhere",
      "Soak units across real attackers, never across Eggs, empty slots or 0 Attack"
    ]
  }
}
```

- **Court plan:** Bridge Toad R1, tier 2 R2, Nan and the Pretender R3, Bufo R4, Gideon and Hopkin R5, tier 4 and Tiddy R6, His Highness R7, tier 5 and the Prima Donna R9, tier 6 and the King R10–R11, the Lantern after.
- **Swamp plan:** a full board by R7, Bitter across the front by R6, the Chorus by R6, Ranocchio R8, Tiddy R9, the Prima Donna R10, the King R12.
- **The critic's check:** the plan asks an independent critic to beat these lists. The obvious attack is a court that skips Bufo and Hopkin entirely for two Soak toads.

---

## 7. Engine support needed

| Need | For | What | Size |
|---|---|---|---|
| Proportional Bitter, rounded up | Bitter everywhere | Track B's `percent` on `bitter`, plus a round-up mode; floor 1 Attack; one Bitter per unit; golden doesn't change it (Track B already) | Small |
| Soak | 7 cards, the Chorus, the Prince | Track Bitter's take per unit per fight, from enemies on its own patches only. Write +k/+k to the recruit copy at Start of Turn, even if it died. Golden k = 2 | Small |
| The Toll | Nan, Tiddy, Sal, the tribe icon | Per player, the sum of every Bitter take in the last fight. Persist it to the next fight. Show it on the Bog folk icon and in the fight summary | Small |
| Toll split | Tiddy Mun | Start of Turn: half the Toll (golden all), split evenly among occupied slots beside her (`adjacent`) | Small |
| Smallest selector | Warty Nan | Friendly Bog folk with the least Attack plus Health; ties in reading order (Track B's `biggest`, mirrored) | Small |
| Toll damage | Spitfire Sal | Start of Combat, after patches: the Toll (golden twice) split evenly among Mired enemies, rounded down | Small |
| Kisses | His Highness, the Prince | A per-player counter: +1 for a fight with a Sink while a frog prince is on the board. On multiples of 3, every frog doubles (golden triples) the units beside it: base plus permanent stats again, the fight copy gains the same at once. A unit is doubled once a turn; the biggest multiplier wins. His Highness transforms on the first break, keeping slot and buffs | Small–medium (the kiss counter exists) |
| Borrowed Attack | Vaulting Hopkin | In the back row, his first attack uses a quarter (golden half) of the highest Attack among the units in front of him, if higher | Small |
| Proportional gain from the target | Signor Ranocchio | `stat_fraction` gain from the attacked Mired enemy: +1/+1 per 4 of its Attack, immediately | Data |
| Pull | Jenny | Start of Combat, before patches: swap the biggest enemy in the facing row into the slot across; skip the Lantern's target | Small (relocate events exist) |
| Biggest-enemy patch | The Lantern Man | His patch on Track B's `biggest` (golden: two), laid before every other patch | Small–medium |
| Peatlings | The Peat King | `summon of: subject` with the sunk enemy's starting stats and Bitter, twice a fight (golden four), nearest the King | Small (pass 2 summon path) |
| Remove caps | Data | Bridge Toad's `permanent_buff_cap`, the Cutter's `lifetime`, Ranocchio's limit, Tiddy's limit, the Prima Donna's `once_per_enemy`, the Prince's spell discount | Data |
| Tier swaps | Data | Tiddy to tier 4 at 3/5; Jenny to tier 5 at 4/7 | Data |
| Screens | UI | Pending Soak badges in the fight; "Gideon soaked +27/+27" in the summary; the Toll on the tribe icon; kiss hearts showing the shared count on every frog; Tiddy's neighbours lit when she is selected; the tray's drink preview against the scout | Small–medium |
| Bots and lines | Harness | The placement policy above; the hold rule for His Highness; the "fell or feed" rule for Bufo. Bots must hold their carries still between rounds, or every across-card measures as a coin flip (pass 1) | Medium |

---

## 8. The breaker's points: what I took and what I didn't

### Wild

| Point | Call | What changed |
|---|---|---|
| **Must:** the curse stacks with copies (×4) | **Taken, and pushed further.** The breaker's guard ("a unit doubled once a turn") still lets two frogs on different counts double one carry twice in three fights | Kisses are shared, so every frog acts on the same kiss, and a unit is doubled once a turn. Model: 2.13× → 1.35× at R14–16 |
| Tokens speed up the curse | Taken | Kisses count fights (one a fight), not deaths |
| Golden Gideon is a common 2–3× board | Taken (moot) | Swell is gone and there is no Brann; golden Soak keeps +2/+2. Golden Gideon: 1.24× / 1.47× |
| The numbers lean on an unpicked body multiplier | Taken | The model uses printed bodies everywhere |
| The curse's "current stats" is undefined | Taken | Base plus permanent stats, on the recruit board; the fight copy gains the same; combat buffs never doubled |
| Jenny's pull fights the Lantern | Taken | Jenny skips the Lantern's target; Ring stripping noted as a feature |
| Over-concentration (note) | Taken as a gate | The court's Diva holds 0.55–0.68. Section 10 puts it first for the combat model, with a spread court as the fallback |
| Sink and Sink (5) under one word (note) | Taken | Sink (X) is gone; "Sink" is only a trigger |

### Carry

| Point | Call | What changed |
|---|---|---|
| **Must:** golden Soak plus the King makes the Diva unkillable | **Taken, and pushed further.** "Gain after the hit" still leaves a golden Soak beside a doubling King gaining more than each bite costs once she survives the first | Soak lands at Start of Turn, never mid-fight. Golden never changes Bitter's share. The King no longer multiplies Soak. No combination grows a unit mid-fight |
| **Must:** two Hopkins kill every carry before it swings | Taken | A quarter of the highest Attack in front (golden half) |
| The crown locks onto the Toad | Taken; fixed another way | No crown: the units beside Tiddy are fed. **Rejected: "the understudy takes the stage"** (the new Diva gets half the old one's gains). The old Diva keeps hers, so every move creates stats; once a turn, that is a +50% engine a turn |
| Golden Nan halves every bite | Taken | Golden never changes Bitter's share; golden Nan gives half the Toll |
| Six rounds behind | Taken | Tiddy at tier 4; Soak on every patch bite; Bitter rounded up. Typical: 0.98 at R6, 0.82–0.87 at R8–R11 (was 0.69–0.83). The combat model is still the gate |
| The funnel and Soak read alike; the King doubles one | Taken | The King doubles nothing. Soak is per unit; the Toll is the board's, by name |
| The Prince's echo reads "current" (note) | Moot | The echo is gone |
| Growth needs enemy Attack; no gold-to-stats (note) | Accepted as variance | The tray preview makes the drink readable |

### Engine

| Point | Call | What changed |
|---|---|---|
| **Must:** Turfs break the hand rules | Moot | No Turfs |
| The typical line is a strong board | Checked | The typical court is 1.04× at R11–13 |
| The King doubles the Lantern's halving | Moot | No halving on the Lantern; no "triggers twice" in Bog |
| Blood Gems with a bog skin | Taken | No tribe number. The Toll is last fight's take from the enemy, not a rising number you buy |
| The tail is thin and Tiddy squeezes it | **Partly rejected** | Tiddy is no longer a flat layer, but Bog's tail stays modest (2.0–2.5×) on purpose: it is the brake tribe. A self-compounding capstone is listed as an option for the cross-tribe synthesis (section 9) |
| Tier-ups don't feel like progress | Partly taken | Higher tiers drink more by design: the Toad one patch, the Prima Donna three, Jenny and the Lantern the biggest enemy. The Peat King's payoff is at field size the fight he lands. Bodies still arrive small; the lever is "When played: gain the Toll" on the tier 5–6 cards |
| "The Drowning" is under the median | Checked | The Swamp is 0.83–1.03× in stats; its answers need the fight model |

### Shared and cross-tribe

| Point | Call |
|---|---|
| Swell is the Hunters' Trophy | **Taken** (both breakers agree). Bog grows from the bite; Ranocchio's and Nan's kill shares are gone too |
| Brann is everywhere | Taken: Bog has no "triggers twice" card |
| Auto-biggest carries | Taken: no auto-picked carry |
| Parasitic engines are spreading | Noted for the cross-tribe synthesis: Bog's Soak is one; Hunters' Take is another. Bog belongs in wave 2, measured against a compounding field |
| No design fought a board | Taken: section 10 makes it the gate |
| Proportional Bitter compounds | Taken as a measure: three bites leave a carry at 42%. Levers in section 10 |
| The any-row budget is spent | Taken: Bog keeps one (the Lantern, tier 6) |
| New tier 5–6 bodies arrive small | Stated: the payoff, not the body, is the reward; lever listed |

---

## 9. For the cross-tribe synthesis

1. **Bog grows from being bitten; Hunters grow from the kill.** Agreed by both breakers. Nothing in Bog reads a dead enemy's stats except the Peat King's Peatlings, which are combat-only copies.
2. **Name clashes.** "The Toll" is a Bog term; the Hunters engine design has a card called the Toll-Bard. If Hunters keep that name, one changes. "Soak" should stay out of other tribes' card text (the Oozes, Birds and Fairies drafts use "soak a hit" in prose).
3. **Bog's tail is the brake by design.** It mirrors the field and can't make its own top 1%. If the owner wants every tribe able to reach 10× in rare games, the option is a self-compounding capstone, e.g. a golden Prince that also doubles himself; test it against the snowball bar.
4. **Answers counted:** one any-row card (the Lantern); one one-row card (Jenny); Bitter on most of the tribe.
5. **Not taken from the engine design: the Peat.** A fourth rising tribe number (with Birds' Tailwind, Fairies' Glamour, Hunters' Titbit) and Blood Gems by its own account. If the synthesis finds Bog needs a gold-to-stats channel, a Turf that stacks in one hand slot is the shape to take.

---

## 10. Before step 3: what must run, and the levers

**Run first (the audit's combat model, on these boards):**
1. **The court's concentration.** The typical R12 board above (Diva 187/195, six units of 18–70 stats) against the median field, and the spread court (biggest unit 0.42) against the same field. If the tall court loses, the line policy takes the spread court and Tiddy's lever goes to a quarter.
2. **The answer bar, both ways.** A median carry against a Bog front row: three Bitter bites leave it at 42%, Bufo halves that again. A carry must still beat Bog sometimes. First lever: Bitter at a fifth. Second: Bitter's loss lasts that attack only (damage reduction instead of a shrink).
3. **The R8–R11 window.** Typical lines at 0.82–0.87 must win some fights on their answers, or Tiddy's share rises before R12.

**Levers, in order:** k (sweep 0.5–1.5); Tiddy's share (¼, ⅓, ½); Bitter's share (⅕, ¼, ⅓); the frog's repeat (third or fourth kiss); Nan's share (¼, ½); "When played: gain the Toll" on the Prima Donna, Jenny, the King and the Lantern if the progression bar fails.

| Risk | Watch | First lever |
|---|---|---|
| The tall court (Diva 0.55–0.68 of the board) | Biggest unit's share in snapshots; overkill waste in fights | Tiddy to a quarter; the frog beside two supports in the line policy |
| The frog's jumps (×2 every three fights) | R12 and R15 boards swing ±40% on timing | Every fourth kiss |
| Golden frog or golden Tiddy | Share of R13–R15 boards at 2× the median against Battlegrounds' 13–23% | Golden frog to "double twice" (×3 → ×2 then ×2 a turn apart) |
| The answer stack | Carry tribes' field win rate against Bog; fight length | Bitter to a fifth; Sal to half the Toll |
| A weak field starves Bog | Bog's growth against ghosts and small lobbies | Accepted variance; the harness reports it |
| Pack bites past Bitter | Hunters against Bog | Rule 9.6.0 stays; a Hunter answer is fine |
| Big numbers on the board | Typical Divas reach 4 digits by R15 (831/847) | Track B's compact labels already fit 5 digits |

---

## 11. What changed from pass 2

| Card | Pass 2 | Pass 3 synthesis |
|---|---|---|
| Bitter (rule) | Loses N Attack, flat; own and lent stack | Loses a quarter, rounded up; one per unit; golden doesn't change it |
| Soak, the Toll, Sink | — | New keyword, term and trigger |
| Bridge Toad | Mire; +1/+1 after its Mired enemy attacks, up to +3/+3 | Mire. Soak. No cap |
| Warty Nan | Bitter 1, lends Bitter 1 | Bitter; her smallest Bog folk gains a quarter of the Toll |
| Young Pretender | Same | Same |
| Madame Bufo | Mire, Bitter 2, halves her killer | Mire, Bitter, halves her killer |
| Vaulting Hopkin | Snap; back row, first, +2 Attack | Snap; back row, first, with a quarter of the highest Attack in front |
| The Peat Cutter | Gold on a Mired death, once a fight, three times in all | Mire; Sink: gold, once a fight |
| Gideon | Mire; counter with +2 Attack | Mire, Soak, hit it back |
| The Natterjack Chorus | Lends Mire and Bitter 1 to any units | Lends Mire and Soak to Bog folk |
| Spitfire Sal | 2 damage to each Mired enemy | The Toll, split among Mired enemies |
| Tiddy Mun | T5 3/6; +1/+1 to the unit hit, twice a fight | **T4** 3/5; the units beside her split half the Toll |
| His Highness | Third kiss: a 6/7 Prince with a spell discount | Every third kiss: double the units beside him; the first time, become the Prince |
| The Prince Restored | Mire, spell discount | Mire, Soak, every third kiss: double the units beside him |
| Signor Ranocchio | +1/+1 after attacking a Mired enemy, once a fight | +1/+1 per 4 of its Attack, every attack |
| Jenny Greenteeth | T4 3/5; Mire, −2 Attack, a neighbour strikes | **T5** 4/7; Mire, Soak, pulls the biggest in the row across |
| The Prima Donna | Mire three slots; Bitter 2 once per enemy | Mire three slots; Soak |
| The Peat King | Mire; 4/4 Peatlings on Mired deaths, twice a fight | Mire, Soak; the sunk rise as Peatlings with their stats, twice a fight |
| The Lantern Man | Snap; +3 Attack per Mired enemy | Mire the biggest enemy, any row; Soak |
| Peatling (token) | 4/4 | The sunk enemy's starting stats; Bitter |

---

## 12. Reproducing the numbers

`python3 -I build/orchestrator/pass3/bog-pass3-model.py` prints the main lines, the strong-field check, the k × s sweep, the breaker probes, the model boards and the highroll (saved in `bog-pass3-model.out.txt`; `verbose` adds every round). Its limits:
- no fights, no opponents' choices, and no combat-only effects (Bitter's shrink, Bufo, Sal, Hopkin, Peatlings, the hit back);
- bites per enemy guessed (the carry 1.5, others 1.4, 85% of patches filled), and the Diva across their carry 65% of the time (85% for the Prima Donna or Jenny);
- printed bodies, no rolls or triples except scripted ones, Harvest Supper at R8 and R11, gold-honest lines with seven units at most;
- the frog's doubling lands on fixed rounds, so single-round numbers jump; read the three-round means.
