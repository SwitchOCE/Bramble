extends GutTest
## The Pigeon and Mouse reworks' marks on the screens (build plan S5b): Charge and Supply pips on
## cards, the reserve limit by the hand, and the Renown pill in a fight only on a unit that gets
## its slot's Renown (rulebook 11.7.3-11.7.8).

const Marks := preload("res://tests/screens/recruit_pigeon_marks.gd")
const Renown := preload("res://tests/screens/fight_renown.gd")
const RECRUIT: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const FIGHT: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")


func _recruit(flow: GameFlow) -> RecruitScreen:
	var screen: RecruitScreen = RECRUIT.instantiate()
	screen.state = ViewAdapter.recruit_state(flow)
	add_child_autofree(screen)
	return screen


## A board card's node by its card id.
func _board_card(screen: GlassScreen, id: String) -> GlassCard:
	for target: Dictionary in screen.targets_of("board"):
		var card: Dictionary = target["card"]
		var node: Control = target["node"]
		if str(card.get("id", "")) == id:
			return node as GlassCard
	return null


## [pips, of them spent] of one kind on a card.
func _pips(card: GlassCard, kind: String) -> Vector2i:
	var counted: Vector2i = Vector2i.ZERO
	var pips: Node = card.get_node_or_null("Pips")
	if pips == null:
		return counted
	for pip: Node in pips.get_children():
		if String(pip.name).begins_with("Pip_%s_" % kind):
			counted.x += 1
			if String(pip.name).ends_with("_spent"):
				counted.y += 1
				assert_almost_eq(
					(pip as Control).modulate.a, KeywordStyle.SPENT_ALPHA, 0.001, "dimmed"
				)
	return counted


func _front(screen: GlassScreen, prefix: String) -> int:
	var n: int = 0
	for child: Node in screen.get_node("Frame/Stage/Front").get_children():
		if String(child.name).begins_with(prefix) and not child.is_queued_for_deletion():
			n += 1
	return n


func test_recruit_cards_show_charge_and_supply_as_pips() -> void:
	var screen: RecruitScreen = _recruit(Marks.make_flow())
	assert_eq(_pips(_board_card(screen, "padre"), "charge"), Vector2i(4, 0), "Charge 4, full")
	assert_eq(_pips(_board_card(screen, "sentry"), "supply"), Vector2i(6, 4), "2 of 6 left")
	assert_null(_board_card(screen, "lance-corporal").get_node_or_null("Pips"), "no count")


func test_pips_read_the_cards_text_and_counters() -> void:
	var table: Dictionary = GameContent.load_default().display_table()
	var golden: Dictionary = {"text": "Charge 4: After a friendly unit dies, a Private steps in."}
	assert_eq(CardTerms.pips(golden, table), [{"kind": "charge", "total": 4, "left": 4}])
	var used: Dictionary = golden.duplicate()
	used["counters"] = [{"id": "pigeon_padre_uses", "value": 1}]
	assert_eq(CardTerms.pips(used, table), [{"kind": "charge", "total": 4, "left": 1}])
	assert_eq(CardTerms.all_pills(used, table), [], "its uses left are its pips, not a pill")
	var tripled: Dictionary = {
		"text": "Supply 6: At the end of your turn, give this slot 1 Renown.",
		"counters": [{"id": "supply:pigeon_sentry", "value": 14}],
	}
	assert_eq(CardTerms.pips(tripled, table), [{"kind": "supply", "total": 14, "left": 14}])
	assert_eq(CardTerms.pips({"text": "Guard."}, table), [])


func test_reserve_limit_shows_by_the_hand_only_with_a_reserve_unit_there() -> void:
	var state: Dictionary = ViewAdapter.recruit_state(Marks.make_flow())
	assert_eq(GlassPieces.as_int(state.get("reserve_limit", -1)), 2, "the game's limit")
	assert_eq(_front(_recruit(Marks.make_flow()), "ReserveLeft_"), 2)
	var none: Dictionary = ViewAdapter.recruit_state(Marks.make_flow(false, false))
	assert_false(none.has("reserve_limit"), "no Reserve unit in hand")
	assert_eq(_front(_recruit(Marks.make_flow(false, false)), "ReserveLeft_"), 0)


func test_a_quartermaster_raises_the_shown_limit() -> void:
	var flow: GameFlow = Marks.make_flow(true)
	assert_eq(flow.session.rules.reserve_limit(flow.human()), 3)
	assert_eq(_front(_recruit(flow), "ReserveLeft_"), 3)


func test_fight_renown_pill_only_on_starters_and_reservists() -> void:
	var replay: FightReplay = Renown.make_replay()
	var at: int = Renown.frame(replay)
	assert_gt(at, 0, "a frame with a reservist and a Hopper in Renown slots")
	var view: Dictionary = replay.steps[at]["state"]
	var you: int = CoreUtil.to_int(view["you_side"])
	var screen: FightScreen = FIGHT.instantiate()
	screen.state = view
	add_child_autofree(screen)
	var stage: Node = screen.get_node("Frame/Stage")
	var reservist: Node = stage.find_child("Unit_%d_0" % you, true, false)
	assert_not_null(reservist.get_node_or_null("Renown"), "the reservist from the hand")
	var starter: Node = stage.find_child("Unit_%d_4" % you, true, false)
	assert_not_null(starter.get_node_or_null("Renown"), "the Sky-darkener started there")
	for slot: int in [5, 6]:
		var hopper: Node = stage.find_child("Unit_%d_%d" % [you, slot], true, false)
		assert_null(hopper.get_node_or_null("Renown"), "a summoned Hopper gets none")
		var under: Node = stage.find_child("Slot_%d_%d" % [you, slot], true, false)
		assert_false((under.get_node("Renown") as CanvasItem).visible, "hidden under its unit")


func test_a_padre_dims_a_charge_pip_for_each_use_in_the_fight() -> void:
	var replay: FightReplay = Renown.make_replay()
	var at: int = Renown.frame(replay)
	var view: Dictionary = replay.steps[at]["state"]
	var you: int = CoreUtil.to_int(view["you_side"])
	var screen: FightScreen = FIGHT.instantiate()
	screen.state = view
	add_child_autofree(screen)
	var stage: Node = screen.get_node("Frame/Stage")
	var padre: GlassCard = stage.find_child("Unit_%d_2" % you, true, false) as GlassCard
	assert_eq(_pips(padre, "charge"), Vector2i(4, 1), "one friend has died: 3 of 4 left")
	var boards: Array = view["boards"]
	var row: Array = boards[you]
	var unit: Dictionary = row[2]
	assert_eq(screen._pill_words(unit), PackedStringArray(), "its uses show as pips, not a pill")
