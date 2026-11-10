*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov (workflow wf_ba56a210-573). Calls: DECISIONS (ideation/main) "Hedgerow light pass (A2): review calls".]*

**Scope review: Hedgerow light pass (A2), `ideation/wave2b` `ba80977e..424b3c2a`**

The brief had all three inputs: the owner's words, the approved plan text (A2 and item 14) and the target.

- **Counts:** keep 24, cut 0, simplify 1, ask 3.
- **Does it move the original problem (scale too small and flat)?** Yes, for Hedgerow. Measured on the same seats (alive at R14), the lines grow ×1.542 (Supper) and ×1.738 (Parish) a round from R8 to R14. Pooled R12 is 874, which is 0.97× the 900 target. Median boards at R14 are 2,500 and 4,600, roughly 180/180 and 330/330 per unit. This says nothing yet about the other tribes; A3.5 and A4 decide that.
- **Cut:** none.
- **Ask 1:** Nothing reads the 5.9 MB `hedgerow-fights.jsonl.gz` or the players, rounds and cards CSVs. Who reads them, and when? If no one does before A3.5 or A4, keep them out of git.
- **Ask 2:** The lines don't fully play their paper route. Parish misses its R10 Tier 6 climb in 13 of 29 seats, and Supper misses its R12 climb in 7 of 25. Most of those seats banked 0 gold the turn before. The paper's refresh rules and the Supper's Sergeant cash rule were never built, and `route-fidelity.json` doesn't mention them. Fix them, or log them as accepted?
- **Ask 3 (decides criterion 1):** Dozey's clock isn't what carries the Supper. Only 18 of 32 Supper seats field Dozey by R12. Among R14 survivors, seats with Dozey grow ×1.43 (11 seats) against ×1.63 without him (8 seats). He is 22–32% of the board, against the paper's 61% at R12 and 44% at R15. Supper survivors are running the Committee (17 of 19), Mallow (16) and Lollop (13). Does criterion 1 pass on the Committee alone, or does the Supper need work?

---

## Change inventory (pr-report)

**Size:** 117 files, +15,786/−455. That splits into 28 evidence files (+10,485), 31 test files (+2,490) and 58 code, content and doc files (+2,811/−406). No files were deleted, and no tests or assertions were removed.

- **Schema and data:** 26 `hedgerow_*` dials in `content/pass3/rates.json`, in the base rates, B and C. A `pass3_hedgerow` entry in `content/schema/effects.json`. New fields `PlayerState.hedgerow_bonus` and `hedgerow_end_phase` (`player_state.gd:44-46`). Stated reason: the brief and `presets.md`.
- **Scheduled or background:** none.
- **Features:**
  - 16 pass 3 card definitions in `content/units/*.json`. Every tier and stat matches the paper.
  - Faces and details are generated from the selected preset (`pass3_hedgerow_text.gd`).
  - Recruit rules (`pass3_hedgerow.gd`), combat rules (`pass3_hedge_combat.gd`) and mechanic dispatch.
  - A Larder value dial, active under `pass3_content` (`pass3_hedgerow_text.gd:359`).
  - UI: wake pips, the runt circle and the Hunker shield (`hedgerow_marks.gd`), reader lines (`card_detail.gd:404`), and a "Hand ·Ng" Larder header with a tooltip.
  - Stated reason: the brief, plus the design doc's "Engine support needed" and "Screens" lists.
- **Public interfaces:** `BotHedgerow` (548 lines). Hooks in `bot_brain.gd`, `bot_placer.gd`, `bot_pass3.gd` and `committed_line_brain.gd`. The line file `tools/sim/lines/hedgerow.json`. Strategy files: a new `hedgerow_supper.json`, and rewritten parish and treasury files. Changed `cards.json` hints.
- **Internal machinery:** `wave2b_growth_report.py` with 8 tests. Line telemetry (gold, shop tier, Larder, Belly contents) in `wave2b_lines.gd:191-194`. UpsetCombat audit entries. `LegacyWave1.with_hedgerow` plus a frozen pass 2 archive (`tests/core/data/pass2_hedgerow_units.json`). `check_units.py` support.
- **Docs:** rulebook 12.1.10 added, with 12.1.1a and 12.1.2a scoped to pass 2. A new section in `engine.md`. Build notes in `wave2b-build.md`. Commit `424b3c2a` also adds part 1 notes: the Hasty row, an instruction-deviation disclosure, and the Pot Luck plan.
- **Unrequested:** the fight capture and CSVs (nothing reads them). The hand-title font shrink, which applies to every player. The part 1 doc additions.

## Verdicts

| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| 1 | 16 pass 3 cards | keep | Tier, stats and spread 3/3/3/3/2/2 match the paper | — |
| 2 | Text generator | keep | Faces come from the same dials as behaviour (`test_rate_overrides_rewrite_faces…`) | — |
| 3 | Recruit core and dispatch | keep | In scope (Engine support 1–10) | — |
| 4 | Combat module | keep | Hunker aura, Clover, Sergeant | — |
| 5 | Engine hooks | keep | All are gated on a native Hedgerow unit being present (`recruit_rules.gd:167,181,184,210`). Frozen-content normal games replay with their original hashes | — |
| 6 | Larder value dial | keep | Only content-wide path (`:362`). Defaults 1/5/16 and the item text equal legacy. Archived captures are left alone | — |
| 7 | 26 dials | keep | All equal `presets.json` B and C. The base rates equal B. No other tribe's dials changed | — |
| 8 | Schema entries | keep | Supports 7 | — |
| 9 | BotHedgerow and hooks | keep | Covers the paper's bot needs: hold-and-feast, move after a wake, cash-out, runt selling. Moved legacy helpers (`hold_value`, `item_indexes`, `feed_eaters`) are identical when `build()` is false | — |
| 10 | `BotHedgerow.aim` placement | keep | 3-line early return at the top of `_best_aim` (`bot_brain.gd:795`). On main that body is `BotAim.best_slot`, so it moves there at merge, as DECISIONS logs | Move at merge |
| 11 | Line brain climb and cash gating | keep | Hedgerow builds only. The other tribes' line tests pass (`test_committed_lines` 9/9, `test_wave1_lines` 12/12) | — |
| 12 | Line file | keep | Priority and climb are identical to the paper JSON (checked by script) | — |
| 13 | Strategy files and bot hints | keep | The old strategies referenced pass 2 bodies | — |
| 14 | Line telemetry | keep | The plan asks for it. Read by the reporter | — |
| 15 | Growth reporter | keep | I reproduced its figures exactly | — |
| 16 | Upset audit entries | keep | Belongs to S1. None of the 16 ranks enemies by size | — |
| 17 | UI | keep | Listed in the design's Screens section. Note: the hand-title font shrinks for all players | — |
| 18 | Rulebook and engine notes | keep | Rule sections belong to S1 | — |
| 19 | 80 new GUT tests | keep | 18+19+6+9+24+4 | — |
| 20 | Frozen archive and 15 rebound legacy tests | keep | The archive is byte-identical to the base definitions. No expected value changed | — |
| 21 | `check_units.py` | keep | — | — |
| 22 | `recruit_rules.gd` comment trims | keep | Meaning is preserved, except that it drops a pointer to `soak.gd`. 995 lines on the merged tree | — |
| 23 | Core evidence | keep | — | — |
| 24 | Part 1 notes in `424b3c2a` | keep | Docs only. A disclosure, not a new call | — |
| 25 | Fight capture gz and CSVs | **ask** | 5.9 MB, 3.5× the largest evidence file before it. Nothing reads it | Name a reader, or drop it from git |
| 26 | Route fidelity in play | **ask** | See probe 2 | Fix, or log as accepted |
| 27 | Supper's signature | **ask** | See probe 3 | The orchestrator's call on criterion 1 |
| 28 | Growth headline | **simplify** | The headline is the survivor read, not the plan's read | Lead with the same-cohort read |

## Probes

**1. Text equals behaviour.** All 16 cards' generated normal and golden faces match the code's parameters. Fifteen have live pass 3 behaviour tests for both normal and golden, and I checked their arithmetic by hand:
- Dozey: food gives 44 normal and 88 golden; a golden wake gives 12/24, not fourfold.
- Crumb, Partner (6 normal, 12 golden), Clover, Pym and Beadle (9 and 18), Mallow (2 and 4 targets), Treasurer (16 and 32), Hayward (21 and 42), Committee, Lollop, Mast (71 and 81).
- Urchin's golden Hunker (two targets), Sorrel, and the Sergeant (90/91 normal, 25/26 golden).

One gap: golden Mrs Burdock is tested only on the frozen pass 2 copy (`test_slice_hedgerow`) and by a data and face test. Her pass 3 effect data is unchanged and she is an unchanged card, so the brief doesn't require it. Still, the worker's "all 16" claim slightly overstates.

The shipped faces show B's generosity, for example "double your two smallest", "+2/+2 per gold", "a quarter". The amended tribe gate holds: "Your last other Hedgerow unit has Hunker" (cross-tribe §5). I found no card whose text and code disagree.

