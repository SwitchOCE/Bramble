extends RefCounted
## Deterministic fight cues. Durations are real seconds, with a travel/contact floor at ×4.

const Special := preload("res://src/ui/screens/combat_special_motion.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

var precontact_delay: float = 0.0

var _screen: Control
var _snap: bool = false
var _source: int = -1
var _active_snap: bool = false
var _attacker: int = -1
var _strike_count: int = 1
var _strike_presented: int = 1
var _joiners: Array[int] = []
var _joiners_landed: Array[int] = []
var _burst_groups: Dictionary[String, Dictionary] = {}


func _init(screen: Control) -> void:
	_screen = screen


func contact_time() -> float:
	return (
		0.15 + precontact_delay
		if Settings.reduce_motion
		else (
			precontact_delay
			+ (0.0 if _active_snap else 0.1 / _speed())
			+ maxf(0.1, (0.12 if _active_snap else 0.16) / _speed())
		)
	)


func attack_duration() -> float:
	return (
		contact_time()
		+ (_strike_count - 1) * 0.12
		+ (0.04 + (_joiners.size() - 1) * 0.03 if not _joiners.is_empty() else 0.0)
		+ maxf(0.04, 0.05 / _speed())
		+ maxf(0.12, 0.2 / _speed())
		+ maxf(0.25, 0.3 / _speed())
	)


func _speed() -> float:
	return CoreUtil.to_float(_screen.get("speed"))


func _model() -> CombatModel:
	var model: CombatModel = _screen.get("model")
	return model


func _last_death() -> Vector2:
	var point: Vector2 = _screen.get("_last_death")
	return point


func _plaque(side: int) -> Control:
	var plaques: Array = _screen.get("_plaques")
	var plaque: Control = plaques[side]
	return plaque


func _card(uid: int) -> CardView:
	var cards: Dictionary = _screen.get("_cards")
	var card: CardView = cards.get(uid)
	return card


func _tween(node: Node = null) -> Tween:
	var tween: Tween = _screen.call("_tween")
	if node != null:
		tween.bind_node(node)
	return tween


func flash(node: Control, colour: Color) -> void:
	var tween: Tween = _tween(node)
	tween.tween_property(node, "modulate", Color.WHITE.lerp(colour, 0.2) * 1.5, 0.075)
	tween.tween_property(node, "modulate", Color.WHITE, 0.075)


func _pulse(node: Control, colour: Color = UiTheme.ACORN) -> void:
	flash(node, colour)
	if Settings.reduce_motion:
		return
	node.pivot_offset = node.size / 2.0
	var tween: Tween = _tween(node)
	tween.tween_property(node, "scale", Vector2.ONE * 1.35, 0.08)
	tween.tween_property(node, "scale", Vector2.ONE, 0.12)


## Called before the screen computes this attack's event and animation span.
func prepare_attack(event: Dictionary) -> void:
	_attacker = Data.i(event, "attacker", -1)
	_strike_count = maxi(1, Data.i(event, "strikes", 1))
	_strike_presented = 1
	_joiners.clear()
	_joiners_landed.clear()
	_burst_groups.clear()
	for uid: int in Data.a(event, "joiners"):
		_joiners.append(uid)
	_active_snap = _snap


## Peck is emitted as ordinary attack damage with a strike number, not a separate event.
## The screen asks before applying a pending event so the next Health state waits for its jab.
func damage_wait(event: Dictionary) -> float:
	if (
		Data.s(event, "type") == "damage"
		and Data.s(event, "kind") == "attack"
		and Data.i(event, "source", -1) == _attacker
		and Data.i(event, "strike", 1) > _strike_presented
	):
		_strike_presented = Data.i(event, "strike", 1)
		return 0.12
	if Data.s(event, "type") == "damage" and Data.s(event, "kind") == "attack":
		var source: int = Data.i(event, "source", -1)
		if _joiners.has(source) and not _joiners_landed.has(source):
			_joiners_landed.append(source)
			return 0.04 if _joiners_landed.size() == 1 else 0.03
	return 0.0


func attack(event: Dictionary, animate: bool) -> void:
	if not animate:
		return
	var attacker: CardView = _card(Data.i(event, "attacker", -1))
	var defender: CardView = _card(Data.i(event, "defender", -1))
	if attacker == null or defender == null:
		return
	_source = Data.i(event, "attacker", -1)
	_lunge(attacker, defender, 0)
	var n: int = 0
	for uid: int in Data.a(event, "joiners"):
		var joiner: CardView = _card(uid)
		if joiner != null:
			n += 1
			_lunge(joiner, defender, (_strike_count - 1) * 0.12 + 0.04 + (n - 1) * 0.03)
	_snap = false


func _lunge(attacker: CardView, defender: CardView, delay: float) -> void:
	if Settings.reduce_motion:
		if delay <= 0:
			flash(attacker, UiTheme.ACORN)
		else:
			_tween(attacker).tween_callback(flash.bind(attacker, UiTheme.ACORN)).set_delay(delay)
		var flashes: Tween = _tween(defender)
		flashes.tween_interval(0.15 + precontact_delay + delay)
		flashes.tween_callback(flash.bind(defender, UiTheme.HEALTH))
		if attacker.uid() == _attacker:
			for strike: int in range(1, _strike_count):
				flashes.tween_interval(0.12)
				flashes.tween_callback(flash.bind(defender, UiTheme.HEALTH))
		return
	var home: Vector2 = attacker.position
	var parent: Control = attacker.get_parent() as Control
	var target: Vector2 = (
		parent.get_global_transform().affine_inverse() * defender.get_global_rect().get_center()
	)
	var direction: float = signf(home.y - target.y)
	# The leading edge crosses the target's near edge by 15% of the tile height.
	var end: Vector2 = (
		target - attacker.card_size / 2.0 + Vector2(0, direction * attacker.card_size.y * 0.85)
	)
	attacker.z_index = 10
	parent.z_index = 8
	attacker.pivot_offset = attacker.card_size / 2.0
	var tween: Tween = _tween(attacker)
	if delay > 0:
		tween.tween_interval(delay)
	if not _active_snap:
		tween.tween_property(attacker, "scale", Vector2.ONE * 1.1, 0.1 / _speed())
	if precontact_delay > 0:
		tween.tween_interval(precontact_delay)
	(
		tween
		. tween_property(
			attacker, "position", end, maxf(0.1, (0.12 if _active_snap else 0.16) / _speed())
		)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	tween.tween_callback(_shake.bind(defender))
	if attacker.uid() == _attacker:
		for strike: int in range(1, _strike_count):
			tween.tween_interval(0.04)
			tween.tween_property(attacker, "position", end + Vector2(0, direction * 24), 0.04)
			tween.tween_property(attacker, "position", end, 0.04)
			tween.tween_callback(_shake.bind(defender))
	tween.tween_interval(maxf(0.04, 0.05 / _speed()))
	tween.tween_property(attacker, "position", home, maxf(0.12, 0.2 / _speed()))
	tween.parallel().tween_property(attacker, "scale", Vector2.ONE, maxf(0.12, 0.2 / _speed()))
	tween.chain().tween_callback(
		func() -> void:
			if is_instance_valid(attacker):
				attacker.z_index = 0
				parent.z_index = 0
	)


func _shake(node: Control) -> void:
	if Settings.reduce_motion or not is_instance_valid(node):
		return
	var tween: Tween = _tween(node)
	tween.tween_property(node, "rotation", 0.055, 0.04)
	tween.tween_property(node, "rotation", -0.055, 0.04)
	tween.tween_property(node, "rotation", 0.0, 0.04)


func change(event: Dictionary, animate: bool) -> void:
	if not animate:
		return
	var uid: int = Data.i(event, "target", -1)
	var card: CardView = _card(uid)
	if card == null:
		return
	match Data.s(event, "type"):
		"damage":
			_damage(card, event)
		"health_loss":
			_emit("berry", card.health_bead().get_global_rect().get_center(), UiTheme.NIGHTSHADE)
			_pulse(card.health_bead(), UiTheme.NIGHTSHADE)
		"stats":
			var sources: Array[int] = []
			var direct: int = Data.i(event, "source", -1)
			if direct >= 0:
				sources.append(direct)
			for cause: Dictionary in Data.a(event, "causes"):
				var emitter: int = Data.i(cause, "source", -1)
				if emitter >= 0 and not sources.has(emitter):
					sources.append(emitter)
			_source = sources[0] if not sources.is_empty() else -1
			var delay: float = stat_delay(uid)
			for stat: String in ["attack", "health"]:
				var amount: int = Data.i(event, stat + "_delta")
				if amount != 0:
					var bead: Control = (
						card.attack_bead() if stat == "attack" else card.health_bead()
					)
					var colour: Color = UiTheme.MOSS if amount > 0 else UiTheme.HEALTH
					_tween(bead).tween_callback(_pulse.bind(bead, colour)).set_delay(delay)
			for emitter: int in sources:
				_source = emitter
				var origin: CardView = _card(emitter)
				if origin != null:
					flash(origin, UiTheme.ACORN)
					_pulse(origin.trigger_glyph())
				_mote_from_source(card)
			if not sources.is_empty():
				_source = sources[0]
			if Data.b(event, "permanent"):
				(
					_tween(card)
					. tween_callback(
						_emit.bind("spark", card.get_global_rect().get_center(), UiTheme.GILT)
					)
					. set_delay(delay)
				)
		"status":
			if Data.s(event, "status") == "shield" and not Data.b(event, "on", true):
				for i: int in 5:
					_emit(
						"spark",
						card.get_global_rect().get_center() + Vector2.from_angle(i * TAU / 5) * 48,
						UiTheme.FROST
					)
			else:
				flash(card, UiTheme.status_colour(Data.s(event, "status")))
			_mote_from_source(card)
		"kiss":
			var point: Vector2 = _last_death()
			_mote(point, card.get_global_rect().get_center(), "heart", UiTheme.HEALTH)
			_pulse(card.trigger_glyph())


func stat_delay(uid: int) -> float:
	return 0.22 if _source >= 0 and _source != uid else 0.0


func _hop(card: CardView) -> void:
	if Settings.reduce_motion:
		flash(card, UiTheme.ACORN)
		return
	var home: float = card.position.y
	var tween: Tween = _tween(card)
	tween.tween_property(card, "position:y", home - 10, 0.1)
	tween.tween_property(card, "position:y", home, 0.15)


func _damage(card: CardView, event: Dictionary) -> void:
	var amount: int = Data.i(event, "amount")
	var modifiers: Array = Data.a(event, "modifiers")
	var before_pop: float = 0.0
	if modifiers.has("hunker"):
		before_pop = 0.1
		if Settings.reduce_motion:
			flash(card, UiTheme.MUTE)
		else:
			var crouch: Tween = _tween(card)
			crouch.tween_property(card, "scale:y", 0.9, 0.05)
			crouch.tween_property(card, "scale:y", 1.0, 0.1)
	if modifiers.has("damage_reduction"):
		before_pop = 0.1
		flash(card, UiTheme.MUTE)
		_emit("puff", card.health_bead().get_global_rect().get_center(), UiTheme.MUTE)
	if Data.s(event, "kind") == "thorns":
		before_pop = 0.12
		var source: CardView = _card(Data.i(event, "source", -1))
		if source != null:
			_thorns(source, card)
		else:
			_emit("fang", card.get_global_rect().get_center(), UiTheme.MOSS)
	if modifiers.has("cleave"):
		_shake(card)
		var source: CardView = _card(Data.i(event, "source", -1))
		if source != null and not Settings.reduce_motion:
			var sweep: Tween = _tween(source)
			sweep.tween_property(source, "rotation", 0.13, 0.05)
			sweep.tween_property(source, "rotation", -0.13, 0.05)
			sweep.tween_property(source, "rotation", 0.0, 0.05)
	if amount > 0:
		var group: String = ""
		if not _joiners.is_empty() and Data.s(event, "kind") == "attack":
			group = "%d:%d" % [card.uid(), Data.i(event, "strike", 1)]
		if before_pop > 0:
			_tween(card).tween_callback(_damage_pop.bind(card, amount, group)).set_delay(before_pop)
		else:
			_damage_pop(card, amount, group)


func _damage_pop(card: CardView, amount: int, group: String = "") -> void:
	if not is_instance_valid(card):
		return
	_burst(card.health_bead().get_global_rect().get_center(), amount, group)
	_pulse(card.health_bead(), UiTheme.HEALTH)
	_shake(card)


func _thorns(source: CardView, target: CardView) -> void:
	var from: Vector2 = source.get_global_rect().get_center()
	var to: Vector2 = target.get_global_rect().get_center()
	if Settings.reduce_motion:
		_emit("fang", from, UiTheme.MOSS)
		flash(target, UiTheme.MOSS)
		return
	var direction: Vector2 = (to - from).normalized()
	var mark: TextureRect = _icon("fang", from + direction * 55, 64, UiTheme.MOSS)
	mark.rotation = direction.angle() - PI / 2.0
	var tween: Tween = _tween(mark)
	tween.tween_property(mark, "position", mark.position + direction * 35, 0.12)
	tween.tween_property(mark, "modulate:a", 0.0, 0.1)
	tween.tween_callback(mark.queue_free)


func _mote_from_source(target: CardView) -> void:
	var source: CardView = _card(_source)
	if source == target and source != null:
		_mote(
			source.trigger_glyph().get_global_rect().get_center(),
			target.attack_bead().get_global_rect().get_center(),
			"spark",
			UiTheme.ACORN
		)
	elif source != null:
		_mote(
			source.get_global_rect().get_center(),
			target.get_global_rect().get_center(),
			"spark",
			UiTheme.ACORN
		)
	elif source == null and _source >= 0:
		var view: Dictionary = _model().unit(_source)
		if not view.is_empty() and not Data.b(view, "alive", true):
			var board: BoardView = _screen.call("board_for_side", Data.i(view, "side"))
			_mote(
				board.slot_global_center(Data.i(view, "slot")),
				target.get_global_rect().get_center(),
				"bones",
				UiTheme.ACORN
			)


func _burst(point: Vector2, amount: int, group: String = "") -> void:
	if not group.is_empty() and _burst_groups.has(group):
		var active: Dictionary = _burst_groups[group]
		var existing: Variant = active.get("node")
		if is_instance_valid(existing):
			var previous: TextureRect = existing
			var label: Label = previous.get_node("Amount")
			active["amount"] = Data.i(active, "amount") + amount
			label.text = "−%d" % Data.i(active, "amount")
			return
	var side: float = 96.0 + minf(24, floorf(log(maxi(1, amount)) / log(10.0)) * 8)
	var mark: TextureRect = _icon("burst", point, side, Color.WHITE)
	var number := UiTheme.number("−%d" % amount, 52, UiTheme.CREAM)
	number.name = "Amount"
	number.add_theme_color_override("font_outline_color", UiTheme.INK)
	number.add_theme_constant_override("outline_size", 6)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.size = mark.size
	mark.add_child(number)
	if not group.is_empty():
		_burst_groups[group] = {"node": mark, "amount": amount}
	var tween: Tween = _tween(mark)
	if not Settings.reduce_motion:
		mark.scale = Vector2.ONE * 0.4
		tween.tween_property(mark, "scale", Vector2.ONE * 1.15, 0.06)
		tween.tween_property(mark, "scale", Vector2.ONE, 0.06)
	tween.tween_interval(0.25)
	tween.tween_property(mark, "modulate:a", 0.0, 0.15)
	tween.tween_callback(mark.queue_free)


func _icon(key: String, point: Vector2, side: float, colour: Color) -> TextureRect:
	var mark := TextureRect.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.texture = Icons.icon(key, side)
	mark.size = Vector2.ONE * side
	mark.pivot_offset = mark.size / 2
	mark.self_modulate = colour
	var overlay: Control = _screen.get("_overlay")
	overlay.add_child(mark)
	mark.position = overlay.get_global_transform().affine_inverse() * point - mark.size / 2
	return mark


func _emit(key: String, point: Vector2, colour: Color) -> void:
	var mark: TextureRect = _icon(key, point, 54, colour)
	var tween: Tween = _tween(mark)
	if not Settings.reduce_motion:
		tween.tween_property(mark, "scale", Vector2.ONE * 1.3, 0.12)
	tween.tween_property(mark, "modulate:a", 0.0, 0.15)
	tween.tween_callback(mark.queue_free)


func _mote(from: Vector2, to: Vector2, key: String, colour: Color) -> void:
	if Settings.reduce_motion:
		_emit(key, from, colour)
		_tween().tween_callback(_emit.bind(key, to, colour)).set_delay(0.15)
		return
	var mark: TextureRect = _icon(key, from, 44, colour)
	var overlay: Control = _screen.get("_overlay")
	var end: Vector2 = overlay.get_global_transform().affine_inverse() * to - mark.size / 2
	var tween: Tween = _tween(mark)
	tween.tween_property(mark, "position", (mark.position + end) / 2 - Vector2(0, 25), 0.11)
	tween.tween_property(mark, "position", end, 0.11)
	tween.tween_property(mark, "modulate:a", 0.0, 0.1)
	tween.tween_callback(mark.queue_free)


func die(card: CardView) -> void:
	var tween: Tween = _tween(card)
	tween.tween_interval(0.15)
	if Data.s(card.unit, "text").to_lower().contains("when this dies"):
		tween.tween_callback(_pulse.bind(card.trigger_glyph()))
	if not Settings.reduce_motion:
		tween.tween_callback(_emit.bind("leaf", card.get_global_rect().get_center(), UiTheme.MOSS))
		tween.tween_property(card, "position:y", card.position.y + 44, 0.2)
		tween.parallel().tween_property(card, "rotation", 0.3, 0.2)
	tween.tween_property(card, "modulate:a", 0.0, 0.15)
	tween.tween_callback(card.queue_free)


func arrive(card: CardView, event: Dictionary, animate: bool) -> void:
	if not animate:
		return
	flash(card, UiTheme.MOSS)
	if Settings.reduce_motion:
		return
	var start: Vector2 = card.position
	var parent: Control = card.get_parent() as Control
	var source: CardView = _card(Data.i(event, "source", -1))
	if source != null:
		start = (
			(parent.get_global_transform().affine_inverse() * source.get_global_rect().get_center())
			- card.size / 2
		)
	else:
		var from: Dictionary = _model().unit(Data.i(event, "source", -1))
		if not from.is_empty():
			var board: BoardView = _screen.call("board_for_side", Data.i(from, "side"))
			start = (
				(
					parent.get_global_transform().affine_inverse()
					* board.slot_global_center(Data.i(from, "slot"))
				)
				- card.size / 2
			)
		else:
			start.y -= 90
	var tween: Tween = _tween(card)
	card.scale = Vector2.ONE * 0.3
	tween.tween_property(card, "position", card.position, 0.3).from(start)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.3)


func gulp(event: Dictionary, animate: bool) -> void:
	Special.present(_screen, event, animate)


func cue(event: Dictionary, animate: bool) -> void:
	if Special.present(_screen, event, animate):
		return
	if not animate:
		return
	var uid: int = Data.i(event, "uid", Data.i(event, "target", -1))
	var card: CardView = _card(uid)
	match Data.s(event, "type"):
		"trigger":
			_source = uid
			if card != null:
				_pulse(card.trigger_glyph())
				_hop(card)
			elif uid >= 0:
				var view: Dictionary = _model().unit(uid)
				if not view.is_empty() and not Data.b(view, "alive", true):
					var board: BoardView = _screen.call("board_for_side", Data.i(view, "side"))
					_emit("bones", board.slot_global_center(Data.i(view, "slot")), UiTheme.ACORN)
		"phase":
			if Data.s(event, "name") in ["bell", "start_of_combat"]:
				_emit("bell", _screen.get_global_rect().get_center(), UiTheme.ACORN)
		"immediate_attack":
			_snap = true
		"quarry_marked":
			var hunter: CardView = _card(Data.i(event, "hunter", -1))
			var prey: CardView = _card(Data.i(event, "quarry", -1))
			if hunter != null and prey != null:
				_pulse(hunter)
				_mote(
					hunter.get_global_rect().get_center(),
					prey.get_global_rect().get_center(),
					"paw",
					UiTheme.ACORN
				)
		"bog_patch", "slot_hex", "slot_mark":
			var board: BoardView = _screen.call("board_for_side", Data.i(event, "side"))
			var point: Vector2 = board.slot_global_center(Data.i(event, "slot"))
			var source: CardView = _card(Data.i(event, "maker", _source))
			var key: String = "hex" if Data.s(event, "type") == "slot_hex" else "splash"
			if source != null:
				_mote(
					source.get_global_rect().get_center(),
					point,
					key,
					UiTheme.NIGHTSHADE if key == "hex" else UiTheme.MOSS
				)
			else:
				_emit(key, point, UiTheme.MOSS)
		"skip", "mire_wait":
			if card != null:
				flash(card, UiTheme.MOSS)
				_shake(card)
		"whistle":
			if card != null:
				_emit("ring", card.get_global_rect().get_center(), UiTheme.ACORN)
			for target: int in Data.a(event, "warned"):
				var warned: CardView = _card(target)
				if warned != null:
					_emit(
						"note", warned.attack_bead().get_global_rect().get_center(), UiTheme.ACORN
					)
		"cancel", "no_room":
			_emit(
				"puff",
				(
					card.get_global_rect().get_center()
					if card != null
					else _screen.get_global_rect().get_center()
				),
				UiTheme.MUTE
			)
		"pass":
			var board: BoardView = _screen.call("board_for_side", Data.i(event, "side"))
			flash(board, UiTheme.MUTE)
		"take", "poach":
			var hunter: CardView = _card(Data.i(event, "hunter", -1))
			if hunter != null:
				var side: int = Data.i(_model().unit(Data.i(event, "hunter")), "side")
				_mote(
					_last_death(),
					_plaque(side).get_global_rect().get_center(),
					"acorn",
					UiTheme.ACORN
				)
		"transform":
			if card != null:
				var tween: Tween = _tween(card)
				tween.tween_property(card, "scale:x", 0.05, 0.15)
				tween.tween_property(card, "scale:x", 1.0, 0.15)
		"text_taken":
			var victim: CardView = _card(Data.i(event, "from", -1))
			if card != null and victim != null:
				_mote(
					victim.trigger_glyph().get_global_rect().get_center(),
					card.trigger_glyph().get_global_rect().get_center(),
					"spark",
					UiTheme.ACORN
				)


func result(animate: bool) -> void:
	var model: CombatModel = _model()
	var plaques: Array = _screen.get("_plaques")
	var health: Array = _screen.get("hero_health")
	var labels: Array = _screen.get("_health_labels")
	var bottom_side: int = CoreUtil.to_int(_screen.get("bottom_side"))
	if not animate:
		return
	var winner: int = model.winner
	if winner < 0:
		for plaque: Control in plaques:
			_pulse(plaque)
		return
	var target: Vector2 = _plaque(1 - winner).get_global_rect().get_center()
	for uid: int in _screen.get("_cards"):
		var view: Dictionary = model.unit(uid)
		if Data.i(view, "side") == winner and Data.i(view, "starting_side", -1) == winner:
			_mote(_card(uid).get_global_rect().get_center(), target, "spark", UiTheme.ACORN)
	var base: Vector2 = _plaque(winner).get_global_rect().get_center()
	if Data.b(model.result_rules, "last_blow"):
		var source: Dictionary = model.unit(Data.i(model.result_rules, "last_blow_source", -1))
		if not source.is_empty():
			var board: BoardView = _screen.call("board_for_side", Data.i(source, "side"))
			base = board.slot_global_center(Data.i(source, "slot"))
	if not model.result_rules.has("damage_base") or Data.i(model.result_rules, "damage_base") > 0:
		_mote(base, target, "spark", UiTheme.ACORN)
	_tween().tween_callback(_burst.bind(target, model.damage)).set_delay(0.3)
	_shake(_plaque(1 - winner))
	var old_health: int = CoreUtil.to_int(health[1 - winner])
	if old_health >= 0:
		var after: int = maxi(0, old_health - model.damage)
		var final_health: Array = _screen.get("hero_health_after")
		if final_health.size() > 1 - winner:
			after = CoreUtil.to_int(final_health[1 - winner])
		if Data.a(model.result_rules, "last_stand_sides").has(1 - winner):
			after = 1
			_emit("ring", target, UiTheme.GILT)
		var label: Label = labels[1 - winner]
		var tween: Tween = _tween(label)
		tween.tween_interval(0.3)
		tween.tween_method(
			func(value: int) -> void: label.text = str(value), old_health, after, 0.25
		)
	if model.early_spoils.has(bottom_side):
		_emit("acorn", _plaque(bottom_side).get_global_rect().get_center(), UiTheme.ACORN)
