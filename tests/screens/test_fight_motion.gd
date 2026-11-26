extends GutTest
## The fight plays from its schedule (FightTimeline) on game time: an attack winds up, strikes
## its actual target and comes home turned, at the same moments in seconds at any frame rate, and
## skip and restart leave a clean table. Tests drive the screen's clock directly (_process with a
## delta), independently of wall-clock rendering.

const SlotChecks := preload("res://tests/screens/slot_assertions.gd")
const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")

const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")

var _screen: FightScreen


## One attack, yours (slot 0) on their back-row unit (slot 6): a diagonal strike. Its exchange
## kills the target, unless `blocked`, where the target's shield takes the hit.
func _events(blocked: bool = false) -> Array:
	var events: Array = [
		{
			"type": "combat_start",
			"boards":
			[
				[{"id": "a", "uid": 1, "slot": 0, "attack": 2, "health": 3}],
				[{"id": "b", "uid": 2, "slot": 6, "attack": 2, "health": 1}],
			],
		},
		{
			"type": "attack",
			"side": 0,
			"slot": 0,
			"uid": 1,
			"target_side": 1,
			"target_slot": 6,
			"target_uid": 2,
		},
	]
	if blocked:
		(
			events
			. append(
				{
					"type": "prevented",
					"side": 1,
					"slot": 6,
					"uid": 2,
					"amount": 2,
					"reason": "absorbed",
					"source_uid": 1,
				}
			)
		)
	else:
		(
			events
			. append(
				{
					"type": "damage",
					"side": 1,
					"slot": 6,
					"uid": 2,
					"amount": 2,
					"health": 0,
					"source_uid": 1,
					"from_attack": true,
				}
			)
		)
	(
		events
		. append(
			{
				"type": "damage",
				"side": 0,
				"slot": 0,
				"uid": 1,
				"amount": 2,
				"health": 1,
				"source_uid": 2,
				"from_attack": true,
			}
		)
	)
	if not blocked:
		events.append({"type": "death", "side": 1, "slot": 6, "uid": 2})
	events.append({"type": "combat_end", "winner": 0})
	return events


func _make(playback_speed: float = 1.0, blocked: bool = false) -> FightReplay:
	var base: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/fight_start.json")
	var replay: FightReplay = FightReplay.build(base, _events(blocked), {})
	_screen = SCREEN.instantiate()
	_screen.speed = playback_speed
	add_child_autofree(_screen)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "initial slot rows")
	_screen.set_process(false)
	_screen.play(replay)
	return replay


## Game time up to schedule frame `frame`, one 60 fps frame at a time.
func _run_to(frame: float) -> void:
	while _screen._clock < frame - 0.0001:
		_screen._process(1.0 / 60.0)


func _plan() -> Dictionary:
	var attacks: Array[Dictionary] = _screen._schedule.attacks
	return attacks[0]


func _tick_tweens(seconds: float) -> void:
	for value: Variant in _screen._keeper._tweens.values():
		var tween: Tween = value
		if tween.is_valid():
			tween.custom_step(seconds)


func test_an_attack_winds_up_strikes_its_target_and_comes_home() -> void:
	_make()
	var plan: Dictionary = _plan()
	var home: Vector2 = _screen.unit_xy(0, 0)
	var target: Vector2 = _screen.unit_xy(1, 6)
	var direction: Vector2 = (target - home).normalized()
	_run_to(GlassPieces.as_float(plan["lift"]) - 1.0)
	var card: Control = _screen.node_for("board", 0)
	assert_eq(card.position, home, "at rest before the lift")
	_run_to(GlassPieces.as_float(plan["lift"]) + FightTimeline.LIFT)
	assert_lt((card.position - home).dot(direction), 0.0, "pulls back before the strike")
	assert_almost_eq(card.scale.x, FightTimeline.LIFT_SCALE, 0.001, "lifted")
	_run_to(GlassPieces.as_float(plan["contact"]))
	card = _screen.node_for("board", 0)
	var gap: float = FightTimeline._stop_gap(home.distance_to(target) / FightTimeline.H)
	assert_almost_eq(
		card.position.distance_to(target), gap * FightTimeline.H, 0.1, "stops short of the target"
	)
	assert_almost_eq(card.scale.x, FightTimeline.POP, 0.001, "the contact pop")
	_run_to(GlassPieces.as_float(plan["release"]) + FightTimeline.unwind_frames())
	card = _screen.node_for("board", 0)
	assert_almost_eq(card.position.distance_to(home), 0.0, 0.1, "home")
	assert_almost_eq(card.rotation_degrees, 0.0, 0.0001, "straight once the turn unwinds")
	assert_eq(card.scale, Vector2.ONE)
	assert_eq(card.modulate, Color.WHITE)


