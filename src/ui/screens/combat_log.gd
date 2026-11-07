extends RefCounted
## One readable log line per combat event (BBCode for the RichTextLabel), and a short floating
## caption for events that have no bespoke animation. Call before applying the event to the model,
## so names and old Health are still known.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")

const SLOT_NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
## Seconds each event type holds the screen at 1x.
const DURATIONS: Dictionary[String, float] = {
	"combat_start": 0.5,
	"phase": 0.5,
	"trigger": 0.55,
	"attack": 0.5,
	"damage": 0.5,
	"health_loss": 0.65,
	"status": 0.45,
	"stats": 0.4,
	"permanent_reward": 0.55,
	"death": 0.45,
	"summon": 0.5,
	"swallowed": 0.55,
	"goose_strike": 0.5,
	"text_taken": 0.5,
	"no_room": 0.3,
	"pack_blocked": 0.6,
	"relocate": 0.45,
	"skip": 0.55,
	"whistle": 0.55,
	"cancel": 0.55,
	"pass": 0.55,
	"slot_mark": 0.55,
	"bog_patch": 0.55,
	"quarry_marked": 0.55,
	"take": 0.7,
	"poach": 0.65,
	"immediate_attack": 0.6,
	"kiss": 0.6,
	"transform": 0.9,
	"combat_end": 0.3,
}
const LOUD_EVENTS: PackedStringArray = [
	"combat_start", "phase", "attack", "trigger", "pass", "skip", "combat_end"
]

## side -> display name ("You", "Pipkin").
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
	# A loaned keyword needn't appear on the printed card. The Pretender's death-witness
	# payment is a reward, not another attack from the dead frog.
	var named: Dictionary = {"mire": "Mire", "bitter": "Bitter", "snap_kill": "Mired kill reward"}
	if named.has(mechanic):
		return str(named[mechanic])
	for keyword: Variant in Data.a(model.unit(uid), "keywords"):
		var word: String = str(keyword)
		if not mechanic.is_empty() and mechanic.contains(word.to_lower().replace(" ", "_")):
			return word
	return model.unit_name(uid)


func _who(model: CombatModel, uid: int) -> String:
	var view: Dictionary = model.unit(uid)
	var side: int = Data.i(view, "side", 0)
	var colour: String = UiTheme.hex(UiTheme.LOG_SIDE_0 if side == 0 else UiTheme.LOG_SIDE_1)
	return "[color=#%s]%s[/color]" % [colour, _name_at(model, uid)]


static func _name_at(model: CombatModel, uid: int) -> String:
	var slot: int = Data.i(model.unit(uid), "slot", -1)
	var tag: String = " (%s)" % SLOT_NAMES[slot] if slot >= 0 and slot < SLOT_NAMES.size() else ""
	return model.unit_name(uid) + tag


func _side(side: int) -> String:
	return side_names[side] if side >= 0 and side < side_names.size() else "?"


## "Your", "your" or "Pipkin's", for a side at the start or the middle of a line.
func _sides(side: int, capital: bool = false) -> String:
	if _side(side) == "You":
		return "Your" if capital else "your"
	return "%s's" % _side(side)


## "You have" or "Pipkin has".
func _has(side: int) -> String:
	return "You have" if _side(side) == "You" else "%s has" % _side(side)


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
	elif kind in ["bog_patch", "quarry_marked", "take"]:
		keyword = (
			{
				"bog_patch": "Mire",
				"quarry_marked": "Quarry",
				"take": "Quarry",
			}
			. get(kind, "")
		)
	elif kind == "immediate_attack" and Data.s(event, "kind") == "pounce":
		keyword = "Pounce"
	elif kind == "attack" and Data.b(event, "pack"):
		keyword = "Pack"
	elif kind == "pack_blocked":
		keyword = "Mired"
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
			var source: String = _name_at(model, Data.i(event, "source", -1))
			var how: String = (
				"%s's Bristle" if str(event.get("kind", "")) == "thorns" else "%s's hit"
			)
			_hurt_by[Data.i(event, "target", -1)] = how % source
		"health_loss":
			_hurt_by[Data.i(event, "target", -1)] = "Nightshade"


## A keyword's rules text in the player's words. "" when it isn't a keyword.
static func reminder(_model: CombatModel, _uid: int, keyword: String) -> String:
	return KeywordRules.text(keyword)


