extends Mechanic
## Old Campaigner: after each fight, earn `medals` Medals, or `survived` if its fight copy was
## alive at the end. Decorated (3+ Medals): Stiff Upper Lip, given to itself as an aura so it
## follows the Medal count in both phases.

const Medals := preload("res://src/content/pigeon/lib/medals.gd")


func param_kinds() -> Dictionary:
	return {"medals": MechanicParams.Kind.NUMBER, "survived": MechanicParams.Kind.NUMBER}


func after_fight(
	ctx: RecruitContext, unit: Unit, report: FightReport, params: MechanicParams
) -> void:
	if unit == null or not ctx.trigger(unit, &"pigeon_campaigner"):
		return
	var count: int = params.num(&"survived") if report.survived(unit) else params.num(&"medals")
	Medals.earn(ctx, unit, count, unit)


func has_aura() -> bool:
	return true


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if source_slot >= 0 and source_slot == target_slot and Medals.decorated(view, source_slot):
		out.append(&"pigeon_stiff_upper_lip")
	return out
