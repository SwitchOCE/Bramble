extends "res://tests/screens/feel/fight_compare/best_screen.gd"
## The `buffs` treatment's screen (buffs.gd): the best proposal's frame-by-frame playback
## (best_screen.gd), plus CB14's gains as buff_timeline.gd schedules them:
## - every option: the changed disc drawn swollen with its digits counting (buff_disc.gd, over the
##   card; the card itself never scales), and the keeper's own number pop held back for that card;
## - B and C: the running total over each changed disc, as the recruit screen's green gain pill
##   (RecruitTurnStart._gain_tag);
## - C: each gain's pill flying from its cause on the recruit's arc (RecruitTurnStart._arc_point,
##   _arrive), and the disc's flare as the recruit's amber ring (RecruitTurnStart._ring), squeezed
##   to DESIGN.md's 8 f.
## The pieces come from a RecruitTurnStart made with no recruit screen, used for nothing else. The
## log gets markers (take_markers) and one row per drawn piece per frame (buff_rows, written to
## <stem>.buffs.csv). No change in src/. Exploratory: nothing here is the game.

const BuffDisc := preload("res://tests/screens/feel/fight_compare/buff_disc.gd")
const BuffTimeline := preload("res://tests/screens/feel/fight_compare/buff_timeline.gd")
## The recruit's Grudge gain pill colours (recruit_turn_start.gd _grudge).
const TAG_INK: Color = Color("fbffef")
const TAG_PANE: Color = Color("4f9a3a")
## The recruit ring's own length (s, recruit_turn_start.gd _ring), stepped so it lasts FLARE.
const RING_TIME: float = 0.38
## The swollen discs' z_index: above a lit card, below the pieces (RecruitTurnStart's 22).
const DISC_Z: int = 21

## The recruit's presentation node, used only for its pieces (pill, ring).
var _pieces: RecruitTurnStart
## key -> BuffDisc
var _discs: Dictionary = {}
## id -> {node, text}
var _tags: Dictionary = {}
## id -> {node, tween}
var _rings: Dictionary = {}
var _markers: Array = []
var _rows: Array = []
## The schedule's frame at the last drawn frame (markers fire on the frame the clock passes them).
var _was: float = 0.0


func take_markers() -> Array:
	var out: Array = _markers
	_markers = []
	return out


## "key,what,stat,x,y,scale,alpha,value,text" per piece drawn this frame (fight_compare.gd).
## value: a disc's number drawn, or the gain (its index in the timeline's gains) a flight or flare
## belongs to; text: a tag's words, or a disc's radius at rest.
func buff_rows() -> Array:
	var out: Array = _rows
	_rows = []
	return out


## A gain's card shows its numbers through the timeline's count: the keeper's pop is held back on
## the frame the gain lands (the step's own frame, which is the drawn frame unless FAST plays).
func show_state(new_state: Dictionary) -> void:
	if _keeper != null and _timeline != null and _step >= 0 and _step < _plan.size():
		for value: Variant in _timeline.get("gains"):
			var gain: Dictionary = value
			if _i(gain["land"]) == _i(_plan[_step]["frame"]):
				_keeper.quiet_numbers[str(gain["key"])] = true
	super(new_state)


## Keeps the discs and the pieces over a redraw of the front layer.
func _layout() -> void:
	var mine: Array[Node] = []
	for node: Variant in _discs.values():
		mine.append(node)
	if _pieces != null:
		mine.append(_pieces)
	for node: Node in mine:
		if node.get_parent() == _front:
			_front.remove_child(node)
	super()
	for node: Node in mine:
		_front.add_child(node)


func _process(delta: float) -> void:
	super(delta)
	if _timeline == null or _front == null or not _timeline.has_method("disc_at"):
		return
	if _pieces == null:
		_pieces = RecruitTurnStart.new(null)
		_pieces.name = "BuffPieces"
		_front.add_child(_pieces)
	_mark_beats()
	_draw_discs()
	_draw_tags()
	_draw_flights()
	_draw_flares()
	_was = _t


