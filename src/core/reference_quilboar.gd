class_name ReferenceQuilboar
extends RefCounted
## Test-only reference. Resources are absent from exports; even an enabled saved flag cannot
## activate it in a player executable. All size values in state are integer half-stat units.

const ROOT: String = "res://content/reference/quilboar/"


static func allowed(config: GameConfig, editor_build: Variant = null) -> bool:
	var editor: bool = (
		OS.has_feature("editor") if editor_build == null else CoreUtil.to_bool(editor_build)
	)
	return editor and config.get_bool("reference_quilboar")


static func rates(config: GameConfig) -> Dictionary:
	if not allowed(config):
		return {}
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "rates.json"))
	var presets: Dictionary = data["quilboar_ref"]
	var preset: String = config.get_string("quilboar_ref_preset")
	assert(presets.has(preset) and preset != "_note", "Unknown Quilboar reference preset")
	var selected: Dictionary = presets[preset]
	var out: Dictionary = selected.duplicate(true)
	var guards: Dictionary = data["quilboar_ref_loop_guards"]
	out["loop_guards"] = guards.duplicate(true)
	return out


static func configure(library: UnitLibrary, config: GameConfig) -> void:
	if not allowed(config):
		return
	var reference_library: UnitLibrary = UnitLibrary.load_dir(ROOT + "units")
	assert(reference_library.load_errors().is_empty(), str(reference_library.load_errors()))
	var dials: Dictionary = rates(config)
	for unit: Dictionary in reference_library.all_units():
		library.register_unit(_card(unit, dials))
	for card: Dictionary in reference_library.all_cards():
		library.register_card(_card(card, dials))


static func _card(raw: Dictionary, dials: Dictionary) -> Dictionary:
	var out: Dictionary = raw.duplicate(true)
	out["quilboar_ref"] = dials.duplicate(true)
	# Modes author B half steps. C/uncut use whole steps; golden is applied at resolution.
	for mode: Dictionary in out.get("modes", []):
		for step: Dictionary in mode.get("effects", []):
			if str(step.get("effect", "")) == "gem_size_add":
				var scale: int = roundi(CoreUtil.to_float(dials["gem_size_step"]) * 2.0)
				step["attack"] = CoreUtil.to_int(step.get("attack", 0)) * scale
				step["health"] = CoreUtil.to_int(step.get("health", 0)) * scale
			if str(out["id"]) == "qb_veteran_brigand" and str(step.get("effect")) == "gem":
				step["count"] = CoreUtil.to_int(dials["brigand_gems"])
	return out


static func setup(rules: RecruitRules, player: PlayerState) -> void:
	player.reference_quilboar = allowed(rules.config)
	player.quilboar_ref = rates(rules.config)


static func gem_size_add(player: PlayerState, attack: int, health: int) -> void:
	player.gem_attack_halves += attack
	player.gem_health_halves += health
	player.log_event(
		"gem_size",
		{"attack_halves": player.gem_attack_halves, "health_halves": player.gem_health_halves}
	)


static func on_recruit(ctx: RecruitContext, params: Dictionary) -> void:
	if not ctx.player.reference_quilboar:
		return
	var factor: int = CoreUtil.to_int(params.get("factor", 1))
	var kind: String = str(params.get("kind", ""))
	if ctx.trigger == "on_play" and ctx.subject == ctx.source:
		match kind:
			"razorfen_geomancer":
				ctx.add_card("qb_blood_gem", 2 * factor, false)
			"sanguine_champion":
				var step: int = roundi(
					CoreUtil.to_float(ctx.player.quilboar_ref["gem_size_step"]) * 2
				)
				gem_size_add(ctx.player, step * 2 * factor, step * factor)
	if ctx.trigger == "end_of_turn":
		match kind:
			"gem_rat":
				ctx.add_card("qb_gem_day", factor, false)
			"trench_fighter":
				ctx.add_card("qb_gem_confiscation", factor, false)
	if ctx.trigger == "on_choose_one_played" and kind == "turbo_hogrider":
		var dials: Dictionary = ctx.player.quilboar_ref
		var count: int = CoreUtil.to_int(ctx.source.counters.get("qb_choose_count", 0)) + 1
		var every: int = maxi(1, CoreUtil.to_int(dials["hogrider_every"]))
		ctx.source.counters["qb_choose_count"] = count % every
		if count < every:
			return
		for target: RecruitUnit in ctx.player.board:
			if target != null and target.has_tribe("quilboar"):
				if target == ctx.source and str(dials["hogrider_targets"]) != "all_quilboar":
					continue
				ctx.gem(target, CoreUtil.to_int(dials["hogrider_gems"]) * factor)


static func random_card(
	library: UnitLibrary, spec: Dictionary, tier: int, rng: RandomNumberGenerator
) -> String:
	var eligible: PackedStringArray = []
	var top: int = tier if str(spec.get("tier_at_most", "")) in ["tier", "yours"] else 6
	if spec.has("tier_at_most") and typeof(spec["tier_at_most"]) != TYPE_STRING:
		top = CoreUtil.to_int(spec["tier_at_most"])
	for unit: Dictionary in library.all_units():
		if not str(unit["id"]).begins_with("qb_") or not unit.get("pool", false):
			continue
		if CoreUtil.to_int(unit["tier"]) > top:
			continue
		var tags: Array = unit.get("tags", [])
		if spec.has("tag") and not tags.has(spec["tag"]):
			continue
		var tribes: Array = unit["tribes"]
		if spec.has("tribe") and not tribes.has(spec["tribe"]):
			continue
		eligible.append(str(unit["id"]))
	return "" if eligible.is_empty() else eligible[rng.randi_range(0, eligible.size() - 1)]


static func steal_gems(ctx: RecruitContext) -> void:
	if ctx.chosen == null:
		return
	var target: BoardUnit = ctx.chosen
	var slot: int = ctx.player.board.find(target)
	if slot < 0:
		return
	for neighbour: int in BoardGeometry.adjacent(slot):
		var donor: RecruitUnit = ctx.player.board[neighbour]
		if donor == null:
			continue
		var attack: int = donor.gem_attack
		var health: int = donor.gem_health
		var temp_attack: int = donor.combat_gem_attack
		var temp_health: int = donor.combat_gem_health
		ctx.buff(donor, -attack, -health, "permanent")
		ctx.buff(donor, -temp_attack, -temp_health, "combat")
		donor.gem_attack = 0
		donor.gem_health = 0
		donor.combat_gem_attack = 0
		donor.combat_gem_health = 0
		# Transfer the layer, preserving its duration and accounting only accepted gains (Shy).
		ctx.gem_transfer(target, attack, health, false)
		ctx.gem_transfer(target, temp_attack, temp_health, true)
