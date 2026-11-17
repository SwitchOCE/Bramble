# Keywords — brief 2

## Taste calls

- **Colours and drawings:** needed marks recognisable without relying on colour. Weighed 42 colours against the approved six families with separate line drawings; chose the approved families and drawings, adding three distinct counter drawings. `assets/glass/keywords.json` is the shared source, shown in `keywords.html`; geometry and type live in `KeywordStyle`.
- **Card placement:** the owner approved bottom border, so the band was excluded. Marks sit at 92.5% of the card height, between the diamond and shield, with at most three places and overflow counted. The browser's 186 px cards use two places, including “+N” for overflow, to keep the diameter at least 15 px at 1366×768. The first measurement found only 6–7 px of numeral ink despite 20 px type. Chose at least 24 px, weight 900 lining figures; no card words were shortened.
- **Numerals:** weighed the mock-up's cream number badges against outlined figures. Chose outlined lining figures, with a dark icon inset, to keep a fixed 15 px mark while giving the numeral more solid ink. The drawing and minimum type size are in `KeywordMark` / `KeywordStyle`; the owner can swap them without changing card data.
- **Details and hint:** weighed a timed hold against Alt only; chose Alt only, matching the approved interaction and avoiding accidental panes. “Hold Alt for keyword details” changes to “Alt held · Point at a keyword”; an amber edge marks the frozen pane and selected word. Nested keywords keep their parent pane while the pointer crosses the gap.
- **Reminder wording:** numbered rules remain the content's own lines. Added general reminders for Thorns, Root, Grow and Order so references without a number still explain themselves, without inventing a value. Hit's entry is unchanged for brief 7 to rename.

## Action words and owner question

PR 129 scope review removed the strip from this PR. The orchestrator saved it on `night/keywords-action-strip` as a candidate for the owner, who has not seen it; F1–F4/B1–B3 can read like keyboard shortcuts. That candidate branch was not changed here.

Order and Bury now use `origin/dev`'s exact button placement, labels, sizing and click/drag behaviour. Their words remain over the art, a known issue waiting on the owner. No other placement was built. The general tooltip edge clamp, hidden-card skip, border marks, nested details and browser Alt fix remain.

**Question for the owner:** consider the saved strip candidate against using the matching bottom-border marks as action buttons, with action words and costs in the tooltip. Recommend reviewing the saved candidate first; folding the words into marks still needs the owner's approval and was not done in this PR.

## Original implementation verification (before the dev rebase)

The current keyword tooltip script contains 14 focused checks, including the plural-header regression. Coverage includes Alt freeze/release, nested terms, numbered/general reminders, hidden/spent terms, hand lowering, snapshot retention across state refreshes, all 42 visible terms, and six tiers × four sizes. The two strip-only checks were removed in scope review; dev's existing Order/Bury click and drag checks are restored.

The original counts and captures below describe the saved strip candidate before scope review. They are historical evidence for the marks and tooltip; they do not show this PR's restored action-button placement.

Original `./scripts/check.sh`: all 11 steps passed on the final production source. 378 resources compiled; 748 tests / 12,610 assertions; 15 soak games / 683 fights, zero violations; all six planted faults caught. The final film and screenshots were then regenerated. No remaining task is blocked by a denied action.

| Done when | Evidence |
|---|---|
| Marks clear the art | Shared card builder; six tiers × four heights (186, 250, 350, 400). Shop/board/hand images and the fight regression suite use the same builder. |
| Word, icon, colour and number | All 42 shown terms have a unique drawing, family colour and nonempty reminder; printed and granted numbers, plural names, and general reminders are covered. The main pane has no keyword reminder paragraphs; stat-source text remains. |
| Alt and nested details | 14 retained focused checks; Decorated → Medal opens two levels; the 201-frame film report confirms fixed position and both panes closing on release. |
| Laptop size | `readability-1366.json`: minimum round diameter 15.004 px. Both “1” and “4” have 9 px of solid cream ink, versus 6–7 px in the first capture. The method excludes the icon and outline; the native crop and nearest-neighbour zoom are saved. |
| Side-by-side cards | `cards-side-by-side-1920.png` and `cards-side-by-side-1366.png` pair the unchanged approved card with ours at normal and enlarged sizes. |
| Region comparisons | 1920×1080: mean 9.48/255, 7.33% of pixels >32. 1366×768: mean 12.27/255, 10.17% >32. Both `result.json` files contain all 144 regions. Inspected the native images, pairs and storyboard as well as the scores. |

