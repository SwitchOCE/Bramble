extends GutTest
## The fight carries state in tiles and motion; words live in a reader or the log.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const Settings := preload("res://src/ui/settings.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")

const STEP: float = 0.001


func before_each() -> void:
	Settings.path = "user://test_combat_declutter_settings.cfg"
	Settings.reset()


func after_each() -> void:
	CardView.window_override = Vector2.ZERO
	Settings.reset()
	DirAccess.remove_absolute(Settings.path)


func _start(full: bool) -> Dictionary:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var boards: Array = []
	for side: int in 2:
		var board: Array = []
		for slot: int in 7:
			if not full and slot > 0:
				board.append(null)
				continue
			var unit: Dictionary = UnitViews.from_def(library.get_unit("field_vole"))
			unit["uid"] = side * 7 + slot + 1
			board.append(unit)
		boards.append(board)
	return {"type": "combat_start", "boards": boards, "first_side": 0, "player_ids": [0, 1]}


func _screen(phone: bool = true, full: bool = false) -> CombatScreen:
	CardView.window_override = Vector2(1688, 780) if phone else Vector2(1920, 1080)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2337, 1080) if phone else Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var screen := CombatScreen.new()
	screen.manual_playback = true
	screen.auto_return = false
	screen.hero_health = [40, 40]
	viewport.add_child(screen)
	screen.setup({"events": []}, PackedStringArray(["You", "Opponent"]), 0, "Round 3", 40)
	screen._play_event(_start(full), false)
	return screen


func _advance(screen: CombatScreen, seconds: float) -> void:
	for tick: int in roundi(seconds / STEP):
		screen.advance_playback(STEP)


func _tap_background(screen: CombatScreen) -> void:
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	screen._unhandled_input(tap)


func test_full_boards_keep_all_stats_and_health_within_wordless_label_budget() -> void:
	var alphabet: RegEx = RegEx.create_from_string("[A-Za-z]")
	for phone: bool in [false, true]:
		var screen: CombatScreen = _screen(phone, true)
		await get_tree().process_frame
		await get_tree().process_frame
		var labels: Array[Dictionary] = Capture.text_nodes(screen)
		print(
			"declutter label budget: %s = %d/30" % ["phone" if phone else "desktop", labels.size()]
		)
		assert_lte(labels.size(), 30, "combat's visible text-node budget")
		assert_eq(labels.size(), 30, "14 pairs of stats and both hero Health numbers remain")
		for label: Dictionary in labels:
			assert_null(alphabet.search(str(label["text"])), "resting word: " + str(label["text"]))
		assert_eq(LayoutCheck.problems(screen, "resting combat", false), PackedStringArray())


func test_lunge_travel_and_hit_stop_stay_readable_at_one_and_four_times_speed() -> void:
	for speed: float in [1.0, 4.0]:
		var screen: CombatScreen = _screen()
		screen.set_speed(speed)
		var attacker: CardView = screen._cards[1]
		var home: Vector2 = attacker.position
		screen._play_event(
			{
				"type": "attack",
				"side": 0,
				"attacker": 1,
				"defender": 8,
				"joiners": [],
				"strikes": 1,
				"quick": false
			},
			true
		)
		_advance(screen, 0.1 / speed)
		assert_lt(attacker.position.distance_to(home), 0.01, "lift precedes travel")
		_advance(screen, 0.08)
		var travelling: Vector2 = attacker.position
		assert_gt(travelling.distance_to(home), 1.0, "the attacker physically travels")
		_advance(screen, maxf(0.1, 0.16 / speed) - 0.08 + STEP)
		var contact: Vector2 = attacker.position
		assert_gt(contact.distance_to(travelling), 1.0, "travel remains at least 100 ms")
		_advance(screen, 0.03)
		assert_lt(attacker.position.distance_to(contact), 0.01, "contact holds at least 40 ms")
		_advance(screen, 0.04)
		assert_gt(attacker.position.distance_to(contact), 1.0, "return follows hit stop")


func test_phone_tap_reader_pauses_and_background_tap_restores_playback_state() -> void:
	var screen: CombatScreen = _screen()
	var card: CardView = screen._cards[1]
	card.tapped.emit("combat", 1)
	assert_true(screen._reader.visible)
	assert_false(screen.playing, "reading pauses the fight")
	assert_eq(str(screen._reader.shown.get("name", "")), "Field Vole")
	_tap_background(screen)
	assert_false(screen._reader.visible)
	assert_true(screen.playing, "closing restores a running fight")
	screen.toggle_play()
	card.tapped.emit("combat", 1)
	_tap_background(screen)
	assert_false(screen.playing, "closing must preserve an explicit pause")


func test_tapping_marked_empty_pocket_reads_hex_and_trap_and_pauses() -> void:
	var screen: CombatScreen = _screen()
	screen._play_event({"type": "slot_hex", "side": 0, "slot": 3, "total": 4, "percent": 25}, false)
	screen._play_event(
		{"type": "slot_mark", "owner_side": 1, "side": 0, "slot": 3, "damage": 3, "source": 8},
		false
	)
	screen.board_for_side(0).slots[3].tapped.emit("own", 3)
	assert_true(screen._reader.visible)
	assert_false(screen.playing)
	var words: String = str(screen._reader.shown.get("text", ""))
	for expected: String in ["Hex", "−4 Attack", "−25%", "Trap: 3 damage on entry"]:
		assert_string_contains(words, expected)
	_tap_background(screen)
	assert_true(screen.playing)


func test_speed_token_cycles_and_saves_without_adding_a_label() -> void:
	var screen: CombatScreen = _screen()
	for expected: float in [2.0, 4.0, 1.0]:
		screen._speed_button.pressed.emit()
		assert_eq(screen.speed, expected)
		assert_eq(screen._speed_button.text, "", "chevrons show the rate without a label")
		Settings.fight_speed = -1
		Settings.load_saved()
		assert_eq(Settings.fight_speed, expected)
