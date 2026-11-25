extends GutTest
## The comparison fight for fight animation treatments (tests/screens/feel/fight_compare): the
## same log every run, still holding the moments it was built for (a card change could move
## them), and its `today` treatment exactly the game's motion and replay.

const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")
const Treatment := preload("res://tests/screens/feel/fight_compare/fight_treatment.gd")
const TodayMotion := preload("res://tests/screens/feel/fight_compare/today_motion.gd")
const SCENE: PackedScene = preload("res://tests/screens/feel/fight_compare/fight_compare.tscn")

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_the_fight_is_the_same_every_run() -> void:
	var first: Array = Compare.fight(_content).events
	var again: Array = Compare.fight(_content).events
	assert_eq(JSON.stringify(again), JSON.stringify(first))


func test_the_fight_holds_its_moments_in_order() -> void:
	var events: Array = Compare.fight(_content).events
	var attacks: Array[int] = []
	for i: int in events.size():
		if events[i]["type"] == "attack":
			attacks.append(i)
	assert_eq(attacks.size(), 7, "seven attacks")
	var a: Dictionary = events[attacks[0]]
	assert_eq([_i(a["slot"]), _i(a["target_slot"])], [0, 0], "(a) straight across")
	assert_eq(_before_damage(events, attacks[0]), [], "(a) plain")
	var b: Dictionary = events[attacks[1]]
	assert_eq([_i(b["slot"]), _i(b["target_slot"])], [0, 3], "(b) a diagonal target")
	assert_eq(_before_damage(events, attacks[1]), [], "(b) plain")
	assert_eq(_before_damage(events, attacks[2]), ["thorn_thorns"], "(c) Thorns first")
	var d: Dictionary = events[attacks[4]]
	var summoned: bool = false
	for value: Variant in _window(events, attacks, 4):
		var event: Dictionary = value
		if event["type"] == "summon" and _i(event.get("source_uid", -1)) == _i(d["uid"]):
			summoned = true
	assert_true(summoned, "(d) the killed attacker's death summons")
	var brock: int = 0
	for value: Variant in _window(events, attacks, 5):
		var event: Dictionary = value
		if event["type"] == "trigger" and str(event["mechanic"]) == "badger_old_brock":
			brock += 1
	assert_eq(brock, 6, "(e) Old Brock six times in one moment")


func test_today_plays_the_games_own_motion_and_replay() -> void:
	var combat: Combat = Compare.fight(_content)
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	var today: RefCounted = Treatments.make("today")
	var script: Script = today.get_script()
	assert_eq(script, Treatment, "today is the base treatment, nothing overridden")
	var mine: FightReplay = today.call("make_replay", base, combat.events, {}, Compare.DAMAGE)
	var game: FightReplay = FightReplay.build(base, combat.events, {}, Compare.DAMAGE)
	assert_eq(JSON.stringify(mine.steps), JSON.stringify(game.steps), "the game's steps")
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	scene.call("start", "today")
	var screen: FightScreen = scene.get("screen")
	var motion: Script = screen._keeper.get_script()
	assert_eq(motion, TodayMotion, "today's motion, kept from before the turn (today_motion.gd)")
	assert_true(screen.is_playing(), "playing")


func test_game_plays_the_games_own_screen_and_schedule() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	scene.call("start", "game")
	var screen: FightScreen = scene.get("screen")
	var plays: Script = screen.get_script()
	assert_eq(plays, FightScreen, "the game's FightScreen, no subclass")
	var motion: Script = screen._keeper.get_script()
	assert_eq(motion, FightMotion, "the game's FightMotion, no subclass")
	assert_not_null(screen._schedule, "playing the game's schedule (FightTimeline)")
	assert_true(screen.is_playing(), "playing")


func test_every_listed_treatment_is_a_treatment() -> void:
	for treatment_name: String in Treatments.ALL:
		var made: RefCounted = Treatments.make(treatment_name)
		var script: Script = made.get_script()
		while script != null and script != Treatment:
			script = script.get_base_script()
		assert_eq(script, Treatment, "%s extends fight_treatment.gd" % treatment_name)


## The mechanics that trigger (or hit) between an attack and its first damage.
static func _before_damage(events: Array, at: int) -> Array:
	var out: Array = []
	for j: int in range(at + 1, events.size()):
		var event: Dictionary = events[j]
		if event["type"] in ["damage", "prevented", "attack"]:
			break
		if event["type"] == "trigger":
			out.append(str(event["mechanic"]))
	return out


static func _window(events: Array, attacks: Array[int], n: int) -> Array:
	var end: int = attacks[n + 1] if n + 1 < attacks.size() else events.size()
	return events.slice(attacks[n], end)


static func _i(value: Variant) -> int:
	return CoreUtil.to_int(value)
