extends "res://tests/screens/feel/fight_compare/best_timeline.gd"
## CB14, how a stat gain shows (docs/workstreams/fight-animation-24-nov/buff-look/DESIGN.md,
## section 2), on top of the best proposal's schedule (best_timeline.gd): every gain beat (a
## trigger whose effect is a buff) is scheduled by DESIGN.md's beats instead of the proposal's.
## "a" swell and count: only the changed disc swells to x2.0 and its digits count up. "b" running
## total: A plus a "+N" tag over each changed disc, adding up over repeats. "c" carried total: B,
## with each tag flying from its cause (the dead unit's empty slot) into the disc. "none" (or no
## CB14): the proposal as it is. The schedule is all here, by frame; buff_screen.gd draws it.
## Stand-ins (the owner approved filming B and C with them, 24 Nov): the tag is the recruit
## screen's green gain pill, its flight the recruit's arc, the disc's flare the recruit's amber
## ring (src/screens/recruit/recruit_turn_start.gd). Exploratory: nothing here reaches the game,
## and no one has watched it move.

const Tokens := preload("res://tests/screens/feel/fight_compare/pilot_tokens.gd")

const BUFF_OPTIONS: Array[String] = ["a", "b", "c"]
## A run of gains: the first gap, how each shrinks, its floor (DESIGN.md: the best proposal's
## beat, 18 f to the next, combo gaps x0.75, floor 5 f; each gap rounded: 18, 14, 10, 8, 6).
const GAP_FIRST: float = 18.0
const GAP_SHRINK: float = 0.75
const GAP_FLOOR: int = 5
## A and B: the gain lands this many frames into its beat (to itself: no jab), else after the jab.
const LAND_SELF: int = 6
const LAND_OTHER: int = 12
## C: the tag is born this many frames into a beat with a living cause (a giver, or a gain to
## itself), and flies FLY frames (a gain to itself rises RISE frames). A gain caused by a death is
## born at its beat's start, at the dead unit's empty slot (its fall has ended).
const BORN_AT: int = 4
const FLY: int = 10
const RISE: int = 8
## The changed disc: x2.0 at L, held 3 f, back to x1.0 by L+14 (pop.emphasis); digits count over
## 8 f from L.
const SWELL: float = 2.0
const SWELL_HOLD: int = 3
const SWELL_BACK: int = 14
const COUNT: int = 8
## B: the tag appears at L-2 at x0.5, x1.25 at L+2, x1.0 by L+6. Each later gain re-pops it from
## x1.35 to x1.0 over 6 f with the running total. It sinks from the last L+30 (0.1 h down, to
## x0.4, fading) over 6 f.
const TAG_EARLY: int = 2
const TAG_START: float = 0.5
const TAG_PEAK: float = 1.25
const TAG_PEAK_AT: int = 2
const TAG_SETTLE: int = 6
const TAG_REPOP: float = 1.35
const TAG_HOLD: int = 30
const TAG_SINK: int = 6
const SINK_PX: float = 0.1 * H
const SINK_SCALE: float = 0.4
## The tag's centre stands this far above the top of its disc (at rest).
const TAG_ABOVE: float = 38.0
## C: born at x0.5, x0.9 after 3 f, x1.0 as it lands; a low arc at most 0.15 h high.
const BORN_SCALE: float = 0.5
const BORN_GROWN: float = 0.9
const BORN_FRAMES: int = 3
const ARC_LIFT: float = 0.15 * H
## C: the disc's flare (the recruit's amber ring) lasts 8 f from L.
const FLARE: int = 8
## B and C: the source's light ends this long after its tally is gone.
const LIGHT_PAST: int = 2

## Every gain, by landing: {key, uid, run, k, stats: {attack: [from, to, delta], ...}, land,
## born, fly, cause: {uid, side, slot} or {}, source, total: Vector2i}.
var gains: Array[Dictionary] = []
## Every run's tally per target (B and C): {key, run, appear, lands, totals, sink, gone, stats}.
var tallies: Array[Dictionary] = []
## Every run: {run, source, start, lands, end, light_to}.
var runs: Array[Dictionary] = []

