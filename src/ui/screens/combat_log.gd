extends RefCounted
## One readable log line per combat event (BBCode for the RichTextLabel), and a short floating
## caption for events that have no bespoke animation. Call before applying the event to the model,
## so names and old Health are still known.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")

const SLOT_NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]

## side -> display name ("You", "Bot 3 (wide)").
var side_names: PackedStringArray = ["Side A", "Side B"]


## What fired, in the card's own words: its first keyword, else its name.
static func trigger_name(model: CombatModel, uid: int) -> String:
	var keywords: Array = Data.a(model.unit(uid), "keywords")
	if not keywords.is_empty():
		return str(keywords[0])
	return model.unit_name(uid)


func _who(model: CombatModel, uid: int) -> String:
	var view: Dictionary = model.unit(uid)
	var side: int = Data.i(view, "side", 0)
	var colour: String = "e8dfc4" if side == 0 else "f3b9a6"
	return "[color=#%s]%s[/color]" % [colour, model.unit_name(uid)]


func _side(side: int) -> String:
	return side_names[side] if side >= 0 and side < side_names.size() else "?"


func describe(event: Dictionary, model: CombatModel) -> String:
	var kind: String = str(event.get("type", ""))
	var line: String = "(%s)" % kind
	match kind:
		"combat_start":
			var first: int = Data.i(event, "first_side", 0)
			line = (
				"[b]Combat: %s vs %s.[/b] First to attack: %s." % [_side(0), _side(1), _side(first)]
			)
		"phase":
			var phase_name: String = str(event.get("name", ""))
			line = (
				"[b]— %s —[/b]"
				% ("Start of Combat" if phase_name == "start_of_combat" else "Attacks")
			)
		"trigger":
			var trigger_uid: int = Data.i(event, "uid", -1)
			line = "%s: %s" % [_who(model, trigger_uid), trigger_name(model, trigger_uid)]
		"attack":
			line = _attack(event, model)
		"skip":
			line = (
				"%s skips its attack (%s)."
				% [_who(model, Data.i(event, "uid", -1)), str(event.get("reason", ""))]
			)
		"whistle":
			var warned: PackedStringArray = []
			for uid: int in Data.a(event, "warned"):
				warned.append(_who(model, uid))
			line = (
				"%s whistles: %s warned (next attack deals half)."
				% [
					_who(model, Data.i(event, "uid", -1)),
					", ".join(warned) if not warned.is_empty() else "nobody"
				]
			)
		"cancel":
			line = (
				"%s's attack is cancelled (%s)."
				% [_who(model, Data.i(event, "uid", -1)), str(event.get("reason", ""))]
			)
		"pass":
			line = "%s has no unit that can attack and passes." % _side(Data.i(event, "side", 0))
		"damage":
			line = _damage(event, model)
		"health_loss":
			var target: int = Data.i(event, "target", -1)
			var after: int = Data.i(event, "health_after", 0)
			var amount: int = Data.i(event, "amount", 0)
			line = (
				"[color=#c9a0f0]Nightshade halves %s: %d → %d Health (Health loss, not damage).[/color]"
				% [_who(model, target), after + amount, after]
			)
		"status":
			var on: bool = Data.b(event, "on", true)
			var status_name: String = UiTheme.status_label(str(event.get("status", "")))
			line = (
				"%s %s %s."
				% [
					_who(model, Data.i(event, "target", -1)),
					"gains" if on else "loses",
					status_name
				]
			)
		"stats":
			var attack_delta: int = Data.i(event, "attack_delta", 0)
			var health_delta: int = Data.i(event, "health_delta", 0)
			line = (
				"%s %s → %d/%d."
				% [
					_who(model, Data.i(event, "target", -1)),
					stat_delta_text(attack_delta, health_delta),
					Data.i(event, "attack", 0),
					Data.i(event, "health", 0)
				]
			)
		"slot_mark":
			var slot: int = Data.i(event, "slot", 0)
			line = (
				"%s marks %s's %s: units entering it take %d."
				% [
					_who(model, Data.i(event, "source", -1)),
					_side(Data.i(event, "side", 0)),
					SLOT_NAMES[slot] if slot >= 0 and slot < 7 else "?",
					Data.i(event, "damage", 0)
				]
			)
		"death":
			line = "%s dies." % _who(model, Data.i(event, "uid", -1))
		"summon":
			var view: Dictionary = Data.d(event, "unit")
			var slot_index: int = Data.i(event, "slot", 0)
			line = (
				"%s summons %s into %s."
				% [
					_who(model, Data.i(event, "source", -1)),
					str(view.get("name", "a unit")),
					SLOT_NAMES[slot_index] if slot_index >= 0 and slot_index < 7 else "?"
				]
			)
		"combat_end":
			line = _end(event)
	return line


func _attack(event: Dictionary, model: CombatModel) -> String:
	var text: String = (
		"%s attacks %s"
		% [_who(model, Data.i(event, "attacker", -1)), _who(model, Data.i(event, "defender", -1))]
	)
	var joiners: Array = Data.a(event, "joiners")
	if not joiners.is_empty():
		var names: PackedStringArray = []
		for uid: int in joiners:
			names.append(_who(model, uid))
		text += " with " + ", ".join(names)
	var strikes: int = Data.i(event, "strikes", 1)
	if strikes > 1:
		text += " (%d strikes)" % strikes
	var quick: bool = Data.b(event, "quick", false)
	if quick:
		text += " (Quick)"
	return text + "."


func _damage(event: Dictionary, model: CombatModel) -> String:
	var amount: int = Data.i(event, "amount", 0)
	var raw: int = event.get("raw", amount)
	var kind: String = str(event.get("kind", "attack"))
	var text: String = (
		"%s deals %d to %s"
		% [
			_who(model, Data.i(event, "source", -1)),
			amount,
			_who(model, Data.i(event, "target", -1))
		]
	)
	if kind != "attack":
		text += " (%s)" % kind
	var modifiers: Array = Data.a(event, "modifiers")
	if not modifiers.is_empty():
		var names: PackedStringArray = []
		for item: Variant in modifiers:
			names.append(str(item).capitalize())
		text += " [%s: %d → %d]" % [", ".join(names), raw, amount]
	return text + ". Health %d." % Data.i(event, "health_after", 0)


func _end(event: Dictionary) -> String:
	var winner: int = Data.i(event, "winner", -1)
	if winner < 0:
		return "[b]Tie. No damage.[/b]"
	return "[b]Winner: %s, %d damage.[/b]" % [_side(winner), Data.i(event, "damage", 0)]


static func stat_delta_text(attack_delta: int, health_delta: int) -> String:
	return "%s/%s" % [_signed(attack_delta), _signed(health_delta)]


static func _signed(n: int) -> String:
	return ("+%d" % n) if n >= 0 else str(n)
