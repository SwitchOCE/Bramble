# Plan: pool removal, ghosts, Rust engine, third run, Windows build

Written 19 Nov 2026 by the ghost orchestrator, from the brief `docs/workstreams/third-run/ghost-orchestrator-brief.md` (branch `docs/third-run-plan`, 684a3c34). A proposal for the owner: nothing here is decided until the owner says so. No code has been written.

## What this phase is for

The owner, 19 Nov: "do a third bot run after we've removed the minion pool, built out the ghost system, etc." The run is on the game as it will really be played: async, against recorded boards, with no shared pool. It ends with the owner playing that run's ghosts in the Windows build.

On ghosts: "there should be no reason we can't take replay files from the Rust bots and just put them into our ghost system in the engine ... We should build out the full replay architecture, scoped as it will need to be for the full game, soon, regardless. I don't want the networking wired up yet ... but everything needs to be ready, built up to the point at which we start using networking. And we just have other interfaces in that we used during development up until we go for a server architecture."

On the pool: "having a minion pool doesn't make sense for async play when you can't adjust."

## How it works today

- **A live lobby.** The owner and 7 FlowBots (or 8 league bots) play the same rounds in one process and fight each other's live boards (`src/game/game_flow.gd`, `src/core/session/game_session.gd`). The only "ghost" is Battlegrounds' stand-in when an odd number of players is left (rulebook 2.1.2).
- **A shared pool** with copy counts feeds every shop and Discover (5.1, `card_pool.gd`).
- **Records.** Every game writes a record that replays it exactly, and each fight's boards are saved in it as payloads a ghost could be rebuilt from (`src/core/records/README.md`). Nothing builds ghosts from them yet.
- **The Rust engine** on `league/engine` is a bit-exact port of the game at c0d7db79, proved by `proof/recheck.sh` in about 8 minutes (1,000 GDScript games replayed in Rust, 100,000 fights, 50 Rust games replayed in GDScript). It plays a game in 0.15 s against GDScript's 1.9 s. It lacks six rule changes now on `dev` (6ae276e4, 247a1fee, a9114cf3, bac1c909, 77b09a1f, ecf2fc95): three small, one medium, two large.
- **The final league bots** (`red-m2` 03f8827d, `blue-m2` cdbb7620) are Rust crates built against `league-api`. They don't read the pool. Two of the six rule changes add bot actions (choosing a recruit target, selling from hand), and a naive port of those breaks both bots at compile time.

## The plan, in order

Each step that changes code passes the two gates before it merges to `dev`: runtime (tests, type check, the Rust proof where the engine is touched, plus whatever proves the change on real play) and a `scope-reviewer` given the owner's words and this plan. Workers are Codex (gpt-6.2-sol) with Opus reviewers, per the `codex-workers` skill.

### Step 1. The Rust engine brought level with `dev` (item 4, first half)

Port the six rule changes, regenerate the GDScript reference games and the pinned build identity, and re-run the full proof.

- **Bot API kept compatible.** The new choices are added as new actions beside the old ones, so `red-m2` and `blue-m2` compile and play unchanged. A bot that never asks for a recruit target gets the default the GDScript bots get.
- **A check that the final bots still play:** both bots, unchanged, play a 200-game smoke on the new engine with no crashes or clock-outs.
- **Then kept level:** a script regenerates the reference data and pinned identity for a data-only balance PR, so the balance orchestrator's card-number changes reach Rust with one command and a proof run. A mechanic rework needs a Rust port; I take those as they land.

**Ready for the balance orchestrator: tonight, 19 Nov, if the plan is approved by early afternoon.** The original port took about 3 hours with parallel workers; these six changes are smaller. If the large two (recruit on every gain, hand sales) fight back, the morning of 20 Nov.

### Step 2. The pool removed (item 2)

Runs alongside step 1 on the GDScript side, then is ported to Rust once step 1 has merged.

