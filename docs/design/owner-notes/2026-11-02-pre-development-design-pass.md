# Owner direction: the design pass before development

Dictated by the owner on 2 November 2026.

## Where we're heading

I want to get into development in cloud environments in Godot, similar to how the original Autobattler project worked (the repo that is on this computer, which also did a lot of cloud execution). However, before we do that, we need to get our power budgeting systems in order and understand our design philosophies, our tribes and their strategies, and how they link. Here's a list of things that I think we need to do before we move into development.

## What we already have

I think we already put in some effort into researching all Battlegrounds cards that have existed, going through every Battlegrounds patch note, building as much of a design library as possible, and developing a kind of time-stamped content library, to understand what strategies existed in various tribes at various points and what the power budgets were. I think we need to understand roughly what a good power budget is in Battlegrounds land, because it's the closest paradigm for us.

## Our constraints that Battlegrounds doesn't have

Here are the fundamental design constraints that our game has that Battlegrounds does not have. Battlegrounds is time-bounded, so they can distribute economy effects quite a lot. There are situations in Battlegrounds where you can end up truly mathematically infinite: it is statistically impossible for you to run out of resources. We can't have that in a game where there is no time limit, because then the player can just sit there and play forever, until they realize that their power is kind of meaningless for themselves.

But we do want to have really powerful economy effects, because those things are fun. And I like Battlegrounds' current philosophy, where they've got a lot more of those effects in the current patch compared to points in the past. I think it's a better situation where everybody has them. So we need to have enough economy effects in the game that really give the player extra resources in interesting ways, without having it lead to unbounded economic effects.

We've done ourselves some services with our reroll design, and we can lean on that to prevent infinites, with free refreshes being something we need to be super vigilant of because of it. We may even need to change our reroll design rules as we find things to be more or less fun. We may need to extend the escalating reroll costs past a certain point. Maybe they need to go up to 5 rather than 3, whatever. But we want to be able to design fun and cool effects. Something like a Tethys, or a Sky Pirate Rogers with the privateer in current Battlegrounds, is able to go infinite. In our game, I want it to go for a very, very long time, but not infinitely. Finding that balance, whatever that might be, is going to be our challenge. I'm not sure how many shops it should be. Maybe we want 20 shops. Maybe we want less. I'm not sure. But we want to figure all those questions out up front.

## Positioning

Then we need to make sure that our combat rules in terms of positioning actually add a little bit of extra depth compared to Battlegrounds. And if they're not working, we can just cut them.

## What I want from agents

So I want to do both power budgeting and design documents from agents, looking at the pros and cons of these systems, what they actually do to player experience, and what they do to strategy development and variation.

## Strategy flavours

Typically, strategies in these games come in a couple of different flavours:

- Strategies about making lots and lots of small actions that generate money but don't give a large amount of stats.
- Strategies about summoning lots of units and having a deep board: lots and lots of small units with high ability to trade.
- Units that are scam units, with the ability to kill units much larger than themselves, like a Leeroy Jenkins or a poisonous unit in Battlegrounds.
- Comps that attempt to scale, through a variety of different flavours: when they die; when something happens, like trying to summon a unit that can't fit on your board; whenever you play a battlecry unit; whenever you trigger a battlecry; whenever you play a spell; whenever you cast a spell on this thing; whenever you magnetize a mech; whatever it might be. Scaling comps try to win by stats, and there are typically a couple of flavours of those: make one or two really big units, or make a bunch of medium-sized units.

So I want us to understand what our strategies are, what the pieces are in our game, and so on. We are going to want spells. Spells are going to be part of the game, for certain.

## The ask

I want a bunch of agents to iteratively do a bunch of design loops with critics: gathering information, comparing it to other games, and looking at whether it's possible to find player feedback or sentiment. If that's not possible, that's okay; I can provide my take.

Essentially, get some strategy documents in terms of:

- what our strategic archetypes are going to be;
- what mechanics we can create that would fit some of the faction designs we've got, or flavour-wise suit some animals;
- a couple of proposed tribes and prototypes that we think are just easy wins: things that are almost obvious includes for the game, that just make sense.

