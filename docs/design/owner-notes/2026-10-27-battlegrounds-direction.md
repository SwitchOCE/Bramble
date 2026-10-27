# Owner notes: the Battlegrounds direction

Dictated by the owner on 27 October 2026.

**How this record was made.** The wording is the owner's, kept as close to the original as possible. Only the following was changed:

- Filler words, repeats and dictation errors were removed, and punctuation was added.
- The notes were reordered into sections. The owner asked for this so the thoughts read in a structured way.
- Notes in *[italic brackets]* are the editor's (Claude's) reading of what was meant. They are not the owner's words.
- One passage the owner withdrew while speaking ("cut that part") was left out.

The owner also gave instructions about this record itself, plus the repo and session setup. Those are at the end.

---

## 1. The overall direction

I want to take this auto-battler in a direction similar to that of Hearthstone Battlegrounds, but also a little similar to that of Once Upon a Galaxy. I'm going to talk about this from the rules perspective of Hearthstone Battlegrounds, the systems perspective of Hearthstone Battlegrounds, and the differences that our game's going to have.

## 2. Economy

### 2.1 Gold carries over

Firstly, unspent gold will carry over between turns. Hearthstone Battlegrounds does not have that.

### 2.2 Created units don't sell for gold

Created units, i.e. tokens, anything that comes from being created, do not sell for a gold like in Battlegrounds. Anything you buy does sell for a gold, but anything you create does not. So a Battlecry unit that created two elementals: those elementals would be created rather than purchased, so they would not sell for gold.

*[In Battlegrounds every minion sells for 1 gold, tokens included. Here, bought units sell for 1 and created units sell for 0.]*

### 2.3 Reroll costs escalate

Reroll costs will be 1, just like in Battlegrounds, but after a certain number of rerolls we'll have an escalation-in-cost system. I don't know how many rerolls before the costs start rising. Let's say 10. I don't know if 10 is the number; we should keep this flexible. But after a certain number of rerolls, costs will rise. So the rerolls are 2 per, and at some point they go to 3 per. And I think that's probably enough to stop a lot of the generate-infinite aspects of Battlegrounds. We still want people to be able to go crazy with the economy, if possible, but have reasonable limits or diminishing returns.

*[Reading: rerolls cost 1 gold, then 2 after a first threshold (first guess: 10 rerolls), then 3 after a later one. The thresholds are tuning values, not fixed rules.]*

## 3. The board: two rows

Secondly, our positioning system will not be 7 board spaces left to right, like Hearthstone Battlegrounds is. There will be 2 rows the player can place units in, and they could do something like 6 in the front and 1 behind, or 3 in the front and 4 behind, or 1 up front and 2 behind.

And the rules are: row 1 attacks and defends. Row 1 attacks first and is attacked first. And when no row 1 units are able to attack because they've already taken their turn, the row 2 units, the back line, attack left to right. So it's the same system as Battlegrounds, left to right, with an extra rule about rows, but the player has the flexibility to position forward or back for the rows.

And the rows should always be offset by 1, essentially. So even if you had 3 and 3, imagine the first row has a position 1 slot. The thing directly behind it, in the row behind, would be diagonally positioned between the 1 and 2 slots. I don't know how to word this correctly. You'll have to reword this in the dictation. But you can ask clarifying questions about this particular point.

*[Rewording, to be confirmed: the two rows are staggered like bricks in a wall. A back-row slot doesn't sit directly behind one front-row unit; it sits in the gap between two of them, so each back-row unit is "behind" two front-row neighbours. The open questions are in `../direction-summary.md`.]*

## 4. Tribes, positioning and keywords

We're going to have a lot of similar mechanics to Battlegrounds in terms of tribes, and having a certain number of tribes per game in the pool to keep things varied. But unlike in Battlegrounds, we'll have the concept of this front and back row, which gives us more design space.

This is where the more Galaxy aspects come in. Battlegrounds has a lot of stuff like "when you attack, your rightmost unit…" or "your leftmost unit…". I want to expand on that kind of stuff with more "when you attack, the units behind this…", or "the units in front of this gain X when something happens", or "when the unit in front of this dies…". Have some more positioning-based aspects.

Additionally, we want to look at potential keywords that exist in Battlegrounds, but also in other games, Galaxy etc., for cool abilities that we could give to our cards.

## 5. Cards, types and traits

Because we're Battlegrounds-related, obviously all of our units are cards, right? They're cards, they have attack and defense, and that's like their attributes. They probably have a type. Maybe they have a species type, kind of like Magic: The Gathering creature types, as an example. "I am an owl warrior. I am an owl scholar. I am a squirrel farmer", or a squirrel archer, whatever it might be. The idea of races and types.

And we could explore looking at a trait system similar to TFT, although I'm not sold on that at all.

## 6. Setting and roster

We can also explore adding to our lore. We're in a fantasy setting; we can have some more magical-type creatures, I guess. We could have fairies, right? I think that makes sense in a little woodland realm. It's very, very magical.

I was thinking of something like oozes, with ludicrous high-pitched voices, kind of like Viscous from Deadlock, as an example. That's not a perfect example, but something that lets us do some more interesting mechanics, maybe some sort of amalgamation mechanic. Stuff that gives us more ability to do cool mechanical stuff, rather than just what the woodland creatures would constrain us to.

We're going to want to go with a smaller number of the woodland things, and I still haven't made my decisions on those, so just keep that as an outstanding thing.

## 7. How the game should be built

When development begins, the focus should be on good, reusable architecture. We don't care about rushing towards delivery. We want to be able to iterate content, and iterate content well. We want robust code that has a clear architecture and a clear layer separation that allows us to modify things quickly and easily, with solid documentation. The focus is going to be on real quality and adaptability.

So, for example, when creating a function for something like a pick one of three, it needs to have pretty flexible input parameters. For example: pick one of three units from a pool, using the random generation algorithm of this particular pool. We might want to have multiple different functions for random generation and selection, rules in terms of what is allowed to be in the selection pool, things that might be removed, etc. We want to have adaptable functions that are also performant.

I definitely want the ability to add warping game-rule modifiers later, which is why architectural separation is really key. If you look at something like Battlegrounds, with its anomalies or trinkets or quests or any of the crazy things that they've done, I'm pretty sure the game is a complete architectural mess and spaghetti code, because things consistently break. We need to have that architectural separation, and the ability to override specific parts in our responsibility chain, I guess. Or not responsibility-chain architecture; I'm not sure. You could recommend that and think about it deeply.

*[The recommendation is in `../architecture-notes.md`.]*

---

## Instructions given with these notes

- Create a repo for this on this computer, same as the other repos, and maybe one on GitHub as well, under a code name for now. It can be renamed later.
- Move this chat, and all future chats, to that repo.
- Record what was said as close to the original as possible: remove dictation problems (misheard words, missing punctuation and formatting, ums and ahs, repeated words) but don't reword, so no nuance or context is lost. Reordering for coherence and short explanatory preambles are fine, as long as the dictation stays accurate.
- Summarize the whole message, so the owner can make an action plan from the summary.
