# Scope review: wave 1 (c74c2b9..6a54286)

Fresh scope-reviewer, 9 Nov 2026. Saved by the orchestrator from the reviewer's hand-back.

## Summary

**Inputs.** I had the target, the owner's words and the approved plan. The orchestrator's brief to the worker wasn't in my inputs or the repo, so I judged the worker's additions from its own notes in `wave1-build.md`. I didn't write the report to the scratchpad path because my harness doesn't allow report files. The caller should save this message.

**Counts:** 13 keep, 1 cut, 4 simplify, 5 ask.

**Original problem:** The change moves it in mechanism for two of the six tribes: homecomings double, Rings are uncapped and multiply by a growing Ring size, Midsummer doubles, there are carry holders and proportional answers. Nothing measures it yet, which the plan expects. In my weak sanity lobbies (Hard bots), the top Bird boards reached 1,154 and 2,590 by round 15, but five of eight Fairy seats were still at Ring size 1 at round 12.

**Cut**
1. `wave1-build.md:11` says "As confirmed by the owner" about Cluricaun. The owner never said this. It comes from the orchestrator's amendments 1 and 7.

**Ask**
1. Cluricaun grows +0.25 per tier-up. The worker turned amendment 1's "every 4th End of Turn" into a quarter-size step. The critique's line is +1/+1 per tier-up. The worker's version adds fractional Ring sizes and "+0.25" card text.
2. Jack Daw ships with a permanent steal. The critique's call is fight-only, and permanent only if Birds fall below the band.
3. The frozen pass 2 Birds and Fairies stay: a 1,584-line definitions file, 39 test files and 22 mechanics only those tests use. Delete them, or log them as the rollback?
4. Nothing reads `tools/sim/lines/*.json`. Will the harness?
5. Every Bird and Fairy bot route gets a guessed power prior of 3, and Hard rarely thanks Shy Fairies. Are Hard bots the checkpoint 2 opponents?

---

## What I ran and what I didn't

- I read the whole diff and the scope documents at `6a54286` using `git show` and `git diff`. I changed nothing in the worktree.
- I did not rerun the full gate. I read the worker's `build/check/gut.log` (19:25, between `d83b4ae` and `6a54286`): 163 scripts, 1,779 tests, 29,298 asserts, all passing.
- I extracted a temp copy of `6a54286` into the scratchpad and ran Godot under the shared lock and memory cap:
  - The pass 3 core tests passed, 92 of 92.
  - The bot tests passed, 15 of 15.
  - I broke 16 guards one at a time, plus one double break, and reran their tests (table below).
  - I ran a probe comparing the text generator against the authored card text.
  - I ran 2 Hard lobbies for board totals and 3 Hard lobbies for event counts.
  - I re-fought the 12 replay fixtures with the order rule forced on.
- I extracted a temp copy of `c74c2b9` and re-fought the 12 fixtures there: all 12 identical.
- One mutant (played-this-turn guard broken, with the bot tests in the same run) ran 3.5 minutes while holding the lock, so I killed it. The bounded reruns finished.
- I deleted both temp copies afterwards.
- I did not run the UI tests, lint or export. I did not open `docs/ideation/evidence/wave1`, which another session was writing after the change's end.

---

## 1. Inventory

The only intent sources inside the change are the commit subjects (no bodies) and `wave1-build.md`. Scope comes from the plan, `DECISIONS.md`, the pass 3 README amendments and the two design files.

### Schema and data
1. **`content/pass3/rates.json`**
   - What: 42 rate keys (23 Birds, 19 Fairies).
   - Used by: `Pass3Rates` (`src/core/pass3_rates.gd`), the engine, the card text and the bots. Every key is read in `src`.
   - Stated reason: DECISIONS, "Every engine rate is a data dial".
2. **32 unit files rewritten** (16 Birds, 16 Fairies)
   - What: each carries a `pass3_bird` or `pass3_fairy` mechanic with an `ability` and a `factor`.
   - Used by: the pool and the engine.
   - Stated reason: plan step 3, wave 1.
3. **`content/schema/effects.json`**
   - What: parameters for the two new mechanics. The Ring, Fly South, Nest and Egg reminders are rewritten, and "Ring size" is new.
   - Used by: the library and the UI.
   - Stated reason: the designs.
4. **`content/spells/golden_egg.json`**
   - What: a 0-gold token spell, not in the pool.
   - Used by: Mother Goose.
   - Stated reason: the Birds design.
