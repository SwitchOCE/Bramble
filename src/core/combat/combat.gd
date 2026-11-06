class_name Combat
extends RefCounted
## One fight by rulebook chapter 9, returned as the event log of SPEC section 5.
## Usage: Combat.create(library, config, rng).run(boards, tiers, player_ids, damage_cap).
## A board is 7 entries in reading order: null or {"def_id", "golden", "attack"?, "health"?}.
## Mechanic scripts (src/core/mechanics/) act through the public methods below, so every change
## they make is logged.

const BEADLE: String = "beadle"
const REEL: String = "reel_mistress"
## Whirligig Beetle's pairs: F1 with B1, F2 with B2, F3 with B3 (slots: F1-F4 are 0-3, B1-B3 4-6).
const ROW_SWAPS: Array = [[0, 4], [1, 5], [2, 6]]
const REASON_BOARD_EMPTY: String = "board_empty"
const REASON_NO_ATTACKS: String = "no_attacks"
const REASON_ATTACK_LIMIT: String = "attack_limit"
const REASON_TRIGGER_LIMIT: String = "trigger_limit"
## Status -> [keyword, the unit whose note explains it] for the card's keyword_text.
const STATUS_SOURCES: Dictionary = {
	"nightshade": ["Nightshade", "belladonna_sprite"],
	"mired": ["Mire", "mudwallow_toad"],
	"first_bite": ["First Bite", "weasel_second"],
	"shell": ["Shell", "garden_snail"],
	"warned": ["Whistle", "marmot_lookout"],
	"waiting": ["Bide", "hazel_dormouse"],
}

var library: UnitLibrary
var config: GameConfig
var rng: RandomNumberGenerator
## The stream for data effects' random choices, so adding one can't shift targeting or who goes
## first (prototype-lessons section 7).
var effect_rng: RandomNumberGenerator
## sides[side][slot] -> CombatUnit or null.
var sides: Array = [[], []]
var events: Array[Dictionary] = []
## 9.4.5 the pointer per side: the slot of the side's latest attack this cycle, -1 at the start.
## Summons read it (9.4.8).
var pointers: Array[int] = [-1, -1]
var attacks_made: int = 0
## Marked slots (Mark): {"owner_side", "side", "slot", "damage", "source": CombatUnit}.
var marks: Array[Dictionary] = []
## Changes for the players' recruit state once the fight is over ({"side", "op", ...}).
var carry: Array[Dictionary] = []
## 8.5.2 per side, per slot, the slot effects copied into this fight. Set before run().
var slot_effects: Array = [[], []]
## 9.3.1 per side, the hero's Start of Combat entries. Set before run().
var hero_effects: Array = [[], []]
## Per side, what the player's rules say about this fight: {"back_row_first": bool, "larder": int}.
## Set before run(); {} is the usual rules and an empty Larder.
var side_rules: Array = [{}, {}]
## Hex per side: slot -> how much Attack it takes (Hedge Witch). It stays on the slot.
var hexes: Array = [{}, {}]
## False for a fight nobody will watch (a bot trying a layout): no events, same result.
var log_events: bool = true
## Whether any slot effect is in this fight, so most fights skip the lookups.
var _slots_active: bool = false
var _next_uid: int = 1
var _triggers: int = 0
var _halted: bool = false
var _thorns: Array[Hit] = []
var _status_text: Dictionary = {}
## Effect damage asked for while a damage event is landing waits here, so "when damaged" effects
## can't recurse without end.
var _pending_hits: Array[Hit] = []
var _landing: int = 0
var _tiers: Array[int] = [1, 1]
var _ammo_thrown: Array[int] = [0, 0]
## Borrowed unit's uid -> the Changeling standing in for it.
var _borrowed: Dictionary = {}
var _slots_owned: Array[bool] = [false, false]


static func create(
	unit_library: UnitLibrary, game_config: GameConfig, fight_rng: RandomNumberGenerator
) -> Combat:
	var combat := Combat.new()
	combat.library = unit_library
	combat.config = game_config
	combat.rng = fight_rng
	combat.effect_rng = RandomNumberGenerator.new()
	combat.effect_rng.seed = fight_rng.seed ^ 0x5EED
	return combat


## Runs the fight. `tiers` are the players' tiers (10.1.1); `damage_cap` 0 means no cap.
## Returns {"events", "winner", "damage", "damage_uncapped", "reason"}.
func run(boards: Array, tiers: Array[int], player_ids: Array[int], damage_cap: int) -> Dictionary:
	_tiers = tiers
	_slots_active = _has_slot_effects()
	_setup(boards)
	var first_side: int = _first_side()
	_recalc_auras(false)
	if log_events:
		for status: String in STATUS_SOURCES:
			var source: Array = STATUS_SOURCES[status]
			var entries: Array = UnitLibrary.keyword_text_of(library.get_unit(str(source[1])))
			if not entries.is_empty():
				var entry: Dictionary = entries[0]
				_status_text[status] = {"keyword": str(source[0]), "text": entry["text"]}
		var start: Dictionary = {
			"boards": [_board_views(0), _board_views(1)],
			"first_side": first_side,
			"player_ids": player_ids.duplicate(),
		}
		if _slots_active:
			start["slot_effects"] = slot_effects.duplicate(true)
		_emit("combat_start", start)
	_emit("phase", {"name": "start_of_combat"})
	_start_of_combat()
	var reason: String = ""
	if _halted:
		reason = REASON_TRIGGER_LIMIT
	elif not _both_boards_have_units():
		reason = REASON_BOARD_EMPTY
	else:
		_emit("phase", {"name": "attacks"})
		reason = _attack_loop(first_side)
	return _finish(reason, tiers, damage_cap)


