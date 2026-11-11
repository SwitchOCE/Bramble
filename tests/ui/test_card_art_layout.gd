extends GutTest
## Art area is uniform across the shipped faces; state anchors do not move with the crop.

const CardView := preload("res://src/ui/widgets/card_view.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func _assert_art(card: CardView, context: String) -> void:
	var art: Control = card.get("_art")
	var face: Rect2 = card.face_rect()
	var share: float = art.size.x * art.size.y / face.get_area()
	assert_gte(share, 0.70, context + ": portrait covers the hex inside its paper rim")
	assert_true(art.hexagonal, context + ": portrait uses the shared contour")
	assert_almost_eq(face.size.x / face.size.y, 0.78, 0.001)
	assert_gte(art.size.y, CardView.ART_MIN)
	assert_true(Rect2(Vector2.ZERO, card.card_size).encloses(art.get_rect()), context)
	for field: String in ["_name_label", "_type_label", "_rules", "_chip", "_status_tag"]:
		var old_overlay: Control = card.get(field)
		assert_false(old_overlay.visible, context + ": no standing word overlay " + field)


func test_art_share_stays_in_range_for_shop_board_and_mini_at_phone_and_board_widths() -> void:
	for mode: CardView.Mode in [CardView.Mode.SHOP, CardView.Mode.BOARD, CardView.Mode.MINI]:
		for width: float in [96.0, 122.0, 163.0, 189.0, 209.0, 270.0]:
			var card: CardView = CardView.new()
			card.theme = UiTheme.get_theme()
			card.show_unit(
				{"def_id": "mrs_jay", "name": "Mrs Jay", "attack": 12, "health": 19}, mode
			)
			card.set_card_width(width)
			add_child_autofree(card)
			_assert_art(card, "mode %d width %s" % [mode, width])
			if mode == CardView.Mode.BOARD:
				card.set_card_size(card.card_size + Vector2(0, 40))
				_assert_art(card, "taller board width %s" % width)


func test_all_shipped_units_keep_wordless_art_share_and_fixed_stats_with_golden_combat_marks(
) -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var units: Array[Dictionary] = []
	var card_set: String = GameConfig.full_game().card_set()
	for definition: Dictionary in library.all_units():
		if str(definition.get("set", "")) == card_set:
			units.append(definition)
	assert_gt(units.size(), 100, "exercise the shipped set rather than the legacy prototype set")
	for unit: Dictionary in units:
		var card: CardView = CardView.new()
		card.theme = UiTheme.get_theme()
		card.show_unit(UnitViews.from_def(unit), CardView.Mode.BOARD)
		card.set_card_size(Vector2(189, 212))
		add_child_autofree(card)
		assert_false(
			CardView.needs_name(card.unit), str(unit["id"]) + ": shipped art identifies it"
		)
		_assert_art(card, str(unit["id"]))
		var attack: Control = card.attack_bead()
		var health: Control = card.health_bead()
		var attack_anchor: Rect2 = attack.get_rect()
		var health_anchor: Rect2 = health.get_rect()
		var golden: Dictionary = UnitViews.from_def(unit, true)
		golden["keywords"] = ["Mire", "Quarry", "Swoop"]
		golden["statuses"] = [{"status": "shield"}, {"status": "shell"}]
		card.combat_face = true
		card.show_unit(golden, CardView.Mode.BOARD)
		_assert_art(card, str(unit["id"]) + " golden combat")
		assert_eq(attack.get_rect(), attack_anchor, "Attack stays at its fixed corner")
		assert_eq(health.get_rect(), health_anchor, "Health stays at its fixed corner")
		var marks: Control = card.get("_combat_marks")
		assert_gt(attack.z_index, marks.z_index, "status drawings stay behind combat stats")
		assert_gt(health.z_index, marks.z_index)
		assert_lt(attack.position.x, card.card_size.x * 0.2)
		assert_almost_eq(health.get_rect().end.x, card.face_rect().end.x, 0.01)
		card.queue_free()
	await get_tree().process_frame
