extends "res://tests/screens/feel/fight_compare/compare_screen.gd"
## The fight screen for the `pilot` treatment (pilot.gd): FightScreen's own steps, plus
## - CB12 (damage to the player): the result shows the old Health and, from R+12, plays the
##   option's beat by frame (pilot_hero_damage.gd): the striker, the loser's portrait, the stage's
##   shake, the Health counting down and the "-N" on the loser's portrait;
## - CB13 (a single death): the killing number stays on through the death (pilot_motion.gd draws
##   the death itself, from this screen's clock).
## Its clock is game time (delta x speed), so every beat scales with fight speed. Markers for the
## fixture's log come out of take_markers(). Sound: the stand-in fight.hit.heavy at each contact.
## No change in src/. Exploratory (the fight animation pilot, 24 Nov): nothing here is the game.

const HeroDamage := preload("res://tests/screens/feel/fight_compare/pilot_hero_damage.gd")
const PilotMotion := preload("res://tests/screens/feel/fight_compare/pilot_motion.gd")
const Rotate := preload("res://tests/screens/feel/fight_compare/rotate.gd")
const TodayMotion := preload("res://tests/screens/feel/fight_compare/today_motion.gd")
## Drawn above the board and the banner while a portrait strikes; the Health and the "-N" above
## the striker, so it never hides them (E6).
const STRIKER_Z: int = 20
const BADGE_Z: int = 21
const BURST_Z: int = 22
const IMPACT_CUE: String = "fight.hit.heavy"

## Game seconds since the fight began.
var clock: float = 0.0
## [key, marker, detail] waiting for the fixture's log.
var _markers: Array = []
## CB12: the beat, the clock at R, and the nodes it moves.
var _damage: RefCounted
var _result_clock: float = -1.0
var _drawn_to: int = -1
var _striker: Control
var _loser: Control
var _badge: Control
var _striker_home: Vector2 = Vector2.ZERO
var _loser_home: Vector2 = Vector2.ZERO
var _burst_amount: int = -1
## CB13: key -> {amount, r, offset, recipient, born, died, at, node}
var _kills: Dictionary = {}


func _ensure_stage() -> void:
	var fresh: bool = _frame == null
	super()
	if fresh and _keeper is PilotMotion:
		_keeper.set("on_marker", _on_death_marker)
	if fresh:
		result_shown.connect(_on_result)


func take_markers() -> Array:
	var out: Array = _markers
	_markers = []
	return out


func _process(delta: float) -> void:
	clock += delta * maxf(speed, 0.01)
	if _keeper is PilotMotion:
		_keeper.set("clock", clock)
	super(delta)
	if _keeper is PilotMotion:
		_keeper.call("advance")
	_draw_kills()
	_draw_damage()


func _option(decision: String) -> String:
	if treatment == null or not treatment.has_method("option"):
		return "today"
	return str(treatment.call("option", decision))


# ---- CB12: damage to the player ----


func _build_result() -> void:
	super()
	var moment: Dictionary = state.get("moment", {})
	var result: Dictionary = moment.get("result", {})
	if _option("CB12") == "today" or not result.has("pilot"):
		return
	var held: Node = _front.get_node_or_null("ResultHit")
	if held != null:
		_front.remove_child(held)
		held.queue_free()
	var pilot: Dictionary = result["pilot"]
	var loser_is_you: bool = _b(pilot["loser_is_you"])
	_striker = _front.get_node("Opponent" if loser_is_you else "Hero")
	_loser = _front.get_node("Hero" if loser_is_you else "Opponent")
	_badge = _front.get_node("HeroHealth" if loser_is_you else "OpponentHealth")
	_badge.z_index = BADGE_Z
	_striker_home = _striker.position
	_loser_home = _loser.position
	var damage: RefCounted = HeroDamage.new(_option("CB12"))
	damage.set("big", _b(pilot["big"]))
	damage.set("old_health", _i(pilot["old"]))
	damage.set("base", _i(pilot["base"]))
	damage.set("total", _i(pilot["total"]))
	damage.set("loser_is_you", loser_is_you)
	if treatment != null and treatment.get("rotate") == true:
		damage.set("rotation_set", treatment.get("rotate_set"))
	damage.set("winner_at", _striker.position + _striker.size / 2.0)
	damage.set("loser_at", _loser.position + _loser.size / 2.0)
	damage.set("winner_r", _striker.size.x / 2.0)
	damage.set("loser_r", _loser.size.x / 2.0)
	damage.set("board_at", Vector2(960.0, (_f(_g["T0"]) + _f(_g["T1"])) / 2.0))
	_damage = damage
	_burst_amount = -1


