extends GutTest
## The quiet tokens keep every changing journey fact one tap away.

const Away := preload("res://src/ui/widgets/away_tray.gd")
const Plaque := preload("res://src/ui/widgets/lobby_plaque.gd")
const Strip := preload("res://src/ui/widgets/lobby_strip.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func after_each() -> void:
	Card.window_override = Vector2.ZERO


func _state() -> Dictionary:
	return {
		"away":
		[
			{
				"def_id": "one_swallow",
				"name": "One Swallow",
				"attack": 78,
				"health": 94,
				"home_attack": 156,
				"home_health": 188,
				"turns_left": 1,
				"nest": 2,
				"tribes": ["Birds"],
				"text": "Fly South."
			},
			{
				"def_id": "mrs_jay",
				"name": "Mrs Jay",
				"attack": 7,
				"health": 10,
				"home_attack": 14,
				"home_health": 20,
				"turns_left": 2,
				"nest": 3,
				"tribes": ["Birds"]
			},
		],
		"doorstep":
		[
			{
				"def_id": "old_tern",
				"name": "Old Tern",
				"attack": 21,
				"health": 35,
				"tribes": ["Birds"]
			}
		],
	}


func _tray(state: Dictionary) -> Away:
	var tray := Away.new()
	add_child_autofree(tray)
	tray.size = Vector2(331, tray.row_height())
	tray.show_state(state)
	return tray


func test_resting_tokens_show_only_live_countdowns_at_both_sizes() -> void:
	for pixels: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		Card.window_override = pixels
		var state: Dictionary = _state()
		var before: Dictionary = state.duplicate(true)
		var tray: Away = _tray(state)
		await wait_process_frames(2)
		assert_eq(tray.tokens.size(), 3, "away and doorstep Birds all retain tokens")
		var labels: Array[Dictionary] = Capture.text_nodes(tray)
		assert_eq(labels.size(), 2, "one number per travelling Bird, no standing paragraph")
		for label: Dictionary in labels:
			assert_true(str(label["text"]) in ["1", "2"])
		for token: Interactive in tray.tokens:
			assert_gte(token.size.x, 122.0 if Card.is_phone() else 104.0)
			assert_gte(token.size.y, 122.0 if Card.is_phone() else 104.0)
			assert_true(token.has_node("JourneyMark"), "moon or closed door is above the portrait")
		assert_eq(state, before, "token rendering does not edit canonical journey state")


func test_one_tap_reads_exact_stats_homecoming_countdown_and_nest_without_mutating_state() -> void:
	var state: Dictionary = _state()
	var before: Dictionary = state.duplicate(true)
	var tray: Away = _tray(state)
	var requested: Array[Dictionary] = []
	var nests: Array[int] = []
	tray.bird_requested.connect(
		func(view: Dictionary, nest: int) -> void:
			requested.append(view)
			nests.append(nest)
	)
	tray.tokens[0].tapped.emit("away", 0)
	assert_eq(requested.size(), 1, "the first tap supplies the complete reader")
	assert_eq(nests, [2], "the screen can pulse that exact Nest")
	var reader: Dictionary = requested[0]
	assert_eq(CoreUtil.to_int(reader["attack"]), 78)
	assert_eq(CoreUtil.to_int(reader["home_health"]), 188)
	assert_string_contains(str(reader["text"]), "Now: 78 Attack / 94 Health.")
	assert_string_contains(str(reader["text"]), "Homecoming: 156 Attack / 188 Health.")
	assert_string_contains(str(reader["text"]), "Home in 1 turn.")
	assert_string_contains(str(reader["text"]), "Its Nest: front row, 3 from the left.")
	reader["attack"] = -100
	assert_eq(state, before, "the reader receives its own copy")
	tray.tokens[2].tapped.emit("away", 2)
	assert_string_contains(str(requested[1]["text"]), "On the doorstep until your hand has room.")
	assert_eq(CoreUtil.to_int(requested[1]["health"]), 35)


func test_arrival_targets_the_exact_birds_portrait_not_its_outer_token() -> void:
	var state: Dictionary = _state()
	var birds: Array = state["away"]
	var first: Dictionary = birds[0]
	first["iid"] = 501
	var second: Dictionary = birds[1]
	second["def_id"] = first["def_id"]
	second["iid"] = 502
	var tray: Away = _tray(state)
	await wait_process_frames(2)
	var destination: Dictionary = tray.arrival_target({"iid": 502, "def_id": first["def_id"]})
	var portrait: Control = destination["portrait"]
	var countdown: Control = destination["countdown"]
	var mark: Control = destination["mark"]
	assert_eq(portrait, tray.tokens[1].get_node("Portrait"))
	assert_eq(countdown, tray.tokens[1].get_node("Countdown"))
	assert_eq(mark, tray.tokens[1].get_node("JourneyMark"))
	assert_true(tray.tokens[1].get_global_rect().encloses(portrait.get_global_rect()))
	assert_lt(portrait.size.x, tray.tokens[1].size.x, "arrival dissolves inside the portrait")
	assert_eq(tray.arrival_target({"iid": 999, "def_id": first["def_id"]}), {})
	var legacy: Dictionary = tray.arrival_target({"def_id": first["def_id"]})
	var legacy_portrait: Control = legacy["portrait"]
	assert_eq(legacy_portrait, tray.tokens[0].get_node("Portrait"))
	var doorstep: Dictionary = tray.arrival_target({"def_id": "old_tern"})
	var doorstep_countdown: Control = doorstep["countdown"]
	assert_null(doorstep_countdown, "doorstep has no travelling countdown")


func test_overflow_scrolls_without_dropping_any_birds_and_clears_when_empty() -> void:
	var state: Dictionary = _state()
	var birds: Array = state["away"]
	for index: int in 10:
		birds.append(
			{
				"name": "Bird %d" % index,
				"turns_left": 2,
				"attack": 123456,
				"health": 234567,
				"home_attack": 246912,
				"home_health": 469134
			}
		)
	var tray: Away = _tray(state)
	await wait_process_frames(3)
	assert_eq(tray.tokens.size(), 13)
	var scroll: ScrollContainer = tray.get("_scroll")
	assert_gt(scroll.get_h_scroll_bar().max_value, scroll.get_h_scroll_bar().page)
	var final: Dictionary = tray.reader_for(11)
	assert_string_contains(str(final["text"]), "Homecoming: 246912 Attack / 469134 Health.")
	tray.show_state({"away": [], "doorstep": []})
	assert_false(tray.visible)
	assert_true(tray.tokens.is_empty())
	await wait_process_frames(1)


func test_opponent_tier_knots_show_exact_numerals_and_reader_numbers() -> void:
	var hero: Dictionary = UnitLibrary.load_dir().all_heroes()[0]
	var standing: Dictionary = {
		"player_id": 1,
		"hero": hero["name"],
		"name": "Rival",
		"tier": 6,
		"health": 17,
		"alive": true,
		"last_stand_enabled": true,
		"last_stand_active": true,
		"last_stand_used": false
	}
	var plaque := Plaque.new(standing, false)
	add_child_autofree(plaque)
	plaque.size = Vector2(160, 74)
	var knot: Control = plaque.get("_knot")
	assert_true(knot.is_visible_in_tree(), "the opponent tier knot stays on its portrait")
	var tier_number: Label = knot.get_node("TierKnot")
	assert_eq(tier_number.text, "6")
	assert_true(tier_number.is_visible_in_tree())
	var labels: Array[Dictionary] = Capture.text_nodes(plaque)
	assert_eq(labels.size(), 2, "opponent tier and current Health both count")
	var texts: Array[String] = []
	for label: Dictionary in labels:
		texts.append(str(label["text"]))
	assert_has(texts, "17")
	assert_has(texts, "6")
	var reader: Dictionary = Plaque.reader_card(standing)
	assert_eq(CoreUtil.to_int(reader["tier"]), 6)
	assert_string_contains(str(reader["text"]), "Tier 6.")
	assert_string_contains(str(reader["text"]), "Health 17.")
	assert_string_contains(str(reader["text"]), "Last Stand: ready.")
	assert_string_contains(str(reader["text"]), str(hero["text"]))
	var override: Dictionary = Plaque.reader_card(
		standing, {"name": "Resolved hero", "text": "Configured power: 17."}
	)
	assert_string_contains(str(override["text"]), "Configured power: 17.")


func test_next_tap_only_scouts_and_other_taps_read() -> void:
	Card.window_override = Vector2(1920, 1080)
	var strip := Strip.new()
	add_child_autofree(strip)
	strip.size = Vector2(1000, 74)
	strip.show_standings(
		[
			{"player_id": 0, "name": "You", "tier": 3, "health": 40},
			{"player_id": 1, "name": "Rival", "tier": 5, "health": 20}
		],
		1
	)
	var order: Array[String] = []
	strip.next_tapped.connect(func() -> void: order.append("scout"))
	strip.hero_requested.connect(func(_standing: Dictionary) -> void: order.append("reader"))
	var next: Plaque = strip.plaques[1]
	next.tap.tapped.emit("lobby", 1)
	assert_eq(order, ["scout"])
	order.clear()
	var other: Plaque = strip.plaques[0]
	other.tap.tapped.emit("lobby", 0)
	assert_eq(order, ["reader"])
	order.clear()
	next.tap.hovered.emit("lobby", 1, true)
	assert_eq(order, [], "hover leaves the scouting target unobstructed")


func test_all_six_tiers_have_one_counted_numeral_and_nonopponent_knots_stay_hidden() -> void:
	for tier: int in range(1, 7):
		var standing: Dictionary = {"name": "Rival", "tier": tier, "health": 20, "alive": true}
		var plaque := Plaque.new(standing, false)
		add_child_autofree(plaque)
		plaque.size = Vector2(160, 74)
		var knot: Control = plaque.get("_knot")
		assert_true(knot.visible)
		var number: Label = knot.get_node("TierKnot")
		assert_eq(number.text, str(tier))
		assert_eq(Capture.text_nodes(plaque).size(), 2, "tier and Health each count as text")
	for flags: Dictionary in [{"is_human": true}, {"alive": false}, {}]:
		var standing: Dictionary = {"name": "Rival", "tier": 6, "health": 20, "alive": true}
		standing.merge(flags, true)
		var ghost: bool = flags.is_empty()
		var plaque := Plaque.new(standing, false, ghost)
		add_child_autofree(plaque)
		var knot: Control = plaque.get("_knot")
		assert_false(knot.visible, "own, out and ghost portraits do not gain a tier knot")
