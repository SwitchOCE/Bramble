*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the fairies analyst draft. The critic's corrections in critic-fairies.md win where they differ.]*

## Fairies: dial check for A3.5

**Verdict: plausible on today's dials, with no extra dials needed.** All six moving dials already grow Ring size, which is the size axis the Quilboar lesson points to. Most of the raise comes from `fairies_ring_growth` (Cluricaun).

### 1. Dials (`content/pass3/rates.json` @424b3c2a)

✱ marks a dial whose B and C values differ.

| Dial | A | B | C | Read at (src/core) | Card: text at B |
|---|---|---|---|---|---|
| ✱ `fairies_ring_growth` | 1 | 2 | 4 | pass3_fairies.gd:147 | Cluricaun: "End of Turn: if every slot has a Ring, your Rings grow +2/+2." |
| ✱ `fairies_initial_ring_size` | 1 | 4 | 6 | pass3_birds.gd:181 | Ring size keyword: "starts at +4/+4" (pass3_text.gd:597) |
| ✱ `fairies_lob_growth` | 1 | 1 | 3 | pass3_fairies.gd:157 | Lob: "Shy. When this leaves: your Rings grow +1/+1 per 2 turns it stayed." |
| ✱ `fairies_silky_growth` | 1 | 1 | 2 | pass3_fairies.gd:165 | Silky: "Shy. After a Shy unit leaves: your Rings grow +1/+1." |
| ✱ `fairies_monarch_multiplier` | 2 | 2 | 3 | pass3_fairies.gd:177–181 | Monarch: "Every 2nd End of Turn: double your Ring size." |
| ✱ `fairies_golden_monarch_multiplier` | 3 | 3 | 4 | same | golden: "triple" |
| `fairies_monarch_period` | 3 | 2 | 2 | pass3_fairies.gd:173 | "Every 2nd" |
| `fairies_lob_turns` | 3 | 2 | 2 | pass3_fairies.gd:154 | "per 2 turns" |
| `fairies_nan_rings` | 1 | 2 | 2 | pass3_fairies.gd:103 | Nan: "Ring this slot twice." |
| `fairies_fetch_share` | 0.5 | 1 | 1 | combat/pass3_fairy_combat.gd:63 | Fetch: "with full stats" |
| `fairies_annis_rings` / `_annis_sale` | 1 / on | same | same | pass3_fairies.gd:128 / :121 | Annis: "End of Turn and after you sell: Ring the slots behind this." |
| `fairies_sally_rings`, `_queen_rings`, `_queen_period` | 1 | same | same | :137, :211, :196 | Sally, Queen |
| `fairies_chaser_gold`, `_reel_moves`, `_wisp_attack/health` | 1, 2, 1/1 | same | same | :114; combat :188, :138–139 | Chaser, Reel, Will |

**Limits from the card text:** none of the six moving dials has one. They are growth amounts (at least 0) or multipliers (at least 1), so nothing clamps. All are read with `Pass3Rates.number`, and `_n()` (pass3_text.gd:113) prints raw decimals. A value like 5.66 would show as "+5.656854/+5.656854", so path values need rounding up.

### 2. Realized R12 medians

These come from 320 lobbies on source `d5b5b4f8`. All files are on 322a28cb.

| Line | A (shipped) | B | C |
|---|---|---|---|
| `fairies_ring` (engine_carry, the committed engine line) | 142.5 [135, 148.5] | **306** [285, 326] | **617** [542, 723] |
| `fairies_court` (tempo) | 163.5 [156, 181] | 401.5 [361, 458] | 969.5 [796, 1168] |

**Sources:**
- B and C: `docs/ideation/evidence/wave1-rebase.md:26–27, 30–31`, with data in `tools/sim/evidence/wave1-rebase-comparison.json`.
- A: `docs/ideation/evidence/wave1-shipped-baseline.md:20–21`.