The comparisons include inherited differences: the new diamond/shield and coin drawings, duplicate glow and refresh count, card/tooltip anchor spacing, and the missing Cards entry from the parallel browser branch. The tooltip keeps the existing “unit” kind line; the page says the tribe. Detail panes show the keyword and its reminder; the page's family caption is shown on the sheet instead. These are visible differences, not a pixel-parity claim.

Captures were taken from the working tree before committing. `capture-source-sha256.json` records the final source hashes; they were checked against the committed code. Runtime work used `LP_NUM_THREADS=2`, two CPU cores, temporary XDG folders and the shared Godot lock. Images and films are outside Git.

The real Alt film has 201 frames at 60 fps (3.35 s), with two nested detail levels. Its report says the pane stayed fixed and releasing Alt closed both. `alt-flow-storyboard.png` and the two frame-labelled strips sit beside it.

Media root: `media/keywords/`.

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

Pre-scope-review integration gate: `./scripts/check.sh` passed all 12 steps, with 409 compiled resources, 800 tests / 14,340 assertions, 15 soak games / 683 fights and zero violations. All six planted soak faults were caught. The records gate reproduced two games / 30 turns / 90 checkpoints and caught a changed action. Format/lint, final fixture compilation and the rendered states were checked after the capture corrections.

Integration media: `media/keywords/integration/`. `source-sha256.json` records the captured source/test files and was checked against the commit. All runs used the shared Godot lock, two CPU cores, `LP_NUM_THREADS=2`, temporary XDG folders and detached stdin. No approval was denied during this pass. No mock-up files were edited; the browser page SHA-256 remains `30337c26e97e547aa0611132c102afce702a58784cdc88b7ee50ecf54cc4c8a5`.

## PR 129 scope correction

Restored `recruit_buttons.gd`, `recruit_input.gd`, `recruit_screen.gd`, `recruit_board.gd` and `test_recruit_core.gd` byte-for-byte from `origin/dev`. Restored the ability button's original `GlassParts` style and beside-card hover anchor; removed strip-only style constants and two strip tests. The other `test_recruit_screen.gd` changes cover keyword marks/reminders, so they remain.

The 16 hidden Pigeon display entries are back in dev's one-line form. Their JSON values are unchanged; the Pigeon diff now contains only the two added `reminder_general` fields (and their required commas). No formatter rewrote the compact entries.

Scope check: `./scripts/check.sh` passed all 12 steps with 409 compiled resources, 798 tests / 14,215 assertions, 15 soak games / 683 fights and zero violations. All six planted faults were caught; records reproduced two games / 30 turns / 90 checkpoints and caught the changed action. The Pigeon file stayed byte-identical throughout the gate. The earlier media and source manifests refer to the saved candidate, not this correction; no new screenshot claim is made for the restored buttons over art.

## Open notes and blind spots

- Brief 7 must rename the `Hit` key in `assets/glass/keywords.json` when its display name becomes Ambush. Hit's content entry was left untouched here, as instructed; the all-terms coverage test will catch a missed style after the merge.
- Colour preference, icon recognition, the feel of holding Alt, and legibility on the owner's physical display need the owner's eyes. The 60 fps movie is deterministic software rendering; it does not measure real input latency, GPU performance or sound.
- A capture launched from a terminal stopped in Xvfb's terminal probe before any frames. The requested PID 986164 and its verified children were stopped, and `tools/feel/film` now detaches stdin. Subsequent recording uses `< /dev/null`.
- Automatic approval review denied a formatting cleanup that reconstructed pigeon display data from HEAD, citing possible loss of uncommitted work. That cleanup was abandoned at the time. The orchestrator explicitly authorized compacting the hidden entries in this scope review; that change is now made. Media writes, process cleanup and render jobs were approved.

## Owner follow-up — 18 November 2026

Supersedes the Alt interaction above. Card hover now opens every keyword's separate box immediately, plus terms named in those reminders one level deeper, with each term shown once. Alt has no tooltip action, freeze or hint. Shop, board, hand, fight, Discover and browser use the shared flow; a state refresh rebuilds the current hover instead of retaining a snapshot.

