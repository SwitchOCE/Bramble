extends "res://tools/league/gd/standin_fights.gd"
## Supplemental stock-generator cases with an initially populated Compost.
## Uses the inherited generator/oracle unchanged, and its RNG in this exact order.
## Run with the same -- cases=... out=... count=... seed=... folders=shared,thorn arguments.


func _make_player(game: GameSession, player_id: int, board_count: int) -> Dictionary:
	var saved: Dictionary = super._make_player(game, player_id, board_count)
	var compost := CardHeap.new()
	for _entry: int in _generator_rng.range_int(0, 24):
		var card_id: StringName = _unit_ids[_generator_rng.index(_unit_ids.size())]
		var definition: UnitDef = _generator_content.library.get_card(card_id)
		compost.add(card_id, definition.tier)
	saved["heaps"]["thorn_compost"] = RecordState.value(compost)
	return saved