func _on_result() -> void:
	if _damage != null:
		_result_clock = clock
		_drawn_to = -1


func _draw_damage() -> void:
	if _damage == null or _result_clock < 0.0 or not is_instance_valid(_loser):
		return
	var f: int = roundi((clock - _result_clock) * 60.0)
	if f <= _drawn_to or _drawn_to > HeroDamage.BUDGET:
		return
	var marks: Dictionary = _damage.call("markers")
	for k: int in range(_drawn_to + 1, f + 1):
		var listed: Array = marks.get(k, [])
		for marker: Variant in listed:
			if str(marker) == "result_shown":
				continue  # the fixture marks it for every treatment
			_markers.append(["", str(marker), "R+%d" % k])
			if str(marker) in ["hero_contact", "hero_contact_2"]:
				Sound.play(IMPACT_CUE)
	_drawn_to = f
	var pose: Dictionary = _damage.call("pose", f)
	var striker: Dictionary = pose["striker"]
	var light: float = _f(striker["light"])
	_striker.pivot_offset = _striker.size / 2.0
	var moved: Vector2 = striker["offset"]
	_striker.position = _striker_home + moved
	var grown: float = _f(striker["scale"])
	# the rotation switch: shorter along its own length (rotate.gd). No keystone: the portrait is
	# a GlassBox drawn by its own shader material, which tip.gdshader would replace.
	_striker.scale = Vector2(grown, grown * _f(striker.get("length", 1.0)))
	_striker.rotation_degrees = _f(striker["turn"])
	_striker.modulate = Color(light, light, light)
	_striker.z_index = STRIKER_Z if _option("CB12") == "b" else 0
	var loser: Dictionary = pose["loser"]
	var knocked: Vector2 = loser["offset"]
	_loser.position = _loser_home + knocked
	_loser.modulate = loser["light"]
	_stage.position = pose["stage"]
	_draw_badge(_i(pose["health"]), _f(pose["badge"]))
	var burst: Dictionary = pose["burst"]
	_draw_burst(burst)


func _draw_badge(health: int, swell: float) -> void:
	if _badge_value(_badge) != health:
		var fresh: GlassBox = GlassParts.health_badge(health, [".hp"])
		var kept_name: StringName = _badge.name
		fresh.position = _badge.position
		fresh.z_index = BADGE_Z
		# out first, so the new badge takes its name
		_front.remove_child(_badge)
		_badge.queue_free()
		fresh.name = kept_name
		_front.add_child(fresh)
		_badge = fresh
	_badge.pivot_offset = _badge.size / 2.0
	_badge.scale = Vector2.ONE * swell


## The number drawn on a Health badge (its text), or -1.
static func _badge_value(badge: Node) -> int:
	for child: Node in badge.get_children():
		if child is GlassText:
			return (child as GlassText).words.to_int()
	return -1


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


# ---- CB13: the killing number stays on through a single death ----


