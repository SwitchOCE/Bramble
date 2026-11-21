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
##   slots: [side 0, side 1], each 7 {keywords: [{id}], label, renown} or {}
##     (a slot's lasting bonus, as GlassScreen.slot_info reads it)
##   unit: {id, uid, name, tier, art, attack, health, max_health, text, keywords: [id],
##     mechanics: [id], amounts: {mechanic: n}, counters: [{id, value}], renown}: Health under
##     max_health is drawn red; keywords and counters are STAND-IN pills on the card (the mock-up
##     has none); `renown` is the amount shown on the unit's own Renown pill
##   moment: {lunge: {side, slot, target_side, target_slot}, splashes: [{side, slot, amount,
##     blocked}] (amount 0: destroyed; blocked: a prevented hit, drawn as a 0),
##     trigger: {side, slot} (the unit whose effect is acting),
##     result: {winner, damage}}: what is happening right now; all of it optional
##
## Attack, impact and death motion follow the reference beats in fight-beats.md. Replay grouping
## and holds are unchanged; FightMotion owns the motion numbers. Red Health and the result
## banner retain the glass mock-up's drawing.

## The fight is over and its result is showing.
signal playback_finished
## The result is on the screen (its hold has just begun): the flow may move on from here.
signal result_shown

const FIGHT_READY_LINE: String = "fight_screen: ready"
## How long the attacker takes to lunge, in seconds at speed 1.
const LUNGE_TIME: float = FightMotion.ATTACK_TIME
## STAND-IN: how far a unit whose effect is acting lifts in place, and how fast.
const TRIGGER_LIFT: float = 14.0
const TRIGGER_TIME: float = 0.1
## STAND-IN: how much of the attacker's lunge a unit joining the attack moves.
const JOIN_SHARE: float = 0.6
## STAND-IN: the hover line of a unit whose terms count being outnumbered, while its side is.
const OUTNUMBERED_WORDS: String = "Outnumbered by %d."

## Playback speed: 2 plays twice as fast.
@export var speed: float = 1.0

var _replay: FightReplay
var _step: int = -1
var _wait: float = 0.0
## Last visual beats: state refreshes must not replay an attack or recoil.
var _shown_lunge: Dictionary = {}
var _shown_splashes: Array = []
var _attack_start: bool = false
var _impact_start: bool = false
var _recoiled: bool = false


func _geom() -> Dictionary:
	return GlassPieces.fight_geom()


func _ready_line() -> String:
	return FIGHT_READY_LINE


func _leaderboard_key() -> String:
	return "stage.fight.leaderboard"


func _ensure_stage() -> void:
	super()
	if not _keeper is FightMotion:
		_keeper = FightMotion.new(_cards)


func _on_new_state() -> void:
	var lunge: Dictionary = _lunge()
	_attack_start = not lunge.is_empty() and lunge != _shown_lunge
	if lunge != _shown_lunge or lunge.is_empty():
		_recoiled = false
	_shown_lunge = lunge.duplicate()
	var moment: Dictionary = state.get("moment", {})
	var splashes: Array = moment.get("splashes", [])
	_impact_start = not splashes.is_empty() and splashes != _shown_splashes
	_shown_splashes = splashes.duplicate(true)
	# A fixture opened on a single moment shows that moment at rest (including contact).
	if _keeper._kept.is_empty():
		_attack_start = false
		_impact_start = false
		return
	if not splashes.is_empty():
		_recoiled = true


# ---- playback ----


## Plays a fight: each step of the replay is shown for its hold time, then the next.
func play(replay: FightReplay) -> void:
	# a new fight starts from a clean table: no card of the last fight is left fading or popping
	if _keeper != null:
		_keeper.clear()
	_replay = replay
	_shown_lunge = {}
	_shown_splashes = []
	_recoiled = false
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
	Sound.fight_step(step)
	_wait = _f(step["hold"])
	if _step == _replay.steps.size() - 1:
		# the result: no dead unit still fading over its slot
		settle()
		result_shown.emit()


# ---- building ----


func _build() -> void:
	(_keeper as FightMotion).motions.clear()
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
	_attack_start = false
	_impact_start = false


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


## Contact follows the actual target, including back-row/diagonal attacks. The two card centres
## overlap slightly, rather than stopping at a fixed height short of the defending row.
func lunge_xy(lunge: Dictionary) -> Vector2:
	var from: Vector2 = unit_xy(_i(lunge["side"]), _i(lunge["slot"]))
	var to: Vector2 = unit_xy(_i(lunge["target_side"]), _i(lunge["target_slot"]))
	return to - (to - from).normalized() * _h() * FightMotion.CONTACT_PER_H


