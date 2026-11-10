# Loop 1: units toward the woodland

The card uses warm paper, a thin olive-bark edge, an upper-right cream highlight and a soft lower-left contact shadow. Portraits receive uniform restrained colour grading. Badges, keywords, frost, selection and golden states keep their existing symbols and anchors. Card-only colours stay in `card_view.gd`; no shared theme changed.

Owner choice: current portraits, plain-ground repaints (`assets/portraits_v2/`), or scene-kept repaints (`assets/portraits_v2b/`), then **all units like this?** Both sample sets contain Mrs Mallow, Lob-Lie-by-the-Fire, Wee Wobbly, Grey Agnes, the Lantern Man, Mrs Jay, the Lane-Bard and Pill Bug.

The second set restores the kitchen, hearth, lightning, figure in the lantern beam, outdoor planes, woodland shrubs and garden pot. Backgrounds use fewer broad shapes, muted colours and warm upper-right light toward the canopy world. Figures retain clean ink contours and simple cel shadows. Some subtle generated tonal variation remains. No wider repaint or production portrait replacement was made.

Evidence is in `build/loop1/unit-art/`. `eight-unit-comparison.png` now has four columns: current/original card, current/new card, plain-ground/new card, scene-kept/new card. `recruit-plain_1920x1080.png` and `recruit-scene_1920x1080.png` use the same real recruit state on the canopy painting. Only matching visible sample IDs are substituted for these review captures, through `tools/render_unit_art_recruit.gd`; production lookup stays intact. `tools/render_unit_art.gd` renders the sample cards.

The earlier `recruit_*` and `combat_mid_*` PNGs cover PC 1920×1080 and phone 1688×780. `reference-*.png` place them beside Everdell and Ori. Prompt files are `tools/art/prompts/loop1-unit-*.txt`; image-tool PNG masters remain outside git in `build/loop1/unit-art/masters/`.

Recruit/fight paintings are `backdrops/backdrop-highcrown-canopy-{recruit,fight}.jpg`, handed off in `bf62bf85`. Both use one upper-right cream canopy light, cool shaded corners and inhabited edges.

Validation: `./scripts/check.sh --keep-going --base 528de8d5` passed all steps again, including 2,741 Godot tests. Fresh follow-up scope review found no issues. No UI tests were rewritten or deleted; no new checks were added.

Branch is held for rebasing after the layout branch merges. Combined stump layout remains unverified here: use quiet muted surfaces with upper-right light; cards supply contact shadows. Backdrop swapping and any portrait rollout remain with the orchestrator and owner.
