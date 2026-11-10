# Pot Luck triage (10 Nov 2026)

*[Saved by the orchestrator from workflow wf_132aa8e4-7ac: the synthesis and the adversarial critic, verbatim as structured output. Lens reports are beside this file. Scripts stayed in the session scratchpad.]*

## Synthesis

```json
{
 "symptom": "Pot Luck (line_oozes_tempo) grows x1.251 a round from R8 to R14 (survivor median: 88 -> 200 -> 337). The engine line grows x1.369 (87 -> 262 -> 572). Paper P predicts about x1.50.\n- The two lines are level up to R8. Pot Luck then falls behind the field: 0.85x the Hard-field median at R8, 0.69x at R9, 0.59x at R12 and 0.44x at R14. Its R8->R9 step is +6%, against +17% for the engine and +31% for Hard.\n- Realised as a share of paper, with Bellies: 0.86x at R6, 0.56x at R9, 0.27x at R12.\n- The two bot fixes left Pot Luck unchanged (x1.254 -> x1.251).\n- Disputed numbers, recomputed (synth_check.py):\n  - Placement: ties have to be averaged, since every lobby ends with two seats in its last recorded round and no Health is logged. That gives Pot Luck 5.30 mean place and 33% top 4, against 4.47 / 59% for the engine and 4.37 / 51% for Hard. The journey lens is right; the competition lens's 4.94 / 38% gives every tie its best place.\n  - Offers: 7.35 per round alive (6.42 without neutrals), 1.21 of them Oozes, 16.3 Ooze offers a game. The bot lens is right; the competition lens's 6.62 / 1.17 uses another denominator, with the same conclusion.\n  - Growth over all transitions: x1.248 is the geometric mean and x1.226 the median. Both are right.",
 "main_causes": [
  {
   "cause": "Pot Luck boards turn a round into permanent stats more slowly than engine boards, even with the same pieces, tier and round band. The route's own cards (Wobbly, Posset, Pie, Moss, Syllabub, Granny) add no pre-combat stats, and its reserves never grow. It also drops the engine's Aspic, second stomach and eaten Slices. How much is route design and how much is bot valuation is open.",
   "level": "role (route design), bot share open",
   "evidence": "Per-transition growth, geometric mean with Bellies, R8-R14 (synth_split.py, synth_tier.py, synth_hasty.py), Pot Luck against engine:\n- all transitions: 1.248 (n143) / 1.328 (n161);\n- holding Soup, Nell or Elder: 1.273 / 1.339;\n- holding none of the three: 1.211 / 1.299;\n- none of Soup, Nell, Elder, Aspic, Hasty or Cut: 1.234 (n29) / 1.308 (n25);\n- R8-10 with highest card T5 or lower: 1.244 / 1.329.\nAt Pot Luck's piece mix, the engine's rates would give x1.323. At the engine's mix, Pot Luck's own rates give only x1.256.\nTwo alternatives are ruled out: food buys per round are equal (0.60 vs 0.63) and Digest stomachs on board are equal (1.03-1.13 vs 1.15-1.26) (synth_sink.py). Paper reserves stay at 96 stats from R11.",
   "share_of_gap": "About 90% of the gap between the lines (rate vs mix decomposition). Closing it would on its own clear x1.3."
  },
  {
   "cause": "The route grows through two T2 cards (Stone Soup, Dishwater Nell) and one T5 card (Elder), with no growth buy at T3-T4. In a five-tribe pool each specific Ooze shows up about once per seat-game, so most seats never assemble the route, and Elder arrives after its R9-11 window.",
   "level": "journey / supply",
   "evidence": "- Pot Luck seats with none of Soup, Nell or Elder: 50% at R8, 45% at R10, 26% at R12.\n- Soup, Nell and a pot together: 1 seat through R12.\n- Elder on board: 6% at R8, 23% at R10; first seen at a median of R11.5.\n- 1.21 Ooze offers per round alive.\n- Paper P without Soup and Nell: x1.327 and 248 at R12, close to the realised x1.251 and 200-248.\n- Paper P with Elder at R12 instead of R9: R12 board 983 -> 563.\n- If every Pot Luck transition grew at its own with-piece rate: x1.273.",
   "share_of_gap": "About half of the gap to x1.3 at Pot Luck's own rates. About 10% of the gap to the engine, which faces the same scarcity (Soup ever on board in 12/32 seats for both lines)."
  },
  {
   "cause": "Bot faults against the line's own text:\n- CommittedLineBrain adds the base strategy's unit weights, so the executed buy order isn't the written one.\n- There is no fallback pot.\n- The engine's split-gap cap applies to Pot Luck too.\n- BotOoze.best_belly in tempo can bury Moss, Granny, the Pie, Syllabub or a second Bubble as reserves. Only the ENGINES list is protected, not the line's engine_pieces.",
   "level": "bot (measurement)",
   "evidence": "- Recomputed effective weights: Elder 26.2, Granny 25.4, Moss 19.1, Bubble 16.6, Soup 14.0 (written 1st), Pie 13.8, Wobbly 12.0, Nell 10.5 (written 5th). The base oozes_second_helpings gives Soup and Nell no weight.\n- At the same Ooze offer rate, Nell is ever on board in 6/32 Pot Luck seats against 13/32 for the engine. Moss is on 12-13% of Pot Luck boards against 28-31%, despite its higher weight.\n- No Digest pot at R8 in 28% of seats; R12 240 with a pot (n17) against 183.5 without (n6).\n- With Bubble and no Granny, 7 bodies in 4/50 seat-rounds.\n- The blending runs for every line in tools/sim/lines/; Fairies Ring, Fairies Court and Bog Court's top-six cards move by 3 or more ranks.\n- Pot Luck transitions with Nell grow no faster (1.227, n31, against 1.254).",
   "share_of_gap": "Small on growth, estimated +0.01 to +0.03 a round; larger on placement. These are real faults in the harness."
  }
 ],
 "ruled_out": [
  "Survivor bias flattering Pot Luck's slowness away: counting eliminated seats makes it worse (carried forward 1.165, fixed R14 cohort 1.222, paired 1.230).",
  "Leaving out Bellies: growth with Bellies is x1.252 (99 -> 381). Bellies raise the level by 15-25% and leave the growth unchanged.",
  "The paper itself predicting under x1.3: paper P is about x1.50 a round from R8 to R15 (209 -> 924 -> 2,695 at R9 / R12 / R15).",
  "The two bot fixes moving Pot Luck: x1.254 -> x1.251, R12 200 -> 200, R14 341.5 -> 337 on the same seeds.",
  "Early death or tempo: no Pot Luck seat dies before R9. At R6 Pot Luck has 48.5, the engine 46.5 and Hard 52.5.",
  "Too little concentration: Pot Luck's largest share at R12 is 0.415, against 0.358 for lobby winners. At 0.9-1.1x the lobby median it dies within 3 rounds at the field's rate (0.28).",
  "Other seats taking its copies: the peak share of copies held in a lobby is 0.07 for Soup and Nell, and Pot Luck's R12 median shows no trend with the number of Hard Ooze seats.",
  "A slow climb schedule: 3/5/7/9/11, the same as the engine and ahead of the base strategy.",
  "Placement rules ignored: on 7-body boards from R8, pot at B2 107/107, Nell beside it 27/27, Granny at F2 51/55, Soup at B1 45/47.",
  "Feeding the pot less, as the cause of the gap between the lines: non-Ooze buys per round are 0.60 for Pot Luck and 0.63 for the engine, and Digest Oozes on board are about equal (synth_sink.py).",
  "Tier lag as the main cause: the gap holds with highest card tier and round band held fixed (R8-10, T5 or lower: 1.244 vs 1.329).",
  "The B dials as the main cause: C is estimated to add about +0.02, to about x1.27."
 ],
 "open": [
  "Why Pot Luck converts rounds more slowly at equal pieces: the route's design (no Aspic, one stomach, reserves that never grow, Slices played as bodies) or the bot's valuation (INSIDE_WORTH 0.8 keeping tier 1 holders, possible burial). The jsonl logs no gold use, Belly contents or per-unit stats.",
  "Whether Pot Luck buries Moss, Granny or Hasty inside Bellies. The code allows it and the presence pattern fits, but Belly contents aren't logged.",
  "Whether Nell feeds the pot on Pot Luck boards. Transitions with Nell grow x1.227 (n31, 6 seats), against x1.254 without.",
  "Wee Wobbly and Mrs Posset kept as late holders (65% and 57% of R12 boards, against 0% and 8% for the engine). This follows the route text and INSIDE_WORTH 0.8. Boards with 2 or more holders grow x1.231 (n54), against x1.264 with none (n9).",
  "The fight value of Moss, Granny, Posset and Syllabub, the 200-attack cap and the starting-survivor rule: no fight records were committed.",
  "The Hasty scout trigger and the one-meal-a-turn frequency: the scout and Belly contents aren't logged.",
  "At n=32 the survivor-median R8->R14 interval for Pot Luck (1.147-1.353) covers 1.3. The survivor-robust views don't (paired 1.131-1.272, carried forward 1.124-1.226).",
  "report.md was not written: the harness refused a report file from this subagent. The full report is this output, and its scripts (synth_check.py, synth_split.py, synth_sink.py, synth_tier.py, synth_hasty.py, with .out files) are in /tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/potluck-triage2/."
 ],
 "cards_failing_role": [
  {
   "card": "The Sixpenny Pie (T3, 2/5)",
   "full_text": "Belly 2. When this dies: get 1 gold per unit that comes out.",
   "why": "It is meant as Pot Luck's economy card and spare lives, at R5-8. It adds no permanent stats and pays at most 2 gold, on the turn after it dies. At T3 it competes with Aspic and Bubble and Squeak, which grow the board. Pot Luck boards holding it are smaller: R12 147 (n5) against 239.5 (n18), R14 201 (n5) against 385 (n7). The samples are small. It is a trap in the growth window."
  }
 ],
 "journey_gaps": [
  "R1-6: no gap. Pot Luck is level with the field (R6 48.5, against 46.5 for the engine and 52.5 for Hard), and no seat dies before R9.",
  "R7-9 is the break. The R8->R9 step is +6%, and half the Pot Luck seats hold none of Soup, Nell or Elder at R8. Pot Luck's T3-T4 options give no growth: the Pie pays gold, Syllabub works in the fight, Aspic is excluded, and Frumenty and Figgy are generic. A seat that missed the two T2 pieces has nothing to buy that grows until Elder at T5, so the route skips from T2 to T5.",
  "R10+: the payoffs arrive late or don't count before combat. Elder is first seen at a median of R11.5, against the engine line's R10. Elder Ooze (T5, 4/8: 'After your biggest Ooze eats a non-Ooze: your other Oozes gain half its stats.') works when it is there: x1.376 with Soup (n12), x1.317 without (n18). Granny (first seen R12) is fight-only, and the route plays each Slice as a body. Pot Luck falls to 0.59x the field at R12, and 69% of seats are dead by R14.",
  "No second way through: the engine line has Aspic, a second stomach and eaten Slices. Pot Luck has only the shared Soup, Nell and Elder engine, which is assembled in full in 1 of 32 seats."
 ],
 "is_criterion_failed_for_real": "Yes, for Pot Luck. Every alternative view of growth stays under x1.3:\n- survivor median 1.251 (the defined measure; the point estimate decides);\n- paired per seat 1.230;\n- fixed R14 cohort 1.222;\n- R8->R12 1.228;\n- with Bellies 1.252;\n- last observation carried forward over all 32 seats 1.165.\n\nThe survivor-robust intervals sit wholly under 1.3: paired 1.131-1.272, carried forward 1.124-1.226. The paired engine-minus-Pot-Luck difference over R8-R14 excludes zero (+0.003 to +0.210).\n\nWhat it fails is the wave 2b brief's per-line criterion: each committed line at x1.3 or more. Checkpoint 1's lobby criterion is not at risk here: the lobby median in these 32 lobbies grows x1.373 (99 -> 663.5). The Oozes engine line passes, but only on survivor views (carried forward it is 1.277). Both lines' R12 levels (0.22-0.32x of 900) are the larger shared miss, and that is reported, not deciding.",
 "process_cause": "The design's paper-model step should have caught it, and three steps let it through.\n\n1. **The paper model.**\n   - Line P scripts all seven route cards on time ('scripted arrival rounds stand in for the shop', oozes-pass3.md line 740).\n   - It has no low-roll row: the C and C2 floors exist only for the carry line.\n   - It counts reserves as a fixed gold sink.\n   - Its weak-points section names the two-T2-card risk but reasons on copies ('Both are T2 cards with many copies'). Copies don't matter (peak share held in a lobby 0.07); offers per seat-game do (about 1.2 per specific Ooze).\n   - Why it was missed: the design (9 Nov) came a day before wave 1 triage's rule that the low-roll row removes the keystone (DECISIONS, 10 Nov). The wave 2b brief then called the design 'settled; build them as written'. The builder stated the rule only in words ('Low-roll paper row: remove Stone Soup ... documented here') and never computed it for P. Computed, it gives x1.327 and 248 at R12, close to what the bots realised.\n2. **The harness.**\n   - CommittedLineBrain blends in the base strategy's weights, so every file-loaded line's executed priority differs from its written one, and no check compares the two.\n   - Wave 1 triage's rule 'line files hold only rules a bot runs' passed, because the priority list does run, just blended.\n   - best_belly protects a hard-coded list rather than the line's engine_pieces.\n3. **The line log.** It has no per-card offers, Belly contents, shop tier, gold use or fight records, and every lens hit that wall.\n\nWhere else the same cause applies:\n- the Hedgerow light pass, next in wave 2b, whose pass 3 paper has no keystone-removed rows;\n- every committed line in tools/sim/lines/ (Birds, Fairies, Bog, Hunters, Hedgerow, Oozes), all running blended weights;\n- any second or non-carry route whose paper row scripts its arrivals.",
 "fixes": [
  {
   "rank": 1,
   "kind": "card",
   "fix": "Give Pot Luck a compounding payoff at T3-T4 for what it already does: reserves in front Bellies and one pot meal a turn. Proposals for the design step, briefed without the budget:\n- The Sixpenny Pie becomes 'Belly 2. After your biggest Ooze eats a non-Ooze: units inside this gain half of it.' The gold can stay as its own reward, keeping the full-pie core.\n- Or Elder counts units inside Bellies. The breaker cut this as a runaway; under 09h, dial it back at the outlier.",
   "expected_effect": "Pot Luck's conversion rate per round rises toward the engine's. Piece-less transitions go from x1.21 toward x1.3, and the R8->R9 step recovers from +6%. This targets the cause behind about 90% of the gap between the lines.",
   "how_to_verify": "First a paper row for P with real arrival odds and the keystone removed. Then rerun the 32 lobbies at B. Pot Luck's survivor median should reach x1.3 or more, with paired and carried-forward growth reported beside it, and per-transition growth split by pieces."
  },
  {
   "rank": 2,
   "kind": "card",
   "fix": "Move Elder Ooze to T4, or add a T3-T4 Elder-like family share, to fill the skip from T2 to T5. Generous first: it lifts both lines.",
   "expected_effect": "Elder on Pot Luck boards by R10 rises from 23% to over 40%, and R8-R12 growth rises. In the paper, Elder from R9 rather than R12 is worth about 420 stats at R12.",
   "how_to_verify": "Paper P with Elder at T4 under real arrivals, then the same 32-lobby rerun. Check Elder's first-seen round (now a median of R11.5) and the R8->R12 interval."
  },
  {
   "rank": 3,
   "kind": "bot-bug",
   "fix": "Make the line run as its text says:\n- the line priority overrides the base strategy's weights, for every file-loaded line;\n- best_belly never buries the line's engine_pieces, nor Granny or a wanted Hasty;\n- max_bodies skips the split gap for tempo;\n- Little Dollop or Frumenty counts as the fallback pot when no Digest Ooze is on board (the route's R1-4 step lists Dollop).",
   "expected_effect": "Nell on Pot Luck boards at R8 rises from 16% toward the engine's 38%; pot presence at R8 rises from 72% toward 88%; 7-body boards with Bubble are no longer capped. About +0.01 to +0.03 on growth, more on placement.",
   "how_to_verify": "A unit test that each line's executed weights keep its written order. Then rerun both Ooze lines and the other tribes' lines, whose figures also change, with today's bots as the control."
  },
  {
   "rank": 4,
   "kind": "measurement",
   "fix": "Log per-card offers, Belly contents, shop tier, gold use and fight records in wave2b_lines.gd. Report paired and all-seat growth beside the survivor median. Run one constructed setup (09d): a Pot Luck seat starts R8 with the route's board in the real engine, and the line plays R8-R14.",
   "expected_effect": "This settles the main open point, design against bot, behind the conversion gap, and separates 'weak when assembled' from 'doesn't arrive'. Today's data hints at the first: with pieces, Pot Luck grows 1.27-1.30 against the engine's 1.33-1.35.",
   "how_to_verify": "The constructed Pot Luck board reaches about x1.4-1.5 a round (the cards are fine and the fault is arrival or the bot), or stays near x1.27 (the cards are weak)."
  },
  {
   "rank": 5,
   "kind": "dial",
   "fix": "Raise the Ooze dials to C (Soup 1/6, Elder 3/4), but only together with fix 1.",
   "expected_effect": "Alone, about +0.02 (to roughly x1.27). It matters once the pieces are on the board.",
   "how_to_verify": "Soup and Elder transitions scale by about 4/3 and 1.5, while piece-less transitions stay near x1.21."
  },
  {
   "rank": 6,
   "kind": "measurement",
   "fix": "Process changes:\n- Before a brief calls a design settled, compute every line's keystone-removed row with real arrival odds (offers per seat-game, not copies). Do this for Hedgerow now, before its build.\n- A non-carry route's paper row must show where spare gold goes and whether it compounds.\n- Either record the weight blend in HARNESS.md and the line files, or remove it.",
   "expected_effect": "The next tribe's floor shows on paper before the build, not after the sim.",
   "how_to_verify": "The Hedgerow pass 3 table gains computed low-roll rows per line, and the harness test from fix 3 passes for every line file."
  }
 ],
 "recommendation": "Log the call in DECISIONS: Pot Luck's x1.3 failure is real and robust across every view, but it fails the wave 2b per-line criterion, not checkpoint 1's lobby criterion (lobby median x1.373 here). Don't steer bots away from Pot Luck, and don't treat a dial alone as the fix (C adds about +0.02). Do three things together, with one 32-lobby rerun at B in three arms (bot fixes only; bot fixes plus the card change; one constructed R8 Pot Luck board):\n1. Fix the bot faults as measurement faults across every file-loaded line: the written priority wins, the line's engine_pieces are never buried, no split gap for tempo, and a fallback pot. Today's bots stay as the control.\n2. Send Pot Luck back to the design step, briefed without the budget and generous first (09h), for one compounding payoff at T3-T4 built on its reserves and pot. Options: a reworked Sixpenny Pie, or Elder reaching inside Bellies; plus Elder at T4 if the paper row supports it.\n3. Add the missing logging, so the design-against-bot split behind the conversion gap is settled by data.\n\nKeep the step's two deciding criteria (09i): text equals behaviour, and each committed Ooze line at x1.3 or more on the survivor median, with paired and all-seat growth reported beside it, not deciding. Before Hedgerow's build, apply the same fix to its paper: computed keystone-removed rows per line with real arrival odds."
}
```

