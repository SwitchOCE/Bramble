# Scope review: wave 2b part 1 (Oozes), `df9ed13e..c66a88e5`

## Summary

**Counts:** 22 keep, 1 cut, 1 simplify, 5 ask (29 items).

**Does it move the original problem (scale too small and flat)?** Partly. Oozes went from flat to growing, but they are still small.
- The engine line grows ×1.37 a round from R8 to R14 (×1.34 if you only follow the seats that survive). Pot Luck grows ×1.25 (×1.22 on the same basis).
- The pass 2 model's bots were about ×1.14 (80 at R8, 133 at R12).
- At R12 the boards are 262 (engine) and 200 (Pot Luck). The Hard field in the same lobbies is at 337, the preset target is 900, and the paper figure is 978. So Oozes reach 0.20–0.27× of their paper size, against a plan that says "Oozes stay at their design size".
- Hard seats that ended up as Oozes: 246 at R12 and 510 at R14. That is second-lowest, above only the pass 2 Hedgerow. Fairies are at 460 and 1,348.

**Cut (1):**
- Stone Soup buffs Shy shop offers, and the bonus stays permanent when the unit is bought (`src/core/pass3_oozes.gd:146-153, 157-167`). This breaks Shy's own text, "Only a spell aimed at this buffs it", and rulebook 12.1.7. It is not in the rulebook and no test covers it.

**Ask (5):**
1. Pot Luck misses the brief's per-line "not flat" bar. It shows ×1.251, and the honest figure is lower (×1.22 same-cohort; only 2 of 12 surviving seats reach ×1.3). Merge with it open pending the triage, or hold?
2. Hasty's permanent gain reads the swallowed enemy's base plus permanent stats only, leaving out Rings, auras, tribe bonuses and combat buffs (`pass3_ooze_combat.gd:153-154`). The settled design says "The gain reads the enemy as it's swallowed" (`oozes-pass3.md:272`). The build's reading is narrower and less generous. Keep it, or read current stats?
3. Nothing sets the `replay_starting_belly_survivors` flag (`game_config.gd:41`) except tests, and the Python offline replay can't switch it on. Who runs captures with it on, and when?
4. The new `killer` field on Posset death events (`combat.gd:778-781`) is read only by one test. Drop it, or name who reads it.
5. The `on_eat` trigger is declared and fired (`effects.json:10`, `pass3_oozes.gd:259`), but no card or code listens to it; Elder is wired directly. Keep it as a building block, or drop it?

**Simplify (1):**
- Posset keeps her own killer map (`combat.notes["ooze_killers"]`). Use `CombatLanes.by_uid(combat, unit.killed_by)` instead, the way Bufo does (`bufo.gd:6`).

**What I ran, and what I didn't:**
- Ran: git reads at `c66a88e5` and `a2f4295f`; Python recomputes of growth from the committed JSONL; `check_units.py` (0 problems) and `test_check_units.py` (19/19 pass), both on a `git archive` copy in the scratchpad.
- Didn't run: Godot, GUT, sims, refights or screenshots (machine rule).

---

## Brief

- All three inputs were present: the target (`df9ed13e..c66a88e5`), the owner's words (09a, 09c, 09e, 09h, 09i, 6 Nov), and the plan v3 step 2 text plus the checkpoint criteria.
- The worker brief's two criteria ("text equals behaviour", and each line ≥ ×1.3) are orchestrator proposals.
  - The plan's own bar is the lobby median ≥ ×1.3 from R8 to R14, judged at checkpoint 1.
  - In these 32 lobbies the whole lobby grows ×1.37 (×1.34 same-cohort). That figure is context, not a checkpoint result.
- The merge on top (`a2f4295f`) touches no Ooze file. It brings ideation/main's combat fast paths:
  - copies of cached `BoardGeometry` tables;
  - inline health reads;
  - early exits for Rings and the Hex percent.

  They look semantics-preserving. But the 1,930 refights ran on `c66a88e5`, not on the merge tip.

