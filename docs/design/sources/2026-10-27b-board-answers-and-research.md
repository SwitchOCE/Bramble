# Owner notes: board answers, combat model and research

Dictated by the owner on 27 October 2026. This is the second note that day: the owner's answers to the questions in `../direction-summary.md`, plus new direction.

**How this record was made.** The wording is the owner's, kept as close to the original as possible. Only the following was changed:

- Filler words, repeats and dictation errors were removed, and punctuation was added.
- The notes were reordered into sections.
- Notes in *[italic brackets]* are the editor's (Claude's) reading. They are not the owner's words.

---

## 1. The board

**Staggering** *[question 1]*: Yes, agree on the staggering. That's exactly correct.

**Board size and row caps** *[question 2]*: Board size will still be 7 total. I'm not sure on row caps yet. Maybe we just have a 4–3 cap, or a 3–4 cap. I'm not sure; we'll experiment with that. That's still up for debate. I know we're going to have a 7-unit board for now. In terms of whether you could have a 7–0, or whether you can have a 6–1, or whether you're only allowed a 2–5 or a 5–2, or a 4–3, I don't know. And I also don't know how it works when it's less than fully filled. Maybe we need to think about this more. The idea is I want to be able to have more card designs that are flexible.

**"Behind" and "in front of"** *[question 3]*: Yes. Anything that sits in between a unit counts as behind or in front, because they're all sitting between each other, right? The rows are staggered at 50%, so you have this kind of triangle shape. If you imagine the connection between two units in the front or the back, and vice versa: the units that are split off at 45 degrees in either direction, forward or backwards, are the ones that are connected. So those are behind or in front of.

*[Reading: each unit's diagonal neighbours in the other row are "in front of" or "behind" it. A unit has at most two of each.]*

**Targeting** *[question 4]*: No, not by default, but we may have mechanics that allow players to do that. Maybe stuff like overkill damage splashing through as a keyword, or something that specifically targets back-row characters rather than front-row characters, etc.

*[Reading: back-row units can't be attacked while any front-row unit is alive, unless a mechanic says otherwise.]*

**Attack order** *[question 5]*: Yes, you're correct on attack order. That's exactly how it works. Every unit attacks once, unless it has something that allows it to attack multiple times in a row as a keyword, something like the equivalent of Windfury from Battlegrounds.

## 2. The combat model, and the previous project

I saw that you had a good read of the existing Autobattler repo. I want to go away from that kind of context where the player has an in-fight HP model. Also, that project was not well run. I was too unsupervised at the beginning, and as a result I wasn't a big fan of some of the outputs at the end. This is a second attempt at auto-battling.

I want the units, the board, to be the HP for the fight. It leads to a deeper, more strategic and more interesting fight dynamic, because there's more RNG in the fight, so the stakes feel higher for the player as well.

*[Reading: as in Battlegrounds, a fight is won or lost by the units on the board. The player's own health isn't part of the fight.]*

## 3. Economy

*[Questions 6 and 7]* The reroll count does reset each turn. And there is no cap on carried-over gold, and we will not have interest.

## 4. Tiers and the pool

Unit tiers, the pool mechanics, etc.: we should base those off Battlegrounds and revisit as needed.

## 5. A full rulebook, and deep research

We should probably document a full rulebook, and I can go through the full rulebook and go, "okay, where do we differ from Battlegrounds?" as problems arise. That should be a task that you should perhaps have a sub-agent do.

We're going to need extremely deep research and documentation on how Battlegrounds works and how Galaxy works, and how they have changed over various patches. Plus as exhaustive a content library of designs from those games as we can get, which we can use for referencing power budgeting, etc.

## 6. Power budgeting and fundamentals first

We are going to want detailed power budgeting. You looked at some of the comments I made in the previous Autobattler chat, and the lack of power budgeting and a bottom-up approach was, I think, a large issue. So we really want to make sure that we have our fundamentals in order before we go into content design.
