extends GutTest
## Fight faces expose targeting and defence as marks; only current numbers use labels.

const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatFace := preload("res://src/ui/widgets/combat_face.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
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


func test_swallow_anchor_tracks_the_stomach_above_its_count_at_both_sizes() -> void:
	for dimensions: Vector2 in [Vector2(96, 116), Vector2(200, 216)]:
		var tile: CardView = _card()
		var view: Dictionary = tile.unit.duplicate(true)
		view["held"] = [{"def_id": "sleeping_partner"}]
		tile.show_unit(view, CardView.Mode.BOARD)
		tile.set_card_size(dimensions)
		tile.scale = Vector2.ONE * 1.1
		var marks: CombatFace = tile.get("_combat_marks")
		var anchor: Vector2 = tile.belly_point()
		assert_true(tile.get_global_rect().has_point(anchor), str(dimensions))
		assert_lt(anchor.y, marks.counter.get_global_rect().position.y)
		assert_almost_eq(anchor.x, marks.counter.get_global_rect().get_center().x, 0.01)
		var before: Vector2 = anchor
		tile.position += Vector2(42, -19)
		assert_eq(tile.belly_point() - before, Vector2(42, -19), "anchor follows the tile")
		assert_eq(marks.counter.text, "1", "the route anchor adds no label")


func test_on_play_has_no_trigger_mark_and_recruit_uses_wordless_marks() -> void:
	assert_eq(CombatFace.trigger_kind({"text": "On play: Gain 1 Attack."}), "")
	assert_eq(CombatFace.trigger_kind({"text": "When played: Gain 1 Attack."}), "")
	assert_eq(CombatFace.trigger_kind({"text": "Start of Combat: Gain Shield."}), "spark")
	var tile: CardView = _card()
	tile.combat_face = false
	assert_eq(tile.chip_shown, "")
	var marks: CombatFace = tile.get("_combat_marks")
	assert_eq(marks.marked_statuses, PackedStringArray(["shield"]))
	assert_true(marks.marked_keywords.has("Mire"))
	assert_true(marks.marked_keywords.has("Quarry"))
	assert_true(marks.glyph.visible)


func test_recruit_only_triggers_have_no_combat_spark() -> void:
	for text: String in [
		"Start of Turn: get 1 gold.",
		"End of Turn: your smallest unit gains +1/+1.",
		"Every 3rd End of Turn: double your Ring size.",
		"After you cast a spell: get 1 gold.",
		"When a spell gives your Ooze stats: what's inside gains them.",
		"After you get an Acorn: Pass +1/+1.",
		"After you put a unit into any Belly: gain +1/+1.",
		"After a Bird comes home: gain an eighth of its stats.",
		"After 3 turns in this slot: double its stats.",
		"When this leaves: your Rings grow +1/+1.",
	]:
		assert_eq(CombatFace.trigger_kind({"text": text}), "", text)


func test_fight_triggers_keep_sparks_including_borrowed_or_mixed_rules() -> void:
	for text: String in [
		"Quarry. Take: gain +1/+1 permanently.",
		"Mire. After the enemy this Mires attacks this: attack it back.",
		"Pounce. After this pounces: gain +2/+1.",
		"Whenever this is attacked: give the units behind it +1 Attack.",
		"After a friendly unit dies: get 1 gold next turn.",
		"After you summon a unit: give it +1/+1. Twice a turn.",
		"When a unit comes out of your Oozes: its Start of Combat fires.",
		"End of Turn: get gold.\nStart of Combat: gain Shield.",
	]:
		assert_eq(CombatFace.trigger_kind({"text": text}), "spark", text)
	assert_eq(CombatFace.trigger_kind({"text": "When this dies: summon a Hoglet."}), "bones")


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


func test_configured_kiss_pips_read_initial_and_replayed_state_at_both_sizes() -> void:
	for tile_size: Vector2 in [Vector2(96, 116), Vector2(200, 216)]:
		var tile: CardView = _card()
		var view: Dictionary = tile.unit.duplicate(true)
		view["counters"] = {"kisses": 4}
		view["bog_kiss_period"] = 5
		tile.show_unit(view, CardView.Mode.BOARD)
		tile.set_card_size(tile_size)
		var marks: CombatFace = tile.get("_combat_marks")
		assert_eq(marks.kiss_count, 4)
		assert_eq(marks.kiss_period, 5)
		assert_eq(marks.kiss_progress, 4)
		assert_eq(marks.kiss_pips.size(), 5)
		assert_eq(tile.chip_shown, "")
		for pip: Vector2 in marks.kiss_pips:
			assert_true(Rect2(Vector2.ZERO, tile_size).has_point(pip))
		tile.set_kisses(5, 5)
		assert_eq(marks.kiss_count, 5, "replay replaces initial nested counter")
		assert_eq(marks.kiss_progress, 0, "a full period starts a fresh wordless row")
		assert_string_contains(CardDetail.full_text_bbcode(tile.unit), "Shared kisses: 5 (0/5)")
		tile.set_kisses(7, 3)
		assert_eq(marks.kiss_pips.size(), 3)
		assert_eq(marks.kiss_progress, 1)


func test_kiss_pips_accept_both_top_level_fields_and_default_period() -> void:
	var tile: CardView = _card()
	for field: String in ["kisses", "recruit_kisses"]:
		var view: Dictionary = tile.unit.duplicate(true)
		view.erase("kisses")
		view.erase("recruit_kisses")
		view[field] = 4
		tile.show_unit(view, CardView.Mode.BOARD)
		var marks: CombatFace = tile.get("_combat_marks")
		assert_eq(marks.kiss_count, 4, field)
		assert_eq(marks.kiss_period, 3, field)
		assert_eq(marks.kiss_progress, 1, field)


func test_pending_hourglass_refreshes_without_labels_and_stays_clear_of_other_marks() -> void:
	for tile_size: Vector2 in [Vector2(96, 116), Vector2(200, 216)]:
		var tile: CardView = _card()
		tile.set_card_size(tile_size)
		tile.set_kisses(4, 5)
		var marks: CombatFace = tile.get("_combat_marks")
		assert_false(marks.pending_visible)
		for gains: Vector2i in [Vector2i(0, 5), Vector2i(7, 0), Vector2i(123456, 1234567)]:
			tile.set_pending_gains(gains.x, gains.y)
			assert_true(marks.pending_visible)
			assert_eq(marks.pending_attack, gains.x)
			assert_eq(marks.pending_health, gains.y)
			var numeric_tag: Control = tile.get("_pending_tag")
			assert_false(numeric_tag.visible)
			assert_eq(
				tile.pending_gain_point(),
				marks.get_global_transform() * marks.pending_rect.get_center()
			)
			assert_true(Rect2(Vector2.ZERO, tile_size).encloses(marks.pending_rect))
			for key: String in ["_attack_badge", "_health_badge"]:
				var badge: Control = tile.get(key)
				var pending_on_card := Rect2(
					marks.position + marks.pending_rect.position, marks.pending_rect.size
				)
				assert_false(pending_on_card.intersects(badge.get_rect()), key)
			assert_false(marks.pending_rect.intersects(marks.glyph.get_rect()))
			for pip: Vector2 in marks.kiss_pips:
				assert_false(marks.pending_rect.grow(7).has_point(pip))
		tile.set_pending_gains(0, 0)
		assert_false(marks.pending_visible)