# --- Methods for the mechanic scripts -----------------------------------------------------------


## The units on a side's board in reading order.
func units_of(side: int) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	var row: Array = sides[side]
	for entry: Variant in row:
		if entry != null:
			var unit: CombatUnit = entry
			out.append(unit)
	return out


## The unit in a slot, or null.
func unit_at(side: int, slot: int) -> CombatUnit:
	var row: Array = sides[side]
	var entry: Variant = row[slot]
	if entry == null:
		return null
	var unit: CombatUnit = entry
	return unit


## Logs that a unit's mechanic fires; counts toward the trigger limit (9.10.2).
func trigger(unit: CombatUnit, mechanic_id: String) -> void:
	_triggers += 1
	if _triggers > config.get_int("trigger_limit_combat"):
		_halted = true
	_emit("trigger", {"uid": unit.uid, "mechanic": mechanic_id})


func set_status(
	unit: CombatUnit, status: String, on: bool, source: CombatUnit, data: Dictionary = {}
) -> void:
	if on:
		unit.statuses[status] = data
	elif not unit.statuses.erase(status):
		return
	_emit(
		"status",
		{
			"target": unit.uid,
			"status": status,
			"on": on,
			"source": _uid_or_null(source),
			"data": data.duplicate(),
		}
	)


## A "this combat" buff or debuff (12.1.1). Health gains raise maximum Health too. With
## `permanent` it also reaches the recruit board after the fight (12.1.1, `carry` in the result).
func buff(
	unit: CombatUnit,
	attack_delta: int,
	health_delta: int,
	source: CombatUnit,
	permanent: bool = false
) -> void:
	var old_attack: int = unit.attack
	var old_health: int = unit.health
	unit.add_combat(attack_delta, health_delta)
	_emit_stats(unit, unit.attack - old_attack, unit.health - old_health, source, permanent)
	if permanent and unit.iid != 0:
		carry_back(
			unit.side,
			{"op": "buff", "iid": unit.iid, "attack": attack_delta, "health": health_delta}
		)


## Something a fight does to a player's recruit state, applied when the fight is over.
func carry_back(side: int, change: Dictionary) -> void:
	var change_on_side: Dictionary = change.duplicate()
	change_on_side["side"] = side
	carry.append(change_on_side)


## The tier of the player on a side (10.1.1).
func tier_of(side: int) -> int:
	return _tiers[side]


## Effect damage from a unit (Both Ends' prick, Mark). Deaths resolve later, by the caller.
func deal_effect_damage(source: CombatUnit, target: CombatUnit, amount: int) -> void:
	var hit: Hit = Hit.make(source, target, amount, Hit.EFFECT)
	if _landing > 0:
		_pending_hits.append(hit)
		return
	var hits: Array[Hit] = [hit]
	_apply_hits(hits)


## Bristle: thorn damage dealt after the exchange, before deaths are checked.
func queue_thorns(source: CombatUnit, target: CombatUnit, amount: int) -> void:
	_thorns.append(Hit.make(source, target, amount, Hit.THORNS))


## 8.4 summon placement, 9.4.8 flags, 9.8.1 joins the order. Returns null if the board is full.
func summon(
	def_id: String, golden: bool, side: int, source_slot: int, source: CombatUnit
) -> CombatUnit:
	var slot_to: int = BoardGeometry.summon_slot(_occupied(side), source_slot, true)
	return summon_into(def_id, golden, side, slot_to, source)


## A summon into a chosen slot. `stats` above 0 sets its Attack and Health (Mousewife's Mouse).
func summon_into(
	def_id: String, golden: bool, side: int, slot_to: int, source: CombatUnit, stats: int = 0
) -> CombatUnit:
	var unit_def: Dictionary = library.get_unit(def_id)
	if slot_to < 0 or unit_def.is_empty():
		return null
	var spec: Dictionary = {"def_id": def_id, "golden": golden}
	if stats > 0:
		spec["attack"] = stats
		spec["health"] = stats
	var unit := CombatUnit.make(unit_def, spec, _next_uid, side)
	_next_uid += 1
	unit.slot = slot_to
	var row: Array = sides[side]
	row[slot_to] = unit
	unit.flagged = _attack_rank(side, slot_to) < _pointer_rank(side)
	_apply_slot_grants(unit)
	_emit(
		"summon",
		{
			"unit": unit.view(_status_text),
			"side": side,
			"slot": slot_to,
			"source": _uid_or_null(source),
		}
	)
	_recalc_auras(true)
	_enter_slot(unit)
	if _has_ally_listener(side):
		for ally: CombatUnit in units_of(side):
			for index: int in ally.ally_listeners:
				ally.scripts[index].on_ally_summon(self, ally, ally.params[index], unit)
	return unit


## Where a summon naming a place goes (BoardGeometry.named_slot); -1 for no room.
func named_slot(side: int, at: String, anchor: int) -> int:
	return BoardGeometry.named_slot(_occupied(side), at, anchor, true)


## Spill: the summon found no room, so an Acorn arrives after the fight.
func spill(side: int, source: CombatUnit) -> void:
	carry_back(side, {"op": "add_card", "card": "acorn", "count": 1, "from_pool": false})
	_emit("spill", {"side": side, "source": _uid_or_null(source)})
	for unit: CombatUnit in units_of(side):
		if not unit.has_mechanic(BEADLE):
			continue
		var index: int = unit.mechanic_ids.find(BEADLE)
		var used: int = CoreUtil.to_int(unit.limits.get(BEADLE, 0))
		if used < CoreUtil.to_int(unit.params[index].get("limit", 0)):
			unit.limits[BEADLE] = used + 1
			var stats: int = CoreUtil.to_int(unit.params[index].get("stats", 0))
			trigger(unit, BEADLE)
			pass_buff(unit, stats, stats)


