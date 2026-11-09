## Follow-up scope review: `ideation/wave2a` 5cd5cd71..e3711131

**Counts:** 12 keep, 0 cut, 0 simplify, 1 ask.

**Does it move the original problem?** It's neutral on board size and makes the measurements more trustworthy. The pin modes I compared here barely change board sizes.
- In 8 shipped-config games at the head, the lobby median grows ×1.38 a round from R8 to R14. That clears the ×1.3 growth bar.
- The R12 median board is 291 (only seats still alive are counted), still far under B's 900.

**Cut:** none.

**Ask:**
1. The Hunter splash conclusion goes too far. The fixes didn't change the splash (99/652 → 106/670), but that doesn't show "Hunters are strong at B" or "no valuation bug left".
   - Counted per card offered, the bots pick Bog (0.38) and Hunters (0.31) about three times as often as any other off-build tribe.
   - In the worker's own probe, Bog is the bigger splash (207 off-build buys against 106 for Hunters).
   - Nothing measured whether splashing helps a seat, so bot overvaluation and real strength remain untold apart.
   - My suggestion: log it as "two real bugs fixed; the two newest pass 3 tribes are picked about 3× per offer; cause not separated". Don't log "no bug left".

**Clear to merge into ideation/main once the merged-tree gate passes?** Yes. The ask is about what gets logged, not about the code. The worker's gate passed at a9b5ff3e (2,092 tests). e3711131 only adds docs on top of it.

---

### (1) The cut: fixed, and the test catches it
- One overridable check now decides whether a unit may be replaced (`BotBrain._can_replace`, `bot_brain.gd:434`). Every slot choice uses it:
  - the weakest slot;
  - the best replacement slot;
  - ordinary clear-slot and funding sales;
  - Carrier upgrade plans (`bot_carrier.gd:52`);
  - Bog's sale, through the weakest slot.
- Committed lines add their own `engine_pieces` to that check (`committed_line_brain.gd:60`).
- **The tests:** two new tests use a custom Hunters 1/1 with no text. They first assert that `BotPass3.keep_engine` does not protect it, so no other keeper covers it.
- **Negative controls**, run in a temp copy:

| Change | Result |
|---|---|
| None | 9/9 pass |
| Line override drops `_protected` | both new tests fail, and the engine is sold (slot 0 becomes empty) |
| Carrier check reverted to `keep_engine` | the Carrier test fails |

- **Side effect:** line seats now also skip native Bog and Hunter engines when picking their weakest slot. Ordinary Hard already did this.
- **Not covered:** four older sell routes don't use the check. They are Annis fodder (`bot_pass3.gd:470`), Bird flights, naive random sells and Rainbow cash-outs. They predate wave 2a and weren't touched by 04b95d32, so this is not a regression. The Annis route could still sell a Fairy line's piece if it isn't in `FAIRY_ENGINES`.

### (2) The narrowed pin: matches the call
- **The code** (`bot_eval.gd:172`): `round < 4 or board_count() < 3`.
  - Neutrals, completing a pair and poached offers stay allowed.
  - Tests cover R3, R4 and a sparse board after R4.
  - The empty-board fallback from 59dbbed3 is fully replaced.
- **Real-game probe:** shipped `full_game` at B, seeds 41–48. All 64 bot seats are pinned in every mode.

| Mode | Off-build share of tribal buys | R1–3 | R4+ | Neutral buys | Median R12 | Growth R8→R14 |
|---|---|---|---|---|---|---|
| Head (narrowed) | 13.3% (101 of 759) | 51% | 3.2% (19 of 599) | 172 | 291 | ×1.38 |
| 5cd5cd71 hard filter | 0.6% | 0% | 0.7% | 240 | 280 | ×1.41 |
| No pin | 58.2% | 51% | 59% | 34 | 308 | ×1.40 |

- R1–3 buys at the head are the same as with no pin, as the call intends.
- After R4, opponents buy on-build plus neutrals. The neutral pick rate per offer is 0.25, against 0.05 with no pin. The call allows this, but it changes what opponents field.
- Board sizes differ between modes by no more than the noise.

