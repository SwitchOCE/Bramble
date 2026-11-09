extends GutTest
## Queued gains stay distinct from combat stats and explain themselves in the existing reader.
@warning_ignore_start("unsafe_call_argument")

const CombatLanesView := preload("res://src/ui/screens/combat_lanes_view.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const FightLog := preload("res://tools/play/play_fight_log.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const States := preload("res://tests/ui/big_number_states.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")


func _unit() -> Dictionary:
	return {
		"uid": 1, "attack": 4, "health": 0, "max_health": 5, "text": "Soak 2.", "keywords": ["Soak"]
	}


func test_pending_event_uses_totals_without_changing_current_or_dying_stats() -> void:
	var model: CombatModel = CombatModel.new()
	model.apply({"type": "combat_start", "boards": [[_unit()], []]})
	model.apply({"type": "death", "uid": 1})
	for total: int in [2, 5]:
		model.apply(
			{"type": "gain_pending", "target": 1, "attack": 0, "health": total, "health_delta": 2}
		)
	assert_eq(model.unit(1)["attack"], 4)
	assert_eq(model.unit(1)["health"], 0)
	assert_eq(model.unit(1)["max_health"], 5)
	assert_eq(model.unit(1)["pending_attack"], 0)
	assert_eq(model.unit(1)["pending_health"], 5, "events carry totals, not increments")
	assert_false(model.unit(1)["alive"])


func test_pending_badge_is_numeric_readable_and_clear_of_existing_card_labels() -> void:
	CardView.window_override = Vector2(1688, 780)
	var card: CardView = CardView.new()
	add_child_autofree(card)
	card.show_unit(_unit(), CardView.Mode.BOARD)
	card.set_card_width(210)
	var gain_badge: Panel = card.get("_pending_tag")
	assert_false(gain_badge.visible)
	for gains: Vector2i in [Vector2i(0, 2), Vector2i(7, 12), Vector2i(123456, 1234567)]:
		card.set_pending_gains(gains.x, gains.y)
		var label: Label = card.get("_pending_label")
		assert_true(gain_badge.visible, "zero-health units retain their queued gain while visible")
		assert_gte(label.get_theme_font_size("font_size"), 31)
		assert_true(label.text.begins_with("+"))
		assert_true(label.text.contains("/+"))
		var text_width: float = (
			label
			. get_theme_font("font")
			. get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 31)
			. x
		)
		assert_lte(text_width, label.size.x)
		assert_gte(gain_badge.position.x, 0.0)
		assert_lte(gain_badge.position.x + gain_badge.size.x, card.size.x)
		for key: String in ["_chip", "_attack_badge", "_health_badge", "_tier_badge"]:
			var existing: Control = card.get(key)
			assert_false(gain_badge.get_rect().intersects(existing.get_rect()), key)
	card.set_pending_gains(0, 0)
	assert_false(gain_badge.visible)
	CardView.window_override = Vector2.ZERO


func test_reader_explains_exact_queued_amount_and_arrival() -> void:
	var view: Dictionary = _unit()
	assert_false(CardDetail.state_bbcode(view).contains("Pending gain"))
	view["pending_attack"] = 123456
	view["pending_health"] = 1234567
	var words: String = CardDetail.state_bbcode(view)
	assert_string_contains(words, "+123,456/+1,234,567")
	assert_string_contains(words, "next Start of Turn")


func test_phone_combat_pending_event_updates_badge_and_open_one_tap_reader() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var screen: CombatScreen = CombatScreen.new()
	viewport.add_child(screen)
	screen.call("setup", States.fight(4), PackedStringArray(["You", "Opponent"]), 0, "Round 14")
	screen.set("playing", false)
	var events: Array = screen.get("events")
	screen.call("_play_event", events[0], false)
	await get_tree().process_frame
	screen.call("_on_card_tapped", "combat", 2)
	screen.call(
		"_play_event",
		{"type": "gain_pending", "target": 2, "attack": 123456, "health": 1234567},
		false
	)
	await get_tree().process_frame
	var cards: Dictionary = screen.get("_cards")
	var card: CardView = cards[2]
	var gain_badge: Panel = card.get("_pending_tag")
	assert_true(gain_badge.visible)
	assert_lte(gain_badge.position.x + gain_badge.size.x, card.size.x)
	for key: String in ["_chip", "_attack_badge", "_health_badge", "_tier_badge"]:
		var existing: Control = card.get(key)
		assert_false(gain_badge.get_rect().intersects(existing.get_rect()), key)
	var notes: RichTextLabel = screen.get("_note_text")
	assert_string_contains(notes.get_parsed_text(), "+123,456/+1,234,567")
	assert_string_contains(notes.get_parsed_text(), "next Start of Turn")
	CardView.window_override = Vector2.ZERO


func test_pending_event_updates_a_dying_card_until_it_leaves_the_screen() -> void:
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	screen.setup(States.fight(4), PackedStringArray(["You", "Opponent"]), 0, "Round 14")
	screen.playing = false
	screen._play_event(screen.events[0], false)
	var cards: Dictionary = screen.get("_cards")
	var dying: CardView = cards[2]
	screen._play_event({"type": "death", "uid": 2}, true)
	screen._play_event({"type": "gain_pending", "target": 2, "attack": 0, "health": 5}, false)
	var gain_badge: Panel = dying.get("_pending_tag")
	var label: Label = dying.get("_pending_label")
	assert_true(gain_badge.visible)
	assert_eq(label.text, "+0/+5")


func test_dying_lookup_skips_freed_cards_before_a_live_card() -> void:
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	var expired: CardView = CardView.new()
	expired.show_unit({"uid": 10}, CardView.Mode.BOARD)
	var live: CardView = CardView.new()
	live.show_unit({"uid": 11}, CardView.Mode.BOARD)
	screen.add_child(live)
	var fading: Array[CardView] = [expired, live]
	screen.set("_dying", fading)
	expired.free()
	assert_same(CombatLanesView.card_for_uid(screen, 11), live)
	assert_null(CombatLanesView.card_for_uid(screen, 10))
	CombatLanesView.clear_dying_cards(screen)
	assert_true(fading.is_empty())
	assert_true(live.is_queued_for_deletion())


func test_both_logs_name_pending_increment_and_arrival_without_live_stats() -> void:
	var model: CombatModel = CombatModel.new()
	var view: Dictionary = _unit()
	view["name"] = "Little Nip"
	model.apply({"type": "combat_start", "boards": [[view], []]})
	var event: Dictionary = {
		"type": "gain_pending",
		"target": 1,
		"attack": 9,
		"health": 12,
		"attack_delta": 2,
		"health_delta": 3,
		"cause": "take",
		"source": 1
	}
	var log_text: CombatLog = CombatLog.new()
	for line: String in [
		log_text.describe(event, model, false), FightLog.event_line(event, {1: "Little Nip"}, 0)
	]:
		assert_string_contains(line, "Little Nip")
		assert_string_contains(line, "+2/+3")
		assert_string_contains(line, "next Start of Turn")
		assert_false(line.contains("now "))
		assert_false(line.contains("attack_delta"))
		assert_false(line.contains("+9/+12"), "logs report this increment, not queued total")
