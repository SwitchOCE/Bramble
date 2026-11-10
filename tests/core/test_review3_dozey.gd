extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_doubling_is_preserved_and_permanent_growth_stops_at_printed_ceiling() -> void:
	for golden: bool in [false, true]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game())
		kit.rules.start_phase(kit.player, 1)
		var unit: RecruitUnit = kit.put("alderman_dozey", 0, golden)
		var factor: int = 2 if golden else 1
		for _turn: int in 3:
			kit.pass_turn()
		assert_eq(unit.attack, 4 * factor)
		assert_eq(unit.health, 10 * factor)
		unit.add_permanent(100, 100)
		assert_eq(unit.perm_attack, 12 * factor)
		assert_eq(unit.perm_health, 12 * factor)
		unit.add_permanent(100, 100)
		assert_eq(unit.attack, 14 * factor)
		assert_eq(unit.health, 17 * factor)
		unit.add_permanent(-4, -4)
		assert_true(unit.can_gain_permanent(), "debuffs reduce the actual stored bonus")
		unit.add_permanent(4, 4)
		assert_false(unit.can_gain_permanent())
		unit.set_aura(3, 5)
		assert_eq(unit.attack, 14 * factor + 3, "slot bonuses still matter")


func test_a_capped_feed_is_refused_without_consuming_the_acorn() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var unit: RecruitUnit = kit.put("alderman_dozey", 0)
	unit.add_permanent(20, 20)
	kit.rules.give_card(kit.player, "great_hoard")
	assert_string_contains(kit.rules.play_item(kit.player, 0, 0), "capped")
	assert_eq(kit.item_ids(), ["great_hoard"])
	assert_false(unit.view()["eats_items"])
	var before: int = kit.player.gold
	assert_eq(kit.rules.play_item(kit.player, 0), "")
	assert_eq(kit.player.gold, before + 16)


func test_triples_and_combat_permanence_obey_the_same_ceiling() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	for _copy: int in 3:
		var unit: RecruitUnit = kit.put("alderman_dozey")
		unit.add_permanent(100, 100)
	kit.rules.check_triples(kit.player)
	var golden: RecruitUnit = kit.player.hand[0]
	assert_eq(golden.perm_attack, 24)
	assert_eq(golden.perm_health, 24)
	assert_eq(golden.attack, 28)
	assert_eq(golden.health, 34)
	var giver: String = kit.card(
		"permanent_giver",
		[
			Kit.effect(
				"start_of_combat",
				{
					"effect": "buff",
					"attack": 100,
					"health": 100,
					"duration": "permanent",
					"target": {"select": "friendly"}
				}
			)
		]
	)
	var dozey: RecruitUnit = kit.put("alderman_dozey", 0)
	dozey.add_permanent(10, 8)
	kit.put(giver, 1)
	var result: Dictionary = kit.fight_board({})
	assert_eq(dozey.perm_attack, 12)
	assert_eq(dozey.perm_health, 12)
	for change: Dictionary in result["carry"]:
		if change.get("iid", 0) == dozey.iid:
			assert_eq(change["attack"], 2, "carry only what fits")
			assert_eq(change["health"], 4)
	var ordinary: RecruitUnit = kit.put("field_vole", 2)
	ordinary.add_permanent(100, 100)
	assert_eq(ordinary.perm_attack, 100, "other cards have no new ceiling")


func test_borrowing_dozey_keeps_the_original_doubling_increment_bound() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game(), false, LegacyWave1.current_with_oozes())
	kit.rules.start_phase(kit.player, 1)
	var ooze: RecruitUnit = kit.put("frumenty", 0)
	ooze.add_permanent(30, 30)
	kit.put("alderman_dozey")
	assert_eq(kit.rules.swallow(kit.player, HeldUnits.HAND, 0, 0), "")
	var attack: int = ooze.attack
	var health: int = ooze.health
	for _turn: int in 3:
		kit.pass_turn()
	assert_eq(ooze.attack, attack + 8, "borrowed doubling retains its former bound")
	assert_eq(ooze.health, health + 8)


func test_native_frumenty_digests_before_its_borrowed_bounded_wake() -> void:
	var kit := Kit.new()
	var config := GameConfig.full_game()
	# The meal is a non-Ooze; hold A3.5's printed-stat eat multiplier off to check the wake order.
	config.set_value("oozes_eat_printed_multiplier", 1)
	kit.setup(config)
	kit.rules.start_phase(kit.player, 1)
	var ooze: RecruitUnit = kit.put("frumenty", 0)
	ooze.add_permanent(30, 30)
	var meal: RecruitUnit = kit.put("alderman_dozey")
	var attack: int = ooze.attack
	var health: int = ooze.health
	var meal_attack: int = meal.attack
	var meal_health: int = meal.health
	assert_eq(kit.rules.swallow(kit.player, HeldUnits.HAND, 0, 0), "")
	kit.pass_turn()
	assert_true(ooze.held.is_empty(), "native Frumenty digests the meal next morning")
	assert_eq(ooze.last_meals.size(), 1, "the digested meal's text remains available")
	assert_eq(ooze.attack, attack + meal_attack, "Digest adds the meal's own Attack")
	assert_eq(ooze.health, health + meal_health, "Digest adds the meal's own Health")
	for _turn: int in 2:
		kit.pass_turn()
	assert_eq(ooze.attack, attack + meal_attack + 8, "the borrowed wake adds only its bound")
	assert_eq(ooze.health, health + meal_health + 8)
