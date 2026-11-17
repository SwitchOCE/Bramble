# Keywords — brief 2

## Taste calls

- **Colours and drawings:** needed marks recognisable without relying on colour. Weighed 42 colours against the approved six families with separate line drawings; chose the approved families and drawings, adding three distinct counter drawings. `assets/glass/keywords.json` is the shared source, shown in `keywords.html`; geometry and type live in `KeywordStyle`.
- **Card placement:** the owner approved bottom border, so the band was excluded. Marks sit at 92.5% of the card height, between the diamond and shield, with at most three places and overflow counted. The browser's 186 px cards use two places, including “+N” for overflow, to keep the diameter at least 15 px at 1366×768. The first measurement found only 6–7 px of numeral ink despite 20 px type. Chose at least 24 px, weight 900 lining figures; no card words were shortened.
- **Numerals:** weighed the mock-up's cream number badges against outlined figures. Chose outlined lining figures, with a dark icon inset, to keep a fixed 15 px mark while giving the numeral more solid ink. The drawing and minimum type size are in `KeywordMark` / `KeywordStyle`; the owner can swap them without changing card data.
- **Details and hint:** weighed a timed hold against Alt only; chose Alt only, matching the approved interaction and avoiding accidental panes. “Hold Alt for keyword details” changes to “Alt held · Point at a keyword”; an amber edge marks the frozen pane and selected word. Nested keywords keep their parent pane while the pointer crosses the gap.
- **Reminder wording:** numbered rules remain the content's own lines. Added general reminders for Thorns, Root, Grow and Order so references without a number still explain themselves, without inventing a value. Hit's entry is unchanged for brief 7 to rename.

## Action words and owner question

The orchestrator answered: keep Order/Bury names and costs visible outside the art. A front-row button directly below its own card would cover the back row, so chose a shared strip below the board, with F1–F4/B1–B3 identifying the unit. Names and costs remain; labels use 20 px lining type. The buttons stay off the art during travel and hide while their unit is carried. Their old click and drag actions remain; dragging a strip control resolves its owning unit by slot and picks it up at its centre.

**Question for the owner:** may Order and Bury use their matching bottom-border marks as the action buttons, with action words and costs in the tooltip? Recommend trying that later: it would keep the control attached to its unit and remove the separate strip. It removes repeated words from the card, so it was not done tonight.

## Original implementation verification (before the dev rebase)

The keyword tooltip script contains 16 focused checks, including the final plural-header regression. Coverage includes Alt freeze/release, nested terms, numbered/general reminders, hidden/spent terms, hand lowering, snapshot retention across state refreshes, all 42 visible terms, six tiers × four sizes, and seven action controls checked against every board/hand art polygon. The full gate checks the moved control's original click and drag actions too.

Original `./scripts/check.sh`: all 11 steps passed on the final production source. 378 resources compiled; 748 tests / 12,610 assertions; 15 soak games / 683 fights, zero violations; all six planted faults caught. The final film and screenshots were then regenerated. No remaining task is blocked by a denied action.

| Done when | Evidence |
|---|---|
| Marks clear the art | Shared card builder; six tiers × four heights (186, 250, 350, 400). Seven action controls each checked against all 11 board/hand unit art polygons: 77 clear intersections. Shop/board/hand images and the fight regression suite use the same builder. |
| Word, icon, colour and number | All 42 shown terms have a unique drawing, family colour and nonempty reminder; printed and granted numbers, plural names, and general reminders are covered. The main pane has no keyword reminder paragraphs; stat-source text remains. |
| Alt and nested details | 16 focused checks within the passing full suite; Decorated → Medal opens two levels; the 201-frame film report confirms fixed position and both panes closing on release. |
| Laptop size | `readability-1366.json`: minimum round diameter 15.004 px. Both “1” and “4” have 9 px of solid cream ink, versus 6–7 px in the first capture. The method excludes the icon and outline; the native crop and nearest-neighbour zoom are saved. |
| Side-by-side cards | `cards-side-by-side-1920.png` and `cards-side-by-side-1366.png` pair the unchanged approved card with ours at normal and enlarged sizes. |
| Region comparisons | 1920×1080: mean 9.48/255, 7.33% of pixels >32. 1366×768: mean 12.27/255, 10.17% >32. Both `result.json` files contain all 144 regions. Inspected the native images, pairs and storyboard as well as the scores. |

The comparisons include inherited differences: the new diamond/shield and coin drawings, duplicate glow and refresh count, card/tooltip anchor spacing, and the missing Cards entry from the parallel browser branch. The tooltip keeps the existing “unit” kind line; the page says the tribe. Detail panes show the keyword and its reminder; the page's family caption is shown on the sheet instead. These are visible differences, not a pixel-parity claim.

Captures were taken from the working tree before committing. `capture-source-sha256.json` records the final source hashes; they were checked against the committed code. Runtime work used `LP_NUM_THREADS=2`, two CPU cores, temporary XDG folders and the shared Godot lock. Images and films are outside Git.

The real Alt film has 201 frames at 60 fps (3.35 s), with two nested detail levels. Its report says the pane stayed fixed and releasing Alt closed both. `alt-flow-storyboard.png` and the two frame-labelled strips sit beside it.

Media root: `/home/alex/code/Bramble/.claude/worktrees/night-media/keywords/`.

