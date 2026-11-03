extends Control
## Plays back one fight's event list (SPEC section 5) step by step: attacks with a short lunge,
## damage numbers, deaths, summons into slots and statuses, with play/pause, step, 1x/2x/4x,
## skip to the end and a scrolling log. Then the result and the damage dealt. It knows no rules:
## it only shows what the events say.

signal finished

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")

const CARD_WIDTH: float = 144.0
## Seconds each event type holds the screen at 1x.
const DURATIONS: Dictionary[String, float] = {
	"combat_start": 0.6,
	"phase": 0.9,
	"trigger": 0.6,
	"attack": 0.7,
	"damage": 0.55,
	"health_loss": 1.4,
	"status": 0.8,
	"stats": 0.6,
	"death": 0.6,
	"summon": 0.7,
	"skip": 0.8,
	"whistle": 0.9,
	"cancel": 0.8,
	"pass": 0.8,
	"slot_mark": 0.9,
	"combat_end": 0.3,
}
const SPEEDS: Array[float] = [1.0, 2.0, 4.0]

var model: CombatModel = CombatModel.new()
var events: Array = []
## Index of the next event to play.
var next_index: int = 0
var playing: bool = true
var speed: float = 1.0
## Which side is drawn at the bottom ("yours").
var bottom_side: int = 0

var _log_text: CombatLog = CombatLog.new()
var _boards: Array[BoardView] = []
var _cards: Dictionary[int, CardView] = {}
var _wait: float = 0.0
var _title: Label
var _caption: Label
var _log: RichTextLabel
var _detail: CardDetail
var _overlay: Control
var _play_button: Button
var _speed_buttons: Array[Button] = []
## Full-screen dimmer holding the centred result panel.
var _result_panel: ColorRect
var _result_title: Label
var _result_text: Label
var _tweens: Array[Tween] = []
## Cards fading out after a death; freed when their tween ends or playback is cut short.
var _dying: Array[CardView] = []


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = UiTheme.BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	margin.add_child(columns)
	columns.add_child(_build_arena())
	columns.add_child(_build_side())
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_build_result()


func _build_arena() -> VBoxContainer:
	var arena: VBoxContainer = VBoxContainer.new()
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 8)
	_title = UiTheme.label("", UiTheme.FONT_TITLE - 4)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena.add_child(_title)
	for i: int in 2:
		var holder: CenterContainer = CenterContainer.new()
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var board: BoardView = BoardView.new()
		holder.add_child(board)
		_boards.append(board)
		arena.add_child(holder)
		if i == 0:
			_caption = UiTheme.label("", UiTheme.FONT_TITLE - 2, UiTheme.SELECT)
			_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_caption.custom_minimum_size = Vector2(0, 46)
			_caption.add_theme_color_override("font_outline_color", UiTheme.INK)
			_caption.add_theme_constant_override("outline_size", 6)
			arena.add_child(_caption)
	arena.add_child(_build_controls())
	return arena


func _build_controls() -> HBoxContainer:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 12)
	_play_button = UiTheme.button("Pause", 150)
	_play_button.pressed.connect(toggle_play)
	bar.add_child(_play_button)
	var step: Button = UiTheme.button("Step", 120)
	step.pressed.connect(step_once)
	bar.add_child(step)
	for value: float in SPEEDS:
		var button: Button = UiTheme.button("%d×" % int(value), 90)
		button.toggle_mode = true
		button.button_pressed = is_equal_approx(value, speed)
		button.pressed.connect(set_speed.bind(value))
		bar.add_child(button)
		_speed_buttons.append(button)
	var skip: Button = UiTheme.button("Skip to end", 190)
	skip.pressed.connect(skip_to_end)
	bar.add_child(skip)
	return bar


func _build_side() -> VBoxContainer:
	var side: VBoxContainer = VBoxContainer.new()
	side.custom_minimum_size = Vector2(470, 0)
	side.add_theme_constant_override("separation", 10)
	side.add_child(UiTheme.label("Combat log", UiTheme.FONT_BODY, UiTheme.TEXT_DIM))
	var log_panel: PanelContainer = PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.selection_enabled = false
	_log.add_theme_font_size_override("normal_font_size", UiTheme.FONT_SMALL + 1)
	_log.add_theme_font_size_override("bold_font_size", UiTheme.FONT_SMALL + 1)
	log_panel.add_child(_log)
	_detail = CardDetail.new()
	_detail.set_card_width(200)
	_detail.show_empty("Hover or tap a unit to read it.")
	side.add_child(_detail)
	return side


