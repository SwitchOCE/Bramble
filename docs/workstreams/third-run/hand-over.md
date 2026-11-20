# Ghost orchestrator hand-over (20 Nov 2026)

From the ghost and Rust engine orchestrator, for the session that takes over. Where things stand and the plan going forward are in [ghost-plan.md](ghost-plan.md); this page holds what the repo can't tell you. Machine: the Optiplex (`Mini-Optiplex`). `dev` is at 5d697e07 (PR 201), rules fingerprint from `dev` e5e8db8a (the Mouse and Pigeon tuning).

## 1. On the Optiplex

| Path | What | Keep? |
|---|---|---|
| `/data/night-19nov/tuned/data` (3.3 GB) | Reference data at the e5e8db8a fingerprint: 1,000 GDScript records, 200 TribeBot records, 100,000 fights, r2g seeds. `LEAGUE_DATA` for `recheck.sh` | Keep until the next card change; then refresh into a new folder and delete this one |
| `/data/night-19nov/tuned/prove.sh` | The full-proof script I ran (recheck, cargo test, smoke, check.sh) | Keep as a template |
| `/data/night-19nov/tuned/{recheck,smoke,tmp,*.log}` | Output of the last proof | Safe to delete |
| `/data/night-19nov/NOTES.md`, `step3-design.md`, `strong-bots-proposal*.md`, `brief-common.md` | Night log, step 3 design, the strong-bots proposal with the owner's answers, the common worker brief | Keep `brief-common.md` (reuse it); the rest is history, safe to delete once you've read what you need |
| `/data/cargo-target/orch` (274 MB) | My Rust build folder | Safe to delete |
| `/home/alex/.t3/worktrees/Bramble/orch-ghost-system-a42a0ada71db6d18` | My worktree, now on `docs/ghost-hand-over` | Safe to delete once this PR merges |
| `/home/alex/league/` (red, blue, ladder, practice-*, ref, matches) | The league's teams, referee and match data | Not mine. **Never write to or delete anything here** |
| `/data/measure`, `/data/wt-handover`, `/data/worktrees/fix-round-dev`, `/data/bramble-*`, the `t3-*` worktrees on `balance/*` and `t3/tune-*`, `t3/pile-on-*` | The balance orchestrator's and others' work | Not mine; leave |

The provisional 800-run field and step D's logs (`/data/night-19nov/D`) are already gone; the real field gets cut fresh (section 10).

## 2. Branches

- **Merged, safe to delete (local):** `ghost/c-base`, `ghost/d-base`, `orch/ghost-system` (also on origin), `orch/night-base`, `engine/fight-logs`, `engine/level-to-dev`, `engine/poolless`, `rework/s5-pigeons`, `rework/s7-mice`, `rework/s9-retire-slot-buffs`, `rules/created-units-sell`, `t3/add-fight-kill-summon-logs`, `docs/third-run-plan`. `ghost/s9-review-fixes`, `ghost/a1-ghost-run` and `ghost/a2-async-session` are already deleted (merged through PR 191).
- **On origin, only superseded pin refreshes left, safe to delete:** `engine/night-integration`, `engine/badgers`, `engine/badgers-port`, `engine/pass1-cleave`. Their ports are on `dev`; the extra commits are reference refreshes for old fingerprints.
- **Holding work not on `dev`:** `engine/refight` and `t3/add-league-refight-command` hold the `league refight` command (paired combat comparisons), made for the balance orchestrator's measurements. Ask them before deleting. `measure/*` are theirs.
- **Not mine:** `league/engine` and `league/t3-amend` (the league's engine history and the referee's amendments, including `pin_teams.sh`).

## 3. Running or scheduled

- **`pin_teams.sh`** (pid 386835, running since 18 Nov from the `league-t3-amend` worktree): keeps red's processes on cores 0–1 and blue's on 2–3, logging to `/home/alex/league/pin.log`. It's the league referee's. Leave it running while the teams' sessions exist; the referee or owner stops it.
- Nothing of mine is running or scheduled. The approval watcher (section 4) runs only while a worker does.

## 4. Codex workers

