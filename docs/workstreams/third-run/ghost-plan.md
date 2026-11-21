# Plan: pool removal, ghosts, Rust engine, third run, Windows build

Written 19 Nov 2026 by the ghost orchestrator, from the brief `docs/workstreams/third-run/ghost-orchestrator-brief.md` (branch `docs/third-run-plan`, 684a3c34). **Approved by the owner, 19 Nov 2026**, with one amendment to decision 4. The owner's words:

> Yeah, we'll go with the async rules you suggested. I like those rules. The old ghost stuff that'll be harder, I think, for when the games are really live, we won't have any ghosts if we make an update in the future. Like that rule can only hold in dev, and I don't want to populate ranked games in the future with bots. So we may have to allow the architecture for a player to play against a different patch. And I'm not sure how that would work with utility effects and stuff. And we'd hope to age the old ghosts out very quickly. It's a thorny subject, essentially. I like the idea of repopulating with bots for all of development, but we need to document that we need a solution long term and look at how other games have done it long term in terms of when we're a live game, how do we handle that exact same problem. I like the rest of the plan. I approve all of it. You're good to go as long as you understand those amendments.

So every decision below is taken as recommended, except decision 4, which becomes: **refill the field from bots after every change, for all of development.** For the live game, bots must not fill ranked games, so the problem stays open. A research note, `ghost-patches-long-term.md`, covers how other async games handle ghosts across patches, playing against a ghost from a different patch (and what that does to utility effects), and aging old ghosts out quickly. The ghost format records each run's patch and card fingerprints, so that work isn't ruled out later.

## What this phase is for

The owner, 19 Nov: "do a third bot run after we've removed the minion pool, built out the ghost system, etc." The run is on the game as it will really be played: async, against recorded boards, with no shared pool. It ends with the owner playing that run's ghosts in the Windows build.

On ghosts: "there should be no reason we can't take replay files from the Rust bots and just put them into our ghost system in the engine ... We should build out the full replay architecture, scoped as it will need to be for the full game, soon, regardless. I don't want the networking wired up yet ... but everything needs to be ready, built up to the point at which we start using networking. And we just have other interfaces in that we used during development up until we go for a server architecture."

On the pool: "having a minion pool doesn't make sense for async play when you can't adjust."

## Where it stands (20 Nov 2026)

- **Steps 1 and 2 are done.** The Rust engine is level with `dev`, including the Mouse and Pigeon tuning (PR 196), and is proved hash for hash. The pool is gone in both engines.
- **Step 3 is done.** Ghost runs, the cutter, the local store and matchmaker, the async game in both engines, records that name their runs, and `league ghost-match` (paired games against a field) are built and proved. The playable game runs on ghosts: its own store and matchmaker in `src/ghosts`, the screens, and the owner's finished runs saved as ghosts. Step E's extra proof is in `recheck.sh`: `proof/fight_logs.sh` compares every fight event on 10,000 reference cases (on 21 Nov: 649,706 events of 27 types, no difference).
- **Step 4 is done.** The Windows build ships a field of 8,000 runs from 1,000 live red-vs-blue games at the batch-1 rules (21 Nov). The bots predate batch 1, so the field tests the system, not balance.
- **TribeBot** is not a balance bot and can't play any match, ghost match or field (owner note `2026-11-20a`). It drives only the `selfcheck --bots tribe` engine check, until the league bots use every tribe mechanic in their own games.

## The plan, in order

Each step that changes code passes the two gates before it merges to `dev`: runtime (tests, type check, the Rust proof where the engine is touched, plus whatever proves the change on real play) and a `scope-reviewer` given the owner's words and this plan. Workers are Codex (gpt-6.2-sol) with Opus reviewers, per the `codex-workers` skill.

### Step 1. The Rust engine brought level with `dev` (item 4, first half)

Port the six rule changes, regenerate the GDScript reference games and the pinned build identity, and re-run the full proof.

- **Bot API kept compatible.** The new choices are added as new actions beside the old ones, so `red-m2` and `blue-m2` compile and play unchanged. A bot that never asks for a recruit target gets the default the GDScript bots get.
- **A check that the final bots still play:** both bots, unchanged, play a 200-game smoke on the new engine with no crashes or clock-outs.
- **Then kept level:** a script regenerates the reference data and pinned identity for a data-only balance PR, so the balance orchestrator's card-number changes reach Rust with one command and a proof run. A mechanic rework needs a Rust port; I take those as they land.

**Done.**

### Step 2. The pool removed (item 2)

Runs alongside step 1 on the GDScript side, then is ported to Rust once step 1 has merged.

