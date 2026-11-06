class_name HandItem
extends RefCounted
## A card that isn't a unit: a Tavern spell (6.1.5) or a hand item like an Acorn. One shape for
## both: a def with a play effect, cast from hand with an optional aim.

const AIM_NONE: String = "none"
const AIM_UNIT: String = "unit"
const AIM_EMPTY_SLOT: String = "empty_slot"
const AIM_ANY_SLOT: String = "any_slot"

var iid: int = 0
var def: Dictionary = {}
## How many pool copies it holds: 1 if it came from the spell pool, 0 if generated (5.3.6).
var pool_copies: int = 0


static func make(card_def: Dictionary, instance_id: int) -> HandItem:
	var item := HandItem.new()
	item.iid = instance_id
	item.def = card_def
	return item


func def_id() -> String:
	return str(def["id"])


func cost() -> int:
	return CoreUtil.to_int(def.get("cost", 0))


func aim() -> String:
	return str(def.get("aim", AIM_NONE))


## "spell" fires on_spell_cast when played; "item" doesn't.
func is_spell() -> bool:
	return str(def.get("kind", "spell")) == "spell"


func view() -> Dictionary:
	return {
		"iid": iid,
		"def_id": def_id(),
		"name": str(def["name"]),
		"kind": str(def.get("kind", "spell")),
		"tier": CoreUtil.to_int(def.get("tier", 1)),
		"cost": cost(),
		"aim": aim(),
		"text": str(def.get("text", "")),
		"sample": CoreUtil.to_bool(def.get("sample", false)),
	}
