extends GutTest
@warning_ignore_start("unsafe_call_argument")
## Permanent rewards observe the settled ordinary-start board in either player order.

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")

var kit: KIT
var seen_orders: Dictionary = {}


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())
	seen_orders = {}


func _body(id: String, attack: int, health: int, iid: int) -> Dictionary:
	var spec: Dictionary = CK.u(id, attack, health)
	spec["iid"] = iid
	return spec


func _fight(mine: Dictionary, theirs: Dictionary, seed_value: int) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	var peek := RandomNumberGenerator.new()
	peek.seed = rng.seed
	peek.state = rng.state
	seen_orders[peek.randi_range(0, 1)] = true
	return combat


func _start(combat: Combat) -> void:
	combat._recalc_auras(false)
	combat._start_of_combat()


func _reward(combat: Combat, iid: int) -> Vector2i:
	var total := Vector2i.ZERO
	for change: Dictionary in combat.carry:
		if str(change.get("op", "")) == "buff" and CoreUtil.to_int(change.get("iid", 0)) == iid:
			total += Vector2i(CoreUtil.to_int(change["attack"]), CoreUtil.to_int(change["health"]))
	return total


func test_jack_reads_full_fetch_and_its_own_ring_after_either_player_order() -> void:
	for seed_value: int in range(1, 17):
		var combat: Combat = _fight(
			{0: "jack_daw", 4: _body("chiffchaff", 1000, 1000, 91)},
			{0: "cradle_fetch", 4: CK.u("hedge_witch", 100, 120)},
			seed_value
		)
		combat.slot_effects = [
			[], [[{"name": "Ring", "attack": 10, "health": 10}], [], [], [], [], [], []]
		]
		combat._slots_active = true
		_start(combat)
		assert_eq(_reward(combat, 91), Vector2i(28, 33), str(seed_value))
	assert_eq(seen_orders.size(), 2)


func test_jack_steals_after_granny_gathers_in_both_player_orders() -> void:
	for seed_value: int in range(1, 17):
		var combat: Combat = _fight(
			{0: "jack_daw", 4: _body("chiffchaff", 1000, 1000, 91)},
			{0: CK.u("granny_stir_up", 20, 40), 4: CK.u("moss_ooze", 80, 60)},
			seed_value
		)
		_start(combat)
		assert_eq(_reward(combat, 91), Vector2i(25, 10), str(seed_value))
	assert_eq(seen_orders.size(), 2)


func test_whistlers_set_the_largest_friendly_recipient_before_jack() -> void:
	for seed_value: int in range(1, 17):
		var combat: Combat = _fight(
			{
				0: "jack_daw",
				4: _body("chiffchaff", 100, 100, 91),
				5: _body("one_swallow", 70, 80, 92)
			},
			{0: CK.plain(80, 120), 4: "seven_whistlers"},
			seed_value
		)
		_start(combat)
		assert_eq(_reward(combat, 91), Vector2i.ZERO)
		assert_eq(_reward(combat, 92), Vector2i(20, 30), str(seed_value))
	assert_eq(seen_orders.size(), 2)


func test_changeling_changes_the_recipient_pool_before_jack() -> void:
	for seed_value: int in range(1, 17):
		var combat: Combat = _fight(
			{
				0: "jack_daw",
				4: _body("chiffchaff", 100, 100, 91),
				5: _body("one_swallow", 70, 80, 92)
			},
			{0: CK.plain(80, 120), 4: "changeling"},
			seed_value
		)
		_start(combat)
		assert_eq(_reward(combat, 91), Vector2i.ZERO)
		assert_eq(_reward(combat, 92), Vector2i(20, 30), str(seed_value))
	assert_eq(seen_orders.size(), 2)


func test_copied_jack_also_waits_and_stays_outside_the_biggest_enemy_audit_class() -> void:
	kit.card(
		"fairy_jack",
		[{"id": "pass3_bird", "ability": "jack_daw", "factor": 1}],
		["Fairies"],
		100,
		100
	)
	kit.card(
		"booster",
		[
			KIT.effect(
				"start_of_combat",
				{"effect": "buff", "attack": 60, "health": 40, "target": {"select": "self"}}
			)
		],
		[],
		40,
		80
	)
	for seed_value: int in range(1, 17):
		var combat: Combat = _fight(
			{0: "booster", 4: CK.plain(1, 1)},
			{0: "cradle_fetch", 4: "fairy_jack", 5: _body("chiffchaff", 2, 2, 93)},
			seed_value
		)
		_start(combat)
		assert_eq(_reward(combat, 93), Vector2i(26, 30), str(seed_value))
	assert_eq(seen_orders.size(), 2)
	assert_true(Pass3Combat.is_late_start("pass3_bird", {"ability": "jack_daw"}))
	assert_false(Pass3Combat.is_biggest_enemy("pass3_bird", {"ability": "jack_daw"}))
