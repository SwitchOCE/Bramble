extends GutTest
## A new action retires older cues without waiting for their decorative tails.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const EffectPath := preload("res://src/ui/widgets/combat_effect_path.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Numbers := preload("res://src/ui/stat_numbers.gd")
const Settings := preload("res://src/ui/settings.gd")
const STEP: float = 1.0 / 120.0


func after_each() -> void:
	Settings.reset()


func _screen() -> CombatScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var screen := CombatScreen.new()
	screen.manual_playback = true
	screen.auto_return = false
	viewport.add_child(screen)
	screen.setup({"events": []}, PackedStringArray(["You", "Opponent"]), 0, "Fight", 40)
	var library: UnitLibrary = UnitLibrary.load_dir()
	var first: Dictionary = UnitViews.from_def(library.get_unit("field_vole"), false, 1)
	var second: Dictionary = UnitViews.from_def(library.get_unit("field_vole"), false, 8)
	var third: Dictionary = UnitViews.from_def(library.get_unit("field_vole"), false, 2)
	(
		screen
		. _play_event(
			{
				"type": "combat_start",
				"boards":
				[
					[first, third, null, null, null, null, null],
					[second, null, null, null, null, null, null]
				],
				"first_side": 0,
				"player_ids": [0, 1],
			},
			false
		)
	)
	return screen


func _live_stat_cues(screen: CombatScreen) -> int:
	var count: int = 0
	for child: Node in screen._overlay.get_children():
		if not child is Control:
			continue
		var cue: Control = child
		if cue.is_queued_for_deletion() or not cue.visible or cue.modulate.a < 0.05:
			continue
		if (
			cue.get_script() == EffectPath
			or cue.has_meta("effect_stat")
			or str(cue.name).begins_with("StatLanding_")
		):
			count += 1
	return count


func _assert_stat_cue_settles_before_attack(speed: float, reduced: bool) -> void:
	Settings.reduce_motion = reduced
	for source: int in [1, 8, -1]:
		var screen: CombatScreen = _screen()
		screen.set_speed(speed)
		var attack_observed: Dictionary = {}
		screen.attack_started.connect(
			func(_index: int, _duration: float) -> void:
				attack_observed["old_cues"] = _live_stat_cues(screen)
		)
		screen.events = [
			{
				"type": "stats",
				"source": source,
				"causes": [{"source": 8}, {"source": 1}] if source < 0 else [],
				"target": 1,
				"attack": 5,
				"attack_delta": 3,
				"health_delta": 0,
			},
			{"type": "attack", "attacker": 8, "defender": 1, "joiners": []},
		]
		screen._wait = 0.0
		screen.advance_playback(STEP)
		var original_deadline: float = maxf(0.4, 0.15 + screen._motion.stat_delay(1)) + 3 * STEP
		assert_eq(screen.next_index, 1, "the stat event precedes the next attack")
		for lead_tick: int in 24:
			screen.advance_playback(STEP)
		assert_eq(screen.next_index, 1, "the source lead remains within the stat effect")
		assert_gt(
			_live_stat_cues(screen), 0, "the source cue really exists; this is not a vacuous cut"
		)
		var elapsed: float = 24 * STEP
		for tick: int in 360:
			screen.advance_playback(STEP)
			elapsed += STEP
			if not attack_observed.is_empty():
				break
		assert_false(attack_observed.is_empty(), "the next attack still starts")
		assert_lte(elapsed, original_deadline, "a decorative route tail adds no extra wait")
		assert_eq(
			CoreUtil.to_int(attack_observed.get("old_cues", -1)),
			0,
			(
				"no preceding stat route, mote or landing survives into the next attack; source=%d"
				% source
			)
		)


func test_stat_cues_finish_before_next_attack_at_x1() -> void:
	_assert_stat_cue_settles_before_attack(1.0, false)


func test_stat_cues_finish_before_next_attack_at_x4() -> void:
	_assert_stat_cue_settles_before_attack(4.0, false)


func test_stat_cues_finish_before_next_attack_with_reduce_motion() -> void:
	_assert_stat_cue_settles_before_attack(1.0, true)


func _advance(screen: CombatScreen, seconds: float) -> void:
	for tick: int in roundi(seconds / STEP):
		screen.advance_playback(STEP)


