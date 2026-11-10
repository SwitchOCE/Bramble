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
| `on_home` | A bird lands back in hand after Fly South | it, `self` |
| `on_swallow` | A unit goes into a Belly | the Ooze, `other` is the unit |
| `on_eat` | An Ooze eats a meal through the shared meal pipeline | `subject` is the eater; `meal` contains the consumed unit and its stats |
| `on_refresh` | The shop refreshes | `paid` tells if it cost gold |
| `on_spell_cast` | A spell is cast (items don't count) | `card_def` for scripts |
| `on_tier_up` | Tavern tier goes up | |
| `on_triple` | Three copies combine | the golden, `any` |
| `on_gold_spent` | Gold is spent | `amount` is how much |
| `on_item_gained` | An item reaches your hand, including a combined Stash | `card_def` is the actual item gained |
| `on_item_played` | An item is cashed or fed to a unit | `card_def` is the item played |
| `on_shy_left` | An aimed spell thanks a Shy unit | `subject` is the departed unit; `amount` is its vacated slot |
| `on_unit_bought` | You buy any unit | `subject` is the unit |
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
- `pick`: `first`, `random`, `biggest`, `highest_attack`, `lowest_attack`, `highest_health`, `lowest_health`. `count`: how many. Ties keep the existing random-key ordering and effect RNG (rulebook 1.2.2).

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
| `bring_home` | `count`: birds away land next turn, longest away first; never the same turn | recruit |

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
| `debt` | int | Total gold Hob Mumblecrust still owes. |
| `debt_payment` | int | Gold repaid each turn until the debt is cleared. |
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

## The balance step: what it added

- **Shop odds.** `shop_tier_odds` in `GameConfig`: per shop tier, the weight of each card tier. A draw picks a tier by those weights, then a copy within it (`UnitPool.draw_by_odds`). Tiers with nothing left drop out. Empty means the old rule, every copy equal. Spells use the same table.
- **Discover** tops up from the tiers below when a one-tier Discover can't show its count.
- New effects and params: `upgrade_discount` `amount` (off the next upgrade), `turns_in_slot` `every`, an effect's `lifetime` (payments in the unit's life, kept through a move), `rainbow` `finish` (gold on top for all seven).
- Effect params: `multiply` `most` (ceiling on the gain, doubles on golden), `tier_down` `climb_back`, `borrow` `health`. New effect `rainy_day` (`win`, `lose`). Query `unit_cost`. Selector `smaller_row`. Condition `turns_in_slot` takes `every`; a card field `turns_repeat` says it keeps counting.
- Mechanic scripts: `band_attack`, `rainbow_paint`, `savings`, `beadle`, `echo`, `cradle_fetch`, `changeling`, `reel_mistress`, `parasite`, `row_swap`, `sergeant`, `urchin`. `hex` gained `most`; `rainbow` is now `gold` and `stats` per band.
- `fight_rules` gained `bands` and `ammo`. Combat events added: `relocate` (`uid`, `side`, `slot`: a unit changed slot or side) and `ring_dance`. `carry` op `spend_item` (`gold`).
- A triple keeps the copies' waiting Cold Frames.

## Oozes and Birds: what they added

