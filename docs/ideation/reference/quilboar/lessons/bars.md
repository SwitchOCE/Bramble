# Our yardsticks tested against Quilboar (H1 archives)

**Question:** do our bars and reads tell a known strong tribe from a weak one?

**Short answer:** mostly they don't.
- The lobby-median growth bar fails in every arm, and one strong seat moves it by only 0.01–0.05.
- Survivor-median reads, the R12 anchor and the R8-leader snowball read each misjudge a tribe that is weak early and takes off at R12.
- Only the Done-means depth bar flags BG-text Quilboar as dominant, and it does so only relative to the other lines in the lobby.
- In our engine the preset C dials land at about half of BG's own text, and BG's own text lands near BG's September 2025 mean.

**Sources** (read-only):
- `Bramble-ideation-sol/tools/sim/evidence/quilboar-h1*/`: the compact `*.lobbies.json.gz` and `summary.json.gz`;
- `docs/ideation/reference/quilboar/h1.md` (working copy);
- `quilboar-port.md` (paper);
- `Bramble-ideation/docs/ideation/evidence/reference-curves.md` (BG).

**Scripts:** `qload.py`, `bars.py`, `extras.py`, `cohort.py` in this folder. Raw outputs are `bars-out.txt`, `extras-out.txt` and `bars-out.json`. The loader reproduces h1.md exactly: R12 medians 259 / 422 / 747 / 175.5, and lobby growth 1.244 / 1.257 / 1.255 / 1.236.

**Arms:**
- B and uncut are post-fix (canonical). C and uncut_frozen are pre-fix (retained).
- `B_pre` and `uncut_pre` are the superseded pre-fix runs. They are used only for like-for-like checks: the frozen-size ablation, and C against uncut.

**Caveats:**
- These are bot lobbies, not human frequencies.
- Bog, Hedgerow, Hunters and Oozes ran legacy (pre-wave-2a) profiles. No native line ran at a B or C preset.
- Shops are unpaired across arms.
- Intervals are 95% whole-lobby seed bootstraps, 1,000–2,000 replicates.
- **Kinds of finding:** M = measured (read from the archive), D = derived (computed by my scripts), I = inferred.

---

## 1. Growth from R8 to R14, against the ×1.3 bar

**Per line** (survivor-median growth per round, from `bars.py`, section 1):

| Line | B | C | uncut | frozen |
|---|---:|---:|---:|---:|
| Quilboar | **1.64** [1.60, 1.70] | **1.75** [1.72, 1.80] | **2.06** [1.94, 2.12] | **1.41** [1.37, 1.46] |
| Birds | **1.38** | **1.41** | **1.36** | **1.40** |
| Fairies | 1.27 | 1.23 | 1.23 | 1.25 |
| Hedgerow | 1.23 | 1.24 | 1.25 | 1.23 |
| Bog / Hunters / Oozes | 1.17–1.18 | 1.17–1.20 | 1.17–1.19 | 1.16–1.20 |
| Hard | 1.17 | 1.16 | 1.18 | 1.19 |
| Quilboar seats alive at R14 | 84/150 | 95/150 | 69/100 | 37/100 |

- **D. Exactly two of eight lines pass ×1.3 in every arm: Quilboar and Birds.** Same-cohort per-seat medians (seats alive at R14) agree within 0.03.
- **D. The bar can't tell frozen Quilboar from Birds.** Both grow ×1.40, but they are very different lines:
  - frozen Quilboar wins 9% of lobbies and 63% of its seats are out before R14;
  - Birds wins 50% and loses 11%.

  Survivor growth says how fast the survivors grow. It doesn't say whether the line is strong.

**The lobby median (checkpoint 1, criterion 2)** (`bars.py` 1b, `cohort.py`):

| Arm | All 8 seats | Without the Quilboar seat | Lobby **mean** growth | Quilboar's R14 median |
|---|---:|---:|---:|---:|
| B | 1.244 [1.23, 1.28] | 1.217 | 1.44 | 1,341 |
| C | 1.257 [1.24, 1.29] | 1.224 | 1.49 | 2,028 |
| uncut | 1.255 [1.23, 1.30] | 1.228 | 1.65 | 5,319 |
| frozen | 1.236 [1.22, 1.26] | 1.226 | 1.37 | 522 |
| uncut (pre-fix) | 1.279 [1.26, 1.30] | 1.234 | 1.64 | 4,681 |

