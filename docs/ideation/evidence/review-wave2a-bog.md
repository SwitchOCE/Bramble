# Bog build scope review (10 Nov 2026)

Fresh scope reviewer, range 1144ad6..9f03fe0b on ideation/wave2a. Verbatim report.

## Scope review: `ideation/wave2a`, `1144ad6..9f03fe0b` (feebc5a, 3bc385e, 9f03fe0b)

The brief had everything it needed: the target, the owner's words and the approved plan.

**Counts:** 23 keep, 2 cut, 1 simplify, 2 ask.

**Does it move the original problem (09a)?** In the rules, yes. In evidence, not yet. Every cap is gone and Bog's growth is now proportional, but the build doc has only rule tests. Nothing shows Bog compounding in real play.

**Cut**
1. **Tiddy Mun, His Highness and the Prince affect "the units beside this", not "the Bog folk beside this".** That breaks README amendment 2 (`README.md:34`) and the cross-tribe "Must" (`cross-tribe.md:382`). No logged reason exists; only the build doc's note at `wave2a-build.md:67`. This brings back the splash the Lollop lesson warned about: any carry next to a frog doubles every third fight.
2. **`tools/sim/lines/bog.json` fails ideation/main's line loader in five places.**
   - `low_roll` is an unknown key, twice (`:77`, `:154`).
   - `keep` holds prose where the loader wants card ids, three times (`:45-46`, `:125`).
   - Path after the merge: `test_wave1_lines.gd:9` calls `BenchSuites.reload_lines`, which calls `LinePolicies.load_profiles`, which asserts there are no errors. The merged tree's line tests and every harness load would break.

**Ask**
1. **Bog's paper B values landed before the wave 1 accounting check.** The "Paper values for presets B and C" call made that check a precondition (the doc labels them provisional at `wave2a-build.md:75`). Do they stay as the starting B until w1 measures wave 2a's head?
2. **Two cards' conditions are often false when their triggers fire in mid and late fights, and nothing measures how often.**
   - The Peat King needs an empty slot at a Sink, but the first Sinks usually come while your board is full. The design's own R12 example fails this way (`bog-pass3.md:400`).
   - The Peat Cutter is a 2/4 front mirer with no Bitter, so it usually dies to its first bite before any Sink.
   - Proposed: have w1's run report Peatlings raised per fight with the King on board, and Cutter gold per fight by round.

**Merge:** Not clear at 9f03fe0b. Fix the two cuts, then run the merged-tree gate. Then it waits on the fun probe gate, as before. The two asks don't block.

---

## Answers to your six questions

**1. Does the build match the design and the calls?** Yes, except the three faces in Cut 1.
- **Numbers:** they all equal preset B.
  - Soak keeps 2 (golden 4).
  - Nan, Tiddy and Ranocchio take ½ (golden the whole amount).
  - Every other dial is at its design value.
  - C raises only Soak, to 3/6, as `presets.md` says (`rates.json:49-77`, `:102-103`).
- **Tiers:** Tiddy is T4 at 3/5 and Jenny is T5 at 4/7, as the design says.
- **Timing** matches the design and the "Bog's three questions" call:
  - Soak lands at the next Start of Turn, and Nan and Tiddy pay at Start of Turn.
  - The opening runs Lantern, then Jenny, then the patches, then Sal.
  - The doubling and Ranocchio's gain land at once.
- **Readings in the build doc only** (generous or edge cases, not deviations):
  - the King's "twice a fight" counts only successful raises;
  - Jenny can move the Lantern's lured enemy off his patch, which defeats the lure in that case.
- **Text bug:** the schema's default Soak reminder has the direction backwards: "When this bites its own Mired enemy" (`effects.json:883`). Bog cards show the correct generated reminder, but `KeywordRules.text` falls back to the schema line (`combat_log.gd:245`, `unit_views.gd:18`).

**2. Rule (b): can each card's condition hold when its trigger fires?**

| Card | Holds? |
|---|---|
| Bridge Toad, Prima Donna, Jenny, Peat King, Lantern Man, Prince (Soak) | Yes. Mire forces exactly that biter onto the unit. A 1-Attack biter loses nothing (`bitter()`: loss is at most Attack − 1). |
| Natterjack Chorus | Yes. The lend is worked out from the live board each time. |
| Warty Nan, Tiddy Mun | Yes, whenever the last fight had Bitter bites. |
| Spitfire Sal | Yes. She runs after the patches, using last fight's Toll. |
| Madame Bufo | Yes. Mire forces her enemy to hit her. |
| Vaulting Hopkin | Yes. Checked on every back-row attack. |
| His Highness, Prince | Mostly. A Sink at Start of Combat from Sal always counts. Otherwise the 3/5 frog has to outlive the first Sink. The doubling lands at once, so his neighbours are alive. |
| Gideon | Once he is the fed Diva, yes. A small Gideon dies before he can hit back (`hit_back()` needs him alive); the build doc says so. |
| Signor Ranocchio | Plausible, not measured. Mirers die first, so late in a fight his Snap may find no Mired enemy. |
| Young Pretender | Fine early. Snap aims it at the Mired enemy with the most Attack, which is the one least likely to die to 3 damage. Text unchanged from pass 2; it's sold by R7–8. |
| Peat Cutter, Peat King | Partial (Ask 2). The King is the closest thing to a Cluricaun case. |

