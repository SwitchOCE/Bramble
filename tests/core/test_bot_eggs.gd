extends GutTest
## A mirrored Egg is a body in its fixed Nest, not a recruit available to rearrange.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _player: PlayerState
var _brain: BotBrain


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_player.round_number = 5
	_brain = BotBrain.from_name("hard:birds_passage")
	_brain._player = _player
	_brain._rules = _kit.rules


func _nest(slot: int) -> void:
	var bird: RecruitUnit = RecruitUnit.make(_kit.library.get_unit("old_tern"), 900)
	bird.attack = 20
	bird.health = 20
	_player.away.append({"unit": bird, "nest": slot, "due": 7, "left": 2})


func test_small_purchase_preserves_a_giant_egg_and_prefers_a_real_gap() -> void:
	_nest(1)
	var small: RecruitUnit = RecruitUnit.make(_kit.library.get_unit("pill_bug"), 901)
	assert_ne(BotPlacer.play_slot(_player, small, _brain.value), 1)
	for slot: int in BoardGeometry.SLOTS:
		if slot != 1:
			var unit: RecruitUnit = _kit.put("field_vole", slot)
			unit.add_permanent(30, 30)
	assert_eq(BotPlacer.play_slot(_player, small, _brain.value), -1)
	assert_lte(_brain._unit_gain(small), 0.0, "a recruit gap above an Egg is not free strength")


func test_search_fills_fixed_nests_only_where_the_layout_leaves_gaps() -> void:
	_nest(1)
	_kit.put("field_vole", 0)
	var problem := BoardSearch.Problem.new()
	problem.board = _player.board_specs()
	problem.empty_specs = BotEggs.specs(_player)
	var layout: Array[int] = [0, -1, -1, -1, -1, -1, -1]
	var specs: Array = BoardSearch.combat_specs(problem, layout)
	assert_eq(specs[1]["def_id"], HeldUnits.EGG)
	assert_eq([specs[1]["attack"], specs[1]["health"]], [20, 20])
	layout = [-1, 0, -1, -1, -1, -1, -1]
	specs = BoardSearch.combat_specs(problem, layout)
	assert_null(specs[0], "the Egg stays at its Nest, never at the recruit's old slot")
	assert_eq(specs[1]["def_id"], "field_vole", "a covering recruit suppresses the Egg")


func test_rule_layout_does_not_cover_a_nest_when_an_empty_slot_exists() -> void:
	_nest(1)
	_kit.put("field_vole", 0)
	_kit.put("field_vole", 2)
	_kit.put("field_vole", 3)
	var layout: Array[int] = BotPlacer.rule_layout(_player, _brain.value, [])
	assert_eq(layout[1], -1)


func test_flying_preserves_the_build_identity_prior() -> void:
	var strategy: Dictionary = _brain.knowledge.strategy("birds_passage")
	var bird: RecruitUnit = _kit.put("old_tern", 0)
	var before: float = _brain.value.strategy_fit(strategy, _player)
	_player.board[0] = null
	_player.away.append({"unit": bird, "nest": 0, "due": 7, "left": 2})
	assert_eq(_brain.value.strategy_fit(strategy, _player), before)
