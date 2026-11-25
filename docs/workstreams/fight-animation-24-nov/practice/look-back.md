# Look back: how Bramble's animations were made (24 Nov 2026)

Step "look back" of [PLAN-animation-practice.md](../PLAN-animation-practice.md). It compares how each past piece of animation work was run, to find which process produced motion the owner liked. Read-only: nothing was run or filmed for it.

The owner, 24 Nov: "Triples are great. A triple animation is great, I really like that one. But a lot of the other stuff …" and "death animations in general might need work, and the player taking damage after a fight as well … I feel like animations are a weak spot in our process and we need to improve them."

**Sources.** Briefs, taste logs, beat specs, run logs, morning packs, plans and git history on this branch and its remotes; `gh pr view` for PRs 124, 126 and 250 (none has a PR comment). The owner's reactions are only those quoted in the repo. Where the repo records none, this page says so; he may have said more in chat.

**One caution.** There is one clear success (the triple) and one near-success (drag feel). Two cases can't prove a process. The lessons below are the differences that line up with the owner's reactions, not proof of cause.

## At a glance

| | Triple (brief 5) | Drag feel | Fight hits (brief 10) | Shop glow (brief 4) | Fix round 20 Nov + PR 250 | This phase (24 Nov) |
|---|---|---|---|---|---|---|
| **Owner's verdict** | Loved | "feels really good", then "way better" | "doesn't feel right yet" | "still not quite obvious enough" | Deaths "might need work"; hero damage named; recruit batch: no recorded reaction | "I think I like this honestly"; hard to tell options apart |
| **Brief's target** | A feeling: "the same sense of excitement" | Parity with Galaxy | "learn the best practices", "easier to follow" | A glow on duplicates | "prototype for every single one" | The owner's four named faults; a decision tree |
| **References** | 5 clips of the same event (BG, TFT) | 2 Galaxy clips | 11 clips, 5 games, mixed (incl. player-driven) | None | None | BG and Galaxy, measured at 60 fps |
| **Frame-by-frame beat spec** | Yes, 8 beats in frames | Per round, in commits | Beat table, but references read at 10 fps | No | Timings as "first guesses", per action | Yes, per phase, each marked measured or guess |
| **Time limit** | Only: block input no longer than the longest reference (3.84 s) | None | Hard: no attack or fight longer (later lifted) | None | Note of 18 Nov (may change, not wildly) | Same note |
| **Shown to the owner** | In his build; 2 paces side by side, same script | In his build, his hands | In his build; 11 unaligned side-by-sides | In his build | 81 looping HTML prototypes on one page | 5–7 panes side by side per decision, then a 2-pick viewer |
| **Rounds with the owner** | 1 (plus a review fix and a rules beat) | 2 builds in one day | 1, then nothing for 6 days | 2 (stronger glow, then foil) | 1 blanket yes; fight half never built | 2 so far |

## 1. The triple (brief 5, PR 126, 17–18 Nov)

- **Brief asked:** the owner's words, a feeling as the bar: "is our animation like taking inspiration from these and better than them, or of a similar quality level? At least is it doing the same types of things, right? It's building the same sense of excitement" ([sources/2026-11-17a](../../../design/sources/2026-11-17a-backlog-scope-shop-tooltips-data.md)). Done when: a 60 fps film beside each clip, a list of each reference's beats (gather, build-up, flash, reveal, reward) against ours, and input never blocked longer than the longest reference. The agent decided all motion. Sound and the golden's look out of scope ([backlog-briefs.md](../../backlog-briefs.md) §5).
- **Reference, and who approved it:** the owner named the games (The Bazaar, TFT, Battlegrounds) and OK'd the download. Agents found and cut five clips: two BG triples, two TFT combines, one BG normal-against-golden still ([reference-clips](../../../design/reference-clips/README.md)). The owner said going without The Bazaar was "fine". No record that he watched the cuts. All five show the same moment: three things become one stronger thing.
- **Beat spec:** yes. [triple-beats.md](../../night-18-nov/triple-beats.md) breaks each reference into beats with seconds (10 and 12 fps frames, ±0.08 s, fine for beats of 0.2–0.4 s), maps each to a Bramble beat, and fixes ours in frames: lift 0–14, gather 14–36, compress 36–50, flash 50–58, reveal 58–78, curve home 78–98, landing 98–108. All tuning lives in one file (`recruit_triple_motion.gd`).
- **How options were shown:** two paces, brisk 1.80 s and ceremonial 2.16 s, filmed with the same pointer script and state, only the pace changed, side by side at real speed (`pace-candidates.mp4`). Five reference side-by-sides. In the morning pack: "Buy a third and watch the triple. It's 1.80 s, and a click finishes it early." So the owner judged it in his own build.
- **Rounds:** one build. The orchestrator's review sent it back once for correctness, not look: copies the screen had never drawn appeared as stand-ins under the screen centre, any redraw cut the show short, a press snapped every moving card, and a made-up "0 s lock" sat in the reports ([night run log](../../night-18-nov/README.md), 23:00). A later rules change (Triple Reward at formation, C15) added one reward beat without touching the first six. The owner's brisk-or-ceremonial answer isn't recorded; brisk stayed.
- **What the agents claimed they had checked:** drawn pixels, not node settings (`drawn-motion.json`: every beat sample changes over 52,000 pixels, and a frozen sequence is rejected); film rates and frame counts; 18 then 24 focused tests; input at eight beat positions. They said what they could not judge: "the owner's sense of excitement, real GPU frame pacing and physical input latency. … not a claim that an agent proved equal aesthetic quality."
- **Owner said:** 24 Nov: "A triple animation is great, I really like that one."
- **Why it went right:**
  - The bar was a feeling plus references of exactly the same event, so "same beats" was a fair test. Each beat had a clear job: identify the three, gather, build, flash, reveal, land.
  - It is a rare, single ceremony with nothing else to sequence, so it had room for anticipation and a payoff. No time limit squeezed it: the only limit was the 3.84 s input bound, and it came in under that.
  - Two options differing in one thing, filmed identically, at real speed.
  - Built from nothing: before it, a triple had no animation of its own. *[Editor note: any decent version was a large step up, which may flatter the process.]*

