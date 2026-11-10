# Interrogation of the look-and-feel plan (draft, 10 Nov)

The owner asked for three things: a UI/UX-only phase, headless "computer use" so agents can feel the scenes, and a process that avoids last run's problems. The plan covers all three. These are the findings, most important first.

## Findings, each with a change

1. **It clashes with `docs/ideation/plan-build9.md`.** That file is untracked, comes from note 10i earlier the same day, is all balance work, and is also called "build 9". The owner's later words say "solely… nothing balance". **Change:** say plainly that plan-build9 is shelved for this phase. Give the UI build its own number, and log the call in DECISIONS.

2. **Phone size is wrong.** Step 0 says 1080×2340 portrait. The game is landscape (`project.godot` orientation=0), and every UI tool and layout check uses 1688×780. `CLOUD_SETUP.md` says orientation "is held for the UI and UX phase; the owner leans to portrait." Portrait means re-laying out the whole game, which is a focus item in its own right. **Change:** step 0 shoots at 1920×1080 and 1688×780. Portrait goes on the day-1 list of candidates, tied to the open "phone-first" call.

3. **"One display per agent, in parallel" fights the Godot slots.** `scripts/godot_slot.sh` allows two local slots. A live look session keeps Godot open the whole time, so two agents looking would block the gate. That is the lock waste the owner raised in note 10a. **Change:** look sessions take their own slot class, capped at one or two. During the phase the gate runs in the cloud.

4. **Clips: scrot can't time animations.** Polling screenshots under llvmpipe misses 0.1–0.2 s lifts and hit-stops, and timing is in scope. **Change:** record clips with Godot's `--write-movie`, which writes fixed-fps frames whatever the real speed. Build contact sheets and GIFs with Pillow, which the repo already uses. Skip ffmpeg unless video is needed.

5. **Day 1 redoes known work.** `ui-declutter-spec.md` already has unbuilt batches 3 (HUD and lobby) and 4 (tutorial and Rules), reviewer questions (section 6), and `evidence/declutter/visual-comparison.md` with sources for the reference shots. **Change:** the gallery lists batches 3 and 4 as candidates beside its new findings, reuses the comparison sources, and asks reviewers the spec's section 6 questions.

6. **"Build both looks behind a setting" doubles the work.** An agent proposed it. It doubles the build, the tests at both sizes and the settings code that stays behind. **Change:** show alternatives as stills or clips in the mid-loop gallery. Build a setting for at most one pair per loop, and only when the owner can't pick from the clips.

7. **The step-0 proof is heavy.** A full game is 11–14 turns, which is hundreds of screenshot round trips. **Change:** proof is a fresh Codex worker that finishes one recruit turn and one fight, and reaches game-over from a jump. The day-1 gallery covers full play.

8. **Replay jumps are new work the states already cover.** `tests/ui/shots/screenshot.gd` has about 55 named states (recruit_late, combat_mid, game_over and more). **Change:** jumps use those states. Replay jumps wait until someone needs a scene they lack.

9. **game-design-process is a mechanics skill**, and this phase has no mechanics. **Change:** take it off the default skill list and keep design-critique, accessibility-review and ux-copy.

10. **Owner prework could stall the start.** It asks for four things before work begins. **Change:** give a default for each (N=3, sound out, batch 4 in, PC landscape first). The run starts on the defaults unless the owner overrides them.

## Table

| Item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| Scope fence + path check | Yes ("purely UI") | Owner's words | Keep | Enforces it |
| Step 0 look tool | Yes (headless feel) | Owner's words | Shrink | Landscape sizes, movie clips, existing states (2, 4, 8) |
| Parallel displays | Partly | Agent | Shrink | Slot cap (3) |
| x11vnc watch | Barely | Agent | Defer | Until the owner asks |
| Full-game proof | Yes | Agent | Shrink | (7) |
| Day-1 gallery | Yes | Agent, after 09f | Keep, reuse spec | (5) |
| Two looks behind a setting | Partly | Agent | Shrink | (6) |
| One-page DECISIONS, short RESTART, fresh session | Yes (process) | PROCESS-PROPOSAL | Keep | Fixes last run's process load |
| Three-line "done", N-day end | Yes | PROCESS-PROPOSAL | Keep | |
| Default skills | Partly | Agent | Shrink | (9) |
| plan-build9 | No | 10i reading | Ask, then shelve | (1) |

## Fixed after

- **Headless eyes:** after step 0's proof.
- **The process plan:** once the owner approves this plan.
- **Look and feel:** the owner sees a diagnosis on day 1 and a better build only at loop end. That is the main finding, and it's fine for a 3-day loop.

## Smallest plan

1. Shelve plan-build9.
2. Step 0, cut down.
3. Day-1 gallery (spec batches plus new findings).
4. Two focus items.
5. Mid-loop gallery.
6. Export.

## Deferred

| What | Trigger |
|---|---|
| Replay jumps | A scene the named states lack |
| Portrait | The owner picks phone-first portrait |
| VNC | The owner wants to watch |
| Look variants behind settings | The owner can't choose from clips |

## Checkpoints

After step 0's proof, after the day-1 gallery (the owner picks), and at the mid-loop gallery.

## Open questions for the owner

- Is plan-build9 shelved for this phase?
- Portrait now, or later?
