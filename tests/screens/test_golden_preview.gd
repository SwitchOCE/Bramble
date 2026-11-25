extends GutTest
## Golden previews through viewport input; presentation must never touch persistent rules state.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const MAIN: PackedScene = preload("res://src/main/main.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")

@warning_ignore_start("unsafe_call_argument")

var _content: GameContent
var _screen: GlassScreen


func before_all() -> void:
	_content = GameContent.load_default()


func after_each() -> void:
	_alt(false)
	await wait_process_frames(2)


func _recruit() -> GameFlow:
	var flow: GameFlow = FlowFixture.live(_content, 3)
	flow.start_round()
	CoreKit.set_shop(flow.session, flow.human(), ["hedge-knight", "widow-thimble"] as Array[String])
	var held: Unit = CoreKit.put(flow.session, flow.human(), "hedge-knight", 0)
	held.stats.perm_attack = 30
	held.stats.renown = 20
	held.grant_effect(_content.registry, &"badger_fury", {"fury": 7})
	flow.human().hand.append(CoreKit.unit(flow.session, "widow-thimble"))
	_screen = SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(flow)
	add_child_autofree(_screen)
	_screen.settle()
	return flow


func _move(node: Control, fraction: Vector2 = Vector2(0.5, 0.5)) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = node.get_global_transform_with_canvas() * (node.size * fraction)
	get_viewport().push_input(motion, true)


func _alt(pressed: bool) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ALT
	key.pressed = pressed
	get_viewport().push_input(key, true)


func _shown() -> GlassCard:
	return _screen._tips.tip.get_node_or_null("Card") as GlassCard


func _words() -> String:
	var words: String = ""
	for node: Node in _screen._tips.tip.get_node("Words").find_children(
		"*", "GlassText", true, false
	):
		words += (node as GlassText).words
	return words


func _assert_golden(id: String) -> void:
	var definition: UnitDef = _content.library.get_card(StringName(id))
	assert_not_null(_shown(), "enlarged golden card")
	if _shown() == null:
		return
	assert_true(_shown().golden)
	assert_eq(_shown().attack, definition.attack * 2)
	assert_eq(_shown().health, definition.health * 2)
	var expected: Dictionary = ViewAdapter.printed_unit(_content, id, true)
	assert_false(str(expected["text"]).contains("{"))


func _assert_in_place(id: String, node: GlassCard) -> void:
	assert_same(_screen._tips.hot, node)
	assert_true(node.golden)
	var definition: UnitDef = _content.library.get_card(StringName(id))
	assert_eq(node.attack, definition.attack * 2)
	assert_eq(node.health, definition.health * 2)


func test_detached_presentation_matches_the_rules_for_every_unit() -> void:
	var session: GameSession = _content.new_session(42)
	var before: String = RecordState.state_hash(session)
	for id: StringName in _content.library.ids():
		var definition: UnitDef = _content.library.get_card(id)
		if definition.is_spell():
			assert_eq(ViewAdapter.printed_unit(_content, String(id), true), {})
			continue
		var unit: Unit = Unit.create(
			definition, -1, true, _content.registry, session.config.stat_max
		)
		var shown: Dictionary = ViewAdapter.printed_unit(_content, String(id), true)
		assert_false(shown.has("uid"))
		assert_eq(shown["text"], unit.view()["text"], String(id))
		assert_eq(shown["attack"], unit.attack(), String(id))
		assert_eq(shown["health"], unit.health(), String(id))
		assert_eq(shown["amounts"], ViewAdapter.amounts(unit.view()), String(id))
	assert_eq(RecordState.state_hash(session), before, "UID, RNG and all rules state")
	assert_eq(ViewAdapter.printed_unit(_content, "hedge-knight", true, 3)["health"], 3)


