class_name RecruitTurnStart
extends Node2D
## A presentation over the first recruit view of a turn. The screen and its hit targets
## already have the authoritative state; finishing the presentation restores their drawn poses.

const LAUNCH: float = 0.11
const LIFT: float = 14.0
const WARM: Color = Color(1.18, 1.13, 1.06)
const AMBER: Color = Color("ffd678")

var _screen: RecruitScreen
var _timeline: Tween
var _poses: Dictionary = {}
var _numbers: Dictionary = {}
var _lit: Array[GlassCard] = []
var _sources: Dictionary = {}
var _gold: int = 0


func _init(screen: RecruitScreen) -> void:
	_screen = screen
	name = "TurnStart"
	z_index = 22


func active() -> bool:
	return _timeline != null


func play(effects: Array) -> void:
	_screen._tips.hide()
	for kind: String in ["board", "hand"]:
		for target: Dictionary in _screen.targets_of(kind):
			_sources[target["card"]["uid"]] = target["node"]
	_timeline = create_tween().set_parallel()
	_gold = _screen._counts.gold()
	for effect: Dictionary in effects:
		if effect["kind"] == "relic":
			_gold -= GlassPieces.as_int(effect["amount"])
	_screen._counts.show_gold(_gold)
	var start: float = 0.0
	var gap: float = 0.42
	for beat: Array in _beats(effects):
		var effect: Dictionary = beat[0]
		var source: GlassCard = _sources[effect["source_uid"]]
		match effect["kind"]:
			"grudge":
				for i: int in beat.size():
					var gain: Dictionary = beat[i]
					_grudge(gain, start + i * 0.05)
			"relic":
				_coin(source, GlassPieces.as_int(effect["amount"]), start)
			"campaigner":
				_campaigner(source, effect, start)
		start += gap
		gap = maxf(0.26, gap * 0.86)
	_timeline.finished.connect(finish)


func finish() -> void:
	if not active():
		return
	_timeline.kill()
	_timeline = null
	for card: GlassCard in _lit:
		card.set_glow("", "")
	_lit.clear()
	for node: Control in _poses:
		var pose: Dictionary = _poses[node]
		node.position = pose["position"]
		node.scale = pose["scale"]
		node.rotation = pose["rotation"]
		node.pivot_offset = pose["pivot"]
		node.z_index = pose["z"]
		node.modulate = pose["modulate"]
		node.visible = pose["visible"]
	_poses.clear()
	for card: GlassCard in _numbers:
		var final: Vector2i = _numbers[card]
		card.max_health = final.y
		card.set_numbers(final.x, final.y)
		card.number_pop = Vector2.ONE
	_numbers.clear()
	_screen._counts.show_gold(_screen._counts.gold())
	_sources.clear()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()


## Grudge is a single wave.
static func _beats(effects: Array) -> Array[Array]:
	var beats: Array[Array] = []
	var grudge: Array[Dictionary] = []
	for effect: Dictionary in effects:
		match effect["kind"]:
			"grudge":
				if grudge.is_empty():
					beats.append(grudge)
				grudge.append(effect)
			_:
				beats.append([effect])
	return beats


func _remember(node: Control) -> void:
	if _poses.has(node):
		return
	_screen._keeper.finish(node)
	_poses[node] = {
		"position": node.position,
		"scale": node.scale,
		"rotation": node.rotation,
		"pivot": node.pivot_offset,
		"z": node.z_index,
		"modulate": node.modulate,
		"visible": node.visible,
	}


func _fire(card: GlassCard, start: float, hold: float) -> void:
	if _lit.has(card):
		return
	_lit.append(card)
	_remember(card)
	var at: Vector2 = card.position
	var original: Color = card.modulate
	var z: int = card.z_index
	var duration: float = hold + 0.25
	_at(
		start,
		func() -> void:
			card.set_glow("fight", ".card.lunge")
			card.z_index = 8
	)
	_phase(
		start,
		duration,
		func(t: float) -> void:
			var elapsed: float = t * duration
			var light: float = minf(clampf(elapsed / 0.10, 0.0, 1.0), (duration - elapsed) / 0.15)
			card.modulate = original.lerp(WARM, light)
			card.position = at - Vector2(0.0, LIFT * light)
	)
	_at(
		start + duration,
		func() -> void:
			card.set_glow("", "")
			card.z_index = z
	)


