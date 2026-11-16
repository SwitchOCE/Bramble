class_name FightScreen
extends GlassScreen
## The fight screen in lead and stained glass, rebuilt from fight.html: the shared window, hero,
## leaderboard and hover (GlassScreen), with the opponent's board in the shop's light, its front
## row facing yours across the transom. It draws one plain view state (show_state) and can play a
## fight log through FightReplay (play). It holds no rules and sends no requests.
##
## The view state (tests/screens/fixtures/fight_start.json and fight_mid.json are examples):
##   turn, health, hero, players: as the recruit screen's
##   opponent: {name, portrait, health}
##   you_side: which of the two boards is yours (the rules core's side, 0 or 1)
##   boards: [side 0, side 1], each 7 entries, unit or null, slots 0-6 in reading order
##   slots: [side 0, side 1], each 7 {attack, health, keywords: [{id}], label, percent} or {}
##     (a slot's lasting bonus, as GlassScreen.slot_info reads it)
##   unit: {id, uid, name, tier, art, attack, health, max_health, text, keywords: [id],
##     mechanics: [id], amounts: {mechanic: n}, counters: [{id, value}]}: Health under max_health
##     is drawn red; keywords and counters are STAND-IN pills on the card (the mock-up has none)
##   moment: {lunge: {side, slot, target_side, target_slot}, splashes: [{side, slot, amount,
##     blocked}] (amount 0: destroyed; blocked: a prevented hit, drawn as a 0),
##     trigger: {side, slot} (the unit whose effect is acting),
##     result: {winner, damage}}: what is happening right now; all of it optional
##
## STAND-IN (fight.html's own): the lunge, the damage splashes and red Health. The result banner,
## the pills and the playback timing are this screen's stand-ins; fight animation is not designed.

## The fight is over and its result is showing.
signal playback_finished
## The result is on the screen (its hold has just begun): the flow may move on from here.
signal result_shown

const FIGHT_READY_LINE: String = "fight_screen: ready"
## How long the attacker takes to lunge, in seconds at speed 1.
const LUNGE_TIME: float = 0.16
## STAND-IN: how far a unit whose effect is acting lifts in place, and how fast.
const TRIGGER_LIFT: float = 14.0
const TRIGGER_TIME: float = 0.1

## Playback speed: 2 plays twice as fast.
@export var speed: float = 1.0

var _replay: FightReplay
var _step: int = -1
var _wait: float = 0.0
## The lunge the screen showed last, so the splashes wait only for a lunge that is starting.
var _shown_lunge: Dictionary = {}


func _geom() -> Dictionary:
	return GlassPieces.fight_geom()


func _ready_line() -> String:
	return FIGHT_READY_LINE


func _leaderboard_key() -> String:
	return "stage.fight.leaderboard"


# ---- playback ----


## Plays a fight: each step of the replay is shown for its hold time, then the next.
func play(replay: FightReplay) -> void:
	# a new fight starts from a clean table: no card of the last fight is left fading or popping
	if _keeper != null:
		_keeper.clear()
	_replay = replay
	_shown_lunge = {}
	_step = -1
	_wait = 0.0
	_next_step()


## Jumps to the end of the fight being played. Once there, a second skip does nothing: the
## result keeps its hold and then finishes.
func skip() -> void:
	if _replay == null or _step >= _replay.steps.size() - 1:
		return
	_step = _replay.steps.size() - 2
	_wait = 0.0
	_next_step()


func is_playing() -> bool:
	return _replay != null


func _process(delta: float) -> void:
	super(delta)
	if _replay == null:
		return
	_wait -= delta * speed
	if _wait <= 0.0:
		_next_step()


func _next_step() -> void:
	_step += 1
	if _step >= _replay.steps.size():
		_replay = null
		playback_finished.emit()
		return
	var step: Dictionary = _replay.steps[_step]
	_keeper.speed = maxf(speed, 0.01)
	var view: Dictionary = step["state"]
	show_state(view)
	_wait = _f(step["hold"])
	_hold_splashes()
	if _step == _replay.steps.size() - 1:
		result_shown.emit()