func _mark_beats() -> void:
	for value: Variant in _timeline.get("gains"):
		var gain: Dictionary = value
		var stats: Dictionary = gain["stats"]
		var parts: PackedStringArray = []
		for stat: String in stats:
			var counted: Array = stats[stat]
			parts.append("%s %d->%d +%d" % [stat, counted[0], counted[1], counted[2]])
		var detail: String = "run %d k %d %s" % [gain["run"], gain["k"], " ".join(parts)]
		if _passed(_i(gain["land"])):
			_markers.append([gain["key"], "gain_land", detail])
		if _passed(_i(gain["born"])):
			_markers.append([gain["key"], "tag_born", detail])
		if _passed(_i(gain["land"]) + BuffTimeline.SWELL_BACK):
			_markers.append([gain["key"], "disc_rest", detail])
	for value: Variant in _timeline.get("tallies"):
		var tally: Dictionary = value
		for what: String in ["appear", "sink", "gone"]:
			if _passed(_i(tally[what])):
				_markers.append([tally["key"], "tally_" + what, "run %d" % tally["run"]])


## Whether the schedule's clock reached frame x on this drawn frame (with no FAST: x is it).
func _passed(x: int) -> bool:
	return _was < x and x <= _t


func _draw_discs() -> void:
	var active: Array[String] = _timeline.call("swelling", _t)
	for key: Variant in _discs:
		if not active.has(str(key)):
			var idle: BuffDisc = _discs[key]
			idle.visible = false
	for key: String in active:
		var card: GlassCard = _node_of(key) as GlassCard
		if card == null:
			continue
		var over: BuffDisc = _disc_over(key, card)
		over.pivot_offset = card.pivot_offset
		over.position = card.position
		over.scale = card.scale
		over.rotation = card.rotation
		over.modulate = card.modulate
		over.visible = true
		# over the card, which a glow lifts above the layers (fight.html .card.lunge z-index),
		# and under the pieces (RecruitTurnStart's own z_index)
		over.z_index = maxi(card.z_index + 1, DISC_Z)
		var discs: Dictionary = {}
		var numbers: Vector2i = Vector2i(card.attack, card.health)
		for stat: String in ["attack", "health"]:
			var shown: Dictionary = _timeline.call("disc_at", key, stat, _t)
			if shown.is_empty():
				continue
			discs[stat] = shown
			if stat == "attack":
				numbers.x = _i(shown["value"])
			else:
				numbers.y = _i(shown["value"])
			var at: Vector2 = _disc_xy(card, stat)
			# text: the disc's radius at rest, so a tag's height over it can be checked
			var r: String = "%.2f" % (_disc_r(card, stat) * card.scale.y)
			_row(key, "disc", stat, at, _f(shown["scale"]), 1.0, _i(shown["value"]), r)
		over.discs = discs
		over.queue_redraw()
		# the card under it counts too, so the log's numbers are the ones drawn
		if numbers != Vector2i(card.attack, card.health):
			card.set_numbers(numbers.x, numbers.y)


func _disc_over(key: String, card: GlassCard) -> BuffDisc:
	var over: BuffDisc = _discs.get(key)
	if over == null:
		over = BuffDisc.new()
		over.name = "BuffDisc_%s" % key
		over.card_height = card.card_height
		_front.add_child(over)
		# under the tags
		_front.move_child(over, _pieces.get_index())
		_discs[key] = over
	return over


func _draw_tags() -> void:
	var seen: Dictionary = {}
	for value: Variant in _timeline.call("tags_at", _t):
		var tag: Dictionary = value
		var card: GlassCard = _node_of(str(tag["key"])) as GlassCard
		if card == null:
			continue
		var stat: String = tag["stat"]
		var id: String = "t%d_%s_%s" % [tag["run"], tag["key"], stat]
		seen[id] = true
		var node: Control = _tag(id, str(tag["text"]))
		var at: Vector2 = _pin(card, stat) + Vector2(0.0, _f(tag["drop"]))
		RecruitTurnStart._pose(node, at, _f(tag["scale"]), 0.0)
		node.modulate.a = _f(tag["alpha"])
		_row(str(tag["key"]), "tag", stat, at, _f(tag["scale"]), _f(tag["alpha"]), -1, tag["text"])
	_drop_unseen("t", seen)


