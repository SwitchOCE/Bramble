# Wave 2a pool rules review: f574eaf..acf3d63 (scope reviewer, 10 Nov 2026)

## Scope review: `acf3d63` (`f574eaf..acf3d63`, ideation/wave2a)

**Inputs.** I had all three inputs: the target, the owner's words and the plan text. I did not see the orchestrator's brief to the worker. The build doc quotes from it ("as explicitly requested" for the Fetch change, "the orchestrator relayed 09h"), so I can't always tell the orchestrator's proposals from the worker's own choices. Pushback (pr-interrogate section 4) happens later with the owner.

**Counts:** keep 18, cut 0, simplify 2, ask 3.

**Does it move the original problem (09a, the scale is too low)?** A little, and nothing measures it.
- What adds power: the Fetch twin is full in B, spells and Brother Bracken now grow with the board, and Supper's +3/+3 cap is gone.
- What adds none: the gain queue and the loop guards.
- The commit says so itself: "No round-size targets are measured here" (`rates.json` notes).
- The plan expects the median to come from the Bog/Hunters commits, W2b and the paper B/C values.

**Ask items (the orchestrator's call):**
1. **C preset values.** The worker doubled 16 Birds/Fairies rates and set the spell dial to 20% (`content/pass3/rates.json:55-72`, marked `"provisional": true`). The plan says "A paper workflow writes B's and C's values during wave 2." Keep them as a labelled placeholder, or leave C empty until the paper values land?
2. **`gain_landed` event** (`src/core/pending_gains.gd:72`). It is logged, but nothing reads it. `RecruitView.event_note` has no case for it, so the queued gain arrives at Start of Turn with no cue. Who reads it, and when? Step 3's animation is the likely owner.
3. **Scaled card faces.** They read, but some get long:
   - Brother Bracken: "up to +50%/+50% (minimum +5/+5)" puts a floor on a cap.
   - Harvest Supper: "gain 10% of your board's lower average stat as +Attack/+Health (minimum +1/+1)".
   - Elderflower Cordial now carries two percentage pairs.

   Fix the wording now, or leave it to the step 3 audit?

**Simplify items:**
1. `src/core/game_config.gd` removed `scale_hero_spell_percent` from `defaults()`. On the merged tree, `tools/sim/bench.gd:150` asserts `config._values.has(key)`, so a bench or shard override of the spell dial now fails. Keep the key as a `null` default, as was done for `scale_hero_spell_stats`.
2. `Pass3Rates.preset()` (`src/core/pass3_rates.gd:22`) is called only by `test_pass3_presets`. `resolved(config)` with `pass3_preset` set does the same job. Delete it.

**Clear to merge after a merge with ideation/main?** Not yet. One fix and a full gate first:
- **Textual merge:** clean. `git merge-tree cd07673 acf3d63` exits 0; only `src/core/game_session.gd` changed on both sides, and it auto-merges.
- **Semantic conflict:** the merged tree fails `tests/core/test_field_combat.gd:23` (`test_pre_lever_captures_keep_capped_defaults`): `FightCapture.library_for(values, source)` is expected to equal `source`. It no longer does, because pass 3 now always builds a configured library (`src/core/effects/scale_overlay.gd:16`). The test's caps-on half still holds; only the identity check is stale. Update that test, or the overlay condition, at merge.
- **UpsetCombat whole-library audit:** fine on the merged tree.
  - `test_upset_combat` passes 15/15.
  - My probe captured real `full_game` lobbies on the merged tree: 63 fights in B and 62 in C. `UpsetCombat.prepare` found 0 unsupported, and `run_input` matched `FightCapture.replay` in every fight.
- **Biggest-enemy ordering:** this commit doesn't touch it. The only `combat.gd` hunk is the Pack cleave at line 626. Wave 1's order and see-through code and tests are unchanged, and `test_pass3_combat` passes 43/43 on the merged tree.
- **What I ran on the merged tree:**
  - 20 GUT scripts (200 tests): 199 pass, and the 1 failure is the one above.
  - Harness Python tests: 124 pass.
  - Gate Python checks: 57 pass.

  The full merged gate still needs a run after the fix.

---

## Answers to the brief's questions

**Anything beyond the pool rules?** Yes: provisional A/B/C presets (planned for wave 2, but their values belong to the paper workflow), a Ring-count exception, a configured-rulings reader path, and a replay fixture. Each is judged below.

**Birds/Fairies changes beyond Fetch 0.5 to 1.0 in B?**
- **In B, no other Birds/Fairies dial moves.** The planned pool-wide rules do reach them:
  - spell and hero scaling;
  - Supper's ceiling;
  - Great Lump no longer cleaves when it joins a Pack.
- **Ring spells keep their printed count** (`src/core/effects/flat_stat_scaling.gd:40`), so Fairies' Rings don't scale into dozens.
- **Evidence:** 8 fixed-dial Birds/Fairies/Oozes/Hedgerow fights replay byte for byte against `f574eaf`.
- **In C, yes:** 16 Birds/Fairies rates are doubled (ask 1).

**Is hero and spell scaling generous enough, and does it read?** B aims at about 900 at R12, which is roughly 64/64 per unit:

| Effect | B | C |
|---|---|---|
| Pinch of Dust (1 gold) | +6/+6, about 1.3% of the board (flat was +1/+1) | doubles |
| Stand Behind Me / Bread from the Back, shared tribe | +12/+12 per unit | doubles |
| Cold Frame | +19/+19 after 2 turns | doubles |
| Harvest Supper | +6/+6 to every unit of the tribe, now and later, once a turn, stacking with no cap; about +84 a cast on a 7-unit tribe board | doubles |
| Last Orders at 10 gold | +50% to one unit | doubles |
| Brother Bracken at tier 5+ | +50% to each of up to 5 units, every fight | doubles |

- Gains scale with the recipient, so they favour the carry. That fits 09a's concentration.
- 10% is the old mechanics-build default (`docs/ideation/evidence/mechanics-build.md:37`), not a number sized for B. C's 20% is a 2x guess. I propose no new bar.
- **Gap:** Old Mother Mousewife's Mouse stays "stats equal to your tier" (6/6 at most). It is the one stat hero power left unscaled.

**Are the loop guards real?** Yes. In a scratch copy I removed each guard:
- Pack joiner guard removed: `test_pack_joiners_never_cleave_but_their_leader_still_can` fails (`[14, 14] != [20, 20]`).
- Scripted-engine guard removed: `test_scripted_engine_guards_doublings...` fails (`[40] expected to equal [20]`) in two samples.
- Wave 1's existing guard on extra triggers repeating a doubling or moving a countdown is unchanged; a new test also covers it on extra When played firings.

**Is the gain queue readable?**
- **In the fight:** a numeric "+N/+N" badge on the portrait, kept apart from the current stats. The one-tap reader adds "Pending gain: ... Arrives at your next Start of Turn." The combat log adds one line.
- **Main screen:** nothing new on it, which fits 09e.
- **Missing:** a cue when the gain lands (ask 2).

---

## pr-report (facts only)

1. **Schema / data**
   - `content/pass3/rates.json`:
     - What: restructured into `rates`, `presets` {A, B, C}, `default_preset`, `provisional` and `notes`. B is the shared map, with Fetch at 1.0 (:31). A sets Fetch to 0.5 (:52). C doubles 16 rates and the spell percent (:55-72).
     - Used by: `Pass3Rates`. Nothing reads `provisional` or `notes`.
     - Stated reason: the plan's "The presets: B ... C ... A"; the B Fetch value from "the Fetch twin is full". C's values: the build doc only ("provisionally doubles").
   - `content/units/cradle_fetch.json`:
     - What: text changes from "half stats" to "full stats".
     - Stated reason: the plan.
   - `PlayerState.pending_gains`, `CombatUnit.pending_attack/health`:
     - Stated reason: amendment 6.
   - Replay fixture `tests/core/data/pass3_pool_replay.json` (1,238 lines), its capture tool `tools/checks/capture_pass3_pool_replays.gd` and its test:
     - Stated reason: the build doc ("fixed-dial replay fixtures").
2. **Scheduled / background**
   - `PendingGains.land` runs first in `start_phase` (`src/core/recruit_rules.gd:136`).
   - Stated reason: amendment 6, rulebook 3.2.1 step 0.
3. **Features**
   - Takes queue their gain (`src/core/effects/combat_world.gd:70`). Bridge Toad stands in for Soak (`src/core/mechanics/bridge_toad.gd:12`).
   - Triples merge queued gains (`src/core/recruit_rules.gd:494`). Elimination clears the queue. Tokens get nothing. A dead fighter keeps its gain. The cap reserves room for gains already queued.
   - Pending badge, reader line and log lines: `src/ui/widgets/card_view.gd:307,688`, `src/ui/widgets/card_detail.gd:430`, `src/ui/screens/combat_log.gd:404,623`, `tools/play/play_fight_log.gd`.
   - Take/bite timing rulings in Details: `src/core/effects/scale_text.gd:60-69`.
   - Pack joiners never Cleave (`src/core/combat/combat.gd:626`). Stated reason: amendment 11.
   - Scripted-engine doubling guard (`src/core/mechanics/scale_engine.gd:16`). Stated reason: amendment 11, "whatever doubler".
   - Scaling on with pass 3 (`src/core/game_config.gd:47,165`), with scaled faces. Stated reason: the plan.
   - Ring spells keep their count. Stated reason: the build doc.
   - Supper: no ceiling, still once a turn, and the bots follow (`src/core/tribe_bonus.gd:9,13`, `src/core/bots/bot_commitment.gd:23,30,80`). Stated reason: the plan.
   - Rulebook entries 3.2.1 step 0, 5.2.9a and the Cleave note.
4. **External:** none.
5. **Config**
   - `pass3_preset`: default B, values A/B/C. Set by tests and the capture tool. Step 5 lobbies and the step 6 portal setting would set it.
   - `scale_hero_spell_stats`: `null` follows pass 3; explicit true/false is kept for comparisons.
   - `scale_hero_spell_percent`: moved into the rates map.
6. **Public interfaces**
   - `PendingGains` (queue, receive, land, merge_copies).
   - Carry op `pending_gain`.
   - Events `gain_pending` (read by the UI) and `gain_landed` (read by nothing).
   - `TribeBonus.ceiling` and `TribeBonus.used_this_turn`.
   - `Pass3Rates.preset` (tests only) and `Pass3Rates.default_preset`.
   - `UnitLibrary.add_configured_rulings`.
   - `CombatLog.pending_gain_words`.
7. **Internal machinery**
   - Configured-rulings path: `src/core/effects/scale_overlay.gd:85`, `src/core/unit_library.gd:366`, `src/ui/card_rulings.gd:16`, plus the views.
   - The overlay is now always built under pass 3 (`src/core/effects/scale_overlay.gd:16`).
   - `RecruitRules.create` detects the pool before building the overlay, and `GameSession` keeps `_rules.library` (`src/core/game_session.gd:570`).
   - `_spend_acorn` moved to `src/core/recruit_carry.gd:72`, and the dying-card helpers moved to `CombatLanesView`. Stated reason: none, but both keep files under gdlint's 1,000-line cap (`recruit_rules.gd` was at 998 lines, `combat_screen.gd` at 997).
   - `Pass3Text` wording for "twice" and "double stats" (used only by C).
8. **Deleted:** `RecruitRules._spend_acorn` (moved); the `scale_hero_spell_percent` default in `GameConfig`.

**Unrequested:** C's values; `provisional` and `notes`; `gain_landed`; `Pass3Rates.preset`; the file moves (explained by the lint cap). **Size:** 59 files, +2,897 / -102 lines.

---

## Verdict table

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| Gain queue core | keep | amendment 6; `pending_gains.gd`; `test_pass3_pool_rules` 12/12 | none |
| Takes and Toad routed into the queue | keep | `combat_world.gd:70`, `bridge_toad.gd:12` | none |
| Badge, reader line, log lines | keep | amendment 6, "shown as a pending badge"; `test_pending_gains_ui` 7/7 | none |
| `gain_landed` | ask | `pending_gains.gd:72`, unread | ask 2 |
| Timing rulings in Details | keep | reader only; `test_configured_rulings` | none |
| Pack joiner guard | keep | amendment 11; mutation fails its test | none |
| Scripted-engine guard | keep | amendment 11; mutation fails its test | none |
| Scaling on with pass 3 | keep | the plan | none |
| Spell percent moved out of `GameConfig` | simplify | breaks `bench.gd:150` on the merged tree | null default |
| Scaled face wording | ask | probe faces above | ask 3 |
| Ring spells keep their count | keep | without it, wave 1's Rings would scale | none |
| Supper ceiling and bots | keep | the plan; `tribe_bonus.gd:9` | none |
| Preset mechanism | keep | the plan; step 5 needs `pass3_preset` | none |
| B Fetch 1.0 and its text | keep | the plan | none |
| A half Fetch | keep | the plan's A fallback | none |
| C values, `provisional`, C wording | ask | `rates.json:55-72`; plan assigns B/C values to the paper workflow | ask 1 |
| `Pass3Rates.preset()` | simplify | `pass3_rates.gd:22`, tests only | delete |
| Configured-rulings path | keep | the reader would otherwise show stale rules | none |
| Overlay always on under pass 3, create order | keep | needed for the scaled text | fix `test_field_combat.gd:23` at merge |
| File moves | keep | lint cap of 1,000 lines | none |
| Replay fixture | keep | evidence that Birds/Fairies are unchanged | recapture or retire at W2b (it also pins Oozes and Hedgerow) |
| Rulebook entries | keep | amendments 6 and 11, the plan | none |
| `test_pass3_combat` runs under preset A | keep | only Fetch differs; B is covered in `test_pass3_presets` | none |

**Cut:** none.

**Gaps:**
- The merged-tree failure above.
- Mousewife's Mouse is not scaled.
- Birds are not "raised to match" in B; that waits on the paper values.
- Until the Hunters commit, Hunter permanent gains have two timings: Takes queue, while Grizel's reward (`tests/core/test_hunters.gd:314`) and Jack Daw's steal land at once.
- Captures record the preset's name, not its rate values, so captured fights will replay differently once the paper B/C values change.

**Open questions:** asks 1 to 3.

---

## Scratch notes

- The project worktree is untouched (clean, at `acf3d63`).
- I ran everything on a scratch copy of the merged tree, then deleted it.
- My logs are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/` (`merged-tests.log`, `mutation-tests.log`, `run_review.sh`, `run_review.out`).
- That scratchpad is shared with another session. My `import.log` there may have overwritten an older scratch file of the same name.