func _line(event: Dictionary, model: CombatModel) -> String:
	var kind: String = str(event.get("type", ""))
	var line: String = ""
	match kind:
		"combat_start":
			var first: int = Data.i(event, "first_side", 0)
			line = (
				"[b]Combat: %s vs %s.[/b] First to attack: %s." % [_side(0), _side(1), _side(first)]
			)
		"phase":
			var phase_name: String = str(event.get("name", ""))
			line = "[b]— %s —[/b]" % phase_word(phase_name)
		"bog_patch":
			line = (
				"%s bogs %s %s."
				% [
					_who(model, Data.i(event, "maker")),
					_sides(Data.i(event, "side")),
					SLOT_NAMES[Data.i(event, "slot")]
				]
			)
		"quarry_marked":
			line = (
				"%s marks %s as quarry."
				% [_who(model, Data.i(event, "hunter")), _who(model, Data.i(event, "quarry"))]
			)
		"quarry_lost":
			line = "%s loses its quarry mark." % _who(model, Data.i(event, "hunter"))
		"take":
			line = (
				"%s makes a Take on %s."
				% [_who(model, Data.i(event, "hunter")), _who(model, Data.i(event, "quarry"))]
			)
		"poach":
			line = (
				"%s claims a pool copy of %s for the next shop, if available."
				% [_who(model, Data.i(event, "hunter")), _who(model, Data.i(event, "quarry"))]
			)
		"immediate_attack":
			var action: String = "pounces on" if Data.s(event, "kind") == "pounce" else "answers"
			line = (
				"%s %s %s at once."
				% [
					_who(model, Data.i(event, "attacker")),
					action,
					_who(model, Data.i(event, "defender"))
				]
			)
		"kiss":
			line = (
				"%s gets a kiss (%d/3)."
				% [_who(model, Data.i(event, "target")), Data.i(event, "count")]
			)
		"transform":
			line = (
				"%s becomes %s."
				% [_who(model, Data.i(event, "target")), Data.s(Data.d(event, "unit"), "name")]
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
				% [_who(model, Data.i(event, "uid", -1)), Data.s(event, "reason").replace("_", " ")]
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
				% [
					_who(model, Data.i(event, "uid", -1)),
					str(event.get("reason", "")).replace("_", " ")
				]
			)
		"pass":
			line = "%s no unit that can attack and passes." % _has(Data.i(event, "side", 0))
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
			if attack_delta == 0 and health_delta == 0:
				return ""
			line = (
				"%s %s, now %d/%d."
				% [
					_who(model, Data.i(event, "target", -1)),
					stat_delta_text(attack_delta, health_delta),
					Data.i(event, "attack", 0),
					Data.i(event, "health", 0)
				]
			)
		"permanent_reward":
			line = (
				"%s earns %s permanently for the recruit board."
				% [
					_who(model, Data.i(event, "target", -1)),
					stat_delta_text(Data.i(event, "attack_delta"), Data.i(event, "health_delta"))
				]
			)
		"slot_mark":
			var slot: int = Data.i(event, "slot", 0)
			line = (
				"%s marks %s %s: units entering it take %d."
				% [
					_who(model, Data.i(event, "source", -1)),
					_sides(Data.i(event, "side", 0)),
					SLOT_NAMES[slot] if slot >= 0 and slot < 7 else "?",
					Data.i(event, "damage", 0)
				]
			)
		"slot_hex":
			var hexed: int = Data.i(event, "slot", 0)
			line = (
				"%s hexes %s %s: %d Attack for this fight."
				% [
					_who(model, Data.i(event, "source", -1)),
					_sides(Data.i(event, "side", 0)),
					SLOT_NAMES[hexed] if hexed >= 0 and hexed < 7 else "?",
					-absi(Data.i(event, "amount", 0))
				]
			)
		"spill":
			line = "%s no room: an Acorn instead." % _has(Data.i(event, "side", 0))
		"relocate":
			var moved_to: int = Data.i(event, "slot", 0)
			var moved_uid: int = Data.i(event, "uid", -1)
			var old_side: int = Data.i(model.unit(moved_uid), "side", -1)
			var new_side: int = Data.i(event, "side", 0)
			var owner: String = "" if old_side == new_side else _sides(new_side) + " "
			line = (
				"%s moves to %s%s."
				% [
					_who(model, moved_uid),
					owner,
					SLOT_NAMES[moved_to] if moved_to >= 0 and moved_to < 7 else "?"
				]
			)
		"ring_dance":
			var danced: int = Data.i(event, "to", 0)
			line = (
				"A Ring dances to %s %s."
				% [
					_sides(Data.i(event, "side", 0)),
					SLOT_NAMES[danced] if danced >= 0 and danced < 7 else "?"
				]
			)
		"side_trigger":
			line = "%s hero power goes off." % _sides(Data.i(event, "side", 0), true)
		"death":
			var dead: int = Data.i(event, "uid", -1)
			line = "%s dies." % _who(model, dead)
			if _hurt_by.has(dead):
				line = "%s dies to %s." % [_who(model, dead), _hurt_by[dead]]
		"summon":
			line = _summon_line(event, model)
		"swallowed":
			var by: int = Data.i(event, "by", -1)
			line = "%s swallows %s." % [_who(model, by), _who(model, Data.i(event, "uid", -1))]
		"no_room":
			if Data.s(event, "mechanic") == "mice":
				line = "%s: no room for a Mouse." % _side(Data.i(event, "side"))
			elif Data.s(event, "mechanic") == "peat_king":
				line = (
					"%s has no room for a Peatling; nothing rises."
					% _who(model, Data.i(event, "uid"))
				)
			else:
				line = "%s: no room, so it stays inside." % _who(model, Data.i(event, "uid", -1))
		"pack_blocked":
			line = (
				"%s stays out of %s's Pack: it must attack %s while Mired."
				% [
					_who(model, Data.i(event, "joiner")),
					_who(model, Data.i(event, "leader")),
					_who(model, Data.i(event, "maker"))
				]
			)
		"goose_strike":
			line = "A Nest strikes %s for Mother Goose." % _who(model, Data.i(event, "target", -1))
		"text_taken":
			var thief: int = Data.i(event, "uid", -1)
			line = (
				"%s takes %s's text." % [_who(model, thief), _who(model, Data.i(event, "from", -1))]
			)
		"combat_end":
			line = _end(event)
	return line


