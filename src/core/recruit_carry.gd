class_name RecruitCarry
extends RefCounted
## Apply fight rewards to the owned units, including those held in hand or a Belly.


static func apply(rules: RecruitRules, player: PlayerState, change: Dictionary) -> void:
	match str(change.get("op", "")):
		"gem_size_add":
			ReferenceQuilboar.gem_size_add(
				player, CoreUtil.to_int(change["attack"]), CoreUtil.to_int(change["health"])
			)
		"gem_ledger":
			var unit: RecruitUnit = RecruitRules._unit_by_iid(
				player, CoreUtil.to_int(change["iid"])
			)
			if unit != null:
				unit.gem_attack += CoreUtil.to_int(change["attack"])
				unit.gem_health += CoreUtil.to_int(change["health"])
		"bog_state":
			Pass3Bog.receive_state(player, change)
		"pending_gain":
			PendingGains.receive(player, change)
		"poach":
			HunterRecruit.poach(rules, player, change)
		"kiss":
			var unit: RecruitUnit = RecruitRules._unit_by_iid(
				player, CoreUtil.to_int(change["iid"])
			)
			if unit != null:
				unit.counters["kisses"] = CoreUtil.to_int(change["count"])
				player.log_event("kiss", {"iid": unit.iid, "count": unit.counters["kisses"]})
		"transform":
			var unit: RecruitUnit = RecruitRules._unit_by_iid(
				player, CoreUtil.to_int(change["iid"])
			)
			if unit != null:
				var into: Dictionary = rules.library.get_unit(str(change["into"]))
				if not into.is_empty():
					unit.pool_origin = unit.pool_id()
					unit.set_base(into, unit.golden)
					player.log_event("transform", {"iid": unit.iid, "name": str(into["name"])})
		"buff":
			var unit: RecruitUnit = RecruitRules._unit_by_iid(
				player, CoreUtil.to_int(change["iid"])
			)
			if unit != null:
				unit.shy_accepts_stats = true
				unit.add_permanent(
					CoreUtil.to_int(change["attack"]), CoreUtil.to_int(change["health"])
				)
				unit.shy_accepts_stats = false
				unit.shy_seen = Vector2i(-1, -1)
		"grant":
			var target: RecruitUnit = RecruitRules._unit_by_iid(
				player, CoreUtil.to_int(change["iid"])
			)
			if target != null:
				(
					target
					. grants
					. append(
						{
							"entry": change["entry"],
							"golden": change["golden"],
							"keyword": change["keyword"],
							"combat_only": false,
						}
					)
				)
		"counter":
			var unit: RecruitUnit = RecruitRules._unit_by_iid(
				player, CoreUtil.to_int(change["iid"])
			)
			if unit != null:
				unit.counters[str(change["key"])] = CoreUtil.to_int(change["value"])
		"gold_next_turn":
			player.gold_next_turn += CoreUtil.to_int(change["amount"])
		"spend_item":
			_spend_acorn(player, CoreUtil.to_int(change["gold"]))
		"add_card":
			player.cards_next_turn.append(change.duplicate())


## Sergeant-at-Conkers threw an Acorn item worth this much.
static func _spend_acorn(player: PlayerState, gold: int) -> void:
	for index: int in player.items.size():
		if player.items[index].gold_value() == gold:
			player.items.remove_at(index)
			player.log_event("thrown", {"gold": gold})
			return
