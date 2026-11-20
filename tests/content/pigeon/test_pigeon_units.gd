extends GutTest
## Each Pigeon card's text, proved through the core in a real fight or recruit turn (the event
## log or the player view), plus the tribe's data checks. Design:
## docs/ideation-track-2/tribes/pigeon/units.json.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/pigeon/pigeon_kit.gd")
const DESIGN: String = "res://docs/ideation-track-2/tribes/pigeon/units.json"
const GOLDEN_TEXT: Dictionary = {
	"sentry": "Supply 6: At the end of your turn, give this slot 2 Renown.",
	"territorial": "Reserve.",
	"recruiting-sergeant":
	"Charge 2: After a unit in front of this dies, a Private steps in there.",
	"lance-corporal": "1: Give the slots in front of this 4 Renown.",
	"old-campaigner":
	"At the start of your turn, give this slot 2 Renown, or 4 if this survived last fight.",
	"colour-sergeant":
	"At the end of your turn, if this row is full of Pigeons, give each slot in it 4 Renown.",
	"padre": "Charge 8: After a friendly unit dies, give its slot 2 Renown.",
	"grenadier-guard":
	"0: Make a slot your Guard post.\nAt the end of your turn, give your Guard post 6 Renown.",
	"squadron-leader": "The units in front of this have Sortie and +6 Attack.",
	"home-guard": "Guard.\nReserve.",
	"flying-ace": "Cleave.\nCharge 4: After this kills, give this slot 2 Renown.",
	"lieutenant":
	(
		"Start of fight: If this row is full, each unit in it deals its slot's full Renown"
		+ " as damage to the enemy across from it."
	),
	"bugler": "Charge 4: After a friendly unit dies, a Private steps in there.",
	"quartermaster":
	"Recruit: Give 2 units in your hand Reserve.\nYou can call 2 more reservists each fight.",
	"colour-ensign": "Start of fight: This slot and the slots next to it copy your highest Renown.",
	"wing-commander":
	"Sortie.\nStart of fight: Your Pigeons with Sortie attack immediately, twice.",
	"group-captain": "Your reservists have Sortie and +8 Attack.",
	"regimental-sergeant-major": "At the end of your turn, give every slot 8 Renown.",
	"the-colonel": "Reservists from your hand have triple Renown.",
	"air-marshal": "Charge 6: After a reservist steps in, it attacks immediately."
}

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	game.start_round()
	p = game.player(0)
	q = game.player(1)


# --- Data -------------------------------------------------------------------------------------


func test_pigeon_content_loads_without_errors() -> void:
	var content: ContentSet = Kit.CoreKit.content(["pigeon"], false)
	assert_eq(content.errors, PackedStringArray(), "no loader errors")
	assert_true(content.standing.has(&"pigeon_guard_post"))


func test_every_card_matches_the_design_name_tier_stats_and_text() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var entries: Array = design["units"] + design["tokens"]
	assert_eq(entries.size(), 21, "20 units and the Private")
	for value: Variant in entries:
		var entry: Dictionary = value
		var card: UnitDef = game.library.get_card(StringName(entry["id"]))
		assert_not_null(card, "%s is a card" % entry["id"])
		if card == null:
			continue
		assert_eq(card.name, entry["name"])
		assert_eq(card.tier, int(entry["tier"]))
		assert_eq(card.attack, int(entry["attack"]))
		assert_eq(card.health, int(entry["health"]))
		assert_true(card.has_tribe("Pigeon"))
		var shown: Unit = Kit.CoreKit.unit(game, entry["id"])
		assert_eq(
			str(shown.view()["text"]).replace("\n", " "), entry["text"], "%s text" % entry["id"]
		)


