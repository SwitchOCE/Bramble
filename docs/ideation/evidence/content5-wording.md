# Content5 wording — 8 November 2026

Merged `origin/ideation/main` at `cc90a61` (includes `b2c3f01`) as `45f719a`. Resolved the reminder-schema conflict using main's shortened shared reminders while retaining content5 mechanic/effect registrations. Main's `text`/`details`, CardRulings and ReminderSlip architecture is unchanged.

Only the four content5 cards and their added vocabulary were reworded, following `wording-guide.md` and the owner's concise-wording direction. Effect data, numbers, costs and tiers compare identical to the merged baseline after excluding presentation fields; no runtime rules changed.

Measured using `tools/research/word_counts.py` and its `words()` function; baseline `45f719a`:

| Card | Normal before → after | Golden before → after |
|---|---:|---:|
| Horseshoe | 14 → 9 | — |
| Barn Owl | 12 → 9 | 12 → 9 |
| Redwing | 12 → 10 | 13 → 11 |
| Market Stall | 19 → 10 | — |

Four-card median: 13 → 9.5 words; maximum: 19 → 10. Egg reminder: 38 → 8 words. Removed redundant Horseshoe (36 words) and Market Stall (33 words) card-name reminders; their rulings now live in Details. Owl's quarry refusal is in Details, not a standalone Quarry label.

Counts: `content5-wording/counts.json`; full tool output: `content5-wording/library-counts.txt`.

Rendered and visually inspected native-size PC (1920×1080, Horseshoe/Owl) and phone (1688×780, golden Redwing/Stall) [PC](content5-wording/details-1920x1080.jpg) and [phone](content5-wording/details-1688x780.jpg) JPEGs, both showing two real CardDetail panels with open Details slips. LayoutCheck passed; text is readable, unclipped, and separated into upright rules and smaller italic details.

Validation:

- Targeted tests: 37/37 passed, 980 assertions; content validation/format/lint clean.
- One final `./scripts/check.sh`: all ten steps passed; 402 compiled files, 1,392 tests, 19,510 assertions, strict hook clean. Hard timeout 900 seconds.
- Subsequent `tools/checks/soak.sh 100 801942679`: passed; 1,594 rounds, 4,903 fights, zero violations, 393.8 seconds. Hard timeout 1,200 seconds.
