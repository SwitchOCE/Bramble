# The owner's earlier decisions about screens

Written on 21 Nov 2026 for the `ideation/ui-ux` branch, from the owner's own words in the repo. It lists every decision, rule or stated preference of the owner's that shapes what is on screen or how the player acts, so that a concept which reverses one can name it. It leaves out unit numbers, balance, bots and the build toolchain.

**Fixed** on this branch means part of the three fixed things: the woodland theme (animal folk, fairies, oozes), lead and stained glass for cards and the whole UI, and units and cards as tall, stretched hexagons in lead. Everything else is **open**: a designer may reverse it, and says which row they reverse. **Unsure** rows say why. The owner's words for the branch: "hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate." (21 Nov, `docs/workstreams/ui-ideation/README.md`)

Quotes are exact but cut short; "..." marks a cut. Paths are from the repo root. Where two sources disagree, both are given and the later one is named.

**Accepted in general is not a rule.** On 17 Nov the owner, after playing the build, said: "I am happy with all of the card art and the mechanics so far and the UI" (`docs/ideation-track-2/README.md`). That accepts the build as a whole. It does not turn the agents' layout calls into owner rules; those are in the second table.

## 1. The owner's decisions and preferences

### The look

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 1 | Cards and the whole UI are lead and stained glass, and this overrides any contradicting instruction on any branch. | "do up the UI with lead lining and stained glass art"; "this is authoritative" (15 Nov) | `docs/design/owner-notes/2026-11-15b-stained-glass-direction.md` | Fixed |
| 2 | The theme is a magical woodland realm of animal folk, with fairies and oozes. | "We could have fairies, right? I think that makes sense in a little woodland realm."; "something like oozes, with ludicrous high-pitched voices" (27 Oct) | `docs/design/sources/2026-10-27-battlegrounds-direction.md` §6 | Fixed |
| 3 | Call them "fae", not "fairies", so they feel adult and dangerous. | "I think I prefer the term "fae" to "fairy"." (15 Nov) | `docs/design/owner-ideas-log.md` #9 | Open (a word; the fae themselves are fixed) |
| 4 | A demon-like tribe might be djinn, with a Middle Eastern feel. | "Have a kind of Middle Eastern vibe." (15 Nov) | `docs/design/owner-ideas-log.md` #7 | Unsure: an idea, not a decision, and an exception to the European woodland of the fixed theme |
| 5 | Each tribe's glass shows its biome. | No quote in the repo; recorded as "already the owner's" (15 Nov) | `docs/workstreams/glass-dial-in.md` step 4 | Unsure: part of the glass look, but which biome and how is not among the three fixed things |
| 6 | Fighters are warriors shown full body, not cute or zoomed in. | "these are fighters. They're supposed to be warriors" (14–15 Nov) | `docs/design/art-direction/README.md` | Unsure: card art is in glass (fixed), but how figures are drawn is not named as fixed |
| 7 | The card art recipe stays as it is. | "This process is producing what I like" (15 Nov) | `docs/workstreams/glass-dial-in.md`; `docs/design/art-direction/card-art-recipe.md` | Unsure: it is how the glass art is made, not the glass itself |
| 8 | Tier frames start plain at tier 1 and gain more panes and deeper colour as tiers rise; the six frames (take 1 of thin-c) are locked. | "starting off pretty plain at the lower tiers and going with more segments and more color tinting as the tiers rose" (15 Nov) | `docs/workstreams/glass-frames.md` | Unsure: the frames are lead and glass (fixed); this ladder is a choice inside that |
| 9 | Frame accents are mirror-symmetric. | "I like the symmetry, and I think we should keep the symmetry of the accenting." (15 Nov) | `docs/workstreams/glass-frames.md` | Unsure: as row 8 |
| 10 | Tier colours run grey (tier 1), green, blue, purple, yellow, red. | "white, then green, then blue, then that purple, then like yellow for legendary and red for mythic"; "The white stuff can be gray." (15 Nov; order confirmed 16 Nov) | `docs/design/art-direction/README.md`; `docs/workstreams/glass-frames.md` | Unsure: a glass colour scheme, but tier marking is listed as open in the art README |
| 11 | Units are tall hexagons. | "somewhere between the mid hex and the tall hex" (11 Nov); "the tall hexes ... these are the right path" (14 Nov); "the warped hexagons ... sacrosanct" (21 Nov) | `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md`; `docs/workstreams/ui-ideation/README.md` | Fixed |
| 12 | The card outline is 0.56 wide to 1 tall. | "I think everything we want to do from now on is 0.56"; later the same day, "let's not be too rigid on anything yet" (15 Nov) | `docs/workstreams/glass-frames.md` | Unsure: the tall hexagon is fixed; whether this exact ratio is part of it is not said |
| 13 | The cards' roofs are 1.3° off a true hexagon, and that is a bug in the card frames, to be fixed later. | "that's a bug on the card side, not on the spells side" (16 Nov) | `docs/workstreams/glass-mockups.md` (on branch `design/glass-mockups` only); `docs/design/art-direction/frame-lab/art-space.md` | Unsure: it is not clear whether "warped hexagons" (21 Nov) means the stretched shape or includes this angle |
| 14 | The background frames play; the gameplay stays central; the background may be covered; areas of the screen are visibly separate. | "the background is there to provide framing, but the gameplay still needs to be central"; "There needs to be visual breakup between different areas of the screen." (11 Nov) | `docs/design/sources/2026-11-11b-art-meets-in-the-middle-and-framing.md` | Open |
| 15 | Cards and background should match in fidelity. Said of the look before glass. | "they need to come closer together" (11 Nov) | `docs/design/sources/2026-11-11b-art-meets-in-the-middle-and-framing.md` | Open |
| 16 | The glass screen mock-up is close; refine it, don't redo it. | "The UI is very close, so I just want to refine a few more things." (15 Nov) | `docs/design/owner-notes/2026-11-15b-stained-glass-direction.md` | Open (this branch reopens it) |
| 17 | Judge the screens against Hearthstone, Battlegrounds, Galaxy and TFT screenshots. | "comparing screenshots of our game directly with screenshots of Hearthstone, Battlegrounds, Galaxy, TFT, etc." (9 Nov) | `docs/design/sources/2026-11-09f-visual-comparison-and-reference-tribe.md` | Open |
| 18 | Look, feel and moment-to-moment play matter most. | "What is most important to me is the game's look and feel, its moment-to-moment gameplay is good." (14 Nov) | `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md` | Open (a priority) |
| 19 | Players who love flavour are the lowest priority; clever-combo and winning players come first. | "Vorthos is our last priority." (10 Nov) | `docs/design/sources/2026-11-10d-audience.md` | Open |