func test_every_shown_display_entry_has_the_glossary_name_and_reminder() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var glossary: Dictionary = design["keywords"]
	var wanted: Dictionary = {
		"taunt": "Guard",
		"cleave": "Cleave",
		"charge": "Charge",
		"supply": "Supply",
		"pigeon_private": "Private",
		"pigeon_guard_post": "Guard post",
		"pigeon_reserve": "Reserve",
		"pigeon_sortie": "Sortie",
		"renown": "Renown"
	}
	for key: String in wanted:
		var entry: Dictionary = game.display[key]
		assert_eq(entry["name"], wanted[key])
		assert_eq(entry["reminder"], glossary[wanted[key]], key)
	assert_eq(game.display["cleave"]["reminder"], glossary["Cleave"])
	assert_eq(game.display["taunt"]["reminder"], glossary["Guard"])
	# an Active is shown by its gold cost alone: its entries and the shared one are hidden
	for key: String in ["pigeon_lance_corporal", "pigeon_grenadier", "active"]:
		assert_true(game.display[key]["hidden"], "%s is hidden" % key)


## What a screen reads: every reminder id on a card is a shown display entry; every glossary term
## the design lists for the card is reachable from it (its reminders, or a shown keyword or
## mechanic of its own); printed keywords are shown entries; helper mechanics are hidden.
func test_every_card_reaches_a_reminder_for_every_term_it_uses() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var shown_keywords: Array = ["pigeon_reserve", "pigeon_sortie", "taunt", "cleave"]
	for value: Variant in design["units"]:
		var entry: Dictionary = value
		var card: UnitDef = game.library.get_card(StringName(entry["id"]))
		var names: Array = []
		for id: String in card.reminders:
			var shown: Dictionary = game.display.get(id, {})
			assert_false(shown.is_empty(), "%s: reminder %s has an entry" % [card.id, id])
			assert_false(shown.get("hidden", true), "%s: reminder %s is shown" % [card.id, id])
			names.append(shown.get("name", ""))
		var own: Array = []
		for spec: MechanicSpec in card.mechanics:
			own.append(spec.id)
		for id: Variant in own:
			var shown: Dictionary = game.display[String(id)]
			assert_eq(
				shown["hidden"], not shown_keywords.has(String(id)), "%s: %s shown?" % [card.id, id]
			)
			if not shown["hidden"]:
				names.append(shown["name"])
		for term: String in entry["keywords"]:
			assert_true(names.has(term), "%s reaches %s" % [card.id, term])


func test_the_private_token_has_its_stats_for_the_screen() -> void:
	var private: UnitDef = game.library.get_card(&"private")
	assert_true(private.token)
	assert_eq([private.attack, private.health], [2, 2])
	assert_eq(game.display["pigeon_private"]["reminder"], "A 2/2 Pigeon reservist.")
	var sergeant: UnitDef = game.library.get_card(&"recruiting-sergeant")
	assert_true(Array(sergeant.reminders).has("pigeon_private"))


func test_private_is_never_offered() -> void:
	assert_eq(game.unit_odds.weight_of(&"private"), 0)
	assert_gt(game.unit_odds.weight_of(&"sentry"), 0)


# --- Golden copies (the design's `golden` line for each unit) ---------------------------------


func test_every_golden_reads_as_the_design_golden_line_with_doubled_stats() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	assert_eq(GOLDEN_TEXT.size(), design["units"].size(), "one line per unit")
	for value: Variant in design["units"]:
		var entry: Dictionary = value
		var golden: Unit = Kit.CoreKit.unit(game, entry["id"], true)
		assert_eq(golden.view()["text"], GOLDEN_TEXT[entry["id"]], entry["id"])
		assert_eq(golden.attack(), 2 * int(entry["attack"]), "%s Attack" % entry["id"])
		assert_eq(golden.health(), 2 * int(entry["health"]), "%s Health" % entry["id"])


func test_golden_squadron_leader_gives_6_attack() -> void:
	Kit.put(game, p, "squadron-leader", 5, -1, -1, true)
	var plain: Unit = Kit.put(game, p, "t1_plain", 1)
	assert_eq(plain.attack(), 2 + 6)
	assert_true(plain.has_mechanic(&"pigeon_sortie"))


