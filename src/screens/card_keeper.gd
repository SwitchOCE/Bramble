class_name CardKeeper
extends RefCounted
## Keeps a screen's card nodes between states, by key (the core's uid, or a shop place), so a new
## state moves cards instead of rebuilding the stage: a card goes to its new place with a short
## tween, a number that changed pops, a card that leaves fades, a new one fades in. A card that
## shows up under a new key where one with the same card id left (a shop card bought into the
## hand) starts from where that one was. A new state arriving mid-tween wins: each tween starts
## from wherever the card is now. STAND-IN timing: no motion is designed yet.
##
## Per state: want() each card in drawing order, then commit(), which returns the nodes by key.

## A let-go card's flight to a place it was not put is over (its hop follows).
signal flown(node: Control)
## A card that left (sold) has reached where it went: its count can change now.
signal flown_out(node: Control)

## How long a card takes to reach its new place, in seconds.
const MOVE_TIME: float = 0.2
const FADE_TIME: float = 0.18
const POP_TIME: float = 0.24
## How long a card takes to move to where it went (an eater, a heap's plate) as it leaves. It
## sets off at once, at full speed, and slows as it arrives: a card let go over the shop to be sold
## never hangs where it was let go.
const FLY_TIME: float = 0.3
## How big a changed number starts before it settles.
const POP_SCALE: float = 1.5
## A card let go by the pointer, after Once Upon a Galaxy (feel-reference/baseline-notes.md):
## let go over the place it goes (a drop the rules took, or one let go over its own place), it
## drops in (shrinking back from its lift, straightening) in 4 to 6 frames, however far its middle
## is from there; going somewhere it was not put (home after a refused drop, to the hand after a
## buy onto a unit) it flies there in 8 to 15 frames, setting off gently and arriving at speed (20
## px a frame or more), leaning as it travels, so the eye can follow it. Then it hops back up and
## swells a little and settles, in one smooth rise and fall of 12 frames. Its numbers, when they
## differ from what it showed while carried (a slot's bonus), count up as it lands.
const DROP_TIME: float = 4.0 / 60.0
const DROP_TIME_MOST: float = 6.0 / 60.0
## One more frame of drop per this many pixels its middle has to go, up to DROP_TIME_MOST.
const DROP_PX_PER_FRAME: float = 100.0
const FLIGHT_TIME: float = 15.0 / 60.0
const FLIGHT_TIME_LEAST: float = 8.0 / 60.0
## A flight's speed as it arrives, at least (px a second; 20 px a frame).
const FLIGHT_ARRIVE: float = 1200.0
## How far round its place, as a share of the card's size, the pointer may be let go and the card
## still count as put there. With no let-go point (the window lost), a card further than
## HOME_DISTANCE of its height from its place flies.
const PUT_MARGIN: float = 0.35
const HOME_DISTANCE: float = 0.5
## The hop: its height as a share of the card's height (16 px on a 250 px card), its swell, and
## its time.
const HOP: float = 0.064
const SWELL: float = 1.06
const HOP_TIME: float = 12.0 / 60.0
const ROLL_TIME: float = 0.2

## Where the cards are drawn; the keeper owns its children.
var layer: Control
## Divides every duration (the fight screen's playback speed).
var speed: float = 1.0
## Off: every change lands at once (tests, and skipping to a fight's end).
var animate: bool = true
## For the next commit: card id -> where a card of that id that leaves goes as it fades (a sold
## unit to the unit that ate it, a shop unit to the Compost plate). Cleared by commit.
var leave_to: Dictionary = {}

## key -> {node, card_id, look, numbers}
var _kept: Dictionary = {}
## [{key, card_id, look, numbers, at, turn, make, time}] for the state being drawn
var _wanted: Array[Dictionary] = []
## node -> Tween
var _tweens: Dictionary = {}
## Cards that left and are still fading out.
var _fading: Array[Control] = []
## Cards let go by the pointer that stay drawn above the rest until they reach their place.
var _landing: Dictionary = {}
## node -> the Tween counting its numbers up
var _rolls: Dictionary = {}
## Let-go card -> where the pointer let it go (on the layer), for whether it flies.
var _let_go: Dictionary = {}
## Let-go cards flying to a place they were not put.
var _flying: Dictionary = {}