func test_the_target_is_knocked_and_its_burst_shows_on_it() -> void:
	_make()
	var plan: Dictionary = _plan()
	var victim_home: Vector2 = _screen.unit_xy(1, 6)
	_run_to(GlassPieces.as_float(plan["contact"]) + FightTimeline.KNOCK_IN)
	var defender: Control = _screen.node_for("board", 13)
	assert_almost_eq(
		defender.position.distance_to(victim_home), FightTimeline.KNOCK_PX, 0.1, "knocked back"
	)
	_run_to(GlassPieces.as_float(plan["contact"]) + FightTimeline.NUMBERS_AT)
	var hits: Array[Node] = _screen._front.find_children("Hit_*", "", false, false)
	assert_eq(hits.size(), 2, "a burst on each card of the exchange")
	for hit: Node in hits:
		assert_eq((hit as Control).rotation_degrees, 0.0, "damage stays upright")


func test_damage_burst_follows_its_recipient_and_stays_upright() -> void:
	var layer: Control = Control.new()
	add_child_autofree(layer)
	var recipient: Control = Control.new()
	layer.add_child(recipient)
	var hit: Control = Control.new()
	hit.position = Vector2(10.0, 20.0)
	layer.add_child(hit)
	var motion: FightMotion = FightMotion.new(layer)
	var tween: Tween = motion.burst(hit, recipient)
	recipient.position = Vector2(150.0, 200.0)
	recipient.rotation_degrees = 4.0
	tween.custom_step(FightMotion.BURST_IN + FightMotion.BURST_SETTLE)
	assert_eq(hit.position, recipient.position + Vector2(10.0, 20.0))
	assert_eq(hit.rotation_degrees, 0.0, "damage stays upright during card recoil")
	assert_almost_eq(hit.scale.x, 1.0, 0.001)
	tween.custom_step(FightMotion.BURST_READ + FightMotion.BURST_FADE)
	assert_almost_eq(hit.modulate.a, 0.0, 0.001)


func test_death_falls_and_skip_removes_it_even_at_double_speed() -> void:
	var replay: FightReplay = _make(2.0)
	var fall: Dictionary = _screen._schedule.falls[0]
	_run_to(GlassPieces.as_float(fall["frame"]) - 2.0)
	# the card as it is now (the exchange rebuilt it with its new numbers)
	var dying: Control = _screen.node_for("board", 13)
	_run_to(GlassPieces.as_float(fall["frame"]))
	assert_null(_screen.node_for("board", 13), "dead unit is no longer a pointer target")
	# dying alone (CB13 c): its light goes out, it holds, then sinks, on the schedule's clock
	var was: Vector2 = dying.position
	_run_to(GlassPieces.as_float(fall["frame"]) + FightTimeline.DEATH_DARK_FRAMES)
	assert_almost_eq(dying.modulate.r, FightTimeline.DEATH_DARK, 0.001, "its light goes out")
	assert_eq(dying.position, was, "and it holds")
	var sinking: float = FightTimeline.DEATH_DARK_FRAMES + FightTimeline.DEATH_HOLD_FRAMES + 6.0
	_run_to(GlassPieces.as_float(fall["frame"]) + sinking)
	assert_gt(dying.position.distance_to(was), 0.0, "then sinks, distinct from a knock")
	assert_lt(dying.scale.x, 1.0)
	assert_lt(dying.modulate.a, 1.0)
	_screen.skip()
	assert_true(_screen._keeper._fading.is_empty(), "skip leaves no dying cards")
	var motion: FightMotion = _screen._keeper as FightMotion
	assert_true(motion.dying.is_empty(), "nor any drawn by the screen")
	_screen.play(replay)
	assert_eq(_screen.targets_of("board").size(), 2, "restart restores both units")
	for target: Dictionary in _screen.targets_of("board"):
		var node: Control = target["node"]
		assert_eq(node.scale, Vector2.ONE)
		assert_eq(node.rotation_degrees, 0.0)
		assert_eq(node.modulate, Color.WHITE)


