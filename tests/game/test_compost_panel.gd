extends GutTest

const MainScene: PackedScene = preload("res://src/main/main.tscn")
const IDS: Array[StringName] = [&"bramble-runner", &"old-stump", &"nettle-sprout"]

@warning_ignore_start("unsafe_call_argument")


func _game(count: int = 3) -> GameController:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(GameContent.load_default(), 4, ["thorn"])
	var heap: CardHeap = game.flow.human().heap(&"thorn_compost")
	for i: int in count:
		var def: UnitDef = game.flow.content.library.get_card(IDS[i % IDS.size()])
		heap.add(def.id, def.tier)
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()
	return game


func _chip(screen: GlassScreen) -> Control:
	for target: Dictionary in screen._targets:
		if target.get("id", "") == "thorn_compost":
			return target["node"]
	return null


func _click_at(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	get_viewport().push_input(motion, true)
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = at
		click.pressed = down
		get_viewport().push_input(click, true)


func _click(node: Control) -> void:
	_click_at(node.get_global_transform_with_canvas() * (node.size / 2.0))


func test_click_opens_and_three_dismissals_preserve_the_core_and_view() -> void:
	var game: GameController = _game()
	var before: String = JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN))
	var state_before: Dictionary = game.recruit.state.duplicate(true)
	var events: Array = game.flow.session.events.duplicate(true)
	var next_uid: int = game.flow.session._next_uid
	for close_by: String in ["chip", "outside", "escape", "close"]:
		_click(_chip(game.recruit))
		assert_not_null(game.recruit._compost, "opened by a real chip click")
		assert_false(get_tree().paused)
		if close_by == "chip":
			_click(_chip(game.recruit))
		elif close_by == "outside":
			_click_at(game.recruit._stage.get_global_transform_with_canvas() * Vector2(1500, 400))
		elif close_by == "escape":
			var key := InputEventKey.new()
			key.keycode = KEY_ESCAPE
			key.pressed = true
			get_viewport().push_input(key, true)
		else:
			# As in the browser tests, exercise the GUI signal under GUT's own overlay.
			var button: Control = game.recruit._compost.find_child("Button_Close", true, false)
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			button.gui_input.emit(click)
		assert_null(game.recruit._compost, close_by)
		assert_eq(JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN)), before)
		assert_eq(game.flow.session.events, events)
		assert_eq(game.flow.session._next_uid, next_uid)
		assert_eq(game.recruit.state, state_before)
		await wait_process_frames(2)


func test_twelve_cards_match_core_newest_first_and_scroll_to_oldest_with_shared_hover() -> void:
	var game: GameController = _game(12)
	var core: Array = game.flow.human().heap(&"thorn_compost").view()
	_click(_chip(game.recruit))
	var panel: CompostPanel = game.recruit._compost
	assert_eq(panel._targets.size(), core.size())
	assert_eq((panel._front.get_node("Count") as GlassText).words, "12 cards")
	for i: int in core.size():
		var card: Dictionary = panel._targets[i]["card"]
		assert_eq(card["id"], core[core.size() - 1 - i]["id"])
		assert_eq(card["tier"], core[core.size() - 1 - i]["tier"])
		assert_is(panel._targets[i]["node"], GlassCard)
		var def: UnitDef = game.flow.content.library.get_card(StringName(str(card["id"])))
		assert_eq(card["attack"], def.attack)
		assert_eq(card["health"], def.health)
	await wait_process_frames(2)
	var oldest: Control = panel._targets.back()["node"]
	var at: Vector2 = (
		panel._stage.get_global_transform().affine_inverse()
		* (oldest.get_global_transform() * (oldest.size / 2.0))
	)
	assert_true(panel._target_at(at, true).is_empty(), "clipped cards do not hover")
	panel.scroll.scroll_vertical = 100000
	await wait_process_frames(2)
	at = (
		panel._stage.get_global_transform().affine_inverse()
		* (oldest.get_global_transform() * (oldest.size / 2.0))
	)
	var hit: Dictionary = panel._target_at(at, true)
	assert_false(hit.is_empty(), "oldest card is reachable")
	var motion := InputEventMouseMotion.new()
	motion.position = panel._stage.get_global_transform_with_canvas() * at
	get_viewport().push_input(motion, true)
	await wait_process_frames(2)
	panel._notification(Control.NOTIFICATION_MOUSE_EXIT)
	panel._process(0.0)
	assert_same(panel._tips.hot, oldest)
	assert_is(panel._tips.tip.get_node("Card"), GlassCard)
	assert_true(panel._tips.tip.visible)
	# The view owns its entries, including nested keyword/amount arrays.
	panel.entries[0]["attack"] = 999
	game.recruit._close_compost()
	assert_eq(game.flow.human().heap(&"thorn_compost").view(), core)
	await wait_process_frames(2)


