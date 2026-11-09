class_name StatFraction
extends RefCounted
## Integer ratios survive content loading and never double on golden.


static func part(value: int, numerator: int, denominator: int = 100) -> int:
	@warning_ignore("integer_division")
	return maxi(0, value) * maxi(0, numerator) / maxi(1, denominator)


static func loss(value: int, params: Dictionary, flat_key: String) -> int:
	return (
		part(value, CoreUtil.to_int(params["percent"]))
		if params.has("percent")
		else CoreUtil.to_int(params.get(flat_key, 0))
	)


static func apply(step: Dictionary, targets: Array[BoardUnit], world: EffectWorld) -> void:
	var stat: String = str(step.get("stat", "both"))
	var operation: String = str(step.get("operation", "set"))
	var numerator: int = CoreUtil.to_int(step.get("numerator", 1))
	var denominator: int = CoreUtil.to_int(step.get("denominator", 2))
	for target: BoardUnit in targets:
		var attack: int = (
			delta(target.attack, numerator, denominator, operation, 0) if stat != "health" else 0
		)
		var health: int = (
			delta(target.health, numerator, denominator, operation, 1) if stat != "attack" else 0
		)
		world.buff(target, attack, health, str(step.get("duration", world.default_duration())))


static func delta(
	value: int, numerator: int, denominator: int, operation: String, floor_value: int
) -> int:
	var amount: int = part(value, numerator, denominator)
	if operation == "gain":
		return amount
	var next: int = value - amount if operation == "reduce" else amount
	return maxi(floor_value, next) - value


static func attack_before_auras(unit: BoardUnit) -> int:
	return clampi(
		unit.base_attack_now() + unit.perm_attack + unit.tribe_attack + unit.combat_attack,
		0,
		BoardUnit.STAT_CLAMP
	)
