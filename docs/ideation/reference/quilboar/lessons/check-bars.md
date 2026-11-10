# Skeptic check: the "bars" lens (bars.md)

**What I checked:** each of the 21 findings in `bars.md`. I recomputed the numbers with my own loader, which doesn't use `qload.py`, from the committed compact archives (`*.lobbies.json.gz`) and `summary.json.gz`. I also re-read the paper (`quilboar-port.md` §0, §3, §6, §10, §11.5), `reference-curves.md`, plan v3 (`plan-scale-rework.md`, "What decides checkpoint 1"), DECISIONS (9–10 Nov entries), `tools/sim/HARNESS.md` (strength gate) and PLAN.md's Done means.

**Scripts and outputs:** `check/bars/ck_load.py` and `ck1.py` to `ck6.py`, each with a `ck*-out.txt` beside it, all in this folder. Python only, sources read-only, no Godot.

**Result:** 4 hold, 10 need correcting, 7 overreach.
- The arithmetic is almost all right: every headline number reproduces to the stated precision.
- The problems are in what the numbers are compared against, and in implications that go past them.

**Common caveats** (these apply to every finding):
- All of it is bot data from 100–150 lobbies an arm. None of it is human frequency.
- Native seats were fixed: Birds and Fairies were wave 1 (pass 3), and the other four were legacy profiles. They also ran with the broad Busker guard (DECISIONS 10 Nov, Gap 1).
- `summary.json.gz` labels lobby growth "descriptive ... no pass/fail bar" for these lobbies.

---

## 1. Lobby median fails ×1.3 in every arm: **holds**
- **Recomputed:** B 1.244 [1.226, 1.278], C 1.257, uncut 1.255 [1.230, 1.298], frozen 1.236, pre-fix uncut 1.279 [1.255, 1.302]. Every point estimate is below 1.3. Pre-fix uncut's interval crosses 1.3, but the point estimate decides (DECISIONS 10 Nov, Ask A). Source: `summary.json.gz` `all_seat_growth_r8_r14`, and `ck1`.
- **Caveat:** checkpoint 1 applies this bar to the shipped pass 3 pool, not to reference lobbies. "Reads the typical seat, not tribe strength" is what plan v3 says the bar is for ("The scale is no longer flat"). It isn't a defect.

## 2. One strong seat barely moves the lobby median: **overreaches**
- **The numbers hold.**
  - Dropping the Quilboar seat moves the median by 0.009–0.045: B 0.027, C 0.033, uncut 0.026, frozen 0.009, pre-fix uncut 0.045.
  - Quilboar's R14 median runs 522 to 5,319.
  - Lobby mean growth runs 1.37–1.65.
  - The seats nearest the R14 median are Birds, Hard, Fairies and Hedgerow. In frozen, half of them are Hard.
- **New detail:** lobby mean growth without the Quilboar seat is 1.37 in every arm (1.366–1.379). The mean moves only because of Quilboar. (`ck1`)
- **The implication overreaches.** It says checkpoint 1 "needs" a per-line extreme-miss check, but plan v3 already has two:
  - "a tribe's best line outside an order of magnitude of the others";
  - "one line winning whatever the player chooses".

  The real refinement is finding 20: which round that check reads.

## 3. Per-line ×1.3: Quilboar and Birds pass in every arm: **corrected**
- **Every survivor-median growth figure reproduces**, and Quilboar and Birds are the only two that pass in all four arms.
- **Correction:** same-cohort per-seat medians agree within **0.05**, not 0.03:
  - uncut Quilboar 2.063 against 2.014;
  - C Bog 1.197 against 1.159.

  No line changes pass or fail. (`ck1`)

## 4. Survivor growth can't tell frozen Quilboar from Birds: **overreaches**
- **The numbers hold.**
  - Frozen Quilboar: 1.408 growth, mean place 5.10, 9% wins, 37 of 100 seats alive at R14.
  - Birds in the frozen arm: 1.397, mean place 2.10, 50% wins, 89 of 100 alive.
