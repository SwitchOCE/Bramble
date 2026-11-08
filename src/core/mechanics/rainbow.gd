extends Mechanic
## Rainbow: while this is on your board, a unit played into an empty slot paints it (BoardUpkeep
## fades a band when its unit moves or leaves). `stats`: this has that per band, both phases.
## When sold: `gold` per band, `finish` more for all seven, then the bands wash away. A card with
## no `gold` doesn't cash.

const RainbowValue := preload("res://src/core/rainbow_value.gd")


func on_play(ctx: RecruitContext) -> void:
	var slot: int = ctx.subject_slot
	if slot < 0 or ctx.player.bands[slot] != 0:
		return
	var unit: RecruitUnit = ctx.subject
	ctx.player.bands[slot] = unit.iid
	ctx.player.log_event("band", {"slot": slot})


func on_sell(ctx: RecruitContext) -> void:
	var per: int = CoreUtil.to_int(ctx.params.get("gold", 0))
	if ctx.subject != ctx.source or per <= 0:
		return
	var pays: int = RainbowValue.sale_bonus(ctx.params, ctx.player.band_count())
	ctx.announce("rainbow")
	if pays > 0:
		ctx.gain_gold(pays, "now")
	ctx.player.bands.fill(0)


func recruit_aura(player: PlayerState, _unit: RecruitUnit, params: Dictionary) -> Vector2i:
	var per: int = CoreUtil.to_int(params.get("stats", 0))
	@warning_ignore("integer_division")
	var groups: int = player.band_count() / maxi(1, CoreUtil.to_int(params.get("stats_every", 1)))
	return Vector2i(per, per) * groups


func aura(combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	var per: int = CoreUtil.to_int(params.get("stats", 0))
	@warning_ignore("integer_division")
	var groups: int = (
		CombatMoves.bands_of(combat, unit.side).size()
		/ maxi(1, CoreUtil.to_int(params.get("stats_every", 1)))
	)
	return Vector2i(per, per) * groups
