class_name Pass3Birds
extends RefCounted
## Homecoming changes the permanent body once, before listeners see the returned Bird.


static func ability(unit: RecruitUnit, name: String) -> bool:
	for one: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if one.id == "pass3_bird" and str(one.params.get("ability", "")) == name:
			return true
	return false


static func prepare(rules: RecruitRules, player: PlayerState) -> void:
	player.pass3_rates = Pass3Rates.resolved(rules.config)
	player.pass3_loop_guards = rules.config.get_value("pass3_loop_guards") != false
	for unit: RecruitUnit in player.all_units():
		if unit.has_mechanic_id("pass3_bird") or unit.has_mechanic_id("pass3_fairy"):
			player.pass3_content = true
			player.pass3_fairies = true
		if ability(unit, "stork"):
			unit.counters["stork_goal"] = Pass3Rates.integer(rules.config, "birds_stork_gold_step")
		if unit.has_mechanic_id("pass3_bird"):
			unit.set_meta("pass3_rates", player.pass3_rates)


static func missed_fight(player: PlayerState) -> void:
	for entry: Dictionary in player.away:
		entry["missed_fight"] = true


static func homecoming(rules: RecruitRules, player: PlayerState, unit: RecruitUnit) -> void:
	if not unit.has_mechanic_id("pass3_bird"):
		return
	if (
		player.pass3_loop_guards
		and CoreUtil.to_int(unit.counters.get("pass3_home_round", -1)) == player.round_number
	):
		return
	var key: String = (
		"birds_golden_homecoming_multiplier" if unit.golden else "birds_homecoming_multiplier"
	)
	multiply_body(unit, Pass3Rates.number(rules.config, key))
	unit.counters["pass3_home_round"] = player.round_number


static func multiply_body(unit: RecruitUnit, multiplier: float) -> void:
	var attack: int = maxi(0, unit.base_attack_now() + unit.perm_attack)
	var health: int = maxi(1, unit.base_health_now() + unit.perm_health)
	unit.add_permanent(ceili(attack * multiplier) - attack, ceili(health * multiplier) - health)


static func egg_problem(unit: RecruitUnit, guards: bool = true) -> String:
	if unit == null or not unit.has_tribe("Birds"):
		return "Choose a Bird"
	if guards and CoreUtil.to_bool(unit.counters.get("egged", false)):
		return "This Bird already had a Golden Egg"
	return ""


static func golden_egg(rules: RecruitRules, player: PlayerState, unit: RecruitUnit) -> void:
	if egg_problem(unit, player.pass3_loop_guards) != "":
		return
	multiply_body(unit, Pass3Rates.number(rules.config, "birds_golden_egg_multiplier"))
	unit.counters["egged"] = true
	player.log_event("trigger", {"mechanic": "golden_egg", "source": unit.def_id()})


static func recruit_hook(ctx: RecruitContext) -> void:
	var name: String = str(ctx.params.get("ability", ""))
	match name:
		"dunnock":
			_dunnock(ctx)
		"redbreast", "cuckoo":
			_share(ctx, name)
		"old_tern":
			if ctx.trigger == "on_home" and ctx.source == ctx.subject:
				HeldUnits.land_flock(ctx.rules, ctx.player)
		"stork":
			_stork(ctx)
		"goose":
			if ctx.trigger == "on_play" and ctx.source == ctx.subject:
				if Pass3Rates.enabled(ctx.rules.config, "birds_golden_egg_enabled"):
					ctx.add_card("golden_egg", _factor(ctx), false)


static func _dunnock(ctx: RecruitContext) -> void:
	if ctx.trigger != "end_of_turn" or (ctx.player.pass3_loop_guards and ctx.repeat_index > 0):
		return
	var ready: Array[Dictionary] = []
	for entry: Dictionary in ctx.player.away:
		if CoreUtil.to_int(entry["due"]) - ctx.player.round_number >= 2:
			ready.append(entry)
	ready.sort_custom(_biggest_away)
	var count: int = Pass3Rates.integer(ctx.rules.config, "birds_dunnock_targets") * _factor(ctx)
	for entry: Dictionary in ready.slice(0, count):
		var turns: int = Pass3Rates.integer(ctx.rules.config, "birds_dunnock_turns")
		entry["due"] = maxi(ctx.player.round_number + 1, CoreUtil.to_int(entry["due"]) - turns)
		ctx.announce("pass3_dunnock")


