class_name BoardUpkeep
extends RefCounted
## What has to stay true of a recruit board whenever it changes: Rings and other auras in the unit's
## stats, Rainbow bands, Shy units. And what End of Turn does before its triggers: the turns-in-slot
## counter and Passes. RecruitRules.board_changed and end_phase call these.

const RING: String = "Ring"
const RING_TEXT: String = "Whoever stands on this slot has these stats."


## Everything that follows from the board as it now stands. A Shy unit leaving changes the board.
static func settle(rules: RecruitRules, player: PlayerState) -> void:
	var again: bool = true
	while again:
		TribeBonus.sync(player)
		_fade_bands(player)
		_recalc_auras(player)
		again = _shy_leaves(rules, player)


## A slot holds one Ring; a new one adds to it. Rings stay for the rest of the game.
static func add_ring(player: PlayerState, slot: int, step: Dictionary) -> void:
	var effects: Array = player.slot_effects[slot]
	var attack: int = CoreUtil.to_int(step.get("attack", 0))
	var health: int = CoreUtil.to_int(step.get("health", 0))
	for value: Variant in effects:
		var effect: Dictionary = value
		if str(effect.get("name", "")) == RING:
			effect["attack"] = CoreUtil.to_int(effect["attack"]) + attack
			effect["health"] = CoreUtil.to_int(effect["health"]) + health
			return
	effects.append(
		{"name": RING, "text": RING_TEXT, "attack": attack, "health": health, "golden": false}
	)


static func has_ring(effects: Array) -> bool:
	for value: Variant in effects:
		var effect: Dictionary = value
		if str(effect.get("name", "")) == RING:
			return true
	return false


## Whether any slot on these sides holds an effect.
static func any_slot_effects(sides: Array) -> bool:
	for row: Variant in sides:
		var slots: Array = row
		for effects: Variant in slots:
			var list: Array = effects
			if not list.is_empty():
				return true
	return false


## Rainbow: a band belongs to the unit that painted it; it fades when that unit moves or leaves.
static func _fade_bands(player: PlayerState) -> void:
	for slot: int in BoardGeometry.SLOTS:
		if player.bands[slot] == 0:
			continue
		var unit: RecruitUnit = player.board[slot]
		if unit == null or unit.iid != player.bands[slot]:
			player.bands[slot] = 0
			player.log_event("band_faded", {"slot": slot})


## 12.2.1: what slots and a unit's own aura give it. Shown in its stats; a fight works it out again.
static func _recalc_auras(player: PlayerState) -> void:
	var band_attack: int = _band_attack(player)
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null:
			continue
		var bonus: Vector2i = _monarch_bonus(player, unit, slot)
		if player.bands[slot] != 0:
			bonus.x += band_attack
		for value: Variant in player.slot_effects[slot]:
			var effect: Dictionary = value
			bonus += Vector2i(
				CoreUtil.to_int(effect.get("attack", 0)), CoreUtil.to_int(effect.get("health", 0))
			)
		for value: Variant in MechanicRegistry.compiled(unit.def):
			var compiled: CompiledMechanic = value
			bonus += compiled.mechanic.recruit_aura(player, unit, compiled.params_for(unit.golden))
		for lent: Dictionary in unit.borrowed_text():
			var entry: Dictionary = lent["entry"]
			var is_golden: bool = lent["golden"]
			var one: CompiledMechanic = MechanicRegistry.compile_entry(entry)
			if one != null:
				bonus += one.mechanic.recruit_aura(player, unit, one.params_for(is_golden))
		if bonus.x != unit.aura_attack or bonus.y != unit.aura_health:
			unit.set_aura(bonus.x, bonus.y)


## Cluricaun: what standing on a band gives.
static func _band_attack(player: PlayerState) -> int:
	var total: int = 0
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id("band_attack"):
			total += unit.mechanic_number("band_attack", "attack")
	return total


