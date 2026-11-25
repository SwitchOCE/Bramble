extends GutTest
## Real screen input and geometry: automatic keyword details and bottom-border hover.
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


func after_each() -> void:
	await wait_process_frames(2)


func _hover(index: int = 2) -> void:
	var card: Control = _screen.node_for("shop", index)
	_screen._pointer = card.position + card.size / 2.0
	_screen._tips.hover(_screen._pointer)


func _alt(pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_ALT
	event.pressed = pressed
	get_viewport().push_input(event, true)


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


func _detail(title: String, tips: GlassTips = null) -> GlassBox:
	if tips == null:
		tips = _screen._tips
	for pane: GlassBox in tips.details:
		var header: KeywordMark = pane.get_child(0)
		if CardTerms.key_of(str(header.term.get("name", header.words))) == CardTerms.key_of(title):
			return pane
	return null


func _border_mark(card: Control, title: String = "") -> KeywordMark:
	for child: Node in card.get_children():
		var mark: KeywordMark = child as KeywordMark
		if mark != null and not str(mark.term.get("reminder", "")).is_empty():
			if title == "" or CardTerms.key_of(str(mark.term["name"])) == CardTerms.key_of(title):
				return mark
	return null


func _stage_rect(node: Control, screen: GlassScreen = null) -> Rect2:
	if screen == null:
		screen = _screen
	var transform: Transform2D = (
		screen._stage.get_global_transform().affine_inverse() * node.get_global_transform()
	)
	var rect: Rect2 = Rect2(transform * Vector2.ZERO, Vector2.ZERO)
	for corner: Vector2 in [Vector2(node.size.x, 0), node.size, Vector2(0, node.size.y)]:
		rect = rect.expand(transform * corner)
	return rect


func _assert_clear_geometry(source: Control, context: String, screen: GlassScreen = null) -> void:
	if screen == null:
		screen = _screen
	var occupied: Array[Rect2] = [_stage_rect(source, screen)]
	for control_name: String in ["Hero", "HeroHealth", "EndTurn", "Opponent", "OpponentHealth"]:
		var protected: Control = screen._stage.find_child(control_name, true, false) as Control
		if protected != null and protected.is_visible_in_tree():
			occupied.append(_stage_rect(protected, screen))
	var panes: Array[Control] = []
	for primary_name: String in ["Card", "Words"]:
		var primary: Control = screen._tips.tip.get_node_or_null(primary_name)
		if primary != null:
			panes.append(primary)
	for detail: GlassBox in screen._tips.details:
		panes.append(detail)
	for pane: Control in panes:
		var rect: Rect2 = _stage_rect(pane, screen)
		assert_true(Rect2(0, 0, 1920, 1080).encloses(rect), context + ": " + pane.name)
		for other: Rect2 in occupied:
			assert_false(
				rect.intersects(other), context + ": " + pane.name + " must leave controls clear"
			)
		occupied.append(rect)


func _assert_left_column(context: String, screen: GlassScreen = null) -> void:
	if screen == null:
		screen = _screen
	if screen is RecruitScreen:
		var column: Rect2 = Rect2(12, 82, 220, 818)
		assert_eq(screen._tips.tip.position, column.position, context)
		var foot: float = column.position.y
		for pane: Node in screen._tips.tip.get_children():
			var rect: Rect2 = _stage_rect(pane as Control, screen)
			assert_true(column.grow(0.01).encloses(rect), context + ": " + str(pane.name))
			assert_gte(rect.position.y + 0.01, foot, context + ": panes stack vertically")
			foot = rect.end.y
		return
	var details: Array[GlassBox] = screen._tips.details
	var y: float = KeywordStyle.DETAIL_ORIGIN.y
	for detail: GlassBox in details:
		var rect: Rect2 = _stage_rect(detail, screen)
		assert_almost_eq(rect.position.x, KeywordStyle.DETAIL_ORIGIN.x, 0.01, context)
		assert_almost_eq(rect.position.y, y, 0.01, context)
		assert_almost_eq(rect.size.x, KeywordStyle.DETAIL_W * detail.scale.x, 0.01, context)
		assert_lte(rect.end.y, KeywordStyle.DETAIL_FOOT + 0.01, context)
		y = rect.end.y + KeywordStyle.GAP * detail.scale.y


func test_shop_knight_and_grenadier_details_stay_on_the_left_and_leave_controls_clear() -> void:
	var content: GameContent = GameContent.load_default()
	var session: GameSession = content.new_session(3)
	for card_id: String in ["hedge-knight", "grenadier-guard"]:
		var state: Dictionary = _screen.state.duplicate(true)
		state["shop_units"][2] = ViewAdapter.card_from_id(content, session, card_id)
		_screen.show_state(state)
		_screen.settle()
		_hover()
		assert_gt(_screen._tips.details.size(), 1, card_id)
		_assert_left_column(card_id)
		_assert_clear_geometry(_screen.node_for("shop", 2), card_id)
	for control_name: String in ["Hero", "EndTurn"]:
		assert_not_null(_screen._stage.find_child(control_name, true, false), control_name)


func test_card_hover_opens_every_keyword_and_one_nested_level_once() -> void:
	_hover()
	var tips: GlassTips = _screen._tips
	assert_true(tips.tip.visible)
	assert_eq(tips.details.size(), 3)
	assert_not_null(_detail("Guard"))
	var fury: GlassBox = _detail("Fury")
	assert_not_null(fury)
	assert_not_null(_detail("Outnumbered"))
	assert_null(_detail("Squire"), "Squire is two levels from the card; do not recurse again")
	var text: String = ""
	for node: Node in fury.find_children("*", "GlassText", true, false):
		text += (node as GlassText).words
	assert_string_contains(text, "+1 Attack")
	assert_false(CardTerms.has_n(text))
	assert_not_null(_mark("Outnumbered", fury))


func test_alt_previews_golden_and_does_not_freeze_hover() -> void:
	_hover()
	var tips: GlassTips = _screen._tips
	var pane: Control = tips.tip
	var before: Vector2 = pane.position
	_alt(true)
	assert_same(tips.tip, pane)
	assert_eq(tips.tip.position, before)
	assert_eq(tips.details.size(), 3)
	assert_true((tips.tip.get_node("Card") as GlassCard).golden)
	_alt(false)
	assert_true(tips.tip.visible)
	assert_eq(tips.details.size(), 3)
	assert_false((tips.tip.get_node("Card") as GlassCard).golden)
	_alt(true)
	_hover(3)
	assert_same(tips.hot, _screen.node_for("shop", 3), "Alt cannot hold the previous card")
	_alt(false)
	assert_true(tips.tip.visible)
	tips.hover(Vector2.ZERO)
	assert_false(tips.tip.visible)
	assert_eq(tips.details.size(), 0)


func test_primary_pane_has_marks_without_alt_hint_or_keyword_reminder_paragraphs() -> void:
	_hover()
	var pane: Control = _screen._tips.tip.get_node("Words")
	assert_not_null(_mark("Fury", pane))
	assert_null(pane.get_node_or_null("AltHint"))
	var text: String = ""
	for node: Node in pane.find_children("*", "GlassText", true, false):
		text += (node as GlassText).words
	assert_false(text.contains("Alt"))
	assert_false(text.contains("Enemies must attack this first"))
	assert_false(text.contains("Whenever this attacks or is attacked"))


func test_guard_post_opens_guard_once_without_further_pointer_input() -> void:
	var target: Dictionary = _screen.targets_of("shop")[2].duplicate()
	target["card"] = {"name": "Post test", "text": "Guard post. Guard.", "tier": 1}
	_screen._tips.show(target, Vector2(900, 300))
	assert_not_null(_detail("Guard post"))
	assert_not_null(_detail("Guard"))
	assert_eq(_screen._tips.details.size(), 2, "Guard is both printed and nested, but appears once")


func test_focus_loss_closes_and_state_refresh_rebuilds_current_hover() -> void:
	_hover()
	_screen._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(_screen._tips.tip.visible)
	var card: Control = _screen.node_for("shop", 2)
	_screen._pointer = card.position + card.size / 2.0
	_screen._tips.hover(_screen._pointer)
	var old_tip: Control = _screen._tips.tip
	_screen.show_state(_screen.state.duplicate(true))
	assert_ne(
		_screen._tips.tip, old_tip, "refresh displays the current card, not a frozen snapshot"
	)
	assert_true(_screen._tips.tip.visible)
	assert_not_null(_detail("Fury"))


func test_bottom_mark_hover_replaces_card_with_keyword_box_and_returns_to_card() -> void:
	var card: Control = _screen.node_for("shop", 2)
	var mark: KeywordMark = _border_mark(card, "Fury")
	assert_not_null(mark)
	if mark == null:
		return
	_screen._tips.hover(_point(mark))
	var tips: GlassTips = _screen._tips
	assert_true(tips.tip.visible)
	assert_null(tips.tip.get_node_or_null("Words"))
	assert_null(tips.tip.get_node_or_null("Card"))
	var pane: GlassBox = _detail("Fury")
	assert_not_null(pane)
	var header: KeywordMark = pane.get_child(0)
	assert_eq(header.words, "Fury 1")
	assert_eq(str(KeywordStyle.entry(str(header.term["name"]))["icon"]), "flame")
	assert_not_null(_detail("Outnumbered"))
	assert_eq(tips.details.size(), 2)
	tips.follow(card.position + card.size / 2.0)
	assert_not_null(tips.tip.get_node_or_null("Words"))
	assert_not_null(tips.tip.get_node_or_null("Card"))
	assert_not_null(_detail("Guard"))
	tips.follow(_point(mark))
	assert_null(tips.tip.get_node_or_null("Words"), "follow also detects entering the small icon")


func test_bottom_mark_hover_has_padding_without_moving_the_drawing() -> void:
	var card: Control = _screen.node_for("shop", 2)
	var mark: KeywordMark = _border_mark(card, "Guard")
	assert_not_null(mark)
	if mark == null:
		return
	var at: Vector2 = mark.position
	var just_outside: Vector2 = Vector2(-2.0, mark.size.y / 2.0)
	assert_false(Rect2(Vector2.ZERO, mark.size).has_point(just_outside))
	assert_true(mark.hit_rect().has_point(just_outside))
	var pointer: Vector2 = (
		_screen._stage.get_global_transform().affine_inverse()
		* (mark.get_global_transform() * just_outside)
	)
	_screen._tips.hover(pointer)
	assert_not_null(_detail("Guard"))
	assert_eq(mark.position, at)
	assert_null(_screen._tips.tip.get_node_or_null("Card"))


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
	assert_false(names.has("Gains left this fight"), "Pile on 5 tracks the Pikeman’s uses")
	# 42 before S5 and S6. S5: -Medal, -Decorated, -Stiff Upper Lip, -Joins the fight,
	# -Privates left, +Charge, +Supply. S6: -Gains left this fight, +Hand-me-down.
	# S9 removed Slot buff.
	assert_eq(names.size(), 38)


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
	var words: String = "2: Give a neighbour +2 Thorns. Your units' Fury is doubled."
	var rules: KeywordText = KeywordText.make(words, _table, 340.0)
	add_child_autofree(rules)
	var reconstructed: String = ""
	for child: Node in rules.get_children():
		reconstructed += (
			(child as KeywordMark).words if child is KeywordMark else (child as GlassText).words
		)
	assert_eq(reconstructed, KeywordText.effect_lines(words))
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
		"Thorns, Root, Grow and Bury. Hoppers. Squires.", _table, 340.0
	)
	add_child_autofree(text)
	assert_eq(text.marks.size(), 6)
	for mark: KeywordMark in text.marks:
		assert_ne(str(mark.term["reminder"]), "", mark.words)
		assert_false(CardTerms.has_n(str(mark.term["reminder"])), mark.words)
	assert_eq(str(KeywordStyle.entry(str(text.marks[4].term["name"]))["icon"]), "hopper")