- **What went wrong:** on 19–20 Nov three workers sat 7–11 hours on an approval prompt overnight. Codex asks the owner before any `rm -rf`, even inside its own checkout, and T3 does not wake the parent orchestrator. My brief's "remove your scratch files" line caused it, twice.
- **What works now:** briefs say never run `rm -rf` anywhere and list leftovers in a disk report; the orchestrator deletes them (`/data/night-19nov/brief-common.md`). While any worker runs, keep `timeout 7100 ~/.local/bin/t3-approval-watch.py 30 60` running as a background command and re-arm it when it ends: exit 124 means nothing waited, a `WORKER WAITING` line names the stuck worker, `WATCH BROKEN` means the watch failed, not all clear. It caught the next stall in 62 s. If the blocked step is yours to do, cancel the worker and do it.
- Codex workers can't `git checkout`, merge or push; you do those. Target `{"driverKind":"codex","model":"gpt-6.2-sol","options":{"reasoningEffort":"high"}}` with `isolation:"worktree"` (made from your checkout's HEAD).

## 5. How to run things

Set `CARGO_TARGET_DIR` and `TMPDIR` on `/data`; run `godot --headless --import` once in a fresh checkout.

- **Full proof (about 1 hour):** `JOBS=8 tools/league/proof/refresh_reference.sh <data>` (15–20 min) → `python3 tools/league/proof/regen_curated.py` → `LEAGUE_DATA=<data> JOBS=8 tools/league/proof/recheck.sh <out>` (20–30 min) → `LEAGUE_DATA=<data> tools/league/proof/smoke_final_bots.sh <out>` → `scripts/check.sh` (10–12 min). Template: `/data/night-19nov/tuned/prove.sh`.
- **Re-pin after a card change:** refresh as above; run `regen_curated.py`, and if it reports `TRACE CHANGED`, check each changed case uses a changed card, then rerun with `--rewrite-traces`; copy `LIVE_REFERENCE` from `tests/core/test_async_session.gd` into the pin in `tools/league/league/src/game.rs`; `cargo test --offline --release --workspace --exclude red --exclude blue --no-fail-fast` with `LEAGUE_DATA` set; then the full recheck. Any change under `src/core` or `src/content` moves the fingerprint and needs this, and a fresh field.
- **Cut a field:** `league match --red red --blue blue --games 1000 --seeds <file> --clock-ms 1000 --threads <k> --out <m>`, then `bramble-ghosts cut --match <m> --store <field> --made <ISO time>` and `bramble-ghosts verify --store <field>`. Cutting is fast (50 games in about a second); the match is the slow part, and I haven't timed 1,000 final-bot games at this fingerprint: time 20 first.
- **Ghost match:** `league ghost-match --red red --blue blue --field <field> --games <even N> --seeds <file> --clock-ms 1000 --threads <k> --out <dir>`, then `python3 tools/league/proof/check_ghost_match.py <dir> <N>`. A match never reuses a run, so a field of R runs supports about R ÷ 3.5 games.

## 6. Memory the next session needs