## Whether a summon that found no room should Spill on this side (Beadle Warrenby).
func spills_all(side: int) -> bool:
	for unit: CombatUnit in units_of(side):
		if unit.has_mechanic(BEADLE):
			return true
	return false


## Pass in a fight: the last unit touching `from` to its right gains this, for this combat.
func pass_buff(from: CombatUnit, attack_delta: int, health_delta: int) -> void:
	var landing: int = BoardGeometry.pass_landing(_occupied(from.side), from.slot)
	var unit: CombatUnit = unit_at(from.side, landing) if landing >= 0 else null
	if unit != null:
		buff(unit, attack_delta, health_delta, from)


## The slots painted with a band on this side.
func bands_of(side: int) -> Array[int]:
	var out: Array[int] = []
	var rules_here: Dictionary = side_rules[side]
	var row: Array = rules_here.get("bands", [])
	for slot: int in row.size():
		if CoreUtil.to_int(row[slot]) != 0:
			out.append(slot)
	return out


## Sergeant-at-Conkers: the smallest Acorn item not yet thrown this fight; 0 if none. It leaves the
## hand when the fight is over.
func take_ammo(side: int) -> int:
	var rules_here: Dictionary = side_rules[side]
	var thrown: int = CoreUtil.to_int(_ammo_thrown[side])
	var ammo: Array = rules_here.get("ammo", [])
	if thrown >= ammo.size():
		return 0
	_ammo_thrown[side] = thrown + 1
	var gold: int = CoreUtil.to_int(ammo[thrown])
	carry_back(side, {"op": "spend_item", "gold": gold})
	return gold


## Cradle Fetch: `unit` is gone (no death effects) and a printed copy of `other` stands in its slot.
func become_copy(unit: CombatUnit, other: CombatUnit, bonus: int) -> void:
	var slot: int = unit.slot
	var side: int = unit.side
	var row: Array = sides[side]
	row[slot] = null
	unit.on_board = false
	_emit("death", {"uid": unit.uid, "side": side, "slot": slot})
	var copy: CombatUnit = summon_into(other.def_id(), unit.golden, side, slot, unit)
	if copy == null:
		return
	if bonus > 0:
		buff(copy, bonus, bonus, copy)
	for index: int in copy.scripts.size():
		copy.scripts[index].on_start_of_combat(self, copy, copy.params[index])


## Changeling: the two trade places and sides. The enemy comes back after it has attacked once.
func borrow_across(unit: CombatUnit, enemy: CombatUnit, bonus: int) -> void:
	_trade_sides(unit, enemy)
	set_status(enemy, "borrowed", true, unit, {"partner": unit.uid})
	_borrowed[enemy.uid] = unit
	if bonus > 0:
		buff(enemy, bonus, bonus, unit)


func _trade_sides(a: CombatUnit, b: CombatUnit) -> void:
	var slot_a: int = a.slot
	var slot_b: int = b.slot
	var side_a: int = a.side
	var side_b: int = b.side
	var row_a: Array = sides[side_a]
	var row_b: Array = sides[side_b]
	row_a[slot_a] = b
	row_b[slot_b] = a
	a.side = side_b
	a.slot = slot_b
	b.side = side_a
	b.slot = slot_a
	_emit("relocate", {"uid": a.uid, "side": a.side, "slot": a.slot})
	_emit("relocate", {"uid": b.uid, "side": b.side, "slot": b.slot})
	_recalc_auras(true)


## A borrowed unit has attacked (or its Changeling is gone): it goes home, to its own slot if free.
func _send_home(borrowed: CombatUnit) -> void:
	var partner: CombatUnit = _borrowed.get(borrowed.uid)
	if not _borrowed.erase(borrowed.uid):
		return
	set_status(borrowed, "borrowed", false, null)
	if not borrowed.on_board or borrowed.is_dead():
		return
	if partner != null and partner.on_board:
		_trade_sides(borrowed, partner)
		return
	var home: int = 1 - borrowed.side
	var slot_to: int = borrowed.slot if unit_at(home, borrowed.slot) == null else -1
	if slot_to < 0:
		slot_to = BoardGeometry.summon_slot(_occupied(home), borrowed.slot, true)
	if slot_to < 0:
		return
	var row: Array = sides[borrowed.side]
	row[borrowed.slot] = null
	var row_home: Array = sides[home]
	row_home[slot_to] = borrowed
	borrowed.side = home
	borrowed.slot = slot_to
	_emit("relocate", {"uid": borrowed.uid, "side": home, "slot": slot_to})
	_recalc_auras(true)


## Whirligig Beetle: a side's rows swap, slot by slot; F4 stays. Returns the units that moved.
func swap_rows(side: int) -> Array[CombatUnit]:
	var moved: Array[CombatUnit] = []
	var row: Array = sides[side]
	for pair: Array in ROW_SWAPS:
		var front: int = pair[0]
		var back: int = pair[1]
		var front_unit: CombatUnit = unit_at(side, front)
		var back_unit: CombatUnit = unit_at(side, back)
		row[front] = back_unit
		row[back] = front_unit
		if front_unit != null:
			moved.append(front_unit)
			front_unit.slot = back
			_emit("relocate", {"uid": front_unit.uid, "side": side, "slot": back})
		if back_unit != null:
			moved.append(back_unit)
			back_unit.slot = front
			_emit("relocate", {"uid": back_unit.uid, "side": side, "slot": front})
	_recalc_auras(true)
	return moved


