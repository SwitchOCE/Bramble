# Wave 2a fix-ups follow-up review (9 Nov 2026)

Fresh scope reviewer, range 0a31c5f..1144ad6 on ideation/wave2a. Verbatim report.

## Follow-up review: `0a31c5f..1144ad6` (ideation/wave2a)

The fix-up does what I asked, and both rule changes are built and tested, including the fallback to a copy. Two things go further than your calls. Once the one cut is fixed it can merge.

**Counts:** keep 10, cut 1, simplify 0, ask 2.

**Original problem (scale too low):** these commits barely move it. Mousewife's Mouse now scales, but the rest is fixes and two rule corrections.

**Cut:**
1. **The rollback's Fetch copies are marked too.** `CombatMoves.become_copy` sets `copy.copied_this_fight = true` with no pass 3 check, right after `summon_into`. Only the legacy `cradle_fetch` mechanic calls it. With pass 3 off, enemy picks by Attack plus Health, Attack or Health now skip the legacy Fetch copy. The worker's last test asserts exactly this (`test_legacy_copy_path_is_marked_without_changing_legacy_event_shape`).
   - Your call is about pass 3's twin, and the pass 2 tests are meant to stay the rollback.
   - Rulebook 9.3.2b also lacks the "With pass 3 content" qualifier that 9.3.2a has.
   - **Fix:** delete that line. Pass 3's Fetch already marks its copy through `enter_board(..., {"copied": ...})`. Flip the test to expect the legacy copy unmarked, and add the qualifier to 9.3.2b.

**Ask items:**
1. **The copy rule reaches more cards than item 3 names.** Item 3 says "biggest-enemy effects skip copies made this fight". The build applies it to every enemy pick ranked by Attack or Health, not only by size:
   - `highest_attack` and `highest_health` picks in `src/core/effects/target_select.gd:16`;
   - Marmot Lookout's Whistle (Hedgerow, in the pool);
   - the prototype Nightshade mark (Belladonna Sprite, not in the pool).

   It also moves `whistle` and `nightshade_mark` into the harness's masked answer class (`tools/sim/upset_combat.gd:7`), which changes what upset audits count as an answer. Your message to me calls it "stat-ranked enemy picks", so it may be what you meant. If so, the DECISIONS wording needs to match. If not, narrow it to `biggest`.
2. **Jack's recipient can still depend on the random side order.** Jack Daw now resolves in the late step, as item 4 says. But inside that step, sides still go in random order. My probe:
   - Setup: Jack plus Birds of 100/100 and 70/80, against an enemy scale_answer lever (a biggest-enemy answer, 50%).
   - Result over 32 seeds: the reward went to the 70/80 Bird 19 times and to the 100/100 Bird 13 times.

   That cuts against the call's reason, "A permanent gain shouldn't rest on a random side order". It has no effect today, but it will once wave 2's biggest-enemy answers land. Accept it, or run Jack after all biggest-enemy effects, the way Jenny runs after the Lantern?

**Each fix checked against what I asked:**

| Fix | Done? | Evidence |
|---|---|---|
| Capture identity test | yes | It now checks a private pass 3 library, cache reuse, an unchanged source and caps on (`tests/core/test_field_combat.gd:18-35`). |
| `null` default for the spell percent | yes | `src/core/game_config.gd:48`. A test asserts the key exists, so a bench override no longer trips `bench.gd:150`. |
| `Pass3Rates.preset()` removed | yes | The tests use `resolved()`. |
| Mousewife scaled | yes | `src/core/effects/combat_world.gd:198`: tier × percent × the living board's average, with the tier as the floor. Removing it fails `test_mousewife_scaling`. |
| Captures freeze rates | yes | `GameConfig.resolved_values()`, saved at `game_session.gd:811`, also stores the default text basis (`pass3_text_defaults`) so replayed events match exactly. The test edits the defaults and presets and includes a negative control. Unfreezing makes it fail. |
| Short faces (fallback) | yes | Examples: Pinch "Give +10%/+10%.", Supper "Choose a unit. Increase its tribe bonus. Once a turn.", Bracken "...they gain +10%/+10% per tier." The percentage, minimums and Bracken's "up to +5/+5" are in Details. The one side effect: "Give a unit" becomes "Give" on Pinch, Cordial and Last Orders. |

**The two rule changes:**
- **Item 3, original over copy:** marked by Fetch through `enter_board` and filtered by `Pass3Combat.prefer_original_enemies`.
  - The fallback when only copies are left is tested (`test_each_stat_pick_removes_original_candidates_before_falling_back_to_copy`, plus the Whistle, Nightshade and Snap cases).
  - Friendly picks, positional targets and all-enemy effects keep the copy (tested).
  - Removing the preference fails 6 tests. Removing the fallback, in a version that compiles, fails 5.
- **Item 4, Jack late:** `Pass3Combat.is_late_start`, which copied text also uses.
  - Tested in both player orders across 16 seeds, against Fetch plus Ring, Granny, Whistlers, Changeling and a copied Jack.
  - Reverting it fails 4 of 5 tests.

**Birds and Fairies elsewhere:** nothing else changes in pass 3. The only Birds/Fairies effects are item 3 (enemy answers now reach the Fairies' carry), item 4, and the rollback marking in the cut. Their own picks of the biggest friendly Bird or Fairy are untouched, and the gate's fixed-dial replay against `f574eaf` still passes.

**Clear to merge into ideation/main?** Yes, after the cut, or now if you decide to keep the rollback marking.
- `0a31c5f` is exactly the automatic merge of `7b5abf8`.
- `git merge-tree` onto `ba37b9e` is clean. Since `7b5abf8`, ideation/main has changed only docs, so the merged code equals `1144ad6`.
- The worker's gate covered that code: 1,908 of 1,908 GUT tests (`docs/ideation/evidence/wave2a/fixups-gate.log`).
- On a scratch copy of `1144ad6`, I ran 13 test scripts: all 121 tests pass.

**Notes:**
- The worktree `/home/alex/code/Bramble-ideation-balance` now has uncommitted Bog edits (`content/bots/...`) from another session. They aren't mine: I read committed revisions only, and HEAD is still `1144ad6`.
- My probe logs are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv2-logs/`.