class_name L1RefreshBeads
extends Control
## One bead per paid refresh at the current price, with the available ones filled from the left;
## each lit bead gives off a small warm light (buy-screen-l1.md §9, S4).

var step: Vector2i


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_step(value: Vector2i) -> void:
	step = value
	for old: Node in get_children():
		remove_child(old)
		old.queue_free()
	var d: float = L1Layout.number("shop.bead.d") + 2.0 * L1Layout.number("shop.bead.rim")
	for i: int in mini(step.y, step.x):
		var light: L1Light = L1Light.make(
			L1Light.Shape.CIRCLE,
			Rect2(_bead_at(i) - Vector2.ONE * d / 2.0, Vector2.ONE * d),
			L1Layout.colour("light.bead.light_colour"),
			"BeadLight_%d" % i
		)
		light.show_behind_parent = true
		light.glow(
			Vector3(0.0, L1Layout.number("light.bead.blur"), L1Layout.number("light.bead.alpha"))
		)
		light.blend(L1Layout.number("light.bead.additive"))
		add_child(light)
	queue_redraw()


func _bead_at(i: int) -> Vector2:
	var angle: float = PI + PI * float(i) / maxi(1, step.x - 1)
	return Vector2.from_angle(angle) * L1Layout.number("shop.bead.radius")


func _draw() -> void:
	var radius: float = L1Layout.number("shop.bead.d") / 2.0
	var rim: float = L1Layout.number("shop.bead.rim")
	for i: int in step.x:
		var at: Vector2 = _bead_at(i)
		var lit: bool = i < step.y
		draw_circle(at, radius + rim, Color("15191a"), true, -1.0, true)
		draw_circle(at, radius, Color("a9741f") if lit else Color("1c2124"), true, -1.0, true)
		draw_circle(
			at, radius * 0.88, Color("f0c468") if lit else Color("4a5258"), true, -1.0, true
		)
		if lit:
			draw_circle(at + Vector2(-0.6, -0.8), radius * 0.55, Color("fff6d8"), true, -1.0, true)
