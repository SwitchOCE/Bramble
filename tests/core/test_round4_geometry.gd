extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Preview := preload("res://src/core/recruit_preview.gd")
const View := preload("res://src/ui/screens/recruit_view.gd")

var _library: UnitLibrary = TestLibraries.current()


func _rules() -> RecruitRules:
	var config: GameConfig = GameConfig.full_game()
	return RecruitRules.create(_library, config, UnitPool.create(_library, config))


func _player(rules: RecruitRules) -> PlayerState:
	var player := PlayerState.new()
	rules.setup_player(player)
	player.gold = 20
	player.board[1] = RecruitUnit.make(_library.get_unit("pill_bug"), 4)
	player.board[4] = RecruitUnit.make(_library.get_unit("hob_in_the_hearth"), 1)
	player.board[5] = RecruitUnit.make(_library.get_unit("pill_bug"), 2)
	player.items.append(HandItem.make(_library.get_card("pinch_of_dust"), 3))
	rules.board_changed(player)
	return player


func test_behind_f2_keeps_geometry_without_a_standing_highlight_note() -> void:
	var card: Dictionary = {"text": "Units behind this gain +1/+1."}
	assert_eq(View.related_slots(card, 1), [4, 5] as Array[int])
	# Declutter §2.2 replaces the standing Highlighted prose with a reader reach pulse.
	assert_eq(View.geometry_note(card, 1), "", "reach remains geometry, not a reminder caption")
	assert_eq(View.related_slots(card, 4), [] as Array[int], "nothing behind a back slot")


func test_beside_and_next_to_light_different_slots() -> void:
	var beside: Dictionary = {"text": "Your units beside this have Bitter 1."}
	assert_eq(View.related_slots(beside, 1), [0, 2] as Array[int], "beside: same row only")
	var next_to: Dictionary = {"text": "Units next to this have Pounce."}
	assert_eq(View.related_slots(next_to, 1), [0, 2, 4, 5] as Array[int], "next to: and behind")


func test_shy_preview_predicts_walkout_without_consuming_any_state() -> void:
	var rules: RecruitRules = _rules()
	var player: PlayerState = _player(rules)
	var before: String = JSON.stringify(player.board_specs())
	var pool_before: String = JSON.stringify(rules.pool._copies)
	var random_before: int = player.effect_rng.state
	var iid_before: int = rules._next_iid
	var warning: String = Preview.shy_warning(player, rules, "play_item", 0, 4)
	assert_true("Hob-in-the-Hearth" in warning)
	assert_eq(JSON.stringify(player.board_specs()), before)
	assert_eq(JSON.stringify(rules.pool._copies), pool_before)
	assert_eq(player.effect_rng.state, random_before)
	assert_eq(rules._next_iid, iid_before)
	assert_eq(player.items.size(), 1)
	assert_eq(player.gold, 20)
	assert_eq(rules.play_item(player, 0, 4), "")
	assert_null(player.board[4], "the real action matches its preview")
	assert_not_null(player.board[5], "ordinary units stay")


func test_shy_moves_never_warn_because_rings_are_ignored() -> void:
	var rules: RecruitRules = _rules()
	var player: PlayerState = _player(rules)
	BoardUpkeep.add_ring(player, 6, {"attack": 1, "health": 1})
	assert_eq(Preview.shy_warning(player, rules, "move", 4, 6), "")
	assert_eq(Preview.shy_warning(player, rules, "move", 4, 0), "")
	assert_not_null(player.board[4])


func test_sergeant_next_acorn_uses_actual_smallest_item_and_golden_multiplier() -> void:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("hero_choice", false)
	var library: UnitLibrary = LegacyWave1.with_hedgerow(_library)
	var session: GameSession = GameSession.create(202, library, config)
	var player: PlayerState = session._players[0]
	player.board[1] = RecruitUnit.make(library.get_unit("sergeant_at_conkers"), 600, true)
	player.items.append(HandItem.make(library.get_card("stash"), 601))
	player.items.append(HandItem.make(library.get_card("acorn"), 602))
	var view: Dictionary = session.get_state()["board"][1]
	assert_eq(view["next_acorn"], "Next Acorn: 1 gold → 6 damage")
	assert_eq(View.tile_slip(view), "1g → 6", "compact ammunition label fits the tile")
	assert_true("earlier Sergeants throw first" in str(view["text"]))


func test_shy_action_commits_on_one_press_without_a_warning_step() -> void:
	const CorePort := preload("res://src/ui/adapter/core_port.gd")
	const Actions := preload("res://src/ui/screens/recruit_actions.gd")
	var config: GameConfig = GameConfig.full_game()
	config.set_value("hero_choice", false)
	var port: CorePort = CorePort.new()
	port.setup(config)
	port.new_game(202)
	var player: PlayerState = port.session._players[0]
	var staged: PlayerState = _player(port.session._rules)
	player.board = staged.board
	player.items = staged.items
	var actions: Actions = Actions.new()
	add_child_autofree(actions)
	actions.port = port
	# Declutter §2.3 makes Shy one press; departure feedback follows the committed action.
	assert_eq(actions._safe_item(0, 4), "")
	assert_null(player.board[4], "the aimed action commits its Shy departure immediately")
	assert_eq(player.items.size(), 0, "the spell is consumed by the same action")
