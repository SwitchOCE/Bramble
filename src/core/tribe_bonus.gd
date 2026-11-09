class_name TribeBonus
extends RefCounted
## A standing owner bonus, separate from a unit's permanent buffs. It follows ownership and
## does not get tripled, doubled on golden, fed through Moss Ooze, or put on fight summons.

const CAP: int = 3


static func ceiling(player: PlayerState) -> int:
	return CAP if player.card_size_caps and not player.pass3_content else BoardUnit.STAT_CLAMP


static func used_this_turn(player: PlayerState) -> bool:
	return (
		(player.pass3_content or player.card_rate_limits)
		and player.harvest_supper_round == player.round_number
	)


static func cast_problem(player: PlayerState, item: HandItem, slot: int) -> String:
	if item.def_id() != "harvest_supper":
		return ""
	if used_this_turn(player):
		return "Harvest Supper can be cast only once a turn"
	if not BoardGeometry.is_valid(slot) or player.board[slot] == null:
		return "Choose a unit with a tribe"
	for tribe: Variant in player.board[slot].tribes():
		if CoreUtil.to_int(player.tribe_bonuses.get(tribe, 0)) < ceiling(player):
			return ""
	return "That tribe's bonus is already +3/+3"


static func grant(player: PlayerState, chosen: BoardUnit, amount: int) -> void:
	player.harvest_supper_round = player.round_number
	for tribe: Variant in chosen.tribes():
		var before: int = CoreUtil.to_int(player.tribe_bonuses.get(tribe, 0))
		var after: int = mini(ceiling(player), before + amount)
		player.tribe_bonuses[tribe] = after
		player.log_event("tribe_bonus", {"tribe": tribe, "amount": after - before, "total": after})
	sync(player)


static func sync(player: PlayerState) -> void:
	for unit: RecruitUnit in player.all_units():
		_sync_unit(player, unit)


static func _sync_unit(player: PlayerState, unit: RecruitUnit) -> void:
	var bonus: int = 0
	unit.tribe_bonuses = {}
	for tribe: Variant in unit.tribes():
		var amount: int = CoreUtil.to_int(player.tribe_bonuses.get(tribe, 0))
		if unit.has_mechanic_id("shy"):
			amount = 0
		unit.tribe_bonuses[tribe] = amount
		bonus += amount
	unit.tribe_attack = bonus
	unit.tribe_health = bonus
	for held: RecruitUnit in unit.held:
		_sync_unit(player, held)
