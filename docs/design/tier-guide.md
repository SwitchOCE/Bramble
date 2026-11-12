# Tier guide: what each tier is for, and roughly how much it gives (12 Nov 2026)

A short guide for designing and costing units. It replaces strict per-card budgets with one job per tier and rough number targets, taken from what Battlegrounds units actually give. The evidence is 310 Battlegrounds units valued by role and stats per turn (`docs/research/battlegrounds/analysis/unit_values.json`; the page is the "Battlegrounds Value Ledger" artifact). These are guidelines, not limits: any tier can hold an exception if it is fun and the costing reviewer says why.

The owner's words (12 Nov): "more important than the budget is just having it be like, instead of being really strict, have it be like pretty simplistic." Tier 6 "needs to be big, impactful … a capstone. Like a pivotal engine piece or a big scaling payoff for an engine." Tier 5 needs to be "strong enough to give you strategic direction or a lot of tempo to buy you time to find strategic direction." Tier 4 needs to be "a strong player in a composition that sets up future things, enables, gives you some stats."

**Who reads which part.** Designers get Part 1 (the jobs and the shape of a tribe). The costing reviewer uses Parts 1 and 2. Part 2 is in ratios, so it holds when Bramble's economy and stat scale change. That keeps the standing rule that designers work without the numbers, so their ideas aren't narrowed to what Battlegrounds already does.

## Part 1: what each tier is for

| Tier | Job | Roles it usually holds (Battlegrounds today) |
|---|---|---|
| 1 | A body that wins the early fights, or a small seed a later engine grows from | tempo, combat engine; a few buffers, scalers and economy |
| 2 | The first buffers and economy; a direction starts | buffer (about 40%), economy, enabler, combat engine |
| 3 | Enablers that name your composition: they make what the tribe feeds on | enabler, economy, combat engine, buffer |
| 4 | "A strong player in a composition that sets up future things, enables, gives you some stats" | buffer, economy, enabler, plus the first multipliers |
| 5 | "Strategic direction or a lot of tempo": the card that says what this game's build is, or holds the line while you find it | buffer (about 40%), combat engine, economy, multipliers |
| 6 | "A capstone … a pivotal engine piece or a big scaling payoff": the comp is built to reach it | capstone, payoff, enabler, multiplier |

**A 19-unit tribe (2 / 3 / 4 / 4 / 3 / 3), as a starting shape:**
- **Tier 1:** one tempo body and one seed.
- **Tier 2:** two buffers or enablers and one economy piece.
- **Tier 3:** two enablers, one buffer, and one combat engine or economy piece.
- **Tier 4:** one or two buffers, one enabler, and one multiplier or economy piece.
- **Tier 5:** one direction card (a payoff or a strong buffer), one combat engine, and one tempo piece or multiplier.
- **Tier 6:** one or two capstones and one payoff.

Change the shape when the tribe's idea needs it, and say why.

**Three rules of thumb:**
1. **The tier is paid for in text, not body.** Printed stats rise only about ×1.26 a tier (median 4.5 at Tier 1, 12.5 at Tier 6).
2. **Output roughly doubles each tier from Tier 3.**
3. **The same job one tier up gives about three times as much,** through more triggers or more recipients rather than a bigger number per trigger. Examples:
   - Gatekeeper Amalgam (T6) gives the same +4/+4 packet as Lightfang (T5), four times a turn instead of once: 160 against 40.
   - Brann (T5) repeats every Battlecry, where Kelp Keeper (T4) repeats one: +72 against +24.
   - Nadina (T6) gives three shields, where Glowscale (T5) gives one: 120 against 40 a fight.

## Part 2: the curve, as ratios (for the costing reviewer)

Bramble's economy and stat scale will change (owner, 12 Nov), so the guide is anchored to **ratios, the curve and each tier's job**, not to Battlegrounds' gold or stat numbers. The owner: "as long as it's not like anchored to Battleground's economy numbers and more about like the ratio and the curve and the kind of like strategic parts they play."

**The unit of measure is a body:** the median printed stats (Attack + Health) of a vanilla unit at the same tier, in whatever scale Bramble uses. Every target below is in bodies, so it moves with the scale.

The targets are for a normal (non-golden) copy in a good setup, meaning the tribe's composition is mostly assembled, around two-thirds of the way through a game. **Permanent** stats stay on the board. **In fight** is stat value inside one fight, starting again each fight. **Once** is a one-off permanent buff. A unit usually gives one of the three.

| Tier | Body grows (vs T1) | Permanent / turn | Or in fight | Or once | Ceiling with goldens |
|---|---|---|---|---|---|
| 1 | 1.0 | ~0.4 body | ~0.6 | ~1 | ×2 |
| 2 | 1.3 | 0.3–1 body | ~1 | ~1.3 | ×2 |
| 3 | 1.6 | ~0.8 body | 0.7–1.4 | ~1–1.4 | ×2 |
| 4 | 2.0 | ~1.3 bodies | ~2 | ~2 | ×2–4 |
| 5 | 2.2 | ~2 bodies (top ~5) | ~4 | ~2.5 | ×2–4 |
| 6 | 2.8 | ~4 bodies (top ~10) | ~6 | ~6 | ×2–4 |

**The curve in one line:** bodies grow about ×1.2 a tier, while what a unit adds grows about ×2 a tier from Tier 3, so by Tier 6 a unit adds about four of its own bodies a turn.

- **Goldens.** One golden key piece usually doubles its effect. Two golden key pieces, or a golden multiplier (a golden Brann triggers three times), double it again. The owner (12 Nov): "With a single golden unit, you can start doubling things, and you get multiple copies of goldens, you can start doubling things." The Battlegrounds values were measured on normal copies, so their top end is understated. Cost the normal copy against the table, and check that the golden ceiling is a high roll worth chasing, not a runaway.
- **Economy.** Price gold against what it buys at that stage: one gold is worth the share of a unit purchase it pays for (in Battlegrounds, a third of a unit). Don't use a fixed stats-per-gold rate, because Bramble's economy will change.
- **Well outside** means about twice the tier's target, or half of it, with no reason written down. Flag those and propose a change that keeps the card's core idea.
- **Runaway growth is a separate check.** This table prices growth that adds a set amount each turn. A unit whose gain feeds its own source goes through the two-pass runaway check in `bramble-design-guidance.md`.
- **Battlegrounds' own numbers,** for reference only. The bodies are 4.5 / 6 / 7 / 9 / 10 / 12.5 stats at Tiers 1–6. Median permanent growth a turn is 2 / 2 / 5.5 / 12 / 20 / 53, and in fight it is 2.5 / 6 / 4.5 / 20 / 42 / 80.

## Where the numbers come from

- **Batches.** Five Codex (gpt-6.1-sol) workers each valued one batch: Tiers 1–3, 4, 5, 6, and 50 past landmarks.
- **Basis.** Card text, printed stats, Bramble's Battlegrounds research and general play knowledge. Each value comes with its setup and working.
- **The figures above** are medians over today's pool, with the top quarter in brackets where shown.
- **Checks.** About 14 well-known units were spot-checked. Nothing was simulated.
- **Past landmarks** (2020–23) are about a third of today's at the top: a median of 16 permanent a turn at Tier 6, against 53 today.
