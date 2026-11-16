# Positioning sim: do the rows add depth?

**Status: for the owner's review, 2 November 2026 (revision 2).** This answers the owner's ask in [sources/2026-11-02-pre-development-design-pass.md](sources/2026-11-02-pre-development-design-pass.md):

> Make sure that our combat rules in terms of positioning actually add a little bit of extra depth compared to Battlegrounds. And if they're not working, we can just cut them.

The owner chose "a quick sim" and "both" kinds of evidence: sim evidence that smart placement beats random placement once position cards are in, plus prototype position cards to judge by feel.

- **Code:** `tools/research/power_budget.py`, section "rows study" (engine v1, cards, experiments). Run `python -I tools/research/power_budget.py --rows` for a smaller run that prints only (about a tenth of the work, wider error bars), or `--rows --full` for the sizes the committed tables were made with (16 minutes on all 24 cores, about 30 on the default half). Only `--rows --full` writes, and only `rows_*.csv` files. Don't extend this study: the owner judged it too brute-force, and future position questions use small hand-built puzzle boards instead ([owner note, 2 Nov](owner-notes/2026-11-02b-compute-and-rows-sim.md)). `--rows --quick` is a smoke test that prints and writes nothing. The default, `--quick` and `--no-sim` runs don't touch the rows study. With `--no-sim` they reproduce the committed v0 tables exactly.
- **Tests:** `python -I tools/research/test_power_budget_sim.py` (38 tests, all pass). `python -I -m unittest discover -s tools/research -p test_power_budget_sim.py` also works. `python -I -m unittest tools/research/test_power_budget_sim.py` can't work: `-I` keeps the repo root off the import path.
- **Tables:** [docs/research/battlegrounds/analysis/](../research/battlegrounds/analysis/), files starting `rows_`. Each number below names its CSV.

Claims are marked **[data]** (from a sim run or a cited file) or **[judgement]**. **SP** is one stat point (power-budget.md section 1). **pp** is a percentage point of win rate.

**What changed in revision 2:** a Battlegrounds-style one-row baseline on the same boards; a fairer rule of thumb for part-full boards; a textless-body control; three new prototypes (a Taunt and Divine Shield front, Recruit Phase position text, "across from"); cards measured on small early boards; the revision 1 reprices measured; a common opponent field; and decision criteria set before the run. Revision 1's findings 3, 4 and 5 and its reprice claim are replaced below.

---

## 1. The answer

**Keep the rows. The depth they add comes from position cards, so the content has to carry it.**

1. **The rows double to triple placement value over one row [data].** On matched boards, the best policy beats random placement by 1.6 SP with plain units on the rows board, against 0.8 SP on one row. With two position cards it is 4.9 SP against 1.9 SP. On 5-unit boards it is 5.5 against 1.7 ([rows_vs_line.csv](../research/battlegrounds/analysis/rows_vs_line.csv)). This passes the keep test set before the run (section 2).
2. **With plain units, the rows are one rule [data].** "Hitters in front, biggest first" finds all of the full-board value: the search doesn't beat it (−0.0 SP). On 5-unit boards the search finds 0.2 SP more.
3. **Position cards add a real decision on top of the rule [data].** With two position cards, the search beats a fair written rule by 0.9 SP at T3, both on full boards and with 5 units. With three, by 1.3 SP. On one row with the same cards it is 0.5 SP. So the rows add about 0.35 SP of thinking that a simple rule doesn't find, on top of a much larger obvious part. **[judgement]** That is "a little bit of extra depth", which is what the owner asked for. It isn't a lot.
4. **The depth comes from the text, not the bodies or the gaps [data].** With the text stripped off the same cards, placement is worth what it is with plain units (1.35 SP, 0.2 SP above the rule). At matched density, gaps add nothing: 2 position cards in 5 units (40%) leave 0.87 SP, and 3 in 7 (43%) leave 1.26 SP. Revision 1's "gaps give more depth" was mostly card density and a weak rule.
5. **Most of it is one obvious answer per card [data].** A fair rule of thumb captures 79–86% of placement value with position cards. Several layouts are close behind the best: on about half the boards, the search's three end points can't be told apart on 2,000 fights.
6. **No fortress [data].** No searched layout, in any cell, used a single front unit. That includes 48 five-unit boards with the new Taunt and Divine Shield prototype. Played as a fortress on 4-unit boards, that card measures 4.4–5.0 SP against a budget of 8.
7. **Prices [data]:** 6 of 11 position prototypes are within ±15% at their best slot on a full board. Several cards shift outside it on the early boards where they are actually bought: Lone Stag +21% at 3–4 units, Lantern Moth +17–24%, Drummer Hare −15 to −22%. Revision 1's reprices, measured: Moth 1/2 +5%, Vole 2/2 0%, Fern Hare 3/2 +12%, Hedgehog 2/2 still +18%. Section 5.

---

## 2. Decision criteria (set before the revision 2 run)

These were written after reading revision 1 and the review, before the revision 2 numbers existed. "Value" is win-rate gain in SP with the cell's own slope.

| Outcome | Test |
|---|---|
| **Cut** | Rows add less than 0.5 SP of placement value (best policy − random) over the one-row baseline, on plain **and** position boards, full and 5-unit. |
| **Keep, but the rows are only a layout rule** | Rows add ≥ 0.5 SP over one row, but on position boards the search beats a fair rule by less than 0.5 SP. Placement would be real but solved by one rule. Then simplify the board or lean harder on content. |
| **Keep** | Rows add ≥ 0.5 SP over one row, **and** the search beats a fair rule by ≥ 0.5 SP on position boards. |