- Shops and Discover draw by set chances (decision 1). Nothing is taken out or given back: buying, selling, casting, a full hand, triples, Bury and elimination stop touching any pool.
- `CardPool` becomes a fixed weight table; `pool_copies` on units, the pool in the state hash and in fight snapshots, and the soak's `pool_leak` check go. Tests that count copies are rewritten to check the draws.
- Bots keep compiling: `pool_copies` reads as 0 and the sandbox draws from the same weights.
- **Card text.** No card or keyword text in `src/content` mentions the pool (checked by the balance orchestrator). The docs and code comments that do are reworded: the Eat and Bury rules, Gorger, `ADDING-A-TRIBE.md`, `src/core/README.md`.
- **The rulebook.** 5.1 and 5.3 are replaced by the owner's choice, quoting their words; 5.1.4, 6.1.2–6.1.4, 6.2.1 and 6.2.3 are rewritten to match. 6.1.7 (tier weighting) stays open unless the owner settles it in decision 1.

**Done.**

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

**Done in Rust and for records; the playable game on ghosts is still to do.**

### Step 4. A first field of ghosts, and a Windows build to play it

The final league bots, unchanged, play 1,000 live 8-player games at the tuned rules (`dev` e5e8db8a); every seat's run becomes a ghost, about 8,000. A Windows build with that field goes to the owner's PC, alongside the third run's start; it doesn't hold the run up.

### Step 5. The third run: strong bots for balance

The owner, 20 Nov: "We need strong bots for balance." "They have to hill climb and at least reach a local maximum. Even if it's not the actual maximum, we need to at least reach local. And I prefer not to get stuck at a local maximum." The run makes those bots, and balance is measured with them, so **the run comes before the balance sign-off.**

- **Rules frozen during a climb** (owner: "Freeze per climb"). No card numbers change while the bots climb. Balance tunes between climbs, then the bots climb again on the new numbers, starting from where they were.
- **One fixed thread count for scored matches.** The final league bots time their search by CPU, so the same game at a different thread count can play differently (19 of 20 games matched at 1 vs 8 threads). Every scored match and stopping test uses one thread count, stated in the referee brief. The owner, 21 Nov 2026, agreeing with the recommendations put to them: "I agree with the calls."
- **Climbing.** Each team changes its bot one idea at a time. The referee keeps a change only if the new version beats the current one in a paired ghost match (same seeds, same 7 ghosts) with a 95% interval that excludes zero.
- **The stopping test** (a local maximum), on one reference field frozen for the test, with each match sized to see 0.1 in mean placement:
  - **Numbers:** for each of up to 10 numbers the team names up front, one step up and one step down (steps stated up front) don't beat the current version.
  - **Ideas:** the team's last 8 ideas, covering economy, tribe choice, board order and each reworked mechanic, were all rejected.
  - **Both bots** must pass, on overall placement. The test also plays each bot made to stay in each tribe and reports its placement per tribe (owner: "Overall + per-tribe report").
- **Not getting stuck.** At a bot's first local maximum its team climbs again from 2 different strategies it names; the best of the three is kept. The two teams use different model families, and each team's best plays the other's. A climb ends when both bots have passed the stopping test after their restarts, or the owner stops it.
- **The reworked cards.** For each mechanic (holding reservists, Actives, Mouse pilers, Hand-me-down routing), the referee reports how often the bot uses it, and plays it against itself with that mechanic switched off. If switching it off costs nothing, the team hears that the bot isn't using it well.
- **What balance gets.** Every kept version goes to the balance orchestrator labelled interim, with what it picks and how it places per tribe, and its rework checks. Balance tunes only from bots that passed the stopping test (owner: "Only passed bots").
- **Reports.** A short report to the owner each day: versions kept, the gap between the teams, and where each bot stands on the stopping test.
- **The field** starts from step 4's ghosts and refreshes with each team's kept versions (decision 6b).

The teams work in their own sessions, as in the league; the referee runs the matches and the tests (decision 6e).

### Step 6. The Windows build

The owner plays async games against the third run's final field of ghosts, shipped inside the build as a local ghost store. Their own runs are saved as ghosts beside them, so a later run can include them. The zip goes to the owner's PC by Taildrop, as every build does.

### When the problem is fixed

The owner plays async against the Rust bots' ghosts after step 4. Balance is measured with strong bots once both bots pass the stopping test on frozen rules. The whole goal, a third run on the real game and its ghosts in the owner's hands, is met after step 6. Checkpoints with the owner: after step 4 (the async game itself), at each bot's first local maximum (do the rework checks show the bots using the reworks?), and at each balance change.

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
