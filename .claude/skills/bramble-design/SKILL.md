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

**Cost against the tier guide,** and end each design with the tier check its "Who reads it" paragraph asks for.

**Idea:** take two equal plain boards, give one the effect, and raise the other's stats until they are even. Use the [rough ten-case method](../../../docs/design/power-check.md) in under ten minutes:

`godot --headless -s res://tools/checks/power_check.gd -- cleave '{}'`

Replace the mechanic and parameters. All five tribes load. The automatic +50% buff **wiring check** matches ×1.5 by construction; it does not prove balance.

Pitch the **built-around number**: the median of cases where it fired, including weak outcomes. The method page records the all-ten number as setup cost. For an unbuilt effect, hand-work **two or three** of the ten cases and state assumptions.

Reference effects, in total carrying-unit stats:

| Effect | Built around |
|---|---|
| Master of Engines, full Hit | ×4 |
| Catapult, full Hit | ×2 |
| Pile on, full Hit | ×2.5 |
| Ballista, full Hit | ×2 |
| Cleave | ×3 |
| One 4/4 death summon | ×1.25 |
| +50% Attack and Health | ×1.5 |
| Pigeon row volley | >×6.5 |

**Limits:** damage that does not change who survives can be missed. The reference prices cover Mice and Pigeons; other tribes now load but need their own measurements.

The bar is Hit among the strongest effects, Cleave very strong, and a plain buff at its own stats. **If it doesn't, the check is wrong.** Report misses without tuning cases to force a pass.

Strong utility is allowed when paid for; free hits belong on a single card or capstone. Summons reuse slot buffs. Keep it rough, without large sweeps.

Budgets and taxonomy are guidelines. The tier guide and the effect taxonomy are not exhaustive, and any agent may add an effect that isn't in them.

## Showing the owner

- Pitch ideas concretely. Every mechanic or tribe idea shown to the owner comes with an example unit with full rules text, how it interacts with other cards, why a player would run it, a situation where it is good, and two or three variations. Where it resembles a design the owner may know from another game, say so in a line. Purpose: the owner can't judge an idea from a one-line summary (2 Nov).
- Design reactions are directions. When the owner reacts to a design, the reaction sets what to iterate on, not what changes. Never cut a design straight away: explore what it can teach, push back with an example where it works, or propose a version that does. This applies only to evaluating designs. Purpose: early cuts lose ideas, and the owner's comments on designs are mostly suggestions (2 Nov).
- Rules text on an example unit follows the wording rule in the `ux-copy` skill. Load it before you write card text.

## Reviews

Designs go to the owner without a review round, unless the owner asks for one. The owner (12 Nov, `docs/design/sources/2026-11-12a-tier-guide-designs-and-less-review.md`): "I want more unreviewed stuff coming to me" and "I need to have less long review cycles."

## Briefing agents that can't see this skill

Codex workers, and agents started without skills, never see this page. Put the reading list and the tier check in their brief. For how to brief designers, see "Briefing other designers" in `game-design-process`.
