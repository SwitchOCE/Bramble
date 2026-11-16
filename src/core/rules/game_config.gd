class_name GameConfig
extends RefCounted
## Every tunable number of rulebook Appendix A, with its rule. The base answer of each rule
## query (Rules) reads these; modifiers never edit them at run time (prototype lesson 1).

## 2.1.1
var players: int = 8
## 2.2.5 (no heroes on this track: everyone starts at the default)
var starting_health: int = 40
var starting_armor: int = 0
## 4.1.1: 5 on turn 1, +2 a turn until 15, then +1 a turn, no ceiling.
var income_first: int = 5
var income_fast_step: int = 2
var income_fast_until: int = 15
var income_slow_step: int = 1
## 4.4.2-4.4.3: 1 gold for the first 10 paid refreshes, then +1 every 5.
var refresh_base_cost: int = 1
var refresh_first_step_after: int = 10
var refresh_step_length: int = 5
## 4.5.1
var freeze_toggles_per_turn: int = 5
## 4.6.1-4.6.2: base cost to upgrade to tiers 2..6.
var max_tier: int = 6
var upgrade_costs: Array[int] = [8, 12, 16, 19, 26]
## 4.6.3, 4.6.6: the per-turn drop grows by 1 a turn up to this.
var discount_step_cap: int = 5
## 5.1.2: copies per unit and per Tavern spell, by tier 1..7 (spells 1..6).
var unit_copies_by_tier: Array[int] = [15, 15, 13, 11, 9, 7, 5]
var spell_copies_by_tier: Array[int] = [5, 7, 9, 11, 9, 7]
## 6.1.1
var shop_units: int = 5
var shop_spells: int = 2
## 6.2.1
var discover_options: int = 3
## 7.1.1
var hand_limit: int = 7
## 8.1.2
var front_slots: int = 4
var back_slots: int = 3
## 10.1.1, 10.1.3: small loss = round + 1 up to 10; a big loss deals 3 more.
var loss_round_offset: int = 1
var loss_cap: int = 10
var big_loss_extra: int = 3
## 9.10.1-9.10.3
var attack_limit: int = 200
var combat_trigger_limit: int = 10000
var action_trigger_limit: int = 1000
var return_limit: int = 5
## 1.2.4
var stat_max: int = 1000000000
## 2.1.3
var round_limit: int = 50


func copies_for(tier: int, spell: bool) -> int:
	var table: Array[int] = spell_copies_by_tier if spell else unit_copies_by_tier
	if tier < 1 or tier > table.size():
		return 0
	return table[tier - 1]