- **Docs say what holds now** (owner, 20 Nov): edit docs and owner notes in place so they're correct going forward; remove old stuff and history caveats.
- **Balance needs strong bots** (20 Nov): TribeBot is not a balance bot; only iterated league bots that reach at least a local maximum.
- **Workers waiting on the owner:** keep the watcher running (section 4). Workers never delete outside their checkout.
- **You may edit `bots/red` and `bots/blue`** (owner, 20 Nov: the never-edit rule was for the league teams). The teams still change nothing outside their own folders.
- **League: trust the teams.** No extra cheat checks; never tell the teams about checks.
- **Tell the owner about blind spots at once** (motion, real hardware, anything a tool can't see).
- **Builds go to the owner's PC by Taildrop:** `sudo -n tailscale file cp <zip> <pc>:`; the owner starts it with `Play-Bramble.cmd`.
- **Clean up what's superseded** once it's merged or backed up. Merging `dev` into `main` deletes `dev` on GitHub: restore it at `main` and retarget open PRs.
- **The Optiplex has no compute limit:** use all cores. `/tmp` is RAM (16 GB); big output goes on `/data`.
- **The owner wants clickable links** for anything they're asked to look at.

## 7. Choices I made without the owner that still stand

- A ghost match uses each run at most once (Galaxy's "never the same run twice in a session", read with the bot as the player).
- Ghost-match scores one live seat per game: red and blue each play seat 0 against the same seed and the same 7 ghosts.
- One record seat is one run, whatever `--made` says; the matchmaker skips unfinished runs; ghost-match refuses a run whose rules differ from the game's.
- The cutter refuses TribeBot seats, and a `games.jsonl` row that names a run seat.
- Kept, with no reader yet: per-card fingerprints in runs (for decision 4's per-card retire rule), per-turn health, gold and actions, the records archive, and the ghost-game fields in `games.jsonl` (owner: keep them).
- `summary.winner` dropped: the sign of `gap_red_minus_blue` says the same.
- Recheck gained a ghost-match step (cut twice, match, cut back).
- The stopping test's numbers in ghost-plan step 5 are mine: at most 10 named numbers, the last 8 ideas, 0.1 placement, 2 restarts, the switch-off test per mechanic, a daily report. The owner answered the four forks and didn't object to the rest.

## 8. Questions waiting on the owner

- Editing owner notes in place: should the project `CLAUDE.md` say a changed instruction is edited into the existing note? (`CLAUDE.md` left as it is.)

## 9. Owner notes written for this work

- `2026-11-19d-record-every-state-change.md`: fight logs always on, every state change recorded.
- `2026-11-19e-ghosts-not-bots.md`: players face ghosts, not bots; GDScript bots are archived once the game plays ghosts.
- `2026-11-20a-strong-bots-for-balance.md`: balance uses strong bots that reach a local maximum; TribeBot only drives the engine check (written by the balance orchestrator, made correct by me on the owner's word).

## 10. What I'd do next, in order

1. **Step E:** a full fight-log comparison on a 10,000-case sample (today only `uses` events are compared beyond state hashes); a test that the cutter's hand-written Triple Reward entry matches the engine's; a Rust test for the cutter refusing a run seat.
2. **The field:** red vs blue, 1,000 live games at the current fingerprint, cut into about 8,000 runs, verified, and a sample replayed in Godot.
3. **Third-run briefs** for the referee and both teams, from ghost-plan step 5. Two gaps first: the teams' tools crates call `run_factories`, which is live-only, and `run_match` is private, so they can't run ghost matches yet; and `league analyze` has never run on ghost-match output (it averages each seed pair by colour, and an async game has one).
4. **The playable game on ghosts (GDScript).** Exists: `GhostRun` (reads and checks a run file, gives the payload per round), `GhostStore` (read-only `fetch` by id from a folder store), `GameContent.new_async_session` (one live player against runs), async records and their replay with `--ghost-store`. Missing: the store's add, find and index (Rust `FolderStore` has them); a matchmaker (port Rust's `LocalMatchmaker`: same rules, a band, no run twice); the game flow (`src/game` plays live lobbies only); the screens (opponent names and run boards, using the record's `run_board` event); shipping the field in the build; saving the owner's runs as ghosts.
5. **The Windows build** with the field, by Taildrop.
6. **Archive the GDScript bots** (note 19e). Warning: the proof's 1,000 reference records are GDScript FlowBot and RandomBot games; replace that check first (Rust plays, Godot replays: the r2g steps already do this one way).

**Warnings.** Chain cleanup with `&&`, never `;` (a failed `git add` once let my chain delete a worker's branch). Clippy fails on the `blue` crate: use `--no-deps` on your crates. `cargo test` stops at the first failing binary without `--no-fail-fast`. Piping hides `regen_curated.py`'s exit code. Stale GUT class cache: rerun `godot --headless --import`. The committed `proof/fixtures/async-store` is at old rules: Godot tests and `async_session.rs` use it for its fixed IDs, while recheck cuts a fresh async field from a current Godot game (`proof/current_async_field.sh`). The league page builder fails on old matches until `analysis/deep/run.py` reruns with records.
