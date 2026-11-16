# gdlint: disable=max-public-methods
# A fight hook may use any of these, so the fight API is one class on purpose.
class_name FightSide
extends RefCounted
## One side of a fight and its bridge to the player (12.1.1, 9.1.1's exception). Mechanics reach
## it with combat.bridge(n). It holds the player's lasting numbers and heaps (the real ones when the
## side writes back, copies for the ghost or a bare test fight), the slot effects copied into the
## fight (8.5.2), and this fight's per-side numbers. "Permanently" changes also go to the real
## unit, slot or player when the side writes back; otherwise they last this fight only.

var index: int = 0
## The player, or null for a bare fight (tests).
var player: PlayerState
## True when permanent changes reach the player (a live player; not the ghost).
var writes_back: bool = false
var counters: Dictionary = {}
var heaps: Dictionary = {}
var slots: Array[SlotState] = []
var standing: Array[BoundMechanic] = []
## Units of this side that died this fight (9.7), tokens included.
var deaths: int = 0
## Numbers a mechanic keeps for this side for this fight only.
var state: Dictionary = {}
## Heap name -> the `n` of each entry marked used for this fight (heap_use); the heap itself
## doesn't change.
var used: Dictionary = {}
## The percent of their Attack buff this side's slots give for the rest of the fight (base 100;
## the Edgewright sets 200). Kept if the unit that set it dies (set_slot_attack_percent).
var slot_attack_percent: int = 100
var _combat_ref: WeakRef


static func create(
	combat: Combat, side: int, owner: PlayerState, live: bool, slot_count: int
) -> FightSide:
	var made := FightSide.new()
	made._combat_ref = weakref(combat)
	made.index = side
	made.player = owner
	made.writes_back = owner != null and live
	if owner != null:
		made.standing = owner.standing
		made.counters = owner.counters if made.writes_back else owner.counters.duplicate()
		if made.writes_back:
			made.heaps = owner.heaps
		else:
			for key: Variant in owner.heaps:
				var heap_found: CardHeap = owner.heaps[key]
				made.heaps[key] = heap_found.duplicate_heap()
		for each_slot: SlotState in owner.slots:
			made.slots.append(each_slot.duplicate_slot())
	while made.slots.size() < slot_count:
		made.slots.append(SlotState.new())
	return made


func _combat() -> Combat:
	var found: Combat = _combat_ref.get_ref()
	return found


## The recruit unit (board or hand) a fight unit copies, to read; null for one made in the
## fight. A ghost or saved board has one too; use real_unit to change it.
func recruit_unit(unit: CombatUnit) -> Unit:
	if player == null or unit == null or unit.recruit_uid < 0:
		return null
	return player.find_uid(unit.recruit_uid)


## The recruit-board unit a fight unit copies, when this side writes back; else null.
func real_unit(unit: CombatUnit) -> Unit:
	if not writes_back or unit == null or unit.recruit_uid < 0:
		return null
	return player.find_uid(unit.recruit_uid)


func counter(key: StringName) -> int:
	return CoreUtil.to_int(counters.get(key, 0))


## A player-level number ("this game", 12.1.1). Lasts the game when this side writes back.
func add_counter(key: StringName, amount: int, source: CombatUnit) -> void:
	var combat: Combat = _combat()
	combat.registry.check_name(key, "player counter")
	counters[key] = counter(key) + amount
	combat.log_side(
		self, {"type": "player_counter", "key": String(key), "value": counter(key)}, source
	)
	combat._refresh_auras()


## A number on a unit. `permanent` writes it to the recruit unit too (Unit.counters).
func add_unit_counter(
	unit: CombatUnit, key: StringName, amount: int, permanent: bool, source: CombatUnit
) -> void:
	_combat().registry.check_name(key, "unit counter")
	unit.counters[key] = unit.counter(key) + amount
	var real: Unit = real_unit(unit) if permanent else null
	if real != null:
		real.counters[key] = real.counter(key) + amount
	(
		_combat()
		. log_side(
			self,
			{
				"type": "counter",
				"slot": unit.slot,
				"uid": unit.uid,
				"key": String(key),
				"value": unit.counter(key),
				"permanent": real != null,
			},
			source
		)
	)


## The named heap, made empty on first use (the player's own when this side writes back).
func heap(heap_name: StringName) -> CardHeap:
	if not heaps.has(heap_name):
		_combat().registry.check_name(heap_name, "heap")
		heaps[heap_name] = CardHeap.new()
	var found: CardHeap = heaps[heap_name]
	return found


func heap_add(heap_name: StringName, card_id: StringName, tier: int, source: CombatUnit) -> void:
	heap(heap_name).add(card_id, tier)
	var combat: Combat = _combat()
	combat.log_side(
		self,
		{
			"type": "heap_add",
			"heap": String(heap_name),
			"id": String(card_id),
			"size": heap(heap_name).size()
		},
		source
	)
	combat._notify_heap_added(index, heap_name, card_id)
	combat._refresh_auras()


