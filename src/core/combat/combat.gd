# gdlint: disable=max-public-methods
# A fight hook may use any of these, so the fight API is one class on purpose.
class_name Combat
extends RefCounted
## One fight (rulebook chapter 9) between two recruit boards, as a JSON-shaped event log.
## Phase order, each step named by its rule:
##   9.1 copy boards and slot effects -> on_combat_begin -> auras -> combat_start event
##   9.2.1 first attacker -> 9.3 Start of Combat (random player first, reading order, deaths after
##   each effect) -> 9.4 alternate attacks (attack pointer, 9.4.5) -> each attack 9.6.1:
##   on_attacked; on_attack, on_friendly_attack; hits; damage exchange (+ cleave);
##   after_attack, after_friendly_attack; death resolution 9.7 -> 9.9 end, or 9.10 limits.
## Randomness comes from sub-streams of the fight's seed (prototype lesson 7): "first", "soc",
## "target" and "effect", so one new random mechanic can't move every later target.
## Mechanics act only through the public methods below and bridge(n) (FightSide: the bridge to
## the player). Combat names no keyword itself.

const REASON_BOARD_EMPTY: String = "board_empty"
const REASON_NO_ATTACKS: String = "no_attacks"
const REASON_ATTACK_LIMIT: String = "attack_limit"
const REASON_TRIGGER_LIMIT: String = "trigger_limit"
const REASONS: PackedStringArray = [
	REASON_BOARD_EMPTY, REASON_NO_ATTACKS, REASON_ATTACK_LIMIT, REASON_TRIGGER_LIMIT
]
## How deep out-of-turn attacks may nest (an attack that starts another attack...).
const MAX_ATTACK_DEPTH: int = 4
## CombatUnit.state while an attack that "takes no damage" resolves.
const NO_DAMAGE: StringName = &"core_takes_no_damage"

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
## Reserve units and waiting summons, and the order they fill emptied slots (FightArrivals).
var arrivals: FightArrivals
## The side whose standing mechanics a listener hook is running for (they get unit = null).
var listening_side: int = -1
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
var _bridges: Array[FightSide] = []
var _depth: int = 0
var _auras: FightAuras
## Per side: units counted for Outnumbered when the fight began (fixed; see outnumbered_by).
var _counted_start: Array[int] = [0, 0]
var _started: bool = false
## The unit whose damage is being absorbed, so a status event can name it.
var _acting: CombatUnit = null


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
	combat.arrivals = FightArrivals.create(combat)
	combat._auras = FightAuras.create(combat)
	return combat


## Runs the fight. `boards` is [board_a, board_b], each an Array of Unit or null per slot.
## `owners` gives each side's PlayerState (or null), and `live` whether that side's permanent
## changes reach the player (false for the ghost, 8.5.2 and 2.1.4). `hands` gives each side's
## hand (Array of Unit), for its Reserve units.
func run(
	boards: Array, ids: Array[int], owners: Array = [], live: Array = [], hands: Array = []
) -> Dictionary:
	player_ids = ids
	for side: int in 2:
		var owner: PlayerState = owners[side] if side < owners.size() else null
		var is_live: bool = side < live.size() and CoreUtil.to_bool(live[side])
		_bridges.append(FightSide.create(self, side, owner, is_live, geometry.slot_count))
	_setup(boards)
	arrivals.take_reserve(hands)
	var first: int = _first_side()
	_log(
		{
			"type": "combat_start",
			"players": player_ids.duplicate(),
			"first": first,
			"boards": [_board_view(0), _board_view(1)],
			"slots": [_slots_view(0), _slots_view(1)],
			"counters": [bridge(0).counters.duplicate(), bridge(1).counters.duplicate()],
			"heaps": [bridge(0).heap_sizes(), bridge(1).heap_sizes()],
			"reserve": arrivals.reserve_view(geometry),
			"outnumbered_by": [outnumbered_by(0), outnumbered_by(1)],
		}
	)
	_started = true
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


