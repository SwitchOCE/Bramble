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
## How long a card takes to move to where it went (an eater, a heap's plate) as it leaves.
const FLY_TIME: float = 0.45
## How big a changed number starts before it settles.
const POP_SCALE: float = 1.5

## Where the cards are drawn; the keeper owns its children.
var layer: Control
## Divides every duration (the fight screen's playback speed).
var speed: float = 1.0
## Off: every change lands at once (tests, and skipping to a fight's end).
var animate: bool = true

## key -> {node, card_id, look, numbers}
var _kept: Dictionary = {}
## [{key, card_id, look, numbers, at, turn, make, time}] for the state being drawn
var _wanted: Array[Dictionary] = []
## node -> Tween
var _tweens: Dictionary = {}
## Cards that left and are still fading out.
var _fading: Array[Control] = []
## For the next commit: card id -> where a card of that id that leaves goes as it fades (a sold
## unit to the unit that ate it, a shop unit to the Compost plate). Cleared by commit.
var leave_to: Dictionary = {}


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


## Drops every card at once, those still fading out too (a screen rebuilt from nothing).
func clear() -> void:
	for node: Node in layer.get_children():
		layer.remove_child(node)
		node.queue_free()
	_kept.clear()
	_tweens.clear()
	_fading.clear()


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
	if not old.is_empty() and old["look"] == entry["look"]:
		node = old["node"]
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
		node.position = was.position
		node.rotation_degrees = was.rotation_degrees
		var before: Vector2i = old["numbers"]
		var after: Vector2i = entry["numbers"]
		_pop(node, before, after)
		stop(was)
		layer.remove_child(was)
		was.queue_free()
	stop(node)
	node.modulate.a = 1.0
	if node.position.is_equal_approx(at) and is_equal_approx(node.rotation_degrees, turn):
		return node
	if not animate:
		stop(node)
		node.position = at
		node.rotation_degrees = turn
		return node
	var time: float = entry["time"]
	var tween: Tween = _run(node)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at, (MOVE_TIME if time < 0.0 else time) / speed)
	tween.parallel().tween_property(node, "rotation_degrees", turn, MOVE_TIME / speed)
	return node


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
	node.z_index = 9
	_fading.append(node)
	node.pivot_offset = node.size / 2.0
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "position", at - node.size / 2.0, FLY_TIME / speed)
	tween.parallel().tween_property(node, "scale", Vector2.ONE * 0.35, FLY_TIME / speed)
	tween.parallel().tween_property(node, "modulate:a", 0.0, FLY_TIME / speed).set_delay(
		FLY_TIME * 0.5 / speed
	)
	tween.tween_callback(func() -> void: _gone(node))


func _gone(node: Control) -> void:
	_fading.erase(node)
	if is_instance_valid(node):
		node.queue_free()
