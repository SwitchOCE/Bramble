extends Mechanic
## 12.2.1 an aura: adjacent units (8.2.2) have +amount Attack while this is on the board.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura(
	geometry: BoardGeometry, source_slot: int, target_slot: int, params: MechanicParams
) -> Vector2i:
	if geometry.adjacent(source_slot).has(target_slot):
		return Vector2i(params.num(&"amount"), 0)
	return Vector2i.ZERO
