extends GutTest
## Milestone A scope-review fixes: status reminders are the unit notes word for word, triggers
## are named by the card's own keyword, the sandbox takes Attack/Health overrides, shop-to-board
## drag plays the unit the buy produced, and a real touch drag buys and plays.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")


func test_general_interactive_zones_keep_rectangular_taps_and_drops() -> void:
	var zone := Interactive.new()
	add_child_autofree(zone)
	zone.size = Vector2(500, 150)
	var corner := Vector2(8, 8)
	assert_true(zone._has_point(corner), "wide hand and hero zones include their corners")
	assert_false(zone._has_point(Vector2(-1, 8)))
	var taps: Array = []
	var drops: Array = []
	zone.tapped.connect(func(_zone: String, _index: int) -> void: taps.append(true))
	zone.can_drop_fn = func(_data: Variant, _zone: String, _index: int) -> bool: return true
	zone.drop_fn = func(data: Variant, _zone: String, _index: int) -> void: drops.append(data)
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = corner
		zone._gui_input(click)
	assert_eq(taps.size(), 1)
	assert_true(zone._can_drop_data(corner, "hand"))
	zone._drop_data(corner, "hand")
	assert_eq(drops, ["hand"])


func test_drag_keeps_a_valid_hex_press_after_pointer_leaves_the_face() -> void:
	var card := CardView.new()
	add_child_autofree(card)
	card.set_card_size(Vector2(176, 226))
	card.drag_data_fn = func(_zone: String, _index: int) -> Variant: return {"index": 0}
	var outside: Vector2 = card.face_rect().position + Vector2(2, 2)
	assert_false(card._has_point(outside))
	assert_true(card._get_drag_data(outside) == null, "an unpressed cut corner cannot start a drag")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = card.face_rect().get_center()
	card._gui_input(press)
	assert_true(
		card._get_drag_data(outside) is Dictionary,
		"Godot's delayed drag request preserves a press that began on the face"
	)


## A stand-alone stub port (no core): buy() puts a golden at the front of the hand with a fresh
## iid, as a triple would, and play() records what was played.
class FrontBuyPort:
	extends GamePort
	var hand: Array = []
	var board: Array = [null, null, null, null, null, null, null]
	var shop: Array = [{"iid": 50, "def_id": "dewdrop_ooze", "name": "Dewdrop Ooze", "cost": 3}]
	var played: Array = []

	func get_state() -> Dictionary:
		return {"round": 1, "gold": 10, "tier": 1, "shop": shop, "hand": hand, "board": board}

	func buy(_shop_index: int) -> String:
		hand.insert(0, {"iid": 99, "def_id": "dewdrop_ooze", "name": "Golden", "golden": true})
		shop = []
		return ""

	func play(hand_index: int, slot: int) -> String:
		played.append([Data.i(Data.entry(hand, hand_index), "iid", -1), slot])
		return ""


func _core() -> CorePort:
	var port: CorePort = CorePort.new()
	port.setup(GameConfig.defaults())
	if port.config.card_set().is_empty():
		port.library = LegacyPrototypes.library()
	port.manual_choices = false
	return port


## The real core with 10 gold every turn, so one turn can buy several units.
func _rich_core() -> CorePort:
	var config: GameConfig = GameConfig.defaults()
	config.set_value("income_by_turn", [10, 10, 10, 10, 10, 10, 10, 10])
	var port: CorePort = CorePort.new()
	port.setup(config)
	if port.config.card_set().is_empty():
		port.library = LegacyPrototypes.library()
	return port


func test_status_reminders_are_the_players_words_never_a_designers_note() -> void:
	var view: Dictionary = {
		"def_id": "common_toad",
		"statuses": [{"status": "nightshade", "data": {}}, {"status": "first_bite", "data": {}}],
	}
	var notes: String = CardDetail.notes_bbcode(view)
	var plain: String = RegEx.create_from_string("\\[[^\\]]*\\]").sub(notes, "", true)
	assert_string_contains(plain, "first loses half its Health")
	assert_string_contains(plain, "Quick in this unit's first exchange")
	assert_false(plain.contains("library text"))
	assert_false(plain.contains("prototype"))
	assert_false(plain.contains("next time this is hit"), "no invented Nightshade text")


func test_trigger_is_named_by_its_mechanic_keyword_or_the_unit() -> void:
	var model: CombatModel = CombatModel.new()
	model.units[1] = {"uid": 1, "name": "Drumming Woodpecker", "keywords": ["Peck"]}
	model.units[2] = {"uid": 2, "name": "Hoglet Mother", "keywords": ["Bristle"]}
	model.units[3] = {"uid": 3, "name": "Sett Warden", "keywords": ["Hunker"]}
	model.units[4] = {"uid": 4, "name": "Weasel Second", "keywords": ["First Bite"]}
	assert_eq(CombatLog.trigger_name(model, 1, "peck"), "Peck")
	assert_eq(CombatLog.trigger_name(model, 1, "on_attack_buff_tribe"), "Drumming Woodpecker")
	assert_eq(CombatLog.trigger_name(model, 2, "bristle"), "Bristle")
	assert_eq(CombatLog.trigger_name(model, 2, "death_summon"), "Hoglet Mother")
	assert_eq(CombatLog.trigger_name(model, 3, "survive_buff_behind"), "Sett Warden")
	assert_eq(CombatLog.trigger_name(model, 4, "grant_first_bite_in_front"), "First Bite")


