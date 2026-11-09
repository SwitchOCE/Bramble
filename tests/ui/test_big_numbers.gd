extends GutTest
## Compact stats keep their exact source values and one-tap recruit/combat details.
@warning_ignore_start("unsafe_call_argument")

const Numbers := preload("res://src/ui/stat_numbers.gd")
const States := preload("res://tests/ui/big_number_states.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _phone() -> SubViewport:
	CardView.window_override = Vector2(1688, 780)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	return viewport


func _tap(card: CardView) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = card.size / 2.0
		card._gui_input(event)


func _badges_fit(card: CardView) -> void:
	for key: String in ["_attack_label", "_health_label"]:
		var label: Label = card.get(key)
		var badge: ShapeBadge = label.get_parent() as ShapeBadge
		var font: Font = label.get_theme_font("font")
		var text_width: float = (
			font
			. get_string_size(
				label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")
			)
			. x
		)
		assert_lte(text_width, badge.inner_width(), label.text)
		assert_lte(badge.size.x, 84.0, "large values cannot grow into another pocket")


func test_compact_cutoff_rounding_suffix_promotion_and_exact_values() -> void:
	var examples: Dictionary = {
		0: "0",
		1234: "1234",
		9999: "9999",
		10000: "10k",
		12345: "12.3k",
		12350: "12.4k",
		999949: "999.9k",
		999950: "1m",
		1234567: "1.2m",
		9999999: "10m",
		1000000000: "1b"
	}
	for value: int in examples:
		assert_eq(Numbers.compact(value), examples[value])
	assert_eq(Numbers.exact(1234567), "1,234,567")
	assert_eq(Numbers.exact(0), "0")
	assert_eq(Numbers.exact(-12345), "-12,345")


func test_badges_fit_fixed_sizes_and_recover_font_on_combat_stat_updates() -> void:
	var viewport: SubViewport = _phone()
	var values: Array[int] = [9999, 12345, 999949, 1234567, BoardUnit.STAT_CLAMP]
	for width: float in [96.0, 124.0, 168.0]:
		for mode: CardView.Mode in [CardView.Mode.BOARD, CardView.Mode.SHOP, CardView.Mode.MINI]:
			var card := CardView.new()
			viewport.add_child(card)
			var view: Dictionary = States.boards(7)[0][0]
			card.show_unit(view.duplicate(true), mode)
			card.set_card_width(width)
			for value: int in values:
				card.set_stats(value, value, value)
				await get_tree().process_frame
				_badges_fit(card)
				assert_eq(card.unit["attack"], value, "formatting never changes the actual stat")
			var label: Label = card.get("_attack_label")
			card.set_stats(999949, 999949, 999949)
			var small_font: int = label.get_theme_font_size("font_size")
			card.set_stats(1, 0, 1)
			assert_gt(label.get_theme_font_size("font_size"), small_font)
			assert_eq(label.text, "1")
			var health: Label = card.get("_health_label")
			assert_eq(health.text, "0")
			card.free()


func test_phone_recruit_boards_fit_at_all_requested_digit_counts_and_tap_shows_exact_stats(
) -> void:
	for digits: int in [4, 5, 7]:
		var viewport: SubViewport = _phone()
		var port := FixturePort.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		States.recruit(port.get_state(), digits)
		var screen := RecruitScreen.new()
		viewport.add_child(screen)
		screen.setup(port)
		await get_tree().process_frame
		var board: BoardView = screen.get("_board")
		for card: CardView in board.cards:
			_badges_fit(card)
		assert_eq(LayoutCheck.problems(screen, "recruit %d digits" % digits), PackedStringArray())
		if digits == 7:
			var detail: CardDetail = screen.get("_detail")
			assert_false(detail.visible)
			_tap(board.cards[1])
			await get_tree().process_frame
			var notes: RichTextLabel = detail.get("_notes")
			assert_true(detail.visible, "one tap opens the exact stats")
			assert_string_contains(notes.get_parsed_text(), "Attack: 1,234,567\nHealth: 9,999,998")
			assert_eq(detail.shown["attack"], 1234567)
			assert_eq(
				LayoutCheck.problems(screen, "selected recruit 7 digits"), PackedStringArray()
			)
		viewport.free()


func test_phone_combat_boards_fit_and_one_tap_uses_current_exact_health() -> void:
	for digits: int in [4, 5, 7]:
		var viewport: SubViewport = _phone()
		var screen := CombatScreen.new()
		viewport.add_child(screen)
		screen.setup(States.fight(digits), PackedStringArray(["You", "Opponent"]), 0, "Round 14")
		screen.playing = false
		var first: Dictionary = screen.events[0]
		screen._play_event(first, false)
		await get_tree().process_frame
		for side: int in 2:
			for card: CardView in screen.board_for_side(side).cards:
				_badges_fit(card)
		assert_eq(LayoutCheck.problems(screen, "combat %d digits" % digits), PackedStringArray())
		if digits == 7:
			screen._play_event(
				{
					"type": "damage",
					"source": 101,
					"target": 2,
					"amount": 111,
					"raw": 111,
					"kind": "attack",
					"health_after": 9999887
				},
				false
			)
			_tap(screen.board_for_side(0).cards[1])
			await get_tree().process_frame
			var notes: RichTextLabel = screen.get("_note_text")
			assert_string_contains(notes.get_parsed_text(), "Attack: 1,234,567\nHealth: 9,999,887")
			assert_eq(screen.model.unit(2)["health"], 9999887)
			screen._play_event(
				{
					"type": "damage",
					"source": 101,
					"target": 2,
					"amount": 222,
					"raw": 222,
					"kind": "attack",
					"health_after": 9999665
				},
				false
			)
			assert_string_contains(
				notes.get_parsed_text(),
				"Health: 9,999,665",
				"open details follow live damage without another tap"
			)
		viewport.free()
