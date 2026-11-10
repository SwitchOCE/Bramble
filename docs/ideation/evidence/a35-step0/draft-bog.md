*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the bog analyst draft. The critic's corrections in critic-bog.md win where they differ.]*

## Bog folk: dials, realized boards, factor, path

### 1. Dials (`content/pass3/rates.json` at 424b3c2a)
Preset A has no Bog overrides, and B is the base, so A equals B for every Bog dial. Only two dials differ between B and C. All reads are under `src/core/` at 424b3c2a. Card text comes from `content/units/*.json`, and the design doc is `docs/ideation/content/pass3/bog-pass3.md` §3, costed in `presets.md:128–158`.

| Dial | A = B | C | Read in | Card, text at B |
|---|---|---|---|---|
| **bog_soak_keep** | 2 | **3** | pass3_bog.gd:109,144; combat/pass3_bog_combat.gd:117 (queues floor(loss × keep)); pass3_bog_text.gd:281 | The Soak keyword (Bridge Toad, Gideon, Prima Donna, Jenny, Peat King, Lantern Man, Prince Restored; the Chorus lends it): "keep +2/+2 per Attack taken from its Mired enemies" |
| **bog_golden_soak_keep** | 4 | **6** | same places | golden Soak |
| bog_tiddy_share / golden | 0.5 / 1 | same | pass3_bog.gd:91–93; bot_bog.gd:92 | Tiddy Mun: "the Bog folk beside this split half the Toll" |
| bog_frog_multiplier / golden | 2 / 3 | same | combat/pass3_bog_growth.gd:56 | His Highness and the Prince Restored: "Every third kiss: double the Bog folk beside this" |
| bog_kiss_period | 3 | same | pass3_bog_growth.gd:38; pass3_bog_combat.gd:85 | the "third" in that text |
| bog_nan_share / golden | 0.5 / 1 | same | pass3_bog.gd:91–93 | Warty Nan: "smallest Bog folk gains half the Toll" |
| bog_ranocchio_share / golden | 0.5 / 1 | same | pass3_bog_combat.gd:240 | Signor Ranocchio: "gain half its Attack as +Attack/+Health permanently" |
| bog_bitter_share | 0.25 | same | pass3_bog_combat.gd:167 | the Bitter keyword |

**Guards and switches, all held:**
- bitter_round_up true (combat:169)
- soak_mired_only true (combat:194)
- kisses_per_fight 1 (growth:31)
- frog_doubles_per_turn 1 (growth:73)
- capstone_gain_toll false (pass3_bog.gd:54)

**Answer, economy and count dials, all held:**
- hopkin 0.25 (combat:227), bufo_halvings 1 (combat:276), gideon_hitbacks 1 (combat:260), sal_toll_multiplier 1 (start:164)
- cutter and pretender gold 1 (growth:144)
- king_peatlings 2 (growth:154), peatling_stat_share 1 (growth:163)
- prima_donna_patches 3 (start:43), chorus_lends 2 (combat:133), lantern_lures 1 (start:67), jenny_pulls 1 (start:82)

### 2. Realized boards: missing
- **No lobby has seated the pass 3 lines** `bog_court` and `bog_swamp` (`tools/sim/lines/bog.json`). At both commits, `git grep` finds them only in the design doc, the line file and a content test.
- `wave2b-build.md` covers only Oozes and Hedgerow.
- `docs/ideation/evidence/wave1-rebase.md` ran pass 3 Bog (d5b5b4f8), but only as blind Hard seats, and it reports no Bog R12.
- **The only measured Bog R12 is older content.** Quilboar H1's `line_bog_engine` ran on source edfe1ed1, which predates wave 2a, so it is pass 2 Bog. It reads B 119 (`docs/ideation/reference/quilboar/h1.md:72`) and 121 in its C arm (:87). That arm's native rates were unchanged, so the 121 is not Bog's C. It doesn't apply to pass 3.

**Estimate in its place.** I made a copy of `bog-pass3-model.py` with every dial exposed. It reproduces `tribe-agents.json` exactly: 988, 1,272, 1,430 and 1,859. I took realized = paper × 0.35, the geometric mean of wave 1's 0.17–0.72.
- **B:** paper 988 in a 900 field gives about 346 (range 168–711). In today's B lobby (R12 about 394), paper is 649, so about 227 (110–467).
- **C:** paper 1,859 in an 1,800 field gives about 651 (316–1,338).

### 3. Factor needed
- **B:** 900 ÷ 346 = **2.6×** (range 1.3–5.4) once the other tribes reach target, or 4.0× in today's lobby.
- **C:** 1,800 ÷ 651 = **2.8×** (range 1.3–5.7).

