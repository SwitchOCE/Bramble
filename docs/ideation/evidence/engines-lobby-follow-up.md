# Engines lobby follow-up — 8 Nov 2026

Addresses follow-up Asks 1–2 on review branch `origin/ideation/c-review-engines`, inspected after fetching origin. Base: `6659bb2` on `ideation/engines`.

## Regression first

Before editing production code, added the rounded-plaque ink check to `tests/ui/layout_check.gd` and called it from the existing eight-plaque test. Running GUT with `-gselect=test_engines.gd` failed the UI lobby test at both canvas widths, explicitly reporting **“text crosses rounded plaque edge: Last Stand: ready/used/locked”**. The previous box-width assertion passed those cases. The initial standalone strip also reported unrelated viewport bounds because its old test had no sized viewport; the replacement test mounts the strip in the correct desktop/phone canvas and retains the shape check.

The final test checks 8, 5, 4 and 3 heroes alive at each size, exact full hero names, natural wanted width (no clipping or shortening to make the row fit), marker absence above four, ready/used below that threshold, and the existing type/tap minimums. Disabled, eliminated and ghost plaques stay unmarked. An additional whole-screen check stages all five earned tribe bonuses, with and without a selected board card, and verifies that settings and bonuses cannot obscure status and that every bonus stays in its header.

## Renders inspected

Rendered with `taskset -c 2 tests/ui/render_screens.sh engines_lobby_locked engines_lobby`, then inspected all four native-size images. These are staged real-core states, not played games. The four-alive state includes ready and used markers and all five earned tribe bonuses. The desktop four-alive image was rendered once more after the final tag-border padding adjustment.

| Window | Eight alive | Four alive |
|---|---|---|
| 1688×780 | [No markers; full names](engines/lobby-follow-up/engines_lobby_locked_1688x780.jpg) | [Ready/used; full names](engines/lobby-follow-up/engines_lobby_1688x780.jpg) |
| 1920×1080 | [No markers; full names](engines/lobby-follow-up/engines_lobby_locked_1920x1080.jpg) | [Ready/used; full names](engines/lobby-follow-up/engines_lobby_1920x1080.jpg) |

The original marker crossed the plaque’s rounded lower edge. It now has a separate rectangular backing below the plaque. The whole name remains on two lines; Next is a prefix on the first line. Inspection caught an intermediate NEXT-tag overlap and then the settings button covering the player’s marker; both were corrected. While status tags are visible, tools start below that band and tribe bonuses occupy the empty board header. Five bonuses keep their text size and chip width; the caption yields and spacing tightens when needed. No layout/font/tap minimum was lowered.

## Pacing watch

PLAYTEST.md now asks whether the extra last-four time feels tense or drawn out, and whether a save creates a meaningful recovery decision. The roughly 1.4 extra last-four rounds without more lead changes are the reviewer’s **bot data**, not a human pacing conclusion. DECISIONS.md records the UI and watch-item call as the orchestrator’s.

## Validation

- Targeted engines tests: 23/23 passing, 523 assertions.
- Full gate: `./scripts/check.sh` passed every step; 375 files compiled, 1,279/1,279 tests, 16,546 assertions, strict hook clean.
- All commands pinned to core 2. Godot data/settings/cache use `/tmp/bramble-engines-*` because the default home paths are read-only in this sandbox. An initial gate reached import and failed on that settings path; the final run uses the writable paths.
