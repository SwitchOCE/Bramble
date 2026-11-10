*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the oozes analyst draft. The critic's corrections in critic-oozes.md win where they differ.]*

## Oozes: B and C presets from real boards

Today's two moving dials can't plausibly get the engine line to 900 at B or 1,800 at C. The one dial that carries paper's raise, Stone Soup's share, is on the board in only 6 of 26 engine seats at R12.

### 1. Dials (`content/pass3/rates.json` @424b3c2a)

A has no Oozes overrides, so A = base = B for every Oozes dial. Only two dials differ between B and C. File keys: `oz` = `src/core/pass3_oozes.gd`, `tx` = `src/core/pass3_ooze_text.gd` (face text and mechanic entries), `bot` = `src/core/bots/bot_ooze.gd`.

| Dial | A | B | C | Moves? | Read at | Card: B text |
|---|---|---|---|---|---|---|
| `oozes_soup_share` | 1/8 | 1/8 | 1/6 | **yes** | oz:107 (`soup_bonus`), tx:64,158, bot:126 | Stone Soup: "Shop units gain an eighth of your biggest Ooze's stats." |
| `oozes_elder_share` | 1/2 | 1/2 | 3/4 | **yes** | oz:299 (`_share`), tx:82,225, bot:141 | Elder Ooze: "…your other Oozes gain half its stats." |
| `golden_elder_multiplier` | 2 | 2 | 2 | no | oz:301, tx:84,227 | Elder, golden: "all its stats" |
| `aspic_bonus` / `golden_aspic_multiplier` | 0.5 / 2 | same | same | no | oz:270,273, tx:75,77,182,191, bot:135 | Aunt Aspic: "50% more from eating non-Oozes" (golden "double") |
| `slice_share` / `slice_count` | 0.2 / 1 | same | same | no | oz:197,199, tx:95,96,266,272, bot:146 | Cut-and-Come-Again: "a Slice with a fifth of your biggest Ooze's stats" |
| `hasty_share` / `hasty_swallows` / `hasty_release_deaths` | 0.2 / 1 / 3 | same | same | no | tx:87–89,108,233,244,367 | Hasty Pudding: "gains a fifth of it" |
| `golden_soup_reads` | 2 | 2 | 2 | no | oz:99, tx:66,152,311, bot:121 | Soup, golden: "two biggest Oozes'" |
| `nell_meals` | 1 | 1 | 1 | no | oz:143,179, tx:69,161 | Dishwater Nell |
| `bubble_belly` / `bubble_splits` | 1 / 1 | same | same | no | tx:104 / tx:52,194 | Bubble and Squeak |
| `dollop_belly` / `dollop_discount` | 1 / 1 | same | same | no | tx:102 / tx:50,124 | Little Dollop |
| `frumenty_meals` | 1 | 1 | 1 | no | oz:238, tx:80,208, `recruit_rules.gd`:542 | Frumenty |
| `granny_attack_multiplier`, `posset_loss_share`, `moss_golden_reduction`, `pie_gold`, `wobbly_drip`, `syllabub_fires` | 1, 0.5, 25, 1, 1, 1 | same | same | no | tx:92/253, 62/136, 72/174, 56/204, 54/143, 58/219 | Granny, Posset, Moss, Pie, Wobbly, Syllabub |

### 2. Realized boards

Both lines are pass 3 content. The 32 lobbies at B were measured on base 722f5ae4.
- **Engine line (`line_oozes_engine`), B: R12 median 262** (n=26), or 285.5 counting Bellies. Source: `docs/ideation/content/pass3/wave2b-build.md` line 74 (table) and line 81, plus `docs/ideation/evidence/wave2b/oozes-summary.json`.
- **Pot Luck (`line_oozes_tempo`), B: 200** (n=23), same lines. Line 408 marks Pot Luck's numbers as historical; it gets remeasured.
- **Neither line was measured at C.**

### 3. Factor needed

- **B:** 900 ÷ 262 = **×3.44**.
- **C:** no measurement. My estimate is ×3.7 if real boards track paper's B→C step (paper 954 → 1,771), or ×6.1 if they track my seat estimate below (about 294).

### 4. Plausibility: not plausible

