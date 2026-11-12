# Owner notes: what I think of other auto-battlers' systems

Dictated by the owner on 8 November 2026. The owner set out a checklist (paradigms and tuning; TFT, Battlegrounds and Galaxy compared; damage systems; shop size, tier and rarity; pool size) and talked through each item.

**Why this record exists.** The owner wants agents to understand their taste: what they think is good and bad about these games' systems, and why. Read it as the owner's opinions and reasoning, not as decisions. Where it disagrees with the rulebook, the rulebook still holds until the owner changes it (see the editor notes at the end).

**How this record was made.** The wording is the owner's, kept as close to the original as possible. Only the following was changed:

- Filler words, repeats and dictation errors were removed, and punctuation was added.
- The notes were reordered into sections by topic. Two later amendments the owner made (to shop size and to "tuning") are folded into the sections they amend, and marked.
- Notes in *[italic brackets]* are the editor's (Claude's) reading of what was meant. They are not the owner's words.

---

## 1. What makes a paradigm good

I think a paradigm's as good as long as it offers lots of different interesting strategic or tactical options. And I think a good mix of strategy and tactics is ideal.

Many different paradigms can be good. Tuning is inherently linked to paradigm. *[The owner first said "it's the tuning of those paradigms that really matters", then corrected it: "I shouldn't say tuning beats paradigm, but tuning is inherently linked to paradigm."]*

Essentially, I think all these design philosophies are designed to work within the systems they serve, which makes sense. And our question is: do we need to create our own system that works inside its own paradigm, or can we be a little more directly inspired by one of these systems and be a subfamily of an existing system?

## 2. Tuning is linked to paradigm: stat granularity

I think I covered that with the triples, in terms of the granularity at which TFT hands out stats. TFT deals with large numbers, in the hundreds, and you can hand out stats in pretty granular increments at that point. But a lot of effects in Battlegrounds and Galaxy are legitimately just +1/+1, and there's not much you can do to increase +1/+1 in power level by 2% or 3% to give it a small nudge. Your only options are adding an extra Attack or an extra Health, and that gives you about 50% additional power handed out by a stat. That's a real downside of the granularity difference.

It's why a lot of these silver, gold or tripling effects have to be double: there's no way to hand out a slightly better effect and have it feel consistent across the board to players. Whereas in TFT it's very easy to go: at this tier it does 300 damage, at this tier 450, and at this tier 650. That's roughly 50–60% more power each time, somewhere in that ballpark. And that works in that paradigm because you have different stat block sizing.

## 3. TFT, Battlegrounds and Galaxy: strategy and tactics

### 3.1 TFT

My biggest issue with TFT is that you don't really make strategic choices so much as pick between pre-existing strategic choices. The optimal boards are mostly already solved, due to how the trait system works, the lack of granularity, and the thresholds.

Most traits don't give you any additional stats for going from 2 to 3 units in a trait, but you do get a bunch of extra stats going to 4. So it's never an interesting choice. Do I want to run 3 Heart units? No. I always want to run 2 Heart units or 4. There's no situation where I'd ever want to run 3. It's just inefficient. It wastes one of my very key resources, and I could get stats elsewhere.

That leads to these pre-solved strategies of which units are best together. And the gap between them and the next-best strategy is so large that it causes many problems, for me at least. So all the choices are more tactical ones. You don't make strategic choices so much as pick which composition you're going to play. But it's a pre-solved comp with pre-solved mini-variations. And you have enough economy to get to those pre-solved comps repeatedly, and it's worth spending all the economy to do it rather than going for something slightly suboptimal, because the power jump is so large.

What makes TFT's paradigm good is the tactical depth. It's a very deep game tactically, and there's so much micro-optimisation you can do with economic decisions. There's a constant tension between sacrificing economy for strength, and gaining strength at the cost of long-term power because you lose economic power. If you go below a certain gold threshold, your economy takes quite a while to recover. That constant trade-off between strength now and more strength later, at the cost of HP as a resource and potentially not being able to survive, is always an interesting one.

### 3.2 Battlegrounds

Battlegrounds, at least in the early game, is much more about being flexible, playing around the units you're given and finding ways to make things good together.

### 3.3 Galaxy

Galaxy really does this well. You don't ever have to play a specific combination of this unit plus that unit. Pretty much always in Galaxy you've got a novel combination of units on your board for most of a game, and there are a lot of interchangeable effects. There are situations now where that's not as much the case, but for a large part of the game's life cycle that was true.

So the small shop in Galaxy wouldn't work in TFT or Battlegrounds, due to how their paradigms work. Galaxy designs a lot more units that are just generically useful, and they don't need other pieces to combo with to become really good. But as a result, some of them feel a bit samey. Not all, and they do a good job, but it's not as strategically asymmetric as a game like TFT or Battlegrounds.

