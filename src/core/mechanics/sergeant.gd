extends Mechanic
## Sergeant-at-Conkers: Start of Combat, throw your smallest Acorn item at the enemy across:
## `damage` per gold it's worth. It's spent after the fight. No enemy there: it stays in hand.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(unit.slot))
	if enemy == null:
		return
	var gold: int = CombatMoves.take_ammo(combat, unit.side)
	if gold > 0:
		combat.trigger(unit, "sergeant")
		combat.deal_effect_damage(unit, enemy, gold * CoreUtil.to_int(params.get("damage", 0)))
