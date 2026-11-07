# Hunters

Foxes, stoats, weasels, pine martens, badgers, otters, wolves and one wolverine who came for a christening and stayed for the buffet. The woodland's small carnivores, written light: nobody dies in the woodland, they faint, and the fox takes the credit. **Every Hunter picks its prey at the bell and follows it.**

**Stats are by feel, then costed in `../evidence/costing-3.md`. Nothing here has been played.** Numbers below are costing's, where costing changed them.

**The tribe in one paragraph.** At the bell, each Hunter with Quarry marks the enemy standing across from it. That unit is its **quarry** for the fight: the Hunter attacks it whenever it legally can, and the mark stays on that animal wherever it goes, swapped, shuffled or moved. When the quarry faints, by anyone's hand, and the Hunter is still on the board, that's a **Take**, and Takes pay: gold, a copy of the fallen card in your shop, a cheaper upgrade, a bigger wolverine. Badgers lend their quarry to whoever stands beside them, so other tribes can aim too. Wolves hunt in packs: several hits land as one, and only the leader takes the hit back. So each turn you scout the next opponent and solve a matching problem: which Hunter goes across from which of theirs, given that Nip wants something killable, Sable wants something bigger than her and the Toll-Bard wants something that lives?

## What the first playtest asked for, and the answer here

| Playtest or review said | What Hunters do about it |
|---|---|
| Builds end as one huge unit stacked with spells | Hunters **aim at** a giant but can't kill one alone. Their late plan is to aim *around* it: take every other unit, bank Takes, grow the Glutton, and steal the triple pieces the tall player still needs (Mistress Russet). Sable and Old Brock's back-row reach are the two cards that hurt a mid-sized carry. |
| Placement is what reviewers liked most, but a simple row rule nearly matches search | Every Hunter reads the enemy across, a neighbour or a Take. The position test found "across from" is the only text that clears the noise floor (+6.5 to +7.1 adaptive). |
| Knowing the enemy board adds the most | The tribe is built on the scout. Last round's board tells you whom to mark. |
| Economy should be tied to what the tribe already does | Every economy card pays for a Take or for the quarry's own attacks. Nothing pays for standing still. |
| "I don't know what 'foxes take a shop card' means" (02h) | Mistress Russet: when her quarry faints, a copy of its card goes into your next shop, 1 gold cheaper, out of the shared pool. Worked example below. |
| Swarm: "I like that idea a lot" (02h) | It's Pack, for wolves and weasels. |
| Mire: "it makes their backline attack into you... counterattack damage" (02h) | **The owner was exploring that idea, not asking for it** (02i: "If it seems like I'm not asking you to do anything with it, I'm not"). Hunters don't build on it. The enemy-must-attack-this relationship belongs to Bog folk, and Hunters only own the marked quarry. |

---

## The signature: Quarry and the Take

### Quarry

*Reminder: at the bell, the enemy across becomes this unit's quarry. This attacks its quarry whenever it can.*

**Example card.** **Little Nip**, tier 1, 2/1. "Quarry. Take: get 1 gold next turn."

**How it plays, one turn.** Round 3. The scout shows the next opponent fought last round with a 2/2 in F2 and a 1/3 in F3. You put Nip in F2. At the bell, if their 2/2 still stands in F2, it becomes his quarry: a paw-print on it, a line back to Nip. He attacks it, not a coin-flip between the two. They trade; it faints while Nip is on the board, so it's a Take and you get 1 gold next turn. Had you put him in F3, he'd have bounced off the 1/3 and earned nothing. If the opponent moved the 2/2 to F4 this turn, Nip's quarry is whatever now stands in F2, or nothing at all, and you learn how this opponent plays.

**Why build around it.**

- It turns "who do I stack?" into "who do I aim at whom?" Battlegrounds has no aimed attacks; every target there is random unless a Taunt changes it.
- Several Hunters want *different* things from the same lanes, so the question is a matching problem, and the answer changes every round because the opponent moves too.
- Takes pay, so aiming is economy. A badly aimed Hunter is a plain unit; a well aimed one is a plain unit plus gold.
- **The mark is on the animal, not the slot.** A Whirligig swap or a shuffle at Start of Combat doesn't throw the Hunter off. A unit that drops into the slot later is not the quarry, so a Belly opening or a summon gives no extra Take.

**The price.** Quarry isn't optional. A Hunter must attack its quarry when it can, even if that's a 1/10 Hunker wall or a hedgehog with Bristle 3. The opponent sees your Hunters in the scout and can wall your lanes. **Walling answers Hunters; moving doesn't**, because the mark is fixed on whatever stands there at the bell. That is the opposite of Bog folk, whose mud stays on the slot, so a lobby with both tribes asks for two different kinds of counterplay.

### Take

*Reminder: "Take:" text fires when this unit's quarry faints while this is on the board, whoever made it faint.*

- The Hunter needn't strike the blow. A Fairy's Nightshade, a Hedgerow Acorn or a teammate's swing all count: a fox claims every kill of its quarry.
- **The Hunter must be on the board when the quarry faints.** If both faint in the same exchange, the Take counts (they go down together). A Hunter that fainted earlier claims nothing. This is the rule `costing-3.md` priced; letting a dead Hunter's mark pay would raise every Take rate by 1.3-2.5x.
- **Only Hunters make Takes.** A non-Hunter given a quarry (by a badger or the Laird) hunts it but makes no Take.
- **One Take per death.** If several Hunters share a quarry, the first of them in reading order makes the Take.
- Takes happen only in combat. Payoffs that touch the Recruit Phase (gold, shop cards, upgrade cost) arrive after the fight, like every combat effect that changes the recruit board (`engine.md`).

