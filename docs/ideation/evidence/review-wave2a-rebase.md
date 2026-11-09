# Wave 1 re-base and Bog fix-up follow-up review (10 Nov 2026)

Same scope reviewer as the Bog build review, range 9f03fe0b..d5b5b4f8 on ideation/wave2a. Verbatim report.

## Follow-up scope review: ideation/wave2a 9f03fe0b..d5b5b4f8 (f86f2d7c wave 1 re-base, d5b5b4f8 Bog fix-up)

The owner's words (09a, 09c, 09f, 09h, 09i) and plan v3 are the same as in the first review. I added the DECISIONS entries "Wave 1 triage: what we fix", "Wave 1 fun probe: go…" and "Paper values for presets B and C", plus `evidence/wave1-triage/` on ideation/main. I couldn't see the orchestrator's brief to the worker. Its stated intent, quoted in your message, counts as a proposal.

**Counts: 14 keep, 0 cut, 1 simplify, 3 ask.**

**Does it move the original problem (09a, numbers too small and flat)?** Yes, for Fairies:
- At B every Ring is +4/+4, against +1/+1 before.
- Cluricaun now fires every turn, T6 included.
- The Queen's emptied slots can be refilled before the fight.

Nothing is measured yet: no one has read the realized R12 medians against B's 900. Birds and Bog power are unchanged, as intended.

**Ask items:**
1. B carries four Fairy dial changes the triage entry doesn't list. Ring growth goes 1 to 2, so B's Cluricaun prints "+2/+2" (golden +4/+4), against the logged "+1/+1". Nan Toadstool goes from 1 Ring to 2, Lob from every 3 turns to every 2, Monarch from every 3rd End of Turn to every 2nd. Keep them and log it, or hold B to the logged list?
2. C was replaced with the paper C. Some dials went up (ring size 6, ring growth 2 to 4, Lob growth 2 to 3, both periods 3 to 2). Five went down: Fetch 2 to 1, Monarch ×4 to ×3, golden ×6 to ×4, and Annis, Queen and Sally from 2 Rings to 1. Your brief says "Annis and Sally unchanged", but C's went from 2 to 1. Is this dial-back intended?
3. The `test_a_pinned_bot_plays_its_strategy` pin to preset A weakens the test for the shipped config; it isn't fair isolation. My probe ran seeds 31–34. The Hedgerow pin's Fairy share is 0.34–0.51 under B (3 of 4 seeds miss the < 0.4 bar), against 0.15–0.48 under A. A also fails seed 32 (0.476), so the single-seed test is fragile at A too. Fix the test (B run, several seeds, the build_of checks), or accept and log that hard pins drift toward strong Fairies under B? Line sims at B would inherit that drift.

**Simplify:**
- The preset A pin on the whole of `tests/core/test_pass3_birds_recruit.gd` isn't needed. The suite passes unpinned under B (22 of 22 tests, 86 asserts), so drop the pin.

**Keep:**
- **d5b5b4f8, all four done as asked:**
  - Cut 1, Bog folk only: card faces, `pass3_bog.gd:79`, `pass3_bog_growth.gd:58`, the text, and the bot's value, hold and pins, with tests that exclude other tribes.
  - Cut 2, `tools/sim/lines/bog.json`: `low_roll` is removed and `keep` holds only card ids. It validates clean against my Python port of main's strict loader.
  - The simplify: rulebook 9.3.2a.1 and 12.1.8 are tagged `[PROPOSED ideation]`.
  - The Soak text (`effects.json:883`).
  - The new Bog tests, including the splashed-Fairy placement test.
