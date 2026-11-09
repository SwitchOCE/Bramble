# gdlint:disable=max-public-methods
class_name Combat
extends RefCounted
## Rulebook chapter 9: seven-slot boards, mechanics and the resulting combat event log.

const REASON_BOARD_EMPTY: String = "board_empty"
const REASON_NO_ATTACKS: String = "no_attacks"
const REASON_ATTACK_LIMIT: String = "attack_limit"
const REASON_TRIGGER_LIMIT: String = "trigger_limit"
## Status -> [keyword, the unit whose note explains it] for the card's keyword_text.
const STATUS_SOURCES: Dictionary = {
	"nightshade": ["Nightshade", "belladonna_sprite"],
	"stalled": ["Pin", "mudwallow_toad"],
	"first_bite": ["First Bite", "weasel_second"],
	"shell": ["Shell", "garden_snail"],
	"warned": ["Whistle", "marmot_lookout"],
	"waiting": ["Bide", "hazel_dormouse"],
}

var library: UnitLibrary
var config: GameConfig
var rng: RandomNumberGenerator
## Separate effect RNG preserves targeting and attack order (prototype-lessons section 7).
var effect_rng: RandomNumberGenerator
## sides[side][slot] -> CombatUnit or null.
var sides: Array = [[], []]
var events: Array[Dictionary] = []
## 9.4.5 per side: the slot of its latest attack this cycle, -1 at start; summons read it (9.4.8).
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
var hero_limits: Array[Dictionary] = [{}, {}]
## Per side, this fight's player rules: {"back_row_first": bool, "larder": int}; {} is usual.
var side_rules: Array = [{}, {}]
## Hex per side: slot -> how much Attack it takes (Hedge Witch). It stays on the slot.
var hexes: Array = [{}, {}]
## Mire belongs to enemy slots; quarry belongs to CombatUnit identities.
var bog_patches: Array = [{}, {}]
var takes: Array[int] = [0, 0]
var cycles: Array[int] = [0, 0]
var reactions: CombatReactions = CombatReactions.new()
## False for a fight nobody will watch (a bot trying a layout): no events, same result.
var log_events: bool = true
## Diagnostic switch; normal fights always retain the Mire wait.
var mire_wait_enabled: bool = true
## Set by the session; layout simulations need only the fight outcome.
var round_number: int = 1
## uid -> original side, captured before any Start of Combat effect.
var starting_sides: Dictionary = {}
var ammo_thrown: Array[int] = [0, 0]
## Borrowed unit's uid -> the Changeling standing in for it.
var borrowed: Dictionary = {}
var slots_owned: Array[bool] = [false, false]
## Set once anyone has been swallowed, so most fights skip the check for an emptied side.
var swallowing: bool = false
## One-a-fight marks for rules with no unit to keep them on ("key" -> true).
var notes: Dictionary = {}
## Attribution follows lethal damage, not merely the most recent attack declaration.
var _attacks_started: bool = false
var _last_blow_side: int = -1
var _last_blow_source: int = -1
var _last_blow_kind: String = ""
## Whether any slot effect is in this fight, so most fights skip the lookups.
var _slots_active: bool = false
var _next_uid: int = 1
var _triggers: int = 0
var _halted: bool = false
var _thorns: Array[Hit] = []
var _status_text: Dictionary = {}
## Effect damage asked for while damage lands waits here, so "when damaged" can't recurse.
var _pending_hits: Array[Hit] = []
var _landing: int = 0
var _tiers: Array[int] = [1, 1]


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