func test_redrawing_the_board_mid_attack_keeps_its_pose() -> void:
	_make()
	var plan: Dictionary = _plan()
	_run_to(GlassPieces.as_float(plan["lift"]) + FightTimeline.LIFT / 2.0)
	var card: Control = _screen.node_for("board", 0)
	var was: Transform2D = card.get_transform()
	_screen.toggle_leaderboard()
	_screen._process(0.0)
	assert_eq(_screen.node_for("board", 0).get_transform(), was, "the redraw keeps the pose")
	_run_to(GlassPieces.as_float(plan["contact"]))
	assert_almost_eq(_screen.node_for("board", 0).scale.x, FightTimeline.POP, 0.001)


func test_prevented_hit_uses_cool_light_small_knock_and_zero() -> void:
	_make(1.0, true)
	var plan: Dictionary = _plan()
	_run_to(GlassPieces.as_float(plan["contact"]))
	var victim: Control = _screen.node_for("board", 13)
	assert_eq(victim.modulate, FightTimeline.BLOCK_LIGHT)
	_run_to(GlassPieces.as_float(plan["contact"]) + FightTimeline.KNOCK_IN)
	assert_almost_eq(
		victim.position.distance_to(_screen.unit_xy(1, 6)),
		FightTimeline.KNOCK_PX * FightTimeline.BLOCK_SHARE,
		0.1
	)
	_run_to(GlassPieces.as_float(plan["contact"]) + FightTimeline.NUMBERS_AT)
	var words: Array[String] = []
	for hit: Node in _screen._front.find_children("Hit_*", "", false, false):
		for node: Node in hit.find_children("*", "GlassText", true, false):
			words.append((node as GlassText).words)
	words.sort()
	assert_eq(words, ["-2", "0"] as Array[String], "the shield's 0 beside the strike back")


func test_an_attack_whose_hits_all_do_nothing_still_strikes_and_comes_home() -> void:
	var base: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/fight_start.json")
	var events: Array = _events(true)
	# the strike back blocked too: no attack damage in the log at all
	events[3] = {
		"type": "prevented",
		"side": 0,
		"slot": 0,
		"uid": 1,
		"amount": 2,
		"reason": "absorbed",
		"source_uid": 2,
	}
	var replay: FightReplay = FightReplay.build(base, events, {})
	FightScreen.schedule(replay)
	var plan: Dictionary = replay.plan.attacks[0]
	assert_gt(GlassPieces.as_int(plan["contact"]), 0, "it strikes")
	assert_lt(GlassPieces.as_int(plan["home"]), FightTimeline.FOREVER, "and comes home")
	assert_eq(replay.plan.bursts.size(), 2, "both blocks show")


