# Build step 1: the room and the layout of the L1 buy screen

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal** for how to carry out step 1 of a plan; the owner's own words are quoted below and outrank it.

## The job in one paragraph

Bramble's buy screen (the recruit screen) is being rebuilt to a new look that the owner chose from an HTML mock-up. You do the first of several steps: give the screen its new room (background art) and move every element the screen has today to its new place, each still drawn with today's art. You add nothing new and change no behaviour. Later steps, done by other workers, change the card, the shop and the side columns, and add light.

## The owner's words (25 Nov 2026)

> "Everything else is basically perfect. I really like this. I think this is almost ready to become a spec and start real work." (of the mock-up)

> "Lanterns are good. Let's go with that and build it out in-game."

> "Obviously, the glows we've got are not how the glows will look in Godot ... There needs to be some sort of lighting effect in Godot rather than some sort of static asset."

> "We need to be less focused on how everything fits into one screen and being willing to handle overflow with modals."

## Where you work

- Your checkout: `/data/worktrees/ui-l1-step1`, already on branch `ui/l1-step1-room` (cut from `dev`). Work only there. Do not switch branches, merge, rebase or push. Commit your work on that branch, in a few clear commits.
- Scratch: `TMPDIR=/data/ui-ideation/tmp/step1`. Pictures you make for the report: `/data/ui-ideation/build/step1/`.
- Godot is `/usr/local/bin/godot`. The quality gate is `./scripts/check.sh` (see its header and `docs/CLOUD_SETUP.md`). It is long: run it with a time limit, in the way your harness prefers for long commands.

## What to read first

- The spec: `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/spec/buy-screen-l1.md`. For this step read sections 1 (ground rules), 2 (the grid), 3 (pieces), 4 (where the layout numbers live), 5 (step 1) and 11 (states). Its rectangles are also in `buy-screen-l1.rects.json` beside it.
- The picture of the finished screen: `/data/ui-ideation/looks/L1/c/c8-spec.png`. Open it. Your step will not look like it yet: only the room and the places will.
- The painted pieces: `/data/ui-ideation/looks/L1/pieces/`.
- The game: `src/screens/glass_screen.gd`, `src/screens/recruit/`, `src/glass/`, `assets/glass/layout.json`, `tests/`, and the repo's `CLAUDE.md` and `AGENTS.md`.

## What to do

1. Copy the 20 pieces the spec's section 3 lists as used into `assets/glass/l1/`, and add the hand-kept layout file and its small reader as section 4 recommends. Do not edit the generated `assets/glass/layout.json`.
2. Draw the new room on the buy screen as section 5 "The room" gives it: the two window columns, the shop wall, the slate tablet, the oak table, its front edge and the hand ledge. No light or glow of any kind in this step.
3. Move every element in section 5's table "Every element's new place" to its new rectangle, drawn with the art it has today. Where today's element is another size, centre it in the new rectangle. Board, shop and hand positions follow the spec's rules.
4. Keep the position functions the tests rely on (section 5 lists them), so tests that check behaviour pass unchanged. Rewrite only the tests that are pinned to old positions or node names, and say in your report which ones and why.
5. The fight screen shares code with this screen. It must look and work as it does today. Where a shared function would change it, give the buy screen its own version as section 10 describes.

## What not to do

- Nothing from the spec's sections 6 to 9 (the card, the shop's arches and round buttons, the columns' new elements, light). If doing step 1 properly needs a small piece of one of them, stop and say so in your report instead.
- No rule, balance or input change. No change to how dragging, buying, selling or the bots work.
- Do not design anything the spec does not show. A state the spec lists as not designed keeps today's look and behaviour, moved only as far as it must be, and is marked `STAND-IN` in the code as the game already does. Where the spec gives a "Pick (P)" for such a state, follow the pick.
- Do not read token or `auth.json` files.

## Done means

- `./scripts/check.sh` passes in your checkout. Quote its last summary lines.
- A screenshot of the built buy screen in a mid-game state, made with `tools/look`, saved as `/data/ui-ideation/build/step1/buy.png`, and one of the fight screen as `fight.png`. Look at both yourself at full size and fix what is plainly wrong (things overlapping, cut off, or outside their zone) before you report.
- A list of anything in the spec you found wrong, missing or impossible, each in a line. Do not work around a gap silently.
- Motion, hover feel and sound cannot be judged from screenshots: write "not judged" for them.

## Report

Under 250 words: what you built, the commits, the checks' result, the tests you rewrote and why, the spec gaps, and what you would hand to the next step.

Never run `rm -rf`, or any other delete, anywhere, inside your checkout or outside it: Codex stops for the owner's approval on it, and the run stalls for hours. Instead, list every file and folder you made that you think should be removed afterwards, inside your checkout and outside it, each with its path and size; the orchestrator removes them. End your report with a Disk section: every folder you created or wrote into outside your checkout (data, logs, temp, build output, cargo targets), each with its `du -sh` size, whether it is still needed, and which ones the orchestrator can delete; and `df -h` for each disk you used, at the start and at the end.
