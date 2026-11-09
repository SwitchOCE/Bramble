extends GutTest
## Triples and golden units (rulebook 7.3) and the simplified Triple Reward (SPEC 9, 7.3.6).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()
var _config: GameConfig
var _pool: UnitPool
var _rules: RecruitRules
var _player: PlayerState


func before_each() -> void:
	_config = GameConfig.defaults()
	_pool = UnitPool.create(_library, _config)
	_rules = RecruitRules.create(_library, _config, _pool)
	_player = PlayerState.new()
	_player.shop_rng.seed = 3
	_rules.setup_player(_player)


func _copy(def_id: String, origin: String = RecruitUnit.ORIGIN_BOUGHT) -> RecruitUnit:
	var unit := RecruitUnit.make(_library.get_unit(def_id), _rules.new_iid())
	unit.origin = origin
	if origin == RecruitUnit.ORIGIN_BOUGHT:
		assert_true(_pool.take(def_id), "a pool copy")
		unit.pool_copies = 1
	return unit


## Puts a copy in the shop so `buy` can take it.
func _shop(def_id: String) -> void:
	_player.shop.clear()
	var unit: RecruitUnit = _copy(def_id)
	_player.shop.append(unit)
	_player.gold = 99


## A golden Created unit: fills a hand without forming triples.
func _filler() -> RecruitUnit:
	var unit := RecruitUnit.make(_library.get_unit("fieldfare"), _rules.new_iid(), true)
	unit.origin = RecruitUnit.ORIGIN_CREATED
	return unit


func _goldens() -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	for unit: RecruitUnit in _player.owned_units():
		if unit.golden:
			out.append(unit)
	return out


func test_third_copy_combines_at_once_7_3_1() -> void:
	_player.board[0] = _copy("hoglet_mother")
	_player.hand.append(_copy("hoglet_mother"))
	_shop("hoglet_mother")
	assert_eq(_rules.buy(_player, 0), "", "buy the third")
	assert_eq(_goldens().size(), 1, "one golden")
	assert_null(_player.board[0], "the board copy left its slot")
	assert_eq(_player.hand.size(), 1, "the golden is in hand")
	assert_true(_player.hand[0].from_triple, "from a triple")


func test_created_copies_count_7_3_3() -> void:
	_player.board[0] = _copy("hoglet_mother", RecruitUnit.ORIGIN_CREATED)
	_player.board[1] = _copy("hoglet_mother", RecruitUnit.ORIGIN_CREATED)
	_shop("hoglet_mother")
	_rules.buy(_player, 0)
	assert_eq(_goldens().size(), 1, "Created copies count")
	assert_eq(_goldens()[0].pool_copies, 1, "only the bought copy came from the pool (5.3.5)")


func test_golden_doubles_base_and_keeps_buffs_7_3_4() -> void:
	var buffed: RecruitUnit = _copy("hoglet_mother")
	buffed.attack += 3
	var debuffed: RecruitUnit = _copy("hoglet_mother")
	debuffed.health -= 2
	_player.board[0] = buffed
	_player.board[1] = debuffed
	_shop("hoglet_mother")
	_rules.buy(_player, 0)
	var golden: RecruitUnit = _goldens()[0]
	assert_eq([golden.attack, golden.health], [5, 6], "2/6 base, +3 Attack, Health floored at base")


func test_triple_golden_sells_for_1_and_returns_its_copies_5_3_5() -> void:
	_player.board[0] = _copy("hoglet_mother")
	_player.board[1] = _copy("hoglet_mother", RecruitUnit.ORIGIN_CREATED)
	_shop("hoglet_mother")
	_rules.buy(_player, 0)
	var before: int = _pool.copies_left("hoglet_mother")
	assert_eq(_rules.play(_player, _player.hand.find(_goldens()[0]), 3), "", "play")
	var gold: int = _player.gold
	assert_eq(_rules.sell(_player, 3), "", "sell")
	assert_eq(_player.gold - gold, 1, "4.3.4: sells for 1")
	assert_eq(_pool.copies_left("hoglet_mother") - before, 2, "two of its copies were pool copies")


func test_goldens_dont_triple_again() -> void:
	var golden := RecruitUnit.make(_library.get_unit("hoglet_mother"), _rules.new_iid(), true)
	_player.board[0] = golden
	_player.hand.append(_copy("hoglet_mother"))
	_shop("hoglet_mother")
	_rules.buy(_player, 0)
	assert_eq(_goldens().size(), 1, "golden plus two copies is no triple")
	assert_eq(_player.hand.size(), 2, "both copies stay")