---

## Report (pr-report)

101 files, +6,185 / −246.

### 1. Schema / data
- **23 Ooze dials.**
  - What: `oozes_*` keys in `content/pass3/rates.json`, under base rates (= B), B and C. A falls back to the base rates.
  - Used by: `Pass3OozeText._parameters`, `Pass3Oozes`, `Pass3OozeCombat`, `BotOoze`.
  - Stated reason: plan "Every engine rate is a dial"; `presets.json`.
- **16 Ooze cards and the Slice.**
  - What: rewritten `content/units/*.json`, plus the new `slice.json` (tribeless, `pool: false`).
  - Used by: the library and the generated faces.
  - Stated reason: the settled `oozes-pass3.md`.
- **Schema additions** (`content/schema/effects.json`):
  - `on_eat` trigger (`:10`): used by nothing (fired at `pass3_oozes.gd:259`). Stated reason: none. The design's item 2 asks for "Elder's on-eat hook", but that is built directly.
  - `pass3_ooze` params, `pass3` flags on bubble/wobbly/pie/syllabub/figgy_duff/borrows_text, and the Digest/Eat/Slice reminders: used by the mechanics and text code. Stated reason: design items 1–15.
  - The `scalar` kind and the `mechanic_ability_params` section: used by `tools/checks/check_units.py`. Stated reason: none for the per-ability check; `scalar` is needed because shares are fractions.
- **Frozen pass 2 definitions.**
  - What: `tests/core/data/pass2_oozes_units.json` (610 lines) and `LegacyWave1.with_oozes`.
  - Used by: `test_belly`, `test_scale_review`, `test_pass3_pool_replays`.
  - Stated reason: plan, "the pass 2 tests stay as the rollback" (deleting them waits on step 5).
- **New unit state.**
  - What: `RecruitUnit.last_meals`; the metas `ooze_ladle`, `ooze_soup_bonus`, `ooze_digest_preview`, `ooze_nell_eaters`; the counter `ooze_share_serial`; the combat counters `ooze_reduction`, `pass3_bubble_half`, `replay_starting_belly_survivor`.
  - Used by: Frumenty's `_text_sources`, the UI marks and reader, DR sync, Bubble's split guard, and the replay flag.
- **`killer` field on death events.**
  - What: added only for Posset units (`combat.gd:778-781`).
  - Used by: one assertion in `test_posset_halves_her_actual_effect_killer...`.
  - Stated reason: none.
- **`combat.notes["ooze_killers"]`.**
  - What: Posset's own map from victim to killer (`pass3_ooze_combat.gd:87-92`).
  - Used by: `death()` (`:62-82`).
  - Stated reason: a code comment only.

### 2. Scheduled / background
None.

### 3. Features
- **Eating at Start of Turn.**
  - What: Digest, then Nell, then Cut-and-Come-Again (`pass3_oozes.gd:171-226`), called from `recruit_rules.gd:168` after Birds land and before ordinary Start of Turn. One meal pipeline (`:229-259`), the Aspic bonus (`:262`), Elder's share (`:292`).
  - Stated reason: design items 1, 2, 5, 9, 13.
- **Soup's shop layer.**
  - What: a live aura on every shop offer (`pass3_oozes.gd:118-153`), committed into permanent stats on buy, swallow-from-shop or a Nell meal (`:157-167`; `recruit_rules.gd:259`; `held_units.gd:71`). It overrides Shy's immunity (`:164-167`).
  - Stated reason: design item 3. The Shy part is a "build reading … for scope review" (`wave2b-build.md:34`).
- **Combat.**
  - What: Hasty, Granny, Posset and Moss (`pass3_ooze_combat.gd`); the pass 3 Bubble, Wobbly, Pie and Syllabub variants (`mechanics/*.gd`, `combat_held.gd`).
  - Stated reason: design items 6, 7, 10–12, 15.