func _draw_flights() -> void:
	var seen: Dictionary = {}
	for value: Variant in _timeline.call("flights_at", _t):
		var flight: Dictionary = value
		var card: GlassCard = _node_of(str(flight["key"])) as GlassCard
		if card == null:
			continue
		var stat: String = flight["stat"]
		var id: String = "f%d_%s" % [flight["gain"], stat]
		seen[id] = true
		var node: Control = _tag(id, str(flight["text"]))
		var from: Vector2 = _cause_xy(flight, card, stat)
		var to: Vector2 = _pin(card, stat)
		var at: Vector2 = RecruitTurnStart._arc_point(
			from, to, BuffTimeline.ARC_LIFT, _f(flight["mix"])
		)
		RecruitTurnStart._pose(node, at, _f(flight["scale"]), 0.0)
		node.modulate.a = _f(flight["alpha"])
		_row(
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


func _draw_flares() -> void:
	var seen: Dictionary = {}
	for value: Variant in _timeline.call("flares_at", _t):
		var flare: Dictionary = value
		var card: GlassCard = _node_of(str(flare["key"])) as GlassCard
		if card == null:
			continue
		var stat: String = flare["stat"]
		var id: String = "r%d_%s" % [flare["gain"], stat]
		seen[id] = true
		var at: Vector2 = _disc_xy(card, stat)
		if not _rings.has(id):
			# the recruit's ring, on a tween of its own that this screen steps by frame
			var tween: Tween = _pieces.create_tween()
			tween.pause()
			_pieces._timeline = tween
			var radius: float = _disc_r(card, stat) * BuffTimeline.SWELL
			_pieces._ring(at, 0.0, radius)
			var ring: Node2D = _pieces.get_child(_pieces.get_child_count() - 1)
			ring.name = "Flare_%s" % id
			_rings[id] = {"node": ring, "tween": tween}
		var entry: Dictionary = _rings[id]
		var ring_node: Node2D = entry["node"]
		var stepped: Tween = entry["tween"]
		ring_node.position = at
		# stepped to its age: FLARE frames for the ring's own RING_TIME (its first drawn frame one in)
		var due: float = clampf((_f(flare["age"]) + 1.0) / BuffTimeline.FLARE, 0.0, 1.0) * RING_TIME
		stepped.custom_step(due - _f(entry.get("done", 0.0)))
		entry["done"] = due
		_row(
			str(flare["key"]),
			"flare",
			stat,
			at,
			ring_node.scale.x,
			ring_node.modulate.a,
			_i(flare["gain"]),
			""
		)
	for id: Variant in _rings.keys():
		if seen.has(id):
			continue
		var gone: Dictionary = _rings[id]
		var old_tween: Tween = gone["tween"]
		old_tween.kill()
		var old: Node2D = gone["node"]
		old.queue_free()
		_rings.erase(id)
	if _rings.is_empty() and _pieces != null:
		_pieces._timeline = null


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
func _disc_xy(card: GlassCard, stat: String) -> Vector2:
	return card.get_transform() * _disc_local(card, stat)


static func _disc_local(card: GlassCard, stat: String) -> Vector2:
	var disc: Vector3 = GlassCard.stat_disc(stat)
	return Vector2(disc.x, disc.y) * card.card_height / L1Layout.number("card.h")


static func _disc_r(card: GlassCard, stat: String) -> float:
	return GlassCard.stat_disc(stat).z * card.card_height / L1Layout.number("card.h")


## Where a stat's tag pins: TAG_ABOVE above the top of its disc at rest.
func _pin(card: GlassCard, stat: String) -> Vector2:
	var r: float = _disc_r(card, stat) * card.scale.y
	return _disc_xy(card, stat) - Vector2(0.0, r + BuffTimeline.TAG_ABOVE)


## C: where a flight leaves from. A death: the dead unit's empty slot, at the disc's place on a
## card standing there (the target's card geometry). Otherwise the source card's middle.
func _cause_xy(flight: Dictionary, card: GlassCard, stat: String) -> Vector2:
	var cause: Dictionary = flight["cause"]
	if not cause.is_empty():
		return unit_xy(_i(cause["side"]), _i(cause["slot"])) + _disc_local(card, stat)
	var source: Control = _node_of(str(flight["source"]))
	if source != null:
		return source.get_transform() * (source.size / 2.0)
	return _disc_xy(card, stat)


func _row(
	key: String,
	what: String,
	stat: String,
	at: Vector2,
	amount: float,
	alpha: float,
	value: int,
	text: Variant
) -> void:
	_rows.append(
		(
			"%s,%s,%s,%.2f,%.2f,%.4f,%.3f,%d,%s"
			% [key, what, stat, at.x, at.y, amount, alpha, value, str(text)]
		)
	)
