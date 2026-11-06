extends GutTest
## Lobby tribes (rulebook 5.2.4, 5.2.7, 5.1.3) and merges (4.3.5, 7.2.2: one unit absorbs another).
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup()
	_player = _kit.player
	_rules = _kit.rules


func _neutral_count(pool: UnitPool) -> int:
	var count: int = 0
	for id: String in pool.ids():
		if pool.tribes_of(id).is_empty():
			count += 1
	return count


func test_lobby_draws_the_config_number_of_tribes_5_2_4() -> void:
	var library := UnitLibrary.load_dir()
	var rotation: PackedStringArray = library.tribes_in_rotation()
	if rotation.size() < 2:
		pending("needs two tribes in rotation")
		return
	var config := GameConfig.defaults()
	config.set_value("tribes_per_lobby", rotation.size() - 1)
	var state: Dictionary = GameSession.create(3, library, config).get_state()
	assert_eq(state["lobby_tribes"].size(), rotation.size() - 1, "the number asked")


func test_lobby_default_means_every_tribe_5_2_4() -> void:
	var state: Dictionary = (
		GameSession.create(3, UnitLibrary.load_dir(), GameConfig.defaults()).get_state()
	)
	assert_eq(state["lobby_tribes"], [], "empty: all in")


func test_pool_holds_only_lobby_tribes_and_neutrals_5_1_3_5_2_7() -> void:
	var library := UnitLibrary.load_dir()
	var rotation: PackedStringArray = library.tribes_in_rotation()
	var chosen := PackedStringArray([rotation[0]])
	var whole: UnitPool = UnitPool.create(library, _kit.config)
	var pool: UnitPool = UnitPool.create(library, _kit.config, chosen)
	assert_eq(_neutral_count(pool), _neutral_count(whole), "neutrals always in")
	for id: String in pool.ids():
		var tribes: Array = pool.tribes_of(id)
		assert_true(tribes.is_empty() or tribes.has(rotation[0]), "%s fits the lobby" % id)


func test_lobby_draw_is_seeded_5_2_4() -> void:
	var library := UnitLibrary.load_dir()
	var config := GameConfig.defaults()
	config.set_value("tribes_per_lobby", 1)
	var one: Array = GameSession.create(8, library, config).get_state()["lobby_tribes"]
	var two: Array = GameSession.create(8, library, config).get_state()["lobby_tribes"]
	assert_eq(one, two, "same seed, same tribes")


func _ooze(text: String = "") -> String:
	var raw: Dictionary = {
		"id": "ooze",
		"name": "Ooze",
		"tier": 1,
		"attack": 2,
		"health": 3,
		"tribes": ["ooze"],
		"text": text,
		"golden_text": text,
		"mechanics": [],
		"keywords": [],
		"row_hint": null,
		"pool": false,
		"priority": null,
		"skeleton": false,
		"merge_into": "ooze",
	}
	assert_eq(_kit.library.register_unit(raw), "", "registered")
	return "ooze"


func test_merge_adds_stats_as_permanent_4_3_5() -> void:
	_ooze()
	var into: RecruitUnit = _kit.put("ooze", 0)
	var other: RecruitUnit = _kit.put("ooze", 1)
	other.add_permanent(1, 1)
	_rules.merge_units(_player, into, other)
	assert_eq([into.attack, into.health], [5, 7], "2/3 + 3/4")
	assert_null(_player.board[1], "the absorbed unit is gone")


func test_merge_pass_the_mechanics_along_4_3_5() -> void:
	_kit.card("giver", [KIT.effect("end_of_turn", {"effect": "gold", "amount": 1})], ["ooze"], 1, 1)
	_ooze()
	var into: RecruitUnit = _kit.put("ooze", 0)
	var other: RecruitUnit = _kit.put("giver", 1)
	_rules.merge_units(_player, into, other)
	_player.gold = 0
	_rules.events.fire(_player, "end_of_turn")
	assert_eq(_player.gold, 1, "the absorber does what the absorbed did")