**How current these are:**
- The Fairies rates in `wave1-rebase-{B,C}-plan.json` exactly match today's B and C. The shipped run's rates exactly match today's A.
- Fairy unit files and `pass3_fairies.gd` are unchanged from d5b5b4f8 to 424b3c2a. Only bot splash logic, one Fetch dispatch line and the lines' `base_strategy` changed.
- The opponents are older: pass-2 Hunters, free-splashing anchors, Birds C at the superseded 4× homecoming, and no pass-3 Oozes or Hedgerow.
- Medians count survivors only.
- `baseline-step2.md` Fairies rows are benchmark boards on older content, so I didn't use them.

### 3. Factor needed

| Line | B: 900 ÷ R12 | C: 1,800 ÷ R12 |
|---|---|---|
| Ring | ×2.94 | ×2.92 |
| Court | ×2.24 | ×1.86 |

### 4. Plausibility

**How the real boards respond:** ring rose ×2.15 from A to B and ×2.02 from B to C; court rose ×2.41 from B to C.

**Paper model:** I ran a scratch copy of `fairies-pass3-model.py` with every rates.json dial wired in, and Cluricaun firing every End of Turn as the current text says. Its median over typ/slow/low lines gives:
- B to C response: ring ×1.97 and court ×1.93. That matches the real ring response.
- Level: real is 0.17× of paper at both B (306 vs 1,809) and C (617 vs 3,569). Because the ratio holds, the paper's shape can be applied to the real boards.

Along the path, with growth dials rounded up to whole numbers and multipliers to halves:

| t | Ring growth / start size / Lob / Silky / Monarch (golden) | Paper ring × | Implied real ring | Implied real court |
|---|---|---|---|---|
| 1.5 | 6 / 8 / 6 / 3 / 4 (5) | ×3.04 | ~931 | ~1,165 |
| 2.0 | 8 / 9 / 9 / 4 / 4.5 (5.5) | ×4.06 | ~1,244 | ~1,537 |
| 2.5 | 12 / 12 / 16 / 6 / 6 (6.5) | ×6.25 | ~1,914 | ~2,321 |
| 3.0 | 16 / 14 / 27 / 8 / 7 (7.5) | ×8.78 | ~2,688 | ~3,168 |

**Solved t:**

| Line and preset | Paper shape | Log-linear on real points | Pessimistic end of interval |
|---|---|---|---|
| Ring, B | 1.56 | 1.54 | 2.12 |
| Ring, C | 2.49 | 2.53 | 3.49 |
| Court, B | 1.23 | 0.92 | not computed |
| Court, C | 2.22 | 1.70 | not computed |

The pessimistic column uses the interval ends for the B-to-C response (542 ÷ 326).

The central estimates sit under both caps (2 for B, 3 for C). At the pessimistic end, the ring line would just hit both caps.

**Which dial carries the raise.** Each dial alone at t = 2 (ring line, total ×4.06):

| Dial | Effect on R12 |
|---|---|
| `fairies_ring_growth` | **×2.75** |
| `fairies_lob_growth` | ×1.78 |
| `fairies_silky_growth` | ×1.29 |
| `fairies_initial_ring_size` | ×1.24 |
| Monarch multipliers | ×1.00 |

The Monarch multipliers do nothing at R12 because the first Midsummer comes on R13 or R14.

### 5–6. Proposals

No extra dials are needed. Two settings would make the path work as intended:

1. **Round up for the text.** Round `ring_growth`, `lob_growth`, `silky_growth` and `initial_ring_size` up to whole numbers, and the Monarch multipliers up to the nearest half. That keeps the card text readable, and rounding up adds about 8% at t = 1.5, in the generous direction.
2. **Take the Monarch multipliers off the path and hold them at C (×3, golden ×4).** This is an ask for the orchestrator. They add nothing at R12 but inflate R14:
   - On paper, R14 grows ×9.0 at t = 2 and ×29.8 at t = 3 against B. Holding Monarch at C cuts that to ×6.1 and ×13.0.
   - Real boards are already steep after R12: R14 ÷ R12 is 2.7 at B and 5.4 at C.

**If run 1 lands at the pessimistic end:** ring growth is already the size lever, and the count dials (Annis, Nan, Queen) would only add Rings. I'd treat a miss as an arrival or rainbow-completion problem to triage, not a reason to add dials.

The scratch model copy and drivers are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/fairies/` (`model_dials.py`, `drive.py`, `drive_lib.py`, `solve.py`).