## A side's bridge to its player: lasting numbers, heaps, slots, write-back (FightSide).
func bridge(index: int) -> FightSide:
	return _bridges[index]


# --- Setup ----------------------------------------------------------------------------------------


func _setup(boards: Array) -> void:
	for side_index: int in 2:
		var row: Array = []
		row.resize(geometry.slot_count)
		sides[side_index] = row
		var board: Array = boards[side_index]
		for slot: int in mini(board.size(), geometry.slot_count):
			var source: Unit = board[slot]
			if source == null:
				continue
			var unit: CombatUnit = CombatUnit.from_unit(source, _take_uid(), side_index)
			unit.slot = slot
			row[slot] = unit
			_units_cache[side_index] = null
			var starting: Array = _starting_uids[side_index]
			starting.append(unit.uid)
	_counted_start = [_counted(0), _counted(1)]
	_refresh_auras()
	for side_index: int in 2:
		for unit: CombatUnit in units(side_index):
			for bound: BoundMechanic in unit.hooks():
				bound.mechanic.on_combat_begin(self, unit, bound.params)
	_refresh_auras()


## Units that count toward being outnumbered: all but back-row units that say they don't
## (Q_UNCOUNTED).
func _counted(side_index: int) -> int:
	var count: int = 0
	for unit: CombatUnit in units(side_index):
		if geometry.is_front(unit.slot) or unit.query(Mechanic.Q_UNCOUNTED, 0) == 0:
			count += 1
	return count


## Outnumbered (SHARED-RULES 1-5): how many more counted units the other side had when the
## boards were counted, before any Start of Combat effect; fixed for the whole fight. Back-row
## units with Q_UNCOUNTED (Squires) are left out of both counts; hands never count.
func outnumbered_by(side_index: int) -> int:
	return maxi(0, _counted_start[1 - side_index] - _counted_start[side_index])


## True once the fight has stopped (a limit or the end): a hook must then do nothing.
func halted() -> bool:
	return _halt_reason != ""


## Internal (FightArrivals): a new fight uid.
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
## resolve after each effect (9.3.5). SHARED-RULES 41: passes by Mechanic
## .start_of_combat_priority, highest first: the set-up pass (Mechanic.SOC_SETUP) on both
## sides, then the main pass (SOC_MAIN). Only units on the board when it begins act (42).
func _start_of_combat() -> void:
	var first: int = _soc_rng.range_int(0, 1)
	var priorities: Array[int] = []
	var present: Array = [units(0).duplicate(), units(1).duplicate()]
	for side_index: int in 2:
		for unit: CombatUnit in units(side_index):
			for bound: BoundMechanic in unit.hooks():
				var rank: int = bound.mechanic.start_of_combat_priority(bound.params)
				if not priorities.has(rank):
					priorities.append(rank)
	priorities.sort()
	priorities.reverse()
	for rank: int in priorities:
		for side_index: int in [first, 1 - first]:
			var acting: Array = present[side_index]
			for value: Variant in acting:
				var unit: CombatUnit = value
				for bound: BoundMechanic in unit.hooks():
					if unit.gone or _halt_reason != "":
						break
					if bound.mechanic.start_of_combat_priority(bound.params) != rank:
						continue
					_active_side = side_index
					bound.mechanic.on_start_of_combat(self, unit, bound.params)
					_resolve_deaths(side_index)


# --- Attacks ------------------------------------------------------------------------------------


## 9.4.5 step 1: on the board, Attack above 0, and not "can't attack" (Q_CANT_ATTACK).
func _can_attack(unit: CombatUnit) -> bool:
	if unit == null or unit.gone or unit.attack() <= 0:
		return false
	return unit.query(Mechanic.Q_CANT_ATTACK, 0) == 0


func _side_can_attack(side_index: int) -> bool:
	for unit: CombatUnit in units(side_index):
		if _can_attack(unit):
			return true
	return false


