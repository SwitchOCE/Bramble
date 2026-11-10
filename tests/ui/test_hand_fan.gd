extends GutTest
## All ten tiles remain directly accessible; a fan changes stacking, never canonical hand indices.

const Fan := preload("res://src/ui/widgets/hand_fan.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Views := preload("res://src/ui/unit_views.gd")
const Fixture := preload("res://src/ui/adapter/fixture_port.gd")
const Screen := preload("res://src/ui/screens/recruit_screen.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const SHIPPED_IDS: PackedStringArray = [
	"old_moth_annis",
	"mrs_sorrel",
	"one_swallow",
	"mrs_jay",
	"little_nip",
	"wick",
	"old_moth_annis",
	"mrs_sorrel",
	"one_swallow",
	"mrs_jay"
]


func after_each() -> void:
	Card.window_override = Vector2.ZERO


static func hand_views(count: int = 10) -> Array:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var hand: Array = []
	for index: int in count:
		var view: Dictionary = Views.from_def(
			library.get_unit(SHIPPED_IDS[index]), false, 900 + index
		)
		view["iid"] = 900 + index
		hand.append(view)
	return hand


func _viewport(pixels: Vector2) -> SubViewport:
	Card.window_override = pixels
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(1080.0 * pixels.x / pixels.y), 1080)
	viewport.gui_disable_input = false
	add_child_autofree(viewport)
	return viewport


func _fan(viewport: SubViewport) -> Fan:
	var fan := Fan.new()
	viewport.add_child(fan)
	fan.position = Vector2(100, 100)
	fan.size = Vector2(331, 337)
	var hand: Array = hand_views()
	for index: int in hand.size():
		var card := Card.new()
		var view: Dictionary = hand[index]
		card.show_unit(view, Card.Mode.MINI)
		card.set_card_size(Vector2(130, 130))
		card.zone = "hand"
		card.index = index
		card.drag_data_fn = func(zone: String, at: int) -> Variant:
			return {"zone": zone, "index": at}
		fan.add_card(card)
	return fan


func _screen(pixels: Vector2, count: int, away: bool) -> Screen:
	var viewport: SubViewport = _viewport(pixels)
	var port := Fixture.new()
	var archive: Dictionary = Fixture.load_json(
		"res://docs/ideation/evidence/declutter/batch2/states.json"
	)
	var overview: Dictionary = archive["overview"]
	var initial: Dictionary = overview["state"]
	var state: Dictionary = initial.duplicate(true)
	state["hand"] = hand_views(count)
	state["hand_items"] = []
	if not away:
		state["away"] = []
		state["doorstep"] = []
	port.set("_state", state)
	var screen := Screen.new()
	viewport.add_child(screen)
	screen.setup(port)
	return screen


func test_ten_real_cards_fit_and_keep_canonical_indices_after_each_focus() -> void:
	var viewport: SubViewport = _viewport(Vector2(1688, 780))
	var fan: Fan = _fan(viewport)
	await wait_process_frames(2)
	assert_eq(fan.cards.size(), 10)
	assert_eq(fan.get_child_count(), 10, "there is no +N picker hiding hand cards")
	for index: int in 10:
		var card: Card = fan.card_at(index)
		assert_true(card.is_visible_in_tree())
		assert_eq(card.card_size, Vector2(130, 130))
		assert_true(fan.get_global_rect().encloses(card.get_global_rect()))
		fan.focus(index)
		assert_eq(fan.get_child(9), card, "the focused card owns input and drawing precedence")
		for canonical: int in 10:
			assert_eq(fan.card_at(canonical).index, canonical, "focus never changes action indices")


func test_each_visible_card_can_be_tapped_and_dragged_without_a_picker() -> void:
	var viewport: SubViewport = _viewport(Vector2(1688, 780))
	var fan: Fan = _fan(viewport)
	await wait_process_frames(2)
	var tapped: Array[int] = []
	for card: Card in fan.cards:
		card.tapped.connect(func(_zone: String, index: int) -> void: tapped.append(index))
	for index: int in 10:
		fan.rest_cards()
		var card: Card = fan.card_at(index)
		# Reverse stacking exposes each lower tier's own numeric foot.
		var at: Vector2 = card.get_global_rect().end - Vector2(card.size.x / 2, 10)
		for pressed: bool in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			click.position = at
			click.global_position = at
			viewport.push_input(click, true)
		assert_false(tapped.is_empty(), "the viewport tap reaches a card")
		if not tapped.is_empty():
			assert_eq(
				CoreUtil.to_int(tapped.back()),
				index,
				"a real viewport tap selects every exposed card"
			)
		var drag: Variant = card._get_drag_data(Vector2(20, 20))
		assert_true(drag is Dictionary)
		if drag is Dictionary:
			var data: Dictionary = drag
			assert_eq(str(data["zone"]), "hand")
			assert_eq(CoreUtil.to_int(data["index"]), index)