5. **`nest_egg` changes from 0/2 to 0/1**
   - Stated reason: cross-tribe §7, Birds data.
6. **12 prototype Bird and Fairy bodies set to `pool:false`**
   - Stated reason: §7 says to retire them. Amendment 12 says "when wave 2 lands".
7. **New player and unit state**
   - What: `pass3_content`, `pass3_loop_guards`, `pass3_fairies`, `ring_size` (a float) and `pass3_rates` on the player (`player_state.gd:9-14`). Unit counters: `egged`, `pass3_home_round`, `stork`, `pass3_turns_stayed`, `pass3_midsummer`. Away entries get `missed_fight`. Fight and ghost rules carry `ring_size`, `away_specs` and `pass3_content` (`recruit_extras.gd:108`).
   - Stated reason: the designs ("Snapshots and ghosts carry ring_size").
8. **`tests/core/data/pass2_wave1_units.json`** (1,584 lines)
   - What: 45 frozen definitions from `c74c2b9`.
   - Used by: `tests/core/legacy_wave1.gd` and 39 test files.
   - Stated reason: none in scope. The worker says: "Old-design Bird/Fairy regression suites explicitly opt into frozen c74c2b9 card definitions".
9. **`tests/core/data/pass3_legacy_replay.json`**
   - What: 12 captured `c74c2b9` fight results.
   - Used by: `test_pass3_combat.gd:454`.
   - Stated reason: proposed by the orchestrator ("exact replays").
10. **`tools/sim/lines/birds.json` and `fairies.json`**
    - What: copies of the designs' line policies.
    - Used by: nothing yet.
    - Stated reason: the worker says they "preserve the synthesis policies".
11. **Bot hints and 7 strategy files**
    - What: hint and route changes. Every Bird and Fairy route's `power` becomes 3 (Highway was 8, Passage 3, Summer and Winter 1).
    - Stated reason: the worker says "provisional route priors pending fresh measurements".

### Features
1. **Birds, recruit phase**
   - Homecoming doubles a Bird once (`pass3_birds.gd:31`).
   - A Bird that has missed a fight is flagged (`pass3_birds.gd:26`, `recruit_rules.gd:209`).
   - A Bird played this turn can't fly (`held_units.gd:194`).
   - Early recalls need a missed fight (`held_units.gd:247`, `:281`).
   - Golden Egg (`pass3_birds.gd:60`, `recruit_rules.gd:706`).
   - Dunnock, Redbreast and Cuckoo shares, Stork's counter, Tern's flock, Goose's Eggs, the Lump's aura, trip lengths from the rates.
2. **Birds, combat** (`pass3_bird_combat.gd`): Jack Daw's steal, Tom Tit's Damage Reduction 50%, Mag Pye's text going to the biggest Bird, the Lump, Redwing's Eggs, the Ratchet dropping in once per Nest, the Whistlers' halving and the seven-Birds omen.
3. **Fairies, recruit phase**
   - A Ring is a count times your own Ring size (`pass3_fairies.gd:17`, `board_upkeep.gd:24`), with no cap.
   - Nan, Chaser, Annis (End of Turn and after any sale), Sally.
   - Cluricaun grows +0.25 on tier-up (`pass3_fairies.gd:140`).
   - Lob, Silky, the Monarch's shared clock, the Queen's tithe.
   - Copy guards (`_is_grower` at `pass3_fairies.gd:273`, `_once_event` at `:292`).
4. **Fairies, combat** (`pass3_fairy_combat.gd`)
   - Witch.
   - Hob shields the biggest Fairy, after Fetch has copied.
   - Fetch copies the Fairy behind at half.
   - Wisps, Belladonna across, Changeling's attack count.
   - Reel's dance budget per Ring.
   - Shy units ignore Rings (`combat_rings.gd:26`).
