class_name BotCommitment
extends RefCounted
## Live values for commitment spells. A kin target matters more than an already tall carry.


static func future_bonus(unit: RecruitUnit, player: PlayerState) -> float:
	# Owned units already carry this layer; shop and Discover units do not.
	if player.all_units().has(unit):
		return 0.0
	var total: int = 0
	for tribe: Variant in unit.tribes():
		total += CoreUtil.to_int(player.tribe_bonuses.get(tribe, 0)) * 2
	return total


static func can_cast(card: Dictionary, player: PlayerState) -> bool:
	if str(card.get("id", "")) == "horseshoe":
		return BotContent5.spell_value(card, player) > 0.0
	if str(card.get("id", "")) == "market_stall":
		return player.market_stalls < MarketStalls.LIMIT
	if str(card.get("id", "")) != "harvest_supper":
		return true
	return player.harvest_supper_round != player.round_number and spell_value(card, player) > 0.0


## Negative means use ordinary hints; zero means this spell cannot currently help.
static func spell_value(card: Dictionary, player: PlayerState) -> float:
	var id: String = str(card.get("id", ""))
	if id in ["stand_behind_me", "bread_from_the_back", "harvest_supper"]:
		if id == "harvest_supper" and player.harvest_supper_round == player.round_number:
			return 0.0
		var best: float = 0.0
		for slot: int in BoardGeometry.SLOTS:
			best = maxf(best, aim_value(card, slot, player))
		return best
	if id == "hiring_fair":
		var committed: bool = false
		for count: Variant in board_counts(player).values():
			if CoreUtil.to_int(count) >= 5:
				committed = true
		return 22.0 if committed else 12.0
	return -1.0


static func has_live_aim(card: Dictionary) -> bool:
	return str(card.get("id", "")) in ["stand_behind_me", "bread_from_the_back", "harvest_supper"]


static func aim_value(card: Dictionary, slot: int, player: PlayerState) -> float:
	var id: String = str(card.get("id", ""))
	if not has_live_aim(card):
		return -1.0
	var source: RecruitUnit = player.board[slot]
	if source == null:
		return 0.0
	if id == "harvest_supper":
		return _supper_value(source, player)
	if id == "stand_behind_me" and not BoardGeometry.is_front(slot):
		return 0.0
	if id == "bread_from_the_back" and not BoardGeometry.is_back(slot):
		return 0.0
	var targets: Array[int] = (
		BoardGeometry.behind(slot) if id == "stand_behind_me" else BoardGeometry.in_front_of(slot)
	)
	var total: float = 0.0
	for target: int in targets:
		var unit: RecruitUnit = player.board[target]
		if unit == null or not unit.can_gain_permanent():
			continue
		if unit.has_mechanic_id("shy"):
			total -= 20.0
		else:
			total += 4.0 if _shares(source, unit) else 2.0
	return total


static func _supper_value(source: RecruitUnit, player: PlayerState) -> float:
	var total: float = 0.0
	for tribe: Variant in source.tribes():
		if CoreUtil.to_int(player.tribe_bonuses.get(tribe, 0)) >= 3:
			continue
		# The next two replacements also receive it. Away birds and Belly units count now.
		total += 4.0
		for unit: RecruitUnit in player.all_units():
			if unit.tribes().has(tribe):
				total += -20.0 if unit.has_mechanic_id("shy") else 2.0
	return total


static func board_counts(player: PlayerState) -> Dictionary:
	var counts: Dictionary = {}
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		for tribe: Variant in unit.tribes():
			counts[tribe] = CoreUtil.to_int(counts.get(tribe, 0)) + 1
	return counts


static func _shares(first: RecruitUnit, second: RecruitUnit) -> bool:
	for tribe: Variant in first.tribes():
		if second.tribes().has(tribe):
			return true
	return false