func test_territorial_steps_in_from_reserve_where_a_friend_died() -> void:
	Kit.put(game, p, "t1_plain", 1, 1, 1)
	Kit.to_hand(game, p, "territorial")
	Kit.put(game, q, "t1_plain", 0, 10, 100)
	var combat: Combat = Kit.fight(game)
	var start: Dictionary = combat.events[0]
	assert_eq(start["reserve"][0].size(), 1, "in Reserve, off the board")
	assert_eq(start["boards"][0].size(), 1)
	var stepped: Array[Dictionary] = Kit.events(combat, "reserve", 0)
	assert_eq(stepped.size(), 1)
	assert_eq(stepped[0]["id"], "territorial")
	assert_eq(stepped[0]["slot"], 1, "the slot the friend died in")
	assert_eq(p.hand.size(), 1, "the hand is unchanged")


func test_lance_corporal_active_is_not_usable_from_the_front_row() -> void:
	var corporal: Unit = Kit.put(game, p, "lance-corporal", 0)
	p.gold = 3
	var order: Dictionary = {
		"type": "ability", "uid": corporal.uid, "mechanic": "pigeon_lance_corporal", "target": -1
	}
	assert_false(game.legal_actions(0).has(order), "not legal with no slot in front")
	assert_ne(
		game.recruit.ability_error(p, corporal, corporal.mechanics[0]), "", "shown as not usable"
	)
	assert_ne(game.act(0, order), "", "refused")
	assert_eq(p.gold, 3)
	for slot: int in game.geometry.slot_count:
		assert_eq(p.slots[slot].renown, 0)


func test_a_squadron_leader_behind_the_flying_ace_gives_it_sortie() -> void:
	Kit.put(game, p, "flying-ace", 1)
	Kit.put(game, p, "squadron-leader", 5)
	Kit.put(game, q, "t1_guard", 0, 0, 100000)
	Kit.put(game, q, "t1_plain", 4, 0, 3)
	var combat: Combat = Kit.fight(game)
	var swing: Dictionary = Kit.events(combat, "attack", 0)[0]
	assert_eq(swing["slot"], 1)
	assert_eq(swing["target_slot"], 4, "the back row, past a front-row Guard")


func test_sortie_stops_at_a_back_row_guard() -> void:
	var flier: Unit = Kit.put(game, p, "flying-ace", 0, -1, 500)
	flier.grant(game.registry, &"pigeon_sortie")
	Kit.put(game, q, "t1_plain", 0, 0, 500)
	Kit.put(game, q, "t1_plain", 4, 0, 500)
	Kit.put(game, q, "t1_guard", 5, 0, 100000)
	var combat: Combat = Kit.fight(game)
	for swing: Dictionary in Kit.events(combat, "attack", 0):
		assert_eq(swing["target_slot"], 5)


func test_the_unit_on_the_guard_post_has_guard_in_a_fight() -> void:
	var grenadier: Unit = Kit.put(game, p, "grenadier-guard", 0)
	Kit.put(game, p, "t1_plain", 2, 0, 500)
	p.gold = 3
	game.act(
		0, {"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 2}
	)
	grenadier.stats.set_attack = 0
	Kit.put(game, q, "t1_plain", 0, 1, 500)
	var combat: Combat = Kit.fight(game)
	var swings: Array[Dictionary] = Kit.events(combat, "attack", 1)
	assert_gt(swings.size(), 0)
	for swing: Dictionary in swings:
		assert_eq(swing["target_slot"], 2, "enemies must attack the post")


func test_lieutenant_does_nothing_unless_its_row_is_full() -> void:
	p.slots[1].renown = 5
	Kit.put(game, p, "lieutenant", 0)
	Kit.put(game, p, "t1_plain", 1)
	Kit.put(game, q, "t1_plain", 1, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "damage", 1).size(), 0)


func test_squadron_leader_gives_the_units_in_front_sortie_and_3_attack() -> void:
	Kit.put(game, p, "squadron-leader", 5)
	var plain: Unit = Kit.put(game, p, "t1_plain", 1)
	var aside: Unit = Kit.put(game, p, "t1_plain", 3)
	assert_eq(plain.attack(), 2 + 3)
	assert_true(plain.has_mechanic(&"pigeon_sortie"))
	assert_eq(aside.attack(), 2, "not in front of it")
	assert_eq(plain.stats.own_attack(), 2, "borrowed")
	aside.stats.set_attack = 0
	Kit.put(game, q, "t1_guard", 0, 0, 500)
	Kit.put(game, q, "t1_plain", 4, 0, 500)
	var combat: Combat = Kit.fight(game)
	var swing: Dictionary = Kit.events(combat, "attack", 0)[0]
	assert_eq(swing["slot"], 1)
	assert_eq(swing["target_slot"], 4)


