class_name CommittedLineBrain
extends LineBrain
## A separate, testable candidate: committed purchases, retained engine pieces, affordable climbs.
## Profiles opt in with policy_version=2. Version 1 and ordinary Hard remain unchanged.


func configure_line(id: String) -> void:
	super.configure_line(id)
	var base: Dictionary = knowledge.strategy(str(profile["base_strategy"]))
	var old_units: Dictionary = base.get("units", {})
	var units: Dictionary = value.strategy["units"]
	for card: String in old_units:
		units[card] = BotEval._number(units.get(card, 0)) + BotEval._number(old_units[card])
	var tribe: String = str(profile["tribe"])
	if tribe != "":
		var old_tribes: Dictionary = base.get("tribes", {})
		var tribes: Dictionary = value.strategy["tribes"]
		tribes[tribe] = maxf(
			BotEval._number(tribes[tribe]), BotEval._number(old_tribes.get(tribe, 0))
		)


func _unit_gain(unit: RecruitUnit) -> float:
	if not _permits(unit):
		return 0.0
	var ordinary: float = _ordinary_unit_gain(unit)
	if _replacements >= MAX_STEPS:
		return ordinary
	var plan: Dictionary = BotCarrier.upgrade_plan(self, unit)
	if plan.is_empty() or _protected(_player.board[CoreUtil.to_int(plan["slot"])]):
		return ordinary
	return maxf(ordinary, BotEval._number(plan.get("gain", 0)))


func _permits(unit: RecruitUnit) -> bool:
	if is_banned(unit.def_id()) or not ban_failure.is_empty():
		return false
	var tribe: String = str(profile["tribe"])
	var priority: Array = profile["priority"]
	if tribe == "" or unit.tribes().has(tribe) or priority.has(unit.def_id()):
		return true
	if _round_now < CoreUtil.to_int(profile.get("commit_round", 4)) or _player.board_count() < 3:
		return true
	# Neutral role fillers can bridge gaps; the completed board follows the written line.
	return unit.tribes().is_empty() and _room_left() > 0


func _weakest_slot() -> int:
	var weakest: int = -1
	var lowest: float = INF
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _player.board[slot]
		if unit == null or not _can_replace(unit):
			continue
		var score: float = value.keep_value(unit)
		if score < lowest:
			weakest = slot
			lowest = score
	return weakest


func _can_replace(unit: RecruitUnit) -> bool:
	return super._can_replace(unit) and not _protected(unit)


func _protected(unit: RecruitUnit) -> bool:
	var engines: Array = profile.get("engine_pieces", [])
	if unit == null or not engines.has(unit.def_id()):
		return false
	# Keep the best on-board copy of each component; weaker duplicates can still be upgraded.
	var score: float = value.keep_value(unit)
	var at: int = _player.board.find(unit)
	for slot: int in BoardGeometry.SLOTS:
		var other: RecruitUnit = _player.board[slot]
		if other == null or other == unit or other.def_id() != unit.def_id():
			continue
		var other_score: float = value.keep_value(other)
		if other_score > score or (other_score == score and slot < at):
			return false
	return true


func _clear_slot_for(unit: RecruitUnit) -> int:
	var plan: Dictionary = BotCarrier.upgrade_plan(self, unit)
	if not plan.is_empty() and _protected(_player.board[CoreUtil.to_int(plan["slot"])]):
		return _ordinary_clear_slot_for(unit)
	return super._clear_slot_for(unit)


func _climb(leftover: bool) -> void:
	for _step: int in UnitLibrary.TIERS:
		if _player.tier >= UnitLibrary.TIERS:
			return
		var cost: int = _rules.tier_up_cost(_player)
		var cash: int = _player.gold + _player.larder()
		if cash < cost:
			return
		if _player.health <= LOW_HEALTH and cash < cost + _rules.unit_cost(_player):
			return
		var scheduled: bool = _round_now >= _target_round(_player.tier)
		var enough_bodies: bool = _player.board_count() >= mini(4, _player.tier + 1)
		var early: bool = enough_bodies and _player.health > LOW_HEALTH
		if leftover:
			early = early and _best_offer().is_empty()
		else:
			early = early and cash >= cost + _rules.unit_cost(_player)
		if not scheduled and not early:
			return
		if _player.board_count() == 0 and cash - cost < _rules.unit_cost(_player):
			return
		if not _pay(cost, 100.0) or _rules.tier_up(_player) != "":
			return
		_settle()
