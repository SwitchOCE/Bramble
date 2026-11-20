extends Mechanic
## Start of fight: Summon copies of the N highest-tier units in your Compost, with +M/+M for each
## unit in it (Elder Mother; main pass). Each copy goes to the empty slot nearest this unit; with
## no room the copy is lost. On arrival the standing Compost mechanic gives it +M/+M per entry,
## including entries marked used this fight. Entries stay in the heap. Only entries that are
## copied are marked used (FightSide.heap_use_highest). Copies don't run Start of fight effects.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"copies": MechanicParams.Kind.NUMBER, "per": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var side: FightSide = combat.bridge(unit.side)
	if side.heap_unused(Compost.HEAP) <= 0 or not Compost.has_room(combat, unit.side):
		return
	if not combat.trigger(unit, &"thorn_elder_mother"):
		return
	var payload: Dictionary = {Compost.ELDER_PER: params.num(&"per")}
	for _i: int in params.num(&"copies"):
		if not Compost.has_room(combat, unit.side):
			return
		var entry: Dictionary = side.heap_use_highest(Compost.HEAP, unit)
		if entry.is_empty():
			return
		combat.summon(unit.side, StringName(str(entry["id"])), unit.slot, false, unit, payload)
