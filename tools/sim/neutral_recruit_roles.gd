extends RefCounted
## Constructed native recruit actions. Every row includes the real recruit event log.


static func run(library: UnitLibrary, config: GameConfig) -> Array:
	var rows: Array = []
	for golden: bool in [false, true]:
		rows.append(_burner(library, config, golden))
		rows.append(_click(library, config, golden))
		for preset: String in ["B", "C"]:
			rows.append(_echo(library, config, golden, preset))
	return rows


static func _state(library: UnitLibrary, config: GameConfig) -> Dictionary:
	var rules: RecruitRules = RecruitRules.create(library, config, UnitPool.create(library, config))
	var player := PlayerState.new()
	player.shop_rng.seed = 11
	player.effect_rng.seed = 12
	player.discover_rng.seed = 13
	player.spell_rng.seed = 14
	rules.setup_player(player)
	player.round_number = 12
	player.tier = 4
	player.upgrade_cost = rules.base_upgrade_cost(4)
	player.gold = 30
	player.hand.clear()
	player.items.clear()
	player.shop.clear()
	player.shop_spells.clear()
	return {"rules": rules, "player": player}


static func _put(state: Dictionary, id: String, slot: int, golden: bool = false) -> RecruitUnit:
	var rules: RecruitRules = state["rules"]
	var player: PlayerState = state["player"]
	var unit: RecruitUnit = RecruitUnit.make(rules.library.get_unit(id), rules.new_iid(), golden)
	unit.origin = RecruitUnit.ORIGIN_CREATED
	if slot < 0:
		player.hand.append(unit)
	else:
		player.board[slot] = unit
	return unit


static func _body(unit: RecruitUnit, attack: int, health: int) -> void:
	unit.add_permanent(attack - unit.attack, health - unit.health)


static func _snapshot(state: Dictionary) -> Dictionary:
	var player: PlayerState = state["player"]
	return {
		"gold": player.gold,
		"shop_tier": player.tier,
		"larder": player.larder(),
		"board": player.combat_board(),
		"events": player.recruit_log.duplicate(true)
	}


static func _burner(library: UnitLibrary, config: GameConfig, golden: bool) -> Dictionary:
	var state: Dictionary = _state(library, config)
	var rules: RecruitRules = state["rules"]
	var player: PlayerState = state["player"]
	_put(state, "charcoal_burner", 1, golden)
	var first: RecruitUnit = _put(state, "old_isegrim", 4)
	var second: RecruitUnit = _put(state, "lantern_man", 5)
	_body(first, 100, 100)
	_body(second, 100, 100)
	rules.board_changed(player)
	player.gold = 17 if golden else 11
	var before: Dictionary = _snapshot(state)
	rules.events.fire(player, "end_of_turn")
	var after: Dictionary = _snapshot(state)
	var expected: int = 160 if golden else 130
	assert(first.attack == expected and first.health == expected)
	assert(second.attack == expected and second.health == expected)
	assert(player.gold == 5)
	player.round_number += 1
	player.gold = 17 if golden else 11
	rules.events.fire(player, "end_of_turn")
	var compounded: int = 256 if golden else 169
	assert(first.attack == compounded and second.attack == compounded)
	return {
		"role": "charcoal_fractional_growth",
		"golden": golden,
		"before": before,
		"after": after,
		"second_turn": _snapshot(state),
		"per_recipient_first_gain": expected - 100,
		"total_first_stat_gain": (expected - 100) * 4,
		"second_turn_body": compounded,
		"control": "Without the Burner mechanic: bodies stay 100/100 and no gold is burned."
	}


static func _click(library: UnitLibrary, config: GameConfig, golden: bool) -> Dictionary:
	var state: Dictionary = _state(library, config)
	var rules: RecruitRules = state["rules"]
	var player: PlayerState = state["player"]
	_put(state, "click_beetle", 0, golden)
	var carry: RecruitUnit = _put(state, "field_vole", 3)
	_body(carry, 10, 10)
	var before: Dictionary = _snapshot(state)
	var crumb: RecruitUnit = _put(state, "mr_crumb", -1)
	assert(rules.play(player, player.hand.find(crumb), 4) == "")
	var moth: RecruitUnit = _put(state, "lamp_moth", -1)
	var previous_discount: int = player.upgrade_cost
	assert(rules.play(player, player.hand.find(moth), 1) == "")
	var repeats: int = 3 if golden else 2
	BoardUpkeep.resolve_passes(rules, player)
	assert(carry.attack == 10 + repeats and carry.health == 10 + repeats)
	assert(previous_discount - player.upgrade_cost == repeats)
	return {
		"role": "click_two_when_played_units",
		"golden": golden,
		"before": before,
		"after": _snapshot(state),
		"carry_gain": repeats,
		"tier_discount_gain": repeats,
		"without_click_each_gain": 1,
		"homecoming": _homecoming(library, config, golden)
	}


static func _homecoming(library: UnitLibrary, config: GameConfig, golden: bool) -> Array:
	var rows: Array = []
	for id: String in ["chiffchaff", "one_swallow", "mother_goose"]:
		var cfg := GameConfig.new()
		cfg._values = config._values.duplicate(true)
		cfg.set_value("birds_homecoming_multiplier", 2.0)
		var state: Dictionary = _state(library, cfg)
		var player: PlayerState = state["player"]
		var rules: RecruitRules = state["rules"]
		_put(state, "click_beetle", 6, golden)
		var bird: RecruitUnit = _put(state, id, -1)
		player.hand.erase(bird)
		player.gold = 0
		player.away.append({"unit": bird, "left": 8, "due": 12, "nest": 0, "missed_fight": true})
		HeldUnits.land_due(rules, player)
		var repeats: int = 3 if golden else 2
		if id == "chiffchaff":
			assert(bird.attack == (8 if golden else 6))
			assert(bird.health == (10 if golden else 8))
		elif id == "one_swallow":
			assert(player.gold == repeats)
		else:
			assert(player.items.size() == repeats)
		rows.append(
			{
				"bird": id,
				"attack": bird.attack,
				"health": bird.health,
				"gold": player.gold,
				"items": player.items.size(),
				"log": player.recruit_log
			}
		)
	return rows


static func _echo(
	library: UnitLibrary, config: GameConfig, golden: bool, preset: String
) -> Dictionary:
	var cfg := GameConfig.new()
	cfg._values = config._values.duplicate(true)
	cfg.set_value("pass3_preset", preset)
	var state: Dictionary = _state(library, cfg)
	var rules: RecruitRules = state["rules"]
	var player: PlayerState = state["player"]
	var left: RecruitUnit = _put(state, "field_vole", 0)
	var echo: RecruitUnit = _put(state, "pipistrelle_echo", 1, golden)
	var right: RecruitUnit = _put(state, "lamp_moth", 2)
	for unit: RecruitUnit in [left, echo, right]:
		_body(unit, 100, 100)
	rules.board_changed(player)
	var before: Dictionary = _snapshot(state)
	rules.give_card(player, "pinch_of_dust")
	assert(rules.play_item(player, player.items.size() - 1, 1) == "")
	var gain: int = 20 if preset == "C" else 10
	for unit: RecruitUnit in [left, echo, right]:
		assert(unit.attack == 100 + gain and unit.health == 100 + gain)
	return {
		"role": "echo_scaled_spell",
		"golden": golden,
		"preset": preset,
		"before": before,
		"after": _snapshot(state),
		"recipient_gain": gain,
		"total_stat_gain": gain * 6,
		"without_echo_total_stat_gain": gain * 2
	}
