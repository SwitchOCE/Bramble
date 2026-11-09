extends RefCounted
## Plain fight events, with identity and slot tracking shared across one replay.

const CombatLog := preload("res://src/ui/screens/combat_log.gd")


static func event_line(event: Dictionary, names: Dictionary, mine: int) -> String:
	match str(event["type"]):
		"combat_start":
			return _start_line(event, names, mine)
		"phase":
			return "-- %s" % CombatLog.phase_word(str(event["name"]))
		"attack":
			var line: String = (
				"%s attacks %s" % [_who(event["attacker"], names), _who(event["defender"], names)]
			)
			if event.get("pack", false):
				var joined: PackedStringArray = []
				for uid: int in event.get("joiners", []):
					joined.append(_who(uid, names))
				line += (
					" in a Pack attack; "
					+ ", ".join(joined)
					+ (" joins" if joined.size() == 1 else " join")
					+ " the attack"
				)
			return line
		"damage":
			return (
				"%s takes %s from %s (%s left)"
				% [
					_who(event["target"], names),
					event["amount"],
					_who(event.get("source"), names),
					event["health_after"],
				]
			)
		"health_loss":
			return (
				"%s loses %s Health to %s (%s left)"
				% [
					_who(event["target"], names),
					event["amount"],
					CombatLog.health_loss_cause(
						event, func(uid: int) -> String: return _who(uid, names)
					),
					event["health_after"]
				]
			)
		"death":
			return "%s dies" % _who(event["uid"], names)
		"summon":
			var unit: Dictionary = event["unit"]
			_record_unit(
				names, unit, CoreUtil.to_int(event["side"]), CoreUtil.to_int(event["slot"]), mine
			)
			var verb: String = "comes out at" if event.has("came_out") else "arrives at"
			if event.has("landed"):
				verb = "lands from the sky at"
			return (
				"%s %s %s, %s/%s"
				% [names[unit["uid"]], verb, _label(event["slot"]), unit["attack"], unit["health"]]
			)
		"stats":
			if event["attack_delta"] == 0 and event["health_delta"] == 0:
				return ""
			return (
				"%s %s (%s), now %s/%s"
				% [
					_who(event["target"], names),
					CombatLog.stat_change_text(
						CoreUtil.to_int(event["attack_delta"]),
						CoreUtil.to_int(event["health_delta"])
					),
					CombatLog.stat_cause(event, func(uid: int) -> String: return _who(uid, names)),
					event["attack"],
					event["health"]
				]
			)
		"gain_pending":
			return CombatLog.pending_gain_words(
				event, func(uid: int) -> String: return _who(uid, names)
			)
		"permanent_reward":
			return (
				"%s gains %+d/%+d permanently (%s)"
				% [
					_who(event["target"], names),
					event["attack_delta"],
					event["health_delta"],
					CombatLog.stat_cause(event, func(uid: int) -> String: return _who(uid, names))
				]
			)
		"status":
			return CombatLog.status_words(event, func(uid: int) -> String: return _who(uid, names))
		"trigger":
			return _trigger_line(event, names)
	return _rare_line(event, names, mine)


