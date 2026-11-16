extends Mechanic
## Parish Standard-bearer: your Mice have +attack Attack for each Mouse you have (itself and
## Cousins included), recounted as units arrive and die. Borrowed Attack (an aura).

const MouseRules := preload("res://src/content/mouse/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, _source_slot: int, target_slot: int, params: MechanicParams
) -> Vector2i:
	if not MouseRules.is_mouse(view.def_at(target_slot)):
		return Vector2i.ZERO
	return Vector2i(params.num(&"attack") * view.count_tribe(MouseRules.TRIBE), 0)