## The attacker's rotation and centre every 1/6 s of game time, the seconds each step first
## shows, and when the result shows, run at `fps` frames a second.
func _run_at(fps: int) -> Dictionary:
	_make()
	var times: Array[float] = []
	var turns: Array[float] = []
	var places: Array[Vector2] = []
	var shown: Dictionary = {}
	var result: Array[float] = [-1.0]
	_screen.result_shown.connect(func() -> void: result[0] = _screen._clock / 60.0)
	var per_sixth: int = roundi(fps / 6.0)
	for k: int in 24:
		var card: Control = _screen.node_for("board", 0)
		times.append(_screen._clock / 60.0)
		turns.append(card.rotation_degrees if card != null else 0.0)
		places.append(card.position if card != null else Vector2.ZERO)
		for frame: int in per_sixth:
			_screen._process(1.0 / fps)
			if not shown.has(_screen._step):
				shown[_screen._step] = _screen._clock / 60.0
	return {"times": times, "turns": turns, "places": places, "shown": shown, "result": result[0]}


func test_the_same_fight_at_30_and_144_frames_a_second() -> void:
	var slow: Dictionary = _run_at(30)
	var plan: Dictionary = _plan()
	var fast: Dictionary = _run_at(144)
	var slow_times: Array[float] = slow["times"]
	var fast_times: Array[float] = fast["times"]
	var slow_turns: Array[float] = slow["turns"]
	var fast_turns: Array[float] = fast["turns"]
	var slow_places: Array[Vector2] = slow["places"]
	var fast_places: Array[Vector2] = fast["places"]
	var end_s: float = _screen._schedule.end_frame / 60.0
	for k: int in slow_times.size():
		if slow_times[k] >= end_s:
			# the fight is over: its clock stops
			break
		assert_almost_eq(fast_times[k], slow_times[k], 0.0001, "the clock at %d/6 s" % k)
		assert_almost_eq(fast_turns[k], slow_turns[k], 0.01, "the same turn at %d/6 s" % k)
		assert_almost_eq(
			fast_places[k].distance_to(slow_places[k]), 0.0, 0.01, "the same place at %d/6 s" % k
		)
	var slow_shown: Dictionary = slow["shown"]
	var fast_shown: Dictionary = fast["shown"]
	assert_eq(fast_shown.keys(), slow_shown.keys(), "every step shows at both rates")
	for step: Variant in slow_shown:
		assert_almost_eq(
			GlassPieces.as_float(fast_shown[step]),
			GlassPieces.as_float(slow_shown[step]),
			1.0 / 30.0,
			"step %s shows within a frame" % step
		)
	assert_gt(GlassPieces.as_float(slow["result"]), 0.0, "the result showed")
	assert_almost_eq(
		GlassPieces.as_float(fast["result"]), GlassPieces.as_float(slow["result"]), 1.0 / 30.0
	)
	# and the turn is the game's one set: 90 % of TURN_AIM of the path's angle at contact
	var turns: Array[float] = slow["turns"]
	var moving: bool = false
	for turn: float in turns:
		moving = moving or absf(turn) > 1.0
	assert_true(moving, "the diagonal attack turns")
	var home: Vector2 = _screen.unit_xy(0, 0)
	var way: Vector2 = (_screen.unit_xy(1, 6) - home).normalized()
	# yours attacks upward: its top edge leads
	var aim: float = FightMotion.TURN_AIM * rad_to_deg(Vector2(0.0, -1.0).angle_to(way))
	var contact: Dictionary = _screen._schedule.pose("u1", GlassPieces.as_float(plan["contact"]))
	assert_almost_eq(
		GlassPieces.as_float(contact["turn"]),
		aim * FightMotion.TURN_AT_CONTACT,
		0.001,
		"at contact: 90 % of the turn, the lean gone"
	)