## Run a fight: tier damage per 10.1.1; damage_cap 0 means no cap.
func run(boards: Array, tiers: Array[int], player_ids: Array[int], damage_cap: int) -> Dictionary:
	_attacks_started = false
	_last_blow_side = -1
	_last_blow_source = -1
	_last_blow_kind = ""
	_tiers = tiers
	CombatRings.prepare(self)
	_slots_active = _has_slot_effects()
	_setup(boards)
	Pass3BogCombat.prepare(self)
	var first_side: int = _first_side()
	_recalc_auras(false)
	if log_events:
		for status: String in STATUS_SOURCES:
			var source: Array = STATUS_SOURCES[status]
			var entries: Array = UnitLibrary.keyword_text_of(library.get_unit(str(source[1])))
			if not entries.is_empty():
				var entry: Dictionary = entries[0]
				_status_text[status] = {"keyword": str(source[0]), "text": entry["text"]}
		_status_text["shield"] = {
			"keyword": "Shield", "text": str(EffectSchema.section("keywords")["Shield"])
		}
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
		_attacks_started = true
		reason = _attack_loop(first_side)
	return _finish(reason, tiers, damage_cap)


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
			"source": CombatMoves.uid_or_null(source),
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
	permanent: bool = false,
	cause: String = ""
) -> void:
	CombatMoves.buff(self, unit, attack_delta, health_delta, source, permanent, cause)


## Something a fight does to a player's recruit state, applied when the fight is over.
func carry_back(side: int, change: Dictionary) -> void:
	var change_on_side: Dictionary = change.duplicate()
	change_on_side["side"] = side
	carry.append(change_on_side)


## The tier of the player on a side (10.1.1).
func tier_of(side: int) -> int:
	return _tiers[side]


## Effect damage from a unit (Both Ends' prick, Mark). Deaths resolve later, by the caller.
func deal_effect_damage(
	source: CombatUnit, target: CombatUnit, amount: int, owner_side: int = -1
) -> void:
	var hit: Hit = Hit.make(source, target, amount, Hit.EFFECT)
	if source == null:
		hit.owner_side = owner_side
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
	def_id: String,
	golden: bool,
	side: int,
	slot_to: int,
	source: CombatUnit,
	stats: int = 0,
	fields: Dictionary = {}
) -> CombatUnit:
	var unit_def: Dictionary = library.get_unit(def_id)
	if slot_to < 0:
		emit_event(
			"no_room", {"uid": CombatMoves.uid_or_null(source), "side": side, "def_id": def_id}
		)
		return null
	if unit_def.is_empty():
		return null
	var spec: Dictionary = {"def_id": def_id, "golden": golden}
	if stats > 0:
		spec["attack"] = stats
		spec["health"] = stats
	return enter_from_spec(spec, side, slot_to, source, fields)


## Enters an off-board unit as a summon (9.4.8, 9.8.1), `fields` on the event; null if no card.
func enter_from_spec(
	spec: Dictionary, side: int, slot_to: int, source: CombatUnit, fields: Dictionary = {}
) -> CombatUnit:
	var unit_def: Dictionary = library.get_unit(str(spec["def_id"]))
	if unit_def.is_empty():
		return null
	var unit := CombatUnit.make(unit_def, spec, _next_uid, side)
	_next_uid += 1
	unit.slot = slot_to
	_apply_slot_grants(unit)
	enter_board(unit, source, fields)
	return unit


## Puts a fighter into unit.slot and tells the side. A swallowed unit comes back through here.
func enter_board(unit: CombatUnit, source: CombatUnit, fields: Dictionary = {}) -> void:
	if fields.has("copied"):
		unit.copied_this_fight = true
	var side: int = unit.side
	var slot_to: int = unit.slot
	var row: Array = sides[side]
	row[slot_to] = unit
	unit.on_board = true
	unit.flagged = _attack_rank(side, slot_to) < _pointer_rank(side)
	if log_events:
		var event: Dictionary = {
			"unit": unit.view(_status_text),
			"side": side,
			"slot": slot_to,
			"source": CombatMoves.uid_or_null(source),
		}
		event.merge(fields)
		_emit("summon", event)
	CombatHeld.emerged(self, unit, source, fields)
	_recalc_auras(true)
	_enter_slot(unit)
	if _has_ally_listener(side):
		for ally: CombatUnit in units_of(side):
			for index: int in ally.ally_listeners:
				ally.scripts[index].on_ally_summon(self, ally, ally.params[index], unit)
	Pass3BogStart.entered(self, unit)
	Pass3HunterCombat.entered(self, unit)


