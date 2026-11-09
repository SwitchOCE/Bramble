extends BotBrain
## Hard's recruit decisions, followed by the same blind final placer used by field lines.


func _arrange() -> void:
	var scout: Dictionary = _player.scout
	_player.scout = {}
	BotPlacer.arrange(_player, _rules, value, BotLevel.PLACE_RULE, 0)
	_player.scout = scout