## Reel-Mistress: after a unit on a Ring attacks, the Ring moves to the side's next living unit in
## attack order, and adds to any Ring there. Each Ring dances once. It costs its old holder Health.
func dance_rings(attacker: CombatUnit) -> void:
	var side: int = attacker.side
	var mistress: CombatUnit = null
	for unit: CombatUnit in units_of(side):
		if unit.has_mechanic(REEL):
			mistress = unit
			break
	if mistress == null or not attacker.on_board:
		return
	var here: Array = _slot_effects_at(side, attacker.slot)
	if not BoardUpkeep.has_ring(here):
		return
	var next_slot: int = _next_in_attack_order(attacker)
	if next_slot < 0:
		return
	_own_slot_effects(side)
	var row: Array = slot_effects[side]
	var from: Array = row[attacker.slot]
	var ring: Dictionary = {}
	for value: Variant in from:
		var effect: Dictionary = value
		if str(effect.get("name", "")) == BoardUpkeep.RING and not effect.get("danced", false):
			ring = effect
			break
	if ring.is_empty():
		return
	from.erase(ring)
	var moved: Dictionary = ring.duplicate()
	moved["danced"] = true
	if mistress.golden:
		moved["attack"] = CoreUtil.to_int(moved["attack"]) + 1
		moved["health"] = CoreUtil.to_int(moved["health"]) + 1
	var to: Array = row[next_slot]
	to.append(moved)
	trigger(mistress, REEL)
	_emit(
		"ring_dance",
		{"side": side, "from": attacker.slot, "to": next_slot, "attack": moved["attack"], "health": moved["health"]}
	)
	_recalc_auras(true)
	_resolve_deaths(side)


## The slot effects of a fight are shared with the recruit board until something changes them.
func _own_slot_effects(side: int) -> void:
	if _slots_owned[side]:
		return
	_slots_owned[side] = true
	var copied: Array = []
	var row: Array = slot_effects[side]
	for effects: Variant in row:
		var list: Array = effects
		copied.append(list.duplicate(true))
	slot_effects[side] = copied
	_slots_active = true


func _next_in_attack_order(unit: CombatUnit) -> int:
	var order: Array[CombatUnit] = _attack_order(unit.side)
	var at: int = order.find(unit)
	for step: int in range(1, order.size()):
		var other: CombatUnit = order[(at + step) % order.size()]
		if other.on_board and other != unit:
			return other.slot
	return -1


## The empty slots on a side that hold a Ring (Will-o'-the-Wisp).
func empty_ring_slots(side: int) -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if unit_at(side, slot) == null and BoardUpkeep.has_ring(_slot_effects_at(side, slot)):
			out.append(slot)
	return out


## What the Acorn items in this side's hand are worth.
func larder_of(side: int) -> int:
	var rules_here: Dictionary = side_rules[side]
	return CoreUtil.to_int(rules_here.get("larder", 0))


## Hex: the slot has less Attack for the rest of this fight, whoever stands there, now or later.
## It waits on an empty slot and stays when the Hexer dies. Hexes on one slot add up.
func add_hex(source: CombatUnit, side: int, slot: int, amount: int) -> void:
	var row: Dictionary = hexes[side]
	row[slot] = CoreUtil.to_int(row.get(slot, 0)) + amount
	_slots_active = true
	_emit(
		"slot_hex",
		{
			"side": side,
			"slot": slot,
			"amount": amount,
			"total": row[slot],
			"source": _uid_or_null(source),
		}
	)
	_recalc_auras(true)


## Mark: marks an enemy slot for the rest of combat.
func add_mark(source: CombatUnit, side: int, slot: int, damage: int) -> void:
	marks.append(
		{"owner_side": source.side, "side": side, "slot": slot, "damage": damage, "source": source}
	)
	_emit(
		"slot_mark",
		{
			"owner_side": source.side,
			"side": side,
			"slot": slot,
			"damage": damage,
			"source": source.uid,
		}
	)


## Logs that an effect with no unit on the board fired (a hero's Start of Combat power).
func side_trigger(side: int, mechanic_id: String) -> void:
	_triggers += 1
	if _triggers > config.get_int("trigger_limit_combat"):
		_halted = true
	_emit("side_trigger", {"side": side, "mechanic": mechanic_id})


## Logs an event a script describes itself (skip, whistle).
func emit_event(type: String, fields: Dictionary) -> void:
	_emit(type, fields)


# --- Setup and Start of Combat ------------------------------------------------------------------


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
			_apply_slot_grants(unit)


## 9.2.1 more units attacks first; a tie is random.
func _first_side() -> int:
	var count_0: int = units_of(0).size()
	var count_1: int = units_of(1).size()
	if count_0 != count_1:
		return 0 if count_0 > count_1 else 1
	return rng.randi_range(0, 1)


## 9.3.2: one random player resolves all their Start of Combat units in reading order, then the
## other; deaths resolve between effects (9.3.5).
func _start_of_combat() -> void:
	var first: int = rng.randi_range(0, 1)
	_hero_start_of_combat(first)
	for side: int in [first, 1 - first]:
		for unit: CombatUnit in units_of(side):
			if not unit.on_board or _halted:
				continue
			for index: int in unit.scripts.size():
				unit.scripts[index].on_start_of_combat(self, unit, unit.params[index])
			_resolve_deaths(side)


