*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the hedgerow analyst draft. The critic's corrections in critic-hedgerow.md win where they differ.]*

## Hedgerow folk: preset dials and the R12 path

**Verdict:** the dials already on the path can plausibly reach both targets. In the paper model, B needs t ≈ 0.4 and C needs t ≈ 1.5, both well under the caps. No extra dials are needed.

### 1. Dials (rates.json at 424b3c2a)

Preset A has no Hedgerow keys, so it falls back to the base rates, which equal B. Four dials differ between B and C (marked **moved**).

Code paths: T = `src/core/pass3_hedgerow_text.gd` (its `PARAMETERS` table at lines 5–27 passes each dial to the runtime), R = `src/core/pass3_hedgerow.gd`, bot = `src/core/bots/bot_hedgerow.gd`.

| Dial (`hedgerow_…`) | A = B | C | Card: built text at B | Read at |
|---|---|---|---|---|
| **dozey_wake_multiplier** | 2 | **3** | Dozey: "Every 3 turns in this slot: double its stats" | T:280, R:294 |
| **golden_dozey_wake_multiplier** | 2 | **3** | golden Dozey, same | T:278, R:292 |
| **mallow_multiplier** | 2 | **3** | Mallow: "End of Turn: double your two smallest Hedgerow units' stats" | T:231, R:196, bot:171 |
| **treasurer_per_gold** | 1 | **2** | Treasurer: "End of Turn: gain +1/+1 per gold in your Larder" | T:303, R:200, bot:196 |
| dozey_period | 3 | 3 | Dozey's wait | T:150/288, R:269 |
| dozey_food_per_gold | 2 | 2 | Dozey: "+2/+2 per gold" (the design said +1/+1 per 2 gold) | T:126/273, bot:190 |
| partner_period / partner_acorns | 3 / 2 | same | Partner: "two Acorns per Hedgerow unit touching" | T:150/203/207, R:164/170 |
| crumb_pass / crumb_sell_share | 1 / 1.0 | same | Crumb | T:192–193, R:152/156 |
| clover_share | 1.0 | 1.0 | Clover gives all her stats | T:215, R:179 |
| pym_pass / beadle_pass | 3 / 2 | same | "Pass +3/+3" / "Pass +2/+2" | T:221, R:186 |
| sorrel_summons / burdock_kits | 1 / 1 | same | number of summons | T:134–136/179 |
| mallow_targets | 2 | 2 | "two smallest" | T:230, R:194 |
| urchin_bristle / urchin_hunker_targets | 2 / 1 | same | Urchin | T:124/250/254 |
| sergeant_share_per_gold / sergeant_throws | 0.1 / 1 | same | Sergeant | T:260/267 |
| hayward_per_gold | 1 | 1 | Hayward | T:305, R:211 |
| committee_share | 0.25 | 0.25 | "a quarter of the smallest one's stats" | T:323, R:235 |
| lollop_share | 0.1 | 0.1 | Lollop | T:331, R:131/339 |
| mast_gold_step / mast_cap | 5 / 5 | same | Mast | T:340–348, R:243/249 |
| larder_gold | [1,5,16] | same | Larder item values | T:140/364 |

**Limits from the card text.** The two multipliers must stay above 1 and the Treasurer above 0. Nothing caps them from above, so nothing clamps up to t = 3. All four moved dials are floats, so nothing is rounded up.

### 2. Realized boards (current pass 3 content, B only)

- **Supper**, the engine line (`engine_flag: true`): R12 median **730** at B, from 25 of 32 seats still alive. Source: `docs/ideation/content/pass3/wave2b-build.md:340` at 424b3c2a, and `docs/ideation/evidence/wave2b/hedgerow/hedgerow-summary.json`. Its paper reference is 979 (`presets-model/six.json`), so real is 0.75× of paper.
- **Parish**, the tempo line: **1,094.5** (`wave2b-build.md:341`).
- **C was never measured.**
- Eliminated seats drop out of the median, so 730 reads a little high.

**What the real Supper looks like** (my read of the R12 captures in `hedgerow-fights.jsonl.gz`):
- Dozey is on only 14 of 25 boards and holds **15%** of all Supper stats. The paper has him at 61%.
- From R10 the median Larder is 0 gold, so the bot never holds food for him.
- Mallow is on 17 of 25 boards. Those boards have a median of **1,156**, against 461 without her.
- So the real Supper grows mainly through Mallow and the Committee, not through Dozey.

### 3. Factor needed

- **B:** 900 ÷ 730 = **×1.23**.
- **C:** today's C is unmeasured. Scaling 730 by the paper's C/B ratio (1.77 in six.json, 1.87 in my copy) estimates 1,290–1,370, so C needs about ×1.3–1.4 on today's C. That is **×2.47 over today's B**.

### 4. Plausibility

I ran a copy of `hedgerow-pass3-model.py` with `python3 -I`, set to the built B values: food 2 per gold, Beadle 2, Committee a quarter, Partner 2, Mallow on two targets, plus a Mallow multiplier dial. On this copy the Supper R12 at B is 1,579 (mean of on-time and late), so real is 0.46× of it. The ratio from B to C still matches six.json.

Paper Supper R12 along the path, ×B:

| t | 0.25 | **0.40** | 1.0 | **1.46** | 2 | 3 |
|---|---|---|---|---|---|---|
| Supper | 1.13 | **1.23** | 1.87 | **2.47** | 3.74 | 8.1 |

One dial at a time, at t = 1:

| Dial | Supper | Parish |
|---|---|---|
| Wake ×3 | ×1.59 | ×1.00 |
| Mallow ×3 | ×1.24 | ×2.90 |
| Treasurer 2 | ×1.00 | ×1.00 |

- On paper, **B needs t ≈ 0.4** (wake and Mallow ×2.35, Treasurer 1.32) and **C needs t ≈ 1.5** (×3.67, 2.83).
- Even if real boards respond only half as strongly as paper, t_B ≈ 0.8 and t_C ≈ 2.9, both under the caps of 2 and 3.
- The real Supper is Mallow-driven, so its response probably sits between the paper Supper and the paper Parish. That puts t_C at about 1.0–1.5.

### 5. Which dial carries the raise

- **On paper:** the wake multiplier, about 75% of the raise.
- **In real lobbies:** most likely Mallow's multiplier, because Dozey holds only 15% of the stats.
- **The Treasurer does nothing for the Supper**, because nothing is held in the Larder.

### Caveats

- **The Parish rides the same Mallow dial.** It is already 1.22× B's target. At t_C ≈ 1.5 the paper puts it near ×5.4 of its B board, about 5,900 real, or 3.3× C's target. Watch it in run 1. `presets.md` §4 already lists Mallow ×3 → ×2.5 as Hedgerow's first cut.
- **Fractional values print literally on the cards.** For example "multiply its stats by 2.35" or "+1.32/+1.32 per gold" (`_n`, `pass3_text.gd:112`). The text stays true, but rounding up to half steps reads better: Mallow and wake ×2.5 and Treasurer 1.5 at B (t ≈ 0.55). The estimate still keeps that inside 0.75–2× of the target.
- **The bot doesn't hold the Larder.** That is a policy gap, not a dial gap, and it leaves Dozey's food, the Treasurer, Hayward and Mast mostly idle. If run 1 shows a weak response anyway, the first extra dial to try is `committee_share`: B ¼, limit 1 from "gain … of the smallest one's stats".

The copied model and the analysis scripts are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/hedge/`, the model as `hm.py` and the sweep as `drive.py`.