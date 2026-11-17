# Card browser — brief 9

## Taste calls

- **Order:** needed a predictable way to find cards without a planner. Weighed a flat alphabetic list against the approved tier groups; chose tiers, then Badgers/Mice/Pigeons/Locusts/Briars, then name, with tokens last. Filters combine; all totals come from `GameContent`, including tokens and excluding the hidden system Triple Reward.
- **Search:** the approved field was drawn but inactive. Weighed omitting it against name/text matching; chose live, case-insensitive matching of names and resolved rules text, intersected with kind/tribe/tier. It resets the scroll and explains an empty result; no extra search syntax.
- **During a game:** weighed fight access against the required recruit entry only. Chose recruit only tonight: the round Cards button opens a dimmed layer with Close, keeping the game and UI nodes in place and disabling their processing/input. Close or Escape resumes the same nodes; fights retain their existing skip controls.
- **Start (review correction):** the orchestrator says restore: the approved Cards addition did not authorize removing the tribe picker. The game again supplies tribes/names and restores the previous game's choice, with toggle/Only controls and Play/Cards/Quit in the existing expanded layout. The compact layout remains for callers with no tribes.
- **Cards ring — owner question:** weighed keeping the approved amber ring against treating it as the mock-up's temporary “new” marker. Kept the ring in both start layouts, as the review requests. Should it stay permanently, or disappear once the button is familiar? Only that decoration rests on the answer.
- **Hover and card marks:** weighed a browser-specific reproduction of the approved tooltip against the required shared component. Chose `GlassTips` (`src/screens/glass_tips.gd`), the card-hover base that the shop's `RecruitTips` delegates to, and the existing `GlassScreen` card makers. Brief 2's shared tooltip/keyword work therefore reaches this browser; current differences are recorded in the comparison results rather than copied into a second tooltip.
- **Look:** used round 2's stage geometry, filter sizes, grouped grid and compact spell cells, with the shop branch's chosen coins and Attack/Health shapes. New look constants live in `BrowserLook`; approved mock-up files are untouched. The saved HTML reference adapter only hides the page's presentation and selects its existing five states.

## Original implementation verification

- Strict compilation: 378 resources, zero failures.
- Catalog suite: 5 tests, 859 assertions; reads 99 units (including 4 tokens) and 3 offered spells from content, covers 42 tribe/tier combinations and 7 spell-tier combinations, names/resolved-text search and deterministic ordering.
- Browser integration suite: 5 tests, 51 assertions; switches hide/reset tribe, reaches the last token by scrolling, uses `GlassTips` for units and spells, ignores offscreen targets, opens from both buttons, and preserves the live game's view/events/recruit UI/leaderboard/phase across Close. Escape closes; carrying a card prevents entry.
- The first broader run caught cached recruit geometry being shared with the browser. The browser now duplicates it before applying its layout; a regression assertion checks that the shared geometry stays unchanged. The integration tests wait for deferred UI deletion and report no orphans. Visual comparison also caught initial sizing of a browser created in code; explicit full-rect sizing and a resize connection fix it, with a frame-position assertion.
- Approved page SHA-256: `30337c26e97e547aa0611132c102afce702a58784cdc88b7ee50ecf54cc4c8a5`.

- `./scripts/check.sh`: all 11 steps passed with the final code; 378 resources, 735 tests / 12,776 assertions; 15 games / 683 fights across mixed and shipped-only soaks, zero violations; all six planted faults caught. The motion tool's own check filmed 126 frames at 60 fps and confirmed its drag/drop.
- Runtime/check environment: `LP_NUM_THREADS=2`, `XDG_CONFIG_HOME=/tmp/n18-browser-config`, `XDG_DATA_HOME=/tmp/n18-browser-data`, `FEEL_TMP=/tmp/n18-browser-feel`; Godot/check runs serialized with `/tmp/bramble-n18-godot.lock`.

- Real mouse/keyboard pass through the main scene: start Cards → Mice/tier 5 (3 units) → Spells/all tiers (3 spells) → hover Seek → search `seek` (1 spell) → Escape → Play → recruit Cards → Close. Seven `flow-*.png` shots record it. `flow-recruit-before.png` and `flow-recruit-after.png` are pixel-identical (zero differing pixels); the game log has zero errors/warnings. `flow-audit.txt` confirms the completed artifacts independently of the temporary driver's status-line parser.

Media root: `/home/alex/code/Bramble/.claude/worktrees/night-media/browser/` (outside Git).


## Original mock-up comparisons

All five requested states were compared at 1920 × 1080 and 1366 × 768 with `tools/look/compare.py`: ten pairs, each with `mockup.png`, `godot.png`, `stacked.png`, `diff.png` and all 144 regions in `result.json`. Folders are `<state>-1920/` and `<state>-1366/`. The approved page was not edited; `tests/screens/browser_reference.html` embeds it and selects its own controls. Inspected the stacked/difference images and the real-input shots, including wrapping and clipping at laptop size.

