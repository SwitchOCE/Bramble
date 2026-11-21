extends GutTest

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")
const MARK := RecruitDuplicates.Mark


func after_each() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _unit(id: String = "brock-cub", golden: bool = false) -> Dictionary:
	return {"id": id, "golden": golden}


func test_shop_pair_and_trio_stay_unmarked_with_none_owned() -> void:
	var state: Dictionary = {
		"shop_units": [_unit(), _unit(), null],
		"board": [null],
		"hand": [{"id": "brock-cub", "spell": true}],
	}
	assert_eq(RecruitDuplicates.marks(state), {"shop": [0, 0, 0], "board": [0], "hand": [0]})
	state.shop_units[2] = _unit()
	assert_eq(RecruitDuplicates.marks(state).shop, [0, 0, 0])


func test_one_owned_in_either_zone_marks_each_matching_shop_copy() -> void:
	for zone: String in ["board", "hand"]:
		var state: Dictionary = {
			"shop_units": [_unit(), _unit("hedge-knight"), _unit(), null],
			"board": [null],
			"hand": [],
		}
		state[zone] = [_unit(), {"id": "hedge-knight", "spell": true}]
		var marks: Dictionary = RecruitDuplicates.marks(state)
		assert_eq(marks.shop, [MARK.MATCH, MARK.NONE, MARK.MATCH, MARK.NONE])
		assert_eq(marks[zone], [0, 0], "owned partners only glow for a triple")


func test_owned_pair_with_an_empty_shop_gets_no_mark() -> void:
	assert_eq(
		RecruitDuplicates.marks({"shop_units": [], "board": [_unit()], "hand": [_unit()]}),
		{"shop": [], "board": [0], "hand": [0]}
	)


func test_owned_triple_gets_no_mark_from_vacancies_unrelated_offers_or_spells() -> void:
	var state: Dictionary = {
		"shop_units": [null, _unit("hedge-knight"), {"id": "brock-cub", "spell": true}],
		"board": [_unit()],
		"hand": [_unit(), _unit()],
	}
	assert_eq(RecruitDuplicates.marks(state), {"shop": [0, 0, 0], "board": [0], "hand": [0, 0]})


func test_two_owned_mark_matching_offers_and_both_owned_edges_even_without_gold() -> void:
	for board_count: int in range(3):
		var state: Dictionary = {
			"shop_units": [_unit(), _unit(), _unit("hedge-knight")],
			"board": [null, _unit("hedge-knight")],
			"hand": [{"id": "sp_sharpen", "spell": true}],
			"gold": 0,
			"legal_actions": [],
		}
		for i: int in range(2):
			var copy: Dictionary = _unit()
			copy["bought_copies"] = 1 if i == 0 else 0
			state["board" if i < board_count else "hand"].append(copy)
		var marks: Dictionary = RecruitDuplicates.marks(state)
		assert_eq(marks.shop, [MARK.TRIPLE, MARK.TRIPLE, MARK.MATCH])
		assert_eq(marks.board.slice(0, 2), [0, 0], "owned copies outside the triple stay unmarked")
		assert_eq(marks.hand[0], 0, "spells cannot triple")
		assert_eq(marks.board.count(MARK.OWNED_EDGE), board_count, "both origins count (7.3.3)")
		assert_eq(marks.hand.count(MARK.OWNED_EDGE), 2 - board_count)


func test_goldens_do_not_give_or_receive_owned_marks() -> void:
	var state: Dictionary = {
		"shop_units": [_unit(), _unit("brock-cub", true)],
		"board": [_unit("brock-cub", true)],
		"hand": [],
	}
	assert_eq(RecruitDuplicates.marks(state).shop, [MARK.NONE, MARK.NONE])
	state.hand.append(_unit())
	assert_eq(RecruitDuplicates.marks(state).shop, [1, 1], "golden plus normal is not two normals")
	state.hand.append(_unit())
	var marks: Dictionary = RecruitDuplicates.marks(state)
	assert_eq(marks.shop, [2, 1], "a golden offer cannot complete a normal triple")
	assert_eq(marks.board, [0], "owned goldens never get a match or triple glow")
	assert_eq(marks.hand, [MARK.OWNED_EDGE, MARK.OWNED_EDGE])
	state.shop_units[0] = null
	assert_eq(RecruitDuplicates.marks(state).hand, [0, 0], "a golden offer gives no owned edge")


func _screen(state: Dictionary) -> RecruitScreen:
	var screen: RecruitScreen = SCREEN.instantiate()
	screen.state = state
	add_child_autofree(screen)
	screen.settle()
	return screen


func _mark(screen: RecruitScreen, kind: String, index: int) -> int:
	var glow: GlassDuplicateGlow = screen.node_for(kind, index).get_node_or_null("DuplicateGlow")
	return glow.mark if glow != null else MARK.NONE


func _act(flow: GameFlow, screen: RecruitScreen, action: Dictionary) -> void:
	var first: int = flow.session.events.size()
	var reason: String = flow.act(action)
	assert_eq(reason, "", "the core takes %s" % JSON.stringify(action))
	screen.show_state(ViewAdapter.recruit_state(flow, reason, flow.session.events.slice(first)))


