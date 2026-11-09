**Scope review: `ideation/quilboar` 4d23628e..6bb7c730 (H1) and merge 92cbce1f**

*[Saved by the orchestrator from the reviewer's final message, verbatim. The reviewer couldn't write the file itself.]*

**Counts:** 20 keep, 0 cut, 2 simplify, 3 ask.

**Does it serve the owner's purpose (an A/B that teaches lessons about scale)? Partly.**
- **It confirms the owner's prediction in our engine.** Uncut Quilboar at R12 is 5.5–7.7× five of our six lines and 2.4× Birds, and it wins 64% of lobbies.
- **Its archives already answer the trivariate question, but nobody has logged it.** Freezing gem size (pre-fix, same seeds) cuts uncut R12 from 825.5 to 175.5, which is near our lines.
- **It does not produce the design lessons.** No H2, D1–D6 or playtest step is scheduled.
- **It does not settle the owner's "is the strategy correct?"** The check meant to prove the bot (accounting) failed.

**Ask items**
1. **Strategy (the owner's question).** The bot keeps at most 2 off-tribe units from R1, so it leaves slots empty early: 2.5 units at R4 and 4.0 at R6, against Hard's 4.3 and 6.4. It also finds Hogrider at a median of R12, against paper's R11. What do we tell the owner, given the stop rule bars retuning?
2. **94 MB of full fight captures in git.** Only hash checks read them. ideation/main's whole evidence folder is 15 MB. Who reads them, and when?
3. **What next for the reference.** Both criteria failed. DECISIONS keeps a "scale finding" but lists only "merge" as the next step. Is the reference parked? If not, which run comes next, and against what bar?

**What I ran and didn't**
- Ran (Python and git on temp copies, no Godot):
  - Recomputed the headline medians from the committed compact archives.
  - Recomputed paper from the model at T6=11 and T6=13.
  - Re-bootstrapped the fidelity interval with my own code.
  - Rebuilt `h1.md` and `summary.json.gz` from committed evidence with the worker's rerun script. Both came out byte-identical.
  - Timed the new Python tests.
  - On a copy of 92cbce1f: `check_units.py` (0 problems) and the full Python suite (109 tests, OK).
  - `gdparse`, `gdformat --check` and `gdlint` on 12 merged GDScript files: all clean.
  - Three-way line and key checks on every conflict file.
- Didn't run: Godot, GUT, or a GDScript type check.
- Housekeeping: I hit the `/tmp` quota and deleted only my own scratch copies.

---

### Inventory and verdicts

The pr-report inventory is folded into this table. Lines are at 92cbce1f unless noted.

| # | Item | Where | Used by | Stated reason | Verdict |
|---|---|---|---|---|---|
| 1 | Cycle budget counts shop-cycled units (4), not refreshes | bot_quilboar.gd:31, 84, 130–137 | H1 bot | Phase 1 calls, ask 1 | keep |
| 2 | Created cards outside the 4-cycle budget (4cf1a219) | bot_quilboar.gd:228, 266 | H1 rerun | H1 calls: "cycle cap follows the paper" | keep |
| 3 | Trailblazer's combined choice goes to Foodie, then Miner, before a Gem Day | bot_quilboar.gd:270, 315 | bot | Phase 1 ask 1 | keep |
| 4 | 2-flex cap, applied from R1; flex sold first | bot_quilboar.gd:32, 141, 216, 301 | bot | Phase 1 ask 1 | **ask 1** |
| 5 | `quilboar_line.json` deleted | — | — | Phase 1 ask 2 | keep |
| 6 | Three dead hooks removed | quilboar_choices.gd:35; reference_quilboar.gd `_card`; combat_world.gd | — | Phase 1 simplify | keep |
| 7 | A refused flag fails loudly | reference_quilboar.gd:16–27; scale_overlay.gd:7; game_session.gd:73 | session | Phase 1 gap | keep |
| 8 | README: Phase 2 reads the Phase 2 dials | content/reference/quilboar/README.md | readers | Phase 1 ask 3 | keep |
| 9 | `reference_quilboar_freeze_size` flag (recruit, combat, bot modes, overlay key) | game_config.gd:40; reference_quilboar.gd:41; combat_world.gd:228; bot_quilboar.gd:458 | frozen arm only | port §11.2 H1 arm; question 8 | keep |
| 10 | Busker loop guard for Created free spells | effect_runner.gd:13; reference_quilboar.gd:180–195; recruit_rules.gd:699; recruit_context.gd:13, 35 | uncut arms (caps off) | port spec line 328 | **simplify 1** |
| 11 | H1 bench suite, capture fields, classify against the session library | bench_suites.gd:30, 109–123; bench.gd:219–228, 374, 519 | H1 driver | port §11.2 | keep |
| 12 | H1 driver (frozen plan, sealed sources, resumable chunks, config and roster checks) | tools/sim/quilboar_h1.py | runs | port §11.2; DECISIONS | keep |
| 13 | H1 report, the labelled T6=13 column, the gap section | tools/sim/quilboar_h1_report.py | h1.md | DECISIONS H1 calls | keep (wording gap below) |
| 14 | Rerun combiner | tools/sim/quilboar_h1_rerun_report.py | h1.md | "Rerun once, B and uncut only" | keep |
| 15 | Two frozen plans | tools/sim/evidence/quilboar-h1-plan.json, quilboar-h1-cycle-fix-plan.json | driver | criteria set before the run | keep |
| 16 | Compact lobbies, players, logs, receipts, checkpoints, summaries | tools/sim/evidence/quilboar-h1*/ | report; my rebuild | reproducibility | keep |
| 17 | Full fight captures, 154 files, 93.9 MB (including the superseded originals) | `*.fights.jsonl.gz` | hash checks only (archive_quilboar_h1_cycle_fix.py:45; checkpoint_quilboar_h1.py:31) | none stated | **ask 2** |
| 18 | Smoke evidence and `h1-smoke.md` (683 lines) | docs/ideation/reference/quilboar/h1-smoke.md | only the timing was used | a68ff118 "smoke timing budget" | **simplify 2** |
| 19 | Seven one-off evidence drivers | tools/sim/evidence/drivers/*quilboar_h1* | provenance | DECISIONS: drivers are committed | keep |
| 20 | Docs: h1.md, h1-status.md, READMEs, engine.md line | docs/ideation/reference/quilboar/ | readers | plan | keep |
| 21 | Paper model loads from a relative path, not /tmp | model/final3.py, presets3.py | report's paper | needed for offline accounting | keep |
| 22 | Tests: 2 GUT scripts (16 tests), 3 Python files (22 tests) | tests/core/test_quilboar_h1_*.gd; tools/checks/tests/test_quilboar_h1_*.py | gate | the fixes above | keep |
| 23 | Merge: 8 hand-resolved conflicts | below | — | merge message | keep |
| 24 | Merge: 2 auto-merged files that combine both sides | scale_overlay.gd:15–22; recruit_unit.gd:211–219 | — | — | keep |

Inventory sections with nothing in them:
- Scheduled or background: none (the sim runs were one-off).
- External services or libraries: none.
- Schema: the only change is the merged `reference_quilboar` mechanic entry.
- Deleted: items 5 and 6.

Size: range 1 changes 685 files (+17,668 / −71). 651 of those files are evidence: +14,118 lines and 101.4 MB.

### Probes

**1. Isolation after the merge: not widened.**
- The defaults are still `reference_quilboar: false`, `reference_quilboar_freeze_size: false`, `quilboar_ref_preset: "B"` (game_config.gd:39–41).
- All four presets still exclude `content/reference/*` (export_presets.cfg:11, 48, 105, 177).
- Field-library hashing covers units, heroes, spells, levers, schema and pass3 only, not reference content (field_library.gd:12). The `unit_library.gd` change only adds `add_configured_rulings`.
- The default path reads the flag but never the content:
  - every effect now calls `effect_allowed`, which returns true for non-reference players (effect_runner.gd:13);
  - `play_item` computes `created_free_spell`, which only that guard reads (recruit_rules.gd:699);
  - `validate_request` passes when the flag is off.
- These calls were added in ddd321e5 and change no behaviour with the flag off. The field regression test drops config keys that have defaults, so the three new keys don't break it.

**2. Merge resolutions: all eight keep both sides' intent.** I checked that every line each side added survives (except the single combined set line), that every removed line stays removed, and that the schema's sections union cleanly.
- **effects.json:** `reference_quilboar` sits next to `pass3_bog` and `pass3_hunter`. Queries match both parents.
- **combat_unit.gd:85–91:** gem fields plus `bog_frog_turn`.
- **recruit_context.gd:358–360:** `scaling_exempt` and `fixed_stat_reward` are OR'd and both return 0, so their order doesn't matter. Quilboar spells and Pelts both stay unscaled.
- **game_config.gd:** the reference keys plus `pass3_preset`.
- **recruit_carry.gd:8–22:** four distinct ops. Per-branch `var unit` was already the pattern on main.
- **recruit_extras.gd:122–127:** both blocks are added to `out`.
- **tribe_bonuses.gd:76–84:** `_show_bog_toll` runs first. That order is required: it calls `show_bonuses`, which clears chips, so the other order would erase the Gem chip.
- **check_units.py:345:** `{pass3_bird, pass3_fairy, pass3_bog, pass3_hunter, reference_quilboar}` are all exempt from golden doubling.

**Semantic clashes the textual merge can't show: none found.**
- **Board-scaled hero powers and spells:** the setting now defaults to following pass3, H1 sets it explicitly, and all three Quilboar spells are `scaling_exempt`.
- **Card arrivals:** they now go through `Pass3Hunters.arrival`, but only Pelts change, so Created Tunneler and Trapper cards arrive as before (pass3_hunters.gd:58–62).
- **In-fight copies** (Fetch, Hunters) have iid 0, and the combat gem ledger skips iid 0. Nothing leaks into the original's ledger.
- **Combat fast paths:** gem stats live in the permanent and combat fields. `golden_factor` isn't overridden, so the inlined health read is safe.
- **Bog state:** a separate key in fight rules and a separate carry op.
- **Latent:** pending gains intercept permanent buffs on `on_take` (combat_world.gd:72–74). A gem played on that trigger would record 0 in the ledger. No Quilboar card has an `on_take` trigger today.
- After the merge, `line_bog_engine` and `line_hunters_engine` would resolve to wave 2a's new line files. The frozen plans' source seal refuses to run on the merged tree, so old and new lines can't mix silently.

**3. H1 numbers: both headline figures match.**
- B post-fix R12: Quilboar median 259, paper 1,144, ratio 0.226.
- Uncut post-fix R12: Quilboar 747 against Birds 313.5, ratio 2.38. My bootstrap gives [1.51, 3.25], against the reported [1.50, 3.28].
- Pre-fix: 825.5 / 271 = 3.05 ([2.22, 3.90] against [2.19, 3.97]).
- All DECISIONS ratios match: 0.45 / 0.23 / 0.70 (rerun B), 0.46 / 0.24 / 0.57 (first-run B), and C's.

**4. Stop rule: honoured.**
- After the authorized fix (4cf1a219) and the rerun freeze (01963473), nothing in `src/`, `content/`, `tests/` or `tools/sim/*.gd` changes through 6bb7c730.
- The merge leaves the bot, reference and H1 files untouched.
- The shared-gap claim is dropped: h1.md:56 says "These data do not establish a matching shared gap", and DECISIONS:15 agrees.

**5. Harness follow-ups: none done here, and they don't apply directly.**
- This branch ran on cc6d26d5, before harness review 6 merged (1ab3bc5e is not an ancestor of 6bb7c730).
- H1 uses its own driver with no bans.
- That driver also aborts a chunk on any bad capture, the behaviour review 6 asked the harness to replace.
- After the merge, the harness still aborts on a contaminated trial (HARNESS.md:889–892). All four follow-ups are still owed by the harness worker.

**6. Owner misattribution: none.** No range-1 line mentions the owner. "The orchestrator authorized one rerun" is correct.

**7. Test cost: small.**
- Two GUT scripts, 16 tests, all unit-level with no lobby or whole-game test. I couldn't time them; read their times from the Actions junit on 92cbce1f.
- Three Python files, 22 tests: 1.15 s together.
- The 101 MB of evidence is checked out by every Actions job (ci.yml:33 and :126).

### Simplify
1. **Busker guard reaches native seats.** `setup` marks every seat in a reference lobby (reference_quilboar.gd:72). So under caps-off, native Created 0-cost spells also get only one Busker refund a turn: Triple Rewards, and after the merge, Pelts. Wave-1 accounting ran caps-off without the guard. Fix: key the guard on `qb_` spells (Blood Gem, Gem Day), and add one test with a native seat in a reference lobby.
2. **`h1-smoke.md`:** cut it to the timing lines. `quilboar-h1-smoke/progress.json` already holds the timing.

### Asks, in detail
1. **Strategy.**
   - *Flex cap.* The cap applies at every round, and test_quilboar_h1_switches.gd:228–240 pins the empty-slot behaviour at R4. The port's research says BG winners' boards are 35–45% Quilboar before turn 6, and its policy says "Before R6 flex". But it also lists `max_flex_kept: 2` inside that policy, so the spec is ambiguous. In B post-fix the seat holds about 1.9 off-tribe units from R4 to R7.
   - *Hogrider.* 39% of B seats lack Hogrider at R12. Seats with it average place 2.9 with an R12 median of 313. Seats without it average 5.5 with 179.
   - *Curve.* The real B curve matches paper's 2–3 rounds late at R9–R12, and about 1 round late at R15–R16.
   - *Suggested line to the owner:* "The bot follows the guides from R6. Its early board is thinner than BG players' and Hogrider comes about a round late, so ~750 uncut is a floor."
2. **Fight captures.** Keep the compact files in git. Move `fights.jsonl.gz` to `build/` or a release asset, with their hashes kept in progress.json, unless H2 is scheduled.
3. **Next step.** The port gates playtests on criterion 1 passing (§11.4). Accounting also fails for 3 of 4 native lines, so it can't gate future steps as written.

### Gaps
- **Question 8 not logged.** Pre-fix uncut against frozen on the same seeds: 825.5 against 175.5 at R12, so the third axis is the gap. Frozen sits between Hard (144) and Birds (283).
- **Paper's timing lesson is contradicted but not logged.** Paper says proportional tribes catch Quilboar by R13–R15. At B, Quilboar trails Birds at R12 (259 against 309), then leads 2.1× at R13 and 3.2× at R15.
- **The native lines are pre-wave-2a.** The plan's `line_versions` field says Bog, Hedgerow, Hunters and Oozes use "legacy engine profiles". DECISIONS' "5.5–7.7× the other lines" doesn't say so.
- **The native range is misquoted.** h1.md:49 and quilboar_h1_report.py:410 give 0.17–0.44×. The wave-1 accounting has four lines at 0.17–0.72×: Tempo's 0.72× is inside the band. The conclusion stands, because uncut's 0.121 is below all four.
- **Birds moved 271 → 313.5 between seed sets with identical Birds code,** so most of the 3.05 → 2.38 drop is seed noise. Both intervals exclude 4, so the verdict holds.

### What I'd run with Godot
1. The Actions gate on 92cbce1f (already running).
2. `tests/core/test_quilboar*.gd`, `test_quilboar_isolation.gd` and `test_field_normal_regression.gd`. The last checks the per-effect hook added in ddd321e5 with the flag off.
3. An unfrozen 5-lobby `suite=quilboar_h1` uncut smoke, to confirm the reference still plays with wave 2a Bog and Hunters seated.
4. One new test: a native Busker seat casting two Pelts caps-off in a reference lobby.

Paths: target worktree `/home/alex/code/Bramble-ideation-sol`; H1 report `/home/alex/code/Bramble-ideation-sol/docs/ideation/reference/quilboar/h1.md`; bot `/home/alex/code/Bramble-ideation-sol/src/core/bots/bot_quilboar.gd`.
