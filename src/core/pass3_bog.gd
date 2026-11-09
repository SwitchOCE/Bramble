class_name Pass3Bog
extends RefCounted
## Owner-owned Toll and kisses survive changes of body; recruit growth uses the last fight.


static func entries(unit: RecruitUnit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if compiled.id == "pass3_bog":
			out.append(compiled.params_for(unit.golden))
	for group: Array in [unit.grants, unit.borrowed_text()]:
		for grant: Dictionary in group:
			var entry: Dictionary = grant["entry"]
			if str(entry.get("id", "")) == "pass3_bog":
				out.append(
					MechanicRegistry.params_for(entry, CoreUtil.to_bool(grant.get("golden", false)))
				)
	return out


static func factor(unit: RecruitUnit, ability: String) -> int:
	var best: int = 0
	for entry: Dictionary in entries(unit):
		if str(entry.get("ability", "")) == ability:
			best = maxi(best, CoreUtil.to_int(entry.get("factor", 1)))
	return best


static func prepare(rules: RecruitRules, player: PlayerState) -> void:
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		if not entries(unit).is_empty():
			player.pass3_bog = true
		if factor(unit, "frog") > 0:
			unit.counters["kisses"] = player.bog_kisses
			unit.counters["bog_kiss_period"] = Pass3Rates.integer(rules.config, "bog_kiss_period")


static func receive_state(player: PlayerState, change: Dictionary) -> void:
	player.pass3_bog = true
	player.bog_toll = CoreUtil.to_int(change.get("toll", 0))
	player.bog_kisses = CoreUtil.to_int(change.get("kisses", 0))
	for unit: RecruitUnit in player.all_units():
		if factor(unit, "frog") > 0:
			unit.counters["kisses"] = player.bog_kisses


static func recruit_hook(ctx: RecruitContext) -> void:
	var ability: String = str(ctx.params.get("ability", ""))
	if (
		ctx.trigger == "on_play"
		and ctx.source == ctx.subject
		and Pass3Rates.enabled(ctx.rules.config, "bog_capstone_gain_toll")
	):
		var native: String = ctx.source.def_id()
		if (
			native in ["prima_donna", "jenny_greenteeth", "peat_king", "lantern_man"]
			and ability == "soak"
		):
			ctx.buff(ctx.source, ctx.player.bog_toll, ctx.player.bog_toll, "permanent")
	if ctx.trigger != "start_of_turn" or ability not in ["nan", "tiddy"]:
		return
	# Printed and borrowed copies of one ability compete, rather than firing twice.
	var strongest: int = factor(ctx.source as RecruitUnit, ability)
	if CoreUtil.to_int(ctx.params.get("factor", 1)) < strongest:
		return
	var serial: int = CoreUtil.to_int(ctx.player.owner_counters.get("pass3_event_serial", 0))
	var key: String = "bog_%s_%d" % [ability, (ctx.source as RecruitUnit).iid]
	if (
		ctx.player.pass3_loop_guards
		and CoreUtil.to_int(ctx.player.owner_counters.get(key, -1)) == serial
	):
		return
	ctx.player.owner_counters[key] = serial
	var targets: Array[RecruitUnit] = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = ctx.player.board[slot]
		if unit == null or not unit.has_tribe("Bog folk"):
			continue
		if ability == "nan" or BoardGeometry.adjacent(ctx.source_slot).has(slot):
			targets.append(unit)
	if targets.is_empty():
		return
	if ability == "nan":
		var smallest: RecruitUnit = targets[0]
		for unit: RecruitUnit in targets:
			if unit.attack + unit.health < smallest.attack + smallest.health:
				smallest = unit
		targets = [smallest]
	var prefix: String = "bog_golden_" if strongest > 1 else "bog_"
	var amount: float = (
		ctx.player.bog_toll * Pass3Rates.number(ctx.rules.config, prefix + ability + "_share")
	)
	var share: int = floori(amount / targets.size())
	ctx.announce("pass3_bog:" + ability)
	for target: RecruitUnit in targets:
		ctx.buff(target, share, share, "permanent")


static func soak_keep(player: PlayerState, slot: int, config: GameConfig) -> float:
	var unit: RecruitUnit = player.board[slot]
	if unit == null:
		return 0.0
	var strongest: int = factor(unit, "soak")
	strongest = maxi(strongest, loan_factor(player, slot, config))
	if strongest <= 0:
		return 0.0
	return Pass3Rates.number(config, "bog_golden_soak_keep" if strongest > 1 else "bog_soak_keep")


static func loan_factor(player: PlayerState, slot: int, config: GameConfig) -> int:
	var unit: RecruitUnit = player.board[slot]
	if unit == null or not unit.has_tribe("Bog folk"):
		return 0
	var strongest: int = 0
	var count: int = Pass3Rates.integer(config, "bog_chorus_lends")
	for source_slot: int in BoardGeometry.adjacent(slot):
		var source: RecruitUnit = player.board[source_slot]
		if source == null:
			continue
		var candidates: Array[int] = []
		for adjacent: int in BoardGeometry.adjacent(source_slot):
			if player.board[adjacent] != null and player.board[adjacent].has_tribe("Bog folk"):
				candidates.append(adjacent)
		if candidates.find(slot) >= 0 and candidates.find(slot) < count:
			strongest = maxi(strongest, factor(source, "chorus"))
	return strongest


static func views(player: PlayerState, board: Array, config: GameConfig) -> void:
	for slot: int in board.size():
		if board[slot] == null or player.board[slot] == null:
			continue
		var shown: Dictionary = board[slot]
		var keep: float = soak_keep(player, slot, config)
		if keep > 0:
			shown["bog_soak_keep"] = keep
		var loan: int = loan_factor(player, slot, config)
		if loan > 0:
			var borrowed: Array = shown.get("borrowed_rules", [])
			borrowed = borrowed.duplicate(true)
			var loan_keep: float = Pass3Rates.number(
				config, "bog_golden_soak_keep" if loan > 1 else "bog_soak_keep"
			)
			var amount: String = (
				str(int(loan_keep))
				if is_equal_approx(loan_keep, roundf(loan_keep))
				else str(loan_keep)
			)
			borrowed.append(
				{
					"name": "Natterjack Chorus",
					"text":
					(
						(
							"Mire. Soak: next Start of Turn, keep +%s/+%s per Attack Bitter took "
							+ "from its own Mired enemies. Only the strongest Soak applies."
						)
						% [amount, amount]
					)
				}
			)
			shown["borrowed_rules"] = borrowed
		if factor(player.board[slot], "frog") > 0:
			shown["bog_kiss_period"] = Pass3Rates.integer(config, "bog_kiss_period")
			var counters: Dictionary = shown.get("counters", {})
			shown["counters"] = counters.duplicate()
			shown["counters"]["kisses"] = player.bog_kisses
	Pass3BogPreview.attach(player, board, config)