func named_slot(side: int, at: String, anchor: int) -> int:
	return BoardGeometry.named_slot(_occupied(side), at, anchor, true)


## Spill: the summon found no room, so an Acorn arrives after the fight.
func spill(side: int, source: CombatUnit) -> void:
	carry_back(side, {"op": "add_card", "card": "acorn", "count": 1, "from_pool": false})
	_emit("spill", {"side": side, "source": CombatMoves.uid_or_null(source)})


## What the Acorn items in this side's hand are worth.
func larder_of(side: int) -> int:
	var rules_here: Dictionary = side_rules[side]
	return CoreUtil.to_int(rules_here.get("larder", 0))


## Hex: the slot loses Attack this fight, whoever stands there. It waits, outlives Hexer, adds up.
func add_hex(source: CombatUnit, side: int, slot: int, amount: int) -> void:
	var row: Dictionary = hexes[side]
	row[slot] = CoreUtil.to_int(row.get(slot, 0)) + amount
	_slots_active = true
	var fields: Dictionary = {
		"side": side,
		"slot": slot,
		"amount": amount,
		"total": row[slot],
		"source": CombatMoves.uid_or_null(source),
	}
	var percent: int = CombatScale.hex_percent(self, side, slot)
	if percent > 0:
		fields["percent"] = percent
	_emit("slot_hex", fields)
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
func side_trigger(side: int, mechanic_id: String, visible: bool = true) -> void:
	_triggers += 1
	if _triggers > config.get_int("trigger_limit_combat"):
		_halted = true
	if visible:
		_emit("side_trigger", {"side": side, "mechanic": mechanic_id})


## Logs an event a script describes itself (skip, whistle).
func emit_event(type: String, fields: Dictionary) -> void:
	_emit(type, fields)


# --- Setup and Start of Combat ------------------------------------------------------------------


func _setup(boards: Array) -> void:
	CombatSetup.apply(self, boards)
	starting_sides.clear()
	for side: int in 2:
		for unit: CombatUnit in units_of(side):
			starting_sides[unit.uid] = side


## 9.2.1 more units attacks first; a tie is random.
func _first_side() -> int:
	var count_0: int = units_of(0).size()
	var count_1: int = units_of(1).size()
	if count_0 != count_1:
		return 0 if count_0 > count_1 else 1
	return rng.randi_range(0, 1)


## 9.3.2, 9.3.5: one random player resolves all their Start of Combat units, then the other.
func _start_of_combat() -> void:
	var first: int = rng.randi_range(0, 1)
	Pass3HunterCombat.prepare(self)
	CombatHeld.first_of_all(self, first)
	Pass3HunterCombat.bell(self)
	CombatLanes.bell(self)
	CombatHeld.goose_strikes(self, first)
	reactions.drain(self)
	_hero_start_of_combat(first)
	if Pass3Combat.enabled(self):
		Pass3Combat.start(self, first)
		return
	var queues: Array = [units_of(first), units_of(1 - first)]
	for queue: Array in queues:
		for unit: CombatUnit in queue:
			if not unit.on_board or _halted:
				continue
			Pass3HunterStart.begin_dispatch(unit)
			for index: int in unit.scripts.size():
				unit.scripts[index].on_start_of_combat(self, unit, unit.params[index])
			_resolve_deaths(unit.side)
			reactions.drain(self)


## 9.3.1, 9.3.3: hero powers before units, in the random player order.
func _hero_start_of_combat(first: int) -> void:
	if Pass3Combat.enabled(self):
		Pass3Combat.heroes(self, first)
		return
	for side: int in [first, 1 - first]:
		var entries: Array = hero_effects[side]
		for value: Variant in entries:
			var entry: Dictionary = value
			if str(entry.get("trigger", "")) == HeroRules.START_OF_COMBAT:
				EffectRunner.run(
					entry, CombatWorld.make(self, null, side, entry, "start_of_combat")
				)
		_resolve_deaths(side)
		reactions.drain(self)


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


