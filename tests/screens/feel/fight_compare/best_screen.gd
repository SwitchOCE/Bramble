extends "res://tests/screens/feel/fight_compare/compare_screen.gd"
## The fight screen playing best_timeline.gd's schedule frame by frame, instead of FightScreen's
## step-by-step playback: each step's view state is shown on its frame, then every card is posed
## from the timeline (where it stands plus the timeline's offset, scale, turn and light), and the
## damage bursts and glows are drawn on their own frames. The screen still draws the boards,
## numbers, deaths (today's fall) and the result. Exploratory: nothing here reaches the game.

## The burst: pop in, settle, read, fade (frames); best.md: readable to C+30, gone by C+40.
const BURST_IN: int = 3
const BURST_SETTLE: int = 5
const BURST_READ: int = 20
const BURST_FADE: int = 8
const BURST_START: float = 0.55
const BURST_SCALE: float = 1.18
const BURST_RISE: float = 16.0
const LABEL_SIZE: int = 40

var _timeline: RefCounted
var _plan: Array[Dictionary] = []
var _n: int = 0
var _next: int = 0
var _playing: bool = false
var _finished: bool = false
## key -> where the card stands (its slot), from the state shown
var _homes: Dictionary = {}
var _burst_next: int = 0
## [{node, key, recipient, offset, from}]
var _live: Array[Dictionary] = []
var _lit: Dictionary = {}
var _label: Label


func play(replay: FightReplay) -> void:
	if _keeper != null:
		_keeper.clear()
	_timeline = replay.get("timeline")
	_plan.assign(replay.steps)
	_replay = null
	_shown_lunge = {}
	_shown_splashes = []
	_step = -1
	_n = 0
	_next = 0
	_burst_next = 0
	_playing = true
	_finished = false
	_apply_due()
	_pose_cards()


func is_playing() -> bool:
	return _playing


## The timeline moves every card itself: no lunge for FightScreen to play.
func _lunge() -> Dictionary:
	return {}


## Bursts are the timeline's (_spawn_bursts), not the state's.
func _build_moment() -> void:
	pass


func _light_lunge() -> void:
	_apply_glow()


## Keeps the bursts and the placeholder label over a redraw of the front layer.
func _layout() -> void:
	var kept: Array[Control] = []
	for live: Dictionary in _live:
		var node: Control = live["node"]
		if is_instance_valid(node) and node.get_parent() == _front:
			_front.remove_child(node)
			kept.append(node)
	if _label != null and _label.get_parent() == _front:
		_front.remove_child(_label)
	super()
	for node: Control in kept:
		_front.add_child(node)
	if _label != null:
		_front.add_child(_label)


func _process(delta: float) -> void:
	super(delta)
	if not _playing:
		return
	_n += 1
	if _i(_timeline.get("frame_offset")) < 0:
		_timeline.set("frame_offset", Engine.get_frames_drawn() - _n)
	_apply_due()
	_pose_cards()
	_spawn_bursts()
	_draw_bursts()
	_apply_glow()
	_draw_label()


func _apply_due() -> void:
	while _next < _plan.size() and _i(_plan[_next]["frame"]) <= _n:
		var step: Dictionary = _plan[_next]
		_step = _next
		_next += 1
		_keeper.speed = maxf(_f(step.get("speed", 1.0)), 0.01)
		var view: Dictionary = step["state"]
		show_state(view)
		_keeper.speed = 1.0
		_take_over()
		if _next == _plan.size():
			settle()
			result_shown.emit()
	if not _finished and _next >= _plan.size() and _n >= _i(_timeline.get("end_frame")):
		_finished = true
		_playing = false
		playback_finished.emit()


## After a commit: the keeper's own moves stop (the timeline poses every card), and where each
## card stands is read from the state.
func _take_over() -> void:
	_homes.clear()
	for target: Dictionary in _targets:
		if str(target["kind"]) != "board":
			continue
		var index: int = target["index"]
		var side: int = floori(index / float(BOARD_SLOTS))
		var data: Dictionary = target["card"]
		var key: String = card_key("f%d_" % side, index % BOARD_SLOTS, data)
		_homes[key] = unit_xy(side, index % BOARD_SLOTS)
	for key: Variant in _keeper._kept:
		var entry: Dictionary = _keeper._kept[key]
		var node: Control = entry["node"]
		_keeper.stop(node)


func _pose_cards() -> void:
	for key: Variant in _keeper._kept:
		var name_of: String = str(key)
		if not _homes.has(name_of):
			continue
		var entry: Dictionary = _keeper._kept[key]
		var node: Control = entry["node"]
		var pose: Dictionary = _timeline.call("pose", name_of, _n)
		var home: Vector2 = _homes[name_of]
		var offset: Vector2 = pose["offset"]
		node.pivot_offset = node.size / 2.0
		node.position = home + offset
		node.scale = Vector2.ONE * _f(pose["scale"])
		node.rotation_degrees = _f(pose["turn"])
		var light: Color = pose["light"]
		node.modulate = light


