class_name RecruitMotion
extends Node2D
## The recruit batch of animations (fix round 20 Nov, plan step 12), built from the owner's
## accepted prototypes (docs/design/mockups/fix-round-20-nov/anim-recruit/, protos.js): refresh,
## tier-up, gold counting down as it is spent, a hand card swapped onto an occupied slot, a waiting
## card sliding into the hand when room frees, the waiting count popping, and a shop card's price
## tag dropping off as it is lifted. Every time below is the prototype's, in seconds from the
## moment the new state arrives (the click, or the let-go). The taste calls are logged in
## docs/workstreams/fix-round-20-nov/night-21-nov/taste-anim-recruit.md.
##
## It only moves what the screen already drew: the new state is on the stage before anything
## moves, and finish() lands every piece where the state has it (any press, a new state, a
## redraw).

## protos.js goldTo: the gold counts over 0.26 s; the gold button dips to 0.94 over 0.28 s.
const GOLD_COUNT: float = 0.26
const GOLD_DIP: float = 0.28
## protos.js refresh and tierup: the shop moves 40 ms after the click; the button's own press
## plays from the click.
const AFTER_CLICK: float = 0.04
## protos.js shopOut: each card 25 ms after the one before, sinking 24 px to 0.94 as it fades
## over 0.15 s (ease in); its tag fades over 0.1 s.
const OUT_STEP: float = 0.025
const OUT_TIME: float = 0.15
const OUT_SINK: float = 24.0
## protos.js shopIn, 0.14 s after the old shop starts to go: each card 50 ms after the one before,
## from 40 px up at 1.04 to 4 px past its place at 90 ms and settling at 220 ms (eased out); its tag
## swings in 140 ms after its card.
const IN_AFTER: float = 0.14
const IN_STEP: float = 0.05
## protos.js tierup: the sweep's band, 260 px wide and the card's height + 60, from 300 px left of
## the shop across it, 80 ms after the click, over 0.48 s.
const SWEEP_W: float = 260.0
const SWEEP_TIME: float = 0.48
## protos.js swap: the unit under a carried hand card lifts 12 px to 0.94 over 0.14 s; let go, it
## arcs 120 px up into the hand in 0.28 s, leaning 6 degrees, then hops. It dims to the swap's blue
## (recruit/NOTES.md 3, PR 241's tint), not the prototype's grey 0.85, and clears on the way.
const SWAP_LIFT: float = 12.0
const SWAP_SCALE: float = 0.94
const SWAP_TINT: Color = Color(0.67, 0.75, 0.83, 0.72)
const SWAP_TIME: float = 0.28
## protos.js fromwait: the waiting card leaves its stack 120 ms after the let-go, arcs 40 px over
## 0.32 s and hops; the rest of the hand closes the gap in 0.2 s and opens again 0.2 s in.
const JOIN_AFTER: float = 0.12
const JOIN_TIME: float = 0.32
const HOP_TIME: float = 0.2
## Drawn over the cards, under nothing (a flying card is the top of the stage).
const FLYING_Z: int = 8

static var _sweep_code: Shader

var _screen: RecruitScreen
var _timeline: GlassTimeline
## The last action the screen asked for, to tell a refresh from a new turn's shop.
var _asked: Dictionary = {}
## Shop nodes taken from the keeper before a refresh: [{node, kind, index}].
var _old_shop: Array[Dictionary] = []
## A waiting card that flies to the stack: its count pops as it lands.
var _pop_for: Control
## Whether this timeline moves cards (a refresh, a swap, a join): no hover detail meanwhile. A
## count or a button's flash leaves hover alone.
var _cards_moving: bool = false


func _init(screen: RecruitScreen) -> void:
	_screen = screen
	name = "RecruitMotion"
	z_index = 21


func _ready() -> void:
	_screen._keeper.flown.connect(_on_flown)


## The timeline the moves of this state go on, made with the first one (a Tween with nothing
## on it is an error).
func _tl() -> GlassTimeline:
	if _timeline == null or not _timeline.running():
		_timeline = GlassTimeline.new(self)
	return _timeline


func active() -> bool:
	return _timeline != null and _timeline.running()


## Whether cards are on their way somewhere (the hover detail waits).
func moving_cards() -> bool:
	return _cards_moving and active()


