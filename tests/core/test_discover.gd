extends GutTest
## Prototype supply is an explicit test fixture; the live library keeps all prototypes retired.
## The one pick function (direction-summary, Engineering) and Discover (rulebook 6.2, 5.3.3).
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules
var _rng: RandomNumberGenerator


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(null, false, LegacyPrototypes.library())
	_player = _kit.player
	_rules = _kit.rules
	_rng = RandomNumberGenerator.new()
	_rng.seed = 3


func test_pick_removes_from_the_pool_6_1_3() -> void:
	var before: int = _kit.pool.total_copies()
	var picked: PackedStringArray = CardPick.spec(4, 2).run(_kit.pool, _rng)
	assert_eq(picked.size(), 4, "four")
	assert_eq(_kit.pool.total_copies(), before - 4, "out of the pool")


func test_pick_can_leave_the_pool_alone() -> void:
	var pick: CardPick = CardPick.spec(4, 2)
	pick.remove = false
	var before: int = _kit.pool.total_copies()
	pick.run(_kit.pool, _rng)
	assert_eq(_kit.pool.total_copies(), before, "only looked")


func test_pick_keeps_to_tier_limits_6_2_1() -> void:
	var pick: CardPick = CardPick.spec(20, 3, 3)
	for id: String in pick.run(_kit.pool, _rng):
		assert_eq(_kit.pool.tier_of(id), 3, "tier 3 only")


func test_pick_distinct_6_2_2() -> void:
	var pick: CardPick = CardPick.spec(5, 1)
	pick.distinct = true
	var picked: PackedStringArray = pick.run(_kit.pool, _rng)
	var seen: Dictionary = {}
	for id: String in picked:
		assert_false(seen.has(id), "no duplicates")
		seen[id] = true


func test_pick_include_exclude_tribes() -> void:
	var tribe: String = _kit.library.tribes_in_rotation()[0]
	var pick: CardPick = CardPick.spec(5, 6)
	pick.distinct = true
	pick.tribes = PackedStringArray([tribe])
	for id: String in pick.run(_kit.pool, _rng):
		assert_true(_kit.pool.tribes_of(id).has(tribe), "has the tribe")
	var without: CardPick = CardPick.spec(5, 6)
	without.distinct = true
	without.not_tribes = PackedStringArray([tribe])
	for id: String in without.run(_kit.pool, _rng):
		assert_false(_kit.pool.tribes_of(id).has(tribe), "not the tribe")
	var named: CardPick = CardPick.spec(1, 6)
	var first: String = _kit.pool.ids()[0]
	named.include = func(id: String) -> bool: return id == first
	assert_eq(named.run(_kit.pool, _rng)[0], first, "the include rule decides")
	var ruled_out: CardPick = CardPick.spec(1, 1)
	ruled_out.exclude = _kit.pool.ids()
	assert_eq(ruled_out.run(_kit.pool, _rng).size(), 0, "exclude removes all")


func test_pick_uniform_ignores_copies() -> void:
	var pick: CardPick = CardPick.spec(1, 1)
	pick.algorithm = CardPick.UNIFORM
	pick.remove = false
	var first: String = _kit.pool.ids()[0]
	var copies: int = _kit.pool.copies_left(first)
	for _index: int in copies - 1:
		_kit.pool.take(first)
	var hits: int = 0
	for _index: int in 1000:
		if pick.run(_kit.pool, _rng)[0] == first:
			hits += 1
	var tier_one: int = 0
	for id: String in _kit.pool.ids():
		if _kit.pool.tier_of(id) == 1:
			tier_one += 1
	assert_almost_eq(float(hits) / 1000.0, 1.0 / tier_one, 0.05, "as likely as any other")


func test_pick_tier_weighted_favours_the_weight() -> void:
	var pick: CardPick = CardPick.spec(1, 2)
	pick.algorithm = CardPick.TIER_WEIGHTED
	pick.tier_weights = [0, 1]
	pick.remove = false
	for _index: int in 20:
		assert_eq(_kit.pool.tier_of(pick.run(_kit.pool, _rng)[0]), 2, "weight 0 never comes")


func test_shop_draw_matches_the_old_uniform_copy_draw_6_1_3() -> void:
	var one: UnitPool = UnitPool.create(_kit.library, _kit.config)
	var two: UnitPool = UnitPool.create(_kit.library, _kit.config)
	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = 9
	rng_b.seed = 9
	for _index: int in 30:
		assert_eq(
			CardPick.spec(1, 4).run(one, rng_a)[0], two.draw(4, rng_b), "same stream, same card"
		)


