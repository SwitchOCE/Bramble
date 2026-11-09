# Oozes, pass 3 synthesis: "The Big Pudding"

9 Nov 2026. The synthesis for the Track C Oozes panel (`docs/ideation/plan-scale-rework.md`, step 1). I read the owner's notes 09a, 09c, 09d and 08e, `fundamentals.md` §1 and §3, the plan, rulebook §8–9 and the BRAMBLE ideation rules, the wording guide, and the three designs: `oozes-carry.md` (Big Pudding), `oozes-engine.md` (Back Burner) and `oozes-wild.md` (What goes in comes out bigger). Then I read the breaker (`oozes-breaker.md`), and the Birds, Bog, Fairies and Hedgerow syntheses where they touch Oozes.

The breaker ranked **Carry** first, **Wild** second and **Engine** third. I start from Carry, take the best ideas from the other two, and fix the breaker's points I accept.

**No price list was used.** Sizes are set against the brief's shape: level with today's boards to about round 7, then about ×1.5 a round. The targets are Battlegrounds' September 2025 means: 53 / 194 / 759 / 2,600 at R6 / R9 / R12 / R15. A paper model backs every number:
- `oozes-pass3-model.py`, next to this file. Run `python3 -I oozes-pass3-model.py`. The saved output is `oozes-pass3-model.out.txt`.
- **Growth:** it plays scripted lines turn by turn and charges gold: income, carry-over, upgrade costs with the discount, 3-gold buys.
- **Fights:** it fights the boards in the carry designer's combat model (`oozes-carry-model/ooze_combat3.py`, which extends the audit's), loaded with patches and not edited.
- Nothing ran in Godot. The fight model is near-deterministic, so read it for direction.

**In short.** Oozes eat. One pudding becomes the Big Pudding: it digests what you feed it into permanent stats. Stone Soup gives every shop unit a tenth of it, so each meal makes the next meal and the next support bigger. Elder Ooze shares every meal with the family, and Granny gathers the family into one swing at Start of Combat. Nothing Ooze happens at End of Turn, so Track B's tier 3 doubler can't square it.

---

## What I took from each design

| From | Kept | Changed |
|---|---|---|
| **Carry** (base) | Stone Soup's share of your biggest Ooze, the engine. Digest and the verb Eat. Dishwater Nell's free meal. Aunt Aspic's +50% on eating, which pulls the carry to the front. Bubble and Squeak's stat-keeping split. Frumenty keeping the text of its last meal. Cut-and-Come-Again's free share of the pudding. Granny's gathered Cleave. Mrs Posset halving her killer. The tier spread, names and portraits | **Nell** eats at Start of Turn, so the doubler can't reach her. **Moss** gives Shield to units coming out of Bellies, not to the carry. **Elder** shares each meal instead of a tenth of the carry. **Aspic and Elder** ignore Ooze meals (a loop guard, below). **Goldens** widen the compounding fractions instead of doubling them. The **slice** is a food token. The **turducken** is cut |
| **Engine** | The see-through rule, proposed for the whole pool. Hasty swallowing the Ooze that holds the biggest enemy. Shield on every unit that comes out of a Belly (the engine design's Syllabub), moved to Moss at tier 2. Hasty's release after 3 deaths. The engine-support list as a template | No Simmer: it shares its shape with three other tribes, and it was End of Turn |
| **Wild** | Hasty's growth, given to your biggest Ooze so it can't splash. Every Ooze growth step at Start of Turn, as Rise is. The fiction ("swallowed whole, comes out alive"), the "HAVE A SLICE!" hook, and the Hasty-eats-Granny moment. Posset's "what comes out attacks at once" as a variation | No Rise and no free take-out rule. Rise is the same shape as Simmer, and take-out needed a hidden rule |

---

## The pitch in three lines

1. **Every unit you buy has three homes.** On the board it fights. In a Belly it's a spare life. In a stomach it's food.
2. **Your Pudding is a stomach the shop can see.** Feed it, and Stone Soup puts a tenth of it on every shop unit. The next meal is bigger, and so is every support you buy.
3. **The family shares the dinner.** Elder Ooze gives the other Oozes half of each meal. At Start of Combat, Granny gathers them all into one swing, and when she falls they drop back out whole.

**What Battlegrounds doesn't have:** a shop that grows with your own carry, and a stomach you can see filling. The nearest relatives are Battlegrounds Demons, who eat tavern minions (a Felbat or Ur'zul eating the shop), and Nomi's tavern buff. The difference is that the shop's buff is a share of your pudding, so it grows as the pudding grows.

---

## Why this fixes what the audit found

| The audit found | Pass 3 Oozes |
|---|---|
| Stats don't compound; about 25% of Battlegrounds' pool says "this game" or "improve", and ours has one card | Soup's share compounds every buy. Digest, Nell, Elder, Aspic, the Slice and Hasty all grow permanent stats proportionally. The typical line grows ×1.56 a round from R8 |
| No concentration: the biggest Ooze was a 10/12 Soup at R12 | The carry holds 48% of the board at R12 and 32% by R15, near Battlegrounds' 34%. It holds its stats with the split and its meal inside, which comes out Shielded |
| Combat-only payoffs | Soup, Digest, Nell, Aspic, Elder, Hasty's gain, Figgy and the Slice are permanent and show in the shop or on the board. Granny, Moss and Posset are fight-only, but Granny is built from stats the shop shows |
| Caps (Soup once a turn, Figgy and Cut-and-Come-Again every other turn) | All gone. What remains: "only your best Soup counts", "one Aspic per eater" and "non-Ooze meals" on Aspic and Elder, each a loop guard. Bubble's "Once a fight" is its golden's lever |
| Answers aim across | Hasty swallows the biggest enemy in any row. Posset halves whoever kills her |
| Hedgerow's lead was one tribe-agnostic aura | Every Ooze payoff reads an Ooze, a Belly or eating. Hasty and Posset splash, but as answers; Hasty's growth needs an Ooze |

---

## Tribe rules (pass 3)

**Belly N** (kept). Reminder: *"Holds this many units, safe inside. When this dies, they come out."* The rules in `docs/ideation/content/oozes.md` stand: last in comes out first; the first takes the Ooze's slot (8.4.1); copies inside count for triples; buying straight into a Belly is a buy, not a play. **No nesting** stays (DECISIONS, pass 2): a unit holding units can't be swallowed. Granny's gathering is the one exception.

**Digest** (new keyword, on 3 cards: Little Dollop, Bubble and Squeak, Frumenty). Reminder: *"Start of Turn: this eats what's inside it."* (8 words)

**Eat** (a verb with its own reminder, like Take). It appears on Digest, Nell, Aspic and Elder. Reminder: *"Destroy it. The eater gains its stats permanently."* (8 words)

**Slice** (new token). No tribe, no text, Created. Cut-and-Come-Again sets its stats. Because a Slice is food, not an Ooze, eating it earns Aspic's bonus and Elder's share.

**"Your biggest Ooze"** stays plain words: the Ooze on your board with the most Attack plus Health. Ties go to reading order. The UI marks it with a ladle, and Stone Soup's share shows inside every shop card's stats.

**Rulings** (Details and the rulebook):
- **What eating takes.** The eaten unit's own Attack and Health: base plus permanent. It doesn't take the tribe bonus, Rings or auras. Eaten units go back to the pool, and no gold is paid.
- **Eating an Ooze passes its stats on whole.** Aspic's bonus and Elder's share count only non-Oozes. Their card text says so, because this is a loop guard (see "Where it could run away", row 1).
- **Start of Turn order:** the shop fills, then Digest, then Nell, then Cut-and-Come-Again. Soup's share is live, so the shop shows each meal as it lands.
- **See-through** (proposed for the whole pool, from the engine design): effects that pick the biggest enemy also see units inside enemy Bellies. They can shrink a unit there, but they can't swallow or move it. If the biggest enemy is inside an Ooze, Hasty swallows that Ooze.
- **Starting survivors** (a variant for the offline damage replay, from breaker C): a unit that began the fight inside your Belly counts once as a starting survivor if it's alive at the end. Ooze wins then stop hitting softly.

