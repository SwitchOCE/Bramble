class_name UnitLibrary
extends RefCounted
## The cards a lobby can use, loaded from JSON data and checked against the mechanics'
## declared parameter kinds. Data shape (one object per card):
##   {"id", "name", "tier", "attack", "health", "types": [], "tribes": [], "keywords": [],
##    "effects": [{"mechanic": id, <params>}], "token": bool, "kind": "unit" | "spell",
##    "cost": int (spells), "offered": bool (spells the shop never offers), "text"}
## Load errors are kept in `errors`; a library with errors must not be played.

const TRIPLE_REWARD_ID: StringName = &"triple_reward"
## The core's own cards, in every library: the Triple Reward spell (7.3.6).
const SYSTEM_CARDS: Array[Dictionary] = [
	{
		"id": "triple_reward",
		"name": "Triple Reward",
		"kind": "spell",
		"tier": 1,
		"cost": 0,
		"offered": false,
		"effects": [{"mechanic": "triple_reward"}],
	},
]

var errors: PackedStringArray = []
var _cards: Dictionary = {}
var _order: Array[StringName] = []


## A library with only the system cards; add_cards() adds the rest.
static func with_system_cards(registry: MechanicRegistry) -> UnitLibrary:
	var library := UnitLibrary.new()
	library.add_cards(SYSTEM_CARDS, registry)
	return library


static func from_file(path: String, registry: MechanicRegistry) -> UnitLibrary:
	var library: UnitLibrary = with_system_cards(registry)
	if not FileAccess.file_exists(path):
		library.errors.append("no card file at %s" % path)
		return library
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var root: Dictionary = CoreUtil.to_dict(parsed)
	if root.is_empty():
		library.errors.append("%s is not a JSON object" % path)
		return library
	library.add_cards(CoreUtil.to_array(root.get("cards", [])), registry)
	return library


func add_cards(raw_cards: Array, registry: MechanicRegistry) -> void:
	for raw: Variant in raw_cards:
		var card: UnitDef = _parse(CoreUtil.to_dict(raw), registry)
		if card == null:
			continue
		if _cards.has(card.id):
			errors.append("duplicate card id %s" % card.id)
			continue
		_cards[card.id] = card
		_order.append(card.id)


func _parse(raw: Dictionary, registry: MechanicRegistry) -> UnitDef:
	var card := UnitDef.new()
	card.id = StringName(CoreUtil.to_text(raw.get("id", "")))
	if card.id == &"":
		errors.append("a card has no id")
		return null
	card.name = CoreUtil.to_text(raw.get("name", String(card.id)))
	card.kind = UnitDef.Kind.SPELL if raw.get("kind", "unit") == "spell" else UnitDef.Kind.UNIT
	card.tier = CoreUtil.to_int(raw.get("tier", 1))
	card.attack = CoreUtil.to_int(raw.get("attack", 0))
	card.health = CoreUtil.to_int(raw.get("health", 1))
	card.token = CoreUtil.to_bool(raw.get("token", false))
	card.combines = CoreUtil.to_bool(raw.get("combines", true))
	card.cost = CoreUtil.to_int(raw.get("cost", 0))
	card.offered = CoreUtil.to_bool(raw.get("offered", true))
	card.text = CoreUtil.to_text(raw.get("text", ""))
	card.golden_text = CoreUtil.to_text(raw.get("golden_text", ""))
	for line: Variant in CoreUtil.to_array(raw.get("reminders", [])):
		card.reminders.append(str(line))
	for type_name: Variant in CoreUtil.to_array(raw.get("types", [])):
		card.types.append(str(type_name))
	for tribe: Variant in CoreUtil.to_array(raw.get("tribes", [])):
		card.tribes.append(str(tribe))
	var ok: bool = card.tier >= 1 and card.tier <= 7 and (card.health >= 1 or card.is_spell())
	if not ok:
		errors.append("%s: tier must be 1-7 and Health at least 1" % card.id)
	for keyword: Variant in CoreUtil.to_array(raw.get("keywords", [])):
		var mechanic_id := StringName(str(keyword))
		card.keywords.append(mechanic_id)
		ok = _add_mechanic(card, mechanic_id, {}, registry) and ok
	for effect: Variant in CoreUtil.to_array(raw.get("effects", [])):
		var params: Dictionary = CoreUtil.to_dict(effect).duplicate()
		var mechanic_id := StringName(CoreUtil.to_text(params.get("mechanic", "")))
		params.erase("mechanic")
		ok = _add_mechanic(card, mechanic_id, params, registry) and ok
	return card if ok else null


func _add_mechanic(
	card: UnitDef, mechanic_id: StringName, raw: Dictionary, registry: MechanicRegistry
) -> bool:
	var where: String = "%s/%s" % [card.id, mechanic_id]
	if not registry.has(mechanic_id):
		errors.append("%s: no such mechanic" % where)
		return false
	var params: MechanicParams = MechanicParams.parse(
		raw, registry.kinds_of(mechanic_id), where, errors
	)
	if params == null:
		return false
	card.mechanics.append(MechanicSpec.new(mechanic_id, params))
	return true


func has(card_id: StringName) -> bool:
	return _cards.has(card_id)


func get_card(card_id: StringName) -> UnitDef:
	var found: UnitDef = _cards.get(card_id, null)
	return found


func ids() -> Array[StringName]:
	return _order.duplicate()


## The drawable cards of one kind, in library order.
func drawable_cards(spells: bool) -> Array[UnitDef]:
	var out: Array[UnitDef] = []
	for card_id: StringName in _order:
		var found: UnitDef = _cards[card_id]
		if found.can_be_drawn() and found.is_spell() == spells:
			out.append(found)
	return out
