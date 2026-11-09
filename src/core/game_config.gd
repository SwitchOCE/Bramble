class_name GameConfig
extends RefCounted
## Every tunable of docs/prototype/SPEC.md section 2, under the keys listed there, so the dev
## panel or a test can change one. Per-turn tables are arrays indexed by turn - 1; the last entry
## repeats for later turns.

const SLICE: String = "slice"
## Copies per tier in the slice's pool: 9/8/7/5/5/3 units a tier.
const SLICE_COPIES: Array = [15, 15, 13, 13, 11, 9]
## The odds a shop at each tier shows a card of each tier. Without them a tier 6 shop was mostly
## tier 1 and 2 cards, as the low tiers hold most of the copies.
const SLICE_SHOP_ODDS: Array = [
	[100],
	[50, 50],
	[20, 30, 50],
	[10, 15, 25, 50],
	[5, 10, 15, 25, 45],
	[5, 5, 10, 15, 25, 40],
]
## Tier 6 by round 11 won too often: the last climb costs 2 more than the rulebook.
const SLICE_UPGRADE_COSTS: Array = [5, 7, 8, 11, 13]
const SLICE_OPENING_SPELLS: Array = ["rainy_day", "a_leg_up"]
const SLICE_HEALTH: int = 40
## Default arm B: docs/ideation/evidence/damage-v05.md.
const V05_BASE_DAMAGE: Array = [0, 0, 0, 1, 1, 2, 2, 3, 4, 5, 7, 9, 11, 13]
## Retained for damage_mode="legacy", including its floor, divisor and toll below.
const SLICE_DAMAGE_CAPS: Array = [4, 4, 5, 6, 7, 8, 9, 10, 11, 12]

var _values: Dictionary = {}


static func defaults() -> GameConfig:
	var config := GameConfig.new()
	config._values = {
		"pass3_content": false,
		"pass3_preset": Pass3Rates.default_preset(),
		"pass3_loop_guards": true,
		"card_size_caps": true,
		"card_rate_limits": true,
		"scale_levers": [],
		"scale_engine_percent": 25,
		"scale_engine_flat": 0,
		"scale_engine_self": false,
		"scale_engine_tribe": "Hedgerow folk",
		"scale_answer_percent": 50,
		"scale_economy_cap": 10,
		"scale_hero_spell_stats": null,
		"scale_hero_spell_percent": null,
		"players": 8,
		"starting_health": 30,
		"damage_mode": "legacy",
		"base_damage_by_turn": [],
		"max_rounds": 50,
		"income_by_turn": [3, 4, 5, 6, 7, 8, 9, 10],
		"unit_cost": 3,
		"sell_bought": 1,
		"sell_created": 0,
		"refresh_base_cost": 1,
		"refresh_first_step_after": 15,
		"refresh_step_length": 5,
		"freeze_toggles_per_turn": 5,
		"upgrade_costs": [5, 7, 8, 11, 11],
		"upgrade_discount_per_turn": 1,
		"pool_copies_by_tier": [15, 15, 13, 11, 9, 7],
		"shop_units_by_tier": [3, 4, 4, 5, 5, 6],
		"hand_limit": 10,
		"damage_cap_by_turn": [5, 5, 5, 10, 10, 10, 10, 15],
		"damage_cap_off_at_alive": 4,
		"hero_damage_floor": 0,
		"round_toll": false,
		"early_spoils": false,
		"ask_for_kin": false,
		"last_blow": false,
		"last_stand": false,
		"survivor_damage_divisor": 1,
		"attack_limit": 200,
		"trigger_limit_combat": 10000,
		"trigger_limit_action": 1000,
		"pool_filter": "all",
		"bots": ["greedy", "greedy", "wide", "wide", "tribe", "tribe", "balanced"],
		"human_bot": "",
		"shop_tier_odds": [],
		"shop_spells_by_tier": [1, 1, 1, 1, 1, 1],
		"spell_copies_by_tier": [5, 7, 9, 11, 9, 7],
		"spells_in_shop": false,
		"hero_choice": false,
		"heroes_offered": 3,
		"discover_options": 3,
		"opening_spells": [],
		"opening_rounds": 2,
		"tribes_per_lobby": 0,
		"lobby_tribe_min_units": 4,
	}
	# Every authored rate is a legal bench override; null follows the selected preset.
	for key: String in Pass3Rates.defaults():
		if not config._values.has(key):
			config._values[key] = null
	return config