## 9.4.5 steps 2-3: the lowest slot that can attack and isn't flagged, resetting the cycle once.
func _next_attacker(side_index: int) -> CombatUnit:
	for pass_number: int in 2:
		for unit: CombatUnit in units(side_index):
			if _can_attack(unit) and not unit.flagged:
				return unit
		if pass_number == 0:
			for unit: CombatUnit in units(side_index):
				unit.flagged = false
			pointers[side_index] = -1
	return null


func _take_turn(side_index: int) -> void:
	var attacker: CombatUnit = _next_attacker(side_index)
	if attacker == null:
		_log({"type": "pass", "side": side_index})
		return
	# 9.4.5 step 5: P = its slot; it and every unit in a lower slot are flagged.
	pointers[side_index] = attacker.slot
	for unit: CombatUnit in units(side_index):
		if unit.slot <= attacker.slot:
			unit.flagged = true
	# "Instead of attacking": a mechanic that takes the turn replaces the attacks, and counts as
	# one toward the attack limit (9.10.1).
	for bound: BoundMechanic in attacker.hooks():
		if bound.mechanic.instead_of_attack(self, attacker, bound.params):
			_attacks += 1
			_log(
				{
					"type": "instead_of_attack",
					"side": attacker.side,
					"slot": attacker.slot,
					"uid": attacker.uid,
					"mechanic": String(bound.id),
				}
			)
			_resolve_deaths(side_index)
			return
	# 9.4.11 repeat attacks back to back, a new target each, while it lives and has Attack.
	var swings: int = maxi(1, attacker.query(Mechanic.Q_ATTACKS, 1))
	for _swing: int in swings:
		if not _can_attack(attacker) or _halt_reason != "" or _attacks >= config.attack_limit:
			break
		var defender: CombatUnit = choose_target(attacker)
		if defender == null:
			break
		_attack(attacker, defender)


## 9.5.1-9.5.5: front row if any lives, else back row; drop untargetable unless all are;
## must-be-attacked units first; then random. Public so an effect that picks the next target
## (Overrun) picks it by the same rules.
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
	# 9.5.7 text that overrides targeting (Q_TARGET_ROW on the attacker).
	var row_rule: int = attacker.query(Mechanic.Q_TARGET_ROW, 0)
	if row_rule == Mechanic.ROW_BACK and not back.is_empty():
		candidates = back
	elif row_rule == Mechanic.ROW_ANY:
		candidates = front + back
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
	for bound: BoundMechanic in defender.hooks():
		bound.mechanic.on_attacked(self, defender, attacker, bound.params)
	# Step 1 killed the attacker (Thorns): it doesn't attack, so no "whenever this attacks" and
	# no friend joins in. The attack still counts.
	if attacker.should_die() or attacker.gone:
		_resolve_deaths(attacker.side)
		return
	for bound: BoundMechanic in attacker.hooks():
		bound.mechanic.on_attack(self, attacker, defender, bound.params)
	_notify_joiners(attacker, defender)
	var both_standing: bool = not defender.should_die() and not attacker.should_die()
	if both_standing and not defender.gone and not attacker.gone:
		_exchange(attacker, defender)
	# "After this attacks" happens even when a friend joining in killed the target first.
	for bound: BoundMechanic in attacker.hooks():
		bound.mechanic.after_attack(self, attacker, defender, bound.params)
	_notify_friends(attacker, &"after_friendly_attack", [attacker, defender])
	_resolve_deaths(attacker.side)


## 9.6.1 step 3, 9.6.2: both deal damage at once; the attacker's damage (and its splash) resolves
## first. Amounts are read before any damage lands. A Q_STRIKES_FIRST
## attacker's damage lands first, and a defender it kills doesn't strike back.
func _exchange(attacker: CombatUnit, defender: CombatUnit) -> void:
	var dealt: int = attacker.attack()
	var taken: int = defender.attack()
	var splash: Array[CombatUnit] = []
	if attacker.query(Mechanic.Q_CLEAVE, 0) != 0:
		for slot: int in geometry.adjacent(defender.slot):
			var near: CombatUnit = unit_at(defender.side, slot)
			if near != null:
				splash.append(near)
	deal_damage(attacker, defender, dealt, true)
	for near: CombatUnit in splash:
		deal_damage(attacker, near, dealt, true)
	if attacker.query(Mechanic.Q_STRIKES_FIRST, 0) != 0 and defender.should_die():
		return
	deal_damage(defender, attacker, taken, true)


