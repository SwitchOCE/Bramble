# Phone big-number check — BRAMBLE ideation

Follow-up, 9 November 2026: the requester requires every stat numeral to keep the
shared font minimum (`UiTheme.MIN_FONT`, 31 canvas units). This supersedes the
requester's earlier exception allowing numerals to shrink below the minimum.
The phone target is 1688×780 landscape (844×390 points at 2×), using real
recruit/combat widgets. Every fixture has a full 4-front/3-back board; combat
shows both full boards.

| Original stat size | Recruit | Combat |
| --- | --- | --- |
| 4 digits | [Adaptive thousands + tapped details](recruit-4-digits.png) | [Adaptive thousands + tapped details](combat-4-digits.png) |
| 5 digits | [Compact thousands](recruit-5-digits.png) | [Compact thousands](combat-5-digits.png) |
| 7 digits | [Compact millions + tapped details](recruit-7-digits.png) | [Compact millions + tapped details](combat-7-digits.png) |

**Current policy:** full values below 10,000 stay exact when they fit at the
minimum font size. Otherwise the badge uses compact notation, including below
10,000. Values from 10,000 normally use one decimal, omitting `.0`:
`12,345 → 12.3k`, `1,234,567 → 1.2m`. The formatter first drops decimal precision
when necessary (`12,345 → 12k`). At a rounding boundary the suffix advances:
`999,950 → 1m` with one decimal; `999,500 → 1m` with whole-unit precision.

For the narrowest badges, a final fallback uses tenths of the next suffix without
a leading zero, such as `.1m` for approximately 100,000 or `.1b` for approximately
100,000,000. It never replaces a positive value with `0m` or `0b`. The smallest
badges may widen just enough for the shortest representation at size 31; the
supported nonnegative stat range through the game's one-billion clamp stays
within the existing 84-unit maximum. Their positions preserve center clearance
even on a 96-unit card. Normal small values keep their existing badge sizing.

These are display approximations only: views, game rules, comparisons and combat
retain exact integers. One tap opens comma-grouped Attack and Health for values
from 1,000, including four-digit stats newly compacted by fitting. Smaller stats
remain exact in their badges. Inspected combat stats refresh with subsequent
damage or buffs. The four- and seven-digit screenshot fixtures tap F2 once;
the seven-digit exact details read **Attack: 1,234,567** and **Health: 9,999,998**.

The deterministic fixture is `tests/ui/big_number_states.gd`. It includes values
near both ends of each requested digit range; Health reverses the Attack order.
Focused UI tests cover rounding, adaptive precision, fixed maximum footprints,
non-overlapping badges, the font minimum, font recovery, complete phone layouts,
one-tap exact values below and above 10,000, and live exact Health updates.
The layout checker no longer has a stat-font exception.

Reproduce, **one run at a time**, after `source /opt/bramble/env.sh`:

```sh
for screen in recruit combat; do
  for digits in 4 5 7; do
    systemd-run --user --scope -p MemoryMax=3G timeout 120 xvfb-run -a \
      -s '-screen 0 2560x1440x24' godot --rendering-driver opengl3 --audio-driver Dummy \
      -s res://tests/ui/shots/big_numbers.gd -- "${screen}_${digits}" 1688x780 \
      "res://docs/ideation/evidence/big-numbers/${screen}-${digits}-digits.png"
  done
done
```

The earlier mixed-size [recruit](recruit.png) and [combat](combat.png) captures are
retained as **before** evidence: their five-digit values clipped. This is a
rendered phone-layout check, not a physical-device study.

**Verification:** all six PNGs were regenerated on 9 November 2026 at the
restored minimum and visually inspected. The [focused suite](focused.log.txt)
passed **6/6 tests, 1,844 assertions**. The [full gate](gate.log.txt) passed all
11 steps, including **1,649/1,649 GUT tests, 26,770 assertions** and 53 Python
tests. Labels fit and remain readable at this rendered phone size; compact
precision varies by available badge width. This is not a physical-device study.
