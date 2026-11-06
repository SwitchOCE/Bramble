extends RefCounted
## One readable log line per combat event (BBCode for the RichTextLabel), and a short floating
## caption for events that have no bespoke animation. Call before applying the event to the model,
## so names and old Health are still known.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")

const SLOT_NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]

## side -> display name ("You", "Bot 3 (wide)").
var side_names: PackedStringArray = ["Side A", "Side B"]
## The keyword the last described event was about ("" if none), and what it means: the screen shows
## it on the keyword note.
var last_keyword: String = ""
var last_reminder: String = ""
## Keywords already explained in this fight (reset at combat_start).
var _explained: Dictionary = {}
## uid -> what last hurt it, for "why it died".
var _hurt_by: Dictionary[int, String] = {}


## What fired, in the card's own words: the keyword the mechanic id names ("nightshade_mark" ->
## Nightshade), else the unit's name (Hoglet Mother's death_summon is not Bristle).
static func trigger_name(model: CombatModel, uid: int, mechanic: String) -> String:
	for keyword: Variant in Data.a(model.unit(uid), "keywords"):
		var word: String = str(keyword)
		if not mechanic.is_empty() and mechanic.contains(word.to_lower().replace(" ", "_")):
			return word
	return model.unit_name(uid)


func _who(model: CombatModel, uid: int) -> String:
	var view: Dictionary = model.unit(uid)
	var side: int = Data.i(view, "side", 0)
	var colour: String = UiTheme.hex(UiTheme.LOG_SIDE_0 if side == 0 else UiTheme.LOG_SIDE_1)
	return "[color=#%s]%s[/color]" % [colour, model.unit_name(uid)]


func _side(side: int) -> String:
	return side_names[side] if side >= 0 and side < side_names.size() else "?"


## The log line for an event, plus, the first time a keyword shows up in this fight (a trigger
## or a status gained), its reminder text from keyword_text as a dim line under it.
## `with_reminder` false leaves the reminder off the line (the screen's note panel carries it).
func describe(event: Dictionary, model: CombatModel, with_reminder: bool = true) -> String:
	var kind: String = str(event.get("type", ""))
	if kind == "combat_start":
		_explained.clear()
		_hurt_by.clear()
	var line: String = _line(event, model)
	_note_hurt(event, model)
	last_keyword = ""
	last_reminder = ""
	var keyword: String = ""
	var uid: int = -1
	if kind == "trigger":
		uid = Data.i(event, "uid", -1)
		keyword = trigger_name(model, uid, Data.s(event, "mechanic"))
	elif kind == "status" and Data.b(event, "on", false):
		uid = Data.i(event, "target", -1)
		keyword = UiTheme.status_keyword(Data.s(event, "status"))
	var text: String = reminder(model, uid, keyword)
	if not text.is_empty():
		last_keyword = keyword
		last_reminder = text
	if text.is_empty() or _explained.has(keyword) or not with_reminder:
		return line
	_explained[keyword] = true
	return line + "\n[color=#%s][i]%s[/i][/color]" % [UiTheme.hex(UiTheme.REMINDER), text]


func _note_hurt(event: Dictionary, model: CombatModel) -> void:
	match str(event.get("type", "")):
		"damage":
			var source: String = model.unit_name(Data.i(event, "source", -1))
			var how: String = (
				"%s's Bristle" if str(event.get("kind", "")) == "thorns" else "%s's hit"
			)
			_hurt_by[Data.i(event, "target", -1)] = how % source
		"health_loss":
			_hurt_by[Data.i(event, "target", -1)] = "Nightshade"


## A keyword's rules text: the unit's own keyword_text entry, else the library's (statuses
## gained mid-fight aren't in the unit's view yet). "" when it isn't a keyword.
static func reminder(model: CombatModel, uid: int, keyword: String) -> String:
	if keyword.is_empty():
		return ""
	for entry: Variant in Data.a(model.unit(uid), "keyword_text"):
		var item: Dictionary = entry
		if Data.s(item, "keyword") == keyword:
			return Data.s(item, "text")
	return CardDetail.glossary.get(keyword, "")


func _line(event: Dictionary, model: CombatModel) -> String:
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
			var trigger_text: String = trigger_name(model, trigger_uid, Data.s(event, "mechanic"))
			line = "%s: %s." % [_who(model, trigger_uid), trigger_text]
			if trigger_text == model.unit_name(trigger_uid):
				line = "%s's ability goes off." % _who(model, trigger_uid)
		"attack":
			line = _attack(event, model)
		"skip":
			line = (
				"%s skips its attack (%s)."
				% [_who(model, Data.i(event, "uid", -1)), Data.s(event, "reason").capitalize()]
			)
		"whistle":
			var warned: PackedStringArray = []
			for uid: int in Data.a(event, "warned"):
				warned.append(_who(model, uid))
			line = (
				"%s whistles: %s warned."
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
				"[color=#%s]Nightshade[/color] halves %s from %d to %d Health."
				% [UiTheme.hex(UiTheme.LOG_NIGHTSHADE), _who(model, target), after + amount, after]
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
			var dead: int = Data.i(event, "uid", -1)
			line = "%s dies." % _who(model, dead)
			if _hurt_by.has(dead):
				line = "%s dies to %s." % [_who(model, dead), _hurt_by[dead]]
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
	# "quick" is the state at declaration only (Quick is checked per exchange and per Peck
	# strike), so the log doesn't label it; the damage lines that follow show who hit first.
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
	return text + ": %d Health left." % maxi(Data.i(event, "health_after", 0), 0)


func _end(event: Dictionary) -> String:
	var winner: int = Data.i(event, "winner", -1)
	var prefix: String = ""
	if Data.s(event, "reason") == "no_attacks":
		prefix = "No unit left can attack. "
	if winner < 0:
		return "[b]%sTie. No damage.[/b]" % prefix
	return "[b]%sWinner: %s, %d damage.[/b]" % [prefix, _side(winner), Data.i(event, "damage", 0)]


static func stat_delta_text(attack_delta: int, health_delta: int) -> String:
	return "%s/%s" % [_signed(attack_delta), _signed(health_delta)]


static func _signed(n: int) -> String:
	return ("+%d" % n) if n >= 0 else str(n)