Essentially, you have to pick a trade-off in one of these areas.

## 4. Damage systems

### 4.1 Battlegrounds' formula and what it says

Initially, Battlegrounds' system picked damage equal to the sum of the tiers of all units left alive at the end of the fight, plus the tier of the victorious player's shop, dealt to the loser. There's an inherent statement there that you are punished more for leaving higher-tier units alive. That isn't a statement about fight quality or how well the player performed in the fight. It just acts as a function to deal more damage as the game goes on, in theory. And because damage isn't at all based on how well you actually performed and how close in strength you were to your opponent, the system has produced a lot of issues for Battlegrounds over the years.

### 4.2 How Battlegrounds patched it

I'm not sure if in the beginning there was no damage cap, but the first system I remember playing capped damage at 15 until one person had died. After that there was no damage cap. There was no small damage cap in the early turns, nothing. And as a result, a lot of games were just three lost fights, sometimes two. It was possible to take 30 in a fight. I remember fights where I took over 40 damage in a single fight. And that felt really, really bad.

The second modification, instead of addressing the core problem, started putting limits on the formula's ability to output high numbers. They changed it to no one could take more than 15 until four people had died. That again just shifted the problem. It was a better shift, but there were still situations in the early game where you'd take 15 that just wasn't deserved. You'd run across somebody who got very lucky in the early game and dealt 15 to you, and your entire game would be ruined.

So they introduced the system we have now: in the first 3 turns you take at most 5, then at most 10 until turn 7, and after that at most 15 until there are 4 or fewer players left alive.

I think this is still a bad system, because it's still dealing damage based on something other than how close you are in strength to your opponent, which is what the player is trying to achieve as their goal. The idea is that if you're close in strength to your opponent, you should take less damage, and if you're very far away, you should be punished more. I feel the system really fails to achieve that. There are many situations where you could be 80% to win, but in the 20% of outcomes where you don't win the fight, fully three-quarters of those have you taking 15. That's not a good system, in my opinion.

### 4.3 What damage should measure

I want a system that accurately measures: did the player do well? If you cleared the majority of units on your opponent's board, or dealt with most of your opponent's threats, but just didn't quite get there, I'd prefer the system punishes you less than if you got absolutely stomped.

Ideally I want to reduce the big swinginess and the arbitrary feeling of the damage system to the player. I want the damage system to reflect your objectives as a player, and in doing so say that your objectives are the right things: having a chance of winning the fight, and killing as many of your opponent's units as possible.

### 4.4 TFT's system, which I prefer

I compare it to the last damage system I was aware of in TFT when I stopped playing. It dealt damage based on the number of units left alive at the end of the fight, making no distinction about whether those were big or small units or their tiers. It was just how many did you not kill, plus a certain number, and that number increased over time.

I think that was a better system. You want the system to deal more damage as you go into the late game, so games don't drag on forever. And a better way of measuring how long the game's gone on than tavern tiers and the tiers of units left on boards is measuring how long the game's gone on. Instead of using a proxy to measure game length and deal extra damage, it's better to use the length of the game itself. It's far more accurate than the Battlegrounds system.

I don't mind a little swinginess in how much damage you take from fight RNG, though. The number-of-units-surviving thing feels fine.

### 4.5 The problem with counting units: tokens and summons

The issue is that in any system with tokens or summons in combat, that number can really warp. A lot of the big problematic Battlegrounds damage boards in the past were Undead boards that summoned a T7 unit called Recurring Nightmare. With that unit around, it was not uncommon to have seven of them on the board at the end of a fight and take 49 damage. It happened a surprisingly large amount. It was absolutely awful.

### 4.6 What I'd like to try in Bramble

I'd like to experiment with a damage system that's more around the number of starting units left alive, plus some number that increases over time. I don't know exactly what balance we want to strike, and that will depend on how much starting health we have.

I have thought about looking at tavern tiers and modifying the system. I have thought about looking at the Health or Attack left on the board and summing that, but that's less intuitive to a player. It can't be done on the fly in the same way, and it's not inherently understandable. Those are systems we could also experiment with if the current one doesn't work.

### 4.7 Starting health, and how much performance should count

We need to pick a starting health that fits our system and doesn't feel wrong, for want of a better word. Battlegrounds went with 30, TFT with 100, and many games go with 10. I'm not sure what the right number is.

There are also many games that don't measure how bad or good a fight was at all. If you lost, you take a loss; if you won, you take a win. There's no difference between a big loss and a big win. Something close to that would perhaps be better. The performance measurement should probably be significant, but not the majority of it. I'm not sure what the proportion between the two should be.

## 5. The shop: size, tier and rarity

### 5.1 The shop as a power lever

