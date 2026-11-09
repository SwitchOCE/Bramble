extends Control
## Shared scout/fight language: brown ground patches, reed links, gold paw marks and hunter links.
## Endpoints use labelled slots, so enemy B1 faces your B1 despite the staggered rows.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")
const MUD := Color("68482f")
const REED := Color("b8d27a")
const PAW := Color("f6c963")
var boards: Array = []
var bindings: Dictionary = {"patches": [], "quarries": []}
var pack: Array[Dictionary] = []
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
	for patch: Dictionary in bindings.get("patches", []):
		if combat_mode and not Data.b(patch, "live", true):
			continue
		_draw_patch(Data.i(patch, "side"), Data.i(patch, "slot"))
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
	if not pack.is_empty() and not combat_mode:
		var bracket: Rect2 = _rect(Data.i(pack[0], "side"), Data.i(pack[0], "slot"))
		for member: Dictionary in pack:
			bracket = bracket.merge(_rect(Data.i(member, "side"), Data.i(member, "slot")))
		var y: float = bracket.position.y + 5.0
		draw_polyline(
			PackedVector2Array(
				[
					Vector2(bracket.position.x, y + 14),
					Vector2(bracket.position.x, y),
					Vector2(bracket.end.x, y),
					Vector2(bracket.end.x, y + 14)
				]
			),
			PAW,
			5.0,
			true
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


## A mark lives beyond the slot chip, and on a labelled back row above its pocket.
## That leaves both the name strip and the slot label readable.
func patch_rect(side: int, slot: int) -> Rect2:
	var rect: Rect2 = _rect(side, slot)
	var board: Control = boards[side]
	if combat_mode:
		return Rect2(rect.position + Vector2(5, rect.size.y - 9.0), Vector2(rect.size.x - 10, 18))
	if board.get("zone") == "scout":
		# Scout already puts the slot caption below the pocket: merge mud into it.
		return Rect2(
			rect.position + Vector2(-2, rect.size.y + 12.0), Vector2(rect.size.x + 4.0, 42)
		)
	var above: bool = board.get("with_labels") == true and slot >= 4
	var top: float = -44.0 if above else rect.size.y + 22.0
	return Rect2(rect.position + Vector2(5, top), Vector2(rect.size.x - 10.0, 38))


func _draw_patch(side: int, slot: int) -> void:
	var foot: Rect2 = patch_rect(side, slot)
	draw_style_box(UiTheme.flat_box(MUD, UiTheme.INK, 3, 20), foot)
	if combat_mode:
		return
	for fraction: float in [0.13, 0.85]:
		var at: Vector2 = Vector2(foot.position.x + foot.size.x * fraction, foot.position.y + 4)
		draw_line(at + Vector2(-3, 16), at + Vector2(-8, -7), REED, 3.0, true)
		draw_line(at + Vector2(3, 16), at + Vector2(6, -13), REED, 3.0, true)
	var word: String = "MIRE"
	var board: Control = boards[side]
	if board.get("zone") == "scout":
		word = "%s MIRE" % BoardGeometry.LABELS[slot]
	var font: Font = UiTheme.bold_font()
	var width: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.MIN_FONT).x
	draw_string(
		font,
		Vector2(foot.get_center().x - width / 2, foot.end.y - 7),
		word,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		UiTheme.MIN_FONT,
		UiTheme.CREAM
	)


static func paw(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	canvas.draw_circle(at, radius + 3, UiTheme.INK, true, -1, true)
	canvas.draw_circle(at, radius, PAW, true, -1, true)
	canvas.draw_circle(at + Vector2(0, radius * 0.22), radius * 0.39, UiTheme.INK, true, -1, true)
	for delta: Vector2 in [
		Vector2(-0.51, -0.19), Vector2(-0.18, -0.52), Vector2(0.22, -0.52), Vector2(0.54, -0.16)
	]:
		canvas.draw_circle(at + delta * radius, radius * 0.18, UiTheme.INK, true, -1, true)
