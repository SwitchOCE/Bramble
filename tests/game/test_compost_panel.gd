extends GutTest

const MainScene: PackedScene = preload("res://src/main/main.tscn")
const IDS: Array[StringName] = [&"bramble-runner", &"old-stump", &"nettle-sprout"]

@warning_ignore_start("unsafe_call_argument")


func _game(count: int = 3) -> GameController:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(FlowFixture.live(GameContent.load_default(), 4, ["thorn"]))
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


# GUT's full-viewport test UI intercepts GUI delivery. World targets use viewport input above.
func _activate(node: Control) -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	node.gui_input.emit(release)


func test_click_opens_and_dismissals_preserve_the_core_and_view() -> void:
	var game: GameController = _game()
	var before: String = JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN))
	var state_before: Dictionary = game.recruit.state.duplicate(true)
	var events: Array = game.flow.session.events.duplicate(true)
	var next_uid: int = game.flow.session._next_uid
	for close_by: String in ["chip", "outside", "escape", "close"]:
		_click(_chip(game.recruit))
		assert_not_null(game.recruit._auras, "opened by a real chip click")
		assert_false(get_tree().paused)
		if close_by == "chip":
			_click(_chip(game.recruit))
		elif close_by == "outside":
			_click_at(game.recruit._stage.get_global_transform_with_canvas() * Vector2(1250, 400))
		elif close_by == "escape":
			var key := InputEventKey.new()
			key.keycode = KEY_ESCAPE
			key.pressed = true
			get_viewport().push_input(key, true)
		else:
			var button: Control = game.recruit._auras.get_node("Surface/Close")
			_activate(button)
		assert_null(game.recruit._auras, close_by)
		assert_eq(JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN)), before)
		assert_eq(game.flow.session.events, events)
		assert_eq(game.flow.session._next_uid, next_uid)
		assert_eq(game.recruit.state, state_before)
		await wait_process_frames(2)


func test_heap_groups_copies_at_the_newest_copy_and_keeps_golden_separate() -> void:
	var game: GameController = _game(12)
	var core: Array = game.flow.human().heap(&"thorn_compost").view()
	var state: Dictionary = ViewAdapter.recruit_state(game.flow)
	var heap: Dictionary = state["counters"][0]
	var golden: Dictionary = ViewAdapter.printed_unit(game.flow.content, "bramble-runner", true)
	var entries: Array = heap["entries"]
	entries.insert(1, golden)
	heap["value"] = 13
	game.recruit.show_state(state)
	game.recruit.settle()
	_click(_chip(game.recruit))
	var panel: RecruitAuraPanel = game.recruit._auras
	assert_eq((panel.get_node("Surface/Count") as GlassText).words, "13")
	assert_eq(panel.groups.size(), 4)
	for i: int in IDS.size():
		var card: Dictionary = panel.groups[i]["card"]
		var def: UnitDef = game.flow.content.library.get_card(IDS[IDS.size() - 1 - i])
		assert_eq(card["id"], str(def.id))
		assert_eq(card["tier"], def.tier)
		assert_eq(card["attack"], def.attack)
		assert_eq(card["health"], def.health)
		assert_eq(panel.groups[i]["count"], 4)
	assert_eq(panel.groups.back(), {"card": golden, "count": 1})
	assert_not_null(panel.find_child("HeapCard_3", true, false), "fourth card drawn")
	assert_eq(game.flow.human().heap(&"thorn_compost").view(), core)
	assert_eq(game.recruit.state, state)
	game.recruit._close_auras()
	await wait_process_frames(2)


func test_empty_message_and_no_chip_in_a_game_without_briars() -> void:
	var game: GameController = _game(0)
	assert_true(game.flow.human().heaps.has(&"thorn_compost"), "an existing empty core heap")
	var chip: Control = _chip(game.recruit)
	assert_eq(chip.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND)
	chip.mouse_entered.emit()
	assert_ne(chip.modulate, Color.WHITE, "hover changes the chip")
	chip.mouse_exited.emit()
	assert_eq(chip.modulate, Color.WHITE)
	_click(chip)
	assert_eq(game.recruit._auras.groups.size(), 0)
	assert_eq((game.recruit._auras.get_node("Surface/Count") as GlassText).words, "0")
	assert_eq((game.recruit._auras.get_node("Surface/Empty") as GlassText).words, "Empty")
	game.recruit._close_auras()
	var other := GameController.new()
	add_child_autofree(other)
	other.start(FlowFixture.live(GameContent.load_default(), 4, ["mouse"]))
	assert_null(_chip(other.recruit))
	await wait_process_frames(2)


func test_escape_consumed_once_before_main_pause_shortcut() -> void:
	var main: Control = MainScene.instantiate()
	main.set("ghost_store", FlowFixture.test_store())
	add_child_autofree(main)
	var start: StartScreen = main.get("screen")
	start.play_requested.emit(PackedStringArray())
	var game: GameController = main.get("screen")
	await wait_process_frames(2)
	assert_false(game.flow.human().heaps.has(&"thorn_compost"), "core has not created a heap yet")
	assert_null(_chip(game.recruit), "a fresh Briars game has no Compost chip")
	var heap: CardHeap = game.flow.human().heap(&"thorn_compost")
	heap.add(&"bramble-runner", 1)
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()
	var before: String = JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN))
	_click(_chip(game.recruit))
	assert_not_null(game.recruit._auras)
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	get_viewport().push_input(key, true)
	assert_null(game.recruit._auras)
	assert_null(main.get("pause"), "closing Escape never opens Pause")
	key.echo = true
	get_viewport().push_input(key, true)
	assert_null(main.get("pause"))
	assert_eq(JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN)), before, "core unchanged")
	_click(_chip(game.recruit))
	_click(main.get("cog"))
	assert_null(game.recruit._auras, "clicking outside on the cog closes the panel")
	assert_null(main.get("pause"), "that click cannot also open Pause")
	assert_eq(JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN)), before, "core unchanged")
	await wait_process_frames(2)


