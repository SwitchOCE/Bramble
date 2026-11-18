class_name BrowserCatalog
extends RefCounted
## Printed cards from the same content and view adapter as the shop. The system's hidden
## Triple Reward is not a browsable spell; tokens are included, as in the approved browser.

const TRIBE_ORDER: PackedStringArray = ["badger", "mouse", "pigeon", "locust", "thorn"]

var cards: Array[Dictionary] = []


func _init(content: GameContent) -> void:
	# A separate session only formats printed cards. Browsing never reads or mutates a live game.
	var session: GameSession = content.new_session(0)
	for card_id: StringName in content.library.ids():
		var def: UnitDef = content.library.get_card(card_id)
		if def.is_spell() and not def.offered:
			continue
		var card: Dictionary = ViewAdapter.card_from_id(content, session, String(card_id))
		card["tier"] = def.tier
		card["token"] = def.token
		card["tribe"] = content.folder_of(String(card_id))
		card["types"] = Array(def.types)
		cards.append(card)
	cards.sort_custom(_before)


func matching(
	spells: bool = false, tribe: String = "", tier: int = 0, query: String = ""
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var needle: String = query.strip_edges().to_lower()
	for card: Dictionary in cards:
		if CoreUtil.to_bool(card["spell"]) != spells:
			continue
		if not spells and tribe != "" and str(card["tribe"]) != tribe:
			continue
		if tier != 0 and CoreUtil.to_int(card["tier"]) != tier:
			continue
		if (
			needle != ""
			and not (str(card["name"]) + " " + str(card["text"])).to_lower().contains(needle)
		):
			continue
		out.append(card)
	return out


static func _before(a: Dictionary, b: Dictionary) -> bool:
	if a["token"] != b["token"]:
		return not CoreUtil.to_bool(a["token"])
	if a["tier"] != b["tier"]:
		return CoreUtil.to_int(a["tier"]) < CoreUtil.to_int(b["tier"])
	var ai: int = TRIBE_ORDER.find(str(a["tribe"]))
	var bi: int = TRIBE_ORDER.find(str(b["tribe"]))
	if ai != bi:
		return ai < bi
	return str(a["name"]).naturalnocasecmp_to(str(b["name"])) < 0
