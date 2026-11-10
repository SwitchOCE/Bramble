**Narrow scope check: Quilboar review fixes and the lint-cap extraction (`92cbce1f..25fc1576`, squash `1511dc22`)**

*[Saved by the orchestrator from the reviewer's final message, verbatim.]*

All three inputs were in the brief: the target, the owner's words (09f, 09i, the 6 Nov never-into-main rule) and the plan text (DECISIONS "Quilboar H1 and merge review: calls" and the LEARNINGS lint-cap entry).

## Summary

- **Counts:** 15 keep, 0 cut, 0 simplify, 1 ask.
- **Does it move the original problem?** Yes. The owner wanted a BG tribe in the game for testing only (09f). These five commits were all that stood between the Quilboar reference and ideation/main:
  - the lint failure that blocked the gate is fixed;
  - the 94 MB of captures are out of git;
  - native seats in reference lobbies now keep their own Busker rules.

  Isolation still holds in the squash. The change adds no new measurement, which is right under the stop rule and 09i.
- **Ask 1:** nothing reads the new `capture_storage: "not in git, hash recorded"` label on all 154 records, or the three new `verification.json` counters in `archive_quilboar_h1_cycle_fix.py:58–60`. Who reads them? My suggested answer: a person opening a receipt after `build/` is gone. Keeping them is cheap.

No cuts. No line credits the owner with a call the orchestrator or worker made. The "requested 985" in 4b44e66a's message is the orchestrator's number, and the message doesn't attribute it to the owner.

## What changed (pr-report, range 92cbce1f..25fc1576, 5 commits)

**1. Schema / data**
- **154 full fight captures deleted from git** (93.85 MB, `*.fights.jsonl.gz` under `tools/sim/evidence/quilboar-h1*`).
  - Used by: only the hash checks below.
  - Stated reason: DECISIONS Ask 2, "move them out of git to `build/quilboar-h1-captures/`, and keep each file's hash".
- **12 receipt, progress and summary files.** Each capture record's `capture` path now points to `build/quilboar-h1-captures/…`, and each record gains `capture_storage`.
  - Used by: `verify_capture`, `relocate`, `quilboar_h1_rerun_report.py`.
  - Stated reason: same as above. The label itself: none stated.
- **cycle-fix `summary.json.gz`:** `native_wave1_r12_range` goes from [0.17, 0.44] to [0.17, 0.72].
  - Used by: the h1.md rendering.
  - Stated reason: DECISIONS caveat, "Correct `h1.md` and the report script".

**3. Features**
- **Busker guard narrowed** (`reference_quilboar.gd:189`): the guard now applies only to spells whose id starts with `qb_`. Stated reason: Simplify 1.
- **New test** (`test_quilboar_h1_switches.gd:104–114`): a native Busker seat casts two Pelts caps-off in a reference lobby and gets +2 gold. Stated reason: Simplify 1.
- **Test fixture changes** (lines 21, 29, 37): the test spell is renamed to `qb_h1_free_spell`, and `card_size_caps=false` is set for the whole file. Stated reason: none stated.
- **`h1-smoke.md`** cut from about 690 lines to 14 lines of timing. Stated reason: Simplify 2.
- **h1.md:49 and `quilboar_h1_report.py`** (lines 410, 421, 425–426, 454) give the range as 0.17–0.72×, with a new test in `test_quilboar_h1_report.py`. Stated reason: DECISIONS caveat.

**6. Public interfaces**
- New global classes `SessionViews` (`passes`, `hero_card`) and `BotAim` (`best_slot`).
- The old entry points stay as one-line delegates: `game_session.gd:259–260` and `:362–363`, and `bot_brain.gd:783–784`.
- Stated reason: LEARNINGS "The 1,000-line lint cap bites at merges: extract helpers".

**7. Internal machinery**
- **`verify_capture` and `archive_capture`** (`checkpoint_quilboar_h1.py:23–55`):
  - a missing file returns False;
  - a bad or missing hash raises;
  - present but changed bytes raise;
  - full captures are copied only into `build/`.

  `archive_quilboar_h1_cycle_fix.py` now uses it. Stated reason: Ask 2.
- **`relocate_quilboar_h1_captures.py`** (72 lines): the one-shot script that did the move. Nothing calls it. Stated reason: none stated, though it matches the drivers folder's stated role as "historical execution evidence".
- **`test_quilboar_h1_archives.py`:** 6 tests. Stated reason: supports Ask 2.

**8. Deleted:** the captures, most of `h1-smoke.md`, and the inline hash loop in `archive_quilboar_h1_cycle_fix.py`.

**None:** Scheduled/background, External, Config.

**Unrequested:** the `capture_storage` label and verification counters; the relocate script; `card_size_caps=false` in the shared fixture.

**Size:** 184 files, +1,285 / −1,383 lines (154 of the files are binary deletions). 30 files excluding captures.

## Verdicts

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| Busker guard on `qb_` only | keep | `reference_quilboar.gd:189`. `check_units.py:516–517` rejects `qb_` ids outside the reference folder, so `qb_` means exactly "Quilboar". All three reference spells are `qb_`. | — |
| Native Pelt test | keep | It's a real test. Pelt costs 0 and `give_card` leaves `paid_cost=-1, pool_copies=0`, so `created_free_spell` is true (`recruit_rules.gd:699`). `setup` flags every seat in the lobby (`reference_quilboar.gd:72`). Under the old guard the second refund was blocked, so the test fails before the fix. | — |
| Fixture rename and `card_size_caps=false` | keep | The rename keeps the existing guard tests on the guard. All four H1 arms ran with both caps off (`quilboar-h1-plan.json`), so the fixture now matches H1. The Gem Day test still covers delayed Choose One (`quilboar_choices.gd:65`). | — |
| SessionViews extraction | keep | Both blocks are byte-identical. Both were already static, so no instance state is involved. No RNG. All callers resolve: `game_session.gd:213/297/317`, `field_rivals.gd:268`, `test_configured_rulings.gd`. | — |
| BotAim extraction | keep | Identical apart from the `brain.` receiver and one wrapped line. Same order, defaults, early returns and iteration. No subclass overrides `_best_aim` or `_aim_score`, and `brain._aim_score` still dispatches dynamically. Lines: 974 and 977, against a cap of 1000. gdlint and gdformat are clean. | Plan the wave 2b conflict (below). |
| Captures out of git | keep | No `fights.jsonl` file is in the 1511dc22 tree. `build/` is already in `.gitignore`. | — |
| Receipt paths rewritten | keep | A JSON diff of all 12 files shows only `capture` and `capture_storage` changed. Every hash is unchanged. | — |
| `capture_storage` label and verification counters | **ask** | Nothing in code reads them. `relocate` only compares the label against itself. | Orchestrator decides; keeping them is cheap. |
| `verify_capture` / `archive_capture` | keep | Missing hash raises at `:26–28`; changed bytes raise at `:32` and `:38`. Covered by `test_missing_capture_without_hashes…`, `test_corrupt…` and `test_conflicting_local…`. A missing file returns False at `:30–31`. | — |
| Relocate script | keep | Matches the drivers README ("historical execution evidence"). Nothing breaks if it's deleted. | — |
| Archive tests | keep | They prove missing-is-OK and corrupt-fails. | — |
| READMEs (cycle-fix, smoke) | keep | They describe the new storage. | — |
| `h1-smoke.md` cut to timing | keep | Numbers match `progress.json`: 5.24 / 4.11 / 3.56 / 4.85 s, mean 4.44 s, 2,243.5 s projected. Nothing else links to it. | — |
| 0.72 range | keep | Matches review-quilboar-h1.md:144. Uncut 0.121 is still outside the range; B (0.226) still inside. The conclusion stands. | — |
| Squash 1511dc22 | keep | Single parent 3cfd1f0c. `git diff 2ac2e5be 3cfd1f0c` equals `git diff 25fc1576 1511dc22`, and `git diff 2ac2e5be 25fc1576` equals `git diff 3cfd1f0c 1511dc22` (patch sha256 match). Stats match: 583 files, +20,520 / −116. ideation/main's 9 changed files since the merge base are all docs and don't overlap the branch. Isolation holds: flag defaults false (`game_config.gd:39–40`), all 4 export presets exclude `content/reference/*`, field-library hashing excludes reference content (`field_library.gd:12`), and none of these files changed in the range. No `origin/ideation/quilboar` exists, so the captures were never pushed. | Gate and fast-forward as planned. |

- **Cut:** none.
- **Simplify:** none.

**Gaps (not verdicts):**
1. **h1.md has no note that H1 ran with the broad guard.** In H1's reference lobbies, native seats were under the old guard, so Busker refunded their Created 0-cost spells (Triple Rewards) only once a turn. Nothing reruns. A one-line caveat would keep the native comparison honest. I didn't measure how much it mattered.
2. **RESTART.md still quotes 0.17–0.44×** at lines 105 and 478. That's ideation/main's guide, outside this branch, but it's a living doc.
3. **One copy of the captures is left.** Once ideation/quilboar is deleted, the only copy of the 154 captures is `/home/alex/code/Bramble-ideation-sol/build/quilboar-h1-captures/`. All 154 match their recorded hashes today. The plan accepts this.

## Wave 2b merge plan (bot_brain.gd)

Both branches fork from 2ac2e5be.

- **`_best_aim`: certain conflict.** Wave 2b adds a 3-line `BotHedgerow.aim(_player, value, legal, card_def)` early return at the top of a body that this branch replaced with `return BotAim.best_slot(...)`. Two ways to resolve it:
  - put the 3 lines in the delegate, before the call (bot_brain about 984 lines);
  - or put them at the top of `BotAim.best_slot`, using `brain._player` and `brain.value` (about 981 lines).
- **`from_name`:** this branch adds an alias and a strategy branch. Wave 2b deletes the doc comment above the function. They're adjacent but don't overlap, so it should auto-merge. Check whether the WIP meant to delete that comment.
- **`_smart_turn`:** this branch adds a Quilboar early return at the top. Wave 2b adds Ooze/Hedgerow `prepare` and `feed` calls further down. Separate lines.
- **game_session.gd:** wave 2b doesn't touch it, so it stays at 974.
- **Other files both branches change**, from earlier Quilboar commits: `combat_unit.gd`, `recruit_context.gd`, `game_config.gd`, `player_state.gd`, `recruit_rules.gd`, `recruit_unit.gd`, `check_units.py`.
- The `-balance` worktree has no uncommitted bot edits.

## What I ran and didn't

**Ran** (read-only, on git objects or temp copies in the scratchpad):
- block-by-block diffs of the extraction;
- a JSON field comparison of all 12 rewritten evidence files;
- a hash check of the 154 local captures in the `-sol` worktree: 154 of 154 match;
- `test_quilboar_h1_archives.py` and `test_quilboar_h1_report.py` on a `git archive` copy: 20 pass;
- a rebuild of h1.md from committed evidence with no captures present: byte-identical, and the rebuilt summary equals the committed `summary.json.gz`;
- gdlint and gdformat `--check` on the 5 touched GDScript files: clean;
- the squash patch-equality check.

**Didn't run:** Godot or GUT (per the brief; the 66-test GUT claim is unchecked here), the full Python suite, or anything after 25fc1576 or 1511dc22. Nothing was checked out or edited.
