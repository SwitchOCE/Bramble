class_name RecruitTripleMotion
extends Control
## Presentation only. The core's triple events identify new goldens; the live old targets supply
## the consumed copies' drawn positions (including the third copy while it is being dropped).
## The state is already authoritative. Any press finishes this layer before normal input runs.

# All triple motion tuning lives here; times are frames at 60 fps, in order.
const BEATS: Dictionary = {
	"lift": 14.0,
	"gather": 22.0,
	"charge": 14.0,
	"flash": 8.0,
	"reveal": 20.0,
	"land": 20.0,
	"tail": 10.0,
}
const PACES: Dictionary = {"brisk": 1.0, "ceremonial": 1.2}
const HUB: Vector2 = Vector2(960, 570)
const AMBER: Color = Color("ffcb65")
const CREAM: Color = Color("fff4cc")
const LIFT: float = 28.0
const SPREAD: float = 110.0
const REVEAL_SCALE: float = 1.22
const LAND_ARC: float = 90.0
const RAYS: int = 18
const HALO_RADIUS: float = 205.0
const MULTIPLE_SPACING: float = 430.0
const FLASH_RADIUS: float = 170.0

var pace: float = 1.0
var _screen: RecruitScreen
var _pending: Array[Dictionary] = []
var _runs: Array[Dictionary] = []
var _age: float = 0.0


func _init(screen: RecruitScreen) -> void:
	_screen = screen
	name = "TripleMotion"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


static func duration() -> float:
	var frames: float = 0.0
	for value: float in BEATS.values():
		frames += value
	return frames / 60.0


func active() -> bool:
	return not _runs.is_empty()


## Called before the keeper can replace or fade the old cards. Initial loads never celebrate.
func prepare(next: Dictionary) -> void:
	finish()
	_pending.clear()
	if _screen.state.is_empty():
		return
	var available: Array[Dictionary] = []
	var surviving: Dictionary = {}
	for kind: String in ["hand", "board"]:
		for value: Variant in next.get(kind, []):
			if value is Dictionary:
				var card: Dictionary = value
				surviving[GlassScreen.card_key(kind, 0, card)] = true
	for kind: String in ["hand", "board", "shop"]:
		for target: Dictionary in _screen.targets_of(kind):
			var card: Dictionary = target["card"]
			if GlassPieces.as_bool(card.get("golden", false)) or GlassScreen._is_spell(card):
				continue
			var consumed: bool = not surviving.has(GlassScreen.card_key(kind, 0, card))
			if kind == "shop":
				var new_shop: Array = next.get("shop_units", [])
				var index: int = target["index"]
				var bought: Array = next.get("triple_bought_ids", [])
				consumed = (
					bought.has(str(card["id"]))
					and (index >= new_shop.size() or not new_shop[index] is Dictionary)
				)
			if consumed:
				available.append(target)
	for raw_uid: Variant in next.get("triple_uids", []):
		var uid: int = GlassPieces.as_int(raw_uid)
		var golden: Dictionary = _find_golden(next, uid)
		if golden.is_empty() or surviving_in_old(uid):
			continue
		var sources: Array[Dictionary] = []
		for target: Dictionary in available.duplicate():
			var card: Dictionary = target["card"]
			if str(card["id"]) != str(golden["id"]) or sources.size() == 3:
				continue
			var node: Control = target["node"]
			if not is_instance_valid(node):
				continue
			(
				sources
				. append(
					{
						"card": card,
						"at": node.get_transform() * (node.size / 2.0),
						"turn": node.rotation,
						"scale": node.scale,
					}
				)
			)
			node.hide()
			available.erase(target)
		# Created/summoned copies can arrive and combine within one core action. Give these an
		# arrival at the destination, without pretending a shop purchase happened.
		while sources.size() < 3:
			var normal: Dictionary = golden.duplicate(true)
			normal["golden"] = false
			normal["attack"] = GlassPieces.as_int(golden.get("base_attack", 0)) / 2.0
			normal["health"] = GlassPieces.as_int(golden.get("base_health", 0)) / 2.0
			normal["base_attack"] = normal["attack"]
			normal["base_health"] = normal["health"]
			normal["max_health"] = normal["health"]
			(
				sources
				. append(
					{
						"card": normal,
						"at": HUB + Vector2((sources.size() - 1) * SPREAD, 170),
						"turn": 0.0,
						"scale": Vector2.ONE,
					}
				)
			)
		_pending.append({"uid": uid, "sources": sources, "golden": golden})