## 2. Drag feel (PRs 107, 108, 112, 16–17 Nov)

Not on the task's list; found in the history. It is the other case the owner praised.

- **Brief asked:** the owner, after playing `five-tribes-4`: picking units up "doesn't feel visceral … I want you to keep improving the feel until we've got parity with that [Galaxy] to a reviewer" ([ideation-track-2/HANDOVER.md](../../../ideation-track-2/HANDOVER.md)).
- **Reference:** two Galaxy clips, picked by agents. The `tools/feel` film tool was built for this work.
- **Beat spec:** per round, in the commits (for example round 2: "4 frames to lock, then a hop of 16 px with a 6% swell, held 3 frames, then down: 16 frames in all").
- **Shown:** films to two film reviewers, then a Windows build in the owner's hands.
- **Rounds:** four agent rounds against the clips, then two owner builds in one day.
- **Agents claimed:** both film reviewers said "not yet parity", and disagreed on how far a Galaxy card bounces on landing (18 px or 72 px) because the clip hides the pointer.
- **Owner said:** on `drag-feel-1`: "it feels really good. This is a great improvement … It's a bit too bouncy at the moment in terms of like moving it side to side. It tilts a bit too much … If it never changed again, it'd be fine." After the numbers were calmed (lean cap 28° to 16°, and so on): "it feels way better".
- **Why it went right:** the owner's hands on a real build between rounds, with a same-day turnaround, and his note was a direction an agent could act on ("too bouncy", "tilts too much"). The agents' "not yet parity" was stricter than the owner. Their verdict didn't predict his, in either direction.

## 3. Fight hits (brief 10, PR 124, 17 Nov)

