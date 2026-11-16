class_name FightReplay
extends RefCounted
## Turns the rules core's fight log (src/core/README.md, "Fight log") into the fight screen's
## steps: each a whole view state with its moment, and how long it is held. It reads only the
## log; it decides nothing. Steps, at speed 1 (STAND-IN timing, fight animation is not designed):
##   combat_start: both boards whole
##   attack: the attacker lunges; the damage events that follow splash on both units
##   death: the units leave their slots, which stay empty (8.3.4)
##   summon, return: the unit appears in its slot
##   buff, status: the numbers or pills change
##   combat_end: the result, with the loser's damage when the caller gives it
## Any event naming a uid resyncs that unit from the fields it carries (attack, health,
## max_health, keywords, counters, golden), so an event type the core adds later updates the
## numbers without a step of its own. Unknown events never fail.

const HOLD_START: float = 0.7
const HOLD_LUNGE: float = 0.22
const HOLD_SPLASH: float = 0.55
const HOLD_DEATH: float = 0.3
const HOLD_SUMMON: float = 0.35
const HOLD_CHANGE: float = 0.25
const HOLD_END: float = 1.5
const SLOTS: int = 7
## Unit fields an event may carry that the screen shows.
const SYNCED: Array[String] = ["attack", "health", "max_health", "keywords", "counters", "golden"]

## [{state, hold}], in order.
var steps: Array[Dictionary] = []
## The boards after the last event: [side 0, side 1], 7 entries each.
var boards: Array = [[], []]

var _base: Dictionary
var _catalog: Dictionary
var _moment: Dictionary = {}
## uid -> [side, slot]
var _where: Dictionary = {}


## base: the view state around the fight (hero, opponent, you_side, slots...); its boards are
## replaced by the log's. catalog: card id -> {name, tier, art, text, health} for what the log
## does not carry. damage: what the loser takes, from GameSession's fight entry (-1 for none).
static func build(
	base: Dictionary, events: Array, catalog: Dictionary, damage: int = -1
) -> FightReplay:
	var replay: FightReplay = FightReplay.new()
	replay._base = base
	replay._catalog = catalog
	for i: int in 2:
		var row: Array = []
		row.resize(SLOTS)
		replay.boards[i] = row
	for value: Variant in events:
		if value is Dictionary:
			var event: Dictionary = value
			replay._apply(event, damage)
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


func _apply(event: Dictionary, damage: int) -> void:
	var kind: String = str(event.get("type", ""))
	if kind != "damage" and _moment.has("splashes"):
		# the splashes have been seen; the attacker goes home
		_moment = {}
	match kind:
		"combat_start":
			_moment = {}
			var start: Array = event.get("boards", [[], []])
			for side: int in mini(2, start.size()):
				var listed: Array = start[side]
				for item: Variant in listed:
					if item is Dictionary:
						var view: Dictionary = item
						_place(_unit_view(view, side))
			_push(HOLD_START)
		"attack":
			_moment = {
				"lunge":
				{
					"side": _i(event["side"]),
					"slot": _i(event["slot"]),
					"target_side": _i(event["target_side"]),
					"target_slot": _i(event["target_slot"]),
				}
			}
			_push(HOLD_LUNGE)
		"damage":
			_sync(event)
			var splashes: Array = _moment.get("splashes", [])
			var at: Array = _locate(event)
			if not at.is_empty():
				splashes.append({"side": at[0], "slot": at[1], "amount": _i(event["amount"])})
			_moment["splashes"] = splashes
			# the damage of one attack or effect shares a step
			if not steps.is_empty() and str(steps[steps.size() - 1].get("kind", "")) == "splash":
				steps.pop_back()
			_push(HOLD_SPLASH, "splash")
		"death":
			var at: Array = _locate(event)
			if not at.is_empty():
				var row: Array = boards[at[0]]
				row[at[1]] = null
				_where.erase(_i(event.get("uid", -1)))
			# deaths of one pass share a step
			if not steps.is_empty() and str(steps[steps.size() - 1].get("kind", "")) == "death":
				steps.pop_back()
			_push(HOLD_DEATH, "death")
		"summon":
			var view: Dictionary = event.duplicate()
			_place(_unit_view(view, _i(event["side"])))
			_push(HOLD_SUMMON)
		"return":
			_sync(event)
			_push(HOLD_SUMMON)
		"status":
			var at: Array = _locate(event)
			if not at.is_empty():
				var unit: Dictionary = _row(at[0])[at[1]]
				var keywords: Array = unit.get("keywords", [])
				var status: String = str(event.get("status", ""))
				if _b(event.get("on", false)):
					if not keywords.has(status):
						keywords.append(status)
				else:
					keywords.erase(status)
				unit["keywords"] = keywords
			_push(HOLD_CHANGE)
		"buff":
			_sync(event)
			_push(HOLD_CHANGE)
		"combat_end":
			_moment = {"result": {"winner": _i(event.get("winner", -1)), "damage": maxi(0, damage)}}
			_push(HOLD_END)
		_:
			# trigger, pass, destroy, summon_failed and any type added later: numbers only
			if _sync(event):
				_push(HOLD_CHANGE)


## Copies the fields an event carries onto its unit; true when the unit was found.
func _sync(event: Dictionary) -> bool:
	var at: Array = _locate(event)
	if at.is_empty():
		return false
	var unit: Dictionary = _row(at[0])[at[1]]
	var old_health: int = _i(unit.get("health", 0))
	for key: String in SYNCED:
		if event.has(key):
			unit[key] = event[key]
	# a buff to Health raises the most it can have; damage does not
	if str(event.get("type", "")) == "buff" and not event.has("max_health"):
		var gain: int = _i(unit.get("health", 0)) - old_health
		if gain > 0:
			unit["max_health"] = _i(unit.get("max_health", 0)) + gain
	return true


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
		"text": str(card.get("text", "")),
		"attack": _i(view.get("attack", 0)),
		"health": _i(view.get("health", 0)),
		"keywords": _list(view.get("keywords", card.get("keywords", []))),
		"counters": _list(view.get("counters", [])),
		"golden": _b(view.get("golden", false)),
	}
	var full: int = _i(card.get("health", 0)) * (2 if unit["golden"] else 1)
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


func _push(hold: float, kind: String = "") -> void:
	var view: Dictionary = _base.duplicate(true)
	view["boards"] = boards.duplicate(true)
	view["moment"] = _moment.duplicate(true)
	steps.append({"state": view, "hold": hold, "kind": kind})


func _row(side: Variant) -> Array:
	var row: Array = boards[_i(side)]
	return row


static func _list(v: Variant) -> Array:
	var out: Array = v if v is Array else []
	return out.duplicate()


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _b(v: Variant) -> bool:
	return GlassPieces.as_bool(v)
