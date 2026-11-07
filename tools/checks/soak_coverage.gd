class_name SoakCoverage
extends RefCounted
## Which cards and keywords of the slice actually did something in a soak. A card counts when its
## effect ran, a spell or item when played, a token when summoned, a rule-only hero when in a game.

const KEYWORD_ITEMS: PackedStringArray = ["acorn", "stash", "great_hoard"]

var _cards: Dictionary = {}
var _keywords: Dictionary = {}
var _purchases: Dictionary = {}
var _snail_gains: int = 0


## A line of a player's recruit log. `hero` is the player's hero id.
func note_recruit(hero: String, type: String, fields: Dictionary) -> void:
	match type:
		"buy":
			var id: String = str(fields.get("unit", ""))
			_purchases[id] = CoreUtil.to_int(_purchases.get(id, 0)) + 1
		"trigger":
			var source: String = str(fields.get("source", ""))
			_note_card(source if source != "" else hero)
			if source == "pennywort_snail" and str(fields.get("mechanic", "")) == "savings":
				_snail_gains += 1
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
			"summon":
				var unit: Dictionary = event["unit"]
				units[unit["uid"]] = str(unit["def_id"])
				_note_card(str(unit["def_id"]))
			"trigger":
				_note_card(str(units.get(event["uid"], "")))
				if str(event.get("mechanic", "")) == "swoop":
					_note_keyword("Swoop")
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


## Actual shop purchases, separate from activations: a silent effect need not be an absent card.
func purchase_counts() -> Dictionary:
	return _purchases


func snail_gains() -> int:
	return _snail_gains
