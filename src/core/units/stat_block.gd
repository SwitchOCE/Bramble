class_name StatBlock
extends RefCounted
## Attack and Health computed from layers, never mutated in place (architecture notes 4;
## prototype lesson 4): base (golden already doubled) -> "set to" -> permanent additions ->
## this-turn additions -> this-combat additions -> auras -> clamp (1.2.4). Damage is kept apart:
## Health = maximum Health - damage (9.6.3).

const UNSET: int = -1

var base_attack: int = 0
var base_health: int = 0
var set_attack: int = UNSET
var set_health: int = UNSET
var perm_attack: int = 0
var perm_health: int = 0
var turn_attack: int = 0
var turn_health: int = 0
var combat_attack: int = 0
var combat_health: int = 0
var aura_attack: int = 0
var aura_health: int = 0
var stat_max: int = 1000000000


static func of(start_attack: int, start_health: int, cap: int) -> StatBlock:
	var block := StatBlock.new()
	block.base_attack = start_attack
	block.base_health = start_health
	block.stat_max = cap
	return block


func attack() -> int:
	var value: int = base_attack if set_attack == UNSET else set_attack
	value += perm_attack + turn_attack + combat_attack + aura_attack
	return clampi(value, 0, stat_max)


func max_health() -> int:
	var value: int = base_health if set_health == UNSET else set_health
	value += perm_health + turn_health + combat_health + aura_health
	return clampi(value, 0, stat_max)


## A copy for combat (9.1.1): this-turn layers have already ended (3.4.1 step 2).
func duplicate_block() -> StatBlock:
	var block := StatBlock.new()
	block.base_attack = base_attack
	block.base_health = base_health
	block.set_attack = set_attack
	block.set_health = set_health
	block.perm_attack = perm_attack
	block.perm_health = perm_health
	block.turn_attack = turn_attack
	block.turn_health = turn_health
	block.combat_attack = combat_attack
	block.combat_health = combat_health
	block.aura_attack = aura_attack
	block.aura_health = aura_health
	block.stat_max = stat_max
	return block


## 12.1.1 "this turn" ends.
func end_turn() -> void:
	turn_attack = 0
	turn_health = 0
