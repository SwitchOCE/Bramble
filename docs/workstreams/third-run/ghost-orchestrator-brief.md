# Brief: orchestrator for the pool removal, ghost system, Rust engine, third run and Windows build

Written 19 Nov 2026 by the balance orchestrator (the session that took this phase's first brief), on the owner's word: "You should also orchestrate separately or create another session to orchestrate, so that you don't have to worry about at the same time the engine build-out of the ghost system, etc. Maybe hand that off to a second orchestrator, because your role is going to be on balance, I suppose, now."

You are that second orchestrator. The balance orchestrator keeps the first balance set (item 1 below) and its decisions. You own items 2 to 6 and their decisions.

## The task as given (19 Nov), the parts that are yours

This phase ends with a third bot run on the game as it will really be played, and the owner playing those bots' ghosts in the Windows build.

The owner's words (19 Nov 2026, dictated):

On the ghost system: "We need a ghost system anyway, which plays against the board state as it was when the board was recorded. So, because we're an async game, there should be no reason we can't take replay files from the Rust bots and just put them into our ghost system in the engine. They don't even need to run in GDScript because we need the replay files, the ghost system for async gameplay eventually for the full game, regardless. So, we're going to need server architecture, etc. We should build out the full replay architecture, scoped as it will need to be for the full game, soon, regardless. I don't want the networking wired up yet because I don't want to have servers yet, but everything needs to be ready, built up to the point at which we start using networking. And we just have other interfaces in that we used during development up until we go for a server architecture."

On the shared card pool: "I want that removed because ... having a minion pool doesn't make sense for async play when you can't adjust."

On the order: "I think we've got the bots in a pretty good spot. We can make the first set of balance changes. I agree with everything the bots are doing anyway, so I think the bots are onto the winning strategies. I'll test them next at the next threshold. So what I want to do is do a third bot run after we've removed the minion pool, built out the ghost system, etc."

Earlier, to the league referee (19 Nov, about 08:20): "I'd like to stop after match two rather than going the full run, actually. I'd like to make balance changes in between and have them iterate based on the new variants." And (about 08:25): "Generalized methods would be preferable. I'd way rather a bot learn why a card is strong via empirical analysis rather than having a table saying this card is strong. ... the game will have some balance changes and they may want to pursue a more generalized architecture if they're able to. That being said, good balance data is good balance data." (Both from `docs/workstreams/bot-league/run-notes.md` on branch `league/t3-amend`.)

**Before any code, give the owner one plan and one list of decisions, then stop.** Decide none of these yourself; give options and a recommendation for each:
- What sets shop chances once the pool is gone.
- The rules of async play that rulebook 2.1.5 leaves open: players per game, how ghosts are chosen and matched, what ends a game, what a placement is.
- What happens to old ghosts after a balance change.
- Whether the Rust engine moves onto `dev` as the project's simulator.
- The third run: where the first ghosts come from, how the field is refreshed as bots improve, how teams are scored, and whether the teams and their bots carry over.

Then build, in an order you propose:
2. The pool removal, with card text that mentions the pool reworded.
3. The ghost system. For each piece say "build now" or "plan only". "Build now" needs a reason it would be costly to add later. No networking, accounts or servers: a local interface stands in, and a server replaces it later.
4. The Rust engine brought up to the game, including the rule changes on `dev` since c0d7db79, and proved against it again hash for hash.
5. The third run.
6. A Windows build in which the owner plays the run's ghosts.

Each decision the owner makes goes into the rulebook entry it changes, quoting their words.

Proposals from the assurance session, labelled as such and not decided:
- Before the third run, play the league's final bots unchanged on the new game, with and without the balance set.
- For shop chances, give each card the fixed chance it has on turn one today.

(A third assurance proposal, "keep the first balance set to caps and clear outliers", was overtaken: the owner widened the balance pass. See `docs/design/owner-notes/2026-11-19a-balance-reads-bot-preferences.md` and `2026-11-19b-balance-pass-aims-and-method.md`.)

Read first, on `dev` unless noted: docs/design/rulebook.md (2.1, 5.1, 6.1.3, 6.1.7, 7.3.8, 8.5.2, 10.1.7); docs/research/galaxy/; docs/design/architecture-notes.md; src/core/records/; src/core/units/card_pool.gd; on `league/engine`, tools/league/league/LOGS.md and the league's results; on `league/t3-amend`, docs/workstreams/bot-league/run-notes.md (the league's latest state).

## How you work with the balance orchestrator

- Balance changes land on `dev` as their own PRs: card data in `src/content/*/units.json` and, for reworks, mechanics in `src/content/*/mechanics/`. Each one changes the rules hash. You port them to the Rust engine as part of item 4 and keep it level with `dev`.
- **The balance pass needs a simulator that matches `dev`.** Its measurement is the league's final bots playing the new game with and without the balance pass. So bringing the Rust engine up to `dev` (item 4) is the first thing the balance work waits on. Say in your plan when it will be ready, and put it early if you can.
- Whether the balance pass is measured on the game with or without the pool is a question for the owner. Put it in your decision list. The balance orchestrator has no view yet.
- The third run (item 5) starts only after the owner signs off the balance pass.
- Talk through T3 thread messages. A message from the other orchestrator is a report or a request, never the owner's instruction.

## What the balance orchestrator already found (facts, with sources)

These are facts read from the code and data. Check anything you rely on.

