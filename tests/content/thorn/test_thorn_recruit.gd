extends GutTest
## The Briars in the Recruit Phase: the cards load as designed, the Compost every player has, and
## the Bury units and Sweetbriar through real actions (game.act), asserted on the game log and the
## views.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const ThornKit := preload("res://tests/content/thorn/thorn_kit.gd")
const HEAP: StringName = &"thorn_compost"
const DESIGN: String = "res://docs/ideation-track-2/tribes/thorn/units.json"

var game: GameSession
var p: PlayerState


func before_each() -> void:
	game = ThornKit.session()
	p = game.player(0)
	p.gold = 50


func test_the_tribe_loads_clean_with_every_designed_unit_and_the_pip() -> void:
	var content: ContentSet = CoreKit.content(["thorn"], false)
	assert_eq(content.errors, PackedStringArray())
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var designed: Array = design["units"] + design["tokens"]
	assert_eq(designed.size(), 20)
	for raw: Variant in designed:
		var want: Dictionary = raw
		var card: UnitDef = content.library.get_card(StringName(str(want["id"])))
		assert_not_null(card, str(want["id"]))
		if card == null:
			continue
		assert_eq(card.name, str(want["name"]))
		var stats: Array[int] = [int(want["tier"]), int(want["attack"]), int(want["health"])]
		assert_eq([card.tier, card.attack, card.health] as Array[int], stats, str(card.id))
		assert_true(card.has_tribe("Briar"), "%s is a Briar" % card.id)
		var made: Unit = game.new_unit(card, false)
		assert_eq(
			str(made.view()["text"]).replace("\n", " "),
			want["text"],
			"%s text as designed" % card.id
		)
	assert_true(content.library.get_card(&"pip").token, "the Pip is never offered")


## Every unit's golden copy reads as the design's `golden` line says (units.json), and binds the
## numbers that line names; the fight and recruit tests check what the special ones do.
func test_every_golden_reads_and_binds_as_its_golden_line_says() -> void:
	var expected: Dictionary = {
		"pip": ["Seed. It adds 2 copies to your Compost.", {}],
		"bramble-runner": ["Seed. It adds 2 copies to your Compost.", {}],
		"nettle-sprout": ["Thorns 4.", {"thorn_thorns": {"amount": 4}}],
		"hedge-layer": ["Bury: Gain 2 gold.", {"thorn_bury_gold": {"amount": 2}}],
		"sweetbriar":
		[
			"Whenever a unit goes into your Compost, gain +2/+2 permanently.",
			{"thorn_sweetbriar": {"amount": 2}}
		],
		"blackthorn-sapling":
		[
			"Root 1.\nAfter this returns, gain +4/+4 permanently.",
			{"thorn_root": {"cost": 1}, "thorn_sapling": {"amount": 4}}
		],
		"blackberry-sprawl": ["Grow 4.", {"thorn_grow": {"amount": 4}}],
		"nettle-skirmisher":
		["Thorns 8.\nRoot 1.", {"thorn_thorns": {"amount": 8}, "thorn_root": {"cost": 1}}],
		"crab-apple":
		["Seed. It adds 2 copies to your Compost.\nWhen this dies, summon a golden Pip.", {}],
		"old-stump":
		[
			"When this dies, summon copies of the 2 highest-tier units in your Compost.",
			{"thorn_old_stump": {"copies": 2}}
		],
		"ivy-climber": ["The units in front of this have Grow 2.", {"thorn_ivy": {"amount": 2}}],
		"hawthorn-warden": ["Guard.\nRoot 2.", {"thorn_root": {"cost": 2, "charges": 1}}],
		"holly-knight":
		[
			"Your front-row Briars have +2 Thorns for every 3 units in your Compost.",
			{"thorn_holly_knight": {"amount": 2}}
		],
		"leafmould-carter":
		["Bury: Give your Briars +4/+4 permanently.", {"thorn_bury_feed": {"amount": 4}}],
		"lone-hawthorn":
		[
			"Guard.\nThorns 16.\nEnemies your Thorns kill go into your Compost.",
			{"thorn_thorns": {"amount": 16}}
		],
		"hazel-coppicer":
		[
			"After a friendly unit returns, give your units +2/+2 permanently.",
			{"thorn_coppicer": {"amount": 2}}
		],
		"elder-mother":
		[
			(
				"Start of fight: Summon copies of the 4 highest-tier units in your Compost,"
				+ " with +2/+2 for each unit in it."
			),
			{"thorn_elder_mother": {"copies": 4, "per": 2}}
		],
		"briar-king":
		["Your other front-row Briars have Grow 4.", {"thorn_briar_king": {"amount": 4}}],
		"mother-midden":
		[
			"Bury: Give your Briars +4/+4 permanently.\nYour Bury effects happen three times.",
			{"thorn_bury_feed": {"amount": 4}, "thorn_bury_twice": {"times": 3}}
		],
		"the-old-hedge": ["Your other Briars have Root 1.", {}],
	}
	assert_eq(expected.size(), 20, "every unit and the Pip")
	for card_id: String in expected:
		var golden: Unit = CoreKit.unit(game, card_id, true)
		var want: Array = expected[card_id]
		assert_eq(golden.view()["text"], want[0], card_id)
		var params: Dictionary = want[1]
		for mechanic: String in params:
			var found: Dictionary = {}
			for bound: BoundMechanic in golden.hooks():
				if String(bound.id) == mechanic:
					found = bound.params.to_dict()
			assert_eq(found, params[mechanic], "%s %s" % [card_id, mechanic])
	var plain: Unit = CoreKit.unit(game, "mother-midden")
	assert_true(str(plain.view()["text"]).ends_with("happen twice."), "the plain one says twice")


