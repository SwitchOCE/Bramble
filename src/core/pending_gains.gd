class_name PendingGains
extends RefCounted
## Takes and Soak share one queue. A fighting body never spends its next-turn reward.


static func queue(
	combat: Combat, unit: CombatUnit, attack: int, health: int, source: CombatUnit, cause: String
) -> void:
	if not Pass3Combat.has_content(combat):
		combat.buff(unit, attack, health, source, true)
		return
	if unit.iid == 0:
		return
	var bonus := Vector2i(maxi(0, attack), maxi(0, health))
	var ceiling: int = CoreUtil.to_int(unit.def.get("permanent_buff_cap", 0)) * unit.golden_factor()
	if ceiling > 0:
		bonus.x = mini(bonus.x, maxi(0, ceiling - unit.perm_attack - unit.pending_attack))
		bonus.y = mini(bonus.y, maxi(0, ceiling - unit.perm_health - unit.pending_health))
	if bonus == Vector2i.ZERO:
		return
	unit.pending_attack += bonus.x
	unit.pending_health += bonus.y
	combat.carry_back(
		CoreUtil.to_int(combat.starting_sides.get(unit.uid, unit.side)),
		{
			"op": "pending_gain",
			"iid": unit.iid,
			"attack": bonus.x,
			"health": bonus.y,
			"cause": cause
		}
	)
	(
		combat
		. emit_event(
			"gain_pending",
			{
				"target": unit.uid,
				"source": CombatMoves.uid_or_null(source),
				"attack": unit.pending_attack,
				"health": unit.pending_health,
				"attack_delta": bonus.x,
				"health_delta": bonus.y,
				"cause": cause,
			}
		)
	)


static func receive(player: PlayerState, change: Dictionary) -> void:
	player.pending_gains.append(change.duplicate(true))


## Drain before arrivals, homecomings and Start of Turn listeners can read these bodies.
static func land(rules: RecruitRules, player: PlayerState) -> void:
	if player.pending_gains.is_empty():
		return
	var waiting: Array[Dictionary] = player.pending_gains
	player.pending_gains = []
	for change: Dictionary in waiting:
		var unit: RecruitUnit = _find(player, CoreUtil.to_int(change["iid"]))
		if unit == null:
			continue
		var before := Vector2i(unit.perm_attack, unit.perm_health)
		unit.shy_accepts_stats = true
		unit.add_permanent(CoreUtil.to_int(change["attack"]), CoreUtil.to_int(change["health"]))
		unit.shy_accepts_stats = false
		unit.shy_seen = Vector2i(-1, -1)
		(
			player
			. log_event(
				"gain_landed",
				{
					"iid": unit.iid,
					"unit": unit.def_id(),
					"attack": unit.perm_attack - before.x,
					"health": unit.perm_health - before.y,
					"cause": str(change.get("cause", "")),
				}
			)
		)
	rules.board_changed(player)


static func merge_copies(player: PlayerState, copies: Array, golden: RecruitUnit) -> void:
	for change: Dictionary in player.pending_gains:
		for copy: RecruitUnit in copies:
			if CoreUtil.to_int(change["iid"]) == copy.iid:
				change["iid"] = golden.iid
				break


static func _find(player: PlayerState, iid: int) -> RecruitUnit:
	for unit: RecruitUnit in player.all_units():
		if unit.iid == iid:
			return unit
	return null
