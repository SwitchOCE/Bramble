# Design round 5: positions, counters and bounded economy

**What this is.** Eight new card ideas for the ideation build after build 6, aimed at the five open problems in the brief. There's also a variation note for each existing card that strains one of the owner's principles. Two critics and a costing pass reviewed the draft (`design5-critics.md`). The file has been revised once: each pitch opens with its revised text. Section 0 marks what's recommended for the next build.

**Base.** `ideation/main` at 359fc20 (build 6 content, c8693ae plus logs). The current library is the 133 pool units in `content/units/`, the spells in `content/spells/` and the heroes in `content/heroes/`. Nothing here is game code.

**The owner's rules for this round (8 Nov), which this file follows.** "Apply them going forward, to new ideas only. Do not revise, rescale or cut anything already in your library. If an existing design strains one of the principles, add a short note or a variation next to it and leave the original as it is. The owner wants to try the current designs before anything is reworked. Treat the principles as a lens, not a veto. If a new idea strains one, say which, and propose a version that keeps the idea's core rather than dropping it."

So section 3 adds notes beside existing cards and changes none of them. P1 to P9 are the principles in section 1 of `docs/design/owner-taste.md` (6150f29).

**Numbers.** Stats are the designer's first guess at the **current library's scale**, so a card can drop into build 6 as it stands. The costing pass checked them against `docs/design/power-budget.md`. Under rulebook v0.5 (stats about double Battlegrounds), double each body and each +N.

**Shared wording.** The draft used "to the left of this" (the next slot left in the same row, from the owner's side), the owner's own example (N-B §8.1). It would have been a new engine selector. After review, no recommended or revised main text uses it. It survives only in the Cuckoo's hatch variation and as the Mould's left-hand option.

---

## 0. Recommended for the next build (at most 4)

Chosen after the critics and costing (section 5 explains the choice). Texts are the revised ones.

| # | Item | Problems | Why it's in |
|---|---|---|---|
| 1 | **Horseshoe** (spell, tier 2, 1 gold): "Choose one of your slots. Next fight, the Ring across from it gives half." | 1, 3, 4 | It's the cheapest direct answer to the biggest pile source: Rings carry 27% of the biggest unit's stats at round 15. You buy it after scouting, so it's never dead. All three reviewers backed Cold Iron, and Critic A asked for this spell form specifically. The Farrier unit stays ready as the board form. |
| 2 | **Barn Owl** (Birds, tier 4, 3/4): "Swoop. Never takes quarry. Takes no damage when attacking the back row." | 3, 4 | It puts two of the owner's own positioning examples on one card. It gives back-row engines and Burner or Stand Behind Me carriers a weakness, and the defender has four answers: decoys, an empty back row, Mire, or killing it. Both critics put it in their top 4, and costing says keep it. |
| 3 | **Redwing**, revised (Birds, tier 2, 2/2): "Fly South. Eggs beside this have their Bird's full Attack and Health." | 2, 3 | It's the one item aimed at Summer/Winter's measured weakness, the tempo lost while Birds are away (6.11 average place, 1.4% wins). It makes no permanent stats, so it doesn't feed problem 1, and it's positional. Critic A proposed this text. |
| 4 | **Market Stall**, revised (spell, tier 4, 4 gold): "For the rest of the game, your shop shows 1 more unit, of your tier. At most 2 Stalls." | 1, 5 | It's the owner's own idea (N-A §5.3), a delayed and bounded kind of economy. It spends mid- to late-game gold on choice instead of piles, so carriers get replaced rather than fed. Critic B ranked it 4th, costing set its price, and Critic A's objections are answered in pitch 8. |

**First reserves, in order:** the Old Pike (Critic B's first pick, on budget, needs "never takes quarry"), the Jelly Mould (Critic A's second pick, now tier 5 with the nearest-gap fix), the Pedlar (bounded, 3 times in all) and the Cuckoo (simple form, best tried after Redwing). The Farrier unit goes in alongside Horseshoe if a playtest shows Ring lobbies need a board answer as well.

---

## 1. The open problems, and which idea aims at which

| Idea | 1 Late stall / stat piles | 2 Summer/Winter Birds | 3 Positioning | 4 Generic engines | 5 Economy kinds |
|---|:-:|:-:|:-:|:-:|:-:|
| 1 The Farrier | ● | | ● | ● | |
| 2 Barn Owl | ◐ | ◐ | ● | ● | |
| 3 Redwing | | ● | ◐ | | |
| 4 The Cuckoo | | ● | ● | | |
| 5 The Jelly Mould | ◐ | | ● | | |
| 6 The Old Pike | ◐ | | ● | ◐ | |
| 7 The Pedlar | | | | | ● |
| 8 Market Stall | ● | | | ◐ | ● |

● aims straight at it, ◐ helps on the side.

**Why these and not more stat cards.** The engines study (`engines-design.md` §1) found that total stats decide late fights (coefficient +1.17), and that the stats come from neutral spells and Rings sitting on cheap bodies. Adding more stats won't break that. Three things can. (a) Counters that bite harder the bigger the pile is, or that bite by position: the Farrier, the Owl and the Pike. (b) Gold sinks that buy quality instead of quantity: Market Stall and the Pedlar. (c) Second lives that copy the printed card, never the pile: the Mould and the Cuckoo. The owner's counterplay model is "Venomous, Leeroy, scam units, positioned well" (N-B §2). Highway Robbery, the Birds' scam route, is already the strongest Bird route in bot data (4.57 average place, 10.2% wins), so scam pieces are known to work in this engine.

---

## 2. The pitches

### 1. The Farrier — Cold Iron against Rings

> **Revised after review: two forms, the spell first.**
> **Horseshoe** — spell, offered from tier 2, costs 1: "Choose one of your slots. Next fight, the Ring across from it gives half." Bought after scouting, so it is never a dead slot (Critic A: a unit is dead against the two-thirds of boards with no Ring).
> **The Farrier** — neutral, tier 3, 3/4: "Start of Combat: the Ring across from this gives half." Rounding (down) moves to the Ring reminder text (Critic B). Golden: "...across from this and beside that slot." Kept as the board form for Ring-heavy lobbies; costing puts it on to +10–30%, inside the slot-targeting band.
> Steal (variation a) is dropped: both A and costing say it doubles the swing, and totals decide fights.

*The draft as reviewed follows; its reasoning still holds except where the revision says otherwise.*

**Card.** Neutral, tier 3, 3/4.
**Text.** "Start of Combat: the Ring on the enemy slot across from this gives half this combat, rounded down."
**Golden.** "...the Rings on the enemy slot across from this and the two slots beside it give half..."
*The designer first wrote "does nothing this combat" and chose half for P3 (below).*

**How it plays.** Scout already shows Rings by slot. You stand the Farrier across from the opponent's ringed carry. Folklore: a horseshoe over the door keeps the fair folk out, and cold iron undoes their gifts.

**Interactions.**
- **Rings, Boundary Stone and Spore Cloud** are the target. Rings stay on slots, so the Ring player can't step out of the lane the way a unit can. Their answers are to spread Rings over several slots, to fight the Farrier itself (it's 3/4), or to win Start of Combat ordering with a Whirligig Beetle (rows swap, so a different slot ends up across).
- **Will-o'-the-Wisp:** a halved empty Ring still counts as a Ring, and its Wisp still comes. Only the stats are halved.
- **Fairy Monarch:** the Monarch's extra +1/+1 is part of the Ring, so it's halved too.
- **Reel-Mistress:** a halved Ring dances halved. The halving belongs to that Ring for the fight.
- **Queen of Elfland:** no effect. Her split happens in the recruit phase, where the Farrier does nothing.
- **Hex** (Hedge Witch) isn't a Ring and isn't affected. The two stack in one lane: the Witch takes Attack, the Farrier takes the Ring.
- **Mag Pye** taking the Farrier's text runs it against you for that fight. That's fine and readable.