## The splashes wait until the attacker has reached its lunge place.
func _hold_splashes() -> void:
	var moment: Dictionary = state.get("moment", {})
	var lunge: Dictionary = moment.get("lunge", {})
	var starting: bool = not lunge.is_empty() and lunge != _shown_lunge
	_shown_lunge = lunge
	if not starting or not _keeper.animate:
		return
	var hits: Array[CanvasItem] = []
	for child: Node in _front.get_children():
		if String(child.name).begins_with("Hit_"):
			hits.append(child as CanvasItem)
			(child as CanvasItem).visible = false
	var tween: Tween = create_tween()
	tween.tween_interval(LUNGE_TIME / maxf(speed, 0.01))
	for hit: CanvasItem in hits:
		tween.tween_callback(hit.show)


# ---- building ----


func _build() -> void:
	_add_window()
	var you: int = _you()
	_want_side(1 - you)
	_want_side(you)
	_place_cards()
	_light_lunge()
	_build_moment()
	_build_hero()
	_build_opponent()
	if show_leaderboard:
		_build_leaderboard()
	_add_vignette()
	_build_result()


func _you() -> int:
	return _i(state.get("you_side", 0))


## Where a unit of a side stands, by slot: yours as on the recruit screen but under the transom,
## theirs mirrored above it (front row at the bottom), both reading left to right.
func unit_xy(side: int, slot: int) -> Vector2:
	var fw: float = FRONT_SLOTS * _w() + (FRONT_SLOTS - 1) * _gap()
	var fx: float = 960.0 - fw / 2.0
	var x: float = (
		fx + slot * (_w() + _gap())
		if slot < FRONT_SLOTS
		else fx + (_w() + _gap()) / 2.0 + (slot - FRONT_SLOTS) * (_w() + _gap())
	)
	var row: float = (
		GlassPieces.number("stage.fight.board.row_drop_per_h") * _h()
		+ GlassPieces.number("stage.fight.board.row_gap")
	)
	var front: bool = slot < FRONT_SLOTS
	if side == _you():
		return Vector2(x, _f(_g["boardTop"]) + (0.0 if front else row))
	return Vector2(x, _f(_g["oppTop"]) + (row if front else 0.0))


## Where an attacker lunges to: up across the transom towards its target (theirs mirrored down).
func lunge_xy(lunge: Dictionary) -> Vector2:
	var from: Vector2 = unit_xy(_i(lunge["side"]), _i(lunge["slot"]))
	var to: Vector2 = unit_xy(_i(lunge["target_side"]), _i(lunge["target_slot"]))
	var lift: float = GlassPieces.number("stage.fight.lunge.lift_per_h") * _h()
	var x: float = from.x + (to.x - from.x) * GlassPieces.number("stage.fight.lunge.toward")
	if _i(lunge["side"]) == _you():
		return Vector2(x, _f(_g["boardTop"]) - lift)
	# STAND-IN: the mock-up only shows your unit lunging; theirs mirrors it
	var row: float = (
		GlassPieces.number("stage.fight.board.row_drop_per_h") * _h()
		+ GlassPieces.number("stage.fight.board.row_gap")
	)
	return Vector2(x, _f(_g["oppTop"]) + row + lift)


func _want_side(side: int) -> void:
	var boards: Array = state.get("boards", [[], []])
	var board: Array = boards[side] if side < boards.size() else []
	var all_slots: Array = state.get("slots", [[], []])
	var slots: Array = all_slots[side] if side < all_slots.size() else []
	var lunge: Dictionary = _lunge()
	for i: int in BOARD_SLOTS:
		var unit: Variant = board[i] if i < board.size() else null
		var raw: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		var info: Dictionary = slot_info(raw)
		if unit is Dictionary:
			var held: Dictionary = unit
			var extra: Dictionary = {}
			if info.has("buff"):
				extra["buff"] = str(info["buff"])
			var at: Vector2 = unit_xy(side, i)
			var time: float = -1.0
			if _is_lunger(lunge, side, i):
				at = lunge_xy(lunge)
				time = LUNGE_TIME
			elif _is_lunger(_trigger(), side, i):
				at.y -= TRIGGER_LIFT if side == _you() else -TRIGGER_LIFT
				time = TRIGGER_TIME
			var key: String = card_key("f%d_" % side, i, held)
			_want_card(key, "board", side * BOARD_SLOTS + i, held, at, 0.0, extra, time)
			continue
		var slot: GlassBox = _slot(raw)
		slot.name = "Slot_%d_%d" % [side, i]
		slot.position = unit_xy(side, i)
		_back.add_child(slot)