func test_wing_commander_sends_every_sortie_pigeon_at_the_back_row_at_start_of_fight() -> void:
	Kit.put(game, p, "wing-commander", 0)
	var flier: Unit = Kit.put(game, p, "sentry", 1)
	flier.grant(game.registry, &"pigeon_sortie")
	Kit.put(game, p, "t1_plain", 2)
	Kit.put(game, q, "t1_guard", 0, 0, 500)
	Kit.put(game, q, "t1_plain", 4, 0, 500)
	game.config.attack_limit = 2
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "pigeon_wing_commander").size(), 1)
	var swings: Array[Dictionary] = Kit.events(combat, "attack", 0)
	assert_eq(swings.size(), 2)
	assert_eq(swings[0]["slot"], 0)
	assert_eq(swings[1]["slot"], 1)
	for swing: Dictionary in swings:
		assert_eq(swing["target_slot"], 4)


func test_golden_wing_commander_makes_them_attack_twice() -> void:
	Kit.put(game, p, "wing-commander", 0, -1, -1, true)
	Kit.put(game, q, "t1_plain", 4, 0, 500)
	game.config.attack_limit = 2
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.CoreKit.attack_slots(combat, 0), [0, 0])


func test_without_the_colonel_a_plain_hand_unit_stays_out() -> void:
	Kit.put(game, p, "t1_plain", 0, 1, 1)
	Kit.to_hand(game, p, "t1_plain")
	Kit.put(game, q, "t1_plain", 0, 50, 5000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "reserve", 0).size(), 0)


func _still() -> Combat:
	Kit.put(game, q, "t1_plain", 0, 0, 1000)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	combat._halt_reason = ""
	game.config.attack_limit = 100
	return combat


func _kill(combat: Combat, slot: int) -> void:
	combat.deal_damage(null, combat.unit_at(0, slot), 1000)
	combat._resolve_deaths(0)


func _uses_left(combat: Combat, key: String) -> Array[int]:
	var left: Array[int] = []
	for event: Dictionary in Kit.events(combat, "uses", 0):
		if event["key"] == key:
			left.append(CoreUtil.to_int(event["left"]))
	return left


func test_sentry_runs_out_even_if_it_changes_slots() -> void:
	var sentry: Unit = Kit.put(game, p, "sentry", 2)
	var ctx: RecruitContext = Kit.ctx(game, p)
	for i: int in 8:
		if i == 2:
			p.remove_from_board(sentry)
			p.place(sentry, 1)
		game.recruit.notify(ctx, &"on_end_of_turn", [])
	assert_eq(sentry.counter(&"supply:pigeon_sentry"), 0)
	assert_eq([p.slots[2].renown, p.slots[1].renown], [2, 4])
	var gains: Array = Kit.CoreKit.log_of(game, "renown")
	assert_eq(gains.size(), 6)
	assert_eq(gains[0]["source_uid"], sentry.uid)


func test_sentry_triple_pools_supply_and_created_golden_starts_full() -> void:
	var deck: Array[Unit] = []
	for left: int in [0, 2, 6]:
		var sentry: Unit = Kit.to_hand(game, p, "sentry")
		sentry.counters["supply:pigeon_sentry"] = left
		deck.append(sentry)
	game.recruit._combine(p, deck)
	var golden: Unit = p.hand[0]
	assert_true(golden.golden)
	assert_eq(golden.counter(&"supply:pigeon_sentry"), 8)
	assert_eq(Kit.CoreKit.unit(game, "sentry", true).counter(&"supply:pigeon_sentry"), 6)