**Path values:**
- Soup: 2/9 at t = 2, 8/27 at t = 3. 8/27 has no fraction name, so the face would print "29.6296%". Snap it to 2/7.
- Elder: clamps at 1 from t = 2 ("all its stats").

**Paper engine line** (my copy of `oozes-pass3-model.py`, which reproduces 954 and 1,771): ×3.99 at t = 2 and ×8.59 at t = 3. Real boards run at 0.275× paper, so that would read 1,046 at B and 2,252 at C, which looks fine.

**The real seats don't run that engine.** In `oozes-final.jsonl`:
- **R12 engine boards:** Soup 6/26, Aspic 8/26, Bubble 8/26, Nell 11/26, Elder 16/26.
- **20 of 26 seats never fielded Soup by R12.** Those 20 have a median of 258.
- **Calibration:** paper line B with Soup removed gives **254** at R12, which matches.

Without Soup, only Elder moves: ×1.10 at t = 1 and ×1.21 at t ≥ 2. I scaled each seat by its paper factor: ×1.21 for the 20 seats without Soup, ×3.99 or ×8.59 for the 6 with it. That gives:
- **B at t = 2: about 343 (0.38×).**
- **C at t = 3: about 343 (0.19×).**

### 5. Proposals

**Not a dial, and the biggest gap: why Stone Soup reaches only 23% of engine boards.** It is first in the line's priority list. Possible causes are the pool, Nell eating it from the shop (she eats the lowest-tier offer), or the bot. The seats that had Soup ran at a median of 331. If Soup were reliable, today's two dials would likely be enough: paper says 331 × 3.99 ≈ 1,320 at B and 331 × 8.59 ≈ 2,840 at C (rough, n = 6). Triage this before adding dials.

Extra dials, if Soup can't be made reliable:

1. **`oozes_hasty_share` (existing).**
   - Values: B 1/3, C 1/2. Path: t = 2 is 3/4; t = 3 is 1.125, clamped to 1.
   - Limit: 1, since the biggest Ooze can't gain more than "all of it".
   - Text at B, before: "Your biggest Ooze permanently gains a fifth of it." After: "…gains a third of it."
   - Why it moves R12: the gain grows with the lobby's biggest enemy, not with Soup. Hasty is on 8 of 26 boards.
2. **`oozes_slice_share` (existing).**
   - Values: B 1/4, C 1/3. Path: t = 2 is 4/9; t = 3 is 16/27, snapped to 3/5.
   - Limit: 1 ("all your biggest Ooze's stats").
   - Text at B, before: "…get a Slice with a fifth of your biggest Ooze's stats." After: "…with a quarter of your biggest Ooze's stats."
   - Why it moves R12: the Slice is a share of the carry, eaten as a non-Ooze, so it compounds. Cut-and-Come-Again is on 11 of 26 boards at R12 and 16 of 21 at R14, so it mostly lifts R13–R15.
   - Hasty and Slice together: paper ×1.55 on a no-Soup Hasty and Cut-and-Come-Again line, and a median of only about 351.
3. **`oozes_eat_printed_multiplier` (proposed new).**
   - Values: B 2, C 3. Path: t = 2 is 4.5; t = 3 is 6.75.
   - Limit: none in today's text; it must stay at 1 or more. It applies only to non-Ooze meals' printed stats, so Soup's committed bonus and the Ooze-passes-whole guard are untouched. Elder keeps reading the meal's own stats, so "half its stats" stays true.
   - Eat reminder at B, before: "Destroy it. The eater gains its stats permanently." After: "Destroy it. The eater gains its stats permanently, with its printed stats doubled." C says "tripled".
   - Why it moves R12: without Soup the meal is the buff, and its size is the printed stats. This is the only dial that reaches the 25 of 26 seats that have an eater.
   - With 1–3 together: paper no-Soup lines go ×2.9–3.1 at t = 2 and ×4.0–4.4 at t = 3. The estimated median is **about 857 at B (0.95×) but only about 1,169 at C (0.65×)**.
   - Risk: it still compounds through Soup. The paper Soup line goes ×15 at t = 2, so the 23% of seats with Soup could snowball. A4's extreme-miss check would need to watch them.

Even with all three, C stays under the 0.75× floor. Pushing harder means a growing size axis on a card the median seat actually fields, which is design work.

The scripts are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/` (`sens.py` to `sens5.py`, with the model copies in `oz/`).