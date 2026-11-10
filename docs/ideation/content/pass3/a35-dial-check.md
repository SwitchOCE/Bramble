# A3.5 step 0: dial check for run 1

*[Saved verbatim from the synthesis agent of workflow wf_ce74d9f0-cdb, 10 Nov. Drafts and critics: `docs/ideation/evidence/a35-step0/`. Calls: DECISIONS "A3.5 step 0: dials for run 1".]*


Dial values: `content/pass3/rates.json` @424b3c2a. Evidence: 322a28cb unless named. Each tribe merges a draft with a critic's check; the critic's sourced corrections win. **Call** items go to `DECISIONS.md`.

## In short

- **Reach 900 (B) and 1,800 (C) on today's dials:** Birds (t ≈ 1.05 / 1.6), Fairies (1.5 / 2.5), Hedgerow (0.6–0.7 / 2.1–2.7; C tight) and Bog (if the lobby grows).
- **Bog gets one reserve dial**, Tiddy Mun's share: with no lobby growth it sits at 0.76× / 0.90×.
- **Need extra dials:** Hunters (Ermeline's Pelts; Glutton and Lodger past 1) and Oozes (Hasty, Aspic, a new eat multiplier). Hunters still need lobby growth; Oozes likely miss C (~0.65×), as Stone Soup is on 6 of 26 engine boards.

## Per tribe

Limits come from card text unless marked *rule* (the plan's share cap of 1) or *choice*. **+** marks an extra dial.

### Birds (`birds_homecoming`)

| Dial | B | C | Limit |
|---|---|---|---|
| homecoming_multiplier | 2 | 2.5 | none |
| golden_homecoming_multiplier | 2 | 3 | ≥ normal |
| chiffchaff_gain | 1 | 4 | none |
| golden_egg_multiplier | 2 | 3 | none |
| redbreast_share, cuckoo_share | 1/8, 0.1 | 1/6, 0.15 | 1 *rule* (golden 2×) |
| stork_gold_step | 6 | 5 | ≥ 1 |

- **R12 at B:** 367, n = 269 (`evidence/wave1-rebase.md:24`); other reads 270–367. **Factor:** ×2.45 (B); ×4.9 over B (C).
- **Verdict: yes, conditionally.** At elasticity 0.71 (from the old 4× arm): t ≈ 1.05 (B), 1.55 (C). Homecoming and Chiffchaff carry half each, and Chiffchaff has never moved in a run. At elasticity 0.5 the full path still reaches C (t ≈ 2), but with Chiffchaff at +1, B misses (787 at t = 2).
- **Extra dials:** none. Not `trip_turns` (kills Mrs Dunnock's text). **Call:** cap Chiffchaff at +4 if A4 shows R4–R8 spikes (C then t ≈ 2.0).

### Fairies (`fairies_ring`)

| Dial | B | C | Limit |
|---|---|---|---|
| ring_growth | 2 | 4 | none |
| lob_growth | 1 | 3 | none |
| silky_growth | 1 | 2 | none |
| initial_ring_size | 4 | 6 | off path: shared (**Call**) |
| monarch_multiplier / golden | 2 / 3 | 3 / 4 | off path: 3 / 4 in both (**Call**) |

- **R12 at B:** 306; C 617 (`wave1-rebase.md:26–31`; rates and Fairy cards as today). **Factor:** ×2.94 (B), ×2.92 (C).
- **Verdict: yes.** Log fit on the real B→C step: t ≈ 1.54 (B), 2.53 (C). The pessimistic slope at the caps still gives 0.94× and 0.78×. Which dial carries it is unknown: real Fairies grow by Ring count (Quilboar L2).
- **Calls:** `initial_ring_size` is shared: every player starts at it (`recruit_rules.gd:57`), and Spore Cloud and Boundary Stone use it. It holds at each preset's value (t +0.05–0.08). Monarch adds little at R12 but inflates R14 (×9.0 on the path, ×6.1 held).
- **Extra dials:** none.

### Bog folk (`bog_court`)

| Dial | B | C | Limit |
|---|---|---|---|
| soak_keep | 2 | 3 | whole number |
| golden_soak_keep | 4 | 6 | 2 × soak_keep |
| **+** tiddy_share | 0.5 | 0.75 | 1, "split the Toll" |
| **+** golden_tiddy_share | 1 | 1.5 | 2, "twice the Toll" |

- **R12 at B:** 393, n = 135; C 866. Hard seats on Bog, not `bog_court` (`tools/sim/evidence/wave1-rebase-{B,C}.boards.json.gz`, round 12, `hard_field`; Bog code and rates as today). **Factor:** ×2.3 (B), ×2.1 (C).
- **Verdict: yes, if the lobby grows.** Realization 0.59–0.72 of paper. If the field reaches target: B 753 (t = 1), 1,088 (t = 2); C 1,344 (t = 1), 1,964 (t = 2). With no growth: 0.76× and 0.90× at the caps.
- **Extra dial (Call):** Tiddy's share, court ×1.23 at 1, clamps at t = 1.71. It concentrates the board (09a), overruling the logged hold. Before: "Start of Turn: the Bog folk beside this split half the Toll." After: "…three quarters of the Toll" (C), "…split the Toll" (limit).
- **Left off:** frog multiplier (logged hold), Ranocchio (Swamp only), Hopkin (fight-only).

### Hunters (Open Season)

| Dial | B | C | Limit |
|---|---|---|---|
| nip/sable/lutra_share | 2/3 | 3/4 | 1 *rule* |
| glutton_share, lodger_share | 2/3 | 1 | lifted (**Call**) |
| wick/grizel/pelt_share | 1/3 | 1/2 | 1 *rule* |
| russet_buff_share | 2/3 | 3/4 | 1 *rule* |
| **+** ermeline_pelts / golden | 1 / 2 | 2 / 4 | whole number; golden 10 a *choice* |

- **R12 at B: missing.** Nearest: forced Hunter seats in 3 wave 2a games, 216–467 (`evidence/review-wave2a-hunters.md:13–14`). **Factor:** ×1.9–4.2 (B), ×1.9–4.1 (C).
- **Verdict: no.** At today's field: 0.50× (B, t = 2), 0.26× (C, t = 3). The clamps bind from t = 1.
- **Extra dials:**
  1. Ermeline's Pelts, path 1, 2, 4, 8: ×1.31 (t = 2), ×2.00 (t = 3); no Laird needed. Before: "After each fight: get a Pelt of your biggest quarry." After: "…get two Pelts…".
  2. Glutton and Lodger past 1, the carry's size axis. Before: "gain two thirds of the quarry's stats." After: "three halves" (t = 2), "nine quarters" (t = 3). Golden copies already print "four thirds".
  - Together, at today's field: 0.67–0.72× (B), 0.60–0.62× (C). The target also needs lobby growth.
- **Dropped:** a new Laird repeat; the Laird multiplier (lifts R13+, not R12).

### Oozes (`line_oozes_engine`)

| Dial | B | C | Limit |
|---|---|---|---|
| soup_share | 1/8 | 1/6 | 1 *rule* |
| elder_share | 1/2 | 3/4 | 1 *rule* |
| **+** hasty_share | 1/3 | 1/2 | 1 *rule* |
| **+** aspic_bonus | 3/4 | 1 | none |
| **+** golden_aspic_multiplier | 2.5 | 3 | 1 + 2 × bonus |
| **+** eat_printed_multiplier (new) | 2 | 3 | ≥ 1, whole |

- **R12 at B:** 262, n = 26 (`content/pass3/wave2b-build.md:74` @424b3c2a), run on `c66a88e5`; `21a65947` then changed Hasty, Soup, Posset and the bot. **Factor:** ×3.44 (B); C ×3.7–6.1.
- **Verdict: no.** ~343 at both caps (0.38×, 0.19×): 20 of 26 seats never field Soup.
- **Extra dials:** Hasty and the eat multiplier give ~0.95× (B) and ~0.65× (C); Aspic adds on its boards. Expect a weak responder at C.
  - Hasty, before: "…gains a fifth of it." After: "…a third" (t = 0), "three quarters" (t = 2). It grows with the enemy.
  - Aspic, before: "…50% more from eating non-Oozes." After: "75%" (t = 0), "135%" (t = 2). On 8 of 26 boards.
  - Eat reminder, before: "The eater gains its stats permanently." After: "…, with a non-Ooze's printed stats doubled" (×5 at t = 2). On 25 of 26 boards.
- **Left off:** Slice (on no R12 board), Elder past 1 (spreads stats, against 09a).
- **First design item:** why Soup seats are rare and die early (5 of 11 out before R12). A4 watches them for snowballs (Aspic ×43 on the Soup line at t = 3).

### Hedgerow folk (Supper)

| Dial | B | C | Limit |
|---|---|---|---|
| mallow_multiplier | 2 | 3 | > 1 |
| dozey_wake_multiplier / golden | 2 / 2 | 3 / 3 | > 1 |
| treasurer_per_gold | 1 | 2 | > 0 |

- **R12 at B:** 730, 25 of 32 alive (`content/pass3/wave2b-build.md:340` @424b3c2a; current content). **Factor:** ×1.23 (B); ×2.47 over B (C).
- **Verdict: yes; C tight.** t ≈ 0.6–0.7 (B), 2.1–2.7 (C). Mallow carries it (1,156 with her, 461 without); Dozey holds 15% of real stats against paper's 70–75%.
- **Extra dials:** none. Committee and Mallow's targets lift the Parish more than the Supper.
- **Watch:** the Parish rides Mallow to ~2.1× target at B. A4 checks it.

## Checklist before run 1

- [ ] `birds_homecoming_multiplier`: fix the glossary line `effects.json:916` ("double stats").
- [ ] `birds_golden_homecoming_multiplier`: stays ≥ normal.
- [ ] `birds_chiffchaff_gain`: write 1 into preset B, with the C-only Goose, Swallow and Jay keys.
- [ ] `birds_golden_egg_multiplier`: no limit.
- [ ] `birds_redbreast_share`, `_cuckoo_share`: golden stays under 1 to t = 3.
- [ ] `birds_stork_gold_step`: whole, rounds up.
- [ ] `fairies_ring_growth`, `_lob_growth`, `_silky_growth`: snap up to whole numbers (`_n` prints raw decimals).
- [ ] `fairies_initial_ring_size`: off path.
- [ ] `fairies_monarch_multiplier` / golden: 3 / 4 in both presets and both arms.
- [ ] `bog_soak_keep`: whole; golden = 2k.
- [ ] `bog_tiddy_share` / golden: limits 1 / 2; a wording for 1.5; bot reads (`bot_bog.gd:88–132`).
- [ ] `hunters_nip/sable/lutra_share`: snap to 7/8, then 1 (`_portion` prints halves to twelfths).
- [ ] `hunters_glutton_share`, `_lodger_share`: past 1; golden needs "three times".
- [ ] `hunters_wick/grizel/pelt_share`, `_russet_buff_share`: clamp at 1.
- [ ] `hunters_ermeline_pelts` / golden: golden cap 10.
- [ ] `oozes_soup_share`: 2/9, then 3/10.
- [ ] `oozes_elder_share`: clamp at 1.
- [ ] `oozes_hasty_share`: `bot_ooze.gd:148` must read the dial.
- [ ] `oozes_aspic_bonus` / golden: golden = 1 + 2 × bonus; snap 1.35, 1.8.
- [ ] `oozes_eat_printed_multiplier`: new code, text and bot value; non-Ooze meals only; reminder per `effects.json:939`.
- [ ] `hedgerow_mallow_multiplier`: above 1; snap to half steps.
- [ ] `hedgerow_dozey_wake_multiplier` / golden: above 1; half steps.
- [ ] `hedgerow_treasurer_per_gold`: above 0; half steps.
- [ ] `scale_hero_spell_percent`: B 10, C 20, on no path.

## Missing data

| Tribe | Gap | Supplied by |
|---|---|---|
| Birds | C unmeasured (only the superseded 4× set); older field | run 1, t = 1 |
| Fairies | B and C against an older field | run 1 |
| Bog | `bog_court` never seated | run 1 |
| Hunters | Open Season never seated | run 1 |
| Oozes | B run before `21a65947`; C unmeasured | run 1 |
| Hedgerow | C unmeasured | run 1, t = 1 |

Run 1 measures t = 0 and 1 on current content, so no earlier run is needed.

## Assumptions

1. Paper only shapes each path. Run 1 sets the levels by a log fit on the same-cohort R12 median.
2. Each tribe's realization (real ÷ paper) holds from t = 0 to 1. Birds, Fairies, Bog and Hedgerow have measured reads; Hunters (0.63) and Oozes (0.275) rest on thin ones.
3. A fit through t = 0 and 1 overpredicts past a clamp, so Bog's, Oozes' and Hunters' solved t may come out low.
4. Bog and Hunters grow with the lobby. Run 1 moves every tribe together; run 2 doesn't. Fit them on R12 ÷ lobby median, or solve them last.
5. Medians count survivors, so tribes that lose seats early read high.
6. The share cap of 1 is a default. Where text stays true past 1 it is a choice; only Glutton and Lodger lift it.
7. Decimals snap to printable values toward generous (09h); integers round up.
8. A dial joins a path now or never: after run 1, a weak responder runs at its cap and is triaged.
9. Oozes' extra dials start above today's values, so their t = 0 isn't today's B. Accepted under 09h.