- Shops and Discover draw by set chances (decision 1). Nothing is taken out or given back: buying, selling, casting, a full hand, triples, Bury and elimination stop touching any pool.
- `CardPool` becomes a fixed weight table; `pool_copies` on units, the pool in the state hash and in fight snapshots, and the soak's `pool_leak` check go. Tests that count copies are rewritten to check the draws.
- Bots keep compiling: `pool_copies` reads as 0 and the sandbox draws from the same weights.
- **Card text.** No card or keyword text in `src/content` mentions the pool (checked by the balance orchestrator). The docs and code comments that do are reworded: the Eat and Bury rules, Gorger, `ADDING-A-TRIBE.md`, `src/core/README.md`.
- **The rulebook.** 5.1 and 5.3 are replaced by the owner's choice, quoting their words; 5.1.4, 6.1.2–6.1.4, 6.2.1 and 6.2.3 are rewritten to match. 6.1.7 (tier weighting) stays open unless the owner settles it in decision 1.

**Ready, with the Rust port proved: 20 Nov.**

### Step 3. The ghost system (item 3)

What a ghost is here: **one player's run, turn by turn**: for each turn, the board, hand, slots, tier and health they took into that turn's fight, as the record already saves it. A new game puts a player against several such runs (decision 3). Records already hold every living player's pre-fight board each turn, so a run can be cut out of any record, GDScript's or Rust's, which is what lets the Rust bots' games feed the game's ghosts directly.

The pieces, each "build now" (with why it would be costly later) or "plan only". "Local" means a folder on disk standing in for the server; each piece sits behind an interface a server version replaces.

| Piece | Build now or plan only | Why |
|---|---|---|
| **Ghost run format**: one file per run; each turn's fight payload and tier; the run's id, bot or player id, rules version, final placement, and a fingerprint of each card it holds | **Build now** | Every run recorded before the format exists is lost or needs converting. The card fingerprints are one field, and runs recorded without them can never be sorted by card later (decision 4). |
| **Cutting runs out of records**: one cutter, in Rust, since Rust already writes GDScript's record format | **Build now** | The bot field for the run and the Windows build both come from it. |
| Saving the owner's own runs as ghosts for later fields | **Plan only** | Nothing in this phase plays against them, and the owner's records are kept, so runs can be cut from them later. |
| **The async game**: a session of one live player against recorded runs, by the rules the owner picks in decision 3, in GDScript and in Rust, proved hash for hash like the rest | **Build now** | It is what the third run plays and the owner plays. |
| **Records of async games point at the runs they used** (by id and content hash), so they still replay exactly | **Build now** | A record that can't name its opponents can't be replayed or checked, and the owner wants "a log of the game that can reconstruct a game exactly" (17 Nov). |
| **Ghost store** interface: add a run, fetch a run, find runs by version and strength. Local: a folder of run files | **Build now** (interface and local) | Matching and the third run need it; without the interface, every caller reads files directly and the server swap touches all of them. |
| **Matchmaker** interface: pick a game's opponents. Local: same rules version, a strength band, never the same run twice in a session (Galaxy) | **Build now**, simple rules | The run and the build need opponents picked. Galaxy's later refinements (thinning very strong early boards) are plan only. |
| **Strength for matching**: each run's bot version and placement; the matchmaker picks by those | **Build now**, behind the matchmaker's interface | A rating that updates from results matters with real players; with two near-identical bots and one human it has nothing to separate. **Plan only:** the rating maths. |
| Uploading a finished run | **Plan only** | Locally it's the store's "add a run"; the server version replaces it. |
| **Retiring old ghosts after a balance change** | **Build now**: refill from bots, by hand. **Plan only**: the per-card rule and doing it on the server | Nothing needs the per-card rule until there are players' ghosts. |
| Server, networking, accounts, uploads | **Plan only** | The owner: "I don't want the networking wired up yet." |
| Checking a submitted run is legal by replaying its record on the server | **Plan only** | Already possible, because records replay exactly. Nothing to build until there's a server. |
| Leaving a run and coming back to it later | **Plan only** | A record can already rebuild a game; the screen flow for it can wait. |

**The plan for the server**, written as a short design note in the same step: what it stores, what it checks, what each local interface becomes. No server code.

**Ready, proved in both engines: about 23 Nov.** This is the biggest step and the estimate is the loosest. Fights are already proved in both engines (100,000 of them); the new proof is the async game around them: opponents picked, ghosts fighting ghosts, records naming their runs.

### Step 4. A first field of ghosts, and a Windows build to play it

The final league bots, unchanged, play 1,000 live 8-player games on the poolless game; every seat's run becomes a ghost, about 8,000 at league strength, in under an hour. A Windows build with that field goes to the owner's PC. **About 24 Nov.**