I think of the shop as one of the levers you can use to give the player power. You need a certain number of different levers the player can invest in to enable strategic differentiation, which then enables interesting gameplay. TFT has probably done it best of the games I've played, but I still have a fair number of issues with the way TFT has done things.

### 5.2 Shop size

In TFT the shop is always 5 units. I like the set number. An adjustable number is an option, but looking at 7 units at once can feel a bit overwhelming. I've even enjoyed the simplicity of Galaxy's pick 1 of 3.

The issue is that a smaller number of options limits your ability to design really niche pieces. The player needs to get stronger from the average shop, and feel there's stuff in there they want, that could be useful, and that there are real choices to be made. Not a lot of stuff that's all worse than what they have because it's too niche and can't apply to their board. So you need to design more general effects. But the more general effects you design, the less asymmetry there is, and thus the less strategic differentiation and interest. There's a careful balance to strike.

So I don't mind a static number for the shop, and I don't necessarily mind a flexible number. I'm not quite decided which direction is better. I feel Battlegrounds going to 7 units in the shop is probably too much. I feel an odd number is correct, for some reason, and even numbers feel worse. So I feel drawn to 3 and 5. 3 is probably too simple for the game complexity we're going for, so I feel drawn to doing something similar to TFT, with 5. But we may need to experiment.

*[Amendment, given after the owner read the summary:]* This is very much a feel-based thing, and I'll know what's right when I see it. These are just suspicions. Even numbers may be fine: 4 and 6 may be completely fine. It definitely needs to be between 3 and 6, I think, but maybe it can be 7. 8 is definitely too many; 7 is the upper limit and may be good. Somewhere between 3 and 7 feels right. Visual structure also affects this. What needs recording is that shop size is very flexible, and we can and should experiment with different things. Even if at the moment I think something might not be the right direction, we should try a few different things.

### 5.3 Extra shop slots as their own upgrade

Maybe adding more shop slots could be an upgrade path the player invests in. It's an interesting design idea. In Battlegrounds, when you level, you get extra shop slots for free at certain tiers: every second tier gives you an extra slot, up to 7 at least. But what if it was a completely separate thing you could invest in? You could just invest in extra shop slots, not linked to levelling or any other thing. It's potentially interesting.

### 5.4 Tier odds

Shop tiers are handled quite differently between systems. Battlegrounds doesn't weight specific units by shop tier. The shop is a completely random selection from the pool. TFT does have weighting: at higher levels your odds of higher-tier units go up and your odds of lower-tier units go down.

That poses some downsides. At higher levels you're less likely to see lower-tier units, and if there's a specific lower-tier unit you need, it can be hard to find. Levelling has real downsides for specific strategies.

The idea of the Battlegrounds design is that you change the number of units in the pool, so you get roughly equal chances of seeing everything. But the way they've tuned it, the maths doesn't actually pan out that way.

### 5.5 Pool size, especially in async

With the Battlegrounds method, the number of copies in the pool changes the likelihood of seeing something. With the TFT method, I think rarity is decided first in the shop, and then you pick from the copies in the pool. So having more or fewer copies of an epic acts more as a restriction for a live lobby, which I don't think makes sense in an async environment. It acts more like a cap on the total number of units that can be offered than actually changing the odds.

So is pool size even something you want to support in an async environment? Or do you just have chances? That's something I've been thinking about.

### 5.6 Strategies built on many copies of one unit

I think the fundamental tension is whether you want strategies about finding a large number of copies of one unit: a triple, or multiple triples. TFT has 1-star, 2-star, 3-star of a unit, versus Battlegrounds, which only allows a single triple. Entire strategies can revolve around looking for multiple copies of a single unit. I'm not sure whether we're going to do that. I haven't decided yet. But it has consequences.

### 5.7 My biggest issue with TFT's shop: levelling bundles board space and shop tier

The biggest issue I have with TFT is how linked shop tier and board space are. Many reroll comps would love extra board slots, but they don't want a higher shop tier; it actually makes them weaker. They'd love to buy half of the upgrade and not the other half. Because the two come stitched together, reroll comps are artificially weaker than they otherwise should be. I never liked that.

### 5.8 Board size limit

We currently have no plans to limit the number of units you're allowed to play, same as Battlegrounds. *[Editor's reading: Bramble's board is fixed at 7 slots (rulebook 8.1.1), as Battlegrounds' is at 7. The owner means there's no limit that grows with level, as TFT has.]* I'm not sure that's the right approach either. We could introduce a limit on the number of units on the board at any one time, which you could upgrade over time. That's an interesting way of introducing strategic variation. They're just two very different paradigms, and for each of these mechanics you need to figure out what makes sense and how to test it.

## 6. Combining copies of a unit