Six Bazaar clips copied there (6.9, 9.2, 7.9, 5.6, 2.9 and 7.5 seconds). Inspected frames showing the enlarged card, colour/icon/word/number, adjacent glossary and held tooltip during combat. The approved Bramble page remains the concrete layout bar.


The approved tooltip page SHA-256 remains `fc0b80954ab2a5e8074ea279095cfe65d569afaecf24b9bdbfda107d06401006`. The screenshot adapter embeds that page unchanged and only hides its presentation around the stage. No files under `docs/design/mockups/` changed.

## Dev integration — 18 Nov 2026

Rebased baseline: `d9b3fbff` on dev's fixed duplicate glow, card browser and triple animation. The browser already used the shared `_unit_card` / `GlassTips`; no second tooltip was needed. Its `_input` handler swallowed Alt before the inherited handler could see it. Forwarded Alt press/release to `GlassTips` before the search field handles keys, preserving the approved freeze/detail/release flow even with search focused.

**Taste and layout:** kept the established bottom-border geometry and two-place overflow on 186 px cards; weighed a smaller three-mark row against the measured laptop minimum and retained the 15.004 px diameter. No colours, drawings, card words or rules changed in this pass. The owner still judges recognition and physical-display readability.

**Capture corrections:** the new fight/triple review fixture initially created a zero-sized screen in code; it now loads the real full-rect screen scenes. The existing in-game browser fixture lacked Main's canvas layer, which let Order/Bury buttons draw over the modal. It now uses the same layer 10 as `Main.open_browser`; production already did. Retook the affected captures, and the Alt capture now checks that a detail pane actually opened.

Browser integration is complete. The new regression checks both browser contexts with search focused: every grid mark stays below 86% of card height and at least 15 physical pixels at 1366×768, hover opens the shared tooltip, Alt freezes its position, Fury opens one detail, and Alt release closes both. Browser suite: 8 tests / 309 assertions. Triple suite: 19 tests / 176 assertions, including all three visible flying copies with Fury 1/Grudge and the golden with Fury 2/Grudge on their borders.

Six `tools/look/compare.py` pairs compare all, Mice/tier 5, and in-game states with the unchanged approved browser page at 1920×1080 and 1366×768. Each has `mockup.png`, `godot.png`, `stacked.png`, `diff.png` and 144 scored regions: 864 regions total. Inspected native images, pairs and difference maps; named-area measurements are in `named-regions.json`.

| State | 1920 mean /255 | Pixels >32 | 1366 mean /255 | Pixels >32 |
|---|---:|---:|---:|---:|
| All | 8.05 | 5.65% | 12.22 | 10.86% |
| Mice / tier 5 | 5.11 | 3.62% | 6.45 | 4.54% |
| In game | 8.84 | 5.77% | 11.48 | 9.66% |

The filters, grid and window retain the approved arrangement. Largest differences remain around the enlarged card: shared hover placement differs by +6 px horizontally / −7.5 px vertically from the browser page at 1920, and the shop's diamond/shield replaces its older cream discs. The shared pane says “UNIT” where the page has a tribe/type; its hint lacks the page's keycap and divider. Our 186 px marks use two places with +N overflow rather than the page's three small dots. These are recorded differences, not a pixel-parity claim; the shared component remains the source for both shop and browser.

The 1920 shots `fight/godot.png` and `dupes/godot.png` show six fight cards and the fixed gold duplicate glow with their border marks clear of art. `gather/godot.png` freezes the real buy-triggered triple at 0.60 s, with hand/board/shop copies all marked; `golden/godot.png` freezes its 1.00 s reveal with the upgraded Fury 2. `triple-with-marks.png` pairs those shots. `browser_alt/godot.png` shows the frozen browser tooltip and Fury detail. These are frozen states, not a new motion-film claim; the original 201-frame Alt film remains above.

Final integration gate: `./scripts/check.sh` passed all 12 steps, with 409 compiled resources, 800 tests / 14,340 assertions, 15 soak games / 683 fights and zero violations. All six planted soak faults were caught. The records gate reproduced two games / 30 turns / 90 checkpoints and caught a changed action. Format/lint, final fixture compilation and the rendered states were checked after the capture corrections.

Integration media: `/home/alex/code/Bramble/.claude/worktrees/night-media/keywords/integration/`. `source-sha256.json` records the captured source/test files and was checked against the commit. All runs used the shared Godot lock, two CPU cores, `LP_NUM_THREADS=2`, temporary XDG folders and detached stdin. No approval was denied during this pass. No mock-up files were edited; the browser page SHA-256 remains `30337c26e97e547aa0611132c102afce702a58784cdc88b7ee50ecf54cc4c8a5`.

## Open notes and blind spots

- Brief 7 must rename the `Hit` key in `assets/glass/keywords.json` when its display name becomes Ambush. Hit's content entry was left untouched here, as instructed; the all-terms coverage test will catch a missed style after the merge.
- Colour preference, icon recognition, the feel of holding Alt, and legibility on the owner's physical display need the owner's eyes. The 60 fps movie is deterministic software rendering; it does not measure real input latency, GPU performance or sound.
- A capture launched from a terminal stopped in Xvfb's terminal probe before any frames. The requested PID 986164 and its verified children were stopped, and `tools/feel/film` now detaches stdin. Subsequent recording uses `< /dev/null`.
- Automatic approval review denied a formatting cleanup that reconstructed pigeon display data from HEAD, citing possible loss of uncommitted work. That cleanup was abandoned; the harmless formatting expansion remains. Media writes, process cleanup and render jobs were approved.