func surviving_in_old(uid: int) -> bool:
	return not _find_golden(_screen.state, uid).is_empty()


## Called after layout, including the input helper's deferred buy-onto-board redraw.
func present() -> void:
	if _pending.is_empty():
		return
	_screen._tips.hide()
	for plan: Dictionary in _pending:
		var target: Control = null
		for kind: String in ["hand", "board"]:
			for entry: Dictionary in _screen.targets_of(kind):
				var card: Dictionary = entry["card"]
				if GlassPieces.as_int(card.get("uid", -1)) == plan["uid"]:
					target = entry["node"]
		if target == null:
			continue
		_screen._keeper.finish(target)
		plan["target"] = target
		plan["end"] = target.get_transform() * (target.size / 2.0)
		plan["turn"] = target.rotation
		target.hide()
		for source: Dictionary in plan["sources"]:
			var data: Dictionary = source["card"]
			var copy: Control = _screen._make_card("board", data, {})
			add_child(copy)
			copy.pivot_offset = copy.size / 2.0
			source["node"] = copy
		var golden: Dictionary = plan["golden"]
		var reveal: Control = _screen._make_card("board", golden, {})
		add_child(reveal)
		reveal.pivot_offset = reveal.size / 2.0
		plan["reveal"] = reveal
		var flare: Polygon2D = Polygon2D.new()
		flare.polygon = GlassBox.hexagon(
			Rect2(Vector2.ONE * -FLASH_RADIUS, Vector2.ONE * FLASH_RADIUS * 2.0), 0.22
		)
		flare.color = CREAM
		add_child(flare)
		plan["flare"] = flare
		_runs.append(plan)
	for i: int in _runs.size():
		_runs[i]["hub"] = HUB + Vector2((i - (_runs.size() - 1) / 2.0) * MULTIPLE_SPACING, 0)
	_pending.clear()
	_age = 0.0
	set_process(active())
	_pose()


## No queued action and no swallowed click: reveal the authoritative state synchronously.
func finish() -> void:
	for run: Dictionary in _runs:
		var target: Control = run["target"]
		if is_instance_valid(target):
			target.show()
	_runs.clear()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta / pace
	if _age >= duration():
		finish()
	else:
		_pose()


func _end(beat: String) -> float:
	var frames: float = 0.0
	for key: String in BEATS:
		frames += BEATS[key]
		if key == beat:
			return frames / 60.0
	return frames / 60.0


func _part(beat: String) -> float:
	var length: float = BEATS[beat] / 60.0
	return clampf((_age - _end(beat) + length) / length, 0, 1)


