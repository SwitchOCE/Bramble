extends GutTest
## Motion must fit its replay holds, reach the actual target, and leave a clean
## table on skip/restart. Tests advance tweens directly, independently of wall-clock rendering.

const SlotChecks := preload("res://tests/screens/slot_assertions.gd")

const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")

var _screen: FightScreen


func _make(playback_speed: float = 1.0) -> FightReplay:
	var base: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/fight_start.json")
	var events: Array = [
		{
			"type": "combat_start",
			"boards":
			[
				[{"id": "a", "uid": 1, "slot": 0, "attack": 2, "health": 3}],
				[{"id": "b", "uid": 2, "slot": 6, "attack": 2, "health": 1}],
			],
		},
		{"type": "attack", "side": 0, "slot": 0, "target_side": 1, "target_slot": 6},
		{"type": "damage", "uid": 1, "health": 1, "amount": 2, "source_uid": 2},
		{"type": "damage", "uid": 2, "health": 0, "amount": 2, "source_uid": 1},
		{"type": "death", "uid": 2},
		{"type": "combat_end", "winner": 0},
	]
	var replay: FightReplay = FightReplay.build(base, events, {})
	_screen = SCREEN.instantiate()
	_screen.speed = playback_speed
	add_child_autofree(_screen)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "initial slot rows")
	_screen.set_process(false)
	_screen.play(replay)
	return replay


func _tick_motion(seconds: float) -> void:
	for value: Variant in _screen._keeper._tweens.values():
		var tween: Tween = value
		if tween.is_valid():
			tween.custom_step(seconds)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows during live motion")


func test_diagonal_attack_winds_up_accelerates_and_contacts_the_target() -> void:
	_make()
	_screen._process(FightReplay.HOLD_START)
	var card: Control = _screen.node_for("board", 0)
	var home: Vector2 = _screen.unit_xy(0, 0)
	var target: Vector2 = _screen.unit_xy(1, 6)
	var direction: Vector2 = (target - home).normalized()
	_tick_motion(FightMotion.WINDUP_TIME)
	assert_lt((card.position - home).dot(direction), 0.0, "pulls away before launching")
	assert_gt(absf(card.rotation_degrees), 0.0, "attacker tilts for the wind-up")
	_tick_motion(FightMotion.ATTACK_TIME - FightMotion.WINDUP_TIME + 0.001)
	assert_almost_eq(
		card.position.distance_to(target), card.size.y * FightMotion.CONTACT_PER_H, 0.1
	)
	assert_lt(FightMotion.ATTACK_TIME, FightReplay.HOLD_LUNGE, "contact within the old attack hold")


func test_hit_recoils_survivor_home_and_later_damage_starts_at_its_current_pose() -> void:
	_make()
	_screen._process(FightReplay.HOLD_START)
	_tick_motion(FightMotion.ATTACK_TIME)
	_screen._process(FightReplay.HOLD_LUNGE)
	var attacker: Control = _screen.node_for("board", 0)
	var defender: Control = _screen.node_for("board", 13)
	var victim_home: Vector2 = _screen.unit_xy(1, 6)
	_tick_motion(FightMotion.HIT_TIME)
	assert_gt(defender.position.distance_to(victim_home), 0.0, "defender visibly takes the hit")
	_tick_motion(FightMotion.RETURN_TIME + FightMotion.CONTACT_HOLD)
	assert_almost_eq(attacker.position.distance_to(_screen.unit_xy(0, 0)), 0.0, 0.1)
	assert_almost_eq(defender.position.distance_to(victim_home), 0.0, 0.1)
	assert_eq(attacker.scale, Vector2.ONE)
	assert_eq(attacker.modulate, Color.WHITE)
	# A trigger after this hit retains the log's lunge but must not launch the attacker again.
	var next: Dictionary = _screen.state.duplicate(true)
	var moment: Dictionary = next["moment"]
	moment.erase("splashes")
	moment["trigger"] = {"side": 1, "slot": 6}
	_screen.show_state(next)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	_tick_motion(1.0)
	assert_almost_eq(
		_screen.node_for("board", 0).position.distance_to(_screen.unit_xy(0, 0)), 0.0, 0.1
	)
	# A later effect still belongs to the same logical attack; its recipient has returned.
	moment.erase("trigger")
	moment["splashes"] = [{"side": 0, "slot": 0, "amount": 4}]
	_screen.show_state(next)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	var later_hit: Control = _screen._front.get_node("Hit_0")
	assert_lt(
		later_hit.position.distance_to(_screen.unit_xy(0, 0)),
		_screen.card_box().y,
		"later damage starts on the returned card, not at the old collision"
	)


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