func test_shop_and_board_switch_without_motion_and_restore_buffs() -> void:
	var flow: GameFlow = _recruit()
	await wait_process_frames(2)
	var before: String = RecordState.state_hash(flow.session)
	var events: Array = flow.session.events.duplicate(true)
	var state: Dictionary = _screen.state.duplicate(true)
	for kind: String in ["shop", "board"]:
		var source: GlassCard = _screen.node_for(kind, 0) as GlassCard
		_move(source)
		assert_not_null(_shown())
		var attack: int = _shown().attack
		var health: int = _shown().health
		_alt(true)
		_assert_golden("hedge-knight")
		assert_eq(source.attack, attack, "the source stays unchanged")
		assert_eq(_screen._tips.details.size(), 3)
		var fury: String = ""
		for pane: GlassBox in _screen._tips.details:
			for node: Node in pane.find_children("*", "GlassText", true, false):
				fury += (node as GlassText).words
		assert_string_contains(fury, "+2 Attack", "golden's own numbered keyword boxes")
		_alt(false)
		assert_false(_shown().golden)
		assert_eq(_shown().attack, attack)
		assert_eq(_shown().health, health)
	assert_eq(RecordState.state_hash(flow.session), before)
	assert_eq(flow.session.events, events)
	assert_eq(_screen.state, state)
	await wait_process_frames(2)


func test_alt_held_before_hover_and_hand_preview_use_own_golden_text() -> void:
	_recruit()
	await wait_process_frames(2)
	_alt(true)
	_move(_screen.node_for("shop", 1))
	_assert_golden("widow-thimble")
	assert_string_contains(_words(), "3 nearest")
	_move(_screen.node_for("hand", 0), Vector2(0.5, 0.1))
	var hand: GlassCard = _screen.node_for("hand", 0) as GlassCard
	_assert_in_place("widow-thimble", hand)
	_assert_golden("widow-thimble")
	assert_same((_screen._tips as RecruitTips).standing, hand)
	var standing_at: Vector2 = hand.position
	_alt(false)
	assert_not_null(_shown(), "normal hand hover keeps its enlarged detail")
	assert_false(_shown().golden)
	assert_eq(_shown().attack, 5)
	assert_eq(_shown().health, 28)
	assert_false(hand.golden)
	assert_eq(hand.attack, 5)
	assert_eq(hand.health, 28)
	assert_eq(hand.position, standing_at)
	assert_false(_words().contains("3 nearest"))
	_alt(true)
	_assert_in_place("widow-thimble", hand)
	await wait_process_frames(2)
	_assert_in_place("widow-thimble", hand)
	assert_eq(hand.position, standing_at)
	_alt(false)
	await wait_process_frames(2)


func test_discover_previews_in_place_and_compost_keeps_its_enlarged_hover() -> void:
	var flow: GameFlow = _recruit()
	_screen.state["discover"] = {
		"prompt": "Choose a unit",
		"options": [ViewAdapter.card_from_id(_content, flow.session, "widow-thimble")]
	}
	_screen.show_state(_screen.state)
	_screen.settle()
	await wait_process_frames(2)
	_move(_screen.node_for("discover", 0))
	assert_null(_shown(), "normal Discover has only its words")
	var option: GlassCard = _screen.node_for("discover", 0) as GlassCard
	var original_at: Vector2 = option.position
	_alt(true)
	_assert_in_place("widow-thimble", option)
	assert_null(_shown(), "Discover previews the card in place")
	assert_eq(option.position, original_at)
	assert_string_contains(_words(), "3 nearest")
	_alt(false)
	assert_null(_shown())
	assert_false(option.golden)
	assert_eq(option.attack, 5)
	assert_false(_words().contains("3 nearest"))
	_screen.hide()
	var panel := CompostPanel.new()
	panel.entries = [ViewAdapter.printed_unit(_content, "hedge-knight")]
	panel.state = {"display": _content.display_table()}
	_screen = panel
	add_child_autofree(panel)
	await wait_process_frames(2)
	_move(panel._targets[0]["node"])
	assert_false(_shown().golden)
	_alt(true)
	_assert_golden("hedge-knight")
	_alt(false)
	assert_false(_shown().golden)
	await wait_process_frames(2)


func test_fight_hover_restores_current_combat_numbers() -> void:
	var card: Dictionary = ViewAdapter.printed_unit(_content, "hedge-knight")
	card["attack"] = 37
	card["health"] = 3
	var fight: FightScreen = (
		(load("res://src/screens/fight/fight_screen.tscn") as PackedScene).instantiate()
	)
	fight.state = {"boards": [[card], []], "display": _content.display_table()}
	_screen = fight
	add_child_autofree(fight)
	await wait_process_frames(2)
	fight.settle()
	_move(fight.targets_of("board")[0]["node"])
	assert_eq(_shown().attack, 37)
	_alt(true)
	_assert_golden("hedge-knight")
	_alt(false)
	assert_eq(_shown().attack, 37)
	assert_eq(_shown().health, 3)
	await wait_process_frames(2)