func test_campaigner_rewards_survival_and_death() -> void:
	var unit: Unit = Kit.put(game, p, "old-campaigner", 0)
	game.finish_round()
	assert_true(p.last_fight_report.survived(unit))
	assert_eq(p.slots[0].renown, 0)
	game.start_round()
	assert_eq(p.slots[0].renown, 2)
	Kit.put(game, game.player(game.opponent_of(0)), "t1_plain", 0, 500, 1000)
	game.finish_round()
	assert_false(p.last_fight_report.survived(unit))
	assert_eq(p.slots[0].renown, 2)
	game.start_round()
	assert_eq(p.slots[0].renown, 3)


func test_corporal_pays_one_for_both_front_slots() -> void:
	var corporal: Unit = Kit.put(game, p, "lance-corporal", 4)
	p.gold = 1
	var action: Dictionary = {
		"type": "ability", "uid": corporal.uid, "mechanic": "pigeon_lance_corporal", "target": -1
	}
	assert_eq(game.act(0, action), "")
	assert_eq(p.gold, 0)
	assert_eq([p.slots[0].renown, p.slots[1].renown, p.slots[2].renown], [2, 2, 0])
	assert_ne(game.act(0, action), "")


func test_recruiting_sergeant_only_replaces_a_death_in_front() -> void:
	Kit.put(game, p, "recruiting-sergeant", 4)
	Kit.put(game, p, "sentry", 0)
	Kit.put(game, p, "sentry", 3)
	var combat: Combat = _still()
	assert_null(combat.unit_at(0, 1))
	_kill(combat, 3)
	assert_null(combat.unit_at(0, 3))
	_kill(combat, 0)
	assert_eq(combat.unit_at(0, 0).def.id, &"private")
	_kill(combat, 0)
	assert_null(combat.unit_at(0, 0))
	assert_eq(_uses_left(combat, "pigeon_recruiting_sergeant_uses"), [0])


func test_colour_sergeant_needs_a_whole_row_of_pigeons() -> void:
	Kit.put(game, p, "colour-sergeant", 4)
	Kit.put(game, p, "territorial", 5)
	var outsider: Unit = Kit.put(game, p, "t1_plain", 6)
	var ctx: RecruitContext = Kit.ctx(game, p)
	game.recruit.notify(ctx, &"on_end_of_turn", [])
	assert_eq(p.slots[4].renown, 0)
	p.remove_from_board(outsider)
	Kit.put(game, p, "territorial", 6)
	game.recruit.notify(ctx, &"on_end_of_turn", [])
	for i: int in game.geometry.back:
		assert_eq(p.slots[i].renown, 2)


func test_padre_spends_four_charges_for_next_fight() -> void:
	var padre: Unit = Kit.put(game, p, "padre", 4)
	Kit.put(game, p, "bugler", 5, -1, -1, true)
	Kit.put(game, p, "sentry", 0)
	var combat: Combat = _still()
	var padre_uid: int = combat.unit_at(0, 4).uid
	assert_eq(combat.unit_at(0, 4).def.id, padre.def.id)
	for i: int in 5:
		_kill(combat, 0)
	assert_eq(p.slots[0].renown, 4)
	assert_eq(combat.bridge(0).slot(0).renown, 0)
	var gains: Array = Kit.events(combat, "renown", 0)
	assert_eq(gains.size(), 4)
	assert_eq(gains[0]["source_uid"], padre_uid)


func test_grenadier_marks_a_post_for_free_and_drills_it() -> void:
	var guard: Unit = Kit.put(game, p, "grenadier-guard", 4)
	p.gold = 0
	assert_eq(
		game.act(
			0, {"type": "ability", "uid": guard.uid, "mechanic": "pigeon_grenadier", "target": 1}
		),
		""
	)
	assert_true(p.slots[1].keywords.has(&"taunt"))
	game.end_turn(0)
	assert_eq(p.slots[1].renown, 3)


