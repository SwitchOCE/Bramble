extends GutTest

const TurnStart := preload("res://tests/screens/feel/recruit_turn_start_film.gd")

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _screen(flow: GameFlow) -> RecruitScreen:
	var screen: RecruitScreen = TurnStart.SCREEN.instantiate()
	screen.state = ViewAdapter.recruit_state(flow)
	add_child_autofree(screen)
	return screen


func test_turn_start_plays_the_three_effects_and_lands_on_the_rules_state() -> void:
	var flow: GameFlow = TurnStart.after_fight(_content)
	var screen: RecruitScreen = _screen(flow)
	var before: Dictionary = screen.state
	assert_eq(flow.human().gold_next_turn, 2, "Cutpurse earned 2 gold in combat")
	var state: Dictionary = TurnStart.next_turn_state(flow)
	screen.show_state(state)

	var effects: Array = state.get("turn_start_effects", [])
	var kinds: Array = effects.map(func(effect: Dictionary) -> String: return effect["kind"])
	var amounts: Array = effects.map(
		func(effect: Dictionary) -> int: return effect.get("amount", 0)
	)
	var gold: int = flow.human().gold
	var income_balance: int = before["gold"] + before["next_turn_income"]
	var renown: Control = screen._back.get_node("Renown_2")
	assert_eq(kinds, ["grudge", "campaigner", "relic"])
	assert_eq(amounts, [0, 2, 6])
	assert_eq(_model_numbers(state, 0) - _model_numbers(before, 0), Vector2i(4, 5))
	assert_eq(gold, income_balance + 8)
	assert_eq(str(state["message"]), "+2 gold from the last fight", "fight gold stays a notice")
	assert_true(screen._turn_start.active())
	assert_eq(_numbers(screen, 0), _model_numbers(before, 0))
	assert_eq(_numbers(screen, 2), _model_numbers(before, 2))
	assert_eq(_gold(screen), income_balance + 2, "only the Relic Seeker's gold is held back")
	assert_eq(_hand_count(screen), "Hand 2/7")
	assert_false(renown.visible)

	var tween: Tween = screen._turn_start._timeline
	tween.custom_step(0.25)
	assert_gt(_effect_alpha(screen, "GrudgeGain"), 0.0)
	tween.custom_step(0.38)
	assert_gt(_effect_alpha(screen, "RenownGain"), 0.0)
	assert_eq(_numbers(screen, 0), _model_numbers(state, 0))
	tween.custom_step(0.36)
	assert_gt(_effect_alpha(screen, "GoldGain"), 0.0)
	assert_true(renown.visible)
	assert_eq(_numbers(screen, 2), _model_numbers(state, 2))
	tween.custom_step(0.16)
	var coins: Array[Node] = screen._turn_start.get_children().filter(
		func(node: Node) -> bool: return node is GoldCoin
	)
	var relic: GoldCoin = coins[0]
	assert_gt(relic.modulate.a, 0.0)
	assert_eq(_gold(screen), income_balance + 2)
	tween.custom_step(2.0)
	assert_false(screen._turn_start.active())
	_assert_final(screen, state)


func test_press_finishes_immediately_and_same_turn_does_not_replay() -> void:
	var flow: GameFlow = TurnStart.after_fight(_content)
	var screen: RecruitScreen = _screen(flow)
	var state: Dictionary = TurnStart.next_turn_state(flow)
	screen.show_state(state)
	assert_true(screen._turn_start.active())

	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(5, 5)
	screen._gui_input(click)
	assert_false(screen._turn_start.active())
	_assert_final(screen, state)
	click.pressed = false
	screen._gui_input(click)
	screen.show_state(state)
	assert_false(screen._turn_start.active())


func test_key_finishes_immediately() -> void:
	var flow: GameFlow = TurnStart.after_fight(_content)
	var screen: RecruitScreen = _screen(flow)
	var state: Dictionary = TurnStart.next_turn_state(flow)
	screen.show_state(state)
	assert_true(screen._turn_start.active())

	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	screen._unhandled_key_input(key)
	assert_false(screen._turn_start.active())
	_assert_final(screen, state)


func test_turn_without_effects_has_no_playback() -> void:
	var flow: GameFlow = FlowFixture.live(_content, 7)
	flow.start_round()
	var screen: RecruitScreen = _screen(flow)
	flow.session.finish_round()
	flow.start_round()
	var state: Dictionary = ViewAdapter.recruit_state(flow)
	screen.show_state(state)

	assert_false(state.has("turn_start_effects"))
	assert_false(screen._turn_start.active())
	assert_eq(screen.state, state)
	assert_eq(_gold(screen), flow.human().gold)
	assert_eq(_hand_count(screen), "Hand 0/7")


func _assert_final(screen: RecruitScreen, state: Dictionary) -> void:
	assert_eq(screen.state, state)
	assert_eq(_numbers(screen, 0), _model_numbers(state, 0))
	assert_eq(_numbers(screen, 2), _model_numbers(state, 2))
	assert_eq(_gold(screen), GlassPieces.as_int(state["gold"]))
	var hand: Array = state["hand"]
	assert_eq(_hand_count(screen), "Hand %d/7" % hand.size())
	var renown: Control = screen._back.get_node("Renown_2")
	assert_true(renown.visible)
	var label: GlassText = renown.get_child(0)
	assert_eq(label.words, "Renown %d" % GlassPieces.as_int(state["slots"][2]["renown"]))
	for i: int in hand.size():
		var card: Control = screen.node_for("hand", i)
		var place: Vector3 = screen.hand_place(i, hand.size())
		assert_true(card.visible)
		assert_eq(card.position, Vector2(place.x, place.y))
		assert_eq(card.scale, Vector2.ONE)


static func _effect_alpha(screen: RecruitScreen, effect: String) -> float:
	var node: Control = screen._turn_start.get_node(effect)
	return node.modulate.a


static func _gold(screen: RecruitScreen) -> int:
	var label: GlassText = screen._back.get_node("Button_gold/GoldValue")
	return label.words.to_int()


static func _hand_count(screen: RecruitScreen) -> String:
	var label: GlassText = screen._front.get_node("HandCount")
	return label.words


static func _numbers(screen: RecruitScreen, slot: int) -> Vector2i:
	var card: GlassCard = screen.node_for("board", slot) as GlassCard
	return Vector2i(card.attack, card.health)


static func _model_numbers(state: Dictionary, slot: int) -> Vector2i:
	var card: Dictionary = state["board"][slot]
	return Vector2i(GlassPieces.as_int(card["attack"]), GlassPieces.as_int(card["health"]))
