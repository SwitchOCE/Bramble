class_name SoakContent
extends RefCounted
## Test cards for the soak: one pool unit per trigger, one per effect, a roster of filler heroes.
## They hold no design; they exist so that bots reach every trigger and effect in ordinary games.
## Each effect's entry is named "effect:<name>" or "trigger:<name>", and the soak counts firings
## by those names (its coverage check).

const TOKEN: String = "soak_token"
const HEROES: int = 30
const TRIBES: Array[String] = ["Oozes", "Birds", "Hunters", "Fairies", "Hedgerow folk", "Bog folk"]
const NEVER: Array[String] = ["aura", "activated", "cast"]
const FRIEND: Dictionary = {"select": "friendly", "pick": "random"}
const ACROSS_FOE: Dictionary = {"select": "enemies", "pick": "random"}


static func build() -> UnitLibrary:
	var library: UnitLibrary = UnitLibrary.load_dir()
	_register(library, TOKEN, [], 1, false)
	var index: int = 0
	for trigger: Variant in EffectSchema.section("triggers"):
		if not NEVER.has(str(trigger)):
			var entry: Dictionary = _trigger_entry(str(trigger))
			_register(library, "soak_%s" % trigger, [entry], index, true)
			index += 1
	for effect: Variant in EffectSchema.section("effects"):
		var entry: Dictionary = _effect_entry(str(effect))
		_register(library, "soak_do_%s" % effect, [entry], index, true)
		index += 1
	_add_heroes(library)
	return library


## A trigger's soak unit: a small buff, or gold outside combat, so the trigger's the thing tested.
static func _trigger_entry(trigger: String) -> Dictionary:
	var entry: Dictionary = {"id": "effect", "name": "trigger:%s" % trigger, "trigger": trigger}
	var info: Dictionary = EffectSchema.section("triggers")[trigger]
	if str(info.get("subject", "")) == "other":
		entry["subject"] = "any"
	entry["do"] = {"effect": "buff", "attack": 1, "health": 1, "target": FRIEND}
	return entry


static func _effect_entry(effect: String) -> Dictionary:
	var info: Dictionary = EffectSchema.section("effects")[effect]
	var phase: String = str(info["phase"])
	var trigger: String = "start_of_combat" if phase == "combat" else "on_play"
	var entry: Dictionary = {"id": "effect", "name": "effect:%s" % effect, "trigger": trigger}
	entry["do"] = _step(effect)
	return entry


## One legal step per effect.
static func _step(effect: String) -> Dictionary:
	match effect:
		"buff":
			return {"effect": effect, "attack": 1, "health": 1, "target": FRIEND}
		"summon":
			return {"effect": effect, "unit": TOKEN}
		"gold":
			return {"effect": effect, "amount": 1, "when": "next_turn"}
		"add_card":
			return {"effect": effect, "card": "sample_growth"}
		"grant":
			var granted: Dictionary = {
				"id": "effect",
				"name": "granted",
				"trigger": "end_of_turn",
				"do": {"effect": "gold", "amount": 1, "when": "next_turn"},
			}
			return {
				"effect": effect, "mechanic": granted, "target": FRIEND, "duration": "permanent"
			}
		"status":
			return {"effect": effect, "status": "stun", "target": ACROSS_FOE}
		"damage":
			return {"effect": effect, "amount": 1, "target": {"select": "others", "pick": "random"}}
		"swap":
			return {"effect": effect, "target": {"select": "others", "pick": "random"}}
		"move":
			return {"effect": effect, "to": "back"}
		"slot_effect":
			return {"effect": effect, "attack": 1, "health": 1, "target": FRIEND}
		"discover":
			return {"effect": effect, "count": 3, "tier": "current"}
		"rule":
			return {
				"effect": effect,
				"query": "refresh_cost",
				"op": "add",
				"value": -1,
				"duration": "turn"
			}
	return _slice_step(effect)


## The slice's effects. `refresh_keep` needs an aim, so here it does nothing and only proves that.
static func _slice_step(effect: String) -> Dictionary:
	match effect:
		"pass":
			return {"effect": effect, "attack": 1, "health": 1}
		"multiply":
			return {"effect": effect, "factor": 2, "target": {"select": "self"}}
		"wait_in_slot":
			return {"effect": effect, "turns": 1, "attack": 1, "health": 1, "target": FRIEND}
		"burn_gold":
			return {"effect": effect, "above": 8}
		"borrow":
			return {"effect": effect, "amount": 1, "repay": 1}
		"borrow_attack":
			return {"effect": effect, "target": FRIEND}
		"bring_home":
			return {"effect": effect, "count": 1}
	return {"effect": effect}


static func _add_heroes(library: UnitLibrary) -> void:
	for index: int in HEROES:
		var hero: Dictionary = {
			"id": "soak_hero_%02d" % index,
			"name": "Soak hero %d" % index,
			"text": "",
			"armor": index % 4,
			"power": _power(index),
		}
		library.register_hero(hero)


static func _power(index: int) -> Dictionary:
	match index % 5:
		0:
			var step: Dictionary = {"effect": "free_refresh"}
			return {"kind": "activated", "cost": 1, "uses_per_turn": 1, "do": step}
		1:
			var entry: Dictionary = {
				"trigger": "start_of_turn", "do": {"effect": "add_card", "card": "sample_acorn"}
			}
			return {"kind": "passive", "effects": [entry]}
		2:
			var rule: Dictionary = {"query": "income", "op": "add", "value": 1}
			return {"kind": "passive", "rules": [rule]}
		3:
			var entry: Dictionary = {
				"trigger": "start_of_combat",
				"do": {"effect": "buff", "attack": 1, "target": {"select": "friendly"}},
			}
			return {"kind": "passive", "effects": [entry]}
	var paint: Dictionary = {"effect": "slot_effect", "attack": 1, "health": 1, "at": "chosen"}
	return {"kind": "activated", "cost": 0, "uses_per_turn": 1, "aim": "any_slot", "do": paint}


static func _register(
	library: UnitLibrary, id: String, mechanics: Array, index: int, in_pool: bool
) -> void:
	_check(library.register_unit(_unit(id, mechanics, index, in_pool)))


static func _unit(id: String, mechanics: Array, index: int, in_pool: bool) -> Dictionary:
	return {
		"id": id,
		"name": id,
		"tier": 1 + index % 3,
		"attack": 1 + index % 3,
		"health": 2 + index % 3,
		"tribes": [TRIBES[index % TRIBES.size()]] if index % 7 != 0 else [],
		"text": "",
		"golden_text": "",
		"mechanics": mechanics,
		"keywords": [],
		"row_hint": null,
		"pool": in_pool,
		"priority": null,
		"skeleton": false,
	}


static func _check(problem: String) -> void:
	if problem != "":
		push_error("soak content: %s" % problem)
