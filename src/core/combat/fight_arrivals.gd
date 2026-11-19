class_name FightArrivals
extends RefCounted
## Who fills a slot that empties in a fight, in one place (SHARED-RULES slot-fill order). After a
## round of deaths: first each dying unit's own summons and returns (Combat's death steps 2 and
## 4), then Reserve units step into the slots friends died in (the side's fill-first slot, such
## as a Guard post, then the slot with the most Renown, then reading order), at most the side's
## reserve limit a fight (GameConfig.reserve_limit, raised by Q_RESERVE_LIMIT), then waiting
## summons in one line (Hoppers, Compost copies) into empty slots in reading order, then the
## after_death_round hook (a Recruiting Sergeant's Private, which steps in through
## Combat.step_in and doesn't count against the limit). SHARED-RULES ruling 6.

## Per side: CombatUnits from the hand waiting to step in (Reserve), in hand order.
var reserve: Array = [[], []]
## Per side: waiting summons, {"id", "source", "payload"}, in landing order.
var waiting: Array = [[], []]
## Per side: reservists from the hand that have stepped in this fight (the reserve limit).
var called: Array[int] = [0, 0]
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
			copy.reservist = true
			copy.from_hand = true
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
	var slots: Array[SlotState] = combat.bridge(side_index).slots
	open.sort_custom(
		func(a: int, b: int) -> bool:
			if slots[a].renown != slots[b].renown:
				return slots[a].renown > slots[b].renown
			return a < b
	)
	var first: int = combat.side_query(side_index, Mechanic.Q_FILL_FIRST, -1)
	if open.has(first):
		open.erase(first)
		open.push_front(first)
	for slot: int in open:
		if queue.is_empty() or combat.halted() or called[side_index] >= limit(side_index):
			return
		var unit: CombatUnit = queue.pop_front()
		called[side_index] += 1
		unit.renown_slot = slot
		combat._enter(unit, slot, null, "reserve", {"from_hand": true})


## A reservist that isn't from the hand (a Private: "a Private steps in there") steps into
## `slot`, if it is empty: a new unit of `card_id` (Created), logged as `reserve` with
## from_hand false. It gets the slot's Renown like any reservist and doesn't count against the
## reserve limit. Null, and nothing logged, when the slot is taken or the card is unknown.
func step_in(
	side_index: int, card_id: StringName, slot: int, source: CombatUnit, golden: bool = false
) -> CombatUnit:
	var combat: Combat = _combat()
	if slot < 0 or slot >= combat.geometry.slot_count or not combat.library.has(card_id):
		return null
	if combat.unit_at(side_index, slot) != null:
		return null
	var unit: CombatUnit = CombatUnit.fresh(
		combat.library.get_card(card_id),
		combat._take_uid(),
		side_index,
		golden,
		combat.registry,
		combat.config.stat_max
	)
	unit.reservist = true
	unit.renown_slot = slot
	combat._enter(unit, slot, source, "reserve", {"from_hand": false})
	return unit


## How many reservists from the hand may step in for this side this fight: GameConfig
## .reserve_limit, raised by Q_RESERVE_LIMIT (asked now, so a raise ends if its source dies).
func limit(side_index: int) -> int:
	var combat: Combat = _combat()
	return combat.side_query(side_index, Mechanic.Q_RESERVE_LIMIT, combat.config.reserve_limit)


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