**Why a player runs it.** Any tribe meeting a Ring pile has, today, only Nightshade (Belladonna Sprite) and Jack Daw as answers. The Farrier is a neutral 3/4 that's never dead. With no Ring across, it's just a body.

**When it's good.** Round 12, against the pile from `engines-critic-play.md` game 3: a golden Mrs Sorrel at 32/35, 19 of it from a Ring on F2. With the Farrier across F2, she fights at about 23/26. That's beatable by a normal late board instead of being the fight.

**Variations.**
- (a) **Steal:** "...gives half, and this gains the other half this combat." More swingy, and fun.
- (b) **Horseshoe, a spell** (tier 2, 1 gold): "Choose one of your slots. Next fight, the Ring across from it gives half." The spell version needs no slot on the board.
- (c) **Iron Gate, an aura:** "Enemy Rings in the row across from this give half." Bigger, for tier 5.

**Resembles.** Hearthstone's Silence, aimed at a slot instead of a unit. Battlegrounds has no slot buffs, so nothing there counters one.

**Principles it might strain.** **P3:** "does nothing" would erase a whole investment in one move, the kind of single hard counter that feels arbitrary. **Half** keeps the core: cold iron weakens the Ring by position. A ringed carry still matters, it just stops deciding the fight alone. **P1:** one more across-text to read. That's small, since Hex already teaches "the enemy slot across from this".

---

### 2. Barn Owl — hunts the back row unharmed

> **Revised after review:** "Swoop. Never takes quarry. Takes no damage when attacking the back row." Golden 6/8, same text.
> "Never takes quarry" closes the rules hole Critic A found: quarry outranks a unit's own targeting (`engine.md`), so the Laird of the Sett or either Brock would silently turn Swoop off. Wording shortened per Critic B. Costing: +10–20%, keep; fallback if hot is "takes half damage" or 3/3.

*The draft as reviewed follows; its reasoning still holds except where the revision says otherwise.*

**Card.** Birds, tier 4, 3/4.
**Text.** "Swoop. When this attacks a back-row unit, it takes no damage."
**Golden.** 6/8, same text. *A growing golden ("+2 Attack per back-row attack") was considered and left out for P3.*

**How it plays.** Swoop already sends it at the back row. Now that's free for it. It's built to kill the small support units that hide behind a wall and work in the fight: Elder Ooze, Mr Syllabub, Reel-Mistress, Tiddy Mun, the Gabble Ratchet, Sexton Beetle, the Mountain Glutton, Weasel Second's beneficiaries, Sett Warden.

**Interactions.**
- **Charcoal Burner and Stand Behind Me** put permanent stats on the units behind a front-row unit, which means the back row. The Owl can't one-shot a 30/30 there, but it takes no damage from it, so it keeps chipping and never trades. Against small back-row engines, it kills them.
- **Counterplay for the defender** (P3 wants several fixes, not one):
  1. Keep the back row empty: four in front and nothing behind.
  2. Put a decoy in the back row. Swoop picks at random among the back row, so a Garden Snail (Shell 4) or an Egg spreads the risk.
  3. Mire it. Mire binds "even in your back row", so a back-row Madame Bufo or The Peat King forces the Owl to attack it, and Bitter still shrinks it.
  4. Kill it first. It's 3/4, and the Old Pike or Quick units remove it.
- **Bristle** doesn't hurt it on a back-row attack: Bristle needs damage dealt to the Owl, and it takes none. Bitter still works, because Bitter isn't damage.
- **Dame Hoolet** (back row attacks first) gets the Owl in before the enemy's support has fired.
- **Ballooning Spider** is the neutral back-row sniper. Together they make the back row unsafe without making it pointless.

**Why a player runs it.** Highway Robbery (the scam route) gets its third tool beside Jack Daw and Mag Pye. Passage players get a counter to the enemy's Gabble Ratchet. It's also the Bird answer to the support layout the lobby converges on.

