extends GutTest
## Cards on screen: rules on the tile, Acorn sizes, big and frozen stats. What must ship or never
## show: font licences, designers' notes, debug strings. A real fight with motion turned down.

const App := preload("res://src/ui/app.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const Data := preload("res://src/ui/view_data.gd")
const HeroPlaque := preload("res://src/ui/widgets/hero_plaque.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const Settings := preload("res://src/ui/settings.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")

const DESKTOP: Vector2 = Vector2(1920, 1080)
const PHONE: Vector2 = Vector2(1688, 780)
const LONG_RULES: String = "alderman_dozey"


func after_each() -> void:
	CardView.window_override = Vector2.ZERO
	Settings.reduce_motion = false


func _port() -> CorePort:
	var port: CorePort = CorePort.new()
	port.setup()
	return port


func _holder() -> Control:
	var holder: Control = Control.new()
	holder.theme = UiTheme.get_theme()
	holder.size = DESKTOP
	add_child_autofree(holder)
	return holder


func _tile(holder: Control, view: Dictionary, width: float = CardView.SHOP_WIDTH) -> CardView:
	var card: CardView = CardView.new()
	card.show_unit(view, CardView.Mode.SHOP)
	card.set_card_width(width)
	card.position = Vector2(200, 200)
	holder.add_child(card)
	return card


func _slice_units(port: CorePort) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for def: Dictionary in port.library_units():
		if def.get("set") == "slice" and not str(def.get("text", "")).is_empty():
			out.append(def)
	return out


func test_every_slice_card_shows_its_rules_on_a_desktop_shop_tile() -> void:
	CardView.window_override = DESKTOP
	var holder: Control = _holder()
	var units: Array[Dictionary] = _slice_units(_port())
	assert_gt(units.size(), 10)
	for def: Dictionary in units:
		var card: CardView = _tile(holder, UnitViews.from_def(def))
		await get_tree().process_frame
		assert_true(card.rules_shown, "%s has its rules on the tile" % def["name"])
		assert_eq(LayoutCheck.problems(card, str(def["name"])), PackedStringArray())
		card.queue_free()


func test_at_the_phone_minimum_long_rules_go_to_a_tap_and_short_ones_stay() -> void:
	CardView.window_override = PHONE
	var port: CorePort = _port()
	var holder: Control = _holder()
	var long: Dictionary = UnitViews.from_def(port.library.get_unit(LONG_RULES))
	var card: CardView = _tile(holder, long)
	assert_false(card.rules_shown, "too long at 31")
	assert_false(card.chip_shown.is_empty(), "the tile still says its keyword or Ability")
	var short: Dictionary = long.duplicate()
	short["text"] = "Rainbow."
	var other: CardView = _tile(holder, short)
	assert_true(other.rules_shown, "short rules fit at 31")
	var rules: Label = other.get("_rules")
	assert_eq(rules.get_theme_font_size("font_size"), UiTheme.MIN_FONT)


func test_name_and_card_word_stay_apart_on_a_short_tile_without_rules() -> void:
	CardView.window_override = PHONE
	var holder: Control = _holder()
	var card: CardView = CardView.new()
	var long: String = "Play for 1 gold. Three Acorns combine into a Stash."
	var item: Dictionary = {"name": "Acorn", "kind": "item", "gold_value": 1, "text": long}
	card.show_unit(item, CardView.Mode.SHOP)
	card.set_card_size(Vector2(CardView.SHOP_WIDTH, RecruitScreen.HAND_TWO_H))
	holder.add_child(card)
	assert_false(card.rules_shown)
	var words: Label = card.get("_name_label")
	var kind: Label = card.get("_type_label")
	assert_lte(words.position.y + words.size.y, kind.position.y)


func test_two_cards_in_hand_at_desktop_show_their_rules() -> void:
	CardView.window_override = DESKTOP
	var holder: Control = _holder()
	var card: CardView = CardView.new()
	card.show_unit(
		{"name": "Acorn", "kind": "item", "text": "Play for 1 gold."}, CardView.Mode.SHOP
	)
	card.set_card_size(Vector2(CardView.SHOP_WIDTH, RecruitScreen.HAND_TWO_H))
	holder.add_child(card)
	assert_true(card.rules_shown)


func test_acorn_sizes_have_their_own_portrait_and_read_their_worth() -> void:
	var holder: Control = _holder()
	var seen: Dictionary = {}
	for def_id: String in ["acorn", "stash", "great_hoard"]:
		var view: Dictionary = {"def_id": def_id, "name": def_id, "kind": "item", "gold_value": 20}
		var card: CardView = _tile(holder, view)
		var art: ArtFrame = card.get("_art")
		seen[art.texture.resource_path] = true
		var badge: Label = card.get("_tier_label")
		assert_eq(badge.text, "20", "%s's badge reads its gold value" % def_id)
	assert_eq(seen.size(), 3, "three different pictures")


func test_font_licences_ship_with_every_export() -> void:
	var presets: String = FileAccess.get_file_as_string("res://export_presets.cfg")
	var filters: int = presets.count('include_filter="')
	assert_gt(filters, 0)
	assert_eq(presets.count("assets/fonts/*.txt"), filters, "every preset")


func test_fight_note_names_the_next_opponent_or_the_ghost() -> void:
	var standings: Array = [
		{"player_id": 2, "name": "Bramblewick"}, {"player_id": 3, "name": "Old Tansy"}
	]
	var state: Dictionary = {"next_opponent_id": 3, "standings": standings}
	assert_eq(RecruitView.fight_note(state), "then fight Old Tansy")
	assert_eq(RecruitView.fight_note({"next_opponent_id": -1}), "", "nobody out: no pairing yet")
	assert_eq(RecruitView.fight_note({}), "")


func test_big_stats_fit_inside_their_badges() -> void:
	var port: CorePort = _port()
	var holder: Control = _holder()
	for stats: Array in [[10, 10], [14, 99], [120, 250]]:
		var view: Dictionary = UnitViews.from_def(port.library.get_unit("old_badger"), true)
		view["attack"] = stats[0]
		view["health"] = stats[1]
		view["max_health"] = stats[1]
		view["tier"] = 6
		for width: float in [96.0, 124.0, 168.0]:
			for mode: CardView.Mode in [
				CardView.Mode.SHOP, CardView.Mode.BOARD, CardView.Mode.MINI
			]:
				var card: CardView = CardView.new()
				card.show_unit(view.duplicate(), mode)
				card.set_card_width(width)
				card.position = Vector2(200, 200)
				holder.add_child(card)
				await get_tree().process_frame
				var where: String = "%s at %d mode %d" % [str(stats), int(width), mode]
				assert_eq(LayoutCheck.problems(card, where), PackedStringArray(), where)
				card.queue_free()


func test_frozen_offers_keep_their_stats_visible() -> void:
	var app: App = App.new()
	add_child_autofree(app)
	var port: CorePort = _port()
	app.setup(port)
	Settings.seen_guide = true
	app.start_game(11)
	var recruit: RecruitScreen = app.current as RecruitScreen
	var picker: Control = recruit.get("_discover")
	if picker.visible:
		picker.call("_on_card_tapped", "picker", 0)
	recruit.call("_on_freeze")
	assert_true(Data.b(recruit.state, "frozen", false), "the shop is frozen")
	await get_tree().process_frame
	await get_tree().process_frame
	var shop: Control = recruit.get("_shop_cards")
	var checked: int = 0
	for child: Node in shop.get_children():
		var card: CardView = child as CardView
		if card == null:
			continue
		var where: String = Data.s(card.unit, "name")
		assert_true(card.frost, where + ": frost rim on")
		assert_eq(card.outline, Color.TRANSPARENT, where + ": no outline instead")
		assert_eq(card.modulate, Color.WHITE, where + ": not tinted or faded")
		for key: String in ["_attack_label", "_health_label", "_name_label"]:
			var label: Label = card.get(key)
			if CardView.is_spell(card.unit) and key != "_name_label":
				continue
			assert_true(label.is_visible_in_tree(), where + key + " shows")
			assert_false(label.text.is_empty(), where + key + " has text")
			assert_eq(label.get_theme_color("font_color").a, 1.0, where + key + " is opaque")
		checked += 1
	assert_gt(checked, 0, "the frozen shop has offers")
	assert_eq(LayoutCheck.problems(recruit, "frozen"), PackedStringArray())


func test_no_keyword_reminder_carries_a_designers_note() -> void:
	var port: CorePort = _port()
	for def: Dictionary in port.library_units():
		for keyword: Variant in Data.a(def, "keywords"):
			var words: String = KeywordRules.text(str(keyword))
			assert_false(words.is_empty(), "%s (%s) has player's words" % [keyword, def["id"]])
			_assert_player_words(words)
		var view: Dictionary = UnitViews.from_def(def)
		_assert_player_words(CardDetail.full_text_bbcode(view))


func _assert_player_words(words: String) -> void:
	for dev: String in [
		"library", "prototype", "Prototype", "filler", "SPEC", ".json", "→", "+0/+0"
	]:
		assert_false(words.contains(dev), "'%s' in: %s" % [dev, words])


func _sandbox_fight(port: CorePort, sides: Array) -> Dictionary:
	var boards: Array = [[], []]
	for side: int in 2:
		var row: Array = []
		row.resize(7)
		var ids: Array = sides[side]
		for slot: int in ids.size():
			if str(ids[slot]) != "":
				row[slot] = {"def_id": ids[slot], "golden": false}
		boards[side] = row
	var result: Dictionary = port.sandbox_fight(boards, 3)
	assert_false(result.has("error"), Data.s(result, "error"))
	return result


func _fighters() -> Array:
	return [
		["hedge_witch", "garden_snail", "hoglet", "sett_warden"],
		["marmot_lookout", "worker_bee", "worker_bee", "fox_cub", "weasel_second"],
	]


func test_a_real_fights_log_reads_in_plain_words() -> void:
	var port: CorePort = _port()
	var events: Array = Data.a(_sandbox_fight(port, _fighters()), "events")
	assert_gt(events.size(), 5)
	var words: CombatLog = CombatLog.new()
	var model: CombatModel = CombatModel.new()
	var saw_hex: bool = false
	for entry: Variant in events:
		var event: Dictionary = entry
		saw_hex = saw_hex or Data.s(event, "type") == "slot_hex"
		var line: String = words.describe(event, model)
		model.apply(event)
		var plain: String = RegEx.create_from_string("\\[/?[^\\]]*\\]").sub(line, "", true)
		_assert_player_words(plain)
		assert_false(plain.contains("["), plain)
		assert_false(plain.begins_with("("), plain)
		assert_false(plain.contains("_"), plain)
	assert_true(saw_hex, "the Witch hexed the slot across")
	assert_false(model.slot_hexes.is_empty())


func _combat(fight: Dictionary) -> CombatScreen:
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	screen.setup(fight, ["You", "Bot"], 0, "Fight")
	return screen


func test_a_real_fight_plays_through_with_motion_turned_down() -> void:
	var port: CorePort = _port()
	var fight: Dictionary = _sandbox_fight(port, _fighters())
	Settings.reduce_motion = true
	var screen: CombatScreen = _combat(fight)
	screen.set_speed(4.0)
	var frames: int = 0
	while not screen.is_showing_result() and frames < 3000:
		screen.call("_process", 0.2)
		frames += 1
		if frames % 20 == 0:
			await get_tree().process_frame
	assert_true(screen.is_showing_result(), "the whole fight played")
	var quiet: Dictionary = screen.model.units.duplicate(true)
	Settings.reduce_motion = false
	var moving: CombatScreen = _combat(fight)
	moving.skip_to_end()
	assert_eq(screen.model.winner, moving.model.winner)
	assert_eq(quiet.size(), moving.model.units.size())


func test_hex_shows_on_the_slot_it_lands_on_in_the_fight_and_not_on_a_recruit_unit() -> void:
	var port: CorePort = _port()
	var screen: CombatScreen = _combat(_sandbox_fight(port, _fighters()))
	screen.skip_to_end()
	var marks: Control = screen.board_for_side(1).get("_marks")
	var hexes: Dictionary = marks.get("_hex_labels")
	assert_true(hexes.has(0), "F1 across from the Witch in F1")
	var slip: Label = hexes[0]
	assert_eq(slip.text, "Hex -1")
	assert_false(UiTheme.STATUS_INFO.has("hex"), "Hex is never a status on your own unit")


func test_an_activated_heros_power_is_finger_sized_on_a_phone() -> void:
	var holder: Control = _holder()
	for window: Vector2 in [PHONE, DESKTOP]:
		CardView.window_override = window
		var plaque: HeroPlaque = HeroPlaque.new()
		plaque.size = Vector2(190, 300)
		holder.add_child(plaque)
		plaque.show_hero({"name": "Jill Down-the-Tree", "id": "x", "kind": "activated"})
		await get_tree().process_frame
		assert_gte(plaque.power.size.y, LayoutCheck.min_tap(window), str(window))


func test_a_long_hero_name_reads_whole() -> void:
	var holder: Control = _holder()
	for hero_name: String in ["Old Mother Mousewife", "Old Thornbeard", "Jill Down-the-Tree"]:
		var plaque: HeroPlaque = HeroPlaque.new()
		plaque.size = Vector2(150, 300)
		holder.add_child(plaque)
		plaque.show_hero({"name": hero_name, "id": "x", "kind": "passive"})
		await get_tree().process_frame
		var label: Label = plaque.get("_name")
		assert_eq(label.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING, hero_name)
		assert_eq(label.get_visible_line_count(), label.get_line_count(), hero_name)
		assert_lte(label.get_line_count(), 3, "%s breaks at its spaces only" % hero_name)
		assert_eq(LayoutCheck.problems(plaque, hero_name), PackedStringArray(), hero_name)