| State | 1920 mean /255 | Pixels >32 | 1366 mean /255 | Pixels >32 | Worst 1920 region |
|---|---:|---:|---:|---:|---|
| start | 1.28 | 0.13% | 2.32 | 0.40% | K4 5.19 |
| all | 9.65 | 6.98% | 13.42 | 11.78% | F4 60.15 |
| mice | 5.17 | 3.69% | 6.54 | 4.65% | F4 63.24 |
| spells | 3.46 | 2.57% | 4.71 | 3.00% | D5 55.63 |
| game | 10.45 | 7.22% | 12.82 | 10.88% | F4 60.44 |

Named 1920 regions, using the same brightness-weighted difference:

| State / area (x,y,w,h) | Mean /255 | Pixels >32 |
|---|---:|---:|
| start: pane (580,200,760,640) | 3.17 | 0.54% |
| all: filters (16,60,218,750) | 7.13 | 3.90% |
| all: header / search (276,100,1390,65) | 2.75 | 2.01% |
| all: tooltip (520,160,580,400) | 45.30 | 38.35% |
| all: grid below tooltip (276,560,1390,450) | 7.87 | 5.05% |
| all: right window (1682,160,220,850) | 0.63 | 0.00% |
| mice: filters (16,60,218,750) | 7.07 | 3.89% |
| mice: empty window below cards (276,600,1390,410) | 0.36 | 0.00% |
| spells: filters (16,60,218,400) | 5.34 | 2.60% |
| game: filters (145,70,200,750) | 7.96 | 4.14% |
| game: header / search (386,60,1260,75) | 4.27 | 2.13% |
| game: right entry (1740,45,115,115) | 15.15 | 12.60% |

The worst unit regions cover the enlarged card and old tooltip: the current shop draws text pills in the art and always shows all reminders, while the approved page has bottom keyword marks and the Alt tooltip. The browser deliberately uses the same `GlassTips` and shared card makers, so brief 2's replacement reaches it. The shop branch's accepted diamond/shield combat numbers and detailed coins also differ from the approved page's older discs. Spell differences include the shared tooltip's size/placement and cost coin. These are real remaining visual differences, not a claim of pixel equality.

The browser-specific layout follows round 2: columns/rows, headings, names, switch/filter placement, search/count, pane and Close. The right entry currently has the game's narrow amber ring; the reference adds a broader halo (the named region above records it). Other small differences are text rasterization, button type/edges, the usable scrollbar, and fractional scaling at 1366. No mock-up pixels were changed or excluded from the comparisons.

## Questions and limits

- The orchestrator resolved the picker question during review: restore it in the game, keep the compact start only when no tribes are given. The remaining start-screen question is whether the Cards ring is permanent or a temporary “new” marker.
- The owner still needs to judge readability at laptop scale, hover feel, the shop's chosen coin/stat silhouettes, and the eventual brief 2 keyword/tooltip presentation. Pixel scores and tests cannot establish those preferences, sound, or real hardware behavior.


## Runtime housekeeping

No action was denied. Before the shared lock was in use, a failed records-check process (PID 794498) had remained asleep for over 50 minutes after a fatal script error; verified its exact command and error log, then terminated that abandoned process to free the Godot slot. No other branch/worktree was edited. No push or PR was attempted.


## PR 125 review fixes

On the rebased `3f0766b0` over `9b8b1a8b`, restored the main screen's tribe/names setup and saved-choice restoration, keeping the expanded picker layout and Cards between Play and Quit. Kept the Cards amber ring in both start variants and logged the owner question above. Removed the unused `card_browser.tscn`; the browser is constructed in code.

Escape closes the browser only in `CardBrowser._input`, before GUI focus or main's pause shortcut. The unhandled-key override only suppresses the inherited leaderboard shortcut; it has no Escape logic. `toggle_pause` refuses to open a second overlay while the browser exists. New viewport-input tests cover focused search in and out of a game, exactly one close signal, key repeats, and the next distinct Escape opening Pause normally. A picker integration test exercises toggling, Only, opening/closing Cards, Play, and return from the result screen with the same chosen tribes.

Review regression suite: 7 tests / 80 assertions passed, with no errors, warnings or orphan notices. Actual main-scene start captures are `review-start-1920.png` (1920 × 1080) and `review-start-1366.png` (1366 × 768), in the media root above; both show all five tribe choices, Only links, and the ringed Cards button between Play and Quit, without clipping. Both look runs logged zero errors/warnings. The original comparison table above records the compact fallback start.

Review `./scripts/check.sh`: all 12 steps passed on the rebased code. Compiled 389 resources; 758 tests / 13,186 assertions passed. Both soaks had zero violations and all six planted faults were caught. Record replay matched 2 seeds, 30 turns and 90 checkpoints, and detected the changed action. Full log: `review-check.log` in the media root. No approvals were denied; no push or PR action was attempted.
