# Loop 1: units toward the woodland

The unit card is warm paper with a thin olive-bark edge, a cream upper-right highlight and a soft lower-left contact shadow. Portrait colours receive a restrained, uniform warm/desaturated grade; no texture or detail is added. Attack, Health, keywords, frost, selection and golden states retain their existing symbols and anchors. All card-only values live in `card_view.gd`; no shared theme file changed.

Eight reference-led Ink-B repaints are in `assets/portraits_v2/`: Mrs Mallow, Lob-Lie-by-the-Fire, Wee Wobbly, Grey Agnes, the Lantern Man, Mrs Jay, the Lane-Bard and Pill Bug. They cover the current tribes and a neutral. Owner question: **all units like this?** No wider repaint was made or mixed set put into the game. The model retained subtle tonal variation despite retries; exact flat-fill export remains an open choice for this study. `tools/render_unit_art.gd` substitutes portraits for review only; gameplay still uses the originals. Prompts are `tools/art/prompts/loop1-unit-*.txt`; generated PNG masters and discarded trials stay in `build/loop1/unit-art/masters/` outside git.

New paintings: `backdrops/backdrop-highcrown-canopy-recruit.jpg` and `backdrops/backdrop-highcrown-canopy-fight.jpg`. Both keep one cream canopy light from upper right, cool shadowed roots and leaves, edge homes, lamps and worn paths. The fight variant gathers cooler shadow around the same clearing. Their prompts are `loop1-highcrown-*.txt`.

Look in `build/loop1/unit-art/`: `recruit_1920x1080.png`, `recruit_1688x780.png`, `combat_mid_1920x1080.png` and `combat_mid_1688x780.png` are real game renders on the respective new paintings. `eight-unit-comparison.png` shows current/current, current/new and repaint/new. `reference-*.png` set recruit and fight at both sizes beside Everdell and Ori references.

Validation: `./scripts/check.sh --keep-going --base 528de8d5` passed all steps, including 2,741 Godot tests. Fresh scope review found no material issue. No UI tests were rewritten or deleted, and no new checks were added. Live phone hover/reader and frozen/selected renders were also inspected.

First backdrop handoff: commit `bf62bf85`.

For integration: these shots use this branch's existing layout. The layout worker's painted stump counter is not available here. It should receive upper-right cream light with a quiet, muted surface under cards; cards supply their own small contact shadows and need no wooden sockets. The orchestrator chooses the portrait rollout and swaps backdrop files into `assets/ui/world/`; those changes remain outside this step.