## 9.4.12 "attacks immediately": an extra attack at once, out of turn, at `target` or a target
## chosen as usual. The pointer and flags don't change. False if it couldn't attack. With
## `takes_no_damage` the unit takes none from anything while the attack resolves, Thorns
## included (SHARED-RULES 26).
func attack_now(unit: CombatUnit, target: CombatUnit = null, takes_no_damage: bool = false) -> bool:
	if not _can_attack(unit) or _halt_reason != "" or _depth >= MAX_ATTACK_DEPTH:
		return false
	if _attacks >= config.attack_limit:
		return false
	var defender: CombatUnit = target
	if defender == null or defender.gone or defender.side == unit.side:
		defender = choose_target(unit)
	if defender == null:
		return false
	_depth += 1
	if takes_no_damage:
		unit.set_state(NO_DAMAGE, 1)
	_attack(unit, defender)
	unit.set_state(NO_DAMAGE, 0)
	_depth -= 1
	return true


## A hit: `unit` deals its Attack (times `percent` / 100) to `target` and takes nothing back.
## Not an attack (no attack count, no attack hooks) and not attack damage (absorb_damage sees
## from_attack false, so Plate doesn't reduce it); deaths wait for the next resolution. From
## on_friendly_attack it is "joining" an attack: a target it kills ends that attack before the
## exchange (9.6.1), and no later hit lands on it.
func hit(unit: CombatUnit, target: CombatUnit, percent: int = 100) -> void:
	if unit == null or unit.gone or target == null or target.gone or unit.attack() <= 0:
		return
	if target.should_die():
		return
	_log(
		{
			"type": "hit",
			"side": unit.side,
			"slot": unit.slot,
			"uid": unit.uid,
			"target_side": target.side,
			"target_slot": target.slot,
			"target_uid": target.uid
		}
	)
	deal_damage(unit, target, int(unit.attack() * percent / 100.0), false)


## Internal, for FightSide: the player's slot buff percent (Rules.SLOT_BUFF_PERCENT).
func rules_percent(player: PlayerState) -> int:
	return Rules.new(config).slot_buff_percent(player)


## 8.3.5, 9.4.9 an effect moves a unit: into an empty slot, or swapping when `swap`. A unit that
## moves below the pointer and isn't flagged becomes flagged. False if it can't move.
func move_unit(unit: CombatUnit, to_slot: int, swap: bool = false) -> bool:
	if unit == null or unit.gone or not geometry.is_valid(to_slot) or to_slot == unit.slot:
		return false
	var other: CombatUnit = unit_at(unit.side, to_slot)
	if other != null and not swap:
		return false
	var row: Array = sides[unit.side]
	var from_slot: int = unit.slot
	row[from_slot] = other
	row[to_slot] = unit
	unit.slot = to_slot
	_flag_moved(unit)
	if other != null:
		other.slot = from_slot
		_flag_moved(other)
	_units_cache[unit.side] = null
	_log({"type": "move", "side": unit.side, "uid": unit.uid, "from": from_slot, "to": to_slot})
	_refresh_auras()
	return true


func _flag_moved(unit: CombatUnit) -> void:
	if not unit.flagged and unit.slot < pointers[unit.side]:
		unit.flagged = true


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


## A trigger for a standing mechanic (no unit), counted the same way.
func trigger_side(side_index: int, mechanic_id: StringName) -> bool:
	if _halt_reason != "":
		return false
	if _triggers >= config.combat_trigger_limit:
		_halt_reason = REASON_TRIGGER_LIMIT
		return false
	_triggers += 1
	_log(
		{
			"type": "trigger",
			"side": side_index,
			"slot": -1,
			"uid": -1,
			"mechanic": String(mechanic_id)
		}
	)
	return true


