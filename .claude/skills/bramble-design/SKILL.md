---
name: bramble-design
description: Design, cost or review Bramble's units, tribes, mechanics and keywords, pitch a design to the owner, act on the owner's reaction to a design, or brief another agent to do any of these. Says what to read first, how to cost against the tier guide, how to show the owner a design, and when to review. Not for screens (design-critique), in-game wording (ux-copy) or art.
---

# Designing for Bramble

The `game-design-process` skill is how to design. This skill is the Bramble part: what to read, how to cost, and how to show the owner. Load `game-design-process` now too; this is the instruction it waits for.

Make design calls freely and mark them as yours, not decided. What makes a design decided, and what may enter `main`, is in `CLAUDE.md`.

## Read first

- **`docs/design/tier-guide.md`, all of it, numbers included.** What each shop tier is for and roughly how much it gives.
- **`docs/design/rulebook.md`**, the parts your design touches. Its tags say what is decided, proposed or open. Anything tagged [EXAMPLE] is a Battlegrounds or Galaxy mechanic kept as an example, not a Bramble mechanic.
- **`docs/design/direction-summary.md` and `docs/design/owner-ideas-log.md`.** The owner's direction. The log holds directions, not decisions.
- **For a tribe that started as a species seed:** the species seeds page, https://claude.ai/artifact/L7QD6ka8LzD22mnGsgA4SY (16 Nov 2026). It holds the shells, the owner's ratings and the owner's comments. Open it with the Artifact tool. If you can't open it, say so; don't guess what it says.

## Costing

- **Cost against the tier guide,** and end each design with the tier check its "Who reads it" paragraph asks for.
- **Give every utility effect a rough power number before you pitch it.** The owner (17 Nov): "agents are currently, as a general rule, vastly underestimating how strong the utility effects they're designing are. They're overestimating how powerful the stat boosting effects are." Extra bodies double dip on slot buffs, which Battlegrounds doesn't have; anything that trades 2 for 1, or deals damage and takes none back, is worth far more than it looks. A free hit is capstone-level, for one card at most.
  - How: take two plain boards of equal stats with no abilities. Add the effect to one, and raise the other's stats until the two are even. Do this in about 10 small scenarios (one unit against one, full boards, front row, back row, against Guard, and so on), worked by hand or with a few fights on the game's fight engine. The result is one rough number: "about ×3 stats", or "about 2.5 times the damage of the same unit without it". Put it in the pitch.
  - Keep it rough. The owner: "I don't want them doing endless simulations and ... writing Python scripts that simulate a million different boards."
  - Check the check: it should rate Hit as one of the strongest effects, Cleave as very strong, and a plain stat buff at about its own stats. The owner: "Something like Cleave is incredibly good. Something like Hit is unbelievably good." If it doesn't, the check is wrong.
  - It doesn't forbid strong effects: "I don't want to completely eliminate creativity". A strong effect is fine when its number is known and it is paid for (rarer, harder to trigger, smaller, or a capstone).
  - The owner's words in full: `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md`.
- **Price an effect that grows on recorded boards.** For an effect that grows per turn, per death or per unit on the board, give its stats at rounds 6, 10 and 14 on boards from a real match, not on a board you made up. The card report (`tools/league/card_report.sh`) gives each card's growth per turn and how many plain stats its text is worth, by stage; `docs/workstreams/card-power/definitions.md` says how to read them. Why: the costing read Old Brock as on target at round 11 on one made-up board; on recorded boards his text was the strongest of any card from round 13.
- **Compare the same effect across tiers.** When two cards do the same job at different tiers, put them side by side in the pitch and say why each sits where it does. Why: Sword-heir (tier 3) and Old Brock (tier 6) had nearly the same text, and The Eighth Plague (tier 5) does Gleaner's job (tier 3) and does it worse.
- **Ask for a first-sight read, and record it.** Before a new or changed card is built, the owner, or a fresh agent that hasn't seen the design work, marks any card that looks too strong or too weak on sight. The pitch records the marks. Why: the owner saw that Sword-heir and Old Brock were too strong "Within two seconds of seeing them", and no stage asked.
- **A fight on a made-up board illustrates; it isn't evidence.** The rough power number above is a first estimate for a pitch. Once a card is in a recorded match, the card report's numbers replace it.
- Budgets and taxonomy are guidelines. The tier guide and the effect taxonomy are not exhaustive, and any agent may add an effect that isn't in them.

## Balancing existing cards

The owner's method (19 Nov 2026). Their words are in `docs/design/owner-notes/2026-11-19a-balance-reads-bot-preferences.md`, `2026-11-19b-balance-pass-aims-and-method.md` and `2026-11-19c-double-tap-nerfs.md`; read them before a balance pass, and follow them over this summary where the two differ.

- **Measure before you tune.** The card step in `docs/workstreams/balance/plan.md` says how one card's power is measured and when a marked card may be changed.
- **Read what the bots prefer, not only how they place.** Buy rates when a card is on offer, and the values the bots give cards, show what a strong player wants. Placement by tribe hides which cards carried a board.
- **Weigh four kinds of change for every card:** numbers, economy (its tier), replace it, or rework it. Pick the best of the four, not the first that works.
- **Check the support before the card.** A card can be strong only because of another card that feeds it (the Flying Ace through the Wing Commander's free attacks). Fix the cause.
- **Give each card a defence before changing it:** the case for leaving it alone, put as strongly as you can. Change it only if the case against wins.
- **Don't double-tap.** When two cards of one strategy both look too strong because they lean on each other, one change is usually enough for both; changing both can make the pair unviable. The same holds for buffs. Find the one right place for the change.
- **Fix the game's balance, not just the outliers:** counters and redesigns from first principles, and every card fitting its tier.
- Show each changed card to the owner as it looks in the game, before and after, with the game's keyword tooltips.

## Showing the owner

- Pitch ideas concretely. Every mechanic or tribe idea shown to the owner comes with an example unit with full rules text, how it interacts with other cards, why a player would run it, a situation where it is good, and two or three variations. Where it resembles a design the owner may know from another game, say so in a line. Purpose: the owner can't judge an idea from a one-line summary (2 Nov).
- Design reactions are directions. When the owner reacts to a design, the reaction sets what to iterate on, not what changes. Never cut a design straight away: explore what it can teach, push back with an example where it works, or propose a version that does. This applies only to evaluating designs. Purpose: early cuts lose ideas, and the owner's comments on designs are mostly suggestions (2 Nov).
- Rules text on an example unit follows the wording rule in the `ux-copy` skill. Load it before you write card text.

## Reviews

Designs go to the owner without a review round, unless the owner asks for one. The owner (12 Nov, `docs/design/sources/2026-11-12a-tier-guide-designs-and-less-review.md`): "I want more unreviewed stuff coming to me" and "I need to have less long review cycles."

## Briefing agents that can't see this skill

Codex workers, and agents started without skills, never see this page. Put the reading list and the tier check in their brief. For how to brief designers, see "Briefing other designers" in `game-design-process`.
