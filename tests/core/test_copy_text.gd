extends GutTest
## Copies are printed cards, even when Mag Pye has taken a card's current fight text.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Legacy := preload("res://tests/core/legacy_wave1.gd")
const KIT := preload("res://tests/core/recruit_kit.gd")
const F1: int = 0
const B1: int = 4


func test_fetch_cannot_copy_a_fetch_whose_text_mag_pye_stole() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	kit.put("cradle_fetch", F1)
	kit.put("cradle_fetch", B1)
	var result: Dictionary = kit.fight_board({B1: {"def_id": "mag_pye"}})
	assert_eq(KIT.of_type(result, "text_taken").size(), 1)
	assert_eq(KIT.of_type(result, "summon").size(), 0, "a printed Fetch remains ineligible")
	assert_ne(result["reason"], Combat.REASON_TRIGGER_LIMIT)
	assert_eq(KIT.of_type(result, "combat_end").size(), 1)


func test_golden_fetch_cannot_copy_a_stripped_golden_fetch() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	kit.put("cradle_fetch", F1, true)
	kit.put("cradle_fetch", B1, true)
	var result: Dictionary = kit.fight_board({B1: {"def_id": "mag_pye", "golden": true}})
	assert_eq(
		KIT.of_type(result, "text_taken").size(), 2, "golden Mag Pye also takes the next-to Fetch"
	)
	assert_eq(KIT.of_type(result, "summon").size(), 0)
	assert_ne(result["reason"], Combat.REASON_TRIGGER_LIMIT)


func test_copy_exclusion_checks_the_printed_mechanic_not_the_card_id() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	kit.card("another_fetch", [{"id": "cradle_fetch", "golden_bonus": 4}])
	kit.put("cradle_fetch", F1)
	kit.put("another_fetch", B1)
	var result: Dictionary = kit.fight_board({B1: {"def_id": "mag_pye"}})
	assert_eq(KIT.of_type(result, "text_taken").size(), 1)
	assert_eq(KIT.of_type(result, "summon").size(), 0)


func test_soak_always_exercises_copy_text_transfer_cases() -> void:
	assert_eq(SoakCopyCheck.problems(UnitLibrary.load_dir()), PackedStringArray())


func test_soak_still_exercises_frozen_legacy_text_transfer() -> void:
	assert_eq(SoakCopyCheck.problems(Legacy.library()), PackedStringArray())
