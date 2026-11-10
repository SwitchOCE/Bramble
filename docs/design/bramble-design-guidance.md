# Bramble design guidance

This is the Bramble-specific companion to the general `game-design-process` skill. The skill covers how to design; this file covers what is true of Bramble right now. Bramble's current systems, such as shop tiers, rows and the gold economy, are a paradigm that can change, so check the docs below before relying on any of them.

*Status: 10 Nov 2026 (runaway-growth rule and breaker review added). In the repo on `ideation/main`. The general skill is `.claude/skills/game-design-process/`, used only when a user or an orchestrator says so. Codex workers are given the file path to read.*

## Runaway growth: one hard rule, judged by a fresh breaker (owner, 10–11 Nov 2026)

Every time Battlegrounds has had exponential scaling, it has had to be removed (owner). But a long hard rule kills good cards and still leaks, so only the verdict is hard; spotting it is a judgement question with the maths shown.

**The hard rule:** *No number may grow by a share of itself turn after turn, by any route, unless the card states the most it can multiply that number by for any one unit in a whole game, and that is at most ×3.* A card found doing it changes before it's built, however good it looks in sims.

**The breaker's question,** for every new or changed card: *"Can what this card gives ever raise the number it was measured from, directly or through another card (yours or an enemy's), a copy, a golden, a return to hand or a system rule? Show the formula."*
- Pass: Honorary Treasurer reads the gold in the Larder; his stats never raise that gold.
- Fail: Squire Lollop skips your biggest unit, but a receiver overtakes it and becomes the next source.
- Costs, periods and exclusions don't stop compounding: Charcoal Burner's gold cost, Alderman Dozey's "every 3 turns" and Lollop's "except your biggest" all still compound.

- Pin a loop on the card that closes it: the one whose gain raises its own source. A card that only amplifies someone else's loop passes, judged as if that loop were fixed. Aunt Aspic multiplies what an Ooze eats; Stone Soup is what makes the meal a share of the eater, so Soup breaks the rule and Aspic doesn't.
- An enemy running the same card doesn't count as a loop. Mirrors are rare and the health clock ends them (Sable, Jack Daw).

**When unsure, run it:** script the card's best line for six turns. A steady ratio above 1 between turns means it compounds.

**Judged on best play, not bot play.** Bots under-play engines, so a sim median never clears a card.

**Big numbers are wanted.** Two linear things multiplied together (Ring count × Ring size, units × buff per unit) are fine, and so are combos that take real assembly. The breaker sorts what's left by judgement:

1. **Best use:** the board, the line and the pieces that get the most out of it.
2. **Growth per turn** on that line, as a formula: flat, linear, polynomial or compounding.
3. **Combos** with named cards from the whole pool, any tribe.
4. **Power fantasy or degenerate?** A power fantasy takes real assembly and can still lose to a strong board. A degenerate combo is cheap or common and wins nearly every fight.
5. **How often** the pieces come together in a real lobby, with the reasoning.
6. **Verdict:** fine; power fantasy (keep it); degenerate (change one piece); or breaks the hard rule (must change). Give the smallest change that keeps the card's creative core.

**Keeping the rule honest.** Before the rule's wording changes, a fresh agent given only the rule and the cards must sort both lists correctly. Must catch: Mrs Mallow, Alderman Dozey, Standing Committee, Charcoal Burner, Squire Lollop, Fly South, Fairy Monarch. Must keep: Honorary Treasurer, Hayward, Redbreast, Aunt Aspic, a Hunter trophy card, Cluricaun. If the rule needs a new clause to pass, make it a worked example for the breaker instead.

