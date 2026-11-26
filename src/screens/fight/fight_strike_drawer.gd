class_name FightStrikeDrawer
extends RefCounted
## Draws the portrait strike after a fight's result (CB12 b) as its schedule has it
## (FightTimeline.hero_strike, FightStrike), over the fight screen's front layer, on its own game
## clock past the fight's end: the winner's portrait lifts, turns toward the loser's and strikes
## it, the loser's Health badge counts down and the "-N" shows on their portrait. Skip (settle)
## lands it at once. When the count has landed the screen is told (FightScreen._land_health).

## The portrait strike over the board and the banner, the Health badge and the "-N" above the
## striker, so it never hides them (E6).
const PORTRAIT_Z: int = 20
const BADGE_Z: int = 21
const BURST_Z: int = 22

## Game frames since the result showed (-1 before).
var age: float = -1.0
## "" none, "playing", "skipped" (landed at once) or "over".
var mode: String = ""

var _screen: FightScreen
var _strike: FightStrike


func _init(screen: FightScreen) -> void:
	_screen = screen


func playing() -> bool:
	return mode == "playing"


## The result has shown, `since` frames ago: the strike starts, from the loser's old Health.
func start(strike: FightStrike, since: float) -> void:
	end()
	_strike = strike
	if strike == null:
		return
	age = maxf(0.0, since)
	mode = "playing"
	var striker: Control = _node(false)
	var loser: Control = _node(true)
	if striker == null or loser == null:
		return
	var geom: Dictionary = _screen._g
	strike.place(
		home_of(striker) + striker.size / 2.0,
		home_of(loser) + loser.size / 2.0,
		striker.size.x / 2.0,
		loser.size.x / 2.0,
		Vector2(960.0, (_f(geom["T0"]) + _f(geom["T1"])) / 2.0)
	)
	draw()


## No strike: a new fight, or a state with no result.
func end() -> void:
	age = -1.0
	mode = ""
	_strike = null
	if _screen._stage != null:
		_screen._stage.position = Vector2.ZERO


## Skip: the strike lands at once, every portrait at rest, the loss on the loser's Health and its
## "-N" on their portrait, still.
func settle() -> void:
	if mode != "playing":
		return
	mode = "skipped"
	_pose(_strike.pose(float(_strike.end())))
	_burst({"shown": true, "scale": 1.0, "alpha": 1.0, "amount": _strike.total})
	_screen._land_health()


## The strike at its age; its last frame once more as it ends, or after a skip.
func draw() -> void:
	if mode == "skipped" and _strike != null:
		_pose(_strike.pose(float(_strike.end())))
		return
	if mode != "playing":
		return
	var f: float = minf(age, float(_strike.end()))
	var pose: Dictionary = _strike.pose(f)
	_pose(pose)
	var burst: Dictionary = pose["burst"]
	_burst(burst)
	if f >= _strike.count_end():
		_screen._land_health()
	if f >= _strike.end():
		mode = "over"
		var striker: Control = _node(false)
		if striker != null:
			striker.z_index = 0


func _pose(pose: Dictionary) -> void:
	var striker: Control = _node(false)
	var loser: Control = _node(true)
	if striker == null or loser == null:
		return
	var moved: Dictionary = pose["striker"]
	var light: float = _f(moved["light"])
	var offset: Vector2 = moved["offset"]
	striker.pivot_offset = striker.size / 2.0
	striker.position = home_of(striker) + offset
	var grown: float = _f(moved["scale"])
	striker.scale = Vector2(grown, grown)
	striker.rotation_degrees = _f(moved["turn"])
	striker.modulate = Color(light, light, light)
	striker.z_index = PORTRAIT_Z
	var hit: Dictionary = pose["loser"]
	var knocked: Vector2 = hit["offset"]
	loser.position = home_of(loser) + knocked
	loser.modulate = hit["light"]
	_screen._stage.position = pose["stage"]
	_badge(GlassPieces.as_int(pose["health"]), _f(pose["badge"]))


## The loser's Health badge showing `health`, swollen `swell` times.
func _badge(health: int, swell: float) -> void:
	var front: Control = _screen._front
	var badge_name: String = "HeroHealth" if _strike.loser_is_you else "OpponentHealth"
	var badge: Control = front.get_node_or_null(badge_name)
	if badge == null:
		return
	if badge_number(badge) != health:
		var fresh: GlassBox = GlassParts.health_badge(health, [".hp"])
		fresh.position = badge.position
		# out first, so the new badge takes its name
		front.remove_child(badge)
		badge.queue_free()
		fresh.name = badge_name
		front.add_child(fresh)
		badge = fresh
	badge.z_index = BADGE_Z
	badge.pivot_offset = badge.size / 2.0
	badge.scale = Vector2.ONE * swell


## The "-N" on the loser's portrait (ResultHit), as the strike shows it.
func _burst(burst: Dictionary) -> void:
	var front: Control = _screen._front
	var node: Control = front.get_node_or_null("ResultHit")
	var amount: int = GlassPieces.as_int(burst["amount"])
	if burst["shown"] != true:
		if node != null:
			front.remove_child(node)
			node.queue_free()
		return
	if node != null and GlassPieces.as_int(node.get_meta("amount", -1)) != amount:
		front.remove_child(node)
		node.queue_free()
		node = null
	if node == null:
		var r: float = GlassPieces.number("stage.fight.hit.dealt_r")
		node = FightScreen.hit_splash(amount, r)
		node.name = "ResultHit"
		node.set_meta("amount", amount)
		var loser: Control = _node(true)
		node.position = home_of(loser) + loser.size / 2.0 - Vector2(r, r)
		node.z_index = BURST_Z
		front.add_child(node)
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2.ONE * _f(burst["scale"])
	node.modulate.a = _f(burst["alpha"])


## The winner's portrait (loser false) or the loser's, as drawn now.
func _node(loser: bool) -> Control:
	var hero: bool = _strike.loser_is_you == loser
	return _screen._front.get_node_or_null("Hero" if hero else "Opponent") as Control


## Where a portrait stands: where it was built (its first position, kept as it moves).
static func home_of(node: Control) -> Vector2:
	if not node.has_meta("strike_home"):
		node.set_meta("strike_home", node.position)
	return node.get_meta("strike_home")


## The number drawn on a Health badge (its text), or -1.
static func badge_number(badge: Node) -> int:
	for child: Node in badge.get_children():
		if child is GlassText:
			return (child as GlassText).words.to_int()
	return -1


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
