# L1 at real size: the screen, the card's shape and a little depth

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). For the art director of look L1. The owner chose L1. This step builds it as real screens at 1920x1080, with real card art, so the owner can judge size, layout and the card's shape. You design and build in code; a separate worker paints any pictures you order.

## The owner's words (24 Nov 2026, after looking at the three looks)

*[Transcribed from dictation: filler removed, punctuation added, clear dictation errors fixed.]*

> "I agree with you that L1 is the best. And I think the background lighting effect in the shop, like the red's over the top, it needs to be dialled back. They [can] have less glow and you can have less of a progression, less of a difference between the things. It can be pretty subtle, right? It doesn't need to be as really distinct. I think the tier fives, the legendaries, already kind of produce a lot of light. I think maybe even the red should be a little bit less: a bit more than what our tier four is, and a bit less than what our tier five is, in terms of lighting strength. And the scale should start at the same point from tier one. Go up from there."

> "Cards are staying on the board. Tier on the board on hover only, agreed. The tier 5 orange, agreed. I agree with calmer card backgrounds. We need less bright backgrounds. Maybe not as washed out as this, but definitely we need to set guidelines for background colours that are allowed per tribe. Maybe not too plain."

> "Do you have similar thoughts on sizing and UI layout? I still think that the board having the 4-3, the two rows, is important to me, but I'm willing to sacrifice card height, and I would like to keep the card's angles at exactly the shape of a regular hexagon for the top part. That needs to change, I would say, because I think it's slightly off. We could even actually go to less than a regular hexagon, I suppose. But yeah, card height and aspect ratio: if you have strong opinions on how we could change that, and if changing that would really aid in UI design and fitting things in, I'm interested in hearing it."

> "I don't think we necessarily need to go the whole way L2 does with perspective, but giving a bit more of a 3D feel. Basically the game right now operates purely as a 2D game. If we could just evoke, I guess, almost like two-and-a-half-D. We can hold that, I guess, for now, or not, I'm not sure. Surprise me, I guess."

Standing, from 22 Nov: "The padding in every direction should be equal, both along both 45-degree axes and the vertical lines." And: "Don't be too stringent. We're trying to do good design, right? That's the number one priority."

## Settled by the owner

L1 is the base. Cards stay on the board. No tier mark on the card: tier shows in the shop's light and on hover. Tier 5 is orange. The board is two nested rows, four over three. The card's points take the angles of a regular hexagon (or flatter). The shop light is calmer than in your paintings, as the owner describes above.

## The orchestrator's view (advice, for you to test or overturn)

- **The card is too tall for a wide screen.** Today it is 0.56 wide to 1 tall. A fight stacks four rows of cards, so height sets the card's size, and at 112 px wide the boards use under a third of the screen's width. A shorter card can be wider at the same height. With regular-hexagon points (the point rises 0.289 of the card's width), a card whose straight sides are one and a half times its sloping edges is 0.69 wide to 1 tall; at about 140 x 200 px it fills the same rows as today's 112 x 200 with a quarter more picture, and the screen has room for larger still. I would try that first. Card art is to be repainted with calmer backgrounds anyway, so its window can change at the same time.
- **Equal gaps still work.** With regular points, two rows nest like a honeycomb: with a gap g everywhere, the second row's points sit 0.866 g below the line where the first row's sloping edges end.
- **Depth without perspective on the cards.** I would keep every card flat to the viewer and get depth from the room: the shop wall stands upright, the table lies under it, and the cards stand on the table as panes of glass that throw a faint pool of their own colours forward onto the wood, as real stained glass does. A golden card throws gold. A hovered card lifts towards the viewer and its light spreads. That is my surprise for the owner; yours may be better.

## What to build

A page, `docs/workstreams/ui-ideation/looks/L1/screen.html`, that draws the buy screen and the fight at 1920x1080 from layers, with switches in the address (for instance `?shape=b&view=fight`):

1. **The buy screen and the fight**, in the L1 look, with today's card art from `assets/units/` cropped to the card's window. What is on the screen, and the rules it must respect (five units and two spells in the shop, seven board slots, a hand of seven, eight players), are in `docs/workstreams/ui-ideation/owner-decisions.md` and `/data/ui-ideation/concepts/A/p2r5/` (an earlier layout; use it for content, not look). Two golden units on the board. No words at rest beyond numerals.
2. **Card shapes to compare.** Three or four proportions with regular-hexagon points, from today's 0.56 to nearly a regular hexagon, each at the largest size that fits both screens with equal gaps; and one with a flatter point. Say which you would choose and why.
3. **The shop light**, redone to the owner's words: calm, a gentle rise from tier 1, tier 6 between your painted tier 4 and tier 5 in strength.
4. **Depth.** One buy screen with your best idea for a two-and-a-half-D feel, and the same screen without it, so the owner can compare.
5. Golden as gilded lead plus light from behind; `docs/workstreams/ui-ideation/looks/golden/golden.html` has code for both that you may reuse.

For the room (stone wall and arches, oak table, leather ledge, side windows, a fight backdrop), order pictures: write `docs/workstreams/ui-ideation/looks/L1/prompts-3.txt` (up to 8 items, in the format of your earlier orders) and reply at once; the orchestrator runs it and messages you. The image tool does not hold exact positions, so ask for pieces and plain surfaces you can cut and place in code, not for finished screens. Light effects are better done in code.

## What to deliver

Render at 1920x1080 into `/data/ui-ideation/looks/L1/real/`: the buy screen and the fight for each card shape; the depth pair; and `shapes.png`, the card shapes side by side at their real sizes with the pixel sizes written beside them. Look at every render at full size. Add a section "At real size" to `look.md`, 300 words at most: the shape and size you recommend with the numbers, what the shorter card costs, what depth adds, and what falls short.

## Rules

Write only `docs/workstreams/ui-ideation/looks/L1/`, `/data/ui-ideation/looks/L1/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/look-L1`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model yourself. From stills, motion and glow timing are "not judged".

## Report

In under 200 words: what you built, the shape you recommend, what falls short, what you need next, and a **Disk** line.