## Critic

```json
{
 "verdict": "sound_with_changes",
 "refuted_claims": [
  {
   "claim": "CommittedLineBrain adding the base strategy's weights is a bot fault, no check compares the two, and the blend should be recorded in HARNESS.md or removed for every line.",
   "why": "The blend is deliberate, documented and tested, so it is not a fault. Removing it everywhere would change every tribe's bot policy, which the 'fix cards, not bot routes' rule doesn't cover.",
   "evidence": "HARNESS.md:258: 'Priority bonuses add to Hard's original card bonuses, rather than replacing them.' Test: test_priorities_add_to_hard_knowledge_without_mutating_it (tests/core/test_committed_lines.gd:41), from commit 2e2625a2. The recomputed weights match the synthesis (Elder 26.2 ... Nell 10.5)."
  },
  {
   "claim": "There is no fallback pot; the fix makes Little Dollop or Frumenty count as the pot when no Digest Ooze is on board.",
   "why": "The code already treats any Digest unit as the pot, so the fix changes nothing. The seats without a pot have none of the three Digest Oozes. The real cause is the line's own written priority: little_dollop is 13th of 16 (effective weight 6.5, against the engine's 17.2).",
   "evidence": "BotOoze.carry() picks the biggest Digest unit, and DIGEST is [little_dollop, bubble_and_squeak, frumenty] (pass3_oozes.gd:5). Seats with no Digest Ooze at R8: Pot Luck 28%, engine 12%, Hard Oozes 7%. Pot Luck transitions with none grow x1.189 (n32); with one, x1.295 (critic_pot.out, critic_edge.out)."
  },
  {
   "claim": "Process cause: computed for P, the keystone-removed paper row gives x1.327 and 248 at R12, close to what the bots realised, so the paper step should have caught it.",
   "why": "At B, x1.327 passes the x1.3 bar, so the row would not have flagged this growth failure. The engine's own floor row fails on paper while the engine line passes in the sim. Low-roll rows don't predict which lines pass.",
   "evidence": "Paper at r=1/8: P without Soup and Nell x1.327; C2 floor x1.285, yet the engine line realised x1.369. Only P without Soup, Nell and Elder drops under the bar, to x1.292 (critic_paper.out, critic_paperlines.out)."
  },
  {
   "claim": "Ruled out: a slow climb schedule (3/5/7/9/11, the same as the engine).",
   "why": "This checks the written schedule, not the executed one; shop tier and gold aren't logged. Executed play points the other way. Pot Luck's shortfall sits on the scheduled climb rounds, and only the engine line holds 3 gold back the round before a climb. The paper P route holds 3 back before every scheduled climb; the committed Pot Luck line 'never saves'.",
   "evidence": "Paired steps, Pot Luck against engine: R6->R7 x1.291 / 1.397, R8->R9 x1.171 / 1.293, R10->R11 x1.217 / 1.335. The two climb transitions hold 51% of the R8-R14 log gap (49% in the first run). Boards with a T5+ card: R10 55% against 81%. The save is engine-only in line_brain.gd _held_back; the paper keeps 3 at oozes-pass3-model.py lines 202 and 214 (critic_steps.out, critic_climbsplit.out)."
  },
  {
   "claim": "Ruled out: feeding the pot less, because non-Ooze buys per round are 0.60 for Pot Luck and 0.63 for the engine.",
   "why": "The logger counts buys only by tribe, so neutral buys, a main meal source, are never recorded. The count also includes R1-3 buys, double-counts units with two tribes, and can't separate meals from reserves or board bodies.",
   "evidence": "held_units.gd:102-103 increments bought_by_tribe only for each tribe in unit.tribes(). No 'neutral' key appears in any seat's buys. Neutral offers are 0.93-0.95 a round for both lines (critic_buys.out)."
  },
  {
   "claim": "Journey: Pot Luck's T3-T4 options give no growth, so a seat that misses the T2 pieces has nothing that grows until Elder; the route skips from T2 to T5.",
   "why": "Bubble and Squeak (T3) and Frumenty (T4) are Digest stomachs, and Pot Luck boards holding them grow faster.",
   "evidence": "Frumenty is on 43% of Pot Luck boards at R12. Pot Luck transitions with Bubble x1.278 (without, 1.246); with Frumenty x1.287 (without, 1.235) (critic_edge.out)."
  },
  {
   "claim": "Fix 1 (the Pie's insides gain half of each meal, or Elder counts units inside Bellies) raises Pot Luck's conversion toward the engine's and lifts the survivor median to x1.3.",
   "why": "Both versions grow units inside Bellies. The deciding measure excludes Bellies, and fights run on a copy, so reserves don't reach the board for good. The fix can't directly move the number it is verified against.",
   "evidence": "oozes-summary.json counting: 'Pre-Start-of-Combat active Attack+Health, no Bellies.' Elder's Details: 'not inside Bellies.' The design doc says fights run on a copy, and Bellies empty to hand only when the holder leaves the board outside a fight."
  },
  {
   "claim": "Fix 3's expected effect: Nell on Pot Luck boards rising from 16% toward the engine's 38% is part of the growth gain.",
   "why": "Nell shows no measurable growth effect in any Ooze seat, the engine line included. Raising her presence predicts no growth.",
   "evidence": "OLS over all Ooze seats: Nell x0.994 [0.966, 1.019] over 145 transitions; Soup x1.060 [1.030, 1.090]; Elder x1.045 [1.011, 1.079]. Engine transitions with Nell 1.333, without 1.325 (critic_nell.out)."
  }
 ],
 "missed": [
  "Pot Luck is not the anomaly; the engine line is. With the same controls, Pot Luck grows like Hard seats playing Oozes in the same lobbies (x0.98-0.997, interval covers 1). The engine line runs x1.05 a round above them (1.015-1.092). Paired R8->R12 growth: Pot Luck 1.223, Hard Oozes 1.276, engine 1.319. Placement: Pot Luck 5.30, Hard Oozes 5.23 (critic_pot.out, critic_groups.out).",
  "Half the gap between the lines sits on the scheduled climb rounds. Only the engine holds 3 gold back before a climb, and the paper P route does the same; the Pot Luck line never saves. The pattern repeats in both runs (51% and 49%). The excess over the other rounds is about a quarter of the gap, about +0.017 a round (critic_climbsplit.out).",
  "Dishwater Nell, a paper keystone (+457 at R12 in the ablation), has no realised growth effect: x0.994 [0.966, 1.019]. She belongs in cards_failing_role, with the caveat that the evidence is observational.",
  "The pot shortage follows the line's own text. little_dollop is 13th of 16 in Pot Luck's written priority, while the route's R1-4 step lists Dollop. 28% of Pot Luck seats have no Digest Ooze at R8 (engine 12%, Hard Oozes 7%), and those transitions grow x1.189.",
  "The composition test the synthesis implies, done properly: tier 1 bodies (2.35 against 1.35 at R12), mean tier, highest tier, body count and holders don't explain the gap. Pot Luck stays at x0.94 a round in every specification (critic_regress.out). This supports the main cause's 'rate, not mix', but says nothing about route design against bot.",
  "On the deciding survivor-median measure, the engine-minus-Pot-Luck lobby-bootstrap interval is -0.004 to +0.216, which includes zero (critic_boot.out).",
  "Elder's gap between the lines is not a tier or supply gap. The climb schedule and Ooze offer rate are the same, and Pot Luck weights Elder higher (26.2 against 19.6). Yet Elder is on 23% against 45% of boards at R10, so moving Elder to T4 doesn't target the Pot Luck-specific shortfall.",
  "The brief's criterion 2 reads 'each W2b tribe's committed line' in the singular, so whether a failing second line fails the step is a reading the orchestrator should log."
 ],
 "fix_changes": [
  "Put two diagnostic arms first, before any card change, on the same 32 seeds at B: (a) Pot Luck with the paper's keep-3 rule before scheduled climbs (save_threshold 3, save_until 10, as the engine line and paper P already do); (b) little_dollop moved up Pot Luck's written priority to match its route's R1-4 step. Both are cases where the line diverges from the route the paper costed, so they count as measurement faults under the project rule. Run the 09d constructed R8 board alongside them, with gold, shop tier and Belly contents logged.",
  "Drop fix 1 as written, or restate it so its stats land on active board units. If a Belly-reserve payoff is kept, change the deciding measure explicitly (include Bellies) and log why. Also weigh it against 09a, since it spreads stats over reserves.",
  "Fix 3: drop the harness-wide removal of the weight blend (documented and tested). Drop the 'fallback pot' (the code already has it). Drop Nell's presence as a growth target. Keep the two items that stand: best_belly can bury Moss (it isn't in ENGINES; Moss is on 12% of Pot Luck boards against 28-31%), and the split-gap cap applies to tempo although Pot Luck's text doesn't ask for one.",
  "Reframe the main cause: Pot Luck converts at the Oozes' generic bot rate, and the engine line's policy adds about 5% a round. Leave 'route design against bot' open rather than leaning to route design.",
  "Process cause: replace 'compute the keystone-removed paper row' with 'check each committed line's gold and save rules and written priority against the paper route's', and log gold and shop tier. The low-roll row passes for P at B (x1.327) and anti-predicts the engine (C2 fails on paper at x1.285; the engine passes in the sim).",
  "Move 'slow climb' and 'feeding the pot less' from ruled_out to open. Mark the T3-T4 'skip' as refuted. Downgrade the Sixpenny Pie from 'trap' to 'watch' (5 boards; per transition x1.220, n29, against x1.260). Add Dishwater Nell to the role check.",
  "Fix 2 (Elder to T4) can stay as a 09h option for the tribe, but drop its expected effect for Pot Luck ('Elder by R10 over 40%'), which has no support."
 ],
 "owner_direction_conflicts": [
  "09d: card fixes 1-2 are ranked on observational bot data, ahead of the constructed setup (rank 4). The owner weights constructed setups far above bot play, so they should run before any card change is decided.",
  "09a: both fix 1 options spread stats across Belly reserves; the owner says concentrating stats is always better than spreading them out. The synthesis doesn't address this.",
  "09i: the synthesis keeps 'text equals behaviour' as a deciding criterion but stretches it from the brief's card known-answer tests to bot line weights ('each line's executed weights keep its written order'). In effect, that adds a criterion.",
  "'Fix cards, not bot routes': removing the weight blend for every file-loaded line changes documented, intended bot policy for every tribe. The exception for real bot bugs doesn't cover it. By contrast, matching Pot Luck's save rule and Dollop priority to its own paper route does fall under the exception."
 ],
 "bottom_line": "The symptom numbers recompute exactly, and Pot Luck's failure is real. The engine-over-Pot-Luck gap survives controls for board composition (Pot Luck x0.94 a round, interval [0.91, 0.98]). But Pot Luck grows at the same rate as Hard bots playing Oozes; the engine line is the outlier, about 5% a round above both. Half the gap sits on the scheduled climb rounds. Before those rounds, only the engine line holds back 3 gold, and so does the paper route the design costed; the committed Pot Luck line never saves. The top-ranked card fix grows units inside Bellies, which the deciding measure excludes. Two of the bot 'faults' (the weight blend, no fallback pot) are documented or already-implemented behaviour, and Nell shows no realised growth effect. Run the save-rule and Dollop-priority arms and the 09d constructed board before changing any card. Critique: /tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/potluck-triage2/critic.md"
}
```
