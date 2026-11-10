# Bramble design guidance

This is the Bramble-specific companion to the general `game-design-process` skill. The skill covers how to design; this file covers what is true of Bramble right now. Bramble's current systems, such as shop tiers, rows and the gold economy, are a paradigm that can change, so check the docs below before relying on any of them.

*Status: 10 Nov 2026 (hard rules and the breaker review added). In the repo on `ideation/main`. The general skill is `.claude/skills/game-design-process/`, used only when a user or an orchestrator says so. Codex workers are given the file path to read.*

## Hard rules (owner, 10 Nov 2026)

A few rules that bind absolutely, in place of soft bars. A design that breaks one is changed before it's built, however good it looks in sims. The owner's reason: every time Battlegrounds has had exponential scaling, it has had to be removed, however rare or hard Blizzard made it.

1. **No repeated multiplication without a hard cap.** Nothing may repeatedly give a unit a gain proportional to its own current stats (or multiply gold, cards or triggers the same way) without a hard cap. This covers cards, golden text, copied text, combinations of cards and system rules alike (a spell-scaling rule that turns +1 into "10% of the target" counts).
   - A cap is a lifetime count ("up to three times a game") or a ceiling on the result ("never past your biggest unit"). A gold cost, a period ("every 3 turns") or excluding the card itself is not a cap.
   - One-shot means once in the card's whole life: if it can return to hand, be replayed or be copied, it isn't one-shot.
2. **One card's own growth is at most linear.** What a card adds each turn may grow with the game (tier, turn, gold spent, units on board), but never with the stats it has already given. Taking a share of another unit's stats is fine one way (an enemy's body as a trophy, one copy at a sale); it breaks the rule when the share flows back to the unit it came from, directly or round a loop.
3. **Cards are judged on their best play, not on bot play.** Bots under-play engines, so a sim median never clears a card. The breaker review below decides.

**Allowed on purpose:** two linear things multiplied together (Ring count × Ring size, units × buff per unit) are quadratic, not exponential. They are a power fantasy and the rules allow them; the breaker review checks how often they come together.

**Combos are the power fantasy.** Big numbers from assembling several cards are wanted, as long as the chain obeys rule 1. The breaker review separates a combo worth chasing from a degenerate one.

## The breaker review (every new or changed card)

The reviewer plays as a top Battlegrounds player whose aim is to break the card. For each card:
1. **Best use:** the board, the line and the pieces that get the most out of it.
2. **Its own growth per turn** under that play, written as a formula, and its class: flat, linear, polynomial or exponential.
3. **Combos:** the cards in the pool, from any tribe, that multiply it, and the combo's growth.
4. **Power fantasy or degenerate?** A power fantasy takes real assembly (several specific pieces, a real cost along the way), and once assembled it can still lose to a strong board. A degenerate combo is cheap or common to assemble and wins nearly every fight once it is.
5. **How often:** a rough estimate of how often the pieces come together in a real lobby (copies in the pool, tiers, how many pieces, five of six tribes per lobby), with the reasoning.
6. **Verdict:** fine; power fantasy (keep it); degenerate (change one piece); or breaks a hard rule (must change). For a change, give the smallest one that keeps the card's creative core. Cool designs are kept wherever a version can obey the rules.

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
- **Caps only as loop guards.** Where sims show a common snowball, add a rate limit or an answer, not a size cap (`fundamentals.md`). Hard rule 1 overrides this: repeated multiplication always needs a cap.
- **Growth is wanted.**
  - The game was "flat by construction", growing about +13 a round.
  - The first target was Battlegrounds' September 2025 shape, about ×1.5 a round from round 8. Check `DECISIONS.md` for the current bar: 10 Nov entries work to ×1.3 for one line and a 900 R12 target.
  - Growth rate and game length are one decision.
  - Growth comes from the whole board, the economy and combos, never from one card multiplying itself (hard rules 1 and 2).
- **Briefs** carry the target curve shape and the condition/payoff/enabler frame, but no price table.
- **Fun over balance.** Rewards always give the player power. Be generous, then dial back.

## Known failure patterns of Bramble's design agents
- **Card fixes for system causes:** at least 19 decisions added a cap or limiter after something dominated (`fundamentals.md`).
- **The middle level skipped:** checks looked at one card or the whole game, never a tribe as a sequence of buying decisions (`docs/ideation/evidence/birds-case-study.md`).
- **Complaints not tallied across rounds:** "Birds weak" came up in four rounds and never reached the top.
- **Paper models overshoot:** real round-12 boards reach 0.17–0.72× of paper (corrected 10 Nov, `RESTART.md`). Set targets on measured medians.
- **Bot play is weak evidence:** bots are "okay at best" as players. Weight sims far above observational bot play (`owner-notes/2026-11-09d`).
- **Exponential engines passed every review (run 1):** Mrs Mallow ("triple your two smallest other Hedgerow units" every turn) grows ×3 a turn when you keep two eligible units, and the Standing Committee spreads that to its whole run. A breaker panel called her "a spread compounder that limits itself by design", reasoning on an even board; the costing warning in `power-budget.md` was never shown to designers; the bots valued her at one turn's gain; reviews read medians. The owner found it by playing. Hence the hard rules and the breaker review above.
- **Chasing critics' scores cluttered the UI:** trust real players over agent critics (`owner-notes/2026-11-09e`).

## Open questions for the owner
- **Bridge pieces vs tribe-locked payoffs.** The skill's Players check asks what pieces do outside their home. The docs partly answer this:
  - "Early units should be somewhat flexible as well as enabling" (`owner-notes/2026-11-09f`).
  - "Tribe-only payoffs carry the tribe word, so others can't splash them" (`fundamentals.md`; DECISIONS: "Tribe words follow the Lollop lesson").
  - That reads as: early units are flexible bridges, and payoffs stay tribe-locked. Is that right?