func _lunge() -> Dictionary:
	var moment: Dictionary = state.get("moment", {})
	var lunge: Dictionary = moment.get("lunge", {})
	return lunge


## The unit whose effect is acting now: {side, slot}, or {}.
func _trigger() -> Dictionary:
	var moment: Dictionary = state.get("moment", {})
	var trigger: Dictionary = moment.get("trigger", {})
	return trigger


static func _is_lunger(lunge: Dictionary, side: int, slot: int) -> bool:
	return not lunge.is_empty() and _i(lunge["side"]) == side and _i(lunge["slot"]) == slot


func _make_card(kind: String, data: Dictionary, extra: Dictionary) -> Control:
	var node: Control = super(kind, data, extra)
	if extra.has("buff") and node is GlassCard:
		_slot_buff_pill(node as GlassCard, str(extra["buff"]))
	return node


## The attacker glows above the rest (fight.html .card.lunge); every other card has its own look.
func _light_lunge() -> void:
	var lunge: Dictionary = _lunge()
	for target: Dictionary in _targets:
		var node: Variant = target.get("node")
		if not node is GlassCard:
			continue
		var card: GlassCard = node
		var index: int = target["index"]
		card.name = "Unit_%d_%d" % [floori(index / float(BOARD_SLOTS)), index % BOARD_SLOTS]
		var side: int = floori(index / float(BOARD_SLOTS))
		if (
			_is_lunger(lunge, side, index % BOARD_SLOTS)
			or _is_lunger(_trigger(), side, index % BOARD_SLOTS)
		):
			card.set_glow("fight", ".card.lunge")
			card.z_index = _i(GlassPieces.rule("fight", ".card.lunge", "z-index"))
		else:
			card.set_glow("", "")
			card.z_index = 0


## fight.html's ATTACK: each splash at its unit, the attacker's at its lunge place.
func _build_moment() -> void:
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
		var attacker: bool = (
			not lunge.is_empty() and _i(lunge["side"]) == side and _i(lunge["slot"]) == slot
		)
		if attacker:
			at = lunge_xy(lunge)
			down = GlassPieces.number("stage.fight.hit.taken_down_per_h")
			r = GlassPieces.number("stage.fight.hit.taken_r")
		var hit: Control = hit_splash(_i(splash["amount"]), r, _b(splash.get("blocked", false)))
		hit.name = "Hit_%d" % k
		hit.position = at + Vector2(_w() / 2.0 - r, _h() * down - r)
		_front.add_child(hit)


## fight.html hit(): an eight-pointed burst in lead, its glass red, the damage on it. Amount 0 is
## a destroy (STAND-IN, stand-ins.html): the burst with no number. `blocked` (STAND-IN,
## stand-ins.html ?m=trigger): a hit that did nothing, the burst with a 0 on it.
static func hit_splash(amount: int, r: float, blocked: bool = false) -> Control:
	var outer: Rect2 = Rect2(0, 0, 2.0 * r, 2.0 * r)
	var root: Control = Control.new()
	root.size = outer.size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = GlassPieces.as_int(GlassPieces.rule("fight", ".hit", "z-index"))
	var lead_layers: Array = GlassPieces.rule("fight", ".hit i", "background")
	var lead_layer: Dictionary = lead_layers[0]
	var lead: Color = Color.html(str(lead_layer["colour"]))
	var star_outer: PackedVector2Array = _star(outer)
	root.draw.connect(func() -> void: root.draw_colored_polygon(star_outer, lead))
	var inset: float = GlassPieces.as_float(GlassPieces.rule("fight", ".hit i + i", "inset"))
	var inner: Rect2 = outer.grow(-inset)
	var mask: Control = Control.new()
	mask.name = "Glass"
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.position = inner.position
	mask.size = inner.size
	var star_inner: PackedVector2Array = _star(Rect2(Vector2.ZERO, inner.size))
	mask.draw.connect(func() -> void: mask.draw_colored_polygon(star_inner, Color.WHITE))
	root.add_child(mask)
	var glass: GlassBox = GlassBox.new()
	glass.box_size = inner.size
	glass.use_css("fight", ".hit i + i")
	glass.refresh()
	mask.add_child(glass)
	if amount <= 0 and not blocked:
		return root
	var words: GlassText = GlassText.from_rule(
		"fight", ".hit b", "0" if blocked else "-%d" % amount
	)
	words.refresh()
	words.position = ((outer.size - words.size) / 2.0).round()
	root.add_child(words)
	return root


