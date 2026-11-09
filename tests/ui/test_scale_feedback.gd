extends GutTest
## Percentage Hex and spent Shield stay readable through combat playback and recruit slips.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Data := preload("res://src/ui/view_data.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const SlotMarks := preload("res://src/ui/widgets/slot_marks.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func _hex(flat: int, percent: int, percent_amount: int = 0) -> Dictionary:
	return {
		"type": "slot_hex",
		"source": 1,
		"side": 1,
		"slot": 0,
		"amount": flat,
		"total": flat,
		"percent": percent,
		"percent_amount": percent_amount
	}


func _badge(board: BoardView) -> Label:
	var marks: SlotMarks = board.get("_marks")
	return marks._hex_labels[0]


func _start() -> Dictionary:
	var unit: Dictionary = {
		"uid": 1,
		"def_id": "fox_cub",
		"name": "Shield bearer",
		"tier": 1,
		"attack": 10,
		"health": 10,
		"max_health": 10,
		"text": "",
		"keywords": [],
		"statuses": [{"status": "shield", "data": {}}]
	}
	return {
		"type": "combat_start",
		"boards": [[unit, null, null, null, null, null, null], []],
		"player_ids": [0, 1],
		"first_side": 0
	}


func test_log_uses_the_applied_percentage_and_keeps_flat_attack_wording() -> void:
	var model: CombatModel = CombatModel.new()
	model.apply(_start())
	var words: CombatLog = CombatLog.new()
	var percent_line: String = words.describe(_hex(0, 50, 25), model, false)
	assert_string_contains(percent_line, "-25% Attack")
	assert_false(percent_line.contains("0 Attack"), "proportional Hex is never narrated as zero")
	assert_false(percent_line.contains("-50%"), "the line describes this application")
	assert_string_contains(words.describe(_hex(3, 50), model, false), "-3 Attack")


func test_model_and_slot_badge_preserve_both_hex_scales() -> void:
	var model: CombatModel = CombatModel.new()
	model.apply(_hex(0, 25, 25))
	assert_eq(Data.i(model.slot_hexes["1:0"], "percent"), 25)
	model.apply(_hex(3, 25))
	assert_eq(Data.i(model.slot_hexes["1:0"], "percent"), 25, "flat application keeps percent")
	assert_eq(Data.i(model.slot_hexes["1:0"], "total"), 3)
	var board: BoardView = BoardView.new()
	add_child_autofree(board)
	board.set_hex(0, 0, 25)
	assert_eq(_badge(board).text, "Hex -25%")
	board.set_hex(0, 3, 25)
	assert_eq(_badge(board).text, "Hex -3 / -25%")
	board.set_hex(0, 0, 100)
	assert_eq(_badge(board).text, "Hex -100%")
	board.set_hex(0, 3)
	assert_eq(_badge(board).text, "Hex -3", "legacy flat callers keep their display")


func test_recruit_slip_shows_percentage_storage_and_mixed_hex() -> void:
	var unit: Dictionary = {"hex_percent_amount": 25, "hex_percent_stored": 25}
	assert_eq(RecruitView.turns_word(unit), "Hex 25%")
	assert_eq(RecruitView.tile_slip(unit), "Hex 25%")
	unit.merge({"hex_percent_amount": 100, "hex_percent_stored": 140}, true)
	assert_eq(RecruitView.turns_word(unit), "Hex 100% (140% stored)")
	unit.merge({"hex_amount": 3, "hex_stored": 3}, true)
	assert_eq(RecruitView.tile_slip(unit), "Hex 3 + 100% (3 + 140% stored)")
	assert_eq(RecruitView.tile_slip({"hex_amount": 3, "hex_stored": 5}), "Hex 3 (5 stored)")
	assert_eq(RecruitView.turns_word({"turns_goal": 3, "turns_in_slot": 1}), "1/3")


func test_playback_rebuild_keeps_percent_and_spent_shield_removes_its_tag() -> void:
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	screen.setup({"events": []}, PackedStringArray(["You", "Enemy"]), 0, "Scale feedback")
	screen.call("_play_event", _start(), false)
	var card: CardView = screen._cards[1]
	var tag: Panel = card.get("_status_tag")
	var label: Label = card.get("_status_label")
	assert_true(tag.visible)
	assert_eq(label.text, "Shield")
	assert_true(UiTheme.STATUS_INFO.has("shield"), "Shield has an explicit theme status")
	assert_eq(UiTheme.status_keyword("shield"), "Shield")
	assert_false(KeywordRules.text("Shield").is_empty(), "the status has a reminder")
	assert_string_contains(CardDetail.state_bbcode(screen.model.unit(1)), "[url=kw:Shield]")
	var detail: CardDetail = CardDetail.new()
	add_child_autofree(detail)
	detail.show_unit(screen.model.unit(1))
	var notes: RichTextLabel = detail.get("_notes")
	notes.meta_hover_started.emit("kw:Shield")
	assert_true(detail.reminder.visible, "Shield's reminder opens from its link")
	assert_eq(detail.reminder.keyword, "Shield")
	var reminder_text: RichTextLabel = detail.reminder.get("_text")
	assert_string_contains(reminder_text.get_parsed_text(), KeywordRules.text("Shield"))
	screen.call("_play_event", _hex(0, 25, 25), false)
	assert_eq(_badge(screen.board_for_side(1)).text, "Hex -25%")
	screen.call("_sync_all")
	card = screen._cards[1]
	tag = card.get("_status_tag")
	assert_true(tag.visible, "rebuilt card keeps its Shield")
	assert_eq(_badge(screen.board_for_side(1)).text, "Hex -25%", "rebuild preserves scale")
	screen.call(
		"_play_event", {"type": "status", "target": 1, "status": "shield", "on": false}, false
	)
	assert_false(tag.visible, "spent Shield loses its hanging tag in playback")
	assert_true(Data.a(screen.model.unit(1), "statuses").is_empty())
	assert_false(CardDetail.state_bbcode(screen.model.unit(1)).contains("Shield"))