- **The remedy overreaches.** Same-cohort growth doesn't separate them either: 1.388 against 1.402.
- The survivors are also similar in size: 522 against 595 at R14. So it isn't true that "a line with heavy early deaths looks strong on its survivors". Its survivors look ordinary.
- Only the share alive, the all-seat median or the win rate tells the two apart. (`ck1`)

## 5. The ×1.3 result depends on the window: **corrected**
- **One round later, R9–R15, does not pass every arm:** B 1.288, C 1.313, uncut 1.318, frozen 1.248. Two rounds later, R10–R16, all four pass: 1.352, 1.380, 1.383, 1.308.
- **R12 to R15:** survivor medians grow 1.36–1.42 a round (frozen 1.29).
  - The same seats, as a ratio of their medians, grow **1.25–1.30**. The 1.21–1.22 figure is a median of per-seat rates, so it is a different statistic, and the comparison overstates the survivorship effect.
  - About 45% of seats are alive at R15, and the all-seat R15 median is 0. Both confirmed.
  - No game ends before R15, so counting the eliminated as 0 never zeroes a winner. (`ck1`)
- **The implication is partly done already.** DECISIONS 10 Nov (Ask A) fixed the window and formula in writing.
- The live risk is something that changes when seats die (the damage table chosen at step 5). That moves survivor medians without changing the content's growth. Window drift is already ruled out.

## 6. ×1.3 sits well below BG's lobby growth: **corrected**
- **Confirmed** from `reference-curves.md`: September 2025 mean ×1.56, November 2026 column C median ×1.94, top 0.4% ×2.07.
- **Correction 1:** ×1.94 is not "BG's November 2026 lobby".
  - Column C is the median of the opponents of perfect-game winners: 129 replays, survivors, 60 boards at turn 14.
  - The all-games November 2026 figure is the Firestone mean, ×1.76.
- **Correction 2:** the like-for-like comparison is mean against mean.
  - Our lobby mean growth without Quilboar is 1.37. Against BG's September 2025 mean of 1.56, that is still below.
  - With uncut Quilboar in the lobby, our mean reaches 1.65.
- **The conclusion stands:** ×1.3 is below BG's growth. Plan v3 already names the criterion "The scale is no longer flat".

## 7. Quilboar's growth is a step at R12–R13: **corrected**
- **Confirmed:**
  - B round ratios: ×1.10–1.22 over R9–R11, then ×2.38, ×3.13, ×1.65. Uncut: ×5.34 at R12, then ×3.34.
  - Each seat's biggest jump is most often at R12 (seats alive at R15).
  - Median jump size: ×3.35, ×3.57, ×6.37 and ×2.06.
  - Birds jump at R10 (×2.43–2.72), the four legacy lines at R8–R10 (×1.43–1.84), and Fairies at R15 (×1.80–1.94). (`ck2`)
- **Correction 1, "not a steady compound":** after the step, Quilboar still grows ×1.65–2.13 at R14 and ×1.54–1.74 at R15.
- **Correction 2:** counting every seat alive at R13, B's most common jump round is R13 (35 seats) against R12 (33).
- **Already planned:** port question 3 already lists "H1 largest one-round jump" as its measure. The owner's progression question is checkpoint 1's play criterion, which testers answer.

## 8. Most growth comes after R12, and an R12 read gets the order wrong: **overreaches**
- **Confirmed:**
  - Same cohort R15÷R12: Quilboar ×6.38, ×6.43, ×8.70 and ×3.12.
  - Quilboar against Birds in B: 0.84× at R12, 2.47× at R14, 3.17× at R15.
  - Late log share on survivor medians: Quilboar 50–62%, Fairies 53–60%. On the same cohort it is 45–57%, so in uncut it is under half.
