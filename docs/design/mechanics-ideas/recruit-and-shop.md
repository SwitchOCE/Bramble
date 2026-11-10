# Mechanics ideas: the Recruit Phase

**Status: goldfish ideas, 2 November 2026. Not costed, not decided.** Written blind to the power budget, as the owner asked: "explicit attempts to create different effects than just what exists in Hearthstone Battlegrounds", and "The good mechanics break the system rules. They change them" ([2026-11-02f note](../owner-notes/archive/2026-11-02f-new-effects-and-goldfish-designers.md)). Every number on an example unit is a guess by feel. Balance is someone else's job.

**Angle.** Buying, selling, refreshing, freezing, upgrading, the hand, triples and goldens, Tavern spells, gold kept over turns, the shared pool and the next opponent. Each mechanic is a turn-to-turn engine or a choice, and each says how it **ends within a turn**, because Bramble has no recruit timer ([rulebook](../rulebook.md) 3.1.2).

**Names are stand-ins too.** Keyword names here are working names. Rule numbers are [rulebook.md](../rulebook.md). Archetype IDs (ECO, WIDE, TALL, MEDIUM, STICKY, SCAM, BURST, and the golden-chasing enabler) are from [archetypes.md](../archetypes.md) §1.2–1.3.

**Close variants.** 4 of the 18 are close to something Battlegrounds or Galaxy already does, and say so: Cold Store (a stronger Freeze), Hibernate (Galaxy's Mysterious Egg, Battlegrounds' Lockbox), Rehearse (Battlegrounds' hand-buff lines), Mimic (Galaxy's Mirror Mirror).

**Two assumptions the designer followed.**
- Recruit position text reads where a unit **fought from** or where it stands at End of Turn, never the moment of a buy or a cast, so moving units back and forth is never the play. This is a proposal in archetypes.md §3, rule 2, not a decided rule; the designer followed it.
- Anything that reads the shared pool or another player's board depends on how async play handles the pool and opponents, which is open (2.1.4, 2.1.5). Those entries say so.

## At a glance

| # | Keyword | Recruit system it bends | Creature | Archetype | Variant? |
|---|---|---|---|---|---|
| 1 | Cache | Gold kept, no interest (4.1.3) | Red squirrel | ECO | |
| 2 | Thrift / Revel | Banking is neutral (4.1.2–4.1.3) | Ants / cicadas | ECO, MEDIUM | |
| 3 | Upkeep | Start of turn (3.2.1) | Shrew | TALL, tempo | |
| 4 | Wager | Combat pays only in hero damage (10.1) | Otter | ECO, tempo | |
| 5 | Mimic | Units come from the pool or effects (4.3.1, 5.3.6) | Jay | Golden chasing | Galaxy Mirror Mirror |
| 6 | Pawn | Sell value (4.3.3) | Jackdaw | ECO, TALL | |
| 7 | Barter | Price, hand, "when played" (4.2.1, 7.2.3) | Fox | MEDIUM, WIDE | |
| 8 | Aisle | The shop ignores position (6.1) | Badger | ECO, MEDIUM | |
| 9 | Cold Store | Refresh replaces everything; freeze ends (4.4.1, 4.5.3) | Wolverine | TALL, golden chasing | Freeze |
| 10 | Fast | No timer, so refresh is always right (3.1.2, 4.4) | Heron, olm | TALL | |
| 11 | Hibernate | Units on the board fight (9.1.2) | Dormouse | TALL | Egg, Lockbox |
| 12 | Dig Down | Tier only rises (4.6.1) | Mole | WIDE, golden chasing | |
| 13 | Rehearse | Hand cards are inert (3.4.2) | Frog chorus | MEDIUM, TALL | Hand buffs |
| 14 | Foundling | Triples need 3 of the same (7.3.1) | Fairy changeling | Golden chasing | |
| 15 | Pair | Triples need 3; goldens double (7.3.1, 7.3.5) | Swan | TALL, STICKY | |
| 16 | Brew | Spells can't triple (6.1.5) | Toad apothecary | MEDIUM | |
| 17 | Endangered | Pool counts are hidden plumbing (5.1.2, 5.3) | Capercaillie | TALL | |
| 18 | Migrate | A unit is on the board or in hand (3.4.2, 8.3) | Stork | ECO, WIDE | |

---

## Gold kept over turns

### 1. Cache