## Shy: any rise in Attack or Health on the board and it leaves, paying next turn. Tripling makes a
## new unit, so it starts from its new stats. Not a sale: no "when sold", and its copy goes back.
static func _shy_leaves(rules: RecruitRules, player: PlayerState) -> bool:
	var someone_left: bool = false
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or not unit.has_mechanic_id("shy"):
			continue
		if unit.shy_seen.x < 0:
			unit.shy_seen = Vector2i(unit.attack - unit.aura_attack, unit.health - unit.aura_health)
		if unit.attack > unit.shy_seen.x or unit.health > unit.shy_seen.y:
			player.board[slot] = null
			HeldUnits.release(rules, player, unit)
			rules.pool.give_back(unit.def_id(), unit.pool_copies)
			rules.give_gold(player, unit.mechanic_number("shy", "gold"), "next_turn")
			player.log_event(
				"walk_out",
				{
					"name": str(unit.def["name"]),
					"slot": slot,
					"gold": unit.mechanic_number("shy", "gold")
				}
			)
			player.log_event("trigger", {"mechanic": "shy", "source": unit.def_id()})
			someone_left = true
		else:
			unit.shy_seen = Vector2i(unit.attack, unit.health)
	return someone_left


## The start of End of Turn: each unit on the board counts this turn in its slot, and prizes that
## have waited long enough arrive. A unit in a new slot starts counting there.
static func tick_turns(rules: RecruitRules, player: PlayerState) -> void:
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null:
			continue
		if unit.home_slot != slot:
			unit.reset_turns()
			unit.home_slot = slot
		unit.turns_in_slot += 1
		_tick_timers(player, unit)
	rules.board_changed(player)


static func _tick_timers(player: PlayerState, unit: RecruitUnit) -> void:
	var waiting: Array[Dictionary] = []
	for timer: Dictionary in unit.timers:
		timer["left"] = CoreUtil.to_int(timer["left"]) - 1
		if CoreUtil.to_int(timer["left"]) > 0:
			waiting.append(timer)
			continue
		var attack: int = timer["attack"]
		var health: int = timer["health"]
		unit.add_permanent(attack, health)
		player.log_event(
			"buff",
			{"target": unit.def_id(), "attack": attack, "health": health, "duration": "permanent"}
		)
		player.log_event("trigger", {"mechanic": "wait_in_slot", "source": unit.def_id()})
	unit.timers = waiting


## Pass: from where the source stands now, or the slot it left, along the zigzag to the last
## touching unit. Read at End of Turn, so the layout you fight with is the one that gets it.
static func resolve_passes(rules: RecruitRules, player: PlayerState) -> void:
	var waiting: Array[Dictionary] = player.pending_passes
	player.pending_passes = []
	var ctx: RecruitContext = RecruitContext.make(rules, player, "pass", {})
	for entry: Dictionary in waiting:
		var start: int = pass_start(player, entry)
		var landing: int = BoardGeometry.pass_landing(player.occupied(), start)
		player.log_event("pass", {"from": start, "to": landing})
		player.log_event("trigger", {"mechanic": "pass", "source": "mr_crumb"})
		if landing >= 0:
			var unit: RecruitUnit = player.board[landing]
			ctx.buff(unit, CoreUtil.to_int(entry["attack"]), CoreUtil.to_int(entry["health"]), "")


## Where a waiting Pass would start right now.
static func pass_start(player: PlayerState, entry: Dictionary) -> int:
	var iid: int = entry["iid"]
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit != null and unit.iid == iid:
			return slot
	return entry["slot"]


## Each Monarch adds a flat bonus once to the Ring beneath a Fairy.
static func _monarch_bonus(player: PlayerState, unit: RecruitUnit, slot: int) -> Vector2i:
	var effects: Array = player.slot_effects[slot]
	if not unit.has_tribe("Fairies") or not has_ring(effects):
		return Vector2i.ZERO
	var total: int = 0
	for source: RecruitUnit in player.board:
		if source != null:
			total += source.mechanic_number("fairy_monarch", "stats")
			for group: Array in [source.grants, source.borrowed_text()]:
				for grant: Dictionary in group:
					var entry: Dictionary = grant["entry"]
					if str(entry.get("id", "")) == "fairy_monarch":
						var params: Dictionary = MechanicRegistry.params_for(
							entry, CoreUtil.to_bool(grant.get("golden", false))
						)
						total += CoreUtil.to_int(params["stats"])
	return Vector2i(total, total)
