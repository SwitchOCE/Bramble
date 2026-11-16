class_name FightScreen
extends RecruitScreen
## The fight screen in lead and stained glass, rebuilt from fight.html: the recruit screen's
## window, hero, leaderboard and hover, with the opponent's board in the shop's light, its front
## row facing yours across the transom. It draws one plain view state (show_state) and can play a
## fight log through FightReplay (play). It holds no rules and sends no requests.
##
## The view state (tests/screens/fixtures/fight_start.json and fight_mid.json are examples):
##   turn, health, hero, players: as the recruit screen's
##   opponent: {name, portrait, health}
##   you_side: which of the two boards is yours (the rules core's side, 0 or 1)
##   boards: [side 0, side 1], each 7 entries, unit or null, slots 0-6 in reading order
##   slots: [side 0, side 1], each 7 {buff, buff_name} or {} (a slot's lasting bonus)
##   unit: {id, uid, name, tier, art, attack, health, max_health, text, keywords: [String],
##     badges: [{label, value}]}: Health under max_health is drawn red; keywords and badges are
##     STAND-IN pills on the card (the mock-up has none)
##   moment: {lunge: {side, slot, target_side, target_slot}, splashes: [{side, slot, amount}],
##     result: {winner, damage}}: what is happening right now; all of it optional
##
## STAND-IN (fight.html's own): the lunge, the damage splashes and red Health. The result banner,
## the pills and the playback timing are this screen's stand-ins; fight animation is not designed.

## The fight is over and its result is showing.
signal playback_finished

const FIGHT_READY_LINE: String = "fight_screen: ready"
## How long the attacker takes to lunge, in seconds at speed 1.
const LUNGE_TIME: float = 0.16

## Playback speed: 2 plays twice as fast.
@export var speed: float = 1.0

var _frame: Control
var _replay: FightReplay
var _step: int = -1
var _wait: float = 0.0


func _geom() -> Dictionary:
	return GlassPieces.fight_geom()


func _ready_line() -> String:
	return FIGHT_READY_LINE


func _leaderboard_key() -> String:
	return "stage.fight.leaderboard"


# ---- playback ----


## Plays a fight: each step of the replay is shown for its hold time, then the next.
func play(replay: FightReplay) -> void:
	_replay = replay
	_step = -1
	_wait = 0.0
	_next_step()


## Jumps to the end of the fight being played.
func skip() -> void:
	if _replay == null:
		return
	_step = _replay.steps.size() - 2
	_wait = 0.0
	_next_step()


func is_playing() -> bool:
	return _replay != null


func _process(delta: float) -> void:
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
	var before: Dictionary = state.get("moment", {})
	var view: Dictionary = step["state"]
	show_state(view)
	_wait = _f(step["hold"])
	var moment: Dictionary = state.get("moment", {})
	if moment.has("lunge") and not before.has("lunge"):
		var lunge: Dictionary = moment["lunge"]
		_tween_lunge(lunge)


## The attacker moves from its slot to its lunge place, the splashes waiting until it lands.
func _tween_lunge(lunge: Dictionary) -> void:
	var node: Control = _stage.get_node_or_null(_card_name(_i(lunge["side"]), _i(lunge["slot"])))
	if node == null:
		return
	var to: Vector2 = node.position
	node.position = unit_xy(_i(lunge["side"]), _i(lunge["slot"]))
	var tween: Tween = create_tween()
	tween.tween_property(node, "position", to, LUNGE_TIME / maxf(speed, 0.01))
	for child: Node in _stage.get_children():
		if String(child.name).begins_with("Hit_"):
			var hit: CanvasItem = child
			hit.visible = false
			tween.tween_callback(hit.show)


# ---- building ----


func _rebuild() -> void:
	if _frame != null:
		remove_child(_frame)
		_frame.queue_free()
	_targets.clear()
	_hot = null
	_frame = Control.new()
	_frame.name = "Frame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.size = Vector2(GlassPieces.number("stage.width"), GlassPieces.number("stage.height"))
	add_child(_frame)
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.size = _frame.size
	_frame.add_child(_stage)
	_fit()
	var window: StoneWindow = StoneWindow.new()
	window.name = "Window"
	_stage.add_child(window)
	window.build(_g)
	var you: int = _you()
	_build_side(1 - you)
	_build_side(you)
	_build_moment()
	_build_hero()
	_build_opponent()
	if show_leaderboard:
		_build_leaderboard()
	var vig: GlassBox = GlassBox.new()
	vig.name = "Vignette"
	vig.box_size = _stage.size
	vig.use_css("stage", "#vig").refresh()
	_stage.add_child(vig)
	_build_result()
	_tip = Control.new()
	_tip.name = "Tip"
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.z_index = _i(GlassPieces.rule("stage", "#tip", "z-index"))
	_tip.visible = false
	_stage.add_child(_tip)
	if pinned_hover != "":
		_pin_hover(pinned_hover)


func _fit() -> void:
	if _frame != null:
		_frame.position = ((size - _frame.size) / 2.0).floor()


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


static func _card_name(side: int, slot: int) -> String:
	return "Unit_%d_%d" % [side, slot]