## Spends the `count` lowest entries (CardHeap.spend_lowest). False, and nothing spent, if the
## heap has fewer.
func heap_spend(heap_name: StringName, count: int, source: CombatUnit) -> bool:
	var spent: Array[StringName] = heap(heap_name).spend_lowest(count)
	if spent.is_empty():
		return false
	_heap_removed(heap_name, spent, source)
	return true


## Marks the `count` highest-tier entries not yet used this fight (newest first on a tie) used
## for this fight; they stay in the heap. False, and nothing marked, if fewer are unused. The
## `heap_use` event names each entry (`ids`, `entries` by `n`) so a screen shows which.
func heap_use(heap_name: StringName, count: int, source: CombatUnit) -> bool:
	if heap_unused(heap_name) < count or count <= 0:
		return false
	var marked: Array[Dictionary] = []
	for _i: int in count:
		marked.append(_mark(heap_name))
	_log_use(heap_name, marked, source)
	return true


## "Copy the highest-tier unit in your Compost" (Old Stump, Elder Mother): marks the highest-tier
## entry not yet used this fight and returns it ({"id", "tier", "n"}), or {} with nothing marked
## when none is left. Right when the heap changes mid-fight: marks name entries, not a count.
func heap_use_highest(heap_name: StringName, source: CombatUnit) -> Dictionary:
	if heap_unused(heap_name) <= 0:
		return {}
	var entry: Dictionary = _mark(heap_name)
	_log_use(heap_name, [entry], source)
	return entry


## Entries still in the heap and not yet marked used this fight.
func heap_unused(heap_name: StringName) -> int:
	var marks: Array = used.get(heap_name, [])
	var count: int = 0
	for entry: Dictionary in heap(heap_name).entries:
		if not marks.has(CoreUtil.to_int(entry.get("n", 0))):
			count += 1
	return count


func _mark(heap_name: StringName) -> Dictionary:
	var marks: Array = used.get(heap_name, [])
	var entry: Dictionary = heap(heap_name).highest_except(marks)
	marks.append(CoreUtil.to_int(entry.get("n", 0)))
	used[heap_name] = marks
	return entry


func _log_use(heap_name: StringName, marked: Array[Dictionary], source: CombatUnit) -> void:
	_combat().log_side(
		self,
		{
			"type": "heap_use",
			"heap": String(heap_name),
			"count": marked.size(),
			"ids": marked.map(func(e: Dictionary) -> String: return str(e["id"])),
			"entries": marked.map(func(e: Dictionary) -> int: return CoreUtil.to_int(e["n"])),
			"unused": heap_unused(heap_name)
		},
		source
	)


## Takes the highest entry (CardHeap.take_highest); &"" when empty.
func heap_take(heap_name: StringName, source: CombatUnit) -> StringName:
	var card_id: StringName = heap(heap_name).take_highest()
	if card_id != &"":
		_heap_removed(heap_name, [card_id] as Array[StringName], source)
	return card_id


func _heap_removed(heap_name: StringName, ids: Array[StringName], source: CombatUnit) -> void:
	var combat: Combat = _combat()
	combat.log_side(
		self,
		{
			"type": "heap_remove",
			"heap": String(heap_name),
			"ids": ids.map(func(c: StringName) -> String: return String(c)),
			"size": heap(heap_name).size()
		},
		source
	)
	combat._refresh_auras()


func slot(slot_index: int) -> SlotState:
	return slots[slot_index]


## "Your slots give double Attack this fight" (SHARED-RULES 13): the side's slots give `percent`
## of their stored Attack buff for the rest of the fight, even if `source` dies. Two don't stack:
## the bigger applies. Logged as `slot_percent`; every unit whose Attack changes gets `stats`.
func set_slot_attack_percent(percent: int, source: CombatUnit) -> void:
	if percent <= slot_attack_percent:
		return
	slot_attack_percent = percent
	var combat: Combat = _combat()
	combat.log_side(self, {"type": "slot_percent", "percent": percent}, source)
	combat._refresh_auras()


## The Attack the slot gives this fight: its stored buff at the fight's percent (what a unit
## there gets, and what anything that reads a slot's Attack buff should read).
func slot_attack_given(slot_index: int) -> int:
	return int(slots[slot_index].attack * FightAuras.slot_attack_percent(_combat(), index) / 100.0)


## A slot as a screen shows it in a fight: the stored buff and keywords, plus `given_attack`
## (what it gives at this fight's percent) and the `percent`.
func slot_view(slot_index: int) -> Dictionary:
	var out: Dictionary = slots[slot_index].view()
	out["given_attack"] = slot_attack_given(slot_index)
	out["percent"] = FightAuras.slot_attack_percent(_combat(), index)
	return out


## 8.5 a slot buff, and optionally a keyword the slot gives. This fight only, unless
## `permanent` and this side writes back (8.5.2).
func slot_buff(
	slot_index: int,
	attack: int,
	health: int,
	permanent: bool,
	source: CombatUnit,
	keyword: StringName = &""
) -> void:
	var lasting: bool = permanent and writes_back
	if player != null:
		var percent: int = _combat().rules_percent(player)
		attack = int(attack * percent / 100.0)
		health = int(health * percent / 100.0)
	var targets: Array[SlotState] = [slots[slot_index]]
	if lasting:
		targets.append(player.slots[slot_index])
	for each_slot: SlotState in targets:
		each_slot.attack += attack
		each_slot.health += health
		if keyword != &"" and not each_slot.keywords.has(keyword):
			each_slot.keywords.append(keyword)
	_log_slot(slot_index, attack, health, lasting, source)