func test_full_hand_with_three_board_copies_takes_the_first_vacated_slot_7_3_7() -> void:
	for slot: int in [5, 2, 6]:
		_player.board[slot] = _copy("hoglet_mother")
	for _index: int in 10:
		_player.hand.append(_filler())
	_rules.check_triples(_player)
	assert_eq(_player.hand.size(), 10, "the hand stays full")
	assert_true(_player.board[2] != null and _player.board[2].golden, "B2 first in reading order")
	assert_null(_player.board[5], "the other slots are empty")


func test_a_golden_placed_straight_on_the_board_owes_no_reward() -> void:
	for slot: int in 3:
		_player.board[slot] = _copy("hoglet_mother")
	for _index: int in 10:
		_player.hand.append(_filler())
	_rules.check_triples(_player)
	var golden: RecruitUnit = _player.board[0]
	assert_true(golden.golden, "it took the first vacated slot")
	assert_false(golden.reward_pending, "nothing is owed: it will never be played")


func test_playing_the_golden_gives_a_triple_reward_spell_7_3_6() -> void:
	# The reduced prototype pool has only two tier-3 cards. Supply a third real card so
	# this tests the next-tier reward rather than Discover's lower-tier fallback.
	var cards: Array[Dictionary] = _library.pool_units()
	cards.append(_library.get_unit("brother_wolf"))
	_pool = UnitPool.from_cards(cards, _config, "pool_copies_by_tier", [])
	_rules = RecruitRules.create(_library, _config, _pool)
	assert_eq(_pool.tier_of("brother_wolf"), 3)
	_player.tier = 2
	_player.board[0] = _copy("hoglet_mother")
	_player.hand.append(_copy("hoglet_mother"))
	_shop("hoglet_mother")
	_rules.buy(_player, 0)
	assert_eq(_rules.play(_player, 0, 3), "", "play the golden")
	assert_eq(_player.items.size(), 1, "the reward is in hand")
	assert_eq(_player.items[0].def_id(), "triple_reward", "a spell to cast when you like")
	var total: int = _pool.total_copies()
	assert_eq(_rules.play_item(_player, 0), "", "cast it")
	assert_true(_player.is_choosing(), "a Discover is waiting")
	var options: PackedStringArray = _player.pending[0]["options"]
	for id: String in options:
		assert_eq(_library.get_unit(id)["tier"], 3, "tier above the player's")
	assert_eq(_rules.choose(_player, 0), "", "pick the first")
	var reward: RecruitUnit = _player.hand[0]
	assert_eq(reward.origin, RecruitUnit.ORIGIN_CREATED, "Created (4.3.2)")
	assert_eq([reward.pool_copies, total - _pool.total_copies()], [1, 1], "one real pool copy")
	assert_eq(_rules.sell_value(reward), 0, "sells for 0")
	_rules.move(_player, 3, 4)
	_rules.play(_player, 0, 3)
	assert_eq(_player.items.size(), 0, "moving or replaying gives no second reward")
	assert_eq(_player.hand.size(), 0, "and the hand is empty")


func test_reward_at_tier_6_is_tier_6() -> void:
	# The live slice has three or more distinct tier-six choices. Legacy fillers now have two,
	# so their Discover correctly tops up from tier five and cannot test this guarantee.
	_config = GameConfig.full_game()
	_pool = UnitPool.create(_library, _config)
	_rules = RecruitRules.create(_library, _config, _pool)
	_player = PlayerState.new()
	_rules.setup_player(_player)
	_player.tier = 6
	var golden: RecruitUnit = RecruitUnit.make(_library.get_unit("hoglet_mother"), 1, true)
	golden.reward_pending = true
	_player.hand.append(golden)
	_rules.play(_player, 0, 0)
	_rules.play_item(_player, 0)
	var options: PackedStringArray = _player.pending[0]["options"]
	assert_eq(options.size(), 3, "three distinct live tier-six choices")
	for id: String in options:
		assert_eq(_library.get_unit(id)["tier"], 6, "6 at 6")


func test_reward_on_a_full_hand_is_lost_7_1_2() -> void:
	var golden: RecruitUnit = RecruitUnit.make(_library.get_unit("hoglet_mother"), 1, true)
	golden.reward_pending = true
	_player.hand.append(golden)
	for _index: int in 10:
		_player.hand.append(_filler())
	var total: int = _pool.total_copies()
	_rules.play(_player, 0, 0)
	assert_eq(_player.hand.size(), 10, "nothing added")
	assert_eq(_pool.total_copies(), total, "its copy went back")
