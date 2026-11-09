extends RefCounted
## Event-specific fight motion. Every tween belongs to the screen's deterministic clock.

const EffectPath := preload("res://src/ui/widgets/combat_effect_path.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const Data := preload("res://src/ui/view_data.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const Settings := preload("res://src/ui/settings.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


## The caller has applied the event model. Gulp runs before the original victim is removed.
## Transform also receives the old target snapshot in screen._event_before.
static func present(screen: Control, event: Dictionary, animate: bool) -> bool:
	var kind: String = Data.s(event, "type")
	if (
		kind
		not in [
			"swallowed", "whistle", "cancel", "skip", "mire_wait", "pass", "no_room", "transform"
		]
	):
		return false
	if not animate:
		return true
	match kind:
		"swallowed":
			_gulp(screen, event)
		"whistle":
			_whistle(screen, event)
		"cancel":
			_cancel(screen, event)
		"skip", "mire_wait":
			_skip(screen, event)
		"pass":
			_pass(screen, event)
		"no_room":
			_no_room(screen, event)
		"transform":
			_transform(screen, event)
	return true


static func _card(screen: Control, uid: int) -> CardView:
	var cards: Dictionary = screen.get("_cards")
	var card: CardView = cards.get(uid)
	return card


static func _model(screen: Control) -> CombatModel:
	var model: CombatModel = screen.get("model")
	return model


static func _overlay(screen: Control) -> Control:
	var overlay: Control = screen.get("_overlay")
	return overlay


static func _tween(screen: Control, node: Node = null) -> Tween:
	var tween: Tween = screen.call("_tween")
	if node != null:
		tween.bind_node(node)
	return tween


static func _local(screen: Control, point: Vector2) -> Vector2:
	return _overlay(screen).get_global_transform().affine_inverse() * point


static func _point(screen: Control, uid: int) -> Vector2:
	var card: CardView = _card(screen, uid)
	if card != null:
		return card.get_global_rect().get_center()
	var view: Dictionary = _model(screen).unit(uid)
	if not view.is_empty():
		var board: BoardView = screen.call("board_for_side", Data.i(view, "side"))
		return board.slot_global_center(Data.i(view, "slot"))
	return screen.get_global_rect().get_center()


static func _icon(screen: Control, key: String, point: Vector2, side: float) -> TextureRect:
	var mark: TextureRect = TextureRect.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.texture = Icons.icon(key, side)
	mark.size = Vector2.ONE * side
	mark.pivot_offset = mark.size / 2.0
	_overlay(screen).add_child(mark)
	mark.position = _local(screen, point) - mark.size / 2.0
	return mark


static func _flash(screen: Control, node: Control, colour: Color) -> void:
	if not is_instance_valid(node):
		return
	var tween: Tween = _tween(screen, node)
	tween.tween_property(node, "modulate", Color.WHITE.lerp(colour, 0.2) * 1.5, 0.075)
	tween.tween_property(node, "modulate", Color.WHITE, 0.075)


static func _pulse(screen: Control, node: Control, colour: Color) -> void:
	if not is_instance_valid(node):
		return
	_flash(screen, node, colour)
	if Settings.reduce_motion:
		return
	var home: Vector2 = node.scale
	node.pivot_offset = node.size / 2.0
	var tween: Tween = _tween(screen, node)
	tween.tween_property(node, "scale", home * 1.3, 0.075)
	tween.tween_property(node, "scale", home, 0.125)


static func _gulp(screen: Control, event: Dictionary) -> void:
	var victim: CardView = _card(screen, Data.i(event, "uid", -1))
	var holder: CardView = _card(screen, Data.i(event, "by", -1))
	if victim == null or holder == null:
		return
	# A separate visual survives the model's immediate removal of the swallowed unit.
	var swallowed: CardView = CardView.new()
	swallowed.combat_face = true
	swallowed.show_unit(victim.unit.duplicate(true), CardView.Mode.BOARD)
	swallowed.set_card_size(victim.card_size)
	swallowed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay(screen).add_child(swallowed)
	swallowed.position = _local(screen, victim.get_global_rect().get_center()) - swallowed.size / 2
	swallowed.pivot_offset = swallowed.size / 2.0
	var tween: Tween = _tween(screen, swallowed)
	if Settings.reduce_motion:
		_flash(screen, swallowed, UiTheme.ACORN)
		tween.tween_property(swallowed, "modulate:a", 0.0, 0.15)
	else:
		var destination: Vector2 = _local(screen, holder.get_global_rect().get_center())
		tween.tween_property(swallowed, "position", destination - swallowed.size / 2.0, 0.25)
		tween.parallel().tween_property(swallowed, "scale", Vector2.ONE * 0.05, 0.25)
	tween.tween_callback(swallowed.queue_free)
	tween.tween_callback(_gulp_landed.bind(screen, holder))


static func _gulp_landed(screen: Control, holder: CardView) -> void:
	if not is_instance_valid(holder):
		return
	_flash(screen, holder, UiTheme.ACORN)
	var marks: Control = holder.get("_combat_marks")
	var counter: Label = marks.get("counter")
	_pulse(screen, counter, UiTheme.ACORN)
	if Settings.reduce_motion:
		return
	var home: Vector2 = holder.scale
	var bulge: Tween = _tween(screen, holder)
	bulge.tween_property(holder, "scale", home * 1.15, 0.05)
	bulge.tween_property(holder, "scale", home, 0.1)


static func _whistle(screen: Control, event: Dictionary) -> void:
	var uid: int = Data.i(event, "uid", -1)
	var source: CardView = _card(screen, uid)
	var centre: Vector2 = _point(screen, uid)
	if source != null:
		_flash(screen, source.trigger_glyph(), UiTheme.ACORN)
	var ring: TextureRect = _icon(screen, "ring", centre, 108)
	var tween: Tween = _tween(screen, ring)
	if Settings.reduce_motion:
		tween.tween_property(ring, "modulate:a", 0.0, 0.15)
	else:
		ring.scale = Vector2.ONE * 0.2
		tween.tween_property(ring, "scale", Vector2.ONE * 1.65, 0.3)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ring.queue_free)
	for target: int in Data.a(event, "warned"):
		var warned: CardView = _card(screen, target)
		if warned != null:
			_note(screen, centre, warned)