### 4. Plausibility: not plausible on today's path
The only dial on the path is Soak keep. It has no limit from card text.
- At t = 2: k = 5 (4.5 rounded up). The path gives golden 9, but golden Details needs 2k, so golden 10.
- At t = 3: k = 7, golden 14.

**Sensitivity, court R12 in a 900 field (today's B is 988):**

| Change | Court | Swamp |
|---|---|---|
| k 2→3 | ×1.29 | |
| k 2→5 | ×1.86 | ×1.50 |
| k 2→7 | ×2.43 | |
| Tiddy ½→1 | ×1.23 | |
| Frog ×2→×3 | ×1.20 | |
| Frog ×2→×4 | ×1.32 | |
| Kiss period 3→2 | ×1.08 | |
| Kiss period 3→1 | ×1.65 | |
| Nan ½→1 | ×1.10 | |
| Ranocchio ½→1 | ×1.00 | ×1.27 |
| Bitter ¼→⅓ | ×1.25 | |

**The path itself:**
- **B at t = 2:** paper 1,838, about 643 realized, which is **0.71×** of 900.
- **C at t = 3:** paper 3,574, about 1,251 realized, which is **0.69×** of 1,800.

Both fall under the 0.75× floor. If the lobby stays at today's size, they drop to 0.45× and 0.56×. The path passes only if Bog realizes at least 0.37× of its paper, and the other tribes reach their targets.

### 5. Proposals: three existing dials that grow size
1. **bog_tiddy_share** (the funnel into the carry)
   - Values: B 0.5, C 0.75; golden B 1, C 1.5. At t = 2 it clamps to 1.0 (from 1.125), golden 2 (from 2.25).
   - Limit: the share of the Toll can't pass 1, "split the Toll". Golden stops at 2, "twice the Toll", which Sal's golden text already uses.
   - Text: "split half the Toll" at B becomes "split three quarters of the Toll" at C, and "split the Toll" at t = 2. Golden at C would print "150% of the Toll", so the text printer needs a word for 1.5.
   - Why it moves R12: it pours the whole board's Toll into the carry every turn.
2. **bog_frog_multiplier** (an integer dial)
   - Values: B 2, C 3; golden B 3, C 4. At t = 2: 5 and 6. At t = 3: 7 and 8.
   - Limit: the text only needs it above 1. The once-a-turn and one-kiss-a-fight guards stay.
   - Text: "double" becomes "triple", then at t = 2 the printer gives "multiply by 5 the Bog folk beside this". That is true but awkward; "multiply the Bog folk beside this by 5" reads better.
   - Why it moves R12: it multiplies the carry's size and compounds with k, as in the Quilboar lesson.
   - Risk: the late tail grows. Court R15 ÷ R12 goes from 4.8 to 6.8 at t = 2.
3. **bog_ranocchio_share** (the Swamp's carry)
   - Values: B 0.5, C 0.75; golden B 1, C 1.5. At t = 2 it clamps to 1, golden 2.
   - Limit: share at most 1, "gain its Attack"; golden "twice its Attack".
   - Text: "gain half its Attack" becomes "three quarters of its Attack", then "its Attack".
   - Why: k barely moves the Swamp, and this is the Swamp's own size dial.

**The combined path:**

| Field | t = 1 | t = 2 | t = 3 |
|---|---|---|---|
| 900 field, court | paper 1,634, about 572 (0.64×) | paper 2,901, about 1,015 (**1.13×**) | |
| 1,800 field, court | | paper 4,195, about 1,468 (0.82×) | paper 6,127, about 2,144 (**1.19×**) |

In today's smaller lobby the combined path gives 0.75× at B (t = 2) and 0.96× at C (t = 3). The Swamp at t = 2 in the 900 field comes to about 706, which is 0.78×.

**Not proposed:**
- Kiss period: it changes frequency, not size, and a period of 1 makes the late tail run away.
- Nan: she spreads stats rather than concentrating them (09a).
- Bitter: it adds to the answer stack.
- Patch, lend and Peatling counts: they grow by count, not size.

**Caveats:**
- The 0.35 realization factor is a guess.
- Bog's board follows the lobby's size: going from a 900 field to today's 394 cuts the paper court from 988 to 649. Bog's t should be fitted after the other tribes' t, or together with them.
- The model feeds Bog pre-start enemy sizes. Bites happen at fight-time sizes, which are bigger, so real boards would err high.

Scripts:
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/bog/dials.py`
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/bog/path.py`