# Prototype plan (overnight, 3–4 November 2026)

Branch family `proto/*`, merged into `proto/main`. It never merges into `main`. Nothing here is final: it is for the owner to get hands-on with the game and react.

## The owner's words (3 Nov, ~23:45)

> "Then overnight, what I want is for as much stuff that will represent forward progress to be done. You can create a new isolated work tree and or work trees and a branch that can sit quite, you know, essentially almost a fork at that point. … that can push on and try and get a complete build going so that I can play test things and iterate. I think I'll have better responses to these kinds of things once I get my hands on them. Mocking up and, you know, trying to create early versions of things will do a world of good. Keep in mind that nothing needs to be final in this branch. It's more for prototypes, right? It's for me getting my hands on things and getting a feel for stuff. We can take coding lessons and gotchas from it, and we should take any … learnings from the prototyping phase. Things that went well, things that went wrong, to help, you know, set up issues, you know, permissions issues, anything like that, should be recorded to some sort of, like, log so that we can prevent those issues in the future. … I want you to forge ahead, install Godot, do what's required, use some tokens."

## The goal

By morning: a build the owner can play on Windows (and Android), that plays a full game of Bramble by the current rulebook against bot opponents, using the units already designed in the mechanics library. Plus a log of what was learned building it.

## What the build contains

1. **The recruit phase** by rulebook v0.4: gold, buying, selling, refresh at the owner's schedule, freeze, tier-ups, the hand, triples and golden units, the shared pool.
2. **The 4–3 brick board** with fixed slots, drag to place and move.
3. **Combat** by rulebook §9: front row then back row, back-row protection, Taunt within the row, summons into slots, death resolution. Played back on screen step by step, with speed control, skip and a text log.
4. **A full game**: you and 7 bot opponents. Async snapshot fights against bot boards, hero damage and elimination per rulebook §10. No heroes (they have never been discussed with the owner).
5. **Content**: a pool of about 40 units taken from the mechanics library's example units, chosen to cover the shortlisted mechanics, Nightshade, position text and the tribes on the longlist. Units are data files, so adding or changing one doesn't need code.
6. **A sandbox**: build any two boards from any units and fight them. This is how the owner tries a single mechanic (for example Nightshade against a tall board).
7. **A dev panel**: seed, add gold, spawn a unit, set the tier, skip turns.
8. **Look**: placeholder cards with tribe colours in the spirit of Ink + flat B. If time allows, Codex portraits for the units in that style.

## Where gaps get filled

The rulebook and library leave things open. The prototype picks something so it runs, and lists each pick in `PLAYTEST.md` under "Things the prototype just picked". These are not decisions; they are things for the owner to react to after playing. The rulebook's proposed defaults are used first. Nothing in `docs/design/` changes.

## Steps

| Step | Who | Branch | Files it owns |
|---|---|---|---|
| 0. Toolchain on this machine, branch, logs | orchestrator | `proto/main` | `docs/prototype/` |
| 1. Spec: rule subset, unit list, the API between rules and UI | spec agent | `proto/spec` | `docs/prototype/SPEC.md`, `content/units/` |
| 2a. Rules core: data, effects, combat, recruit phase, bots, game loop, tests | core worker | `proto/core` | `src/core/`, `tests/core/` |
| 2b. UI against the spec's API with a stub game | UI worker | `proto/ui` | `src/ui/`, `assets/ui/` |
| 2c. Optional: unit portraits with Codex | art worker | `proto/art` | `assets/units/`, `tools/art/` |
| 3. Integration: wire UI to core, sandbox, dev panel, exports | integration worker | `proto/integrate` | anything, after 2a/2b merge |
| 4. Playtest pass: bot-vs-bot games, a scripted run through the UI, bug list, fixes | QA + fix workers | `proto/qa-*` | as found |
| 5. Hand-over: builds, `PLAYTEST.md`, `LEARNINGS.md`, a morning report | orchestrator | `proto/main` | `docs/prototype/` |

Steps 2a, 2b and 2c run in parallel in separate worktrees with no shared files.

## Gates for each step before it merges into `proto/main`

- **Runtime:** `scripts/check.sh` passes; GUT tests pass; for UI steps, native-size screenshots that the orchestrator looks at; for step 3 onward, the exports build and the Linux build boots.
- **Scope review:** the `scope-reviewer` agent on the step's commits, briefed with the owner's words above and this plan.
- The owner is asleep, and asked for the work to go ahead. So, on this branch only: cut items get fixed before the merge; ask items are written into the morning report and work carries on when they don't block it. Anything that would change `main`, `docs/design/` or GitHub settings waits for the owner.

## Limits

- At most half the CPU (3 of 6 cores) and half the free memory (about 5 GB), checked before heavy runs. At most three workers running Godot at once.
- Long commands run in the background with a time limit.
- No new standing rules for agents (in CLAUDE.md, AGENTS.md or memory) without the owner's OK on the wording. Learnings go in the log freely.
- Builds go to `/data/bramble-builds/`, not into git and not into a public GitHub release.

## Logs

- `docs/prototype/LEARNINGS.md`: dated entries of what went well, what went wrong, setup and permission problems, engine gotchas.
- `docs/prototype/PLAYTEST.md`: how to get and run the builds, what to try, and the prototype's picks.
