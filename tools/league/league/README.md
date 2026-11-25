# `league`: the bot league's match harness

The plan is `docs/workstreams/bot-league/brief.md` (sections 5, 5a, 5b step 4, 6, 8, 9). The
engine is `../bramble-engine`, a bit-exact port of the GDScript rules. Log formats are in
[LOGS.md](LOGS.md).

```
tools/league/
  league-api/          the crate bots depend on: Bot, BotView, Sim, Sandbox, Action, Report
  league/              this binary and library: game loop, seats and seeds, clock, logs,
                       baselines, selfcheck, check-crate, analyze, refight, bench
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

# Fight the recorded boards again using the current engine and card data.
target/release/league refight --match build/matches/m1 --out build/refight/m1 \
  [--repo-root <dir>] [--select tribe:<name>[:<min>]] [--threads N] [--verify]

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

## Refighting a match

Pass a completed `league match` directory with its `records/`, `games.jsonl`, and
`summary.json`. Each refight restores both pre-fight payloads, including the ghost where
applicable, and uses the baseline game seed, round and ordered pairing. The baseline
match's content option selects the card folders under `--repo-root`, which defaults to the
checkout the binary was built in. The engine, config and card definitions come from the
binary and that checkout. Refights are independent and log in game and round order at any
thread count. The default is one thread.

`--select tribe:badger` keeps fights with at least four Badger units on either baseline
board. Tribe names are case-insensitive and an optional positive integer overrides the
minimum. `All` units count toward the selected tribe. Qualifying sides come from the
baseline `library.json` and pre-fight boards, so the same sides are compared across rule
changes. With no selector, both sides qualify for every fight.

- `refights.jsonl` logs `game`, `round`, `players` in original pair order, `ghost_of`,
  `qualifying_sides` as player IDs, `original_winner`, `original_damage`, `new_winner`,
  and `new_damage`. A winner of `null` is a draw and `-1` denotes the ghost. Damage is
  before armor. A skip records its reason in `skip` and has `null` new winner and damage.
  A card absent from the new content or a payload that cannot be restored skips the fight.
- `summary.tsv` gives one pooled row (`all`) and one row per pairing position (`a`, `b`).
  `sides` counts qualifying sides with both outcomes. The pooled row leaves out fights
  where both sides qualify, since they cancel to zero; the per-side rows keep them.
  Win, draw and loss rates and new-minus-original changes are fractions.
  The 95% intervals use Student's t on paired differences, clustered by seeds-file line
  to account for correlated fights and colour-swapped games. An interval is `NA` with
  fewer than ten represented seed lines. Rates are `NA` with zero observations.

**What a refight can and can't show.** Each unit keeps everything it had when the fight was
recorded: buffs, granted effects and counters. Only base stats and each card's own effects
come from the new rules. So a refight measures changes to combat: stats, combat effects and
keywords. It can't see changes to the shop phase, economy, tiers or what the bots buy; a full
match on the new rules measures those.

Run `--verify` against the original binary and content to require the same winner, damage and
full combat result from `games.jsonl` for every fight, including those outside a selector.
Skips and mismatches are logged even if unselected. Verification exits 1 if any fight was
skipped or differed and writes any result differences to `verify_mismatch`.

### Switching one thing off (card power)

```
league refight --match <dir> --out <dir> [--text-off] [--keyword-off <id>[,<id>...]]
               [--overrun-swings] [--seeds 4] [--cap 1000] [--threads N] [--verify]