func _grudge(effect: Dictionary, start: float) -> void:
	var card: GlassCard = _sources[effect["source_uid"]]
	var origin: Vector2 = card.position
	_fire(card, start, 0.42)
	var words: String = "+%d/+%d" % [effect["attack"], effect["health"]]
	var pill: Control = _gain_tag(words, Color("c8f7ba"), Color("284c32"))
	pill.name = "GrudgeGain"
	var mark: KeywordMark = _grudge_mark(card)
	var from: Vector2 = origin + Vector2(card.size.x / 2.0, card.size.y * KeywordStyle.CARD_Y)
	if mark != null:
		from = origin + mark.position + mark.size / 2.0
		_remember(mark)
		mark.pivot_offset = mark.size / 2.0
		_pulse(mark, start + 0.04, 0.38, 1.6)
	from.y -= LIFT
	var mid: Vector2 = origin + card.size * Vector2(0.5, 0.42) - Vector2(0.0, LIFT)
	_move(pill, start + LAUNCH, 0.09, from, from - Vector2(0, 10), 0.5, 0.9)
	_move(pill, start + 0.20, 0.24, from - Vector2(0, 10), mid, 0.9, 1.1)
	_move(pill, start + 0.44, 0.10, mid, mid + Vector2(0, 62), 1.1, 0.5)
	_fade(pill, start + LAUNCH, 0.09, 0.0, 1.0)
	_fade(pill, start + 0.44, 0.10, 1.0, 0.0)
	_gain_stats(card, effect, start + 0.52)


func _coin(source: GlassCard, amount: int, start: float) -> void:
	_fire(source, start, 0.26)
	var button: GlassBox = _screen._back.get_node("Button_gold")
	_remember(button)
	button.pivot_offset = button.size / 2.0
	var from: Vector2 = _centre(source) - Vector2(0.0, LIFT)
	var to: Vector2 = _centre(button)
	var coin: GoldCoin = GoldCoin.make(amount, 50.0, false, true)
	coin.show_plus = true
	coin.name = "GoldGain"
	_add_effect(coin)
	_arc(coin, start + LAUNCH, 0.42, from, to, 140.0, 0.7)
	_fade(coin, start + LAUNCH, 0.06, 0.0, 1.0)
	_fade(coin, start + 0.59, 0.14, 1.0, 0.0)
	_ring(to, start + 0.50, 44.0)
	var balance: int = _gold
	_gold += amount
	_phase(
		start + 0.53,
		0.26,
		func(t: float) -> void: _screen._counts.show_gold(balance + roundi(amount * _out(t)))
	)
	_pulse(button, start + 0.53, 0.28, 1.07)


func _campaigner(source: GlassCard, effect: Dictionary, start: float) -> void:
	_fire(source, start, 0.38)
	var slot: int = effect["slot"]
	var banner: GlassBox = _screen._back.get_node("Renown_%d" % slot)
	var under: Control = _screen._slots.get_node_or_null("Slot_%d/Renown" % slot)
	_remember(banner)
	banner.hide()
	if under != null:
		_remember(under)
		under.hide()
	var before: int = effect["before"]
	if before != 0:
		var old: GlassBox = GlassSlot.renown_banner(before, _screen.card_box())
		old.position += _screen.slot_xy(slot)
		add_child(old)
		_at(start + 0.50, old.hide)
	_at(
		start + 0.50,
		func() -> void:
			banner.show()
			if under != null:
				under.show()
	)
	banner.pivot_offset = banner.size / 2.0
	_pulse(banner, start + 0.50, 0.32, 1.7)
	var to: Vector2 = _centre(banner)
	var peak: Vector2 = to - Vector2(0, 100)
	var star: Control = _renown_star(GlassPieces.as_int(effect["amount"]))
	_move(star, start + LAUNCH, 0.14, peak + Vector2(0, 60), peak, 0.4, 1.15)
	_move(star, start + 0.25, 0.12, peak, peak, 1.15, 1.0)
	_move(star, start + 0.37, 0.14, peak, to, 1.0, 0.7)
	_move(star, start + 0.51, 0.05, to, to, 0.7, 0.5)
	_phase(start + LAUNCH, 0.14, func(t: float) -> void: star.rotation_degrees = lerpf(-30, 0, t))
	_fade(star, start + LAUNCH, 0.14, 0.0, 1.0)
	_fade(star, start + 0.51, 0.05, 1.0, 0.0)
	_ring(to, start + 0.48, 40.0)
	_gain_stats(source, effect, start + 0.52)


func _gain_stats(card: GlassCard, effect: Dictionary, at: float) -> void:
	var gain: Vector2i = Vector2i(
		GlassPieces.as_int(effect["shown_attack"]), GlassPieces.as_int(effect["shown_health"])
	)
	_remember(card)
	if not _numbers.has(card):
		_numbers[card] = Vector2i(card.attack, card.health)
	_add_numbers(card, -gain)
	_at(at, func() -> void: _add_numbers(card, gain))
	var pop: Vector2 = Vector2(1.6 if gain.x != 0 else 1.0, 1.6 if gain.y != 0 else 1.0)
	_phase(at, 0.26, func(t: float) -> void: card.number_pop = pop.lerp(Vector2.ONE, _out(t)))


