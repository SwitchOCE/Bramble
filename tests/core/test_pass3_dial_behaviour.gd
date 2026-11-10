# gdlint:disable=max-public-methods
extends GutTest

const ORIGINAL_B := preload("res://tests/core/pass3_original_b.gd")
## Endpoint answers are deliberately literal, independent of the rate reads in each rule.
## Each example checks the configured face and runs the recruit/combat effect it describes.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
const WORDS := preload("res://tests/core/test_pass3_path.gd")
const ENDPOINTS: Array[float] = [0.0, 3.0]
const OOZE_ENDPOINTS: Array[float] = [0.0, 1.0]
const FLIERS: Array[String] = ["one_swallow", "chiffchaff", "mrs_jay", "old_tern", "mother_goose"]
const SOAKERS: Array[String] = [
	"bridge_toad",
	"gideon",
	"prima_donna",
	"prince_restored",
	"peat_king",
	"jenny_greenteeth",
	"lantern_man",
]
var kit: KIT


func _setup(t: float) -> void:
	var config := GameConfig.full_game()
	var rates: Dictionary = ORIGINAL_B.path(t)
	for key: String in rates:
		config.set_value(key, rates[key])
	kit = KIT.new()
	kit.setup(config)
	kit.player.round_number = 5
	kit.player.gold = 100


func _face(id: String, golden: bool, pattern: String, expected: float, field: String = "") -> void:
	var card: Dictionary = kit.library.get_unit(id)
	if card.is_empty():
		card = kit.library.get_card(id)
	if field == "":
		field = "golden_text" if golden else "text"
	var text: String = str(card.get(field, ""))
	var found: RegExMatch = RegEx.create_from_string(pattern).search(text)
	var label: String = "%s %s: %s" % [id, field, text]
	assert_not_null(found, label)
	if found == null:
		return
	for index: int in range(found.get_group_count(), 0, -1):
		if found.get_string(index) != "":
			assert_almost_eq(WORDS.amount(found.get_string(index)), expected, 1e-6, label)
			return
	assert_almost_eq(WORDS.amount(""), expected, 1e-6, label)