- **Held units.** `HeldUnits` (recruit) and `CombatHeld` (fight) own the shared zone. `RecruitUnit.held` lists what an Ooze holds; `PlayerState.away` lists birds on their way home, each with its landing round and Nest slot; `PlayerState.doorstep` lists birds with no hand space. `owned_units()` counts held units for triples, not away ones.
- **Belly.** `RecruitRules.swallow(player, source, index, into_slot)` with `HeldUnits.SHOP`, `HAND` or `BOARD`. Paying from the shop fires `on_buy` and `on_unit_bought`; nothing fires `on_play`. A unit holding others can't be swallowed. In a fight, `CombatHeld.open_bellies` lets them out last in first when the Ooze dies.
- **Mid-fight entry.** `Combat.enter_from_spec(spec, side, slot, source, fields)` and `enter_board(unit, source, fields)`. Summon events carry `came_out`, `landed` or `split`.
- **Fly South.** The sell intercept in `RecruitRules.sell` keeps the unit and leaves a Nest, paying no sale gold. Birds cannot fly on the turn they land. `HeldUnits.land_due` runs at turn start and then checks triples, so a landing can complete one over the hand limit.
- **Nest.** A marker on the slot (`PlayerState.nest_at`). `PlayerState.combat_board()` adds a textless `nest_egg` with half the away Bird's current stats, each rounded up, on an empty Nest (including Mother Goose's own Egg); `board_specs()` is the board without Eggs, which bots and placement read. A starting Egg that survives adds 1 hero damage under v0.5 (none under legacy). The scout shows `nests`; it doesn't show who is away.
- **Text transfer.** `borrows_text` on Frumenty; `RecruitUnit.borrowed_text()` lends a held unit's text for the turn, except Belly, Fly South, Shy, `on_play`, `on_sell` and `on_home`. Mag Pye's fight version: `CombatHeld.steal_text`, event `text_taken`, in a `first_of_all` phase before Start of Combat.
- `fight_rules` gained `nests`, `goose` and `away_birds`. Combat events added: `swallowed`, `no_room`, `goose_strike`, `text_taken`. A combat unit's view has `held` when it holds anything.
- `get_state()` gained `away`, `doorstep` and `next_opponent_last_nests`. A recruit unit's view gained `belly`, `belly_discount`, `held`, `fly_south`, `played_round` and `plain_copy`. The port gained `swallow`. `LegalActions` lists `swallow_shop`, `swallow_hand` and `swallow_board`.
- Mechanic scripts: `belly`, `belly_discount`, `borrows_text`, `figgy_duff`, `syllabub`, `fly_south`, `hit_reactor`, `wobbly`, `bubble`, `pie`, `hasty`, `granny`, `nell`, `stone_soup`, `aspic`, `cut_and_come`, `dunnock`, `swoop`, `tom_tit`, `lump`, `redbreast`, `jack_daw`, `mag_pye`, `mother_goose`, `gabble_ratchet`, `whistlers`.

## Checks

- `scripts/check.sh`: the gate.
- `tools/checks/soak.sh [games] [first seed]`: seeds take turns. `seed % 3 == 1` plays the real game on the slice with half the table on `SoakBot` (random legal play) (one such game in three hands out extra Acorns, since a game rarely reaches a Stash on its own) and reports the slice's cards and keywords that never fired; `2` plays spells and heroes with one test unit per trigger and effect; `0` the bare rules. It fails only on rules breaches, including any action `LegalActions` listed that the rules refused. What a run didn't reach is reported, not failed.
- `tools/checks/soak_plant.sh`: plants one fault per check and wants each run red.
- `tools/checks/bench_fights.gd`: fight speed and an event hash that must not move unless fights change.


## Bog folk and Hunters: shared foundation

The bell runs after Mag Pye's `first_of_all`, before Goose, heroes and ordinary Start of Combat.
`CombatLanes.bell` takes one snapshot of both boards. It fixes all own Quarry marks and Mire
patches first, then lenders in reading order, then applies bell buffs. Ordinary Start of Combat
text cannot change who was marked. The bell phase is logged when there are lane bindings.

- `mire` (`spread`: bool) lays a patch, including on an empty slot. `bog_aura` (`mire`, `bitter`)
  lends Mire at the bell and Bitter during the fight to adjacent units. The first maker in reading
  order owns an overlapping patch. `Combat.bog_patches[side][slot]` retains its maker after death.
- `quarry` (`reach`: bool) fixes an enemy uid; Eggs and empty slots cannot be quarry.
  `lend_quarry` (`select`, `reach`, `attack`, `own_across`) fills only missing marks.
- Every attack uses the same precedence: Mire lock, legal quarry, other own targeting text,
  Taunt when built, then protected-row random. `CombatLanes.lock_target` also restricts joiners
  and immediate attacks. Moving off a patch frees the unit; ordinary moves preserve quarry.
  Swallowing or changing side clears marks without a Take, permanently for this fight.
- `on_enemy_death` has the dead enemy as subject; `subject_mired` tests its last-known mud.
  `on_take` has the credited Hunter as subject and the fallen quarry as `other`.
  Selectors added: `mired` (enemies in mud), `quarry`, `other`.
  Death witnesses are captured before the whole simultaneous batch leaves. One Hunter, first
  in reading order, makes each Take. A Hunter already gone from an earlier batch makes none.
  The result includes `takes`, a count per side.
