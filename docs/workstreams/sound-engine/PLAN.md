# Sound in the game: plan (approved 21 Nov 2026)

The owner's words (21 Nov, dictated, as heard): "I gave neon feedback, so you can now begin the next round. And we should probably run inside this repo, right? Anyway, let's get Nissan's into the game. Trust Neon to build the sound files and then have Opus models implement them based on its instruction. They can collaborate with it" *[probably "these sounds"]*

The owner approving it (21 Nov): "I approve the plan Put the mute in the pause menu on a volume slider as well". So step 1 also adds a volume slider and a mute to the pause menu.

Split: Neon (Gemini, branch `sound/files`) makes the files and says how they are used. This session (Opus, branch `sound/engine`) builds the code that plays them, the checks and the PRs to `dev`.

## How Neon and this session work together (agreed with Neon, 21 Nov)

- Neon owns `assets/audio/` (files in `sfx/`, the cue table `cues.json`, `SOURCES.md`), make scripts in `tools/sound/`, and its instruction in `docs/workstreams/sound/audio-spec.md`. It sets the table's fields; this session reads what it writes.
- This session merges `sound/files` into `sound/engine` and opens the PRs to `dev`. It never edits Neon's files; problems go back to Neon by thread message.
- Neon is making the fight hits first: three weights around Ladder 4 (the owner's favourite, from the Ladder 3–5 range), five takes each.

## What the game does today (measured, 40 bot games)

No sound code. Playback speed is fixed at 1. A fight lasts about 20 s (p90 28 s). Sound-worthy steps come at least 0.3 s apart, at most 4 in a second. 74% of hit steps land two hits at once, up to 7 with area hits. Shop per turn: buy 2.7, play 3.3, sell 1.4, refresh 0.8, tier up 0.4, triple about once a game.

## Steps

1. **Fight hits in the game.** `src/sound/`: one player that reads Neon's table, with its own random source and a limiter on its own sound bus. One call per step in the fight screen's playback (`src/screens/fight/fight_screen.gd`), agreed with the fix round. Only the fields and cues Neon's instruction asks for. Placeholders until Neon's hits land: the trial's `ladder-3/4/5.wav`.
2. **Neon's hits in, Windows build to the owner** with a short note on what to listen for. The owner's verdict decides what comes next.
3. **The rest in batches as Neon delivers them** (Wave 2, 21 Nov: the rest of the fight; Wave 3: shop actions), each heard by the owner before the next. The shop hook in `src/game/game_controller.gd` is agreed with the ghost build session first.

## Checks for each step

- `scripts/check.sh` (tests, type check, lint).
- Sound never changes a fight: it reads only the finished fight's replay. A check fails if anything in `src/core` refers to sound. No core file changes, so ghost and Rust comparisons are untouched.
- A real fight played through the fight screen logs every cue asked for, checked against the cues its steps call for (`tests/sound/test_sound.gd`).
- The Windows export carries the files and the game plays them without errors.
- Only if the owner hears clipping: mix the busiest fight offline and measure its peak.
- What no check can tell: whether it sounds right, and how late the sound comes on the owner's hardware. Only the owner, on a Windows build.
- A fresh scope reviewer on each step's commits before it merges into `dev`. Nothing goes to `main`.