static func _note(screen: Control, from: Vector2, warned: CardView) -> void:
	var bead: Control = warned.attack_bead()
	var end: Vector2 = _local(screen, bead.get_global_rect().get_center()) - Vector2(22, 22)
	var mark: TextureRect = _icon(screen, "note", from, 44)
	var tween: Tween = _tween(screen, mark)
	if Settings.reduce_motion:
		mark.hide()
		mark.position = end
		tween.tween_interval(0.15)
		tween.tween_callback(mark.show)
	else:
		tween.tween_property(mark, "position", end, 0.25)
	tween.tween_callback(_flash.bind(screen, bead, UiTheme.ACORN))
	tween.tween_property(mark, "modulate:a", 0.0, 0.1)
	tween.tween_callback(mark.queue_free)


static func _smoke(screen: Control, point: Vector2, duration: float = 0.2) -> void:
	for index: int in 3:
		var mark: TextureRect = _icon(screen, "puff", point + Vector2((index - 1) * 10, 0), 40)
		mark.self_modulate = UiTheme.MUTE
		var tween: Tween = _tween(screen, mark)
		if not Settings.reduce_motion:
			tween.tween_property(
				mark, "position", mark.position + Vector2((index - 1) * 15, -14), duration
			)
			tween.parallel().tween_property(mark, "scale", Vector2.ONE * 1.3, duration)
			tween.parallel().tween_property(mark, "modulate:a", 0.0, duration)
		else:
			tween.tween_property(mark, "modulate:a", 0.0, 0.15)
		tween.tween_callback(mark.queue_free)


