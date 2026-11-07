extends Control
## Plays a fight event list (SPEC 5): trays, attack yarn, effects, log, controls, then result.

signal finished

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatSounds := preload("res://src/ui/screens/combat_sounds.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const RowTag := preload("res://src/ui/widgets/row_tag.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const HitPanel := preload("res://src/ui/widgets/hit_panel.gd")
const LogNote := preload("res://src/ui/widgets/log_note.gd")
const AttackYarn := preload("res://src/ui/widgets/attack_yarn.gd")

const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const CombatLanesView := preload("res://src/ui/screens/combat_lanes_view.gd")

const CANVAS_H: float = 1080.0
const POCKET: float = 189.0
const TRAY_TOP: float = 14.0
const TRAY_GAP: float = 72.0
const SPEEDS: Array[float] = [1.0, 2.0, 4.0]
const DEATH_LEAVES: int = 6

var model: CombatModel = CombatModel.new()
var events: Array = []
var next_index: int = 0
var playing: bool = true
var speed: float = 1.0
## Which side is drawn at the bottom ("yours").
var bottom_side: int = 0

var _log_text: CombatLog = CombatLog.new()
var _stage: Control
var _boards: Array[BoardView] = []
var _tags: Array[RowTag] = []
var _cards: Dictionary[int, CardView] = {}
var _wait: float = 0.0
var _hit: HitPanel
var _log: LogNote
var _note: WoodPanel
var _note_icon: TextureRect
var _note_head: Label
var _note_text: RichTextLabel
var _fight_plaque: WoodPanel
var _fight_word: Label
var _fight_name: Label
var _fight_hip: ShapeBadge
var _fight_health: Label
var _speed_plaque: WoodPanel
var _speed_word: Label
var _speed_buttons: Array[TokenButton] = []
var _play_button: TokenButton
var _step_button: TokenButton
var _skip_button: LeafButton
var _lanes: LaneOverlay
var _yarn: AttackYarn
var _attacking_tag: Label
var _target_tag: Label
var _caption: Label
var _overlay: Control
var _attack_count: int = 0
var _attacker_uid: int = -1
var _defender_uid: int = -1
var _result_panel: ColorRect
var _result_plaque: WoodPanel
var _result_title: Label
var _result_text: Label
var _tweens: Array[Tween] = []
## Cards fading out after a death; freed when their tween ends or playback is cut short.
var _dying: Array[CardView] = []


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiTheme.add_table(self)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_build_left()
	_build_field()
	_build_right()
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_build_result()
	set_speed(Settings.fight_speed)
	resized.connect(_layout)
	ready.connect(_layout)
	_layout()


func _build_left() -> void:
	_hit = HitPanel.new()
	_stage.add_child(_hit)
	_log = LogNote.new()
	_stage.add_child(_log)
	_note = WoodPanel.new(WoodPanel.Kind.BIRCH)
	_stage.add_child(_note)
	_note_icon = TextureRect.new()
	_note_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_note_icon.texture = Icons.icon("berry", 46.0)
	_note_icon.position = Vector2(26, 14)
	_note_icon.size = Vector2(46, 46)
	_note.add_child(_note_icon)
	_note_head = UiTheme.burned("", UiTheme.FONT_SMALL, UiTheme.NIGHTSHADE)
	_note_head.position = Vector2(82, 16)
	_note_head.clip_text = true
	_note_head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_note_head.set_meta("ellipsis_ok", true)
	_note.add_child(_note_head)
	_note_text = RichTextLabel.new()
	_note_text.bbcode_enabled = true
	_note_text.scroll_active = true
	_note_text.mouse_filter = Control.MOUSE_FILTER_PASS
	_note_text.add_theme_font_size_override("normal_font_size", UiTheme.FONT_SMALL)
	_note_text.add_theme_font_size_override("bold_font_size", UiTheme.FONT_SMALL)
	_note_text.add_theme_constant_override("line_separation", -2)
	_note.add_child(_note_text)
	_show_note("", "Tap a unit to read it.")


func _build_field() -> void:
	for i: int in 2:
		var board: BoardView = BoardView.new()
		board.configure("enemy" if i == 0 else "own", POCKET, i == 1)
		_stage.add_child(board)
		_boards.append(board)
		var tag: RowTag = RowTag.new("")
		_stage.add_child(tag)
		_tags.append(tag)
	_lanes = LaneOverlay.new()
	_stage.add_child(_lanes)
	_yarn = AttackYarn.new()
	_yarn.visible = false
	_yarn.z_index = 6
	_stage.add_child(_yarn)
	_attacking_tag = _tag_slip(UiTheme.ACORN, UiTheme.INK)
	_target_tag = _tag_slip(UiTheme.HEALTH, UiTheme.CREAM)
	_caption = UiTheme.head("", UiTheme.FONT_TITLE)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.BIRCH, 5, 14))
	_caption.z_index = 9
	_caption.visible = false
	_stage.add_child(_caption)


