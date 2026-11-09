# Pass 2 Bog fix: costing and triage review

9 Nov 2026, a fresh cloud reviewer of `content/pass2-bog.md`. Buy-moment costing as `birds-pass1-costing.md` (V(t) 5/7/8/10/12/14, B4 growth caps), then triage against the owner's test: "If it's not fulfilling its primary purpose, then it's always useless and it becomes a trap."

**Counts: 3 cut, 3 ask, the rest fine.** The fix moves the problem: Bog is off 0% on fair R9 fixtures, and in 400 lobbies Bitter-first lifts Bog's first rate only 13.5% → 15.6%, so it isn't dominant. Hedgerow leads lobbies (25.8%). The uncapped Toad carries the low roll.

**Cut**
1. **Bridge Toad's growth is uncapped**: 1.7 SP a fight against a T1 combat cap of 1.0. Add "up to +3/+3".
2. **The Committee's flat +2 numbers don't reproduce**: a flat +2 gives Hedgerow high 6.0%, not 22.2%. Use §4's proposal.
3. **`corrected-boards.json` still carries the old `assumptions` text** ("One Supper", Scarecrow, Wobbly).

**Ask**
1. **The Prima Donna to Bitter 2**: she gains the most from the new timing, about +7 SP a fight.
2. **Tiddy Mun: keep the old text** (+1/+1 after, twice a fight). The old one benches better under Bitter-first (51.0 vs 43.3) and costs less.
3. **Warty Nan**: about +50% at T1 under the new timing, level with Little Nip. Watch Bog's R1–R4 results.

## What I ran

In a scratch worktree with `prototype.patch` and a Mire-only Toad, I reproduced §6 exactly (43.3 / 34.2; Hedgerow high 35.0), then varied one thing at a time on `corrected-boards.json` (100 seeds × swapped sides). I also ran `free_choice_plain`, 400 lobbies per arm, on the pass 2 cards merged with `ideation/main`'s tools (§1). No repo code changed.

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

**Bog low's 34% is the Toad's banked size, not Bitter** (Bitter-first alone: 3.8 → 7.6). **Bog high's gain is Bitter** (12.1 → 51.0); the new Tiddy then takes 8 points off.

## 1. Bitter hits first

The new timing adds min(N, A−1) once per enemy that attacks the unit; later hits were already shrunk.