static func _cancel(screen: Control, event: Dictionary) -> void:
	var uid: int = Data.i(event, "uid", -1)
	var defender: int = screen.get("_defender_uid")
	var target: int = Data.i(event, "target", defender)
	var origin: Vector2 = _point(screen, uid)
	var destination: Vector2 = _point(screen, target if target >= 0 else uid)
	var mote: TextureRect = _icon(screen, "spark", origin, 36)
	var tween: Tween = _tween(screen, mote)
	if Settings.reduce_motion:
		tween.tween_property(mote, "modulate:a", 0.0, 0.15)
	else:
		tween.tween_property(mote, "position", _local(screen, destination) - mote.size / 2, 0.12)
	tween.tween_callback(_smoke.bind(screen, destination, 0.08))
	tween.tween_callback(mote.queue_free)


static func _skip(screen: Control, event: Dictionary) -> void:
	var card: CardView = _card(screen, Data.i(event, "uid", -1))
	if card == null:
		return
	if Data.s(event, "type") == "mire_wait" or Data.s(event, "reason") == "mired":
		_bog_bubble(screen, card)
	if Data.s(event, "reason") == "bide":
		_wait_curls(screen, card)
	if Settings.reduce_motion:
		return
	var home: Vector2 = card.position
	var angle: float = card.rotation
	var tween: Tween = _tween(screen, card)
	tween.tween_property(card, "position", home - Vector2(0, 6), 0.07)
	tween.tween_property(card, "rotation", angle + 0.05, 0.05)
	tween.tween_property(card, "rotation", angle - 0.05, 0.05)
	tween.tween_property(card, "rotation", angle, 0.04)
	tween.parallel().tween_property(card, "position", home, 0.08)


static func _bog_bubble(screen: Control, card: CardView) -> void:
	var foot: Vector2 = card.get_global_rect().get_center() + Vector2(0, card.size.y / 2.0)
	var bubble: TextureRect = _icon(screen, "ring", foot, 30)
	bubble.self_modulate = Color("68482f")
	var tween: Tween = _tween(screen, bubble)
	if not Settings.reduce_motion:
		tween.tween_property(bubble, "scale", Vector2.ONE * 1.6, 0.1)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.12)
	tween.tween_callback(bubble.queue_free)


static func _wait_curls(screen: Control, card: CardView) -> void:
	for index: int in 2:
		var point: Vector2 = card.get_global_rect().position + Vector2(42 + index * 24, 14)
		var curl: TextureRect = _icon(screen, "hex", point, 22)
		curl.texture = _curl_texture()
		var tween: Tween = _tween(screen, curl)
		if not Settings.reduce_motion:
			tween.tween_property(curl, "position:y", curl.position.y - 10, 0.2)
			tween.parallel().tween_property(curl, "modulate:a", 0.0, 0.2)
		else:
			tween.tween_property(curl, "modulate:a", 0.0, 0.15)
		tween.tween_callback(curl.queue_free)


static func _curl_texture() -> ImageTexture:
	var svg: String = (
		'<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">'
		+ '<path d="M9 12h23L10 31h23" fill="none" stroke="#dcf0ed" stroke-width="5"'
		+ ' stroke-linejoin="round" stroke-linecap="round"/></svg>'
	)
	var image: Image = Image.new()
	image.load_svg_from_string(svg)
	return ImageTexture.create_from_image(image)


static func _pass(screen: Control, event: Dictionary) -> void:
	var board: BoardView = screen.call("board_for_side", Data.i(event, "side"))
	Sfx.play("turn_end")
	_flash(screen, board, UiTheme.MUTE)
	if Settings.reduce_motion:
		return
	var home: Vector2 = board.position
	var tween: Tween = _tween(screen, board)
	tween.tween_property(board, "position", home + Vector2(0, 6), 0.1)
	tween.tween_property(board, "position", home, 0.15)


