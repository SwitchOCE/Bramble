@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_property_access")
# Cue records are internal dictionaries; cards and animation anchors remain explicitly typed.
extends Control
## Recruit presentation runs on one clock. Drawing never applies a gameplay change.

const Data := preload("res://src/ui/view_data.gd")
const Settings := preload("res://src/ui/settings.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Numbers := preload("res://src/ui/stat_numbers.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

var tracks: Array[Dictionary] = []
var elapsed: float = 0.0
var duration: float = 0.0
var _board: BoardView
var _done: Callable
var _sources: Dictionary = {}
var _rolls: Array[Dictionary] = []
var _pops: Array[Dictionary] = []
var _reduced: bool = false
var _rate: float = 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 12
	set_process(false)


func play_events(board: BoardView, events: Array, finished: Callable = Callable()) -> float:
	finish()
	_board = board
	_done = finished
	elapsed = 0.0
	duration = 0.0
	_reduced = Settings.reduce_motion
	_rate = maxf(1.0, Settings.fight_speed)
	var order: Array[int] = []
	var passes: Array[Dictionary] = []
	for event_index: int in events.size():
		var event: Dictionary = events[event_index]
		var kind: String = Data.s(event, "type")
		if kind == "pass":
			var pass_event: Dictionary = event.duplicate(true)
			pass_event["_core_order"] = event_index
			passes.append(pass_event)
		elif kind == "buff" and Data.s(event, "trigger") == "end_of_turn":
			var track: Dictionary = _make_track(event, false)
			if not track.is_empty():
				track["core_order"] = event_index
				tracks.append(track)
				if not order.has(track.source):
					order.append(track.source)
	order.sort()
	var pass_start: float = 0.0
	for track: Dictionary in tracks:
		track["start"] = order.find(track.source) * 0.12 / _rate
		_schedule(track)
		pass_start = maxf(pass_start, track.land)
	passes.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return Data.i(a, "from") < Data.i(b, "from")
	)
	var pass_index: int = 0
	for event: Dictionary in passes:
		var track: Dictionary = _make_track(event, true)
		if track.is_empty():
			continue
		track["start"] = pass_start + pass_index * 0.05 / _rate
		pass_index += 1
		_schedule(track)
		tracks.append(track)
	# Pass is presented last, even when a carried Pass resolved before the EOT triggers.
	# Rebase actual applied deltas into that visual order, preserving the true final stats.
	var chronological: Array[Dictionary] = tracks.duplicate()
	chronological.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return a.core_order < b.core_order
	)
	var running_stats: Dictionary = {}
	for track: Dictionary in chronological:
		if track.target >= 0 and not running_stats.has(track.target):
			running_stats[track.target] = Vector2i(track.before_attack, track.before_health)
	tracks.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a.start < b.start if a.start != b.start else a.core_order < b.core_order
	)
	for track: Dictionary in tracks:
		if track.target < 0:
			continue
		var applied := Vector2i(
			track.after_attack - track.before_attack, track.after_health - track.before_health
		)
		var before: Vector2i = running_stats[track.target]
		track["before_attack"] = before.x
		track["before_health"] = before.y
		track["after_attack"] = before.x + applied.x
		track["after_health"] = before.y + applied.y
		running_stats[track.target] = before + applied
	var recipient_end: Dictionary = {}
	for track: Dictionary in tracks:
		if track.target >= 0:
			track["land"] = maxf(track.land, recipient_end.get(track.target, 0.0))
			recipient_end[track.target] = track.land + track.roll
		duration = maxf(duration, track.land + track.roll)
	var compression: float = minf(1.0, 1.5 / maxf(0.001, duration))
	var initial_targets: Dictionary = {}
	for track: Dictionary in tracks:
		for clock: String in ["start", "land", "roll"]:
			track[clock] *= compression
		var card: CardView = _card(track.source)
		if card != null and not _sources.has(track.source):
			var glyph: Control = card.trigger_glyph()
			_sources[track.source] = {
				"glyph": glyph,
				"start": track.start,
				"scale": glyph.scale,
				"colour": glyph.modulate,
				"visible": glyph.visible,
				"texture": (glyph as TextureRect).texture if glyph is TextureRect else null,
			}
		var target: CardView = _card(track.target)
		if target != null and not initial_targets.has(track.target):
			_set_numbers(target, track.before_attack, track.before_health)
			initial_targets[track.target] = true
	duration *= compression
	set_process(not tracks.is_empty() or not _rolls.is_empty())
	if tracks.is_empty():
		_complete()
	return duration


