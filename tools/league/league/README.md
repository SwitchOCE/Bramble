# `league`: the bot league's match harness

The plan is `docs/workstreams/bot-league/brief.md` (sections 5, 5a, 5b step 4, 6, 8, 9). The
engine is `../bramble-engine`, a bit-exact port of the GDScript rules. Log formats are in
[LOGS.md](LOGS.md).

```
tools/league/
  league-api/          the crate bots depend on: Bot, BotView, Sim, Sandbox, Action, Report
  league/              this binary and library: game loop, seats and seeds, clock, logs,
                       baselines, selfcheck, check-crate, analyze, bench
  bots/registry/       `league-bots`: the team crates compiled into the binary, by name
  bots/examples/       clean/ (a clean team-style bot), testbots/ (busy, hang, panic, fault,
                       burn), cheat-*/ (planted cheats; outside the workspace on purpose)
  bots/red, bots/blue  the teams' folders: bot crate, data/, tools/ (registered at the engine tag)
```

Build from `tools/league/` (Rust is in `~/.cargo/bin`):

```sh
export PATH="$HOME/.cargo/bin:$PATH"
CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p league
target/release/league bots          # every registered bot name
```

## Commands

```sh
# A match: 2 games per seed line (colours swapped), one game per thread.
target/release/league match --red flow --blue random --games 1000 --seeds seeds.txt \
  --clock-ms 1000 --threads 4 --out /home/alex/league/matches/m1 [--content standin] [--secret HEX] \
  [--red-label red-m1] [--blue-label blue-m1]
target/release/league analyze /home/alex/league/matches/m1

# An async match: each bot plays the live seat against the same seven runs in its pair.
target/release/league ghost-match --red red --blue blue --field field --games 200 +  --seeds seeds.txt --clock-ms 5000 --threads 4 --out ghost-match [--secret HEX]

# Baselines against the GDScript reference records (records.gd's games, line for line).
target/release/league selfcheck --records /home/alex/league/records/gd/c0 \
  --records /home/alex/league/records/gd/c1 --records /home/alex/league/records/gd/c2 --threads 2

# The crate rules (brief 5a) and an isolated build.
target/release/league check-crate /home/alex/league/red/tools/league/bots/red --name red

# Speed: whole records.gd-style games, and Sim.fight on round 12+ payloads from records.
target/release/league bench --games 20 --fight-records /home/alex/league/records/gd/c0 --fights 2000
```

`--content`: omitted or `all` is the shipped game (`GameContent.load_default`, all five tribes);
`standin` is the stand-in cards; otherwise comma-separated `src/content` folders in order.

Exit codes: 0 done, 1 a failure (`selfcheck` mismatch, `check-crate` problem, bad input),
2 usage, 3 the watchdog aborted the match.

## Async matches

`ghost-match` takes an even number of games. Each seed creates a lobby using
seven runs from the field with the current rules hash. Game `2p` puts red in
seat 0 and game `2p+1` puts blue there. Both games use the same seed and runs
in the same seats. A run is eligible for only one pair, so 200 games need at
least 700 eligible runs. Reuse the match secret and seeds to reproduce the draw.

The score is each team's mean placement from seat 0. The mean of the paired
red-minus-blue differences is `gap_red_minus_blue`. The lower placement wins.
The session plays out after seat 0 is eliminated, and fight logs cover all seats.
Optional `--red-label` and `--blue-label` tag the live seat for later cutting.

To save the live seats' runs, use
`bramble-ghosts cut --match ghost-match --ghost-store field --store new-runs --made TIME`.
Keep the field available to replay the source match.

## Seats, seeds and the secret

- The seeds file has one decimal seed per line (blank lines and `#` comments skipped). Game `g`
  plays seed line `g / 2`; odd `g` swaps the colours. `--games N` needs `ceil(N/2)` seeds.
- Colours: 4 red and 4 blue seats, shuffled per seed pair from the secret
  (`red_seats` in `matchrun.rs`; the owner's pick, 18 Nov, so teammates can't be told from seat
  numbers). The second game of the pair swaps every colour, so each seat is red exactly once a
  pair. `games.jsonl` logs the unswapped game's red seats.
