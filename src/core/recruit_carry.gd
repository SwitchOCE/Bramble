class_name RecruitCarry
extends RefCounted
## Apply fight rewards to the owned units, including those held in hand or a Belly.


static func apply(rules: RecruitRules, player: PlayerState, change: Dictionary) -> void:
	match str(change.get("op", "")):
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
		"pie_payment":
			var pie: RecruitUnit = RecruitRules._unit_by_iid(player, CoreUtil.to_int(change["iid"]))
			if pie != null:
				pie.counters["paid_pie"] = CoreUtil.to_int(pie.counters.get("paid_pie", 0)) + 1
			player.gold_next_turn += CoreUtil.to_int(change["amount"])
		"gold_next_turn":
			player.gold_next_turn += CoreUtil.to_int(change["amount"])
		"spend_item":
			RecruitRules._spend_acorn(player, CoreUtil.to_int(change["gold"]))
		"add_card":
			player.cards_next_turn.append(change.duplicate())