### Exact rules

1. **The bell.** A new first step of Start of Combat, after Mag Pye's "first of all" and before every other Start of Combat text. Both sides fix their marks and patches at the same time: Hunters mark quarries, Bog folk lay their patches. Then Start of Combat runs as usual, so Sable's check reads a quarry already fixed.
2. **Marking.** Each unit with Quarry takes the enemy across as its quarry. An empty slot, or a Nest Egg, means no quarry: the unit attacks as usual all fight. Then lenders (Young Brock, Old Brock, the Laird) lend in reading order to units that still have none.
3. **One quarry each.** A unit's own Quarry beats a lent one; between lenders, the first in reading order wins.
4. **Targeting precedence for every attack:** Mire lock, then the attacker's own text (quarry, Swoop, Poacher's Path), then Taunt, then random. So a Mired Hunter swings at the toad. If one unit has two of its own targeting texts, quarry goes first when its quarry is a legal target.
5. **Legal targets.** A quarry attack needs a legal target under 9.5.1: the front row, or the back row once the front row is empty. If the quarry is protected, the Hunter attacks as usual until it isn't. Cards with **reach** (Old Lutra, Old Brock's neighbours) may attack their quarry wherever it stands. Untargetable units can't be hunted while hidden.
6. **The mark follows the unit.** Moved by Whirligig Beetle, Mole Cricket, Jack-in-the-Green or a swap, the quarry is still the quarry, and a moved Hunter keeps its quarry too.
7. **Losing it.** If the quarry faints, changes side or is swallowed, the Hunter has no quarry for the rest of the fight, and attacks as usual. It never marks again that fight.
8. **No new marks after the bell.** A unit summoned or let out mid-fight isn't anyone's quarry, and a Hunter summoned mid-fight has none, unless a card says so.
9. **Repeat attacks** (Windfury-style) each go to the quarry if it's still a legal target.
10. **Recruit Phase.** Quarry does nothing until the bell. Recruit moves are free, so the commitment is that you mark from last round's board, not the one you'll fight.
11. **Golden.** Quarry has no number; goldens double the card's other numbers. Take text doubles its numbers and fires once per death.
12. **Ghosts.** Marks read the ghost's board as it is copied in. Nothing special.

### Why this isn't Galaxy's Hunt or Battlegrounds' "after this kills"

Those reward the unit that struck the blow, and the blow lands on a random target, so you can't plan the kill. A Take rewards **the mark you chose before the fight**, not who struck. You can set one up with another unit's attack or a spell, as long as the Hunter is still standing when the quarry falls. Galaxy's Hunt text says "my prey"; this tribe's noun is **quarry**, so the two never read alike.

**Similar to:** Galaxy's "the enemy across from me" duel text and Magic's "attacks each combat if able", aimed by position and held on one target. Players of lane games (Legends of Runeterra's Challenger, Marvel Snap's locations) know the feeling: what faces you at the start is what you chase.

---

## The other keywords

Three keywords in all: **Quarry** (with Take), **Pack** and **Pounce**. Poach and Toll are printed text on one card each.

### Pack (the owner's Swarm)

*Reminder: when a unit beside this attacks, this joins in. The target hits back only the leader.*

- When a friendly unit adjacent to this (same row, 8.2.2) makes an attack on its side's turn, this joins, if it's alive, has Attack above 0 and hasn't attacked this cycle.
- **Joining.** This deals its Attack to the leader's target in the same damage step. The target deals damage only to the leader. The leader's damage triggers resolve first, then joiners in reading order.
- Joining uses up this unit's attack for the cycle (9.4.5 flag), so its own turn is skipped. It hits the leader's target, not its own quarry.
- Joining isn't attacking: "when this attacks" text doesn't fire on the joiner; "after this deals damage" does. Bristle and "when attacked" text answer the leader only.
- Each joiner's damage is a separate hit: good against Shell, which caps single hits. Hunker halves all of it.
- **Reading order matters.** A Pack unit that comes before its partner in reading order leads on its own turn and has nothing left to join with. Put it just after its leader: F2 joins F1, F4 joins F3.
- **No chains.** Only the leader's neighbours join. Pack joins turn attacks only, not Pounces or "attacks immediately". A gap beside it means no partner on that side.
- **Under Mire.** A Mired unit whose maker lives can join only if the leader's target is that maker.

**Why it matters for quarry.** The leader picks the target. A Quarry leader with two wolves beside it sends three units' Attack into its quarry, and only the leader takes the counter-hit. But the wolves give up their own marks to do it.

### Pounce

*Reminder: once a cycle, after your side damages a neighbour's quarry, this attacks that quarry at once, wherever it stands.*

- **Trigger.** Any friendly damage to the quarry of a unit next to this (8.2.3: beside, in front or behind): a turn attack, a joiner's hit, a spell, another Pounce. The pouncer needn't have a quarry of its own.
- **The pounce** is an immediate attack (9.4.12): it doesn't use this unit's turn or move the attack pointer. It ignores rows and Taunt. Counter-damage as usual. A Mired pouncer can pounce only at its maker.
- It needs the quarry still alive, this unit alive with Attack above 0, and this unit's pounce unused this cycle.
- A Pounce is an attack, so its damage can set off other Pounces. Each unit pounces once a cycle, so the chain ends.
- **Why it isn't Ambush.** The draft's Ambush struck back at whoever attacked a neighbour: that's the inbound counterattack, which is Bog folk's ground. Pounce piles onto the quarry you chose, so it stays offence.

### Poach and Toll, as printed text

