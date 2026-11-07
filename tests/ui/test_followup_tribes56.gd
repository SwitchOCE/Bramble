extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

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
	"mr_redbreast": "Per Nest",
	"peat_cutter": "Mired gold",
	"beadle_warrenby": "Spill",
	"ichneumon_wasp": "Delayed kill",
	"pipistrelle_echo": "Spell echo",
	"reel_mistress": "Ring dance",
	"mountain_glutton": "Take growth",
	"tiddy_mun": "Maker grows",
}
var _combat: Combat


func test_every_plain_and_golden_unit_has_a_meaningful_authored_chip() -> void:
	for card: Dictionary in FIGHT.library.all_units():
		for golden: bool in [false, true]:
			var view: Dictionary = Views.from_def(card, golden)
			if str(view["text"]).is_empty():
				continue
			var chip: String = Cards.chip_text(view)
			assert_ne(chip, "Ability", str(card["id"]))
			assert_false(chip.is_empty(), str(card["id"]))
			assert_lte(chip.length(), 16, "%s: %s" % [card["id"], chip])


func test_all_eleven_audited_fallbacks_have_explicit_plain_and_golden_tags() -> void:
	for id: String in TAGS:
		for golden: bool in [false, true]:
			# Golden Reel-Mistress already has the informative numeric Ring tag.
			var wanted: String = "Ring +1/+1" if id == "reel_mistress" and golden else str(TAGS[id])
			assert_eq(Cards.chip_text(Views.from_def(FIGHT.library.get_unit(id), golden)), wanted)


func _setup(ours: Dictionary, theirs: Dictionary, mousewife: bool = false) -> void:
	var rng := RandomNumberGenerator.new()
	_combat = Combat.create(FIGHT.library, GameConfig.full_game(), rng)
	_combat._tiers = [3, 3]
	if mousewife:
		_combat.hero_effects[0] = HeroRules.effects_of(
			FIGHT.library.get_hero("old_mother_mousewife")
		)
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


func test_mousewife_reports_one_fizzle_but_still_summons_when_room_opens() -> void:
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
	assert_eq(_events("no_room").size(), 1)
	assert_true(_events("side_trigger").is_empty(), "failed summons do not claim hero success")
	_kill(0, 6)
	_kill(0, 2)
	assert_eq(_events("no_room").size(), 1)
	assert_eq(_events("side_trigger").size(), 1, "a later successful firing remains visible")
	assert_eq(_events("summon").size(), 1)
	assert_eq(_events("summon")[0]["slot"], 6)
	assert_eq(_events("summon")[0]["unit"]["attack"], 3)
	assert_eq(
		_combat._triggers, 3, "all three attempted firings still count against the trigger cap"
	)
	for text: String in _visible_lines():
		assert_eq(text.count("no room for a Mouse"), 1)
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
		assert_eq(_events("no_room").size(), 2, "fresh notices for fight %d" % fight)
		assert_eq(_events("no_room")[0]["side"], 0)
		assert_eq(_events("no_room")[1]["side"], 1)


func test_failed_mouse_summons_still_spill_with_beadle() -> void:
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
	assert_eq(_events("no_room").size(), 1)
	assert_eq(_events("spill").size(), 2, "both failed summons still earn their Spill")
	assert_true(_events("side_trigger").is_empty())


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
		assert_string_contains(text, "Wick (F2)")
		assert_string_contains(text, "stays out of")
		assert_string_contains(text, "Little Nip (F1)")
		assert_string_contains(text, "Bridge Toad (F2)")
		assert_string_contains(text, "while Mired")
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
