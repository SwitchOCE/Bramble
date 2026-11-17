class_name GlassDuplicateGlow
extends Control
## Brief 4. Rim light behind the frame, independent of hover, drag and target lighting.
## Look/motion numbers are kept here; A is selected, B stays available for the review film.

const SELECTED: int = 0
const PERIODS: Array[float] = [2.8, 1.4]
const FLOORS: Array[float] = [0.78, 0.48]
const MATCH_LAYERS: Array[Dictionary] = [
	{"blur": 4.0, "colour": Color("fff3c4")},
	{"blur": 12.0, "colour": Color("ffe296d9")},
]
const TRIPLE_LAYERS: Array[Dictionary] = [
	{"blur": 4.0, "colour": Color("fff6c8")},
	{"blur": 12.0, "colour": Color("ffc23a")},
	{"blur": 26.0, "colour": Color("ff9614f2")},
]

var mark: int = RecruitDuplicates.Mark.NONE
var candidate: int = SELECTED
var _layers: Array[Control] = []


static func apply(card: GlassCard, value: int) -> GlassDuplicateGlow:
	var glow: GlassDuplicateGlow = card.get_node_or_null("DuplicateGlow")
	if glow == null and value != RecruitDuplicates.Mark.NONE:
		glow = GlassDuplicateGlow.new()
		glow.name = "DuplicateGlow"
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.show_behind_parent = true
		card.add_child(glow)
	if glow != null:
		glow._set_mark(card, value)
	return glow


func _set_mark(card: GlassCard, value: int) -> void:
	visible = value != RecruitDuplicates.Mark.NONE
	if mark == value:
		return
	mark = value
	for layer: Control in _layers:
		remove_child(layer)
		layer.queue_free()
	_layers.clear()
	if not visible:
		return
	var specs: Array[Dictionary] = (
		TRIPLE_LAYERS if mark == RecruitDuplicates.Mark.TRIPLE else MATCH_LAYERS
	)
	for i: int in range(specs.size() - 1, -1, -1):
		var layer: Control = Control.new()
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var spec: Dictionary = specs[i]
		var shadow: Dictionary = {"x": 0.0, "y": 0.0, "blur": spec.blur, "colour": spec.colour}
		layer.draw.connect(func() -> void: card._draw_shadow(layer, shadow))
		add_child(layer)
		_layers.append(layer)


## Shared screen time keeps the shop, board and hand breathing together, including after redraws.
## Match stays steady; a triple never goes dark. Delta time also works with the 60 fps movie writer.
func set_phase(seconds: float) -> void:
	var alpha: float = 1.0
	if mark == RecruitDuplicates.Mark.TRIPLE:
		var wave: float = (1.0 + cos(TAU * seconds / PERIODS[candidate])) / 2.0
		alpha = lerpf(FLOORS[candidate], 1.0, wave)
	modulate.a = alpha
