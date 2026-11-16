class_name Combat
extends RefCounted
## One fight (rulebook chapter 9) between two recruit boards, as a JSON-shaped event log.
## Phase order, each step named by its rule:
##   9.1 copy boards -> on_combat_begin -> combat_start event
##   9.2.1 first attacker -> 9.3 Start of Combat (random player first, reading order, deaths after
##   each effect) -> 9.4 alternate attacks (attack pointer, 9.4.5) -> each attack 9.6.1:
##   on_attacked, on_attack, damage exchange (+ cleave splash), death resolution 9.7 ->
##   9.9 end, or 9.10 limits (ties).
## Randomness comes from sub-streams of the fight's seed (prototype lesson 7): "first", "soc",
## "target" and "effect", so one new random mechanic can't move every later target.
## Mechanics act only through the public methods below (trigger, buff, deal_damage, destroy,
## summon, select, random_enemy...). Combat names no keyword itself.

const REASON_BOARD_EMPTY: String = "board_empty"
const REASON_NO_ATTACKS: String = "no_attacks"
const REASON_ATTACK_LIMIT: String = "attack_limit"
const REASON_TRIGGER_LIMIT: String = "trigger_limit"
const REASONS: PackedStringArray = [
	REASON_BOARD_EMPTY, REASON_NO_ATTACKS, REASON_ATTACK_LIMIT, REASON_TRIGGER_LIMIT
]

var geometry: BoardGeometry
var config: GameConfig
var registry: MechanicRegistry
var library: UnitLibrary
var events: Array[Dictionary] = []
## sides[side][slot] -> CombatUnit or null.
var sides: Array = [[], []]
## 9.4.5 per side: the slot of its latest attack this cycle; -1 at the start of a cycle.
var pointers: Array[int] = [-1, -1]
var effect_rng: Rng
var player_ids: Array[int] = [-1, -1]
var result: Dictionary = {}
var _first_rng: Rng
var _soc_rng: Rng
var _target_rng: Rng
var _next_uid: int = 1
var _attacks: int = 0
var _triggers: int = 0
var _halt_reason: String = ""
var _active_side: int = 0
var _starting_uids: Array = [[], []]
## Victim uid -> the unit whose damage last hit it, for "after a unit kills" (9.7.2 step 1).
var _hit_by: Dictionary = {}
var _units_cache: Array = [null, null]


static func create(
	game_geometry: BoardGeometry,
	game_config: GameConfig,
	mechanic_registry: MechanicRegistry,
	unit_library: UnitLibrary,
	fight_seed: int
) -> Combat:
	var combat := Combat.new()
	combat.geometry = game_geometry
	combat.config = game_config
	combat.registry = mechanic_registry
	combat.library = unit_library
	combat._first_rng = Rng.derive(fight_seed, "first")
	combat._soc_rng = Rng.derive(fight_seed, "soc")
	combat._target_rng = Rng.derive(fight_seed, "target")
	combat.effect_rng = Rng.derive(fight_seed, "effect")
	return combat


## Runs the fight. `boards` is [board_a, board_b], each an Array of Unit or null per slot.
func run(boards: Array, ids: Array[int]) -> Dictionary:
	player_ids = ids
	_setup(boards)
	var first: int = _first_side()
	_log(
		{
			"type": "combat_start",
			"players": player_ids.duplicate(),
			"first": first,
			"boards": [_board_view(0), _board_view(1)]
		}
	)
	_start_of_combat()
	var side: int = first
	while _halt_reason == "":
		if _board_empty(0) or _board_empty(1):
			_halt_reason = REASON_BOARD_EMPTY
			break
		if not _side_can_attack(0) and not _side_can_attack(1):
			_halt_reason = REASON_NO_ATTACKS
			break
		if _attacks >= config.attack_limit:
			_halt_reason = REASON_ATTACK_LIMIT
			break
		if _side_can_attack(side):
			_take_turn(side)
		else:
			_log({"type": "pass", "side": side})
		side = 1 - side
	return _finish()


# --- Setup ----------------------------------------------------------------------------------------


