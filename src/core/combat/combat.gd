class_name Combat
extends RefCounted
## One fight by rulebook chapter 9, returned as the event log of SPEC section 5.
## Usage: Combat.create(library, config, rng).run(boards, tiers, player_ids, damage_cap).
## A board is 7 entries in reading order: null or {"def_id", "golden", "attack"?, "health"?}.

const REASON_BOARD_EMPTY: String = "board_empty"
const REASON_NO_ATTACKS: String = "no_attacks"
const REASON_ATTACK_LIMIT: String = "attack_limit"

var library: UnitLibrary
var config: GameConfig
var rng: RandomNumberGenerator
## sides[side][slot] -> CombatUnit or null.
var sides: Array = [[], []]
var events: Array[Dictionary] = []
## 9.4.5 the pointer per side: the slot of the side's latest attack this cycle, -1 at the start.
var pointers: Array[int] = [-1, -1]
var attacks_made: int = 0
var _next_uid: int = 1


static func create(
	unit_library: UnitLibrary, game_config: GameConfig, fight_rng: RandomNumberGenerator
) -> Combat:
	var combat := Combat.new()
	combat.library = unit_library
	combat.config = game_config
	combat.rng = fight_rng
	return combat


## Runs the fight. `tiers` are the players' tiers (10.1.1); `damage_cap` 0 means no cap.
## Returns {"events", "winner", "damage", "damage_uncapped", "reason"}.
func run(boards: Array, tiers: Array[int], player_ids: Array[int], damage_cap: int) -> Dictionary:
	_setup(boards)
	var first_side: int = _first_side()
	_emit(
		"combat_start",
		{
			"boards": [_board_views(0), _board_views(1)],
			"first_side": first_side,
			"player_ids": player_ids.duplicate()
		}
	)
	_emit("phase", {"name": "start_of_combat"})
	_start_of_combat()
	var reason: String = ""
	if not _both_boards_have_units():
		reason = REASON_BOARD_EMPTY
	else:
		_emit("phase", {"name": "attacks"})
		reason = _attack_loop(first_side)
	return _finish(reason, tiers, damage_cap)


func _setup(boards: Array) -> void:
	for side: int in 2:
		var row: Array = []
		row.resize(BoardGeometry.SLOTS)
		sides[side] = row
		var board: Array = boards[side]
		for slot: int in BoardGeometry.SLOTS:
			if slot >= board.size() or board[slot] == null:
				continue
			var spec: Dictionary = board[slot]
			var unit_def: Dictionary = library.get_unit(str(spec["def_id"]))
			if unit_def.is_empty():
				continue
			var unit := CombatUnit.make(unit_def, spec, _next_uid, side)
			_next_uid += 1
			unit.slot = slot
			row[slot] = unit


## 9.2.1 more units attacks first; a tie is random.
func _first_side() -> int:
	var count_0: int = units_of(0).size()
	var count_1: int = units_of(1).size()
	if count_0 != count_1:
		return 0 if count_0 > count_1 else 1
	return rng.randi_range(0, 1)


## 9.3: one random player resolves all their Start of Combat units, then the other. No unit in
## milestone A has a Start of Combat effect.
func _start_of_combat() -> void:
	pass


func _attack_loop(first_side: int) -> String:
	var active: int = first_side
	var limit: int = config.get_int("attack_limit")
	while true:
		if not _both_boards_have_units():
			return REASON_BOARD_EMPTY
		if not _side_can_attack(0) and not _side_can_attack(1):
			return REASON_NO_ATTACKS
		if attacks_made >= limit:
			return REASON_ATTACK_LIMIT
		if not _side_can_attack(active):
			_emit("pass", {"side": active})
		else:
			var attacker: CombatUnit = _choose_attacker(active)
			var defender: CombatUnit = _choose_target(attacker)
			attacks_made += 1
			_resolve_attack(attacker, defender)
		active = 1 - active
	return REASON_ATTACK_LIMIT


## 9.4.5 steps 2, 3 and 5.
func _choose_attacker(side: int) -> CombatUnit:
	var ready: Array[CombatUnit] = []
	for unit: CombatUnit in units_of(side):
		if unit.can_attack():
			ready.append(unit)
	var attacker: CombatUnit = null
	for unit: CombatUnit in ready:
		if not unit.flagged:
			attacker = unit
			break
	if attacker == null:
		for unit: CombatUnit in units_of(side):
			unit.flagged = false
		pointers[side] = -1
		attacker = ready[0]
	pointers[side] = attacker.slot
	for unit: CombatUnit in units_of(side):
		if unit.slot <= attacker.slot:
			unit.flagged = true
	return attacker


