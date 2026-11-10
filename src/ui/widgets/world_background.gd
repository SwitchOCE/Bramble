extends Control
## One replaceable painting per phase; the dark near foliage stays behind all input and cards.

var backdrop_path: String = "res://assets/ui/world/recruit_backdrop.jpg"
var _backdrop: Texture2D
var _foliage: Texture2D = preload("res://assets/ui/world/foreground.png")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop = load(backdrop_path)
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if _backdrop == null:
		return
	var source: Vector2 = _backdrop.get_size()
	var ratio: float = maxf(size.x / source.x, size.y / source.y)
	var crop: Vector2 = size / ratio
	draw_texture_rect_region(
		_backdrop, Rect2(Vector2.ZERO, size), Rect2((source - crop) / 2.0, crop)
	)
	var corner: Vector2 = Vector2(minf(size.x * 0.23, 450.0), size.y * 0.45)
	draw_texture_rect(_foliage, Rect2(Vector2(0, size.y - corner.y), corner), false)
	draw_texture_rect(
		_foliage, Rect2(Vector2(size.x, size.y - corner.y), Vector2(-corner.x, corner.y)), false
	)
