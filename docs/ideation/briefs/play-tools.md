# Brief: play tools for testers and reviewers (plan to Done, stream S5)

Written by the orchestrator on 10 Nov 2026 for a cloud session. The routine's prompt points here.

Plan: `docs/ideation/plan-to-done.md`. Read §1 items 7 and 11, §2 rows A5 and A7, §3 row S5, and §4 criterion 7. You own `tools/play/**` and the new `src/ui/game_record_log.gd`, and nothing else. If another file needs a change, keep it to the smallest one and say why in your report.

Work on a new branch `ideation/c-play-tools` from `ideation/main` and push it. Before your final check, merge `ideation/main` into it again, because other streams land there while you work.

**Why:** the final verdict needs fresh reviewers who "each played the latest build". On this branch that means (§1.7):
- the same source commit as the export;
- default settings;
- played by `tools/play` commands;
- the reviewer's own turns and fights rendered by that commit's UI at 1688×780 and 1920×1080.

Checkpoint 1 also needs testers who play two presets blind. Today `tools/play` plays the real rules by commands (`tools/play/README.md`), but nothing renders a played game on the real screens, and nothing hides which preset a tester is on.

## What to build, in order

### 1. S5a: blind variants (needed before checkpoint 1)
`tools/play/play.sh new --seed S --variant X|Y` starts a game on a preset chosen by a mapping the tester can't see.
- **The mapping:** X and Y each map to a preset name in `content/pass3/rates.json` (today A, B and C). It's read from a file whose path is in the env var `BRAMBLE_VARIANT_MAP` (JSON, e.g. `{"X": "C", "Y": "B"}`). With no map, `--variant` is refused with a clear message.
- **The save:** it stores the preset itself, so it replays exactly without the map. But neither the screen, `log`, `--json` output nor the save's printed path may show the preset name. The orchestrator reads the preset from the save with a separate command, `play.sh <save> reveal`.
- **Test:** a game started with `--variant X` replays to the same state hash with and without the map, and no player-facing output contains the preset name.

### 2. The render tool (needed before round 6)
`tools/play/render.sh <save> [--turn N | --all]` replays a save through the real `CorePort` on the current commit and writes the real UI's screens:
- the recruit screen at the start and end of each requested turn;
- a frame strip of that turn's fight;
- each at 1688×780 and 1920×1080, as PNGs under `build/render/<save-stem>/`;
- an `index.md` that names the commit, the save's state hash per turn, and each file.

Renders run under xvfb and Mesa, which cloud sessions have (`docs/CLOUD_SETUP.md`). Reuse the UI's existing shot helpers if they fit (`tests/ui/shots/`), but don't change them; call them from `tools/play`.

**Test:** rendering a short saved game twice gives the same state hashes and the same file list, and the fight strip shows the fight that `play.sh <save> log` reports for that round.

### 3. The game log writer
`src/ui/game_record_log.gd`: a small class the UI calls when a game ends. It writes the seed, the settings (preset, field library SHA, strength), the hero and the full action list to `user://games/<timestamp>-<seed>.json`, in the same action format `tools/play` saves use. `play.sh replay-log <file>` then replays it.
- **Hooking it into the game-over screen is the UI worker's job.** Expose one static call, document it in `tools/play/README.md`, and say in your report what the hook should call.
- **Test:** a log written from a scripted game replays to the same final state.

### Later, not now
`play.sh --tutorial`, once the tutorial data lands.

## Checks
- Run `./scripts/check.sh` (the full gate) on your final commit, plus `ruff check`, `ruff format --check`, and gdlint on src, tools and `(cd tests && gdlint .)`.
- Keep every GDScript file under the 1,000-line lint cap.
- Don't loosen any existing test.

## Report
Under 250 words:
- the branch tip;
- what each tool does, with one example command;
- the test count against ideation/main's;
- what the UI hook should call;
- anything you declined, and why.

Don't edit `docs/ideation/DECISIONS.md`; put notes in `docs/ideation/evidence/play-tools.md`. Never push to or merge into `main`, and open no PR.