- All five tribes are in every lobby (`content.new_session(seed)`), as in the shipped game.
- Each seat gets a fresh bot each game: `new_bot(seed, &setup)`, where `seed` is the first 8 bytes
  of `sha256("<secret>|bot|<game>|<seat>")`. The secret is random per match (from `/dev/urandom`),
  or `--secret` to replay one; it is written only to `<out>/private/secret.txt`. So no bot can
  work out the game seed, and a seat's seed says nothing about its colour. Each seat's `Sim` has
  its own stream from `sha256("<secret>|sim|<game>|<seat>")`.
- The turn loop is `tools/checks/records.gd`'s and `Bot.take_turn`'s: each round `start_round`,
  each alive player in id order takes its turn (up to `Bot.MAX_ACTIONS` = 120 actions; a refused
  action is counted, ends the loop, and the turn ends), then `finish_round`, until `over`.
- Games run one per thread, up to `--threads`; outputs are written in game order, so a match is
  byte-identical at any thread count (see LOGS.md for what is excepted).
- `--red-label` and `--blue-label` are optional manifest tags, defaulting to the bot names.
  They never affect bot selection, colours or random streams.
- Schema 1 matches include `library.json` (the bots' card lookup) and a completed match
  manifest in `summary.json`. The manifest is published last; failed/interrupted runs have
  no summary, including when an output directory is reused. `shops.jsonl` and
  `decisions.jsonl` are compressed with `gzip -f -n` at match end, or kept as text if gzip
  is unavailable. `games.jsonl` stays plain text for analysis.

## The clock

Each seat has `--clock-ms` of **thread CPU time** per game (`clock_gettime(CLOCK_THREAD_CPUTIME_ID)`),
measured around every call into the bot: `new_bot`, every `choose` and `report`, and the Sim work
inside them. The view's `clock_left_ns()` gives what was left at the start of the call, and
`sim.clock_left_ns()` reads it live, so a search can stop in time.

- A call that ends with the seat over its clock has its result discarded; a clock-out is logged
  and SimpleBot plays the rest of that seat's game.
- A panic in a bot (caught with `catch_unwind`), or an index outside `view.legal()`, is handled
  the same way, with the panic message or the index logged. A panic inside a `Sim` or `Sandbox`
  call is caught there and returned as `Err` to the bot, so an engine panic on a strange payload
  doesn't cost the bot its seat.
- **A call that never returns can't be stopped safely.** A watchdog thread reads each game
  thread's CPU clock (`pthread_getcpuclockid`). If one call runs past the seat clock plus 5 s of
  thread CPU time, or 60 s of wall time, it **aborts the whole match** (exit code 3), printing the
  bot, colour, seat, game and round. The match is then replayed after the team fixes the bot.

## The bot API (`league-api`)

The existing `Buy { spell, index }` and `Pick { index }` actions use the default Recruit
target (the gained unit). `BuyTarget` and `PickTarget` let a bot name a friendly unit's uid
at acquisition. Effects that ask after a gain expose `RecruitTarget` choices in board-then-hand
order. `Sell { slot }` sells from the board. `SellHand { hand }` sells from hand, and
`ToHand { slot }` returns a board unit that can still move to hand this turn.
`BuyBoard { index, slot, target }` buys a unit straight into an empty board slot, at any hand
size; it runs its Recruit like a play. `Swap { hand, slot }` swaps a hand unit with a board
unit: the board unit takes that hand index, nothing settles and no Recruit runs, and a unit that
Worked this turn can't be swapped out. `UnitView.own_attack` and `own_health` are a unit's
stats before board auras and slot effects.

```rust
pub trait Bot {
    fn choose(&mut self, view: &BotView, sim: &mut Sim) -> usize;            // index into view.legal()
    fn report(&mut self, _view: &BotView, _sim: &mut Sim) -> Option<Report> { None }
}
// a bot crate exposes:
pub fn new_bot(seed: u64, setup: &BotSetup) -> Box<dyn Bot>
```

`BotSetup` gives the seat id, the card library and the clock. `BotView` is built by the harness
for each call and holds only what a player may know, as owned copies (nothing in it refers to a
live game object): its own player in full (`me()`: board, hand, shop and prices, gold, tier,
Discover options and queue, counters, heaps, slots, standing effects, refresh/upgrade costs, sell
values, its own fight payload), every player's id, health, armor, tier, alive and placement,
the round, this round's opponent, the fight payload of each past opponent as it was when they
fought (ghosts included), the card library and the `GameConfig` numbers, the legal actions in
`LegalActions.of` order, and the clock left. Its fields are private (read through methods);
the record types inside it (`Me`, `UnitView`, `CardInfo`, ...) have public fields, which a bot
can only read through the `&BotView` it is given. Payloads and their units clone deeply.

`Sim` (one per seat per game, sharing nothing):
- `fight(a, b, seed)`: one fight on two payloads, run as `fights/FORMAT.md`'s runner does (a fresh
  session seeded `seed`, round = the current round, both payloads restored, `GameSession._fight`
  once). Gives winner, loser, damage, reason, survivors and both sides after the fight.