- **Start-of-combat order.**
  - What: Hasty joins the late, stat-ranked answers. Both sides' Grannies gather after every answer, and Jack Daw stays last (`pass3_combat.gd:130-139`).
  - Stated reason: design "Granny gathers after the answers resolve" (`oozes-pass3.md:438`); `wave2b-build.md:40`.
- **Damage reduction.**
  - What: when Tom Tit's DR and golden Moss's DR overlap, the stronger wins (`pass3_bird_combat.gd:155-185`).
  - Stated reason: `wave2b-build.md` "the strongest applicable protection wins".
- **Granny's family comes back together**, so a gathered Moss shields its siblings; Syllabub also fires on own-side returns in pass 3 fights (`combat_held.gd:130-171`).
  - Stated reason: design Moss details; `wave2b-build.md`.
- **Figgy has no cooldown** for pass 3 (`held_units.gd:150-160`). Stated reason: design item 15.
- **Frumenty's history** survives a triple (`recruit_rules.gd:517, 538-541`). Stated reason: design item 8.
- **UI.**
  - What: drawn ladle, pot and meal marks plus the Elder pulse (`ooze_marks.gd`); Nell and Aspic slot highlights on hover and "Current eater: F2." (`recruit_oozes.gd`, `recruit_view.gd:600-632`); Digest and Soup lines in the reader (`card_detail.gd:405-420`); three tile tags (`card_view.gd:53-55`).
  - Stated reason: design item 17; 09e.
- **Bots.**
  - What: `BotOoze` (407 lines), hooked into `bot_brain.gd:198, 213, 363, 417, 628, 945`, `bot_held`, `bot_pass3`, `bot_placer`, `line_brain`, `committed_line_brain`.
  - Stated reason: plan, "Hard-bot fixes"; design item 16 and the line policies.

### 4. External
None.

### 5. Config
- **`replay_starting_belly_survivors`**, default false (`game_config.gd:41`).
  - Changes: `combat.gd:384` and `combat_moves.gd` `starting_survivors`.
  - Set by: tests only.
  - Stated reason: design item 14, "The starting-survivor variant as a flag for the offline replay".

### 6. Public interfaces
- **`tools/sim/wave2b_lines.gd`** (`suite=lines tribe=Oozes …`).
  - Used by: the committed measurement.
  - Stated reason: the brief's criterion 2.
- **`tools/sim/lines/oozes.json`.**
  - Used by: `LinePolicies`.
  - Stated reason: plan, "each with its line JSON".

### 7. Internal machinery
- **`Pass3OozeText`**: faces and details generated from the dials. Used by `Pass3Text.configure`. Stated reason: `presets.md`, "Card text follows the dials".
- **`check_units.py`**: the `scalar` kind and the per-ability parameter check. Used by the quality gate. Stated reason: none.
- **`UpsetCombat.AUDITED_OOZES`** and the refreshed audit hashes. Used by the upset audit. Stated reason: the existing audit rejects any pass 3 ability it hasn't audited.

### 8. Deleted or deprecated
- The Wobbly and Figgy limits are gone for pass 3 (design item 15).
- Rule 12.1.2b is now scoped to pass 2.
- Four existing tests swap the new Granny or Hasty for synthetic ordinary gatherers or positional holders.
- One fixed card count (157) becomes a count captured at the start of the test.

### Unrequested
These items say "none stated" or "nothing yet", so they are the ones to question:
- `on_eat`;
- the `killer` field;
- `ooze_killers`;
- the per-ability checker;
- the Shy override;
- the replay flag (requested, but nothing sets it).

---

## Interrogation (pr-interrogate)

