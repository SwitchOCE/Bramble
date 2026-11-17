extends GutTest

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")


func after_each() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _unit(id: String = "brock-cub", golden: bool = false) -> Dictionary:
	return {"id": id, "golden": golden}


func test_match_counts_either_owned_zone_but_never_other_offers_or_spells() -> void:
	for zone: String in ["board", "hand"]:
		var state: Dictionary = {
			"shop_units": [_unit(), _unit(), _unit("hedge-knight"), null],
			"board": [null],
			"hand": [],
		}
		var marks: Dictionary = RecruitDuplicates.marks(state)
		assert_eq(marks.shop, [0, 0, 0, 0], "shop copies alone are not owned")
		state[zone] = [_unit(), {"id": "hedge-knight", "spell": true}]
		marks = RecruitDuplicates.marks(state)
		assert_eq(marks.shop, [1, 1, 0, 0], "each matching offer is marked")
		assert_eq(marks[zone], [0, 0], "one owned copy does not glow")


func test_triple_marks_all_participants_across_board_and_hand_without_gold_or_legality_gate(
) -> void:
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
		assert_eq(marks.shop, [2, 2, 1], "each offer independently completes the triple")
		assert_eq(marks.board.slice(0, 2), [0, 0], "empty and unrelated board slots")
		assert_eq(marks.hand[0], 0, "spells cannot triple")
		assert_eq(marks.board.count(2) + marks.hand.count(2), 2, "both origins count (7.3.3)")


func test_goldens_match_but_do_not_count_or_participate_in_normal_triples() -> void:
	var state: Dictionary = {
		"shop_units": [_unit(), _unit("brock-cub", true)],
		"board": [_unit("brock-cub", true)],
		"hand": [],
	}
	assert_eq(RecruitDuplicates.marks(state).shop, [1, 1], "golden ownership is still a match")
	state.hand.append(_unit())
	assert_eq(RecruitDuplicates.marks(state).shop, [1, 1], "golden plus normal is not two normals")
	state.hand.append(_unit())
	var marks: Dictionary = RecruitDuplicates.marks(state)
	assert_eq(marks.shop, [2, 1], "a golden offer cannot complete a normal triple")
	assert_eq(marks.board, [0], "owned golden does not participate")
	assert_eq(marks.hand, [2, 2])


func _screen(state: Dictionary) -> RecruitScreen:
	var screen: RecruitScreen = SCREEN.instantiate()
	screen.state = state
	add_child_autofree(screen)
	screen.settle()
	return screen


func _mark(screen: RecruitScreen, kind: String, index: int) -> int:
	var glow: GlassDuplicateGlow = screen.node_for(kind, index).get_node_or_null("DuplicateGlow")
	return glow.mark if glow != null else RecruitDuplicates.Mark.NONE


func test_live_buy_changes_match_to_triple_and_combination_removes_every_preview() -> void:
	var flow: GameFlow = GameFlow.create(GameContent.load_default(), 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	CoreKit.put(flow.session, me, "brock-cub", 0)
	me.shop_units = [&"brock-cub", &"brock-cub"]
	me.gold = 20
	var screen: RecruitScreen = _screen(ViewAdapter.recruit_state(flow))
	assert_eq(_mark(screen, "shop", 0), 1)
	assert_eq(_mark(screen, "board", 0), 0)
	assert_eq(flow.session.act(0, {"type": "buy", "spell": false, "index": 0}), "")
	screen.show_state(ViewAdapter.recruit_state(flow))
	assert_eq(_mark(screen, "shop", 1), 2)
	assert_eq(_mark(screen, "board", 0), 2)
	assert_eq(_mark(screen, "hand", 0), 2)
	assert_eq(flow.session.act(0, {"type": "buy", "spell": false, "index": 1}), "")
	screen.show_state(ViewAdapter.recruit_state(flow))
	assert_null(screen.node_for("board", 0))
	assert_eq(_mark(screen, "hand", 0), 0, "golden result carries no triple preview")
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
	assert_eq(glow.mark, 2)
	var shop: GlassDuplicateGlow = screen.node_for("shop", 3).get_node("DuplicateGlow")
	var candidate: int = glow.candidate
	glow.set_phase(GlassDuplicateGlow.PERIODS[candidate] / 2.0)
	shop.set_phase(GlassDuplicateGlow.PERIODS[candidate] / 2.0)
	var mat: ShaderMaterial = glow._layers[0].material as ShaderMaterial
	var shop_mat: ShaderMaterial = shop._layers[0].material as ShaderMaterial
	assert_almost_eq(
		float(mat.get_shader_parameter("shadow_opacity")),
		GlassDuplicateGlow.FLOORS[candidate],
		0.001
	)
	assert_eq(
		mat.get_shader_parameter("shadow_opacity"),
		shop_mat.get_shader_parameter("shadow_opacity"),
		"all participants share the pulse"
	)
	card.set_hot(true)
	card.set_held(true)
	screen._board.light("unit", [GlassPieces.as_int(state.board[board_index].uid)])
	assert_true(glow.visible, "hover, drag and target lighting preserve the duplicate cue")
	card.set_hot(false)
	card.set_held(false)
	state = state.duplicate(true)
	state.shop_units[3] = state.shop_units[0].duplicate(true)
	screen.show_state(state)
	assert_same(screen.node_for("board", board_index), card, "unchanged owned card is kept")
	assert_eq(_mark(screen, "board", board_index), 0, "refresh removes its preview")
	assert_false(glow.visible)
	assert_eq(_mark(screen, "hand", 2), 0)


func test_noncombining_offers_only_match_and_adapter_exposes_the_definition_flag() -> void:
	var flow: GameFlow = GameFlow.create(GameContent.load_default(), 3)
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
	assert_eq(marks.board.count(2), 0)
	assert_eq(marks.hand, [0])
	# Also exercise a noncombining offer against otherwise eligible owned entries.
	state.board[0].combines = true
	state.hand[0].combines = true
	assert_eq(RecruitDuplicates.marks(state).shop, [1])
	# Noncombining owned entries must not help a combining offer complete a triple.
	state.shop_units[0].combines = true
	state.hand[0].combines = false
	assert_eq(RecruitDuplicates.marks(state).shop, [1])