func _discover(step: Dictionary = {}) -> PackedStringArray:
	var full: Dictionary = {"effect": "discover", "count": 3, "tier": "current"}
	full.merge(step, true)
	_rules.discover(_player, full)
	return _player.pending[0]["options"] if _player.is_choosing() else PackedStringArray()


func test_discover_offers_three_distinct_in_tier_6_2_1() -> void:
	_player.tier = 2
	var options: PackedStringArray = _discover()
	assert_eq(options.size(), 3, "three")
	var seen: Dictionary = {}
	for id: String in options:
		assert_lte(_kit.pool.tier_of(id), 2, "at or below the tier")
		seen[id] = true
	assert_eq(seen.size(), 3, "distinct")


func test_discover_blocks_other_actions_6_2() -> void:
	_discover()
	_player.gold = 9
	assert_eq(_rules.refresh(_player), RecruitRules.CHOOSE_FIRST, "refresh waits")
	assert_eq(_rules.tier_up(_player), RecruitRules.CHOOSE_FIRST, "tier up waits")
	assert_eq(_rules.buy(_player, 0), RecruitRules.CHOOSE_FIRST, "buy waits")


func test_discover_returns_the_others_5_3_3() -> void:
	var before: int = _kit.pool.total_copies()
	_discover()
	assert_eq(_kit.pool.total_copies(), before - 3, "all out while shown")
	assert_eq(_rules.choose(_player, 1), "", "chose")
	assert_eq(_kit.pool.total_copies(), before - 1, "the others back")
	assert_eq(_player.hand[0].origin, RecruitUnit.ORIGIN_CREATED, "Created (4.3.2)")
	assert_eq(_player.hand[0].pool_copies, 1, "holds the copy")


func test_discover_on_a_full_hand_loses_it_7_1_2() -> void:
	_kit.card("filler", [])
	for _index: int in _kit.config.get_int("hand_limit"):
		_kit.put("filler")
	var before: int = _kit.pool.total_copies()
	_discover()
	_rules.choose(_player, 0)
	assert_eq(_kit.pool.total_copies(), before, "copy returned")


func test_discover_with_fewer_eligible_offers_what_there_is_6_2_3() -> void:
	var empty := UnitPool.from_cards([], _kit.config, "pool_copies_by_tier", PackedStringArray())
	_rules.pool = empty
	assert_eq(_discover().size(), 0, "nothing to offer, nothing pending")
	assert_false(_player.is_choosing(), "no choice")


func test_discover_choices_queue_in_order_6_2() -> void:
	_discover({"tier": 1})
	_discover({"tier": 2})
	assert_eq(_player.pending.size(), 2, "two waiting")
	_rules.choose(_player, 0)
	var second: PackedStringArray = _player.pending[0]["options"]
	assert_eq(_kit.pool.tier_of(second[0]), 2, "the older one went first")


func test_discover_by_tribe_6_2_1() -> void:
	var tribe: String = _kit.library.tribes_in_rotation()[0]
	_player.tier = UnitLibrary.TIERS
	var options: PackedStringArray = _discover({"tribe": tribe})
	assert_gt(options.size(), 0, "some")
	for id: String in options:
		assert_true(_kit.pool.tribes_of(id).has(tribe), "the named tribe")


func test_discover_effect_from_card_text_6_2() -> void:
	_kit.card(
		"seer", [KIT.effect("on_play", {"effect": "discover", "count": 2, "tier": "current"})]
	)
	_kit.put("seer")
	assert_eq(_rules.play(_player, 0, 0), "", "played")
	var options: PackedStringArray = _player.pending[0]["options"]
	assert_eq(options.size(), 2, "as the card says")


func test_end_phase_settles_a_waiting_choice_6_2() -> void:
	_discover()
	_rules.end_phase(_player)
	assert_false(_player.is_choosing(), "nothing carries over")
	assert_eq(_player.hand.size(), 1, "took the first")


func test_session_blocks_end_turn_while_choosing_6_2() -> void:
	var library := LegacyPrototypes.library()
	var session := GameSession.create(4, library, GameConfig.defaults())
	assert_null(session.get_state()["pending_choice"], "null when nothing waits")
	session._human().pending.append(
		{"kind": "discover", "options": PackedStringArray(["hoglet_mother"]), "spells": false}
	)
	assert_eq(session.end_turn(), RecruitRules.CHOOSE_FIRST, "must choose first")
	assert_eq(session.get_state()["pending_choice"]["kind"], "discover", "the state shows it")
	assert_eq(session.choose(0), "", "chosen")
	assert_eq(session.end_turn(), "", "now it can end")
