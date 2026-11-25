# Fix: the card's hover detail went backwards on the L1 buy screen

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal** for a fix; the owner's own words are quoted below and outrank it.

## What went wrong

Bramble's buy screen has been rebuilt to a new look on the branch you start from. In the first step of that rebuild, the orchestrator's spec said the card's hover detail and the keyword reminder boxes both "stay in the left column". The worker did as told: when a card is pointed at, its enlarged copy, its words and its keyword boxes are now stacked together in the 244 px left column and scaled down to fit (`RecruitTips._layout_details`, `left.hover` in `assets/glass/l1/layout.json`). That was the orchestrator's misreading of the owner. On `dev`, before the rebuild, the detail was a pane beside the pointer with the card's enlarged copy and its words (`src/screens/glass_tips.gd`: "the pane beside the pointer with a card's enlarged copy and its words"), and keyword reminders were a separate thing.

The owner has played the build and says it is worse than before.

## The owner's words

25 Nov 2026, after playing the build:

> "The tooltips I do not like. The size of the new tooltips don't help, and the fact they're anchored to the left-hand side of the screen, I don't like either. The idea is the card, when you hover over it, should zoom in, make it more legible, and you should get a bigger tooltip to see it. And the tooltips for keywords should not be anchored to the rest of the card. It should be clear that keywords are different. Not connected to the rest. So it's obviously not part of the card's effect."

> "Essentially, what I'm saying is, I think we went backwards compared to previous." ... "Only on tooltips."

22 Nov 2026, the owner's standing rule (the note `docs/design/owner-notes/2026-11-22a-card-details-on-hover.md` on the branch `origin/owner-note/2026-11-22a-card-details-on-hover`; read it with `git show`):

> "I feel like the tooltips should be hover states, like modals or toasts or whatever they're called. And keyword reminders should not be anchored or rendered in the same way as the tooltip that follows the cursor. They should go in some consistent part of the screen. Either they're at the top or the side or out of the way ... because [it's] an option that players can turn off in the settings, and even if they don't, it sits in some part of the screen the player can move their eyes towards that isn't the active state. So they're available but not obtrusive."

25 Nov 2026, earlier, on where overlays may sit:

> "The pop-up just can't be anchored to the tooltip of the card. I think it's fine going on the left column or the right column because they're overlays."

## The problem to solve

Two different things show when a card is pointed at, and they must look and sit like two different things:

1. **The card's own detail**: the card, bigger, and what it does, legible. It belongs with the card the player is pointing at, as it did before the rebuild. It must not be shrunk to fit a column.
2. **Keyword reminders**: what the keywords on that card mean. They are not part of the card's effect and must not read as attached to the card's detail. They sit in one consistent, out-of-the-way place; the side columns are allowed, because they are overlays. They are not scaled down until they can't be read.

The surest way to the first is to put the card's hover detail back to how it behaved on `dev` (compare your branch with `origin/dev` for `src/screens/glass_tips.gd`, `src/screens/recruit/recruit_tips.gd`, `src/screens/keyword_layout.gd` and their tests), now drawing the new card. Where the new layout makes the old placement impossible or bad (the hand is now flat and half below the screen; the shop is now a wall of arches at the top; the side columns are wider), choose the placement that keeps the detail next to its card, wholly on the screen, and not covering the card itself, and say what you chose. Do not design a new kind of tooltip.

## Where you work

- Your checkout: `/data/worktrees/ui-l1-build`, already on branch `ui/l1-fix-hover` (the rebuilt screen with its light). Work only there. Do not switch branches, merge, rebase or push. Commit in a few clear commits.
- Scratch: `TMPDIR=/data/ui-ideation/tmp/fix-hover`. Pictures for the report: `/data/ui-ideation/build/fix-hover/`.
- Godot is `/usr/local/bin/godot`. The quality gate is `./scripts/check.sh`. It is long: run it with a time limit, in the way your harness prefers for long commands. The checkout is fresh, so its first Godot run imports the project.
- Another worker is building two panels on the same base in another checkout. It works on the counters and their panes. Keep your change to the hover detail and its tests, so the two join cleanly.

## What must stay

- A hand card that is pointed at still stands up, wholly on the screen (its foot 8 px above the stage's bottom).
- A card that is pointed at still gets its tier's light around it (`RecruitTips.light_tier`).
- Hovering a counter shows what it showed before, and hovering a scoreboard portrait shows the player's name only.
- The fight screen is untouched: nothing under `src/screens/fight/`. Do not change `GlassCard.stat_disc` or `GlassCard._draw_stat`.
- No rule, balance or input change beyond where the hover detail is drawn.

## Done means

- `./scripts/check.sh` passes in your checkout. Quote its last summary lines.
- Tests: the hover detail's size is the card's enlarged copy at the size it has on `dev` (not scaled to a column); it sits beside the pointed-at card and on the screen for a shop card, a board card and a hand card; keyword reminders are in their fixed place and are not children of, or stacked with, the card's detail; nothing is scaled below its natural size. Where step 1 changed a test of the hover detail, put the `dev` assertion back unless the new layout truly forbids it, and say which.
- Screenshots made with `tools/look` in `/data/ui-ideation/build/fix-hover/`: a shop card pointed at, a board card pointed at, a hand card pointed at, each with a card that has at least two keywords; and, for comparison, the same three from before your change. Look at each at full size. Can you read every word of the detail and of each keyword box? Say so only if you can.
- Motion, hover feel and sound: "not judged".

## Report

Under 200 words: what the detail and the keyword reminders now do, where each sits for a shop, board and hand card and why, the commits, the checks' result, the tests you restored or changed.

Do not read token or `auth.json` files. Never run `rm -rf`, or any other delete, anywhere, inside your checkout or outside it: Codex stops for the owner's approval on it, and the run stalls for hours. Instead, list every file and folder you made that you think should be removed afterwards, each with its path and size; the orchestrator removes them. End your report with a Disk section: every folder you created or wrote into outside your checkout, each with its `du -sh` size, whether it is still needed, and which ones the orchestrator can delete; and `df -h` for each disk you used, at the start and at the end.
