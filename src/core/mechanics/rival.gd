extends Mechanic
## Rival (library entry 16): Start of Combat, the enemy across from this becomes its Rival. While
## the Rival lives this attacks only it, in either row, and the two deal double attack damage to
## each other. With no unit across, this has no Rival and fights normally.


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: Dictionary) -> void:
	var across: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(unit.slot))
	if across == null:
		return
	combat.trigger(unit, "rival")
	combat.set_status(unit, "rival", true, unit, {"uid": across.uid})


func choose_target(combat: Combat, unit: CombatUnit, _params: Dictionary) -> CombatUnit:
	return _rival_of(combat, unit)


func modify_damage_dealt(unit: CombatUnit, _params: Dictionary, hit: Hit) -> int:
	return _doubled(unit, hit.target, hit)


func modify_damage_taken(unit: CombatUnit, _params: Dictionary, hit: Hit) -> int:
	return _doubled(unit, hit.source, hit)


static func _doubled(unit: CombatUnit, other: CombatUnit, hit: Hit) -> int:
	if hit.kind != Hit.ATTACK or not unit.has_status("rival"):
		return hit.amount
	var data: Dictionary = unit.statuses["rival"]
	if CoreUtil.to_int(data.get("uid", -1)) != other.uid:
		return hit.amount
	hit.modifiers.append("rival")
	return hit.amount * 2


static func _rival_of(combat: Combat, unit: CombatUnit) -> CombatUnit:
	if not unit.has_status("rival"):
		return null
	var data: Dictionary = unit.statuses["rival"]
	var uid: int = CoreUtil.to_int(data.get("uid", -1))
	for enemy: CombatUnit in combat.units_of(1 - unit.side):
		if enemy.uid == uid:
			return enemy
	return null