- **M. It fails ×1.3 in every arm,** even beside a BG-text tribe at 5,319.
- **D. One strong seat moves it by 0.01–0.05.** Quilboar's own R14 board varies tenfold across arms (522 to 5,319); the lobby median moves 0.02. The mean does move (1.37 to 1.65). By construction the median reads the 4th–5th seat, and at R14 the seats round it are Birds, Hard, Fairies and Hedgerow.
- **D. It depends on the window and on who survives:**
  - The same lobbies pass when the window moves later: 1.29–1.32 for R9–R15, and 1.35–1.38 for R10–R16 (frozen 1.25 and 1.31).
  - Within-seat growth stays at 1.22–1.29 over those windows.
  - After R12 the survivor-median lobby grows 1.36–1.42 a round, but the same seats grow only 1.21–1.22 (frozen: 1.29 and 1.18): about half the seats die between R12 and R15, and the median rises because the weak ones leave.
  - From R15 the median over all seats, with the eliminated counted lowest, is 0, because more than half are out.
- **I. BG's own lobby grows faster than our bar asks.** Over R8–R14, the September 2025 mean grows ×1.56 and the November 2026 median ×1.94 (reference-curves). Uncut Quilboar's line (2.06) is close to BG's November lobby, and B Quilboar (1.64) to the September era. ×1.3 is a "no longer flat" bar, not a BG-shape bar.

## 2. The shape of growth

**Growth a round, from the survivor medians** (`bars.py` section 2):

| Arm | R9–R11 | R12 | R13 | R14 | R15 | R16 |
|---|---|---:|---:|---:|---:|---:|
| B | 1.10–1.22 | **2.38** | **3.13** | 1.65 | 1.74 | 1.41 |
| C | 1.11–1.35 | **3.32** | 2.33 | 2.06 | 1.67 | 1.53 |
| uncut | 1.15–1.44 | **5.34** | **3.34** | 2.13 | 1.58 | 1.50 |
| frozen | 1.10–1.20 | 1.69 | 1.69 | 1.76 | 1.54 | 1.22 |

- **D. Quilboar's growth is a step, not a steady compound.**
  - Each seat's biggest one-round jump: the most common round is R12 in every arm, and the median round is R12–R13.
  - Median jump size: ×3.35 (B), ×3.57 (C), ×6.37 (uncut), ×2.06 (frozen).
  - Our lines jump earlier and smaller:
    - Birds at R10 (×2.4–2.7);
    - Hedgerow, Bog, Hunters and Oozes at R8–R10 (×1.4–1.8);
    - Fairies late, at R13–R15 (×1.8–1.9).
- **D. R13–R15 against R12** (same cohort, seats alive at R15):

  | Line | R15 ÷ R12 |
  |---|---|
  | Quilboar | ×6.4 (B), ×6.4 (C), ×8.7 (uncut), ×3.1 (frozen) |
  | Birds | ×2.1–2.4 |
  | Fairies | ×1.9–2.2 |
  | Hedgerow | ×1.6–1.8 |
  | Hard | ×1.40–1.49 |
  | Bog, Hunters, Oozes | ×1.24–1.35 |

  Half or more of Quilboar's R8→R15 growth (on a log scale) comes after R12: 50–62%. Fairies is the native line with the same shape (53–60%), as paper's "Ring size is the closest analogue" predicted.
- **D. An R12-anchored read gets the order wrong:**
  - At R12, B Quilboar is 0.84× Birds (259 against 309), and frozen is 0.62×.
  - At R14 B is 2.47× Birds, and at R15 3.17×.
  - Paper predicted the reverse: a lead of 1.2–1.8× at R12, caught by R15.
- **D. R8–R14 growth does catch the takeoff, but hides its shape and cuts it off:**
  - B Quilboar is ×1.39 a round from R8 to R12, then ×2.08 from R12 to R15.
  - At R14 it is still growing ×1.5–1.7 a round.
  - A geometric mean averages the jump away, and the jump is the thing the owner's progression question is about.
- **D. Growth after R12 flattens for three native lines** (legacy profiles only), from R12 to R15:
  - Bog 1.10–1.12 a round, Hunters 1.09–1.13, Oozes 1.03–1.08;
  - Hedgerow 1.18–1.22;
  - Birds 1.30–1.40, Fairies 1.34–1.43.

  This answers the DECISIONS check ("whether our lines' growth flattens after R12") for the pre-wave-2a profiles only.
- **D. Survivor medians overstate a boom-or-bust line late.**
  - In B at R15, Quilboar's survivor median is 2,339. Counting eliminated seats lowest, its median is 774 (3.0× lower). Birds' is 737 against 604 (1.2× lower).
  - So Quilboar against Birds is 3.17× on survivors and 1.28× over all seats, and Birds wins more B lobbies (36% against 32%).
  - Frozen Quilboar's R15 survivor median (803) beats Birds' (708), with 31% of its seats alive and 9% wins.

## 3. How generous preset C is, against BG

**Quilboar's R12 and R15 medians** (`bars.py` section 3; paper from `quilboar-port.md` §6):

