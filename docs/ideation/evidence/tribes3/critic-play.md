# Tribes 3 critique: play and strategic depth

One independent critic, playing the three designs in my head against Hedgerow, Fairies, Oozes and Birds on turns 3, 6, 9 and 12. Nothing was simulated. No costing here; obvious runaways are flagged.

Read: `hunters.md`, `bogfolk.md`, `greatbeasts.md`; `direction-summary.md`; the four built tribes and neutrals; `playtest-1.md`, `design-review-2.md`, `position-test.md`, `engine.md`; rulebook 8.2 and 9.4-9.5; owner notes 02h and 02i.

## The headline

All three designs take one finding from the position test ("across from" is the only text above the noise floor), and all three built a tribe on that same sentence. As written they collide twice:

- **Being attacked from across, three times over.** Hunters' Bait, Bog folk's Mire and Great beasts' Big Ursula all say "the enemy across must attack this". The Hunters' Sett build is the Bog folk tribe with foxes.
- **Attacking across, twice.** Quarry ("attacks the enemy across whenever it can") and Charge ("its first attack goes at the enemy across") are the same aim. Charge is Quarry for one attack, plus trample.

The Laird of the Sett is also the `across_targeting` rule that the position test turned down: it added nothing past scouting, and search on old boards fell below the rule of thumb.

The owner's Mire musing (02h: "it makes their backline attack into you... counterattack damage") was exploring, not a request (02i). It should belong to one tribe, not three.

## Ruling: one relationship to the lane per tribe

Put this in the rulebook as 8.2.6a, the bell. Each tribe owns a different noun:

| Tribe | Owns | In one line | What the lane binds to | Glyph on screen |
|---|---|---|---|---|
| **Bog folk** | **Inbound**: the enemy across must come to you | "Who hits me" | **The ground.** A patch sits on the enemy *slot*, so whoever stands there later is Mired too. | Mud patch under their slot, reed-line to the toad |
| **Hunters** | **The quarry**: the enemy unit across at the bell is marked, followed and paid for when it faints | "Whom I chase" | **The animal.** The mark sits on the enemy *unit*. It follows that unit if it moves. A new unit in the slot isn't quarry. | Paw-print on their unit, line from the Hunter |
| **Great beasts** (on file) | **The column**: one charge through the slot across into whatever stands behind it | "What's behind them" | **The line through the slot**, read at the moment of the charge | Arrow through their slot into the back row |

**Exclusive rights.** These hold for every card in the game, including neutrals and new tribes:

- Only Bog folk make an enemy attack a chosen unit. Remove Bait from Hunters and the forced attack from Big Ursula.
- Only Hunters mark a unit to follow, and only they are paid for its death. Only Hunters make a marked enemy attackable "wherever it stands". So Jenny Greenteeth's exposure moves to Old Brock.
- Only Great beasts go through a slot into what's behind it (run through the gap, trample).
- Built tribes keep their one-shot across effects at the bell: Hex, Changeling, Belladonna, Hasty Pudding, Sergeant, Choirboy, Mag Pye, Jack Daw, Goose, Whistlers, Scarecrow. They act once and bind nothing for the fight, so they don't compete with the three relationships.

**The bell step.** This is a new first step of Start of Combat, after Mag Pye's "first of all" and before all other Start of Combat text. Both sides fix their bindings at once: patches are laid and quarries are marked. Then Start of Combat runs as usual:

- A Changeling, a Whirligig, Old Steinbock or a Hasty swallow that moves a unit leaves patches on their slots and quarries on their units.
- Charge reads its column when it attacks.