func test_alt_state_follows_modal_open_and_close() -> void:
	var flow: GameFlow = _recruit()
	flow.human().heap(&"thorn_compost").add(&"hedge-knight", 1)
	_screen.show_state(ViewAdapter.recruit_state(flow))
	_screen.settle()
	await wait_process_frames(2)
	_move(_screen.node_for("shop", 0))
	_alt(true)
	_assert_golden("hedge-knight")
	_screen._open_compost()
	_alt(false)
	_screen._close_compost()
	_move(_screen.node_for("shop", 0))
	assert_false(_shown().golden, "release in the modal reaches the underlying screen")
	_screen._open_compost()
	_alt(true)
	_screen._close_compost()
	_move(_screen.node_for("shop", 0))
	_assert_golden("hedge-knight")
	_alt(false)
	await wait_process_frames(2)


func test_already_golden_and_spell_hovers_keep_their_existing_nodes() -> void:
	var flow: GameFlow = _recruit()
	var golden: Unit = CoreKit.unit(flow.session, "hedge-knight", true)
	golden.stats.perm_attack = 40
	flow.human().place(golden, 1)
	_screen.show_state(ViewAdapter.recruit_state(flow))
	_screen.settle()
	await wait_process_frames(2)
	for source: Control in [_screen.node_for("board", 1), _screen.node_for("spell", 0)]:
		assert_not_null(source)
		_move(source)
		var shown: Control = _screen._tips.tip.get_node("Card")
		var words: String = _words()
		_alt(true)
		assert_same(_screen._tips.tip.get_node("Card"), shown)
		assert_eq(_words(), words)
		_alt(false)
		assert_same(_screen._tips.tip.get_node("Card"), shown)


func test_alt_release_in_pause_panel_restores_normal_hover_after_resume() -> void:
	var main: Control = MAIN.instantiate()
	main.set("ghost_store", FlowFixture.test_store())
	add_child_autofree(main)
	var start: StartScreen = main.get("screen")
	start.play_requested.emit(PackedStringArray())
	var game: GameController = main.get("screen")
	game.request({"type": "buy", "spell": false, "index": 0})
	_screen = game.recruit
	_screen.settle()
	await wait_process_frames(2)
	var before: String = RecordState.state_hash(game.flow.session)
	for kind: String in ["shop", "hand"]:
		var source: GlassCard = _screen.node_for(kind, 1 if kind == "shop" else 0) as GlassCard
		_move(source, Vector2(0.5, 0.1))
		_alt(true)
		assert_true(_shown().golden if kind == "shop" else source.golden)
		_escape()
		assert_true(get_tree().paused)
		assert_not_null(main.get("pause"))
		await wait_process_frames(2)
		if kind == "hand":
			assert_false(source.golden, "pausing restores the source card")
		_alt(false)
		_escape()
		assert_false(get_tree().paused)
		assert_null(main.get("pause"))
		await wait_process_frames(2)
		assert_false(_shown().golden if kind == "shop" else source.golden)
	assert_eq(RecordState.state_hash(game.flow.session), before)


func test_in_place_preview_restores_buffs_on_focus_loss_leave_and_redraw() -> void:
	var flow: GameFlow = _recruit()
	flow.human().hand[0].stats.perm_attack = 7
	_screen.show_state(ViewAdapter.recruit_state(flow))
	_screen.settle()
	await wait_process_frames(2)
	var core_before: String = RecordState.state_hash(flow.session)
	var state_before: Dictionary = _screen.state.duplicate(true)
	var hand: GlassCard = _screen.node_for("hand", 0) as GlassCard
	_move(hand, Vector2(0.5, 0.1))
	_alt(true)
	_assert_in_place("widow-thimble", hand)
	_screen.propagate_notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(hand.golden)
	assert_eq(hand.attack, 5 + 7, "restore the current buffed instance, not the printed normal")
	assert_false(_screen._tips.tip.visible)
	_move(hand, Vector2(0.5, 0.1))
	assert_false(hand.golden)
	_alt(true)
	_assert_in_place("widow-thimble", hand)
	_move(_screen.node_for("shop", 1))
	assert_false(hand.golden, "leaving restores the hand even with Alt still down")
	_move(hand, Vector2(0.5, 0.1))
	_assert_in_place("widow-thimble", hand)
	_screen.show_state(state_before.duplicate(true))
	_screen.settle()
	_alt(false)
	assert_false(hand.golden)
	assert_eq(hand.attack, 5 + 7)
	assert_eq(_screen.state, state_before)
	assert_eq(RecordState.state_hash(flow.session), core_before)


