class_name Pass3Neutrals
extends RefCounted
## Native neutral recruit rules preserve legacy definitions and the shared extra-trigger guards.


static func play_repeats(player: PlayerState) -> int:
	var best: int = 1
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		for entry: Dictionary in _entries(unit):
			if str(entry.get("ability", "")) == "click_beetle":
				var golden: bool = CoreUtil.to_int(entry.get("factor", 1)) >= 2
				best = maxi(
					best,
					CoreUtil.to_int(
						entry.get("golden_repeats" if golden else "repeats", 3 if golden else 2)
					)
				)
	return best


static func replay_homecoming(rules: RecruitRules, player: PlayerState, unit: RecruitUnit) -> void:
	var repeats: int = play_repeats(player)
	if repeats <= 1 or not unit.has_tribe("Birds"):
		return
	player.log_event("click_homecoming", {"unit": unit.def_id(), "repeats": repeats})
	# HeldUnits queues growth behind this event; fire never interrupts an active event drain.
	rules.events.fire(player, "on_play", {"subject": unit})


## Pure forecast of unconditional printed self buffs. Dynamic conditions, grants and borrowed
## text need event resolution and are deliberately outside this away-tray estimate.
static func homecoming_play_gain(player: PlayerState, unit: RecruitUnit) -> Vector2i:
	var repeats: int = play_repeats(player)
	if repeats <= 1 or not unit.has_tribe("Birds"):
		return Vector2i.ZERO
	var gain := Vector2i.ZERO
	for entry: Dictionary in unit.def.get("mechanics", []):
		if str(entry.get("id", "")) != "effect" or str(entry.get("trigger", "")) != "on_play":
			continue
		var params: Dictionary = MechanicRegistry.params_for(entry, unit.golden)
		if params.has("if") or params.has("every") or params.has("once"):
			continue
		if params.has("limit") or params.has("lifetime"):
			continue
		if str(params.get("subject", "self")) == "other":
			continue
		for step: Dictionary in MechanicRegistry.steps_of(params):
			var target: Dictionary = step.get("target", params.get("target", {}))
			if str(step.get("effect", "")) != "buff" or str(target.get("select", "self")) != "self":
				continue
			if step.has("per") or str(step.get("duration", "permanent")) == "combat":
				continue
			gain += Vector2i(
				CoreUtil.to_int(step.get("attack", 0)), CoreUtil.to_int(step.get("health", 0))
			)
	return gain * repeats


static func recruit_hook(ctx: RecruitContext) -> void:
	if str(ctx.params.get("ability", "")) != "charcoal_burner" or ctx.trigger != "end_of_turn":
		return
	var cap: int = (
		CoreUtil.to_int(ctx.params.get("cap", 6)) * CoreUtil.to_int(ctx.params.get("factor", 1))
	)
	var above: int = CoreUtil.to_int(ctx.params.get("above", 5))
	if ctx.player.gold <= above or cap <= 0:
		return
	ctx.announce("burn")
	ctx.burn_gold(above, cap)
	var share: float = CoreUtil.to_float(ctx.params.get("share", 0.05)) * ctx.amount
	for slot: int in BoardGeometry.behind(ctx.source_slot):
		var target: RecruitUnit = ctx.player.board[slot]
		if target == null:
			continue
		# Own permanent body only: standing tribe layers, slot Rings and auras never compound here.
		var attack: int = maxi(0, target.base_attack_now() + target.perm_attack)
		var health: int = maxi(0, target.base_health_now() + target.perm_health)
		ctx.buff(target, floori(attack * share), floori(health * share), "permanent")


static func _entries(unit: RecruitUnit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if compiled.id == "pass3_neutral":
			out.append(compiled.params_for(unit.golden))
	for grant: Dictionary in unit.grants + unit.borrowed_text():
		var entry: Dictionary = grant["entry"]
		if str(entry.get("id", "")) == "pass3_neutral":
			out.append(
				MechanicRegistry.params_for(entry, CoreUtil.to_bool(grant.get("golden", false)))
			)
	return out