- The build doc's audit (`wave2a-build.md:116-131`) checks structure only, and says so at `:131`.
- No card has Cluricaun's structural mismatch.

**Rule (a): does the low-roll row remove the keystone?** It is written down but nothing applies it.
- `bog.json` says to remove Tiddy (Court) and the Prima Donna (Swamp) for the whole game.
- Nothing on this branch reads that file, and ideation/main's loader rejects the key (Cut 2).
- The design's paper low-roll row still only delays Tiddy (to R10).

**3. Does the cut fix leave the pass 2 rollback untouched?** Yes.
- feebc5a removes only the mark in the legacy copy path (`combat_moves.gd:60` at 1144ad6).
- Pass 3 copies are still marked: `become_copy` passes the `copied` field only when pass 3 is on (`combat_moves.gd:54`), and `combat.gd:281-282` marks the copy.
- The flipped test checks that with pass 3 off the copy is unmarked and the highest-Health pick takes it (`test_wave1_copy_targets.gd:248-257`).
- The Bog commit keeps the rollback too:
  - `pass2_bog_units.json` matches 1144ad6 exactly for all 23 Bog definitions; I checked each one.
  - The legacy tests are only re-pointed to that frozen library. `test_bot_lanes.gd` also pins the old strategy priors, because the live strategy files changed.
  - The 12 archived legacy replays pass (`bog-gate.log`).

**4. Do non-Bog tribes stay unchanged?** Yes in combat.
- The fixed-dial replay test and its fixture are unchanged in this range: 8 fights from f574eaf covering Birds, Fairies, Oozes and Hedgerow. They pass in the gate.
- The shared combat hooks switch on only when a Bog unit or Bog state is present (`Pass3BogCombat.prepare`, `is_bitter`).
- No non-Bog unit has Mire, Bitter or Snap (I checked every unit file). So replacing the old Mire scoring for every pass 3 bot seat (`bot_lanes.gd:74-77`) has no effect on them.
- Gaps:
  - Hunters and neutrals are not in the replay set.
  - A non-Bog bot holding one splashed Bog unit switches to the Bog placer (`bot_placer.gd:85`), and no test covers that.

**5. Does Bog compound in real play, or only on paper?** Only on paper so far.
- **What the build doc's evidence shows:**
  - The gate passes: 1,989 GUT tests, 72 Bog tests, and the fixed-dial and legacy replays.
  - There is no lobby run, no real board sizes and no R8–R14 growth figure.
  - The doc says itself the rates are "not evidence of reaching the plan's round-12 size targets" (`:19`) and that a real board check "remains necessary" (`:131`).
- **Why the effect in real play is likely smaller:**
  - Bog's main engine takes a share of the enemy's Attack. So it can only grow as fast as its opponents do.
  - Today three of the six tribes are still pass 2, and wave 1's committed lines reach only 0.17–0.72× of their paper boards.
  - Only the frog (×2 every third kiss, placement-dependent) and Tiddy's funnel can compound on their own.

**6. Is anything gold-plated?** Very little.
- The Bog bot is 528 lines, but the plan and design §7 ask for it.
- The scout drink preview and the "gain the Toll" lever are design items; the lever is off by default.
- Beyond what was asked: the `low_roll` metadata that nothing runs, and the Bog entries added to the wave 1 upset audit record. No code reads that file; it is a reviewer record.

---

## Inventory (pr-report)

1. **Schema and data**
   - Bog rate keys: 29 at `rates.json:49-77`, plus the C override at `:102-103`. Read by the Bog combat, growth and recruit helpers, the text generator and the bot. Stated reason: "provisional B rates" (commit title).
   - Unit files:
     - 16 pool bodies and 2 tokens rewritten (build doc `:61`);
     - 5 prototype bodies set to `pool: false`.
   - Schema additions: a `pass3` flag on `bitter`, the `pass3_bog` mechanic (with `ability`, `factor`, `restore`), and keyword reminders for Soak, Sink, Toll and kiss.
   - New player state: `pass3_bog`, `bog_toll`, `bog_kisses`. A `bog_frog_turn` counter enforces doubled-once-a-turn.
   - Frozen rollback data: `pass2_bog_units.json`.
   - Records: Bog entries in the upset audit record (no code reader); `bog.json` (nothing on this branch reads it).
2. **Scheduled or background:** none.
3. **Features:**
   - Bitter, Soak and the Toll; Hopkin, Ranocchio, Gideon and Bufo;
   - the dependent opening, and lures and pulls that wait for a unit to leave a Belly;
   - Sinks, shared kisses, the curse break and the Prince, the Peatlings, and the Cutter's and Pretender's gold;
   - Nan and Tiddy at Start of Turn, and the "gain the Toll" lever;
   - card text generated from the rates, and the drink preview in the reader;
   - the Toll on the tribe chip, the shared kiss counter, and log lines;
   - the Bog Hard bot and its three strategies;
   - rulebook entries 9.3.2a.1 and 12.1.8.
