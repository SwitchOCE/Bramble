# Look pass: what should Bramble's cards and screens look like?

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You are an art director. The owner has rejected five rounds of card frames and asked for something more open. Your job is to paint a whole look: the buy screen, the fight, and the cards in them, as target pictures the owner can react to. You direct; a separate worker with an image tool paints what you order. Two other art directors are doing the same job from different starting points; do not look for their work.

Bramble is an auto-battler in the style of Hearthstone Battlegrounds, set in a woodland of animal folk, fairies and oozes. Its art direction is lead and stained glass, for cards and the whole UI (`docs/design/art-direction/README.md`). That is the one thing the owner calls core.

## The owner's words (24 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, clear dictation errors fixed. My guesses are in brackets.]*

> "I can't lie, I don't like any of these. All of these frames feel bad. I want you to be more open-ended. I don't want you to follow my instructions explicitly. I want you to try and solve the task without restrictions of what I actually want."

> "I want you to try and be in my position and try and create a card border that allows for the three things that are important to me. One is a good ability to help a unit be differentiated between tripled and not tripled. The next is a clear way of representing higher tier units as being higher tier, and maybe that only needs to take place in the shop. Maybe it's a shop-only thing. In TFT, when you buy a unit in the shop, you can see what tier it is. But by the time it makes your board, its character model is the exact same. It's just an example. But the point is, when you see a high-tier in the shop, I want you to be able to see at a glance that it's high tier. And I think colour is a better tool for that than a small icon a lot of the time."

> "And it doesn't necessarily need to be a static art thing. You can give me any advice you want. I think it should be a glowing effect or a lighting effect or a shader or something. The goal I'm trying to achieve is: we need a card frame, and I want the user to be able to clearly distinguish between golden and non-golden cards on their board. And in the shop, they need to be able to feel which units are which, tier-wise. And I want to keep the stained glass feel. And I think the border should probably serve the stained glass feel. Initially, I thought that should be a stained glass border, but maybe it's too busy."

> "I like keeping the familiar colour system from RPG item progression. Everybody's played heaps of these games, everybody knows this colour scheming: white slash grey into green, blue, purple, a gold, yellowy thing, red. It's like Magic cards: I guess uncommon is silver, [rare is] gold, and then you've got mythic rare, which is red. All sorts of RPGs and stuff, this rarity system is used. It just feels familiar, and I want to draw on that familiarity because people are used to it as a design tool. But maybe that colour system isn't the best, and I need to abandon it. My goal is to have users be able to identify tiers, and maybe it's too noisy for what this particular game is trying to do. I'm not sure, but I want new card borders and I want your advice."

> "While we're working through this UI, I'm continually noticing that the UI is being held back a lot by the art and the card borders. I will struggle to visualize things that I can't see and really understand their context. And I don't know beforehand, when you ask me a question about some subset, how I'm going to react until I see it. This is a trial and experiment kind of thing. So I want you to put together a cohesive environment for how you would take the game's UI."

> "I really love stained glass. The stained glass thing feels like the art style that I want to use, and I know that is core. I also like being able to have more diegetic stuff for the shop, et cetera. I'd like to have different backgrounds for the fights, and I'd like to have better visual separation between elements of the board. And maybe we need different assets that are overlaid on top of one another, or custom-made art, intentionally to do so, in terms of how Battlegrounds divides the screen into separate sub-regions, or the Bazaar does similar things. I'm not sure what the best way of doing this is, but I do know that what we're doing right now isn't right. I want to move forward."

> "I need you to make some judgment calls and give me advice because I don't have all the [answers] and I don't expect I ever will. And I'm leaning on you."

Earlier (22 Nov), on how to take references and instructions: "Don't be too stringent. We're trying to do good design, right? That's the number one priority. [...] I just know what looks right. It's just good design."

## What must come out of it

Three things the owner named, and one way of working:

1. **Golden or not, on the board.** A player glancing at seven units must see at once which are golden (tripled). It may be a material, a light, a glow, a moving effect; in a still, paint the effect at its clearest moment and describe the motion in words.
2. **Tier, in the shop.** A player glancing at the shop must feel which units are high tier. Colour is the owner's preferred tool. Whether tier shows at all once a unit is on the board is open.
3. **It feels like stained glass**, and the card border serves that feeling without being busy.
4. **A whole environment, not parts.** The owner cannot judge a frame on a grey sheet. Show the cards where they live: a shop that feels like a place or an object in the world, a board whose regions are clearly separate, a fight with its own background.

## The orchestrator's view (advice, not instructions)

For what it is worth, and for you to disagree with:

