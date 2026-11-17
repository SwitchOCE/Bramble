extends GutTest

const MainScene: PackedScene = preload("res://src/main/main.tscn")

@warning_ignore_start("unsafe_call_argument")


func test_kind_switch_resets_tribe_and_hides_tribe_controls() -> void:
	var geometry_before: Dictionary = GlassPieces.recruit_geom().duplicate(true)
	var browser := CardBrowser.new()
	add_child_autofree(browser)
	assert_eq(browser._targets.size(), browser.catalog.matching().size())
	browser.select_tribe("mouse")
	browser.select_tier(5)
	assert_eq(browser._targets.size(), browser.catalog.matching(false, "mouse", 5).size())
	browser.select_kind(true)
	assert_eq(browser.tribe, "")
	assert_eq(browser.tier, 5, "tier keeps its meaning across kind changes")
	assert_null(browser.find_child("Button_All_tribes", true, false))
	browser.select_tier(0)
	assert_eq(browser._targets.size(), browser.catalog.matching(true).size())
	browser.select_kind(false)
	assert_not_null(browser.find_child("Button_All_tribes", true, false))
	browser.set_query("not-a-real-card")
	assert_eq(browser._targets.size(), 0)
	assert_eq((browser._front.get_node("Count") as GlassText).words, "0 units")
	assert_eq(
		GlassPieces.recruit_geom(), geometry_before, "browser cannot alter shared recruit geometry"
	)
	await wait_process_frames(2)


func test_scroll_reaches_tokens_and_hover_uses_the_shop_component() -> void:
	var browser := CardBrowser.new()
	add_child_autofree(browser)
	await wait_process_frames(2)
	assert_eq(browser._frame.position, Vector2.ZERO, "the browser fills its stage after layout")
	assert_is(browser._tips, GlassTips, "same component the shop delegates its card hover to")
	var target: Dictionary = browser._targets.back()
	assert_true(target["card"]["token"])
	var node: Control = target["node"]
	var at: Vector2 = (
		browser._stage.get_global_transform().affine_inverse()
		* node.get_global_transform()
		* (node.size / 2.0)
	)
	assert_true(browser._target_at(at, true).is_empty(), "offscreen cards have no hover")
	browser.scroll.scroll_vertical = 100000
	await wait_process_frames(2)
	at = (
		browser._stage.get_global_transform().affine_inverse()
		* node.get_global_transform()
		* (node.size / 2.0)
	)
	var hit: Dictionary = browser._target_at(at, true)
	assert_false(hit.is_empty(), "the last token can be reached by scrolling")
	browser._tips.show(hit, at)
	assert_true(browser._tips.tip.visible)
	assert_same(browser._tips.hot, node)
	assert_true(browser._tips.tip.get_node("Card") is GlassCard)
	browser.select_kind(true)
	await wait_process_frames(2)
	for spell: Dictionary in browser._targets:
		browser._tips.show(spell, Vector2(500, 300))
		assert_true(browser._tips.tip.get_node("Card") is GlassSpell)
		assert_true(browser._tips.tip.visible)
	await wait_process_frames(2)


func test_start_entry_returns_to_the_same_start_screen() -> void:
	var main: Control = MainScene.instantiate()
	add_child_autofree(main)
	var start: StartScreen = main.get("screen")
	var entry: Control = start.find_child("Button_Cards", true, false)
	assert_not_null(entry)
	_click(entry)
	var browser: CardBrowser = main.get("browser")
	assert_not_null(browser)
	assert_false(browser.in_game)
	assert_true(get_tree().paused)
	browser.close_requested.emit()
	assert_false(get_tree().paused)
	assert_same(main.get("screen"), start)
	assert_null(main.get("browser"))
	await wait_process_frames(2)


func test_recruit_entry_pauses_and_close_preserves_the_live_game_exactly() -> void:
	var main: Control = MainScene.instantiate()
	add_child_autofree(main)
	var start: StartScreen = main.get("screen")
	start.play_requested.emit(PackedStringArray())
	var game: GameController = main.get("screen")
	game.request({"type": "buy", "spell": false, "index": 0})
	game.recruit.settle()
	game.recruit.toggle_leaderboard()
	var before: String = JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN))
	var events_before: int = game.flow.session.events.size()
	var state_before: Dictionary = game.recruit.state.duplicate(true)
	var shown: int = game.recruit.shown_count()
	var entry: Control = game.recruit.find_child("CardsButton", true, false)
	assert_not_null(entry)
	_click(entry)
	var browser: CardBrowser = main.get("browser")
	assert_not_null(browser)
	assert_true(browser.in_game)
	assert_true(get_tree().paused)
	assert_eq(game.process_mode, Node.PROCESS_MODE_DISABLED)
	browser.select_tribe("mouse")
	browser.select_tier(5)
	browser.select_kind(true)
	browser.set_query("seek")
	_click(browser.find_child("Button_Close", true, false))
	assert_false(get_tree().paused)
	assert_eq(game.process_mode, Node.PROCESS_MODE_PAUSABLE)
	assert_same(main.get("screen"), game)
	assert_eq(JSON.stringify(game.flow.session.view_for(GameFlow.HUMAN)), before)
	assert_eq(game.flow.session.events.size(), events_before)
	assert_eq(game.recruit.state, state_before)
	assert_eq(game.recruit.shown_count(), shown, "the recruit UI was never redrawn")
	assert_true(game.recruit.show_leaderboard)
	assert_eq(game.phase, GameController.Phase.RECRUIT)
	await wait_process_frames(2)