## Damage from `source` (null for no unit). Damage prevention runs first (absorb_damage); then
## Health drops and the source's damage triggers run (9.6.2). Deaths wait for death resolution.
## `from_attack` marks the exchange and its splash (9.6.1 step 3).
func deal_damage(
	source: CombatUnit, target: CombatUnit, amount: int, from_attack: bool = false
) -> void:
	if target == null or target.gone or amount <= 0 or target.state_int(NO_DAMAGE) != 0:
		return
	var left: int = amount
	var outer: CombatUnit = _acting
	_acting = source
	for bound: BoundMechanic in target.hooks():
		left = bound.mechanic.absorb_damage(self, target, left, from_attack, bound.params)
	_acting = outer
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
		for bound: BoundMechanic in source.hooks():
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


## A buff: this combat (12.1.2), or `permanent` also on the recruit unit (12.1.1) when its side
## writes back. A permanent buff a unit earns as it dies (Flying Ace in the same exchange) is
## kept: it still reaches the recruit unit.
func buff(
	unit: CombatUnit, attack: int, health: int, source: CombatUnit, permanent: bool = false
) -> void:
	if unit == null or (unit.gone and not permanent):
		return
	unit.stats.combat_attack += attack
	unit.stats.combat_health += health
	var real: Unit = bridge(unit.side).real_unit(unit) if permanent else null
	if real != null:
		real.stats.perm_attack += attack
		real.stats.perm_health += health
	if unit.gone and real == null:
		return
	_log(
		{
			"type": "buff",
			"side": unit.side,
			"slot": unit.slot,
			"uid": unit.uid,
			"attack": unit.attack(),
			"health": unit.health(),
			"source_uid": source.uid if source != null else -1,
			"permanent": real != null,
		}
	)
	_refresh_auras()


## A status a mechanic shows (a shield popping, stealth ending): for the UI only. `source` is
## the unit that caused it; left null, the unit whose damage is being prevented.
func show_status(unit: CombatUnit, status: StringName, on: bool, source: CombatUnit = null) -> void:
	var cause: CombatUnit = source if source != null else _acting
	_log(
		{
			"type": "status",
			"side": unit.side,
			"slot": unit.slot,
			"uid": unit.uid,
			"status": String(status),
			"on": on,
			"source_uid": cause.uid if cause != null else -1,
		}
	)


## 8.4, 9.8.1 a combat summon on `side`. `source_slot` -1 means no source (8.4.3);
## `own_slot_first` for a dying unit's own effect (8.4.1). With no empty slot it fails (8.4.5)
## and returns null, or with `wait` it waits in one line and lands after the next death
## resolution (FightArrivals). A summon keeps its source and `payload`, which goes into the
## landed unit's `state`.
func summon(
	side_index: int,
	card_id: StringName,
	source_slot: int,
	own_slot_first: bool,
	source: CombatUnit,
	wait: bool = false,
	payload: Dictionary = {}
) -> CombatUnit:
	var slot: int = geometry.summon_slot(_occupied(side_index), source_slot, own_slot_first)
	if slot < 0 or not library.has(card_id):
		if wait and library.has(card_id):
			arrivals.wait(side_index, card_id, source, payload)
			_log(
				{
					"type": "summon_waiting",
					"side": side_index,
					"id": String(card_id),
					"source_uid": source.uid if source != null else -1,
				}
			)
		else:
			_log({"type": "summon_failed", "side": side_index, "id": String(card_id)})
		return null
	var unit: CombatUnit = CombatUnit.fresh(
		library.get_card(card_id), _take_uid(), side_index, false, registry, config.stat_max
	)
	unit.state.merge(payload, true)
	_enter(unit, slot, source)
	return unit