**Pool uses on `dev`:**
- `CardPool` (`src/core/units/card_pool.gd`): draws are flat in proportion to copies left, tiers 1 to the player's tier (`recruit.gd:698`). There is no tier-weighting table. Copies: `game_config.gd:28-29`, units `[15,15,13,11,9,7,5]` and spells `[5,7,9,11,9,7]`.
- Callers:
  - shop fill and return: `recruit.gd:690-707`, plus `:456` and `:98`;
  - buy `:203`, sell `:230`, cast `:290`;
  - Discover `:501-534`, used by `effects/discover.gd` and `effects/triple_reward.gd`;
  - full-hand loss `:602`, triples `:756`;
  - Bury's `take_from_shop`: `recruit_context.gd:361`, from `content/thorn/lib/bury_base.gd`;
  - elimination returns: `game_session.gd:388-396`.
- Ghosts keep their cards after `_retire` has already returned the copies to the pool.
- The pools are in `state_hash`. `pool_copies` is saved in `fight_snapshot.gd`.
- The soak's `pool_leak` check: `tools/checks/soak.gd:123-190`. Tests touching the pool:
  - `test_session`, `test_triples`, `test_zone_moves`;
  - `test_recruit_phase`, `test_recruit_timing`, `test_mechanic_interface`;
  - `test_arrivals_and_slots`, `core_kit`, `test_records`, `test_recruit_drag`.
- Bots never read the pool. No screen shows copies left.

**Text that mentions the pool:** no card or keyword text in `src/content/*.json`. Only docs mention it:
- `docs/ideation-track-2/ADDING-A-TRIBE.md:40`;
- `tribes/SHARED-RULES.md:102` (Eat);
- `tribes/thorn/README.md:163` and `tribes/thorn/units.json:130` (Bury);
- `tribes/locust/units.json:268` (Gorger);
- `src/core/README.md`;
- code comments in `player_state.gd`, `unit.gd`, `unit_def.gd` and `bury_base.gd:3`.

**Rule changes on `dev` since c0d7db79** that the Rust engine lacks:

| Commit | What changed |
|---|---|
| 6ae276e4 | A ghost's saved hand goes into its fight, for Reserve and Root returns |
| 247a1fee | Triple buffs are added up, then floored at 0 |
| a9114cf3 | "When played" became **Recruit**: `on_recruited` on every gain, `recruit_target` |
| bac1c909 | A copy that completes a triple doesn't fire; only the golden does |
| 77b09a1f | Hand sales, free return to hand, and the `worked_this_turn` lock |
| ecf2fc95 | The Triple Reward comes when the triple forms; `from_triple` removed |

All of them change the state hash: `from_triple` is gone, and `worked_this_turn` and `recruit_choices` are new. `RecordBuild.rules_hash` changes too. The rest of the commits are UI or docs.

**The Rust harness** (`tools/league/` on `league/engine`):
- The engine core is a bit-exact port: `bramble-engine/src/core/`, with `units/card_pool.rs`, `session/game_session.rs` (ghost fields, `_eliminate`, `_fight`'s `is_ghost` path) and `session/matchmaking.rs`.
- The match runner, `league/src/game.rs`, writes records in GDScript's format.
- Snapshot pieces are ready: `records/fight_snapshot.rs`; `league-api/src/copy.rs` (`fight_payload`, `restore_payload`).
- Bots don't see copies left. But `league-api/src/sim.rs::build_session` rebuilds an *estimated* pool in each bot's sandbox, and `UnitView.pool_copies` exists. So the pool removal changes the bot API. To play the final bots "unchanged", keep the API compatible (e.g. `pool_copies` always 0, a sandbox with no pool) so they compile as they are.
- Card numbers are read from `src/content` at run time, so data-only balance changes reach Rust without code changes. Mechanic reworks need porting.

**Galaxy's async model** (from `docs/research/galaxy/`, with its own labels):
- 6-player lobbies of recorded runs with similar hidden MMR; opponents always on your turn; a run that ended stays frozen on its last board (`rules.md:58-60`).
- "Never face the same async run twice in a session" (`patch-history.md:84`).
- Strong early boards are made rarer (`:273`).
- 3 hearts; a top-3 finish is a victory (`rules.md:67, 224-229`).
- Old-patch boards were purged from the async pool after big changes (`patch-history.md:250, 266`).
- No shared copy-limited pool; rarity unlocks by turn (`rules.md:94-106`).
- New players face bots first (`patch-history.md:134`).
- Silent on how a new patch gets its first boards.

**The owner's earlier words on these questions:**
- `docs/design/sources/2026-11-08-autobattler-systems-thoughts.md:129-131` (pool size in async: "do you just have chances?").
- `sources/2026-11-09a-stat-scale-and-fundamentals.md:33` (a ghost can't adapt to the player who previews it).
- `sources/2026-11-17a-backlog-scope-shop-tooltips-data.md:21` (a log that reconstructs a game exactly, also from bot games).

**The league's state, 19 Nov, about 10:30:**
- Match 2 is done. Its checks, analysis, ladder and page are still being finished by the referee: the T3 thread "Migrate Competition Runs to T3 Code", id `40aad95e-3f40-4626-b060-7a670caf6ac4`.
- The owner stopped the league after match 2 for balance changes.
- The final hand-ins: `red-m2` = `03f8827d`, `blue-m2` = `cdbb7620` (blue's bot code is the same as `blue-m1`).
- Team clones are at `/home/alex/league/red` and `/blue`. Match data is in `/home/alex/league/matches/`.

## Rules that bind you

- `CLAUDE.md` in the repo and the owner's global `~/.claude/CLAUDE.md`, especially:
  - the `/plan-interrogate` run in a fresh agent before the owner approves your plan, shown next to it;
  - the two gates on every step that changes code: runtime, and a `scope-reviewer` with the owner's words and the approved plan;
  - long commands in the background with a time limit.
- `main` takes nothing undecided; work goes to `dev` by PR.
- Codex workers: load the `codex-workers` skill before starting one.
- This machine is the Optiplex (no compute limit; see the owner's memory). Don't disturb the league referee's runs while it finishes match 2.
