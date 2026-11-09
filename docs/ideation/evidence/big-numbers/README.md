# Phone big-number check — BRAMBLE ideation

Rendered early, 9 November 2026, at the project's phone size (1688×780 landscape,
844×390 points at 2×), using the existing screenshot driver and real UI widgets.
Full 4-front/3-back boards contain 1234, 5678, 9999, 10000, 23456, 88888 and 99999
Attack and reversed Health values. Screens: [recruit](recruit.png), [paused combat start](combat.png).

Four digits read, although tightly. Five digits **do not reliably fit**: digits extend
past the fixed stat badges and clip at card edges, especially Health. The phone UI
therefore supports a four-digit visual target today; a five-digit era needs a separate
badge/layout change. No abbreviation or smaller text was introduced to mask the failure.
This is a rendered layout check, not a physical-device readability study.

Reproduce, one run at a time, after `source /opt/bramble/env.sh`:

```sh
systemd-run --user --scope -p MemoryMax=3G timeout 120 xvfb-run -a \
  -s '-screen 0 2560x1440x24' godot --rendering-driver opengl3 --audio-driver Dummy \
  -s res://tests/ui/shots/big_numbers.gd -- recruit 1688x780 \
  res://docs/ideation/evidence/big-numbers/recruit.png
# Repeat with combat and combat.png.
```