func test_grenadier_guard_moving_the_post_clears_the_old_one_and_the_renown_stays() -> void:
	var grenadier: Unit = Kit.put(game, p, "grenadier-guard", 0)
	p.gold = 0
	var first: Dictionary = {
		"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 1
	}
	assert_eq(game.act(0, first), "")
	game.end_turn(0)
	game.finish_round()
	game.start_round()
	assert_eq(p.slots[1].renown, 3)
	var order: Dictionary = {
		"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 3
	}
	assert_eq(game.act(0, order), "")
	assert_false(p.slots[1].keywords.has(&"pigeon_guard_post"))
	assert_false(p.slots[1].keywords.has(&"taunt"))
	assert_true(p.slots[3].keywords.has(&"pigeon_guard_post"))
	assert_true(p.slots[3].keywords.has(&"taunt"))
	assert_eq(p.slots[1].renown, 3, "Renown given to the old post stays there")
	game.end_turn(0)
	assert_eq([p.slots[1].renown, p.slots[3].renown], [3, 3])


func test_ace_cleaves_and_stops_after_two_kills() -> void:
	Kit.put(game, p, "flying-ace", 0, -1, 500)
	for i: int in 3:
		Kit.put(game, q, "t1_plain", i, 0, 1)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "attack", 0).size(), 2)
	assert_eq(Kit.events(combat, "death", 1).size(), 3)
	assert_eq(p.slots[0].renown, 2)
	assert_eq(_uses_left(combat, "pigeon_flying_ace_uses"), [1, 0])


func test_golden_ace_doubles_the_reward_and_the_charge() -> void:
	Kit.put(game, p, "flying-ace", 0, -1, 500, true)
	for i: int in 3:
		Kit.put(game, q, "t1_plain", i, 0, 1)
	var combat: Combat = Kit.fight(game)
	assert_eq(p.slots[0].renown, 6, "three kills under Charge 4, 2 Renown each")
	assert_eq(_uses_left(combat, "pigeon_flying_ace_uses"), [3, 2, 1])


func test_bugler_reports_each_charge_spent() -> void:
	Kit.put(game, p, "bugler", 4)
	Kit.put(game, p, "sentry", 1)
	var combat: Combat = _still()
	for i: int in 3:
		_kill(combat, 1)
	assert_eq(_uses_left(combat, "pigeon_bugler_uses"), [1, 0])


func test_golden_bugler_calls_four_normal_privates() -> void:
	Kit.put(game, p, "bugler", 4, -1, -1, true)
	Kit.put(game, p, "sentry", 1)
	var combat: Combat = _still()
	for i: int in 4:
		_kill(combat, 1)
		var private: CombatUnit = combat.unit_at(0, 1)
		assert_eq([private.def.id, private.attack(), private.health()], [&"private", 2, 2])
		assert_true(private.reservist)
	_kill(combat, 1)
	assert_null(combat.unit_at(0, 1))
	assert_eq(_uses_left(combat, "pigeon_bugler_uses"), [3, 2, 1, 0])


func test_quartermaster_grants_reserve_and_stacks_the_limit() -> void:
	Kit.to_hand(game, p, "territorial")
	var first: Unit = Kit.to_hand(game, p, "t1_plain")
	var second: Unit = Kit.to_hand(game, p, "t1_guard")
	Kit.CoreKit.set_shop(game, p, ["quartermaster"])
	p.gold = 10
	assert_eq(game.act(0, {"type": "buy", "index": 0, "target": -1}), "")
	var officer: Unit = p.hand.back()
	assert_true(first.has_mechanic(&"pigeon_reserve"))
	assert_false(second.has_mechanic(&"pigeon_reserve"))
	assert_eq(FightSnapshot.unit(first)["grants"], [["pigeon_reserve"]])
	p.hand.erase(officer)
	p.place(officer, 4)
	Kit.put(game, p, "t1_plain", 0)
	Kit.to_hand(game, p, "home-guard")
	Kit.to_hand(game, p, "territorial")
	var combat: Combat = _still()
	assert_eq(combat.arrivals.limit(0), 3)
	for i: int in 4:
		_kill(combat, 0)
	assert_null(combat.unit_at(0, 0))
	assert_eq(combat.arrivals.called[0], 3)
	Kit.put(game, p, "quartermaster", 5)
	assert_eq(Kit.fight(game).arrivals.limit(0), 4)


