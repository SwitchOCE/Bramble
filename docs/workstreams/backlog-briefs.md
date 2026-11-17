# Backlog briefs

One short brief per backlog item, so an agent can pick one up cold, at the start of an overnight run, without guessing what the owner wants. Started 17 Nov 2026 in the scope interview with the owner. The owner's words for every brief here are in [sources/2026-11-17a](../design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md); each brief quotes the line it rests on.

**How to read a brief.**
- **Wanted:** the owner's words. They win over everything else in the brief.
- **Bar:** what the work is held against: a mock-up the owner approved, or reference clips. Without the bar, the item isn't ready.
- **Done when:** checks an agent can run. Feel, motion and look still need the owner's eyes; say so in the morning pack.
- **Agent decides:** make the call, log it as a taste call (`overnight-run` skill), keep it easy to redo.
- **Ask first:** stop and bring it back to the owner.
- **Not in scope:** leave it alone, even if it looks like a quick win.

How a night is run and reported is in the global `overnight-run` skill; in-game text follows the `ux-copy` skill; the look is lead and stained glass ([art direction](../design/art-direction/README.md)). Briefs don't repeat those.

**State, 17 Nov.** The owner: "these are kind of all relatively high priority and can all occur right now in the overnight run tonight, if we get the concrete bars set and we get the scope in terms of some mock-ups done in terms of me getting happy with where things are at." So each brief below says what it still needs before it can start.

---

## 1. Gold coin and shop prices

**Wanted.** "I don't want the acorns as gold anymore. I'd rather have like a gold icon ... shiny and bright and it's easy to see." And "little gold price tags on things, maybe like little labels coming off the bottom of the cards, or maybe we put something more diegetic in the shop, like have like pedestals where the cards are essentially for the shop slots ... evoking the idea that they are things on sale".

**Bar.** A mock-up of the shop the owner approves, with the coin and one of the two price styles (tags hanging off the card, or pedestals under the shop slots). *Needs: the mock-up, and the owner's pick.*

**Done when.**
- The gold coin replaces the acorn everywhere gold shows: the gold counter, shop prices, sell value, tier-up cost, refresh cost.
- Every shop card shows its price in the approved style; the price is right for every card type in the shop, spells included.
- The recruit screen matches the approved mock-up, region by region (`tools/look/compare.py`), and is shot at 1920 x 1080 and 1366 x 768.

**Agent decides.** The coin's drawing within the glass look; where the price sits on cards of odd sizes; what a price looks like when you can't afford it.

**Ask first.** A third price style; prices on cards outside the shop.

**Not in scope.** Changing any price.

## 2. Keywords and tooltips

**Wanted.** "I want keywords to be color-coded ... have a color or an icon as well as the word to make them more recognizable. Look at the bazaar for an example." "Something like a tooltip like burn or ignite and just have a number next to it ... it can replace long sentences with short sentences. That's the purpose of a keyword." "The reminder text that's in italics to be in a separate tooltip." "Hold alt ... and it freezes the tooltip in place, and you can move your cursor over burn and it explains how burn works. So ... if we have a card with 3 or 4 keywords, we don't have to have all the descriptions on screen at once".

**Bar.** Reference clips of a player hovering tooltips in The Bazaar, ideally from a new-player video (found by the agent, cut short, kept in R2 per `tools/assets/`). A mock-up of one card's tooltip, closed and with Alt held, that the owner approves. *Needs: the clips, and the mock-up.*

**Done when.**
- A card's tooltip shows its keywords as a coloured mark with an icon, the word and its number (for example "Fury 1"), and no italic reminder text.
- Holding Alt freezes the tooltip; moving the pointer onto a keyword opens that keyword's own tooltip with what it does. Letting go of Alt closes both.
- Every keyword in the game has a colour, an icon and one short line of reminder text. Colour is never the only difference between two keywords.
- Keyword marks read at 1366 x 768. The hardware check on the owner's PC (17 Nov) found labels 6 to 7 pixels tall there.
- Shots of the mock-up's card and the built one, side by side.

**Agent decides.** The colours and the icon drawings (as a sheet first, so they can be swapped in one place); whether Alt or a held pointer opens detail too; a hint that Alt exists.

**Ask first.** Taking words off a card that aren't a keyword's reminder text; a new keyword to shorten a card.

