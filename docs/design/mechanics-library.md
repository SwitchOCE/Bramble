# Mechanics library

**Status: ideas, 2 November 2026. Nothing is adopted.** Built by `tools/research/build_mechanics_library.py` from the designer and review files in `mechanics-library-src/`; change those and rerun the build, not this file. Four goldfish designers rewrote the 65 mechanics of [mechanics-ideas.md](mechanics-ideas.md) (the first-round record) with example units, a play scene and variations, following the owner's directions ([02h](owner-notes/2026-11-02h-checkpoint-read-through.md), [02i](owner-notes/2026-11-02i-reactions-are-directions.md)). A rules reviewer and a budget reviewer then checked them; budget flags use only the tier curve and tolerance bands ([02g](owner-notes/2026-11-02g-stage-2-checkpoint-scope.md)). The owner reads the formatted page, mechanics-library.html.

## A. How much damage a hit does

### 1. Hunker — NEW

When an enemy attacks this badger, it takes only half the damage.

- **Rules.** Hunker. When an enemy attacks this, the damage this takes from that attack is halved, rounded up. Damage it takes while it is attacking, splash damage aimed at another unit, reflected damage and damage from effects are taken in full.
- **Bends.** 9.6.1 step 3: the damage exchange is no longer equal when this is the defender.
- **Creatures.** Badger. A badger in its sett is the classic animal you can't dig out. Folio: the faded gentry and the Bathhouse Veterans.. **Archetypes.** STICKY, MEDIUM
- **Example units.**
  - *Sett Digger*, Tier 1, 1/4, Hunters. Hunker.
  - *Sett Warden*, Tier 3, 2/8, Hunters. Hunker. Whenever this survives being attacked, your back-row units gain +1 Attack this combat.
  - *Old Brock*, Tier 5, 4/9, Hunters. Hunker. Units adjacent to this have Hunker.
- **How they play.** Sett Warden goes in F2 or F3, in front of your back-row carries. Every big hit it soaks at half value makes the units behind it hit harder when their turn comes. Old Brock in the middle of the front row gives Hunker to both neighbours, so a row of three badgers halves every attack the enemy makes until one of them falls. Hunker pairs with Shoulder (a bear that takes hits for its neighbours) and with back-row units that gain from waiting, such as Bide.
- **Why run it.** It makes your front row last against one or two huge attackers, which buys time for whatever you are growing behind it.
- **Scene.** Turn 3, you buy Sett Warden and put it in F2, in front of your dormouse and heron. Turn 7, you face a TALL board with a 22/18 Great beast. In the fight, the beast hits your Warden (now 2/14) for 11, not 22, and the Warden lives. Your heron in B1 gains +1 Attack. The beast's next hit would kill it, but your front units have used those turns to kill the beast's feeders, and your heron comes out of Bide at 8 Attack.
- **Good against.** TALL boards that rely on one or two very large hits. **Weak against.** WIDE swarms and BURST pings, which lose little or nothing to halving; and the badger takes full damage when it attacks.
- **Variations.**
  - **Dig In.** Hunker until this attacks for the first time in a combat. After that it takes full damage.
  - **Badger Sett (slot effect).** When you play this, the slot it is in gains 'The unit in this slot has Hunker' for the rest of the game.
  - **Thick Hide.** Damage this takes from attacks is reduced by 2, to a minimum of 1. This flips the matchup: good against WIDE, poor against TALL.
- **Similar to.** Like 'defend' stances in turn-based RPGs that halve incoming damage.
- **Owner's direction.** 'Hunker. This is one of the ones I mentioned. This seems cool.' (02h). Direction: example cards.
- **Designer's response.** Followed. Three badgers that build on each other, plus a slot-effect version that uses fixed slots and a flat-reduction version that has the opposite matchup, for comparison.
- **Open.** Against Peck (X), is each strike halved on its own? Proposed: yes. Rounding up then favours the woodpecker slightly, which is fine counterplay.
- **Open.** The order of Hunker, Shell and other reductions should be set once in the rulebook, not on each card.
- **Rules review (clean).** Works as a Halve handler on a damage query at the unit layer (R1), and the text already limits it to exchange damage as the defender, so splash, thorns and effects land in full. Two small gaps: say Hunker from two sources (Old Brock's aura on a unit that already has Hunker) halves once, and define Sett Warden's 'survives being attacked' as still on the board after that attack's death resolution (9.6.1 step 5). No loop; rounding up means it never stalls alone; one badge, readable.
- **Budget review.** Hunker is cheap to price, but all three badgers carry big bodies on top of it; shrink the bodies and keep the text.
  - *Sett Digger*: edge. T1 1/4: body 5 + Hunker (E89, halve while defending) 0.3 x 4 = 1.2 [guess] = 6.2 vs V(1) 5: +24% (Tier-1 floor +-1 SP = +-20%). Rounding up makes halving weak against Tier-1 hits of 1-2, so it may be nearer 6.0. Change: If the sim agrees: 1/3 (4 + 0.9 = 4.9, -2%).
  - *Sett Warden*: flag over. T3 2/8: body 10 (+25% before text) + Hunker 0.3 x 8 = 2.4 + about 1.5 survived attacks x +1 Attack to about 2.5 back units x 0.75 (back Attack) x 1.4 (combat buff on back units, T04) = 3.9 [guess] = 16.3 vs V(3) 8: +104% (+-15%). Change: 1/4, and the payoff goes to 'the units behind this' (it stands in F2 or F3 in front of the carries, as in the scene): 5 + 1.2 + about 1.2 survived attacks x 1.5 units x 0.75 x 1.4 = 1.9 = 8.1 (+1%).
  - *Old Brock*: flag over. T5 4/9: body 13 + own Hunker 0.3 x 9 = 2.7 + Hunker for about 1.43 neighbours (about 5 Health each at turn 8) x 0.3 x 0.7 while Brock lives = 1.5 [guess] = 17.2 vs V(5) 12: +43% (+-15%). Change: 3/6 (9 + 1.8 + 1.5 = 12.3, +3%).
- **From.** combat 1

### 2. Antlers — VARIANT of Galaxy's Ranged

While this stag is attacking, it takes only half the damage.

- **Rules.** Antlers. While this is attacking, damage it takes is halved, rounded up. 'While attacking' means from the start of its attack to the end of the damage exchange (9.6.1 steps 1 to 4), for each of its attacks, extra attacks included. It includes damage reflected at it during the attack. Damage that lands later, such as from an enemy's death effect, is taken in full.
- **Bends.** 9.6.1 step 3: the exchange is no longer equal when this is the attacker.
- **Creatures.** Red deer stag. It leads with its antlers and takes the blow on bone. Great beasts front carry.. **Archetypes.** TALL
- **Example units.**
  - *Yearling Stag*, Tier 2, 3/4, Great beasts. Antlers.
  - *Rutting Stag*, Tier 4, 6/5, Great beasts. Antlers. After this kills a unit, it gains +2 Attack this combat.
  - *Monarch of the Glen*, Tier 6, 8/8, Great beasts. Antlers. This attacks twice each cycle.
- **How they play.** Rutting Stag is a front carry that wants many trades: each kill makes it bigger, and Antlers means it only pays half for each one. The Monarch's second attack in every cycle doubles how often the halving helps. Antlers likes Bristle defenders less than most attackers do, because the reflected damage is halved too.
- **Why run it.** Your carry can trade into several units in one fight instead of dying to the first big defender.
- **Scene.** Turn 5, you buy Rutting Stag and buff it to 12/14. In the fight it attacks a 10/10 boar: it takes 5, not 10, kills the boar and goes to 14 Attack. Next it hits a 6/8 badger and takes 3. Three trades later it is still standing, where a plain 12/14 would have died on the second.
- **Good against.** Boards of medium units that each hit back hard. **Weak against.** Hunker defenders (both sides halve, so trades are slow), random damage effects, and anything that hits it while it isn't attacking.
- **Variations.**
  - **Lowered Antlers.** The first attack this makes each combat, it takes no damage.
  - **Charge.** While this is attacking, it takes 3 less damage from each hit, to a minimum of 1.
  - **Antler Clash.** Antlers. When this attacks a unit with Antlers or Hunker, neither unit halves damage, and both deal double damage.
- **Similar to.** Like a charging knight's lance-and-shield in tactics games, where the attacker takes less counter-damage.
- **Owner's direction.** No reaction to this entry yet. It is the owner's own example (02f): 'You could have something that takes 50% less damage when it's attacking (either it rounds up or down, I don't know).'
- **Designer's response.** Rounded up, so a stag never becomes immune and Antlers against Hunker always finishes.
- **Open.** Rounding up versus down: up keeps every hit worth at least 1, down lets 1-damage hits do nothing. Proposed: up.
- **Rules review (clean).** Works under 9.6.1 with the time window it now states (steps 1 to 4 of each of its own attacks, extra attacks included), and Bristle's prick lands inside that window, so it is halved as the text says. Monarch's two attacks use 9.4.11 and Rutting Stag's kill trigger is 9.7.2 step 1. Antlers against Hunker is slow but finite because both round up; readable.
- **Budget review.** The stags are priced like their bodies plus a small damage cut; the Tier-6 stag is far over because double attack on a big body is expensive.
  - *Yearling Stag*: edge. T2 3/4: body 7 + Antlers (E89, halve while attacking) 0.3 x 4 = 1.2 [guess] = 8.2 vs V(2) 7: +17% (+-15%). Change: If the sim agrees: 3/3 (6 + 0.9 = 6.9, -1%).
  - *Rutting Stag*: flag over. T4 6/5: body 11 + Antlers 0.3 x 5 = 1.5 + '+2 Attack this combat after a kill' (about 0.6 kills x about 0.6 later attacks x 2) = 0.8 [guess] = 13.3 vs V(4) 10: +33% (+-15%). The old line priced the same stag without the kill text at +25%. Change: 5/4 (9 + 1.2 + 0.8 = 11.0, +10%).
  - *Monarch of the Glen*: flag over. T6 8/8: body 16 (+14% before text) + Antlers 0.3 x 8 = 2.4 + attacks twice (Windfury, 0.8 x own Attack = 6.4; Antlers makes the second attack likelier) [guess] = 24.8 vs V(6) 14: +77% (+-15%). Change: 5/5 (10 + 1.5 + 4.0 = 15.5, +11%).
- **From.** combat 2 (marked variant by the designer)

### 3. Shrug — NEW

Small hits bounce off this bison and do nothing.

- **Rules.** Shrug (N). Hits of N damage or less deal no damage to this. A hit ignored this way counts as no hit: it fires no 'when damaged' or 'when hit' effects on either side. Golden: N stays the same (7.3.5, thresholds keep their value).
- **Bends.** 9.6.1 step 3 and 9.6.3: some damage events do nothing at all.
- **Creatures.** Bison. Thick fleece on a huge frame. Folio: the Bison Elders, immovable tanks.. **Archetypes.** STICKY, TALL
- **Example units.**
  - *Bison Calf*, Tier 2, 2/5, Great beasts. Shrug 1.
  - *Bison Elder*, Tier 5, 4/10, Great beasts. Shrug 2.
  - *Herd Matriarch*, Tier 6, 5/9, Great beasts. Shrug 2. Start of Combat: give your other Great beasts Shrug 1 this combat.
- **How they play.** The Calf is an early wall that 1-Attack tokens can't touch. The Elder ignores tokens and pings outright. The Matriarch spreads Shrug 1 to the rest of the herd, so a whole Great beasts board stops caring about chip damage and BURST.
- **Why run it.** It is a built-in answer to WIDE token boards and Start of Combat pings, the comps that usually beat big slow units.
- **Scene.** Turn 8, your scouting says the lobby has a strong WIDE player with dozens of 1/1 and 2/2 tokens. You buy Bison Elder and put it in F2. In the fight, every token that attacks it bounces off and dies to its 4 Attack hitting back. They have to find one big hitter, and they don't have one.
- **Good against.** WIDE swarms, BURST pings and Peck. **Weak against.** One big hitter, SCAM kills, and anything that lowers N.
- **Variations.**
  - **Thick Fleece.** The first 3 hits each combat that deal 2 or less to this are ignored.
  - **Stubborn.** Shrug 1. Whenever this ignores a hit, it gains +1 Attack this combat.
  - **Winter Coat.** Shrug 3 until this takes damage for the first time; then Shrug 0.
- **Similar to.** Like damage thresholds in tabletop games (a vehicle that ignores small-arms fire).
- **Open.** A board with no hit above N can never kill it, so the fight runs to the 200-attack tie (9.10.1). That is the intended counter, but a no-progress rule could end such fights sooner.
- **Open.** Should golden double N? The entry assumed yes (Shrug 4); 7.3.5 as written keeps it at 2.
- **Rules review (needs a ruling).** Works as an Ignore handler (R1), and the text now keeps N on a golden, which matches 7.3.5 (R12) but contradicts the old entry, so the owner should confirm. Needs a ruling on stacking: the Herd Matriarch gives Shrug 1 to a Bison Elder that has Shrug 2, so say the highest N applies, and keep Ignore before Halve in the pipeline or Shrug plus Hunker ignores hits it shouldn't. Stalemate: a board with no hit above N can't kill it and the fight runs to the 200-attack tie (9.10.1); R3's no-progress rule would end it sooner.
- **Budget review.** Shrug is worth little because few hits are small; only the Bison Elder needs a smaller body.
  - *Bison Calf*: in band. T2 2/5 Shrug 1: body 7 + Shrug 1 (E89, ignore hits of N or less: about 0.08 of Tier-2 damage arrives in 1-damage hits) x 5 = 0.4 [guess] = 7.4 vs V(2) 7: +6% (+-15%).
  - *Bison Elder*: flag over. T5 4/10 Shrug 2: body 14 (+17% before text) + Shrug 2 at about 0.15 x 10 = 1.5 [guess] = 15.5 vs V(5) 12: +29% (+-15%). Same as the old line. Change: 3/8 Shrug 2 (11 + 1.2 = 12.2, +2%).
  - *Herd Matriarch*: in band. T6 5/9 Shrug 2: body 14 + own Shrug 2 at about 0.1 x 9 (Tier-6 hits are bigger) = 0.9 + Shrug 1 to about 3 other Great beasts of about 6 Health at 0.05 = 0.9 [guess] = 15.8 vs V(6) 14: +13% (+-15%).
- **From.** combat 3

### 4. Shell — NEW

The first hit on this snail each combat deals at most N damage, then the shell breaks.

- **Rules.** Shell (N). The first time this takes damage in a combat, that damage is capped at N (N is at least 1). Then the shell breaks for the rest of combat. Any damage breaks it, including a 1-damage ping. A Shell unit with N Health or less still dies to a hit of N, so its Health must be raised above N for the shell to save it.
- **Bends.** 9.6.1 step 3: for one hit, the attacker's Attack stops mattering above N.
- **Creatures.** Snail. A shell doesn't care how hard you hit it, only how often.. **Archetypes.** STICKY
- **Example units.**
  - *Garden Snail*, Tier 1, 1/3, Neutral. Shell 4.
  - *Snail-Shell Trader*, Tier 2, 2/3, Neutral. When you play this, give another friendly unit Shell 5.
  - *Roman Snail*, Tier 4, 3/6, Neutral. Shell 7. End of Turn: give your other units with Shell +2 Health permanently.
- **How they play.** The shell number is a Health target. Garden Snail at 3 Health dies to a capped 4 hit, so it is a trap until you give it 2 more Health; after that it shrugs off the first hit of any size. Roman Snail feeds Health to your other shelled units every turn, so they climb past their N. The Trader puts Shell 5 on a unit that already has more than 5 Health, such as your carry, so the enemy's biggest first swing does at most 5.
- **Why run it.** It is a one-hit wall that rewards you for buffing Health, and it stops the enemy carry's first big swing cold.
- **Scene.** Turn 2, you buy Garden Snail (1/3, Shell 4) and a Health buff, and it becomes 1/5. Turn 4, a 9/9 boar hits it: the hit is capped at 4 and the snail lives at 1 Health, so the boar is held up for a full attack. Turn 6, you play Snail-Shell Trader and give your 6/14 carry Shell 5; the enemy's 20-Attack stag hits it for 5, not 20.
- **Good against.** TALL boards and big single hits, for one hit per unit. **Weak against.** Pings and tokens that break the shell cheaply, Peck (the first strike breaks it), and anything when the unit's Health is below N.
- **Variations.**
  - **Hard Shell (the original).** No single hit deals more than N damage to this, all combat. Best on a dedicated low-Health tech unit, such as Grove Snail, Tier 3, 1/9, Shell 3: a TALL carry does 3 a hit, while Peck, WIDE and BURST break through.
  - **Thick Shell.** Shell (N), but it breaks after the second hit instead of the first.
  - **Regrowing Shell.** Shell (N). When this side's attack order starts a new cycle, a broken shell regrows.
- **Similar to.** Like Hearthstone's Divine Shield, but it caps a hit instead of blocking it, so small hits still get through.
- **Owner's direction.** 'Shell seems potentially cool. We could iterate. Maybe a flat number is problematic. Or maybe it operates like Divine Shield in Hearthstone, and the shell breaks after a couple of hits, or maybe just one hit, but it limits the damage to a certain number for the first hit ... If you have a shell unit that has 5 Health but a 7-strength shell, you know you need to buff it to get the power from the shell.' (02h)
- **Designer's response.** Followed: the main text is now the owner's breakable shell, and the units are built around buffing Health past N. Light pushback: the flat cap still works as a narrow tech card (Hard Shell variation), because Peck, WIDE and BURST all break it; it is kept as a variation, not the keyword.
- **Open.** Golden: with a cap, a bigger N is weaker. Proposed: N stays the same on golden (7.3.5); the golden gets its doubled stats only.
- **Open.** Does a hit that Shrug ignores break the shell? Proposed: no, because it counts as no hit.
- **Rules review (needs a ruling).** The owner's breakable version works as a one-time Cap handler (R1), and keeping N on golden is consistent with 7.3.5. Needs rulings: a second Shell on one unit (Snail-Shell Trader onto a Roman Snail) should keep the lower N or not stack; 'the first time this takes damage' needs an answer for simultaneous hits (Swarm joiners, Close Ranks, Cleave), proposed cap the largest and break; and say whether a Knot share breaks it (proposed no, shares aren't hits). Readability: Garden Snail's printed Shell 4 on a 3-Health body does nothing until buffed, which the owner asked for, but the card should say 'needs more than 4 Health' or new players will read it as broken.
- **Budget review.** The owner's first-hit Shell is cheap and fair on the low snails; the Tier-4 Roman Snail is +79% over its tier (band ±25%), and +1 Health a turn instead of +2 brings it back.
  - *Garden Snail*: in band. T1 1/3 Shell 4: body 4 + Shell 4 is blank until buffed (3 Health is under N, and Tier-1 hits are about 2), about 0.3 for later buffs [guess] = 4.3 vs V(1) 5: -14% (floor +-20%).
  - *Snail-Shell Trader*: in band. T2 2/3: body 5 + 'give another unit Shell 5' (a one-off keyword grant, E20 at 0.9: blank on turns 2-4, about 1.5-2 on a late carry facing big first hits, about 1.2 averaged) [guess] = 6.2 vs V(2) 7: -11% (+-15%). It grows with the game, so sim it at turns 8-12 too.
  - *Roman Snail*: flag over. T4 3/6 Shell 7: body 9 + own Shell 7 about 0.5 (6 Health is under N until buffed) + End of Turn +2 Health to about 1.5 other Shell units = s about 3 SP a turn x 0.9 (Health only) = 2.7, over the Tier-4 growth cap of 2.5; c(4) 3.1 x 2.7 = 8.4 [guess] = 17.9 vs V(4) 10: +79% (+-25%, an R03 trigger). Change: 2/4, and End of Turn gives +1 Health (s about 1.5 x 0.9 = 1.35, under the cap; 3.1 x 1.35 = 4.2): 6 + 0.3 + 4.2 = 10.5 (+5%).
- **From.** combat 4

### 5. Peck (X) — NEW *(was Peck)*

This woodpecker strikes its target 2 or 3 times in one attack, splitting its Attack between the strikes.

- **Rules.** Peck (X), where X is 2 or 3. When this attacks, it strikes its target X times instead of once, in one turn of the attack order. Its Attack is split among the strikes as evenly as possible, larger parts first. Each strike counts as an attack: this unit's 'whenever this attacks' effects fire before each strike, and each strike is a separate hit. The target deals its damage back once, with the last strike. If the target dies, the remaining strikes are lost.
- **Bends.** 9.6.1 step 3 (one damage event per attack) and 9.4.3 (one attack per turn).
- **Creatures.** Great spotted woodpecker. It drums; it doesn't punch.. **Archetypes.** MEDIUM, BURST
- **Example units.**
  - *Lesser Spotted Woodpecker*, Tier 1, 2/2, Birds. Peck 2.
  - *Drumming Woodpecker*, Tier 3, 4/4, Birds. Peck 2. Whenever this attacks, give your other Birds +1 Attack this combat.
  - *Yaffle, the Green Woodpecker*, Tier 5, 6/6, Birds. Peck 3. Whenever a friendly unit attacks, deal 1 damage to a random enemy.
- **How they play.** Drumming Woodpecker's buff fires once per strike, so each of its attacks gives your other Birds +2 Attack. Yaffle pings once per friendly attack, three times on its own attack, and again for each Drumming strike. Against Shell, the first strike breaks the shell and the rest land in full; against Hunker, each strike is halved separately and rounds up.
- **Why run it.** It doubles or triples your on-attack effects, and it opens one-hit walls such as Shell.
- **Scene.** Turn 3, you buy Drumming Woodpecker and put it in F1 with two Birds behind. Turn 6, you add Yaffle. In the fight, Drumming attacks a snail with Shell 5: strike one (2 damage) breaks the shell, strike two lands 2. Your Birds gain +2 Attack, and Yaffle pings twice. When Yaffle attacks, it pings three more times before its own strikes land.
- **Good against.** Shell, Divine-Shield-style blocking layers, and Hunker. **Weak against.** Shrug (small strikes do nothing) and Bristle (it pricks back once per strike).
- **Variations.**
  - **Peck (original).** Its damage is dealt as that many 1-damage hits, capped at 5 hits, with the rest added to the last hit.
  - **Flurry.** This unit's first attack each combat has Peck 3. Later attacks are normal.
  - **Scatter Peck.** Peck 2, but each strike picks its own random target among the candidates.
- **Similar to.** Like multi-hit moves in Pokemon (Double Kick, Fury Attack), which split one action into several hits.
- **Owner's direction.** 'I think 10 is probably far too much, because we'd have balance issues. I think Peck would lend itself to on-attack trigger effects: it takes damage normally, but its attacks count as multiple attacks, maybe 2 or 3 ... which is good against things like Shell ... So we can have a look at Peck X, where X is the number of attacks it splits the damage into.' (02h)
- **Designer's response.** Followed: Peck is now Peck (X) with X of 2 or 3, each strike counts as an attack for on-attack effects, and it takes damage back once, normally. The small X also fixes the trigger-limit problem the rules review found. The uncapped original is kept only as a capped variation.
- **Open.** Does the target's 'when attacked' effect fire once or X times? Proposed: once, so only the woodpecker's own effects multiply.
- **Open.** Should the damage back land with the first strike (the woodpecker may die mid-attack) or the last (proposed)?
- **Rules review (needs a ruling).** Works as a split on the dealing side (R1, E90) inside one turn of the attack order. Needs a ruling: deaths are checked after each strike (9.6.3), so if an early strike kills the target the return blow 'with the last strike' never lands, which makes Peck a partial first strike like Quick; say whether that is intended or move the return blow to the first strike. Also say that 'each strike counts as an attack' is for this unit's own effects only: not for enemy 'when attacked', Bystander or Whistle triggers, and not toward the 200-attack limit (9.10.1).
- **Budget review.** Peck X itself is cheap; the two payoff woodpeckers are over because Peck multiplies their 'whenever attacks' text, so their bodies must shrink.
  - *Lesser Spotted Woodpecker*: in band. T1 2/2 Peck 2: body 4 + Peck about 0.5 (E90 split: gains against Divine Shield, Shell and Hunker, loses against Shrug and Bristle; same as the old line) [guess] = 4.5 vs V(1) 5: -10% (floor +-20%).
  - *Drumming Woodpecker*: flag over. T3 4/4 Peck 2: body 8 + Peck 0.5 + '+1 Attack to your other Birds this combat' on each strike: about 1.25 attacks x 2 strikes x about 1.8 other Birds x 0.7 realised = 3.2 [guess] = 11.7 vs V(3) 8: +46% (+-15%). Change: 2/3, text unchanged (5 + 0.5 + 3.2 = 8.7, +9%).
  - *Yaffle, the Green Woodpecker*: flag over. T5 6/6 Peck 3: body 12 + Peck about 0.7 + 1 damage to a random enemy on each friendly attack (about 6 friendly attacks, Peck strikes included, while Yaffle lives x 0.85 x 0.7 for wasted pings at Tier 5 = 4.2) [guess] = 16.9 vs V(5) 12: +41% (+-15%). Change: 4/4 (8 + 0.7 + 4.2 = 12.9, +8%).
- **From.** combat 5

### 6. Knot — NEW

Damage to one Knotted rat is shared out evenly among all your Knotted rats.

- **Rules.** Knot. When a Knotted unit takes damage, after its own reductions, the damage is split as evenly as possible among all your Knotted units, in either row. Any leftover points go to the unit that was hit. The shares are not new hits: the units that receive them apply no reductions and fire no 'when damaged' effects. This breaks back-row protection on purpose. Units that die because a Knot aura is lost die in the same death check.
- **Bends.** 9.6.3: a unit's Health is no longer only its own, and Knotted units tend to die together.
- **Creatures.** Rats. Folio: the Rat King, 'tails have knotted into one gossiping hive-mind'.. **Archetypes.** WIDE, MEDIUM
- **Example units.**
  - *Gutter Rat*, Tier 1, 1/2, Hedgerow folk. Knot. When this dies, your other Knotted units gain +1 Attack this combat.
  - *Knotted Rat*, Tier 2, 2/3, Hedgerow folk. Knot.
  - *Knot Elder*, Tier 6, 5/5, Hedgerow folk. Knot. Your Knotted units have +1 Health for each Knotted unit you have.
- **How they play.** Five Knotted units with the Elder each have +5 Health, and a 20-damage hit costs each of them 4. When the knot finally fails, many rats die at once, and each Gutter Rat that dies makes the survivors hit harder. The Elder dying is the big moment: everyone loses Health together.
- **Why run it.** A wide board that big hitters can't pick apart one unit at a time.
- **Scene.** Turn 4, you have three Knotted Rats and a Gutter Rat in the front row. An enemy 12/12 boar hits one rat: the 12 damage is split 3 each, and nobody dies. Turn 8, you find Knot Elder. Your six rats now have +6 Health each, and the enemy TALL carry needs several swings before anything dies.
- **Good against.** TALL boards that win by killing one unit per big hit. **Weak against.** Peck and WIDE boards (every small hit still counts), and destroy effects that skip damage.
- **Variations.**
  - **Linked (Oozes).** Damage to this is shared only with the friendly units in front of it and behind it.
  - **Tied Tails.** When you play this, choose an adjacent unit. Damage to either is split evenly between the two.
  - **Frayed Knot.** Shares go only to Knotted units in the same row, so back-row protection holds.
- **Similar to.** Like linked enemies that share one health bar in action games.
- **Open.** Overlaps the Ooze 'Linked' idea in archetypes.md 4.1. Pick one, or keep Knot for rats and Linked for Oozes.
- **Open.** Riding or underground units: are they in the knot?
- **Open.** The old example name, The Rat King, clashes with a Galaxy card; renamed Knot Elder.
- **Rules review (clean).** Works as a Share handler at the end of the damage query (R1): shares are not hits, fire no 'when damaged' effects, deliberately pass back-row protection (card text wins, 1.2.1), and aura-loss deaths join the same check. Small gaps: say a share doesn't break a Shell and doesn't feed Scar, and that two Knotted units hit at the same moment (Cleave) split one after the other. Off-slot rats (riding, underground) need R7's occupant table; readable with a drawn rope.
- **Budget review.** Plain Knot is priced at about zero, so the vanilla rat needs a bigger body, and the Elder's N-squared aura needs to become linear.
  - *Gutter Rat*: edge. T1 1/2: body 3 + Knot about 0 net (E91 sharing) + on death, about 2 other Knotted units gain +1 Attack this combat x 0.8 realised x 0.6 chance they are there = 1.0 [guess] = 4.0 vs V(1) 5: -20% (on the Tier-1 floor of +-1 SP). Change: If the sim agrees: 1/3 (5.0, 0%).
  - *Knotted Rat*: flag under. T2 2/3: body 5 + Knot about 0 net (it keeps every rat attacking, but the attacker's overkill is no longer wasted) [guess] = 5 vs V(2) 7: -29% (+-15%). Same as the old line. Change: 3/4 (7, 0%).
  - *Knot Elder*: flag over. T6 5/5: body 10 + '+1 Health per Knotted unit' on every Knotted unit is about N squared Health: N about 4 gives 16 x 0.9 (aura survival) = 14.4 [guess] = 24.4 vs V(6) 14: +74% (+-15%), and it grows as N squared. Same as the old Rat King. Change: 3/3, 'This has +2 Health for each Knotted unit you have' (linear; Knot spreads that Health to every rat): 6 + 8 x 0.9 = 13.2 at N = 4 (-6%), about 15 at N = 5 (+7%).
- **From.** combat 13

## B. Damage back to the attacker

### 7. Bristle — VARIANT of Galaxy's Stinky

Whenever an enemy hurts this hedgehog in a fight, its spines deal damage back.

- **Rules.** Bristle (N). Whenever an enemy unit deals damage to this during an attack (when this attacks or is attacked), deal N damage to that unit after the damage exchange and before deaths are checked. So a hedgehog that dies still pricks. Thorn damage (from Bristle, Curl or any other reflect) never triggers thorn damage.
- **Bends.** 9.6.1: adds a damage event after the exchange and before death resolution.
- **Creatures.** Hedgehog, the owner's suggestion. Rival of the hare in the old race story.. **Archetypes.** STICKY, WIDE
- **Example units.**
  - *Hedgerow Hedgehog*, Tier 1, 1/3, Hedgerow folk. Bristle 1.
  - *Hoglet Mother*, Tier 2, 1/3, Hedgerow folk. Bristle 1. When this dies, summon a 1/1 Hoglet with Bristle 1.
  - *Hedgehog Apothecary*, Tier 4, 2/6, Hedgerow folk. Bristle 3. Your other units with Bristle have +1 Bristle.
- **How they play.** Tokens with 1 Health die just by attacking a hedgehog. Hoglet Mother leaves a pricking baby behind, so the wall takes two kills. The Apothecary raises every hedgehog's Bristle, so a front row of them makes each enemy attack cost its attacker 2 or more Health on top of the exchange.
- **Why run it.** It punishes many small attacks, so it is the one wall where swarming is wrong.
- **Scene.** Turn 2, you play Hedgerow Hedgehog and Hoglet Mother in the front row. The enemy has four 1/1 tokens. In the fight, each token attacks a hedgehog, deals 1, and dies to the prick before it can do anything else. Turn 6, with the Apothecary, a Peck 2 woodpecker that strikes your hedgehog takes 2 pricks of 2.
- **Good against.** WIDE token boards, Peck and Swarm. **Weak against.** One big hit that kills the hedgehog at once, and Antlers (pricks are halved).
- **Variations.**
  - **Spines.** Bristle, but the prick goes to a random enemy instead of the attacker (closer to Galaxy's Stinky).
  - **Quill Shed.** When this dies, deal N damage to the unit that killed it.
  - **Bristle (any damage).** Also fires when an enemy effect damages this; the unit responsible takes N, or a random enemy if no unit is.
- **Similar to.** Thorns in Diablo and World of Warcraft.
- **Owner's direction.** No reaction to this entry yet. It is the owner's own idea (02f): 'Something that deals damage back to the attacker whenever it's dealt damage. Maybe the hedgehogs do that: the thorn effect.'
- **Designer's response.** Kept on hedgehogs. The no-thorns-from-thorns rule covers Curl too, which closes the Bristle and Curl loop the rules review found.
- **Open.** Should Bristle fire on effect damage? It is a dial (the 'any damage' variation).
- **Rules review (clean).** Works: the thorn tag closes R2's loop with Curl, Both Ends and Thicket, and pricking 'before deaths are checked' is a card-text exception to 9.6.3 that Quick's text already relies on. One line to add: splash from a Cleave-style attack counts as damage 'during an attack', so a hedgehog next to the target pricks too; say if that is meant. Golden doubles N (it is damage, not a threshold, 7.3.5); readable.
- **Budget review.** The low hedgehogs fit; the Apothecary is over by about its aura, so it needs a smaller body.
  - *Hedgerow Hedgehog*: in band. T1 1/3 Bristle 1: body 4 + about 1.5 exchanges x 1 damage x 0.85 (E72 on R24) = 1.3 [guess] = 5.3 vs V(1) 5: +6%. Same as the old line.
  - *Hoglet Mother*: in band. T2 1/3 Bristle 1: body 4 + Bristle 1.3 + Deathrattle 1/1 with Bristle 1 (2 x 0.8 = 1.6, plus about 0.5 for its prick) [guess] = 7.4 vs V(2) 7: +6% (+-15%).
  - *Hedgehog Apothecary*: flag over. T4 2/6 Bristle 3: body 8 + about 2 exchanges x 3 x 0.7 (chip damage partly wasted) = 4.2 + '+1 Bristle' to about 2 other Bristle units x 1.5 exchanges x 0.7 x 0.6 while it lives = 1.3 [guess] = 13.5 vs V(4) 10: +35% (+-15%). Change: 2/4 Bristle 3 (6 + about 3.2 on a smaller body + 1.3 = 10.5, +5%).
- **From.** combat 6 (marked variant by the designer)

### 8. Curl — NEW

This hedgehog rolls into a ball: it doesn't attack, it takes half damage, and anything that hits it gets pricked.

- **Rules.** Curl. While another friendly unit can attack, this doesn't attack and damage it takes is halved, rounded down. Whenever an enemy unit or enemy effect hits this, even for 0 damage, the enemy unit responsible takes 1 thorn damage; if no unit is responsible, a random enemy takes it. When no other friendly unit can attack, it uncurls for the rest of combat: it attacks normally and takes full damage.
- **Bends.** 9.4.5: a unit with Attack sits out the attack order. 9.6.1 step 3: the exchange stops being equal.
- **Creatures.** Hedgehog rolled into a ball. Folio: hedge-apothecaries who carry cures on their spines.. **Archetypes.** STICKY
- **Example units.**
  - *Pincushion Hedgehog*, Tier 2, 2/6, Hedgerow folk. Curl.
  - *Hedge Doctor*, Tier 3, 2/4, Hedgerow folk. Whenever a friendly unit with Curl pricks an enemy, your Hedgerow folk gain +1 Attack this combat.
  - *Tightly Wound Hedgehog*, Tier 5, 4/10, Hedgerow folk. Curl. Its thorn damage is 3.
- **How they play.** Pincushion soaks hits in the front row while the Hedge Doctor turns every prick into Attack for the board. When everything else has died, the curled hedgehogs uncurl with all that Attack and finish the fight. Pings and tokens are the worst attackers into it: they deal 0 and still get pricked.
- **Why run it.** A wall that wins by making the enemy hurt itself, and a late finisher once it uncurls.
- **Scene.** Turn 4, you have two Pincushions in F2 and F3 and the Hedge Doctor in B2. The enemy BURST board opens with five 1-damage pings: each deals 0, each pricks a random enemy, and your board gains +5 Attack. Their tokens attack the balls, deal 0 and die to the pricks. When your other units have fallen, the Pincushions uncurl with 7 Attack.
- **Good against.** BURST pings and WIDE tokens. **Weak against.** One big hitter: half of 20 is still 10.
- **Variations.**
  - **Curl (simple).** This doesn't attack while another friendly unit can. Bristle 1. (Built from existing parts, as the entry suggested.)
  - **Brief Curl.** Curl for the first cycle of combat only; then it uncurls.
  - **Prickle Ball.** Curl. When this uncurls, it deals damage equal to the pricks it made this combat to a random enemy.
- **Open.** Overlaps Bristle, Hunker and Bide; it may be better as one unit's text than as its own keyword.
- **Open.** Uncurling needs a clear visual cue.
- **Rules review (broken as written).** Broken for two Curl units with no other attackers, which is the designed Pincushion plus Tightly Wound pair: each one waits only while 'another friendly unit can attack', and whether the other can attack depends on the first, so no consistent answer exists (if both can attack neither does, if neither can both do). Fix: 'While another friendly unit without Curl can attack', and give Curl, Bide and Nocturnal one shared 'waiting' status so they don't keep each other asleep (R3). Also note that pricking 'even for 0 damage' is a deliberate exception to R1's rule that a 0 hit fires nothing, and rounding down here conflicts with the round-up halvings elsewhere (question 1).
- **Budget review.** Halving damage while never attacking roughly doubles a hedgehog's Health, so every Curl body needs to be about half as big, and the Doctor's team-wide payoff should hit one unit per prick.
  - *Pincushion Hedgehog*: flag over. T2 2/6: Attack only once uncurled (about 0.4) + halving rounded down about doubles its Health against attacks, 12 effective Health at 0.7 on a unit that doesn't attack = 8.4 (E89, E83) + pricks about 3 hits x 0.85 = 2.5 [guess] = 11.3 vs V(2) 7: +61% (+-15%). Same as the old line. Change: 1/4 (0.2 + 5.6 + 2 = 7.8, +11%).
  - *Hedge Doctor*: flag over. T3 2/4: body 6 + '+1 Attack to your Hedgerow folk this combat' on every Curl prick. In the build it serves (2 Curl units, about 6 pricks a fight, 4 Hedgerow folk) that is 6 x 4 x 0.5 realised = 12 [guess] = 18 vs V(3) 8: +125% (+-15%). With one Curl unit about 8.3 (+4%); the price is the committed build's. Change: Each prick gives +1 Attack to one random other Hedgerow folk: 6 + 6 pricks x 0.85 x 0.5 = 8.6 (+7%) in a committed build.
  - *Tightly Wound Hedgehog*: flag over. T5 4/10, thorns 3: Attack only once uncurled (about 0.8) + about 20 effective Health at 0.7 = 14 + pricks about 3.5 hits x 3 x 0.7 = 7.4 [guess] = 22.2 vs V(5) 12: +85% (+-15%). Change: 3/5 with thorns 3 (0.6 + 7 + about 2.5 hits x 3 x 0.7 = 5.3 = 12.9, +7%).
- **From.** creatures 1

## C. Not attacking, and stopping attacks

### 9. Bide — NEW

This unit skips its attacks and grows each time, until it wakes up and strikes.

- **Rules.** Bide. While this waits, it skips its attacks. Each time its side's attack order passes over it, it grows. It stops waiting, for the rest of combat, when its wake condition is met or when no friendly unit that isn't waiting can attack. Each Bide card names one wake condition:
- Screen: it waits while a friendly unit stands in a slot in front of it (8.2.1), and gains +2 Attack this combat each time it waits. Only back-row slots have slots in front, so in the front row it never waits.
- Slumber: it waits until it takes damage, and gains +1/+1 this combat each time it waits.
- **Bends.** 9.4.5 and 9.4.6: a unit able to attack declines to, and the pointer moves past it. 9.4.2: the back row's reserve role becomes a wind-up.
- **Creatures.** Grey heron, which stands still, then stabs (Folio: first-strike lancer). Hazel dormouse, which sleeps over half the year; the Marmot Cantons' hibernators who wake stronger.. **Archetypes.** TALL
- **Example units.**
  - *Hazel Dormouse*, Tier 1, 1/3, Hedgerow folk. Bide (Slumber).
  - *Grey Heron*, Tier 3, 1/5, Birds. Bide (Screen). When this stops waiting, it attacks immediately.
  - *Seven Sleepers' Dormouse*, Tier 5, 3/6, Hedgerow folk. Bide (Slumber). It gains +2/+2 instead each time it waits.
- **How they play.** The heron sits in the back row behind two tough front units, such as Hunker badgers or Shell snails. The longer they hold, the bigger it gets, and when its screen falls it strikes at once. Dormice sleep in the back row, where attacks can't reach them while the front lives, and wake only when the fight finally comes to them.
- **Why run it.** A back-row carry fed by time instead of deaths, which makes a sturdy front row pay twice.
- **Scene.** Turn 3, you buy Grey Heron and put it in B2, behind Sett Warden in F2 and a Bison Calf in F3. In the fight, the heron waits through four cycles while the badger and bison hold, reaching 9 Attack. When the Calf dies, its screen breaks, and the heron attacks immediately for 9.
- **Good against.** Slow boards that take many cycles to break your front row. **Weak against.** Boards that break the screen fast (it wakes small) and early pings (one ping wakes a dormouse at once, since random damage ignores rows).
- **Variations.**
  - **Bide (N).** This skips its first N turns, gaining +3 Attack this combat each time. Then it attacks normally. A fixed countdown.
  - **Hibernate.** When you play this, it sleeps for 2 turns: it can't attack in those combats. Then it wakes with +6/+6 permanently. (A time-bound Recruit Phase version, per pillar 13.)
  - **Patient Strike.** Bide (Screen). When this stops waiting, its next attack deals double damage.
- **Similar to.** Like Bide in Pokemon (wait two turns, then strike back), and charge-up attacks in many games.
- **Owner's direction.** 'The Bide stuff's interesting. I like that. Kind of cool. We could explore that.' (02h)
- **Designer's response.** Followed with example cards. The wake rule now reads 'no friendly unit that isn't waiting can attack', so two Bide units can't wait for ever. The waiting is inside one fight and ends by itself, so it stays on the right side of pillar 13; the Hibernate variation tries the Recruit Phase version the owner called cool ('Don't move for 3 turns, then X', 02i).
- **Open.** Grey Heron's 'attacks immediately' can fire in the middle of death resolution when its screen dies. Proposed: it attacks after death resolution ends.
- **Rules review (needs a ruling).** Works as a declined turn: the unit is skipped and flagged (shared rule 2), and the fallback 'no friendly unit that isn't waiting can attack' prevents a lone heron from stalling. Needs a ruling that Curl and Nocturnal count as waiting under that fallback, or a Bide heron and a Curl hedgehog can each wait on the other (R3). Grey Heron's 'attacks immediately' on waking can fire inside death resolution, so queue it after the death pass and before the 9.9.1 check (R5).
- **Budget review.** Bide fits the budget once the heron's body is trimmed; the Tier-1 dormouse sits just over the line.
  - *Hazel Dormouse*: edge. T1 1/3 Slumber, back: body 3.75 + about 1.5 waits at Tier 1 (short fights) x +1/+1 on a back unit, net of skipped attacks = 2.3 (R32) [guess] = 6.05 vs V(1) 5: +21% (floor +-20%). The old line priced it at Tier 2 (-2%); it moved down a tier. Change: If the sim agrees: 1/2 (about 5.0, 0%).
  - *Grey Heron*: flag over. T3 1/5 Screen, back: body 5.75 + about 2 waits x +2 Attack as a combat buff on a back unit (x 1.4) = 4.2, + waking attack 0.5, - back-row attacks it gives up 0.7 = 4.0 [guess] = 9.75 vs V(3) 8: +22% (+-15%). Same as the old line. Change: 1/3 (3.75 + 4.0 = 7.75, -3%).
  - *Seven Sleepers' Dormouse*: edge. T5 3/6 Slumber +2/+2, back: body 8.25 + 2 waits x +2/+2 = 7.2, - 1.5 for skipped attacks [guess] = 14 vs V(5) 12: +16% (+-15%). Same as the old line. Assumes the growth lasts this combat only. Change: If the sim agrees: 3/5 (about 13, +8%).
- **From.** rows 12, combat 8

### 10. Whistle — NEW

This marmot never attacks; on its turn it whistles a warning, and the biggest enemy's next attack deals half damage.

- **Rules.** Whistle. This never attacks, even with 0 Attack. When its turn in the attack order comes, it whistles instead, and that uses its side's turn. A whistle warns of the highest-Attack enemy unit that isn't already warned of (ties at random): that unit's next attack deals half damage, rounded up, to everything it hits, splash included. Then the warning is used up. Whistles don't count as attacks for ending combat: a side whose only units have Whistle can't attack (9.9.1).
- **Bends.** 9.4.5 and 9.4.6: a unit takes a turn in the attack order to do something other than attack. 9.6.1: one enemy attack's damage is halved.
- **Creatures.** Alpine marmot. Sentries whistle an alarm from the rocks. Folio: whistle-sentries who raise the alarm at everything, including clouds.. **Archetypes.** STICKY, MEDIUM
- **Example units.**
  - *Marmot Lookout*, Tier 2, 0/4, Hedgerow folk. Whistle.
  - *Whistle-Watch Marmot*, Tier 3, 1/5, Hedgerow folk. Whistle. When an attack you warned of doesn't kill the unit it hit, give that unit +2 Health this combat.
  - *Alpine Elder*, Tier 5, 2/7, Hedgerow folk. Whistle. Each whistle warns of the two highest-Attack enemies instead of one.
- **How they play.** Put the marmot in the back row, where it can't be attacked while your front lives. Every time its turn comes, instead of a weak attack, it takes the edge off the enemy's best hitter. Whistle-Watch adds Health to whoever survives the softened hit, so your wall gets tougher each time. It stacks with Hunker: a 24 hit halved by the whistle and again by Hunker is 6.
- **Why run it.** Your back row can protect your front row instead of sitting idle.
- **Scene.** Turn 6. Your opponent is TALL: a 24/20 Rutting Stag and a few small feeders. You have Sett Warden (Hunker, 3/14) in F2, a Bison Calf in F3 and Marmot Lookout in B2. In the fight, your front units attack first; then your marmot's turn comes, and it whistles at the stag. The stag attacks your Warden: 24, halved by the whistle to 12, halved by Hunker to 6. The Warden lives. Next cycle the marmot whistles again. Without the marmot the Warden takes 12 a hit and dies on the second; with it, the Warden survives two hits and your front row has time to kill the feeders.
- **Good against.** TALL boards with one huge hitter. **Weak against.** WIDE boards with many similar attackers (each whistle softens only one attack), and any board that kills your front row fast.
- **Variations.**
  - **Alarm Call (original).** The next enemy attack, whoever makes it, deals half damage. Simpler, but often wasted on a token.
  - **Lookout Post.** This never attacks. Enemy attacks against the units in front of this deal 2 less damage, to a minimum of 1. (No timing to follow: a plain aura.)
  - **Sentry Call.** Whistle, but instead of halving, the warned enemy's next attack must target your friendly unit with the most Health.
- **Similar to.** Like a support character's 'defend ally' or 'weaken' action in turn-based RPGs: it spends its turn reducing an enemy hit instead of attacking.
- **Owner's direction.** 'Whistle. I don't quite understand it. I'd need a bit more of an example.' (02h). Direction: example cards and a play scene.
- **Designer's response.** In one line: it is a back-row unit that spends its turns protecting instead of hitting. To make that easy to picture, the whistle now aims at the highest-Attack enemy (the predator the marmot spots), rather than whichever enemy happens to attack next, which was often a token. The original is kept as a variation, and Lookout Post is a version with no timing at all.
- **Open.** Does whistling use the side's turn (proposed, so it is a real trade) or come free, as shared rule 2 suggests?
- **Open.** Should a warning still pending at the end of a cycle carry over? Proposed: yes, until that enemy attacks.
- **Rules review (needs a ruling).** Works with its explicit override of 9.4.6 (it takes a turn even at 0 Attack) and its own end-of-combat line, so two Whistle-only boards end as a tie (9.9.1). Needs rulings: whether a whistle counts toward the 200-attack limit (9.10.1), whether a warned Peck unit halves only its first strike or the whole attack (proposed whole attack), and that a lone marmot still whistles while the enemy keeps attacking. The card reads as one sentence ('On its turn: the strongest enemy's next attack deals half'), which should answer the owner's 'need more of an example'.
- **Budget review.** A whistle saves half of the enemy's biggest hit, which grows with the tier, so the Tier-3 and Tier-5 marmots need smaller bodies.
  - *Marmot Lookout*: in band. T2 0/4: body 4 + about 3 whistles a fight x about 1 damage saved x 0.8 = 2.4 (E89 on the enemy's next hit, R32) [guess] = 6.4 vs V(2) 7: -9% (+-15%). Same as the old line.
  - *Whistle-Watch Marmot*: flag over. T3 1/5: Attack only on retaliation (about 0.5) + 5 + 3 whistles x about 2.5 saved (half of a Tier-3 top hitter's hit) x 0.5 used well x 0.8 = 3.0 + '+2 Health this combat' after about 2 survived warned attacks x 2 x 0.9 x 0.6 = 2.2 [guess] = 10.7 vs V(3) 8: +34% (+-15%). Change: 1/3 (0.5 + 3 + 3.0 + 2.2 = 8.7, +9%).
  - *Alpine Elder*: flag over. T5 2/7: retaliation about 1 + 7 + about 2.5 whistles x 2 enemies x about 4 saved (half of a Tier-5 top hitter) x 0.45 used well x 0.8 = 7 [guess] = 15 vs V(5) 12: +25% (+-15%). The saving grows with the size of the enemy's biggest hit. Change: 1/5 (0.5 + 5 + 7 = 12.5, +4%).
- **From.** combat 9, creatures 13

### 11. Mire — NEW

An enemy that this toad damages gets stuck in the mud and skips its next attack.

- **Rules.** Mire. An enemy unit that takes damage from this, whether this attacks it or it attacks this, skips its next turn in the attack order; the pointer passes to its side's next unit. Mire doesn't stack: a unit already stuck stays stuck once. Extra attacks out of turn ('attacks immediately') are not skipped.
- **Bends.** 9.4.5: the enemy's attack order is changed from outside.
- **Creatures.** Common toad and the Bog folk. Mud and bog water slow anything that wades in. Folio: the Fen Tigers, who sabotage and flood.. **Archetypes.** MEDIUM, STICKY
- **Example units.**
  - *Mudwallow Toad*, Tier 2, 2/4, Bog folk. Mire.
  - *Fen Newt*, Tier 3, 2/5, Bog folk. Ambush (whenever an enemy back-row unit attacks this, this deals its Attack to the attacker first).
  - *Bogland Matron*, Tier 5, 3/7, Bog folk. Mire. Your other Bog folk have Mire.
- **How they play.** Every enemy front-row unit that trades with a toad loses its next turn, and that turn passes to its side's next unit. With the front row stuck, more of the enemy's attacks come from its back row: support units and carries that would rather not trade. Fen Newt is waiting for exactly those attackers and hits them first. The Matron spreads Mire across your whole Bog folk board.
- **Why run it.** It shuts down a carry for a turn, and with the right partners it drags the enemy's fragile back row into bad trades.
- **Scene.** Turn 3, you buy Mudwallow Toad and put it in F2. Turn 5, the enemy's 10/10 bear attacks the toad and gets stuck: next cycle it skips, and the enemy's B1 owl (4/3) takes that turn instead. It attacks your Fen Newt, takes 2 first, then trades and dies. Your toad mired the bear and your newt ate the back row.
- **Good against.** TALL carries (one stuck turn costs them a lot) and boards with attacking back-row units. **Weak against.** Quick attackers that kill the toad first, and WIDE boards, where one skipped attack matters little.
- **Variations.**
  - **Sink.** An enemy damaged by this has -3 Attack until after its next attack.
  - **Deep Mire.** The first enemy this damages each combat skips its next two turns.
  - **Mud Slot (slot effect).** When you play this, its slot gains: 'Start of Combat: the enemy across from this slot skips its first turn.'
- **Similar to.** Like Freeze in constructed Hearthstone (the frozen unit loses its next attack).
- **Owner's direction.** 'Mire's interesting. That's cool, because it makes their backline attack into you. I like that as a tech-card effect. And you could have effects for when the enemy's backline attacks, so you have some counterattack damage or something; you could build into that.' (02h). Then: 'I was just kind of exploring the idea ... If it seems like I'm not asking you to do anything with it, I'm not.' (02i)
- **Designer's response.** No change to Mire. The owner's picture partly holds as written: Mire moves nobody, but each skipped front-row turn passes to the next unit, so more of the enemy's attacks come from its back row. Fen Newt is one 'effect for when the enemy's backline attacks', and Ambush is pitched as its own new mechanic below.
- **Open.** Is it intended that attacking a toad mires the attacker (the damage back counts)? Proposed: yes; that is what makes it anti-TALL.
- **Rules review (clean).** Works as a skip on the enemy's next turn: when chosen to attack, a stuck unit is flagged, loses the mark, and its side picks its next unit or passes (9.4.10), so it can't stall a fight. The text already covers no stacking and out-of-turn attacks; add that Mire still applies when the toad dies in the same exchange. Fen Newt depends on the new Ambush mechanic's ruling; readable.
- **Budget review.** Each skipped enemy attack is worth most of an enemy unit's Attack, so the Tier-5 toad that spreads Mire is well over and needs a small body.
  - *Mudwallow Toad*: edge. T2 2/4: body 6 + about 1.1 enemies a fight survive its damage and lose an attack x A(2) 2.5 x 0.8 = 2.2 (E93) [guess] = 8.2 vs V(2) 7: +17% (+-15%). Same as the old line. Change: If the sim agrees: 2/3 (7.2, +3%).
  - *Fen Newt*: in band. T3 2/5 Ambush (no Mire): body 7 + about 0.6 enemy back-row attacks on it x first strike (Divine Shield's 3.0 x about 0.4 chance its 2 damage kills the attacker) + a little for blunting back-row hitters = 1.0 [guess] = 8.0 vs V(3) 8: 0% (+-15%).
  - *Bogland Matron*: flag over. T5 3/7: body 10 + own Mire about 1.1 x A(5) 4.9 x 0.8 = 4.3 + Mire for about 2 other Bog folk, about 0.8 skipped attacks each x 4.9 x 0.8 x 0.6 while she lives = 3.8 [guess] = 18.1 vs V(5) 12: +51% (+-15%). Change: 2/4 (6 + about 3.0 on fewer exchanges + about 3.0 as she dies sooner = 12, 0%).
- **From.** combat 10

### 12. War Dance — NEW

Instead of its first attack, this stoat dances, freezing the enemy's strongest unit, then strikes it for double damage.

- **Rules.** War Dance. Instead of its first attack each combat, this dances, which uses its turn. The enemy unit with the highest Attack (ties at random) is entranced: it can't attack until this unit attacks again or dies. This unit's next attack must target the entranced unit, in either row, and deals double damage. If the entranced unit can't be targeted when that attack comes, this attacks normally and the trance ends.
- **Bends.** 9.4.5: an enemy unit is taken out of its own side's attack order. 9.5.1: the strike ignores back-row protection.
- **Creatures.** Stoat. Stoats do a leaping war dance that seems to hold a rabbit still before the strike. Folio: the Ermine Court's war-dance troupe.. **Archetypes.** SCAM
- **Example units.**
  - *Weasel Feint*, Tier 1, 1/2, Hunters. Instead of its first attack each combat, the highest-Attack enemy is entranced until this attacks again or dies. (The dance without the strike.)
  - *Ermine Dancer*, Tier 4, 3/4, Hunters. War Dance.
  - *Prima of the Ermine Court*, Tier 6, 5/6, Hunters. War Dance. Your other units also deal double damage to the entranced unit.
- **How they play.** The dance holds the enemy carry still for about a cycle. Your other units use that time to clear its feeders and guards, and then the stoat's strike lands on the carry wherever it stands. The Prima turns the whole board into the strike. Weasel Feint is the cheap early version that just buys a cycle.
- **Why run it.** It switches off the enemy's best unit for a cycle and then hits it hard, even in the back row.
- **Scene.** Turn 7, you fight a 30/30 boar carry. You have Ermine Dancer, now 9/8, in F3. In the fight, the stoat dances and the boar stands entranced while your front row kills two of its feeders. On the stoat's next turn it strikes the boar for 18. Your next two attackers finish it.
- **Good against.** TALL boards with one carry. **Weak against.** Pings and fast front units that kill the stoat before its second turn, and WIDE boards with no single big unit.
- **Variations.**
  - **Hypnotic Dance.** The trance lasts until this dies, but there is no double damage.
  - **Pair Dance.** Entrances the two highest-Attack enemies; no double damage.
  - **Courtship Display.** Instead of its first attack, the highest-Attack enemy must attack this unit on its next turn.
- **Similar to.** Like stun or sleep effects in RPGs.
- **Open.** Double damage applies before Peck splits the damage (a Peck stoat doubles first).
- **Open.** If the stoat is Mired, the trance lasts longer; both still end.
- **Rules review (needs a ruling).** Works under 9.4.5 if an entranced unit counts as unable to attack, so a side whose only unit is entranced passes and 9.9.1 can end a fight where neither side can attack (R3). Needs a ruling for two dancers: the second dance picks the same highest-Attack enemy, so say each dance picks the highest enemy not already entranced, and that each trance ends with its own dancer. Long for a card; the Weasel Feint half is the readable core.
- **Budget review.** Taking the enemy's best attack off the board is worth a lot at high tiers, so the Tier-6 dancer needs a much smaller body; the lower two sit near the line.
  - *Weasel Feint*: edge. T1 1/2: body 3 + the highest-Attack enemy (about 3 at Tier 1) loses about one attack x 0.8 x 0.8 (it would sometimes attack after the weasel died anyway) = 1.6 (E93) - its own skipped first attack 0.7 [guess] = 3.9 vs V(1) 5: -22% (floor +-20%). Change: If the sim agrees: 1/3 (4.9, -2%); more Health also keeps the trance up longer.
  - *Ermine Dancer*: edge. T4 3/4: body 7 + the entranced carry loses about one attack (about 5) + double-damage strike about 2.5 - its own skipped first attack about 2.5 = 5 (E93, E90) [guess] = 12 vs V(4) 10: +20% (+-15%). Same as the old line. Change: If the sim agrees: 3/3 (about 11, +10%).
  - *Prima of the Ermine Court*: flag over. T6 5/6: body 11 + trance on the top enemy hitter (0.8 x A(6) 6.1 x 1.3 for the highest Attack = 6.4) + double strike 5 x 0.85 x 0.6 = 2.6 - own skipped attack about 3 + allies' double damage, about 1.5 hits x 5 x 0.85 x 0.5 (the carry often dies anyway) = 3.2 [guess] = 20.2 vs V(6) 14: +44% (+-15%). Change: 3/3 (6 + 5.8 + 1.5 - 1.8 + 3.2 = 14.7, +5%).
- **From.** creatures 16

## D. When something else is attacked

### 13. Bystander — VARIANT of Battlegrounds' Champion of Y'Shaarj and Arm of the Empire *(was Alibi)*

Whenever an enemy attacks one of your other units, this fox grows.

- **Rules.** Bystander. Whenever an enemy unit attacks one of your other units, this gains +1/+1 this combat.
- **Bends.** 9.5.5: each enemy target choice becomes a trigger for the units it didn't pick.
- **Creatures.** Fox. Folio: Reynard's lawyers, who talk their way out of any fight. It was there, but it wasn't involved.. **Archetypes.** WIDE, MEDIUM
- **Example units.**
  - *Fox Notary*, Tier 1, 1/3, Hunters. Bystander.
  - *Fox Witness*, Tier 3, 3/3, Hunters. Bystander. Your other Foxes also gain the +1/+1.
  - *Reynard, Esquire*, Tier 5, 4/5, Hunters. Bystander. At the end of combat, if this was never attacked, it keeps half the stats Bystander gave it this combat (rounded down), permanently.
- **How they play.** In the back row, a fox is never attacked while your front lives, so it grows from every enemy attack. Tough front units (Hunker badgers, Shoulder bears, Shell snails) mean more enemy attacks before the front falls. Reynard turns a good fight into permanent stats, but only if nothing ever reached him.
- **Why run it.** A back-row carry that grows from the enemy's attacks, so your sturdy front row feeds it.
- **Scene.** Turn 5, you put Reynard, Esquire in B2 behind two Hunker badgers and a bear. In the fight, the enemy attacks your front row nine times before it falls, and Reynard reaches 13/14. He finishes the last two enemies and is never touched. After the fight he keeps +4/+4 permanently.
- **Good against.** Slow boards that need many attacks to get through your front. **Weak against.** BURST and random damage that reach the back row, and anything that attacks the fox directly (Swoop, Grudge, Rival).
- **Variations.**
  - **Alibi (original).** Whenever an enemy attacks and this was one of the units it could have targeted, but it chose another, this gains +1/+1. Rewards a front-row fox that was lucky; harder to see.
  - **Hideout.** Whenever a friendly unit is attacked while this can't be targeted, this gains +1/+1. Back row only.
  - **Onlooker.** Whenever any unit, friendly or enemy, is attacked, this gains +1 Attack this combat.
- **Owner's direction.** 'Alibi is interesting. I'm not sure it's the right name for it, but that's cool. Maybe have Alibi just be "whenever an enemy unit attacks a different unit", and rename it to something else, rather than having it be that complicated.' (02h)
- **Designer's response.** Followed: the trigger is now the owner's simpler one, and the keyword is renamed Bystander. Other names: Onlooker, Lie Low, Wallflower, Not Me. The original candidate-list version is kept as a variation. The simpler trigger also fixes the rules review's problem that a back-row fox could never be a candidate. The Clerk is renamed Fox Notary to avoid the name clash with the Play Dead example.
- **Open.** When Shoulder redirects an attack aimed at a fox onto a bear, does the fox count as 'one of your other units' being attacked? Proposed: the trigger reads the final defender, so yes for every fox except one that ends up the defender.
- **Rules review (clean).** Simple and readable: one trigger on enemy attack declarations, reading the final defender after any Shoulder redirect, as the designer proposes. Peck's strikes should count once here (see Peck). Reynard, Esquire should say 'if this survived and was never attacked', since a fox killed by an effect was never attacked; the permanent write to its own recruit board is allowed (9.1.1, R9).
- **Budget review.** The renamed trigger fires on almost every enemy attack, so +1/+1 per trigger is expensive; +1 Attack per trigger and smaller bodies keep the fox idea in band.
  - *Fox Notary*: edge. T1 1/3: body 4 + about 1.5 triggers in Tier-1 fights (1-3 units, often none beside it) x +1/+1 this combat x 0.65 realised = 2.0 (R33) [guess] = 6.0 vs V(1) 5: +20% (on the floor of +-1 SP). Change: If the sim agrees: 1/2 (5.0, 0%).
  - *Fox Witness*: flag over. T3 3/3: body 6 + own Bystander about 3.5 triggers x +1/+1 = 4.5 + other Foxes (about 1.5 x 3 triggers x 2 SP x 0.7) = 6.3 [guess] = 16.8 vs V(3) 8: +110% (+-15%). The simpler trigger fires more than Alibi did, so this is if anything low. Change: 1/2 in the back row, where it lives longest, and Bystander plus the shared gain give +1 Attack instead of +1/+1: 0.75 + 2 + 2.5 + 3.2 = 8.5 (+6%).
  - *Reynard, Esquire*: flag over. T5 4/5: body 9 + own Bystander about 4 + keeping half the gains permanently when never attacked (about 0.5 of fights x about +2/+2 = 2 SP a fight, under the Tier-5 combat growth cap; c_combat(5) 1.6 x 2 = 3.2) [guess] = 16.2 vs V(5) 12: +35% (+-25%, scaling). Change: 3/4 (7 + 4 + 3.2 = 14.2, +18%); in the back row, where it wants to be, about 13.5 (+12%).
- **From.** combat 11

### 14. Shoulder — VARIANT of Battlegrounds' Elistra the Immortal and Taunt

Once per enemy cycle, this bear steps in and takes an attack aimed at a unit beside it.

- **Rules.** Shoulder. Once per enemy cycle, when an enemy attacks a unit adjacent to this, this becomes the defender instead, before any 'when attacked' effects. The enemy cycle resets when the attacking side's attack order starts again. If two Shoulder units could take the attack, the first in reading order does. A gap next to this (8.2.2) means no neighbour to guard.
- **Bends.** 9.5.5 and 9.6.1: the defender changes after targeting, so the new defender's triggers fire and the original's don't.
- **Creatures.** Brown bear. It puts its shoulder in the way. Folio: the honey monks and the sleeping king.. **Archetypes.** STICKY, TALL
- **Example units.**
  - *Bear Cub*, Tier 2, 2/5, Great beasts. Shoulder.
  - *Bear Warden*, Tier 4, 3/9, Great beasts. Shoulder. Whenever this takes an attack for another unit, it gains +1/+2 this combat.
  - *Old Bruin*, Tier 6, 6/12, Great beasts. Shoulder, with no once-per-cycle limit.
- **How they play.** Put the bear between two units you want kept alive, such as a front-row carry and a Hunker badger. Bear Warden grows each time it steps in. Old Bruin takes every attack aimed at its neighbours, so a TALL player can put a carry in F2 next to it and the carry is almost never hit until Bruin falls.
- **Why run it.** It guards your front-row carry without moving it to the back row.
- **Scene.** Turn 6, your carry is a 15/10 Rutting Stag in F3. You put Bear Warden in F2, next to it. In the fight, the first enemy attack each cycle that targets the stag hits the bear instead, and the bear grows to 5/13. The stag keeps attacking at full strength.
- **Good against.** Boards whose attacks land randomly on your carry. **Weak against.** Many attackers per cycle (only one is redirected), and gaps: a bear in F1 guards only F2.
- **Variations.**
  - **Shield Bash.** Shoulder. When this takes an attack for another unit, deal 3 damage to the attacker first.
  - **Interpose.** Once per combat, when an enemy effect would damage an adjacent unit, this takes the damage instead.
  - **Den Mother.** Shoulder, but it guards the units behind it once the back row can be attacked.
- **Similar to.** Like bodyguard or 'cover' abilities in tactics games (Final Fantasy's Cover).
- **Open.** A bear that takes the attack and then dodges it (Jink) makes the attack miss: intended?
- **Rules review (needs a ruling).** The redirect works if it sits in a separate defender step after must-be-attacked (R6), before 'when attacked' effects as the text says. Needs a ruling that a redirected attack is never redirected again: if a defender change counts as a new 'attacks a unit adjacent to this', two adjacent Old Bruins (no once-per-cycle limit) pass one attack back and forth until the 10,000-trigger tie (9.10.2), and even two Bear Cubs bounce it once each. The 'enemy cycle' needs R4's per-side cycle counter; readable as 'takes hits for its neighbours'.
- **Budget review.** Shoulder itself is cheap; the two bigger bears are over mostly on body size.
  - *Bear Cub*: in band. T2 2/5: body 7 + Shoulder (E91: Taunt's 0 plus the neighbour it guards) about 0.5 [guess] = 7.5 vs V(2) 7: +7% (+-15%).
  - *Bear Warden*: flag over. T4 3/9: body 12 (+20% before text) + Shoulder 0.5 + '+1/+2 this combat' on about 2 redirected attacks x 3 SP x 0.6 realised = 3.6 [guess] = 16.1 vs V(4) 10: +61% (+-15%). The old line priced the bear without the growth at +25%. Change: 2/5 (7 + 0.5 + about 2.9 as it falls sooner = 10.4, +4%).
  - *Old Bruin*: flag over. T6 6/12: body 18 (+29% before text) + Shoulder with no limit, a full Taunt for both neighbours, about 2 (top of E91) [guess] = 20 vs V(6) 14: +43% (+-15%). Change: 4/8 (12 + 2 = 14, 0%).
- **From.** combat 12 (marked variant by the designer)

## E. Choosing targets and reaching the back row

### 15. Grudge — NEW

This rook remembers whoever hurt it, attacks them first, even in the back row, and hits them harder.

- **Rules.** Grudge. When an enemy unit damages this, by attack or effect, that enemy is marked for the rest of combat. When this attacks, it must target a marked enemy if one can be targeted, in either row (at random among several), and it deals +2 damage to marked enemies. Marks stay on units that move. A unit that dies and comes back is a fresh copy with no mark.
- **Bends.** 9.5.1 (back-row protection) and 9.5.5 (random target).
- **Creatures.** Rook and crow. Crows remember faces and hold grudges. Folio: the Rook courts, and Rook parliaments that punish the strongest enemy.. **Archetypes.** SCAM
- **Example units.**
  - *Jackdaw Witness*, Tier 1, 1/3, Birds. Grudge.
  - *Rook Magistrate*, Tier 3, 3/4, Birds. Grudge.
  - *Speaker of the Parliament*, Tier 5, 4/6, Birds. Grudge. Your other Birds also attack marked enemies first and deal +2 damage to them.
- **How they play.** A rook in the front row gets marked attackers: whatever hits it, it hits back on its turn with +2. If an enemy back-row unit pings the rook or attacks it, the rook flies straight to it. The Speaker shares the marks with every Bird, so one hit on any rook points your whole flock at that enemy.
- **Why run it.** It punishes the enemy for hitting it, and it lets your Birds reach back-row units that touch you.
- **Scene.** Turn 5, the enemy has a back-row owl that pings at Start of Combat. It pings your Rook Magistrate. The owl is marked, and on the rook's turn it attacks the owl in the back row for 5 and kills it. Turn 8, with the Speaker, every Bird follows the mark.
- **Good against.** BURST pings from the back row, and back-row attackers. **Weak against.** Being hit only by tokens, which wastes the grudge, and boards that don't hit the rook first.
- **Variations.**
  - **Vendetta.** When a friendly unit dies, the enemy that killed it is marked.
  - **Hold a Grudge.** Marked enemies take +2 damage from all your units; no change to targeting.
  - **Remember Faces.** Start of Combat: mark the enemy with the highest Attack.
- **Similar to.** Like threat or aggro in MMOs, turned around: the one who hurt you is the one you go after.
- **Open.** A marked unit that can't be targeted falls back to normal targeting (R6).
- **Rules review (needs a ruling).** Works as reach plus bonus damage, with R6's fallback stated for marked units that can't be targeted. Needs a ruling on whose marks they are: the text says 'a marked enemy', so a mark made by one rook already steers every rook, which makes the Speaker's 'your other Birds also attack marked enemies' only useful for non-Grudge Birds; say marks belong to the marking side. Retaliation damage marks the defender too, which is probably intended; readable with a mark badge.
- **Budget review.** Grudge is in band at every tier as written.
  - *Jackdaw Witness*: in band. T1 1/3: body 4 + 2 bonus damage x about 1 attack x 0.5 chance a marked enemy lives x 0.85 = 0.85 + reach 0.3 (E90, E83) [guess] = 5.15 vs V(1) 5: +3%.
  - *Rook Magistrate*: in band. T3 3/4: body 7 + bonus damage about 1.3 + back-row reach about 0.5 [guess] = 8.8 vs V(3) 8: +10% (+-15%). Same as the old line.
  - *Speaker of the Parliament*: in band. T5 4/6: body 10 + own Grudge about 1.8 + about 2 other Birds attacking marked enemies for +2 (about 1 attack x 0.6 x 2 x 0.85, x 0.6 while it lives = 1.2, plus reach 0.4) [guess] = 13.4 vs V(5) 12: +12% (+-15%).
- **From.** combat 7

### 16. Rival — VARIANT of Battlegrounds' Interrogator Whitemane

This robin picks the enemy across from it as its rival and fights only that unit, both dealing double damage.

- **Rules.** Rival. Start of Combat: the enemy unit across from this (8.2.6) becomes its Rival. The bond follows both units if they move. While the Rival lives and can be targeted, this attacks only its Rival, in either row, and the two deal double damage to each other. If no unit is across, this has no Rival and fights normally. If the Rival can't be targeted, this attacks normally until it can.
- **Bends.** 8.2.6 (across from) becomes a duel. 9.5.5's random target and 9.5.1's back-row protection give way to the column.
- **Creatures.** Robin, which defends its territory against rivals, sometimes to the death. Folio: the bard who duels.. **Archetypes.** SCAM
- **Example units.**
  - *Robin Fledgling*, Tier 1, 2/1, Birds. Rival.
  - *Robin Redbreast*, Tier 2, 3/2, Birds. Rival. If this kills its Rival, it gains +2/+2 permanently.
  - *Robin Minstrel*, Tier 4, 4/4, Birds. Rival. Whenever this and its Rival damage each other, your other Birds gain +1 Attack this combat.
- **How they play.** Where you place a robin is where you aim it. In B1 or B2 it duels the enemy back-row carry that sits across from it, ignoring the front row. Double damage both ways means the robin usually dies, but it often takes something much bigger with it. The Redbreast grows each time it wins a duel.
- **Why run it.** A cheap piece that reaches into the enemy's back row and trades up.
- **Scene.** Turn 4, you notice the lobby's strong players keep their carry in B2. You put Robin Redbreast in B2. In the fight, it duels an 8/8 back-row owl: it hits for 6 and the owl hits it for 16. It dies, but your next attacker finishes the hurt owl. Another fight, it kills a 5/4 and becomes 5/4 permanently.
- **Good against.** Boards with one carry in a predictable slot. **Weak against.** Gaps across from it (no Rival), and big Rivals with high Attack that kill it first.
- **Variations.**
  - **Turf.** Start of Combat: the enemy across from this must attack only this until one of them dies.
  - **Fair Duel.** Rival without double damage. If this kills its Rival, it gains the Rival's Attack this combat.
  - **Song Duel.** Start of Combat: this and the enemy across from it each lose Attack equal to the other's, this combat.
- **Similar to.** Like duel cards in Magic (Fight effects), aimed by board position.
- **Open.** In async snapshot play you can't see where the enemy carry is; the duel is a guess. Keep numbers small.
- **Open.** Start of Combat order: if another effect moves units first, who is across changes.
- **Rules review (needs a ruling).** Works as a Start of Combat bond with forced reach (R6), and the fallback for a Rival that can't be targeted is stated. Needs rulings: two robins across from each other become mutual Rivals, so say the double damage applies once, not four times; and the bond reads the board when it resolves, so random Start of Combat side order decides it against Flush or Changeling (R8). The duel line is readable one at a time; 'Turf' as a variation name clashes with the new Turf mechanic in batch 3.
- **Budget review.** Rival fights fit, but Robin Redbreast's permanent +2/+2 per kill is +104% over Tier 2 (band ±25%); +1 Attack per kill keeps the snowball slower.
  - *Robin Fledgling*: edge. T1 2/1: body 3 + the duel (trades up with double damage, about 1.5) x about 0.7 chance a unit is across on small boards = 1.0 (E90) [guess] = 4.0 vs V(1) 5: -20% (on the floor). Change: If the sim agrees: 2/2 (5.0, 0%).
  - *Robin Redbreast*: flag over. T2 3/2: body 5 + duel 1.5 + '+2/+2 permanently' on a Rival kill at about 0.7 kills a fight = 2.8 SP a fight, over the Tier-2 combat growth cap of 1.7; c_combat(2) 2.8 x 2.8 = 7.8 (E02 on R23) [guess] = 14.3 vs V(2) 7: +104% (+-25%). Same as the old line. Change: 2/2, '+1 Attack permanently' on a kill (0.7 SP a fight, under the cap, about 2.0): 4 + 1.5 + 2.0 = 7.5 (+7%). Attack growth still feeds the double damage.
  - *Robin Minstrel*: edge. T4 4/4: body 8 + duel about 2 + about 1.2 exchanges with its Rival x +1 Attack to about 2 other Birds x 0.7 = 1.7 [guess] = 11.7 vs V(4) 10: +17% (+-15%). Change: If the sim agrees: 4/3 (about 10.7, +7%).
- **From.** rows 11

### 17. Nocturnal — VARIANT of Galaxy's Sneak

This unit waits out the first round of attacks, then hunts the weakest enemy anywhere on the board.

- **Rules.** Nocturnal. This doesn't attack in your side's first attack cycle. From your second cycle on (“night falls”), it attacks the enemy unit with the lowest Health, in either row. Ties are random. If that unit can't be attacked (for example it is behind a Shelter), it attacks the next lowest. If every unit on your side that can attack is Nocturnal, your first cycle ends at once and night falls.
- **Bends.** 9.4.5: it opts out of cycle 1, and a side made only of Nocturnal units starts its second cycle straight away. 9.5.1 and 9.5.5: it ignores back-row protection and doesn't choose at random.
- **Creatures.** Owl. Owls hunt at night, silently, taking the weak and the stragglers. The Folio's owls are “the court that sits after dark”.. **Archetypes.** SCAM, TALL
- **Example units.**
  - *Little Owl Usher*, Tier 1, 2/3, Birds. Nocturnal.
  - *Tawny Magistrate*, Tier 3, 5/2, Birds. Nocturnal. After this kills a unit, it gains +1/+1 permanently.
  - *Eagle-Owl Justice*, Tier 5, 6/6, Birds. Nocturnal. When night falls, your other Nocturnal units gain +3 Attack for this combat.
- **How they play.** The owls sit in the back row during the first cycle, while the front rows trade and leave units wounded. When night falls they each pick off the lowest-Health enemy, often a damaged front unit or a fragile back-row buffer. The Magistrate grows from each kill it lands, so pairing it with Start of Combat pings (BURST) or splash makes its targets easier. The Eagle-Owl turns the moment night falls into a spike for every owl.
- **Why run it.** It kills the enemy's support pieces that normally hide safe in the back row, and it finishes wounded units instead of bouncing off a fresh tank. It also stays out of harm for a cycle, so a low-Health carry like the Magistrate survives long enough to act.
- **Scene.** Turn 6, your opponent has been winning with a 1/3 Nest Robin in their back row that buffs their front line every turn. You buy a Tawny Magistrate and put it in B2. In the fight, cycle 1 goes by and your owl does nothing while the front rows trade. Then night falls: the Magistrate ignores their 4/7 front tank and drops on the Robin in B1, the lowest-Health enemy, and kills it. It survives the 1-damage return blow and grows to 6/3 for good.
- **Good against.** Boards that hide fragile engines or buffers in the back row, and boards whose front row is already wounded. **Weak against.** Fast fights that end in one cycle, and high-Health boards where nothing is ever low; Shelter blocks its reach.
- **Variations.**
  - **Crepuscular.** This attacks only in your first and last cycle: it skips every cycle after the first until it is the last unit on your side that can attack.
  - **Night Watch.** This doesn't attack in your first cycle. When night falls, it gains +X/+X for this combat. (Waits, but keeps normal targeting.)
  - **Early Bird.** In your first cycle only, this attacks the enemy with the lowest Health in either row. After that it attacks normally.
- **Similar to.** Galaxy's Sneak reaches the back row; Nocturnal waits first and then targets the weakest anywhere.
- **Designer's response.** No owner reaction. I kept the idea and fixed the review's gap: a side of only Nocturnal units skips straight to night, so its cycle can't stall.
- **Open.** Does night fall per side (each side's own second cycle) or once for the whole fight? Proposed: per side, since 9.4.5 keeps a pointer per side.
- **Open.** The UI needs to show cycles for this to be readable. Is a visible “night falls” moment acceptable in the fight presentation?
- **Rules review (clean).** Works with R4's per-side cycle counter, which the designer proposes, and the text solves R4's stall itself: a side of only Nocturnal units ends its first cycle at once. Lowest-Health reach with a 'next lowest' fallback fits R6 (protection beats reach). Readable if the fight shows a 'night falls' moment, which Nightfall needs too.
- **Budget review.** Nocturnal's wait and its reach roughly cancel, so the owls are near budget; only the Tier-5 owl needs a smaller body.
  - *Little Owl Usher*: in band. T1 2/3, back: body 4.5 - sitting out cycle 1 about 0.6 + lowest-Health target in either row about 1.0 (E83) [guess] = 4.9 vs V(1) 5: -2%.
  - *Tawny Magistrate*: in band. T3 5/2, back: body 5.75 - 1.5 sit-out + 2.5 targeting = 6.75 (old line) + '+1/+1 permanently' after a kill: about 0.6 kills a fight = 1.2 SP a fight, under the Tier-3 combat cap of 2.2; c_combat(3) 2.5 x 1.2 = 3.0 [guess] = 9.75 vs V(3) 8: +22% (+-25%, permanent growth).
  - *Eagle-Owl Justice*: flag over. T5 6/6, back: body 10.5 - 1.8 sit-out + 3.0 targeting = 11.7 + '+3 Attack' at night to about 1.5 other Nocturnal units x 0.75 x 1.4 (combat buff on back units) x 0.8 alive at night = 3.8 [guess] = 15.5 vs V(5) 12: +29% (+-15%). Change: 5/5 (3.75 + 5 - 1.5 + 2.5 + 3.8 = 13.5, +13%).
- **From.** creatures 6 (marked variant by the designer).

### 18. Shiny — NEW

This thief goes straight for enemy golden units, wherever they stand, and steals stats from them.

- **Rules.** Shiny. If the enemy has any golden units, this attacks one of them (chosen at random), in either row. Whenever this damages a golden enemy, it steals +1/+1: the enemy loses +1/+1 for this combat, and this gains +1/+1 permanently. With no golden enemy, this attacks normally. A golden Shiny unit steals +2/+2.
- **Bends.** 9.5.1: back-row protection is ignored, but only for golden targets. 7.3: being golden becomes something the enemy can aim at. The victim's loss lasts the combat only, because the enemy is a recorded snapshot (2.1.4, 9.1.1).
- **Creatures.** Magpie and jackdaw. Magpies can't resist shiny things; the Folio's Shiny Syndicate “can't resist anything shiny, including evidence”.. **Archetypes.** SCAM, TALL
- **Example units.**
  - *Jackdaw Lookout*, Tier 1, 1/3, Birds. Start of Combat: if the enemy has a golden unit, your Shiny units gain +2 Attack for this combat.
  - *Fence Magpie*, Tier 3, 3/3, Birds. Shiny.
  - *Magpie Hoarder*, Tier 4, 2/5, Birds. After a friendly unit steals in combat, you get 1 extra gold next turn (at most 2 gold per combat).
- **How they play.** The Lookout spots goldens at Start of Combat and sharpens the magpies, so the Fence Magpie's first hit on a golden lands harder. Every time a magpie connects it grows for good, and the Hoarder turns each theft into gold for next turn. Against a lobby with no goldens the magpies are plain 3/3s, so they are a tech package you pick up when someone is ahead.
- **Why run it.** It is a tax on the player who is far ahead: the bigger their golden pile, the more you take. Your magpie grows permanently from fights with the leaders, and the Hoarder pays you for it.
- **Scene.** Turn 8, the lobby leader has a golden 12/12 Bison in their back row behind three front units. You pick up a Fence Magpie and a Jackdaw Lookout. In the fight, the Lookout gives the magpie +2 Attack; it flies over the front row, hits the golden Bison for 5, steals +1/+1 and dies to the return blow. Next turn your magpie is 4/4 for good, and the Bison's owner lost that fight by one unit.
- **Good against.** Players who are triple-rich and stack stats on golden units. **Weak against.** Lobbies without goldens, and golden units big enough to kill the magpie in one return blow before it steals again.
- **Variations.**
  - **Covet.** This attacks the enemy with the most Attack above its card's printed Attack (the most buffed unit). Whenever it damages that unit, steal +1/+1 as Shiny does. Works without goldens.
  - **Snatch.** Start of Combat: steal +2/+2 from a random enemy golden unit. (A BURST version: no attack needed, but no growth beyond the steal.)
  - **Thieves' Honour.** Shiny, and this never attacks enemy units that are Shiny. (The old golden rule: thieves don't rob each other.)
- **Similar to.** Like a catch-up tool in racing games (the blue shell in Mario Kart): it aims at whoever is ahead.
- **Designer's response.** No owner reaction. I took the review's fix: the victim loses the stats for this combat only, and only the magpie's gain is permanent. I moved the golden magpie's special rule into a variation.
- **Open.** Can the steal reduce a golden enemy's Attack to 0 (so it stops attacking)? Proposed: yes, it is an ordinary combat debuff.
- **Open.** Should golden chasing (archetypes.md 1.3) get more answers like this, or is one magpie line enough?
- **Rules review (clean).** Works: the steal is permanent only on its own unit and combat-only on the snapshot, which fixes R9's impossible write. Add R6's fallback for when every golden is protected (a Shelter in front of it), and say a steal that takes Health can kill. The Hoarder's gold reads a combat result back into the Recruit Phase, which needs R9's combat report; readable.
- **Budget review.** Shiny is near budget; its value rises as goldens get commoner, so sim it late.
  - *Jackdaw Lookout*: in band. T1 1/3: body 4 + '+2 Attack to your Shiny units if the enemy has a golden': about 0.15 chance of an enemy golden on turns 1-3 (C08) x about 1 Shiny unit x 2 x 0.8 = 0.25, about 1.2 if held to mid-game [guess] = 4.25 vs V(1) 5: -15% (floor +-20%).
  - *Fence Magpie*: edge. T3 3/3: body 6 + permanent steal (about 0.5 hits on goldens a fight x 2 SP = 1 SP a fight, under the cap; c_combat 2.5 x 1 = 2.5) + the golden's loss 1.1 + golden-seeking reach 0.4 [guess] = 10 vs V(3) 8: +25% (+-25%, scaling). Same as the old line; it rises late as enemy goldens get commoner. Change: If the sim agrees: 3/2 (about 9, +12%).
  - *Magpie Hoarder*: in band. T4 2/5: body 7 + about 1 gold next turn in a build with two Shiny units, conditional recurring gold (2.2: +1 a turn at Tier 4 = 4.2) [guess] = 11.2 vs V(4) 10: +12% (+-25%, economy). For information: it can pay up to 2 gold a turn, over power-budget 4.1's proposed Tier-4 cap of 1 (not approved).
- **From.** creatures 4.

### 19. Flush — NEW

Before the fight, this drags an enemy back-row unit out into their front row, where it can be attacked.

- **Rules.** Flush has two shapes. Flush (swap): Start of Combat: the enemy back-row unit with the highest Attack swaps places with the unit in front of it that has the lowest Health (ties: the left one). If no unit is in front of it, nothing happens. Tongue (pull): Start of Combat: the enemy back-row unit with the lowest Health moves into the nearest empty slot in their front row (nearest by the 8.4.2 order from its slot). If their front row is full, nothing happens. Ties for highest Attack or lowest Health are random. Later Start of Combat effects see the new board.
- **Bends.** 8.3.5: an effect moves an enemy unit. 9.5.1: back-row protection is beaten by moving the target, not by reaching over the front row (11.5.3). 8.2.4: the moved unit's “in front of” and “behind” text now points at new slots.
- **Creatures.** Weasels, stoats and ferrets hunt inside burrows (ferreting drives rabbits out of the warren). Frogs and toads snatch prey from a distance with a sticky tongue.. **Archetypes.** SCAM
- **Example units.**
  - *Natterjack Toad*, Tier 1, 1/3, Bog folk. After an enemy unit is moved into their front row, deal 1 damage to it.
  - *Bullfrog Tenor*, Tier 3, 3/4, Bog folk. Tongue.
  - *Burrow Weasel*, Tier 3, 3/3, Hunters. Flush. This unit's first attack this combat targets the unit it flushed, if that unit is still alive.
- **How they play.** The Bullfrog pulls the enemy's flimsiest back unit into the open, and the Natterjack nicks it for 1 on arrival, so it reaches the fight already hurt. The Weasel works the other way: it drags their biggest back-row carry forward by swapping it with a weak front unit, then attacks it first. Both break the enemy's position text, because a buffer that was “behind” its tank is now beside it.
- **Why run it.** The back row is where players keep their engines and carries. Flush lets your front row reach them on the first attack, without needing a whole tribe of back-row reach.
- **Scene.** Turn 5, your opponent's board is a wall of three front units and a 2/2 Nest Robin and a 7/4 back-row carry. You buy a Bullfrog Tenor and a Natterjack. At Start of Combat the Tenor's tongue yanks the Robin into the empty F4 and the toad hits it to 2/1. Your first attacker kills it. Next turn you add a Burrow Weasel, which swaps their 7/4 carry with their weakest front unit and goes for it on its first attack.
- **Good against.** Boards that hide a carry or a fragile engine in the back row. **Weak against.** Against Tongue, a full enemy front row; against Flush, no units in front of the carry. The two shapes have opposite defences.
- **Variations.**
  - **Ferret Out.** Start of Combat: swap the enemy back-row unit with the highest Attack with the enemy unit across from this, if both exist.
  - **Long Tongue.** Tongue, and the pulled unit can't be the target of its own side's buffs this combat.
  - **Beat the Bushes.** Start of Combat: every enemy back-row unit with 2 Health or less moves into an empty enemy front slot, if there is one.
- **Similar to.** Like the hook or pull champions in MOBAs (Blitzcrank in League of Legends, Pudge in Dota 2): drag the target out of safety.
- **Designer's response.** No owner reaction. I kept both shapes under one entry and added tie rules and the nearest-slot rule from the review. The two shapes give opposite counterplay, which is the interesting part.
- **Open.** Should Start of Combat effects that already resolved (the enemy's auras) re-read the board after a Flush? Proposed: no; only effects that resolve later see the new board (9.3.4 needs a line).
- **Open.** Is one entry with two shapes right, or should Tongue be its own mechanic?
- **Rules review (needs a ruling).** Both shapes are precise moves that 8.3.5 allows ('effects that say so'). Needs a ruling in 9.3.4 that each Start of Combat effect reads the board as it stands when it resolves, which the designer proposes, so random side order (9.3.2) decides some outcomes (R8). Two Flush units can swap a pair back; that is finite but should be shown clearly, and Tongue may read better as its own keyword.
- **Budget review.** Flush is in band as written; the Tier-1 toad is blank until a mover joins it.
  - *Natterjack Toad*: in band. T1 1/3: body 4 + 1 damage to enemies moved into their front row, about 0.2 (it needs a Flush or Tongue unit, Tier 3) [guess] = 4.2 vs V(1) 5: -16% (floor +-20%). Blank without a mover.
  - *Bullfrog Tenor*: in band. T3 3/4 Tongue: body 7 + pull about 2.5 (E94) x about 0.4 chance of an empty enemy front slot = 1 [guess] = 8 vs V(3) 8: 0%. Same as the old line; blank against full boards.
  - *Burrow Weasel*: in band. T3 3/3 Flush: body 6 + bringing their back carry forward about 2.5 (E94) + first attack on the flushed unit about 0.5 (E83) [guess] = 9 vs V(3) 8: +12.5% (+-15%).
- **From.** rows 10, creatures 17.

## F. Protection and dodging

### 20. Shelter — VARIANT of Battlegrounds' Taunt

A big front unit that keeps the back-row units behind it safe from anything that reaches over the front row.

- **Rules.** Shelter. While this lives, the units in the slots behind it can't be attacked, even by attacks that may reach the back row (such as Swoop, Nocturnal or Shiny). Effects that pick a random enemy or hit a group still reach them. “Behind” is 8.2.1: one slot for F1 and F4, two for F2 and F3.
- **Bends.** 9.5.1: back-row protection works by column as well as by row. 11.5.3: a counter to back-row reach, so reach doesn't become a must-have.
- **Creatures.** Bison, the “immovable tank”. A herd turns to face a threat with the calves behind it. Red deer stags do the same.. **Archetypes.** STICKY, TALL
- **Example units.**
  - *Bison Yearling*, Tier 1, 1/3, Great beasts. While a unit with Shelter is in front of this, this has +2 Attack.
  - *Red Deer Hind*, Tier 2, 2/5, Great beasts. Shelter.
  - *Białowieża Bison*, Tier 4, 3/9, Great beasts. Shelter. When an effect would damage a unit behind this, this takes the damage instead.
- **How they play.** Put the Bison in F2 or F3 and it covers two back slots. The Calves and your back carry sit there, safe from Swoop birds and owls, and the Bison even soaks random pings aimed at them. The Hind is the early version for F1 or F4, covering one slot. The Calf rewards you for building the column: it hits harder while it is sheltered.
- **Why run it.** Reach mechanics (Swoop, Nocturnal, Shiny, Flush) are how other players get at your back-row carry. Shelter is the answer, and it gives Great beasts a gameplay identity that matches the flavour: big animals guarding the young.
- **Scene.** Turn 7, two players in your lobby run Birds whose Swoop units dive at your back-row 10/10 Ooze. You buy a Białowieża Bison and put it in F2, in front of the Ooze in B1. In the fight their Swoopers have to hit your front row instead, and a Start of Combat ping aimed at the Ooze hits the Bison's 9 Health. The Ooze lives through the fight and wins it.
- **Good against.** Back-row reach: Swoop, Nocturnal, Shiny and the targeted effects that pick a back-row unit. **Weak against.** Plain front-row pressure that kills the Shelter unit first; once it falls, the column opens. Flush can still drag a sheltered unit out.
- **Variations.**
  - **Herd.** Shelter, and adjacent units with Herd also shelter the slots behind them while this lives.
  - **Brace.** Shelter until this first takes damage; then it loses Shelter. (Cheaper, breakable cover.)
  - **Stand Over.** While this lives, the units behind it take half damage (rounded down) from every source.
- **Similar to.** The bodyguard role in many tactics games: a big unit that covers the fragile one standing behind it.
- **Owner's direction.** On Great beasts as a tribe (02h): “I don't really see how it connects to the gameplay ideas and how they're fleshed out here with the great beasts.”
- **Designer's response.** Not a reaction to Shelter itself, but Shelter is one answer to it: the herd guarding its calves is a gameplay idea the flavour explains. I cut the review's redundant clause (“even after the rest of your front row has fallen”) and settled the Bison's damage text: an effect can still pick the calf, but the Bison takes the damage.
- **Open.** Does Shelter protect against Flush and Tongue moving the sheltered unit? Proposed: no; moving isn't attacking, and Flush is one counter to Shelter.
- **Open.** Does the Bison's redirect apply to damage from group effects (“all enemies”)? Proposed: yes, so it can take two hits at once.
- **Rules review (clean).** Works as protection that beats reach (R6), and it can't stall a fight because the Shelter unit itself stands in the front row and is attackable. The Białowieża Bison's redirect of effect damage should say it takes each redirected hit separately (two group hits means two hits). Moving isn't attacking, so Flush beats it, which is a good counter; readable.
- **Budget review.** Shelter matters only against reach, so it is cheap; only the big bison is over, on body size.
  - *Bison Yearling*: in band. T1 1/3, back: body 3.75 + '+2 Attack while a Shelter unit is in front' (2 x 0.75 x about 0.25 chance on its turns) [guess] = 4.15 vs V(1) 5: -17% (floor +-20%).
  - *Red Deer Hind*: in band. T2 2/5: body 7 + Shelter about 0.5: while it lives the front row isn't empty, so it only adds protection against reach attacks (Nocturnal, Shiny, Grudge, Rival) [guess] = 7.5 vs V(2) 7: +7% (+-15%).
  - *Białowieża Bison*: flag over. T4 3/9: body 12 (+20% before text) + Shelter about 2 (it also soaks effect damage meant for the units behind; E91) [guess] = 14 vs V(4) 10: +40% (+-15%). Same as the old line. Change: 3/6 (about 11, +10%).
- **From.** rows 13 (marked variant by the designer).

### 21. Thicket — VARIANT of Battlegrounds' Taunt

A back-row unit that grows a bramble hedge in every empty front slot in front of it, so the enemy has to cut through the hedges first.

- **Rules.** Thicket. Start of Combat: each empty front slot in front of this grows a Thicket with 3 Health. A Thicket is a hedge, not a unit. It can be attacked, and it counts as a front-row unit for back-row protection (9.5.1), but it never attacks. It doesn't count for winning or losing (a side left with only Thickets has lost), attack order, who attacks first, hero damage, random enemy effects, Cleave, or “adjacent” text. A summon into a Thicket's slot clears the Thicket; for summon placement (8.4) the slot counts as empty. Thickets have no death effects.
- **Bends.** 9.5.1: back-row protection can come from terrain, not only units. 9.9.1 and 9.2.1: Thickets don't count as units. Killing a Thicket isn't a death, so it feeds no death triggers.
- **Creatures.** Brambles themselves, the game's name. Greenwood folk grow hedges over their burrows; hedgehogs and dormice live in them.. **Archetypes.** STICKY, TALL
- **Example units.**
  - *Bramble Warden*, Tier 2, 1/4, Greenwood. Thicket. Units that attack your Thickets take 1 damage.
  - *Briar Sprite*, Tier 3, 4/2, Fairies. While a Thicket is in front of this, this has +2 Attack.
  - *Blackthorn Keeper*, Tier 5, 3/6, Greenwood. Thicket. Your Thickets have +3 Health. Whenever one of your Thickets is cut down, your back-row units gain +1/+1 for this combat.
- **How they play.** Put the Warden in B2 and leave F2 and F3 empty. At Start of Combat two 3-Health hedges appear in those gaps. The enemy must attack your front row, which is now mostly hedge, so their first few attacks are spent cutting brambles (and taking 1 damage each from the Warden) while your back-row units attack freely. The Sprite hits harder while a hedge stands in front of it, and the Keeper makes the hedges tougher and pumps your back row each time one is cut.
- **Why run it.** It turns empty front slots, which are normally a weakness, into a wall. It suits a board with a few strong back-row units (a TALL carry or a buffing engine) that doesn't want to spend gold on front-row bodies.
- **Scene.** Turn 4, you have a strong 6/6 carry in B1 and only two front units in F1 and F4. Gaps in F2 and F3 normally mean little. You buy a Bramble Warden and put it in B2, behind F2 and F3. In the fight two hedges grow in F2 and F3. The enemy's 3/3 cuts the first hedge and takes 1 damage; their next attacker hits the second hedge. Meanwhile your carry and the Warden have attacked twice each. By the time the hedges are gone, the enemy has two units fewer than you.
- **Good against.** Many small attackers and Tongue (which needs empty front slots: hedges fill them). **Weak against.** Cleave, Trample and splash cut through brush, and Swarm spends one joint attack to clear a hedge. Hedges do nothing for a board that fills its front row.
- **Variations.**
  - **Hedge (Recruit Phase).** Spell: plant a Hedge on an empty front slot (a slot effect, 8.5). At Start of Combat, if that slot is still empty, a 3-Health Thicket grows there. The player sees the hedge on the board while recruiting.
  - **Lure (Lights).** Start of Combat: each empty front slot in front of this fills with a Wisp (0 Attack, 1 Health). Enemies must attack Wisps before other front-row units. (The decoy-lights version.)
  - **Overgrowth.** Thicket. At the start of each of your cycles, each of your Thickets regrows +1 Health, up to its maximum.
- **Similar to.** Like the Wall-nut in Plants vs. Zombies: a wall that only soaks hits, placed in the lanes your attackers leave open.
- **Owner's direction.** “I'm not really sure about Thicket. I'd have to see more on that. I don't necessarily love it yet, but I still don't understand it well.” And on Lights (02h): “Decoy lights that fill empty slots and draw attacks: I'm interested to see what that would look like.”
- **Designer's response.** I kept Thicket as written and added a concrete board and turn so it can be judged. In short: hedges are walls in your front-row gaps that the enemy must cut through, and they never count as units. I also give a Recruit-Phase version (a hedge you plant and can see while recruiting) and the Lights decoy version the owner asked to see.
- **Open.** Should hedges be visible during the Recruit Phase (the planted variation) for readability?
- **Open.** Do Thickets count for Swarm's joint attack as a target? Proposed: yes, they are attack targets like any front-row unit.
- **Rules review (needs a ruling).** The text answers R7 for hedges almost fully: front-row cover yes, attack order, win, hero damage, random effects and adjacency no. Needs rulings: cutting a Thicket should also not count as a kill ('after this kills', Gorge, Grudge marks), two Wardens behind one empty slot should grow one hedge, and the Warden's 1 damage to attackers should carry the thorn tag (R2). The play scene (Warden in B2, F2 and F3 left empty) makes it understandable; the planted 'Hedge' variation would make it visible while recruiting.
- **Budget review.** Thicket is priced for the turns with gaps; the Tier-3 sprite is under because its bonus rarely applies.
  - *Bramble Warden*: edge. T2 1/4, back: body 4.75 + about 1.2 Thickets a fight on turns 2-4 x (3-Health decoy 2.1 + 1 prick 0.85) = 3.5 (E97) [guess] = 8.25 vs V(2) 7: +18% at its turns (+-15%). Same as the old line; blank on a full board. Change: If the sim agrees: 1/3 (about 7.25, +4%).
  - *Briar Sprite*: flag under. T3 4/2, back: body 5 + '+2 Attack while a Thicket is in front' (2 x 0.75 x about 0.4 chance on turns 4-6) = 0.6 [guess] = 5.6 vs V(3) 8: -30% (+-15%). Change: 5/3 (3.75 + 3 + 0.6 = 7.35, -8%).
  - *Blackthorn Keeper*: edge. T5 3/6, back: body 8.25 + about 0.5 Thickets a fight on its turns, 6 Health each as decoys (0.7 x 6 = 4.2) = 2.1, + '+1/+1 to your back row' per Thicket cut (about 3 units x 1.75 x 0.9 x 1.4 = 6.6) x 0.5 = 3.3 [guess] = 13.65 vs V(5) 12: +14% (+-15%). More with other Thicket units; blank on full boards. Change: If the sim says it is over in a Thicket build, 3/5.
- **From.** rows 9 (marked variant by the designer).

### 22. Jink — VARIANT of Battlegrounds' Divine Shield

The first time this is attacked, it darts sideways into an empty slot and the attack misses.

- **Rules.** Jink. The first time each combat this is attacked, if a slot adjacent to it in its row is empty, it darts into that slot (the right one if both are empty) and the attack misses: no damage either way. Darting doesn't use up its attack: it keeps whether or not it has attacked this cycle. Random effects, group effects and splash can't be dodged.
- **Bends.** 9.6.1: an attack whose defender is gone ends without damage; here the defender leaves on purpose. 8.3.5: units change slots in combat. 9.4.9: a dart is an exception to flagging on moving to a lower slot.
- **Creatures.** Hare. A hare doesn't fight; it jinks, turning sharply sideways at full speed.. **Archetypes.** STICKY
- **Example units.**
  - *Jack Hare*, Tier 1, 2/2, Hedgerow folk. Jink.
  - *Brown Hare Courier*, Tier 3, 3/4, Hedgerow folk. Jink. After this darts, it attacks the unit that missed it.
  - *Warren Matron*, Tier 5, 4/6, Hedgerow folk. Your Jink units can dart once more each combat.
- **How they play.** A hare needs an empty slot beside it, so you build the board with gaps: hares in F1 and F3 with F2 and F4 open, for example. Each hare dodges one attack, and the Courier punishes the miss with a free counterattack. The Matron gives every hare a second dodge, but each dart uses up a gap, so placement decides how many dodges you get.
- **Why run it.** It makes gaps worth having and rewards careful placement. A row of hares wastes the enemy's attacks.
- **Scene.** Turn 2, you have a Jack Hare in F2 and a unit in F4, leaving F1 and F3 empty. In the fight the enemy's 3/2 attacks the hare; it darts right into F3 and the attack misses. Your hare survives the first exchange and kills their next attacker. On turn 6 you replace it with a Brown Hare Courier, which dodges their big front unit and then bites it.
- **Good against.** Big single hitters and boards that rely on a few strong attacks. **Weak against.** Random pings and splash, and full boards (yours or a summon that fills your gaps). Its moves can break your own adjacency text.
- **Variations.**
  - **Zigzag.** Jink, but it can dart into any empty slot in its row, not only an adjacent one.
  - **Scrape.** The first time each combat this is attacked, if the slot behind it is empty, it drops into that back slot and the attack misses.
  - **Swerve.** The first time each combat this is attacked, if a slot next to it is empty, the attack misses (it doesn't move).
- **Similar to.** Like a dodge or evade chance in many RPGs, but certain and visible from the board instead of random.
- **Designer's response.** No owner reaction. I settled the review's open points: right if both slots are empty, and a dart doesn't cost the hare its attack.
- **Open.** If a redirect (Shoulder) makes the hare the defender, does it still dart? Proposed: yes; it is attacked either way.
- **Open.** Does a dart onto a slot with a slot effect (8.5) pick that effect up? Proposed: yes, slot effects apply to whoever stands there.
- **Rules review (clean).** Works: the dart happens in 9.6.1 step 1 and the 'defender gone' line ends the attack, and keeping the flag is a stated exception to 9.4.9. Brown Hare Courier's counterattack is an out-of-turn attack that should queue after the missed attack ends (R5). Picking up a slot effect on landing follows 8.5.1; readable, and placement decides how many dodges you get.
- **Budget review.** Jink is cheap because it needs a gap; the Tier-3 hare is just over and fits at 3/3.
  - *Jack Hare*: in band. T1 2/2: body 4 + one Divine-Shield-like block 1.8 x about 0.6 chance of an empty slot beside it on turns 1-4 = 1.1 (E20, E32) [guess] = 5.1 vs V(1) 5: +2%. Same as the old line.
  - *Brown Hare Courier*: flag over. T3 3/4: body 7 + Jink 3.0 x about 0.5 chance of an empty neighbour slot = 1.5 + attacking the attacker after a dart (about 3 x 0.8 x 0.5) = 1.2 [guess] = 9.7 vs V(3) 8: +21% (+-15%). Change: 3/3 (6 + 1.5 + 1.2 = 8.7, +9%).
  - *Warren Matron*: in band. T5 4/6: body 10 + a second dart for about 2 Jink units (4.4 x about 0.3 chance of an empty slot late x 0.7 chance the first dart happened) = 1.8 [guess] = 11.8 vs V(5) 12: -2% (+-15%). Blank on full boards.
- **From.** creatures 15 (marked variant by the designer).

## G. Attack order and timing

### 23. Headstart — VARIANT of Battlegrounds' Heroic Broodmother

This attacks once before the fight proper, but it tires and loses 1 Attack every time it attacks.

- **Rules.** Headstart. After Start of Combat and before either side's first attack, this makes one attack. Then it attacks in normal order. Each time it attacks, it loses 1 Attack for this combat (after the attack). Headstart attacks don't move the attack pointer (as 9.4.12). If both sides have Headstart units, the side that attacks first goes first; within a side, reading order.
- **Bends.** 9.2.1 (who attacks first) and 9.4.2 (attack order).
- **Creatures.** Hare. The fastest runner who tires and loses the race (Folio: “Losing racers, forever beaten by hedgehogs”).. **Archetypes.** BURST
- **Example units.**
  - *March Hare*, Tier 1, 3/1, Hedgerow folk. Headstart.
  - *Starter's Rook*, Tier 2, 2/3, Birds. Your Headstart units have +2 Attack for their Headstart attack.
  - *Racing Hare*, Tier 4, 5/4, Hedgerow folk. Headstart. If this kills a unit with its Headstart attack, it doesn't lose Attack for that attack.
- **How they play.** The hares open the fight by picking off a token or a weak front unit before anyone else moves. The Rook makes that first strike much harder, so a March Hare can take out a 5-Health unit on turn 2. The Racing Hare doesn't tire if its opening shot is a kill, so it rewards picking fights it can win.
- **Why run it.** It strips a layer before the fight starts: a shield, a decoy, a token or a buffer. That changes who wins the trades that follow.
- **Scene.** Turn 3, your opponent's board leans on a 2/4 front unit that buffs its neighbours. You have a March Hare and buy a Starter's Rook. In the fight, before anyone attacks, the hare hits the buffer for 5 and kills it. The hare dies to the return blow, but their board loses its buffs before the first trade.
- **Good against.** Boards that rely on one key front unit, tokens or a protective layer. **Weak against.** A hedgehog with Bristle in front (the fable: the hare dies on the spikes), and long fights where it has faded.
- **Variations.**
  - **Tortoise.** This starts each combat with 0 Attack and gains +1 Attack each time an enemy attacks. (The mirror: slow, then strong.)
  - **False Start.** Headstart, but its Headstart attack targets the enemy's leftmost front-row unit.
  - **Sprint (time-bound).** Headstart. Each turn you don't move this, it gains +1 Attack permanently, up to 3 turns; moving it resets the count.
- **Similar to.** The hare in Aesop's “The Tortoise and the Hare”; mechanically like a first-turn ambush.
- **Designer's response.** No owner reaction. Kept as written, with the ordering rule from the review. The Sprint variation is a time-bound version in the spirit of pillar 13.
- **Open.** Does a Headstart attack count toward who attacks first afterwards? Proposed: no; the normal first attacker still goes first after the Headstart attacks.
- **Rules review (needs a ruling).** Works as an out-of-turn attack that leaves the pointer alone (9.4.12). Needs a ruling when both sides have Headstart units: 'the side that attacks first goes first' doesn't say whether that side makes all its Headstart attacks before the other side starts, or whether the sides alternate; proposed alternate, as in 9.4.1. The Attack loss after each attack is clear; readable.
- **Budget review.** Headstart fits at low tiers; the Tier-4 hare needs a smaller body.
  - *March Hare*: in band. T1 3/1: body 4 + an extra attack before the fight about A(1) 2 (E83) - the fade about 0.5 (E15) [guess] = 5.5 vs V(1) 5: +10%. Same as the old line.
  - *Starter's Rook*: in band. T2 2/3: body 5 + '+2 Attack on the Headstart attack' for about 1.5 Headstart units x 2 x 0.85 x 0.6 chance you have one = 1.5 [guess] = 6.5 vs V(2) 7: -7% (+-15%).
  - *Racing Hare*: flag over. T4 5/4: body 9 + Headstart attack about A(4) 4.0 - fade about 0.6 (the kill clause saves some) = 3.4 [guess] = 12.4 vs V(4) 10: +24% (+-15%). Change: 4/3 (7 + 3.4 = 10.4, +4%).
- **From.** combat 15.

### 24. Quick — NEW

In a fight between two units, this strikes first; if that kills the other unit, it takes no damage back.

- **Rules.** Quick. In an exchange (attacking or defending), this deals its damage first. If that kills the other unit, this takes no damage from it. Splash from this unit lands with its strike. Bristle on a unit this kills still fires. If both units are Quick, the exchange is simultaneous. Limits are set per card, not in the keyword: the high-tier version is Quick while this is undamaged, and the low-tier version is First Bite (Quick in this unit's first exchange each combat).
- **Bends.** 9.6.1 step 3 and 9.6.2: damage in an exchange is no longer simultaneous.
- **Creatures.** Stoat. It kills with one fast bite; the Folio's stoat “war-dance troupe”.. **Archetypes.** TALL, SCAM
- **Example units.**
  - *Stoat War-Dancer*, Tier 2, 3/2, Hunters. First Bite (this is Quick in its first exchange each combat).
  - *Weasel Second*, Tier 3, 2/4, Hunters. Start of Combat: the unit in front of this gains First Bite for this combat.
  - *Ermine Duellist*, Tier 5, 7/5, Hunters. Quick while this is undamaged.
- **How they play.** The War-Dancer wins its first trade against anything with 3 Health or less and walks away unhurt, then fights normally. The Weasel Second hands a single First Bite to whatever stands in front of it, often your own front carry. The Duellist kills cleanly as long as nothing has scratched it, so it is strong on a protected board and weak against pings: one point of damage and it trades normally.
- **Why run it.** A Quick carry wins exchanges against anything it can kill in one hit, so it survives much longer. The limits keep it from being free: First Bite works once, and the Duellist loses Quick to the first scratch.
- **Scene.** Turn 9, your opponent's front row is three 6/6 units. Your Ermine Duellist, buffed to 8/6, attacks one and kills it without taking a hit, then kills a second. Their board has a Start of Combat pinger, though, and in the next fight it deals 1 damage to the Duellist first, so it loses Quick and trades normally with the third unit.
- **Good against.** Boards of medium units the Quick unit can kill in one hit. **Weak against.** High-Health units, Bristle (it still fires), hit-blocking layers such as Shell or Hunker, and any ping that damages it first (for the undamaged version).
- **Variations.**
  - **First Bite.** This is Quick in its first exchange each combat. (Low-tier limit.)
  - **Quick (attacking only).** When this attacks, it deals its damage first; when it is attacked, damage is simultaneous.
  - **Outpace.** This is Quick against units with less Attack than it. (The faster unit strikes first.)
- **Similar to.** First strike in Magic: The Gathering.
- **Owner's direction.** “Quick seems incredibly strong. That would be a very, very hard effect to balance. It would be on high-tier units; it absolutely could be, but it would need to go on high-tier units. … we'd need some sort of limits attached to it.”
- **Designer's response.** I followed this: the full keyword sits on a Tier 5 unit and only while it is undamaged, and the low tiers get First Bite, which works once per combat. I'd push back gently on “almost impossible”: Bramble already has natural answers in Bristle, Shell, Hunker, pings and high Health, so Quick has counters without extra rules.
- **Open.** Which limit reads best: undamaged, first exchange, attacking only, or against lower Attack?
- **Open.** Does Peck plus Quick deal all its pecks first? Proposed: yes, as the review said.
- **Rules review (clean).** Works as a first-strike handler in the exchange (E90), with both-Quick, splash and Bristle cases stated, and the high-tier limits follow the owner's ask. Order against Ambush: Ambush strikes in 9.6.1 step 1, before any exchange, so it still beats Quick. 'Quick while undamaged' reads well; First Bite is clear.
- **Budget review.** The owner's limits (first exchange only, or while undamaged) keep Quick near budget; the Tier-5 duellist still needs a smaller body.
  - *Stoat War-Dancer*: in band. T2 3/2 First Bite: body 5 + first strike in its first exchange: Divine Shield's 2.25 x about 0.5 chance 3 damage kills a Tier-2 unit = 1.1 (E90) [guess] = 6.1 vs V(2) 7: -13% (+-15%).
  - *Weasel Second*: in band. T3 2/4, back: body 5.5 + First Bite for the unit in front (3.0 x about 0.5 x 0.9 fill) = 1.35 [guess] = 6.85 vs V(3) 8: -14% (+-15%). A back slot has two slots in front; if both get First Bite it is about 8.2 (+3%).
  - *Ermine Duellist*: flag over. T5 7/5 Quick while undamaged: body 12 + first strike 4.4 x about 0.6 one-shot chance x about 1.4 (it stays undamaged after a clean kill and strikes first again) = 3.7 [guess] = 15.7 vs V(5) 12: +31% (+-15%). Change: 6/4 (10 + 4.4 x 0.5 x 1.3 = 2.9 = 12.9, +7.5%).
- **From.** combat 16.

### 25. Swarm — NEW

When one Swarm unit attacks, every other Swarm unit in its row joins in on the same target, and only the leader takes the return blow.

- **Rules.** Swarm. When a Swarm unit attacks, every other Swarm unit in its row that can attack and hasn't attacked this cycle joins in, hitting the same target at the same time. The target hits back only the unit that started the attack. Every joiner counts as having attacked this cycle. Units that are stopped (Mired, entranced) don't join. Bristle and Curl prick each joiner one by one.
- **Bends.** 9.4.1 and 9.4.5: one attack per side per turn, from one unit. The pointer is set by the leader and every joiner is flagged. 9.6.1: the exchange is no longer one against one.
- **Creatures.** Honeybee and bumblebee. Bees mob an intruder together. Wolves' Pack is the same idea for Hunters.. **Archetypes.** WIDE
- **Example units.**
  - *Worker Bee*, Tier 1, 1/1, Hive. Swarm.
  - *Bumblebee Nurse*, Tier 2, 2/3, Hive. Swarm. When a friendly Swarm unit dies, your Swarm units gain +1 Health for this combat.
  - *Drone Captain*, Tier 4, 3/3, Hive. Swarm. Your other Swarm units have +1 Attack while they join this one's attacks.
- **How they play.** Fill a row with bees. When the first bee attacks, the whole row piles on the same target, so four 1-Attack bees deal 4 at once and only one bee takes the hit back. The Nurse makes the swarm tougher as bees die, and the Captain adds +1 per joiner when it leads. Because joiners are flagged, the row makes one big attack per cycle instead of many small ones.
- **Why run it.** It lets a wide board of small units kill a big one, which they normally can't. It makes wide against tall a choice of shape, not only of numbers.
- **Scene.** Turn 4, your opponent has built one 4/9 carry in the front row. You have three Worker Bees and a Bumblebee Nurse in F1 to F4. In the fight the first bee attacks the carry and the whole row joins: 5 damage, and only one bee dies. The Nurse makes the others tougher. Next cycle the three survivors hit again for 4 and the carry falls. A few 1/1 bees took down their best unit.
- **Good against.** TALL boards with one or two huge units. **Weak against.** Cleave, splash and Curl, and Bristle, which pricks every joiner. Many small enemy units waste the swarm's focus.
- **Variations.**
  - **Pack (Hunters).** When this attacks, adjacent units with Pack join in (adjacent only, so gaps break the pack).
  - **Sting.** Swarm, and each joiner dies after the attack. Joiners deal double damage.
  - **Cloud.** Swarm, and the return blow is split evenly among all the bees that attacked (rounded down, the rest to the leader).
- **Similar to.** Like mob tactics in strategy games, or gang-up attacks in some tactics RPGs (Fire Emblem's adjacent support attacks).
- **Owner's direction.** “Swarm's really interesting. I like that idea a lot. That's really, really interesting to me.”
- **Designer's response.** Kept as written, with the review's rules made explicit: only bees that haven't attacked join, stopped units don't join, and pricks hit joiners one by one. I added a Pack version for the Hunters' wolves, which uses adjacency so slot placement matters.
- **Open.** Does a Swarm unit summoned mid-cycle join a later leader? Proposed: only if it isn't flagged (9.4.8).
- **Open.** Should the back row's Swarm units join a front-row leader? Proposed: no, row only.
- **Rules review (clean).** Works: the leader sets the pointer, joiners are later unflagged units in its row and get flagged (9.4.5), and the return blow hits only the leader. Each joiner's damage is its own hit, so Hunker halves each and Bristle pricks each; the simultaneous-hit question belongs to Shell's ruling. A Thicket is a valid target, as the designer proposes; readable.
- **Budget review.** Swarm is in band except the 1/1 bee, which is too small for Tier 1.
  - *Worker Bee*: flag under. T1 1/1: body 2 + Swarm about 0.6 (joiners skip retaliation; needs a partner in its row; E90) [guess] = 2.6 vs V(1) 5: -48%. Same as the old line. Change: 2/2 (4 + 0.8 = 4.8, -4%).
  - *Bumblebee Nurse*: in band. T2 2/3: body 5 + Swarm 0.6 + '+1 Health this combat' to about 2 Swarm units on each of about 2 Swarm deaths x 0.9 x 0.7, x 0.6 chance of other bees = 1.5 [guess] = 7.1 vs V(2) 7: +1% (+-15%).
  - *Drone Captain*: in band. T4 3/3: body 6 + Swarm 0.6 + '+1 Attack' to about 3 joiners x about 1.25 attacks it leads x 0.85 = 3.2 [guess] = 9.8 vs V(4) 10: -2%. Same as the old line.
- **From.** creatures 5.

## H. Kills, overkill and survival

### 26. Gorge — VARIANT of Battlegrounds' Overkill and Wildfire Elemental

When this kills a unit with more damage than it needed, it gains the extra as Health.

- **Rules.** Gorge. When this kills a unit by attacking it, this gains Health equal to the excess damage for this combat. Excess is the damage that actually landed (after Shell, Hunker and other reductions) minus the target's Health before the hit.
- **Bends.** 9.6.3: excess damage below 0 is normally lost. Here it is a resource.
- **Creatures.** Wolverine, the “mountain glutton” (Folio seed “The Gluttons”); pine martens and badgers.. **Archetypes.** TALL
- **Example units.**
  - *Pine Marten Glutton*, Tier 2, 4/2, Hunters. Gorge.
  - *Glutton Wolverine*, Tier 4, 6/4, Hunters. Gorge. After this gorges three times in one combat, it gains +2/+2 permanently.
  - *Acorn Slinger*, Tier 2, 2/2, Hedgerow folk. Start of Combat: deal 1 damage to two random enemies.
- **How they play.** The gluttons attack small units and grow from the overflow: a 6-Attack Wolverine that kills a 1/1 token gains 5 Health. The Slinger softens targets first, so more of each hit is excess. The Wolverine gets permanent stats from a big feast, so it scales from fighting wide boards.
- **Why run it.** It is a front carry that heals and grows as it fights, so it lasts longer the more it kills.
- **Scene.** Turn 6, your opponent goes wide with 1/1 and 2/2 tokens. You put a Glutton Wolverine in F1. In the fight it eats a 1/1 (+5 Health), a 2/2 (+4) and another 1/1 (+5). After the return blows it ends at 6/14, wins the fight and gains +2/+2 for good.
- **Good against.** WIDE boards of small tokens. **Weak against.** Sturdy medium units that die to exactly its hit, and hedgehogs that prick it each meal.
- **Variations.**
  - **Gorge (Attack).** When this kills a unit by attacking it, it gains Attack equal to the excess damage for this combat.
  - **Stash.** When this kills a unit by attacking it, gain Acorns equal to the excess damage, at most 2 per combat. (Hedgerow economy tied to fighting.)
  - **Trample.** When this kills a unit by attacking it, the excess damage hits the enemy unit behind it. (Great beasts' version.)
- **Similar to.** Lifesteal in many games, but paid only from the overkill.
- **Owner's direction.** On Hunters' Devour (02h): “I don't necessarily think you need something that's capped per combat.”
- **Designer's response.** That remark was about Devour, but it fits Gorge too: I put no cap on Gorge. The Wolverine's permanent gain needs three meals in one combat, which is a trigger, not a cap.
- **Open.** With Peck, only the last peck has excess. Is that the right reading?
- **Rules review (clean).** Works with excess defined as landed damage minus the target's Health. Say that against a Knotted target the landed damage is the part that stayed on the target after the split, and that with Peck only the killing strike has excess. The Wolverine's 'three times' is a counter and stays 3 on a golden (7.3.5); readable.
- **Budget review.** Gorge is in band; the pinging helper is a little under.
  - *Pine Marten Glutton*: in band. T2 4/2: body 6 + about 0.6 kills x about 1.5 excess as Health this combat x 0.7 = 0.6 (E03 on R23) [guess] = 6.6 vs V(2) 7: -6% (+-15%).
  - *Glutton Wolverine*: in band. T4 6/4: body 10 + Gorge about 1.5 + '+2/+2 permanently after three gorges in one combat' (about 0.1 of fights x 4 SP = 0.4 SP a fight; c_combat(4) 2.1 x 0.4 = 0.8) [guess] = 12.3 vs V(4) 10: +23% (+-25%, permanent growth). Near the line.
  - *Acorn Slinger*: edge. T2 2/2: body 4 + Start of Combat 1 damage to two random enemies (E72: 2 x 0.85 = 1.7) [guess] = 5.7 vs V(2) 7: -19% (+-15%). Change: If the sim agrees: 2/3 (6.7, -4%).
- **From.** combat 14.

### 27. Bloodied — VARIANT of Battlegrounds' Frenzy

Once this has taken enough damage to drop to half Health, it gets angry and its effect fires once.

- **Rules.** Bloodied: [effect]. The first time each combat this survives damage that leaves its Health at half its maximum or lower (half rounded down), the effect happens. It checks only when this takes damage, after the death check. On a golden unit the threshold is still half.
- **Bends.** 9.6.3: adds a threshold between full Health and death.
- **Creatures.** Wild boar. In hunting lore a wounded boar is the most dangerous animal in the forest.. **Archetypes.** TALL, STICKY
- **Example units.**
  - *Boar Piglet*, Tier 1, 2/4, Great beasts. Bloodied: gain +3 Attack for this combat.
  - *Wounded Tusker*, Tier 3, 3/6, Great beasts. Bloodied: gain Attack equal to its Attack for this combat.
  - *Sounder Sow*, Tier 5, 4/8, Great beasts. Bloodied: your other Great beasts gain +2/+2 for this combat.
- **How they play.** The boars want to be hit, but not killed. A Piglet that takes 2 survives at 2 and jumps to 5 Attack. The Tusker doubles its current Attack once (so buff it before it is hit). The Matriarch is a large body that makes the whole herd tougher once it is wounded. Damage reduction (Hunker, Shell) makes the threshold easier to reach without dying.
- **Why run it.** The enemy has to kill a boar in one hit or face the angry version, which makes your front line harder to trade with.
- **Scene.** Turn 5, your Wounded Tusker has been buffed to 6/10. In the fight an enemy 5/5 attacks it. The Tusker drops to 5 Health and kills the attacker in the same exchange; it is Bloodied and becomes 12/5, and its next attack kills their biggest front unit.
- **Good against.** Many small hits and chip damage. **Weak against.** One big hit that kills it outright, and effects that set or swap Health.
- **Variations.**
  - **Last Stand.** The first time each combat this survives at 1 Health, [effect].
  - **Enraged.** While this is damaged, it has +X Attack.
  - **Wounds.** Each time this survives damage that takes it below a quarter, half and three quarters of its maximum Health, [effect]. (Up to three triggers.)
- **Similar to.** Enrage in classic Hearthstone (an effect while damaged); boss phases at half health in action games.
- **Designer's response.** No owner reaction. I took the review's fixes: half rounded down, checked only on damage, and the Tusker's text written as a one-off gain, not a multiplier.
- **Open.** If an aura raising its maximum Health is lost mid-combat, can that trigger Bloodied? Proposed: no; it checks only when it takes damage.
- **Rules review (clean).** Works: it checks only on damage, after the death check, once per combat, and the threshold stays half on a golden (7.3.5). Lost-aura Health doesn't trigger it, as proposed. Name clash: this Sounder Sow (T5 4/8) and Scar's Sounder Sow (T6 5/9) are different cards with the same name.
- **Budget review.** Bloodied payoffs are fair, but every boar's body is already at or over budget before its text.
  - *Boar Piglet*: flag over. T1 2/4: body 6 (+20% before text) + '+3 Attack this combat' at half Health (fires in about 0.5 of fights, then about 0.5 attacks left) = 1.0 (E03 on an R24 threshold) [guess] = 7.0 vs V(1) 5: +40% (floor +-20%). Change: 1/3 (4 + about 0.8 = 4.8, -4%).
  - *Wounded Tusker*: flag over. T3 3/6: body 9 + doubling its Attack once at half Health (E06 in combat, about 0.7 of fights, about one attack left) = 2 [guess] = 11 vs V(3) 8: +38% (+-15%). Same as the old line. Change: 3/4 (7 + about 1.5 = 8.5, +6%).
  - *Sounder Sow*: flag over. T5 4/8: body 12 + '+2/+2 this combat' to about 2.5 other Great beasts in about 0.7 of fights x 0.6 realised = 4.2 [guess] = 16.2 vs V(5) 12: +35% (+-15%). Change: 3/6 (9 + 4.2 = 13.2, +10%).
- **From.** combat 17 (marked variant by the designer).

### 28. Play Dead — VARIANT of Battlegrounds' Reborn

The first time this would die, it fakes its death, lies still, then springs up and ambushes the next enemy that attacks next to it.

- **Rules.** Play Dead. The first time each combat this would die, it lies limp at 1 Health instead. While limp it can't be attacked and doesn't attack. The enemy's “after this kills” effects fire as if it had died; your own death effects and death counters don't (it didn't die). After the next enemy attack on a unit adjacent to it (and that attack's deaths), it springs up and attacks that attacker immediately. If no other friendly unit can attack, it springs up at once. Random and group effects can still hit it while limp, and damage while limp kills it for real.
- **Bends.** 9.6.3: a unit at 0 Health doesn't die. 9.7.2: kill triggers fire with no death. 9.5: it leaves the candidate list. 9.4.12: it attacks out of turn.
- **Creatures.** Fox. Reynard, in the old fables, plays dead by the road to catch the crows that come to peck him.. **Archetypes.** SCAM, STICKY
- **Example units.**
  - *Vixen Cub*, Tier 1, 2/1, Hunters. Play Dead.
  - *Roadside Reynard*, Tier 3, 3/3, Hunters. Play Dead. When this springs up, it has +4 Attack for that attack.
  - *Old Fox of the Sett*, Tier 5, 4/6, Hunters. Your limp units can't be hit by enemy effects.
- **How they play.** Place the foxes beside the units the enemy will attack next. When a fox goes limp, the enemy's on-kill effects fire for nothing, and the fox waits. When the enemy attacks its neighbour, Roadside Reynard springs up and hits that attacker for 7. The Old Fox protects limp foxes from the random pings that would otherwise finish them.
- **Why run it.** It is a second life that ends in an ambush, and it wastes the enemy's kill triggers (Hunt, Gorge).
- **Scene.** Turn 6, your opponent runs a Glutton Wolverine. In the fight it kills your Roadside Reynard, which lies limp; the Wolverine's Gorge fires, but the fox isn't dead. The Wolverine then attacks the unit beside the fox: Reynard springs up and hits it for 7, and it dies.
- **Good against.** On-kill payoffs and big single attackers. **Weak against.** Random damage and splash that finish limp foxes, and boards with gaps (no adjacent unit to wait beside).
- **Variations.**
  - **Feign.** The first time each combat this would die, it stays at 1 Health and can't be attacked until your next cycle starts.
  - **Possum Trap.** Play Dead, but instead of springing up, the next enemy that attacks next to it takes damage equal to this unit's Attack.
  - **Regrow (Bog folk newt).** The first time each combat this would die, it lies limp, and at the start of your next cycle it returns to full Health.
- **Similar to.** Feign Death in World of Warcraft; Reynard the Fox fables.
- **Designer's response.** No owner reaction. I renamed the example to avoid the clash with Alibi's Reynard's Clerk, and I settled the review's open points: only enemy kill effects fire, and the spring-up waits for that attack's deaths.
- **Open.** Does a side with only a limp fox count as empty for 9.9.1? Proposed: no, and it springs up at once.
- **Rules review (needs a ruling).** Mostly well specified: kill triggers fire without a death, the spring-up waits for that attack's deaths, and the 'no other friendly unit can attack' line prevents a stall on its own side. Needs a ruling on back-row protection: a limp front-row unit 'can't be attacked', so either it still counts as a front-row unit and, as the only one, makes your back row unattackable until it springs, or 9.5.3 turns it back into a candidate; proposed: limp and asleep units don't count for 9.5.1 (R7). The spring-up attack is out of turn (R5).
- **Budget review.** Play Dead is a second life plus a free attack; it fits on the cub, and the Tier-3 fox needs a smaller spring bonus.
  - *Vixen Cub*: in band. T1 2/1: body 3 + a second life (Reborn-like, 0.4 x 3 = 1.2; E96) + springing up to attack, 2 x 0.85 x 0.8 = 1.4 [guess] = 5.6 vs V(1) 5: +12% (floor +-20%).
  - *Roadside Reynard*: flag over. T3 3/3: body 6 + second life about 2.4 + springing with +4 Attack about 2.7 [guess] = 11.1 vs V(3) 8: +39% (+-15%). Same as the old Reynard's Clerk. Change: 2/3, and +2 Attack on springing (5 + 2.0 + 1.4 = 8.4, +5%).
  - *Old Fox of the Sett*: in band. T5 4/6: body 10 + limp units safe from enemy effects (about 1.5 limp units x 0.15 chance an effect would finish one x about 5 SP) = 1.1 [guess] = 11.1 vs V(5) 12: -7.5% (+-15%).
- **From.** creatures 14.

### 29. Last Word — NEW

This turns a fight that would be a draw into a win for you.

- **Rules.** Last Word (once per combat). If a death resolution would leave both boards empty and this is among the dying, it survives with 1 Health instead. If combat would end because neither side can attack, and +1 Attack would let this attack, it gains +1 Attack and combat goes on.
- **Bends.** 9.9.1 and 9.9.2: both ways a fight ties.
- **Creatures.** Wren. The wren hid on the eagle's back, flew highest and was crowned king of birds for being the last one up (Folio hook “A small unit rides a big one”).. **Archetypes.** STICKY, SCAM
- **Example units.**
  - *Jenny Wren*, Tier 2, 1/2, Birds. Last Word.
  - *Crowned Wren*, Tier 5, 2/3, Birds. Last Word. When Last Word saves this, it gains +4/+4 for this combat.
  - *Golden Eagle Elder*, Tier 4, 5/6, Birds. A Bird riding this gains Last Word.
- **How they play.** The wren does nothing until the last moment. If the fight would end with both sides wiped out, it survives at 1 Health and you win. The Crowned Wren wins by more. With the Eagle Elder and Ride, the wren sits on the eagle and saves the fight when the eagle falls.
- **Why run it.** Late fights between sticky boards often end empty on both sides. A win instead of a tie means hero damage for you.
- **Scene.** Turn 11, you and your opponent both have strong sticky boards. In the fight your last unit and theirs trade; your Jenny Wren is among the dying, but Last Word saves it at 1 Health. You win the fight instead of tying it.
- **Good against.** Even fights, Curl or Hunker walls, and Whistle-only boards that stall. **Weak against.** Opponents who kill the wren before the last trade, and fights that aren't close.
- **Variations.**
  - **Tie Breaker.** If combat ends in a tie and this is on your board or died this combat, you deal hero damage as if you had won with this unit alone.
  - **Final Say.** While this is the last unit on your side, it has +3/+3.
  - **Encore.** If this is among the last units to die in combat, summon a 1/1 Wren in its slot.
- **Designer's response.** No owner reaction. I took the review's fix: once per combat, and the +1 Attack only if it lets a unit attack, so it can't loop.
- **Open.** Is it readable when it fires rarely? It may need a clear moment in the fight to be noticed.
- **Rules review (needs a ruling).** Needs a ruling on timing: 'a death resolution would leave both boards empty' can only be known after the whole pass (death effects, summons, returns, 9.7.2), so say the check happens at the end of the pass and the Last Word unit then comes back to its slot at 1 Health without firing its death effects again. The second clause (+1 Attack when neither side can attack) works and stops 9.9.1's tie; both sides having Last Word is finite because each is once per combat. Hard to notice when it fires; it needs a clear moment in the fight.
- **Budget review.** Last Word almost never fires, so both wrens are far under and need normal bodies.
  - *Jenny Wren*: flag under. T2 1/2: body 3 + Last Word about 0.3 (it acts only on ties and stalls; E92) [guess] = 3.3 vs V(2) 7: -53% (+-15%). Same as the old line. Change: Tier 1 at 2/2 (4.3, -14%), or Tier 2 at 2/4 (6.3, -10%).
  - *Crowned Wren*: flag under. T5 2/3: body 5 + Last Word about 0.4 + '+4/+4 this combat' when saved (about 0.1 x 8 x 0.5 = 0.4) [guess] = 5.8 vs V(5) 12: -52% (+-15%). Change: 5/6 (11 + 0.8 = 11.8, -2%).
  - *Golden Eagle Elder*: in band. T4 5/6: body 11 (+10% before text) + Last Word for a Bird rider (about 0.3 x 0.4 chance a Bird rides it) = 0.1 [guess] = 11.1 vs V(4) 10: +11% (+-15%).
- **From.** combat 18.

### 30. Bud — VARIANT of Battlegrounds' Silver Goose

Whenever this blob survives a hit, it splits into two smaller blobs.

- **Rules.** Bud. Whenever this survives damage and has at least 2 Health, it splits: it loses half its current Attack and half its current Health (rounded down), and a copy with that Attack, Health and text appears in the nearest empty slot. Split copies are combat-only. A full board means no split.
- **Bends.** 9.6.3: damage normally only lowers Health; here it also makes bodies. 8.4.2: where the bud lands.
- **Creatures.** Ooze. Oozes are unstable magic slime; real slime moulds split and rejoin.. **Archetypes.** TALL, WIDE
- **Example units.**
  - *Jelly Drop*, Tier 1, 2/4, Oozes. Bud.
  - *Pudding Ooze*, Tier 4, 6/10, Oozes. Bud.
  - *Slime Mould Sage*, Tier 5, 3/6, Oozes. Whenever a friendly Ooze splits, both halves gain +1/+1 for this combat.
- **How they play.** You pump one big blob in the shop. In the fight, every hit it survives splits it, filling your empty slots with copies. The Sage makes every split add stats, so chip damage turns a big blob into a wide board. Leave slots empty for buds to land in.
- **Why run it.** It is TALL in the shop and WIDE in the fight: one unit to buff, many bodies once it is hit.
- **Scene.** Turn 7, you have pumped a Pudding Ooze to 12/16 and left four slots empty. In the fight an enemy 4/4 hits it: it drops to 12/12, splits into two 6/6s, and with the Sage both become 7/7. Each later hit splits again until your board is full.
- **Good against.** Many small hits and chip damage. **Weak against.** One big hit that kills it outright, and Cleave or splash that hits the buds together.
- **Variations.**
  - **Split (on death).** When this dies, summon two copies with half its Attack and Health (rounded down).
  - **Shed.** Whenever this survives damage, summon a 1/1 Ooze with no text in the nearest empty slot.
  - **Rejoin.** When a bud of this dies, this gains that bud's remaining Attack for this combat.
- **Similar to.** Splitting slimes in many RPGs and roguelikes (the slimes in Slay the Spire).
- **Owner's direction.** On Oozes as a tribe (02h): “They work around buffing the shop and amalgamating things into them, and eating each other, and combining and splitting. Yeah, there could be some cool stuff there. I like that as an idea. Let's keep exploring it.”
- **Designer's response.** Bud is the splitting half of that: grow by merging in the shop, fight by splitting. I added the review's minimum (no split below 2 Health).
- **Open.** Do buds count for hero damage if they survive? Proposed: yes, each as a copy of the card's tier.
- **Open.** With Peck, the ooze can fill the board in one attack. Is that acceptable, given the 7-slot limit?
- **Rules review (needs a ruling).** Needs a ruling that 'loses half its current Health' lowers maximum Health and is not damage; if it were damage, each split would trigger Bud again until the unit is at 1 Health. With that, it is bounded by the 7 slots and the halving, and buds use 8.4.2 placement and 9.4.8 flags. Say whether a bud 'appearing' is a summon (Delivery, Mark and Bury read summons); proposed yes.
- **Budget review.** Splitting adds no stats, so Bud is cheap, but the oozes' bodies are large and the Sage's payoff doubles on every split.
  - *Jelly Drop*: flag over. T1 2/4: body 6 + Bud about 1.0 (more bodies and attacks against chip damage, worse against Cleave; E95) [guess] = 7.0 vs V(1) 5: +40% (floor +-20%). Change: 2/3 (5 + 1.0 = 6.0, +20%, on the floor).
  - *Pudding Ooze*: flag over. T4 6/10: body 16 (+60% before text) + Bud about 1.5 [guess] = 17.5 vs V(4) 10: +75% (+-15%). Same as the old line. Change: 4/5 (9 + 1.5 = 10.5, +5%).
  - *Slime Mould Sage*: flag over. T5 3/6: body 9 + '+1/+1 this combat' to both halves of about 3 splits a fight in an Ooze build (copies split again until the board fills) x 4 SP x 0.6 = 7.2 [guess] = 16.2 vs V(5) 12: +35% (+-15%). Change: 3/5, and only the new copy gains +1/+1 (8 + 3 x 2 x 0.6 = 3.6 = 11.6, -3%).
- **From.** creatures 7.

## I. Extra bodies, off-slot zones and switching sides

### 31. Ride — VARIANT of Battlegrounds' Magnetic plus a Deathrattle summon

A small unit rides on a bigger one; when the mount dies, the rider leaps off and attacks.

- **Rules.** Ride. Play this onto a friendly unit with more Attack instead of into a slot. It rides that unit: it uses no slot, can't be targeted or hit by any effect, and can be played onto a full board. One rider per mount. When the mount dies, the rider leaps into the mount's slot before the mount's own death effects summon (those go to the nearest empty slot), then attacks immediately. Stowaway is the same with no Attack limit and no attack on leaping.
- **Bends.** 8.1.1 and 7.2.2: the board can hold more than 7 bodies. 8.4.1: the rider jumps ahead of the mount's own summons. 9.4.12: it attacks out of turn.
- **Creatures.** Wren, from the fable of the wren on the eagle's back (Folio hook “Rider”). The Folio's mice “ride larger allies into battle”.. **Archetypes.** STICKY, WIDE
- **Example units.**
  - *Field Mouse Squire*, Tier 1, 1/2, Hedgerow folk. Stowaway. While this rides a unit, that unit has +1 Health.
  - *Wren King*, Tier 2, 2/1, Birds. Ride. When this leaps, it has +2 Attack for that attack.
  - *Brown Bear Porter*, Tier 4, 5/7, Great beasts. This can carry two riders.
- **How they play.** Riders go on your big units: the mouse adds Health while it rides, and the Wren King bursts out when the mount dies and hits for 4. The Bear Porter carries two, so each of its deaths gives you two more bodies. Every mount takes two kills.
- **Why run it.** It gets more bodies than slots onto the board, and each mount becomes a two-part threat.
- **Scene.** Turn 5, your board is full. You buy a Wren King and play it onto your 6/6 bear. In the fight the enemy kills the bear; the wren leaps into its slot and pecks a damaged enemy to death.
- **Good against.** Boards that win by trading one for one. **Weak against.** Cleave and splash, if they hit riders too; mounts that never die.
- **Variations.**
  - **Stowaway.** Play this onto any friendly unit. When it dies, this takes its slot (no attack on leaping).
  - **Pouch.** This carries one friendly unit with less Attack, which leaps out when this dies.
  - **Swap Mount.** Ride. In the Recruit Phase you may move a rider to another mount for free.
- **Similar to.** Magnetic in Battlegrounds, but the rider stays itself and separates on death.
- **Designer's response.** No owner reaction. I kept both shapes (Ride and Stowaway) and settled the leaping order from the review.
- **Open.** Does a rider count for who attacks first, hero damage and triples? Proposed: not for who attacks first; yes for hero damage and triples.
- **Open.** What happens when the mount is sold? Proposed: the rider goes to hand if there is room; otherwise it is sold too.
- **Rules review (needs a ruling).** Works as an off-slot zone (R7) with its leap timing stated, but several of R7's questions are open: whether riders count for who attacks first (proposed no), hero damage and triples (proposed yes), and whether 'can't be targeted or hit by any effect' blocks your own buffs too. Also rule what happens to the rider when the mount is sold, tripled or transformed (proposed: to hand, else sold). The leap's 'attacks immediately' fires inside death resolution and should queue after it (R5).
- **Budget review.** Riders fit at their tiers; the bear mount is over on body size, and the saved-slot price needs a sim.
  - *Field Mouse Squire*: in band. T1 1/2 Stowaway: body 3 x 0.9 (it enters when the mount dies) = 2.7 + no slot used about 1 (E23) + the mount's +1 Health about 0.9 [guess] = 4.6 vs V(1) 5: -8%.
  - *Wren King*: in band. T2 2/1: body 2.7 + attacks at once with +2 Attack about 2.4 (E83) + no slot about 1 [guess] = 6.1 vs V(2) 7: -13% (+-15%). Same as the old creatures version.
  - *Brown Bear Porter*: flag over. T4 5/7: body 12 (+20% before text) + a second rider seat (another saved slot about 1 x about 0.4 chance of two riders) = 0.4 [guess] = 12.4 vs V(4) 10: +24% (+-15%). Change: 5/5 (10 + 0.4 = 10.4, +4%). For information: E23's +1 for a saved slot likely under-prices an eighth or ninth body on a full late board; sim riders before printing them above Tier 2.
- **From.** creatures 10, rows 6 (both marked variant by their designers).

### 32. Burrow — VARIANT of Battlegrounds' Deity

This digs underground at the start of combat, safe from everything, and pops up to attack when a friendly unit dies.

- **Rules.** Burrow. Start of Combat: this goes underground. It leaves its slot and can't attack, be attacked or be hit by any effect. A molehill stays in its slot and blocks summons there. After the first friendly death, it surfaces in that unit's slot (or the nearest empty one) and attacks immediately. If your side would be left with no units, it surfaces first.
- **Bends.** 9.1.2: this unit is in combat but on no slot, a new zone. 9.4.12: it attacks out of turn when it surfaces. Units are counted for who attacks first (9.2.1) before it digs.
- **Creatures.** Mole. Moles come up where you don't expect them; the Folio's “velvet conspirators” had a molehill topple a king.. **Archetypes.** WIDE, STICKY
- **Example units.**
  - *Mole Digger*, Tier 1, 2/2, Hedgerow folk. Burrow.
  - *Velvet Sapper*, Tier 3, 4/3, Hedgerow folk. Burrow. When this surfaces, it has +3 Attack for that attack.
  - *Velvet Conspirator*, Tier 5, 5/6, Hedgerow folk. Burrow. When this surfaces, your other underground units surface too, and all of them attack immediately.
- **How they play.** The moles are safe from Start of Combat damage and pop up as the first friendly unit falls. The Sapper hits for 7 on surfacing. The Conspirator brings every mole up at once, so a board with three moles ambushes with all of them after the first death.
- **Why run it.** It refills your board safely and hits back the moment you lose a unit.
- **Scene.** Turn 6, your opponent's board opens with Start of Combat pings. Your Velvet Sapper digs in and takes none. When their first attack kills your front unit, the Sapper surfaces in that slot and hits the attacker for 7.
- **Good against.** Start of Combat damage and boards that kill one unit quickly. **Weak against.** Boards that kill nothing for a long time, and opponents who see the molehill and plan the first kill.
- **Variations.**
  - **Tunnel.** Once per combat, after a friendly unit dies, this moves into its slot.
  - **Go to Ground.** Start of Combat: this goes underground. At the start of your second cycle it surfaces with +3/+3.
  - **Molehill.** When this surfaces, the enemy unit across from it takes 2 damage.
- **Similar to.** Burrowed units in StarCraft; Deity in Battlegrounds joins after deaths.
- **Designer's response.** No owner reaction. I settled the review's slot question: the molehill blocks summons, so the board shows where the mole is.
- **Open.** If no friendly unit dies and you win, does the mole count for hero damage? Proposed: yes, it survived.
- **Rules review (needs a ruling).** Works as an off-slot zone with a clear safety line (it surfaces before its side would be empty). Needs rulings: the mole surfaces in step 3 of 9.7.2, after the dead unit's own death summons, so say it then takes the nearest empty slot; and say the molehill clears when the mole surfaces elsewhere. Counting for who attacks first before it digs is stated; its 'attacks immediately' needs R5's queue.
- **Budget review.** Burrow is near budget; the Tier-3 mole's surfacing bonus needs a smaller body.
  - *Mole Digger*: in band. T1 2/2: body 4 + surfacing to attack at once about 0.8 + safety until the first death about 0.3 - an empty slot at Start of Combat about 0.2 on small boards (E96, E83) [guess] = 4.9 vs V(1) 5: -2%.
  - *Velvet Sapper*: flag over. T3 4/3: body 7 + the early attack about 1.5 + '+3 Attack' on it about 2.5 - empty slot 0.5 [guess] = 10.5 vs V(3) 8: +31% (+-15%). Same as the old line. Change: 3/2, keeping +3 Attack (5 + 3.5 = 8.5, +6%).
  - *Velvet Conspirator*: in band. T5 5/6: body 11 + early attack about 1.9 - empty slot 0.5 + surfacing the others about 0.3 (they already surface at the first friendly death under Burrow, so this adds little) [guess] = 12.7 vs V(5) 12: +6% (+-15%).
- **From.** creatures 3.

### 33. Changeling — NEW

At the start of the fight, this trades places with the enemy unit facing it, and each one fights for its new side.

- **Rules.** Start of Combat: this swaps places with the enemy unit across from it. For this combat, each of the two fights for the side it now stands on: it attacks for that side, counts as that side's unit for every effect, and its death counts for that side. Its owner keeps the card, so a 'permanently' effect on it still goes to its owner's recruit board. A unit can be swapped at most once per combat. If the slot across is empty, nothing happens.
- **Bends.** 9.1.1: each side fights with its own copied board; here a unit fights for the other side. 8.2.6: across from. 10.1.1 (proposal): a swapped unit counts for the side it ends the fight on.
- **Creatures.** The folklore changeling: fairies take a child and leave one of their own in its place.. **Archetypes.** SCAM
- **Example units.**
  - *Cradle Swapper*, Tier 2, 1/3, Fairies. Changeling.
  - *Changeling Babe*, Tier 4, 1/1, Fairies. Changeling. While this fights for the enemy, enemy units adjacent to it have -2 Attack.
  - *Hob of the Hollow Hill*, Tier 5, 4/6, Fairies. After a friendly Changeling swaps, give the unit it brought over +3/+3 this combat.
- **How they play.** Cradle Swapper is the cheap version: it trades a 1/3 for whatever the enemy put across from it. Changeling Babe goes over as a saboteur, weakening the two enemies next to it in their line. Hob sits in your back row and turns each stolen unit into a bigger threat against its own board. Stolen units still use their own text for you, so a stolen death-summoner summons on your side.
- **Why run it.** It takes the enemy's front unit for one fight and hands them a weak body in exchange. Inside any comp it is a SCAM piece that answers a big front carry without needing to kill it.
- **Scene.** Turn 8. You are on Tier 4 and the last fight showed that most boards in the lobby put their carry in the middle of the front row. You buy Changeling Babe and play it in F2. In the fight, the enemy's 14/14 boar stands in their F2. Start of Combat: the Babe and the boar swap. The boar now fights for you from your F2, and your Babe sits in their F2, giving their F1 and F3 units -2 Attack. Their board has to kill its own carry to win.
- **Good against.** TALL boards that keep one big carry in a predictable front slot. **Weak against.** WIDE boards of tokens (you steal a 1/1), boards with a gap across from it, and a cheap decoy placed in the mirrored slot.
- **Variations.**
  - **Glamour.** Start of Combat: this and the enemy unit across from it swap Attack and Health for this combat. Nobody changes sides. A simpler SCAM with no ownership rules.
  - **Borrowed Child.** Start of Combat: swap places with the enemy across from this, as Changeling. After the stolen unit attacks once, the two swap back to their own sides and slots (or the nearest empty ones). A time-bound theft.
  - **Front-row Changeling.** As Changeling, but only from the front row: in the back row it does nothing. Keeps back-row carries safe and the rule easier to read.
- **Similar to.** Like Hearthstone's Mind Control or Sylvanas Windrunner, but only for one fight, and paid for by sending your own unit over.
- **Owner's direction.** No reaction to this mechanic.
- **Open.** Name clash: archetypes.md uses 'Changeling' for a Fairy that copies the unit behind it. One of the two needs another name.
- **Open.** Should a back-row Changeling be able to swap with a back-row carry, or only the front row?
- **Open.** Hero damage: does a stolen unit that survives count its tier for the side it ended on (proposed in 10.1.1)?
- **Open.** Against Rival or Flush, the result depends on the random Start of Combat order (9.3.2). Is that acceptable?
- **Rules review (needs a ruling).** Needs R10's combat-side attribute for every 'friendly' and 'enemy' selector, which the text implies. Needs a ruling on 'a permanently effect on it still goes to its owner's recruit board': when the stolen unit belongs to the recorded opponent, that write is impossible (2.1.4, R9), so say permanent effects on a unit fighting for the other side are lost. Hero damage for a stolen survivor (10.1.1) and the clash with archetypes.md's Changeling name are open.
- **Budget review.** Stealing a unit is worth about twice that unit, so cheap Changelings get stronger as enemy boards grow; a limit on what they can steal keeps them in band all game.
  - *Cradle Swapper*: flag over. body 4 + swap (you gain the unit across and they lose it, less both bodies: 2 × X − 8, × 0.6 the slot is filled) ≈ 1.2–2.4 at turns 2–4 (X ≈ 5–6), ≈ 20 late (X ≈ 15) (proposed E94) [guess] ≈ 5.2–6.4 vs V(2) 7 early (−9% to −26%), ≈ 24 late (+240%), ±25% Change: 2/3, and swap only with an enemy that has 4 Attack or less: ≈ 5.5 at turns 2–4 (−21%), ≈ 7.5 from turn 6 (+7%). It still steals mid-size units; big carries are safe.
  - *Changeling Babe*: flag over. body 2 + swap (2 × X − 4) × 0.9 ≈ 9.4 at turn 6 (X ≈ 7.2), ≈ 23 late + −2 Attack to 2 enemy neighbours while it lives (E15 4.4 × 0.4 survival ≈ 1.8) [guess] ≈ 13.2 vs V(4) 10 at turn 6 (+32%), ≈ 27 late (+170%), ±25% Change: The old review's change still fits: 2/2, and only if the enemy across has 6 Attack or less: ≈ 10.2 at turn 6 (+2%), ≈ 10.5 late (+5%).
  - *Hob of the Hollow Hill*: in band. body 10 + +3/+3 this combat on the stolen unit (6 × 0.9 swaps × 0.8 realised × 0.6 a Changeling is on board ≈ 2.6, E03) [guess] ≈ 12.6 vs V(5) 12: +5%, ±15%. With two Changelings on board ≈ 18.6 (+55%)
- **From.** creatures 8.

### 34. Brood — NEW

At the start of the fight, this lays an egg in an empty slot on the enemy board, blocking it, and the egg later hatches into a chick for you.

- **Rules.** Start of Combat: lay an Egg in the enemy slot across from this if it is empty; otherwise in the empty enemy slot nearest it (8.4.2 order). If the enemy board has no empty slot, nothing happens. The Egg is not a unit: it can't attack, be attacked or be hit by effects, and it doesn't count for protecting the back row, attack order, winning or hero damage. It only fills the slot: no summon, move or return can enter it. After the enemy side has made 3 attacks (extra attacks count), the Egg hatches: remove it and summon a 3/3 Cuckoo Chick for you into your empty slot nearest this unit's slot (its last slot if it has died). If you have no empty slot, the hatch fails.
- **Bends.** 8.4: summons land only on their own side; Brood puts an object on the enemy board and takes their summon space. 9.9.1: the Egg is not a unit, so it never keeps a board alive.
- **Creatures.** Cuckoo, the brood parasite (Folio hook 'Sabotage').. **Archetypes.** SCAM, WIDE
- **Example units.**
  - *Cuckoo*, Tier 2, 2/2, Birds. Brood.
  - *Cuckoo Mother*, Tier 4, 3/4, Birds. Brood. Your Cuckoo Chicks hatch after 2 enemy attacks instead of 3 and have +2/+2.
  - *Reed Warbler Dupe*, Tier 3, 2/5, Birds. Whenever one of your Cuckoo Chicks is summoned, give it +1/+1 for each enemy unit that has died this combat.
- **How they play.** Cuckoo and Cuckoo Mother each lay an Egg, so two Eggs can take two of the enemy's gaps. The Mother makes the chicks hatch faster and bigger, so they arrive while the fight is still open. The Warbler, fooled into feeding the chick, makes late hatchlings huge. A Delivery stork (44) steers the chicks into your safest slot.
- **Why run it.** It answers WIDE boards that leave gaps for their summons: a summon with nowhere to land is lost (8.4.5). And after a few enemy attacks you get a free 3/3.
- **Scene.** Turn 5. Your opponent runs rabbits that bolt and leave Kits behind, and they keep one front slot open for them. You have a Cuckoo in F3. Start of Combat: their F3 is the gap, so the Egg goes there. Later their death-summoner in F1 dies: its first token takes F1, and its second token has nowhere to go, because the Egg holds their only gap, so it is lost. After their third attack, the Egg hatches and a 3/3 Chick joins your side.
- **Good against.** WIDE boards with one or two gaps kept for summons. **Weak against.** Full 7-unit boards (no Egg at all) and short fights that end before the enemy has made 3 attacks.
- **Variations.**
  - **Laid in Their Nest.** Start of Combat: lay an Egg under the enemy across from this. When that unit dies, the Egg takes its slot before that unit's own summons can, and you summon a 2/2 Chick. Works against full boards too.
  - **Clutch.** Start of Combat: lay an Egg in every empty enemy front slot. These Eggs never hatch. Pure summon denial, readable at a glance.
  - **Early Hatch.** As Brood, but the Egg hatches after the first enemy death in its row, not after 3 attacks.
- **Owner's direction.** No reaction to this mechanic.
- **Open.** Can an Egg be the target of an effect that 'destroys' or 'clears' things on a slot, such as a Thicket clearer?
- **Open.** Should the Egg count as an empty slot for Solitary (41) and Caravan (35)? Proposed: Caravan can't step into it; Solitary ignores it (only units are neighbours).
- **Rules review (needs a ruling).** The Egg's occupant rules are stated in full, so it fits R7's table. Needs a ruling on what counts as one of the 'enemy attacks' that hatch it: whistles, dances, Swarm joiners (one attack or several) and Peck strikes; proposed only attack declarations count, one per Swarm. A side that never attacks never hatches it, which is fine; readable.
- **Budget review.** Brood is in band on the turns when enemy boards have gaps and fades on full boards, as the old review found.
  - *Cuckoo*: in band. body 4 + 3/3 chick (E30 6 × 0.8) × your empty slot by the hatch 0.85 × an empty enemy slot at Start of Combat 0.9 × it hatches 0.9 ≈ 3.3 + blocked enemy summon space ≈ 0.3 (proposed E97) [guess] ≈ 7.6 vs V(2) 7: +9% at turns 2–5; ≈ 5 late (−28%), weak late by design, ±15%
  - *Cuckoo Mother*: edge. body 7 + own 5/5 chick (8 × 0.85 × 0.6 enemy gap at turn 6 × 0.95 ≈ 3.9) + faster, bigger chicks for another Brood unit ≈ 0.6 + blocked space ≈ 0.3 [guess] ≈ 11.8 vs V(4) 10: +18% at turn 6, ≈ 9.9 late (−1%), ±15% Change: If the sim agrees, 3/3 (≈ 10.8, +8%).
  - *Reed Warbler Dupe*: in band. body 7 + the chick gains +1/+1 per dead enemy (≈ 1.5 deaths by the hatch × 2 × 0.8 ≈ 2.4) × a chick hatches 0.7 × a Brood unit on board 0.6 ≈ 1.0 [guess] ≈ 8.0 vs V(3) 8: 0%, ±15%
- **From.** rows 7.

## J. Moving your own units in combat

### 35. Caravan — VARIANT of Battlegrounds' board packing

When a gap opens to its left in combat, this steps into it, so a line of Caravan units closes up after deaths.

- **Rules.** In combat, after each death resolution ends, every Caravan unit whose left-hand slot in its row is empty steps into that slot, going left to right; repeat until no Caravan unit can step. Summons made during that death resolution land first, so a dying unit's own summon still takes its slot (8.4.1). A unit that steps keeps its attack flag; stepping into a slot below the attack pointer flags it (9.4.9).
- **Bends.** 8.3.4 (no packing): packing comes back as a keyword, for one tribe. A moved unit keeps its attack flag, and stepping into a slot below the pointer flags it (9.4.9).
- **Creatures.** Shrews. Young shrews travel in a line, each holding the next one's tail (Folio hook 'Formation').. **Archetypes.** WIDE, MEDIUM
- **Example units.**
  - *Shrewlet Train*, Tier 1, 2/1, Hedgerow folk. Caravan. After this steps, gain +1 Attack this combat.
  - *Tail-holder Shrew*, Tier 3, 3/4, Hedgerow folk. Caravan. Adjacent Caravan units have +2 Attack.
  - *Shrew Matriarch*, Tier 5, 4/6, Hedgerow folk. Caravan. Whenever a friendly Caravan unit steps, give your Caravan units +1/+1 this combat.
- **How they play.** Shrewlet Trains grow every time they step, so the line gets meaner as it loses members. The Tail-holder's aura only works on neighbours, and Caravan keeps them neighbours after deaths. The Matriarch turns every step into a buff for the whole line, so each death powers the survivors.
- **Why run it.** Adjacency boards normally fall apart when a unit in the middle dies. Caravan keeps the chain whole, so adjacency auras and 'units next to this' text keep working all fight.
- **Scene.** Turn 6. Your front row is Shrewlet Train in F1, Tail-holder in F2, Shrewlet Train in F3 and the Matriarch in F4. The enemy kills your F1 shrew first. The Tail-holder steps into F1, the F3 shrew steps into F2, and the Matriarch steps into F3: three steps, so every Caravan unit gets +3/+3, and the shrew that stepped gets +1 Attack. The line is still touching, so the Tail-holder's +2 Attack aura still reaches both neighbours.
- **Good against.** SCAM and kill-order boards that snipe one middle unit to break up an adjacency chain. **Weak against.** Cleave and splash, which love a packed line, and Mark (40), which punishes units that step into its slot.
- **Variations.**
  - **Step Up.** When the front slot in front of this empties in combat, this steps forward into it. A back-row reserve that refills the front.
  - **Follow the Leader.** When the unit to the left of this dies, this steps into its slot and gains that unit's Attack this combat.
  - **Shuffle Right.** As Caravan, but steps right. Keeps the F4 flank filled, for boards that build on the right.
- **Similar to.** Battlegrounds packs every board after a death; Caravan is that rule as a keyword, leftward within a row only.
- **Owner's direction.** No reaction to this mechanic.
- **Open.** Should Caravan units also close gaps at Start of Combat, or only after deaths? Proposed: only after deaths, so recruit placement stays the player's choice.
- **Open.** Rows compete for 'units that move in combat': Flush (19), Jink (22), Tunnel for a Digger calling. Should one group own movement?
- **Rules review (clean).** Works: it runs after each death resolution, after that pass's summons, and its flag handling follows 9.4.9, so a step into the slot that just attacked lets it attack next. Say whether a Thicket's slot counts as empty for a step (Thickets count as empty only for summons); Eggs block steps as their own text says. Finite and readable.
- **Budget review.** The keyword is cheap; the Matriarch's team buff on every step snowballs inside one fight, so aim it at the unit that moves.
  - *Shrewlet Train*: flag under. Same text as the old review: body 3 + stepping ≈ 0.3 (E32) + +1 Attack after a step ≈ 0.5 [guess] ≈ 3.8 vs V(1) 5: −24%, outside ±15% and the ±1 SP floor Change: 2/2 (≈ 4.8, −4%).
  - *Tail-holder Shrew*: in band. body 7 + stepping 0.3 + +2 Attack to adjacent Caravan units (≈ 0.8 Caravan neighbours in a Caravan row × 2 × 0.6 realised, a little more as the line closes up ≈ 1.3; E13 adjacent) [guess] ≈ 8.6 vs V(3) 8: +8%, ±15%
  - *Shrew Matriarch*: flag over. body 10 + stepping 0.3 + every step gives each Caravan unit +1/+1 this combat; one front death can cause 3 steps: ≈ 3 steps a fight × 2.5 Caravan units × 2 SP × 0.6 realised × 0.6 Caravan build ≈ 5.4 (E03) [guess] ≈ 15.7 vs V(5) 12: +31%, ±15% Change: Give the +1/+1 only to the unit that stepped (≈ 3 × 2 × 0.6 × 0.6 ≈ 2.2): ≈ 12.5 (+4%) on the same 4/6.
- **From.** rows 3.

### 36. Rotate — NEW

After this attacks, it swaps with the healthiest unit behind it, so a fresh unit comes forward and the tired one rests in the back.

- **Rules.** After this attacks, if it is alive and in the front row, it swaps places with the friendly unit behind it that has the most Health (a tie goes to the lower reading order). If no unit is behind it, nothing happens. Each keeps its own attack flag; a unit brought forward into the slot that just attacked is unflagged, so it attacks next (9.4.8).
- **Bends.** 9.5.1: the back row becomes a place to rest mid-fight. 8.3.5 and 9.4.9 cover the swap.
- **Creatures.** Geese. A V of geese rotates the bird at the point so the lead is shared; the Folio's goose 'flies in a V; aggressive'.. **Archetypes.** STICKY, MEDIUM
- **Example units.**
  - *Skein Gosling*, Tier 1, 2/2, Birds. Rotate. When this swaps into the back row, it heals to full Health.
  - *Lead Goose*, Tier 3, 4/4, Birds. Rotate. A unit that swaps forward with this gains +2 Attack this combat.
  - *Barnacle Goose Matriarch*, Tier 5, 5/7, Birds. Rotate. Whenever two friendly units swap places, both gain +1/+1 this combat.
- **How they play.** Two geese, one in F1 and one in B1, take turns at the point: each attacks, swaps back, and the Gosling heals while it rests. The Lead Goose brings a back-row unit forward with +2 Attack, so your back carry gets an early swing. The Matriarch makes every swap a buff. Stance units (43) flip mode as they rotate.
- **Why run it.** Your front unit gets to hit and then hide before the enemy's reply kills it. The back row stops being a waiting room: its best unit joins the fight early.
- **Scene.** Turn 5. You have a Lead Goose in F2 and a 3/9 Hedgehog in B1. The Lead Goose attacks an enemy 3/3, kills it and drops to 4/1. It swaps with the Hedgehog: the goose rests safe in B1, and the Hedgehog stands in F2 as a 5/9 with no flag, so it attacks next. The enemy now faces a fresh wall, and the wounded goose can still fight later if the front falls.
- **Good against.** Boards with one big front hitter that would kill your front units one at a time. **Weak against.** Back-row reach and random damage (9.5.6), which ignore rows and find the resting goose.
- **Variations.**
  - **Relieve.** When the unit in front of this survives damage, this swaps with it. A back-row unit that steps in to take over.
  - **V Formation.** After this attacks, swap with the unit behind it that has the most Attack, not Health. An attacking version.
  - **Wheel.** Once per combat: after this attacks, rotate instead with the friendly unit across the whole board with the most Health, in either row.
- **Similar to.** Like switching out a hurt fighter in Pokemon or a tag-team fighting game.
- **Owner's direction.** No reaction to this mechanic.
- **Open.** Is healing on retreat (Skein Gosling) too sticky? A Gosling pair can cycle all fight.
- **Open.** Should a back-row Rotate unit be able to swap forward with a wounded front unit?
- **Rules review (clean).** Works with 9.4.9: both units keep their flags. Drop 'a unit brought forward into the slot that just attacked is unflagged', which can contradict 'each keeps its own attack flag' when the back unit has already attacked this cycle. Two Skein Goslings healing on retreat can survive weak attackers until the 200-attack tie (9.10.1); R3's no-progress rule would end it sooner.
- **Budget review.** Rotation itself is cheap, but both bigger geese print a full body before their text.
  - *Skein Gosling*: in band. body 4 + rotation ≈ 1 (E32) × a unit behind it on turns 1–3 ≈ 0.4 + heals to full when it rests (≈ 2 Health × 0.4 × 0.5 used ≈ 0.4) [guess] ≈ 4.8 vs V(1) 5: −4%, ±15%
  - *Lead Goose*: flag over. Same text as the old review: body 8 + rotation ≈ 1 + +2 Attack to the unit that comes forward ≈ 0.9 [guess] ≈ 10 vs V(3) 8: +25%, ±15% Change: 3/4 (≈ 9, +12%).
  - *Barnacle Goose Matriarch*: flag over. body 12 (on V(5) before text) + rotation ≈ 1 + both units gain +1/+1 this combat per swap (≈ 1.5 combat swaps × 4 SP × 0.7 × 0.6 goose build ≈ 2.5; E03) [guess] ≈ 15.5 vs V(5) 12: +29%, ±15%. Priced on combat swaps only: if Recruit Phase moves count, nothing limits it Change: 4/6 (≈ 13.5, +12%), and the text names combat swaps only.
- **From.** rows 4.

### 37. Bolt — NEW

The first time this gets hurt but survives, it runs into an empty back slot behind it, leaving a gap in the front.

- **Rules.** The first time each combat this survives damage while in the front row and a slot behind it is empty, it bolts: it moves into that back slot (the left one if both are empty). If no slot behind it is empty, it stays and can bolt later. It checks after the death check. It keeps its attack flag (9.4.9).
- **Bends.** 9.5.1: a unit leaves the targetable row by itself. Its place in the attack order follows 9.4.9. The front gap it leaves is summon space (8.4).
- **Creatures.** Rabbits. They thump a warning and vanish down the warren (Folio: 'Thumps to warn the warren'; Watership Down).. **Archetypes.** STICKY, WIDE
- **Example units.**
  - *Warren Lookout*, Tier 1, 1/3, Hedgerow folk. Bolt. After this bolts, summon a 1/1 Kit into the slot it left.
  - *Thumper*, Tier 3, 3/4, Hedgerow folk. Bolt. After this bolts, give your front-row units +1/+2 this combat.
  - *Old Buck of the Down*, Tier 5, 5/6, Hedgerow folk. Whenever you summon a Kit, give it +2/+2 and Bolt.
- **How they play.** The Lookout runs and leaves a Kit in its hole, so the front stays full. Thumper's warning thump toughens everyone left in front. With the Old Buck, every Kit is a 3/3 that can bolt too, as long as you left back slots open as bolt holes. A rabbit board plans its gaps: every bolter needs an empty slot behind it.
- **Why run it.** Each bolter takes a hit, then gets out of the way and leaves something new in front. The enemy spends attacks on bodies that don't die.
- **Scene.** Turn 2. You play Warren Lookout in F2 and leave B1 empty. In the fight an enemy 2/2 hits it: the Lookout is 1/1 and kills nothing, but it survives, so it bolts to B1 and a 1/1 Kit pops into F2. The enemy now has to chew through the Kit, and the Lookout still waits in the back to fight last.
- **Good against.** Boards that win with many medium hits, and Peck (5). **Weak against.** One big hit that kills outright (it never survives to bolt), random damage, and back-row reach.
- **Variations.**
  - **Go to Ground.** The first time this survives damage, it can't be attacked until your front row has no other units. It doesn't move.
  - **Spring.** When the front slot in front of this empties, this springs forward into it and attacks immediately. The bolt in reverse.
  - **Bolt Hole.** After this bolts, the slot it left gets +2/+2 for this combat (a slot effect), so whatever fills it next is bigger.
- **Owner's direction.** No reaction to this mechanic.
- **Open.** If both back slots behind F2 or F3 are empty, should the player choose, or is 'left one' fine?
- **Open.** Does a unit that bolts into a Bury or Fallow slot (39) take the pickup?
- **Rules review (clean).** Works: it checks after the death check, picks the left slot on a tie, and keeps its flag (9.4.9). The Lookout's Kit goes into a named slot (8.4.6). Bolting onto a Nut needs Bury's 'enters a slot' event; readable.
- **Budget review.** Bolt prices fine on small boards; Thumper's team buff is the one over.
  - *Warren Lookout*: in band. Same as the old review: body 4 + (bolt ≈ 0.5 + a 1/1 Kit ≈ 1.6) × survives a hit 0.7 × an empty back slot 0.8 ≈ 1.2 [guess] ≈ 5.2 vs V(1) 5: +4%, ±15%. Blank on a full board
  - *Thumper*: flag over. body 7 + bolt ≈ 0.2 + +1/+2 this combat to the front row after it bolts (≈ 3 front units × 3 SP × 0.7 realised × it bolts in ≈ 0.45 of fights at turns 4–6 ≈ 2.8; E03) [guess] ≈ 10 vs V(3) 8: +25%, ±15%. Blank on a full board Change: 3/3 (≈ 9, +12%).
  - *Old Buck of the Down*: in band. body 11 + Kits get +2/+2 and Bolt (≈ 0.2 Kits a fight late, from Warren Lookouts that find an empty back slot, × 3.2 ≈ 0.7) [guess] ≈ 11.7 vs V(5) 12: −2%, ±15%. Nearly a plain unit while only one card makes Kits
- **From.** rows 5.

## K. Slots, gaps and terrain

### 38. Sett — RESKIN of Galaxy's slot buffs

At the end of each turn, this badger's slot gets +1/+1, and the slot keeps it for whoever stands there later.

- **Rules.** End of Turn: this unit's slot gains +1/+1 Sett. A Sett is a slot effect (8.5): whatever unit stands in that slot has its stats, now or later, including units summoned into it in combat. The Sett stays when this unit moves, is sold or dies. Golden: +2/+2.
- **Bends.** 12.2.1: auras end when their source leaves; a Sett outlives the badger. 8.2.4: 'relations belong to slots' extends to stats.
- **Creatures.** Badgers. Setts are dug over generations and handed down; the Folio's 'faded gentry, landlords of ancient setts'.. **Archetypes.** MEDIUM, TALL, WIDE
- **Example units.**
  - *Badger Cub*, Tier 1, 1/2, Hunters. Sett.
  - *Sett Grandsire*, Tier 2, 2/4, Hunters. Sett. When you sell this, its slot's Sett gains +2/+2.
  - *Sett Matriarch*, Tier 4, 3/6, Hunters. End of Turn: each of your slots that has a Sett gains +1/+1 more Sett.
- **How they play.** The Cub and Brock build slots, not units. You can keep a badger in one slot to dig a mansion, or move it each turn to spread Setts across the board, since free moves let you choose. Sell Sett Grandsire to cash out into its slot, then play your carry there. The Matriarch grows every Sett you have, wherever the badgers went.
- **Why run it.** Stats on a slot survive the unit dying. A death summon that takes a dead unit's slot (8.4.1) moves into the mansion and comes out big.
- **Scene.** Turns 1 to 4: your Badger Cub sits in F2, and the F2 Sett reaches +4/+4. Turn 5: you sell the Cub and play your best unit in F2; it fights with +4/+4. In combat it dies, and its own death summon lands in F2, so that token has +4/+4 too.
- **Good against.** SCAM boards that kill one big unit: the next unit in the slot is just as big. **Weak against.** Early tempo, because it gives nothing the turn you buy it, and hostile slot effects like Mark (40).
- **Variations.**
  - **Ancestral Sett.** When this dies in combat, its slot gains +1/+1 permanently. Grows from dying, for STICKY and WIDE boards.
  - **Warren.** End of Turn: this unit's slot gains 'When the unit here dies, summon a 1/1 Kit into this slot.' (Stacks.) A slot that carries a death effect, not stats.
  - **Tenancy.** If this has stood in the same slot at the end of 3 of your turns in a row, its slot gains +3/+3 and this loses Tenancy. A time-bound version, as pillar 13 asks for.
- **Similar to.** Galaxy's slot buffs, such as Candy Claws: 'Hunt - Give my slot +1/+1'.
- **Owner's direction.** 02e: "We have set slots, so we can experiment with slot buff mechanics, and we should have the ability to do that, I think."
- **Designer's response.** Sett is the plainest slot buff: one per turn, on the badger's slot. The variations try a slot that carries a death effect and a time-bound version.
- **Open.** Slots need to show their buffs on screen; every slot mechanic needs that UI.
- **Rules review (clean).** Works directly under 8.5 (slot effects stay through moves, sales and deaths; copied into combat). Note that an enemy unit swapped into the slot by a Changeling would get the Sett too, since 8.5.1 applies to whatever unit stands there. Name clash: this Sett Grandsire (T2) and Hunker's Sett Grandsire (T5) are different cards.
- **Budget review.** Unconditional +1/+1 a turn puts the Setts +72% to +164% over their tiers (band ±25%); Health-only Setts or a higher tier keep the slot idea.
  - *Badger Cub*: flag over. body 3 + slot +1/+1 every turn: s = 2, 2.5× the Tier-1 growth cap of 0.8; c(1) 3.9 × 2 × 1.1 (E16, the slot keeps it) ≈ 8.6 [guess] ≈ 11.6 vs V(1) 5: +132%, ±25% Change: 1/1, and its Sett gives +1 Health a turn (golden +2): 2 + 3.9 × 0.9 × 1.1 ≈ 5.9 (+18%). The full +1/+1 Sett fits from Tier 4.
  - *Sett Grandsire*: flag over. Same as the old review: body 6 + 3.7 × 2 × 1.1 ≈ 8.1 + +2/+2 Sett on sale ≈ 4.4 ≈ 18.5 vs V(2) 7: +164%, ±25%; over the Tier-2 growth cap Change: Tier 4 at 1/1 with +1/+1 on sale (≈ 11, +10%), or Tier 2 at 1/1 with a +1 Health Sett a turn and +1/+1 on sale (≈ 8.3, +19%).
  - *Sett Matriarch*: flag over. body 9 + +1/+1 more on each Sett slot a turn (≈ 2 Sett slots × 2 SP × 0.6 Sett build: s ≈ 2.4, near the Tier-4 cap of 2.5): 3.1 × 2.4 × 1.1 ≈ 8.2 [guess] ≈ 17.2 vs V(4) 10: +72%, ±25% Change: 2/3, and only your slot with the most Sett gains the extra +1/+1 (s ≈ 1.6): ≈ 5 + 5.5 ≈ 10.5 (+5%).
- **From.** rows 1 (marked variant by the designer).

### 39. Bury — VARIANT of Galaxy's slot buffs (merged with Fallow)

This hides a Nut in an empty slot; the first unit you put there eats it for +1/+1, and a Nut left alone for 3 turns grows into a sapling.

- **Rules.** End of Turn: bury a Nut in your empty slot nearest this (8.4.2 order). You can have at most 3 Nuts on your board. In the Recruit Phase, the first unit that enters a Nut's slot (played, moved or summoned) eats it: +1/+1 permanently, and the Nut is gone. A unit eats at most one Nut per turn. In combat, a unit summoned into a Nut's slot eats it for that combat only, and the Nut is still there after combat. A Nut no unit has eaten by the end of 3 of your turns sprouts: summon a 1/2 Oakling into its slot (Created).
- **Bends.** 8.1 and 8.3.1: a slot holds something that isn't a unit, so a gap becomes a resource. 9.1.1: because combat runs on a copy, a Nut eaten in combat is still there next fight.
- **Creatures.** Red squirrels and jays scatter-hoard and forget many caches, which grow into trees (the Folio's Acorn Exchange; jays as 'Investment').. **Archetypes.** WIDE, ECO
- **Example units.**
  - *Hoarder Squirrel*, Tier 1, 1/2, Hedgerow folk. Bury.
  - *Jay Forester*, Tier 3, 3/3, Birds. Start of Combat: summon a 1/1 Oakling into each of your empty slots that holds a Nut.
  - *Cache Keeper*, Tier 4, 2/5, Hedgerow folk. Bury. Your Nuts give +2/+2 instead, and your Oaklings sprout with +2/+2.
- **How they play.** The Squirrel plants Nuts in your gaps, and you choose which gaps by where you put it. You can spend a Nut by playing a new unit there, or leave it for three turns for a free Oakling. The Jay turns every Nut into a combat Oakling that eats it, every fight, without using it up. The Cache Keeper doubles both payoffs.
- **Why run it.** It turns the turns when your board isn't full into value: a stat buff for your next unit, or a free body later. The owner's 'take a little bit of stuff up front now, or get more later' choice, slot by slot.
- **Scene.** Turn 2. You have four units, with the Hoarder Squirrel in F1 and F2 empty. End of Turn: a Nut goes into F2. Turn 3: you can play your new buy into F2 for +1/+1, or play it elsewhere and wait. You wait. On Turn 4 the Jay Forester arrives: in each fight it summons a 1/1 Oakling into F2, which eats the Nut and fights as a 2/2. At the end of Turn 4 the Nut sprouts, and a real 1/2 Oakling joins your board.
- **Good against.** Slow lobbies where a few gaps early don't cost you fights. **Weak against.** Early tempo boards, since every Nut is a slot you didn't fill.
- **Variations.**
  - **Fallow.** While this is on your board, at End of Turn each empty slot gains +1/+1 Fallow (up to +3/+3). The first unit to enter a fallow slot harvests it: in the Recruit Phase it keeps the Fallow permanently and the slot resets; in combat, a summon takes it for that combat only. A unit harvests at most once per turn.
  - **Scatter.** When this dies in combat, bury a Nut in its slot on your recruit board.
  - **Acorn Stash.** If you have 3 Nuts on your board, they combine into one Acorn Stash in the slot of the oldest: the first unit to enter it gains +5/+5 permanently. Hoard, then cash in big.
- **Similar to.** A Galaxy slot buff on an empty slot that is used up by the first unit to enter.
- **Owner's direction.** 02h on the Hedgerow Acorns: "Maybe you get large acorns and bigger acorns ... to encourage you to hoard for a bit ... it's always nice to have an idea of 'take a little bit of stuff up front now, or get more later'."
- **Designer's response.** Bury is that choice on the board: eat the Nut now, or let it sprout. The Acorn Stash variation is the owner's 'three small make a big one' idea as a slot pickup. Nuts land in the empty slot nearest the squirrel, not a random one, so the player picks the spot.
- **Open.** Overlaps Hedgerow Acorns (cards in hand) and the Fairy ring (a slot enchantment). Should Nuts and Acorns be one system?
- **Open.** Needs a 'unit enters slot' event that covers playing, moving, summoning and returning.
- **Rules review (clean).** Works: Nuts are pickups (R7) that don't block summons or play, with a cap of 3 and a once-per-turn eating rule that stops move-in-move-out farming. It needs one 'unit enters a slot' event covering play, move, summon and return, as the designer says. Readable with a slot badge.
- **Budget review.** Free permanent stats from gaps put two units +56% and +94% over their tiers (band ±25%); one tier up and smaller bodies fix it without touching the Nut.
  - *Hoarder Squirrel*: flag over. As the old review: a Nut a turn, eaten by the next unit to enter (played or moved): s ≈ 1.6, twice the Tier-1 cap; 3.9 × 1.6 ≈ 6.2 + Oakling ≈ 0.5 [guess] ≈ 9.7 vs V(1) 5: +94%, ±25% Change: Tier 2 at 1/1, same text (s ≈ 1.4, near the Tier-2 cap: ≈ 7.7, +10%).
  - *Jay Forester*: in band. body 6 + Start of Combat Oaklings in Nut slots (≈ 1.2 Nut gaps in a Bury build × a 2/2 after eating, 3.2 × 0.6 a Bury unit on board ≈ 2.3; E30) [guess] ≈ 8.3 vs V(3) 8: +4%, ±15%. It fires every fight, since a Nut eaten in combat stays
  - *Cache Keeper*: flag over. body 7 + own Nuts at +2/+2 (s ≈ 4 × 0.5 a Nut eaten at turn 6 ≈ 2.0: 3.1 × 2 ≈ 6.2) + other squirrels' Nuts doubled (s ≈ 0.6: ≈ 1.9) + bigger Oaklings ≈ 0.5 [guess] ≈ 15.6 vs V(4) 10: +56%, ±25%; total s ≈ 2.6, at the Tier-4 cap Change: 1/2, same text (≈ 11.6, +16%).
- **From.** creatures 2, rows 2.

### 40. Mark — NEW

At the start of the fight, this marks the enemy slot facing it, and any enemy unit that steps or is summoned into that slot later takes damage.

- **Rules.** Mark (X). Start of Combat: scent-mark the enemy slot across from this. For the rest of this combat, each enemy unit that enters a marked slot (summoned there, returned there after dying, or moved there) takes X damage. The unit already standing there when the mark is made is not hurt. The mark is yours, lasts the combat, and stays after this unit dies.
- **Bends.** 8.2.4: slot relations turned against the enemy, a hostile slot effect that stays when the unit there changes. It punishes 8.4.1 (a death summon takes the dead unit's slot first) and 9.8.3 (a returning unit comes back to its own slot).
- **Creatures.** Wolves and foxes scent-mark territory. In the Folio, Hunters 'follow wolves to kills'.. **Archetypes.** SCAM, WIDE, STICKY
- **Example units.**
  - *Fox Cub*, Tier 1, 2/1, Hunters. Mark (2).
  - *Gubbio Wolf*, Tier 2, 3/2, Hunters. Mark (3). After an enemy dies in a marked slot, this gains +1/+1 this combat.
  - *Pack Alpha*, Tier 4, 4/5, Hunters. Mark (3). Your units attack enemies standing in marked slots first, if they can be attacked.
- **How they play.** Mark does nothing to the unit facing it at first. It waits for what comes next: the token the dead unit leaves, the rabbit that comes back, the shrew that steps in. Because refills go into the dead unit's own slot, the slot across from your wolf is exactly where the enemy's next body lands, with no aiming needed. The Gubbio Wolf grows from each kill there, and the Pack Alpha sends your attacks at the marked slot, so you kill the first unit, then the refill steps onto the scent.
- **Why run it.** WIDE and STICKY boards get their value from bodies that come back into the same slot. Mark taxes every one of those arrivals, and kills tokens before they can attack.
- **Scene.** Turn 6. Your opponent's last board had rabbits that leave Kits and a unit that comes back after dying. You play the Fox Cub in F1, the Gubbio Wolf in F2 and the Pack Alpha in F3. Start of Combat: they mark the enemy's F1, F2 and F3. Your Fox Cub attacks first and hits their Warren Lookout (1/3) in F2: it survives at 1 Health and bolts to the back row, and the Kit it leaves pops into F2, steps on the scent, takes 3 and dies at once. The Wolf is now 4/3. Later you kill their F3 unit; it comes back into F3 with 1 Health, takes 3 and dies again. Two of their 'free' bodies never got to attack.
- **Good against.** Boards that refill the same slot: death summons, returns, Bolt Kits, Caravan lines stepping left. **Weak against.** Boards with no summons or returns, where Mark is just a body, and Delivery (44), which sends summons elsewhere.
- **Variations.**
  - **Mark, hits now.** Start of Combat: deal X damage to the enemy across from this and mark its slot; every enemy that later enters it takes X too. Always does something, so it is easier to read.
  - **Scent.** Start of Combat: the enemy slot across from this is Scented for this combat. Whatever unit stands in it has -2 Attack, now and after it is replaced. A hostile slot debuff, like a curse on the ground.
  - **Territory.** Mark your own ground instead. See the new mechanic Territory: your slot punishes enemies that attack the unit standing in it.
- **Similar to.** Like a trap square in a tactics game: you place it where you know the enemy's next unit will stand.
- **Owner's direction.** "Mark doesn't make sense to me at all. I don't really see how that could be a good mechanic. Maybe there's iteration to it, but I don't see it right now." (02h). Direction: example cards; look for the version that works.
- **Designer's response.** Push back with the case where it works: Bramble's summon rule sends refills into the dead unit's own slot, so the slot across from the wolf is a known landing spot. The scene shows two refills dying there. The weak point is that Mark does nothing against a board with no refills, so the cards may read as blank. Three iterations: 'Mark, hits now' (always does something), 'Scent' (a hostile slot debuff, close to the owner's suggestion of curses that debuff enemies), and Territory (marks your own slot, written in full as a new mechanic). My pick to show the owner first is 'Mark, hits now'.
- **Open.** 8.5 needs an owner for slot effects made in combat on the enemy board (8.5.2 only copies each board's own).
- **Open.** Should the base Mark hurt the unit already in the slot, as 'Mark, hits now' does?
- **Rules review (needs a ruling).** Needs a ruling in 8.5: slot effects made in combat on the enemy board have an owner (you), last that combat, and are not copied back to either recruit board. Entering damage should be effect damage: Shrug and Shell apply, Hunker doesn't. 'Mark, hits now' makes the card readable at Start of Combat, which answers the owner's 'doesn't make sense to me'.
- **Budget review.** Mark itself is cheap, so the units that carry it want full bodies.
  - *Fox Cub*: flag under. body 3 + Mark (2): ≈ 0.3 refills a fight outside summon builds × 2 × 0.85 ≈ 0.5 (proposed E97, hostile mark) [guess] ≈ 3.5 vs V(1) 5: −30%, outside ±15% and the ±1 SP floor Change: 2/2 (≈ 4.5, −10%).
  - *Gubbio Wolf*: in band. Close to the old review: body 5 + Mark (3) on refills ≈ 0.8 + +1/+1 this combat after a death in the mark ≈ 0.9 [guess] ≈ 6.7 vs V(2) 7: −4%, ±15%
  - *Pack Alpha*: edge. body 9 + Mark (3) ≈ 1.0 (more summons by turn 6) + your units attack the marked slot first (kills that unit sooner, then hits each refill ≈ 1.5; E83, E90) [guess] ≈ 11.5 vs V(4) 10: +15%, on the ±15% line Change: If the sim agrees, 4/4 (≈ 10.5, +5%).
- **From.** rows 8.

### 41. Solitary — NEW

While no friendly unit is next to it, in front of it or behind it, this has double Attack.

- **Rules.** While this has no friendly neighbours (8.2.3: the slots adjacent in its row, in front of it and behind it; only units count, so Eggs, Thickets and riders don't), its Attack is doubled. This is checked whenever the board changes, so it can wake mid-combat when its neighbours die, and switch off when a summon lands next to it. Doubling applies after other Attack changes.
- **Bends.** 8.2.3 and 8.3.1: almost all position text rewards clustering; Solitary rewards gaps.
- **Creatures.** Wildcats, solitary and untameable (Folio: Clan Chattan's 'touch not the cat'). Lynxes and pine martens fit too.. **Archetypes.** TALL
- **Example units.**
  - *Pine Marten*, Tier 2, 2/3, Hunters. Solitary.
  - *Scottish Wildcat*, Tier 4, 4/6, Hunters. Solitary. Start of Combat: if this has no friendly neighbours, gain +3 Health.
  - *Lone Lynx*, Tier 6, 6/8, Hunters. Solitary. After this kills an enemy while it has no friendly neighbours, gain +2/+2 permanently.
- **How they play.** A Solitary unit wants a clearing: in F1 it needs F2 and B1 empty; in F4, F3 and B3. The rest of the board still fills the other slots, so a board of five can keep one cat alone. The Wildcat gets tougher when it starts alone, and the Lynx grows permanently from kills made alone, so it is a TALL carry.
- **Why run it.** One carry with doubled Attack trades up into almost anything. The cost is two or three empty slots, which is a real choice on a 7-slot board.
- **Scene.** Turn 8. Your Wildcat stands in F1. You leave F2 and B1 empty and put four units in F3, F4, B2 and B3. Start of Combat: the cat is alone, so it is 8/9 (doubled Attack, +3 Health). It kills an enemy 7/7 in one hit. In a later fight one of your own death summons lands in F2 next to it, and the cat drops to 4 Attack until that token dies; you learn to keep summoners away from the clearing.
- **Good against.** Boards with one big carry it can trade into, and SCAM pieces that need two hits to land. **Weak against.** Your own summons landing next to it, and WIDE boards that out-number its attacks.
- **Variations.**
  - **Clearing.** This has +2 Attack for each empty slot among its neighbours. A graded version of the Galaxy note's idea 'If the slot beside me is empty, +2 Attack'.
  - **Wake.** The first time this has no friendly neighbours in a combat, it gains +4/+4 this combat. Kill-order drama: the enemy kills its friends and wakes it up.
  - **Recluse.** End of Turn: if this has no friendly neighbours, gain +1/+2 permanently. A Recruit Phase version; the gap is the price.
- **Similar to.** Like Magic's 'exalted', which rewards a creature for attacking alone, but here it is about the board around it.
- **Owner's direction.** No reaction to this mechanic.
- **Open.** Doubling also doubles later buffs. Should it be a flat bonus instead (see Clearing)?
- **Rules review (clean).** Works: 'neighbour' is 8.2.3, only units count, and the doubling applies in the multiplier layer after additions (architecture-notes.md 4), recalculated when the board changes like an aura (12.2.1). No loop; readable.
- **Budget review.** Solitary is about on budget; the two big cats print full bodies and land just over.
  - *Pine Marten*: in band. body 5 + doubled Attack (+2) when alone, easy on turns 2–4 when gaps are free (≈ 0.6 at Start of Combat, plus late wakes) × 0.7 realised ≈ 1.5 (E06 with C02) [guess] ≈ 6.5 vs V(2) 7: −7%, ±15%; ≈ 5.8 on full boards
  - *Scottish Wildcat*: edge. Same text as the old review: body 10 + doubled Attack once its neighbours die ≈ 1.7 + +3 Health if alone ≈ 0.3 [guess] ≈ 12 vs V(4) 10: +20%, ±15% Change: If the sim agrees, 4/5 (≈ 11, +10%).
  - *Lone Lynx*: edge. body 14 (on V(6)) + doubled Attack when its neighbours die (+6 × 0.5 of fights × 0.6 ≈ 1.8) + +2/+2 permanently per lonely kill (≈ 0.3 a fight: s ≈ 1.2, under the cap; c_combat 1.6 × 1.2 ≈ 1.9) [guess] ≈ 17.7 vs V(6) 14: +26%, ±25% Change: 6/7 (≈ 16.7, +19%).
- **From.** rows 15.

### 42. Migrate — NEW

At the end of each turn, this moves itself to the next empty slot and grows a little.

- **Rules.** End of Turn: this moves to the next empty slot after its own in reading order (F1, F2, F3, F4, B1, B2, B3, then back to F1) and gains +1/+1 permanently. If there is no empty slot, it stays and gains nothing. All End of Turn triggers are listed before any unit moves, so each migrator moves once. A unit 'migrates past B3' when its next empty slot can only be reached by wrapping round.
- **Bends.** 8.3.3: the player places units freely; a Migrate unit places itself, and the player steers it only by choosing which slots to fill. It reads position at End of Turn.
- **Creatures.** Lemmings and their 'cheerful, endless tide' (Folio take 'The Great Migration'); their doom cult, 'believers in the cliff'.. **Archetypes.** MEDIUM
- **Example units.**
  - *Lemming Pup*, Tier 1, 1/2, Hedgerow folk. Migrate.
  - *Cliff-cult Lemming*, Tier 2, 1/1, Hedgerow folk. Migrate. If this would migrate past B3, it leaps instead: remove it and give your other units +1/+1 permanently.
  - *Lemming Prophet*, Tier 4, 3/4, Hedgerow folk. Whenever one of your units leaps, gain +2/+2 permanently and add a Cliff-cult Lemming to your hand.
- **How they play.** You steer a lemming by filling slots: it skips every full slot, so filling the slots in front of it makes it jump further and reach the cliff sooner. The Cliff-cult Lemming gives the board a permanent buff when it leaps off past B3. The Prophet grows from each leap and hands you a new lemming, so the march starts again.
- **Why run it.** It is slow, steady permanent growth, and the leap is a timed payoff the player can see coming and plan for.
- **Scene.** Turn 3. You play a Cliff-cult Lemming in F3. End of Turn: F4 is empty, so it moves there as a 2/2. Turn 4: you fill B1 and B2 with new buys, so its next empty slot is B3; it jumps there as a 3/3. Turn 5: every slot after it is behind the wrap, so it leaps off the cliff, and your six other units each gain +1/+1 permanently. With a Prophet on board, a new lemming comes to your hand to start again.
- **Good against.** Long games, where a steady permanent buff adds up. **Weak against.** Full boards (no room to move) and fast tempo early, since a 1/1 that moves itself is a weak fighter.
- **Variations.**
  - **Stampede.** End of Turn: all your Migrate units move together, and each gains +1/+1 for each other Migrate unit that moved.
  - **Pilgrimage.** When this reaches B3, it gains +3/+3 permanently and loses Migrate. A one-trip journey with a payoff at the end.
  - **Ebb.** As Migrate, but it moves backwards in reading order, from the back row to the front.
- **Similar to.** Like the Lemmings video game: they walk on their own, and you shape where they go.
- **Owner's direction.** 02h on Recruit Phase position: "it is our choice where to put things and which units to put where. It can be an interesting puzzle to figure those things out."
- **Designer's response.** Migrate keeps that puzzle: the unit moves itself, but the player decides which slots are full and so where it lands.
- **Open.** Should it wrap from B3 to F1, or simply stop at B3 when no 'leap' text exists?
- **Open.** Does a migrator eat Bury Nuts and harvest Fallow (39) as it passes? Proposed: yes, only the slot it ends in.
- **Rules review (clean).** Works: listing End of Turn triggers before any move fits 3.4.1, and wrapping past B3 is defined. Removing a Cliff-cult Lemming returns a Bought pool copy (5.3.7). Under Bury's text a migrator does eat the Nut in the slot it moves into; readable with an arrow.
- **Budget review.** Migrate's free +1/+1 a turn puts two units +42% and +100% over their tiers (band ±25%), and the Prophet closes a lemming loop that needs a sim.
  - *Lemming Pup*: flag over. body 3 + +1/+1 a turn while a slot ahead is empty (≈ 0.9 on turns 1–4): s ≈ 1.8, over twice the Tier-1 cap of 0.8; 3.9 × 1.8 ≈ 7.0 (E02, E32) [guess] ≈ 10 vs V(1) 5: +100%, ±25% Change: Tier 2 at 1/1, like Cliff-cult Lemming (s ≈ 1.6: 2 + 3.7 × 1.6 ≈ 7.9, +13%).
  - *Cliff-cult Lemming*: edge. Same as the old review: 3.7 × 1.4 ≈ 5.2 + the leap ≈ 1.6 + body 2 ≈ 8.8 vs V(2) 7: +26%, ±25% Change: None yet; sim the leap turn.
  - *Lemming Prophet*: flag over. body 7 + +2/+2 permanently per leap (≈ 0.35 leaps a turn in a lemming build: s ≈ 1.4; 3.1 × 1.4 ≈ 4.3) + a Cliff-cult Lemming per leap (≈ 0.7 gold-equivalent a turn ≈ 2.9; E40) [guess] ≈ 14.2 vs V(4) 10: +42%, ±25%. With it, Cliff-cult Lemmings come back forever, so their leap's +1/+1 to your units repeats too Change: +1/+1 per leap instead of +2/+2, keeping the new lemming (≈ 12.1, +21%).
- **From.** rows 16. The recruit list's stork 'Migrate' is a different mechanic, renamed Fly South (60).

### 43. Stance — VARIANT of Battlegrounds' Choose One

This card has a front-row side and a back-row side, and it uses whichever matches the row it is in.

- **Rules.** This card has a front text and a back text, each with its own stats, rules or both. It uses the one for the row it is in. If it changes row in combat, it switches at once. Buffs apply on top of either side, and damage taken stays when it switches: if the new side leaves it at 0 Health or less, it dies.
- **Bends.** 8.2.7 and 7.2.1: a row becomes a mode switch. 12.2.1's 'recalculated whenever the board changes' now covers a unit's own stats, so moves in combat (Rotate, Bolt, Flush) flip it mid-fight.
- **Creatures.** Bats. Aesop's bat belongs to neither birds nor beasts and changes sides to suit itself (Folio take 'Double agents').. **Archetypes.** MEDIUM
- **Example units.**
  - *Pipistrelle*, Tier 1, 3/1, Neutral. Front: 3/1. Back: 1/3, and Start of Combat: deal 1 damage to a random enemy.
  - *Double-agent Bat*, Tier 3, 5/2, Neutral. Front: 5/2. Back: 2/5, and the units in front of this have +1 Attack.
  - *Noctule Captain*, Tier 5, 7/4, Neutral. Front: 7/4. Back: 3/7, and after a friendly unit changes row, give it +2/+2 this combat.
- **How they play.** Each bat is two cards in one, so one buy fills whichever role the board lacks. Early, the Pipistrelle is a 3/1 attacker in front or a pinger in back. The Double-agent Bat in the back row is a sturdy aura for the two units in front of it. The Noctule Captain rewards Rotate (36), Bolt (37) and Caravan-style moves, which change units' rows mid-fight.
- **Why run it.** Flexibility. A Stance unit never sits in the wrong row, and boards that move units in combat get a second use out of every move.
- **Scene.** Turn 5. Your Double-agent Bat sits in B1 as a 2/5 and gives F1 and F2 +1 Attack. In the fight, your Lead Goose (36) in F2 attacks and rotates with the healthiest unit behind it: the bat. The bat comes forward into F2 as a 5/2, unflagged, and attacks next. If the bat had taken 3 damage while in the back, coming forward would have killed it, so you plan the rotation.
- **Good against.** Lobbies that change fast, where one card that can play two roles keeps the board useful. **Weak against.** Flush (19) and other enemy moves that drag a back-row bat forward into its fragile side.
- **Variations.**
  - **Perch.** Stats only: Front: +3 Attack. Back: +3 Health. The simplest Stance, for any tribe.
  - **Turncoat.** Text only: Front: 'Whenever this attacks, gain +1 Attack.' Back: 'Start of Combat: give the units in front of this +2 Health.'
  - **Choose by placement.** When played, it locks to the side for the row it was played into, and keeps it even if it moves. Battlegrounds' Choose One, chosen by the slot.
- **Similar to.** Like Hearthstone's Choose One, or a double-faced card in Magic, but the row picks the face and it can flip mid-fight.
- **Owner's direction.** 02h on Recruit Phase position: "if I have two different fairies, one that buffs things behind it and one that buffs things in front of it, it is our choice where to put things ... It can be an interesting puzzle to figure those things out."
- **Designer's response.** Stance is that puzzle inside one card: where you put it decides what it is.
- **Open.** Two stat lines on one card are busy. The card frame needs a clear front and back half.
- **Rules review (clean).** Works as a base-stat switch in the stat layers, with death on switching stated. Say which side applies when it is in hand or off the board (proposed: front), which hand-buff cards such as Rehearse need. Busy as a card, as the designer says; the Perch variation is the readable form.
- **Budget review.** Stance prices cleanly as a body with a row condition, and all three are in band.
  - *Pipistrelle*: in band. Front 3/1 = 4 (−20%); back 0.75 + 3 + Start of Combat 1 damage ≈ 0.85 = 4.6 (−8%). The player picks the better side: ≈ 4.6 + 0.3 for the choice ≈ 4.9 vs V(1) 5: −2%, ±15%
  - *Double-agent Bat*: in band. Same as the old review: front 5/2 = 7 (−12%); back 2/5 = 6.5 + +1 Attack to the units in front (1.9 measured on Lantern Moth) = 8.4 (+5%), ±15%
  - *Noctule Captain*: in band. Front 7/4 = 11 (−8%); back 2.25 + 7 + +2/+2 this combat to a unit that changes row (≈ 1.5 row changes a fight in a mover build × 4 × 0.7 × 0.6 ≈ 2.5) ≈ 11.75 (−2%) [guess], ±15%. Priced on combat row changes only
- **From.** rows 17.

### 44. Delivery — NEW

While this lives, every unit you summon lands in the empty slot nearest this stork and gets +1/+1.

- **Rules.** While this lives, units summoned for your side, from any source, go into your empty slot nearest this unit (8.4.2 order from its slot) instead of their normal slot. Delivered units gain +1/+1. Text that names a slot (8.4.6) still wins. Returns (units coming back after dying) are not summons and go home as normal. If you have two Delivery units, the first in reading order delivers. It works in the Recruit Phase and in combat (8.4.7).
- **Bends.** 8.4.1 to 8.4.3, summon placement. A summon's attack timing depends on where it lands (9.4.8), so steering summons also steers when they attack.
- **Creatures.** Storks, the bringers of babies, who bring luck to the roof they nest on (the Folio's Stork Post).. **Archetypes.** WIDE
- **Example units.**
  - *Bundle of Joy*, Tier 1, 1/1, Neutral. When this dies, summon two 1/1 Babies.
  - *Rooftop Stork*, Tier 4, 2/5, Birds. Delivery.
  - *Stork Post Sorter*, Tier 5, 3/6, Birds. Delivery. Each unit delivered this combat gains +1/+1 more than the one before.
- **How they play.** Where you put the stork decides where your summons go. A stork in the back row sends tokens into protected back slots; in the front row it keeps them in the line. Bundle of Joy is a cheap summon to deliver, and the Sorter makes each later summon bigger. Delivery also sends tokens into a Sett (38) or onto a Nut (39), and away from enemy Marks (40) and Eggs (34).
- **Why run it.** Summons get +1/+1 and land where you want them, which matters on a board where slot position is everything.
- **Scene.** Turn 7. Your opponent's wolves mark your F2 every fight. You play a Rooftop Stork in B2 and your Bundle of Joy in F2. In the fight the Bundle dies in F2. Normally its Babies would land in F2, onto the scent; instead they go to B1 and B3, next to the stork, as 2/2s that the enemy can't reach while your front row lives.
- **Good against.** Mark, Brood, Cleave and any enemy text that punishes where your summons land. **Weak against.** Anything that kills the stork first; then placement snaps back to normal.
- **Variations.**
  - **Doorstep.** While this lives, your summons go into the slot in front of this (or the nearest empty one) and gain +1/+1.
  - **Special Delivery.** The first unit you summon each combat is delivered next to this and gains +3/+3. A one-off version, easier to read.
  - **Wrong Address.** While this lives, enemy summons go into their empty slot farthest from their source. A tech card against slot-based WIDE boards.
- **Owner's direction.** No reaction to this mechanic.
- **Open.** Should Delivery cover Ride or Burrow arrivals (31, 32)? Proposed: summons only.
- **Open.** Readability: summons land away from where players expect. A visible flight path from the stork would help.
- **Rules review (clean).** Works as an override of 8.4.1 to 8.4.3 that still loses to named slots (8.4.6), with two storks resolved by reading order. Say whether Bud's copies, Brood's chicks and Fly South's arrival are summons (proposed: Bud and Brood yes, Fly South no). Readable if the summon's flight path is shown.
- **Budget review.** Delivery itself prices fine for summon builds; the Sorter's step-up grows with the square of summons.
  - *Bundle of Joy*: in band. body 2 + two 1/1s on death (E30: 4 × 0.8 × dies 0.95 ≈ 3.0) [guess] ≈ 5.0 vs V(1) 5: 0%, ±15%
  - *Rooftop Stork*: in band. Same as the old review: body 7 + +1/+1 per summon and placement ≈ 8.3 outside summon builds (−17%), ≈ 10.7 in one (+7%), ±15%. In band for the build it serves
  - *Stork Post Sorter*: flag over. body 9 + Delivery's +1/+1 + a step-up of +1/+1 per delivered unit: 2 summons give +1 and +2 (6 SP × 0.8 ≈ 4.8), 3 give +1, +2, +3 (12 × 0.8 ≈ 9.6) + placement ≈ 0.5 [guess] ≈ 14.3 vs V(5) 12 at the summon-build reference of 2 (+19%), ≈ 19 at 3 (+59%), ±15%; it grows with the square of summons Change: 2/5 (≈ 12.3 at 2 summons, +3%), and stop the step-up at +2/+2 so more summons add only Delivery's +1/+1 each.
- **From.** rows 18.

### 45. Both Ends — NEW

Put one hedgehog at each end of a row: they get tougher, and whichever one the enemy attacks, the other one pricks the attacker first.

- **Rules.** Both Ends works in pairs. While you have a Both Ends unit in F1 and another in F4 (or one in B1 and one in B3), each of the two has +1/+2. Whenever an enemy attacks one of the pair, the other first deals 2 damage to the attacker. If that kills the attacker, the attack doesn't happen. Any two Both Ends units make a pair; they don't need to be the same card. The empty or full slots between them don't matter.
- **Bends.** 8.2.2: adjacency never skips a gap; this relation spans a whole row, gaps and all. It gives the flank slots (F1 and F4) a job the centre can't do. 9.6.1 needs an 'attacker gone' line to match its 'defender gone' line.
- **Creatures.** Hedgehogs. In Grimm's The Hare and the Hedgehog, the hedgehog's wife waits at the far end of the furrow, so whichever end the hare reaches, a hedgehog is already there (Folio take 'Twin tricksters'). The owner's thorn idea, struck from the far end.. **Archetypes.** MEDIUM, STICKY
- **Example units.**
  - *Hedgehog Hoglet*, Tier 1, 1/2, Hedgerow folk. Both Ends.
  - *Hedgehog Twin*, Tier 2, 2/3, Hedgerow folk. Both Ends.
  - *Furrow Racer*, Tier 4, 4/5, Hedgerow folk. Both Ends. Whenever the other end of your pair pricks an attacker, give your units in this row +1 Attack this combat.
- **How they play.** Picture the front row as a furrow with a hedgehog at each end, F1 and F4, and your other units in F2 and F3. Every enemy attack on either hedgehog costs the attacker 2 Health before the blow lands. Small attackers die before they swing. The Furrow Racer turns each prick into +1 Attack for the whole row. Kill one hedgehog and the other loses its bonus, so the enemy's kill order matters.
- **Why run it.** Enemy attacks pick front units at random, so with two of four front slots held by hedgehogs, about half of the enemy's attacks get pricked. And the corner slots, which normally do nothing special, get a job.
- **Scene.** Turn 4. You play Hedgehog Hoglet in F1 and Hedgehog Twin in F4, with a 3/3 in F2 and a 4/4 in F3. The pair is set: the Hoglet is a 2/4 and the Twin a 3/5. In the fight an enemy 3/2 attacks the Hoglet in F1. Before the blow lands, the Twin at the far end throws its quills: 2 damage, and the 3/2 dies without hitting. Next an enemy 4/5 attacks the Twin in F4. The Hoglet pricks it to 4/3, the Twin hits back for 3 and kills it, and the Twin survives at 3/1.
- **Good against.** WIDE boards of small attackers, many of which die to the prick before they swing. **Weak against.** Random damage and Start of Combat pings that kill one hedgehog, which breaks the pair, and big attackers that shrug off 2.
- **Variations.**
  - **Far End.** One card, no pair: whenever an enemy attacks the unit at the other end of this row, this deals damage equal to its Attack to the attacker first.
  - **Twin Strike.** Whenever an enemy attacks one of the pair, the other attacks that enemy immediately. The other hedgehog jumps in with a full attack, and takes the hit back.
  - **Already Here.** When one of the pair dies, the other gains its Attack and Health this combat. The race is lost, but the hedgehog at the far end is waiting.
- **Similar to.** Like the fable The Hare and the Hedgehog: wherever the enemy goes, a hedgehog is already at the other end.
- **Owner's direction.** "I don't understand Both Ends. I still don't get the proposal." (02h). Direction: example cards and a play scene.
- **Designer's response.** The rules now name the slots (F1 and F4, or B1 and B3) instead of 'the other end of this row', and the scene walks through two attacks step by step. 'Far End' is the simplest version to show if the pair is the confusing part: one card that guards the opposite corner.
- **Open.** Should a pair in F1 and F4 still count if one of them is moved in combat (Rotate, Bolt)? Proposed: the pair is checked all the time, like an aura.
- **Rules review (needs a ruling).** Works as a fixed-slot pair (F1 with F4, B1 with B3), checked all the time like an aura. Needs the 'attacker gone' line in 9.6.1, shared with Ambush and Territory, and the pre-strike should count as effect damage (the attacker's Bristle pricks the far hedgehog, which is finite because thorns never trigger thorns, R2). The F1-and-F4 picture makes it understandable; the card should show the partner slot.
- **Budget review.** Both Ends is cheap because it needs a partner; the Tier-4 racer has a full body plus text.
  - *Hedgehog Hoglet*: edge. body 3 + (+1/+2 ≈ 3 + a 2-damage prick ≈ 1.5) × a partner at the other end ≈ 0.25 on turns 1–3 ≈ 1.1 (E13, E72 on proposed R33) [guess] ≈ 4.1 vs V(1) 5: −18%, just inside the ±1 SP floor Change: If the sim agrees, 1/3 (≈ 5.1, +2%).
  - *Hedgehog Twin*: in band. Same as the old review: body 5 + (3 + 1.5) × 0.4 partner ≈ 1.8 ≈ 6.8 vs V(2) 7: −3%, ±15%
  - *Furrow Racer*: flag over. body 9 + Both Ends (≈ 5 × 0.5 partner at turn 6 ≈ 2.5) + +1 Attack this combat to its row per prick (≈ 1.2 pricks × 0.5 × 3 units × 0.6 ≈ 1.1) [guess] ≈ 12.6 vs V(4) 10: +26%, ±15% Change: 3/4 (≈ 10.6, +6%).
- **From.** rows 14.

### 46. Flood — NEW

At the start of the fight, this raises the water on both boards, weakening every front-row unit except swimmers.

- **Rules.** Start of Combat: raise the water by 1 for this combat. Both boards share one water level, which goes up to 3. Each level gives every front-row unit on both boards -1 Attack, but units with Swim get +1 Attack instead. Back-row units stand on high ground and are dry. Water can't lower a unit's Attack below 1. The water stays up after this unit dies.
- **Bends.** 9.3.1: game-wide combat modifiers come from the modifier layer; here a unit sets terrain for both boards. It adds a combat state other text can read ('while the water is up').
- **Creatures.** Beavers dam streams and flood the land around them; the Folio's Dyke Board: 'the water level decides every battle'. Swim suits otters, frogs, newts and water voles.. **Archetypes.** MEDIUM, TALL
- **Example units.**
  - *Water Vole*, Tier 1, 2/1, Hedgerow folk. Swim.
  - *Ditch Otter*, Tier 2, 3/2, Hunters. Swim.
  - *Dam-Warden Beaver*, Tier 3, 2/5, Neutral. Flood.
  - *Lodge Builder*, Tier 5, 3/7, Neutral. Flood. While the water is up, your back-row units have +1 Attack for each level.
- **How they play.** Beavers raise the water from the back row; swimmers in your front row get stronger while the enemy's front row gets weaker. Swim is a keyword any tribe can carry, so voles, otters and frogs all join. The Lodge Builder adds a second plan: a strong, dry back row.
- **Why run it.** It shrinks the enemy's front carry and grows your swimmers in one move, and both players can see it coming.
- **Scene.** Turn 7. Your opponent runs a 14/14 boar in front. You have two Dam-Warden Beavers in the back and two Ditch Otters plus a Water Vole in front. Start of Combat: the water rises to 2. Their boar is 12/14; your otters are 5/2 and your vole 4/1. Your own non-swimmers in front lose 2 Attack too, so you keep them in the back.
- **Good against.** Front-row TALL carries. **Weak against.** Boards whose carries sit in the back row, and other boards with Swim.
- **Variations.**
  - **Rain.** Start of Combat: the enemy front row has -1 Attack this combat, and your Swim units +1. One-sided and simpler, no shared level.
  - **Rising Tide.** After every 5 attacks in this combat, raise the water by 1. The water rises as the fight goes on.
  - **Marsh Slot.** End of Turn: this unit's slot becomes Marsh (a slot effect). A Swim unit in a Marsh slot has +2/+2; any other unit there has -1 Attack.
- **Similar to.** Like weather in Pokemon: Rain helps Water moves for both sides.
- **Owner's direction.** No reaction to this mechanic.
- **Open.** Do two players' Flood units add to the same level? Proposed: yes, one shared level up to 3.
- **Open.** Beavers have no tribe yet in the longlist.
- **Rules review (needs a ruling).** Works as a combat state set from a unit through the modifier layer, with one shared level up to 3 as proposed. Needs a ruling on 'can't lower Attack below 1': a front-row unit with 0 Attack should stay at 0, not rise to 1. Row changes mid-combat should recalculate it like an aura (12.2.1); readable with a visible water level.
- **Budget review.** Swim units are a little under on their own; the big swing is Flood plus several swimmers, which needs a sim.
  - *Water Vole*: flag under. body 3 + Swim (+1 Attack per water level; needs a Flood unit on either board) ≈ 0.5 [guess] ≈ 3.5 vs V(1) 5: −30%, outside the ±1 SP floor Change: 2/2 Swim (≈ 4.5, −10%).
  - *Ditch Otter*: flag under. Same as the old review: body 5 + Swim ≈ 0.5 ≈ 5.5 vs V(2) 7: −21%, ±15% Change: 3/3 Swim (≈ 6.5, −7%).
  - *Dam-Warden Beaver*: in band. Same as the old review, in the back row: 6.5 + net terrain ≈ 0.5 ≈ 7 vs V(3) 8: −12%, ±15%
  - *Lodge Builder*: in band. back row: 2.25 + 7 = 9.25 + net terrain ≈ 0.5 + back units +1 Attack per level (≈ 1.5 levels × 3 back units × 0.75 × 0.9 ≈ 3.0) [guess] ≈ 12.75 vs V(5) 12: +6%, ±15%
- **From.** creatures 18.

## L. Gold over turns

### 47. Cache — VARIANT of Battlegrounds' anomaly Prudence of Amitus

Hide some gold in this squirrel; next turn you get it back plus 1, unless the squirrel died in the fight.

- **Rules.** Cache (X). Once per turn, you may bury up to X gold in this unit. It has +1 Health for each buried gold. At the start of your next turn, dig it all up plus 1 gold. If this died in the last combat, dig up only half (rounded down) and get a 1/2 Oak Seedling in your hand instead of the +1 (lost if your hand is full). Selling this returns its buried gold, with no +1. In a triple, buried gold carries over to the golden unit. Golden: X stays the same; the bonus is +2.
- **Bends.** 4.1.3 (holding gold earns nothing): a small, capped interest. 9.1.1: a death in combat changes next turn's gold.
- **Creatures.** Red squirrel, which scatter-hoards and forgets a share of its nuts, which sprout (the Folio's Acorn Exchange).. **Archetypes.** ECO, STICKY
- **Example units.**
  - *Harvest Mouse*, Tier 1, 1/1, Hedgerow folk. Cache (2).
  - *Nutkin Teller*, Tier 2, 1/2, Hedgerow folk. Cache (3).
  - *Acorn Exchange Clerk*, Tier 4, 3/5, Hedgerow folk. Your Cache units dig up 1 more gold each, and have +1 Attack for each gold buried in them.
- **How they play.** Each Cache unit is a small bank that also gets tougher while it holds gold. Keep it alive and it pays interest; let it die and you lose half. So the bank wants the back row and STICKY friends. The Clerk raises the interest and turns the buried gold into Attack too, so a full bank fights.
- **Why run it.** Gold that sits unspent earns nothing in Bramble. Cache gives it a return, tied to an action (burying) and to keeping the squirrel alive.
- **Scene.** Turn 3. You have 6 gold. You buy one unit for 3, then bury the other 3 in your Nutkin Teller in B1, which fights as a 1/5. Your front row holds, the squirrel lives, and on Turn 4 you dig up 4 gold on top of your income: enough to upgrade and buy in the same turn.
- **Good against.** Slow lobbies where you can protect the back row. **Weak against.** Back-row reach and random damage, which find the fat squirrel and rob the bank.
- **Variations.**
  - **Long Cache.** Bury gold for two turns instead of one; dig up all of it plus 3. 'Take a little now or more later.'
  - **Seed Cache.** Once per turn, put a unit from your hand under this. At the start of your next turn it comes back to your hand with +2/+2.
  - **Shared Hoard.** Start of turn: if this survived the last combat, gain 1 gold for every 5 gold you carried over (up to 2).
- **Similar to.** Battlegrounds' anomaly Prudence of Amitus: 'Unspent Gold carries over to your next turn. If you saved at least 5, gain 1 extra.' Cache puts that interest on a unit that can die.
- **Owner's direction.** 02h on economy: "I like a lot of the economy ideas of tying economy effects to specific actions that kind of reward you for being in that type of strategy." And on Acorns: "take a little bit of stuff up front now, or get more later".
- **Designer's response.** Cache ties its interest to an action (burying) and to the board (the squirrel must survive), so it pays best in a back-row, STICKY build. Long Cache is the 'more later' version.
- **Open.** Combat deaths happen on a copy (9.1.1), so the game must remember whether this unit died in the last combat.
- **Rules review (clean).** Works as an activated ability (3.3.1) with digging at the start-of-turn step (3.2.1 step 5), and keeping X on golden fits 7.3.5. It needs R9's combat report for 'died in the last combat'. Say it can only hold gold while on the board; readable.
- **Budget review.** Cache prices as conditional income and stays in band; the Clerk makes every Cache unit pay even when it dies.
  - *Harvest Mouse*: in band. body 2 + bury 1–2 gold a turn: +1 gold if it survives (≈ 0.35 early), lose up to 1 and get a 1/2 Seedling if it dies: ≈ +0.35 gold a turn × ≈ 5 (Tier-1 recurring gold beats a plain unit at a sink of 2.0) ≈ 1.8 + Health while buried ≈ 1.5 (E50) [guess] ≈ 5.3 vs V(1) 5: +6%, ±25%
  - *Nutkin Teller*: in band. Close to the old review: ≈ 5.75, plus the Seedling on a death ≈ 0.6 → ≈ 6.4 vs V(2) 7: −9%, ±25%. For information: kept alive in the back, it nears unconditional recurring gold at Tier 2, which the proposed gold caps (not approved) would rule out
  - *Acorn Exchange Clerk*: edge. body 8 + 1 more gold per Cache unit dug up (a Cache unit that dies now breaks even: ≈ +0.55 gold a turn each × 1.5 Cache units × 0.6 build ≈ 0.5 gold a turn × 4.2 ≈ 2.1) + Cache units +1 Attack per buried gold ≈ 1.2 [guess] ≈ 11.3 vs V(4) 10: +13%, ±25%; ≈ 14 (+40%) on a board with two Cache units Change: If the bot shows two-Cache boards are common, 2/4 (≈ 9.3 typical, ≈ 12 with two Cache units).
- **From.** recruit 1.

### 48. Thrift / Revel — VARIANT of Battlegrounds' Tavern Tipper

Thrift units reward you for saving some gold this turn; Revel units reward you for spending every last coin.

- **Rules.** Thrift: End of Turn: if you have more gold than you carried into this turn (before this turn's income), do the effect. Revel: End of Turn: if you have 0 gold, do the effect.
- **Bends.** 4.1.2 to 4.1.3. Carry-over makes banking neutral; these put a board reward on each side, so 'save or spend' becomes a build identity.
- **Creatures.** Aesop's ant and grasshopper; the Folio's 'The Hive and the Carnival': thrifty ants and bees against a cicada brass band.. **Archetypes.** ECO, MEDIUM
- **Example units.**
  - *Worker Ant*, Tier 1, 1/2, Hive. Thrift: gain +1/+1 permanently.
  - *Cicada Bandleader*, Tier 2, 3/2, Neutral. Revel: give this and the units behind it +2/+1 permanently.
  - *Granary Ant*, Tier 3, 2/4, Hive. Thrift: give your back-row units +1/+2 permanently.
  - *Grasshopper Fiddler*, Tier 5, 5/4, Neutral. Thrift: give your back-row units +2/+2 permanently. Revel: give your front-row units +2/+2 permanently.
- **How they play.** Thrift units pay when you bank part of this turn's income; Revel units pay when you end at 0. Since refreshes cost 1, a Revel board can always dump its last coins into the shop. The Fiddler pays either way, so each turn the question becomes which row to grow.
- **Why run it.** Gold carry-over makes saving and spending equal; these units make your choice each turn grow the board. Thrift suits a board saving up for a big upgrade turn; Revel suits a board rolling for pieces.
- **Scene.** Turn 5. You have 9 gold, 2 of it carried over. You are saving for Tier 4 next turn, so you buy one unit and end with 6: more than the 2 you carried in, so the Granary Ant gives your back row +1/+2. On Turn 6 you upgrade, roll and spend everything: the Cicada Bandleader triggers instead.
- **Good against.** Thrift: lobbies slow enough for a delayed spike. Revel: fast lobbies, where it hits hard now. **Weak against.** Thrift: early pressure while you bank. Revel: turns where you need to save for an upgrade.
- **Variations.**
  - **Profit.** End of Turn: if you have more gold than you had after this turn's income came in, do the effect. Only selling and gold effects reach it, so it rewards ECO actions.
  - **Feast.** End of Turn: if you spent 10 or more gold this turn, do the effect. Revel for big turns, no need to hit exactly 0.
  - **Lean Years.** End of Turn: if you have banked gold for 3 turns in a row, do the effect, then the count restarts. A time-bound Thrift, as pillar 13 suggests.
- **Similar to.** Battlegrounds' retired Tavern Tipper: 'If you have any unspent Gold at the end of your turn, gain +1/+2.' Revel mirrors it.
- **Owner's direction.** 02h on economy: "tying economy effects to specific actions that kind of reward you for being in that type of strategy." Pillar 13: a design that rewards not acting is fine if isolated or time-bound.
- **Designer's response.** Thrift rewards a choice, saving part of your income, while every other action stays open, so it is isolated in the sense of pillar 13. I read 'started the turn with' as the gold carried in before income, so that Thrift means 'you saved some'. The rules review's reading (after income) is kept as the Profit variation, since it rewards selling and gold effects instead.
- **Open.** Which reading of 'started the turn with' does the owner want: before income (save some) or after income (make a profit)?
- **Rules review (clean).** Works: both read gold at End of Turn (3.4.1 step 1), and 'carried into this turn' is a stored value from 3.2.1 step 1. Say whether gold dug up from Cache counts as carried in or gained this turn (proposed: gained). Readable.
- **Budget review.** Whole-row permanent buffs every turn put all four units +75% to +235% over their tiers (band ±25%); the save-or-spend choice survives if each trigger buffs one unit.
  - *Worker Ant*: flag over. Thrift now fires whenever you save part of this turn's income, ≈ 0.8 of turns in a Thrift build: s ≈ 2 × 0.8 = 1.6, twice the Tier-1 cap; 3.9 × 1.6 ≈ 6.2 − banking cost ≈ 0.5 [guess] ≈ 8.7 vs V(1) 5: +75%, ±25% Change: Thrift: gain +1 Health permanently (s ≈ 0.7, under the cap): ≈ 5.3 (+6%).
  - *Cicada Bandleader*: flag over. Same text as the old review: Revel on ≈ 0.7 of turns, +2/+1 to this and ≈ 1.5 units behind: s ≈ 4.7, over three times the Tier-2 cap; ≈ 22 vs V(2) 7: +214%, ±25% Change: 1/1, 'Revel: give this and the units behind it +1 Attack permanently' (s ≈ 1.5, at the cap): ≈ 7.5 (+7%).
  - *Granary Ant*: flag over. +1/+2 to ≈ 2.5 back units (≈ 6.9 SP) a fire × 0.8 of turns (the new wording fires far more often than the old review's 0.3): s ≈ 5.5, over three times the Tier-3 cap; 3.5 × 5.5 ≈ 19 [guess] ≈ 25 vs V(3) 8: +215%, ±25% Change: 1/2, 'Thrift: give a random back-row unit +1/+1 permanently' (s ≈ 1.4): ≈ 7.4 (−8%).
  - *Grasshopper Fiddler*: flag over. One side fires on ≈ 0.9 of turns: back +2/+2 ≈ 10.5 SP or front +2/+2 ≈ 16: s ≈ 12, three times the Tier-5 cap of 3.8; 2.6 × 12 ≈ 31 [guess] ≈ 40 vs V(5) 12: +235%, ±25% Change: 2/2, and each side gives one random unit in its row +2/+2 (s ≈ 3.4, under the cap): ≈ 12.8 (+7%).
- **From.** recruit 2.

### 49. Upkeep (X) — NEW (merged with Hungry)

A cheap unit that hits far above its tier, but you must feed it gold every turn or it fights at half Attack.

- **Rules.** Upkeep (X): At the start of your turn, after your gold is set and before start-of-turn triggers, choose for each Upkeep unit: pay X gold, or it Starves until your next turn starts. A Starved unit has half its Attack, rounded down (applied after all other Attack changes). A golden Upkeep unit keeps the same X. Hungry (the creature version): In each attack cycle, this attacks before your other units; then your side continues in reading order, and this doesn't move the attack pointer. At the start of your turn it eats 1 gold; if you have none, it loses 1/1 permanently.
- **Bends.** 3.2.1 (the start of a turn gives gold and never takes it) and 4.1: a recurring cost on a body. Hungry also bends 9.4.2 and 9.4.5: it jumps the reading order.
- **Creatures.** Shrews: they must eat every few hours and are the fastest things in the hedge.. **Archetypes.** TALL, ECO
- **Example units.**
  - *Pygmy Shrew Berserker*, Tier 1, 4/3, Hedgerow folk. Upkeep (1).
  - *Shrew Quartermaster*, Tier 2, 2/3, Hedgerow folk. After you pay Upkeep for a unit, give it +1/+1 permanently.
  - *Shrew Warband Chief*, Tier 4, 5/5, Hedgerow folk. Upkeep (2). Start of Combat: if you paid Upkeep for every unit this turn, give your Upkeep units +2 Attack this combat.
- **How they play.** The Berserker is a 4/3 on turn 1, when everything else is a 2/3 or a 3/2. The Quartermaster turns every payment into a permanent +1/+1, so a shrew you keep feeding becomes a slow scaler instead of a tax. The Chief pays out only on turns you fed everyone, so starving one shrew to afford an upgrade has a real cost. Any card that makes gold now also makes shrew stats.
- **Why run it.** The most fight power per gold on turns 1 to 4, when fights decide early health. Later, the bill is small next to your income, and with the Quartermaster the bill is buying stats.
- **Scene.** Turn 1, you buy Pygmy Shrew Berserker and win a fight nobody else can win. Turn 2, you have 4 gold: pay 1 upkeep, buy Shrew Quartermaster with the rest, and the Berserker grows to 5/4. Turn 3 you want to upgrade, so you let the Berserker starve (2/4 this fight) and accept a close loss. Turn 6 you add the Chief: you pay 3 gold at the start of each turn, and in the fight your shrews have +2 Attack.
- **Good against.** Economy boards and slow scalers in the first five turns, which take damage while they build. **Weak against.** Long games against tall boards: shrews stop scaling once you stop paying, and a short turn means starving them.
- **Variations.**
  - **Hungry.** Pygmy Shrew, Tier 1, 3/1: "Hungry." Attacks first in each cycle; eats 1 gold at the start of each turn, or loses 1/1 permanently.
  - **Tier Upkeep.** "Upkeep: pay gold equal to your tier, or this Starves." The cost grows as you level, so it stays a real choice on turn 12.
  - **Lean Times.** "Upkeep (1). While Starved, this has +4 Health." Starving becomes a choice: a cheap wall this fight, or a full hitter.
- **Similar to.** Magic: The Gathering's upkeep costs, where you pay each turn or lose the creature.
- **Open.** A Hungry unit in the back row attacks first but can't be attacked while the front row lives. Should Hungry work only from the front row?
- **Open.** Fixed X or tier-scaled X? With uncapped carry-over, 1 gold is a lot on turn 2 and almost nothing on turn 12.
- **Open.** Does a Starved unit show its halved Attack in the Recruit Phase, so the opponent's snapshot reads it correctly?
- **Rules review (needs a ruling).** Upkeep works as a new step in 3.2.1 between gold and start-of-turn triggers, and the Starved half Attack sits in the last stat layer. Needs rulings for Hungry: it attacks out of turn at the start of each cycle (R5), so say it is then flagged and skips its own slot's turn; and a 1-Health Hungry unit at 0 gold drops to 0 Health and dies in the Recruit Phase (5.3.7), which the text should say. The snapshot copies the Starved state into the fight (9.1.1).
- **Budget review.** Upkeep is a fair option on its own; the Quartermaster turns every payment into permanent stats and needs a once-per-turn limit.
  - *Pygmy Shrew Berserker*: in band. Same as the old review: starved 2/3 = 5; paying 1 gold for +2 Attack is a fair option ≈ +0.5 → ≈ 5.5 vs V(1) 5: +10%, ±25% (proposed E98)
  - *Shrew Quartermaster*: flag over. body 5 + +1/+1 permanently per Upkeep payment (≈ 1.2 Upkeep units × 0.6 build ≈ 0.7 payments a turn: s ≈ 1.4, over the Tier-2 cap of 1.3; 3.7 × 1.4 ≈ 5.2) [guess] ≈ 10.2 vs V(2) 7: +46%, ±25%; with three Upkeep units s ≈ 6 Change: 1/2, once per turn (s ≈ 1.2): ≈ 7.4 (+6%).
  - *Shrew Warband Chief*: in band. starved 2/5 = 7; paying 2 gold buys +3 Attack plus Start of Combat +2 Attack to ≈ 1.5 Upkeep units (≈ 2.4 × 0.8), ≈ 5 SP for gold worth ≈ 4: ≈ +1.4 + option ≈ 0.3 [guess] ≈ 8.7 vs V(4) 10: −13%, ±25%
- **From.** recruit 3, creatures 11.

### 50. Wager (X) — NEW

Bet some of your gold on winning your next fight: win and you get double back, lose and it's gone.

- **Rules.** Wager (X): At End of Turn you may stake up to X gold on your next fight. The stake leaves your gold at once. If you win, you gain double the stake at the start of your next turn. If you tie, you get the stake back. If you lose, it is gone. You make at most one wager a turn, up to your highest Wager value. A fight against a ghost or a recorded board settles the same way; the result is known before your next turn starts.
- **Bends.** 10.1: a fight pays out only in hero damage. Wager pays out in gold too. It uses the next-opponent information you already have (2.3.3).
- **Creatures.** Otters: the Norse otter's ransom and its cursed gold; the Folio's otter smugglers.. **Archetypes.** ECO
- **Example units.**
  - *Otter Bookie*, Tier 2, 2/3, Hunters. Wager (2).
  - *Ransom Otter*, Tier 3, 3/3, Hunters. Wager (3). After you win a wager, this gains +1/+1 permanently.
  - *High-Stakes Otter*, Tier 5, 5/5, Hunters. Wager (5). Start of Combat: give your front-row units +1 Attack for each gold you staked this turn (this combat).
- **How they play.** Wager values don't add: a second otter only raises your cap, so you run several for the payoffs, not the cap. The Ransom Otter grows with every bet you win, and the High-Stakes Otter turns the stake itself into fight power, so a bigger bet makes the win more likely.
- **Why run it.** It turns a board that is already ahead into gold, so a winning streak pays for your upgrades without slowing your board.
- **Scene.** Turn 4, you have won three fights in a row and your next opponent's board looks weaker than yours. You end the turn with 3 gold and stake all of it with Ransom Otter. You win: turn 5 starts with 6 extra gold, the otter is 4/4, and you upgrade and buy in the same turn.
- **Good against.** Slow starters and economy boards whose early boards are thin. **Weak against.** Close, swingy fights and losing streaks, where each lost bet sets you back further.
- **Variations.**
  - **Stake a Unit.** "Wager: at End of Turn you may stake a unit. Lose the fight and it is destroyed; win and it gains +3/+3 permanently."
  - **Insured.** "Wager (4). On a loss, get half the stake back, rounded down." A safer bet that pays the same on a win.
  - **Side Bet.** "End of Turn: you may stake up to 3 gold that the enemy unit across from this dies in the next fight. If it does, gain double."
- **Similar to.** Teamfight Tactics' Fortune trait, where you bank on a streak and cash out; poker-style betting.
- **Open.** In async play the stake is a bet on your own board against a recorded one. Is that still fun, or should the bet be on something you can read better?
- **Open.** Does a golden double X (a stake cap is a number, but it works like a threshold under 7.3.5)?
- **Open.** Does Wager need a late-game ceiling on the payout, given uncapped gold?
- **Rules review (needs a ruling).** Works against a recorded board: the stake leaves at End of Turn and settles at the next start of turn. Needs a ruling on golden X (a stake cap reads like a threshold under 7.3.5, R12) and depends on async play showing the next opponent (2.3.3 under 2.1.5's open question). Readable.
- **Budget review.** Wager is fair if players can't read their next fight; the High-Stakes payoff turns a 5-gold stake into a 20-Attack front row.
  - *Otter Bookie*: in band. body 5 + staking 2 when you expect to win (≈ 0.65 win rate, on ≈ 0.6 of turns): ≈ +0.36 gold a turn × 6.5 (Tier-2 recurring price) ≈ 2.3 (E50 on R28) [guess] ≈ 7.3 vs V(2) 7: +4%, ±25%; ≈ 5 (−29%) if players can't pick their fights
  - *Ransom Otter*: edge. Same as the old review: ≈ 11.3 (+41%) if players pick their fights, ≈ 9.5 (+19%) if not, ±25% Change: If the bot shows players pick their fights, 2/2 (≈ 9.3, +16%).
  - *High-Stakes Otter*: flag over. body 10 + Wager (5) ≈ 0.9 gold a turn × 4.1 ≈ 3.7 + up to +5 Attack to each front unit this combat (≈ 20 Attack × 0.9 of turns × 0.8 ≈ 14; E03) [guess] ≈ 28 vs V(5) 12: +130%, ±25% Change: 3/3, and the Attack goes to one random front-row unit (+1 per gold staked ≈ 3.6): ≈ 13.3 (+11%).
- **From.** recruit 4.

### 51. Bargain — NEW

A fairy gives you something big now, and you pay its price a few turns later.

- **Rules.** Bargain: When you play this, you get its gift now. Its price is due at the start of your turn a set number of turns later; the due turn shows on the card and on your hero. The debt is yours, not the unit's: selling, tripling or losing the unit doesn't clear it. If you sell the unit before the price is due, you pay the price at once, doubled. A price in gold that you can't pay in full takes what you have, then its fallback happens. A golden Bargain unit doubles both its gift and its price.
- **Bends.** 3.2.1: a new start-of-turn step where debts are paid. 4.1: gold borrowed against later turns. 4.3: selling has a cost as well as a value.
- **Creatures.** Fairies: their bargains always carry a catch, and the debt always comes due.. **Archetypes.** ECO, TALL
- **Example units.**
  - *Hob of the Crossroads*, Tier 2, 2/2, Fairies. Bargain: give a unit +4/+4 permanently. Price, in 2 turns: your shop has one fewer unit that turn.
  - *Toll Brownie*, Tier 3, 3/4, Fairies. After you pay a Bargain price, give your Fairies +1/+1 permanently.
  - *Thrice-Kissed Sprite*, Tier 4, 3/3, Fairies. Bargain: gain 4 gold. Price, in 3 turns: pay 6 gold. Fallback: your highest-Attack unit loses 4 Attack permanently.
- **How they play.** The Hob puts a big buff on your carry two turns early; the Sprite is a loan for the turn you need to upgrade and buy at once. The Toll Brownie turns every repaid debt into a buff for your Fairies, so a fairy player who plans for the due days comes out ahead. The price sometimes lands on the board (a lost 4 Attack), so opponents can see it in fights.
- **Why run it.** Tempo when you need it most: a spike turn now, paid for on a turn when you can afford it.
- **Scene.** Turn 4, you have 7 gold and need 8 to upgrade and buy the unit you want. You play Thrice-Kissed Sprite: +4 gold, upgrade to tier 4, buy. Turn 7 the 6 gold falls due. You kept gold back on turns 5 and 6, and with Toll Brownie on board, paying it gives your three Fairies +1/+1.
- **Good against.** Opponents you need to beat on one key turn, such as a lobby leader on a streak. **Weak against.** Bad due days: a loss streak or a dry shop on the turn the price comes due.
- **Variations.**
  - **Fairy Gold.** "Bargain: gain 3 gold now. Price: none, but the gold vanishes at End of Turn if unspent." A same-turn loan with no debt.
  - **Open Bargain.** "Bargain: gain 4 gold. Pay 4 back whenever you like; each turn unpaid, the price rises by 1." You choose the due day.
  - **Changeling's Price.** "Bargain: get a Created copy of a unit in your shop. Price, in 2 turns: a random unit on your board is replaced by a Created 1/1."
- **Similar to.** Magic: The Gathering's Pact cards: free now, pay on your next turn or lose.
- **Open.** Should prices more often land on the board, so the debt is visible in fights, rather than in gold?
- **Open.** Does a Bargain price count as a start-of-turn trigger (reading order) or a separate debt step before them?
- **Rules review (needs a ruling).** The player-level debt is well specified, including selling and fallbacks. Needs a ruling on where debts are paid in 3.2.1, and their order against Upkeep (proposed: debts after gold is set, then Upkeep, then start-of-turn triggers). Say that Pair's 'triggers twice' doubles both gift and price; the due turn shown on the hero keeps it readable.
- **Budget review.** Bargain prices well when the price is real; the Hob's +4/+4 gift is the one still over.
  - *Hob of the Crossroads*: flag over. Same as the old review: body 4 + +4/+4 now (0.9 × 8 ≈ 7.2) − one fewer shop unit once ≈ 0.5 ≈ 10.7 vs V(2) 7: +53%, ±15% Change: 1/1 and +3/+3 (≈ 6.9, −1%).
  - *Toll Brownie*: edge. body 7 + +1/+1 permanently to ≈ 2.5 Fairies per Bargain price paid (≈ 0.2 a turn: s ≈ 0.9, under the cap; 3.5 × 0.9 ≈ 3.2) [guess] ≈ 10.2 vs V(3) 8: +28%, ±25% Change: If the sim agrees, 2/4 (≈ 9.2, +15%).
  - *Thrice-Kissed Sprite*: in band. body 6 + 4 gold now (≈ 8.4 at about 2.1 a gold) − the cheaper price: spend to 0 on debt day and the carry loses 4 Attack (≈ −5) rather than pay 6 gold (≈ −12) [guess] ≈ 9.4 vs V(4) 10: −6%, ±25%. The new fallback wording closes the old dodge. For information: 4 gold in one trigger is over the proposed one-off cap (not approved)
- **From.** creatures 9.

## M. The shop: buying, selling, refreshing, tiers

### 52. Pawn — NEW

Sell a unit for more than usual, with a chance to buy it back next turn for a little extra.

- **Rules.** Pawn: Once per turn, instead of selling a Bought unit with Pawn, you may pawn it: gain 3 gold, and it goes into your Pawn slot at the end of your shop, frozen, keeping its buffs. Until the end of your next turn you may buy it back for 4 gold; it returns to your hand, Bought, and triggers "when played" as normal when you play it. Pawning isn't selling, so "when sold" effects don't trigger. If you don't buy it back in time, it is forfeit and returns to the pool (a golden returns copies under 5.3.5). Created units can't be pawned. You have one Pawn slot.
- **Bends.** 4.3.3 (sell value), 6.1.1 (shop size) and 4.5 (freeze).
- **Creatures.** The Folio's corvid crime family: jackdaws run the pawnshop.. **Archetypes.** ECO, TALL
- **Example units.**
  - *Carrion Crow Fence*, Tier 1, 2/1, Birds. Pawn. When this is forfeit, gain 1 gold.
  - *Jackdaw Pawnbroker*, Tier 2, 2/3, Birds. Your other units have Pawn.
  - *Jackdaw Uncle*, Tier 4, 4/4, Birds. After you buy back a pawned unit, give it +2/+2 permanently.
- **How they play.** The Pawnbroker gives your whole board the option, so any unit can become a loan of 3 gold for one fight. The Uncle makes buying back a buff, so a pawn cycle loses 1 gold but gains +2/+2. The Crow Fence is a body you are happy to let go: pawning it and letting it lapse earns 4 gold in total.
- **Why run it.** It lands an upgrade or a triple a turn early, and you get the unit back after the spike.
- **Scene.** Turn 5, you have 8 gold. You need 9 to upgrade, plus 3 for the third Mole that makes a triple. You pawn your Hedgehog wall for 3, upgrade, buy the Mole and triple. You fight one body short. Turn 6 you buy the Hedgehog back for 4, and with Jackdaw Uncle it comes back +2/+2.
- **Good against.** Opponents racing to the same triple or tier: you get there first. **Weak against.** Aggressive boards that punish the fight you play a body short.
- **Variations.**
  - **Long Loan.** "Pawn: gain 3 gold. Buy back for 4, plus 1 for each turn it has been pawned. It is never forfeit, but it takes up the Pawn slot."
  - **Quick Hock.** "Pawn for 2 gold; buy back for 2, this turn only." A free loan inside one turn, for landing a triple.
- **Similar to.** A real pawnshop loan.
- **Open.** Should buying back go to hand (and retrigger "when played") or straight back to its slot (no retrigger)? Hand is cleaner; slot is safer for free-refresh triggers.
- **Open.** Can a pawned unit be refreshed away, or is the Pawn slot outside refreshes entirely? Proposed: outside.
- **Rules review (needs a ruling).** Works as a sell alternative with its own slot outside refreshes. Needs a ruling on 'once per turn': per player or per Pawn unit, which matters once the Pawnbroker gives every unit Pawn. Buying back to hand re-fires 'when played', so under G1 any 'when played: refresh the shop' unit becomes a refresh for about 1 gold; once per turn passes G1, but it must be reviewed against every retrigger (R11).
- **Budget review.** Pawning is a better sale, which is gold, and gold at Tiers 1–2 is worth a lot, so the gold-makers sit better a tier or two higher.
  - *Carrion Crow Fence*: flag over. body 3 + pawning instead of selling gives 3 gold and +1 more on forfeit: +3 gold over a normal sale, paid around turns 3–5 (≈ 6; E54) [guess] ≈ 9 vs V(1) 5: +80%, ±25%; at the Tier-1 table ≈ 6.5 (+30%), still over Change: Tier 2, same text (the gold arrives around turns 5–6, ≈ 5.4): ≈ 8.4 (+20%).
  - *Jackdaw Pawnbroker*: flag over. As the old review: one Pawn slot, ≈ one pawn every other turn for +2 over a sale ≈ +1 gold a turn ≈ 6 [guess] ≈ 11 vs V(2) 7: +57%, ±25%. The new rules already keep Created units out Change: Tier 4 at 3/4, same text (+1 gold a turn at 4.2 × 0.8 ≈ 3.4): ≈ 10.4 (+4%).
  - *Jackdaw Uncle*: in band. body 8 + +2/+2 per buy-back (once a turn: pawn, then buy back at once for a net 1 gold; net ≈ 4 − 2 = 2 SP × 0.6 Pawn on board: s ≈ 1.2; 3.1 × 1.2 ≈ 3.7; E88) [guess] ≈ 11.7 vs V(4) 10: +17%, ±25%. For information: each buy-back replays 'when played' text for 1 gold
- **From.** recruit 6.

### 53. Barter — NEW

Once a turn, swap a unit on your board for a unit in the shop without paying.

- **Rules.** Barter: Once per turn for each unit with Barter, instead of buying, you may swap one of your board units with a unit in your shop. The shop unit goes straight into the board unit's slot; it isn't played, so "when played" effects don't trigger, and it takes the old unit's origin (Bought or Created). The old unit goes into that shop slot with its buffs and costs the normal 3 to buy back. If the shop refreshes, or the turn ends with the shop unfrozen, it returns to the pool and loses its buffs; a Created unit vanishes instead. If the new unit completes a triple, it triples at once (7.3.1).
- **Bends.** 4.2.1 (units cost 3) and 7.2.3 (units enter through the hand and trigger "when played"). The new unit takes the old one's origin (4.3).
- **Creatures.** The Folio's fox rag-and-bone traders.. **Archetypes.** MEDIUM, WIDE
- **Example units.**
  - *Fox Cub Peddler*, Tier 1, 2/1, Hunters. Barter.
  - *Rag-and-Bone Fox*, Tier 3, 3/3, Hunters. Barter. After you barter, the new unit gains +1/+1 permanently.
  - *Market Vixen*, Tier 5, 4/6, Hunters. Barter. After you barter, the new unit gets the permanent buffs of the unit you gave away.
- **How they play.** The Peddler swaps a weak body for a shop unit for free, which is a buy without gold. The Rag-and-Bone Fox adds a small buff to every trade. The Market Vixen moves your buffs onto the better unit, so a tall carry can change into a higher-tier body without starting over. This is one concrete version of the Hunters' idea of foxes taking a shop card once a turn.
- **Why run it.** Cheap pivots: you upgrade units without gold, and a tall board isn't stuck with its first carry.
- **Scene.** Turn 7, your carry is a tier 2 Mole with +10/+10 from earlier turns, and the shop shows the tier 5 Badger you want. With Market Vixen you barter the Mole for the Badger: it lands in F2 with the Mole's +10/+10 and +1/+1 from Rag-and-Bone Fox. You spent no gold and still have 10 to upgrade.
- **Good against.** Players who read your last board: barter boards change shape between fights. **Weak against.** Thin shops: if the shop shows nothing you want, the fox is a plain body.
- **Variations.**
  - **Trade-In.** "Barter: pay 1 gold; the new unit goes to your hand instead and is played as normal." Slower, but keeps "when played" effects.
  - **Hand Barter.** "Once per turn, swap a card in your hand with a unit in your shop."
  - **Even Trade.** "Barter only for a unit of the same tier or lower." A safer, cheaper version for low tiers.
- **Open.** Swapping a Created token in makes the shop unit Created (sells for 0). Is a token-for-real-unit swap too strong for WIDE, or the point?
- **Open.** Does the Market Vixen's buff transfer need a limit (for example, only buffs from this game's effects, not golden base stats)?
- **Rules review (needs a ruling).** Works: the shop unit enters the slot without being played and takes the old unit's origin, consistent with 4.3.2. Needs a ruling for the Market Vixen: the given-away unit goes to the shop 'with its buffs' and the new unit also 'gets' them, so buffs are copied, not moved, and buying the old unit back duplicates a carry's buffs every turn; say the old unit loses them. Base stats versus buffs is answerable with the stat layers (architecture-notes.md 4).
- **Budget review.** A free swap saves 2 gold every turn, so Barter needs a gold cost or a higher tier.
  - *Fox Cub Peddler*: flag over. body 3 + a barter saves 2 gold against sell-and-buy (≈ 0.4 uses a turn on turns 1–5: ≈ 0.8 gold a turn × ≈ 5.5 early recurring price ≈ 4.5; E44) [guess] ≈ 7.5 vs V(1) 5: +50%, ±25% Change: Barter costs 1 gold on this card (it still saves 1): ≈ 5.6 (+12%).
  - *Rag-and-Bone Fox*: flag over. Same as the old review: ≈ recurring +2 gold a turn + +1/+1 per barter (s = 2, over the Tier-3 cap) ≈ 23 vs V(3) 8: +188%, ±25% Change: 'Barter (1 gold)' and drop the +1/+1, on 1/2 (≈ 8.1, +1%); the +1/+1 payoff can live on a Tier-5 fox.
  - *Market Vixen*: flag over. body 10 + Barter late (≈ 0.8 uses × 2 gold ≈ 1.6 gold a turn ≈ 5.8) + the new unit keeps the old one's permanent buffs (≈ 4 SP a use: s ≈ 3.2; 2.6 × 3.2 ≈ 8.3; E08) [guess] ≈ 24 vs V(5) 12: +100%, ±25% Change: Drop its own Barter so it pays off other Barter units, on 3/6: 9 + 2.6 × 1.9 ≈ 14 (+17%). The text should say the unit given away loses those buffs, or buying it back duplicates them.
- **From.** recruit 7.

### 54. Aisle — NEW

Each unit improves one card in your shop, depending on which slot it fought from last time.

- **Rules.** Aisle: Your shop's unit cards line up with your board slots in reading order: the first unit card is F1's aisle, the second F2's, and so on, with the fifth B1's and the sixth B2's. The spell card has no aisle. A unit's aisle is the slot it stood in when your last fight began. Aisle text acts on the unit card in that aisle each time the shop fills (at the start of your turn and after each refresh). A unit that hasn't fought since you got it has no aisle. A discount never takes a card below 1 gold.
- **Bends.** 6.1: the shop ignores position. Now combat position is also shop position, so free moves (8.3.3) gain a cost.
- **Creatures.** The Folio's Sett Gentry: badger landlords whose tenants pay rent to stand near them.. **Archetypes.** ECO, MEDIUM
- **Example units.**
  - *Rent-Paying Vole*, Tier 1, 1/3, Hedgerow folk. Aisle: when you buy that card, give this +1/+1 permanently.
  - *Sett Landlord*, Tier 2, 2/5, Hunters. Aisle: that card costs 1 less.
  - *Market Hedgehog*, Tier 4, 3/4, Hedgerow folk. Aisle: that unit has +2/+2.
- **How they play.** The Landlord makes one shop card cheaper every refill, and it wants the front row because front aisles exist from tier 1. The Hedgehog buffs the card in its aisle, so placing it next to the Landlord gives you two good cards side by side. The Vole grows when you buy from its aisle, which pays you for refreshing that slot. Back-row aisles open only at tier 4 (5 unit cards) and tier 6 (6), so back-row Aisle units are a late plan.
- **Why run it.** Cheaper and stronger buys every turn, and the deciding question each fight is where your shopkeepers stand.
- **Scene.** Last fight your Sett Landlord stood in F1 and your Market Hedgehog in F2. Turn 6, the shop fills: card 1 costs 2 gold, and card 2 is a +2/+2 unit. You refresh twice and get the same deal each time. Before you end the turn you think about moving the Landlord to the back row, where it would survive longer, but its discount would move to card 5, which you won't see until tier 4.
- **Good against.** Slow boards that let you shop cheaply for several turns. **Weak against.** Boards that kill your front row early: Aisle units in the front row are your shopkeepers and your wall at once.
- **Variations.**
  - **Window Shopping.** "Aisle reads the slot this stands in now, not where it fought." Simpler, but free moves then cost nothing.
  - **Corner Shop.** "Aisle: if that card shares a tribe with this, it costs 1 less." Rewards tribe focus.
  - **Shop Front.** "Aisle: that card is frozen each time the shop fills." A one-card freeze that follows the unit's position.
- **Open.** Needs a clear link in the UI from each slot to its shop card. Is that worth the work?
- **Open.** A 1-gold buy and a 1-gold sell make buy and sell triggers nearly free; fine while no Aisle effect refreshes the shop?
- **Rules review (needs a ruling).** Works with a fixed mapping of shop unit cards to slots, using 4.2.3's empty bought slots. Needs rulings: does the Market Hedgehog's '+2/+2' stay on the unit after it is bought (proposed yes, as 'gains'); and where Pawn and Cold Store cards sit in the aisle order. Not a loop: a bought slot only refills through a paid refresh, so cheap buy-and-sell cycles stay priced; hard to read without a drawn link from slot to card.
- **Budget review.** Aisle text acts on every shop fill, so with no turn timer it needs once per turn and smaller bodies.
  - *Rent-Paying Vole*: flag over. body 4 + +1/+1 permanently per aisle card bought (≈ 0.4 a turn early, more on refresh-heavy turns: s ≈ 0.8, at the Tier-1 cap; 3.9 × 0.8 ≈ 3.1) [guess] ≈ 7.1 vs V(1) 5: +42%, ±25% Change: 1/2 (≈ 6.1, +22%).
  - *Sett Landlord*: flag over. Same as the old review: ≈ recurring +0.7 gold a turn from discounts (≈ 4.5) + body 7 ≈ 11.5 vs V(2) 7: +64%, ±25% Change: Tier 3, 2/2, once per turn (≈ 7.6, −5%).
  - *Market Hedgehog*: flag over. Same as the old review: +2/+2 on the aisle card when bought (s ≈ 2: 3.1 × 2 ≈ 6.2) + body 7 ≈ 13.2 vs V(4) 10: +32%, ±25% Change: 2/3 and once per turn (≈ 11.2, +12%).
- **From.** recruit 8.

### 55. Cold Store — VARIANT of Battlegrounds' Freeze

Keep one shop card in the snow for as many turns as you like; it grows every turn until you buy it.

- **Rules.** Cold Store: Once per turn, if your Cold Store is empty, you may put one unit card from your shop into it. You have one Cold Store. The stored card stays through refreshes and turns and takes up one of your shop's slots until you buy it. At the start of each of your turns it gains +1/+1. You buy it at its normal price; it arrives Bought and keeps its growth.
- **Bends.** 4.4.1 (refresh replaces every card), 4.5.3 (the freeze ends each turn) and 5.3.2 (a copy kept out of the pool for many turns).
- **Creatures.** The wolverine caches meat in snow; the red-backed shrike keeps a larder of prey on thorns.. **Archetypes.** TALL
- **Example units.**
  - *Red-Backed Shrike*, Tier 2, 2/2, Birds. Cold Store.
  - *Snow-Cache Wolverine*, Tier 3, 4/3, Hunters. Cold Store. Your stored card gains +2/+2 a turn instead.
  - *Ice-Cellar Stoat*, Tier 4, 3/5, Hunters. After you buy a unit from Cold Store, get a Created plain copy of it.
- **How they play.** The Shrike lets you hold one card from tier 2 on; the Wolverine doubles its growth. The Stoat turns a stored card into two copies, which is two thirds of a triple. Each stored card costs you a shop slot every refresh, so the price is a smaller shop while it ripens.
- **Why run it.** You ripen a carry before you buy it, or hold the copy you need for a triple without spending a hand slot or gold.
- **Scene.** Turn 3, the shop shows a tier 3 unit you love but can't use yet. You put it in Cold Store with the Shrike. Turns 4 to 6 you shop from four cards instead of five. Turn 6 you buy it with +3/+3 on top (+6/+6 with the Wolverine), and the Stoat gives you a second copy.
- **Good against.** Boards that peak in the mid game: your stored unit lands as a surprise. **Weak against.** Low-tier tempo: a smaller shop at tier 1 and 2 hurts most.
- **Variations.**
  - **Root Cellar.** "Cold Store, but the stored card sits in an extra slot and gains only +1 Health a turn." Costs no shop slot.
  - **Snowbank.** "Your stored card gains +1/+1 each time you refresh, instead of each turn." A concrete version of the Birds' 'each refresh improves something in the shop'.
  - **Spoils.** "Cold Store. A card stored for 3 turns costs 0."
- **Similar to.** Battlegrounds' Freeze, kept on one card across refreshes and turns.
- **Open.** Taking a shop slot is a third of the units at tier 1. Should Cold Store start at tier 2 only?
- **Open.** Is growth unbounded (linear) a problem if a card sits for ten turns?
- **Rules review (needs a ruling).** Works as a player-level stored card kept out of the pool (5.3.2) that grows at start of turn. Needs a ruling on what happens to the stored card when no Cold Store unit is left on the board (proposed: it stays until bought, but can't be replaced). Two Wolverines shouldn't stack their 'instead'; readable.
- **Budget review.** A card that grows in the shop is per-turn scaling paid out on purchase; the three units are +34% to +130% over their tiers (band ±25%).
  - *Red-Backed Shrike*: flag over. body 4 + the stored card grows +1/+1 a turn until bought (s ≈ 2 × 0.85 ≈ 1.7, over the Tier-2 cap; 3.7 × 1.7 ≈ 6.3) − a shop slot ≈ 0.5 (E14 on one card) [guess] ≈ 9.8 vs V(2) 7: +40%, ±25% Change: Tier 3 at 2/2 (≈ 9.5, +19%), or Tier 2 at 1/1 (≈ 7.8, +11%).
  - *Snow-Cache Wolverine*: flag over. Now +2/+2 a turn: s ≈ 3.4, twice the Tier-3 cap; 3.5 × 3.4 ≈ 11.9 − 0.5 + body 7 [guess] ≈ 18.4 vs V(3) 8: +130%, ±25% Change: Tier 5 at 2/3 (2.6 × 3.4 ≈ 8.8): ≈ 13.3 (+11%).
  - *Ice-Cellar Stoat*: flag over. body 8 + a Created plain copy per Cold Store buy (≈ 0.25 a turn × ≈ 7 SP, E43; card generation every turn priced as per-turn scaling, 3.1 × 1.75 ≈ 5.4), and the copy helps triples [guess] ≈ 13.4 vs V(4) 10: +34%, ±25% Change: 2/4 (≈ 11.4, +14%).
- **From.** recruit 9 (marked variant by the designer).

### 56. Fast (action, N) — NEW *(was Fast (action))*

Go without one action for a few turns in a row, and this unit gives you a feast: a big turn of that same action.

- **Rules.** Fast (action, N): This keeps a count. At End of Turn, if you didn't do the named action this turn, the count goes up by 1; if you did, it goes back to 0. When the count reaches N, the Feast happens and the count goes back to 0. Only your own paid actions count: a paid refresh, buying from the shop, or selling. Free refreshes and effects don't. The count shows on the card. Break Fast: at any time in your turn you may end the fast early to get half the Feast, rounded down, and the count goes back to 0.
- **Bends.** 3.1.2 and 4.4. With no timer, the usual best play is to refresh until gold runs out; Fast puts a price on doing the same thing every turn. With uncapped carry-over (4.1.2), not doing an action is saving for it.
- **Creatures.** The heron stands still, then stabs; the olm can go years without food.. **Archetypes.** TALL, ECO
- **Example units.**
  - *Still-Water Heron*, Tier 2, 3/2, Birds. Fast (refresh, 2). Feast: gain +4/+4 permanently.
  - *Lenten Heron*, Tier 4, 3/5, Birds. Fast (refresh, 2). Feast: next turn, your first 8 refreshes are free.
  - *Olm Sleeper*, Tier 5, 2/8, Bog folk. Fast (buy, 3). Feast: next turn, units in your shop cost 2 gold.
- **How they play.** The waiting turns aren't empty: a refresh fast still lets you buy, sell, upgrade, place and play from the shop you have, and a buy fast still lets you sell, upgrade, and play cards from hand. The Feasts are action-rich: the Lenten Heron turns two turns without refreshing into a long free reroll turn, and the Olm turns three turns of saved gold into a cut-price shopping spree. It works with other waiting cards: Rehearse units grow in hand and Cold Store cards ripen while you fast.
- **Why run it.** It turns patience into one planned spike turn, timed for when you need it.
- **Scene.** Turn 6, you buy Olm Sleeper. Turns 7 to 9 you buy nothing: you upgrade to tier 5, sell two weak units, and play the Rehearse toads you held, while your gold piles up to 22. End of turn 9 the count reaches 3: Feast. Turn 10 you start with 32 gold and every shop unit costs 2. You buy eleven units across your refreshes, finish two triples and rebuild the board in one turn. Turns 7 to 9 you fought with a thin board and lost some health; that was the price.
- **Good against.** Boards that peak in the mid game, which your Feast turn outgrows. **Weak against.** Tempo boards and Wager players who punish your waiting turns.
- **Variations.**
  - **Streak (the original Fast).** "End of Turn: if you didn't refresh this turn, this gains +1/+1 permanently, and +1 more for each turn in a row." The isolated form: you still buy and sell, but it rewards the same skip every turn.
  - **Vigil (N).** "If this doesn't move for 3 turns, it gains +6/+6 permanently and Vigil starts again." The owner's "Don't move for 3 turns, then X" on a single unit; it also fits the Greenwood's Rooted.
  - **Lent.** "When you play this, choose refresh, buy or sell. For the next 3 turns you can't do it. Then get a Feast for that action." The decision moves to the start: which action you give up.
- **Similar to.** Magic: The Gathering's Suspend (wait a set number of turns for a big payoff); Hearthstone's Quests turned around (don't do X for N turns instead of doing X N times).
- **Owner's direction.** "Nah, Fast is boring. It rewards you for not playing the game ... Being rewarded for not making choices is not fun" (02h). "Fast isn't cut ... Fast might be a dead end, but we should still explore it" (02i). On the principle: "'Don't move for 3 turns, then X': that's cool. 'Don't move to get stats every single turn': not so cool" (02i; pillar 13).
- **Designer's response.** Followed the direction. The main rule is now time-bound: a count to N, then a Feast, then it starts again. Break Fast adds a choice on each waiting turn: cash in early for half, or hold on. I also push back a little, with an example. What Fast teaches is that with no timer and uncapped gold, not doing an action is saving for it. So the Feast should be a big turn of that same action (8 free refreshes, units at 2 gold), not stats for doing nothing. The Olm scene shows the waiting turns still have decisions: what to sell, when to upgrade, what to play from hand. The original per-turn streak is kept only as a variation, in its most isolated form (refresh), since pillar 13 calls that one a delicate balance.
- **Open.** Does a Feast of free refreshes need a cap beyond N turns of waiting, given the guardrail on unpaid refreshes (G1)?
- **Open.** Two Fast units with different actions can lock you out of most of the shop. Allowed as a player's choice, or one Fast count per player?
- **Open.** Should the count reset on selling at all, or only on the action named?
- **Rules review (needs a ruling).** Works: only paid actions count, so free refreshes in a Feast don't reset the count. G1: the Lenten Heron's 8 free refreshes can't chain (free refreshes give no new count), so it passes as bounded, but Pair and golden double it to 16, so it belongs on the retrigger review list (R11). Needs rulings: Break Fast at count 0 should give nothing, and two Fast units with different actions need the owner's call.
- **Budget review.** With the count resetting after each Feast, Fast is a timed reward, not a runaway; the Tier-2 stat Feast is still too big.
  - *Still-Water Heron*: flag over. Feast +4/+4 every 2 turns without a paid refresh, common early (≈ 0.55 of the time): s ≈ 2.2, over the Tier-2 cap of 1.3; 3.7 × 2.2 ≈ 8.1 − refreshes given up ≈ 0.7 + body 5 [guess] ≈ 12.4 vs V(2) 7: +77%, ±25%. The count now resets after each Feast, so the old quadratic growth is gone. Priced with Break Fast needing a count of 1 or more; at 0 it would be +2/+2 every turn Change: Feast +2/+2 on 2/2 (≈ 7.4, +6%); Break Fast then gives +1/+1.
  - *Lenten Heron*: in band. 8 free refreshes after 2 turns without refreshing; about 4 are useful on a normal turn (E52: 4 × 1.1 ≈ 4.4 a Feast, ≈ 0.67 gold-equivalent a turn ≈ 2.8) + body 8 [guess] ≈ 10.8 vs V(4) 10: +8%, ±25%. For information: 8 in one turn is a banked-turn case for the deferred turn-length check
  - *Olm Sleeper*: in band. body 10 + a Feast turn of 2-gold units every 4 turns (≈ 6 gold saved on a banked turn ≈ +1.5 gold a turn ≈ 6) − 3 turns without buying units (≈ −4) [guess] ≈ 12 vs V(5) 12: 0%, ±25%; very uncertain, and 'half the Feast' has no clear meaning for a price change
- **From.** recruit 10.

### 57. Dig Down — NEW

Once a turn, a mole lets you shop among lower-tier units only, to find the copies and cheap units you still need late in the game.

- **Rules.** Dig Down: Once per turn for each unit with Dig Down, you may dig down: choose a tier lower than yours. For the rest of this turn your shop shows only units of that tier, and it refreshes now for free. Later refreshes this turn cost the normal price and also show only that tier. Your real tier doesn't change (upgrade cost and hero damage use it), but you can't upgrade while dug down. The spell card and the shop's size stay as they are. At End of Turn your shop returns to normal. Golden: twice per turn.
- **Bends.** 4.6.1 (your tier only rises) and 6.1.2 (the shop draws from your tier or lower). Late boards can fish for low-tier copies and token makers.
- **Creatures.** The Folio's mole miners' union, digging down into an old seam.. **Archetypes.** WIDE, TALL
- **Example units.**
  - *Mole Prospector*, Tier 2, 2/3, Hedgerow folk. After you buy a unit while dug down, give it +1/+1 permanently.
  - *Mole Foreman*, Tier 4, 3/5, Hedgerow folk. Dig Down.
  - *Deep-Seam Mole*, Tier 5, 4/6, Hedgerow folk. Dig Down. While you're dug down, units in your shop cost 2.
- **How they play.** At tier 5, your shop draws from tiers 1 to 5, so the one tier 1 unit you need turns up rarely. The Foreman lets you say "show me only tier 1" for the rest of the turn. The Prospector buffs everything you buy down there, so old units come back up stronger. The Deep-Seam Mole makes the old seam cheap, so late in the game you can fill your board with low-tier token makers at 2 gold each.
- **Why run it.** Golden low-tier units are the cheapest triples in the game, and every triple gives a Triple Reward from the tier above yours. Digging down lets a late board chase those triples on purpose.
- **Scene.** Turn 9, you're at tier 5 with two Pygmy Shrew Berserkers (tier 1) on your board. In a normal tier 5 shop a tier 1 unit is a rare sight. You dig down to tier 1 with the Mole Foreman: your shop refreshes for free, and every unit in it is now tier 1. Two paid refreshes later the third Berserker shows up. You buy it, it triples into a golden Berserker, and its Triple Reward discovers a tier 6 unit. You couldn't upgrade this turn, but you weren't going to.
- **Good against.** Late lobbies where everyone's high-tier copies are taken, and boards that need a golden to keep up. **Weak against.** Turns where you need to upgrade: a dug-down turn is a turn at your current tier.
- **Variations.**
  - **Dig Down (the original).** "Once per turn, lower your shop tier by 1 until the end of the turn and refresh for free." Smaller: it only removes your top tier from the draw, which slightly raises the odds of everything else.
  - **Old Seam.** "Dig Down to tier 1 only; units found there have +1/+1 for each tier you have above 1." Keeps tier 1 units viable late.
  - **Climb.** "Once per turn, refresh your shop for free with units of the tier above yours; you may buy at most one of them." A peek up instead of down.
- **Similar to.** Teamfight Tactics' "slow rolling": players stay at a low level so the shop keeps offering low-cost copies they need for three-stars. Also like Battlegrounds' "Discover a lower-tier unit" effects, but for a whole shop.
- **Owner's direction.** "I have no idea what Dig Down even means. I don't understand this" (02h). Direction: example cards and a play scene.
- **Designer's response.** Followed the direction: three units and a turn-9 scene that show what it's for, finishing low-tier triples late and fetching early token makers. I also changed the rule, because I think the original was hard to picture for a real reason: your shop already includes every lower tier, so lowering your tier by 1 only removes your top tier and slightly shifts the odds. The new version names the tier and shows only that tier, which is a clear, visible effect. The original stays as a variation.
- **Open.** Do several moles dig further, or does each just grant another dig?
- **Open.** Is a shop of only tier 1 units at tier 6 too reliable for triples? A cap of one dig per turn per player may be enough.
- **Rules review (clean).** Passes G1: one free refresh per dig, once per turn per unit (twice on a golden), and it can't chain. It needs the shop query to take a draw tier apart from the player's tier (shopOffer in architecture-notes.md), with 6.1.4 empty slots when that tier runs out. Pair's 'triggers twice' shouldn't double an activated ability; the play scene makes it readable.
- **Budget review.** Dig Down itself is fair; a discount or growth on every dug-down buy adds up fast without a turn timer.
  - *Mole Prospector*: flag over. body 5 + +1/+1 permanently per unit bought while dug down (≈ 1.5 buys × 0.6 a mole on board: s ≈ 1.8 once Tier-4 moles arrive; priced at turn 6, 3.1 × 1.8 ≈ 5.6) [guess] ≈ 10.6 vs V(2) 7: +51%, ±25%; ≈ 6.5 (−7%) before a mole is on board Change: Once per turn, on 2/2 (s ≈ 1.2): ≈ 7.7 (+10%).
  - *Mole Foreman*: in band. As the old review: one free refresh a turn ≈ 2.1 + low-tier access ≈ 1.3 (any lower tier now) + body 8 [guess] ≈ 11.4 vs V(4) 10: +14%, ±25%
  - *Deep-Seam Mole*: flag over. body 10 + Dig Down ≈ 2.3 + units cost 2 while dug down (≈ 2 buys × 0.6 of turns ≈ 1.2 gold a turn × 4.1 ≈ 4.9; E53) [guess] ≈ 17.2 vs V(5) 12: +43%, ±25% Change: 2/4 (≈ 13.2, +10%).
- **From.** recruit 12.

## N. Waiting off the board: hand and sleep

### 58. Hibernate (N) — VARIANT of Galaxy's Mysterious Egg and Battlegrounds' Lockbox

This unit sleeps in its slot through your next few upgrades, growing each time, then wakes up big.

- **Rules.** Hibernate (N): This sleeps through your next N upgrades. While asleep it stays in its slot, but in combat it can't attack, be attacked or be chosen by effects; it isn't anyone's neighbour; and it doesn't count as a unit for who attacks first (9.2.1), for when the fight ends (9.9.1) or for hero damage (10.1.1). Its slot still counts as full, so summons can't land there. In the Recruit Phase it can be buffed and moved as normal. Each time you upgrade, it gains +3/+3 permanently. After the Nth upgrade it wakes. A golden keeps the same N and gains +6/+6.
- **Bends.** 9.1.2 (each unit fights from its slot) and 9.2.1 (sleepers aren't counted for who attacks first). Upgrading becomes a trigger.
- **Creatures.** The dormouse sleeps over half the year; the Folio's Dormouse Clockmakers' guild hibernates by law.. **Archetypes.** TALL
- **Example units.**
  - *Clockwork Dormouse*, Tier 2, 1/1, Hedgerow folk. Hibernate (2).
  - *Fat Dormouse*, Tier 3, 3/3, Hedgerow folk. Hibernate (1). While this is asleep, your upgrades cost 1 less.
  - *Dormouse Clockmaker*, Tier 4, 2/5, Hedgerow folk. After a friendly unit wakes from Hibernate, give its adjacent units +2/+2 permanently.
- **How they play.** The Clockwork Dormouse is a 1/1 that becomes a 7/7 after two upgrades. The Fat Dormouse pays for itself by making the upgrades that wake it cheaper. The Clockmaker turns each waking into a buff for the units beside it, so you plan where the sleeper lies.
- **Why run it.** Cheap, sure growth you can see coming, tied to something you were going to do anyway: upgrading.
- **Scene.** Turn 2, you buy Clockwork Dormouse and put it in B3. For a few fights your board fights a body short. Turn 3 you upgrade to tier 3: it is 4/4. Turn 5 you upgrade to tier 4: it is 7/7 and wakes. You had put the Dormouse Clockmaker next to it, in B2, so the waking gives the Clockmaker +2/+2 as well.
- **Good against.** Opponents who can't punish a body-short board in the early game. **Weak against.** Tempo boards on turns 2 to 5, and slow upgraders: no upgrade, no growth.
- **Variations.**
  - **Hibernate (turns).** "This sleeps for your next 3 turns, gaining +2/+2 at the start of each." Counts turns, not upgrades.
  - **Torpor.** "This sleeps until you lose a fight. Then it wakes with +2/+2 for each turn it slept." A comeback card.
  - **Light Sleeper.** "Hibernate (2). If your front row is empty in combat, this wakes for that fight."
- **Similar to.** Galaxy's Mysterious Egg and Battlegrounds' Lockbox: delayed payoffs that take a slot.
- **Open.** A Hibernate (3) bought at tier 5 can never wake (only one upgrade left). Should it wake at tier 6 regardless?
- **Open.** Do upgrades past tier 6 (to tier 7 by effect) count?
- **Rules review (needs a ruling).** Its occupant rules are stated, but they leave out back-row protection (9.5.1): a sleeper in the front row 'can't be attacked', so either it counts as a front-row unit and a lone sleeper in F1 makes your whole back row unattackable, or 9.5.3 turns it back into a candidate. Proposed: a sleeper doesn't count for 9.5.1, as with Play Dead (R7). Upgrades by effect to tier 7 should count; a Hibernate (3) bought at tier 5 never waking is a design choice.
- **Budget review.** Sleeping units pay for their missing fights about right; a gold discount on the same upgrade tips the Tier-3 one over.
  - *Clockwork Dormouse*: edge. asleep ≈ 4 fights, then 7/7 from about turn 6; time-averaged over turns 2–12 ≈ 8.9 vs V(2) 7: +27% (old review: +20%), ±25% (E02 on proposed R34, E96) [guess] Change: None yet; check in the sim. Bought with fewer than 2 upgrades left it never wakes, as intended.
  - *Fat Dormouse*: flag over. asleep ≈ 2 fights, then 6/6 from about turn 6: time-averaged ≈ 9 (+12%) + 'upgrades cost 1 less' on the upgrade it sleeps through (one-off gold at Tier 3 ≈ 4.5) [guess] ≈ 13.5 vs V(3) 8: +69%, ±25% Change: Tier 4, same text: one-off gold is cheaper there (2.2) and it wakes about turn 8: ≈ 10.2 (+2%).
  - *Dormouse Clockmaker*: in band. body 7 + +2/+2 permanently to ≈ 1.43 neighbours per wake (≈ 5.1 a wake × ≈ 1.5 wakes after turn 6 × 0.6 Hibernate build ≈ 4.6, one-off) [guess] ≈ 11.6 vs V(4) 10: +16%, ±25%
- **From.** recruit 11 (marked variant by the designer). Creatures-first used the same name for in-hand growth, merged into Rehearse (59).

### 59. Rehearse — VARIANT of Battlegrounds' hand-buff cards (merged with creatures' Hibernate)

Keep this card in your hand and it grows each turn, faster with another Rehearse card beside it; play it when the show is ready.

- **Rules.** Rehearse: At End of Turn, if this is in your hand, it gains +1/+1 permanently, or +2/+2 if another card with Rehearse is in your hand too. Once played, it stops growing. End of Turn effects resolve on the board in reading order first, then in your hand from left to right.
- **Bends.** 3.4.2 (cards in hand do nothing) and 7.1: the hand becomes a growth space that competes with board slots.
- **Creatures.** The Folio's Frog Chorus and fox travelling theatre, rehearsing offstage; dormice sleeping through half the year, with the hand as a den.. **Archetypes.** MEDIUM, TALL
- **Example units.**
  - *Den Dormouse*, Tier 2, 1/1, Hedgerow folk. Rehearse.
  - *Understudy Toad*, Tier 3, 2/2, Bog folk. Rehearse. When you play this, give your other Bog folk +1/+1 permanently for each turn it rehearsed (up to 4).
  - *Old Sleeper*, Tier 5, 4/4, Hedgerow folk. Rehearse. When you play this, give its adjacent units the stats it gained in hand as well.
- **How they play.** Two Rehearse cards in hand each grow +2/+2 a turn, so they want company. The Understudy Toad's opening night buffs your whole chorus, scaled by how long it waited. The Old Sleeper copies its growth onto the units beside it, so where you play it matters.
- **Why run it.** Growth with a visible cost: hand slots and units not on the board. It fits waiting plans like Fast and gives a thin board a planned big turn.
- **Scene.** Turn 4, you buy two Understudy Toads and keep them in hand. At End of Turn on turns 4, 5 and 6 each gains +2/+2. Turn 7, opening night: you play the first (8/8) and it gives your other Bog folk +3/+3; you play the second, and it gives the first toad and the rest +3/+3 again.
- **Good against.** Slow lobbies, where a few thin fights cost little. **Weak against.** Tempo boards on the turns you hold cards back.
- **Variations.**
  - **Understudy (capped).** "Rehearse, up to +5/+5." A version with a ceiling.
  - **Curtain Call.** "Rehearse. When you play this after 3 or more turns in hand, get a Created copy of it."
  - **Dress Rehearsal.** "While this is in your hand, at End of Turn it gains +1/+1 for each unit you played this turn." Grows from your actions, not from waiting.
- **Similar to.** Battlegrounds' Bream Counter and Futurefin, which grow cards in hand; Rehearse grows on its own each turn.
- **Open.** Name clash: the old Hazel Dormouse was also Bide's Slumber example, so it is renamed Den Dormouse here.
- **Open.** Unbounded but linear growth: does it need a cap, given the 10-card hand?
- **Rules review (clean).** Works as an End of Turn trigger from hand, with board-then-hand order stated. The rulebook has no hand order yet, and Offstage needs it too: add one ('cards in hand keep the order they arrived in, left to right'). Readable.
- **Budget review.** Growth in hand is cheaper than growth on the board, but payoffs that multiply it by turns rehearsed run over.
  - *Den Dormouse*: in band. body 2 + +1/+1 a turn in hand, +2/+2 with another Rehearse card (≈ 0.3): s ≈ 2.6 × 0.6 for growth that isn't fighting: 3.7 × 2.6 × 0.6 ≈ 5.8 (E17, E02) [guess] ≈ 7.8 vs V(2) 7: +11%, ±25%. The old review: in band if held up to about 4 turns
  - *Understudy Toad*: flag over. Same as the old review: in-hand growth ≈ 4.2 + +1/+1 to other Bog folk per turn rehearsed, up to 4 (≈ 8.6) + body 4 ≈ 16.8 vs V(3) 8: +110%, ±25% Change: 1/1, payoff '+1 Attack to your other Bog folk for each turn it rehearsed (up to 3)': ≈ 9.4 (+18%).
  - *Old Sleeper*: edge. Same as the old review: ≈ 15.6 vs V(5) 12: +30%, ±25%; more when the pair doubling applies Change: If the sim agrees, 3/3 (≈ 13.6, +13%).
- **From.** recruit 13 (marked variant by the designer), creatures 12.

### 60. Fly South — NEW

Send this bird away for two turns; it comes back stronger and brings you a free unit.

- **Rules.** Fly South: At End of Turn you may send this away. It leaves the board, and its slot is empty. While away it isn't on your board or in your hand: it doesn't fight, doesn't count for triples or hero damage, and its pool copy stays out of the pool. At the start of your turn after next, after your gold is set, it returns to its slot, or the nearest empty one (8.4.2), with +2/+2 permanently and a bundle: a Created random unit of your tier added to your hand. If your board is full, it returns to your hand instead. Golden: two bundles.
- **Bends.** 3.4.2 and 8.3. A unit is normally on the board or in hand; a migrant is neither for two turns, and it frees a slot without selling.
- **Creatures.** The Folio's Stork Post: storks bring the babies and are mysteriously absent every winter.. **Archetypes.** ECO, WIDE
- **Example units.**
  - *Swallow*, Tier 1, 2/1, Birds. Fly South.
  - *Stork Courier*, Tier 3, 3/3, Birds. Fly South.
  - *Stork Postmaster*, Tier 5, 4/5, Birds. When a unit returns from flying south, give it and its bundle +2/+2 permanently.
- **How they play.** Sending a bird away frees its slot, so you can try a new unit there for two turns; when the bird comes back it takes the nearest empty slot. Each return brings a Created unit of your tier, which sells for 0 but fills the board. The Postmaster makes each return a bigger delivery.
- **Why run it.** A free unit of your tier every two turns per bird, paid for with two fights a body short.
- **Scene.** Turn 7, you're healthy and the next two fights matter less. At End of Turn you send two Stork Couriers away and fight with five units. You use the free slots to test a new unit. Turn 9 the storks return with +2/+2 each and two Created tier 4 units in your hand; with the Postmaster, all four have +2/+2 more.
- **Good against.** Lobbies where you can afford to lose a fight or two to build up. **Weak against.** Tempo boards, and the turns you are low on health.
- **Variations.**
  - **Long Haul.** "Fly South: choose how many turns it's away (1 to 3). It returns with +2/+2 and one bundle for each turn."
  - **Escort.** "End of Turn: you may send away the unit in front of this with it. Both return together."
  - **Winter Visitor.** "Start of your turn: if you have an empty slot, a Created copy of a random Bird from the pool flies in for this turn and the next fight."
- **Similar to.** Magic: The Gathering's phasing and 'exile, then return' effects; Battlegrounds' Free Travel Winner, which leaves for a reward but doesn't return.
- **Open.** Renamed from Migrate because rows' Migrate (42) is a different mechanic.
- **Open.** Does an away unit return to the pool if you are eliminated (5.3.8)? Proposed: yes.
- **Open.** A bundle into a full hand is lost (7.1.2). Should it wait instead?
- **Rules review (needs a ruling).** Works as an 'away' zone (R7) with the return after gold is set. Needs rulings: is the return a summon (Delivery, Mark, Bury read summons), is the bundle drawn from the pool (4.3.2 then makes it Created and a pool copy), and what happens when it returns to a full hand (7.1.2 loses it). Pool copies of an away unit should return on elimination (5.3.8), as proposed.
- **Budget review.** A free unit card plus +2/+2 more than pays for two missed fights, so Fly South carriers want smaller bodies.
  - *Swallow*: flag over. misses 2 fights, returns as 4/3 for fights 3–6 (time-averaged body ≈ 4.7) + a Created random unit of your tier (E41: 0.55 × V(2) ≈ 3.9) [guess] ≈ 8.6 vs V(1) 5: +72%, ±25% Change: Tier 2 at 1/1 (≈ 8.7 vs V(2) 7, +24%).
  - *Stork Courier*: flag over. misses fights 4–5, returns as 5/5 for fights to about turn 9 (time-averaged ≈ 6.7) + a random unit of your tier (0.45 × V(3–4) ≈ 4; E41, E96) [guess] ≈ 10.7 vs V(3) 8: +34%, ±25%. The old review put it in band; it didn't count the bundle at full value Change: 2/2 (≈ 9.3, +16%).
  - *Stork Postmaster*: edge. body 9 + +2/+2 permanently to the returner and its bundle (≈ 0.3 returns a turn × 8 × 0.9: s ≈ 2.2, under the cap; 2.6 × 2.2 ≈ 5.6) [guess] ≈ 14.6 vs V(5) 12: +22%, ±25% Change: If the sim agrees, 4/4 (≈ 13.6, +13%).
- **From.** recruit 18.

## O. Copies, triples, spells and the pool

### 61. Mimic — VARIANT of Galaxy's Mirror Mirror and Battlegrounds' Karmic Chameleon

Each turn this becomes a copy of the enemy unit that faced it in your last fight.

- **Rules.** Mimic: At the start of your turn, this becomes a copy of the enemy unit that was across from it (8.2.6) when your last fight began, before Start of Combat effects. It takes that unit's base stats and text, not golden, and keeps Mimic, its own permanent buffs and its own origin (4.3.6). For triples it counts as a copy of the unit it copied. If no unit was across from it, it stays as it is.
- **Bends.** 4.3.1 and 5.3.6: units come from the pool or your own effects; Mimic takes one from another player's board.
- **Creatures.** The jay imitates the calls of other birds; a Folio noisy sentinel.. **Archetypes.** TALL
- **Example units.**
  - *Starling Echo*, Tier 2, 1/2, Birds. Mimic. After this copies a unit, it loses Mimic.
  - *Jay Sentinel*, Tier 3, 3/3, Birds. After one of your units copies a unit with Mimic, give it +1/+1 permanently.
  - *Mocking Jay*, Tier 4, 2/2, Birds. Mimic. Has +2/+2.
- **How they play.** The Starling copies once and keeps it, so a cheap card can land a higher-tier unit early. The Mocking Jay keeps copying every turn, and the Sentinel makes each copy grow. You aim it by where you place it before the fight, guessing where the enemy's best unit will stand. Since it counts as the copied unit, it can be the third copy of a unit you saw your opponent run.
- **Why run it.** It borrows your opponent's best units, and it can finish a triple from a unit you don't have.
- **Scene.** Turn 6, your opponent's best unit is a tier 5 Badger in F2, as it was last fight. You place Mocking Jay in F2. Turn 7 the jay is a Badger with +2/+2 and its buffs from the Sentinel. You already hold two Badgers, so it triples at once.
- **Good against.** Boards with one big carry in a predictable slot. **Weak against.** Wide token boards and gaps: it copies a 1/1, or nothing.
- **Variations.**
  - **Echo.** "Mimic, but only for the next fight; then it turns back."
  - **Borrowed Song.** "At the start of your turn, copy the text (not the stats) of the enemy unit across from this in your last fight." Closer to Mirror Mirror.
  - **Changeling's Mimic.** "At the start of your turn, become a copy of the friendly unit behind this." Friendly and aimable, as in the Fairies' Changeling idea.
- **Similar to.** Galaxy's Mirror Mirror; Battlegrounds' Karmic Chameleon; Magic: The Gathering's Clone.
- **Open.** Origin: the entry said the copy is Created, but 4.3.6 keeps origin through a transform. Proposed here: it keeps its own origin.
- **Open.** Async: the copied unit may come from a tribe outside your lobby (5.1.3, 2.1.5). Allowed?
- **Open.** Name clash: Galaxy has a card called Mimic.
- **Rules review (needs a ruling).** Works as a start-of-turn transform that keeps its own origin (4.3.6). Needs a pool ruling: a Bought Starling that became a copy of a tier 5 unit would return a copy of that unit to the pool when sold, a copy the pool never lost (5.3.4), so say it returns its original card's copy. The copied unit may come from a tribe outside your lobby (5.1.3) in async play; the name clashes with Galaxy's Mimic.
- **Budget review.** Mimic is worth whatever stands across, so it is weak early and strong late at every tier; price it by when it is bought.
  - *Starling Echo*: flag under. body 3, then one copy at turn 3 of a ≈ 6-SP enemy unit if the slot was filled (≈ 0.55): time-averaged over turns 2–6 ≈ 4.3 + triple help ≈ 0.2 (E31) [guess] ≈ 4.5 vs V(2) 7: −36%, ±25%. Bought late, it copies a much bigger unit Change: Tier 1, same text (≈ 4.5 vs V(1) 5, −10%); sim late buys, when it copies a Tier-4–5 unit.
  - *Jay Sentinel*: edge. body 6 + +1/+1 permanently per copy (≈ 1 a turn × 0.6 a Mimic on board: s ≈ 1.2; 3.5 × 1.2 ≈ 4.2) [guess] ≈ 10.2 vs V(3) 8: +28%, ±25% Change: If the sim agrees, 2/3 (≈ 9.2, +15%).
  - *Mocking Jay*: flag over. Same as the old review: base copy of the unit across + its own +2/+2 × 0.9 ≈ 11.7 at turn 6 (+17%), ≈ 15.3 late (+53%), ±25% Change: Drop 'Has +2/+2' (≈ 8.1 at turn 6, ≈ 11.7 late), or keep it and move it to Tier 5.
- **From.** recruit 5 (marked variant by the designer).

### 62. Foundling — VARIANT of Battlegrounds' Elemental of Surprise and Zilliax modules

A fairy child that counts as a copy of any unit for a triple, and makes the golden a Fairy too.

- **Rules.** Foundling: In your hand or on your board, this counts as a copy of any non-golden unit for a triple. A triple that needs a Foundling forms only when you choose, at any time in the Recruit Phase. When it completes one, the golden also gains the Fairy type. If it could complete two triples, you choose. Two Foundlings and one other unit make that unit golden; three Foundlings make a golden Foundling.
- **Bends.** 7.3.1 (a triple needs three copies of the same unit, and forms at once).
- **Creatures.** The folklore changeling: a fairy child left in a cradle in place of a human one.. **Archetypes.** MEDIUM
- **Example units.**
  - *Swapped Babe*, Tier 1, 1/1, Fairies. Foundling. Only for a triple of a tier 1 or 2 unit.
  - *Cradle Changeling*, Tier 3, 2/2, Fairies. Foundling.
  - *Fairy Ring Keeper*, Tier 4, 3/4, Fairies. Start of Combat: give your other Fairies +2/+2 this combat.
- **How they play.** Any pair becomes a golden as soon as a Changeling turns up. The golden is then also a Fairy, so Fairy payoffs like the Ring Keeper reach into other tribes. The Swapped Babe is the cheap early version for low-tier pairs.
- **Why run it.** Goldens a turn or two early, and the Triple Reward that comes with each.
- **Scene.** Turn 5, you hold two tier 3 Badgers. Cradle Changeling shows up: you buy it and choose to triple. Your golden Badger is now also a Fairy. You play it, and the Triple Reward discovers a tier 5 unit. Next fight your Fairy Ring Keeper gives the golden Badger +2/+2.
- **Good against.** Slow lobbies where triples decide the mid game. **Weak against.** Tempo: a Foundling with no pair is a 2/2 for 3.
- **Variations.**
  - **True Changeling.** "Foundling, but the golden loses its other types and is only a Fairy."
  - **Stray.** "Counts as a copy of an adjacent unit only." Positional and easier to read.
  - **Fairy Gift.** "Foundling. After it completes a triple, the golden also gets: Start of Combat: give a random friendly Fairy +2/+2."
- **Similar to.** Battlegrounds' Elemental of Surprise and Zilliax modules; a joker or wild card.
- **Open.** A golden made with a Foundling sells for 1 (4.3.4). Does it return the Foundling's pool copy when sold (5.3.5)?
- **Rules review (clean).** Works as a wild card for 7.3.1, with chosen timing and a choice between two triples stated. When the golden is sold, 5.3.5 returns the Foundling's own copy as a Foundling, which answers the designer's question. Readable.
- **Budget review.** Foundlings price like a saved buy and are in band; the Keeper is a standard tribe buffer on a full body.
  - *Swapped Babe*: in band. body 2 + saves about one buy when you hold a Tier-1–2 pair (E44 ≈ 4.3 × 0.5) + Fairy type ≈ 0.3 (E85) [guess] ≈ 4.5 vs V(1) 5: −10%, ±25%
  - *Cradle Changeling*: in band. Same as the old review: body 4 + a saved buy (≈ 4 × 0.6) + Fairy type ≈ 0.3 ≈ 6.7 vs V(3) 8: −16%, ±25%
  - *Fairy Ring Keeper*: flag over. body 7 + Start of Combat +2/+2 to other Fairies (≈ 1.5 Fairies at the tribe rate × 4 SP × 0.9 ≈ 5.4; E01, T08) [guess] ≈ 12.4 vs V(4) 10: +24%, ±15% Change: 2/3 (≈ 10.4, +4%).
- **From.** recruit 14.

### 63. Pair — VARIANT of Battlegrounds' First Mate Pip and the False Idols anomaly

Two copies of a swan bond into one stronger unit whose effects fire twice, and a third copy still makes it golden.

- **Rules.** Pair: When you have two non-golden copies of the same Pair unit across board and hand, they bond at once into one Bonded unit with both copies' stats and buffs added together. It takes the board copy's slot, or goes to hand if neither was on the board. A Bonded unit's effects trigger twice. It isn't golden and gives no Triple Reward. It counts as two copies for a triple: a third copy makes it golden as normal, with the higher of the Bonded stats and the golden stats, triggering once with doubled numbers, and gives the Triple Reward. If three copies arrive together, they triple.
- **Bends.** 7.3.1 (three copies), 7.3.5 (golden doubles numbers) and 7.3.6 (Triple Reward).
- **Creatures.** Swans pair for life; the Children of Lir and Six Swans tales.. **Archetypes.** TALL, STICKY
- **Example units.**
  - *Bewick's Swan*, Tier 1, 2/2, Birds. Pair.
  - *Mute Swan Paladin*, Tier 2, 2/4, Birds. Pair. Start of Combat: give the units in front of this +1 Health this combat.
  - *Swan Maiden*, Tier 4, 3/5, Birds. Pair. End of Turn: give the units in front of this +1/+1 permanently.
- **How they play.** Bewick's Swan is a plain early 4/4 from two copies. The Paladin and the Maiden sit in the back row and work on the units in front of them; Bonded, they work twice. A Bonded Maiden is a fast scaler for the two front units it backs.
- **Why run it.** A halfway step to golden: a big unit with doubled effects from only two copies.
- **Scene.** Turn 2, you buy two Mute Swan Paladins: they bond into a 4/8 in B2 whose Start of Combat fires twice, so F2 and F3 get +2 Health each fight. Turn 6 the third swan appears: golden, Triple Reward.
- **Good against.** Early boards: a 4/8 on turn 2 is hard to break. **Weak against.** Wide boards: one big unit is one body.
- **Variations.**
  - **Side by Side.** "Pair: while this is adjacent to a copy of itself, its effects trigger twice." No merge, two bodies, for WIDE.
  - **Mated for Life.** "Pair. When the Bonded unit dies, summon both halves as 2/2s."
- **Similar to.** Battlegrounds' First Mate Pip, the Designer Eyepatch trinket and the False Idols anomaly, which make goldens from two copies.
- **Open.** "Triggers twice" is a retrigger: any free-refresh or gold effect on a Pair unit doubles. Should Pair be kept off those effects?
- **Open.** Does the golden keep firing twice? Proposed: no; it uses doubled numbers instead.
- **Rules review (needs a ruling).** Works as a two-copy merge that counts as two for a triple. Needs rulings: bonding happens only in the Recruit Phase, like triples (7.3.2); the Bonded unit's sell value and pool return (4.3.5 makes it Bought if either copy was; return one copy per pool copy, as 5.3.5); and 'triggers twice' doubles only triggered effects, not activated ones. It is a retrigger source, so it belongs on G1's review list (R11).
- **Budget review.** Pair prices fine; the Maiden is the budget's own failing example, and its passing twin is the fix.
  - *Bewick's Swan*: in band. body 4 + a second copy bonds into a 4/4 that saves a slot (≈ 1 × 0.4; E23) ≈ 4.4 vs V(1) 5: −12%; bonded ≈ 9 vs two cards' 10 (−10%), ±15%
  - *Mute Swan Paladin*: in band. Same as the old review: single ≈ 7.3 (+4%), bonded ≈ 15.6 vs 14 (+11%), ±15%. The new rule (golden takes the higher stats) removes the old four-times-body worry
  - *Swan Maiden*: flag over. back-bound: 2.25 + 5 = 7.25 + 'End of Turn: +1/+1 to the units in front' (power-budget example #7a: s ≈ 3.8, over the Tier-4 cap; 3.1 × 3.8 ≈ 11.8) ≈ 19 vs V(4) 10: +90%, ±25%; bonded it fires twice Change: Power-budget example #7b: 1/3, 'give the units in front of this +1 Health permanently' (≈ 9.65, −4%); bonded ≈ 18.3 vs two cards' 20.
- **From.** recruit 15.

### 64. Brew — NEW

With a brewer on your board, two copies of the same spell in your hand mix into one stronger spell.

- **Rules.** Brew: While a unit with Brew is on your board, two copies of the same Tavern spell in your hand combine at once into one Strong copy: double its numbers, same cost. A Strong spell can't brew again. One of the two copies returns to the spell pool.
- **Bends.** 6.1.5 (spells can't triple) and the spell pool counts in 5.1.2.
- **Creatures.** The Folio's toadstone apothecaries: witch-healers with jewels in their heads.. **Archetypes.** MEDIUM
- **Example units.**
  - *Herb-Wife Newt*, Tier 1, 1/3, Bog folk. Brew.
  - *Toadstone Apothecary*, Tier 3, 2/4, Bog folk. Brew. After you cast a Strong spell, this gains +2/+2 permanently.
  - *Cauldron Toad*, Tier 5, 4/6, Bog folk. Brew. After you refresh, if you have a Tavern spell in hand, the shop's spell card is a copy of it.
- **How they play.** The Newt turns on brewing from tier 1. The Apothecary grows each time you cast a Strong spell. The Cauldron Toad makes brewing reliable: hold one spell, refresh, and the shop offers its twin.
- **Why run it.** Fewer, stronger spell turns, and the Apothecary as a payoff.
- **Scene.** Turn 4, you buy a buff spell and keep it. Next turn the shop shows the same spell; you buy it and the two brew into a Strong copy. You cast it: double the buff, and the Apothecary gains +2/+2.
- **Good against.** Boards that win on a key turn: a Strong spell spikes harder. **Weak against.** Luck: without the Cauldron Toad, two copies of one spell is rare.
- **Variations.**
  - **Brew (any pair).** "Two spells of the same tier combine into a random Strong spell of that tier."
  - **Simmer.** "While this is on your board, a spell in your hand at End of Turn gains +1 to its numbers."
- **Similar to.** Battlegrounds' Balinda Stonehearth, which casts spells twice; merge games.
- **Open.** A Strong spell that gives gold or free refreshes doubles them. Should Brew double only stat spells?
- **Open.** Can you keep two plain copies apart if you want to cast both? Proposed: no, they combine at once.
- **Rules review (needs a ruling).** Works as a spell merge with one copy returned to the spell pool. Needs a ruling on the Cauldron Toad's copy: drawn from the spell pool (5.1.2) or created outside it; proposed from the pool, empty if none left. A Strong spell doubles gold or free refreshes, so Brew belongs on G1's doubling list (R11); readable.
- **Budget review.** Brew adds no stats, so its cards are bodies plus payoffs; the Cauldron Toad's spell copying is the one to watch for loops.
  - *Herb-Wife Newt*: in band. body 4 + merging two bought spells moves no stats (one fewer cast, one hand slot freed ≈ 0.2) [guess] ≈ 4.2 vs V(1) 5: −16%, inside the ±1 SP floor
  - *Toadstone Apothecary*: edge. Same as the old review: body 6 + +2/+2 per Strong cast (≈ 0.3 a turn: s ≈ 1.2; 3.5 × 1.2 ≈ 4.2) ≈ 10.2 vs V(3) 8: +28%, ±25% Change: If the sim agrees, 2/3 (≈ 9.2, +15%).
  - *Cauldron Toad*: in band. body 10 + Brew ≈ 0.2 + every refresh offers a copy of the spell in hand (spell shop control, E60: the best-rate spell every time ≈ 3.5) [guess] ≈ 13.7 vs V(5) 12: +14%, ±25%. For information: with a free-refresh spell, each refresh offers it again; the proposed guardrails G5 and G12 (not approved) cover that
- **From.** recruit 16.

### 65. Endangered — NEW

This gets stronger for every copy of it that's out of the pool, so others buying it helps you.

- **Rules.** Endangered: At Start of Combat, this has +1/+1 for each copy of it that isn't in the pool: on any board, in any hand or in any shop, its own copy included. In async play, the count uses your game's pool.
- **Bends.** 5.1.2 and 5.3: the pool's copy counts become a stat.
- **Creatures.** The capercaillie, a forest grouse in decline; the bison, saved from extinction.. **Archetypes.** TALL
- **Example units.**
  - *Corncrake*, Tier 2, 2/2, Birds. Endangered.
  - *Grouse Lek*, Tier 4, 2/6, Birds. Your Endangered units also count copies of your other Endangered units.
  - *Last Capercaillie*, Tier 5, 4/4, Birds. Endangered. With all 9 tier 5 copies out of the pool it is 13/13.
- **How they play.** Each Endangered unit counts its own copies, and the Grouse Lek adds your other Endangered units' copies. Cold Store and Pawn keep copies out of the pool, so they raise the count too.
- **Why run it.** A real dilemma for opponents: buying a copy to deny you feeds yours, and leaving them lets you triple.
- **Scene.** Turn 9, two other players hold Capercaillies, and one is in your shop. You buy it: your Capercaillie counts 4 copies out and is 8/8 in the fight. Next turn you put a third in Cold Store, and it counts 5.
- **Good against.** Lobbies that hate-buy or share your tribe. **Weak against.** Quiet lobbies where nobody else touches the unit.
- **Variations.**
  - **Thriving.** "+1/+1 for each copy still in the pool." Strong early, weaker as copies leave.
  - **Last of Its Kind.** "If this is the only copy out of the pool, it has +5/+5."
- **Similar to.** Magic: The Gathering's Relentless Rats, which count copies of themselves, turned to count the pool.
- **Open.** It tells you how many copies rivals hold. Is that information fine to show?
- **Open.** Async: whose pool, and can it read other players' live shops (2.1.5)?
- **Rules review (needs a ruling).** Needs a ruling on what it counts: the Capercaillie's example (13/13 with all 9 tier 5 copies out) means pool copies missing from the pool, so Created copies (Ice-Cellar Stoat) shouldn't count. Async play: 'your game's pool' depends on 2.1.5, which is open. It shows how many copies rivals hold, an information question for the owner.
- **Budget review.** Every Endangered price depends on how many copies leave the pool, which the async model (rulebook 2.1.5) hasn't settled.
  - *Corncrake*: flag over. body 4 + +1/+1 per copy out of the pool (≈ 3 mid-game: yours, other boards and shops) ≈ 6 (E09) [guess] ≈ 10 vs V(2) 7: +43%, ±25%; if async counts only your own game, ≈ 6.4 (−9%) Change: 1/1 (≈ 8, +14%).
  - *Grouse Lek*: flag over. body 8 + your Endangered units also count each other's copies (≈ +3/+3 on ≈ 1.5 Endangered units × 0.6 ≈ 5.4) [guess] ≈ 13.4 vs V(4) 10: +34%, ±25% Change: 2/4 (≈ 11.4, +14%).
  - *Last Capercaillie*: edge. Same as the old review: +3/+3 to +4/+4 ≈ 14–16 vs V(5) 12: +17% to +33%, ±25% Change: If the sim agrees, 3/3 (≈ 12–14).
- **From.** recruit 17.

## New mechanics: C. Not attacking, and stopping attacks

### 66. Ambush — NEW

When an enemy back-row unit attacks this, this strikes first.

- **Rules.** Ambush. Whenever an enemy back-row unit attacks this, this deals damage equal to its Attack to the attacker before the damage exchange. If the attacker dies, the attack ends and this takes no damage. Against front-row attackers it fights normally.
- **Bends.** 9.6.1 step 3: the exchange is no longer simultaneous when a back-row unit attacks this.
- **Creatures.** Newts and frogs that wait in the reeds. Bog folk.. **Archetypes.** MEDIUM, SCAM
- **Example units.**
  - *Reedbed Lurker*, Tier 2, 3/3, Bog folk. Ambush.
  - *Fen Newt*, Tier 3, 2/5, Bog folk. Ambush.
  - *Bog Drummer*, Tier 5, 3/6, Bog folk. Whenever an enemy back-row unit attacks, your Bog folk gain +1 Attack this combat.
- **How they play.** Back-row units attack in every cycle once the front row has had its turn (9.4.2), and Mire makes them attack more often by skipping the front. Ambush units in your front row hit those back-row attackers first, and many back-row carries and supports have low Health. The Bog Drummer grows your board each time the enemy's back row has to come forward.
- **Why run it.** It punishes the enemy's back row for attacking, which is where their engines and carries live.
- **Scene.** Turn 5, you have Mudwallow Toad and Fen Newt in the front row. In the fight, the toad mires the enemy's front-row bear. The bear's turn passes to its B1 owl, 5/3, which attacks your Fen Newt. The newt strikes first for 2, the owl survives at 1, and in the exchange both die. Later Bog Drummer turns every such attack into Attack for your board.
- **Good against.** Boards that attack with their back row, such as Grudge rooks, Swoop birds and back-row carries. **Weak against.** Boards whose back row never attacks (0-Attack supports) and WIDE front rows.
- **Variations.**
  - **Ambush (any).** The first enemy that attacks this each combat is hit first, whatever its row.
  - **Snap.** Whenever an enemy back-row unit attacks this, deal double damage back.
  - **Reed Cover.** Enemy back-row units can't attack this while another friendly front-row unit lives.
- **Similar to.** Like first strike in Magic, but only against one kind of attacker.
- **Owner's direction.** Inspired by the owner on Mire (02h): 'you could have effects for when the enemy's backline attacks, so you have some counterattack damage or something; you could build into that.' The owner said no change was asked (02i); this is offered as a new idea, not a change to Mire.
- **Designer's response.** Pitched as its own mechanic so it can pair with Mire without changing it.
- **Open.** Does 'first' happen at 9.6.1 step 1? Then the rule 'if the defender is gone, the attack ends' needs an attacker-gone version too.
- **Rules review (needs a ruling).** Works as a pre-strike in 9.6.1 step 1, but the rulebook only says what happens when the defender is gone after step 1 or 2; it needs the matching 'attacker gone' line, shared with Both Ends and Territory. Needs an order against Quick and Hunker: proposed Ambush resolves first (it is a 'when attacked' effect), Ambush damage is effect-like and not halved by the attacker's Antlers unless the window says so. Readable; 'enemy back-row unit' should mean the attacker's slot at the moment it attacks.
- **Budget review.** Ambush only fires against back-row attackers, so it is cheap and all three units are in band.
  - *Reedbed Lurker*: in band. T2 3/3: body 6 + about 0.6 enemy back-row attacks on it x first strike (Divine Shield's 2.25 x about 0.5 chance 3 damage kills a Tier-2 back unit) = 0.7 (E90) [guess] = 6.7 vs V(2) 7: -4% (+-15%).
  - *Fen Newt*: in band. T3 2/5: body 7 + about 1.0 (as under Mire) [guess] = 8.0 vs V(3) 8: 0% (+-15%).
  - *Bog Drummer*: in band. T5 3/6: body 9 + about 2 enemy back-row attacks while it lives x +1 Attack to about 3 Bog folk x 0.6 realised = 3.6 [guess] = 12.6 vs V(5) 12: +5% (+-15%).
- **From.** new, inspired by Mire (combat 10) and the owner's 02h note

## New mechanics: A. How much damage a hit does

### 67. Scar — NEW

Every time this boar is hit and survives, it gets tougher for the rest of the fight.

- **Rules.** Scar. After this survives a hit in an attack, it gains +1/+1 this combat. Each separate hit counts, so Peck strikes each trigger it.
- **Bends.** 9.6.4 (damage just stays): surviving a hit becomes a trigger, which pays off this batch's damage reducers.
- **Creatures.** Wild boar. Old tuskers are covered in scars from fights they won. Great beasts.. **Archetypes.** STICKY, TALL
- **Example units.**
  - *Scarred Boar*, Tier 2, 2/5, Great beasts. Scar.
  - *Old Tusker*, Tier 4, 4/7, Great beasts. Scar. It gains +2/+2 instead.
  - *Sounder Matriarch*, Tier 6, 5/9, Great beasts. Scar. Whenever a friendly unit with Scar gains stats, your other Great beasts gain +1 Attack this combat.
- **How they play.** Scar wants to survive hits, so it pairs with this batch's damage reducers: a boar given Shell, standing next to a Shoulder bear, or behind a whistle survives more hits and grows from each. Enemy Peck and WIDE boards, normally good against walls, feed it with every small hit.
- **Why run it.** It turns the damage reducers into scaling, and it punishes swarms that try to chip it down.
- **Scene.** Turn 3, you buy Scarred Boar. Turn 6, Old Tusker sits in F2 at 4/12. The enemy's tokens hit it five times for 2: each hit leaves it alive and adds +2/+2, so it ends the cycle with 14 Attack and still 12 Health left. Their swarm has made your boar into their biggest problem.
- **Good against.** WIDE swarms and Peck. **Weak against.** One hit big enough to kill it outright, and SCAM kills.
- **Variations.**
  - **Battle-Scarred.** Scar, but the gains are permanent, up to +5/+5 in total per combat.
  - **Thick Skin.** After this survives a hit, its next hit taken deals 1 less damage.
  - **Old Wounds.** Scar. When this dies, give the unit behind it the stats Scar gave it.
- **Similar to.** Like Hearthstone's Enrage (stronger once damaged), but it grows with every hit instead of switching on once.
- **Designer's response.** A payoff for the batch's defensive keywords, so STICKY has something to scale with besides surviving.
- **Open.** Does a hit reduced to 0 (Shrug, Curl) count as a hit for Scar? Proposed: no.
- **Rules review (broken as written).** Broken: Sounder Matriarch's 'whenever a friendly unit with Scar gains stats, your other Great beasts gain +1 Attack' hits Scarred Boar, a Great beast with Scar, whose gain fires the Matriarch again, without end, until the 10,000-trigger tie (9.10.2). Fix: 'whenever a friendly unit gains stats from Scar'. Scar itself works: 'survives a hit' is checked after that hit's death check, a hit reduced to 0 doesn't count (R1), and the name clashes with Bloodied's Sounder Matriarch (batch 2), a different card.
- **Budget review.** Scar's growth on survived hits is worth more than it looks on tanky bodies, so all three need smaller bodies.
  - *Scarred Boar*: flag over. T2 2/5: body 7 + about 1.3 survived hits a fight (its own attacks' retaliation and attacks on it) x +1/+1 this combat x 0.6 realised = 1.6 [guess] = 8.6 vs V(2) 7: +23% (+-15%). Change: 2/4 (6 + about 1.4 = 7.4, +6%).
  - *Old Tusker*: flag over. T4 4/7: body 11 + about 1.6 survived hits x +2/+2 x 0.6 = 3.8 [guess] = 14.8 vs V(4) 10: +48% (+-15%). Change: 3/5 (8 + about 1.3 hits x 4 x 0.6 = 3.1 = 11.1, +11%).
  - *Sounder Matriarch*: flag over. T6 5/9: body 14 + own Scar about 2 hits x 2 x 0.6 = 2.4 + about 3.5 Scar gains a fight in a build x +1 Attack to about 3 other Great beasts x 0.5 = 5.2 [guess] = 21.6 vs V(6) 14: +54% (+-15%). If 'gains stats' also counts other buffs on Scar units, more. Change: 3/6 (9 + 1.8 + 5.2 = 16, +14%).
- **From.** new, inspired by Hunker, Shell, Shrug and Peck (X) in this batch

## New mechanics: G. Attack order and timing

### 68. Nightfall — NEW

An effect that fires when your second round of attacks begins, so the fight has a turning point.

- **Rules.** Nightfall: [effect]. When your side's second attack cycle begins (night falls), this effect happens. Once per combat.
- **Bends.** 9.4.5: the cycle reset becomes a trigger.
- **Creatures.** Moths, owls and other night creatures; Lights glow brighter at night.. **Archetypes.** MEDIUM, BURST
- **Example units.**
  - *Lamp Moth*, Tier 1, 1/2, Lights. Nightfall: gain +2/+2 for this combat.
  - *Marsh Light*, Tier 3, 2/4, Lights. Nightfall: deal 2 damage to each enemy back-row unit.
  - *Glow-worm Lantern*, Tier 2, 0/4, Lights. Nightfall: the units in front of this gain +2 Attack for this combat.
- **How they play.** The moths are weak in the first cycle and stronger after night falls. The Glow-worm sits in the back row and lights up the two front units in front of it. The Marsh Light hits the enemy back row just as Nocturnal owls start hunting the weakest, so it sets up their kills.
- **Why run it.** It rewards units that survive the first cycle, which pairs with protection (Shelter, Thicket) and with Nocturnal.
- **Scene.** Turn 4, you have two Lamp Moths behind a Thicket. The hedges soak the first cycle. Night falls: the moths become 3/4s and break the enemy's front row.
- **Good against.** Slow fights and boards that rely on the first cycle. **Weak against.** Fast fights that end before night falls.
- **Variations.**
  - **Dawn.** When your third cycle begins, [effect].
  - **Every Night.** At the start of each of your cycles after the first, [effect].
- **Designer's response.** A new trigger inspired by Nocturnal: the owner asked to think about all the game triggers we could use (02f), and the cycle reset is one we haven't used.
- **Open.** Does every cycle reset need to be visible in the fight presentation?
- **Rules review (clean).** Works once R4's per-side cycle counter exists: the trigger is the first cycle reset of its own side (9.4.5 step 3). A side that passes should still advance its cycle (R4), or a board of 0-Attack lanterns never reaches night. Readable if the fight shows the moment.
- **Budget review.** Nightfall is a cheap timed trigger and all three units are in band or close.
  - *Lamp Moth*: in band. T1 1/2, back: body 2.75 + '+2/+2 this combat' at night x 0.5 realised x 0.7 alive at night x 1.4 (combat buff on a back unit) = 2.0 [guess] = 4.75 vs V(1) 5: -5%.
  - *Marsh Light*: in band. T3 2/4: body 6 + 2 damage to about 2.5 enemy back units x 0.85 x 0.7 alive at night = 3.0 (E72) [guess] = 9.0 vs V(3) 8: +12.5% (+-15%).
  - *Glow-worm Lantern*: edge. T2 0/4, back: body 4 + '+2 Attack this combat' to about 1.25 surviving units in front at night x 0.8 alive = 2.0 [guess] = 6.0 vs V(2) 7: -14% (+-15%). Change: If the sim agrees: 1/4 (6.75, -4%).
- **From.** new, inspired by Nocturnal (17).

## New mechanics: F. Protection and dodging

### 69. Close Ranks — NEW

When this is attacked, the units beside it also hit back at the attacker.

- **Rules.** Close Ranks. When this is attacked, adjacent units with Close Ranks also deal their damage to the attacker at the same time. The attacker hits back only the defender.
- **Bends.** 9.6.1: the exchange is no longer one against one, on the defending side.
- **Creatures.** Red deer and bison herds that close ranks against a wolf.. **Archetypes.** MEDIUM, STICKY
- **Example units.**
  - *Roe Deer*, Tier 1, 2/2, Great beasts. Close Ranks.
  - *Red Deer Stag*, Tier 4, 4/6, Great beasts. Close Ranks. Adjacent units with Close Ranks have +1 Attack while they join this one's defence.
- **How they play.** Line up deer side by side. Each attacker takes damage from the whole line, so small attackers die on contact.
- **Why run it.** It punishes attacks into a wall of deer, and it rewards placing them next to each other.
- **Scene.** Turn 3, you have two Roe Deer in F1 and F2. An enemy 3/3 attacks one: both deer hit it for 2, and it dies.
- **Good against.** Many medium attackers. **Weak against.** Gaps in the row, splash and big single hitters.
- **Variations.**
  - **Herd Guard.** When an adjacent unit is attacked, this also deals its damage to the attacker.
  - **Square.** Close Ranks, and units in front of and behind this join too, not only adjacent ones.
- **Similar to.** The defensive mirror of Swarm.
- **Designer's response.** A defensive mirror of Swarm, which the owner liked a lot.
- **Open.** Does Close Ranks damage trigger the attacker's Bristle? Proposed: yes.
- **Rules review (clean).** Works as a defending-side joint strike in the exchange: joiners deal damage at the same time and take none back. The attacker's Bristle pricks each joiner, as proposed, and a Shell attacker hit by several joiners at once falls under Shell's simultaneous-hit ruling. Readable.
- **Budget review.** Close Ranks is cheap without partners; the Tier-4 stag is over on its body plus joint damage.
  - *Roe Deer*: in band. T1 2/2: body 4 + joint defence both ways: about 0.8 times attacked x 0.4 chance of an adjacent Close Ranks partner x 2 x 0.85, twice (it joins and is joined) = 1.1 (E90 joint attack) [guess] = 5.1 vs V(1) 5: +2%.
  - *Red Deer Stag*: flag over. T4 4/6: body 10 + partners join its defence (about 1 attack on it x 0.5 x 3 x 0.85 = 1.3) + it joins theirs (about 1 x 0.5 x 4 x 0.85 = 1.7) + '+1 Attack while joining' about 0.4 [guess] = 13.4 vs V(4) 10: +34% (+-15%). Change: 3/5 (8 + about 3.0 = 11, +10%).
- **From.** new, inspired by Swarm (25).

## New mechanics: I. Extra bodies, off-slot zones and switching sides

### 70. Gall — NEW

At the start of the fight, this lays a gall on the enemy facing it: that enemy is weaker, and when it dies a wasp hatches for you.

- **Rules.** Start of Combat: put a Gall on the enemy unit across from this, or, if that slot is empty, on a random enemy front-row unit. A galled unit has -2 Attack this combat. When it dies, summon a 2/2 Gall Wasp for you into your empty slot nearest this unit's slot (its last slot if it has died).
- **Bends.** 8.4: a death on the enemy side summons a unit on your side. Unlike Brood and Changeling, nothing stands on the enemy board, so no new ownership rule is needed.
- **Creatures.** Gall wasps lay eggs in oak buds, and the tree grows an oak apple around the larva. Inspired by Brood (34) and Changeling (33).. **Archetypes.** SCAM, WIDE
- **Example units.**
  - *Oak Gall Wasp*, Tier 2, 2/2, Hive. Gall.
  - *Oak-apple Witch*, Tier 4, 2/6, Fairies. Start of Combat: put a Gall on the two enemies with the highest Attack.
  - *Gall Tender*, Tier 5, 4/5, Hive. Your Galls give -3 Attack instead, and Gall Wasps you summon have +2/+2.
- **How they play.** Each Gall weakens one enemy and turns its death into a body for you. The Oak-apple Witch aims Galls at the biggest threats. The Gall Tender makes the debuff and the wasps bigger.
- **Why run it.** It is a debuff and a death payoff in one, and the payoff comes from the enemy's units dying, which happens every fight.
- **Scene.** Turn 6. The enemy's 10/10 stands across from your Oak-apple Witch. Start of Combat: the Witch galls it and their next-biggest unit. The 10/10 swings as an 8/10, and when your units finally kill it, a 2/2 Gall Wasp joins your side.
- **Good against.** TALL boards, where one Gall shrinks the main threat. **Weak against.** WIDE boards with many small units, where -2 Attack on one token means little.
- **Variations.**
  - **Curse.** Start of Combat: the enemy across from this has -3 Attack this combat. No wasp. The owner's 'curses that debuff enemy units' for Fairies.
  - **Gall Swarm.** As Gall, and when a Gall Wasp dies, put a Gall on a random enemy unit.
- **Owner's direction.** 02h on Fairy curses: "Maybe curses that debuff enemy units is perhaps a better outcome."
- **Designer's response.** Gall is a curse that debuffs, with a parasite payoff from Brood's idea, but it keeps everything on your own board.
- **Open.** Should Gall be Hive (wasps) or a shared keyword with Fairy curses?
- **Rules review (clean).** Works as a death effect granted to an enemy unit (9.7.2 step 2) whose summon goes to the Gall's controller, so the engine must track who controls a granted effect. Say whether two Galls on one unit stack (two wasps, -4 Attack). Readable.
- **Budget review.** One Gall per unit is in band; the Witch's double Gall puts two cards' text on one body.
  - *Oak Gall Wasp*: in band. body 4 + −2 Attack on one enemy this combat (E15 2.2 × 0.8 ≈ 1.8) + a 2/2 Wasp when that enemy dies (3.2 × 0.7 it dies × 0.85 your gap ≈ 1.9) [guess] ≈ 7.7 vs V(2) 7: +10%, ±15%
  - *Oak-apple Witch*: flag over. body 8 + Galls on the two highest-Attack enemies (−2 Attack each ≈ 4.4) + two Wasps (≈ 3.8) [guess] ≈ 16.2 vs V(4) 10: +62%, ±15% Change: 2/4, one Gall on the highest-Attack enemy: ≈ 10.1 (+1%).
  - *Gall Tender*: in band. body 9 + −1 more Attack per Gall (≈ 1.5 Galls × 1.1 × 0.6 ≈ 1.0) + Wasps +2/+2 (≈ 1 Wasp a fight × 3.2 × 0.6 ≈ 1.9) [guess] ≈ 11.9 vs V(5) 12: −1%, ±15%
- **From.** new, inspired by Brood (34) and Changeling (33).

## New mechanics: L. Gold over turns

### 71. Ripen — NEW

The longer this stays on your board, the more gold it sells for, up to 3 more.

- **Rules.** Ripen: this sells for 1 more gold for each of your turns that ended with it on your board, up to 3 more. A unit that is Ripe (3 turns) shows it on the card.
- **Bends.** 4.3.3 (sell values are fixed): sell value grows over time. It is a time-bound payoff: keep it and fight with it now, or cash it in later.
- **Creatures.** Apples and blackberries ripen on the bough; windfalls in the orchard. Inspired by Cache (47) and the owner's 'take a little now or get more later'.. **Archetypes.** ECO
- **Example units.**
  - *Crab Apple Sapling*, Tier 1, 1/3, Greenwood. Ripen.
  - *Blackberry Bramble*, Tier 2, 2/3, Greenwood. Ripen. When this becomes Ripe, give the units next to it +1/+1 permanently.
  - *Cider Badger*, Tier 4, 4/4, Hunters. Whenever you sell a Ripe unit, give your units +1/+1 permanently.
- **How they play.** Ripen units fight like normal units while they ripen, then sell for up to 4 gold. The Cider Badger turns each ripe sale into a board-wide buff, so selling them is the plan and not just cash.
- **Why run it.** It is economy tied to a decision you make every turn: keep the body, or sell it for more than usual.
- **Scene.** Turn 2. You play a Crab Apple Sapling in B1. It fights as a 1/3 wall for three turns. On Turn 5 it is Ripe and sells for 4 gold, which pays for the upgrade to Tier 4 a turn early.
- **Good against.** Long, slow games where early units would otherwise be sold for 1. **Weak against.** Fast lobbies where you need every slot for stronger units now.
- **Variations.**
  - **Overripe.** After 4 turns, this rots: it sells for 0 again. Sell it on time.
  - **Windfall.** When this becomes Ripe, get 2 gold and this loses Ripen. No selling needed.
- **Owner's direction.** 02h on Acorns: "take a little bit of stuff up front now, or get more later. It always creates interesting decisions." Pillar 13: "Don't move for 3 turns, then X" is good.
- **Designer's response.** Ripen is a time-bound payoff in that spirit: the unit keeps fighting while it ripens, so waiting isn't doing nothing.
- **Open.** Created units sell for 0. Should Ripen add to that, which would let token makers farm gold?
- **Rules review (needs a ruling).** Works as a sell-value change, which 4.3.8 allows. Needs a ruling on Created units: 'sells for 1 more' on a 0-value token lets token makers farm gold, so say Ripen adds only to Bought units, or accept it as an economy rule. Say whether a triple keeps the turn count; readable with a counter.
- **Budget review.** Three extra gold at sale, and a team-wide payoff per sale, put the units +36% to +80% over their tiers (band ±25%).
  - *Crab Apple Sapling*: flag over. body 4 + up to +3 gold at sale, ≈ 0.8 ripened on average, paid around turns 3–5 when gold moves an upgrade (first gold ≈ 4.5, each further ≈ 1.0: 6.5 × 0.8 ≈ 5.2; E54) [guess] ≈ 9.2 vs V(1) 5: +84%, ±25%. Priced at the Tier-1 table it is ≈ 6.8 (+36%), still over Change: Tier 2 on the same 1/3 (the gold arrives around turns 5–7, ≈ 4.3): ≈ 8.3 (+19%).
  - *Blackberry Bramble*: flag over. body 5 + Ripen gold ≈ 4.3 + +1/+1 permanently to its neighbours when Ripe (≈ 1.2 × 2 × 0.9 × 0.8 it ripens ≈ 1.7) [guess] ≈ 11 vs V(2) 7: +57%, ±25% Change: 1/1 (≈ 8, +14%).
  - *Cider Badger*: flag over. body 8 + +1/+1 to every unit per Ripe sale (≈ 0.3 a turn in a Ripen build × 12 SP × 0.9: s ≈ 3.2, over the Tier-4 cap of 2.5; 3.1 × 3.2 ≈ 10) [guess] ≈ 18 vs V(4) 10: +80%, ±25% Change: 3/3, and the buff goes to your units in this row (≈ 3 units, s ≈ 1.6): ≈ 11 (+10%).
- **From.** new, inspired by Cache (47).

## New mechanics: K. Slots, gaps and terrain

### 72. Territory — NEW

This wolf marks its own slot each turn, and enemies that attack whoever stands there get hurt first.

- **Rules.** End of Turn: this unit's slot gains 1 Territory (a slot effect, 8.5; it stacks and stays). In combat, whenever an enemy attacks the unit standing in a slot with Territory, the attacker first takes damage equal to that slot's Territory. If that kills it, the attack doesn't happen.
- **Bends.** 8.5 slot effects, used for defence. 9.6.1 needs an 'attacker gone' line, as Both Ends does.
- **Creatures.** Wolves and foxes scent-mark their own territory. An iteration of Mark (40), aimed at your own ground instead of the enemy's.. **Archetypes.** MEDIUM, STICKY
- **Example units.**
  - *Vixen*, Tier 1, 1/3, Hunters. Territory.
  - *Boundary Wolf*, Tier 2, 2/4, Hunters. Territory.
  - *Old Grey Wolf*, Tier 5, 5/6, Hunters. After an enemy dies from Territory damage, give your units +1/+1 this combat.
- **How they play.** Each wolf marks the slot it stands in at the end of the turn, so a slot it has held for three turns hurts attackers for 3. You can move the wolf to spread the marks, or keep it still to deepen one slot. The marks stay on the slot, so your next unit there is guarded too.
- **Why run it.** It punishes every enemy attack into your marked slots and gets stronger the longer you hold your ground.
- **Scene.** Turns 1 to 3: your Vixen stands in F2, and F2 reaches Territory 3. Turn 4: you move the Vixen to F3 and play a big unit in F2. In the fight every enemy that attacks your big unit takes 3 first, and the 3/3s die before they can hit.
- **Good against.** WIDE boards of small attackers. **Weak against.** Random damage and Start of Combat effects, which aren't attacks.
- **Variations.**
  - **Den.** Territory only works for units of the marker's tribe.
  - **Howl.** Start of Combat: for each slot with Territory, give the unit there +1 Attack per Territory this combat.
- **Similar to.** Like a defensive Galaxy slot buff.
- **Owner's direction.** On Mark: "Mark doesn't make sense to me at all ... Maybe there's iteration to it, but I don't see it right now." (02h)
- **Designer's response.** Territory is one iteration: the scent goes on your own slot, as wolves really do it, and it works every fight instead of only against refills.
- **Open.** Should Territory have a cap per slot?
- **Rules review (needs a ruling).** Works as a stacking slot effect (8.5) with a pre-strike. Needs the 'attacker gone' line in 9.6.1 (as Both Ends), and a rule for the source of slot damage: with no unit as the source, the attacker's Bristle has nothing to prick. It grows without limit over a game; that is a design dial, not a rules break, and the Rival variation named Territory should be renamed.
- **Budget review.** Territory is slot growth that never stops, so its cheap carriers need small bodies, and the sim should find the turn a slot becomes unhittable.
  - *Vixen*: flag over. body 4 + 1 Territory a turn; each point pricks ≈ 1 attack a fight for ≈ 0.85 SP and the slot keeps it (× 1.1): s ≈ 0.95, over the Tier-1 cap of 0.8; 3.9 × 0.95 ≈ 3.7 (E72, E16) [guess] ≈ 7.7 vs V(1) 5: +54%, ±25%. Not linear: once Territory passes an attacker's Health, the slot can't be attacked Change: 1/1 (≈ 5.7, +14%), or Tier 2 on the same 1/3 (≈ 7.5, +7%).
  - *Boundary Wolf*: flag over. body 6 + Territory 3.7 × 0.95 ≈ 3.5 [guess] ≈ 9.5 vs V(2) 7: +36%, ±25% Change: 2/2 (≈ 7.5, +7%).
  - *Old Grey Wolf*: in band. body 11 + +1/+1 this combat to your units per Territory kill (≈ 0.6 kills a fight in a Territory build × 0.6 × 10 SP × 0.6 realised ≈ 2.2) [guess] ≈ 13.2 vs V(5) 12: +10%, ±15%
- **From.** new, inspired by Mark (40).

## New mechanics: L. Gold over turns

### 73. Rainbow — NEW

A fairy starts a pot of gold that grows each turn until you do its task and claim it.

- **Rules.** Rainbow: When you play this, a Pot of Gold appears beside your shop. It holds 1 gold and gains 1 gold at the start of each of your turns, up to 10. It has a task. Once the task is done, you may claim the pot at any time in a Recruit Phase: gain its gold, and the pot is gone. You have at most one pot at a time.
- **Bends.** 4.1 and 3.2.1: gold held off your hand and board, growing at the start of each turn.
- **Creatures.** Fairies and the leprechaun's pot of gold at the rainbow's end.. **Archetypes.** ECO
- **Example units.**
  - *Rainbow Sprite*, Tier 2, 2/2, Fairies. Rainbow. Task: win 2 fights.
  - *Cluricaun*, Tier 4, 3/4, Fairies. Rainbow. Task: have a Fairy in every back-row slot at End of Turn.
  - *Gold-Digger Brownie*, Tier 3, 3/3, Fairies. After you claim a Pot of Gold, give your Fairies +1 Attack permanently for every 2 gold in it.
- **How they play.** The pot grows while you work on the task, and once it's done, waiting a turn is worth 1 more gold. The Brownie turns a big pot into stats too, so a full pot is a board spike as well as gold.
- **Why run it.** Gold with a goal: it rewards the board you were building anyway.
- **Scene.** Turn 3, you play Rainbow Sprite: the pot holds 1. You win on turns 3 and 4; the task is done and the pot holds 3. You leave it, because turn 7 is your big turn. Turn 7 you claim 6 gold, upgrade and buy, and the Brownie gives your Fairies +3 Attack.
- **Good against.** Slow lobbies, where you can let the pot grow. **Weak against.** Pressure that forces you to claim early.
- **Variations.**
  - **Rainbow's End.** "The task is to have a unit at both ends of your front row (F1 and F4) at End of Turn."
  - **Chase the Rainbow.** "Each turn the task moves: it names a random empty slot to fill."
- **Similar to.** Hearthstone's Quests (a task with a reward) and the owner's leprechaun pot of gold.
- **Owner's direction.** From 02h on fairy gold: "We could look at some rainbow mechanics, like leprechauns: there's a pot of gold, and you've got to do something to go get it as well ... Just put some more ideas down."
- **Designer's response.** A new mechanic built on that suggestion: the pot grows each turn (take a little now or more later) and you must do a task to reach it. Waiting after the task is done is a choice with a cap of 10, in line with pillar 13.
- **Open.** Are task wins counted from when the card is played, or across the game?
- **Rules review (needs a ruling).** Works as a player-level gold store that grows at start of turn up to 10. Needs rulings: tasks count from when the card is played (proposed), and a second Rainbow played while a pot exists does nothing. Pair's double trigger should still make one pot; readable.
- **Budget review.** The Pot is about a slow +1 gold a turn and prices near the band; the Brownie's team-wide payoff makes waiting for a full Pot very strong.
  - *Rainbow Sprite*: edge. body 4 + a Pot that grows 1 gold a turn to 10, claimed once after 2 wins: about recurring +1 gold for the game, paid in one lump (6.5 × 0.7 ≈ 4.5; E50) [guess] ≈ 8.5 vs V(2) 7: +21%, ±25%. The Pot stays if the Sprite is sold. For information: up to 10 gold in one claim is over the proposed one-off cap (not approved) Change: If the bot agrees, 2/1 (≈ 7.5, +7%).
  - *Cluricaun*: in band. body 7 + a Pot from turn 6 (≈ 7 gold by turn 12: 4.2 × 0.7 × 0.6 the task is met ≈ 1.8) [guess] ≈ 8.8 vs V(4) 10: −12%, ±25%
  - *Gold-Digger Brownie*: flag over. body 6 + +1 Attack per 2 gold to every Fairy when a Pot is claimed (a 6–10 gold Pot gives +3 to +5 Attack × ≈ 2.5 Fairies × 0.9 ≈ 8, once per Pot × 0.6 ≈ 4.8; E01) [guess] ≈ 10.8 vs V(3) 8: +35%, ±15% Change: 2/2 (≈ 8.8, +10%).
- **From.** Inspired by Bargain (51) and Wager (50), and the owner's leprechaun idea in 02h.

## New mechanics: N. Waiting off the board: hand and sleep

### 74. Offstage — NEW

This card helps your board from your hand, like a prompter in the wings.

- **Rules.** Offstage: While this is in your hand, it does its Offstage effect in combat. Only your leftmost Offstage card in hand acts. It doesn't fight and can't be hit.
- **Bends.** 3.4.2 (units in hand don't fight and don't count). The hand gains a slot that acts in combat.
- **Creatures.** The Folio's fox travelling theatre and Frog Chorus: the prompter offstage.. **Archetypes.** MEDIUM
- **Example units.**
  - *Prompter Mouse*, Tier 1, 1/1, Hedgerow folk. Offstage: Start of Combat: give your F1 unit +2 Attack this combat.
  - *Wings Toad*, Tier 3, 2/3, Bog folk. Offstage: after one of your Bog folk dies, give your other Bog folk +1 Attack this combat.
  - *Stage Manager Fox*, Tier 4, 4/4, Hunters. When you play this, give your Offstage card in hand +2/+2 permanently.
- **How they play.** Your leftmost Offstage card acts from hand, so you choose which to put first. Playing it later puts a body on the board, so it is a choice each turn: help now or join later. The Stage Manager grows the card in the wings for its debut.
- **Why run it.** An eighth piece in the fight that can't be killed, at the cost of a hand slot and a body off the board.
- **Scene.** Turn 2 you hold Prompter Mouse instead of playing it: your F1 hits for +2 each fight. Turn 6 your board is full, so it stays in hand all game.
- **Good against.** Boards that kill the support units in your back row. **Weak against.** Boards that need every body: an Offstage card isn't one.
- **Variations.**
  - **Understudy.** "Offstage. When a friendly unit dies, this is summoned in its place."
- **Open.** Is "leftmost Offstage card only" readable enough, or should Offstage need an empty board slot instead?
- **Rules review (needs a ruling).** Works with 9.3.1's 'units that trigger from hand' phase. Needs rulings: the snapshot others fight must include your leftmost Offstage card (9.1.1 copies only the board), and the hand needs a fixed order (see Rehearse). The Understudy variation summons from hand in combat, so say the card stays in hand after combat; readable.
- **Budget review.** An Offstage card gives only its effect, so the effect must carry most of a unit's budget; both are written at aura size and come out under. Slot-free value is a guess until simulated.
  - *Prompter Mouse*: flag under. never takes a board slot: Start of Combat +2 Attack to F1 (≈ 2.2) + a slot saved ≈ 1 (E23, proposed E96) [guess] ≈ 3.2 vs V(1) 5: −36%, ±15% Change: '+2/+2' instead of '+2 Attack' (≈ 5.2, +4%).
  - *Wings Toad*: flag under. +1 Attack this combat to other Bog folk per Bog folk death (≈ 3 buffs a fight × 0.6 realised ≈ 1.8) + a slot saved ≈ 1 [guess] ≈ 2.8 vs V(3) 8: −65%, ±15%; played as a 2/3 it is 5 (−38%) Change: '+2/+2 this combat' instead of '+1 Attack' (≈ 8.2, +3%).
  - *Stage Manager Fox*: edge. body 8 + +2/+2 to the Offstage card in hand, which counts only if that card is later played (≈ 0.6 × 0.3 × 3.6 ≈ 0.6) [guess] ≈ 8.6 vs V(4) 10: −14%, ±15% Change: 4/5 (≈ 9.6, −4%).
- **From.** Inspired by Rehearse (59) and Hibernate (58).

## Questions for the owner

1. **Rounding when damage is halved.** One rule for the whole game, or a choice per keyword? Rounding up means a 1-damage hit always lands (Hunker, Antlers, Whistle). Curl rounds down on purpose, so 1-Attack tokens can't hurt it.
2. **Turns that aren't attacks.** May a unit spend its place in the attack order on something other than an attack (Bide, Whistle, War Dance, Curl, Nocturnal)? If so, *proposed:* a skip costs only that unit's attack, not its side's turn (shared rule 2), and a fight ends as a tie when a full cycle of both sides deals no damage, instead of running to the 200-attack limit (R3). Still open: do non-attack turns count toward that limit?
3. **What the board holds besides one unit per slot.** Do you want non-unit objects in slots (Thicket, Brood's Egg, Bury's Nut, Fallow, Mark, Flood's water), and units that are in combat on no slot (Ride's riders, Burrow, Play Dead; Hibernate and Fly South between fights)? *Proposed:* one shared off-slot state, and one table (R7) saying what each kind counts for. And is 7 bodies a line to keep? *Proposed:* if riders may pass it, they stay at Tier 1–2 until simulated, since E23's +1 SP probably under-prices an eighth body.
4. **Reaching into the enemy's board.** Which of these may effects do: put objects in enemy slots (Brood), move enemy units (Flush), make a unit fight for the other side (Changeling), permanently change the opponent's board (Shiny's steal)? *Proposed:* no permanent change to the opponent, since fights are against snapshots, so Shiny's victim loses the stats for that combat only. Changeling alone needs units to fight for the other side (R10): hold it back from v0, or keep it with a condition such as "only if the enemy unit across has 6 Attack or less" so it stays on a unit budget. If enemy moves stay in, should Start of Combat keep its random side order (9.3.2), which decides results like Rival against Changeling, or use a fixed order?
5. **Bending fixed slots and free moves.** Three ideas break a placement rule. Caravan brings packing back for one tribe (8.3.4), Migrate makes a unit place itself each turn (8.3.3), and Aisle makes the slot a unit fought from pick which shop card it affects, so moves get a cost. Which are good rule-breakers, and which undercut fixed slots or become a chore?
6. **Owners for two open ideas.** Golden chasing has no tribe yet (archetypes.md 1.3). Foundling, Pair and Mimic serve it: should one tribe own it, or neutral units? And should shared damage go to rats (Knot, Hedgerow folk) or Oozes (Linked)?
7. **Smaller rulings, as a set.** Accept these defaults, or name the ones to change:
   - Reflected damage never triggers reflected damage. It becomes a system rule, which stops the Bristle, Curl and Both Ends chain (R2). Bristle reflects damage from attacks only, not enemy pings; Curl reflects all damage.
   - Protection beats reach: Shelter wins over Grudge, Rival, Nocturnal, Shiny and War Dance, and a reach unit whose target is protected attacks normally (R6).
   - Golden thresholds don't double, as 7.3.5 reads now: a golden Shrug, Shell or Cache keeps its N, so a golden Shell isn't weakened (R12).
   - Combat text that says "gains" with no duration means "this combat" (Slumber, Gorge, Alibi).
   - Thrift's "more gold than you started the turn with" counts this turn's income in the start. That fires on about 0.3 of turns; the "banked some gold" reading fires on about 0.7 and costs about 3 times as much.
   - Bargain's "if you can't pay" takes the gold you have as well as the Attack, so holding under 6 gold doesn't dodge the debt.
   - Pawn applies to Bought units only, so Created units still sell for 0, and pawning is limited to once per turn.
   - A Strong refresh spell from Brew is reviewed under G1 (R11), like any other unpaid refresh.
   - Sett goes to Tier 4 with the printed +1/+1 a turn, rather than Tier 2 with +1 Health a turn.
   - A third copy makes a Bonded pair golden at the normal golden size, not double the pair (four times one body). This is the reading that keeps it in budget; the review left it open.

Not asked here: Mimic, Endangered and Wager can't be judged until the async model (rulebook 2.1.4, 2.1.5) is settled.