## The latest death item's units, in the log's order: [{uid, side, slot}], and how many of them
## a gain has taken as its cause.
var _causes: Array[Dictionary] = []
var _taken: int = 0
## While a staggered group (CB8) plays, its gains' rows, shown in one tally per card.
var _grouping: bool = false
var _group_rows: Array[Dictionary] = []
var _run_count: int = 0


## The CB14 option this film plays ("none": the proposal as it is).
func buff_option() -> String:
	var picked: String = str(options.get("CB14", "none"))
	return picked if picked in BUFF_OPTIONS else "none"


func report() -> Dictionary:
	var out: Dictionary = super()
	var chosen: Dictionary = out["options"]
	chosen["CB14"] = buff_option()
	out["buffs"] = {"gains": _gains_report(), "tallies": tallies, "runs": runs}
	return out


## The gap after the k-th gain of a run (0: after the first), rounded per gap.
static func gap_after(k: int) -> int:
	return maxi(GAP_FLOOR, roundi(GAP_FIRST * pow(GAP_SHRINK, k)))


## The k-th gain's beat start, frames after the run's first.
static func start_of(k: int) -> int:
	var at: int = 0
	for j: int in k:
		at += gap_after(j)
	return at


# ---- scheduling ----


func _fall(item: Dictionary, at: int, length: int) -> void:
	_causes = []
	_taken = 0
	for value: Variant in item["events"]:
		var event: Dictionary = _events[_i(value)]
		_causes.append(
			{"uid": _i(event["uid"]), "side": _i(event["side"]), "slot": _i(event["slot"])}
		)
	super(item, at, length)


func _combo(run: Array[Dictionary], start: int, from: int) -> Dictionary:
	if buff_option() != "none" and _is_gain(run[0]):
		return _gains(run, start)
	return super(run, start, from)


func _item(item: Dictionary, start: int, tempo: float) -> Dictionary:
	if buff_option() != "none" and _is_gain(item):
		var one: Array[Dictionary] = [item]
		return _gains(one, start)
	return super(item, start, tempo)


static func _is_gain(item: Dictionary) -> bool:
	return str(item.get("kind", "")) == "beat" and str(item.get("effect", "")) == "buff"


## A run of gain beats (one or more) by DESIGN.md's beats, from `start`, without rule 7's
## speed-up (DESIGN.md's frames have none). Returns {land, next, end, damage}.
func _gains(run: Array[Dictionary], start: int) -> Dictionary:
	var option: String = buff_option()
	var source: int = _i(run[0]["source"])
	var alive: bool = source >= 0 and _where.has(source) and not _dead.has(source)
	var lands: Array[int] = []
	var all_self: bool = true
	var run_id: int = _run_count
	var rows: Array[Dictionary] = []
	for k: int in run.size():
		var item: Dictionary = run[k]
		var targets: Array = item["targets"]
		var to_self: bool = targets.is_empty() or (targets.size() == 1 and _i(targets[0]) == source)
		all_self = all_self and to_self
		var s: int = start + start_of(k)
		var cause: Dictionary = _next_cause(item)
		var born: int = -1
		var fly: int = 0
		var land: int = s + (LAND_SELF if to_self else LAND_OTHER)
		if option == "c":
			if not cause.is_empty():
				born = s
				fly = FLY
			else:
				born = s + BORN_AT
				fly = RISE if to_self else FLY
			land = born + fly
		if alive and not to_self:
			if option == "c":
				# C: the tag's flight replaces the jab; the giver still pulses
				_add(
					_key(source),
					{
						"kind": "pulse",
						"from": s,
						"land": land,
						"lift": _up(source) * PULSE_PX,
						"jab": Vector2.ZERO
					}
				)
			else:
				_pulse(item, s, land)
		lands.append(land)
		if _commit:
			_reveal_all(item, land)
			# each row joins `gains` at once: the next gain's count carries on from it
			var made: Array[Dictionary] = _gain_rows(item, run_id, k, s, land, born, fly, cause)
			gains.append_array(made)
			rows.append_array(made)
	var last: int = lands.max()
	var settle: int = last + SWELL_BACK
	var gone: int = last + TAG_HOLD + TAG_SINK
	# the queue goes on once the discs settle: a tally's tail runs under what plays next
	# (DESIGN.md: "The next beat starts at f20, under the tag's tail")
	var end: int = settle
	var light_to: int = settle if option == "a" else gone + LIGHT_PAST
	if alive and all_self:
		# a gain to itself: the source lights once and stays lit through the run
		_add(
			_key(source),
			{
				"kind": "pulse",
				"from": start,
				"land": last,
				"lift": _up(source) * PULSE_PX,
				"jab": Vector2.ZERO
			}
		)
	if alive and _commit:
		glows.append({"key": _key(source), "from": start, "to": light_to})
	if _commit:
		_run_count += 1
		(
			runs
			. append(
				{
					"run": run_id,
					"source": _key(source),
					"start": start,
					"lands": lands.duplicate(),
					"end": end,
					"light_to": light_to,
				}
			)
		)
		if option != "a" and _grouping:
			_group_rows.append_array(rows)
		elif option != "a":
			_tally(rows, run_id, last)
	return {"land": last, "next": last + BEAT_GAP, "end": end, "damage": false}


