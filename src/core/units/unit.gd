class_name Unit
extends RefCounted
## One card a player holds, in hand or on the recruit board: a unit or a Tavern spell.
## `copies` counts copies of a real card for sell value (4.3.3–4.3.4). A unit starts with one
## copy, and a triple combines three. `bought_copies` tracks origin for Compost and token sales.
## A Bought unit starts with one bought copy, and a Created unit starts with zero.

var uid: int = 0
var def: UnitDef
var golden: bool = false
var copies: int = 1
var bought_copies: int = 0
var stats: StatBlock
## Own text first (golden already applied to its numbers), then granted mechanics.
var mechanics: Array[BoundMechanic] = []
## Board slot, or -1 in hand.
var slot: int = -1
## Prototype economy commitment: an own Recruit Phase effect worked this turn.
var worked_this_turn: bool = false
## Lasting mechanic numbers on this unit (remaining Supply), kept for the game and
## copied into each fight. Keys are mechanic-chosen names.
var counters: Dictionary = {}
## Mechanic numbers that reset at the start of each turn (uses of an ability this turn).
var turn_counters: Dictionary = {}
## Keywords this unit has from an aura or its slot, recalculated with auras (12.2.1).
var aura_mechanics: Array[BoundMechanic] = []


static func create(
	card: UnitDef, new_uid: int, is_golden: bool, registry: MechanicRegistry, stat_max: int
) -> Unit:
	var unit := Unit.new()
	unit.uid = new_uid
	unit.def = card
	unit.golden = is_golden
	var factor: int = 2 if is_golden else 1
	unit.stats = StatBlock.of(card.attack * factor, card.health * factor, stat_max)
	for spec: MechanicSpec in card.mechanics:
		var bound: BoundMechanic = registry.bind(spec, is_golden, false)
		unit.mechanics.append(bound)
		if bound.params.num(&"supply") > 0:
			unit.counters["supply:%s" % bound.id] = bound.params.num(&"supply")
	return unit


func is_bought() -> bool:
	return bought_copies > 0


func is_spell() -> bool:
	return def.is_spell()


func attack() -> int:
	return stats.attack()


func health() -> int:
	return stats.max_health()


func has_mechanic(mechanic_id: StringName) -> bool:
	for bound: BoundMechanic in hooks():
		if bound.id == mechanic_id:
			return true
	return false


## Every mechanic whose hooks run for this unit: its own text, then what auras and its slot give.
func hooks() -> Array[BoundMechanic]:
	if aura_mechanics.is_empty():
		return mechanics
	var out: Array[BoundMechanic] = mechanics.duplicate()
	out.append_array(aura_mechanics)
	return out


## Has a death effect (Mechanic.has_death_effect), its own or given.
func has_death_effect() -> bool:
	return hooks().any(func(b: BoundMechanic) -> bool: return b.mechanic.has_death_effect())


func counter(key: StringName) -> int:
	return CoreUtil.to_int(counters.get(key, 0))


func turn_counter(key: StringName) -> int:
	return CoreUtil.to_int(turn_counters.get(key, 0))


## 11.1.1 gain a keyword (no parameters). False if the unit has it already or it is unknown.
func grant(registry: MechanicRegistry, mechanic_id: StringName) -> bool:
	if has_mechanic(mechanic_id) or not registry.has(mechanic_id):
		return false
	mechanics.append(registry.bind(MechanicSpec.new(mechanic_id), golden, true))
	return true


## Gains a mechanic with parameters ('Give a unit "+1 Fury"'), checked like card data. Unlike a
## keyword it may stack: a second grant adds another, and a mechanic that sums its numbers (Fury)
## adds them up. The numbers are the giver's (already doubled if the giver is golden), so a golden
## target never doubles them again (7.3.5). Use RecruitContext.give_effect or
## FightSide.give_effect, which log it. False when the mechanic is unknown or the params are wrong.
func grant_effect(registry: MechanicRegistry, mechanic_id: StringName, raw: Dictionary) -> bool:
	var bound: BoundMechanic = registry.bind_given(mechanic_id, raw)
	if bound == null:
		return false
	mechanics.append(bound)
	return true


## The keyword mechanics (those with no parameters), for display.
func keyword_ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for bound: BoundMechanic in hooks():
		if bound.params.to_dict().is_empty() and not out.has(String(bound.id)):
			out.append(String(bound.id))
	return out


## JSON-shaped view for logs and the UI.
func view() -> Dictionary:
	return {
		"uid": uid,
		"id": String(def.id),
		"slot": slot,
		"attack": attack(),
		"health": health(),
		"golden": golden,
		"bought": is_bought(),
		"worked_this_turn": worked_this_turn,
		"keywords": Array(keyword_ids()),
		"counters": UnitText.counters_view(counters),
		"effects": UnitText.effects_view(mechanics),
		"totals": UnitText.totals_view(hooks()),
		"text": UnitText.text_of(def, mechanics, golden),
		"reminders": Array(def.reminders),
	}
