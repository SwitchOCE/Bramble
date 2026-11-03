extends RefCounted
## What the combat screen knows at each point of a fight: which unit is in which slot with what
## stats and statuses. Built only by applying SPEC section 5 events in order; it never decides
## anything (the event log already says what happened). Pure data, so tests can check it.

const Data := preload("res://src/ui/view_data.gd")
const SLOTS: int = 7

## uid -> combat unit view (SPEC 6.3) plus "side", "slot" and "alive".
var units: Dictionary[int, Dictionary] = {}
## boards[side][slot] = uid, or -1 for empty.
var boards: Array[PackedInt32Array] = []
var player_ids: Array = [-1, -1]
var first_side: int = 0
var phase: String = ""
var finished: bool = false
var winner: int = -1
var damage: int = 0
var damage_uncapped: int = 0
var end_reason: String = ""
## Enemy slots marked by Mark: [{"owner_side", "side", "slot", "damage"}].
var slot_marks: Array[Dictionary] = []


func _init() -> void:
	reset()


func reset() -> void:
	units.clear()
	boards = [PackedInt32Array(), PackedInt32Array()]
	for side: int in 2:
		boards[side].resize(SLOTS)
		boards[side].fill(-1)
	slot_marks.clear()
	finished = false
	phase = ""


func unit(uid: int) -> Dictionary:
	return units.get(uid, {})


func unit_name(uid: int) -> String:
	return str(unit(uid).get("name", "unit %d" % uid))


func uid_at(side: int, slot: int) -> int:
	return boards[side][slot]


## Applies one event. Unknown event types are ignored, so a newer core doesn't break playback.
func apply(event: Dictionary) -> void:
	match str(event.get("type", "")):
		"combat_start":
			_start(event)
		"phase":
			phase = str(event.get("name", ""))
		"damage", "health_loss":
			_set_health(Data.i(event, "target", -1), Data.i(event, "health_after", 0))
		"status":
			_status(event)
		"stats":
			_stats(event)
		"death":
			_death(Data.i(event, "uid", -1))
		"summon":
			var view: Dictionary = Data.d(event, "unit")
			_add(view.duplicate(true), Data.i(event, "side", 0), Data.i(event, "slot", 0))
		"slot_mark":
			slot_marks.append(event.duplicate())
		"combat_end":
			finished = true
			winner = Data.i(event, "winner", -1)
			damage = Data.i(event, "damage", 0)
			damage_uncapped = event.get("damage_uncapped", damage)
			end_reason = str(event.get("reason", ""))


func _start(event: Dictionary) -> void:
	reset()
	player_ids = event.get("player_ids", [-1, -1])
	first_side = Data.i(event, "first_side", 0)
	var start_boards: Array = event.get("boards", [[], []])
	for side: int in mini(2, start_boards.size()):
		var board: Array = start_boards[side]
		for slot: int in mini(SLOTS, board.size()):
			var entry: Variant = board[slot]
			if entry is Dictionary:
				var view: Dictionary = entry
				_add(view.duplicate(true), side, slot)


func _add(view: Dictionary, side: int, slot: int) -> void:
	var uid: int = Data.i(view, "uid", -1)
	view["side"] = side
	view["slot"] = slot
	view["alive"] = true
	if not view.has("max_health"):
		view["max_health"] = Data.i(view, "health", 0)
	if not view.has("statuses"):
		view["statuses"] = []
	units[uid] = view
	if slot >= 0 and slot < SLOTS:
		boards[side][slot] = uid


func _set_health(uid: int, health: int) -> void:
	if units.has(uid):
		units[uid]["health"] = health


func _status(event: Dictionary) -> void:
	var uid: int = Data.i(event, "target", -1)
	if not units.has(uid):
		return
	var key: String = str(event.get("status", ""))
	var statuses: Array = units[uid].get("statuses", [])
	var kept: Array = []
	for entry: Variant in statuses:
		var status: Dictionary = entry
		if str(status.get("status", "")) != key:
			kept.append(status)
	var on: bool = Data.b(event, "on", true)
	if on:
		kept.append({"status": key, "data": Data.d(event, "data")})
	units[uid]["statuses"] = kept


func _stats(event: Dictionary) -> void:
	var uid: int = Data.i(event, "target", -1)
	if not units.has(uid):
		return
	var view: Dictionary = units[uid]
	view["attack"] = event.get("attack", Data.i(view, "attack", 0))
	view["health"] = event.get("health", Data.i(view, "health", 0))
	view["max_health"] = event.get("max_health", Data.i(view, "max_health", 0))


func _death(uid: int) -> void:
	if not units.has(uid):
		return
	var view: Dictionary = units[uid]
	view["alive"] = false
	var side: int = Data.i(view, "side", 0)
	var slot: int = Data.i(view, "slot", -1)
	if slot >= 0 and slot < SLOTS and boards[side][slot] == uid:
		boards[side][slot] = -1
