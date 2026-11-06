extends GutTest
## Slot effects (rulebook 8.5): a slot keeps a lasting effect for the rest of the game, acting
## through whatever stands in it.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const PAINT: Dictionary = {"effect": "slot_effect", "attack": 2, "health": 3, "at": "chosen"}

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup()
	_player = _kit.player
	_rules = _kit.rules


func _paint(slot: int, step: Dictionary = PAINT) -> void:
	var id: String = _kit.spell("paint", step, HandItem.AIM_ANY_SLOT)
	_rules.give_card(_player, id)
	assert_eq(_rules.play_item(_player, _player.items.size() - 1, slot), "", "cast the paint")


func test_slot_effect_stays_with_the_slot_8_5_1() -> void:
	_kit.card("post", [], [], 1, 1)
	_kit.put("post", 2)
	_paint(2)
	_rules.move(_player, 2, 3)
	var slot_two: Array = _player.slot_effects[2]
	var slot_three: Array = _player.slot_effects[3]
	assert_eq([slot_two.size(), slot_three.size()], [1, 0], "moving the unit leaves it behind")
	_rules.sell(_player, 3)
	assert_eq(slot_two.size(), 1, "selling doesn't remove it")


func test_empty_slot_does_nothing_8_5_1() -> void:
	_paint(1)
	_kit.card("post", [], [], 1, 1)
	var result: Dictionary = _kit.fight_with_slots({0: "post"}, {0: "post"}, [{1: [PAINT]}, {}])
	var strikes: Array[Dictionary] = KIT.of_type(result, "attack")
	assert_gt(strikes.size(), 0, "they still fight")
	assert_eq(result["winner"], -1, "the empty slot's +2/+3 helped nobody")


func test_slot_bonus_applies_in_the_fight_8_5_1() -> void:
	_kit.card("post", [], [], 1, 1)
	var result: Dictionary = _kit.fight_with_slots({0: "post"}, {0: "post"}, [{0: [PAINT]}, {}])
	assert_eq(result["winner"], 0, "+2/+3 wins an even fight")
	assert_true(result["events"][0].has("slot_effects"), "the replay can show them")


func test_no_slot_effects_means_no_event_field_8_5() -> void:
	_kit.card("post", [], [], 1, 1)
	var result: Dictionary = _kit.fight_with_slots({0: "post"}, {0: "post"}, [{}, {}])
	assert_false(result["events"][0].has("slot_effects"), "fights without them read as before")


func test_slot_mechanic_plays_through_the_occupant_8_5_1() -> void:
	_kit.card("post", [], [], 1, 1)
	var entry: Dictionary = KIT.effect(
		"end_of_turn", {"effect": "buff", "attack": 1, "target": {"select": "self"}}
	)
	_paint(0, {"effect": "slot_effect", "mechanic": entry, "at": "chosen"})
	var unit: RecruitUnit = _kit.put("post", 0)
	_rules.events.fire(_player, "end_of_turn")
	assert_eq(unit.attack, 2, "the unit in the slot gains")
	var other: RecruitUnit = _kit.put("post", 1)
	_rules.events.fire(_player, "end_of_turn")
	assert_eq([unit.attack, other.attack], [3, 1], "only that slot's unit")


func test_slot_mechanic_grants_in_combat_8_5_1() -> void:
	_kit.card("post", [], [], 1, 1)
	var entry: Dictionary = KIT.effect(
		"start_of_combat",
		{"effect": "buff", "attack": 5, "health": 5, "target": {"select": "self"}}
	)
	var effect: Dictionary = {"entry": entry, "golden": false}
	var result: Dictionary = _kit.fight_with_slots({0: "post"}, {0: "post"}, [{0: [effect]}, {}])
	assert_eq(result["winner"], 0, "the slot's mechanic played through the unit")


func test_slot_effects_on_a_targeted_step_8_5() -> void:
	_kit.card("post", [], [], 1, 1)
	_kit.put("post", 4)
	var id: String = _kit.spell(
		"rows", {"effect": "slot_effect", "attack": 1, "target": {"select": "friendly"}}
	)
	_rules.give_card(_player, id)
	_rules.play_item(_player, 0)
	var effects: Array = _player.slot_effects[4]
	var empty: Array = _player.slot_effects[0]
	assert_eq([effects.size(), empty.size()], [1, 0], "only the occupied slot was chosen")


func test_session_fights_with_the_players_slots_8_5_2() -> void:
	var session := GameSession.create(5, UnitLibrary.load_dir(), GameConfig.defaults())
	var human: PlayerState = session._human()
	var slots: Array = session.get_state()["slot_effects"]
	assert_eq(slots.size(), BoardGeometry.SLOTS, "the state shows one list per slot")
	var paint: Array = human.slot_effects[0]
	paint.append({"name": "Paint", "attack": 50, "health": 50})
	human.board[0] = RecruitUnit.make(UnitLibrary.load_dir().get_unit("hoglet_mother"), 900)
	assert_eq(session.end_turn(), "", "fought")
	assert_eq(session.get_last_combat()["winner"], 0, "the slot's +50/+50 won it")
	assert_eq(human.slot_effects[0].size(), 1, "and it stays afterwards")


func test_ghost_fights_with_its_slots_8_5_2() -> void:
	var session := GameSession.create(5, UnitLibrary.load_dir(), GameConfig.defaults())
	var dying: PlayerState = session._players[3]
	var paint: Array = dying.slot_effects[1]
	paint.append({"name": "Paint", "attack": 1})
	dying.health = 0
	session._ghost_board = dying.combat_board()
	session._ghost_slots = dying.combat_slots()
	var row: Array = session._ghost_slots[1]
	assert_eq(row.size(), 1, "the ghost carries the slot's effect")
