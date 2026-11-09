extends RefCounted
## Deterministic fight cues. Durations are real seconds, with a travel/contact floor at ×4.

const EffectPath := preload("res://src/ui/widgets/combat_effect_path.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const AttackCue := preload("res://src/ui/widgets/combat_attack_cue.gd")
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
var _hero_source: int = -1
var _pocket_source: bool = false
var _active_snap: bool = false
var _attacker: int = -1
var _strike_count: int = 1
var _strike_presented: int = 1
var _joiners: Array[int] = []
var _joiners_landed: Array[int] = []
var _held_sources: Array[Control] = []
var _lunges: Dictionary[int, Tween] = {}


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
	_hero_source = -1
	_attacker = Data.i(event, "attacker", -1)
	_strike_count = maxi(1, Data.i(event, "strikes", 1))
	_strike_presented = 1
	_joiners.clear()
	_joiners_landed.clear()
	_clear_attack_sources()
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
	_hold_attack_source(attacker)
	_lunge(attacker, defender, 0)
	var n: int = 0
	for uid: int in Data.a(event, "joiners"):
		var joiner: CardView = _card(uid)
		if joiner != null:
			_hold_attack_source(joiner)
			n += 1
			_lunge(joiner, defender, (_strike_count - 1) * 0.12 + 0.04 + (n - 1) * 0.03)
	_snap = false


func _hold_attack_source(card: CardView) -> void:
	var mark := AttackCue.new()
	mark.actor_uid = card.uid()
	mark.toward_top = Data.i(card.unit, "side") == CoreUtil.to_int(_screen.get("bottom_side"))
	var overlay: Control = _screen.get("_overlay")
	overlay.add_child(mark)
	var rect: Rect2 = card.get_global_rect().grow(6)
	mark.position = overlay.get_global_transform().affine_inverse() * rect.position
	mark.size = rect.size
	_held_sources.append(mark)


func _clear_attack_sources() -> void:
	for value: Variant in _held_sources:
		if is_instance_valid(value):
			var mark: Control = value
			mark.hide()
			mark.queue_free()
	_held_sources.clear()


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
	_lunges[attacker.uid()] = tween
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
			_pocket_source = false
			var sources: Array[int] = []
			var direct: int = Data.i(event, "source", -1)
			if _model().units.has(direct):
				sources.append(direct)
			for cause: Dictionary in Data.a(event, "causes"):
				_pocket_source = _pocket_source or Data.s(cause, "name") == "Ring"
				var emitter: int = Data.i(cause, "source", -1)
				if _model().units.has(emitter) and not sources.has(emitter):
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
				_source_pulse(emitter)
				for stat: String in ["attack", "health"]:
					if Data.i(event, stat + "_delta") == 0:
						continue
					var bead: Control = (
						card.attack_bead() if stat == "attack" else card.health_bead()
					)
					var colour: Color = (
						UiTheme.MOSS if Data.i(event, stat + "_delta") > 0 else UiTheme.HEALTH
					)
					var mote: Control = _mote(
						_unit_point(emitter), bead.get_global_rect().get_center(), "spark", colour
					)
					mote.set_meta("effect_source_uid", emitter)
					mote.set_meta("effect_target_uid", uid)
					mote.set_meta("effect_stat", stat)

			if sources.is_empty() and _hero_source >= 0 and not _pocket_source:
				_hero_stat_effect(card, event)
			elif sources.is_empty():
				# A Ring belongs to this pocket; it is not the preceding hero or unit trigger.
				for cause: Dictionary in Data.a(event, "causes"):
					if Data.s(cause, "name") == "Ring":
						var foot: Vector2 = _unit_point(uid) + Vector2(0, card.size.y * 0.45)
						_mote(
							foot,
							card.attack_bead().get_global_rect().get_center(),
							"ring",
							UiTheme.ACORN
						)
						_mote(
							foot,
							card.health_bead().get_global_rect().get_center(),
							"ring",
							UiTheme.ACORN
						)
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
			var source: int = Data.i(event, "source", _source)
			if _model().units.has(source):
				_source_pulse(source)
				_mote(
					_unit_point(source),
					card.get_global_rect().get_center(),
					"splash" if Data.s(event, "status") == "mired" else "spark",
					UiTheme.ACORN
				)
		"kiss":
			var point: Vector2 = _last_death()
			_mote(point, card.get_global_rect().get_center(), "heart", UiTheme.HEALTH)
			_pulse(card.trigger_glyph())


func _hero_stat_effect(card: CardView, event: Dictionary) -> void:
	var hero: Control = _plaque(_hero_source)
	flash(hero, UiTheme.ACORN)
	for stat: String in ["attack", "health"]:
		if Data.i(event, stat + "_delta") != 0:
			var bead: Control = card.attack_bead() if stat == "attack" else card.health_bead()
			var mote: Control = _mote(
				hero.get_global_rect().get_center(),
				bead.get_global_rect().get_center(),
				"spark",
				UiTheme.MOSS
			)
			mote.set_meta("effect_source_side", _hero_source)
			mote.set_meta("effect_target_uid", card.uid())


func stat_delay(_uid: int) -> float:
	return 0.35 if _source >= 0 or _hero_source >= 0 or _pocket_source else 0.0


func _unit_point(uid: int) -> Vector2:
	var card: CardView = _card(uid)
	if card != null:
		return card.get_global_rect().get_center() - Vector2(0, card.size.y * 0.12)
	var view: Dictionary = _model().unit(uid)
	if not view.is_empty():
		var board: BoardView = _screen.call("board_for_side", Data.i(view, "side"))
		return board.slot_global_center(Data.i(view, "slot"))
	return _screen.get_global_rect().get_center()


func _effect_barrier(seconds: float) -> void:
	_screen.set(
		"_effect_remaining", maxf(CoreUtil.to_float(_screen.get("_effect_remaining")), seconds)
	)


func _source_pulse(uid: int) -> void:
	var card: CardView = _card(uid)
	if card == null and not _model().unit(uid).is_empty():
		_remember_unit(uid)
	if card != null:
		var pulse: Tween = _tween(card)
		pulse.tween_property(card, "modulate", Color(1.6, 1.4, 1.1), 0.04)
		pulse.tween_interval(0.7)
		pulse.tween_property(card, "modulate", Color.WHITE, 0.11)
		_pulse(card.trigger_glyph())
	var halo: TextureRect = _icon("ring", _unit_point(uid), 104, Color.WHITE)
	halo.name = "TriggerSource_%d" % uid
	halo.set_meta("effect_source_uid", uid)
	var tween: Tween = _tween(halo)
	tween.tween_interval(0.75)
	tween.tween_property(halo, "modulate:a", 0.0, 0.15)
	tween.tween_callback(halo.queue_free)


## A portrait echo identifies a dead source without returning a live tile to its pocket.
func _remember_unit(uid: int) -> Control:
	var view: Dictionary = _model().unit(uid)
	var echo := Control.new()
	echo.name = "DeadSource_%d" % uid
	echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	echo.set_meta("dead_source_uid", uid)
	var overlay: Control = _screen.get("_overlay")
	overlay.add_child(echo)
	echo.size = Vector2(160, 160)
	echo.position = (
		overlay.get_global_transform().affine_inverse() * _unit_point(uid) - echo.size / 2
	)
	var art := ArtFrame.new()
	art.texture = UiTheme.portrait_for(Data.s(view, "def_id"), Data.a(view, "tribes"))
	art.position = Vector2(32, 0)
	art.size = Vector2(96, 96)
	art.modulate = Color(1.4, 1.2, 0.9)
	echo.add_child(art)
	var tween: Tween = _tween(echo)
	tween.tween_interval(0.85)
	tween.tween_property(echo, "modulate:a", 0.0, 0.15)
	tween.tween_callback(echo.queue_free)
	return echo


func _permanent_reward(event: Dictionary) -> void:
	var source: int = Data.i(event, "source", -1)
	var target: int = Data.i(event, "target", source)
	if _model().unit(target).is_empty():
		return
	_source_pulse(source)
	var echo: Control = _remember_unit(target)
	for stat: String in ["attack", "health"]:
		var delta: int = Data.i(event, stat + "_delta")
		if delta == 0:
			continue
		var bead := ShapeBadge.new("nut" if stat == "attack" else "rosehip")
		bead.name = "Reward_" + stat
		bead.position = Vector2(0 if stat == "attack" else 96, 96)
		bead.size = Vector2(64, 64)
		echo.add_child(bead)
		bead.hide()
		var number := UiTheme.number("%+d" % delta, UiTheme.MIN_FONT, UiTheme.CREAM)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.size = bead.size
		bead.add_child(number)
		var mote: Control = _mote(
			_unit_point(source),
			bead.get_global_rect().get_center(),
			"spark" if stat == "attack" else "heart",
			UiTheme.ACORN if stat == "attack" else UiTheme.HEALTH
		)
		mote.set_meta("effect_source_uid", source)
		mote.set_meta("effect_target_uid", target)
		mote.set_meta("effect_stat", stat)
		var landing: Tween = _tween(bead)
		landing.tween_interval(0.35)
		landing.tween_callback(bead.show)
		landing.tween_callback(_pulse.bind(bead))
	_effect_barrier(0.85)


func _take(event: Dictionary) -> void:
	var hunter: int = Data.i(event, "hunter", -1)
	var quarry: int = Data.i(event, "quarry", -1)
	var view: Dictionary = _model().unit(hunter)
	if view.is_empty():
		return
	_source_pulse(hunter)
	var hunter_point: Vector2 = _unit_point(hunter)
	var quarry_point: Vector2 = _unit_point(quarry)
	var claim: Control = _mote(hunter_point, quarry_point, "paw", UiTheme.ACORN, 0.18)
	claim.set_meta("effect_source_uid", hunter)
	claim.set_meta("take_quarry_uid", quarry)
	claim.set_meta("quarry_point", quarry_point)
	(
		_tween()
		. tween_callback(_mote.bind(quarry_point, hunter_point, "acorn", Color.WHITE, 0.18))
		. set_delay(0.18)
	)
	var hero: Control = _plaque(Data.i(view, "side"))
	var hero_point: Vector2 = hero.get_global_rect().get_center() + Vector2(0, hero.size.y * 0.8)
	(
		_tween()
		. tween_callback(_mote.bind(hunter_point, hero_point, "acorn", Color.WHITE, 0.22))
		. set_delay(0.36)
	)
	_effect_barrier(1.2)


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
		var offset := Vector2.ZERO
		var source: int = Data.i(event, "source", -1)
		if not _joiners.is_empty() and Data.s(event, "kind") == "attack":
			if source == _attacker:
				offset.y = -76
			elif _joiners.has(source):
				offset.y = _joiners.find(source) * 76
		if before_pop > 0:
			_tween(card).tween_callback(_damage_pop.bind(card, amount, offset)).set_delay(
				before_pop
			)
		else:
			_damage_pop(card, amount, offset)


func _damage_pop(card: CardView, amount: int, offset: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(card):
		return
	var pop: TextureRect = _burst(
		card.health_bead().get_global_rect().get_center() + offset, amount
	)
	pop.name = "DamagePop"
	pop.set_meta("recipient_uid", card.uid())
	pop.reparent(card)
	pop.position = card.health_bead().position + card.health_bead().size / 2 + offset - pop.size / 2
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


func _burst(point: Vector2, amount: int) -> TextureRect:
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
	var tween: Tween = _tween(mark)
	if not Settings.reduce_motion:
		mark.scale = Vector2.ONE * 0.4
		tween.tween_property(mark, "scale", Vector2.ONE * 1.15, 0.06)
		tween.tween_property(mark, "scale", Vector2.ONE, 0.06)
	tween.tween_interval(0.25)
	tween.tween_property(mark, "modulate:a", 0.0, 0.15)
	tween.tween_callback(mark.queue_free)
	return mark


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


func _mote(from: Vector2, to: Vector2, key: String, colour: Color, travel: float = 0.35) -> Control:
	var mark: TextureRect = _icon(key, from, 88 if key == "acorn" else 52, colour)
	var overlay: Control = _screen.get("_overlay")
	var path := EffectPath.new()
	path.name = "EffectRoute"
	path.from_point = overlay.get_global_transform().affine_inverse() * from
	path.to_point = overlay.get_global_transform().affine_inverse() * to
	path.colour = colour
	overlay.add_child(path)
	overlay.move_child(path, maxi(0, overlay.get_child_count() - 2))
	var route: Tween = _tween(path)
	if Settings.reduce_motion:
		path.progress = 1.0
		route.tween_interval(travel)
	else:
		route.tween_property(path, "progress", 1.0, travel)
	route.tween_interval(0.6)
	route.tween_property(path, "modulate:a", 0.0, 0.15)
	route.tween_callback(path.queue_free)
	mark.set_meta("effect_from", from)
	mark.set_meta("effect_to", to)
	var tween: Tween = _tween(mark)
	if Settings.reduce_motion:
		var landing: TextureRect = _icon(key, to, 88 if key == "acorn" else 52, colour)
		landing.hide()
		var target: Tween = _tween(landing)
		target.tween_interval(travel)
		target.tween_callback(landing.show)
		target.tween_interval(0.7 if key == "acorn" else 0.6)
		target.tween_property(landing, "modulate:a", 0.0, 0.15)
		target.tween_callback(landing.queue_free)
		tween.tween_interval(travel)
	else:
		var end: Vector2 = overlay.get_global_transform().affine_inverse() * to - mark.size / 2
		tween.tween_property(
			mark, "position", (mark.position + end) / 2 - Vector2(0, 28), travel / 2
		)
		tween.tween_property(mark, "position", end, travel / 2)
	tween.tween_interval(0.7 if key == "acorn" else (0.6 if Settings.reduce_motion else 0.25))
	tween.tween_property(mark, "modulate:a", 0.0, 0.15)
	tween.tween_callback(mark.queue_free)
	return mark


func die(card: CardView) -> void:
	# Stop the return tween before fading: two position writers looked like a second hit.
	var lunge: Tween = _lunges.get(card.uid())
	if lunge != null and lunge.is_valid():
		lunge.kill()
	var board: BoardView = _screen.call("board_for_side", Data.i(card.unit, "side"))
	card.position = board.card_position(Data.i(card.unit, "slot"))
	card.scale = Vector2.ONE
	card.z_index = 0
	var parent: Control = card.get_parent() as Control
	parent.z_index = 0
	var tween: Tween = _tween(card)
	tween.tween_interval(0.15)
	if Data.s(card.unit, "text").to_lower().contains("when this dies"):
		tween.tween_callback(_pulse.bind(card.trigger_glyph()))
	if not Settings.reduce_motion:
		tween.tween_callback(_emit.bind("leaf", card.get_global_rect().get_center(), UiTheme.MOSS))
	tween.tween_property(card, "modulate:a", 0.0, 0.3)
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
	if animate and Data.s(event, "type") in ["mire_wait", "skip"]:
		var waiting: int = Data.i(event, "uid", -1)
		var unit: CardView = _card(waiting)
		if unit != null:
			_source_pulse(waiting)
			var foot: Vector2 = (
				unit.get_global_rect().get_center() + Vector2(0, unit.size.y / 2 - 10)
			)
			_mote(_unit_point(waiting), foot, "pause", UiTheme.MOSS)
			_effect_barrier(0.8)
		if Data.s(event, "type") == "mire_wait":
			return
	if Special.present(_screen, event, animate):
		return
	if not animate:
		return
	var uid: int = Data.i(event, "uid", Data.i(event, "target", -1))
	var card: CardView = _card(uid)
	match Data.s(event, "type"):
		"permanent_reward":
			_permanent_reward(event)
		"side_trigger":
			_hero_source = Data.i(event, "side", -1)
			_source = -1
		"trigger":
			_hero_source = -1
			_source = uid
			_source_pulse(uid)
			if card != null:
				_hop(card)
			_effect_barrier(0.5)
		"phase":
			if Data.s(event, "name") in ["bell", "start_of_combat"]:
				_emit("bell", _screen.get_global_rect().get_center(), UiTheme.ACORN)
		"immediate_attack":
			_snap = true
			var source: int = Data.i(event, "attacker", -1)
			_source_pulse(source)
			var mote: Control = _mote(
				_unit_point(source),
				_unit_point(Data.i(event, "defender", -1)),
				"spark",
				UiTheme.ACORN
			)
			mote.set_meta("effect_source_uid", source)
			mote.set_meta("effect_target_uid", Data.i(event, "defender", -1))
			_effect_barrier(0.5)
		"quarry_marked":
			var hunter: int = Data.i(event, "hunter", -1)
			var maker: int = Data.i(event, "source", hunter)
			_source_pulse(maker)
			_mote(_unit_point(maker), _unit_point(hunter), "paw", UiTheme.ACORN, 0.2)
			_mote(
				_unit_point(hunter), _unit_point(Data.i(event, "quarry", -1)), "paw", UiTheme.ACORN
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
			_take(event)
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
	_clear_attack_sources()
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
