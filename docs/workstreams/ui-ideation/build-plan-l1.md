# Plan: build the L1 buy screen in the game

Written by the orchestrator of `ideation/ui-ux` on 25 Nov 2026. **A proposal: not approved by the owner yet.**

## What the owner asked for

> "Everything else is basically perfect. I really like this. I think this is almost ready to become a spec and start real work." (25 Nov, of the buy screen mock-up)

> "Lanterns are good. Let's go with that and build it out in-game." (25 Nov)

> "Obviously, the glows we've got are not how the glows will look in Godot, and that needs to be documented. There needs to be some sort of lighting effect in Godot rather than some sort of static asset. And the twinkles on the gold borders are going to fall into the same kind of bucket."

> "We don't have to contain everything on the static screens. We have modals as well ... We need to be less focused on how everything fits into one screen and being willing to handle overflow with modals."

The design is the mock-up `looks/L1/screen.html?view=polish&room=zones` (picture `/data/ui-ideation/looks/L1/c/c7-chosen.png`), with decisions L1 to L44 in `owner-decisions.md` and the notes in `looks/L1/look.md`.

## The goal

The game's buy screen looks and lays out like that picture, plays exactly as it does today, and the owner can play it in a Windows build. Nothing merges into `dev` or `main` without the owner's say-so for that merge.

## What the game has today (survey of `dev` at `16da2ade`)

- The screen is built wholly in code (`src/screens/glass_screen.gd`, `src/screens/recruit/`), on a fixed 1920 x 1080 stage, from numbers pulled out of the old HTML mock-ups (`assets/glass/layout.json`) plus constants in the scripts.
- The card is already 140 x 250 with a hexagon point. Tier is shown by which of six frame pictures is drawn; golden is a stand-in gold line.
- The fight screen shares the stage, the card, the hero and the scoreboard code, but has its own board positions.
- About 220 buy-screen tests. Most find places through `shop_xy`, `slot_xy`, `hand_place` and check the actions sent; roughly 15 to 25 are pinned to old positions or node names.
- No lights or particles exist; four small shaders do shadows, the triple foil, CSS-like boxes and the background.

## How it is built

- One long-lived branch `ui/l1` cut from `dev`. Each step is a worker's branch and PR into `ui/l1`. `ui/l1` is rebased on `dev` before each step.
- Builders are Codex workers (GPT Sol). The orchestrator writes the spec and the briefs and builds nothing.
- Each step passes two gates before it joins `ui/l1`: the project's checks (`scripts/check.sh`) plus a screenshot of the built screen compared with the mock-up region by region (`tools/look`); and a scope review by a fresh reviewer given the owner's words and this plan.
- The layout for this screen becomes a hand-kept data file read by the game. The old pull-from-mock-up path stays for the screens that still use it.
- The position functions the behaviour tests rely on are kept, so those tests keep passing unchanged. Tests pinned to the old look are rewritten to the new one in the step that moves the thing they pin.

## Steps

Order changed after the plan was interrogated by a fresh agent (its result is at the end): the card moves forward, because it carries most of the look, and the first build comes once the screen is whole.

0. **Spec** (written now). Every element's place and size, every piece of art and where it goes, each state (cannot afford, frozen, shop full, golden, level 1 to 6), the list of light effects with purpose and colour, and what is out of scope. The painted pieces go into `assets/glass/l1/` (34 files, 7 MB). **The owner sees the spec before any worker starts.**
1. **The room and the layout.** The new background (window columns, shop wall, slate tablet, oak table, hand ledge) and every existing element moved to its new place with its present art. Nothing new is added. Pinned tests rewritten.
2. **The card.** Plain lead frame with no tier mark; golden as gilt; tier colour on hover; a spell in the hand as a disc. This changes cards on the fight screen too.
3. **The shop.** Arches with the card's tier colour behind it, costs as coins at the lower right, two spells on the hanger, three round buttons, refresh count as beads, lanterns for the shop's level.
4. **The columns.** Left: turn plate, scoreboard always showing with a red health circle on each portrait, the hero's rectangle. Right: gold coin, health heart, counter medallions and the auras plate, library and settings buttons, End turn as red crossed swords with its three states.
5. **First build to the owner.** Light is still plain stand-ins at this point.
6. **Light.** Tier light, golden glow and twinkle, lit lanterns and beads made as engine effects. Filmed for the owner; agents cannot judge them.
7. **The fight screen kept working.** Only what steps 1 to 4 break is fixed. No new fight design.
8. **Final build to the owner,** then the owner decides whether `ui/l1` merges into `dev`.

The screenshot compare leaves out the lit areas: they are meant to differ from the mock-up (L38).

## Out of scope (not designed yet)

The auras panel (the plate shows the count and opens today's Compost panel), a new Compost panel, the card library's and settings' own screens (only their buttons move), a landing screen, the hero power, calmer card art, and any rule or balance change.

## Choices made here that the owner has not been asked about

1. Building on a branch from `dev`, with builds to play before any merge.
2. The fight screen is fitted, not redesigned.
3. The card's lead frame is drawn by the game in code, as in the mock-up, not painted.
4. The scoreboard is always showing on the left (today it is hidden until Tab).
5. End turn stops being the next opponent's portrait; the next opponent is marked on the scoreboard by crossed swords.

## Not known

- Whether other sessions have unpushed work on the same screen files (`recruit_screen.gd` changed 50 times in two weeks; the last pushed change is from 22 Nov).
- How close an engine light can come to the mock-up's glow. Step 5 exists to find out.
- The exact count of tests that will need rewriting.

## The interrogation (a fresh Opus agent, 25 Nov)

It checked the plan's claims about the code against `dev` and found them true. Its findings, all taken into the steps above unless marked:

- The screen only looks like the approved picture once the card and the light are in; the card step is small and should come before the columns. **Taken.**
- The owner should see the spec before any worker starts. **Taken.**
- Fix on the fight screen only what the other steps break. **Taken.**
- Leave the lit areas out of the screenshot compare, or workers will copy the stand-in glows. **Taken.**
- Put the new layout in the existing `assets/glass/layout.json` instead of a second file. **Open:** that file is generated and hash-tested; the spec settles it.
- A long-lived branch rebased over a busy `dev` invites conflicts (143 commits touched `src/screens` since 11 Nov). **For the owner:** one branch to the end, or merges into `dev` along the way.
- The library, settings, landing screen and auras panel are named by the owner as missing; the plan should say who designs them and when. **For the owner.**