| # | Item | Verdict | Evidence | Action |
|---|---|---|---|---|
| 1 | 23 Ooze dials (B, C) | keep | `test_all_twenty_three_ooze_dials_match_the_paper_b_and_c_values`; plan "Every engine rate is a dial" | — |
| 2 | 16 cards and the Slice; faces from dials | keep | `test_authored_normal_and_golden_faces_equal_resolved_b_generation` | Log the Pie wording change (Gaps) |
| 3 | Eating pipeline (Digest, Nell, Slice, Soup, Aspic, Elder) | keep | Known answers in `test_pass3_ooze_recruit.gd` (checked by hand below) | — |
| 4 | Soup on Shy offers | **cut** | Shy reminder `effects.json:891`, "Only a spell aimed at this buffs it."; rulebook 12.1.7 (`rulebook.md:821`) "Only a spell aimed at a Shy unit … can buff it while recruiting … auras … give Shy no stats". Existing shop-target buffs already zero Shy (`recruit_context.gd:107-114`). Not in 12.1.9. No test | In `prepare`, skip Shy offers (aura 0) and drop the override in `commit_shop` (`:164-167`); add a known-answer test. If the exception is wanted instead: write it into 12.1.7 and 12.1.9 as [PROPOSED ideation], change Shy's reminder, test it |
| 5 | Combat abilities and pass 3 variants | keep | `test_pass3_ooze_combat.gd` (27), `test_pass3_ooze_start.gd` (13) | — |
| 6 | Hasty's gain reads base plus permanent stats | **ask** | `pass3_ooze_combat.gd:153-154`; design `:272` "reads the enemy as it's swallowed"; documented in 12.1.9a and the details text; pinned by `test_hasty_reads_body_stats_excluding_tribe_auras_and_combat_loans` | The orchestrator decides. Against a Fairy carry that is mostly Rings, the gain is far below "a fifth of it" as the player sees it |
| 7 | Grannies gather after all answers, including both Hasties | keep | Design `:438`; logged at `wave2b-build.md:40`. Cost: the design's mirror moment "your Hasty … swallows the whole family" (`:477`, credited at `:23`) can no longer happen | — |
| 8 | Tom Tit and Moss DR, strongest wins | keep | `test_moss_reduction_survives_a_stronger_tom_protection_ending`; the 8 f574eaf replays (with Tom Tit) stay byte-identical | — |
| 9 | Batch family return; Syllabub on own-side returns | keep | `test_gathered_moss_returns_with_family...`, `test_syllabub_replays_a_returned_grannys_family...` | — |
| 10 | Posset's `ooze_killers` map | simplify | `killed_by` is already set at `combat_damage.gd:67`. Bufo reads it with `CombatLanes.by_uid` (`bufo.gd:6`). `death()` returns when the killer is dead, so keeping the reference after a mutual kill changes nothing | Replace with `by_uid(killed_by)` |
| 11 | `killer` field on Posset death events | **ask** | `combat.gd:780`. Grep finds no reader in `src/` or `tools/`, only a test. It changes event hashes in Posset fights | Drop it and assert on the halving, or name the reader |
| 12 | `on_eat` trigger | **ask** | Declared at `effects.json:10`, fired at `pass3_oozes.gd:259`; no card uses it | Owner prefers "flexible building blocks", so keeping it is defensible; or drop it |
| 13 | `replay_starting_belly_survivors` | **ask** | Requested by design item 14. Set only by `test_pass3_ooze_combat.gd:361, 378`. `replay_damage.py` replays captures, so it can't switch this flag on | Who runs the capture with it on, and when? |
| 14 | Frumenty history | keep | Design item 8; four recruit tests | — |
| 15 | No Figgy cooldown | keep | Design item 15; two Figgy tests | — |
| 16 | `BotOoze` and its hooks | keep | Plan "Hard-bot fixes"; line policies (`oozes-pass3.md` JSON); 17 bot tests. Every hook is gated on an Ooze build plus a live Ooze | — |
| 17 | The two measured bot fixes | keep | See probe 3 | — |
| 18 | `oozes.json` lines | keep | Matches the design JSON | — |
| 19 | `wave2b_lines.gd` | keep | Needed for criterion 2; Hedgerow part 2 reuses it | — |
| 20 | UI marks, hover, reader lines, tile tags | keep | See probe 7 | — |
| 21 | Rulebook 12.1.9 and 12.1.9a [PROPOSED ideation]; 12.1.2b scoped | keep | — | Add a Shy line only if item 4 is kept the other way |
| 22 | Schema params and reminders | keep | Supports items 2–5 | — |
| 23 | Checker `scalar` and per-ability params | keep | Ratios are integer-only, so `scalar` is needed. The per-ability check catches a mistyped `ability` before Godot runs; nothing else in the Python gate does. 19/19 pass | Don't extend it without a need |
| 24 | Upset audit for Oozes | keep | `test_upset_audits_every_ooze_ability_and_masks_only_hasty` | — |
| 25 | Frozen pass 2 Oozes and legacy tests | keep | Plan rollback rule; fixture bytes not re-recorded | — |
| 26 | Existing tests switched to synthetic gatherers; captured card count | keep | Comments give the reasons; the general ordering rule stays tested | — |
| 27 | Six new scripts, 88 tests | keep | No game or lobby tests; about 38 s | — |
| 28 | Committed evidence (2.2 MB JSONL plus logs) | keep | Precedent: wave 1 committed 1.7 MB; this review read it | — |
| 29 | Pot Luck below ×1.3 | **ask** | See probe 2 | The orchestrator decides, pending the triage |

