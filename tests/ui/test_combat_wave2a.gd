extends GutTest
## Wave 2a state is wordless on the board, exact in the reader and visibly caused by its unit.
@warning_ignore_start("unsafe_call_argument")

const Screen := preload("res://src/ui/screens/combat_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Settings := preload("res://src/ui/settings.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")


func after_each() -> void:
	Settings.reset()
	CardView.window_override = Vector2.ZERO


func _screen() -> Screen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var screen := Screen.new()
	screen.manual_playback = true
	screen.auto_return = false
	viewport.add_child(screen)
	screen.setup({"events": []}, PackedStringArray(["You", "Opponent"]), 0, "Round 3", 40)
	var boards: Array = []
	for side: int in 2:
		var slots: Array = []
		for slot: int in 7:
			slots.append(
				{
					"uid": side * 7 + slot + 1,
					"def_id": "his_highness",
					"name": "Frog",
					"attack": 4,
					"health": 6,
					"max_health": 6,
					"bog_kiss_period": 5,
					"counters": {"kisses": 4},
					"text": "After this attacks: gain Health."
				}
			)
		boards.append(slots)
	screen._play_event({"type": "combat_start", "boards": boards}, false)
	return screen


func _advance(screen: Screen, seconds: float) -> void:
	for tick: int in roundi(seconds * 120):
		screen.advance_playback(1.0 / 120.0)


func test_pending_gain_has_a_source_and_its_dead_recipient_landing_fades() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var screen: Screen = _screen()
		screen._play_event(
			{
				"type": "gain_pending",
				"target": 1,
				"source": 8,
				"attack": 2,
				"health": 3,
				"attack_delta": 2,
				"health_delta": 3
			},
			true
		)
		assert_eq(screen.model.unit(1)["attack"], 4, "queued gains do not change fighting stats")
		var marks: Control = screen._cards[1].get("_combat_marks")
		assert_true(marks.get("pending_visible"))
		assert_eq(Capture.budget_nodes(screen).size(), 0, "the live tag adds no labels")
		assert_true(screen._overlay.has_node("TriggerSource_8"))
		screen._play_event({"type": "death", "uid": 1}, false)
		screen._play_event(
			{
				"type": "gain_pending",
				"target": 1,
				"source": 8,
				"attack": 3,
				"health": 5,
				"attack_delta": 1,
				"health_delta": 2
			},
			true
		)
		_advance(screen, 0.5)
		var kept: Control = screen._overlay.get_node("KeptGain_1")
		assert_true(kept.visible)
		assert_eq(kept.get_node("Pending").get("text"), "+3/+5", "totals are retained, not doubled")
		assert_false(screen._cards.has(1))
		_advance(screen, 1.0)
		await get_tree().process_frame
		assert_false(
			is_instance_valid(kept), "no reserve portrait or total stands beside the board"
		)


func test_bog_toll_travels_to_hero_then_fades_and_keeps_exact_reader_total() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var screen: Screen = _screen()
		screen._play_event(
			{"type": "bog_toll", "side": 1, "source": 8, "amount": 7, "total": 1234567}, true
		)
		assert_false(screen._plaques[1].has_node("BogToll"), "there is no standing plaque badge")
		assert_true(screen._overlay.has_node("TriggerSource_8"))
		assert_eq(screen.model.bog_toll[1], 1234567)
		assert_eq(Capture.budget_nodes(screen).size(), 0)
		var found: bool = false
		for child: Node in screen._overlay.get_children():
			if child.has_meta("bog_toll_side"):
				found = true
				assert_eq(CoreUtil.to_int(child.get_meta("bog_toll_side")), 1)
				assert_eq(
					child.get_meta("effect_to"), screen._plaques[1].get_global_rect().get_center()
				)
		assert_true(found, "the splash travels from its source to its own hero")
		_advance(screen, 0.4)
		assert_gt(screen._plaques[1].modulate.g, 1.0, "arrival pulses the hero")
		_advance(screen, 1.0)
		await get_tree().process_frame
		for child: Node in screen._overlay.get_children():
			assert_false(child.has_meta("bog_toll_side"), "the Toll cue fades and is freed")
		assert_eq(screen._plaques[1].modulate, Color.WHITE)
		screen._show_hero(1)
		assert_string_contains(screen._note_text.get_parsed_text(), "Bog Toll: 1,234,567")
		screen.restart()
		assert_false(screen._plaques[1].has_node("BogToll"))
		await get_tree().process_frame


func test_dropped_action_chips_retain_a_held_source_cue_in_both_motion_modes() -> void:
	var cases: Array[Dictionary] = [
		{"type": "bog_patch", "maker": 1, "side": 1, "slot": 0},
		{"type": "take", "hunter": 1, "quarry": 8, "side": 0},
		{"type": "poach", "hunter": 1, "quarry": 8, "side": 0},
		{"type": "trigger", "uid": 1, "mechanic": "pass3_hunter:russet"},
		{"type": "trigger", "uid": 1, "mechanic": "pack"},
		{"type": "immediate_attack", "kind": "pounce", "attacker": 1, "defender": 8},
		{"type": "immediate_attack", "kind": "counter", "attacker": 1, "defender": 8},
		{"type": "quarry_marked", "source": 1, "hunter": 1, "quarry": 8},
		{"type": "kiss", "target": 1, "side": 0, "count": 5, "period": 5},
		{"type": "transform", "target": 1, "unit": {"def_id": "the_prince_restored", "attack": 8}},
		{"type": "bog_hit_back", "source": 1, "target": 8}
	]
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		for event: Dictionary in cases:
			var screen: Screen = _screen()
			screen._play_event(event, true)
			_advance(screen, 0.4)
			var ring: Control = screen._overlay.get_node_or_null("TriggerSource_1")
			assert_not_null(ring, str(event))
			if ring != null:
				assert_true(ring.visible, str(event))
			assert_eq(screen._cards[1].chip_shown, "", "the source cue adds no word chip")


func test_combat_kiss_reader_uses_replayed_count_and_configured_period() -> void:
	var screen: Screen = _screen()
	screen._play_event({"type": "kiss", "target": 1, "side": 0, "count": 9, "period": 5}, false)
	screen._show_detail(1)
	assert_string_contains(screen._note_text.get_parsed_text(), "Shared kisses: 9 (4/5)")


func test_many_kept_gains_fade_and_hold_the_ten_label_cap() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var screen: Screen = _screen()
		for uid: int in range(1, 15):
			screen._play_event({"type": "death", "uid": uid}, false)
			var event: Dictionary = {
				"type": "gain_pending",
				"source": uid,
				"target": uid,
				"attack": 1,
				"health": 2,
				"attack_delta": 1,
				"health_delta": 2
			}
			screen._play_event(event, true)
		for tick: int in 180:
			screen.advance_playback(1.0 / 120.0)
			assert_lte(
				Capture.budget_nodes(screen).size(), 10, "all transient and reserve labels count"
			)
		await get_tree().process_frame
		for child: Node in screen._overlay.get_children():
			assert_false(child.has_meta("kept_target_uid") and child is Panel, "no reserve remains")
		for type: String in ["gain_pending", "permanent_reward"]:
			screen._play_event(
				{"type": type, "source": 1, "target": 1, "attack_delta": 1, "health_delta": 1},
				false
			)
		assert_false(
			screen._overlay.has_node("KeptGain_1"), "skip to end creates neither reserve path"
		)


func test_repeated_kept_gain_refreshes_hold_without_an_old_fade_hiding_it() -> void:
	var screen: Screen = _screen()
	screen._play_event({"type": "death", "uid": 1}, false)
	for total: int in [1, 2]:
		screen._play_event(
			{"type": "gain_pending", "target": 1, "source": 8, "attack": total, "health": total},
			true
		)
		_advance(screen, 0.3)
	var kept: Control = screen._overlay.get_node("KeptGain_1")
	_advance(screen, 0.48)
	assert_true(kept.visible)
	assert_gt(kept.modulate.a, 0.95, "the first event's fade cannot hide the refreshed landing")
	_advance(screen, 0.5)
	await get_tree().process_frame
	assert_false(is_instance_valid(kept))