## One side's turn: choose units until one attacks or uses the turn (9.4.5). Stalled and waiting
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
			_emit("skip", {"side": side, "uid": unit.uid, "reason": "stalled"})
			skipped.append(unit)
			continue
		if CombatLanes.wait_once(self, unit):
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
			_attack(unit, _choose_target(unit, true))
		return
	_emit("pass", {"side": side})


## Pin ends after its one skip; Turnip Scarecrow's lasts "skips" attacks.
func _use_skip(unit: CombatUnit) -> void:
	var data: Dictionary = unit.statuses["stalled"]
	var left: int = CoreUtil.to_int(data.get("skips", 1)) - 1
	if left > 0:
		data["skips"] = left
	else:
		set_status(unit, "stalled", false, null)


## 9.4.5 steps 2, 3 and 5; null when no unit can be chosen. A unit that skipped this turn
## (Pin, Bide) can't be chosen again in the same turn, even after a cycle reset (prototype pick).
func _choose_attacker(side: int, skipped: Array[CombatUnit]) -> CombatUnit:
	Pass3BogCombat.sync_hopkin(self)
	var ready: Array[CombatUnit] = []
	for unit: CombatUnit in _attack_order(side):
		if unit.can_act() and not skipped.has(unit) and CombatHunt.can_lead(self, unit):
			ready.append(unit)
	if ready.is_empty():
		return null
	var attacker: CombatUnit = null
	for unit: CombatUnit in ready:
		if not unit.flagged:
			attacker = unit
			break
	if attacker == null:
		cycles[side] += 1
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
	return AttackOrder.rank(rules_here, slot, AttackOrder.early_slots(units_of(side)))


func _pointer_rank(side: int) -> int:
	return -1 if pointers[side] < 0 else _attack_rank(side, pointers[side])


## 9.5.1 back-row protection and 9.5.5 random target among the candidates.
func _choose_target(attacker: CombatUnit, announce: bool = false) -> CombatUnit:
	return CombatLanes.choose_target(self, attacker, announce)


## 9.6.1: declaration (Swarm joiners, "when attacked" effects), Nightshade, then the strikes
## (Peck), each an exchange; then "after" effects for a surviving defender.
func _attack(attacker: CombatUnit, defender: CombatUnit) -> void:
	reactions.attack(self, attacker, defender)


## An immediate attack waits until the current attack and its deaths finish.
func queue_attack(
	attacker: CombatUnit, defender: CombatUnit, kind: String = "counter", attack_bonus: int = 0
) -> void:
	reactions.enqueue(attacker, defender, kind, attack_bonus)


func _perform_attack(attacker: CombatUnit, defender: CombatUnit) -> void:
	if attacker == null or defender == null or not attacker.on_board or not defender.on_board:
		return
	if attacker.is_dead() or defender.is_dead():
		return
	var joiners: Array[CombatUnit] = []
	var strike_count: int = 1
	for index: int in attacker.scripts.size():
		var mechanic: Mechanic = attacker.scripts[index]
		joiners.append_array(mechanic.joiners(self, attacker, attacker.params[index]))
		strike_count = maxi(strike_count, mechanic.strikes(attacker.params[index]))
	# The event's "quick" is the state at declaration; each exchange checks again (_strikes).
	var pack: Array[CombatUnit] = CombatHunt.joiners(self, attacker, defender)
	joiners.append_array(pack)
	joiners = CombatLanes.legal_joiners(self, joiners, defender)
	reactions.pack_joiners = pack
	if log_events:
		var quick_now: bool = _is_quick(attacker) != _is_quick(defender)
		var attack_event: Dictionary = {
			"side": attacker.side,
			"attacker": attacker.uid,
			"defender": defender.uid,
			"joiners": CombatMoves.uid_list(joiners),
			"strikes": strike_count,
			"quick": quick_now,
		}
		if not pack.is_empty():
			attack_event["pack"] = true
		_emit("attack", attack_event)
	_attack_declared(attacker, defender)
	if not attacker.on_board:
		_emit("cancel", {"uid": attacker.uid, "reason": "died_before_attacking"})
		return
	if not defender.on_board or _halted:
		return
	CombatMoves.nightshade(self, defender)
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
		CombatMoves.after_attacked_once(self, attacker)


