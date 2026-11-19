# Match output, file by file

**Schema 1:** `summary.json` is the completed match manifest. The field names below replace
pre-schema names (round `attack`/`health`/`golden`, fight-round `health`). `red_seats` now lists
this game's red seats; before schema 1 it was the pair's unswapped layout.

`league match ... --out <dir>` writes these. Outputs are byte-identical except for
`cpu.jsonl`, `timing.json` and the runtime `summary.json.git_sha` field, for the same seeds,
bots, content and `--secret`, at any `--threads`, as
long as no seat's result depends on its CPU clock (a bot that reads `clock_left_ns` to stop a
search, or a clock-out, can change its own play from run to run). JSON lines are in game order.

Seats are player ids 0..7. A game index `g` plays seed line `g / 2` of the seeds file; odd `g`
is the same seed with the colours swapped.

## `records/game-<g>.jsonl`

Each game as a format-3 record, the same lines `GameRecord` writes: `header` (with the pinned
GDScript build's fingerprint, `league/build.json`), then per round `start`, every `act`, each
`end`, `fight_boards`, `finish`. `scripts/records.sh record=<file>` replays it in GDScript;
`target/release/bramble-replay replay --record <file>` in Rust.

## `games.jsonl`: one line per game

```
{"game": 0, "seed": "123", "swapped": false, "red_seats": [0, 3, 4, 6], "rounds": 17, "round_limit_hit": false,
 "seats": [ {seat line} x 8 ], "fights": [ {fight round} ... ]}
```

`game` is the zero-based match index; `seed` is the decimal engine seed as text;
`swapped` is true for odd game indices. `red_seats` lists the seats that are red in **this**
game (each seat's `colour` says the same); the two games of a pair swap them. `rounds` is the final session round number;
`round_limit_hit` compares it with the bot Library's `round_limit` config.

A seat line:

| Field | Meaning |
|---|---|
| `seat`, `colour`, `bot` | player id, `red`/`blue`, registered bot name |
| `place` | final placement, 1..8 |
| `died_round` | `PlayerState.eliminated_round` when positive, otherwise null. Survivors, including those placed at the round limit, have null |
| `clock_out` | null, or `{round, call, used_ms}`: the call (`new_bot`, `choose`, `report`) that ended over the clock. Its result was discarded; SimpleBot played the rest |
| `panic` | null, or `{round, call, message}` (message with file:line) |
| `fault` | null, or `{round, index, legal}`: an index outside the legal list |
| `refused`, `last_refusal` | actions the engine refused (the turn then ends, as `Bot.take_turn`) |
| `final_board` | the board at the seat's last fight: `[{card, golden, slot, attack, health}]` |
| `main_tribe` | of the final board: most units; ties to higher total attack+health of that tribe's units, then the name. A unit of tribe `All` counts for every tribe. `null` with no tribal unit |
| `commit_round` | first round with 4+ units of the final main tribe, or null |
| `pivots` | `[{round, from, to}]`: after the commit round, a round whose main tribe (with 4+ units) differs from the last such main tribe |
| `rounds` | one entry per round the seat was alive, after all turns and before the fights, except `gold_from_cards` finalized after fights; fields below |

Each seat's `rounds[]` entry:

| Field | Meaning and source |
|---|---|
| `round` | `GameSession.round_number` |
| `tribes` | `{tribe: unit count}` from board card definitions; `All` counts for every tribe |
| `board` | `[{card, golden, slot, attack, health}]` in board reading order, same shape as `final_board`. From each board unit's definition id, golden flag, slot and engine `attack()`/`health()` (including slot buffs) |
| `hand` | card ids from `PlayerState.hand`, in hand order; includes spells |
| `heaps` | `{heap name: entry count}` from existing `PlayerState.heaps` and each heap's `entries.len()`; empty heaps are included, absent heaps are not created |
| `counters` | raw `PlayerState.counters` dictionary, with its keys and values unchanged |
| `board_attack`, `board_health` | sums of `attack`/`health` in `board` |
| `tier` | `PlayerState.tier` before fights |
| `gold_start` | gold in the seat's first decision view, after start-of-turn effects and before choosing any action; null if the seat had no decision |
| `gold_left` | `PlayerState.gold` after the turn |
| `gold_from_cards` | gross positive gold **generated** by cards this round, finalized after fights: positive `amount` in session `gold` events for this player with `source_uid >= 0` (`RecruitContext::gain_gold`, including start/end-turn and after-fight Relic Seeker payouts), plus positive `PlayerState.gold_next_turn` after combat (`FightSide::add_gold`, e.g. Cutpurse). `start_turn` resets `gold_next_turn`, so each combat payout counts in the round earned, not again when credited next turn. Excludes normal income, ordinary sale proceeds, spending, and source-less standing effects. Combat payouts become spendable next round, so the next `gold_start` includes them too. Combat events need not be retained |
| `triple` | whether the session events contain a `triple` for this player this round |
| `golden_gained` | whether the count of golden cards in board and hand increased since the last round (not a count of triples) |
| `slot_buff` | whether serialized `PlayerState.slots` changed since the previous round (stats or keywords) |

`fights[]` has one entry per round with `round`, `fights`, `players` and `renown`. `round` is the
session round number. `players` is all seats, in seat order, **after** fights and elimination:
`[{seat, hp, armor, alive}]` from `PlayerState.id`, `health`, `armor`, `alive`.

The round's `renown` contains the game log's Renown events in order, including after-fight
Recruit hooks. Each carries `type`, `round`, `player`, `slot`, `amount`, `total` and `source_uid`.
Each nested `fights[]` item has `a`, `b`, `winner`, `loser`, `damage`, `result`,
`ghost_of`, `kills`, `summons` and `renown`.

| Field | Meaning and source |
|---|---|
| `a`, `b` | seat ids from the engine fight's `players`; `b == -1` is the ghost (`Matchmaking::GHOST`), not -2 |
| `winner` | result winner side mapped to `a` or `b`, so -1 when the ghost won; **null for a draw** |
| `loser` | engine fight's `loser`: seat id, -1 for the ghost, -2 when there is no loser |
| `damage` | engine fight's damage to the losing live player **before armour** (0 when no live loser); `players[].hp`/`armor` show what was lost |
| `result` | engine combat result dictionary, unchanged, from `GameSession::finish_round`; combat events are read separately for the two counts |
| `ghost_of` | null for a live opponent, otherwise the seat copied by the ghost: session `ghost_of` captured **before** `finish_round`. `_fight` uses `ghost_board`, `ghost_hand`, `ghost_player`; `_eliminate` can replace them for the next round, so the post-fight value would be wrong |
| `kills` | Two arrays in `[a, b]` order, including zero counts. Every starting unit has a row `{card, golden, slot, origin: "start", source: null, kills}` in slot order. Arrivals follow, grouped by `{card, golden, origin, source}` with `kills` and no slot. A `"summon"` names the summoning unit's card id, or null when the event names no unit. A `"reserve"` has null source. Each enemy death credits the engine's `killer_uid`, the last recorded damaging or destroying source, including Cleave and other effects. Kills by returned copies credit the original unit and its origin. Deaths with no credited enemy unit add no kill |
| `summons` | Two arrays in `[a, b]` order. Each groups successful `summon` events by `{source, card, count}`, sorted by source and summoned card id. `source` is the summoning unit's card id, or null when the event names no unit. Waiting summons count when they land. Failed summons, returns and Reserve arrivals are excluded |

| `renown` | Combat Renown events in order, each with `type`, `side`, `slot`, `amount`, `next_fight`, `permanent` and `source_uid` |

The per-fight arrays use the ghost's combat board and events on side `b` when applicable. These additive
fields keep the manifest at schema 1.

## `decisions.jsonl.gz`: one line per decision

Every decision every seat made, with the full list of legal actions it chose from, in the
engine's order:

```
{"game", "seat", "colour", "bot", "by": "bot"|"fallback", "round", "step", "gold", "tier", "board_n", "hand_n",
 "legal": [{"type", ...the action's fields..., "card", "price"}], "chosen": index, "result"}
```

- `board_n` counts occupied slots in the decision view's `me.board`; `hand_n` is the length
  of `me.hand` (units and spells). Both describe the state **before** the action.
- `legal` entries carry the action's own fields (as in the record) plus `card`: the card bought,
  sold, played, picked, or whose ability it is. Buys also carry `price`. Moves, refresh, freeze,
  upgrade and end turn have no card.
- `by` is `fallback` once the seat's bot has clocked out, panicked or faulted and SimpleBot
  plays on.
- `step` counts decisions within the seat's turn, from 0. `result` is the engine's answer to
  the chosen action: empty when it was accepted.
- The lines match the record's `act` lines one for one, in game order.

The file is gzipped (`gzip -f -n`, so it stays byte-identical) when the match ends, from about
1.7 GB to about 40 MB for 1,000 games. Read it with `zcat` or Python's `gzip.open`. If gzip is missing or fails, the text
`decisions.jsonl` is kept. `--no-decisions` omits this log.

## `cpu.jsonl`: one line per game (not deterministic)

`{"game": g, "seats": [{"seat": 0, "cpu_ms": 41.2}, ...]}`: each seat's thread CPU time spent in
its bot (construction, every `choose` and `report`, and its Sim work), the fallback bot excluded.

## `shops.jsonl.gz`: one line per shop a bot saw

A new line starts at the seat's first decision of each turn (`reason: "turn_start"`), after a
refresh (`"refresh"`), and whenever the shop changed other than by the bot buying from it
(`"changed"`: an ability, a Discover, an upgrade that changed it). While a Discover is pending
no shop line is started (those decisions are in `discovers.jsonl`).

```
{"game", "seat", "colour", "bot", "round", "reason", "gold", "tier",
 "offers": [{"card", "spell", "index", "buyable"}], "bought": [{"card", "spell", "index"}]}
```

`buyable` is true when a buy of that slot was in the legal list when the shop was seen:
affordable, with room in the hand. `bought` lists what the seat bought from this shop before it
changed. At match end, `gzip -f -n` compresses `shops.jsonl` deterministically, just like
the decisions log. If gzip is missing or fails, `shops.jsonl` stays as text.

## `discovers.jsonl`: one line per Discover choice

`{"game", "seat", "colour", "bot", "round", "options": [card ids], "pick": index, "card": id}`.

## `reports.jsonl`: one line per `report()` that returned something

`{"game", "seat", "colour", "bot", "round", "kind": "shop"|"discover", "offered": [card ids],
"strategy", "values": [[card id, value], ...]}`. `report` is called (on the seat's clock) when a
shop line starts and at each Discover choice. Values are on the bot's own scale.

## `library.json`: the match's card lookup

A JSON array sorted by `id`, taken from `Engine.library.cards()` (the harness `Library` passed
to bots in `BotSetup` and decision views), with one object per card:

| Field | Meaning and source (`CardInfo`) |
|---|---|
| `id`, `name` | card id and display name |
| `tribes` | tribe names, including `All` where applicable |
| `tier` | card tier |
| `attack`, `health` | base card stats, not a particular unit's buffs |
| `spell`, `token` | whether the card is a spell or a token |

Analysis can join card ids to this file without reading external card files.

## `summary.json`, `timing.json`, `private/secret.txt`

`summary.json` is published atomically **last**, after every game, log flush, compression
attempt and `timing.json` write. It is absent for an interrupted/failed match. Starting a run
in an existing output directory removes the old summary first, preventing a stale completion
marker. `private/summary.json.tmp` can remain if interrupted during publication.

| Manifest field | Meaning and source |
|---|---|
| `schema` | integer 1, the log schema documented here |
| `complete` | always true; an incomplete run has no summary |
| `rules_hash` | pinned build fingerprint from the harness's embedded `league/build.json`, the same build used by record headers |
| `git_sha` | trimmed stdout of runtime `git rev-parse HEAD` in the repository root, or null if unavailable; identifies the checkout, not uncommitted edits. Excluded from thread determinism comparisons |
| `red`, `blue` | bot names from `MatchArgs` |
| `red_label`, `blue_label` | optional `--red-label` / `--blue-label` team tags (e.g. `red-m1`), defaulting independently to the respective bot name; labels do not select bots or affect play |
| `seeds_sha256` | lowercase SHA-256 of the exact seeds file bytes read for this match, including comments, whitespace and unused seed lines |
| `games` | number of completed games |
| `clock_ms` | configured CPU clock per seat per game |
| `content` | content argument, default `all` |
| `red_avg_place`, `blue_avg_place` | colour's mean placement over all its seats |
| `gap_red_minus_blue` | red mean placement minus blue mean placement |

`timing.json` (not deterministic): wall seconds, threads, seconds a game.
`private/secret.txt`: the match secret the bots' seeds come from (see README). Don't give it to
the teams; with it, the bots' seeds of every game can be worked out.

## `analysis.json` (written by `league analyze <dir>`)

The score with 95% intervals over the seed pairs, placement by seat and by colour, and the
health counts. Pairs are grouped by integer `game / 2`, so repeated seed text on
different seeds-file lines remains separate. Reads the plain-text `games.jsonl`. See README.

## Combat TSVs

`tools/league/analyse_match.sh MATCH` writes `kills_by_card.tsv`, `summons_by_source.tsv` and
`kill_shares.tsv` next to the match logs. See the [analysis notes](../analysis/README.md#combat-tsvs)
for the columns and denominators.
