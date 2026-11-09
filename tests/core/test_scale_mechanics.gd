extends GutTest
## BRAMBLE ideation: shared mechanisms, including large-number breakpoints.
@warning_ignore_start("unsafe_call_argument")

const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup()


func _enable_levers() -> void:
	kit.config.set_value("scale_levers", EffectSchema.data()["lever_cards"])
	kit.library = ScaleOverlay.library_for(kit.library, kit.config)
	kit.rules.library = kit.library


func _fight(mine: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	return combat


func test_biggest_and_most_stat_picks_ignore_rows_and_use_effect_rng_ties() -> void:
	var combat: Combat = _fight(
		{0: "field_vole"},
		{
			0: {"def_id": "field_vole", "attack": 100, "health": 20},
			4: {"def_id": "field_vole", "attack": 70, "health": 100},
			5: {"def_id": "field_vole", "attack": 100, "health": 70}
		}
	)
	var world := CombatWorld.make(combat, combat.unit_at(0, 0), 0, {}, "start_of_combat")
	var rng_before: int = combat.rng.state
	var effect_before: int = combat.effect_rng.state
	var biggest: BoardUnit = TargetSelect.pick({"select": "enemies", "pick": "biggest"}, world)[0]
	assert_true([combat.unit_at(1, 4), combat.unit_at(1, 5)].has(biggest))
	assert_eq(combat.rng.state, rng_before)
	assert_ne(combat.effect_rng.state, effect_before)
	assert_true(
		[combat.unit_at(1, 0), combat.unit_at(1, 5)].has(
			TargetSelect.pick({"select": "enemies", "pick": "highest_attack"}, world)[0]
		)
	)
	assert_eq(
		TargetSelect.pick({"select": "enemies", "pick": "highest_health"}, world)[0],
		combat.unit_at(1, 4)
	)
	combat.unit_at(1, 4).take_damage(100)
	assert_eq(
		TargetSelect.pick({"select": "enemies", "pick": "biggest"}, world)[0], combat.unit_at(1, 5)
	)
	world.enemy = []
	assert_eq(TargetSelect.pick({"select": "enemies", "pick": "biggest"}, world).size(), 0)


func test_target_picks_preserve_original_random_keys_and_rng_consumption() -> void:
	var combat: Combat = _fight(
		{0: "field_vole"}, {0: "field_vole", 4: "field_vole", 5: "field_vole"}
	)
	var world := CombatWorld.make(combat, combat.unit_at(0, 0), 0, {}, "start_of_combat")
	var reference := RandomNumberGenerator.new()
	reference.state = combat.effect_rng.state
	var expected_slot: int = -1
	var minimum_key: int = 0x100000000
	for slot: int in [0, 4, 5]:
		var key: int = reference.randi()
		if key < minimum_key:
			minimum_key = key
			expected_slot = slot
	var initial: int = combat.effect_rng.state
	for how: String in [
		"random", "biggest", "highest_attack", "lowest_attack", "highest_health", "lowest_health"
	]:
		combat.effect_rng.state = initial
		var picked: BoardUnit = TargetSelect.pick({"select": "enemies", "pick": how}, world)[0]
		assert_eq(picked, combat.unit_at(1, expected_slot), how)
		assert_eq(combat.effect_rng.state, reference.state, how + " consumes one key per candidate")
	combat.effect_rng.state = initial
	TargetSelect.pick({"select": "enemies", "pick": "first"}, world)
	assert_eq(combat.effect_rng.state, initial, "first consumes no RNG")


func test_fraction_set_reduce_gain_rounding_and_health_floor() -> void:
	var combat: Combat = _fight(
		{0: "field_vole"}, {4: {"def_id": "field_vole", "attack": 10001, "health": 9999}}
	)
	var world := CombatWorld.make(combat, combat.unit_at(0, 0), 0, {}, "start_of_combat")
	var enemy: CombatUnit = combat.unit_at(1, 4)
	EffectRunner.run_step(
		{
			"effect": "stat_fraction",
			"target": {"select": "enemies", "pick": "biggest"},
			"stat": "attack",
			"numerator": 1,
			"denominator": 2
		},
		{},
		world
	)
	assert_eq(enemy.attack, 5000)
	EffectRunner.run_step(
		{
			"effect": "stat_fraction",
			"target": {"select": "enemies", "pick": "biggest"},
			"stat": "health",
			"operation": "reduce",
			"numerator": 25,
			"denominator": 100
		},
		{},
		world
	)
	assert_eq(enemy.health, 7500)
	EffectRunner.run_step(
		{
			"effect": "stat_fraction",
			"target": {"select": "enemies", "pick": "biggest"},
			"operation": "reduce",
			"numerator": 200,
			"denominator": 100
		},
		{},
		world
	)
	assert_eq(enemy.health, 1)
	assert_eq(enemy.attack, 0)
	assert_eq(StatFraction.delta(10, 1, 2, "gain", 0), 5)
	assert_eq(
		MechanicRegistry.params_for({"id": "damage_reduction", "percent": 25}, true)["percent"], 25
	)


func test_damage_reduction_shield_batch_and_effect_damage() -> void:
	kit.card("armour", [{"id": "damage_reduction", "n": 2}, {"id": "shield"}], [], 3, 100)
	var combat: Combat = _fight({0: "armour"}, {0: "field_vole"})
	var target: CombatUnit = combat.unit_at(0, 0)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	combat.deal_effect_damage(enemy, target, 1)
	assert_true(target.has_status("shield"), "fully reduced damage does not spend Shield")
	var hits: Array[Hit] = [
		Hit.make(enemy, target, 10, Hit.ATTACK), Hit.make(enemy, target, 12, Hit.THORNS)
	]
	combat._apply_hits(hits)
	assert_eq(target.health, 90, "Shield prevents first positive hit, second is reduced by 2")
	assert_false(target.has_status("shield"))
	assert_true(target.damaged)
	kit.card("percent_armour", [{"id": "damage_reduction", "percent": 25}], [], 0, 20000)
	combat = _fight({0: "percent_armour"}, {0: "field_vole"})
	target = combat.unit_at(0, 0)
	combat.deal_effect_damage(combat.unit_at(1, 0), target, 10001)
	assert_eq(target.health, 12499, "fraction prevented rounds down")


func test_cleave_hits_only_occupied_beside_slots_and_each_strike() -> void:
	kit.card("cleaver", [{"id": "cleave"}], [], 1000, 2000)
	var combat: Combat = _fight(
		{0: "cleaver"}, {0: "field_vole", 1: "field_vole", 2: "field_vole", 4: "field_vole"}
	)
	var hits: Array[Hit] = [
		Hit.make(combat.unit_at(0, 0), combat.unit_at(1, 1), 500, Hit.ATTACK, 2)
	]
	CombatDamage.cleave(combat, hits)
	assert_eq(hits.size(), 3)
	assert_eq([hits[1].target.slot, hits[2].target.slot], [0, 2])
	assert_eq(hits[1].strike, 2)
	assert_false(hits[1].on_defender, "collateral units do not retaliate or defend")


func test_proportional_bitter_jenny_hex_and_jack_keep_biting() -> void:
	kit.card("bitter_test", [{"id": "bitter", "percent": 25}], [], 1, 1)
	var combat: Combat = _fight(
		{0: "bitter_test"}, {0: {"def_id": "field_vole", "attack": 10000, "health": 10000}}
	)
	CombatLanes.bitter(combat, combat.unit_at(0, 0), combat.unit_at(1, 0))
	assert_eq(combat.unit_at(1, 0).attack, 7500)
	kit.card("daw_test", [{"id": "jack_daw", "percent": 50}], [], 1, 1)
	combat = _fight(
		{0: "daw_test"}, {0: {"def_id": "field_vole", "attack": 10000, "health": 10000}}
	)
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 0).attack, 5000)
	assert_eq(combat.unit_at(0, 0).attack, 5001)
	kit.card("hex_test", [{"id": "hex", "percent": 25}], [], 1, 1)
	combat = _fight(
		{0: "hex_test"}, {0: {"def_id": "field_vole", "attack": 10000, "health": 10000}}
	)
	combat._start_of_combat()
	combat._recalc_auras(false)
	assert_eq(combat.unit_at(1, 0).attack, 7500, "live Hex does not compound on recalc")
	kit.card("jenny_test", [{"id": "mire"}, {"id": "jenny", "percent": 25}], [], 1, 1)
	combat = _fight(
		{0: "jenny_test"}, {0: {"def_id": "field_vole", "attack": 10000, "health": 10000}}
	)
	combat._start_of_combat()
	combat._recalc_auras(false)
	assert_eq(combat.unit_at(1, 0).attack, 7500)


