extends Mechanic
## Queen of Elfland: every 3rd End of Turn, counted from the turn she is played, destroy the units
## behind this (or this, if none). Other Fairies split printed stats and permanent buffs evenly.
## Odd points go to the first in reading order. Golden: the pool is doubled first.

const EVERY: int = 3


func on_end_of_turn(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0:
		return
	var count: int = CoreUtil.to_int(ctx.source.counters.get("teind", 0)) + 1
	if count < EVERY:
		ctx.source.counters["teind"] = count
		return
	ctx.source.counters["teind"] = 0
	ctx.announce("teind")
	var queen: RecruitUnit = ctx.source
	var factor: int = 2 if queen.golden else 1
	var pool_stats: Vector2i = _destroy(ctx, _victims(ctx, queen))
	_split(ctx, queen, pool_stats * factor)


func _victims(ctx: RecruitContext, queen: RecruitUnit) -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	for slot: int in BoardGeometry.behind(ctx.source_slot):
		var unit: RecruitUnit = ctx.player.board[slot]
		if unit != null:
			out.append(unit)
	if out.is_empty():
		out.append(queen)
	return out


func _destroy(ctx: RecruitContext, victims: Array[RecruitUnit]) -> Vector2i:
	var total: Vector2i = Vector2i.ZERO
	for unit: RecruitUnit in victims:
		total += Vector2i(
			unit.base_attack_now() + unit.perm_attack, unit.base_health_now() + unit.perm_health
		)
		ctx.rules.destroy_unit(ctx.player, unit)
	return total


func _split(ctx: RecruitContext, queen: RecruitUnit, stats: Vector2i) -> void:
	var others: Array[RecruitUnit] = []
	for unit: RecruitUnit in ctx.player.board:
		if unit != null and unit != queen and unit.has_tribe("Fairies"):
			others.append(unit)
	var count: int = others.size()
	for index: int in count:
		@warning_ignore("integer_division")
		var attack: int = stats.x / count + (1 if index < stats.x % count else 0)
		@warning_ignore("integer_division")
		var health: int = stats.y / count + (1 if index < stats.y % count else 0)
		ctx.buff(others[index], attack, health, "permanent")
