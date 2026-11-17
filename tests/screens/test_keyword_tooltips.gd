extends GutTest
## Real screen input and geometry: Alt freeze, separate details, nested details and release.
const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
var _screen: RecruitScreen
var _table: Dictionary


func before_each() -> void:
	_table = GameContent.load_default().display_table()
	_screen = SCREEN.instantiate()
	_screen.state = GlassScreen.load_state("res://tests/screens/fixtures/shop_review.json")
	_screen.state["display"] = _table
	add_child_autofree(_screen)
	_screen.settle()


func _hover(index: int = 2) -> void:
	var card: Control = _screen.node_for("shop", index)
	_screen._tips.hover(card.position + card.size / 2.0)


func _alt(pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_ALT
	event.pressed = pressed
	_screen._unhandled_key_input(event)


func _mark(name_words: String, pane: Control) -> KeywordMark:
	for node: Node in pane.find_children("*", "KeywordMark", true, false):
		var mark: KeywordMark = node
		if (
			not mark.compact
			and (
				CardTerms.key_of(str(mark.term.get("name", mark.words)))
				== CardTerms.key_of(name_words)
			)
		):
			return mark
	return null


func _point(mark: KeywordMark) -> Vector2:
	return (
		_screen._stage.get_global_transform().affine_inverse()
		* (mark.get_global_transform() * (mark.size / 2.0))
	)


func test_alt_freezes_position_and_card_until_release() -> void:
	_hover()
	var tips: GlassTips = _screen._tips
	var position: Vector2 = tips.tip.position
	var hot: Control = tips.hot
	_alt(true)
	tips.hover(Vector2(1100, 400))
	tips.follow(Vector2(1200, 300))
	assert_true(tips.frozen)
	assert_eq(tips.tip.position, position)
	assert_eq(tips.hot, hot)
	_alt(false)
	assert_false(tips.frozen)
	assert_false(tips.tip.visible)
	assert_null(tips.hot)
	assert_eq(tips.details.size(), 0)


func test_keyword_opens_only_while_alt_is_held_and_uses_its_number() -> void:
	_hover()
	var tips: GlassTips = _screen._tips
	var mark: KeywordMark = _mark("Fury", tips.tip)
	assert_not_null(mark)
	if mark == null:
		return
	var pointer: Vector2 = _point(mark)
	tips.keyword_hover(pointer)
	assert_eq(tips.details.size(), 0)
	_alt(true)
	tips.hover(pointer)
	assert_eq(tips.details.size(), 1)
	var detail: GlassBox = tips.details[0]
	var text: String = ""
	for node: Node in detail.find_children("*", "GlassText", true, false):
		text += (node as GlassText).words
	assert_string_contains(text, "+1 Attack")
	assert_false(CardTerms.has_n(text))
	assert_not_null(_mark("Outnumbered", detail))
	_alt(false)
	assert_false(tips.tip.visible)
	assert_eq(tips.details.size(), 0)


func test_nested_keyword_detail_and_switching_parent() -> void:
	_hover()
	var tips: GlassTips = _screen._tips
	_alt(true)
	tips.hover(_point(_mark("Fury", tips.tip)))
	var nested: KeywordMark = _mark("Outnumbered", tips.details[0])
	tips.hover(_point(nested))
	assert_eq(tips.details.size(), 2)
	assert_not_null(_mark("Squire", tips.details[1]))
	tips.hover(_point(_mark("Guard", tips.tip.get_node("Words") as Control)))
	assert_eq(tips.details.size(), 1, "switching the parent discards its old descendants")
	_alt(false)
	assert_eq(tips.details.size(), 0)


func test_primary_pane_has_marks_and_hint_without_keyword_reminders() -> void:
	_hover()
	var pane: Control = _screen._tips.tip.get_node("Words")
	assert_not_null(_mark("Fury", pane))
	assert_eq((pane.get_node("AltHint") as GlassText).words, KeywordStyle.HINT)
	var text: String = ""
	for node: Node in pane.find_children("*", "GlassText", true, false):
		text += (node as GlassText).words
	assert_false(text.contains("Enemies must attack this first"))
	assert_false(text.contains("Whenever this attacks or is attacked"))


func test_release_does_not_reopen_same_card_next_frame() -> void:
	_hover()
	var tips: GlassTips = _screen._tips
	var card: Control = tips.hot
	var pointer: Vector2 = card.position + card.size / 2.0
	_alt(true)
	_alt(false)
	tips.follow(pointer)
	assert_false(tips.tip.visible)
	tips.hover(Vector2.ZERO)
	tips.hover(pointer)
	assert_true(tips.tip.visible)


func test_focus_loss_closes_and_a_state_refresh_keeps_the_frozen_snapshot() -> void:
	_hover()
	_alt(true)
	_screen._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(_screen._tips.frozen)
	assert_false(_screen._tips.tip.visible)
	_hover()
	_alt(true)
	var held: Control = _screen._tips.tip
	var at: Vector2 = held.position
	_screen.show_state(_screen.state.duplicate(true))
	assert_true(_screen._tips.frozen)
	assert_eq(_screen._tips.tip, held)
	assert_eq(held.position, at)
	_alt(false)
	assert_false(held.visible)


func test_all_shown_terms_have_unique_drawings_colours_and_reminders() -> void:
	var names: Dictionary = {}
	var icons: Dictionary = {}
	for raw: Variant in _table.values():
		var value: Dictionary = raw
		var entry: Dictionary = CardTerms.shown(value)
		if entry.is_empty():
			continue
		var name_words: String = CardTerms.general_name(str(entry["name"]))
		if names.has(name_words):
			continue
		names[name_words] = true
		var styles: Dictionary = KeywordStyle.data()["keywords"]
		assert_true(styles.has(name_words), name_words)
		assert_ne(str(entry["reminder"]), "", name_words)
		var style: Dictionary = KeywordStyle.entry(name_words)
		assert_false(icons.has(style["icon"]), name_words + " has a distinct silhouette")
		icons[style["icon"]] = true
		assert_true(KeywordStyle.icon(name_words) is Texture2D)
		assert_true(Color(str(KeywordStyle.family(name_words)["colour"])).a > 0)
	assert_eq(names.size(), 42)


func test_marks_stay_in_bottom_border_for_every_tier_and_context_size() -> void:
	for height: float in [186.0, 250.0, 350.0, 400.0]:
		for tier: int in range(1, 7):
			var card: GlassCard = _screen._unit_card(
				{
					"tier": tier,
					"text": "Guard. Fury 1. Thorns 4.",
					"keywords": ["taunt"],
					"mechanics": ["badger_fury", "thorn_thorns"]
				},
				height
			)
			add_child_autofree(card)
			var marks: Array[Node] = card.find_children("Pill*", "KeywordMark", false, false)
			assert_eq(marks.size(), 2 if height < 250.0 else 3)
			if height < 250.0:
				assert_eq((marks[1] as KeywordMark).words, "+2")
			for node: Node in marks:
				var mark: KeywordMark = node
				assert_gte(mark.position.y, height * 0.86)
				assert_lt(mark.position.x, card.size.x * 0.75)
				assert_gt(mark.position.x, card.size.x * 0.20)
				assert_gte(mark.size.y * 1366.0 / 1920.0, 15.0)


func test_rules_text_preserves_all_words_and_keyword_numbers() -> void:
	var words: String = "Order (2): Give a neighbour +2 Thorns. Your units' Fury is doubled."
	var rules: KeywordText = KeywordText.make(words, _table, 340.0)
	add_child_autofree(rules)
	var reconstructed: String = ""
	for child: Node in rules.get_children():
		reconstructed += (
			(child as KeywordMark).words if child is KeywordMark else (child as GlassText).words
		)
	assert_eq(reconstructed, words)
	assert_eq(rules.marks.size(), 3)
	assert_string_contains(str(rules.marks[0].term["reminder"]), "2 gold")
	assert_string_contains(str(rules.marks[1].term["reminder"]), "2 damage")


func test_granted_amount_replaces_the_printed_number_in_both_panes() -> void:
	var card: Dictionary = {
		"text": "Fury 1.", "mechanics": ["badger_fury"], "amounts": {"badger_fury": 3}
	}
	var terms: Array[Dictionary] = CardTerms.all_pills(card, _table)
	var text: KeywordText = KeywordText.make(str(card["text"]), _table, 340.0, terms)
	add_child_autofree(text)
	assert_eq(text.marks[0].words, "Fury 3")
	assert_string_contains(str(text.marks[0].term["reminder"]), "+3 Attack")


func test_general_references_and_plural_terms_have_real_details() -> void:
	var text: KeywordText = KeywordText.make(
		"Thorns, Root, Grow and Order. Medals. Squires.", _table, 340.0
	)
	add_child_autofree(text)
	assert_eq(text.marks.size(), 6)
	for mark: KeywordMark in text.marks:
		assert_ne(str(mark.term["reminder"]), "", mark.words)
		assert_false(CardTerms.has_n(str(mark.term["reminder"])), mark.words)
	assert_eq(str(KeywordStyle.entry(str(text.marks[4].term["name"]))["icon"]), "medal")


func test_hand_tooltip_uses_the_same_keyword_flow_and_lowers_on_release() -> void:
	var card: Control = _screen.node_for("hand", 3)
	var rest: Vector2 = card.position
	_screen._tips.show(_screen.targets_of("hand")[3], card.position)
	assert_eq((_screen._tips as RecruitTips).standing, card)
	_alt(true)
	var mark: KeywordMark = _mark("Decorated", _screen._tips.tip)
	assert_not_null(mark)
	if mark != null:
		_screen._tips.hover(_point(mark))
		assert_eq(_screen._tips.details.size(), 1)
	_alt(false)
	assert_eq(card.position, rest)
	assert_null((_screen._tips as RecruitTips).standing)
	assert_false(_screen._tips.tip.visible)


func test_nested_panes_stay_inside_the_stage() -> void:
	_hover()
	_alt(true)
	var tips: GlassTips = _screen._tips
	tips.hover(_point(_mark("Fury", tips.tip)))
	tips.hover(_point(_mark("Outnumbered", tips.details[0])))
	for pane: GlassBox in tips.details:
		var at: Vector2 = pane.position + tips.tip.position
		assert_gte(at.x, 0.0)
		assert_gte(at.y, 0.0)
		assert_lte(at.x + pane.size.x, 1920.0)
		assert_lte(at.y + pane.size.y, 1080.0)


func test_plural_detail_keeps_the_keywords_colour_and_drawing() -> void:
	_hover()
	_alt(true)
	var mark: KeywordMark = KeywordMark.make(
		{"name": "Medal", "words": "Medals", "reminder": "+2/+2 permanently."}
	)
	add_child_autofree(mark)
	_screen._tips._open_keyword(mark, _screen._tips.tip.get_node("Words") as Control, 0)
	var header: KeywordMark = _screen._tips.details[0].get_child(0)
	assert_eq(header.words, "Medals")
	assert_eq(str(header.term["name"]), "Medal")
	var style: Dictionary = KeywordStyle.entry(str(header.term["name"]))
	assert_eq(str(style["family"]), "growth")
	assert_eq(str(style["icon"]), "medal")
