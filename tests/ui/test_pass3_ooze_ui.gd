extends GutTest
## Fixed recruit cards only: no game or lobby runs, and no new reminder labels.
@warning_ignore_start("unsafe_call_argument")

const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const OozeMarks := preload("res://src/ui/widgets/ooze_marks.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitOozes := preload("res://src/ui/screens/recruit_oozes.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const RecruitMotion := preload("res://src/ui/screens/recruit_motion.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const Settings := preload("res://src/ui/settings.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO
	Settings.reset()


func _ooze() -> Dictionary:
	return {
		"iid": 91,
		"def_id": "little_dollop",
		"name": "Little Dollop",
		"tier": 1,
		"attack": 31,
		"health": 42,
		"text": "Belly 1. Digest. Buying into this costs 1 gold less.",
		"tribes": ["Oozes"],
		"keywords": ["Belly", "Digest"],
		"ooze_ladle": true,
		"ooze_digest_preview": Vector2i(12, 17),
		"held": [{"def_id": "field_vole", "name": "Field Vole", "tribes": ["Hedgerow"]}]
	}


func test_digest_and_meal_are_read_on_demand_while_the_held_count_stays_visible() -> void:
	for window: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		CardView.window_override = window
		var card: CardView = CardView.new()
		add_child_autofree(card)
		card.show_unit(_ooze(), CardView.Mode.BOARD)
		card.set_card_width(189)
		var marks: OozeMarks = card.get("_ooze_marks")
		assert_false(marks.visible, "largest-Ooze and meal identity do not cover the portrait")
		assert_false(marks.ladle)
		assert_null(marks.meal)
		assert_eq(marks.get_child_count(), 0)
		var face: Control = card.get("_combat_marks")
		var counter: Label = face.get("counter")
		assert_true(counter.visible, "current Belly occupancy remains decision state")
		assert_eq(counter.text, "1")
		assert_eq(card.unit["attack"], 31)
		assert_eq(card.unit["health"], 42)
		assert_eq(card.chip_shown, "")
		var reader: String = CardDetail.full_text_bbcode(RecruitHeld.with_inside(card.unit))
		assert_string_contains(reader, "+12/+17")
		assert_string_contains(reader, "Field Vole")


func test_live_soup_bonus_is_already_in_stats_and_its_breakdown_is_in_reader() -> void:
	var view: Dictionary = _ooze()
	view["held"] = []
	view["ooze_ladle"] = false
	view["ooze_soup_bonus"] = Vector2i(7, 9)
	var card: CardView = CardView.new()
	add_child_autofree(card)
	card.show_unit(view)
	var marks: OozeMarks = card.get("_ooze_marks")
	assert_false(marks.visible)
	assert_false(marks.soup, "the pot duplicated numbers already in the beads")
	assert_string_contains(CardDetail.full_text_bbcode(view), "Stone Soup: +7/+9")
	assert_string_contains(CardDetail.full_text_bbcode(view), "kept when bought")
	assert_eq(card.unit["attack"], 31, "Soup is not added to stats a second time")
	assert_eq(card.unit["health"], 42)
	var attack: Label = card.get("_attack_label")
	var health: Label = card.get("_health_label")
	assert_eq(attack.text, "31")
	assert_eq(health.text, "42")


func test_reused_card_has_no_stale_ooze_overlay() -> void:
	var card: CardView = CardView.new()
	add_child_autofree(card)
	card.show_unit(_ooze())
	card.show_unit({"name": "Field Vole", "def_id": "field_vole", "tribes": ["Hedgerow"]})
	var marks: OozeMarks = card.get("_ooze_marks")
	assert_false(marks.visible)
	assert_null(marks.meal)
	assert_false(marks.ladle)
	assert_false(marks.soup)


func _board_card(board: BoardView, view: Dictionary, slot: int) -> CardView:
	var card: CardView = CardView.new()
	card.show_unit(view, CardView.Mode.BOARD)
	board.place_card(card, slot)
	return card


func test_nell_reader_names_resolved_eaters_and_reach_pulses_only_after_opening() -> void:
	for speed: float in [1.0, 4.0]:
		for reduced: bool in [false, true]:
			Settings.fight_speed = speed
			Settings.reduce_motion = reduced
			var board: BoardView = BoardView.new()
			add_child_autofree(board)
			board.configure("board", 209, true)
			_board_card(board, {"iid": 1, "name": "Little Dollop", "tribes": ["Oozes"]}, 1)
			_board_card(board, {"iid": 2, "name": "Mrs Posset", "tribes": ["Oozes"]}, 2)
			var nell: Dictionary = {
				"iid": 95,
				"def_id": "dishwater_nell",
				"text":
				"Start of Turn: the biggest Ooze next to this eats your shop's lowest-tier unit.",
				"ooze_nell_eaters": [1, 2]
			}
			_board_card(board, nell, 5)
			var interaction: RecruitOozes = RecruitOozes.new()
			assert_eq(interaction.hover(board, nell, 5, true), nell)
			assert_eq(board.get("_relations"), [], "pointer entry alone gives no rule highlight")
			var preview: Dictionary = RecruitOozes.reader_view(board, nell)
			assert_string_contains(
				str(preview["text"]), "Current eaters: Little Dollop and Mrs Posset."
			)
			assert_false(
				str(nell["text"]).contains("Current eaters"), "canonical rules are untouched"
			)
			assert_eq(preview["ooze_nell_eaters"], [1, 2])
			board.show_relations(RecruitView.related_slots(nell, 5))
			var pulse: Tween = board.get("_reach_tween")
			pulse.pause()
			pulse.custom_step(0.1 / speed)
			assert_gt(board.slots[1].reach_flash, 0.0)
			assert_gt(board.slots[2].reach_flash, 0.0)
			assert_eq(board.slots[0].reach_flash, 0.0, "unreached pockets stay calm")
			pulse.custom_step(0.4 / speed)
			assert_eq(board.slots[1].reach_flash, 0.0, "no standing reach remains")
			assert_eq(board.slots[2].reach_flash, 0.0)
			nell["ooze_nell_eaters"] = []
			assert_string_contains(
				RecruitOozes.reader_view(board, nell)["text"], "No Ooze next to this."
			)


func test_aspic_reader_names_the_eligible_front_oozes_without_slot_codes() -> void:
	var board: BoardView = BoardView.new()
	add_child_autofree(board)
	board.configure("board", 209, true)
	_board_card(board, {"iid": 1, "name": "Little Dollop", "tribes": ["Oozes"]}, 0)
	_board_card(board, {"iid": 2, "name": "Field Vole", "tribes": ["Hedgerow"]}, 1)
	var aspic: Dictionary = {
		"iid": 3,
		"def_id": "aunt_aspic",
		"text": "Oozes in front of this gain half more from eating non-Oozes."
	}
	_board_card(board, aspic, 4)
	var reader: Dictionary = RecruitOozes.reader_view(board, aspic)
	assert_string_contains(str(reader["text"]), "Serves Little Dollop.")
	assert_false(str(reader["text"]).contains("Field Vole"))
	assert_eq(RecruitView.related_slots(aspic, 4), [0, 1])


func test_elder_share_uses_short_bead_motion_once_per_new_serial_without_an_overlay() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var port: FixturePort = FixturePort.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		var state: Dictionary = port.get_state()
		var view: Dictionary = _ooze()
		view["ooze_share_serial"] = 1
		state["board"] = [view, null, null, null, null, null, null]
		var screen: RecruitScreen = RecruitScreen.new()
		add_child_autofree(screen)
		screen.setup(port)
		var motion: RecruitMotion = screen.get("_motion")
		motion.set_process(false)
		var board: BoardView = screen.get("_board")
		var initial: CardView = board.cards[0]
		assert_eq(initial.attack_bead().modulate, Color.WHITE, "first paint establishes a baseline")
		view["ooze_share_serial"] = 2
		screen.render()
		motion.set_process(false)
		var first: CardView = board.cards[0]
		motion.advance(0.075)
		assert_ne(first.attack_bead().modulate, Color.WHITE, "new sharing pops the actual beads")
		var first_marks: Control = first.get("_ooze_marks")
		assert_false(first_marks.visible)
		motion.advance(0.4)
		assert_eq(first.attack_bead().modulate, Color.WHITE)
		assert_eq(first.attack_bead().scale, Vector2.ONE)
		screen.render()
		var second: CardView = board.cards[0]
		assert_eq(second.attack_bead().modulate, Color.WHITE, "unchanged serial does not replay")
		view["ooze_share_serial"] = 3
		screen.render()
		motion.set_process(false)
		var third: CardView = board.cards[0]
		motion.advance(0.075)
		assert_ne(third.health_bead().modulate, Color.WHITE)
		motion.advance(0.4)
		assert_eq(third.health_bead().modulate, Color.WHITE)
		assert_eq(third.unit["attack"], 31)
		assert_eq(third.unit["health"], 42)
		await wait_process_frames(2)


func test_soup_bonus_changes_roll_actual_beads_and_do_not_repeat_on_unchanged_render() -> void:
	var board: BoardView = BoardView.new()
	add_child_autofree(board)
	var holder: Control = Control.new()
	add_child_autofree(holder)
	var card: CardView = CardView.new()
	holder.add_child(card)
	var view: Dictionary = _ooze()
	view["iid"] = 123
	view["held"] = []
	view["ooze_soup_bonus"] = Vector2i(7, 9)
	card.show_unit(view)
	var motion: RecruitMotion = RecruitMotion.new()
	add_child_autofree(motion)
	var adapter: RecruitOozes = RecruitOozes.new()
	adapter.render(board, motion, holder)
	motion.set_process(false)
	var attack: Label = card.get("_attack_label")
	assert_eq(attack.text, "31", "first paint establishes the shown Soup baseline")
	assert_eq(motion.get("_pops"), [], "initial state is not presented as a newly earned gain")
	view["ooze_soup_bonus"] = Vector2i(11, 13)
	view["attack"] = 35
	view["health"] = 46
	card.show_unit(view)
	adapter.render(board, motion, holder)
	motion.set_process(false)
	assert_eq(attack.text, "31", "the displayed label rolls from the previous Soup value")
	assert_eq(card.unit["attack"], 35, "the canonical stats are never changed by the roll")
	motion.advance(0.3)
	assert_eq(attack.text, "35")
	motion.finish()
	adapter.render(board, motion, holder)
	assert_eq(motion.get("_pops"), [], "unchanged Soup bonus does not replay its cue")
	assert_eq(card.unit["ooze_soup_bonus"], Vector2i(11, 13))
