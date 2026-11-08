# Case study: how weak Birds got through the process (8 Nov 2026)

Prompted by the owner: `docs/design/owner-notes/2026-11-08f-birds-case-study.md`. Their hypothesis is that the early Birds give no reason to buy them, so the tribe's late payoffs are never reached, and that tribes have uneven card counts and tier spreads. Both are checked below, and then traced back through the process.

## 1. The hypothesis holds

**Early Birds are the weakest bodies at their tier** (pool units only, stats summed):

| Tier | Birds | Best of the other tribes | Median of the tier |
|---|---|---|---|
| 1 | Mrs Dunnock 4; Chiffchaff, One Swallow, Tom Tit 3 | 5 (Field Vole, Dewdrop Ooze, Pixie Scout, Marsh Frog, Young Pretender, Wee Wobbly, Pill Bug) | 4 |
| 2 | Fieldfare 7 (no text); Lump, Heron, Jay, Redwing 4; **Mr Redbreast 3** | 7 (Hedge Sprite) | 4–5 |

- **Chiffchaff:** "When played: give the units in front of this +1 Attack." On turn 1 the board is empty, so on the turn a tier-1 card matters most you are buying a 1/2.
- **Mr Redbreast:** a 1/2 at tier 2 that grows only with Nests. The cards that make Nests aren't worth buying on their own.

**Counts and tiers are uneven** (shop pool, tiers 1–6):

| Tribe | Cards | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|---|
| Birds | 22 | 4 | 6 | 4 | 4 | 1 | 3 |
| Hunters | 21 | 5 | 3 | 5 | 3 | 4 | 1 |
| Fairies | 20 | 4 | 4 | 3 | 3 | 3 | 3 |
| Oozes | 20 | 4 | 3 | 4 | 3 | 2 | 4 |
| Bog folk | 19 | 4 | 4 | 4 | 3 | 3 | 1 |
| Hedgerow folk | 18 | 5 | 4 | 4 | 3 | 1 | 1 |

**Results agree.** Eight playtester games across rounds 3–5 were built on Birds. Seven placed 7th or 8th, and one placed 3rd (pt3-a, with Jack Daw and Mag Pye). Six reports called Birds weak, clunky or a trap (pt2-b, pt3-c, pt4-c, pt5-b, pt5-c, pt5-d). In the 1,000-lobby pinned spread, the two Bird routes won 1.4% and 2.5% of lobbies, against a 6% floor.

## 2. Where the process let it through

1. **Costing priced cards at their best case, not at the moment you'd buy them.** Costing pass 2 counted Chiffchaff's when-played buff at full value (2.5 SP) and its repeat on each return, then rated it "+90%, over". Mr Redbreast was costed on a guessed 2.5 Nests at tier 2 and rated "+43%, over". The fix in both cases was to cut the body (Redbreast 2/3 to 1/2). The method has no term for what is on your board when you buy the card, and no comparison against the other cards the shop offers at that tier. The result was the smallest bodies at their tier, rated as fair.
2. **Nobody checked the tribe's journey.** The design doc wrote a turn-by-turn plan, "Turns 1-3: Swallow and Chiffchaff", along with its own warning: "Loses to: early tempo… may simply be too expensive". No step tested whether a player would pick a turn-1 Bird over the other cards in the shop. Reviews looked at cards one at a time and at whole tribes as ideas, never at the order of buying decisions.
3. **The bars couldn't see a weak tribe.** The spread bar asks for any 5 strategies at 6–25%. Nineteen passed, so Bird routes at 1.4% and 2.5% failed nothing. When the sims showed the weakness, the logged call was to steer the bots off the weak route ("instead of an equal prior that sends bots down the weak line"), with "no extra unmeasured card buff". That treated a weak tribe as a bot-routing problem.
4. **Pinned bots hide traps.** A bot pinned to Birds buys Birds whatever the shop offers. The sim never asks whether a free player would choose them.
5. **The same signal recurred across rounds and was never tallied.** Each round's fixes took that round's top items. "Birds weak" came up in four rounds and never topped a single one. The one logged Bird watch item was the opposite risk, "small-Bird flights may be too strong", taken from a single report.
6. **No structural checks.** Nothing compares card counts or tier spreads across tribes.
7. **Freezing designs locked the problem in.** The 8 Nov rule, "existing designs stay", was meant for taste revisions. In practice it also blocked fixes to cards that were failing.

**The common root:** every check worked on one card (cost it, review it, word it) or on the whole game (one global spread bar). Nothing checked the level between them: a tribe as a sequence of buying decisions, each made against everything else in the shop at that moment. That middle level is where the owner spotted the problem in ten seconds.

## 3. Process changes (adopted on ideation)

- **A. Buy-moment costing.** Cost each card at the round it is most likely bought, with the board you would have then; on turn 1 the board is empty. Compare it with the best same-tier cards in the pool. A card must be a sensible pick there on its own, or be marked as a payoff and name the enablers it needs, and those enablers must pass.
- **B. Tribe journey review.** For every tribe, rounds 1–3, 4–6, 7–9 and 10+: what you buy, why you take it over the other tribes' options, and what that makes you want next. The reviewer gets the whole pool laid out by tier.
- **C. Per-tribe bars.** Free-choice bots, not pinned ones. Each tribe needs a pick rate and a win rate inside a band. A tribe below the floor fails the step, and the fix goes into cards, not bot routing.
- **D. Structural parity.** The same number of shop-pool cards per tribe, with the same tier spread, enforced by a check in `check.sh`.
- **E. Cross-round tally.** One running table of every playtest problem across all rounds. Anything raised in 3 or more reports is a must-fix, not a watch item.
- **F. No cards frozen by default.** "Existing designs stay" covers taste. A card that fails A–C gets redesigned, keeping its idea where possible.