func _build_result() -> void:
	_result_panel = ColorRect.new()
	_result_panel.color = Color(0, 0, 0, 0.45)
	_result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var centre: CenterContainer = CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_panel.add_child(centre)
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", UiTheme.flat_box(Color(UiTheme.PANEL, 0.97), UiTheme.GOLD, 4, 18)
	)
	panel.custom_minimum_size = Vector2(760, 320)
	centre.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	_result_title = UiTheme.label("", 64, UiTheme.GOLD)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_title)
	_result_text = UiTheme.label("", UiTheme.FONT_TITLE - 6)
	_result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_result_text)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	var replay: Button = UiTheme.button("Watch again", 220)
	replay.pressed.connect(restart)
	buttons.add_child(replay)
	var go_on: Button = UiTheme.button("Continue", 220)
	go_on.add_theme_stylebox_override("normal", UiTheme.flat_box(UiTheme.GOLD, UiTheme.INK, 3))
	go_on.pressed.connect(func() -> void: finished.emit())
	buttons.add_child(go_on)
	_result_panel.visible = false
	add_child(_result_panel)


## combat: {"events": [...], ...}; side_names[side]; bottom: the side drawn at the bottom.
func setup(combat: Dictionary, side_names: PackedStringArray, bottom: int, title: String) -> void:
	events = Data.a(combat, "events")
	bottom_side = clampi(bottom, 0, 1)
	_log_text.side_names = side_names
	_title.text = title
	# The enemy board is on top with its front row facing down toward yours.
	_boards[0].configure("enemy", CARD_WIDTH, false, 16.0)
	_boards[1].configure("own", CARD_WIDTH, true, 16.0)
	restart()


func board_for_side(side: int) -> BoardView:
	return _boards[1] if side == bottom_side else _boards[0]


func restart() -> void:
	_kill_tweens()
	model = CombatModel.new()
	for board: BoardView in _boards:
		board.clear_highlights()
		board.clear()
	_cards.clear()
	_log.clear()
	_caption.text = ""
	_result_panel.visible = false
	next_index = 0
	# A short pause first, so the boards are laid out before anything moves.
	_wait = 0.4
	playing = true
	_play_button.text = "Pause"


func toggle_play() -> void:
	if model.finished:
		return
	playing = not playing
	_play_button.text = "Pause" if playing else "Play"


func set_speed(value: float) -> void:
	speed = value
	for i: int in SPEEDS.size():
		_speed_buttons[i].button_pressed = is_equal_approx(SPEEDS[i], value)
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.set_speed_scale(speed)


func step_once() -> void:
	playing = false
	_play_button.text = "Play"
	if next_index < events.size():
		_play_event(Data.entry(events, next_index), true)
		next_index += 1


func skip_to_end() -> void:
	_kill_tweens()
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
	_wait = DURATIONS.get(str(event.get("type", "")), 0.5)


## Logs the event, applies it to the model, then shows it (animated or instantly).
func _play_event(event: Dictionary, animate: bool) -> void:
	_log.append_text(_log_text.describe(event, model) + "\n")
	var before: Dictionary = {}
	var target_uid: int = event.get("target", Data.i(event, "uid", -1))
	if model.units.has(target_uid):
		before = model.unit(target_uid).duplicate()
	model.apply(event)
	match str(event.get("type", "")):
		"combat_start":
			_sync_all()
		"phase":
			var phase_name: String = str(event.get("name", ""))
			_say("Start of Combat" if phase_name == "start_of_combat" else "Attack!")
		"trigger":
			var uid: int = Data.i(event, "uid", -1)
			_flash(uid, UiTheme.GOLD, animate)
			_float_text(uid, CombatLog.trigger_name(model, uid), UiTheme.GOLD, animate)
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
			var text: String = CombatLog.stat_delta_text(
				Data.i(event, "attack_delta", 0), Data.i(event, "health_delta", 0)
			)
			_float_text(uid, text, UiTheme.BUFF, animate)
		"death":
			_death(Data.i(event, "uid", -1), animate)
		"summon":
			_summon(event, animate)
		"skip":
			_float_text(
				Data.i(event, "uid", -1),
				"Skips (%s)" % str(event.get("reason", "")),
				UiTheme.TEXT_DIM,
				animate
			)
		"whistle":
			_float_text(Data.i(event, "uid", -1), "Whistle!", UiTheme.GOLD, animate)
			for uid: int in Data.a(event, "warned"):
				_float_text(uid, "Warned", UiTheme.status_colour("warned"), animate)
		"cancel":
			_float_text(Data.i(event, "uid", -1), "Attack cancelled", UiTheme.LOSS, animate)
		"pass":
			_say(
				(
					"%s can't attack: pass"
					% _log_text.side_names[clampi(Data.i(event, "side", 0), 0, 1)]
				)
			)
		"slot_mark":
			_slot_mark(event, animate)
		"combat_end":
			_show_result()