4. **External:** none.
5. **Config:** every pass 3 rate becomes a GameConfig key with a null default (`game_config.gd:94-97`), so the bench can override it; `bench.gd:152` rejects unknown keys. Stated reason: build doc `:79`.
6. **Public interfaces:**
   - `get_state` adds `bog_toll`, `bog_kisses` and `bog_kiss_period`; the per-fight player rules add the Toll and kisses;
   - a new `bog_state` carry operation;
   - new events `bog_toll`, `bog_pull`, `bog_bind`, `bog_hit_back` and `permanent_reward`; kiss events now carry the period.
7. **Internal machinery:**
   - six Bog helpers and one mechanic dispatcher, in the same shape as wave 1's;
   - hooks in shared combat code;
   - the pass 3 content check now counts Bog;
   - the upset audit's per-ability Bog list (needed because the audit refuses unknown abilities);
   - three exceptions in `check_units.py`;
   - the `LegacyBog` test library.
8. **Deleted:**
   - the pass 2 Bog rules, kept only as the frozen copy in tests;
   - the copy mark in the legacy copy path;
   - the five prototype bodies, out of the pool;
   - the old strategy routes.

**Unrequested** (no stated reason, or nothing reads it): `low_roll`; `bog.json` on this branch; the Bog audit-record entries; the any-unit scope on Tiddy and the frogs.

**Size:** 129 files, +5,500/−325. The Bog commit alone is 128 files, +5,489/−312: src +2,054, tests +2,500, content +304, docs +154, other +477.

## Verdicts (pr-interrogate)

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| Legacy copy mark removed; test isolated; 9.3.2b qualified | keep | `combat_moves.gd:54`, `combat.gd:281` | — |
| 16 bodies and 2 tokens, apart from three faces | keep | they match `bog-pass3.md` §3 | — |
| Tiddy, frog and Prince "units beside" | **cut** | `tiddy_mun.json:11`, `his_highness.json:11`, `prince_restored.json:11`, `pass3_bog.gd:81`, `pass3_bog_growth.gd:58` | Change to "Bog folk beside this" in faces, code, bot frog value, README:48 and three tests (`test_pass3_bog_content.gd:243`, `test_pass3_bog_growth.gd:155`, `test_pass3_bog_recruit.gd:13`), or log a reversal of amendment 2 |
| Five prototypes out of the pool | keep | wave 1 did the same; parity 16 | — |
| B and C rates | keep | they equal `presets.md` | — |
| Paper B values before the accounting check | **ask** | DECISIONS, "Paper values" | Ask 1 |
| Bitter, Soak, Toll and the card abilities | keep | design §2, §7 | — |
| Dependent opening, deferred targets, rulebook 9.3.2a.1 | keep | DECISIONS, "Bog's three questions" | — |
| Sinks, kisses, curse, King, gold | keep | design §7 | — |
| Player Toll and kiss state, and their carry | keep | design §7 | — |
| "Gain the Toll" lever (off) | keep | presets key; design §10 | — |
| Every rate a null config key | keep | `bench.gd:152` | — |
| Text generated from rates | keep | presets §6 | Fix the Soak reminder at `effects.json:883` |
| Bog bot and strategies | keep | plan, design §7 | Follow Cut 1 |
| UI: Toll chip, kisses, preview, logs | keep | design §1 and §7; nothing new on the main screen (09e) | — |
| Upset audit Bog list and record | keep | the audit refuses unknown abilities | — |
| `bog.json` priorities, climb and placement | keep | plan | — |
| `bog.json` `low_roll` and prose `keep` | **cut** | five loader errors | Remove `low_roll` and use card ids in `keep` (prose can go in `placement`), or implement `low_roll` in the loader |
| Rule (b) audit, structural only | **ask** | `wave2a-build.md:131` | Ask 2 |
| Rulebook tag `[PROPOSED BRAMBLE]` | **simplify** | `rulebook.md:536`, `:815`; `[BRAMBLE]` means an owner decision (`:16`) | Retag as `[PROPOSED ideation]` |
| Frozen rollback library and re-pointed tests | keep | plan: "pass 2 tests stay as the rollback" | — |
| New Bog test suites, `check_units.py` exceptions, pass 3 content check, build doc and gate log | keep | — | — |

## How I checked, and what didn't run
- `git merge-tree` shows the branch merges cleanly into ideation/main (tree `3af0bc51`). It changed no refs or files.
- I tried a Godot run of the line tests on that merged tree in a temp copy, under the lock. It didn't complete:
  - the first try timed out after 300 s waiting for the lock, which the running worker's gate held;
  - the rerun died when the scratch quota on `/tmp/claude-1000` filled. I deleted my copy and didn't try a third time.
- So the `bog.json` finding rests on two things: a Python port of the loader's key and card checks, which found exactly the five errors, and reading the call path from `test_wave1_lines.gd:9` to the loader's assert.
- **The `/tmp/claude-1000` quota is still full**, so your other agents' writes there may fail too. Your session's scratch folder holds about 2.6 GB, none of it mine. I left all of it in place; my folder `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-bog/` is now a few small files.