## The comparison fight (seven attacks, Thorns, a summon, Old Brock's six triggers) at 30 and 144
## frames a second: every card's turn and place every 1/6 s while it plays (FAST included), and
## each step's first showing, agree.
func test_a_whole_fight_at_30_and_144_frames_a_second() -> void:
	var content: GameContent = GameContent.load_default()
	var combat: Combat = Compare.fight(content)
	var catalog: Dictionary = {}
	ViewAdapter.add_fight_cards(content, combat.events, catalog)
	var runs: Array[Dictionary] = []
	for fps: int in [30, 144]:
		var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
		base.erase("boards")
		base["slots"] = [[], []]
		var replay: FightReplay = FightReplay.build(base, combat.events, catalog, Compare.DAMAGE)
		_screen = SCREEN.instantiate()
		add_child_autofree(_screen)
		_screen.set_process(false)
		_screen.play(replay)
		var cards: Dictionary = {}
		var shown: Dictionary = {}
		var per_sixth: int = roundi(fps / 6.0)
		# as many samples at both rates: the fight's length in seconds, FAST's part at x1.5
		var plan: FightTimeline = _screen._schedule
		var end_s: float = plan.end_frame / 60.0
		if plan.fast_from >= 0:
			end_s -= (plan.fast_to - plan.fast_from) / 60.0 * (1.0 - 1.0 / plan.FAST_SPEED)
		var samples: int = floori((end_s - 0.2) * 6.0)
		var k: int = 0
		while k < samples:
			for key: Variant in _screen._keeper._kept:
				var node: Control = _screen._kept_node(str(key))
				cards["%s@%d" % [key, k]] = [node.rotation_degrees, node.position]
			for frame: int in per_sixth:
				_screen._process(1.0 / fps)
				if not shown.has(_screen._step):
					shown[_screen._step] = _screen._clock / 60.0
			k += 1
		runs.append({"cards": cards, "shown": shown, "samples": k})
		_screen.queue_free()
	var slow: Dictionary = runs[0]["cards"]
	var fast: Dictionary = runs[1]["cards"]
	assert_gt(_i(runs[0]["samples"]), 54, "over 9 s of fight")
	assert_eq(fast.keys(), slow.keys(), "the same cards at every sample")
	var turned: int = 0
	for at: Variant in slow:
		var a: Array = slow[at]
		var b: Array = fast[at]
		var turn_a: float = a[0]
		var turn_b: float = b[0]
		var place_a: Vector2 = a[1]
		var place_b: Vector2 = b[1]
		assert_almost_eq(turn_b, turn_a, 0.01, "%s's turn" % at)
		assert_almost_eq(place_b.distance_to(place_a), 0.0, 0.01, "%s's place" % at)
		if absf(turn_a) > 1.0:
			turned += 1
	assert_gt(turned, 10, "cards turn during it")
	var slow_shown: Dictionary = runs[0]["shown"]
	var fast_shown: Dictionary = runs[1]["shown"]
	assert_eq(fast_shown.keys(), slow_shown.keys(), "every step shows at both rates")
	for step: Variant in slow_shown:
		assert_almost_eq(
			GlassPieces.as_float(fast_shown[step]),
			GlassPieces.as_float(slow_shown[step]),
			1.0 / 30.0,
			"step %s shows within a frame" % step
		)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


func test_skip_mid_attack_leaves_every_card_straight_and_home() -> void:
	for into: float in [
		FightTimeline.LIFT + 4.0, FightTimeline.LIFT + FightTimeline.HOLD_LEAST + 6.0
	]:
		_make()
		var plan: Dictionary = _plan()
		_run_to(GlassPieces.as_float(plan["lift"]) + into)
		assert_ne(_screen.node_for("board", 0).rotation_degrees, 0.0, "turned before the skip")
		_screen.skip()
		for target: Dictionary in _screen.targets_of("board"):
			var node: Control = target["node"]
			assert_almost_eq(node.rotation_degrees, 0.0, 0.0001, "straight after a skip")
			assert_eq(node.scale, Vector2.ONE, "full size after a skip")
			var index: int = target["index"]
			assert_almost_eq(
				node.position.distance_to(_screen.unit_xy(floori(index / 7.0), index % 7)),
				0.0,
				0.1,
				"home after a skip"
			)
		assert_true(
			(
				_screen._front.find_children("Hit_*", "", false, false).is_empty()
				or _screen._bursts_on.is_empty()
			),
			"no burst left over"
		)
