extends GutTest
## The position test's 12 units (source.experiment = "position_test"): each does what its text
## says in the right slot, and not in the wrong one. Loaded only with the experiment's name.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")
const IDS: PackedStringArray = [
	"pipistrelle",
	"robin_fledgling",
	"warren_lookout",
	"glow_worm_lantern",
	"pine_marten",
	"double_agent_bat",
	"lead_goose",
	"furrow_racer",
	"pack_alpha",
	"noctule_captain",
	"barnacle_matriarch",
	"lone_lynx",
]

var _library: UnitLibrary = UnitLibrary.load_dir(UnitLibrary.DEFAULT_DIR, "position_test")


func _run(mine: Array, theirs: Array, fight_seed: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var combat := Combat.create(_library, GameConfig.defaults(), rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([mine, theirs], tiers, ids, 0)


func _start_view(result: Dictionary, side: int, slot: int) -> Dictionary:
	var start: Dictionary = Kit.of_type(result, "combat_start")[0]
	var boards: Array = start["boards"]
	var board: Array = boards[side]
	var view: Dictionary = board[slot]
	return view


func _stats_at_start(result: Dictionary, side: int, slot: int) -> Array:
	var view: Dictionary = _start_view(result, side, slot)
	return [view["attack"], view["health"]]


func _fired(result: Dictionary, mechanic: String) -> int:
	var count: int = 0
	for event: Dictionary in Kit.of_type(result, "trigger"):
		if event["mechanic"] == mechanic:
			count += 1
	return count


## A wall the side with more units attacks first: it never kills anything.
func _wall() -> Array:
	return Kit.board({0: Kit.plain(0, 200)})


func test_every_unit_is_built_marked_and_out_of_normal_games() -> void:
	var normal: UnitLibrary = UnitLibrary.load_dir()
	assert_eq(_library.load_errors(), PackedStringArray(), "no load errors")
	assert_eq(_library.unbuilt_units(), PackedStringArray(), "every mechanic has a script")
	for id: String in IDS:
		var unit: Dictionary = _library.get_unit(id)
		var source: Dictionary = unit["source"]
		assert_eq(source["experiment"], "position_test", "%s is marked" % id)
		assert_true(normal.get_unit(id).is_empty(), "%s isn't in a normal library" % id)


func test_the_units_cover_every_tier() -> void:
	var tiers: Dictionary = {}
	for id: String in IDS:
		var unit: Dictionary = _library.get_unit(id)
		tiers[unit["tier"]] = true
	assert_eq(tiers.size(), 6, "tiers 1-6")


func test_pipistrelle_front_is_3_1_back_is_1_3_and_pings() -> void:
	var front: Dictionary = _run(Kit.board({0: Kit.u("pipistrelle")}), _wall())
	var back: Dictionary = _run(Kit.board({4: Kit.u("pipistrelle")}), _wall())
	assert_eq(_stats_at_start(front, 0, 0), [3, 1], "front side")
	assert_eq(_stats_at_start(back, 0, 4), [1, 3], "back side")
	assert_eq(_fired(front, "stance_back_ping"), 0, "no ping from the front")
	assert_eq(_fired(back, "stance_back_ping"), 1, "a ping from the back")


func test_robin_duels_the_unit_across_for_double_damage() -> void:
	var theirs: Array = Kit.board({0: Kit.plain(0, 50), 1: Kit.plain(0, 50), 5: Kit.plain(0, 50)})
	var mine: Array = Kit.board(
		{1: Kit.u("robin_fledgling"), 2: Kit.plain(0, 9), 3: Kit.plain(0, 9)}
	)
	mine[4] = Kit.plain(0, 9)
	var result: Dictionary = _run(mine, theirs)
	var attacks: Array[Dictionary] = Kit.of_type(result, "attack")
	var across: int = _start_view(result, 1, 1)["uid"]
	assert_eq(attacks[0]["defender"], across, "attacks the unit across")
	var hit: Dictionary = Kit.of_type(result, "damage")[0]
	assert_eq(hit["amount"], 4, "2 doubled")


func test_robin_in_the_back_reaches_the_back_row() -> void:
	var theirs: Array = Kit.board({0: Kit.plain(0, 50), 5: Kit.plain(0, 50)})
	var mine: Array = Kit.board(
		{5: Kit.u("robin_fledgling"), 6: Kit.plain(0, 9), 4: Kit.plain(0, 9)}
	)
	var result: Dictionary = _run(mine, theirs)
	assert_eq(Kit.of_type(result, "attack")[0]["defender"], _start_view(result, 1, 5)["uid"], "B2")


func test_robin_with_nobody_across_fights_normally() -> void:
	var mine: Array = Kit.board({3: Kit.u("robin_fledgling"), 0: Kit.plain(0, 9)})
	var result: Dictionary = _run(mine, _wall())
	assert_eq(_fired(result, "rival"), 0, "no Rival")
	assert_eq(Kit.of_type(result, "damage")[0]["amount"], 2, "not doubled")


func test_warren_lookout_bolts_into_an_empty_slot_and_leaves_a_kit() -> void:
	var theirs: Array = Kit.board({0: Kit.plain(1, 50), 1: Kit.plain(0, 50)})
	var result: Dictionary = _run(Kit.board({0: Kit.u("warren_lookout")}), theirs)
	var move: Dictionary = Kit.of_type(result, "move")[0]
	assert_eq([move["from"], move["to"]], [0, 4], "F1 to B1")
	var summon: Dictionary = Kit.of_type(result, "summon")[0]
	assert_eq(summon["slot"], 0, "the Kit takes F1")
	assert_eq(_fired(result, "bolt"), 1, "once a combat")


func test_warren_lookout_stays_with_the_slot_behind_it_full() -> void:
	var mine: Array = Kit.board({0: Kit.u("warren_lookout"), 4: Kit.plain(0, 9)})
	var result: Dictionary = _run(mine, Kit.board({0: Kit.plain(1, 50)}))
	assert_eq(_fired(result, "bolt"), 0, "nowhere to go")


func test_lantern_lights_only_the_units_in_front_of_it() -> void:
	var mine: Array = (
		Kit
		. board(
			{
				0: Kit.plain(1, 9),
				1: Kit.plain(1, 9),
				2: Kit.plain(1, 9),
				5: Kit.u("glow_worm_lantern"),
			}
		)
	)
	var result: Dictionary = _run(mine, _wall())
	var targets: Array = []
	for event: Dictionary in Kit.of_type(result, "stats"):
		if event["attack_delta"] == 2:
			targets.append(event["target"])
	assert_eq(targets, [2, 3], "F2 and F3, not F1")


func test_lantern_in_the_front_row_lights_nothing() -> void:
	var mine: Array = Kit.board({0: Kit.u("glow_worm_lantern"), 1: Kit.plain(1, 9)})
	assert_eq(_fired(_run(mine, _wall()), "buff_in_front"), 0, "no slots in front of F1")


func test_golden_lantern_gives_plus_4() -> void:
	var mine: Array = Kit.board({1: Kit.plain(1, 9), 5: Kit.u("glow_worm_lantern", -1, -1, true)})
	var stats: Dictionary = Kit.of_type(_run(mine, _wall()), "stats")[0]
	assert_eq(stats["attack_delta"], 4, "+4")


func test_pine_marten_doubles_only_with_no_neighbours() -> void:
	var alone: Dictionary = _run(Kit.board({0: Kit.u("pine_marten"), 6: Kit.plain(0, 9)}), _wall())
	var crowded: Dictionary = _run(
		Kit.board({0: Kit.u("pine_marten"), 1: Kit.plain(0, 9)}), _wall()
	)
	var behind: Dictionary = _run(Kit.board({0: Kit.u("pine_marten"), 4: Kit.plain(0, 9)}), _wall())
	assert_eq(_stats_at_start(alone, 0, 0), [4, 3], "no neighbours")
	assert_eq(_stats_at_start(crowded, 0, 0), [2, 3], "a unit beside it")
	assert_eq(_stats_at_start(behind, 0, 0), [2, 3], "a unit behind it")


func test_pine_marten_wakes_when_its_neighbour_dies() -> void:
	var mine: Array = Kit.board({0: Kit.u("pine_marten", -1, 50), 1: Kit.plain(0, 1)})
	var theirs: Array = Kit.board({0: Kit.plain(0, 50), 1: Kit.plain(1, 50), 2: Kit.plain(0, 50)})
	for fight_seed: int in 30:
		var result: Dictionary = _run(mine, theirs, fight_seed)
		for event: Dictionary in Kit.of_type(result, "stats"):
			if event["attack_delta"] == 2 and event["target"] == 1:
				pass_test("woke")
				return
	fail_test("the Marten never woke")


func test_bat_front_side_and_back_side() -> void:
	var front: Dictionary = _run(Kit.board({0: Kit.u("double_agent_bat")}), _wall())
	var mine: Array = Kit.board({0: Kit.plain(1, 9), 4: Kit.u("double_agent_bat")})
	var back: Dictionary = _run(mine, _wall())
	assert_eq(_stats_at_start(front, 0, 0), [5, 2], "front")
	assert_eq(_stats_at_start(back, 0, 4), [2, 5], "back")
	assert_eq(Kit.of_type(back, "stats")[0]["attack_delta"], 1, "+1 to the unit in front")


func test_lead_goose_swaps_forward_the_healthiest_behind_it() -> void:
	var mine: Array = Kit.board(
		{0: Kit.u("lead_goose"), 4: Kit.plain(1, 9), 1: Kit.plain(0, 9), 5: Kit.plain(0, 2)}
	)
	var result: Dictionary = _run(mine, _wall())
	var moves: Array[Dictionary] = Kit.of_type(result, "move")
	assert_eq([moves[0]["from"], moves[0]["to"]], [0, 4], "the Goose goes back")
	var stats: Dictionary = Kit.of_type(result, "stats")[0]
	assert_eq(stats["attack_delta"], 2, "the unit coming forward gets +2")
	var attacks: Array[Dictionary] = Kit.of_type(result, "attack")
	assert_eq(attacks[1]["attacker"], stats["target"], "and attacks next")


func test_lead_goose_with_nobody_behind_stays() -> void:
	var mine: Array = Kit.board({0: Kit.u("lead_goose"), 1: Kit.plain(0, 9)})
	assert_eq(_fired(_run(mine, _wall()), "rotate"), 0, "no swap")


func test_furrow_racer_needs_the_other_end() -> void:
	var paired: Array = Kit.board({0: Kit.u("furrow_racer"), 3: Kit.u("hedgehog_twin")})
	var apart: Array = Kit.board({1: Kit.u("furrow_racer"), 3: Kit.u("hedgehog_twin")})
	assert_eq(_stats_at_start(_run(paired, _wall()), 0, 0), [5, 7], "+1/+2 on the ends")
	assert_eq(_stats_at_start(_run(apart, _wall()), 0, 1), [4, 5], "nothing in F2")


func test_furrow_racer_rallies_the_row_when_its_partner_pricks() -> void:
	var mine: Array = Kit.board(
		{0: Kit.u("furrow_racer"), 3: Kit.u("hedgehog_twin"), 4: Kit.plain(0, 9)}
	)
	var theirs: Array = Kit.board({0: Kit.plain(1, 200), 1: Kit.plain(0, 200)})
	for fight_seed: int in 30:
		if _fired(_run(mine, theirs, fight_seed), "both_ends_rally") > 0:
			pass_test("rallied")
			return
	fail_test("no rally")


func test_pack_alpha_makes_its_side_attack_the_slot_across() -> void:
	var mine: Array = Kit.board({2: Kit.u("pack_alpha"), 0: Kit.plain(1, 9), 1: Kit.plain(1, 9)})
	var theirs: Array = Kit.board(
		{0: Kit.plain(0, 200), 1: Kit.plain(0, 200), 2: Kit.plain(0, 200)}
	)
	var result: Dictionary = _run(mine, theirs)
	var across: int = _start_view(result, 1, 2)["uid"]
	for attack: Dictionary in Kit.of_type(result, "attack").slice(0, 12):
		if attack["side"] == 0:
			assert_eq(attack["defender"], across, "every attack goes to F3")


func test_noctule_captain_back_side_lifts_the_units_in_front() -> void:
	var mine: Array = Kit.board({6: Kit.u("noctule_captain"), 3: Kit.plain(1, 9)})
	var back: Dictionary = _run(mine, _wall())
	assert_eq(_stats_at_start(back, 0, 6), [3, 7], "back side")
	assert_eq(Kit.of_type(back, "stats")[0]["attack_delta"], 2, "+2 to F4")
	var front: Dictionary = _run(Kit.board({0: Kit.u("noctule_captain")}), _wall())
	assert_eq(_stats_at_start(front, 0, 0), [7, 4], "front side")


func test_matriarch_swap_buffs_both() -> void:
	var mine: Array = Kit.board({0: Kit.u("barnacle_matriarch"), 4: Kit.plain(1, 9)})
	var result: Dictionary = _run(mine, Kit.board({0: Kit.plain(0, 200)}))
	var stats: Array[Dictionary] = Kit.of_type(result, "stats")
	assert_eq(_fired(result, "rotate"), 1, "swapped")
	assert_eq([stats[0]["attack_delta"], stats[0]["health_delta"]], [1, 1], "the forward unit")
	assert_eq([stats[1]["attack_delta"], stats[1]["health_delta"]], [1, 1], "the Matriarch")


func test_lone_lynx_alone_doubles_and_grows_on_a_kill() -> void:
	var alone: Dictionary = _run(Kit.board({0: Kit.u("lone_lynx"), 6: Kit.plain(0, 9)}), _kills())
	assert_eq(_stats_at_start(alone, 0, 0), [12, 8], "doubled")
	assert_eq(_fired(alone, "solitary_kill_buff"), 1, "grew on the kill")
	var crowded: Dictionary = _run(Kit.board({0: Kit.u("lone_lynx"), 1: Kit.plain(0, 9)}), _kills())
	assert_eq(_stats_at_start(crowded, 0, 0), [6, 8], "not doubled")
	assert_eq(_fired(crowded, "solitary_kill_buff"), 0, "no growth with a neighbour")


func _kills() -> Array:
	return Kit.board({0: Kit.plain(0, 1)})


func test_mark_focus_and_rival_change_nothing_without_those_units() -> void:
	var mine: Array = Kit.board({0: Kit.plain(1, 9), 1: Kit.plain(1, 9)})
	var result: Dictionary = _run(mine, Kit.board({0: Kit.plain(1, 9)}))
	assert_eq(Kit.of_type(result, "move").size(), 0, "no moves in a plain fight")