**Targeting precedence for an attack** (replaces each design's own list):

1. Mire lock.
2. The attacker's own text: quarry, Charge, Snap, Swoop, Poacher's Path.
3. Taunt.
4. Random.

So a Mired Hunter swings at the toad, and a Mired charger charges the toad. Its trample goes behind the toad on its own side. When the toad is in the back row, nobody is behind it, so the trample is lost.

**When both sides have lane text in one lane.**

- My F2 toad Mires their F2 Hunter, and that Hunter's quarry is my F2 toad: one lock, consistent, a straight duel.
- Two toads facing each other: each is locked onto the other, a duel. Bitter's floor of 1 and the fight-length cap end it.
- My back-row toad Mires their B2, and their B2 Hunter's quarry is my B2: the lock wins. The answer is the same.

**Pack and Pounce against Mire (a hole in both).** Joining isn't attacking under Hunters' rules, so a Mired wolf could escape its lock by joining.

Ruling: a Mired unit whose maker lives can join an attack only if the leader's target is that maker. A Pounce by a Mired unit can only go at its maker. Bitter answers the leader only.

**Why two lane tribes can share a lobby after this.** Against the Bog player you ask "which of my units does my opponent want to pull?" Against the Hunter you ask "which of mine is marked, and do I move it?" A unit moved off a patch is free, and a unit moved off its slot is still marked. So moving answers Bog folk and doesn't answer Hunters, and walling answers Hunters and feeds Bog folk. Those are different counterplay, which is what makes them two tribes.

---

## Bog folk: strong

**Why.**

- It's the only design whose signature does something Battlegrounds and Galaxy both lack: choosing **who does the hitting**.
- It reads the other board, and it has one picture that tells the whole tribe on a phone: a mud patch and a reed-line.
- Economy is tied to its action, and it pays win or lose.
- The bot heuristic is simple.

**Problems.**

- Its main claim is wrong as written.
- One mechanic, Kiss, is Fairies' Shy.
- Tempo on turns 3-6 is poor.

### Played through

- **Turn 3 against Hedgerow** (scout: Mrs Burdock 2/4 in F1, a Shrewlet in F2, Mr Crumb in F3).
  - Toll Toad 1/4 across Burdock, Young Pretender in B1, Warty Nan beside the Toad.
  - The decision is real but small. Burdock would have hit a random front unit anyway, and the lock only saves Nan.
  - Toll Toad's "4 or more Attack" never fires this early.
  - Bog folk lose small. That's acceptable only if the early gold is real (rewrite 1).
- **Turn 6 against Oozes.** The best matchup in the set.
  - Every body that comes out of a Belly lands on the patch, is Mired, and is locked onto the same toad. The Peat Cutter pays twice.
  - Decision: which Ooze to bog. Bog the Belly with most inside, not the biggest one. That's a good, non-obvious question.
- **Turn 9 against Fairies.**
  - The scout shows a Changeling in F3. Put a cheap unit in your F3, not a toad. A Changeling swap moves your toad to their side, and the lock ends.
  - Hex across a toad costs little, since toads don't need Attack.
  - Prima Donna: front or back? Their attack is in the front, so F2.
  - Several real decisions this turn.
- **Turn 9 against Birds.**
  - Nests show in the scout, so avoid them: a Mire on an Egg is a wasted mirer.
  - Mother Goose's strikes aren't attacks, so Mire does nothing to them.
  - Decision: which non-Nest slot holds their attack this round.
- **Turn 12 against a Hedgerow Dozey at 90/94 in F2.**
  - As written, Bufo 2/6 across Dozey takes one swing, dies, and Bitter takes Dozey to 88. The lock ends.
  - **"Their giant spends the fight wrestling your 2/6 toad" is false.** Against a giant, Mire is a one-swing Taunt, and Bitter N is noise.
  - The anti-tall role needs one card that makes the giant pay for killing a toad (rewrite 2).

**Do slots matter beyond a row hint?** Yes, and the best slot changes with the enemy board. The default answer, "sturdiest mirer across their biggest", is a rule of thumb, so the depth comes from conflicts between choices:

- **Reading order.** The first mirer in reading order claims the slot.
- **Front or back.** A back mirer drags their back-row unit into your back row. That's good only if it's their carry, and bad if it's a 1-Attack support unit.
- **Who to leave free.**
- **Refills.** Patches catch what lands in the slot, which matters against Oozes and Hedgerow summons.

**Are the builds different?**

- **Wrestling Match** (lock and grind) and **Tongues Across the Water** (lock the back carry, frogs snipe it) are truly different.
- **Frog Prince** is a spells-to-gold build that copies Shy. Rewritten (below), it becomes **The Borrowed Bog**: the Chorus lends Mire to other tribes' Bristle and Hunker walls. That's a real mixed-tribe build.
- Three builds.

### Rulings and rewrites

1. **Toll Toad.** Rename it: Hunters' Toll is a keyword. Its threshold is dead early and flat late.
   **Bridge Toad**. Tier 1, 1/4. "Mire. Start of Combat: if the enemy this Mires has the most Attack on its board (ties count), get 1 gold next turn."
   Golden: "...get 2 gold next turn."
   Now it's a scout test every round, from turn 2 to turn 14.
2. **Madame Bufo** makes the anti-giant claim true. The halving needs her across the right unit, and that comes from the scout.
   "Mire. Bitter 2. If the enemy this Mires kills this, it loses half its Attack this fight."
   Golden: "Mire. Bitter 4. If the enemy this Mires kills this, it loses half its Attack this fight."
   *Runaway watch:* three Bufos are 1/8 of a giant. That's intended, but cost it.
3. **His Highness, Allegedly.** Kiss is Shy: stats from spells or Fairies become gold. It also needs a new recruit intercept on every stat source. Tie it to the tribe's own action instead:
   "Snap. After this kills a Mired enemy, get 1 gold next turn and a kiss. On the third kiss, transform into The Prince Restored."
   Golden: "...get 2 gold next turn..., transform into a golden Prince Restored."
   Kisses are kept between fights. A triple keeps the highest count.
4. **The Prince Restored.** "2 gold every turn, forever" is flat income for doing nothing, which the owner dislikes (02i).
   "Mire. Start of your turn: gain 1 gold for each Mired enemy that died last fight, up to 3."
   Golden: "...2 gold for each..., up to 3."
5. **Jenny Greenteeth.** Her "can be attacked wherever it stands" is outbound reach, which belongs to Hunters. Make her inbound, which is the owner's counterattack:
   "Mire. The enemy this Mires has -2 Attack. After it attacks this, your units beside this attack it at once."
   Golden: "-4 Attack."
   Attacks "at once" never trigger more attacks at once. Tongues still works, because Snap already reaches Mired enemies anywhere.
6. **Tiddy Mun.** As written it can reach +21/+21 of board stats a fight. Rewrite to grow the walls that did the job:
   "After a Mired enemy dies, the Bog folk it was locked onto gains +1/+1 permanently (this, if that one has gone). Three times a fight."
   Golden: "+2/+2."
7. **The Prima Donna.** In B2 on golden, she can delete back rows. Pick the designer's first lever now:
   "Mire, and also the enemies beside the one across from this. Bitter 3, once per enemy."
8. **Rules holes to close.**
   - **An untargetable maker.** The lock makes the maker targetable by its own Mired enemy.
   - **Pack joining and Pounce.** As in the lobby ruling above.
   - **Leapfrog.** "Attacks before your front row" means that at the start of each cycle, flagged back-row units take that side's first turns in reading order. One attack per side's turn still applies, so it doesn't double-attack.
   - **The existing `mired` status** (Turnip Scarecrow) is renamed `stalled`, as the designer asked.
9. **Names.** There are four Jacks in the game (Leapfrog Jack, Low-Water Jack, Jack Daw, Jack-in-the-Green). Rename Leapfrog Jack to **Leapfrog Hopkin**.
10. **Intro copy.** Replace "Their giant spends the fight wrestling your 2/6 toad" with "Their giant's first swing goes into your toad, and Madame Bufo halves it on her way down."

**Overlap check.**

- **Kiss and Fairies' Shy:** fixed above.
- **Bitter and Hedgerow's Bristle:** Bitter weakens the attacker, Bristle hurts it. They're distinct.
- **Snap and Birds' Swoop:** both reach the back row. Snap only reaches what's stuck in your own mud, so it's tied to Mire. Acceptable.
- **Belly:** no clash. Mire feeds on Belly, and that's a good matchup, not a copy.
- **Other games:** none copied. The Frog Prince, Jenny Greenteeth and Tiddy Mun are public-domain folklore.

**Bots.** The heuristic is fine:

- Mirers across the scouted highest Attack, sturdiest first in reading order.
- A back mirer only when you have Snap and their carry is in the back.
- Avoid Nests.

**Phone.** One glyph and short texts. Prima Donna and the Peat King are the longest. Show the patches in the tray preview against the scout.

---

## Hunters: workable as written, strong after the rewrite

**Why.**

- It has the most decisions per turn of the three. Several Hunters want *different* things from the same lanes, so you solve a matching problem every round:
  - Tod wants something killable.
  - Sable wants something bigger than her.
  - The Toll-Bard wants something durable.
  - Russet wants the card you'd like to own.
- Poach is new to the genre: it takes a card from the opponent's board into your shop and out of the pool. It also makes the owner's "foxes take a shop card" concrete.
- Pack is the owner's Swarm, which he liked a lot.

**Problems.**

- Seven keywords: Quarry, Take, Bait, Ambush, Pack, Poach, Toll.
- Bait duplicates Mire.
- The Laird is a rule that was already turned down.
- Take is farmable by refills.

### Played through (with the rewrite)

- **Turn 3 against Fairies** (scout: Toadstool Pixie 3/2 on its Ring in F1, Mothwing 2/2 in F2, Hedge Witch in B2).
  - Tod across Mothwing: a trade, a Take, 1 gold.
  - Wick beside Tod joins his attack.
  - Keep your B2 empty or cheap, because the Witch hexes the slot across from her.
  - A real decision with three units.
- **Turn 6 against Oozes.**
  - Tod's quarry is a Dollop. The Dollop dies, and that's a Take. What comes out of it isn't quarry.
  - Under the original slot rule, Tod would have had 2-3 Takes from one lane, which is the refill farm the designer flagged.
  - Russet across the Posset you'd like to own.
  - The scout shows Hasty Pudding in B2, so keep your carry out of your B2.
- **Turn 9 against Birds.**
  - Nest Eggs can't be quarry. A Hunter across a Nest has no quarry and swings at random. So aim only at slots that are home.
  - Mag Pye across Old Brock takes his text before the bell. That's order-consistent: "first of all" comes before the bell.
- **Turn 12 against a Hedgerow giant at 90/94.**
  - Sable across it is 5/3 and bounces. Three wolves deal 15. Hunters can **aim at** a giant but can't kill one.
  - The design says "it's the tribe that can choose to kill a carry". That's true for mid-sized carries only.
  - The late plan is to aim *around* the giant: take every other unit, bank Takes, and let the Glutton grow. That's a real plan, so say so on the page.

**Do slots matter beyond a row hint?** Most of the three, and the answer changes every round. Two kinds of decision stack up:

- **Matching** each Quarry unit to an enemy.
- **Adjacency:** Pack, Pounce and Old Brock's neighbours.

The cost: the opponent reads your lanes too. If every player scouts, this becomes a guessing game. The position test flagged that and didn't test it. Test it first, with bots in all eight seats scouting.

**Are the builds different?**

- **Open Season** (aim and cash in) is distinct.
- **The Sett** and **The Pact** both focus fire. After the rewrite, the Sett is the *back-row* hunt (flush their B2 and pounce on it), and the Pact is the *front exchange* (three hits, one counter-hit).
- Call it 2.5 builds. Keep the Sett's identity at the back row.

### Rulings and rewrites

1. **Quarry** (signature; replaces "attacks the slot across"). This moves Hunters onto the unit, fixes the refill farm, and makes the mark survive a Whirligig or Changeling.
   *Reminder:* "At the bell, the enemy across becomes this unit's quarry. This attacks its quarry whenever it can."
   - **No quarry.** An empty slot or a Nest Egg across means no quarry, and the Hunter attacks as usual all fight.
   - **Legal targets.** Quarry attacks need a legal target: the front row, or the back row once the front row is empty.
   - **Losing it.** If the quarry dies, changes side or is swallowed, the Hunter has no quarry for the rest of the fight.
   - **Sharing.** Several Hunters may share a quarry. Its death is one Take, made by the first of them in reading order.
   - **Precedence.** Quarry beats Taunt, and Mire beats Quarry.
   - **The noun.** It's "quarry", not "prey". Galaxy's Hunt text already uses "my prey".
2. **Take.** *Reminder:* "Take: when this unit's quarry faints, by any hand."
   Only Hunters make Takes. One Take per death.
3. **Bait is removed.** Bog folk own "must attack this".
   - **Young Brock.** Tier 1, 1/4. "At the bell, your units beside this take the enemy across from this as their quarry, and gain +1 Attack this fight."
     Golden: "+2 Attack."
     A non-Hunter given a quarry hunts it but makes no Take. The badger is how other tribes aim.
   - **Old Brock.** Tier 4, 3/7. "At the bell, your units next to this take the enemy across from this as their quarry. It can be attacked wherever it stands. Your units next to this have Pounce and +1 Attack."
     Golden: "+2 Attack."
     In B2 he flushes their B2 carry for four neighbours. This is the Hunters' back-row reach, and Jenny's exposure now lives here.
4. **Ambush becomes Pounce.** As written it was a counterattack on any enemy that attacks a neighbour, which is the owner's inbound counterattack and Bog folk's. Tie it to the quarry instead.
   *Reminder:* "Pounce: once each cycle, after one of your units damages the quarry of a unit next to this, this attacks that quarry at once, wherever it stands."
   - **The Lodger.** "Pounce. After this pounces, it gains +2/+1 this fight." Golden: "+4/+2."
   - A Pounce is an attack and can set off other Pounces. Each unit pounces once a cycle, so the chain ends.
5. **The Laird of the Sett.** As written it makes both sides' attacks target across: the turned-down rule, and a whole-fight rule switch. Rewrite it to act on your side only:
   "At the bell, all your units take the enemy across as their quarry. After any of your units' quarry faints, your Hunters gain +1/+1 this fight."
   Golden: "+2/+2."
6. **Brother Wolf.** He joins twice a cycle and never takes a counter-hit. That's the designer's own second-riskiest card, and it's a runaway.
   "Pack, on both sides: this can join one attack from each unit beside it per cycle, and takes the hit back each time it joins. While a unit beside it lives, this doesn't lead."
7. **The Toll-Bard.** Fold Toll into Quarry so it isn't a separate keyword:
   "Quarry. After this unit's quarry attacks, get 1 gold next turn, up to 3 times a fight."
   Golden: "2 gold."
   He hunts the thing he wants alive, so pick durable quarry. That's a readable tension, and it competes with Tod for lanes.
8. **Mistress Russet (Poach).** As written, a tier 2 card can steal a tier 6 card at a discount.
   "Quarry. Take: a copy of its card, of your tavern tier or lower, goes into your next shop, 1 gold cheaper. If none is left in the pool, nothing."
   Golden: "2 gold cheaper."
   No Created fallback, since denying the pool is the point.
9. **Low-Water Jack.** Rename him **Old Lutra** (there are four Jacks).
   "Quarry. Its quarry can be attacked wherever it stands. Take: if it was in their back row, get 2 gold next turn."
   Golden: "4 gold."
10. **Pack against Mire:** see the lobby ruling.
11. **The Grizel lever** goes to the costing reviewer: her permanent +1/+1 is the tribe's only lasting scaling.
12. **Reserve Ferreter.** "Mire" means Bog folk's keyword now, so rename the library effect **Pin**.
13. **Names and copies.**
    - Sable's hook, "Winter is coming", is the Game of Thrones line. Use "In winter, ermine. Until then, she makes do."
    - Madame Ermeline is Reynard the Fox's wife in the medieval cycle. That's public domain and fine.
    - Mr. Tod is Beatrix Potter's fox, but "tod" is ordinary Scots for fox, so Tod Scrapling is fine.
    - "Toll" collided with Toll Toad. Fixed above.

**Overlap check.**

- **Bait** = Mire: removed.
- **Ambush** = Bog's counterattack: rewritten.
- **Take** vs Galaxy's Hunt: distinct. Take is credited by mark, not by blow.
- **Pack** vs Hedgerow's Line: distinct. Pack is adjacency in one exchange; the Line passes stats.
- **Poach:** no clash.

**Keywords after the rewrite:** Quarry (with Take), Pack, Pounce. Poach and Toll become plain card text.

**Bots.**

- They need a cheap assignment step on the scouted board:
  - Each Quarry unit goes to the best-scoring enemy for its want (killable, bigger, durable, wanted card). Greedy is enough for Normal.
  - Pack wolves go beside the strongest leader.
  - Old Brock goes across their back carry.
- Opponent bots must hold carries still, or Quarry measures as a coin-flip.

**Phone.** Paw-prints with lines. Keep each card to about 20 words; Old Brock and Brother Wolf are the long ones. The log needs "Take", "Poached" and "Pounce" lines.

---

## Great beasts: workable, stays on file

**Why it's on file.**

- Trample is the clearest picture of the three, and the owner liked it. Hide is the owner's Shell as he described it.
- But it's the closest to Battlegrounds:
  - Trample is the retired Overkill and Wildfire Elemental line. Our own `keywords.md` already names "excess carries to the unit behind" as the natural two-row Overkill.
  - Hide is a cousin of Divine Shield.
- Charge is Quarry for one attack.
- It has eight keywords: Charge, Trample, Hide, Room, Rut, Trophy, Trodden, plus Hunker borrowed from Hedgerow.
- One of its three builds is a wall build (Circle of Horns, Hedgerow's territory). Another is gap text (Open Country), which the position test measured as blank on full boards. Gaps are also Fairies' ground: Spore Sprite, Leaf-Gold Sprite.

### Played through

- **Turn 3.** Truffle across an empty F4 gets 1 gold every fight for standing across nothing. Free early money, and it does nothing late.
- **Turn 6 against Hedgerow** (Old Delver Hunker wall in F2, Dozey in B1 behind it).
  - Old Steinbock in F2 bounces off the wall and swaps Dozey forward. That's a good card and a real decision.
- **Turn 9 against Bog folk.**
  - A Mired charger charges the toad. Its trample is lost if the toad is in the back row, and Bitter eats it.
  - Bog folk counter Great beasts hard. That's good for lobby texture, and fine.
- **Turn 12.**
  - The stampede fires once, then the herd is plain bodies.
  - Each charger's lane is a decision once a fight. That's fewer than Hunters, but still a scout-read every round.

### Rulings and rewrites (for the file)

1. **Charge keeps the column**, as written. It isn't changed by the lobby ruling, which already separates it from Quarry: Charge reads the slot when it attacks and what's behind it; Quarry reads the unit at the bell.
2. **Big Ursula** loses the forced attack, which belongs to Bog folk.
   "Hide 8. When this loses Hide, deal the damage it stopped to the unit that hit it."
   Golden: "Hide 8, lasting two hits... twice the damage it stopped."
3. **Truffle.**
   "Charge. After this charges, if it ran through a gap or its target died, gain 1 gold next turn."
   Golden: "2 gold."
4. **Room becomes column text.** It now reads the enemy's gaps in its column, which change every opponent, not your own gaps.
   - **The Bog Elk.** Rename it **The Alder Elk** ("Bog" is a tribe name now).
     "Trample. Start of Combat: gain +2/+2 this combat for each empty enemy slot in the column across from this (the slot across and the slots behind it)."
     Golden: "+4/+4."
   - **Ibex Kid.** "Start of Combat: gain +1/+1 this combat for each empty enemy slot in the column across from this." Golden: "+2/+2."
   - **Old Grazer.** "Hide 4. After a hit on this is capped by Hide, gain 1 gold next turn, once a fight." Golden: "2 gold."
5. **Hunker is Hedgerow's keyword.**
   - **Mother Wisent.** "Hide 6. Start of Combat: give the other units next to this Hide 5 this combat."
   - **The Bison Elders.** "Hide 6. Your Charges deal 3 extra damage, and their trample doesn't split." Golden: "6 extra damage."
6. **Trodden and Spill.** Trodden turns Hedgerow summons into Acorns. That's fine, and it's on the card's page.

---

## Which two to build: Bog folk and Hunters

- **Both are new to the genre.** Bog folk choose who hits whom. Hunters mark, follow and are paid for their quarry, and Poach takes cards out of the pool. Great beasts are Battlegrounds' Overkill plus Divine Shield, done well.
- **After the ruling, they own opposite relationships** (inbound and the ground against outbound and the animal), with opposite counterplay: moving answers Bog folk, walling answers Hunters. One is defensive and one aggressive, so a lobby with both has texture.
- **Both answer the playtest.** Bog folk (with Bufo rewritten) tax the giant. Hunters win around it and steal the triple pieces the tall player needs.
- **Both build economy from what they do.** Bog folk pay when Mired enemies die, win or lose. Hunters' Takes pay when winning, and the Toll-Bard pays when losing.
- **Hunters have the most decisions per turn,** which is what the falling placement value needs.
- **The cost:** trample stays on file. If the owner wants it in, the cleanest home is a neutral Overkill card ("excess damage carries to the unit behind"), not a third lane tribe.

### Bog folk: first 8

| Tier | Unit | Why it's in the first 8 |
|---|---|---|
| 1 | Bridge Toad (rewrite 1) | The tribe in one card, and early gold |
| 1 | Young Pretender | The Snap half; gold for finishing the stuck enemy |
| 2 | Madame Bufo (rewrite 2) | The core wall, and the anti-giant halving |
| 2 | The Peat Cutter | Steady income, best against Oozes and token boards |
| 2 | Leapfrog Hopkin (renamed Leapfrog Jack) | Kills the stuck carry before it swings; the Tongues build |
| 3 | Gideon, Basso Profundo | The owner's counterattack, in the tribe that owns it |
| 5 | The Prima Donna (rewrite 7) | The front-or-back question at its biggest |
| 5 | Tiddy Mun (rewrite 6) | Spread, lasting scaling for the walls that held |

Next in: Warty Nan, the Natterjack Chorus (The Borrowed Bog build), Spitfire Sal.

### Hunters: first 8

| Tier | Unit | Why it's in the first 8 |
|---|---|---|
| 1 | Tod Scrapling | Quarry and Take in one line; basic money |
| 1 | Wick | Pack on turn 1; follows the leader's aim |
| 2 | Sable | Wants a *different* lane from Tod, so the matching starts at once |
| 2 | Mistress Russet (rewrite 8) | Poach, the tribe's novelty and its triple denial |
| 3 | The Lodger (Pounce, rewrite 4) | Punishes the quarry for being hit; adjacency decisions |
| 4 | Old Brock (rewrite 3) | The back-row hunt; lends quarry to other tribes |
| 4 | Madame Ermeline | Takes into tempo; "do I level now?" |
| 5 | Grizel | Pack's lasting scaling, spread across three units |

Next in: Young Brock, the Toll-Bard (rewrite 7), The Mountain Glutton, Old Lutra.

## Before any of this is judged

- **Bots must hold carries still between rounds.** Playtest B saw half of each bot board shuffle. All three tribes measure as noise against a moving target.
- **The lane relationships must show on screen.** The tray must draw the patches and quarry lines against the scout before the bell. Without that, a phone player can't see either tribe's decision.
- **Run the all-seats-scout test** the position test listed as untested, before tuning Quarry. If everyone reads everyone, Hunters may become a guessing game.
