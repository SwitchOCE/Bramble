# Pass 2 Bog fix: costing and triage review

9 Nov 2026, a fresh cloud reviewer, on `ideation/c-pass2-bog-review` from `ideation/c-pass2-bog`. Target: `content/pass2-bog.md`. Method: buy-moment costing as `birds-pass1-costing.md` (V(t) 5/7/8/10/12/14, A(t) 2.0–6.1, growth caps from `power-budget.md` B4), then triage against the owner's test: "If it's not fulfilling its primary purpose, then it's always useless and it becomes a trap."

**Counts: 3 cut, 4 ask, the rest fine.** The fix moves the original problem: Bog is no longer 0% on fair R9 fixtures. But the fixed-board story and the lobby story disagree (§1), and the Toad as written is what carries the low roll, over the T1 cap.

**Cut**
1. **Bridge Toad's growth is uncapped**: 1.7 SP a fight against a T1 combat cap of 1.0. Add "up to +3/+3".
2. **The Committee's flat +2 numbers don't reproduce**: on the corrected fixtures a flat +2 leaves Hedgerow high at 6.0%, not 22.2%. Replace §3's proposal with the one below.
3. **`corrected-boards.json` still carries the old `assumptions` text** for both Bog boards ("One Supper", Scarecrow, Wobbly). Rewrite it to match the slots.

**Ask**
1. **Ship Bitter-first behind a lobby check**: Bog already placed first 17% of the time in free choice before pass 2, so the R9 fixtures understate Bog (§1).
2. **The Prima Donna to Bitter 2**: she gains the most from the new timing, about +7 SP a fight.
3. **Tiddy Mun: keep the old text** (+1/+1 after, twice a fight). With Bitter-first, the old Tiddy does better on the bench (51.0%) than the redesign (43.3%), and the redesign costs more by hand.
4. **Warty Nan**: about +50% at T1 under the new timing, level with Little Nip. Watch Bog's R1–R4 results.

## What I ran

I applied `evidence/pass2-bog/prototype.patch` in a scratch worktree, set Bridge Toad to Mire-only as the doc says, and reproduced §6 exactly: Bog high 43.3, Bog low 34.2, Hedgerow high 35.0 (100 seeds × swapped sides, seed 92100). Then I varied one thing at a time on `corrected-boards.json`. I also merged `ideation/main`'s measurement tools into a second scratch tree and ran the `free_choice_plain` arm on the pass 2 cards, at 400 lobbies with Bitter-first off and on (§1). No repo code or content changed.

| R9 probe (same roll) | Bog high | Bog low | Hedgerow high |
|---|---:|---:|---:|
| Full fix, as published | 43.3 | 34.2 | 35.0 |
| Bitter-first only (old Tiddy), Toad 3/5 | **51.0** | 34.2 | 33.3 |
| Bitter-first only, Toad 1/3 (no growth) | 51.0 | **7.6** | 33.3 |
| Full fix, Toad 1/3 / 1/5 / 5/7 / 7/9 | 43.3 | 7.6 / 10.1 / 50.4 / 59.6 | 35.0 |
| Committee flat +2 | 54.2 | 34.2 | **6.0** |
| Committee +1/+1, or +2/+1 if all 7 | 46.5 | 34.2 | 25.1 |
| Same text + Committee body 5/7 | 42.3 | 34.2 | **35.3** |
| Same text + Mallow 4/6 instead | 41.1 | 34.2 | 35.4 |
| Committee +2 Attack, or +2/+2 if all 7 | 38.3 | 34.2 | 62.9 |

Two readings. **The low roll's 34% is the Toad's banked size, not Bitter**: Bitter-first moves Bog low only from 3.8 to 7.6. The Toad's size then sets the rate almost linearly. **Bog high's gain is Bitter**: 12.1 to 51.0. The new Tiddy then takes 8 points off.

## 1. Bitter hits first