func test_cap_overlay_isolated_removes_all_declared_ceilings_and_keeps_guards() -> void:
	var config := GameConfig.full_game()
	assert_true(config.get_bool("card_size_caps"))
	assert_eq(config.get_strings("scale_levers"), PackedStringArray())
	assert_false(config.get_bool("scale_hero_spell_stats"))
	config.set_value("card_size_caps", false)
	config.set_value("card_rate_limits", false)
	var library: UnitLibrary = ScaleOverlay.library_for(kit.library, config)
	assert_eq(CoreUtil.to_int(kit.library.get_unit("bridge_toad")["permanent_buff_cap"]), 3)
	assert_false(library.get_unit("bridge_toad").has("permanent_buff_cap"))
	var toad := RecruitUnit.make(library.get_unit("bridge_toad"), 1)
	toad.add_permanent(10000, 10000)
	assert_eq(toad.perm_attack, 10000)
	var raw: Dictionary = {
		"id": "effect",
		"limit": 1,
		"lifetime": 3,
		"once": true,
		"do": {"effect": "multiply", "most": 8, "per_max": 1}
	}
	var overlaid: Dictionary = ScaleOverlay.card_for(raw, config)
	assert_false(overlaid.has("lifetime"))
	assert_false(overlaid["once"])
	assert_eq(overlaid["limit"], BoardUnit.STAT_CLAMP)
	var step: Dictionary = overlaid["do"]
	assert_false(step.has("most"))
	assert_false(step.has("per_max"))
	var witch: RecruitUnit = RecruitUnit.make(library.get_unit("hedge_witch"), 2)
	assert_eq(witch.mechanic_number("hex", "most"), 0)
	assert_eq(config.get_int("trigger_limit_action"), 1000)
	assert_eq(config.get_int("trigger_limit_combat"), 10000)
	assert_eq(config.get_int("attack_limit"), 200)
	var session := GameSession.create(431, kit.library, config)
	assert_false(session._library.get_unit("alderman_dozey").has("permanent_buff_cap"))
	assert_true(kit.library.get_unit("alderman_dozey").has("permanent_buff_cap"))


