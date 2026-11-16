# Owner notes: where Bramble should sit, and designs I like

Dictated by the owner on 8 November 2026, answering questions Claude asked after [2026-11-08-autobattler-systems-thoughts.md](2026-11-08-autobattler-systems-thoughts.md) about what would help agents understand the owner's taste. The questions were: where Bramble sits between TFT and Galaxy; whether solved comps are acceptable; what stat scale to use; and which designs the owner loves.

**How this record was made.** As for the earlier note: the wording is the owner's, with filler, repeats and dictation errors removed and punctuation added. Card names the dictation got wrong are corrected to their names in `docs/research/battlegrounds/data/`, and each correction is listed in the editor notes. Notes in *[italic brackets]* are the editor's (Claude's), not the owner's words.

---

## 1. Where Bramble should sit: depth without complexity

I want Bramble to try to strike a balance. If possible, I want to have our cake and eat it too. I know we'll never fully get that. It's impossible to get everything, and you have to make sacrifices at some point. But great designers find ways of capturing depth while removing complexity. They find ways of keeping decisions feeling really meaningful, and eliminating everything that isn't needed for that decision to have the same weight.

If we can achieve the kind of depth TFT has, with mechanics as simple as Galaxy's, that's what I'd love. I know you can't get quite to those extremes, but we should try to get towards that.

## 2. Solved comps

I accept somewhat solved comps. It's pretty inevitable, especially if you want to design key, cool, interesting pieces at high tiers without an enormously wide, long pool that's hard for the player to remember. There will be some best setups. There's always going to be a mathematical best.

I'm fine with some solved strategy as long as it takes cool tactical play to get to it. Solved strategy in the mid game is a problem, and in the early game it's a very big problem. In the end game it's less of a problem. That's always going to happen; you can't avoid it. There's going to be a best option. That's just how it works.

At the highest tiers you want chase units that do really powerful, exciting effects. The more exciting and bigger the effects, the more multiplying some of them together can get out of hand, and it will happen. As long as there's counterplay, that's good. In Battlegrounds there are a lot of situations where you end up with really, really big units, much bigger than your opponent's. But a clever opponent can run enough Venomous units, Leeroys and other scam units, and position well against your comp, so they may have a chance of beating you anyway. Having some counterplay is important. Units having a weakness is important, even if they're really strong.

## 3. Stat scale

I think we may want higher numbers. Galaxy's numbers are too small to enable good tuning, and to a certain degree Battlegrounds' early-game numbers are too small for good tuning. So we may want bigger numbers than Battlegrounds. Not by a ton, but by a bit. We want a bit more granularity.

## 4. Designs I like, and one I don't

### 4.1 Bounded value engines

I really like a lot of the value-engine, mid-range strategies that have existed in Battlegrounds. For example, a lot of the menagerie comps have bounded economy effects that are really powerful. You pretty reliably get 10 spells a turn, and you can use them to buff your board somewhere between +50/+50 and +100/+100. Then you run out of gas and go on to the next turn.

You have to keep changing which units you're running, and it's a real question whether it's worth swapping something out. Finding the right mix of economy units that don't scale, because they're typeless, versus units that hold stats really well but don't give economy is really interesting. Those strategies can be really good.

### 4.2 Unbounded engines: Infinite Pirates

I don't like strategies like Infinite Pirates in Battlegrounds. They revolve around Sky Admiral Rogers and Proud Privateer being golden, and effectively getting enough Bounties that you can take an infinite number of actions. Then the game just boils down to pure action spam.

I think Sky Admiral Rogers and Proud Privateer are cool effects. You probably just need a limit on them. In our game we have escalating refresh costs, which should probably mean you couldn't do that forever. I'd expect that in our game you could copy Sky Admiral Rogers, the Bounties and Proud Privateer as they are, and you wouldn't be able to go forever with those units. Maybe that would actually be a good design in our system. I'm not sure.

*[Follow-up, after Claude questioned whether refresh costs would stop the loop:]* I'm not sure about the exact maths on Sky Admiral Rogers. I'll give you some frameworks for evaluating it and you can figure it out yourself.

If you had two golden Sky Admiral Rogers and a golden Proud Privateer, every time you spent 9 gold you'd get 4 Bounties. 1 in 5 Bounties gave you 2 gold, so 4 Bounties gives you essentially an 80% chance of getting the gold Bounty. Say you get 1.6 gold every time you spend 9. That Bounty casts 2 additional times, so it gives you 6 gold back. So after spending 9 gold, just in expected value from the gold Bounty, you'd get 5.2 gold back, I think.

Then you also have the 80% chance of getting the random-Pirate Bounty, which also casts 3 times. The 3 Pirates would always sell for at least 3 gold, but some Pirates sold for more. Some had Battlecries that gave you more Bounties, and there was a Pirate in the game for quite a while that sold for 3 gold. So in a lot of situations, the Bounty that gave you 3 random Pirates was giving you closer to 4 gold on average.

So you had an 80% chance of 6 gold and an 80% chance of 4 gold. Between the two, you'd spend 9 gold and your average return was close to 9, but not quite.

The thing is, you could spend 9 gold by just buying 3 units and selling them. If you bought 3 random units with no economy effects and sold them, you'd only have lost 6 gold to spend 9. However, when you refresh, you don't get any refund. So that same bounded infinite probably wouldn't work in our game. Eventually you'd have to keep refreshing, and to spend 9 gold you'd actually have to lose 9 gold. You'd need additional economy effects on top of that return for it to still be infinite past that point.

One thing I forgot to mention: of course you wouldn't just buy units that cost a net 2 gold, where you spend 3 and get 1 back. You'd buy good economy units in the shop, and you'd roll more and get units that cost you much less than spending 3 and losing 2. You'd spend… *[The message was cut off here.]*

*[Editor notes on this follow-up:*
- *Bounties from Rogers go to hand and are free to cast. They cost 2 gold only when bought from the shop. So counting only the 9 gold spent is right.*
- *The arithmetic: 4 Bounties hold 0.8 Wealthy Bounties on average (the chance of at least one is 59%). 0.8 × 6 gold = 4.8, not 5.2. With the owner's ~4 gold per Friendly Bounty, the total is about 8 back per 9 spent (r ≈ 0.89). The repo's analysis, using 1 gold per Pirate, has r = 0.80 ([economy-engines.md §4.2](../../research/battlegrounds/economy-engines.md)).*
- *The owner's buy-and-sell point adds the part that tips Battlegrounds over 1. Spending through buying refunds about a third (1 of every 3 gold). With the shop's 1-gold refreshes included, about 0.3. So r ≈ 0.8–0.9 from Bounties plus ≈ 0.3 from selling, about 1.1–1.2: effectively infinite.*
- *The owner's later point raises this further. Buying economy units such as Freedealing Gambler (sells for 3) lets you spend gold at almost no net cost. The real cost then becomes the refreshes needed to find those units, which refund nothing.*
- *In Bramble two rules bound the loop. First, Friendly Bounty's Pirates are Created and sell for 0 (rulebook 4.3.3), which drops the Bounty return to r ≈ 0.53 (economy-engines.md §4.2). Second, when the spending comes from finding economy units, the binding cost is refreshes, as the owner says. Bramble's refreshes stay at 1 gold for the first 15 each turn and then rise (rulebook 4.4.3), so escalation limits long turns, not short ones.]*

#### Why Infinite Pirates added complexity without depth

*[Said while answering the depth-and-complexity question.]* I don't think anything adds complexity without adding depth, but some things add a lot of complexity without adding enough depth to justify it. When you add complexity, it leads to more possibilities, because that's what complexity is. More possibilities is going to be deep: it's stuff you can look at and potentially choose between.

Look at Sky Admiral Rogers and its tuning in Battlegrounds across various metas. It's in a better spot now, with Freedealing Gambler and some other things gone. The idea of what it was supposed to do was give Pirates this Bounty mechanic. You'd play into the Bounties for stats and take a lot of actions, but the Bounties weren't very powerful, so you'd only get small amounts of stats from them.

But the Pirate builds could always just use the money to play different comps. A lot of the time these Pirate builds used the infinite money to play Dragons. They'd put a bunch of Fire-forged Evokers on the board and cast so many spells that the Evokers got huge, then eventually sell all their Pirates and just play Dragons. They were strong enough the entire time by cheating: using the Dragons' scaling engine instead of their own. They did this with a number of other units as well. There was a Beast that, whenever it gained stats, gave your Beetles an additional +2/+2 for the game, or something like that. I can't remember what it was called. They'd steal other tribes' scaling engines and use the Bounties to play those tribes.

Because of the nature of the engine, once you got a Rogers and a Proud Privateer you had a lot of money, and you could use it to find more Rogers and Proud Privateers, which helped you finish the engine. Then you'd have so much money, and be so far ahead of everyone else, that you could play any tribe. And you'd be the best version of that tribe, because you had infinite money, and infinite is a lot more than any bounded amount.

So it added a lot of complexity without adding a lot of depth. Every single game was just looking for Rogers and Proud Privateer, because they were absolutely broken, and every other strategy was second best. The game became a race: sacrifice the early game, go up in tavern tier as soon as possible, and try to get lucky and get Bounties enabled. It added a lot of complexity, because there were huge cycling mechanics and you had to take heaps of actions very quickly. You needed to make an action every quarter of a second: keep going, really fast, high tempo, don't think too much, just spend gold and cycle. It added a ton of complexity without really adding any depth, because the strategy wasn't being played the way it was intended as its best version, and it cannibalised all these other designs. It wasn't because it was a bad design. It was because it didn't have the correct limits on it.

#### What the right limit is

You asked me about the pushback: what's the right limit? I don't know what the right limit is. But the answer is that there should be some limit that preserves the goal of the design. The goal is a comp about taking lots and lots of smaller actions and gaining a lot of incremental things: a large number of actions, each giving a small benefit. That contrasts with other comps that take a small number of actions with larger benefits, or that scale in combat through summons, or whatever.

### 4.3 Undead: flexible pieces that lean towards sub-strategies

I've quite liked a lot of the ways Undead have played in Battlegrounds. The units all feel like they work with one another and have synergy, but there are more powerful combinations and different variations of Undead that you move towards one way or another. Being in one gives you options to go into another, because you're enabling all of them. Units are just flexible enough to work in all the Undead strategies, but just different enough that they're significantly better in one or two of the sub-flavours.

For example, an Eternal Knight comp often works really well with Reborn, and it still likes attack-scaling Undead. But it just wants as many Eternal Knights and as much Reborn as possible. Early on, if you pick up some Eternal Knights, picking up Undead that give your units Reborn is really powerful. But that Reborn can also work well with Avenge Undead setups or token-summoning Undead setups. Because you've already invested in units that were good for whatever tempo strategy you were doing, you can maybe go in a different direction later. Those kinds of effects are really cool.

### 4.4 Quilboar: one tribe, several ways to play

I think Blizzard have done a better job of that kind of thing over time. Quilboar now have two or three different ways they play in the current meta, and they're very strong as a result:

- Buff the shop with Blood Gem Barrages, and either transfer gems off units in the shop onto units on your board using Gem Confiscations, or eat the shop with a Felboar.
- Buff your Blood Gems and apply them to your board directly whenever you play Choose One cards, with Turbo Hogrider.
- Play Blood Gems from hand that cast multiple times, using something like Geomagus Roogug and Hot-Air Surveyor.

You may need to go and find examples of all these things, and ask me additional questions about why I like them and how the things I've said are true, because there's a lot of nuance there.

## 5. Depth without complexity: Galaxy

*[Claude asked for a decision that is deep but simple. The owner first answered the inverse (Infinite Pirates, section 4.2), then this.]*

Galaxy is a really good example, as a game in general. Galaxy has a very dialled-back system. There's no gold; you just pick one of three. There's no choice in when you level up; the shop levels up for you over time. So you've lost two very real decisions: managing your economy, and managing your best time to level up.

But the game has an interesting enough tempo loop, and the cards are well designed enough, that picking one of three can actually be tough. Or one of four, because there's always a spell. Sometimes there are really good arguments for three of the four options. Give the same spot to top players and you get all sorts of different takes on the best play. I think that's because the cards are flexible enough to be used in a variety of ways, but also different enough in what they offer. Galaxy has struck a really good balance of giving a lot of depth while removing a ton of complexity. You take far fewer individual actions than in TFT or Battlegrounds, but those actions are distilled into the most meaningful ones.

A lot of the time in Battlegrounds, you look at a big shop filled with tier 1 units. Almost every tier 1 unit in the history of Battlegrounds is completely useless in the late game, and yet they're littered all over the shop whenever you refresh. So there are all these units that aren't contributing to making the player's decisions interesting every time you press refresh. It's a downside of the way they've chosen to do shop and pool mechanics. There are upsides, of course, but it adds a lot of complexity. You have to sift through lots of options and look at all these cards that most of the time aren't useful. Because of the time pressure, you have to build up a whole skill in Battlegrounds of erasing those cards from your mind. Your brain just skips over them and pretends they don't exist.

So by removing the options that are never going to be interesting, by removing the economy, and by making it pick one of three rather than one of seven, Galaxy finds a way to keep depth. I'd say the average Galaxy shop has more interesting units that could impact my board than the average Battlegrounds shop, because of unit replaceability and flexibility.

## 6. What agents need from this record

That nuance is obviously quite hard for an agent to capture, because it's quite an involved example. That's the kind of worry I have for this document. I want to make sure all of that nuance is captured. You mentioned there was a simulation piece of code. Whatever aids you can record for agents to understand this stuff and really get it, I want recorded in this markdown document. Even little bits of code that run a simulation, so the agent can say: because of this simulation, I now understand why this played out this way in the example. It's very difficult for an agent to get my example without the relevant context. So we need to give evidence in forms an agent can understand, even if it's just a mathematical simulation or a bounded equation.

There's heaps here to answer, and I'm going to keep missing things. So keep reminding me about the things I haven't answered yet.

## 7. Answers to the follow-up questions

When I'm happy with this, we'll figure out where to put the document. It will probably go somewhere most agents see it. I'm not sure what level of depth: we may need to split it into levels of detail, because some agents may not need everything and some may. But let's handle that at the end, when we feel we're done with the document, because that is the final goal.

### 7.1 The tactical play it takes to reach a solved comp

The tactical play is working with the fact that the shop doesn't offer you the best option every time. There are going to be strong early-game setups. Take Eternal Knight in Battlegrounds. One Eternal Knight in the early game is an okay unit, pretty good tempo. But two Eternal Knights in the early game can carry your entire early game. That doesn't happen very often, with Battlegrounds' pool size and the number of options you're offered. Especially on a hero like the Lich King or Teron, who can effectively double the value of Eternal Knight, you can almost use the tempo to go straight to tier 6 without making any other investment in being strong. But you don't get offered that every game.

The tactical play that gets you to the end game is figuring out how to make the best of what you've been offered, without being wasteful, versus looking for the pieces that are theoretically the best fit at the cost of spending a lot of gold refreshing. There's often a path to a pretty good result with what you've got, if you're creative. There's also a skill in being just selective enough to get something actually synergistic, rather than taking a bunch of units that are individually strong but have no synergy.

I think that's where the best players are separated from really good players. They know when it's worth spending a bit of their early-game economy on becoming strong now, because it'll save them enough HP that they won't have to spend money in two turns' time to stay strong. They can use that time to go to the highest tier and then get very strong at the end of the game.

### 7.2 How much bigger stats should be

My guess, without having done a ton of thinking, is about double Battlegrounds, because it gives you room to balance effects. It's very hard to balance a card in Battlegrounds like Timecap'n Hooktail or Felfire Conjurer. Let me give you the reasons.

Felfire Conjurer says that at the end of your turn, your Tavern spells give an extra +1/+1 for the rest of the game. Blizzard made various attempts to balance this card after they introduced it. The problem was that if you took either the Attack or the Health away, it became very weak. If it gave no Health, all your units would die after one hit: anybody with sticky units would just kill you, and your high-Attack board wouldn't matter. If it only gave Health, your units wouldn't have any Attack. You'd have a board of 1/10s, they'd have a bunch of 3/3s or 4/4s, and they'd clean you up despite you having more stats. So you just couldn't make it less good: if it became less good, it became useless.

But at +1/+1 it was very strong in a lot of situations. Most Tavern spells in the game at that time gave numbers like "give your entire board +1/+1" or +2/+2, and increasing that by +1/+1 two or three times in a row is a drastic increase in power. Anybody trying to play around cards that generate spells, without spell buffs, just couldn't compete with somebody doing it with a Felfire Conjurer. So that's an example of why I think we need more granularity. When an effect gives +1/+1, you don't have a lot of room to balance it. That doesn't mean you can't design any effects with +1/+1; it just makes it harder. It's much easier to improve an effect if the improvement isn't a literal doubling of its power.

Another example from Battlegrounds is Quilboar. Blood Gems give +1/+1 by default. The first time you play a card that gives your Blood Gems an extra +1/+1 for the rest of the game, every Blood Gem from then on is literally twice as strong. For most of Battlegrounds' history there were only two Quilboar cards that improved your Blood Gems. As a result they were absolutely mandatory, and you had to find them every single game. Otherwise you could play all the Blood Gems in the world, and someone playing literally a quarter as many Blood Gems as you, who has improved them four times, is actually a little stronger. So it became an incredible dependence on the buff cards.

In a hypothetical world where Blood Gems started at 2/2, the player who improves them by +1/+1 doesn't get twice as powerful; they get 50% more powerful. In the same example, if I'm playing 50 gems a turn to their 10, and they've improved their gems four times: in the first world we're equal, even though I'm playing five times as many gems. In the second world I'm playing 50 gems a turn and getting 100 in stats, and they're playing 10 gems a turn and getting 60. Changing the base from 1/1 to 2/2 is an enormous difference.

So whenever an effect is scaled or improved by stat amounts, it's very hard to balance if it starts at a low number. I don't think every number in our game should be double Battlegrounds. We just need to give ourselves room to move on effects that could be problematic.

### 7.3 Menagerie

Menagerie does mean mixed-type boards. There have been a variety of them in Battlegrounds' history.

### 7.4 Why I like bounded engines

I like bounded engines because economy is cool. Making more decisions is cool. It's fun. It's enjoyable to get the ability to do more stuff. People love that. It feels awesome, like the limits don't apply to them anymore. Players love that; it feels like they're breaking the game. The problem is that it's self-destructive and can destroy the game state if the engines are unbounded.

So I'm very happy for there to be lots of economy effects in the game, and I like it if they're varied in how they provide economy:
- Some give you spells.
- Some give you random units of a type.
- Some just give you gold.
- Some might give you additional weighted refreshes, or chances at discovering units of a specific type.
- Some might give you economy in two turns' time but none now, so it's about delaying.
- Some might give you random copies of units you already have, so you don't have to go searching for them.

The triggers that enable those economy effects can also be very different. Some might reward you for taking specific types of actions, playing specific types of units, triggering certain types of effects, and so on.

Bounded engines are really cool because they let players go into a strategy. Often any source of recursive value is something you can pick up in the early game, and it can lead you in a bunch of different directions in the mid game.

One of my favourite games ever: I had a reliable way of playing a bunch of Blood Gems with really high Attack but basically zero Health, like Blood Gems that gave 9 Attack and 1 Health. And I had a bunch of Tavern spell buffs that gave all my Tavern spells a lot of Health but no Attack. I gave my units a ton of Attack early with the Blood Gems, then sold all my Blood Gem stuff, played all these Tavern spells, gave my units a ton of Health, and won the game. It was a very atypical game, because normally you want to be in one or the other. I found a way of doing something unusual and overcoming adversity creatively, not through a normal strategy, because that was just what the game gave me. I liked that it worked. I liked that it was an available option that wasn't the standard path, and that you could still make something work if you're clever about it. That was all enabled by value engines and by strategies having strengths and weaknesses.

### 7.5 Strategies should have weaknesses

At that point in time, a lot of Battlegrounds strategies ended up with a mismatch: the board had a ton of Attack, or a ton of Health, or one or two big units and lots of small units that didn't get buffed at all. Your strategies having weaknesses made you evolve and adapt over the course of a game.

One of my problems with Galaxy is that almost always your units have about the same Attack and Health. It never creates the strategic problem you have to solve, which is interesting. It just gives you everything you need, and you're comfortable in the end game. Whereas still having a discernible weakness to address can be really fun, or at least really interesting, as long as there are multiple ways of solving it rather than just one. If you're pressing refresh to try to see one exact unit, and if you hit it you're really strong and if you don't you die, that's very uninteresting.

### 7.6 Sub-strategies within tribes

If you look at a lot of Battlegrounds' more recent designs, there are a lot more sub-strategies within tribes. For example, Murlocs have buffing units that are in hand, and keywords matter: buffing units based on how many keywords you have on board. Those are two different strategies, but they tie together a bit. Some of the same units work in both, and some don't. The strategies have overlapping pieces and also discrete pieces. If you have some of the overlapping pieces early, it lets you play for one or the other.

### 7.7 Quilboar and Blood Gems

Yes, Blood Gems are what make Quilboar work. Quilboar have always been either pretty amazing or kind of terrible, because they always had X-Y-Z scaling, whereas most other tribes had X-Y for a long time. Now pretty much every tribe has X-Y-Z; Blizzard has abandoned that. But in the past, Quilboar were the only tribe that could improve both how many times they cast buffs and how good the buffs were. Most other tribes could only change how many applicators they had and how many times they cast the buffs.

For example: "every time you trigger a Battlecry, your Dragons get +2/+2". I can find an extra copy of that, so with two of them my units get +4/+4 per Battlecry. But a Quilboar card could say "every time you trigger a Battlecry, play a Blood Gem on all your units". I could theoretically buff those Blood Gems up to 20/20 and still find multiple copies of the card. So Quilboar had three multiplying factors they could affect in their scaling.

*[Owner's note on the transcript: the dictation garbled "Quilboar" and "Blood Gems" many times. The owner fixed some and asked the editor to correct the rest from context.]*

## 8. More answers, and the filtering problem

### 8.1 Positioning as counterplay

Yes, positioning should hopefully be one of the ways to counter a strategy. What that needs is units that really care about positioning, maybe with different targeting rules:
- units that only attack units in the back;
- units where something interesting happens if they attack a unit in a certain position: they get a bonus effect, or don't take damage, or whatever;
- things that summon a copy of the unit to their left if something happens, so the unit to the left doesn't have to survive. Then maybe someone plays a card that counters that strategy;
- cards that attack the lowest-Health units.

Positioning should be one of the ways to counter a strategy. It doesn't have to be much; it should just matter a bit. Positioning should feel relevant. I don't think changing position has to be the biggest aspect of the game, but it should be a tactical and strategic motif.

### 8.2 Sub-strategies per tribe

Whatever fits the design and works. I think it's pretty hard to get more than three working at once, but sometimes things just naturally work well together.

### 8.3 A third scaling factor

That one I don't know the answer to. I'm so torn on it, because once you've introduced it to the game, everything merges together. It's harder for anything other than the A-B-C to matter, and you need a good mix of each, because that's how multipliers work. But players clearly like it. I'm really torn.

When Battlegrounds first released, pretty much nothing had it except Quilboar, and Quilboar were always the problematic tribe because of it. Now pretty much every tribe has A-B-C, and it's changed the game a lot.

### 8.4 The Beetle card

I honestly can't remember. It was from a patch six or seven months ago, and it's been removed from the game. It was a tier 6 Beast. It basically said that whenever it gained stats, all your Beetles this game are bigger. I think it was called Silky Shimmermoth, if that's what it was called.

### 8.5 Feel-bad moments, and judging designs

There are other feel-bad moments, and we'll learn as we develop. I don't know the answer to that question yet; we'll see as things go forward. I think all designs can be tuned to be better designs, so nothing's necessarily a dead end. That said, that's not useful, because something has to be thrown out to make room for whatever you eventually decide is the best design. So I'm honestly open to suggestions here.

I know agents are incredibly good at bounded tasks, and it's very, very hard for agents to be good at this subjective, unbounded task of having taste. It doesn't have a nice, clean evaluation criterion. You can't do any sort of hill climbing or gradient ascent or descent with it. And agents can't understand the games, because they can't get their hands on them themselves. You don't play games the way humans do, at least. So it's entirely impossible to get this feeling right. It's impossible for human designers as well, by the way. We have so many advantages over you here, and yet we can't do it perfectly either, because every human is different and has different tastes. You just can't know.

So I have this challenge. I expect agents will come up with a lot of good designs and a lot of bad designs. I'm worried that if I let agents judge them, you might not judge them the way I'd like. Some of the good designs will get buried and I'll never see them, lost in heaps of sub-agent turns and sub-session turns I never saw and documents I never read. On the other hand, I can't be presented with 200 options and filter them all without getting overwhelmed, especially at the pace agentic development happens. So I need some sort of filtering.

I actually don't know what I want here. I'm trying to work through it. It's my biggest problem right now with the entire project.

*[Editor note on 8.4: the library's Silky Shimmermoth is a tier 6 Beast, 3/12: "Whenever this takes damage, your Beetles have +2/+2 this game. Deathrattle: Summon a 2/2 Beetle." It was in the pool from 29 April 2025 to 21 July 2026. The library keeps only each card's latest text. The owner confirms the earlier text below.]*

### 8.6 Shimmermoth, confirmed

I definitely didn't remember Shimmermoth incorrectly. They probably changed it precisely because of the problem I just described. It used to say "whenever it gained stats", and it was the card that made the Rogers comp broken. I assume it was changed and then removed because of that: they changed it, and it no longer worked.

### 8.7 The problems with learning from my reactions

*[Reply to Claude's proposal: keep every design, show the owner small batches with random slots, log reactions, and score how well a reviewer agent predicts them.]*

The problem with learning from my reactions is the time it takes. Look at the timestamps of this session. We've been here for quite a while, and I've done nothing but engage with you the entire time. Your turns take about a minute, but I haven't taken a single break between my responses; I've been thinking the entire time. Directly giving you these ideas and scoring is a large time cost. Maybe that's something I just have to do, and there's no way around it. You could be right.

But also, whenever you develop a scoring system, what gets measured gets made. Agents will start developing designs to fit my scoring system, or whatever they think it is. And the reality is that this is a bit artistic in nature. It's a bit unbounded and a bit subjective, and even my opinion on a given day will change, because I'll receive new information about a design.

I can be wrong about my own opinion, by the way. Many times I've thought something was bad, then tried it out and got to know it better. As I learned more and engaged with it more, or saw it in a different context, or something else changed that recontextualised the design, it turned out better. For example, it works better once something else it was interacting with is gone. That can happen all the time.

We could implement it, but it does have those downsides.

### 8.8 Mental effort, not time

With review, I'm not so worried about the time; I'm more worried about the mental effort. I've actually quite enjoyed this dictation with you. This process has felt more fun and more collaborative. It's easier to dictate my chain of thought and focus on one thing at a time.

A lot of the time agents generate a long list for me. *[The owner asked Claude not to turn this into a rule: "I have concerns about you doing so, so hold off, please."]* When I see a really long list, I think: I have to get through all 15 of these things. That's a lot to answer. Going through the problems one by one, each feels approachable. That said, I also have concerns about not being given the long lists, because then what if items are never surfaced and get lost, because I don't continue with the next problem in the chat, thinking everything's fine?

I think the way we structured this, exploring more and more things as time went on, worked really well, and I don't mind doing as much. But I can get overwhelmed when there are a lot of things to work on at once. That gets much worse when I'm working on several projects at the same time. At the moment I'm focused on Bramble only, and just this session. But when I have other projects running at once, Webatrice, Anagrind and other smaller ones, it gets overwhelming.

I think that's partly something agents can't help me with, and I have to figure out my own ways of working with you. Maybe I need a step-by-step skill that takes a long list of things and goes through it one by one, like we've done here, because this process feels good to me. I actually enjoy it. The time isn't much of a concern as long as I don't find it mentally draining and unenjoyable.

---

*[Editor notes:*

- ***Name corrections.** The dictation said: "soft comps" (→ solved comps; the question asked about "somewhat solved comps"), "poisonous" (→ Venomous, the current Battlegrounds keyword; older cards said Poisonous), "Leroys" (→ Leeroy the Reckless), "Sky Pirate Rogers" (→ Sky Admiral Rogers), "Quillballs" (→ Quilboar), "Fellbore" (→ Felboar), "Turbo Hog Rider" (→ Turbo Hogrider), "Ragoog" (→ Geomagus Roogug; the owner flagged this one), "Hot Air Surveyor" (→ Hot-Air Surveyor), "mid-rangey stats" (→ mid-range strategies), "Frida and Gambler" (→ Freedealing Gambler, in the pool until 21 July 2026), "Fireforged Evokers" (→ Fire-forged Evoker, tier 6 Dragon: "Start of Combat: Give your Dragons +2/+2. Improves permanently after you cast a Tavern spell.", in the pool April 2025 to September 2026). The Beast that buffed Beetles "whenever it gained stats" isn't identified: no Beetle card in the library has that trigger. The nearest are Silky Shimmermoth ("whenever this takes damage") and Runed Progenitor ("Avenge (3)"). To be confirmed by the owner.*
- ***Section 7 corrections.** "Terron" (→ Teron Gorefiend, hero power: "Choose a friendly minion. Start of Combat: Destroy it. When you have space, resummon an exact copy."). The Lich King's power is "Give a minion Reborn until next turn." Both give an Eternal Knight an extra death. "Captain Hooktail" (→ Timecap'n Hooktail, tier 3: "Whenever you cast a Tavern spell, give your minions +1 Attack."). "Fellfire Conjurer" (→ Felfire Conjurer, tier 5 Demon/Dragon: "At the end of your turn, your Tavern spells give an extra +1/+1 this game."). "Quillbores", "Coolball", "COBOL" and similar (→ Quilboar). "battle cry" (→ Battlecry).*
- ***Blood Gem buff cards today** (library): Fearless Foodie (+1/+1, a Choose One option), Sanguine Refiner (+1/+2), Sanguine Champion (+2/+1), Moon-Bacon Jazzer (+1 Health), Prickly Piper (+1 Attack), Dreaming Thornweaver (+1 Health). Which two cards the owner means for "most of Battlegrounds' history" isn't checked; the library keeps only latest texts.*
- ***"Menagerie comps."** Confirmed by the owner (section 7.3): mixed-type boards.*
- ***Where this meets existing docs.** Section 3 (bigger numbers) bears on the power budget, which is built on Battlegrounds' stat scale. Section 4.1's "about 10 spells a turn for +50/+50 to +100/+100" is a concrete target for a bounded engine; compare the owner's existing target of 20–30 shops a turn for the strongest engines (effect-taxonomy.md, economy-bounding.md).]*
