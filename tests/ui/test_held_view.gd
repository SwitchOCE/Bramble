extends GutTest
## How Bellies, birds away and Nests read on screen, and how a fight plays them back.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Words := preload("res://tests/ui/playthrough_words.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")


func _ooze(size: int, inside: Array = []) -> Dictionary:
	return {"name": "Pudding", "kind": "unit", "belly": size, "held": inside, "text": "Belly."}


func test_an_ooze_with_room_takes_a_unit() -> void:
	assert_true(RecruitHeld.can_swallow(_ooze(1), {"name": "A", "kind": "unit"}))


func test_a_full_belly_doesnt() -> void:
	assert_false(RecruitHeld.can_swallow(_ooze(1, [{"name": "B"}]), {"name": "A", "kind": "unit"}))


func test_no_belly_no_swallow() -> void:
	assert_false(RecruitHeld.can_swallow({"name": "Plain"}, {"name": "A", "kind": "unit"}))


func test_a_spell_cant_go_in() -> void:
	assert_false(RecruitHeld.can_swallow(_ooze(1), {"name": "A", "kind": "spell"}))


func test_a_unit_holding_others_cant_go_in() -> void:
	var holder: Dictionary = _ooze(1, [{"name": "B"}])
	assert_false(RecruitHeld.can_swallow(_ooze(2), holder))


func test_a_unit_cant_swallow_itself() -> void:
	var ooze: Dictionary = _ooze(2)
	assert_false(RecruitHeld.can_swallow(ooze, ooze))


func test_bellies_for_lists_only_the_slots_with_room() -> void:
	var board: Array = [_ooze(1), null, _ooze(1, [{"name": "B"}]), {"name": "Plain"}, _ooze(2)]
	var slots: Array[int] = RecruitHeld.bellies_for(board, {"name": "A", "kind": "unit"})
	assert_eq(slots, [0, 4] as Array[int])


func test_the_tile_slip_shows_inside_against_size() -> void:
	assert_eq(RecruitHeld.belly_slip(_ooze(3, [{"name": "B"}])), "In 1/3")
	assert_eq(RecruitHeld.belly_slip({"name": "Plain"}), "")
	assert_eq(RecruitView.tile_slip(_ooze(3, [{"name": "B"}])), "In 1/3", "and the tile reads it")


func test_the_full_text_lists_who_is_inside_next_out_first() -> void:
	var inside: Array = [
		{"name": "First", "attack": 1, "health": 2}, {"name": "Last", "attack": 3, "health": 4}
	]
	var text: String = RecruitHeld.with_inside(_ooze(2, inside))["text"]
	assert_string_contains(text, "Last 3/4, First 1/2")


func test_the_sell_button_says_what_selling_does() -> void:
	var bird: Dictionary = {"fly_south": 2, "played_round": 3}
	assert_eq(RecruitHeld.sell_word(bird, 5), "Fly south")
	assert_eq(RecruitHeld.sell_word(bird, 3), "Sell for good", "played this turn")
	assert_eq(RecruitHeld.sell_word({"name": "Plain"}, 5), "Sell")


func test_the_note_warns_about_a_full_ooze() -> void:
	assert_string_contains(RecruitHeld.sell_note(_ooze(1, [{"name": "B"}]), 2), "lets out")
	assert_eq(RecruitHeld.sell_note(_ooze(1), 2), "")


func test_a_nest_marks_its_slot_with_its_countdown() -> void:
	var state: Dictionary = {"away": [{"nest": 2, "turns_left": 2, "name": "Mrs Jay"}]}
	var marks: Array = RecruitView.slot_marks(state)
	assert_true(marks[2]["nest"])
	assert_eq(marks[2]["nest_left"], 2)
	assert_false(marks[1].has("nest"), "only that slot")
	assert_string_contains(RecruitView.slot_note(marks[2], 2), "Mrs Jay comes home in 2 turns")


func test_a_bird_whose_nest_ended_marks_nothing() -> void:
	var marks: Array = RecruitView.slot_marks(
		{"away": [{"nest": -1, "turns_left": 2, "name": "A"}]}
	)
	for mark: Dictionary in marks:
		assert_false(mark.has("nest"))


func test_their_nests_never_say_who_or_when() -> void:
	var marks: Array = RecruitHeld.with_their_nests(RecruitView.slot_marks({}), [3])
	assert_true(marks[3]["nest"])
	assert_eq(marks[3]["nest_left"], -1)
	var note: String = RecruitHeld.nest_note(marks[3])
	assert_string_contains(note, "a bird of theirs")


func test_the_sky_card_lists_birds_away_and_on_the_doorstep() -> void:
	var state: Dictionary = {
		"away": [{"name": "Mrs Jay", "turns_left": 1, "nest": 4}], "doorstep": [{"name": "Tern"}]
	}
	var text: String = RecruitHeld.sky_card(state)["text"]
	assert_string_contains(text, "Mrs Jay · home in 1 turn · B1")
	assert_string_contains(text, "Tern: on the doorstep")
	assert_true(RecruitHeld.sky_card({}).is_empty(), "nobody out: no card")


