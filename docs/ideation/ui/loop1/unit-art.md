# Loop 1: units toward the woodland

The card uses warm paper, a thin olive-bark edge, upper-right cream light and a soft lower-left contact shadow. Badges, keywords and state anchors retain their existing symbols and geometry. All card-only colours remain in `card_view.gd`.

Owner choice: gentle grading of current portraits, stronger grading of current portraits, plain-ground repaints (`assets/portraits_v2/`), or scene-kept repaints (`assets/portraits_v2b/`), then **all units like this?** The two repaint sets cover the same eight sample IDs.

`STRONG_PORTRAIT_GRADE` in `card_view.gd` is the single production switch, currently true. False restores the earlier gentle grade; there is no player setting. The stronger option mutes saturation while protecting identifying blues and yellows, and adds broad warm upper-right light with cooler lower-left shade. It uses the current portraits throughout, requiring no repaint or mixed set. Stats and keyword badges are outside the graded material.

The scene-kept repaint alternative restores the kitchen, hearth, lightning, figure in the lantern beam, outdoor planes, shrubs and garden pot. It simplifies backgrounds and warms the light while retaining clean ink contours and cel shadows. Some subtle generated tonal variation remains. Production portrait lookup is unchanged.

Evidence is in `build/loop1/unit-art/`. `eight-unit-comparison.png` has five columns: current/original card, current/new card, plain-ground/new card, scene-kept/new card, and **Current / stronger grade**. The preceding comparison columns are unchanged. `recruit-plain_1920x1080.png`, `recruit-scene_1920x1080.png` and `recruit-strong_1920x1080.png` show the same real recruit state on the canopy backdrop. `tools/render_unit_art*.gd` provide review-only overrides.

Earlier `recruit_*` and `combat_mid_*` captures cover PC and phone. Prompt files are `tools/art/prompts/loop1-unit-*.txt`; PNG masters stay outside git in `build/loop1/unit-art/masters/`. Recruit/fight canopy paintings were handed off in `bf62bf85`.

Validation: `./scripts/check.sh --keep-going --base 528de8d5` passed all steps with the stronger grade enabled, including 2,741 Godot tests. Fresh scope review found no issues. The frozen phone capture was also inspected. No UI tests were rewritten or deleted; no new checks were added.

Branch remains held for rebasing after the layout merge. Combined stump layout is unverified here. Cards supply contact shadows; the surface should stay quiet, muted and lit from upper right. The owner/orchestrator chooses portrait rollout and backdrop integration.