## The burst's 16 points, as fight.html writes them (percentages to one decimal).
static func _star(rect: Rect2) -> PackedVector2Array:
	var points: int = GlassPieces.as_int(GlassPieces.number("stage.fight.hit.points"))
	var inner_k: float = GlassPieces.number("stage.fight.hit.inner_k")
	var out: PackedVector2Array = PackedVector2Array()
	for i: int in points:
		var a: float = PI * i / (points / 2.0) - PI / 2.0
		var k: float = inner_k if i % 2 == 1 else 1.0
		var px: float = snappedf(50.0 + 50.0 * k * cos(a), 0.1)
		var py: float = snappedf(50.0 + 50.0 * k * sin(a), 0.1)
		out.append(rect.position + Vector2(px, py) / 100.0 * rect.size)
	return out


## The right light: the opponent's hero at the top, its Health and name under it.
func _build_opponent() -> void:
	var opponent: Dictionary = state.get("opponent", {})
	var x: float = 1904.0 - _f(_g["sideW"]) / 2.0 - GlassPieces.number("stage.fight.opp.port_left")
	var side: float = GlassPieces.number("stage.fight.opp.port")
	var port: GlassBox = GlassBox.new()
	port.name = "Opponent"
	port.box_size = Vector2(side, side)
	port.use_css("fight", ".opphero")
	port.radii = Vector4.ONE * side / 2.0
	port.image_texture = GlassPieces.portrait(str(opponent.get("portrait", "")))
	port.layers = [{"kind": "image", "size": "cover", "position": [50.0, 50.0]}]
	port.refresh()
	port.position = Vector2(x, GlassPieces.number("stage.fight.opp.port_y"))
	_front.add_child(port)
	var hp: GlassBox = GlassParts.health_badge(_i(opponent.get("health", 0)), [".hp"])
	hp.name = "OpponentHealth"
	hp.position = Vector2(
		x + GlassPieces.number("stage.fight.opp.hp_right"),
		GlassPieces.number("stage.fight.opp.hp_y")
	)
	_front.add_child(hp)
	var words: GlassText = GlassText.from_rule("stage", ".lbl", str(opponent.get("name", "")))
	words.name = "OpponentName"
	words.font_px = GlassPieces.number("stage.fight.opp.name_size")
	words.colour = GlassPieces.rule_colour("fight", ".oppname", "color")
	words.refresh()
	words.position = Vector2(
		x - GlassPieces.number("stage.fight.opp.name_left"),
		GlassPieces.number("stage.fight.opp.name_y")
	)
	_front.add_child(words)


## STAND-IN: the result over the transom, and the loser's damage as a splash on their portrait.
func _build_result() -> void:
	var moment: Dictionary = state.get("moment", {})
	if not moment.has("result"):
		return
	var result: Dictionary = moment["result"]
	var winner: int = _i(result.get("winner", -1))
	var words: String = "Draw"
	if winner >= 0:
		words = "Victory" if winner == _you() else "Defeat"
	var banner: GlassText = GlassText.from_rule("stage", ".lbl", words)
	banner.name = "Result"
	banner.font_px = 72.0
	banner.refresh()
	banner.z_index = 7
	banner.position = Vector2(
		960.0 - banner.size.x / 2.0, (_f(_g["T0"]) + _f(_g["T1"])) / 2.0 - banner.size.y / 2.0
	)
	_front.add_child(banner)
	var damage: int = _i(result.get("damage", 0))
	if winner < 0 or damage <= 0:
		return
	var r: float = GlassPieces.number("stage.fight.hit.dealt_r")
	var hit: Control = hit_splash(damage, r)
	hit.name = "ResultHit"
	var target: Control = _front.get_node("Opponent" if winner == _you() else "Hero")
	hit.position = target.position + target.size / 2.0 - Vector2(r, r)
	_front.add_child(hit)