func _fight(mine: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	Pass3BogCombat.prepare(combat)
	combat._start_of_combat()
	return combat


func _spec(id: String, golden: bool, slot: int = 0) -> Dictionary:
	var spec: Dictionary = CK.u(id, 1, 100, golden)
	spec["iid"] = 100 + slot
	return spec


func _body(unit: RecruitUnit, attack: int, health: int) -> void:
	unit.add_permanent(attack - unit.base_attack_now(), health - unit.base_health_now())


func _kill(combat: Combat, side: int, slot: int) -> void:
	combat.deal_effect_damage(null, combat.unit_at(side, slot), 10000)
	combat._resolve_deaths(side)


func _changes(combat: Combat, operation: String) -> Array:
	return combat.carry.filter(
		func(change: Dictionary) -> bool: return str(change["op"]) == operation
	)


func test_every_flying_face_matches_actual_normal_and_golden_homecoming_at_both_endpoints() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			for id: String in FLIERS:
				_setup(t)
				var multiplier: float = (7.0 if golden else 4.0) if t == 3.0 else 2.0
				_face(
					id,
					golden,
					"at ([\\d.]+)× permanent",
					multiplier,
					"golden_details" if golden else "details"
				)
				var bird: RecruitUnit = kit.put(id, 0, golden)
				_body(bird, 20, 40)
				Pass3Birds.homecoming(kit.rules, kit.player, bird)
				assert_eq(
					Pass3Oozes.own_stats(bird),
					Vector2i(20, 40) * int(multiplier),
					"%s golden=%s t=%s" % [id, golden, t]
				)


func test_chiffchaff_printed_play_gain_is_what_the_play_action_applies() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var gain: int = (64 if t == 3.0 else 1) * (2 if golden else 1)
			_face("chiffchaff", golden, "gain \\+(\\d+)/", gain)
			var bird: RecruitUnit = kit.play("chiffchaff", 0, golden)
			assert_eq(Vector2i(bird.perm_attack, bird.perm_health), Vector2i(gain, gain))


func test_golden_egg_face_matches_the_cast_on_normal_and_golden_birds() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var multiplier: int = 7 if t == 3.0 else 2
			_face(
				"golden_egg",
				false,
				"^(?:(Double|Triple)|Multiply) a Bird's stats(?: by ([\\d.]+))?",
				multiplier
			)
			var bird: RecruitUnit = kit.put("mrs_jay", 0, golden)
			_body(bird, 20, 40)
			assert_eq(kit.cast("golden_egg", 0), "")
			assert_eq(Pass3Oozes.own_stats(bird), Vector2i(20, 40) * multiplier)


func test_redbreast_and_cuckoo_printed_shares_match_home_event_rewards() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			for id: String in ["mr_redbreast", "cuckoo"]:
				_setup(t)
				var share: float
				if id == "mr_redbreast":
					share = 0.3 if t == 3.0 else 0.125
				else:
					share = 0.35 if t == 3.0 else 0.1
				share *= 2.0 if golden else 1.0
				_face(id, golden, "gain (.*?) ?(?:of )?its stats\\.", share)
				var source: RecruitUnit = kit.put(id, 6, golden)
				var other: RecruitUnit = kit.put("mrs_jay", 4)
				var landed: RecruitUnit = kit.put("one_swallow")
				_body(landed, 400, 800)
				kit.rules.events.fire(kit.player, "on_home", {"subject": landed})
				var expected := Vector2i(roundi(400 * share), roundi(800 * share))
				assert_eq(Vector2i(source.perm_attack, source.perm_health), expected)
				assert_eq(
					Vector2i(other.perm_attack, other.perm_health),
					expected if id == "cuckoo" else Vector2i.ZERO
				)


func test_stork_printed_gold_threshold_recalls_one_or_two_birds() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var step: int = 4 if t == 3.0 else 6
			_face("mrs_stork", golden, "^Every (\\d+) gold", step)
			kit.put("mrs_stork", 6, golden)
			for slot: int in [0, 1]:
				var bird: RecruitUnit = kit.put("mrs_jay", slot)
				bird.played_round = 0
				assert_eq(kit.rules.sell(kit.player, slot), "")
			Pass3Birds.missed_fight(kit.player)
			kit.rules.spend(kit.player, step - 1)
			assert_eq(kit.player.away.size(), 2, "no recall before the printed threshold")
			kit.rules.spend(kit.player, 1)
			assert_eq(kit.player.away.size(), 0 if golden else 1)
			assert_eq(kit.player.hand.size(), 2 if golden else 1)


func test_cluricaun_printed_growth_matches_end_of_turn_ring_growth() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var growth: int = (16 if t == 3.0 else 2) * (2 if golden else 1)
			_face("cluricaun", golden, "grow \\+(\\d+)/", growth)
			kit.put("cluricaun", 0, golden)
			for slot: int in BoardGeometry.SLOTS:
				Pass3Fairies.add_ring(kit.player, slot, {"count": 1})
			var before: float = kit.player.ring_size
			kit.rules.end_phase(kit.player)
			assert_eq(kit.player.ring_size - before, float(growth))


func test_lob_printed_growth_matches_one_completed_stay_when_thanked() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var growth: int = (27 if t == 3.0 else 1) * (2 if golden else 1)
			_face("lob_lie_by_the_fire", golden, "grow \\+(\\d+)/", growth)
			var lob: RecruitUnit = kit.put("lob_lie_by_the_fire", 0, golden)
			lob.counters["pass3_turns_stayed"] = 2
			var before: float = kit.player.ring_size
			assert_eq(kit.cast("pinch_of_dust", 0), "")
			assert_eq(kit.player.ring_size - before, float(growth))


func test_silky_printed_growth_matches_a_real_shy_departure() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var growth: int = (8 if t == 3.0 else 1) * (2 if golden else 1)
			_face("silky", golden, "grow \\+(\\d+)/", growth)
			kit.put("silky", 0, golden)
			kit.put("hob_in_the_hearth", 1)
			var before: float = kit.player.ring_size
			assert_eq(kit.cast("pinch_of_dust", 1), "")
			assert_eq(kit.player.ring_size - before, float(growth))


func test_monarch_printed_pin_is_the_multiplier_applied_at_midsummer() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var multiplier: int = 4 if golden else 3
			_face(
				"fairy_monarch",
				golden,
				"(double|triple|multiply) your Ring size(?: by ([\\d.]+))?",
				multiplier
			)
			kit.put("fairy_monarch", 0, golden)
			kit.player.owner_counters["pass3_midsummer"] = 1
			var before: float = kit.player.ring_size
			kit.rules.end_phase(kit.player)
			assert_eq(kit.player.ring_size, before * multiplier)


func test_all_native_soak_faces_match_the_pending_bitter_reward() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			for id: String in SOAKERS:
				_setup(t)
				var keep: int = (7 if t == 3.0 else 2) * (2 if golden else 1)
				_face(
					id,
					golden,
					"Soak keeps \\+(\\d+)/",
					keep,
					"golden_details" if golden else "details"
				)
				var combat: Combat = _fight({0: _spec(id, golden)}, {0: CK.plain(9, 100)})
				var soaker: CombatUnit = combat.unit_at(0, 0)
				CombatLanes.bitter(combat, soaker, combat.unit_at(1, 0))
				assert_eq(combat.unit_at(1, 0).attack, 6, id)
				assert_eq(
					Vector2i(soaker.pending_attack, soaker.pending_health),
					Vector2i(3, 3) * keep,
					"%s golden=%s t=%s" % [id, golden, t]
				)


func test_chorus_printed_soak_is_what_its_neighbour_keeps() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var keep: int = (7 if t == 3.0 else 2) * (2 if golden else 1)
			_face(
				"natterjack_chorus",
				golden,
				"Soak keeps \\+(\\d+)/",
				keep,
				"golden_details" if golden else "details"
			)
			var combat: Combat = _fight(
				{0: _spec("warty_nan", false), 1: _spec("natterjack_chorus", golden, 1)},
				{0: CK.plain(9, 100)}
			)
			var neighbour: CombatUnit = combat.unit_at(0, 0)
			CombatLanes.bitter(combat, neighbour, combat.unit_at(1, 0))
			assert_eq(
				Vector2i(neighbour.pending_attack, neighbour.pending_health), Vector2i(3, 3) * keep
			)


func test_tiddy_printed_share_matches_the_start_of_turn_split() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var share: float = (1.0 if t == 3.0 else 0.5) * (2.0 if golden else 1.0)
			_face("tiddy_mun", golden, "split ?(.*?) ?(?:of )?the Toll\\.", share)
			var toad: RecruitUnit = kit.put("bridge_toad", 4)
			kit.put("tiddy_mun", 5, golden)
			kit.player.bog_toll = 120
			kit.rules.events.fire(kit.player, "start_of_turn")
			assert_eq(
				Vector2i(toad.perm_attack, toad.perm_health),
				Vector2i(roundi(120 * share), roundi(120 * share))
			)


func test_each_printed_take_or_observer_share_matches_a_real_quarry_death() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			for id: String in ["little_nip", "sable", "old_lutra", "lodger", "mountain_glutton"]:
				_setup(t)
				var observer: bool = id in ["lodger", "mountain_glutton"]
				var slot: int = 1 if observer else 0
				var share: float = 2.0 / 3.0
				if t == 3.0:
					share = 2.25 if observer else 1.0
				share *= 2.0 if golden else 1.0
				var prefix: String = "Take: " if id == "sable" else ""
				_face(id, golden, prefix + "gain ?(.*?) ?(?:of )?the quarry's stats", share)
				var mine: Dictionary = {slot: _spec(id, golden, slot)}
				if observer:
					mine[0] = _spec("little_nip", false)
				var combat: Combat = _fight(mine, {0: CK.plain(120, 240)})
				var hunter: CombatUnit = combat.unit_at(0, slot)
				_kill(combat, 1, 0)
				assert_eq(
					Vector2i(hunter.pending_attack, hunter.pending_health),
					Vector2i(roundi(120 * share), roundi(240 * share)),
					"%s golden=%s t=%s" % [id, golden, t]
				)


func test_wick_and_grizel_printed_shares_match_pack_kill_rewards() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			for id: String in ["wick", "grizel"]:
				_setup(t)
				var share: float = (1.0 if t == 3.0 else 1.0 / 3.0) * (2.0 if golden else 1.0)
				_face(id, golden, "gain ?(.*?) ?(?:of )?the target's stats", share)
				var combat: Combat = _fight(
					{0: _spec("little_nip", false), 1: _spec(id, golden, 1)},
					{0: CK.plain(120, 240)}
				)
				var leader: CombatUnit = combat.unit_at(0, 0)
				var source: CombatUnit = combat.unit_at(0, 1)
				var prey: CombatUnit = combat.unit_at(1, 0)
				prey.counters["hunter_attack_lethal"] = 1
				combat.reactions.pack_joiners = [source]
				Pass3HunterGains.pack_kill(combat, [leader, source], prey)
				var rewarded: CombatUnit = source if id == "wick" else leader
				assert_eq(
					Vector2i(rewarded.pending_attack, rewarded.pending_health),
					Vector2i(roundi(120 * share), roundi(240 * share))
				)


func test_russet_printed_buff_share_matches_the_poached_copy_payload() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var share: float = 1.0 if golden or t == 3.0 else 2.0 / 3.0
			_face("mistress_russet", golden, "with ?(.*?) ?(?:of )?its buffs", share)
			var combat: Combat = _fight(
				{0: _spec("mistress_russet", golden)}, {0: CK.u("young_brock", 122, 243)}
			)
			_kill(combat, 1, 0)
			var copies: Array = _changes(combat, "poach")
			assert_eq(copies.size(), 1)
			if copies.size() != 1:
				continue
			assert_eq(
				Vector2i(copies[0]["perm_attack"], copies[0]["perm_health"]),
				Vector2i(roundi(120 * share), roundi(240 * share))
			)


func test_ermeline_printed_count_and_pelt_share_match_award_and_spell_effect() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var count: int = (10 if golden else 8) if t == 3.0 else (2 if golden else 1)
			var share: float = 1.0 if t == 3.0 else 1.0 / 3.0
			_face("madame_ermeline", golden, "get (\\w+) Pelts? of", count)
			var card: Dictionary = kit.library.get_unit("madame_ermeline")
			var reminder: String = str(card["keyword_text_overrides"]["Pelt"])
			var found: RegExMatch = (
				RegEx.create_from_string("Hunter ?(.*?) ?(?:of )?the prey's stats").search(reminder)
			)
			assert_not_null(found)
			assert_almost_eq(WORDS.amount(found.get_string(1)), share, 1e-6)
			var combat: Combat = _fight(
				{0: _spec("little_nip", false), 4: _spec("madame_ermeline", golden, 4)},
				{0: CK.plain(120, 240)}
			)
			Pass3HunterGains.finish(combat)
			var awards: Array = _changes(combat, "add_card")
			assert_eq(awards.size(), 1)
			assert_eq(awards[0]["count"], count)
			var stats := Vector2i(roundi(120 * share), roundi(240 * share))
			assert_eq(Vector2i(awards[0]["attack"], awards[0]["health"]), stats)
			var hunter: RecruitUnit = kit.put("little_nip", 0, golden)
			kit.rules.apply_carry(kit.player, awards[0])
			kit.rules.start_phase(kit.player, 6)
			assert_eq(kit.player.items.size(), count)
			assert_eq(kit.rules.play_item(kit.player, 0, 0), "")
			assert_eq(Vector2i(hunter.perm_attack, hunter.perm_health), stats)


func test_soup_printed_share_matches_live_shop_stats_normal_and_golden() -> void:
	for t: float in OOZE_ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var share: float = 0.9 if t == 1.0 else 0.3
			_face("stone_soup", golden, "gain ?(.*?) ?(?:of )?your (?:\\w+ )?biggest", share)
			var card: Dictionary = kit.library.get_unit("stone_soup")
			assert_true(str(card["golden_text" if golden else "text"]).ends_with(", rounded up."))
			kit.put("stone_soup", 4, golden)
			_body(kit.put("little_dollop", 0), 101, 201)
			_body(kit.put("bubble_and_squeak", 1), 51, 101)
			_body(kit.put("little_dollop", 2), 9, 19)
			_body(kit.put("little_dollop", 3), 7, 17)
			_body(kit.put("little_dollop", 5), 5, 15)
			var offer: RecruitUnit = kit.shop("field_vole")
			kit.rules.board_changed(kit.player)
			var expected: Vector2i
			if t == 1.0:
				expected = Vector2i(160, 324) if golden else Vector2i(91, 181)
			else:
				expected = Vector2i(46, 91) if golden else Vector2i(31, 61)
			assert_eq(Vector2i(offer.attack, offer.health) - Pass3Oozes.own_stats(offer), expected)
			assert_eq(kit.rules.buy(kit.player, 0), "")
			assert_eq(Vector2i(offer.perm_attack, offer.perm_health), expected)


func test_elder_printed_share_matches_redistribution_of_original_meal_stats() -> void:
	for t: float in OOZE_ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var share: float = 2.0 if golden else 1.0
			_face("elder_ooze", golden, "Oozes gain ?(.*?) ?(?:of )?its stats", share)
			var eater: RecruitUnit = kit.put("little_dollop", 0)
			_body(eater, 500, 600)
			var elder: RecruitUnit = kit.put("elder_ooze", 4, golden)
			var meal: RecruitUnit = kit.put("field_vole")
			kit.player.hand.erase(meal)
			_body(meal, 80, 120)
			Pass3Oozes.eat(kit.rules, kit.player, eater, meal)
			assert_eq(
				Vector2i(elder.perm_attack, elder.perm_health),
				Vector2i(roundi(80 * share), roundi(120 * share))
			)


func test_hasty_printed_share_matches_each_swallowed_enemy_including_golden() -> void:
	for t: float in OOZE_ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var share: float = 1.0
			_face("hasty_pudding", golden, "gains (.*?) of (?:it|each)\\.", share)
			var carry_spec: Dictionary = CK.u("little_dollop", 600, 800)
			carry_spec["iid"] = 104
			var combat: Combat = _fight(
				{0: _spec("hasty_pudding", golden), 4: carry_spec},
				{
					0: CK.plain(120, 240),
					1: CK.plain(100, 200),
					2: CK.plain(80, 160),
					3: CK.plain(60, 120),
					4: CK.plain(40, 80),
					5: CK.plain(20, 40),
					6: CK.plain(1, 1),
				}
			)
			var hasty: CombatUnit = combat.unit_at(0, 0)
			var count: int = (3 if t == 1.0 else 1) * (2 if golden else 1)
			assert_eq(hasty.inside.size(), count)
			var gains: Array = _changes(combat, "buff")
			assert_eq(gains.size(), count)
			var expected_gains: Array[Vector2i] = [
				Vector2i(120, 240),
				Vector2i(100, 200),
				Vector2i(80, 160),
				Vector2i(60, 120),
				Vector2i(40, 80),
				Vector2i(20, 40),
			]
			var total := Vector2i.ZERO
			for index: int in count:
				assert_eq(
					Vector2i(gains[index]["attack"], gains[index]["health"]), expected_gains[index]
				)
				total += expected_gains[index]
			var carry: CombatUnit = combat.unit_at(0, 4)
			assert_eq(Vector2i(carry.attack, carry.health), Vector2i(600, 800) + total)


func test_aspic_printed_bonus_matches_eating_with_the_current_printed_multiplier() -> void:
	for t: float in OOZE_ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			if golden:
				_face(
					"aunt_aspic",
					true,
					"gain (double|[\\w.]+ times as many) stats",
					11.8 if t == 1.0 else 4.6
				)
			else:
				_face("aunt_aspic", false, "gain ([\\d.]+%) more", 5.4 if t == 1.0 else 1.8)
			var eater: RecruitUnit = kit.put("little_dollop", 1)
			kit.put("aunt_aspic", 4, golden)
			kit.card("dial_meal", [], [], 20, 40)
			var meal: RecruitUnit = kit.put("dial_meal")
			kit.player.hand.erase(meal)
			meal.add_permanent(4, 8)
			Pass3Oozes.eat(kit.rules, kit.player, eater, meal)
			var expected: Vector2i
			if t == 1.0:
				expected = Vector2i(5003, 10006) if golden else Vector2i(2713, 5427)
			else:
				expected = Vector2i(662, 1324) if golden else Vector2i(403, 806)
			assert_eq(Vector2i(eater.perm_attack, eater.perm_health), expected)


func test_eat_reminder_matches_non_ooze_printed_stats_and_preserves_ooze_meals() -> void:
	for t: float in OOZE_ENDPOINTS:
		for golden: bool in [false, true]:
			for golden_meal: bool in [false, true]:
				_setup(t)
				var eater: RecruitUnit = kit.put("little_dollop", 0, golden)
				var reminder: String = ""
				for entry: Dictionary in eater.view()["keyword_text"]:
					if str(entry["keyword"]) == "Eat":
						reminder = str(entry["text"])
				assert_string_contains(
					reminder, "printed stats × 21" if t == 1.0 else "printed stats × 7"
				)
				var meal: RecruitUnit = kit.put("field_vole", -1, golden_meal)
				kit.player.hand.erase(meal)
				meal.add_permanent(5, 6)
				Pass3Oozes.eat(kit.rules, kit.player, eater, meal)
				var expected: Vector2i
				if t == 1.0:
					expected = Vector2i(89, 132) if golden_meal else Vector2i(47, 69)
				else:
					expected = Vector2i(33, 48) if golden_meal else Vector2i(19, 27)
				assert_eq(Vector2i(eater.perm_attack, eater.perm_health), expected)
				var ooze: RecruitUnit = kit.put("little_dollop", -1, golden_meal)
				kit.player.hand.erase(ooze)
				ooze.add_permanent(3, 4)
				Pass3Oozes.eat(kit.rules, kit.player, eater, ooze)
				var whole := Vector2i(5, 8) if golden_meal else Vector2i(4, 6)
				assert_eq(Vector2i(eater.perm_attack, eater.perm_health), expected + whole)
