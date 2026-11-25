class_name FightOrder
extends RefCounted
## CB8 c, several deaths at once (docs/workstreams/fight-animation-24-nov/research/mass-deaths.md;
## the owner, 25 Nov: "I want all the recommendations implemented into the game"): the log a fight
## is shown from, with each group of deaths at once in display order and tagged with the frame
## its fall starts after the first, and each death's own "after a friendly unit dies" gain moved
## beside it. Display order only: the deaths still resolve at one moment in the rules core, and
## the board at the end is the core's. Ported from the fight fixture's best_timeline.gd
## (reorder, _staggered), which keeps the other options. FightReplay.schedule plays it.

## The gaps between fall starts (frames): the k-th gap is GAPS[k], FLOOR past the list. A spread
## longer than CAP shrinks every gap by the same factor.
const GAPS: Array[int] = [10, 7, 5, 4, 4]
const FLOOR: int = 4
const CAP: int = 30
## A death's own gain lands this long after its fall starts (the fall's length: the slot empty).
const LAND: int = 15


## The log with every run of two or more deaths at once in rulebook 9.7.3's order (the active
## side's dying units first, then the other side's, each in reading order), each death tagged
## `stagger_at` (frames after the group's first fall). When the run is followed by one "after a
## friendly unit dies" beat per friendly death, of one mechanic, from a living source (Old Brock),
## the k-th beat is that side's k-th death in the log: its events are tagged `stagger_at` (that
## death's start + LAND), and the group is sorted by frame. When that changes the order of the
## beats, their buffs' Attack and Health are recounted so each stays true and the last equals the
## log's. Otherwise (a death effect among them, say)
## what follows waits for the last fall. A log with no such run comes back as it is.
static func staggered(events: Array) -> Array:
	var out: Array = []
	var active: int = -1
	var i: int = 0
	while i < events.size():
		var event: Dictionary = events[i]
		if _kind_of(event) == "attack":
			active = _i(event.get("side", -1))
		var run: int = i
		while run < events.size() and _kind_at(events, run) == "death":
			run += 1
		if run - i < 2:
			out.append(event)
			i += 1
			continue
		var deaths: Array[Dictionary] = []
		for k: int in range(i, run):
			deaths.append(_at(events, k))
		var beats: Array[Array] = _friendly_beats(events, run, deaths)
		var shown: Array[Dictionary] = deaths.duplicate()
		shown.sort_custom(
			func(x: Dictionary, y: Dictionary) -> bool:
				return _reading(x, active) < _reading(y, active)
		)
		var starts: Array[int] = starts_of(shown.size())
		var start_of: Dictionary = {}
		# [frame after the first fall, 0 death / 1 beat, index, events]
		var rows: Array[Array] = []
		for k: int in shown.size():
			var death: Dictionary = shown[k].duplicate()
			death["stagger_at"] = starts[k]
			start_of[_i(death["uid"])] = starts[k]
			rows.append([starts[k], 0, k, [death]])
		var friendly: Array[int] = []
		if not beats.is_empty():
			var trigger: Dictionary = beats[0][0]
			for death: Dictionary in deaths:
				if _i(death["side"]) == _i(trigger["side"]):
					friendly.append(_i(death["uid"]))
		for k: int in beats.size():
			var at: int = _i(start_of[friendly[k]]) + LAND
			var tagged: Array[Dictionary] = []
			for value: Variant in beats[k]:
				var part: Dictionary = value
				var copy: Dictionary = part.duplicate()
				copy["stagger_at"] = at
				tagged.append(copy)
			rows.append([at, 1, k, tagged])
		rows.sort_custom(_row_before)
		var moved: bool = false
		var next_beat: int = 0
		for row: Array in rows:
			if _i(row[1]) == 1:
				moved = moved or _i(row[2]) != next_beat
				next_beat += 1
		if moved:
			_recount(rows, beats, events, i)
		for row: Array in rows:
			var part: Array = row[3]
			out.append_array(part)
		i = run
		for beat: Array in beats:
			i += beat.size()
	return out


## Whether a log has a staggered group (staggered() changed it).
static func has_stagger(events: Array) -> bool:
	for value: Variant in events:
		if not value is Dictionary:
			continue
		var event: Dictionary = value
		if event.has("stagger_at"):
			return true
	return false


