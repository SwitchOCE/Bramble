extends "res://src/ui/widgets/hand_fan.gd"
## An exposed reserve row on the player's table. Every identity has its own stable hit rectangle.


func arrange() -> void:
	for value: Variant in cards.duplicate():
		if not is_instance_valid(value):
			cards.erase(value)
	if cards.is_empty() or size.x <= 0.0:
		return
	var tile: Vector2 = cards[0].card_size
	var pitch: float = tile.x + 12.0
	var left: float = maxf(0.0, (size.x - (cards.size() * pitch - 12.0)) / 2.0)
	for index: int in cards.size():
		var card: CardView = cards[index]
		var at := Vector2(left + index * pitch, FOCUS_LIFT)
		_homes[card] = at
		card.position = at
		card.rotation = 0.0
		card.z_index = 0
	if focused_index >= 0:
		focus(focused_index)