func test_uncapped_lifetime_and_per_turn_limits_really_stop_limiting_payments() -> void:
	kit.config.set_value("card_size_caps", false)
	kit.config.set_value("card_rate_limits", false)
	var entry: Dictionary = KIT.effect(
		"end_of_turn", {"effect": "buff", "attack": 1, "health": 1}, {"limit": 1, "lifetime": 1}
	)
	entry = ScaleOverlay.card_for(entry, kit.config)
	kit.card("uncapped_test", [entry])
	var unit: RecruitUnit = kit.put("uncapped_test", 0)
	for _turn: int in 3:
		kit.rules.events.fire(kit.player, "end_of_turn")
	assert_eq(unit.attack, 4)
	assert_eq(unit.health, 4)


func test_lever_pool_default_absence_opt_in_presence_and_engine_dials() -> void:
	for id: String in ["scale_engine", "scale_answer", "scale_doubler", "scale_economy"]:
		assert_false(kit.pool.has_unit(id))
		assert_true(kit.library.get_unit(id).is_empty())
		assert_false(UnitLibrary.load_dir("res://content/levers").get_unit(id)["pool"])
	_enable_levers()
	var pool: UnitPool = UnitPool.create(kit.library, kit.config)
	for id: String in ["scale_engine", "scale_answer", "scale_doubler", "scale_economy"]:
		assert_true(pool.has_unit(id))
	var engine: RecruitUnit = kit.put("scale_engine", 0)
	var ally: RecruitUnit = kit.put("field_vole", 1)
	kit.config.set_value("scale_engine_tribe", "Hedgerow folk")
	kit.config.set_value("scale_engine_percent", 50)
	ally.attack = 1000
	ally.health = 2000
	kit.rules.end_phase(kit.player)
	assert_eq([ally.attack, ally.health], [1500, 3000])
	assert_eq(engine.attack, 3, "neutral engine is outside the tribe target")
	kit.config.set_value("scale_engine_self", true)
	kit.config.set_value("scale_engine_flat", 10)
	kit.rules.end_phase(kit.player)
	assert_eq([engine.attack, engine.health], [13, 13])
	assert_eq(ally.attack, 1500)


