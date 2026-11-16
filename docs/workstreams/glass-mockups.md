# Plan: higher-fidelity UI mock-ups in stained glass

<!-- status -->
- **In short:** Recruit and fight screens are built at 250 px. Slot buffs are redrawn (no name, values where Attack and Health sit) and tooltips have more contrast (step 5).
- **Status:** waiting on you
- **Last step done:** Slot buffs and tooltips (step 5, 16 Nov 2026).
- **Next step:** The full scoreboard state, once you say what it should show.
- **Waiting on you:** What the full scoreboard shows.
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
- **Recipe files:** `assemble.py` and `window.json` (`tools/art/glass-art/`), merged into `design/stained-glass-direction` on 16 Nov (PR 56) and so on this branch too.
- **The first mock-up's page,** stone, quarry field, hero portraits and empty slot: copied from the Optiplex (`/data/bramble-art/stained-glass/glass/`).
- **Branch:** a new branch, `design/glass-mockups`, off `design/stained-glass-direction`. Art goes in as JPEG; PNG masters stay on the Optiplex. Nothing goes to `main` without the owner's say-so.

## Steps

1. **Bring the pieces over.** Copy the old page and its assets, build the card art from the test set, and check every picture under every tier frame for gaps (tier 5 was redrawn after some of the art was made).
2. **Recruit screen.** The first mock-up's layout with the new cards: the shop's 5 units and 2 spells (rulebook 6.1.1, settled 13 Nov), with gold, tier up, refresh and freeze in the shop zone; the board 4 and 3; the hand; the hero and End turn; Turn. Shown at two card sizes (see below), with the leaderboard on and off, and one card hovered. A card sheet with every tier and one- and two-digit numbers goes alongside, as a check on the number fit. **This is the first mock-up shown to the owner.**
3. **The owner's refinements.** Whatever the owner asks for after seeing step 2.

   **Spells above the shop (owner, 15 Nov 2026), tried:** "I think if we have spells in the shop, they'll take up a second row above, and maybe they won't be, maybe they'll be smaller hexes, like almost regular hexagons rather than the tall hexes. That way we can have the shop be centered. And maybe we just do, two spells in between the, on either side of the third card, basically, but above." Built as a switch, with the first layout kept beside it for comparison.

   **Then, on their size (owner, 15 Nov 2026):** "The card size of them should be exactly the same as the width, but they should be regular. So they should inherit the width from the normal cards, but the height of a regular hexagon. ... I want a regular hexagon of the same width, so it tiles is the exact same." Done: each spell is a regular hexagon exactly a unit's width (height = width / (√3/2), about 0.65 of a unit's height), sitting in the notch between two units with the same gap as the board's back row. A regular hexagon's sides slope at 30°, the units' roofs at 31.3°, so the gap narrows very slightly towards the point. To fit the taller spell row the hand gives way: at 250 px it shows a little under half a card.

   **Card-shape bug, and spells matched to it for now (owner, 16 Nov 2026):** asked whether "the slightly off angle" meant the spells should slope like the cards' roofs, the owner said: "No. I want them to be the regular hexagons. Like our existing borders are slightly off. I'll fix them in future. For now, it just needs to be noted that our existing shapes are off by that, however many degrees, the 1.3 degrees. And that's a bug on the card side, not on the spells side. I guess until that point, we can have it match the inverse, like the upper and like the, we can make them slightly like less. They can be, instead of being, they could be like 27, oh, sorry, 28.7 or something, I guess. I don't know, to make that match." Recorded as a known bug in [frame-lab/art-space.md](../design/art-direction/frame-lab/art-space.md). The spells now slope at the cards' 31.3°, with all six edges as long as a card's roof edge, so the gap to the units is even; "Regular, 30°" is a switch for when the frames are fixed. *[Editor note: matching means 31.3°, not 28.7°.]*

   **Chosen (owner, 16 Nov 2026):** asked to pick 212 or 250 px, the owner first said: "Can you explain what the difference between the two sizes are again? Sorry. I think the sizing that matches the length of the slightly off angle is correct." Then, sending the 250 px screenshot with these spells ([recruit-250-spells-above.jpg](../design/art-direction/mockups/shots/recruit-250-spells-above.jpg)), the owner said: "I like this image, if that answers the question." So cards are 250 px tall, and the spells are regular hexes the units' width, as above. The page now opens on this version; the other sizes and layouts stay as switches.

