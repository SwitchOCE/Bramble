extends GutTest
## The fight replay against the rules core, event by event: over a batch of random fights (many
## with an aura unit), after each moment of the log the numbers the fight screen would show equal
## the core's own units. Adapted from the scope review's probe (PR 82). Also checks the steps: no
## step repeats the one before, and every lunge starts from rest.

const CoreKit := preload("res://tests/core/core_kit.gd")
const UNITS_PATH: String = CoreKit.LIBRARY_PATH
const FIGHTS: int = 150
const SlotChecks := preload("res://tests/screens/slot_assertions.gd")
const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")

var _slot_screen: FightScreen
var _slot_states: int = 0


func before_each() -> void:
	_slot_screen = SCREEN.instantiate() as FightScreen
	add_child_autofree(_slot_screen)
	_slot_screen._keeper.animate = false
	_slot_states = 0


func after_each() -> void:
	gut.p("slot invariant checked %d replay states" % _slot_states)
	assert_gt(_slot_states, 0, "every generated replay step was rendered")
	await get_tree().process_frame
	await get_tree().process_frame


## A fight that notes, after each logged event, every unit the core has on the board.
class Spy:
	extends Combat
	## per event: {"side:slot": [uid, attack, health, max_health]}
	var truth: Array[Dictionary] = []

	func _log(event: Dictionary) -> void:
		super._log(event)
		var snap: Dictionary = {}
		for side: int in 2:
			var row: Array = sides[side]
			for value: Variant in row:
				if value != null:
					var unit: CombatUnit = value
					snap["%d:%d" % [side, unit.slot]] = [
						unit.uid, unit.attack(), unit.health(), unit.max_health()
					]
		truth.append(snap)


func _spy(game: GameSession, fight_seed: int) -> Spy:
	var spy: Spy = Spy.new()
	spy.geometry = game.geometry
	spy.config = game.config
	spy.registry = game.registry
	spy.library = game.library
	spy._first_rng = Rng.derive(fight_seed, "first")
	spy._soc_rng = Rng.derive(fight_seed, "soc")
	spy._target_rng = Rng.derive(fight_seed, "target")
	spy.effect_rng = Rng.derive(fight_seed, "effect")
	# as Combat.create does
	spy.arrivals = FightArrivals.create(spy)
	spy._auras = FightAuras.create(spy)
	return spy


func _ids() -> Array[String]:
	var out: Array[String] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(UNITS_PATH))
	var data: Dictionary = parsed
	var cards: Array = data["cards"]
	for value: Variant in cards:
		var card: Dictionary = value
		if str(card.get("kind", "unit")) != "spell" and str(card["id"]) != "tk_sprout":
			out.append(str(card["id"]))
	return out


func _catalog(game: GameSession, ids: Array[String]) -> Dictionary:
	var out: Dictionary = {}
	for card_id: String in ids + (["tk_sprout"] as Array[String]):
		var def: UnitDef = game.library.get_card(StringName(card_id))
		out[card_id] = {"name": def.name, "tier": def.tier, "art": "", "health": def.health}
	return out


## Plays one fight into a replay; returns the first difference from the core, or "".
func _wrong(spec_a: Dictionary, spec_b: Dictionary, fight_seed: int) -> String:
	var game: GameSession = CoreKit.session(7)
	var spy: Spy = _spy(game, fight_seed)
	var players: Array[int] = [0, 1]
	spy.run([CoreKit.board(game, spec_a), CoreKit.board(game, spec_b)], players)
	var replay: FightReplay = FightReplay.start({"you_side": 0}, _catalog(game, _ids()))
	for k: int in spy.events.size():
		var event: Dictionary = spy.events[k]
		replay.apply(event, 7)
		# an aura's stats for several units are one moment, logged one unit at a time
		var next: Dictionary = spy.events[k + 1] if k + 1 < spy.events.size() else {}
		if str(event["type"]) == "stats" and str(next.get("type", "")) == "stats":
			continue
		var bad: String = _differs(replay, spy.truth[k])
		if bad != "":
			return "event %d (%s): %s" % [k, event["type"], bad]
	return await _steps_wrong(replay)