func test_buy_move_to_hand_sell_and_combine_update_the_marks() -> void:
	var flow: GameFlow = FlowFixture.live(GameContent.load_default(), 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	CoreKit.put(flow.session, me, "brock-cub", 0)
	me.shop_units = [&"brock-cub", &"brock-cub", &"brock-cub"]
	me.gold = 20
	var screen: RecruitScreen = _screen(ViewAdapter.recruit_state(flow))
	assert_eq(_mark(screen, "shop", 0), MARK.MATCH)
	assert_eq(_mark(screen, "shop", 1), MARK.MATCH)
	assert_eq(_mark(screen, "board", 0), MARK.NONE)

	_act(flow, screen, {"type": "buy", "index": 0})
	assert_eq(_mark(screen, "shop", 1), MARK.TRIPLE)
	assert_eq(_mark(screen, "board", 0), MARK.OWNED_EDGE)
	assert_eq(_mark(screen, "hand", 0), MARK.OWNED_EDGE)
	var foil: Control = screen.node_for("shop", 1).get_node("TripleFoil")
	assert_true(foil.visible)
	assert_false(screen.node_for("hand", 0).has_node("TripleFoil"))

	_act(flow, screen, {"type": "to_hand", "slot": 0})
	assert_null(screen.node_for("board", 0))
	assert_eq(_mark(screen, "hand", 1), MARK.OWNED_EDGE, "the edge follows the moved copy")
	assert_eq(_mark(screen, "shop", 1), MARK.TRIPLE, "moving preserves the owned count")

	_act(flow, screen, {"type": "sell", "hand": 1})
	assert_eq(_mark(screen, "hand", 0), MARK.NONE)
	assert_eq(_mark(screen, "shop", 1), MARK.MATCH)
	assert_false(foil.visible)

	_act(flow, screen, {"type": "buy", "index": 1})
	assert_eq(_mark(screen, "shop", 2), MARK.TRIPLE)
	_act(flow, screen, {"type": "buy", "index": 2})
	assert_eq(_mark(screen, "hand", 0), MARK.NONE, "golden result carries no triple preview")
	assert_true(me.hand[0].golden)


func test_glow_updates_on_kept_cards_and_survives_hover_drag_and_target_light() -> void:
	var state: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/shop_review.json")
	var screen: RecruitScreen = _screen(state)
	var board_index: int = -1
	for i: int in state.board.size():
		if state.board[i] is Dictionary and state.board[i].id == "brock-cub":
			board_index = i
	var card: GlassCard = screen.node_for("board", board_index)
	var glow: GlassDuplicateGlow = card.get_node("DuplicateGlow")
	assert_eq(glow.mark, MARK.OWNED_EDGE)
	assert_false(card.has_node("TripleFoil"))
	var shop: GlassDuplicateGlow = screen.node_for("shop", 3).get_node("DuplicateGlow")
	var candidate: int = shop.candidate
	glow.set_phase(GlassDuplicateGlow.PERIODS[candidate] / 2.0)
	shop.set_phase(GlassDuplicateGlow.PERIODS[candidate] / 2.0)
	var mat: ShaderMaterial = glow._layers[0].material as ShaderMaterial
	var shop_mat: ShaderMaterial = shop._layers[0].material as ShaderMaterial
	assert_almost_eq(
		float(shop_mat.get_shader_parameter("shadow_opacity")),
		GlassDuplicateGlow.FLOORS[candidate],
		0.001
	)
	assert_eq(mat.get_shader_parameter("shadow_opacity"), 1.0, "owned edge stays steady")
	card.set_hot(true)
	card.set_held(true)
	screen._board.light("unit", [GlassPieces.as_int(state.board[board_index].uid)])
	assert_true(glow.visible, "hover, drag and target lighting preserve the duplicate cue")
	card.set_hot(false)
	card.set_held(false)
	var owned_partner: Dictionary = state.hand[2].duplicate(true)
	state = state.duplicate(true)
	state.hand.remove_at(2)
	screen.show_state(state)
	assert_same(screen.node_for("board", board_index), card, "unchanged owned card is kept")
	assert_eq(_mark(screen, "board", board_index), 0, "the owned partner gets no match mark")
	assert_false(glow.visible)
	assert_eq(_mark(screen, "shop", 3), 1, "the shop copy keeps its match")
	var shop_pair: GlassDuplicateGlow = screen.node_for("shop", 3).get_node("DuplicateGlow")
	assert_true(shop_pair.visible)
	assert_false((screen.node_for("shop", 3).get_node("TripleFoil") as Control).visible)
	state = state.duplicate(true)
	state.hand.append(owned_partner)
	state.shop_units[3] = state.shop_units[0].duplicate(true)
	screen.show_state(state)
	assert_eq(
		_mark(screen, "board", board_index), 0, "owned pair loses its mark without a shop copy"
	)
	assert_eq(_mark(screen, "hand", state.hand.size() - 1), 0)
	assert_false(glow.visible)


func test_noncombining_offers_only_match_and_adapter_exposes_the_definition_flag() -> void:
	var flow: GameFlow = FlowFixture.live(GameContent.load_default(), 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	CoreKit.put(flow.session, me, "private", 0)
	me.hand.append(CoreKit.unit(flow.session, "private"))
	me.shop_units = [&"private"]
	var state: Dictionary = ViewAdapter.recruit_state(flow)
	assert_false(state.shop_units[0].combines, "preview reads the real card definition")
	assert_false(state.board[0].combines)
	assert_false(state.hand[0].combines)
	var marks: Dictionary = RecruitDuplicates.marks(state)
	assert_eq(marks.shop, [1], "noncombining offer is a match, never a triple")
	assert_eq(marks.board.count(MARK.OWNED_EDGE), 0)
	assert_eq(marks.hand, [0], "noncombining owned copies get no match mark")
	# Also exercise a noncombining offer against otherwise eligible owned entries.
	state.board[0].combines = true
	state.hand[0].combines = true
	assert_eq(RecruitDuplicates.marks(state).shop, [1])
	# Noncombining owned entries must not help a combining offer complete a triple.
	state.shop_units[0].combines = true
	state.hand[0].combines = false
	assert_eq(RecruitDuplicates.marks(state).shop, [1])
