extends Mechanic
## Start of fight: Summon copies of the N highest-tier units in your Compost, with +M/+M for each
## unit in it (Elder Mother; main pass). Each copy goes to the empty slot nearest this unit; with
## no room it waits in the core's one line of waiting summons and lands after a round of deaths.
## On arrival it gains +M/+M for each Compost entry, used ones included (the standing Compost
## mechanic gives it, so it still lands bigger after the Elder Mother has died). The entries stay,
## marked copied for this fight. Copies don't run Start of fight effects.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"copies": MechanicParams.Kind.NUMBER, "per": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var side: FightSide = combat.bridge(unit.side)
	if Compost.next_copy(side).is_empty() or not combat.trigger(unit, &"thorn_elder_mother"):
		return
	var payload: Dictionary = {Compost.ELDER_PER: params.num(&"per")}
	for _i: int in params.num(&"copies"):
		var entry: Dictionary = Compost.next_copy(side)
		if entry.is_empty():
			return
		Compost.mark_copied(side, entry, unit)
		combat.summon(
			unit.side, StringName(str(entry["id"])), unit.slot, false, unit, true, payload
		)
