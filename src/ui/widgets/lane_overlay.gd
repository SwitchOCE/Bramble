extends Control
## Shared scout/fight language: reed links, gold paw marks and hunter links.
## Mire has no standing ground pill: tucked and moving faces must remain unobscured.
## Endpoints use labelled slots, so enemy B1 faces your B1 despite the staggered rows.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")
const REED := Color("b8d27a")
const PAW := Color("f6c963")
var boards: Array = []
var bindings: Dictionary = {"patches": [], "quarries": []}
## Fights keep only end-state marks: motion conveys their source and target.
var combat_mode: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 14


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _rect(side: int, slot: int) -> Rect2:
	var board: Control = boards[side]
	var slot_point: Vector2 = board.call("slot_position", slot)
	var point: Vector2 = (
		get_global_transform().affine_inverse() * (board.get_global_transform() * slot_point)
	)
	var pocket: Vector2 = board.get("pocket")
	return Rect2(point, pocket)


func _draw() -> void:
	if boards.size() != 2:
		return
	if not combat_mode:
		_draw_links()
	var drawn: Dictionary = {}
	for mark: Dictionary in bindings.get("quarries", []):
		var key: String = "%d:%d" % [Data.i(mark, "side"), Data.i(mark, "slot")]
		if not drawn.has(key):
			drawn[key] = true
			var rect: Rect2 = _rect(Data.i(mark, "side"), Data.i(mark, "slot"))
			paw(
				self,
				rect.position + Vector2(rect.size.x - 18.0, 24.0),
				15.0 if combat_mode else 22.0
			)


func _draw_links() -> void:
	for kind: String in ["patches", "quarries"]:
		for binding: Dictionary in bindings.get(kind, []):
			if not Data.b(binding, "live", true):
				continue
			var start: Rect2 = _rect(Data.i(binding, "from_side"), Data.i(binding, "from_slot"))
			var target: Rect2 = _rect(Data.i(binding, "side"), Data.i(binding, "slot"))
			var offset: float = -0.36 if kind == "patches" else 0.36
			var from: Vector2 = start.get_center() + Vector2(start.size.x * offset, 0)
			var to: Vector2 = target.get_center() + Vector2(target.size.x * offset, 0)
			var colour: Color = REED if kind == "patches" else PAW
			draw_line(from, to, Color(UiTheme.INK, 0.9), 7.0, true)
			draw_dashed_line(from, to, colour, 3.0, 10.0, true, true)


static func paw(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	canvas.draw_circle(at, radius + 3, UiTheme.INK, true, -1, true)
	canvas.draw_circle(at, radius, PAW, true, -1, true)
	canvas.draw_circle(at + Vector2(0, radius * 0.22), radius * 0.39, UiTheme.INK, true, -1, true)
	for delta: Vector2 in [
		Vector2(-0.51, -0.19), Vector2(-0.18, -0.52), Vector2(0.22, -0.52), Vector2(0.54, -0.16)
	]:
		canvas.draw_circle(at + delta * radius, radius * 0.18, UiTheme.INK, true, -1, true)
