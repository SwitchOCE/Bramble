extends GutTest
## A preceding stat cue must finish before the next attack can be attributed to it.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const EffectPath := preload("res://src/ui/widgets/combat_effect_path.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
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
	(
		screen
		. _play_event(
			{
				"type": "combat_start",
				"boards":
				[
					[first, null, null, null, null, null, null],
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
		assert_eq(screen.next_index, 1, "the stat event precedes the next attack")
		for lead_tick: int in 24:
			screen.advance_playback(STEP)
		assert_eq(screen.next_index, 1, "the source lead remains within the stat effect")
		assert_gt(
			_live_stat_cues(screen), 0, "the source cue really exists; this is not a vacuous cut"
		)
		for tick: int in 360:
			screen.advance_playback(STEP)
			if not attack_observed.is_empty():
				break
		assert_false(attack_observed.is_empty(), "the next attack still starts")
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