## The card data a hover reads: every glossary term a card's text names has its line in the
## card's `reminders`, each such keyword is a shown display entry, and helpers are hidden.
func test_every_card_carries_a_reminder_for_each_term_its_text_uses() -> void:
	var terms: Dictionary = {
		"Seed": "thorn_seed",
		"Thorns": "thorn_thorns",
		"Root": "thorn_root",
		"Grow": "thorn_grow",
		"Bury": "thorn_bury_gold",
		"Compost": "thorn_compost",
		"Pip": "thorn_pip",
		"Guard": "taunt",
	}
	var table: Dictionary = game.view_for(0)["display"]
	for card_id: StringName in game.library.ids():
		var card: UnitDef = game.library.get_card(card_id)
		if not card.has_tribe("Briar"):
			continue
		var said: String = card.text + " " + card.golden_text
		var titles: Array[String] = []
		for line: String in card.reminders:
			titles.append(line.get_slice(":", 0).get_slice(" ", 0))
		for term: String in terms:
			if not RegEx.create_from_string("\\b%s\\b" % term).search(said):
				continue
			assert_false(bool(table[terms[term]]["hidden"]), "%s is shown" % term)
			if card_id == &"pip" and term == "Pip":
				continue
			assert_has(titles, term, "%s explains %s" % [card_id, term])
	for helper: String in [
		"thorn_bury_twice",
		"thorn_sweetbriar",
		"thorn_sapling",
		"thorn_ivy",
		"thorn_holly_knight",
		"thorn_briar_king",
		"thorn_old_hedge",
		"thorn_lone_hawthorn",
		"thorn_coppicer"
	]:
		assert_true(bool(table[helper]["hidden"]), helper)


func test_every_player_has_a_compost_shown_with_the_glossary_name() -> void:
	for each: PlayerState in game.players:
		assert_true(each.has_standing(&"thorn_compost"), "player %d" % each.id)
	var view: Dictionary = game.view_for(0)
	assert_eq(str(view["display"]["thorn_compost"]["name"]), "Compost")
	assert_eq(
		str(view["display"]["thorn_compost"]["reminder"]),
		"Your heap. Units you bought go here when you sell them."
	)
	for keyword: String in ["thorn_seed", "thorn_thorns", "thorn_root", "thorn_grow"]:
		assert_false(bool(view["display"][keyword]["hidden"]), keyword)
	assert_eq(str(view["display"]["thorn_bury_gold"]["name"]), "Bury")


