class_name Unit
extends RefCounted
## One card a player holds, in hand or on the recruit board: a unit or a Tavern spell.
## Origin (4.3.1) is tracked by copies: `bought_copies` is how many of its copies were paid for
## (sell value, 4.3.3-4.3.4) and `pool_copies` how many came from the shared pool (what returns
## to the pool, 5.3.4-5.3.8). A Bought unit is 1/1, a Discover pick or Triple Reward unit 0/1
## (4.3.2), a token 0/0, a tripled golden the sum of its three copies.

var uid: int = 0
var def: UnitDef
var golden: bool = false
## 7.3.6 made by a triple: playing it gives the Triple Reward.
var from_triple: bool = false
var bought_copies: int = 0
var pool_copies: int = 0
var stats: StatBlock
## Own text first (golden already applied to its numbers), then granted mechanics.
var mechanics: Array[BoundMechanic] = []
## Board slot, or -1 in hand.
var slot: int = -1
## Lasting mechanic numbers on this unit (a medal count, a charge), kept for the game and
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
		unit.mechanics.append(registry.bind(spec, is_golden, false))
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


## 11.1.1 lose a keyword (no parameters) from its own text or a grant. False if it had none.
func remove_keyword(mechanic_id: StringName) -> bool:
	for i: int in mechanics.size():
		if mechanics[i].id == mechanic_id and mechanics[i].params.to_dict().is_empty():
			mechanics.remove_at(i)
			return true
	return false


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
		"keywords": Array(keyword_ids()),
		"counters": UnitText.counters_view(counters),
		"effects": UnitText.effects_view(mechanics),
		"text": UnitText.text_of(def, mechanics, golden),
		"reminders": Array(def.reminders),
	}