This is the first real test of "take replay files from the Rust bots and just put them into our ghost system", and the owner plays the async game here, before the third run's rules are set on top of it. The assurance session's proposal (the final bots unchanged on the new game, with and without the balance set) is the balance orchestrator's measurement, so I run it with them rather than twice.

### Step 5. The third run (item 5)

Starts only after the owner signs off the balance pass. Its rules are decision 6. The teams' work happens in their own sessions, as in the league; I referee, as the league's referee did, or the same referee does it (decision 6e).

### Step 6. The Windows build (item 6)

The owner plays async games against the third run's final field of ghosts, shipped inside the build as a local ghost store. Their own runs are saved as ghosts beside them, so a later run can include them. The zip goes to the owner's PC by Taildrop, as every build does.

### When the problem is fixed

The owner first plays async against ghosts made by the Rust bots after step 4, about 24 Nov. The whole goal, a third run on the real game and its ghosts in the owner's hands, is met after step 6. Checkpoints with the owner: after step 2 (the game without the pool, if they want to play it), **after step 4** (the async game itself, the most important stop), and before step 5 (the balance sign-off).

## Decisions for the owner

### 1. What sets the shop's chances once the pool is gone

- **A. Each card keeps the chance it has on turn one today (recommended).** Every card's weight is its starting copies (15 at tiers 1–2, then 13, 11, 9, 7, 5; spells 5, 7, 9, 11, 9, 7), and the weights never run down. It's the assurance session's proposal. It changes the least, so the bots' play and the balance pass's numbers carry over.
- **B. A chance per tier, as in Teamfight Tactics.** A table of odds by your tier, like the economy sims' (at tier 6: 7/13/22/27/21/10 % per slot), then an even pick within the tier. It also settles tier weighting (6.1.7), but it's a bigger change to the game the bots learned.
- **C. Every card equally likely**, from tier 1 up to yours. Simplest; at high tiers you'd see more high-tier cards than today.

Either way: a shop can show the same card twice, and Discover still offers 3 different cards.

