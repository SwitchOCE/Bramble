# Prototype plan (overnight, 3–4 November 2026)

<!-- status -->
- **Status:** waiting on you
- **Last step done:** Build 4: a full game against 7 bots, with the sandbox and three looks (4 Nov 2026).
- **Next step:** Changes from your first playtest.
- **Waiting on you:** Play build 4; the 16 questions in `docs/prototype/OWNER-QUESTIONS.md`.
<!-- /status -->

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
5. **Content**: 12–16 units from the mechanics library's example units (the shortlisted mechanics, Nightshade, position text), with plain stat-line filler on every tier. Growing toward 40 comes only after the rest is stable.
6. **A sandbox**: build any two boards from any units and fight them. This is how the owner tries a single mechanic (for example Nightshade against a tall board).
7. **A dev panel**: seed, add gold, spawn a unit, set the tier, skip turns.
8. **Look**: placeholder cards with flat tribe colours. Landscape, with mouse and touch drag (a pick, logged).

## Where gaps get filled

The rulebook and library leave things open. The prototype picks something so it runs, and lists each pick in `PLAYTEST.md` under "Things the prototype just picked". These are not decisions; they are things for the owner to react to after playing. The rulebook's proposed defaults are used first. Nothing in `docs/design/` changes.

## Steps

Reordered on 3 Nov after a plan-interrogate review. Its main point was that the first playable build must come early, and everything after it widens a build the owner already has.

| Step | Who | Branch | Files it owns |
|---|---|---|---|
| 0. Toolchain on this machine, branch, logs, **delivery path** proven with an export of the empty project | orchestrator | `proto/main` | `docs/prototype/` |
| 1. Short spec: rule subset, state and event formats, the API between rules and UI, fixtures, 12–16 library units plus plain filler | spec agent | `proto/spec` | `docs/prototype/SPEC.md`, `docs/prototype/fixtures/`, `content/units/` |
| 2. **Walking skeleton**: recruit (buy, sell, refresh, tier up, board) and combat with playback against one bot, about 6 plain units. Core and UI in parallel (UI against the fixtures), then wired together and exported. **The owner has something to play from here on.** | core worker, UI worker, then integration | `proto/core`, `proto/ui` | `src/core/`, `tests/core/` / `src/ui/`, `assets/ui/` |
| 3. Widen, in this order: sandbox; library mechanics in priority order (shortlist, Nightshade, position text); the 8-player lobby with hero damage and elimination; freeze, hand, triples, golden; dev panel. Re-export after each merge. | workers | `proto/*` | as briefed |
| 4. QA: bot-vs-bot games and a scripted UI run, for crashes and rules bugs only. **No balance tuning and no win-rate targets.** | QA + fix workers | `proto/qa-*` | as found |
| 5. Hand-over: `PLAYTEST.md`, `LEARNINGS.md`, the morning report, opening with how to play in 2 minutes | orchestrator | `proto/main` | `docs/prototype/` |
| 6. Optional, only after a playable build is delivered: unit portraits with Codex. Folio character lineups are on hold (STATUS), so these would be placeholders, logged as a pick. | art worker | `proto/art` | `assets/units/` |

No general data-driven effects engine: combat and recruit hook points, with one script per mechanic. A new unit needs no code only when it reuses an existing mechanic.

**Delivery:** each export goes to `/data/bramble-builds/<time>/`, with `/data/bramble-builds/latest` pointing at the newest good one. From the Windows PC: `scp -r alex@mini-optiplex:/data/bramble-builds/latest .` (SSH key login from the PC was tested on 3 Nov). The Windows .exe is launch-tested under Wine on the server; the APK is debug-signed and installed by sideloading.

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