**Result [data]:** rows add 0.7–0.8 SP over one row with plain units and 3.0–3.9 SP with position cards. The search beats the fair rule by 0.87–1.06 SP on position boards at T3, and 1.2–1.5 SP at T5. **Keep.** The margin on the second test is modest: 0.4–0.6 SP above the bar.

---

## 3. Method

### 3.1 The engine (v1)

A small engine in `power_budget.py` (`Fight`). The v0 engine (`combat`) is unchanged. On 6,000 vanilla 6-vs-7 boards at T3 the two agree: rows 29.4% (v0) against 29.9% (v1), difference 0.6 ± 0.4 pp; one row 30.3% against 30.5% **[data, [rows_engine_check.csv](../research/battlegrounds/analysis/rows_engine_check.csv)]**.

It follows the rulebook:

| Rule | Rulebook | Test |
|---|---|---|
| More units attacks first; else a coin flip | 9.2.1 | `test_more_units_attacks_first` |
| Start of Combat: random side first, reading order; its deaths resolve before the next effect | 9.3.2, 9.3.5 | `test_start_of_combat_side_is_random_and_deaths_resolve_between` |
| Attack order F1–F4 then B1–B3; pointer and flags | 9.4.2, 9.4.5 | `test_front_left_to_right_then_back` |
| A summon into the attacker's slot attacks next; one below the pointer waits | 9.4.8 | `test_summon_into_attackers_slot_attacks_next` (the rulebook's example, run through `attack()`), `test_summon_below_pointer_waits` |
| 0-Attack units skipped; stall and the 200-attack limit are ties | 9.4.6, 9.9, 9.10.1 | `test_zero_attack_units_skipped_and_stall_is_a_tie` |
| Back row can't be attacked while any front unit lives | 9.5.1 | two targeting tests |
| Taunt works within the attackable row | 9.5.4 | three Taunt tests |
| Random effects ignore rows and Taunt | 9.5.6 | `test_random_effects_ignore_rows_and_taunt` |
| "Whenever this attacks" before damage; no damage if either side is gone | 9.6.1 | `test_drummer_hare_...`, `test_spotter_rook_...`, `test_ping_that_kills_the_defender_cancels_the_attack` |
| Deaths checked after each damage event (each ping) | 9.6.3 | `test_deaths_checked_after_each_ping` (fixed in revision 2) |
| Dying units leave their slots first; "when dies", Deathrattles, "after dies", Reborn; repeat | 9.7.1–9.7.2 | `test_when_front_dies_trigger_and_after_death_summon`, `test_martyr_hedgehog_deathrattle_buffs_units_behind` |
| Active side's deaths first | 9.7.3 | `test_active_side_deaths_resolve_first` |
| Death summons: own slot first, then nearest empty (table 8.4.2); a full board loses them | 8.4.1–8.4.5 | `test_nearest_empty_slot_table` and three placement tests |
| A named-slot summon fails if the slot is full | 8.4.6 | `test_named_slot_summon_fails_if_slot_is_full` |
| Reborn: 1 Health, own slot, else nearest | 9.8.2–9.8.3 | two Reborn tests |
| Across from: same slot label | 8.2.6 | the Start of Combat side test |

Not modelled: Windfury, Stealth, Venomous, Cleave, Avenge, hero powers, spells, moving. Nest Robin's End of Turn buffs are applied before combat as if it had been held two turns in the same slot (section 4.1).

### 3.2 The one-row baseline (Battlegrounds stand-in)

The same engine with `mode="line"`: one row of 7, every enemy unit can be attacked, attack order left to right. "In front of" and "behind" both become "adjacent" (left and right), like Dire Wolf-style Battlegrounds text. Summons go to the nearest empty slot, and a tie goes right. Boards are packed (n units in slots 1..n), as in Battlegrounds. The same boards, opponents, search and seeds are used as on the rows board. Tests: `OneRowBaseline`.

**[judgement]** It is a stand-in, not Battlegrounds. Battlegrounds slides units together after deaths; this baseline doesn't. Lone Stag and Shellback Tortoise can't trigger on a packed row, and Acorn Slinger hits the same position number. Those make the one-row side slightly weaker with position cards.

### 3.3 Boards

- **Plain units** are attack/health pairs from Battlegrounds' current pool at Tier 3 (main band) or Tier 5 (check band), as in v0. Their bodies are a bit below V(t) because the real cards carry text.
- **Matched boards.** Each board draws 7 plain units, 3 position cards (from 11) and 2 summon cards once. Each condition then swaps cards in for the first plain units:
  - **plain:** plain units only;
  - **summons:** 2 summon cards + plain;
  - **position:** 2 position cards + plain;
  - **position+summons:** 2 position + 1 summon + plain;
  - **position-body:** the same 2 position cards with their text and keywords removed (the control);
  - **position3:** 3 position cards + plain (density check: 43% of a full board, against 40% for 2 in 5).
- **Sizes:** 7 units (full board) and 5 units in 7 slots (gaps allowed on the rows board, packed on one row).
- **Bands:** T3 (main). T5 uses golden prototypes (2× body and effect, counts unchanged) as stand-ins for later cards.
- **Opponents:** boards built the same way, same condition and size. Half are placed by the fair rule of thumb, half at random. There are 160 training opponents, 500 separate test opponents, 2,000 for re-scoring the search's end points, and a **common rule field**: 400 boards with mixed conditions, all placed by the rule. Win rates against the common field can be compared across conditions; win rates against each cell's own pool can't.
- 150 boards per cell, 23 cells. Every layout of a board meets the same opponents with the same dice.

### 3.4 Placement policies