func test_ensign_copies_only_fight_slots() -> void:
	Kit.put(game, p, "colour-ensign", 2, -1, -1, true)
	p.slots[0].renown = 7
	var combat: Combat = _still()
	for i: int in [1, 2, 3]:
		assert_eq(combat.bridge(0).slot(i).renown, 7)
		assert_eq(p.slots[i].renown, 0)
	assert_eq(combat.unit_at(0, 2).attack(), 12 + 7)


func test_major_gives_four_to_every_slot() -> void:
	Kit.put(game, p, "regimental-sergeant-major", 5)
	game.end_turn(0)
	for slot: SlotState in p.slots:
		assert_eq(slot.renown, 4)


func test_colonel_and_group_captain_on_home_guard_then_private() -> void:
	Kit.put(game, p, "the-colonel", 4)
	Kit.put(game, p, "group-captain", 5)
	Kit.put(game, p, "bugler", 6)
	Kit.put(game, p, "sentry", 0)
	Kit.to_hand(game, p, "home-guard")
	p.slots[0].renown = 3
	var combat: Combat = _still()
	_kill(combat, 0)
	var guard: CombatUnit = combat.unit_at(0, 0)
	assert_eq(guard.def.id, &"home-guard")
	assert_true(guard.has_mechanic(&"taunt") and guard.has_mechanic(&"pigeon_sortie"))
	assert_eq([guard.attack(), guard.health()], [3 + 6 + 4, 11 + 6])
	_kill(combat, 0)
	var private: CombatUnit = combat.unit_at(0, 0)
	assert_eq(private.def.id, &"private")
	assert_eq([private.attack(), private.health()], [2 + 3 + 4, 2 + 3])
	assert_true(private.has_mechanic(&"pigeon_sortie"))
	_kill(combat, 5)
	assert_eq(private.attack(), 5)
	assert_false(private.has_mechanic(&"pigeon_sortie"))


func test_air_marshal_sends_three_reservists_immediately() -> void:
	Kit.put(game, p, "air-marshal", 4)
	Kit.put(game, p, "bugler", 5, -1, -1, true)
	Kit.put(game, p, "sentry", 0)
	Kit.to_hand(game, p, "territorial")
	var combat: Combat = _still()
	for i: int in 4:
		_kill(combat, 0)
	var swings: Array = Kit.events(combat, "attack", 0)
	var arrivals: Array = Kit.events(combat, "reserve", 0)
	assert_eq(arrivals.size(), 4)
	assert_eq(swings.size(), 3)
	for i: int in 3:
		assert_eq(swings[i]["uid"], arrivals[i]["uid"])
	assert_eq(_uses_left(combat, "pigeon_air_marshal_uses"), [2, 1, 0])


func test_golden_air_marshal_reports_chained_attacks_and_skips_a_refund() -> void:
	Kit.put(game, p, "air-marshal", 4, -1, -1, true)
	Kit.put(game, p, "bugler", 5, -1, -1, true)
	Kit.put(game, p, "bugler", 6, -1, -1, true)
	Kit.put(game, p, "sentry", 0)
	var unarmed: Unit = Kit.to_hand(game, p, "territorial")
	unarmed.stats.set_attack = 0
	Kit.to_hand(game, p, "territorial")
	var combat: Combat = _still()
	combat.unit_at(1, 0).stats.set_attack = 100
	_kill(combat, 0)
	assert_eq(_uses_left(combat, "pigeon_air_marshal_uses"), [])
	_kill(combat, 0)
	assert_eq(_uses_left(combat, "pigeon_air_marshal_uses"), [5, 4, 3, 2])
	_kill(combat, 0)
	assert_eq(Kit.events(combat, "attack", 0).size(), 6)
	assert_eq(_uses_left(combat, "pigeon_air_marshal_uses"), [5, 4, 3, 2, 1, 0])


func test_golden_quartermaster_aims_first_and_grants_two_distinct_units() -> void:
	var first: Unit = Kit.to_hand(game, p, "sentry")
	var skipped: Unit = Kit.to_hand(game, p, "lance-corporal")
	var chosen: Unit = Kit.to_hand(game, p, "padre")
	var quartermaster: Unit = Kit.CoreKit.unit(game, "quartermaster", true)
	game.recruit._gain(p, quartermaster, chosen.uid)
	assert_eq(FightSnapshot.unit(chosen)["grants"], [["pigeon_reserve"]])
	assert_true(first.has_mechanic(&"pigeon_reserve"))
	assert_false(skipped.has_mechanic(&"pigeon_reserve"))
	assert_false(quartermaster.has_mechanic(&"pigeon_reserve"))
	p.hand.erase(quartermaster)
	p.place(quartermaster, 6)
	assert_eq(_still().arrivals.limit(0), 4)


