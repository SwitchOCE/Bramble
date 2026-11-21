# Plan: UI and UX ideation

Written by the orchestrator of `ideation/ui-ux` (an agent) on 21 Nov 2026, and changed the same day after a fresh agent interrogated it (`interrogation.md`). Everything here is the orchestrator's proposal except the quoted owner's words. The owner has not approved it; three questions for the owner are at the end, each with a default the run uses until the owner answers.

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
| This plan, interrogated by a fresh agent | `interrogation.md` |

## What every concept is judged on

Two things, besides holding the three fixed things and being free of visual defects.

1. **The look: it belongs among games players love.** This is the owner's own done line (the gallery check), and the owner's stated priority: "What is most important to me is the game's look and feel" (14 Nov). It is scored from the first council round, so a concept is never cut before anyone asks whether it looks good.
2. **Reading the game at a glance: "I can read the shop, my board and who I'm up against mid-game without opening each card."** From the map of the live game: a card face shows art, Attack, Health and small marks, so a mid-game shop costs up to 12 hovers, and again after each refresh; cards fill about 650 px of a 1400 px pane; the other players are behind an unlabelled click.

The second runs into owner decisions: a card face shows "just ... attack and health" (15 Nov, row 20), keyword looks on cards were "too busy" (21 Nov, row 23), and "I don't want that full detail stuff yet" on the leaderboard (16 Nov, row 40). So it is stated as the player's outcome, not as a fix. A concept may put more on a card and name the rows it reverses, or keep the face minimal and solve reading another way; the council judges whether the result is busy.

Each concept also draws the fight and its end, including how the player learns why they lost. The council comments on that; it is not a third score.

Screens in play: recruit (most of the work) and the fight with its end. Start, result, pause, the card browser and the compost panel are not redrawn in this run, and the final page says so.

## Step 1. Six designers, in parallel

Each makes one concept in an assigned direction and commits to it fully. None is shown another's work. Models: two each of Claude Opus, GPT Sol and Gemini Neon, all at high effort. The orchestrator does not design.