```

These modes measure what one card's text, or one keyword, is worth in the fights a match
recorded (`docs/workstreams/card-power/definitions.md`). They write one JSON line per
observation and aggregate nothing. With none of them asked for, `league refight` works as above.
`--select` doesn't combine with them.

Each fight is first fought as recorded on `--seeds` seeds: the recorded one, then seeds
derived from it (game seed `hash32("<seed>|refight|<k>")` for k = 1, 2, ..., from which the
engine derives the fight seed from round and pairing as usual). The recorded seed must give
the recorded winner and damage (with `--verify`, the full combat result too). A fight that
doesn't is left out, logged on stderr and counted as "not reproduced"; `--verify` then exits 1.
The changed board is fought on the same seeds.

**Text off** (`--text-off`, `text_off.jsonl`). One observation is one unit on a board at the
start of one recorded fight. That unit keeps its stats, slot, counters and everything given to
it (grants, and what auras and its slot give it in the fight). Its own card's mechanics, printed
keywords included, are removed for that fight. Because auras are worked out again in the fight,
an aura the unit gives others goes too.

**Keyword off** (`--keyword-off`, `keyword_off.jsonl`). Takes mechanic ids from the card
data: `badger_overrun`, `cleave`, `badger_fury`. One observation is one side that has the
keyword at the start of the fight. That side's keyword does nothing, on every unit, printed or
given. The other side's copy still works, so fights where both sides have it are kept, one
observation per side. A side **has** the keyword when at least one of its board units holds the
mechanic in the recorded `fight_boards`: printed on its card, in its `grants`, in its
`aura_grants` (Greatsword-bearer and Dame of the Old Sett give Overrun this way), or as a
keyword of the slot it stands in. A unit that gets the keyword only during the fight doesn't
make its side count. A keyword with an aura, a death effect or an ability is refused.

**Sampling.** At most `--cap` observations per card (text off) or per keyword (keyword off)
per stage (rounds 1–4, 5–8, 9–12, 13 on). The kept ones are those with the lowest
`hash32("text_off|<game>|<round>|<position>|<slot>")` (keyword off:
`"keyword_off|<id>|<game>|<round>|<position>"`). The outcome is never looked at.

Fields of both files:

| Field | Meaning |
|---|---|
| `mode` | `text_off` or `keyword_off` |
| `game`, `round`, `stage` | match game index, round, and `1-4`, `5-8`, `9-12` or `13+` |
| `player`, `ghost_of`, `position` | the observed side: its player id (`-1` for a ghost), the ghost's source player (else null), and `a` or `b` in the pairing |
| `seeds` | seeds per board |
| `slot`, `card`, `golden`, `tier` | text off only: the unit's board slot, card id, golden flag and card tier |
| `keyword`, `keyword_units`, `enemy_keyword_units` | keyword off only: the mechanic id, and how many units hold it on the observed side and on the enemy's |
| `score_recorded`, `score_off` | the observed side's mean score, win 1, draw ½, loss 0: board as recorded, and with the change |
| `dealt_recorded`, `dealt_off` | mean damage the observed side's win deals to the enemy player (0 on a draw or loss) |
| `taken_recorded`, `taken_off` | mean damage the observed side's player takes |
| `result_changed` | the change gave a different winner (or a draw) on the recorded seed |
| `own_units`, `enemy_units` | units on each board at the start of the fight |
| `enemy_median_health` | median Health of the enemy's units at the start of the fight, as the recruit board shows it (auras included); null for an empty board |

Damage is before armour. The engine deals a ghost no damage; here a ghost that loses takes
what a player would, so damage reads the same for every fight.

**Overrun swings** (`--overrun-swings`, `overrun_swings.jsonl`, `overrun_swings.tsv`). Every
recorded fight is fought once more on its recorded seed, with the board as recorded, while each
attack by a unit holding Overrun is noted. The count is left out if the fight's result changes
(it never should). One line per such attack: `game`, `round`, `stage`, `player`, `ghost_of`,
`position`, `card`, `golden`, `enemy_standing` (enemy units standing when the attack began),
`kills` (enemy units that died credited to the attacker, from its attack up to the next attack:
the target, carried damage and Cleave), and `whole_board` (it killed every enemy unit that was
standing). `overrun_swings.tsv` counts them per stage: `attacks`, `kills_0`, `kills_1`,
`kills_2_plus`, `kills_3_plus`, `whole_board`. An attack counts once it reaches the "on attack"
step: one stopped by an "is attacked" effect isn't counted.

**What these can't show.** Anything outside the fight: gold, shop effects, growth over turns,
or what a Recruit effect already gave other units. The boards are the ones bots built around
each card. A unit that comes back during the fight (Reborn given by another card) can come
back as a fresh copy of its card, text included. An attack made at once inside another
attack (Oakfeller) starts a new swing count.

The modes don't change the engine's rules code. Text off edits the restored unit in the
refight's own session. Keyword off and the swing count give that session its own copy of the
mechanic registry, in which the chosen mechanic is wrapped (`src/refight/switch.rs`). The
wrapper asks the real mechanic for every hook, and does nothing for units of the switched-off
side. A test wraps every mechanic and checks that 300 random boards fight exactly as before.

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

## Leaving cards out of the shop

`league ghost-match ... --without <card id>[,<card id>...] --no-records` plays a ghost match in
which the live seat is never offered the named units, in the shop or in Discover. The shop
draws other cards in their place by the normal tier weights. Seeds, secret, lobbies, bots and
seats are those of the same match without the flag, so the two pair game by game. It measures
"Left out of the shop" in `docs/workstreams/card-power/definitions.md`.

- The harness rebuilds the game's unit draw list without the cards right after it creates
  each session, before the first shop fills. The engine's rules code is unchanged. Ghost seats
  never shop; their recorded boards still hold the cards and play as recorded.
- Every id must be a unit the shop draws. An unknown id, a spell, a token or a repeated id is
  an error before the output folder is touched.
- **Placement only.** Such a match writes no records, and `--without` without `--no-records`
  is refused. The draw list is not in the state hash, so a record could not say what was left
  out: it would not replay, and `bramble-ghosts cut` would put runs from a changed game into a
  field. `summary.json` lists the cards under `without`. Don't cut or refight these folders.
- Without the flag, `ghost-match` and `match` write the same bytes as before.

Two scripts in `analysis/` use it:

- `python3 card_without_run.py BASELINE OUT_ROOT --field STORE --seeds FILE CARD...` plays one
  `--without <card>` match per card into `OUT_ROOT/<card>`, one after another, with the
  baseline's bots, labels, games, clock, content and secret, `--no-records --no-decisions`, and
  `--timeout` seconds per match (default 7200). It checks the seeds file against the baseline's
  SHA-256 and each finished match's lobbies against the baseline's, skips cards already done,
  and stops at the first failure.
- `python3 card_without.py BASELINE WITHOUT... [--control RERUN] [--out FILE.csv]` writes one row
  per card per bot: games, mean place with and without, the mean paired difference (without
  minus with, by game index) with its 95% interval over seed lines, the baseline games in which
  the bot bought the card at least once, and the definition's `too_few` and `flag`. It refuses
  matches whose summary fields, secret, games, seeds or lobbies differ.

**Clock noise.** The red and blue bots read their CPU clock to size searches, so two runs of the
same match differ in some games (4 of 40 on a busy machine, 25 Nov). That noise lands in the
paired difference. `--control` takes a second, flag-free run of the baseline; its `(control)`
rows show the size of the noise.

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
size; it runs its Recruit as a buy into hand does (when it completes a triple, only the golden
recruits). `Swap { hand, slot }` swaps a hand unit with a board
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