## Peck: each strike fires "whenever this attacks" and is its own exchange; joiners and the
## return blow land with the last strike (SPEC 4.2). Quick is checked per exchange, so a unit
## damaged by the declaration or an earlier strike loses "Quick while undamaged" (entry 24);
## First Bite is used up by the first exchange.
func _strikes(
	attacker: CombatUnit, defender: CombatUnit, joiners: Array[CombatUnit], strike_count: int
) -> void:
	var parts: Array[int] = Hit.split(_strike_attack(attacker), strike_count)
	for strike: int in strike_count:
		reactions.last_strike = strike == strike_count - 1
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
					hits_out.append(
						_attack_hit(joiner, defender, CombatHunt.join_attack(self, joiner), 1, true)
					)
			hits_back.append(_attack_hit(defender, attacker, defender.attack, strike + 1, false))
		if Pass3Combat.has_content(self) and config.get_bool("pass3_loop_guards"):
			var leader_hits: Array[Hit] = [hits_out[0]]
			CombatDamage.cleave(self, leader_hits)
			hits_out.append_array(leader_hits.slice(1))
		else:
			CombatDamage.cleave(self, hits_out)
		var attacker_quick: bool = _is_quick(attacker)
		var defender_quick: bool = _is_quick(defender)
		if strike == 0:
			_use_first_bite(attacker)
			_use_first_bite(defender)
		_exchange(hits_out, hits_back, attacker_quick, defender_quick, attacker.side)


