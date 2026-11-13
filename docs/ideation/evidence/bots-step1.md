# BOTS step 1: one best opponent

Checkpoint before this work: **887d9fc**, gate **1,258 tests / 16,100 assertions**, then soak 100 fresh seeds **471–570**, 1,518 rounds / 4,774 fights / zero violations. Reported before step 1 began.

Binding direction: owner removal note and [BOTS step 1](../BOTS.md). The game keeps today's Hard play at one strength, with no menu choice or level label. Easy/Normal profiles, their teaching-only rules, active tests and bench suites are removed. Naive remains a tools/test yardstick. Records show best placement and wins with no level; legacy saved records migrate safely. Existing evidence files are retained as history, including Plain/Easy **3.34**.

All Bird/Burner observations in commitment evidence are **Hard bot data, weak evidence**; this step makes no card edits or card-strength conclusions. Steps 2–7 are not implemented.

Final validation and inspected menu/record renders at desktop and phone sizes follow below.


## Focused validation before the final gate

Bot policy/RNG/legal-game focus **3/3 tests, 38 assertions**; records migration/config **8/8, 71 assertions**; UI **28/28, 2,364 assertions**; CLI/save/legal actions **16/16, 124 assertions**, plus three shell smokes; bench contracts **3/3, 54 assertions**. Format, lint, shell syntax and diff checks pass. The best-bot among Naive bar accepts exactly 85% top four and 45% wins and rejects either lower boundary.

Hard determinism canary: seed **73420** produces **447 exactly equal normalized probe events/rows** against the accepted pre-removal frozen runtime, with no script/engine errors. The former zero-noise offer RNG draw is deliberately preserved. The configured best policy remains 20 search fights, 30 refreshes and replacement margin 3. This is one regression canary plus policy inspection, not an exhaustive strategy-strength proof.

Records merge the known Easy/Normal/Hard legacy sections once into overall best/wins/games, retain unknown/legacy data, sanitize invalid values, saturate counters and avoid overwriting malformed files. Tools-only Naive history is not a player record. New CLI saves contain seed/actions only; legacy Hard metadata replays current rules, retired-strength saves are refused without changing the file, and malformed/refused actions give a readable failure. Historical evidence remains untouched.


## Final gate, soak and inspected renders

**Gate PASS:** all ten steps, **1,250/1,250 tests / 15,984 assertions / 115 scripts**, strict clean; **371 scripts compile, zero failures**. Runtime commit **7796d0e**; final amendments add only evidence and generated test UID metadata. Logs and runtime stamp: `build/sim/bots-step1-final/`.


The first final soak, seeds 671–770, hit its **240-second process limit**; it is not accepted or reported as a pass. The game now uses the best bot in the real-game soak cohort, so the old short limit is insufficient. The gate remains valid and source is unchanged. Retry: **100 fresh seeds 771–870**, core 2, detached with a **600-second hard timeout**; no search-budget, bot-policy or card change. Original timeout logs are retained in `build/sim/bots-step1-final/`; retry logs in `build/sim/bots-step1-soak-retry/`.


**Retry soak PASS:** 100 games, fresh seeds **771–870**, **1,504 rounds / 4,790 fights / zero violations**, exit 0. Three fights ended with no attacks available. Runtime was 339.2 seconds; source remains the gate-tested runtime `7796d0e`. Complete retry evidence: `build/sim/bots-step1-soak-retry/soak-summary.log` and `soak.log`.

All four native-size menu renders were visually inspected after the passing gate and retry soak. New game has no strength chooser; the single record summary shows best placement and wins without a level label. Text and controls fit without clipping or scrolling at both sizes. The populated example reads “Best 1st · 1 win”.

| Screen | Desktop, 1920×1080 | Phone, 1688×780 |
|---|---|---|
| New menu | [Desktop](bots-step1-ui/menu-desktop.jpg) | [Phone](bots-step1-ui/menu-phone.jpg) |
| Saved record | [Desktop](bots-step1-ui/menu_records-desktop.jpg) | [Phone](bots-step1-ui/menu_records-phone.jpg) |

Render logs: `build/screens/menu_*.log` and `menu_records_*.log`; all four completed without script/engine errors. This is a layout render check, not a physical-device playtest.
