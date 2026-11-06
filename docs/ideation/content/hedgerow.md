# Hedgerow folk

Many small hands that hoard. A parish council in permanent session: everyone holds an office, nobody is in charge, and there is a great deal in the cupboard.

**The tribe in one paragraph.** Hedgerow folk pass things along a line of hands and put things by for later. Summons that don't fit become Acorns. Three Acorns become a Stash, worth 5 rather than 3, and holding that wealth is often better than spending it, because other cards read it, eat it or throw it. Every turn asks: cash this now, or keep it? Fill the gap for more Acorns, or leave it so the Line ends on the unit you want?

**Design note.** 16 units, tiers 5/4/3/2/1/1, no plain stat lines. Costing is a later reviewer's job: the stats and gold numbers here were set by feel.

---

## The keywords

Reminder text is what the card's tap-through shows. Exact rules follow it.

### Acorn, Stash, Great Hoard (hand items)

*Reminder: Play for gold: Acorn 1, Stash 5, Great Hoard 20. Three of a size combine into the next size.*

- All three are hand items with `pool: false`, no cost and no aim. Playing one gains its gold. They aren't spells, so they don't fire "cast a spell" effects.
- As soon as you hold 3 Acorns they combine into a Stash, and 3 Stashes into a Great Hoard. This happens at once and can't be declined. So the choice is made earlier: cash the second Acorn, or wait for the third.
- They take up hand space (limit 10). A new Acorn that would complete a three still arrives on a full hand. Otherwise it is lost.
- Combat can grant them; they arrive after the fight and combine then.

### Larder

*Reminder: what the Acorn items in your hand are worth in gold.*

- Acorn 1, Stash 5, Great Hoard 20. Two Acorns are a Larder of 2; the third makes it 5, a visible jump.

### Spill

*Reminder: if a summon from this has no room, get an Acorn instead.*

- One Acorn per unit that fails to arrive, in either phase. It replaces the lost summon of rule 8.4.5.
- A summon naming a slot ("behind this") fails if the named slots are full (8.4.6). **A back-row unit has nothing behind it, so "summon behind this" always Spills there.** That is the point: the same card makes bodies in the front row and money in the back.

### The Line

*Reminder: your board's zigzag, F1-B1-F2-B2-F3-B3-F4. A gap cuts it.*

- A unit's Line is the unbroken run of occupied slots along that zigzag that includes it. F1 and F2 are not linked unless B1 is occupied.
- No packing (8.3.4), so a death in combat cuts the Line where it stands.
- The tray draws the zigzag as a string of linked hands, lit where it is unbroken.

### Hand Along and Hand Back

*Reminder, Hand Along: give this to the last unit rightward down this unit's Line.*
*Reminder, Hand Back: the same, leftward.*

- "Rightward" is the zigzag order above. If nothing is linked on that side, the source gets it.
- The default duration applies: permanent in the Recruit Phase, this combat in combat.
- It reads the Line when it fires. A sold unit hands along from its slot before it leaves.
- On a full board, Hand Along ends at F4 and Hand Back at F1, both exposed. To feed a protected back-row carry you must cut the Line just past it. That gap costs a body, and it can cost Spill, because a gap gives summons somewhere to land.

### Snug N

*Reminder: after N of your turns ending in this slot, do this, once. Moving restarts the count.*

- Counts at End of Turn, including the turn it was played. Any recruit move or swap, by you or by an effect, restarts it. Moves in combat don't, because combat runs on a copy.
- A golden made by a triple is a new unit: its count starts over and it can fire again.
- This is the owner's "Don't move for 3 turns, then X". It costs something real on this tribe, because the rest of your cards keep wanting you to rearrange the Line.

### Eats Acorns

*Reminder: you may play Acorn items onto this instead of cashing them: Acorn +1/+1, Stash +6/+6, Great Hoard +25/+25.*

- Only units with this text can do it, so Hedgerow gold is portable to other tribes but its best use isn't. This is the owner's point about economy that is "way better for the strategy you're in".

### Bury

*Reminder: put an Acorn from hand in an empty slot. Left alone 3 turns, it returns as a Stash. A unit stepping there digs it up for +2/+2 instead.*

- The nearest empty slot is found by the 8.4.2 order from the source, skipping slots that already hold a Buried Acorn. If none is free, nothing is buried and the Acorn stays in hand. So a full board protects your Acorns from the squirrel.
- The Buried Acorn is a slot effect. It counts three of your End of Turns with no unit in the slot, then a Stash goes to hand.
- In the Recruit Phase, the first unit to enter (played, moved or summoned) gains +2/+2 permanently and the Acorn is gone.
- In combat, a summon landing there gains +2/+2 this combat and the Acorn stays (combat runs on a copy). A Buried Acorn is not a unit, so it doesn't link the Line.