**Golden rule for the tribe.**
- A fraction that is a compounding rate never doubles. The golden reaches further instead: Soup reads your two biggest Oozes, Nell feeds two Oozes, Cut-and-Come-Again serves two Slices, Hasty swallows two enemies and Posset halves the killer's neighbours too. This follows Track B ("fractions do not double on golden").
- Two cards double on golden, because only one of each counts per eater or per meal: Aspic (double) and Elder (the whole meal). They are the tribe's highrolls.

---

## The 16 Oozes

Tier spread 3/3/3/3/2/2. Every name, creature and portrait is kept. Rows and stats use the model's line B, the carry route with Aspic (below), unless another line is named. "Ablation" is line B's board total minus the same line without the card.

### Tier 1

**Little Dollop** (Custard Ooze). T1, 1/2.
- **Text:** Belly 1. Digest. Buying into this costs 1 gold less.
- **Golden (2/4):** Belly 2. Digest. Buying into this costs 2 gold less.
- **Condition:** buy units straight into it.
- **Payoff:**
  - The first carry: 2-gold meals that become permanent stats. It's about 10/11 by R5, when it's eaten into Bubble and Squeak.
  - From R8 a fresh Dollop is the **second stomach**. It takes one 2-gold meal a turn, and the carry eats it every few turns. That's +360 stats on the board by R15, and it's where late gold goes.
- **Permanence:** permanent and visible.
- **Enabler:** Stone Soup (an early biggest Ooze), Nell and Aspic (an early eater), and Figgy (a golden Dollop eats two meals a turn).
- **Concentrates:** yes.
- *From:* Carry. The text is trimmed by 2 words.

**Mrs Posset** (Hot Milk Ooze). T1, 2/1.
- **Text:** Belly 1. When this dies: its killer loses half its stats.
- **Golden (4/2):** Belly 2. When this dies: its killer and the units beside it lose half their stats.
- **Details:** the killer is the unit whose attack or effect dealt the killing damage. Rounds down; Health stays at 1 or more. Lasts the fight.
- **Condition:** she dies to an enemy, so she stands in the front row.
- **Payoff:**
  - R2–5: she halves a 3/3 to 6/6 attacker. In the carry designer's model at R4 she wins 42% where a plain 2/1 wins 31%.
  - Late: when the killer is their carry, about 1 time in 5–7, she takes about 60 stats off at R9, 150 at R12 and 570 at R15. It's proportional, so she stays scam at any size.
- **Permanence:** fight only.
- **Enabler:** a front Belly for Pot Luck; Moss (her reserve comes out Shielded).
- **Concentrates:** no; she's an answer.
- *From:* Carry. The golden widens, by the tribe's golden rule.

**Wee Wobbly** (Junket Ooze). T1, 1/4.
- **Text:** Belly 1. After this survives a hit: what's inside comes out, or a 1/1 Drip.
- **Golden (2/8):** Belly 2. After this survives a hit: what's inside comes out, or a 2/2 Drip.
- **Condition:** front row, hit and alive.
- **Payoff:** R1–5, a wall that turns hits into bodies and lets its reserve out early, Shielded with Moss. Late it's sold, or eaten as a meal with the Soup's share.
- **Permanence:** fight only.
- **Enabler:** Moss and Syllabub (each release counts as coming out), the early front row.
- **Concentrates:** no.
- *From:* Carry. "Twice a fight" is cut, because board slots already bound the Drips.

### Tier 2

**Stone Soup** (Broth Ooze). T2, 2/3. **The engine.**
- **Text:** Shop units gain a tenth of your biggest Ooze's stats.
- **Golden (4/6):** Shop units gain a tenth of your two biggest Oozes' stats.
- **Details:** shown live, and a unit keeps it when bought. Only your best Stone Soup counts. Rounds down.
- **Condition:** one Ooze bigger than the rest.
- **Payoff:**
  - Every shop unit gains about +6/+6 at R9, +20/+20 at R12 and +60/+60 at R15.
  - Ablation: +96 / +568 / +2,882 at R9 / R12 / R15. Without Soup, line B is 0.3× the target at R15.