- `sandbox()`: a recruit sandbox that can't leak: a full copy of the bot's own player now, the
  others as their last fight payloads (with public health, armor, tier and alive), and the live
  lobby's fixed unit and spell draw tables. Shop and Discover RNG streams are seeded by the Sim.
  Nothing is written back. `Sandbox` has `legal()`, `act(&action)`,
  `end_turn()`, `view()`, `payload()`, `fight_vs(&payload, seed)` and `fork()`.
- `next_seed()`, `clock_left_ns()`.

Why this shape: the brief's sketch, with three choices. Bots get typed `Action`s (they never
build engine dictionaries). The harness enumerates the engine's action fields directly into
typed actions, then builds the selected dictionary in the engine's original key order.
Sim and Sandbox return plain data only, never engine objects, so a bot can never hold a
reference that reaches the library, registry or another seat. And `report` returns
`(card id, value)` pairs, because a shop can offer the same card twice.

`league-api` also has a `harness` module that the harness uses to build views and sims. It
needs engine objects to call, which a bot can't obtain, and `check-crate` rejects a bot that
names it. The doc tests in `league-api/src/lib.rs` show the rest of the surface by construction.

## Baselines

The baselines `simple`, `flow` and `random` play through `BotView`. TribeBot is not a player:
no match, ghost match or field cut can use it (owner note
[`2026-11-20a`](../../../docs/design/owner-notes/2026-11-20a-strong-bots-for-balance.md)). It only
drives the engine check below.

`league selfcheck` plays the GDScript reference seeds through the harness and compares every
action, result and state hash. Its default lobby gives FlowBot even seats and RandomBot odd
seats. `league selfcheck --bots tribe --records <dir>` checks TribeBot's games against
`gd/tribe_records.gd`: it is the check that tribe mechanics play the same in Rust and GDScript,
since the simple baselines rarely trigger them. Both lobbies seed each bot with `Rng.derive(seed, "bot:%d" % seat)`.

## The teams' crates

`bots/red` and `bots/blue` are the teams' folders, already in the workspace and the registry
(as the bots `red` and `blue`), so a team never edits a file outside its folder. Each holds:

- the bot crate (package name `red` or `blue`; `src/lib.rs` with `new_bot`), starting as a copy
  of `bots/examples/clean`. It must pass `check-crate`;
- `data/`, for tables built offline, read with `include_bytes!("../data/...")`;
- `tools/`, the team's own crate (`red-tools`, `blue-tools`): self-play, weight searches, log
  analysis. It may use files, threads and the harness. `check-crate` doesn't scan it, the bot
  can't reach it (`include!` and `#[path]` into `tools/` fail), and no match runs it. Its
  dependencies are fixed at the engine tag: `league`, `league-api`, `serde_json` and `sha2`
  (a new one changes the shared `Cargo.lock`; ask the referee). Run it with
  `cargo run --offline --locked --release -p red-tools -- <games> <seeds> <out>`.