### Bristle N (owner's thorns; library entry 7)

*Reminder: when an enemy deals this damage in an attack, it takes N back.*

- As in the library: the prick lands after the exchange and before deaths are checked, and thorn damage never triggers thorn damage. "Pricks" in card text means this event. Already built (`bristle`), except for the trigger.

### Hunker (owner's; library entry 1)

*Reminder: takes half damage when attacked, rounded up.*

- As in the library: only damage from being attacked. Already built (`hunker`).

### Tunnel

*Reminder: once a combat, when a unit in front of this dies, this moves into its slot.*

- A back-row mole steps up, so your front row isn't empty and the rest of the back row stays safe. The cost: its old slot is now empty, which cuts the Line.

---

## The units

Tokens: **Kit** (Rabbit, 1/1) and **Shrewlet** (Shrew, 1/1), both Hedgerow folk with no text. Kits are Created, so they sell for 0, and three of them triple as normal. That is intended and worth a look in review.

### Tier 1

**Mrs Burdock, Expecting Again**. *Rabbit Parishioner.* Tier 1, 1/2.
- Text: On play: summon a 1/1 Kit behind this. Spill.
- Golden (2/4): On play: summon two 1/1 Kits behind this. Spill.
- Row: F2 or F3 for a body. A back slot, or a front slot with its back slots full, for an Acorn.
- Why buy: you pick body or Acorn with the slot you play her in.

**Mr Crumb**. *Church Mouse Sidesman.* Tier 1, 1/2.
- Text: On play and when sold: Hand Along +1/+1.
- Golden (2/4): On play and when sold: Hand Along +2/+2.
- Row: anywhere left of the unit you want fed.
- Why buy: two aimed buffs for one mouse, and you do the aiming with slots.

**The Sleeping Partner**. *Dormouse Investor.* Tier 1, 1/3.
- Text: Snug 3: get a Stash.
- Golden (2/6): Snug 3: get two Stashes.
- Row: back, in a slot you can leave alone for three turns.
- Why buy: a turn-1 investment that pays on turn 3, if you keep your hands off it.

**Miss Prickett**. *Hedgehog Verger.* Tier 1, 1/3.
- Text: Bristle 1. After this pricks, units behind this gain +1 Attack this combat.
- Golden (2/6): Bristle 2. After this pricks, units behind this gain +2 Attack this combat.
- Row: F2 or F3 (two units behind). F1 or F4 only feeds one, so you aim all of it at one carry.
- Why buy: swarms feed your back row by attacking her.

**Choirboy Tobias**. *Shrew Choirboy.* Tier 1, 2/1.
- Text: Start of Combat: deal 1 to the enemy across from this; 3 if you hold a Stash.
- Golden (4/2): Start of Combat: deal 2 to the enemy across from this; 6 if you hold a Stash.
- Row: whichever slot faces the next opponent's weak unit. It misses if that slot is empty.
- Why buy: an early aimed ping, and a reason to hold a Stash through a fight.

### Tier 2

**Mrs Sorrel, Harassed**. *Shrew Mother.* Tier 2, 2/3.
- Text: After this attacks, summon a 1/1 Shrewlet behind this. Spill.
- Golden (4/6): After this attacks, summon two 1/1 Shrewlets behind this. Spill.
- Row: front for bodies in the fight. Back for an Acorn per attack, if she lives to attack.
- Why buy: the tribe's main Acorn source in combat, and where to put her is a real question.

**Mr Pym**. *Vole, Clerk to the Council.* Tier 2, 2/3.
- Text: Whenever you get a Stash or Great Hoard: Hand Back +2/+2.
- Golden (4/6): Whenever you get a Stash or Great Hoard: Hand Back +4/+4.
- Row: to the right of the unit you want fed. It feeds the left end of its Line, the opposite of most feeders.
- Why buy: forming a Stash pays once as stats, and you still have the Stash.

**The Absent Almoner**. *Red Squirrel.* Tier 2, 2/2.
- Text: End of Turn: Bury an Acorn from hand.
- Golden (4/4): End of Turn: Bury two Acorns from hand.
- Row: next to the gap you want to plant in; the 8.4.2 order decides which gap.
- Why buy: one Acorn becomes a Stash if you can afford an empty slot for three turns.

