# Cold-reader packet: tutorial and Rules only

This packet contains only the tutorial/Rules proposal from section 4 of the UI
spec and text from the shipped How to play pages, including the linked term slips
those pages let a player open. It contains no fight event streams, manifests,
attacker identities or expected answers.

The owner confirmed a source/effect criterion for Batch 1. For each attack,
use visible positions or portraits to identify who moved or flashed, who received
the hit or change, and what visibly happened, including the visible cause of a
death. You do not need to reconstruct an unstated unit ability or name an unfamiliar
keyword. If a source or effect is not visible, say so explicitly. This applies at
×1, ×4 and reduce motion. Read only this packet and the strip images until your
answers are recorded.

## Tutorial script and proposed Rules reference


### Tutorial: one scripted game, 4 rounds, about 5 minutes

- **Setup.** You plus 3 rivals with fixed boards each round (built like `content/scenarios`), fixed shops, and fights locked at ×1.
- **Coach.** A coach slip sits outside the board. An animated finger shows each new action once, and only that control works.
- **Access.** It can be skipped at any time. It replaces the guide on the first New game, and can be replayed from the menu hub, Settings and the pause menu.
- **Containment.** The coach exists only in the tutorial.

| Step | Round | The player does | It makes safe the cut of |
|---|---|---|---|
| 1 | 1 | Taps a shop unit (hover on PC) to open the reader, then taps its underlined keyword for the reminder. Coach: "Tap any card, here or in a fight, to read it." | Rules text, names, tier and tribe on tiles; keyword chips; the fight's keyword box |
| 2 | 1 | Buys a unit and drags it (or taps a lit slot) into the front row, while acorns fly off the gold. | Hand title and hint, "Board 7/7", the acorn pile, action hints |
| 3 | 1 | Ends the turn. In the fight, which you win: the bell rings and the coach says "Start of Combat first". Your glyph pulses and its mote flies. Then the lunges, damage pops and a death. Coach: "Then the sides take turns: front row left to right, then the back row." | THIS HIT, yarn, slips, phase captions, the "Start of Combat first" text |
| 4 | 2 | Sells, refreshes (icon leaf; hold it to see its word), buys two and puts one in the back row. Coach: "The back row is safe until the front row falls." | Row tags, leaf words, empty-slot notes |
| 5 | 2 | Opens a unit with "beside" text, and the slots it reaches pulse. Places it. At End of Turn its spark jumps to its neighbours. | Grooves, relation highlight, slot codes |
| 6 | 2 | In the fight, which you lose (the rival has the bigger band and goes first), taps a unit. Play pauses and the reader opens; a tap resumes. | The combat log and keyword box |
| 7 | 2 | Watches the damage, with sparks staggered this one time: one spark per enemy starting survivor, and a summoned survivor sends none. Coach: "You lose the round's base plus 1 for each of their units that started and survived. The base is 0 now and rises each round." | End turn formula, result panel, damage text |
| 8 | 3 | The red rim marks who you fight next. Taps it to see their last board, taps their portrait to read their hero, and taps the rim again to close. | "Next:", Scout/Close, Who?, scout title, "then fight X" |
| 9 | 3 | Tiers up (the cost is lower than last turn), then freezes. | "Tier 4" row, frozen tag |
| 10 | 3 | Skips the fight with the double-chevron. | "Skip / to the result" |
| 11 | 4 | A third copy is offered. Buys it; the three merge into a golden card in hand. Plays it and Discovers. | Triple toasts, spark star |
| 12 | 4 | Uses the hero power, and plays a bought spell onto a unit. | The "Power" word, spell tile text |
| End | | Coach: "The rest is on any card you tap, and in How to play." | |

**Left to the Rules pages and the reader, not the tutorial:** ghosts, eliminations, Last Four, Last Stand, Last Blow, Pass and Touching, Rings, Nests, Belly, Hex, Shy, Mire, Quarry, statuses, counters, tribe and Ring-size counters, the income badge, the hand limit and armor. Each has a tappable mark whose reader states the rule.

### Rules reference (replaces the 14-page guide)

