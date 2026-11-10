# Narrow scope check: wave 2b part 1 fixes (`a2f4295f..ba80977e`) and the merge `53ff356a`

*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov. Brief: `brief-review-wave2b-fixes.md` in the orchestrator's scratchpad. Calls: DECISIONS (ideation/main) "Wave 2b part 1 merged: narrow check calls".]*

**Counts:** 22 keep, 0 cut, 0 simplify, 1 ask (23 items).

**Does it serve the owner's purpose (scale too small and flat, 09a/09h)?** Only by unblocking. This step fixes the gate and the rollback and applies the review calls, so the pass 3 Oozes can land:
- Engine line ×1.37: passes.
- Pot Luck ×1.25: still open.
- R12 is still 0.22–0.32× of 900.

Hasty now reads current stats, which is more generous (09h). Shy getting no Soup gives slightly less. Nothing was re-measured.

**Cut:** none.

**Ask (1):**
1. The bot fix in `bot_ooze.gd:154` changes how Hard bots and committed lines value six native Oozes: Wobbly, Figgy, Pie, Syllabub, Moss and Posset. They now use the pass 2-era authored keep hints (5/8/5/6/4/4) instead of a flat 6 or 3. No one re-measured the lines afterwards. Should the Pot Luck and engine baselines (×1.251 / ×1.37) be rerun on ba80977e or later before the route-fidelity arms are compared against them?

All file:line references are in `/home/alex/code/Bramble-ideation`, read at `ba80977e` (range A) or `53ff356a` (merge).

---

## Brief
All three inputs were present:
- **Target:** range A plus merge B.
- **Owner's words:**
  - 09a: "our numbers may just be too small in general"; "concentrating stats is always better than spreading them out".
  - 09h: "giving out power overly generously and then dialing it back, rather than starting from too weak and dialing up".
  - 09i: "Get good at one or two things and then start fixing other issues."
- **Plan:** `docs/ideation/briefs/wave2b-build.md` (criterion 1, "text equals behaviour") and the two DECISIONS entries.

The orchestrator's instruction to fix the frozen Elders/Wobbly failure in code is a proposal, and I judged it on the merits (probe 1, row 8).

## Probes

**1. Tests loosened? No.** I checked each failure in run 42714374887 against the gate log (`/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/wave2b-gate-fail.log`).

| # | Failure | Fix | Assertion values |
|---|---|---|---|
| 1 | ruff format | Formatting only (`check_units.py:186-193`) | n/a |
| 2 | `test_combat_logging` | Test: the Posset line now loads frozen pass 2 definitions | Unchanged. The equality assert (old line 71) never failed; only 73 and 75–77 did, ×32 seeds. A new native test was added |
| 3 | `test_engine_docs` | Doc: `on_eat` row in `engine.md:63` | n/a |
| 4 | `test_engines` ×2 | Test: frozen definitions | Unchanged |
| 5 | Field normal regression | **Code** (ba80977e) | Test and fixture untouched |
| 6 | `test_free_choice` | **Code** (`bot_ooze.gd:154`) | Assertions added, none weakened |
| 7 | View keys | Allow-list gains `ooze_share_serial`, plus an `== 0` assert | The key already existed (`recruit_unit.gd:148`, since part 1); the Elder pulse reads it (`recruit_oozes.gd:17`) |
| 8 | Frozen Elders/Wobbly | **Test, not code**: frozen definitions | Unchanged (see below) |
| 9 | Dozey 42/46 vs 40/41 | Old test moved to frozen; new native test | The gap is exactly Dozey's 2/5 body being digested first. The bound is still +8. Native test: `test_review3_dozey.gd:104` |
| 10 | Counts 158 / 158 | Assertion values changed | Slice is the one new file (158 unit JSONs). 37+1+109+10+1 = 158 |
| 11 | tribes56 tag "Comes out" | Assertion value changed | Native Moss text "When a unit comes out…" matches chip rule `card_view.gd:102` |
| 12 | Portraits 120 | Asset added (512×512 JPEG) plus count | 109 + 10 + 1 |

Row 8: the orchestrator asked for a code fix and the worker changed the test instead. That is right on the merits:
- The test asserts pass 2 Elder text (Elder buffs Drips), which the native card no longer has.
- It passes on frozen definitions with no change to the legacy rules (`legacy_wave1.gd` is untouched).
- So the failure came from the default library now holding pass 3 cards, not from a frozen-rule fault.
- The worker didn't flag that it was declining the instruction.

**2. Determinism.** killed_by is set on the lethal hit whether or not logging is on (`combat_damage.gd:65-66`), and Posset reads it (`pass3_ooze_combat.gd:65`).

The new `test_native_posset_halving…` (`test_combat_logging.gd:122`) runs 3 seeds × attack/effect kill × swapped × golden. It compares quiet and logged runs on:
- the result;
- the killer's stats [6,5];
- killed_by;
- the credit triple;
- both RNG states;
- carry and triggers.

A logging-only path would break it. It is narrower than the legacy line: no board views or statuses, and the golden neighbour branch has no neighbours to hit.

**3. Rollback.** The only content-wide gate part 1 added was `Pass3Combat.has_content` in `return_inside`, and that is true in any lobby with pass 3 Birds (`pass3_combat.gd:14-29`). That was the leak. It is now a per-copy `pass3` check (`combat_held.gd:91, 150, 174`). Every other Ooze path is gated per card.

