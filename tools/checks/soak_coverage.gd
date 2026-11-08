class_name SoakCoverage
extends RefCounted
## Which cards and keywords of the slice actually did something in a soak. A card counts when its
## effect ran, a spell or item when played, a token when summoned, a rule-only hero when in a game.

const KEYWORD_ITEMS: PackedStringArray = ["acorn", "stash", "great_hoard"]

var _cards: Dictionary = {}
var _keywords: Dictionary = {}
var _purchases: Dictionary = {}
var _snail_gains: int = 0
## Native card payouts only; borrowed text on other cards is excluded.
var _mire_gold: Dictionary = {
	"bridge_toad": {"starting_copy_fights": 0, "payouts": 0, "gold": 0, "starting_gold": 0},
	"peat_cutter": {"starting_copy_fights": 0, "payouts": 0, "gold": 0, "starting_gold": 0},
}
var _engines: Dictionary = {"harvest_supper": 0, "last_four": 0, "last_stand": 0, "last_blow": 0}


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
	if type == "cast" and str(fields.get("card", "")) == "harvest_supper":
		_engines["harvest_supper"] += 1
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
	var mire_sources: Dictionary = {}
	for event: Dictionary in events:
		if str(event["type"]) == "combat_end":
			if (
				event.has("alive")
				and CoreUtil.to_int(event["alive"]) <= 4
				and CoreUtil.to_int(event.get("damage_cap", -1)) == 0
			):
				_engines["last_four"] += 1
			if CoreUtil.to_bool(event.get("last_blow", false)):
				_engines["last_blow"] += 1
			var saves: Array = event.get("last_stand_sides", [])
			_engines["last_stand"] += saves.size()
		match str(event["type"]):
			"combat_start":
				_note_start(event, units)
				_note_mire_start(event, heroes, mire_sources)
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
				var side: int = CoreUtil.to_int(event["side"])
				if heroes[side] != "":
					_note_mire_source(unit, mire_sources, false)
				units[unit["uid"]] = str(unit["def_id"])
				_note_card(str(unit["def_id"]))
			"trigger":
				_note_card(str(units.get(event["uid"], "")))
				var mechanic: String = str(event.get("mechanic", ""))
				_note_mire_payout(event, mire_sources)
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


## Actual shop purchases, separate from activations: a silent effect need not be an absent card.
func purchase_counts() -> Dictionary:
	return _purchases


func snail_gains() -> int:
	return _snail_gains


## Called by BoardUpkeep only after the actual aura layer receives a Monarch contribution.
func note_aura(_unit: RecruitUnit, monarch_bonus: Vector2i) -> void:
	if monarch_bonus.x > 0 or monarch_bonus.y > 0:
		_note_card("fairy_monarch")


func engine_counts() -> Dictionary:
	var counts: Dictionary = _engines.duplicate()
	counts["mire_gold_watch"] = mire_gold_counts()
	return counts


## Existing soak report prints this under engine counts. These are chaos-soak exposure rates,
## not lifetime balance estimates. Golden copies count once per fight and pay their printed 2.
func mire_gold_counts() -> Dictionary:
	var out: Dictionary = _mire_gold.duplicate(true)
	for id: String in out:
		var row: Dictionary = out[id]
		var purchases: int = CoreUtil.to_int(_purchases.get(id, 0))
		var exposures: int = CoreUtil.to_int(row["starting_copy_fights"])
		row["purchases"] = purchases
		row["starting_gold_per_copy_fight"] = (
			float(CoreUtil.to_int(row["starting_gold"])) / exposures if exposures > 0 else 0.0
		)
		row["rough_gold_per_purchase"] = (
			float(CoreUtil.to_int(row["gold"])) / purchases if purchases > 0 else 0.0
		)
	return out


func _note_mire_start(event: Dictionary, heroes: Array[String], sources: Dictionary) -> void:
	var boards: Array = event["boards"]
	for side: int in 2:
		if heroes[side] == "":
			continue
		var row: Array = boards[side]
		for value: Variant in row:
			if value != null:
				var view: Dictionary = value
				_note_mire_source(view, sources, true)


func _note_mire_source(view: Dictionary, sources: Dictionary, starting: bool) -> void:
	var id: String = str(view["def_id"])
	if not _mire_gold.has(id):
		return
	var uid: int = CoreUtil.to_int(view["uid"])
	if starting:
		var row: Dictionary = _mire_gold[id]
		row["starting_copy_fights"] += 1
	var old: Dictionary = sources.get(uid, {})
	sources[uid] = {
		"id": id,
		"gold": 2 if CoreUtil.to_bool(view.get("golden", false)) else 1,
		"starting": starting or CoreUtil.to_bool(old.get("starting", false)),
	}


func _note_mire_payout(event: Dictionary, sources: Dictionary) -> void:
	var uid: int = CoreUtil.to_int(event["uid"])
	var source: Dictionary = sources.get(uid, {})
	if source.is_empty():
		return
	var id: String = str(source["id"])
	var wanted: String = "bridge_toad" if id == "bridge_toad" else "peat_cutting"
	if str(event.get("mechanic", "")) != wanted:
		return
	var row: Dictionary = _mire_gold[id]
	var gold: int = CoreUtil.to_int(source["gold"])
	row["payouts"] += 1
	row["gold"] += gold
	if CoreUtil.to_bool(source["starting"]):
		row["starting_gold"] += gold


func engines_silent() -> PackedStringArray:
	var out: PackedStringArray = []
	for rule: String in _engines:
		if CoreUtil.to_int(_engines[rule]) == 0:
			out.append(rule)
	return out
