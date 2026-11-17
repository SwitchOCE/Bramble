class_name FightArrivals
extends RefCounted
## Who fills a slot that empties in a fight, in one place (SHARED-RULES slot-fill order). After a
## round of deaths: first each dying unit's own summons and returns (Combat's death steps 2 and
## 4), then Reserve units step into the slots friends died in (the side's fill-first slot, such
## as a Guard post, then reading order), then waiting summons in one line (Hoppers, Compost
## copies) into empty slots in reading order, then the after_death_round hook (a Recruiting
## Sergeant's Private). SHARED-RULES ruling 6.

## Per side: CombatUnits from the hand waiting to step in (Reserve), in hand order.
var reserve: Array = [[], []]
## Per side: waiting summons, {"id", "source", "payload"}, in landing order.
var waiting: Array = [[], []]
var _combat_ref: WeakRef


static func create(combat: Combat) -> FightArrivals:
	var made := FightArrivals.new()
	made._combat_ref = weakref(combat)
	return made


func _combat() -> Combat:
	var found: Combat = _combat_ref.get_ref()
	return found


## Copies each side's hand units that have Reserve (Q_RESERVE), or every hand unit when the
## side says so (Q_HAND_RESERVE), with their buffs, as waiting units. Spells stay behind.
func take_reserve(hands: Array) -> void:
	var combat: Combat = _combat()
	for side_index: int in mini(2, hands.size()):
		var everyone: bool = combat.side_query(side_index, Mechanic.Q_HAND_RESERVE, 0) != 0
		var queue: Array = reserve[side_index]
		for value: Variant in hands[side_index]:
			var card: Unit = value
			if card == null or card.is_spell():
				continue
			var copy: CombatUnit = CombatUnit.from_unit(card, combat._take_uid(), side_index)
			copy.slot = -1
			copy.starting = false
			if everyone or copy.query(Mechanic.Q_RESERVE, 0) != 0:
				queue.append(copy)


## The reserve as the fight log shows it at the start: [[unit view], [unit view]].
func reserve_view(geometry: BoardGeometry) -> Array:
	var out: Array = []
	for side_index: int in 2:
		var queue: Array = reserve[side_index]
		out.append(queue.map(func(u: CombatUnit) -> Dictionary: return u.view(geometry)))
	return out


## Queues a summon that found no room; it keeps its source and payload.
func wait(
	side_index: int,
	card_id: StringName,
	source: CombatUnit,
	payload: Dictionary,
	golden: bool = false
) -> void:
	var queue: Array = waiting[side_index]
	queue.append({"id": card_id, "source": source, "payload": payload, "golden": golden})


## The slot-fill order after one round of deaths. `emptied` [[slot], [slot]]: slots units died
## in this round. Active side first.
func after_deaths(emptied: Array, active_side: int) -> void:
	var combat: Combat = _combat()
	for side_index: int in [active_side, 1 - active_side]:
		var died_in: Array = emptied[side_index]
		_step_in(side_index, died_in)
	for side_index: int in [active_side, 1 - active_side]:
		_land(side_index)
	for side_index: int in [active_side, 1 - active_side]:
		combat._notify(side_index, &"after_death_round", [])


func _step_in(side_index: int, died_in: Array) -> void:
	var combat: Combat = _combat()
	var queue: Array = reserve[side_index]
	if queue.is_empty():
		return
	var open: Array[int] = []
	for value: Variant in died_in:
		var slot: int = CoreUtil.to_int(value)
		if combat.unit_at(side_index, slot) == null and not open.has(slot):
			open.append(slot)
	open.sort()
	var first: int = combat.side_query(side_index, Mechanic.Q_FILL_FIRST, -1)
	if open.has(first):
		open.erase(first)
		open.push_front(first)
	for slot: int in open:
		if queue.is_empty() or combat.halted():
			return
		var unit: CombatUnit = queue.pop_front()
		combat._enter(unit, slot, null, "reserve", {})


func _land(side_index: int) -> void:
	var combat: Combat = _combat()
	var queue: Array = waiting[side_index]
	while not queue.is_empty() and not combat.halted():
		var slot: int = combat.geometry.summon_slot(combat._occupied(side_index), -1, false)
		if slot < 0:
			return
		var entry: Dictionary = queue.pop_front()
		var card_id: StringName = entry["id"]
		var source: CombatUnit = entry["source"]
		var payload: Dictionary = entry["payload"]
		var unit: CombatUnit = CombatUnit.fresh(
			combat.library.get_card(card_id),
			combat._take_uid(),
			side_index,
			CoreUtil.to_bool(entry.get("golden", false)),
			combat.registry,
			combat.config.stat_max
		)
		unit.state.merge(payload, true)
		combat._enter(unit, slot, source, "summon", {"waited": true, "payload": payload})