static func _share(ctx: RecruitContext, name: String) -> void:
	if ctx.trigger != "on_home" or ctx.subject == null or not ctx.subject.has_tribe("Birds"):
		return
	var landed: RecruitUnit = ctx.subject
	var share: float = (
		Pass3Rates.number(ctx.rules.config, "birds_" + name + "_share") * _factor(ctx)
	)
	var attack: int = ceili((landed.base_attack_now() + landed.perm_attack) * share)
	var health: int = ceili((landed.base_health_now() + landed.perm_health) * share)
	ctx.announce("pass3_" + name)
	if name == "redbreast":
		ctx.buff(ctx.source, attack, health, "")
	else:
		for target: RecruitUnit in ctx.player.board:
			if target != null and target != landed and target.has_tribe("Birds"):
				ctx.buff(target, attack, health, "")


static func _stork(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_gold_spent" or ctx.source_slot < 0:
		return
	var step: int = maxi(1, Pass3Rates.integer(ctx.rules.config, "birds_stork_gold_step"))
	var count: int = CoreUtil.to_int(ctx.source.counters.get("stork", 0)) + ctx.amount
	ctx.source.counters["stork"] = count % step
	@warning_ignore("integer_division")
	var recalls: int = count / step
	for _index: int in recalls:
		ctx.announce("pass3_stork")
		HeldUnits.bring_home(
			ctx.rules,
			ctx.player,
			Pass3Rates.integer(ctx.rules.config, "birds_stork_recalls") * _factor(ctx)
		)


static func recruit_aura(player: PlayerState, unit: RecruitUnit, params: Dictionary) -> Vector2i:
	if str(params.get("ability", "")) != "lump":
		return Vector2i.ZERO
	var nest: Dictionary = player.nest_at(player.board.find(unit))
	if nest.is_empty():
		return Vector2i.ZERO
	var bird: RecruitUnit = nest["unit"]
	var body: Dictionary = bird.combat_spec()
	var multiplier: float = (
		CoreUtil.to_float(player.pass3_rates.get("birds_lump_multiplier", 1.0))
		* unit.golden_factor()
	)
	return Vector2i(
		ceili(CoreUtil.to_int(body["attack"]) * multiplier),
		ceili(CoreUtil.to_int(body["health"]) * multiplier)
	)


static func _biggest_away(first: Dictionary, second: Dictionary) -> bool:
	var a: RecruitUnit = first["unit"]
	var b: RecruitUnit = second["unit"]
	return a.attack + a.health > b.attack + b.health


static func _factor(ctx: RecruitContext) -> int:
	return CoreUtil.to_int(ctx.params.get("factor", 2 if ctx.source.golden else 1))


## A bench may select the live pool without using full_game(). Content enables its fight rule.
static func detect_pool(rules: RecruitRules) -> void:
	for card: Dictionary in rules.library.pool_units(rules.config.card_set()):
		for entry: Dictionary in card["mechanics"]:
			if str(entry.get("id", "")) in ["pass3_bird", "pass3_fairy", "pass3_bog"]:
				rules.config.set_value("pass3_content", true)
				return


static func setup(rules: RecruitRules, player: PlayerState) -> void:
	player.pass3_content = rules.config.get_bool("pass3_content")
	player.pass3_fairies = player.pass3_content
	player.pass3_bog = player.pass3_content
	player.pass3_rates = Pass3Rates.resolved(rules.config)
	player.pass3_loop_guards = rules.config.get_value("pass3_loop_guards") != false
	player.ring_size = Pass3Rates.number(rules.config, "fairies_initial_ring_size")