func _routes(screen: CombatScreen) -> Array[EffectPath]:
	var result: Array[EffectPath] = []
	for child: Node in screen._overlay.get_children():
		if child.get_script() == EffectPath:
			var route: EffectPath = child
			if route.visible and not route.is_queued_for_deletion():
				result.append(route)
	return result


func _alpha(cue: CanvasItem) -> float:
	var alpha: float = 1.0
	var cursor: Node = cue
	while cursor is CanvasItem:
		var item: CanvasItem = cursor
		alpha *= item.modulate.a * item.self_modulate.a
		cursor = cursor.get_parent()
	return alpha


func _cause(kind: String) -> Dictionary:
	match kind:
		"stats", "self_stats":
			return {
				"type": "stats",
				"target": 1,
				"source": 1 if kind == "self_stats" else 8,
				"attack": 5,
				"attack_delta": 3,
				"health_delta": 0,
			}
		"kiss":
			return {"type": "kiss", "target": 1, "side": 0, "count": 1, "period": 3}
		"toll":
			return {"type": "bog_toll", "side": 0, "source": 8, "total": 7, "amount": 2}
	return {
		"type": "gain_pending",
		"source": 8,
		"target": 1,
		"attack": 2,
		"health": 3,
		"attack_delta": 2,
		"health_delta": 3,
	}


func _boundary(kind: String) -> Dictionary:
	if kind == "attack":
		return {"type": "attack", "attacker": 8, "defender": 2, "joiners": []}
	return {"type": "mire_wait", "uid": 8, "target": 2, "side": 1}


func _assert_card_numbers_match_model(screen: CombatScreen, context: String) -> void:
	for uid: int in screen._cards:
		var card: CardView = screen._cards[uid]
		var canonical: Dictionary = screen.model.unit(uid)
		for stat: String in ["attack", "health"]:
			var label: Label = card.get("_" + stat + "_label")
			assert_eq(
				label.text,
				Numbers.compact(maxi(0, CoreUtil.to_int(canonical.get(stat, 0)))),
				context + ": retired callbacks cannot roll canonical " + stat + " backwards"
			)