func _build_side(side: int) -> void:
	var boards: Array = state.get("boards", [[], []])
	var board: Array = boards[side] if side < boards.size() else []
	var all_slots: Array = state.get("slots", [[], []])
	var slots: Array = all_slots[side] if side < all_slots.size() else []
	var moment: Dictionary = state.get("moment", {})
	var lunge: Dictionary = moment.get("lunge", {})
	for i: int in BOARD_SLOTS:
		var unit: Variant = board[i] if i < board.size() else null
		var info: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		if unit is Dictionary:
			var held: Dictionary = unit
			var card: GlassCard = _unit_card(held, _h())
			card.name = _card_name(side, i)
			card.position = unit_xy(side, i)
			if not lunge.is_empty() and _i(lunge["side"]) == side and _i(lunge["slot"]) == i:
				card.position = lunge_xy(lunge)
				card.set_glow("fight", ".card.lunge")
				card.z_index = _i(GlassPieces.rule("fight", ".card.lunge", "z-index"))
			_add_card(card, "board", side * BOARD_SLOTS + i, held)
			if info.has("buff"):
				_slot_buff_pill(card, str(info["buff"]))
			continue
		var slot: GlassBox = _slot(info)
		slot.name = "Slot_%d_%d" % [side, i]
		slot.position = unit_xy(side, i)
		_stage.add_child(slot)


## The unit card with fight state: red Health under its most, and its keywords and badges as
## STAND-IN pills down the art (no design exists for either).
func _unit_card(unit: Dictionary, height: float) -> GlassCard:
	var card: GlassCard = super._unit_card(unit, height)
	card.hurt = unit.has("max_health") and _i(unit["health"]) < _i(unit["max_health"])
	var words: PackedStringArray = PackedStringArray()
	for keyword: Variant in unit.get("keywords", []):
		words.append(str(keyword).replace("_", " ").capitalize())
	for badge: Variant in unit.get("badges", []):
		if badge is Dictionary:
			var b: Dictionary = badge
			words.append(("%s %s" % [b.get("label", ""), b.get("value", "")]).strip_edges())
	if _b(unit.get("golden", false)):
		words.append("Golden")
	var y: float = height * 0.2
	for text: String in words:
		var pill: GlassBox = _pill(text)
		pill.name = "Pill"
		pill.scale = Vector2.ONE * height / _h()
		pill.position = Vector2((card.size.x - pill.box_size.x * pill.scale.x) / 2.0, y)
		card.add_child(pill)
		y += (pill.box_size.y + 4.0) * pill.scale.y
	return card


## STAND-IN: a slot's lasting bonus under a unit standing on it, at the card's foot.
func _slot_buff_pill(card: GlassCard, buff: String) -> void:
	var pill: GlassBox = _pill(buff)
	pill.name = "SlotBuff"
	pill.position = Vector2((card.size.x - pill.box_size.x) / 2.0, card.size.y - pill.box_size.y)
	card.add_child(pill)


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
		var hit: Control = hit_splash(_i(splash["amount"]), r)
		hit.name = "Hit_%d" % k
		hit.position = at + Vector2(_w() / 2.0 - r, _h() * down - r)
		_stage.add_child(hit)


## fight.html hit(): an eight-pointed burst in lead, its glass red, the damage on it.
static func hit_splash(amount: int, r: float) -> Control:
	var outer: Rect2 = Rect2(0, 0, 2.0 * r, 2.0 * r)
	var root: Control = Control.new()
	root.size = outer.size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = GlassPieces.as_int(GlassPieces.rule("fight", ".hit", "z-index"))
	var lead: Color = GlassPieces.rule_colour("fight", ".hit i", "background")
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
	var words: GlassText = GlassText.from_rule("fight", ".hit b", "-%d" % amount)
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
	_stage.add_child(port)
	var hp: GlassBox = _health(_i(opponent.get("health", 0)), [".hp"])
	hp.name = "OpponentHealth"
	hp.position = Vector2(
		x + GlassPieces.number("stage.fight.opp.hp_right"),
		GlassPieces.number("stage.fight.opp.hp_y")
	)
	_stage.add_child(hp)
	var words: GlassText = GlassText.from_rule("stage", ".lbl", str(opponent.get("name", "")))
	words.name = "OpponentName"
	words.font_px = GlassPieces.number("stage.fight.opp.name_size")
	words.colour = GlassPieces.rule_colour("fight", ".oppname", "color")
	words.refresh()
	words.position = Vector2(
		x - GlassPieces.number("stage.fight.opp.name_left"),
		GlassPieces.number("stage.fight.opp.name_y")
	)
	_stage.add_child(words)


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
	_stage.add_child(banner)
	var damage: int = _i(result.get("damage", 0))
	if winner < 0 or damage <= 0:
		return
	var r: float = GlassPieces.number("stage.fight.hit.dealt_r")
	var hit: Control = hit_splash(damage, r)
	hit.name = "ResultHit"
	var target: Control = _stage.get_node("Opponent" if winner == _you() else "Hero")
	hit.position = target.position + target.size / 2.0 - Vector2(r, r)
	_stage.add_child(hit)


# ---- input: hover only ----


func _gui_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null or _frame == null:
		return
	var here: Vector2 = motion.position - _frame.position
	var over: Dictionary = _target_at(here, true)
	if over.is_empty():
		if pinned_hover == "":
			_hide_tip()
	else:
		_show_tip(over, here)
