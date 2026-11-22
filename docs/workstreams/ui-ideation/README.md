# UI and UX ideation

An exploratory branch, `ideation/ui-ux`, cut from `dev` at `007e2789` on 21 Nov 2026. Agents propose other ways Bramble's screens could look and work, a council of three models picks and fixes the best, and the owner sees the result. Nothing here is decided for the game, and nothing from this branch enters `main` or `dev` without the owner's say-so for that merge.

## The owner's words (21 Nov 2026)

> "I want you to have a look at the work that's being done in the PDoom repo in terms of on this PC, in terms of using the council skill for design stuff. And I'd like to start a new ideation branch where agents focus on improving our UI and UX in the same method and process that I've gone through there. Can you have a crack at that?"

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

*[Editor note: "length" is read as "lead", a dictation slip.]*

## What is fixed and what is open

*[The orchestrator's reading of the second quote, not the owner's words.]*

Fixed:
1. The theme: an idealised European woodland of animal folk, fairies and oozes.
2. Lead and stained glass, for cards and the whole UI (`docs/design/art-direction/README.md`).
3. The hexagons: units and cards are tall, stretched hexagons set in lead.

Open, on this branch only: everything else. The board's shape, the zones, the shop, the type line, tooltips, screen flow, controls, fonts, wording and what is on screen at all are today's choices, not rules. A concept that reverses an earlier owner decision names it, so the owner can see what they would be reversing.

## Result (21 Nov 2026)

Six concepts were drawn. The council kept three: **A, the great window, refit**; **D, the glazier's bench**; **E, glass in the forest**. After two fix rounds and one touch-up on E, all three members say good to go with nothing blocking, and every member places every one of the three at average or better in the reference gallery (opus: A better, D average, E better; sol: all three average; neon: A average, D better, E better). All three members place today's game below all six concepts.

Nothing is decided and nothing is built. The owner's page: https://claude.ai/artifact/5HLXKUJk4wN6KEC8LUvsoh (private; its source is `results-page.html`, its pictures are in `/data/ui-ideation/page/img/`). What the council agreed in each round is in `council/r1-agreed.md`, `r2-agreed.md` and `r3-agreed.md`; neon's final check is `council/r5-neon.md`.

From stills, motion, timing, hover and drag feel and sound were not judged.

## Pass 2 (22 Nov 2026): the owner's reactions, in short loops

The owner looked at the result and redirected the work, twice. The owner's words are quoted in `briefs/08-pass2-designer.md` and `briefs/13-pass2-round3.md`. In short: nothing at rest explains a card, details show on hover, keyword reminders sit in a fixed place; the card frame may change and spells may take another shape; card size is free (shape and proportions stay); no dimming filters over card art; layouts are judged with blank cards; the art's colour is handled as an art-style recommendation.

The council changed too, on the owner's yes: two Claude Opus voters (a player's eye, and craft) and Gemini Neon, with GPT Sol checking measurable defects only, without a vote.

Rounds 1 to 4 for A, D and E are in `concepts/`, with each round's council answers in `council/p2r<n>-*.md` and what was agreed in `council/p2r<n>-agreed.md`. The council's spacing rule (round 3): a gap of a quarter of the card's width across and down, rows offset and never nested, half a card between zones. After round 4, two of three voters call E's layout ready and the voters split on the board card's width (112, 120 or 128 px), which is the owner's call.

The owner's pages: the rounds, https://claude.ai/artifact/5FHCCWaLvNacStTEfYCW4K ; three card-art styles before and after, https://claude.ai/artifact/HkVAmemUdBwEqQk7oGWC7p (`art-style/`, pictures in `/data/bramble-art/uiid-style/`). The owner's rule on tooltips is `docs/design/owner-notes/2026-11-22a-card-details-on-hover.md`. Nothing is decided and nothing is built.

## Where things are

| What | Where |
|---|---|
| Briefs given to workers | `briefs/` |
| The map of today's game, its critique and the state every mock-up draws | `map/` |
| Earlier owner decisions about screens | `owner-decisions.md` |
| The plan and its interrogation | `PLAN.md`, `interrogation.md` |
| The page shown to the owner | `results-page.html` |
| Designers' concepts (HTML and notes) | `concepts/<letter>/` |
| The council's answers, word for word | `council/` |
| Screenshots of today's game, renders, the reference gallery (other studios' images, never in Git) | `/data/ui-ideation/` on the Optiplex |

## The method

The owner's method from the P(Doom)1 work: understand the live game; decide what must be shown from the player's decisions (the `game-ui-design` skill, copy in `/data/ui-ideation/skills/`); find the bar in games players love; several designers with different assigned styles, none shown another's work; a council (Claude Opus, GPT Sol, Gemini Neon) finds defects, ranks and agrees fixes; the same designers fix; and the final check is whether a concept belongs in a gallery of those games' screens. The orchestrator does not design or review.
