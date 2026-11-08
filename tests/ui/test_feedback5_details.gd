extends GutTest
## Round 5: readable Rings, honest sale payouts, borrowed rules and both sides' reminders.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const ReminderSlip := preload("res://src/ui/widgets/reminder_slip.gd")
const Keywords := preload("res://src/ui/keyword_rules.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_rings_print_slot_words_instead_of_dictionary_syntax() -> void:
	var marks: String = PlayView._slot_marks([{"name": "Ring", "attack": 1, "health": 1}])
	assert_eq(marks, " [Slot: Ring +1/+1]")
	assert_false(marks.contains("{"))
	var state: Dictionary = {
		"board": [null],
		"slot_effects": [[{"name": "Ring", "attack": 3, "health": 2}]],
		"away": [],
		"round": 1
	}
	var lines: PackedStringArray = []
	PlayView._board(state, lines)
	assert_string_contains("\n".join(lines), "F1 (empty) [Slot: Ring +3/+2]")


func test_frumenty_details_show_borrowed_golden_rules_in_both_phases() -> void:
	var library := UnitLibrary.load_dir()
	var frumenty := RecruitUnit.make(library.get_unit("frumenty"), 100)
	frumenty.held.append(RecruitUnit.make(library.get_unit("hoglet_mother"), 101, true))
	var view: Dictionary = frumenty.view()
	var full: String = CardDetail.full_text_bbcode(view)
	assert_string_contains(full, "Borrowed from Hoglet Mother:")
	assert_string_contains(full, "Bristle[/url][/b] 2.")
	assert_string_contains(full, "golden 2/2 Hoglet")
	assert_string_contains(PlayView._card(view), "Borrowed from Hoglet Mother: Bristle 2.")
	var fighter := CombatUnit.make(library.get_unit("frumenty"), frumenty.combat_spec(), 1, 0)
	assert_eq(fighter.view()["borrowed_rules"], view["borrowed_rules"])
	assert_string_contains(CardDetail.full_text_bbcode(fighter.view()), "golden 2/2 Hoglet")


func test_frumenty_borrowed_rules_exclude_unborrowed_text_and_keep_limits() -> void:
	var library := UnitLibrary.load_dir()
	var frumenty := RecruitUnit.make(library.get_unit("frumenty"), 100, true)
	frumenty.held.append(RecruitUnit.make(library.get_unit("wee_wobbly"), 101))
	frumenty.held.append(RecruitUnit.make(library.get_unit("mrs_jay"), 102))
	var rules: Array = frumenty.view()["borrowed_rules"]
	assert_string_contains(rules[0]["text"], "After this survives a hit:")
	assert_string_contains(rules[0]["text"], "a 1/1 Drip")
	assert_string_contains(rules[0]["text"], "Twice a fight.")
	assert_false(rules[0]["text"].contains("Belly"))
	assert_eq(rules[1]["text"], "No borrowed text.")
	assert_eq(
		frumenty.borrowed_text().size(), 1, "display filtering follows actual copied mechanics"
	)


func test_last_fight_enemy_and_summon_keywords_join_the_same_glossary() -> void:
	var state: Dictionary = {"pending_choice": null}
	for key: String in [
		"shop", "board", "hand", "hand_items", "shop_spells", "next_opponent_last_board"
	]:
		state[key] = []
	var library := UnitLibrary.load_dir()
	var enemy: Dictionary = UnitViews.from_def(library.get_unit("hoglet_mother"), false, 2)
	var arrival: Dictionary = UnitViews.from_def(library.get_unit("hedge_witch"), false, 3)
	var fight: Dictionary = {
		"events":
		[
			{"type": "combat_start", "boards": [[], [enemy]]},
			{"type": "summon", "unit": arrival},
			{"type": "text_taken", "uid": 1, "from": 2}
		]
	}
	var lines: PackedStringArray = []
	PlayView._glossary(state, lines, fight)
	var words: String = "\n".join(lines)
	for keyword: String in ["Bristle", "Hex"]:
		assert_string_contains(words, "%s: %s" % [keyword, Keywords.text(keyword)])
		assert_eq(words.count(keyword + ":"), 1, "one explanation for either side")


func test_enemy_only_keyword_opens_the_same_slip_on_pc_and_phone() -> void:
	var library := UnitLibrary.load_dir()
	for window: Vector2 in [Vector2(1920, 1080), Vector2(1688, 780)]:
		CardView.window_override = window
		var viewport := SubViewport.new()
		viewport.size = Vector2i(roundi(1080.0 * window.x / window.y), 1080)
		add_child_autofree(viewport)
		var screen: CombatScreen = CombatScreen.new()
		viewport.add_child(screen)
		var mine: Dictionary = UnitViews.from_def(library.get_unit("field_vole"), false, 1)
		var enemy: Dictionary = UnitViews.from_def(library.get_unit("hoglet_mother"), false, 2)
		var fight: Dictionary = {
			"events":
			[
				{
					"type": "combat_start",
					"player_ids": [0, 1],
					"first_side": 0,
					"boards":
					[
						[mine, null, null, null, null, null, null],
						[enemy, null, null, null, null, null, null]
					]
				}
			]
		}
		screen.setup(fight, PackedStringArray(["You", "Enemy"]), 0, "Round 5")
		screen.playing = false
		screen.step_once()
		screen.call("_on_card_tapped", "combat", 2)
		var notes: RichTextLabel = screen.get("_note_text")
		assert_string_contains(notes.text, "[url=kw:Bristle]")
		notes.meta_hover_started.emit("kw:Bristle")
		if window.y == 780:
			notes.meta_clicked.emit("kw:Bristle")
		var slip: ReminderSlip = notes.get_meta("reminder")
		assert_true(slip.visible)
		assert_eq(slip.keyword, "Bristle")
		var words: RichTextLabel = slip.get("_text")
		assert_string_contains(words.get_parsed_text(), Keywords.text("Bristle"))