For a match:

1. Fetch the tag and replace the team's bot crate in the referee's workspace, keeping the
   engine tag's stub `tools/` (the referee never builds or runs a team's tools: they could hold
   a `build.rs`, and the referee's tree has both teams' code):
   `find bots/red -mindepth 1 -maxdepth 1 ! -name tools -exec rm -rf {} + && git -C /home/alex/league/red archive red-m1 tools/league/bots/red | tar -x -C <worktree> --exclude='tools/league/bots/red/tools'`.
   Check that the tag's diff touches nothing outside `tools/league/bots/red/`.
2. Run `league check-crate tools/league/bots/red --name red`.
3. Build with `--offline --locked`. Nothing else changes.

Two versions of one team's bot (strength checks): copy the older tag's folder to
`bots/red-m1/` without `tools/`, change its `[package] name` to `red-m1` (Cargo won't take two
packages of one name), add it to the workspace members and `bots/registry`
(`("red-m1", red_m1::new_bot)`), and `cargo update --offline --workspace`.

## `check-crate`

Rules (brief 5a), each failure with a reason and line: the manifest has only `[package]`,
`[lib]` and `[dependencies]`; every dependency is on the allowlist (`ALLOWED_DEPS` in
`src/checkcrate.rs`, now only `league-api`; to allow a vendored crate, put it in `vendor/` and
add its name there); no `build.rs`, `build =`, `links`, proc-macro, `.cargo/` or symbolic links;
`#![forbid(unsafe_code)]` in `src/lib.rs`; and a token scan of every `.rs` file (comments and
strings stripped) for `unsafe`, `static`, `thread_local!`, `OnceLock`, `LazyLock`,
`lazy_static`, `once_cell`, atomics, `extern`, `no_mangle`, `export_name`, `link_section`,
`asm!`, `env!`/`option_env!`, `Instant`/`SystemTime`, the `harness` module, memory addresses
(`{:p}`, raw pointers, `&raw`, `as_ptr`, `into_raw`/`from_raw`, `addr_of`, `fmt::Pointer`,
`leak`: an address could carry a message between seats), any
`std::`/`core::`/`alloc::` path outside `STD_ALLOWED` (that rules out `ptr`, `thread`, `fs`, `net`,
`process`, `env`, `time`, `io`, `sync`, `os`, `arch`, `ffi`, `panic`, `alloc` and the rest),
including in `use std::{...}` groups, `std::*` globs and `use std as x`; and
`include!`/`include_str!`/`include_bytes!`/`#[path]` must be a literal path inside the crate
folder. Then it builds in a fresh tree under `$TMPDIR` holding only the engine, `league-api`,
the harness, a registry with only this crate, and the vendored crates, `--offline --locked`
with `CARGO_BUILD_JOBS=2`, and checks the built `league bots` lists the crate. The planted
cheats `bots/examples/cheat-unsafe`, `cheat-static` and `cheat-include` must fail;
`bots/red` and `bots/blue` must pass (the stubs do). The package name must be the colour
(`--name`), and `tools/` is skipped.

The scan is for ways around the types; the types do the rest. A team crate can't name the
engine (not its dependency), and the view and Sim hand out copies only.

## Tests

`cargo test --offline --locked -p league -p league-api` runs, on stand-in content: a sandbox
refresh against the real next refresh (1,920 trials), the sandbox and views writing nothing back,
the busy bot's clock-out with the game finishing, panics and bad indices falling back, a match
byte-identical at 1 and 3 threads, records replaying in Rust, 3 stand-in selfcheck games, the
check-crate scanner, and the API's compile-fail doc tests.

The bounded speed pass and its complete parity proofs are in
[proof/SPEED.md](../proof/SPEED.md). A repeatable recruit sandbox benchmark is available as
`cargo run --release --offline --locked -p league-api --example recruit_bench -- /home/alex/league/proof/late-cases.jsonl 5000`.

