extends Mechanic
## Dishwater Nell: Start of your turn, the `units` lowest-tier units in your shop go back and units
## of your tier take their place. If one was 2+ tiers lower and she touches an Ooze, `gold` now;
## only the first Nell pays each turn. Not a refresh.

const OOZES: String = "Oozes"
const PAID: String = "nell_paid"
const TIERS_LOWER: int = 2


func on_start_of_turn(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0:
		return
	ctx.announce("nell")
	var was_cheap: bool = false
	for _time: int in CoreUtil.to_int(ctx.params.get("units", 1)):
		was_cheap = _swap_lowest(ctx) or was_cheap
	if was_cheap and _touches_ooze(ctx) and not ctx.player.owner_limits.has(PAID):
		ctx.player.owner_limits[PAID] = 1
		ctx.gain_gold(CoreUtil.to_int(ctx.params.get("gold", 1)), "now")


## True if the unit it swapped was 2+ tiers lower than the player's tier.
func _swap_lowest(ctx: RecruitContext) -> bool:
	var player: PlayerState = ctx.player
	var at: int = -1
	for index: int in player.shop.size():
		var unit: RecruitUnit = player.shop[index]
		if unit.tier() < player.tier and (at < 0 or unit.tier() < player.shop[at].tier()):
			at = index
	if at < 0:
		return false
	var drawn: String = ctx.rules.pool.draw(player.tier, player.shop_rng, player.tier)
	if drawn == "":
		return false
	var eaten: RecruitUnit = player.shop[at]
	ctx.rules.pool.give_back(eaten.def_id(), eaten.pool_copies)
	var fresh := RecruitUnit.make(ctx.rules.library.get_unit(drawn), ctx.rules.new_iid())
	fresh.pool_copies = 1
	player.shop[at] = fresh
	return player.tier - eaten.tier() >= TIERS_LOWER


func _touches_ooze(ctx: RecruitContext) -> bool:
	for slot: int in BoardGeometry.touching(ctx.occupied_slots(), ctx.source_slot):
		var unit: RecruitUnit = ctx.player.board[slot]
		if unit != ctx.source and unit.has_tribe(OOZES):
			return true
	return false