**Every Bitter unit, at buy time.** The new timing adds the first hit's reduction, min(N, A−1), once for each enemy that attacks the unit. Bitter already shrank later hits.

| Unit | Bought | Added by the rule | Verdict |
|---|---|---|---|
| Warty Nan 1/3, Bitter 1, lends 1 | R1, empty board | ~1.2 hits on her and ~1.2 on neighbours, at 1 each: **+2.4 SP**, about 8 vs 5 (+55%). At A = 2, Bitter 1 halves a T1 hit. Two Nans side by side floor every T1 attacker at 1 | **Ask 4**. Level with Little Nip (8.5), so not a rise against the pool |
| Madame Bufo 1/4, Bitter 2 | R3 | Mire guarantees ~0.9 locked hits, at A = 2.5, so ~1.5 each: **+2 SP** (about +30%) | Fine, at the band's edge |
| Natterjack Chorus, lends 1 to two neighbours | R5 | **+2 SP**, +25% | Fine |
| The Prima Donna 2/8, Bitter 3 once per enemy | R8 | Her three Mired enemies must hit her: 3 × 3 × 0.8 ≈ **+7 SP** on V = 12. With Nan and the Chorus beside her it's Bitter 5, which floors any enemy up to 6 Attack at 1 | **Ask 2: Bitter 2** (the designer's own fallback) |
| Peatlings 4/4, Bitter 2 | R10+, via the Peat King | ~+1.5 each, twice: +3 on ~28 | Fine |
| Non-Bog Bitter | — | None in the slice pool, heroes or spells (`bitter_toad` is old-library Nightshade) | Nothing to check |

**Lobbies.** Before pass 2, in the plain free-choice arm, Bog folk took first **17.2%** of the time (mean place 4.21), the second-best rate after Hedgerow's 20.4%, while scoring 0% on the R9 fixtures. The fixtures are threshold tests (H9), and they put Bog just under a cliff that real lobbies don't: there, Bog walls grow, and Bog players skip the stingy compositions. A lever worth +39 points on a fixture can't be judged there alone. My run on the pass 2 cards:

LOBBY_TABLE

**Edge cases, checked in the engine source:**
- **Counters and pounces:** `drain()` applies a counter's `attack_bonus` before `attack()`, so Bitter subtracts after the bonus. The doc should say so. It decides the 1-Attack floor in a Bog mirror: Gideon's 2-Attack counter into Bitter 3 deals 1, not 3.
- **Pack joiners:** "only the leading attacker" means joiners hit at full Attack. Fine, but "leading" should name Pack.
- **Once per enemy:** the Prima Donna's key is now set at declaration. A declared attack that whiffs still spends it. That's acceptable; put it in the Details.
- **Last Blow (9.9.2):** still can't cause a wipe. It can turn a final-exchange mutual wipe into a defender's win, which is the intended effect.
- **Slow walls:** stacked Bitter 4–5 floors most first hits at 1. R12 isn't benched and the soak isn't rerun. The risk is attack-limit stops, so run the soak before merging.

## 2. Bridge Toad and Tiddy Mun at the buy moment

**Bridge Toad 1/3, R1, empty board.** Mire makes its enemy attack it in about 0.85 of fights, before the Toad dies or the enemy does: 2 SP × 0.85 = **1.7 SP a fight**, against B4's T1 combat cap of 1.0. Priced with c_combat(1) = 3.0: 4 + 5.1 = **9.1 against 5 (+82%)**, over Little Nip (8.5). Bought R1, it banks about six gains by R9: a 7/9, and **Bog low at 59.6%**, second of the lows. The fixture's 3/5 is a guess that undersells the card as written. **Cut 1:** "Mire. After its Mired enemy attacks this: gain +1/+1 permanently, up to +3/+3." (13 words; golden "+2/+2 ... up to +6/+6"). It reaches 4/6 by about R5, between the 34% and 50% probes, below Nip's typical R9 size. Its job, a low-roll body that scales, survives.

