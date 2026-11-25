extends "res://tests/screens/feel/fight_compare/buff_screen.gd"
## The `recommended` treatment's screen (recommended.gd): buff_screen.gd (the best proposal's
## schedule and CB14's pieces), plus
## - CB13 c: the deaths of units dying alone, drawn by pilot_motion.gd from the schedule's clock
##   (_t / 60: the drawn frame, faster under FAST), and the number that killed each held on
##   through it (recommended.gd `held`): it pops as any burst does, follows its card until the
##   card leaves the board, then stands still, full to D+18 and fading over 8 f;
## - CB12 b: after the result, the winner's portrait strikes the loser's and the loser's Health
##   counts down, the "-N" on the loser's portrait (pilot_hero_damage.gd, option b), by frame
##   after the result, on into the result's hold and past the schedule's end.
## Their markers (death_dark, death_gone, hero_*) go to the fixture's log with the buff markers.
## Exploratory: nothing here reaches the game.

const PilotMotion := preload("res://tests/screens/feel/fight_compare/pilot_motion.gd")
const HeroDamage := preload("res://tests/screens/feel/fight_compare/pilot_hero_damage.gd")
## Drawn above the board and the banner while a portrait strikes; the Health and the "-N" above
## the striker (pilot_screen.gd's).
const STRIKER_Z: int = 20
const BADGE_Z: int = 21
const BURST_Z: int = 22

## CB12: the beat, frames since the result (-1 before), the last frame drawn, and its nodes.
var _damage: RefCounted
var _age: float = -1.0
var _drawn_to: int = -1
var _striker: Control
var _loser: Control
var _badge: Control
var _striker_home: Vector2 = Vector2.ZERO
var _loser_home: Vector2 = Vector2.ZERO
var _burst_amount: int = -1


func _ensure_stage() -> void:
	var fresh: bool = _frame == null
	super()
	if fresh and _keeper is PilotMotion:
		_keeper.set("on_marker", _on_death_marker)
	if fresh:
		result_shown.connect(_on_result)


func _process(delta: float) -> void:
	var was_playing: bool = _playing
	super(delta)
	if _keeper is PilotMotion:
		_keeper.set("clock", _t / 60.0)
		_keeper.call("advance")
	if _age >= 0.0:
		if was_playing:
			_age = _t - _i(_plan.back()["frame"])
		else:
			_age += delta * 60.0 * maxf(speed, 0.01)
	_draw_damage()


func _on_death_marker(key: String, marker: String) -> void:
	_markers.append([key, marker, ""])


# ---- CB13: the killing number held through a single death ----


## Each new burst that kills a unit dying alone is held (its `hold`: the frame the unit leaves).
func _spawn_bursts() -> void:
	var before: int = _burst_next
	super()
	var held: Dictionary = treatment.get("held") if treatment != null else {}
	for index: int in range(before, _burst_next):
		if not held.has(index):
			continue
		for live: Dictionary in _live:
			var node: Control = live["node"]
			if is_instance_valid(node) and String(node.name) == "Hit_%d" % (index + 1):
				live["hold"] = _f(held[index])


## best_screen.gd's bursts, and the held ones by their own beat.
func _draw_bursts() -> void:
	var holding: Array[Dictionary] = []
	var rest: Array[Dictionary] = []
	for live: Dictionary in _live:
		if live.has("hold"):
			holding.append(live)
		else:
			rest.append(live)
	_live = rest
	super()
	for live: Dictionary in holding:
		if _draw_held(live):
			_live.append(live)


## A held number: today's pop, following its card while the card is on the board, then still;
## full to D + C_NUMBER_TO, fading over NUMBER_FADE. False once it is gone.
func _draw_held(live: Dictionary) -> bool:
	var hit: Control = live["node"]
	var since: float = _t - _f(live["hold"])
	var alpha: float = 1.0
	if since > PilotMotion.C_NUMBER_TO:
		alpha = clampf(1.0 - (since - PilotMotion.C_NUMBER_TO) / PilotMotion.NUMBER_FADE, 0.0, 1.0)
	if alpha <= 0.0 or not is_instance_valid(hit):
		if is_instance_valid(hit):
			hit.queue_free()
		return false
	var age: float = _t - _f(live["from"])
	var swell: float = 1.0
	if age < BURST_IN:
		swell = lerpf(BURST_START, BURST_SCALE, float(age) / BURST_IN)
	elif age < BURST_IN + BURST_SETTLE:
		swell = lerpf(BURST_SCALE, 1.0, float(age - BURST_IN) / BURST_SETTLE)
	var recipient: Control = _node_of(str(live["key"]))
	if recipient != null:
		var offset: Vector2 = live["offset"]
		hit.position = recipient.position + offset
	hit.scale = Vector2.ONE * swell
	hit.modulate.a = alpha
	return true


