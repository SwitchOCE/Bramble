extends GutTest
## Frozen pass 2 design regression; current pool rules are tested in test_pass3_*.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const ROSTER: Dictionary = {
	"one_swallow": Vector3i(1, 1, 2),
	"chiffchaff": Vector3i(1, 1, 2),
	"mrs_dunnock": Vector3i(1, 2, 3),
	"mr_redbreast": Vector3i(2, 2, 4),
	"redwing": Vector3i(2, 2, 4),
	"mrs_jay": Vector3i(2, 3, 3),
	"tom_tit": Vector3i(3, 3, 4),
	"jack_daw": Vector3i(3, 3, 3),
	"old_tern": Vector3i(3, 3, 4),
	"mrs_stork": Vector3i(4, 3, 6),
	"cuckoo": Vector3i(4, 3, 6),
	"mag_pye": Vector3i(4, 3, 6),
	"mother_goose": Vector3i(5, 4, 7),
	"great_lump": Vector3i(5, 3, 5),
	"gabble_ratchet": Vector3i(6, 3, 7),
	"seven_whistlers": Vector3i(6, 5, 7),
}

var _kit: KIT


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game(), true)
	_kit.rules.start_phase(_kit.player, 1)


func test_slice_birds_match_revised_roster_and_tier_spread() -> void:
	var found: Array[String] = []
	var spread: Array[int] = [0, 0, 0, 0, 0, 0]
	for file: String in DirAccess.get_files_at("res://content/units"):
		if not file.ends_with(".json"):
			continue
		var card: Dictionary = _kit.library.get_unit(file.get_basename())
		if card.get("set", "") != "slice" or not card.get("pool", false):
			continue
		var tribes: Array = card["tribes"]
		if not tribes.has("Birds"):
			continue
		var id: String = str(card["id"])
		found.append(id)
		assert_true(ROSTER.has(id), id)
		var body := Vector3i(int(card["tier"]), int(card["attack"]), int(card["health"]))
		assert_eq(body, ROSTER.get(id), id)
		spread[body.x - 1] += 1
	assert_eq(found.size(), 16)
	assert_eq(spread, [3, 3, 3, 3, 2, 2])
	assert_false(found.has("barn_owl"))
	assert_true(found.has("cuckoo"))


func _return_tern(tier: int, golden: bool = false) -> void:
	_kit.player.tier = tier
	var tern: RecruitUnit = _kit.put("old_tern", 0, golden)
	tern.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_eq(_kit.rules.sell(_kit.player, 0), "")
	for _turn: int in 1 if golden else 2:
		_kit.pass_turn()
	assert_true(_kit.player.hand.has(tern))


func test_tern_homecoming_no_longer_uses_the_thin_high_tier_discover_pool() -> void:
	for tier: int in [5, 6]:
		before_each()
		_return_tern(tier)
		assert_true(_kit.player.pending.is_empty())


func test_golden_tern_returns_in_one_turn_without_discovers() -> void:
	_return_tern(6, true)
	assert_true(_kit.player.pending.is_empty())


func test_tern_homecoming_still_works_when_the_shop_tier_is_depleted() -> void:
	for id: String in ["great_lump", "mother_goose"]:
		while _kit.pool.copies_left(id) > 0:
			assert_true(_kit.pool.take(id))
	_return_tern(5)
	assert_true(_kit.player.pending.is_empty())
	assert_false(
		_kit.player.recruit_log.any(
			func(event: Dictionary) -> bool: return event["type"] == "discover_empty"
		)
	)
