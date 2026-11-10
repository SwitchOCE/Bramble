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
	rules.events.fire(player, "on_play", {"subject": unit})


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