**Layout choice:** keep the existing enlarged card and words pane, then stack separate reminder boxes in nearby free space, using another column or space below when an edge is full. Packing leaves the hovered source card, enlarged card, words and sibling panes clear, within the 1920×1080 stage scaled to either window size. Border marks replace the card pane with that keyword's box and its one nested level. Their hit rectangles grow by 4 stage pixels on each side; drawings and positions stay unchanged, and a drawn mark takes priority over a neighbour's padded area. Browser “+N” remains overflow, opening the card's full details.

The [owner's exact line-break rule](../../design/owner-notes/2026-11-18b-one-effect-per-line.md) now lives in the renderer, including plain tooltip and Discover text. Separate sentences start new effect lines; long effects still wrap naturally. Commas, decimal points and abbreviations stay within their effect. No content files changed.

| Card | Before | After (effect lines) |
|---|---|---|
| Shrew Cutpurse | Pile on. The first time this piles on each fight, gain 1 gold. | Pile on.<br>The first time this piles on each fight, gain 1 gold. |
| Flying Ace | Sortie. After this kills, earn a Medal. Decorated: Cleave. | Sortie.<br>After this kills, earn a Medal.<br>Decorated: Cleave. |
| Grenadier Guard | `[Order (1)] : Make a slot your [Guard post] . At the end of your turn, give your [Guard post +2] /+4.` | `[Order (1)]: Make a slot your [Guard post].`<br>`At the end of your turn, give your [Guard post] +2/+4.` |

Grenadier's stat buff stays outside the mark: a suffix is a keyword count only for a numbered keyword, and slash pairs or following Attack/Health remain prose. Punctuation stays against its mark and travels with it when wrapping. Regression coverage walks every normal and golden card, checks numbered marks against stat continuations, and covers literal and symbolic buffs.

Media: `/home/alex/code/Bramble/.claude/worktrees/n18-media/tipfix/`. `shop-1920.png`, `shop-1366.png`, `icon-1920.png` and `icon-1366.png` show Hedge Knight's two keywords and one nested reminder, then its Fury border hover. `grenadier-before-{1920,1366}.png` uses the original `8f55bcca` source in an isolated temporary project; `grenadier-after-{1920,1366}.png` uses this change. All eight shots were inspected at native size. `source-sha256.json` records the captured production/fixture source; logs sit beside the images. Runtime work uses `LP_NUM_THREADS=2`, two CPU cores and temporary XDG directories.

Final gate: `check.sh: all steps passed` — all 12 steps; 411 compiled resources; 812 tests / 15,699 assertions; 15 soak games / 683 fights, zero violations; all six planted faults caught; two replay games / 30 turns / 90 checkpoints matched and the altered action was caught. Set `FEEL_TMP=/tmp/tipfix-feel` for the sandbox. The gate's strict-hook presence check now consumes the full log, avoiding a `grep -q` / `pipefail` false failure after otherwise passing tests. The three parallel shop files were untouched; no approval was denied.

## Owner layout correction — 18 November 2026

Replaces the free-space packing choice above. Keyword boxes now touch in one column directly under the card's words, with the same width. The whole group moves together to stay on screen; only when that column cannot fit does the intact keyword stack sit beside the words, on the side away from the enlarged card. The hovered card, End turn label/button and both hero portraits (including their health badges) are protected from overlap. Icon-only reminders also stay in one joined column.

Added real Hedge Knight/Grenadier regressions, protected-control checks throughout the catalog/edge/icon coverage, and direct tests of below-first placement and left/right side fallback. Retook shop and Grenadier-after shots at both requested sizes, plus icon shots, in the same media directory. The capture fixture now reads the full display so the laptop PNG is exactly 1366×768, including the aspect-fit edge pixel. The approved `check.sh` grep fix is unchanged.

Verification: `check.sh: all steps passed` — all 12 steps; 412 compiled resources; 817 tests / 19,182 assertions; 15 soak games / 683 fights with zero violations; all six planted faults caught; two replay games / 30 turns / 90 checkpoints matched. An earlier contended run hit two drag timer/Tween assertions; the focused 49-test drag suite and final full gate passed without changing those tests or their timing limits. The final gate used `LP_NUM_THREADS=2`, CPUs 2–3 and temporary XDG/film directories. Capture hashes match the final source; no approval was denied.
