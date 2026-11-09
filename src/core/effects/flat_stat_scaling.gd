class_name FlatStatScaling
extends RefCounted
## One flat point becomes X% of the recipient, keeping the original as an early-game floor.


static func gains(target: BoardUnit, attack: int, health: int, world: EffectWorld) -> Vector2i:
	var rate: int = world.flat_gain_percent()
	if rate <= 0:
		return Vector2i(attack, health)
	var baseline: Vector2i = (
		Vector2i(target.attack, target.health) if target != null else board_baseline(world)
	)
	return Vector2i(
		scaled_amount(attack, baseline.x, rate), scaled_amount(health, baseline.y, rate)
	)


static func scaled_amount(flat: int, baseline: int, rate: int) -> int:
	return maxi(flat, StatFraction.part(baseline, rate * flat)) if flat > 0 else flat


static func board_baseline(world: EffectWorld) -> Vector2i:
	var total_attack: int = 0
	var total_health: int = 0
	var count: int = 0
	for unit: BoardUnit in world.own:
		if unit != null and unit.health > 0:
			total_attack += unit.attack
			total_health += unit.health
			count += 1
	@warning_ignore("integer_division")
	return Vector2i(total_attack / maxi(1, count), total_health / maxi(1, count))


static func slot_step(
	step: Dictionary, targets: Array[BoardUnit], world: EffectWorld
) -> Dictionary:
	if world is RecruitContext and str(step.get("name", "")) == BoardUpkeep.RING:
		var ctx: RecruitContext = world
		if ctx.player.pass3_fairies:
			return step
	if world.flat_gain_percent() <= 0:
		return step
	var out: Dictionary = step.duplicate(true)
	var target: BoardUnit = targets[0] if not targets.is_empty() else world.chosen
	var bonus: Vector2i = gains(
		target,
		CoreUtil.to_int(step.get("attack", 0)),
		CoreUtil.to_int(step.get("health", 0)),
		world
	)
	out["attack"] = bonus.x
	out["health"] = bonus.y
	return out
