*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the bog critic.]*

## Bog folk, A3.5 step 0: checked against the repo

**Corrections**

1. **"No measured pass 3 Bog R12" → there is one.** The wave-1 rebase archives hold pass 3 Bog boards: Hard seats assigned to Bog, at R12.
   - B: median **393** [358, 438], n = 135.
   - C: median **866** [788, 999], n = 129.
   - Bog code, units, bots, line file and Bog rates are identical at `d5b5b4f8` and `424b3c2a` (the git diff is empty).
   - Source: `tools/sim/evidence/wave1-rebase-{B,C}.boards.json.gz`, filtered on `players.assigned_tribes`, `line == hard_field`, round 12.
2. **Realization 0.35 → measured 0.59 (B) and 0.72 (C).** Paper court in the measured lobbies is 664 at B and 1,198 at C (`dials.py` run on the measured all-seat curve), so 393/664 and 866/1,198. That is the top of wave 1's range, not its geometric mean.
3. **"Today's B lobby R12 about 394", and C 1,376 in `path.py` → neither was measured.** They are R8 × growth⁴ (97 × 1.42⁴ and 132.5 × 1.795⁴). Measured all-seat R12 is **339** at B and **968** at C; committed seats are 357 and 1,263. Source: `wave1-rebase-{B,C}.json`, `growth.all_seats.rounds.12`.
4. **"k barely moves the Swamp" → wrong.** k 2→5 moves the Swamp ×1.50, more than Ranocchio ½→1 (×1.27). Source: `dials.py`.
5. **Ranocchio "moves R12" → not the target line.** It moves the court ×1.00. The target is the engine line: `bog_court` has kind `engine_carry` and `engine_flag: true`, while `bog_swamp` has kind `tempo` and `engine_flag: false`. Source: `tools/sim/lines/bog.json`.
6. **Frog "an integer dial" → it isn't.**
   - It is stored as 2.0 and read as a float (`pass3_bog_growth.gd:56`, floor(stats × (m−1))). The printer would print "multiply by 4.5", so rounding up is a choice made for the text.
   - Golden 4/6/8 follows the m+1 convention in `presets-model/cuts.py`. Rulebook 7.3.5 says golden doubles every number; if that means doubling the gain, golden would be 2m−1 = 5/9/13.
7. **Tiddy and frog were held with logged reasons, which the draft doesn't cite.**
   - Tiddy: a whole Toll makes the Diva 0.67–0.70 of the board.
   - Frog: "×3 adds jumps and concentration for less size than k."
   - Source: `tribe-agents.json`. Raising either needs a logged overrule citing 09a.
8. **Hopkin is missing.** The plan names it as a candidate, and the draft doesn't address it. It is fight-only and outside the pre-start count, so it has no effect on R12.
9. **The clamps bend the path.** Tiddy and Ranocchio clamp at t = ln 2 / ln 1.5 = 1.71, so a log fit from t = 0 and t = 1 overpredicts at t = 2–3.
10. **Minor:**
    - The Soak gain is queued at `pass3_bog_combat.gd:198`; line 117 is only the lookup.
    - `bot_bog.gd:88, 92, 95, 98, 132` also read these dials, so raising them changes how the Bog bots value cards.
    - At C t = 3 the break-even realization is 0.38, not 0.37.

**Confirmed as stated:**
- A = B for every Bog dial, and only Soak keep and its golden twin differ in C.
- All other read sites, card texts and printer outputs.
- `golden = 2k` is sourced (`bog-pass3.md:77`, `tribe-agents.json`).
- 988 / 1,272 / 1,430 / 1,859, the sensitivity table, and the path arithmetic: 643 (0.71×), 1,251 (0.69×), 1,015 (1.13×), 2,144 (1.19×).
- Quilboar H1's 119 and 121 (`h1.md:72, 87`) are pass 2 Bog: at `edfe1ed1` the Bog cards are pass 2 and there is no `pass3_bog.gd`.

**Corrected verdict: plausible on today's dials, yes.** This uses the measured realization.

| Case | Projected R12 | vs target |
|---|---|---|
| B field 900, t = 1 | 753 | 0.84× |
| B field 900, t = 2 | 1,088 | 1.21× |
| C field 1,800, t = 1 | 1,344 | 0.75× |
| C field 1,800, t = 2 | 1,964 | 1.09× |
| C field 1,800, t = 3 | 2,584 | 1.44× |
| Today's lobby, no growth, B t = 2 | 684 | 0.76× |
| Today's lobby, no growth, C t = 3 | 1,622 | 0.90× |

Caveats:
- These are Hard seats, not `bog_court`. In that run committed lines beat Hard seats (B 357 against 320), so the projections are probably low.
- Wave 1's lobby field had pass 2 Hunters and the older Oozes and Hedgerow.

With the measured realization, the proposed combined path would land at 1.9× at B (t = 2) and 2.45× at C (t = 3) if the field reaches target. C goes past the 2× top of the band.

**Corrected extra dials.** None are needed to reach the target. If the plan's step 0 wants a reserve on the path:

| Dial | B | C | Limit (card text) | Note |
|---|---|---|---|---|
| `bog_tiddy_share` | 0.5 | 0.75 | 1 ("split the Toll") | Court ×1.23 at 1; concentrates the board (09a). Overrules the logged hold. |
| `bog_golden_tiddy_share` | 1 | 1.5 | 2 ("twice the Toll") | 1.5 prints "150% of the Toll". |
| `bog_frog_multiplier` (optional, second) | 2 | 3 | > 1 | Path 5 at t = 2, 7 at t = 3. Court ×1.20 at ×3. |
| `bog_golden_frog_multiplier` | 3 | 4 (m+1) or 5 (2m−1) | > normal | Pick one golden convention and log it. |

**Drop:**
- **Ranocchio:** it doesn't touch the engine line.
- **Hopkin:** it has no effect on R12.

**Better size dial than Ranocchio:** `bog_bitter_share` has the most effect per step. ¼→⅓ moves the court ×1.25, an elasticity of about 0.78 against k's 0.63. Its limit is 1. It stays held because it also strengthens every Bitter card's answer (`tribe-agents.json`), and at t ≥ 2 its path values print as percentages.

Scripts:
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/verify/bogr12.py`
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/verify/boot.py`
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/verify/measured_field.py`