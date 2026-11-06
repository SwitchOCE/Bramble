extends Control
## Settings, opened over the menu or the game, in the mock's layout (docs/design-lab/r3/woodcraft
## settings): Back leaf, carved title, oak panels. Every change saves straight away.

signal closed
signal guide_requested

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const PegSlider := preload("res://src/ui/widgets/peg_slider.gd")
const LatchButton := preload("res://src/ui/widgets/latch_button.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

const PANEL_TOP: float = 176.0
const PANEL_GAP: float = 24.0
const SIDE: float = 24.0

var volume_slider: PegSlider
var motion_latch: LatchButton
var dev_latch: LatchButton
var speed_tokens: Array[TokenButton] = []

var _back: LeafButton
var _plaque: WoodPanel
var _saved: Label
var _panels: Array[WoodPanel] = []
var _volume_value: Label
var _rows: Array[Dictionary] = []


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
	for i: int in 3:
		var panel: WoodPanel = WoodPanel.new(WoodPanel.Kind.OAK)
		add_child(panel)
		_panels.append(panel)
	_build_sound(_panels[0])
	_build_fights(_panels[1])
	_build_more(_panels[2])
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


func _build_sound(panel: WoodPanel) -> void:
	_head(panel, "Sound", "speaker", 26.0)
	volume_slider = PegSlider.new()
	volume_slider.value = Settings.volume
	volume_slider.changed.connect(_on_volume)
	panel.add_child(volume_slider)
	_volume_value = UiTheme.number(str(Settings.volume), UiTheme.FONT_TITLE)
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_volume_value)
	var note: Label = UiTheme.label(
		"The game has no sound yet. This is how loud it will be.", UiTheme.FONT_SMALL, UiTheme.INK
	)
	note.name = "SoundNote"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(note)


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


func _build_more(panel: WoodPanel) -> void:
	_head(panel, "Help and testing", "gear", 26.0)
	var guide: LeafButton = LeafButton.new()
	guide.name = "Guide"
	guide.set_face("How to play")
	guide.pressed.connect(func() -> void: guide_requested.emit())
	panel.add_child(guide)
	dev_latch = LatchButton.new()
	dev_latch.set_on(Settings.show_dev_panel)
	dev_latch.toggled.connect(_on_dev)
	panel.add_child(dev_latch)
	_rows.append(_row(panel, dev_latch, "Dev panel", "and sandbox, for testing"))


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
	var panel_w: float = (w - SIDE * 2.0 - PANEL_GAP * 2.0) / 3.0
	var panel_h: float = 1056.0 - PANEL_TOP
	for i: int in _panels.size():
		_panels[i].position = Vector2(SIDE + i * (panel_w + PANEL_GAP), top + PANEL_TOP)
		_panels[i].size = Vector2(panel_w, panel_h)
	volume_slider.position = Vector2(32, 110)
	volume_slider.size = Vector2(panel_w - 170.0, 122)
	_volume_value.position = Vector2(panel_w - 130.0, 130)
	_volume_value.size = Vector2(100, 76)
	var note: Control = _panels[0].get_node("SoundNote")
	note.position = Vector2(32, 260)
	note.size = Vector2(panel_w - 64.0, 130)
	var token_w: float = 122.0
	for i: int in speed_tokens.size():
		speed_tokens[i].position = Vector2(32.0 + i * (token_w + 22.0), 100)
		speed_tokens[i].size = Vector2(token_w, token_w + 9.0)
	var guide: Control = _panels[2].get_node("Guide")
	guide.position = Vector2(28, 100)
	guide.size = Vector2(panel_w - 56.0, 136)
	for row: Dictionary in _rows:
		_layout_row(row, panel_w, 280.0)


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


func _on_volume(value: int) -> void:
	Settings.volume = value
	_volume_value.text = str(value)
	Settings.save()


func _on_speed(value: float) -> void:
	Settings.fight_speed = value
	for i: int in speed_tokens.size():
		speed_tokens[i].lit = is_equal_approx(Settings.SPEEDS[i], value)
	Settings.save()


func _on_motion(on: bool) -> void:
	Settings.reduce_motion = on
	Settings.save()


func _on_dev(on: bool) -> void:
	Settings.show_dev_panel = on
	Settings.save()


func _close() -> void:
	closed.emit()
	queue_free()
