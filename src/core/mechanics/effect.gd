extends Mechanic
## The data-driven mechanic: {"id": "effect", "trigger", "if"?, "target"?, "do"} in a unit's
## mechanics list runs through EffectRunner. Most cards need nothing else. Format and worked
## examples: docs/ideation/engine.md.


func recruit_hook(ctx: RecruitContext) -> void:
	if str(ctx.params.get("trigger", "")) != ctx.trigger or not _subject_fits(ctx.params, ctx):
		return
	EffectRunner.run(ctx.params, ctx)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	_fire(combat, unit, params, "start_of_combat", null, 0)


func on_attack_declared(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit, defender: CombatUnit
) -> void:
	if unit == defender:
		_fire(combat, unit, params, "on_attacked", attacker, 0)


func on_before_attack(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	_fire(combat, unit, params, "on_attack", null, 0)


func on_damage_dealt(combat: Combat, unit: CombatUnit, params: Dictionary, hit: Hit) -> void:
	if hit.amount > 0:
		_fire(combat, unit, params, "on_damage_dealt", hit.target, hit.amount)


func on_damage_taken(combat: Combat, unit: CombatUnit, params: Dictionary, hit: Hit) -> void:
	if hit.amount > 0:
		_fire(combat, unit, params, "on_damage_taken", hit.source, hit.amount)


func on_survived_attack(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit
) -> void:
	_fire(combat, unit, params, "on_survived_attack", attacker, 0)


func on_death(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	_fire(combat, unit, params, "on_death", null, 0)


func on_friendly_death(
	combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit
) -> void:
	_fire(combat, unit, params, "on_friendly_death", dead, 0)


func on_ally_summon(
	combat: Combat, unit: CombatUnit, params: Dictionary, summoned: CombatUnit
) -> void:
	_fire(combat, unit, params, "on_summon", summoned, 0)


func has_board_aura(params: Dictionary) -> bool:
	return str(params.get("trigger", "")) == "aura"


func board_aura(combat: Combat, unit: CombatUnit, params: Dictionary, out: Dictionary) -> void:
	var world := CombatWorld.make(combat, unit, unit.side, params, "aura")
	if not EffectConditions.all_hold(params, world):
		return
	for value: Variant in MechanicRegistry.steps_of(params):
		var step: Dictionary = value
		var spec: Dictionary = step.get("target", params.get("target", {}))
		var bonus := Vector2i(
			CoreUtil.to_int(step.get("attack", 0)), CoreUtil.to_int(step.get("health", 0))
		)
		for target: BoardUnit in TargetSelect.pick(spec, world):
			var fighter: CombatUnit = target
			var so_far: Vector2i = out.get(fighter.uid, Vector2i.ZERO)
			out[fighter.uid] = so_far + bonus


static func _fire(
	combat: Combat,
	unit: CombatUnit,
	params: Dictionary,
	trigger: String,
	subject: CombatUnit,
	amount: int
) -> void:
	if str(params.get("trigger", "")) != trigger:
		return
	var world := CombatWorld.make(combat, unit, unit.side, params, trigger)
	world.amount = amount
	if subject != null:
		world.set_subject(subject)
	if _subject_fits(params, world):
		EffectRunner.run(params, world)


## "subject" ("self", "other", "any") and "subject_tribe" narrow whose event this hears.
static func _subject_fits(params: Dictionary, world: EffectWorld) -> bool:
	if world.subject == null:
		return true
	var who: String = str(params.get("subject", EffectSchema.default_subject(world.trigger)))
	if world.source != null:
		if who == "self" and world.subject != world.source:
			return false
		if who == "other" and world.subject == world.source:
			return false
	var tribe: String = str(params.get("subject_tribe", ""))
	return tribe == "" or world.subject.has_tribe(tribe)
