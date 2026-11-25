# Build step 6: light on the L1 buy screen

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal** for how to carry out step 6 of a plan; the owner's own words are quoted below and outrank it.

## The job in one paragraph

Bramble's buy screen has been rebuilt to a new look the owner chose from an HTML mock-up. Steps 1 to 4 are on the branch you start from: the room, the card, the shop and the columns. What is missing is light. Where the mock-up glows, the game shows a flat stand-in or nothing: a solid tint fills each shop arch, a golden card has no halo, lit lanterns and beads give off nothing, End turn never changes. You make those lights, as effects the engine draws and animates, so the built screen has the mock-up's sense of coloured light coming through glass. The game has no lights or particles yet, only a few small shaders, so how you build them is yours to choose.

## The owner's words

25 Nov 2026:

> "Obviously, the glows we've got are not how the glows will look in Godot, and that needs to be documented. There needs to be some sort of lighting effect in Godot rather than some sort of static asset. And the twinkles on the gold borders are going to fall into the same kind of bucket. But that's okay. I think that's understood."

> "The archway needs a bit more negative space ... so that the lighting effect has a way of glowing, like in the original mock-up."

24 Nov 2026, of the tier light in the shop:

> "It can be pretty subtle ... maybe even the red should be a little bit less: a bit more than what our tier four is, and a bit less than what our tier five is, in terms of lighting strength. And the scale should start at the same point from tier one."

> "Tier on the board on hover only, agreed."

The three things the owner wants from this look, in their order: a golden unit is clear on the board at a glance; a shop card's tier is felt at a glance; it feels like stained glass. Standing rules: quiet backgrounds; no dimming filter over card art; "Don't be too stringent. We're trying to do good design, right? That's the number one priority."

## Where you work

- Your checkout: `/data/worktrees/ui-l1-step1`, already on branch `ui/l1-step6-light`. Work only there. Do not switch branches, merge, rebase or push. Commit your work on that branch, in a few clear commits.
- Scratch: `TMPDIR=/data/ui-ideation/tmp/step6`. Pictures and films for the report: `/data/ui-ideation/build/step6/`.
- Godot is `/usr/local/bin/godot`. The quality gate is `./scripts/check.sh`. It is long: run it in the background with a time limit.

## What to read first

- The spec: `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/spec/buy-screen-l1.md`, section 9 (the eight lights, the tier colours and strengths, the motion the notes ask for) and section 11 items 15, 16 and 28. Its numbers describe the mock-up's stand-ins: where to start, not a target.
- The mock-up, to see what the light is meant to feel like: `/data/ui-ideation/looks/L1/c/c8-spec.png`. The built screen as it is now: `/data/ui-ideation/build/step4/buy.png`. Put them side by side.
- The look's notes on motion and light: `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/looks/L1/look.md` ("Motion and light").
- The game: what step 3 added for the stand-ins (`src/glass/l1_shop_arch.gd`, `l1_shop_wall.gd`, `l1_refresh_beads.gd`), the card (`l1_card_face.gd`, its shader), End turn in `src/screens/recruit/`, the existing effects (`glass_duplicate_glow.gd`, `glass_triple_foil.gd`), and `tools/feel` (films a scene at a true 60 frames a second) with `docs/AGENT-BLIND-SPOTS.md`.

## The lights

Each of these, as an effect drawn at run time and tinted at run time. None may be a glow painted into a texture.

1. **Shop tier light.** Each arch is lit from behind in its card's tier colour, at that tier's strength: brightest behind the card, falling off toward the stone, a little spilling onto the wall and the sill. It replaces the flat tint. An empty arch is dark.
2. **Spell tier light.** The same idea behind each shop spell.
3. **Lanterns and beads.** A lit lantern and a lit bead give off a small warm light.
4. **Golden.** A golden unit has a warm halo that marks it from across the board, its gilt catches light, and a slow glint runs along the gilt every few seconds.
5. **Tier on hover.** A board or hand card that is pointed at gets its tier's light hugging it (the orchestrator's pick; the owner agreed that tier shows on hover and nothing is drawn on the card).
6. **End turn.** Steady while the player can still do something; a slow glow when nothing is left to do; a flash as the fight starts. The state gives no "nothing left to do" flag: reading it from the legal actions is a proposal you may improve on. Never change what End turn does.

Slow, quiet motion: the notes ask for arches that breathe slowly and a golden glint every few seconds. Nothing should pull the eye from the cards.

## What matters, in order

1. It must still play exactly as it does. No rule or input change; the fight screen's behaviour is untouched (its cards may take the golden light and nothing else).
2. Card art is never dimmed or washed over. Light goes behind and around a card, not across its picture.
3. Tier strength follows the owner's words above. Tier 6 sits between tier 4 and tier 5.
4. It runs smoothly. The owner plays on an ordinary Windows PC; you cannot measure that here, so prefer cheap effects and say what you chose and why.
5. Then: the closer it feels to light through glass, the better.

## What you cannot judge, and what to do about it

You cannot see motion, and a still cannot show whether a glow breathes well. Do not write that the light looks good or passes. Instead:

- Film each light with `tools/feel` at 60 frames a second and save the films in `/data/ui-ideation/build/step6/` (the shop with all six tiers on show if a state allows it, a board with a golden unit, a hand card pointed at, End turn in its three states). Say for each film what it shows.
- Save stills next to them, and one side-by-side of the built shop and the mock-up's shop.
- Write "not judged" for motion, timing and feel. The owner judges them.
- Put each light's numbers (colour, strength, size, speed) in the hand-kept layout file so they can be tuned without code changes, and list them in your report.

## Tests

Add tests that each light exists where it should, takes its tier's colour and strength, and is absent where it should be (an empty arch, a plain unit, an unlit lantern). Rewrite a test only if it is pinned to a stand-in you replace. Tests of behaviour pass unchanged.

## Done means

- `./scripts/check.sh` passes in your checkout. Quote its last summary lines.
- The films and stills above exist and you have looked at the stills at full size.
- A list of anything in the spec you found wrong, missing or impossible, each in a line.

## Rules

No rule, balance or input change. Nothing outside the buy screen's lights and the golden card's light. Do not read token or `auth.json` files. Start no subagents. Never run `rm -rf` or any other delete, inside your checkout or outside it: list what should be removed instead, with paths and sizes.

## Report

Under 300 words: how each light is built and why, the commits, the checks' result, each film and still with what it shows, the tunable numbers, what you could not solve, and a **Disk** section (every folder you wrote outside your checkout with its `du -sh` size, what can go, and `df -h` for `/data` at the start and at the end).