func test_death_has_an_exit_and_skip_removes_it_even_at_double_speed() -> void:
	var replay: FightReplay = _make(2.0)
	_screen._process(FightReplay.HOLD_START / 2.0)
	_tick_motion(FightMotion.ATTACK_TIME / 2.0)
	_screen._process(FightReplay.HOLD_LUNGE / 2.0)
	_tick_motion(FightMotion.RETURN_TIME)
	var dying: Control = _screen.node_for("board", 13)
	var was: Vector2 = dying.position
	_screen._process(FightReplay.HOLD_SPLASH / 2.0)
	assert_null(_screen.node_for("board", 13), "dead unit is no longer a pointer target")
	_tick_motion(FightMotion.DEATH_TIME / 4.0)
	assert_gt(dying.position.distance_to(was), 0.0, "death moves away, distinct from taking a hit")
	assert_gt(absf(dying.rotation_degrees), 0.0)
	assert_lt(dying.modulate.a, 1.0)
	_screen.skip()
	assert_true(_screen._keeper._fading.is_empty(), "skip leaves no dying cards")
	_screen.play(replay)
	assert_eq(_screen.targets_of("board").size(), 2, "restart restores both units")
	for target: Dictionary in _screen.targets_of("board"):
		var node: Control = target["node"]
		assert_eq(node.scale, Vector2.ONE)
		assert_eq(node.rotation_degrees, 0.0)
		assert_eq(node.modulate, Color.WHITE)


func test_redrawing_the_board_during_windup_preserves_the_attack_clock() -> void:
	_make()
	_screen._process(FightReplay.HOLD_START)
	_tick_motion(FightMotion.WINDUP_TIME / 2.0)
	var card: Control = _screen.node_for("board", 0)
	var original: Tween = _screen._keeper._tweens[card]
	_screen.toggle_leaderboard()
	var current: Tween = _screen._keeper._tweens[card]
	assert_same(current, original, "redraw keeps the running attack")
	_tick_motion(FightMotion.ATTACK_TIME - FightMotion.WINDUP_TIME / 2.0 + 0.001)
	assert_almost_eq(card.position.distance_to(_screen.lunge_xy(_screen._lunge())), 0.0, 0.1)


func test_prevented_hit_uses_cool_light_small_recoil_and_zero() -> void:
	_make()
	_screen._process(FightReplay.HOLD_START)
	_tick_motion(FightMotion.ATTACK_TIME)
	var blocked: Dictionary = _screen.state.duplicate(true)
	var moment: Dictionary = blocked["moment"]
	moment["splashes"] = [{"side": 1, "slot": 6, "amount": 0, "blocked": true}]
	_screen.show_state(blocked)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	var victim: Control = _screen.node_for("board", 13)
	assert_eq(victim.modulate, FightMotion.BLOCK_LIGHT)
	_tick_motion(FightMotion.HIT_TIME)
	assert_almost_eq(
		victim.position.distance_to(_screen.unit_xy(1, 6)),
		FightMotion.HIT_PX * FightMotion.BLOCK_SHARE,
		0.1
	)
	var hit: Node = _screen._front.get_node("Hit_0")
	var words: Array[String] = []
	for node: Node in hit.find_children("*", "GlassText", true, false):
		words.append((node as GlassText).words)
	assert_eq(words, ["0"] as Array[String])