## 9.3.1, 9.3.3: hero powers before units, in the random player order.
func _hero_start_of_combat(first: int) -> void:
	for side: int in [first, 1 - first]:
		var entries: Array = hero_effects[side]
		for value: Variant in entries:
			var entry: Dictionary = value
			if str(entry.get("trigger", "")) == HeroRules.START_OF_COMBAT:
				EffectRunner.run(
					entry, CombatWorld.make(self, null, side, entry, "start_of_combat")
				)
		_resolve_deaths(side)


# --- Attacks ------------------------------------------------------------------------------------


func _attack_loop(first_side: int) -> String:
	var active: int = first_side
	var limit: int = config.get_int("attack_limit")
	while true:
		if _halted:
			return REASON_TRIGGER_LIMIT
		if not _both_boards_have_units():
			return REASON_BOARD_EMPTY
		if not _side_can_attack(0) and not _side_can_attack(1):
			return REASON_NO_ATTACKS
		if attacks_made >= limit:
			return REASON_ATTACK_LIMIT
		_take_turn(active)
		active = 1 - active
	return REASON_ATTACK_LIMIT


## One side's turn: choose units until one attacks or uses the turn (9.4.5). Mired and waiting
## units pass the turn to the side's next unit (SPEC 4.2); no unit to choose is a pass (9.4.10).
func _take_turn(side: int) -> void:
	var skipped: Array[CombatUnit] = []
	# Each pick either ends the turn or adds a unit to `skipped`, so the loop is bounded.
	while not _halted:
		var unit: CombatUnit = _choose_attacker(side, skipped)
		if unit == null:
			break
		if unit.is_stopped():
			_use_skip(unit)
			_emit("skip", {"side": side, "uid": unit.uid, "reason": "mired"})
			skipped.append(unit)
			continue
		var action: String = ""
		for index: int in unit.scripts.size():
			action = unit.scripts[index].choose_turn_action(self, unit, unit.params[index])
			if action != "":
				break
		if action == "skip":
			skipped.append(unit)
			continue
		attacks_made += 1
		if action == "":
			_attack(unit, _choose_target(unit))
		return
	_emit("pass", {"side": side})


## Mire ends after its one skip; Turnip Scarecrow's lasts "skips" attacks.
func _use_skip(unit: CombatUnit) -> void:
	var data: Dictionary = unit.statuses["mired"]
	var left: int = CoreUtil.to_int(data.get("skips", 1)) - 1
	if left > 0:
		data["skips"] = left
	else:
		set_status(unit, "mired", false, null)


## 9.4.5 steps 2, 3 and 5; null when no unit can be chosen. A unit that skipped this turn
## (Mire, Bide) can't be chosen again in the same turn, even after a cycle reset (prototype pick).
func _choose_attacker(side: int, skipped: Array[CombatUnit]) -> CombatUnit:
	var ready: Array[CombatUnit] = []
	for unit: CombatUnit in _attack_order(side):
		if unit.can_act() and not skipped.has(unit):
			ready.append(unit)
	if ready.is_empty():
		return null
	var attacker: CombatUnit = null
	for unit: CombatUnit in ready:
		if not unit.flagged:
			attacker = unit
			break
	if attacker == null:
		for unit: CombatUnit in units_of(side):
			unit.flagged = false
		attacker = ready[0]
	pointers[side] = attacker.slot
	var reached: int = _attack_rank(side, attacker.slot)
	for unit: CombatUnit in units_of(side):
		if _attack_rank(side, unit.slot) <= reached:
			unit.flagged = true
	return attacker


func _attack_order(side: int) -> Array[CombatUnit]:
	var rules_here: Dictionary = side_rules[side]
	return AttackOrder.of(units_of(side), rules_here)


func _attack_rank(side: int, slot: int) -> int:
	var rules_here: Dictionary = side_rules[side]
	return AttackOrder.rank(rules_here, slot)


func _pointer_rank(side: int) -> int:
	return -1 if pointers[side] < 0 else _attack_rank(side, pointers[side])


## 9.5.1 back-row protection and 9.5.5 random target among the candidates.
func _choose_target(attacker: CombatUnit) -> CombatUnit:
	for index: int in attacker.scripts.size():
		var forced: CombatUnit = attacker.scripts[index].attack_target(
			self, attacker, attacker.params[index]
		)
		if forced != null:
			return forced
	var enemies: Array[CombatUnit] = units_of(1 - attacker.side)
	var front: Array[CombatUnit] = []
	for unit: CombatUnit in enemies:
		if BoardGeometry.is_front(unit.slot):
			front.append(unit)
	var candidates: Array[CombatUnit] = front if not front.is_empty() else enemies
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## 9.6.1: declaration (Swarm joiners, "when attacked" effects), Nightshade, then the strikes
## (Peck), each an exchange; then "after" effects for a surviving defender.
func _attack(attacker: CombatUnit, defender: CombatUnit) -> void:
	var joiners: Array[CombatUnit] = []
	var strike_count: int = 1
	for index: int in attacker.scripts.size():
		var mechanic: Mechanic = attacker.scripts[index]
		joiners.append_array(mechanic.joiners(self, attacker, attacker.params[index]))
		strike_count = maxi(strike_count, mechanic.strikes(attacker.params[index]))
	# The event's "quick" is the state at declaration; each exchange checks again (_strikes).
	var quick_now: bool = _is_quick(attacker) != _is_quick(defender)
	_emit(
		"attack",
		{
			"side": attacker.side,
			"attacker": attacker.uid,
			"defender": defender.uid,
			"joiners": _uid_list(joiners),
			"strikes": strike_count,
			"quick": quick_now,
		}
	)
	_attack_declared(attacker, defender)
	if not attacker.on_board:
		_emit("cancel", {"uid": attacker.uid, "reason": "died_before_attacking"})
		return
	if not defender.on_board or _halted:
		return
	_nightshade(defender)
	_strikes(attacker, defender, joiners, strike_count)
	var attackers: Array[CombatUnit] = [attacker]
	attackers.append_array(joiners)
	for unit: CombatUnit in attackers:
		if unit.has_status("warned"):
			set_status(unit, "warned", false, null)
	if defender.on_board and not _halted:
		for index: int in defender.scripts.size():
			defender.scripts[index].on_survived_attack(
				self, defender, defender.params[index], attacker
			)
	if attacker.on_board and not _halted:
		if attacker.has_status("borrowed_attack"):
			set_status(attacker, "borrowed_attack", false, null)
		for index: int in attacker.scripts.size():
			attacker.scripts[index].on_after_attack(self, attacker, attacker.params[index])
		_resolve_deaths(attacker.side)
	if attacker.on_board and not _halted:
		_after_attacked_once(attacker)


