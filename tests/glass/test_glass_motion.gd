extends GutTest
## GlassMotion copies the anim-recruit prototypes' easing (engine.js): CSS cubic-bezier curves,
## Web Animations keyframes on an eased run, and fly()'s arc and lean.


func test_bezier_curves_meet_their_ends_and_rise() -> void:
	for curve: Vector4 in [GlassMotion.OUT, GlassMotion.INOUT, GlassMotion.IN, GlassMotion.LINEAR]:
		assert_eq(GlassMotion.bezier(curve, 0.0), 0.0)
		assert_eq(GlassMotion.bezier(curve, 1.0), 1.0)
		var last: float = 0.0
		for i: int in range(1, 20):
			var y: float = GlassMotion.bezier(curve, i / 20.0)
			assert_gt(y, last, "rises")
			last = y


func test_bezier_matches_the_css_curve() -> void:
	# cubic-bezier(.2,.8,.2,1) at x = 0.3, against a bisection of the same curve
	var x: float = 0.3
	var lo: float = 0.0
	var hi: float = 1.0
	for i: int in 60:
		var s: float = (lo + hi) / 2.0
		var r: float = 1.0 - s
		var at: float = 3.0 * r * r * s * 0.2 + 3.0 * r * s * s * 0.2 + s * s * s
		if at < x:
			lo = s
		else:
			hi = s
	var s2: float = (lo + hi) / 2.0
	var r2: float = 1.0 - s2
	var want: float = 3.0 * r2 * r2 * s2 * 0.8 + 3.0 * r2 * s2 * s2 + s2 * s2 * s2
	assert_almost_eq(GlassMotion.bezier(GlassMotion.OUT, x), want, 1e-4)
	assert_almost_eq(GlassMotion.bezier(GlassMotion.LINEAR, 0.37), 0.37, 1e-6)


func test_keyframes_join_neighbours_in_a_straight_line() -> void:
	var steps: Array = [[0.0, 0.0], [0.25, 1.0], [1.0, 0.0]]
	var early: float = GlassMotion.keyframes(steps, 0.125)
	var late: float = GlassMotion.keyframes(steps, 0.625)
	assert_almost_eq(early, 0.5, 1e-6)
	assert_almost_eq(late, 0.5, 1e-6)
	var a: Dictionary = GlassMotion.pose(Vector2(0, 0), 0.0, 1.0)
	var b: Dictionary = GlassMotion.pose(Vector2(100, 40), 10.0, 2.0)
	var mid: Dictionary = GlassMotion.keyframes([[0.0, a], [1.0, b]], 0.5)
	var at: Vector2 = mid["at"]
	var turn: float = mid["turn"]
	var size: float = mid["scale"]
	assert_eq(at, Vector2(50, 20))
	assert_almost_eq(turn, 5.0, 1e-6)
	assert_almost_eq(size, 1.5, 1e-6)


func test_a_flight_arcs_by_its_lift_and_leans_at_its_middle() -> void:
	var a: Dictionary = GlassMotion.pose(Vector2(0, 100))
	var b: Dictionary = GlassMotion.pose(Vector2(200, 100))
	var mid: Dictionary = GlassMotion.flight(a, b, 0.5, "inout", 120.0, -6.0)
	var mid_at: Vector2 = mid["at"]
	var mid_turn: float = mid["turn"]
	assert_eq(mid_at, Vector2(100, -20), "120 px up at the middle")
	assert_almost_eq(mid_turn, -6.0, 1e-6)
	var end: Dictionary = GlassMotion.flight(a, b, 1.0, "arrive", 120.0, -6.0)
	var end_at: Vector2 = end["at"]
	var end_turn: float = end["turn"]
	assert_eq(end_at, Vector2(200, 100))
	assert_almost_eq(end_turn, 0.0, 1e-6)


func test_the_hop_rises_6_4_percent_at_45_percent_and_settles() -> void:
	var rest: Dictionary = GlassMotion.pose(Vector2(10, 500))
	var highest: float = 500.0
	for i: int in 101:
		var p: Dictionary = GlassMotion.hop(rest, 250.0, i / 100.0)
		var at: Vector2 = p["at"]
		highest = minf(highest, at.y)
	assert_almost_eq(highest, 500.0 - 16.0, 0.2)
	var end: Dictionary = GlassMotion.hop(rest, 250.0, 1.0)
	var end_at: Vector2 = end["at"]
	assert_eq(end_at, Vector2(10, 500))
