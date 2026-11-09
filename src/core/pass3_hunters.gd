class_name Pass3Hunters
extends RefCounted
## Recruit-side inheritance and fixed, prey-labelled trophies. Combat owns their snapshots.


static func entries(unit: RecruitUnit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if compiled.id == "pass3_hunter":
			out.append(compiled.params_for(unit.golden))
	for group: Array in [unit.grants, unit.borrowed_text()]:
		for grant: Dictionary in group:
			var entry: Dictionary = grant["entry"]
			if str(entry.get("id", "")) == "pass3_hunter":
				out.append(
					MechanicRegistry.params_for(entry, CoreUtil.to_bool(grant.get("golden", false)))
				)
	return out


static func factor(unit: RecruitUnit, ability: String) -> int:
	var best: int = 0
	for entry: Dictionary in entries(unit):
		if str(entry.get("ability", "")) == ability:
			best = maxi(best, CoreUtil.to_int(entry.get("factor", 1)))
	return best


static func recruit_hook(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_sell" or str(ctx.params.get("ability", "")) != "young_brock":
		return
	var sold: RecruitUnit = ctx.subject as RecruitUnit
	var heir: RecruitUnit = ctx.source as RecruitUnit
	if sold == null or heir == null or sold == heir or not sold.has_tribe("Hunters"):
		return
	var reach: Array[int] = (
		BoardGeometry.neighbours(ctx.source_slot)
		if factor(heir, "young_brock") > 1
		else BoardGeometry.adjacent(ctx.source_slot)
	)
	if not reach.has(ctx.subject_slot):
		return
	# Printed and borrowed instances of the same heir text pay once for the same actual sale.
	var key: String = "hunter_heir_%d" % sold.iid
	if heir.limits.has(key):
		return
	heir.limits[key] = 1
	var share: float = Pass3Rates.number(ctx.rules.config, "hunters_young_brock_share")
	ctx.announce("young_brock")
	ctx.buff(
		heir,
		floori(maxi(0, sold.attack - sold.tribe_attack) * share),
		floori(maxi(0, sold.health - sold.tribe_health) * share),
		"permanent"
	)


static func arrival(rules: RecruitRules, player: PlayerState, change: Dictionary) -> void:
	if str(change.get("card", "")) != "pelt":
		for _index: int in CoreUtil.to_int(change["count"]):
			rules.give_card(player, str(change["card"]), CoreUtil.to_bool(change["from_pool"]))
		return
	for _index: int in CoreUtil.to_int(change.get("count", 1)):
		var definition: Dictionary = rules.library.get_card("pelt").duplicate(true)
		var prey: Dictionary = change.get("prey", {})
		var attack: int = CoreUtil.to_int(change.get("attack", 0))
		var health: int = CoreUtil.to_int(change.get("health", 0))
		definition["name"] = "Pelt of %s" % str(prey.get("name", "the quarry"))
		definition["portrait_id"] = str(prey.get("id", ""))
		definition["copied_prey"] = prey.duplicate(true)
		definition["attack"] = attack
		definition["health"] = health
		definition["text"] = "Give a Hunter +%d/+%d permanently." % [attack, health]
		definition["do"] = {
			"effect": "buff",
			"attack": attack,
			"health": health,
			"duration": "permanent",
			"target": {"select": "chosen"}
		}
		definition["details"] = (
			"Created. Its fixed reward reads this quarry's stats at the bell. "
			+ "Board spell scaling does not scale it again."
		)
		var item: HandItem = HandItem.make(definition, rules.new_iid())
		if rules.has_hand_space(player):
			player.items.append(item)
		else:
			player.item_doorstep.append(item)
		player.log_event(
			"card", {"card": "pelt", "name": definition["name"], "attack": attack, "health": health}
		)


static func drain_items(rules: RecruitRules, player: PlayerState) -> void:
	while not player.item_doorstep.is_empty() and rules.has_hand_space(player):
		player.items.append(player.item_doorstep.pop_front())


static func aim_problem(player: PlayerState, item: HandItem, slot: int) -> String:
	var tribe: String = str(item.def.get("target_tribe", ""))
	if tribe != "" and not player.board[slot].has_tribe(tribe):
		return "Choose a " + tribe + " unit"
	return ""