func _differs(replay: FightReplay, snap: Dictionary) -> String:
	for side: int in 2:
		var row: Array = replay.boards[side]
		for slot: int in 7:
			var key: String = "%d:%d" % [side, slot]
			var shown: Variant = row[slot]
			if (shown is Dictionary) != snap.has(key):
				return "%s shown %s, on the board %s" % [key, shown is Dictionary, snap.has(key)]
			if not snap.has(key):
				continue
			var unit: Dictionary = shown
			var real: Array = snap[key]
			var got: Array = [
				GlassPieces.as_int(unit["uid"]),
				GlassPieces.as_int(unit["attack"]),
				GlassPieces.as_int(unit["health"]),
			]
			if got != real.slice(0, 3):
				return "%s %s shows uid/attack/health %s, is %s" % [key, unit["id"], got, real]
			var red: bool = got[2] < GlassPieces.as_int(unit["max_health"])
			if red != (GlassPieces.as_int(real[2]) < GlassPieces.as_int(real[3])):
				return "%s %s red is %s" % [key, unit["id"], red]
	return ""


func _steps_wrong(replay: FightReplay) -> String:
	for i: int in replay.steps.size():
		var now: Dictionary = replay.steps[i]["state"]
		_slot_screen.show_state(now)
		_slot_screen.settle()
		var errors: PackedStringArray = SlotChecks.check(_slot_screen)
		_slot_states += 1
		if _slot_states % 16 == 0:
			await get_tree().process_frame
		if not errors.is_empty():
			return "step %d slots: %s" % [i, "; ".join(errors)]
		if i == 0:
			continue
		var before: Dictionary = replay.steps[i - 1]["state"]
		if now == before:
			return "step %d shows nothing new" % i
		var moment: Dictionary = now["moment"]
		var was: Dictionary = before["moment"]
		var lunge: Variant = moment.get("lunge")
		if lunge != null and was.has("lunge") and was["lunge"] != lunge:
			return "step %d lunges straight from another lunge" % i
	return ""


func test_named_fights_match_the_core_after_every_moment() -> void:
	var named: Dictionary = {
		"stand-in 0":
		[
			{0: "t2_shield", 1: "t3_twin", 2: "t1_seed", 4: "t4_phoenix"},
			{0: "t1_guard", 1: "t4_cleaver", 2: "t3_viper", 5: "t1_plain"}
		],
		"venomous":
		[{0: "t1_plain", 1: "t1_plain", 2: "t1_herald"}, {0: "t2_shield", 1: "t3_viper"}],
		"banner beside a seed":
		[{0: "t1_seed", 1: "t3_banner", 2: "t5_hoard"}, {0: "t4_cleaver", 1: "t5_bomber"}],
		"phoenix": [{0: "t4_phoenix"}, {0: "t4_wall"}],
	}
	for label: Variant in named:
		var spec: Array = named[label]
		var a: Dictionary = spec[0]
		var b: Dictionary = spec[1]
		assert_eq(await _wrong(a, b, 11), "", str(label))


func test_random_fights_match_the_core_after_every_moment() -> void:
	var ids: Array[String] = _ids()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var wrong: Array[String] = []
	var with_aura: int = 0
	for s: int in FIGHTS:
		rng.seed = 1000 + s
		var specs: Array[Dictionary] = [{}, {}]
		for side: int in 2:
			for slot: int in rng.randi_range(4, 7):
				specs[side][slot] = ids[rng.randi_range(0, ids.size() - 1)]
				with_aura += 1 if specs[side][slot] == "t3_banner" else 0
		var bad: String = await _wrong(specs[0], specs[1], 100 + s)
		if bad != "":
			wrong.append("seed %d: %s" % [s, bad])
	assert_gt(with_aura, 20, "the batch has aura units in it")
	assert_eq(wrong.size(), 0, "\n".join(wrong.slice(0, 5)))
