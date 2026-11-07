class_name MossOoze
extends Mechanic
## A spell's direct stat gift reaches the units inside its Ooze. The owner bonus has no buff
## event, so Harvest Supper never copies it. Inner gifts do not recursively count as spells.


static func share(
	player: PlayerState, target: RecruitUnit, attack: int, health: int, duration: String
) -> void:
	if not target.has_tribe("Oozes") or target.held.is_empty() or (attack <= 0 and health <= 0):
		return
	for source: RecruitUnit in player.board:
		if source == null:
			continue
		var factor: int = _factor(source)
		if factor <= 0:
			continue
		player.log_event("moss_copy", {"source": source.def_id(), "target": target.def_id()})
		for inner: RecruitUnit in target.held:
			if duration == "combat":
				inner.add_combat(attack * factor, health * factor)
			else:
				inner.add_permanent(attack * factor, health * factor)
			player.log_event(
				"buff",
				{
					"target": inner.def_id(),
					"attack": attack * factor,
					"health": health * factor,
					"duration": duration
				}
			)


static func _factor(unit: RecruitUnit) -> int:
	var factor: int = unit.mechanic_number("moss_ooze", "factor")
	for group: Array in [unit.grants, unit.borrowed_text()]:
		for grant: Dictionary in group:
			var entry: Dictionary = grant["entry"]
			if str(entry.get("id", "")) == "moss_ooze":
				var params: Dictionary = MechanicRegistry.params_for(
					entry, CoreUtil.to_bool(grant.get("golden", false))
				)
				factor += CoreUtil.to_int(params["factor"])
	return factor
