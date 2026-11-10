# Quilboar reference: what it says about our process

The question (owner, 10 Nov): "What have we learned from it? And does it help us improve any of our processes or challenge any of our assumptions?" This part answers the process half. For each thing the reference showed: which of our steps should have caught it earlier, why that step didn't, and what change to the step would. Then the design-doc assumptions the evidence challenges, and what is already fixed against what is still open.

**Read the numbers with these limits.**
- Every lobby figure is from bots, not humans. The Quilboar bot keeps at most 2 off-tribe units from R1 and finds Hogrider about a round late, so its boards are a floor (DECISIONS "Quilboar H1 and merge review: calls", Ask 1).
- Board medians are pre-start boards of surviving seats only, unless a line says "all seats" or "same cohort".
- Arms: B and uncut are post-fix (seeds 2921xxx). C and uncut_frozen are pre-fix (seeds 2911xxx). The size comparison uses pre-fix uncut against frozen, both on 2911xxx labels.
- Native lines: Birds and Fairies are pass 3. Bog, Hedgerow, Hunters and Oozes ran legacy (pre-wave-2a) profiles.
- Tags: **measured** (read off a committed file), **derived** (computed from measured figures or the paper model), **inferred** (my judgement about cause).

## In short

1. **The accounting gate could not tell a bad port from a bad model.** It had already failed on 3 of our 4 wave-1 lines five hours before the H1 plan was frozen. The same band then became a gate on the reference. The change: validate a bar on a known case before it decides anything, and split paper, shop and bot into separate checks.
2. **The paper model scripted every arrival and kept the keystone in its low roll.** All four engine pieces plus T6 were on the paper's schedule in 1 of 150 B seats. The real B median at R12 (259) is below the paper's own low roll (308). The wave-1 triage had found this cause that night, but its list of other places with the same cause left out the reference.
3. **A ratio band at a steep round is a timing test with less than one round of slack.** Measured in rounds, every Quilboar arm runs 1.6–2.1 rounds behind paper at R12. Our wave-1 lines run 0.8–3.4 rounds behind. So, read in rounds, a shared gap is plausible, which reopens the H1 rerun conclusion.
4. **The bot spec was ambiguous twice, and one test locked in the wrong reading.** The early-flex lesson the owner asked for (09f) is the one the bot made unreadable.
5. **The learning arms never ran.** They waited behind two validity gates, and the owner's preferred method (designed setups, 09d) came after bot lobbies. Of the ten questions, 8 and 9 have answers and 5 has part of one.
6. **Costing and paper still treat coupled axes as if they added.** Measured in the engine, freezing gem size cuts uncut R12 by ÷4.7. The paper's ÷11.6 overstates it, but the direction holds. power-budget.md's linear-growth and fixed-reference rules can't see this, and the check that could (B8) is not in force.

---

## 1. What the reference revealed, and which step should have caught it

### 1.1 The accounting gate could not tell a bad port from a bad model

**Revealed**
- **Measured.** B (post-fix) is at 0.45× paper at R9, 0.23× at R12 and 0.70× at R15. C (pre-fix) is at 0.38×, 0.22× and 0.55×. The band is 0.5–2×, so both fail (h1.md, Accounting table).
- **Measured.** The same band at R12 on our wave-1 lines: Homecoming 0.439, Tempo 0.722, Ring 0.268, Court 0.169. Three of four fail (docs/ideation/evidence/wave1-accounting.md, table at line 17).
- **Measured.** B's 0.23× sits inside the native range of 0.17–0.72×. So the gate fails our own lines, which match their paper by construction, about as often as it fails the port.

**Timeline (measured, git log on ideation/main and the plan files)**
- 00:33: Quilboar spec a51d9f39 declares accounting as a deciding criterion.
- 01:27: wave-1 accounting result 1353aa82.
- 02:22: wave-1 triage 034b098e finds that paper scripts arrivals.
- 07:40: the Phase 1 calls say "fix all three before the full H1, because the H1 accounting criterion depends on the bot".
- 07:48 local (20:48Z): the H1 plan freezes `accounting_bounds [0.5, 2]` (quilboar-h1-plan.json `created_utc`).