func test_sandbox_overrides_reach_the_fight() -> void:
	var port: CorePort = _core()
	var sandbox: SandboxScreen = SandboxScreen.new()
	add_child_autofree(sandbox)
	sandbox.setup(port)
	sandbox.place(0, 1, "belladonna_sprite", false)
	sandbox.place(1, 1, "common_toad", false)
	sandbox.set_stats(1, 1, 40, 70)
	var board: Array = sandbox.boards[1]
	var entry: Dictionary = Data.entry(board, 1)
	assert_eq(Data.i(entry, "attack"), 40)
	assert_eq(Data.i(entry, "health"), 70)
	var result: Dictionary = port.sandbox_fight(sandbox.boards, 3)
	assert_false(result.has("error"), Data.s(result, "error"))
	var events: Array = Data.a(result, "events")
	var start: Dictionary = Data.entry(events, 0)
	var sides: Array = Data.a(start, "boards")
	var found: bool = false
	for side_entry: Variant in sides:
		var slots: Array = side_entry
		for unit_entry: Variant in slots:
			if unit_entry is Dictionary:
				var unit: Dictionary = unit_entry
				if Data.s(unit, "def_id") == "common_toad":
					found = Data.i(unit, "attack") == 40 and Data.i(unit, "health") == 70
	assert_true(found, "the fight starts with a 40/70 Common Toad")
	sandbox.reset_stats(1, 1)
	var reset_board: Array = sandbox.boards[1]
	var reset: Dictionary = Data.entry(reset_board, 1)
	assert_false(reset.has("attack"), "reset drops the override")


func test_shop_to_board_drag_plays_the_bought_unit_on_the_core() -> void:
	var port: CorePort = _rich_core()
	port.new_game(21)
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	assert_eq(port.buy(0), "", "a unit already waits in hand")
	screen.call("render")
	var shop: Array = Data.a(port.get_state(), "shop")
	var bought_iid: int = Data.i(Data.entry(shop, 0), "iid", -1)
	screen.call("_drop", {"zone": "shop", "index": 0}, "board", 2)
	var board: Array = Data.a(port.get_state(), "board")
	var placed: Dictionary = Data.entry(board, 2)
	assert_eq(Data.i(placed, "iid", -2), bought_iid, "the bought unit, not the waiting one")


func test_shop_to_board_drag_finds_a_triple_golden_anywhere_in_hand() -> void:
	var port: FrontBuyPort = FrontBuyPort.new()
	port.hand = [{"iid": 7, "def_id": "field_vole", "name": "Field Vole"}]
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	screen.call("_drop", {"zone": "shop", "index": 0}, "board", 3)
	assert_eq(port.played, [[99, 3]], "plays the new golden at hand index 0")


func test_touch_drag_buys_and_plays_through_the_recruit_screen() -> void:
	var port: CorePort = _core()
	port.new_game(21)
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	await get_tree().process_frame
	await get_tree().process_frame
	var shop_cards: GridContainer = screen.get("_shop_cards")
	var card: CardView = shop_cards.get_child(0) as CardView
	var board: BoardView = screen.get("_board")
	var from: Vector2 = card.get_global_rect().get_center()
	var to: Vector2 = board.slot_global_center(1)
	var bought_iid: int = Data.i(Data.entry(Data.a(port.get_state(), "shop"), 0), "iid", -1)
	Input.use_accumulated_input = false
	await _touch(true, from)
	var steps: int = 12
	for i: int in range(1, steps + 1):
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.position = _to_window(from.lerp(to, float(i) / steps))
		drag.relative = _to_window(to) - _to_window(from.lerp(to, float(i - 1) / steps))
		Input.parse_input_event(drag)
		await get_tree().process_frame
	await _touch(false, to)
	Input.use_accumulated_input = true
	var placed: Dictionary = Data.entry(Data.a(port.get_state(), "board"), 1)
	assert_eq(Data.i(placed, "iid", -2), bought_iid, "touch drag bought and played into F2")


## Input events arrive in window pixels; the root viewport stretches 1920x1080 onto the window.
func _to_window(at: Vector2) -> Vector2:
	return get_tree().root.get_final_transform() * at


func _touch(pressed: bool, at: Vector2) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = pressed
	touch.position = _to_window(at)
	Input.parse_input_event(touch)
	await get_tree().process_frame
	await get_tree().process_frame