5. **Start of Combat order, see-through Bellies, reading-order ties for "biggest"** (`pass3_combat.gd:58`, `target_select.gd`). Stated reason: amendment 4.
6. **Extra End of Turn firings skip `every` counters and doubling steps** in any data effect while pass 3 content is on (`pass3_trigger_guards.gd`, `effect_runner.gd`). Stated reason: amendment 11.
7. **Ring spells add Rings at the caster's size.** Shop text reads "Ring a slot N times." (`pass3_views.gd:45`).
8. **Shop and UI overlays**: Fetch's combat-start stats, Stork's pip, the Lump's share, the egged rim, the away-tray landing preview, the Ring badge with its count, Ring size and Midsummer chips, Golden Egg aim filter. Stated reason: the designs' UI lists.
9. **Card text rewritten from rates whenever a rate is overridden** (`pass3_text.gd`, 426 lines; `scale_overlay.gd`). Stated reason: none. Worker addition.
10. **Hard bot support** (`bot_pass3.gd`, 489 lines, plus edits to brain, eval, placer, held, content5 and eggs).
    - Covers flights, Tern, the omen, the low-Health guard, the Lump's seat, Golden Egg target and hold, placement, the Queen's tithe, Annis churn (at most 8 actions), Shy thank timing and Ring spell aims.
    - Also changes every tribe: all aimed spells are now filtered through `item_aim_problem` (`bot_brain.gd:640`, `:675`).
    - Stated reason: DECISIONS "bot legality".

### Config
1. `pass3_content`: false by default, true in `full_game`. It is forced true by `detect_pool` (`pass3_birds.gd:165`) whenever the pool holds new cards. Only the legacy tests set it false (`recruit_kit.gd:17`).
2. `pass3_loop_guards`: true by default. Only the counterexample tests set it false.
3. `pass3_start_order`: null means auto, or true or false. Only two tests set it false.
4. Every key in `rates.json` can be overridden through `GameConfig`.

### Public interfaces
1. `get_state` adds `pass3_content`, `ring_size`, `midsummer_left` and three rates (`game_session.gd:180`). Unit views gain egged, Stork count, home stats and Ring count.
2. New classes: `Pass3Rates`, `Pass3Birds`, `Pass3Fairies`, `Pass3Text`, `Pass3Views`, `Pass3Combat`, `Pass3BirdCombat`, `Pass3FairyCombat`, `Pass3TriggerGuards`, `BotPass3`.

### Internal machinery
1. Two mechanics that dispatch on an ability name. The golden `factor` is skipped by `check_units.py:332`.
2. An event serial bumped on every recruit event for every player (`recruit_events.gd:48`). Only `_once_event` reads it.
3. Lazy fighters for units inside Bellies, and hidden buffs carried back to the recruit phase (`pass3_combat.gd:166-230`).
4. Fractional Ring size with rounding once per slot (`_write_stats`, `_sync_totals`).
5. The `LegacyWave1` library and a legacy flag in the recruit kit. Old branches stay in `held_units` and `board_upkeep`. 22 mechanic ids are now used only by the frozen definitions, including `hex`, `rainbow`, `teind`, the old `cuckoo` and the old `tom_tit`.
6. `keyword_text_overrides` (`unit_library.gd:197`).

### Deleted or deprecated
1. The old Bird and Fairy card definitions are replaced in content. Their scripts stay.
2. `fight_rules` moved from recruit rules to `recruit_extras`.
3. 12 prototypes left the pool.

**Scheduled or background, and external: none.**

**Not requested:** data items 8, 10 and 11; features 9 and the all-tribe part of 10; config items 1–3; internal items 2, 4 and 5.

**Size:** 191 files, +9,164 / −733 lines, including 3,107 lines of test fixtures. Items per section: data 11, features 10, config 4, interfaces 2, internal 6, deleted 3.

---

## 2. Answers to the six probes

**Do the rules match the designs plus amendments, and is the text true?**
- I compared all 32 cards and both golden states, text and code, against the two design tables and the amendments. They match, with these exceptions:
  - Cluricaun's step value (Ask 1).
  - Jack Daw's default (Ask 2).
  - One Swallow's card face drops "Its trips last 1 turn" from amendment 10's line (`cross-tribe.md:343`). The details text and the sell note carry it instead.
- Dunnock stays 2/3. §6 suggested 2/4, but that isn't in the adopted amendments or §7, so 2/3 is correct for this scope.
- At default rates, the card text, golden text and shop overlays match the code, with two caveats:
  - Cluricaun says "+0.25/+0.25", but slots round up once each. A slot with 1–4 Rings visibly gains +1/+1.
  - Under any rate override, the generated text is clumsy, and Tom Tit's is wrong (Simplify 1). If `rates.json` itself is edited, the text goes stale.

**Are the loop guards real?** Yes. I broke each guard alone in the temp copy:

