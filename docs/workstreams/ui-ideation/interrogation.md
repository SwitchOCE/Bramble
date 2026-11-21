# Interrogation of PLAN.md (UI and UX ideation)

By a fresh agent that did not write the plan, 21 Nov 2026, following `~/.claude/skills/plan-interrogate/SKILL.md`. Read: `PLAN.md`, `README.md`, `map/critique.md`, `map/state.md`, `map/map.md` (head), `owner-decisions.md`, `briefs/03-owner-decisions.md`, the gallery (`index.md`, both contact sheets), `recruit-mid.png`, `fight-mid-t9-attack.png`, the `council` and `game-ui-design` skills, and the P(Doom) example briefs.

**The problem, in the owner's words:** "start a new ideation branch where agents focus on improving our UI and UX in the same method and process that I've gone through there"; hold "the theme and the stained glass and the hexagons ... sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things". The method ends when the council says "our design feels like it belongs here ... or it's at least the average kind of level".

## Main findings

1. **Nothing in the scoring judges the look.** Step 2 scores every concept on two information outcomes "and nothing else". The owner's top priority is look and feel (row 18: "What is most important to me is the game's look and feel"), and the P(Doom) council's first score was flavour. The look is judged only in step 4, after the shortlist is already cut on legibility alone. So the most beautiful concepts (likely C, D, E) can be cut before anyone asks whether they look good. That is the same failure as the first P(Doom) mock-up ("all of the flavor ... lost").
2. **The two outcomes are the orchestrator's choice, taken from its own critique.** The owner never named them. In P(Doom) the council agreed the bar (`pdoom-example/bar.md`). Outcome 1 is well argued, but it pushes against the owner's own verdict from the same day ("The keyword stuff I don't like. It's too busy.", 21 Nov, row 23). Outcome 2 lifts the lobby, which the owner played down ("I don't want that full detail stuff yet", row 40; the leaderboard "may be dropped", row 39), and the fight explanation, which the owner never asked for. The owner's rule is at most two deciding criteria, so adding a third doesn't work. One of the two has to change. (Open question 1.)
3. **D and E are starved of their art.** "No new generated pictures" is the orchestrator's rule. The glazier's bench and the forest in glass both need a scene, and `state.md` lists no background picture to reuse: only cards, frames, portraits, stone and pane textures. With only CSS glass they will lose to A and F on polish, not on idea.
4. **A and F share a layout.** Both keep today's great window. They differ mainly in the card face (minimal plus a reading pane, against words on the card). The owner asked for "different styles and different layouts". F should take a different layout. The side-by-side "book" layout the owner once floated (row 80) is the obvious unused one.
5. **D can break a fixed thing.** A wooden bench with coins is a wood UI, not "lead and stained glass for cards and the whole UI". Its brief must say the bench, coins and controls are drawn in glass and lead.
6. **The designers' inputs anchor them.** Every designer gets `critique.md`, with its "Fix" column (names on cards, the lobby in the side lights), and all 84 earlier owner decisions. The owner said "They're not to follow the other constraints". Six designers reading the same fixes and preferences will converge. In P(Doom) the designers got the brief, not the reviews.
7. **What the owner sees is only the shortlist.** Step 5 shows the shortlisted concepts. The other concepts and their "other things" suggestions, the part the owner said they "should" make, never reach the owner.
8. **The owner can wait a long time.** Up to two fix rounds in step 3 and two more in step 4 come before the owner hears of a failure, and the plan shows the owner nothing before step 5. The worker approval watch (global rule 6) is not in the run rules, and it is the main way a worker stalls overnight on the Optiplex.