## Where the specifics live
| Need | Source |
|---|---|
| Rules and keywords | `docs/design/rulebook.md` and `rulebook-deltas.md`. HSBG and Galaxy keywords appear there only as [EXAMPLE]s; Bramble designs its own |
| Power for its place | **First:** triage step 3, which compares a card with the best same-tier cards in the pool (other tribes' included), and measured medians (`docs/ideation/archive/run1/RESTART.md`). **Then:** `docs/design/power-budget.md`, which predates `fundamentals.md` (fundamentals found its costing made the game flat), so read fundamentals before using it |
| Finding a cause vs choosing where to fix | Find the cause with triage's list (`.claude/skills/triage/SKILL.md`: card, role, journey, competition, system, measurement, readability). Choose the level to fix with the skill's ladder |
| Idea library | `docs/design/mechanics-library.md`, `docs/design/mechanics-ideas.md` |
| Wording | `docs/ideation/wording-guide.md` |
| Fundamentals | `docs/ideation/archive/run1/fundamentals.md` |
| Owner's own words | `docs/design/owner-notes/`, verbatim and dated. Never edit these |
| Decisions | `docs/ideation/DECISIONS.md` |

## Audience
Source: `owner-notes/2026-11-10d-audience.md`.
- **Primary player:** someone who wants a more skill-rewarding game than Battlegrounds.
- **Johnny first:** cards should interweave, overlap and be usable outside their obvious purpose.
- **Spike second:** kept happy through balance.
- **Timmy:** not the focus.
- **Vorthos:** last priority, barely a concern. Flavor serves the mechanics, not the other way round. Weight Melvin's mechanical elegance well above flavor.

## Standing direction
- **No endless loops.** In async play with no timer, an endless loop breaks the game. Big economy turns are wanted: "Big economy turns for everybody, never infinite" (`pillars.md` 4).
  - Prefer a system rule to bound endless loops. Escalating reroll cost is the model.
  - Content safeguards are allowed too: "Not every problem needs a system to prevent it, we can have content safeguards as well" (`content-guardrails.md`).
- **Caps only as loop guards.** Where sims show a common snowball, add a rate limit or an answer, not a size cap (`fundamentals.md`). The runaway-growth rule overrides this.
- **Growth is wanted.**
  - The game was "flat by construction", growing about +13 a round.
  - The first target was Battlegrounds' September 2025 shape, about ×1.5 a round from round 8. Check `DECISIONS.md` for the current bar: 10 Nov entries work to ×1.3 for one line and a 900 R12 target.
  - Growth rate and game length are one decision.
  - Growth comes from the whole board, the economy and combos, never from a number growing by a share of itself (the runaway-growth rule).
- **Briefs** carry the target curve shape and the condition/payoff/enabler frame, but no price table.
- **Fun over balance.** Rewards always give the player power. Be generous, then dial back.

## Known failure patterns of Bramble's design agents
- **Card fixes for system causes:** at least 19 decisions added a cap or limiter after something dominated (`fundamentals.md`).
- **The middle level skipped:** checks looked at one card or the whole game, never a tribe as a sequence of buying decisions (`docs/ideation/evidence/birds-case-study.md`).
- **Complaints not tallied across rounds:** "Birds weak" came up in four rounds and never reached the top.
- **Paper models overshoot:** real round-12 boards reach 0.17–0.72× of paper (corrected 10 Nov, `RESTART.md`). Set targets on measured medians.
- **Bot play is weak evidence:** bots are "okay at best" as players. Weight sims far above observational bot play (`owner-notes/2026-11-09d`).
- **Exponential engines passed every review (run 1):** Mrs Mallow ("triple your two smallest other Hedgerow units" every turn) grows ×3 a turn when you keep two eligible units, and the Standing Committee spreads that to its whole run. A breaker panel called her "a spread compounder that limits itself by design", reasoning on an even board; the costing warning in `power-budget.md` was never shown to designers; the bots valued her at one turn's gain; reviews read medians. The owner found it by playing. Hence the runaway-growth rule and the breaker's question above.
- **Chasing critics' scores cluttered the UI:** trust real players over agent critics (`owner-notes/2026-11-09e`).

## Open questions for the owner
- **Bridge pieces vs tribe-locked payoffs.** The skill's Players check asks what pieces do outside their home. The docs partly answer this:
  - "Early units should be somewhat flexible as well as enabling" (`owner-notes/2026-11-09f`).
  - "Tribe-only payoffs carry the tribe word, so others can't splash them" (`fundamentals.md`; DECISIONS: "Tribe words follow the Lollop lesson").
  - That reads as: early units are flexible bridges, and payoffs stay tribe-locked. Is that right?