- **f86f2d7c:**
  - Ring size 4 in B and 6 in C.
  - Queen at Start of Turn: trigger, text, rulebook 12.1.5, line prose, and the bot places food only when her next firing is due.
  - Cluricaun at End of Turn, and the bot keeps it at T6.
  - Annis and Sally stay at 1 Ring in B.
  - Birds are unchanged: the resolved Birds rates are identical before and after in A, B and C.
  - `legal_actions.gd`: pass 3 Rings no longer hit the old flat cap. This is needed, because at size 4 a single Ring reads +4/+4 and would bar Ring spells from every Ringed slot. The legacy cap still applies outside pass 3 and is tested.
  - `Pass3Rates.overridden()` now compares against the selected preset.
  - The pool-replay fixture also pins its reader basis; the fixture itself is unchanged.
  - The Fairy recruit and pass 3 bots suites are pinned to A. That's fair isolation: they test mechanics at fixed dials, and `test_pass3_presets.gd` checks the B and C values.

**Pass 2 rollback: untouched.**
- Nothing under `tests/core/legacy_*.gd` or `tests/core/data/` changed.
- `LegacyWave1.library()` swaps every wave 1 and Bog id for the frozen pass 2 cards, so the edited Fairy unit files don't reach it.

**Rule (b), whether each condition can hold when its trigger fires:** both cards pass.
- **Queen:** Start of Turn fires after the shop fills and gold is paid (`recruit_rules.gd:168`). Whatever was left behind her at the last End of Turn is there to destroy, and the phase stays open to refill those slots. That fixes the triage's 1.8-empty-slots finding.
  - Minor note: held Birds land just before Start of Turn (`HeldUnits.land_due`). A Bird whose nest is behind the Queen is now destroyed as it comes home, which the old End of Turn timing spared.
- **Cluricaun:** End of Turn fires every turn, T6 included, where the old trigger couldn't fire for 42–55% of its board time. Rings are slot effects that persist, and a Start of Turn Queen rings all slots, so a Queen board meets the condition the same turn. The critic measured 45–78% of R12 boards meeting it.

**Merge.**
- ideation/main is now c6dc089d, a docs-only DECISIONS commit after b5601aa2.
- `git merge-tree --write-tree ideation/main d5b5b4f8` is clean (tree 63eb2420; against b5601aa2 it was a6718ec8).
- Seven files changed on both sides: `bot_pass3.gd`, `game_config.gd`, `game_session.gd`, `combat_screen.gd`, `recruit_layout.gd`, `recruit_view.gd` and `tools/sim/lines/fairies.json`. Main's bot changes (fly policy, court flag) don't touch the branch's Cluricaun and Queen logic, and the two `fairies.json` edits are compatible.

**The merged-tree gate must run** these main-only tests, which the branch's gate never ran. I didn't run them: my merged-tree run was dropped from the rerun because of lock contention.
- **`test_field_normal_regression.gd`, the highest risk.** It replays 4 recorded games on frozen 0946909 content, which includes pass 3 Cluricaun and Queen. Their triggers live in code, so the new timing and bot changes run against the recorded hashes. Expect a mismatch; if it comes, re-record the fixture in a logged step rather than loosening the test.
- `test_field_library_v2`, `test_field_mode` and `test_field_launch`: their content hashes cover `rates.json` and the unit files.
- `test_real_designed` with `real_designed_recipes.json`: Fairy designed boards change at ring size 4.
- `test_wave1_lines` and `test_committed_lines`: main's strict loader on `bog.json` and `fairies.json`.
- `tests/sim`: `test_real_designed.py`, `test_wave1_accounting*.py` and `test_field.py`.
- The UI suite plus a screenshot, for the three overlapping screens.
- The full `scripts/check.sh` on the merged tree.

**Clear to merge into ideation/main at d5b5b4f8?** There are no cuts and the fun probe gate is met. It can merge once you've settled or logged the three asks, the worker's own gate passes, and the merged-tree gate passes. Expect `test_field_normal_regression` to need a re-record.

**Probe notes.**
- The temp copies are deleted; only small notes remain in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-bog/`.
- My first probe ran the whole suite, because the temp copy's `.gutconfig.json` dirs override `-gtest`, so I stopped it. The second never got the lock. The third, smaller run used the shared lock as the new DECISIONS lock entry says reviews should.