func _setup(boards: Array) -> void:
	for side: int in 2:
		var row: Array = []
		row.resize(geometry.slot_count)
		sides[side] = row
		var board: Array = boards[side]
		for slot: int in mini(board.size(), geometry.slot_count):
			var source: Unit = board[slot]
			if source == null:
				continue
			var unit: CombatUnit = CombatUnit.from_unit(source, _take_uid(), side)
			unit.slot = slot
			row[slot] = unit
			_units_cache[side] = null
			var starting: Array = _starting_uids[side]
			starting.append(unit.uid)
	for side: int in 2:
		for unit: CombatUnit in units(side):
			for bound: BoundMechanic in unit.mechanics:
				bound.mechanic.on_combat_begin(self, unit, bound.params)
		_refresh_auras(side)


func _take_uid() -> int:
	_next_uid += 1
	return _next_uid - 1


## 9.2.1 more units attacks first; a tie is random.
func _first_side() -> int:
	var counts: Array[int] = [units(0).size(), units(1).size()]
	if counts[0] != counts[1]:
		return 0 if counts[0] > counts[1] else 1
	return _first_rng.range_int(0, 1)


## 9.3: only the unit phase applies on this track (no heroes or player modifiers yet). One
## random player resolves all their Start of Combat units, then the other (9.3.2). Deaths
## resolve after each effect (9.3.5).
func _start_of_combat() -> void:
	var first: int = _soc_rng.range_int(0, 1)
	for side: int in [first, 1 - first]:
		for unit: CombatUnit in units(side):
			if unit.gone:
				continue
			for bound: BoundMechanic in unit.mechanics:
				if unit.gone or _halt_reason != "":
					break
				_active_side = side
				bound.mechanic.on_start_of_combat(self, unit, bound.params)
				resolve_deaths(side)


# --- Attacks ------------------------------------------------------------------------------------


## 9.4.5 step 1: on the board, Attack above 0.
func can_attack(unit: CombatUnit) -> bool:
	return unit != null and not unit.gone and unit.attack() > 0


func _side_can_attack(side: int) -> bool:
	for unit: CombatUnit in units(side):
		if can_attack(unit):
			return true
	return false


## 9.4.5 steps 2-3: the lowest slot that can attack and isn't flagged, resetting the cycle once.
func _next_attacker(side: int) -> CombatUnit:
	for pass_number: int in 2:
		for unit: CombatUnit in units(side):
			if can_attack(unit) and not unit.flagged:
				return unit
		if pass_number == 0:
			for unit: CombatUnit in units(side):
				unit.flagged = false
			pointers[side] = -1
	return null


func _take_turn(side: int) -> void:
	var attacker: CombatUnit = _next_attacker(side)
	if attacker == null:
		_log({"type": "pass", "side": side})
		return
	# 9.4.5 step 5: P = its slot; it and every unit in a lower slot are flagged.
	pointers[side] = attacker.slot
	for unit: CombatUnit in units(side):
		if unit.slot <= attacker.slot:
			unit.flagged = true
	# 9.4.11 repeat attacks back to back, a new target each, while it lives and has Attack.
	var swings: int = maxi(1, attacker.query(Mechanic.Q_ATTACKS, 1))
	for _swing: int in swings:
		if not can_attack(attacker) or _halt_reason != "" or _attacks >= config.attack_limit:
			break
		var defender: CombatUnit = choose_target(attacker)
		if defender == null:
			break
		_attack(attacker, defender)


## 9.5.1-9.5.5: front row if any lives, else back row; drop untargetable unless all are;
## must-be-attacked units first; then random.
func choose_target(attacker: CombatUnit) -> CombatUnit:
	var enemy: int = 1 - attacker.side
	var front: Array[CombatUnit] = []
	var back: Array[CombatUnit] = []
	for unit: CombatUnit in units(enemy):
		if geometry.is_front(unit.slot):
			front.append(unit)
		else:
			back.append(unit)
	var candidates: Array[CombatUnit] = front if not front.is_empty() else back
	if candidates.is_empty():
		return null
	var visible: Array[CombatUnit] = candidates.filter(
		func(u: CombatUnit) -> bool: return u.query(Mechanic.Q_UNTARGETABLE, 0) == 0
	)
	if not visible.is_empty():
		candidates = visible
	var taunts: Array[CombatUnit] = candidates.filter(
		func(u: CombatUnit) -> bool: return u.query(Mechanic.Q_TAUNT, 0) != 0
	)
	if not taunts.is_empty():
		candidates = taunts
	return candidates[_target_rng.index(candidates.size())]