func _make_track(event: Dictionary, pass_seed: bool) -> Dictionary:
	var source: int = Data.i(event, "source_slot", Data.i(event, "from", -1))
	var target: int = Data.i(event, "to", -1)
	if not pass_seed:
		target = _slot_for_iid(Data.i(event, "target_iid", -2))
	if not BoardGeometry.is_valid(source) or (not pass_seed and target < 0):
		return {}
	var route: Array[int] = [source]
	var card: CardView = _card(source)
	var touching: bool = Data.s(event, "relation") == "touching"
	touching = (
		touching or (card != null and Data.s(card.unit, "text").to_lower().contains("touching"))
	)
	if pass_seed and target >= 0:
		for slot: int in BoardGeometry.ZIGZAG:
			if slot != source and _card(slot) != null:
				route.append(slot)
			if slot == target:
				break
	elif pass_seed:
		pass  # No recipient: the seed fizzles at its source.
	elif touching:
		var occupied: Array[bool] = []
		for unit: Variant in _board.cards:
			occupied.append(is_instance_valid(unit))
		route = BoardGeometry.touching(occupied, source)
		if not route.has(target):
			return {}
		route = route.slice(0, route.find(target) + 1)
	else:
		route.append(target)
	var target_card: CardView = _card(target)
	var old_attack: int = Data.i(target_card.unit, "attack") if target_card != null else 0
	var old_health: int = Data.i(target_card.unit, "health") if target_card != null else 0
	return {
		"core_order": Data.i(event, "_core_order"),
		"source": source,
		"target": target,
		"pass": pass_seed,
		"touching": touching,
		"route": route,
		"landed": false,
		"before_attack": Data.i(event, "before_attack", old_attack),
		"before_health": Data.i(event, "before_health", old_health),
		"after_attack": Data.i(event, "after_attack", old_attack + Data.i(event, "attack")),
		"after_health": Data.i(event, "after_health", old_health + Data.i(event, "health")),
		"start": 0.0,
		"land": 0.0,
		"roll": 0.2 / _rate,
	}


func _schedule(track: Dictionary) -> void:
	var travel: float = minf(0.38, 0.08 + maxi(1, track.route.size() - 1) * 0.05) / _rate
	track["land"] = track.start + (0.15 if _reduced else travel)
	if _reduced:
		track["roll"] = 0.15


func _slot_for_iid(iid: int) -> int:
	for slot: int in _board.cards.size():
		var card: CardView = _card(slot)
		if card != null and Data.i(card.unit, "iid", -1) == iid:
			return slot
	return -1


func _card(slot: int) -> CardView:
	if not is_instance_valid(_board) or not BoardGeometry.is_valid(slot):
		return null
	return Data.control(_board.cards[slot]) as CardView


func _process(delta: float) -> void:
	advance(delta)


## Also used by fixed-step evidence and tests; there are no autonomous tweens.
func advance(delta: float) -> void:
	elapsed += delta
	for source: Dictionary in _sources.values():
		var glyph: Control = Data.control(source.glyph)
		if not is_instance_valid(glyph):
			continue
		var age: float = elapsed - source.start
		var phase: float = clampf(age / (0.15 if _reduced else 0.25 / _rate), 0.0, 1.0)
		var strength: float = (
			(1.0 if _reduced else sin(phase * PI)) if age >= 0 and phase < 1 else 0.0
		)
		glyph.visible = source.visible or (age >= 0 and phase < 1)
		if not source.visible and glyph is TextureRect:
			(glyph as TextureRect).texture = (
				Icons.icon("spark", 44) if strength > 0 else source.texture
			)
		glyph.modulate = source.colour.lerp(Color(1.8, 1.6, 1.1), strength)
		glyph.scale = source.scale * (1.0 + (0.0 if _reduced else strength * 0.5))
	for track: Dictionary in tracks:
		if elapsed >= track.land and not track.landed:
			track["landed"] = true
			var card: CardView = _card(track.target)
			if card != null:
				_start_roll(
					card,
					track.before_attack,
					track.before_health,
					track.after_attack,
					track.after_health,
					track.roll
				)
	_advance_rolls(delta)
	queue_redraw()
	if not tracks.is_empty() and elapsed >= duration:
		finish()
	set_process(not tracks.is_empty() or not _rolls.is_empty() or not _pops.is_empty())