func _want_side(side: int) -> void:
	var boards: Array = state.get("boards", [[], []])
	var board: Array = boards[side] if side < boards.size() else []
	var all_slots: Array = state.get("slots", [[], []])
	var slots: Array = all_slots[side] if side < all_slots.size() else []
	var places: Array[Vector2] = []
	var bonuses: Array[Dictionary] = []
	for i: int in BOARD_SLOTS:
		places.append(unit_xy(side, i))
		var raw: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		bonuses.append(slot_info(raw))
	_slots.set_row("Slot_%d_" % side, places, card_box(), bonuses)
	var lunge: Dictionary = _lunge()
	for i: int in BOARD_SLOTS:
		var unit: Variant = board[i] if i < board.size() else null
		var info: Dictionary = bonuses[i]
		# the slot's own Renown banner shows while it is empty; a unit that gets it carries it
		var banner: CanvasItem = _slots.get_node_or_null("Slot_%d_%d/Renown" % [side, i])
		if banner != null:
			banner.visible = not unit is Dictionary
		if unit is Dictionary:
			var held: Dictionary = unit
			var extra: Dictionary = {}
			if info.has("keyword"):
				extra["keyword"] = str(info["keyword"])
			# Older replay views carry only whether the unit received its slot's Renown.
			var renown: int = _i(held.get("renown", 0))
			if not held.has("renown") and _b(held.get("renowned", false)):
				renown = _i(info.get("renown", 0))
			if renown != 0:
				extra["renown"] = renown
			var at: Vector2 = unit_xy(side, i)
			var time: float = -1.0
			# An attacker waiting for its pilers winds up at home; a piler jabs out (FightMotion)
			# and holds there until the attacker lunges.
			if _is_lunger(lunge, side, i) and not _recoiled and not _b(lunge.get("waiting", false)):
				at = lunge_xy(lunge)
				time = LUNGE_TIME
			elif _joins(side, i):
				at = join_xy(side, i, lunge)
				time = LUNGE_TIME
			elif _is_lunger(_trigger(), side, i):
				at.y -= TRIGGER_LIFT if side == _you() else -TRIGGER_LIFT
				time = TRIGGER_TIME
			var key: String = card_key("f%d_" % side, i, held)
			(_keeper as FightMotion).motions[key] = _card_motion(side, i, lunge)
			_want_card(key, "board", side * BOARD_SLOTS + i, held, at, 0.0, extra, time)


func _card_motion(side: int, slot: int, lunge: Dictionary) -> Dictionary:
	var direction: Vector2 = Vector2.DOWN if side == _you() else Vector2.UP
	var attacker: bool = _is_lunger(lunge, side, slot)
	if not lunge.is_empty():
		direction = (
			(
				unit_xy(_i(lunge["target_side"]), _i(lunge["target_slot"]))
				- unit_xy(_i(lunge["side"]), _i(lunge["slot"]))
			)
			. normalized()
		)
	var hit: Dictionary = {}
	for splash: Dictionary in _shown_splashes:
		if _i(splash["side"]) == side and _i(splash["slot"]) == slot:
			hit = splash
	var joining: bool = _joins(side, slot)
	return {
		"attack": _attack_start and attacker,
		"hit": _impact_start and (not hit.is_empty() or attacker) and not joining,
		"jab": _impact_start and joining,
		"home": unit_xy(side, slot),
		"received": not hit.is_empty(),
		"blocked": _b(hit.get("blocked", false)),
		"returning": attacker,
		"direction": direction,
		"death_direction": -direction if attacker else direction,
	}


## Whether a unit joins the attack now (a mouse piling on): moment.joins [{side, slot}].
func _joins(side: int, slot: int) -> bool:
	var moment: Dictionary = state.get("moment", {})
	for value: Variant in moment.get("joins", []):
		var join: Dictionary = value if value is Dictionary else {}
		if _i(join.get("side", -1)) == side and _i(join.get("slot", -1)) == slot:
			return true
	return false


## STAND-IN (stand-ins.html ?m=fight3): where a unit joining an attack jabs to and holds: from its
## own slot JOIN_SHARE of the way along the attacker's lunge.
func join_xy(side: int, slot: int, lunge: Dictionary) -> Vector2:
	var from: Vector2 = unit_xy(side, slot)
	if lunge.is_empty():
		return from
	return from + (lunge_xy(lunge) - unit_xy(_i(lunge["side"]), _i(lunge["slot"]))) * JOIN_SHARE


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
	if extra.has("keyword") and node is GlassCard:
		_slot_keyword_pill(node as GlassCard, str(extra["keyword"]))
	if extra.has("renown") and node is GlassCard:
		var card: GlassCard = node as GlassCard
		var banner: GlassBox = GlassSlot.renown_banner(
			_i(extra["renown"]), GlassCard.card_size(card.card_height)
		)
		banner.name = "Renown"
		card.add_child(banner)
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
			or _joins(side, index % BOARD_SLOTS)
		):
			card.set_glow("fight", ".card.lunge")
			card.z_index = _i(GlassPieces.rule("fight", ".card.lunge", "z-index"))
		else:
			card.set_glow("", "")
			card.z_index = 0


## Each splash starts at its recipient's current pose and follows its recoil upright.
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
		var recipient: Control = node_for("board", side * BOARD_SLOTS + slot)
		if recipient != null:
			at = recipient.position
		var hit: Control = hit_splash(_i(splash["amount"]), r, _b(splash.get("blocked", false)))
		hit.name = "Hit_%d" % k
		hit.position = at + Vector2(_w() / 2.0 - r, _h() * down - r)
		_front.add_child(hit)
		if _impact_start:
			(_keeper as FightMotion).burst(hit, recipient)


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


## Reminder lines for the hover, and for a unit whose terms count being outnumbered (Fury,
## Grudge) while its side is (combat_start's outnumbered_by, the unit's `outnumbered`): "Outnumbered
## by 2."
func _reminders(card: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = super(card)
	var n: int = _i(card.get("outnumbered", 0))
	if n <= 0:
		return lines
	for line: String in CardTerms.reminders(card, _display_table()):
		if CardTerms.mentions(line, "Outnumbered"):
			lines.append(OUTNUMBERED_WORDS % n)
			break
	return lines


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
