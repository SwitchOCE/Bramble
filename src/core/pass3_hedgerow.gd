class_name Pass3Hedgerow
extends RefCounted
## Native recruit effects; timer wakes run only after the ordinary queue has drained.

const TRIBE: String = "Hedgerow folk"


static func active(player: PlayerState) -> bool:
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id("pass3_hedgerow"):
			return true
	return false


static func entries(unit: RecruitUnit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if compiled.id == "pass3_hedgerow":
			out.append(compiled.params_for(unit.golden))
	for grant: Dictionary in unit.grants + unit.borrowed_text():
		var entry: Dictionary = grant["entry"]
		if str(entry.get("id", "")) == "pass3_hedgerow":
			out.append(
				MechanicRegistry.params_for(entry, CoreUtil.to_bool(grant.get("golden", false)))
			)
	return out


static func params(unit: RecruitUnit, ability: String) -> Dictionary:
	var best: Dictionary = {}
	for entry: Dictionary in entries(unit):
		if str(entry.get("ability", "")) == ability:
			if (
				best.is_empty()
				or CoreUtil.to_int(entry.get("factor", 1)) > CoreUtil.to_int(best.get("factor", 1))
			):
				best = entry
	return best


static func factor(unit: RecruitUnit, ability: String) -> int:
	var entry: Dictionary = params(unit, ability)
	return 0 if entry.is_empty() else CoreUtil.to_int(entry.get("factor", 1))


static func has(unit: RecruitUnit, ability: String) -> bool:
	return factor(unit, ability) > 0


static func larder(player: PlayerState) -> int:
	return player.larder()


static func own_stats(unit: RecruitUnit, include_tribe: bool = true) -> Vector2i:
	return Vector2i(
		clampi(
			unit.base_attack_now() + unit.perm_attack + (unit.tribe_attack if include_tribe else 0),
			0,
			BoardUnit.STAT_CLAMP
		),
		clampi(
			unit.base_health_now() + unit.perm_health + (unit.tribe_health if include_tribe else 0),
			0,
			BoardUnit.STAT_CLAMP
		)
	)


static func wake_due(unit: RecruitUnit, player: PlayerState) -> bool:
	var entry: Dictionary = params(unit, "alderman_dozey")
	if entry.is_empty():
		return false
	var turns: int = unit.turns_in_slot if unit.home_slot == player.board.find(unit) else 0
	return (turns + 1) % maxi(1, CoreUtil.to_int(entry.get("period", 3))) == 0


static func ranked(
	player: PlayerState, biggest_first: bool = false, tribe_only: bool = true
) -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if (
			unit != null
			and (not tribe_only or unit.has_tribe(TRIBE))
			and (not tribe_only or not unit.has_mechanic_id("shy"))
		):
			out.append(unit)
	out.sort_custom(
		func(a: RecruitUnit, b: RecruitUnit) -> bool:
			var first: int = a.attack + a.health
			var second: int = b.attack + b.health
			if first == second:
				if biggest_first:
					return player.board.find(a) < player.board.find(b)
				return (
					BoardGeometry.ZIGZAG.find(player.board.find(a))
					< BoardGeometry.ZIGZAG.find(player.board.find(b))
				)
			return first > second if biggest_first else first < second
	)
	return out


static func touching(player: PlayerState, source: RecruitUnit) -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	var slot: int = player.board.find(source)
	if slot < 0:
		return out
	for at: int in BoardGeometry.touching(player.occupied(), slot):
		var unit: RecruitUnit = player.board[at]
		if unit.has_tribe(TRIBE):
			out.append(unit)
	return out


## Freeze the carrier and its share for all copies: a newly overtaking recipient is not re-read.
static func start_turn(rules: RecruitRules, player: PlayerState) -> void:
	var biggest: Array[RecruitUnit] = ranked(player, true, false)
	if biggest.is_empty():
		return
	var carrier: RecruitUnit = biggest[0]
	var stats: Vector2i = Vector2i(carrier.attack, carrier.health)
	var guarded: bool = player.pass3_loop_guards
	for source: RecruitUnit in player.board:
		if source == null or not has(source, "squire_lollop"):
			continue
		if not guarded:
			carrier = ranked(player, true, false)[0]
			stats = Vector2i(carrier.attack, carrier.health)
		var entry: Dictionary = params(source, "squire_lollop")
		var share: float = (
			CoreUtil.to_float(entry.get("share", 0.1)) * CoreUtil.to_int(entry.get("factor", 1))
		)
		var ctx: RecruitContext = RecruitContext.make(rules, player, "start_of_turn", {})
		ctx.source = source
		ctx.source_slot = player.board.find(source)
		var targets: Array[RecruitUnit] = touching(player, source)
		targets.erase(carrier)
		_share(ctx, stats, targets, share)


static func recruit_hook(ctx: RecruitContext) -> void:
	var ability: String = str(ctx.params.get("ability", ""))
	var unit: RecruitUnit = ctx.source as RecruitUnit
	if unit == null or not _claim(ctx, ability):
		return
	var scale: int = CoreUtil.to_int(ctx.params.get("factor", 1))
	match ability:
		"mr_crumb":
			if ctx.subject != unit:
				return
			if ctx.trigger == "on_play":
				var gain: int = CoreUtil.to_int(ctx.params.get("pass", 1)) * scale
				ctx.queue_pass(gain, gain)
			elif ctx.trigger == "on_sell":
				var stats: Vector2i = own_stats(unit, false)
				var share: float = CoreUtil.to_float(ctx.params.get("sell_share", 1.0)) * scale
				ctx.queue_pass(floori(stats.x * share), floori(stats.y * share))
		"sleeping_partner":
			if (
				ctx.trigger != "end_of_turn"
				or (ctx.player.pass3_loop_guards and ctx.repeat_index > 0)
			):
				return
			var period: int = maxi(1, CoreUtil.to_int(ctx.params.get("period", 3)))
			if unit.turns_in_slot > 0 and unit.turns_in_slot % period == 0:
				ctx.add_card(
					"acorn",
					(
						touching(ctx.player, unit).size()
						* CoreUtil.to_int(ctx.params.get("acorns", 2))
						* scale
					),
					false
				)
		"mrs_clover":
			if ctx.trigger == "on_summon" and ctx.subject != null and ctx.subject.has_tribe(TRIBE):
				ctx.buff(
					ctx.subject,
					floori(unit.attack * CoreUtil.to_float(ctx.params.get("share", 1.0)) * scale),
					floori(unit.health * CoreUtil.to_float(ctx.params.get("share", 1.0)) * scale),
					"permanent"
				)
		"mr_pym", "beadle_warrenby":
			var card: String = "stash" if ability == "mr_pym" else "acorn"
			if ctx.trigger == "on_item_gained" and str(ctx.card_def.get("id", "")) == card:
				var gain: int = CoreUtil.to_int(ctx.params.get("pass", 1)) * scale
				ctx.queue_pass(gain, gain)
		"mrs_mallow":
			if (
				ctx.trigger == "end_of_turn"
				and not (ctx.player.pass3_loop_guards and ctx.repeat_index > 0)
			):
				var targets: Array[RecruitUnit] = ranked(ctx.player)
				targets.erase(unit)
				var count: int = CoreUtil.to_int(ctx.params.get("targets", 2)) * scale
				for target: RecruitUnit in targets.slice(0, count):
					_multiply(ctx, target, CoreUtil.to_float(ctx.params.get("multiplier", 2.0)))
		"honorary_treasurer":
			if ctx.trigger == "end_of_turn":
				var gain: int = floori(
					larder(ctx.player) * CoreUtil.to_float(ctx.params.get("per_gold", 1)) * scale
				)
				ctx.buff(unit, gain, gain, "permanent")
		"goodman_hayward":
			if (
				ctx.trigger == "on_item_played"
				and CoreUtil.to_int(ctx.card_def.get("gold_value", 0)) > 0
			):
				var gain: int = floori(
					(
						CoreUtil.to_int(ctx.card_def["gold_value"])
						* CoreUtil.to_float(ctx.params.get("per_gold", 1))
						* scale
					)
				)
				ctx.player.hedgerow_bonus += gain
				ctx.player.log_event(
					"hedgerow_bonus", {"amount": gain, "total": ctx.player.hedgerow_bonus}
				)
				ctx.rules.board_changed(ctx.player)
		"standing_committee":
			if ctx.trigger == "end_of_turn":
				var targets: Array[RecruitUnit] = touching(ctx.player, unit)
				var smallest: RecruitUnit = null
				for target: RecruitUnit in targets:
					if (
						smallest == null
						or target.attack + target.health < smallest.attack + smallest.health
					):
						smallest = target
				if smallest != null:
					_share(
						ctx,
						Vector2i(smallest.attack, smallest.health),
						targets,
						CoreUtil.to_float(ctx.params.get("share", 0.25)) * scale
					)
		"old_mother_mast":
			if ctx.trigger == "start_of_turn":
				var count: int = (
					floori(
						(
							float(larder(ctx.player))
							/ maxi(1, CoreUtil.to_int(ctx.params.get("gold_step", 5)))
						)
					)
					* scale
				)
				if ctx.player.card_rate_limits:
					count = mini(count, CoreUtil.to_int(ctx.params.get("limit", 5)) * scale)
				ctx.add_card("acorn", count, false)


## A source with printed and borrowed copies uses its strongest text per dispatch/repeat.
static func _claim(ctx: RecruitContext, ability: String) -> bool:
	if not ctx.player.pass3_loop_guards:
		return true
	var unit: RecruitUnit = ctx.source as RecruitUnit
	if CoreUtil.to_int(ctx.params.get("factor", 1)) < factor(unit, ability):
		return false
	var serial: int = CoreUtil.to_int(ctx.player.owner_counters.get("pass3_event_serial", 0))
	var stamp: int = serial * 1000 + ctx.repeat_index
	var key: String = "hedgerow_" + ability
	if CoreUtil.to_int(unit.limits.get(key, -1)) == stamp:
		return false
	unit.limits[key] = stamp
	return true


static func wake_end(rules: RecruitRules, player: PlayerState) -> void:
	var ctx: RecruitContext = RecruitContext.make(rules, player, "end_of_turn", {})
	var repeats: int = EndTurnRepeats.count(ctx)
	for unit: RecruitUnit in player.board:
		if unit == null or not has(unit, "alderman_dozey"):
			continue
		var entry: Dictionary = params(unit, "alderman_dozey")
		var period: int = maxi(1, CoreUtil.to_int(entry.get("period", 3)))
		if unit.turns_in_slot <= 0 or unit.turns_in_slot % period != 0:
			continue
		if (
			player.pass3_loop_guards
			and (
				CoreUtil.to_int(unit.counters.get("hedgerow_last_wake_round", -1))
				== player.round_number
			)
		):
			continue
		ctx.source = unit
		ctx.source_slot = player.board.find(unit)
		var multiplier: float = CoreUtil.to_float(
			entry.get(
				(
					"golden_multiplier"
					if CoreUtil.to_int(entry.get("factor", 1)) > 1
					else "multiplier"
				),
				2.0
			)
		)
		for _repeat: int in 1 if player.pass3_loop_guards else repeats:
			_multiply(ctx, unit, multiplier)
		unit.counters["hedgerow_last_wake_round"] = player.round_number


static func _multiply(ctx: RecruitContext, unit: RecruitUnit, multiplier: float) -> void:
	var stats: Vector2i = own_stats(unit)
	ctx.buff(
		unit,
		floori(stats.x * (multiplier - 1.0)),
		floori(stats.y * (multiplier - 1.0)),
		"permanent"
	)


static func _share(
	ctx: RecruitContext, stats: Vector2i, targets: Array[RecruitUnit], share: float
) -> void:
	var attack: int = floori(stats.x * share)
	var health: int = floori(stats.y * share)
	for target: RecruitUnit in targets:
		ctx.buff(target, attack, health, "permanent")


static func prepare(player: PlayerState) -> void:
	if player.hedgerow_bonus > 0:
		TribeBonus.preview_shop(player)
	for unit: RecruitUnit in player.owned_units():
		for key: String in ["hedgerow_preview", "hedgerow_runt"]:
			if unit.has_meta(key):
				unit.remove_meta(key)
	if not active(player):
		return
	var big: Array[RecruitUnit] = ranked(player, true, false)
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		var entry: Dictionary = params(unit, "squire_lollop")
		if not entry.is_empty() and not big.is_empty():
			var share: float = (
				CoreUtil.to_float(entry.get("share", 0.1)) * CoreUtil.to_int(entry.get("factor", 1))
			)
			unit.set_meta(
				"hedgerow_preview",
				Vector2i(floori(big[0].attack * share), floori(big[0].health * share))
			)
		entry = params(unit, "standing_committee")
		if not entry.is_empty():
			var run: Array[RecruitUnit] = touching(player, unit)
			var runt: RecruitUnit = null
			for target: RecruitUnit in run:
				if runt == null or target.attack + target.health < runt.attack + runt.health:
					runt = target
			if runt != null:
				var share: float = (
					CoreUtil.to_float(entry.get("share", 0.25))
					* CoreUtil.to_int(entry.get("factor", 1))
				)
				runt.set_meta("hedgerow_runt", true)
				unit.set_meta(
					"hedgerow_preview",
					Vector2i(floori(runt.attack * share), floori(runt.health * share))
				)