**Not in scope.** Changing what any keyword does (except brief 7).

## 3. Refresh counter

**Wanted.** "There's a certain number left until the price increases that needs to be made visibly like indicative. Maybe just like X left until price increase, just subtly above it, or maybe have like a little countdown thing ... Just something subtle".

**Bar.** The shop mock-up from brief 1 shows it. *Needs: that mock-up.*

**Done when.** The refresh button shows how many paid refreshes are left this turn before the price goes up (rulebook 4.4.2 to 4.4.5: 10 at 1 gold, then steps of 5, reset each turn, free refreshes don't count). A test walks a turn across two price steps and checks the number each time, and that a free refresh doesn't move it.

**Agent decides.** Text or pips; how subtle.

**Not in scope.** The refresh rules themselves.

## 4. Duplicates in the shop

**Wanted.** "When you see a duplicate of something, there's like a shader effect on it ... We might want a shader effect or maybe a glow". The earlier list adds: when a triple is close, and maybe on rewards too.

**Bar.** Reference clips of how Battlegrounds, TFT and The Bazaar mark a shop card you already own. *Needs: the clips.*

**Done when.** A shop card that matches a unit you own (board or hand) is marked; a card that would complete a triple is marked more strongly. Filmed with `tools/feel/film` and shown next to the clips. Two or three candidates if the call is close.

**Agent decides.** The effect.

**Not in scope.** Rewards and Discover picks, unless it costs nothing extra.

## 5. Triple animation

**Wanted.** "Get some footage of triple animations in, or level up animations or combination animations in the Bazaar, in TFT, in Battlegrounds, and use them as a concrete bar ... cut down the clip to a small size so that agents can compare against and go, is our animation like taking inspiration from these and better than them, or of a similar quality level? At least is it doing the same types of things, right? It's building the same sense of excitement."

**Bar.** Short clips of combining in The Bazaar (item upgrade), TFT (three units into a star-up) and Battlegrounds (triple into a golden), each a few seconds. *Needs: the clips.*

**Done when.**
- Three copies forming a triple plays an animation in the recruit screen, ending on the golden card where the rules put it.
- A film of ours at 60 frames a second sits next to each clip, with a list of the beats each reference has (for example: gather, build-up, flash, reveal, reward) and which ours has.
- The animation never blocks input for longer than the longest reference does.

**Agent decides.** Everything about the motion. Log it; two or three candidates filmed if close.

**Ask first.** Sound (no agent can hear).

**Not in scope.** The golden card's own look (still a stand-in).

## 6. A rough power check for utility effects

**Wanted.** "Agents need to be able to find this stuff. And we need to introduce some sort of way of having them measure the strength of utility effects without having it be exhaustive simulations of millions of fights. Just a small, like, mock-up of, like, 10 scenarios and ... a couple of parameters to kind of get a feeling, some heuristics about how good the effect is ... It, like, effectively acts as an X3 multiplier for stats ... a unit with this on average ... outputs 2.5 times more damage than a unit without this utility effect ... They need to come up with a heuristic that gives them a rough power budget for it. And it needs to be rough."

Why: "Agents are currently, as a general rule, vastly underestimating how strong the utility effects they're designing are. They're overestimating how powerful the stat boosting effects are." "Summoning an extra body is very powerful. It lets you double dip on slot buffs ... sticky units essentially, are very good. Anything that lets you trade 2 for 1, or ... trade 1 for 1 and win a fight ... can be very powerful if built around correctly." "I don't want to completely eliminate creativity".

The shape the owner gave first: two plain boards of equal stats; add the effect to one; raise the other's stats until they're even. "It doesn't have to be that exact thing."

**Bar.** Before being told, the check rates Hit as one of the strongest effects in the game, Cleave as very strong, and a plain stat buff at about its own stats. The owner: "Something like Cleave is incredibly good. Something like Hit is unbelievably good."

**Done when.**
- About 10 small scenarios and a couple of parameters, worked by hand or with a few fights on the build's fight engine, give each effect one rough number: "about ×N stats" or "about N times the damage of the same unit without it".
- It is a step in the `bramble-design` skill's costing, next to the [tier guide](../design/tier-guide.md), with the owner's words above quoted: run it on any new utility effect and give the number when pitching a card. *The skill change waits on the owner's yes.*
- One line per effect for Hit, Cleave, a summon, a plain stat buff and the pigeon row-hit board ("the pigeons have a strategy where they can have the entire row hit the enemy's front row ... you just win every fight").

**Agent decides.** The scenarios, the parameters and the heuristic itself.

**Not in scope.** "I don't want them doing endless simulations and ... writing Python scripts that simulate a million different boards." No bots, no whole games, no large sweeps.

## 7. Hit made much weaker

**Wanted.** "In its current form, it needs to be tuned back. You can't go the full way of giving it immunity to damage ... a free hit is a pretty big deal." "It could be ... made worse in any number of ways. It doesn't necessarily have to be that it takes some damage on the hit. You could have a smaller free hit that does less damage, or it's way harder to trigger and activate and it's much rarer ... It just needs to be way less strong ... I don't really care how it's made worse, as long as it's thematic and it fits the tribe and ... it's still cool. Or maybe we just remove it and get a different mechanic." Why: "it's just not fun to play against. It kind of undermines the core gameplay of units attacking and trading in combat ... can damage the excitement of the fight." Earlier the same evening: "I think hit should be changed maybe to like ambush as a word" and "dealing damage without [taking] damage back is like the highest form of utility ... should be preserved for very like singular cards and or capstone effects".

**Bar.** The power check (brief 6) puts the new version well below today's Hit, and the morning pack gives both numbers.

**Done when.** Every card with Hit, or that gives Hit (Master of Engines), and the pigeon row-hit board, are changed or replaced; the shared rules and card text match; tests and the soak pass.

**Agent decides.** How it's made weaker, or a different mechanic in its place, as long as it is thematic, fits the Mice, and is still cool. The name (the owner's idea was Ambush). Log the choice and the reason.

