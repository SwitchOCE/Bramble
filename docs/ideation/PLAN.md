# Ideation plan

<!-- status -->
- **In short:** Just started: agents are building the best vanilla version of the game they can, making every open call themselves.
- **Status:** active
- **Last step done:** Branch set up from the prototype, the rules, the design lab and the portal's decision cards (6 Nov 2026).
- **Next step:** The orchestrator's first plan: what "very good" means, and the order of work.
- **Waiting on you:** Nothing. Play any ideation build whenever you like.
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
4. **Bots worth beating**, with difficulty levels, so "how far can I get" means something.
5. **Release feel**: one look applied throughout, art on every unit, readable text on phone and PC, clear feedback in fights, a how-to-play, settings, no crashes in long automated runs.
6. **Delivered**: Windows and Android builds on the portal, with a playtest guide.
7. **Agreed**: at least three fresh reviewers, each playing the build independently, judge it very good for a playtest, and the open items they agree on are fixed.

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
