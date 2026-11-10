extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Detail := preload("res://src/ui/widgets/card_detail.gd")
const Cards := preload("res://src/ui/widgets/card_view.gd")
const Views := preload("res://src/ui/unit_views.gd")
const Model := preload("res://src/ui/screens/combat_model.gd")
const Log := preload("res://src/ui/screens/combat_log.gd")
const PlayLog := preload("res://tools/play/play_fight_log.gd")
const FIGHT := preload("res://tests/core/combat_kit.gd")
const TAGS: Dictionary = {
	"natterjack_chorus": "Mire",
	"madame_ermeline": "Take reward",
	"pennywort_snail": "Sale grows",
	"mr_redbreast": "Homecoming",
	"peat_cutter": "Mire",
	"beadle_warrenby": "Pass +1/+1",
	"ichneumon_wasp": "Delayed kill",
	"pipistrelle_echo": "Spell echo",
	"reel_mistress": "Ring dance",
	"mountain_glutton": "Take growth",
	"tiddy_mun": "Hit growth",
	"moss_ooze": "Comes out",
}
var _library: UnitLibrary = LegacyWave1.with_hedgerow(LegacyBog.library(false))
var _combat: Combat


func test_every_plain_and_golden_unit_keeps_rules_in_reader_without_word_chips() -> void:
	for definition: Dictionary in _library.all_units():
		for golden: bool in [false, true]:
			var view: Dictionary = Views.from_def(definition, golden)
			assert_eq(Cards.chip_text(view), "")
			if not str(view["text"]).is_empty():
				assert_false(Detail.full_text_bbcode(view).is_empty(), str(definition["id"]))


func test_audited_cards_keep_their_exact_abilities_in_the_reader() -> void:
	for id: String in TAGS:
		for golden: bool in [false, true]:
			var view: Dictionary = Views.from_def(_library.get_unit(id), golden)
			assert_eq(Cards.chip_text(view), "")
			assert_false(Detail.full_text_bbcode(view).is_empty(), id)


func _setup(ours: Dictionary, theirs: Dictionary, mousewife: bool = false) -> void:
	var rng := RandomNumberGenerator.new()
	_combat = Combat.create(_library, GameConfig.full_game(), rng)
	_combat._tiers = [3, 3]
	if mousewife:
		_combat.hero_effects[0] = HeroRules.effects_of(_library.get_hero("old_mother_mousewife"))
	_combat._setup([FIGHT.board(ours), FIGHT.board(theirs)])
	_combat._recalc_auras(false)
	_combat.emit_event(
		"combat_start",
		{
			"boards": [_combat._board_views(0), _combat._board_views(1)],
			"player_ids": [0, 1],
			"first_side": 0
		}
	)
	CombatLanes.bell(_combat)


func _kill(side: int, slot: int) -> void:
	_combat.deal_effect_damage(null, _combat.unit_at(side, slot), 999)
	_combat._resolve_deaths(side)


func _events(type: String) -> Array[Dictionary]:
	return FIGHT.of_type({"events": _combat.events}, type)


func _visible_lines() -> Array[String]:
	var model := Model.new()
	var log_text := Log.new()
	var names: Dictionary = {}
	var ui: PackedStringArray = []
	var tool: PackedStringArray = []
	for event: Dictionary in _combat.events:
		ui.append(log_text.describe(event, model, false))
		tool.append(PlayLog.event_line(event, names, 0))
		model.apply(event)
	return ["\n".join(ui), "\n".join(tool)]


func test_mousewife_replaces_two_units_in_place_then_stops() -> void:
	_setup(
		{
			0: FIGHT.plain(1, 2),
			1: FIGHT.plain(1, 2),
			2: FIGHT.plain(1, 2),
			4: FIGHT.plain(1, 2),
			5: FIGHT.plain(1, 2),
			6: FIGHT.plain(1, 2)
		},
		{0: FIGHT.plain(1, 100)},
		true
	)
	_kill(0, 0)
	_kill(0, 1)
	assert_true(_events("no_room").is_empty())
	assert_eq(_events("side_trigger").size(), 1, "hero notice appears once a fight")
	_kill(0, 6)
	_kill(0, 2)
	assert_eq(_events("summon").size(), 2)
	assert_eq(_events("summon")[0]["slot"], 0)
	assert_eq(_events("summon")[1]["slot"], 1)
	assert_eq(_events("summon")[0]["unit"]["attack"], 3)
	for text: String in _visible_lines():
		assert_false("no room for a Mouse" in text)
		assert_eq(text.count("hero power goes off"), 1)


func test_mousewife_notice_is_independent_for_each_side_and_each_fight() -> void:
	for fight: int in 2:
		_setup(
			{0: FIGHT.plain(1, 2), 4: FIGHT.plain(1, 2)},
			{0: FIGHT.plain(1, 2), 4: FIGHT.plain(1, 2)},
			true
		)
		_combat.hero_effects[1] = _combat.hero_effects[0]
		_kill(0, 0)
		_kill(1, 0)
		assert_eq(_events("side_trigger").size(), 2, "fresh notices for fight %d" % fight)
		assert_eq(_events("side_trigger")[0]["side"], 0)
		assert_eq(_events("side_trigger")[1]["side"], 1)


func test_mouse_replacements_do_not_spill_with_beadle() -> void:
	_setup(
		{
			0: FIGHT.plain(1, 2),
			1: FIGHT.plain(1, 2),
			4: FIGHT.plain(1, 2),
			5: FIGHT.plain(1, 2),
			6: FIGHT.u("beadle_warrenby"),
		},
		{0: FIGHT.plain(1, 100)},
		true
	)
	_kill(0, 0)
	_kill(0, 1)
	assert_true(_events("no_room").is_empty())
	assert_true(_events("spill").is_empty(), "successful replacements do not Spill")
	assert_eq(_events("summon").size(), 2)
	assert_eq(_events("side_trigger").size(), 1)


func test_a_mired_pack_joiner_names_its_maker_and_keeps_its_turn() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 2, 20), 1: FIGHT.u("wick", 2, 20)},
		{0: FIGHT.plain(1, 100), 1: FIGHT.u("bridge_toad", 1, 100)}
	)
	var leader: CombatUnit = _combat.unit_at(0, 0)
	var joiner: CombatUnit = _combat.unit_at(0, 1)
	_combat._attack(leader, _combat.unit_at(1, 0))
	assert_eq(_events("pack_blocked").size(), 1)
	assert_true(_events("attack")[0]["joiners"].is_empty())
	assert_false(joiner.flagged)
	for text: String in _visible_lines():
		assert_string_contains(text, "Wick")
		assert_string_contains(text, "stays out of")
		assert_string_contains(text, "Little Nip")
		assert_string_contains(text, "Bridge Toad")
		assert_string_contains(text, "Mired by")
	_combat._attack(leader, _combat.unit_at(1, 1))
	assert_eq(_events("pack_blocked").size(), 1, "joining against its maker is legal")
	assert_eq(_events("attack")[1]["joiners"], [joiner.uid])
	assert_true(joiner.flagged)


func test_an_already_spent_joiner_does_not_claim_mire_stopped_it() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 2, 20), 1: FIGHT.u("wick", 2, 20)},
		{0: FIGHT.plain(1, 100), 1: FIGHT.u("bridge_toad", 1, 100)}
	)
	_combat.unit_at(0, 1).flagged = true
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_true(_events("pack_blocked").is_empty())
