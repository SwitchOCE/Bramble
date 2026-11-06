class_name PlayerState
extends RefCounted
## One player's game state: hero, economy, shop, hand and the 7-slot board (index = slot).

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
## Opponent id -> their board as last seen in a fight with this player (for BoardSearch).
var seen_boards: Dictionary = {}
## This round's opponent (Matchmaking.GHOST for the ghost, -2 before the first pairing).
var next_opponent: int = -2
## The board this round's opponent will really fight with; only set for an oracle bot.
var scouted_board: Array = []
## This round's opponent's board as it fought last round (the scouting rule); experiments only.
var scout_report: Array = []
var shop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var bot_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	board.resize(BoardGeometry.SLOTS)


func board_count() -> int:
	var count: int = 0
	for unit: RecruitUnit in board:
		if unit != null:
			count += 1
	return count


## The occupied slots, in reading order.
func occupied_slots() -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if board[slot] != null:
			out.append(slot)
	return out


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