## What waits for a unit's attack to be over: Rings dance, a parasite hatches, a loan ends.
func _after_attacked_once(attacker: CombatUnit) -> void:
	if _slots_active:
		dance_rings(attacker)
	if attacker.on_board and attacker.has_status("parasite"):
		attacker.lose_health(attacker.health)
		set_status(attacker, "parasite", false, null)
		_resolve_deaths(attacker.side)
	if not _borrowed.is_empty() and _borrowed.has(attacker.uid):
		_send_home(attacker)


## Peck: each strike fires "whenever this attacks" and is its own exchange; joiners and the
## return blow land with the last strike (SPEC 4.2). Quick is checked per exchange, so a unit
## damaged by the declaration or an earlier strike loses "Quick while undamaged" (entry 24);
## First Bite is used up by the first exchange.
func _strikes(
	attacker: CombatUnit, defender: CombatUnit, joiners: Array[CombatUnit], strike_count: int
) -> void:
	var parts: Array[int] = Hit.split(_strike_attack(attacker), strike_count)
	for strike: int in strike_count:
		if not attacker.on_board or not defender.on_board or _halted:
			return
		for index: int in attacker.scripts.size():
			attacker.scripts[index].on_before_attack(self, attacker, attacker.params[index])
		_resolve_deaths(attacker.side)
		if not attacker.on_board or not defender.on_board or _halted:
			return
		var hits_out: Array[Hit] = [
			_attack_hit(attacker, defender, parts[strike], strike + 1, true)
		]
		var hits_back: Array[Hit] = []
		if strike == strike_count - 1:
			for joiner: CombatUnit in joiners:
				if joiner.on_board:
					hits_out.append(_attack_hit(joiner, defender, joiner.attack, 1, true))
			hits_back.append(_attack_hit(defender, attacker, defender.attack, strike + 1, false))
		var attacker_quick: bool = _is_quick(attacker)
		var defender_quick: bool = _is_quick(defender)
		if strike == 0:
			_use_first_bite(attacker)
			_use_first_bite(defender)
		_exchange(hits_out, hits_back, attacker_quick, defender_quick, attacker.side)


## What this attack hits with. Little King Wren: the highest enemy Attack, read as it swings.
func _strike_attack(attacker: CombatUnit) -> int:
	if not attacker.has_status("borrowed_attack"):
		return attacker.attack
	var highest: int = 0
	for enemy: CombatUnit in units_of(1 - attacker.side):
		highest = maxi(highest, enemy.attack)
	return highest


## Nightshade (library entry 75): the defender first loses half its current Health, rounded
## down; Health loss, not damage, so it never kills.
func _nightshade(defender: CombatUnit) -> void:
	if not defender.has_status("nightshade"):
		return
	@warning_ignore("integer_division")
	var loss: int = defender.health / 2
	if loss <= 0:
		return
	defender.lose_health(loss)
	_emit(
		"health_loss",
		{
			"target": defender.uid,
			"amount": loss,
			"cause": "nightshade",
			"health_after": defender.health,
		}
	)


## Before 9.6.1 step 1: every unit's on_attack_declared, the defender's side first, each side in
## reading order; then deaths (Both Ends' prick).
func _attack_declared(attacker: CombatUnit, defender: CombatUnit) -> void:
	for side: int in [defender.side, attacker.side]:
		for unit: CombatUnit in units_of(side):
			for index: int in unit.scripts.size():
				unit.scripts[index].on_attack_declared(
					self, unit, unit.params[index], attacker, defender
				)
	_resolve_deaths(defender.side)


## One exchange (9.6.1 step 3): simultaneous, unless exactly one side is Quick, whose damage
## (and the thorns it causes) resolves with a death check before the other side's (SPEC 4.2).
func _exchange(
	hits_out: Array[Hit], hits_back: Array[Hit], out_quick: bool, back_quick: bool, side: int
) -> void:
	if out_quick == back_quick:
		var all_hits: Array[Hit] = hits_out.duplicate()
		all_hits.append_array(hits_back)
		_damage_step(all_hits, side)
		return
	var first: Array[Hit] = hits_out if out_quick else hits_back
	var second: Array[Hit] = hits_back if out_quick else hits_out
	_damage_step(first, side)
	var still: Array[Hit] = []
	for hit: Hit in second:
		if hit.source.on_board and hit.target.on_board:
			still.append(hit)
	_damage_step(still, side)


