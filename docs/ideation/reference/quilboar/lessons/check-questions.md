# Skeptic check of the "questions" lens (questions.md)

I recomputed each finding with my own scripts. I didn't reuse the analyst's loader or `fights.pkl`. Nothing in any worktree was changed, and no Godot was run.

- **Compact data.** The committed `tools/sim/evidence/quilboar-h1{,-cycle-fix}/<arm>/*.lobbies.json.gz` in `Bramble-ideation-sol`. Scripts: `check/ck_compact.py`, `check/ck_compact2.py`, `check/ck_flex.py`, `check/ck_pieces.py` and `check/ck_nativegems.py`, with outputs in `check/ck_*.txt`.
- **Captures.** `build/quilboar-h1-captures/**`. All 150 chunk hashes match `receipt.json` `capture_gzip_sha256`. Ghost fights are dropped. Script: `check/ck_captures.py`.
- **Content.** Unit tribes, tiers and line profiles come from `git archive bb8bb5f2`, unpacked into `check/content-bb8bb5f2/`.
- **Paper.** `quilboar-port.md` §3, §6, §10 and §11. Q7: I diffed `model-copy/qm3.py` against the committed model and found only the two-line `gemday_no_hog` patch. Re-running `q7_paper.py` gives byte-identical output.
- **Bot data.** Every rate below comes from bots, not people. That matters most for F3, F7, F9, F12, F13 and F14.

Verdicts: **3 hold, 4 need corrections, 10 overreach.** Most overreaches have correct numbers and an implication that goes past them.

| # | Finding (short) | Verdict | The point |
|---|---|---|---|
| F1 | Frozen size: R12 ÷4.70, R15 ÷9.61 | overreaches (minor) | Every number reproduces. Only "any additive tribe" generalises from one tribe |
| F2 | Size closes 72–89% of the gap; "contradicts paper's 65%" | overreaches | Paper's own size-off ablation predicted about 97% of the gap. Real is less than paper, not a contradiction |
| F3 | Frozen is weak: place 5.10, first 0.09 | holds | |
| F4 | Size-step dial transfers; "paper ranks elasticities well" | overreaches | Paper's 1.70 sits outside the real R12 interval. The frozen dial missed by 1.6× on a log scale |
| F5 | Paper spread transfers almost exactly | overreaches | It matches only on the post-fix arms (pre-fix uncut is 13.9 against 22), for one tribe, and on scripted scenarios |
| F6 | Equal totals: Quilboar wins 18–25% | corrected (minor) | Post-start baseline is 0.45–0.50, not 0.48–0.50. The implication holds and is stronger |
| F7 | Our answers don't lose value | overreaches | Every line gains 0.05–0.54. Answer lines sit mid-pack. Cells are 8–43 fights |
| F8 | Our tribes flatten after R12 | overreaches | Fairies speed up after R12 (1.27→1.29). Four lines are legacy |
| F9 | Games long enough; R9–R11 trough | overreaches | BG-text Quilboar has no trough (0.50→0.48) |
| F10 | ×2 rounds and their win rate | holds | The win is near-mechanical: the jumping board is 2.5–3.3× its opponent |
| F11 | 61–63% of native fights lopsided | overreaches | That trigger was replaced on 9 Nov. The plan v3 band lists it as reported, not as a cut trigger |
| F12 | The harness has no pivoting bot | corrected | The engine has an unpinned Hard that re-picks its build until R9. H1 pinned it |
| F13 | Hogrider is worth 0.3–0.6 places once there | overreaches | The range is 0.09–1.89, and the native comparison isn't like-for-like |
| F14 | Q1 flex numbers | corrected | Hard and Quilboar make 38–45% of off-tribe holdings, not "most" |
| F15 | Ring and gem size curves | holds | |
| F16 | Q7 on paper: coupling cuts from the top | overreaches | True at R12 only. At R15 the coupling cut hits the low roll hardest |
| F17 | Q10 not exercised; natives never receive gems | corrected | Native seats held Quilboar units in 249 of 3,000 seat-games |

---

## F1. Freezing gem size (Q8)
**Recomputed** (measured, `ck_compact.txt` F1):
- uncut_pre against frozen_pre at R9/R10/R11: 1.13/1.10/1.32.
- R12: 825.5 (n=80) against 175.5 (n=68), ×4.70. My bootstrap gives [3.99, 5.36].
- R15: 7,718 (n=71) against 803 (n=31), ×9.61 [8.14, 12.42].
- Per seed: uncut is bigger in 0.92 of seeds at R12 (n=66) and 1.00 at R15 (n=31).

