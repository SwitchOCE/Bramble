extends Mechanic
## Rainbow: while this is on your board, a unit played into an empty slot paints it (BoardUpkeep
## fades a band when its unit moves or leaves). When this is sold: `gold` per 2 bands, `all` for all
## seven, then the bands wash away.

const SEVEN: int = 7


func on_play(ctx: RecruitContext) -> void:
	var slot: int = ctx.subject_slot
	if slot < 0 or ctx.player.bands[slot] != 0:
		return
	var unit: RecruitUnit = ctx.subject
	ctx.player.bands[slot] = unit.iid
	ctx.player.log_event("band", {"slot": slot})


func on_sell(ctx: RecruitContext) -> void:
	if ctx.subject != ctx.source:
		return
	var bands: int = ctx.player.band_count()
	var pays: int = CoreUtil.to_int(ctx.params.get("all", 0))
	if bands < SEVEN:
		@warning_ignore("integer_division")
		pays = bands / 2 * CoreUtil.to_int(ctx.params.get("gold", 0))
	ctx.announce("rainbow")
	if pays > 0:
		ctx.gain_gold(pays, "now")
	ctx.player.bands.fill(0)
