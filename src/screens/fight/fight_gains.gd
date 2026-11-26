class_name FightGains
extends RefCounted
## Draws a fight's stat gains (CB14 c) as its schedule has them (FightTimeline gains, tallies),
## over the fight screen's front layer, from the screen's game clock:
## - the changed disc swollen with its digits counting (FightGainDisc, over the card; the card
##   itself never scales, and its own numbers count with the disc);
## - the running total over each changed disc;
## - each +N flying from its cause on a low arc;
## - the disc's flare as it lands.
## STAND-INS (the owner's yes of 25 Nov, until a marker is designed and approved on a picture): the
## +N and the tally are the recruit screen's green gain pill (RecruitTurnStart._gain_tag), the
## flight its arc and arrive curve, the flare its amber ring. Ported from the fight fixture's
## buff_screen.gd.

## The recruit's Grudge gain pill colours (recruit_turn_start.gd _grudge).
const TAG_INK: Color = Color("fbffef")
const TAG_PANE: Color = Color("4f9a3a")
## The swollen discs' z_index: above a lit card, below the pieces (RecruitTurnStart's 22).
const DISC_Z: int = 21
## The recruit's ring (recruit_turn_start.gd _ring): from 0.3 to 0.6 of its size as it shows (a
## quarter of the way) and out to 1.3 as it fades, eased out, here over FightTimeline.FLARE.
const RING_STEPS: Array = [
	[0.0, Vector2(0.3, 0.0)],
	[0.25, Vector2(0.6, 1.0)],
	[1.0, Vector2(1.3, 0.0)],
]

## What was drawn on the last frame: [{key, what, stat, at, scale, alpha, value, text}]. what:
## disc, tag, flight or flare. value: a disc's number, or the gain (its index in the schedule's
## gains) a flight or flare belongs to; text: a pill's words, or a disc's radius at rest.
var drawn: Array[Dictionary] = []

var _screen: FightScreen
## The recruit's presentation node, used only for its pill.
var _pieces: RecruitTurnStart
## key -> FightGainDisc
var _discs: Dictionary = {}
## id -> {node, text}
var _tags: Dictionary = {}
## id -> Node2D
var _rings: Dictionary = {}


func _init(screen: FightScreen) -> void:
	_screen = screen


## The pieces at frame n of the schedule.
func draw(schedule: FightTimeline, n: float) -> void:
	drawn.clear()
	if schedule == null or schedule.gains.is_empty():
		clear()
		return
	var front: Control = _screen._front
	if front == null:
		return
	if _pieces == null:
		_pieces = RecruitTurnStart.new(null)
		_pieces.name = "GainPieces"
		front.add_child(_pieces)
	_draw_discs(schedule, n)
	_draw_tags(schedule, n)
	_draw_flights(schedule, n)
	_draw_flares(schedule, n)


## Every piece gone (a skip, a new fight).
func clear() -> void:
	drawn.clear()
	for node: Variant in _discs.values():
		var disc: Node = node
		disc.queue_free()
	_discs.clear()
	for held: Variant in _tags.values():
		var tag: Dictionary = held
		var node: Node = tag["node"]
		node.queue_free()
	_tags.clear()
	for ring: Variant in _rings.values():
		var node: Node = ring
		node.queue_free()
	_rings.clear()
	if _pieces != null:
		_pieces.queue_free()
		_pieces = null


## The nodes to keep over a redraw of the front layer, in drawing order.
func nodes() -> Array[Node]:
	var out: Array[Node] = []
	for node: Variant in _discs.values():
		out.append(node)
	if _pieces != null:
		out.append(_pieces)
	return out