func _init(on: Control) -> void:
	layer = on


## A card for the state being drawn. look: everything that changes how the node is drawn (when it
## differs from the kept node's, make() builds a new one in its place). numbers: {attack, health}
## for the pop. at and turn: the card's resting place and its turn in degrees. time: this move's
## own duration (a fight's lunge), or -1 for MOVE_TIME.
func want(
	key: String,
	card_id: String,
	look: String,
	numbers: Vector2i,
	at: Vector2,
	turn: float,
	make: Callable,
	time: float = -1.0
) -> void:
	(
		_wanted
		. append(
			{
				"key": key,
				"card_id": card_id,
				"look": look,
				"numbers": numbers,
				"at": at,
				"turn": turn,
				"make": make,
				"time": time,
			}
		)
	)


## Places every wanted card, fades the rest out, and returns {key: node}.
func commit() -> Dictionary:
	for node: Variant in _tweens.keys():
		var old_tween: Tween = _tweens[node]
		if not old_tween.is_valid() or not old_tween.is_running():
			_tweens.erase(node)
	var first: bool = _kept.is_empty()
	var leaving: Dictionary = {}
	var wanted_keys: Dictionary = {}
	for entry: Dictionary in _wanted:
		wanted_keys[entry["key"]] = true
	for key: Variant in _kept:
		if not wanted_keys.has(key):
			leaving[key] = _kept[key]
	var kept: Dictionary = {}
	var out: Dictionary = {}
	for entry: Dictionary in _wanted:
		var key: String = entry["key"]
		var old: Dictionary = _kept.get(key, {})
		if old.is_empty():
			old = _take_leaver(leaving, str(entry["card_id"]))
		var node: Control = _place(entry, old, first)
		kept[key] = {
			"node": node,
			"card_id": entry["card_id"],
			"look": entry["look"],
			"numbers": entry["numbers"],
		}
		out[key] = node
	for key: Variant in leaving:
		var gone: Dictionary = leaving[key]
		var gone_node: Control = gone["node"]
		if leave_to.has(gone["card_id"]) and animate and gone_node.is_inside_tree():
			var target: Vector2 = leave_to[gone["card_id"]]
			_fly_out(gone_node, target)
		else:
			_fade_out(gone_node)
	leave_to = {}
	_kept = kept
	_wanted.clear()
	# drawing order follows the state's: shop, board, hand, each left to right
	var index: int = 0
	for key: Variant in out:
		var node: Control = out[key]
		layer.move_child(node, index)
		index += 1
	return out


## Every card at once where it is going, and every card that left gone (tests; a skip; a fight's
## result, which shows no dead unit still fading over its slot).
func settle() -> void:
	for node: Variant in _tweens:
		var tween: Tween = _tweens[node]
		if tween.is_valid():
			tween.custom_step(10.0)
	_tweens.clear()
	for node: Variant in _rolls:
		var roll: Tween = _rolls[node]
		if roll.is_valid():
			roll.custom_step(10.0)
	_rolls.clear()
	for node: Variant in _landing:
		if is_instance_valid(node):
			var landed: Control = node
			landed.z_index = 0
			_unhold(landed)
	_landing.clear()
	_let_go.clear()
	var flew: Array = _flying.keys()
	_flying.clear()
	for node: Variant in flew:
		if is_instance_valid(node):
			flown.emit(node)
	for node: Control in _fading:
		if is_instance_valid(node):
			if node.get_parent() == layer:
				layer.remove_child(node)
			node.queue_free()
	_fading.clear()


## Whether any card is still moving, popping in or fading out.
func is_moving() -> bool:
	for node: Variant in _tweens:
		var tween: Tween = _tweens[node]
		if tween.is_valid() and tween.is_running():
			return true
	for node: Control in _fading:
		if is_instance_valid(node) and node.get_parent() == layer:
			return true
	return false


## Stops a card's tween where it is (a drag picks it up).
func stop(node: Control) -> void:
	var tween: Tween = _tweens.get(node)
	if tween != null and tween.is_valid():
		tween.kill()
	_tweens.erase(node)