## When each of n deaths at once starts its fall, in frames after the first.
static func starts_of(n: int) -> Array[int]:
	var widths: Array[float] = []
	var total: float = 0.0
	for k: int in maxi(n - 1, 0):
		var gap: float = float(GAPS[k]) if k < GAPS.size() else float(FLOOR)
		widths.append(gap)
		total += gap
	var shrink: float = 1.0
	if total > CAP:
		shrink = CAP / total
	var out: Array[int] = [0]
	var sum: float = 0.0
	for gap: float in widths:
		sum += gap * shrink
		out.append(roundi(sum))
	return out


## Where a dying unit stands in rulebook 9.7.3's order: the active side first, then reading order.
static func _reading(death: Dictionary, active: int) -> int:
	var other: int = 0 if _i(death["side"]) == active else 1
	return other * 100 + _i(death["slot"])


static func _row_before(x: Array, y: Array) -> bool:
	for c: int in 3:
		if _i(x[c]) != _i(y[c]):
			return _i(x[c]) < _i(y[c])
	return false


## The beats right after a run of deaths that are one per friendly death (see staggered), each
## [trigger, what it does...], or [] when they are not.
static func _friendly_beats(events: Array, from: int, deaths: Array[Dictionary]) -> Array[Array]:
	var none: Array[Array] = []
	if from >= events.size() or _kind_at(events, from) != "trigger":
		return none
	var first: Dictionary = events[from]
	var source: int = _i(first.get("uid", -1))
	var side: int = _i(first.get("side", -1))
	for death: Dictionary in deaths:
		if _i(death["uid"]) == source:
			return none
	var beats: Array[Array] = []
	var j: int = from
	while j < events.size():
		var trigger: Dictionary = events[j]
		if (
			_kind_of(trigger) != "trigger"
			or _i(trigger.get("uid", -1)) != source
			or str(trigger.get("mechanic", "")) != str(first.get("mechanic", ""))
		):
			break
		var beat: Array = [trigger]
		j += 1
		while (
			j < events.size()
			and not _kind_at(events, j) in ["trigger", "death", "attack", "combat_end"]
		):
			beat.append(events[j])
			j += 1
		beats.append(beat)
	var friendly: int = 0
	for death: Dictionary in deaths:
		if _i(death["side"]) == side:
			friendly += 1
	return beats if beats.size() == friendly else none


## The buffs of a group in its new order (rows, sorted), recounted: each is its unit's Attack and
## Health before the group plus every gain on that unit shown so far, so the numbers stay true and
## the last equals the log's. A gain is what its buff added in the log's own order (beats).
static func _recount(rows: Array[Array], beats: Array[Array], events: Array, upto: int) -> void:
	var stats: Dictionary = {}
	var start: Dictionary = events[0]
	var boards: Array = start.get("boards", [])
	for row: Variant in boards:
		var units: Array = row
		for value: Variant in units:
			if value is Dictionary:
				var unit: Dictionary = value
				stats[_i(unit["uid"])] = Vector2i(
					_i(unit.get("attack", 0)), _i(unit.get("health", 0))
				)
	for k: int in upto:
		var event: Dictionary = events[k]
		var uid: int = _i(event.get("uid", -1))
		if _kind_of(event) == "buff":
			stats[uid] = Vector2i(_i(event["attack"]), _i(event["health"]))
		elif _kind_of(event) == "damage" and stats.has(uid):
			var had: Vector2i = stats[uid]
			stats[uid] = Vector2i(had.x, _i(event["health"]))
	var was: Dictionary = stats.duplicate()
	var gains: Array[Vector2i] = []
	for beat: Array in beats:
		var gain: Vector2i = Vector2i.ZERO
		for value: Variant in beat:
			var event: Dictionary = value
			if _kind_of(event) == "buff":
				var uid: int = _i(event["uid"])
				var now: Vector2i = Vector2i(_i(event["attack"]), _i(event["health"]))
				var before: Vector2i = was.get(uid, Vector2i.ZERO)
				gain += now - before
				was[uid] = now
		gains.append(gain)
	for row: Array in rows:
		if _i(row[1]) != 1:
			continue
		var part: Array = row[3]
		for value: Variant in part:
			var event: Dictionary = value
			if _kind_of(event) != "buff":
				continue
			var uid: int = _i(event["uid"])
			var had: Vector2i = stats.get(uid, Vector2i.ZERO)
			var now: Vector2i = had + gains[_i(row[2])]
			stats[uid] = now
			event["attack"] = now.x
			event["health"] = now.y


static func _at(events: Array, k: int) -> Dictionary:
	var event: Dictionary = events[k]
	return event


static func _kind_at(events: Array, k: int) -> String:
	return _kind_of(_at(events, k))


static func _kind_of(event: Dictionary) -> String:
	return str(event.get("type", ""))


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)