func _spawn_bursts() -> void:
	var spawned: Array = []
	var all: Array = _timeline.get("bursts")
	while _burst_next < all.size():
		var burst: Dictionary = all[_burst_next]
		if _i(burst["frame"]) > _n:
			break
		_burst_next += 1
		var key: String = burst["key"]
		var taken: bool = burst["taken"]
		var down_key: String = "taken_down_per_h" if taken else "dealt_down_per_h"
		var down: float = GlassPieces.number("stage.fight.hit." + down_key)
		var r: float = GlassPieces.number("stage.fight.hit." + ("taken_r" if taken else "dealt_r"))
		var blocked: bool = burst["blocked"]
		var merge: bool = burst.get("merge", false)
		if merge:
			_drop_merged(key)
		var hit: Control = hit_splash(_i(burst["amount"]), r, blocked)
		hit.name = "Hit_%d" % _burst_next
		hit.pivot_offset = hit.size / 2.0
		var recipient: Control = _node_of(key)
		var offset: Vector2 = Vector2(_w() / 2.0 - r, _h() * down - r)
		var at: Vector2 = recipient.position if recipient != null else Vector2.ZERO
		hit.position = at + offset
		_front.add_child(hit)
		(
			_live
			. append(
				{
					"node": hit,
					"key": key,
					"recipient": recipient,
					"offset": offset,
					"from": _n,
					"merge": merge,
				}
			)
		)
		(
			spawned
			. append(
				{
					"side": burst["side"],
					"slot": burst["slot"],
					"amount": burst["amount"],
					"blocked": blocked,
				}
			)
		)
	# the fixture logs a burst when this list changes to a new, non-empty one
	_shown_splashes = spawned


## Rule 5: a card hit again in a combo keeps one burst; the old one goes as the new one pops with
## the running total.
func _drop_merged(key: String) -> void:
	var still: Array[Dictionary] = []
	for live: Dictionary in _live:
		if str(live["key"]) == key and live.get("merge", false):
			var node: Control = live["node"]
			if is_instance_valid(node):
				node.queue_free()
			continue
		still.append(live)
	_live = still


func _draw_bursts() -> void:
	var still: Array[Dictionary] = []
	var life: int = BURST_IN + BURST_SETTLE + BURST_READ + BURST_FADE
	for live: Dictionary in _live:
		var hit: Control = live["node"]
		var age: int = _n - _i(live["from"])
		if age >= life or not is_instance_valid(hit):
			if is_instance_valid(hit):
				hit.queue_free()
			continue
		var swell: float = 1.0
		if age < BURST_IN:
			swell = lerpf(BURST_START, BURST_SCALE, float(age) / BURST_IN)
		elif age < BURST_IN + BURST_SETTLE:
			swell = lerpf(BURST_SCALE, 1.0, float(age - BURST_IN) / BURST_SETTLE)
		var fade: float = clampf(float(age - life + BURST_FADE) / BURST_FADE, 0.0, 1.0)
		var recipient: Control = _node_of(str(live["key"]))
		if recipient == null:
			var was: Variant = live["recipient"]
			if is_instance_valid(was):
				recipient = was
		else:
			live["recipient"] = recipient
		if recipient != null:
			var offset: Vector2 = live["offset"]
			hit.position = recipient.position + offset + Vector2.UP * BURST_RISE * fade
		hit.scale = Vector2.ONE * swell
		hit.modulate.a = 1.0 - fade
		still.append(live)
	_live = still


func _node_of(key: String) -> Control:
	if not _keeper._kept.has(key):
		return null
	var entry: Dictionary = _keeper._kept[key]
	var node: Control = entry["node"]
	return node


## The attacker's (and a trigger source's) glow: today's lunge look (fight.html .card.lunge),
## drawn above the other cards.
func _apply_glow() -> void:
	if _timeline == null:
		return
	var glowing: Dictionary = _timeline.call("glowing", maxi(_n, 0))
	var z: int = _i(GlassPieces.rule("fight", ".card.lunge", "z-index"))
	for target: Dictionary in _targets:
		var node: Variant = target.get("node")
		if not node is GlassCard or str(target["kind"]) != "board":
			continue
		var card: GlassCard = node
		var data: Dictionary = target["card"]
		var key: String = card_key("", 0, data)
		var on: bool = glowing.has(key)
		if _lit.get(card.get_instance_id(), not on) == on:
			continue
		_lit[card.get_instance_id()] = on
		if on:
			card.set_glow("fight", ".card.lunge")
			card.z_index = z
		else:
			card.set_glow("", "")
			card.z_index = 0


## CB7 "best_xn": a plain-text xN over the source, marked as a placeholder (not the art).
func _draw_label() -> void:
	var label: Dictionary = _timeline.call("label_at", _n)
	if label.is_empty():
		if _label != null:
			_label.visible = false
		return
	if _label == null:
		_label = Label.new()
		_label.name = "PlaceholderCount"
		_label.add_theme_font_size_override("font_size", LABEL_SIZE)
		_label.add_theme_color_override("font_color", Color.WHITE)
		_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_label.add_theme_constant_override("outline_size", 10)
		_label.z_index = 20
		_front.add_child(_label)
	_label.visible = true
	_label.text = "%s\n(placeholder)" % str(label["text"]).replace("x", "×")
	var key: String = label["key"]
	var home: Vector2 = _homes.get(key, Vector2.ZERO)
	_label.position = home + Vector2(_w() + 8.0, 10.0)
