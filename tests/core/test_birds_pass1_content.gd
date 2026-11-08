extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const ROSTER: Dictionary = {
	"one_swallow": Vector3i(1, 1, 2),
	"chiffchaff": Vector3i(1, 1, 2),
	"mrs_dunnock": Vector3i(1, 2, 3),
	"mr_redbreast": Vector3i(2, 2, 4),
	"redwing": Vector3i(2, 2, 4),
	"mrs_jay": Vector3i(2, 3, 3),
	"tom_tit": Vector3i(3, 2, 4),
	"jack_daw": Vector3i(3, 2, 4),
	"old_tern": Vector3i(3, 2, 4),
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
	_kit.setup(GameConfig.full_game())
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
	for _turn: int in 3:
		_kit.pass_turn()
	assert_true(_kit.player.hand.has(tern))


func test_tern_offers_only_two_distinct_birds_at_tier_five_and_six() -> void:
	for tier: int in [5, 6]:
		before_each()
		_return_tern(tier)
		assert_eq(_kit.player.pending.size(), 1)
		var options: PackedStringArray = _kit.player.pending[0]["options"]
		assert_eq(options.size(), 2, "a thin tier is not filled from lower tiers")
		assert_ne(options[0], options[1])
		for id: String in options:
			var card: Dictionary = _kit.library.get_unit(id)
			assert_eq(card["tier"], tier)
			var tribes: Array = card["tribes"]
			assert_true(tribes.has("Birds"))


func test_golden_tern_makes_two_bird_only_discovers_at_your_tier() -> void:
	_return_tern(6, true)
	assert_eq(_kit.player.pending.size(), 2)
	for choice: Dictionary in _kit.player.pending:
		var options: PackedStringArray = choice["options"]
		assert_eq(options.size(), 2)
		for id: String in options:
			var card: Dictionary = _kit.library.get_unit(id)
			var tribes: Array = card["tribes"]
			assert_eq(card["tier"], 6)
			assert_true(tribes.has("Birds"))


func test_tern_does_not_substitute_other_cards_when_its_tier_is_depleted() -> void:
	for id: String in ["great_lump", "mother_goose"]:
		while _kit.pool.copies_left(id) > 0:
			assert_true(_kit.pool.take(id))
	_return_tern(5)
	assert_true(_kit.player.pending.is_empty())
	assert_true(
		_kit.player.recruit_log.any(
			func(event: Dictionary) -> bool: return event["type"] == "discover_empty"
		)
	)