func _tag_slip(fill: Color, ink: Color) -> Label:
	var tag: Label = UiTheme.burned("", UiTheme.FONT_SMALL, ink)
	var face: StyleBoxFlat = UiTheme.slip_box(fill, 5, 8)
	tag.add_theme_stylebox_override("normal", face)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.visible = false
	tag.z_index = 8
	_stage.add_child(tag)
	return tag


func _build_right() -> void:
	_fight_plaque = WoodPanel.new(WoodPanel.Kind.OAK)
	_stage.add_child(_fight_plaque)
	_fight_word = UiTheme.burned("Fighting", UiTheme.FONT_SMALL)
	_fight_word.position = Vector2(30, 14)
	_fight_plaque.add_child(_fight_word)
	_fight_name = UiTheme.head("", UiTheme.FONT_TITLE)
	_fight_name.clip_text = true
	_fight_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_fight_name.set_meta("ellipsis_ok", true)
	_fight_plaque.add_child(_fight_name)
	_fight_hip = ShapeBadge.new("rosehip")
	_fight_plaque.add_child(_fight_hip)
	_fight_health = UiTheme.number("", UiTheme.FONT_BODY, UiTheme.CREAM)
	_fight_health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fight_health.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fight_health.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fight_health.offset_top = 5.0
	_fight_hip.add_child(_fight_health)
	_speed_plaque = WoodPanel.new(WoodPanel.Kind.OAK)
	_stage.add_child(_speed_plaque)
	_speed_word = UiTheme.burned("Speed", UiTheme.FONT_SMALL)
	_speed_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_plaque.add_child(_speed_word)
	for value: float in SPEEDS:
		var token: TokenButton = TokenButton.new("×%d" % int(value))
		token.pressed.connect(set_speed.bind(value))
		_speed_plaque.add_child(token)
		_speed_buttons.append(token)
	_play_button = TokenButton.new("Pause", "pause")
	_play_button.set_word("")
	_play_button.pressed.connect(toggle_play)
	_stage.add_child(_play_button)
	_step_button = TokenButton.new("", "step")
	_step_button.pressed.connect(step_once)
	_stage.add_child(_step_button)
	_skip_button = LeafButton.new()
	_skip_button.colour = LeafButton.Colour.MOSS
	_skip_button.set_face("Skip", "", -1, "to the result")
	_skip_button.pressed.connect(skip_to_end)
	_stage.add_child(_skip_button)


func _build_result() -> void:
	_result_panel = ColorRect.new()
	_result_panel.color = UiTheme.SHADE
	_result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_panel.visible = false
	_result_panel.z_index = 20
	add_child(_result_panel)
	_result_plaque = WoodPanel.new(WoodPanel.Kind.OAK)
	_result_panel.add_child(_result_plaque)
	_result_title = UiTheme.head("", UiTheme.FONT_HUGE)
	_result_title.add_theme_font_override("font", UiTheme.title_font())
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_plaque.add_child(_result_title)
	_result_text = UiTheme.head("", UiTheme.FONT_BODY + 6)
	_result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_plaque.add_child(_result_text)
	var replay: LeafButton = LeafButton.new()
	replay.name = "WatchAgain"
	replay.set_face("Watch again")
	replay.pressed.connect(restart)
	_result_plaque.add_child(replay)
	var go_on: LeafButton = LeafButton.new()
	go_on.name = "Continue"
	go_on.colour = LeafButton.Colour.MOSS
	go_on.set_face("Continue")
	go_on.pressed.connect(func() -> void: finished.emit())
	_result_plaque.add_child(go_on)


## combat: {"events": [...], ...}; side_names[side]; bottom: the side drawn at the bottom. The title
## sits on the log ("Round 6"). `opponent_health` below 0 hides the rosehip (sandbox).
func setup(
	combat: Dictionary,
	side_names: PackedStringArray,
	bottom: int,
	title: String,
	opponent_health: int = -1
) -> void:
	events = Data.a(combat, "events")
	bottom_side = clampi(bottom, 0, 1)
	_log_text.side_names = side_names
	_log.set_title(title)
	var opponent: String = UiTheme.short_name(side_names[1 - bottom_side])
	_fight_name.text = opponent
	_fight_hip.visible = opponent_health >= 0
	_fight_health.text = str(opponent_health)
	_tags[0].text = opponent
	_tags[1].text = UiTheme.short_name(side_names[bottom_side])
	_layout()
	_fight_name.text = UiTheme.fit_words(opponent, _fight_name)
	restart()


