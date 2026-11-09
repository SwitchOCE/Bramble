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
	"mire_wait": 0.65,
	"early_spoils": 0.55,
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

## Mechanics the log names by a word, even when the unit only borrowed it (Old Brock lends Pounce).
const NAMED_TRIGGERS: Dictionary[String, String] = {
	"mire": "Mire",
	"bitter": "Bitter",
	"snap_kill": "Mired kill reward",
	"pounce": "Pounce",
	"pack": "Pack",
}
## Mechanics with no rules sentence of their own, as a short true line after the unit's name.
const TRIGGER_LINES: Dictionary[String, String] = {
	"hasty_release": "lets its prisoners go",
}
## The words before a rules colon that each mechanic answers to. A mechanic missing here, or whose
## words aren't in the card's text, logs no effect words rather than another ability's.
const MECHANIC_TRIGGERS: Dictionary[String, String] = {
	"bubble": "after this survives a hit",
	"wobbly": "after this survives a hit",
	"survive_buff_behind": "after this survives an attack",
	"changeling": "start of combat",
	"cradle_fetch": "start of combat",
	"granny": "start of combat",
	"jack_daw": "start of combat",
	"mag_pye": "start of combat",
	"sable": "start of combat",
	"sergeant": "start of combat",
	"whistlers": "start of combat",
	"grant_first_bite_in_front": "start of combat",
	"row_swap": "start of combat",
	"nightshade_mark": "start of combat",
	"hasty": "start of combat",
	"mother_goose": "start of combat",
	"lend_quarry": "start of combat",
	"urchin": "after this pricks",
	"on_attack_buff_tribe": "whenever this attacks",
	"gabble_ratchet": "when a unit on a nest dies",
	"bog_answer": "after the enemy this mires attacks this",
	"grizel": "after your pack attack kills",
	"kiss": "after a mired enemy dies",
	"peat_king": "after a mired enemy dies",
	"tiddy_mun": "after a mired enemy attacks one of your units",
	"death_summon": "when this dies",
	"pie": "when this dies",
	"jenny": "after that enemy attacks this",
	"laird": "after each take",
	"take_gold": "take",
	"poach": "take",
	"lodger": "after this pounces",
	"glutton": "after one of your hunters makes a take",
	"toll_bard": "after its quarry attacks",
	"tom_tit": "while your Eggs fight",
	"reel_mistress": "after a unit on a ring attacks",
	"syllabub": "when a unit comes out of your oozes",
	"beadle": "after you get an acorn",
	"mrs_clover": "after you summon a unit",
	"ranocchio": "after this attacks a mired enemy",
	"moss_ooze": "when a spell gives your ooze stats",
}
## The same for data effects, by their trigger.
const EFFECT_TRIGGERS: Dictionary[String, String] = {
	"start_of_combat": "start of combat",
	"on_death": "when this dies",
	"after_attack": "after this attacks",
	"on_attacked": "whenever this is attacked",
	"on_enemy_death": "after a mired enemy dies",
	"on_friendly_death": "after a friendly unit dies",
}

static var _library: UnitLibrary = null

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
## The last phase header, so the bell and Start of Combat (one phase to the player) print once.
var _last_phase: String = ""


## What fired, in the card's own words: the keyword the mechanic id names ("nightshade_mark" ->
## Nightshade), else the unit's name (Hoglet Mother's death_summon is not Bristle).
static func trigger_name(model: CombatModel, uid: int, mechanic: String) -> String:
	# A loaned keyword needn't appear on the printed card. The Pretender's death-witness
	# payment is a reward, not another attack from the dead frog.
	if NAMED_TRIGGERS.has(mechanic):
		return NAMED_TRIGGERS[mechanic]
	var word: String = keyword_for(Data.a(model.unit(uid), "keywords"), mechanic)
	return word if not word.is_empty() else model.unit_name(uid)


## The unit's own keyword that a mechanic id names ("bristle" fires Bristle), or "".
static func keyword_for(keywords: Array, mechanic: String) -> String:
	for keyword: Variant in keywords:
		var word: String = str(keyword)
		if not mechanic.is_empty() and mechanic.contains(word.to_lower().replace(" ", "_")):
			return word
	return ""


func _who(model: CombatModel, uid: int) -> String:
	var view: Dictionary = model.unit(uid)
	var side: int = Data.i(view, "side", 0)
	var colour: String = UiTheme.hex(UiTheme.LOG_SIDE_0 if side == 0 else UiTheme.LOG_SIDE_1)
	return "[color=#%s]%s[/color]" % [colour, _name_at(model, uid)]