- **Poach** (Mistress Russet). The base card, not golden, no buffs, taken from the shared pool into an extra slot in your next shop, 1 gold cheaper. It stays through your refreshes that turn and goes back to the pool at End of Turn if you don't buy it. Only cards of your tavern tier or lower. If the pool has none left, nothing happens: denying the pool is the point. Tokens can't be poached. Bought, it's an ordinary bought unit: it sells for 1 and counts for triples.
- **Toll** (The Toll-Bard). Counts every attack his quarry makes, at anyone: turn attacks, repeats, immediate attacks. He wants the opposite of a Take, so he hunts the thing he'd like to keep alive.

**Worked example (the owner's question).** Round 7, you're at tier 3. Your next opponent's scouted board has Alderman Dozey in F2. You put Mistress Russet in F2. At the bell Dozey is her quarry. She doesn't kill him, but your F1 unit's attack does, while Russet still stands: a Take. After the fight, your next shop has an extra card: a fresh Alderman Dozey, base 2/5, for 2 gold instead of 3. It came out of the pool, so that's one fewer Dozey for the Hedgerow player trying to triple him. That's "the fox takes a shop card": it takes it from their board, into your shop, and out of their reach.

---

## The units

14 units: 3 / 3 / 3 / 2 / 2 / 1. Five have Quarry (Little Nip, Sable, The Toll-Bard, Mistress Russet, Old Lutra). Three lend a quarry (Young Brock, Old Brock, the Laird), three have Pack, and two Pounce or give it. Every unit reads a quarry, a neighbour or a Take.

Type line: all are **Hunters**. "Beside" means adjacent in the row (8.2.2); "next to" means any neighbour (8.2.3).

### Tier 1

**Little Nip**. *Fox Cub, Errand-Runner.* Tier 1, 2/1.
- Text: Quarry. Take: get 1 gold next turn.
- Golden (4/2): Quarry. Take: get 2 gold next turn.
- Row: front, across from something 2 Attack can trade with. In a back lane he waits for a Take that may never come.
- Why buy: the tribe's basic money, and the first lesson in reading the scout. The only Hunter gold that works on any board; at 0.55 Takes a fight it's in band.
- Hook: he did all of it himself. Ask anyone. Don't ask anyone.

**Young Brock**. *Badger, Heir to the Sett.* Tier 1, 1/3.
- Text: At the bell, your units beside this take the enemy across from this as their quarry, and gain +1 Attack this fight.
- Golden (2/6): Same, and they gain +2 Attack.
- Row: between two attackers that have no quarry of their own, across from what you want them to kill. F2 and F3 lend to two units, F1 and F4 to one.
- Why buy: the badger is how other tribes aim. Two Hedgerow bodies beside him become hunters for one fight, though only Hunters make Takes.
- Hook: will inherit four hundred years of tunnels and a family of foxes who have never paid rent.

**Wick**. *Least Weasel, Runner for the Pack.* Tier 1, 2/2.
- Text: Pack. After this joins an attack, it gains +1 Attack this fight.
- Golden (4/4): Pack. After this joins an attack, it gains +2 Attack this fight.
- Row: just after your Quarry Hunter in the row, so it joins before its own turn comes and its hits go where you aimed. Every join makes the next one bigger.
- Why buy: a cheap body whose hits follow your best-aimed unit, and the start of a pack.
- Hook: the smallest carnivore in the wood. Has decided this means the fastest.

### Tier 2

**Sable**. *Stoat, of the Ermine Court, in Summer Brown.* Tier 2, 2/3.
- Text: Quarry. Start of Combat: if its quarry has more Attack than this, this gains +3 Attack this fight.
- Golden (4/6): Quarry. Start of Combat: if its quarry has more Attack than this, this gains +6 Attack this fight.
- Row: across from something bigger than her. Lined up against a weakling, she's a 2/3.
- Why buy: a cheap hitter that's best against their best units, and the tribe's one measured answer to a tall front unit (+4.3 SP there). It wants a different lane from Nip, so the matching starts at once.
- Hook: the Court's summer assassins dress in brown. They are counting the days to ermine.

**The Toll-Bard**. *Pine Marten, Keeper of the Lane Songs.* Tier 2, 2/3.
- Text: Quarry. After its quarry attacks, get 1 gold next turn, up to 3 times a fight.
- Golden (4/6): Quarry. After its quarry attacks, get 2 gold next turn, up to 3 gold a fight.
- Row: across from an enemy that will live long and swing often. Never across something your other Hunters want dead.
- Why buy: the one Hunter that pays when you're behind, since a strong enemy swings more. He also takes a lane from your other Hunters, which is the decision.
- Hook: any traveller may pass. Each pays in verse, or failing verse, in coin.

**Mistress Russet**. *Fox, Poacher, Licensed After a Fashion.* Tier 2, 3/2.
- Text: Quarry. Take: if its card is your tier or lower, a pool copy goes into your next shop, 1 gold cheaper.
- Golden (6/4): Same, 2 gold cheaper.
- Row: across from the card you want to own, or want them not to own.
- Why buy: theft. A card you chose, at a discount, out of the opponent's reach. The tier limit stops a tier 2 fox stealing tier 6 cards cheap.
- Hook: it was already out of its pen. She was only showing it the way.

### Tier 3

**Brother Wolf**. *Wolf, Under a Vow.* Tier 3, 3/4.
- Text: Pack, once per unit beside it each cycle. Doesn't lead while a unit beside it can lead.
- Golden (6/8): Same text.
- Row: front, between two leaders: F2 or F3 joins both attacks a cycle. With no leader beside him, he remembers he's a wolf and attacks on his own.
- Why buy: 3 Attack that can land twice a cycle and never takes a counter-hit while his partners live. The catch is the partners. Two Brother Wolves side by side with nobody else simply lead as usual.
- Hook: he swore on the old oak never to strike first. He does not consider this striking first.

**The Lodger**. *Fox, Lodger in a Badger Sett, Pays No Rent.* Tier 3, 4/4.
- Text: Pounce. After this pounces, it gains +2/+1 this fight.
- Golden (8/8): Pounce. After this pounces, it gains +4/+2 this fight.
- Row: next to the units whose quarry will be hit first. In B1, B2 or B3 he sits behind two front units at once; beside Old Brock's neighbours he pounces on a back-row carry.
- Why buy: piles onto the mark from anywhere. It reaches a protected back-row quarry, which nothing else at tier 3 can.
- Hook: has lived in the east wing for eleven generations. Is still described as "staying for a bit".

**Old Lutra**. *Otter, Runner of the Reed Channels.* Tier 3, 2/4.
- Text: Quarry, reaching it wherever it stands. Take: if it was in their back row, get 1 gold next turn.
- Golden (4/8): Same, 2 gold.
- Row: back, across from their protected carry or back-row engine. In the front row he's a plain Quarry otter.
- Why buy: a way into one chosen back-row slot from the first cycle, and paid for it. He attacks after your front row, so his first swing is late in cycle one.
- Hook: the heron customs men have searched him nine times. They have never once looked under the water.

### Tier 4

**Madame Ermeline**. *Stoat, Court Dressmaker.* Tier 4, 3/6.
- Text: After each fight, your next upgrade costs 1 less per Take your Hunters made (up to 3). At tier 6, gold instead (up to 2).
- Golden (6/12): 2 less per Take (up to 3 Takes). At tier 6, up to 3 gold.
- Row: back, safe. Her text is board-wide: what matters is where everyone else stands.
- Why buy: tempo for the tribe's whole job. Use it next turn or lose it, so it asks "do I level now?" The discount floors at 0 and applies after other upgrade discounts.
- Hook: her trims are the finest in the Court. She will not say where the ribbons come from.

**Old Brock**. *Badger, Squire of the Sett.* Tier 4, 2/5.
- Text: At the bell, your units next to this take the enemy across as quarry and can reach it anywhere. They have Pounce and +1 Attack.
- Golden (4/10): Same, and +2 Attack.
- Row: B2, with four neighbours, marks their B2 for F2, F3, B1 and B3. Your F2 attacks it in the first cycle, and the rest pounce. Units with their own Quarry keep their own mark, so fill his neighbours with Lodgers, wolves or other tribes. The marks stay if he faints; Pounce and +1 Attack go with him.
- Why buy: the Sett build's centre, and the Hunters' back-row reach. Their back row, the safest place on their board, is where the fight starts.
- Hook: the foxes are frightful, of course. But one must have *somebody* to dinner.

### Tier 5

**The Mountain Glutton**. *Wolverine, Saga Mercenary, Here for the Food.* Tier 5, 4/5.
- Text: After one of your Hunters makes a Take, this gains +2/+2 this fight.
- Golden (8/10): After one of your Hunters makes a Take, this gains +4/+4 this fight.
- Row: back, and not across from anything that can reach it. It grows while the front hunts, then swings last and large.
- Why buy: the old longlist glutton, without the cap (owner, 02h), and without the permanent stack: its growth ends with the fight. Three Takes make it 10/11 by its first swing.
- Hook: signed on for the plunder. Is now mostly there for the catering.

**Grizel**. *Wolf, Mother of the Pack.* Tier 5, 5/6.
- Text: Pack. After a pack attack kills its target, the leader and each joiner gain +1 Attack permanently.
- Golden (10/12): Same, +2 Attack permanently.
- Row: front, just after a Quarry leader. The leader's aim decides whether the pack kills.
- Why buy: the tribe's lasting scaling, spread over three units a little at a time rather than one unit a lot.
- Hook: raised every cub in the valley, half of them not wolves. They all still call her on Sundays.

### Tier 6

**The Laird of the Sett**. *Badger, Keeper of the Old Rights.* Tier 6, 4/6.
- Text: At the bell, all your units take the enemy across as quarry. Your Hunters that have one gain +1/+1 this fight.
- Golden (8/12): Same, +2/+2.
- Row: back, out of the way. He changes your whole side, not his slot. The opponent's targeting stays their own.
- Why buy: every lane on your side becomes a planned matchup, and every unit becomes a possible Take for the Glutton and Ermeline. Seven lanes, seven questions, answered from the scout.
- Hook: the old rights are clear. Everyone faces whoever stands opposite. He has the papers somewhere.

### Reserves, if the roster grows

- **The Wildcat of the Cairn**. *Wildcat, Answers to No One.* Tier 3, 4/3. "Quarry. Start of Combat: if no friendly unit is beside this, its quarry loses 3 Health." The solitary hunter.
- **Light-Fingered Nan**. *Weasel, Pickpocket.* Tier 2, 2/2. "Quarry. Take: the enemy player gets 1 less gold next turn, and you get 1 more." Theft of the other player's gold. Maybe too feel-bad; kept for the owner to judge.
- **The Ferreter**. *Polecat, Who Goes Down the Holes.* Tier 4, 3/5. "Quarry. Pin (its quarry skips its next attack after this damages it)." Library entry 11, renamed **Pin** because "Mire" is now Bog folk's keyword.

---

## How it interacts with slots, position and scouting

Hunters are the tribe whose best slot depends most on the other board.

| Card or rule | What the slot decides |
|---|---|
| Quarry Hunters (Nip, Sable, the Toll-Bard, Russet, Lutra) | Whom they mark. Front quarries can be hit at once; back quarries wait for the front to fall, unless the Hunter has reach. |
| Little Nip and Sable | Nip wants something he can trade with; Sable wants something with more Attack. They often want different lanes. |
| The Toll-Bard | Wants a long-lived attacker: the very lane the others want cleared. |
| Young Brock, Old Brock | Which enemy their neighbours mark. Young Brock: front, two at most. Old Brock in B2: their B2, for four. |
| The Lodger | Who counts as next door. B2 has four neighbours; F1 and F4 have two. |
| Wick, Brother Wolf, Grizel | Adjacent in the row, so their hits follow the leader's mark. Choose the leader by its quarry, then build the pack round it. |
| Old Lutra | His back slot picks which of their back three he reaches. |
| The Mountain Glutton | Back, across nothing that will reach it. |
| The Laird | Makes every one of your slots a marking decision. |

**Scouting, both ways.** You read their board as it fought last round. They read yours, and a Hunter board is easy to read.

- Moving their carry out of your Sable's lane works only if they guess right, and whatever they move *into* that slot becomes her quarry instead.
- The stronger answer is a wall: put a 1/10 Hunker across your Quarry unit and it spends the fight there. Then you choose: aim again where you think the wall went, or give that Hunter a different lane.
- Leaving a lane empty starves a Quarry Hunter of a mark, but it costs them a body. Birds' Nests leave lanes empty on a timetable.
- Bots currently shuffle about half their units between rounds (playtest B). That makes Quarry look like a coin-flip against bots, for the wrong reason. Bots must hold carries still, and a Hard bot should respond to visible lanes, before the tribe can be judged. The all-seats-scout test (every bot reads every board) comes first: if everyone reads everyone, Quarry may turn into a guessing game.

**A turn, round 9.** The scout shows their board: F1 a 6/6, F2 a 4/12 Hunker wall, F3 a 10/8, F4 a 3/3, B2 a 24/30 carry, B1 and B3 small engines.

1. Sable to F3: her quarry, the 10/8, has more Attack, so she's 5/3. She trades into it: a Take.
2. Little Nip to F4 across the 3/3: an easy Take, 1 gold.
3. F2 is their wall, and that's the Toll-Bard's lane: it swings every cycle and won't faint, so he collects 3 gold while his own swings bounce off.
4. Wick to F4 instead of Nip? Then he joins Sable's attack (F3 comes first) and she kills the 10/8 for sure, but the 3/3 goes unmarked. You weigh a sure Take against a second one.
5. Old Lutra to B2: their 24/30 carry is his quarry, and he can reach it in the first cycle. He won't kill it alone, but every hit softens it for later.
6. Next round they'll have moved the carry. So will you.

---

## Where the economy comes from

On the owner's two points: every tribe has some economy, and the best kind rewards "being in that type of strategy" (02h, 02i). Each source pays for something the tribe does anyway, and they don't all want the same lane.

| Source | Kind | How it plays | Better for |
|---|---|---|---|
| **Little Nip** | 1 gold next turn per Take | Aim him at something he can clear. Easy early, when boards are small; 0.70 Takes a fight aimed at turn 4, falling to 0.38 by turn 6. | Anyone who scouts |
| **Old Lutra** | 1 gold per back-row Take | Late in the fight, only if you get through. About 0.7 a fight across a back unit. | Boards that break the front row |
| **The Toll-Bard** | Gold per quarry attack, up to 3 | Paid by the enemy you *don't* kill. Fights your other Hunters for lanes. | Long fights; when you're behind |
| **Mistress Russet** | A card, 1 cheaper, from their board | Selection and denial, not gold. Lets a Hunter splash another tribe and steal a triple piece. | Late, when your shops are thin |
| **Madame Ermeline** | Cheaper upgrade per Take; gold at tier 6 | Tempo, use it or lose it next turn. | Wide Quarry boards, many Takes |

**Tribe verdict.** Modest, and it **tracks winning**: Take rates fall as boards widen, and a losing board makes fewer Takes. The Toll-Bard is the counterweight, paid best when the enemy is strong, so he belongs in the core set. On the owner's warning about economy that funds someone else's scaling (02h): Nip is the only source that ports to any board, and he's in band. Everything else needs Hunters standing when their quarry falls.

---

## Three ways to build

### 1. Open Season (the front hunt: mark, kill, cash in)

```
F1 Little Nip (golden)   F2 Sable          F3 Mistress Russet     F4 Grizel
       B1 Madame Ermeline        B2 The Mountain Glutton     B3 Old Lutra
```

- **Turns 1-3.** Nip and a second Quarry unit. Place them across from what the scout shows. Bank the Take gold.
- **Turns 4-6.** Sable for their big hitters, Russet for the card you want. Start poaching the triples they're building.
- **Turns 7-9.** Ermeline, then level quickly on Takes. Lutra in the back across their protected carry.
- **Turn 10+.** The Glutton grows on each Take and swings last; Grizel joins Russet's attacks, and every pack kill makes both of them permanently stronger.
- **Wins by.** Choosing which enemies faint, and being paid each time. Against a giant, it takes everything around it and wins the fight on bodies left.
- **Loses to.** Walls across your Quarry units (Hunker, Shell, Bristle); empty lanes from fliers and gaps; boards so big that no quarry faints.

### 2. The Sett (the back-row hunt: flush their B2 and pounce on it)

```
F1 Any wall        F2 The Lodger          F3 Wick                F4 The Toll-Bard
       B1 The Lodger          B2 Old Brock           B3 The Mountain Glutton
```

- **Turns 1-4.** Young Brock lends his mark to two plain bodies beside him. You lose little early, and learn to read their front row.
- **Turns 5-7.** Two Lodgers. They pounce whenever a neighbour's quarry is hit.
- **Turns 8-9.** Old Brock to B2. F2, F3, B1 and B3 all take their B2 as quarry and can reach it anywhere. Your F2 Lodger swings at their back-row carry second in the first cycle, with Wick joining. Then the pounces start: B1 and Wick off F2, the F2 Lodger off B1, the Glutton off Wick. Their carry, which expected to fight last, takes a pile of hits before it moves, and each pouncer takes its hit back.
- **Turn 10+.** The Toll-Bard across their sturdiest front attacker for 3 gold a fight. The Laird if you find him: every remaining unit gets a mark too.
- **Wins by.** Their back row, normally the safest place on the board, faints first.
- **Loses to.** An empty B2, or a swallow or Start of Combat kill that removes it, leaves the whole sett with no quarry. Hunker on their B2 halves every hit. Bristle stings each pouncer. Killing Old Brock early doesn't undo the marks, but it takes away the Pounce.

### 3. The Pact (the front exchange: three hits, one counter-hit)

```
F1 Sable              F2 Brother Wolf       F3 Grizel            F4 Young Brock
       B1 Old Lutra             B2 Brother Wolf        B3 Wick
```

How one cycle goes: Sable leads into her quarry and Brother Wolf joins. Brother Wolf doesn't lead, so F2 is skipped. Grizel leads into the quarry Young Brock lent her (his across, their F4), and Brother Wolf joins again. In the back, Lutra leads into his quarry wherever it stands, and the second Brother Wolf joins; Wick leads at random, and that Brother Wolf joins him too. Six units' Attack lands in four exchanges, and only the leaders take counter-hits.

- **Turns 1-4.** Wick just after a Quarry unit. Even 2 extra Attack per attack on the aimed target wins early trades.
- **Turns 5-7.** Brother Wolf between two leaders.
- **Turns 8-9.** Grizel. Every pack kill grows the leader and joiners by +1 Attack for good. Pick leaders whose quarry the pack can kill.
- **Turn 10+.** A second Brother Wolf in B2. Young Brock in F4 gives Grizel an aimed lane.
- **Wins by.** Killing a mid-sized carry in one exchange that only one of your units pays for.
- **Loses to.** Bristle on the quarry (the leader takes every prick); wide boards where focused damage is overkill; Cleave or splash that hits the pack together; gaps that cut adjacency.

---

## With Hedgerow, Fairies, Oozes, Birds, Bog folk and neutrals

**Hedgerow folk.**
- *Feeds Hunters:* the Sergeant-at-Conkers' and Choirboy Tobias's pings and thrown Acorns finish a Hunter's quarry, and that's a Take if the Hunter stands. Young Brock lends marks to Hedgerow bodies.
- *No refill farm:* Mrs Burdock's Kits and Earwig-style summons that land in the dead unit's slot aren't marked. One quarry, one Take.
- *Against Hunters:* Hunker (Old Delver) and Bristle (Miss Prickett, Dr Urchin) are the best walls to put across a Quarry unit. A Pack leader takes every prick.
- Snug and Cold Frame reward standing still; Quarry rewards moving. A mixed board has to choose who stays.

**Fairies.**
- *Feeds Hunters:* Belladonna Sprite gives Nightshade to the enemies across from the slots in front of her, which are the quarries of your front Hunters. The tribe's strongest cross-tribe pairing.
- Hedge Witch's Hex lands on the enemy across from her, so she and a Quarry Hunter work side by side, never on the same slot.
- Rings stay on your slots: re-aiming a Hunter each turn gives up its Ring. That's a decision.
- *Against Hunters:* a Changeling that swaps your Hunter's quarry onto your side ends the mark (rule 7). Shy units leave when buffed, so Grizel's permanent Attack sends them home: don't pack them.

**Oozes.**
- *Feeds Hunters a little:* the Belly itself is a Take when it faints, but what comes out isn't quarry. Russet poaching an Ooze takes only the Ooze's card.
- *Against Hunters:* Hasty Pudding swallows the enemy across at the bell. If that's your Hunter, it's gone for the fight. If it swallows your Hunter's quarry, the mark is lost and nobody gets a Take.

**Birds.**
- Nest Eggs can't be quarry, so Birds starve Quarry units. Scout the timetable: a lane is full on the turn a bird lands.
- Mag Pye steals text "first of all", before the bell. Across Sable, she takes Quarry and marks Sable herself. Across Old Brock, she takes the lending.
- Mother Goose strikes the enemy across each Nest. A Hunter standing on a Nest has that same enemy as quarry, so Goose's kills become Takes. A tight but real Bird-Hunter board.
- The Seven Whistlers' halving isn't an attack, but a halved quarry is easier to finish.

**Bog folk** (the other lane tribe).
- **Mire beats quarry.** A Mired Hunter swings at the toad. If the toad is also its quarry, it's a straight duel.
- A Mired wolf can join only an attack on the toad; a Mired pouncer can pounce only at the toad.
- Their mud stays on the slot; your mark stays on the animal. Moving a unit answers Bog folk; walling answers you.

**Neutrals, spells and heroes.**
- **Turnip Scarecrow** stalls the first attack of the enemy across (its status is renamed `stalled`). Across your Quarry Hunter, it costs your first swing.
- **Wormwood Charm** ("the enemy across from a unit has half its Attack"): cast on a Quarry Hunter, its quarry swings at half while it stays across.
- **Poacher's Path** (first attack hits the back row) and quarry are both the attacker's own text: quarry first if its quarry is legal, otherwise the path.
- **Ichneumon Wasp** in a pack: its joined damage marks the leader's target. Pack spreads odd text onto your aim.
- **Mole Cricket** and **Whirligig Beetle** move units but never marks: your Hunters keep their quarry through any swap.
- **Sexton Beetle** and Hunters both pay for deaths, of different sides.
- **Heroes.** Mother Snare (name an enemy slot for your first attacker) is a Hunter hero; her aim wins for that one attack. Little King Wren is very good with Sable. Dame Hoolet (back row first) suits Old Lutra, who has reach, and suits other back Hunters badly. Jack-in-the-Green swaps your rows mid-fight; marks hold.

---

## Weak against

- **Walls across your lanes.** Quarry is mandatory: a Hunker or Bristle unit across your hitter wastes it all fight.
- **Empty lanes.** Fliers away, Hedgerow gaps, swallows. No mark, no Take.
- **Being read.** Your Hunters are visible in the scout; a thoughtful opponent walls them.
- **Removal at the bell.** A swallow, a Changeling or a Start of Combat kill on your quarry ends that Hunter's plan, and the Sett's whole plan if it hits Old Brock's mark.
- **Huge stat leads.** Aim doesn't matter if no quarry faints. Position text needs close fights (position test guideline 5).
- **Losing streaks.** Takes, Poach and Ermeline pay best when you're winning. A behind Hunter has poor economy, apart from the Toll-Bard.

---

## Where it could loop or run away

| Risk | What stops it, or what to do |
|---|---|
| **Refill Takes** (the draft's slot rule gave Nip 2-3 Takes a fight across an Ooze or summoner) | Closed: the mark is on the unit, and nothing summoned is marked unless a card says so. |
| **Dead Hunters keeping their claim** | Closed: the Hunter must be on the board. Otherwise every Take rate rises 1.3-2.5x [costing]. |
| **Golden Toll-Bard** (draft: 6 gold a fight; two goldens, 12) | Capped at 3 gold a fight. Lever: 3 times per player per fight. |
| **Grizel and Brother Wolf** grow three units per pack kill | Attack only (2.4 SP a fight, permanent). Lever: leader only (+21%). Bench this: it's the tribe's one lasting engine. |
| **Brother Wolf** joining twice a cycle without counter-hits | Costed at 3/4 (+17%, edge). Lever: 2/4 (-1%) if the bench says he's still strong. P's counter-hit-on-every-join version measured under, so it isn't used. |
| **The Glutton** on a board that makes many Takes | Combat-only. With the Laird, 4-6 Takes make it +8/+8 to +12/+12 for one fight. Acceptable as a tier 5 finisher. |
| **Poach and triples** | Your tier or lower, pool copies only, one per Take in Russet's lane. |
| **Pounce chains** | Each unit pounces once a cycle; the chain ends. |
| **The Sett's first-cycle pile-on** | Four hits on their B2 before it moves is the build's point. Old Brock is costed for it at 2/5 (+10%, with Pounce guessed). Lever: the grant gives Pounce to back-row neighbours only. |
| **Ermeline at tier 6** | Gold, capped at 2 (golden 3). |
| **The Laird** | Your side only, +1/+1 to Hunters with a quarry. Logged over at 4/6 (+29%), like Cut-and-Come-Again: tier 6 is hollow, and a 3/5 (+14%) would read as nothing. |

**Riskiest card: Old Brock.** He's the only card that puts several units onto a back-row target in the first cycle, and his price rests on a guess for Pounce. If the Sett deletes back rows on the bench, try in order: Pounce to his back-row neighbours only; no +1 Attack; reach only for the unit in front of him.

**Second riskiest: the Laird.** The position test turned down `across_targeting` for both sides (search on old boards fell below the rule of thumb). The Laird now touches your side only, so the opponent's attacks stay random. Test Laird mirrors for fight length and win-rate swing.

---

## Variations to try

**On Quarry:**

- **Lanes** (the draft's rule). "Attacks the enemy in its slot's lane, whoever stands there." Reads the slot at each attack. Rejected: it farms refills and copies Bog folk's binding to the ground.
- **Stalk.** "While its quarry can't be attacked, this skips its turn and gains +2 Attack this fight." A back-row hunter that waits and then strikes hard: time-bounded waiting, which the owner allowed (02i).
- **Run Down.** "After its quarry faints, the enemy now across becomes its quarry." A card that does mark a refill, on purpose, once.
- **Bounty.** "At the bell, the highest-tier enemy is the Bounty. A Take on it pays double." A lobby-wide hunt for the biggest prey.

**On Take:**

- **Credit only the killer.** Safer, less positional: the Hunter must strike the blow.
- **Trophies.** A Take leaves a Trophy on your slot (+1 Attack for whoever stands there). A slot effect, so this risks Ring territory.

**On the badgers:**

- **Dig Out** (the feel critic's Old Brock). "Start of Combat: move the enemy across to their nearest empty front slot." Pulls their back row *out* instead of reaching in. Uncosted, and moving an enemy into a slot leans toward the column, which Great beasts own on file.

**Similar to, in one line each:**

- Quarry: Galaxy's across-duel text and Magic's "attacks each combat if able", aimed by position and held on one animal.
- Take: Galaxy's Hunt and Battlegrounds' "after this kills", but credited by mark, not by blow.
- Pack: the library's Swarm (25), and Magic's banding.
- Pounce: Hearthstone's "attacks immediately", triggered by your own aim.
- Poach: Hearthstone's Rogue "burgle" cards, here from their board and the shared pool.
- Toll: no close match. A pinball bumper that pays per hit.

---

## Engine needs beyond `engine.md`

**Already data:** `across` selector; `gold` with `when: next_turn`; `buff` with `duration: combat`; `start_of_combat`; `upgrade_discount`; `add_card` with `from_pool`; `relocate` event for side changes; immediate attacks (9.4.12).

| Need | For | What |
|---|---|---|
| **Bell step** | Quarry, the badgers, the Laird (and Bog folk's patches) | A new first phase of Start of Combat, after `first_of_all`, run for both sides on one snapshot. Own Quarry marks first, then lenders in reading order. Event `quarry_marked` (`hunter`, `quarry`). |
| **Quarry state** | All Quarry text | A combat unit field `quarry` (enemy uid), cleared on that unit's death, side change (`relocate` with a new side) or swallow. Never set after the bell unless a card says so. |
| **Targeting precedence** | Quarry | One table in `Combat`: Mire lock > own text (quarry, Swoop, Poacher's Path) > must-be-attacked > random. Quarry target legal under 9.5.1 unless the unit has `reach`. |
| **Reach** | Old Lutra, Old Brock | A flag letting a unit attack its quarry in either row. |
| **Lend quarry** | Young Brock, Old Brock, the Laird | A bell effect: give `quarry` = the lender's across unit to units with none, over a selector (`adjacent`, `neighbours`, `friendly`). |
| **`on_take` trigger** | Take text, Ermeline, the Glutton | Fired in death resolution when a dying enemy is the quarry of a friendly Hunter still on the board (including one dying in the same step). First such Hunter in reading order is the subject; `other` is the dead unit, with `row` and `card`. A per-fight `takes` count per side. |
| **Joint attack** | Pack, Brother Wolf, Grizel | One exchange with a leader and joiners: joiners deal damage in the same step, counter-damage to the leader only, joiners flagged as attacked. A `joined` field on the attack event. Brother Wolf: once per neighbour per cycle, and doesn't lead while a neighbour can. Mired joiners only onto their maker. |
| **Pounce** | The Lodger, Old Brock | `on_damage_dealt` to a neighbour's quarry, from any friendly source, then an immediate attack that ignores rows and Taunt, with a per-cycle used flag. |
| **`on_quarry_attacks`** | The Toll-Bard | Fires when this unit's quarry makes any attack. `per_fight_max`, in gold for the golden. |
| **Poach** | Mistress Russet | After the fight, take a pool copy of the dead unit's base card (tier at most yours) into an extra next-turn shop slot that survives refreshes and returns to the pool at End of Turn. Nothing if the pool is out. |
| **Takes into upgrade cost** | Madame Ermeline | `upgrade_discount` per the fight's `takes` count, up to 3, applied after other discounts, floor 0; `gold` instead at tier 6, capped. |
| **Permanent buff from a fight event** | Grizel | Permanent Attack for leader and joiners of a killing pack attack, sent back after the fight. |
| **Ghosts** | All | Nothing special: marks read the ghost board at the bell. |

**Screens and bots.**

- **Marks on the board.** Before the bell, the tray draws a paw-print on each enemy a Hunter will mark (on the scout panel, from last round's board) and a line back to the Hunter. During the fight, the paw-print stays on the quarry wherever it moves. Pack draws a bracket over the row.
- The fight log needs "Marked", "Take", "Poached" and "Pounce" lines.
- Poached shop cards need a mark (a fox's paw on the card) and the words "from your last opponent".
- `get_state`: `next_opponent_last_board` already gives the scout. Add `takes_last_fight`, `poached` (shop indices) and, in fights, each unit's `quarry`.
- **Bots** need a cheap assignment step on the scouted board: each Quarry unit to the best enemy for its want (killable for Nip, bigger for Sable, durable for the Toll-Bard, wanted card for Russet). Greedy is enough for Normal. Pack wolves go beside the strongest leader; Old Brock across their back carry. Opponent bots must hold carries still, or Quarry measures as noise.

---

## Review calls

Where the critics agreed, their rewrite is in. Where they split, this is the pick.

- **Signature.** The play critic's mark on the unit, as the orchestrator ruled. The feel critic kept the draft's slot reading; the mark closes the refill farm, survives swaps, and keeps Hunters off Bog folk's ground.
- **Ambush or Pounce.** Play critic's **Pounce**. The feel critic kept Ambush, but striking whoever attacks your neighbour is the inbound counterattack, which belongs to Bog folk. Lodger at costing's 4/4.
- **Young Brock.** Play critic's text (lends his mark), at costing's 1/3. The feel critic's "after the enemy across attacks" reads the slot and the inbound side.
- **Old Brock.** Play critic's text over the feel critic's "dig out" (uncosted, and moving an enemy leans toward Great beasts' column). Costing's 2/5. Reach is for the units he lends to, not for every attacker.
- **The Toll-Bard.** Play critic's fold into Quarry over the feel critic's "enemy across", since Hunters bind units, not slots. Costing's golden cap.
- **Brother Wolf.** Feel critic's text with costing's 3/4 and the stall fix. The play critic's counter-hit version measured under a plain body.
- **The Laird.** Both critics: your side only. Payoff and numbers from costing; 4/6 chosen over 3/5, logged over.
- **Grizel** Attack only, **Lutra** 1 gold and 2/4, **Glutton** 4/5, **Ermeline** tier 6 cap: costing.
- **Names.** Tod Scrapling is now **Little Nip** (Potter's and Disney's foxes are both Tod). Low-Water Jack is now **Old Lutra** (four Jacks). Sable's hook takes the feel critic's line, without the Game of Thrones quote. Brother Wolf loses the saint of Gubbio, a human legend, for a vow on the old oak. **Madame Ermeline** is kept: she's from the medieval Reynard fables, which are public domain and which the play critic ruled fine. Kept (orchestrator, tribes 3): public-domain fable names are allowed, as with Reynard himself.