func _draw_discs(schedule: FightTimeline, n: float) -> void:
	var active: Array[String] = schedule.swelling(n)
	for key: Variant in _discs:
		if not active.has(str(key)):
			var idle: FightGainDisc = _discs[key]
			idle.visible = false
	for key: String in active:
		var card: GlassCard = _screen._kept_node(key) as GlassCard
		if card == null:
			continue
		var over: FightGainDisc = _disc_over(key, card)
		over.pivot_offset = card.pivot_offset
		over.position = card.position
		over.scale = card.scale
		over.rotation = card.rotation
		over.modulate = card.modulate
		over.visible = true
		# over the card, which a glow lifts above the layers, and under the pieces
		over.z_index = maxi(card.z_index + 1, DISC_Z)
		var discs: Dictionary = {}
		var numbers: Vector2i = Vector2i(card.attack, card.health)
		for stat: String in ["attack", "health"]:
			var shown: Dictionary = schedule.disc_at(key, stat, n)
			if shown.is_empty():
				continue
			discs[stat] = shown
			if stat == "attack":
				numbers.x = _i(shown["value"])
			else:
				numbers.y = _i(shown["value"])
			var radius: String = "%.2f" % (_disc_r(card, stat) * card.scale.y)
			_note(
				key,
				"disc",
				stat,
				_disc_xy(card, stat),
				_f(shown["scale"]),
				1.0,
				_i(shown["value"]),
				radius
			)
		over.discs = discs
		over.queue_redraw()
		# the card under it counts too, so its numbers are the ones drawn
		if numbers != Vector2i(card.attack, card.health):
			card.set_numbers(numbers.x, numbers.y)


func _disc_over(key: String, card: GlassCard) -> FightGainDisc:
	var over: FightGainDisc = _discs.get(key)
	if over == null:
		over = FightGainDisc.new()
		over.name = "GainDisc_%s" % key
		over.card_height = card.card_height
		over.golden = card.golden
		var front: Control = _screen._front
		front.add_child(over)
		# under the pills
		front.move_child(over, _pieces.get_index())
		_discs[key] = over
	return over


func _draw_tags(schedule: FightTimeline, n: float) -> void:
	var seen: Dictionary = {}
	for value: Dictionary in schedule.tags_at(n):
		var card: GlassCard = _screen._kept_node(str(value["key"])) as GlassCard
		if card == null:
			continue
		var stat: String = value["stat"]
		var id: String = "t%d_%s" % [_i(value["tally"]), stat]
		seen[id] = true
		var node: Control = _tag(id, str(value["text"]))
		var at: Vector2 = _pin(card, stat) + Vector2(0.0, _f(value["drop"]))
		RecruitTurnStart._pose(node, at, _f(value["scale"]), 0.0)
		node.modulate.a = _f(value["alpha"])
		_note(
			str(value["key"]),
			"tag",
			stat,
			at,
			_f(value["scale"]),
			_f(value["alpha"]),
			-1,
			value["text"]
		)
	_drop_unseen("t", seen)


func _draw_flights(schedule: FightTimeline, n: float) -> void:
	var seen: Dictionary = {}
	for flight: Dictionary in schedule.flights_at(n):
		var card: GlassCard = _screen._kept_node(str(flight["key"])) as GlassCard
		if card == null:
			continue
		var stat: String = flight["stat"]
		var id: String = "f%d_%s" % [_i(flight["gain"]), stat]
		seen[id] = true
		var node: Control = _tag(id, str(flight["text"]))
		var from: Vector2 = _cause_xy(flight, card, stat)
		var at: Vector2 = RecruitTurnStart._arc_point(
			from, _pin(card, stat), FightTimeline.ARC_LIFT, _f(flight["mix"])
		)
		RecruitTurnStart._pose(node, at, _f(flight["scale"]), 0.0)
		node.modulate.a = _f(flight["alpha"])
		_note(
			str(flight["key"]),
			"flight",
			stat,
			at,
			_f(flight["scale"]),
			_f(flight["alpha"]),
			_i(flight["gain"]),
			flight["text"]
		)
	_drop_unseen("f", seen)


