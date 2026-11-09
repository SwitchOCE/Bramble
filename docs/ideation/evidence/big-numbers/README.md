# Phone big-number check — BRAMBLE ideation

Follow-up, 9 November 2026: the owner requested fitted numerals, compact values from
10,000, and exact values one tap away. Rendered at the project's phone size,
1688×780 landscape (844×390 points at 2×), using real recruit/combat widgets.
Every screenshot has a full 4-front/3-back board; combat shows both full boards.

| Original stat size | Recruit | Combat |
| --- | --- | --- |
| 4 digits | [Full values](recruit-4-digits.png) | [Full values](combat-4-digits.png) |
| 5 digits | [Compact thousands](recruit-5-digits.png) | [Compact thousands](combat-5-digits.png) |
| 7 digits | [Compact millions + tapped details](recruit-7-digits.png) | [Compact millions + tapped details](combat-7-digits.png) |

**Fit and reading:** all six renders keep numbers inside their fixed stat badges.
Four digits remain exact. Five digits use readable `k` labels; seven digits use `m`.
The seven-digit captures tap F2 once, revealing **Attack: 1,234,567** and
**Health: 9,999,998** in normal-size detail text while the board remains visible.
Numerals shrink to fit the existing badges, rather than growing over neighbouring
cards; this is an owner-requested exception to the normal body-text font minimum.
Rules, names and exact detail text keep their existing font sizes.

Formatting rounds to one decimal and omits `.0`: `12,345 → 12.3k`,
`1,234,567 → 1.2m`. At a rounding boundary the suffix advances: `999,950 → 1m`;
`99,999 → 100k`. A billion uses `b`. These are display approximations only:
the view, game rules, comparisons and combat retain exact integers. A single tap
opens exact, comma-grouped Attack and Health; inspected combat stats refresh with
subsequent damage or buffs. Four-digit values can also be read exactly in their badges.

The deterministic fixture is `tests/ui/big_number_states.gd`. It includes values near
both ends of each requested digit range; Health reverses the Attack order. The four
new UI tests cover rounding boundaries, fixed badge footprints and text fitting,
font recovery after stat changes, complete phone recruit/combat layouts, one-tap
exact values, and exact Health updating during playback.

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
retained as the **before** evidence: their five-digit values clipped. The six images
above supersede that visual limitation. This is a rendered phone-layout check, not
a physical-device study.


Verification: **PASS**, `./scripts/check.sh`, all eleven steps; **1,632/1,632 Godot
tests, 25,044 assertions**, plus 53 Python tests. [Gate log](gate.log.txt).
The new focused UI suite passes **4/4 tests, 532 assertions** without warnings or
pending/risky tests ([focused log](focused.log.txt)). All six PNGs are 1688×780;
the final render run logged no script errors. No core mechanics, simulation harness
or bot files changed in this follow-up. No actions were denied; nothing remains
unfinished for this request.