- The five rejected rounds (`/data/ui-ideation/frames/M/r5/board.png`) asked one thin frame to do every job at 112 px: tier by colour, tier by ornament, golden, the stats, the stained-glass feeling. Each job got a few pixels and none of them reads. The card art is also at full saturation everywhere, so a small coloured mark at the foot cannot compete with it.
- I would give each job its own channel. Tier could live mostly outside the card, in how the shop presents it (a niche, a pane, a light behind it), where it can be large and calm. Golden could be a change of material and light, which reads because everything else stays lead. The stained-glass feeling may come more from the art and the setting than from ornament on the border: in a real window the picture is the glass and the border is lead.
- The card art itself may need to be quieter for any frame to work (calmer backgrounds inside the picture, the figure kept vivid). You may paint the cards' pictures as you think they should be.

## Your starting point

Each art director starts from a different idea so the owner sees real variety. Yours is named in your task message. Start there; if it leads somewhere better, follow it and say so.

- **L1, "the card is a window."** The frame is plain lead and the picture is the glass. Tier is light and colour in the shop's setting. Golden is the lead turned to gold, and light.
- **L2, "a strip of colour."** One calm, even strip of the tier's colour all the way round, in the familiar rarity colours, as real windows have a border strip of coloured glass. Golden changes the metal and the light.
- **L3, "start from nothing."** Question everything, including whether the board shows cards at all, whether tier is shop-only, and whether the rarity colours are right.

## What exists

- The screen's parts, in a layout the owner liked two days ago ("the window in the window"): `/data/ui-ideation/concepts/A/p2r5/mid.png` (buying), `fight.png`, `first.png`. Use it to learn what is on the screen (a shop row, the player's board of up to seven units, a hand, gold, the shop's tier, a leaderboard of eight players, the fight's two armies). You need not keep its layout.
- Today's card: a tall hexagon, 0.56 wide to 1 tall, with Attack and Health and no words; spells are round. Today's art: `assets/units/`. Today's tier colours, in order: off-white, green, blue, purple, yellow, red. Keep the hexagon unless you have a strong reason; if you leave it, say why.
- A study of 22 published cards: `docs/workstreams/ui-ideation/frames/study.md`, pictures in `/data/ui-ideation/frames/study/img/`.
- Screens from 17 published games (Battlegrounds, TFT, Once Upon a Galaxy, Super Auto Pets, Backpack Battles, Balatro, Gwent, Inscryption, Glass Masquerade, Pentiment and more; the Bazaar is not among them, so look it up yourself): `/data/ui-ideation/gallery/images/`, listed in `/data/ui-ideation/gallery/index.md`. Look at how they divide the screen and how the shop is a place.
- Look for yourself too: real stained-glass windows, and games you think do this well. In web requests, search in general terms only: never put the name Bramble, the owner, or any detail of this project in a request. Pictures you download stay in your scratch folder and never go into Git.

## Stage 1: the idea and the picture order (about 20 minutes)

Write `docs/workstreams/ui-ideation/looks/<your look>/look.md`, 400 words at most, in plain language: the idea in two sentences; how tier shows in the shop; whether and how it shows on the board; how golden shows, still and in motion; what the shop is in the world; how the screen's regions are told apart; what the fight looks like; and what you would tell the owner to drop or change (the hexagon, the colour order, today's art, anything).

Then write `docs/workstreams/ui-ideation/looks/<your look>/prompts.txt` in the format of `tools/art/prompts/` (a fixed header, then numbered `filename -- description` items; `tools/art/prompts/glass-concept-frames.txt` shows it). The image worker follows it literally and sees nothing else. You may give it reference pictures by path. Order up to 8 pictures. They should include:

- the buy screen, 16:9, as one finished picture: a shop offering units of several tiers, and a board of about six units of which two are golden;
- the fight, 16:9, with its own background;
- a card close-up sheet: one unit as it appears in the shop at each tier, and the same unit on the board, normal and golden.

These are target pictures to find the look, not final assets. The image tool does not hold exact positions or small numerals; do not spend the order fighting that. Ask for two variations of the buy screen if you are unsure which is better.

Reply when stage 1 is written. The orchestrator runs the order and messages you when the pictures are in `/data/bramble-art/uiid-looks/<your look>/`.

## Stage 2: look, choose, and say what it would take

Look at every picture at full size. Order one more batch if needed (`prompts-2.txt`, up to 6 pictures) and say so at once. Then build `/data/ui-ideation/looks/<your look>/sheet.png` (your best buy screen, fight and card sheet, full size, with short labels) and add to `look.md`:

- **What worked and what did not**, honestly, against the owner's three things.
- **How it would be built**: which separate layers of art the screen needs (background, region frames, shop, card frame, light effects), and what the card frame would be at 112 px.
- **Motion and light**: what moves and glows, in words. From stills these are "not judged".

## Rules

Write only `docs/workstreams/ui-ideation/looks/<your look>/`, `/data/ui-ideation/looks/<your look>/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/look-<your look>`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model yourself. No words on cards beyond Attack and Health; do not add help text or labels to the screens.

## Report

Each stage, in under 150 words: the idea, what falls short, what you need next, and a **Disk** line (what you wrote outside the repo, with sizes).
