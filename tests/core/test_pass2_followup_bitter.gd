extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")
const Fight := preload("res://tests/core/combat_kit.gd")
var _kit: Kit
var _combat: Combat


func before_each() -> void:
	_kit = Kit.new()
	_kit.setup(GameConfig.full_game(), false, LegacyBog.library())
	_combat = Combat.create(_kit.library, _kit.config, RandomNumberGenerator.new())


func _setup(ours: Dictionary, theirs: Dictionary) -> void:
	_combat._setup([Fight.board(ours), Fight.board(theirs)])
	_combat._recalc_auras(false)
	CombatLanes.bell(_combat)


func test_bitter_shrinks_the_first_hit_before_damage_and_keeps_the_wall_alive() -> void:
	_setup({0: Fight.u("madame_bufo", 1, 4)}, {0: Fight.plain(5, 20)})
	var wall: CombatUnit = _combat.unit_at(0, 0)
	var attacker: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(attacker, wall)
	assert_true(wall.on_board)
	assert_eq(wall.health, 1)
	assert_eq(attacker.attack, 3)
	var first_loss: int = -1
	var first_damage: int = -1
	for index: int in _combat.events.size():
		var event: Dictionary = _combat.events[index]
		if event["type"] == "stats" and event["target"] == attacker.uid:
			first_loss = index
		if event["type"] == "damage" and first_damage < 0:
			first_damage = index
	assert_gte(first_loss, 0)
	assert_lt(first_loss, first_damage)


func test_bitter_does_not_reduce_pack_joiner_damage() -> void:
	_setup({0: Fight.plain(5, 30), 1: Fight.u("wick", 2, 30)}, {0: Fight.u("madame_bufo", 1, 100)})
	var leader: CombatUnit = _combat.unit_at(0, 0)
	var joiner: CombatUnit = _combat.unit_at(0, 1)
	var wall: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(leader, wall)
	assert_eq(leader.attack, 3)
	assert_eq(wall.health, 95, "leader 3 plus unchanged joiner 2")
	var joined_damage: int = 0
	for event: Dictionary in Fight.of_type({"events": _combat.events}, "damage"):
		if event.get("source") == joiner.uid:
			joined_damage += CoreUtil.to_int(event["amount"])
	assert_eq(joined_damage, 2)


func test_bitter_applies_after_the_counter_bonus_and_before_the_counter_hit() -> void:
	_setup(
		{0: Fight.u("prima_donna", 3, 40), 1: Fight.u("warty_nan", 1, 50)},
		{0: Fight.u("gideon", 2, 100)}
	)
	var wall: CombatUnit = _combat.unit_at(0, 0)
	_combat.queue_attack(_combat.unit_at(1, 0), wall, "counter", 2)
	_combat.reactions.drain(_combat)
	assert_eq(wall.health, 39, "2 base +2 counter -3 Bitter =1, not3")


func test_bitter_also_precedes_a_pounce() -> void:
	_setup({0: Fight.u("madame_bufo", 1, 40)}, {0: Fight.u("lodger", 4, 30)})
	var wall: CombatUnit = _combat.unit_at(0, 0)
	_combat.queue_attack(_combat.unit_at(1, 0), wall, "pounce")
	_combat.reactions.drain(_combat)
	assert_eq(wall.health, 38)


func test_bitter_never_raises_zero_attack_and_stops_a_positive_attack_at_one() -> void:
	for attack: int in [0, 1, 2]:
		_setup({0: Fight.u("madame_bufo", 1, 40)}, {0: Fight.plain(attack, 20)})
		var wall: CombatUnit = _combat.unit_at(0, 0)
		var attacker: CombatUnit = _combat.unit_at(1, 0)
		_combat._attack(attacker, wall)
		assert_eq(attacker.attack, 0 if attack == 0 else 1)
		assert_eq(wall.health, 40 if attack == 0 else 39)


func test_borrowed_wren_attack_is_also_shrunk_before_damage() -> void:
	_setup({0: Fight.plain(1, 40)}, {0: Fight.u("madame_bufo", 0, 100), 4: Fight.plain(20, 100)})
	var attacker: CombatUnit = _combat.unit_at(0, 0)
	var wall: CombatUnit = _combat.unit_at(1, 0)
	_combat.set_status(attacker, "borrowed_attack", true, null)
	_combat._attack(attacker, wall)
	assert_eq(wall.health, 82, "highest enemy20 minus Bitter2")
	assert_false(attacker.has_status("borrowed_attack"))


func test_once_per_enemy_is_spent_even_when_the_declaration_cancels_the_hit() -> void:
	_kit.card(
		"bitter_cancel",
		[
			{"id": "bitter", "n": 2, "once_per_enemy": true},
			Kit.effect(
				"on_attacked", {"effect": "damage", "amount": 50, "target": {"select": "subject"}}
			)
		],
		[],
		1,
		40
	)
	_setup({0: Fight.u("bitter_cancel")}, {0: Fight.plain(5, 1)})
	var wall: CombatUnit = _combat.unit_at(0, 0)
	var attacker: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(attacker, wall)
	assert_false(attacker.on_board)
	assert_eq(wall.health, 40, "attack damage never lands")
	assert_eq(wall.limits.size(), 1, "the declaration still spends the enemy's one Bitter")
	assert_eq(Fight.of_type({"events": _combat.events}, "cancel").size(), 1)


func test_bitter_is_once_per_declared_attack_not_per_peck_strike() -> void:
	_kit.card("bitter_pecker", [{"id": "peck", "strikes": 3}], [], 5, 40)
	_setup({0: Fight.u("bitter_pecker")}, {0: Fight.u("madame_bufo", 1, 100)})
	var attacker: CombatUnit = _combat.unit_at(0, 0)
	var wall: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(attacker, wall)
	assert_eq(attacker.attack, 3)
	assert_eq(wall.health, 97, "reduced Attack3 is split into three1 hits")