## A staggered group's gains add up in one tally per card (CB14 c: "adds up").
func _stagger_open() -> void:
	_grouping = true
	_group_rows = []


func _stagger_close(lands: Array[int]) -> void:
	_grouping = false
	if _commit and not _group_rows.is_empty():
		_tally(_group_rows, _i(_group_rows[0]["run"]), _i(lands.max()))


## The next cause for a gain: the death it is for when the group named one (a staggered beat's
## `stagger_cause`), else the latest death item's next unit on the gain's source's side (the
## k-th gain after a group of deaths is that side's k-th death in the log), or {}.
func _next_cause(item: Dictionary) -> Dictionary:
	var listed: Array = item["events"]
	var trigger: Dictionary = _at(_events, _i(listed[0]))
	if trigger.has("stagger_cause"):
		var dead: int = _i(trigger["stagger_cause"])
		for value: Variant in _events:
			var event: Dictionary = value
			if _kind_of(event) == "death" and _i(event.get("uid", -1)) == dead:
				return {"uid": dead, "side": _i(event["side"]), "slot": _i(event["slot"])}
	var source: int = _i(item["source"])
	if not _where.has(source):
		return {}
	var side: int = _i(_where[source][0])
	var seen: int = 0
	for cause: Dictionary in _causes:
		if _i(cause["side"]) != side or _i(cause["uid"]) == source:
			continue
		if seen == _taken:
			_taken += 1
			return cause
		seen += 1
	return {}


