# Pot Luck triage: adversarial critique of the synthesis

Data: `docs/ideation/evidence/wave2b/oozes-final.jsonl` (32 lobbies) and `oozes-before-pot-fix.jsonl`, in `/home/alex/code/Bramble-ideation-balance` (ideation/wave2b; c66a88e5 is an ancestor of HEAD). Read-only. No Godot. Scripts and `.out` files are listed at the end, all in this folder.

**Verdict: sound, with changes.** The symptom numbers recompute exactly, and the failure is real. The gap between the lines also survives controls for board composition. But the synthesis leans toward route and card design without evidence for that lean. Its top-ranked card fix can't move the deciding measure. Two of its bot "faults" are documented or already-implemented behaviour. And it missed a pattern on the climb rounds that matches a divergence between the paper route and the committed line.

## 1. Numbers recomputed

| Claim | Recomputed | Source |
|---|---|---|
| PL survivor medians 88 / 200 / 337, x1.251; EN 87 / 262 / 572, x1.369 | identical | critic_groups.out |
| PL against the Hard field: 0.85 / 0.69 / 0.59 / 0.44 at R8 / R9 / R12 / R14; R8->R9 +6% / +17% / +31% | identical | critic_groups.out |
| Lobby median 99 -> 663.5, x1.373 | identical | synth_check.out |
| Placement with ties averaged: 5.30 / 4.47 / 4.37 | identical | synth_check.out |
| Effective weights (Elder 26.2 ... Nell 10.5) | identical | inline check of line_policies.gd and committed_line_brain.gd |
| Rate-against-mix result (x1.323 / x1.256) | arithmetic correct | synth_split.out |
| Paper P without Soup and Nell: x1.327, 248 at R12 | identical | critic_paper.out |
| PL survivor-median interval 1.147-1.353 | 1.148-1.353 (lobby bootstrap) | critic_boot.out |

One correction: on the deciding measure (survivor median), the engine-minus-Pot-Luck difference has a lobby-bootstrap interval of **-0.004 to +0.216**, which includes zero. Only the synthesis's paired view excludes zero, and only narrowly.

## 2. Tests of the main cause

**H1. The gap is board mix, not conversion rate (attempt to refute the main cause).**
- Test: OLS of log one-round growth (R8-R13 starts, 304 transitions, seat-cluster bootstrap) on the line, with controls for round, Soup, Nell, Elder, Aspic, Cut, tier 1 bodies, mean tier, highest tier, body count, and holders (Wobbly, Posset, Pie).
- Result: Pot Luck's coefficient stays at **x0.94 a round** in every specification (with all controls, x0.945, interval [0.912, 0.979]). Tier 1 bodies are higher on Pot Luck boards (2.35 against 1.35 at R12), but they don't explain the gap (critic_regress.out, critic_comp.out).
- Verdict: **ruled out.** On this point the main cause stands.