### (3) The Hunter splash: half supported (the ask)
- **Supported:**
  - The Glutton and Russet valuation bugs were real. Directed tests confirm them with before/after numbers, for example a Glutton with no Take source drops from 66.7 to 0.
  - Fixing them didn't reduce the splash.
- **Not supported:**
  - The worker's measure is Hunter buys over all buys, which hides the per-offer rates.
  - Per-offer pick rates with no pin (my probe):

| Tribe | Picks per offered card |
|---|---|
| Own tribe | 0.51 |
| Bog | 0.38 |
| Hunters | 0.31 |
| Fairies | 0.14 |
| Birds | 0.11 |
| Hedgerow | 0.10 |
| Oozes | 0.04 |

  - Seats that splashed Hunters most placed slightly better (3.4 against 3.9). Seats that splashed Bog most placed slightly worse. That's 8 games, so it's weak.
  - Nobody audited the other Hunter and Bog text values.
- **It matters less now:** the narrowed pin leaves splash only in the opening, where Hunters are 38% of off-build buys.

### (4) Birds: C equals paper C, B unchanged
- **C:** all 27 C `birds_*` values equal ideation/main 4eacc662 `presets.json` C, with no extras. The test fixture matches it too.
- **B:**
  - The resolved maps for A, B and the defaults are identical before and after the range.
  - B introduces no new keys.
  - The new optional effects (Chiffchaff growth, Swallow gold, Jay Acorns, Goose Eggs) apply only when a key is present, so never under B.
  - The frozen B test passes.
- **Visible under C:** Chiffchaff goes from +1/+1 to +4/+4, golden +8/+8, and its text follows.
- **One byte-level change:** `GameConfig.defaults()` now carries 4 null keys that only presets add. Config and capture dumps under B therefore change in bytes but not in behaviour. The fixture re-record covers this.

### (5) Anything new out of scope? Nothing that needs cutting.
- 49da56d6 changes the text of the existing compact tag on native Hunter tiles ("Sale growth", "Take growth", "Pelt", "Quarry", "Take twice"), and "Hunt" now names the Quarry reminder in the reader. A failing gate test prompted it. It adds no new element to the main screen.
- The rest are UI test fixes (archived lenders, Pelt portraits), the Acorn test fix, an upset-audit hash refresh, and the doc corrections. The preset A sentence now reads "A is a fallback only", which is true, and "step 5 of plan v3" is right.

### Verdicts

| Item | Verdict |
|---|---|
| `_can_replace` with the line override, plus 2 tests (8fd285a2) | keep |
| Narrowed pin and its tests (f3593975; 59dbbed3 replaced) | keep |
| Glutton valuation fix (5cafe42f) | keep |
| Russet valuation fix (5cafe42f) | keep |
| Splash conclusion in `wave2a-build.md` (daeae760) | **ask** |
| C Birds at paper C (6aac2e5c) | keep |
| Optional preset dials: rates plumbing, Bird text, Goose (e9c6285f) | keep |
| Acorn reward-sweep test (a9b5ff3e) | keep |
| Native Hunter tags (49da56d6, 6260727d) | keep |
| UI test fixes (4c12236b, 86bd0fab) | keep |
| Doc corrections (33118b69) | keep |
| Upset-audit refresh and evidence files | keep |

**Gaps:**
- The unchanged sell routes listed under (1).
- No test of whether splashing actually helps a seat. The owner's preferred form would be constructed boards: a splash buy against an on-build buy at R6–R10.
- After the merge, measure B/C on the head with the keystone-removed low rolls, as already logged.

### Files and housekeeping
All of these are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-hunters2/`:
- probe script: `pin_probe.gd`
- probe output: `pin_out.jsonl`
- analysis: `analyze_pin.py`
- negative-control logs: `gut_base.log`, `gut_no_line_override.log`, `gut_carrier_old.log`

All Godot runs held `/tmp/bramble-godot.lock` with the 3 GB cap, one process at a time, in a temp `git archive` copy of e3711131. That copy is deleted. I changed nothing in `/home/alex/code/Bramble-ideation-balance`. Its one modified file and one new file are the worker's re-record in progress: `tests/core/test_field_normal_regression.gd` and `docs/ideation/evidence/wave2a/record-field-normal.gd.txt`.