- **Correction 1, the R12 order:** it is wrong only in B and frozen. In C and uncut, Quilboar already leads Birds at R12, by 1.57× and 2.38×.
- **Correction 2, paper:** paper did not predict that Birds would catch Quilboar. §3.4 says "Birds' ratio is flat (0.75 → 0.76), so there is no overtake in sight". The R15 catch-up was predicted for seven other lines.
- **The implication overreaches.** "Looks average at R12" is wrong: B Quilboar's 259 at R12 is 1.9–2.7× each of the other five native lines (`h1.md` medians). DECISIONS (10 Nov) already logged this lesson.

## 9. Bog, Hunters and Oozes flatten after R12; Birds and Fairies don't: **holds**
- **Every figure reproduces:** Bog 1.10–1.12, Hunters 1.09–1.13, Oozes 1.03–1.08, Hedgerow 1.18–1.22, Birds 1.30–1.40, Fairies 1.34–1.43.
- Same-cohort R15÷R12 points the same way: Bog, Hunters and Oozes at ×1.24–1.35 over three rounds.
- **The limit is stated correctly:** legacy profiles only, with the Busker-guard caveat. (`ck2`)

## 10. Survivor medians overstate a boom-or-bust line about 2.5-fold: **corrected**
- **B is confirmed:**
  - Quilboar's survivor median is 2,339 against an all-seat median of 773.5 (3.0×).
  - Birds': 737 against 604 (1.2×).
  - So Quilboar's lead over Birds is 3.17× on survivors but 1.28× on all seats.
- **"About 2.5-fold" is B only.** The overstatement relative to Birds:
  - B: 3.0 against 1.22, so about 2.5×;
  - C: 1.81 against 1.15, so 1.6×;
  - uncut: 1.60 against 1.23, so 1.3×.
- On all seats, Quilboar still ranks above Birds at R15 in B, C and uncut. Survivor medians get the order wrong only in frozen (803 against 708, with 31% of Quilboar seats alive). (`ck2`)

## 11. The preset dials cost about half of what paper said: **corrected**
- **The ratios reproduce:**
  - C÷uncut, both pre-fix: 0.51 [0.38, 0.64] at R12 and 0.44 [0.35, 0.54] at R15.
  - B÷uncut, both pre-fix: 0.33 and 0.25.
  - C÷B: 1.54 [1.17, 1.82] at R12 and 1.76 [1.45, 2.04] at R15. (`ck3`)
- **"About half" is wrong.** On a log scale, the realised cut is **58–60%** of paper's for C and **65–71%** for B.
- The B→C dial (gem-size steps) tracks paper closely: 81–94% of paper's step on a log scale.
- **What holds:** paper's gap comes mostly from the BG-text levers, which is the finding's own implication.

## 12. Preset C is overpowered only on paper: **overreaches**
- **The figures reproduce:**
  - Uncut at R12 is 0.98–1.09× BG's September 2025 mean, and at R14 2.7–3.0×.
  - C at R12 is 0.56× September 2025, 0.16× November 2026 column C, and 0.23× its 1,800 target.
  - C at R14 is 1.16× September 2025.
- **The mechanism is backwards.** Realised C-dialed Quilboar sits below BG's 2025 mean at R12 (0.56×) and above it by R14 (1.16×). That is the opposite of "looks generous at R12, isn't at R15".
  - Only paper C looks generous at R12: 1,942 is 2.6× September 2025.
- **Like-for-like (mean against mean):** BG text is 1.2–1.4× September 2025 at R12, not about 1.0×.
- **"A sixth of current BG"** uses column C. Against the all-games Firestone mean it is 0.12–0.14×, an eighth to a seventh.
- **"Preset C" here means only the port's own C dials.** Native lines ran at fixed rates. Generous first's C target is a realised median for our tribes (DECISIONS: "the realized median of a committed line"), and nothing here tests it.