func _assert_retirement(kind: String, boundary: String, speed: float, reduced: bool) -> void:
	Settings.reduce_motion = reduced
	var screen: CombatScreen = _screen()
	screen.set_speed(speed)
	var initial_unit: Dictionary = screen.model.unit(1).duplicate(true)
	if kind == "dead_pending":
		screen._play_event({"type": "death", "uid": 1}, false)
	screen._play_event(_cause(kind), true)
	var lead: float = 0.2
	if kind == "toll":
		lead = maxf(0.04, 0.18 / speed) * 0.5
	elif kind == "pending":
		lead = maxf(0.04, 0.15 / speed) * 0.5
	_advance(screen, lead)
	var context: String = "%s -> %s x%s reduced=%s" % [kind, boundary, speed, reduced]
	var routes: Array[EffectPath] = _routes(screen)
	assert_gt(routes.size(), 0, context + ": a real visible route precedes the boundary")
	if routes.is_empty():
		return
	var route: EffectPath = routes[0]
	var motes: Array[Control] = []
	for child: Node in screen._overlay.get_children():
		if child is Control and child.has_meta("effect_from"):
			var picture: Control = child
			if picture.visible:
				motes.append(picture)
	assert_gt(motes.size(), 0, context + ": a real travelling picture precedes retirement")
	if motes.is_empty():
		return
	var mote: Control = motes[0]
	assert_false(route.arrived, context + ": cancel while still in flight")
	if not reduced:
		assert_gt(route.progress, 0.0, context + ": the route really advanced before retirement")
		assert_lt(route.progress, 1.0)
	var before_progress: float = route.progress
	var before_arrival: bool = route.arrived
	var before_units: Dictionary = screen.model.units.duplicate(true)
	var before_toll: Dictionary = screen.model.bog_toll.duplicate(true)
	var before_hero_health: Array[int] = screen.hero_health.duplicate()
	screen._play_event(_boundary(boundary), true)
	var retiring: Control = screen.get("_retiring_cues")
	assert_not_null(retiring)
	assert_false(
		screen._overlay.is_ancestor_of(route), context + ": old route leaves the active cue layer"
	)
	assert_true(retiring.is_ancestor_of(route))
	assert_true(route.is_visible_in_tree(), context + ": retirement is a visible fade, not hiding")
	var frozen_picture: Transform2D = mote.get_global_transform()
	var initial_alpha: float = _alpha(route)
	assert_gt(initial_alpha, 0.9)
	assert_eq(route.progress, before_progress)
	assert_eq(route.arrived, before_arrival)
	_assert_card_numbers_match_model(screen, context)
	_advance(screen, 0.04)
	assert_true(
		is_instance_valid(route), context + ": the .08 second fade is still visible halfway"
	)
	if is_instance_valid(route):
		assert_gt(_alpha(route), 0.05)
		assert_lt(
			_alpha(route),
			initial_alpha,
			context + ": fade advances while route motion stays frozen"
		)
		assert_eq(route.progress, before_progress)
		assert_eq(
			mote.get_global_transform(),
			frozen_picture,
			context + ": the retiring picture cannot keep travelling"
		)
		assert_eq(
			route.arrived,
			before_arrival,
			context + ": the retired route cannot acquire a landing arrow"
		)
	_advance(screen, 0.06)
	await get_tree().process_frame
	assert_false(is_instance_valid(route), context + ": old route is freed within .1 second")
	# Cross the original .35-second landing callback and the .47-second self-stat delay.
	_advance(screen, 0.1)
	if kind == "toll":
		var plaques: Array = screen.get("_plaques")
		var hero: Control = plaques[0]
		assert_eq(hero.scale, Vector2.ONE, context + ": no old Toll pulse arrives late")
		assert_eq(hero.modulate, Color.WHITE)
	_advance(screen, 0.6)
	assert_eq(
		screen.model.units, before_units, context + ": no delayed callback applies damage or gains"
	)
	assert_eq(screen.model.bog_toll, before_toll)
	assert_eq(screen.hero_health, before_hero_health)
	_assert_card_numbers_match_model(screen, context)
	if kind in ["pending", "dead_pending"]:
		var queued: Dictionary = screen.model.unit(1)
		assert_eq(CoreUtil.to_int(queued.get("pending_attack")), 2)
		assert_eq(CoreUtil.to_int(queued.get("pending_health")), 3)
		assert_eq(
			CoreUtil.to_int(queued.get("attack")),
			CoreUtil.to_int(initial_unit.get("attack")),
			"queued gains do not become combat Attack"
		)
		assert_eq(
			CoreUtil.to_int(queued.get("health")),
			CoreUtil.to_int(initial_unit.get("health")),
			"queued gains do not become combat Health"
		)
	if kind == "pending":
		assert_false(
			screen._overlay.has_node("PendingLanding_1"),
			"preempted queued numbers cannot appear later"
		)
	if kind == "toll":
		assert_false(
			screen._overlay.has_node("TollLanding_0"), "preempted Toll numbers cannot appear later"
		)
	if kind == "dead_pending":
		assert_false(screen._cards.has(1), "retiring the reserve cannot resurrect its recipient")
		assert_false(screen._overlay.has_node("KeptGain_1"))
		assert_eq(retiring.get_child_count(), 0)


func _assert_retirement_modes(kind: String) -> void:
	for mode: int in 3:
		var speed: float = 4.0 if mode == 1 else 1.0
		var reduced: bool = mode == 2
		for boundary: String in ["attack", "mire_wait"]:
			await _assert_retirement(kind, boundary, speed, reduced)


func test_external_and_self_stat_routes_freeze_then_visibly_retire_at_each_boundary() -> void:
	await _assert_retirement_modes("stats")
	await _assert_retirement_modes("self_stats")


func test_toll_route_retires_without_a_late_hero_pulse() -> void:
	await _assert_retirement_modes("toll")


func test_live_pending_gain_routes_retire_without_spending_the_queue() -> void:
	await _assert_retirement_modes("pending")


func test_dead_pending_gain_routes_and_reserve_retire_without_resurrection() -> void:
	await _assert_retirement_modes("dead_pending")


