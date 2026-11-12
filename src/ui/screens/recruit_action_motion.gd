@warning_ignore_start("unsafe_call_argument", "unsafe_property_access")
extends Control
## Action pictures run on one clock; the rules have already committed the new state.

const Layout := preload("res://src/ui/screens/recruit_layout.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const Settings := preload("res://src/ui/settings.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

var elapsed: float = 0.0
var duration: float = 0.0
var active: bool = false
var tracks: Array[Dictionary] = []
var kind: String = ""
var _targets: Array[Control] = []
var _gold: Label
var _tier: Label
var _old_gold: int = 0
var _final_gold: int = 0
var _final_tier: int = 1
var _reduced: bool = false
var _rate: float = 1.0
var _pulses: Array[Dictionary] = []
var _price: Label
var _final_price: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 14
	set_process(false)


func snapshot(ui: Layout) -> Dictionary:
	var cards: Array[Dictionary] = []
	for holder: Node in [ui._shop_cards, ui._hand_cards, ui._board]:
		for child: Node in holder.get_children():
			if child is Card:
				var card: Card = child
				(
					cards
					. append(
						{
							"unit": card.unit.duplicate(true),
							"zone": card.zone,
							"index": card.index,
							"mode": card.mode,
							"selected": card.selected,
							"rect": _rect(card),
							"card": card,
						}
					)
				)
	return {
		"cards": cards,
		"state": ui.state.duplicate(true),
		"gold": _point(ui._gold.get("_big")),
		"tier": _point(ui._tier_label),
	}


## Called immediately after render, never as a gate in front of input or the core action.
func present(ui: Layout, before: Dictionary, action: String) -> void:
	finish()
	elapsed = 0.0
	duration = 0.0
	_reduced = Settings.reduce_motion
	_rate = maxf(1.0, Settings.fight_speed)
	kind = action
	var after: Dictionary = snapshot(ui)
	var old_cards: Array = Data.a(before, "cards")
	var new_cards: Array = Data.a(after, "cards")
	var removed: Array[Dictionary] = _difference(old_cards, new_cards)
	var added: Array[Dictionary] = _difference(new_cards, old_cards)
	var old_state: Dictionary = Data.d(before, "state")
	_gold = ui._gold.get("_value")
	_tier = ui._tier_label
	_price = ui._tier_button.get("_cost_label")
	_final_price = _price.text
	_old_gold = Data.i(old_state, "gold")
	_final_gold = Data.i(ui.state, "gold")
	_final_tier = Data.i(ui.state, "tier", 1)
	var golden: Dictionary = _golden(added, old_cards)
	var eater: Dictionary = _eater(old_cards, new_cards)
	if not golden.is_empty():
		kind = "triple"
		var id: String = Data.s(Data.d(golden, "unit"), "def_id")
		var copies: int = 0
		for source: Dictionary in removed:
			if Data.s(Data.d(source, "unit"), "def_id") == id and copies < 3:
				_fly(source, golden, 0.3, copies * 0.025)
				copies += 1
		for track: Dictionary in tracks:
			track["reveal_at"] = duration
		_pulse(golden.get("card"), duration, true)
	elif not eater.is_empty():
		kind = "swallow"
		for source: Dictionary in removed:
			if Data.s(source, "zone") != "board" or _key(source) != _key(eater):
				var belly: Card = eater["card"]
				var point: Vector2 = get_global_transform().affine_inverse() * belly.belly_point()
				_fly(source, {"rect": Rect2(point - Vector2(8, 8), Vector2(16, 16))}, 0.36)
				tracks[-1]["dissolve"] = true
				tracks[-1]["swallow"] = true
				var arrival: float = tracks[-1]["seconds"]
				_pulse(belly.trigger_glyph(), arrival, true)
				_settle(belly, arrival)
				break
	elif action == "buy":
		for target: Dictionary in added:
			if Data.s(target, "zone") not in ["hand", "board"]:
				continue
			var source: Dictionary = _matching(removed, "shop", Data.d(target, "unit"))
			if not source.is_empty():
				_fly(source, target, 0.36)
				if Data.s(target, "zone") == "hand" and not source.get("released", false):
					tracks[-1]["route"] = _hand_route(source, target, _rect(ui._board))
				_settle(target.get("card"), tracks[-1]["seconds"])
	elif action == "sell":
		for source: Dictionary in removed:
			if Data.s(source, "zone") != "board":
				continue
			var away: Dictionary = ui._away_tray.arrival_target(Data.d(source, "unit"))
			if not away.is_empty():
				kind = "fly_south"
				var portrait: Control = away["portrait"]
				_fly(source, {"rect": _rect(portrait)}, 0.4)
				tracks[-1]["dissolve"] = true
				_pulse(away["countdown"], 0.4 / _rate, true)
				_pulse(away["mark"], 0.4 / _rate)
			else:
				_dissolve(source)
	else:
		for target: Dictionary in added:
			if Data.s(target, "zone") == "board":
				var source: Dictionary = _matching(removed, "hand", Data.d(target, "unit"))
				if not source.is_empty():
					kind = "play"
					_fly(source, target, 0.28)
					_settle(target.get("card"), tracks[-1]["seconds"])
	# A reorder keeps the same identities, so it is absent from the added/removed sets.
	if action == "place" and eater.is_empty():
		for target: Dictionary in new_cards:
			if Data.s(target, "zone") != "board":
				continue
			var source: Dictionary = _matching(old_cards, "board", Data.d(target, "unit"))
			if not source.is_empty() and Data.i(source, "index") != Data.i(target, "index"):
				_fly(source, target, 0.22)
				_settle(target.get("card"), tracks[-1]["seconds"])
	if _final_gold != _old_gold:
		_gold.text = str(_old_gold)
		var anchor: Vector2 = before["gold"]
		var other: Vector2 = after["tier"]
		if not removed.is_empty():
			var source_rect: Rect2 = removed[0]["rect"]
			other = Vector2(source_rect.get_center().x, source_rect.position.y - 30.0)
		_coin(
			anchor if _final_gold < _old_gold else other,
			other if _final_gold < _old_gold else anchor
		)
		_pulse(ui._gold.get("_big"), 0.36 / _rate)
	if _final_tier != Data.i(old_state, "tier", 1):
		kind = "tier_up"
		_tier.text = "TIER %d" % Data.i(old_state, "tier", 1)
		_price.text = str(Data.i(old_state, "tier_up_cost"))
		duration = maxf(duration, 0.56 / _rate)
	active = duration > 0.0
	set_process(active)
	advance(0.0)


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	for track: Dictionary in tracks:
		var node: Control = Data.control(track["node"])
		if not is_instance_valid(node):
			continue
		var phase: float = clampf((elapsed - track.start) / track.seconds, 0.0, 1.0)
		var from: Rect2 = track["from"]
		var to: Rect2 = track["to"]
		node.visible = elapsed >= track.start and phase < 1.0
		var progress: float = 0.0 if _reduced and phase < 0.5 else 1.0 if _reduced else phase
		var travel: float = progress * progress * (3.0 - 2.0 * progress)
		var shrink: float = travel
		if track.get("swallow", false):
			shrink = pow(progress, 4.0)
		var extent: Vector2 = from.size.lerp(to.size, shrink)
		node.scale = extent / from.size
		node.position = from.get_center().lerp(to.get_center(), travel) - extent / 2.0
		if track.has("route") and not _reduced:
			_hand_position(node, from, to, track["route"], phase)
		elif not _reduced:
			node.position.y -= (
				sin(phase * PI) * minf(32.0, from.get_center().distance_to(to.get_center()) * 0.12)
			)
		if track.get("dissolve", false):
			node.modulate.a = 1.0 - clampf((phase - 0.82) / 0.18, 0.0, 1.0)

		var target: Control = Data.control(track.get("target"))
		if is_instance_valid(target):
			if track.get("hide_target", true):
				target.modulate.a = (
					1.0 if elapsed >= track.get("reveal_at", track.start + track.seconds) else 0.0
				)
			elif phase >= 0.65:
				var pop: float = sin((phase - 0.65) / 0.35 * PI)
				target.scale = Vector2.ONE * (1.0 if _reduced else 1.0 + pop * 0.1)
	for pulse: Dictionary in _pulses:
		var target: Control = Data.control(pulse["target"])
		if not is_instance_valid(target):
			continue
		var beat: float = clampf((elapsed - pulse.start) / (0.18 / _rate), 0.0, 1.0)
		if pulse.hidden:
			target.modulate.a = 1.0 if elapsed >= pulse.start else 0.0
		target.pivot_offset = target.size / 2.0
		if pulse.get("settle", false):
			var squash: float = sin(beat * TAU) * (1.0 - beat) * (0.0 if _reduced else 0.12)
			target.pivot_offset = Vector2(target.size.x / 2.0, target.size.y)
			target.scale = Vector2(1.0 + squash, 1.0 - squash)
		else:
			target.scale = Vector2.ONE * (1.0 + sin(beat * PI) * (0.08 if _reduced else 0.3))
	var earning: bool = _final_gold > _old_gold
	var landing: float = clampf(
		(elapsed * _rate - (0.32 if earning else 0.16)) / (0.04 if earning else 0.2), 0.0, 1.0
	)
	if is_instance_valid(_gold):
		_gold.text = str(roundi(lerpf(_old_gold, _final_gold, landing)))
	if is_instance_valid(_tier) and kind == "tier_up":
		if elapsed * _rate >= 0.36:
			_tier.text = "TIER %d" % _final_tier
			_price.text = _final_price
		_tier.pivot_offset = _tier.size / 2
		var tier_beat: float = clampf((elapsed * _rate - 0.36) / 0.2, 0.0, 1.0)
		_tier.scale = Vector2.ONE * (1.0 + sin(tier_beat * PI) * (0.1 if _reduced else 0.25))
	if elapsed >= duration:
		finish()


func finish() -> void:
	for pulse: Dictionary in _pulses:
		var target: Control = Data.control(pulse["target"])
		if is_instance_valid(target):
			target.scale = Vector2.ONE
			target.modulate.a = 1.0
	_pulses.clear()
	if is_instance_valid(_price):
		_price.text = _final_price
	for value: Variant in _targets:
		var target: Control = Data.control(value)
		if target != null:
			target.modulate.a = 1.0
			target.scale = Vector2.ONE
	_targets.clear()
	for track: Dictionary in tracks:
		var node: Control = Data.control(track["node"])
		if is_instance_valid(node):
			node.hide()
			node.queue_free()
	tracks.clear()
	if is_instance_valid(_gold):
		_gold.text = str(_final_gold)
	if is_instance_valid(_tier):
		_tier.text = "TIER %d" % _final_tier
		_tier.scale = Vector2.ONE
	active = false
	set_process(false)


func _fly(
	source: Dictionary,
	target: Dictionary,
	seconds: float,
	delay: float = 0.0,
	hide_target: bool = true
) -> void:
	seconds = (minf(seconds, 0.14) if source.get("released", false) else seconds) / _rate
	delay /= _rate
	var ghost := Card.new()
	ghost.show_unit(Data.d(source, "unit"), source.get("mode", Card.Mode.MINI))
	var from: Rect2 = source["rect"]
	ghost.set_card_size(from.size)
	ghost.pivot_offset = Vector2.ZERO
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A moving picture must never become another hit target for rapid successive actions.
	_disable_input(ghost)
	add_child(ghost)
	var landing: Control = Data.control(target.get("card"))
	if is_instance_valid(landing):
		landing.modulate.a = 0.0 if hide_target else 1.0
		_targets.append(landing)
	tracks.append(
		{
			"node": ghost,
			"from": from,
			"to": target["rect"],
			"start": delay,
			"seconds": seconds,
			"target": landing,
			"hide_target": hide_target
		}
	)
	duration = maxf(duration, seconds + delay)


func _dissolve(source: Dictionary) -> void:
	var from: Rect2 = source["rect"]
	_fly(source, {"rect": Rect2(from.get_center(), Vector2.ONE * 20)}, 0.32)
	tracks[-1]["dissolve"] = true


func _coin(from: Vector2, to: Vector2) -> void:
	var coin := TextureRect.new()
	coin.texture = Icons.icon("acorn", 48)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.size = Vector2.ONE * 48
	add_child(coin)
	tracks.append(
		{
			"node": coin,
			"from": Rect2(from - coin.size / 2, coin.size),
			"to": Rect2(to - coin.size / 2, coin.size),
			"start": 0.0,
			"seconds": 0.36 / _rate
		}
	)
	duration = maxf(duration, 0.4 / _rate)


func _rect(control: Control) -> Rect2:
	return get_global_transform().affine_inverse() * control.get_global_rect()


func _point(control: Control) -> Vector2:
	return _rect(control).get_center()


static func _key(record: Dictionary) -> String:
	var unit: Dictionary = Data.d(record, "unit")
	var iid: int = Data.i(unit, "iid", -1)
	return (
		"%s:%s"
		% [
			Data.s(record, "zone"),
			str(iid) if iid > 0 else Data.s(unit, "def_id") + str(Data.b(unit, "golden"))
		]
	)


static func _difference(a: Array, b: Array) -> Array[Dictionary]:
	var available: Dictionary = {}
	for entry: Dictionary in b:
		var key: String = _key(entry)
		available[key] = Data.i(available, key) + 1
	var out: Array[Dictionary] = []
	for entry: Dictionary in a:
		var key: String = _key(entry)
		if Data.i(available, key) > 0:
			available[key] -= 1
		else:
			out.append(entry)
	return out


static func _matching(records: Array, zone: String, unit: Dictionary) -> Dictionary:
	var iid: int = Data.i(unit, "iid", -1)
	for entry: Dictionary in records:
		if (
			Data.s(entry, "zone") == zone
			and iid > 0
			and Data.i(Data.d(entry, "unit"), "iid", -2) == iid
		):
			return entry
	var fallback: Dictionary = {}
	for entry: Dictionary in records:
		if (
			Data.s(entry, "zone") == zone
			and Data.s(Data.d(entry, "unit"), "def_id") == Data.s(unit, "def_id")
		):
			if Data.b(entry, "selected"):
				return entry
			fallback = entry
	return fallback if iid <= 0 else {}


static func _golden(records: Array, before: Array) -> Dictionary:
	for entry: Dictionary in records:
		var view: Dictionary = Data.d(entry, "unit")
		if not Data.b(view, "golden"):
			continue
		var owned_copies: int = 0
		for old: Dictionary in before:
			var old_view: Dictionary = Data.d(old, "unit")
			if Data.i(old_view, "iid", -2) == Data.i(view, "iid", -1):
				owned_copies = 0
				break
			if (
				Data.s(old, "zone") != "shop"
				and Data.s(old_view, "def_id") == Data.s(view, "def_id")
			):
				owned_copies += 1
		if owned_copies >= 2:
			return entry
	return {}


static func _eater(before: Array, after: Array) -> Dictionary:
	for now: Dictionary in after:
		if Data.s(now, "zone") != "board":
			continue
		for old: Dictionary in before:
			if (
				_key(now) == _key(old)
				and (
					Data.a(Data.d(now, "unit"), "held").size()
					> Data.a(Data.d(old, "unit"), "held").size()
				)
			):
				return now
	return {}


func _pulse(target: Control, start: float, hide_before: bool = false) -> void:
	if not is_instance_valid(target):
		return
	_pulses.append({"target": target, "start": start, "hidden": hide_before})
	if hide_before:
		target.modulate.a = 0.0
	duration = maxf(duration, start + 0.18 / _rate)


func _hand_route(source: Dictionary, target: Dictionary, board: Rect2) -> Array[Vector2]:
	var from: Rect2 = source["rect"]
	var to: Rect2 = target["rect"]
	var half_width: float = maxf(from.size.x, to.size.x) / 2.0 + 18.0
	var gutter: float = board.position.x - half_width
	if from.get_center().x > board.get_center().x:
		gutter = board.end.x + half_width
	return [
		from.get_center(),
		Vector2(gutter, from.get_center().y),
		Vector2(gutter, to.get_center().y),
		to.get_center(),
	]


func _hand_position(node: Control, from: Rect2, to: Rect2, route: Array, phase: float) -> void:
	# Cross beside the formation, then along the real reserve row; never through residents.
	var length: float = 0.0
	for i: int in range(1, route.size()):
		var previous: Vector2 = route[i - 1]
		length += previous.distance_to(route[i])
	var progress: float = phase * phase * (3.0 - 2.0 * phase)
	var remaining: float = length * progress
	var center: Vector2 = to.get_center()
	for i: int in range(1, route.size()):
		var previous: Vector2 = route[i - 1]
		var next: Vector2 = route[i]
		var leg: float = previous.distance_to(next)
		if remaining <= leg:
			center = previous.lerp(next, remaining / maxf(leg, 0.001))
			break
		remaining -= leg
	var extent: Vector2 = from.size.lerp(to.size, progress)
	node.position = center - extent / 2.0
	node.scale = extent / from.size


func _settle(target: Control, start: float) -> void:
	_pulse(target, start)
	if is_instance_valid(target):
		_pulses[-1]["settle"] = true


func _disable_input(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_disable_input(child)