func test_pressing_a_previewed_hand_card_restores_its_drawing_before_carry() -> void:
	_recruit()
	await wait_process_frames(2)
	var hand: GlassCard = _screen.node_for("hand", 0) as GlassCard
	_move(hand, Vector2(0.5, 0.1))
	_alt(true)
	_assert_in_place("widow-thimble", hand)
	var at: Vector2 = hand.get_global_transform_with_canvas() * (hand.size / 2.0)
	var click := InputEventMouseButton.new()
	click.position = at
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	get_viewport().push_input(click, true)
	assert_true((_screen as RecruitScreen).is_holding())
	assert_false(hand.golden)
	assert_eq(hand.attack, 5)
	click.pressed = false
	get_viewport().push_input(click, true)


## Keep dev's 340px words pane over the visible caption and use the fixed reminder overlay.
func test_normal_discover_hover_preserves_dev_pane_and_caption() -> void:
	var flow: GameFlow = _recruit()
	var options: Array = []
	for id: String in ["hedge-knight", "widow-thimble", "nettle-skirmisher"]:
		options.append(ViewAdapter.card_from_id(_content, flow.session, id))
	_screen.state["discover"] = {"prompt": "Choose", "options": options}
	_screen.show_state(_screen.state)
	_screen.settle()
	await wait_process_frames(2)
	var option: GlassCard = _screen.node_for("discover", 1) as GlassCard
	var caption: Control = _screen._front.get_node("DiscoverText_1")
	var caption_at: Vector2 = caption.position
	var caption_size: Vector2 = caption.size
	_move(option)
	var words: GlassBox = _screen._tips.last_box()
	assert_eq(words.size.x, 340.0, "dev's normal hover pane width")
	assert_true(caption.visible, "dev leaves the option caption visible on hover")
	assert_eq(caption.position, caption_at)
	assert_eq(caption.size, caption_size)
	assert_eq(
		_screen._tips.tip.position,
		Vector2(
			option.position.x + option.size.x / 2.0 - 170.0,
			option.position.y + option.size.y + RecruitDiscover.TEXT_DOWN
		)
	)
	assert_eq(_screen._tips.details.size(), 1)
	_assert_left_discover_reminders()
	assert_false(option.golden)
	assert_null(_shown())


func test_discover_alt_uses_normal_hover_layout_on_left_middle_and_right() -> void:
	var flow: GameFlow = _recruit()
	var ids: Array[String] = ["hedge-knight", "widow-thimble", "armsbearer"]
	var options: Array = []
	for id: String in ids:
		options.append(ViewAdapter.card_from_id(_content, flow.session, id))
	_screen.state["discover"] = {"prompt": "Choose a unit", "options": options}
	_screen.show_state(_screen.state)
	_screen.settle()
	await wait_process_frames(2)
	var before: Dictionary = _screen.state.duplicate(true)
	for index: int in ids.size():
		var node: GlassCard = _screen.node_for("discover", index) as GlassCard
		var original_at: Vector2 = node.position
		var original_size: Vector2 = node.size
		var original_marks: Array[Node] = node.find_children("Pill_*", "KeywordMark", false, false)
		_move(node)
		var normal_size: Vector2 = _screen._tips.last_box().size
		var normal_at: Vector2 = _screen._tips.tip.position
		var normal_text: String = _words()
		_alt(true)
		_assert_in_place(ids[index], node)
		assert_null(_shown(), "Discover previews the card in place")
		assert_eq(node.position, original_at)
		assert_eq(node.size, original_size)
		var words: GlassBox = _screen._tips.last_box()
		assert_eq(words.size.x, 340.0, "Alt retains the normal pane width")
		for other: int in ids.size():
			var caption: Control = _screen._front.get_node("DiscoverText_%d" % other)
			assert_true(caption.visible, "Alt never hides a caption")
			if other != index:
				var neighbour: GlassCard = _screen.node_for("discover", other) as GlassCard
				assert_false(neighbour.golden)
		if ids[index] == "widow-thimble":
			assert_string_contains(_words(), "3 nearest")
		_assert_left_discover_reminders()
		_alt(false)
		assert_false(node.golden)
		assert_eq(_screen._tips.last_box().size, normal_size)
		assert_eq(_screen._tips.tip.position, normal_at)
		assert_eq(_words(), normal_text)
		for mark: Node in original_marks:
			assert_same(mark.get_parent(), node, "restore the original keyword marks")
	assert_eq(_screen.state, before)


