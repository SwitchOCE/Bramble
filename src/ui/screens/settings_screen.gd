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
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")

const PANEL_TOP: float = 176.0
const PANEL_GAP: float = 24.0
const SIDE: float = 24.0
const PANEL_H: float = 470.0
const SOUND_H: float = 176.0
const DEV_TAPS: int = 7
const FACES: PackedStringArray = [
	"Hedgerow folk", "Fairies", "Oozes", "Birds", "Hunters", "Bog folk"
]

var motion_latch: LatchButton
## Tapped DEV_TAPS times running, it turns the testing tools on or off. No player is told of it.
var version_tap: Interactive
var speed_tokens: Array[TokenButton] = []
var master_groove: VolumeGroove
var effects_groove: VolumeGroove

var _back: LeafButton
var _plaque: WoodPanel
var _saved: Label
var _panels: Array[WoodPanel] = []
var _version: Label
var _taps: int = 0
var _rows: Array[Dictionary] = []
var _sound: WoodPanel
var _sound_rows: Array[Dictionary] = []
var _tray: WoodPanel
var _faces: Array[ArtFrame] = []


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	UiTheme.add_table(self)
	_back = LeafButton.new()
	_back.flipped = true
	_back.colour = LeafButton.Colour.ACORN
	_back.set_face("Back")
	_back.pressed.connect(_close)
	add_child(_back)
	_plaque = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_plaque)
	var title: Label = UiTheme.label("Settings", UiTheme.FONT_TITLE + 14)
	title.add_theme_font_override("font", UiTheme.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.offset_bottom = -6.0
	_plaque.add_child(title)
	_saved = UiTheme.label("Changes save as you make them.", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_saved.add_theme_font_override("font", UiTheme.bold_font())
	_saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_saved)
	for i: int in 2:
		var panel: WoodPanel = WoodPanel.new(WoodPanel.Kind.OAK)
		add_child(panel)
		_panels.append(panel)
	_build_fights(_panels[0])
	_build_more(_panels[1])
	_sound = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_sound)
	_build_sound(_sound)
	_tray = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_tray)
	for tribe: String in FACES:
		var face: ArtFrame = ArtFrame.new()
		face.texture = UiTheme.portrait([tribe])
		face.radius = 18.0
		_tray.add_child(face)
		_faces.append(face)
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
	var head: Label = UiTheme.burned(words, UiTheme.FONT_SMALL)
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
	_rows.append(_row(panel, motion_latch, "Reduce motion", "no lunges, shakes or leaves"))


func _build_sound(panel: WoodPanel) -> void:
	_head(panel, "Sound", "speaker", 14.0)
	master_groove = _volume_row(panel, "Master", Settings.master_volume)
	master_groove.value_changed.connect(_on_master)
	effects_groove = _volume_row(panel, "Effects", Settings.effects_volume)
	effects_groove.value_changed.connect(_on_effects)


func _volume_row(panel: WoodPanel, words: String, volume: float) -> VolumeGroove:
	var head: Label = UiTheme.head(words, UiTheme.FONT_BODY + 4)
	head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(head)
	var groove: VolumeGroove = VolumeGroove.new()
	groove.value = round(volume * 100.0)
	# A click at the new level, so the player hears what they set.
	groove.drag_ended.connect(func(_changed: bool) -> void: Sfx.tap())
	panel.add_child(groove)
	_sound_rows.append({"head": head, "groove": groove})
	return groove


func _build_more(panel: WoodPanel) -> void:
	_head(panel, "Help", "gear", 26.0)
	var guide: LeafButton = LeafButton.new()
	guide.name = "Guide"
	guide.set_face("How to play")
	guide.pressed.connect(func() -> void: guide_requested.emit())
	panel.add_child(guide)
	var words: String = _version_words()
	words += " (testing tools on)" if Settings.show_dev_panel else ""
	_version = UiTheme.label(words, UiTheme.FONT_SMALL, UiTheme.INK)
	_version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(_version)
	version_tap = Interactive.new()
	version_tap.tapped.connect(func(_zone: String, _index: int) -> void: _on_version_tapped())
	panel.add_child(version_tap)