**When it's good.** The opponent is Oozes: Granny Stir-Up in front, Elder Ooze and Mr Syllabub in the back row. The Owl kills Elder Ooze first, so every later Belly release lands without its +3/+3.

**Variations.**
- (a) **Tawny Owl, neutral:** "In your back row, this attacks the enemy back row and takes no damage from it." For non-Birds.
- (b) **Gold:** "After this kills a back-row unit, get 1 gold next turn, once a fight." Fits the Birds' small-gold habit, and it's an economy trigger driven by action (P4).
- (c) **Hunts the weakest:** "Swoop. Attacks the back-row unit with the lowest Health." It combines the owner's back-row and lowest-Health examples.

**Resembles.** Battlegrounds' Zapp Slywick (attacks the lowest-Attack enemy), aimed by row instead. Ballooning Spider is the in-house cousin.

**Principles it might strain.** **P3:** a unit that takes no damage needs another weakness. It has four (above), and its 4 Health is the main one. A growing golden would snowball past those weaknesses, so it isn't used. The core-keeping fallback, if the Owl measures too strong, is "takes half damage" instead of none.

---

### 3. Redwing — the Eggs beside it stand full size

> **Revised after review: aimed at tempo, not stats.** Birds, tier 2, 2/2. "Fly South. Eggs beside this have their Bird's full Attack and Health." Golden: "...full Attack and Health, +2/+2."
> All three reviewers objected to the homecoming version: costing put it +60–100% over (copies stacked, far above the tier 2 growth rate), Critic A said it adds permanent stats (problem 1 again) and pays too late for Summer/Winter's early-tempo loss, and Critic B said a per-Bird cap is hidden state. The new text hits the loss itself, the half-sized Egg while a Bird is away, makes nothing permanent, shows on the board, and is positional: you choose which slots to fly from by where the Redwing stands. It also blunts the Old Pike's pressure on Eggs. Redwing flying leaves its own neighbours' Eggs at half, which is the card's tension. Unrevised for costing: by the costing agent's method an early Egg goes 1/1 to 2/2 (+2 SP each, two at most), on budget at tier 2; late, a buffed Bird's Egg doubles, which is the point and is limited to two slots.
> The homecoming version moves to variations, with costing's shared cap: "...up to +4/+4 per Bird from all your Redwings", tier 3, 2/3.

*The draft as reviewed follows; its reasoning still holds except where the revision says otherwise.*

**Card.** Birds, tier 2, 2/2.
**Text (capped).** "Fly South. When one of your Birds comes home, it has +1/+1 permanently for each fight it missed, up to +4/+4 per Bird this game."
**Golden.** "+2/+2 for each fight it missed, up to +8/+8."

Redwing has to be on your board when the Bird lands (start of turn). It doesn't grow itself on its own trips, since it's away. Two Redwings stack, each up to its own cap.

**How it plays.** A redwing is a winter thrush that comes from the north and goes back. Today a trip is pure tempo loss: the Bird is gone for two fights and leaves half of itself as an Egg. With a Redwing, a trip is an investment. The Bird comes home bigger, and because an Egg is **half the Bird's current stats**, the next trip leaves a bigger Egg too. Rotation's cost shrinks over the game. That's the measured weakness of Summer/Winter ("Loses to: early tempo", 6.11 average place).