## 9.6.1 one attack.
func _attack(attacker: CombatUnit, defender: CombatUnit) -> void:
	_attacks += 1
	_active_side = attacker.side
	_log(
		{
			"type": "attack",
			"side": attacker.side,
			"slot": attacker.slot,
			"uid": attacker.uid,
			"target_side": defender.side,
			"target_slot": defender.slot,
			"target_uid": defender.uid
		}
	)
	for bound: BoundMechanic in defender.mechanics:
		bound.mechanic.on_attacked(self, defender, attacker, bound.params)
	for bound: BoundMechanic in attacker.mechanics:
		bound.mechanic.on_attack(self, attacker, defender, bound.params)
	var both_standing: bool = not defender.should_die() and not attacker.should_die()
	if both_standing and not defender.gone and not attacker.gone:
		_exchange(attacker, defender)
	resolve_deaths(attacker.side)


## 9.6.1 step 3, 9.6.2: both deal damage at once; the attacker's damage (and its splash) resolves
## first. Amounts are read before any damage lands.
func _exchange(attacker: CombatUnit, defender: CombatUnit) -> void:
	var dealt: int = attacker.attack()
	var taken: int = defender.attack()
	var splash: Array[CombatUnit] = []
	if attacker.query(Mechanic.Q_CLEAVE, 0) != 0:
		for slot: int in geometry.adjacent(defender.slot):
			var near: CombatUnit = unit_at(defender.side, slot)
			if near != null:
				splash.append(near)
	deal_damage(attacker, defender, dealt)
	for near: CombatUnit in splash:
		deal_damage(attacker, near, dealt)
	deal_damage(defender, attacker, taken)


# --- What mechanics may do --------------------------------------------------------------------


## Call before a hook acts: logs the trigger and counts it (9.10.2). False once the limit is
## reached: the hook must then do nothing, and the fight ends as a tie.
func trigger(unit: CombatUnit, mechanic_id: StringName) -> bool:
	if _halt_reason != "":
		return false
	if _triggers >= config.combat_trigger_limit:
		_halt_reason = REASON_TRIGGER_LIMIT
		return false
	_triggers += 1
	_log(
		{
			"type": "trigger",
			"side": unit.side,
			"slot": unit.slot,
			"uid": unit.uid,
			"mechanic": String(mechanic_id)
		}
	)
	return true


## Damage from `source` (null for no unit). Damage prevention runs first (absorb_damage); then
## Health drops and the source's damage triggers run (9.6.2). Deaths wait for resolve_deaths.
func deal_damage(source: CombatUnit, target: CombatUnit, amount: int) -> void:
	if target == null or target.gone or amount <= 0:
		return
	var left: int = amount
	for bound: BoundMechanic in target.mechanics:
		left = bound.mechanic.absorb_damage(self, target, left, bound.params)
	if left <= 0:
		return
	target.damage += left
	_hit_by[target.uid] = source
	_log(
		{
			"type": "damage",
			"side": target.side,
			"slot": target.slot,
			"uid": target.uid,
			"amount": left,
			"health": target.health(),
			"source_uid": source.uid if source != null else -1
		}
	)
	if source != null:
		for bound: BoundMechanic in source.mechanics:
			bound.mechanic.on_damage_dealt(self, source, target, left, bound.params)


## Destroys a unit outright; it dies at the next death resolution.
func destroy(source: CombatUnit, target: CombatUnit) -> void:
	if target == null or target.gone:
		return
	target.destroyed = true
	_hit_by[target.uid] = source
	_log(
		{
			"type": "destroy",
			"side": target.side,
			"slot": target.slot,
			"uid": target.uid,
			"source_uid": source.uid if source != null else -1
		}
	)


## A this-combat buff (12.1.2).
func buff(unit: CombatUnit, attack: int, health: int, source: CombatUnit) -> void:
	if unit == null or unit.gone:
		return
	unit.stats.combat_attack += attack
	unit.stats.combat_health += health
	_log(
		{
			"type": "buff",
			"side": unit.side,
			"slot": unit.slot,
			"uid": unit.uid,
			"attack": unit.attack(),
			"health": unit.health(),
			"source_uid": source.uid if source != null else -1
		}
	)