## Sets a slot's buff to these values, unscaled (a copy is not a buff given: Colour Ensign,
## SHARED-RULES 12). This fight only, unless `permanent` and this side writes back.
func slot_set(
	slot_index: int, attack: int, health: int, permanent: bool, source: CombatUnit
) -> void:
	var lasting: bool = permanent and writes_back
	var targets: Array[SlotState] = [slots[slot_index]]
	if lasting:
		targets.append(player.slots[slot_index])
	var before: SlotState = targets[targets.size() - 1]
	var change := Vector2i(attack - before.attack, health - before.health)
	for each_slot: SlotState in targets:
		each_slot.attack = attack
		each_slot.health = health
	_log_slot(slot_index, change.x, change.y, lasting, source)


## Clears a keyword from a slot (moving a Guard post): this fight, or for good.
func slot_clear_keyword(
	slot_index: int, keyword: StringName, permanent: bool, source: CombatUnit
) -> void:
	var lasting: bool = permanent and writes_back
	var targets: Array[SlotState] = [slots[slot_index]]
	if lasting:
		targets.append(player.slots[slot_index])
	for each_slot: SlotState in targets:
		each_slot.keywords.erase(keyword)
	_log_slot(slot_index, 0, 0, lasting, source)


func _log_slot(
	slot_index: int, attack: int, health: int, lasting: bool, source: CombatUnit
) -> void:
	var combat: Combat = _combat()
	combat.log_side(
		self,
		{
			"type": "slot",
			"slot": slot_index,
			"attack": attack,
			"health": health,
			"total": slot_view(slot_index),
			"permanent": lasting
		},
		source
	)
	combat._refresh_auras()


## 11.1.1 a unit gains a keyword (a mechanic with no parameters): this fight, or for good.
func give_keyword(
	unit: CombatUnit, keyword: StringName, permanent: bool, source: CombatUnit = null
) -> bool:
	var combat: Combat = _combat()
	if unit == null or unit.gone or not combat.registry.has(keyword):
		return false
	var lasting: bool = false
	if permanent:
		var real: Unit = real_unit(unit)
		lasting = real != null and real.grant(combat.registry, keyword)
	if unit.mechanics.any(func(b: BoundMechanic) -> bool: return b.id == keyword):
		return lasting
	var bound: BoundMechanic = combat.registry.bind(MechanicSpec.new(keyword), unit.golden, true)
	unit.mechanics.append(bound)
	bound.mechanic.on_combat_begin(combat, unit, bound.params)
	combat.log_side(
		self,
		{
			"type": "keyword",
			"slot": unit.slot,
			"uid": unit.uid,
			"keyword": String(keyword),
			"on": true
		},
		source
	)
	return true


## A unit gains a mechanic with parameters ("+2 Fury" onto a unit with none: Sett Sexton,
## Sword-heir): this fight, or also on the recruit unit when `permanent` and this side writes
## back. `raw` holds its parameters as card data does; the numbers are the giver's, never doubled
## by a golden target. Its on_combat_begin runs; logged as `effect`. False when unknown or bad.
func give_effect(
	unit: CombatUnit, mechanic_id: StringName, raw: Dictionary, permanent: bool, source: CombatUnit
) -> bool:
	var combat: Combat = _combat()
	if unit == null or unit.gone:
		return false
	var bound: BoundMechanic = combat.registry.bind_given(mechanic_id, raw)
	if bound == null:
		return false
	var real: Unit = real_unit(unit) if permanent else null
	if real != null:
		real.grant_effect(combat.registry, mechanic_id, raw)
	unit.mechanics.append(bound)
	bound.mechanic.on_combat_begin(combat, unit, bound.params)
	(
		combat
		. log_side(
			self,
			{
				"type": "effect",
				"slot": unit.slot,
				"uid": unit.uid,
				"mechanic": String(mechanic_id),
				"params": raw.duplicate(),
				"permanent": real != null,
			},
			source
		)
	)
	combat._refresh_auras()
	return true


## Gold earned in the fight, paid at the start of the next turn; nothing for a copy side.
func add_gold(amount: int, source: CombatUnit) -> void:
	if not writes_back:
		return
	player.gold_next_turn += amount
	_combat().log_side(self, {"type": "gold", "amount": amount, "next_turn": true}, source)


## Heap name -> its size, for the fight log.
func heap_sizes() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in heaps:
		var found: CardHeap = heaps[key]
		out[str(key)] = found.size()
	return out


func state_int(key: StringName) -> int:
	return CoreUtil.to_int(state.get(key, 0))


func set_state(key: StringName, value: int) -> void:
	_combat().registry.check_name(key, "side state")
	state[key] = value
