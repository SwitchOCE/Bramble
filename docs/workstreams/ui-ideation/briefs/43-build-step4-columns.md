# Build step 4: the two side columns of the L1 look

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal** for how to carry out step 4 of a plan; the owner's own words are quoted below and outrank it.

## The job in one paragraph

Bramble's buy screen is being rebuilt to a new look the owner chose from an HTML mock-up. Steps 1 to 3 (done, on the branch you start from) gave it the new room, the new card and the new shop. You do step 4, the last before the owner plays it: the two side columns. Left, what the player watches: the turn plate, the scoreboard with a heart of health on each portrait, and the player's own hero in a painted frame. Right, what the player acts on: gold on a coin, health on a heart, counters as glass medallions, three small round buttons, and End turn as a red roundel with crossed swords. You change how these look and where they sit, and nothing about how the game plays.

## The owner's words (25 Nov 2026)

> "The health should be at the top right and can stay as whatever, maybe like a heart with a little [number] inside of it. And your portrait should go down the bottom left, as a rectangle, and use a bit more height to be in line with the hand. It's where the hero power will activate when we turn hero powers back on."

> "The next turn button should probably be like [crossed] swords, I would guess, and probably have a red texture because you're going to a fight."

> "I like a lot of the tile-based ones [counters] ... Only your highest counters or most recently changed things could show up ... It's fine to have something and X more and you click on a button and it pops out a modal or a tooltip."

> "The coin is probably a little bit too big, and the four is not in the centre of the coin at the top right of the screen."

> "I would like the circles on the portraits changed to heart symbols." (the health on each scoreboard portrait)

> "I think I agree with all the decisions ... I'm willing to accept that as a build scope." (accepting, among others: no place numbers and no hero names on the scoreboard; pressing your hero does nothing yet)

> "The pop-up just can't be anchored to the tooltip of the card. I think it's fine going on the left column or the right column because they're overlays." (the hover detail and keyword boxes stay in the left column, drawn over the scoreboard)

Standing rules of the owner's: the main screen assumes a player who knows the rules, so numerals and clear icons, very few words; glows are engine lighting effects made in a later step, never baked pictures.

## Where you work

- Your checkout: `/data/worktrees/ui-l1-step1`, already on branch `ui/l1-step4-columns`. Work only there. Do not switch branches, merge, rebase or push. Commit your work on that branch, in a few clear commits.
- Scratch: `TMPDIR=/data/ui-ideation/tmp/step4`. Pictures for the report: `/data/ui-ideation/build/step4/`.
- Godot is `/usr/local/bin/godot`. The quality gate is `./scripts/check.sh`. It is long: run it with a time limit, in the way your harness prefers for long commands.

## What to read first

- The spec: `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/spec/buy-screen-l1.md`. For this step: sections 1, 2, 3 (pieces), 8 (step 4: the columns), 9 (light: only to know what you must **not** build yet), 10 (the fight screen), 11 (states: read the whole "The columns" list and its picks), 12 and 13 (icons).
- The picture of the finished screen: `/data/ui-ideation/looks/L1/c/c8-spec.png`. Open it and study the two columns, 244 pixels wide at each side.
- The game: `src/screens/glass_screen.gd`, `src/screens/recruit/` (step 1 added `recruit_columns.gd`), `src/screens/glass_counters.gd`, `src/screens/browser/cards_button.gd`, `src/game/ui/settings_cog.gd`, `src/game/game_controller.gd` (the Past boards button), and `assets/glass/l1/`.

## What to do

1. **Left column.** The turn plate; the scoreboard rows as section 8 gives them (round portraits, the ring colours for you and for your next opponent, a heart of health at each portrait's lower right, crossed swords by the next opponent, a knocked-out player greyed with no heart); no place numbers and no names. The player's hero in the painted frame at the foot, its top level with the hand ledge; pressing it does nothing yet.
2. **Right column.** Gold on the coin with next turn's income under it; the player's health on the heart; counters as medallions with a number badge at the lower right, following section 8 and section 11's picks for none to three counters, for colours and icons, and for the plate that appears only above four; the card library, Past boards and settings as three small round buttons in a row; End turn as the swords roundel.
3. The hover detail and keyword boxes stay in the left column over the scoreboard, as step 1 left them. The player hover card on a scoreboard portrait keeps today's content, placed beside the column.
4. The fight screen keeps today's hero, scoreboard, counters and buttons. Where shared code would change it, give the buy screen its own version (section 10).
5. States the spec lists as not designed keep today's behaviour on the new shapes, marked `STAND-IN`. Follow a "Pick (P)" or "Settled" line where the spec gives one.
6. New numbers go in the hand-kept layout file. Rewrite only tests pinned to the old look; tests of behaviour pass unchanged. Say which tests you changed and why.

## One small carry-over from step 3's review

`RecruitShop.refresh_step` has a fallback branch that works out the refresh step size from the price and `GameConfig` defaults when the state has no `refresh_step_size`. That copies a core rule into the screen, and only the test fixture `tests/screens/fixtures/shop_review.json` needs it. Add `refresh_step_size` to that fixture and delete the fallback. Do this first, as its own commit.

## What not to do

- No light of any kind: no glow, pulse or flash on End turn, the heart, the coin or the medallions. Light is a later step.
- No hero power, no auras panel, no new screens. The library, Past boards and settings buttons open exactly what they open today.
- No rule, balance or input change. End turn does exactly what it does today.
- Nothing on the shop wall, the board, the hand or the card.
- Do not design anything the spec does not show.
- Do not read token or `auth.json` files.

## Done means

- `./scripts/check.sh` passes in your checkout. Quote its last summary lines.
- Screenshots made with `tools/look`, saved in `/data/ui-ideation/build/step4/`: `buy.png` (mid-game, with Compost and Tide counters if the lobby has them), `buy-hover.png` (a hand unit pointed at, the detail over the scoreboard), `buy-late.png` (late game: a knocked-out player on the scoreboard, health of two digits, gold of two digits), `fight.png`. Look at each at full size and compare the columns with the picture; fix what is plainly wrong before you report.
- A list of anything in the spec you found wrong, missing or impossible, each in a line. Do not work around a gap silently.
- Motion, hover feel and sound cannot be judged from screenshots: write "not judged" for them.

## Report

Under 250 words: what you built, the commits, the checks' result, the tests you rewrote and why, and the spec gaps.

Never run `rm -rf`, or any other delete, anywhere, inside your checkout or outside it: Codex stops for the owner's approval on it, and the run stalls for hours. Instead, list every file and folder you made that you think should be removed afterwards, inside your checkout and outside it, each with its path and size; the orchestrator removes them. End your report with a Disk section: every folder you created or wrote into outside your checkout (data, logs, temp, build output, cargo targets), each with its `du -sh` size, whether it is still needed, and which ones the orchestrator can delete; and `df -h` for each disk you used, at the start and at the end.
