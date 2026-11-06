extends GutTest
## Sound: each screen event asks for the right sound by name, every name has a file, fights at ×4
## are rate-limited, a skipped fight is silent, and volumes save. No test can say they sound good.

const App := preload("res://src/ui/app.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const Settings := preload("res://src/ui/settings.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CombatSounds := preload("res://src/ui/screens/combat_sounds.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const SettingsScreen := preload("res://src/ui/screens/settings_screen.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const LatchButton := preload("res://src/ui/widgets/latch_button.gd")

const AUDIO_DIR: String = "res://assets/audio"
const MAX_TOTAL_BYTES: int = 6_000_000
const OOZE: Dictionary = {"iid": 1, "def_id": "o", "name": "Blob", "tribes": ["Oozes"], "cost": 3}
const FOX: Dictionary = {"iid": 2, "def_id": "f", "name": "Fox", "tribes": ["Hunters"], "cost": 3}
const FAIRY: Dictionary = {"iid": 3, "def_id": "y", "name": "Pip", "tribes": ["Fairies"]}


## Says yes to everything, or `refuse` when set, and shows whatever state the test gives it.
class YesPort:
	extends GamePort
	var view: Dictionary = {}
	var next_view: Dictionary = {}
	var refuse: String = ""

	func get_state() -> Dictionary:
		return view

	func _answer() -> String:
		if refuse.is_empty() and not next_view.is_empty():
			view = next_view
		return refuse

	func buy(_shop_index: int) -> String:
		return _answer()

	func sell(_slot: int) -> String:
		return _answer()

	func play(_hand_index: int, _slot: int) -> String:
		return _answer()

	func move(_from_slot: int, _to_slot: int) -> String:
		return _answer()

	func refresh() -> String:
		return _answer()

	func toggle_freeze() -> String:
		return _answer()

	func tier_up() -> String:
		return _answer()

	func end_turn() -> String:
		return _answer()

	func use_power(_slot: int = -1) -> String:
		return _answer()

	func choose(_index: int) -> String:
		return _answer()


func before_each() -> void:
	Settings.path = "user://test_sound_settings.cfg"
	DirAccess.remove_absolute(Settings.path)
	Settings.reset()
	Sfx.reset_limits()
	Sfx.logging = true


func after_each() -> void:
	Sfx.logging = false
	Sfx.reset_limits()
	DirAccess.remove_absolute(Settings.path)
	Settings.reset()
	Sfx.apply_volumes()


func _state(extra: Dictionary = {}) -> Dictionary:
	var view: Dictionary = {
		"round": 1,
		"gold": 5,
		"tier": 1,
		"shop": [FOX],
		"hand": [],
		"board": [null, null, null, null, null, null, null],
		"hero": {"aim": "none"},
	}
	view.merge(extra, true)
	return view


func _recruit(view: Dictionary = {}) -> Array:
	var port: YesPort = YesPort.new()
	port.view = _state(view)
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	Sfx.requests.clear()
	return [screen, port]


func _heard() -> PackedStringArray:
	var heard: PackedStringArray = Sfx.requests.duplicate()
	Sfx.requests.clear()
	return heard


# --- the files ------------------------------------------------------------------------------


func test_every_name_has_a_file_and_every_file_a_name() -> void:
	for sound: String in Sfx.SOUNDS:
		assert_true(ResourceLoader.exists(Sfx.FOLDER % sound), "%s has a file" % sound)
		assert_true(load(Sfx.FOLDER % sound) is AudioStreamWAV, "%s loads" % sound)
	var total: int = 0
	for file: String in DirAccess.get_files_at(AUDIO_DIR):
		if file.ends_with(".wav"):
			assert_true(Sfx.SOUNDS.has(file.get_basename()), "%s is a known name" % file)
			total += FileAccess.get_file_as_bytes(AUDIO_DIR.path_join(file)).size()
	assert_lt(total, MAX_TOTAL_BYTES, "the sounds stay small")


func test_a_sound_really_plays_on_the_app_instance() -> void:
	var app: App = App.new()
	add_child_autofree(app)
	Sfx.play("buy")
	var sounding: int = 0
	for child: Node in app.find_children("*", "AudioStreamPlayer", true, false):
		var voice: AudioStreamPlayer = child
		if voice.playing:
			sounding += 1
			assert_between(voice.pitch_scale, 0.94, 1.06, "the pitch varies a little")
	assert_eq(sounding, 1)


# --- the recruit screen ---------------------------------------------------------------------


func test_recruit_buttons_ask_for_their_sounds() -> void:
	var made: Array = _recruit()
	var screen: RecruitScreen = made[0]
	var cases: Dictionary = {
		screen._tier_button: "tier_up",
		screen._refresh_button: "refresh",
		screen._freeze_button: "freeze",
		screen._end_button: "turn_end",
	}
	for button: LeafButton in cases:
		button.disabled = false
		button.pressed.emit()
		var sound: String = cases[button]
		assert_eq(_heard(), PackedStringArray(["tap", sound]))


func test_a_refused_action_only_clicks() -> void:
	var made: Array = _recruit()
	var screen: RecruitScreen = made[0]
	var port: YesPort = made[1]
	port.refuse = "Not enough gold"
	screen._refresh_button.pressed.emit()
	assert_eq(_heard(), PackedStringArray(["tap"]))


func test_buying_and_selling_and_moving() -> void:
	var made: Array = _recruit({"board": [FOX, null, null, null, null, null, null]})
	var screen: RecruitScreen = made[0]
	screen._selected = {"zone": "shop", "index": 0}
	screen._on_buy_selected()
	assert_eq(_heard(), PackedStringArray(["buy"]))
	screen._drop({"zone": "shop", "index": 0}, "hand", 0)
	assert_eq(_heard(), PackedStringArray(["buy"]))
	screen._selected = {"zone": "board", "index": 0}
	screen._on_sell_selected()
	assert_eq(_heard(), PackedStringArray(["sell"]))
	screen._drop({"zone": "board", "index": 0}, "shop", 0)
	assert_eq(_heard(), PackedStringArray(["sell"]))
	screen._drop({"zone": "board", "index": 0}, "board", 3)
	assert_eq(_heard(), PackedStringArray(["place"]))


func test_oozes_and_fairies_squeak_when_played_others_do_not() -> void:
	var made: Array = _recruit({"hand": [OOZE, FOX, FAIRY]})
	var screen: RecruitScreen = made[0]
	screen._drop({"zone": "hand", "index": 0}, "board", 0)
	assert_eq(_heard(), PackedStringArray(["squeak_ooze", "place"]))
	screen._drop({"zone": "hand", "index": 1}, "board", 1)
	assert_eq(_heard(), PackedStringArray(["place"]))
	screen._drop({"zone": "hand", "index": 2}, "board", 2)
	assert_eq(_heard(), PackedStringArray(["squeak_fairy", "place"]))


func test_hero_power_asks_for_its_sound() -> void:
	var made: Array = _recruit()
	var screen: RecruitScreen = made[0]
	screen._on_hero_power()
	assert_eq(_heard(), PackedStringArray(["hero_power"]))


func test_a_new_discover_opens_with_its_sound_once() -> void:
	var options: Array = [FOX, OOZE]
	var port: YesPort = YesPort.new()
	port.view = _state({"pending_choice": {"kind": "discover", "options": options}})
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	assert_eq(_heard(), PackedStringArray(["discover"]))
	screen.render()
	assert_eq(_heard(), PackedStringArray(), "already open: no second sound")


func test_a_new_turn_rattles_the_purse_but_the_first_does_not() -> void:
	var port: YesPort = YesPort.new()
	port.view = _state({"round": 2})
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	assert_eq(_heard(), PackedStringArray(["gold"]))
	port.view = _state({"round": 1})
	var first: RecruitScreen = RecruitScreen.new()
	add_child_autofree(first)
	first.setup(port)
	assert_eq(_heard(), PackedStringArray())


func test_gold_gained_rattles_except_from_a_sale() -> void:
	var made: Array = _recruit({"board": [FOX, null, null, null, null, null, null]})
	var screen: RecruitScreen = made[0]
	var port: YesPort = made[1]
	port.next_view = _state({"gold": 9})
	screen._refresh_button.pressed.emit()
	assert_eq(_heard(), PackedStringArray(["tap", "refresh", "gold"]))
	port.view = _state({"gold": 5, "board": [FOX, null, null, null, null, null, null]})
	screen.render()
	screen._drop({"zone": "board", "index": 0}, "shop", 0)
	assert_eq(_heard(), PackedStringArray(["sell"]))


func test_a_triple_asks_for_its_sound() -> void:
	var copy: Dictionary = {"iid": 7, "def_id": "f", "name": "Fox", "cost": 3}
	var made: Array = _recruit({"hand": [copy, copy.merged({"iid": 8})]})
	var screen: RecruitScreen = made[0]
	var port: YesPort = made[1]
	var golden: Dictionary = {"iid": 9, "def_id": "f", "name": "Fox", "golden": true, "copies": 3}
	port.next_view = _state({"hand": [golden], "shop": []})
	screen._drop({"zone": "shop", "index": 0}, "hand", 0)
	var heard: PackedStringArray = _heard()
	assert_true(heard.has("buy"), "buy: %s" % heard)
	assert_true(heard.has("triple"), "triple: %s" % heard)


func test_acorns_combining_asks_for_its_sound() -> void:
	var acorn: Dictionary = {"iid": 1, "def_id": "acorn", "name": "Acorn", "combines_into": "stash"}
	var made: Array = _recruit({"hand": [acorn, acorn.merged({"iid": 2})], "shop": [acorn]})
	var screen: RecruitScreen = made[0]
	var port: YesPort = made[1]
	var stash: Dictionary = {"iid": 9, "def_id": "stash", "name": "Stash"}
	port.next_view = _state({"hand": [stash], "shop": []})
	screen._drop({"zone": "shop", "index": 0}, "hand", 0)
	assert_true(_heard().has("acorns_combine"))


func test_a_ring_landing_asks_for_its_sound() -> void:
	var made: Array = _recruit()
	var screen: RecruitScreen = made[0]
	var port: YesPort = made[1]
	var ring: Dictionary = {"name": "Ring", "text": "", "attack": 1, "health": 1}
	var effects: Array = [[ring], [], [], [], [], [], []]
	port.next_view = _state({"slot_effects": effects})
	screen._refresh_button.pressed.emit()
	assert_eq(_heard(), PackedStringArray(["tap", "refresh", "ring"]))


func test_every_wooden_button_clicks() -> void:
	var buttons: Array[BaseButton] = [LeafButton.new(), TokenButton.new("x"), LatchButton.new()]
	for button: BaseButton in buttons:
		add_child_autofree(button)
		button.pressed.emit()
		assert_eq(_heard(), PackedStringArray(["tap"]))


# --- the fight ------------------------------------------------------------------------------


func _fight_model() -> CombatModel:
	var model: CombatModel = CombatModel.new()
	model.units[1] = {"tribes": ["Oozes"]}
	model.units[2] = {"tribes": ["Hunters"]}
	model.units[3] = {"tribes": ["Fairies"]}
	return model


func test_each_fight_event_names_its_sound() -> void:
	var model: CombatModel = _fight_model()
	var cases: Array = [
		[{"type": "attack", "attacker": 2}, ["attack"]],
		[{"type": "attack", "attacker": 1}, ["attack", "squeak_ooze"]],
		[{"type": "attack", "attacker": 3}, ["attack", "squeak_fairy"]],
		[{"type": "damage", "amount": 1}, ["hit_small"]],
		[{"type": "damage", "amount": 2}, ["hit_small"]],
		[{"type": "damage", "amount": 3}, ["hit_medium"]],
		[{"type": "damage", "amount": 6}, ["hit_medium"]],
		[{"type": "damage", "amount": 7}, ["hit_big"]],
		[{"type": "death", "uid": 1}, ["death"]],
		[{"type": "summon"}, ["summon"]],
		[{"type": "trigger", "uid": 1}, ["keyword"]],
		[{"type": "status", "on": true}, ["keyword"]],
		[{"type": "status", "on": false}, []],
		[{"type": "whistle"}, ["keyword"]],
		[{"type": "health_loss"}, ["keyword"]],
		[{"type": "slot_mark"}, ["ring"]],
		[{"type": "slot_hex"}, ["ring"]],
		[{"type": "stats"}, []],
	]
	for case: Array in cases:
		var event: Dictionary = case[0]
		var names: Array = case[1]
		var want: PackedStringArray = PackedStringArray(names)
		assert_eq(CombatSounds.names_for(event, model, 0), want, str(event))


func test_the_result_sound_follows_the_players_side() -> void:
	var model: CombatModel = _fight_model()
	var end: Dictionary = {"type": "combat_end"}
	model.winner = 1
	assert_eq(CombatSounds.names_for(end, model, 1), PackedStringArray(["win"]))
	assert_eq(CombatSounds.names_for(end, model, 0), PackedStringArray(["loss"]))
	model.winner = -1
	assert_eq(CombatSounds.names_for(end, model, 0), PackedStringArray(["turn_end"]))


func _fight_screen() -> CombatScreen:
	var combat: Dictionary = FixturePort.load_json("res://tests/ui/data/combat_all_events.json")
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	screen.setup(combat, PackedStringArray(["You", "Enemy"]), 0, "Round 1")
	return screen


func test_stepping_through_a_fight_asks_for_sounds() -> void:
	var screen: CombatScreen = _fight_screen()
	for i: int in screen.events.size():
		screen.step_once()
	var heard: PackedStringArray = _heard()
	assert_true(heard.has("attack"), "attack in %s" % heard)
	assert_true(heard.has("death"), "death in %s" % heard)
	assert_true(heard.has("win") or heard.has("loss") or heard.has("turn_end"), "a result")


func test_a_skipped_fight_makes_no_sound() -> void:
	var screen: CombatScreen = _fight_screen()
	screen.skip_to_end()
	assert_true(screen.is_showing_result(), "the fight did end")
	assert_eq(_heard(), PackedStringArray())


func test_skip_stops_what_is_ringing() -> void:
	var app: App = App.new()
	add_child_autofree(app)
	Sfx.play("win")
	Sfx.silence()
	for child: Node in app.find_children("*", "AudioStreamPlayer", true, false):
		assert_false((child as AudioStreamPlayer).playing)


func test_four_times_speed_does_not_machine_gun() -> void:
	# ×4: an event every 100 to 125 ms.
	var pattern: PackedStringArray = ["attack", "hit_medium", "hit_small", "keyword"]
	var played: int = 0
	var seconds: int = 10
	var event_ms: int = 110
	for tick: int in 90:
		if Sfx.allowed(pattern[tick % pattern.size()], 100_000 + tick * event_ms):
			played += 1
	assert_lte(played, Sfx.BUDGET_PER_SECOND * seconds, "at most the budget per second")
	assert_gt(played, seconds, "the fight isn't silent either")


func test_normal_speed_is_not_limited() -> void:
	# ×1: the same pattern at the quickest event's 400 ms: every sound gets through.
	var pattern: PackedStringArray = ["attack", "hit_medium", "hit_small", "keyword"]
	for tick: int in 40:
		assert_true(Sfx.allowed(pattern[tick % pattern.size()], 100_000 + tick * 400))


func test_a_big_hit_at_speed_is_heard_whatever_the_budget() -> void:
	for tick: int in Sfx.BUDGET_PER_SECOND:
		Sfx.allowed(Sfx.BUDGETED[tick], 100_000)
	assert_false(Sfx.allowed("hit_small", 100_201), "the budget is spent")
	assert_true(Sfx.allowed("hit_big", 100_202))


func test_a_death_at_speed_is_heard_whatever_the_budget() -> void:
	for tick: int in Sfx.BUDGET_PER_SECOND:
		Sfx.allowed(Sfx.BUDGETED[tick], 100_000)
	assert_false(Sfx.allowed("attack", 100_001), "the budget is spent")
	assert_true(Sfx.allowed("death", 100_002))


# --- settings -------------------------------------------------------------------------------


func test_volume_grooves_save_and_set_the_buses() -> void:
	var screen: SettingsScreen = SettingsScreen.new()
	add_child_autofree(screen)
	assert_eq(screen.master_groove.value, 80.0, "shows the default")
	screen.master_groove.value = 50.0
	assert_almost_eq(AudioServer.get_bus_volume_db(0), 2.0 * linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(0))
	Settings.reset()
	Settings.load_saved()
	assert_almost_eq(Settings.master_volume, 0.5, 0.001)
	screen.master_groove.value = 0.0
	assert_true(AudioServer.is_bus_mute(0), "zero is silent")


func test_a_broken_saved_volume_falls_back() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("sound", "master", "loud")
	file.save(Settings.path)
	Settings.load_saved()
	assert_eq(Settings.master_volume, Settings.DEFAULT_MASTER)
	file.set_value("sound", "master", 40.0)
	file.save(Settings.path)
	Settings.load_saved()
	assert_eq(Settings.master_volume, 1.0, "clamped")