## FightScreen's own splashes, except that a hit that kills a unit dying alone keeps its number
## (popping as today's does) until its death's number time ends.
func _build_moment() -> void:
	if _option("CB13") == "today":
		super()
		return
	var moment: Dictionary = state.get("moment", {})
	var lunge: Dictionary = moment.get("lunge", {})
	var splashes: Array = moment.get("splashes", [])
	for k: int in splashes.size():
		var splash: Dictionary = splashes[k]
		var side: int = _i(splash["side"])
		var slot: int = _i(splash["slot"])
		var at: Vector2 = unit_xy(side, slot)
		var down: float = GlassPieces.number("stage.fight.hit.dealt_down_per_h")
		var r: float = GlassPieces.number("stage.fight.hit.dealt_r")
		if _is_lunger(lunge, side, slot):
			at = lunge_xy(lunge)
			down = GlassPieces.number("stage.fight.hit.taken_down_per_h")
			r = GlassPieces.number("stage.fight.hit.taken_r")
		var recipient: Control = node_for("board", side * BOARD_SLOTS + slot)
		if recipient != null:
			at = recipient.position
		var amount: int = _i(splash["amount"])
		var blocked: bool = _b(splash.get("blocked", false))
		var hit: Control = hit_splash(amount, r, blocked)
		hit.name = "Hit_%d" % k
		hit.position = at + Vector2(_w() / 2.0 - r, _h() * down - r)
		var key: String = _killed_alone(side, slot)
		if key != "" and _impact_start and not _kills.has(key):
			hit.name = "HitKill_%s" % key
			_front.add_child(hit)
			_kills[key] = {
				"amount": amount,
				"r": r,
				"blocked": blocked,
				"offset": hit.position - (recipient.position if recipient != null else at),
				"recipient": recipient,
				"born": clock,
				"died": -1.0,
				"at": hit.position,
				"node": hit,
			}
			continue
		_front.add_child(hit)
		if _impact_start:
			(_keeper as FightMotion).burst(hit, recipient)
	# the held numbers of earlier kills, drawn again after the front was rebuilt
	for key: Variant in _kills:
		var held: Dictionary = _kills[key]
		var node: Variant = held["node"]
		if is_instance_valid(node):
			var drawn: Node = node
			if drawn.get_parent() == _front:
				continue
		var again: Control = hit_splash(_i(held["amount"]), _f(held["r"]), _b(held["blocked"]))
		again.name = "HitKill_%s" % str(key)
		again.position = held["at"]
		_front.add_child(again)
		held["node"] = again
	_draw_kills()


## The key of the unit at side/slot when this hit kills it and it dies alone, else "".
func _killed_alone(side: int, slot: int) -> String:
	var boards: Array = state.get("boards", [[], []])
	var row: Array = boards[side] if side < boards.size() else []
	if slot >= row.size() or not row[slot] is Dictionary:
		return ""
	var unit: Dictionary = row[slot]
	if _i(unit.get("health", 1)) > 0:
		return ""
	var key: String = "u%d" % _i(unit.get("uid", -1))
	var solo: Dictionary = _keeper.get("solo") if _keeper is PilotMotion else {}
	return key if solo.has(key) else ""


func _on_death_marker(key: String, marker: String) -> void:
	_markers.append([key, marker, ""])
	if _kills.has(key) and marker in ["death_tip", "death_dark"]:
		var held: Dictionary = _kills[key]
		held["died"] = clock


## Each held number: today's pop (x0.55 to x1.18 in 3 f, to 1 in 5 f), following its card until
## the card starts to die, then still, full until the option's number time ends, then fading.
func _draw_kills() -> void:
	for key: Variant in _kills.keys():
		var held: Dictionary = _kills[key]
		var node: Variant = held["node"]
		if not is_instance_valid(node):
			continue
		var hit: Control = node
		var age: int = roundi((clock - _f(held["born"])) * 60.0)
		var swell: float = 1.0
		var pop_in: int = roundi(TodayMotion.TODAY_BURST_IN * 60.0)
		var settle_in: int = roundi(TodayMotion.TODAY_BURST_SETTLE * 60.0)
		if age < pop_in:
			swell = lerpf(
				TodayMotion.TODAY_BURST_START, TodayMotion.TODAY_BURST_SCALE, float(age) / pop_in
			)
		elif age < pop_in + settle_in:
			swell = lerpf(TodayMotion.TODAY_BURST_SCALE, 1.0, float(age - pop_in) / settle_in)
		hit.pivot_offset = hit.size / 2.0
		hit.scale = Vector2.ONE * swell
		var died: float = _f(held["died"])
		var recipient: Variant = held["recipient"]
		if died < 0.0 and is_instance_valid(recipient):
			var offset: Vector2 = held["offset"]
			var card: Control = recipient
			held["at"] = card.position + offset
		hit.position = held["at"]
		var alpha: float = 1.0
		if died >= 0.0:
			var since: int = roundi((clock - died) * 60.0)
			alpha = PilotMotion.number_alpha(_option("CB13"), since)
		hit.modulate.a = alpha
		if alpha <= 0.0:
			_kills.erase(key)
			if hit.get_parent() == _front:
				_front.remove_child(hit)
			hit.queue_free()