func _draw_flares(schedule: FightTimeline, n: float) -> void:
	var seen: Dictionary = {}
	for flare: Dictionary in schedule.flares_at(n):
		var card: GlassCard = _screen._kept_node(str(flare["key"])) as GlassCard
		if card == null:
			continue
		var stat: String = flare["stat"]
		var id: String = "r%d_%s" % [_i(flare["gain"]), stat]
		seen[id] = true
		var at: Vector2 = _disc_xy(card, stat)
		var ring: Node2D = _rings.get(id)
		if ring == null:
			ring = _ring(_disc_r(card, stat) * FightTimeline.SWELL)
			ring.name = "Flare_%s" % id
			_pieces.add_child(ring)
			_rings[id] = ring
		# the recruit ring's eased keyframes, over FLARE frames (its first drawn frame one in)
		var t: float = clampf((_f(flare["age"]) + 1.0) / FightTimeline.FLARE, 0.0, 1.0)
		var pose: Vector2 = GlassMotion.keyframes(
			RING_STEPS, GlassMotion.bezier(GlassMotion.OUT, t)
		)
		ring.position = at
		ring.scale = Vector2.ONE * pose.x
		ring.modulate.a = pose.y
		_note(str(flare["key"]), "flare", stat, at, pose.x, pose.y, _i(flare["gain"]), "")
	for id: Variant in _rings.keys():
		if seen.has(id):
			continue
		var gone: Node2D = _rings[id]
		gone.queue_free()
		_rings.erase(id)


## The recruit's ring of light (recruit_turn_start.gd _ring): 4 px with a soft glow.
static func _ring(radius: float) -> Node2D:
	var ring: Node2D = Node2D.new()
	ring.modulate.a = 0.0
	var colour: Color = RecruitTurnStart.AMBER
	ring.draw.connect(
		func() -> void:
			ring.draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(colour, 0.35), 14, true)
			ring.draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(colour, 0.95), 4, true)
	)
	return ring


## A pill with these words for this id: the one drawn last frame, or a new one when the words
## changed (the running total re-pops as a new pill).
func _tag(id: String, words: String) -> Control:
	var held: Dictionary = _tags.get(id, {})
	if not held.is_empty() and str(held["text"]) == words:
		return held["node"]
	if not held.is_empty():
		var old: Control = held["node"]
		old.queue_free()
	var node: Control = _pieces._gain_tag(words, TAG_INK, TAG_PANE)
	node.name = "Gain_%s" % id
	_tags[id] = {"node": node, "text": words}
	return node


func _drop_unseen(prefix: String, seen: Dictionary) -> void:
	for id: Variant in _tags.keys():
		if not str(id).begins_with(prefix) or seen.has(id):
			continue
		var held: Dictionary = _tags[id]
		var node: Control = held["node"]
		node.queue_free()
		_tags.erase(id)


## A disc's centre where the card is drawn now (the layer's pixels).
static func _disc_xy(card: GlassCard, stat: String) -> Vector2:
	return card.get_transform() * _disc_local(card, stat)


static func _disc_local(card: GlassCard, stat: String) -> Vector2:
	var disc: Vector3 = GlassCard.stat_disc(stat)
	return Vector2(disc.x, disc.y) * card.card_height / L1Layout.number("card.h")


static func _disc_r(card: GlassCard, stat: String) -> float:
	return GlassCard.stat_disc(stat).z * card.card_height / L1Layout.number("card.h")


## Where a stat's tally pins: TAG_ABOVE above the top of its disc at rest.
static func _pin(card: GlassCard, stat: String) -> Vector2:
	var r: float = _disc_r(card, stat) * card.scale.y
	return _disc_xy(card, stat) - Vector2(0.0, r + FightTimeline.TAG_ABOVE)


## Where a flight leaves from. A death: the dead unit's empty slot, at the disc's place on a card
## standing there (the target's card geometry). Otherwise the source card's middle.
func _cause_xy(flight: Dictionary, card: GlassCard, stat: String) -> Vector2:
	var cause: Dictionary = flight["cause"]
	if not cause.is_empty():
		return _screen.unit_xy(_i(cause["side"]), _i(cause["slot"])) + _disc_local(card, stat)
	var source: Control = _screen._kept_node(str(flight["source"]))
	if source != null:
		return source.get_transform() * (source.size / 2.0)
	return _disc_xy(card, stat)


func _note(
	key: String,
	what: String,
	stat: String,
	at: Vector2,
	amount: float,
	alpha: float,
	value: int,
	text: Variant
) -> void:
	(
		drawn
		. append(
			{
				"key": key,
				"what": what,
				"stat": stat,
				"at": at,
				"scale": amount,
				"alpha": alpha,
				"value": value,
				"text": str(text),
			}
		)
	)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