func test_doubler_repeats_end_turn_with_limits_and_action_guard_intact() -> void:
	_enable_levers()
	kit.config.set_value("scale_engine_self", true)
	kit.config.set_value("scale_engine_flat", 10)
	var unit: RecruitUnit = kit.put("scale_engine", 0)
	kit.put("scale_doubler", 4)
	kit.rules.end_phase(kit.player)
	assert_eq(unit.attack, 23)
	kit.player.board[4] = null
	kit.put("scale_doubler", 4, true)
	kit.rules.end_phase(kit.player)
	assert_eq(unit.attack, 53, "golden adds two firings")
	kit.card(
		"limited_test", [KIT.effect("end_of_turn", {"effect": "buff", "attack": 1}, {"limit": 1})]
	)
	var limited: RecruitUnit = kit.put("limited_test", 1)
	kit.rules.end_phase(kit.player)
	assert_eq(limited.attack, 2, "a doubler does not bypass card caps")
	kit.config.set_value("trigger_limit_action", 1)
	var before: int = unit.attack
	kit.rules.end_phase(kit.player)
	assert_lte(unit.attack - before, 20, "the trigger guard bounds repeats")


func test_economy_income_ramps_caps_and_buys_stats() -> void:
	_enable_levers()
	kit.config.set_value("scale_economy_cap", 2)
	kit.put("scale_economy", 0)
	for expected: int in [1, 2, 2]:
		kit.player.gold_next_turn = 0
		kit.rules.end_phase(kit.player)
		assert_eq(kit.player.gold_next_turn, expected)
	kit.rules.start_phase(kit.player, 1)
	assert_eq(kit.player.gold, 5, "ordinary 3 income plus lever's banked 2")
	kit.shop("field_vole")
	assert_eq(kit.rules.buy(kit.player, 0), "")
	assert_eq(kit.player.hand.size(), 1, "the income purchases an ordinary stat body")


func test_answer_dial_hits_hidden_carry_and_disabled_levers_are_inert() -> void:
	_enable_levers()
	kit.config.set_value("scale_levers", [])
	var combat: Combat = _fight(
		{0: "scale_answer"},
		{0: "field_vole", 4: {"def_id": "field_vole", "attack": 10000, "health": 20000}}
	)
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 4).attack, 10000)
	_enable_levers()
	kit.config.set_value("scale_answer_percent", 25)
	combat = _fight(
		{0: "scale_answer"},
		{0: "field_vole", 4: {"def_id": "field_vole", "attack": 10000, "health": 20000}}
	)
	combat._start_of_combat()
	assert_eq([combat.unit_at(1, 4).attack, combat.unit_at(1, 4).health], [7500, 15000])


func test_hero_spell_scaling_default_off_targeted_spell_and_unit_effect_separation() -> void:
	var ally: RecruitUnit = kit.put("field_vole", 0)
	ally.attack = 1000
	ally.health = 2000
	kit.spell(
		"scale_spell",
		{"effect": "buff", "attack": 2, "health": 1, "target": {"select": "chosen"}},
		"unit"
	)
	assert_eq(kit.cast("scale_spell", 0), "")
	assert_eq([ally.attack, ally.health], [1002, 2001])
	kit.config.set_value("scale_hero_spell_stats", true)
	kit.config.set_value("scale_hero_spell_percent", 10)
	assert_eq(kit.cast("scale_spell", 0), "")
	assert_eq([ally.attack, ally.health], [1202, 2201])
	kit.card(
		"flat_unit",
		[
			KIT.effect(
				"end_of_turn", {"effect": "buff", "attack": 2, "target": {"select": "friendly"}}
			)
		]
	)
	kit.put("flat_unit", 1)
	kit.rules.end_phase(kit.player)
	assert_eq(ally.attack, 1204, "unit effects keep their flat value")


