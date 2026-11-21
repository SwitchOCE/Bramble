class_name RecruitTripleMotion
extends Control
## Presentation only. Triple events identify the golden and logged arrivals. Drawn sources
## retain their actual poses/data, including Discover options; truly unseen sources start at
## their own gathering hub, with logged stats or a normal-definition stand-in. The core already
## owns the result. A press finishes only this layer before normal input runs.

# All triple motion tuning lives here; times are frames at 60 fps, in order.
const BEATS: Dictionary = {
	"lift": 14.0,
	"gather": 22.0,
	"charge": 14.0,
	"flash": 8.0,
	"reveal": 20.0,
	"land": 20.0,
	"reward": 27.0,
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
## Reward emerges below the reveal, then uses CardKeeper's existing 15-frame flight and hop.
const REWARD_OFFSET: Vector2 = Vector2(120, 100)

var pace: float = 1.0
var _screen: RecruitScreen
var _pending: Array[Dictionary] = []
var _runs: Array[Dictionary] = []
var _age: float = 0.0
var _presenting: bool = false


func _init(screen: RecruitScreen) -> void:
	_screen = screen
	name = "TripleMotion"
	z_index = RecruitDiscover.Z + 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


static func duration() -> float:
	var frames: float = 0.0
	for value: float in BEATS.values():
		frames += value
	return frames / 60.0


func active() -> bool:
	return not _runs.is_empty()


## Capture before layout deletes Discover options or the keeper replaces consumed cards.
## Unchanged golden entries survive counter-only redraws and unrelated state updates.
func prepare(next: Dictionary) -> void:
	if active() and not _same_destinations(next):
		finish()
	_pending.clear()
	if _screen.state.is_empty():
		return
	var available: Array[Dictionary] = []
	for kind: String in ["hand", "board"]:
		for target: Dictionary in _screen.targets_of(kind):
			var card: Dictionary = target["card"]
			var uid: int = GlassPieces.as_int(card.get("uid", -1))
			if (
				not GlassPieces.as_bool(card.get("golden", false))
				and _owned_entry(next, uid).is_empty()
			):
				available.append(target)
	var arrivals: Array = next.get("triple_arrivals", [])
	var used: Dictionary = {}
	for raw_uid: Variant in next.get("triple_uids", []):
		var uid: int = GlassPieces.as_int(raw_uid)
		var golden: Dictionary = _find_golden(next, uid)
		if golden.is_empty() or not _find_golden(_screen.state, uid).is_empty():
			continue
		# A genuinely new formation supersedes the previous presentation; ordinary redraws do not.
		finish()
		var id: String = str(golden["id"])
		var sources: Array[Dictionary] = []
		for target: Dictionary in available.duplicate():
			var card: Dictionary = target["card"]
			if str(card["id"]) != id or sources.size() == 3:
				continue
			var source_uid: int = GlassPieces.as_int(card.get("uid", -1))
			var source: Dictionary = _capture(
				target, _source_card(next, card, source_uid), str(target["kind"])
			)
			source["stats_from"] = "log" if _has_stats(next, source_uid) else "state"
			sources.append(source)
			used[source_uid] = true
			available.erase(target)
		for arrival: Dictionary in arrivals:
			var card: Dictionary = arrival["card"]
			var source_uid: int = GlassPieces.as_int(card.get("uid", -1))
			if str(card.get("id", "")) != id or used.has(source_uid) or sources.size() == 3:
				continue
			if not _owned_entry(next, source_uid).is_empty():
				continue
			var target: Dictionary = _arrival_target(next, arrival)
			if target.is_empty():
				sources.append(
					_unseen(
						_source_card(next, card, source_uid),
						"log" if _has_stats(next, source_uid) else "definition"
					)
				)
			else:
				# A drawn option/offer has its actual displayed data. Prefer a richer logged
				# snapshot when one exists, rather than substituting half the golden's stats.
				var shown: Dictionary = (
					card if arrival.get("logged_stats", false) else target["card"]
				)
				var source: Dictionary = _capture(
					target, _source_card(next, shown, source_uid), str(target["kind"])
				)
				source["stats_from"] = "log" if _has_stats(next, source_uid) else "state"
				sources.append(source)
			used[source_uid] = true
		# No drawn source or logged copy: use the normal definition as an explicit visual
		# stand-in. Its start is assigned to this run's own hub in present(), never screen centre.
		var normals: Dictionary = next.get("triple_normals", {})
		while sources.size() < 3:
			var normal: Dictionary = normals.get(id, {})
			if normal.is_empty():
				break
			sources.append(_unseen(normal, "definition"))
		if sources.size() == 3:
			var rewards: Dictionary = next.get("triple_rewards", {})
			_pending.append(
				{
					"uid": uid,
					"sources": sources,
					"golden": golden,
					"reward_uid": GlassPieces.as_int(rewards.get(str(uid), -1)),
					"reward_started": false
				}
			)


static func _has_stats(view: Dictionary, uid: int) -> bool:
	var stats: Dictionary = view.get("triple_stats", {})
	return stats.has(str(uid))


static func _source_card(view: Dictionary, card: Dictionary, uid: int) -> Dictionary:
	var result: Dictionary = card.duplicate(true)
	result["uid"] = uid
	var stats: Dictionary = view.get("triple_stats", {})
	var latest: Dictionary = stats.get(str(uid), {})
	result.merge(latest, true)
	if latest.has("health"):
		result["max_health"] = latest["health"]
	return result


func _capture(target: Dictionary, card: Dictionary, origin: String) -> Dictionary:
	var node: Control = target["node"]
	var transform: Transform2D = (
		_screen._stage.get_global_transform().affine_inverse() * node.get_global_transform()
	)
	node.hide()
	return {
		"card": card,
		"origin": origin,
		"stats_from": "state",
		"at": transform * (node.size / 2.0),
		"turn": transform.get_rotation(),
		"scale": transform.get_scale() * node.size / _screen.card_box(),
	}


static func _unseen(card: Dictionary, stats_from: String) -> Dictionary:
	return {
		"card": card,
		"origin": "unseen",
		"stats_from": stats_from,
		"turn": 0.0,
		"scale": Vector2.ONE
	}


func _arrival_target(next: Dictionary, arrival: Dictionary) -> Dictionary:
	var card: Dictionary = arrival["card"]
	var kind: String = str(arrival["kind"])
	if kind == "waiting_join":
		for entry: Dictionary in _screen.targets_of("waiting_pile"):
			var waiting: Dictionary = entry["card"]
			if waiting.get("uid") == card.get("uid"):
				return entry
		return {}
	var targets: Array[Dictionary] = _screen.targets_of("discover" if kind == "pick" else "shop")
	if kind not in ["pick", "buy"]:
		return {}
	for target: Dictionary in targets:
		var shown: Dictionary = target["card"]
		var node: Control = target["node"]
		if str(shown.get("id", "")) != str(card.get("id", "")) or not node.visible:
			continue
		if kind == "buy":
			var shop: Array = next.get("shop_units", [])
			var index: int = target["index"]
			if index < shop.size() and shop[index] is Dictionary:
				continue
		return target
	return {}


func _same_destinations(next: Dictionary) -> bool:
	for run: Dictionary in _runs:
		var uid: int = run["uid"]
		if _owned_entry(_screen.state, uid) != _owned_entry(next, uid):
			return false
		var reward_uid: int = run.get("reward_uid", -1)
		if (
			reward_uid >= 0
			and _owned_entry(_screen.state, reward_uid) != _owned_entry(next, reward_uid)
		):
			return false
	return true


static func _owned_entry(view: Dictionary, uid: int) -> Dictionary:
	for kind: String in ["hand", "board", "waiting_pile"]:
		var cards: Array = view.get(kind, [])
		for i: int in cards.size():
			if cards[i] is Dictionary:
				var card: Dictionary = cards[i]
				if uid >= 0 and GlassPieces.as_int(card.get("uid", -1)) == uid:
					return {"card": card, "kind": kind, "index": i, "count": cards.size()}
	return {}


func _target_for(uid: int) -> Control:
	for kind: String in ["hand", "board", "waiting_pile"]:
		for entry: Dictionary in _screen.targets_of(kind):
			var card: Dictionary = entry["card"]
			if GlassPieces.as_int(card.get("uid", -1)) == uid:
				return entry["node"]
	return null


## Rebind the authoritative targets after layout, preserving age and drawn copies on redraw.
func present() -> void:
	if _presenting:
		return
	_presenting = true
	if _pending.is_empty():
		for run: Dictionary in _runs:
			var uid: int = run["uid"]
			var target: Control = _target_for(uid)
			if target != null:
				_screen._keeper.finish(target)
				run["target"] = target
			_bind_reward(run)
		if active():
			_pose()
		_presenting = false
		return
	_screen._tips.hide()
	var plans: Array[Dictionary] = _pending
	_pending = []
	for i: int in plans.size():
		var plan: Dictionary = plans[i]
		var uid: int = plan["uid"]
		var target: Control = _target_for(uid)
		if target == null:
			continue
		_screen._keeper.finish(target)
		var hub: Vector2 = HUB + Vector2((i - (plans.size() - 1) / 2.0) * MULTIPLE_SPACING, 0)
		plan["hub"] = hub
		plan["target"] = target
		plan["end"] = target.get_transform() * (target.size / 2.0)
		plan["turn"] = target.rotation
		_bind_reward(plan)
		target.hide()
		for source: Dictionary in plan["sources"]:
			if str(source["origin"]) == "unseen":
				source["at"] = hub
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
	_age = 0.0
	set_process(active())
	_pose()
	_presenting = false


## No queued action and no swallowed click: reveal the authoritative state synchronously.
func finish() -> void:
	for run: Dictionary in _runs:
		var target: Control = run["target"]
		if is_instance_valid(target):
			target.show()
		var reward: Control = run.get("reward")
		if is_instance_valid(reward):
			_screen._keeper.finish(reward)
			reward.show()
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
		_present_reward(run)
	queue_redraw()


## Hold the real reward card until its beat. Redraws rebind it without replaying from the hub.
func _bind_reward(run: Dictionary) -> void:
	var reward_uid: int = run.get("reward_uid", -1)
	if reward_uid < 0:
		return
	var reward: Control = _target_for(reward_uid)
	if reward == null:
		return
	run["reward"] = reward
	if not run["reward_started"]:
		_screen._keeper.finish(reward)
		run["reward_end"] = reward.position
		run["reward_turn"] = reward.rotation_degrees
		reward.hide()


func _present_reward(run: Dictionary) -> void:
	var reward: Control = run.get("reward")
	if not is_instance_valid(reward) or run["reward_started"]:
		return
	if _age < _end("land"):
		reward.hide()
		return
	run["reward_started"] = true
	var hub: Vector2 = run["hub"]
	var end: Vector2 = run["reward_end"]
	_screen._keeper.arrive_from(
		reward,
		hub + REWARD_OFFSET - reward.size / 2.0,
		end,
		GlassPieces.as_float(run["reward_turn"])
	)


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