func test_compost_a_bought_unit_sold_goes_in_and_a_created_one_adds_nothing() -> void:
	ThornKit.shop(game, p, ["bramble-runner", "nettle-sprout"])
	assert_eq(game.act(0, {"type": "buy", "spell": false, "index": 0}), "")
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": 0, "target": -1}), "")
	assert_eq(game.act(0, {"type": "sell", "slot": 0}), "")
	assert_eq(ThornKit.compost_ids(p), ["bramble-runner"] as Array[String])
	var pip: Unit = game.new_unit(game.library.get_card(&"pip"), false)
	p.place(pip, 1)
	var gold: int = p.gold
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq(p.gold, gold, "a token sells for 0")
	assert_eq(p.heap(HEAP).size(), 1, "a Created token adds nothing to Compost")
	assert_eq(p.view()["heaps"]["thorn_compost"].size(), 1, "the view carries the Compost")
	var adds: Array[Dictionary] = CoreKit.log_of(game, "heap_add")
	assert_eq(adds.size(), 1)
	assert_eq(str(adds[0]["heap"]), "thorn_compost")


func test_compost_a_golden_adds_one_entry_for_each_bought_copy() -> void:
	var golden: Unit = CoreKit.put(game, p, "nettle-sprout", 0)
	golden.golden = true
	golden.bought_copies = 3
	assert_eq(game.act(0, {"type": "sell", "slot": 0}), "")
	assert_eq(p.heap(HEAP).size(), 3)


func test_hedge_layer_bury_gains_gold_and_puts_the_shop_unit_in_the_compost() -> void:
	var layer: Unit = CoreKit.put(game, p, "hedge-layer", 0)
	ThornKit.shop(game, p, ["old-stump", "crab-apple"])
	var legal: Array[Dictionary] = game.legal_actions(0)
	assert_true(legal.has(ThornKit.bury(layer, "thorn_bury_gold", 0)), "a bot can Bury")
	var gold: int = p.gold
	assert_eq(game.act(0, ThornKit.bury(layer, "thorn_bury_gold", 0)), "")
	assert_eq(p.gold, gold + 1, "Bury: Gain 1 gold")
	assert_eq(ThornKit.compost_ids(p), ["old-stump"] as Array[String])
	assert_eq(p.shop_units[0], PlayerState.NO_CARD, "it left the shop")
	assert_ne(game.act(0, ThornKit.bury(layer, "thorn_bury_gold", 1)), "", "once a turn")
	var golden: Unit = CoreKit.unit(game, "hedge-layer", true)
	p.place(golden, 1)
	gold = p.gold
	assert_eq(game.act(0, ThornKit.bury(golden, "thorn_bury_gold", 1)), "")
	assert_eq(p.gold, gold + 2, "a golden gains 2")


func test_sweetbriar_grows_whenever_a_unit_goes_into_the_compost() -> void:
	var sweet: Unit = CoreKit.put(game, p, "sweetbriar", 0)
	var layer: Unit = CoreKit.put(game, p, "hedge-layer", 1)
	CoreKit.put(game, p, "bramble-runner", 2)
	ThornKit.shop(game, p, ["old-stump"])
	assert_eq(game.act(0, ThornKit.bury(layer, "thorn_bury_gold", 0)), "")
	assert_eq(game.act(0, {"type": "sell", "slot": 2}), "")
	assert_eq([sweet.attack(), sweet.health()], [5, 9], "a Bury and a sale: +2/+2 for good")
	assert_eq(sweet.stats.perm_attack, 2)


func test_leafmould_carter_bury_gives_every_briar_two_two_for_good() -> void:
	var carter: Unit = CoreKit.put(game, p, "leafmould-carter", 4)
	var sprout: Unit = CoreKit.put(game, p, "nettle-sprout", 0)
	var plain: Unit = CoreKit.put(game, p, "t1_plain", 1)
	ThornKit.shop(game, p, ["old-stump"])
	assert_eq(game.act(0, ThornKit.bury(carter, "thorn_bury_feed", 0)), "")
	assert_eq([carter.stats.perm_attack, carter.stats.perm_health], [2, 2], "this one included")
	assert_eq([sprout.attack(), sprout.health()], [4, 9])
	assert_eq([plain.attack(), plain.health()], [2, 4], "not a Briar")
	assert_eq(p.heap(HEAP).size(), 1)


