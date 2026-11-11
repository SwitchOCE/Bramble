extends "res://src/ui/widgets/board_view.gd"
## Screen sizing adapter. The shared board still owns slots, row packing, marks and input.
## A4 can change that packing without changing the screen's frame or the object's drawn size.

const ArenaGeometry := preload("res://src/ui/arena_geometry.gd")


func tile_width() -> float:
	return ArenaGeometry.UNIT.x


func card_position(slot: int) -> Vector2:
	return slot_position(slot) + (pocket - ArenaGeometry.UNIT) / 2.0 - Vector2(0, 6)


func _layout() -> void:
	super()
	ArenaGeometry.fit_cards(self)


func place_card(card: CardView, slot: int) -> void:
	super(card, slot)
	card.set_card_size(ArenaGeometry.UNIT)