static func _name_at(model: CombatModel, uid: int) -> String:
	var slot: int = Data.i(model.unit(uid), "slot", -1)
	var duplicates: int = 0
	for other: Dictionary in model.units.values():
		if Data.s(other, "name") == model.unit_name(uid):
			duplicates += 1
	var tag: String = (
		" (%s)" % SLOT_NAMES[slot]
		if duplicates > 1 and slot >= 0 and slot < SLOT_NAMES.size()
		else ""
	)
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
		_last_phase = ""
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
				"take": "Take",
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
			_hurt_by[Data.i(event, "target", -1)] = health_loss_cause(
				event, func(uid: int) -> String: return _name_at(model, uid)
			)


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
			var word: String = phase_word(phase_name)
			if word != _last_phase:
				line = "[b]— %s —[/b]" % word
			_last_phase = word
		"bog_patch":
			line = (
				"%s applies Mire to %s %s."
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
				"%s claims %s for the next shop."
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
				var view: Dictionary = model.unit(trigger_uid)
				line = (
					_who(model, trigger_uid)
					+ trigger_words(
						card_of(Data.s(view, "def_id")),
						Data.s(view, "text"),
						Data.s(event, "mechanic")
					)
				)
		"attack":
			line = _attack(event, model)
		"mire_wait":
			line = (
				"%s waits for %s (Mire)."
				% [_who(model, Data.i(event, "uid")), _who(model, Data.i(event, "target"))]
			)
		"early_spoils":
			line = (
				"%s: +%d gold next turn (Spoils)."
				% [_side(Data.i(event, "side")), Data.i(event, "amount")]
			)
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
			line = "%s no unit that can attack." % _has(Data.i(event, "side", 0))
		"damage":
			line = _damage(event, model)
		"health_loss":
			var target: int = Data.i(event, "target", -1)
			var after: int = Data.i(event, "health_after", 0)
			var amount: int = Data.i(event, "amount", 0)
			if Data.s(event, "cause") == "parasite":
				line = (
					"%s loses %d Health to %s: %d Health left."
					% [
						_who(model, target),
						amount,
						health_loss_cause(event, func(uid: int) -> String: return _who(model, uid)),
						maxi(after, 0)
					]
				)
			else:
				line = (
					"[color=#%s]Nightshade[/color] halves %s from %d to %d Health."
					% [
						UiTheme.hex(UiTheme.LOG_NIGHTSHADE),
						_who(model, target),
						after + amount,
						after
					]
				)
		"status":
			line = status_words(event, func(uid: int) -> String: return _who(model, uid)) + "."
		"stats":
			var attack_delta: int = Data.i(event, "attack_delta", 0)
			var health_delta: int = Data.i(event, "health_delta", 0)
			if attack_delta == 0 and health_delta == 0:
				return ""
			line = (
				"%s %s (%s), now %d/%d."
				% [
					_who(model, Data.i(event, "target", -1)),
					stat_change_text(attack_delta, health_delta),
					stat_cause(event, func(uid: int) -> String: return _who(model, uid)),
					Data.i(event, "attack", 0),
					Data.i(event, "health", 0)
				]
			)
		"permanent_reward":
			line = (
				"%s gains %s permanently (%s)."
				% [
					_who(model, Data.i(event, "target", -1)),
					stat_delta_text(Data.i(event, "attack_delta"), Data.i(event, "health_delta")),
					stat_cause(event, func(uid: int) -> String: return _who(model, uid))
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
			var loss: String = "%d Attack" % -absi(Data.i(event, "amount", 0))
			if Data.i(event, "percent_amount", 0) > 0:
				loss = "-%d%% Attack" % Data.i(event, "percent_amount")
			line = (
				"%s applies Hex to %s %s: %s."
				% [
					_who(model, Data.i(event, "source", -1)),
					_sides(Data.i(event, "side", 0)),
					SLOT_NAMES[hexed] if hexed >= 0 and hexed < 7 else "?",
					loss
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
			else:
				line = no_room_words(event, func(uid: int) -> String: return _who(model, uid)) + "."
		"no_target":
			line = (
				"%s: %s."
				% [_who(model, Data.i(event, "uid", -1)), Data.s(event, "reason", "no target")]
			)
		"pack_blocked":
			line = (
				"%s stays out of %s's Pack: Mired by %s."
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
		text += (
			"; " + ", ".join(names) + (" joins" if names.size() == 1 else " join") + " the attack"
		)
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
		text += " with its ability"
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
	if Data.b(event, "last_blow"):
		prefix = last_blow_note(event, side_names.find("You")) + " "
	if Data.s(event, "reason") == "no_attacks":
		prefix = "No unit left can attack. "
	var result: String = ""
	if winner < 0:
		result = (
			("[b]%sTie. Each hero takes %d toll damage.[/b]" % [prefix, Data.i(event, "damage")])
			if Data.i(event, "damage") > 0
			else "[b]%sTie. No damage.[/b]" % prefix
		)
	else:
		var note: String = toll_note(Data.i(event, "round_toll"), Data.i(event, "round_toll_added"))
		note = " " + note if not note.is_empty() else ""
		result = (
			"[b]%sWinner: %s, %d damage.%s[/b]"
			% [prefix, _side(winner), Data.i(event, "damage", 0), note]
		)
	for side: Variant in Data.a(event, "last_stand_sides"):
		result += "\nLast Stand: %s left on 1 Health." % _side(Data.as_int(side))
	return result


## Damage from the toll after the cap, before any hero Armor absorbs the hit.
static func toll_note(toll: int, added: int) -> String:
	if toll <= 0:
		return ""
	if added < toll:
		return "Round toll added %d of %d (limited by cap)." % [added, toll]
	return "Round toll added %d damage." % added


static func stat_delta_text(attack_delta: int, health_delta: int) -> String:
	return "%s/%s" % [_signed(attack_delta), _signed(health_delta)]


static func stat_change_text(attack_delta: int, health_delta: int) -> String:
	if health_delta == 0:
		return _signed(attack_delta) + " Attack"
	if attack_delta == 0:
		return _signed(health_delta) + " Health"
	return stat_delta_text(attack_delta, health_delta)


## Shared by the graphical and plain fight logs; internal ids never become player vocabulary.
static func stat_cause(event: Dictionary, name_of: Callable) -> String:
	var explicit: String = Data.s(event, "cause")
	if not explicit.is_empty():
		return explicit.replace("_", " ").capitalize() if explicit.contains("_") else explicit
	var parts: PackedStringArray = []
	for value: Variant in Data.a(event, "causes"):
		var cause: Dictionary = value
		var name: String = Data.s(cause, "name")
		if name == "aura":
			name = "%s's aura" % name_of.call(Data.i(cause, "source", -1))
		parts.append("%s %s" % [name, Data.s(cause, "change")])
	if not parts.is_empty():
		return ", ".join(parts)
	if event.get("source") != null:
		return "%s's ability" % name_of.call(Data.i(event, "source"))
	return "hero power"


static func health_loss_cause(event: Dictionary, name_of: Callable) -> String:
	if Data.s(event, "cause") != "parasite":
		return "Nightshade"
	var source: int = Data.i(event, "source", -1)
	return (str(name_of.call(source)) if source >= 0 else "Ichneumon Wasp") + "'s delayed kill"


static func status_words(event: Dictionary, name_of: Callable) -> String:
	var who: String = name_of.call(Data.i(event, "target", -1))
	var on: bool = Data.b(event, "on", true)
	match Data.s(event, "status"):
		"mired":
			return who + (" is Mired" if on else " is no longer Mired")
		"parasite":
			return (
				who
				+ (
					" will die after its next attack (Ichneumon Wasp)"
					if on
					else " is free of Ichneumon Wasp's delayed kill"
				)
			)
		"borrowed":
			return (
				who
				+ (
					" fights for the other side until it attacks"
					if on
					else " returns to its own side"
				)
			)
		"waiting":
			return who + (" skips its attacks until hurt" if on else " can attack again")
		"borrowed_attack":
			return (
				who
				+ (
					" uses the highest enemy Attack for its first attack"
					if on
					else " has used the highest enemy Attack"
				)
			)
	return (
		"%s %s %s"
		% [who, "gains" if on else "loses", UiTheme.status_label(Data.s(event, "status"))]
	)


static func no_room_words(event: Dictionary, name_of: Callable) -> String:
	var card: Dictionary = card_of(Data.s(event, "def_id"))
	var name: String = Data.s(card, "name", "the unit")
	var who: String = (
		name_of.call(Data.i(event, "uid", -1)) if event.get("uid") != null else "Summon"
	)
	var line: String = "%s has no room for %s" % [who, "a Peatling" if name == "Peatling" else name]
	if Data.s(event, "outcome") == "stays_inside":
		line += "; it stays inside"
	elif Data.s(event, "outcome") == "lost":
		line += "; it is lost for this fight"
	if Data.s(event, "place") == "empty_rings":
		line += ": no empty Ring slot"
	return line


static func _signed(n: int) -> String:
	return ("+%d" % n) if n >= 0 else str(n)


## What a card's triggered text does, for a log line: the part after its first "Trigger:" colon,
## up to the end of that sentence ("get 1 gold next turn"). "" when the text has no trigger.
## The card a unit was printed from, for its mechanics.
static func card_of(def_id: String) -> Dictionary:
	if _library == null:
		_library = UnitLibrary.load_dir()
	return _library.get_unit(def_id)


## What a fired mechanic does, in the card's own words: the effect after the colon or comma of the
## sentence whose trigger is that mechanic's. "" when the card has no such sentence, or the
## mechanic isn't the card's own (a lent ability), so the log never shows another ability's words.
static func effect_words(card: Dictionary, rules: String, mechanic: String) -> String:
	var trigger: String = ""
	for entry: Variant in card.get("mechanics", []):
		var mech: Dictionary = entry
		var id: String = str(mech.get("id", ""))
		if id == "effect":
			var on: String = str(mech.get("trigger", ""))
			if str(mech.get("name", on)) == mechanic:
				trigger = EFFECT_TRIGGERS.get(on, "")
		elif id == mechanic:
			trigger = MECHANIC_TRIGGERS.get(id, "")
		if not trigger.is_empty():
			break
	if trigger.is_empty():
		return ""
	var found: PackedStringArray = []
	for sentence: String in rules.split(". ", false):
		var separator: int = sentence.find(": ")
		if separator < 0:
			separator = sentence.find(", ")
		if separator > 0 and trigger in sentence.substr(0, separator).to_lower():
			found.append(sentence.substr(separator + 2).trim_suffix("."))
	return found[0] if found.size() == 1 else ""


## The log line for a fired mechanic that isn't a named keyword, after the unit's name.
static func trigger_words(card: Dictionary, rules: String, mechanic: String) -> String:
	if TRIGGER_LINES.has(mechanic):
		return " " + TRIGGER_LINES[mechanic] + "."
	var effect: String = effect_words(card, rules, mechanic)
	return ": %s." % effect if not effect.is_empty() else "'s ability goes off."


static func phase_word(name: String) -> String:
	return "Start of Combat" if name in ["bell", "start_of_combat"] else "Attacks"


static func rules_note(rules: Dictionary, names: PackedStringArray) -> String:
	var note: String = ""
	if Data.b(rules, "last_blow"):
		note += "\n" + last_blow_note(rules, names.find("You"))
	if Data.s(rules, "damage_mode") == "v05":
		note += (
			"\nDamage: %d base + %d starting survivors = %d."
			% [
				Data.i(rules, "damage_base"),
				Data.i(rules, "damage_performance"),
				Data.i(rules, "damage_uncapped"),
			]
		)
	elif rules.has("damage_base"):
		note += (
			"\nDamage: %d + %d toll = %d%s."
			% [
				Data.i(rules, "damage_base"),
				Data.i(rules, "round_toll"),
				Data.i(rules, "damage_uncapped"),
				" before cap" if Data.i(rules, "damage_cap") > 0 else ""
			]
		)
	if rules.has("alive") and Data.s(rules, "damage_mode") != "v05":
		note += (
			"\nCap lifted: %d left." % Data.i(rules, "alive")
			if Data.i(rules, "damage_cap") == 0
			else "\nDamage cap: %d." % Data.i(rules, "damage_cap")
		)
	for side: Variant in Data.a(rules, "last_stand_sides"):
		note += (
			"\nLast Stand: %s left on 1 Health." % UiTheme.short_name(names[Data.as_int(side)])
		)
	return note


## Explain an empty winner's board without implying anyone survived. No damage rules live here.
static func last_blow_note(rules: Dictionary, mine: int) -> String:
	var won: bool = Data.i(rules, "winner", -1) == mine
	var kind: String = (
		"attack" if Data.s(rules, "last_blow_kind") == "attack" else "finishing effect"
	)
	return (
		"Both boards fell. Last Blow: %s %s, so %s win."
		% ["your" if won else "their", kind, "you" if won else "they"]
	)