**2. Route fidelity.**
- On paper the line files match: priority and climbs are identical, and the save rule is the exact next-turn shortfall. Gold, shop tier, Larder and Belly contents are logged in every row.
- In play the climbs run on schedule up to Tier 5: 30–32 of 32 seats in each line. Tier 6 slips:
  - Parish at R10: 16 on time, 13 late, and 12 of the 13 late seats banked 0 gold at R9.
  - Supper at R12: 18 on time, 7 late.
  - T6 costs 13 in code against the paper's 11 (C10). That explains part of the slip, but the save rule should still have banked the 1 gold short.
- Not built, and not listed in `route-fidelity.json`:
  - Parish: "refresh up to twice a turn, more only to find Committee/Lollop".
  - Supper: "from R12, refresh freely".
  - The Supper's Sergeant cash rule.
  - The Parish neutral rule (the worker logged this one).
- The Supper's fuel is mostly missing. The Partner is on 7 of 32 boards at R3–R6. The Larder median at R8 is 2 gold, against the paper's 16–17.

**3. Growth.** I recomputed it from `hedgerow-lines.jsonl` and every figure matches the summary.
- **The plan's read** (the same seats, alive at R14, from their R8 median to their R14 median) is "matched medians":
  - Supper 186 → 2,500, **×1.542**.
  - Parish 167 → 4,600, **×1.738**.
  - Both clear ×1.3.
- **Share alive at R14:** Supper 19/32 (59%), Parish 20/32 (62.5%), pooled 61%. No lobby ended before R14.
- ×1.615 and ×1.848 are the survivor read, and ×1.480 and ×1.723 are the median of each seat's own growth. Neither is the plan's read.
- On that same cohort, R12 medians are 1,100 and 1,468.5.

Signature check, as the fresh reviewer for criterion 1:
- **The rules have signatures that aren't Blood Gems:** Dozey's slot clock and the Committee paying the run by its weakest member. The Blood-Gem-shaped parts are Larder items played onto Dozey and Hayward's "+N per gold played".
- **On real boards only the Committee shows up strongly** (see Ask 3).
- **Dozey's realized size** is a median of 225 at R12 and 1,148 at R15. That tracks the paper's late line, not its on-time line.

**4. Rollback and leaks.** Every new path is gated on a native `pass3_hedgerow` unit, or on `build()`, which needs the native library plus a Hedgerow strategy. I found no content-wide leak like the Ooze one:
- The `pass3_content` Larder path leaves values and text identical.
- The `"hunker"` status is set only by this module.
- `hedgerow_end_phase` (the rule that a Pass fired during End of Turn lands at once) applies only when a native Hedgerow unit is on the board.

`test_field_normal_regression` (frozen content, original hashes) passes on the final source. The worker recorded that run, along with the start-order run at 41/41. There are no src, content or tests changes after the measured revision `313501fa`.

**5. Tests loosened.** None. All 15 edited legacy files only rebind to the frozen pass 2 Hedgerow; no expected values change. `test_fixture_port` only wraps a message string. They last ran in the earlier 360/360 compatibility run, not the final targeted run, so the cloud full gate has to cover them.

**6. Caps.**

| File | At `424b3c2a` | Trial merge with `d9462c84` |
|---|---|---|
| `recruit_rules.gd` | 1,000 (at cap, lint passes) | 995, clean |
| `bot_brain.gd` | 997 | one conflict (`_best_aim`), about 981 once resolved |
| `game_session.gd` | 999 | 974 |
| `recruit_screen.gd` | 1,000 | 1,000 (B2 has to absorb the extra line) |

**7. Generous first (09h).** All B dials equal paper B or sit above them, and six are above the design value (food, Partner, Clover, Mallow targets, Beadle, Committee). C is at or above B everywhere.

**8. Owner misattribution.** None found. `DECISIONS.md`, the owner notes and the briefs are untouched.

## Gaps
- Golden Burdock has no live pass 3 behaviour test.
- The rebound legacy tests weren't rerun on the final source (the cloud gate covers this).
- The unbuilt route rules listed in probe 2.

## Open questions (orchestrator)
Asks 1–3 above.

## What I ran
- Git reads only, and a trial merge with `git merge-tree --write-tree` against `d9462c84`. That writes only unreferenced objects; no refs or worktrees changed.
- Independent recompute of growth, tiers, gold, Larder and cards from `hedgerow-lines.jsonl`, and Dozey's size and slot from the fight capture.
- Dial checks against `presets.json`, and a byte check of the frozen archive against the base definitions.
- On a scratch copy of the tip: `ruff check` and `ruff format --check` pass, 29/29 Python unittests pass, `check_units.py` reports 165 files with 0 problems, `gdlint` passes on src, tools and tests, and `gdformat --check` passes on the 4 new files.

**Not run:** Godot, GUT or any sim (per the brief).