- **Permanence:** permanent once bought, and visible in the shop.
- **Enabler:** every meal (Digest, Nell, the Slice), every support, every tier-up, and Figgy's copies.
- **Concentrates:** it rewards concentration (it reads the biggest Ooze), then hands a share to every support you buy.
- *From:* Carry. The golden widens instead of doubling the rate (breaker Carry #1).

**Dishwater Nell** (Scullery Slime). T2, 2/3.
- **Text:** Start of Turn: the biggest Ooze next to this eats your shop's lowest-tier unit.
- **Golden (4/6):** Start of Turn: the two biggest Oozes next to this eat your shop's two lowest-tier units.
- **Details:** she never eats a frozen unit. With golden, they eat one each, the bigger Ooze first. "Next to" means beside, in front or behind.
- **Condition:** an Ooze next to her, and an unfrozen unit in the shop.
- **Payoff:**
  - A free meal every turn, carrying Soup's share: about 17 stats at R9, 45 at R12 and 125 at R15, or 25 / 68 / 187 with Aspic. Elder shares each one too.
  - Ablation: +57 / +457 / +2,497.
- **Permanence:** permanent.
- **Enabler:** Aspic, Elder, and every Soup share.
- **Concentrates:** yes. She must touch the carry, which pins where the carry stands.
- **The decision:** freeze a low-tier unit you want (a triple piece, a Figgy copy), or let Nell eat it.
- *From:* Carry, moved to Start of Turn. At End of Turn, Track B's tier 3 doubler made Nell 2.95× / 4.47× the target at R12 / R15. A golden that doubled her meals made 2.63× / 3.99×. Now the doubler does nothing, and the golden is 1.44× / 1.94×.
- "Lowest-tier" rather than "smallest", because "smallest" is Hedgerow's word (the Hedgerow synthesis).

**Moss Ooze.** T2, 2/4.
- **Text:** When a unit comes out of your Oozes: it gains Shield.
- **Golden (4/8):** When a unit comes out of your Oozes: it gains Shield and Damage Reduction 25%.
- **Details:** fights only, and your own units only. Granny's family counts as coming out.
- **Condition:** units inside Bellies that come out in the fight.
- **Payoff:**
  - Every reserve costs the enemy two hits instead of one: the carry's waiting meal, the Pie's two reserves, Wobbly's release, and Granny's whole family when she falls.
  - Pot Luck at R12, at equal totals: 50 / 17 / 59% with Moss, 25 / 12 / 20% without.
- **Permanence:** an aura every fight, visible on the board.
- **Enabler:** every Belly, and Granny.
- **Concentrates:** no. It holds a wide board.
- *From:* Engine (its Syllabub). The carry design put Shield on the carry. Combined with the split, that won 98–100% at equal totals (below), so Moss now holds the reserves instead.

### Tier 3

**Aunt Aspic** (Savoury Jelly). T3, 2/4.
- **Text:** Oozes in front of this gain 50% more from eating non-Oozes.
- **Golden (4/8):** Oozes in front of this gain double from eating non-Oozes.
- **Details:** an eater gets one Aspic's bonus, the best. B1 is behind F1–F2, B2 behind F2–F3, B3 behind F3–F4.
- **Condition:** she stands in the back row, and the eater stands in front of her.
- **Payoff:**
  - +50% on every meal of the carry and the second stomach.
  - Ablation: +38 / +212 / +1,589. Line B is 1.34× line A at R12 and 1.75× at R15.
  - Golden: 1.32× / 1.45× line B (the F line).
- **Permanence:** permanent.
- **Enabler:** Dollop, Bubble, Frumenty, Nell, the Slice.
- **Concentrates:** yes. She pulls the carry into the front row, where it's hit first. That's the trade.
- *From:* Carry. One Aspic per eater (breaker Carry #1). The non-Ooze clause stops the carry-move loop.

**Bubble and Squeak** (Two Oozes, Barely). T3, 3/4. **The usual carry.**
- **Text:** Belly 1. Digest. After this survives a hit: split in two. Once a fight.
- **Golden (6/8):** Belly 2. Digest. After this survives a hit: split in two. Twice a fight.
- **Details:**
  - Each half has half its stats. The new half goes to the nearest empty slot; with no room, there's no split.
  - Halves don't split again.
  - A hit that Shield stops doesn't count.
- **Condition:** fed, hit and alive, with an empty slot nearby.
- **Payoff:**
  - The carry: about 58/59 at R9, 202/202 at R12 and 600/600 at R15 on line B.
  - In a fight the split turns overkill into a second attacker. At R12, at equal totals, line B's board wins 62 / 27 / 62% against even / Battlegrounds-shaped (carry front) / Battlegrounds-shaped (carry back) boards.
  - Golden: two meals a turn, and two splits.
- **Permanence:** permanent stats; the split lasts the fight.
- **Enabler:** Aspic, Nell, Moss (its meal comes out Shielded).
- **Concentrates:** yes, and it holds.
- *From:* Carry. "Split in two" saves 4 words. The split is unchanged, apart from the Shield ruling.

**The Sixpenny Pie** (Pudding Ooze, Very Full). T3, 2/5.
- **Text:** Belly 2. When this dies: get 1 gold per unit inside.
- **Golden (4/10):** Belly 4. When this dies: get 1 gold per unit inside.
- **Details:** the gold arrives next turn. A unit with no room to come out doesn't count. The golden keeps 1 gold a unit; the bigger Belly doubles the most it can pay.
- **Condition:** front row, with units inside.
- **Payoff:** about 2 gold a fight from R5, which is one more meal every turn or two, plus two spare lives that come out Shielded with Moss.
- **Permanence:** gold, and permanent reserves.
- **Enabler:** Pot Luck, Figgy (two copies wait inside), Syllabub.
- **Concentrates:** no.
- *From:* Carry, with the turducken cut (breaker Carry #2): eating a full Pie needs nesting, which stays blocked. "Next turn" moves to Details.

### Tier 4

**Frumenty** (Porridge Ooze, Cook's Taster). T4, 2/3.
- **Text:** Belly 1. Digest. This has the text of its last meal.
- **Golden (4/6):** Belly 2. Digest. This has the text of its last two meals.
- **Details:** it can't borrow Belly, Digest, Fly South, Shy, or on-play, on-sell or homecoming text. Borrowed text reads from its slot.
- **Condition:** digest a unit whose text you want. A non-Ooze earns the bonuses; an Ooze passes on whole.
- **Payoff:** a carry with a keyword you choose, at Bubble's size:
  - a Cleave or Shield neutral (Track B's `scale_cleaver` or `scale_defender`);
  - a second Nell (two free meals a turn);
  - Hasty's swallow;
  - Bubble's split (Frumenty eats your old Bubble).
- **Permanence:** permanent.
- **Enabler:** Track B's keywords, and other tribes' text.
- **Concentrates:** yes.
- *From:* Carry. "Its last meal" saves 2 words.

**Figgy Duff** (Boiled Ooze, Sees Double). T4, 3/5.
- **Text:** Belly 1. What's inside goes golden when you buy another copy.
- **Golden (6/10):** Belly 2. What's inside goes golden when you buy another copy.
- **Details:** both copies must be bought. The golden goes to your hand and keeps every copy's buffs.
- **Condition:** a bought unit inside, and a second copy in the shop.
- **Payoff:** a golden from two copies, plus the Triple Reward. The goldens that matter, against line B at R12 / R15:
  - Soup ×1.15 / ×1.15;
  - Nell ×1.31 / ×1.37;
  - Aspic ×1.32 / ×1.45;
  - Soup and Aspic together ×1.49 / ×1.84.
- **Permanence:** permanent.
- **Enabler:** every Ooze golden.
- **Concentrates:** through its goldens.
- *From:* Carry. "Once every other turn" stays cut: it guarded a copy loop that no longer exists.

**Mr Syllabub** (Whipped Ooze, Light Sleeper). T4, 3/6.
- **Text:** When a unit comes out of your Oozes: its Start of Combat fires.
- **Golden (6/12):** When a unit comes out of your Oozes: its Start of Combat fires twice.
- **Condition:** units with Start of Combat text inside your Oozes.
- **Payoff:**
  - A Hasty kept inside a front Pie comes out and swallows the next biggest enemy mid-fight, and your biggest Ooze keeps a fifth of that one too.
  - A neutral answer fires a second time.
  - A Granny inside a Belly gathers again.
- **Permanence:** fight only.
- **Enabler:** Hasty, Granny, neutral answers. With Moss, each release is Shielded and fires.
- **Concentrates:** no.
- *From:* unchanged. The engine design's Shield moved to Moss, so the Rude Awakening puzzle stays.

### Tier 5

**Elder Ooze.** T5, 4/8.
- **Text:** After your biggest Ooze eats a non-Ooze: your other Oozes gain half of it.
- **Golden (8/16):** After your biggest Ooze eats a non-Ooze: your other Oozes gain its stats.
- **Details:** Oozes on your board only; not inside Bellies, not in hand. "Half of it" is half the meal's own stats, before Aspic.
- **Condition:** a fed biggest Ooze, and other Oozes on the board.
- **Payoff:**
  - Each other Ooze gains about +25/+25 a turn at R12 and +90/+90 at R15.
  - Ablation: +230 at R12, +1,708 at R15.
  - The carry's share falls from 52% at R9 to 48% at R12 and 32% at R15, which is Battlegrounds' shape.
- **Permanence:** permanent.
- **Enabler:** Pot Luck (a big family), Granny (more Attack to gather), and golden Soup (a bigger second Ooze).
- **Concentrates:** no. It spreads the pudding to the family, which is the distribution the owner asked for.
- *From:* rebuilt.
  - The carry design's "a tenth of your biggest each End of Turn" matched Hedgerow's Lollop (Hedgerow breaker), and the doubler doubled it.
  - Counting Oozes inside Bellies let it reach 11 Oozes (breaker Carry #3).
  - Sharing each meal is new, Ooze-only and immune to the doubler.

**Hasty Pudding** (Steamed Ooze). T5, 3/9.
- **Text:** Belly 1. Start of Combat: if empty, swallow the biggest enemy. Your biggest Ooze permanently gains a fifth of it.
- **Golden (6/18):** Belly 2. Start of Combat: if empty, swallow the two biggest enemies. Your biggest Ooze permanently gains a fifth of each.
- **Details:**
  - The swallowed unit goes back to its own slot when this dies, after 3 of your units die, or when your side has nobody else. While inside, it isn't a survivor.
  - The gain reads the enemy as it's swallowed.
  - If the biggest enemy is inside an Ooze, this swallows that Ooze.
- **Condition:** an empty Belly at Start of Combat, which costs a stomach or a spare life.
- **Payoff:**
  - Their biggest unit sits out for part of the fight.
  - Against a field whose biggest unit is a third of the board, your biggest Ooze keeps about +26/+26 a fight at R12 and +88/+88 at R15.
  - The Hasty line is 0.96× line B at R12 (it costs a slot) and 1.21× at R15.
- **Permanence:** the gain is permanent; the swallow lasts the fight.
- **Enabler:** Syllabub (a second swallow), Frumenty (borrows the swallow).
- **Concentrates:** into your carry, from the lobby's leader.
- *From:* Engine (the release, and swallowing the container) and Wild (the gain, moved to your biggest Ooze so it can't splash: breaker D and Wild #3). The share is a fifth, not the wild's quarter, because Hasty arrives on top of a full engine.
- This is Oozes' one "biggest enemy in any row" card.

### Tier 6

**Granny Stir-Up** (Christmas Pudding, Everybody In). T6, 4/8.
- **Text:** Cleave. Start of Combat: touching Oozes go inside. Gain their Attack.
- **Golden (8/16):** Cleave. Start of Combat: touching Oozes go inside. Gain twice their Attack.
- **Details:**
  - "Touching" means an unbroken run along the zigzag through her slot.
  - She gathers after your other Start of Combat effects, so Hasty swallows first and then goes in with its prisoner.
  - When she dies, they come out to their own slots, whole.
- **Condition:** an unbroken run of Oozes.
- **Payoff:**
  - One swing with the family's Attack that hits three units: about 400 Attack at R12 and 1,800 at R15 on line B. Then everyone comes back out whole, Shielded with Moss.
  - If they hit her first, the whole family has wasted one enemy attack.
  - At R12 the board wins 97 / 70 / 92% at equal totals with her, against 62 / 27 / 62% without. Against a free halving or swallow it still wins 40% and 58%.
- **Permanence:** fight only, built from permanent stats the shop shows.
- **Enabler:** Elder (a bigger family), Moss, Syllabub, Hasty.
- **Concentrates:** yes, in the fight.
- *From:* Carry. "This" is cut ("go inside"). The ordering rule replaces the wild design's gap puzzle for Hasty.

**Cut-and-Come-Again** (The Pudding That Is Never Finished). T6, 4/6.
- **Text:** Start of Turn: get a Slice with a fifth of your biggest Ooze's stats.
- **Golden (8/12):** Start of Turn: get two Slices with a fifth of your biggest Ooze's stats.
- **Details:** with a full hand, the Slice is lost.
- **Condition:** a big Ooze and room in your hand.
- **Payoff:**
  - A free unit every turn: about 40/40 at R13 and 120/120 at R15.
  - Eat it, and the carry gains +30% a turn with Aspic, while Elder gives each other Ooze a tenth of the carry. Or play it as a non-Ooze body at a fifth of the carry.
  - Ablation: +464 at R15. As an Ooze token it added nothing late, so the Slice is food.
- **Permanence:** permanent.
- **Enabler:** Digest, Aspic, Elder.
- **Concentrates:** either way. The choice comes every turn.
- *From:* Carry (the share) and Wild ("HAVE A SLICE! HAVE ANOTHER!").

**Tokens.**
- **Drip:** an Ooze, 1/1, no text. Unchanged.
- **Slice:** no tribe, no text, Created, with stats set by Cut-and-Come-Again.

### Word counts

Card text (16 cards): median **11**, p90 15, max 20 (Hasty). The guide asks for a median of 11 or less, p90 17 or less and a max of 22, so all three pass. The longest texts carry conditions that change play ("if empty", "a non-Ooze", "next to this"), which rule 8 keeps.

New terms: Digest (3 cards), the Eat reminder (4 cards) and the Slice token. Shield and Cleave are Track B's.

---

## The tribe

### Engine and rate parameter

**The Stock Pot.**
1. A meal goes in.
2. Digest or Nell makes your biggest Ooze bigger.
3. Stone Soup puts a tenth of it on every shop unit, so the next meal and the next support are bigger.
4. Elder hands half of each meal to the family, and the Slice feeds the pot a fifth of itself.

**Rate parameter: `r`, Stone Soup's share. Default a tenth.** Sweep a twelfth, a tenth and an eighth. Results are R12 / R15 × target.

| `r` | No Aspic (A) | Typical, with Aspic (B) | Golden Soup (E) | Golden Aspic (F) | Both goldens (H) | 1% line (I) |
|---|---|---|---|---|---|---|
| 1/12 | 0.70 / 0.66 | 0.91 / 1.11 | 1.03 / 1.20 | 1.17 / 1.52 | 1.30 / 1.84 | 1.84 / 4.54 |
| **1/10** | **0.82 / 0.81** | **1.10 / 1.42** | **1.26 / 1.63** | **1.45 / 2.07** | **1.64 / 2.61** | **2.38 / 6.71** |
| 1/8 | 1.04 / 1.10 | 1.36 / 2.02 | 1.72 / 2.59 | 1.98 / 3.27 | 2.33 / 4.42 | 3.51 / 12.37 |

**Secondary dials.** They stay at their defaults unless `r` alone can't reach the shape:

| Dial | Card | Default | Sweep | Line B at R12 / R15 |
|---|---|---|---|---|
| `e` | Elder's share of a meal | half | a quarter, a third | 0.89 / 1.02 at a quarter, 0.94 / 1.14 at a third; the carry's share rises to 56–58% |
| `s` | the Slice | a fifth | a tenth, a quarter | 1.10 / 1.24 at a tenth, 1.10 / 1.58 at a quarter |
| `h` | Hasty's gain | a fifth | a tenth, a quarter | Hasty line 0.98 / 1.46 at a tenth, 1.09 / 1.84 at a quarter |
| `a` | Aspic's bonus | +50% | +33% | — |

**Why it compounds.** Every meal is the shop unit's base plus `r` × the carry. From R8 the carry eats two or three meals a turn: Digest, Nell, and from R13 the Slice. Elder spreads half of each meal across five or six Oozes. The typical line grows **×1.56 a round from R8 to R15**, the same as the September 2025 means.

**What brakes it.**
- **Belly 1.** One digested meal a turn per stomach. More meals need another stomach (2 gold a meal into a Dollop), a golden Bubble, or Nell.
- **Gold.** A meal costs 3 gold, or 2 into a Dollop.
- **Three stacking rules, each a loop guard:**
  - Only your best Soup counts. Two copies would otherwise double the compounding rate.
  - One Aspic per eater.
  - Aspic and Elder count non-Oozes only.
- **Nothing Ooze is End of Turn,** so the shared doubler can't square the engine.
- **The carry is one target.** Answers that pick the biggest enemy hit it.

### When it comes online

Board totals at combat start, insides counted, ÷ the target means. R6 is also shown for the board alone, because that's the carry-move turn.

| Line | R4 | R6 | R7 | R8 | R9 | R10 | R12 | R15 |
|---|---|---|---|---|---|---|---|---|
| Today's bots (median) | 30 | 52 | 64 | 80 | 92 | 107 | 133 | ~165 |
| Carry, with Aspic (B) | 27 | 75 (board 44: 0.83×) | 1.27× | 1.34× | 1.16× | 1.09× | 1.10× | 1.42× |
| Carry, no Aspic (A) | 27 | 65 (board 35: 0.66×) | 1.27× | 1.41× | 0.97× | 0.88× | 0.82× | 0.81× |
| Pot Luck (P) | 27 | 64 (1.21×) | 1.25× | 1.26× | 1.08× | 1.26× | 1.22× | 1.04× |

- **Carry line:**
  - **Behind on R4–6.** The Dollop is 1/2, the meals sit inside, and on R6 the carry fights inside Bubble. The board alone is 44 against today's 52.
  - **Online on R6–7,** when Soup, Bubble, Nell and Aspic are all down.
  - **Level from R8 to R12.**
  - **Clearly ahead from R13,** with Elder and the Slice: 1.4× by R15.
- **Pot Luck:**
  - **Ahead from R6 to R12,** with bodies, spare lives and Elder from R9.
  - **Level by R15.** The carry line passes it at R13 unless it pivots: the pot moves to F2 behind an Aspic.
- **The tribe's clocks differ on purpose.** The model's R7–R8 runs high, because it loses no fights and never misses a shop.

### The decision the engine creates

- **Each unit you buy:** onto the board as a support, into a Belly as a spare life, or into a stomach as food. And which stomach?
- **Each meal:** a non-Ooze earns Aspic and Elder. An Ooze passes on whole, but moves your carry into a better pudding or borrows its text for Frumenty.
- **Each Slice:** eat it (the pot grows ×1.3 and the family gains) or play it (a body now, at a fifth of the carry).
- **Each turn:** feed the pot (compounding, one target) or buy supports (spread, safer against answers). Keep the second stomach as a second pudding against Hasty-style answers, or merge it into the carry.
- **Each fight:** carry in front behind Aspic (+50%, hit first, splits sooner) or in the back (safe while the front lives, slower).
- **Smaller choices:**
  - freeze a low-tier unit or let Nell eat it;
  - keep Hasty empty (an answer and a gain) or full (a spare life);
  - keep an unbroken run for Granny.

### Carry route: the Big Pudding

1. **R1–5:** Little Dollop, and every spare unit into it at 2 gold. Stone Soup when you see it.
2. **R5–6:** Nell next to the Dollop. On R6 Bubble and Squeak eats the Dollop: it passes on whole, and the carry fights inside Bubble that turn.
3. **R6–8:** Aspic in B1, the carry in F2. A fresh Dollop in F1 is the second stomach, which Aspic serves too.
4. **R9–11:** Elder for the family. Figgy for a golden Soup, Nell or Aspic. Hasty if the lobby's carries are big.
5. **R12 on:** Cut-and-Come-Again's Slice goes into the carry every turn. Granny for the Christmas swing.

Typical R12 board, line B: about 835 stats with insides, 728 on the board.
```
F1 Little Dollop 22/21 [meal]   F2 Bubble and Squeak 202/202 [meal 27/26]   F3 Elder Ooze 28/27   F4 Moss Ooze 25/25
          B1 Aunt Aspic 26/26          B2 Dishwater Nell 27/26          B3 Stone Soup 35/35
```
- Aspic in B1 is behind F1 and F2, so both stomachs get +50%.
- Nell in B2 is next to F2, so she feeds the carry.
- When Bubble or the Dollop dies, its meal comes out Shielded (Moss).
- Soup, Nell, Aspic and Elder work in the Recruit Phase. They can stand anywhere their slot rule allows and lose nothing in fights, since fights run on a copy.
- At R13 Granny takes the Dollop's slot once it's eaten: all seven touch, and she gathers about 400 Attack with Cleave.

### Non-carry route: Pot Luck

Renamed from "Second Helpings", which clashes with Track B's doubler. The bot strategy id `oozes_second_helpings` stays internal.

The biggest Ooze stays in B2 as the pot, with no Aspic. It cooks the shop and feeds the family through Elder. Gold goes into supports and Belly reserves. Moss makes every reserve cost two hits, and Granny makes the family one body at the bell.

1. **R1–4:** Wobbly, Posset, Dollop, Stone Soup. Spare units go into front Bellies.
2. **R5–8:** the Pie in front, Bubble as the pot in B2, Nell in B3 beside it. Moss.
3. **R9–11:** Elder, so every meal grows the family. Hasty when the scout shows a carry.
4. **R12 on:** Granny in F2 with an unbroken run; Syllabub if a Hasty or Granny sits inside a Belly.

R12 board, about 924 stats with insides; the pot holds 31%:
```
F1 Sixpenny Pie 47/47 [two reserves]   F2 Granny Stir-Up 44/43   F3 Moss Ooze 43/43   F4 Elder Ooze 44/44
          B1 Stone Soup 42/41        B2 Bubble and Squeak, the pot 145/145 [meal]        B3 Dishwater Nell 41/40
```
- Hasty swaps in for the Pie or Moss when the scout shows a carry of 35% or more.
- **Why it works:** answers barely touch it. The pot is a third of the board, and Granny gathers after the answers resolve.
- **In the model at R12** (1.15× the target total), it wins 50 / 17 / 59% at equal totals. Without Granny that's 3 / 5 / 22%, and without Moss 25 / 12 / 20%. Both cards are the route.

### Answers to other tribes' carries

1. **Hasty Pudding (T5):** swallows the biggest enemy in any row, until Hasty dies, 3 of yours die or your side is empty. Your biggest Ooze keeps a fifth.
2. **Mrs Posset (T1):** her killer loses half its stats for the fight. That's often their biggest hitter. It lands sometimes, not reliably.
3. **Mr Syllabub (T4):** a Hasty or a neutral answer kept in a Belly fires again when it comes out.
4. **Frumenty (T4):** borrows an answer's text from its last meal.
5. **Granny's Cleave and Bubble's split** answer wide boards rather than carries.

Oozes add one any-row answer to the pool (Hasty) and no aimed-across answers.

### Weak points

- **Biggest-enemy answers hit the carry.** At R12 the carry holds 48% of the board.
  - In the model, a target-shaped board given a free halving or swallow beat line B every time.
  - With Granny out, Oozes still win 40% and 58%.
  - The counters are the second stomach as a second pudding, Pot Luck, and Granny.
- **Two T2 cards carry the engine.** Without Nell the line is 0.31× at R15 (C2); with Nell late and no Aspic, 0.56× (C). Without Soup it's 0.31×. Both are T2 cards with many copies.
- **The carry-move turn (R6):** the carry fights inside Bubble.
- **Early tempo:** R4–R6 sit below today's bots (19, 37 and 44 against 30, 42 and 52).
- **Placement is readable:** Aspic's two slots, Nell touching the carry, and the second stomach. A scout sees all of it.
- **Wide boards with many attacks:** the carry kills one unit an attack until it splits.
- **Pot Luck hits softly** (reserves inside aren't starting survivors) and leans on Granny and Moss. Cleave hits its front row in pairs.
- **Granny locks:** at the bell she is the whole team, so a Mire, Pin or Stall on her stops the family.

### Two highroll moments

1. **"Have a slice!" (R13, golden Aspic).**
   - Cut-and-Come-Again serves a Slice at a fifth of your 280/280 Bubble: 56/56.
   - Bubble eats it behind golden Aspic and gains +112/+112.
   - Elder hands every other Ooze +28/+28, and every card in your shop swells by another +11/+11 while you watch.
   - The next turn's Slice is bigger still.
2. **Granny's Christmas (R14).**
   - Seven Oozes stand in one zigzag. At Start of Combat, Hasty swallows their 300/300 carry, and your Bubble keeps +60/+60 of it for good.
   - Then everyone goes into Granny: one 1,200-Attack Cleave kills three of their units.
   - She falls, and the family drops back out whole, each one Shielded by Moss. Their carry is still inside Hasty.

*A third, for the mirror: their Granny gathers seven Oozes; your Hasty resolves after her and swallows the whole family, and your biggest Ooze keeps a fifth of Granny.*

### Placement decisions

| Choice | Option A | Option B |
|---|---|---|
| The carry's row | Front (F2–F3): Aspic's +50%, attacks first, splits sooner | Back (B2): safe while the front lives, slower: the pot |
| Aspic | B1 or B3: serves the carry and one stomach | B2: serves F2 and F3, so Nell has to sit in B1 or B3 |
| Nell | Touching the carry, which pins its slot | Touching a stomach: it grows, and the carry eats it later |
| The second stomach | Eaten every few turns (concentrate) | Kept as a second pudding (insurance against answers) |
| Bubble's gap | Leave a slot free for the split | Full board: the split waits for a death |
| Hasty | Empty: answer plus gain | Full: one more spare life |
| Granny | An unbroken run of Oozes | A gap cuts who joins |

---

## Boards at R6 / R9 / R12 / R15 (model, `r` = a tenth)

Totals at combat start, insides counted, then × target and × line B at R15.

| Line | R6 | R9 | R12 | R15 | × target R12 / R15 | × B at R15 | Carry share R12 |
|---|---|---|---|---|---|---|---|
| A: carry, no Aspic | 65 | 188 | 623 | 2,108 | 0.82 / 0.81 | 0.57 | 43% |
| **B: carry with Aspic (typical)** | 75 | 226 | 835 | 3,697 | 1.10 / 1.42 | 1.00 | 48% |
| C: Nell late (R8), no Aspic | 80 | 156 | 385 | 1,452 | 0.51 / 0.56 | 0.39 | 49% |
| C2: floor, no Nell, no Aspic | 80 | 163 | 307 | 809 | 0.40 / 0.31 | 0.22 | 47% |
| D: B + Hasty R10 | 75 | 226 | 799 | 4,458 | 1.05 / 1.71 | 1.21 | 51% |
| E: B + golden Soup R9 | 75 | 228 | 957 | 4,235 | 1.26 / 1.63 | 1.15 | 46% |
| F: B + golden Aspic R9 | 75 | 252 | 1,099 | 5,378 | 1.45 / 2.07 | 1.45 | 51% |
| J: B + golden Nell R9 | 75 | 249 | 1,090 | 5,055 | 1.44 / 1.94 | 1.37 | 47% |
| G: B + Track B doubler R8 | 75 | 222 | 842 | 3,354 | 1.11 / 1.29 | 0.91 | 48% |
| H: golden Soup and Aspic | 75 | 256 | 1,247 | 6,793 | 1.64 / 2.61 | 1.84 | 49% |
| I: the 1% line (four goldens by R12, Hasty) | 69 | 281 | 1,808 | 17,457 | 2.38 / 6.71 | 4.72 | 42% |
| P: Pot Luck | 64 | 209 | 924 | 2,695 | 1.22 / 1.04 | 0.73 | 31% |

**How to read the spread.**
- The common lines sit at 0.6–1.4× of each other.
- One golden gives 1.15–1.45×. Two give about 1.8×, the tail Battlegrounds shows at "twice the median".
- Four goldens by R12 reach 4.7× the typical line at R15, which is the owner's top-1% case (up to 10×).
- The doubler no longer moves anything: G is slightly below B, because it costs a slot.

**Ablations on line B** (board R12 / R15 with the card minus without):
- Stone Soup +568 / +2,882; Nell +457 / +2,497; Elder +230 / +1,708; Aspic +212 / +1,589.
- Cut-and-Come-Again +0 / +464 (it lands at R12); the second stomach −92 / +360 (at R12 it's inside the carry).

**Fights** (R12, win % for the Ooze board; columns are even / Battlegrounds carry front / Battlegrounds carry back):

| Board | Equal totals | Against the 760 target | Against a free halving / swallow |
|---|---|---|---|
| A, carry B2 (584, 0.77×) | 73 / 21 / 32 | 0 / 0 / 3 | 0 / 0 |
| **B, carry F2, split, meal Shielded (782)** | **63 / 27 / 62** | **71 / 29 / 63** | **0 / 0** |
| B with the carry design's Shield on the carry | 100 / 98 / 97 | 100 / 98 / 97 | 25 / 0 |
| B + Granny | 98 / 70 / 92 | 97 / 70 / 93 | 40 / 58 |
| Pot Luck with Granny and Moss (874) | 50 / 17 / 59 | 60 / 100 / 100 | 3 / 14 |

At R15, B (3,564) wins 84 / 58 / 80% at equal totals; Pot Luck (2,586) wins 37 / 42 / 83%.

---

## Where it could run away, and the lever for each

1. **The carry-move loop (found in synthesis).**
   - **The loop:** buy a fresh Dollop every turn, put the carry in, and the Dollop digests it. Under the carry design's Aspic, that's ×1.5 on the whole carry each turn for 3 gold. Under a meal-sharing Elder, every other Ooze also gains half the carry.
   - **The guard:** Aspic and Elder count non-Oozes only. Eating an Ooze passes it on whole, which is the owner's "combining".
   - **Fallback if the clause reads badly:** Aspic becomes "Oozes in front of this have +1 Belly", which gold bounds (variation 6).
2. **Golden Aspic** (F, 1.45× B at R15) is the most common golden that matters, because Figgy makes it from two T3 copies. If Aspic-golden lines exceed about 20% of Ooze games at 2× the median or more, golden Aspic becomes +75%, or it widens to "Oozes next to this".
3. **Elder at half** spreads fast: supports outgrow shop units from R12, and the carry's share falls to 32% at R15. If the field shows Pot Luck as a common snowball, `e` drops to a third.
4. **Granny** wins 97–98% at equal totals and 40–58% against answers. If field sims show a common lead, the order of fallbacks is:
   - "the Oozes beside this" (at most two join; the wild design's smaller Granny);
   - then no Cleave.
   Half Attack changed nothing in the model, because she overkills anyway.
5. **Hasty's gain** feeds off the lobby's leader, which is good against runaways. In the Ooze mirror it can eat a gathered Granny. Lever: `h` from a fifth to a tenth.
6. **Golden Bubble** (Belly 2: two digested meals a turn) isn't modelled. Watch it with the goldens.
7. **A Start of Turn doubler** would square Digest, Nell and the Slice. None exists. If one is made, it is the Oozes' 1% card, never a common neutral.
8. **Late gold:** the model leaves about 2 gold a turn unspent from R10, which reaches about 20 by R15. Real lines spend it on stomachs, Figgy copies and spells on the carry (Track B's spell scaling), so real totals run a little higher. The line brain should buy a stomach for every 3 spare gold.
9. **Fight length:** Pot Luck has about 10 bodies, plus Shields and Granny's return. Watch the 200-attack limit.

**Snowball check.**
- Digest, Nell and the Slice grow without wins. Hasty grows off the leader. Elder grows the family whatever the result.
- Only the starting-survivor variant ties growth to winning, and only through damage.
- The tail comes from goldens stacking (rows 2 and 6), which is what the sweep should count as a share of games.

---

## Harness line policies

Format: `tools/sim/line_profiles.json` on `ideation/harness`. These two replace that file's `line_oozes_engine` and `line_oozes_tempo`, so `LinePolicies.resolve` finds them by tribe and engine flag. The harness reads the standard keys; `save_rule` and `line_brain` are for the line-brain work below.

```json
{
  "line_oozes_engine": {
    "tribe": "Oozes",
    "base_strategy": "oozes_waste_not",
    "priority": ["stone_soup", "dishwater_nell", "little_dollop", "aunt_aspic", "bubble_and_squeak",
                 "elder_ooze", "cut_and_come_again", "figgy_duff", "hasty_pudding", "granny_stir_up",
                 "frumenty", "moss_ooze", "mr_syllabub", "sixpenny_pie", "wee_wobbly", "mrs_posset"],
    "climb_schedule": [3, 5, 7, 9, 11],
    "save_threshold": 3,
    "save_until": 10,
    "engine": true,
    "priority_weight": 14,
    "tribe_weight": 4,
    "save_rule": "Spend out every turn, because a meal now compounds through the Soup. The one save: on the turn before a scheduled tier-up, keep 3 gold so the climb and a meal fit the same turn. After tier 6, spend everything; every 3 spare gold buys a stomach meal.",
    "line_brain": {
      "meals": "After the board is set, put the biggest non-Ooze shop unit into the carry (the biggest Digest Ooze with room); use the Dollop's discount while the carry is a Dollop. From R12, the Slice is the carry's meal when it is bigger than the best shop unit; otherwise play it over the smallest support.",
      "carry_move": "When Bubble and Squeak or Frumenty arrives, put the empty Dollop into it, unless the Dollop is golden.",
      "second_stomach": "From R8, keep a fresh Little Dollop as a second stomach in front of Aspic; one 2-gold meal a turn; the carry eats it every 3 turns, unless the next opponent's scout shows a biggest-enemy answer, then keep both.",
      "placement": "With Aspic: carry F2, second stomach F1, Aspic B1, Nell B2. Without Aspic: carry B2, Nell B1 or B3. Moss, Soup and Elder fill the rest. Keep one slot beside the carry free for the split when there is a spare body. From R13, Granny in an unbroken run.",
      "hasty": "Buy and keep it empty when the next opponent's biggest unit holds 35% or more of its board; otherwise use its Belly as a spare life.",
      "freeze": "Freeze only a wanted low-tier unit (a triple or Figgy copy) to keep it from Nell; otherwise let Nell eat."
    }
  },
  "line_oozes_tempo": {
    "tribe": "Oozes",
    "base_strategy": "oozes_second_helpings",
    "priority": ["stone_soup", "moss_ooze", "elder_ooze", "granny_stir_up", "dishwater_nell",
                 "bubble_and_squeak", "sixpenny_pie", "hasty_pudding", "wee_wobbly", "mr_syllabub",
                 "mrs_posset", "cut_and_come_again", "little_dollop", "figgy_duff", "frumenty", "aunt_aspic"],
    "climb_schedule": [3, 5, 7, 9, 11],
    "save_threshold": 0,
    "save_until": 0,
    "engine": false,
    "priority_weight": 14,
    "tribe_weight": 4,
    "save_rule": "Never save. Spare gold buys reserves into front Bellies, Ooze reserves first.",
    "line_brain": {
      "meals": "The pot (Bubble and Squeak in B2) gets one non-Ooze meal a turn; Nell stands beside it.",
      "reserves": "Fill front Bellies (Pie, Wobbly, Posset) with the biggest spare units; the last in is the biggest.",
      "placement": "Pot B2, Nell B3, Soup B1; Pie, Moss and Elder in front; from R12 Granny F2 with every slot occupied so the run is unbroken.",
      "hasty": "Swap Hasty in for the Pie or Moss when the scout shows a carry of 35% or more; keep it empty.",
      "slices": "Play each Slice over the smallest support; never feed it to the pot."
    }
  }
}
```

**Bot needs for both lines:**
- the meal policy and the non-Ooze preference;
- the carry move;
- the second stomach and when to keep it;
- slot rules for Aspic, Nell and Granny's run;
- the Hasty trigger.

Without them, Oozes look weak for the wrong reason, as `oozes.md` warned in pass 1. In the model, the second stomach alone moves R15 by +360 (10%).

---

## The breaker's points: accepted and rejected

| Breaker point | Call | How or why |
|---|---|---|
| A, must fix: the tier 3 doubler squares End of Turn engines | **Accepted, fixed by timing** | No Ooze card has End of Turn text. Nell moves to Start of Turn, and Elder triggers on eating. The doubler line is now 0.91× of B (it costs a slot). At the carry design's timing it was 2.95× / 4.47× the target. The doubler's tier is still a cross-tribe call |
| B, must fix: a back-row riser loses fights | **Accepted** | No riser. The carry stands on the board and holds with the tribe's own tools: the split, its Shielded meal, Granny's Cleave. It doesn't depend on finding a neutral Cleave. Line B wins 63 / 27 / 62% at equal totals |
| C, should fix: Ooze wins hit softly | **Accepted as a sweep variant** | A unit that began inside your Belly counts once as a starting survivor. It goes to the offline damage replay. It matters most for Pot Luck |
| D, should fix: Hasty splashes | **Accepted** | Today's release is kept, and the gain goes to your biggest Ooze. A splasher gets the swallow and nothing else |
| E, should fix: Simmer and Rise are everyone's shape | **Accepted** | Neither is used. The Pie oven is only variation 3 |
| F, note: the three tables used different bases | **Accepted** | Every table here counts insides, as the harness snapshot will, and fights rank the boards |
| Carry #1, must fix: Aspics stack; golden Soup doubles `r` | **Accepted, extended** | One Aspic per eater. Golden Soup reads your two biggest Oozes. I also found that golden Nell doubled meals and the carry-move loop, and fixed both. Both goldens together: 2.6× the target at R15, where the breaker measured 15.3×. `r` sweeps from a twelfth to an eighth |
| Carry #2, must fix: the turducken needs nesting | **Accepted** | Cut. No nesting stays. The Pie is Pot Luck's gold card |
| Carry #3, should fix: Elder counts Oozes inside Bellies | **Accepted, rebuilt** | Elder counts board Oozes only and shares meals. That also clears the Hedgerow Lollop overlap |
| Carry #4, should fix: Hasty makes carries pointless | **Accepted** | The 3-death release is back |
| Carry #5, should fix: the carry holds too well | **Accepted, fixed another way** | In the model, Shield on the carry plus the split is the over-hold: 98–100% at equal totals. Moss now Shields what comes out of Bellies, and the split counts only hits that deal damage. Line B: 63 / 27 / 62% |
| Carry #5: "split after the second hit" | **Rejected** | In the model it made the Shielded carry stronger (100 / 96 / 95%) and the unshielded one erratic (88 / 25 / 57%). The knife-edge was Shield plus the split, not the split's timing |
| Carry #5: "Granny is a coin flip already" | **Rejected, with the evidence** | With Moss's release and the family coming back whole, both outcomes help Oozes: 97–98% at equal totals. She stays, as the capstone moment, with fallbacks (row 4 of the runaway list) |
| Carry #6, should fix: the doubler doubles Nell and Elder | **Accepted** | See A |
| Carry #7, note: name "your Pudding" | **Rejected** | It clashes with Hasty Pudding, Granny's "Christmas Pudding" and the Pie's "Pudding Ooze", and the plain words are about as short. Texts are trimmed instead: median 11 (was 13) |
| Carry #7, note: "Eat" beside Feast and feeding | **Kept for Oozes** | Eat is the Oozes' verb, with its own reminder. See the cross-tribe notes |
| Engine: see-through rule | **Taken, proposed pool-wide** | It stops a carry hiding in a Belly from Start of Combat answers |
| Engine: Hasty swallows the Ooze that holds the biggest enemy | **Taken** | Hasty's Details |
| Engine: Syllabub's Shield as a variation | **Taken onto Moss** | At tier 2 it's Pot Luck's hold. Syllabub keeps its Start of Combat text |
| Engine #3: Nell's unit can fill Hasty's Belly | **N/A** | Nell's meals are stats, not Belly contents |
| Engine #4: flat payoffs, small tier-ups | **Accepted** | Every shop unit carries Soup's share. A T5 Elder bought at R10 arrives at about 16/18 |
| Engine #7: Moss and spell scaling | **N/A** | Moss no longer reads spells |
| Wild #1: no answer reaches the carry | **N/A** | The carry is on the board. See-through is adopted anyway |
| Wild #3: Hasty's quarter splashes | **Accepted** | A fifth, to your biggest Ooze |
| Wild #4: "comes out" rests on a hidden rule | **N/A** | There's no free take-out. Moss and Syllabub fire only in fights, when an Ooze dies or Wobbly lets go |
| Wild #5: flat payoffs, unspent late gold | **Accepted** | Soup is proportional and Elder is a share. Late gold goes to stomachs. The model still leaves about 2 gold a turn, which the line brain should spend (runaway row 8) |
| Wild #6: wording | **Accepted** | Wobbly is trimmed. No card is over 20 words |
| Wild #8: keep the Start of Turn timing | **Accepted** | Every Ooze growth step is Start of Turn or on eating |
| For the synthesis, item 4: one oven card at Start of Turn | **Left as a variation** | The cross-tribe call decides who owns "leave it and it grows" |
| Sims the breaker asked for | **Accepted** | Listed under "Before step 3" |

---

## Cross-tribe notes

- **The doubler.** Oozes now have no End of Turn text, so they don't care where it sits. The Fairies synthesis has several End of Turn engines, so its tier and reach still need the cross-tribe call. The route-name clash is gone: Second Helpings is now Pot Luck.
- **"Leave it and it grows by half"** is gone from Oozes. Hedgerow keeps the sleep and the Fairies their Ring.
- **Lollop and Elder.** Hedgerow keeps "share the biggest with the Line". Elder now shares each meal, a different trigger and source, so neither tribe needs its fallback.
- **"Gain a share of an enemy."** Three tribes now have it:
  - Hasty: swallow the biggest, and your biggest Ooze gains a fifth;
  - the Birds' Jack Daw: "your biggest Bird permanently steals a quarter of the stats of the enemy across";
  - the Hunters' Take.

  Hasty differs: it takes nothing from the enemy, and it aims at the biggest. If the cross-tribe call wants one owner, Hasty's fallback is the plain swallow, and the Hasty line drops from 1.21× to about 1.0× of B at R15. A Slice of the swallowed unit is variation 5.
- **Eat** is the Oozes' verb, with a reminder. The Hunters engine's "Feast" and Hedgerow's "feed" (Acorns) should stay off it.
- **"Smallest"** is Hedgerow's word, so Nell reads "lowest-tier".
- **Any-row answers:** Oozes add one, Hasty. The Fairies breaker counted 6 or more across tribes against a plan of 2 or 3; the cross-tribe synthesis has to choose.
- **See-through** is a pool-wide rule. Only Oozes have Bellies, but every tribe's biggest-enemy answer reads it.
- **Other Ooze-tagged units:** `dewdrop_ooze` (T1 2/3), `bramble_ooze` (T3 4/4), `bog_ooze` (T4 5/5) and `great_ooze` (T5 6/6) are plain bodies outside these 16. They count as Oozes for Soup, Elder and Granny. Whether they stay is the cross-tribe call.

---

## Engine support needed

| # | Piece | Work |
|---|---|---|
| 1 | **Digest** | A Start of Turn trigger that eats the Belly's contents. They go back to the pool; the eater gains their own Attack and Health permanently, without the tribe bonus or Rings |
| 2 | **Eat and bonuses** | An `eat` effect with an eat-bonus query: Aspic's +50% (best only, non-Ooze only) and Elder's on-eat hook |
| 3 | **Stone Soup** | A shop stat layer from a player-level live value: floor(`r` × your biggest Ooze's Attack and Health), kept on purchase, best Soup only. Golden reads the sum of your two biggest. Precedent: pass 1 Soup's per-shop layer |
| 4 | **Selectors** | `biggest_own` with a tribe filter and `exclude_self`; `biggest_own_next_to` (Nell); `shop_lowest_tier_unfrozen`; `biggest_enemy` (exists on `ideation/mechanics`) |
| 5 | **Nell** | A Start of Turn eat from the shop, after Digest. Golden: two eaters, one unit each |
| 6 | **Moss** | An on-come-out trigger (own units, fights only) that grants Shield; golden adds Damage Reduction 25%. Granny's release counts |
| 7 | **Bubble** | The split exists. "Survives a hit" must exclude a hit that Shield fully stops. Halves don't split |
| 8 | **Frumenty** | A persisted "last meal" record, read by the existing `borrows_text` |
| 9 | **Elder** | On the biggest Ooze's eat (non-Ooze meal), board Oozes gain the share of the meal's own stats, before Aspic |
| 10 | **Hasty** | Target `biggest_enemy`. Today's release (dies, 3 friendly deaths, side empty). A permanent gain from combat to your biggest Ooze's recruit copy. See-through: swallow the Ooze that holds the biggest |
| 11 | **Posset** | A killer reference on the death event; `stat_fraction` reduce on both stats; golden also hits the units beside the killer |
| 12 | **Granny** | Add Cleave (Track B). Her gather resolves after your other Start of Combat effects |
| 13 | **Cut-and-Come-Again** | A new token, Slice (no tribe, no text, Created), with stats set to a fraction of your biggest Ooze, sent to hand |
| 14 | **Rules** | See-through for biggest-enemy effects. The starting-survivor variant as a flag for the offline replay |
| 15 | **Data only** | Wobbly's and Figgy's limits removed; new bodies (Nell 2/3, Aspic 2/4, Elder 4/8, Hasty 3/9, Cut-and-Come-Again 4/6) |
| 16 | **Line brain** | The policies in the JSON above |
| 17 | **UI** | A ladle on your biggest Ooze. Soup's share inside shop stats, with a pot icon. A "+X/+Y at Start of Turn" preview on Digest Oozes. Aspic lighting the two slots she serves, and Nell lighting her eater. The meal floating inside the jelly. Elder's share shown when a meal lands |

---

## Variations, if the panel wants another shape

1. **Posset (wild):** "Belly 1. When this dies: what comes out attacks at once." Test it against the killer halving.
2. **Syllabub (engine):** units that come out gain Shield. That's now Moss's job, so this is only a variation if Moss changes again.
3. **The Pie as one oven (wild's Rise):** "Belly 2. Start of Turn, in the back row: what's inside gains half its stats." Only if the cross-tribe call leaves the shape to Oozes.
4. **Smaller Granny (wild):** "Cleave. Start of Combat: the Oozes beside this go inside. Gain their Attack."
5. **Hasty's gain as food:** "After this fight: get a Slice with a fifth of it." Eat it or play it. It splashes more, so it isn't the default.
6. **Aspic as room, not a rate:** "Oozes in front of this have +1 Belly." It's loop-free without the non-Ooze clause, and gold bounds it.
7. **Nell at End of Turn** (the carry design's original timing), if Track B's doubler moves to tier 5 or stops doubling eat effects. It restores "freeze or let Nell eat the leftovers".

---

## Calls for the orchestrator to log

1. Oozes are built on the Carry design. Simmer and Rise are not adopted: breaker problems A, B and E, and the cross-tribe sameness.
2. Rates: `r` a tenth, `e` half, `s` a fifth, `h` a fifth, Aspic +50%. Each has a sweep range.
3. Nell moves to Start of Turn and eats the lowest-tier unit. No Ooze card has End of Turn text.
4. Moss gives Shield to units coming out, not to the carry. The carry design's version won 98–100% at equal totals in the model.
5. "Non-Oozes" on Aspic and Elder, a loop guard against eating the carry into a fresh stomach every turn.
6. The Oozes' golden rule: compounding fractions widen; Aspic and Elder may double.
7. The see-through rule is proposed for the pool. The starting-survivor variant goes to the offline damage replay.
8. The route is renamed Pot Luck. The turducken is cut, and no nesting stays.

## Before step 3: what must run (harness)

- The `r` sweep (a twelfth, a tenth, an eighth) on both lines, read as distributions. Two numbers decide it:
  - the share of Ooze games at 2× the median or more from R10 (aim 13–23%);
  - the share of the round 8 leader's wins.
- Golden frequency on the engine line (Figgy goldens of Soup, Nell and Aspic), read as a share of games, not a best case (9d).
- Hasty against carries of 34% and 60% of a board, in both rows. Also the Ooze carry against one any-row answer in a common field.
- The R12 and R15 carry boards against the field, with and without Granny. Pot Luck with and without Moss.
- Every Ooze line with the tier 3 doubler in the pool, to confirm it does nothing.
- Game length and damage dealt, with and without the starting-survivor variant.

## Model limits

- **Growth:** scripted arrival rounds stand in for the shop. Supports are typical shop units of their tier. The field's biggest unit is 34% of the target board. Spells, heroes, Discovers and triples other than the named goldens aren't modelled.
- **Fights:** the carry designer's combat model with patches: list Bellies, damage-only splits, Hasty's 3-death release, and a Start of Combat halving for the answer test. It's near-deterministic; fights flip on breakpoints from 0 to 100%. The opponents are plain boards with no keywords; real boards bring their own holds and answers.
- **Granny** gathers every Ooze on the side in the model, which stands in for a full run. In the answer test, the answer resolves before the gather.