func test_empty_message_and_no_chip_in_a_game_without_briars() -> void:
	var game: GameController = _game(0)
	var chip: Control = _chip(game.recruit)
	assert_eq(chip.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND)
	chip.mouse_entered.emit()
	assert_ne(chip.modulate, Color.WHITE, "hover changes the chip")
	chip.mouse_exited.emit()
	assert_eq(chip.modulate, Color.WHITE)
	_click(chip)
	assert_eq(game.recruit._compost._targets.size(), 0)
	assert_eq((game.recruit._compost._front.get_node("Count") as GlassText).words, "0 cards")
	var words: Array[String] = []
	for child: Node in game.recruit._compost._front.get_children():
		if child is GlassText:
			words.append((child as GlassText).words)
	assert_has(words, "Your Compost is empty.")
	game.recruit._close_compost()
	var other := GameController.new()
	add_child_autofree(other)
	other.start(GameContent.load_default(), 4, ["mouse"])
	assert_null(_chip(other.recruit))
	await wait_process_frames(2)


func test_escape_consumed_once_before_main_pause_shortcut() -> void:
	var main: Control = MainScene.instantiate()
	add_child_autofree(main)
	var start: StartScreen = main.get("screen")
	start.play_requested.emit(PackedStringArray(["thorn"]))
	var game: GameController = main.get("screen")
	await wait_process_frames(2)
	assert_false(game.flow.human().heaps.has(&"thorn_compost"), "core heap is still lazy")
	_click(_chip(game.recruit))
	assert_not_null(game.recruit._compost)
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	get_viewport().push_input(key, true)
	assert_null(game.recruit._compost)
	assert_null(main.get("pause"), "closing Escape never opens Pause")
	key.echo = true
	get_viewport().push_input(key, true)
	assert_null(main.get("pause"))
	assert_false(game.flow.human().heaps.has(&"thorn_compost"), "opening never creates a heap")
	_click(_chip(game.recruit))
	_click(main.get("cog"))
	assert_null(game.recruit._compost, "clicking outside on the cog closes the panel")
	assert_null(main.get("pause"), "that click cannot also open Pause")
	await wait_process_frames(2)


func test_fight_keeps_playing_and_panel_refreshes_when_compost_changes() -> void:
	var game: GameController = _game()
	game.request({"type": "buy", "spell": false, "index": 0})
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	game.request({"type": "end_turn"})
	assert_eq(game.phase, GameController.Phase.FIGHT)
	await wait_process_frames(2)
	game._fight_age = GameController.RESULT_GUARD
	var step_before: int = game.fight._step
	_click(_chip(game.fight))
	assert_not_null(game.fight._compost)
	assert_eq(game.fight._step, step_before, "chip click did not skip")
	assert_false(get_tree().paused)
	_click_at(game.fight._stage.get_global_transform_with_canvas() * Vector2(1100, 600))
	assert_eq(game.fight._step, step_before, "panel clicks did not skip")
	game.fight._process(game.fight._wait + 0.01)
	assert_gt(game.fight._step, step_before, "replay progresses with panel open")
	var replay: FightReplay = game.fight._replay
	var catalog: Dictionary = ViewAdapter.catalog(game.flow.content)
	var before: Dictionary = game.fight.state.duplicate(true)
	var changed: bool = replay._set_player_number(
		{
			"type": "heap_add",
			"heap": "thorn_compost",
			"side": before["you_side"],
			"id": "old-stump",
			"size": 4
		}
	)
	assert_true(changed)
	var chips: Array = replay._base["counters"]
	before["counters"] = chips.duplicate(true)
	game.fight.show_state(before)
	var panel: CompostPanel = game.fight._compost
	assert_eq(panel._targets.size(), 4)
	assert_eq(panel._targets[0]["card"]["id"], "old-stump")
	assert_eq(panel._targets[0]["card"]["attack"], catalog["old-stump"]["attack"])
	var chip: Dictionary = before["counters"][0]
	chip["entries"] = []
	chip["value"] = 0
	game.fight.show_state(before)
	assert_null(panel.scroll, "an emptied Compost replaces its old scroll")
	var stump: Dictionary = catalog["old-stump"]
	chip["entries"] = [stump.duplicate(true)]
	chip["value"] = 1
	game.fight.show_state(before)
	assert_eq(panel._targets.size(), 1, "it can gain cards again while open")
	_click(_chip(game.fight))
	assert_null(game.fight._compost)
	assert_eq(game.phase, GameController.Phase.FIGHT)
	await wait_process_frames(2)
