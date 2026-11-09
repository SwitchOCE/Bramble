extends Control
## Earned tribe bonuses, named on screen and shown on their tribe portraits.

const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const StatNumbers := preload("res://src/ui/stat_numbers.gd")

const HEIGHT: float = 40.0
const WIDTH: float = 152.0
const GAP: float = 16.0
const CAPTION_WIDTH: float = 184.0
const ENGINE_WIDTH: float = 240.0

var bonuses: Dictionary = {}
var tribes: Array = []
var chips: Array[Control] = []
var _caption: Label
var _engine: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption = UiTheme.head("Tribe bonus", UiTheme.FONT_SMALL)
	_caption.name = "Caption"
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.visible = false
	add_child(_caption)
	resized.connect(_place)


func show_bonuses(lobby: Array, values: Dictionary) -> void:
	_engine = false
	tribes.clear()
	bonuses = values.duplicate()
	for child: Control in chips:
		remove_child(child)
		child.queue_free()
	chips.clear()
	for value: Variant in lobby:
		if Data.i(bonuses, str(value)) > 0:
			tribes.append(value)
	_caption.visible = not tribes.is_empty()
	for value: Variant in tribes:
		var tribe: String = str(value)
		var bonus: int = Data.i(bonuses, tribe)
		var button: Panel = Panel.new()
		button.name = tribe.replace(" ", "") + "Bonus"
		button.tooltip_text = "%s tribe bonus: +%d/+%d." % [tribe, bonus, bonus]
		button.add_theme_stylebox_override(
			"panel", UiTheme.flat_box(UiTheme.BIRCH, UiTheme.INK, 2, 20)
		)

		add_child(button)
		chips.append(button)
		var icon: ArtFrame = ArtFrame.new()
		icon.texture = UiTheme.portrait([tribe])
		icon.radius = 18
		icon.line = 2
		icon.position = Vector2(2, 2)
		icon.size = Vector2(36, 36)
		button.add_child(icon)
		var label: Label = UiTheme.number("+%d/+%d" % [bonus, bonus], UiTheme.FONT_SMALL)
		label.name = "Bonus"
		label.position = Vector2(42, 0)
		label.size = Vector2(WIDTH - 46, HEIGHT)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
	_place()


## Permanent Ring size and the shared Midsummer clock sit beside the earned tribe chips.
func show_engine(state: Dictionary) -> void:
	_show_bog_toll(state)
	if not state.has("ring_size"):
		return
	var size_value: float = Data.f(state, "ring_size", 1.0)
	var has_rings: bool = false
	for entries: Variant in Data.a(state, "slot_effects"):
		for effect: Variant in entries:
			if effect is Dictionary:
				var entry: Dictionary = effect
				if Data.s(entry, "name") == "Ring":
					has_rings = true
	if not has_rings and not Data.a(state, "lobby_tribes").has("Fairies"):
		return
	_engine = true
	var exact: String = String.num(size_value, 4)
	var shown: String = exact
	if size_value >= 1000.0:
		shown = StatNumbers.compact(roundi(size_value), 1, true)
	_engine_chip("RingSize", "Ring size " + shown, "Each Ring gives +%s/+%s." % [exact, exact])
	var left: int = Data.i(state, "midsummer_left")
	if left > 0:
		_engine_chip(
			"Midsummer",
			"Midsummer %d" % left,
			"Midsummer in %d End of Turns: your Ring size grows." % left
		)
	_place()


## The Bog portrait carries its earned number in the existing tribe-chip strip.
func _show_bog_toll(state: Dictionary) -> void:
	if not state.has("bog_toll") or not Data.a(state, "lobby_tribes").has("Bog folk"):
		return
	var chip: Control = get_node_or_null("BogfolkBonus") as Control
	if chip == null:
		var lobby: Array = Data.a(state, "lobby_tribes")
		var original: Dictionary = bonuses.duplicate()
		var values: Dictionary = bonuses.duplicate()
		values["Bog folk"] = 1
		show_bonuses(lobby, values)
		bonuses = original
		chip = get_node("BogfolkBonus") as Control
	var label: Label = chip.get_node("Bonus") as Label
	var toll: int = Data.i(state, "bog_toll")
	StatNumbers.fit(label, WIDTH - 46, 31, toll)
	chip.tooltip_text = (
		"Bog Toll: %s. Attack taken by your Bitter in the last fight." % StatNumbers.exact(toll)
	)
	_engine = true
	_place()


func _engine_chip(chip_name: String, words: String, note: String) -> void:
	var panel := Panel.new()
	panel.name = chip_name
	panel.tooltip_text = note
	panel.add_theme_stylebox_override("panel", UiTheme.flat_box(UiTheme.BIRCH, UiTheme.INK, 2, 20))
	panel.set_meta("chip_width", ENGINE_WIDTH)
	add_child(panel)
	chips.append(panel)
	tribes.append(chip_name)
	var label: Label = UiTheme.number(words, UiTheme.FONT_SMALL)
	label.name = "Engine"
	label.position = Vector2(8, 0)
	label.size = Vector2(ENGINE_WIDTH - 16.0, HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)


func _place() -> void:
	var chips_width: float = 0.0
	for chip: Control in chips:
		var width: float = chip.get_meta("chip_width", WIDTH)
		chips_width += width
	var captioned: bool = (
		not tribes.is_empty()
		and not _engine
		and size.x >= CAPTION_WIDTH + GAP + chips_width + GAP * (chips.size() - 1)
	)
	_caption.visible = captioned
	var start: float = CAPTION_WIDTH + GAP if captioned else 0.0
	var gap: float = minf(
		GAP, maxf(0.0, (size.x - start - chips_width) / maxf(chips.size() - 1, 1))
	)
	_caption.position = Vector2.ZERO
	_caption.size = Vector2(CAPTION_WIDTH, HEIGHT)
	var cursor: float = start
	for chip: Control in chips:
		var width: float = chip.get_meta("chip_width", WIDTH)
		chip.position = Vector2(cursor, 0)
		chip.size = Vector2(width, HEIGHT)
		cursor += width + gap