func _pose() -> void:
	var lift: float = _part("lift")
	var gather: float = _part("gather")
	var charge: float = _part("charge")
	var land: float = _part("land")
	for run: Dictionary in _runs:
		var hub: Vector2 = run["hub"]
		var sources: Array = run["sources"]
		for i: int in sources.size():
			var source: Dictionary = sources[i]
			var node: Control = source["node"]
			var start: Vector2 = source["at"]
			var staging: Vector2 = hub + Vector2((i - 1) * SPREAD, -30 if i == 1 else 30)
			var raised: Vector2 = start + Vector2((i - 1) * LIFT * lift, -LIFT * lift)
			var source_center: Vector2 = raised.lerp(staging, gather * gather * gather)
			source_center = source_center.lerp(hub, charge * charge)
			node.position = source_center - node.size / 2.0
			var initial_scale: Vector2 = source["scale"]
			node.scale = initial_scale.lerp(Vector2.ONE * 0.8, gather)
			node.scale *= lerpf(1.0, 0.16, charge * charge)
			var initial_turn: float = source["turn"]
			node.rotation = lerpf(initial_turn, (i - 1) * 0.12, gather) * (1.0 - charge)
			node.modulate = Color.WHITE.lerp(CREAM, charge)
			node.visible = _age < _end("charge")
		var reveal: Control = run["reveal"]
		var turn: float = run["turn"]
		var resolved: float = _part("reveal")
		var eased: float = smoothstep(0.0, 1.0, land)
		var end: Vector2 = run["end"]
		var center: Vector2 = hub.lerp(end, eased) + Vector2(0, -LAND_ARC * sin(PI * land))
		reveal.position = center - reveal.size / 2.0
		reveal.rotation = turn * eased
		var swell: float = REVEAL_SCALE + sin(PI * resolved) * 0.09
		reveal.scale = Vector2.ONE * lerpf(swell, 1.0, eased)
		reveal.modulate.a = minf(1.0, _part("flash") * 3.0)
		reveal.visible = _age >= _end("charge") and land < 1.0
		var flare: Polygon2D = run["flare"]
		flare.position = hub
		flare.scale = Vector2.ONE * lerpf(0.45, 1.25, _part("flash"))
		flare.modulate.a = 1.0 - _part("flash")
		flare.visible = _age >= _end("charge") and _part("flash") < 1.0
		var target: Control = run["target"]
		if is_instance_valid(target):
			target.visible = land >= 1.0
	queue_redraw()


func _draw() -> void:
	if not active():
		return
	for run: Dictionary in _runs:
		_draw_run(run)


func _draw_run(run: Dictionary) -> void:
	var hub: Vector2 = run["hub"]
	var charge: float = _part("charge")
	var flash: float = _part("flash")
	var tail: float = _part("tail")
	var brightness: float = (0.15 + charge * 0.5) * (1.0 - _part("land"))
	for i: int in range(12, 0, -1):
		draw_circle(hub, HALO_RADIUS * i / 12.0, Color(AMBER, brightness * 0.035))
	if _age < _end("charge"):
		for source: Dictionary in run["sources"]:
			var node: Control = source["node"]
			var center: Vector2 = node.position + node.size / 2.0
			var start: Vector2 = source["at"]
			draw_line(start.lerp(center, 0.6), center, Color(AMBER, _part("gather") * 0.6), 5, true)
			draw_arc(
				center,
				node.size.y * node.scale.y * 0.55,
				0,
				TAU,
				48,
				Color(AMBER, 0.35 + charge * 0.6),
				3,
				true
			)
		var radius: float = lerpf(130.0, 20.0, charge * charge)
		draw_arc(hub, radius, -PI / 2, TAU - PI / 2, 64, Color(AMBER, charge), 4, true)
	else:
		var release: float = clampf((_age - _end("charge")) / 0.65, 0, 1)
		for i: int in RAYS:
			var direction: Vector2 = Vector2.from_angle(TAU * i / RAYS + 0.15)
			var reach: float = lerpf(70, 330 if i % 2 == 0 else 235, release)
			draw_line(
				hub + direction * reach * 0.65,
				hub + direction * reach,
				Color(CREAM, (1.0 - release) * 0.9),
				6 * (1.0 - release) + 1,
				true
			)
		draw_arc(
			hub,
			lerpf(30, 260, flash),
			0,
			TAU,
			80,
			Color(CREAM, (1.0 - flash) * 0.9),
			8 * (1.0 - flash) + 1,
			true
		)
		var end: Vector2 = run["end"]
		if _part("land") >= 1.0:
			draw_arc(end, 140 + tail * 45, 0, TAU, 64, Color(AMBER, (1.0 - tail) * 0.6), 3, true)


static func _find_golden(view: Dictionary, uid: int) -> Dictionary:
	for kind: String in ["hand", "board"]:
		for value: Variant in view.get(kind, []):
			if value is Dictionary:
				var card: Dictionary = value
				if (
					GlassPieces.as_int(card.get("uid", -1)) == uid
					and GlassPieces.as_bool(card.get("golden", false))
				):
					return card
	return {}
