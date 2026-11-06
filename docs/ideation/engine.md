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
- `aim`: `none`, `unit`, `empty_slot` or `any_slot`.
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

Rule queries, in the order added: `refresh_cost`, `tier_up_cost`, `income`, `shop_size`, `sell_value`. `op`: `add`, `set`, `min`, `max`.

## Adding a script

When data won't do (signature mechanics, things that change how a rule works):

1. Write `src/core/mechanics/<id>.gd`, extending `Mechanic`. Override the hooks you need: recruit hooks like `on_play(ctx)` take a `RecruitContext`, whose `buff`, `summon`, `gain_gold` and so on are what data effects use; combat hooks like `on_attack_declared(combat, unit, params, ...)` take the fight. A mechanic using `on_friendly_death` or `on_ally_summon` must also return true from `hears_allies(params)`.
2. Add it under `mechanics` in `content/schema/effects.json`, which is what makes it count as built, with its parameters as `number` (doubles on golden), `threshold`, `unit`, `tribe`, `bool` or `action`.
3. Add a GUT test with the rule number in its name. The soak's golden check reads the same schema.

## For screens and bots

`get_state()` gained `shop_spells`, `hand_items`, `pending_choice` (a hero or Discover, with options), `hero`, `armor`, `free_refreshes`, `gold_next_turn`, `gold_spent_turn`, `slot_effects`, `lobby_tribes`, `recruit_log` and `next_opponent_last_board` (the scouting rule: the next opponent's board as it fought last round, an array by slot of `null` or the same unit dict as `board`; `[]` before they have fought; a ghost shows the board it fought with). The port gained `buy_spell`, `play_item`, `use_power`, `choose` and `get_game_log`.

`get_game_log()` works at any time: `lobby_tribes`, `rounds`, `players` (placement, hero, gold spent, main tribe, and per round the tier, result, gold and board), and `tribes` (bought, unit-rounds, main players, average placement, wins). `LegalActions.of(state)` lists what the player may do.

Use `GameConfig.full_game()` to play with spells, heroes and lobby tribes; `defaults()` stays the bare rules. A lobby draws `tribes_per_lobby` tribes from those with at least `lobby_tribe_min_units` pool units. Sample cards have `"sample": true`.

## Checks

- `scripts/check.sh`: the gate.
- `tools/checks/soak.sh [games] [first seed]`: odd seeds play `full_game()` with one test unit per trigger and effect, even seeds the bare rules. It fails only on rules breaches; what a run didn't reach is reported, not failed.
- `tools/checks/soak_plant.sh`: plants one fault per check and wants each run red.
- `tools/checks/bench_fights.gd`: fight speed and an event hash that must not move unless fights change.