## Table

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| Map, state, critique (done) | Yes: "first principles ... what needs to be shown" | Owner's method; content by the orchestrator | keep; **shrink** what designers get | Give designers `state.md`, `map.md` and the baseline shots, not `critique.md`'s fixes (finding 6). The council can have the critique. |
| Reference gallery (done) | Yes: the owner's final check needs it | Owner | keep | 17 games picked by players' love, not UI praise, as the owner's skill says. |
| `owner-decisions.md` (done) | Partly: lets a concept name what it reverses | Orchestrator | keep; **shrink** its use | Designers draft first, then check the list and name the rows they reverse. Read up front, it pulls them back to today's game (finding 6). |
| "Judged on these two outcomes and nothing else" | Partly | Orchestrator, from its own critique | **ask** | Findings 1 and 2. Open question 1. |
| Only recruit and fight are redrawn | Yes: the owner's rule to focus each pass | Orchestrator, under the owner's skill | keep | Say it on the final page, so the owner knows start, result, pause and the browser weren't touched. |
| Step 1: six designers, none sees the others, orchestrator doesn't design | Yes | Owner ("more variety ... different styles and different layouts", "don't do the designs yourself") | keep | |
| Models 2 Opus, 2 Sol, 2 Neon | Yes: more variety | Orchestrator (P(Doom) brief suggested mixing) | keep | |
| A, the great window refit | Yes, as the control | Orchestrator | keep | The concept that reverses the fewest decisions. Useful to see beside the bold ones. |
| B, honeycomb | Yes | Orchestrator | keep | Stretched hexagons do tile, so the fixed shape holds. Its "adjacency shows who stands in front" changes the 4-and-3 rows and who attacks whom (R1, R18), so it must be labelled a rules suggestion. |
| C, rose window | Yes | Orchestrator | keep | A layout that is truly different, and it grows out of the glass. The radial board is also a rules suggestion (R1, R18). |
| D, the glazier's bench | Yes | Orchestrator | **shrink** | The brief must say everything on screen is lead and glass (finding 5), and D needs its scene art (finding 3). |
| E, glass in the forest | Yes | Orchestrator | keep, **if** art is allowed | Without a woodland background in glass it can't be drawn fairly (finding 3). |
| F, the reading card | Yes | Orchestrator | **shrink** | Give it its own layout (side by side, row 80), not only its own card face (finding 4). It reverses the 21 Nov "too busy" verdict on purpose. That is allowed, but the council should judge whether it is busy. |
| Four views per concept (t9 recruit, t1 with a cue, t9 fight, fight end) | Yes | Owner's skill (first-session and returning views); the fight views come from outcome 2 | keep | If outcome 2 changes, keep the fight start and drop the fight-end view. |
| notes.md: glance count, reversals, suggestions, weakest point | Yes | Owner's skill, plus the orchestrator | keep | The suggestions line is where "should suggest other things" lives. It must reach the owner (finding 7). |
| Visual quality pass | Yes: the owner's P(Doom) complaints | Owner | keep | |
| "No new generated pictures" | No | Orchestrator | **cut** | Allow one background picture per concept whose direction needs a scene (D, E), made by the `bramble-art` recipe. Otherwise the comparison is about polish. (Open question 3.) |
| Step 2: council, three members, low sensitivity, defects then scores then ranking | Yes | Owner ("Have the council pick") | keep, but **change the scores** | Score on the two agreed criteria (open question 1), and score today's game too, as planned. |
| The council's consensus process | Yes | Owner's council skill | keep, **cap it** | One discussion round and one vote, then the majority holds. The skill's "goes round again" has no end. |
| Step 3: fixes, at most two rounds | Yes | Owner's P(Doom) shape | keep | |
| Step 4: gallery check, done at "average or better" | Yes: the owner's own done line | Owner | keep, **add one test** | Today's game sits in the same gallery. Require the concept to place above today's game, or say plainly that it doesn't. Otherwise "average" might be no better than what exists. |
| Step 4: two more fix rounds, then tell the owner | Partly | Orchestrator (copies P(Doom)) | keep, with a checkpoint | That is fine once the owner has seen the first round (checkpoint 2). |
| Step 5: one page in house style | Yes | Owner (house-style rule) | keep, **widen** | Add all six concepts as a contact sheet, with each one's suggestions in a line, not only the shortlist (finding 7). |
| Owner question: how much of the card is fixed | Yes | Orchestrator | **ask**, fix the default | The proposed default ("keep today's frames exactly") narrows the owner's words and contradicts F ("names set in its lead"). Open question 2. |
| No child orchestrator | Neutral | Orchestrator | keep | The reason given ("a child would be Opus") is doubtful, but the owner's two layers already exist: the owner's session plus the Fable orchestrator. |
| Model at capacity: retry once, then report | Yes | Owner's council skill | keep | |
| Approval watch | Missing | Global rule 6 | **add** | Run `timeout 7100 t3-approval-watch.py` while any worker runs. |
| Size: "nine agents, two to five turns each" | n/a | Orchestrator | **fix the number** | With 4 possible fix rounds, the discussion and the vote, council members can run 10 or more turns and designers 5. Say the maximum. |

## Fixed after step

- **Today:** step 5. The owner sees nothing until the end, after up to four fix rounds.
- **Reordered:** the owner gets a first look after step 2 (all six concepts and the council's ranking, without blocking the fixes). The problem is fixed at step 5, when the council says a concept belongs in the gallery and the owner has the page.

## Smallest plan

1. The owner settles open questions 1 to 3 with the plan's approval. Designers wait only on question 1. Questions 2 and 3 have defaults.
2. Six designers, with D and F changed as above, a background allowed for D and E, `owner-decisions.md` checked after drafting, and no critique fixes in their brief.
3. Council round 1 on the two agreed criteria, plus defects and today's game. One discussion, one vote.
4. Send the owner a contact sheet of all six, the ranking and each concept's suggestions. This doesn't block; fixes go ahead.
5. Fixes, at most two rounds.
6. Gallery check, with today's game placed in the same gallery. Up to two more rounds, then report.
7. The page: the shortlist in full, the other concepts in a line each, every suggestion, what wasn't judged.

## Deferred

- Start, result, pause, browser and compost screens: until the owner picks a direction.
- Motion, drag feel, timing and sound: "not judged" from stills. Building in Godot is the owner's call after step 7.
- The fight-end view and the fight explanation: only if the owner keeps outcome 2.

## Checkpoints

1. **Now**, with the plan: the two deciding criteria and the six directions, one line each.
2. **After council round 1**: the contact sheet to the owner (doesn't block).
3. **At once**, if a model is unavailable, a worker waits on an approval, or the council can't agree after the vote.
4. **After the first failed gallery check**: one line to the owner on what stands in the way, before the last two rounds.
5. **Step 7**: the page.

## Open questions for the owner

1. **The two things every concept is judged on.** The plan has (a) reading the shop and board without opening each card, and (b) knowing who you face and why you lost. My recommendation is (a), with the lobby folded into it, plus **the look: would it belong in the gallery of games players love**. The fight explanation stays a view each concept draws, not a score.
2. **Card frames.** Keep today's tier frames exactly, as the plan proposes? Or keep only the tall hexagon in lead and leave the frame open, as your "everything else is up for debate" reads?
3. **Art.** Allow one generated background per concept that needs a scene (the bench, the forest)? Recommended: yes.

## Disk

Nothing written outside this file.