**Tiddy Mun 3/6, R8, the Prima Donna and two mirers.** +2 Health twice a fight, fired ~0.95: 3.8 SP × 0.9 (Health-only growth) × c_combat(5) 1.6 ≈ 5.5, plus ~2.5 for walls surviving this fight, plus a 9 body: **~17 against 12 (+40%)**. Pass 2 costed the old text at 14.8 (+23%). Under the T5 cap. On the bench the redesign *lowers* Bog high from 51.0 to 43.3. The designer's reason, gains going to dead walls, is the Bitter-timing problem, and Bitter-first already fixes it. **Ask 3:** keep the old card, one rule change fewer. If the redesign stays, the wording is in §5.

## 3. The corrected fixtures

Fair, not generous. Bog high (86 stats, two Suppers, `tribe_bonuses` 2) matches every other high's Supper count. It sits inside the field: Hunters 88, Fairies 98, Hedgerow 72 plus 21 bell Attack. Its 51 gold of 62 is close to Hedgerow's 48. Bog low swaps a neutral T2 for a tribal T2 and finds the Burner that two other lows found: parity. Two faults:
- The JSON `assumptions` strings still describe the old boards (cut 3).
- Bog low's Toad 3/5 is arbitrary, and the result moves 1:1 with it. Fix the Toad's cap first, then set the fixture to the capped size (4/6).

The parity check (§2's process fix) is right. I'd add the free-choice lobby rate next to every fixture result.

## 4. The Standing Committee

**Outlier: confirmed on cost, refuted on results.** By the budget, 21 bell Attack on a full Line (plus a partial-Line case of 12) is ~16 SP of text on a 9 body: **~25 against V(5) = 12**, close to Squire Lollop's ~28 a tier higher. On the bench Hedgerow high wins **35.0%**, fourth of six, not a dominant board. Its defects are elsewhere:
- **It's a cliff:** +3 gives 35.0%, +2 gives 6.0%.
- **All Attack, no Health:** the board's matchups swing from 59% to 2%.
- **Lobbies:** 113 seats, 20.4% first, interval 12.9–27.9%. Small, but the best placing tribe.

The designer's "weaken it and move stats" is right in direction. Their 22.2% for a flat +2 doesn't reproduce (cut 2).

**Proposal.** **The Standing Committee, T5, 5/7** (was 4/5): "Start of Combat: give units touching this +1/+1, or +2/+1 if all 7 touch." *Golden 10/14:* "+2/+2, or +4/+2 if all 7 touch."
- Full Line: +14/+7 instead of +21/+0. One sentence, same shape as Lollop, and still half of Lollop's +2/+2 at T6 in Health.
- Bench: Hedgerow high **35.3%** (unchanged), but no longer all-or-nothing: Hunters 11, Oozes 23.5, Fairies 24, Birds 45, Bog 73.
- Stats move into the Committee's own body, not into Mallow. Mallow 4/6 scores the same (35.4%), but Mallow already grows +2 SP a turn at T4 (about +60%), so it shouldn't take more.
- By hand it's still over budget (~26). That's true of the whole board-aura class. The class is the owner's call, not this pass's.

## 5. Wording

- **Bitter reminder:** "When an enemy attacks this, it first loses this much Attack, down to 1." 14 words, fine. The rulebook entry adds: after the attack's own bonuses, leading attacker only (not Pack joiners), Prima Donna's once-per-enemy spent at declaration.
- **Toad:** "its Mired enemy" matches Jenny. Fine. With the cap, drop "Once a fight" (§2).
- **Tiddy, if kept:** "first," mid-sentence breaks rule 1. Use "Before a Mired enemy attacks one of your units: it gains +2 Health permanently. Twice a fight."
- **§3 of the doc:** "Squire Lollop gives +14/+14 to all seven" means +2/+2 each. Say that.

## Not done

No R3/R6/R12 fixture runs, no soak with the rule on, no lobby run of the Toad or Committee changes. The lobby run used the old Bridge Toad (gold), since the redesign isn't built.