---

## Probes

### 1. Text equals behaviour

I read the JSON, the code and the tests for Soup, Nell, Hasty and Granny, plus the golden faces of Soup, Nell, Elder, Hasty, Granny, Cut-and-Come-Again, Posset and Moss. Each test pins its card's text with a known answer, and I checked the arithmetic by hand:
- **Soup:** 80/96 → +10/+12, then 160/176 → +20/+22; the bonus is kept after Soup leaves. Golden Soup reads 120/144 → 15/18; with the guard off, two Soups stack to 25/30.
- **Nell:** her neighbour eats the lowest-tier offer with no buy and no gold spent. Golden Nell feeds the bigger neighbour first, one offer each, and skips a frozen shop.
- **Start of Turn sequence:** 80/80 + 8/8 → 88/88, then Nell eats a 2/3 with a live +11/+11 → 101/102, then the Slice is 20/20.
- **Hasty:** the biggest enemy 40/50 → +8/+10 kept permanently. Golden Hasty swallows two and takes a fifth of each (20/36). A hidden 100/120 gives +20/+24. Release happens after 3 friendly deaths or on Hasty's own death.
- **Granny:** gathers 10 + 7 Attack → 21 (golden 42), Health unchanged. Non-Oozes bridge the run, which is the rulebook's existing "touching" and the old Granny's behaviour. Cleave works on both faces.
- **Elder:** a normal Aspic gives 8/10 → 12/15, golden Elder → 8/10 ("all its stats"), and both Aspics → best only.

Where text and code disagree:
- **Shy under Soup** (item 4, cut).
- **Hasty's gain reading** (item 6, ask). The code matches its own details text but is narrower than the design's.
- **Two small gaps** (see Gaps): the Elder details typo, and the Pie face that departs from the settled text.

### 2. Pot Luck growth and survivor bias

**The arithmetic is right.** From `oozes-final.jsonl`:
- Engine: R8 87 (n=32), R14 572 (n=21) → ×1.3687.
- Pot Luck: R8 88 (n=32), R14 337 (n=12) → ×1.2508.
- Pooled: ×1.3026.

**Survivor bias lifts every figure.** R8 is a median over all 32 seats, but R14 counts only the seats still alive, and those started higher:
- Pot Luck's 12 survivors had an R8 median of 101 (88 for all 32). The engine's 21 survivors had 97 (87 for all).

Measured on the same seats at both ends:

