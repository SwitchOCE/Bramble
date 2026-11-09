extends Mechanic
## Synthetic dial: percent of each recipient's stats, or a flat amount, permanently.


func on_end_of_turn(ctx: RecruitContext) -> void:
	if not ctx.rules.config.get_bool("scale_levers") or ctx.source_slot < 0:
		return
	var config: GameConfig = ctx.rules.config
	var spec: Dictionary = (
		{"select": "self"}
		if config.get_bool("scale_engine_self")
		else {"select": "friendly", "tribe": config.get_string("scale_engine_tribe")}
	)
	var factor: int = ctx.source.golden_factor()
	ctx.announce("scale_engine")
	for unit: BoardUnit in TargetSelect.pick(spec, ctx):
		var flat: int = config.get_int("scale_engine_flat")
		var attack: int = (
			flat
			if flat > 0
			else StatFraction.part(unit.attack, config.get_int("scale_engine_percent"))
		)
		var health: int = (
			flat
			if flat > 0
			else StatFraction.part(unit.health, config.get_int("scale_engine_percent"))
		)
		ctx.buff(unit, attack * factor, health * factor, "permanent")