func test_every_keyword_has_a_reminder_and_needs_no_word_chip() -> void:
	for word: String in ["Belly", "Fly South", "Nest", "Swoop"]:
		assert_false(KeywordRules.text(word).is_empty(), word)
	var ooze: Dictionary = {"text": "Belly 1. Something.", "keywords": ["Belly"]}
	assert_eq(CardView.chip_text(ooze), "")
	assert_true(KeywordRules.named_on(ooze).has("Belly"))
	var bird: Dictionary = {"text": "Fly South. Something.", "keywords": ["Fly South"]}
	assert_eq(CardView.chip_text(bird), "")
	assert_true(KeywordRules.named_on(bird).has("Fly South"))


func test_copies_inside_a_belly_count_for_triples_and_plain_ones_dont() -> void:
	var inside: Array = [{"def_id": "vole"}, {"def_id": "vole", "plain_copy": true}]
	var state: Dictionary = {
		"hand": [{"def_id": "vole"}],
		"board": [{"def_id": "ooze", "belly": 2, "held": inside}, null],
	}
	assert_eq(RecruitView.copies(state)["vole"], 2)


func _model_with(units: Array) -> CombatModel:
	var model := CombatModel.new()
	model.apply({"type": "combat_start", "boards": [units, []], "player_ids": [0, 1]})
	return model


func test_swallowed_takes_a_unit_off_the_board_and_fills_the_holder() -> void:
	var model: CombatModel = _model_with(
		[{"uid": 1, "health": 3, "attack": 1}, {"uid": 2, "health": 3, "attack": 1}]
	)
	model.apply({"type": "swallowed", "uid": 2, "side": 0, "slot": 1, "by": 1})
	assert_eq(model.uid_at(0, 1), -1, "the slot's empty")
	assert_eq(model.unit(1)["held"], 1)


func test_the_same_unit_coming_back_stands_there_again() -> void:
	var model: CombatModel = _model_with(
		[{"uid": 1, "health": 3, "attack": 1}, {"uid": 2, "health": 3, "attack": 1}]
	)
	model.apply({"type": "swallowed", "uid": 2, "side": 0, "slot": 1, "by": 1})
	var view: Dictionary = {"uid": 2, "health": 3, "attack": 1, "name": "Back"}
	model.apply(
		{"type": "summon", "unit": view, "side": 0, "slot": 2, "source": 1, "came_out": true}
	)
	assert_eq(model.uid_at(0, 2), 2)
	assert_true(model.unit(2)["alive"], "alive again")
	assert_eq(model.unit(1)["held"], 0, "the holder's empty")


func test_the_log_names_what_happened() -> void:
	var model: CombatModel = _model_with([{"uid": 1, "health": 3, "attack": 1, "name": "Pudding"}])
	var log_text := CombatLog.new()
	var out: Dictionary = {"name": "Vole"}
	var event: Dictionary = {
		"type": "summon", "unit": out, "slot": 2, "source": 1, "came_out": true
	}
	assert_string_contains(log_text.describe(event, model, false), "comes out into F3")
	event = {"type": "summon", "unit": out, "slot": 2, "source": 1, "landed": true}
	assert_string_contains(log_text.describe(event, model, false), "lands on its Nest")
	var arrival: String = CombatLog.arrival_word({"split": true})
	assert_eq(arrival, "Split!")
	assert_eq(CombatLog.held_slip({"held": 2}), "In 2")
	assert_eq(CombatLog.held_slip({}), "", "nothing inside: no slip")


func test_a_plain_bird_copy_shows_a_final_sale() -> void:
	var copy: Dictionary = {"fly_south": 2, "plain_copy": true, "played_round": 1}
	assert_eq(RecruitHeld.sell_word(copy, 5), "Sell for good")
	assert_eq(RecruitHeld.sell_note(copy, 5), "A plain copy: a sale is final.")


func test_ui_run_accepts_tribes_in_the_lobby_and_rejects_absent_ones() -> void:
	var four: RegEx = Words.pattern(["Hedgerow folk", "Fairies", "Oozes", "Birds"])
	assert_null(four.search("Oozes and Birds. An Ooze holds a Bird."))
	var two: RegEx = Words.pattern(["Hedgerow folk", "Fairies"])
	assert_not_null(two.search("An Ooze"))
	assert_not_null(two.search("A Bird"))
	assert_not_null(four.search("Bot 3"))
	assert_not_null(four.search("sixpenny_pie"))
	assert_not_null(four.search("You has"))
	assert_null(Words.pattern([]).search("Oozes and Birds"), "empty lobby list means all")
	assert_not_null(Words.pattern([]).search("Bot 3"), "whole-game guide still rejects bot numbers")
	assert_not_null(Words.pattern([]).search("moss_ooze"), "whole-game guide still rejects raw ids")