func test_motion_fits_inside_its_replay_holds() -> void:
	# The holds themselves may change (owner, 18 Nov:
	# docs/design/owner-notes/2026-11-18b-fight-timing-and-grouping.md); motion must fit them.
	assert_lte(FightMotion.ATTACK_TIME, FightReplay.HOLD_LUNGE)
	assert_lte(FightMotion.CONTACT_HOLD + FightMotion.RETURN_TIME, FightReplay.HOLD_SPLASH)
	assert_lte(FightMotion.HIT_TIME + FightMotion.RETURN_TIME, FightReplay.HOLD_SPLASH)
	assert_lte(FightMotion.DEATH_TIME, FightReplay.HOLD_DEATH)
	assert_lte(
		(
			FightMotion.BURST_IN
			+ FightMotion.BURST_SETTLE
			+ FightMotion.BURST_READ
			+ FightMotion.BURST_FADE
		),
		FightReplay.HOLD_SPLASH
	)
	assert_lte(FightMotion.CONTACT_HOLD + FightMotion.TURN_UNWIND, FightReplay.HOLD_SPLASH)


## The attack's rotation every 1/6 s from its start (a time both rates land on), its hit at 1/3 s,
## run at `fps` frames a second.
func _turn_every_sixth(fps: int) -> Array[float]:
	_make()
	_screen._process(FightReplay.HOLD_START)
	var samples: Array[float] = []
	for k: int in 6:
		if k == 2:
			_screen._process(FightReplay.HOLD_LUNGE)
		# the hit rebuilds the card (its numbers change): the node of now
		samples.append(_screen.node_for("board", 0).rotation_degrees)
		for frame: int in roundi(fps / 6.0):
			for value: Variant in _screen._keeper._tweens.values():
				var tween: Tween = value
				if tween.is_valid():
					tween.custom_step(1.0 / fps)
	return samples


func test_every_attack_turns_toward_its_target_on_game_time() -> void:
	var slow: Array[float] = _turn_every_sixth(30)
	var home: Vector2 = _screen.unit_xy(0, 0)
	var direction: Vector2 = (_screen.unit_xy(1, 6) - home).normalized()
	var fast: Array[float] = _turn_every_sixth(144)
	for k: int in slow.size():
		assert_almost_eq(fast[k], slow[k], 0.01, "the same turn at %d/6 s at 30 and 144 fps" % k)
	var lead: float = -1.0 if direction.y > 0.0 else 1.0
	var aim: float = FightMotion.TURN_AIM * rad_to_deg(Vector2(0.0, -lead).angle_to(direction))
	var cock: float = FightMotion.WINDUP_TURN * (-1.0 if direction.y < 0.0 else 1.0)
	assert_gt(absf(aim), 10.0, "a diagonal attack: a real turn")
	# 1/6 s: 10 frames in, 6 into the 8-frame strike (quad in), the lean going
	var u: float = 6.0 / 8.0
	var lean: float = FightMotion.TURN_LEAN * direction.x * lead * (1.0 - u)
	var striking: float = lerpf(cock, -cock / 2.0, u * u) + aim * lerpf(1.0, 0.9, u) + lean
	assert_almost_eq(slow[1], striking, 0.01, "mid-strike: the cock, the turn and the lean")
	assert_almost_eq(slow[2], -cock / 2.0 + aim * 0.9, 0.01, "at contact: 90 % of the turn")
	assert_true(signf(slow[2] + cock / 2.0) == signf(aim), "turned toward its target")
	assert_almost_eq(slow[5], 0.0, 0.01, "straight 25 frames after the return starts")


func test_skip_mid_attack_leaves_every_card_straight() -> void:
	for wait: float in [FightMotion.ATTACK_TIME / 2.0, FightMotion.ATTACK_TIME + 0.05]:
		_make()
		_screen._process(FightReplay.HOLD_START)
		_tick_motion(wait)
		assert_ne(_screen.node_for("board", 0).rotation_degrees, 0.0, "turned before the skip")
		_screen.skip()
		for target: Dictionary in _screen.targets_of("board"):
			var node: Control = target["node"]
			assert_almost_eq(node.rotation_degrees, 0.0, 0.0001, "straight after a skip")
			assert_eq(node.scale, Vector2.ONE, "full size after a skip")
		var turns: Dictionary = _screen._keeper.get("_turns")
		assert_true(turns.is_empty(), "no turn left after a skip")