func _row(panel: WoodPanel, latch: Control, words: String, note: String) -> Dictionary:
	var head: Label = UiTheme.head(words, UiTheme.FONT_BODY + 4)
	panel.add_child(head)
	var sub: Label = UiTheme.label(note, UiTheme.FONT_SMALL)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(sub)
	return {"panel": panel, "latch": latch, "head": head, "sub": sub}


func _layout() -> void:
	var w: float = size.x
	var top: float = maxf(0.0, (size.y - 1080.0) / 2.0)
	_back.position = Vector2(SIDE + 12.0, top + 32.0)
	_back.size = Vector2(350, 112)
	_plaque.position = Vector2(412, top + 34.0)
	_plaque.size = Vector2(330, 110)
	_saved.position = Vector2(w - SIDE - 560.0, top + 62.0)
	_saved.size = Vector2(560, 50)
	var panel_w: float = (w - SIDE * 2.0 - PANEL_GAP) / 2.0
	var panel_h: float = PANEL_H
	var sound_y: float = PANEL_TOP + PANEL_H + 16.0
	_sound.position = Vector2(SIDE, top + sound_y)
	_sound.size = Vector2(w - SIDE * 2.0, SOUND_H)
	_layout_sound(_sound.size.x)
	var tray_y: float = sound_y + SOUND_H + 16.0
	_tray.position = Vector2(SIDE, top + tray_y)
	_tray.size = Vector2(w - SIDE * 2.0, 1056.0 - tray_y)
	var gap: float = 22.0
	var face_w: float = minf(_tray.size.y - 50.0, (_tray.size.x - gap * 5.0 - 40.0) / 6.0)
	var row_w: float = face_w * 6.0 + gap * 5.0
	for i: int in _faces.size():
		_faces[i].position = Vector2((_tray.size.x - row_w) / 2.0 + i * (face_w + gap), 18.0)
		_faces[i].size = Vector2(face_w, face_w)
	for i: int in _panels.size():
		_panels[i].position = Vector2(SIDE + i * (panel_w + PANEL_GAP), top + PANEL_TOP)
		_panels[i].size = Vector2(panel_w, panel_h)
	var token_w: float = 122.0
	for i: int in speed_tokens.size():
		speed_tokens[i].position = Vector2(32.0 + i * (token_w + 22.0), 100)
		speed_tokens[i].size = Vector2(token_w, token_w + 9.0)
	var guide: Control = _panels[1].get_node("Guide")
	guide.position = Vector2(28, 100)
	guide.size = Vector2(panel_w - 56.0, 136)
	version_tap.position = Vector2(28, 270)
	version_tap.size = Vector2(panel_w - 56.0, 122)
	_version.position = Vector2(32, 270)
	_version.size = Vector2(panel_w - 64.0, 122)
	for row: Dictionary in _rows:
		_layout_row(row, panel_w, 280.0)


func _layout_sound(width: float) -> void:
	var row_w: float = (width - 64.0 - 40.0) / 2.0
	for i: int in _sound_rows.size():
		var head: Control = _sound_rows[i]["head"]
		var groove: Control = _sound_rows[i]["groove"]
		var x: float = 32.0 + i * (row_w + 40.0)
		head.position = Vector2(x, 62.0)
		head.size = Vector2(150, 96)
		groove.position = Vector2(x + 150.0, 62.0)
		groove.size = Vector2(row_w - 150.0, 96)


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


func _on_effects(value: float) -> void:
	Settings.effects_volume = value / 100.0
	Sfx.apply_volumes()
	Settings.save()


func _on_motion(on: bool) -> void:
	Settings.reduce_motion = on
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