static func _no_room(screen: Control, event: Dictionary) -> void:
	var uid: int = Data.i(event, "uid", -1)
	var source: CardView = _card(screen, uid)
	var source_view: Dictionary = _model(screen).unit(uid)
	var side: int = Data.i(event, "side", Data.i(source_view, "side"))
	var board: BoardView = screen.call("board_for_side", side)
	var picture: ArtFrame = ArtFrame.new()
	picture.texture = UiTheme.portrait_for(Data.s(event, "def_id", "mouse"), [])
	picture.size = Vector2(66, 66)
	picture.pivot_offset = picture.size / 2.0
	_overlay(screen).add_child(picture)
	var start: Vector2 = _point(screen, uid)
	var board_rect: Rect2 = board.get_global_rect()
	var direction: float = -1.0 if start.x < board_rect.get_center().x else 1.0
	var edge: Vector2 = Vector2(
		board_rect.position.x + 24 if direction < 0 else board_rect.end.x - 24,
		clampf(start.y, board_rect.position.y + 40, board_rect.end.y - 40)
	)
	picture.position = _local(screen, start) - picture.size / 2.0
	var tween: Tween = _tween(screen, picture)
	if source != null:
		_flash(screen, source.trigger_glyph(), UiTheme.MUTE)
	if Settings.reduce_motion:
		tween.tween_property(picture, "modulate:a", 0.0, 0.15)
		tween.tween_callback(_smoke.bind(screen, start))
	else:
		picture.scale = Vector2.ONE * 0.65
		tween.tween_property(picture, "position", _local(screen, edge) - picture.size / 2, 0.16)
		tween.parallel().tween_property(picture, "scale", Vector2.ONE, 0.16)
		tween.tween_property(
			picture,
			"position:x",
			_local(screen, edge).x - picture.size.x / 2 - direction * 12,
			0.05
		)
		tween.tween_callback(_smoke.bind(screen, edge, 0.09))
		tween.tween_property(picture, "modulate:a", 0.0, 0.09)
	tween.tween_callback(picture.queue_free)


static func _transform(screen: Control, event: Dictionary) -> void:
	var uid: int = Data.i(event, "target", -1)
	var card: CardView = _card(screen, uid)
	if card == null:
		return
	var previous: Dictionary = screen.get("_event_before")
	var current: Dictionary = _model(screen).unit(uid).duplicate(true)
	if not previous.is_empty():
		card.show_unit(previous.duplicate(true), CardView.Mode.BOARD)
	card.pivot_offset = card.size / 2.0
	var tween: Tween = _tween(screen, card)
	if Settings.reduce_motion:
		_flash(screen, card, UiTheme.HEALTH)
		tween.tween_interval(0.15)
	else:
		tween.tween_property(card, "scale:x", 0.02, 0.2)
	tween.tween_callback(_change_face.bind(screen, card, current))
	if not Settings.reduce_motion:
		tween.tween_property(card, "scale:x", 1.0, 0.2)


static func _change_face(screen: Control, card: CardView, view: Dictionary) -> void:
	if not is_instance_valid(card):
		return
	var latest: Dictionary = _model(screen).unit(Data.i(view, "uid", -1))
	card.show_unit(latest.duplicate(true) if not latest.is_empty() else view, CardView.Mode.BOARD)
	_flash(screen, card, UiTheme.HEALTH)