func test_hand_hover_opens_details_and_lowers_when_pointer_leaves() -> void:
	var card: Control = _screen.node_for("hand", 3)
	var rest: Vector2 = card.position
	_screen._tips.show(_screen.targets_of("hand")[3], card.position)
	_screen._pointer = card.position + card.size / 2.0
	assert_eq((_screen._tips as RecruitTips).standing, card)
	assert_not_null(_detail("Renown"))
	_alt(true)
	_alt(false)
	assert_eq((_screen._tips as RecruitTips).standing, card)
	_screen._tips.hover(Vector2.ZERO)
	assert_eq(card.position, rest)
	assert_null((_screen._tips as RecruitTips).standing)
	assert_false(_screen._tips.tip.visible)


func test_hand_bottom_mark_opens_its_keyword_without_the_card_pane() -> void:
	var card: Control = _screen.node_for("hand", 2)
	var mark: KeywordMark = _border_mark(card)
	assert_not_null(mark)
	if mark == null:
		return
	_screen._tips.hover(card.position + Vector2(card.size.x / 2.0, 45.0))
	assert_eq((_screen._tips as RecruitTips).standing, card)
	_screen._tips.hover(_point(mark))
	assert_true(_screen._tips.tip.visible)
	assert_null(_screen._tips.tip.get_node_or_null("Words"))
	assert_null(_screen._tips.tip.get_node_or_null("Card"))
	assert_not_null(_detail(str(mark.term["name"])))