| Guard | Broken result |
|---|---|
| A homecoming doubles once (`pass3_birds.gd:33`) | 1 test fails |
| Golden Egg once per Bird (`:55`) | 3 fail |
| A Bird played this turn can't fly (`held_units.gd:194`) | 1 Birds test and 1 bot test fail |
| Old Tern only calls Birds that missed a fight (`:281`) | 1 fails |
| The missed-fight flag in early recall (`:247`) | **nothing fails**: the old "left before this round" rule gives the same result |
| Extra End of Turn firings, any data effect (`pass3_trigger_guards.gd:10`) | 2 fail |
| Dunnock repeat guard | 1 fails |
| Monarch repeat check alone (`pass3_fairies.gd:171`) | **nothing fails**: the shared-event check also stops it |
| Shared-event check alone (`:292`) | **nothing fails** |
| Both Monarch checks together | 2 fail |
| Strongest-copy check (`:273`) | 3 fail |
| Queen repeat guard | 1 fails |
| Ratchet once per Nest (`pass3_bird_combat.gd:190`) | 1 fails |
| Fetch never reuses a target (`pass3_fairy_combat.gd:54`) | 1 fails |
| Dance budget per Ring (`:195`) | 3 fail |

**Is today's pool unchanged with the switch off?**
- The 12 fixtures really are from `c74c2b9`: re-fought there, all 12 are identical.
- At the change's end they replay exactly with the order switch off. They also replay exactly with it forced on, because none of these boards has a biggest-enemy effect.
- But a real game now has no "switch off":
  - The old Birds and Fairies are gone from content.
  - `detect_pool` forces pass 3 on, and the order rule defaults to on.
- So other tribes see these changes in real games:
  - Ring spells add Rings at your Ring size, with no +4 cap.
  - Biggest-enemy effects at Start of Combat move later (only levers and heroes have them today).
  - Extra End of Turn firings are guarded (only matters with the doubler lever).
  - Bots filter all aimed spells.
- The replays cover combat only, not the recruit phase.

**Are the rates really data?** Yes. All 42 keys go through `Pass3Rates` and can be overridden in `GameConfig`. The one catch is the card text: it follows overrides, but not edits to `rates.json` (Simplify 1).

**Is anything credited to the owner that the owner didn't say?** Yes, one line (Cut 1). There is no owner note about it, the portal inbox is empty, and DECISIONS marks both amendments "Picked (orchestrator)".

**Can the Hard bot play both tribes legally?**
- Yes. Bots act through the same rules calls that reject illegal moves. The worker's lobby and my three 15-round lobbies (8 Hard seats, Bird and Fairy routes only) finished with no engine errors.
- The Bird engine runs: 109 flights, 108 homecomings, 125 Stork recalls, 19 Golden Eggs.
- The Fairy engine mostly doesn't:
  - 8 Midsummers and 5 Ring-size growths in total.
  - Shy Fairies were thanked only 5 times.
  - Lob was sold 5 of the 6 times it was bought (a sale forfeits his bank), Hob 9 of 10, Cluricaun 3 of 3.
- Board totals in my two printed lobbies:
  - Median board about 140 at round 12, against a reference of about 500.
  - Top boards were Birds: 501 and 534 at round 12, 1,154 and 2,590 at round 15.
  - Bot play is a sanity line only, per the owner's 9d note.

---

## 3. Verdicts

| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| K1 | The 32 cards' rules | keep | They match the designs and amendments 2, 3, 7, 8 and 10 (exceptions above); 92 of 92 pass 3 tests | see Asks 1–2, Simplify 4 |
| K2 | Golden Egg, 0/1 Egg, Wisp | keep | Birds design; §7 | — |
| K3 | Birds engine | keep | Birds design, "Engine support needed" 1–15 | — |
| K4 | Fairies engine | keep | Fairies design's engine table | — |
| K5 | Start of Combat order, see-through, reading-order ties | keep | Amendment 4 | — |
| K6 | Loop guards | keep | Amendment 11; table above | — |
| K7 | `rates.json` and overrides | keep | DECISIONS "data dial"; all keys read | — |
| K8 | Hard bot support | keep | DECISIONS; lobbies ran clean | Log the all-tribe aim change (`bot_brain.gd:640`, `:675`) |
| K9 | UI overlays | keep | The designs' UI lists; `test_pass3_ui.gd` | — |
| K10 | Replay fixtures (proposed by the orchestrator) | keep | Re-fought on `c74c2b9`: 12 of 12 | — |
| K11 | `pass3_loop_guards` flag | keep | The counterexample tests depend on it | — |
| K12 | 12 prototypes out of the pool | keep | §7; they have no set, so `full_game` shops never offered them | — |
| K13 | `wave1-build.md` | keep | It records the rulings | Except Cut 1 |
| C1 | "As confirmed by the owner" | **cut** | `wave1-build.md:11` | Say it is the orchestrator's reading of amendments 1 and 7 |
| S1 | `Pass3Text` | **simplify** | It only rewrites when a value differs from `rates.json` (`pass3_text.gd:31`). The test at `test_pass3_rates.gd:23` can't fail. With every rate treated as changed, 35 text fields differ from the authored text, and Tom Tit reads "Your biggest Bird other has Damage Reduction 50%." (`pass3_text.gd:133-135`) | Keep one source of text, generated from the resolved rates with fraction words, or check authored text against `rates.json`. Fix Tom Tit's word order |
| S2 | The off path of `pass3_start_order` | **simplify** | The fixtures are identical with the rule forced on; only 2 tests set it off | Remove the flag, or mark it test-only |
| S3 | Missed-fight branch in `bring_home` | **simplify** | `held_units.gd:247`; breaking it fails nothing | Drop it, or add a case where the two rules differ |
| S4 | One Swallow's card face | **simplify** | `one_swallow.json` vs `cross-tribe.md:343` | Use the amendment's line |
| A1 | Cluricaun +0.25 | **ask** | `rates.json:25`; the critique's line at `cross-tribe.md:153` is "+1/+1"; README line 31's g = ¼ was the timer setting ("every 4th End of Turn"). In my lobbies Cluricaun never produced a fractional size | Pick +1/+1, or keep 0.25 and log why |
| A2 | Jack Daw permanent by default | **ask** | `cross-tribe.md:129-131` | Pick the default that goes to checkpoint 2 |
| A3 | Frozen pass 2 Birds and Fairies | **ask** | The fixture file, `legacy_wave1.gd`, 39 test files, 22 mechanics, the `pass3_content` flag | Delete them, or log them as the rollback |
| A4 | `tools/sim/lines/*.json` | **ask** | `git grep` finds no reader | Say who loads them, and when |
| A5 | Bot priors and Fairy play | **ask** | `birds_highway.json:40` (8 becomes 3); 5 thanks in 3 lobbies | Decide whether Hard bots are the checkpoint 2 opponents |

## 4. Gaps
- Tom Tit's generated text is wrong, and the test checks only that "25%" appears (`test_pass3_rates.gd:83`).
- Nothing checks that the authored card text matches `rates.json`.
- The shared-event check is the only guard for a unit that carries the same growing ability twice (printed plus borrowed). No test covers that case.
- The rulebook isn't updated for the rule edits the Fairies design lists (8.5.4, the Ring cap; 12.1.7, Silky) or for the new Fly South and Egg rules.
- The built tribes aren't measured yet. The plan puts that in the harness after checkpoint 1.

## 5. Original problem
The change moves it in mechanism for Birds and Fairies, but it is unmeasured. Value-wise, Cluricaun's +0.25 cuts against the owner's "very, very much too low".

## 6. Open questions
These are Asks 1–5 above.

Scratchpad files from the probes (small logs and scripts only; the project copies are deleted):
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/mutate.py`
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/mutants2.out`
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/mut-T_text_generator.log`
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/mut-E_events.log`
- `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/mut-L_lobby.log`

---

## Follow-up review: 6a54286..95128ed

**Counts:** 14 keep, 0 cut, 1 simplify, 2 ask.

- Every call landed:
  - Cluricaun grows +1/+1 a tier-up, as a dial.
  - Jack Daw stays permanent.
  - Text comes from the generator only.
  - Tom Tit is fixed.
  - The order switch is test-only.
  - One Swallow shows its 1-turn trip.
  - The rulebook is updated.
- The fixes add nothing unrequested.
- **What the reviewer ran:**
  - The pass 3 suites passed 109/109 and the bot tests 20/20.
  - Seven fixes were broken one at a time, and a test failed each time.
  - The full gate wasn't rerun. The worker's log shows 1,791 of 1,791 passing.
- Fairy Ring size at R12 went from 1.25 to 2.17 in the worker's lobbies. That is not yet measured on the harness.

**Items:**
- **Simplify 1:** `attribution-audit.md` must note that the quarter-step reading was corrected.
- **Ask 1:** the away tray doesn't show each Bird's stats now and at landing (`birds-pass3.md:627`; `recruit_screen.gd:525` shows an empty panel). The reviewer recommends fixing it first.
- **Ask 2:** layout problems found in the screenshots: the Ring badge overlap, the phone End Turn line cut off, and PC shop names wrapping.

**Verdict:** clear to merge after checkpoint 1, once the two asks are decided.
