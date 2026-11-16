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
## onto a place near it, it drops in (shrinking back from its lift, straightening) in about five
## frames; from further (a refused drop going home) it flies there in HOME_TIME. Then one small,
## soft bob up and down, about 0.3 s in all for a drop. Its numbers, when they differ from what it
## showed while carried (a slot's bonus), count up to the new ones as it lands.
const DROP_TIME: float = 5.0 / 60.0
const HOME_TIME: float = 0.2
## Further than this share of the card's height from its place, a let-go card flies home.
const HOME_DISTANCE: float = 0.5
## The bob's height as a share of the card's height (6 px on a 250 px card), and its two halves.
const BOB: float = 0.024
const BOB_UP: float = 0.08
const BOB_DOWN: float = 0.13
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


## A card let go by the pointer: it stays drawn above the others (at its carried z_index) until
## the next commit has moved it to its place, so it never slides under the cards it passes.
func land(node: Control) -> void:
	_landing[node] = true


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


## A let-go card to its place (DROP_TIME or HOME_TIME, then the bob), its numbers counting from
## what it showed while carried to the state's.
func _land(node: Control, at: Vector2, turn: float, shown: Vector2i, numbers: Vector2i) -> void:
	var far: bool = node.position.distance_to(at) > node.size.y * HOME_DISTANCE
	var drop: float = (HOME_TIME if far else DROP_TIME) / speed
	var tween: Tween = _run(node)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at, drop)
	tween.parallel().tween_property(node, "rotation_degrees", turn, drop)
	tween.parallel().tween_property(node, "scale", Vector2.ONE, drop)
	tween.tween_callback(func() -> void: _unhold(node))
	var bob: float = node.size.y * BOB
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position:y", at.y - bob, BOB_UP / speed)
	tween.tween_property(node, "position:y", at.y, BOB_DOWN / speed).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: _landed(node))
	if shown.x >= 0 and shown != numbers and node is GlassCard:
		_roll(node as GlassCard, shown, numbers, drop)


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
		card.attack = numbers.x
		card.health = numbers.y
		card.queue_redraw()


static func _unhold(node: Control) -> void:
	if node is GlassCard:
		(node as GlassCard).set_held(false)


## A let-go card at its place: drawn among the others again.
func _landed(node: Control) -> void:
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
	tween.parallel().tween_property(node, "modulate:a", 0.0, FLY_TIME * 0.6 / speed).set_delay(
		FLY_TIME * 0.4 / speed
	)
	tween.tween_callback(func() -> void: _gone(node))


func _gone(node: Control) -> void:
	_fading.erase(node)
	if is_instance_valid(node):
		node.queue_free()