**Ask first.** Keeping any card that deals damage and takes none back.

**Not in scope.** Other tribes' effects, beyond the pigeon board named above. Rebalancing the rest waits for balance work, after the UI work.

## 8. Game records

**Wanted.** "A data collection mechanism that records essentially a log of the game that can reconstruct a game exactly, and have it be relatively efficient and non-wasteful in terms of its storage". "For now it can be a manual export ... that way agents can get tangible run data and also from bot games." "We need a data collection system first before setting up any web server".

**Bar.** Exact replay: a record rebuilt into a game gives the same state at every turn.

**Done when.**
- Every game, the owner's and the bots', writes one record: the build it was played on, the seed, and every player's actions.
- A replay tool rebuilds the game from the record. Over many bot games across seeds, every turn's state matches what was recorded; the tool says the first turn that differs if one does.
- The owner can export records by hand (a folder they can zip, or a button), and the size of a typical record is reported.
- A record holds each player's board at each fight, so ghosts come from it.

**Agent decides.** The format; what is stored and what is rebuilt.

**Ask first.** Anything that sends data off the PC.

**Not in scope.** A server, the network, dashboards.

## 9. Card browser

**Wanted.** "An in-game compendium, some way of seeing all of the cards that are in the game and browsing through them in a card browser that makes sense. Battlegrounds has one ... TFT has one as well. They actually have a build [planner] tool. Maybe we can find footage of it for a concrete bar".

**Bar.** Reference clips of the Battlegrounds and TFT browsers. A mock-up of ours the owner approves. *Needs: the clips, and the mock-up.*

**Done when.** From the start screen the player can see every card in the game, filter by tribe and tier, and hover any card for the same tooltip as in the shop (brief 2). It matches the approved mock-up.

**Agent decides.** Sorting, search, whether it opens during a game too.

**Not in scope.** A build planner.

---

## Left in the backlog, on the owner's word

- **Tips on loading and transition screens.** "Just backlog that ... We'll just leave that unresolved."
- **The lock keyword.** A unit that "bounces off your board into your hand after a fight. And look, I'm not sure if we need it yet. The lock keyword can stay in the backlog for now."

## Not covered yet

From the map of 17 Nov, still to go through with the owner: the window that doesn't fit the screen; buying by dragging onto a slot, the drop mode, chips or plates; fight animations and pacing; the open rules ("after fight", effect order, the twelve build calls, which rules win); balance feedback and card checks; sound; the way of working.