**Old Delver**. *Mole Sexton.* Tier 2, 2/5.
- Text: Hunker. Tunnel.
- Golden (4/10): Hunker. Tunnel.
- Row: back to Tunnel, front to wall. Behind the unit most likely to die first.
- Why buy: a wall that can also hold up your front row after it breaks.

### Tier 3

**Alderman Dozey**. *Dormouse Alderman.* Tier 3, 2/5.
- Text: Eats Acorns. Snug 3: double this unit's Attack and Health.
- Golden (4/10): Eats Acorns, twice the stats. Snug 3: double this unit's Attack and Health.
- Row: back, at an end of a Line, chosen once and then left alone.
- Why buy: the tall carry. Feed him before he wakes and every bite counts twice.

**Sergeant-at-Conkers**. *Shrew Sergeant.* Tier 3, 3/3.
- Text: Start of Combat: throw your smallest Acorn item at the enemy across from this: 3 damage per gold it's worth.
- Golden (6/6): Start of Combat: throw your smallest Acorn item at the enemy across from this: 6 damage per gold it's worth.
- Row: facing the opponent's carry, usually the back row. If that slot is empty, he keeps his ammunition.
- Why buy: a Stash deals 15 to one chosen slot. Cash your loose Acorns first if you want him to throw the big one.

**Dr Urchin**. *Hedgehog Apothecary.* Tier 3, 2/6.
- Text: Bristle 2. After any of your units pricks: Hand Along +1 Attack this combat.
- Golden (4/12): Bristle 4. After any of your units pricks: Hand Along +2 Attack this combat.
- Row: front, left of your carry and linked to it.
- Why buy: every attack the enemy makes into your wall sharpens the unit at the end of his Line.

### Tier 4

**The Honorary Treasurer**. *Bank Vole.* Tier 4, 3/6.
- Text: Has +1/+1 for each gold in your Larder.
- Golden (6/12): Has +2/+2 for each gold in your Larder.
- Row: back. She is your money, so protect her.
- Why buy: your unspent wealth fights for you, until you spend it, and then she shrinks. Every purchase now has a second price.

**Beadle Warrenby**. *Rabbit Beadle.* Tier 4, 3/5.
- Text: All your summons Spill. After a Spill: Hand Along +1/+1.
- Golden (6/10): All your summons Spill. After a Spill: Hand Along +2/+2.
- Row: left half of the Line, with units linked past him, so the buff still lands after losses.
- Why buy: turns any summoner on any tribe's full board into Acorns and stats.

### Tier 5

**The Standing Committee**. *Several Mice in One Coat.* Tier 5, 4/7.
- Text: Start of Combat: give each unit in this Line +1 Attack for each unit in it.
- Golden (8/14): Start of Combat: give each unit in this Line +2 Attack for each unit in it.
- Row: anywhere on an unbroken Line. B2 is safest. Each gap shortens the Line, so every unit in it loses Attack too.
- Why buy: the wide finisher. A full board gets +7 Attack on every unit, and it punishes you for the gaps your other cards want.

### Tier 6

**Old Mother Mast**. *Red Squirrel, Keeper of the Great Hoard.* Tier 6, 5/9.
- Text: Start of your turn: get an Acorn for each Stash you hold. A Great Hoard counts as three.
- Golden (10/18): Start of your turn: get two Acorns for each Stash you hold. A Great Hoard counts as three.
- Row: F4 in a wide board, the end of Hand Along. Otherwise any safe slot.
- Why buy: this breaks rule 4.1.3, "holding gold earns nothing". Your hoard now earns interest, if you can bear not to spend it.

---

## Where the slot is the decision

| Card | What changes by slot |
|---|---|
| Mrs Burdock | Front with room: a Kit. Back: an Acorn. |
| Mrs Sorrel | Front: Shrewlets fill the back as it empties. Back: Acorns only, and only if she lives to attack. |
| Miss Prickett | F2 or F3 splits the Attack across two carries. F1 or F4 sends it all to one. |
| Mr Crumb, Dr Urchin, Beadle | The feed lands on the right end of their Line. Where you cut the Line picks the carry. |
| Mr Pym | The same, but leftward. With a right-hand feeder and him, one Line feeds two carries, one at each end. |
| Choirboy Tobias, Sergeant-at-Conkers | The slot aims the shot, so the answer changes with the next opponent's board. Back slots face back slots. |
| The Absent Almoner | Her slot picks which gap she plants in, and a full board stops her. |
| Old Delver | He only Tunnels from the back. He tunnels where the front is likeliest to fall, and doing so cuts the Line at his old slot. |
| The Standing Committee | Punishes each gap. Direct conflict with Hand Along's gap and Bury's gaps. |
| Snug units | The slot is a commitment. Rearranging for this turn's opponent resets the sleeper. |

