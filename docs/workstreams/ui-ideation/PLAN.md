# Plan: UI and UX ideation

Written by the orchestrator of `ideation/ui-ux` (an agent) on 21 Nov 2026. Everything here is the orchestrator's proposal except the quoted owner's words. Not approved by the owner yet.

## The problem, in the owner's words

> "I'd like to start a new ideation branch where agents focus on improving our UI and UX in the same method and process that I've gone through there."

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

The method ("there" is the owner's P(Doom)1 UI work), in the owner's words from that work:

> "we need to start the UI from first principles. What needs to be shown? What is most important"

> "I think you need to offer more variety in designs. Use different styles and different layouts. Have the council pick which ones are the best."

> "I just meant don't do the designs yourself"

> "I would say the final check for the council should be that they are presented with the full gallery of all of the images of other UIs that we found. Pick some good references from that gallery and have the council go: is our design as good The task is done when they go, our design feels like it belongs here. It's one of the better ones here, or it's at least the average kind of level"

## Done so far

| Step | Result |
|---|---|
| Map today's game from the live build | `map/map.md`, `map/state.md` (turn 9, full board, the fight that follows), `map/critique.md`; 53 screenshots in `/data/ui-ideation/baseline/shots/` |
| Reference gallery | 17 games, 79 real screenshots, in `/data/ui-ideation/gallery/` (`index.md`, `gallery.html`, two contact sheets) |
| The owner's earlier decisions about screens | `owner-decisions.md`: 84 decisions (3 fixed, 71 open, 10 unsure), 17 agent choices, 20 rules |

## The focus: two player outcomes

Taken from the map's critique of the live game. Every concept is judged on these two and nothing else, besides holding the three fixed things and being free of visual defects.

1. **"I can read the shop and my board mid-game without opening each card."** Today a card face shows art, Attack, Health and small marks. With five offers and seven units, a mid-game shop costs up to 12 hovers, and again after each refresh. Cards fill about 650 px of a 1400 px pane.
2. **"I know who I'm up against, and after a fight I know why I won or lost."** Today the lobby is behind an unlabelled click on your own portrait, and a lost fight ends with one number.

Screens this puts in play: recruit (most of the work) and the fight with its end. Start, result, pause, the card browser and the compost panel are not redrawn in this run.

Outcome 1 runs into an owner decision: a card face shows "just ... attack and health" (15 Nov, row 20), and keyword looks on cards were "too busy" (21 Nov, row 23). The outcome is the player's, not a fix: a concept may meet it with words on the card and name the rows it reverses, or by another route (bigger cards, a fixed reading pane, a read-all view). The six directions below are split between both routes on purpose.

## Step 1. Six designers, in parallel

Each makes one concept in an assigned direction and commits to it fully. None is shown another's work. Models: two each of Claude Opus, GPT Sol and Gemini Neon, all at high effort. The orchestrator does not design.

| | Direction (the orchestrator's assignment, to give variety) | Model |
|---|---|---|
| A | **The great window, refit.** Today's architecture kept: one window of lights in stone, shop over board. Cards much larger, the empty side lights put to work (lobby, hand, counters), card faces kept minimal as the owner chose, with a fixed reading pane for the card under the pointer. The concept that reverses the fewest decisions. | Sol |
| B | **Honeycomb.** The whole screen is one leaded lattice of tall hexagon cells that fit together; board, shop and hand are neighbouring clusters of cells, and adjacency shows who stands in front of whom. | Neon |
| C | **Rose window.** A radial screen: the board in the centre rose, the shop and hand as arcs of petals, the eight players as roundels on the rim, always in view. | Neon |
| D | **The glazier's bench.** Diegetic: a workbench in a woodland workshop. The shop is glass laid out for sale, the board is the panel being leaded, gold is coin on the bench, and the fight is your finished panel raised to the light against another's. | Opus |
| E | **Glass in the forest.** No great window: a woodland scene in glass fills the screen and the cards stand or hang in it as lit panels and lanterns. As little frame and chrome as the decisions allow. | Opus |
| F | **The reading card.** Information first: each card carries a name and type line and its keywords in words, set in its lead; your board faces the next opponent's last known board all through recruit; the lobby is always open; the fight has a readable account of what happened. Reverses the minimal card face on purpose. | Sol |

Every designer gets: the owner's second quote, unchanged; the three fixed things; the two outcomes; `map/` and the baseline screenshots; `owner-decisions.md`; the gallery; the `game-ui-design` skill; and the list of reusable art (cards, frames, portraits, textures, fonts). The brief says plainly that the board's 4 and 3, the zones and every other layout rule in the project's skills are today's choices on this branch.

Each delivers, in `concepts/<letter>/`:
- `concept.html`, 1920x1080, with four views of the same game the baseline shows: recruit at turn 9 (the returning player's view), recruit at turn 1 with at most one tutorial cue (the first-session view), the turn-9 fight with both full boards, and the end of that fight.
- Renders of each view (in `/data/ui-ideation/concepts/<letter>/`, not in Git).
- `notes.md`: the concept in two sentences; the glance-tier count against today's 23 (recruit) and 9 (fight); how it meets each outcome; each owner decision it reverses, by row number; any rules or flow change it suggests, labelled as a suggestion for the owner; its weakest point.
- A visual quality pass before finishing: consistent alignment inside each group, every icon matches its action or is left out, text a player acts on at least 18 px and other text at least 14 px, no overlap, overflow or clipping, contrast at least 4.5:1 for text, no large dead areas.
- A disk report.

Art: existing card art, frames, portraits and textures, plus glass and lead drawn in SVG or CSS. No new generated pictures in this round, so the six can be compared on layout and on how the glass carries the screen.

## Step 2. The council picks

Three new delegates: Claude Opus, GPT Sol, Gemini Neon, at high effort, per the owner's `council` skill (low sensitivity). They see the six concepts and today's screens side by side. Each member:
1. Lists visual defects in every concept (the quality-pass list above), with view and place.
2. Scores every concept, and today's game, out of 10 on each of the two outcomes, and says pass or fail on the three fixed things.
3. Ranks all six, names the best two or three, and gives each of those a numbered fix list.

Then the skill's process: members see each other's findings word for word and agree one ranking and one fix list per shortlisted concept. The orchestrator relays through files and takes no side.

From stills, motion, timing, hover feel and sound are "not judged", by every designer and member.

## Step 3. Fixes

Each shortlisted concept's agreed fix list goes back to the same designer. The council re-checks (Opus and Sol first, Neon once both pass). At most two fix rounds; then the orchestrator reports what remains.

## Step 4. The gallery check

The shortlisted concepts' renders are mixed into the gallery beside today's game. Each member picks the references that are the right comparison for each concept, says why, and answers: does it belong among them: one of the better ones, about average, or below?

The run is done when the members agree that at least one concept "feels like it belongs here" at average or better. If none does after two more fix rounds, the orchestrator tells the owner what stands in the way.

## Step 5. Show the owner

One page in the owner's house style: the shortlisted concepts beside today's game and the chosen references; each member's verdict per round; what each concept changes; the owner decisions each would reverse; what was not judged. The owner's reactions are directions. Building anything in Godot comes after that and is the owner's call.

## What the owner is asked

One question, which does not block the designers:

- **How much of the card itself is fixed?** Ten rows in `owner-decisions.md` are unsure: the tier colours and frame ladder, the 0.56 outline, the slightly-off roof angle, how fighters are drawn, the art recipe, spells as regular hexagons. Proposed: designers keep today's card frames and art exactly as they are, and what is shown on and around a card (stats, marks, names, text) is open.

## Rules for the run

- Nothing from this branch enters `main` or `dev` without the owner's say-so for that merge. No game code changes in this plan.
- The orchestrator runs the designers and the council itself, without a child orchestrator, and neither designs nor reviews. Reason: a child would be Opus, and the owner chose a Fable orchestrator for this run. Relays go through files so they stay word for word.
- If a model is at capacity: one retry later, then report it. Never another model in its place.
- Other studios' screenshots and all renders stay under `/data/ui-ideation/`, never in Git. Every worker reports its disk use; the orchestrator deletes leftovers.

## Size

Six designers, three council members, and the same nine again for fixes and re-checks: nine agents in all, each used for two to five turns.
