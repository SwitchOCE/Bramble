# Pilot notes: the practice under test (24 Nov 2026)

What the draft [GUIDELINES.md](GUIDELINES.md) and [PROCESS.md](PROCESS.md) did on their first real run: two subjects, [damage to the player](../pilot/player-damage.md) and [a single death](../pilot/death.md), taken from the brief to just before filming (steps 1–4, plus a filming plan). One agent ran both. Nothing was built or filmed, so steps 5–10 are untested.

The owner, 24 Nov: "we're trying to measure how to improve them. We're also not trying to lock it in as final yet. We're just trying to experiment on it."

**Verdicts:** **helped**, **in the way**, **missed** (the practice didn't cover something it needed). Each ends with a proposed change.

## The findings that matter most

1. **"Check ordering first" was the most useful line in the process.** In both subjects it found the real fault before any motion was designed. Damage to the player: the new Health and the burst appear on the result's first frame, before any cause, and then nothing moves for 2.5 s (measured: no pixel changes f692–f816). Death: the killing number has gone a frame before the card starts to die, and the result's `settle()` would cut any death longer than 4 f past the last kill. None of these is a motion problem. *Keep it, and move it before the reference study:* knowing the ordering fault first told me what to look for in the footage (does the number outlast the card?).
2. **Finding the moment in footage was most of the reference work, and the process gives no help with it.** No research note had timestamps for a hero hit or a single death on its own. I scanned 1 fps contact sheets of hour-long videos, about a third of all tool calls in the run. One candidate (Super Auto Pets) turned out not to show the moment at all. *Change:* keep a moment index (`research/moments.csv`: game, video, time, moment, who found it) and add a row whenever anyone watches footage.
3. **A full per-frame table for every reference is too costly, and not needed.** PROCESS step 2 asks for position, angle, scale, opacity and light on every frame of every reference. I did that only for the motion I might copy (Battlegrounds' portrait flight: tracker positions plus region brightness as "light"). The rest I timed by beat onsets from 2-frame sheets (±2 f), which was enough to say "breaks in 5–6 f, trace about 20 f". *Change:* per-frame only for the motion being copied; a beat-onset table for the others; state the error (±1 f for beats under 10 f, ±2 for longer). Name region brightness as the way to measure light.
4. **Guideline D3 named a design, not a need.** "A cause from the winner's side … Accepted 21 Nov (bolt, shake, count-down)" turned an accepted, never-watched proposal into a rule. Every option either obeyed the bolt or "broke D3 on purpose". It is the "matches the prototype" mistake from LB §5, written into the guidelines. *Change:* D3 states the need (the loss lands visibly, the amount reads, the player can tell why) and lists the bolt as the accepted candidate in the motion list, not the guidelines.
5. **The rules of the game changed the design, and the brief template has no line for them.** Bramble's loss damage is round + 1, plus 3 when you killed fewer than half (rulebook 10.1.1), not the survivors' tiers. That ruled out the obvious move (survivors firing at the portrait) and made the big-loss "+3" worth showing. I found it only because I went looking. *Change:* add "Rules it must tell:" to the brief template.
6. **Picture-first had a good side effect: it made me design a filmable pair.** Because nothing with a new piece may be filmed before the owner's yes, each subject ended up with two options from existing pieces (filmable now) and a pick that needs pictures. Filming the cheap pair first answers the big question (does a cause need to travel? must a dead card move?) before anyone pays for art. *Change:* write it into PROCESS: "where you can, make one pair of options from existing pieces, differing in one thing, and film it while the pictures wait."
7. **Several guideline numbers were set for attacks and don't fit other moments.** T4's 5–8 f strike assumes card-to-card distances (1–2.4 card heights); portrait to portrait is 7.7, and 8 f would average 236 px a frame. T5's "react within 3 f" holds for the target's flash, but Battlegrounds delays the hero-hit number by 41 f and LoR by 18 f, on purpose. T10's "≤ 12 f per trigger" was unclear for deaths. *Change:* give T4 a distance clause (keep the speed near an attack's, cap the time); split T5 into "reaction within 3 f" and "number when it can be read"; say whether T10 covers deaths.

## Step by step

### Before step 1: reading

- **Helped:** the skill's reading list was right and short. The inventory's code lines (`fight_screen.gd:515` STAND-IN, `fight_replay.gd:562`) saved a search. The fixture film's per-frame log made "ours, before" a measurement in minutes: the death's 15 f fall, its alpha from the fifth frame, and the slot emptying on the same frame.
- **Missed:** where the 20 Nov proposal lives. The task had to say "find it with grep". The inventory cites "F:herodmg" but not the file (`docs/design/mockups/fix-round-20-nov/anim-fight/NOTES.md`). *Change:* the motion list links each accepted proposal's text.

### Step 1: brief

- **Helped:** naming each limit and what it squeezed. Writing "the death step's 0.3 s came from brief 10's frozen budget, lifted 18 Nov" reopened it on the spot (LB 2 working as designed). "Out of scope" with a reason kept CB8's stagger out without fuss.
- **Helped:** the requirement to quote the owner made the thinness visible: on these two subjects he has said one sentence. That is fine, but it means the bar is mine.
- **In the way:** "Bar: a feeling plus one reference moment". The owner gave neither for these subjects. The template has no honest way to say so. I wrote "Not given by the owner. Proposed, to confirm: …". *Change:* allow exactly that, and make "confirm the bar" the first thing shown to the owner.
- **Missed:** "Rules it must tell" (finding 5).
- **Missed:** "This run stops at …". The template's "Done when" assumes one agent goes to the owner's verdict. When the work is split (specify, then build, then film), each part needs its own stop line. *Change:* add "This run ends at:".
- **Missed:** the brief's "Ordering" line is for one moment, but the death's ordering touched the result screen (the cut at `settle()`). Two subjects run side by side caught it; one alone might not have. *Change:* "Ordering: … and what plays right after it".

### Step 2: reference study

- **Helped:** "few, all of the same moment". It stopped me pulling five games' worth of "end of fight" effects. Three plus ours per subject was enough to see a pattern (the number outlasts the card in every reference; two of three break in 5–6 f).
- **Helped:** "our own build, measured the same way". It produced the two failing checks I want the builder to prove first: the number gone before the death; Health changed before any cause.
- **In the way:** the per-frame table for everything (finding 3).
- **In the way:** "the same moment" across games is often not the same moment. Galaxy has lives, not Health, and the clip was an elimination. LoR's Nexus hit is mid-combat. SAP shows nothing. *Change:* "the same moment, or the nearest the game has; one line on how it differs." I added a "how it differs" column, and it was useful.
- **Missed:** finding the moment (finding 2).
- **Missed:** old sheets with no frame rate on them. `galaxy/work/L_jackdeath.png` has frame labels but no fps; I inferred 30 fps from a timing in another doc. *Change:* every saved sheet's file name or header says its source time and frame step.
- **Missed:** what to do when a reference does something no rule covers. Battlegrounds holds the hero-hit number back 41 f; none of the guidelines say a number may wait. I wrote it down as a finding, but the process doesn't ask for "what does this reference do that our rules don't allow?" *Change:* add it as a step-2 output, since that is where guidelines get revised.
- **Rule held:** no studio frames left `/data`; the docs cite links only. Clear and easy to follow.

### Step 3: beat spec

- **Helped:** the column set (frames, who moves, token, marker, sound, reduced motion). "Reduced motion" took seconds per beat and caught that a count-down is information (it stays) while the shake is not (it goes). "Marker" forced a name for every moment a check or a sound needs, and those names became the log the builder must write.
- **Helped:** anchoring every beat to a marker (R, C, D, H) rather than to film frames. Options can be compared without a film, and big against small losses just shift the anchor. *Change:* PROCESS says "anchor every beat to a named marker".
- **In the way:** the "M or G" column. In a spec for motion that doesn't exist yet, every number is a guess. The useful thing is where a number came from. *Change:* rename it "Source" (a reference row, a rule, or "guess").
- **Missed:** tokens. S1 says every motion uses a named token, but there are none for gravity, shake, hit-stop or a number counting down. Both subjects needed them. I proposed `fall.gravity`, `shake.dir`, `stop.hit` and `count.roll`. *Change:* add them to GUIDELINES §2, with starting numbers.
- **Missed:** the tier is set in E1, but the template has no column or field for it, and "a big unit" (tier 2 for deaths) is not defined anywhere. *Change:* a "Tier:" field in the brief; define "big" (for example, the top tier present, or Attack + Health above a threshold); the owner decides.
- **Guidelines:** the rule tables were quick to apply and found real problems (B and C have no death trace; the striker could cover the Health disc). Two rules were too narrow (T4, T5; finding 7) and one too specific (D3; finding 4). V1 ("a card travels toward another card only when it attacks") didn't say whether a portrait counts. Battlegrounds treats the hero hit as an attack. *Change:* the owner says whether V1 covers portraits.
- **Guidelines:** E5's open question ("whether glass may bend or crack is art direction") blocks the strongest death option and touches elimination's cracked portrait. Nobody had asked the owner. *Change:* put it on the review queue now; it's one question that unblocks three pieces of work.

### Step 4: picture first

- **Helped:** clear about what needs a picture: anything drawn that isn't there today. It led to the filmable pairs (finding 6).
- **Helped:** the combo-look prompt format worked as a template: it pastes sprites onto a real frame at real size, so the owner sees the piece in place. Base frames came from the existing fixture film in one command each, so no new filming was needed.
- **Missed:** the owner's reaction to combo-look round 1 ("someone's gone way too heavy … We need stuff that has good visual clarity") is the single most useful instruction for effect sprites, and I found it only by reading another workstream's art direction. *Change:* a "Lessons for effect sprites" line in `bramble-art` or PROCESS step 4: clarity first, few big pieces, nothing over a number.
- **Missed:** the 22 Nov rule "never crop existing assets" doesn't say whether a runtime effect may cut up the live card (shards from the dying card's own picture). I think it may (it's the card breaking, not a new element made of old art), but the rule is the owner's. *Change:* ask, and write the answer into the rule.
- **Missed:** PROCESS step 4 asks for "a full design pass … an art director who answers the craft questions in writing". For a sprite brief inside a motion spec, that ended up as a short "art direction in short" list plus the prompt. A separate art-direction doc for each effect would have doubled the writing with no new decisions. *Change:* say that, for an effect sprite, the craft answers may sit in the motion spec and the prompt.

### Not in PROCESS: the filming plan

- **Missed:** PROCESS goes from beat spec (3) and pictures (4) straight to build (5). When one agent specifies and another builds, the builder needs a plan: which fixture reaches the moment, what code changes, what the log must add, which checks must fail on today's film first, which cues move. I wrote one per subject. It also caught things the spec alone didn't: no fixture reaches a lost fight; sound cues fire only at step start, so "move the cue with its marker" needs new code. *Change:* add "3b. Filming plan" to PROCESS, with those five headings.
- **Helped:** "Prove the check bites" was easy to plan for here, because the failing version is today's build. Each subject has at least two checks that fail on today's film.

### The sound-cue section

- **Helped:** listing every cue against a moved beat found two gaps: there is no damage-to-the-player cue at all, and cues can't follow a marker inside a step. Both went into the filming plan.

### Step 5: building the cheap options (CB12, CB13 B and C)

- **Helped:** beat tables anchored to named markers turned straight into per-frame log checks, so every beat was measured, not judged. **Got in the way:** the CB12 spec's big-loss totals (B R+79, C R+68) don't follow from its own tables (R+72, R+58); the brief and the pilot named different death moments; sound can't follow a marker inside a step; and filming ran at about 2.4 frames a second, so each change cost a 15-minute film.

## What I could not test

Steps 5–10: building, filming, the compare viewer, the Windows build and the owner's verdict. The claim rules ("never claim it feels better") didn't come up, since nothing moved. Whether the options above are any good is the owner's call on film; this run only shows that the process produced a spec and a plan.

## Proposed edits, in one list

| # | Where | Change |
|---|---|---|
| 1 | PROCESS step 1 | Move "check ordering first" before the reference study; add "and what plays right after it" |
| 2 | Brief template | Add "Rules it must tell:", "Tier:", "This run ends at:"; allow "Bar: not given; proposed …, to confirm" |
| 3 | PROCESS step 2 | Per-frame only for the motion being copied; beat onsets for the rest; stated error; brightness of a region as "light"; "nearest moment, and how it differs"; "what does it do that our rules don't allow?" |
| 4 | Research | A moment index, `research/moments.csv`; sheets labelled with source time and frame step |
| 5 | Beat-spec template | "M or G" becomes "Source"; anchor beats to named markers |
| 6 | GUIDELINES §2 | Tokens `fall.gravity`, `shake.dir`, `stop.hit`, `count.roll` |
| 7 | GUIDELINES | D3 states the need, not the bolt; T4 gets a distance clause; T5 splits reaction from number; say if T10 covers deaths; define "big unit" for tier 2 |
| 8 | Owner questions | May glass crack (E5)? Does V1 cover portraits? May a runtime effect cut up the live card? |
| 9 | PROCESS step 4 | Make a filmable pair from existing pieces where possible; effect sprites: clarity first (combo round 1); the craft answers may sit in the spec and prompt |
| 10 | PROCESS | New step 3b, the filming plan |
| 11 | Motion list | Link each accepted proposal's text |