func _damage_step(hits: Array[Hit], side: int) -> void:
	if hits.is_empty():
		return
	_apply_hits(hits)
	_flush_thorns()
	_resolve_deaths(side)


func _attack_hit(
	source: CombatUnit, target: CombatUnit, amount: int, strike: int, on_defender: bool
) -> Hit:
	var hit: Hit = Hit.make(source, target, amount, Hit.ATTACK, strike)
	hit.on_defender = on_defender
	return hit


## Simultaneous hits: modifiers (Whistle's warning, the target's own, then Shell on the largest
## hit to each target), then one damage event each, then the damage hooks. 0 damage logs nothing.
func _apply_hits(hits: Array[Hit]) -> void:
	var live: Array[Hit] = []
	for hit: Hit in hits:
		if hit.raw <= 0:
			continue
		hit.amount = hit.raw
		if hit.kind == Hit.ATTACK and hit.source.has_status("warned"):
			hit.amount = ceili(hit.amount / 2.0)
			hit.modifiers.append("whistle")
		for index: int in hit.target.scripts.size():
			hit.amount = hit.target.scripts[index].modify_damage_taken(
				hit.target, hit.target.params[index], hit
			)
		live.append(hit)
	var shell_hits: Dictionary = {}
	for hit: Hit in live:
		if not hit.target.has_status("shell"):
			continue
		var current: Hit = shell_hits.get(hit.target.uid)
		if current == null or current.amount < hit.amount:
			shell_hits[hit.target.uid] = hit
	for key: Variant in shell_hits:
		var hit: Hit = shell_hits[key]
		var shell: Dictionary = hit.target.statuses["shell"]
		hit.amount = mini(hit.amount, CoreUtil.to_int(shell.get("n", 0)))
		hit.modifiers.append("shell")
	_landing += 1
	for hit: Hit in live:
		var breaker: Hit = shell_hits.get(hit.target.uid)
		_land(hit, breaker == hit)
	_landing -= 1
	while _landing == 0 and not _pending_hits.is_empty() and not _halted:
		var waiting: Array[Hit] = [_pending_hits.pop_front()]
		_apply_hits(waiting)


func _land(hit: Hit, breaks_shell: bool) -> void:
	var target: CombatUnit = hit.target
	target.take_damage(hit.amount)
	_emit(
		"damage",
		{
			"source": _uid_or_null(hit.source),
			"target": target.uid,
			"amount": hit.amount,
			"raw": hit.raw,
			"kind": hit.kind,
			"strike": hit.strike,
			"modifiers": hit.modifiers.duplicate(),
			"health_after": target.health,
		}
	)
	if breaks_shell:
		set_status(target, "shell", false, null)
	if hit.source != null:
		for index: int in hit.source.scripts.size():
			hit.source.scripts[index].on_damage_dealt(
				self, hit.source, hit.source.params[index], hit
			)
	for index: int in target.scripts.size():
		target.scripts[index].on_damage_taken(self, target, target.params[index], hit)


func _flush_thorns() -> void:
	while not _thorns.is_empty() and not _halted:
		var hit: Hit = _thorns.pop_front()
		trigger(hit.source, "bristle")
		var hits: Array[Hit] = [hit]
		_apply_hits(hits)


## Quick this exchange: First Bite, or a mechanic that says so (Ermine Duellist).
func _is_quick(unit: CombatUnit) -> bool:
	if unit.has_status("first_bite"):
		return true
	for index: int in unit.scripts.size():
		if unit.scripts[index].strikes_first(unit, unit.params[index]):
			return true
	return false


## First Bite is used up by the unit's first exchange, attacking or defending (SPEC 4.2).
func _use_first_bite(unit: CombatUnit) -> void:
	if unit.has_status("first_bite"):
		set_status(unit, "first_bite", false, null)


# --- Deaths, auras and slots --------------------------------------------------------------------


## 9.7: every dying unit leaves its slot first (9.7.1), the active side's first and then in
## reading order (9.7.3); then each one's death effects; new deaths start another pass.
func _resolve_deaths(active_side: int) -> void:
	while not _halted and _anyone_dying():
		var dying: Array[CombatUnit] = []
		for side: int in [active_side, 1 - active_side]:
			for unit: CombatUnit in units_of(side):
				if unit.health <= 0:
					dying.append(unit)
		for unit: CombatUnit in dying:
			var row: Array = sides[unit.side]
			row[unit.slot] = null
			unit.on_board = false
			_emit("death", {"uid": unit.uid, "side": unit.side, "slot": unit.slot})
		_recalc_auras(true)
		for unit: CombatUnit in dying:
			for index: int in unit.scripts.size():
				unit.scripts[index].on_death(self, unit, unit.params[index])
			if _has_ally_listener(unit.side):
				for ally: CombatUnit in units_of(unit.side):
					for index: int in ally.ally_listeners:
						ally.scripts[index].on_friendly_death(self, ally, ally.params[index], unit)
			_hero_on_death(unit)
		_flush_thorns()


## A hero's "a friendly unit died" entries (Old Mother Mousewife).
func _hero_on_death(dead: CombatUnit) -> void:
	var entries: Array = hero_effects[dead.side]
	for value: Variant in entries:
		var entry: Dictionary = value
		if str(entry.get("trigger", "")) == "on_friendly_death":
			var world := CombatWorld.make(self, null, dead.side, entry, "on_friendly_death")
			world.set_subject(dead)
			EffectRunner.run(entry, world)