# --- syncing cards with the model ---------------------------------------------------------


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


func _make_card(uid: int, side: int, slot: int) -> CardView:
	var card: CardView = CardView.new()
	card.show_unit(model.unit(uid).duplicate(true), CardView.Mode.FULL)
	card.zone = "combat"
	card.index = uid
	card.tapped.connect(_on_card_tapped)
	card.hovered.connect(_on_card_hovered)
	board_for_side(side).place_card(card, slot)
	card.pivot_offset = card.card_size / 2.0
	_cards[uid] = card
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


func _on_card_tapped(_zone: String, uid: int) -> void:
	_show_detail(uid)


func _on_card_hovered(_zone: String, uid: int, inside: bool) -> void:
	if inside:
		_show_detail(uid)


func _show_detail(uid: int) -> void:
	var view: Dictionary = model.unit(uid)
	if not view.is_empty():
		_detail.show_unit(view)


# --- presentation --------------------------------------------------------------------------


func _attack(event: Dictionary, animate: bool) -> void:
	var attacker: CardView = _cards.get(Data.i(event, "attacker", -1))
	var defender: CardView = _cards.get(Data.i(event, "defender", -1))
	if attacker == null or defender == null:
		return
	defender.outline = UiTheme.DAMAGE
	attacker.outline = UiTheme.SELECT
	for uid: int in Data.a(event, "joiners"):
		var joiner: CardView = _cards.get(uid)
		if joiner != null:
			joiner.outline = UiTheme.SELECT
	if not animate:
		_clear_outlines()
		return
	var home: Vector2 = attacker.position
	var board: Control = attacker.get_parent() as Control
	var target_global: Vector2 = defender.get_global_rect().get_center()
	var target_local: Vector2 = board.get_global_transform().affine_inverse() * target_global
	var lunge: Vector2 = home.lerp(target_local - attacker.card_size / 2.0, 0.55)
	attacker.z_index = 10
	var tween: Tween = _tween()
	tween.tween_property(attacker, "position", lunge, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tween.tween_property(attacker, "position", home, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_callback(func() -> void: attacker.z_index = 0)


func _clear_outlines() -> void:
	for card: CardView in _cards.values():
		if is_instance_valid(card):
			card.outline = Color.TRANSPARENT


func _damage(event: Dictionary, animate: bool) -> void:
	var uid: int = Data.i(event, "target", -1)
	_sync_unit(uid)
	var amount: int = Data.i(event, "amount", 0)
	var kind: String = str(event.get("kind", "attack"))
	var text: String = "-%d" % amount
	if kind == "thorns":
		text += " thorns"
	var modifiers: Array = Data.a(event, "modifiers")
	if not modifiers.is_empty():
		text += " (%s)" % str(modifiers[0]).capitalize()
	_float_text(uid, text, UiTheme.DAMAGE, animate, 40)
	_shake(uid, animate)


func _health_loss(event: Dictionary, before: Dictionary, animate: bool) -> void:
	var uid: int = Data.i(event, "target", -1)
	_sync_unit(uid)
	var after: int = Data.i(event, "health_after", 0)
	var old: int = before.get("health", after + Data.i(event, "amount", 0))
	_flash(uid, UiTheme.NIGHTSHADE, animate)
	_float_text(uid, "½  %d → %d" % [old, after], UiTheme.NIGHTSHADE.lightened(0.6), animate, 54)
	_say(
		"Nightshade halves %s: %d → %d Health" % [model.unit_name(uid), old, after],
		UiTheme.NIGHTSHADE.lightened(0.45)
	)


func _status(event: Dictionary, animate: bool) -> void:
	var uid: int = Data.i(event, "target", -1)
	_sync_unit(uid)
	var key: String = str(event.get("status", ""))
	var on: bool = Data.b(event, "on", true)
	var label: String = UiTheme.status_label(key)
	_float_text(
		uid, ("+ " if on else "− ") + label, UiTheme.status_colour(key).lightened(0.3), animate
	)
	if on:
		_flash(uid, UiTheme.status_colour(key), animate)


func _death(uid: int, animate: bool) -> void:
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
	tween.tween_property(card, "modulate", Color(1, 0.3, 0.3, 0.0), 0.45)
	tween.tween_property(card, "scale", Vector2(0.6, 0.6), 0.45)
	tween.chain().tween_callback(card.queue_free)


func _summon(event: Dictionary, animate: bool) -> void:
	var view: Dictionary = Data.d(event, "unit")
	var uid: int = Data.i(view, "uid", -1)
	var card: CardView = _make_card(uid, Data.i(event, "side", 0), Data.i(event, "slot", 0))
	_clear_outlines()
	if animate:
		card.scale = Vector2(0.3, 0.3)
		card.modulate = Color(1, 1, 1, 0)
		var tween: Tween = _tween()
		tween.set_parallel(true)
		tween.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(
			Tween.EASE_OUT
		)
		tween.tween_property(card, "modulate", Color.WHITE, 0.25)
	_float_text(uid, "Summoned", UiTheme.BUFF, animate)


func _slot_mark(event: Dictionary, animate: bool) -> void:
	_mark_slot(event)
	var board: BoardView = board_for_side(Data.i(event, "side", 0))
	var slot: int = Data.i(event, "slot", 0)
	if animate:
		_float_at(
			board.slot_global_center(slot),
			"Marked (%d)" % Data.i(event, "damage", 0),
			UiTheme.DAMAGE,
			30
		)


func _mark_slot(mark: Dictionary) -> void:
	var board: BoardView = board_for_side(Data.i(mark, "side", 0))
	var slot: int = Data.i(mark, "slot", 0)
	if slot >= 0 and slot < board.slots.size():
		board.slots[slot].highlight = UiTheme.DAMAGE


func _show_result() -> void:
	_clear_outlines()
	playing = false
	_play_button.text = "Play"
	var winner: int = model.winner
	var damage: int = model.damage
	var names: PackedStringArray = _log_text.side_names
	var loser: int = 1 - winner
	if winner < 0:
		_result_title.text = "Tie"
		_result_title.add_theme_color_override("font_color", UiTheme.TIE)
		_result_text.text = "Both boards fell or stalled. No damage either way."
	else:
		var won: bool = winner == bottom_side
		_result_title.text = "Victory" if won else "Defeat"
		_result_title.add_theme_color_override("font_color", UiTheme.WIN if won else UiTheme.LOSS)
		var cap_note: String = ""
		if model.damage_uncapped > damage:
			cap_note = "\n(%d before the cap)" % model.damage_uncapped
		_result_text.text = (
			"%s dealt %d damage to %s.%s" % [names[winner], damage, names[loser], cap_note]
		)
	_say("")
	_result_panel.visible = true


func is_showing_result() -> bool:
	return _result_panel.visible


# --- small effects -------------------------------------------------------------------------


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


func _say(text: String, colour: Color = UiTheme.SELECT) -> void:
	_caption.text = text
	_caption.add_theme_color_override("font_color", colour)


func _flash(uid: int, colour: Color, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card == null or not animate:
		return
	card.outline = colour
	var tween: Tween = _tween()
	tween.tween_interval(0.5)
	tween.tween_callback(
		func() -> void:
			if is_instance_valid(card):
				card.outline = Color.TRANSPARENT
	)


func _shake(uid: int, animate: bool) -> void:
	var card: CardView = _cards.get(uid)
	if card == null or not animate:
		return
	var tween: Tween = _tween()
	tween.tween_property(card, "rotation", 0.06, 0.05)
	tween.tween_property(card, "rotation", -0.06, 0.08)
	tween.tween_property(card, "rotation", 0.0, 0.05)


func _float_text(uid: int, text: String, colour: Color, animate: bool, font_size: int = 28) -> void:
	var card: CardView = _cards.get(uid)
	if card == null or not animate:
		return
	_float_at(card.get_global_rect().get_center(), text, colour, font_size)


func _float_at(global_point: Vector2, text: String, colour: Color, font_size: int) -> void:
	var label: Label = UiTheme.label(text, font_size, colour)
	label.add_theme_color_override("font_outline_color", UiTheme.INK)
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(label)
	label.size = Vector2(320, font_size * 1.6)
	var local: Vector2 = _overlay.get_global_transform().affine_inverse() * global_point
	label.position = local - label.size / 2.0
	var tween: Tween = _tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 70.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.chain().tween_callback(label.queue_free)