| Line | Reported | Same cohort | Per-seat median | Surviving seats ≥ ×1.3 |
|---|---|---|---|---|
| Engine | ×1.369 | ×1.344 | ×1.332 | 14 of 21 |
| Pot Luck | ×1.251 | ×1.222 | ×1.230 | 2 of 12 |
| Pooled | ×1.303 | ×1.279 | — | — |

- Carrying eliminated seats forward at their last board gives engine ×1.277 and Pot Luck ×1.165. That method is biased downward, so it only shows the spread.
- **Verdict:** the engine passes on every reading. Pot Luck fails on every reading, by more than reported. The pooled "pass" disappears on a same-cohort basis.
- Under the worker's reading (each line must pass), Oozes do not meet "not flat". Pot Luck also survives less often: 38% reach R14, against 55% across the lobby.
- I recomputed the pre-fix run too: engine ×1.325, Pot Luck ×1.254.

### 3. The two bot fixes

Both are real bug fixes that bring the bots in line with the settled line policy. Neither changes a rate or a card.
- **`_needs_live_pot`** (`bot_ooze.gd:179-186`): a Digest carrier inside a Belly can't digest, so the first pot (or the upgrade from a Dollop) has to stand on the board. The design says "Bubble as the pot in B2".
  - Tests: `test_first_digest_purchase_replaces_a_weak_body_instead_of_becoming_a_reserve` (all three Digest cards, Hard and line seats) and `test_bubble_upgrade_is_played_then_receives_the_old_dollop_whole`.