## The screen is about to ask for an action (its new state comes back from the handler).
func asked(action: Dictionary) -> void:
	_asked = action.duplicate()


## Everything where the state has it, at once. (Between before_state and after_state nothing has
## started: the old shop taken for a refresh waits for after_state.)
func finish() -> void:
	if _timeline != null:
		var timeline: GlassTimeline = _timeline
		_timeline = null
		timeline.finish()


## Before a new state is drawn: a refresh takes the old shop out of the keeper, so the old cards
## can sink away while the new ones (even one that rolled the same card) drop in.
func before_state(before: Dictionary, new_state: Dictionary) -> void:
	finish()
	_drop_old_shop()
	if _is_refresh(before, new_state):
		for kind: String in ["shop", "spell"]:
			for target: Dictionary in _screen.targets_of(kind):
				var node: Control = target["node"]
				var index: int = target["index"]
				var card: Dictionary = target["card"]
				var key: String = GlassScreen.card_key(kind, index, card)
				if _screen._keeper._kept.has(key) and is_instance_valid(node):
					_screen._keeper.stop(node)
					_screen._keeper._kept.erase(key)
					_old_shop.append({"node": node, "kind": kind, "index": target["index"]})


## After the new state is drawn: what changed since before moves as its prototype does.
func after_state(before: Dictionary) -> void:
	var action: Dictionary = _asked
	_asked = {}
	_cards_moving = false
	var state: Dictionary = _screen.state
	if before.is_empty() or not _screen._keeper.animate or not _screen.is_inside_tree():
		_drop_old_shop()
		return
	var same_turn: bool = before.get("turn", -1) == state.get("turn", -2)
	var tier_up: bool = (
		same_turn
		and GlassPieces.as_int(state.get("tier", 1)) > GlassPieces.as_int(before.get("tier", 1))
	)
	var spend_at: float = 0.0
	if not _old_shop.is_empty():
		_cards_moving = true
		_refresh(before)
		spend_at = AFTER_CLICK
	if tier_up:
		_tier_up(before)
		spend_at = AFTER_CLICK
	var old_gold: int = GlassPieces.as_int(before.get("gold", 0))
	var gold: int = GlassPieces.as_int(state.get("gold", 0))
	if same_turn and gold < old_gold:
		_spend(old_gold, gold, spend_at)
	if same_turn:
		_swap(before, action)
		_join(before)
		_pile_count(before)
	if _timeline != null:
		_timeline.on_end(_after_end)


## A shop card's price tag drops off as the card is lifted (protos.js buy: it falls 14 px as it
## fades over 0.14 s, easing in), left hanging where the card was.
func drop_tag(card: Control) -> void:
	var tag: Control = card.get_node_or_null("ShopTag")
	if tag == null or not tag.visible or not _screen._keeper.animate:
		return
	var price: GoldCoin = tag.get_node_or_null("Price") as GoldCoin
	var ghost: Control = RecruitShop.price_tag(
		price.amount if price != null else 0, price != null and price.poor
	)
	ghost.name = "DroppedTag"
	var at: Vector2 = card.get_transform() * tag.position
	_screen._front.add_child(ghost)
	var fall: Tween = ghost.create_tween()
	fall.tween_method(
		func(u: float) -> void:
			var k: float = GlassMotion.bezier(GlassMotion.IN, u)
			ghost.position = at + Vector2(0.0, 14.0 * k)
			ghost.modulate.a = 1.0 - k,
		0.0,
		1.0,
		0.14
	)
	fall.tween_callback(ghost.queue_free)


# ---- refresh (protos.js refresh) ----


func _is_refresh(before: Dictionary, new_state: Dictionary) -> bool:
	if str(_asked.get("type", "")) != "refresh" or before.is_empty():
		return false
	if before.get("turn", -1) != new_state.get("turn", -2):
		return false
	return (
		before.get("shop_units", []) != new_state.get("shop_units", [])
		or before.get("shop_spells", []) != new_state.get("shop_spells", [])
		or before.get("gold", 0) != new_state.get("gold", 0)
		or before.get("refreshes_left", 0) != new_state.get("refreshes_left", 0)
	)


