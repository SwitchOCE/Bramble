# Design pillars

**Status: draft for the owner's review, 2 November 2026.** The owner asked for "short pillars": one page of what Bramble values and avoids, drawn from the owner notes ([2026-11-02 note](owner-notes/2026-11-02-pre-development-design-pass.md), answers to the plan check).

Every pillar comes from the owner notes in [owner-notes/](owner-notes/) or from [direction-summary.md](direction-summary.md). Quotes are the owner's words **[data]**. The grouping and the "meaning" lines are Claude's reading **[judgement]**. If a pillar and the owner's words disagree, the owner's words win. Pillars the owner hasn't stated are not here; they are open questions for the owner.

Note names below are short: `10-27` is [2026-10-27-battlegrounds-direction.md](owner-notes/2026-10-27-battlegrounds-direction.md), `10-27b` to `10-27f` are the other 27 October notes, `11-01b`/`11-01c` are the art notes, `11-02` is the pre-development design pass.

---

## The game

**1. Battlegrounds is the base. Every difference has a reason.**
Bramble starts from Battlegrounds' rules and systems. A rule changes only when it serves a Bramble goal, and the rulebook marks each change.
*Source: 10-27b §4, "we should base those off Battlegrounds and revisit as needed"; §5, "where do we differ from Battlegrounds?"*

**2. The board is the fight.**
Units are the fight's HP; the player has none in the fight. Combat randomness is welcome, because it raises the stakes.
*Source: 10-27b §2, "I want the units, the board, to be the HP for the fight", "there's more RNG in the fight, so the stakes feel higher".*

**3. Position is new design space, and it must earn its place.**
Two staggered rows exist so cards can say "in front of" and "behind", which Battlegrounds can't. If the rows don't add depth over Battlegrounds, they go.
*Source: 10-27 §4, "Have some more positioning-based aspects"; 10-27b §1, "I want to be able to have more card designs that are flexible"; 11-02, "if they're not working, we can just cut them".*

**4. Big economy turns for everybody, never infinite.**
Strong economy effects are fun and should be common, not rare. The best engine runs for a very long turn (about 20-30 shops) and then runs out of gold. There is no turn timer, so an infinite would let a player sit and play until their power means nothing.
*Source: 11-02, "we do want to have really powerful economy effects, because those things are fun", "a better situation where everybody has them", "a very, very long time, but not infinitely", "No turn timer at all"; 10-27 §2.3, "go crazy with the economy, if possible, but have reasonable limits or diminishing returns".*

**5. Magic widens what cards can do.**
Fewer woodland species. Fairies and oozes are there because they unlock mechanics animals can't. Mechanics should suit the creature they're on.
*Source: 10-27 §6, "more ability to do cool mechanical stuff, rather than just what the woodland creatures would constrain us to", "It's very, very magical"; 11-02, mechanics that "flavour-wise suit some animals".*

**6. Every game plays differently, and the tribes are balanced.**
A subset of tribes each game keeps lobbies varied. A tribe is a broad creature kind that supports clear strategies: economy, wide boards, scam units, scaling. The target is 10 tribes, in power balance.
*Source: 10-27 §4, "a certain number of tribes per game in the pool to keep things varied"; 11-02, "strategy development and variation", "We want power balance", tribe as "Broad creature kind".*

## How Bramble is made

**7. Fundamentals before content.**
A bottom-up power budget comes before any card design. Economy and scaling text are priced like combat text, more strictly than Battlegrounds prices them.
*Source: 10-27b §6, "we really want to make sure that we have our fundamentals in order before we go into content design"; 10-27e #11, "Stricter than Battlegrounds".*

**8. Roughly right, then iterate.**
Budgets have a tolerance band (±15% plain, ±25% economy, scaling and engine cards) because some prices will be wrong. Numbers stay tunable and are revisited as problems appear.
*Source: 11-02, "We're going to get things wrong. That's okay. We're going to iterate and catch those things later"; 10-27 §2.3, "we should keep this flexible".*

**9. Content safeguards before systems.**
Solve a problem with card design where possible. Add a rule only when content can't do the job.
*Source: 10-27f, "Not every problem needs a system to prevent it, we can have content safeguards as well", "We just need to make good balance and design decisions".*

**10. Keep what proves itself.**
Features, tools and rules stay only when evidence shows they help. The artist mood board was dropped after a blind test; the rows face a sim and prototype cards.
*Source: 11-01c, "If the mood board isn't producing better results ... then we don't want it"; 11-02, evidence for the rows: "Both".*

**11. Quality and adaptability over speed.**
Clear layers, flexible building blocks and solid docs, so content iterates fast. Game-warping modifiers must be addable later without breaking the game.
*Source: 10-27 §7, "We don't care about rushing towards delivery", "real quality and adaptability", "I definitely want the ability to add warping game-rule modifiers later".*

**12. The owner stays close and judges the human questions.**
Work is supervised from the start. Anything that needs human feedback goes to the owner as a question.
*Source: 10-27b §2, "I was too unsupervised at the beginning"; 11-02, "If you want human feedback on a topic, ask me."*

## Design principles

**13. Waiting must be a choice.** A design that rewards not taking an action is fine if it is isolated, so the player still has plenty of interesting choices, or time-bounded, so the player waits for a payoff. "Don't move for 3 turns, then X" is good; "don't move to get stats every single turn" is not. It is a delicate balance. *Source: 02h, 02i.*

*[`02h` and `02i` are [2026-11-02h](owner-notes/2026-11-02h-checkpoint-read-through.md) and [2026-11-02i](owner-notes/2026-11-02i-reactions-are-directions.md). The owner agreed this wording on 2 November.]*

## What Bramble avoids

| Avoid | Source |
|---|---|
| Unbounded loops: power that stops meaning anything | 11-02, "the player can just sit there and play forever" |
| An in-fight player HP model | 10-27b §2, "I want to go away from that kind of context where the player has an in-fight HP model" |
| Under-priced economy and scaling | 10-27e #11, "Stricter than Battlegrounds" |
| A system cap where content design would do | 10-27f, "Not every problem needs a system to prevent it" |
| Spaghetti architecture that breaks under warping rules | 10-27 §7, "a complete architectural mess and spaghetti code, because things consistently break" |
| Rushing to delivery | 10-27 §7, "We don't care about rushing towards delivery" |
| Content before fundamentals, and unsupervised early work | 10-27b §2 and §6 |
| Over-engineered rules (said of the art style) | 11-01b, "simple but clear, not over-engineered" |
| Keeping a tool or feature that hasn't proved itself | 11-01c; 11-02 on the rows |
