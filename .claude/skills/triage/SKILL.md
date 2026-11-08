---
name: triage
description: Before fixing a game-design, balance or metagame problem (a weak or dominant tribe, a trap card, a dull stage of the game, a recurring playtest complaint), step back, form several hypotheses about its cause, test each against evidence, check every card involved against its role, and name the process step that should have caught it. Use whenever a playtest, sim or review reports a design problem, and before redesigning content.
argument-hint: "[the problem, with where it was reported]"
---

# Triage a design problem

The owner's method (`docs/design/owner-notes/2026-11-08f-birds-case-study.md`): "When you see an issue… take a step back and then triage what's causing it… form multiple hypotheses… and then look for evidence for each of those." Don't jump from the symptom to a fix.

## 1. State the symptom

Say what goes wrong, for whom, and how often, with the evidence: which reports, which games, which sim numbers. Count across every playtest round, not just the latest. A problem that comes second or third every round is still a top problem.

## 2. Form at least three hypotheses at different levels

Pick from these, and don't stop at the first one that fits:

- **Card:** one card is too weak or too strong for its tier.
- **Role:** cards don't do the job they were designed for (step 3).
- **Journey:** the tribe or strategy has a gap at some stage, so its later payoffs are never reached.
- **Competition:** other cards do the same job better at the same tier. Uneven card counts or tier spreads across tribes mean more good pieces for one of them.
- **System:** economy, damage, shop odds or board rules push everyone away from it, or towards it.
- **Measurement:** bots, sims or bars hide or cause it, for example pinned bots buying a tribe whatever the shop offers.
- **Readability:** the design works, but players can't see why or how.

For each hypothesis, write what you'd expect to see if it were true and what would rule it out. Then look, and record what you found.

## 3. Check each card against its role

For every card involved, answer:

1. **Its role:** enabler, payoff, tempo body, economy, answer or finisher, and which wider strategy it serves.
2. **When the player should want it:** which rounds, which stage of the game, and what board you'd have then. On turn 1 the board is empty. At tier 2 you've only had a turn or two to collect pieces.
3. **The competition:** at that moment, is it a better use of the gold than the best same-tier cards in the pool, including other tribes'? Compare stats and effect against those cards, not against a budget number alone.
4. **The bad board states:** where it's a poor buy. That's fine: most cards are poor buys in many states. Make sure the window where it's good is real and comes up often.

If a card doesn't fulfil its primary role in its intended window, it's a trap, however good its idea or its late synergy. A payoff is only as good as the enablers that lead to it, so check those first. A late payoff can't rescue a tribe whose early cards nobody would buy.

## 4. Check the journey

For a tribe or strategy, lay out rounds 1–3, 4–6, 7–9 and 10+. At each stage: what you'd buy, why it's better than the alternatives in the shop, and what it makes you want next. Early cards should make the later ones more attractive. A break anywhere means the rest is rarely reached.

## 5. Find the process cause

Ask which step should have caught this: design, costing, review, sim bars, playtest tally, or the rules agents work under. Say why it didn't. Fix that step as well as the content, and list where else the same cause applies. One example is `docs/ideation/evidence/birds-case-study.md`.

## 6. Report

Give the symptom, the hypotheses with their evidence (kept, ruled out or open), the cards that fail their role and why, the journey gaps, the process cause, and the fix you propose for the content and for the process. Keep it short, and show cards with their full text.
