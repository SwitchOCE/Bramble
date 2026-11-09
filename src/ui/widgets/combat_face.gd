extends Control
## Wordless fight marks. A tile is their hit target; its reader supplies their meaning.
## Kept above the portrait so defence, targeting and current counters stack independently.

const Data := preload("res://src/ui/view_data.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const StatNumbers := preload("res://src/ui/stat_numbers.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const GLYPH: float = 44.0
const COUNTER_WIDTH: float = 64.0
const PALE: Color = Color("dcf0ed")

var glyph: TextureRect
var counter: Label
var counter_kind: String = ""
var glyph_kind: String = ""
var marked_keywords: PackedStringArray = []
var marked_statuses: PackedStringArray = []

var _view: Dictionary = {}
var _combat: bool = false
var _attack: Rect2
var _health: Rect2
var _counter_rect: Rect2


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph = TextureRect.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.size = Vector2.ONE * GLYPH
	glyph.pivot_offset = glyph.size / 2.0
	add_child(glyph)
	counter = UiTheme.number("", UiTheme.MIN_FONT, UiTheme.CREAM)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(counter)


func setup(
	view: Dictionary, tile_size: Vector2, in_combat: bool, attack: Rect2, health: Rect2
) -> void:
	_view = view
	size = tile_size
	_combat = in_combat
	_attack = attack
	_health = health
	marked_keywords.clear()
	marked_statuses.clear()
	for entry: Variant in Data.a(view, "statuses"):
		var key: String = str(entry)
		if entry is Dictionary:
			var status: Dictionary = entry
			key = Data.s(status, "status")
		if in_combat or key == "shield":
			marked_statuses.append(key)
	if (
		not in_combat
		and Data.a(view, "keywords").has("Shield")
		and not marked_statuses.has("shield")
	):
		marked_statuses.append("shield")
	if in_combat:
		for keyword: Variant in Data.a(view, "keywords"):
			if str(keyword) in ["Mire", "Quarry", "Swoop"]:
				marked_keywords.append(str(keyword))
		if Data.i(view, "quarry") > 0 and not marked_keywords.has("Quarry"):
			marked_keywords.append("Quarry")
		if Data.b(view, "mire_granted") and not marked_keywords.has("Mire"):
			marked_keywords.append("Mire")
	glyph_kind = trigger_kind(view) if in_combat else ""
	counter_kind = ""
	var count: String = ""
	if in_combat:
		var pip: Dictionary = counter_value(view)
		counter_kind = Data.s(pip, "kind")
		count = Data.s(pip, "number")
	glyph.visible = not glyph_kind.is_empty() and count.is_empty()
	if glyph.visible:
		glyph.texture = Icons.icon(glyph_kind, GLYPH)
	glyph.position = Vector2((size.x - GLYPH) / 2.0, size.y - GLYPH + 6.0)
	counter.visible = not count.is_empty()
	counter.text = count
	_counter_rect = Rect2((size.x - COUNTER_WIDTH) / 2.0, size.y - 48.0, COUNTER_WIDTH, 52.0)
	counter.position = _counter_rect.position + Vector2(0, 15)
	counter.size = Vector2(COUNTER_WIDTH, 37)
	counter.pivot_offset = counter.size / 2.0
	if counter.visible:
		StatNumbers.fit(counter, counter.size.x, UiTheme.MIN_FONT, int(count))
	queue_redraw()


## On-play-only cards deliberately have no resting trigger glyph.
static func trigger_kind(view: Dictionary) -> String:
	var words: String = Data.s(view, "text").to_lower()
	words = words.replace("when played", "").replace("when you play this", "")
	if words.contains("when this dies") or words.contains("when i die"):
		return "bones"
	for phrase: String in [
		"start of combat", "start of turn", "end of turn", "after ", "whenever ", "when ", "every "
	]:
		if words.contains(phrase):
			return "spark"
	return ""


## Current data only: combat snapshots do not expose recruit's stored Hex/ammo/Bitter values.
## Supporting those fields here lets a future view add them without reviving text slips.
static func counter_value(view: Dictionary) -> Dictionary:
	var held: Variant = view.get("held", 0)
	var count: int = CoreUtil.to_int(held)
	if held is Array:
		var inside: Array = held
		count = inside.size()
	if count > 0:
		return {"kind": "belly", "number": str(count)}
	for field: String in ["hex_amount", "hex_percent_amount", "ammo", "bitter", "recruit_bitter"]:
		if view.has(field) and not view[field] is Array:
			var value: int = Data.i(view, field)
			if value > 0 or field == "ammo":
				var kind: String = "hex" if field.begins_with("hex") else "acorn"
				if field.contains("bitter"):
					kind = "berry"
				return {"kind": kind, "number": str(value)}
	return {}


func _draw() -> void:
	var tile: Rect2 = Rect2(Vector2.ZERO, size)
	if "nightshade" in marked_statuses:
		draw_style_box(
			UiTheme.flat_box(Color(UiTheme.NIGHTSHADE, 0.14), Color.TRANSPARENT, 0, 18), tile
		)
		_draw_icon("berry", Rect2(_health.position + Vector2(-4, -12), Vector2(30, 30)))
	if "shell" in marked_statuses:
		draw_style_box(UiTheme.flat_box(Color.TRANSPARENT, PALE, 5, 18), tile.grow(-7))
	if "shield" in marked_statuses:
		draw_style_box(
			UiTheme.flat_box(Color(UiTheme.FROST, 0.08), Color(UiTheme.FROST, 0.95), 5, 38),
			tile.grow(9)
		)
		draw_arc(Vector2(size.x * 0.33, size.y * 0.26), 19, PI, PI * 1.55, 14, PALE, 4, true)
	if "waiting" in marked_statuses:
		_draw_waiting()
	if "warned" in marked_statuses:
		_draw_note(_attack.position + Vector2(_attack.size.x * 0.5, 0))
	if "first_bite" in marked_statuses:
		_draw_fang(_attack.position + Vector2(3, -4))
	if "Mire" in marked_keywords:
		_draw_reeds()
	if "Quarry" in marked_keywords:
		_draw_claw()
	if "Swoop" in marked_keywords:
		_draw_wing()
	if _combat and _view.has("kisses"):
		_draw_kisses()
	if counter.visible:
		_draw_counter()


func _draw_icon(key: String, rect: Rect2) -> void:
	draw_texture_rect(Icons.icon(key, rect.size.x), rect, false)


func _draw_reeds() -> void:
	var foot: Vector2 = Vector2(size.x * 0.26, size.y - 6)
	for index: int in 3:
		var root: Vector2 = foot + Vector2(index * 8, 0)
		var tip: Vector2 = root + Vector2(-4 + index * 3, -24 - index % 2 * 8)
		draw_line(root, tip, UiTheme.MOSS, 4, true)
		draw_line(tip, tip + Vector2(0, -8), UiTheme.CARVE, 6, true)


func _draw_claw() -> void:
	for index: int in 3:
		var start: Vector2 = Vector2(size.x - 10 - index * 8, 9)
		draw_line(start, start + Vector2(-6, 20), UiTheme.INK, 7, true)
		draw_line(start, start + Vector2(-6, 20), UiTheme.CREAM, 3, true)


func _draw_wing() -> void:
	var at: Vector2 = Vector2(9, 16)
	var points: PackedVector2Array = [
		at, at + Vector2(24, -3), at + Vector2(13, 8), at + Vector2(7, 20)
	]
	draw_colored_polygon(points, UiTheme.CREAM)
	draw_polyline(points, UiTheme.INK, 3, true)


func _draw_waiting() -> void:
	for index: int in 2:
		var center: Vector2 = Vector2(size.x * 0.45 + index * 22, 25 - index * 10)
		draw_arc(center, 8, 0.15, PI * 1.7, 18, PALE, 3, true)


func _draw_note(at: Vector2) -> void:
	draw_circle(at + Vector2(1, 2), 7, UiTheme.GILT)
	draw_line(at + Vector2(6, 0), at + Vector2(6, -20), UiTheme.INK, 4, true)
	draw_line(at + Vector2(6, -20), at + Vector2(17, -15), UiTheme.INK, 4, true)


func _draw_fang(at: Vector2) -> void:
	var points: PackedVector2Array = [at, at + Vector2(15, 0), at + Vector2(6, 22)]
	draw_colored_polygon(points, UiTheme.CREAM)
	draw_polyline(
		PackedVector2Array([points[0], points[1], points[2], points[0]]), UiTheme.INK, 2, true
	)


func _draw_kisses() -> void:
	var count: int = Data.i(_view, "kisses", Data.i(_view, "recruit_kisses"))
	for index: int in 3:
		var at: Vector2 = Vector2(size.x / 2.0 + (index - 1) * 22, 15)
		draw_circle(at, 8, UiTheme.INK)
		draw_circle(at, 5, UiTheme.HEALTH if index < count else UiTheme.CREAM)


func _draw_counter() -> void:
	draw_style_box(UiTheme.flat_box(UiTheme.INK, UiTheme.CREAM, 2, 15), _counter_rect)
	var icon_rect: Rect2 = Rect2(_counter_rect.position + Vector2(21, -1), Vector2(22, 22))
	match counter_kind:
		"belly":
			draw_arc(icon_rect.get_center(), 9, 0.0, TAU, 20, UiTheme.CREAM, 3, true)
			draw_line(
				icon_rect.position + Vector2(7, 2),
				icon_rect.position + Vector2(15, 2),
				UiTheme.INK,
				4
			)
		"hex":
			draw_arc(icon_rect.get_center(), 9, 0.0, TAU * 0.8, 20, UiTheme.NIGHTSHADE, 4, true)
			draw_circle(icon_rect.get_center(), 3, UiTheme.CREAM)
		_:
			_draw_icon(counter_kind, icon_rect)
