class_name Pass3Fairies
extends RefCounted
## Rings keep a count and a player-owned size. The integer contribution is rounded once per slot,
## so quarter-point growth is retained until it changes the visible stats.


static func ensure(player: PlayerState) -> void:
	if player.pass3_fairies:
		return
	for source: RecruitUnit in player.board:
		if source != null and source.has_mechanic_id("pass3_fairy"):
			player.pass3_fairies = true
			player.pass3_content = true
			return


static func add_ring(player: PlayerState, slot: int, step: Dictionary) -> void:
	if not BoardGeometry.is_valid(slot):
		return
	var count: int = CoreUtil.to_int(step.get("count", step.get("attack", 0)))
	if count <= 0:
		return
	var effects: Array = player.slot_effects[slot]
	for ring: Dictionary in effects:
		if str(ring.get("name", "")) == BoardUpkeep.RING:
			ring["count"] = ring_count(ring) + count
			_write_stats(ring, player.ring_size)
			return
	var ring: Dictionary = {
		"name": BoardUpkeep.RING,
		"text": "Whoever stands here gains your Ring size for each Ring.",
		"count": count,
		"golden": false,
	}
	_write_stats(ring, player.ring_size)
	effects.append(ring)


static func ring_count(ring: Dictionary) -> int:
	return CoreUtil.to_int(ring.get("count", ring.get("attack", 0)))


static func sync_rings(player: PlayerState) -> void:
	ensure(player)
	if not player.pass3_fairies:
		return
	for effects: Array in player.slot_effects:
		for ring: Dictionary in effects:
			if str(ring.get("name", "")) == BoardUpkeep.RING:
				ring["count"] = ring_count(ring)
				_write_stats(ring, player.ring_size)


static func _write_stats(ring: Dictionary, size: float) -> void:
	var total: int = ceili(float(ring_count(ring)) * size)
	ring["attack"] = total
	ring["health"] = total
	ring["ring_size"] = size


## The unit's own age survives moves. Repeated End of Turn effects do not advance it.
static func tick_turns(player: PlayerState) -> void:
	ensure(player)
	if not player.pass3_fairies:
		return
	if CoreUtil.to_int(player.owner_counters.get("pass3_age_round", -1)) == player.round_number:
		return
	player.owner_counters["pass3_age_round"] = player.round_number
	for unit: RecruitUnit in player.board:
		if unit != null and _has_ability(unit, "lob"):
			unit.counters["pass3_turns_stayed"] = (
				CoreUtil.to_int(unit.counters.get("pass3_turns_stayed", 0)) + 1
			)


static func recruit_hook(ctx: RecruitContext) -> void:
	ensure(ctx.player)
	var ability: String = str(ctx.params.get("ability", ""))
	match ability:
		"nan":
			_nan(ctx)
		"chaser":
			_chaser(ctx)
		"annis":
			_annis(ctx)
		"sally":
			_sally(ctx)
		"cluricaun":
			_cluricaun(ctx)
		"lob":
			_lob(ctx)
		"silky":
			_silky(ctx)
		"monarch":
			_monarch(ctx)
		"queen":
			_queen(ctx)


static func _nan(ctx: RecruitContext) -> void:
	if ctx.source != ctx.subject or ctx.trigger not in ["on_play", "on_sell"]:
		return
	_ring(ctx, [ctx.source_slot], _rate_int(ctx, "fairies_nan_rings") * _factor(ctx))


