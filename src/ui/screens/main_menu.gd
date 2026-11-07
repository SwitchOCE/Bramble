extends Control
## Title screen in the woodcraft look: the name carved on a plaque, a tray of woodland faces, your
## records, and leaf buttons. "Bramble" is a code name. New game opens the difficulty chooser.

## The player chose a difficulty ("easy", "normal", "hard").
signal play_requested(difficulty: String)
signal guide_requested
signal settings_requested
signal sandbox_requested
signal quit_requested

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const Records := preload("res://src/ui/records.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")

const LEAF_H: float = 136.0
const TITLE_SIZE: int = 190
## Folk who are really in the game, with their tribe's picture if a card ever goes.
const FACES: Array[Array] = [
	["mr_crumb", "Hedgerow folk"],
	["hedge_witch", "Fairies"],
	["alderman_dozey", "Hedgerow folk"],
	["belladonna", "Fairies"],
]

var _plaque: WoodPanel
var _title: Label
var _tray: WoodPanel
var _faces: Array[ArtFrame] = []
var _records: WoodPanel
var _record_lines: Array[Label] = []
var _leaves: Array[LeafButton] = []
var _chooser: Control


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiTheme.add_table(self)
	_plaque = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_plaque)
	_title = UiTheme.label("Bramble", TITLE_SIZE)
	_title.name = "Title"
	_title.add_theme_font_override("font", UiTheme.title_font())
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_plaque.add_child(_title)
	_tray = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_tray)
	for entry: Array in FACES:
		var face: ArtFrame = ArtFrame.new()
		face.texture = UiTheme.portrait_for(str(entry[0]), [entry[1]])
		face.radius = 18.0
		_tray.add_child(face)
		_faces.append(face)
	_records = WoodPanel.new(WoodPanel.Kind.PAPER)
	_records.nails = true
	add_child(_records)
	var head: Label = UiTheme.burned("Your records", UiTheme.FONT_SMALL, UiTheme.MUTE)
	head.name = "RecordsHead"
	_records.add_child(head)
	for id: String in Records.DIFFICULTIES:
		var line: Label = UiTheme.label("", UiTheme.FONT_BODY)
		line.text = "%s: %s" % [Records.TITLES[id], Records.summary(id)]
		_records.add_child(line)
		_record_lines.append(line)
	_add_leaf("New game", LeafButton.Colour.MOSS, _open_chooser)
	_add_leaf("How to play", LeafButton.Colour.BIRCH, func() -> void: guide_requested.emit())
	_add_leaf("Settings", LeafButton.Colour.BIRCH, func() -> void: settings_requested.emit())
	if Settings.show_dev_panel:
		_add_leaf("Sandbox", LeafButton.Colour.FROST, func() -> void: sandbox_requested.emit())
	_add_leaf("Quit", LeafButton.Colour.ACORN, func() -> void: quit_requested.emit())
	resized.connect(_layout)
	ready.connect(_layout)


func _add_leaf(words: String, colour: LeafButton.Colour, on_press: Callable) -> void:
	var leaf: LeafButton = LeafButton.new()
	leaf.name = words.replace(" ", "")
	leaf.colour = colour
	leaf.set_face(words)
	leaf.pressed.connect(on_press)
	add_child(leaf)
	_leaves.append(leaf)


func _layout() -> void:
	var w: float = size.x
	var top: float = maxf(0.0, (size.y - 1080.0) / 2.0)
	var leaf_w: float = 520.0
	var left_w: float = w - leaf_w - 120.0
	_plaque.position = Vector2(50, top + 36.0)
	_plaque.size = Vector2(left_w, 290)
	_title.position = Vector2.ZERO
	_title.size = _plaque.size - Vector2(0, 10)
	_tray.position = Vector2(50, top + 360.0)
	_tray.size = Vector2(left_w, 360)
	var count: int = _faces.size()
	var gap: float = 26.0
	var face_w: float = (left_w - 56.0 - gap * (count - 1)) / count
	var face_h: float = minf(face_w, 304.0)
	for i: int in count:
		_faces[i].position = Vector2(28.0 + i * (face_w + gap), 24.0)
		_faces[i].size = Vector2(face_w, face_h)
	_records.position = Vector2(50, top + 754.0)
	_records.size = Vector2(left_w, 270)
	var head: Control = _records.get_node("RecordsHead")
	head.position = Vector2(60, 16)
	var y: float = 72.0
	for line: Label in _record_lines:
		line.position = Vector2(40, y)
		line.size = Vector2(left_w - 80.0, 56)
		y += 58.0
	var leaf_y: float = top + (1080.0 - _leaves.size() * (LEAF_H + 26.0)) / 2.0
	for leaf: LeafButton in _leaves:
		leaf.position = Vector2(w - leaf_w - 40.0, leaf_y)
		leaf.size = Vector2(leaf_w, LEAF_H)
		leaf_y += LEAF_H + 26.0
	if _chooser != null:
		_chooser.size = size


## Pick a difficulty: your best at each sits right under its leaf.
func _open_chooser() -> void:
	if _chooser != null:
		return
	_chooser = Control.new()
	_chooser.mouse_filter = Control.MOUSE_FILTER_STOP
	_chooser.size = size
	_chooser.z_index = 30
	add_child(_chooser)
	var shade: ColorRect = ColorRect.new()
	shade.color = UiTheme.SHADE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chooser.add_child(shade)
	var panel_size: Vector2 = Vector2(1420, 620)
	var panel: WoodPanel = WoodPanel.new(WoodPanel.Kind.OAK)
	panel.position = (size - panel_size) / 2.0
	panel.size = panel_size
	_chooser.add_child(panel)
	var title: Label = UiTheme.head("How hard a game?", UiTheme.FONT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 26)
	title.size = Vector2(panel_size.x, 80)
	panel.add_child(title)
	var x: float = 40.0
	for id: String in Records.DIFFICULTIES:
		var leaf: LeafButton = LeafButton.new()
		leaf.colour = LeafButton.Colour.MOSS if id == "normal" else LeafButton.Colour.BIRCH
		leaf.set_face(Records.TITLES[id])
		leaf.position = Vector2(x, 140)
		leaf.size = Vector2(430, 160)
		leaf.pressed.connect(_choose.bind(id))
		panel.add_child(leaf)
		var best: Label = UiTheme.label(Records.summary(id), UiTheme.FONT_SMALL)
		best.add_theme_font_override("font", UiTheme.bold_font())
		best.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.BIRCH, 4, 12))
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		best.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		best.position = Vector2(x + 30.0, 320)
		best.size = Vector2(370, 54)
		panel.add_child(best)
		x += 450.0
	var back: LeafButton = LeafButton.new()
	back.flipped = true
	back.colour = LeafButton.Colour.ACORN
	back.set_face("Back")
	back.position = Vector2((panel_size.x - 360.0) / 2.0, 430)
	back.size = Vector2(360, 136)
	back.pressed.connect(_close_chooser)
	panel.add_child(back)


func _close_chooser() -> void:
	if _chooser != null:
		_chooser.queue_free()
		_chooser = null


func _choose(id: String) -> void:
	_close_chooser()
	play_requested.emit(id)
