class_name SoundCues
extends RefCounted
## Turns a fight screen step into the cues it sounds, by the rules in Neon's table
## (assets/audio/cues.json, docs/workstreams/sound/audio-spec.md). It reads only the step the
## screen is about to show, never the rules core, so sound can't change a fight.
## Each cue asked for is {cue, delay_s, gain_db}; SoundPlayer picks the take and plays it.


## The cues of one FightReplay step ({state, hold, kind}). table: cues.json as parsed.
static func for_fight_step(step: Dictionary, table: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if str(step.get("kind", "")) != "splash":
		return out
	var state: Dictionary = CoreUtil.to_dict(step.get("state", {}))
	var moment: Dictionary = CoreUtil.to_dict(state.get("moment", {}))
	var hits: Array[int] = []
	var blocked: int = 0
	for value: Variant in CoreUtil.to_array(moment.get("splashes", [])):
		var splash: Dictionary = CoreUtil.to_dict(value)
		if CoreUtil.to_bool(splash.get("blocked", false)):
			blocked += 1
		else:
			hits.append(CoreUtil.to_int(splash.get("amount", 0)))
	hits.sort()
	hits.reverse()
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
			out.append(_cue("fight.hit.blocked", stagger, _num(rules.get("blocked_companion_db", -3.0))))
		return out
	if blocked > 0:
		out.append(_cue("fight.hit.blocked", 0.0, 0.0))
	return out


## The hit cue for damage dealt. A destroy (a splash with no number) counts as heavy.
static func hit_cue(damage: int, weights: Dictionary) -> String:
	if damage <= 0:
		return "fight.hit.heavy"
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