4. **Fight screen (owner, 16 Nov 2026).** Asked which screen next, the owner said: "Fight screen". Built from rules already set, with the same window, cards and heroes as the recruit screen:
   - Both boards are 4 and 3 bricks with the front rows facing each other across the stone transom; the opponent's board takes the shop's light, mirrored.
   - Your board stays the same size and centred, and moves down about 90 px into the hand's space; the hand leaves (owner, 14 Nov: "I don't think your hand is needed for combat", "maybe the board can move a little bit").
   - Dead units leave their slot empty, as units never slide to fill a gap (rulebook 8.3.4); your slot buffs come into the fight (9.1.1). Mid-fight, the dead are front-row units, since the back row can't be attacked while a front unit lives (9.5.1).
   - Your hero bottom left as in recruit; the leaderboard in the right light when shown.
   - Two moments: before the first attack, and mid-fight (a unit lunging across the transom, damage splashes, damaged Health in red). The lunge, splashes and red Health are stand-ins; nothing about fight animation is designed.
   - Not decided, chosen for the mock-up: the opponent's hero at the top of the right light, beside their board; the opponent's slots read left to right like yours (F1 on the left); no fight controls (speed, skip).

5. **Slot buffs, tooltips and the full scoreboard (owner, 16 Nov 2026).** The owner, on the recruit and fight screens: "No, I'm fairly happy for now. I obviously want to, we need the full scoreboard state for when the full scoreboard's being displayed. I would like the tooltips to maybe have a bit more high contrast, and we can think about how the tooltips work when you hover over cards, etc. I think that also the slot buffs are not well done currently. I want the ability when you hover, like the rings are communicated horribly currently, right? Like we won't be calling the slot buffs rings. That's not going to be going into the game. That was an ideation thing. I don't know how that leaked, but I want them to match the positioning of where the power and toughness would be without. And I want to ensure that we capture it in a similar way to how Galaxy does, which I think does it fairly well." *["power and toughness" means Attack and Health.]*
   - **Slot buffs, done:** the name "Ring" and its amber ring are gone. An empty buffed slot shows its values, "+4" and "+4", in green glass discs on the tier-1 frame's Attack and Health disc positions. A unit on a buffed slot has the buff in its numbers and a small green splat under its stats; Galaxy's guide describes "a subtle green splat icon under the stats" ([guide.galaxy.fun/slot-buffs](https://guide.galaxy.fun/slot-buffs/)), and says nothing about empty slots, so that part follows the owner's words. Hovering a buffed slot says what it gives; hovering a unit on one adds a green "Slot buff" line. The colours and the splat are stand-ins.
   - **Tooltips, done:** near-black glass with a light rim, brighter text, the name in gold, larger rules text. How hover works on cards is still to think about with the owner.
   - **Full scoreboard:** waiting on what it should show.

Before each step is kept: screenshots of every view, and a scope review by a fresh agent.

**Checkpoint after step 2:** is this the higher-fidelity mock-up you wanted, and which card size? Answered 16 Nov: 250 px, spells above (step 3).

## Things the new cards change

- **Card size.** The new card is narrower (0.56 against about 0.79). At the first mock-up's card height (212 px) it is 119 px wide, so the board and shop take less width and the numbers are small. A larger card makes the art and numbers easier to read but uses height, which is scarce. Step 2 shows both. Neither has been judged at game size on a real screen yet.
- **The board packs differently.** The new card's points are deeper, so the back row nests further into the front row.
- **Seven shop offers.** The first mock-up showed five.

## Stand-ins, labelled as such

- **Spells.** There is no spell frame yet. The two shop spells get a marked stand-in.
- **Empty slot:** the first mock-up's, reused. **Slot buffs:** redrawn in step 5. Can or cannot afford, selected, frozen and golden have no design yet and are left out.
- **Hero portraits:** the first mock-up's glass portraits.

## Not in this plan

- New frames, or changes to the art recipe.
- A playable build or anything in Godot.
- The woodland backdrop switch from the first mock-up (the window architecture is open), unless it comes free with the old page.
- Phone or small-screen layouts.

## How this fits the dial-in plan

The dial-in plan's step 3 (screen refinements, on the owner's list plus spacing) is done through these mock-ups. If approved, its status block points here and its "Waiting on you" about the list moves to this plan's step 3.

## Questions for the owner

1. After the recruit screen, which other screens do you want at this fidelity: the fight screen (deferred in the dial-in plan "when the owner asks for it"), choosing a hero, the end of a game, or none yet? Answered 16 Nov: the fight screen (step 4).
2. Do you already have the "few more things" for the UI and the spacing you want locked, or would you rather react to the recruit screen first?
