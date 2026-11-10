extends GutTest
## Definitions stay loadable; only explicit regression libraries restore prototype supply.
@warning_ignore_start("unsafe_call_argument")
const IDS: PackedStringArray = [
	"belladonna_sprite",
	"bitter_toad",
	"bog_ooze",
	"bramble_ooze",
	"brownie_porter",
	"buzzard",
	"carrion_crow",
	"common_toad",
	"crested_newt",
	"dewdrop_ooze",
	"drumming_woodpecker",
	"ermine_duellist",
	"fairy_knight",
	"field_vole",
	"fieldfare",
	"fox_cub",
	"fox_notary",
	"garden_snail",
	"great_ooze",
	"hazel_dormouse",
	"hedge_sprite",
	"hedgehog_twin",
	"hedgerow_elder",
	"hoglet",
	"hoglet_mother",
	"marmot_lookout",
	"marsh_frog",
	"moth_fairy",
	"mudwallow_toad",
	"old_badger",
	"old_crane",
	"pixie_scout",
	"sett_warden",
	"still_water_heron",
	"stoat_captain",
	"weasel_second",
	"wood_mouse_guard",
	"worker_bee"
]
const RESTORED: PackedStringArray = [
	"bog_ooze",
	"bramble_ooze",
	"dewdrop_ooze",
	"field_vole",
	"garden_snail",
	"great_ooze",
	"hazel_dormouse",
	"hedgehog_twin",
	"hedgerow_elder",
	"hoglet_mother",
	"marmot_lookout",
	"wood_mouse_guard",
	"worker_bee"
]
var current: UnitLibrary


func before_all() -> void:
	current = UnitLibrary.load_dir()


func test_all_thirty_eight_prototypes_are_loadable_but_absent_from_current_pools() -> void:
	assert_eq(current.all_units().size(), 160)
	assert_eq(current.pool_units().size(), 0)
	assert_eq(current.pool_units("slice").size(), 111)
	var found: int = 0
	for card: Dictionary in current.all_units():
		if not card.has("set"):
			found += 1
			assert_true(IDS.has(str(card["id"])))
			assert_false(card["pool"], str(card["id"]))
	assert_eq(found, 38)
	for id: String in IDS:
		assert_false(current.get_unit(id).is_empty(), id + " is retained for fixtures")
	var pool: UnitPool = UnitPool.create(current, GameConfig.full_game())
	assert_eq(pool.ids().size(), 111)
	for id: String in IDS:
		assert_false(pool.has_unit(id), id + " cannot be drawn in a live game")


func test_explicit_archive_restores_exactly_the_thirteen_previous_pool_cards() -> void:
	var old: UnitLibrary = LegacyPrototypes.library()
	assert_eq(old.pool_units().size(), 13)
	assert_eq(old.pool_units("slice").size(), 111)
	for id: String in IDS:
		assert_eq(old.get_unit(id)["pool"], RESTORED.has(id), id)
	assert_eq(TestLibraries.current().pool_units().size(), 0, "current cache is still live")


func test_rollback_wrappers_restore_supply_without_overwriting_other_tribal_archives() -> void:
	var wave1: UnitLibrary = LegacyWave1.library()
	var bog: UnitLibrary = LegacyBog.library(false, false)
	var hunters: UnitLibrary = LegacyHunters.library()
	for id: String in RESTORED:
		assert_true(wave1.get_unit(id)["pool"], id)
		assert_true(bog.get_unit(id)["pool"], id)
		assert_true(hunters.get_unit(id)["pool"], id)
	assert_true(wave1.get_unit("pixie_scout")["pool"], "old Fairy pool flag survives")
	assert_true(wave1.get_unit("fox_cub")["pool"], "old Hunter pool flag survives")
	assert_true(hunters.get_unit("fox_cub")["pool"], "Hunter rollback is not clobbered")
