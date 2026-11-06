class_name PlayerState
extends RefCounted
## One player's game state: hero, economy, shop, hand and the 7-slot board (index = slot).

const LOG_CAP: int = 200

var id: int = 0
var name: String = ""
var personality: String = "human"
var is_human: bool = false
var health: int = 30
var gold: int = 0
var tier: int = 1
var upgrade_cost: int = 0
var paid_refreshes: int = 0
var frozen: bool = false
var freezes_left: int = 0
var shop: Array[RecruitUnit] = []
var hand: Array[RecruitUnit] = []
var board: Array[RecruitUnit] = []
var alive: bool = true
## 0 while alive (shown as null).
var placement: int = 0
## "win", "loss", "tie" or "" (shown as null).
var last_result: String = ""
## Last opponents, most recent last (-1 is the ghost).
var recent_opponents: Array[int] = []
var shop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var bot_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Data effects' random choices (a separate stream, so they can't shift the shop).
var effect_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## The round this player's Recruit Phase belongs to.
var round_number: int = 0
## Unpaid refreshes waiting to be used (4.4.5).
var free_refreshes: int = 0
## Gold that arrives at the start of the next turn.
var gold_next_turn: int = 0
var gold_spent_turn: int = 0
var gold_spent_game: int = 0
## Counters and limits for an owner that isn't a unit (a hero).
var owner_counters: Dictionary = {}
var owner_limits: Dictionary = {}
## This phase's recruit events, oldest first, for the UI and tools/play ({"type", ...}).
var recruit_log: Array[Dictionary] = []


func _init() -> void:
	board.resize(BoardGeometry.SLOTS)


func board_count() -> int:
	var count: int = 0
	for unit: RecruitUnit in board:
		if unit != null:
			count += 1
	return count


func first_empty_slot() -> int:
	for slot: int in BoardGeometry.SLOTS:
		if board[slot] == null:
			return slot
	return -1


## All units the player holds on board and in hand.
func owned_units() -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	for unit: RecruitUnit in board:
		if unit != null:
			out.append(unit)
	out.append_array(hand)
	return out


## The board as CombatSandbox-style entries (null or {"def_id", "golden", "attack", "health"}).
func combat_board() -> Array:
	var out: Array = []
	for unit: RecruitUnit in board:
		if unit == null:
			out.append(null)
		else:
			out.append(unit.combat_spec())
	return out


## Notes something that happened this phase. Capped, so a trigger loop can't eat memory.
func log_event(type: String, fields: Dictionary = {}) -> void:
	if recruit_log.size() >= LOG_CAP:
		return
	var entry: Dictionary = fields.duplicate()
	entry["type"] = type
	recruit_log.append(entry)


## 6.4 standing.
func standing() -> Dictionary:
	return {
		"player_id": id,
		"name": name,
		"is_human": is_human,
		"personality": personality,
		"health": health,
		"tier": tier,
		"alive": alive,
		"placement": CoreUtil.int_or_null(placement, 0),
		"last_result": CoreUtil.string_or_null(last_result),
	}
