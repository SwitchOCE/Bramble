# Ideation plan

<!-- status -->
- **In short:** You ended this run at build 8 (note 10g). The A3.5 dials, the neutrals, the soak fixes and the fight-screen declutter are merged. What's left is the Oozes' new values, one smaller run that sets every other tribe's numbers, and the export.
- **Status:** active, ending at build 8
- **Last step done:** 10 Nov:
  - Merged: A3.5's dials (c5e65925), the neutrals with the soak's Egg and release fixes (4df1c876), and declutter batch 2 (54d7fb78).
  - The 200-game soak on the merged pool: 0 violations in 160 games played. The 40 field-rival games need the rebuilt field library.
  - The Ooze probe: their problem is the numbers. Arm b takes the engine line's R12 median from 352 to 1,205 on the same seeds.
- **Next step:**
  - The Ooze values: merging main, then the gate.
  - The measurement run: four dial settings on 32 seeds, a fit per tribe to 900 at R12, and one confirming run.
  - Build 8: rebuild the field library, export with the usual checks, point `latest` at it.
  - Then the end-of-run report and the process proposal (note 10g), and the run stops.
- **Waiting on you:** Nothing until build 8 is out.
- **Scope:** Only what build 8 needs (note 10g). Parked work: `PARKED.md`. One review per step, plus the test gate.
<!-- /status -->

Branch family `ideation/*`, merged into `ideation/main`, worktrees at `~/code/Bramble-ideation*`. **It never merges into `main` without the owner's say-so** (CLAUDE.md).

## The owner's words (6 Nov 2026)

The full record is `docs/design/owner-notes/2026-11-06a-ideation-branch.md`. The core of it:

> "In ideation branch, I want agents to make decisions without me. They're fully empowered to just try and make the best version of the game based on what I've said, things that I've said in the past, etc. They can iterate as much as they want. And if multiple reviewers independently agree on the same thing, you should just keep iterating along that branch. Treat it almost like a slash goal."

> "Its goal would be to oversee just continuous iterative development until it gets the game to a very good state from a playtesting perspective. It needs to focus on interesting designs and strategic depth. And it needs to get a vanilla version of the game up and running. Don't worry about Battlegrounds' extra mechanics like trinkets and quests, etc. Like dark gifts, Darkmoon Faire, all of that: not needed, not required."

> "Agents' jobs are to take what we've got now, what's known, and just run with it. Make the best game they can. If something's still up for debate, make a choice, make a decision. It's okay to be inspired by other games. It's okay to deviate from the other games. The goal is to give me something really high quality that I can playtest, almost like it's ready for a release, via the agents' tastes, and that I can just try out and see how far I can get with it."

## The goal

A vanilla Bramble the owner can download from the portal and play like a finished game: one they can't tell is a prototype, where they keep finding new strategies, and where good bots push them to see how far they can get.

**Vanilla means** the core loop and nothing bolted on: the recruit phase, the shop and its tiers, gold, refresh, freeze, the hand, triples, the 4–3 board, combat, hero damage, an 8-player lobby, and the content pool that makes it all interesting. **Out:** trinkets, quests, Darkmoon Faire, dark gifts, anomalies, buddies, seasonal or rotating systems, and anything else layered on top of the core loop. Whether heroes and hero powers, or tavern spells, count as core is the agents' call, logged with the reason.

## Starting point

- `proto/main`: the playable Godot build (build 4), its spec, picks, questions and learnings in `docs/prototype/`.
- `design/tribes-and-budget`: the rulebook, power budget, archetypes and the 75-mechanic library in `docs/design/`, plus every owner note.
- `design-lab/main`: the visual directions and their scores in `docs/design-lab/`.
- `portal/main`: the 36 decision cards in `docs/decisions/`. Each is an open question with the evidence and a suggestion. On this branch they are the agents' to settle.
- The owner's direction: `docs/design/direction-summary.md` and `docs/design/owner-notes/`. These outrank everything else; deviate from them only for a reason you'd defend to the owner, and log it.

## Done means (the orchestrator's first job is to sharpen this; it may add criteria, and drop one only with a logged reason)

