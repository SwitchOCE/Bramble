extends GutTest
## The Pigeon and Mouse reworks' marks on the screens (build plan S5b): Charge and Supply pips on
## cards, the reserve limit by the hand, and the Renown pill in a fight only on a unit that gets
## its slot's Renown (rulebook 11.7.3-11.7.8).

const Marks := preload("res://tests/screens/recruit_pigeon_marks.gd")
const Renown := preload("res://tests/screens/fight_renown.gd")
const CoreKit := preload("res://tests/core/core_kit.gd")
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


func _colonel_replay(golden: bool) -> FightReplay:
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = FlowFixture.live(content, 11)
	flow.start_round()
	var session: GameSession = flow.session
	var me: PlayerState = flow.human()
	me.slots[0].renown = 3
	me.slots[0].keywords.append(&"taunt")
	CoreKit.put(session, me, "sentry", 0)
	var colonel: Unit = CoreKit.unit(session, "the-colonel", golden)
	colonel.stats.set_attack = 0
	me.place(colonel, 4)
	var bugler: Unit = CoreKit.put(session, me, "bugler", 5)
	bugler.stats.set_attack = 0
	me.hand.append(CoreKit.unit(session, "territorial"))
	session.recruit.refresh_auras(me)
	me.turn_ended = true
	var them: PlayerState = session.player(session.opponent_of(GameFlow.HUMAN))
	var enemy: Unit = CoreKit.put(session, them, "regimental-sergeant-major", 0)
	enemy.stats.set_attack = 50
	enemy.stats.set_health = 500
	them.turn_ended = true
	var record: Dictionary = flow.finish_round()
	var events: Array = record["events"]
	return FightReplay.build(
		ViewAdapter.fight_base(flow, record),
		events,
		ViewAdapter.catalog(content),
		CoreUtil.to_int(record["damage"])
	)


func _fight_screen_at_entry(replay: FightReplay, id: String) -> FightScreen:
	for step: Dictionary in replay.steps:
		var view: Dictionary = step["state"]
		var row: Array = view["boards"][CoreUtil.to_int(view["you_side"])]
		var card: Dictionary = row[0] if row[0] is Dictionary else {}
		if card.get("id") == id:
			var screen: FightScreen = FIGHT.instantiate()
			screen.state = view
			add_child_autofree(screen)
			return screen
	return null


func test_a_bugler_dims_a_charge_pip_after_calling_a_private() -> void:
	var replay: FightReplay = _colonel_replay(false)
	var before: FightScreen = _fight_screen_at_entry(replay, "sentry")
	var after: FightScreen = _fight_screen_at_entry(replay, "private")
	assert_not_null(before, "a starter occupied the slot")
	assert_not_null(after, "a Private stepped in")
	if before == null or after == null:
		return
	assert_eq(_pips(_board_card(before, "bugler"), "charge"), Vector2i(2, 0))
	assert_eq(_pips(_board_card(after, "bugler"), "charge"), Vector2i(2, 1))


func _renown_words(screen: FightScreen, card_id: String) -> String:
	var pill: Node = _board_card(screen, card_id).get_node_or_null("Renown")
	return (pill.get_child(0) as GlassText).words if pill != null else ""


func test_colonel_renown_pill_shows_double_or_triple_only_from_the_hand() -> void:
	for golden: bool in [false, true]:
		var replay: FightReplay = _colonel_replay(golden)
		var hand: FightScreen = _fight_screen_at_entry(replay, "territorial")
		var called: FightScreen = _fight_screen_at_entry(replay, "private")
		assert_not_null(hand, "the Territorial stepped in from the hand")
		assert_not_null(called, "the Bugler called a Private")
		if hand == null or called == null:
			return
		assert_eq(_renown_words(hand, "territorial"), "Renown 9" if golden else "Renown 6")
		assert_eq(_renown_words(called, "private"), "Renown 3")


## Step 6: on a card with a type line, the pips sit over its strip, not on it.
func test_pips_clear_the_type_line() -> void:
	var screen: RecruitScreen = _recruit(Marks.make_flow())
	for id: String in ["padre", "sentry"]:
		var card: GlassCard = _board_card(screen, id)
		assert_false(card.type_line.is_empty(), "%s prints its types" % id)
		var strip_top: float = card.card_height * GlassCard.TYPE_TOP
		for pip: Node in card.get_node("Pips").get_children():
			var bottom: float = (pip as Control).position.y + (pip as Control).size.y
			assert_true(bottom <= strip_top, "%s's %s clears the type strip" % [id, pip.name])