func test_auras_show_player_and_slot_effects_and_navigate_to_heap_and_back() -> void:
	var game: GameController = _game()
	var player: PlayerState = game.flow.human()
	player.counters[&"locust_tide"] = 3
	player.counters[&"locust_hopper_bonus"] = 2
	player.counters[&"locust_swarm"] = 99
	player.slots[2].keywords.append(&"pigeon_guard_post")
	player.slots[5].renown = 4
	game.request({"type": "buy", "spell": false, "index": 0})
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	player.board[0].counters[&"locust_tide"] = 7
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()

	var stage: Control = game.recruit._stage
	var board: Control = game.recruit.node_for("board", 0)
	var before: Color = board.modulate
	var counters: RecruitCounters = game.recruit._counters as RecruitCounters
	assert_eq(counters.rows.size(), 5)
	assert_eq(counters.rows[0]["id"], "thorn_compost")
	assert_eq(counters.rows[1]["id"], "locust_tide")
	assert_eq(counters.rows[1]["effect"], "Locusts +3 Attack")
	assert_eq(counters.rows[2]["id"], "locust_hopper_bonus")
	assert_eq(counters.rows[3]["name"], "Guard post")
	assert_eq(counters.rows[3]["slot"], 2)
	assert_eq(counters.rows[4]["name"], "Renown")
	assert_eq(counters.rows[4]["slot"], 5)

	assert_null(game.recruit._front.get_node_or_null("AurasPlate"), "only three player counters")
	var tide: Control = game.recruit._front.get_node("Chip_1")
	_click(tide)
	var panel: RecruitAuraPanel = game.recruit._auras
	assert_eq((panel.get_node("Surface/Title") as GlassText).words, "Auras")
	assert_eq((panel.get_node("Surface/Count") as GlassText).words, "5")
	assert_eq(panel.find_children("*", "ColorRect", true, false).size(), 0)
	assert_eq(board.modulate, before, "board card remains undimmed")
	assert_eq(stage.modulate, Color.WHITE)
	assert_false(get_tree().paused)
	await wait_process_frames(2)
	var heap_row: Control = panel.find_child("Row_thorn_compost", true, false)
	_activate(heap_row)
	assert_same(game.recruit._auras, panel)
	assert_eq(panel.heap_id, "thorn_compost")
	assert_eq((panel.get_node("Surface/Title") as GlassText).words, "Compost")
	_activate(panel.get_node("Surface/Back"))
	assert_eq(panel.heap_id, "")
	assert_eq((panel.get_node("Surface/Title") as GlassText).words, "Auras")
	_click(tide)
	assert_null(game.recruit._auras)
	await wait_process_frames(2)


func test_round_medallion_opens_the_list_with_its_row_marked() -> void:
	var game: GameController = _game()
	game.flow.human().counters[&"locust_tide"] = 3
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()
	var chip: Control = game.recruit._front.get_node("Chip_1")
	_click(chip)
	var panel: RecruitAuraPanel = game.recruit._auras
	assert_eq((panel.get_node("Surface/Title") as GlassText).words, "Auras")
	var row: GlassBox = panel.find_child("Row_locust_tide", true, false)
	assert_gt(row.border_width, 0.0)
	_click(chip)
	assert_null(game.recruit._auras)
	await wait_process_frames(2)


func test_a_slot_medallion_opens_auras_when_there_is_no_player_counter() -> void:
	var game: GameController = _game(0)
	var player: PlayerState = game.flow.human()
	player.heaps.erase(&"thorn_compost")
	player.slots[5].renown = 2
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()
	assert_null(game.recruit._front.get_node_or_null("AurasPlate"))
	_click(game.recruit._front.get_node("Chip_0"))
	var panel: RecruitAuraPanel = game.recruit._auras
	assert_eq(panel.rows.size(), 1)
	assert_eq(panel.rows[0]["id"], "renown:5")
	assert_not_null(panel.find_child("Slot_5", true, false))
	game.recruit._close_auras()
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
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	get_viewport().push_input(space, true)
	assert_eq(game.fight._step, step_before, "Space did not skip through the panel")
	_click(game.fight._skip_button)
	assert_null(game.fight._compost, "clicking outside dismisses Compost")
	assert_eq(game.fight._step, step_before, "the dismissing click did not also skip")
	_click(_chip(game.fight))
	game.fight._process(game.fight._wait + 0.01)
	assert_gt(game.fight._step, step_before, "replay progresses with panel open")
	var replay: FightReplay = game.fight._replay
	var catalog: Dictionary = ViewAdapter.catalog(game.flow.content)
	var before: Dictionary = game.fight.state.duplicate(true)
	var addition: Dictionary = {
		"type": "heap_add",
		"heap": "thorn_compost",
		"side": before["you_side"],
		"id": "old-stump",
		"size": 4
	}
	# Give the injected log event the same card data as events the controller replays.
	ViewAdapter.add_fight_cards(game.flow.content, [addition], replay._catalog)
	var changed: bool = replay._set_player_number(addition)
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
