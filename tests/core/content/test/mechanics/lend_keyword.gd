extends Mechanic
## An aura that gives a keyword: adjacent units have `keyword`.


func param_kinds() -> Dictionary:
	return {"keyword": MechanicParams.Kind.TEXT}


func has_aura() -> bool:
	return true


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if source_slot >= 0 and view.geometry.adjacent(source_slot).has(target_slot):
		out.append(StringName(params.text(&"keyword")))
	return out
