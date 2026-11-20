extends GutTest
## The slot rows survive the actual causes of gaps: purchases and occupied combat movement.

const Slots := preload("res://tests/screens/slot_assertions.gd")
const RECRUIT: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const FIGHT: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")
const FIXTURES: String = "res://tests/screens/fixtures/"


func after_each() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _make(scene: PackedScene, state: Dictionary) -> GlassScreen:
	var screen: GlassScreen = scene.instantiate() as GlassScreen
	screen.state = state
	add_child_autofree(screen)
	screen._keeper.animate = false
	screen.settle()
	return screen


func test_every_recruit_and_fight_json_fixture_has_all_its_slot_rows() -> void:
	var checked: int = 0
	var files: PackedStringArray = DirAccess.get_files_at(FIXTURES)
	files.sort()
	for filename: String in files:
		if filename.get_extension() != "json":
			continue
		var state: Dictionary = GlassScreen.load_state(FIXTURES + filename)
		if not state.has("board") and not state.has("boards"):
			continue
		var scene: PackedScene = FIGHT if state.has("boards") else RECRUIT
		var screen: GlassScreen = _make(scene, state)
		assert_eq(Slots.check(screen), PackedStringArray(), filename)
		var layer: Node = screen.get_node_or_null("Frame/Stage/Slots")
		screen.show_state(state.duplicate(true))
		screen.settle()
		assert_same(screen.get_node_or_null("Frame/Stage/Slots"), layer, filename + " keeps layer")
		assert_eq(Slots.check(screen), PackedStringArray(), filename + " redraw")
		checked += 1
		screen.free()
		await get_tree().process_frame
	assert_gt(checked, 0, "fixture enumeration exercised states")


func test_real_unit_and_spell_purchases_leave_their_null_shop_places_visible() -> void:
	var content: GameContent = GameContent.load_default()
	assert_eq(content.errors, PackedStringArray())
	var flow: GameFlow = GameFlow.create(content, 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.gold = 30
	me.shop_units = [&"brock-cub", &"hedge-knight"]
	me.shop_spells = [&"sp_seek", &"sp_sharpen"]
	var screen: RecruitScreen = _make(RECRUIT, ViewAdapter.recruit_state(flow)) as RecruitScreen
	var unit_slot: Node = screen.get_node_or_null("Frame/Stage/Slots/ShopSlot_0")
	var spell_slot: Node = screen.get_node_or_null("Frame/Stage/Slots/SpellSlot_0")
	assert_not_null(unit_slot, "occupied unit offer already has its slot")
	assert_not_null(spell_slot, "occupied spell offer already has its slot")
	for spell: bool in [false, true]:
		assert_eq(flow.act({"type": "buy", "spell": spell, "index": 0}), "", "real core purchase")
		var state: Dictionary = ViewAdapter.recruit_state(flow)
		var row: Array = state["shop_spells" if spell else "shop_units"]
		assert_eq(row.size(), 2, "purchase keeps row indices")
		assert_true(row[0] == null, "core/adapter leaves the bought offer null")
		screen.show_state(state)
		screen.settle()
		assert_eq(Slots.check(screen), PackedStringArray(), "after spell=%s purchase" % spell)
		assert_null(screen.node_for("spell" if spell else "shop", 0), "bought card left its place")
		assert_same(screen.get_node_or_null("Frame/Stage/Slots/ShopSlot_0"), unit_slot)
		assert_same(screen.get_node_or_null("Frame/Stage/Slots/SpellSlot_0"), spell_slot)
		await get_tree().process_frame
	assert_eq(flow.act({"type": "refresh"}), "", "real core refill")
	screen.show_state(ViewAdapter.recruit_state(flow))
	screen.settle()
	assert_not_null(screen.node_for("shop", 0), "refill puts a card back over its place")
	assert_same(screen.get_node_or_null("Frame/Stage/Slots/ShopSlot_0"), unit_slot)
	assert_same(screen.get_node_or_null("Frame/Stage/Slots/SpellSlot_0"), spell_slot)
	assert_eq(Slots.check(screen), PackedStringArray(), "after refill")


func test_occupied_attacker_trigger_and_joiner_keep_their_exposed_home_slots() -> void:
	for you: int in 2:
		var state: Dictionary = GlassScreen.load_state(FIXTURES + "fight_start.json")
		state["you_side"] = you
		var screen: FightScreen = _make(FIGHT, state) as FightScreen
		var home: Node = screen.find_child("Slot_%d_0" % you, true, false)
		var friend_home: Node = screen.find_child("Slot_%d_1" % you, true, false)
		assert_not_null(home, "occupied attacker already has its backing slot")
		assert_not_null(friend_home, "occupied trigger/joiner already has its backing slot")
		var lunge: Dictionary = {"side": you, "slot": 0, "target_side": 1 - you, "target_slot": 0}
		var waiting: Dictionary = lunge.duplicate()
		waiting["waiting"] = true
		var moments: Array[Dictionary] = [
			{"lunge": lunge},
			{"trigger": {"side": you, "slot": 1}},
			{"lunge": lunge, "joins": [{"side": you, "slot": 1}]},
			{"lunge": lunge, "splashes": [{"side": 1 - you, "slot": 0, "amount": 1}]},
			# A pile-on as a real replay shows it: the attacker waits, the piler's hit shows.
			{
				"lunge": waiting,
				"joins": [{"side": you, "slot": 1}],
				"splashes": [{"side": 1 - you, "slot": 0, "amount": 4}],
			},
		]
		for index: int in moments.size():
			state["moment"] = moments[index]
			screen.show_state(state)
			screen.settle()
			var slot: int = 0 if index in [0, 3] else 1
			var card: Control = screen.node_for("board", you * 7 + slot)
			assert_not_null(card, "occupied moving unit")
			if card != null and index != 3:
				assert_ne(card.position, screen.unit_xy(you, slot), "card really exposes its home")
			assert_same(screen.find_child("Slot_%d_0" % you, true, false), home)
			assert_same(screen.find_child("Slot_%d_1" % you, true, false), friend_home)
			assert_eq(Slots.check(screen), PackedStringArray(), "side %d moment %d" % [you, index])
			await get_tree().process_frame
		var boards: Array = state["boards"]
		var row: Array = boards[you]
		row[0] = null
		state["moment"] = {}
		screen.show_state(state)
		screen.settle()
		assert_null(screen.node_for("board", you * 7), "death removes the occupied card")
		assert_same(screen.find_child("Slot_%d_0" % you, true, false), home)
		assert_eq(Slots.check(screen), PackedStringArray(), "after death")
		await get_tree().process_frame
		screen.free()


func test_shop_rows_follow_arbitrary_lengths_and_shrink_without_stale_slots() -> void:
	var state: Dictionary = GlassScreen.load_state(FIXTURES + "recruit_mockup.json")
	var screen: GlassScreen = _make(RECRUIT, state)
	for counts: Vector2i in [Vector2i(0, 0), Vector2i(1, 3), Vector2i(7, 1), Vector2i(2, 0)]:
		var units: Array = []
		units.resize(counts.x)
		var spells: Array = []
		spells.resize(counts.y)
		state["shop_units"] = units
		state["shop_spells"] = spells
		screen.show_state(state)
		screen.settle()
		assert_eq(Slots.check(screen), PackedStringArray(), "row lengths %s" % counts)
		await get_tree().process_frame