func _refresh(before: Dictionary) -> void:
	_press(_button("refresh"), 0.0)
	var counter: GlassText = _screen._back.get_node_or_null("RefreshCounter") as GlassText
	if counter != null and before.has("refreshes_left"):
		var words: String = counter.words
		_set_words(counter, "%d left at this price" % GlassPieces.as_int(before["refreshes_left"]))
		_tl().call_at(AFTER_CLICK, func() -> void: _set_words(counter, words))
		_centre_pivot(counter)
		var base: Color = RecruitShop.SHOP_READOUT_TINT
		var lit: Color = Color("ffe08a")
		var tint: Color = Color(lit.r / base.r, lit.g / base.g, lit.b / base.b)
		_tl().frames(
			AFTER_CLICK,
			0.3,
			[[0.0, Vector3(1.15, 1.0, 0.0)], [1.0, Vector3(1.0, 0.0, 0.0)]],
			GlassMotion.OUT,
			func(v: Vector3) -> void:
				counter.scale = Vector2.ONE * v.x
				counter.modulate = Color.WHITE.lerp(tint, v.y)
		)
	var units: int = 0
	for entry: Dictionary in _old_shop:
		var node: Control = entry["node"]
		var order: int = GlassPieces.as_int(entry["index"])
		if entry["kind"] == "shop":
			units = maxi(units, order + 1)
		else:
			order += _shop_size(before)
		_shop_out(node, AFTER_CLICK + order * OUT_STEP)
	_shop_in(AFTER_CLICK + IN_AFTER)


func _shop_out(node: Control, at: float) -> void:
	CardKeeper.set_pivot(node, node.size / 2.0)
	var rest: Dictionary = GlassMotion.pose(node.position, node.rotation_degrees, node.scale.x)
	var sunk: Dictionary = GlassMotion.pose(node.position + Vector2(0.0, OUT_SINK), 0.0, 0.94)
	_tl().path(node, at, [[0.0, rest, 1.0], [OUT_TIME, sunk, 0.0]], GlassMotion.IN)
	var tag: Control = node.get_node_or_null("ShopTag")
	if tag != null:
		_tl().phase(at, 0.1, func(u: float) -> void: tag.modulate.a = 1.0 - u)


func _shop_in(start: float) -> void:
	var first_gap: float = GlassPieces.number("stage.recruit.spell.first_gap")
	for kind: String in ["shop", "spell"]:
		for target: Dictionary in _screen.targets_of(kind):
			var node: Control = target["node"]
			var index: int = target["index"]
			_screen._keeper.stop(node)
			CardKeeper.set_pivot(node, node.size / 2.0)
			var place: Vector2 = (
				_screen.shop_xy(index) if kind == "shop" else _screen.spell_xy(index)
			)
			var rest: Dictionary = GlassMotion.pose(place)
			node.modulate.a = 0.0
			GlassMotion.apply(node, rest)
			if kind == "shop":
				var at: float = start + index * IN_STEP
				(
					_tl()
					. path(
						node,
						at,
						[
							[0.0, GlassMotion.pose(place - Vector2(0.0, 40.0), 0.0, 1.04), 0.0],
							[0.09, GlassMotion.pose(place + Vector2(0.0, 4.0)), 1.0],
							[0.22, rest, 1.0],
						],
						GlassMotion.OUT
					)
				)
				_swing_tag(node.get_node_or_null("ShopTag") as Control, at + 0.14)
			else:
				var at: float = start + (first_gap + index) * IN_STEP + 0.02
				(
					_tl()
					. path(
						node,
						at,
						[
							[0.0, GlassMotion.pose(place - Vector2(0.0, 30.0)), 0.0],
							[0.09, GlassMotion.pose(place + Vector2(0.0, 3.0)), 1.0],
							[0.22, rest, 1.0],
						],
						GlassMotion.OUT
					)
				)


## protos.js shopIn: a price tag swings in about its pin, from -28 degrees through 10, as it
## shows, over 0.26 s.
func _swing_tag(tag: Control, at: float) -> void:
	if tag == null:
		return
	tag.modulate.a = 0.0
	_tl().frames(
		at,
		0.26,
		[[0.0, Vector2(0.0, -28.0)], [0.5, Vector2(1.0, 10.0)], [1.0, Vector2(1.0, 0.0)]],
		GlassMotion.OUT,
		func(v: Vector2) -> void:
			tag.modulate.a = v.x
			tag.rotation_degrees = v.y
	)


