# Ideation plan

<!-- status -->
- **In short:** The game is flat because our costing method capped growth. The fix is under way: the shared mechanics are in, six tribe redesigns are written on paper, and the harness that measures strong scripted play is close to done. Birds and Fairies are being built. Next is a scale build for you to play.
- **Status:** active
- **Last step done:** Shared scale mechanics merged. Pass 3 tribe designs and the cross-tribe calls committed (`content/pass3/`), with one target table (`evidence/reference-curves.md`).
- **Next step:** Finish the harness (Sol, `ideation/harness`): the fair line-strength test, then the lever sweep. Wave 1, Birds and Fairies, is being built alongside it (Sol, `ideation/wave1`). Then the lever pick and scale build 8a (checkpoint 1).
- **Waiting on you:** Nothing. Four optional questions in `fundamentals.md` §4; my defaults stand until you answer.
- **Scope:** Fun first, then balance; simulations over bot play (owner, 9 Nov).
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
5. **Release feel.** One look throughout, no switcher. Unique art on every unit, hero and spell. Text readable on phone (nothing under the phone minimum; full text one tap away). Fights read clearly: who hits, what triggered, why it died. Fight and UI sound. How-to-play, settings, game-over summary, no dev tools in the player's path. 20 scripted full UI games at phone and PC sizes without a crash or a layout failure.
6. **Delivered.** Windows and Android builds on the portal, each with a `README.txt`, and `PLAYTEST.md`.
7. **Agreed.** Three fresh reviewers who each played full games say "very good for a playtest", with their agreed items fixed. Agents can't feel a phone: phone checks are layout measurements and screenshots at phone size, and the playtest guide says no real device was tested.

**Reviewers can really play:** agents can't drag cards, so `tools/play/` lets an agent play the real game by commands, and a scripted UI driver produces screenshots of the same game.

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
