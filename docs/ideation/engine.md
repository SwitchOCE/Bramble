# The engine for card designers

How to put a card, spell or hero into `content/` without writing code, and how to add a script when data won't do. The names in this file are checked against `content/schema/effects.json` by a test, and `tools/checks/check_units.py` rejects anything the schema doesn't know.

## A data effect

Every data effect is one entry in a unit's `mechanics`:

```json
{
  "id": "effect",
  "trigger": "on_play",
  "if": [{"kind": "tier", "at_least": 3}],
  "target": {"select": "adjacent", "tribe": "Birds"},
  "do": {"effect": "buff", "attack": 2, "health": 2}
}
```

Trigger, then conditions, then target, then what happens. The card's text stays hand-written on the card. The checker wants each doubling number in `text` and its double in `golden_text`.

**Worked example.** A tier 2 Bird: "Whenever you cast a spell, give your front row +1 Attack this combat and get 1 gold next turn, twice a turn."

```json
{
  "id": "effect",
  "name": "song",
  "trigger": "on_spell_cast",
  "limit": 2,
  "do": [
    {"effect": "buff", "attack": 1, "duration": "combat", "target": {"select": "front_row"}},
    {"effect": "gold", "amount": 1, "when": "next_turn"}
  ]
}
```

On a golden copy the `attack` and `amount` become 2; `limit` stays 2 (rulebook 7.3.5: numbers double, thresholds keep their value).

Fields of an entry: `trigger`, `do` (one step or a list), and optionally:

- `name`: what the log calls it, and the key its `limit` and `every` count under.
- `if`: conditions, all of which must hold.
- `target`: the default target for steps without their own.
- `subject`: `self`, `other` or `any`, whose event this hears. Each trigger has a default.
- `subject_tribe`: only events about this tribe.
- `every` and `counter`: fires each Nth time (5: every fifth). `count_amount`: counts the event's amount, not 1.
- `limit`: at most this many firings a turn in recruit, a fight in combat.

## Triggers

Recruit Phase. All fire through one queue in `src/core/recruit_events.gd`; anything an effect causes waits behind it. Hero first, then the board in reading order, each unit then its slot, then a subject outside the board.

