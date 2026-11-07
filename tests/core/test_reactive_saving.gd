extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const SAVING := preload("res://tools/sim/candidates/reactive_saving.gd")
const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _brain: SAVING


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_kit.player.gold = 7
	_kit.player.health = 40
	_brain = BenchSuites.create_bot("reactive_saving:neutrals_purse") as SAVING
	_brain._player = _kit.player
	_brain._rules = _kit.rules
	_brain._round_now = 5
	_brain.value.library = _kit.library
	_brain.value.board_owner = _kit.player


func after_each() -> void:
	_brain.value.board_owner = null
	_brain._player = null
	_brain._rules = null


func test_reserve_follows_actual_interest_threshold_and_cap() -> void:
	_kit.put("money_spider", 0)
	_kit.player.gold = 5
	assert_eq(_brain._held_back(), 3)
	_kit.player.gold = 7
	assert_eq(_brain._held_back(), 6)
	_kit.player.gold = 30
	assert_eq(_brain._held_back(), 6, "no reserve beyond the actual interest cap")


func test_hero_and_golden_interest_match_real_rules() -> void:
	_kit.put("money_spider", 0, true)
	_kit.player.hero = _kit.library.get_hero("dame_farthing")
	assert_eq(_brain.interest_at(2), 0)
	assert_eq(_brain.interest_at(3), 2)
	assert_eq(_brain.interest_at(6), 5)
	assert_eq(_brain.interest_at(20), 9)


func test_no_engine_releases_the_fixed_purse_schedule() -> void:
	_kit.put("pill_bug", 0)
	assert_eq(_brain._held_back(), 0)


func test_low_health_and_losing_scout_release_interest_reserves() -> void:
	_kit.put("money_spider", 0)
	_kit.player.health = BotBrain.LOW_HEALTH
	assert_eq(_brain._held_back(), 0)
	_kit.player.health = 40
	_kit.player.scout = {"specs": [{"attack": 100, "health": 100}]}
	assert_eq(_brain._held_back(), 0)


func test_premium_shop_can_break_reserve_but_small_gain_cannot() -> void:
	_kit.put("money_spider", 0)
	_kit.player.gold = 5
	var weak: String = _kit.card("weak_offer", [], [], 0, 1)
	_kit.shop(weak)
	assert_true(_brain._best_offer().is_empty(), "small gain doesn't forfeit known interest")
	_kit.player.shop.clear()
	var strong: String = _kit.card("strong_offer", [], [], 50, 50)
	_kit.shop(strong)
	var offer: Dictionary = _brain._best_offer()
	assert_false(offer.is_empty(), "premium offer may use the reserved gold")
	assert_eq(offer.get("index"), 0)
