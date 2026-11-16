class_name FightReplay
extends RefCounted
## Turns the rules core's fight log (src/core/README.md, "Fight log") into the fight screen's
## steps: each a whole view state with its moment, and how long it is held. It reads only the
## log; it decides nothing. Steps, at speed 1 (STAND-IN timing, fight animation is not designed):
##   combat_start: both boards whole
##   trigger: the unit that acts glows and lifts in place; what it does follows, still glowing
##   attack: the attacker lunges (from rest: a lunge still showing goes home first) and stays
##     there through its whole attack (damage, triggers, destroy) until the deaths or the next
##     attack; the damage events of one hit share a step, each splashing on its unit
##   destroy: a splash with no number on the unit
##   death: the units of one pass leave their slots together, which stay empty (8.3.4)
##   summon, return: the unit appears in its slot
##   buff, stats, keyword, counter, status, slot, move: the numbers, pills or places change; the
##     changes of one moment (several in a row) share a step
##   combat_end: the result, the loser's damage taken off their Health
## A step that would look exactly like the one before is not made. Any event naming a placed uid
## resyncs that unit from the fields it carries (attack, health, max_health, keywords, counters,
## golden), so an event type the core adds later still updates the numbers. Unknown events never
## fail.

const HOLD_START: float = 0.7
const HOLD_HOME: float = 0.14
const HOLD_LUNGE: float = 0.22
const HOLD_SPLASH: float = 0.55
const HOLD_TRIGGER: float = 0.3
const HOLD_DEATH: float = 0.3
const HOLD_SUMMON: float = 0.35
const HOLD_CHANGE: float = 0.3
const HOLD_END: float = 1.5
const SLOTS: int = 7
## Unit fields an event may carry that the screen shows.
const SYNCED: Array[String] = ["attack", "health", "max_health", "keywords", "counters", "golden"]
## Events that change what a unit shows; several in a row are one moment and share a step.
const CHANGES: Array[String] = [
	"buff",
	"stats",
	"keyword",
	"counter",
	"uses",
	"status",
	"slot",
	"move",
	"player_counter",
	"heap_add",
	"heap_remove",
]

## [{state, hold, kind}], in order.
var steps: Array[Dictionary] = []
## The boards after the last event: [side 0, side 1], 7 entries each.
var boards: Array = [[], []]

var _base: Dictionary
var _catalog: Dictionary
var _moment: Dictionary = {}
## uid -> [side, slot]
var _where: Dictionary = {}
## uid -> the unit as it was when it died, for a return
var _gone: Dictionary = {}


## base: the view state around the fight (hero, opponent, you_side, slots...); its boards are
## replaced by the log's. catalog: card id -> {name, tier, art, text, health} for what the log
## does not carry. damage: what the loser takes, from GameSession's fight entry (-1 for none).
static func build(
	base: Dictionary, events: Array, catalog: Dictionary, damage: int = -1
) -> FightReplay:
	var replay: FightReplay = FightReplay.start(base, catalog)
	for value: Variant in events:
		if value is Dictionary:
			var event: Dictionary = value
			replay.apply(event, damage)
	return replay


## An empty replay, for feeding events one at a time with apply.
static func start(base: Dictionary, catalog: Dictionary) -> FightReplay:
	var replay: FightReplay = FightReplay.new()
	replay._base = base
	replay._catalog = catalog
	for i: int in 2:
		var row: Array = []
		row.resize(SLOTS)
		replay.boards[i] = row
	return replay