- `bitter` (`n`, `once_per_enemy`) applies at attack declaration before damage and thorns, after queued attack bonuses. It stacks with neighbouring Bitter, affects only the leading attacker (not Pack joiners), and floors at 1. Once-per-enemy is spent on declaration even if the attack whiffs; counters and pounces count, Peck strikes do not spend it again.
  `snap` chooses the highest-Attack Mired enemy, ignoring rows, with random ties.
- `Combat.queue_attack(attacker, defender, kind)` queues a named-target attack after the current
  attack and its deaths. It doesn't move the pointer or flag the attacker. `counter` cannot
  trigger another counter; `pounce` chains require a per-cycle limit. All consume the attack cap.
  `on_attacked_complete` lets scripts react after attack damage, before deaths, even when dying.
- The old prototype damage-and-skip Mire is now `pin` / Pin. Its skip status, and Scarecrow's,
  is `stalled` / Stalled. The prototype scenario keeps its existing id for saved links.

New combat events: `bog_patch` (`side`, `slot`, `maker`), `quarry_marked` (`hunter`, `quarry`,
`source`), `quarry_lost` (`hunter`, `quarry`), `take` (`hunter`, `quarry`, `side`),
`immediate_attack` (`attacker`, `defender`, `kind`). Combat unit views include `quarry` and
`quarry_reach`. Mire uses the `mired` status with its maker uid, never the skip status.


### Bog folk roster

All 14 shop cards and the two created cards are in `content/units`. `vault` promotes a back-row
unit to the start of each cycle and supplies a row-dependent Attack aura. Counterattacks use
`queue_attack`'s optional `attack_bonus`, removed after the reply. They never cause another counter.
A hit records the identity of its killing source, so Pretender and Bufo also work in trades and
when Bufo dies to counter-damage.

`kiss` persists `kisses` through combat specs and carryback. The third kiss transforms the same
fighter immediately; it keeps damage and buffs, and its new Mire has missed the bell. Recruit
carry transforms the same owned unit. `pool_origin` preserves the original pool identity through
transforms, sales, triples and elimination. After all carry is applied, `after_fights` checks for
new Prince triples. A Highness and a Prince are different cards.

`spell_cost(player, item)` prices a purchase. The first spell **bought** in a turn consumes the
Prince's discount, even if free; free cards or casting from hand do not. Multiple Princes add
their discounts, then floor the cost at zero. A player-wide counter prevents selling/replaying
from refreshing it. `GameSession` exposes the same price that the rules and bots use.

Combat events added: `kiss` (`target`, `count`) and `transform` (`target`, `unit` view). Recruit
log events of those names carry `iid` and `count` or `name`. `SoakBogCheck` runs 24 directed normal
and golden bog mirrors, including Belly refills and a frog on its third kiss, before soak games.


A counter's temporary bonus can restore Attack lost to Hex; admission must not reject the reply
just because the pre-bonus displayed Attack is zero. Pounce still requires positive Attack.
Readable combat/CLI lines, replay state and board overlays cover the new events.


### Hunters, recruit rewards and lane views

`CombatHunt` resolves Pack before the leader hits, spends normal joiners' cycle flags and directs
counter-damage/Bristle to the leader. Brother Wolf tracks each neighbour separately per own
cycle. Immediate attacks do not recruit a Pack. `Combat.cycles` advances when that side resets
its attack flags. Pounce spends at most one successful attack per own cycle, validates its mark
and Mire lock when dequeued, and may chain into another eligible Pounce. Friendly effect hits
carry `Hit.owner_side`, including Nest and hero hits without a source unit.

Young Brock's `lend_quarry.bell_buff` distinguishes lasting bell Attack from Old Brock's live
`brock_aura`. The Laird marks only our side; each Take then buffs our Hunters for that combat. Pack, Pounce, Takes,
Poach, gold rewards and transforms have separate replay/log feedback. `LaneProjection` shares
scout forecasting and replay bindings; patches remain on slots, quarry follows the marked uid,
and a reed line disappears when its maker dies or changes side. `LaneOverlay` draws the same
labels and links on phone and desktop.

