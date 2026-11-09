class_name Pass3Combat
extends RefCounted
## Pass 3's optional timing rule. The legacy path consumes exactly the same random values.


static func enabled(combat: Combat) -> bool:
	var explicit: Variant = combat.config.get_value("pass3_start_order")
	if explicit != null:
		return CoreUtil.to_bool(explicit)
	return has_content(combat)


static func has_content(combat: Combat) -> bool:
	if combat.config.get_bool("pass3_content"):
		return true
	if not combat.notes.has("pass3_pool_content"):
		var found: bool = false
		for card: Dictionary in combat.library.pool_units(combat.config.card_set()):
			var entries: Array = card.get("mechanics", [])
			for entry: Dictionary in entries:
				found = found or str(entry.get("id", "")) in ["pass3_bird", "pass3_fairy"]
		combat.notes["pass3_pool_content"] = found
	if CoreUtil.to_bool(combat.notes["pass3_pool_content"]):
		return true
	for side: int in 2:
		var rules: Dictionary = combat.side_rules[side]
		if rules.get("pass3_content", false):
			return true
		for unit: CombatUnit in combat.units_of(side):
			if unit.has_mechanic("pass3_bird") or unit.has_mechanic("pass3_fairy"):
				return true
	return false


static func is_biggest_enemy(id: String, params: Dictionary) -> bool:
	if id == "scale_answer":
		return true
	if id != "effect":
		return false
	if str(params.get("trigger", "")) != "start_of_combat":
		return false
	if biggest_selector(params.get("target", {})):
		return true
	for step: Dictionary in MechanicRegistry.steps_of(params):
		if biggest_selector(step.get("target", {})):
			return true
	return false