1. **The whole vanilla game** plays start to finish: 8 players, every tier, the full economy, a real content pool with several tribes deep enough to build around.
2. **Strategic depth**, shown by evidence and not asserted: bot-vs-bot simulations show several different strategies that can win, none dominant; a strong bot clearly beats a naive one; reviewers who play it find real decisions most turns.
3. **Interesting designs**: units and tribes with their own identity, from the mechanics library and new ones, not a re-skin of Battlegrounds.
4. **Bots worth beating**, at one strength: the best bot, so "how far can I get" means something.
5. **Release feel**: one look applied throughout, art on every unit, readable text on phone and PC, clear feedback in fights, a how-to-play, settings, no crashes in long automated runs.
6. **Delivered**: Windows and Android builds on the portal, with a playtest guide.
7. **Agreed**: at least three fresh reviewers, each playing the build independently, judge it very good for a playtest, and the open items they agree on are fixed.

## Done means, sharpened (orchestrator, 6 Nov 2026)

*Superseded where the 10 Nov revision below differs; kept as the record.*

Numbers are starting bars; tightening is free, loosening needs a line in `DECISIONS.md`. Evidence goes in `docs/ideation/evidence/`.

1. **Whole game.** A human can pick a hero and play 8-player games to the end through the real UI. Pool, reached in stages (2, then 4, then 6): at least 6 tribes of 12+ units each across tiers 1–6, plus neutrals and 10+ tavern spells; each lobby uses all six unless measured shop thinness justifies rotation (7 Nov call in DECISIONS.md). No filler stat-line units unless a reviewer would call it a deliberate vanilla body. Evidence: 2,000-game soak with rules checks, 0 violations, 0 crashes.
2. **Depth.**
   - Sim: 8 pinned strategy bots in a lobby, 2,000+ games. At least 5 distinct strategies (tribe plus archetype shape) each win 6–25% of lobbies they appear in. Nothing above 25%.
   - Skill: Naive means legal random-ish play with no synergy logic (buys what it can afford, places at random). 1 best bot among 7 Naive places top-4 at least 85% and wins at least 45%. The current best bot clearly beats the previous best head to head on fresh seeds (orchestrator's plan following the 8 Nov direction: `docs/ideation/BOTS.md`).
   - The win-spread bar measures bot skill as well as the game. Don't tune to it alone. The owner warns economy tends to be best at high level (02h), which weak bots hide, so reviewers check economy by hand.
   - Position matters a bit, and differs by opponent (replaced 8 Nov: `evidence/placing-bar-ruling.md`). Take 100 mid- and late-game boards from bench games (5+ units, pool as it stands), each paired with the opponent board it really fought, keeping fights the rule layout wins 20–80% of the time. (a) The best layout found against that opponent wins at least 5 points more than the rule layout, with the 95% interval above 0. (b) The answer depends on the opponent: a layout searched against another real board from the same round scores at least 5 points less against the real opponent than the layout searched against that opponent (95% interval above 0; changed 8 Nov on the placing review's simplify, because "differs from the rule layout" passes for any imperfect rule). (c) Most fresh playtesters name a fight that placement won or lost for them, or a placement they changed to answer an opponent. Search against shuffled placement stays as a smoke line with no bar: near 0 means placing is broken.
   - Reviewers who played: a real decision on most turns, and they found at least 3 builds that felt different.
3. **Interesting.** Every tribe has at least one signature mechanic Battlegrounds doesn't have. Every tribe has some economy (owner, 02h). Reviewers don't call it a re-skin.
4. **Bots.** One strength: the best players we can make, in several flavours with different strategic quirks (owner, 8 Nov: "No easy, no medium bot."). "How far can I get" shows as a visible record: best placement and wins. The current implementation uses today's Hard policy; Naive is tools-only.
5. **Release feel.** One look throughout, no switcher. Unique art on every unit, hero and spell. Text readable on phone (nothing under the phone minimum; full text one tap away). Fights read clearly, through animation and feel rather than static labels, arrows or a running log: who hits, what triggered, why it died. The main game space assumes a player who knows the rules: no tutorial text, rule reminders or static pointers on the board. Teaching lives in a tutorial and how-to-play, and full rules text is one tap away (owner, 9 Nov: `docs/design/owner-notes/2026-11-09e-ui-clutter-and-tutorials.md`). Fight and UI sound. A tutorial, how-to-play, settings, game-over summary, no dev tools in the player's path. 20 scripted full UI games at phone and PC sizes without a crash or a layout failure.
6. **Delivered.** Windows and Android builds on the portal, each with a `README.txt`, and `PLAYTEST.md`.
7. **Agreed.** Three fresh reviewers who each played full games say "very good for a playtest", with their agreed items fixed. Agents can't feel a phone: phone checks are layout measurements and screenshots at phone size, and the playtest guide says no real device was tested.

**Reviewers can really play:** agents can't drag cards, so `tools/play/` lets an agent play the real game by commands, and a scripted UI driver produces screenshots of the same game.

## Done means, revised 10 Nov (orchestrator; `plan-to-done.md` §4)

**This section decides whether Done is met.** The base text and the 6 Nov sharpened bars above stay as the record. Each change is listed below beside the 6 Nov line it changes, with its kind; every loosening's reason is in its row, in `plan-to-done.md` §1.12 or in DECISIONS ("Plan to Done v3 approved", "Done means: fidelity check calls", "Done means: re-check calls"). Each criterion has at most two deciding items (owner, 09i: "Get good at one or two things and then start fixing other issues"). A checklist item is a fact or test that must hold. A reported item is triaged only on an extreme miss. These bars were written before A4's numbers exist, and they don't move to fit them.

**Lines the table doesn't change still bind** (fidelity check, 10 Nov: `evidence/plan-to-done/done-means-fidelity.md`). Every line of the 6 Nov text that no row below changes is still part of Done, and the criteria restate the ones a reader could miss: the pool target, unique art, full text one tap away, and the declutter line. Such a line is a checklist item unless the criteria name it as reported. The 6 Nov text's own stand-ins apply: agents can't drag cards, so "a human can pick a hero and play … through the real UI" is met by the scripted UI games and `tools/play/`, and "reviewers check economy by hand" is a reported question in the final brief.

**What changes a bar** (re-check, 10 Nov: `evidence/plan-to-done/done-means-recheck.md`). Each of these changes the bar and needs a DECISIONS entry first:
- editing a threshold in `tests/ui/layout_check.gd` (`SLACK`, `OVERLAP_SHARE`, `MIN_FONT`, `DESKTOP_RULES_FONT`, the tap minimums);
- adding or removing a line in `tools/sim/lines/` after A4's commit;
- changing the final brief's questions.

### Each change beside the 6 Nov text

| # | 6 Nov sharpened text (quoted) | v3 | Kind |
|---|---|---|---|
| 1 | "each lobby uses all six unless measured shop thinness justifies rotation" | five of six tribes per lobby (DECISIONS 8 Nov, "Commit review B", item 7) | logged 8 Nov |
| 1 | "No filler stat-line units unless a reviewer would call it a deliberate vanilla body" | restored 10 Nov: every unit without rules text is listed in the final brief; a unit called filler by 2+ final reviewers fails it, and a listed unit no reviewer calls filler counts as a deliberate vanilla body | loosening on "a reviewer" to "2+ reviewers", like the re-skin row. Reason: 06a, "if multiple reviewers independently agree on the same thing" |
| 1 | "2,000-game soak with rules checks, 0 violations, 0 crashes" | kept, on S4's mix, plus "no unit without a set appears" | tightening |
| 2 | "At least 5 distinct strategies … each win 6–25% of lobbies they appear in. Nothing above 25%." | field fights at R10, R12 and R14 decide. The band is reported | loosening, §1.12 |
| 2 | "1 best bot among 7 Naive places top-4 at least 85% and wins at least 45%" | **kept, as a checklist item at J2** | unchanged |
| 2 | "The current best bot clearly beats the previous best head to head on fresh seeds" | dropped | loosening, §1.12 |
| 2 | placing (a), (b) and (c) | all three reported. (c) is a verdict-brief question | loosening, §1.12 |
| 2 | "Reviewers who played: a real decision on most turns, and they found at least 3 builds that felt different" | "most final reviewers" report a real decision on most turns, and "together" they found 3 builds; decisions asked by round range | loosening (a reading): 6 Nov said neither "most" nor "together", and v2 read "each". Reason: 06a, "if multiple reviewers independently agree on the same thing, you should just keep iterating", which makes reviewers' shared findings the unit, not each reviewer alone |
| 3 | "Every tribe has at least one signature mechanic Battlegrounds doesn't have. Every tribe has some economy … Reviewers don't call it a re-skin." | an evidence file with a fresh check against `docs/research/battlegrounds/`; no tribe called a re-skin by 2+ final reviewers | the re-skin part is a loosening, §1.12 |
| 4 | "One strength … 'How far can I get' shows as a visible record"; base 4 "Bots worth beating" | kept, plus the default-opponent call; "worth beating" now decides (most final reviewers calling the rivals pushovers blocks Done) | tightening (restored 10 Nov) |
| 5 | "20 scripted full UI games at phone and PC sizes without a crash or a layout failure"; "Fights read clearly, through animation and feel rather than static labels, arrows or a running log: who hits, what triggered, why it died. The main game space assumes a player who knows the rules: no tutorial text, rule reminders or static pointers on the board." | kept, plus the script's own depth bar, a fixed slot table, and a cold reader who also checks the board for the owner's 9 Nov declutter line | tightening (the declutter line restored 10 Nov) |
| 6 | "Windows and Android builds on the portal, each with a README.txt, and PLAYTEST.md" | kept, plus the tag, the library SHA and `latest` | tightening |
| 7 | "Three fresh reviewers who each played full games say "very good for a playtest", with their agreed items fixed" | kept, plus `plan-to-done.md` §1.7's definition and §1.8's pass rule (no counted agreed item left) | tightening on who reviews and how; **loosening** on "fixed": C4 and 09d's power filter count only agreed items that pass the filter. Reasons: the power filter is 09d, the owner's own direction. C4 (an agreed item counts only if a reviewer who raised it wants it changed before this playtest) exists because every counted agreed item means a new build and a new trio, so without it the pass rule can loop (`plan-to-done.md` §7, "The pass rule can loop"). Every filtered-out item goes into PLAYTEST as a known issue |

### The criteria (these govern)

**1. Whole game.**
- **Checklist:**
  - The pool on the build 9 tree, counting only units with a `set`: six tribes of 12+ units each across tiers 1–6, plus neutrals and 10+ tavern spells (6 Nov target).
  - Every unit without rules text is listed in the final brief, and no unit is called filler by 2+ final reviewers. A listed unit no reviewer calls filler counts as a deliberate vanilla body.
- **Deciding:**
  1. 2,000 real `full_game` lobbies on the build 9 tree (S4's mix, on Actions): 0 violations, 0 crashes, and no unit without a set appearing.
  2. The 20 scripted UI games (shared with item 5) pick a hero and play 8-player games to game over.

**2. Depth.** 09d: "rely far more on empirical simulation data than on observational bot play"; "I don't want you to force it". 09c: tribes "the same order of magnitude".
- **Deciding:**
  1. **Field fights at R10, R12 and R14**, on the shipped default preset. Each committed line's boards from that round, plus each tribe's designed strong board, fight the round's field, with placer layouts and both orientations.
     - It passes when at least 5 lines from at least 4 tribes beat the field in 40%+ of fights at R12 or R14, and no line or designed board beats it in 80%+ at both R12 and R14.
     - The 80% cap was checked on the Quilboar archives (`plan-to-done.md` §1.13), and its fallback is the order-of-magnitude read.
     - **The field, fixed before A4:**
       - The round's field is the shipped library's boards from that round, equally weighted per line.
       - Each line is scored against the field without its own boards.
       - A draw counts as half a win.
       - A committed line is one in `tools/sim/lines/*.json` at A4's commit. Hedgerow's line lands with wave 2b, before A4.
       - A designed board isn't in the field, so it is scored against the whole field.
     - First read at A4, where a miss is cut at the outlier dial. Decided at J2. The bar never moves.
  2. **Reviewers:** most final reviewers report a real decision on most turns, and **together they found at least 3 builds that felt different.** Decisions are asked by round range (R1–5, R6–10, R11+), and each reviewer also answers one overall question ("a real decision on most turns?"). The overall answers decide, and the ranges are reported.
- **Checklist:** the Naive check (J2): 1 best bot among 7 Naive places top 4 in at least 85% of 300 games and wins at least 45%.
- **Reported:**
  - line-lobby firsts (the 6–25% band);
  - answers against carries, and distribution against totals;
  - placing (a) and (b), rerun once on the build 9 tree at J2 (an extreme miss is an interval that includes 0);
  - placing (c), from the verdict brief;
  - decisions in R1–5. If round 6 agrees they're thin, W-g triages it (see C6).

**3. Interesting.**
- **Deciding:**
  1. `evidence/interesting-designs.md`, from shipped content. For each tribe: its signature, the nearest Battlegrounds analogue and why it differs, and an economy card tied to the tribe's own action (02h). A fresh reviewer checks it against `docs/research/battlegrounds/`. It fails if the reviewer finds a tribe with no signature that Battlegrounds lacks, or no economy card tied to the tribe's own action.
  2. No tribe is called a re-skin by 2+ final reviewers. The brief asks about each tribe by name.
- **Reported:** tribe gold against neutral gold (the 02h risk), and Quilboar absent from the pack.

**4. Bots.** One strength (08a, 08b), and the dealt lines are the flavours (8 Nov).
- **Default-opponent call:** the strong field is the default on the default preset, if two things hold:
  - a field start adds at most 300 MB of peak memory over a normal start, on the Linux export;
  - the library loads from the APK and Windows packs, and fails loudly when missing.

  Otherwise the default is normal Hard lobbies, and the call is logged.
- **Checklist:** the build 9 export's default opponents are as called above, with the library SHA in the README and the library in the pack listing.
- **Deciding:**
  1. **Worth beating:** the final brief asks "were the opponents worth beating?". Done fails if most final reviewers answer no.
  2. The record (best placement and wins, default settings only) shows on the main menu and at game over, on build 9 screenshots at both sizes.
- **Reported:**
  - distinct dealt lines.
  - PLAYTEST says the rivals replay strong games and don't react to the player (the owner's 09a ghost question).

**5. Release feel.**
- **Checklist:**
  - one theme;
  - `portraits_pending.json` empty and `test_portraits` passing, and every unit, hero and spell with a `set` has its own art (Pelt wears its prey's, by design);
  - full rules text one tap away from every card on every screen, checked in the scripted UI run (it taps one card on each screen and finds the reader);
  - a sound for each new cue, unheard, and PLAYTEST says so;
  - the tutorial;
  - the Rules hub covering every keyword in the pool;
  - settings;
  - game over;
  - no dev tools in exports.
- **Deciding:**
  1. 20 scripted UI games on the build 9 tree, 10 at 1920×1080 and 10 at 1688×780: 0 crashes and 0 layout failures.
     - A layout failure is any fault `tests/ui/layout_check.gd` reports on a checked screen: a control leaving the window or its container, text that doesn't fit, overlapping cards, text under `UiTheme.MIN_FONT` (31 canvas units, which is 22 window px at 1688×780, 11 pt on a 2× phone), or a tap target under the minimum.
     - The script's own depth bar applies as written: 10 games reach turn 12, 3 reach turn 15, one is won, 3 ghost fights happen, and tiers 5 and 6 are reached.
     - The scripted player is Hard.
     - The slot table is fixed before the run: at least 10 games at default settings, and the rest in lobbies chosen to reach the late game. There is no fallback bar.
  2. A fresh cold reader passes build 9's fight strips at batch 1's bar: who hits, what triggered, and why it died. These must be read from motion and marks that end with their moment (09e: "through animation and feel rather than static labels, arrows or a running log"). A moment the reader gets only from a static label, a lasting arrow or a running log doesn't count. The same reader checks build 9's recruit and fight screenshots at both sizes against the owner's 9 Nov line: "no tutorial text, rule reminders or static pointers on the board" (09e). Any one found fails it.

**6. Delivered.**
- **Deciding:**
  1. The build folder holds `Bramble.apk`, `Bramble-windows.zip` and `README.txt`.
     - README line 1 has no parentheses.
     - It names the commit tag and the library SHA.
     - `latest` points at the folder, and the portal's `/builds` lists it.
  2. PLAYTEST.md matches that build, is frozen at its commit, can be reached from the portal, and says no real device was tested.

**7. Agreed.**
- **Deciding:**
  1. 3+ fresh reviewers each play 2 full games of the build as defined (`plan-to-done.md` §1.7), and say "very good for a playtest".
  2. No problem is raised by 2+ of them (`plan-to-done.md` §1.8, with 09d's filter and C4's definition), and round 6's agreed items are fixed.

**Checkpoint 1:** keep its two criteria. Criterion 2 is read on the same cohort (`plan-to-done.md` §1.14). W-c fixes the brief.

## Calls made up front

Full reasons in `DECISIONS.md`.
- **Spells are in** (owner, 2 Nov: "Spells are going to be part of the game, for certain"; "Like Battlegrounds").
- **Heroes are in**, small roster with one simple power each. They are Battlegrounds' main source of "every game plays differently" and don't sit on top of the loop the way trinkets do.
- **One-player against bots, no turn timer.** The live lobby stands for this build.

## Order of work (revised 6 Nov after the plan review; review in `evidence/plan-interrogate.md`)

The review's main point: the first plan designed all content before anyone played it. So play a small slice first, and grow it only when it holds up.

1. **Position test.** Does where you put units matter? A placer that searches arrangements, plus 12 position units on today's engine, against shuffled placement. Bar: at least 0.5 of a place better. If it fails, fix targeting and row rules, or redesign position text, before designing tribes.
2. **Blocking calls and the look.** Settle only what the slice needs (the suggested answers stand unless logged otherwise), and pick the look in one pass.
3. **The slice.** 2 tribes plus neutrals, heroes, spells, Engine v2 (stat layers, recruit triggers, spells, Discover, lobby tribes, heroes; rule queries only as far as those need), `tools/play/`, strategy bots at one best strength, the sim bench, and the chosen look. Ship a build.
4. **Fresh reviewers play the slice.** Fix what they agree on. If they don't find real decisions, change the design rather than add content.
5. **Grow:** to 4 tribes, then 6, repeating sim and reviews at each size.
6. **Finish:** art for what survived balance, phone polish, how-to-play, settings, records, fight and UI sound, delivery, final reviews.

A build goes out at step 3, and after each meaningful improvement. Music is deferred until the final-review build shows it is wanted. Expert-bot work is not deferred: it proceeds under one best-bot name (BOTS.md). The portal inbox is read at each build.

## How work runs

- **The orchestrator** (the session the owner started) plans, briefs workers, runs reviews, merges into `ideation/main` and exports builds. It decides; it does not wait on the owner.
- **Workers** each get their own branch `ideation/<topic>` and worktree `~/code/Bramble-ideation-<topic>`.
- **Gates before a merge:** the runtime gate (`scripts/check.sh`, the GUT tests, exports that build and boot, screenshots the orchestrator looks at, simulations where balance is touched), and an independent review by a fresh agent (`scope-reviewer` for code steps, briefed with the owner's words above and this plan). Cut items are fixed before the merge. Ask items are the orchestrator's to decide, logged in `DECISIONS.md`.
- **Agreement:** for design choices, get two or three independent reviews that don't see each other. Where they agree, act and keep going. Where they split, the orchestrator picks and logs why.
- **Iterate on evidence:** playtest by simulation and by fresh reviewer agents playing the build, change, re-test. Balance tuning and win-rate targets are allowed here.
- **Builds:** each meaningful improvement is exported to `/data/bramble-builds/<mmdd-hhmm>-ideation<N>/` with a `README.txt` whose first line is `Ideation build <N>: <what's new, in plain words>`, and `latest` points at the newest good one. The portal lists them.

## Logs (keep them current; they are how a resumed session picks up)

- `DECISIONS.md`: every open question the agents settled, with what was picked and why, newest first.
- `LOG.md`: what was done, what's in flight, what's next.
- `LEARNINGS.md`: gotchas and what went wrong, in the prototype's format.
- `PLAYTEST.md`: how to get and play the latest ideation build, and what changed.
- The status block above, in the owner's plain voice (`docs/portal/WORDING.md`).
