extends Control
## Fight playback: event state remains in CombatModel; motion carries the public presentation.

signal finished
signal attack_started(index: int, duration: float)
signal guide_requested
signal settings_requested
signal menu_requested

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const SlotView := preload("res://src/ui/widgets/slot_view.gd")
const BoardView := preload("res://src/ui/screens/arena_board.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatSounds := preload("res://src/ui/screens/combat_sounds.gd")
const CombatMotion := preload("res://src/ui/screens/combat_motion.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const LogNote := preload("res://src/ui/widgets/log_note.gd")
const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const CombatLanesView := preload("res://src/ui/screens/combat_lanes_view.gd")
const PauseMenu := preload("res://src/ui/widgets/pause_menu.gd")
const FightLogPage := preload("res://src/ui/screens/fight_log_page.gd")
const WaveMotion := preload("res://src/ui/screens/combat_wave_motion.gd")
const Arena := preload("res://src/ui/arena_geometry.gd")
const LobbyStrip := preload("res://src/ui/widgets/lobby_strip.gd")
const LobbyPlaque := preload("res://src/ui/widgets/lobby_plaque.gd")
const CombatScout := preload("res://src/ui/screens/combat_scout.gd")

const PlayFrame := preload("res://src/ui/widgets/play_frame.gd")
const Surface := preload("res://src/ui/widgets/painted_surface.gd")

const CANVAS_H: float = 1080.0
const SPEEDS: Array[float] = [1.0, 2.0, 4.0]

var model: CombatModel = CombatModel.new()
var events: Array = []
var next_index: int = 0
var playing: bool = true
var speed: float = 1.0
var bottom_side: int = 0
## The evidence runner supplies fixed deltas, including manual tween stepping.
var manual_playback: bool = false
var auto_return: bool = true
var hero_views: Array[Dictionary] = [{}, {}]
var hero_health: Array[int] = [-1, -1]
var hero_health_after: Array = []
var floor_marks: Array = []
var scout_provider: Callable
var _log_text: CombatLog = CombatLog.new()
var _fight_bar: PlayFrame
var _stage: Control
var _boards: Array[BoardView] = []
var _cards: Dictionary[int, CardView] = {}
var _wait: float = 0.0
var _return_wait: float = -1.0
var _attack_remaining: float = 0.0
var _contact_remaining: float = 0.0
var _pause_open: bool = false
var _step_motion_remaining: float = 0.0
var _effect_remaining: float = 0.0
var _hit_remaining: float = 0.0
var _arrival_remaining: float = 0.0
var _ending: bool = false
var _motion: CombatMotion
var _log: LogNote
var _hover_close: Timer
var _reader: CardDetail
var _note_text: RichTextLabel
var _play_button: TokenButton
var _speed_button: TokenButton
var _step_button: TokenButton
var _skip_button: TokenButton
var _gear: TokenButton
var _lanes: LaneOverlay
var _overlay: Control
var _retiring_cues: Control
var _plaques: Array[TokenButton] = []
var _health_labels: Array[Label] = []
var _tweens: Array[Tween] = []
var _dying: Array[CardView] = []
var _attacker_uid: int = -1
var _defender_uid: int = -1
var _last_death: Vector2 = Vector2.ZERO
var _resume_reader: bool = false
var _complete: bool = false
var _return_ready: bool = false
var _title: String = ""
var _event_before: Dictionary = {}
var _lobby: LobbyStrip
var _round_label: Label
var _scout_board: BoardView
var _scout: CombatScout
var _scout_view: Dictionary = {}
var _scouting: bool = false
var _resume_scout: bool = false
var _scout_previous_health: String = ""


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiTheme.add_world(self, "fight")
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_fight_bar = PlayFrame.new()
	_stage.add_child(_fight_bar)
	for i: int in 2:
		var board := BoardView.new()
		board.combat_mode = true
		Arena.size_board(board, "enemy" if i == 0 else "own", i == 1)
		for slot: SlotView in board.slots:
			slot.tapped.connect(_on_slot_tapped.bind(i))
		_stage.add_child(board)
		_boards.append(board)
	_lanes = LaneOverlay.new()
	_lanes.combat_mode = true
	_stage.add_child(_lanes)
	_scout = CombatScout.new(self)
	_scout_board = _scout.board
	_lobby = LobbyStrip.new()
	_lobby.scout_requested.connect(show_scout)
	_lobby.hero_requested.connect(_scout.show_lobby_hero)
	_stage.add_child(_lobby)
	_round_label = UiTheme.head("", UiTheme.FONT_BODY, UiTheme.CREAM)
	_round_label.add_theme_color_override("font_outline_color", UiTheme.INK)
	_round_label.add_theme_constant_override("outline_size", 5)
	_stage.add_child(_round_label)
	_retiring_cues = Control.new()
	_retiring_cues.name = "RetiringCues"
	_retiring_cues.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_retiring_cues.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_retiring_cues)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	# Preserve the complete machine-testable log, outside the visible fight.
	_log = LogNote.new()
	_log.hide()
	add_child(_log)
	_reader = CardDetail.new()
	_reader.z_index = 30
	add_child(_reader)
	_note_text = _reader.get("_notes")
	_note_text.set_meta("reminder", _reader.reminder)
	_hover_close = Timer.new()
	_hover_close.one_shot = true
	_hover_close.wait_time = 0.2
	_hover_close.timeout.connect(_reader.show_empty)
	add_child(_hover_close)
	_reader.mouse_entered.connect(_hover_close.stop)
	_reader.mouse_exited.connect(
		func() -> void:
			if not CardView.is_phone():
				_hover_close.start()
	)
	for side: int in 2:
		var plaque := TokenButton.new()
		plaque.self_modulate.a = 0.0
		plaque.pressed.connect(_show_hero.bind(side))
		_stage.add_child(plaque)
		_plaques.append(plaque)
		var art := ArtFrame.new()
		art.name = "Portrait"
		art.radius = 62.0
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.position = Vector2(9, 9)
		art.size = Vector2(122, 122)
		plaque.add_child(art)
		var hip := ShapeBadge.new("rosehip")
		hip.position = Vector2(82, 91)
		hip.size = Vector2(66, 66)
		plaque.add_child(hip)
		var health := UiTheme.number("", 36, UiTheme.CREAM)
		health.set_meta("combat_primary_stat", true)
		health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		health.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		health.set_anchors_preset(Control.PRESET_FULL_RECT)
		hip.add_child(health)
		_health_labels.append(health)
	_speed_button = TokenButton.new("", "speed_1")
	_speed_button.tooltip_text = "Fight speed"
	_speed_button.pressed.connect(_cycle_speed)
	_stage.add_child(_speed_button)
	_play_button = TokenButton.new("", "pause")
	_play_button.tooltip_text = "Pause or play"
	_play_button.pressed.connect(toggle_play)
	_stage.add_child(_play_button)
	_step_button = TokenButton.new("", "step")
	_step_button.tooltip_text = "Step"
	_step_button.pressed.connect(step_once)
	_stage.add_child(_step_button)
	_skip_button = TokenButton.new("", "skip")
	_skip_button.tooltip_text = "Skip fight"
	var skip_glyph: TextureRect = _skip_button.get("_glyph")
	skip_glyph.self_modulate = UiTheme.INK
	_skip_button.pressed.connect(skip_to_end)
	_stage.add_child(_skip_button)
	_gear = TokenButton.new("", "gear")
	_gear.tooltip_text = "Menu"
	_gear.pressed.connect(_open_pause)
	_stage.add_child(_gear)
	_motion = CombatMotion.new(self)
	set_speed(Settings.fight_speed)
	resized.connect(_layout)
	ready.connect(_layout)


func setup(
	combat: Dictionary,
	side_names: PackedStringArray,
	bottom: int,
	title: String,
	opponent_health: int = -1
) -> void:
	events = Data.a(combat, "events")
	floor_marks = Data.a(combat, "floor_marks")
	bottom_side = clampi(bottom, 0, 1)
	_log_text.side_names = side_names
	_title = title
	_round_label.text = title
	hero_health[1 - bottom_side] = opponent_health
	var health_before: Array = Data.a(combat, "hero_health_before")
	for side: int in mini(2, health_before.size()):
		hero_health[side] = Data.as_int(health_before[side])
	hero_health_after = Data.a(combat, "hero_health_after")
	for side: int in 2:
		_populate_hero(side, hero_views[side], hero_health[side])
	_layout()
	restart()


func board_for_side(side: int) -> BoardView:
	return _boards[1] if side == bottom_side else _boards[0]


func _populate_hero(side: int, hero: Dictionary, health: int) -> void:
	var art: ArtFrame = _plaques[side].get_node("Portrait")
	art.texture = UiTheme.portrait_for(Data.s(hero, "id"), [])
	_health_labels[side].text = str(health)
	var hip: Control = _health_labels[side].get_parent() as Control
	hip.visible = health >= 0


func _layout() -> void:
	if _stage == null or size.x < 10.0:
		return
	_stage.position = Vector2(0, maxf(0.0, (size.y - CANVAS_H) / 2.0))
	_stage.size = Vector2(size.x, CANVAS_H)
	var canvas: Vector2 = _stage.size
	Arena.place_board(_boards[0], canvas, true)
	Arena.place_board(_boards[1], canvas)
	_fight_bar.position = Vector2.ZERO
	_fight_bar.size = _stage.size
	_fight_bar.clear_regions()
	for opponent: bool in [true, false]:
		_fight_bar.add_region(Arena.board_rect(canvas, opponent), Surface.Finish.MOSS)
	for side: int in 2:
		var plaque: Control = _plaques[side]
		var hero_rect: Rect2 = Arena.hero_rect(canvas, side != bottom_side)
		plaque.position = hero_rect.position
		plaque.size = Vector2(140, 140)
		var art: Control = plaque.get_node("Portrait")
		art.position = Vector2.ZERO
		art.size = Vector2(120, 120)
		var hip: Control = _health_labels[side].get_parent() as Control
		hip.position = Vector2(72, 49)
		hip.size = Vector2(68, 68)
		_health_labels[side].add_theme_font_size_override("font_size", 40)
	var left_width: float = Arena.board_rect(canvas).position.x - 32.0
	_round_label.position = Vector2(160, 24)
	_round_label.size = Vector2(left_width - 144.0, 64)
	var tap: float = 122.0
	var controls: Array[Control] = [_step_button, _play_button, _speed_button, _skip_button]
	for i: int in controls.size():
		controls[i].position = Vector2(12 + i * (tap + 12), 172)
		controls[i].size = Vector2(tap, tap + 9)
	_gear.position = Vector2(12, 16)
	_gear.size = Vector2(122, 131)
	_fight_bar.add_region(Rect2(4, 162, 540, 150), Surface.Finish.BAR)
	var lobby_rect: Rect2 = Arena.lobby_rect(canvas)
	_lobby.position = lobby_rect.position
	_lobby.size = lobby_rect.size
	_lanes.boards = [board_for_side(0), board_for_side(1)]
	_reader.position = _stage.position + Vector2(16, 330)
	_reader.size = Vector2(left_width, 734)
	_scout.layout(canvas)


func set_standings(standings: Array, next_opponent_id: int, ghost_owner_id: int = -9) -> void:
	_lobby.show_standings(standings, next_opponent_id, ghost_owner_id)


func show_scout(player_id: int) -> void:
	if not scout_provider.is_valid():
		return
	var result: Variant = scout_provider.call(player_id)
	if not result is Dictionary:
		return
	var scout: Dictionary = result
	if scout.is_empty():
		return
	if not _scouting:
		_resume_scout = playing or _resume_reader
		_resume_reader = false
		_scout_previous_health = _health_labels[1 - bottom_side].text
		_set_playing(false)
		_retire_older_cues()
		_step_motion_remaining = 0.0
	_scout_view = scout
	_scout.populate(_scout_view)
	_scout_visibility(true)
	var standing: Dictionary = Data.d(_scout_view, "standing")
	_populate_hero(1 - bottom_side, Data.d(_scout_view, "hero"), Data.i(standing, "health", -1))
	_lobby.select_player(player_id)
	_reader.show_empty()
	_layout()


func close_scout() -> void:
	if not _scouting:
		return
	_scout_visibility(false)
	_scout_view = {}
	_scout_board.clear()
	_lobby.select_player()
	_populate_hero(1 - bottom_side, hero_views[1 - bottom_side], hero_health[1 - bottom_side])
	_health_labels[1 - bottom_side].text = _scout_previous_health
	_reader.show_empty()
	_set_playing(_resume_scout)


func _scout_visibility(on: bool) -> void:
	_scouting = on
	_scout.set_visible(on)
	_boards[0].visible = not on
	_lanes.visible = not on
	_overlay.visible = not on
	_retiring_cues.visible = not on
	for button: Button in [_step_button, _play_button, _speed_button, _skip_button]:
		button.disabled = on


func restart() -> void:
	close_scout()
	_kill_tweens()
	CombatLanesView.reset_floor_state(self)
	_motion = CombatMotion.new(self)
	model = CombatModel.new()
	for board: BoardView in _boards:
		board.clear_highlights()
		board.clear()
	for plaque: Control in _plaques:
		plaque.modulate = Color.WHITE
		plaque.scale = Vector2.ONE
	for side: int in 2:
		_populate_hero(side, hero_views[side], hero_health[side])
	_cards.clear()
	_log.clear()
	_log.set_title(_title)
	_lanes.bindings = {"patches": [], "quarries": []}
	_reader.show_empty()
	next_index = 0
	_complete = false
	_ending = false
	_return_wait = -1
	_attack_remaining = 0
	_effect_remaining = 0
	_hit_remaining = 0
	_arrival_remaining = 0
	_wait = 0.1
	_set_playing(true)


func _set_playing(on: bool) -> void:
	playing = on
	_play_button.set_icon_name("pause" if on else "play")


func toggle_play() -> void:
	if model.finished:
		_return_wait = 0
	else:
		_set_playing(not playing)


func _cycle_speed() -> void:
	set_speed(SPEEDS[(SPEEDS.find(speed) + 1) % SPEEDS.size()])
	Settings.fight_speed = speed
	Settings.save()


func set_speed(value: float) -> void:
	# Travel durations are calculated when a cue starts; never accelerate an airborne unit.
	speed = value
	_speed_button.set_icon_name("speed_%d" % int(value))


func step_once() -> void:
	_set_playing(false)
	if next_index < events.size():
		_play_event(Data.entry(events, next_index), true)
		_step_motion_remaining = maxf(0.6, _attack_remaining)
		next_index += 1


func skip_to_end() -> void:
	_kill_tweens()
	Sfx.silence()
	while next_index < events.size():
		_play_event(Data.entry(events, next_index), false)
		next_index += 1
	_sync_all()
	_return_wait = 0.1


func _process(delta: float) -> void:
	if not manual_playback:
		advance_playback(delta)


func attack_duration() -> float:
	var duration: float = _motion.contact_time()
	for i: int in range(next_index, events.size()):
		var kind: String = Data.s(Data.entry(events, i), "type")
		if kind in ["attack", "combat_end"]:
			break
		duration += _event_hold(kind)
	return maxf(_motion.attack_duration(), duration + 0.2)


func advance_playback(delta: float) -> void:
	if (
		_scouting
		or _pause_open
		or (not playing and not model.finished and _step_motion_remaining <= 0)
	):
		return
	for tween: Tween in _tweens.duplicate():
		if tween.is_valid():
			tween.custom_step(delta)
		if not tween.is_valid():
			_tweens.erase(tween)
	_step_motion_remaining = maxf(0, _step_motion_remaining - delta)
	if _return_wait >= 0:
		_return_wait -= delta
		if _return_wait <= 0 and auto_return and not _complete:
			if _has_active_tweens():
				# The final death/return lunge can outlast the result's nominal hold.
				_return_ready = false
				_return_wait = 0.001
			elif not _return_ready:
				# Paint the settled result for a frame before replacing the screen.
				_return_ready = true
				_return_wait = 1.0 / 60.0
			else:
				_complete = true
				finished.emit()
		return
	_attack_remaining = maxf(0, _attack_remaining - delta)
	_contact_remaining = maxf(0, _contact_remaining - delta)
	_effect_remaining = maxf(0, _effect_remaining - delta)
	_hit_remaining = maxf(0, _hit_remaining - delta)
	_arrival_remaining = maxf(0, _arrival_remaining - delta)
	_wait -= delta
	while playing and next_index < events.size() and _wait <= 0:
		var event: Dictionary = events[next_index]
		var kind: String = Data.s(event, "type")
		var self_stat: bool = (
			kind == "stats"
			and event.get("source") != null
			and Data.i(event, "source", -1) == Data.i(event, "target", -2)
		)
		var settle: float = (
			maxf(_effect_remaining, _hit_remaining)
			if kind == "mire_wait"
			else (_hit_remaining if self_stat else 0.0)
		)
		if kind == "stats":
			settle = maxf(settle, _arrival_remaining)
		if not _ending and settle > 0:
			_wait = settle
			return
		if kind == "attack" and maxf(_attack_remaining, _effect_remaining) > 0:
			_wait = maxf(_attack_remaining, _effect_remaining)
			return
		if kind == "damage" and Data.s(event, "kind") == "attack" and _contact_remaining > 0:
			_wait = _contact_remaining
			return
		var jab_wait: float = _motion.damage_wait(event)
		if jab_wait > 0:
			_wait += jab_wait
			return
		next_index += 1
		_play_event(event, true)
		var following: String = Data.s(Data.entry(events, next_index), "type")
		if kind != "death" or following != "death":
			_wait += _event_hold(kind)


func _event_hold(kind: String) -> float:
	if _ending:
		# Overlap the final rewards with the death fade, keeping the 1.6-second tail budget.
		return maxf(0.15, 0.24 / speed) if kind == "death" else 0.0
	if kind == "attack":
		return maxf(0.025, 0.1 / speed)
	if kind in ["stats", "status", "quarry_marked", "take", "mire_wait"]:
		return 0.9 if kind in ["take", "mire_wait"] else 0.4
	if kind in ["death", "health_loss"]:
		return maxf(0.15, (0.3 if kind == "death" else 0.4) / speed)
	if kind in ["trigger", "kiss", "transform", "summon", "relocate"]:
		return maxf(0.08, 0.22 / speed)
	return 0.0 if kind == "damage" else maxf(0.05, 0.3 / speed)


func _play_event(event: Dictionary, animate: bool) -> void:
	var kind: String = Data.s(event, "type")
	if animate and kind in ["attack", "mire_wait"]:
		_retire_older_cues()
	var line: String = _log_text.describe(event, model, false)
	if not line.is_empty():
		_log.push(line, CombatLog.LOUD_EVENTS.has(kind))
	var changed_uid: int = Data.i(event, "target", Data.i(event, "uid", -1))
	_event_before = model.unit(changed_uid).duplicate(true)
	model.apply(event)
	if kind == "bog_patch":
		var maker: int = Data.i(event, "maker", -1)
		if model.units.has(maker):
			model.units[maker]["mire_granted"] = true
			_sync_unit(maker)
	if kind in ["quarry_marked", "quarry_lost"]:
		_sync_unit(Data.i(event, "hunter", -1))
	if animate:
		CombatSounds.play(event, model, bottom_side)
	CombatLanesView.present(self, event, animate)
	match kind:
		"combat_start":
			_sync_all()
		"attack":
			_attacker_uid = Data.i(event, "attacker", -1)
			_defender_uid = Data.i(event, "defender", -1)
			_motion.precontact_delay = _declaration_delay()
			_motion.prepare_attack(event)
			_attack_remaining = attack_duration() if animate else 0.0
			_contact_remaining = _motion.contact_time() if animate else 0.0
			_motion.attack(event, animate)
			attack_started.emit(next_index - 1, _attack_remaining)
		"damage", "health_loss", "stats", "status", "kiss":
			var status_delay: float = (
				_motion.status_delay(event) if animate and kind == "status" else 0.0
			)
			if status_delay > 0:
				_tween().tween_callback(_sync_unit.bind(changed_uid)).set_delay(status_delay)
			else:
				_sync_unit(changed_uid)
			_motion.change(event, animate)
			if animate:
				if kind == "damage" and Data.i(event, "amount") > 0:
					_hit_remaining = 0.7
				if kind == "stats":
					# Wait only for arrival and the number roll. The next action retires old tails.
					_effect_remaining = maxf(
						_effect_remaining, 0.15 + _motion.stat_delay(changed_uid)
					)
				_roll_changes(
					changed_uid,
					_event_before,
					_motion.stat_delay(changed_uid) if kind == "stats" else 0.0
				)
		"gain_pending":
			_sync_unit(Data.i(event, "target", -1))
			WaveMotion.present(self, event, animate)
		"bog_toll", "bog_pull", "bog_bind", "bog_hit_back":
			WaveMotion.present(self, event, animate)
		"death":
			_death(Data.i(event, "uid", -1), animate)
			if animate:
				_ending = _final_death_pending()
		"swallowed":
			_motion.gulp(event, animate)
			_death(Data.i(event, "uid", -1), false)
			_sync_unit(Data.i(event, "by", -1))
		"summon":
			_summon(event, animate)
			_sync_unit(Data.i(event, "source", -1))
			if animate:
				_arrival_remaining = 0.3
		"relocate":
			_relocate(Data.i(event, "uid", -1), animate)
		"transform", "text_taken":
			for uid: int in _cards:
				_sync_unit(uid)
			_motion.cue(event, animate)
		"slot_mark":
			_mark_slot(event)
			_motion.cue(event, animate)
		"slot_hex":
			CombatLanesView.show_hex(self, event, animate)
			_motion.cue(event, animate)
		"combat_end":
			_show_result(animate)
		_:
			_motion.cue(event, animate)


func _final_death_pending() -> bool:
	for index: int in range(next_index, events.size()):
		var kind: String = Data.s(Data.entry(events, index), "type")
		if kind in ["attack", "death", "summon"]:
			return false
		if kind == "combat_end":
			return true
	return false


func _declaration_delay() -> float:
	var delay: float = 0.0
	for i: int in range(next_index, events.size()):
		var event: Dictionary = Data.entry(events, i)
		var kind: String = Data.s(event, "type")
		if (
			kind in ["attack", "combat_end"]
			or (kind == "damage" and Data.s(event, "kind") == "attack")
		):
			break
		delay += _event_hold(kind)
	return delay


func _sync_all() -> void:
	for board: BoardView in _boards:
		board.clear()
	_cards.clear()
	for side: int in 2:
		for slot: int in CombatModel.SLOTS:
			var uid: int = model.uid_at(side, slot)
			if uid >= 0:
				_make_card(uid, side, slot)
	for mark: Dictionary in model.slot_marks:
		_mark_slot(mark)
	var current_floor: Array = CombatLanesView.floor_state(self)
	for side: int in mini(2, current_floor.size()):
		if not current_floor[side] is Array:
			continue
		var marks: Array = current_floor[side]
		board_for_side(side).set_marks(marks)
	for hex: Dictionary in model.slot_hexes.values():
		board_for_side(Data.i(hex, "side")).set_hex(
			Data.i(hex, "slot"), Data.i(hex, "total"), Data.i(hex, "percent")
		)


func _make_card(uid: int, side: int, slot: int) -> CardView:
	var card := CardView.new()
	card.combat_face = true
	card.show_unit(model.unit(uid).duplicate(true), CardView.Mode.BOARD)
	for stat: String in ["attack", "health"]:
		var label: Label = card.get("_" + stat + "_label")
		label.set_meta("combat_primary_stat", true)
	card.zone = "combat"
	card.index = uid
	card.tapped.connect(_on_card_tapped)
	card.hovered.connect(_on_card_hovered)
	board_for_side(side).place_card(card, slot)
	_cards[uid] = card
	return card


func _roll_changes(uid: int, before: Dictionary, delay: float = 0.0) -> void:
	var card: CardView = _cards.get(uid)
	if card == null or before.is_empty():
		return
	for stat: String in ["attack", "health"]:
		var old: int = maxi(0, Data.i(before, stat))
		var current: int = maxi(0, Data.i(model.unit(uid), stat))
		if old != current:
			var label: Label = card.get("_" + stat + "_label")
			card.show_stat(stat, old)
			var tween: Tween = _tween().bind_node(label)
			tween.tween_interval(delay)
			tween.tween_method(
				func(value: int) -> void: card.show_stat(stat, value), old, current, 0.15
			)


func _sync_unit(uid: int) -> void:
	var card: CardView = CombatLanesView.card_for_uid(self, uid)
	if card == null:
		return
	var view: Dictionary = model.unit(uid)
	card.show_unit(view.duplicate(true), CardView.Mode.BOARD)
	CombatLanesView.sync_bog_state(card, view)


func _on_card_tapped(_zone: String, uid: int) -> void:
	if _reader.visible:
		_close_reader()
	else:
		_show_detail(uid)


func _on_card_hovered(_zone: String, uid: int, inside: bool) -> void:
	if CardView.is_phone():
		return
	if inside:
		_hover_close.stop()
		_show_detail(uid)
	else:
		_hover_close.start()


func _show_detail(uid: int) -> void:
	var view: Dictionary = model.unit(uid)
	if view.is_empty():
		return
	_open_reader()
	_reader.show_unit(view)
	CardDetail.show_rules(_note_text, view, Data.i(view, "side", -1) == bottom_side)
	var notes: PackedStringArray = _slot_notes(Data.i(view, "side"), Data.i(view, "slot"))
	if Data.i(view, "quarry") > 0:
		notes.append("Quarry: " + model.unit_name(Data.i(view, "quarry")))
	for hunter: Dictionary in model.units.values():
		if Data.i(hunter, "quarry", -1) == uid:
			notes.append("Quarry of: " + Data.s(hunter, "name"))
	if Data.i(view, "held") > 0:
		notes.append("Held: %d" % Data.i(view, "held"))
	if view.has("kisses"):
		var period: int = maxi(1, Data.i(view, "bog_kiss_period", 3))
		notes.append("Kisses: %d/%d" % [Data.i(view, "kisses") % period, period])
	_note_text.append_text("\n" + "\n".join(notes))


func _open_reader() -> void:
	_reader.clear_actions()
	_step_motion_remaining = 0
	if CardView.is_phone() and not _reader.visible:
		_resume_reader = playing
		_set_playing(false)


func _close_reader() -> void:
	_reader.show_empty()
	if CardView.is_phone() and _resume_reader:
		_set_playing(true)
	_resume_reader = false


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_ESCAPE and _scouting:
		close_scout()
		accept_event()
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed:
		if model.finished:
			_return_wait = 0
		elif _reader.visible and CardView.is_phone():
			_close_reader()


func _on_slot_tapped(_zone: String, slot: int, visual_side: int) -> void:
	if _reader.visible and CardView.is_phone():
		_close_reader()
		return
	var side: int = bottom_side if visual_side == 1 else 1 - bottom_side
	var words: PackedStringArray = _slot_notes(side, slot)
	if not words.is_empty():
		_open_reader()
		_reader.show_unit({"name": "This pocket", "text": "\n".join(words), "type_word": "Slot"})


func _slot_notes(side: int, slot: int) -> PackedStringArray:
	var words: PackedStringArray = []
	var current_floor: Array = CombatLanesView.floor_state(self)
	if side >= 0 and side < current_floor.size():
		var marks: Array = current_floor[side]
		var mark: Dictionary = Data.entry(marks, slot)
		if Data.b(mark, "has_ring"):
			words.append("Ring: " + Data.s(mark, "ring"))
		if Data.b(mark, "nest"):
			words.append("This pocket holds a Nest.")
	for hex: Dictionary in model.slot_hexes.values():
		if Data.i(hex, "side") == side and Data.i(hex, "slot") == slot:
			words.append("Hex: −%d Attack, −%d%%." % [Data.i(hex, "total"), Data.i(hex, "percent")])
	for patch: Dictionary in model.bog_patches.values():
		if (
			Data.i(patch, "side") == side
			and Data.i(patch, "slot") == slot
			and not Data.b(patch, "broken")
		):
			words.append("Mire binds this pocket while its maker is here.")
	for mark: Dictionary in model.slot_marks:
		if Data.i(mark, "side") == side and Data.i(mark, "slot") == slot:
			words.append("Trap: %d damage on entry." % Data.i(mark, "damage"))
	return words


func _show_hero(side: int) -> void:
	_open_reader()
	if _scouting and side != bottom_side:
		_reader.show_unit(
			LobbyPlaque.reader_card(Data.d(_scout_view, "standing"), Data.d(_scout_view, "hero"))
		)
		return
	var hero: Dictionary = hero_views[side]
	_reader.show_unit(
		{
			"name": _log_text.side_names[side],
			"def_id": Data.s(hero, "id"),
			"text": Data.s(hero, "text") + CombatLanesView.bog_summary(model, side),
			"type_word": "Hero"
		}
	)
	_reader.add_action("Last fight", open_log)
	_reader.add_action("Watch again", restart)


func _open_pause() -> void:
	var resume: bool = playing
	_pause_open = true
	_set_playing(false)
	var menu := PauseMenu.new()
	menu.add_fight_actions(open_log, restart)
	menu.guide_requested.connect(func() -> void: guide_requested.emit())
	menu.settings_requested.connect(func() -> void: settings_requested.emit())
	menu.leave_requested.connect(func() -> void: menu_requested.emit())
	menu.closed.connect(
		func() -> void:
			_pause_open = false
			_set_playing(resume)
	)
	add_child(menu)


func open_log() -> void:
	var page := FightLogPage.new()
	page.setup(_title, _log.all_text())
	add_child(page)


func _mark_slot(mark: Dictionary) -> void:
	board_for_side(Data.i(mark, "side")).set_trap(Data.i(mark, "slot"), Data.i(mark, "damage"))


func _summon(event: Dictionary, animate: bool) -> void:
	var view: Dictionary = Data.d(event, "unit")
	var card: CardView = _make_card(
		Data.i(view, "uid", -1), Data.i(event, "side"), Data.i(event, "slot")
	)
	_motion.arrive(card, event, animate)


func _relocate(uid: int, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card == null:
		return
	var view: Dictionary = model.unit(uid)
	var board: BoardView = board_for_side(Data.i(view, "side"))
	var start: Vector2 = board.move_card_here(card, Data.i(view, "slot"))
	if animate and not Settings.reduce_motion:
		_tween().tween_property(card, "position", card.position, maxf(0.1, 0.3 / speed)).from(start)
	else:
		_flash(uid, UiTheme.MOSS, animate)


func _death(uid: int, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	_motion.clear_actor_attack_source(uid)
	_cards.erase(uid)
	if card == null:
		return
	var board: BoardView = card.get_parent() as BoardView
	var slot: int = board.slot_of_card(card) if board != null else -1
	_last_death = (
		board.slot_global_center(slot) if slot >= 0 else card.get_global_rect().get_center()
	)
	if slot >= 0:
		board.detach_card(slot)
	if animate:
		_dying.append(card)
		_motion.die(card)
	else:
		card.get_parent().remove_child(card)
		card.queue_free()


func _show_result(animate: bool = true) -> void:
	_return_ready = not animate
	_set_playing(false)
	_motion.result(animate)
	_return_wait = 1.0 if animate else 0.1


func is_showing_result() -> bool:
	return model.finished


func _tween() -> Tween:
	var tween: Tween = create_tween()
	tween.pause()
	_tweens.append(tween)
	return tween


## Action boundaries cancel old callbacks and freeze their transient pictures while they fade.
## A separate layer keeps retiring pictures distinct from the new action's active cues.
func _retire_older_cues() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_clear_retiring_cues()
	for child: Node in _overlay.get_children():
		if child is CanvasItem and not child.is_queued_for_deletion():
			child.set_meta("cue_retired", true)
			child.reparent(_retiring_cues)
	for value: Variant in _dying:
		var dead: CardView = Data.control(value) as CardView
		if dead != null and not dead.is_queued_for_deletion():
			dead.set_meta("cue_retired", true)
			dead.reparent(_retiring_cues)
	_dying.clear()
	for uid: int in _cards:
		var card: CardView = _cards[uid]
		if not is_instance_valid(card):
			continue
		for child: Node in card.get_children():
			if child.has_meta("recipient_uid") and not child.is_queued_for_deletion():
				child.set_meta("cue_retired", true)
				child.reparent(_retiring_cues)
		_sync_unit(uid)
		card.modulate = Color.WHITE
		card.self_modulate = Color.WHITE
		card.scale = Vector2.ONE
		card.rotation = 0.0
		card.z_index = 0
		var host: BoardView = card.get_parent() as BoardView
		if host != null:
			var slot: int = host.slot_of_card(card)
			if slot >= 0:
				card.position = host.card_position(slot)
		for mark: Control in [card.trigger_glyph(), card.attack_bead(), card.health_bead()]:
			mark.modulate = Color.WHITE
			mark.scale = Vector2.ONE
	for board: BoardView in _boards:
		board.z_index = 0
		board.modulate = Color.WHITE
		board.scale = Vector2.ONE
	for plaque: Control in _plaques:
		plaque.modulate = Color.WHITE
		plaque.scale = Vector2.ONE
	_layout()
	if _retiring_cues.get_child_count() > 0:
		_retiring_cues.modulate = Color.WHITE
		var fade: Tween = _tween()
		fade.tween_property(_retiring_cues, "modulate:a", 0.0, 0.08)
		fade.tween_callback(_clear_retiring_cues)


func _clear_retiring_cues() -> void:
	if _retiring_cues == null:
		return
	for child: Node in _retiring_cues.get_children():
		if child is CanvasItem:
			(child as CanvasItem).hide()
		child.queue_free()
	_retiring_cues.modulate = Color.WHITE


func _kill_tweens() -> void:
	_clear_retiring_cues()
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	for child: Node in _overlay.get_children():
		child.queue_free()
	CombatLanesView.clear_dying_cards(self)


func _flash(uid: int, colour: Color, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card != null and animate:
		_motion.flash(card, colour)


func _has_active_tweens() -> bool:
	for tween: Tween in _tweens:
		if tween.is_valid() and tween.get_loops_left() != 0:
			return true
	return false