func test_scaling_passive_activated_and_combat_hero_and_empty_slot_spell() -> void:
	kit.config.set_value("scale_hero_spell_stats", true)
	var ally: RecruitUnit = kit.put("field_vole", 0)
	ally.attack = 1000
	ally.health = 2000
	var entry: Dictionary = KIT.effect(
		"end_of_turn",
		{"effect": "buff", "attack": 1, "health": 1, "target": {"select": "friendly"}}
	)
	HeroRules.assign(kit.player, {"id": "test", "power": {"kind": "passive", "effects": [entry]}})
	kit.rules.end_phase(kit.player)
	assert_eq([ally.attack, ally.health], [1100, 2200])
	HeroRules.assign(
		kit.player,
		{
			"id": "test",
			"power":
			{
				"kind": "activated",
				"uses_per_turn": 1,
				"cost": 0,
				"aim": "unit",
				"do": {"effect": "buff", "health": 1, "target": {"select": "chosen"}}
			}
		}
	)
	assert_eq(kit.rules.use_power(kit.player, 0), "")
	assert_eq(ally.health, 2420)
	kit.spell(
		"scale_slot",
		{"effect": "slot_effect", "name": "Paint", "attack": 1, "health": 1, "at": "chosen"},
		"empty_slot"
	)
	assert_eq(kit.cast("scale_slot", 4), "")
	var slot: Dictionary = kit.player.slot_effects[4][0]
	assert_eq([slot["attack"], slot["health"]], [110, 242])
	var combat: Combat = _fight(
		{0: {"def_id": "field_vole", "attack": 10000, "health": 20000}}, {0: "field_vole"}
	)
	var world := CombatWorld.make(combat, null, 0, {}, "start_of_combat")
	EffectRunner.run(
		{"do": {"effect": "buff", "attack": 1, "target": {"select": "friendly"}}}, world
	)
	assert_eq(combat.unit_at(0, 0).attack, 11000)


func test_proportional_hex_growth_survives_recruit_to_combat_snapshot() -> void:
	kit.card("percent_hex", [{"id": "hex", "percent": 10}])
	var unit: RecruitUnit = kit.put("percent_hex", 0)
	kit.spell("nothing", {"effect": "gold", "amount": 0})
	assert_eq(kit.cast("nothing"), "")
	assert_eq(unit.counters["hex_percent"], 10)
	var result: Dictionary = kit.fight_board(
		{0: {"def_id": "field_vole", "attack": 10000, "health": 20000}}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -2000)


func test_keyword_reminders_follow_the_wording_guide_and_golden_parameters() -> void:
	for word: String in ["Damage Reduction", "Shield", "Cleave"]:
		var reminder: String = KeywordRules.text(word)
		assert_gt(reminder.length(), 0)
		assert_lte(reminder.split(" ", false).size(), 16)
		assert_false(reminder.contains("Scale"), "reminders name no test card")
	assert_eq(MechanicRegistry.params_for({"id": "damage_reduction", "n": 2}, true)["n"], 4)
	var step: Dictionary = {"effect": "stat_fraction", "numerator": 1, "denominator": 2}
	assert_eq(EffectSchema.doubled_step(step), step, "golden keeps ratios unchanged")


func test_cleave_in_real_quick_exchange_kills_beside_without_retaliation() -> void:
	kit.card("quick_cleave", [{"id": "cleave"}, {"id": "quick_while_undamaged"}], [], 10000, 20000)
	var combat: Combat = _fight(
		{0: "quick_cleave"},
		{
			0: {"def_id": "field_vole", "attack": 20000, "health": 9999},
			1: {"def_id": "field_vole", "attack": 20000, "health": 9999},
			4: {"def_id": "field_vole", "attack": 0, "health": 10000}
		}
	)
	var attacker: CombatUnit = combat.unit_at(0, 0)
	combat._perform_attack(attacker, combat.unit_at(1, 0))
	assert_null(combat.unit_at(1, 0))
	assert_null(combat.unit_at(1, 1))
	assert_eq(combat.unit_at(1, 4).health, 10000)
	assert_eq(attacker.health, 20000)


func test_delayed_spell_scales_at_cast_and_large_board_mean_does_not_overflow() -> void:
	kit.config.set_value("scale_hero_spell_stats", true)
	var unit: RecruitUnit = kit.put("field_vole", 0)
	unit.attack = 10000
	unit.health = 20000
	kit.spell(
		"scale_timer",
		{
			"effect": "wait_in_slot",
			"turns": 2,
			"attack": 3,
			"health": 3,
			"target": {"select": "chosen"}
		},
		"unit"
	)
	assert_eq(kit.cast("scale_timer", 0), "")
	assert_eq([unit.timers[0]["attack"], unit.timers[0]["health"]], [3000, 6000])
	for slot: int in range(1, 7):
		kit.put("field_vole", slot)
	for ally: RecruitUnit in kit.player.board:
		ally.attack = BoardUnit.STAT_CLAMP
		ally.health = BoardUnit.STAT_CLAMP
	var world := RecruitContext.make(kit.rules, kit.player, "cast", {})
	assert_eq(
		FlatStatScaling.board_baseline(world), Vector2i(BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP)
	)