The configs differ only in `reference_quilboar_freeze_size`. The bot switches to gem modes when frozen (`bot_quilboar.gd:458`), so the frozen arm isn't handicapped by dead size picks.

**Verdict.** Overreaches, but only slightly. The numbers and "most of 'obliterate' is gem size that grows" hold. "Any additive tribe" is a generalisation from one tribe; paper says none of our tribes is additive-trivariate. Say "on Quilboar".

## F2. Share of the gap
**Recomputed** (derived): ln(uncut/frozen) ÷ ln(uncut/native) at R12, with natives from the same uncut_pre lobbies:
- Oozes 0.72, Hunters 0.76, Bog 0.81, Hedgerow 0.81, Fairies 0.84, Hard 0.89, Birds 1.39.
- The claim states Birds as 283, which is the frozen-lobby median. The share uses 271 (uncut_pre). Either way frozen is below Birds.

**The misreading.** Port §3.3 says 65% of the gap is "Battlegrounds' general scale". It then says "The size axis puts Quilboar on BG's scale". Its own ablation (§3.2) predicts size-off at 532 against preset A's 500, so freezing size closes ln(6195/532)/ln(6195/500) = 0.97 of the gap on paper. The real 72–89% is *less* than paper predicted. It is not a contradiction of the 65% sentence, which isn't an ablation claim.