static func _shop_size(state: Dictionary) -> int:
	var units: Array = state.get("shop_units", [])
	return units.size()


# ---- tier up (protos.js tierup) ----


func _tier_up(before: Dictionary) -> void:
	var button: Control = _button("tier")
	if button != null:
		_centre_pivot(button)
		_tl().frames(
			0.0,
			0.42,
			[[0.0, Vector2(1.0, 1.0)], [0.3, Vector2(1.7, 1.06)], [1.0, Vector2(1.0, 1.0)]],
			GlassMotion.OUT,
			func(v: Vector2) -> void:
				button.modulate = Color(v.x, v.x, v.x)
				button.scale = Vector2.ONE * v.y
		)
		var tiers: GlassText = button.find_child("Tiers", true, false) as GlassText
		if tiers != null:
			var words: String = tiers.words
			var old: int = GlassPieces.as_int(before.get("tier", 1))
			_set_words(tiers, "%d → %d" % [old, old + 1])
			_centre_pivot(tiers)
			_tl().frames(
				0.02,
				0.11,
				[[0.0, 0.0], [1.0, 90.0]],
				GlassMotion.IN,
				func(deg: float) -> void: tiers.scale.y = cos(deg_to_rad(deg))
			)
			_tl().call_at(0.13, func() -> void: _set_words(tiers, words))
			_tl().frames(
				0.13,
				0.18,
				[[0.0, -90.0], [1.0, 0.0]],
				GlassMotion.OUT,
				func(deg: float) -> void: tiers.scale.y = cos(deg_to_rad(deg))
			)
		var cost: GoldCoin = button.find_child("Cost", true, false) as GoldCoin
		if cost != null and before.get("upgrade_cost") != null:
			var value: int = cost.amount
			cost.amount = GlassPieces.as_int(before["upgrade_cost"])
			cost.queue_redraw()
			_tl().call_at(
				0.13,
				func() -> void:
					cost.amount = value
					cost.queue_redraw()
			)
	_sweep(0.08)


## protos.js tierup: a band of warm light sweeps across the shop, left to right.
func _sweep(at: float) -> void:
	var band: ColorRect = ColorRect.new()
	band.name = "TierSweep"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.size = Vector2(SWEEP_W, _screen.card_box().y + 60.0)
	var look: ShaderMaterial = ShaderMaterial.new()
	look.shader = _sweep_shader()
	band.material = look
	var left: Vector2 = Vector2(_screen.geom("shopL") - 300.0, _screen.geom("shopTop") - 30.0)
	var travel: float = _screen.geom("shopW") + 340.0
	band.position = left
	band.modulate.a = 0.0
	add_child(band)
	_tl().frames(
		at,
		SWEEP_TIME,
		[
			[0.0, Vector2(0.0, 0.0)],
			[0.2, Vector2(0.2, 1.0)],
			[0.8, Vector2(0.8, 1.0)],
			[1.0, Vector2(1.0, 0.0)]
		],
		GlassMotion.INOUT,
		func(v: Vector2) -> void:
			band.position = left + Vector2(travel * v.x, 0.0)
			band.modulate.a = v.y
	)
	_tl().call_at(at + SWEEP_TIME, band.queue_free)


## stage .sweep: a horizontal gradient, clear to rgba(255,236,180,.6) to clear, screened over the
## shop and blurred 8 px (its top and bottom edges soften).
static func _sweep_shader() -> Shader:
	if _sweep_code == null:
		_sweep_code = Shader.new()
		_sweep_code.code = """
shader_type canvas_item;
render_mode blend_add;
void fragment() {
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float edge = smoothstep(0.0, 0.06, UV.y) * smoothstep(0.0, 0.06, 1.0 - UV.y);
	float a = 0.6 * across * edge * COLOR.a;
	COLOR = vec4(vec3(1.0, 0.925, 0.706), a);
}
"""
	return _sweep_code


# ---- gold ----


