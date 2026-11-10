*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the hedgerow critic.]*

## Hedgerow folk: check of the step-0 draft

**Corrections** (claim → what's true → source)

1. **"The paper has Dozey at 61%"** → 61% is the repo model at its design defaults. In your built-B copy, the one that drives the path, he holds 70–72% at t = 0 and about 75% along the path. Real boards: 15%. So the wake carries about 74% of the paper raise, on a unit that holds 15% of the real board. Source: runs of `hm.py`.
2. **"The bot never holds food" / "policy gap"** → The policy exists. `bot_hedgerow.gd`:43–44 `holds()`, 97–105 cashes only for Supper buys, 249–268 `feed()` plays every item on Dozey when his wake is due, and 545–547 keeps the held Larder out of the refresh budget. The median Larder of 0 from R10 is right. But p75 is 10 at R10, and 3 of the 14 Dozey seats hold 1–10 gold at R12 (`hedgerow-rounds.csv`). The evidence doesn't show why the Larder stays empty.
3. **"Treasurer ×1.00 because nothing is held"** → On paper the Supper holds 23–28 gold at R12. The Treasurer reads ×1.00 because `supper_script` buys him at R14 (R15 when late). In real lobbies he is on 5 of 25 boards, with 1.9% of stats. The conclusion stands; the reason was wrong.
4. **"Half as strongly → t_B 0.8, t_C 2.9"** → That doubles t. Halving the log response on the paper curve gives 0.70 and 2.69. The premise is weak anyway (item 1).
5. **"Between paper Supper and Parish → t_C ≈ 1.0–1.5"** → All 8 boards with two Mallows or a golden Mallow sit above the median (1,156–3,343). The median (727–849) sits among boards with 0–1 Mallow. I estimated each board on its own:
   - one-Mallow boards scale like paper-Supper Mallow-only (×1.24 / 1.71 / 2.88 at t = 1 / 2 / 3);
   - two-Mallow boards scale like the paper Parish;
   - Dozey's own stats scale by (M/2)^k, for 1–2 wakes.

   That gives **t_B ≈ 0.6–0.7 and t_C ≈ 2.1–2.7**.
6. **"If run 1 shows a weak response, try `committee_share`"** → Plan §2, A3.5 step 0 names extra dials *before* run 1. After run 1, a weak responder runs at its cap and is triaged: "Don't raise it further" (step 4). So name it now or not at all.
7. **Half steps** (×2.5, Treasurer 1.5, t ≈ 0.55–0.59) → The Supper is fine: about 1,040, 1.15× the target. But the Parish goes ×1.75, to about 1,900, which is 2.1× B's target.
8. **Minor:**
   - `dozey_period` is read at R:276; line 269 is the function header.
   - `PARAMETERS` doesn't carry every dial. Urchin's Bristle (T:124), the summons (T:131–137), the Larder (T:140) and Dozey's `eats_acorns` food (T:126, rounded up at runtime) are set outside it.
   - The B→C ratio is 1.87 in your copy against 1.77 in `six.json`: close, not equal.

**Checked and correct:**
- The four moved dials and their B/C values.
- A falls back to the base rates, which equal B (`pass3_rates.gd`:63–71).
- Every T, R and bot line cited, except the R:269 in item 8.
- The R12 medians: 730 from 25 of 32 seats, Parish 1,094.5, paper 979 (0.746×). The measured source `313501fa` has the same `src/`, `content/` and rates SHA as `424b3c2a`.
- Dozey on 14 of 25 boards with 15%; Mallow on 17 of 25, medians 1,156 against 461.
- Both paper tables, and the Parish at ×5.36 (about 5,860).
- `presets.md`:337 lists Mallow ×3 → ×2.5 as the first cut, and `_n` is at `pass3_text.gd`:112.
- The limits (multipliers above 1, Treasurer above 0, all four are floats).

**Corrected verdict: yes, plausible on today's dials, but C only just.**
- **B** is comfortable: t ≈ 0.4 on paper and 0.6–0.7 on the per-board estimate, against a cap of 2.
- **C** needs t ≈ 2.1–2.7 against a cap of 3, not 1.5. Mallow's multiplier carries it, not the wake.
- **The Parish** rides the same dial and will overshoot far at that t.

**Extra dials** (optional; name one before run 1 only if you want a margin on C). In the ranges below, the first figure is the paper Supper as written and the second is with the Supper cashing its Larder, as real seats do.
- **`committee_share`**: B 0.25, C 0.5.
  - Limit 1, by the plan's share rule. The text alone would stay true above 1: it prints "twice …" at 2, and the golden prints double, so the golden reaches "all" at 0.5. Clamps from t = 2.
  - It is a size axis but weak at R12: Supper ×1.07–1.12 at t = 1 and ×1.21–1.35 at the limit. Parish ×1.58, and ×2.81 at the limit.
- **Stronger alternative, `mallow_targets`**: B 2, C 3, rounded up (5 at t = 2, 7 at t = 3).
  - Limit 7, the board's slots; the golden doubles it.
  - Supper ×1.17–1.31 at t = 1, about twice the Committee's effect. But it is a count axis, and it lifts the Parish ×2.43.
- **No stronger size axis is left off the path.** Mallow's multiplier, the size axis, is already on it. The Supper-only dials (wake, period, food, Treasurer) act on Dozey or the Larder, which the median board barely has. Lollop is ×1.00 at R12 on paper, because he arrives at R12, and he is on only 6 of 25 boards.

Scripts are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/chk/`: `an.py` and `an2.py` read the captures, and `sweep.py` and `one.py` are the paper sweeps.