**Which step should have caught it:** the sim bar (the reference's criterion 1) and review.
- The port review saw the cause but kept the bar: "its R12 hump comes partly from the scripted arrivals (Hogrider at R11). Expect the harness median below paper. Apply the plan's accounting check (0.5–2× of paper) to Quilboar too" (research/port-review.md).
- The spec does the same: "Arrivals are scripted, not shopped. Expect the harness median below paper. The plan's 0.5–2× accounting check applies" (quilboar-port.md §10.4).

**Why it didn't (inferred)**
- The 0.5–2× check began as a diagnostic: when paper misses, fix the paper (plan-v3-interrogate.md item 3b; plan-scale-rework.md:48). As a diagnostic it worked: "The plan's 0.5-2x accounting check is what caught it" (wave1-triage/report.md).
- The reference reused the same band as a gate on the measuring stick: "If it misses, fix the bot or the port's accounting before reading any lesson" (§11.1). The orchestrator then treated it as a bot test (the Phase 1 calls, 07:40), after the triage had shown that the paper's arrivals were the main cause.
- Nobody ran the bar on a known-good case before it decided anything. The wave-1 lines were that case, and they failed it.

**Change**
- **Sim bars:** a bar decides only after it has passed on a case where we know the answer. This is the bar-side twin of prototype LEARNINGS 4 Nov 01:05: "Plant one fault per check before trusting a clean run."
- **Accounting for any measuring stick, split three ways:**
  - **Engine on paper arrivals.** A designed setup scripts the paper's buys and climbs into the engine. Engine against paper tests the port and the rules alone.
  - **Arrival replay.** The triage's proposal: "Every paper model gets an arrival replay." This tests shop supply.
  - **Bot against scripted.** The same seeds with the bot choosing, which tests the policy.

**Status**
- Fixed for the reference: the §11.4 rule that playtests wait for accounting is dropped (DECISIONS "Quilboar H1 and merge review: calls", Ask 3).
- Fixed for paper as a target: "Paper ... isn't a usable target. Targets stay on realized medians" (DECISIONS "Quilboar H1 rerun"; "Wave 1 triage: what we fix", item 1). The wave 2b brief lists paper accounting as reported only.
- **Open:** no rule that a bar is checked on a known case. The three-way split has no tool: the triage's arrival replay was not among the picks, and no designed setup with scripted arrivals has run. plan-scale-rework.md:48 still carries the 0.5–2× "fix the accounting" step.

### 1.2 The paper model assumed on-time arrivals and kept the keystone in its low roll

**Revealed** (scratchpad `arrivals.py`, over committed compact archives)

| B post-fix, 150 seats | Paper round | On time | Never seen |
|---|---:|---:|---:|
| Gem Rat | R5 | 16.7% | 20.0% |
| Bramble Tunneler | R7 | 48.7% | 11.3% |
| Sanguine Refiner | R9 | 33.3% | 6.7% |
| Turbo Hogrider | R11 | 22.7% | 32.7% |
| T5 / T6 | R9 / R11 | 97.3% / 96.0% | — |
| All four pieces and T6 on time | | **0.7% (1 seat)** | |

- **Measured.** uncut post-fix: all on time in 0 of 100 seats; Hogrider on time 25%. C pre-fix: all on time 2%.
- **Measured.** Climbs ran on time but the pieces came late, so the gap is in supply and policy, not in the tier clock.
- **Derived.** The paper's low roll ("Hogrider only at R13", §10.1) gives 308 at R12. The real B median is 259, below the paper's own low roll. The paper's range from low roll to strong (308–1,698) misses the realized median.
- **Measured.** Even seats with Hogrider and T6 by R11 reach only 0.40× paper at R12 in B (453, n=26) and 0.24× in uncut (1,462, n=23). At R15 they reach 0.92× and 0.44×. Getting the keystone on time doesn't close the gap. The other pieces are still late: Gem Rat is on time in 17% of seats.
- **Derived** (scratchpad `paper_variants.py`, on a copy of qm3.py). Every arrival from R5 one round late takes paper B R12 to 0.50× and uncut to 0.40×. Hogrider alone one round late gives 0.77× and 0.69×. §10.4's sensitivity table varies cycling, Rally, sell value and halves, but not arrival timing, the assumption that moves results most.
- **Derived.** Phase 1's missing Roadboar is immaterial: paper with Roadboar as a 4/4 is 1.01× at R12 and 1.00× at R15. It matters only at R6 (45 against 54).

**Which step should have caught it:** the paper model, then the triage's search for other places with the same cause.
- The triage named the cause and its fix that night: "The low-roll row removes the keystone" (DECISIONS "Wave 1 triage", rule 1).
- Its list of where else the cause applies reads: "The same cause is in the Bog, Hunters, Oozes and Hedgerow paper models, in all six tribes' B and C values, in checkpoint 1's 900 and 1,800 targets, and in wave 2's line files." The Quilboar reference is not there, though the same entry says "The Quilboar reference build waits behind this."

**Why it didn't (inferred):** the reference's paper was finished and frozen, and its model looked like a separate workstream. The triage skill's §5 ("list where else the same cause applies") was followed against tribe content, not against frozen plans and criteria that use the same method.

**Change**
- **The triage's "where else" step, as a mechanical search.** When a triage finds a flaw in a method, grep every frozen plan, brief and criterion that uses that method (the 0.5–2× accounting band appears in 10 docs on ideation/main, among them the plan, a brief, HARNESS.md and DECISIONS), and amend or label each one before its next run.
- **Paper models:** label the typical line as a high roll, with its measured chance of being on time. Give the sensitivity table a row for each arrival-timing shift.

**Status**
- Fixed for wave 2's native models (rule 1 above).
- **Open** for the reference's model, which is parked, so the cost of leaving it is low. **Open** as a general tool: there is no arrival replay.

### 1.3 A ratio band at a steep round tests timing, with under a round of slack

**Revealed** (derived; scratchpad `lag.py` and `lag_native.py`, log interpolation on the paper curve)

| Line | R12 real / paper | Rounds behind paper at R12 | Lateness the 0.5–2× band tolerates at R12 |
|---|---:|---:|---:|
| Quilboar B (post) | 0.226 | 2.06 | 0.85 |
| Quilboar C (pre) | 0.217 | 1.79 | 0.77 |
| Quilboar uncut (post) | 0.121 | 1.62 | 0.64 |
| Birds Homecoming | 0.439 | 1.75 | 1.47 |
| Birds Tempo | 0.722 | 0.80 | 1.69 |
| Fairies Ring | 0.268 | 3.21 | 2.07 |
| Fairies Court | 0.169 | 3.38 | 1.56 |

- Paper Quilboar grows ×2.25 (B) and ×2.95 (uncut) into R12. So the band allows less than one round of lateness for Quilboar, and about twice that for our lines. One band is a different test on each line.
- Measured in rounds, the Quilboar arms (1.6–2.1) sit inside our lines' range (0.8–3.4). The rerun's conclusion, "A matching shared gap is not established", rested on ratios, where uncut's 0.121 falls below the native range.
- The lag starts before any engine. At R9 every Quilboar arm is 2.3–2.4 rounds behind. At R6 the real board (33) is below paper's R5 (47).

**Which step should have caught it:** the sim bar's definition, and the report format.

**Why it didn't (inferred):** the band was chosen in board-ratio terms for wave 1, whose curves are flatter at R12. Nobody checked what it means in rounds on a curve with a steep hump, and the hump is the one property the reference was built to show.

**Change:** report paper-against-real as rounds behind (and rounds ahead) as well as the ratio. Read it at rounds where the paper's growth is below about ×1.5 a round, or align on rounds since the commit card.

**Status: open.** Not logged anywhere.

### 1.4 The fidelity bar measured Birds, not the port

**Revealed**
- **Measured.** uncut is 2.38× Birds at R12 [1.50, 3.28] and 5.5–7.7× the other five lines (h1.md, Fidelity).
- **Measured.** Birds' R12 median moved from 271 to 313.5 between the two seed sets with identical Birds code, which the reviewer reads as mostly seed noise (review-quilboar-h1.md, Gaps).
- **Measured.** Four of the six comparison lines ran legacy profiles.

**Which step should have caught it:** the sim bar's design.
- The criterion claims three things at once: "This is proof that the port is faithful, that the cuts are what close the gap, and a direct test of the owner's prediction" (quilboar-port.md §11.1).
- A bar whose denominator is our strongest line fails whenever our line gets better. Birds were re-based upward the same day, and DECISIONS "Birds: no nerf" puts skilled Birds inside the human range.

**Why it didn't (inferred):** fidelity to Battlegrounds was defined against our own lines because that was the data in the lobby.

**Change:** define fidelity on the port's own properties, which BG data can check. These are staple shares and keystone dependence. For example, BG's Choose One wins 29.8% of games and reaches top 4 in 65%. The port at B wins 32% and reaches top 4 in 55%; uncut wins 64% and reaches top 4 in 69% (h1.md, Descriptive B and uncut). Keep "obliterates our lines" as a reported lesson, not as the fidelity test.

**Status: open.** DECISIONS logs the failure and keeps the scale finding, but doesn't say that the bar measured Birds.

### 1.5 Costing and paper treat coupled axes additively; growth is not linear

**Revealed**
- **Measured.** Freezing gem size on the same seed labels cuts uncut R12 from 825.5 to 175.5 (÷4.70) and R15 from 7,718 to 803 (÷9.6). The R15 figure has a survivor caveat: 71% of uncut seats are alive at R15 against 31% of frozen seats.
- **Derived.** The paper said ÷11.6 at R12 and ÷20.1 at R15 (§3.2). The direction holds and the paper overstates the size dial about 2.5× at R12. A multiplicative engine magnifies every late axis.
- **Measured.** Realized gem size against paper:
  - B: 0.67× at R9, 0.75× at R12, 0.63× at R15 (2 / 6 / 9.5 against 3 / 8 / 15);
  - uncut: 0.53× at R12 and 0.46× at R15;
  - C: 0.67× and 0.62×.

  The size engines arrive late too.
- **Measured.** Applications are realized: the median board holds 7 Quilboar from R12 in every arm.
- **Not measurable from the committed archives:** count, meaning Choose One cards played and shop cycles per turn (see the unanswerable list).
- **Measured.** Same cohort (seats alive at R15, B): Quilboar is level with Birds at R12 (323.5 against 316), then grows ×1.93 a round to R15 against Birds' ×1.33 (scratchpad `cohort.py`).

**Which step should have caught it:** costing in power-budget.md.
- It was not run on this content. That is by rule: designers are briefed without the budget, and plan v3 defers "Power budget v2".
- Had it run, its structure prices each effect alone and sums them:
  - "The card's body is then V(t) − Σ cost" (§3);
  - "Linear growth only. The caps assume a fixed s per turn" (§3.2);
  - free inputs at "a fixed reference … 2 at Tiers 5–6 [guess]" that "doesn't re-price old cards" (§3.5), while the paper line plays 3–6 Choose One cards a turn (§10.2).
- The one check that sees combinations is "Check combinations, not cards" (§4.4), and the doc itself says "These bounds aren't in force yet."

**Why it didn't (inferred):** the budget was written for linear, single-card scaling. The only coupling check was deferred, and since then no costing step has run on the ideation branch.

**Change**
- Power budget v2 needs a package rule. A card that moves an axis another card multiplies (a global size, a fan-out, a count source) is priced as part of its package, at the package's measured ablation. Use a frozen-axis arm in the engine, like uncut_frozen, rather than per-card SP.
- Run question 7's two arms when sims resume (Gem Day not counting as Choose One, against half Refiner steps), before using "cut the coupling, not the axis" as a guardrail on Hayward, Stone Soup or Silky.

**Status: open.** Plan v3 step 4 plans budget v2. Question 7 never ran.

### 1.6 The bot spec was ambiguous twice, and a test locked in one misreading

**Revealed**
- **Ambiguity 1, measured.** §9 puts `"max_flex_kept": 2` inside `"flex_policy": {"until_round": 6, …}` under the rule "Before R6 flex". The bot applied the cap from R1, and a test pins it: `test_flex_policy_keeps_at_most_two_off_tribe_units_even_with_empty_slots` (tests/core/test_quilboar_h1_switches.gd on ideation/quilboar).
- **Effect, measured** (scratchpad `early_board.py`, B):

  | Mean units on board | R4 | R6 |
  |---|---:|---:|
  | Quilboar seat | 2.54 | 4.01 |
  | Hard seat | 4.29 | 6.43 |

  - Off-tribe units stay at 1.7–1.95 from R3 to R7: the cap.
  - Median R6 board: 33 for Quilboar, 47 for Hard, 54 on paper.
  - The research says BG winners' boards are 35–45% Quilboar before turn 6 (§2).
- **Ambiguity 2, measured.** The orchestrator's correction "Cycled units are capped at 4 a turn, not refreshes" (DECISIONS "Quilboar Phase 1 review: calls") didn't say whether Created Tunneler cards count. The bot counted them, and DECISIONS "Quilboar H1: both criteria failed" records it: "The frozen build counted them, from my ambiguous wording". The paper model held the unambiguous answer all along: `cycle_cap` 4 applies to shop units, and Tunneler cards are separate (qm3.py).
- **Measured.** The smoke ran one lobby per arm and reported only timing (h1-smoke.md). Four lobbies would have shown 2.5 units at R4.

**Which step should have caught it:** bot specs and review.
- The Phase 1 reviewer compared the code with §9's words and asked for the cap to be built.
- No review compared §9's numbers with the research it cites. The H1 reviewer did that after 500 lobbies.

**Why it didn't (inferred)**
- Bot rules are prose and JSON with no observable attached.
- Corrections are one-line prose in DECISIONS, which the worker implements literally.
- The worker's tests check the worker's own reading.
- This is the third case of a bot not running what its line spec says. The first was wave 1's ignored `thank`, `max_copies` and `stayer_cap` (DECISIONS "Wave 1 triage").

**Change**
- **Bot specs:** each rule carries an observable with a number taken from its source: board fill at R4 within one unit of Hard's; shop-bought and Created cycles counted apart, with at most 4 shop-bought a turn; the keystone's round.
- **Smoke runs:** check those observables on 4–8 lobbies before a frozen run starts.
- **Corrections:** they land as a diff to the spec plus a test written by someone other than the bot's author. Where a paper model exists, the model's code is the spec of record.
- **Effect on the owner's question:** 09f asks that "Early units should be somewhat flexible as well as enabling". The cap makes Quilboar's early game a bot artefact, so question 1 can't be read from H1.

**Status**
- The cycle cap is fixed (4cf1a219; DECISIONS "Quilboar H1: both criteria failed").
- The flex cap is not fixed (stop rule), and is logged as making H1 a floor (Ask 1).
- **Open:** a general rule for bot-spec wording.

### 1.7 A mid-run fix was rerun without predicting its effect, and it split the arms

**Revealed**
- **Measured.** After the cycle fix, B R12 went from 274.5 to 259 (−6%) and uncut from 825.5 to 747 (−10%). These are different seed sets, so the readings are unpaired.
- **Derived.** Paper's own sensitivity table says even no cycling at all moves B R12 only ×0.83 (944 against 1,144, §10.4). From 0.24×, passing needed ×2.08, so no cycling fix could have reached the band.
- **Measured.** The fix left C and frozen pre-fix, and "The frozen arm is not a controlled size ablation against post-fix uncut" (h1.md, header). Question 8 had to use the superseded pre-fix uncut.

**Which step should have caught it:** the rules agents work under (rerun authorization).

**Why it didn't (inferred):** "A fixed bug may move both numbers" was the stated reason, with no size estimate. The stop rule, set beforehand and honoured, limited the damage to one rerun of about 15 minutes of Godot scope time (887 s, verification.json).

**Change:** before authorizing a rerun, read the paper's sensitivity table (or a quick replay) for the fix's largest plausible effect. If it can't cross the bar, don't rerun. If you do rerun, rerun every arm that a deciding comparison pairs with.

**Status: open** (minor). The stop rule itself is good practice and should stay.

### 1.8 Paper constants drifted from the code

**Revealed**
- **Measured.** Rulebook 4.6.2 gives the upgrade to tier 6 a base cost of 11. The game uses 13: `game_config.gd:20-21` reads "Tier 6 by round 11 won too often: the last climb costs 2 more than the rulebook" (DECISIONS 7 Nov "the last climb", marked provisional).
- **Measured.** qm3.py and bog-engine-model.py both use `6: 11`.
- **Measured.** The correction moves paper B R12 from 1,144 to 1,065 (−7%) and uncut from 6,195 to 5,740 (h1.md).

**Which step should have caught it:** the paper model, and rulebook upkeep.

**Why it didn't (inferred):** paper models copy constants from the rulebook, and the rulebook wasn't amended when the code moved.

**Change:** paper models read economy constants from `GameConfig.full_game()` (or a dumped copy of it). Rulebook 4.6.2 gets the slice value, or a delta note.

**Status**
- Logged for this run: "T6 stays at the game's cost of 13" (DECISIONS "Quilboar H1: both criteria failed").
- **Open:** the rulebook text, and the native models that use 11.

### 1.9 94 MB of raw captures went into git

**Revealed**
- **Measured.** ideation/quilboar's history at 6bb7c730 adds 154 `*.fights.jsonl.gz` files of 93.85 MB (git cat-file over the tree). Only hash checks read them. All of tools/sim/evidence on ideation/main is 14.97 MB tracked.
- **Measured.** A precedent existed: wave-1 accounting kept "Raw captures … under build/sim/wave1-accounting/run/" (wave1-accounting.md:89). RESTART's gotchas say "Large screenshot sets bloat history (29 MB). Squash-merge UI-shot branches."

**Which step should have caught it:** the rules agents work under, meaning the brief and the evidence conventions. The reviewer caught it only after the fact.

**Why it didn't (inferred):** the precedent was a habit, not a written rule, and the H1 driver archived for reproducibility without asking who reads what.

**Change:** add one line to HARNESS.md and the brief template: raw captures stay under `build/`, with their hashes in committed receipts. Flag any commit that adds more than a few MB of evidence.

**Status**
- Fixed on the branch: 9374d5e4, "Keep full H1 fight captures out of git and retain their hashes" (DECISIONS "Quilboar H1 and merge review: calls", Ask 2).
- A squash merge is planned, so ideation/main's history won't carry the files. It has not landed: 9374d5e4 is not an ancestor of ideation/main.
- **Open:** the written rule. The branch's own history still holds the 93.85 MB until it is squashed.

### 1.10 The learning arms never ran; bot lobbies went first

**Revealed**
- **Measured.** Of the ten questions (§11.5):
  - **Question 8** is answered, by the size freeze.
  - **Question 9** is answered. B seats with Hogrider by R12 place 2.92 on average and win 44%, against 5.46 and 14% without it. In uncut: 2.16 and 75%, against 4.48 and 39%.
  - **Question 5** is half answered. Quilboar compounds late in the same cohort (1.5 above). Lobbies run to R18–19, and none end by R14 in any arm.
  - **Questions 1–4, 6, 7 and 10** have no data: H2–H5, D1–D6 and P never ran.
- **Measured.** §11.6 puts the designed setups after the H1 criteria, and §11.4 puts playtests "only after criterion 1 passes". After the failure, DECISIONS says "stop the sim work after the merge" (Ask 3).

**Which step should have caught it:** the plan, and the rules agents work under.
- The owner's purpose was lessons: "getting a feel for how our tribes play against those would be instructive in teaching us some design lessons" (09f).
- The owner's method ranks constructed setups above bot lobbies: "The bots will not be good players … if you can instead create empirical simulations, at various turn thresholds, with various setups of things you think might be strong, that will be far more reliable" (09d).
- The Choose One line, with its cycling, is the kind of many-actions-a-turn play 09d says bots execute badly. Yet the deciding gate was the bot's ability to reproduce the paper.

**Why it didn't (inferred):** "at most two deciding criteria" (09i) was filled with two validity checks. When they failed, the stop rule halted the lessons too. And the designed setups were scheduled as follow-ups to the lobbies, not as the main measurement.

**Change:** in a step whose purpose is lessons, the deciding criteria say "lesson X can be read", one per lesson. Validity checks are reported, and when one fails it routes to a cheaper measurement that doesn't depend on the bot's shop (a designed setup). Run designed setups first (09d; plan v3's "they outrank line lobbies").

**Status**
- Partly fixed: the playtest gate is dropped, and one optional playtest arm stays (Ask 3).
- **Open:** whether to run D1, D4 and D5 at least. They answer the owner's named lessons (early flex, wide against tall, retroactive against future-only size) without the bot's shop.

### 1.11 Survivor-only medians at late rounds

**Revealed** (scratchpad `survival.py`, B)
- **Measured.** Alive at R15:

  | Quilboar | Birds | Bog | Hunters | Oozes |
  |---:|---:|---:|---:|---:|
  | 55% | 85% | 33% | 26% | 19% |

- **Measured.** All-seat R15 medians (eliminated seats = 0): Quilboar 773.5, Birds 604. Survivor-only medians: 2,339 and 737.
- **Measured.** The accounting "pass" at R15 (0.70×) is on 55% of B seats.
- **Measured.** Within the same cohort the "compounds late" lesson holds: ×1.93 against ×1.33 a round. So the lesson stands, but the population ratios at R15 (3.2× Birds) mix growth with who survived.

**Which step should have caught it:** the sim bar and report format. The wave-1 triage noted survivor bias as reported-only (DECISIONS "Wave 1 triage").

**Change:** report survival and a same-cohort reading beside every late-round median. Don't let a late-round bar pass on a selected population.

**Status:** open. The DECISIONS lesson "It compounds late" is right, but carries no cohort caveat.

### 1.12 Smaller misses

- **Measured: shop dilution not reported.** The spec promised "Adding a seventh tribe thins every shop, so that dilution is reported too" (§11.1). h1.md has no dilution figure. H1 ran `tribes_per_lobby` 0. That is needed for all-lines lobbies, but it is the same gap the wave-1 triage logged ("The accounting run also used `tribes_per_lobby` 0, not the shipped 5"), so H1's arrivals likely run later than in a shipped lobby (inferred). **Open.**
- **Measured: a stale range in the restart guide.** RESTART.md:478 still says "0.17–0.44× of paper for our tribes". The branch fixed h1.md in 25fc1576, and the correct range is 0.17–0.72×. **Open** (small).

---

## 2. Assumptions in our design docs that this evidence challenges

| Doc line (quoted) | Evidence | Kind | Status |
|---|---|---|---|
| power-budget.md §3.2: "**Linear growth only.** The caps assume a fixed s per turn." | A global future-only size makes the per-turn gain grow every turn. Same-cohort Quilboar grows ×1.93 a round from R12 to R15 at B, against Birds' ×1.33. Freezing size divides uncut R12 by 4.7. | measured | Open (budget v2) |
| power-budget.md §3: "The card's body is then V(t) − Σ cost" | Effects are priced alone and summed. Gem Day moves size and also count × applications through Hogrider (§3.1). The axes multiply, so shortfalls compound: realized size at R12 is 0.53–0.75× paper, and the board 0.12–0.23×. | derived | Open |
| power-budget.md §3.5: "0 free cards or casts a turn at Tiers 1–2, 1 at Tiers 3–4, 2 at Tiers 5–6 **[guess]**" … "It is fixed, so adding a new free source doesn't re-price old cards." | The paper line plays 3–6 Choose One cards a turn (§10.2), so a fixed reference of 2 underprices "after you play" payoffs by 1.5–3×. Realized count isn't in the committed archives. | inferred | Open |
| power-budget.md §4.4: "**Check combinations, not cards.**" / "**These bounds aren't in force yet.**" | The principle is right, and the evidence says this is where the scale comes from. Nothing enforces it. | inferred | Open |
| rulebook.md 4.6.2: upgrade to 6, base cost 11 | `full_game()` uses 13 (game_config.gd:21). Paper models copied 11 (qm3.py; bog-engine-model.py), so paper R12 sits 7% high. | measured | Open |
| quilboar-port.md §3.1: "Our proportional tribes add a share of their own board (`G = r × Board`), so they grow as `(1 + r)^t` and catch up later." §0: "By R15, seven of the twelve lines are level or ahead." | Reversed in the engine: at B, Quilboar trails Birds at R12 (259 against 309) and leads every line at R15 (2,339 against Birds' 737). Same cohort, it is level at R12 and 3.17× at R15. | measured | Logged as a lesson ("It compounds late"); the paper text is unchanged |
| quilboar-port.md §0: "Size is the strongest dial: freezing it costs ×4.3 at R12 and ×7.1 at R15 at B" (uncut on paper: ÷11.6 / ÷20.1) | Uncut measured ÷4.70 at R12. The direction holds (the owner's 09g prediction) and the magnitude is overstated about 2.5×. B was never measured frozen. | measured / derived | Logged (question 8); the magnitude is not logged |
| quilboar-port.md §10.4: "Arrivals are scripted, not shopped. Expect the harness median below paper. The plan's 0.5–2× accounting check applies." | It contradicts itself: it expects a one-sided miss but uses a two-sided band. On time in 0–2% of seats. | measured | Gate dropped (Ask 3) |
| quilboar-port.md §10.1: "**Low roll:** … Hogrider only at R13." | 33% of B seats never see Hogrider. The real median (259) is below this low roll (308) at R12. | measured | Open for the reference; fixed for native models (DECISIONS "Wave 1 triage", rule 1) |
| quilboar-port.md §11.1: "This is proof that the port is faithful, that the cuts are what close the gap, and a direct test of the owner's prediction." | The bar's failure came from Birds' strength (2.38×) while the other five lines were 5.5–7.7×. Birds moved 271 → 313.5 on seed noise alone. | measured | Open |
| quilboar-port.md §9: `"flex_policy": {"until_round": 6, …}` with `"max_flex_kept": 2` | It reads as a cap from R1: 2.5 units at R4 against Hard's 4.3. The research says BG winners are 35–45% Quilboar before turn 6. | measured | Logged as a floor (Ask 1); not retuned |
| DECISIONS "Wave 1 triage": "Replaying them with real arrivals reproduces the measured ratios." | Not tested for Quilboar. Seats with the keystone and T6 on time still reach only 0.40× (B) and 0.24× (uncut) of paper at R12. That doesn't refute the claim, since the other pieces are still late, but it doesn't show it either. | measured | Open |
| DECISIONS "Quilboar H1 rerun": "A matching shared gap is not established." | In rounds behind paper at R12, the Quilboar arms (1.6–2.1) sit inside our lines' range (0.8–3.4). The ratio framing made uncut look like an outlier because its paper curve is steeper. | derived | Open: worth reopening before anyone cites it |
| plan-scale-rework.md:48: "if Birds' or Fairies' real R12 board is outside 0.5–2× its paper figure, fix the accounting in the wave 2 briefs before their dial values land." | Superseded by the realized-median targets (DECISIONS "Wave 1 triage", item 1), but the plan text is unchanged. | measured | Open (text) |
| wave1-triage/report.md: "A keystone under about 60% gets a second card doing its job at another tier." | This holds as a guide. BG's most-played comp, ported, finds its keystone by R12 in 61% of B seats (accounting-checkpoint.json `keystone_found_by_r12` 0.607), and the seats without it place 5.46 against 2.92. Our 60% line sits where BG's own top comp lives in our engine. That's bot data in a 7-tribe pool. | measured / inferred | No change needed |

---

## 3. Already fixed against still open

**Fixed** (by entry)
- **Accounting no longer gates the reference's playtests:** "Quilboar H1 and merge review: calls", Ask 3.
- **Paper is not a target; targets are realized medians:** "Quilboar H1 rerun"; "Wave 1 triage: what we fix", item 1; wave2b-build.md lists paper accounting as reported only.
- **Low-roll rows remove the keystone, and conditions are checked against trigger timing, for wave 2's native models:** "Wave 1 triage", two rules.
- **The cycle cap excludes Created cards:** "Quilboar H1: both criteria failed; one fidelity fix, one rerun" (commit 4cf1a219).
- **Tuning stopped on failure, and the stop rule was honoured:** "Quilboar H1 rerun" (review-quilboar-h1.md, probe 4).
- **Raw captures are out of the branch tree:** "Quilboar H1 and merge review: calls", Ask 2 (commit 9374d5e4). The squash merge into ideation/main is still pending.
- **Lessons logged:** the third axis is the gap (question 8); it compounds late. Both are in "Quilboar H1 and merge review: calls".
- **The native range in h1.md is corrected to 0.17–0.72×:** commit 25fc1576 on ideation/quilboar.

**Still open**
1. **Bars:** a rule that a bar decides only after it passes on a known case.
2. **Accounting:** an accounting split into engine-on-paper-arrivals, arrival replay and bot against scripted. There is no tool for it yet.
3. **Rounds-behind reporting:** paper-against-real in rounds, beside the ratio. With it, reopen "no shared gap".
4. **Fidelity:** defined on the port's own properties, not on our lines' strength.
5. **Costing:** a coupled-axis package rule in power budget v2, and question 7's arms, before coupling is used as a guardrail.
6. **Bot specs:** rules carry observables with numbers. The smoke run checks behaviour. Corrections land as spec diffs plus a test written by someone other than the bot's author.
7. **Reruns:** predict a fix's effect before a rerun; rerun paired arms together.
8. **Constants:** paper models read constants from the game config. Rulebook 4.6.2 still says 11 for T6.
9. **Evidence size:** a written rule (HARNESS.md and the brief template).
10. **Learning steps:** lesson-readability criteria, with designed setups first. Choose whether to run D1, D4 and D5.
11. **Triage "where else":** a mechanical grep of frozen plans and criteria when a method flaw is found.
12. **Survival:** survival and a same-cohort reading beside late-round medians.
13. **Small text fixes:** plan-scale-rework.md:48; RESTART.md:478; dilution never reported.

---

## 4. Scripts and outputs (scratchpad)

All are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/quilboar-lessons/`. They read only committed compact archives (`*.lobbies.json.gz`) and a scratch copy of the paper model. No Godot ran.

- `arrivals.py` → `arrivals.json`: piece and tier arrival rounds, on-time shares, board shape, gem size, conditional accounting and placement by Hogrider.
- `paper_curves.py` → `paper_curves.json`: paper curves R5–R16 for B, C and uncut at T6 = 11 and 13 (from `model/`, a copy of qm3.py, presets3.py and final3.py).
- `paper_variants.py`: paper without Roadboar; every arrival one round late; Hogrider one round late.
- `lag.py`, `lag_native.py`: rounds behind paper, and the lateness the 0.5–2× band tolerates.
- `early_board.py`: units on board and off-tribe count from R3 to R8 against Hard and the native lines.
- `game_length.py`: lobby length, winners, and the round non-winning Quilboar seats go out.
- `survival.py`, `cohort.py`: survival by line, all-seat medians, and same-cohort growth from R12 to R15.