## The real game: the first slice's cards (docs/ideation/content/SLICE.md), Tavern spells in the
## shop, 3 heroes offered, tribes per lobby. defaults() stays the bare rules and the old library, so
## tests and older callers see what they always saw. Tools can select full_game("legacy").
static func full_game(damage_mode: String = "v05") -> GameConfig:
	var config := defaults()
	config.set_value("pass3_content", true)
	config.set_value("spells_in_shop", true)
	config.set_value("shop_units_by_tier", [4, 4, 4, 5, 5, 6])
	config.set_value("early_spoils", true)
	config.set_value("hero_choice", true)
	config.set_value("tribes_per_lobby", 5)
	config.set_value("pool_filter", SLICE)
	config.set_value("pool_copies_by_tier", SLICE_COPIES)
	config.set_value("shop_tier_odds", SLICE_SHOP_ODDS)
	config.set_value("starting_health", SLICE_HEALTH)
	config.set_value("damage_mode", damage_mode)
	config.set_value("base_damage_by_turn", V05_BASE_DAMAGE)
	config.set_value("opening_spells", SLICE_OPENING_SPELLS)
	config.set_value("upgrade_costs", SLICE_UPGRADE_COSTS)
	config.set_value("damage_cap_by_turn", SLICE_DAMAGE_CAPS)
	config.set_value("damage_cap_off_at_alive", 4)
	config.set_value("hero_damage_floor", 4)
	config.set_value("round_toll", damage_mode == "legacy")
	config.set_value("last_blow", true)
	config.set_value("last_stand", true)
	config.set_value("survivor_damage_divisor", 2)
	config.set_value("bots", BotLobby.seats(BotLevel.HARD))
	return config


## Which cards this game draws from: a card's "set" field; "" for the old library and test cards.
func card_set() -> String:
	return SLICE if get_string("pool_filter") == SLICE else ""


func get_value(key: String) -> Variant:
	return _values.get(key)


func set_value(key: String, value: Variant) -> void:
	_values[key] = value


## Persist effective rates and switches so captures survive future preset edits.
func resolved_values() -> Dictionary:
	var out: Dictionary = _values.duplicate(true)
	out.merge(Pass3Rates.resolved(self), true)
	out["scale_hero_spell_stats"] = get_bool("scale_hero_spell_stats")
	# Reader overrides compare against the source library's default-generated text.
	out["pass3_text_defaults"] = Pass3Rates.resolved(GameConfig.defaults())
	return out


## The value as an int (0 if missing); scaling uses its authored JSON rate.
func get_int(key: String) -> int:
	var value: Variant = (
		Pass3Rates.value(self, key) if key == "scale_hero_spell_percent" else _values.get(key, 0)
	)
	return CoreUtil.to_int(value)


## The value as a string ("" if missing).
func get_string(key: String) -> String:
	var value: Variant = _values.get(key, "")
	return str(value)


## Entry `index` of an array value, clamped to its last entry (per-turn tables).
func get_int_at(key: String, index: int) -> int:
	var values: Array = _values.get(key, [])
	if values.is_empty():
		return 0
	var value: Variant = values[clampi(index, 0, values.size() - 1)]
	return CoreUtil.to_int(value)


## A null scaling switch follows pass 3; explicit true/false remain comparison controls.
## Other booleans are false if missing.
func get_bool(key: String) -> bool:
	if key == "scale_hero_spell_stats" and _values.get(key) == null:
		return get_bool("pass3_content")
	return CoreUtil.to_bool(_values.get(key, false))


## An array value as strings.
func get_strings(key: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var values: Array = _values.get(key, [])
	for value: Variant in values:
		out.append(str(value))
	return out


## v0.5 replaces tier damage, caps and toll with round base plus own starting survivors.
func uses_v05_damage() -> bool:
	return get_string("damage_mode") == "v05"


## Synthetic units are opt-in individually; a mechanic may still be used by ordinary cards.
func lever_enabled(id: String) -> bool:
	return get_strings("scale_levers").has(id)