**A real decision each turn.** Cash the Acorns or wait for the Stash. Cash the Stash or feed it to the Alderman, leave it for the Treasurer's stats, or leave it for the Sergeant to throw. Fill the gap with this buy, or leave it to mature. Move the carry to face this opponent, or keep the Snug count.

---

## The builds

### 1. The Full Parish (wide and hoard)

```
F1 Mrs Sorrel      F2 Beadle Warrenby     F3 Mrs Sorrel (golden)   F4 Old Mother Mast
     B1 Mrs Sorrel       B2 Standing Committee    B3 Mr Crumb
```

- **Turn 1-3.** Mrs Burdock in F2 with a Kit behind. Add Mr Crumb and anything cheap. Fill slots rather than saving; you want a full board soon.
- **Turn 4-6.** Tier 2 to 3. Mrs Sorrel takes the front, with a second in the back once the board is nearly full. Acorns start after fights. Decide each turn whether to hold for the Stash. Usually hold, because Acorns come in steadily here.
- **Turn 7-9.** Beadle Warrenby at the left of the Line. Every Spill now also feeds F4. Late on, sell Mr Crumb from B3 (+1/+1 to F4) and play Mrs Burdock there: no room behind a back slot, so an Acorn and another +1/+1. Cash Stashes for tier-ups and triples.
- **Turn 10+.** The Standing Committee gives +7 Attack to all seven at Start of Combat. Old Mother Mast's interest pays for rolling.
- **Wins by.** Trading all the way down with a board of medium units while out-earning the lobby.
- **Loses to.** Damage that cuts the Line early (a dead F2 or F3 strands the feed), tall carries with cleave, and anything that keeps the board non-full in the first hits, since then the Mothers summon Shrewlets rather than Acorns. Also Bristle-type walls that punish many small attacks.

### 2. The Treasury (one or two big carries behind a wall)

```
F1 Old Delver      F2 Dr Urchin    F3 (gap)    F4 Mr Pym
     B1 Mr Crumb      B2 Honorary Treasurer     B3 Alderman Dozey
```

- The gap at F3 splits the Line. **F1-B1-F2-B2:** every Hand Along ends on the Treasurer in B2. **B3-F4:** Mr Pym's Hand Back ends on the Alderman in B3.
- **Turn 1-3.** The Sleeping Partner in a back slot, and Miss Prickett in front. Don't rearrange.
- **Turn 4-6.** The Stash comes in on turn 3 or 4. Old Delver and Dr Urchin make the wall. Mr Pym arrives. The Alderman goes in at B3, and you hold Stashes until his third turn.
- **Turn 7-9.** Eat the Stashes on the third turn, then he doubles at End of Turn. The Treasurer comes in: from now on, every Acorn you don't cash is +1/+1 on her. Every purchase is now a real trade against her stats.
- **Turn 10+.** Hold a growing Larder. On a big turn, cash it all, buy, and accept a smaller Treasurer for one fight. Triple the Alderman to wake him again.
- **Wins by.** Two carries too big to answer, with a slow wall that gives them time to attack.
- **Loses to.** Back-row reach (a dead Treasurer means your wealth stops fighting), Peck against Hunker, wide boards that outlast a thin wall, and early tempo while the sleepers do nothing. Its gold is tied up, so a bad fight on turn 6 hurts.

### 3. Forgotten Stores (gaps that pay)

```
F1 (gap, Buried)   F2 The Absent Almoner   F3 (gap, Buried)   F4 Sergeant-at-Conkers
     B1 Alderman Dozey      B2 Mr Pym         B3 Mrs Sorrel
```

