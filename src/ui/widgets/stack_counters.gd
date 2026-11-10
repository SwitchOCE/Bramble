extends "res://src/ui/widgets/tribe_bonuses.gd"
## Counters share the hero bar, two compact rows instead of a second HUD strip.


func _place() -> void:
	_caption.hide()
	for index: int in chips.size():
		var chip: Control = chips[index]
		chip.position = Vector2(floori(index / 2.0) * 120, (index % 2) * 44)
		chip.size = Vector2(112, 40)
		var engine: Label = chip.get_node_or_null("Engine") as Label
		if engine != null:
			engine.size.x = 96
		else:
			var bonus: Label = chip.get_node("Bonus") as Label
			bonus.text = bonus.text.get_slice("/", 0).trim_prefix("+")
			bonus.size.x = 64
