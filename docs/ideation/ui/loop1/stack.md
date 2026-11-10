# Bazaar Stack — loop 1

Three stages: painted world/table (`b06a1e52`), playable recruit stack (`0f33ee84`), then open fight layout and final verification.

The runtime backdrops are the art worker's Highcrown Canopy paintings at `assets/ui/world/recruit_backdrop.jpg` and `fight_backdrop.jpg`. Recruit uses a small muted stump and merchant counter, with cream light from the upper right. Fight uses the painted clearing directly. Resting sockets and dashed pockets are gone; active placement rims and Ring/Nest state remain. Foreground foliage stays behind the interface.

The merchant, formation/reserve stack and hero/action bar are the three main groups. All ten reserve portraits remain exposed in one unframed row. Scouting focuses the opposing formations. The standings rail sorts by Health with short reorder/countdown motion; eliminated faces shrink. The reader floats without moving the stack. Fight has closer ranks, larger cards and readable hero Health on the bottom bar.

Look in `build/loop1/stack/` for early/late recruit, reader, fight start/mid, scout and game-over PNGs at both sizes, plus Bazaar comparison sheets. Compared directly with Bazaar and the gallery critic, the changes prioritise visible woodland, exposed reserve identities and one home for controls. No new instructional labels were added.

Small edits outside the original file ownership: menu/game-over backdrop calls and shared menu materials; `tests/ui/shots/look_live.gd` and `tools/look/states.txt` add a paused `combat_start` capture.

UI tests rewritten: `test_hand_fan.gd`, `test_phone_layout.gd`, `test_recruit_actions_motion.gd`, `test_commitment.gd`, `test_engines.gd`, `test_polish.gd`, `test_pass2_ui.gd`, `test_recruit_declutter.gd`. The last retires `test_scripted_recruit_and_scout_keep_all_visible_text_within_forty`, `test_real_seeded_recruit_uses_the_same_forty_node_budget`, `test_evidence_recruit_and_scout_states_obey_the_same_budget_at_both_sizes` and `test_counter_includes_names_numbers_buttons_and_rich_text_and_rejects_forty_one`; other edits replace old header, pouch and reserved-reader assumptions. No test files deleted.

Checks: PC/phone purchase and placement, plus phone End turn to game-over through `tools/look`; `./scripts/check.sh --keep-going --base 528de8d5` passed. Fixed a first-render shop-sizing bug. Rapid desktop hover can intercept a pointer sequence; isolated placement and real empty-cell taps are verified, with reader feel remaining worker B's scope. The orchestrator retains the cloud gate, four-game UI run and other workers' reader/unit integration.