`HunterRecruit` reserves real pool copies after a Poach, keeping them in `PlayerState.all_units`
while pending. They become extra offers next turn, survive refreshes, and expire at End of Turn
even when frozen. `RecruitRules.unit_cost(player, unit)` includes their discount; buying or
swallowing clears the discount. Ermeline's upgrade discount stacks after other price modifiers,
is consumed by the next successful upgrade, and otherwise expires at End of Turn.

`get_state()` adds `poached` (shop indices) and `takes_last_fight`; unit views add `poached`.
`BotLanes` matches public scout lanes, honours loan/patch precedence and supports Packs. The best bot
uses this placement pass and can additionally search fights with stable carry slots.
The optional `RecruitRules.shop_observer` callback measures visible shop offers in experiments;
it is unset in ordinary play. `tools/sim/tribes56_probe.gd` records focus placement, final tribe
share and visible on-tribe shop share for all six tribes.


## Tribe commitment

- **Tribe bonus:** new effects `tribe_bonus` and `kin_buff` use the rules above. `PlayerState.tribe_bonuses` stores a symmetric 0–3 bonus per tribe. It follows owned units across board, hand, Bellies and away zones, and new acquisitions. Units with two tribes receive both; combat summons do not receive it. The unit view exposes `tribe_bonuses`; the session view exposes the player's whole map. Tribe portrait icons show each bonus, while Harvest Supper explains its grant.
- **Kin spells:** Stand Behind Me and Bread from the Back keep their front/back targeting and pay +2/+2 to recipients sharing a tribe with the target, +1/+1 otherwise. `tribe_unit` targeting requires a board unit with at least one tribe.
- **Hiring Fair:** when five board units share a tribe, one eligible Discover option matches that tribe. The normal shared-pool availability still applies.
- **Payoffs:** mechanics `fairy_monarch` (`stats`), `elder_ooze` (`stats`), `moss_ooze` (`factor`) and `laird` support the new cards. Fairy Monarch adds a flat +1/+1 per Ring under a Fairy (+2/+2 golden); Elder Ooze gives each of your units released from a Belly +1/+1 (+2/+2 golden), this combat; its own death releases also receive its bonus. Moss Ooze echoes spell stat gains into the affected Ooze's contents; the standing tribe bonus is excluded. The Laird grants quarry at the bell, then buffs your Hunters after every Take this combat.


### Engines rules after review

`GameConfig.defaults()` is the Battlegrounds baseline: `last_blow=false`, `last_stand=false`. The playable `full_game()` enables both; Last Stand additionally requires four or fewer living heroes. Session state and each standing expose `last_stand_enabled`, `last_stand_active` and `last_stand_used`; the hero card explains the last-four condition. `combat_end.last_stand_sides` identifies saved sides for the result and combat log. Lethal Health loss (including Wasp parasite) shares Last Blow attribution with ordinary damage, and emits `health_loss` with its `cause`, `source` and `owner_side`.

## Round 5 content

- Effect `market_stall` (recruit, no parameters) adds one permanent shop upgrade, capped at two. `PlayerState.market_stalls` counts cast upgrades; held Stalls also count when filtering future offers. Bonus unit draws use the player's exact current tier. The seven-unit ceiling limits only Stall additions; existing hero shop sizes and Poach offers are preserved (tier-6 Pipkin without Stalls shows eight units). Pipkin converts blocked Stall additions to spell slots; Hungry Gap retains its existing behavior. Refills and Poach keep their pre-Stall freeze, admission and expiry rules.
- Horseshoe uses `slot_effect`, named `Horseshoe`, at `chosen`, with no stat bonus or mechanic grant. Before combat setup, `CombatRings.prepare` marks the opposing Ring for half strength. `CombatRings.bonus` includes Monarch before rounding down and keeps Hex separate. The marker expires in `after_fights` and is stripped from eliminated-player ghost snapshots; the combat-only Ring mark travels with Reel-Mistress's dance. Repeated Horseshoes do not stack.
- Barn Owl combines `swoop`, `no_quarry` and `back_row_immunity` (all parameterless). Quarry marking refuses the latter unit's own and lent marks. Its attack declaration brackets the damage immunity; hits prevented completely never consume Shell or fire damage hooks. Bitter remains a non-damage effect.
- Mechanic `redwing` takes numeric `factor: 1`, doubled on golden. An adjacent Egg receives its Bird's full body once, with `(factor - 1) * 2` extra Attack and Health. Copies use the strongest factor, including granted and borrowed text. This is a combat aura, removed when the supporting text leaves. `HeldUnits.egg_forecast` drives own previews and bots; public scout/ghost snapshots use plain Egg specs with two revealed full-body numbers (`egg_full_attack`, `egg_full_health`), never the Bird's identity, text or return countdown. These numbers preserve dynamic aura loss and the normal Egg baseline without a separate side-rule dictionary.

