# Fight animation phase: plan (24 Nov 2026)

Orchestrator's plan on `ideation/fight-animation`. Nothing here changes the game the owner plays; what gets built afterwards is the owner's call.

## The owner's words (24 Nov, dictated, filler removed)

> "I think I really want to understand our animations pass. I think there are some very key things that Battlegrounds does to make the fights very readable, in terms of: the cards travel all the way to the card they're hitting, and they don't move at a consistent speed. I don't think they pause mid-animation if they trigger something else after starting up, and the wind-up being very clearly visible. Then the other animation goes off. We don't have that either. That's really important."

> "Essentially, I want you to start a phase of work where a bunch of agents look into Battlegrounds animations, Galaxy animations, et cetera, and come up with different plans as to how to tackle different animations. I want to see basically a decision-making tree. You know, if this animation does this, what should we do in response? And I want a proposal the agent gives as to what they think would be the absolute best. I want the council review, only a single council review. I want example video clips or example animations made, maybe, and the different kinds of treatments we can give them, etc. That's a new phase of work."

Standing rule that still holds: `docs/design/owner-notes/2026-11-18b-fight-timing-and-grouping.md`.

## Two problems

1. **One action's motion**: wind-up, travel distance, speed curve, contact, hit. Today (`src/screens/fight/fight_motion.gd`): wind-up 4 frames and 12 px, travel 8 frames (12 frames from start to contact), stops with centres 0.62 card heights apart, 2 frames held, 11 frames home.
2. **Ordering**: when an action triggers others, what plays first, together, or waits. Today every event is its own held step (`fight_replay.gd`: lunge 0.22 s, splash 0.55, trigger 0.3, death 0.3, summon 0.35, change 0.3). This is what the decision tree answers.

## Steps

1. **Research, three agents at once** (Opus):
   - **R1 Battlegrounds, measured.** Public videos into `/data/fight-anim-ref/` (scratch, never committed, never on a page). Step frame by frame; a table of numbers (wind-up frames, travel frames, stop point, speed curve, hit hold, when a triggered effect starts against the attacker's motion, what ten triggers do), each row with link and timestamp. Tests the owner's three claims and says plainly where footage disagrees.
   - **R2 Once Upon a Galaxy and two or three others** (likely Hearthstone constructed, Super Auto Pets, Marvel Snap or TFT), same table.
   - **R3 Our side.** Every event our fight emits (`src/core/combat/`, the fight report), how the build shows each today, what of the 20 Nov fix-round proposal was built, which sound cues sit on which motion. Also films today's attack with `tools/feel` and measures it in R1's table format, so ours and theirs compare like for like.
   - Checkpoint: post the measured table and the claim checks to the owner in this thread as soon as it exists (they test the owner's own claims); work continues.
2. **Three plans, from agents that don't see each other's.** Each gets R1–R3, not another plan. Each gives: numbers for the basic attack, ordering rules, a decision tree over R3's event list, and what it gives up. Each starts from a different stance so they really differ: (A) Battlegrounds' measured grammar as closely as fits our board; (B) fastest that still reads, built round grouping; (C) weight and drama suited to lead and glass. Each may say its stance is wrong.
3. **The best proposal.** A fresh agent reads the three plans and the research and writes the one it stands behind (may be one plan, or a mix), with the full decision tree, marking the branches where the plans disagree. Checkpoint: the branch list goes to the owner before anything is built.
4. **Examples in Godot.** One short fixed fight on real cards: a plain attack, an attack that triggers something, a death with an effect, one trigger many times. Two whole-fight films: today's build and the best proposal. Then, for each branch of the tree where the plans disagree, short clips of each option side by side (e.g. a trigger during the attack: pause / overlap / after contact), so the owner judges one change at a time. Whole-fight films of plans A, B and C only if the owner asks. Treatments sit behind a switch in this branch only. Checks per clip: frames pulled with ffmpeg, the attacker's position logged every frame by the film fixture (for the speed chart), step timings from the film's report. Builders work in their own worktrees; each code step passes the project's checks and a `scope-reviewer` before it lands on this branch. The films go to the owner as soon as they exist, before the council.
5. **Council review, once**, on the finished package (tree, best proposal, films). Members Opus, GPT Sol, Gemini Neon, per the `council` skill, one full round, findings fixed, no re-check round (owner, 24 Nov). Before it: test with one of our clips whether Sol or Neon can take video; if not, they get frame strips and charts, and the page says so.
6. **The page** (`house-style`), published with small clips. Top: the five films side by side, and the decisions with a recommendation each. Below: the tree, the measurements, the plans, what was and wasn't checked. Also lists which sound cues a new timing would move (not retimed here).
7. **Proposed, not built:** the best two or three treatments behind a switch in a Windows build so the owner can feel them at full frame rate.

## Changed after the plan review

A fresh agent questioned this plan (24 Nov). Taken: per-branch option clips instead of five whole-plan films; films to the owner before the council; position logged by the fixture, not read from images; a checkpoint on the tree's branch list. Not taken: cutting R2 to Galaxy plus one game (already running, little to save). Owner, 24 Nov, asked whether the council is one round or the skill's loop: "Yeah, yeah, one four round" *[probably "one full round"]*: one round, findings fixed, no re-check round.

## What no agent can check

Whether a motion reads well or feels right. Films, frame strips, charts and timings are checks of what is drawn and when; feel is the owner's. A yes to a motion not yet watched is provisional.

## Disk

Reference footage in `/data/fight-anim-ref/`, deleted when the phase ends. Our own films in this branch's scratch until the page is published; only small clips go on the page.