## A card's move, landing and count-up done at once: at its place, as when still.
func finish(node: Control) -> void:
	for tweens: Dictionary in [_tweens, _rolls]:
		var tween: Tween = tweens.get(node)
		if tween != null and tween.is_valid():
			tween.custom_step(10.0)
		tweens.erase(node)
	_landed(node)


## A card let go by the pointer, put down at once: drawn among the cards again (under the
## vignette and a slot's bonus pill, as it will be when still), but last, over the cards it passes;
## the screen keeps it last after a commit (is_landing) unless its place overlaps others (a hand).
## So nothing about its look changes when it stops.
func land(node: Control, pointer: Vector2 = Vector2.INF) -> void:
	_landing[node] = true
	if pointer != Vector2.INF:
		_let_go[node] = pointer
	else:
		_let_go.erase(node)
	node.z_index = 0
	if node.get_parent() == layer:
		layer.move_child(node, -1)


func is_landing(node: Control) -> bool:
	return _landing.has(node)


## Whether a card is still on its way somewhere (landing, moving): no hover detail for it yet.
func is_busy(node: Control) -> bool:
	if _landing.has(node):
		return true
	var tween: Tween = _tweens.get(node)
	return tween != null and tween.is_valid() and tween.is_running()


## Whether a let-go card is flying to a place it was not put (on its way to the hand, say).
func is_flying(node: Control) -> bool:
	return _flying.has(node)


## Drops every card at once, those still fading out too (a screen rebuilt from nothing).
func clear() -> void:
	for node: Node in layer.get_children():
		layer.remove_child(node)
		node.queue_free()
	_kept.clear()
	_tweens.clear()
	_fading.clear()
	_landing.clear()
	_rolls.clear()
	_let_go.clear()
	_flying.clear()


## Moves a card's pivot without moving the card on the screen (a carried card turns and grows
## about its middle; a hand card turns about its foot).
static func set_pivot(node: Control, pivot: Vector2) -> void:
	var shift: Vector2 = node.pivot_offset - pivot
	var turn: Transform2D = Transform2D(node.rotation, node.scale, 0.0, Vector2.ZERO)
	node.position += shift - turn * shift
	node.pivot_offset = pivot


func _take_leaver(leaving: Dictionary, card_id: String) -> Dictionary:
	for key: Variant in leaving:
		var entry: Dictionary = leaving[key]
		if str(entry["card_id"]) == card_id:
			leaving.erase(key)
			return entry
	return {}


func _place(entry: Dictionary, old: Dictionary, first: bool) -> Control:
	var at: Vector2 = entry["at"]
	var turn: float = entry["turn"]
	var node: Control
	# the numbers a let-go card shows now, to count up from as it lands
	var shown: Vector2i = Vector2i(-1, -1)
	if not old.is_empty() and old["look"] == entry["look"]:
		node = old["node"]
		shown = _numbers_of(node)
	else:
		var make: Callable = entry["make"]
		node = make.call()
		layer.add_child(node)
		if old.is_empty():
			node.position = at
			node.rotation_degrees = turn
			if not first and animate:
				node.modulate.a = 0.0
				_run(node).tween_property(node, "modulate:a", 1.0, FADE_TIME / speed)
			return node
		var was: Control = old["node"]
		node.pivot_offset = was.pivot_offset
		node.position = was.position
		node.rotation_degrees = was.rotation_degrees
		node.scale = was.scale
		if _landing.has(was):
			_landing.erase(was)
			_landing[node] = true
			if _let_go.has(was):
				_let_go[node] = _let_go[was]
				_let_go.erase(was)
			node.z_index = was.z_index
			shown = _numbers_of(was)
			if was is GlassCard and node is GlassCard and (was as GlassCard).is_held():
				(node as GlassCard).set_held(true)
		else:
			var before: Vector2i = old["numbers"]
			var after: Vector2i = entry["numbers"]
			_pop(node, before, after)
		stop(was)
		layer.remove_child(was)
		was.queue_free()
	stop(node)
	node.modulate.a = 1.0
	var numbers: Vector2i = entry["numbers"]
	if not animate:
		node.position = at
		node.rotation_degrees = turn
		node.scale = Vector2.ONE
		if _landing.has(node):
			_set_numbers(node, numbers)
		_landed(node)
		return node
	if _landing.has(node):
		_land(node, at, turn, shown, numbers)
		return node
	var still: bool = node.position.is_equal_approx(at) and node.scale.is_equal_approx(Vector2.ONE)
	if still and is_equal_approx(node.rotation_degrees, turn):
		return node
	var time: float = entry["time"]
	var tween: Tween = _run(node)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at, (MOVE_TIME if time < 0.0 else time) / speed)
	tween.parallel().tween_property(node, "rotation_degrees", turn, MOVE_TIME / speed)
	if not node.scale.is_equal_approx(Vector2.ONE):
		tween.parallel().tween_property(node, "scale", Vector2.ONE, MOVE_TIME / speed)
	return node


