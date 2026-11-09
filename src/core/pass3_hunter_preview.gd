class_name Pass3HunterPreview
extends RefCounted
## The reader and Hard share one non-random forecast of the recorded scout's marks.


static func attach(player: PlayerState, board: Array, config: GameConfig) -> void:
	if player.scout.is_empty() or not BotHunt.active(player):
		return
	var layout: Array[int] = [0, 1, 2, 3, 4, 5, 6]
	var forecast: Dictionary = BotHunt.forecast(player, layout)
	var marks: Array = forecast["marks"]
	var owners: Dictionary = forecast["owners"]
	var repeats: int = 1
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		var strength: int = Pass3Hunters.factor(unit, "laird")
		if strength > 0:
			var key: String = (
				"hunters_golden_laird_multiplier" if strength > 1 else "hunters_laird_multiplier"
			)
			repeats = maxi(repeats, Pass3Rates.integer(config, key))
	for slot: int in board.size():
		var marked: Dictionary = marks[slot]
		if board[slot] == null or marked.is_empty():
			continue
		var source: RecruitUnit = player.board[slot]
		var prey: Dictionary = marked
		var preview: Dictionary = {
			"name": str(prey.get("name", "Enemy")),
			"owner_slot": owners.get(CoreUtil.to_int(prey["hunt_identity"]), -1),
			"attack": 0,
			"health": 0
		}
		for ability: String in ["nip", "sable", "lutra"]:
			var strength: int = Pass3Hunters.factor(source, ability)
			if strength <= 0:
				continue
			var share: float = Pass3Rates.number(config, "hunters_" + ability + "_share")
			if strength > 1:
				share *= Pass3Rates.number(config, "hunters_golden_take_multiplier")
			var minimum: int = Pass3Rates.integer(config, "hunters_take_floor")
			preview["attack"] = (
				maxi(minimum, floori(CoreUtil.to_int(prey.get("attack", 0)) * share)) * repeats
			)
			preview["health"] = (
				maxi(minimum, floori(CoreUtil.to_int(prey.get("health", 0)) * share)) * repeats
			)
		board[slot]["hunter_take_preview"] = preview