func test_keyword_column_stays_fixed_and_protects_controls_at_card_area_edges() -> void:
	var target: Dictionary = _screen.targets_of("shop")[2]
	var card: Control = target["node"]
	for at: Vector2 in [Vector2(370, 20), Vector2(1700, 20), Vector2(370, 800), Vector2(1700, 800)]:
		_screen._tips.hide()
		card.position = at
		_screen._tips.show(target, at + card.size / 2.0)
		_assert_left_column("card at " + str(at))
		_assert_clear_geometry(card, "card at " + str(at))
		_screen._tips.hover(_point(_border_mark(card, "Fury")))
		assert_null(_screen._tips.tip.get_node_or_null("Words"))
		_assert_left_column("icon at " + str(at))
		_assert_clear_geometry(card, "icon at " + str(at))


func test_plural_detail_keeps_the_keywords_colour_and_drawing() -> void:
	var target: Dictionary = _screen.targets_of("shop")[2].duplicate()
	target["card"] = {"name": "Plural test", "text": "Hoppers.", "tier": 1}
	_screen._tips.show(target, Vector2(900, 300))
	var pane: GlassBox = _detail("Hopper")
	assert_not_null(pane)
	if pane == null:
		return
	var header: KeywordMark = pane.get_child(0)
	assert_eq(header.words, "Hoppers")
	assert_eq(str(header.term["name"]), "Hopper")
	var style: Dictionary = KeywordStyle.entry(str(header.term["name"]))
	assert_eq(str(style["family"]), "kin")
	assert_eq(str(style["icon"]), "hopper")


