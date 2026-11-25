# Build the two panels of the L1 buy screen: all your auras, and a heap's contents

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal** for how to carry out one step of a plan; the owner's own words are quoted below and outrank it.

## The job in one paragraph

Bramble's buy screen has been rebuilt to a new look (the room, the card, the shop, the columns and their light are on the branch you start from). In its right column the player's counters are glass medallions. Two things those lead to are still missing or old: a panel that lists "all your auras", which does not exist yet, and the panel a heap such as Compost opens, which is still the old build's. The look's art director has designed both as one family, as an HTML mock-up, and the owner has approved it. You build that design in the game, on the buy screen only.

## The owner's words

24 Nov 2026:

> "Tide is not always going to be a mechanic. We just need some way of handling any number of other mechanics ... You just need a way of being able to view all your auras, so it shouldn't be like a Tide button. It's more of a generalized thing. Same for Compost: it's a mechanic that may only be in some lobbies."

25 Nov 2026:

> "We need to be less focused on how everything fits into one screen and being willing to handle overflow with modals."

> "It's fine to have something and X more and you click on a button and it pops out a modal or a tooltip, right? ... That's the exact kind of solution I'd expect to see."

> "I'm happy with that." (of the art director's panel design, shown as the pictures named below)

Standing rules of the owner's: the main screen assumes a player who knows the rules, so numerals and icons and very few words; no dimming filter over card art; glows are engine effects, never baked pictures.

## Where you work

- Your checkout: `/data/worktrees/ui-l1-step1`, already on branch `ui/l1-step9-panels`. Work only there. Do not switch branches, merge, rebase or push. Commit your work on that branch, in a few clear commits.
- Scratch: `TMPDIR=/data/ui-ideation/tmp/step9`. Pictures for the report: `/data/ui-ideation/build/step9/`.
- Godot is `/usr/local/bin/godot`. The quality gate is `./scripts/check.sh`. It is long: run it with a time limit, in the way your harness prefers for long commands.

## The design, which is the source of truth

- The mock-up page: `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/looks/L1/panels/panels.html`. It draws each state over a screenshot of the built game: open it with `?state=auras-few`, `auras-many`, `heap-full`, `heap-empty`, `heap-from-auras`. Its code holds every size, colour and position. (`grid-many` is an alternative the art director rejected: do not build it.)
- Its pictures: `/data/ui-ideation/looks/L1/panels/auras-few.png`, `auras-many.png`, `heap-full.png`, `heap-empty.png`, `heap-from-auras.png`. Open them.
- The art director's notes: `panels.md` beside the page. Read all of it: it says what belongs in the auras panel and what does not, how each panel opens and closes, and what was not solved.
- The game: the counters as built (`src/screens/recruit/recruit_counters.gd`, `src/screens/glass_counters.gd`), the old Compost panel (`src/screens/compost/`), how a board slot's buff reaches the screen (`src/screens/glass_slot.gd`, `slot_layer.gd`), the hand-kept layout (`assets/glass/l1/layout.json`, `src/glass/l1_layout.gd`), and the in-game wording rule in `.claude/skills/ux-copy/SKILL.md` (plain text; follow it for any word you put on screen).

## What to do

1. **The pane.** One slate-glass pane on the right wing of the table, in the place and at the size the page gives, drawn in code as the page draws it (the art director would like it painted one day; mark it `STAND-IN`). Nothing behind it is dimmed. It closes on its close button, on Esc, on pressing the same medallion again, and on a press outside it.
2. **The auras panel.** A list, as the page draws it: medallion, name, one short line, the number; a heap's row opens that heap in the same pane, with a way back. It holds what the notes say belongs to the player and not to one unit. Build it from what the game's state really gives today; do not invent counters. Where the notes name a thing the state does not give, leave it out and list it in your report.
3. **Opening it.** As the notes say: with more counters than the four medallions show, the plate under them appears with how many more there are and opens the list; with four or fewer there is no plate, a round medallion opens the list with its row marked, and a heap's medallion opens that heap.
4. **A heap's panel.** As the page draws it: small cards in a grid, newest first, copies stacked with a count, golden ones gilt, an empty heap saying so. On the buy screen this replaces the old Compost panel. The fight screen keeps the old panel and everything else it has: touch nothing under `src/screens/fight/`.
5. Numbers go in the hand-kept layout file. Add tests for: what the list holds for a given state; the plate appearing only above four counters and its count; each way of opening and closing; a heap's grouping, order and empty state; and that nothing on the buy screen is dimmed while a pane is open. Rewrite an existing test only where it is pinned to the old Compost panel on the buy screen, and say which.

## What not to do

- No change to rules, to what counters mean, or to any input outside opening and closing these panes.
- No light or glow on the panes. No new painted pictures.
- Do not change `GlassCard.stat_disc` or `GlassCard._draw_stat` (another session's work depends on them), and nothing under `src/screens/fight/`.
- Do not design what the page does not show. If the page and the notes disagree, follow the pictures and say so.
- Do not read token or `auth.json` files.

## Done means

- `./scripts/check.sh` passes in your checkout. Quote its last summary lines.
- Screenshots made with `tools/look`, saved in `/data/ui-ideation/build/step9/`: the auras list with the game's real counters, the list in a test state with more than four counters (so the plate and scrolling show), a full heap, an empty heap, a heap opened from the list. Look at each at full size against the art director's picture of the same state and fix what is plainly wrong before you report.
- A list of anything in the design you found wrong, missing or impossible, each in a line.
- Motion, hover feel and sound cannot be judged from screenshots: write "not judged" for them, including how the pane opens.

## Report

Under 250 words: what you built, the commits, the checks' result, what the auras list holds today and what the notes name that the state does not give, the tests you rewrote and why, and the design gaps.

Never run `rm -rf`, or any other delete, anywhere, inside your checkout or outside it: Codex stops for the owner's approval on it, and the run stalls for hours. Instead, list every file and folder you made that you think should be removed afterwards, inside your checkout and outside it, each with its path and size; the orchestrator removes them. End your report with a Disk section: every folder you created or wrote into outside your checkout (data, logs, temp, build output, cargo targets), each with its `du -sh` size, whether it is still needed, and which ones the orchestrator can delete; and `df -h` for each disk you used, at the start and at the end.
