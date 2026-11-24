# Golden as light: a live page of ways to show a tripled unit

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). One bounded job: build one web page that shows, moving, several ways a golden (tripled) unit could look on the board, so the owner can watch them and say which feels right. The owner judges; you build and describe.

Bramble is an auto-battler drawn in lead and stained glass. A unit card is a tall hexagon, 0.56 wide to 1 tall, pointed top and bottom, about 112 px wide on the board, with Attack and Health and no words. Three copies of a unit merge into one golden unit.

## The owner's words (24 Nov 2026)

> "One is a good ability to help a unit be differentiated between tripled and not tripled."

> "It doesn't necessarily need to be a static art thing. You can give me any advice you want. I think it should be a glowing effect or a lighting effect or a shader or something. The goal I'm trying to achieve is: we need a card frame, and I want the user to be able to clearly distinguish between golden and non-golden cards on their board."

> "I want to keep the stained glass feel. And I think the border should probably serve the stained glass feel. Initially, I thought that should be a stained glass border, but maybe it's too busy."

Earlier (22 Nov), a standing rule: darkening or dimming the card art to calm a screen "sucked all the joy out of the scene". Do not dim the normal cards to make golden stand out.

## What to build

`docs/workstreams/ui-ideation/looks/golden/golden.html`: one self-contained page (inline CSS and JavaScript, canvas or WebGL as you like, no outside scripts or fonts; card art as separate image files beside the page in an `img/` folder, copied from `assets/units/`, at most 12 files, each under 200 kB after resizing to about 600 px tall).

For each treatment, show a board strip: seven cards at 112 px wide in two nested rows on a quiet dark teal ground, two of them golden, the rest normal, using real card art of mixed colours (include one mostly yellow picture and one dark picture, the hard cases). Beside it, one normal and one golden card at about 300 px. The frame on every card is the same plain dark lead outline, about 5 px at 112 px, drawn in code; this page is about golden, not about the frame.

Treatments to include, as a starting set. Add up to three of your own, and drop one if it cannot be made to look good:

1. **Gilded lead.** The lead outline becomes gold metal, with a slow sheen travelling round it.
2. **Gold lines in the glass.** The dark lead lines inside the picture itself turn to gold (find them from the art's dark lines), with a faint shimmer.
3. **Light from behind.** The card glows as if the sun is behind the window: a soft warm halo outside the frame, and the glass slightly brighter.
4. **A passing beam.** A band of warm light crosses the glass every few seconds, as sunlight moves across a window.
5. **Motes.** A few slow specks of gold light drift up from the card.
6. **Still only.** The best version you can make with no motion at all, for players who turn motion off.

Each treatment gets a short name, one line saying what it is, and a switch to pause motion. Put all treatments on one page, each running. Keep it smooth: aim for 60 frames a second with all strips on screen on an ordinary laptop; pause strips that are scrolled out of view.

## Finish line

- The page opens from a file and from a web server with no errors in the console.
- Render one still per treatment at 1920 px wide into `/data/ui-ideation/looks/golden/` (`g1.png` and so on) and look at each at full size.
- `docs/workstreams/ui-ideation/looks/golden/notes.md`, 200 words at most: for each treatment, can the two golden cards be picked out at a glance at 112 px, including on the yellow picture; which you would choose and which pairs combine well; what a game shader would do better than this page.

Motion feel is the owner's to judge. From your stills, write "not judged" for timing and feel; never pass them.

## Rules

Write only `docs/workstreams/ui-ideation/looks/golden/`, `/data/ui-ideation/looks/golden/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/look-golden`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. No words on cards; no help text on the page beyond each treatment's name and one line.

## Report

In under 150 words: what you built, which treatments work at 112 px and which do not, and a **Disk** line (what you wrote outside the repo, with sizes).