static func _chaser(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_sell" or ctx.source != ctx.subject:
		return
	var count: int = 0
	for effects: Array in ctx.player.slot_effects:
		if BoardUpkeep.has_ring(effects):
			count += 1
	ctx.announce("pass3_chaser")
	ctx.gain_gold(count * _rate_int(ctx, "fairies_chaser_gold") * _factor(ctx), "now")


static func _annis(ctx: RecruitContext) -> void:
	var sale: bool = (
		ctx.trigger == "on_sell"
		and ctx.source != ctx.subject
		and Pass3Rates.enabled(ctx.rules.config, "fairies_annis_sale")
	)
	if ctx.source_slot < 0 or (ctx.trigger != "end_of_turn" and not sale):
		return
	_ring(
		ctx,
		BoardGeometry.behind(ctx.source_slot),
		_rate_int(ctx, "fairies_annis_rings") * _factor(ctx)
	)


static func _sally(ctx: RecruitContext) -> void:
	if ctx.trigger != "end_of_turn" or ctx.source_slot < 0:
		return
	var slot: int = BoardGeometry.summon_slot(ctx.player.occupied(), ctx.source_slot, false)
	if slot >= 0:
		_ring(ctx, [slot], _rate_int(ctx, "fairies_sally_rings") * _factor(ctx))


static func _cluricaun(ctx: RecruitContext) -> void:
	if ctx.trigger != "end_of_turn" or not _is_grower(ctx, "cluricaun"):
		return
	for effects: Array in ctx.player.slot_effects:
		if not BoardUpkeep.has_ring(effects):
			return
	if _once_event(ctx, "cluricaun"):
		_grow(ctx, Pass3Rates.number(ctx.rules.config, "fairies_ring_growth") * _factor(ctx))


static func _lob(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_shy_left" or ctx.source != ctx.subject:
		return
	var age: int = CoreUtil.to_int(ctx.source.counters.get("pass3_turns_stayed", 0))
	var period: int = maxi(1, _rate_int(ctx, "fairies_lob_turns"))
	@warning_ignore("integer_division")
	var steps: int = age / period
	var growth: float = Pass3Rates.number(ctx.rules.config, "fairies_lob_growth")
	_grow(ctx, float(steps * _factor(ctx)) * growth)


static func _silky(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_shy_left" or not _is_grower(ctx, "silky"):
		return
	if _once_event(ctx, "silky"):
		_grow(ctx, Pass3Rates.number(ctx.rules.config, "fairies_silky_growth") * _factor(ctx))


static func _monarch(ctx: RecruitContext) -> void:
	if ctx.trigger != "end_of_turn" or not _is_grower(ctx, "monarch"):
		return
	if (_guards(ctx) and ctx.repeat_index > 0) or not _once_event(ctx, "monarch"):
		return
	var period: int = maxi(1, _rate_int(ctx, "fairies_monarch_period"))
	var count: int = CoreUtil.to_int(ctx.player.owner_counters.get("pass3_midsummer", 0)) + 1
	ctx.player.owner_counters["pass3_midsummer"] = count % period
	var key: String = (
		"fairies_golden_monarch_multiplier" if _factor(ctx) > 1 else "fairies_monarch_multiplier"
	)
	if count >= period:
		ctx.announce("pass3_midsummer")
		ctx.player.ring_size *= Pass3Rates.number(ctx.rules.config, key)
		_refresh(ctx)
	for source: RecruitUnit in ctx.player.board:
		if source != null and _has_ability(source, "monarch"):
			source.counters["pass3_midsummer"] = count % period
			source.counters["pass3_midsummer_period"] = period


static func _queen(ctx: RecruitContext) -> void:
	if (
		ctx.trigger != "start_of_turn"
		or ctx.source_slot < 0
		or (_guards(ctx) and ctx.repeat_index > 0)
	):
		return
	var period: int = maxi(1, _rate_int(ctx, "fairies_queen_period"))
	var count: int = CoreUtil.to_int(ctx.source.counters.get("pass3_teind", 0)) + 1
	ctx.source.counters["pass3_teind"] = count % period
	if count < period:
		return
	var victims: Array[RecruitUnit] = []
	for slot: int in BoardGeometry.behind(ctx.source_slot):
		var victim: RecruitUnit = ctx.player.board[slot]
		if victim != null:
			victims.append(victim)
	for victim: RecruitUnit in victims:
		ctx.rules.destroy_unit(ctx.player, victim)
	var slots: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		slots.append(slot)
	_ring(ctx, slots, victims.size() * _rate_int(ctx, "fairies_queen_rings") * _factor(ctx))


static func _ring(ctx: RecruitContext, slots: Array[int], count: int) -> void:
	if count <= 0:
		return
	for slot: int in slots:
		if BoardGeometry.is_valid(slot):
			add_ring(ctx.player, slot, {"count": count})
			ctx.player.log_event("slot_effect", {"slot": slot, "name": BoardUpkeep.RING})
	ctx.rules.board_changed(ctx.player)


static func _grow(ctx: RecruitContext, growth: float) -> void:
	if growth <= 0:
		return
	ctx.announce("pass3_ring_growth")
	ctx.player.ring_size += growth
	_refresh(ctx)


static func _refresh(ctx: RecruitContext) -> void:
	sync_rings(ctx.player)
	ctx.player.log_event("ring_size", {"size": ctx.player.ring_size})
	ctx.rules.board_changed(ctx.player)


static func _factor(ctx: RecruitContext) -> int:
	return CoreUtil.to_int(ctx.params.get("factor", 2 if ctx.source.golden else 1))


static func _rate_int(ctx: RecruitContext, key: String) -> int:
	return Pass3Rates.integer(ctx.rules.config, key)


static func _has_ability(source: RecruitUnit, ability: String) -> bool:
	return _ability_factor(source, ability) > 0


static func _ability_factor(source: RecruitUnit, ability: String) -> int:
	var factor: int = 0
	for compiled: CompiledMechanic in MechanicRegistry.compiled(source.def):
		if compiled.id == "pass3_fairy" and str(compiled.params.get("ability", "")) == ability:
			factor = maxi(
				factor, CoreUtil.to_int(compiled.params_for(source.golden).get("factor", 1))
			)
	for group: Array in [source.grants, source.borrowed_text()]:
		for grant: Dictionary in group:
			var entry: Dictionary = grant["entry"]
			if (
				str(entry.get("id", "")) != "pass3_fairy"
				or str(entry.get("ability", "")) != ability
			):
				continue
			var params: Dictionary = MechanicRegistry.params_for(
				entry, CoreUtil.to_bool(grant.get("golden", false))
			)
			factor = maxi(factor, CoreUtil.to_int(params.get("factor", 1)))
	return factor


## Shared growers use the strongest copy; extra normal copies cannot hide a golden one.
static func _is_grower(ctx: RecruitContext, ability: String) -> bool:
	if not _guards(ctx):
		return true
	var best: RecruitUnit = null
	var strongest: int = 0
	var candidates: Array[RecruitUnit] = []
	for source: RecruitUnit in ctx.player.board:
		if source != null:
			candidates.append(source)
	if ctx.subject != null and not candidates.has(ctx.subject):
		candidates.append(ctx.subject as RecruitUnit)
	for source: RecruitUnit in candidates:
		var factor: int = _ability_factor(source, ability)
		if factor > strongest:
			best = source
			strongest = factor
	return ctx.source == best and _factor(ctx) == strongest


static func _once_event(ctx: RecruitContext, ability: String) -> bool:
	if not _guards(ctx):
		return true
	var serial: int = CoreUtil.to_int(ctx.player.owner_counters.get("pass3_event_serial", 0))
	var key: String = "pass3_shared_" + ability
	if CoreUtil.to_int(ctx.player.owner_counters.get(key, -1)) == serial:
		return false
	ctx.player.owner_counters[key] = serial
	return true


static func _guards(ctx: RecruitContext) -> bool:
	return ctx.rules.config.get_value("pass3_loop_guards") != false