- **Brief asked:** "Get more concrete bars for Battlegrounds attack animations, Galaxy attack animations … Just 4 or 5 examples so we can learn the best practices and create something of high quality." Done when: a beat-by-beat list of what references do that ours doesn't (wind-up, travel, impact, recoil, damage number, death); attack, hit and death reworked; a whole fight filmed beside the clips; "a fight is easier to follow". **Ask first: making fights longer than they are now.** Not in scope: grouping, sound.
- **Reference:** the owner asked for 4 or 5; agents cut 11, from Battlegrounds, Galaxy, Hearthstone constructed, MTG Arena and Legends of Runeterra. Two of them are player-driven (a targeting arrow, block assignment), and the README admits gaps (one cut each for MTGA and LoR, no Galaxy large board, no clean BG single attack on a full board). Downloaded on the owner's OK; no record he watched the cuts.
- **Beat spec:** yes, a good one in form ([fight-beats.md](../../night-18-nov/fight-beats.md)): each beat with clip and second. But the references were read as **10 fps strips (±0.1 s)**, while the motions being copied are 4–12 frames (0.07–0.2 s) long. The table names what references do ("lifts, grows and leans away before diving", Galaxy 2.4–2.7 s) but couldn't measure how long.
- **The time limit decided the motion:** the brief froze every replay hold and the fight's length. The worker fitted wind-up and travel into the old 0.22 s step: a **4-frame, 12 px** wind-up. It knew this was small. The run log, 21:55: "Galaxy spends about 0.3 s on a big lift and lean. If the motion feels timid, the fix is more time per attack." Deaths had to "clear inside the existing death hold" (0.3 s).
- **How options were shown:** a 4-frame against a 6-frame wind-up inside the same 12-frame budget (`windup-candidates.mp4`), fixed against following damage numbers, before against after, and eleven reference side-by-sides that the morning pack says were "not time-aligned beat by beat". The owner was pointed to his build: "watch the fight: the wind-up, the lunge, the recoil and the deaths."
- **Rounds:** one night. On 18 Nov the owner lifted the time limit ([owner note 2026-11-18b](../../../design/owner-notes/2026-11-18b-fight-timing-and-grouping.md)): "the attack timings can change and vary a bit." **No one went back to redo the wind-up or the deaths.** The next change to fight motion was PR 197's pile-on jab (19 Nov).
- **What the agents claimed:** all 30 transition times identical to the baseline, 727 tests, 18 films validated, "a visible chain: identify attacker → follow it to target → see both recipients react". Stated limit: "No automated assertion establishes human readability … or the owner's preference."
- **Owner said:** no recorded reaction to the motion until 24 Nov, when he listed what Battlegrounds does that we don't: "the cards travel all the way to the card they're hitting, and they don't move at a consistent speed. I don't think they pause mid-animation if they trigger something else after starting up, and the wind-up being very clearly visible … We don't have that either. That's really important." Then: "it doesn't feel right yet."
- **Why it went wrong:**
  - The brief's time limit forced the timid wind-up the worker itself flagged. Lifting the limit didn't reopen the work.
  - The owner's sharpest complaint (pausing mid-attack while triggers play) is ordering, and ordering ("grouping") was out of scope. The motion was polished inside a structure that was the real fault (R3: an attacker freezes at contact for 23–41 frames when a trigger sits between attack and damage, [our-attack-measured.md](../research/our-attack-measured.md)).
  - "Learn best practices" across five games is a wide bar. Unlike the triple, the references didn't all show the same moment the same way, so "does ours do the same things" had no single answer.
  - 10 fps reading couldn't resolve the beats being copied.
  - The two candidates differed by 2 frames inside a fixed budget, too small to be a real choice.

## 4. Shop glow and foil (briefs 4, PRs 127 and 132, 17–18 Nov)

Short, because it is a light, not a movement, but it carries a checking lesson.

- **What happened:** the worker filmed two pulse candidates and picked the slow "breath". A scope reviewer measured the films and found the pulse **never drew**: frames were pixel-identical, a shader dropped the fade, and the test checked a setting, not pixels ([night run log](../../night-18-nov/README.md), 22:05). "A worker's motion choice was made from films that showed no motion."
- **Owner said:** after playing, he "missed last night's glow"; after it was made stronger: "The triple effect's still not quite obvious enough for me", asking for foil ([taste-dupes.md](../../night-18-nov/taste-dupes.md)).
- **Lesson carried:** check drawn pixels, and prove the check fails on the broken version. Brightness that reads on a software render can be too faint in play.

## 5. The 20 Nov fix round: proposals (`anim-recruit`, `anim-fight`) and PR 250