- The Line is B1-F2-B2, so Mr Pym's Hand Back runs B2, F2, B1 and lands on the Alderman. B3-F4 is a separate Line. The Almoner in F2 plants in F3 first, then F1.
- **Turn 1-4.** A Sleeping Partner, and Mrs Burdock in a back slot for the first Acorn. Keep at least one gap on purpose. Survive; don't win.
- **Turn 5-7.** Mrs Sorrel in B3 brings in an Acorn when she gets to attack, and the Almoner buries one each turn. Each Buried Acorn is a choice: step a new buy onto it for +2/+2 right now, or wait for the Stash. Every Stash that arrives feeds the Alderman by Mr Pym's +2/+2, and then again when eaten.
- **Turn 8+.** The Almoner clears loose Acorns from your hand, so the Sergeant's smallest item is a Stash: 15 damage. Move him to face the opponent's carry. In a pinch, fill a gap with your best buy and take +2/+2.
- **Wins by.** A late spike nobody saw coming: a huge Alderman and a sniped enemy carry.
- **Loses to.** Fast tempo on turns 4 to 7, wide boards that run through two front units to the back row, and anyone with a Standing Committee-sized board who plays faster. Its Acorn supply is also thin: one back-row Mother and whatever Mrs Burdocks it finds. A fight where she dies early starves the plan.

---

## The 5 strongest combos

1. **Feed before you wake.** Alderman Dozey, a pile of held Stashes, and his third Snug turn. Eat on that turn, and everything is doubled at End of Turn. Tripling him afterwards restarts Snug and doubles again.
2. **Back-row Mothers and the Beadle.** Mrs Sorrel in the back row with Beadle Warrenby: each attack gives an Acorn and +1/+1 down the Line. In the Recruit Phase, Mrs Burdock played in a back slot does the same at once, then can be sold.
3. **Sergeant's Stash.** Sergeant-at-Conkers facing the next opponent's carry, with Acorns cashed so only a Stash is left: 15 damage before the first attack. Choirboy Tobias does 3 because you hold that Stash, but only if he sits earlier in reading order than the Sergeant.
4. **The Treasurer and Old Mother Mast.** Interest raises the Larder without spending anything, and each new Stash is a jump in her stats and a +2/+2 from Mr Pym.
5. **The prickly wall.** Miss Prickett in F2 and Dr Urchin in the wall, against a wide or Peck board. Every enemy attack gives +1 Attack to B1 and B2, and another +1 down the Line. Swarm boards end up paying for your carry.

---

## With other tribes

- **Fairies.** A Fairy carry at the end of a Line gets every Hand Along. Mr Crumb's on-play and on-sell buffs are permanent, so they combine with Fairies that buff by slot in the same puzzle.
- **Oozes and any tribe with summons.** Beadle Warrenby makes their overflow pay.
- **Greenwood.** Snug and Rooted both reward a settled board. Alderman Dozey fits a "don't move" plan with no extra cost.
- **Any tribe.** The Sleeping Partner and Mrs Burdock are early gold anyone can use. Spending that gold on another tribe's scaling gives up Eats, Larder and Stash triggers, which is the trade the owner asked for.

---

## Riskiest card: Old Mother Mast

**Why.** She pays interest on held wealth, and it compounds: 3 Stashes give 3 Acorns, which make a fourth Stash, so the income grows every turn with no action taken. She also feeds the Treasurer's stats and Mr Pym's triggers, and rising refresh costs only slow spending, not earning. This is the card most likely to be the owner's "economy comps tend to just be the best".

**How I'd adjust, in order.**
1. Cap it: "up to 3 Acorns a turn". This keeps the fantasy and removes the compounding.
2. Don't count a Great Hoard as three; it counts as one.
3. Tie it to a choice: "if you cashed nothing last turn". The interest is then a held breath, not a passive income.
4. Last resort: every other turn.

**Next to watch.** The Absent Almoner (1 Acorn becomes 5 gold of value with only a gap as the cost), and the Treasurer with a Great Hoard (+20/+20). Mrs Burdock's churn stays below break-even on its own: 3 gold in, 1 back from selling and one Acorn. Check that after Stash values are set.

---

## Art direction

