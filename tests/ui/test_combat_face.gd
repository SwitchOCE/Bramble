extends GutTest
## Fight faces expose targeting and defence as marks; only current numbers use labels.

const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatFace := preload("res://src/ui/widgets/combat_face.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func _card() -> CardView:
	var tile: CardView = CardView.new()
	tile.theme = UiTheme.get_theme()
	tile.position = Vector2(200, 200)
	tile.combat_face = true
	tile.show_unit(
		{
			"name": "A name that belongs in the reader",
			"tier": 4,
			"attack": 12,
			"health": 19,
			"max_health": 20,
			"golden": true,
			"text": "When this dies: Give another unit Shield.",
			"keywords": ["Mire", "Quarry", "Swoop", "Bristle"],
			"statuses":
			[
				{"status": "shield"},
				{"status": "shell"},
				{"status": "nightshade"},
				{"status": "warned"},
				{"status": "mired"}
			]
		},
		CardView.Mode.BOARD
	)
	tile.set_card_size(Vector2(200, 216))
	add_child_autofree(tile)
	return tile


func test_combat_face_has_only_stats_and_independent_wordless_marks() -> void:
	var tile: CardView = _card()
	var marks: CombatFace = tile.get("_combat_marks")
	assert_eq(tile.chip_shown, "")
	for part: String in [
		"_name_label", "_type_label", "_tier_badge", "_chip", "_status_tag", "_star"
	]:
		var control: Control = tile.get(part)
		assert_false(control.visible, part)
	assert_eq(marks.glyph_kind, "bones")
	assert_eq(marks.marked_keywords, PackedStringArray(["Mire", "Quarry", "Swoop"]))
	assert_eq(marks.marked_statuses.size(), 5, "statuses stack without a combined slip")
	assert_eq(tile.trigger_glyph(), marks.glyph)
	var attack: Control = tile.get("_attack_badge")
	var health: Control = tile.get("_health_badge")
	assert_eq(tile.attack_bead(), attack)
	assert_eq(tile.health_bead(), health)
	assert_eq(LayoutCheck.problems(tile, "wordless fight face"), PackedStringArray())


func test_held_count_replaces_the_glyph_and_old_slip_without_words() -> void:
	var tile: CardView = _card()
	var view: Dictionary = tile.unit.duplicate(true)
	view["held"] = 2
	view["kisses"] = 2
	tile.show_unit(view, CardView.Mode.BOARD)
	tile.turns_shown = "In 2"
	var marks: CombatFace = tile.get("_combat_marks")
	assert_eq(marks.counter.text, "2")
	assert_eq(marks.counter_kind, "belly")
	assert_false(marks.glyph.visible)
	assert_eq(tile.trigger_glyph(), marks.counter, "a trigger pulses the occupied glyph spot")
	var slip: Label = tile.get("_turns")
	assert_null(slip, "worded held slip is never built")
	assert_gte(marks.counter.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
	assert_lte(marks.counter.size.x, 64.0)
	assert_eq(LayoutCheck.problems(tile, "held fight face"), PackedStringArray())


func test_on_play_has_no_trigger_mark_and_recruit_keeps_its_chip() -> void:
	assert_eq(CombatFace.trigger_kind({"text": "On play: Gain 1 Attack."}), "")
	assert_eq(CombatFace.trigger_kind({"text": "When played: Gain 1 Attack."}), "")
	assert_eq(CombatFace.trigger_kind({"text": "Start of Combat: Gain Shield."}), "spark")
	var tile: CardView = _card()
	tile.combat_face = false
	assert_false(tile.chip_shown.is_empty())
	var marks: CombatFace = tile.get("_combat_marks")
	assert_eq(marks.marked_statuses, PackedStringArray(["shield"]))
	assert_eq(marks.marked_keywords, PackedStringArray())
	assert_false(marks.glyph.visible)


func test_unknown_combat_counters_are_not_guessed_from_rules_text() -> void:
	assert_eq(CombatFace.counter_value({"text": "Hex 4. Bitter 2."}), {})
	assert_eq(CombatFace.counter_value({"ammo": 0}), {"kind": "acorn", "number": "0"})
	assert_eq(CombatFace.counter_value({"held": 3}), {"kind": "belly", "number": "3"})
	assert_eq(CombatFace.counter_value({"bitter": 2}), {"kind": "berry", "number": "2"})


func test_printed_shield_has_the_same_bubble_in_recruit_and_consumes_in_combat() -> void:
	var tile: CardView = _card()
	var view: Dictionary = tile.unit.duplicate(true)
	view["keywords"] = ["Shield"]
	view["statuses"] = []
	tile.show_unit(view, CardView.Mode.BOARD)
	var marks: CombatFace = tile.get("_combat_marks")
	assert_false(marks.marked_statuses.has("shield"), "spent Shield does not grow back from text")
	tile.combat_face = false
	assert_true(marks.marked_statuses.has("shield"), "printed Shield shows before the fight")


func test_granted_quarry_and_mire_use_the_printed_keyword_frame_marks() -> void:
	var tile: CardView = _card()
	var view: Dictionary = tile.unit.duplicate(true)
	view["keywords"] = []
	view["quarry"] = 42
	view["mire_granted"] = true
	tile.show_unit(view, CardView.Mode.BOARD)
	var marks: CombatFace = tile.get("_combat_marks")
	assert_eq(marks.marked_keywords, PackedStringArray(["Quarry", "Mire"]))
