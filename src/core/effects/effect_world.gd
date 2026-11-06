# gdlint:disable=max-public-methods
# One method per effect verb and per question an effect can ask.
class_name EffectWorld
extends RefCounted
## What a data effect needs from the phase it runs in. RecruitContext and CombatWorld fill this
## in, so selectors, conditions and the runner are written once. `own` and `enemy` hold 7 entries
## in reading order, each a BoardUnit or null. A verb a phase doesn't support reports an error,
## which fails the gate; tools/checks/check_units.py rejects such a card before it gets here.

var trigger: String = ""
var params: Dictionary = {}
var own: Array = []
var enemy: Array = []
var hand: Array = []
var shop: Array = []
## The unit that owns this effect; null for a hero, a spell or a hand item.
var source: BoardUnit = null
## The source's slot, its last slot if it died (12.2.3); -1 for no slot (8.4.3).
var source_slot: int = -1
## The unit the event is about (the unit bought, the attacker, the dead friend).
var subject: BoardUnit = null
var subject_slot: int = -1
## The unit a spell or power was aimed at, and its slot.
var chosen: BoardUnit = null
var chosen_slot: int = -1
## The event's number (gold spent, damage).
var amount: int = 0
var rng: RandomNumberGenerator


## "recruit" or "combat": the default buff duration depends on it.
func default_duration() -> String:
	return "permanent"


func tier_now() -> int:
	return 1


func gold_now() -> int:
	return 0


func round_now() -> int:
	return 0


func paid_now() -> bool:
	return false


func paid_refreshes_now() -> int:
	return 0


func won_last_combat() -> bool:
	return false


func lost_last_combat() -> bool:
	return false


## Counters ("every") and limits ("limit") for an owner without a unit (hero, slot).
func counter_store() -> Dictionary:
	return source.counters if source != null else {}


func limit_store() -> Dictionary:
	return source.limits if source != null else {}


## The effect fires: log it, count it toward the trigger limit (9.10.2).
func announce(_name: String) -> void:
	pass


func buff(_target: BoardUnit, _attack: int, _health: int, _duration: String) -> void:
	_unsupported("buff")


func summon(_def_id: String, _count: int, _golden: bool) -> void:
	_unsupported("summon")


func gain_gold(_amount: int, _when: String) -> void:
	_unsupported("gold")


func add_card(_card: String, _count: int, _from_pool: bool) -> void:
	_unsupported("add_card")


func free_refresh(_count: int) -> void:
	_unsupported("free_refresh")


func refresh_shop() -> void:
	_unsupported("refresh_shop")


func grant(_target: BoardUnit, _entry: Dictionary, _keyword: String, _duration: String) -> void:
	_unsupported("grant")


func apply_status(_target: BoardUnit, _status: String) -> void:
	_unsupported("status")


func damage(_target: BoardUnit, _amount: int) -> void:
	_unsupported("damage")


func swap_with(_target: BoardUnit) -> void:
	_unsupported("swap")


func move_source(_to: String) -> void:
	_unsupported("move")


func _unsupported(verb: String) -> void:
	push_error("Effect '%s' can't run on trigger '%s'" % [verb, trigger])
