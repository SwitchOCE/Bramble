class_name L1RefreshBeads
extends Control
## One bead per paid refresh at the current price, with the available ones filled from the left.

var step: Vector2i


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_step(value: Vector2i) -> void:
	step = value
	queue_redraw()


func _draw() -> void:
	var arc: float = L1Layout.number("shop.bead.radius")
	var radius: float = L1Layout.number("shop.bead.d") / 2.0
	var rim: float = L1Layout.number("shop.bead.rim")
	for i: int in step.x:
		var angle: float = PI + PI * float(i) / maxi(1, step.x - 1)
		var at: Vector2 = Vector2.from_angle(angle) * arc
		var lit: bool = i < step.y
		draw_circle(at, radius + rim, Color("15191a"), true, -1.0, true)
		draw_circle(at, radius, Color("a9741f") if lit else Color("1c2124"), true, -1.0, true)
		draw_circle(
			at, radius * 0.88, Color("f0c468") if lit else Color("4a5258"), true, -1.0, true
		)
		if lit:
			draw_circle(at + Vector2(-0.6, -0.8), radius * 0.55, Color("fff6d8"), true, -1.0, true)
