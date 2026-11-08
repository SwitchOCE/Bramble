extends GutTest
## Round 5: readable Rings, honest sale payouts, borrowed rules and both sides' reminders.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
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


func test_recruit_no_room_notice_reaches_the_screen_and_cli() -> void:
	var entry: Dictionary = {"type": "no_room", "unit": "mouse", "name": "Mouse"}
	assert_eq(RecruitView.event_note(entry), "No room for Mouse.")
	var before: Dictionary = {"round": 1, "recruit_log": []}
	var after: Dictionary = {"round": 1, "recruit_log": [entry]}
	assert_string_contains(RecruitView.change_notices(before, after), "No room for Mouse.")
	var lines: PackedStringArray = []
	PlayView._this_turn(null, after, lines)
	assert_has(lines, "No room for Mouse.")


func test_banked_hex_wraps_and_hides_the_chip_for_native_borrowed_and_granted_hex() -> void:
	var library := UnitLibrary.load_dir()
	var witch := RecruitUnit.make(library.get_unit("hedge_witch"), 100)
	var borrowed := RecruitUnit.make(library.get_unit("frumenty"), 101)
	borrowed.held.append(RecruitUnit.make(library.get_unit("hedge_witch"), 102, true))
	var granted := RecruitUnit.make(library.get_unit("field_vole"), 103)
	granted.grants.append({"entry": {"id": "hex", "n": 1, "most": "tier"}})
	for unit: RecruitUnit in [witch, borrowed, granted]:
		unit.counters["hex"] = 99
		var card := CardView.new()
		add_child_autofree(card)
		card.show_unit(unit.view(), CardView.Mode.BOARD)
		card.set_card_width(176)
		card.turns_shown = RecruitView.tile_slip(unit.view())
		var label: Label = card.get("_turns")
		var chip: Control = card.get("_chip")
		assert_string_contains(label.text, "\n")
		assert_string_contains(label.text, "stored")
		assert_false(chip.visible, "%s's chip clears the wrapped Hex label" % unit.def_id())


func test_frumenty_mixed_rules_ignore_card_rewording_and_punctuation() -> void:
	var library := UnitLibrary.load_dir()
	for golden: bool in [false, true]:
		var def: Dictionary = library.get_unit("wee_wobbly").duplicate(true)
		def["text"] = "NEW BELLY WORDS; hidden sale reward! Not split into sentences"
		def["golden_text"] = "Different wording\nwith no standard trigger prefixes or periods"
		var source := RecruitUnit.make(def, 101, golden)
		var frumenty := RecruitUnit.make(library.get_unit("frumenty"), 100, not golden)
		frumenty.held.append(source)
		var rule: Dictionary = frumenty.view()["borrowed_rules"][0]
		var fragments: Dictionary = def["mechanic_text"]
		var fragment: Dictionary = fragments["1"]
		assert_eq(rule["text"], fragment["golden_text" if golden else "text"])
		assert_string_contains(rule["text"], "Twice a fight.")
		assert_string_contains(rule["text"], "golden 2/2 Drip" if golden else "a 1/1 Drip")
		assert_false(rule["text"].contains("BELLY WORDS"))
		assert_false(rule["text"].contains("Different wording"))


func test_frumenty_selects_each_mixed_mechanic_and_excludes_all_unborrowed_triggers() -> void:
	var library := UnitLibrary.load_dir()
	var def: Dictionary = library.get_unit("wee_wobbly").duplicate(true)
	def.erase(MechanicRegistry.COMPILED_KEY)
	var mechanics: Array = def["mechanics"]
	var fragments: Dictionary = def["mechanic_text"]
	for trigger: String in ["on_play", "on_sell", "on_home"]:
		fragments[str(mechanics.size())] = {
			"id": "effect",
			"trigger": trigger,
			"text": "EXCLUDED reward; no trigger prefix",
			"golden_text": "EXCLUDED golden reward"
		}
		mechanics.append(
			{"id": "effect", "trigger": trigger, "do": {"effect": "gold", "amount": 7}}
		)
	var allowed: int = mechanics.size()
	mechanics.append(
		{
			"id": "effect",
			"trigger": "end_of_turn",
			"do": {"effect": "buff", "attack": 1, "health": 2}
		}
	)
	fragments[str(allowed)] = {
		"id": "effect",
		"trigger": "end_of_turn",
		"text": "End of Turn: gain +1/+2.",
		"golden_text": "End of Turn: gain +2/+4."
	}
	def["text"] = "EXCLUDED play, sale and home words mixed with borrowed text; no periods"
	def["golden_text"] = def["text"]
	var frumenty := RecruitUnit.make(library.get_unit("frumenty"), 100)
	frumenty.held.append(RecruitUnit.make(def, 101, true))
	var words: String = frumenty.view()["borrowed_rules"][0]["text"]
	assert_string_contains(words, "End of Turn: gain +2/+4.")
	assert_string_contains(words, "Twice a fight.")
	assert_false(words.contains("EXCLUDED"))
	var borrowed: Array[Dictionary] = frumenty.borrowed_text()
	assert_eq(borrowed.size(), 2, "only Wobbly and End of Turn are copied")
	for grant: Dictionary in borrowed:
		assert_true(RecruitUnit._can_lend(grant["entry"]))


func test_frumenty_never_falls_back_to_full_mixed_card_text_for_stale_fragments() -> void:
	var library := UnitLibrary.load_dir()
	for stale: String in ["missing", "id", "golden_text", "trigger"]:
		var def: Dictionary = library.get_unit("mrs_posset").duplicate(true)
		def["text"] = "EXCLUDED Belly and death ability in one inseparable sentence"
		def["golden_text"] = def["text"]
		var fragments: Dictionary = def["mechanic_text"]
		var fragment: Dictionary = fragments["1"]
		if stale == "missing":
			fragments.clear()
		elif stale == "id":
			fragment["id"] = "belly"
		elif stale == "golden_text":
			fragment.erase("golden_text")
		else:
			fragment["trigger"] = "on_sell"
		var frumenty := RecruitUnit.make(library.get_unit("frumenty"), 100)
		frumenty.held.append(RecruitUnit.make(def, 101, true))
		var words: String = frumenty.view()["borrowed_rules"][0]["text"]
		assert_eq(words, "Borrowed rules unavailable.", stale)
		assert_false(words.contains("EXCLUDED"))


func test_every_mixed_card_has_fragments_for_exactly_its_lendable_mechanics() -> void:
	var library := UnitLibrary.load_dir()
	var mixed: int = 0
	for def: Dictionary in library.all_units():
		var entries: Array = def["mechanics"]
		var lendable: Array[int] = []
		for index: int in entries.size():
			if RecruitUnit._can_lend(entries[index]):
				lendable.append(index)
		if lendable.is_empty() or lendable.size() == entries.size():
			continue
		mixed += 1
		var fragments: Dictionary = def.get("mechanic_text", {})
		assert_eq(fragments.size(), lendable.size(), def["id"])
		for index: int in lendable:
			var fragment: Dictionary = fragments.get(str(index), {})
			var entry: Dictionary = entries[index]
			assert_eq(fragment.get("id"), entry["id"], def["id"])
			assert_eq(fragment.get("trigger", ""), entry.get("trigger", ""), def["id"])
			for key: String in ["text", "golden_text"]:
				assert_false(str(fragment.get(key, "")).is_empty(), "%s %s" % [def["id"], key])
	assert_eq(mixed, 13, "all existing mixed cards have explicit fragments")
