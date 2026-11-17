extends Mechanic
## Standing (no unit): every Bought copy sold goes into the heap.


func on_any_sold(ctx: RecruitContext, _unit: Unit, sold: Unit, _params: MechanicParams) -> void:
	for _copy: int in sold.bought_copies:
		ctx.heap_add(&"test_heap", sold.def.id, null)