The three games have three different approaches to combining multiple copies of one unit.

### 6.1 TFT

In TFT you get three of something and it turns into a better version, and three of those turn into a better one again. *[The owner was unsure of the exact copy count and wants it checked. See the editor notes.]* Regardless, it's a different approach from Battlegrounds.

The difference in power between levels is very interesting. In TFT I think a unit gets roughly 60% stronger per star level, give or take. You don't get anything extra for making the triple; the unit itself is enough. Outside of incredibly rare situations, you always want the triple.

### 6.2 Battlegrounds

Battlegrounds has three units turn into a golden, and that's it. A unit's effect power is typically doubled. Units are also more expensive as a share of your economy in Battlegrounds. So it's a very different system.

You couldn't have an extra level if doubling power was allowed. I don't think Battlegrounds could possibly implement a platinum above gold, where two golds turn into a platinum and you get 4x the power. There also just aren't enough units in the Battlegrounds pool to allow for that, outside of copying effects.

Often many Battlegrounds units don't get more powerful at all with a triple. There are many cards where you'd actually prefer two normal copies over tripling into a golden. In TFT that's just never the case.

Then there's the triple reward. In Battlegrounds, a triple gives you access to something higher-tier. So you can use tripling to try to get direction and a higher-tier unit, and in the early game it can be something you play towards as a strategy. But because of that, triples obviously have to be far rarer than they are in TFT.

So your triple system is inherently linked to your shop system, how you do units, and the power jumps you're expecting.

### 6.3 Galaxy

Galaxy works on an entirely different system, where getting extra copies of a unit is essentially free: they give you a reroll and give you any shop buffs you have as stats. A silver copy doesn't consume one of your shops for the turn. So they're effectively always good. There's no strategic choice beyond opportunity cost: if the other units in the shop aren't anything you're interested in, the silver is always amazing.

As a result the game becomes quite based around silvers. If you don't hit silvers, you lose a lot of power, and you don't get to play the game as much because you don't get enough shops. It adds a lot of randomness. It's a weird system.

Golds in Galaxy can sometimes feel weaker than silvers. Sometimes the treasures are great, but you have to pay the opportunity cost of losing a shop. And many units don't get much better with gold, at least in Galaxy's context. Some do. In theory they're all twice as powerful, the same as Battlegrounds, while silvers give no additional power beyond +1/+1 base stats plus whatever shop buffs you have. But golds in Galaxy are a more interesting choice.

### 6.4 Galaxy's economy: no currency

I'm not really sure how to evaluate these paradigms against one another. But for a game as simple as Galaxy, the silver system works well, because they didn't want an economy of currency. Shops are the only thing that matters. Everything just costs taking it from the shop. You pick one of three, and you don't have to worry about maintaining a resource.

I do think managing a resource is interesting, but the simplicity of getting rid of the resource system is a very valid option. It does, however, take away your ability to be granular with economy effects. Without something as granular as gold, you can't be precise: in TFT a 5-cost unit costs 5 gold, so rewarding someone 2 gold versus 3 versus 4 lets you be quite granular with how much economy you give from something. In Galaxy, giving somebody an extra shop is a big jump in power no matter what. And economy granularity in what you can hand out as rewards does matter.

---

*[Editor notes:*

- ***Where this differs from the current rulebook.** The rulebook uses Battlegrounds as the default for systems, so several rules differ from the views above. None of these rules has been changed. The owner hasn't said whether these views should change the rules or only guide experiments.*
  - *Damage: rulebook 10.1.1 and 10.1.4 use Battlegrounds' formula and caps, the system section 4 criticises.*
  - *Starting health: 30 (rulebook 2.2.5).*
  - *Shop size: grows with tier, 3 to 6 units plus a spell (rulebook 6.1.1). Section 5.2 leans toward a fixed 5 but says to experiment.*
  - *Pool: Battlegrounds copy counts, drawn in proportion to copies left (rulebook 5.1.2, 6.1.3). Fights are async against snapshots (rulebook 2.1.4), which is the case section 5.5 questions.*
  - *Combining: Battlegrounds triples, golden doubles numbers, Triple Reward (rulebook 7.3).*
  - *Economy: Bramble already has gold that carries over with no cap and no interest (rulebook 4.1.2–4.1.3), so it keeps currency (section 6.4).*
- ***TFT copy count (section 6.1).** As I understand TFT, a bought unit is 1-star, three 1-stars make a 2-star, and three 2-stars make a 3-star, so a 3-star takes 9 copies. This hasn't been checked against a source; the repo has no TFT research library.*
- ***Recurring Nightmare (section 4.5).** Confirmed tier 7, Undead, in the card library (`docs/research/battlegrounds/data/minions.csv`), in the pool from 31 August 2023 to 21 January 2025.]*
