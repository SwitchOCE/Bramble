# Bramble design guidance

This is the Bramble-specific companion to the general `game-design-process` skill. The skill covers how to design; this file covers what is true of Bramble right now. Bramble's current systems, such as shop tiers, rows and the gold economy, are a paradigm that can change, so check the docs below before relying on any of them.

*Status: 10 Nov 2026 (runaway-growth rule and breaker review added). In the repo on `ideation/main`. The general skill is `.claude/skills/game-design-process/`, used only when a user or an orchestrator says so. Codex workers are given the file path to read.*

## Runaway growth: two quick checks, then the data (owner, 10–11 Nov 2026)

Every time Battlegrounds has had exponential scaling, it has had to be removed (owner). Two fresh Opus checks catch it before a card is built; cards that pass them can still be caught by data and replays. Missing a runaway is worse than flagging one that turns out fine.

**What counts:** a line, with pieces that exist in the pool, in which some number grows by a share of itself turn after turn with no cap, or grows without limit inside one turn or one fight. Rare pieces, a gold cost, a period ("every 3 turns") and needing several cards don't excuse it: Battlegrounds removed rare loops too. Linear growth, and two linear things multiplied together (units × buff per unit), don't count.
- Pass: Honorary Treasurer reads the gold in the Larder; his stats never raise that gold.
- Counts: Squire Lollop skips your biggest unit, but a receiver overtakes it and becomes the next source.
- Pin a loop on the card that closes it: the one whose gain raises its own source. Aunt Aspic multiplies what an Ooze eats; Stone Soup makes the meal a share of the eater, so Soup is pinned and Aspic isn't.

**1. Flag check,** one per batch of new or changed cards (`breaker-audit/balance-watch-brief.md`): it works backwards from what would make each card loop, searches the pool and the code for the pieces, and flags each card:
- **BROKEN:** the line works as written (every step checked against text and code) and grows about ×1.3 a turn or more, or without limit in a turn or a fight.
- **WATCH:** a step couldn't be confirmed, or the loop is slower than ×1.3 a turn but has no cap.
- **CLEAR:** no such line.

**2. Second check** on every WATCH card (`breaker-audit/second-check-brief.md`): a fresh agent checks each step in the code, looks for a substitute piece where a step fails, settles the open question (no printed limit means none), scripts six turns, and decides BROKEN or KEEP. It asks the owner only when one rules question decides it and the text or code can't.

**After the checks.** BROKEN cards go to the owner with the line, the closer, the numbers and how rare it is. Cards kept after a second check go in `docs/design/balance-watch.md` with what to watch; sims and playtest replays look for the line, judged on strong play (bots under-play engines, so a quiet sim median doesn't clear a card). A runaway seen in replays adds a card, whatever the checks said.

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
