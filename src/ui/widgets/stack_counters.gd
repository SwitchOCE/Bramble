extends "res://src/ui/widgets/tribe_bonuses.gd"
## Portrait-and-number counters share two rows of the hero bar.


func _place() -> void:
	_caption.hide()
	var cursor: float = 0.0
	for column: int in ceili(chips.size() / 2.0):
		var column_width: float = 0.0
		for row: int in 2:
			var index: int = column * 2 + row
			if index >= chips.size():
				continue
			var chip: Control = chips[index]
			var engine: Label = chip.get_node_or_null("Engine") as Label
			var width: float = 76.0
			if engine != null:
				width = 64.0 if chip.name == "Midsummer" else 112.0
				engine.size.x = width - 16.0
			else:
				var bonus: Label = chip.get_node("Bonus") as Label
				bonus.text = bonus.text.get_slice("/", 0).trim_prefix("+")
				var font: Font = bonus.get_theme_font("font")
				width = maxf(
					width,
					font.get_string_size(bonus.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 31).x + 48.0
				)
				bonus.size.x = width - 46.0
			chip.position = Vector2(cursor, row * 44)
			chip.size = Vector2(width, 40)
			column_width = maxf(column_width, width)
		cursor += column_width + 6.0