func test_toll_and_pending_routes_do_not_add_a_wait_before_the_next_action() -> void:
	for mode: int in 3:
		var speed: float = 4.0 if mode == 1 else 1.0
		Settings.reduce_motion = mode == 2
		for kind: String in ["toll", "pending", "dead_pending", "kiss"]:
			for boundary: String in ["attack", "mire_wait"]:
				var screen: CombatScreen = _screen()
				screen.set_speed(speed)
				if kind == "dead_pending":
					screen._play_event({"type": "death", "uid": 1}, false)
				screen.events = [_cause(kind), _boundary(boundary)]
				screen._wait = 0.0
				screen.advance_playback(STEP)
				assert_gt(
					_routes(screen).size(), 0, "a real route precedes the ordinary event cadence"
				)
				var elapsed: float = 0.0
				for tick: int in 60:
					screen.advance_playback(STEP)
					elapsed += STEP
					if screen.next_index == 2:
						break
				assert_eq(screen.next_index, 2)
				assert_lte(
					elapsed,
					maxf(0.05, 0.3 / speed) + 2 * STEP,
					"the route tail adds no new boundary wait"
				)
				await get_tree().process_frame


func _assert_landed_picture_retires(
	kind: String, boundary: String, speed: float, reduced: bool
) -> void:
	Settings.reduce_motion = reduced
	var screen: CombatScreen = _screen()
	screen.set_speed(speed)
	if kind == "kiss":
		var library: UnitLibrary = UnitLibrary.load_dir()
		var prince: Dictionary = UnitViews.from_def(library.get_unit("prince_restored"), false, 1)
		screen._play_event({"type": "transform", "target": 1, "unit": prince}, false)
	var initial_unit: Dictionary = screen.model.unit(1).duplicate(true)
	screen._play_event(_cause(kind), true)
	var node_name: String = (
		"KissPip_1_0"
		if kind == "kiss"
		else "PendingLanding_1" if kind == "pending" else "TollLanding_0"
	)
	var cue: Control = screen._overlay.get_node_or_null(node_name) as Control
	var context: String = "%s landing -> %s x%s reduced=%s" % [kind, boundary, speed, reduced]
	assert_not_null(cue, context + ": the event really creates its landing picture")
	if cue == null:
		return
	var elapsed: float = 0.0
	for tick: int in 48:
		if cue.visible:
			break
		screen.advance_playback(STEP)
		elapsed += STEP
	assert_true(
		cue.is_visible_in_tree(), context + ": the landing must actually appear before retirement"
	)
	assert_lte(elapsed, 0.4 + STEP)
	screen.advance_playback(STEP)
	if not reduced:
		assert_gt(
			cue.scale.x, 1.0, context + ": the ring or number really pops before the next action"
		)
	if kind == "kiss":
		var card: CardView = screen._cards[1]
		var marks: Control = card.get("_combat_marks")
		var pips: Array[Vector2] = marks.get("kiss_pips")
		var point: Vector2 = cue.get_meta("kiss_pip_point")
		assert_eq(
			point,
			marks.get_global_transform() * pips[0],
			"the Prince cue belongs to the newly filled pip"
		)
		assert_eq(CoreUtil.to_int(cue.get_meta("kiss_count")), 1)
		assert_eq(CoreUtil.to_int(cue.get_meta("kiss_target_uid")), 1)
	else:
		var number: Label = cue as Label
		assert_eq(number.text, "+2/+3" if kind == "pending" else "+2")
	var units: Dictionary = screen.model.units.duplicate(true)
	var toll: Dictionary = screen.model.bog_toll.duplicate(true)
	var frozen: Transform2D = cue.get_global_transform()
	screen._play_event(_boundary(boundary), true)
	var retiring: Control = screen.get("_retiring_cues")
	assert_true(retiring.is_ancestor_of(cue), context + ": the actual landed cue retires too")
	assert_false(screen._overlay.is_ancestor_of(cue))
	assert_gt(_alpha(cue), 0.9, context + ": the landed cue is not just hidden")
	_advance(screen, 0.04)
	assert_true(is_instance_valid(cue))
	if is_instance_valid(cue):
		assert_gt(_alpha(cue), 0.05)
		assert_lt(_alpha(cue), 0.9)
		assert_eq(
			cue.get_global_transform(),
			frozen,
			context + ": only retirement alpha can keep changing"
		)
	_advance(screen, 0.06)
	await get_tree().process_frame
	assert_false(is_instance_valid(cue), context + ": no landed cue remains after .1 second")
	_advance(screen, 0.6)
	assert_false(
		screen._overlay.has_node(node_name), context + ": no late callback recreates the cue"
	)
	assert_eq(screen.model.units, units)
	assert_eq(screen.model.bog_toll, toll)
	_assert_card_numbers_match_model(screen, context)
	var current: Dictionary = screen.model.unit(1)
	assert_eq(CoreUtil.to_int(current.get("attack")), CoreUtil.to_int(initial_unit.get("attack")))
	assert_eq(CoreUtil.to_int(current.get("health")), CoreUtil.to_int(initial_unit.get("health")))
	if kind == "kiss":
		assert_eq(str(current["def_id"]), "prince_restored")
		assert_eq(CoreUtil.to_int(current.get("kisses")), 1)
	elif kind == "pending":
		assert_eq(CoreUtil.to_int(current.get("pending_attack")), 2)
		assert_eq(CoreUtil.to_int(current.get("pending_health")), 3)