## One row per changed unit in a gain beat: what each stat counts from and to.
func _gain_rows(
	item: Dictionary, run_id: int, k: int, s: int, land: int, born: int, fly: int, cause: Dictionary
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for value: Variant in item["events"]:
		var i: int = _i(value)
		if _kind(i) != "buff":
			continue
		var event: Dictionary = _events[i]
		var uid: int = _i(event["uid"])
		var after: Vector2i = Vector2i(_i(event["attack"]), _i(event["health"]))
		var before: Vector2i = _shown_before(i, uid, after)
		var key: String = _key(uid)
		var stats: Dictionary = {}
		var delta: Vector2i = after - before
		for stat: String in ["attack", "health"]:
			var d: int = delta.x if stat == "attack" else delta.y
			if d == 0:
				continue
			var was: int = before.x if stat == "attack" else before.y
			var now: int = after.x if stat == "attack" else after.y
			stats[stat] = [_count_from(key, stat, land, was), now, d]
		if stats.is_empty():
			continue
		(
			out
			. append(
				{
					"key": key,
					"uid": uid,
					"run": run_id,
					"k": k,
					"start": s,
					"land": land,
					"born": born,
					"fly": fly,
					"cause": cause,
					"source": _key(_i(item["source"])),
					"stats": stats,
				}
			)
		)
	return out


## A unit's Attack and Health just before log event i, from the log itself: the start boards (or
## its summon), then every buff (its new numbers) and damage (the Health left) on it.
func _shown_before(i: int, uid: int, fallback: Vector2i) -> Vector2i:
	var stats: Vector2i = Vector2i(-1, -1)
	var start: Dictionary = _events[0]
	for row: Variant in start.get("boards", []):
		var units: Array = row
		for unit: Variant in units:
			if not unit is Dictionary:
				continue
			var held: Dictionary = unit
			if _i(held.get("uid", -1)) == uid:
				stats = Vector2i(_i(held.get("attack", 0)), _i(held.get("health", 0)))
	for j: int in range(1, i):
		var event: Dictionary = _events[j]
		if _i(event.get("uid", -1)) != uid:
			continue
		match _kind(j):
			"buff", "summon":
				stats = Vector2i(_i(event.get("attack", stats.x)), _i(event.get("health", stats.y)))
			"damage":
				stats.y = _i(event.get("health", stats.y))
	return fallback if stats.x < 0 else stats


## Where a stat's count starts at `land`: what the last gain on it shows then while it is still
## counting (its count carries on), else the number before this gain.
func _count_from(key: String, stat: String, land: int, was: int) -> int:
	for j: int in range(gains.size() - 1, -1, -1):
		var gain: Dictionary = gains[j]
		var stats: Dictionary = gain["stats"]
		if str(gain["key"]) != key or not stats.has(stat) or _i(gain["land"]) > land:
			continue
		var age: int = land - _i(gain["land"])
		if age >= COUNT:
			return was
		var counted: Array = stats[stat]
		return Tokens.roll(_i(counted[0]), _i(counted[1]), age, COUNT)
	return was


## B and C: one tally per target and run, showing the running total of each stat changed.
func _tally(rows: Array[Dictionary], run_id: int, last: int) -> void:
	var keys: Array[String] = []
	for row: Dictionary in rows:
		if not keys.has(str(row["key"])):
			keys.append(str(row["key"]))
	for key: String in keys:
		var lands: Array[int] = []
		var totals: Array = []
		var sum: Dictionary = {"attack": 0, "health": 0}
		var changed: Dictionary = {}
		for row: Dictionary in rows:
			if str(row["key"]) != key:
				continue
			var stats: Dictionary = row["stats"]
			for stat: String in stats:
				var counted: Array = stats[stat]
				sum[stat] = _i(sum[stat]) + _i(counted[2])
				changed[stat] = true
			lands.append(_i(row["land"]))
			totals.append(sum.duplicate())
		var appear: int = lands[0] - (TAG_EARLY if buff_option() == "b" else 0)
		(
			tallies
			. append(
				{
					"key": key,
					"run": run_id,
					"appear": appear,
					"lands": lands,
					"totals": totals,
					"sink": last + TAG_HOLD,
					"gone": last + TAG_HOLD + TAG_SINK,
					"stats": changed.keys(),
				}
			)
		)


func _up(uid: int) -> Vector2:
	var where: Array = _where[uid]
	return Vector2.UP if _i(where[0]) == 0 else Vector2.DOWN


# ---- what shows at a frame (buff_screen.gd draws it; clips measure the log of it) ----


## A changed disc at frame n: {scale, value, green} while it swells or counts, else {}.
func disc_at(key: String, stat: String, n: float) -> Dictionary:
	for j: int in range(gains.size() - 1, -1, -1):
		var gain: Dictionary = gains[j]
		var stats: Dictionary = gain["stats"]
		if str(gain["key"]) != key or not stats.has(stat) or _i(gain["land"]) > n:
			continue
		var age: float = n - _i(gain["land"])
		if age >= SWELL_BACK:
			return {}
		var size: float = SWELL
		if age >= SWELL_HOLD:
			var p: float = float(age - SWELL_HOLD) / (SWELL_BACK - SWELL_HOLD)
			size = lerpf(SWELL, 1.0, Tokens.enter(p))
		var counted: Array = stats[stat]
		return {
			"scale": size,
			"value": Tokens.roll(_i(counted[0]), _i(counted[1]), floori(age), COUNT),
			"to": _i(counted[1]),
		}
	return {}


## The keys with a gain landing, swelling or counting at frame n.
func swelling(n: float) -> Array[String]:
	var out: Array[String] = []
	for gain: Dictionary in gains:
		var age: float = n - _i(gain["land"])
		if age >= 0 and age < SWELL_BACK and not out.has(str(gain["key"])):
			out.append(str(gain["key"]))
	return out


## Every tally tag at frame n: [{key, run, stat, text, scale, alpha, drop}].
func tags_at(n: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for tally: Dictionary in tallies:
		if n < _i(tally["appear"]) or n >= _i(tally["gone"]):
			continue
		var lands: Array = tally["lands"]
		var totals: Array = tally["totals"]
		var k: int = 0
		for j: int in lands.size():
			if _i(lands[j]) <= n:
				k = j
		var size: float = 1.0
		var first: int = _i(lands[0])
		var age: float = n - _i(lands[k])
		if buff_option() == "b" and n < first + TAG_SETTLE:
			# B's first: x0.5 at L-2, x1.25 at L+2, x1.0 by L+6
			if n < first + TAG_PEAK_AT:
				var up: float = float(n - (first - TAG_EARLY)) / (TAG_EARLY + TAG_PEAK_AT)
				size = lerpf(TAG_START, TAG_PEAK, Tokens.enter(up))
			else:
				var down: float = float(n - first - TAG_PEAK_AT) / (TAG_SETTLE - TAG_PEAK_AT)
				size = lerpf(TAG_PEAK, 1.0, Tokens.enter(down))
		elif age < TAG_SETTLE and (k > 0 or buff_option() == "c"):
			size = lerpf(TAG_REPOP, 1.0, Tokens.enter(float(age) / TAG_SETTLE))
		var alpha: float = 1.0
		var drop: float = 0.0
		var sink: int = _i(tally["sink"])
		if n >= sink:
			var p: float = Tokens.exit(float(n - sink) / TAG_SINK)
			drop = SINK_PX * p
			size *= lerpf(1.0, SINK_SCALE, p)
			alpha = 1.0 - p
		var total: Dictionary = totals[k]
		for stat: Variant in tally["stats"]:
			(
				out
				. append(
					{
						"key": tally["key"],
						"run": tally["run"],
						"stat": str(stat),
						"text": "+%d" % _i(total[stat]),
						"scale": size,
						"alpha": alpha,
						"drop": drop,
					}
				)
			)
	return out


## C: every tag in flight at frame n: [{gain, key, stat, text, cause, mix, scale, alpha}]. mix
## is the share of the way travelled (the recruit's arrive curve: off gently, in at speed).
func flights_at(n: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if buff_option() != "c":
		return out
	for j: int in gains.size():
		var gain: Dictionary = gains[j]
		var born: int = _i(gain["born"])
		if born < 0 or n < born or n >= _i(gain["land"]):
			continue
		var age: float = n - born
		var t: float = float(age) / _i(gain["fly"])
		var mix: float = RecruitTurnStart._arrive(t)
		var size: float = lerpf(BORN_GROWN, 1.0, mix)
		if age < BORN_FRAMES:
			size = lerpf(BORN_SCALE, BORN_GROWN, Tokens.enter(float(age) / BORN_FRAMES))
		var stats: Dictionary = gain["stats"]
		for stat: String in stats:
			var counted: Array = stats[stat]
			(
				out
				. append(
					{
						"gain": j,
						"key": gain["key"],
						"stat": stat,
						"text": "+%d" % _i(counted[2]),
						"cause": gain["cause"],
						"source": gain["source"],
						"mix": mix,
						"scale": size,
						"alpha": minf(1.0, float(age + 1) / BORN_FRAMES),
					}
				)
			)
	return out


## C: every disc flaring at frame n: [{gain, key, stat, age}].
func flares_at(n: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if buff_option() != "c":
		return out
	for j: int in gains.size():
		var gain: Dictionary = gains[j]
		var age: float = n - _i(gain["land"])
		if age < 0 or age >= FLARE:
			continue
		var stats: Dictionary = gain["stats"]
		for stat: String in stats:
			out.append({"gain": j, "key": gain["key"], "stat": stat, "age": age})
	return out


func _gains_report() -> Array:
	var out: Array = []
	for gain: Dictionary in gains:
		var row: Dictionary = gain.duplicate(true)
		out.append(row)
	return out