static func transfer_mote(
	screen: Control,
	from: Vector2,
	to: Vector2,
	key: String,
	colour: Color,
	travel: float = 0.35,
	bead_landing: bool = false,
	via: Vector2 = Vector2.INF,
	start_delay: float = 0.0
) -> Control:
	var mark: TextureRect = _icon(screen, key, from, 88 if key == "acorn" else 52)
	mark.self_modulate = colour
	var overlay: Control = _overlay(screen)
	var path := EffectPath.new()
	path.name = "EffectRoute"
	path.from_point = overlay.get_global_transform().affine_inverse() * from
	path.to_point = overlay.get_global_transform().affine_inverse() * to
	path.colour = colour
	path.via_point = _local(screen, via) if via.is_finite() else Vector2.INF
	overlay.add_child(path)
	overlay.move_child(path, maxi(0, overlay.get_child_count() - 2))
	var route: Tween = _tween(screen, path)
	if start_delay > 0:
		path.hide()
		route.tween_interval(start_delay)
		route.tween_callback(path.show)
	if Settings.reduce_motion:
		path.progress = 1.0
		route.tween_interval(travel)
	else:
		route.tween_property(path, "progress", 1.0, travel)
	route.tween_callback(func() -> void: path.arrived = true)
	route.tween_interval(0.6)
	route.tween_property(path, "modulate:a", 0.0, 0.15)
	route.tween_callback(path.queue_free)
	var landing_point: Vector2 = to - Vector2(0, 52) if bead_landing else to
	mark.set_meta("effect_from", from)
	mark.set_meta("effect_to", to)
	var tween: Tween = _tween(screen, mark)
	if start_delay > 0:
		mark.hide()
		tween.tween_interval(start_delay)
		tween.tween_callback(mark.show)
	if Settings.reduce_motion:
		var landing: TextureRect = _icon(screen, key, landing_point, 88 if key == "acorn" else 52)
		landing.self_modulate = colour
		landing.hide()
		var target: Tween = _tween(screen, landing)
		target.tween_interval(start_delay + travel)
		target.tween_callback(landing.show)
		target.tween_interval(0.7 if key == "acorn" else 0.6)
		target.tween_property(landing, "modulate:a", 0.0, 0.15)
		target.tween_callback(landing.queue_free)
		tween.tween_interval(travel)
	else:
		var end: Vector2 = (
			overlay.get_global_transform().affine_inverse() * landing_point - mark.size / 2
		)
		if via.is_finite():
			var start: Vector2 = mark.position
			var bend: Vector2 = _local(screen, via) - mark.size / 2
			tween.tween_method(
				func(t: float) -> void:
					mark.position = start.lerp(bend, t).lerp(bend.lerp(end, t), t),
				0.0,
				1.0,
				travel
			)
		else:
			tween.tween_property(
				mark, "position", (mark.position + end) / 2 - Vector2(0, 28), travel / 2
			)
			tween.tween_property(mark, "position", end, travel / 2)
	tween.tween_interval(0.7 if key == "acorn" else (0.6 if Settings.reduce_motion else 0.25))
	tween.tween_property(mark, "modulate:a", 0.0, 0.15)
	tween.tween_callback(mark.queue_free)
	return mark


static func wait_action(screen: Control, unit: CardView) -> void:
	var stamp := Panel.new()
	stamp.name = "Waiting_%d" % unit.uid()
	stamp.set_meta("self_pause_uid", unit.uid())
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.add_theme_stylebox_override("panel", UiTheme.flat_box(UiTheme.CREAM, UiTheme.INK, 4, 44))
	stamp.size = Vector2.ONE * 88
	_overlay(screen).add_child(stamp)
	stamp.position = _local(screen, unit.get_global_rect().get_center()) - stamp.size / 2
	var sword := TextureRect.new()
	sword.texture = Icons.icon("sword", 80)
	sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sword.position = Vector2(4, 4)
	sword.size = Vector2.ONE * 80
	sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.add_child(sword)
	for width: int in [11, 6]:
		var slash := Line2D.new()
		slash.points = PackedVector2Array([Vector2(16, 72), Vector2(72, 16)])
		slash.width = width
		slash.default_color = UiTheme.INK if width == 11 else UiTheme.HEALTH
		slash.antialiased = true
		stamp.add_child(slash)
	stamp.hide()
	var hold: Tween = _tween(screen, stamp)
	hold.tween_interval(0.12)
	hold.tween_callback(stamp.show)
	hold.tween_interval(0.58)
	hold.tween_property(stamp, "modulate:a", 0.0, 0.15)
	hold.tween_callback(stamp.queue_free)
	if not Settings.reduce_motion:
		unit.pivot_offset = unit.size / 2
		var windup: Tween = _tween(screen, unit)
		windup.tween_property(unit, "scale", Vector2.ONE * 1.08, 0.12)
		windup.tween_interval(0.42)
		windup.tween_property(unit, "scale", Vector2.ONE, 0.16)