func test_prince_kiss_pip_ring_freezes_and_fades_at_the_next_action() -> void:
	for mode: int in 3:
		for boundary: String in ["attack", "mire_wait"]:
			await _assert_landed_picture_retires(
				"kiss", boundary, 4.0 if mode == 1 else 1.0, mode == 2
			)


func test_queued_gain_and_toll_landing_numbers_freeze_and_fade_at_the_next_action() -> void:
	for mode: int in 3:
		for kind: String in ["pending", "toll"]:
			for boundary: String in ["attack", "mire_wait"]:
				await _assert_landed_picture_retires(
					kind, boundary, 4.0 if mode == 1 else 1.0, mode == 2
				)


func test_preempted_toll_and_queued_gain_numbers_never_land_during_the_next_action() -> void:
	for mode: int in 3:
		Settings.reduce_motion = mode == 2
		for boundary: String in ["attack", "mire_wait"]:
			var screen: CombatScreen = _screen()
			screen.set_speed(4.0 if mode == 1 else 1.0)
			screen._play_event(_cause("toll"), true)
			screen._play_event(_cause("pending"), true)
			var toll_popup: Control = screen._overlay.get_node_or_null("TollLanding_0") as Control
			var pending_popup: Control = (
				screen._overlay.get_node_or_null("PendingLanding_1") as Control
			)
			assert_not_null(toll_popup)
			assert_not_null(pending_popup)
			if toll_popup == null or pending_popup == null:
				continue
			screen.advance_playback(STEP)
			assert_gt(
				_routes(screen).size(), 0, "a real Toll flight precedes the queued number timers"
			)
			assert_false(toll_popup.visible)
			assert_false(pending_popup.visible)
			var units: Dictionary = screen.model.units.duplicate(true)
			var toll: Dictionary = screen.model.bog_toll.duplicate(true)
			screen._play_event(_boundary(boundary), true)
			var retiring: Control = screen.get("_retiring_cues")
			assert_true(retiring.is_ancestor_of(toll_popup))
			assert_true(retiring.is_ancestor_of(pending_popup))
			_advance(screen, 0.1)
			await get_tree().process_frame
			assert_false(is_instance_valid(toll_popup))
			assert_false(is_instance_valid(pending_popup))
			_advance(screen, 0.7)
			assert_false(
				screen._overlay.has_node("TollLanding_0"),
				"a cancelled number cannot appear on the next action"
			)
			assert_false(screen._overlay.has_node("PendingLanding_1"))
			assert_eq(screen.model.units, units)
			assert_eq(screen.model.bog_toll, toll)
			_assert_card_numbers_match_model(screen, "preempted Toll and queued gain")


func test_animated_stat_roll_refits_old_and_intermediate_numbers_to_the_bead() -> void:
	var screen: CombatScreen = _screen()
	var card: CardView = screen._cards[1]
	card.set_card_width(171)
	screen.model.units[1]["health"] = 1
	screen._sync_unit(1)
	screen._roll_changes(1, {"attack": screen.model.units[1]["attack"], "health": 229})
	var label: Label = card.get("_health_label")
	var badge: Control = card.health_bead()
	for delta: float in [0.0, 0.075, 0.075]:
		screen.advance_playback(delta)
		var font: Font = label.get_theme_font("font")
		var font_size: int = label.get_theme_font_size("font_size")
		var width: float = (
			font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		)
		var room: float = badge.call("inner_width")
		assert_lte(width, room, "each animated numeral fits the actual bead")
		assert_gte(font_size, 31, "fitting preserves the shared minimum font")