func board_for_side(side: int) -> BoardView:
	return _boards[1] if side == bottom_side else _boards[0]


func _layout() -> void:
	if _stage == null or size.x < 10.0:
		return
	var w: float = size.x
	var wide: bool = w >= 2200.0
	var left_w: float = 692.0 if wide else 523.0
	var right_w: float = 489.0 if wide else 320.0
	var tap: float = 122.0 if wide else 90.0
	_stage.position = Vector2(0, maxf(0.0, (size.y - CANVAS_H) / 2.0))
	_stage.size = Vector2(w, CANVAS_H)
	_hit.position = Vector2(14, 24)
	_hit.size = Vector2(left_w, 348)
	_log.position = Vector2(14, 396)
	_log.size = Vector2(left_w, 436)
	_note.position = Vector2(14, 858)
	_note.size = Vector2(left_w, 196)
	_note_head.size = Vector2(left_w - 104.0, 42)
	_note_text.position = Vector2(26, 62)
	_note_text.size = Vector2(left_w - 52.0, 124)
	var field_x: float = 14.0 + left_w
	var field_w: float = w - field_x - right_w - 14.0
	var tray: Vector2 = _boards[0].tray_size()
	var tray_x: float = field_x + maxf(40.0, (field_w - tray.x - RowTag.WIDTH) / 2.0)
	_boards[0].position = Vector2(tray_x, TRAY_TOP)
	_boards[1].position = Vector2(tray_x, TRAY_TOP + tray.y + TRAY_GAP)
	for i: int in 2:
		_boards[i].size = tray
		var tag_h: float = 220.0
		var tag_y: float = _boards[i].position.y + (tray.y - tag_h) / 2.0
		_tags[i].position = Vector2(tray_x + tray.x + 8.0, tag_y)
		_tags[i].size = Vector2(RowTag.WIDTH, tag_h)
	_yarn.position = Vector2.ZERO
	_yarn.size = _stage.size
	_layout_right(w - right_w - 14.0, right_w, tap)
	var plaque_size: Vector2 = Vector2(900, 480)
	_result_plaque.position = (size - plaque_size) / 2.0
	_result_plaque.size = plaque_size
	_result_title.position = Vector2(0, 18)
	_result_title.size = Vector2(plaque_size.x, 130)
	_result_text.position = Vector2(50, 160)
	_result_text.size = Vector2(plaque_size.x - 100.0, 130)
	var again: Control = _result_plaque.get_node("WatchAgain")
	var go_on: Control = _result_plaque.get_node("Continue")
	again.position = Vector2(24, 306)
	again.size = Vector2(420, 140)
	go_on.position = Vector2(456, 306)
	go_on.size = Vector2(420, 140)


func _layout_right(x: float, w: float, tap: float) -> void:
	_fight_plaque.position = Vector2(x, 24)
	_fight_plaque.size = Vector2(w, 142)
	_fight_name.position = Vector2(30, 52)
	_fight_name.size = Vector2(w - 118.0, 76)
	_fight_hip.position = Vector2(w - 86.0, 54)
	_fight_hip.size = Vector2(68, 68)
	var row: float = maxf(tap, 88.0)
	_speed_plaque.position = Vector2(x, 202)
	_speed_plaque.size = Vector2(w, 66.0 + row + 22.0)
	_speed_word.position = Vector2(0, 12)
	_speed_word.size = Vector2(w, 42)
	var token_w: float = minf(row, (w - 40.0) / 3.0)
	var spacing: float = (w - token_w * 3.0) / 4.0
	for i: int in _speed_buttons.size():
		_speed_buttons[i].position = Vector2(spacing + i * (token_w + spacing), 60)
		_speed_buttons[i].size = Vector2(token_w, row + 9.0)
	var tool_y: float = 202.0 + _speed_plaque.size.y + 40.0
	var side: float = tap
	_play_button.position = Vector2(x + w / 2.0 - side - 20.0, tool_y)
	_play_button.size = Vector2(side, side + 9.0)
	_step_button.position = Vector2(x + w / 2.0 + 20.0, tool_y)
	_step_button.size = Vector2(side, side + 9.0)
	_skip_button.position = Vector2(x, CANVAS_H - 24.0 - 154.0)
	_skip_button.size = Vector2(w, 154)


func restart() -> void:
	_kill_tweens()
	model = CombatModel.new()
	for board: BoardView in _boards:
		board.clear_highlights()
		board.clear()
	_cards.clear()
	_lanes.bindings = {"patches": [], "quarries": []}
	_lanes.pack.clear()
	_log.clear()
	_hit.clear()
	_clear_attack()
	_caption.visible = false
	_attack_count = 0
	_result_panel.visible = false
	next_index = 0
	# A short pause first, so the boards are laid out before anything moves.
	_wait = 0.4
	_set_playing(true)


