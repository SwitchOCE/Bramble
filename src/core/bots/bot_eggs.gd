class_name BotEggs
extends RefCounted
## Nests stay in their slots. Their Eggs appear only while no recruit covers them.


static func specs(player: PlayerState) -> Dictionary:
	var out: Dictionary = {}
	for entry: Dictionary in player.away:
		var slot: int = CoreUtil.to_int(entry.get("nest", -1))
		if BoardGeometry.is_valid(slot):
			var bird: RecruitUnit = entry["unit"]
			out[slot] = HeldUnits.egg_spec(bird)
	return out


static func worth(player: PlayerState, slot: int) -> float:
	var egg: Dictionary = specs(player).get(slot, {})
	return CoreUtil.to_int(egg.get("attack", 0)) + CoreUtil.to_int(egg.get("health", 0))


static func playable(player: PlayerState, unit: RecruitUnit, value: BotEval, slot: int) -> bool:
	if player.board[slot] != null:
		return false
	if not value.level.reads_text or player.nest_at(slot).is_empty():
		return true
	if value.keep_value(unit) <= worth(player, slot) + value.level.replace_margin:
		return false
	if value.has_flag(unit.def_id(), "on_nest"):
		return true
	for other: int in BoardGeometry.SLOTS:
		if player.board[other] == null and player.nest_at(other).is_empty():
			return false
	return true


static func preserve(player: PlayerState, layout: Array[int], pinned: Array[int]) -> void:
	for slot: Variant in specs(player):
		var nest: int = CoreUtil.to_int(slot)
		if layout[nest] < 0 or pinned.has(nest):
			continue
		var unit: RecruitUnit = player.board[layout[nest]]
		if unit.has_mechanic_id("lump") or unit.has_mechanic_id("dunnock"):
			continue
		for other: int in BoardGeometry.SLOTS:
			if layout[other] < 0 and not pinned.has(other) and player.nest_at(other).is_empty():
				layout[other] = layout[nest]
				layout[nest] = -1
				break