Exact revised texts and interaction readings: [round 5 cards](content/content5.md).


### Pass 1 fixes

- Recruit Rings cap each stat at 4 in `BoardUpkeep.add_ring`; `ring_room` supplies capacity, while `ring_stats` reads combat totals without clamping Reel-Mistress. `HandItem.view.ring_add` carries aimed Ring additions to the preview and legal-action list. Full Rings reject Ring spells without spending them. Sally’s nearest-empty search skips full Rings.
- Rainbow’s `stats_every` and `gold_every` count painted-slot groups, rounded down; both thresholds stay unchanged on golden. Hex `most: "tier_plus_2"` reads the current owner’s tier in both phases. Unit views expose capped `hex_amount` and total `hex_stored` (printed base plus spell growth).
- Toll-Bard has separate `attack_limit` and `gold_limit`; `take_gold.back_only` reads the hunter’s row. Self-targeted Take growth carries permanent rewards through a simultaneous trade. Savings adds its `health` only on the first three counted turns.
- Hob’s `repay_turns` schedules `repay` gold each turn; `debt` stores total remaining and `debt_payment` the instalment. The `debt` condition blocks new loans while repaying. Mousewife uses persistent per-side hero limits, the `subject_card` exclusion and exact `subject_slot` placement.


### Pass 2 follow-up persistence

RecruitUnit combat snapshots carry `lifetime_payments` for named `paid_` counters and `mrs_clover_used` for the shared Recruit/combat limit. Data effects spend their lifetime payment only after the per-turn/fight limit permits a firing; CombatWorld persists it with a `counter` carry. Peat Cutter therefore pays once a fight, only three times in its life, even across reconstructed fights. Wobbly-created Drips carry an explicit emergence marker for Elder; they do not gain Syllabub’s Belly replay semantics.

### Scale mechanisms — BRAMBLE ideation

Use `{"select":"enemies","pick":"biggest"}` to select the living enemy with
highest current Attack + Health, in any row, bypassing row protection. Most Attack
and most Health use the existing `highest_attack` and `highest_health` picks on
`enemies`. Filters run before ranking. Ties keep the existing random-key ordering
and effect RNG (rulebook 1.2.2). The three custom enemy selectors have been removed.

`stat_fraction` takes `stat` (`attack`, `health`, `both`), `operation` (`set`, `reduce`,
`gain`), integer `numerator` and positive `denominator`, plus optional `duration`.
For example `{ "effect": "stat_fraction", "operation": "reduce", "stat": "attack",
"numerator": 25, "denominator": 100, "target": {"select": "enemies", "pick": "biggest"} }`.
Ratios keep their value on golden. Positive fractions round down; shrinking leaves
at least 0 Attack / 1 Health. Negative growth isn't damage and bypasses Shield.

`bitter`, `hex`, `jenny`, `jack_daw` accept optional `percent` instead of their flat
stat-loss parameter. Percentages stay the same on golden. Existing cards keep their
flat values. Hex grows its percentage by that amount per spell; the total is clamped
to 100% for application. Live Hex and Jenny use Attack before auras, avoiding
self-compounding on aura recalculation. Hex remains on its slot after its source dies.

`damage_reduction` takes flat `n` or optional `percent`; `shield` and `cleave` have no
parameters. See the rulebook's scale mechanisms for hit ordering and collateral rules.
`optional_mechanic_params` in the schema marks parameters the content checker allows
but does not require. It leaves required parameters on today's cards unchanged.