**Interactions.**
- **Mrs Dunnock** shortens trips, so the Bird is home sooner but grows less. That's a real choice, not a stack.
- **Old Tern** flies for 3 turns, so +3/+3 per trip, and it hits the cap after two trips.
- **Mrs Stork** pulls the longest-away Bird home after it has missed at least one fight: +1/+1, or more if you wait.
- **Fly South's "When played" text** (One Swallow's gold, Chiffchaff's +1 Attack, Mrs Jay's Acorn) now comes on a body worth keeping.
- **The Seven Whistlers** count Birds, not stats. Redwing gives Summer/Winter a body to live long enough to reach them.
- **Harvest Supper's tribe bonus** already reaches Birds away. No double counting: Redwing adds permanent stats, Supper is the separate tribe layer.
- **Ghost fights** count as missed fights (you played a fight, the Bird didn't).

**Why a player runs it.** It's the mid-game spine Summer/Winter lacks. It suits a wide, spread board of medium Birds, the opposite of one pile, and that also makes it sturdy against Nightshade.

**When it's good.** Turn 7: One Swallow, Mrs Jay and Jack Daw take turns flying. Each lands +2/+2. By turn 11, five homecomings have spread about +10/+10 across the flock, and a Jay's Egg is a 2/2 instead of a 1/1.

**Variations.**
- (a) **Uncapped:** "+1/+1 for each fight it missed." Strains P5, see below.
- (b) **Attack lean:** "+2 Attack for each fight it missed, up to +8." Birds hit hard and stay brittle, so the board has a weakness to fix (P3, the owner's "lopsided boards" point).
- (c) **The Egg version:** "Your Eggs have +1/+1 for each fight their Bird has missed." It buffs the wait, not the return, and creates nothing permanent.

**Resembles.** Battlegrounds' Eternal Knight ("grows for each one that died"): a counter that turns a cost into growth. Here the cost is time away.

**Principles it might strain.** **P5**, repeatable growth on low bases. Uncapped, a 1/2 Swallow becomes 3/4 after one trip and 5/6 after two. That's the owner's own warning ("takes a 1/1 to 3/3, and adds +2/+2 every turn... your power budgeting's out the window", N-C §2). The recommended text keeps the core (trips grow the flock) with a per-Bird cap of +4/+4, so it's an A per trip with a ceiling, not a running C. **Problem 1:** it's still permanent stats, but spread across Birds that are absent a third of the time, which is the least pile-like place stats can go.

---

### 4. The Cuckoo — the Eggs beside it keep their Bird's text

> **Revised after review: the simple form is the main card.** Birds, tier 3, 2/3. "Eggs beside this have their Bird's text." Golden: "...their Bird's text and +2/+2."
> Critic B: the hatch added four new things at once (left geometry, a third Nest state, a "first of all" slot, a Ratchet edge). Costing: +15–20% at 2/4, so 2/3. Critic A liked the hatch for its planning; the simple form keeps that planning (which Nest sits beside the Cuckoo) and the payoff A valued most, a Jack Daw Egg that steals and pays. It pairs with Redwing: Redwing gives Eggs size, the Cuckoo gives them text. An Egg with Jack Daw's text steals at Egg size. The Gabble Ratchet loop (A: three bodies from one Nest) no longer exists. The hatch stays as variation (c).

*The draft as reviewed follows; its reasoning still holds except where the revision says otherwise.*

**Card.** Birds, tier 3, 2/4.
**Text.** "Start of Combat, first of all: the Egg to the left of this hatches. It fights as a copy of its Bird, as printed, with its text."
**Golden.** "...the Eggs to the left and right of this hatch."

**How it plays.** The owner's "copy the unit to my left" example (N-B §8.1), in Bird form. A cuckoo lays in another bird's nest. Eggs are textless today. A hatched Egg gets its Bird's printed card back, text included, for one fight. The real Bird still comes home on schedule, and the copy is gone after the fight.

**Interactions.**
- **Where you sell from now matters spatially.** The Nest has to be to the Cuckoo's left. Summer/Winter's timetable ("who's home this fight") gets a map ("who's home, and next to whom").
- **Hatch or not is a real decision.** An Egg is half the Bird's current stats. A printed copy is card stats. A heavily buffed Bird's Egg can be bigger than its card. The gain is the text: Jack Daw's theft, the Drumming Woodpecker's Peck and its Attack for Birds, Tom Tit's Swoop and kill gold.
- **"First of all"** puts the hatch with Mag Pye's theft, before ordinary Start of Combat text, so a hatched Jack Daw or Mag Pye fires its own Start of Combat.
- **Mother Goose's Egg** (0/2) hatches into a printed 4/7 Goose. Her strike text checks "while this is away". The real Goose is away, so the Nest strikes still happen, and the copy is a body.
- **The Great Lump on a Nest:** the slot is occupied, there's no Egg, and nothing hatches.
- **The Seven Whistlers** count a hatched copy as a Bird.
- **The Gabble Ratchet:** a hatched copy that dies is "a unit on a Nest dying", so its Bird lands. That's a strong pairing, one to watch.

**Why a player runs it.** It's the second tempo fix for Summer/Winter. Redwing makes Eggs bigger over time, and the Cuckoo makes one Egg useful this fight. It's also the Passage's best use of a Nest that isn't striking.

**When it's good.** Turn 8: the Drumming Woodpecker is away from F2, and the Cuckoo stands on F3. The 2/2 Egg fights as a 2/3 Peck 2 Woodpecker, giving your Birds +1 Attack whenever it attacks.

**Variations.**
- (a) **Simpler, no copy:** "Eggs beside this have their Bird's text." They stay Egg-sized. One less state to read.
- (b) **Either side, tier 4:** "the Eggs beside this", with golden doing both and +2/+2.
- (c) **Counter-card hook:** the Old Pike's variation (a), the Butcher-bird, stops copies, which is the owner's "then maybe someone plays a card that counters that strategy".

**Resembles.** Hearthstone's Faceless Manipulator, aimed by position. Battlegrounds has nothing that copies by position.

**Principles it might strain.** **P1:** a third state for one slot (Nest, Egg, hatched copy). The core-keeping version is variation (a): the Egg gets the text and stays an Egg.

---

### 5. The Jelly Mould — sets again in the same shape

> **Revised after review:** Oozes, **tier 5**, 2/5. "Once a fight, when a unit in front of this dies, summon a copy of it, as printed, in your empty slot nearest it." Golden: "Twice a fight."
> Three fixes, one from each reviewer. "In front of" replaces "to the left of" (Critic B: no new selector; it uses existing geometry, and the Mould now stands protected in the back row). "Your empty slot nearest it" is the Peat King's existing wording and moves the copy off the Ring (Critic A's Nan Toadstool scenario: a printed 2/1 back on a +12/+12 Ring). The dead unit's own slot is excluded by "nearest it": the copy goes beside, and keeping a gap becomes the cost. Tier 5 (costing: +35–40% at tier 4, inside the copy band at tier 5). Cradle Fetch: the copy is the printed Fetch, which becomes a copy again at the next Start of Combat only (no Start of Combat mid-fight), so it fights as a 1/1.
> This drops the owner's literal "to the left" wording. The core, rebirth by position, stays. If the owner wants the left-hand version tried, it's variation (a) in reverse.

*The draft as reviewed follows; its reasoning still holds except where the revision says otherwise.*

**Card.** Oozes, tier 4, 2/5.
**Text.** "Once a fight, when the unit to the left of this dies, it sets again: summon a copy of it, as printed, in its slot."
**Golden.** "Twice a fight."

**How it plays.** A jelly mould takes the shape of what was in it. Oozes are the tribe whose units come back out (Belly, Bubble and Squeak), and the Mould extends that to rebirth by position. It's the owner's example: "summon a copy of the unit to my left, so that unit needn't survive" (N-B §8.1).

**Interactions.**
- **Printed only.** A stat pile's copy is just its card. The Mould rewards strong printed text (The Peat King, Hasty Pudding, Old Brock) over piles, which pushes away from problem 1.
- **Rings stay on slots, so the copy lands on the Ring and gets its stats.** That's the strongest line (a ringed slot that dies twice), and why the Farrier is its natural answer.
- **Belly:** a copy of an Ooze has an empty Belly. The original's contents come out as usual, last in first. Order: the copy takes the slot first, then released units go to the nearest gaps.
- **Death text fires twice:** Mrs Posset deals 3 again, Hoglet Mother gives another Hoglet, Earwig Mother more Nymphs. These are the cheap fun lines.
- **Damage (rulebook v0.5):** a copy is a summon, not a starting unit, so it never inflates performance damage. That's the owner's Recurring Nightmare worry (N-A §4.5), avoided by the rule already chosen.
- **Counters:**
  1. Kill the Mould first: 5 Health, standing in the same row as its partner.
  2. The Barn Owl, if it's in the back row.
  3. The Old Pike, if its Health is lowest.
  4. Hasty Pudding swallows the left unit, so it never dies.
  5. Changeling borrows it.
  6. The Butcher-bird variation stops the copy outright.

**Why a player runs it.** Oozes: a sticky front line with the Peat King or Granny Stir-Up. Others: any key printed unit you want to fight twice. It's tribe-tagged, so it's offered in Ooze lobbies, but it works for anyone, as Belly does.

**When it's good.** The Peat King (5/9, Mire, makes Peatlings) on F2, the Mould on F3. When the King falls, a fresh King re-Mires and keeps summoning.

**Variations.**
- (a) **Behind instead of left:** "when the unit in front of this dies". It uses existing geometry, so there's no new selector.
- (b) **With half its permanent buffs:** a stronger, pile-friendly version. Not recommended.
- (c) **Copy ignores Rings:** "summon a copy... It has no Ring this fight." It removes the strongest pairing, at the cost of more text.

**Resembles.** Battlegrounds' Reborn, placed by position. Hearthstone's resurrect effects.

**Principles it might strain.** **P3** with a Ring: a ringed carry that dies twice is a sticky pile with only a few answers. The core-keeping version, if measured too strong, is variation (c). **P1:** summon-placement order with Belly. That's one more rule, but players already learn Belly's release order.

---

### 6. The Old Pike — takes the weakest

> **Revised after review:** neutral, tier 3, 3/3. "Never takes quarry. Attacks the enemy with the lowest Health, wherever it stands." Golden 6/6.
> "Never takes quarry" as for the Owl (Critic A). Variation (c) is replaced by **"spares Eggs"** ("...lowest Health, other than an Egg"), since textless also covers Kits and Wisps, the Pike's best targets (A). Critic A's carrier worry (a 20/20 Pike that only ever hits tokens) is real; the core-keeping fallback is "If this has 10 or more Attack, it attacks normally". Not added to the main text, because Critic B rated the one-line card the cheapest read in the round, and a pile Pike still walks into Mire locks.

*The draft as reviewed follows; its reasoning still holds except where the revision says otherwise.*

**Card.** Neutral, tier 3, 3/3.
**Text.** "Attacks the enemy with the lowest Health, wherever it stands."
**Golden.** 6/6, same text.

**How it plays.** The pike in the mere takes whatever's weakest. This is the owner's "attacks on the lowest-Health unit" example (N-B §8.1).

**Interactions.**
- **Targeting precedence** already exists (`engine.md`: Mire lock, then quarry, then own targeting text, then protected-row random). A Mire unit across the Pike overrides it. Bog folk have a built-in answer, and that's a real positional counter.
- **Tokens and summons:** Kits, Hoglets, Shrewlets, Wisps, Drips, Nymphs and Peatlings go first. It's an answer to wide summon boards, and it lowers how many units survive.
- **Eggs:** Birds' Eggs are often the lowest Health on a board, so the Pike eats Eggs. That's pressure on Birds, the weakest route, and the Cuckoo and Redwing ease it.
- **Defender bait:** a Garden Snail (1/3, Shell 4) or a Pill Bug becomes a lightning rod. Hunker units (Sett Warden) take half.
- **Fragile back-row engines** (Hedge Witch, Cradle Fetch, Lamp Moth, the Jelly Mould) aren't safe behind a wall.

**Why a player runs it.** Any tribe facing a wide or token board, or fragile engines. It's also a tactical answer to the copy effects above.

**When it's good.** The opponent runs Hedgerow Spill: Mrs Sorrel's Shrewlets and Burdock's Kits. Each Pike attack removes a 1/1 without the Pike taking real damage, so the Beadle's Pass triggers starve.

**Variations.**
- (a) **The Butcher-bird:** "...Units this kills can't be copied or summoned back this fight." The shrike pins its prey on thorns, which suits a game called Bramble. It's the hard counter to the Mould, the Cuckoo and the Gabble Ratchet.
- (b) **Lowest Attack:** "Attacks the enemy with the lowest Attack." This is Zapp Slywick, and it's safer for the Pike, since it rarely takes a big hit.
- (c) **Spares the textless:** "the enemy with the lowest Health that has rules text". It leaves Eggs and vanilla bodies alone and hunts engines.

**Resembles.** Battlegrounds' Zapp Slywick, which attacks the lowest-Attack enemy.

**Principles it might strain.** **Problem 2 and P3:** it pressures Eggs, so it pressures the weakest Bird route. The core-keeping version is variation (c), which spares textless units and still hunts the weak engine. No P1 strain: one line, already a familiar idea.

---

### 7. The Pedlar — brings copies of what you own

> **Revised after review:** neutral, tier 2, 2/3. "Start of your turn: one shop slot shows a pool copy of a random other unit on your board, tier 4 or lower. 3 times in all." Golden: "two slots... 6 times in all."
> Critic A's scenario (three pairs on board, a triple 6 turns in 7) and costing's late-game worry (a tier 2 body copying tier 6 units, or itself into a golden Pedlar) both point to bounds. "Other" stops self-copies, "tier 4 or lower" stops late triples of chase units, and "3 times in all" (the Sixpenny Pie's and Sleeping Partner's existing bound) makes it a limited early fork, as P4 wants. The shop slot shows a Pedlar badge (Critic B).

*The draft as reviewed follows; its reasoning still holds except where the revision says otherwise.*

**Card.** Neutral, tier 2, 2/3.
**Text.** "Start of your turn: one slot in your shop shows a pool copy of a random unit on your board, of your tier or lower."
**Golden.** "Two slots."

**How it plays.** It covers the owner's economy kind "random copies of units you already have" (N-B §7.4). The bounds:
- one slot a turn, and it replaces a random offer, so the shop doesn't grow;
- it still costs full price;
- it draws from the pool, so a sold-out unit can't appear;
- it's random among your board, not chosen.

**Interactions.**
- **Triples:** the obvious use. It's a third Wick a third of the time with three units on board, and the Triple Reward follows.
- **Figgy Duff** (two Bought copies make a golden), **Mistress Russet** (a pool copy of fallen quarry) and **Dishwater Nell** (shop upgrades) all build the same "shop knows your board" habit.
- **Birds away** aren't on the board, so they don't count. **Created units** (Cut-and-Come copies) aren't in the pool, so they're skipped.
- **Freeze** keeps the Pedlar's offer. **Market Day** makes it cost 2.

**Why a player runs it.** P3 says "refreshing for one exact unit, where hitting wins and missing loses" is very uninteresting. The Pedlar makes a second copy of your key piece findable without guaranteeing it. It's also an early-fork engine (P4): a turn-3 Pedlar points you at whatever you already hold.

**When it's good.** Turn 5, holding two Wicks and Little Nip. The Pedlar shows a Wick one turn in three, so the triple arrives without rolling.

**Variations.**
- (a) **Aimed:** "a pool copy of the unit to the right of this". It's positional and deterministic, so you choose what it fetches by where you put it.
- (b) **Delayed:** "Every 2nd start of your turn: two slots show copies."
- (c) **Tribe-weighted:** "a pool unit sharing a tribe with a random unit on your board". This is the owner's "weighted refreshes" kind, finding the tribe and not the exact card.

**Resembles.** TFT's reroll comps, where owned units come back. No Battlegrounds minion seeds the shop like this.

**Principles it might strain.** **P2:** more reliable exact copies can make a solved comp reachable earlier, and early solved is "a very big problem". The core-keeping version is variation (c): the shop leans toward your tribe without handing you the exact piece. **P4:** none, since it's bounded by one slot a turn and full price.

---

### 8. Market Stall — buy a bigger shop

> **Revised after review:** spell, offered from **tier 4**, costs **4**. "For the rest of the game, your shop shows 1 more unit, of your tier. At most 2 Stalls." After you hold 2, it stops being offered to you. The 7-unit ceiling moves to the rulebook.
> Costing put it +25–50% over if bought early: cost 4, from tier 4. Critic B: "of your tier" means the extra slot is never one players learn to skip, which turns P1's negative example around. Critic A: a third Stall would be a dead card in the shop, so it stops appearing. A also said it's automatic after the first and can't soak up a 56-gold bank. The first is the price of a permanent upgrade, and buying the second is a real "how long will I live" call at 4 gold. The second is fair: it's a mid-game redirect from piles, not a late bank sink. Section 3's Last Orders and Beltane caps cover the bank. For Pipkin (already at 7), the Stall gives a spell slot instead (A, variation b). New watch item from costing: Stall with Stone Soup, which buffs every shop unit per Belly buy.

*The draft as reviewed follows; its reasoning still holds except where the revision says otherwise.*

**Card.** Spell, offered from tier 3, costs 3.
**Text.** "For the rest of the game, your shop shows 1 more unit. Up to 2 more from Stalls. A shop never shows more than 7 units."


**How it plays.** The owner's own idea: "maybe adding more shop slots could be an upgrade path the player invests in... not linked to levelling" (N-A §5.3). It's delayed economy: nothing now, and every later shop is better.

**Interactions.**
- **Late surplus.** Today, late gold with nothing to buy goes into Stand Behind Me, Last Orders and the Burner, the pile itself (`engines-design.md`: bots spend on Stand Behind Me; humans banked up to 56). A Stall turns that gold into more choice, which means more tier 5–6 offers and more triples, so players replace cheap carriers instead of feeding them. That goes at the cause the engines study found ("nobody upgrades a carrier").
- **Pipkin** (+2 shop cards, 2 buys) reaches the 7-unit cap faster. It's a natural pairing, and the cap matters most here.
- **Hungry Gap** (one fewer next turn) still works: a Stall shop shows one fewer for that turn.
- **Scout:** the shop shrinks beside the Scout row and scrolls when crowded (build 4's fix), so 7 units still fit on a phone.
- **Under rulebook v0.5** (a fixed 5-card shop), a Stall takes 5 to 6, and two take it to 7, the owner's stated upper limit (N-A §5.2 amendment).

**Why a player runs it.** It's the economy player's late sink, and a midgame bet: 3 gold now for a better shop on every later turn. The longer the game, the more it pays, so it's a decision about how long you expect to live.

**When it's good.** Round 9, 14 gold, nothing in the shop for your board. Today that's a Last Orders. With a Stall, it's two Stalls and a shop of 7 from then on.

**Variations.**
- (a) **Hire a Stall:** "Your next 3 shops show 2 more units." It's temporary, so it can't pile up.
- (b) **Spell stall:** "Your shop shows 1 more spell." The menagerie-style spell economy the owner likes (N-B §4.1).
- (c) **A hero:** "Power (3 gold): your shop shows 1 more unit for the rest of the game, up to 3." This makes shop size a whole hero's identity.

**Resembles.** Nothing directly. Battlegrounds adds slots with tavern tier, and the owner's complaint about TFT is that board space and shop odds are bundled together (N-A §5.7). This is the unbundled upgrade.

**Principles it might strain.**
- **P9:** 8 or more shown is "definitely too many", so the cap at 7 is in the card.
- **P1:** a bigger shop is more to read, which is the late-shop clutter the owner dislikes (N-B §5). The core-keeping alternative is variation (b), more spells instead of more units.
- **P2:** more units seen means exact hits are easier. It's bounded by the +2 cap.

---

## 3. Existing cards that strain a principle: notes beside them, originals unchanged

Per the owner's rule, **none of these is a change**. Each note names the principle and gives a variation that keeps the card's core, ready to try **alongside** the original if a playtest wants it. Cards not listed don't strain a principle as far as this pass can tell.

### P4: bounded engines, and surplus shouldn't let one strategy play every tribe best

| Card | Strain | Variation that keeps the core |
|---|---|---|
| **Charcoal Burner** (T4 neutral) | Repeatable gold into permanent stats, every turn, for any tribe. The cap is per turn (6 burned), never per game, so a long game keeps converting. This is problem 4. | **Burner, kindled:** "...Units behind this gain +1/+1 per 2 burned, up to +8/+8 each from Burners this game." It keeps the bank-or-buy choice and adds a game-level bound. Costing: about three turns of full burning, and a fresh unit behind resets it, which rewards upgrading carriers. Critic B calls the per-unit count hidden state, so it needs a pip like Dozey's. **Or, tribe lean** (no counter): "+1/+1 per 2 burned if they share a tribe with each other, else +1 Attack." |
| **Queen of Elfland** (T6 Fairy) | Turns cheap bodies, and the Ring under them (DECISIONS 596), into permanent stats every 3rd turn. It concentrates power with no end. | **Queen, printed tithe:** "...Split their printed Attack and Health evenly among your other Fairies." No permanent buffs and no Ring stats pass on. The tithe stays, and the laundering goes. |
| **Last Orders** (T5 spell), **Beltane Bonfire** (T6 spell) | Flat gold-into-stats sinks with no ceiling. Late surplus from any economy becomes a pile: a 56-gold bank makes Beltane +14/+14 on a row, about 110 stats (costing). | **Last Orders, last round:** "...+1/+1 for every 2 spent, up to +8/+8." It binds only past 16 gold, so normal turns are untouched. **Beltane, banked fire:** "...+1/+1 for every 4 spent, up to +6/+6." Both still spend everything. |
| **Old Mother Mast** (T6), **Dame Farthing** (hero) | Economy that pays for more economy. This is the inflection the owner flagged (N-C §4). | **Mast, lean years:** "After your first unit buy each turn: get an Acorn. While you hold a Hoard, get nothing." **Farthing:** keep her cap of 5, and note her as the hero to watch on the stats-per-turn curve. |

### P5: flexible pieces; repeatable C on a low base is the danger

| Card | Strain | Variation that keeps the core |
|---|---|---|
| **Rings** (Nan Toadstool, Sally Spore, Spore Cloud, Boundary Stone) | Rings stack on one slot without limit. That's repeatable A on a fixed point, the largest source of the biggest unit's stats at round 15 (27%), and problem 1. | **Fairy ring, full circle:** "A slot's Rings stop growing at +12/+12", the wording Alderman Dozey already uses. Fairy Monarch's extra counts inside the cap. That's four Boundary Stones, so it bounds without neutering (costing). The **fading** version ("a Ring with no Fairy on it loses 1/1 each End of Turn") was dropped after review: hidden state (B), and it punishes neutral users hardest (costing). Horseshoe and the Farrier (pitch 1) are the counterplay that edits nothing. |
| **Fairy Monarch** (T6 Fairy) | A C on +1/+1 Rings: the first Monarch doubles every small Ring. That's the owner's Blood Gem case (N-B §7.2). | **Monarch, half again:** "Rings under your Fairies give half again, rounded up." It scales with Ring size instead of doubling the smallest. Or lean it: "+1 Attack more". |
| **Still-Water Heron** (T2 Bird) | Fast and Feast give +2/+2 permanently, repeatable all game on a 2/2 base. | **Heron, sated:** "...gain +2/+2 permanently, up to +8/+8." |
| **Tiddy Mun** (T5 Bog), **Grizel** (T5 Hunter) | Permanent growth from fight events, uncapped across a game, though slow. | **Cap it per game:** "+6/+6 in all" (Tiddy Mun), "+6 Attack in all" (Grizel). Small strains, noted for the watch list. |
| **Cut-and-Come-Again** (T6 Ooze) | A stream of plain copies every other turn, all game (Critic A). Created copies sell for 0, which bounds the gold but not the bodies. | Watch list. If it runs long: "...3 times in all", the Sixpenny Pie's bound. |
| **Old Tern with Mrs Stork** (T3, T4 Birds) | A repeatable Discover engine: Stork pulls the Tern home, it Discovers, it flies again (Critic A). Bounded by Stork's 6-gold trigger. | Watch list. If it runs long: "Old Tern: ...Discover a unit of your tier, 3 times in all." |
| **Stand Behind Me** (T3 spell), **Bread from the Back** (T2 spell) | Generic neutral permanent buffs, 21% of round-10 stats for Stand Behind Me. They do a tribe's scaling job for everyone. Bread was added after Critic A. | **Kin only:** "...gain +2/+2 permanently if they share its tribe, else +1 Attack" (Bread: "else +1 Health"). The tribe half is kept, and the generic half leans. |

### P2: avoid dead steps (thresholds where 6 gives nothing and 7 gives a lot)

| Card | Strain | Variation that keeps the core |
|---|---|---|
| **The Standing Committee** (T5 Hedgerow) | "If all 7 touch, +3": a cliff from 6 to 7. | **Committee, quorum:** "Touching units get +1 Attack, +1 more for every 3 touching." |
| **Rainbow Chaser** (T1 Fairy) | "5 more for all seven": the sixth band is worth 1, the seventh worth 6. | **Chaser, graded:** "1 gold per band, 2 per band from the fifth." |
| **Hiring Fair** (T5 spell) | "If 5 or more share a tribe": nothing at 4, a guarantee at 5. | **Fair, weighted:** "For each 2 units on your board sharing a tribe, one more of the three may be of it." |

**Consistency (costing):** where a cap is used, +8/+8 for a single source and +12/+12 per unit or slot, matching Dozey's printed +12/+12.

### P1: depth without complexity (text that may cost more reading than it adds)

| Card | Strain | Shorter variation |
|---|---|---|
| **Dishwater Nell** (T2 Ooze) | Three conditions: lowest-tier swap, a 2-tier gap with an Ooze touching, only the first Nell pays. | "Start of your turn: swap the lowest-tier unit in your shop for one of your tier." The gold half goes, and with it the card's only Ooze lean (Critic B). That's a real loss, so this is a variation to try, not a preference. |
| **Hasty Pudding** (T5 Ooze) | Three ways the swallowed unit returns. | "...It goes back to its side when this dies, or when its side has nobody else." The second clause stays: without it a fight may never end (Critic A). The 3-deaths clause is the one to drop, at some cost to counterplay (Critic B would keep it instead). |
| **Jack Daw** (T3 Bird) | Quarter of gains, capped, plus a gold condition. | "Start of Combat: take up to +3/+3 of the enemy across's bonus stats. If you took any, get 1 gold next turn." (Critic B's wording.) **This is a power change, not just a shorter text** (Critic A): flat up-to-3 is stronger early than a quarter. Try it as a variation only. |
| **Pipistrelle Echo** (T5 neutral) | A rules exception printed on the card ("Repeats spend no gold..."). | "Spells you aim at this also hit the units beside it, except spells that spend gold." |
| **Belladonna Sprite** (T5 and T6 Fairies) | Two cards share one name with different texts (Critic A). A reading hazard, not a design strain. | Rename one, e.g. the T6 "Deadly Nightshade". |
| **Mag Pye** (T4 Bird) | "A Belly stays" is an edge rule on the card. | "Start of Combat, first of all: steal the text of the enemy across for this fight." "Steal" keeps the enemy losing its text, the card's core. The Belly rule moves to the Belly reminder (Critic B). |

---

## 4. What the critics and costing said (summary)

Full reports are in `design5-critics.md`. Three fresh agents reviewed the draft independently, none seeing the others: Critic A on strategy depth, Critic B on simplicity and newcomers, and the costing agent, which was the only one to read `docs/design/power-budget.md`.

| Idea | Critic A (strategy) | Critic B (simplicity) | Costing | Outcome |
|---|---|---|---|---|
| Farrier | Change: a dead slot most rounds, so lead with the Horseshoe spell | Keep, shorter text | On to +10–30% | Horseshoe leads; the unit is kept |
| Barn Owl | Keep; add "never takes quarry" | Keep, shorter text | +10–20%, keep | Revised wording, recommended |
| Redwing | Change: fix tempo, not stats | Simplify: hidden cap | **Over +60–100%** | Rewritten as full-size Eggs beside it |
| Cuckoo | Keep (in top 4) | Cut to the simple form | +15–20%, so 2/3 | Simple form is the main card |
| Jelly Mould | Change: the Ring pile dies twice | Use "in front of" | **Over +35–70%** | Tier 5, in front, nearest gap |
| Old Pike | Change: quarry hole, pile carrier | Keep (top pick) | On | "Never takes quarry"; spares Eggs as a variation |
| Pedlar | Change: triples 6 turns in 7 | Keep, badge | Over late | Other unit, tier 4 or lower, 3 times in all |
| Market Stall | Cut to a variation | Simplify: own tier | **Over +25–50%** | Cost 4 from tier 4, own tier, 2 at most |

**Where they agreed:**
- Cold Iron and the Barn Owl are worth building.
- Redwing as drafted wasn't.
- The Mould needed taking off the Ring.

**Where they split, and the call made:**
- **The Cuckoo** (A keep, B simplify): the simple form, because it keeps the planning A valued at B's reading cost.
- **Market Stall** (A cut, B top 4): kept and revised, because it's the only recommended item for problem 5 and the owner proposed it.
- **The Pike as a carrier** (A worried, B wanted it plain): plain text plus a written fallback.

**Section 3 corrections taken:**
- Jack Daw's short text is labelled a power change.
- Hasty Pudding keeps its fight-ending clause.
- Mag Pye keeps "first of all" and "steal".
- Nell's variation is marked as losing its Ooze lean.
- The Ring fade variant is dropped for the cap.
- Added: a Beltane cap, a Bread from the Back note, Cut-and-Come-Again and Old Tern with Mrs Stork on the watch list, and the duplicate Belladonna name.

## 5. Revision log and recommendation reasons

**One revision pass.** Every change is in the "Revised after review" block at the top of each pitch and in the section 3 tables. The draft text below each block is kept as the record of what was reviewed (the pre-review commit is on this branch).

**How the four were chosen.** The brief asks for the items that most help the open problems. So the test was coverage first, then reviewer agreement, then budget.
- **Coverage:** every problem has at least one recommended item. Problem 1: Horseshoe and the Stall. Problem 2: Redwing. Problem 3: the Owl, Horseshoe and Redwing. Problem 4: Horseshoe and the Owl. Problem 5: the Stall.
- **Agreement:** Horseshoe and the Owl were in both critics' top 4, and costing passed both.
- **Redwing** is in because nothing else targets problem 2, and its revised text is Critic A's own suggestion, which also clears the costing and hidden-state objections.
- **The Stall** beat the Pike and the Mould for the fourth place on coverage. Problem 3 is already served twice, and problem 5 otherwise has nothing.

**What the owner should know.**
- The revised Jelly Mould no longer uses the owner's literal "unit to my left" wording. It uses existing geometry ("in front of") to avoid a new selector. The core, rebirth by position, is kept, and the left-hand version is one word away if the owner wants it tried.
- None of the revised texts has been through a second costing. Redwing's revised value is the designer's estimate by the costing agent's method.
- Nothing has been simulated or played.
- No existing card has been changed. Section 3 is notes only.