func test_discover_hover_keeps_current_and_previous_options_above_the_veil() -> void:
	var flow: GameFlow = _recruit()
	var options: Array = []
	for id: String in ["hedge-knight", "widow-thimble", "armsbearer"]:
		options.append(ViewAdapter.card_from_id(_content, flow.session, id))
	_screen.state["discover"] = {"prompt": "Choose", "options": options}
	_screen.show_state(_screen.state)
	_screen.settle()
	await wait_process_frames(2)
	var veil: Control = _screen._front.get_node("DiscoverVeil")
	for golden: bool in [false, true]:
		_alt(golden)
		for index: int in options.size():
			var option: GlassCard = _screen.node_for("discover", index) as GlassCard
			_move(option)
			assert_same(_screen._tips.hot, option)
			assert_gt(option.z_index, veil.z_index, "hovered choice stays above the veil")
			for other: int in options.size():
				var neighbour: Control = _screen.node_for("discover", other)
				assert_gt(
					neighbour.z_index, veil.z_index, "previously hovered choices stay above it"
				)
		_move(_screen._front.get_node("DiscoverPrompt"))
		assert_false(_screen._tips.tip.visible)
		for index: int in options.size():
			assert_gt(_screen.node_for("discover", index).z_index, veil.z_index)


func _assert_left_discover_reminders() -> void:
	var overlay: Control = _screen._front.get_node("KeywordReminders")
	assert_eq(overlay.position, Vector2(12, 82))
	var y: float = 0.0
	for detail: GlassBox in _screen._tips.details:
		assert_same(detail.get_parent(), overlay)
		assert_eq(detail.scale, Vector2.ONE)
		assert_eq(detail.position, Vector2(0.0, y))
		y += detail.size.y + KeywordStyle.GAP


func _escape() -> void:
	for pressed: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.pressed = pressed
		get_viewport().push_input(key, true)


func test_browser_input_with_search_focus_and_golden_toggle_persist_across_filters() -> void:
	var browser := CardBrowser.new()
	_screen = browser
	add_child_autofree(browser)
	browser.set_query("Hedge Knight")
	await wait_process_frames(2)
	assert_eq(browser._targets.size(), 1)
	_move(browser._targets[0]["node"])
	browser.search.grab_focus()
	_alt(true)
	_assert_golden("hedge-knight")
	_alt(false)
	assert_false(_shown().golden)
	var button: Control = browser.find_child("Button_Golden", true, false)
	_move(button)
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = button.get_global_transform_with_canvas() * (button.size / 2.0)
		click.pressed = down
		get_viewport().push_input(click, true)
	assert_true(browser.golden)
	var first: GlassCard = browser._targets[0]["node"]
	assert_true(first.golden)
	assert_eq(first.attack, first.base_attack, "printed golden numbers do not look buffed")
	assert_eq(first.health, first.max_health)
	assert_false(
		CoreUtil.to_bool(browser.catalog.matching(false, "", 0, "Hedge Knight")[0]["golden"])
	)
	browser.set_query("")
	browser.select_tribe("mouse")
	browser.select_tier(1)
	for target: Dictionary in browser._targets:
		var node: GlassCard = target["node"]
		assert_true(node.golden)
	browser.select_kind(true)
	assert_null(browser.find_child("Button_Golden", true, false))
	for target: Dictionary in browser._targets:
		assert_is(target["node"], GlassSpell)
		var card: Dictionary = target["card"]
		assert_false(CoreUtil.to_bool(card.get("golden", false)))
	browser.select_kind(false)
	assert_true(browser.golden)
	assert_not_null(browser.find_child("Button_Golden", true, false))
	browser.toggle_golden()
	for target: Dictionary in browser._targets:
		var node: GlassCard = target["node"]
		assert_false(node.golden)