func _set_playing(on: bool) -> void:
	playing = on
	_play_button.set_icon_name("pause" if on else "play")


func toggle_play() -> void:
	if model.finished:
		return
	_set_playing(not playing)


func set_speed(value: float) -> void:
	speed = value
	for i: int in SPEEDS.size():
		_speed_buttons[i].lit = is_equal_approx(SPEEDS[i], value)
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.set_speed_scale(speed)


func step_once() -> void:
	_set_playing(false)
	if next_index < events.size():
		_play_event(Data.entry(events, next_index), true)
		next_index += 1


func skip_to_end() -> void:
	_kill_tweens()
	Sfx.silence()
	while next_index < events.size():
		_play_event(Data.entry(events, next_index), false)
		next_index += 1
	_sync_all()


func _process(delta: float) -> void:
	if not playing or next_index >= events.size():
		return
	_wait -= delta * speed
	if _wait > 0.0:
		return
	var event: Dictionary = events[next_index]
	next_index += 1
	_play_event(event, true)
	_wait = CombatLog.DURATIONS.get(str(event.get("type", "")), 0.5)


func _play_event(event: Dictionary, animate: bool) -> void:
	var kind: String = str(event.get("type", ""))
	var line: String = _log_text.describe(event, model, false)
	if not line.is_empty():
		_log.push(line, CombatLog.LOUD_EVENTS.has(kind))
	if not _log_text.last_reminder.is_empty():
		_show_note(_log_text.last_keyword, _log_text.last_reminder)
	var before: Dictionary = {}
	var target_uid: int = event.get("target", Data.i(event, "uid", -1))
	if model.units.has(target_uid):
		before = model.unit(target_uid).duplicate()
	model.apply(event)
	if animate:
		CombatSounds.play(event, model, bottom_side)
	_lanes.boards = [board_for_side(0), board_for_side(1)]
	CombatLanesView.present(self, event, animate)
	match kind:
		"combat_start":
			_sync_all()
		"phase":
			var phase_name: String = str(event.get("name", ""))
			_clear_attack()
			_say(CombatLog.phase_word(phase_name), animate)
		"trigger":
			var uid: int = Data.i(event, "uid", -1)
			var mechanic: String = Data.s(event, "mechanic")
			_flash(uid, UiTheme.ACORN, animate)
			_float_chip(uid, CombatLog.trigger_name(model, uid, mechanic), UiTheme.BIRCH, animate)
		"attack":
			_attack(event, animate)
		"damage":
			_damage(event, animate)
		"health_loss":
			_health_loss(event, before, animate)
		"status":
			_status(event, animate)
		"stats":
			var uid: int = Data.i(event, "target", -1)
			_sync_unit(uid)
			var attack: int = Data.i(event, "attack_delta", 0)
			var health: int = Data.i(event, "health_delta", 0)
			if attack != 0 or health != 0:
				_float_chip(uid, CombatLog.stat_delta_text(attack, health), UiTheme.BIRCH, animate)
		"death":
			_death(Data.i(event, "uid", -1), animate)
		"summon":
			_summon(event, animate)
			_sync_unit(Data.i(event, "source", -1))
		"swallowed":
			_death(Data.i(event, "uid", -1), false)
			_sync_unit(Data.i(event, "by", -1))
			_float_chip(Data.i(event, "by", -1), "Gulp!", UiTheme.ACORN, animate)
		"goose_strike":
			_flash(Data.i(event, "target", -1), UiTheme.ACORN, animate)
		"text_taken":
			_float_chip(Data.i(event, "uid", -1), "Pinched!", UiTheme.ACORN, animate)
		"relocate":
			_relocate(Data.i(event, "uid", -1), animate)
		"skip":
			var reason: String = str(event.get("reason", "")).capitalize()
			_float_chip(Data.i(event, "uid", -1), "Skips: %s" % reason, UiTheme.BIRCH, animate)
		"whistle":
			_float_chip(Data.i(event, "uid", -1), "Whistle!", UiTheme.ACORN, animate)
			for uid: int in Data.a(event, "warned"):
				_flash(uid, UiTheme.status_colour("warned"), animate)
		"cancel":
			_float_chip(Data.i(event, "uid", -1), "Cancelled", UiTheme.BIRCH, animate)
		"pass":
			var side: int = clampi(Data.i(event, "side", 0), 0, 1)
			_say("%s can't attack: pass" % UiTheme.short_name(_log_text.side_names[side]), animate)
		"slot_mark":
			_slot_mark(event, animate)
		"slot_hex":
			_slot_hex(event, animate)
		"combat_end":
			_show_result()