## A status a mechanic shows (a shield popping, stealth ending): for the UI only.
func show_status(unit: CombatUnit, status: StringName, on: bool) -> void:
	_log(
		{
			"type": "status",
			"side": unit.side,
			"slot": unit.slot,
			"uid": unit.uid,
			"status": String(status),
			"on": on
		}
	)


## 8.4, 9.8.1 a combat summon on `side`. `source_slot` -1 means no source (8.4.3);
## `own_slot_first` for a dying unit's own effect (8.4.1). Null when the board is full (8.4.5).
func summon(
	side: int, card_id: StringName, source_slot: int, own_slot_first: bool, source: CombatUnit
) -> CombatUnit:
	var slot: int = geometry.summon_slot(_occupied(side), source_slot, own_slot_first)
	if slot < 0 or not library.has(card_id):
		_log({"type": "summon_failed", "side": side, "id": String(card_id)})
		return null
	var golden: bool = false
	var unit: CombatUnit = CombatUnit.fresh(
		library.get_card(card_id), _take_uid(), side, golden, registry, config.stat_max
	)
	_enter(unit, slot, source)
	return unit


## 9.4.8 a unit entering slot j mid-cycle is flagged only if j is below the pointer.
func _enter(unit: CombatUnit, slot: int, source: CombatUnit) -> void:
	unit.slot = slot
	unit.flagged = slot < pointers[unit.side]
	var row: Array = sides[unit.side]
	row[slot] = unit
	_units_cache[unit.side] = null
	for bound: BoundMechanic in unit.mechanics:
		bound.mechanic.on_combat_begin(self, unit, bound.params)
	_refresh_auras(unit.side)
	_log(
		{
			"type": "summon",
			"side": unit.side,
			"slot": slot,
			"uid": unit.uid,
			"id": String(unit.def.id),
			"attack": unit.attack(),
			"health": unit.health(),
			"golden": unit.golden,
			"source_uid": source.uid if source != null else -1
		}
	)


## The units of `side` named by a selector (Selectors), relative to `unit`'s slot.
func select(unit: CombatUnit, selector: String) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for slot: int in Selectors.slots(geometry, unit.slot, _occupied(unit.side), selector):
		out.append(unit_at(unit.side, slot))
	return out


## 9.5.6 a random enemy from either row, ignoring targeting rules. Null if none.
func random_enemy(unit: CombatUnit) -> CombatUnit:
	var enemies: Array[CombatUnit] = units(1 - unit.side)
	if enemies.is_empty():
		return null
	return enemies[effect_rng.index(enemies.size())]


func unit_at(side: int, slot: int) -> CombatUnit:
	var row: Array = sides[side]
	var found: CombatUnit = row[slot]
	return found


## The units on `side`'s board, in reading order.
## Cached until the board changes; callers must not modify the returned list.
func units(side: int) -> Array[CombatUnit]:
	if _units_cache[side] != null:
		var cached: Array[CombatUnit] = _units_cache[side]
		return cached
	var out: Array[CombatUnit] = []
	for value: Variant in sides[side]:
		if value != null:
			var unit: CombatUnit = value
			out.append(unit)
	_units_cache[side] = out
	return out


# --- Deaths ---------------------------------------------------------------------------------------


## 9.7: every unit at 0 Health or destroyed dies. Dying units leave their slots first (9.7.1);
## then kills, each dying unit's own death effects and the friendly death counters, in order
## active side first then reading order (9.7.3); then returns (9.8.2-9.8.3); new deaths start
## another pass (9.7.2 step 6).
func resolve_deaths(active_side: int) -> void:
	while _halt_reason == "":
		var dying: Array[CombatUnit] = []
		for side: int in [active_side, 1 - active_side]:
			for unit: CombatUnit in units(side):
				if unit.should_die():
					dying.append(unit)
		if dying.is_empty():
			return
		for unit: CombatUnit in dying:
			unit.gone = true
			var row: Array = sides[unit.side]
			row[unit.slot] = null
			_units_cache[unit.side] = null
			_log({"type": "death", "side": unit.side, "slot": unit.slot, "uid": unit.uid})
		for side: int in 2:
			_refresh_auras(side)
		for unit: CombatUnit in dying:
			var killer: CombatUnit = _hit_by.get(unit.uid, null)
			if killer != null and killer.side != unit.side:
				for bound: BoundMechanic in killer.mechanics:
					bound.mechanic.on_kill(self, killer, unit, bound.params)
		for unit: CombatUnit in dying:
			for bound: BoundMechanic in unit.mechanics:
				bound.mechanic.on_death(self, unit, bound.params)
			for friend: CombatUnit in units(unit.side):
				for bound: BoundMechanic in friend.mechanics:
					bound.mechanic.on_friendly_death(self, friend, unit, bound.params)
		for unit: CombatUnit in dying:
			_try_return(unit)


