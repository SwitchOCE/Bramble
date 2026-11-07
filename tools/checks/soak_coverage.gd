class_name SoakCoverage
extends RefCounted
## Which cards and keywords of the slice actually did something in a soak. A card counts when its
## effect ran, a spell or item when played, a token when summoned, a rule-only hero when in a game.

const KEYWORD_ITEMS: PackedStringArray = ["acorn", "stash", "great_hoard"]

var _cards: Dictionary = {}
var _keywords: Dictionary = {}


## Named synthetic effects and native event aliases both prove that a trigger was reached.
## A native Take need not belong to the synthetic soak_on_take card.
static func gaps(
	recruit: Dictionary, triggers: Dictionary, event_types: Dictionary
) -> PackedStringArray:
	var seen: Dictionary = recruit.duplicate()
	seen.merge(triggers)
	if CoreUtil.to_int(event_types.get("take", 0)) > 0:
		seen["trigger:on_take"] = true
	var out: PackedStringArray = []
	for type: String in ["cast", "power", "discover", "chose", "slot_effect"]:
		if not seen.has(type):
			out.append(type)
	for trigger: Variant in EffectSchema.section("triggers"):
		if not SoakContent.NEVER.has(str(trigger)) and not seen.has("trigger:%s" % trigger):
			out.append("trigger:%s" % trigger)
	for effect: Variant in EffectSchema.section("effects"):
		if not seen.has("effect:%s" % effect):
			out.append("effect:%s" % effect)
	return out


## A line of a player's recruit log. `hero` is the player's hero id.
func note_recruit(hero: String, type: String, fields: Dictionary) -> void:
	match type:
		"trigger":
			var source: String = str(fields.get("source", ""))
			_note_card(source if source != "" else hero)
			if str(fields.get("mechanic", "")) == "shy":
				_note_keyword("Shy")
		"cast", "eat":
			_note_card(str(fields.get("card", "")))
		"swallow":
			_note_card(str(fields.get("by", "")))
			_note_keyword("Belly")
		"fly_south":
			_note_keyword("Fly South")
			_note_keyword("Nest")
		"power":
			_note_card(hero)
		"summon":
			_note_card(str(fields.get("unit", "")))
		"card":
			if KEYWORD_ITEMS.has(str(fields.get("card", ""))):
				_note_keyword("Acorn")
		"combine":
			_note_keyword("Acorn")
		"spill":
			_note_keyword("Spill")
		"pass":
			_note_keyword("Pass")
		"band":
			_note_keyword("Rainbow")
		"slot_effect":
			if str(fields.get("name", "")) == BoardUpkeep.RING:
				_note_keyword("Ring")


## A fight's events; `heroes` is each side's hero id ("" for a ghost).
func note_fight(events: Array[Dictionary], heroes: Array[String]) -> void:
	var units: Dictionary = {}
	for event: Dictionary in events:
		match str(event["type"]):
			"combat_start":
				_note_start(event, units)
			"transform":
				var unit: Dictionary = event["unit"]
				units[unit["uid"]] = str(unit["def_id"])
				_note_card(str(unit["def_id"]))
			"bog_patch":
				_note_keyword("Mire")
			"quarry_marked":
				_note_keyword("Quarry")
				_note_card(str(units.get(event["source"], "")))
			"summon":
				var unit: Dictionary = event["unit"]
				units[unit["uid"]] = str(unit["def_id"])
				_note_card(str(unit["def_id"]))
			"trigger":
				_note_card(str(units.get(event["uid"], "")))
				var mechanic: String = str(event.get("mechanic", ""))
				for keyword: String in ["Swoop", "Bitter", "Snap", "Pack", "Pounce"]:
					if mechanic == keyword.to_lower():
						_note_keyword(keyword)
			"goose_strike":
				_note_card(HeldUnits.GOOSE)
			"side_trigger":
				_note_card(heroes[CoreUtil.to_int(event["side"])])
			"spill":
				_note_keyword("Spill")
			"slot_hex":
				_note_keyword("Hex")
			"health_loss":
				if str(event.get("cause", "")) == "nightshade":
					_note_keyword("Nightshade")


func _note_start(event: Dictionary, units: Dictionary) -> void:
	var boards: Array = event["boards"]
	for side: int in 2:
		var row: Array = boards[side]
		for value: Variant in row:
			if value != null:
				var view: Dictionary = value
				units[view["uid"]] = str(view["def_id"])
				if str(view["def_id"]) == HeldUnits.EGG:
					_note_card(HeldUnits.EGG)


## Heroes whose whole power is a rule are in effect from the moment they're in a game.
func note_hero(hero: Dictionary) -> void:
	var power: Dictionary = hero.get("power", {})
	if power.has("rules"):
		_note_card(str(hero.get("id", "")))


## Stats that are simply there, with no event: the Treasurer counting the Larder.
func note_board(player: PlayerState) -> void:
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id("larder_stats") and player.larder() >= 2:
			_note_card(unit.def_id())
		if unit != null and unit.aura_attack > 0 and _reads_nests(unit):
			_note_card(unit.def_id())


static func _reads_nests(unit: RecruitUnit) -> bool:
	return unit.has_mechanic_id("redbreast") or unit.has_mechanic_id("lump")


## Every card of the slice that never fired, sorted.
func cards_silent(library: UnitLibrary) -> PackedStringArray:
	var out: PackedStringArray = []
	for unit: Dictionary in library.all_units():
		_add_silent(out, unit)
	for card: Dictionary in library.all_cards():
		_add_silent(out, card)
	for hero: Dictionary in library.all_heroes():
		_add_silent(out, hero)
	out.sort()
	return out


func _add_silent(out: PackedStringArray, card: Dictionary) -> void:
	if str(card.get("set", "")) != "":
		var id: String = str(card["id"])
		if not _cards.has(id):
			out.append(id)


func keywords_silent() -> PackedStringArray:
	var out: PackedStringArray = []
	for word: Variant in EffectSchema.section("keywords"):
		if not _keywords.has(word):
			out.append(str(word))
	out.sort()
	return out


## Counts, most-fired last, for the report.
func card_counts() -> Dictionary:
	return _cards


func _note_card(id: String) -> void:
	if id != "":
		_cards[id] = CoreUtil.to_int(_cards.get(id, 0)) + 1


func _note_keyword(word: String) -> void:
	_keywords[word] = CoreUtil.to_int(_keywords.get(word, 0)) + 1