| Policy | What it does |
|---|---|
| **Random** | Units in random slots (gaps anywhere on 5-unit rows boards). The mean of 10 random layouts. |
| **Naive** (5 units, rows) | Front first in reading order, units in random order: a player who ignores the rows. |
| **Rule v1, "front first"** (revision 1's rule) | Back-row cards in B2, B1, B3. Front position cards in F2, F3, F1, F4. Lone Stag in F1 with B1 empty. Other units fill the front first, highest Attack first. |
| **Rule v2, "at most 3 in front"** (the fair rule) | As v1, but on boards of 6 units or fewer, at most 3 units go in front. The rest go in the back, first behind your front position cards. Identical to v1 on full boards. |
| **One-row rule** | Attack-triggered cards (Hare, Rook) in slots 2–4. Other position cards in the late middle (slots n−1, n−2, n−3). Other units left to right, highest Attack first. |
| **Search** | Steepest-ascent hill climb over swaps and moves of any two slots, from three starts (rows: rule v2, rule v1 and one random layout; one row: the rule and two random layouts), scored on the 160 training opponents. The best end is measured on the 500 test opponents. |

**[judgement]** All three rules were written after looking at where the search put units. They are what a player who has played a few games would do. The search is a noisy local search on a finite sample, not an optimum. On full rows boards its training score is 1.2–4.4 pp above its test score (7 pp at T5), and on plain boards the rule ties or beats it on 40–47% of boards ([rows_placement_summary.csv](../research/battlegrounds/analysis/rows_placement_summary.csv)).

### 3.5 Measures

- **Placement value:** best policy minus random, on test opponents, in SP using the cell's own slope (the gain from +1/+1 on a random unit).
- **Leftover decision:** search minus the fair rule. Near zero means one written rule finds the answer.
- **How much layout matters:** the true standard deviation of win rate across random layouts, after noise (covariance between two independent halves of the training pool).
- **Board variety:** whether the three climbs end on the same layout, and whether their ends differ by more than 2 standard errors when re-scored on 2,000 opponents.
- **Card prices:** each card against a vanilla unit of its tier (V(t), 45% Attack) and against its own textless body, in the same slot on the same board. Full boards: 1,500 paired fights per slot. 6-unit boards: 750 per (slot, gap). Small boards of 3 and 4 units at the card's own tier: 800 per slot, with the other units placed either by the rule or to suit the card.

### 3.6 What the review asked for, and what I did

All seven must-fix items are done. The `golden` name clash is fixed. The rows study runs only under `--rows`. There is now a one-row baseline and a fair rule. The reprices are measured. Board variety is re-scored with a significance test. Cross-cell comparisons now use the common field. Should-fix items done: the body control; text value measured against each card's own body; small-board cells; finding 4 reworded; the density cell; the all-rule field; criteria set before the run; tests for the listed rules; the 9.6.3 ping fix; a tolerance band per card; position cards' own share of placement value; 3 broader prototypes; player-experience gaps; the minor code fixes; the engine check saved.

**Declined, with reasons:**
- **Moving or swapping effects, scam units, deep-board tribes.** The sim has no Recruit Phase and no tribes, so these can't be measured yet. Nest Robin is the only Recruit Phase card, and it is approximated.
- **Re-pricing after the measurements.** I report measured numbers and suggest next prices as [judgement], but didn't run a second pricing round. Each round moves the bar; the owner should first say which slot and which turns to price at (questions 4 and 5).

---

## 4. Results

### 4.1 Rows against one row [data]

Source: [rows_vs_line.csv](../research/battlegrounds/analysis/rows_vs_line.csv), [rows_placement_summary.csv](../research/battlegrounds/analysis/rows_placement_summary.csv). T3, matched boards. "Best" is the better of search and rule, per cell.

| Condition | Units | Rows: best − random | One row: best − random | Rows add | Rows: search − rule | One row: search − rule | Layout spread (sd, pp), rows / one row |
|---|---|---|---|---|---|---|---|
| plain | 7 | 1.6 SP | 0.8 SP | **+0.8** | 0.0 | −0.3 | 3.1 / 1.6 |
| summons | 7 | 2.3 | 1.2 | +1.1 | 0.5 | −0.2 | 5.0 / 2.8 |
| position | 7 | 4.9 | 1.9 | **+3.0** | 0.9 | 0.6 | 9.7 / 4.5 |
| position+summons | 7 | 5.2 | 2.1 | +3.1 | 1.1 | 0.5 | 10.8 / 5.2 |
| plain | 5 | 1.4 | 0.6 | +0.7 | 0.2 | −0.2 | 3.8 / 1.1 |
| summons | 5 | 1.9 | 0.9 | +1.0 | 0.7 | 0.1 | 6.4 / 4.0 |
| position | 5 | 5.5 | 1.7 | **+3.8** | 0.9 | 0.5 | 10.5 / 5.5 |
| position+summons | 5 | 5.6 | 1.8 | +3.9 | 1.1 | 0.5 | 11.9 / 6.2 |

- **Placement matters 2–3× as much on the rows board.** Mostly that is the obvious part: hitters in front, support behind.
- **The non-obvious part is a little larger on rows:** 0.9–1.1 SP against 0.5 with position cards. With plain units neither board has any; on one row the rule beats the search.
- One SP is worth the same win rate on both boards (4.0–5.8 pp per SP), so the SP columns compare directly.

### 4.2 The rows board: placement tables [data]

Source: [rows_placement_summary.csv](../research/battlegrounds/analysis/rows_placement_summary.csv). Win rates in %, against each cell's own pool. "±" is one standard error across boards.

**T3, full boards (7 units).** Rule v1 and v2 are the same here.

| Condition | Random | Rule | Search | Search − random | Rule's share | Search − rule | pp per SP | Layout sd (pp) |
|---|---|---|---|---|---|---|---|---|
| plain | 49.1 | 55.8 | 55.7 | 6.6 ±0.3 pp (1.6 SP) | 100% | −0.1 ±0.2 (0.0 SP) | 4.1 | 3.1 |
| summons | 48.1 | 56.3 | 58.7 | 10.6 ±0.4 (2.3) | 77% | 2.4 ±0.3 (0.5) | 4.7 | 5.0 |
| position | 44.8 | 61.7 | 65.4 | 20.5 ±0.8 (4.9) | 82% | 3.7 ±0.4 (0.9) | 4.2 | 9.7 |
| position+summons | 43.6 | 62.0 | 66.7 | 23.1 ±0.8 (5.2) | 79% | 4.7 ±0.4 (1.1) | 4.5 | 10.8 |
| position-body (control) | 49.3 | 54.6 | 55.6 | 6.3 ±0.3 (1.35) | 84% | 1.0 ±0.2 (0.2) | 4.6 | 2.9 |
| position3 | 41.7 | 62.4 | 67.7 | 26.0 ±0.8 (6.1) | 79% | 5.4 ±0.4 (1.3) | 4.3 | 10.9 |

**T3, 5 units in 7 slots**

| Condition | Random | Naive | Rule v1 | Rule v2 | Search | Search − random | Rule v2's share | Search − rule v2 | Search − rule v1 | Layout sd |
|---|---|---|---|---|---|---|---|---|---|---|
| plain | 46.5 | 46.6 | 50.4 | 51.8 | 52.9 | 6.4 ±0.3 (1.4 SP) | 83% | 1.1 ±0.2 (0.2 SP) | 2.5 | 3.8 |
| summons | 47.7 | 48.2 | 53.9 | 54.6 | 58.5 | 10.8 ±0.4 (1.9) | 64% | 3.9 ±0.4 (0.7) | 4.6 | 6.4 |
| position | 39.9 | 39.5 | 59.7 | 63.3 | 67.6 | 27.8 ±0.8 (5.5) | 84% | 4.3 ±0.5 (0.9) | 8.0 | 10.5 |
| position+summons | 38.7 | 38.3 | 60.4 | 63.2 | 68.8 | 30.1 ±0.8 (5.6) | 81% | 5.7 ±0.5 (1.1) | 8.4 | 11.9 |
| position-body | 48.7 | 48.6 | 52.8 | 53.3 | 54.6 | 5.9 ±0.3 (1.0) | 79% | 1.3 ±0.2 (0.2) | 1.9 | 3.4 |

**T5 band, golden prototypes, full boards**

| Condition | Random | Rule | Search | Search − random | Rule's share | Search − rule | pp per SP |
|---|---|---|---|---|---|---|---|
| plain | 47.0 | 53.1 | 53.5 | 6.6 ±0.3 (2.2 SP) | 93% | 0.5 ±0.2 (0.2 SP) | 3.0 |
| summons | 42.2 | 53.0 | 53.7 | 11.5 ±0.4 (3.3) | 94% | 0.7 ±0.2 (0.2) | 3.5 |
| position | 37.2 | 57.2 | 60.4 | 23.2 ±0.9 (8.8) | 86% | 3.2 ±0.3 (1.2) | 2.6 |
| position+summons | 38.8 | 60.4 | 64.6 | 25.7 ±0.9 (9.3) | 84% | 4.2 ±0.3 (1.5) | 2.8 |

What the tables say:

- **v0's "placement is almost not a decision" tested the wrong rule.** Tank-front (highest Health in front) gives +0.3 pp ([sim_placement.csv](../research/battlegrounds/analysis/sim_placement.csv)); Attack-first gives +6.6 pp.
- **Position cards' own share of placement value is 3.3–3.6 SP on full boards.** That is 4.9 SP minus 1.6 SP (plain) or minus 1.35 SP (same bodies without text). Revision 1's "about 5 SP" included the plain part.
- **The text makes the decision, not the bodies.** The body control behaves like plain units: sd 2.9 pp, 0.2 SP left over.
- **The fair rule closes most of revision 1's 5-unit gap.** Search minus rule on 5-unit position boards falls from 8.0 pp (rule v1) to 4.3 pp (rule v2), or 0.9 SP. That is the same as on full boards. Gaps don't add depth by themselves.
- **Depth grows with position-card density:** 0.9 SP with 2 per board, 1.3 SP with 3.
- **The pattern holds at T5,** with a larger leftover (1.2–1.5 SP).

### 4.3 One obvious answer, or real choices? [data]

Source: [rows_placement_summary.csv](../research/battlegrounds/analysis/rows_placement_summary.csv), [rows_placement_boards.csv](../research/battlegrounds/analysis/rows_placement_boards.csv).

| Cell (rows) | Rule ties or beats search | Search beats rule by > 5 pp | Climbs end on the same layout | Same front-row set | Mean largest gap between ends, 2,000 fights (pp) | Ends differ by > 2 SE |
|---|---|---|---|---|---|---|
| T3 7 plain | 47% | 1% | 25% | 40% | 1.5 | 36% |
| T3 7 summons | 29% | 22% | 20% | 47% | 1.4 | 37% |
| T3 7 position | 20% | 29% | 27% | 53% | 1.9 | 45% |
| T3 7 position+summons | 15% | 37% | 22% | 53% | 2.0 | 45% |
| T3 7 position3 | 17% | 45% | 26% | 61% | 1.9 | 46% |
| T3 5 plain | 40% | 5% | 5% | 32% | 1.2 | 42% |
| T3 5 position | 19% | 33% | 19% | 51% | 2.3 | 54% |
| T3 5 position+summons | 18% | 43% | 19% | 59% | 2.5 | 47% |

- **With plain units, the rule is the answer.** It ties or beats the search on 40–47% of boards; the rest is search noise and small gains.
- **With position cards, the search beats the rule by more than 5 pp on 29–45% of boards.** On those boards the rule misses something specific to the board.
- **Several near-equal layouts.** The climbs usually end on different layouts. Re-scored on 2,000 opponents, the ends are within 2 pp of each other on average, and on about half the boards they can't be told apart. **[judgement]** A player who gets the obvious part right is within about 0.5 SP of the best layout found. Reading the single-board numbers needs care: one board's search-minus-rule carries a few pp of noise.

### 4.4 Board shape and the fortress [data]

On 5-unit boards, how many front units the searched layout uses:

| 5-unit condition | 2 front | 3 front | 4 front |
|---|---|---|---|
| plain | 51% | 35% | 14% |
| summons | 22% | 58% | 20% |
| position | 23% | 67% | 10% |
| position+summons | 18% | 69% | 13% |
| position-body | 31% | 45% | 24% |

- **The 2–3 front shape comes from back-row protection, not from position text.** Plain boards use even fewer front units (51% use two). Revision 1 credited "behind" effects for the shape, which was wrong.
- **No searched layout in any of the 2,250 rows boards used one front unit.** On the 48 five-unit boards that held Shellback Tortoise, the search used 2–4 front units every time.
- **The fortress card is weak on the boards it was made for.** Tortoise alone in front with 3 units behind, on 4-unit T3 boards: 4.4–5.0 SP against V(3) = 8 ([rows_card_slots.csv](../research/battlegrounds/analysis/rows_card_slots.csv), layout "fit"). A 1/3 Taunt with Divine Shield holds one hit, and then the back row is open.

**Where each prototype ends up** (T3 position, search, [rows_position_card_slots.csv](../research/battlegrounds/analysis/rows_position_card_slots.csv)):

| Card | Full board | 5 units | Reading |
|---|---|---|---|
| Drummer Hare | F2 83% | F2 90% | One answer: attacks early, two behind. |
| Acorn Slinger | B2 89% | B2 86% | One answer in practice: a safe body (the target is random from the player's side). |
| Spotter Rook | B1 74% | B2 57%, B1 39% | Fixed on full boards, board-dependent with gaps. |
| Sapling Keeper | B3 80% | B3 59% | Mostly fixed. |
| Vigil Vole | B3 78% | B1 42%, B2 33%, B3 24% | Fixed on full boards, open with gaps. |
| Hearthguard Badger | F2 57%, F3 39% | F2 68% | Front, small choice. |
| Martyr Hedgehog | F3 62%, F2 38% | F2 55%, F3 42% | Front, small choice. |
| Lantern Moth | B3 55%, B2 30% | B2 59% | Board-dependent: behind the best hitters. |
| Nest Robin | B1 58%, B2 42% | B2 64% | Board-dependent. |
| Lone Stag | spread, back 75% | F1 56%, F4 33% | Placed as a plain body on full boards; its gap works with 5. |
| Shellback Tortoise | B1 42%, spread | spread, back 70% | Hidden in the back: its Taunt helps little and its body is weak. |

### 4.5 Against a common rule-placed field [data]

The same final layouts, re-tested against one field per board size: 400 boards of mixed conditions, all placed by the rule ([rows_placement_summary.csv](../research/battlegrounds/analysis/rows_placement_summary.csv), columns `field_*`). T3, full boards, win rate in %:

| Condition | Random | Rule | Search | Search − random | Search − rule |
|---|---|---|---|---|---|
| plain | 39.0 | 46.2 | 46.6 | 7.6 | 0.3 |
| summons | 54.6 | 61.6 | 64.1 | 9.5 | 2.5 |
| position | 31.8 | 48.9 | 53.8 | 22.1 | 4.9 |
| position+summons | 39.1 | 58.0 | 64.0 | 24.9 | 6.0 |
| position-body | 20.4 | 24.5 | 26.2 | 5.8 | 1.7 |
| position3 | 27.8 | 49.0 | 56.3 | 28.5 | 7.3 |

- The gains hold against a smarter field. Search minus rule is slightly larger here (4.9–6.0 pp with position cards).
- Because the field is shared, rows can be compared. **Misplaced position cards are worse than plain units:** 31.8% against 39.0% at random. Placed by the rule they are slightly better (48.9 against 46.2), and placed well, clearly better (53.8). **The position cards' bodies alone are very weak** (20.4–26.2%): the text carries their value.

---

## 5. The prototype position cards

Placeholder names, no art. Bodies were priced with power-budget.md v0 before the run, and the run measured them. The last three are new in revision 2.

### 5.1 The cards

**Lantern Moth** — Tier 1, back row. 1/3.
*"The units in front of this have +1 Attack."*
A moth that lights the way. Put it behind your two best hitters. A small, steady aura. In the front row it does nothing.

**Drummer Hare** — Tier 2, front row. 2/2.
*"Whenever this attacks, give the units behind this +1/+1."*
Beats the drum as it charges. Wants F2: it attacks early and has two units behind it. Weak on early boards with nobody behind it.

**Martyr Hedgehog** — Tier 2, front row. 2/3.
*"Deathrattle: Give the units behind this +1/+1."*
Curls up and leaves its spines to the ones behind. Wants F2 or F3 with the back filled.

**Lone Stag** — Tier 2, front row. 2/1.
*"Start of Combat: If this is in the front row with no unit behind it, gain +3/+3."*
Stands alone at the forest edge. Put it in F1 or F4 and leave the slot behind it empty. Strong on the small boards where it is bought; a weak 2/1 once the board is full. *(Wording clarified in revision 2: in the back row it doesn't trigger.)*

**Hearthguard Badger** — Tier 3, front row. 3/3.
*"Start of Combat: Give the units behind this +2 Attack."*
Rallies the burrow before the fight. A one-off buff from the front to the back outlives the Badger.

**Vigil Vole** — Tier 3, back row. 2/3.
*"When a unit in front of this dies, gain +1/+1."*
Keeps watch and grows angrier with every loss. Put it behind the units that die first.

**Spotter Rook** — Tier 3, back row. 2/5.
*"Whenever a unit in front of this attacks, deal 1 damage to a random enemy."*
Calls targets from behind the line. The ping can hit either row (rulebook 9.5.6). Wants B1, behind the two units that attack most.

**Sapling Keeper** — Tier 4, back row. 1/3.
*"After a unit in front of this dies, summon a 2/2 Sapling into its slot. (Twice per combat.)"*
Plants a new guard where one falls. It refills the front, which keeps the back protected longer. The summon fails if the dead unit's own Deathrattle filled the slot (rulebook 8.4.6).

**Shellback Tortoise** — Tier 3, front row. 1/3. *New.*
*"Taunt. Divine Shield. Start of Combat: If this is your only front-row unit, gain +3 Health."*
A shell that hides the whole burrow. Built to test the fortress (rulebook 8.3.2): one tough front unit guarding a full back row. It doesn't work: see 4.4.

**Nest Robin** — Tier 2, back row. 1/2. *New: Recruit Phase position text.*
*"End of Turn: Give the units in front of this +1 Health permanently."*
Feeds the two in front of its nest every turn. The choice is made in the shop: which units sit in front of it at the end of each turn. *Sim approximation: the units in front of it have +2 Health, as if it had been held two turns in that slot (power-budget.md 3.2, H = 3).*

**Acorn Slinger** — Tier 2, back row. 2/2. *New: "across from" (8.2.6).*
*"Start of Combat: Deal 3 damage to the enemy unit across from this."*
Throws from the back at whoever stands opposite. It reaches the enemy back row (open question 11.5.3). With async opponents the player can't aim it, so in practice it is a random 3 damage that can't hit an empty slot.

**Summon cards** (to test the summon rules): Puffball Ooze, Tier 3, 2/3, *"Deathrattle: Summon two 1/1 Spores."* Fern Hare, Tier 3, 3/3, *Reborn.* Rot Toad, Tier 3, 3/2, *"Deathrattle: Deal 3 damage to a random enemy."*

### 5.2 Prices against measurement [data]

Source: [rows_card_summary.csv](../research/battlegrounds/analysis/rows_card_summary.csv), [rows_card_slots.csv](../research/battlegrounds/analysis/rows_card_slots.csv). "Measured" is V(t) plus the card's win-rate gain over a vanilla V(t) unit in the same slot, divided by the slope. One standard error is 0.12–0.22 SP. The best slot is picked from 7 (or from 14 slot-and-layout pairs on small boards), so it reads about one standard error high. **Text** is the card minus its own textless body in the same slot. **Band** is the owner's tolerance: ±15% for plain cards, ±25% for economy, scaling and engine cards. **[judgement]** Only Nest Robin (per-turn scaling) is in the 25% group. Vole, Hare and Keeper could be argued into it (question 4).

| Card | Tier, V(t) | Method price | Full: best slot | Full: error at best | Full: mean over slots | Small boards (3–4 units), best | Text measured / method | Band | Verdict at best slot |
|---|---|---|---|---|---|---|---|---|---|
| Lantern Moth 1/3 | 1, 5 | 4.95 | 5.7 (B3) | +14% | −6% | 5.9–6.2 (**+17–24%**) | 1.9 / 0.95 | 15 | over on its own turns |
| Drummer Hare 2/2 | 2, 7 | 6.6 | 7.0 (F2) | −1% | −26% | 5.5–5.9 (**−15–22%**) | 2.2 / 2.6 | 15 | fine late, weak early |
| Martyr Hedgehog 2/3 | 2, 7 | 7.5 | 8.5 (F3) | **+21%** | −10% | 7.8–8.0 (+11–15%) | 3.6 / 2.5 | 15 | over |
| Lone Stag 2/1 | 2, 7 | 7.2 | 4.5 | **−36%** | −40% | 8.4–8.6 (**+21–22%**); 6 units 9.1 (+31%) | 0 full, 4.7–5.0 small / 4.2 | 15 | over when bought |
| Hearthguard Badger 3/3 | 3, 8 | 8.0 | 8.4 (F2) | +5% | −15% | 7.7 (−3–4%) | 2.5 / 2.0 | 15 | in band |
| Vigil Vole 2/3 | 3, 8 | 7.7 | 9.4 (B3) | **+17%** | −20% | 9.4 (+18%) | 4.3 / 2.7 | 15 | over (in a 25% band) |
| Spotter Rook 2/5 | 3, 8 | 8.1 | 8.8 (B1) | +10% | −12% | 9.0–9.4 (+13–18%) | 1.9 / 1.1 | 15 | edge |
| Sapling Keeper 1/3 | 4, 10 | 10.25 | 9.5 (B3) | −5% | −43% | 10.0 (0%) | 5.1 / 6.25 | 15 | in band |
| Shellback Tortoise 1/3 | 3, 8 | 7.6 | 5.2 (B1) | **−36%** | −42% | 6.1–6.5 (−19–24%) | 1.1 / 3.6 | 15 | under |
| Nest Robin 1/2 | 2, 7 | 7.0 | 7.3 (B1) | +4% | −29% | 7.0–7.5 (−1 to +7%) | 3.8 / 4.0 | 25 | in band |
| Acorn Slinger 2/2 | 2, 7 | 6.4 | 8.1 (F2) | **+16%** | +9% | 6.5–7.0 (−7–0%) | 3.7 / 2.4 | 15 | over late |
| Puffball Ooze 2/3 | 3, 8 | 8.2 | 8.3 (B3) | +3% | −8% | 9.2 (+14–15%) | 2.9 / 3.2 | 15 | in band |
| Fern Hare 3/3 (Reborn) | 3, 8 | 7.6 | 9.3 (F2) | **+16%** | +14% | 9.6 (+20%) | 3.7 / 1.6 | 15 | over |
| Rot Toad 3/2 | 3, 8 | 8.0 | 8.7 (F3) | +9% | +3% | 8.3–8.9 (+4–11%) | 3.2 / 3.0 | 15 | in band |

**Revision 1's suggested reprices, measured [data]:**

| Reprice | Full: best | Full: mean | Small boards |
|---|---|---|---|
| Lantern Moth 1/2 | 5.3 (+5%) | −14% | +2–6% |
| Martyr Hedgehog 2/2 | 8.3 (**+18%**) | −16% | +6–13% |
| Vigil Vole 2/2 | 8.0 (0%) | −29% | −1 to −3% |
| Fern Hare 3/2 | 9.0 (+12%) | +8% | +11–13% |

Revision 1 said these would put all four within about ±7%. That was wrong for Hedgehog (+18%) and Fern Hare (+12%).

What it says about the method:

- **Timing-based position effects are priced about right at their best slot.** Badger, Keeper, Robin, Hare (full board) and Rook land within ±10%.
- **Buffs that land on back units are under-priced.** Hedgehog's text measures 3.6 SP against 2.5, and Vole's 4.3 against 2.7. Back units survive and use the stats.
- **Reborn is under-priced.** Fern Hare's Reborn measures 3.2–3.7 SP, about 0.4–0.45 × V(3), against the method's 0.2. Two Reborn sizes, one card.
- **"Across from" damage is under-priced at 2.4.** It measures 3.3–3.7 SP on full boards, where the slot across is almost always filled. On small boards it measures 2.5–3.0.
- **Taunt with Divine Shield on a weak front body is over-priced.** The method charges 3.0 for Divine Shield and 0 for Taunt; together they measure about 1 SP on a 1/3 front unit.
- **Cards must be priced on the turns they are bought.** Moth (T1) and Stag (T2) are over budget at 3–4 units. Hare is under. The full-board number alone misleads in both directions.
- **The slot spread is the cost of misplacing:** 2–7 SP between the best and worst slot for position cards, under 3 SP for summon cards. A misplaced Keeper (−43% on average) is nearly a blank card.

**Next prices [judgement, not measured]:** Moth 1/2 (measured in band). Vole 2/2 (measured in band). Hedgehog 1/3 or 2/2 with "+1 Attack" only. Fern Hare 2/3 or Tier 4. Lone Stag "+2/+2". Slinger "Deal 2 damage". Tortoise 2/4. Hare 2/3.

---

## 6. Verdict: keep, change, cut

**Keep**
- **The two rows, the stagger, the front-then-back attack order and back-row protection.** They pass the test set before the run: 0.7–0.8 SP more placement value than one row with plain units, and 3–4 SP more with position cards.
- **Timing-based position text:** Start of Combat, Deathrattle, "when the unit in front of this dies", "whenever this attacks" from the front, End of Turn buffs to the units in front. These realise their value and price cleanly.
- **Fixed slots with gaps.** Gaps don't add depth by themselves, but they let cards like Lone Stag work, and part-full boards use them (2–3 front units).

**Change**
- **Retire v0's "placement is almost not a decision"** in power-budget.md 6.1. Replace it with: with plain units, placement is worth about 1.6 SP and one rule (hitters in front, biggest first) finds all of it.
- **Make position text common.** The leftover decision is 0.9 SP with 2 position cards per board and 1.3 SP with 3. **[judgement]** How many units carry position text is a content decision, parked for tribe design (owner, 2 Nov: "In tribe design"). The proposal to start from: roughly a third or more of units in every tribe, with a mix of front-bound and back-bound cards and some board-dependent ones (Moth, Vole, Robin), not only fixed-slot ones (Hare, Slinger).
- **Price position cards on the turns they are bought**, not only on full boards, and raise the realisation for buffs that land on back units, Reborn (toward 0.4 × V(t)) and "across from" damage.
- **Watch back-row congestion.** 6 of the 11 prototypes want the 3 back slots.

**Cut**
- Nothing in the rows rules.
- Card patterns already flagged stay out: static auras from the front onto the back (power-budget.md 6.3) and "when a back unit attacks, buff the units in front of it".
- **[judgement] The minimum-front-row rule (rulebook 8.3.2) looks unnecessary.** No searched layout used one front unit, and a card built for the fortress was weak. The sim had no big Taunt bodies and no Divine Shield givers, so a much stronger fortress card could still change this. Recommendation: drop 8.3.2 as a rule, and add "one-front fortress" to the content guardrails as a pattern to test when such cards appear.

---

## 7. Player experience

What the rows add or cost for a player. **[judgement]** unless marked.

**In the shop**
- **Cards ask "where does this go?" as well as "is this good?".** A Badger is better if you have units to put behind it; a Moth wants your best hitters in front of it. That links buys to board shape, which Battlegrounds only has for a few left/right cards.
- **Recruit Phase position text moves the decision between turns.** Nest Robin asks "who should sit in front of the Robin this turn?" every turn. That is a repeated, visible choice in the shop, where the player has time and information. Combat-only text asks once.
- **Slot pressure.** Three back slots and six back-wanting prototypes mean a player sometimes passes on a good back card. That's good for drafting if it is occasional, and frustrating if one tribe's whole engine wants the back.
- **No turn timer means arranging is free.** Untimed, async play removes the time pressure that makes placement a chore in timed games. The flip side: it rewards fiddling for 1–2 pp gains the player can't see. The leftover decision is about 0.9 SP, or 3–4 pp of win rate per fight. Over a 12–15 fight game that is about half a fight. **Players will feel the obvious rule, not the leftover.** The leftover is for players who care.
- **Async opponents give little feedback for learning a layout.** A player places against the field, never against the board they will meet, and sees one fight per turn. Learning "my Vole belongs in B3" from results alone is slow. The UI should show the links (who is in front of whom) when placing, so the player learns from the rules, not from losses.

**In combat**
- **Readable cause and effect.** "The Hedgehog died and the two behind it grew" is visible on the board. The diagonal links should be drawn.
- **The back row has a clear role.** It acts later and survives more, so support units feel like support.
- **Misplacing hurts new players.** Random placement of position cards costs about 3.5 SP on top of the 1.6 SP of the plain rule [data], and up to 7 SP for one card (Keeper). Misplaced position cards do worse than plain units [data, 4.5]. A **default slot** shown when a card is played (its home row) would remove most of that cost. It would also remove most of the obvious part of the decision, leaving only the 0.9 SP leftover to the player. That is the trade in question 3.
- **Being on the receiving end.** Back-row engines (Vole growing, Rook pinging, Keeper refilling) can't be attacked while your opponent's front lives. A player watching their attacks bounce off the front while a back Vole grows may feel helpless, and async play gives them no way to answer that board directly. Back-row access (rulebook 11.5.3, Acorn Slinger) is the release valve. Random effects already reach the back (9.5.6).
- **What it costs:** more to learn than one row (7 slots, gaps, "in front of / behind"), more to read on a busy late board, and a back-row Taunt that does nothing while the front lives may confuse.

---

## 8. Limits of this study

- Bots, not people. The search is a noisy hill climb on 160 opponents, measured on 500 others. Its training score is up to 7 pp above its test score. The rules were written after seeing the search. A human may find better layouts, or play worse ones.
- The one-row baseline is a stand-in for Battlegrounds: no sliding after deaths, and three prototypes can't trigger on a packed row.
- Plain bodies are Battlegrounds Tier 3 and Tier 5 pairs; the T5 band uses golden prototypes as stand-ins for real late cards.
- Two or three position cards per board, drawn at random from 11. Tribe boards built around position text may have more depth, or more one-answer puzzles.
- No Windfury, Cleave, Venomous, Stealth, Avenge or moving; Recruit Phase text only as Nest Robin's approximation. No big Taunt bodies or Divine Shield givers, so the fortress test is one card.
- Small-board cells use plain opponents of the card's tier, not whole early-game lobbies.
- One rulebook reading for a gap: "when a unit in front of this dies" resolves before Deathrattles (9.7.2 step 1) and "after a unit in front of this dies" after them (step 3). Sapling Keeper depends on this.

---

## 9. Questions for the owner

1. **Is the extra depth enough?** Rows give 2–3× the placement value of one row, but most of it is one obvious rule. The part a rule doesn't find is about 0.9 SP per fight with 2 position cards per board (1.3 SP with 3), against 0.5 SP on one row. Is that the "little bit of extra depth" you wanted? If not, the lever is more position text, not different board rules.
2. **Feel of the prototypes.** Which of the 11 read as fun, and which as homework? (Board-dependent: Moth, Vole, Robin. Fixed-slot: Hare, Slinger, Keeper, Rook. Trap-late: Lone Stag. Fortress: Tortoise.)
3. **Default slots in the UI.** Should a played card go to (or suggest) its home slot? It saves new players several SP of misplacement, and it takes away most of the obvious part of the decision.
4. **Tolerance band for position cards.** ±15% (plain) or ±25% (engine)? And should they be priced at their best slot, their average slot, or on the turns they are usually bought?
5. **Trap-late cards.** Lone Stag is over budget on turns 2–4 and a weak body on full boards. Do you want cards like that, or should every position card stay useful late?
6. **Recruit Phase position text.** Nest Robin makes placement a decision in the shop every turn. Do you want more of this (End of Turn and Battlecry text keyed to "in front of / behind")?
7. **Back-row congestion.** Is it fine that many payoffs want the 3 back slots, or should each tribe have front-row payoffs too?
8. **Minimum front row (8.3.2).** The sim never chose a one-front board, and a fortress card was weak. Drop the rule and watch for fortress cards in content review?

---

## Files

| File | What it holds |
|---|---|
| [rows_placement_summary.csv](../research/battlegrounds/analysis/rows_placement_summary.csv) | One row per cell: win rates by policy, gains in pp and SP, spread, variety, common-field results, board shape |
| [rows_placement_boards.csv](../research/battlegrounds/analysis/rows_placement_boards.csv) | One row per board: the units, every policy's win rate, climb ends, the searched layout |
| [rows_vs_line.csv](../research/battlegrounds/analysis/rows_vs_line.csv) | Rows against the one-row baseline, matched cells |
| [rows_position_card_slots.csv](../research/battlegrounds/analysis/rows_position_card_slots.csv) | Where the search put each prototype, with neighbour counts |
| [rows_card_slots.csv](../research/battlegrounds/analysis/rows_card_slots.csv) | Each card in each slot (and gap or small-board layout): gain over vanilla, body and text value, SP-equivalent |
| [rows_card_summary.csv](../research/battlegrounds/analysis/rows_card_summary.csv) | Each card: best, mean and worst slot, small boards, text value, error and tolerance band |
| [rows_engine_check.csv](../research/battlegrounds/analysis/rows_engine_check.csv) | v0 against v1 engine on 6,000 vanilla boards |
| [rows_run.csv](../research/battlegrounds/analysis/rows_run.csv) | Run settings, seed, slopes and run time |
