extends GutTest
## The `best` treatment of the comparison fight (tests/screens/feel/fight_compare/best.gd): its
## schedule keeps best.md's numbers for a plain attack, and every contested branch's option
## builds a whole fight that ends on the core's board. Exploratory; nothing here is the game.

const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")
const Timeline := preload("res://tests/screens/feel/fight_compare/best_timeline.gd")
const SCENE: PackedScene = preload("res://tests/screens/feel/fight_compare/fight_compare.tscn")

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_a_plain_attack_keeps_the_proposals_numbers() -> void:
	var plan: Dictionary = _plan({})
	var attacks: Array = plan["attacks"]
	var first: Dictionary = attacks[0]
	assert_eq(_i(first["lift"]), Timeline.REST, "lifts after the 30 f rest")
	assert_eq(_i(first["lift_frames"]), 10, "10 f lift")
	assert_eq(_i(first["hold_frames"]), 16, "16 f hold")
	assert_eq(_i(first["strike_frames"]), 7, "7 f strike straight across")
	assert_eq(_i(first["contact"]), Timeline.REST + 33, "contact 33 f after the lift starts")
	assert_almost_eq(_f(first["stop_gap_h"]), 0.62, 0.001, "today's near stop")
	assert_eq(_i(first["next_lift"]), _i(first["contact"]) + 28, "next lifts at C+28")
	var thorns_kill: Dictionary = attacks[4]
	var no_strike: bool = thorns_kill["no_strike"]
	assert_true(no_strike, "(d) Thorns kills the attacker: no strike")


func test_every_option_plays_the_whole_fight() -> void:
	var sets: Array[Dictionary] = [{}]
	for branch: String in ["CB1", "CB2", "CB5", "CB6", "CB7"]:
		var table: Dictionary = _table(branch)
		for option: String in table:
			sets.append({branch: option})
	for option: String in Timeline.CURVES:
		sets.append({"CB3": option})
	for option: String in Timeline.BEFORE_MODES:
		sets.append({"CB4": option})
	for chosen: Dictionary in sets:
		var plan: Dictionary = _plan(chosen)
		var attacks: Array = plan["attacks"]
		var notes: Array = plan["notes"]
		assert_eq(attacks.size(), 7, "%s: seven attacks" % str(chosen))
		assert_eq(notes, [], "%s: every change shows in the log's order" % str(chosen))


func test_only_best_combos_speed_up() -> void:
	var sped: Array[bool] = []
	for option: String in ["best", "bg"]:
		var attacks: Array = _plan({"CB7": option})["attacks"]
		var chain: Dictionary = attacks[5]
		var on: bool = chain["speedup"]
		sped.append(on)
	assert_eq(sped, [true, false], "rule 7 speeds up (e)'s chain for best only")


func test_best_plays_on_the_fight_screen() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	scene.call("start", "best", {"CB7": "best_xn"})
	var screen: FightScreen = scene.get("screen")
	assert_true(screen.is_playing(), "playing")
	for i: int in 3:
		await get_tree().process_frame
	assert_true(screen.is_playing(), "still playing")


func _plan(chosen: Dictionary) -> Dictionary:
	var combat: Combat = Compare.fight(_content)
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	var best: RefCounted = Treatments.make("best")
	best.call("configure", chosen)
	var replay: FightReplay = best.call("make_replay", base, combat.events, {}, Compare.DAMAGE)
	assert_gt(replay.steps.size(), 10, "steps")
	var plan: Dictionary = best.call("plan")
	return plan


static func _table(branch: String) -> Dictionary:
	var tables: Dictionary = {
		"CB1": Timeline.WINDUPS,
		"CB2": Timeline.STOPS,
		"CB5": Timeline.FALLS,
		"CB6": Timeline.LIFTS,
		"CB7": Timeline.COMBOS,
	}
	var table: Dictionary = tables[branch]
	return table


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