## 9.4.8 a unit entering slot j mid-cycle is flagged only if j is below the pointer. Internal
## (FightArrivals too): `kind` is the event type ("summon", or "reserve" for a unit stepping in
## from the hand), `extra` more event fields.
func _enter(
	unit: CombatUnit, slot: int, source: CombatUnit, kind: String = "summon", extra: Dictionary = {}
) -> void:
	unit.slot = slot
	unit.flagged = slot < pointers[unit.side]
	var row: Array = sides[unit.side]
	row[slot] = unit
	_units_cache[unit.side] = null
	_refresh_auras()
	for bound: BoundMechanic in unit.hooks():
		bound.mechanic.on_combat_begin(self, unit, bound.params)
	var event: Dictionary = unit.view(geometry)
	event["type"] = kind
	event["source_uid"] = source.uid if source != null else -1
	event.merge(extra, true)
	_log(event)
	for listener_side: int in [unit.side, 1 - unit.side]:
		_notify(listener_side, &"on_fight_enter", [unit])


## The units of `unit`'s side named by a selector (Selectors), relative to `unit`'s slot.
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


func unit_at(side_index: int, slot: int) -> CombatUnit:
	var row: Array = sides[side_index]
	var found: CombatUnit = row[slot]
	return found


## The units on `side`'s board, in reading order.
## Cached until the board changes; callers must not modify the returned list.
func units(side_index: int) -> Array[CombatUnit]:
	if _units_cache[side_index] != null:
		var cached: Array[CombatUnit] = _units_cache[side_index]
		return cached
	var out: Array[CombatUnit] = []
	for value: Variant in sides[side_index]:
		if value != null:
			var unit: CombatUnit = value
			out.append(unit)
	_units_cache[side_index] = out
	return out


## A rule about a whole side, asked of every unit on it and then its standing mechanics
## (Mechanic.side_query). Example: Q_DEATH_EFFECT_TIMES.
func side_query(side_index: int, query: StringName, base: int) -> int:
	var value: int = base
	for unit: CombatUnit in units(side_index):
		for bound: BoundMechanic in unit.hooks():
			value = bound.mechanic.side_query(self, unit, query, value, bound.params)
	listening_side = side_index
	for bound: BoundMechanic in bridge(side_index).standing:
		value = bound.mechanic.side_query(self, null, query, value, bound.params)
	return value


## A unit's own death effects without the death (from where it stands), each resolving as many
## times as Q_DEATH_EFFECT_TIMES says.
func run_death_effects(unit: CombatUnit) -> void:
	var times: int = maxi(1, side_query(unit.side, Mechanic.Q_DEATH_EFFECT_TIMES, 1))
	for _time: int in times:
		for bound: BoundMechanic in unit.hooks():
			if _halt_reason != "":
				return
			bound.mechanic.on_death(self, unit, bound.params)


# --- Listeners ------------------------------------------------------------------------------------


## Runs a listener hook for every unit on `side` (reading order, skipping the gone), then its
## standing mechanics with unit = null. Arguments go between the unit and the params.
func _notify(side_index: int, hook: StringName, args: Array) -> void:
	for unit: CombatUnit in units(side_index):
		if unit.gone:
			continue
		for bound: BoundMechanic in unit.hooks():
			bound.mechanic.callv(hook, [self, unit] + args + [bound.params])
	listening_side = side_index
	for bound: BoundMechanic in bridge(side_index).standing:
		bound.mechanic.callv(hook, [self, null] + args + [bound.params])


## on_friendly_attack for the attacker's friends, then for any friend that arrived while they
## acted, until none is new; then the side's standing mechanics once.
func _notify_joiners(attacker: CombatUnit, defender: CombatUnit) -> void:
	var heard: Array[int] = [attacker.uid]
	var fresh: bool = true
	while fresh and _halt_reason == "":
		fresh = false
		for unit: CombatUnit in units(attacker.side).duplicate():
			if unit.gone or heard.has(unit.uid):
				continue
			heard.append(unit.uid)
			fresh = true
			for bound: BoundMechanic in unit.hooks():
				bound.mechanic.on_friendly_attack(self, unit, attacker, defender, bound.params)
	listening_side = attacker.side
	for bound: BoundMechanic in bridge(attacker.side).standing:
		bound.mechanic.on_friendly_attack(self, null, attacker, defender, bound.params)


