# Redbreast overview label regression

Confirmed on `69fb304`; fixed in `fd3d86b`.

The Ring badge reserved part of the name strip, reducing its available width from 151 to 108 canvas pixels. “Redbreast” needs 126 at the unchanged 31-pixel font. `fit_name()` therefore returned an empty string. Witch and Hearth still fit, which explains the selective disappearance. The correction reclaims excess horizontal padding from the coordinate chip, Ring badge and their gaps. The complete last word now fits alongside B2 and ×2, without reducing the font or overlapping labels.

The initial regression [fails before the fix](test-before.log). The expanded [focused suite passes 2/2 tests and 88 assertions](test-after.log). It checks the exact B1 Witch, B2 Redbreast and B3 Hearth names at both requested window sizes, complete-word width, coordinate visibility, badge bounds, no overlap, the font minimum and restoration after returning from the reader to the overview. Existing narrow-pocket and large-count checks remain.

| Window | Previous overview, with the regression | Corrected overview |
|---|---|---|
| 1688×780 | [Previous](../ui-followup/ui-after-overview-1688x780.png) | [Corrected](ui-after-overview-1688x780.png) |
| 1920×1080 | [Previous](../ui-followup/ui-after-overview-1920x1080.png) | [Corrected](ui-after-overview-1920x1080.png) |

These are native, unedited production-UI captures from the existing `wave1_ui_followup.gd` driver on `fd3d86b`. The exact input states match the prior after captures; [verification](verification.json) records state and PNG hashes, dimensions and empty layout-note lists. The driver generates three scenes per size; only the corrected overview is retained here. Renderer logs: [phone](render-1688x780.log), [PC](render-1920x1080.log). Visual inspection confirms the complete B2 label and clear adjacent names and counters.

Every Godot run used `/opt/bramble/env.sh`, the shared lock and the 3G user scope. The [full gate](quality-gate.log) **passes on `fd3d86b`: 1,798 tests, 29,563 assertions, 164 scripts, strict hook clean**, with all other checks passing. Command:

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G timeout 1800 ./scripts/check.sh > docs/ideation/evidence/wave1/redbreast-label/quality-gate.log 2>&1
```
