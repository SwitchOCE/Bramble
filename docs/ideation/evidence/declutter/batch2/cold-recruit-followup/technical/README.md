# Technical evidence — contains scenario meanings

Production: `58e836078b79af4ff7085b667a5ea06d1a11443c`. Reader participants receive only the sibling `reader/` directory.

All eight designed states execute unchanged shipped cards through actual production callbacks and core rules.
The older Committee End-of-Turn variant remains in its original packet and is not used here.
No cold-reader result is claimed by capture or validation.
Every final frame is captured two fixed ticks beyond the cue duration, with the helper inactive and no visible action overlay remaining (asserted in capture and report).
Tier-up emits no recruit-log event in the current core; its actual empty stream is preserved, and tier/gold are checked directly.

| Case | Action | Mode | Cue duration |
| --- | --- | --- | --- |
| A | play | reduce | 0.360s |
| A | play | x1 | 0.360s |
| B | ooze | reduce | 0.540s |
| B | ooze | x1 | 0.540s |
| C | buy | reduce | 0.540s |
| C | buy | x1 | 0.540s |
| D | scout | reduce | 0.400s |
| D | scout | x1 | 0.400s |
| E | triple | reduce | 0.540s |
| E | triple | x1 | 0.540s |
| F | bird | reduce | 0.580s |
| F | bird | x1 | 0.580s |
| G | sell | reduce | 0.540s |
| G | sell | x1 | 0.540s |
| H | tier-up | reduce | 0.560s |
| H | tier-up | x1 | 0.560s |

## Words and labels at rest

Every live visible text node remains counted, including numeric stats and hero Health.
The separate tile-word classifier scopes shop, hand and both boards by actual widget ownership.
The original <=40 recruit/scout gate remains on its defined states. The full ten-card fan is a separate stress edge case: all hand stats remain, its full raw count is reported, and no occlusion exemption is used.
An open-reader row is reported separately from the resting-view gate.
It cannot detect lettering inside raster art; the report requires a separate native visual audit.
The ten spec rows link unchanged historical before images to fresh matching afters in paired-stills.json.

| State | Stage | Size | All text nodes | Tile words | Legacy-name words |
| --- | --- | --- | --- | --- | --- |
| A | before | 1688x780 | 27 | 0 | 0 |
| A | after | 1688x780 | 27 | 0 | 0 |
| B | before | 1688x780 | 27 | 0 | 0 |
| B | after | 1688x780 | 26 | 0 | 0 |
| C | before | 1688x780 | 25 | 0 | 0 |
| C | after | 1688x780 | 25 | 0 | 0 |
| D | before | 1688x780 | 13 | 0 | 0 |
| D | after | 1688x780 | 13 | 0 | 0 |
| E | before | 1688x780 | 29 | 0 | 0 |
| E | after | 1688x780 | 25 | 0 | 0 |
| F | before | 1688x780 | 27 | 0 | 0 |
| F | after | 1688x780 | 28 | 0 | 0 |
| G | before | 1688x780 | 27 | 0 | 0 |
| G | after | 1688x780 | 25 | 0 | 0 |
| H | before | 1688x780 | 25 | 0 | 0 |
| H | after | 1688x780 | 25 | 0 | 0 |
| spec-lobby | before | 1688x780 | 39 | 0 | 0 |
| spec-natural-birds | before | 1688x780 | 30 | 0 | 0 |
| spec-overview | before | 1688x780 | 40 | 0 | 0 |
| spec-reader-reel_mistress-golden | before | 1688x780 | 51 | 0 | 0 |
| spec-scout | before | 1688x780 | 30 | 0 | 0 |
| fan10 | before | 1688x780 | 61 | 0 | 0 |
| A | before | 1920x1080 | 27 | 0 | 0 |
| A | after | 1920x1080 | 27 | 0 | 0 |
| B | before | 1920x1080 | 27 | 0 | 0 |
| B | after | 1920x1080 | 26 | 0 | 0 |
| C | before | 1920x1080 | 25 | 0 | 0 |
| C | after | 1920x1080 | 25 | 0 | 0 |
| D | before | 1920x1080 | 13 | 0 | 0 |
| D | after | 1920x1080 | 13 | 0 | 0 |
| E | before | 1920x1080 | 29 | 0 | 0 |
| E | after | 1920x1080 | 25 | 0 | 0 |
| F | before | 1920x1080 | 27 | 0 | 0 |
| F | after | 1920x1080 | 28 | 0 | 0 |
| G | before | 1920x1080 | 27 | 0 | 0 |
| G | after | 1920x1080 | 25 | 0 | 0 |
| H | before | 1920x1080 | 25 | 0 | 0 |
| H | after | 1920x1080 | 25 | 0 | 0 |
| spec-lobby | before | 1920x1080 | 39 | 0 | 0 |
| spec-natural-birds | before | 1920x1080 | 30 | 0 | 0 |
| spec-overview | before | 1920x1080 | 40 | 0 | 0 |
| spec-reader-reel_mistress-golden | before | 1920x1080 | 51 | 0 | 0 |
| spec-scout | before | 1920x1080 | 30 | 0 | 0 |
| fan10 | before | 1920x1080 | 61 | 0 | 0 |