func test_golden_lieutenant_deals_full_renown_before_attacks() -> void:
	Kit.put(game, p, "lieutenant", 4, -1, -1, true)
	Kit.put(game, p, "territorial", 5)
	Kit.put(game, p, "territorial", 6)
	p.slots[5].renown = 5
	p.slots[6].renown = 9
	Kit.put(game, q, "t1_plain", 5, 0, 100)
	var combat: Combat = _still()
	var volley: Array[Dictionary] = Kit.events(combat, "damage", 1)
	assert_eq(volley.size(), 1, "no damage if the opposing slot is empty")
	assert_eq(volley[0]["amount"], 5)
	assert_eq(volley[0]["slot"], 5)


func test_recruiting_sergeant_refills_charge_between_fights() -> void:
	Kit.put(game, p, "recruiting-sergeant", 4, -1, -1, true)
	Kit.put(game, p, "sentry", 0)
	Kit.put(game, q, "t1_plain", 0, 100, 1000)
	for i: int in 2:
		var combat: Combat = Kit.fight(game)
		var privates: Array = Kit.events(combat, "reserve", 0)
		assert_eq(privates.size(), 2)
		assert_false(privates[0]["golden"])
		assert_eq(_uses_left(combat, "pigeon_recruiting_sergeant_uses"), [1, 0])


func test_quartermaster_uses_the_existing_recruit_picker_for_hand_units_only() -> void:
	var guard: Unit = Kit.to_hand(game, p, "home-guard")
	var choice: Unit = Kit.to_hand(game, p, "flying-ace")
	var other: Unit = Kit.to_hand(game, p, "padre")
	var on_board: Unit = Kit.put(game, p, "sentry", 0)
	Kit.CoreKit.set_shop(game, p, ["quartermaster"])
	p.gold = 10
	assert_eq(game.act(0, {"type": "buy", "index": 0}), "")
	assert_false(game.legal_actions(0).has({"type": "recruit_target", "target": guard.uid}))
	assert_true(game.legal_actions(0).has({"type": "recruit_target", "target": other.uid}))
	assert_ne(game.act(0, {"type": "recruit_target", "target": on_board.uid}), "")
	assert_eq(game.act(0, {"type": "recruit_target", "target": choice.uid}), "")
	assert_true(choice.has_mechanic(&"pigeon_reserve"))


func test_quartermaster_never_gives_itself_reserve() -> void:
	Kit.CoreKit.set_shop(game, p, ["quartermaster"])
	p.gold = 10
	assert_eq(game.act(0, {"type": "buy", "index": 0}), "")
	var alone: Unit = p.hand.back()
	assert_true(p.recruit_choices.is_empty())
	assert_false(alone.has_mechanic(&"pigeon_reserve"))
	var other: Unit = Kit.to_hand(game, p, "padre")
	Kit.CoreKit.set_shop(game, p, ["quartermaster"])
	assert_eq(game.act(0, {"type": "buy", "index": 0}), "")
	var officer: Unit = p.hand.back()
	assert_ne(officer, alone)
	assert_true(p.recruit_choices.has(officer), "the earlier Quartermaster and the Padre qualify")
	var targets: Array = game.legal_actions(0).map(func(a: Dictionary) -> int: return a["target"])
	assert_false(targets.has(officer.uid))
	assert_eq(targets, [alone.uid, other.uid])
	assert_ne(game.act(0, {"type": "recruit_target", "target": officer.uid}), "")
	assert_eq(game.act(0, {"type": "recruit_target", "target": other.uid}), "")
	assert_false(officer.has_mechanic(&"pigeon_reserve"))
	assert_true(other.has_mechanic(&"pigeon_reserve"))
