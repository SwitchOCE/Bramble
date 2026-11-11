extends GutTest
## Exercise the actual drawn contour and Godot's GUI picking where row rectangles overlap.

const Card := preload("res://src/ui/widgets/card_view.gd")
const Board := preload("res://src/ui/widgets/board_view.gd")
const Shape := preload("res://src/ui/widgets/hex_shape.gd")
const Layout := preload("res://tests/ui/layout_check.gd")
const Settings := preload("res://src/ui/settings.gd")


func after_each() -> void:
	Settings.reset()


func test_contour_fits_arbitrary_caller_boxes_and_input_matches_rounded_paint() -> void:
	for extent: Vector2 in [Vector2(176, 226), Vector2(270, 297), Vector2(200, 150)]:
		var card := Card.new()
		add_child_autofree(card)
		card.set_card_size(extent)
		var face: Rect2 = card.face_rect()
		assert_almost_eq(face.size.x / face.size.y, 0.78, 0.001)
		assert_true(Rect2(Vector2.ZERO, extent).encloses(face))
		assert_true(card._has_point(face.get_center()))
		assert_false(card._has_point(face.position + Vector2(2, 2)))
		for point: Vector2 in Shape.polygon(face.grow(-2)):
			assert_true(card._has_point(point), "the rounded painted edge takes input")
		card.can_drop_fn = func(_data: Variant, _zone: String, _index: int) -> bool: return true
		assert_true(card._can_drop_data(face.get_center(), {}))
		assert_false(card._can_drop_data(face.position, {}), "cut corners cannot steal drops")


func test_packing_keeps_front_rows_facing_and_real_hexes_separate() -> void:
	for front_on_top: bool in [true, false]:
		var board := Board.new()
		add_child_autofree(board)
		board.configure("board", 196, front_on_top)
		for slot: int in 7:
			var card := Card.new()
			card.show_unit({"def_id": "mrs_jay", "attack": 999, "health": 999})
			board.place_card(card, slot)
		var front: Card = board.cards[0]
		var back: Card = board.cards[4]
		assert_lt(absf(back.position.y - front.position.y), front.size.y)
		assert_eq(front.position.y < back.position.y, front_on_top)
		assert_almost_eq(back.position.x - front.position.x, (board.pocket.x + board.gap) / 2, 0.01)
		for i: int in 7:
			for j: int in range(i + 1, 7):
				assert_almost_eq(
					Layout._shared_face_area(board.cards[i], board.cards[j]), 0.0, 0.01
				)
		# A real overlap still fails the shape-aware guard.
		back.position = front.position
		assert_gt(Layout._shared_face_area(front, back), 1000.0)


func test_native_gui_picking_ignores_the_neighbours_cut_corner() -> void:
	Settings.reduce_motion = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1000, 700)
	viewport.handle_input_locally = true
	add_child_autofree(viewport)
	var board := Board.new()
	viewport.add_child(board)
	board.configure("board", 176, true)
	var taps: Array[int] = []
	for slot: int in 7:
		var card := Card.new()
		card.index = slot
		card.tapped.connect(func(_zone: String, index: int) -> void: taps.append(index))
		card.show_unit({"def_id": "mrs_jay", "attack": 2, "health": 3})
		board.place_card(card, slot)
	await get_tree().process_frame
	# Search the tucked rectangle intersections for a point painted by only one card.
	var a: Card = board.cards[0]
	var b: Card = board.cards[4]
	var picked: bool = false
	var shared: Rect2 = a.get_rect().intersection(b.get_rect())
	for y: int in range(ceili(shared.position.y), floori(shared.end.y), 2):
		for x: int in range(ceili(shared.position.x), floori(shared.end.x), 2):
			var point := Vector2(x, y)
			if not a._has_point(point - a.position) or b._has_point(point - b.position):
				continue
			for pressed: bool in [true, false]:
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = pressed
				event.position = point
				viewport.push_input(event, true)
			picked = true
			break
		if picked:
			break
	assert_true(picked, "the tucked rectangles provide a real ambiguous point")
	assert_eq(taps, [0], "Godot delivers the click to the painted hex behind the cut corner")
	a.selected = true
	var rim: Control = a.get("_focus_rim")
	assert_gt(rim.z_index, b.z_index, "focus ink paints above the tucked neighbour")


func test_three_digit_badges_widen_without_losing_exact_digits_or_the_font_floor() -> void:
	var card := Card.new()
	card.theme = preload("res://src/ui/ui_theme.gd").get_theme()
	add_child_autofree(card)
	card.show_unit({"def_id": "mrs_jay", "attack": 1, "health": 1}, Card.Mode.BOARD)
	card.set_card_size(Vector2(176, 226))
	var narrow: float = card.attack_bead().size.x
	card.set_stats(999, 888, 888)
	assert_gt(card.attack_bead().size.x, narrow)
	for field: String in ["_attack_label", "_health_label"]:
		var number: Label = card.get(field)
		assert_eq(number.text, "999" if field == "_attack_label" else "888")
		assert_gte(number.get_theme_font_size("font_size"), 31)
		var badge: Card.ShapeBadge = number.get_parent()
		assert_lte(
			(
				number
				. get_theme_font("font")
				. get_string_size(
					number.text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					number.get_theme_font_size("font_size")
				)
				. x
			),
			badge.inner_width()
		)


func test_selection_hover_and_golden_have_separate_visible_cues() -> void:
	Settings.reduce_motion = true
	var card := Card.new()
	add_child_autofree(card)
	card.show_unit({"def_id": "mrs_jay", "attack": 3, "health": 3})
	card.set_card_width(176)
	var plain_art: Rect2 = card._art.get_rect()
	assert_false(card._focus_rim.visible, "rest has no focus ring")
	card._set_hover_lift(true)
	assert_false(card._focus_rim.visible, "hover never acquires a selection ring")
	assert_gt(card.scale.x, 1.0, "hover raises the face")
	assert_gt(card._hover_lift, 0.0, "hover also expands the contact shadow")
	card.selected = true
	assert_true(card._focus_rim.visible, "selection has an actual foreground paint layer")
	assert_eq(card.selection_color, Card.UiTheme.SELECT)
	assert_gt(card.selection_color.r, 0.95)
	assert_gt(card.selection_color.g, 0.95)
	assert_ne(card.selection_color, Card.UiTheme.GILT)
	card.selected = false
	card._set_hover_lift(false)
	assert_false(card._focus_rim.visible)
	assert_eq(card.scale, Vector2.ONE)
	assert_eq(card._hover_lift, 0.0)
	card.show_unit({"def_id": "mrs_jay", "attack": 6, "health": 6, "golden": true})
	assert_false(card._focus_rim.visible, "gilt is permanent material, not a focus ring")
	assert_gt(card._art.position.x, plain_art.position.x, "portrait leaves room for full gilt")
	assert_eq(card._face(), Card.GOLDEN_PAPER)
	card.outline = Card.UiTheme.TRIPLE_WARN
	assert_true(card._focus_rim.visible, "triple warning has actual foreground paint")
	assert_ne(card.outline, card.selection_color)
	assert_ne(card.outline, Card.UiTheme.GILT)
