extends GutTest
## The fight carries state in tiles and motion; words live in a reader or the log.

const App := preload("res://src/ui/app.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const Data := preload("res://src/ui/view_data.gd")
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
		var ancillary: Array[Dictionary] = Capture.budget_nodes(screen)
		print(
			(
				"declutter label budget: %s = %d/10 (raw %d)"
				% ["phone" if phone else "desktop", ancillary.size(), labels.size()]
			)
		)
		assert_lte(ancillary.size(), 10, "combat ancillary text-node budget")
		assert_eq(ancillary.size(), 0, "primary stats are the only resting text")
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
	assert_lt(
		screen._reader.get_global_rect().end.y,
		screen._play_button.get_global_rect().position.y,
		"phone reader clears the entire control row"
	)
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


func test_pc_hover_reader_keeps_playing_and_allows_pointer_to_reach_rules() -> void:
	var screen: CombatScreen = _screen(false)
	var card: CardView = screen._cards[1]
	card.hovered.emit("combat", 1, true)
	assert_true(screen._reader.visible)
	assert_true(screen.playing, "hover reading keeps PC playback running")
	card.hovered.emit("combat", 1, false)
	assert_false(screen._hover_close.is_stopped(), "crossing the gap allows a short grace period")
	screen._reader.mouse_entered.emit()
	assert_true(screen._hover_close.is_stopped(), "the reader remains usable under the pointer")
	screen._reader.mouse_exited.emit()
	screen._hover_close.timeout.emit()
	assert_false(screen._reader.visible)


func test_phone_tapping_empty_pocket_closes_an_open_reader() -> void:
	var screen: CombatScreen = _screen()
	screen._cards[1].tapped.emit("combat", 1)
	screen.board_for_side(0).slots[3].tapped.emit("own", 3)
	assert_false(screen._reader.visible)
	assert_true(screen.playing)


func test_aura_change_flashes_its_actual_source_without_an_explicit_trigger_event() -> void:
	var screen: CombatScreen = _screen(false, true)
	screen._play_event(
		{
			"type": "stats",
			"source": null,
			"target": 8,
			"attack": 7,
			"health": 3,
			"max_health": 3,
			"attack_delta": 5,
			"health_delta": 0,
			"causes": [{"name": "aura", "source": 2, "change": "gained"}]
		},
		true
	)
	_advance(screen, 0.075)
	assert_gt(screen._cards[2].modulate.r, 1.05, "the aura giver visibly causes the gain")
	assert_eq(screen._cards[3].modulate, Color.WHITE, "an unrelated card does not flash")
	assert_eq(Data.i(screen.model.unit(8), "attack"), 7)


func test_pack_damage_keeps_each_contribution_visible() -> void:
	var screen: CombatScreen = _screen(false, true)
	screen._play_event(
		{"type": "attack", "attacker": 1, "defender": 8, "joiners": [2], "strikes": 1}, true
	)
	screen._play_event(
		{
			"type": "damage",
			"source": 1,
			"target": 8,
			"amount": 1,
			"health_after": 2,
			"kind": "attack",
			"strike": 1
		},
		true
	)
	screen._play_event(
		{
			"type": "damage",
			"source": 2,
			"target": 8,
			"amount": 2,
			"health_after": 0,
			"kind": "attack",
			"strike": 1
		},
		true
	)
	var text: Array[Dictionary] = Capture.budget_nodes(screen._cards[8])
	assert_eq(text.size(), 2, "the leader and joiner each keep their own damage pop")
	assert_eq(str(text[0]["text"]), "−1")
	assert_eq(str(text[1]["text"]), "−2")


func test_final_death_rewards_overlap_so_automatic_return_stays_inside_time_budget() -> void:
	var screen: CombatScreen = _screen(false)
	screen.auto_return = true
	screen.events = [
		{"type": "attack", "attacker": 1, "defender": 8, "joiners": []},
		{
			"type": "damage",
			"source": 1,
			"target": 8,
			"amount": 3,
			"health_after": 0,
			"kind": "attack"
		},
		{
			"type": "damage",
			"source": 8,
			"target": 1,
			"amount": 1,
			"health_after": 2,
			"kind": "attack"
		},
		{"type": "death", "uid": 8, "side": 1, "slot": 0},
		{"type": "take", "hunter": 1, "quarry": 8, "side": 0},
		{"type": "trigger", "uid": 1, "mechanic": "take_growth"},
		{
			"type": "stats",
			"source": 1,
			"target": 1,
			"attack": 3,
			"health": 3,
			"max_health": 4,
			"attack_delta": 1,
			"health_delta": 1
		},
		{"type": "quarry_lost", "hunter": 1, "quarry": 8},
		{"type": "early_spoils", "side": 0, "amount": 1},
		{"type": "combat_end", "winner": 0, "damage": 2},
	]
	var completed: Array[bool] = []
	screen.finished.connect(func() -> void: completed.append(true))
	var since_death: float = 0.0
	var saw_death: bool = false
	for tick: int in 3000:
		screen.advance_playback(STEP)
		if not Data.b(screen.model.unit(8), "alive", true):
			saw_death = true
		if saw_death:
			since_death += STEP
		if not completed.is_empty():
			break
	assert_true(saw_death)
	assert_eq(completed.size(), 1)
	assert_lte(
		since_death,
		1.6,
		"Take, growth and Spoils share the result animation instead of delaying it"
	)


func test_replaying_from_recruit_does_not_add_a_second_round_record() -> void:
	var port := FixturePort.new()
	port.use_state("recruit_round7")
	port.use_combat()
	var app := App.new()
	add_child_autofree(app)
	app.setup(port)
	app.show_game_combat()
	assert_eq(app.round_log.size(), 1)
	app.show_recruit()
	var recruit: RecruitScreen = app.current as RecruitScreen
	recruit.watch_fight_requested.emit()
	assert_true(app.current is CombatScreen, "the recruit reader opens the last fight")
	assert_eq(app.round_log.size(), 1, "watching it again does not duplicate its record")


func test_reduce_motion_holds_all_attack_sources_until_the_next_attack() -> void:
	Settings.reduce_motion = true
	var screen: CombatScreen = _screen(false, true)
	screen.events = [{"type": "attack", "attacker": 1, "defender": 8, "joiners": [2]}]
	screen.next_index = 1
	var attack: Dictionary = screen.events[0]
	screen._play_event(attack, true)
	_advance(screen, 0.7)
	var sources: Array = screen._motion.get("_held_sources")
	assert_eq(sources.size(), 2)
	for source: Control in sources:
		assert_true(source.visible, "the cue cannot fall between sampled frames")
	screen._play_event({"type": "attack", "attacker": 8, "defender": 1}, true)
	sources = screen._motion.get("_held_sources")
	assert_eq(sources.size(), 1)
	var marker: Control = sources[0]
	var actor: int = marker.get("actor_uid")
	assert_eq(actor, 8)


func test_take_identifies_its_hunter_and_uses_its_own_quarry_after_simultaneous_deaths() -> void:
	var screen: CombatScreen = _screen(false, true)
	screen._play_event({"type": "death", "uid": 8}, false)
	screen._play_event({"type": "death", "uid": 2}, false)
	screen._play_event({"type": "take", "hunter": 1, "quarry": 8}, true)
	_advance(screen, 0.3)
	assert_gt(screen._cards[1].modulate.r, 1.05, "the hunter stays visibly active")
	var found: bool = false
	for child: Node in screen._overlay.get_children():
		if child.has_meta("take_quarry_uid"):
			var uid: int = child.get_meta("take_quarry_uid")
			var point: Vector2 = child.get_meta("quarry_point")
			assert_eq(uid, 8)
			assert_eq(point, screen.board_for_side(1).slot_global_center(0))
			found = true
	assert_true(found, "the claim travels from its hunter to the specified quarry")


func test_self_stat_effect_has_a_source_to_bead_route_before_the_number_roll() -> void:
	var screen: CombatScreen = _screen(false)
	var old_attack: int = Data.i(screen.model.unit(1), "attack")
	screen._play_event(
		{
			"type": "stats",
			"source": 1,
			"target": 1,
			"attack": old_attack + 2,
			"attack_delta": 2,
			"health_delta": 0
		},
		true
	)
	var label: Label = screen._cards[1].get("_attack_label")
	assert_eq(label.text, str(old_attack), "the old value remains until the effect lands")
	var found: bool = false
	for child: Node in screen._overlay.get_children():
		if child.has_meta("effect_stat"):
			var source: int = child.get_meta("effect_source_uid")
			var target: int = child.get_meta("effect_target_uid")
			assert_eq(source, 1)
			assert_eq(target, 1)
			found = true
	assert_true(found)
	_advance(screen, 0.55)
	assert_eq(label.text, str(old_attack + 2))


func test_dead_unit_reward_lands_on_visible_stat_echo_without_resurrecting_it() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var screen: CombatScreen = _screen()
		screen._play_event({"type": "death", "uid": 1, "side": 0, "slot": 0}, false)
		screen._play_event(
			{
				"type": "permanent_reward",
				"source": 1,
				"target": 1,
				"attack_delta": 1,
				"health_delta": 1
			},
			true
		)
		assert_false(screen._cards.has(1), "the effect does not resurrect a tile")
		assert_false(Data.b(screen.model.unit(1), "alive"))
		assert_eq(Capture.text_nodes(screen._overlay).size(), 0, "gains wait for their motes")
		_advance(screen, 0.5)
		var gains: Array[Dictionary] = Capture.text_nodes(screen._overlay)
		assert_eq(gains.size(), 2, "both carried stat gains visibly land")
		for gain: Dictionary in gains:
			assert_eq(str(gain["text"]), "+1")


func test_counter_damage_pop_follows_its_recipient_through_the_return() -> void:
	var screen: CombatScreen = _screen()
	var attacker: CardView = screen._cards[1]
	var home: Vector2 = attacker.position
	screen._play_event({"type": "attack", "attacker": 1, "defender": 8, "joiners": []}, true)
	_advance(screen, screen._motion.contact_time())
	screen._play_event(
		{
			"type": "damage",
			"source": 8,
			"target": 1,
			"amount": 1,
			"health_after": 2,
			"kind": "attack"
		},
		true
	)
	var pop: Control = attacker.get_node("DamagePop")
	assert_eq(CoreUtil.to_int(pop.get_meta("recipient_uid")), 1)
	var local_point: Vector2 = pop.position
	_advance(screen, 0.25)
	assert_eq(pop.position, local_point, "the pop stays attached while its card returns")
	assert_lt(attacker.position.distance_to(home), 1.0)
	assert_lt(
		pop.get_global_rect().get_center().distance_to(
			attacker.health_bead().get_global_rect().get_center()
		),
		2.0
	)


func test_dying_attacker_fades_at_home_without_a_second_enemyward_motion() -> void:
	var screen: CombatScreen = _screen()
	var attacker: CardView = screen._cards[1]
	var home: Vector2 = attacker.position
	screen._play_event({"type": "attack", "attacker": 1, "defender": 8, "joiners": []}, true)
	_advance(screen, screen._motion.contact_time())
	screen._play_event({"type": "death", "uid": 1, "side": 0, "slot": 0}, true)
	assert_eq(attacker.position, home)
	_advance(screen, 0.25)
	assert_lt(attacker.position.distance_to(home), 0.01, "corpse fades in its own pocket")
	assert_lt(attacker.modulate.a, 1.0)


func test_budget_excludes_primary_stats_but_counts_pocket_and_held_numbers() -> void:
	var screen: CombatScreen = _screen(false, true)
	var card: CardView = screen._cards[1]
	card.unit["held"] = 2
	card.show_unit(card.unit, CardView.Mode.BOARD)
	screen._play_event({"type": "slot_hex", "side": 0, "slot": 3, "total": 4, "percent": 25}, false)
	screen._play_event(
		{"type": "slot_mark", "owner_side": 1, "side": 0, "slot": 4, "damage": 3, "source": 8},
		false
	)
	var ancillary: Array[Dictionary] = Capture.budget_nodes(screen)
	assert_gte(ancillary.size(), 3, "held count, Hex and trap must all consume the budget")
	assert_lte(ancillary.size(), 10)
	for entry: Dictionary in ancillary:
		assert_false(CoreUtil.to_bool(entry["primary_stat"]))
