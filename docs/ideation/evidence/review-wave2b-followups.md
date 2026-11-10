*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov: `ideation/wave2b` `424b3c2a..8f94f607` (A1b and the A2 follow-ups). Calls: DECISIONS (ideation/main) "Wave 2b follow-ups (A1b, A2): review calls".]*

**Counts:** keep 13, cut 0, simplify 1, ask 4.

**Does it move the original problem?** A little. R12 medians, from my recompute of the committed rows: Pot Luck went from 200 to 272, but that is still only 0.30× of the 900 target. Hedgerow pooled went from 874 to 923. Hedgerow boards stay flat: the largest unit holds a median 0.27 share of the board at R12.

**Ask items:**
1. **Some changes alter normal Hard bots, not just the lines, and no test covers them.**
   - `BotHedgerow.holds` drops `active()` (`bot_hedgerow.gd:44`). It is called from `bot_brain.gd:274,364,632`, so every Hard `hedgerow_supper`/`hedgerow_treasury` seat now holds Larder before its first Hedgerow unit.
   - `prepare_play` now calls `_prepare_partner` (`:341`, `:686`), which can sell the weakest unit to free B1 for the Partner. This also hits normal Hard Supper and Treasury seats.
   - `move_ready` now uses an averaged median on even boards (`:90`).
   - `max_bodies` drops the split gap for `tempo()` (`bot_ooze.gd:389`), which includes Hard `oozes_second_helpings`.
   - The build log says "Ordinary Hard … keep their existing defaults". That is true only of the climb reserve.
   - Either gate these on line brains, or log them as a deliberate change to Hard.
2. **Pot Luck criterion 2 is not met.** Native median gold is 1/0 at R8/R10 against the paper's 4/5. Belly stats are 14.5/19.5 against the paper's reserves. The constructed boards are stand-ins, and they won 32/32 with 134/363 stats against 99/189, so stat margin alone explains the wins. The plan says A1b lands before A3. Do you accept criterion 1 alone?
3. **Dozey's fuel is still missing.** The R8 Larder median is still 2 against the paper's 16–17, and the Partner is on 8/32 boards (7/32 before). Your trigger for a Dozey triage ("Dozey seats grow slower") isn't met: ×1.700 with Dozey (n=9) against ×1.533 without (n=10), intervals overlapping. But the growth isn't coming from fuel. Triage it now, or carry it to A3.5?
4. **Nothing reads the 0/32 planted Supper result, and it shouldn't be read as a signal about the Supper's board shape.** Either rerun it against a spread of R8 boards or drop the claim (reasons below).

**Simplify:** `tools/checks/growth_intervals.py` recomputes the same-cohort medians that `tools/sim/wave2b_growth_report.py:147-197` already computes. Add the bootstrap to the existing reporter.

**Keep:**
- `line_engine_pieces` copied into the line's private strategy and checked first in `best_belly`, plus Granny and Pie added to the tempo line's pieces (A1b.3).
  - Moving the ENGINES check earlier doesn't change normal bots: `food_belly` already refuses Oozes (`bot_ooze.gd:174`).
- The tempo split-gap drop, for the line itself.
- The arms runner, endpoint rows, constructed Pot Luck tooling and the `_held_back` tweak.
- Keeping control, in line with your call: AB's ×1.304 doesn't beat control's ×1.335 or its R12 of 272.
- Raw A2 captures and CSVs out of git.
- The Hedgerow route fixes:
  - in the line brain: climb reserve, spending guard, refresh limits, Sergeant cash from the scout snapshot, `needs_board`;
  - the Partner opener fix;
  - the `hedgerow.json` rule text;
  - the `BotBrain` hooks (default true, one override).
- The golden Burdock tests, the Supper recipe and its one-wake test, the rerun evidence.
- Both merge resolutions:
  - 2a4b73bb keeps both sides (BotAim with Hedgerow's aim, the checker union, the engine.md union).
  - 5418f5aa puts Larder in the hand counter ("160g · 4/10", only when above 0, hover text), since main removed the title. It adds no labels.

**Does Pot Luck meet A1b?**
- **Criterion 1 is met on the point estimate.** Same cohort ×1.335 (93→527, n=12). The interval [1.243, 1.413] dips under 1.3. Other reads hold: changing survivors ×1.359, R8–R12 ×1.334 on n=23.
- Nothing isolates why control rose from ×1.222. The common fixes and the merge are mixed together.
- The arms refute the triage's saving idea: save-3 came in at ×1.261.
- **Criterion 2 is not met** (ask 2).

**Why the planted Supper 0/32 is mostly an artefact of the plant:**
- **One opponent:** a single board from seed 282013, seat 1, R8, selected as the median of 192. All 32 fights are replays of that one matchup.
- **Not what the line builds:** the plant is the old paper R8 board at 105 stats, with Dozey holding 0.50 of them. Native Supper seats field a median 138 at R8 with a 0.29 largest share (n=32).
- **The 100 understates the opponent:** it is a Fairy Ring board. Will-o'-the-Wisp summons Wisps into empty Rings at the start of combat, which the 100 doesn't count. Ballooning Spider attacks the back row, where Dozey sits.
- **The one real signal concerns the paper's shape, not the line:** half the stats asleep in the back row behind 36 front-row stats loses at equal stats. Native Supper seats are alive at R12 on 27/32.

**Other checks:**
- **Large files:** none landed. The largest addition is the 1.4 MB compact `a2-followup/hedgerow-lines.jsonl`, the same format as A2's. The 5.9 MB capture is gone from the tip but remains in history.
- **No content changes:** no content file changed, so no rates, card stats, offers or prices moved. DECISIONS is identical to c6e554af.
- **The 431/431 test run** happened before the final opener and median edits. Only the 30-test bot rerun covers those, so `test_bot_brain` and the field regression test didn't run on the final code.

**Probes** (`python3 -I` on copies of the committed rows in the orchestrator's scratchpad):
- Every figure reproduces exactly from the committed compact rows:
  - Pot Luck control ×1.335, save-3 ×1.261, Dollop ×1.271, both ×1.304;
  - R12 272 / 222.5 / 230.5 / 239;
  - Supper ×1.576 (n=19), Parish ×1.663 (n=19);
  - pooled R12 923 (n=51);
  - Dozey 1.700 / 1.533.
- Supper R8 Larder median 2; Pot Luck control R8 gold 1, Belly 14.5.
- Old A2 rows: Supper R12 730, Parish 1094.5.