static func _rare_line(event: Dictionary, names: Dictionary, mine: int) -> String:
	match str(event["type"]):
		"bog_patch":
			return (
				"%s applies Mire to %s %s"
				% [
					_who(event["maker"], names),
					"your" if CoreUtil.to_int(event["side"]) == mine else "the enemy's",
					_label(event["slot"])
				]
			)
		"quarry_marked":
			return (
				"%s marks %s as quarry"
				% [_who(event["hunter"], names), _who(event["quarry"], names)]
			)
		"quarry_lost":
			return "%s loses its quarry mark" % _who(event["hunter"], names)
		"take":
			return (
				"%s makes a Take on %s"
				% [_who(event["hunter"], names), _who(event["quarry"], names)]
			)
		"poach":
			return (
				"%s claims %s for the next shop"
				% [_who(event["hunter"], names), _who(event["quarry"], names)]
			)
		"immediate_attack":
			return (
				"%s %s %s at once"
				% [
					_who(event["attacker"], names),
					"pounces on" if event.get("kind", "") == "pounce" else "counterattacks",
					_who(event["defender"], names)
				]
			)
		"kiss":
			return "%s gets a kiss (%s/3)" % [_who(event["target"], names), event["count"]]
		"transform":
			var unit: Dictionary = event["unit"]
			var old_name: String = _who(event["target"], names)
			var views: Dictionary = names.get("units", {})
			var old_view: Dictionary = views.get(event["target"], {})
			var view: Dictionary = old_view.duplicate()
			view.merge(unit, true)
			view["uid"] = event["target"]
			_record_unit(
				names,
				view,
				CoreUtil.to_int(view.get("side", mine)),
				CoreUtil.to_int(view.get("slot", -1)),
				mine
			)
			return "%s becomes %s" % [old_name, unit["name"]]
		"swallowed":
			return "%s swallows %s" % [_who(event["by"], names), _who(event["uid"], names)]
		"no_room":
			if str(event.get("mechanic", "")) == "mice":
				return "%s Mousewife: no room for a Mouse" % _whose(event["side"], mine)
			return CombatLog.no_room_words(event, func(uid: int) -> String: return _who(uid, names))
		"no_target":
			return "%s: %s" % [_who(event.get("uid"), names), event.get("reason", "no target")]
		"pack_blocked":
			return (
				"%s stays out of %s's Pack: Mired by %s"
				% [
					_who(event["joiner"], names),
					_who(event["leader"], names),
					_who(event["maker"], names)
				]
			)
		"goose_strike":
			return "A Nest on %s strikes %s" % [_label(event["slot"]), _who(event["target"], names)]
		"text_taken":
			return (
				"%s takes the text of %s" % [_who(event["uid"], names), _who(event["from"], names)]
			)
		"side_trigger":
			return "%s hero power goes off" % _whose(event["side"], mine)
		"slot_mark":
			return (
				"%s marks %s %s for %s damage"
				% [
					_who(event["source"], names),
					"your" if CoreUtil.to_int(event["side"]) == mine else "the enemy's",
					_label(event["slot"]),
					event["damage"],
				]
			)
		"mire_wait":
			return "%s waits for %s." % [_who(event["uid"], names), _who(event["target"], names)]
		"early_spoils":
			return (
				"+1 gold: Spoils (%s)."
				% ("you" if CoreUtil.to_int(event["side"]) == mine else "opponent")
			)
		"skip":
			return "%s can't attack (%s)" % [_who(event["uid"], names), _plain(event["reason"])]
		"pass":
			return "%s nothing that can attack" % _has(event["side"], mine)
		"cancel":
			return "%s's attack is off (%s)" % [_who(event["uid"], names), _plain(event["reason"])]
		"combat_end":
			if event.get("last_blow", false):
				return CombatLog.last_blow_note(event, mine)
			if str(event["reason"]) == Combat.REASON_BOARD_EMPTY:
				var winner: int = CoreUtil.to_int(event["winner"])
				if winner < 0:
					return (
						"ends: both boards empty; tie, each hero takes %d toll damage"
						% CoreUtil.to_int(event.get("damage", 0))
					)
				var survivors: Array = event["survivors"][winner]
				var alive: PackedStringArray = []
				for uid: Variant in survivors:
					alive.append(_who(uid, names))
				return (
					"ends: %s board empty. Survivors: %s"
					% ["enemy's" if winner == mine else "your", ", ".join(alive)]
				)
			return "ends: %s" % _plain(event["reason"])
		"slot_hex":
			return (
				"%s applies Hex to %s %s: -%s Attack there"
				% [
					_who(event["source"], names),
					"your" if CoreUtil.to_int(event["side"]) == mine else "the enemy's",
					_label(event["slot"]),
					event["total"],
				]
			)
		"spill":
			return "%s no room: an Acorn instead" % _has(event["side"], mine)
		"relocate":
			var views: Dictionary = names.get("units", {})
			var old_view: Dictionary = views.get(event["uid"], {})
			var new_side: int = CoreUtil.to_int(event["side"])
			var same_side: bool = CoreUtil.to_int(old_view.get("side", -1)) == new_side
			var owner: String = (
				"" if same_side else ("your " if new_side == mine else "the enemy's ")
			)
			var line: String = (
				"%s moves to %s%s" % [_who(event["uid"], names), owner, _label(event["slot"])]
			)
			var view: Dictionary = old_view.duplicate()
			if not view.is_empty():
				_record_unit(names, view, new_side, CoreUtil.to_int(event["slot"]), mine)
			return line
		"ring_dance":
			return (
				"%s's Ring dances from %s to %s (+%s/+%s)"
				% [
					_side(event["side"], mine),
					_label(event["from"]),
					_label(event["to"]),
					event["attack"],
					event["health"],
				]
			)
	return JSON.stringify(event)


