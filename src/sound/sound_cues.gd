class_name SoundCues
extends RefCounted
## Turns a fight screen step into the cues it sounds, by the rules in Neon's table
## (assets/audio/cues.json, docs/workstreams/sound/audio-spec.md). It reads only the steps the
## screen shows, never the rules core, so sound can't change a fight.
## Each cue asked for is {cue, delay_s, gain_db}; SoundPlayer picks the take and plays it.


## The cues of one FightReplay step ({state, hold, kind}); before is the step shown just before it
## ({} for the first), to tell which units died. table: cues.json as parsed.
static func for_fight_step(
	step: Dictionary, table: Dictionary, before: Dictionary = {}
) -> Array[Dictionary]:
	var state: Dictionary = CoreUtil.to_dict(step.get("state", {}))
	var moment: Dictionary = CoreUtil.to_dict(state.get("moment", {}))
	match str(step.get("kind", "")):
		"splash":
			return _hits(moment, table)
		"death":
			return _deaths(_dead(before, state), table)
		"summon":
			return [_cue("fight.summon", 0.0, 0.0)]
		"trigger":
			return [_cue("fight.trigger", 0.0, 0.0)]
	var out: Array[Dictionary] = []
	var shown: Dictionary = CoreUtil.to_dict(
		CoreUtil.to_dict(before.get("state", {})).get("moment", {})
	)
	if moment.has("result") and not shown.has("result"):
		var winner: int = CoreUtil.to_int(CoreUtil.to_dict(moment["result"]).get("winner", -1))
		var cue: String = "fight.tie"
		if winner >= 0:
			cue = (
				"fight.win" if winner == CoreUtil.to_int(state.get("you_side", 0)) else "fight.lose"
			)
		out.append(_cue(cue, 0.0, 0.0))
	return out


## The cues of one moment of a fight's schedule (FightTimeline cues), by the same rules as the
## steps': {kind: "hit", splashes} (the bursts showing on one frame), {kind: "death", count} (the
## units starting to fall on one frame), {kind: "summon"}, {kind: "trigger"} (a source pulses),
## {kind: "result", winner, you_side}.
static func for_fight_cue(cue: Dictionary, table: Dictionary) -> Array[Dictionary]:
	match str(cue.get("kind", "")):
		"hit":
			return _hits({"splashes": cue.get("splashes", [])}, table)
		"death":
			return _deaths(CoreUtil.to_int(cue.get("count", 0)), table)
		"summon":
			return [_cue("fight.summon", 0.0, 0.0)]
		"trigger":
			return [_cue("fight.trigger", 0.0, 0.0)]
		"result":
			var winner: int = CoreUtil.to_int(cue.get("winner", -1))
			var named: String = "fight.tie"
			if winner >= 0:
				named = (
					"fight.win"
					if winner == CoreUtil.to_int(cue.get("you_side", 0))
					else "fight.lose"
				)
			return [_cue(named, 0.0, 0.0)]
	var none: Array[Dictionary] = []
	return none


static func _hits(moment: Dictionary, table: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hits: Array[int] = []
	var blocked: int = 0
	for value: Variant in CoreUtil.to_array(moment.get("splashes", [])):
		var splash: Dictionary = CoreUtil.to_dict(value)
		if CoreUtil.to_bool(splash.get("blocked", false)):
			blocked += 1
		else:
			hits.append(CoreUtil.to_int(splash.get("amount", 0)))
	# heaviest first; a destroy (no number) outranks any hit
	hits.sort_custom(func(a: int, b: int) -> bool: return _rank(a) > _rank(b))
	var rules: Dictionary = CoreUtil.to_dict(table.get("simultaneous_hits", {}))
	var weights: Dictionary = CoreUtil.to_dict(table.get("hit_weights", {}))
	var cleave_min: int = CoreUtil.to_int(rules.get("cleave_min_hits", 3))
	if hits.size() >= cleave_min:
		var staggers: Array = CoreUtil.to_array(rules.get("cleave_staggers_s", [0.0]))
		var gains: Array = CoreUtil.to_array(rules.get("cleave_gains_db", [0.0]))
		var played: int = mini(
			hits.size(), mini(CoreUtil.to_int(rules.get("cleave_max_played", 3)), staggers.size())
		)
		for i: int in played:
			out.append(_cue(hit_cue(hits[i], weights), _num(staggers[i]), _gain(gains, i)))
		return out
	if not hits.is_empty():
		# one or two normal hits: the heaviest once (two at once sounded like a flam)
		out.append(_cue(hit_cue(hits[0], weights), 0.0, 0.0))
		if blocked > 0:
			var stagger: float = _num(rules.get("blocked_companion_stagger_s", 0.015))
			out.append(
				_cue("fight.hit.blocked", stagger, _num(rules.get("blocked_companion_db", -3.0)))
			)
		return out
	if blocked > 0:
		out.append(_cue("fight.hit.blocked", 0.0, 0.0))
	return out


## How many units of the step before are gone from this one's boards.
static func _dead(before: Dictionary, state: Dictionary) -> int:
	var now: Dictionary = _uids(state)
	var count: int = 0
	for uid: int in _uids(CoreUtil.to_dict(before.get("state", {}))):
		if not now.has(uid):
			count += 1
	return count


static func _uids(state: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for row: Variant in CoreUtil.to_array(state.get("boards", [])):
		for unit: Variant in CoreUtil.to_array(row):
			if unit is Dictionary:
				out[CoreUtil.to_int(CoreUtil.to_dict(unit).get("uid", -1))] = true
	return out


## One death plays once; more in one pass play a few staggered takes, never a pile.
static func _deaths(count: int, table: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if count <= 0:
		return out
	var rules: Dictionary = CoreUtil.to_dict(table.get("simultaneous_deaths", {}))
	var staggers: Array = CoreUtil.to_array(rules.get("staggers_s", [0.0]))
	var gains: Array = CoreUtil.to_array(rules.get("gains_db", [0.0]))
	var played: int = mini(
		count, mini(CoreUtil.to_int(rules.get("max_played_per_step", 2)), staggers.size())
	)
	for i: int in played:
		out.append(_cue("fight.death", _num(staggers[i]), _gain(gains, i)))
	return out


static func _rank(damage: int) -> int:
	return 1 << 30 if damage <= 0 else damage


## The hit cue for damage dealt. A destroy (a splash with no number) has its own cue.
static func hit_cue(damage: int, weights: Dictionary) -> String:
	if damage <= 0:
		return str(weights.get("destroy_cue", "fight.hit.heavy"))
	if damage <= CoreUtil.to_int(weights.get("light_max_damage", 4)):
		return "fight.hit.light"
	if damage <= CoreUtil.to_int(weights.get("medium_max_damage", 13)):
		return "fight.hit.medium"
	return "fight.hit.heavy"


static func _cue(cue: String, delay_s: float, gain_db: float) -> Dictionary:
	return {"cue": cue, "delay_s": delay_s, "gain_db": gain_db}


static func _gain(gains: Array, i: int) -> float:
	return _num(gains[i]) if i < gains.size() else 0.0


static func _num(value: Variant) -> float:
	if value is float:
		return value
	if value is int:
		return float(CoreUtil.to_int(value))
	return 0.0