| Unit | Bought | Added by the rule | Verdict |
|---|---|---|---|
| Warty Nan 1/3, Bitter 1, lends 1 | R1, empty board | ~1.2 hits on her, ~1.2 on neighbours: **+2.4 SP**, ~8 vs 5 (+55%). Bitter 1 halves a T1 hit | **Ask 3**. Level with Little Nip (8.5) |
| Madame Bufo 1/4, Bitter 2 | R3 | ~0.9 locked hits × 1.5: **+2 SP** (+30%) | Fine, at the band's edge |
| Natterjack Chorus, lends 1 to two neighbours | R5 | **+2 SP**, +25% | Fine |
| The Prima Donna 2/8, Bitter 3 once per enemy | R8 | Three Mired enemies must hit her: 3 × 3 × 0.8 ≈ **+7 SP** on V = 12. Beside Nan and the Chorus, Bitter 5 floors any enemy up to 6 Attack | **Ask 1: Bitter 2** (the designer's fallback); optional given the lobby result |
| Peatlings 4/4, Bitter 2 | R10+, via the Peat King | ~+1.5 each, twice: +3 on ~28 | Fine |
| Non-Bog Bitter | — | None in the slice pool, heroes or spells | — |

**Lobbies.** Before pass 2, Bog took first **17.2%** in the plain arm (second to Hedgerow's 20.4%) while scoring 0% on R9 fixtures: the fixtures are threshold tests (H9), so a +39-point fixture lever must be checked in lobbies. My run, seeds 1–400, old gold Toad:

| Plain arm, pass 2 cards | Bog seats | Bog first (95%) | Bog mean place | Hedgerow first | Hunters first | Birds first |
|---|---:|---:|---:|---:|---:|---:|
| As built | 281 | 13.5% [9.8, 17.3] | 4.30 | 25.8% | 17.1% | 5.5% |
| Bitter-first + new Tiddy | 301 | 15.6% [11.8, 19.5] | 4.21 | 22.1% | 18.1% | 6.8% |

**Verdict: fine.** +2 points, inside the noise; pick 8.8% → 9.4%. Run the Toad redesign in the same arm once built.

**Edge cases (engine source):**
- **Counters and pounces:** `drain()` adds a counter's `attack_bonus` before `attack()`, so Bitter subtracts after it. State this: it decides the floor (Gideon's 2+2 counter into Bitter 3 deals 1, not 3).
- **Pack joiners:** joiners hit at full Attack. Fine; name Pack instead of "leading".
- **Once per enemy:** now spent at declaration, even if the attack whiffs. Acceptable; put it in Details.
- **Last Blow (9.9.2):** still can't cause a wipe; it can turn a final mutual wipe into a defender's win, as intended.
- **Slow walls:** stacked Bitter 4–5 floors most hits at 1. Run the soak (attack-limit stops) and R12 before merging.

## 2. Bridge Toad and Tiddy Mun at the buy moment

**Bridge Toad 1/3, R1, empty board.** Mire makes its enemy hit it in ~0.85 of fights: **1.7 SP a fight**, against a T1 combat cap of 1.0. With c_combat(1) = 3.0: **9.1 against 5 (+82%)**, over Little Nip (8.5). Bought R1, it banks ~6 gains by R9: a 7/9, and **Bog low 59.6%**. **Cut 1:** "Mire. After its Mired enemy attacks this: gain +1/+1 permanently, up to +3/+3." (golden +2/+2, up to +6/+6). A 4/6 by ~R5, between the 34% and 50% probes; the scaling job survives.

**Tiddy Mun 3/6, R8, the Prima Donna and two mirers.** 3.8 SP × 0.9 × c_combat(5) 1.6 ≈ 5.5, ~2.5 for walls surviving now, 9 body: **~17 against 12 (+40%)**, under the T5 cap; the old text costed 14.8 (+23%). On the bench the redesign *lowers* Bog high 51.0 → 43.3. Its reason, gains on dead walls, is the timing problem Bitter-first already fixes. **Ask 2:** keep the old card.

## 3. The corrected fixtures

Fair, not generous. Bog high (86 stats, two Suppers) sits inside the field (Hunters 88, Fairies 98, Hedgerow 72 + 21 bell Attack), at 51 of 62 gold vs Hedgerow's 48. Bog low's Bufo and Burner match what other lows found. Two faults:
- The JSON `assumptions` strings still describe the old boards (cut 3).
- Bog low's Toad 3/5 is arbitrary and the result tracks it. Cap the Toad, then use 4/6.

The parity check is right; add the lobby rate next to each fixture result.

## 4. The Standing Committee

**Outlier: confirmed on cost, refuted on results.** 21 bell Attack (12 on a partial Line) is ~16 SP of text on a 9 body: **~25 against V(5) = 12**, near Lollop's ~28 a tier up. But Hedgerow high wins **35.0%**, fourth of six. The defects:
- **It's a cliff:** +3 gives 35.0%, +2 gives 6.0%.
- **All Attack, no Health:** the board's matchups swing from 59% to 2%.
- **Lobbies:** Hedgerow leads free choice: 20.4% first before pass 2, **25.8%** (mean place 3.58) on pass 2 cards.

**Proposal.** **The Standing Committee, T5, 5/7** (was 4/5): "Start of Combat: give units touching this +1/+1, or +2/+1 if all 7 touch." *Golden 10/14:* "+2/+2, or +4/+2 if all 7 touch."
- Full Line: +14/+7 instead of +21/+0; Lollop's shape, below Lollop.
- Bench: Hedgerow high **35.3%** (unchanged), but no longer all-or-nothing: Hunters 11, Oozes 23.5, Fairies 24, Birds 45, Bog 73.
- Stats go into its body, not Mallow's: Mallow 4/6 scores the same (35.4%), but Mallow is already ~+60% at T4.
- Still ~26 by hand, like every board aura; that class is the owner's call.

## 5. Wording

- **Bitter reminder:** "When an enemy attacks this, it first loses this much Attack, down to 1." Fine. The rulebook adds: after the attack's bonuses, not Pack joiners, once-per-enemy spent at declaration.
- **Toad:** "its Mired enemy" matches Jenny. Fine. With the cap, drop "Once a fight" (§2).
- **Tiddy, if kept:** "first," mid-sentence breaks rule 1. Use "Before a Mired enemy attacks one of your units: it gains +2 Health permanently. Twice a fight."
- **§3 of the doc:** "Squire Lollop gives +14/+14 to all seven" means +2/+2 each. Say that.

## Not done

No R3/R6/R12 runs, no soak, no lobby run of the Toad or Committee changes; CSVs not committed. Rerun: `tools/sim/bench.sh free_choice_plain=400` on a merge of this branch and `ideation/main`, with the prototype patch and `BITTER_FIRST=1 TIDDY_FIRST=1 TIDDY_A=0 TIDDY_H=2 TIDDY_LIMIT=2`.
