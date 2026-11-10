# Mechanics ideas: combat and damage

**Status: goldfish designer draft, 2 November 2026. Not costed.** Numbers on the example units are written by feel; a separate review step costs them. Every keyword name here is a working name.

This answers the owner's ask for "explicit attempts to create different effects than just what exists in Hearthstone Battlegrounds", and "The good mechanics break the system rules" ([2026-11-02f note](../owner-notes/archive/2026-11-02f-new-effects-and-goldfish-designers.md)). The angle is how attacks, damage and death work. Rule numbers refer to [rulebook.md](../rulebook.md); archetype IDs (WIDE, TALL, MEDIUM, STICKY, ECO, SCAM, BURST) refer to [archetypes.md](../archetypes.md).

**How new they are.** 18 mechanics. Four are close variants of an existing keyword, and say so: Bristle (Galaxy's Stinky), Antlers (Galaxy's Ranged), Shoulder (Battlegrounds' Taunt) and Bloodied (Battlegrounds' retired Frenzy). The other 14 have no close match in Battlegrounds or Galaxy that I found.

---

## Two shared rules these mechanics need

Several of the mechanics below change how much damage a hit does, or let a unit not attack. They only read cleanly if they share one rule for each. Both are proposals.

**A. The damage pipeline.** Today a hit deals damage equal to Attack (9.6.1 step 3). With these mechanics, each hit on a unit is worked out in this order:
1. **Split.** Peck turns one attack into several 1-damage hits. Each hit goes through steps 2–5 on its own.
2. **Ignore.** Shrug (N): a hit of N or less does nothing.
3. **Halve.** Hunker, Antlers, Whistle: the hit is halved, **rounded up**. Two halvings on one hit halve twice.
4. **Cap.** Shell (N): the hit is at most N.
5. **Share.** Knot: what is left is spread across the knot.

Rounding up means halving never stops a 1-damage hit. That is deliberate: every damage-reducing mechanic here has a clear answer (many small hits, or a few huge ones), so no wall is unbeatable. A hit-blocking layer (the Battlegrounds stand-in is Divine Shield) would sit before step 1 and block the whole attack, or before step 2 and block one peck; that is a choice for whoever designs it.

**B. Skipping.** When a unit **skips** its attack, it is flagged as having attacked this cycle (9.4.5 step 5) but deals no damage, and its side's turn passes to the next unit that can attack. Skipping costs the side that unit's attack, not a whole turn. *A harsher dial:* a skip uses up the side's turn, so the enemy gets two attacks in a row.

---

## A. Damage taken in parts

### 1. Hunker
- **Rules:** Damage this takes while it is being attacked is halved, rounded up.
- **Bends:** 9.6.1 step 3 (damage equal to Attack). Only applies as the defender; damage from effects and from its own attacks is taken in full.
- **Creature:** Badger. A badger in its sett is the classic thing you can't dig out; the Folio's "faded gentry" and "Bathhouse Veterans" both suit a stubborn defender.
- **Archetype:** STICKY, and MEDIUM front-liners.
- **Example:** *Sett Warden*, Tier 3, 2/7. Hunker.
- **Fun against:** Big hitters are wasted on it, but a swarm of 1-Attack tokens or a Peck unit hits it at full value, so WIDE boards and BURST pings are the answer. The badger also hits back when it attacks, unprotected.

### 2. Antlers *(close variant: Galaxy's Ranged, which takes no retaliation at all)*
- **Rules:** Damage this takes while it is attacking is halved, rounded up. This includes damage reflected at it during its attack.
- **Bends:** 9.6.1 step 3 (the exchange is symmetric).
- **Creature:** Red deer stag. It leads with its antlers, so it takes the blow on bone. It suits a Great beasts front carry.
- **Archetype:** TALL (a front carry that trades up many times).
- **Example:** *Rutting Stag*, Tier 4, 6/5. Antlers.
- **Fun against:** A Hunker defender halves the stag's damage while the stag halves the badger's, so the trade is slow for both. Quick defenders strike it first, and random damage effects ignore it, so the stag isn't safe outside its own attacks.