func test_board_and_discover_marks_open_keyword_only_panes() -> void:
	for kind: String in ["board", "discover"]:
		if kind == "discover":
			var state: Dictionary = _screen.state.duplicate(true)
			state["discover"] = {"options": [state["shop_units"][2]], "prompt": "Choose"}
			_screen.show_state(state)
			_screen.settle()
		var target: Dictionary = _screen.targets_of(kind)[0]
		var node: Control = target["node"]
		var mark: KeywordMark = _border_mark(node)
		assert_not_null(mark, kind)
		if mark == null:
			continue
		_screen._tips.hover(_point(mark))
		assert_true(_screen._tips.tip.visible, kind)
		assert_null(_screen._tips.tip.get_node_or_null("Words"), kind)
		assert_null(_screen._tips.tip.get_node_or_null("Card"), kind)
		assert_not_null(_detail(str(mark.term["name"])), kind)


func test_fight_card_hover_and_mark_use_the_same_automatic_details() -> void:
	var fight: FightScreen = (
		(load("res://src/screens/fight/fight_screen.tscn") as PackedScene).instantiate()
	)
	var state: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/fight_start.json")
	state["display"] = _table
	var knight: Dictionary = _screen.state["shop_units"][2]
	state["boards"][0][0] = knight.duplicate(true)
	fight.state = state
	add_child_autofree(fight)
	fight.settle()
	var card: Control = fight.node_for("board", 0)
	fight._tips.hover(card.position + card.size / 2.0)
	assert_eq(fight._tips.details.size(), 3)
	_assert_clear_geometry(card, "fight card", fight)
	_assert_left_column("fight card", fight)
	var mark: KeywordMark = _border_mark(card, "Guard")
	assert_not_null(mark)
	if mark == null:
		return
	var pointer: Vector2 = (
		fight._stage.get_global_transform().affine_inverse()
		* (mark.get_global_transform() * (mark.size / 2.0))
	)
	fight._tips.hover(pointer)
	assert_true(fight._tips.tip.visible)
	assert_null(fight._tips.tip.get_node_or_null("Card"))
	assert_null(fight._tips.tip.get_node_or_null("Words"))
	assert_eq(fight._tips.details.size(), 1)
	assert_not_null(_detail("Guard", fight._tips))
	_assert_clear_geometry(card, "fight icon", fight)
	assert_not_null(fight._stage.find_child("Opponent", true, false))


