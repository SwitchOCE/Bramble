extends GutTest
## Current counter pips remain readable inside a card and clear both stat beads.

const CardView := preload("res://src/ui/widgets/card_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func test_counter_box_and_number_clear_stat_beads_at_narrow_and_full_card_sizes() -> void:
	for in_combat: bool in [false, true]:
		for dimensions: Vector2 in [
			Vector2(96, 116),
			Vector2(146, 166),
			Vector2(163, 187),
			Vector2(189, 212),
			Vector2(270, 297)
		]:
			for count: int in [1, 17, 123456]:
				var card: CardView = CardView.new()
				card.theme = UiTheme.get_theme()
				card.combat_face = in_combat
				card.show_unit(
					{
						"def_id": "mrs_posset",
						"name": "Mrs Posset",
						"attack": 1,
						"health": 2,
						"held": count,
						"text": "After a spell gives this stats: grow what's inside."
					},
					CardView.Mode.BOARD
				)
				card.set_card_size(dimensions)
				card.position = Vector2(200, 150)
				card.scale = Vector2.ONE * 1.1
				add_child_autofree(card)
				var face: Control = card.get("_combat_marks")
				var counter: Label = face.get("counter")
				var pip: Rect2 = face.get("_counter_rect")
				var global_pip: Rect2 = face.get_global_transform() * pip
				assert_true(counter.visible, "the current count remains visible")
				assert_true(card.get_global_rect().encloses(global_pip), str(dimensions))
				assert_true(
					global_pip.grow(0.01).encloses(counter.get_global_rect()),
					(
						"number stays in its pip %s: %s vs %s"
						% [dimensions, global_pip, counter.get_global_rect()]
					)
				)
				assert_lte(pip.size.x, 64.0)
				assert_gte(counter.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
				assert_lte(
					(
						counter
						. get_theme_font("font")
						. get_string_size(
							counter.text,
							HORIZONTAL_ALIGNMENT_LEFT,
							-1,
							counter.get_theme_font_size("font_size")
						)
						. x
					),
					counter.size.x,
					"counter text fits at the shared font minimum"
				)
				for key: String in ["_attack_badge", "_health_badge"]:
					var bead: Control = card.get(key)
					assert_false(
						global_pip.intersects(bead.get_global_rect()), str(dimensions) + key
					)
