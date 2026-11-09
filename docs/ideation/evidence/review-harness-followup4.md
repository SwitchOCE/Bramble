# Harness follow-up review 4: cd07673..109d404 (scope reviewer, 10 Nov 2026)

## Harness follow-up 4: `cd07673..109d404` on `ideation/harness`

**Counts:** 15 items: 9 keep, 1 cut, 1 simplify, 4 ask.

**Does it move the original problem (09a, the scale is too low)?** It gives us the number that decides it, but nothing here changes the game's scale. On the old, pre-wave-1 pool the deciding number reads ×1.14 a round against the ×1.3 bar, so the old curve was flat by this measure.

**Merge:** not clear yet. Fix the cut first. On a fast-forward: `109d404` is four linear commits on `cd07673`, so it would fast-forward from there. But ideation/main has moved on to `c7c2f37`, four docs-only commits past `cd07673` (the last adds `review-wave2a-pool-rules.md`). No files overlap and `git merge-tree` is clean, so a normal merge works. A fast-forward doesn't. Also, `ideation/harness` now points at `fa95a41`, past `109d404`. I didn't read past `109d404`.

**Cut and ask items, one line each:**
- **Cut. The Whistlers setup isn't the pass 3 one.** The doc's R12 test swaps the Tern for the Whistlers on line A's board and keeps the Nest and the away Birds (six different Birds, no omen). The doc wants the harness to check this one: "If the harness shows the same 42% → 96%, the Whistlers' dial goes to ⅓." The doc's omen is the R15 board with everyone home. The worker's R12 omen instead swaps out the second Jay and drops the away Birds and the Nest, so the Lump is 5/8 instead of 85/104. It also drops the tribe bonus and puts the Whistlers at 7/9, not the model's 10/12. That gives a 375 board against 615. Rebuild it as the doc's R12 Tern swap, and add the R15 omen once an R15 board exists. Relabel or drop its three smoke rows.
- **Ask. The tempo line's results get filed under Homecoming.** After the R7 switch, `build_name()` returns `line_birds_homecoming` (`line_policies.gd:170`, `line_brain.gd:21-23`). The bench writes that final name as `strategy` (`bench.gd:338`), and `placement_ranking` groups by `strategy` (`metrics.py:362`). So Tempo games that reach R7 count as Homecoming. Keep the starting line as the label, or record both, before step 5.
- **Ask. The pre-wave-1 labels leave sets out.** HARNESS.md names the five sets in the call, but these were also measured before wave 1 and carry no label: the line head-to-head and confirmation runs (`line-fast-*`, `line-mixture-*`, `frozen-mixture-blind`, `best-hedgerow-blind`), `current-pool-strength-result`, the upset diagnostic, the designed analogue and boundary sets, the (d) reading of 1.188, and the damage-replay smoke. Simplest fix: state it as a rule. Every result above "Wave-1 line files", and every evidence file not named `wave1-*`, is pre-wave-1.
- **Ask. Wave 2's line files will crash the loader.** It accepts only the four wave 1 line names and the tribes Birds and Fairies (`line_policies.gd:71-73`), and only replaces the committed Birds and Fairies profiles (`:44`). Plan step 2 ships "each with its line JSON", so the first Bog or Hunters file stops every default bench and sweep. Either read the tribe and base strategy from the file now, or add this to the wave 2 briefs, as was done for the UpsetCombat audit.
- **Ask. Granny Pot Luck runs on today's Ooze text.**
  - Today's Granny has no Cleave, and today's Moss doesn't Shield the units that come out. The doc says of the two: "Both cards are the route".
  - The units inside are three 1/1 Mice, 6 stats in all. The doc's 924 total implies about 115.
  - The worker disclosed this. Regenerate the setup after W2b, with the inside units sized from the model, and label the Granny smoke rows as pass 2 Oozes.

**Your five questions:**
1. **Growth reader:** yes. It computes (median R14 / median R8)^(1/6) on pre-start boards, pooled across seats; late rounds hold survivors only. The interval is a percentile bootstrap that resamples whole seeds.
   - Three tests back it: a known-answer check through the capture path (×2 pre-start, ×3 post-start), a match against brute-force resampling, and the unsupported cases.
   - Recomputing gives 135/61 → 1.1416. The bounds are exactly 134/61 and 136/60. The medians are whole numbers, so the interval moves in steps, and a point near the lower end is expected.
   - "Pre-start" here is the board at combat start: Rings, Nests and auras applied, Start of Combat not yet. It isn't strictly the end-of-recruit board, but it matches what the shop shows.
2. **Labels:** only partly (see the ask).
3. **Loader:** it accepts all four wave 1 lines.
   - Bad files fail loudly: an assert, which sweeps catch as `SCRIPT ERROR` (`lever_sweep.py:536`).
   - But unknown keys and sub-keys pass silently. A misspelt `max_away` falls back to 7, and `from_round` isn't checked.
   - The tests cover 4 of the 7 rejection cases the worker claims (missing: duplicates, unknown base, `keep_home_min`).
4. **Faithful to the docs:**
   - **Birds:** yes. I ran a copy of the Birds model at R8 and R10. Every body and every away Bird matches, and the totals are 96, 240 and 615 with the Nest.
   - **Fairies:** yes. Ring size 1/4/6, 23/33/43 Rings, 33 on B1 at R12, matching the model.
   - **Granny:** outer bodies yes, inside units and text no.
   - **Whistlers:** no.
5. **New pass/fail bars:** none. The smoke, the line tests and the input validation are integrity checks only.

**What I ran:**
- Python suite on an exported copy of `109d404`: 134 pass. The first run errored on one test because I'd left `tests/core/data` out of the copy.
- Gate log: the hash matches its record (1,854 tests).
- Copies of the Birds and Fairies models, run in the scratchpad.
- No GUT run.

### Table
| # | Item | Verdict | Evidence / action |
|---|---|---|---|
| 1 | `checkpoint_growth` reader and its tests (`metrics.py:265`) | keep | Correct, per Q1 |
| 2 | `baseline-growth-pre-wave1.json` and its HARNESS section | keep | Labelled; reported only |
| 3 | Pre-wave-1 labels (HARNESS boundary, drivers README) | ask | Incomplete; see above |
| 4 | Loader, validation, aliases, historical opt-out (`line_policies.gd`) | keep | Note the silent unknown keys and untested cases |
| 5 | Line files included in the source fingerprint (`sweep_shards.py`) | keep | Tested |
| 6 | `bot_pass3.gd` reading the fly policy and the court flag | keep | Needed for the lines to play as written |
| 7 | `bot_pass3.gd:33` default `max_away` = 7 for every bot | simplify | Check it only when the policy sets it, so ordinary Hard can't change. Nothing in the rules caps how many Birds are away. |
| 8 | Tempo→Homecoming switch relabels the seat | ask | See above |
| 9 | Loader hardcoded to Birds and Fairies | ask | Wave 2 conflict |
| 10 | `real_designed_boards.gd`, `export_real_designed.gd` | keep | Built through the real PlayerState, not copied rules |
| 11 | Birds and Fairies R8/R10/R12 recipes | keep | Match the models |
| 12 | Granny Pot Luck recipe (`designed_setups.py:358`) | ask | Current text; inside units too small |
| 13 | Whistlers omen recipe (`designed_setups.py:381`) | cut | Not the doc's setup |
| 14 | 128-fight smoke, its driver and archives | keep | Descriptive; no bars |
| 15 | Verification record and gate log | keep | Hash checked |
