# Plan: higher-fidelity UI mock-ups in stained glass

<!-- status -->
- **In short:** The recruit screen is built with the real frames and art, at two card sizes, with the spells now in a row above the shop. Waiting for you to pick a size.
- **Status:** waiting on you
- **Last step done:** Your first refinement: spells as smaller hexes in a row above the shop (15 Nov 2026).
- **Next step:** Your reaction to the recruit screen (step 3).
- **Waiting on you:** Is this the mock-up you wanted, and which card size? The two questions at the end are still open.
<!-- /status -->

Status: approved by the owner, 15 Nov 2026. Asked "Approve the mock-up plan?", the owner said: "Approve it". The two questions at the end were not answered then.

The mock-ups: [../design/art-direction/mockups/](../design/art-direction/mockups/README.md).

## The problem, in the owner's words (15 Nov 2026)

"What I want to do is move on to higher fidelity UI mockups now that we've got the new art direction, and the new art images, and the new frames."

On the Attack and Health numbers: "we need to account for the roundels being in slightly different positions with our fonting, our templating. ... as long as we get it close enough, it'll be fine. Like, I'm going to have a human artist do it eventually anyway, so they can have that precision."

Earlier, on the first glass mock-up: "The UI is very close, so I just want to refine a few more things."

## What "higher fidelity" means here

The first glass mock-up ([glass-mockup.jpg](../design/art-direction/examples/glass-mockup.jpg)) used stand-in cards: a wider hex (about 0.79 wide to 1 tall) with lead drawn by an agent, and art made before the art recipe existed. The new mock-ups replace every card with the real thing:

- the six locked tier frames from `frame-lab/final/`;
- fighter art made by the art recipe, put into the frame with the recipe's fixed crop, never fitted by hand;
- Attack and Health drawn as live text on each tier's own discs, from `frame-lab/final/roundels.json`.

Everything else keeps the first mock-up's layout, which the owner called very close: the window of three lights, board 4 in front and 3 behind offset half a slot, the shop zone holding its own buttons, the boards getting the height, player left and opponent right.

It is a web page at 1920 × 1080 built from the real assets, as the first mock-up was: a still screen, not a playable build. The owner sees screenshots, and can open the page.

## How a card is assembled

One template, used for every card on every screen:

1. **Art.** The Codex picture moved into card space by the recipe's one fixed crop, as `assemble.py` does: crop the 1024 × 1536 picture to (109, 48, 915, 1488) and resize to 1120 × 2000. On screen it is clipped to the recipe's art polygon (`window.json`), so nothing shows past the frame's outer edge.
2. **Frame.** The tier's PNG from `frame-lab/final/` on top. Its window is clear, so only the art shows through.
3. **Numbers.** Attack on the tier's left disc, Health on its right, each centred on that tier's own disc centre and sized from that tier's own disc radius in `roundels.json` (card units, so it works at any card size). Two-digit numbers shrink to fit. Black serif numerals, as in the chosen concept.

Not on the card, because the frames don't have them and the owner asked for Attack and Health only: name, rules text, tier badge, tribe emblem. Rules text appears when the cursor is over a card (the owner, 14 Nov: details follow the cursor, no fixed panel). Its wording in the mock-up is a placeholder; no units are designed yet.

## Where the pieces come from

- **Art:** the art session's test set, 12 subjects in two runs each (Optiplex `window-art-test/`; the newer run made to the current guide if it has landed). They are test subjects, not decided units, and have no tribes. The recruit screen needs about 20 cards, so subjects repeat; a new Codex batch only if the repeats look wrong. The art is not restyled.
- **Recipe files:** `assemble.py` and `window.json` from the unmerged `design/glass-art-recipe` branch, read only.
- **The first mock-up's page,** stone, quarry field, hero portraits, empty slot and Ring slot: copied from the Optiplex (`/data/bramble-art/stained-glass/glass/`).
- **Branch:** a new branch, `design/glass-mockups`, off `design/stained-glass-direction`. Art goes in as JPEG; PNG masters stay on the Optiplex. Nothing goes to `main` without the owner's say-so.

## Steps

1. **Bring the pieces over.** Copy the old page and its assets, build the card art from the test set, and check every picture under every tier frame for gaps (tier 5 was redrawn after some of the art was made).
2. **Recruit screen.** The first mock-up's layout with the new cards: the shop's 5 units and 2 spells (rulebook 6.1.1, settled 13 Nov), with gold, tier up, refresh and freeze in the shop zone; the board 4 and 3; the hand; the hero and End turn; Turn. Shown at two card sizes (see below), with the leaderboard on and off, and one card hovered. A card sheet with every tier and one- and two-digit numbers goes alongside, as a check on the number fit. **This is the first mock-up shown to the owner.**
3. **The owner's refinements.** Whatever the owner asks for after seeing step 2.

   **Spells above the shop (owner, 15 Nov 2026), tried:** "I think if we have spells in the shop, they'll take up a second row above, and maybe they won't be, maybe they'll be smaller hexes, like almost regular hexagons rather than the tall hexes. That way we can have the shop be centered. And maybe we just do, two spells in between the, on either side of the third card, basically, but above." Built as a switch, with the first layout kept beside it for comparison. The spells are about half a unit's height, 0.84 wide to 1 tall; their lower slopes match the units' roofs, so each sits in the notch between two units. To make room the hand shows a little less (57% of a card instead of 70%).

Before each step is kept: screenshots of every view, and a scope review by a fresh agent.

**Checkpoint after step 2:** is this the higher-fidelity mock-up you wanted, and which card size?

## Things the new cards change

- **Card size.** The new card is narrower (0.56 against about 0.79). At the first mock-up's card height (212 px) it is 119 px wide, so the board and shop take less width and the numbers are small. A larger card makes the art and numbers easier to read but uses height, which is scarce. Step 2 shows both. Neither has been judged at game size on a real screen yet.
- **The board packs differently.** The new card's points are deeper, so the back row nests further into the front row.
- **Seven shop offers.** The first mock-up showed five.

## Stand-ins, labelled as such

- **Spells.** There is no spell frame yet. The two shop spells get a marked stand-in.
- **Empty slot and Ring slot:** the first mock-up's, reused. Can or cannot afford, selected, frozen and golden have no design yet and are left out.
- **Hero portraits:** the first mock-up's glass portraits.

## Not in this plan

- New frames, or changes to the art recipe.
- A playable build or anything in Godot.
- The woodland backdrop switch from the first mock-up (the window architecture is open), unless it comes free with the old page.
- Phone or small-screen layouts.

## How this fits the dial-in plan

The dial-in plan's step 3 (screen refinements, on the owner's list plus spacing) is done through these mock-ups. If approved, its status block points here and its "Waiting on you" about the list moves to this plan's step 3.

## Questions for the owner

1. After the recruit screen, which other screens do you want at this fidelity: the fight screen (deferred in the dial-in plan "when the owner asks for it"), choosing a hero, the end of a game, or none yet?
2. Do you already have the "few more things" for the UI and the spacing you want locked, or would you rather react to the recruit screen first?