## "Spill" when the unit's keyword is what fired, or that its ability went off. Never an id.
static func _trigger_line(event: Dictionary, names: Dictionary) -> String:
	var mechanic: String = str(event["mechanic"])
	if CombatLog.NAMED_TRIGGERS.has(mechanic):
		return "%s: %s" % [_who(event["uid"], names), CombatLog.NAMED_TRIGGERS[mechanic]]
	var keywords: Dictionary = names.get("keywords", {})
	var own: Array = keywords.get(event["uid"], [])
	for value: Variant in own:
		var word: String = str(value)
		if mechanic.contains(word.to_lower().replace(" ", "_")):
			return "%s: %s" % [_who(event["uid"], names), word]
	var views: Dictionary = names.get("units", {})
	var view: Dictionary = views.get(event["uid"], {})
	var card: Dictionary = CombatLog.card_of(str(view.get("def_id", "")))
	var words: String = CombatLog.trigger_words(card, str(view.get("text", "")), mechanic)
	return _who(event["uid"], names) + words.trim_suffix(".")


## A raw word from the rules, in plain text.
static func _plain(word: Variant) -> String:
	return str(word).replace("_", " ")


static func _side(side: Variant, mine: int) -> String:
	return "You" if CoreUtil.to_int(side) == mine else "Enemy"


## "You have" or "Enemy has".
static func _has(side: Variant, mine: int) -> String:
	return "You have" if CoreUtil.to_int(side) == mine else "Enemy has"


## "Your" or "Enemy's".
static func _whose(side: Variant, mine: int) -> String:
	return "Your" if CoreUtil.to_int(side) == mine else "Enemy's"


static func _start_line(event: Dictionary, names: Dictionary, mine: int) -> String:
	var boards: Array = event["boards"]
	var parts: PackedStringArray = []
	for side: int in [mine, 1 - mine]:
		var row: Array = boards[side]
		var units: PackedStringArray = []
		for slot: int in row.size():
			if row[slot] != null:
				var unit: Dictionary = row[slot]
				_record_unit(names, unit, side, slot, mine)
				units.append(
					"%s %s %s/%s" % [_label(slot), unit["name"], unit["attack"], unit["health"]]
				)
		parts.append("%s: %s" % [_side(side, mine), ", ".join(units)])
	var first: bool = CoreUtil.to_int(event["first_side"]) == mine
	return "%s. %s first." % [" | ".join(parts), "You go" if first else "Enemy goes"]


static func _note_keywords(names: Dictionary, unit: Dictionary) -> void:
	var keywords: Dictionary = names.get("keywords", {})
	keywords[unit["uid"]] = unit.get("keywords", [])
	names["keywords"] = keywords


static func _unit_name(unit: Dictionary, side: int, mine: int) -> String:
	var slot: int = CoreUtil.to_int(unit.get("slot", -1))
	var tag: String = " (%s)" % _label(slot) if BoardGeometry.is_valid(slot) else ""
	return "%s%s%s" % ["" if side == mine else "enemy ", unit["name"], tag]


static func _record_unit(
	names: Dictionary, unit: Dictionary, side: int, slot: int, mine: int
) -> void:
	var view: Dictionary = unit.duplicate()
	view["side"] = side
	view["slot"] = slot
	var views: Dictionary = names.get("units", {})
	views[unit["uid"]] = view
	names["units"] = views
	names[unit["uid"]] = _unit_name(view, side, mine)
	_note_keywords(names, view)


static func _who(uid: Variant, names: Dictionary) -> String:
	if uid == null:
		return "an effect"
	return str(names.get(uid, "#%s" % str(uid)))


static func _label(slot: Variant) -> String:
	var index: int = CoreUtil.to_int(slot)
	return BoardGeometry.LABELS[index] if BoardGeometry.is_valid(index) else "?"
