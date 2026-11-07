extends RefCounted
## Run one recruit action on isolated state so warnings use the real rules and random stream.
## The source player, pools, instance ids, logs and random streams stay untouched.


static func shy_warning(
	player: PlayerState, rules: RecruitRules, action: String, first: int, second: int
) -> String:
	var copy: PlayerState = _copy(player)
	copy.log_observer = Callable()
	copy.recruit_log.clear()
	var pool: UnitPool = _copy(rules.pool)
	var trial: RecruitRules = RecruitRules.create(rules.library, rules.config, pool)
	trial._next_iid = rules._next_iid
	trial.lobby_tribes = rules.lobby_tribes.duplicate()
	if rules.spell_pool != null:
		trial.spell_pool = _copy(rules.spell_pool)
	match action:
		"buy_play":
			if trial.buy(copy, first) == "":
				trial.play(copy, copy.hand.size() - 1, second)
		"play":
			trial.play(copy, first, second)
		"play_item":
			trial.play_item(copy, first, second)
		"move":
			trial.move(copy, first, second)
		"power":
			trial.use_power(copy, first)
		"end_turn":
			trial.end_phase(copy)
		_:
			return ""
	var names: PackedStringArray = []
	for event: Dictionary in copy.recruit_log:
		if str(event.get("type", "")) == "walk_out":
			names.append(str(event["name"]))
	if names.is_empty():
		return ""
	return "Shy: %s will walk out. Repeat the action to continue." % ", ".join(names)


## Only state objects are copied. Computed stat properties are derived from their copied layers.
static func _copy(value: Variant) -> Variant:
	if value is Array:
		var source_array: Array = value
		var out: Array = source_array.duplicate()
		for index: int in out.size():
			out[index] = _copy(out[index])
		return out
	if value is Dictionary:
		var source_dict: Dictionary = value
		var out: Dictionary = source_dict.duplicate()
		for key: Variant in out:
			out[key] = _copy(out[key])
		return out
	if value is RandomNumberGenerator:
		var original: RandomNumberGenerator = value
		var rng := RandomNumberGenerator.new()
		rng.seed = original.seed
		rng.state = original.state
		return rng
	if value is PlayerState or value is RecruitUnit or value is HandItem or value is UnitPool:
		var source: Object = value
		var script: GDScript = source.get_script()
		var out: Object = script.new()
		for property: Dictionary in source.get_property_list():
			var key: String = str(property["name"])
			if CoreUtil.to_int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
				continue
			if key in ["attack", "health", "max_health"] and source is RecruitUnit:
				continue
			out.set(key, _copy(source.get(key)))
		return out
	return value