- **Aspic is replaceable in Pot Luck** (`:101`, and `text_value` returning 0): Pot Luck keeps its pot in the back row, where Aspic serves nothing ("no Aspic", last in Pot Luck's priority list).
  - Test: `test_tempo_replaces_dead_aspic_while_the_front_carry_engine_keeps_her`, which also checks that the engine line keeps her.
- **They did not move any pass or fail.** Pot Luck went from ×1.254 to ×1.251, and the engine from ×1.325 to ×1.369; the engine already passed before.
- The "before" evidence is the committed diagnostic run, not a failing test. I could not check the "11 of 28 buried" count, because the JSONL keeps only active cards.

### 4. The Shy shop-bonus reading

This is a rule change to Shy, not consistent with the rules as written.
- Rulebook 12.1.7 and Shy's reminder both say only an aimed spell buffs a Shy unit while recruiting. The existing shop-target buff path already zeroes buffs on Shy.
- The change is not in the rulebook at all: 12.1.9 says "every shop offer", with no Shy line.
- It is untested.
- It reaches across tribes: Fairy Shy units (Hob, Lob, Silky) bought from a Soup player's shop arrive with permanent stats.
- Verdict: cut (item 4).

### 5. Blast radius

**What the 1,930 refights cover.** They are every fight captured in the final 32-lobby run (all tribes), refought on the same source (`c66a88e5`). That proves the captures replay deterministically. It does not show that other tribes behave as before the change.

**The real evidence that other tribes are unchanged:**
- The 8 f574eaf fixture fights replay byte-identical with the pass 2 Ooze cards swapped in. Between them they contain:
  - Birds: Tom Tit, the Whistlers, Old Tern;
  - Fairies, including the Shy Hob;
  - Hedgerow;
  - the pass 2 Granny, Hasty, Moss, Elder, Frumenty and Bubble.

  So the DR-sync change, the `return_inside` change and the start-order change are proved neutral for old content.
- The targeted runs of 25 existing test files also pass.
- **Not covered:** Bog and Hunters cards appear in none of the 8 fixture fights.

**Cross-tribe behaviour that does change:**
- Soup on Shy (cut).
- Other tribes' biggest-enemy answers now hit Oozes before Granny gathers (design-backed, 12.1.9a).
- On a mixed board, the Ooze Start of Turn sequence runs before other tribes' Start of Turn text (12.1.9).
- Moss and Tom Tit DR: the stronger wins (tested).

**Checked and inert for non-Ooze seats:**
- Every `BotOoze` hook is gated on an Ooze build plus a live Ooze.
- `Pass3Oozes.prepare` touches the shop only when a pass 3 Ooze is on the board.
- No existing tribe's dial changed.

**What would settle the merge tip:** refight the 1,930 captures on `a2f4295f`. That needs Godot, and I did not run it.

### 6. Test cost

Six new scripts, 88 tests:

| Script | Tests | Seconds |
|---|---:|---:|
| `test_pass3_ooze_bots.gd` | 17 | 12.1 |
| `test_pass3_ooze_combat.gd` | 27 | 11.1 |
| `test_pass3_ooze_recruit.gd` | 19 | 8.0 |
| `test_pass3_ooze_start.gd` | 13 | 5.4 |
| `test_pass3_ooze_ui.gd` | 5 | 0.8 |
| `test_pass3_ooze_content.gd` | 7 | 0.7 |
| **Total** | **88** | **~38** |

- No new test plays a whole game or lobby. A grep for `GameSession`, `end_turn` and `_smart_turn` finds none; `BenchSuites.create_bot` only builds a brain.
- The 38 s is about 10% of the 390 s test step. Most of it is per-test kit setup.

### 7. Screens

No new static labels.
- The marks are drawn, and the UI tests confirm they add no child text nodes.
- The Digest preview and the Soup breakdown live in the reader (on hover).
- "Current eater" appears in the hover text.
- The three tile tags ("Shop grows", "Eat bonus", "Meal share") fill an existing chip that would otherwise say "Ability". The declutter branch will port these chips later.

### 8. Owner misattribution

None. The only owner mention in the diff is "not an owner ruling" (`wave2b-build.md:34`). DECISIONS was not touched.

---

## Cut

- The Shy override in Soup. Edit `src/core/pass3_oozes.gd` in two places:
  - `prepare` (`:146-153`): give Shy offers no aura.
  - `commit_shop` (`:157-167`): remove the `shy_accepts_stats` override.
- Add a known-answer test: a Shy offer under a live Soup shows and keeps no bonus.

## Simplify

- Replace `combat.notes["ooze_killers"]` (`pass3_ooze_combat.gd:62-92`, and the call at `combat_damage.gd:57`) with `CombatLanes.by_uid(combat, unit.killed_by)`, as `bufo.gd:6` does.

## Gaps

- **Elder's details text is missing a space** (`pass3_ooze_text.gd:291-292`). It renders as "…No sale gold.Only other Oozes on your board gain…".
- **The Pie face departs from the settled text.** The design has "get 1 gold per unit inside" (`oozes-pass3.md:193`); the build says "per unit that comes out" (`pass3_ooze_text.gd:203`). The build matches the code but is not in the build's list of readings. Log it.
- **No test pins the Shy interaction**, whichever way it lands.
- **The refights and the measurement predate the merge tip.**
- **The UI has tests but no screenshots** of the ladle, pot or meal marks.
- **Realized size:** R12 is 0.20–0.27× of paper (978), and Pot Luck is 0.22× of its own paper line (924).

## Original problem

- Oozes are no longer flat on the engine line (×1.34–1.37). Pot Luck is still below ×1.3.
- Both lines are about 2× the pass 2 boards, but still below the field (Hard median 337 at R12, 766 at R14) and far below paper and the 900 target.

## Open questions (the orchestrator's calls)

The five asks above:
1. Merge with Pot Luck open?
2. Hasty's gain reading?
3. Who sets the replay flag?
4. The `killer` event field: keep or drop?
5. The `on_eat` trigger: keep or drop?

## Not run (needs Godot)

- Refight the 1,930 captures on `a2f4295f`.
- A GUT test for Soup plus a Shy offer.
- Focused GUT on the merge tip.
- Screenshots of the marks at 1920×1080 and 1688×780.
