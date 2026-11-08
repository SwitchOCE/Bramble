extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const KIT := preload("res://tests/core/recruit_kit.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_combat_egg_detail_reads_the_current_egg_bird_and_trip_without_a_name() -> void:
	var view: Dictionary = {
		"def_id": "nest_egg",
		"attack": 4,
		"health": 3,
		"bird_attack": 7,
		"bird_health": 9,
		"turns_left": 1,
	}
	var text: String = CardDetail.full_text_bbcode(view)
	assert_string_contains(text, "Egg: 4/3.")
	assert_string_contains(text, "Bird: 7/9.")
	assert_string_contains(text, "Home in 1 turn.")
	assert_false(text.contains("No special rules"))
	assert_string_contains(
		CardDetail.full_text_bbcode({"def_id": "nest_egg", "attack": 4, "health": 3}),
		"No special rules",
		"scout Eggs never infer the private Bird or timer"
	)


func test_phone_egg_tooltip_shows_both_bodies_and_refreshes_the_homecoming_timer() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var state: Dictionary = port.get_state()
	state["slot_effects"] = [[], [], [], [], [], [], []]
	var board: Array = state["board"]
	board[2] = null
	var bird: Dictionary = {
		"name": "Old Tern",
		"attack": 7,
		"health": 9,
		"nest": 2,
		"turns_left": 3,
		"egg_attack": 9,
		"egg_health": 11,
	}
	state["away"] = [bird]
	var screen := RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	screen.call("_on_tapped", "board", 2)
	await wait_process_frames(2)
	var detail: CardDetail = screen.get("_detail")
	assert_eq(detail.shown["def_id"], "nest_egg")
	assert_eq(detail.shown["attack"], 9, "the supported Egg's own Attack")
	assert_eq(detail.shown["health"], 11)
	assert_string_contains(str(detail.shown["text"]), "Bird: 7/9")
	assert_string_contains(str(detail.shown["text"]), "comes home in 3 turns")
	assert_eq(LayoutCheck.problems(screen, "phone Egg tooltip"), PackedStringArray())
	bird["turns_left"] = 1
	state["away"] = [bird]
	screen.render()
	screen.call("_on_tapped", "board", 2)
	assert_string_contains(str(detail.shown["text"]), "comes home in 1 turn.")
	screen.call("_on_tapped", "table", -1)
	screen.call("_on_hovered", "board", 2, true)
	screen.call("_show_hover")
	assert_eq(detail.shown["def_id"], "nest_egg", "mouse hover reads the same Egg")
	await wait_process_frames(2)


func test_lump_preview_matches_placement_after_moving_between_nests_and_rings() -> void:
	for golden: bool in [false, true]:
		var kit := KIT.new()
		kit.setup(GameConfig.full_game())
		kit.rules.start_phase(kit.player, 5)
		var first: RecruitUnit = kit.put("mrs_jay")
		first.add_permanent(2, 3)
		var second: RecruitUnit = kit.put("mother_goose")
		second.add_permanent(5, 4)
		kit.player.away = [
			{"unit": first, "left": 4, "due": 7, "nest": 0},
			{"unit": second, "left": 4, "due": 7, "nest": 2},
		]
		kit.player.slot_effects[0] = [{"attack": 5, "health": 6}]
		kit.player.slot_effects[2] = [{"attack": 1, "health": 2}]
		var lump: RecruitUnit = kit.put("great_lump", 0, golden)
		lump.add_permanent(1, 2)
		kit.rules.board_changed(kit.player)
		var marks: Array = RecruitView.slot_marks(
			{"away": HeldUnits.away_views(kit.player), "slot_effects": kit.player.combat_slots()}
		)
		var preview: Dictionary = RecruitHeld.lump_preview(lump.view(), marks[2])
		assert_eq(kit.rules.move(kit.player, 0, 2), "")
		assert_eq(preview["attack"], lump.attack, "no old Nest or Ring bonus remains")
		assert_eq(preview["health"], lump.health)
		preview = RecruitHeld.lump_preview(lump.view(), marks[1])
		assert_eq(kit.rules.move(kit.player, 2, 1), "")
		assert_eq(preview["attack"], lump.attack, "leaving a Nest removes its borrowed body")
		assert_eq(preview["health"], lump.health)


func test_dragging_lump_updates_the_card_under_the_pointer_without_changing_state() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var state: Dictionary = port.get_state()
	state["slot_effects"] = [[], [], [], [], [], [], []]
	var board: Array = state["board"]
	board[0] = {
		"def_id": "great_lump",
		"name": "The Great Lump",
		"attack": 3,
		"health": 5,
		"tribes": ["Birds"],
		"text": "On a Nest, this also has half its Bird's current stats.",
	}
	board[2] = null
	state["away"] = [{"nest": 2, "name": "Mrs Jay", "attack": 9, "health": 11, "turns_left": 3}]
	var screen := RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	var before: String = JSON.stringify(state)
	var holder: Control = screen.call("_drag_preview", "board", 0)
	add_child_autofree(holder)
	assert_true(screen.call("_can_drop", {"zone": "board", "index": 0}, "board", 2))
	var dragged: CardView = holder.get_child(0)
	assert_eq(dragged.unit["attack"], 8)
	assert_eq(dragged.unit["health"], 11)
	assert_eq(JSON.stringify(state), before, "a preview never mutates the game")