## 9.8.2-9.8.3, 9.10.3: a fresh copy of the card comes back, own slot first, then nearest.
func _try_return(unit: CombatUnit) -> void:
	var health: int = unit.query(Mechanic.Q_RETURN_HEALTH, 0)
	if health <= 0 or unit.returns >= config.return_limit or _halt_reason != "":
		return
	var slot: int = geometry.summon_slot(_occupied(unit.side), unit.slot, true)
	if slot < 0:
		return
	if not trigger(unit, &"return"):
		return
	var back: CombatUnit = CombatUnit.fresh(
		unit.def, _take_uid(), unit.side, unit.golden, registry, config.stat_max
	)
	back.returns = unit.returns + 1
	back.starting = unit.starting
	back.recruit_uid = unit.recruit_uid
	back.damage = maxi(0, back.max_health() - health)
	_enter(back, slot, unit)
	_log(
		{
			"type": "return",
			"side": back.side,
			"slot": slot,
			"uid": back.uid,
			"from_uid": unit.uid,
			"health": back.health()
		}
	)


# --- Upkeep and end -------------------------------------------------------------------------------


func _occupied(side: int) -> Array[bool]:
	var out: Array[bool] = []
	for value: Variant in sides[side]:
		out.append(value != null)
	return out


func _board_empty(side: int) -> bool:
	return units(side).is_empty()


## 12.2.1 auras recomputed whenever the board changes.
func _refresh_auras(side: int) -> void:
	var living: Array[CombatUnit] = units(side)
	for unit: CombatUnit in living:
		unit.stats.aura_attack = 0
		unit.stats.aura_health = 0
	for source: CombatUnit in living:
		for bound: BoundMechanic in source.mechanics:
			if not bound.mechanic.has_aura():
				continue
			for target: CombatUnit in living:
				var gain: Vector2i = bound.mechanic.aura(
					geometry, source.slot, target.slot, bound.params
				)
				target.stats.aura_attack += gain.x
				target.stats.aura_health += gain.y


## 9.9 and 10.1.2: the winner, and how many of each side's starting units were killed (a
## starting unit is killed unless it, or its return, is alive on its own side at the end).
func _finish() -> Dictionary:
	var alive: Array[bool] = [not _board_empty(0), not _board_empty(1)]
	var winner: int = -1
	if _halt_reason == REASON_BOARD_EMPTY and alive[0] != alive[1]:
		winner = 0 if alive[0] else 1
	var killed: Array[int] = [0, 0]
	var starting: Array[int] = [0, 0]
	for side: int in 2:
		var survivors: Array[int] = []
		for unit: CombatUnit in units(side):
			if unit.starting:
				survivors.append(unit.recruit_uid)
		var started: Array = _starting_uids[side]
		starting[side] = started.size()
		killed[side] = maxi(0, started.size() - _unique(survivors).size())
	result = {
		"winner": winner,
		"reason": _halt_reason,
		"starting": starting,
		"killed": killed,
		"attacks": _attacks,
		"triggers": _triggers,
		"survivors": [_uids(0), _uids(1)],
	}
	var end_event: Dictionary = result.duplicate()
	end_event["type"] = "combat_end"
	_log(end_event)
	return result


static func _unique(values: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for value: int in values:
		if not out.has(value):
			out.append(value)
	return out


func _uids(side: int) -> Array[int]:
	var out: Array[int] = []
	for unit: CombatUnit in units(side):
		out.append(unit.uid)
	return out


func _board_view(side: int) -> Array:
	var out: Array = []
	for unit: CombatUnit in units(side):
		out.append(unit.view(geometry))
	return out


func _log(event: Dictionary) -> void:
	events.append(event)
