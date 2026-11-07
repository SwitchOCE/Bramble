extends GutTest
## Unified records preserve old history once and reject invalid display/counter data.
@warning_ignore_start("unsafe_call_argument")

const Records := preload("res://src/ui/records.gd")
var _old_path: String


func before_all() -> void:
	_old_path = Records.path


func before_each() -> void:
	Records.path = "user://test_unified_records.cfg"
	DirAccess.remove_absolute(Records.path)


func after_each() -> void:
	DirAccess.remove_absolute(Records.path)


func after_all() -> void:
	Records.path = _old_path


func _save(sections: Dictionary) -> void:
	var file := ConfigFile.new()
	for section: String in sections:
		var values: Dictionary = sections[section]
		for key: String in values:
			file.set_value(section, key, values[key])
	assert_eq(file.save(Records.path), OK)


func test_one_record_tracks_best_and_wins_without_a_level() -> void:
	assert_eq(Records.summary(), "Not played yet")
	assert_true(Records.add_game(5))
	assert_false(Records.add_game(6))
	assert_true(Records.add_game(1))
	assert_eq(Records.best_placement(), 1)
	assert_eq(Records.wins(), 1)
	assert_eq(Records.games(), 3)
	assert_eq(Records.summary(), "Best 1st · 1 win")


func test_legacy_levels_aggregate_once_and_preserve_the_original_history() -> void:
	_save(
		{
			"easy": {"best": 5, "wins": 0, "games": 2},
			"normal": {"best": 3, "wins": 1, "games": 4},
			"hard": {"best": 1, "wins": 2, "games": 7},
			"naive": {"best": 1, "wins": 100, "games": 100},
			"other": {"note": "[b]leave this untouched[/b]"},
		}
	)
	assert_eq(Records.best_placement(), 1)
	assert_eq(Records.wins(), 3)
	assert_eq(Records.games(), 13)
	assert_eq(Records.wins(), 3, "reading repeatedly does not add legacy counts again")
	assert_false(Records.add_game(4))
	assert_eq(Records.games(), 14)
	assert_true(Records.add_game(1) == false, "an equal best is not a new best")
	assert_eq(Records.wins(), 4)
	assert_eq(Records.games(), 15)
	var file := ConfigFile.new()
	assert_eq(file.load(Records.path), OK)
	assert_eq(file.get_value("easy", "games"), 2)
	assert_eq(file.get_value("hard", "wins"), 2)
	assert_eq(file.get_value("naive", "wins"), 100, "tool data stays saved but is not counted")
	assert_eq(file.get_value("other", "note"), "[b]leave this untouched[/b]")
	assert_eq(file.get_value("overall", "version"), Records.VERSION)


func test_bad_legacy_values_cannot_become_placements_counts_or_markup() -> void:
	_save(
		{
			"easy": {"best": "[url=bad]win[/url]", "wins": "9", "games": -7},
			"normal": {"best": 9, "wins": -4, "games": 3},
			"hard": {"best": 2, "wins": 2.5, "games": true},
			"[b]injected[/b]": {"best": 1, "wins": 999, "games": 999},
		}
	)
	assert_eq(Records.best_placement(), 2)
	assert_eq(Records.wins(), 0)
	assert_eq(Records.games(), 3)
	assert_eq(Records.summary(), "Best 2nd · 0 wins")


func test_invalid_placements_do_not_count_as_finished_games() -> void:
	for placement: int in [-5, 0, 9, 999]:
		assert_false(Records.add_game(placement))
	assert_eq(Records.best_placement(), 0)
	assert_eq(Records.wins(), 0)
	assert_eq(Records.games(), 0)


func test_existing_unified_record_is_not_added_to_legacy_data_again() -> void:
	_save(
		{
			"overall": {"version": Records.VERSION, "best": 1, "wins": 2, "games": 8},
			"hard": {"best": 1, "wins": 100, "games": 200},
		}
	)
	assert_eq(Records.wins(), 2)
	assert_eq(Records.games(), 8)
	assert_false(Records.add_game(3))
	assert_eq(Records.games(), 9)
	assert_eq(Records.wins(), 2)


func test_counter_addition_and_migration_cannot_overflow_negative() -> void:
	_save(
		{
			"easy": {"best": 3, "wins": Records.MAX_COUNT, "games": Records.MAX_COUNT},
			"hard": {"best": 2, "wins": 4, "games": 5},
		}
	)
	assert_eq(Records.wins(), Records.MAX_COUNT)
	assert_eq(Records.games(), Records.MAX_COUNT)
	assert_true(Records.add_game(1))
	assert_eq(Records.best_placement(), 1)
	assert_eq(Records.wins(), Records.MAX_COUNT)
	assert_eq(Records.games(), Records.MAX_COUNT)


func test_corrupt_unified_fields_are_sanitized_when_adding_a_game() -> void:
	_save(
		{"overall": {"version": Records.VERSION, "best": false, "wins": "[b]99[/b]", "games": -3}}
	)
	assert_eq(Records.best_placement(), 0)
	assert_eq(Records.wins(), 0)
	assert_eq(Records.games(), 0)
	assert_true(Records.add_game(4))
	assert_eq(Records.summary(), "Best 4th · 0 wins")
	assert_eq(Records.games(), 1)