func test_main_start_keeps_picker_choices_through_browser_game_and_result() -> void:
	var main: Control = MainScene.instantiate()
	add_child_autofree(main)
	var start: StartScreen = main.get("screen")
	var content: GameContent = main.get("content")
	assert_eq(start.tribes, content.tribe_ids())
	assert_eq(start.chosen(), PackedStringArray(), "all tribes initially")
	var first: String = start.tribes[0]
	var selected: String = start.tribes[1]
	assert_eq(str(start.names[first]), content.tribe_name(first))
	_click(start.find_child("Tribe_" + first, true, false))
	assert_false(start.chosen().has(first), "the tribe pill toggles it out")
	_click(start.find_child("Only_" + selected, true, false))
	var chosen := PackedStringArray([selected])
	assert_eq(start.chosen(), chosen, "Only selects that tribe")
	var play: Control = start.find_child("Button_Play", true, false)
	var cards: Control = start.find_child("Button_Cards", true, false)
	var quit_button: Control = start.find_child("Button_Quit", true, false)
	assert_lt(play.position.y, cards.position.y)
	assert_lt(cards.position.y, quit_button.position.y)
	assert_not_null(cards.get_node_or_null("Ring"), "Cards keeps the approved amber ring")
	_click(cards)
	var browser: CardBrowser = main.get("browser")
	browser.close_requested.emit()
	assert_eq(start.chosen(), chosen, "browsing keeps the picker choice")
	_click(play)
	var game: GameController = main.get("screen")
	var remembered: PackedStringArray = main.get("_tribes")
	assert_eq(remembered, chosen, "Play passes the chosen tribe ids into the game")
	var standings: Array[Dictionary] = [
		{"name": "You", "portrait": "", "place": 1, "health": 40, "you": true}
	]
	game.game_finished.emit(standings, 1)
	var result: ResultScreen = main.get("screen")
	result.start_screen_requested.emit()
	var returned: StartScreen = main.get("screen")
	assert_eq(returned.chosen(), chosen, "the picker remembers the choice after a game")
	assert_not_null(returned.find_child("Only_" + selected, true, false))
	assert_not_null(returned.find_child("Button_Cards", true, false))
	await wait_process_frames(2)


func test_escape_from_search_closes_browser_once_before_normal_pause_handling() -> void:
	for in_game: bool in [false, true]:
		var main: Control = MainScene.instantiate()
		add_child_autofree(main)
		if in_game:
			var start: StartScreen = main.get("screen")
			start.play_requested.emit(PackedStringArray())
		main.call("open_browser")
		var browser: CardBrowser = main.get("browser")
		watch_signals(browser)
		await wait_process_frames(2)
		browser.search.grab_focus()
		assert_true(browser.search.has_focus())
		main.call("toggle_pause")
		assert_null(main.get("pause"), "the pause panel cannot open over the browser")
		_escape()
		assert_signal_emit_count(browser, "close_requested", 1)
		assert_null(main.get("browser"))
		assert_null(main.get("pause"), "the closing Escape never opens Pause")
		assert_false(get_tree().paused)
		_escape(true)
		assert_null(main.get("pause"), "holding Escape does not open Pause on a key repeat")
		if in_game:
			_escape()
			assert_not_null(main.get("pause"), "the next distinct Escape opens Pause normally")
			_escape()
			assert_false(get_tree().paused)
		await wait_process_frames(2)


func test_escape_closes_browser_and_entry_ignores_held_cards() -> void:
	var main: Control = MainScene.instantiate()
	add_child_autofree(main)
	var start: StartScreen = main.get("screen")
	start.play_requested.emit(PackedStringArray())
	var game: GameController = main.get("screen")
	game.recruit.settle()
	game.recruit._input.press(game.recruit.shop_xy(0) + game.recruit.card_box() / 2.0)
	assert_true(game.recruit.is_holding())
	_click(game.recruit.find_child("CardsButton", true, false))
	assert_null(main.get("browser"))
	game.recruit._input.focus_lost()
	main.call("open_browser")
	var browser: CardBrowser = main.get("browser")
	assert_not_null(browser)
	await wait_process_frames(2)
	_escape()
	assert_null(main.get("browser"))
	assert_null(main.get("pause"), "Escape closes the browser without opening Pause")
	assert_false(get_tree().paused)
	await wait_process_frames(2)


static func _click(node: Control) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	node.gui_input.emit(click)


func _escape(echo: bool = false) -> void:
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.pressed = down
		key.echo = echo and down
		get_viewport().push_input(key, true)