- **Mrs Burdock:** heavily pregnant doe rabbit in a Sunday bonnet, four kits already hanging off her skirts, her expression past hope.
- **Mr Crumb:** threadbare church mouse in a shrunken black coat, holding out a brass collection plate with one crumb on it.
- **The Sleeping Partner:** dormouse asleep upright in a tiny wingback chair, top hat over eyes, ledger open on its lap.
- **Miss Prickett:** thin spinster hedgehog in a verger's gown, ring of keys, spines through the gown, pursed lips.
- **Choirboy Tobias:** shrew in a ruff and surplice, angelic face, a conker on a string behind his back.
- **Mrs Sorrel:** furious tiny shrew with a shopping basket, a train of shrewlets holding each other's tails behind her.
- **Mr Pym:** water vole at a tall desk, spectacles, minutes piling past his head, ink on one whisker.
- **The Absent Almoner:** red squirrel in almoner's robes, patting her empty pockets at the foot of an oak, acorns dropping unnoticed through a hole.
- **Old Delver:** broad mole with a sexton's spade, half out of a fresh grave-shaped molehill, velvet coat, sees nothing and is unbothered.
- **Alderman Dozey:** vast dormouse in an alderman's chain and scarlet robe, asleep at a laid table, one paw still reaching for the acorn.
- **Sergeant-at-Conkers:** shrew with a waxed moustache and a bandolier of conkers, one eye shut, aiming a catapult.
- **Dr Urchin:** hedgehog apothecary with labelled bottles spiked on his spines, offering one with a professional smile.
- **The Honorary Treasurer:** plump bank vole in pince-nez, sitting on a strongbox, one paw flat on it, watching you.
- **Beadle Warrenby:** large buck rabbit in a beadle's cocked hat and gold braid, staff raised, turning a queue of small animals away from a full doorway.
- **The Standing Committee:** a long overcoat with a mouse's head at the collar and several more at the buttonholes, all talking; the top one is holding the gavel.
- **Old Mother Mast:** ancient red squirrel, tufted ears gone white, in a hollow oak filled to the roof with acorns, knitting; she knows exactly how many.
- **Tokens and items.** Kit: rabbit kit, ears too large. Shrewlet: shrew baby gripping an unseen tail. Acorn: one acorn with a neat cap. Stash: a knotted cloth bulging with acorns. Great Hoard: a small iron-bound chest with acorns spilling from the lid.

---

## Engine features needed beyond `engine.md`

**Already there:** `bristle`, `hunker`, `add_card` from combat, `across`, `behind`, hand items, the `on_play`, `on_sell`, `start_of_combat` and `start_of_turn` triggers, and slot effects.

**New, in rough order of need:**

1. **Acorn items and auto-combine.** Three items, plus a hand rule that fires when an item is gained and combines threes, also after a fight, also on a full hand when the new one completes a three.
2. **`on_summon_failed` trigger and `spill` mechanic.** Spill is the core signature. Needs a board-wide version for Beadle Warrenby ("all your summons") and a hook for his Hand Along.
3. **Line selectors.** `line_end` with `direction: right | left`, `of: self`, and `line` (all units in this Line) for `per` and for targets. Zigzag order is fixed in one place. Reads the board at firing time, including in combat after deaths.
4. **`on_item_gained` trigger,** filtered by size, for Mr Pym.
5. **Larder.** A `per: larder` source and a `larder` condition, readable in `aura` (the Treasurer) at recruit and fight start. Choirboy Tobias's Stash check needs a `hand` condition filtered by card id.
6. **Summon into named relation.** `summon` with `target: {select: behind}` that tries each slot and fails into Spill if none is free, and always fails from the back row.
7. **`snug` mechanic.** A per-unit counter of End of Turns in the same slot, reset by `on_move` and swaps, firing once. Golden resets it. Needs a `multiply` step for Alderman Dozey's double (the effects list only has flat `buff`). Show pips on the card.
8. **`eats_acorns`.** Lets a hand item take a unit aim on units with the keyword, with size-specific stats, while its default stays aim-none gold.
9. **Bury.** Slot contents with a tick count, dig-up on entry, a combat-only version for summons, and the Stash at maturity. Slot effects are close, but they stay on the slot permanently and do nothing when empty, so maturing and being consumed are new.
10. **Spending hand items from combat.** `Sergeant-at-Conkers` reads the hand copy at fight start, picks the smallest, and spends it on the recruit side after the fight. Same return path as `add_card`, in reverse.
11. **`on_prick` trigger.** Extends `bristle`, with subject for "any of your units" (Dr Urchin).
12. **Tunnel.** A combat `move` into a named dead unit's slot (`move` is recruit-only today). Rules needed: this moves after that unit's own death summons (9.7.2), and fails if they filled the slot.

**For screens and bots, not engine rules:**

- **Next opponent's board by slot.** The rulebook shows who you face next (2.3.3). Aimed cards (Tobias, the Sergeant) are one-answer cards unless the player can also see that opponent's last board by slot. The earlier sim found the same for Acorn Slinger ("one answer in practice").
- **The tray.** Draw the zigzag, light unbroken links, and mark on the card which unit a Hand Along will land on when dragging. Show Larder as a number beside the hand, Snug pips and Buried Acorns with a count.
- **Bots.** Hard bots need a policy for cash or hold, and a placement search that knows the Line. Otherwise this tribe will look weak in the tournament for the wrong reason.
