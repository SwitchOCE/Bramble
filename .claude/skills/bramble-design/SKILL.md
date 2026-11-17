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

Cost against the **whole [tier guide](../../../docs/design/tier-guide.md)** and end each design with its tier check. Give utility a rough number before pitching it.

Use [the ten-case check](../../../docs/design/power-check.md) in under ten minutes: `godot --headless -s res://tools/checks/power_check.gd -- mouse_catapult '{"times":1}'`. Replace the mechanic and parameters. Keep the layouts, body size 10 and slot Attack 10. Compare final Health first, starting Attack + Health when tied. The +50% buff control must read about ×1.5 in **every** case.

Define “fired” before running. Report **built around** (median of cases where it fired at least once, even without benefit), then **all-ten median**, plus setup count. Keep Mouse uses separate.

Frozen numbers, including the carrying unit's original body:

| Effect | Built around | All ten |
|---|---|---|
| Master of Engines | ×4 | ×4 |
| Catapult | ×2 | ×1.75 |
| Pile on | ×2.5 | ×1.75 |
| Ballista | ×2 | ×2 |
| Cleave | ×3 | ×1.25 |
| One 4/4 death summon | ×1.25 | ×1.25 |
| +50% Attack and Health | ×1.5 | ×1.5 |
| Pigeon row volley | >×6.5 | ×1 |

These are rough setup estimates, not final prices or win rates. The buff repair followed trial one; utility with unchanged final Health can still be missed. Pigeon front >×8 and back ×5 give >×6.5. Added in-fight bodies: `(multiplier − 1) × unit stats / same-tier body stats`. Both historical tables remain in the check; do not tune cases to force a rating.

The owner: “very powerful if built around correctly.” Extra bodies reuse slot buffs; free damage needs paying for. A free hit is for one card or a capstone. Strong effects are allowed when paid for; budgets are guidelines. Keep it rough: no large sweeps. [Owner's full words](../../../docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md).

## Showing the owner

- Pitch ideas concretely. Every mechanic or tribe idea shown to the owner comes with an example unit with full rules text, how it interacts with other cards, why a player would run it, a situation where it is good, and two or three variations. Where it resembles a design the owner may know from another game, say so in a line. Purpose: the owner can't judge an idea from a one-line summary (2 Nov).
- Design reactions are directions. When the owner reacts to a design, the reaction sets what to iterate on, not what changes. Never cut a design straight away: explore what it can teach, push back with an example where it works, or propose a version that does. This applies only to evaluating designs. Purpose: early cuts lose ideas, and the owner's comments on designs are mostly suggestions (2 Nov).
- Rules text on an example unit follows the wording rule in the `ux-copy` skill. Load it before you write card text.

## Reviews

Designs go to the owner without a review round, unless the owner asks for one. The owner (12 Nov, `docs/design/sources/2026-11-12a-tier-guide-designs-and-less-review.md`): "I want more unreviewed stuff coming to me" and "I need to have less long review cycles."

## Briefing agents that can't see this skill

Codex workers, and agents started without skills, never see this page. Put the reading list and the tier check in their brief. For how to brief designers, see "Briefing other designers" in `game-design-process`.