### Cards and what a card shows

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 20 | A card face shows Attack and Health and nothing else; minimal. Name, rules text, tier badge and tribe emblem are not on the card. | "It can just be attack and health." (15 Nov) | `docs/workstreams/glass-frames.md`; `docs/workstreams/glass-mockups.md` (branch `design/glass-mockups`) | Open |
| 21 | The Attack and Health discs sit slightly differently on each tier; close enough until a human artist redraws them. | "As long as we get it close enough, it'll be fine." (15 Nov) | `docs/workstreams/glass-frames.md` | Open |
| 22 | Keyword marks never cover the art; they go along the bottom border, between Attack and Health. | "I don't want the icons for all of the stuff over the art." (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |
| 23 | Keywords should show on the card the way Battlegrounds shows Taunt or Windfury. Then the drawn keyword looks were refused as too busy; the small marks stay. The later word (21 Nov) holds. | "we need some sort of visual indicator to accomplish the same thing" (20 Nov); "The keyword stuff I don't like. It's too busy." "We'll keep the small marks for now and iterate later." (21 Nov) | `docs/design/mockups/fix-round-20-nov/keywords/NOTES.md`; `docs/workstreams/fix-round-20-nov/PLAN.md` | Open |
| 24 | Cards carry a type line of species and role, printed above the stats. | "I am an owl warrior. I am an owl scholar." (27 Oct); type line above the stats approved with "I accept all the other proposals from that document." (21 Nov) | `docs/design/sources/2026-10-27-battlegrounds-direction.md` §5; `docs/workstreams/fix-round-20-nov/PLAN.md` decision 7 | Open |
| 25 | An activated ability shows its cost as a number in a gold icon, then a colon, then the effect; no "Active" word. | "Colon indicates a cost being paid for an effect, I guess." (19 Nov) | `docs/design/sources/2026-11-19b-tribe-rework-directions.md` | Open |
| 26 | Gold pieces and the Attack and Health discs look too alike; the stat discs may need to change. | "The gold pieces look too similar to the power and toughness areas" (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |
| 27 | Cards you can't afford grey out. | "I like the state where you can't afford stuff, where the stuff grays out." (17 Nov) | same | Open |
| 28 | Duplicates in the shop get a glow or shader. | "We might want a shader effect or maybe a glow" (17 Nov) | same | Open |
| 29 | When a triple is possible, every card that would combine glows; no pips. | "all the cards that would go into the combined unit should just get the shader effect, the glow, and no pips" (17 Nov) | same | Open |
| 30 | A triple also gets a foil shader, because the glow alone is not obvious enough. | "Can we do like a shader that looks like a foiling effect" (18 Nov) | `docs/workstreams/night-18-nov/taste-dupes.md` | Open |
| 31 | Duplicate and triple marks count only cards you own; the faint edge on your own copies stays. | "All other proposals I approve" (21 Nov) | `docs/workstreams/fix-round-20-nov/PLAN.md` decision 4 | Open |
| 32 | Holding Alt over a hand card or a Discover option shows its golden in place. | The owner picked "Golden in place" (18 Nov) | `docs/workstreams/night-18-nov/taste-golden.md` | Open |

### The board and slots

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 33 | The board is 4 in front and 3 behind, the back row offset half a slot. | "Yes, agree on the staggering." (27 Oct); "I want the board to be 4 and 3 if I possibly can get it. If we really can't do it, okay, I'll reevaluate." (14 Nov) | `docs/design/sources/2026-10-27b-board-answers-and-research.md`; `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md` | Open, but a strong wish. The `design-critique` skill calls it fixed; see the report |
| 34 | Your board is centred: left to right when stacked, top to bottom side by side. | "the player's board needs to be centered in the screen" (11 Nov) | `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md` | Open |
| 35 | Your board may move a little between phases. This replaces the 11 Nov rule that it never moves. | "exactly static between phases" (11 Nov); "maybe the board can move a little bit" (14 Nov, later) | `docs/archive/design-lab/journey/HANDOFF.md`; `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md` | Open |
| 36 | Every unit is the same size everywhere: shop, hand and both boards. | "it's going to be the same sized object" (11 Nov) | `docs/archive/design-lab/journey/HANDOFF.md` | Open |
| 37 | The 11 Nov layout rules: Clean Arena's layout as the base, layout B, the board a framed zone, the shop its own zone with its buttons inside, vertical space to the boards. The owner later called them suggestions. | "the closest thing we've got currently to layout perfection" (11 Nov); "Those rules were just things I suggested for improvements." (14 Nov) | `docs/archive/design-lab/journey/HANDOFF.md`; `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md` | Open |
| 38 | Slot buffs are not called rings. An empty buffed slot shows its values where a card's Attack and Health would be, like Galaxy. | "we won't be calling the slot buffs rings"; "I want them to match the positioning of where the power and toughness would be without" (16 Nov) | `docs/workstreams/glass-mockups.md` (branch `design/glass-mockups`) | Open |
| 39 | The leaderboard sits on the right, but may be dropped if it can't be shown well. | "I prefer putting the opponents on the right-hand side of the screen" (11 Nov); "If we need to not render a leaderboard because there's no good way of doing it, I'm okay with that." (14 Nov) | `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md` | Open |
| 40 | No full scoreboard yet. Hovering a player shows one card: name, shop tier, health, your last fight with them and the board you last saw. No tribe icon anywhere on the leaderboard. | "I don't want that full detail stuff yet."; "We don't need to have the icon of the tribe they're playing." (16 Nov) | `docs/workstreams/glass-mockups.md` (branch `design/glass-mockups`) | Open |

### The shop and economy controls

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 41 | Gold is a shiny gold coin, not acorns. | "I don't want the acorns as gold anymore." (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |
| 42 | Shop prices are small tags under the cards, with the number inside the coin. Pedestals were floated too. | "a gold piece that has a number inside of it for costs"; "There's tags in the shop are fine." (17 Nov) | same | Open |
| 43 | Spell prices sit where the mock-up put them, for now. | "where you put the prices for the spells is good"; "Spells might have to change. That's okay." (17 Nov) | same | Open |
| 44 | The tier-up button is too small and its cost needs to read more clearly. | "that button is too small" (17 Nov) | same | Open |
| 45 | A subtle count of refreshes left before the price rises. | "Maybe just like X left until price increase, just subtly above it" (17 Nov) | same | Open |
| 46 | The shop's tier should be more obvious, maybe a shop that visibly upgrades. Shelved. | "Maybe we want to design an entire different kind of, like, diegetic thing for the shop that upgrades as time goes on." (18 Nov) | `docs/design/owner-ideas-log.md` #11 | Open |
| 47 | The tier-up discount is shown as a discount, with the market-stall icon (option A). | "It's a discount." (18 Nov) | `docs/workstreams/night-18-nov/taste-readouts.md` | Open |
| 48 | Shop layout A (two wings), with nothing under the gold, the same gaps on both sides, and next turn's gold as a small "+X" beside the next opponent's portrait. | "So basically option A except with some adjustment"; "next to the top right of the circle down near the profile picture, not on top of it" (21 Nov) | `docs/workstreams/fix-round-20-nov/PLAN.md` decision 6 | Open |
| 49 | The shop may sit higher on the screen. | "Yeah, shop moving up is fine." (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |
| 50 | Shop spells sit in a row above the units, as regular hexagons exactly a unit's width. | "they should inherit the width from the normal cards, but the height of a regular hexagon" (15 Nov) | `docs/workstreams/glass-mockups.md` (branch `design/glass-mockups`) | Unsure: spells are hexagons, but not the tall stretched unit hexagon the fixed rule names |
| 51 | Cards are 250 px tall at 1920 × 1080, with spells above the shop. | "I like this image, if that answers the question." (16 Nov) | same | Open |
| 52 | Double-clicking a shop unit or spell buys it into the hand. | "when you double click a unit in the shop, I want it to buy and go to your hand."; "Yes, spells too" (18 Nov) | `docs/workstreams/night-18-nov/taste-double-click.md` | Open |
| 53 | You can buy a unit straight onto an empty slot, even with a full hand. | Asked for on 20 Nov; settled with "All other proposals I approve" (21 Nov) | `docs/workstreams/fix-round-20-nov/PLAN.md` decision 2; rulebook 4.2.2 | Open (a rule; see table 3) |

### The hand

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 54 | The hand holds 7, and the owner will change hand size to fit what the screen shows well. | "I'm willing to move on hand size" (14 Nov); "I think 7's a good fit." (16 Nov) | `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md`; rulebook 7.1.1 | Open |
| 55 | The hand is not shown in the fight. | "I don't think your hand is needed for combat" (14 Nov) | `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md` | Open |
| 56 | Cards gained with a full hand wait in a pile with a small indicator, with no limit. | "queue … little indicator" (20 Nov, as recorded); settled 21 Nov | `docs/workstreams/fix-round-20-nov/interrogation.md`; `PLAN.md` decision 1 | Open |
| 57 | Dropping a hand card on a board unit swaps them. | Asked for on 20 Nov; settled 21 Nov | `docs/workstreams/fix-round-20-nov/PLAN.md` decision 2 | Open (a rule; see table 3) |
| 58 | A unit whose Recruit Phase economy you use must commit to the board for the fight, or be sold. How is left to agents. | "If you use the economy effect, it's on your board for the fight, or you have to sell it." (18 Nov) | `docs/workstreams/night-18-nov/rules-c15-plan.md` | Open |

### The fight and its pacing

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 59 | Attack timing may change and vary a little, but not wildly; feel matters more than a number. | "we need to make sure we don't have wildly disparate stuff"; "I'm more worried about feel than a specific timing" (18 Nov) | `docs/design/owner-notes/2026-11-18b-fight-timing-and-grouping.md` | Open |
| 60 | Repeated animations are grouped into one quick version with a ×N combo count. | "I just want smart ways of grouping the animations, essentially." (18 Nov) | same; first logged in `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` (17 Nov) | Open |
| 61 | Fight animations are held against Battlegrounds, Galaxy and other card games (Marvel Snap, Arena). | "Just 4 or 5 examples so we can learn the best practices and create something of high quality." (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |
| 62 | Fights skip with a Skip button or Space; clicks elsewhere and Enter don't skip. | "Space only" (21 Nov) | `docs/workstreams/fix-round-20-nov/PLAN.md` decision 3 | Open |
| 63 | No end-of-fight effects: they pay at the start of your turn, where they can be animated. | "we don't get to show an animation for an end-of-fight effect" (20 Nov) | `docs/workstreams/fix-round-20-nov/design/start-of-turn.md` | Open |
| 64 | A prototype animation for every action, all accepted, built in batches the owner plays between. | "prototype for every single one" (20 Nov); "I accept all changes" (21 Nov) | `docs/workstreams/fix-round-20-nov/interrogation.md`; `PLAN.md` decision 13 | Open |

### Tooltips, keywords and wording

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 65 | In-game text is short and plain; keywords save sentences; edge cases go to a second layer or stay implied. | "far too long, far too wordy" (8 Nov, of build 6's text; the full message is not in the repo) | `.claude/skills/ux-copy/SKILL.md` | Open |
| 66 | Each separate effect goes on its own line, with common sense. | "where we would have a full stop probably should be a command return afterwards"; "don't over apply a rule if it doesn't make sense" (18 Nov) | `docs/design/owner-notes/2026-11-18b-one-effect-per-line.md` | Open |
| 67 | Keywords are coloured, with an icon, the word and a number, in place of long sentences. | "That's the purpose of a keyword." (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |
| 68 | Reminder text moves to its own tooltip; holding Alt freezes the tooltip so the player can hover a keyword for its explanation. The mock-up was approved. | "like a modifier key that gives them the advanced tooltips"; "You've nailed it." (17 Nov) | same | Open |
| 69 | The agents' keyword colours are fine. | "Calls you made without me on the keyword colors are fine." (17 Nov) | same | Open |
| 70 | Tooltips have higher contrast. | "I would like the tooltips to maybe have a bit more high contrast" (16 Nov) | `docs/workstreams/glass-mockups.md` (branch `design/glass-mockups`) | Open |
| 71 | Where hover details appear. 14 Nov: details follow the cursor, no fixed panel (recorded by an agent; no words in the repo). 21 Nov: keyword boxes go in a fixed place, the left light (option 1). The later one holds for keyword boxes. | "I think I like the option one." (21 Nov) | `docs/workstreams/glass-mockups.md` (branch `design/glass-mockups`); `docs/workstreams/fix-round-20-nov/PLAN.md` decision 8 | Open |
| 72 | The names of Attack and Health are not settled. | "I'm going to constantly refer them interchangeably, so until we've got it nailed down." (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |

### Screen flow and menus

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 73 | A card browser, with units and spells, that opens during a game as well as from the menu. The mock-up was approved. | "It needs to be visible in game, so the player can use it in game, not just from the menu."; "It does need to include spells, though." (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |
| 74 | A settings cog. | "we need a settings button in general ... Just a cog." (17 Nov) | `docs/ideation-track-2/HANDOVER.md` | Open |
| 75 | Mute and a volume slider in the pause menu. | "Put the mute in the pause menu on a volume slider as well" (21 Nov) | `docs/workstreams/sound-engine/PLAN.md` | Open |
| 76 | Tips on loading or transition screens: backlog, unresolved. | "actually just backlog that" (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |

### Teaching and clutter

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 77 | The game screen assumes a player who knows the rules; teaching is the tutorial's job. | "The job of a tutorial is to tutorialize." (9 Nov) | `docs/design/sources/2026-11-09e-ui-clutter-and-tutorials.md` | Open |
| 78 | Fewer reminders and static pointers; animation shows how the game plays. | "We need to have fewer reminders, fewer static images that indicate where things are."; "Animations should, by player feel, capture how a game is and how it plays." (9 Nov) | same | Open |
| 79 | Depth without complexity: keep decisions meaningful and cut what they don't need. | "eliminating everything that isn't needed for that decision to have the same weight" (8 Nov) | `docs/design/sources/2026-11-08b-taste-answers.md` §1 | Open |

### Platforms, window and input

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 80 | Two layouts were in view, stacked and side by side ("the book version"). The platform is not decided. | "vertically centered in the horizontal mode, the book version" (11 Nov) | `docs/design/sources/2026-11-14-layout-rules-were-suggestions.md` | Open |
| 81 | Picking up and moving cards should feel visceral, like Galaxy, but with less bounce and tilt than the first try. | "moving them around doesn't feel visceral"; "It tilts a bit too much" (17 Nov) | `docs/ideation-track-2/HANDOVER.md` | Open |
| 82 | A setting for whether a carried card drops by the pointer or by the card's middle. Which mode stays is open. | "whether the card's calculated from the position of the center of the card or the position of the cursor" (17 Nov) | `docs/ideation-track-2/HANDOVER.md` | Open |

Double-click buying (52), the Alt tooltip (68) and the Space skip (62) are input decisions too.

### Sound and motion

| # | The decision | The owner's words and date | Source | Fixed or open |
|---|---|---|---|---|
| 83 | Fight hits: ladders 3 to 5 are good, ladder 4 is the favourite. | No words in the repo; the owner's "Round 2 feedback" (about 21 Nov) | `docs/workstreams/sound/audio-spec.md` §3 | Open |
| 84 | The triple animation is held against triple and level-up animations in The Bazaar, TFT and Battlegrounds. | "It's building the same sense of excitement." (17 Nov) | `docs/design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md` | Open |

Motion also appears in rows 59 to 64 (fights), 78 (animation in place of reminders) and 81 (dragging).

## 2. Today's choices made by agents

These are in the build or the mock-ups and are easy to mistake for owner rules. None is the owner's. Most are listed in `docs/ideation-track-2/README.md` under "Calls agents made without the owner"; some have changed on `dev` since, so check the build.

| # | The choice | Where it is recorded |
|---|---|---|
| A1 | The screen as one window of three lights in dark stone, not glass pieces over a woodland. The art README lists the window architecture as open. | `docs/design/art-direction/README.md` |
| A2 | How tier shows beyond colour: a number lozenge, a count of panes down each side, a jewel and glow on tiers 5 and 6. | `docs/design/art-direction/README.md` |
| A3 | Where the hand, your hero and End turn sit; in the fight, the opponent's board in the shop's light, their hero top right, their slots read left to right. | `docs/workstreams/glass-mockups.md` (branch `design/glass-mockups`); `.claude/skills/design-critique/SKILL.md` lists hand, hero and End turn as open |
| A4 | The leaderboard is a slim strip, hidden until Tab or a click on the player's corner. | `docs/ideation-track-2/README.md` |
| A5 | Buying by dragging, and a shop unit dropped on an empty slot buys and plays in one move. (Double-click buying is the owner's, row 52.) | same |
| A6 | Counters by the portrait as named plates ("Compost 4"), not emblem chips. | same |
| A7 | Stand-in looks with no glass mock-up: frozen, golden, keyword and counter pills, the message line, the Discover picker, the start, result and pause screens. | same |
| A8 | The result screen leaves after 2.5 s; a "You" label on the start screen; a seed line on the pause panel. | same |
| A9 | The cog top left opens the pause panel; the setting reads "Cards drop by: Pointer / Card middle"; Pointer is the default. | same |
| A10 | The drag carry's numbers (lift, lean, swing, landing hop). | same |
| A11 | Order and Bury buttons sit over the art; the strip under the board was taken out. The owner has not said where they go. | `docs/workstreams/night-18-nov/morning-pack.md` |
| A12 | The duplicate glow's slow "breath"; the brisk triple (1.80 s). | same |
| A13 | The start screen keeps its tribe picker with Cards between Play and Quit; the browser opens during recruit, not in fights. | same |
| A14 | The lock on economy units is a general rule on worked units, not a keyword (a prototype). | `docs/workstreams/night-18-nov/rules-c15-plan.md` |
| A15 | Spells keep a cream cost disc in the hand; only shop prices use the gold coin. | `docs/workstreams/night-18-nov/README.md` |
| A16 | The game is drawn at 1920 × 1080 and scaled to the window. | `docs/ideation-track-2/README.md` |
| A17 | The fight's lunge, damage splashes and red Health were stand-ins in the mock-up; fight animation was never designed by the owner. | `docs/workstreams/glass-mockups.md` (branch `design/glass-mockups`) |

## 3. Rules a UI concept could bump into

From `docs/design/rulebook.md` (v0.10). These are rules of the game, not screen choices. A concept that needs one changed names it as a rules change.

| # | The rule | Rulebook | Notes |
|---|---|---|---|
| R1 | The board has 7 slots, front F1–F4 and back B1–B3, the back row offset half a slot. | 8.1.1–8.1.3 | 4 and 3 is the working cap; the owner may change it (8.1.2) |
| R2 | Gaps are allowed and units never slide to fill one. | 8.3.1, 8.3.4 | |
| R3 | Moving and swapping units on the board is free during recruit. | 8.3.3 | PROPOSED |
| R4 | The hand holds 7; cards gained with a full hand wait in an unlimited pile that carries over. | 7.1.1, 7.1.2 | |
| R5 | Units move freely between hand and board during recruit; a lone return needs a free hand place. | 7.2.4, 7.2.5 | The owner, 17 Nov: "Units could move freely between the hand and the board, unlike in Battlegrounds." |
| R6 | Playing onto an occupied slot swaps; with a full board, playing needs a swap. | 7.2.1, 7.2.2 | |
| R7 | A unit can be bought into the hand or straight onto an empty slot; with a full hand, only onto a slot. | 4.2.1, 4.2.2 | |
| R8 | Units sell from the hand or the board, for the same value (half the tier, rounded up; tokens 0). | 4.3.7, 4.3.3 | The owner, 17 Nov: "you could sell from either the hand or the board" |
| R9 | Recruit effects fire when a unit is gained, not when it is played. | 7.2.3, 7.2.6 | |
| R10 | Three copies combine at once into a golden in the hand, and the Triple Reward comes when the triple forms. A triple pulls even a locked unit off the board. | 7.3.1, 7.3.6 | The owner, 18 Nov: "the rule that triples take place is a more important rule" (`docs/workstreams/night-18-nov/taste-c15.md`) |
| R11 | The shop shows 5 units and 2 spells at every tier. | 6.1.1 | Settled 12–13 Nov; replaces the 8 Nov "shop size is very flexible" |
| R12 | Refreshes cost 1 for the first 10 a turn, then 1 more every 5; the count resets each turn. | 4.4.2–4.4.4 | |
| R13 | Freezing is free, up to 5 toggles a turn. | 4.5.1 | BG |
| R14 | Tier-up has a base cost per tier and a discount that grows each turn you wait. | 4.6.2–4.6.4 | |
| R15 | Unspent gold carries over, with no cap. | 4.1.2 | |
| R16 | No turn timer. | 2.1.4, 3.1.2 | The owner, 2 Nov: "No turn timer at all." |
| R17 | A game is 8 players: you and 7 recorded runs, one opponent each round. | 2.1.1 | The build still has a shared pool and bots (`docs/STATUS.md`) |
| R18 | Front row attacks first, left to right, then the back row; the back row can't be attacked while a front unit lives. | 9.4.2, 9.5.1 | |
| R19 | The fight runs with no player decisions. | 9.1.3 | |
| R20 | Hero powers: the rulebook keeps Battlegrounds' (2.2.7), but the build has none. | 2.2.7 | The owner, 16 Nov, for the build: "I think no hero powers." (`docs/workstreams/ideation-track-2.md`) |

## 24 Nov 2026: the look

The owner rejected every card frame from the frame pass ("All of these frames feel bad") and asked for whole looks to react to (`briefs/30-look-pass.md` holds the words). After seeing three (`looks/`), the owner chose L1, "the card is a window" (`looks/L1/look.md`):

| # | Decision | The owner's words |
|---|---|---|
| L1 | L1 is the base look. | "I agree with you that L1 is the best." |
| L2 | Cards, not figures, on the board. | "Cards are staying on the board." |
| L3 | No tier mark on a board card; tier shows on hover. | "Tier on the board on hover only, agreed." |
| L4 | Tier 5 is orange, not yellow. | "The tier 5 orange, agreed." |
| L5 | The shop's tier light is calmer than in the paintings. | "It can be pretty subtle ... maybe even the red should be a little bit less: a bit more than what our tier four is, and a bit less than what our tier five is, in terms of lighting strength. And the scale should start at the same point from tier one." |
| L6 | Card art gets calmer backgrounds, with a colour guide per tribe. | "We need less bright backgrounds. Maybe not as washed out as this, but definitely we need to set guidelines for background colours that are allowed per tribe, and I'd like a full colour palette guideline thing made up ... Maybe not too plain." |
| L7 | The board stays two rows, four over three. | "I still think that the board having the 4-3, the two rows, is important to me." |
| L8 | The card's points take a regular hexagon's angles; its height and ratio are open. | "I'm willing to sacrifice card height, and I would like to keep the card's angles at exactly the shape of a regular hexagon for the top part ... We could even actually go to less than a regular hexagon, I suppose." |
| L9 | A little depth is wanted; how is open. | "Giving a bit more of a 3D feel ... almost like two-and-a-half-D ... Surprise me, I guess." |
| L10 | Cards in the hand are the same size as on the board. The hand may be cut off by the bottom of the screen, and a card rises when pointed at. Restates row 36. | "For me it's a non-negotiable that the cards are the same size in the hand, because you need to be able to drag them around ... I'd rather have the hand trim off the bottom of the screen and the bottom half of the card not be visible. And hovering over the card pops it out vertically." (later the same day; the owner added "maybe it's not a non-negotiable" and "I'm very torn") |
| L11 | The card's ratio may change from 0.56. | "I don't mind the aspect ratio change." |
| L12 | One spell either side of the shop's units, so the unit cards stay centred. Replaces rows 50 and 51 (spells in a row above the units as unit-width hexagons). | "How about we put one spell either side then? That would at least keep the cards centred. I think that's better." |
| L13 | The shop's buttons (refresh, freeze, tier up) go up by the shop, on its right-hand side; gold maybe not. | "The controls for at least re-rolling and freezing and [tiering] up the shop, maybe not the player's gold, should go up there ... I want the buttons for the shop on the right-hand side of the shop rather than the left." |
| L14 | The scoreboard may move to the left. Open; it would replace row 39 (leaderboard on the right). | "So I'd like to swap the scoreboard to the left-hand side, maybe. I don't know how you feel about that." |
| L15 | The screen must still give access to the card library and the player's compost. | "The player still needs the ability to access the card library, their compost on the left, maybe some other things." |
| L16 | The cast shadows and thrown colour under the cards did not read, and a board card drawn raised and larger read as a mistake. | "There's some weird sort of shadowing effect underneath the cards. You've made these hexagon shadows underneath them. I don't quite understand what those are supposed to be." |
| L17 | This screen is the direction; make a fully polished version. | "Let's say that this is where we want to go. Let's try and take this to a next level. Take a fully polished version, I guess, with some of those changes." |
| L18 | Counters are general slots, not a Tide or a Compost button: any tribe's mechanic can sit in one, perhaps up to four, with a way to view all your auras. | "Tide is not always going to be a mechanic. We just need some way of handling any number of other mechanics, like whatever your most important counter is determined to be ... You just need a way of being able to view all your auras, so it shouldn't be like a tide button. It's more of a generalized thing. Same for compost: it's a mechanic that may only be in some lobbies ... having maybe up to four of them or something, I'm not sure." (24 Nov, later) |
| L19 | The swap of L14 means the whole side panes, not only the scoreboard and the buttons. | "I kind of meant swapping the entire panes rather than just the leaderboard and the buttons, I guess." |
| L20 | For layout work, assume one spell in the shop. | "Let's assume I'm changing the rules of the game. There's only one spell in the shop." |
| L21 | The polished screen's look is good; the owner wants to move the pieces by hand to show layouts. A whiteboard of the pieces: https://claude.ai/artifact/VB3h4u57FV7gocf4wWoBY7 (which board element is which piece: `/data/ui-ideation/looks/L1/parts/board-map.json`). | "Fidelity-wise, the visual appearance is good. I just want to have a bit more layout control and granular ability to illustrate things without just describing it with words." |
| L22 | The whiteboard was rejected. The owner wants a wireframe with every zone named, to talk about which elements go in which zone: `looks/L1/zones.html` (picture: `/data/ui-ideation/looks/L1/zones/zones.png`). Zone names: Left column and Right column (each top, middle, bottom); Shop (Shop 1 to 5, Shop left wing, Shop right wing); Board (Front 1 to 4, Back 1 to 3, Table left, Table right); Hand (Hand 1 to 7). | "The whiteboard is not it. Don't like the UI of it ... Could you maybe give me just a wireframe with the zones labelled? ... I just want labels for each of these zones, so I can refer [to] them with words, and I can talk about what elements I like in which zones, and then figure out how to lay them out within there." |
| L23 | The hand, the board and the empty table either side of the board are settled for now; the table sides are kept for art. To try: two spells in the shop's left wing, the shop's three buttons in its right wing, the left column the scoreboard alone, the right column gold, portrait, counters, settings and End turn. Drawn as `screen.html?view=polish&layout=b` (`/data/ui-ideation/looks/L1/polish/layout-b.png`). | "I'm very happy with the hand and board as they are. And I like table right and table left as negative space, at least for now ... I think we should use those to be able to display art." "In my head, [the three buttons] should go maybe in the shop right wing, and there should be maybe two spells in the shop left wing. And then the right column should be the player's gold, the player's portrait, and maybe a bunch of counters ... settings and stuff ... go to next turn button ... the left column is pretty much just scoreboard." |

These are choices among mock-ups on `ideation/ui-ux`. Nothing here is in the game, and the earlier frame recipe (mostly lead, glass in the lower third) is dropped.