## Wren reads the highest enemy Attack, then applies this declaration's Bitter loss.
func _strike_attack(attacker: CombatUnit) -> int:
	if attacker.counters.has("bog_hopkin_attack"):
		return maxi(
			attacker.attack,
			(
				CoreUtil.to_int(attacker.counters["bog_hopkin_attack"])
				- CoreUtil.to_int(attacker.counters.get("bitter_borrowed", 0))
			)
		)
	if not attacker.has_status("borrowed_attack"):
		return attacker.attack
	var highest: int = 0
	for enemy: CombatUnit in units_of(1 - attacker.side):
		highest = maxi(highest, enemy.attack)
	return (
		maxi(1, highest - CoreUtil.to_int(attacker.counters.get("bitter_borrowed", 0)))
		if highest > 0
		else 0
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
	for hit: Hit in hits_out + hits_back:
		hit.blow_side = side
	if out_quick == back_quick:
		var all_hits: Array[Hit] = hits_out.duplicate()
		all_hits.append_array(hits_back)
		_damage_step(all_hits, side)
		return
	var first: Array[Hit] = hits_out if out_quick else hits_back
	var second: Array[Hit] = hits_back if out_quick else hits_out
	_damage_step(first, side, false)
	var still: Array[Hit] = []
	for hit: Hit in second:
		if hit.source.on_board and hit.target.on_board:
			still.append(hit)
	_damage_step(still, side)


func _damage_step(hits: Array[Hit], side: int, final_step: bool = true) -> void:
	if hits.is_empty():
		return
	_apply_hits(hits)
	_flush_thorns()
	CombatHunt.pack_kill(self)
	reactions.before_deaths(self, final_step)
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
	CombatDamage.apply(self, hits)


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
		var witnesses: Array = [units_of(0), units_of(1)]
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
		CombatLanes.enemy_deaths(self, dying, witnesses)
		for unit: CombatUnit in dying:
			for index: int in unit.scripts.size():
				unit.scripts[index].on_death(self, unit, unit.params[index])
			if _has_ally_listener(unit.side):
				for ally: CombatUnit in units_of(unit.side):
					for index: int in ally.ally_listeners:
						ally.scripts[index].on_friendly_death(self, ally, ally.params[index], unit)
			CombatMoves.hero_on_death(self, unit)
		CombatHeld.open_bellies(self, dying)
		_flush_thorns()
	if swallowing:
		CombatHeld.check_sides(self)


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
	CombatLanes.sync_mire(self)
	CombatAuras.recalc(self, log_changes)


func _has_slot_effects() -> bool:
	return BoardUpkeep.any_slot_effects(slot_effects)


## 8.5.1: what the unit's slot gives it. It stays with the slot, not the unit.
func _slot_bonus(unit: CombatUnit) -> Vector2i:
	var bonus: Vector2i = CombatRings.bonus(self, unit)
	var row: Dictionary = hexes[unit.side]
	unit.hex_amount = 0 if row.is_empty() else CoreUtil.to_int(row.get(unit.slot, 0))
	unit.hex_amount += CombatScale.hex_loss(self, unit, bonus.x)
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
	Pass3BogCombat.sync_hopkin(self)
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
	Pass3BogCombat.finish(self)
	Pass3HunterGains.finish(self)
	var survivors: Array = [CombatMoves.uid_list(units_of(0)), CombatMoves.uid_list(units_of(1))]
	var winner: int = -1
	var last_blow: bool = false
	if reason == REASON_BOARD_EMPTY:
		var left_0: bool = not units_of(0).is_empty()
		var left_1: bool = not units_of(1).is_empty()
		if left_0 != left_1:
			winner = 0 if left_0 else 1
		elif (
			not left_0
			and _attacks_started
			and config.get_bool("last_blow")
			and _last_blow_side >= 0
		):
			winner = _last_blow_side
			last_blow = true
	var uncapped: int = 0
	if winner >= 0:
		uncapped = (
			maxi(4, tiers[winner])
			if last_blow
			else CombatMoves.hero_damage(self, winner, tiers[winner])
		)
	var base: int = uncapped
	var performance: int = 0
	if config.uses_v05_damage():
		base = config.get_int_at("base_damage_by_turn", round_number - 1) if winner >= 0 else 0
		performance = CombatMoves.starting_survivors(self, winner) if winner >= 0 else 0
		uncapped = base + performance
		damage_cap = 0
	var damage: int = uncapped if damage_cap <= 0 else mini(uncapped, damage_cap)
	_emit(
		"combat_end",
		{
			"winner": winner,
			"reason": reason,
			"survivors": survivors,
			"damage": damage,
			"damage_uncapped": uncapped,
			"damage_base": base,
			"damage_performance": performance,
			"damage_mode": config.get_string("damage_mode"),
			"last_blow": last_blow,
			"last_blow_side": _last_blow_side if last_blow else -1,
			"last_blow_source": _last_blow_source if last_blow else -1,
			"last_blow_kind": _last_blow_kind if last_blow else "",
		}
	)
	return {
		"events": events,
		"winner": winner,
		"damage": damage,
		"damage_uncapped": uncapped,
		"damage_base": base,
		"damage_performance": performance,
		"reason": reason,
		"carry": carry,
		"takes": takes.duplicate(),
		"last_blow": last_blow,
	}


func _board_views(side: int) -> Array:
	var out: Array = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: CombatUnit = unit_at(side, slot)
		if unit == null:
			out.append(null)
		else:
			out.append(unit.view(_status_text))
	return out


func _emit(type: String, fields: Dictionary) -> void:
	if not log_events:
		return
	var event: Dictionary = {"seq": events.size(), "type": type}
	event.merge(fields)
	events.append(event)