A hub of topic tabs. Each topic has one short paragraph and one looping demo built from the in-game animations, in the new look (icon-only leaves, no slot codes except page 3's diagram). Read in order, they teach:

1. **Reading cards.** Tap any card, mark, plaque or token to read it. In a fight, a tap pauses. (Today this is on page 12 of 14. It moves to page 1.)
2. **Recruit.** Gold and the income table, buy, sell, refresh, freeze, tier up and its falling cost, triples and Discover, spells, hero power, and the hand limit of 10.
3. **Board.** The brick wall, the only labelled diagram. The front row takes the hits. Behind, beside, next to and touching, worded without codes. Across means the same column. Then Rings, Nests and Eggs, and the Rainbow band.
4. **Fights.** Start of Combat first (shown with the bell), then front row left to right and then the back row, sides alternating, the bigger band first. Demo: lunges and deaths, with the back unit untouched until the front falls. Then Last Blow.
5. **Damage and Health.** Round base plus 1 per enemy starting survivor, the base schedule as a table, ties, armor and Early Spoils.
6. **Lobby, ghosts and the last four (new page).** The standings order, the Next rim, scouting a last board, the ghost chip (their last board, with no Health), Last Four, and Last Stand (gold ring unused, crack used).
7. **Tribes.** The counter column (tribe bonus, Ring size, Midsummer) and the Birds away tokens.
8. **Keywords A–Z.** Each keyword with its mark or its motion: the Mire reeds, Quarry claw and paw, Swoop notch, Shield bubble, Shell rim, Nightshade berry, Pass seed, Cleave sweep, Pack join, and so on.

**Edits to `how_to_play.gd`:**
- Reword every slot code as in 2.4.
- Add "Start of Combat effects go first, then attacks" to "Who attacks when".
- Change "Tap Scout" to "Tap your next opponent".
- Move card exceptions to their cards.
- Turn every static tag and numbered chip into an animation.

---


## Shipped How to play text

### Page 1: Build a band, then watch them fight

Buy a unit for 3 gold and drag it into a slot. End turn starts an automatic fight; your band returns whole. Outlast seven rivals.

Tap any card, or tap in a fight, to read it.

### Page 2: A little more gold each round

Round 1 gives 3 gold, then 4, 5 and so on, up to 10.

Unspent gold carries over. Rounds 1-4: win a fight for 1 gold next turn. Ties and ghost wins pay nothing.

Linked terms: Early Spoils.

### Page 3: Shape your next shop

Tier 1 offers four units and one spell.

Tier up for better cards; waiting makes it cheaper. Refresh for new offers. Freeze keeps them. Sell a unit to free its slot.

### Page 4: Your hero and your spells

Your hero has a power. Some work by themselves; others have a button.

Spells are in the shop too. Buy one, then play it from your hand.

### Page 5: Help your favourites grow

A 2/3 has 2 Attack and 3 Health. Permanent bonuses stay between fights.

Three copies make a golden unit. Play it for a reward: Discover a unit from the tier above.

### Page 6: Your board is a brick wall

Four slots in front, three behind, laid like bricks: each back slot sits behind two front slots.

Units don't slide into gaps.

### Page 7: The front row takes the hits

Attackers hit a random unit in the enemy front row. The back row is safe until the front is empty.

Attacker and defender hit each other. Put tough units in front.

### Page 8: Who attacks when

Units attack in order: F1 to F4, then B1 to B3.

The sides take turns. The bigger band goes first.

### Page 9: Scout who you fight next

Tap Scout to see your next opponent's last board.

Across means the same slot on their side: your F2 faces their F2.

### Page 10: Stay standing to win

Start with 40 Health. Lose a fight: take the round's base damage, plus 1 per enemy starting survivor.

The base rises as rounds pass. Ties deal no damage. Last hero standing wins.

Linked terms: Round base, Starting survivor, Last Blow, Last Stand.

### Page 11: Make room for your tribe

Each game uses five tribes. Some cards reward units that share a tribe.

Tribe bonuses, shown by the tribe icons, help every unit of that tribe, even ones you get later.

### Page 12: Oozes hold; Birds travel

Oozes keep units in their Belly. When the Ooze dies, they come out.

Birds Fly South and come home later, leaving an Egg in their Nest.

Tap any card to read its rules.

### Page 13: Follow the zigzag

Zigzag order: F1-B1-F2-B2-F3-B3-F4.

Touching needs an unbroken run; a gap breaks it. Pass skips gaps: your last unit other than its source gains the bonus. Recruiting, it lands at End of Turn.

Linked terms: Pass, Shy, Mire.

### Page 14: Give your band a good start

Fill your empty slots early: more units, more attacks.

Stay on a tier while you build.

Scout before you end the turn.

## Term slips linked from the shipped pages

**Early Spoils.** Rounds 1-4: win a fight and get 1 gold next turn. Ghost wins and ties pay nothing.

**Round base.** Rises each round, up to 13.

**Starting survivor.** Your unit that began the fight and survives on your side.

**Last Blow.** Both boards fall: the final attack or effect wins.

**Last Stand.** Last four: from 2+ Health, survive one lethal hero loss on 1 Health.

**Pass.** Pass X: your last unit, other than this, gains X

**Shy.** Only a spell aimed at this buffs it. Then it leaves: get 2 gold next turn.

**Mire.** Start of Combat: the enemy across must attack this while this lives. This waits for it, once.

Provenance: `docs/ideation/ui-declutter-spec.md` section 4;
`src/ui/screens/how_to_play.gd` `PAGES`; linked reminder wording from
`src/ui/keyword_rules.gd` and `content/schema/effects.json`. These are rule
materials rather than fight-specific evidence. The planned Rules hub and the
current linear pages coexist in this packet because Batch 4 builds the hub.