| Trigger | When | Subject |
|---|---|---|
| `start_of_turn` | Phase start, after income and shop | |
| `end_of_turn` | Phase end | |
| `on_buy` | A unit is bought | it, `self` by default |
| `on_play` | A unit is played from hand | it, `self` |
| `on_sell` | A unit is sold | it, `self` |
| `on_summon` | A unit is summoned (also in combat) | it, `other` |
| `on_move` | A unit changes slot | it, `self` |
| `on_refresh` | The shop refreshes | `paid` tells if it cost gold |
| `on_spell_cast` | A spell is cast (items don't count) | `card_def` for scripts |
| `on_tier_up` | Tavern tier goes up | |
| `on_triple` | Three copies combine | the golden, `any` |
| `on_gold_spent` | Gold is spent | `amount` is how much |
| `after_combat` | After the round's fights | |

Combat:

| Trigger | When |
|---|---|
| `start_of_combat` | Start of Combat step |
| `on_attack` | This unit attacks |
| `on_attacked` | This unit is attacked |
| `on_survived_attack` | This unit survives being attacked |
| `on_damage_dealt` | This unit deals damage (`amount`) |
| `on_damage_taken` | This unit takes damage (`amount`) |
| `on_death` | This unit dies |
| `on_friendly_death` | Another friendly unit dies (`other`) |
| `aura` | Continuous: `do` is one `buff` over `target`, recalculated as the board changes |

`activated` and `cast` belong to hero powers and to spells; you don't write them on units.

## Conditions

Each is `{"kind": ..., "at_least"?, "at_most"?, "not"?: true}`. All are thresholds: golden never doubles them.

| Kind | True when, or counts |
|---|---|
| `count` | Units matching its `target` selector |
| `gold` | Gold now |
| `tier` | Tavern tier |
| `round` | Round number |
| `hand` | Cards in hand, units and items |
| `amount` | The event's amount |
| `paid_refreshes` | Paid refreshes this turn |
| `chance` | Rolls `percent` out of 100 |
| `in_row` | Source is in `row` (`front` or `back`) |
| `at_row_end` | Source is at the end of its row |
| `undamaged` | Source has taken no damage (combat) |
| `golden` | Source is golden |
| `won_last_combat`, `lost_last_combat` | Last fight's result |
| `paid` | The event cost gold |

## Selectors

`{"select": ..., "of"?, "tribe"?, "not_tribe"?, "other"?, "golden"?, "tier_at_most"?, "pick"?, "count"?}`. Position selectors measure from the source, or from `"of": "subject"` or `"of": "chosen"`.

- Single: `self`, `subject` (who the event is about), `chosen` (where a spell or power was aimed).
- Sides: `friendly`, `others` (friendly but not the source), `enemies`, `front_row`, `back_row`, `enemy_front_row`, `enemy_back_row`.
- Geometry: `in_front`, `behind`, `adjacent`, `neighbours`, `row`, `row_ends`, `across`.
- Elsewhere: `hand`, `shop`.
- `pick`: `first`, `random`, `highest_attack`, `lowest_attack`, `highest_health`, `lowest_health`. `count`: how many. Ties break at random.

## Effects

| Effect | Params | Phase |
|---|---|---|
| `buff` | `attack`, `health`, `duration` (`permanent` or `combat`; the default is permanent in recruit, combat in combat) | both |
| `summon` | `unit`, `count`, `golden` | both |
| `gold` | `amount`, `when` (`now` or `next_turn`) | both |
| `add_card` | `card` (a unit, spell or item id), `count`, `from_pool` | both |
| `free_refresh` | `count` | recruit |
| `refresh_shop` | | recruit |
| `grant` | `mechanic` (an entry), `keyword`, `duration` | both |
| `status` | `status` | combat |
| `damage` | `amount` | both |
| `swap` | swaps source with its target | recruit |
| `move` | `to`: `front`, `back` or a label like `F2` | recruit |
| `slot_effect` | `attack`, `health`, `mechanic`, `name`, `text`, `at` (`chosen`, otherwise the target's slot) | recruit |
| `discover` | `count`, `tier` (`current`, `next` or a number), `tribe`, `not_tribe`, `kind` (`unit` or `spell`) | recruit |
| `rule` | `query`, `op`, `value`, `duration` (`turn` or `game`) | recruit |

Any step can add `per`: `gold`, `tier`, `hand`, `amount` or a selector. It multiplies the step's numbers. A step's own `target` wins over the entry's.

A combat effect that changes the recruit board goes back after the fight: permanent `buff` and `grant`, `gold`, `add_card`.

## Slot effects

A slot can hold effects for the rest of the game (rulebook 8.5). They stay when the unit moves, is sold or dies. They do nothing on an empty slot, and a fight copies them, ghosts included. `attack` and `health` apply to whoever stands there; `mechanic` is an entry that plays through them.

## Spells and hand items

`content/spells/<id>.json`:

```json
{
  "id": "sample_growth", "name": "Sample Growth", "kind": "spell",
  "tier": 1, "cost": 1, "pool": true, "aim": "unit",
  "text": "Give a unit +2/+2.",
  "do": {"effect": "buff", "attack": 2, "health": 2, "target": {"select": "chosen"}}
}
```

- `kind`: `spell` fires `on_spell_cast`; `item` doesn't. An Acorn is an `item` with `pool: false` that card text hands out with `add_card`. It waits in hand until played.
- `aim`: `none`, `unit`, `empty_slot`, `any_slot`, `front_unit`, `back_unit` or `shop_unit`.
- `pool: true` puts it in shops, from its own pool. `shop_spells_by_tier` and `spell_copies_by_tier` in `GameConfig` set how many.
- Hand items and units share the hand limit.

## Heroes

`content/heroes/<id>.json`:

```json
{
  "id": "sample_painter", "name": "Sample Painter", "armor": 2,
  "text": "Power (2 gold, once a turn): paint a slot.",
  "power": {
    "kind": "activated", "cost": 2, "uses_per_turn": 1, "aim": "any_slot",
    "do": {"effect": "slot_effect", "attack": 1, "health": 1, "at": "chosen"}
  }
}
```

Optional: `health`, `armor`, `requires_tribe` (not offered without that tribe). A `passive` power instead has `effects`, entries on any recruit trigger or on `start_of_combat`, and `rules`:

```json
{"query": "tier_up_cost", "op": "add", "value": 1, "if": [{"kind": "gold", "at_least": 5}]}
```

Rule queries, in the order added: `refresh_cost`, `tier_up_cost`, `income`, `shop_size`, `sell_value`, `back_row_first`, `buys_per_turn`, `tier_step`. `op`: `add`, `set`, `min`, `max`.

## The first slice: what it added

Cards from `docs/ideation/content/SLICE.md` carry `"set": "slice"`. `GameConfig.full_game()` draws units, spells, heroes and lobby tribes from that set only (`pool_filter: "slice"`, `card_set()`). `defaults()` keeps drawing the old library, which has no set, and sandbox scenarios can still name any unit. `pool_copies_by_tier` in `full_game()` is `[15, 15, 20, 16, 12, 10]`.

**Words a card's data can use**

- Triggers: `after_attack` (combat, after this unit's attack, only if it lived).
- Selectors: `touching` (the unbroken run of the zigzag through this unit, itself included), `facing` (in combat, the enemy front-row units in front of this unit's across slot). Selector field `row: "front" | "back"` keeps only that row.
- Conditions: `turns_in_slot` (`at_least`), `holds_item` (`card`, with `not`), `subject_in_row` (`row`).
- Effects: `pass` (`attack`, `health`), `multiply` (`factor`), `wait_in_slot` (`turns`, `attack`, `health`), `spend_all`, `burn_gold` (`above`), `tier_down`, `borrow` (`amount`, `repay`), `refresh_keep`, `borrow_attack`. `spend_all` and `burn_gold` set the step's amount, so a later step can say `"per": "amount", "per_div": 3`.
- `summon` gained `copies` (doubles on golden; `count` doesn't), `at` (`behind`, `behind_or_nearest`, `empty_rings`), `of: "subject"`, `spill` and `stats: "tier"`. `slot_effect` gained `at: "nearest_empty"`. Entry key `once: true` fires once per unit, ever.
- `per` words added: `carried`, `empty_adjacent`; with `per_div` and `per_max`.
- Aims added: `front_unit`, `back_unit`, `shop_unit`. A `shop_unit` aim's slot argument is a shop index.
- Rule queries added: `back_row_first`, `buys_per_turn`, `tier_step`.
- Mechanic scripts: `shy`, `eats_acorns`, `hex`, `rainbow`, `larder_stats`, `teind`, `back_strike`, `skip_across`.
- Hand items: `gold_value` and `combines_into`. Three of a size combine at once (`RecruitRules.give_card`); the third arrives even on a full hand. Three unit copies combining keep their Cold Frame waits, which restart when the golden lands; turn counts restart like any move. Bots in one lobby never share a hero (the human's offer is untouched). A slot passed to `play_item` with an Acorn feeds the unit there if its view has `eats_items`.
- Reminder text: `keywords` in `content/schema/effects.json`. Every unit and card view's `keyword_text` is `[{"keyword", "text"}]`; a card of a set takes it from there.

**State for screens and bots**

`get_state(player_id)` takes any player, by default the human. New keys:

| Key | Shape | Meaning |
| --- | --- | --- |
| `slot_effects` | 7 arrays of `{"name", "text", "attack", "health"}` | A slot's Ring is one entry named `Ring`, its numbers stacked. It stays after the unit leaves. |
| `bands` | 7 bools | Which slots have a Rainbow band. |
| `band_count` | int | How many. |
| `larder` | int | Gold your held Acorn items are worth. |
| `debt` | int | What Hob Mumblecrust repays next turn. |
| `buys_left` | int | Pipkin's limit; -1 for no limit. |
| `pending_passes` | array of `{"attack", "health", "from_slot", "landing_slot"}` | Passes waiting for End of Turn and where each lands now; `landing_slot` -1 means it would fizzle. |
| `hero.usable` | bool | The power's condition holds now (Jill can't drop below tier 1). |

A unit view adds `turns_in_slot`, `turns_goal` (0 if the card doesn't count turns, or once it has fired), `timers` (Cold Frame: `{"turns", "left", "attack", "health"}`), `shy` (gold it pays on leaving, 0 if not Shy), `eats_items`, `reward_pending` (a golden still owed its Triple Reward when played). `counters.hex` holds the Hedge Witch's total; a stat layer's `aura_attack` and `aura_health` show Rings and auras. A hand item view adds `gold_value`, `combines_into`, `keywords`, `keyword_text`.

`recruit_log` kinds added: `combine`, `spill`, `eat`, `burn`, `borrow`, `repaid`, `pass_queued`, `pass` (with `from`, `to`; `to` -1 if it fizzled), `timer`, `band`, `band_faded`, `tier_down`, and `trigger` with `mechanic: "shy"`.

**In a fight**

`Combat.side_rules` is `[{...}, {...}]`, one per side, with `larder` and `back_row_first`. Anything that runs its own fight must set it, using `RecruitRules.fight_rules(player)`, or Dame Hoolet's order and the Treasurer's ghost-free Larder won't apply. The defaults are harmless. `Combat.hexes` holds each side's hexed slots. New combat events: `slot_hex` (`side`, `slot`, `amount`, `total`, `source`) and `spill` (`side`, `source`).

Bots that reassign `player.board` directly should keep a unit in its slot: a unit that stands anywhere new starts its turn count over, at End of Turn, by `home_slot`.

## Adding a script

When data won't do (signature mechanics, things that change how a rule works):

1. Write `src/core/mechanics/<id>.gd`, extending `Mechanic`. Override the hooks you need: recruit hooks like `on_play(ctx)` take a `RecruitContext`, whose `buff`, `summon`, `gain_gold` and so on are what data effects use; combat hooks like `on_attack_declared(combat, unit, params, ...)` take the fight. A mechanic using `on_friendly_death` or `on_ally_summon` must also return true from `hears_allies(params)`.
2. Add it under `mechanics` in `content/schema/effects.json`, which is what makes it count as built, with its parameters as `number` (doubles on golden), `threshold`, `unit`, `tribe`, `bool` or `action`.
3. Add a GUT test with the rule number in its name. The soak's golden check reads the same schema.

## For screens and bots

`get_state()` gained `shop_spells`, `hand_items`, `pending_choice` (a hero or Discover, with options), `hero`, `armor`, `free_refreshes`, `gold_next_turn`, `gold_spent_turn`, `slot_effects`, `lobby_tribes`, `recruit_log` and `next_opponent_last_board` (the scouting rule: the next opponent's board as it fought last round, an array by slot of `null` or the same unit dict as `board`; `[]` before they have fought; a ghost shows the board it fought with). The port gained `buy_spell`, `play_item`, `use_power`, `choose` and `get_game_log`.

`get_game_log()` works at any time: `lobby_tribes`, `rounds`, `players` (placement, hero, gold spent, main tribe, and per round the tier, result, gold and board), and `tribes` (bought, unit-rounds, main players, average placement, wins). `LegalActions.of(state)` lists what the player may do.

Use `GameConfig.full_game()` to play with spells, heroes and lobby tribes; `defaults()` stays the bare rules. A lobby draws `tribes_per_lobby` tribes from those with at least `lobby_tribe_min_units` pool units. Sample cards have `"sample": true` and no set, so they stay out of it.

## Checks

- `scripts/check.sh`: the gate.
- `tools/checks/soak.sh [games] [first seed]`: seeds take turns. `seed % 3 == 1` plays the real game on the slice with half the table on `SoakBot` (random legal play) (one such game in three hands out extra Acorns, since a game rarely reaches a Stash on its own) and reports the slice's cards and keywords that never fired; `2` plays spells and heroes with one test unit per trigger and effect; `0` the bare rules. It fails only on rules breaches, including any action `LegalActions` listed that the rules refused. What a run didn't reach is reported, not failed.
- `tools/checks/soak_plant.sh`: plants one fault per check and wants each run red.
- `tools/checks/bench_fights.gd`: fight speed and an event hash that must not move unless fights change.