**H2. Pot Luck is the anomaly (implied by the synthesis's framing).**
- Test: compare against the 28 Hard seats whose final build is an Ooze strategy, playing the same cards in the same lobbies.
- Result:
  - Per transition, with the same controls: Pot Luck against Hard Oozes x0.98-0.997 (interval covers 1); engine against Hard Oozes **x1.05** (1.015-1.092).
  - Paired R8->R12 growth: Pot Luck 1.223, Hard Oozes 1.276, engine 1.319. Hard on other tribes: 1.343.
  - Mean placement: Pot Luck 5.30, Hard Oozes 5.23.
  - Sources: critic_pot.out, critic_groups.out.
- Verdict: **kept (missed level).** Pot Luck grows at the Oozes' generic bot rate. The engine line is the outlier: it runs about 5% a round above both. The real question is what the engine line does that neither Pot Luck nor Hard play does.

**H3. Pot Luck loses its ground on the scheduled climb rounds (missed).**
- Test: paired per-seat one-round steps by round. Climb rounds come from the schedule 3/5/7/9/11, so T4 at R7, T5 at R9 and T6 at R11.
- Result:
  - Pot Luck dips on every climb transition: R6->R7 x1.291 (engine 1.397), R8->R9 x1.171 (1.293), R10->R11 x1.217 (1.335). It catches up at R7->R8: x1.381 against 1.274.
  - The two climb transitions inside R8-R14 hold **51%** of the Pot Luck-minus-engine log gap. The other four rounds hold the rest. Per transition the gap is -0.096 on climb rounds against -0.046 on the others.
  - The first run repeats it: 49%, -0.085 against -0.045.
  - Share of boards with a tier 5+ card: R10 55% against 81%; R11 63% against 90%.
  - The cause fits the code. Only the engine line holds back 3 gold the round before a scheduled climb (`tools/sim/line_brain.gd` `_held_back`, engine only), and Pot Luck's line text says "Never save". The paper model for P keeps 3 gold before every scheduled climb (`oozes-pass3-model.py` lines 202 and 214, applied to every route).
  - Sources: critic_steps.out, critic_steps_before.out, critic_climbsplit.out.
- Size: the excess on climb rounds is about a quarter of the gap, about +0.017 a round (x1.251 -> about x1.27). Gold and shop tier aren't logged.
- Verdict: **open, strong.** This is a divergence between the paper route and the committed line, which makes it a measurement fault. It is not a card fault.

**H4. Dishwater Nell is a growth keystone (a premise of the supply cause and of bot fix 3).**
- Test: the same OLS on all Ooze seats.
- Result:
  - Nell **x0.994** [0.966, 1.019] over 145 transitions.
  - Soup x1.060 [1.030, 1.090]; Elder x1.045 [1.011, 1.079].
  - Engine transitions with Nell 1.333, without 1.325.
  - Source: critic_nell.out.
- Verdict: **ruled out as a realized keystone.** Nell is a paper keystone (ablation +457 at R12) with no measurable effect in bot play. That makes her a card to check against her role (observational evidence). Raising her presence, as fix 3 targets, predicts no growth.

**H5. The pot is missing (the synthesis's "no fallback pot").**
- Result:
  - Pot Luck has no Digest Ooze (Dollop, Bubble, Frumenty) at R8 in 28% of seats. The engine is at 12% and Hard Oozes at 7%.
  - Pot Luck transitions with no Digest Ooze grow x1.189 (n32), against x1.295 with one.
  - The bot already treats any Digest unit as the pot: `BotOoze.carry`, and `Pass3Oozes.DIGEST` in `pass3_oozes.gd:5`.
  - The line's own written priority puts little_dollop 13th of 16 (effective weight 6.5, against the engine's 17.2). The route's R1-4 step lists Dollop.
  - Source: critic_pot.out, critic_edge.out.
- Verdict: **kept, relabelled.** The pot shortage is real and specific to this line. The "fallback pot" fix as worded is a no-op. The cause is the line's written priority, which contradicts its route prose.

**H6. T3-T4 offers nothing that grows (journey gap).**
- Result: Bubble and Squeak (T3) and Frumenty (T4) are Digest stomachs. Frumenty is on 43% of Pot Luck boards at R12. Pot Luck transitions with Bubble grow x1.278 (without, 1.246), and with Frumenty x1.287 (without, 1.235) (critic_edge.out).
- Verdict: **refuted.**

**H7. The Sixpenny Pie is a trap.**
- Result:
  - R12 boards: 147 with the Pie (n5) against 239.5 without (n18). Highest tier 5.2 against 5.44, tier 1 bodies 2.2 against 2.39.
  - Per transition: x1.220 (n29) against x1.260 (n114).
  - Source: critic_comp.out, critic_elder_pie.out.
- Verdict: **open (weak).** The direction matches the claim, but 5 boards don't carry a "trap" call.

**H8. Win rewards feed back into growth.**
- Result: the only fight reward outside tribe text is Early Spoils, 1 gold, R1-4 only (rulebook 10.1.4c).
- Verdict: **ruled out** after R8.

## 3. Synthesis claims refuted

1. **"CommittedLineBrain blends in the base weights ... no check compares the two"; "record the blend in HARNESS.md or remove it."** The blend is already documented and tested. `tools/sim/HARNESS.md:258` says: "Priority bonuses add to Hard's original card bonuses, rather than replacing them." The test is `tests/core/test_committed_lines.gd:41` (`test_priorities_add_to_hard_knowledge_without_mutating_it`), from commit 2e2625a2. Removing the blend for every line is a change to every tribe's bot policy, not a bug fix.
2. **"There is no fallback pot"; fix: "Little Dollop or Frumenty counts as the fallback pot."** They already count (see H5).
3. **Process cause: "Computed, [the low-roll row] gives x1.327 and 248 at R12, close to what the bots realised."** At B, x1.327 passes the bar, so the row would not have flagged this growth failure. The engine's own paper floor row, C2, fails on paper at x1.285 and passes in the sim at x1.369 (critic_paperlines.out). Low-roll rows don't predict which lines pass.
4. **Ruled out: "a slow climb schedule".** This checked only the written schedule. The executed tier isn't logged, and the climb-round evidence points the other way (H3).
5. **Ruled out: "feeding the pot less ... non-Ooze buys 0.60 against 0.63".**
   - `bought_by_tribe` is counted per tribe (`src/core/held_units.gd:102-103`), so neutral buys are never logged. No "neutral" key appears in any seat (critic_buys.out).
   - The count also includes R1-3 buys and double-counts units with two tribes.
   - It can't separate meals from reserves.
6. **Fix 1's expected effect.** The reworked Pie grows units inside a Belly, and "Elder counts units inside Bellies" grows them too. Elder's Details say "not inside Bellies". The deciding measure excludes Bellies (`oozes-summary.json` "counting"). Fights run on a copy, so reserves don't leave the Belly for good. The fix can't directly raise the survivor median it is verified against.
7. **The T3-T4 "skip" in the journey** (H6).
8. **Fix 3's Nell target as a growth lever** (H4).

## 4. Fixes against the owner's direction and the project rules

- **09d** (constructed setups over bot play):
  - The card fixes are ranked 1-2 on observational bot data. The constructed R8 board comes at rank 4.
  - The constructed setup and the cheap diagnostic arms should run before any card change.
- **09a** (concentration):
  - Both fix 1 options spread stats over reserves.
  - The synthesis doesn't weigh this against "concentrating stats is always better".
- **09i** (at most two criteria):
  - The brief's criterion 1 is "every new or changed card has a known-answer test of its rules text" (`docs/ideation/briefs/wave2b-build.md:44-45`).
  - The synthesis stretches it to bot line policy ("executed weights keep its written order"). In effect, that adds a criterion.
  - The brief's criterion 2 reads "each W2b tribe's committed line" in the singular. Whether a failing second line fails the step is a reading the orchestrator should log.
- **"Fix cards, not bot routes"**:
  - Removing the weight blend harness-wide falls outside the exception, because it is documented, intended behaviour.
  - Matching Pot Luck's gold rule to the paper route's keep-3 rule falls inside it: the line doesn't play the route the paper costed.
- **09h** (generous first): fix 2 (Elder to T4) and dial C are consistent with it. The Elder gap between the lines is not a tier gap, though:
  - same climb schedule;
  - same Ooze offer rate (1.21 against 1.23);
  - a higher Elder weight for Pot Luck (26.2 against 19.6);
  - yet Elder on 23% against 45% of boards at R10.

  So "Elder by R10 over 40%" has no support.
- **09c**: Pot Luck at R12 (200) is 0.6x the field. That is within an order of magnitude, so it is not an extreme miss under the plan's triage list.

## 5. Changes to the synthesis

1. Reframe the main cause: Pot Luck grows at the Oozes' generic bot rate. The engine line's policy is worth about +5% a round.
2. Before any card change, run on the same 32 seeds:
   - (a) Pot Luck with the paper's keep-3 rule before scheduled climbs (save_threshold 3, save_until 10);
   - (b) Pot Luck with little_dollop moved up its written priority to match the route's R1-4 step;
   - (c) the constructed R8 board (09d);
   - with gold, shop tier and Belly contents logged.
3. Drop fix 1 as written, or restate it so the stats land on active board units. Otherwise change the deciding measure explicitly and log why.
4. In fix 3:
   - drop the harness-wide removal of the blend;
   - drop the fallback pot;
   - drop the Nell-presence target.

   Keep best_belly burying Moss (Moss isn't in `ENGINES`; it is on 12% of Pot Luck boards against 28-31%) and the split gap for tempo.
5. Process cause: replace the low-roll row with "check the committed line's gold and save rules against the paper route's", and log gold and shop tier.
6. Move "slow climb" and "feeding the pot less" from ruled out to open. Mark H6 refuted. Downgrade the Pie from "trap" to "watch". Add Dishwater Nell to the role check.

## Scripts (python3 -I, in this folder)

critic_groups.py, critic_comp.py, critic_regress.py, critic_pot.py, critic_edge.py, critic_share.py, critic_steps.py (`.out` and `_before.out`), critic_climbsplit.py, critic_nell.py, critic_buys.py, critic_elder_pie.py, critic_boot.py, critic_paper.py, critic_paperlines.py. Each has a matching `.out` file.
