# Bazaar Stack — loop 1

Stages: painted world/table (`b06a1e52`), playable recruit stack (`0f33ee84`), open fight (`cff34820`), then scope-review fixes.

The runtime backdrops are Highcrown Canopy at `assets/ui/world/recruit_backdrop.jpg` and `fight_backdrop.jpg`. Recruit uses a muted stump and merchant counter with cream light from the upper right; fight uses the clearing directly. Resting sockets are gone; placement rims and Ring/Nest state remain. Foliage stays behind input. Menu, settings, guide, sandbox and results share the world and quiet painted surfaces.

Merchant, formation/reserve and hero/action bar are the three groups. Ten reserve portraits remain exposed in one unframed row. The standings rail sorts with short reorder/Health motion; your Health lives only on your hero in the bar. Scouting focuses the opposing formations. The reader floats without reflow; its phone height again fits the complete Fly South rules. Fight has closer ranks and readable hero Health. The game-over record badge clears its subtitle.

Scope review: folded eight one-use subclasses into their base widgets and removed obsolete layout helpers. Fixed Next opening both scout and reader, made hover reader text transparent to pointer input, and set world input transparency at construction. Changed-price refresh uses a compact cost face. The name-fit exemption now applies only to name-only non-pool fillers.

Evidence is in `build/loop1/stack/`: early/late recruit, reader, fight start/mid, scout and results at both sizes, plus Bazaar comparisons. Fresh late/results stills and recruit/fight clips accompany the review fixes. Direct comparison prioritised visible woodland, exposed reserve identities and one home for controls; no instructional labels were added.

Tests changed across stages: `test_hand_fan.gd`, `test_phone_layout.gd`, `test_recruit_actions_motion.gd`, `test_commitment.gd`, `test_engines.gd`, `test_polish.gd`, `test_pass2_ui.gd`, `test_recruit_declutter.gd`. All four original label-budget tests are restored unchanged. Restored complete-rules and eight-offer finger-size assertions. Deleted obsolete named-plaque tests `test_cards.gd::test_a_long_hero_name_reads_whole` and `test_engines.gd::test_lobby_last_stand_states_fit_without_shortening_names`; the full identity remains tested in the reader. No test files deleted.

Small ownership extensions: menu/results/settings/guide/sandbox, base widgets requested in review, and hover input routing in `recruit_screen.gd`; prior `look_live.gd`/`states.txt` add `combat_start`. No gameplay rules changed. Verification of the review fixes is in progress; the earlier full check passed on `cff34820`.
