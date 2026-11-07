extends GutTest

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const ScoutPanel := preload("res://src/ui/widgets/scout_panel.gd")
const Views := preload("res://src/ui/unit_views.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const FIGHT := preload("res://tests/core/combat_kit.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _board(zone: String = "board", width: float = 180) -> BoardView:
	var board: BoardView = BoardView.new()
	board.configure(zone, width, true, zone == "board")
	add_child_autofree(board)
	return board


func _marks(bird: Dictionary, effects: Array = []) -> Array:
	var away: Dictionary = bird.duplicate()
	away["nest"] = 0
	away["turns_left"] = 2
	return RecruitView.slot_marks({"away": [away], "slot_effects": effects})


func _numbers(board: BoardView, slot: int = 0) -> PackedStringArray:
	var overlay: Control = board.get("_marks")
	var attack: Array = overlay.get("_egg_attack")
	var health: Array = overlay.get("_egg_health")
	var attack_label: Label = attack[slot]
	var health_label: Label = health[slot]
	return PackedStringArray([attack_label.text, health_label.text])


func _shown(board: BoardView, slot: int = 0) -> bool:
	var overlay: Control = board.get("_marks")
	var stats: Array = overlay.get("_egg_stats")
	var row: Control = stats[slot]
	return row.visible


func test_empty_own_nest_shows_rounded_half_stats_and_goose_exception() -> void:
	var board: BoardView = _board()
	board.set_marks(_marks({"def_id": "mrs_jay", "attack": 7, "health": 9}))
	assert_true(_shown(board))
	assert_eq(_numbers(board), PackedStringArray(["4", "5"]))
	assert_null(board.cards[0], "the preview does not occupy the playable slot")
	board.set_marks(_marks({"def_id": "mother_goose", "attack": 99, "health": 99}))
	assert_eq(_numbers(board), PackedStringArray(["0", "2"]))


func test_ring_is_added_once_after_halving_and_matches_the_public_combat_start() -> void:
	var bird: RecruitUnit = RecruitUnit.make(FIGHT.library.get_unit("mrs_jay"), 1)
	bird.attack = 7
	bird.health = 9
	var effects: Array = [
		[{"attack": 1, "health": 2}, {"attack": 2, "health": 0}], [], [], [], [], [], []
	]
	var board: BoardView = _board()
	var marks: Array = _marks(bird.view(), effects)
	board.set_marks(marks)
	assert_eq(_numbers(board), PackedStringArray(["7", "7"]))
	var mark: Dictionary = marks[0]
	assert_string_contains(RecruitHeld.nest_note(mark), "7/7 Egg")
	assert_string_contains(RecruitHeld.nest_note(mark), "Ring stats are included.")
	var combat: Combat = Combat.create(
		FIGHT.library, GameConfig.defaults(), RandomNumberGenerator.new()
	)
	combat.slot_effects = [effects, [[], [], [], [], [], [], []]]
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	var result: Dictionary = combat.run(
		[FIGHT.board({0: HeldUnits.egg_spec(bird)}), FIGHT.board({0: FIGHT.plain(1, 1)})],
		tiers,
		ids,
		0
	)
	var events: Array = result["events"]
	var start: Dictionary = events[0]
	var sides: Array = start["boards"]
	var units: Array = sides[0]
	var egg: Dictionary = units[0]
	assert_eq(_numbers(board), PackedStringArray([str(egg["attack"]), str(egg["health"])]))
	board.set_marks(_marks({"def_id": "mother_goose", "attack": 99, "health": 99}, effects))
	assert_eq(_numbers(board), PackedStringArray(["3", "4"]), "Goose gets the slot Ring normally")


func test_a_standing_unit_hides_egg_numbers_and_they_return_when_it_leaves() -> void:
	var board: BoardView = _board()
	board.set_marks(_marks({"def_id": "mrs_jay", "attack": 7, "health": 9}))
	var card: CardView = CardView.new()
	card.show_unit(Views.from_def(FIGHT.library.get_unit("field_vole")))
	board.place_card(card, 0)
	assert_false(_shown(board), "the standing unit fights, so no Egg is advertised")
	var overlay: Control = board.get("_marks")
	var labels: Array = overlay.get("_nest_labels")
	var caption: Label = labels[0]
	assert_eq(caption.text, "On Nest 2")
	board.remove_card(0)
	assert_true(_shown(board))


func test_scout_never_uses_private_bird_numbers_but_keeps_an_existing_public_egg_card() -> void:
	var board: BoardView = _board("scout", 136)
	board.set_marks(_marks({"def_id": "mrs_jay", "attack": 999, "health": 999}))
	assert_false(_shown(board))
	var overlay: Control = board.get("_marks")
	var labels: Array = overlay.get("_nest_labels")
	var caption: Label = labels[0]
	assert_eq(caption.text, "F1 · Nest", "no private return countdown either")
	var scout: ScoutPanel = ScoutPanel.new()
	add_child_autofree(scout)
	var public: Dictionary = Views.from_def(FIGHT.library.get_unit("nest_egg"))
	public["attack"] = 17
	public["health"] = 19
	scout.show_board("Rival", [public, null, null, null, null, null, null], [], [0])
	var theirs: BoardView = scout.get("_board")
	var attack: Label = theirs.cards[0].get("_attack_label")
	var health: Label = theirs.cards[0].get("_health_label")
	assert_eq(attack.text, "17")
	assert_eq(health.text, "19")
	assert_false(_shown(theirs), "public card stats are not replaced by an inferred preview")


func test_phone_nest_badges_fit_without_covering_the_nest_caption() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var board: BoardView = BoardView.new()
	board.configure("board", 180, true, true)
	viewport.add_child(board)
	board.set_marks(_marks({"def_id": "mrs_jay", "attack": 99, "health": 99}))
	await get_tree().process_frame
	var overlay: Control = board.get("_marks")
	var stats: Array = overlay.get("_egg_stats")
	var labels: Array = overlay.get("_nest_labels")
	var row: Control = stats[0]
	var caption: Label = labels[0]
	assert_false(row.get_global_rect().intersects(caption.get_global_rect()))
	assert_eq(LayoutCheck.problems(board, "phone Nest stats"), PackedStringArray())
