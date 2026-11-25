extends Control
## The buy screen's lights (buy-screen-l1.md §9) for films and stills: a shop of chosen tiers, a
## board with golden and plain units, a hand, and End turn in its three states. The scenario's
## fields, or the exported ones when the scene is opened without a scenario (tools/look):
## shop_tiers [tier per arch, 0 for an empty arch], spell_tiers, level (the shop's tier),
## golden [board slots holding a golden unit], nothing_left (End turn's glow).
## Key N shows the same state with nothing left to do; key S shows it as it was (End turn steady).
## Named targets: "board:i", "hand:i", "end_turn". Nothing the screen asks is acted on.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")

@export var shop_tiers: Array[int] = [2, 3, 4, 5, 6]
@export var spell_tiers: Array[int] = [1, 3]
@export var level: int = 4
@export var golden: Array[int] = [1, 6]
@export var nothing_left: bool = false

var _screen: RecruitScreen
var _state: Dictionary
var _asked: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func feel_setup(scenario: Dictionary) -> void:
	shop_tiers = _ints(CoreUtil.to_array(scenario.get("shop_tiers", shop_tiers)))
	spell_tiers = _ints(CoreUtil.to_array(scenario.get("spell_tiers", spell_tiers)))
	level = GlassPieces.as_int(scenario.get("level", level))
	golden = _ints(CoreUtil.to_array(scenario.get("golden", golden)))
	nothing_left = scenario.get("nothing_left", nothing_left) == true
	_build()


static func _ints(values: Array) -> Array[int]:
	var out: Array[int] = []
	for value: Variant in values:
		out.append(GlassPieces.as_int(value))
	return out


func _build() -> void:
	if _screen != null:
		remove_child(_screen)
		_screen.free()
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = FlowFixture.live(content, 5)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.gold = 7
	me.tier = level
	var units: Array[UnitDef] = content.library.drawable_cards(false)
	var spells: Array[UnitDef] = content.library.drawable_cards(true)
	me.shop_units.clear()
	for tier: int in shop_tiers:
		me.shop_units.append(_first_of(units, maxi(tier, 1), me.shop_units))
	me.shop_spells.clear()
	for tier: int in spell_tiers:
		me.shop_spells.append(_first_of(spells, tier, me.shop_spells))
	var picks: Array[StringName] = []
	for slot: int in 7:
		var card: UnitDef = content.library.get_card(_first_of(units, 1 + slot % 4, picks))
		picks.append(card.id)
		me.place(flow.session.new_unit(card, golden.has(slot)), slot)
	me.hand.clear()
	for tier: int in [2, 3, 5]:
		var card: UnitDef = content.library.get_card(_first_of(units, tier, picks))
		picks.append(card.id)
		me.hand.append(flow.session.new_unit(card, false))
	flow.session.recruit.refresh_auras(me)
	_state = ViewAdapter.recruit_state(flow)
	var shown: Array = _state.get("shop_units", [])
	for i: int in shop_tiers.size():
		if shop_tiers[i] == 0 and i < shown.size():
			shown[i] = null
	_screen = SCREEN.instantiate()
	_screen.state = _with_nothing_left(_state) if nothing_left else _state
	_screen.action_requested.connect(func(action: Dictionary) -> void: _asked.append(action))
	add_child(_screen)
	_screen.settle()


## The first card of a tier not yet picked (the first of the tier when all are).
static func _first_of(cards: Array[UnitDef], tier: int, taken: Array[StringName]) -> StringName:
	var fallback: StringName = &""
	for card: UnitDef in cards:
		if card.tier != tier:
			continue
		if fallback == &"":
			fallback = card.id
		if not taken.has(card.id):
			return card.id
	return fallback


## The state with only the actions that leave nothing to do (sell, move, freeze, end turn).
static func _with_nothing_left(state: Dictionary) -> Dictionary:
	var out: Dictionary = state.duplicate(true)
	var kept: Array = []
	for action: Dictionary in out.get("legal_actions", []):
		if not RecruitColumns.END_TURN_ACTS.has(str(action.get("type", ""))):
			kept.append(action)
	out["legal_actions"] = kept
	return out


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_N:
		_screen.show_state(_with_nothing_left(_state))
	elif key.keycode == KEY_S:
		_screen.show_state(_state)


func feel_point(target: String) -> Variant:
	var box: Vector2 = _screen.card_box()
	var parts: PackedStringArray = target.split(":")
	var index: int = parts[1].to_int() if parts.size() > 1 else 0
	match parts[0]:
		"board":
			return _screen.slot_xy(index) + box / 2.0
		"hand":
			var hand: Array = _screen.state["hand"]
			var place: Vector3 = _screen.hand_place(index, hand.size())
			return Vector2(place.x, place.y) + Vector2(box.x / 2.0, box.y * 0.3)
		"end_turn":
			return L1Layout.rect("right.end_turn").get_center()
	return null


func feel_report() -> Dictionary:
	return {"asked": _asked}