## 9.5.1 back-row protection and 9.5.5 random target among the candidates.
func _choose_target(attacker: CombatUnit) -> CombatUnit:
	var enemies: Array[CombatUnit] = units_of(1 - attacker.side)
	var front: Array[CombatUnit] = []
	for unit: CombatUnit in enemies:
		if BoardGeometry.is_front(unit.slot):
			front.append(unit)
	var candidates: Array[CombatUnit] = front if not front.is_empty() else enemies
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## 9.6.1 for a plain attack: the damage exchange (simultaneous, the attacker's damage first in
## the log, 9.6.2), then death resolution.
func _resolve_attack(attacker: CombatUnit, defender: CombatUnit) -> void:
	_emit(
		"attack",
		{
			"side": attacker.side,
			"attacker": attacker.uid,
			"defender": defender.uid,
			"joiners": [],
			"strikes": 1,
			"quick": false,
		}
	)
	var attacker_damage: int = attacker.attack
	var defender_damage: int = defender.attack
	_deal_damage(attacker, defender, attacker_damage, "attack", 1)
	_deal_damage(defender, attacker, defender_damage, "attack", 1)
	_resolve_deaths(attacker.side)


## One damage event. A unit with 0 Attack deals no damage and logs nothing (prototype pick).
func _deal_damage(
	source: CombatUnit, target: CombatUnit, amount: int, kind: String, strike: int
) -> void:
	if amount <= 0:
		return
	target.health -= amount
	_emit(
		"damage",
		{
			"source": source.uid,
			"target": target.uid,
			"amount": amount,
			"raw": amount,
			"kind": kind,
			"strike": strike,
			"modifiers": [],
			"health_after": target.health,
		}
	)


## 9.7: every dying unit leaves its slot first (9.7.1), the active side's first and then in
## reading order (9.7.3); new deaths start another pass.
func _resolve_deaths(active_side: int) -> void:
	while true:
		var dying: Array[CombatUnit] = []
		for side: int in [active_side, 1 - active_side]:
			for unit: CombatUnit in units_of(side):
				if unit.is_dead():
					dying.append(unit)
		if dying.is_empty():
			return
		for unit: CombatUnit in dying:
			var row: Array = sides[unit.side]
			row[unit.slot] = null
			unit.on_board = false
			_emit("death", {"uid": unit.uid, "side": unit.side, "slot": unit.slot})


## The units on a side's board in reading order.
func units_of(side: int) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	var row: Array = sides[side]
	for entry: Variant in row:
		if entry != null:
			var unit: CombatUnit = entry
			out.append(unit)
	return out


func _side_can_attack(side: int) -> bool:
	for unit: CombatUnit in units_of(side):
		if unit.can_attack():
			return true
	return false


func _both_boards_have_units() -> bool:
	return not units_of(0).is_empty() and not units_of(1).is_empty()


## 9.9 the result and 10.1 the damage.
func _finish(reason: String, tiers: Array[int], damage_cap: int) -> Dictionary:
	var survivors: Array = [_uids(0), _uids(1)]
	var winner: int = -1
	if reason == REASON_BOARD_EMPTY:
		var left_0: bool = not units_of(0).is_empty()
		var left_1: bool = not units_of(1).is_empty()
		if left_0 != left_1:
			winner = 0 if left_0 else 1
	var uncapped: int = 0
	if winner >= 0:
		uncapped = tiers[winner]
		for unit: CombatUnit in units_of(winner):
			uncapped += unit.tier()
	var damage: int = uncapped if damage_cap <= 0 else mini(uncapped, damage_cap)
	_emit(
		"combat_end",
		{
			"winner": winner,
			"reason": reason,
			"survivors": survivors,
			"damage": damage,
			"damage_uncapped": uncapped,
		}
	)
	return {
		"events": events,
		"winner": winner,
		"damage": damage,
		"damage_uncapped": uncapped,
		"reason": reason,
	}


func _uids(side: int) -> Array:
	var out: Array = []
	for unit: CombatUnit in units_of(side):
		out.append(unit.uid)
	return out


func _board_views(side: int) -> Array:
	var out: Array = []
	var row: Array = sides[side]
	for entry: Variant in row:
		if entry == null:
			out.append(null)
		else:
			var unit: CombatUnit = entry
			out.append(unit.view())
	return out


func _emit(type: String, fields: Dictionary) -> void:
	var event: Dictionary = {"seq": events.size(), "type": type}
	event.merge(fields)
	events.append(event)