static func _add_numbers(card: GlassCard, delta: Vector2i) -> void:
	card.max_health = card.health + delta.y
	card.set_numbers(card.attack + delta.x, card.max_health)


static func _grudge_mark(card: GlassCard) -> KeywordMark:
	for child: Node in card.get_children():
		var mark: KeywordMark = child as KeywordMark
		if mark != null and mark.term.get("name", "") == "Grudge":
			return mark
	return null


func _gain_tag(words: String, ink: Color, pane: Color) -> Control:
	var tag: Panel = Panel.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = pane
	style.border_color = Color("20170d")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	tag.add_theme_stylebox_override("panel", style)
	var label: GlassText = _words(words, ink)
	tag.size = Vector2(maxf(72.0, label.size.x + 24.0), 42.0)
	label.position = (tag.size - label.size) / 2.0
	tag.add_child(label)
	_add_effect(tag)
	return tag


func _renown_star(amount: int) -> Control:
	var star: TextureRect = TextureRect.new()
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.texture = KeywordStyle.icon("Renown")
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.size = Vector2.ONE * 54
	star.name = "RenownGain"
	var label: GlassText = _words("+%d" % amount, AMBER)
	label.position = Vector2(star.size.x - 8, (star.size.y - label.size.y) / 2.0)
	star.add_child(label)
	_add_effect(star)
	return star


static func _words(words: String, ink: Color) -> GlassText:
	var label: GlassText = GlassText.new()
	label.words = words
	label.font_px = 30
	label.weight = 900
	label.family = "display"
	label.lining = true
	label.colour = ink
	label.stroke_colour = Color("291c10")
	label.stroke_width = 3.0
	return label.refresh()


func _ring(at: Vector2, start: float, radius: float) -> void:
	var ring: Node2D = Node2D.new()
	ring.position = at
	ring.modulate.a = 0.0
	ring.draw.connect(
		func() -> void: ring.draw_arc(Vector2.ZERO, radius, 0, TAU, 48, AMBER, 2, true)
	)
	add_child(ring)
	_phase(
		start,
		0.38,
		func(t: float) -> void:
			var mix: float = _out(t)
			ring.scale = Vector2.ONE * lerpf(0.3, 1.3, mix)
			ring.modulate.a = minf(t * 4.0, 1.0 - mix)
	)


func _add_effect(node: Control) -> void:
	node.modulate.a = 0.0
	add_child(node)
	node.pivot_offset = node.size / 2.0


func _move(
	node: Control, at: float, time: float, from: Vector2, to: Vector2, small: float, big: float
) -> void:
	_phase(
		at,
		time,
		func(t: float) -> void: _pose(node, from.lerp(to, t), lerpf(small, big, t), node.rotation)
	)


func _arc(
	node: Control, at: float, time: float, from: Vector2, to: Vector2, lift: float, small: float
) -> void:
	_phase(
		at,
		time,
		func(t: float) -> void:
			var mix: float = _arrive(t)
			_pose(node, _arc_point(from, to, lift, mix), lerpf(small, 1.0, mix), 0.0)
	)


func _fade(node: Control, at: float, time: float, from: float, to: float) -> void:
	_phase(at, time, func(t: float) -> void: node.modulate.a = lerpf(from, to, t))


func _pulse(node: Control, at: float, time: float, swell: float) -> void:
	_phase(
		at,
		time,
		func(t: float) -> void:
			var bump: float = minf(t / 0.25, _out(1.0 - t) / _out(0.75))
			node.scale = Vector2.ONE * lerpf(1.0, swell, bump)
	)


func _phase(at: float, time: float, apply: Callable) -> void:
	_timeline.tween_method(apply, 0.0, 1.0, time).set_delay(at)


func _at(at: float, apply: Callable) -> void:
	_timeline.tween_callback(apply).set_delay(at)


static func _centre(node: Control) -> Vector2:
	return node.get_transform() * (node.size / 2.0)


static func _pose(node: Control, centre: Vector2, amount: float, angle: float) -> void:
	node.scale = Vector2.ONE * amount
	node.rotation = angle
	var offset: Vector2 = (node.size / 2.0 - node.pivot_offset) * amount
	node.position = centre - node.pivot_offset - offset.rotated(angle)


static func _arc_point(from: Vector2, to: Vector2, lift: float, t: float) -> Vector2:
	return from.lerp(to, t) - Vector2(0, lift * 4.0 * t * (1.0 - t))


static func _arrive(t: float) -> float:
	return t * t * (1.6 - 0.6 * t)


static func _out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)