func _show_note(keyword: String, words: String) -> void:
	CombatLanesView.show_note(self, keyword, words)


func _sync_all() -> void:
	_clear_attack()
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
	for hex: Dictionary in model.slot_hexes.values():
		board_for_side(Data.i(hex, "side", 0)).set_hex(Data.i(hex, "slot"), Data.i(hex, "total"))


func _make_card(uid: int, side: int, slot: int) -> CardView:
	var card: CardView = CardView.new()
	card.show_unit(model.unit(uid).duplicate(true), CardView.Mode.BOARD)
	card.zone = "combat"
	card.index = uid
	card.tapped.connect(_on_card_tapped)
	card.hovered.connect(_on_card_hovered)
	board_for_side(side).place_card(card, slot)
	_cards[uid] = card
	card.turns_shown = CombatLog.held_slip(model.unit(uid))
	return card


func _sync_unit(uid: int) -> void:
	var card: CardView = _cards.get(uid)
	if card == null:
		return
	var view: Dictionary = model.unit(uid)
	card.set_stats(
		Data.i(view, "attack", 0), Data.i(view, "health", 0), Data.i(view, "max_health", 0)
	)
	card.set_statuses(Data.a(view, "statuses"))
	card.turns_shown = CombatLog.held_slip(view)


func _on_card_tapped(_zone: String, uid: int) -> void:
	_show_detail(uid)


func _on_card_hovered(_zone: String, uid: int, inside: bool) -> void:
	if inside:
		_show_detail(uid)


func _show_detail(uid: int) -> void:
	var view: Dictionary = model.unit(uid)
	if view.is_empty():
		return
	_note_head.text = Data.s(view, "name").to_upper()
	_note_icon.visible = false
	_note_head.position.x = 28.0
	_note_text.text = CardDetail.full_text_bbcode(view)