static func biggest_selector(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var target: Dictionary = value
	return str(target.get("select", "")) == "enemies" and str(target.get("pick", "")) == "biggest"


## Hob waits for both sides' copies, then biggest-enemy answers see the settled boards.
static func start(combat: Combat, first: int) -> void:
	var queues: Array = [combat.units_of(first), combat.units_of(1 - first)]
	var late: Array = []
	var holders: Array = []
	for queue: Array in queues:
		for unit: CombatUnit in queue:
			if not unit.on_board or combat._halted:
				continue
			for index: int in unit.scripts.size():
				var invocation: Array = [unit, index]
				if is_biggest_enemy(unit.mechanic_ids[index], unit.params[index]):
					late.append(invocation)
				elif Pass3FairyCombat.ability(unit, index) == "hob":
					holders.append(invocation)
				else:
					_invoke(combat, invocation, false)
			combat._resolve_deaths(unit.side)
			combat.reactions.drain(combat)
	var copied_holders: Array = combat.notes.get("pass3_copied_holders", [])
	var copied_late: Array = combat.notes.get("pass3_copied_late", [])
	holders.append_array(copied_holders)
	late.append_array(copied_late)
	for invocation: Array in holders:
		_invoke(combat, invocation)
	for invocation: Array in combat.notes.get("pass3_hero_late", []):
		var side: int = invocation[0]
		var entry: Dictionary = invocation[1]
		EffectRunner.run(entry, CombatWorld.make(combat, null, side, entry, "start_of_combat"))
		combat._resolve_deaths(side)
		combat.reactions.drain(combat)
	# The Lantern before Jenny is stable inside the deferred step. Neither today's Lantern nor
	# Jenny picks biggest; this also accommodates future data effects retaining those identities.
	for priority: int in 3:
		for invocation: Array in late:
			var source: CombatUnit = invocation[0]
			if _priority(source) == priority:
				_invoke(combat, invocation)


static func heroes(combat: Combat, first: int) -> void:
	var late: Array = []
	for side: int in [first, 1 - first]:
		var entries: Array = combat.hero_effects[side]
		for entry: Dictionary in entries:
			if str(entry.get("trigger", "")) != HeroRules.START_OF_COMBAT:
				continue
			if is_biggest_enemy("effect", entry):
				late.append([side, entry])
			else:
				EffectRunner.run(
					entry, CombatWorld.make(combat, null, side, entry, "start_of_combat")
				)
		combat._resolve_deaths(side)
		combat.reactions.drain(combat)
	combat.notes["pass3_hero_late"] = late


static func _priority(unit: CombatUnit) -> int:
	if unit.def_id() == "lantern_man":
		return 0
	if unit.def_id() == "jenny_greenteeth":
		return 2
	return 1


static func _invoke(combat: Combat, invocation: Array, resolve: bool = true) -> void:
	var unit: CombatUnit = invocation[0]
	var index: int = invocation[1]
	if not unit.on_board or combat._halted or index >= unit.scripts.size():
		return
	unit.scripts[index].on_start_of_combat(combat, unit, unit.params[index])
	if resolve:
		combat._resolve_deaths(unit.side)
		combat.reactions.drain(combat)


## Most Attack plus Health, with reading-order ties and no random draw.
static func biggest(units: Array[CombatUnit], count: int = 1) -> Array[CombatUnit]:
	var ordered: Array[CombatUnit] = units.duplicate()
	# Stable insertion preserves reading order, including held units immediately after holder.
	for index: int in range(1, ordered.size()):
		var item: CombatUnit = ordered[index]
		var at: int = index
		while at > 0 and _size(item) > _size(ordered[at - 1]):
			ordered[at] = ordered[at - 1]
			at -= 1
		ordered[at] = item
	if ordered.size() > count:
		ordered.resize(count)
	return ordered


static func _size(unit: CombatUnit) -> int:
	return unit.attack + unit.health


static func tribe(
	combat: Combat, side: int, name: String, other: CombatUnit = null
) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for unit: CombatUnit in combat.units_of(side):
		if unit != other and unit.has_tribe(name) and not unit.is_dead():
			out.append(unit)
	return out


## Held specs become private fighters lazily, so answers can alter the exact unit that emerges.
## No recruit snapshot is mutated. Mid-fight prisoners already have fighter identities.
static func enemies(combat: Combat, side: int) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for unit: CombatUnit in combat.units_of(1 - side):
		out.append(unit)
		_append_inside(combat, unit, out)
	var enemies_only: Array[CombatUnit] = []
	for unit: CombatUnit in out:
		if unit.side != side:
			enemies_only.append(unit)
	return enemies_only


static func _append_inside(combat: Combat, holder: CombatUnit, out: Array[CombatUnit]) -> void:
	for index: int in holder.held_specs.size():
		var spec: Dictionary = holder.held_specs[index]
		var fighter: CombatUnit = spec.get("_pass3_fighter")
		if fighter == null:
			var definition: Dictionary = combat.library.get_unit(str(spec["def_id"]))
			if definition.is_empty():
				continue
			fighter = CombatUnit.make(definition, spec, combat._next_uid, holder.side)
			combat._next_uid += 1
			fighter.slot = holder.slot
			fighter.on_board = false
			spec = spec.duplicate(true)
			spec["_pass3_fighter"] = fighter
			holder.held_specs[index] = spec
		out.append(fighter)
		_append_inside(combat, fighter, out)
	for fighter: CombatUnit in holder.inside:
		out.append(fighter)
		_append_inside(combat, fighter, out)


static func buff_hidden(
	combat: Combat, target: CombatUnit, attack: int, health: int, source: CombatUnit
) -> void:
	var old_attack: int = target.attack
	var old_health: int = target.health
	target.add_combat(attack, health)
	CombatMoves.emit_stats(
		combat, target, target.attack - old_attack, target.health - old_health, source
	)


## Presentation follows the same transfer as the scripts; Belly is retained on the victim.
static func take_words(thief: CombatUnit, victim: CombatUnit) -> Dictionary:
	var thief_view: Dictionary = thief.view()
	var victim_view: Dictionary = victim.view()
	var taken: String = str(victim_view["text"])
	var remaining: String = ""
	var remaining_keywords: Array = []
	var belly: int = victim.mechanic_ids.find(HeldUnits.BELLY)
	if belly >= 0:
		remaining = "Belly %d." % CoreUtil.to_int(victim.params[belly].get("size", 0))
		taken = taken.trim_prefix(remaining).strip_edges()
		remaining_keywords.append("Belly")
	var keywords: Array = thief_view["keywords"]
	for keyword: String in victim_view["keywords"]:
		if keyword != "Belly" and not keywords.has(keyword):
			keywords.append(keyword)
	thief.has_text_override = true
	thief.text_override = (str(thief_view["text"]) + " " + taken).strip_edges()
	thief.keywords_override = keywords
	victim.has_text_override = true
	victim.text_override = remaining
	victim.keywords_override = remaining_keywords
	return {
		"current_text": thief.text_override,
		"remaining_text": remaining,
		"current_keywords": keywords.duplicate(),
		"remaining_keywords": remaining_keywords.duplicate()
	}