The four field hashes caught this leak only because seed 17 happens to hit a friendly Belly return with legacy Syllabub. They catch only leaks on paths those four games reach. The new mixed-board test (`test_pass2_followup_review.gd:126`) pins this path directly: before the fix it would read attack 4, not 1.

**4. Review calls: all implemented, each with a known-answer test.**
- **Shy gets no Soup:** `pass3_oozes.gd:152,164`; test `test_pass3_ooze_recruit.gd:78`, normal and golden Soup; rulebook 12.1.9 "non-Shy".
- **Hasty reads current stats:** `pass3_ooze_combat.gd:141-144`.
  - Layers test: 290/405 → [58,81] (`test_pass3_ooze_start.gd:63`).
  - Ring test: [12,16] (`:75`).
- **Posset via `killed_by`:** her own map and lethal hook are gone (no references left). The death event's `killer` is still filled from killed_by (`combat.gd:782`), and the test asserts it.
- **Elder's space:** `pass3_ooze_text.gd:292`; test `test_pass3_ooze_content.gd:172`, normal and golden.

**5. Merge.**
- `combat_unit.gd:85-90` takes the union of the gem fields and the replay flag; nothing else overlaps.
- `check_units.py` takes the union of the golden-exempt set.
- The `test_fixture_port.gd` wrap is a byte-identical string; I reproduced ba80977e's gdlint failure at line 56.

I found no semantic clash in normal games, because Quilboar loads only with the flag in an editor build (`reference_quilboar.gd:9-14`). Specific points:
- Gems live inside perm stats (`recruit_context.gd:384-388`), so eating grants them (`pass3_oozes.gd:83`) and Soup and Elder read them. The ledger doesn't follow the eater, which matches "base plus permanent".
- Belly copies carry gems through `combat_spec` (`recruit_unit.gd:220`) and the merged `make()`.
- `scaling_exempt` touches only spell scaling; no Ooze effect is a spell.

Two interactions are reference-only and untested:
- `_can_lend` (`recruit_unit.gd:322-354`) doesn't exclude `reference_quilboar`, so native Frumenty that eats a qb unit keeps its text for good (for example, Gem Rat's end-of-turn Gem Day).
- The H1 suite's `line_oozes_engine` now resolves to the pass 3 line, so the archived H1 results aren't comparable. Tuning is stopped, so the stakes are low.

**6. Owner misattribution:** none. The old "not an owner ruling" line was replaced with "review call applying rulebook 12.1.7".

## Table
| Item | Verdict | Evidence | Action |
|---|---|---|---|
| 1 Soup/Shy | keep | DECISIONS Cut; `pass3_oozes.gd:152,164`; test `:78` | — |
| 2 Hasty current stats | keep | DECISIONS Ask 2; tests `:63`, `:75` | — |
| 3 Posset killed_by, map removed | keep | DECISIONS Ask 4; `pass3_ooze_combat.gd:65` | — |
| 4 Elder space | keep | DECISIONS Small | — |
| 5 Native-only Syllabub returns, plus test | keep | Field hash mismatch d9a976d8 | — |
| 6 BotOoze −1 fallback | **ask** | `bot_ooze.gd:154`; read by `committed_line_brain.gd:59,75` and BotEval | Keep the code; re-baseline the lines |
| 7 Slice portrait and prompt | keep | `test_portraits` | — |
| 8 `on_eat` doc row | keep | `test_engine_docs` | — |
| 9 Logging test: frozen plus native | keep | Probe 2 | — |
| 10 `test_engines` frozen | keep | Legacy Posset | — |
| 11 Elder tests frozen | keep | Probe 1 | — |
| 12 Dozey frozen plus native | keep | 2/5 meal | — |
| 13 Counts 158/158/120 | keep | 158 files | — |
| 14 tribes56 "Comes out" | keep | `card_view.gd:102` | — |
| 15 View-key allow-list | keep | `recruit_oozes.gd:17` | — |
| 16 ruff format | keep | — | — |
| 17 Upset-audit hash refresh | keep | No code reads it; classifications still hold | Not logged in the notes |
| 18 Targeted logs | keep | Cited by the notes | — |
| 19 Rulebook 12.1.9/9a and build notes | keep | Calls | Fix the stale row (see Gaps) |
| 20–22 Merge resolutions and wrap | keep | Probe 5 | — |
| 23 Reference-only interactions | keep | Probe 5 | Note before any H1 rerun |

**Gaps:**
- `docs/ideation/content/pass3/wave2b-build.md:20` still says Hasty has an "own-body permanent gain".
- The worker said its GDScript lint passed, but `test_fixture_port.gd` failed lint; the merge fixed it.

**Original problem:** not moved by this step itself. It makes part 1 mergeable, and Pot Luck stays open.

## What I ran, and what I didn't
**Ran:**
- git reads, and the a2f4295f gate log.
- On a `git archive` of 53ff356a:
  - `check_units.py`: 165 files, 0 problems.
  - ruff format and ruff check: pass.
  - pytest on `tools/checks/tests`: 120 passed.
  - gdformat: 22 files unchanged.
  - gdlint: src and tests (with the tests' own config) clean.
  - A Python check that every schema name appears in `engine.md`: none missing.
- gdlint on ba80977e's `test_fixture_port.gd`: reproduces the line-56 failure.

**Didn't:** run Godot or GUT, run sims, or look at 53ff356a's gate.