- **Rules.** Once per turn, you may bury up to 3 gold in this unit; it has +1 Health for each buried gold. At the start of your next turn you dig it all up plus 1, unless this died in the last combat: then you dig up half (rounded down) and the rest sprouts into a 1/2 Oak Seedling in your hand.
- **Bends.** 4.1.3 (holding gold earns nothing): Cache is a small, capped interest. Also 9.1.1 (combat doesn't touch the recruit side): a death in combat changes next turn's gold.
- **Creature.** The red squirrel scatter-hoards and forgets a share of its nuts, which sprout. The Folio's Acorn Exchange ("forgotten deposits later sprout into free oaklings").
- **Archetype.** ECO.
- **Example.** *Nutkin Teller*, Tier 2, 1/2, Red Squirrel. "Cache (3)."
- **Fun to play against.** Killing the squirrel robs the bank. Its Health grows with the deposit, so a fat squirrel is a target worth reaching, and Birds or Trample that reach the back row get a reason to.
- **Ends.** One deposit per Cache unit per turn, capped at 3, and the payout comes next turn. The +1 is per unit, not per gold buried, so banking more doesn't earn more.

### 2. Thrift / Revel

- **Rules.** *Thrift:* End of Turn: if you have more gold than you started the turn with, do the effect. *Revel:* End of Turn: if you have 0 gold, do the effect.
- **Bends.** 4.1.2–4.1.3. Carry-over makes banking free and neutral; these put a board reward on each side of the choice, so "save or spend" becomes a build identity.
- **Creature.** Aesop's ant and grasshopper, the Folio's "The Hive and the Carnival": thrifty ants and bees against a cicada brass band.
- **Archetype.** Thrift: ECO turning into MEDIUM. Revel: MEDIUM and tempo.
- **Examples.** *Granary Ant*, Tier 3, 2/4, Ant. "Thrift: give your back-row units +1/+2 permanently." *Cicada Bandleader*, Tier 2, 3/2. "Revel: give this and the units behind it +2/+1 permanently."
- **Fun to play against.** You can read a Thrift board by its weak early fights and know it will spike later; a Revel board hits hard now but has no bank to recover from a bad turn.
- **Ends.** One check at End of Turn, with no counter. Thrift can't fire on a turn you spend more than your income; Revel needs the last gold gone.

### 3. Upkeep (X)

- **Rules.** At the start of your turn, choose: pay X gold, or this unit Starves (half Attack, rounded down) until you next pay.
- **Bends.** 3.2.1 (start of turn gives gold, never takes it) and 4.1: a recurring cost on a body.
- **Creature.** The shrew "must eat every few hours" and attacks fast (Folio hook); the Redwall shrew guerrillas.
- **Archetype.** Tempo for any comp; a cheap carry for TALL early.
- **Example.** *Pygmy Shrew Berserker*, Tier 1, 4/3. "Upkeep (1)."
- **Fun to play against.** Upkeep boards punch above their tier early, then feel the bill. When you meet a starved shrew, you know that player is short on gold.
- **Ends.** One payment per Upkeep unit, once per turn. No trigger, no loop.

### 4. Wager (X)

- **Rules.** At End of Turn you may stake up to X gold on your next fight. Win: get double at the start of next turn. Tie: get it back. Lose: it's gone. You make at most one wager a turn, at your highest Wager value.
- **Bends.** 10.1. A fight pays out only in hero damage; Wager pays it in gold too. It uses the next-opponent information you already have (2.3.3).
- **Creature.** The Norse otter's ransom and its cursed gold; the Folio's otter smugglers and cursed-gold keepers.
- **Archetype.** ECO and tempo: it turns a board that is ahead into gold.
- **Example.** *Ransom Otter*, Tier 3, 3/3. "Wager (3). After you win a wager, this gains +1/+1 permanently."
- **Fun to play against.** Beating a board that bet on itself takes their gold as well as their health. The damage caps (10.1.4) make early bets cheap, so early wagers are a statement.
- **Ends.** One stake per turn, capped by X, and the payout is fixed at double.
- *Async:* in snapshot play the "fight" is against a recorded board; the wager still works, but it is a bet on your board, not a duel.

### 5. Mimic *(close variant: Galaxy's Mirror Mirror copies keywords from the enemy across)*

- **Rules.** At the start of your turn, this becomes a copy of the unit that was across from it in your last fight (8.2.6): base stats, not golden, keeping Mimic and its own buffs. If that slot was empty, it stays as it is.
- **Bends.** 4.3.1 and 5.3.6. Units come from the pool or from your own effects; Mimic takes one from another player's board. The copy is Created and counts toward triples (7.3.3).
- **Creature.** Jays imitate the calls of other birds; a Folio "noisy sentinel".
- **Archetype.** Golden chasing (archetypes.md §1.3): a mimic can be the third copy of a unit you saw your opponent run.
- **Example.** *Mocking Jay*, Tier 4, 2/2, Bird. "Mimic. Has +2/+2."
- **Fun to play against.** Your best unit gets borrowed, which is flattering, and where you put it decides what they can borrow. It reads the slot the jay fought in, so it can't be aimed by moving it in the Recruit Phase.
- **Ends.** Once per turn, at the start of it.
- *Async:* the copied unit may come from a lobby with other tribes. Whether that's allowed depends on 2.1.5.

---

## Buying and selling

### 6. Pawn

- **Rules.** You may sell a unit with Pawn for 3 gold instead of 1. It goes into an extra Pawn slot at the end of your shop, frozen, with its buffs. Buy it back for 4 before the end of your next turn, or it is forfeit and returns to the pool.
- **Bends.** 4.3.3 (sell value), 6.1.1 (shop size) and 4.5 (freeze).
- **Creature.** The Folio's corvid crime family: "jackdaws run the pawnshop".
- **Archetype.** ECO (a loan that lands an upgrade or a triple a turn early); TALL (pawn the feeders for the carry's big turn).
- **Example.** *Jackdaw Pawnbroker*, Tier 2, 2/3, Bird. "Your other units have Pawn."
- **Fun to play against.** You meet boards that pawned something to spike: thinner this fight, with a hole where a unit was. Forfeits put copies back into the pool for everyone.
- **Ends.** One Pawn slot. Buying back costs 1 more than the loan, so a pawn cycle always loses gold.

### 7. Barter

- **Rules.** Once per turn, instead of buying, swap one of your board units with a unit in your shop. The shop unit takes its slot directly, and your old unit goes into that shop slot with its buffs; it loses them if the shop refreshes.
- **Bends.** 4.2.1 (units cost 3), 7.2.3 (units enter through the hand and trigger "when played"): a bartered unit skips the hand and its play effects. The new unit takes the old one's origin (4.3).
- **Creature.** The Folio's fox "rag-and-bone traders" who scavenge what others throw away.
- **Archetype.** MEDIUM and WIDE: cheap pivots when the shop shows your tribe.
- **Example.** *Rag-and-Bone Fox*, Tier 3, 3/3, Fox. "Barter. After you barter, the new unit gains +1/+1 permanently."
- **Fun to play against.** Barter boards change shape fast, so last turn's snapshot is a weak forecast of this one.
- **Ends.** Once per turn per Barter unit. No gold changes hands, and a buffed unit left in the shop costs the normal 3 to take back.

### 8. Aisle

- **Rules.** Shop cards line up with your board slots in reading order: card 1 with F1, card 5 with B1. A unit's aisle is the slot it fought from in your last combat; Aisle text acts on the shop card in that aisle, each time the shop fills.
- **Bends.** 6.1: the shop ignores position. Now combat position is also shop position. Free moves (8.3.3) gain a cost, since moving changes next turn's aisle.
- **Creature.** The Folio's Sett Gentry, badger landlords whose tenants "pay rent to stand near them"; a high street of stalls in front of the sett.
- **Archetype.** ECO and MEDIUM.
- **Examples.** *Sett Landlord*, Tier 2, 2/5, Badger. "Aisle: that card costs 1 less (minimum 1)." *Market Hedgehog*, Tier 4, 3/4. "Aisle: that unit has +2/+2."
- **Tier gate for free.** The shop has 4 cards at Tier 1 and 7 at Tier 6 (6.1.1), so the back row's aisles open only at Tier 4 and up. Back-row landlords are a late plan.
- **Fun to play against.** A landlord in the front row for the discount is a tough unit you have to chew through. Hiding it in the back costs its owner shop value until Tier 4.
- **Ends.** One effect per shop card per fill, and a discount never goes below 1 gold.

### 9. Cold Store *(close variant of Freeze)*

- **Rules.** Once per turn, put one shop card in Cold Store. It stays through refreshes and turns, gains +1/+1 at the start of each of your turns, and takes up a shop slot until you buy it.
- **Bends.** 4.4.1 (refresh replaces every card), 4.5.3 (the freeze ends each turn) and 5.3.2: a copy kept out of the pool for many turns.
- **Creature.** The wolverine "caches meat in snow" (Folio species notes).
- **Archetype.** TALL (ripen a carry before buying it); golden chasing (hold the third copy).
- **Example.** *Snow-Cache Wolverine*, Tier 3, 4/3. "Cold Store. Units you buy from Cold Store are Bought and keep their growth."
- **Fun to play against.** A unit that has been ripening for five turns lands on their board as a surprise. In a live lobby a stored copy is one fewer for your triple.
- **Ends.** One stored card per player, and it grows only at the start of a turn, by a fixed amount.

---

## Refreshing and upgrading

### 10. Fast (action)

- **Rules.** End of Turn: if you didn't do the named action this turn (refresh, buy or sell), this gains the effect. Each turn in a row adds +1 to it; doing the action resets the streak.
- **Bends.** 3.1.2 and 4.4. With no timer, the usual best play is to refresh until gold runs out; Fast puts a board price on every refresh. It is the shop form of the owner's "Things that don't attack, but get rewarded every time they skip".
- **Creature.** The heron "stands still, then stabs"; the olm "can go years without food" (Folio).
- **Archetype.** TALL and late scalers; the counter-plan to ECO's long turns.
- **Examples.** *Still-Water Heron*, Tier 2, 3/2, Bird. "Fast (refresh): +1/+1 permanently." *Olm Sleeper*, Tier 5, 2/8. "Fast (buy): +3/+3 permanently."
- **Fun to play against.** Fast players take short turns and grow slowly, so you know to beat them early. Their board stays small while it grows.
- **Ends.** One check at End of Turn, and the streak adds a fixed +1 each turn.

### 11. Hibernate (N) *(close variant: Galaxy's Mysterious Egg, Battlegrounds' Lockbox)*

- **Rules.** This unit sleeps through your next N upgrades. While asleep it stays in its slot but combat treats the slot as empty, and each upgrade gives it +3/+3 permanently. It wakes after the Nth.
- **Bends.** 9.1.2 (each unit fights from its slot) and 9.2.1 (sleepers aren't counted for who attacks first). Upgrading becomes a trigger.
- **Creature.** The dormouse "sleeps over half the year"; the marmot hibernates (Folio hooks). The Dormouse Clockmakers' guild "hibernates by law".
- **Archetype.** TALL.
- **Example.** *Clockwork Dormouse*, Tier 2, 1/1. "Hibernate (2)."
- **Fun to play against.** Their board fights a body short now, and you can see the sleeper in the snapshot, so you know the size of what is coming.
- **Ends.** A game has at most five upgrades, so the growth is bounded with no counter.

### 12. Dig Down

- **Rules.** Once per turn, lower your tier by 1 until the end of the turn, and refresh your shop for free at that tier. You can't upgrade while dug down.
- **Bends.** 4.6.1 (tier only rises) and 6.1.2 (draws use your tier). Late boards can fish for low-tier copies and token makers.
- **Creature.** The Folio's mole miners' union, digging down into an old seam.
- **Archetype.** WIDE (late access to Tier 1–2 token makers) and golden chasing (better odds on low-tier triples).
- **Example.** *Mole Foreman*, Tier 4, 3/5, Mole. "Dig Down." Golden: two tiers.
- **Fun to play against.** Late boards turn up with golden Tier 1s nobody expected.
- **Ends.** Once per turn per mole, with one free refresh each, and the tier returns at End of Turn.

---

## The hand, triples and spells

### 13. Rehearse *(close variant: Battlegrounds' hand-buff lines)*

- **Rules.** End of Turn: if this is in your hand, it gains +1/+1 permanently, or +2/+2 if another Rehearse card is in your hand too.
- **Bends.** 3.4.2 (cards in hand do nothing) and 7.1: hand space becomes a growth space that competes with board slots.
- **Creature.** The Folio's Frog Chorus, a swamp opera company, and the fox travelling theatre: they rehearse offstage before opening night.
- **Archetype.** MEDIUM (a chorus that debuts together) and TALL.
- **Example.** *Understudy Toad*, Tier 3, 2/2, Frog. "Rehearse. When you play this, give your other Frogs +1/+1 for each turn it rehearsed (up to 4)."
- **Fun to play against.** A thin board for a few turns and then opening night. You can see it coming, because the board stays a slot or two short.
- **Ends.** Once per turn at End of Turn, and the 10-card hand caps it.

### 14. Foundling

- **Rules.** In your hand or on your board, this counts as a copy of any non-golden unit for a triple. When it completes one, the golden also gains the Fairy type. If it could complete two triples, you choose.
- **Bends.** 7.3.1 (a triple needs three copies of the same unit).
- **Creature.** The folklore changeling, a fairy child left in a cradle in place of a human one.
- **Archetype.** Golden chasing (archetypes.md §1.3), which no tribe owns yet.
- **Example.** *Cradle Changeling*, Tier 3, 2/2, Fairy. "Foundling."
- **Fun to play against.** Goldens arrive a turn or two early and with an odd extra type, so Fairy payoffs reach into other tribes.
- **Ends.** Each Foundling is used up by one triple. The golden sells for 1 (4.3.4).

### 15. Pair

- **Rules.** Two copies of a Pair unit combine into a Bonded pair: one unit with both copies' stats and buffs, whose triggers fire twice. It isn't golden and gives no Triple Reward; a third copy makes it golden as normal, and it keeps the pair's stats.
- **Bends.** 7.3.1 (three copies), 7.3.5 (golden doubles numbers) and 7.3.6 (Triple Reward).
- **Creature.** Swans pair for life (Folio species notes), and the Children of Lir and Six Swans tales.
- **Archetype.** TALL early, and STICKY when the text protects.
- **Example.** *Mute Swan Paladin*, Tier 2, 2/4, Bird. "Pair. Start of Combat: give the units in front of this +1 Health this combat."
- **Fun to play against.** An early 4/8 that isn't golden, and a known spike when the third swan lands.
- **Ends.** Each merge uses up cards, and a pair can't re-pair.

### 16. Brew

- **Rules.** While a unit with Brew is on your board, two copies of the same Tavern spell in your hand combine at once into a Strong copy: double its numbers, same cost. A Strong spell can't brew again.
- **Bends.** 6.1.5 (spells can't triple) and the spell pool counts in 5.1.2.
- **Creature.** The Folio's toadstone apothecaries, "witch-healers with jewels in their heads".
- **Archetype.** MEDIUM, through spell lines.
- **Example.** *Toadstone Apothecary*, Tier 3, 2/4, Toad. "Brew. After you cast a Strong spell, this gains +2/+2 permanently."
- **Fun to play against.** Their spell turns hit twice as hard but come less often.
- **Ends.** Two cards make one, and it doesn't chain. *Flag for balance:* whether Brew should double gold or refresh spells.

---

## The shared pool

### 17. Endangered

- **Rules.** This has +1/+1 for each of its copies missing from the pool (bought, shown in any shop, or held by anyone), counted at Start of Combat.
- **Bends.** 5.1.2 and 5.3. The pool's copy counts stop being hidden plumbing and become a public stat.
- **Creature.** The capercaillie, "a forest-grouse icon in decline"; the bison "saved from extinction" (Folio).
- **Archetype.** TALL.
- **Example.** *Last Capercaillie*, Tier 5, 4/4, Bird. "Endangered." With all 9 Tier 5 copies out it is 13/13.
- **Fun to play against.** A real dilemma. Hate-buying a copy feeds theirs; leaving the copies lets them triple.
- **Ends.** It's a count, not a trigger, capped by copies per tier (5.1.2).
- *Async:* only means something if lobbies share a pool (2.1.5).

### 18. Migrate

- **Rules.** End of Turn: you may send this away. It leaves the board, and its slot is empty. At the start of your turn after next it returns to its slot (or the nearest empty one, 8.4.2) with +2/+2 and a bundle: a Created random unit of your tier in your hand.
- **Bends.** 3.4.2 and 8.3. A unit is normally either on the board or in hand; a migrant is neither for two turns, and it frees a slot without selling.
- **Creature.** The Stork Post: storks "bring the babies" and are "mysteriously absent every winter" (Folio).
- **Archetype.** ECO and WIDE.
- **Example.** *Stork Courier*, Tier 3, 3/3, Bird. "Migrate." Golden: two bundles.
- **Fun to play against.** You catch them a body short while the storks are away, and they come back with a delivery.
- **Ends.** One return per stork every two turns. Bundles are Created and sell for 0 (4.3.3), so there is no gold loop.

---

## Notes for whoever picks these up

- **Overlap with the tribe longlist.** Cold Store and Pawn touch the Hedgerow folk's hoarding identity; Rehearse sits next to Bog folk's Frogspawn (delayed cards, archetypes.md §4.2); Fast and Hibernate both give TALL a time-based fuel. Pick one of each pair if the overlap matters.
- **Golden chasing has three candidates here** (Foundling, Pair, Mimic). It is the enabler with no owner in archetypes.md §1.3.
- **Pool and opponent mechanics** (Endangered, Mimic, Wager) need the async model (2.1.5) before they can be judged.
