class_name TomTitAura
extends Mechanic
## Every Egg receives only the strongest Tom Tit aura, after its Redwing body is established.


static func egg_aura(combat: Combat, egg: CombatUnit) -> Vector2i:
	var bonus := Vector2i.ZERO
	for source: CombatUnit in combat.units_of(egg.side):
		for index: int in source.mechanic_ids.size():
			if source.mechanic_ids[index] != "tom_tit":
				continue
			var params: Dictionary = source.params[index]
			bonus.x = maxi(bonus.x, CoreUtil.to_int(params.get("attack", 1)))
			bonus.y = maxi(bonus.y, CoreUtil.to_int(params.get("health", 1)))
	return bonus