## 13. The bot reaches T6 on schedule but finds Hogrider a round late: **overreaches**
- **Confirmed:**
  - T5 at a median R9. T6 at a median R11.
  - Tunneler at R7–R8, 85–89% by R11. Gem Rat at R7, 75–80% ever. Refiner at R10.
  - Hogrider at a median R12, IQR R11–R12: 17–25% by R11, 45–69% by R12, 55–79% ever.
- **Correction:** T6 is reached by **93–97%** of seats (frozen 93%), not 95–97%. (`ck4`)
- **The implication overreaches.** This is one card, one pool and one bot, and 21–45% of seats never find Hogrider at all. A paper model should carry the arrival distribution (B: 23% by R11, 61% by R12, 67% ever), not a one-round shift for every named T6 card.

## 14. On-time Hogrider seats still sit far below paper at R12: **corrected**
- **Confirmed:** B 418 at R12 (0.37× paper) and 3,015 at R15 (0.90×). Uncut 1,462 (0.24×) and 10,466.5 (0.44×).
- **The n values are survivors.** n = 27 and 23 are on-time seats alive at R12, out of 34 and 25 on-time seats in all. (`ck4`, `ck5`)
- **"About a round" understates the lag.** B's 418 sits below paper's R11 board (508, §10.2), so the lag is about 1.3 rounds at R12.
- **"Checking accounting only at R12" is a strawman.** The declared accounting already reads R9, R12 and R15, and B passes at R15 (0.70×, `h1.md`).

## 15. Hogrider matters less than paper said, and a late one is forgiven: **overreaches**
- **The split reproduces:** among seats alive at R12, with Hogrider by R12 against without:
  - B: mean place 2.55 against 4.11; R12 board 313 against 179 (1.75×).
  - C: 1.44× on the board. Uncut: 1.77×.
  - Late finders (R13 or later) won 81% in C (n = 21) and 90% in uncut (n = 10).
- **The flaw:** the "with" group pools seats whose Hogrider first appeared at R12, so they had one recruit phase with it (B: 57 such seats, R12 board 234).
- **Seats with Hogrider by R11 against seats without it by R12:**

  | Arm | R12 board ratio | Paper's staple share implies | Wins, on time / without |
  |---|---:|---:|---|
  | B | 2.34× | 2.2× | 37% / 23% |
  | C | 2.42× | 2.4× | 69% / 56% |
  | uncut | 3.0× | 4.5× | 96% / 67% (n = 23) |

  So Hogrider matters as much as paper said at B and C. (`ck5`)
- **"Mostly forgiven" can't be told from survivorship.** A seat has to be alive at R13 or later to be in the late bucket.

## 16. The bot is weak early because of its two-flex cap: **corrected**
- **Confirmed:**
  - Units at R4: 2.5 against Hard's 4.2–4.7. At R6: 4.0 against 6.4.
  - R9 board: 73.5–79.5 against Hard's 84.5–90 and Birds' 88.5–91.
  - 15–32% of Quilboar seats out before R12, against 1–4% for Birds and Hard.
  - In B: 32% wins, 45% bottom four. (`ck4`)
- **Correction:** the comparison leaves out the native engine lines, and they die early too:
  - out before R12: Fairies 13–16%, Bog 17–25%, Hedgerow 19–21%, Hunters 19–23%, Oozes 28–37%;
  - Fairies also hold only 2.8 units at R4.

  Quilboar's early deaths are typical of this field's engine lines. Birds and Hard are the exceptions. (`ck4`, `ck5`)
- **The cause is inferred, not measured.** The data are consistent with the two-flex cap, but they don't prove it.

## 17. Hedgerow depends on its keystone the way Quilboar does at B: **holds**
- **Confirmed** (B, survivors at R12):
  - Dozey on board: 35% of them (28% of all seats). Wins 36% with Dozey, 1% without.
  - Monarch: 61%. Wins 18% against 8%.
  - Stork: 44%. Mean place 1.78 against 2.52.
  - Bog, Hunters and Oozes: 0% wins either way. (`ck5`)