func test_uncapped_ring_and_scripted_once_limits_are_part_of_the_overlay() -> void:
	kit.config.set_value("card_size_caps", false)
	kit.config.set_value("card_rate_limits", false)
	kit.player.card_size_caps = false
	kit.player.card_rate_limits = false
	var world := RecruitContext.make(kit.rules, kit.player, "cast", {})
	world.add_slot_effect(4, {"name": "Ring", "attack": 10000, "health": 20000})
	world.add_slot_effect(4, {"name": "Ring", "attack": 10000, "health": 20000})
	assert_eq(BoardUpkeep.ring_value(kit.player.slot_effects[4]), Vector2i(20000, 40000))
	assert_false(world.ring_full_at(4))
	var library: UnitLibrary = ScaleOverlay.library_for(kit.library, kit.config)
	for id: String in ["stone_soup", "nell", "kiss"]:
		var entry: Dictionary = ScaleOverlay.card_for({"id": id}, kit.config)
		assert_eq(entry["limit"], BoardUnit.STAT_CLAMP)
	var soup := RecruitUnit.make(library.get_unit("stone_soup"), 123)
	kit.player.board[0] = soup
	world.source = soup
	world.source_slot = 0
	world.params = {"stats": 1, "limit": BoardUnit.STAT_CLAMP}
	var mechanic: Mechanic = MechanicRegistry.get_mechanic("stone_soup")
	var before: int = soup.attack
	for _swallow: int in 3:
		mechanic.on_swallow(world)
	assert_eq(soup.attack, before + 3)
	assert_eq(
		ScaleOverlay.card_for({"id": "bubble", "splits": 1}, kit.config)["splits"],
		BoardUnit.STAT_CLAMP
	)
	assert_true(ScaleOverlay.card_for({"id": "reel_mistress"}, kit.config)["repeat"])


func test_caps_off_allows_repeated_harvest_supper_and_more_than_two_stalls() -> void:
	kit.config.set_value("card_size_caps", false)
	kit.config.set_value("card_rate_limits", false)
	kit.player.card_size_caps = false
	kit.player.card_rate_limits = false
	var unit: RecruitUnit = kit.put("field_vole", 0)
	for _cast: int in 4:
		assert_eq(kit.cast("harvest_supper", 0), "")
	assert_eq(unit.tribe_attack, 4)
	for _cast: int in 3:
		assert_eq(kit.cast("market_stall"), "")
	assert_eq(kit.player.market_stalls, 3)
	assert_false(MarketStalls.limit_reached(kit.player))
	assert_eq(MarketStalls.unit_bonus(kit.rules, kit.player), 3)


func test_proportional_hex_and_economy_progress_survive_triples() -> void:
	kit.card("triple_percent_hex", [{"id": "hex", "percent": 10}])
	var copies: Array = []
	for slot: int in 3:
		var unit: RecruitUnit = kit.put("triple_percent_hex", slot)
		unit.counters["hex_percent"] = (slot + 1) * 10
		copies.append(unit)
	kit.rules.combine(kit.player, copies, false)
	var golden: RecruitUnit = kit.player.hand[0]
	assert_eq(golden.counters["hex_percent"], 60)
	assert_eq(kit.rules.play(kit.player, 0, 0), "")
	var combat: Combat = _fight(
		{0: golden.combat_spec()}, {0: {"def_id": "field_vole", "attack": 10000, "health": 20000}}
	)
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 0).attack, 3000)
	_enable_levers()
	kit.player.board.fill(null)
	copies.clear()
	for slot: int in 3:
		var unit: RecruitUnit = kit.put("scale_economy", slot)
		unit.counters["scale_income"] = slot + 1
		copies.append(unit)
	kit.rules.combine(kit.player, copies, false)
	golden = kit.player.hand[0]
	assert_eq(golden.counters["scale_income"], 3, "keep the most advanced income")
	assert_eq(kit.rules.play(kit.player, 0, 0), "")
	kit.rules.end_phase(kit.player)
	assert_eq(kit.player.gold_next_turn, 8, "improve 3 to 4, then double the payout")