func test_merge_keeps_pool_copies_and_sell_returns_them_5_3_5() -> void:
	_ooze()
	var library: UnitLibrary = _kit.library
	var first: String = library.pool_units()[0]["id"]
	var into: RecruitUnit = RecruitUnit.make(library.get_unit(first), 1)
	var other: RecruitUnit = RecruitUnit.make(library.get_unit(first), 2)
	into.pool_copies = 1
	other.pool_copies = 1
	_player.board[0] = into
	_player.board[1] = other
	_rules.merge_units(_player, into, other)
	assert_eq(into.copies_held(), 2, "both copies")
	var before: int = _kit.pool.total_copies()
	_rules.sell(_player, 0)
	assert_eq(_kit.pool.total_copies(), before + 2, "both go back")


func test_merge_origin_bought_if_either_was_4_3_5() -> void:
	_ooze()
	var into: RecruitUnit = _kit.put("ooze", 0)
	var other: RecruitUnit = _kit.put("ooze", 1)
	other.origin = RecruitUnit.ORIGIN_BOUGHT
	_rules.merge_units(_player, into, other)
	assert_eq(into.origin, RecruitUnit.ORIGIN_BOUGHT, "takes Bought")


func test_merge_text_shows_what_was_absorbed_4_3_5() -> void:
	_ooze("Squish.")
	var into: RecruitUnit = _kit.put("ooze", 0)
	_rules.merge_units(_player, into, _kit.put("ooze", 1))
	var view: Dictionary = into.view()
	assert_string_contains(str(view["text"]), "Ooze: Squish.", "both texts")


func test_merge_into_slot_when_played_on_a_fit_7_2_2() -> void:
	_ooze()
	_kit.put("ooze", 0)
	var other: RecruitUnit = _kit.put("ooze")
	assert_eq(_rules.play(_player, 0, 0), "", "merged instead of refused")
	assert_eq(_player.hand.find(other), -1, "left the hand")
	assert_eq(_player.board[0].health, 6, "stats summed")


func test_merge_refused_without_merge_into_7_2_2() -> void:
	_kit.card("post", [], [], 1, 1)
	_kit.put("post", 0)
	_kit.put("post")
	assert_eq(_rules.play(_player, 0, 0), "That slot is taken", "ordinary units can't")


func test_merge_refused_for_the_wrong_tribe_7_2_2() -> void:
	_ooze()
	_kit.card("post", [], ["vole"], 1, 1)
	_kit.put("post", 0)
	_kit.put("ooze")
	assert_eq(_rules.play(_player, 0, 0), "That slot is taken", "only oozes")


func test_merge_effect_absorbs_the_target_from_a_spell_4_3_5() -> void:
	_ooze()
	var into: RecruitUnit = _kit.put("ooze", 2)
	_kit.put("ooze", 3)
	_rules.give_card(_player, "sample_mingle")
	assert_eq(_rules.play_item(_player, 0, 2), "", "cast")
	assert_eq(into.health, 6, "absorbed the neighbour")
	assert_null(_player.board[3], "gone")


func test_merge_effect_from_a_unit_uses_it_as_absorber_4_3_5() -> void:
	_ooze()
	_kit.card(
		"maw",
		[
			KIT.effect(
				"on_play", {"effect": "merge", "target": {"select": "adjacent", "pick": "first"}}
			)
		],
		[],
		1,
		1
	)
	_kit.put("ooze", 1)
	var maw: RecruitUnit = _kit.put("maw")
	_rules.play(_player, 0, 0)
	assert_eq([maw.attack, maw.health], [3, 4], "absorbed its neighbour")


func test_merge_fires_on_merge_4_3_5() -> void:
	_ooze()
	_kit.card(
		"watcher", [KIT.effect("on_merge", {"effect": "gold", "amount": 1}, {"subject": "any"})]
	)
	_kit.put("watcher", 6)
	_player.gold = 0
	_rules.merge_units(_player, _kit.put("ooze", 0), _kit.put("ooze", 1))
	assert_eq(_player.gold, 1, "the trigger fired")


func test_merged_triples_count_their_copies_4_3_5() -> void:
	_ooze()
	var into: RecruitUnit = _kit.put("ooze", 0)
	into.absorbed_copies["hoglet_mother"] = 2
	var golden_copies: int = into.copies_held()
	assert_eq(golden_copies, 2, "counted")
