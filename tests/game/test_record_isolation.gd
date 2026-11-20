extends GutTest
## Separate suite: test_records overrides its output folder and would mask a missing GUT hook.

const CoreKit := preload("res://tests/core/core_kit.gd")


func test_test_kits_never_write_into_the_owners_records() -> void:
	var before: PackedStringArray = _owner_files()
	assert_true(GameRecord.directory.begins_with("res://build/"), "GUT must redirect all fixtures")
	var kit: GameSession = CoreKit.bridge_session(81)
	kit.start_round()
	assert_true(kit.record.path.begins_with("res://build/"), "test kit record belongs in build")
	var flow: GameFlow = FlowFixture.live(
		GameContent.load_folders(["res://src/content/shared"]), 82
	)
	flow.start_round()
	assert_true(
		flow.session.record.path.begins_with("res://build/"), "UI test games also use build"
	)
	assert_eq(_owner_files(), before, "no test record in the owner's folder")


func _owner_files() -> PackedStringArray:
	if not DirAccess.dir_exists_absolute("user://records"):
		return PackedStringArray()
	return DirAccess.get_files_at("user://records")