func finish() -> void:
	for roll: Dictionary in _rolls:
		if is_instance_valid(roll.card):
			_set_numbers(roll.card, roll.final_a, roll.final_h)
	_rolls.clear()
	for pop: Dictionary in _pops:
		if is_instance_valid(pop.bead):
			pop.bead.scale = Vector2.ONE
			pop.bead.modulate = Color.WHITE
	_pops.clear()
	for track: Dictionary in tracks:
		var card: CardView = _card(track.target)
		if card != null:
			_set_numbers(card, track.after_attack, track.after_health)
	for source: Dictionary in _sources.values():
		var glyph: Control = Data.control(source.glyph)
		if is_instance_valid(glyph):
			glyph.scale = source.scale
			glyph.modulate = source.colour
			glyph.visible = source.visible
			if glyph is TextureRect:
				(glyph as TextureRect).texture = source.texture
	_sources.clear()
	tracks.clear()
	set_process(false)
	queue_redraw()
	_complete()


func _complete() -> void:
	if _done.is_valid():
		var callback: Callable = _done
		_done = Callable()
		callback.call_deferred()


func _start_roll(
	card: CardView, old_a: int, old_h: int, final_a: int, final_h: int, seconds: float
) -> void:
	_rolls.append(
		{
			"card": card,
			"old_a": old_a,
			"old_h": old_h,
			"final_a": final_a,
			"final_h": final_h,
			"age": 0.0,
			"duration": seconds
		}
	)
	pop_beads(card)


func _advance_rolls(delta: float) -> void:
	for roll: Dictionary in _rolls.duplicate():
		roll["age"] += delta
		if is_instance_valid(roll.card):
			var progress: float = clampf(roll.age / maxf(0.001, roll.duration), 0.0, 1.0)
			_set_numbers(
				roll.card,
				roundi(lerpf(roll.old_a, roll.final_a, progress)),
				roundi(lerpf(roll.old_h, roll.final_h, progress))
			)
		if roll.age >= roll.duration or not is_instance_valid(roll.card):
			_rolls.erase(roll)
	for pop: Dictionary in _pops.duplicate():
		pop["age"] += delta
		if is_instance_valid(pop.bead):
			var progress: float = clampf(pop.age / pop.duration, 0.0, 1.0)
			pop.bead.scale = Vector2.ONE * (1.0 + (0.0 if _reduced else sin(progress * PI) * 0.35))
			pop.bead.modulate = Color.WHITE.lerp(UiTheme.SELECT, 1.0 - progress)
		if pop.age >= pop.duration or not is_instance_valid(pop.bead):
			_pops.erase(pop)


func _set_numbers(card: CardView, attack: int, health: int) -> void:
	var attack_label: Label = card.get("_attack_label")
	var health_label: Label = card.get("_health_label")
	attack_label.text = Numbers.compact(maxi(0, attack))
	health_label.text = Numbers.compact(maxi(0, health))


func pop_beads(card: CardView) -> void:
	for bead: Control in [card.attack_bead(), card.health_bead()]:
		bead.pivot_offset = bead.size / 2.0
		_pops.append({"bead": bead, "age": 0.0, "duration": 0.15 if _reduced else 0.2 / _rate})
	set_process(true)


## Queued gains are already in the new recruit view; only its labels roll from the old value.
func roll_gain(card: CardView, attack: int, health: int) -> void:
	_reduced = Settings.reduce_motion
	_rate = maxf(1.0, Settings.fight_speed)
	var final_a: int = Data.i(card.unit, "attack")
	var final_h: int = Data.i(card.unit, "health")
	_set_numbers(card, final_a - attack, final_h - health)
	_start_roll(
		card,
		final_a - attack,
		final_h - health,
		final_a,
		final_h,
		0.15 if _reduced else 0.2 / _rate
	)
	set_process(true)


func _point(slot: int) -> Vector2:
	return get_global_transform().affine_inverse() * _board.slot_global_center(slot)


func _draw() -> void:
	if not is_instance_valid(_board):
		return
	for track: Dictionary in tracks:
		var age: float = elapsed - track.start
		if age < 0.0 or elapsed > track.land + (0.15 if _reduced else 0.0):
			continue
		if _reduced:
			var slot: int = track.source if elapsed < track.land else track.target
			if slot >= 0:
				draw_circle(_point(slot), 28, Color(UiTheme.GILT, 0.65))
			continue
		var phase: float = clampf(age / maxf(0.001, track.land - track.start), 0.0, 1.0)
		var route: Array = track.route
		var index: int = mini(int(phase * maxi(1, route.size() - 1)), maxi(0, route.size() - 2))
		var hop: float = phase * maxi(1, route.size() - 1) - index
		var from: Vector2 = _point(route[index])
		var to: Vector2 = _point(route[mini(index + 1, route.size() - 1)])
		var at: Vector2 = from.lerp(to, hop) - Vector2(0, sin(hop * PI) * 28)
		draw_circle(at, 12 if track["pass"] else 8, UiTheme.GILT)
		draw_circle(at, 19, Color(UiTheme.GILT, 0.18))
