extends GutTest
## The UI on the core's milestone B: every library unit is built, the dev panel's actions work,
## a triple (from dev spawns or a real shop buy) shows its golden and then its Triple Reward, and
## real fights built around the library's mechanics play back with a real log line (not the
## "(type)" fallback) for every event.

const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const RecruitActionMotion := preload("res://src/ui/screens/recruit_action_motion.gd")
const DevPanel := preload("res://src/ui/widgets/dev_panel.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const Data := preload("res://src/ui/view_data.gd")

## Boards that, over a few seeds, fire every one of the 16 library units' mechanics.
const FIGHTS: Array = [
	[["belladonna_sprite", "bitter_toad"], ["old_badger", "stoat_captain"]],
	[["hoglet_mother", "hoglet", "sett_warden"], ["stoat_captain", "old_badger"]],
	[["garden_snail", "mudwallow_toad", "fox_notary"], ["stoat_captain", "old_badger"]],
	[
		["field_vole", "ermine_duellist", null, null, "weasel_second", "drumming_woodpecker"],
		["sett_warden", "old_badger", "hoglet"]
	],
	[["worker_bee", "worker_bee", "worker_bee", "hedgehog_twin"], ["old_badger", "stoat_captain"]],
	[
		["hazel_dormouse", "fox_cub", null, null, "marmot_lookout"],
		["old_badger", "stoat_captain", "field_vole"]
	],
	[
		["still_water_heron", "hedgehog_twin", "hedgehog_twin"],
		["fox_cub", "marmot_lookout", "hazel_dormouse"]
	],
]
const SEEDS: int = 6


func _core() -> CorePort:
	var port: CorePort = CorePort.new()
	port.setup(GameConfig.defaults())
	if port.config.card_set().is_empty():
		port.library = LegacyPrototypes.library()
	port.manual_choices = false
	return port


func _board(ids: Array) -> Array:
	var out: Array = [null, null, null, null, null, null, null]
	for i: int in ids.size():
		if ids[i] != null:
			out[i] = {"def_id": str(ids[i]), "golden": false}
	return out


func _count(units: Array, def_id: String, golden: bool) -> int:
	var n: int = 0
	for entry: Variant in units:
		if entry is Dictionary:
			var view: Dictionary = entry
			if Data.s(view, "def_id") == def_id and Data.b(view, "golden", false) == golden:
				n += 1
	return n


func test_every_library_unit_is_built() -> void:
	var port: CorePort = _core()
	assert_eq(port.unbuilt_units(), PackedStringArray(), "no Not built badges")


func test_dev_panel_actions_change_the_game() -> void:
	var port: CorePort = _core()
	port.new_game(4)
	var panel: DevPanel = DevPanel.new()
	add_child_autofree(panel)
	panel.setup(port)
	var result: Label = panel.get("_result")
	var gold: int = Data.i(port.get_state(), "gold")
	panel.call("_on_add_gold")
	assert_eq(result.text, "Add gold: done")
	assert_gt(Data.i(port.get_state(), "gold"), gold, "gold went up")
	var tier_box: SpinBox = panel.get("_tier")
	tier_box.value = 4
	panel.call("_on_set_tier")
	assert_eq(Data.i(port.get_state(), "tier"), 4, "tier set")
	var options: OptionButton = panel.get("_units")
	options.select(0)
	panel.call("_on_spawn")
	assert_eq(result.text, "Spawn: done")
	assert_eq(Data.a(port.get_state(), "hand").size(), 1, "spawned into hand")
	panel.call("_on_skip")
	assert_eq(result.text, "Skip turn: done")
	assert_eq(Data.i(port.get_state(), "round"), 2, "the turn was skipped")


func test_a_triple_through_the_ui_shows_the_golden_then_the_reward() -> void:
	var port: CorePort = _core()
	port.new_game(8)
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	var panel: DevPanel = screen.get("_dev")
	var ids: PackedStringArray = panel.get("_ids")
	var options: OptionButton = panel.get("_units")
	options.select(ids.find("field_vole"))
	for i: int in 3:
		panel.call("_on_spawn")
	var hand: Array = Data.a(port.get_state(), "hand")
	assert_eq(_count(hand, "field_vole", true), 1, "one golden Field Vole")
	assert_eq(_count(hand, "field_vole", false), 0, "the three copies are gone")
	var toast: Label = screen.get("_toast")
	assert_eq(toast.text, "", "the golden result and gathering motion convey the triple")
	var motion: RecruitActionMotion = screen.get("_action_motion")
	assert_eq(motion.kind, "triple")
	assert_true(motion.active, "the copies gather into the golden")
	assert_gt(motion.tracks.size(), 0)
	var golden_index: int = -1
	for i: int in hand.size():
		if Data.b(Data.entry(hand, i), "golden", false):
			golden_index = i
	screen.call("_drop", {"zone": "hand", "index": golden_index}, "board", 0)
	var board: Array = Data.a(port.get_state(), "board")
	assert_eq(_count(board, "field_vole", true), 1, "the golden is on the board")
	var after: Array = Data.a(port.get_state(), "hand")
	assert_eq(after.size(), 1, "the Triple Reward arrived in hand")
	assert_eq(Data.s(Data.entry(after, 0), "origin"), "created")
	assert_eq(toast.text, "", "the created reward arrives without a prose toast")
	assert_false(Data.s(Data.entry(after, 0), "name").is_empty(), "the reward is identifiable")


func test_real_fights_for_every_mechanic_play_back_with_a_line_per_event() -> void:
	var port: CorePort = _core()
	var seen: Dictionary = {}
	for fight_seed: int in range(1, SEEDS + 1):
		for fight: Variant in FIGHTS:
			var sides: Array = fight
			var own: Array = sides[0]
			var enemy: Array = sides[1]
			var result: Dictionary = port.sandbox_fight([_board(own), _board(enemy)], fight_seed)
			assert_false(result.has("error"), Data.s(result, "error"))
			var model: CombatModel = CombatModel.new()
			var log_lines: CombatLog = CombatLog.new()
			for entry: Variant in Data.a(result, "events"):
				var event: Dictionary = entry
				var type: String = Data.s(event, "type")
				var line: String = log_lines.describe(event, model)
				if line.is_empty() or line == "(%s)" % type:
					fail_test("no log line for %s" % JSON.stringify(event))
				model.apply(event)
				seen[type] = true
				if type == "trigger":
					seen["trigger/" + Data.s(event, "mechanic")] = true
			assert_true(model.finished, "fight %s seed %d replays to the end" % [own, fight_seed])
	for key: String in [
		"health_loss",
		"status",
		"summon",
		"stats",
		"slot_mark",
		"whistle",
		"skip",
		"trigger/death_summon",
		"trigger/swarm",
		"trigger/grant_first_bite_in_front",
	]:
		assert_true(seen.has(key), "fights produced %s" % key)


func test_combat_screen_plays_a_real_mechanic_fight_to_the_end() -> void:
	var port: CorePort = _core()
	var sides: Array = FIGHTS[0]
	var own: Array = sides[0]
	var enemy: Array = sides[1]
	var result: Dictionary = port.sandbox_fight([_board(own), _board(enemy)], 2)
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	screen.setup(result, ["Your board", "Enemy board"], 0, "Sandbox fight")
	screen.skip_to_end()
	assert_true(screen.is_showing_result())


func test_whistle_only_boards_end_with_no_attacks_and_say_so() -> void:
	var port: CorePort = _core()
	var result: Dictionary = port.sandbox_fight(
		[_board(["marmot_lookout"]), _board(["marmot_lookout"])], 1
	)
	var events: Array = Data.a(result, "events")
	var end: Dictionary = Data.entry(events, events.size() - 1)
	assert_eq(Data.s(end, "reason"), "no_attacks")
	var model: CombatModel = CombatModel.new()
	var log_lines: CombatLog = CombatLog.new()
	var last_line: String = ""
	for entry: Variant in events:
		var event: Dictionary = entry
		last_line = log_lines.describe(event, model)
		model.apply(event)
	assert_string_contains(last_line, "No unit left can attack")


func test_a_real_shop_buy_that_makes_a_triple_shows_gathering_motion() -> void:
	var port: CorePort = _core()
	port.new_game(8)
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	var shop: Array = Data.a(port.get_state(), "shop")
	var def_id: String = Data.s(Data.entry(shop, 0), "def_id")
	assert_eq(port.dev_spawn_to_hand(def_id), "")
	assert_eq(port.dev_spawn_to_hand(def_id), "")
	screen.render()
	screen.call("_on_tapped", "shop", 0)
	var detail: CardDetail = screen.get("_detail")
	var buy: Button = detail.actions.get_child(0) as Button
	assert_string_starts_with(buy.text, "Buy")
	buy.pressed.emit()
	var hand: Array = Data.a(port.get_state(), "hand")
	assert_eq(_count(hand, def_id, true), 1, "the buy combined a golden")
	var toast: Label = screen.get("_toast")
	assert_eq(toast.text, "")
	var motion: RecruitActionMotion = screen.get("_action_motion")
	assert_eq(motion.kind, "triple")
	assert_true(motion.active, "buying the third copy animates the golden result")
	assert_gt(motion.tracks.size(), 0)


func test_a_golden_dev_spawn_is_not_announced_as_a_triple() -> void:
	var port: CorePort = _core()
	port.new_game(8)
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	var panel: DevPanel = screen.get("_dev")
	var ids: PackedStringArray = panel.get("_ids")
	var options: OptionButton = panel.get("_units")
	options.select(ids.find("field_vole"))
	var golden: CheckBox = panel.get("_golden")
	golden.button_pressed = true
	panel.call("_on_spawn")
	assert_eq(_count(Data.a(port.get_state(), "hand"), "field_vole", true), 1)
	var toast: Label = screen.get("_toast")
	assert_false(toast.text.begins_with("Triple!"), "no triple happened")


func test_game_over_shows_the_board_of_the_last_fight() -> void:
	var config: GameConfig = GameConfig.defaults()
	config.set_value("human_bot", "greedy")
	var port: CorePort = CorePort.new()
	port.setup(config)
	if port.config.card_set().is_empty():
		port.library = LegacyPrototypes.library()
	port.new_game(20261104)
	var turns: int = 0
	while not (port.is_over() or port.get_state().get("placement") != null) and turns < 60:
		port.end_turn()
		turns += 1
	var screen: GameOverScreen = GameOverScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	var board_view: BoardView = screen.get("_board")
	var shown: int = 0
	for card: Variant in board_view.cards:
		if card != null:
			shown += 1
	assert_gt(shown, 0, "the board from the last fight, not the cleared one")


func test_log_explains_each_keyword_once_per_fight() -> void:
	var port: CorePort = _core()
	var result: Dictionary = port.sandbox_fight(
		[_board(["mudwallow_toad", "mudwallow_toad"]), _board(["old_badger", "stoat_captain"])], 3
	)
	var note: String = KeywordRules.text("Pin")
	var model: CombatModel = CombatModel.new()
	var log_lines: CombatLog = CombatLog.new()
	var explained: int = 0
	for pass_index: int in 2:
		explained = 0
		for entry: Variant in Data.a(result, "events"):
			var event: Dictionary = entry
			if log_lines.describe(event, model).contains(note):
				explained += 1
			model.apply(event)
		assert_eq(
			explained, 1, "Pin's note once (pass %d: a replay explains it again)" % pass_index
		)