## A let-go card to its place (a drop, or a flight), then its hop, its numbers counting from
## what it showed while carried to the state's.
func _land(node: Control, at: Vector2, turn: float, shown: Vector2i, numbers: Vector2i) -> void:
	var far: bool = not _put_there(node, at)
	_let_go.erase(node)
	var tween: Tween = _run(node)
	var arrive: float
	if far:
		_flying[node] = true
		# an eased-in flight arrives at pi / 2 times its mean speed
		var distance: float = node.position.distance_to(at)
		arrive = clampf(PI / 2.0 * distance / FLIGHT_ARRIVE, FLIGHT_TIME_LEAST, FLIGHT_TIME)
		_fly(tween, node, at, turn, arrive / speed)
		tween.tween_callback(
			func() -> void:
				if _flying.erase(node):
					flown.emit(node)
		)
	else:
		var middle: float = node.position.distance_to(at)
		arrive = clampf(DROP_TIME + middle / DROP_PX_PER_FRAME / 60.0, DROP_TIME, DROP_TIME_MOST)
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "position", at, arrive / speed)
		tween.parallel().tween_property(node, "rotation_degrees", turn, arrive / speed)
		tween.parallel().tween_property(node, "scale", Vector2.ONE, arrive / speed)
	# the hop and swell about the card's middle (a hand card keeps its foot: it is turned), in
	# one smooth rise and fall
	tween.tween_callback(
		func() -> void:
			if is_zero_approx(node.rotation):
				set_pivot(node, node.size / 2.0)
	)
	var hop: Callable = func(t: float) -> void:
		var up: float = sin(PI * t)
		node.position.y = at.y - node.size.y * HOP * up
		node.scale = Vector2.ONE * (1.0 + (SWELL - 1.0) * up)
		if t >= 0.5:
			_unhold(node)
	tween.tween_method(hop, 0.0, 1.0, HOP_TIME / speed)
	tween.tween_callback(func() -> void: _landed(node))
	if shown.x >= 0 and shown != numbers and node is GlassCard:
		_roll(node as GlassCard, shown, numbers, arrive / speed)


## Whether a let-go card was let go over the place it goes (or round it, by PUT_MARGIN of its size).
func _put_there(node: Control, at: Vector2) -> bool:
	if not _let_go.has(node):
		return node.position.distance_to(at) <= node.size.y * HOME_DISTANCE
	var pointer: Vector2 = _let_go[node]
	var margin: Vector2 = node.size * PUT_MARGIN
	return Rect2(at - margin, node.size + margin * 2.0).has_point(pointer)


## A let-go card's flight to a place it was not put (home, or the hand): setting off gently and
## arriving at speed (eased in), leaning back against its travel as a carried card does
## (CardCarry), most at mid-flight and straight again as it arrives. It starts from
## wherever the card is on the tween's first step (a hand card's pivot may move before then).
func _fly(tween: Tween, node: Control, at: Vector2, turn: float, time: float) -> void:
	var start: Dictionary = {}
	var fly: Callable = func(t: float) -> void:
		if start.is_empty():
			start.merge({"at": node.position, "turn": node.rotation_degrees, "scale": node.scale})
		var from: Vector2 = start["at"]
		var from_turn: float = start["turn"]
		var eased: float = 1.0 - cos(PI / 2.0 * t)
		# its speed at mid-flight is about its mean
		var speed_x: float = (at.x - from.x) / time
		var lean: float = clampf(
			-speed_x * CardCarry.TILT_PER_SPEED, -CardCarry.TILT_MAX, CardCarry.TILT_MAX
		)
		node.position = from.lerp(at, eased)
		node.rotation_degrees = lerpf(from_turn, turn, eased) + lean * sin(PI * t)
		var size: Vector2 = start["scale"]
		node.scale = size.lerp(Vector2.ONE, eased)
	tween.tween_method(fly, 0.0, 1.0, time)