- **Caveat:** the split is an association, not a cause. Dozey seats were already ahead at R9 (85 against 71). Dozey usually lands by R8, so the two can't be separated.
- The finding's implication (re-check on wave 2 before reading it as a lesson) is suitably limited.

## 18. The line-gate proxy fails Quilboar at B and C: **overreaches**
- **Confirmed:** in-lobby place gain against the Hard seat:
  - Quilboar: B −0.08 [−0.62, +0.47], C +0.45 [−0.13, +1.02], uncut +1.08 [+0.38, +1.78], frozen −1.57.
  - Birds: +1.28 to +1.47. (`ck6`)
- **B Quilboar really is level with Hard, head to head.** It finishes above Hard in 52% of B lobbies, so mean place gives the right pairwise answer. A win rate and a mean place answer different questions.
- **The gate's purpose is different.** The step 5 gate tests whether a scripted line plays well enough to be read as evidence (HARNESS.md: "Script strength is not a checkpoint-1 gameplay criterion"). Plan v3 cut "line-against-Hard placements as tribe evidence".
- HARNESS.md already records this pattern: `line_fast` won 15 of 24 lobbies at a −0.02 mean gain.
- Reporting the win rate beside the gain is fine. Calling the gate's mean-place verdict a fault is not supported.

## 19. The depth bar is the only bar that flags BG-text Quilboar: **corrected**
- **The win shares reproduce:**
  - B: Quilboar 32% and Birds 36% above the band; 3 lines inside.
  - C: Quilboar 50% above; 4 inside.
  - uncut: Quilboar 64% above; 3 inside.
  - frozen: Birds 50% above; Quilboar inside at 9%; 4 inside.
  - Bog, Hunters and Oozes: 0–2%. (`ck6`)
- **"The only one" is wrong.** Three other reads single out uncut Quilboar:
  - the order-of-magnitude triage at R14–R15 (47.5× and 75.5×);
  - plan v3's "one line winning whatever the player chooses" (64%);
  - per-line growth (2.06).
- **The bar is also used outside its scope.** Done means is defined on "8 pinned strategy bots ... 2,000+ games". Here the roster is fixed, and Hard, which isn't a tribe strategy, counts toward the five lines inside the band.

## 20. The order-of-magnitude triage depends on the round: **corrected**
- **Best÷worst reproduces:**
  - R12: 3.2×, 4.3×, 7.7×.
  - R14: 12.5×, 17.5×, 47.5×.
  - R15: 22.1×, 27.7×, 75.5×.
- **Correction 1:** our lines alone at R15 are **5.9–7.0×**. The 4.5× figure is uncut at R14.
- **Correction 2: whether it fires at R14 also depends on how "of the others" is read.** Best ÷ median of the other lines gives B 8.4× at R14 (doesn't fire) and 12.2× at R15 (fires). C and uncut fire from R14 on either reading.
- **Correction 3:** at R14–R15 the worst line is Oozes with only 19–29% of seats alive, so its survivor median is a small, selected group. (`ck6`)
- **The implication should name three things:** the round, the ratio, and the population (survivors or all seats).

## 21. The snowball read takes a late dominant tribe for healthy comebacks: **holds**
- **Confirmed:**
  - R8 leader win rate: uncut 0.30 [0.21, 0.39], against B 0.41 [0.33, 0.49].
  - Quilboar leads at R8 in 18% of uncut lobbies, and when it wins its median R8 rank is 3.
  - Leaving out the lobbies Quilboar wins, the leader's win rate is 0.42–0.45 in every arm. (`summary.json.gz` `round8_leader_win_rate`, and `ck6`)
- **Caveats:**
  - The arms' intervals overlap.
  - Uncut's 0.44 without Quilboar's wins rests on 36 lobbies.

  The mechanism is clear even though the difference isn't statistically shown.
