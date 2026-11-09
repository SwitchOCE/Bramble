class_name QuilboarChoices
extends RefCounted
## Choose One is independent of When played. Only the actual play queues a choice; repeating
## on_play cannot repeat its mode or the after-resolution Hogrider event.


static func begin(
	rules: RecruitRules,
	player: PlayerState,
	card: Dictionary,
	unit: RecruitUnit = null,
	fields: Dictionary = {}
) -> bool:
	if not player.reference_quilboar or not card.has("modes"):
		return false
	var modes: Array = card["modes"]
	var labels: PackedStringArray = []
	var available: Array = []
	for mode: Dictionary in modes:
		if not CoreUtil.to_bool(mode.get("unavailable", false)):
			labels.append(str(mode["name"]))
			available.append(mode)
	var choice: Dictionary = {
		"kind": "choose_one",
		"options": labels,
		"spells": false,
		"modes": available,
		"card_def": card,
		"source_iid": unit.iid if unit != null else 0,
		"item_id": str(card["id"]) if unit == null else "",
		"fields": fields,
		"golden": unit != null and unit.golden
	}
	player.pending.append(choice)
	if _both(player):
		resolve(rules, player, player.pending.find(choice), 0, true)
	return true


static func _both(player: PlayerState) -> bool:
	for unit: RecruitUnit in player.board:
		if unit == null or unit.def_id() != "qb_thorned_trailblazer":
			continue
		var budget: int = (
			CoreUtil.to_int(player.quilboar_ref["trailblazer_both_per_turn"]) * unit.golden_factor()
		)
		var used: int = CoreUtil.to_int(unit.limits.get("qb_both", 0))
		if used < budget:
			unit.limits["qb_both"] = used + 1
			return true
	return false


static func resolve(
	rules: RecruitRules, player: PlayerState, pending_index: int, index: int, both: bool = false
) -> String:
	var choice: Dictionary = player.pending[pending_index]
	var modes: Array = choice["modes"]
	if index < 0 or index >= modes.size():
		return "No such option"
	player.pending.remove_at(pending_index)
	var unit: RecruitUnit = RecruitRules._unit_by_iid(player, CoreUtil.to_int(choice["source_iid"]))
	var original: Dictionary = choice["fields"]
	var fields: Dictionary = original.duplicate()
	fields["card_def"] = choice["card_def"]
	if unit != null:
		fields["subject"] = unit
	var ctx: RecruitContext = RecruitContext.make(
		rules, player, "cast" if unit == null else "choose_one", fields
	)
	ctx.source = unit
	ctx.source_slot = player.board.find(unit) if unit != null else -1
	var picks: Array = modes if both else [modes[index]]
	for mode: Dictionary in picks:
		for step: Dictionary in mode["effects"]:
			var applied: Dictionary = EffectSchema.doubled_step(step) if choice["golden"] else step
			EffectRunner.run_step(applied, {}, ctx)
	player.log_event(
		"choose_one", {"card": str(choice["card_def"]["id"]), "mode": index, "both": both}
	)
	if unit == null:
		rules.events.fire(player, "on_spell_cast", fields)
	rules.events.fire(player, "on_choose_one_played", fields)
	rules.board_changed(player)
	return ""


static func view(choice: Dictionary) -> Dictionary:
	var options: Array = []
	for mode: Dictionary in choice["modes"]:
		options.append(
			{
				"name": str(mode["name"]),
				"text": str(mode["text"]),
				"kind": "choice",
				"def_id": "",
				"keywords": []
			}
		)
	return {"kind": "choose_one", "options": options}