### 3. Shrug (N)
- **Rules:** Hits of N damage or less deal no damage to this.
- **Bends:** 9.6.1 step 3 and 9.6.3: some damage events do nothing at all.
- **Creature:** Bison. Thick fleece and a huge frame; the Folio's Bison Elders are "immovable tanks" whom "nothing moves".
- **Archetype:** STICKY and TALL. A built-in answer to WIDE.
- **Example:** *Bison Elder*, Tier 5, 4/10. Shrug 2.
- **Fun against:** Your token army bounces off it, which is a clear puzzle with a clear answer: bring one big hitter, a SCAM kill, or a debuff that lowers Shrug. Peck does nothing to it at all.
- **Golden:** doubles N under 7.3.5 (Shrug 4), which is a large jump. Worth checking.

### 4. Shell (N)
- **Rules:** No single hit deals more than N damage to this.
- **Bends:** 9.6.1 step 3: the Attack of the attacker stops mattering above N.
- **Creature:** Snail (in the Folio's species list). A shell doesn't care how hard you hit it, only how often.
- **Archetype:** STICKY. The answer to TALL, the mirror of Shrug.
- **Example:** *Grove Snail*, Tier 3, 1/9. Shell 3.
- **Fun against:** Your 40-Attack carry does 3 a hit, which feels terrible until you bring the answer: Peck, a wide board, or BURST pings. It makes the counter loop in archetypes.md §2.2 sharper (STICKY beats TALL).
- **Golden:** doubling N makes Shell *weaker*. Golden Shell probably needs its own rule (keep N, or halve it). Question for the owner.

### 5. Peck
- **Rules:** When this attacks, its damage to the target is dealt as that many separate 1-damage hits. Retaliation is normal.
- **Bends:** 9.6.1 step 3 (one damage event per attack) and 9.6.3 (deaths are checked after each event; here the hits land together and deaths are checked after the last).
- **Creature:** Great spotted woodpecker. It drums, it doesn't punch.
- **Archetype:** An answer to STICKY. It goes straight through Hunker, Shell and Knot, strips a one-hit blocking layer with one peck, and is useless against Shrug.
- **Example:** *Drumming Woodpecker*, Tier 3, 4/3. Peck.
- **Fun against:** Every peck is a hit, so against a hedgehog with Bristle 1 a 4-Attack woodpecker takes 4 back and usually dies. The interactions are the fun: players learn quickly which walls a woodpecker opens and which it bounces off.

---

## B. Damage reflected

### 6. Bristle (N) *(close variant: Galaxy's Stinky, which reflects to a random enemy)*
- **Rules:** Whenever an enemy unit deals damage to this in an attack (attacking it or defending against it), deal N damage to that unit. Bristle damage never triggers Bristle.
- **Bends:** 9.6.1: adds a damage event after the exchange and before death resolution, so a hedgehog that dies still pricks.
- **Creature:** Hedgehog, as the owner suggested ("Maybe the hedgehogs do that: the thorn effect"). The Folio's "losing racers" take, where the hare is always beaten by the hedgehog, gives a natural rival in Headstart below.
- **Archetype:** STICKY; a front wall that trades twice. Strong against WIDE (1-Health tokens die attacking it).
- **Example:** *Hedgerow Hedgehog*, Tier 1, 1/3. Bristle 1. *Hedgehog Apothecary*, Tier 4, 2/6. Bristle 3.
- **Fun against:** It punishes many small attacks, so it is the one wall where swarming is wrong. Hit it once, hard. Damage from effects (BURST pings) isn't reflected; whether it should be is a dial (question 5).
- **No loops:** Bristle damage can't trigger Bristle, so two hedgehogs can't ping each other forever.

### 7. Grudge
- **Rules:** When an enemy unit damages this, that enemy is marked. This attacks marked enemies first, even in the back row, and deals +2 damage to them.
- **Bends:** 9.5.1 (back-row protection) and 9.5.5 (random target).
- **Creature:** Rook and crow. Crows really do remember faces and hold grudges; the Folio has "Rook courts" that judge other birds, and the Rook parliaments that "punish the strongest enemy".
- **Archetype:** SCAM, and back-row reach. Archetypes.md gives back-row reach to Birds' Swoop and Great beasts' Trample; this is a third way in, one that the enemy turns on themselves.
- **Example:** *Rook Magistrate*, Tier 3, 3/4. Grudge.
- **Fun against:** The enemy decides who gets marked. Hit the rook with your back-row carry and the rook comes for it; hit it with a token and it wastes its grudge on the token. Players learn to feed a crow something cheap.

---

## C. Skipping an attack on purpose

### 8. Slumber
- **Rules:** While asleep, this skips its attacks, and gains +1/+1 each time it skips. It wakes, for the rest of combat, when it takes damage or when no other friendly unit can attack.
- **Bends:** 9.4.5 (a unit that can attack, does) and 9.4.6.
- **Creature:** Hazel dormouse, which "sleeps over half the year" (Folio hook), and the Marmot Cantons' hibernators who "wake stronger".
- **Archetype:** TALL. In the back row it is protected while it sleeps, so it grows every cycle the front holds.
- **Example:** *Hazel Dormouse*, Tier 2, 1/3. Slumber. *Seven Sleepers' Dormouse*, Tier 5, 3/6. Slumber; it gains +2/+2 instead.
- **Fun against:** Wake it early. Random damage effects ignore rows (9.5.6), so one 1-damage ping on turn one of the fight wakes it tiny. Against a board with no pings, it is a clock: kill the front fast before the dormouse gets big.

### 9. Whistle
- **Rules:** This never attacks. Each time its place in the attack order comes, it whistles instead: the next enemy attack deals half damage to its target, rounded up.
- **Bends:** 9.4.5 and 9.4.6: a unit that takes a turn in the order to do something other than attack. Units with 0 Attack are normally just skipped.
- **Creature:** Marmot. Marmots stand up and whistle an alarm; the Folio's "whistle-sentries who raise the alarm at everything".
- **Archetype:** MEDIUM and STICKY, as back-row support. It turns a protected back slot into steady defence.
- **Example:** *Marmot Lookout*, Tier 2, 0/4. Whistle.
- **Fun against:** Halving rounds up, so 1-Attack tokens lose nothing to it; and one whistle only covers one attack, so a side with many attacks per whistle wins. Kill the front quickly and the marmot is exposed with no Attack.
- **Stalemates:** a board left with only Whistle units can't attack, and the fight ties (9.9.2). Last Word below interacts with that.

### 10. Mire
- **Rules:** An enemy unit damaged by this skips its next attack.
- **Bends:** 9.4.5: the enemy's attack order is changed from outside.
- **Creature:** Common toad, and the Bog folk. Mud and bog water slow anything that wades in; the Folio's Fen Tigers sabotage and flood.
- **Archetype:** MEDIUM and STICKY. It also works as an anti-TALL tool: when a carry attacks a toad, it loses its next attack.
- **Example:** *Mudwallow Toad*, Tier 2, 2/4. Mire.
- **Fun against:** Quick attackers kill the toad before it deals damage, so it never mires them. Many small attackers make a single toad's mire matter less. Players can see clearly what went wrong: "my bear got stuck in the mud".

---

## D. Rewarded when something else is attacked

### 11. Alibi
- **Rules:** Whenever an enemy attacks and this was one of the units it could have targeted, but it chose another, this gains +1/+1.
- **Bends:** 9.5.5: the random target choice becomes a trigger for the units it didn't pick.
- **Creature:** Fox. The Folio's "Reynard's lawyers, talk their way out of any fight". It was there, but it wasn't involved.
- **Archetype:** WIDE (more friendly candidates, more triggers) and MEDIUM.
- **Example:** *Reynard's Clerk*, Tier 2, 2/3. Alibi. *Reynard, Esquire*, Tier 5, 4/5. Alibi; your other Foxes also gain +1/+1.
- **Fun against:** It rewards the enemy for having a full front row, so attacking it first matters but is random. A must-be-attacked effect on another unit (the Battlegrounds stand-in is Taunt) makes the fox a legal target never chosen, which is a strong pairing. *Variant for the back row:* "whenever a friendly unit is attacked while this can't be targeted" rewards a protected back unit instead.

### 12. Shoulder *(close variant: Battlegrounds' Taunt, though it redirects after the target is chosen)*
- **Rules:** Once per cycle, when an enemy attacks a unit adjacent to this, this becomes the defender instead.
- **Bends:** 9.5.5 and 9.6.1: the defender changes after targeting, before the "when attacked" step, so the new defender's triggers fire and the original's don't.
- **Creature:** Brown bear. It puts its shoulder in the way. It suits the Folio's "honey monks" and "sleeping king".
- **Archetype:** STICKY and TALL; it guards a carry next to it.
- **Example:** *Bear Warden*, Tier 4, 3/9. Shoulder.
- **Fun against:** Only once a cycle, and only for its row neighbours, so gaps beside it (8.2.2) switch it off. Put the bear on F1 and it only guards F2. The enemy learns to attack twice into the bear's neighbours.

---

## E. Sharing damage

### 13. Knot
- **Rules:** Damage dealt to a Knotted unit is split as evenly as possible among all your Knotted units. Any leftover point goes to the unit that was hit.
- **Bends:** 9.6.3: a unit's Health is no longer only its own; Knotted units tend to die together.
- **Creature:** Rats, from the Folio's Rat King: "tails have knotted into one gossiping hive-mind", "shared HP and buffs across a knot". Archetypes.md gives a similar "Linked" to Oozes; one tribe should own it, and the Rat King is the source folklore.
- **Archetype:** WIDE and MEDIUM.
- **Example:** *Knotted Rat*, Tier 2, 2/3. Knot. *The Rat King*, Tier 6, 5/5. Knot. Your Knotted units have +1 Health for each Knotted unit.
- **Fun against:** The knot looks impossible to crack, then collapses all at once. A single big hit is spread out, but every hit counts, so Peck and wide boards wear the whole knot down. Killing effects (SCAM) that destroy instead of damaging cut the knot one rat at a time.

---

## F. Overkill

### 14. Gorge
- **Rules:** When this kills a unit by attacking it, this gains Health equal to the excess damage.
- **Bends:** 9.6.3: excess damage below 0 is normally lost. Here it is a resource.
- **Creature:** Wolverine, the "mountain glutton" (Folio seed "The Gluttons").
- **Archetype:** TALL, a front carry that grows by fighting.
- **Example:** *Glutton Wolverine*, Tier 4, 6/4. Gorge.
- **Fun against:** It grows most when it kills tiny tokens, so WIDE feeds it. The counter is to put sturdy medium units in front that die to exactly its hit, or a hedgehog whose Bristle punishes each meal. Trample (archetypes.md, Great beasts) uses excess damage by space; Gorge uses it on the attacker.

---

## G. Attack order

### 15. Headstart
- **Rules:** This makes one attack before either side's first attack, after Start of Combat. Then it attacks in normal order. Each time it attacks, it loses 1 Attack.
- **Bends:** 9.2.1 (who attacks first) and 9.4.2 (attack order).
- **Creature:** Hare. The fastest runner who tires and loses the race (Folio: "Losing racers, forever beaten by hedgehogs"; Aesop's tortoise).
- **Archetype:** BURST spice and early tempo. It strips a blocking layer or a token before the fight proper starts.
- **Example:** *March Hare*, Tier 1, 3/1. Headstart.
- **Fun against:** A hedgehog in front gives the old story: the hare's first attack lands on Bristle and it dies. Otherwise wait it out; it fades. If both sides have Headstart units, the side that attacks first goes first.

### 16. Quick
- **Rules:** In an exchange, this deals its damage first. If that kills the other unit, this takes no damage from it.
- **Bends:** 9.6.1 step 3 and 9.6.2 (damage is simultaneous). If both units are Quick, the exchange is simultaneous again.
- **Creature:** Stoat. It kills with one fast bite; the Folio's stoat "war-dance troupe" hypnotises its prey.
- **Archetype:** TALL and SCAM. A Quick carry trades for free against anything it can one-shot.
- **Example:** *Ermine Duellist*, Tier 3, 4/2. Quick. Works attacking and defending.
- **Fun against:** Big-Health units take the bite and hit back. Bristle still fires (the hedgehog was dealt damage), so a hedgehog is a cheap answer. Precedent: Magic: The Gathering's first strike; Battlegrounds and Galaxy don't have it.

---

## H. Survival, ties and stalemates

### 17. Bloodied *(close variant: Battlegrounds' retired Frenzy, "the first time this takes damage and survives")*
- **Rules:** Bloodied triggers once, the first time this unit's Health drops to half its maximum or lower and it survives.
- **Bends:** 9.6.3: adds a threshold between full Health and death.
- **Creature:** Wild boar. In hunting lore a wounded boar is the most dangerous animal in the forest.
- **Archetype:** TALL and STICKY.
- **Example:** *Wounded Tusker*, Tier 3, 3/6. Bloodied: double this unit's Attack.
- **Fun against:** Kill it in one hit and it never triggers; chip it and you get the angry version. Peck and wide boards chip it into the angry version. The threshold stays half on a golden (7.3.5).

### 18. Last Word
- **Rules:** If a death resolution would leave both boards empty and this is among the dying, it survives with 1 Health instead. If combat would end because neither side can attack, this gains +1 Attack and combat goes on.
- **Bends:** 9.9.1 and 9.9.2: both ways a fight ties.
- **Creature:** Wren. The folk tale: the wren hid on the eagle's back and flew highest, and was crowned king of birds for being the last one up (Folio hook "A small unit rides a big one").
- **Archetype:** STICKY and SCAM. Mostly a tie-breaker that turns draws into wins.
- **Example:** *Jenny Wren*, Tier 2, 1/2. Last Word.
- **Fun against:** It turns the end of a close fight into a race: kill the wren before your last unit trades. Whistle-only boards and Hunker walls that would stall are broken open by it. The 200-attack limit (9.10.1) still ends any fight that runs on.

---

## Interactions at a glance

The mechanics form small counter loops on purpose, so players can learn them. **[judgement]**

| This | Beats | Loses to |
|---|---|---|
| Peck | Hunker, Shell, Knot, one-hit blocking layers | Shrug, Bristle |
| Shrug | WIDE tokens, Peck | One big hitter, SCAM |
| Shell | TALL carries | Peck, WIDE, BURST |
| Hunker, Whistle | Big hitters | 1-Attack swarms, Peck, BURST |
| Bristle | WIDE, Peck, Headstart | One big hit, Antlers |
| Quick | Small and medium defenders, Mire | Big Health, Bristle |
| Gorge | WIDE (eats tokens) | Sturdy medium units, Bristle |
| Slumber | Slow fights | Pings that wake it early (9.5.6) |
| Grudge | Back-row carries that attack | Being hit by a token |

## Questions for the owner

1. **Rounding.** Halving rounds the damage up (so 1-damage hits always land). Is that the right default for every halving mechanic, or should some round down?
2. **Skipping.** Should a skipped attack cost the side only that unit's attack (proposed) or the side's whole turn?
3. **Golden Shell.** Doubling Shell's N makes a golden Shell weaker. Keep N on goldens, or make golden Shell halve it?
4. **Knot or Linked.** Rats (Hedgerow folk) or Oozes for shared damage? The Rat King is the folklore source.
5. **Bristle and effects.** Should Bristle reflect damage from an enemy unit's effects (pings), or only from attacks?
</content>
</invoke>