## A card's numbers count from one pair to another (a slot's bonus taken back as it lands).
func _roll(card: GlassCard, from: Vector2i, to: Vector2i, delay: float) -> void:
	var old_roll: Tween = _rolls.get(card)
	if old_roll != null and old_roll.is_valid():
		old_roll.kill()
	_set_numbers(card, from)
	var roll: Tween = card.create_tween()
	_rolls[card] = roll
	var count: Callable = func(t: float) -> void:
		_set_numbers(card, Vector2i(roundi(lerpf(from.x, to.x, t)), roundi(lerpf(from.y, to.y, t))))
	roll.tween_method(count, 0.0, 1.0, ROLL_TIME / speed).set_delay(delay)
	roll.tween_callback(func() -> void: _rolls.erase(card))


static func _numbers_of(node: Control) -> Vector2i:
	var card: GlassCard = node as GlassCard
	return Vector2i(card.attack, card.health) if card != null else Vector2i(-1, -1)


static func _set_numbers(node: Control, numbers: Vector2i) -> void:
	var card: GlassCard = node as GlassCard
	if card != null and Vector2i(card.attack, card.health) != numbers:
		card.set_numbers(numbers.x, numbers.y)


static func _unhold(node: Control) -> void:
	if node is GlassCard:
		(node as GlassCard).set_held(false)


## A let-go card at its place: drawn among the others again.
func _landed(node: Control) -> void:
	_let_go.erase(node)
	if _flying.erase(node):
		flown.emit(node)
	if _landing.has(node):
		_landing.erase(node)
		node.z_index = 0
		_unhold(node)


## A new tween for a card, replacing any it had: the newest state wins.
func _run(node: Control) -> Tween:
	stop(node)
	var tween: Tween = node.create_tween()
	_tweens[node] = tween
	return tween


## The numbers that changed start big and settle (GlassCard.number_pop).
func _pop(node: Control, before: Vector2i, after: Vector2i) -> void:
	var card: GlassCard = node as GlassCard
	if card == null or not animate or before == after:
		return
	var start: Vector2 = Vector2(
		POP_SCALE if before.x != after.x else 1.0, POP_SCALE if before.y != after.y else 1.0
	)
	card.number_pop = start
	var tween: Tween = card.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "number_pop", Vector2.ONE, POP_TIME / speed)


func _fade_out(node: Control) -> void:
	stop(node)
	_landing.erase(node)
	if not animate or not node.is_inside_tree():
		layer.remove_child(node)
		node.queue_free()
		return
	node.z_index = 0
	_fading.append(node)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, FADE_TIME / speed)
	tween.tween_callback(func() -> void: _gone(node))


## STAND-IN (stand-ins.html ?m=feedback): a card that went somewhere moves there, shrinking, as
## it fades.
func _fly_out(node: Control, at: Vector2) -> void:
	stop(node)
	_landing.erase(node)
	node.z_index = 9
	_unhold(node)
	_fading.append(node)
	set_pivot(node, node.size / 2.0)
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at - node.size / 2.0, FLY_TIME / speed)
	tween.parallel().tween_property(node, "rotation", 0.0, FLY_TIME / speed)
	tween.parallel().tween_property(node, "scale", Vector2.ONE * 0.35, FLY_TIME / speed)
	tween.parallel().tween_property(node, "modulate:a", 0.0, FLY_TIME * 0.3 / speed).set_delay(
		FLY_TIME * 0.7 / speed
	)
	tween.tween_callback(
		func() -> void:
			flown_out.emit(node)
			_gone(node)
	)


func _gone(node: Control) -> void:
	_fading.erase(node)
	if is_instance_valid(node):
		node.queue_free()
