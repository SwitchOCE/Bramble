extends Control
## Joined, non-interactive surfaces under the real game widgets.

const Surface := preload("res://src/ui/widgets/painted_surface.gd")


class Region:
	extends RefCounted
	var area: Rect2
	var material: Surface.Finish
	var depth: float

	func _init(bounds: Rect2, finish: Surface.Finish, lip: float) -> void:
		area = bounds
		material = finish
		depth = lip


var _regions: Array[Region] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func clear_regions() -> void:
	_regions.clear()
	queue_redraw()


func add_region(area: Rect2, finish: Surface.Finish, depth: float = 8.0) -> void:
	_regions.append(Region.new(area, finish, depth))
	queue_redraw()


func _draw() -> void:
	for region: Region in _regions:
		Surface.paint(self, region.area, region.depth, region.material)
