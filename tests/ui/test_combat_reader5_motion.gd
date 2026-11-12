extends GutTest
## A kiss identifies one crown pip; a Mire wait uses the ordinary actor and arrow language.

const Screen := preload("res://src/ui/screens/combat_screen.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Face := preload("res://src/ui/widgets/combat_face.gd")
const EffectPath := preload("res://src/ui/widgets/combat_effect_path.gd")
const Settings := preload("res://src/ui/settings.gd")
const Views := preload("res://src/ui/unit_views.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const STEP: float = 1.0 / 120.0


func after_each() -> void:
	Settings.reset()


func _screen(back_rows: bool = false) -> Screen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var screen := Screen.new()
	screen.manual_playback = true
	screen.auto_return = false
	viewport.add_child(screen)
	screen.setup({"events": []}, PackedStringArray(["You", "Opponent"]), 0, "Fight", 40)
	var library: UnitLibrary = UnitLibrary.load_dir()
	var frog: Dictionary = Views.from_def(library.get_unit("his_highness"), false, 1)
	frog["bog_kiss_period"] = 3
	frog["kisses"] = 0
	var friend: Dictionary = Views.from_def(library.get_unit("field_vole"), false, 2)
	var enemy: Dictionary = Views.from_def(library.get_unit("field_vole"), false, 8)
	var mine: Array = [frog, friend, null, null, null, null, null]
	var theirs: Array = [enemy, null, null, null, null, null, null]
	if back_rows:
		mine = [null, null, null, null, frog, friend, null]
		theirs = [null, null, null, null, enemy, null, null]
	screen._play_event(
		{"type": "combat_start", "boards": [mine, theirs], "first_side": 0, "player_ids": [0, 1]},
		false
	)
	return screen


func _advance(screen: Screen, seconds: float) -> void:
	for tick: int in ceili(seconds / STEP):
		screen.advance_playback(STEP)


func _actors(screen: Screen) -> Array[int]:
	var found: Array[int] = []
	var held: Array = screen._motion.get("_held_sources")
	for cue: Control in held:
		if is_instance_valid(cue) and cue.visible:
			found.append(CoreUtil.to_int(cue.get("actor_uid")))
	return found


func test_each_kiss_lands_on_its_actual_crown_pip_and_only_that_pip_pulses() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		for count: int in [1, 2, 3]:
			var screen: Screen = _screen()
			screen._play_event({"type": "kiss", "target": 1, "count": count, "period": 3}, true)
			var face: Face = screen._cards[1].get("_combat_marks")
			var expected: Vector2 = face.get_global_transform() * face.kiss_pips[count - 1]
			var ring: Control = screen._overlay.get_node("KissPip_1_%d" % (count - 1))
			var heart: Control
			for child: Node in screen._overlay.get_children():
				if child.has_meta("effect_to") and child.has_meta("kiss_target_uid"):
					heart = child
			assert_not_null(heart)
			if heart != null:
				var landing: Vector2 = heart.get_meta("effect_to")
				assert_eq(landing, expected, "the heart does not land in the card centre")
			assert_false(ring.visible, "the pip does not pulse before arrival")
			assert_false(
				screen._overlay.has_node("TriggerSource_1"), "a kiss does not pulse the whole frog"
			)
			_advance(screen, 0.14)
			assert_true(ring.visible, "the just-filled pip visibly responds on arrival")
			assert_eq(screen._cards[1].modulate, Color.WHITE, "the card itself remains calm")
			if not reduced:
				assert_gt(ring.scale.x, 1.0, "the local pip ring pops")


func test_kiss_lands_before_the_next_attack_at_x1_and_x4_without_extra_waits() -> void:
	for speed: float in [1.0, 4.0]:
		for reduced: bool in [false, true]:
			Settings.reduce_motion = reduced
			var screen: Screen = _screen()
			screen.set_speed(speed)
			screen.events = [
				{"type": "kiss", "target": 1, "count": 1, "period": 3},
				{"type": "attack", "attacker": 8, "defender": 1, "joiners": []}
			]
			screen._wait = 0.0
			screen.advance_playback(STEP)
			var ring: Control = screen._overlay.get_node("KissPip_1_0")
			_advance(screen, 0.13 / speed + 2 * STEP)
			assert_true(ring.visible, "the pip landing occurs during the existing kiss interval")
			assert_eq(screen.next_index, 1)
			_advance(screen, maxf(0.08, 0.22 / speed))
			assert_eq(screen.next_index, 2, "pip animation adds no new action wait")


func test_mire_wait_has_the_same_actor_frame_and_standard_directional_arrow() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var screen: Screen = _screen()
		screen._play_event({"type": "mire_wait", "uid": 1, "target": 8}, true)
		assert_eq(_actors(screen), [1], "the gold actor frame identifies who is waiting")
		var route: EffectPath = screen._overlay.get_node("MireWaitLink_1")
		assert_gt(
			route.from_point.y,
			route.to_point.y,
			"the route runs from your waiting frog toward its enemy"
		)
		_advance(screen, 0.3)
		assert_true(route.visible)
		assert_true(route.arrived, "the shared EffectPath draws its standard arrival arrowhead")
		assert_eq(route.progress, 1.0)
		assert_true(screen._overlay.has_node("Waiting_1"))
		screen._play_event({"type": "attack", "attacker": 8, "defender": 1, "joiners": []}, true)
		assert_eq(_actors(screen), [8], "the waiting frame retires at the next action")
		assert_false(screen._overlay.has_node("MireWaitLink_1"), "no old wait route remains active")


func test_actual_death_clears_only_its_actor_frame_and_anchors_the_original_pocket() -> void:
	var screen: Screen = _screen()
	screen._play_event({"type": "attack", "attacker": 1, "defender": 8, "joiners": [2]}, true)
	assert_eq(_actors(screen), [1, 2])
	var card: Card = screen._cards[1]
	var pocket: Vector2 = screen.board_for_side(0).slot_global_center(0)
	card.position += Vector2(150, -180)
	assert_gt(card.get_global_rect().get_center().distance_to(pocket), 40.0)
	screen._death(1, true)
	assert_eq(_actors(screen), [2], "the deceased leader frame cannot survive on its empty pocket")
	assert_eq(
		screen._last_death, pocket, "death effects start at the dead unit's slot despite its lunge"
	)


func test_mire_pause_bars_stay_above_the_actor_triangle_and_outside_art() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		for back_rows: bool in [false, true]:
			for waiting: int in [1, 8]:
				var screen: Screen = _screen(back_rows)
				var target: int = 8 if waiting == 1 else 1
				var card: Card = screen._cards[waiting]
				var art: Control = card.get("_art")
				screen._play_event({"type": "mire_wait", "uid": waiting, "target": target}, true)
				var pause: Control = screen._overlay.get_node("Waiting_%d" % waiting)
				assert_true(CoreUtil.to_bool(pause.get_meta("pause_bars")))
				assert_false(pause is Panel, "the pause has no white disc backing")
				assert_eq(pause.get_child_count(), 2, "only two unambiguous pause bars")
				assert_false(pause.visible, "the original source lead remains intact")
				_advance(screen, 0.3)
				assert_true(pause.visible)
				assert_true(
					screen.get_viewport_rect().encloses(pause.get_global_rect()),
					"even an enemy back-row pause stays in the viewport"
				)
				assert_false(
					pause.get_global_rect().intersects(art.get_global_rect()),
					(
						"the paused actor's art remains unobscured (reduced=%s, back=%s, uid=%d; pause=%s, art=%s)"
						% [
							reduced,
							back_rows,
							waiting,
							pause.get_global_rect(),
							art.get_global_rect()
						]
					)
				)
				var held: Array = screen._motion.get("_held_sources")
				var frame: Control = held[0]
				var triangle_top: float = frame.get_global_rect().position.y
				if not CoreUtil.to_bool(frame.get("toward_top")):
					triangle_top += maxf(48, frame.size.y - 74) - 26
				assert_lte(
					pause.get_global_rect().end.y,
					triangle_top - 2,
					"bars sit above the actor triangle"
				)
				var left: Control = pause.get_node("LeftBar")
				var right: Control = pause.get_node("RightBar")
				assert_true(
					left.size.is_equal_approx(right.size), "both pause bars have the same size"
				)
				assert_gt(left.size.y, left.size.x, "each bar is a vertical stroke")
				assert_gt(
					right.position.x, left.get_rect().end.x, "the bars remain visibly separate"
				)
				_advance(screen, 0.6)
				await get_tree().process_frame
				assert_false(is_instance_valid(pause), "the original short wait beat still retires")


func test_take_rewards_use_stat_sparks_rather_than_gold_acorns() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var screen: Screen = _screen()
		screen._play_event({"type": "take", "hunter": 1, "quarry": 8, "side": 0}, true)
		_advance(screen, 0.6)
		var rewards: int = 0
		for child: Node in screen._overlay.get_children():
			if (
				not child is TextureRect
				or not child.has_meta("effect_from")
				or child.has_meta("take_quarry_uid")
			):
				continue
			var mark: TextureRect = child
			assert_ne(
				mark.texture, Icons.icon("acorn", 88), "Take pays queued stats, not spendable gold"
			)
			assert_eq(
				mark.texture, Icons.icon("spark", 52), "the reward uses the shared stat-gain spark"
			)
			rewards += 1
		assert_eq(rewards, 2, "both return and retained-gain legs preserve the Take cue")