func _attack(event: Dictionary, animate: bool) -> void:
	_clear_attack()
	_attacker_uid = Data.i(event, "attacker", -1)
	_defender_uid = Data.i(event, "defender", -1)
	_attack_count += 1
	var health: int = Data.i(model.unit(_defender_uid), "health", 0)
	_hit.begin(
		model.unit_name(_attacker_uid), model.unit_name(_defender_uid), health, _attack_count
	)
	var attacker: CardView = _cards.get(_attacker_uid)
	var defender: CardView = _cards.get(_defender_uid)
	if attacker == null or defender == null:
		return
	defender.outline = UiTheme.YARN
	attacker.outline = UiTheme.ACORN
	for uid: int in Data.a(event, "joiners"):
		var joiner: CardView = _cards.get(uid)
		if joiner != null:
			joiner.outline = UiTheme.ACORN
	if not animate:
		_clear_outlines()
		return
	_show_yarn(attacker, defender)
	if Settings.reduce_motion:
		return
	var home: Vector2 = attacker.position
	var board: Control = attacker.get_parent() as Control
	var to: Vector2 = (
		board.get_global_transform().affine_inverse() * (defender.get_global_rect().get_center())
	)
	var lunge: Vector2 = home.lerp(to - attacker.card_size / 2.0, 0.22)
	attacker.z_index = 10
	var tween: Tween = _tween().bind_node(attacker)
	tween.tween_property(attacker, "position", lunge, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tween.tween_property(attacker, "position", home, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_callback(func() -> void: attacker.z_index = 0)


## Yarn runs through the gap; back-row attacks go outside the tray to avoid the unit in front.
func _show_yarn(attacker: CardView, defender: CardView) -> void:
	var from_rect: Rect2 = _stage_rect(attacker)
	var to_rect: Rect2 = _stage_rect(defender)
	var from_side: int = _side_of_board(attacker)
	var slot: int = (attacker.get_parent() as BoardView).slot_of_card(attacker)
	var gap_y: float = _boards[0].position.y + _boards[0].tray_size().y + TRAY_GAP / 2.0 - 4.0
	var going_up: bool = from_side == 1
	var into_y: float = to_rect.end.y + 34.0 if going_up else to_rect.position.y - 34.0
	var to_x: float = to_rect.get_center().x
	var points: PackedVector2Array = []
	var from_x: float = from_rect.get_center().x
	if slot < BoardView.FRONT:
		points.append(Vector2(from_x, from_rect.position.y if going_up else from_rect.end.y))
		points.append(Vector2(from_x, gap_y))
	else:
		var tray: BoardView = _boards[from_side]
		var side_x: float = tray.position.x - 26.0
		var outer_y: float = tray.position.y - 8.0
		if going_up:
			outer_y = tray.position.y + tray.tray_size().y + 6.0
		points.append(Vector2(from_x, from_rect.end.y if going_up else from_rect.position.y))
		points.append(Vector2(from_x, outer_y))
		points.append(Vector2(side_x, outer_y))
		points.append(Vector2(side_x, gap_y))
	points.append(Vector2(to_x, gap_y))
	points.append(Vector2(to_x, into_y))
	_yarn.show_route(points)
	_yarn.progress = 0.0
	var tween: Tween = _tween()
	tween.tween_property(_yarn, "progress", 1.0, 0.0 if Settings.reduce_motion else 0.24)
	_place_tag(_attacking_tag, "Attacking", from_rect, slot >= BoardView.FRONT, going_up)
	_place_target_tag(model.unit_name(_defender_uid), to_x, gap_y)


func _place_tag(tag: Label, words: String, rect: Rect2, back: bool, going_up: bool) -> void:
	tag.text = words.to_upper()
	tag.size = tag.get_minimum_size()
	tag.visible = true
	var below: bool = going_up == back
	var y: float = rect.end.y - 6.0 if below else rect.position.y - tag.size.y + 6.0
	var x: float = rect.get_center().x - tag.size.x / 2.0
	tag.position = Vector2(x, clampf(y, 0.0, CANVAS_H - tag.size.y))


func _place_target_tag(words: String, to_x: float, gap_y: float) -> void:
	_target_tag.text = "TARGET  %s" % words
	_target_tag.size = _target_tag.get_minimum_size()
	_target_tag.visible = true
	var x: float = to_x + 44.0
	var tray_right: float = _boards[0].position.x + _boards[0].tray_size().x
	if x + _target_tag.size.x > tray_right:
		x = to_x - 44.0 - _target_tag.size.x
	_target_tag.position = Vector2(x, gap_y - _target_tag.size.y / 2.0)


func _stage_rect(card: CardView) -> Rect2:
	var board: Control = card.get_parent() as Control
	return Rect2(board.position + card.position, card.card_size)


func _side_of_board(card: CardView) -> int:
	return 0 if card.get_parent() == _boards[0] else 1


func _clear_attack() -> void:
	_yarn.hide_route()
	_attacking_tag.visible = false
	_target_tag.visible = false
	_clear_outlines()


func _clear_outlines() -> void:
	# Untyped until checked: a typed loop variable errors on a card already freed.
	for value: Variant in _cards.values():
		if is_instance_valid(value):
			var card: CardView = value
			card.outline = Color.TRANSPARENT


func _damage(event: Dictionary, animate: bool) -> void:
	var uid: int = Data.i(event, "target", -1)
	_sync_unit(uid)
	var amount: int = Data.i(event, "amount", 0)
	var after: int = Data.i(event, "health_after", 0)
	if uid == _defender_uid:
		_hit.add_hit(amount, after)
	elif uid == _attacker_uid:
		var kind: String = str(event.get("kind", "attack"))
		var how: String = "Bristle" if kind == "thorns" else "Takes"
		_hit.set_back("%s %d back: %d left" % [how, amount, maxi(after, 0)])
	_burst(uid, amount, animate)
	_shake(uid, animate)


func _health_loss(event: Dictionary, before: Dictionary, animate: bool) -> void:
	var uid: int = Data.i(event, "target", -1)
	_sync_unit(uid)
	var after: int = Data.i(event, "health_after", 0)
	var old: int = before.get("health", after + Data.i(event, "amount", 0))
	if uid == _defender_uid:
		_hit.add_half(after)
	_flash(uid, UiTheme.NIGHTSHADE, animate)
	_float_chip(uid, "½: %d to %d" % [old, after], UiTheme.SPELL_FACE, animate)


func _status(event: Dictionary, animate: bool) -> void:
	var uid: int = Data.i(event, "target", -1)
	_sync_unit(uid)
	var key: String = str(event.get("status", ""))
	var on: bool = Data.b(event, "on", true)
	if on:
		_flash(uid, UiTheme.status_colour(key), animate)
		_float_chip(uid, UiTheme.status_label(key), UiTheme.BIRCH, animate)


func _death(uid: int, animate: bool) -> void:
	if uid == _defender_uid:
		_hit.add_death()
	if uid == _attacker_uid:
		_attacking_tag.visible = false
	var card: CardView = _cards.get(uid)
	_cards.erase(uid)
	if card == null:
		return
	var board: BoardView = card.get_parent() as BoardView
	var slot: int = board.slot_of_card(card) if board != null else -1
	if slot >= 0:
		board.detach_card(slot)
	if not animate:
		card.get_parent().remove_child(card)
		card.queue_free()
		return
	card.outline = Color.TRANSPARENT
	_dying.append(card)
	var tween: Tween = _tween()
	tween.set_parallel(true)
	if Settings.reduce_motion:
		tween.tween_property(card, "modulate:a", 0.0, 0.3)
	else:
		_leaf_puff(card.get_global_rect().get_center())
		tween.tween_property(card, "rotation", 0.35, 0.4).set_ease(Tween.EASE_IN)
		tween.tween_property(card, "position:y", card.position.y + 44.0, 0.4).set_ease(
			Tween.EASE_IN
		)
		tween.tween_property(card, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(card.queue_free)


func _summon(event: Dictionary, animate: bool) -> void:
	var view: Dictionary = Data.d(event, "unit")
	var uid: int = Data.i(view, "uid", -1)
	var card: CardView = _make_card(uid, Data.i(event, "side", 0), Data.i(event, "slot", 0))
	if not animate:
		return
	card.outline = UiTheme.MOSS
	_float_chip(uid, CombatLog.arrival_word(event), UiTheme.BIRCH, animate)
	var tween: Tween = _tween().bind_node(card)
	if Settings.reduce_motion:
		tween.tween_interval(0.3)
	else:
		card.scale = Vector2(0.3, 0.3)
		tween.tween_property(card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(
			Tween.EASE_OUT
		)
	tween.tween_callback(
		func() -> void:
			if is_instance_valid(card):
				card.outline = Color.TRANSPARENT
	)


## A unit moved (Whirligig Beetle, Changeling). A card left behind is freed by the next one placed.
func _relocate(uid: int, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card == null:
		return
	var view: Dictionary = model.unit(uid)
	var board: BoardView = board_for_side(Data.i(view, "side", 0))
	var start: Vector2 = board.move_card_here(card, Data.i(view, "slot", 0))
	if animate and not Settings.reduce_motion:
		_tween().tween_property(card, "position", card.position, 0.35).from(start)


func _slot_mark(event: Dictionary, animate: bool) -> void:
	_mark_slot(event)
	if animate:
		var board: BoardView = board_for_side(Data.i(event, "side", 0))
		var point: Vector2 = board.slot_global_center(Data.i(event, "slot", 0))
		_float_at(point, "Marked: %d" % Data.i(event, "damage", 0), UiTheme.BIRCH)


## Hex shows here, in the fight, on the slot it really lands on: the enemy's across from the Hexer.
func _slot_hex(event: Dictionary, animate: bool) -> void:
	var board: BoardView = board_for_side(Data.i(event, "side", 0))
	var slot: int = Data.i(event, "slot", 0)
	board.set_hex(slot, Data.i(event, "total", 0))
	if animate:
		_float_at(board.slot_global_center(slot), "Hex!", UiTheme.BIRCH)


func _mark_slot(mark: Dictionary) -> void:
	var board: BoardView = board_for_side(Data.i(mark, "side", 0))
	var slot: int = Data.i(mark, "slot", 0)
	if slot >= 0 and slot < board.slots.size():
		board.slots[slot].highlight = UiTheme.YARN


func _show_result() -> void:
	_clear_attack()
	_caption.visible = false
	_set_playing(false)
	var winner: int = model.winner
	var damage: int = model.damage
	var names: PackedStringArray = _log_text.side_names
	var loser: int = 1 - winner
	if winner < 0:
		_result_title.text = "Tie"
		_result_title.add_theme_color_override("font_color", UiTheme.INK)
		_result_text.text = (
			"Draw: each hero takes %d damage from the round toll." % damage
			if damage > 0
			else "Both boards fell. No damage either way."
		)
	else:
		var won: bool = winner == bottom_side
		_result_title.text = "Victory" if won else "Defeat"
		_result_title.add_theme_color_override(
			"font_color", UiTheme.MOSS if won else UiTheme.HEALTH
		)
		var cap_note: String = ""
		if model.damage_uncapped > damage:
			cap_note = "\n(%d before the cap)" % model.damage_uncapped
		_result_text.text = (
			"%s dealt %d damage to %s.%s"
			% [
				UiTheme.short_name(names[winner]),
				damage,
				UiTheme.short_name(names[loser]).replace("You", "you"),
				cap_note
			]
		)
	if model.round_toll > 0 and winner >= 0:
		_result_text.text += "\nIncludes round toll %d (before any cap)." % model.round_toll
	_result_panel.visible = true


func is_showing_result() -> bool:
	return _result_panel.visible


func _tween() -> Tween:
	var tween: Tween = create_tween()
	tween.set_speed_scale(speed)
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


## A big slip across the gap between the trays: "Start of Combat".
func _say(text: String, animate: bool) -> void:
	_caption.text = text
	_caption.visible = animate and not text.is_empty()
	if not _caption.visible:
		return
	_caption.size = _caption.get_minimum_size()
	var tray: BoardView = _boards[0]
	_caption.position = Vector2(
		tray.position.x + (tray.tray_size().x - _caption.size.x) / 2.0,
		tray.position.y + tray.tray_size().y + TRAY_GAP / 2.0 - _caption.size.y / 2.0
	)
	var tween: Tween = _tween()
	tween.tween_interval(0.6)
	tween.tween_callback(func() -> void: _caption.visible = false)


func _flash(uid: int, colour: Color, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card == null or not animate:
		return
	card.outline = colour
	var tween: Tween = _tween().bind_node(card)
	tween.tween_interval(0.45)
	tween.tween_callback(
		func() -> void:
			if is_instance_valid(card) and uid != _attacker_uid and uid != _defender_uid:
				card.outline = Color.TRANSPARENT
	)


func _shake(uid: int, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card == null or not animate or Settings.reduce_motion:
		return
	var tween: Tween = _tween()
	tween.tween_property(card, "rotation", 0.07, 0.05)
	tween.tween_property(card, "rotation", -0.07, 0.08)
	tween.tween_property(card, "rotation", 0.0, 0.05)


## A starburst with the number on the card that was hit: pops, holds, fades.
func _burst(uid: int, amount: int, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card == null or not animate:
		return
	var side: float = 150.0
	var burst: TextureRect = TextureRect.new()
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.texture = Icons.icon("burst", side)
	burst.size = Vector2(side, side)
	burst.pivot_offset = burst.size / 2.0
	var number: Label = UiTheme.number("−%d" % amount, 58, UiTheme.CREAM)
	number.add_theme_color_override("font_outline_color", UiTheme.INK)
	number.add_theme_constant_override("outline_size", 10)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.size = burst.size
	burst.add_child(number)
	_overlay.add_child(burst)
	var centre: Vector2 = (
		_overlay.get_global_transform().affine_inverse() * (card.get_global_rect().get_center())
	)
	burst.position = centre + Vector2(card.card_size.x * 0.38, -18.0) - burst.size / 2.0
	var tween: Tween = _tween()
	if not Settings.reduce_motion:
		burst.scale = Vector2(0.4, 0.4)
		(
			tween
			. tween_property(burst, "scale", Vector2.ONE, 0.12)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
	tween.tween_interval(0.3)
	tween.tween_property(burst, "modulate:a", 0.0, 0.15)
	tween.tween_callback(burst.queue_free)


## A chip that pops over the card and lifts away: a keyword firing, a stat change.
func _float_chip(uid: int, words: String, fill: Color, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card == null or not animate:
		return
	_float_at(card.get_global_rect().get_center() - Vector2(0, 40), words, fill)


func _float_at(global_point: Vector2, words: String, fill: Color) -> void:
	var chip: Label = UiTheme.head(words, UiTheme.FONT_BODY)
	chip.add_theme_stylebox_override("normal", UiTheme.slip_box(fill, 5, 12))
	_overlay.add_child(chip)
	chip.size = chip.get_minimum_size()
	var local: Vector2 = _overlay.get_global_transform().affine_inverse() * global_point
	var lower: float = _overlay.size.x - chip.size.x - 8.0
	chip.position = Vector2(clampf(local.x - chip.size.x / 2.0, 8.0, lower), local.y)
	var tween: Tween = _tween()
	tween.set_parallel(true)
	if not Settings.reduce_motion:
		tween.tween_property(chip, "position:y", chip.position.y - 46.0, 0.7)
	tween.tween_property(chip, "modulate:a", 0.0, 0.2).set_delay(0.5)
	tween.chain().tween_callback(chip.queue_free)


func _leaf_puff(global_point: Vector2) -> void:
	var local: Vector2 = _overlay.get_global_transform().affine_inverse() * global_point
	for i: int in DEATH_LEAVES:
		var leaf: TextureRect = TextureRect.new()
		leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		leaf.texture = Icons.icon("leaf", 44.0)
		leaf.size = Vector2(44, 44)
		leaf.pivot_offset = leaf.size / 2.0
		leaf.position = local - leaf.size / 2.0
		_overlay.add_child(leaf)
		var angle: float = TAU * i / DEATH_LEAVES + 0.4
		var far: Vector2 = leaf.position + Vector2(cos(angle), sin(angle) + 0.3) * 110.0
		var tween: Tween = _tween()
		tween.set_parallel(true)
		tween.tween_property(leaf, "position", far, 0.45).set_ease(Tween.EASE_OUT)
		tween.tween_property(leaf, "rotation", 2.4, 0.45)
		tween.tween_property(leaf, "modulate:a", 0.0, 0.2).set_delay(0.25)
		tween.chain().tween_callback(leaf.queue_free)