## protos.js goldTo: spent gold counts down and the gold button dips.
func _spend(from: int, to: int, at: float) -> void:
	var counts: RecruitCounts = _screen._counts
	counts.show_gold(from)
	_tl().count(at, GOLD_COUNT, from, to, func(v: int) -> void: counts.show_gold(v))
	_tl().call_at(at + GOLD_COUNT, func() -> void: counts.show_gold(counts.gold()))
	var button: Control = _button("gold")
	if button == null:
		return
	_centre_pivot(button)
	_tl().frames(
		at,
		GOLD_DIP,
		[[0.0, 1.0], [0.3, 0.94], [1.0, 1.0]],
		GlassMotion.OUT,
		func(v: float) -> void: button.scale = Vector2.ONE * v
	)


# ---- swap (protos.js swap) ----


## A hand unit put on an occupied slot: the unit that was there arcs from its lifted place into
## the hand, where the played card was, and hops.
func _swap(before: Dictionary, action: Dictionary) -> void:
	if str(action.get("type", "")) != "play" or not action.has("slot"):
		return
	var slot: int = GlassPieces.as_int(action["slot"])
	var board: Array = before.get("board", [])
	var was: Variant = board[slot] if slot >= 0 and slot < board.size() else null
	if not was is Dictionary:
		return
	var unit: Dictionary = was
	var uid: int = GlassPieces.as_int(unit.get("uid", -1))
	var hand: Array = _screen.state.get("hand", [])
	for target: Dictionary in _screen.targets_of("hand"):
		var card: Dictionary = target["card"]
		if GlassPieces.as_int(card.get("uid", -2)) != uid:
			continue
		var node: Control = target["node"]
		var index: int = target["index"]
		_cards_moving = true
		_screen._keeper.stop(node)
		var place: Vector3 = _screen.hand_place(index, hand.size())
		var foot: Vector2 = Vector2(node.size.x / 2.0, node.size.y)
		var middle: Vector2 = node.size / 2.0
		node.pivot_offset = middle
		var from: Dictionary = GlassMotion.pose(
			_screen.slot_xy(slot) - Vector2(0.0, SWAP_LIFT), 0.0, SWAP_SCALE
		)
		var rest: Dictionary = GlassMotion.pose(
			_about_middle(Vector2(place.x, place.y), place.z, foot, middle), place.z
		)
		GlassMotion.apply(node, from)
		node.modulate = SWAP_TINT
		node.z_index = FLYING_Z
		_tl().fly(node, from, rest, 0.0, SWAP_TIME, "arrive", 120.0, -6.0)
		_tl().frames(
			0.0,
			0.2,
			[[0.0, 0.0], [1.0, 1.0]],
			GlassMotion.OUT,
			func(v: float) -> void: node.modulate = SWAP_TINT.lerp(Color.WHITE, v)
		)
		_tl().phase(
			SWAP_TIME,
			HOP_TIME,
			func(u: float) -> void: GlassMotion.apply(node, GlassMotion.hop(rest, node.size.y, u))
		)
		_tl().on_end(
			func() -> void:
				if is_instance_valid(node):
					GlassMotion.apply(node, rest)
					node.modulate = Color.WHITE
					node.z_index = 0
					CardKeeper.set_pivot(node, foot)
		)
		return


## The top left a card turned about its middle needs to sit where it sits turned about its foot.
static func _about_middle(at: Vector2, turn: float, foot: Vector2, middle: Vector2) -> Vector2:
	var shift: Vector2 = foot - middle
	return at + shift - shift.rotated(deg_to_rad(turn))


# ---- the waiting stack (protos.js fromwait, towait) ----