We want to aim for 10 tribes. Let's try to come back with at least 5 after this pass, and have a backlog of ideas for the next ones. We want power balance. We want to understand what the strategic archetypes are going to be, and the kinds of unit types that are going to exist on the various shop tiers and how those are going to work.

*[Editor notes:*
- *"Sky Pirate Rogers" is Sky Admiral Rogers (tier 6: "After you spend 9 Gold, get a random Bounty"), per the card library. Fleet Admiral Tethys is tier 6: "After you spend 10 Gold, get a random Pirate."*
- *"Up to 5 rather than 3" is read as the escalating refresh cost: the economy decision of 27 October set thresholds at 1–10, 11–20 and 21+ refreshes, and the owner is open to more steps or a higher cap.*
- *"20 shops" is read as a possible cap on how many refreshes a long turn should allow, not a hard number.]*

## Answers to Claude's questions

The owner chose from options Claude offered:

- **Turn timer:** "No turn timer at all."
- **What bounds a big engine:** "Rising cost only."
- **What a tribe is:** "Broad creature kind."
- **Testing the rows:** "Yes, a quick sim."
- **Size of the agent effort:** "Large: ~25 agents."
- **Starting point:** "Merge #1 first."
- **How spells reach the player:** "Like Battlegrounds."

*[Editor notes: the options as Claude offered them:*
- *No turn timer: fights are async against snapshots of other players, so a player can take as long as they like each turn, and the economy has to run out by itself.*
- *Rising cost only: steeper refresh and action costs, so even the best engine runs out of gold eventually. No hard caps.*
- *Broad creature kind: a few wide groups (for example rodents, birds, fairies, oozes), with species as flavour inside them.*
- *Quick sim: a small, throwaway, headless Python simulator that runs fights with and without position effects, to give evidence for keeping or cutting the rows.*
- *Large: research fan-out, then 2–3 design-and-critic loops per area.*
- *Like Battlegrounds: tavern spells appear in the shop next to units and are bought with gold, plus spells generated by card text.]*

## Effect taxonomy and tolerance

Obviously, for there to be a power budget, we need to have an effect taxonomy. We need to understand all the effects that we can actually give the player. Like, you have a unit: give a unit an additional ability; change its stats; increase its stats; increase the power of future stat increases; give a specific type of stat increase; give a card that does this effect; get a random card. All these kinds of things. We need to understand our total effects taxonomy, and if we can, have some idea of the power associated with those effects.

And also, we've got 15% leeway built into the power budget. That should be in either direction, and maybe even more than that, maybe 25%. We're going to get things wrong. That's okay. We're going to iterate and catch those things later.

## Answers to the plan check's questions

The owner chose from options Claude offered:

- **Tolerance band:** "±15% default, ±25% engines."
- **What rising cost covers:** "Refreshes only."
- **What a very long engine turn means:** "About 20–30 shops."
- **Evidence for keeping the rows:** "Both."
- **A design-pillars document:** "Yes, short pillars."
- **A by-era study of tribe strategies:** "Yes, build it."
- **Where player sentiment can't be found:** "Ask me."

*[Editor notes: the options as Claude offered them:*
- *±15% default, ±25% engines: plain and simple cards within ±15%; economy, scaling and engine cards, which are harder to price, get ±25%. Both directions.*
- *Refreshes only: only the refresh action escalates; gold-spent engines such as Tethys and Rogers are bounded by content design.*
- *About 20–30 shops: the best engines see roughly 20–30 shops in a turn before gold runs out.*
- *Both: sim evidence that smart placement beats random placement once position cards are in, plus prototype position cards for the owner to judge.*
- *Short pillars: one page of what Bramble values and avoids, drawn from the owner notes.*
- *By-era study: a map of each tribe's strategies in each era, built from the card-pool history and patch notes.*
- *Ask me: gaps in player sentiment come back to the owner as a short list of questions.*
- *"No turn timer at all" contradicts rulebook 2.1.4 (async lobbies outside v0) and 3.1.2 (recruit timers). The rulebook needs a delta.]*