## Called after every strike, so it allocates nothing.
func _anyone_dying() -> bool:
	for row: Array in sides:
		for entry: Variant in row:
			if entry != null:
				var unit: CombatUnit = entry
				if unit.health <= 0:
					return true
	return false


func _has_ally_listener(side: int) -> bool:
	var row: Array = sides[side]
	for entry: Variant in row:
		if entry != null:
			var unit: CombatUnit = entry
			if not unit.ally_listeners.is_empty():
				return true
	return false


## 12.2.1 auras are recalculated whenever the board changes. Losing a Health aura lowers maximum
## Health and keeps the damage taken, but never takes Health below 1 (prototype pick).
func _recalc_auras(log_changes: bool) -> void:
	var everyone: Array[CombatUnit] = units_of(0)
	everyone.append_array(units_of(1))
	var from_others: Dictionary = {}
	for unit: CombatUnit in everyone:
		for index: int in unit.board_aura_sources:
			unit.scripts[index].board_aura(self, unit, unit.params[index], from_others)
	for unit: CombatUnit in everyone:
		var bonus: Vector2i = Vector2i.ZERO
		if not from_others.is_empty():
			bonus = from_others.get(unit.uid, Vector2i.ZERO)
		if _slots_active:
			bonus += _slot_bonus(unit)
		for index: int in unit.scripts.size():
			bonus += unit.scripts[index].aura(self, unit, unit.params[index])
		if bonus.x == unit.aura_attack and bonus.y == unit.aura_health:
			continue
		var old_attack: int = unit.attack
		var old_health: int = unit.health
		unit.set_aura(bonus.x, bonus.y)
		if log_changes and (unit.attack != old_attack or unit.health != old_health):
			_emit_stats(unit, unit.attack - old_attack, unit.health - old_health, unit)


func _has_slot_effects() -> bool:
	return BoardUpkeep.any_slot_effects(slot_effects)


## 8.5.1: what the unit's slot gives it. It stays with the slot, not the unit.
func _slot_bonus(unit: CombatUnit) -> Vector2i:
	var effects: Array = _slot_effects_at(unit.side, unit.slot)
	var bonus: Vector2i = Vector2i.ZERO
	for value: Variant in effects:
		var effect: Dictionary = value
		bonus += Vector2i(
			CoreUtil.to_int(effect.get("attack", 0)), CoreUtil.to_int(effect.get("health", 0))
		)
	var row: Dictionary = hexes[unit.side]
	unit.hex_amount = 0 if row.is_empty() else CoreUtil.to_int(row.get(unit.slot, 0))
	bonus.x -= unit.hex_amount
	return bonus


## 8.5.1: a slot's mechanic plays through whatever enters it.
func _apply_slot_grants(unit: CombatUnit) -> void:
	for value: Variant in _slot_effects_at(unit.side, unit.slot):
		var effect: Dictionary = value
		if effect.has("entry"):
			unit.add_grant(effect)


func _slot_effects_at(side: int, slot: int) -> Array:
	var row: Array = slot_effects[side]
	if slot >= row.size():
		return []
	var effects: Array = row[slot]
	return effects


## A unit entered a slot: enemy marks on that slot deal their damage (Mark).
func _enter_slot(unit: CombatUnit) -> void:
	for mark: Dictionary in marks:
		var marked_side: int = mark["side"]
		var marked_slot: int = mark["slot"]
		if marked_side != unit.side or marked_slot != unit.slot:
			continue
		var source: CombatUnit = mark["source"]
		trigger(source, "mark")
		var damage: int = mark["damage"]
		deal_effect_damage(source, unit, damage)


# --- Helpers ------------------------------------------------------------------------------------


func _side_can_attack(side: int) -> bool:
	for unit: CombatUnit in units_of(side):
		if unit.can_attack():
			return true
	return false


func _occupied(side: int) -> Array[bool]:
	var out: Array[bool] = []
	for slot: int in BoardGeometry.SLOTS:
		out.append(unit_at(side, slot) != null)
	return out


func _both_boards_have_units() -> bool:
	return not units_of(0).is_empty() and not units_of(1).is_empty()


## 9.9 the result and 10.1 the damage.
func _finish(reason: String, tiers: Array[int], damage_cap: int) -> Dictionary:
	var survivors: Array = [_uid_list(units_of(0)), _uid_list(units_of(1))]
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
		"carry": carry,
	}


static func _uid_list(units: Array[CombatUnit]) -> Array:
	var out: Array = []
	for unit: CombatUnit in units:
		out.append(unit.uid)
	return out


func _board_views(side: int) -> Array:
	var out: Array = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: CombatUnit = unit_at(side, slot)
		if unit == null:
			out.append(null)
		else:
			out.append(unit.view(_status_text))
	return out


func _emit_stats(
	unit: CombatUnit,
	attack_delta: int,
	health_delta: int,
	source: CombatUnit,
	permanent: bool = false
) -> void:
	_emit(
		"stats",
		{
			"target": unit.uid,
			"attack_delta": attack_delta,
			"health_delta": health_delta,
			"attack": unit.attack,
			"health": unit.health,
			"max_health": unit.max_health,
			"source": _uid_or_null(source),
			"permanent": permanent,
		}
	)


func _emit(type: String, fields: Dictionary) -> void:
	if not log_events:
		return
	var event: Dictionary = {"seq": events.size(), "type": type}
	event.merge(fields)
	events.append(event)


static func _uid_or_null(unit: CombatUnit) -> Variant:
	if unit == null:
		return null
	return unit.uid