func _summon_line(event: Dictionary, model: CombatModel) -> String:
	var view: Dictionary = Data.d(event, "unit")
	var slot: int = Data.i(event, "slot", 0)
	var where: String = SLOT_NAMES[slot] if slot >= 0 and slot < 7 else "?"
	var name_of: String = str(view.get("name", "a unit"))
	if event.has("came_out"):
		return "%s comes out into %s." % [name_of, where]
	if event.has("landed"):
		return "%s lands on its Nest at %s." % [name_of, where]
	if event.has("split"):
		return "%s splits off into %s." % [name_of, where]
	return "%s summons %s into %s." % [_who(model, Data.i(event, "source", -1)), name_of, where]


## The word that floats over a unit arriving in a fight.
static func arrival_word(event: Dictionary) -> String:
	if event.has("came_out"):
		return "Out!"
	if event.has("landed"):
		return "Home!"
	return "Split!" if event.has("split") else "Summoned"


## The slip on a fight's tile: how many are inside it.
static func held_slip(view: Dictionary) -> String:
	var held: int = Data.i(view, "held", 0)
	return "In %d" % held if held > 0 else ""


func _attack(event: Dictionary, model: CombatModel) -> String:
	var text: String = (
		"%s attacks %s"
		% [_who(model, Data.i(event, "attacker", -1)), _who(model, Data.i(event, "defender", -1))]
	)
	if Data.b(event, "pack"):
		text += " in a Pack attack"
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
	if kind == "thorns":
		text += " with Bristle"
	elif kind != "attack":
		text += " with %s" % kind.capitalize()
	var modifiers: Array = Data.a(event, "modifiers")
	if not modifiers.is_empty() and raw != amount:
		var names: PackedStringArray = []
		for item: Variant in modifiers:
			names.append(str(item).capitalize())
		text += " (%s took it from %d)" % [" and ".join(names), raw]
	return text + ": %d Health left." % maxi(Data.i(event, "health_after", 0), 0)


func _end(event: Dictionary) -> String:
	var winner: int = Data.i(event, "winner", -1)
	var prefix: String = ""
	if Data.s(event, "reason") == "no_attacks":
		prefix = "No unit left can attack. "
	if winner < 0:
		return (
			(
				"[b]%sTie. Each hero takes %d round-toll damage.[/b]"
				% [prefix, Data.i(event, "damage")]
			)
			if Data.i(event, "damage") > 0
			else "[b]%sTie. No damage.[/b]" % prefix
		)
	var note: String = (
		" (round toll %d before cap)" % Data.i(event, "round_toll")
		if Data.i(event, "round_toll") > 0
		else ""
	)
	return (
		"[b]%sWinner: %s, %d damage%s.[/b]"
		% [prefix, _side(winner), Data.i(event, "damage", 0), note]
	)


static func stat_delta_text(attack_delta: int, health_delta: int) -> String:
	return "%s/%s" % [_signed(attack_delta), _signed(health_delta)]


static func _signed(n: int) -> String:
	return ("+%d" % n) if n >= 0 else str(n)


static func phase_word(name: String) -> String:
	if name == "bell":
		return "At the bell"
	return "Start of Combat" if name == "start_of_combat" else "Attacks"