func test_catalog_keyword_details_are_unique_bounded_and_clear_of_the_card_panes() -> void:
	var catalog: BrowserCatalog = BrowserCatalog.new(GameContent.load_default())
	var target: Dictionary = _screen.targets_of("shop")[2].duplicate()
	var card_node: Control = target["node"]
	var max_details: int = 0
	var most: String = ""
	for card: Dictionary in catalog.cards:
		_screen._tips.hide()
		target["card"] = card
		target["kind"] = "spell" if GlassScreen._is_spell(card) else "shop"
		_screen._tips.show(target, card_node.position + card_node.size / 2.0)
		var tips: GlassTips = _screen._tips
		if tips.details.size() > max_details:
			max_details = tips.details.size()
			most = str(card["id"])
		var occupied: Array[Rect2] = [Rect2(card_node.position, card_node.size)]
		for child_name: String in ["Card", "Words"]:
			var primary: Control = tips.tip.get_node(child_name)
			occupied.append(_stage_rect(primary))
		_assert_clear_geometry(card_node, str(card["id"]))
		_assert_left_column(str(card["id"]))
		var seen: Dictionary = {}
		for pane: GlassBox in tips.details:
			# a pane's first mark names it (a cost coin's pane starts with the coin's line)
			var header: KeywordMark = pane.find_children("*", "KeywordMark", true, false)[0]
			var key: String = CardTerms.key_of(str(header.term.get("name", header.words)))
			assert_false(seen.has(key), str(card["id"]) + ": " + key)
			seen[key] = true
			assert_true(pane.visible, str(card["id"]) + ": " + key)
			var rect: Rect2 = _stage_rect(pane)
			assert_true(Rect2(0, 0, 1920, 1080).encloses(rect), str(card["id"]) + ": " + key)
			for other: Rect2 in occupied:
				assert_false(rect.intersects(other), str(card["id"]) + ": " + key)
			occupied.append(rect)
	assert_gte(max_details, 3, "catalog stress includes cards with several panes")
	print("keyword catalog layout: most details = %d (%s)" % [max_details, most])