| Arm | R12 real | R15 real | R12 paper | R15 paper |
|---|---:|---:|---:|---:|
| B (post / pre-fix) | 259 / 274.5 | 2,339 / 1,927.5 | 1,144 | 3,363 |
| C (pre-fix) | 422 [344, 478] | 3,383 [3,014, 3,780] | 1,942 | 6,123 |
| uncut (post / pre-fix) | 747 / 825.5 | 8,381 / 7,718 | 6,195 | 23,945 |

- **D. The dial cuts cost about half of what paper said:**

  | Ratio | Real R12 | Real R15 | Paper R12 / R15 |
  |---|---|---|---|
  | C ÷ uncut, both pre-fix | 0.51 [0.39, 0.64] | 0.44 [0.35, 0.54] | 0.31 / 0.26 |
  | B ÷ uncut, both pre-fix | 0.33 | 0.25 | 0.18 / 0.14 |
  | C ÷ B (pre-fix B) | 1.54 [1.18, 1.81] | 1.76 [1.45, 2.03] | 1.70 / 1.82 |

  C sits about 1.5–1.8× above B, close to its "about twice B" design.
- **D. Against BG** (reference-curves; BG's table stops at R14):

  | | R12 | R14 |
  |---|---|---|
  | BG-text Quilboar in our engine | 747–825, which is 0.98–1.09× BG's September 2025 mean (759, the target era) and 0.29–0.32× its November 2026 median (2,598) | 4,681–5,319, which is 2.7–3.0× September 2025 and 0.59–0.67× the November median (7,980) |
  | C-dialed Quilboar | 422: 0.56× September 2025, 0.16× November 2026 | 2,028: 1.16× September 2025, 0.25× November 2026 |

- **D. Against our own targets** (B is 900 at R12, C 1,800):
  - C-dialed Quilboar reaches 0.23× C's target.
  - BG text reaches 0.42–0.46× of C's target and 0.83–0.92× of B's.
  - At R15, BG text realised (7,718–8,381) is above C's paper (6,123).
- **I. What this says about "generous first" (09h):** C is overpowered on paper only.
  - Realised, C dials put a BG tribe at about half its own text, and at a sixth of current BG at R12.
  - The R12 targets misplace generosity. In our engine BG's curve takes off at R12, a round or two later than paper puts it. So C looks generous at R12 and isn't at R15.
  - C is still below BG's scale, unless the yardstick is the September 2025 mean at R14 or later.

## 4. When the key cards arrive

**Quilboar seats** (`bars.py` section 4; "by R12" counts every seat, with survivors in brackets):

| Arm | T6 reached | Tunneler on board | Hogrider found | By R11 | By R12 | Ever |
|---|---|---|---|---:|---:|---:|
| B | R11 (96%) | R7 | R12 (IQR 11–12) | 23% | 61% (71%) | 67% |
| C | R11 | R8 | R12 | 22% | 55% (67%) | 69% |
| uncut | R11 | R7 | R12 | 25% | 69% (79%) | 79% |
| frozen | R11 | R8 | R12 | 17% | 45% (62%) | 55% |

- **M. The bot climbs on paper's schedule, but Hogrider comes a round after T6.**
  - On schedule: T5 at R9; Tunneler's median first round R7–R8 against paper's R7; 85–89% have Tunneler by R11.
  - A little late: Gem Rat at R7 against paper's R5, with 75–80% ever finding one; Refiner at R10 against R9.
  - Hogrider is late. Paper's "typical" line buys it at R11, the turn it reaches T6. The real median falls between paper's typical (R11) and its low roll (R13).
- **D. Arrival explains only part of the accounting gap.**
  - B seats that had Hogrider by R11 (n = 27) sit at 418 at R12, against paper's 1,144 (0.37×), and at 3,015 at R15 against 3,363 (0.90×).
  - Uncut on-time seats: 1,462 against 6,195 at R12 (0.24×), and 10,467 against 23,945 at R15 (0.44×).
  - So the realised curve lags paper by about a round at R12 and closes most of the gap by R15 at B.
- **D. Hogrider matters less than paper said, and a late one is forgiven at C and uncut.** Among seats alive at R12, with and without Hogrider by R12:

  | Arm | Mean place | Wins | R12 board |
  |---|---|---|---|
  | B | 2.55 / 4.11 | 48% / 23% | 313 / 179 (1.75×) |
  | C | 2.04 / 2.44 | 68% / 56% | 470 / 326 (1.44×) |
  | uncut | 2.03 / 2.28 | 78% / 67% | 861 / 488 (1.77×) |
  | frozen | 3.10 / 5.27 | 17% / 8% | |

  - Paper's staple table implies 2.2× (B), 2.4× (C) and 4.5× (uncut) at R12.
  - Seats that found Hogrider at R13 or later still won 81% (C, n = 21) and 90% (uncut, n = 10).
  - Survivorship flatters these late buckets.
- **M. Quilboar loses seats early.**
  - 15–32% of its seats are out before R12, against 1–4% for Birds and Hard.
  - It holds 2.5 units at R4 against Hard's 4.2–4.7, and 4.0 at R6 against 6.4. This is the bot's two-flex cap.
  - Its R9 board trails both Hard and Birds in every arm (73.5–79.5 against 84.5–90).
  - Its places split in two: in B, 32% wins and 45% in the bottom four.
- **D. Our lines' engine pieces** (on board by R12, survivors, B arm; uncut is similar):

  | Line | Piece | Share on board | Result with / without |
  |---|---|---|---|
  | Birds | Stork | 44% | place 1.78 / 2.52 |
  | Fairies | Monarch | 61% | wins 18% / 8% |
  | Hedgerow | Dozey | 35% | **wins 36% / 1%** |
  | Bog, Hunters, Oozes | their pieces | | 0% wins either way |

  - Hedgerow (legacy) is our most keystone-dependent line, as Quilboar is at B.
  - Our pieces first land at median R5–R10, earlier than Hogrider's R12.

## 5. Our deciding criteria on this data

| Criterion | B | C | uncut | frozen | Tells strong from weak? |
|---|---|---|---|---|---|
| Checkpoint 1, criterion 2: lobby median ×1.3, R8–R14 | fail 1.244 | fail 1.257 | fail 1.255 | fail 1.236 | **No.** A 9%-win Quilboar and a 64%-win Quilboar differ by 0.02 |
| Checkpoint 1, criterion 1: testers feel progress | no data | | | | |
| Per-line ×1.3 (as wave reviews use it) | Quilboar 1.64 pass | 1.75 pass | 2.06 pass | 1.41 pass | **Partly.** By size only. Frozen passes at mean place 5.1 |
| Step 5 line gate (proxy: in-lobby paired place gain against the Hard seat) | −0.08 [−0.67, 0.48] fail | +0.45 [−0.13, 1.03] fail | +1.08 [0.36, 1.77] pass | −1.57 fail | **Partly.** It separates uncut from frozen, but fails a line that wins 32–50% of lobbies. Birds passes in every arm (+1.28 to +1.47) |
| Done means depth (≥5 lines at 6–25% wins, none above 25%) | fail: Quilboar 32% and Birds 36% above, 3 inside | fail: Quilboar 50%, 4 inside | fail: Quilboar 64%, 3 inside | fail: Birds 50%, 4 inside | **Relatively.** The only bar that flags uncut Quilboar. It flags whichever line leads this field, whatever the scale |

- **D. The line gate punishes boom-or-bust.** Mean place counts a 1st and a 7th as an average 4th. Quilboar at B wins as often as Birds (32% against 36%) but averages 3.9 against 2.4, so the gate ranks it level with Hard. The proxy isn't the real protocol: the real one is head-to-head against `hard_field` with swapped legs, on predeclared seeds.
- **D. The extreme miss "best line outside an order of magnitude" depends on the round it's read at.**
  - At R12 it doesn't fire even for uncut (7.7× Oozes).
  - From R14 it fires everywhere Quilboar has gems that grow: B 12.5×, C 17.5×, uncut 47.5×. By R15: 22×, 28× and 76×.
  - Our lines alone spread 2.7–3.2× at R12 and 4.5–7.0× at R15.
- **D. The snowball read (the R8 leader's win rate) takes a late dominant tribe for healthy comebacks.**
  - Uncut has the lowest R8-leader win rate (0.30) while Quilboar wins 64%.
  - Quilboar leads at R8 in only 18% of uncut lobbies, and wins from a median R8 rank of 3.
  - Leaving out the lobbies Quilboar wins, the leader's win rate is 0.42–0.45 in every arm.

## What this changes in our process (inferred)

1. **Report growth with who's alive.** Put every survivor median beside its share of seats alive, plus same-cohort growth or the median counting eliminated seats lowest. A line with heavy early deaths looks strong on survivors.
2. **Fix the window and say it's fixed.** On survivor medians, ×1.3 passes or fails by moving the window one or two rounds (R10–R16 passes on these same lobbies). Same-cohort growth is the honest read of compounding.
3. **Add one per-line read to checkpoint 1, or to its extreme-miss triage.** The lobby median can't see one dominant tribe.
4. **Read R12 and R15 both,** for the R12 targets and for the order-of-magnitude triage. A takeoff at R12 is invisible at R12.
5. **Pair the line gate with the win rate.** Mean place alone undervalues a line that wins big or busts.
6. **Paper arrivals:** assume a named T6 card lands about a round after T6 (17–25% by R11), not on the T6 turn.