## The board of one side after the fight as [{slot, uid, attack, health}], for checking against
## the core's result.
func summary(side: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var row: Array = boards[side]
	for slot: int in row.size():
		if row[slot] is Dictionary:
			var unit: Dictionary = row[slot]
			(
				out
				. append(
					{
						"slot": slot,
						"uid": _i(unit.get("uid", -1)),
						"attack": _i(unit.get("attack", 0)),
						"health": _i(unit.get("health", 0)),
					}
				)
			)
	return out


## Takes one event of the log: updates the boards and makes the step it shows, if any.
func apply(event: Dictionary, damage: int = -1) -> void:
	var kind: String = str(event.get("type", ""))
	if kind != "damage" and kind != "destroy":
		_moment.erase("splashes")
	if kind in ["death", "summon", "return", "pass", "combat_end", "combat_start"]:
		_moment.erase("lunge")
	if kind in ["attack", "death", "pass", "combat_end", "combat_start"]:
		_moment.erase("trigger")
	match kind:
		"combat_start":
			var first: Array = event.get("boards", [[], []])
			for side: int in mini(2, first.size()):
				var listed: Array = first[side]
				for item: Variant in listed:
					if item is Dictionary:
						var view: Dictionary = item
						_place(_unit_view(view, side))
			_push(HOLD_START)
		"trigger":
			var at: Array = _locate(event)
			if at.is_empty():
				return
			_moment["trigger"] = {"side": at[0], "slot": at[1]}
			_push(HOLD_TRIGGER, "trigger")
		"attack":
			if _moment.has("lunge"):
				_moment.erase("lunge")
				_push(HOLD_HOME)
			_moment["lunge"] = {
				"side": _i(event["side"]),
				"slot": _i(event["slot"]),
				"target_side": _i(event["target_side"]),
				"target_slot": _i(event["target_slot"]),
			}
			_push(HOLD_LUNGE)
		"damage", "destroy":
			_sync(event)
			var at: Array = _locate(event)
			if not at.is_empty():
				var splashes: Array = _moment.get("splashes", [])
				var amount: int = _i(event.get("amount", 0)) if kind == "damage" else 0
				splashes.append({"side": at[0], "slot": at[1], "amount": amount})
				_moment["splashes"] = splashes
			_push(HOLD_SPLASH, "splash")
		"death":
			var at: Array = _locate(event)
			if not at.is_empty():
				var uid: int = _i(event.get("uid", -1))
				_gone[uid] = _row(at[0])[at[1]]
				_row(at[0])[at[1]] = null
				_where.erase(uid)
			_push(HOLD_DEATH, "death")
		"summon", "reserve":
			# a unit new to the board: a summon (a reborn one too) or a Reserve unit stepping in
			_place(_unit_view(event, _i(event["side"])))
			_push(HOLD_SUMMON)
		"return":
			_return(event)
			_push(HOLD_SUMMON)
		"move":
			_move(event)
			_push(HOLD_CHANGE, "change")
		"keyword", "status":
			_set_keyword(event)
			_push(HOLD_CHANGE, "change")
		"counter":
			_set_counter(event)
			_push(HOLD_CHANGE, "change")
		"uses":
			# uses left a unit shows ("Privates left 2"): drawn like its counters
			var left: Dictionary = event.duplicate()
			left["value"] = event.get("left", 0)
			_set_counter(left)
			_push(HOLD_CHANGE, "change")
		"slot":
			_set_slot(event)
			_push(HOLD_CHANGE, "change")
		"player_counter", "heap_add", "heap_remove":
			if _set_player_number(event):
				_push(HOLD_CHANGE, "change")
		"combat_end":
			_moment["result"] = {"winner": _i(event.get("winner", -1)), "damage": maxi(0, damage)}
			_push(HOLD_END)
			_take_damage(_i(event.get("winner", -1)), damage)
		_:
			# buff, stats and any type added later: numbers only. A unit view for a unit not on the
			# board yet (an aura's stats logged before its summon) places it quietly.
			if not _sync(event) and event.has("id") and event.has("slot") and event.has("side"):
				_place(_unit_view(event, _i(event["side"])))
			_push(HOLD_CHANGE, "change")


## Copies the fields an event carries onto its unit; true when the unit was found.
func _sync(event: Dictionary) -> bool:
	var at: Array = _locate(event)
	if at.is_empty():
		return false
	var unit: Dictionary = _row(at[0])[at[1]]
	var old_health: int = _i(unit.get("health", 0))
	for key: String in SYNCED:
		if event.has(key):
			unit[key] = _counters(event[key]) if key == "counters" else event[key]
	# a buff to Health raises the most it can have; damage does not
	if str(event.get("type", "")) == "buff" and not event.has("max_health"):
		var gain: int = _i(unit.get("health", 0)) - old_health
		if gain > 0:
			unit["max_health"] = _i(unit.get("max_health", 0)) + gain
	# an aura or slot effect moves the most it can have with it
	if str(event.get("type", "")) == "stats" and not event.has("max_health"):
		unit["max_health"] = maxi(
			_i(unit.get("max_health", 0)) + _i(unit["health"]) - old_health, 0
		)
	return true


## A unit coming back (reborn): the one that died, under its new uid, in its slot.
func _return(event: Dictionary) -> void:
	if _sync(event):
		return
	var was: Variant = _gone.get(_i(event.get("from_uid", -1)))
	if not was is Dictionary:
		return
	var gone: Dictionary = was
	var unit: Dictionary = gone.duplicate(true)
	unit["uid"] = _i(event.get("uid", -1))
	unit["slot"] = _i(event.get("slot", unit.get("slot", 0)))
	unit["health"] = _i(event.get("health", 1))
	_place(unit)
	_sync(event)


func _move(event: Dictionary) -> void:
	var at: Array = _locate(event)
	if at.is_empty():
		return
	var unit: Dictionary = _row(at[0])[at[1]]
	_row(at[0])[at[1]] = null
	unit["slot"] = _i(event.get("to", at[1]))
	_place(unit)


func _set_keyword(event: Dictionary) -> void:
	var at: Array = _locate(event)
	if at.is_empty():
		return
	var unit: Dictionary = _row(at[0])[at[1]]
	var keywords: Array = unit.get("keywords", [])
	var word: String = str(event.get("keyword", event.get("status", "")))
	if _b(event.get("on", false)):
		if not keywords.has(word):
			keywords.append(word)
	else:
		keywords.erase(word)
	unit["keywords"] = keywords


## A slot's lasting bonus as the fight changes it: the event's total, in the contract's shape.
func _set_slot(event: Dictionary) -> void:
	var total: Variant = event.get("total")
	if not total is Dictionary:
		return
	var side: int = _i(event.get("side", 0))
	var slot: int = _i(event.get("slot", -1))
	var all_slots: Array = _base.get("slots", [[], []])
	if side >= all_slots.size() or slot < 0 or slot >= SLOTS:
		return
	var row: Array = all_slots[side]
	while row.size() < SLOTS:
		row.append({})
	var was: Dictionary = row[slot] if row[slot] is Dictionary else {}
	var given: Dictionary = total
	var now: Dictionary = given.duplicate(true)
	if was.has("label"):
		now["label"] = was["label"]
	row[slot] = now
	_base["slots"] = all_slots


func _set_counter(event: Dictionary) -> void:
	var at: Array = _locate(event)
	if at.is_empty():
		return
	var unit: Dictionary = _row(at[0])[at[1]]
	var counters: Array = unit.get("counters", [])
	var key: String = str(event.get("key", ""))
	for value: Variant in counters:
		var counter: Dictionary = value
		if str(counter.get("key", "")) == key:
			counter["value"] = event.get("value", 0)
			return
	counters.append({"key": key, "value": event.get("value", 0)})
	unit["counters"] = counters


## Your counter or heap chip as the fight changes it (a Seed going into the Compost): its value,
## and a heap's entries. The other side's numbers are not shown. True when a chip changed.
func _set_player_number(event: Dictionary) -> bool:
	if _i(event.get("side", -1)) != _i(_base.get("you_side", 0)):
		return false
	var kind: String = str(event.get("type", ""))
	var key: String = str(event.get("key" if kind == "player_counter" else "heap", ""))
	var chips: Array = _base.get("counters", [])
	for value: Variant in chips:
		var chip: Dictionary = value if value is Dictionary else {}
		if str(chip.get("id", chip.get("key", ""))) != key:
			continue
		if kind == "player_counter":
			chip["value"] = event.get("value", 0)
			return true
		chip["value"] = _i(event.get("size", chip.get("value", 0)))
		var entries: Array = chip.get("entries", [])
		if kind == "heap_add":
			var card_id: String = str(event.get("id", ""))
			var card: Dictionary = _catalog.get(card_id, {})
			(
				entries
				. append(
					{
						"id": card_id,
						"name": str(card.get("name", card_id)),
						"tier": _i(card.get("tier", 1)),
					}
				)
			)
		else:
			for gone: Variant in _list(event.get("ids", [])):
				for k: int in entries.size():
					var entry: Dictionary = entries[k]
					if str(entry.get("id", "")) == str(gone):
						entries.remove_at(k)
						break
		chip["entries"] = entries
		return true
	return false


## The loser's Health, on their badge and in the leaderboard, after the result is shown.
func _take_damage(winner: int, damage: int) -> void:
	if winner < 0 or damage <= 0 or steps.is_empty():
		return
	var view: Dictionary = steps[steps.size() - 1]["state"]
	var players: Array = view.get("players", [])
	if winner == _i(view.get("you_side", 0)):
		var opponent: Dictionary = view.get("opponent", {})
		opponent["health"] = _i(opponent.get("health", 0)) - damage
		for value: Variant in players:
			var player: Dictionary = value
			if str(player.get("name", "")) == str(opponent.get("name", "")):
				player["health"] = _i(player.get("health", 0)) - damage
		return
	view["health"] = _i(view.get("health", 0)) - damage
	for value: Variant in players:
		var player: Dictionary = value
		if _b(player.get("you", false)):
			player["health"] = _i(player.get("health", 0)) - damage


## [side, slot] of the unit an event names, or [].
func _locate(event: Dictionary) -> Array:
	var uid: int = _i(event.get("uid", -1))
	if _where.has(uid):
		return _where[uid]
	return []


func _unit_view(view: Dictionary, side: int) -> Dictionary:
	var card: Dictionary = _catalog.get(str(view.get("id", "")), {})
	var unit: Dictionary = {
		"id": str(view.get("id", "")),
		"uid": _i(view.get("uid", -1)),
		"slot": _i(view.get("slot", 0)),
		"side": side,
		"name": str(card.get("name", view.get("id", ""))),
		"tier": _i(card.get("tier", 1)),
		"art": str(card.get("art", "")),
		"text": str(view.get("text", card.get("text", ""))),
		"attack": _i(view.get("attack", 0)),
		"health": _i(view.get("health", 0)),
		"keywords": _list(view.get("keywords", [])),
		"counters": _counters(view.get("counters", [])) + _counters(view.get("uses", {})),
		"golden": _b(view.get("golden", false)),
	}
	# what the card prints, for its pills and reminders, and what an aura gave it in this fight
	var mechanics: Array = _list(card.get("mechanics", []))
	for value: Variant in _list(view.get("grants", [])):
		var grant: Dictionary = value if value is Dictionary else {}
		var mechanic: String = str(grant.get("mechanic", ""))
		if mechanic != "" and not mechanics.has(mechanic):
			mechanics.append(mechanic)
	if not mechanics.is_empty():
		unit["mechanics"] = mechanics
	if card.has("reminders"):
		unit["reminders"] = _list(card["reminders"])
	var full: int = _i(card.get("health", 0)) * (2 if unit["golden"] else 1)
	if card.has("attack") and card.has("health"):
		# what it prints, so a number above it shows green and one below red
		unit["base_attack"] = _i(card["attack"]) * (2 if unit["golden"] else 1)
		unit["base_health"] = full
	unit["max_health"] = maxi(full, _i(unit["health"]))
	if view.has("max_health"):
		unit["max_health"] = _i(view["max_health"])
	return unit


func _place(unit: Dictionary) -> void:
	var side: int = _i(unit["side"])
	var slot: int = _i(unit["slot"])
	var row: Array = boards[side]
	if slot < 0 or slot >= row.size():
		return
	row[slot] = unit
	_where[_i(unit["uid"])] = [side, slot]


## Shows the boards and moment as they are now, held for hold. A step of the same kind as the one
## before (the hits of one attack, the deaths of one pass, the changes of one moment) is merged
## into it; a step that looks exactly like the one before is not made.
func _push(hold: float, kind: String = "") -> void:
	var view: Dictionary = _base.duplicate(true)
	view["boards"] = boards.duplicate(true)
	view["moment"] = _moment.duplicate(true)
	if not steps.is_empty():
		var last: Dictionary = steps[steps.size() - 1]
		if kind != "" and kind != "trigger" and str(last.get("kind", "")) == kind:
			last["state"] = view
			return
		var shown: Dictionary = last["state"]
		if shown == view:
			return
	steps.append({"state": view, "hold": hold, "kind": kind})


func _row(side: Variant) -> Array:
	var row: Array = boards[_i(side)]
	return row


## A unit's counters as the screens draw them: [{key, value}] (the log gives {key: value}).
static func _counters(v: Variant) -> Array:
	if v is Dictionary:
		var held: Dictionary = v
		var out: Array = []
		for key: Variant in held:
			out.append({"key": str(key), "value": held[key]})
		return out
	return _list(v)


static func _list(v: Variant) -> Array:
	var out: Array = v if v is Array else []
	return out.duplicate()


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _b(v: Variant) -> bool:
	return GlassPieces.as_bool(v)
