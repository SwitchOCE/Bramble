# Skeptic check: the process lens (process.md)

I re-read each source and recomputed each number with my own scripts. The scripts read only the committed compact archives (`*.lobbies.json.gz`) and a scratch copy of the paper model. No Godot ran, and nothing was written outside the scratchpad. All lobby figures come from bots, not human frequencies.

My scripts are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/quilboar-lessons/check-process/`:
- `ck_arrivals.py`: piece and tier arrivals, conditional medians, placement by Hogrider, gem size and Quilboar count. It covers all six arm archives.
- `ck_lobby.py`: survival, all-seat medians, same-cohort growth, early board fill, game length and median jumps.
- `ck_size.py`: pre-fix uncut against frozen, for survivors and for all seats.
- `ck_paper.py` and `ck_paper_board.py`: paper no-cycling sensitivity, the T6 = 13 correction, the paper curves, and the paper's early boards. They run on `model/`, a copy of qm3.py, presets3.py and final3.py.

Verdicts in short: 5 hold, 6 need a correction, 2 overreach.

| # | Finding | Verdict |
|---|---|---|
| 1 | Accounting gate failed on 3 of 4 native lines before H1 froze it | holds |
| 2 | Paper scripted arrivals; real B median is below the paper's low roll | holds (one denominator caveat) |
| 3 | Getting the keystone on time doesn't close the gap | holds |
| 4 | Measured in rounds behind paper, the Quilboar gap is inside the native range | holds (weak test) |
| 5 | The fidelity bar measured Birds and seed noise | **overreaches** |
| 6 | Size freeze: ÷4.70 measured against paper's ÷11.6; sizes are late | holds |
| 7 | power-budget.md would misprice coupled scaling | **overreaches** |
| 8 | Bot spec ambiguous twice; the smoke checked only timing | **corrected** |
| 9 | The rerun could not have crossed the bar | **corrected** |
| 10 | T6 cost drift (11 against 13) | **corrected** (the drift is wider) |
| 11 | 94 MB of captures went into branch history | holds |
| 12 | Learning arms never ran because they waited behind gates | **corrected** |
| 13 | Smaller misses (dilution, tribes_per_lobby, stale ranges) | **corrected** |

---

## 1. The accounting gate could not tell a bad port from a bad model: holds

- **Measured:** `wave1-accounting.md` table rows at R12: Homecoming 0.439 (marked "False (config-sensitive)"), Tempo 0.722, Ring 0.268, Court 0.169. Three of four fall outside 0.5–2×.
- **Measured:** `h1.md` Accounting gives B post-fix at R12 0.226, inside 0.169–0.722.
- **Measured, timeline from `git log --date=iso`:**
  - a51d9f39 at 00:33:53;
  - 1353aa82 at 01:27:39;
  - 034b098e at 02:22:49;
  - 75d4bbf2 (Phase 1 calls) at 07:40:08;
  - `quilboar-h1-plan.json` `created_utc` 2026-11-09T20:48:52Z (07:48 local), with `accounting_bounds [0.5, 2]`.
- **Measured, quotes:** "the H1 accounting criterion depends on the bot" (DECISIONS, Phase 1 calls) and "Apply the plan's accounting check (0.5–2× of paper) to Quilboar too" (`research/port-review.md`) are both verbatim.
- **Small note** (process.md body, not the JSON claim): "our own lines, which match their paper by construction" is wrong. The native lines miss their paper for the same reason Quilboar does, which is scripted arrivals. The band appears in 14 files on ideation/main, not 10 (`git grep`).

## 2. Paper scripted arrivals; the real median is below the low roll: holds

- **Measured (`ck_arrivals.py`, B post-fix, n = 150).** On time: Gem Rat 16.67%, Tunneler 48.67%, Refiner 33.33%, Hogrider 22.67%. T5 is on time in 97.33% of seats and T6 in 96.0%. All four pieces plus T6 are on time in 1 seat (0.67%). Uncut post-fix: 0 of 100. C pre-fix: 3 of 150 (2%).
- **Derived (`model/final3.py`).** B low roll at R12 = 308, typical = 1,144, strong = 1,698. The real median is 259.
- **Caveat on "never seen 32.7%".** The denominator includes seats eliminated before R11. Among seats alive at R15, only 11.0% never field Hogrider. Hogrider by R12 is 60.7% (on board), which equals `keystone_found_round` (60.7%).
- **Measured.** The triage report's "where else" list (`wave1-triage/report.md:94`) names Bog, Hunters, Oozes and Hedgerow, all six B/C values, the 900/1,800 targets and the line files. It does not name the reference, although DECISIONS "Wave 1 triage" says "The Quilboar reference build waits behind this".
- **Already adopted for native lines:** "Paper lines stay, labelled as high rolls" (triage item 1).

## 3. The keystone on time doesn't close the gap: holds

- **Measured (`ck_arrivals.py`, seats with Hogrider and T6 by R11).**
  - B at R12: n = 26, median 453, 0.396× of 1,144.
  - B at R15: n = 21, median 3,101, 0.922×.
  - Uncut at R12: n = 23, median 1,462, 0.236×.
  - Uncut at R15: n = 22, median 10,466.5, 0.437×.
- The selection is on one piece only, and Gem Rat is on time in 16.7% of seats. So this doesn't refute the triage claim either, as the claim says.
- **Measured.** It is cited for Quilboar implicitly. DECISIONS "Quilboar H1: both criteria failed" says the shortfall "looks like it comes from the method (paper assumes guaranteed arrivals)". RESTART.md:478 reads "Paper models overestimate when they assume arrivals … 0.12–0.23× for Quilboar". So "an arrival replay before citing it" is fair.

## 4. Rounds behind paper: holds, but the test is weak

- **Derived, recomputed by hand from the paper curves (`ck_paper.py`) and `wave1-accounting.md`, log interpolation.**
  - Rounds behind at R12: B 2.06, C 1.79, uncut 1.62; Homecoming 1.75, Tempo 0.80, Ring 3.21, Court 3.38.
  - Lateness the band tolerates at R12: B 0.85, uncut 0.64; native lines 1.47–2.07.
  - Paper growth into R12: ×2.25 (B) and ×2.95 (uncut).
  - At R9: B 2.44, C 2.38, uncut 2.35 rounds behind.

  All of these match.
- **Caveats.**
  - The native paper curves exist only at R8/10/12/14, so their lateness and tolerance are interpolated over two-round steps. The Quilboar curve is sampled every round, with its R11–R12 hump.
  - The native range is four points spanning 2.6 rounds. "Inside" it is a weak test, and no interval was computed in rounds.
- The finding does undercut DECISIONS' reasoning "The two arms disagree about the gap": measured in rounds, B and uncut agree. But rounds don't establish a shared gap either. "Revisit before citing" is the right size of implication. The body's "a shared gap is plausible" goes further than the numbers.

## 5. The fidelity bar measured Birds' strength and seed noise: overreaches

- **Measured (`h1.md` Fidelity).** Uncut is 2.38× Birds [1.50, 3.28] and 5.53–7.70× the other five lines. Four of the six comparison lines are legacy. The Birds move 271 → 313.5 is verbatim from the review, with identical Birds code (4cf1a219 touches only `bot_quilboar.gd` and its test).
- **Why "measured Birds' strength" is the wrong reading (derived).** Paper uncut against paper Homecoming at R12 is 6,195 / 615 = 10.1×. Real is 2.38×. In the same lobbies, Birds realizes 313.5 / 615 = 0.51 of its paper, and the Quilboar seat realizes 0.121. Birds is still below its paper. The bar fails because the Quilboar seat realizes a quarter as much of its paper as Birds does, and that is partly a fidelity fact about the reference's bot and shop: the flex cap and the late Hogrider.
- **Seed noise didn't decide the verdict.** Both runs' intervals exclude 4 ([2.19, 3.97] and [1.50, 3.28]).
- **The proposed replacement has the same flaw.** Win and top-4 rates depend on the field, so they inherit the denominator problem the finding complains about. They also don't compare like with like:
  - BG's 29.8% / 65.3% (`research/guides.md:43`) is conditional on players who ended in Choose One;
  - the port's seat is assigned from R1 and plays against our bot lines.

  Staple shares and keystone dependence are port-intrinsic and checkable. Win shape is not.

## 6. Size freeze: holds

- **Measured (`ck_size.py`).** Pre-fix uncut against frozen at R12, survivors: 825.5 against 175.5, ÷4.70.
  - With all seats and eliminated seats as 0: 645.5 against 137.5, ÷4.69. So R12 is robust to survival, with 80 against 68 seats alive.
  - At R15, survivors: 7,718 against 803 (÷9.61), with 71% against 31% alive. All-seat frozen is 0, so R15 is not usable.
- **Derived.** Paper "size off" for uncut gives 532 / 1,190, which is ÷11.6 and ÷20.1. 11.6 / 4.70 = 2.47.
- **Measured.** Realized gem size, attack side (engine field `gem_attack_halves` ÷ 2, against paper S):
  - B: 2 / 6 / 9.5 against 3 / 8 / 15;
  - uncut: 10 / 16 against 19 / 35;
  - C: 10 / 18 against 15 / 29.

  The median Quilboar count is 7 at R12 and R15 in every arm. All match.
- **Caveat.** "Paper sizes are upper bounds" holds for these bots and the paper's typical line. The paper's strong line is higher, and a better player is untested.
- **Measured.** DECISIONS logs the measured 825.5 → 175.5. What is missing is the comparison with paper's ÷11.6.

## 7. power-budget.md would misprice coupled scaling: overreaches

- **Measured.** All four quotes are verbatim and in the stated sections:
  - §3 line 172;
  - §3.2 line 206;
  - §3.5 line 352;
  - §4.4 lines 456 and 458.

  Paper Choose One plays per turn R9–R16 at B are [3, 4, 3, 6, 5, 5, 6, 6] (final3.py), and 4–8 in uncut.
- **Measured.** Same-cohort growth from R12 to R15 is ×1.934 for Quilboar and ×1.326 for Birds (`ck_lobby.py`).
- **Why it overreaches.**
  - The doc already disclaims this. §3.2 says v1 prices geometric growth "only when the text is once per turn and can't be retriggered" (a content rule, question 9). §3.2 also counts "this game" text reaching later units in its magnitude (E12). §3.4 lists card generation among its guesses.
  - So "would misprice" mostly restates the doc's own limits. It was never run on this content.
  - The implication asks budget v2 to price packages at a measured ablation. Plan v3 defers budget v2 as "guardrails and a 'too small' test, not a price list" (plan-scale-rework.md:203, the v2 step 4 that v3's step 7 keeps).
  - No doc has adopted "cut the coupling" as a guardrail yet. §11.5 Q7 already makes it wait on Q7's arms.
- The useful part is narrow: the free-input reference (2 a turn at T5–6) is below the paper line's 3–6 Choose One plays a turn.

## 8. Bot spec ambiguity and the smoke: corrected

- **Measured (`ck_lobby.py`, B).** Mean units: 2.54 at R4 and 4.01 at R6, against Hard's 4.29 and 6.43. Off-tribe mean at R3–R7 is 1.70 / 1.95 / 1.92 / 1.89 / 1.82. R6 medians: 33 against 47, with paper at 54. All match.
- **Measured.** The test `test_flex_policy_keeps_at_most_two_off_tribe_units_even_with_empty_slots` exists (tests/core/test_quilboar_h1_switches.gd:241 at 25fc1576).
- **Measured.** "My ambiguous wording" is verbatim in DECISIONS.
- **Correction 1: it is not a misreading.** §9 puts `max_flex_kept: 2` inside `flex_policy {until_round: 6}`. Literally, that is a cap during R1–R5, which is what the bot built.
  - The Phase 1 reviewer asked for exactly this ("The 2-flex-unit cap isn't built").
  - The orchestrator's call was "The 2-flex-unit cap is built."
  - The H1 reviewer calls the spec "ambiguous". The test locked in the spec's literal reading, which a review asked for. A test by a second author would likely have pinned the same thing.
- **Correction 2: the smoke did more than timing.** The smoke report (68b0b42a) originally printed the full descriptive tables for one lobby per arm, with "usability verdicts withheld". The file was cut to timing at 10:17 (12911e7c, review Simplify 2). Those four smoke lobbies already showed the gap. Quilboar had 3 / 2 / 2 / 2 units at R4 (mean 2.25), against Hard's 6 / 6 / 4 / 5 (mean 5.25), from the smoke archives. The data was there; nobody checked it against an observable.
- **Correction 3: the paper is thin early too.** `ck_paper_board.py`, typical at B:
  - R4: 3 units, 1 flex (geomancer, flex3, roadboar);
  - R5–R6: 6 units, 1 flex;
  - so 67–83% Quilboar before R6, against the research's 35–45% (`research/structure.md:179`).

  The bot is close to its paper at R4 (2.54 against 3) and short at R6 (4.01 against 6). So "the paper model's code is the spec of record" would not have fixed early flex. An observable taken from the research would have.
- **What holds:** early flex can't be read from H1. Smoke runs should check numeric observables on the lobbies they already run.

## 9. The rerun could not have crossed the bar: corrected

- **Measured.** B R12 went 274.5 → 259 (−5.6%) and uncut 825.5 → 747 (−9.5%), on different seeds. The scope time was 887.07 s (`quilboar-h1-cycle-fix/verification.json`).
- **Derived (`ck_paper.py`).** No cycling gives B R12 944 / 1,144 = ×0.825. The paper cycles only 2 a turn at R12, under the cap of 4. So the fix's ceiling is about ×1.21, against the ×2.08 that accounting needed (0.5 / 0.24). **For accounting, this holds.**
- **For fidelity, it was closer.**
  - It needed 4 / 3.05 = ×1.31.
  - Paper's ceiling for uncut is ×1.20 (no cycling 5,167 / 6,195 = ×0.834).
  - The first run's interval already reached 3.97, and the Birds denominator moves about 15% with seeds.

  Unlikely, but not ruled out by the table. DECISIONS' stated reason was "A fixed bug may move both numbers."
- **The implication's own rule wouldn't have required rerunning frozen.** The size comparison was a reported lesson (Q8), not a deciding comparison.

## 10. T6 cost drift: corrected (wider than stated)

- **Measured.**
  - Rulebook 4.6.2 gives 5, 7, 8, 11, 11.
  - `game_config.gd:20–21` gives `SLICE_UPGRADE_COSTS [5, 7, 8, 11, 13]`, and `full_game()` uses it (line 122).
  - The paper correction is B R12 1,144 → 1,065 (−6.9%) and uncut 6,195 → 5,740 (−7.3%), recomputed.
- **Correction.** It isn't just qm3.py and bog-engine-model.py. `6: 11` is also in:
  - the pass 3 models for Birds, Fairies, Hedgerow and Oozes (`docs/ideation/content/pass3/*-pass3-model.py`);
  - oozes-wild-model.py;
  - the triage's copies.
- The wave-1 native ratios (0.17–0.72×) also use 11-cost denominators, so the Quilboar comparison against them is like for like.

## 11. 94 MB of captures: holds

- **Measured.** `git ls-tree -r -l 6bb7c730` holds 154 `*.fights.jsonl.gz` files, 93.85 MB. ideation/main HEAD's tools/sim/evidence is 14.97 MB. 9374d5e4 and the squash 1511dc22 are not ancestors of HEAD, and 1511dc22 contains 0 capture files.
- **Context the finding leaves out.**
  - `build/` is gitignored, so the precedent was structural.
  - DECISIONS (fixes narrow check) says "the captures were never pushed".
  - A backup exists in `/home/alex/backups/bramble-quilboar-h1-captures/`.
  - ideation/main never carried the files. What is pending is merging the squash after Actions.
- The rule gap is real: HARNESS.md describes captures under `build/`, but nothing says don't commit them.

## 12. The learning arms never ran: corrected

- **Measured.**
  - Q9: B with Hogrider by R12: n = 91, mean place 2.923, 44.0% first. Without it: n = 59, 5.458, 13.6%. Uncut: 2.159 / 75.4% against 4.484 / 38.7%.
  - Game length: median last round 18.5 (B), 18.0 (uncut), 19.0 (C), 18.0 (frozen); no lobby ends by R14.

  All match.
- **Correction 1: Q3 has an H1 part.** §11.5 Q3 is measured by "H1 largest one-round jump", and H1 has it:
  - B median R11→R12 ×2.38, R12→R13 ×3.13;
  - uncut R11→R12 ×5.34;
  - paper B: ×1.90 into R11, ×2.25 into R12.

  So the jump is real, bigger and a round later than paper. Only the "is it fun" half needs P.
- **Correction 2: the "because" is half the story.** §11.1 and §11.4 did put lessons behind the criteria. But Ask 3 then dropped the playtest gate ("accounting fails for three of four native lines as well, so it can't gate anything"). It stopped sim work by choice, citing 09i's focus. Running D1/D4/D5 reopens that logged call, so it is a direction choice, not a fix to an error.
- The 09d quote is verbatim.

## 13. Smaller misses: corrected

- **RESTART.md:478 is stale information.** 7274cd2b (10:36) corrected it, and it now reads "0.17–0.72×". The old range survives at RESTART.md:100 ("0.17–0.44× … (Tempo, at 0.72, is the outlier)") and in the dated DECISIONS records.
- **Dilution.** §11.1 sets the control as "checkpoint 1's own step-5 lobbies", which haven't run. So the dilution report is not due yet, rather than missed.
- **tribes_per_lobby 0** is confirmed in all four arm configs. H1 needed it to seat all seven tribes (smoke README: "All seven tribes are present"), so it is a known cost, not a miss.
- plan-scale-rework.md:48 still carries the 0.5–2× fix-the-accounting step. That holds.
