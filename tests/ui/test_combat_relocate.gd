extends GutTest
## A unit that moves in the fight (Whirligig Beetle's row swap, a Changeling's borrowed unit going
## home) moves its card too. Before, the card stayed put, the next summon onto that slot freed it,
## and `_cards` kept the freed card: "previously freed instance" errors in the deep UI run.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const Settings := preload("res://src/ui/settings.gd")


func after_each() -> void:
	Settings.reduce_motion = false


func test_a_dying_cards_flash_ends_with_the_card() -> void:
	Settings.reduce_motion = true
	var screen: CombatScreen = _screen()
	screen.step_once()
	screen.call("_flash", 1, Color.WHITE, true)
	var flash: Tween = screen._tweens.back()
	screen.call("_death", 1, true)
	await get_tree().create_timer(0.7).timeout
	assert_false(screen._cards.has(1), "the card died before its flash finished")
	assert_false(flash.is_valid(), "the delayed flash cannot outlive its card")


func _unit(uid: int, unit_name: String) -> Dictionary:
	return {
		"uid": uid,
		"def_id": "fox_cub",
		"name": unit_name,
		"tier": 1,
		"tribes": ["Hunters"],
		"attack": 2,
		"health": 3,
		"max_health": 3,
		"golden": false,
		"text": "",
		"keywords": [],
		"keyword_text": [],
		"statuses": []
	}


func _fight() -> Dictionary:
	var mine: Array = [_unit(1, "Ash"), null, null, null, _unit(2, "Birch"), null, null]
	var theirs: Array = [_unit(3, "Cedar"), null, null, null, null, null, null]
	var events: Array = [
		{"type": "combat_start", "player_ids": [0, 1], "first_side": 0, "boards": [mine, theirs]},
		# Row swap: two events, the first lands on a slot still holding the other card.
		{"type": "relocate", "uid": 1, "side": 0, "slot": 4},
		{"type": "relocate", "uid": 2, "side": 0, "slot": 0},
		# Crossing sides, as a borrowed unit going home does.
		{"type": "relocate", "uid": 2, "side": 1, "slot": 2},
		# Onto the slot the moved cards left.
		{"type": "summon", "side": 0, "slot": 0, "unit": _unit(9, "Dock")},
		{
			"type": "stats",
			"target": 1,
			"attack": 5,
			"health": 5,
			"max_health": 5,
			"attack_delta": 3,
			"health_delta": 2
		},
		{"type": "damage", "target": 2, "amount": 1, "health_after": 2},
		{"type": "death", "uid": 1},
		{"type": "combat_end", "winner": 0, "reason": "board_empty", "damage": 1},
	]
	return {"events": events}


func _screen() -> CombatScreen:
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	screen.setup(_fight(), PackedStringArray(["You", "Enemy"]), 0, "Round 1")
	return screen


## Every card the screen holds is alive and on the slot the model puts its unit on.
func _assert_cards_match(screen: CombatScreen, when: String) -> void:
	for uid: int in screen._cards:
		var card: CardView = screen._cards[uid]
		assert_true(is_instance_valid(card), "%s: card %d is not freed" % [when, uid])
		if not is_instance_valid(card):
			continue
		var view: Dictionary = screen.model.unit(uid)
		var side: int = Data.i(view, "side", 0)
		var slot: int = Data.i(view, "slot", -1)
		if screen.model.uid_at(side, slot) != uid:
			continue  # halfway through a swap: its own event places it
		assert_eq(
			screen.board_for_side(side).cards[slot], card, "%s: card %d on its slot" % [when, uid]
		)
	for side: int in 2:
		for slot: int in CombatModel.SLOTS:
			var uid: int = screen.model.uid_at(side, slot)
			if uid >= 0:
				assert_true(screen._cards.has(uid), "%s: unit %d has a card" % [when, uid])


func test_stepping_moves_cards_with_their_units() -> void:
	var screen: CombatScreen = _screen()
	for i: int in screen.events.size():
		screen.step_once()
		await wait_process_frames(1)
		_assert_cards_match(screen, "after event %d" % i)
	var birch: CardView = screen._cards[2]
	assert_eq(birch.get_parent(), screen.board_for_side(1), "Birch went to the other side")


func test_skipping_to_the_end_keeps_every_card() -> void:
	var screen: CombatScreen = _screen()
	screen.skip_to_end()
	await wait_process_frames(1)
	_assert_cards_match(screen, "after skip")
	assert_true(screen.is_showing_result())


func test_restarting_halfway_through_a_swap_leaves_no_stray_card() -> void:
	var screen: CombatScreen = _screen()
	screen.step_once()  # combat_start
	screen.step_once()  # Ash onto Birch's slot: Birch is detached, waiting for its own move
	screen.restart()
	screen.step_once()
	await wait_process_frames(1)
	for side: int in 2:
		var board: BoardView = screen.board_for_side(side)
		for child: Node in board.get_children():
			if child is CardView:
				assert_true(board.cards.has(child), "side %d: %s is in a slot" % [side, child])
