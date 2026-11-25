# Build step 2: the card of the L1 look

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal** for how to carry out step 2 of a plan; the owner's own words are quoted below and outrank it.

## The job in one paragraph

Bramble's buy screen is being rebuilt to a new look the owner chose from an HTML mock-up. Step 1 (done, on the branch you start from) gave the screen its new room and moved everything to its new place. You do step 2: the card. Every unit card in the game, on the buy screen and the fight screen, stops being drawn with one of six tier frame pictures and is drawn by code as a plain lead window, the same at every tier. Golden becomes gilt lead. A spell held in the hand becomes a disc. You change how cards look and nothing about how the game plays.

## The owner's words

> "I agree with you that L1 is the best." (24 Nov, choosing the look whose card is a plain lead window)

> "Tier on the board on hover only, agreed." (24 Nov)

> "Everything else is basically perfect. I really like this ... I'm willing to accept that as a build scope." (25 Nov, of the mock-up and the build's summary)

> "Obviously, the glows we've got are not how the glows will look in Godot ... There needs to be some sort of lighting effect in Godot rather than some sort of static asset. And the twinkles on the gold borders are going to fall into the same kind of bucket." (25 Nov)

A standing rule of the owner's: anything new on the face of a card needs a picture and the owner's explicit yes. What the spec's section 6 gives is approved. Nothing else may be added to or removed from the card's face.

## Where you work

- Your checkout: `/data/worktrees/ui-l1-step1`, already on branch `ui/l1-step2-card` (cut from the working branch after step 1). Work only there. Do not switch branches, merge, rebase or push. Commit your work on that branch, in a few clear commits.
- Scratch: `TMPDIR=/data/ui-ideation/tmp/step2`. Pictures for the report: `/data/ui-ideation/build/step2/`.
- Godot is `/usr/local/bin/godot`. The quality gate is `./scripts/check.sh`. It is long: run it with a time limit, in the way your harness prefers for long commands.

## What to read first

- The spec: `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/spec/buy-screen-l1.md`. For this step: sections 1 (ground rules), 2 (the grid), 6 (step 2: the card), 9 (light: only to know what you must **not** build yet), 10 (the fight screen) and 11 (states).
- The picture of the finished screen: `/data/ui-ideation/looks/L1/c/c8-spec.png`. Open it and look closely at the cards on the board, the two golden ones, and the spell at the right-hand end of the hand.
- The game: `src/glass/glass_card.gd`, `src/glass/glass_spell.gd`, `src/glass/card_shadow.gdshader`, `src/screens/recruit/`, `src/screens/fight/`, `tests/`, and what step 1 added (`src/glass/l1_layout.gd`, `assets/glass/l1/layout.json`).

## What to do

1. Draw the unit card as section 6 gives it: the outline, the lead border, the art window and its crop, the glass bevel, the Attack and Health discs, and the slab (edge and shadow). The same on every screen that shows a card. The six tier frame pictures stop being drawn on cards.
2. Golden: gilt lead, gilt stat rims and the gilt slab edge, as section 6 gives them. No halo, no rim glow, no twinkle: those are lights and belong to a later step.
3. A spell in the hand is a disc, as section 6 gives it. Spells in the shop keep today's look in this step.
4. Everything else that sits on a card today stays, moved only as far as the new frame needs: keyword pills, Charge and Supply pips, the Worked mark, ability buttons, numbers drawn green or red when above or below the printed ones, the duplicate glow, the triple foil, the hover glow. Mark each with `STAND-IN` where you had to refit it. Do not restyle them.
5. Put the card's numbers in the hand-kept layout file step 1 added, not in the generated `assets/glass/layout.json`.
6. Rewrite only tests that are pinned to the old frame (frame pictures, per-tier disc places, old sizes). Tests of behaviour must pass unchanged. Say which tests you changed and why.

## What not to do

- No light of any kind (spec section 9), no arches, round buttons, lanterns, medallions or other shop and column work (sections 7 and 8).
- No rule, balance or input change. The card's hit area for pointing and dragging stays the hexagon outline.
- Tier must not appear on the card in any form. Where tier shows today other than by the frame (the hover detail's words, for instance), leave it as it is.
- Do not design anything the spec does not show. Section 11 lists states that are not designed: each keeps today's look and behaviour.
- Do not read token or `auth.json` files.

## Done means

- `./scripts/check.sh` passes in your checkout. Quote its last summary lines.
- Screenshots made with `tools/look`, saved in `/data/ui-ideation/build/step2/`: `buy.png` (a mid-game buy screen with at least one golden unit on the board and a spell in the hand), `buy-hover.png` (a hand unit pointed at), `fight.png` (the fight screen). Look at each at full size and compare the cards with the picture; fix what is plainly wrong before you report.
- A list of anything in the spec you found wrong, missing or impossible, each in a line. Do not work around a gap silently.
- Motion, hover feel and sound cannot be judged from screenshots: write "not judged" for them.

## Report

Under 250 words: what you built, the commits, the checks' result, the tests you rewrote and why, the spec gaps, and anything on the card's face that you had to move.

Never run `rm -rf`, or any other delete, anywhere, inside your checkout or outside it: Codex stops for the owner's approval on it, and the run stalls for hours. Instead, list every file and folder you made that you think should be removed afterwards, inside your checkout and outside it, each with its path and size; the orchestrator removes them. End your report with a Disk section: every folder you created or wrote into outside your checkout (data, logs, temp, build output, cargo targets), each with its `du -sh` size, whether it is still needed, and which ones the orchestrator can delete; and `df -h` for each disk you used, at the start and at the end.