## Room freed in the hand: each card that joins it from the waiting stack slides in from the stack,
## the hand closing round the card that left and opening for the one that joins.
func _join(before: Dictionary) -> void:
	var old_pile: Array = before.get("waiting_pile", [])
	var old_hand: Array = before.get("hand", [])
	var waiting: Dictionary = _uids(old_pile)
	var held: Dictionary = _uids(old_hand)
	var hand: Array = _screen.state.get("hand", [])
	var n: int = hand.size()
	var joining: Array[Dictionary] = []
	var staying: Array[Dictionary] = []
	for target: Dictionary in _screen.targets_of("hand"):
		var card: Dictionary = target["card"]
		var uid: int = GlassPieces.as_int(card.get("uid", -1))
		if waiting.has(uid):
			joining.append(target)
		elif held.has(uid):
			staying.append(target)
	if joining.is_empty():
		return
	_cards_moving = true
	var left: int = old_hand.size() - staying.size()
	if left > 0:
		for j: int in staying.size():
			var node: Control = staying[j]["node"]
			if _screen._keeper.is_landing(node):
				continue
			_screen._keeper.stop(node)
			var dip: Vector3 = _screen.hand_place(j, staying.size())
			_tl().fly(
				node,
				_pose_of(node),
				GlassMotion.pose(Vector2(dip.x, dip.y), dip.z),
				0.0,
				0.2,
				"out"
			)
		_hand_count(staying.size(), 0.0)
	for target: Dictionary in staying:
		var node: Control = target["node"]
		if _screen._keeper.is_landing(node):
			continue
		_screen._keeper.stop(node)
		var index: int = target["index"]
		var place: Vector3 = _screen.hand_place(index, n)
		var dip_place: Vector3 = _screen.hand_place(staying.find(target), staying.size())
		var from: Dictionary = (
			GlassMotion.pose(Vector2(dip_place.x, dip_place.y), dip_place.z)
			if left > 0
			else _pose_of(node)
		)
		_tl().fly(
			node, from, GlassMotion.pose(Vector2(place.x, place.y), place.z), 0.2, 0.22, "out"
		)
	var top: Vector2 = RecruitWaitingPile.TOP
	for j: int in joining.size():
		var target: Dictionary = joining[j]
		var node: Control = target["node"]
		var index: int = target["index"]
		var card: Dictionary = target["card"]
		if _screen._input.aim_place(GlassScreen.card_key("hand", index, card)) != null:
			# held up while its Recruit target is chosen: it stands there, it does not slide
			continue
		_screen._keeper.stop(node)
		var place: Vector3 = _screen.hand_place(index, n)
		var foot: Vector2 = Vector2(node.size.x / 2.0, node.size.y)
		node.pivot_offset = foot
		var from: Dictionary = _pose_of(node)
		if node.modulate.a < 1.0 or from["at"] == Vector2(place.x, place.y):
			# from deeper in the stack than it draws: from the top of the stack
			from = GlassMotion.pose(top, 9.0)
		node.modulate = Color(0.86, 0.86, 0.86)
		GlassMotion.apply(node, from)
		var rest: Dictionary = GlassMotion.pose(Vector2(place.x, place.y), place.z)
		var at: float = JOIN_AFTER + j * IN_STEP
		_tl().call_at(at, func() -> void: node.z_index = FLYING_Z)
		_tl().fly(node, from, rest, at, JOIN_TIME, "inout", 40.0)
		_tl().phase(
			at,
			JOIN_TIME,
			func(u: float) -> void:
				var v: float = lerpf(0.86, 1.0, u)
				node.modulate = Color(v, v, v)
		)
		_tl().phase(
			at + JOIN_TIME,
			HOP_TIME,
			func(u: float) -> void: GlassMotion.apply(node, GlassMotion.hop(rest, node.size.y, u))
		)
		_tl().on_end(
			func() -> void:
				if is_instance_valid(node):
					GlassMotion.apply(node, rest)
					node.modulate = Color.WHITE
					node.z_index = 0
		)
	_hand_count(n, JOIN_AFTER + JOIN_TIME)
	var pile: Array = _screen.state.get("waiting_pile", [])
	if pile.is_empty():
		_count_goes(JOIN_AFTER, waiting.size())


## The waiting count's chip shrinks away as the stack empties (fades to 0.4 over 0.16 s).
func _count_goes(at: float, was: int) -> void:
	var chip: Control = RecruitWaitingPile.count_chip(was)
	chip.name = "WaitingCountGone"
	chip.position = RecruitWaitingPile.TOP + RecruitWaitingPile.COUNT_OFFSET
	chip.pivot_offset = chip.size / 2.0
	_screen._front.add_child(chip)
	_tl().frames(
		at,
		0.16,
		[[0.0, Vector2(1.0, 1.0)], [1.0, Vector2(0.0, 0.4)]],
		GlassMotion.IN,
		func(v: Vector2) -> void:
			chip.modulate.a = v.x
			chip.scale = Vector2.ONE * v.y
	)
	_tl().on_end(func() -> void: _free(chip))