# ---- CB12: damage to the player ----


## The result as best's, its static "-N" replaced by the strike's (pilot_screen.gd's).
func _build_result() -> void:
	super()
	var moment: Dictionary = state.get("moment", {})
	var result: Dictionary = moment.get("result", {})
	if not result.has("pilot"):
		return
	var shown: Node = _front.get_node_or_null("ResultHit")
	if shown != null:
		_front.remove_child(shown)
		shown.queue_free()
	var pilot: Dictionary = result["pilot"]
	var loser_is_you: bool = _b(pilot["loser_is_you"])
	_striker = _front.get_node("Opponent" if loser_is_you else "Hero")
	_loser = _front.get_node("Hero" if loser_is_you else "Opponent")
	_badge = _front.get_node("HeroHealth" if loser_is_you else "OpponentHealth")
	_badge.z_index = BADGE_Z
	_striker_home = _striker.position
	_loser_home = _loser.position
	var damage: RefCounted = HeroDamage.new("b")
	damage.set("big", _b(pilot["big"]))
	damage.set("old_health", _i(pilot["old"]))
	damage.set("base", _i(pilot["base"]))
	damage.set("total", _i(pilot["total"]))
	damage.set("loser_is_you", loser_is_you)
	damage.set("rotation_set", treatment.get("strike_set"))
	damage.set("lean_in_plane", treatment.get("strike_lean"))
	damage.set("winner_at", _striker.position + _striker.size / 2.0)
	damage.set("loser_at", _loser.position + _loser.size / 2.0)
	damage.set("winner_r", _striker.size.x / 2.0)
	damage.set("loser_r", _loser.size.x / 2.0)
	damage.set("board_at", Vector2(960.0, (_f(_g["T0"]) + _f(_g["T1"])) / 2.0))
	_damage = damage
	_burst_amount = -1


func _on_result() -> void:
	if _damage != null:
		_age = 0.0
		_drawn_to = -1
		_draw_damage()


func _draw_damage() -> void:
	if _damage == null or _age < 0.0 or not is_instance_valid(_loser):
		return
	if _drawn_to > HeroDamage.BUDGET:
		return
	var f: int = roundi(_age)
	var marks: Dictionary = _damage.call("markers")
	for k: int in range(_drawn_to + 1, f + 1):
		var listed: Array = marks.get(k, [])
		for marker: Variant in listed:
			if str(marker) != "result_shown":
				_markers.append(["", str(marker), "R+%d" % k])
	_drawn_to = f
	var pose: Dictionary = _damage.call("pose", f)
	var striker: Dictionary = pose["striker"]
	var light: float = _f(striker["light"])
	_striker.pivot_offset = _striker.size / 2.0
	var moved: Vector2 = striker["offset"]
	_striker.position = _striker_home + moved
	var grown: float = _f(striker["scale"])
	_striker.scale = Vector2(grown, grown * _f(striker.get("length", 1.0)))
	_striker.rotation_degrees = _f(striker["turn"])
	_striker.modulate = Color(light, light, light)
	_striker.z_index = STRIKER_Z
	var loser: Dictionary = pose["loser"]
	var knocked: Vector2 = loser["offset"]
	_loser.position = _loser_home + knocked
	_loser.modulate = loser["light"]
	_stage.position = pose["stage"]
	_draw_badge(_i(pose["health"]), _f(pose["badge"]))
	var burst: Dictionary = pose["burst"]
	_draw_burst(burst)


func _draw_badge(health: int, swell: float) -> void:
	if _badge_number(_badge) != health:
		var fresh: GlassBox = GlassParts.health_badge(health, [".hp"])
		var kept_name: StringName = _badge.name
		fresh.position = _badge.position
		fresh.z_index = BADGE_Z
		_front.remove_child(_badge)
		_badge.queue_free()
		fresh.name = kept_name
		_front.add_child(fresh)
		_badge = fresh
	_badge.pivot_offset = _badge.size / 2.0
	_badge.scale = Vector2.ONE * swell


func _draw_burst(burst: Dictionary) -> void:
	var node: Control = _front.get_node_or_null("ResultHit")
	if not _b(burst["shown"]):
		if node != null:
			_front.remove_child(node)
			node.queue_free()
		return
	var amount: int = _i(burst["amount"])
	if node == null or amount != _burst_amount:
		if node != null:
			_front.remove_child(node)
			node.queue_free()
		var r: float = GlassPieces.number("stage.fight.hit.dealt_r")
		node = hit_splash(amount, r)
		node.name = "ResultHit"
		node.position = _loser_home + _loser.size / 2.0 - Vector2(r, r)
		node.z_index = BURST_Z
		_front.add_child(node)
		_burst_amount = amount
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2.ONE * _f(burst["scale"])
	node.modulate.a = _f(burst["alpha"])
