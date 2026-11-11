extends Control
## Settings, opened over the menu or the game, in the mock's layout (docs/design-lab/r3/woodcraft
## settings): Back leaf, carved title, oak panels. Every change saves straight away.

signal closed
signal guide_requested

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const VolumeGroove := preload("res://src/ui/widgets/volume_groove.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const LatchButton := preload("res://src/ui/widgets/latch_button.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

const PANEL_TOP: float = 176.0
const PANEL_GAP: float = 24.0
const SIDE: float = 24.0
const PANEL_H: float = 470.0
const SOUND_H: float = 176.0
const DEV_TAPS: int = 7

var kin_latch: LatchButton
var motion_latch: LatchButton
## Tapped DEV_TAPS times running, it turns the testing tools on or off. No player is told of it.
var version_tap: Interactive
var speed_tokens: Array[TokenButton] = []
var opponent_buttons: Array[LeafButton] = []
var master_groove: VolumeGroove

var _back: LeafButton
var _plaque: WoodPanel
var _panels: Array[WoodPanel] = []
var _version: Label
var _taps: int = 0
var _rows: Array[Dictionary] = []
var _sound: WoodPanel
var _master_head: Label
var _tray: WoodPanel
var _opponents_head: Label


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	UiTheme.add_world(self, "recruit")
	_back = LeafButton.new()
	_back.flipped = true
	_back.colour = LeafButton.Colour.ACORN
	_back.set_face("Back")
	_back.pressed.connect(_close)
	add_child(_back)
	_plaque = WoodPanel.new(WoodPanel.Kind.PAINTED)
	add_child(_plaque)
	var title: Label = UiTheme.label("Settings", UiTheme.FONT_TITLE + 14, UiTheme.CREAM)
	title.add_theme_font_override("font", UiTheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.offset_bottom = -6.0
	_plaque.add_child(title)
	for i: int in 2:
		var panel: WoodPanel = WoodPanel.new(WoodPanel.Kind.PAINTED)
		add_child(panel)
		_panels.append(panel)
	_build_fights(_panels[0])
	_build_more(_panels[1])
	_sound = WoodPanel.new(WoodPanel.Kind.PAINTED)
	add_child(_sound)
	_build_sound(_sound)
	if Settings.field_mode_enabled:
		_tray = WoodPanel.new(WoodPanel.Kind.PAINTED)
		add_child(_tray)
		_build_opponents()
	resized.connect(_layout)
	ready.connect(_layout)


func _head(panel: WoodPanel, words: String, icon_name: String, y: float) -> void:
	var icon: TextureRect = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = Icons.icon(icon_name, 46.0)
	icon.position = Vector2(32, y)
	icon.size = Vector2(46, 46)
	panel.add_child(icon)
	var head: Label = UiTheme.burned(words, UiTheme.FONT_SMALL, UiTheme.CREAM)
	head.position = Vector2(90, y + 2.0)
	panel.add_child(head)


func _build_fights(panel: WoodPanel) -> void:
	_head(panel, "Combat speed", "sword", 26.0)
	for value: float in Settings.SPEEDS:
		var token: TokenButton = TokenButton.new("×%d" % int(value))
		token.lit = is_equal_approx(value, Settings.fight_speed)
		token.pressed.connect(_on_speed.bind(value))
		panel.add_child(token)
		speed_tokens.append(token)
	motion_latch = LatchButton.new()
	motion_latch.set_on(Settings.reduce_motion)
	motion_latch.toggled.connect(_on_motion)
	panel.add_child(motion_latch)
	_rows.append(
		_row(panel, motion_latch, "Reduce motion", "Flashes instead of lunges and shakes.")
	)


func _build_sound(panel: WoodPanel) -> void:
	_head(panel, "Sound", "speaker", 14.0)
	_master_head = UiTheme.head("Master", UiTheme.FONT_BODY + 4, UiTheme.CREAM)
	_master_head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(_master_head)
	master_groove = VolumeGroove.new()
	master_groove.value = round(Settings.master_volume * 100.0)
	master_groove.value_changed.connect(_on_master)
	# A click at the new level, so the player hears what they set.
	master_groove.drag_ended.connect(func(_changed: bool) -> void: Sfx.tap())
	panel.add_child(master_groove)


func _build_more(panel: WoodPanel) -> void:
	_head(panel, "Help", "gear", 26.0)
	var guide: LeafButton = LeafButton.new()
	guide.name = "Guide"
	guide.set_face("How to play")
	guide.pressed.connect(func() -> void: guide_requested.emit())
	panel.add_child(guide)
	kin_latch = LatchButton.new()
	kin_latch.set_on(Settings.ask_for_kin)
	kin_latch.toggled.connect(_on_kin)
	panel.add_child(kin_latch)
	_rows.append(
		_row(panel, kin_latch, "Ask for Kin", "2 gold: two units share your tribes; new games")
	)
	var words: String = _version_words()
	words += " (testing tools on)" if Settings.show_dev_panel else ""
	_version = UiTheme.label(words, UiTheme.FONT_SMALL, UiTheme.CREAM)
	_version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(_version)
	version_tap = Interactive.new()
	version_tap.tapped.connect(func(_zone: String, _index: int) -> void: _on_version_tapped())
	panel.add_child(version_tap)


func _build_opponents() -> void:
	_opponents_head = UiTheme.head("Opponents", UiTheme.FONT_BODY + 4, UiTheme.CREAM)
	_tray.add_child(_opponents_head)
	var labels: Array[String] = ["Bots", "Strong field"]
	for index: int in labels.size():
		var button := LeafButton.new()
		button.set_face(labels[index])
		button.name = "Bots" if index == 0 else "StrongField"
		button.pressed.connect(_on_opponents.bind("bots" if index == 0 else "field"))
		_tray.add_child(button)
		opponent_buttons.append(button)
	_refresh_opponents()


func _refresh_opponents() -> void:
	for index: int in opponent_buttons.size():
		var selected: bool = (index == 1) == (Settings.opponents == "field")
		opponent_buttons[index].colour = (
			LeafButton.Colour.MOSS if selected else LeafButton.Colour.BIRCH
		)


func _on_opponents(value: String) -> void:
	Settings.opponents = value
	_refresh_opponents()
	Settings.save()


func _row(panel: WoodPanel, latch: Control, words: String, note: String) -> Dictionary:
	var head: Label = UiTheme.head(words, UiTheme.FONT_BODY + 4, UiTheme.CREAM)
	panel.add_child(head)
	var sub: Label = UiTheme.label(note, UiTheme.FONT_SMALL, UiTheme.CREAM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(sub)
	return {"panel": panel, "latch": latch, "head": head, "sub": sub}


func _layout() -> void:
	var w: float = size.x
	var sound_y: float = PANEL_TOP + PANEL_H + 16.0
	var tray_y: float = sound_y + SOUND_H + 16.0
	# The cut portrait tray reserves no space. Center only the settings that actually exist.
	var content_h: float = tray_y + 162.0 + SIDE if _tray != null else sound_y + SOUND_H + SIDE
	var top: float = maxf(0.0, (size.y - content_h) / 2.0)
	_back.position = Vector2(SIDE + 12.0, top + 26.0)
	_back.size = Vector2(350, 124)
	_plaque.position = Vector2(412, top + 34.0)
	_plaque.size = Vector2(330, 110)
	var panel_w: float = (w - SIDE * 2.0 - PANEL_GAP) / 2.0
	var panel_h: float = PANEL_H
	_sound.position = Vector2(SIDE, top + sound_y)
	_sound.size = Vector2(w - SIDE * 2.0, SOUND_H)
	_layout_sound(_sound.size.x)
	if _tray != null:
		_tray.position = Vector2(SIDE, top + tray_y)
		_tray.size = Vector2(w - SIDE * 2.0, 162.0)
	if _opponents_head != null:
		_opponents_head.position = Vector2(32, 22)
		_opponents_head.size = Vector2(310, 56)
		var choice_w: float = minf(520.0, (_tray.size.x - 424.0) / 2.0)
		for index: int in opponent_buttons.size():
			opponent_buttons[index].position = Vector2(376.0 + index * (choice_w + 24.0), 20)
			opponent_buttons[index].size = Vector2(choice_w, 122)
	for i: int in _panels.size():
		_panels[i].position = Vector2(SIDE + i * (panel_w + PANEL_GAP), top + PANEL_TOP)
		_panels[i].size = Vector2(panel_w, panel_h)
	var token_w: float = 122.0
	for i: int in speed_tokens.size():
		speed_tokens[i].position = Vector2(32.0 + i * (token_w + 22.0), 100)
		speed_tokens[i].size = Vector2(token_w, token_w + 9.0)
	var guide: Control = _panels[1].get_node("Guide")
	var guide_w: float = minf(panel_w - 56.0, 520.0)
	guide.position = Vector2((panel_w - guide_w) / 2.0, 88)
	guide.size = Vector2(guide_w, 122)
	version_tap.position = Vector2(28, 344)
	version_tap.size = Vector2(panel_w - 56.0, 122)
	_version.position = Vector2(32, 400)
	_version.size = Vector2(panel_w - 64.0, 60)
	for row: Dictionary in _rows:
		_layout_row(row, panel_w, 218.0 if row["panel"] == _panels[1] else 280.0)


func _layout_sound(width: float) -> void:
	_master_head.position = Vector2(32, 62)
	_master_head.size = Vector2(150, 96)
	master_groove.position = Vector2(182, 62)
	master_groove.size = Vector2(width - 182.0 - 32.0, 96)


func _layout_row(row: Dictionary, panel_w: float, y: float) -> void:
	var latch: Control = row["latch"]
	var head: Control = row["head"]
	var sub: Control = row["sub"]
	latch.position = Vector2(panel_w - LatchButton.WIDTH - 28.0, y)
	latch.size = Vector2(LatchButton.WIDTH, 122)
	head.position = Vector2(32, y - 6.0)
	head.size = Vector2(panel_w - LatchButton.WIDTH - 72.0, 56)
	sub.position = Vector2(32, y + 44.0)
	sub.size = Vector2(panel_w - LatchButton.WIDTH - 72.0, 100)


func _on_speed(value: float) -> void:
	Settings.fight_speed = value
	for i: int in speed_tokens.size():
		speed_tokens[i].lit = is_equal_approx(Settings.SPEEDS[i], value)
	Settings.save()


func _on_master(value: float) -> void:
	Settings.master_volume = value / 100.0
	Sfx.apply_volumes()
	Settings.save()


func _on_motion(on: bool) -> void:
	Settings.reduce_motion = on
	Settings.save()


func _on_kin(on: bool) -> void:
	Settings.ask_for_kin = on
	Settings.save()


func _version_words() -> String:
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	return "Prototype" if version.is_empty() else "Prototype %s" % version


func _on_version_tapped() -> void:
	_taps += 1
	if _taps < DEV_TAPS:
		return
	_taps = 0
	Settings.show_dev_panel = not Settings.show_dev_panel
	Settings.save()
	_version.text = _version_words() + (" (testing tools on)" if Settings.show_dev_panel else "")


func _close() -> void:
	closed.emit()
	queue_free()
