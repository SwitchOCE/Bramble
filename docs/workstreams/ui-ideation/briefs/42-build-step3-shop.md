# Build step 3: the shop of the L1 look

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal** for how to carry out step 3 of a plan; the owner's own words are quoted below and outrank it.

## The job in one paragraph

Bramble's buy screen is being rebuilt to a new look the owner chose from an HTML mock-up. Steps 1 and 2 (done, on the branch you start from) gave the screen its new room and the new card. You do step 3: the shop wall across the top of the screen. Each of the five shop cards gets a painted stone arch with its tier's colour behind it; costs become coins; the two spells hang as discs on a chain; the three shop buttons become round glass buttons on the slate tablet; the "n left at this price" words become beads; lanterns between the arch heads count the shop's level. You change how the shop looks and nothing about how it plays.

## The owner's words (25 Nov 2026)

> "For all of the cost buttons, if they're going to be a circle, they should have a little [coin] either on the bottom right of the circle overlapping the circle's corner, or on the top right."

> "I do not think we need an archway little shelf for the spells ... And the archway needs a bit more negative space ... so that the lighting effect has a way of glowing ... The original arches we had to house the cards in the very first reference image had the arches bigger than the cards themselves."

> "The text on how many things are left is not the best way of displaying it."

> "Lanterns are good. Let's go with that and build it out in-game."

> "Obviously, the glows we've got are not how the glows will look in Godot ... There needs to be some sort of lighting effect in Godot rather than some sort of static asset."

> "I think I agree with all the decisions ... I think just the coin is fine ... I'm willing to accept that as a build scope." (accepting, among others: a price you can't afford greys only its coin; the tier-up discount shows only when the button is pointed at)

Standing rules of the owner's: no dimming filter over card art; the main screen assumes a player who knows the rules, so numerals and clear icons, very few words.

## Where you work

- Your checkout: `/data/worktrees/ui-l1-step1`, already on branch `ui/l1-step3-shop`. Work only there. Do not switch branches, merge, rebase or push. Commit your work on that branch, in a few clear commits.
- Scratch: `TMPDIR=/data/ui-ideation/tmp/step3`. Pictures for the report: `/data/ui-ideation/build/step3/`.
- Godot is `/usr/local/bin/godot`. The quality gate is `./scripts/check.sh`. It is long: run it with a time limit, in the way your harness prefers for long commands.

## What to read first

- The spec: `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/spec/buy-screen-l1.md`. For this step: sections 1, 2, 3 (pieces), 7 (step 3: the shop), 9 (light: its tier colour table, and what you must **not** build yet), 11 (states), 12 (numbers each shape must hold) and 13 (icons).
- The picture of the finished screen: `/data/ui-ideation/looks/L1/c/c8-spec.png`. Open it and study the top 350 pixels. In it the player has 4 gold, so the tier-up coin (9) is pewter and the others are gold.
- The game: `src/screens/recruit/recruit_shop.gd`, `recruit_screen.gd`, `recruit_buttons.gd`, `src/glass/`, and what steps 1 and 2 added (`src/glass/l1_layout.gd`, `l1_room.gd`, `l1_card_face.gd`, `assets/glass/l1/`).

## What to do

1. **Arches.** Behind each shop card, the painted arch (`l1z-arch.png`) with its opening on the card as section 7 gives it. Inside the opening, the card's tier colour as a **plain stand-in**: a flat tint at the strength section 9's table gives, with no blur, glow, gradient spill or animation. An empty place stays dark, with no tint and no coin.
2. **Costs as coins.** Every price is a number on the coin piece: under each arch for a unit, overlapping the lower right of its disc or button for a spell and for the shop buttons. A price above the player's gold is a pewter (grey) coin; the card art is never greyed.
3. **Spells.** The two shop spells are round discs hung on the bracket and chain (`l1z-hanger.png`), with no arch and no backing, their tier colour as the same plain stand-in behind them.
4. **The tablet's three buttons.** Round glass buttons (`l1p-roundel-slate.png`) on the tablet's centre line: tier up (the game's market-stall icon and the shop's level as a numeral), refresh, freeze. Today's "−n next turn" words leave the screen and show only in the tier-up button's hover tip. At level 6 the button stays, shows 6 and carries no coin.
5. **Refresh beads.** The "n left at this price" words become beads on an arc over the refresh button, one per paid refresh at this price step, lit while it is left (ten on the first step, five on later steps). Lit and spent beads are drawn shapes; no glow.
6. **Lanterns.** Six between the arch heads, the n leftmost lit (`l1s-lantern-lit.png`) at shop level n, the rest dark. No glow.
7. States the spec lists as not designed (a frozen shop, a button whose action isn't allowed, a shop card pointed at or carried, and the rest of section 11's shop list) keep today's look and behaviour on the new shapes, marked `STAND-IN`. Follow a "Pick (P)" or "Settled" line where the spec gives one.
8. New numbers go in the hand-kept layout file, not the generated one. Rewrite only tests pinned to the old look (rectangular buttons, the hanging price tag, the words readouts); tests of behaviour pass unchanged. Say which tests you changed and why.

## What not to do

- No light of any kind: no glow, halo, blur, particles or animation on arches, spells, beads or lanterns. Light is a later step, and the owner has said it must be an engine lighting effect, so a baked or faked glow now would have to be torn out.
- Nothing in the side columns (gold, health, counters, scoreboard, End turn): that is step 4. The gold readout stays where step 1 put it.
- No rule, balance or input change. What a click or drag on a shop card, spell or button does stays exactly as it is.
- Do not design anything the spec does not show.
- Do not read token or `auth.json` files.

## Done means

- `./scripts/check.sh` passes in your checkout. Quote its last summary lines.
- Screenshots made with `tools/look`, saved in `/data/ui-ideation/build/step3/`: `buy.png` (mid-game, enough gold to buy), `buy-poor.png` (gold too low for most prices, so pewter coins show), `buy-frozen.png` (the shop frozen), `buy-level6.png` (shop level 6). Look at each at full size and compare the top of the screen with the picture; fix what is plainly wrong (overlaps, things cut off, coins off their rims) before you report.
- A list of anything in the spec you found wrong, missing or impossible, each in a line. Do not work around a gap silently.
- Motion, hover feel and sound cannot be judged from screenshots: write "not judged" for them.

## Report

Under 250 words: what you built, the commits, the checks' result, the tests you rewrote and why, and the spec gaps.

Never run `rm -rf`, or any other delete, anywhere, inside your checkout or outside it: Codex stops for the owner's approval on it, and the run stalls for hours. Instead, list every file and folder you made that you think should be removed afterwards, inside your checkout and outside it, each with its path and size; the orchestrator removes them. End your report with a Disk section: every folder you created or wrote into outside your checkout (data, logs, temp, build output, cargo targets), each with its `du -sh` size, whether it is still needed, and which ones the orchestrator can delete; and `df -h` for each disk you used, at the start and at the end.
