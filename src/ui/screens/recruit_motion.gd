extends Control
## Short event-driven recruit cues. No captions or resting routes.
const Data := preload("res://src/ui/view_data.gd")
const Settings := preload("res://src/ui/settings.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")

var tracks: Array[Dictionary] = []
var elapsed: float = 0.0
var duration: float = 0.0
var _board: BoardView
var _done: Callable


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 12
	set_process(false)


func play_events(board: BoardView, events: Array, finished: Callable = Callable()) -> float:
	tracks.clear()
	_board = board
	_done = finished
	elapsed = 0.0
	var source_order: Array[int] = []
	for event: Dictionary in events:
		var type: String = Data.s(event, "type")
		if type not in ["buff", "pass"]:
			continue
		var source: int = Data.i(event, "source_slot", Data.i(event, "from", -1))
		var target: int = Data.i(event, "to", -1)
		if type == "buff":
			for slot: int in board.cards.size():
				var card: Control = board.cards[slot]
				if card != null and Data.i(card.unit, "iid") == Data.i(event, "target_iid", -2):
					target = slot
		if source < 0 or target < 0 or board.cards[source] == null or board.cards[target] == null:
			continue
		if not source_order.has(source):
			source_order.append(source)
		tracks.append(
			{
				"source": source,
				"target": target,
				"pass": type == "pass",
				"start": 0.0,
				"landed": false,
				"attack": Data.i(event, "attack"),
				"health": Data.i(event, "health")
			}
		)
	source_order.sort()
	var rate: float = maxf(1.0, Settings.fight_speed)
	duration = 0.0
	for track: Dictionary in tracks:
		track["start"] = (
			(source_order.find(track.source) * 0.12 + (0.2 if track["pass"] else 0.0)) / rate
		)
		duration = maxf(duration, track.start + 0.38 / rate)
	duration = minf(1.5, duration)
	set_process(not tracks.is_empty())
	if tracks.is_empty() and _done.is_valid():
		_done.call_deferred()
	return duration


func finish() -> void:
	set_process(false)
	tracks.clear()
	queue_redraw()
	if _done.is_valid():
		var callback: Callable = _done
		_done = Callable()
		callback.call()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		finish()


func _draw() -> void:
	if not is_instance_valid(_board):
		return
	var rate: float = maxf(1.0, Settings.fight_speed)
	for track: Dictionary in tracks:
		var phase: float = (elapsed - track.start) / (0.38 / rate)
		if phase < 0.0 or phase > 1.0:
			continue
		var source: Control = _board.cards[track.source]
		var target: Control = _board.cards[track.target]
		if not is_instance_valid(source) or not is_instance_valid(target):
			continue
		var a: Vector2 = (
			get_global_transform().affine_inverse()
			* source.trigger_glyph().get_global_rect().get_center()
		)
		var b: Vector2 = (
			get_global_transform().affine_inverse()
			* target.health_bead().get_global_rect().get_center()
		)
		if Settings.reduce_motion:
			draw_circle(a if phase < 0.5 else b, 28, Color(UiTheme.GILT, 0.65))
		else:
			var at: Vector2 = a.lerp(b, phase) + Vector2(0, -sin(phase * PI) * 42)
			if track["pass"]:
				var route: Array[int] = []
				for slot: int in BoardGeometry.ZIGZAG:
					if _board.cards[slot] != null:
						route.append(slot)
				var end: int = route.find(track.target)
				if end > 0:
					var step: float = phase * end
					var index: int = mini(int(step), end - 1)
					var ca: Control = _board.cards[route[index]]
					var cb: Control = _board.cards[route[index + 1]]
					var pa: Vector2 = (
						get_global_transform().affine_inverse() * ca.get_global_rect().get_center()
					)
					var pb: Vector2 = (
						get_global_transform().affine_inverse() * cb.get_global_rect().get_center()
					)
					at = pa.lerp(pb, step - index) + Vector2(0, -sin((step - index) * PI) * 24)
			draw_circle(at, 13 if track["pass"] else 8, UiTheme.GILT)
			draw_circle(at, 20, Color(UiTheme.GILT, 0.2))
		if phase > 0.72 and not track.landed:
			track["landed"] = true
			pop_beads(target)


func pop_beads(card: Control) -> void:
	for bead: Control in [card.attack_bead(), card.health_bead()]:
		bead.pivot_offset = bead.size / 2.0
		bead.modulate = UiTheme.SELECT
		if not Settings.reduce_motion:
			bead.scale = Vector2.ONE * 1.35
		var tween: Tween = create_tween().set_parallel()
		tween.tween_property(bead, "scale", Vector2.ONE, 0.2 / maxf(1.0, Settings.fight_speed))
		tween.tween_property(bead, "modulate", Color.WHITE, 0.2 / maxf(1.0, Settings.fight_speed))


## Start-of-Turn rewards land on their actual bead, with no numeric delta overlay.
func roll_gain(card: Control, attack: int, health: int) -> void:
	var final_attack: int = Data.i(card.unit, "attack")
	var final_health: int = Data.i(card.unit, "health")
	var maximum: int = Data.i(card.unit, "max_health", final_health)
	card.set_stats(final_attack - attack, final_health - health, maximum)
	pop_beads(card)
	create_tween().tween_method(
		func(progress: float) -> void:
			if is_instance_valid(card):
				card.set_stats(
					roundi(lerpf(final_attack - attack, final_attack, progress)),
					roundi(lerpf(final_health - health, final_health, progress)),
					maximum
				),
		0.0,
		1.0,
		0.2 / maxf(1.0, Settings.fight_speed)
	)
