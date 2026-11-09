extends Control
## Fight playback: event state remains in CombatModel; motion carries the public presentation.

signal finished
signal attack_started(index: int, duration: float)
signal guide_requested
signal settings_requested
signal menu_requested

const Numbers := preload("res://src/ui/stat_numbers.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const SlotView := preload("res://src/ui/widgets/slot_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatSounds := preload("res://src/ui/screens/combat_sounds.gd")
const CombatMotion := preload("res://src/ui/screens/combat_motion.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const LogNote := preload("res://src/ui/widgets/log_note.gd")
const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const CombatLanesView := preload("res://src/ui/screens/combat_lanes_view.gd")
const PauseMenu := preload("res://src/ui/widgets/pause_menu.gd")
const FightLogPage := preload("res://src/ui/screens/fight_log_page.gd")

const CANVAS_H: float = 1080.0
const POCKET: float = 189.0
const TRAY_GAP: float = 76.0
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
var _log_text: CombatLog = CombatLog.new()
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
var _plaques: Array[TokenButton] = []
var _health_labels: Array[Label] = []
var _tweens: Array[Tween] = []
var _dying: Array[CardView] = []
var _attacker_uid: int = -1
var _defender_uid: int = -1
var _last_death: Vector2 = Vector2.ZERO
var _resume_reader: bool = false
var _complete: bool = false
var _title: String = ""
var _event_before: Dictionary = {}


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiTheme.add_table(self)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	for i: int in 2:
		var board := BoardView.new()
		board.combat_mode = true
		board.configure("enemy" if i == 0 else "own", POCKET, i == 1)
		for slot: SlotView in board.slots:
			slot.tapped.connect(_on_slot_tapped.bind(i))
		_stage.add_child(board)
		_boards.append(board)
	_lanes = LaneOverlay.new()
	_lanes.combat_mode = true
	_stage.add_child(_lanes)
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
		plaque.pressed.connect(_show_hero.bind(side))
		_stage.add_child(plaque)
		_plaques.append(plaque)
		var art := ArtFrame.new()
		art.name = "Portrait"
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
	_speed_button.pressed.connect(_cycle_speed)
	_stage.add_child(_speed_button)
	_play_button = TokenButton.new("", "pause")
	_play_button.pressed.connect(toggle_play)
	_stage.add_child(_play_button)
	_step_button = TokenButton.new("", "step")
	_step_button.pressed.connect(step_once)
	_stage.add_child(_step_button)
	_skip_button = TokenButton.new("", "skip")
	var skip_glyph: TextureRect = _skip_button.get("_glyph")
	skip_glyph.self_modulate = UiTheme.INK
	_skip_button.pressed.connect(skip_to_end)
	_stage.add_child(_skip_button)
	_gear = TokenButton.new("", "gear")
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
	hero_health[1 - bottom_side] = opponent_health
	var health_before: Array = Data.a(combat, "hero_health_before")
	for side: int in mini(2, health_before.size()):
		hero_health[side] = Data.as_int(health_before[side])
	hero_health_after = Data.a(combat, "hero_health_after")
	for side: int in 2:
		var art: ArtFrame = _plaques[side].get_node("Portrait")
		art.texture = UiTheme.portrait_for(Data.s(hero_views[side], "id"), [])
		_health_labels[side].text = str(hero_health[side])
		var hip: Control = _health_labels[side].get_parent() as Control
		hip.visible = hero_health[side] >= 0
	_layout()
	restart()


func board_for_side(side: int) -> BoardView:
	return _boards[1] if side == bottom_side else _boards[0]


func _layout() -> void:
	if _stage == null or size.x < 10.0:
		return
	_stage.position = Vector2(0, maxf(0.0, (size.y - CANVAS_H) / 2.0))
	_stage.size = Vector2(size.x, CANVAS_H)
	var tray: Vector2 = _boards[0].tray_size()
	var x: float = (size.x - tray.x) / 2.0
	_boards[0].position = Vector2(x, 18)
	_boards[1].position = Vector2(x, 18 + tray.y + TRAY_GAP)
	for board: BoardView in _boards:
		board.size = tray
	for side: int in 2:
		var board: BoardView = board_for_side(side)
		_plaques[side].position = board.position + Vector2(-170, tray.y / 2.0 - 70)
		_plaques[side].size = Vector2(148, 157)
	var tap: float = 122.0 if size.x >= 2200 else 90.0
	var controls: Array[Control] = [_gear, _speed_button, _play_button, _skip_button]
	for i: int in controls.size():
		controls[i].position = Vector2(size.x - (4 - i) * (tap + 14), CANVAS_H - tap - 18)
		controls[i].size = Vector2(tap, tap + 9)
	_step_button.position = _speed_button.position
	_step_button.size = _speed_button.size
	_lanes.boards = [board_for_side(0), board_for_side(1)]
	_reader.position = Vector2(clampf(x + tray.x + 20, 12, size.x - 550), 28)
	_reader.size = Vector2(530, CANVAS_H - tap - 18 - _reader.position.y - 16)


func restart() -> void:
	_kill_tweens()
	model = CombatModel.new()
	for board: BoardView in _boards:
		board.clear_highlights()
		board.clear()
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
	_wait = 0.1
	_set_playing(true)


func _set_playing(on: bool) -> void:
	playing = on
	_play_button.set_icon_name("pause" if on else "play")
	_speed_button.visible = on
	_step_button.visible = not on


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
	if _pause_open or (not playing and not model.finished and _step_motion_remaining <= 0):
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
			_complete = true
			finished.emit()
		return
	_attack_remaining = maxf(0, _attack_remaining - delta)
	_contact_remaining = maxf(0, _contact_remaining - delta)
	_effect_remaining = maxf(0, _effect_remaining - delta)
	_hit_remaining = maxf(0, _hit_remaining - delta)
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
	if _ending and kind != "death":
		return 0.0
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
					_effect_remaining = maxf(
						_effect_remaining, 0.15 + _motion.stat_delay(changed_uid)
					)
				_roll_changes(
					changed_uid,
					_event_before,
					_motion.stat_delay(changed_uid) if kind == "stats" else 0.0
				)
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
	for side: int in mini(2, floor_marks.size()):
		if not floor_marks[side] is Array:
			continue
		var marks: Array = floor_marks[side]
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
			label.text = Numbers.compact(old)
			var tween: Tween = _tween().bind_node(label)
			tween.tween_interval(delay)
			tween.tween_method(
				func(value: int) -> void: label.text = Numbers.compact(value), old, current, 0.15
			)


func _sync_unit(uid: int) -> void:
	var card: CardView = _cards.get(uid)
	if card != null:
		card.show_unit(model.unit(uid).duplicate(true), CardView.Mode.BOARD)


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
	if Data.i(view, "kisses") > 0:
		notes.append("Kisses: %d/3" % Data.i(view, "kisses"))
	_note_text.append_text("\n" + "\n".join(notes))


func _open_reader() -> void:
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
	if side >= 0 and side < floor_marks.size():
		var marks: Array = floor_marks[side]
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
	var hero: Dictionary = hero_views[side]
	_reader.show_unit(
		{
			"name": _log_text.side_names[side],
			"def_id": Data.s(hero, "id"),
			"text": Data.s(hero, "text"),
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
	_cards.erase(uid)
	if card == null:
		return
	_last_death = card.get_global_rect().get_center()
	var board: BoardView = card.get_parent() as BoardView
	var slot: int = board.slot_of_card(card) if board != null else -1
	if slot >= 0:
		board.detach_card(slot)
	if animate:
		_dying.append(card)
		_motion.die(card)
	else:
		card.get_parent().remove_child(card)
		card.queue_free()


func _show_result(animate: bool = true) -> void:
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


func _kill_tweens() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	for child: Node in _overlay.get_children():
		child.queue_free()
	for card: CardView in _dying:
		if is_instance_valid(card):
			card.queue_free()
	_dying.clear()


func _flash(uid: int, colour: Color, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card != null and animate:
		_motion.flash(card, colour)