"BG's count and application numbers alone don't reach BG scale" is also what paper predicted (size-off ≈ 0.2× BG's median of 2,598). Even full uncut doesn't reach BG's median in our engine (747–825.5).

**Verdict.** Overreaches. The Undead control is still the only test of "general scale".

## F3. Frozen outcomes
**Recomputed** (measured, `ck_compact.txt` F3; `ck_captures.txt` F3):

| | uncut_pre | frozen |
|---|---|---|
| Mean place | 2.87 | 5.10 |
| First place | 0.60 | 0.09 |
| Top 4 | 0.72 | 0.35 |
| Alive at R15 | 0.71 | 0.31 |

- Hard's mean place in the frozen lobbies is 3.53.
- Birds' first-place rate goes from 0.18 to 0.50.
- Frozen against Birds, head to head: 0.04 at R9–11 (n=51) and 0.18 at R12–14 (n=33).
- Frozen places behind Fairies (4.17) and Hedgerow (4.53), although its R12 board is bigger than theirs (175.5 against 133 and 125.5). That fits F6.

**Verdict.** Holds. Placement is bot data.

## F4. The size-step dial, B against C
**Recomputed** (derived): rates.json at bb8bb5f2 shows B and C differ only in `gem_size_step` (0.5 against 1.0) and `gem_round`. The lobby configs differ only in the preset label.

| | Real | Paper |
|---|---|---|
| C ÷ B at R9 | ×1.01 | ×1.22 |
| C ÷ B at R12 | ×1.537 [1.33, 1.66] | ×1.70 |
| C ÷ B at R15 | ×1.755 [1.51, 1.94] | ×1.82 |
| First place, B_pre → C | 0.34 → 0.50 | |

**The problems:**
- Paper's 1.70 lies outside the real R12 interval.
- The other controlled dial, size frozen, was predicted at ÷11.6 / ÷20.1 against a real ÷4.7 / ÷9.6. Paper overstated it 1.58× on a log scale at R12, and 1.33× at R15.
- With two dials, "ranks dials" is trivially true. "Elasticities well" is contradicted by the frozen dial.
- "Levels miss 4–8×" is true only at R12 (real/paper 0.12–0.23). At R9 and R15 the miss is 1.4–2.9× (h1.md, 0.36–0.60 and 0.35–0.70).

**Verdict.** Overreaches. Say "paper got the sign and order of two dials right, and the size-step size roughly right at R15".

## F5. Paper spread
**Recomputed** (`ck_compact2.txt` F5). Real p90/p10 at R12 against paper strong/low: B_post 5.4 against 5.5, C_pre 7.4 against 7.1, uncut_post 20.6 against 22.

Natives:

| Line | p90/p10 |
|---|---|
| Birds | 4.3–5.3 |
| Hedgerow | 2.3–3.0 (3.3 uncut) |
| Fairies | 2.4–2.8 |
| Bog, Hunters, Oozes | 1.7–2.1 |

**But:**
- Under the pre-fix cycling policy the same tribe gives B 4.8 and uncut **13.9** against paper's 22. The cycle-cap fix alone moved uncut's spread ×1.5.
- Real p10 and p90 each miss paper's low and strong by about the same factor: 0.30–0.39× at B and C, about 0.2× uncut. The ratio matches because the miss is uniform, not because the scenarios are percentiles. Strong and low are scripted lines (§10.1).
- Frozen has no paper strong/low to compare with.
- Paper gives no spread for any native line.

**Verdict.** Overreaches. One tribe, two like-for-like points, and a bot policy that moves the result ×1.5 can't make "paper predicts swinginess" a process input.

## F6. Equal totals (Q4)
**Recomputed** (measured, `ck_captures.txt` F6). Quilboar's win rate at 0.8–1.25× pre-start totals, R9+:

| Arm | Win rate | n |
|---|---|---|
| B | 0.22 | 224 |
| C | 0.18 | 180 |
| uncut | 0.25 | 114 |
| frozen | 0.19 | 157 |

- Natives' wider side wins 0.42–0.46.
- By band at B: R6–8 0.46, R9–11 0.22, R12–14 0.25 (n=28), R15+ 0.24 (n=21).
- Post-start, Quilboar wins 0.28–0.36. The native post-start baseline is **0.45–0.50** (uncut 0.45), not 0.48–0.50.
- Break-even: B wins 0.32 at 1.0–1.25× and 0.62 at 1.25–1.5×, so break-even sits at about 1.25–1.45×.

**Extra point.** Totals aren't neutral among natives either. At equal totals against other natives:

| Line | Win rate |
|---|---|
| Hedgerow | 0.54–0.62 |
| Oozes | 0.53–0.55 |
| Hunters | 0.43–0.46 |
| Fairies | 0.43–0.53 |

**Verdict.** Corrected, minor. The implication holds, and the native spread makes it stronger.

## F7. Answers against the wide board
**Recomputed** (measured). At equal totals, R9+, win rate against Quilboar and against other natives:

| Line | Against Quilboar | Against other natives |
|---|---|---|
| Bog | 0.73–0.91 | 0.45–0.52 |
| Hunters | 0.71–0.83 | 0.43–0.46 |
| Birds | 0.55–1.00 (n=11–34) | 0.46–0.50 |
| Fairies | 0.64–0.84 | 0.43–0.53 |

Quilboar against tall opponents (biggest-unit share 0.4 or more): 0.08–0.25 (n=12–35).

**But every line gains,** answer lines or not:

| Line | Gain against Quilboar |
|---|---|
| Hedgerow | +0.14 to +0.36 |
| Oozes | +0.31 to +0.47 |
| Hard | +0.18 to +0.28 |
| Birds | +0.05 to +0.54 |
| Bog | +0.21 to +0.46 |
| Hunters | +0.25 to +0.40 |

- Bog's and Hunters' gains sit in the middle of the pack.
- The cells are 8–43 fights, so a 0.1–0.2 loss of answer value can't be detected.
- Bog and Hunters ran legacy profiles. No answer card was identified on board.

**Verdict.** Overreaches. The data show Quilboar's per-stat weakness, and nothing either way about answers. "No sign either way" is the honest reading.

## F8. Late growth (Q5)
**Recomputed** (measured, `ck_compact.txt` F8 and `ck_compact2.txt` F8). Same-cohort growth R12→R15 per round, B:

| Line | Growth |
|---|---|
| Quilboar | 1.86 (C 1.86, uncut 2.06, frozen 1.46) |
| Birds | 1.28 |
| Fairies | 1.29 |
| Hedgerow | 1.17 |
| Hard | 1.14 |
| Bog, Hunters, Oozes | 1.07–1.08 |

Quilboar at 259 against Birds' 309 at R12, and 2,339 against 737 at R15 (3.17×), as h1.md says.

**But.** For the same cohort (alive at R15), R8→R12 growth against R12→R15 growth:
- **Fairies speed up:** 1.27→1.29 (B), 1.25→1.30 (frozen).
- Birds slow: 1.40→1.28.
- The legacy four drop: 1.19–1.25 → 1.07–1.17.

So "our tribes flatten after R12" holds for Birds and the legacy lines, not for Fairies. "Don't realize their proportional terms" isn't measured anywhere.

The ×1.3 criterion is defined on the lobby median, (median R14 / median R8)^(1/6) (DECISIONS, Harness follow-up 3, Ask A). The H1 figure of 1.24–1.26 pools all seats, Quilboar included (`quilboar_h1_report.py:269`). 09i caps deciding criteria at two, so a same-cohort reading can only be reported beside it. Four of the six lines are pre-wave-2a, so this says little about checkpoint 1's pool.

**Verdict.** Overreaches.

## F9. Game length and the trough
**Recomputed** (measured):
- No lobby ended by R14 (the minimum end round is 15–16). The median end is R18–19, p10 R17. The first round with four or fewer alive is median R14.
- Quilboar's R9–11 win rate: 0.34 (B), 0.38 (C), 0.27 (frozen).
- Non-winning Quilboar seats are last seen at median R12. Hero HP at R12: 10 for non-winners against 18 for winners (B).

**But.** The BG-text arm has no trough: uncut_post 0.50 → 0.48, uncut_pre 0.46 → 0.45 (R6–8 → R9–11). The trough appears only in our budgeted arms (B and C) and in frozen. So "Quilboar's real shape is a trough … like BG's Choose One" reverses what the data say. *Inferred:* the trough is what our cuts do (Hogrider on other Quilboar only, Tunneler once a fight, half size steps). That may be a lesson in itself. The bot's thin early board (2-flex cap) is a second candidate. The spec's trigger reading is correct: it doesn't fire.

**Verdict.** Overreaches.

## F10. ×2 rounds (Q3)
**Recomputed** (measured). Share of seats with a ×2 round:

| Line | B | C | uncut | frozen |
|---|---|---|---|---|
| Quilboar | 0.62 | 0.73 | 0.73 | 0.28 |
| Birds | 0.69 | 0.68 | 0.71 | 0.74 |

Fairies 0.24–0.30, Hedgerow 0.15–0.20, Bog, Hunters and Oozes 0.00–0.04.

Win rate in the jump round's fight:
- Quilboar 0.84, 0.88 and 0.97 (frozen 0.75).
- Birds 0.84–0.94.
- Other fights: Quilboar 0.51–0.63 (frozen 0.40), Birds 0.63–0.71.

In the jump fight the jumping board is a median 2.5–3.3× its opponent (Quilboar B 3.34, uncut 9.66). Given F11 (94–97% at 1.5× or more), the high win rate is close to mechanical.

**Verdict.** Holds. The implication is suitably hedged.

## F11. Lopsided fights
**Recomputed** (measured). R12–R15 fights where one board is at least 1.5× the other:

| Fights | Share lopsided | Bigger side wins |
|---|---|---|
| Native-only | 0.61–0.63 | 0.94–0.96 |
| Quilboar's (canonical arms) | 0.83–0.92 (uncut_pre 0.94) | |
| Quilboar's (frozen) | 0.68 | |

- The pooled figure hides a round trend: native-only fights are 0.48–0.50 lopsided at R12 and 0.77–0.80 at R15.
- The bigger side wins 0.59–0.61 even below 1.5×.

**But.** The Generous first entry (9 Nov) says the agency bar "replaces 'fights decided before they start' as a cut trigger". The agency bar was then withdrawn under 09i. The current plan (`plan-scale-rework.md` lines 74–84) lists "the uncertain-fight share" as reported, not deciding. Its triage list names only three extreme misses: a tribe outside an order of magnitude, one line winning whatever the player chooses, and runaway snowballs in most lobbies. So the trigger the implication challenges isn't live. It survives as a reported metric and as D3's reading.

**Verdict.** Overreaches. Say "as a reported metric or D3 reading, it needs a native baseline and a per-round split".

## F12. Pivots (Q2)
**Recomputed** (measured):
- Hard: 500 seats, 0 line changes, 21 distinct lines.
- Native `final_line` equals `line` in 3,000 of 3,000 seats.
- Quilboar commits at R6 in 125 of 150 (B).
- Mean place by engine start round:

| Arm | Start by R6 | Start R9 or later |
|---|---|---|
| B | 3.37 (n=52) | 4.57 (n=14) |
| C | 2.19 (n=54) | 5.69 (n=13) |

**Correction.** H1's Hard seats are `hard:varied`. `BotLobby.resolve` pins a build at seating, so `_choose_build` returns early. The engine does have an unpinned Hard: `bot_brain.gd` `_choose_build` re-picks the best-fitting build each round with ×1.3 hysteresis until `LOCK_BUILD_ROUND = 9`.

So it isn't true that "the harness has no pivoting bot". H1 seated none. Seating unpinned Hard is a cheaper first look at pivots up to R8, with no new bot code. It can't cover R10 pivots.

"Worth 1.2 / 3.5 places" is observational, with only 13–14 seats in the late bin.

**Verdict.** Corrected.

## F13. Keystone (Q9)
**Recomputed** (derived). Mean place by Hogrider by R12, with and without, in B: 2.92 against 5.46.

Among seats alive at R13:

| Arm | With | Without | Gap |
|---|---|---|---|
| B | 1.62 | 2.25 | 0.63 |
| C | 1.48 | 1.76 | 0.28 |
| uncut | 1.05 | 1.14 | 0.09 |
| frozen | 2.51 | 4.40 | 1.89 |

- "0.3–0.6 places" quotes B and C only. Uncut sits at a ceiling: 64 of its 69 R13 survivors win.
- Legacy native engine pieces give 0.36–1.39 (`ck_pieces.py`, matching "0.4–1.4"). That is the *unconditional* gap. Like-for-like (alive at R13) it is −0.65 to +1.26, with only 5–17 seats lacking the piece.
- So the juxtaposition compares a conditioned Quilboar number with an unconditioned native one.
- Conditioning on R13 survival also removes any part of Hogrider's effect that works through surviving R12.

**Verdict.** Overreaches. Say "the R13-survivor gap is 0.1–1.9 places, and not comparable to the native figure as written".

## F14. Flex (Q1)
**Recomputed** (measured, `ck_flex.txt`). Off-tribe uptake by R8, with denominators of 3,405–3,557 seat-games:

| Card | Uptake |
|---|---|
| Hedge Witch | 0.300 |
| Wee Wobbly | 0.170 |
| Mrs Dunnock | 0.156 |
| Bridge Toad | 0.150 |
| Little Nip | 0.121 |
| Mr Crumb | 0.101 |

- Own-tribe share at R2–R5: 0.31–0.64 (the claim says 0.29–0.64).
- By R10: 0.73–0.87, and Oozes 0.58–0.60.
- Quilboar at R6/R7/R8 (B): 0.51/0.68/0.86, against the claim's 0.53/0.69/0.87.

**Correction.** "Hard and the Quilboar seat make most of them" is wrong:
- By the analyst's own T1–T3 count they make 4,105 of 9,151 holdings (45%). By my T1–T2 count it is 3,028 of 7,900 (38%).
- They hold the most per seat, but the six native lines make the majority.
- Hedge Witch's off-tribe holders are spread evenly: Oozes 177, Birds 176, Hard 172, Hunters 168.

"Don't add flex cards on this proxy" still stands, for the other reasons given (holding is not buying; four tribes are legacy).

**Verdict.** Corrected.

## F15. Ring and gem size (Q6)
**Recomputed** (measured):
- Fairies' Ring size at R9/R12/R15: 1/2/6 (B) and 1/2/4 (C, uncut, frozen).
- Ring counts: 5–6, 15–16 and 32–44.
- Gem size at B (attack/health): R9 2/2, R12 6/5.5, R15 9.5/9.
- Paper (§3.4): gems 3/8/15 against Rings 2/6/13.

**Verdict.** Holds.

## F16. Q7 on paper
**Recomputed** (derived). `q7_paper.py` re-run gives byte-identical output, and the as-built rows reproduce port §10.1. At R12, all as claimed:
- Coupling cut: strong −31%, typical −11%, strong/low 5.5→3.8.
- Axis cut: strong −10%, typical −16%.

**But at R15 the reading reverses** in all three presets. At B:

| R15 | Strong | Typical | Low roll | Strong/low |
|---|---|---|---|---|
| Coupling cut | −11% | −12.5% | **−16%** | rises 4.0→4.2 |
| Axis cut | −18% | −18.5% | 0% | falls 4.0→3.3 |

The R12 result happens because the scripted low roll gets Hogrider only at R13.

The patch is also narrower than §11.5's "Gem Day not counting as Choose One": Trailblazer still doubles Gem Day (`qm3.py:206-209`).

**Verdict.** Overreaches. "Cuts from the top" holds at R12 only.

## F17. Splash hazards (Q10)
**Recomputed** (measured):
- Quilboar seat-games holding each card: Busker 18 of 500, Silky 59, Sexton Beetle 5, Whirligig 10, Pipistrelle Echo 0, Stone Soup 0.
- The Phase 1 README defers Felboar, Roadboar and Bonker, and Barrage is "unavailable".
- The Busker guard hazard came from review (DECISIONS, 10 Nov H1 review, simplify 1).

**Correction.** "Natives never receive gems" is wrong (`ck_nativegems.py`):
- Native seats held a Quilboar unit in 249 of 3,000 native seat-games: Veteran Brigand in 344 seat-rounds, Hogrider 97, Champion 73, Gem Rat 40. Hard held one in 151 of 500.
- Gem size left its 2/2 start in 69 native and 42 Hard seat-games.

It's rare, not never. H4 can use these seats.

**Verdict.** Corrected.

## Assumptions list in questions.md
- Point 1 holds (F6).
- Point 2 is partial (F8: Fairies don't flatten).
- Point 3 overreaches (F4, F5).
- Point 4 needs F12's correction.
- Point 5 targets a retired trigger (F11).
- Point 6 holds (F15).