Note: without the pool, nobody takes copies from anyone else, so a tribe many players share (Locust, on half the league's boards) gets easier to triple. That's a balance effect of the removal itself.

### 2. Is the balance pass measured with or without the pool?

- **A. Without (recommended).** The balance orchestrator measures on the game as it will be played. The cost is a day: the poolless Rust engine is ready on 20 Nov, not tonight. It can start its baseline measurements tonight on the current game in the meantime.
- **B. With.** Measure on today's game from tonight; check again once the pool is gone.

### 3. How async play works (rulebook 2.1.5)

**a. Players per game**
- **A. 8 (recommended).** Damage and starting health were tuned for 8 (10.1.3's game-length aims), and the bots learned 8.
- **B. 6, as in Galaxy.** Shorter games; damage would need retuning.

**b. Who you fight, and what ends the game**
- **A. Galaxy's way (recommended).** The other 7 are recorded runs. Each round you fight one of them, on the board it had on that same turn of its own run. The recorded runs also fight each other, simulated, so they lose health and drop out just as live players do. A run that ended early in its own game stays on its last board. The game ends when one is left, and your placement is where you finished among the 8, as today. Everything in the rulebook about damage, elimination and placement stays as it is.
- **B. The runs keep their own fate.** Each recorded run keeps the health it had in its own game and leaves on the turn it went out there. No simulated fights between them. Simpler, but their health has nothing to do with your lobby, and placement is a comparison with seven other games.
- **C. A gauntlet.** No placement: you play until your health runs out, and your score is the fights you won. Galaxy's tournaments work a bit like this. It throws away the lobby the game is built around.

**c. How opponents are chosen**
- **A. Recommended:** at the start of a game, 7 runs from the same rules version and strength band, never a run you've already met that session; you face each before facing one again (2.3.1, as today).
- **B.** A fresh pick each round, from runs that reached that turn (closer to Galaxy's turn-by-turn matching, but a lobby has no fixed 7).

**d. What you see of the next opponent.** The screen shows the next opponent's portrait and health, not their board. A ghost can't adapt to you, and you raised the worry that the player "gets to adapt to a ghost that can't adapt to them" (9 Nov). **Recommended: keep it as it is**: who and their health, and past boards only of opponents you've already fought (what the bots see now too).

### 4. Old ghosts after a balance change

- **A. Recommended: retire only the ghosts holding a changed card.** Each run carries a fingerprint of every card on it, so after a change the runs that hold none of the changed cards stay. While the field is only bots, it's simpler still to replay the whole field on the new version, which takes under an hour, so for now: **refill the field from bots after every balance change**, with the per-card rule built for when there are players.
- **B. Retire everything on any change**, as Galaxy did after big patches. Fine for bots; with players it empties the field at every patch.
- **C. Keep old ghosts with the new numbers**: their boards stay and their cards take the new stats. Cheap, but the boards were built for a different game.

### 5. Does the Rust engine move onto `dev` as the project's simulator?

- **A. Yes (recommended).** The engine, the match runner, the proof and the final bots go to `dev` under `tools/league/`. A data-only balance change reaches it with one regenerate command. A mechanic change merges on `dev` without waiting; I port it within a day. Any bot run, and any build that ships ghosts, needs a passing proof first, because the ghosts the bots make must come from the same rules as the game the owner plays.
- **B. No.** It stays on the league branch and is caught up before each run. Less work per rules change, but each catch-up is a day's port and it drifts in between.

This doesn't change `main`: `dev` reaches `main` only on your say-so.

### 6. The third run

**a. Where the first ghosts come from.** You said for the league: "you need to have an existing field of ghosts to play against of the bot strength. Probably ... the first 100 games are just played against random bots, and then they don't count."
- **A. Recommended:** the final league bots play 1,000 live 8-player games on the new game (no pool, balance pass in). Every seat's run becomes a ghost: about 8,000 runs at league strength from the start. Under an hour.
- **B. Your league idea:** the first games are against baseline bots and don't count; the field fills with each team's runs as they play.

**b. How the field is refreshed as bots improve.** **Recommended:** every match adds its runs to the field and the field keeps the newest runs, a fixed number per bot version, so an old version's runs age out as new ones come in. Strength bands set who meets whom.

**c. How teams are scored.** **Recommended:** both teams' bots play the same lobbies (the same 7 ghosts and the same seed), and the lower average placement wins, as in the league. Facing identical opponents makes the comparison fairer than the league's, so fewer games are needed. Alternative: each team's bot meets ghosts matched to its own results, and the stronger final standing wins; that needs the rating maths built now.

**d. Do the teams and their bots carry over?**
- **A. Recommended:** the bots carry over, and the two team sessions continue with their own notes. You asked for them to "iterate based on the new variants", and they know the game.
- **B.** The bots carry over, with fresh team sessions started from each team's hand-over notes.
- **C.** Everything fresh, bots included.

**e. Who referees.** **Recommended:** the league's referee session, which knows the harness and checks; I build the engine and ghost pieces it uses.

### 7. Which ghosts you play in the Windows builds

- **A. Recommended:** opponents picked at random from the field (step 4's, then the third run's), never the same run twice in a session.
- **B.** A menu to pick a strength band each game: the bots' best-placed runs, the middle, or the weakest.

A rating that follows your results is the full game's way; it is planned, not built, because there's one player.

### 8. Build the rating system now?

You asked for the replay architecture "scoped as it will need to be for the full game". A rating that rises and falls with results is part of the full game's matching.
- **A. Recommended: later.** The matchmaker's interface is built now, picking by bot version and placement. With two near-identical bots and one human player, ratings have nothing to separate yet, and they're one class to add behind that interface.
- **B. Now.** Built and used by the third run's matching and the Windows build.

## Rulebook entries each decision changes

Decision 1: 5.1, 5.3, 6.1.2–6.1.4, 6.1.7, 6.2.1, 6.2.3. Decision 3: 2.1, 2.3, 10.1.7, 10.2. Decision 4: a new entry in 2.1 on ghost versions. Decision 6 goes in the third run's own brief, not the rulebook. Each gets the owner's words, quoted.

## The plan check

A fresh agent ran `/plan-interrogate` on the first draft. Its result is in [plan-interrogation.md](plan-interrogation.md). Taken from it: the early Windows build against the league bots' ghosts (step 4), one run cutter instead of two, ratings and the owner's own runs deferred, the assurance check folded into the balance measurement, a lighter rule for keeping Rust level (decision 5). Kept against it: the per-card fingerprint, because it is one field and can't be added to runs after they are recorded.