## As _notify, but not for `subject` itself.
func _notify_friends(subject: CombatUnit, hook: StringName, args: Array) -> void:
	for unit: CombatUnit in units(subject.side):
		if unit.gone or unit == subject:
			continue
		for bound: BoundMechanic in unit.hooks():
			bound.mechanic.callv(hook, [self, unit] + args + [bound.params])
	listening_side = subject.side
	for bound: BoundMechanic in bridge(subject.side).standing:
		bound.mechanic.callv(hook, [self, null] + args + [bound.params])


## Internal, for FightSide: an entry went into one of `side`'s heaps.
func _notify_heap_added(side_index: int, heap_name: StringName, card_id: StringName) -> void:
	_notify(side_index, &"on_heap_added_in_fight", [heap_name, card_id])


# --- Deaths ---------------------------------------------------------------------------------------


## 9.7: every unit at 0 Health or destroyed dies. Dying units leave their slots first (9.7.1);
## then, in order active side first then reading order (9.7.3): step 1 kills and "whenever a
## unit dies"; step 2 own death effects and friendly death counters; step 3 "after a friendly
## unit dies"; step 4 returns; step 5 "after a friendly unit returns"; then the slot-fill order
## (FightArrivals: Reserve, waiting summons, after_death_round); new deaths start another pass
## (step 6).
func _resolve_deaths(active_side: int) -> void:
	while _halt_reason == "":
		var dying: Array[CombatUnit] = []
		for side_index: int in [active_side, 1 - active_side]:
			for unit: CombatUnit in units(side_index):
				if unit.should_die():
					dying.append(unit)
		if dying.is_empty():
			return
		var emptied: Array = [[], []]
		for unit: CombatUnit in dying:
			var died_in: Array = emptied[unit.side]
			died_in.append(unit.slot)
			unit.gone = true
			var row: Array = sides[unit.side]
			row[unit.slot] = null
			_units_cache[unit.side] = null
			bridge(unit.side).deaths += 1
			var killer: CombatUnit = _hit_by.get(unit.uid, null)
			_log(
				{
					"type": "death",
					"side": unit.side,
					"slot": unit.slot,
					"uid": unit.uid,
					"killer_uid": killer.uid if killer != null else -1,
				}
			)
		_refresh_auras()
		_death_steps(dying, active_side)
		var back: Array[CombatUnit] = []
		for unit: CombatUnit in dying:
			var returned: CombatUnit = _try_return(unit)
			if returned != null:
				back.append(returned)
		for unit: CombatUnit in back:
			_notify_friends(unit, &"after_friendly_return", [unit])
		arrivals.after_deaths(emptied, active_side)


func _death_steps(dying: Array[CombatUnit], active_side: int) -> void:
	for unit: CombatUnit in dying:
		var killer: CombatUnit = _hit_by.get(unit.uid, null)
		if killer != null and killer.side != unit.side:
			for bound: BoundMechanic in killer.hooks():
				bound.mechanic.on_kill(self, killer, unit, bound.params)
	for unit: CombatUnit in dying:
		for side_index: int in [active_side, 1 - active_side]:
			_notify(side_index, &"on_any_death", [unit])
	for unit: CombatUnit in dying:
		run_death_effects(unit)
		_notify(unit.side, &"on_friendly_death", [unit])
	for unit: CombatUnit in dying:
		_notify(unit.side, &"after_friendly_death", [unit])