func test_normal_hand_sizes_stay_identical_when_birds_are_away() -> void:
	for pixels: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		for count: int in [1, 2, 10]:
			var home: Screen = _screen(pixels, count, false)
			var away: Screen = _screen(pixels, count, true)
			await wait_process_frames(2)
			var first: Fan = home.get("_hand_cards")
			var second: Fan = away.get("_hand_cards")
			assert_eq(first.cards.size(), count)
			assert_eq(second.cards.size(), count)
			assert_eq(first.card_at(0).card_size, second.card_at(0).card_size)
			assert_eq(first.size, second.size, "journeys do not shrink the hand")


func test_full_hand_and_away_tokens_stay_clear_of_actions_board_and_open_reader_at_both_sizes(
) -> void:
	for pixels: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		var screen: Screen = _screen(pixels, 10, true)
		await wait_process_frames(3)
		var fan: Fan = screen.get("_hand_cards")
		var hand_zone: Control = screen.get("_hand_zone")
		var tray: Control = screen.get("_away_tray")
		var board: Control = screen.get("_board")
		assert_false(hand_zone.get_global_rect().intersects(board.get_global_rect()))
		assert_false(hand_zone.get_global_rect().intersects(tray.get_global_rect()))
		for key: String in [
			"_gold", "_end_button", "_tier_button", "_refresh_button", "_freeze_button"
		]:
			var action: Control = screen.get(key)
			assert_false(hand_zone.get_global_rect().intersects(action.get_global_rect()), key)
			assert_false(tray.get_global_rect().intersects(action.get_global_rect()), key)
		screen._on_tapped("hand", 9)
		await wait_process_frames(2)
		assert_eq(fan.cards.size(), 10, "opening a reader never replaces the fan")
		for index: int in 10:
			assert_true(screen._card_at("hand", index) == fan.card_at(index))
		assert_eq(LayoutCheck.problems(screen, "fan10 with reader and Birds"), PackedStringArray())


func test_pc_hand_reader_selection_and_hover_leave_the_stack_stable() -> void:
	var screen: Screen = _screen(Vector2(1920, 1080), 10, true)
	await wait_process_frames(3)
	var hand: Control = screen.get("_hand_zone")
	var board: Control = screen.get("_board")
	var reader: Control = screen.get("_detail")
	var original_hand: Rect2 = hand.get_global_rect()
	var original_board: Rect2 = board.get_global_rect()
	for index: int in [0, 9]:
		screen._on_tapped("hand", index)
		await wait_process_frames(2)
		assert_true(reader.visible)
		assert_eq(hand.get_global_rect(), original_hand)
		assert_eq(board.get_global_rect(), original_board)
		screen._on_tapped("table", -1)
		screen._on_hovered("hand", index, true)
		screen._show_hover()
		await wait_process_frames(2)
		assert_true(reader.visible)
		assert_eq(hand.get_global_rect(), original_hand)
		assert_eq(board.get_global_rect(), original_board)
		screen._on_hovered("hand", index, false)
		screen._end_hover()


func _number_text_rect(label: Label) -> Rect2:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var scale: Vector2 = label.get_global_transform().get_scale().abs()
	var text_size := (
		Vector2(
			font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x,
			font.get_height(font_size)
		)
		* scale
	)
	return Rect2(label.get_global_rect().get_center() - text_size / 2, text_size)


func test_all_twenty_hand_stat_text_rects_remain_readable_in_the_resting_fan() -> void:
	for pixels: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		var screen: Screen = _screen(pixels, 10, true)
		await wait_process_frames(3)
		var fan: Fan = screen.get("_hand_cards")
		fan.rest_cards()
		var labels_checked: int = 0
		for card: Card in fan.cards:
			for stat: String in ["_attack_label", "_health_label"]:
				var label: Label = card.get(stat)
				assert_true(label.is_visible_in_tree())
				assert_false(label.text.is_empty())
				assert_gte(label.get_theme_font_size("font_size"), 31)
				var text: Rect2 = _number_text_rect(label)
				for higher: Card in fan.cards:
					if higher.get_index() <= card.get_index():
						continue
					var face: Rect2 = higher.get_global_rect().grow_individual(0, 0, 0, Card.EDGE)
					assert_false(
						text.intersects(face),
						"hand %d %s is not covered by a higher card face" % [card.index, stat]
					)
					for other_stat: String in ["_attack_label", "_health_label"]:
						var other_label: Label = higher.get(other_stat)
						assert_false(
							text.intersects(_number_text_rect(other_label)),
							(
								"hand %d %s does not collide with another bead's text"
								% [card.index, stat]
							)
						)
				labels_checked += 1
		assert_eq(labels_checked, 20, "every Attack and Health value was checked at rest")
