extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const K := preload("res://tests/core/recruit_kit.gd")
const C := preload("res://tests/core/combat_kit.gd")
var _kit: K


func before_each() -> void:
	_kit = K.new()
	_kit.setup(GameConfig.full_game())
	_kit.put("field_vole", 0)


func _slots() -> Array:
	var out: Array = []
	for slot: int in BoardGeometry.SLOTS:
		out.append([])
	return out


func _fight(enemy: Dictionary, ring: Vector2i, slot: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var combat := Combat.create(_kit.library, _kit.config, rng)
	var their_slots: Array = _slots()
	their_slots[slot].append({"name": "Ring", "attack": ring.x, "health": ring.y, "golden": false})
	combat.slot_effects = [_kit.player.combat_slots(), their_slots]
	return combat.run([_kit.player.combat_board(), C.board(enemy)], [2, 6], [0, 1], 0)


func _cast(slot: int = 1) -> void:
	_kit.rules.give_card(_kit.player, "horseshoe")
	assert_eq(_kit.rules.play_item(_kit.player, 0, slot), "")


func _start(result: Dictionary, side: int, slot: int) -> Dictionary:
	var boards: Array = C.of_type(result, "combat_start")[0]["boards"]
	return boards[side][slot]


func test_empty_own_slot_can_target_a_ring_and_rounds_down_without_changing_recruit_ring() -> void:
	_cast()
	var result: Dictionary = _fight({1: C.plain(2, 4)}, Vector2i(5, 3))
	var view: Dictionary = _start(result, 1, 1)
	assert_eq([view["attack"], view["health"]], [4, 5])
	var ring: Dictionary = result["events"][0]["slot_effects"][1][1][0]
	assert_eq([ring["attack"], ring["health"]], [5, 3], "raw Ring investment retained")
	_kit.rules.after_fights(_kit.player)
	assert_true(_kit.player.slot_effects[1].is_empty(), "spent after exactly one fight")


func test_monarch_extra_is_included_before_rounding_and_hex_is_separate() -> void:
	_cast()
	var result: Dictionary = _fight({1: C.u("fairy_monarch")}, Vector2i(3, 5))
	var view: Dictionary = _start(result, 1, 1)
	assert_eq([view["attack"], view["health"]], [6, 9], "(Ring + Monarch) / 2")


func test_halved_empty_ring_still_summons_wisp() -> void:
	_cast()
	var result: Dictionary = _fight({4: C.u("will_o_the_wisp")}, Vector2i(1, 1))
	var summons: Array[Dictionary] = C.of_type(result, "summon")
	assert_eq(summons.size(), 1)
	var wisp: Dictionary = summons[0]["unit"]
	assert_eq(summons[0]["slot"], 1)
	assert_eq([wisp["attack"], wisp["health"]], [1, 1])


func test_repeated_horseshoes_do_not_quarter_ring() -> void:
	_cast()
	_cast()
	var result: Dictionary = _fight({1: C.plain(1, 1)}, Vector2i(8, 8))
	var view: Dictionary = _start(result, 1, 1)
	assert_eq([view["attack"], view["health"]], [5, 5])


func test_untargeted_ring_and_non_ring_stats_are_unchanged() -> void:
	_cast(2)
	var result: Dictionary = _fight({1: C.plain(2, 4)}, Vector2i(5, 3))
	var view: Dictionary = _start(result, 1, 1)
	assert_eq([view["attack"], view["health"]], [7, 7])


func test_halving_follows_a_dancing_ring_and_preserves_original() -> void:
	_cast()
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	var combat := Combat.create(_kit.library, _kit.config, rng)
	var original: Array = _slots()
	original[1].append({"name": "Ring", "attack": 5, "health": 7, "golden": false})
	combat.slot_effects = [_kit.player.combat_slots(), original]
	CombatRings.prepare(combat)
	combat._setup([C.board({}), C.board({1: C.plain(1, 10), 2: C.u("reel_mistress")})])
	combat._recalc_auras(false)
	CombatMoves.dance_rings(combat, combat.unit_at(1, 1))
	assert_false(BoardUpkeep.has_ring(combat._slot_effects_at(1, 1)))
	assert_eq(CombatRings.bonus(combat, combat.unit_at(1, 2)), Vector2i(2, 3))
	assert_false(original[1][0].has("horseshoe"), "combat never changes permanent Rings")


func test_horseshoe_does_not_reduce_hex_or_non_ring_slot_effects() -> void:
	_cast()
	var rng := RandomNumberGenerator.new()
	var combat := Combat.create(_kit.library, _kit.config, rng)
	var slots: Array = _slots()
	slots[1].append({"name": "Ring", "attack": 5, "health": 5})
	slots[1].append({"name": "Other", "attack": 3, "health": 4})
	combat.slot_effects = [_kit.player.combat_slots(), slots]
	CombatRings.prepare(combat)
	combat._setup([C.board({}), C.board({1: C.plain(10, 10)})])
	combat.add_hex(null, 1, 1, 4)
	var unit: CombatUnit = combat.unit_at(1, 1)
	assert_eq([unit.attack, unit.health], [11, 16], "10 + 2 Ring + 3 other - 4 Hex")
