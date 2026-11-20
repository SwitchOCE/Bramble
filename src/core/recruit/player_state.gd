class_name PlayerState
extends RefCounted
## One player's state between and during Recruit Phases. No heroes on this track: health starts
## at the default (2.2.5) and armor at 0 (2.2.6).

const NO_CARD: StringName = &""

var id: int = 0
var health: int = 40
var armor: int = 0
var gold: int = 0
## Gold earned in a fight, added at the start of the next turn (3.2.1 with the income).
var gold_next_turn: int = 0
## The last fight's report, used once when this player next recruits.
var last_fight_report: FightReport
var tier: int = 1
## 4.6.3 turns waited on the current tier since the last upgrade (the discount's age).
var turns_waited: int = 0
## 4.4.4 paid refreshes this turn.
var refreshes_paid: int = 0
## 4.5.1 freeze toggles this turn.
var freezes_used: int = 0
var frozen: bool = false
## 6.1.1 the shop's unit and spell slots: card ids, NO_CARD for an empty slot (4.2.3).
var shop_units: Array[StringName] = []
var shop_spells: Array[StringName] = []
## 7.1 cards in hand, in the order gained.
var hand: Array[Unit] = []
## Gained units waiting for their recruit target, in gain order. Other actions wait.
var recruit_choices: Array[Unit] = []
## 8.1 the recruit board: one entry per slot, null for an empty slot.
var board: Array[Unit] = []
## 6.2 Discover options being shown. Empty when none is pending.
var discover_options: Array[StringName] = []
## Discovers waiting behind the one shown, oldest first, as tier ranges (min in x, max in y).
## Their options are drawn only when shown.
var discover_queue: Array[Vector2i] = []
## 12.1.1 "this game": lasting player-level numbers mechanics keep (a tribe-wide bonus).
var counters: Dictionary = {}
## Named card heaps kept for the game (CardHeap), made on first use. Fights use the real ones.
var heaps: Dictionary = {}
## 8.5 one SlotState per board slot.
var slots: Array[SlotState] = []
## Player-level mechanics with no unit (a heap that fills on every sale, a tribe-wide aura).
## Their hooks run with unit = null: listeners, auras (source slot -1), side queries.
var standing: Array[BoundMechanic] = []
var alive: bool = true
## True once the player has ended this Recruit Phase.
var turn_ended: bool = false
## 2.3.2 the opponent faced in each past round, latest last (-1 = the ghost).
var opponents: Array[int] = []
var eliminated_round: int = 0
## 1.1.3 final place, 0 while still playing.
var placement: int = 0


static func create(
	player_id: int, slot_count: int, starting_health: int, start_armor: int
) -> PlayerState:
	var player := PlayerState.new()
	player.id = player_id
	player.health = starting_health
	player.armor = start_armor
	player.board.resize(slot_count)
	for _i: int in slot_count:
		player.slots.append(SlotState.new())
	return player


func counter(key: StringName) -> int:
	return CoreUtil.to_int(counters.get(key, 0))


## The named heap, made empty on first use.
func heap(heap_name: StringName) -> CardHeap:
	if not heaps.has(heap_name):
		heaps[heap_name] = CardHeap.new()
	var found: CardHeap = heaps[heap_name]
	return found


func has_standing(mechanic_id: StringName) -> bool:
	for bound: BoundMechanic in standing:
		if bound.id == mechanic_id:
			return true
	return false


func board_units() -> Array[Unit]:
	var out: Array[Unit] = []
	for unit: Unit in board:
		if unit != null:
			out.append(unit)
	return out


func board_count() -> int:
	return board_units().size()


func empty_slots() -> Array[int]:
	var out: Array[int] = []
	for slot: int in board.size():
		if board[slot] == null:
			out.append(slot)
	return out


func occupied() -> Array[bool]:
	var out: Array[bool] = []
	for unit: Unit in board:
		out.append(unit != null)
	return out


func place(unit: Unit, slot: int) -> void:
	board[slot] = unit
	unit.slot = slot


func remove_from_board(unit: Unit) -> void:
	if unit.slot >= 0 and board[unit.slot] == unit:
		board[unit.slot] = null
	unit.slot = -1


## Only a source still on this board can become committed; sold sources retain a last slot.
func mark_worked(unit: Unit) -> void:
	if unit != null and unit.slot >= 0 and unit.slot < board.size() and board[unit.slot] == unit:
		unit.worked_this_turn = true


func find_uid(uid: int) -> Unit:
	for unit: Unit in hand:
		if unit.uid == uid:
			return unit
	for unit: Unit in board:
		if unit != null and unit.uid == uid:
			return unit
	return null


## Every card the player holds, board first in reading order, then hand.
func all_cards() -> Array[Unit]:
	var out: Array[Unit] = board_units()
	out.append_array(hand)
	return out


## JSON-shaped view for logs and the UI.
func view() -> Dictionary:
	return {
		"id": id,
		"health": health,
		"armor": armor,
		"gold": gold,
		"tier": tier,
		"alive": alive,
		"frozen": frozen,
		"shop_units": shop_units.map(func(c: StringName) -> String: return String(c)),
		"shop_spells": shop_spells.map(func(c: StringName) -> String: return String(c)),
		"hand": hand.map(func(u: Unit) -> Dictionary: return u.view()),
		"board": board.map(_slot_view),
		"discover": discover_options.map(func(c: StringName) -> String: return String(c)),
		"discovers_waiting": discover_queue.size(),
		"recruit_choices": recruit_choices.map(func(u: Unit) -> int: return u.uid),
		"counters": UnitText.counters_view(counters),
		"heaps": _heaps_view(),
		"slots": slots.map(func(s: SlotState) -> Dictionary: return s.view()),
		"standing": standing.map(func(b: BoundMechanic) -> String: return String(b.id)),
		"placement": placement,
	}


func _heaps_view() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in heaps:
		var heap_found: CardHeap = heaps[key]
		out[str(key)] = heap_found.view()
	return out


static func _slot_view(unit: Unit) -> Variant:
	if unit == null:
		return null
	return unit.view()