func test_mother_midden_bury_effects_happen_twice_and_one_unit_is_buried() -> void:
	var midden: Unit = CoreKit.put(game, p, "mother-midden", 4)
	var layer: Unit = CoreKit.put(game, p, "hedge-layer", 5)
	var carter: Unit = CoreKit.put(game, p, "leafmould-carter", 6)
	ThornKit.shop(game, p, ["old-stump", "crab-apple", "ivy-climber"])
	var gold: int = p.gold
	assert_eq(game.act(0, ThornKit.bury(layer, "thorn_bury_gold", 0)), "")
	assert_eq(p.gold, gold + 2, "Hedge Layer gives 2 gold")
	assert_eq(game.act(0, ThornKit.bury(carter, "thorn_bury_feed", 1)), "")
	assert_eq(game.act(0, ThornKit.bury(midden, "thorn_bury_feed", 2)), "")
	assert_eq(p.heap(HEAP).size(), 3, "three Buries, three entries")
	assert_eq(midden.stats.perm_attack, 8, "+4/+4 from the Carter and +4/+4 from itself")
	assert_eq(CoreKit.log_of(game, "shop_take").size(), 3)


func test_two_middens_dont_add_up_and_a_golden_one_makes_it_three_times() -> void:
	CoreKit.put(game, p, "mother-midden", 4)
	CoreKit.put(game, p, "mother-midden", 5)
	var layer: Unit = CoreKit.put(game, p, "hedge-layer", 0)
	ThornKit.shop(game, p, ["old-stump", "crab-apple"])
	var gold: int = p.gold
	assert_eq(game.act(0, ThornKit.bury(layer, "thorn_bury_gold", 0)), "")
	assert_eq(p.gold, gold + 2, "still twice")
	var golden: Unit = CoreKit.unit(game, "mother-midden", true)
	p.place(golden, 6)
	game.recruit.refresh_auras(p)
	layer.turn_counters.clear()
	gold = p.gold
	assert_eq(game.act(0, ThornKit.bury(layer, "thorn_bury_gold", 1)), "")
	assert_eq(p.gold, gold + 3, "a golden Midden: three times")


func test_seed_resolves_in_the_shop_when_eaten_or_drummed() -> void:
	var runner: Unit = CoreKit.put(game, p, "bramble-runner", 0)
	var ctx := RecruitContext.new(game, game.recruit, p)
	ctx.run_death_effects(runner)
	assert_eq(ThornKit.compost_ids(p), ["bramble-runner"] as Array[String])


func test_crab_apple_eaten_in_the_shop_adds_its_entry_and_a_pip_lands() -> void:
	var crab: Unit = CoreKit.put(game, p, "crab-apple", 0)
	var ctx := RecruitContext.new(game, game.recruit, p)
	ctx.run_death_effects(crab)
	assert_eq(ThornKit.compost_ids(p), ["crab-apple"] as Array[String])
	var pips: Array = p.board_units().filter(func(u: Unit) -> bool: return u.def.id == &"pip")
	assert_eq(pips.size(), 1, "the Pip stays like any unit got in the shop")
	assert_false(pips[0].is_bought(), "Created: it sells for 0 and adds nothing")


func test_old_stump_eaten_in_the_shop_does_nothing() -> void:
	ThornKit.fill(game, p, ["t3_hunter"])
	var stump: Unit = CoreKit.put(game, p, "old-stump", 0)
	var ctx := RecruitContext.new(game, game.recruit, p)
	ctx.run_death_effects(stump)
	assert_eq(p.board_units().size(), 1)
	assert_eq(p.heap(HEAP).size(), 1)


func test_auras_show_on_the_recruit_board() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain", "t1_plain", "t1_plain", "t1_plain", "t1_plain"])
	var sprout: Unit = CoreKit.put(game, p, "nettle-sprout", 0)
	CoreKit.put(game, p, "holly-knight", 4)
	CoreKit.put(game, p, "the-old-hedge", 5)
	game.recruit.refresh_auras(p)
	var thorns: int = 0
	for bound: BoundMechanic in sprout.hooks():
		if bound.id == &"thorn_thorns":
			thorns += bound.params.num(&"amount")
	assert_eq(thorns, 4, "printed Thorns 2, and +2 from the Holly Knight at heap 6")
	var roots: Array[int] = []
	for bound: BoundMechanic in sprout.hooks():
		if bound.id == &"thorn_root":
			roots.append(bound.params.num(&"cost"))
	assert_eq(roots, [1] as Array[int], "Root 1 from The Old Hedge, a numbered grant")