## 9.8.2-9.8.3, 9.10.3: a fresh copy of the card comes back, own slot first, then nearest.
func _try_return(unit: CombatUnit) -> CombatUnit:
	var health: int = unit.query(Mechanic.Q_RETURN_HEALTH, 0)
	for bound: BoundMechanic in unit.hooks():
		health = bound.mechanic.return_health(self, unit, health, bound.params)
	if health <= 0 or unit.returns >= config.return_limit or _halt_reason != "":
		return null
	var slot: int = geometry.summon_slot(_occupied(unit.side), unit.slot, true)
	if slot < 0 or not trigger(unit, &"return"):
		return null
	var back: CombatUnit = CombatUnit.fresh(
		unit.def, _take_uid(), unit.side, unit.golden, registry, config.stat_max
	)
	var recruit_copy: Unit = bridge(unit.side).recruit_unit(unit)
	if unit.query(Mechanic.Q_RETURN_AS_RECRUIT, 0) != 0 and recruit_copy != null:
		# Root: back as it stands on the recruit board (SHARED-RULES 16), at `health`.
		back = CombatUnit.from_unit(recruit_copy, back.uid, unit.side)
		back.slot = slot
	back.returns = unit.returns + 1
	back.starting = unit.starting
	back.recruit_uid = unit.recruit_uid
	back.counters = unit.counters.duplicate()
	back.damage = maxi(0, back.max_health() - health)
	_enter(back, slot, unit)
	for bound: BoundMechanic in unit.hooks():
		bound.mechanic.on_returned(self, unit, back, bound.params)
	var event: Dictionary = back.view(geometry)
	event["type"] = "return"
	event["from_uid"] = unit.uid
	_log(event)
	return back


# --- Upkeep and end -------------------------------------------------------------------------------


func _occupied(side_index: int) -> Array[bool]:
	var out: Array[bool] = []
	for value: Variant in sides[side_index]:
		out.append(value != null)
	return out


func _board_empty(side_index: int) -> bool:
	return units(side_index).is_empty()


## Internal (FightSide calls it too): recalculates auras and slot effects (FightAuras).
func _refresh_auras() -> void:
	_auras.refresh(_started)


## 9.9 and 10.1.2: the winner, and how many of each side's starting units were killed (a
## starting unit is killed unless it, or its return, is alive on its own side at the end).
func _finish() -> Dictionary:
	var alive: Array[bool] = [not _board_empty(0), not _board_empty(1)]
	var winner: int = -1
	if _halt_reason == REASON_BOARD_EMPTY and alive[0] != alive[1]:
		winner = 0 if alive[0] else 1
	var killed: Array[int] = [0, 0]
	var starting: Array[int] = [0, 0]
	var kept: Array = [[], []]
	for side_index: int in 2:
		var survivors: Array[int] = []
		for unit: CombatUnit in units(side_index):
			if unit.starting:
				survivors.append(unit.recruit_uid)
		var started: Array = _starting_uids[side_index]
		starting[side_index] = started.size()
		kept[side_index] = _unique(survivors)
		killed[side_index] = maxi(0, started.size() - _unique(survivors).size())
	result = {
		"winner": winner,
		"reason": _halt_reason,
		"starting": starting,
		"killed": killed,
		"attacks": _attacks,
		"triggers": _triggers,
		"survivors": [_uids(0), _uids(1)],
		"survivor_recruit_uids": kept,
		"deaths": [bridge(0).deaths, bridge(1).deaths],
		"outnumbered_by": [outnumbered_by(0), outnumbered_by(1)],
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


func _uids(side_index: int) -> Array[int]:
	var out: Array[int] = []
	for unit: CombatUnit in units(side_index):
		out.append(unit.uid)
	return out


func _board_view(side_index: int) -> Array:
	var out: Array = []
	for unit: CombatUnit in units(side_index):
		out.append(unit.view(geometry))
	return out


func _slots_view(side_index: int) -> Array:
	return bridge(side_index).slots.map(func(s: SlotState) -> Dictionary: return s.view())


## Internal, for FightSide: logs `event` for that side, with the source unit's uid.
func log_side(from_side: FightSide, event: Dictionary, source: CombatUnit) -> void:
	event["side"] = from_side.index
	event["source_uid"] = source.uid if source != null else -1
	_log(event)


func _log(event: Dictionary) -> void:
	events.append(event)
