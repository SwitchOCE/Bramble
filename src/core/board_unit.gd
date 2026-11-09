class_name BoardUnit
extends RefCounted
## What recruit and combat units share: the stat layers (architecture-notes 4, prototype-lessons
## section 4). Attack and Health are computed on read from base (doubled if golden), permanent
## buffs, "this combat" buffs and auras, so the order effects arrive in can't change the result.
## Damage is its own number, so losing a buff or aura never needs a subtraction to undo.
## Assigning `attack` or `health` directly writes the permanent layer.

## 1.2.4 the hard maximum for Attack and Health.
const STAT_CLAMP: int = 1000000000

## Optional QA attribution observer; inert during normal play.
static var probe_hook: Callable = Callable()

var def: Dictionary = {}
var golden: bool = false
var base_attack: int = 0
var base_health: int = 0
var perm_attack: int = 0
var perm_health: int = 0
## Standing tribe bonuses are separate: triples never multiply them.
var tribe_attack: int = 0
var tribe_health: int = 0
var combat_attack: int = 0
var combat_health: int = 0
var aura_attack: int = 0
var aura_health: int = 0
## Health lost so far this combat (damage and Health loss).
var damage_taken: int = 0
## Shown numbers and effect counters (6.2 counters).
var counters: Dictionary = {}
## How often each "limit" effect fired this turn (or this combat, on a combat unit).
var limits: Dictionary = {}
## Keywords and mechanics gained after the unit was made:
## {"entry": mechanic entry, "golden": bool, "keyword": String, "combat_only": bool}.
var grants: Array[Dictionary] = []
var attack: int:
	get = _get_attack,
	set = _set_attack
var health: int:
	get = _get_health,
	set = _set_health
var max_health: int:
	get = _get_max_health


func set_base(unit_def: Dictionary, is_golden: bool) -> void:
	def = unit_def
	golden = is_golden
	base_attack = unit_def["attack"]
	base_health = unit_def["health"]
	_cap_permanent()


## 7.3.4: base doubled while golden.
func golden_factor() -> int:
	return 2 if golden else 1


func base_attack_now() -> int:
	return base_attack * golden_factor()


func base_health_now() -> int:
	return base_health * golden_factor()


## A permanent change: it stays on the recruit board (12.1.1).
func add_permanent(attack_delta: int, health_delta: int) -> void:
	if probe_hook.is_valid():
		probe_hook.call(self, attack_delta, health_delta)
	perm_attack += attack_delta
	perm_health += health_delta
	_cap_permanent()


## A "this combat" change (12.1.1).
func add_combat(attack_delta: int, health_delta: int) -> void:
	combat_attack += attack_delta
	combat_health += health_delta


## 12.2.1: the aura layer's new value. Losing a Health aura lowers maximum Health and keeps
## current Health if it still fits, but never takes Health below 1 (SPEC milestone B picks).
func set_aura(attack_bonus: int, health_bonus: int) -> void:
	var lost_health: bool = health_bonus < aura_health
	var before: int = _get_health()
	aura_attack = attack_bonus
	aura_health = health_bonus
	if lost_health and before > 0:
		damage_taken = _raw_health() - clampi(before, 1, _get_max_health())


func tier() -> int:
	var value: int = def["tier"]
	return value


func tribes() -> Array:
	var value: Array = def["tribes"]
	return value


func has_tribe(tribe: String) -> bool:
	return tribes().has(tribe)


func def_id() -> String:
	var id: String = def["id"]
	return id


func _raw_health() -> int:
	var factor: int = 2 if golden else 1
	return base_health * factor + perm_health + tribe_health + combat_health + aura_health


func _get_attack() -> int:
	var factor: int = 2 if golden else 1
	var raw: int = base_attack * factor + perm_attack + tribe_attack + combat_attack + aura_attack
	return clampi(raw, 0, STAT_CLAMP)


func _set_attack(value: int) -> void:
	add_permanent(value - _get_attack(), 0)


## Read in every death check of every fight, so it repeats _raw_health inline (one call fewer).
func _get_health() -> int:
	var factor: int = 2 if golden else 1
	var raw: int = base_health * factor + perm_health + tribe_health + combat_health + aura_health
	return mini(raw - damage_taken, STAT_CLAMP)


func _set_health(value: int) -> void:
	add_permanent(0, value - _get_health())


func _get_max_health() -> int:
	return clampi(_raw_health(), 1, STAT_CLAMP)


## Printed permanent-buff ceilings double on golden; combat and slot buffs stay separate.
func can_gain_permanent() -> bool:
	var ceiling: int = CoreUtil.to_int(def.get("permanent_buff_cap", 0)) * golden_factor()
	return ceiling <= 0 or perm_attack < ceiling or perm_health < ceiling


func _cap_permanent() -> void:
	var ceiling: int = CoreUtil.to_int(def.get("permanent_buff_cap", 0)) * golden_factor()
	if ceiling > 0:
		perm_attack = mini(perm_attack, ceiling)
		perm_health = mini(perm_health, ceiling)