## A card joins the waiting stack: its count pops in as the card lands (from 1.8 times, 0.26 s).
func _pile_count(before: Dictionary) -> void:
	var old_pile: Array = before.get("waiting_pile", [])
	var was: int = old_pile.size()
	var cards: Array = _screen.state.get("waiting_pile", [])
	if cards.size() <= was:
		return
	var chip: Control = _screen._front.get_node_or_null("WaitingCount")
	if chip == null:
		return
	chip.modulate.a = 0.0
	var top: Control = null
	for target: Dictionary in _screen.targets_of("waiting_pile"):
		if GlassPieces.as_int(target["index"]) == cards.size() - 1:
			top = target["node"]
	if top != null and _screen._keeper.is_flying(top):
		_pop_for = top
		return
	_pop(chip, 0.0)


func _on_flown(node: Control) -> void:
	if node == null or node != _pop_for:
		return
	_pop_for = null
	var chip: Control = _screen._front.get_node_or_null("WaitingCount")
	if chip == null:
		return
	# the screen's timeline has started: the pop runs on its own
	chip.pivot_offset = chip.size / 2.0
	var pop: Tween = chip.create_tween()
	pop.tween_method(
		func(u: float) -> void:
			var k: float = GlassMotion.bezier(GlassMotion.OUT, u)
			chip.modulate.a = k
			chip.scale = Vector2.ONE * lerpf(1.8, 1.0, k),
		0.0,
		1.0,
		0.26
	)


func _pop(chip: Control, at: float) -> void:
	chip.pivot_offset = chip.size / 2.0
	_tl().frames(
		at,
		0.26,
		[[0.0, Vector2(0.0, 1.8)], [1.0, Vector2(1.0, 1.0)]],
		GlassMotion.OUT,
		func(v: Vector2) -> void:
			chip.modulate.a = v.x
			chip.scale = Vector2.ONE * v.y
	)


func _hand_count(shown: int, at: float) -> void:
	_tl().call_at(
		at,
		func() -> void:
			var label: GlassText = _screen._front.get_node_or_null("HandCount") as GlassText
			if label != null:
				var limit: int = GlassPieces.as_int(_screen.state.get("hand_limit", 7))
				_set_words(label, "Hand %d/%d" % [shown, limit])
	)


# ---- shared ----


## protos.js press(): a button dips to 0.93 and brightens 1.25 over 0.2 s.
func _press(button: Control, at: float) -> void:
	if button == null:
		return
	_centre_pivot(button)
	_tl().frames(
		at,
		0.2,
		[[0.0, Vector2(1.0, 1.0)], [0.35, Vector2(0.93, 1.25)], [1.0, Vector2(1.0, 1.0)]],
		GlassMotion.OUT,
		func(v: Vector2) -> void:
			button.scale = Vector2.ONE * v.x
			button.modulate = Color(v.y, v.y, v.y)
	)


func _button(id: String) -> Control:
	var button: Control = _screen._back.get_node_or_null("Button_" + id)
	if button == null:
		button = _screen._back.get_node_or_null("Button_%s_short" % id)
	return button


func _drop_old_shop() -> void:
	for entry: Dictionary in _old_shop:
		var node: Node = entry["node"]
		_free(node)
	_old_shop.clear()


func _after_end() -> void:
	_drop_old_shop()
	for target: Dictionary in _screen.targets_of("shop") + _screen.targets_of("spell"):
		var node: Control = target["node"]
		if is_instance_valid(node) and not _screen._keeper.is_busy(node):
			node.modulate.a = 1.0
			var tag: Control = node.get_node_or_null("ShopTag")
			if tag != null:
				tag.modulate.a = 1.0
				tag.rotation = 0.0
	var chip: Control = _screen._front.get_node_or_null("WaitingCount")
	if chip != null:
		chip.modulate.a = 1.0
		chip.scale = Vector2.ONE


static func _pose_of(node: Control) -> Dictionary:
	return GlassMotion.pose(node.position, node.rotation_degrees, node.scale.x)


static func _centre_pivot(node: Control) -> void:
	node.pivot_offset = node.size / 2.0


static func _set_words(label: GlassText, words: String) -> void:
	if label.words != words:
		label.words = words
		label.refresh()


static func _uids(cards: Array) -> Dictionary:
	var out: Dictionary = {}
	for card: Variant in cards:
		if card is Dictionary:
			var held: Dictionary = card
			out[GlassPieces.as_int(held.get("uid", -1))] = true
	return out


static func _free(node: Node) -> void:
	if is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()