Experiment configuration, overlay coverage and synthetic lever IDs are in
[evidence/mechanics-build.md](evidence/mechanics-build.md). Treat config as immutable
input for a game: set dials and switches before `GameSession.create`; create a new
game to change them. `GameSession.create` builds the private overlay library once,
before constructing units, heroes and pools. `Combat.create` uses its supplied
library without rebuilding the overlay. Standalone tools should configure their
library once with `ScaleOverlay.library_for` before their combat loop; direct
recruit fixtures should also build units from that configured library.

Two independent switches default to true:

- `card_size_caps` controls `permanent_buff_cap`, `most`, `golden_most`, `per_max`,
  `max_steps`, `takes_max`, `gold_max`, Whistlers' homecoming ceiling, and Ring,
  tribe-bonus and shop-size ceilings.
- `card_rate_limits` controls `once`, `once_per_enemy`, `limit`, `lifetime`,
  `attack_limit`, `gold_limit`, `uses_per_turn`, Savings' maximum counted turns,
  Stone Soup/Nell/Kiss/Bubble/Reel-Mistress per-turn or per-fight limits, Figgy's
  cooldown, first-spell discounts, first-free-refresh limits, Harvest's once-per-turn
  limit, Market Stall's lifetime two-upgrade limit, and hero use and buy rates.

**Designer warning:** overlay classification follows the **key name** declared in
`size_cap_overlay` or `rate_limit_overlay` in the schema, not a clause's prose.
`most` is SIZE; `limit`, `lifetime` and `once` are RATE. A card may contain both.
Displayed overlay text strips only the disabled size/rate clauses, retaining active
limits, multipliers and loop guards. Both switches preserve attack/trigger safety
guards, keyword charges, cycle and Nest recursion guards, resource availability,
board/hand capacity, and timing/target conditions. The economy lever's explicit
config cap remains its own dial.

When disabling a limit changes a sentence's meaning, author `overlay_text` on the
card instead of depending on clause removal. Optional `size`, `rate`, and `both`
branches replace only `text`, `golden_text`, `details`, or `golden_details`. Generic
removals run first, then authored size, rate, and both branches in that order.
Defaults apply none of these branches. An authored combined branch must preserve
all still-active rules. Dozey's recurring doubling, Pipkin's unrestricted buys and
golden Money Spider's uncapped income use these data overrides. The catalogue
audit checks all four switch combinations against effective numeric parameters;
new changed printed parameters require a matching text contract.


`scale_levers` is a list of selected IDs, default `[]`, never a boolean. Available
IDs are `scale_engine`, `scale_answer`, `scale_doubler`, `scale_economy`,
`scale_biggest_answer`, `scale_defender` and `scale_cleaver`. Lever text is generated
from numeric config. `scale_answer` remains the adjustable reduction (default 50%);
`scale_biggest_answer` is a fixed Start of Combat 50% reduction of the biggest enemy's
stats. `scale_defender` has Shield and Damage Reduction 2 (4 golden), while
`scale_cleaver` is an 8/8 with Cleave. Second Helping's plain text is “Your End of
Turn effects trigger an extra time.” Golden adds two extra firings; multiple copies
add rather than multiply or recurse.

Percent Hex views carry `hex_percent_amount` (effective, capped at 100) and
`hex_percent_stored` (raw base plus growth); `hex_amount`/`hex_stored` remain flat.
Combat `slot_hex` events retain flat `amount`/`total`, add `percent_amount` for a
percentage application, and carry total active `percent` even on a flat application.
The combat model, log, slot badges and recruit slips preserve the distinction and
show both components for mixed Hex. Shield has an explicit status tag and linked
reminder; playback removes the tag when the status is spent.

### Test-only Quilboar reference

Behind the default-off `reference_quilboar` flag, `gem` plays counted Gems without
casting a spell, `gem_size_add` changes future Gem size in integer half-stat units,
and `steal_gems` transfers only adjacent units' Gem-ledger stats. A real Choose One
play queues modes independently of When played; `on_choose_one_played` fires after
mode resolution. Trailblazer uses its own `both_per_turn` dial. The reference resources are excluded from player exports.
