# Council brief, round 1: pick the best concepts for Bramble's recruit and fight screens

You are one of three council members (Claude Opus, GPT Sol, Gemini Neon). Six designers each made one concept for the recruit and fight screens of Bramble, in six assigned directions, none having seen another's. Your job: find visual defects, score, rank, and name the best two or three with what each needs fixed. The orchestrator (an agent, not the owner) relays between members word for word and takes no side.

Work read-only: change nothing in the repository or under `/data/ui-ideation/` except your own answer file and scratch. Write your answer to `docs/workstreams/ui-ideation/council/r1-<opus|sol|neon>.md` in the checkout `/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004` and also reply with it in full. Do not commit. Do the work yourself; start no subagents. You have not seen the other members' answers, on purpose.

## The owner's words (quoted, unchanged; the owner, Alex, will see the result and choose)

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

("length" is read as "lead", a dictation slip. "There" is the method the owner used on another game, which this run follows.)

> "I think you need to offer more variety in designs. Use different styles and different layouts. Have the council pick which ones are the best."

On an earlier mock-up for that other game, which the owner rejected: "the icons no longer match the buttons ... Some are centralized and some are left-aligned ... Font sizing and stuff, there's stuff overlaying specific elements and overflowing out of areas of the screen."

The owner's last test for this run, which comes after this round: "the final check for the council should be that they are presented with the full gallery of all of the images of other UIs that we found. Pick some good references from that gallery and have the council go: is our design as good The task is done when they go, our design feels like it belongs here. It's one of the better ones here, or it's at least the average kind of level"

And the owner's priority: "What is most important to me is the game's look and feel, its moment-to-moment gameplay is good."

## What is fixed and what is open

Fixed. A concept that breaks one fails:
1. The theme: an idealised European woodland of animal folk, fairies and oozes.
2. Lead and stained glass, for the cards and the whole UI.
3. The hexagons: units and cards are tall, stretched hexagons set in lead, on today's card art and tier frames, undistorted.

Open: everything else, including the board as 4 in front and 3 behind, the zones, what a card shows, and every other layout rule in the project's skills and docs. Do not mark a concept down for departing from today's layout or from an earlier owner decision: the owner asked for other things to be suggested. Do check that each concept's notes name the decisions it reverses (`owner-decisions.md`, by row number) and label any rules change as a suggestion.

## Inputs

All paths are in the checkout unless they start with `/data`.

- The designer brief every designer followed: `docs/workstreams/ui-ideation/briefs/04-designer.md`. Read it first: it holds the state every concept draws, the deliverables and the visual quality pass.
- The six concepts: `docs/workstreams/ui-ideation/concepts/<A to F>/` (`concept.html`, `notes.md`) and their renders at 1920x1080 in `/data/ui-ideation/concepts/<A to F>/`: `mid.png` (recruit, turn 9), `first.png` (recruit, turn 1, first session), `fight.png`, `after.png` (the fight's end), and any `extra*.png`.
  - A. The great window, refit (today's architecture perfected; the control)
  - B. Honeycomb (one lattice of hexagon cells)
  - C. Rose window (a radial screen)
  - D. The glazier's bench (diegetic light table)
  - E. Glass in the forest (no window; cards in a woodland scene)
  - F. The reading book (side by side; names and keywords in words on the cards)
- All six side by side with today's game: `/data/ui-ideation/concepts/compare-mid.png`, `compare-first.png`, `compare-fight.png` and `compare-after.png`. Use them to get your bearings; judge from the full-size renders.
- Today's game, same state: `/data/ui-ideation/baseline/shots/recruit-mid.png`, `recruit-t1.png`, `fight-mid-t9-start.png`, `fight-mid-t9-result-defeat.png` (more in that folder). The state itself: `docs/workstreams/ui-ideation/map/state.md`. What a player decides on each screen: `map/map.md`. A critique of today's screens: `map/critique.md`.
- The gallery of games players love: `/data/ui-ideation/gallery/sheet-1.jpg`, `sheet-2.jpg`, `index.md`, full size in `images/`.
- The owner's method for judging a game screen: `/data/ui-ideation/skills/game-ui-design/SKILL.md` (the critique checks; the hundredth game, not the first; teachable).
- The owner's earlier decisions about the screens: `docs/workstreams/ui-ideation/owner-decisions.md`.

## Facts from the orchestrator (mine, not the owner's and not a judgement)

- The fight's end: `map/state.md` says the opponent keeps all seven units. One designer replayed the game's record and found six survivors (Briar King fell). Do not mark a concept down for showing either number.
- The build keeps no fight log. Any "what beat you" account in an `after` view was reasoned by the designer from the two boards; judge how it is shown, not whether the game records it today.
- The 13 damage is 10 for turn 9 plus 3 for a heavy loss, as several designers checked in the code.
- D and E each have one new background picture, made by a separate art worker from the designer's written request (`art-request.md` in their folders). The other four had no new pictures: only today's art and what they drew in SVG and CSS.
- Designers were told to read `owner-decisions.md` only after their first full draft, and were not given `map/critique.md`.

## What to do

1. **Visual-defect pass on every concept.** Look at every render at full size; crop or zoom as needed. List defects per concept with the view and the place: alignment (centred and left-aligned siblings mixed; zones not sharing edges), an icon that does not match its action, text a player acts on under 18 px or any text under 14 px, contrast under 4.5:1 for text, overlap, overflow, clipping at a panel or screen edge, uneven spacing, large dead areas, more than one accent for "press this next", a card that is distorted or not a tall hexagon in its frame, anything that is not glass, lead or their surround.
2. **Score every concept, and today's game, out of 10 on each of two things:**
   - **The look.** Would it belong among the games in the gallery: flavour, craft and polish as a player would see it? Do the glass, the lead, the light and the woodland carry the whole screen down to the smallest counter? Does it look made, not assembled?
   - **Reading the game at a glance.** Mid-game (`mid.png`), can a returning player read the shop, their board and who they are up against without opening each card, and is the result calm, not busy? Count what a player must open to weigh the shop.
   Then say pass or fail on each of the three fixed things, and add one or two lines on the fight and its end (`fight.png`, `after.png`): can the player see what each side has, and learn why they lost? That comment is not a score.
3. **Rank all six** and name the best two or three, with reasons. For each of those, give a numbered fix list: the defects and misses to fix before the owner sees it, each with evidence (view and place) and the fix.

Keep scope tight: the task is "pick the best concepts and fix their defects". Mark anything outside it (new features, a redesign of a concept into a different one) as non-blocking. From stills, motion, timing, hover feel and sound are "not judged": say so; never pass them.

## Answer format

- First line: `VERDICT: SHORTLIST <letters in rank order>` (for example `VERDICT: SHORTLIST D B A`).
- A score table: the six concepts and today's game by (the look, reading at a glance, the three fixed things pass or fail).
- The full ranking A to F, one line of reasons each, and where today's game would place among them.
- Defects per concept (all six).
- One or two lines per concept on the fight and its end.
- For each shortlisted concept: a numbered blocking fix list, each item with evidence and the fix.
- At most 3 non-blocking notes.
- Not judged.
- A Disk section: anything you wrote besides your answer file (scratch crops and so on), with paths and sizes, and what can be deleted. Use `/data/ui-ideation/tmp/council-<your name>/` for scratch. Never run a delete command; list what should be removed instead.