- **Brief asked:** item 11, the owner's "prototype for every single one" ([interrogation.md](../../fix-round-20-nov/interrogation.md)). An agent drew 47 recruit actions and 34 fight events as looping **HTML / Web Animations prototypes**, each tagged new, changed or keep ([anim-recruit NOTES](../../../design/mockups/fix-round-20-nov/anim-recruit/NOTES.md), [anim-fight NOTES](../../../design/mockups/fix-round-20-nov/anim-fight/NOTES.md)).
- **Reference:** none. Timings were "first guesses, set from the build's existing beats". Battlegrounds appears only once, as the reason for a proposed queue speed-up. "Keep" rows (triple, carry, deaths) were "re-created here roughly; the build's own motion is the reference".
- **Beat spec:** a timing per action (for example "Deaths | keep (motion) | Drop 48 px, turn 16°, shrink to 0.72, fade in 15f … Same motion, started while the burst is read"), not a frame-by-frame breakdown against a reference.
- **How options were shown:** one page, every prototype looping, with normal and quarter speed. A few owner choices listed (two bolts or one, plate or plain text). No side-by-side of alternatives for most rows.
- **Agents claimed:** "I could not judge any motion by eye. I checked only still key frames (PNGs) and the code and timings." That is honest, and it means nobody had watched the 81 proposals move before they were accepted.
- **Owner said:** 21 Nov, one line for all of item 11: "option 11, I accept all changes" ([fix-round PLAN](../../fix-round-20-nov/PLAN.md), decision 13).
- **What was built:** the recruit batch, PR 250 (merged 21 Nov). The worker copied the prototypes' CSS easings exactly (`GlassMotion.bezier`) and checked each animation by filming it and comparing it with its prototype frame by frame ([taste-anim-recruit.md](../../fix-round-20-nov/night-21-nov/taste-anim-recruit.md)). A scope review caught that the swap had lost its approved look, and a fix worker put it back. **No owner reaction to the recruit batch's motion is recorded** beyond the price-tag pick. **The fight batch was never started** ([our-events.md](../research/our-events.md) §2): hero damage is still "a static burst on the loser's portrait", and deaths still use brief 10's 0.3 s fall in their own step.
- **Why deaths and hero damage went wrong:**
  - "Keep" meant "no change proposed", not "judged good". Deaths had been made under brief 10's time limit and never looked at again against the death references brief 10 had listed (Galaxy's card knocked spinning off screen, BG dust, the LoR crack, the MTGA dissolve).
  - A blanket yes to 81 rough HTML prototypes is not a taste verdict on any one of them, least of all on "keep" rows that the page only re-created roughly. (Same pattern as the type line in decision 7, which the owner took back: "That's the kind of visual change that should need to be okayed by me".)
  - Damage to the player was proposed (a bolt from the winner's portrait, a shake, Health counting down), accepted, and then fell out when the fight batch never started. Nothing tracked accepted but unbuilt proposals.
  - PR 250's check, "matches its prototype frame by frame", proved faithful copying of a motion no one had felt. It could not show the motion was good.

## 6. This phase (24 Nov, pass 1 and pass 2 so far)

- **Brief asked:** the owner's four named faults (travel all the way, varied speed, no pause mid-attack, a clear wind-up), plus "a decision-making tree", "a proposal … what they think would be the absolute best", one council review, and example clips ([PLAN.md](../PLAN.md)).
- **Reference:** Battlegrounds and Galaxy footage chosen by agents, kept off pages, **measured at 60 fps** with a per-frame tracker. Our own attack measured the same way, from engine positions logged per drawn frame ([our-attack-measured.md](../research/our-attack-measured.md)). The owner's claims were tested against footage.
- **Beat spec:** yes, the most thorough so far ([plans/best.md](../plans/best.md) §2): each phase in frames, each number marked **M** (measured) or **G** (guess).
- **How options were shown:** for each of seven contested branches (CB1–CB7), 3–5 panes side by side, aligned on the branch's moment, on a published page. A council of three models reviewed it once; all three read clips correctly by pulling frames ([council-video-test.md](../council-video-test.md)).
- **Agents claimed:** "No agent has watched any of it move." The council's 13 findings are all rules, data and labelling faults (when a re-strike may start, a mislabelled pane, a held frame that should be zero), none about feel ([council-review.md](../council-review.md)).
- **Owner said** ([PLAN-pass-2.md](../PLAN-pass-2.md)):
  - "I think I like this honestly. It's very hard for me to tell, like I notice small differences."
  - On the strike curve, where the best proposal had picked **linear because "it is measured"** (CB3): "The constant, linear stuff, I noticed that was very bad. I didn't like that." He liked the speed-up: "maybe even a slower speed-up would be better".
  - Something nobody had measured: "the card should tilt or rotate to point at what it's hitting." (Galaxy's tilt was measured, but Battlegrounds' angle "was searched but never saved".)
  - On the format: "When you give a video clip of seven things side by side, it's very hard for me to pinpoint. Maybe build some sort of tool that lets me pick just two animations to compare, and I can slow or speed them up."
  - New faults he saw only by watching: buffs ("When Brock gets stats it's very hard to tell what happened") and six deaths falling at once ("if we had some way of staggering them a little bit … it would feel more realistic if they dropped off one at a time").
  - "These aren't a firm steering. I don't know what's right … because it doesn't feel right yet."
- **What went right:** frame-level measurement, our own motion measured the same way, every number marked measured or guessed, one variable per comparison, and a fast loop with the owner the same day. He engaged with specifics for the first time on fight motion.
- **What went wrong:** too many panes per decision, with differences too small to see at speed. A measured reference number (linear strike) was recommended over feel, and the owner disliked exactly that. The research measured position and timing, so rotation, which he perceives, wasn't in the table. The council cost three models' review and found no feel problems, as expected.

## What separates the liked from the not liked

| | Liked (triple, drag) | Not liked (fight hits, deaths, hero damage) |
|---|---|---|
| Bar | One moment, the same in every reference, or one named game to match | Many games, many moments, "best practices" |
| Limits | None that shaped the motion | A fixed time budget that shrank the wind-up and death |
| What was really wrong | The motion itself | Mostly ordering and holds, left out of scope |
| Owner's eyes | Real build, his hands, quick next round | One build, then six days; or a blanket yes to HTML |
| Options | Two, differing in one thing | Nearly identical (4 against 6 frames), or seven at once, or none |
| After | Tuned on his words ("too bouncy") | Constraint lifted, work not reopened; accepted, never built |

## Lessons, ranked

1. **Get the owner's reaction on a real build between rounds, and keep each round short.** Both liked cases went brief → build → owner plays → tune on his words → build, in a day. The fight work had one build and then six days of silence; the fix round's fight half got a yes on HTML and was never built. *Evidence: drag feel ("feels really good" → "way better"); triple in the 18 Nov build; brief 10; fix-round decision 13; our-events.md §2.*

2. **A time limit is a design choice. Name it, and reopen the work when it lifts.** Brief 10's frozen holds produced the 4-frame wind-up and the 0.3 s death. The worker flagged both as timid. The owner lifted the limit on 18 Nov, nobody went back, and on 24 Nov his first complaint was the wind-up and his next was deaths. *Evidence: fight-beats.md "Timing ceiling"; run log 21:55; owner note 2026-11-18b; PLAN.md and PLAN-animation-practice.md quotes.*

3. **"Keep" must mean "judged good against a reference", not "not touched".** Tag unjudged rows "not reviewed", and don't let them pass on a blanket yes. Deaths were "keep (motion)" in the fix round because nobody proposed a change. *Evidence: anim-fight NOTES, Deaths row; "Re-created 'keep' items … are rough copies"; the owner's 24 Nov "death animations in general might need work".*

4. **Show two options, differing in one thing, at real speed, with a way to slow them.** The triple's two paces (same script, one change) worked. Seven panes didn't: "very hard for me to pinpoint". Options 2 frames apart inside a fixed budget weren't a real choice either. *Evidence: triple-beats.md `pace-candidates.mp4`; PLAN-pass-2.md second reply; brief 10 `windup-candidates.mp4`.*

5. **A reference number is a candidate, not an answer.** When the owner hasn't felt it, film it against the alternative. The best proposal picked a linear strike because Battlegrounds measures linear, and the owner called it "very bad". *Evidence: plans/best.md CB3; PLAN-pass-2.md.*

6. **Fix ordering before polishing motion.** In a fight, much of the bad feel is when things play, not how one card moves: an attacker frozen at contact for 23–41 frames while a trigger plays, every trigger its own 0.3 s step. Brief 10 polished the lunge with grouping out of scope; the triple had no ordering problem to hide. *Evidence: brief 10 "Not in scope"; our-attack-measured.md "Hold at contact"; the owner's "I don't think they pause mid-animation".*

7. **Measure at the motion's own scale, and measure what the eye sees.** 10 fps strips can't time a 4-frame wind-up (fine for the triple's 0.2–0.4 s beats). Logging only positions missed rotation, which the owner noticed first. Add angle, scale and lean to the table, and read references at 60 fps. *Evidence: fight-beats.md method; our-attack-measured.md; PLAN-pass-2.md "Battlegrounds' angle was searched but never saved".*

8. **Pick references of the same moment, done well, and few of them.** The triple's five clips all showed three-become-one. Brief 10's eleven spanned five games and two player-driven systems, against the owner's "4 or 5". A feeling as the bar ("the same sense of excitement") gave the triple a target each beat could serve. *Evidence: reference-clips README; sources/2026-11-17a.*

9. **Check drawn pixels, prove the check fails on the broken version, and say what no check saw.** The triple did all three; the shop glow's pulse never drew while its test passed. Reviews and councils catch correctness, not feel (the council's 13 findings had no feel item), so don't spend them as a feel gate. *Evidence: triple-beats.md drawn-motion.json; run log 22:05; council-review.md.*

10. **Track accepted but unbuilt motion, and new faults found by watching.** Hero damage was proposed and accepted on 21 Nov, then dropped when the fight batch never started. Buffs and staggered deaths came up only when the owner watched clips. A living list of every animation, with its state (not reviewed, proposed, accepted, built, owner-liked), would have caught both. *Evidence: anim-fight NOTES "Damage to the loser's hero"; our-events.md §2; PLAN-pass-2.md second reply.*