| | Direction (the orchestrator's assignment, to give variety) | Model |
|---|---|---|
| A | **The great window, refit.** Today's architecture kept: one window of lights in stone, shop over board. Cards much larger, the empty side lights put to work, card faces kept minimal as the owner chose, with a fixed reading pane for the card under the pointer. The control: the concept that reverses the fewest decisions. | Sol |
| B | **Honeycomb.** The whole screen is one leaded lattice of tall hexagon cells that fit together; board, shop and hand are neighbouring clusters of cells. If the board's shape changes, that is labelled a rules suggestion. | Neon |
| C | **Rose window.** A radial screen: the board in the centre rose, the shop and hand as arcs of petals, the eight players as roundels on the rim. A radial board is labelled a rules suggestion. | Neon |
| D | **The glazier's bench.** Diegetic: the glazier's table in a woodland workshop, where everything on screen is itself glass, lead and light (the table is a light table; coins, tools and controls are glass and lead pieces). The shop is glass laid out for sale, the board is the panel being leaded, and the fight is your finished panel raised to the light against another's. | Opus |
| E | **Glass in the forest.** No great window: a woodland scene in glass fills the screen and the cards stand or hang in it as lit panels and lanterns. As little frame and chrome as the decisions allow. | Opus |
| F | **The reading book.** Information first, in a side-by-side layout (the "book version" the owner once had in view, row 80): your side on one page, the shop and the opponent on the other. Each card carries a name and type line, and keywords in words, set in lead; the next opponent's last known board is in view through recruit; the fight has a readable account of what happened. Reverses the minimal card face on purpose. | Sol |

Every designer gets: the owner's second quote, unchanged; the three fixed things; the two things concepts are judged on; `map/state.md`, `map/map.md` and the baseline screenshots; the gallery; the `game-ui-design` skill; and the list of reusable art. They do not get `map/critique.md`: its "Fix" column would pull all six toward the same answers. They read `owner-decisions.md` only after their first full draft, to name the rows they reverse. The brief says plainly that the board's 4 and 3, the zones and every other layout rule in the project's skills are today's choices on this branch.

Each delivers, in `concepts/<letter>/`:
- `concept.html`, 1920x1080, with four views of the same game the baseline shows: recruit at turn 9 (the returning player's view), recruit at turn 1 with at most one tutorial cue (the first-session view), the turn-9 fight with both full boards, and the end of that fight.
- Renders of each view (in `/data/ui-ideation/concepts/<letter>/`, not in Git).
- `notes.md`: the concept in two sentences; the glance-tier count against today's 23 (recruit) and 9 (fight); how it meets each of the two; each owner decision it reverses, by row number; every other thing it suggests, including any rules or flow change, labelled as a suggestion for the owner; its weakest point.
- A visual quality pass before finishing: consistent alignment inside each group, every icon matches its action or is left out, text a player acts on at least 18 px and other text at least 14 px, no overlap, overflow or clipping, contrast at least 4.5:1 for text, no large dead areas.
- A disk report.

Art: today's card art, frames, portraits and textures, the woodland pieces from the 15 Nov mock-up, and glass and lead drawn in SVG or CSS. A concept whose direction needs a scene may have one new background picture, made by a Codex worker with its image tool as the `bramble-art` skill says, with the chosen glass concept as style reference.

## Step 2. The council picks

Three new delegates: Claude Opus, GPT Sol, Gemini Neon, at high effort, per the owner's `council` skill (low sensitivity). They see the six concepts, today's screens and the gallery. Each member:
1. Lists visual defects in every concept, with view and place.
2. Scores every concept, and today's game, out of 10 on each of the two things above, says pass or fail on the three fixed things, and comments on the fight and its end.
3. Ranks all six, names the best two or three, and gives each of those a numbered fix list.

Then the skill's process, capped: members see each other's findings word for word in one discussion round, then one vote; the majority holds. The orchestrator relays through files and takes no side.

From stills, motion, timing, hover feel and sound are "not judged", by every designer and member.

**The owner gets a first look here**: a contact sheet of all six concepts, the council's ranking and each concept's suggestions in a line. It does not block the fixes.

## Step 3. Fixes

Each shortlisted concept's agreed fix list goes back to the same designer. The council re-checks (Opus and Sol first, Neon once both pass). At most two fix rounds; then the orchestrator reports what remains.

## Step 4. The gallery check

The shortlisted concepts' renders are mixed into the gallery beside today's game. Each member picks the references that are the right comparison for each concept, says why, and answers: does it belong among them: one of the better ones, about average, or below? And does it place above today's game?

The run is done when the members agree that at least one concept "feels like it belongs here" at average or better, and say plainly whether it beats today's game. After a first failed check the owner gets one line on what stands in the way; then at most two more fix rounds.

## Step 5. Show the owner

One page in the owner's house style: the shortlisted concepts in full beside today's game and the chosen references; the other concepts in a line each with a picture; every suggestion any concept made; each member's verdict per round; the owner decisions each concept would reverse; which screens were not redrawn; what was not judged. The owner's reactions are directions. Building anything in Godot comes after that and is the owner's call.

## Questions for the owner

None blocks the designers. Each has a default the run uses until the owner says otherwise.

1. **What every concept is judged on.** Default: the look, and reading the game at a glance (above). The interrogation's alternative reading was to score "why I lost the fight" in place of one of them.
2. **How much of the card is fixed.** Ten rows in `owner-decisions.md` are unsure (tier colours, the frame ladder, the 0.56 outline, how fighters are drawn, spells as regular hexagons). Default: the tall hexagon in lead and today's card art and tier frames are kept as the base; what is shown on and around a card (stats, marks, a name set in lead, text) is open.
3. **New art.** Default: one new background picture for a concept whose direction needs a scene, none otherwise.

## Rules for the run

- Nothing from this branch enters `main` or `dev` without the owner's say-so for that merge. No game code changes in this plan.
- The orchestrator runs the designers and the council itself, without a child orchestrator, and neither designs nor reviews. Relays go through files so they stay word for word.
- While any worker runs, the approval watch runs (`timeout 7100 t3-approval-watch.py`), started again whenever it ends. The owner hears at once if a worker waits on an approval, a model is unavailable, or the council cannot agree after its vote.
- If a model is at capacity: one retry later, then report it. Never another model in its place.
- Other studios' screenshots and all renders stay under `/data/ui-ideation/`, never in Git. Every worker reports its disk use; the orchestrator deletes leftovers.

## Size

Nine agents: six designers and three council members. At most, a designer takes 5 turns (the concept and four fix rounds) and a council member about 10 (the first round, a discussion, a vote, re-checks and gallery checks). One or two short Codex art workers if D or E asks for a background.
