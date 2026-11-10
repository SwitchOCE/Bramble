# gdlint:disable=max-public-methods
extends GutTest
## Native cards, normal/golden, with fixed targets and explicit Health-loss answers.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func _fight(mine: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	return combat


func _start(combat: Combat, source: CombatUnit) -> void:
	for index: int in source.scripts.size():
		source.scripts[index].on_start_of_combat(combat, source, source.params[index])


func test_spider_normal_and_golden_lend_only_behind_and_target_the_back_row() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{1: CK.u("ballooning_spider", -1, -1, golden), 4: "drip", 5: "drip", 6: "drip"},
			{0: "drip", 6: "drip"}
		)
		var source: CombatUnit = combat.unit_at(0, 1)
		assert_eq([source.attack, source.health], [8, 6] if golden else [4, 3])
		for slot: int in [4, 5]:
			var target: CombatUnit = combat.unit_at(0, slot)
			assert_true(target.has_status("lent_swoop"))
			assert_eq(CombatLanes.choose_target(combat, target).slot, 6)
		assert_false(source.has_status("lent_swoop"))
		assert_false(combat.unit_at(0, 6).has_status("lent_swoop"))
		assert_eq(CombatLanes.choose_target(combat, source).slot, 0)


func test_spider_loan_ends_on_death_and_keeps_intrinsic_swoop() -> void:
	var intrinsic: Dictionary = CK.u("drip")
	intrinsic["grants"] = [{"entry": {"id": "swoop"}, "golden": false}]
	var combat: Combat = _fight(
		{1: "ballooning_spider", 4: "drip", 5: intrinsic}, {0: "drip", 6: "drip"}
	)
	combat.unit_at(0, 1).take_damage(1000)
	combat._resolve_deaths(0)
	assert_false(combat.unit_at(0, 4).has_status("lent_swoop"))
	assert_eq(CombatLanes.choose_target(combat, combat.unit_at(0, 4)).slot, 0)
	assert_eq(CombatLanes.choose_target(combat, combat.unit_at(0, 5)).slot, 6)


func test_spider_aura_tracks_summon_swallow_and_return() -> void:
	var combat: Combat = _fight({1: "ballooning_spider"}, {0: "drip"})
	var source: CombatUnit = combat.unit_at(0, 1)
	var child: CombatUnit = combat.summon_into("drip", false, 0, 4, source)
	assert_true(child.has_status("lent_swoop"))
	var holder: CombatUnit = combat.unit_at(1, 0)
	CombatHeld.swallow(combat, holder, source)
	assert_false(child.has_status("lent_swoop"))
	CombatHeld.return_inside(combat, holder)
	assert_true(child.has_status("lent_swoop"))


func test_spider_text_theft_moves_aura_but_cannot_steal_a_borrowed_loan() -> void:
	var combat: Combat = _fight(
		{1: "ballooning_spider", 4: "drip"}, {1: "drip", 4: "drip", 6: "drip"}
	)
	CombatHeld.steal_text(combat, combat.unit_at(1, 6), combat.unit_at(0, 4))
	assert_false(combat.unit_at(1, 6).has_status("lent_swoop"))
	CombatHeld.steal_text(combat, combat.unit_at(1, 1), combat.unit_at(0, 1))
	assert_false(combat.unit_at(0, 4).has_status("lent_swoop"))
	assert_true(combat.unit_at(1, 4).has_status("lent_swoop"))


func test_lent_swoop_respects_quarry_and_has_no_backrow_holder_targets() -> void:
	var combat: Combat = _fight(
		{1: "ballooning_spider", 4: "drip", 6: "ballooning_spider"}, {0: "drip", 6: "drip"}
	)
	var target: CombatUnit = combat.unit_at(0, 4)
	target.quarry = combat.unit_at(1, 0).uid
	target.quarry_reach = true
	assert_eq(CombatLanes.choose_target(combat, target).slot, 0)
	assert_false(combat.unit_at(0, 1).has_status("lent_swoop"))


func test_shieldbug_normal_and_golden_shield_only_behind_and_keep_shield_after_death() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{1: CK.u("shieldbug", -1, -1, golden), 4: "drip", 5: "drip", 6: "drip"}, {}
		)
		var source: CombatUnit = combat.unit_at(0, 1)
		assert_eq([source.attack, source.health], [4, 10] if golden else [2, 5])
		_start(combat, source)
		assert_true(combat.unit_at(0, 4).has_status("shield"))
		assert_true(combat.unit_at(0, 5).has_status("shield"))
		assert_false(combat.unit_at(0, 6).has_status("shield"))
		assert_false(source.has_status("shield"))
		source.take_damage(1000)
		combat._resolve_deaths(0)
		assert_true(combat.unit_at(0, 4).has_status("shield"))


func test_backrow_shieldbug_has_no_targets_and_granted_shield_stops_one_hit() -> void:
	var empty: Combat = _fight({4: "shieldbug", 5: "drip"}, {})
	_start(empty, empty.unit_at(0, 4))
	assert_false(empty.unit_at(0, 5).has_status("shield"))
	var combat: Combat = _fight({0: "shieldbug", 4: CK.u("drip", 1, 10)}, {0: "drip"})
	_start(combat, combat.unit_at(0, 0))
	var target: CombatUnit = combat.unit_at(0, 4)
	combat._apply_hits([Hit.make(combat.unit_at(1, 0), target, 3, Hit.EFFECT)])
	assert_eq(target.health, 10)
	assert_false(target.has_status("shield"))
	combat._apply_hits([Hit.make(combat.unit_at(1, 0), target, 3, Hit.EFFECT)])
	assert_eq(target.health, 7)


func test_whirligig_normal_and_golden_lose_current_health_without_damage_or_shield_use() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: CK.u("whirligig_beetle", -1, -1, golden)},
			{0: CK.u("drip", 1, 101), 4: CK.u("drip", 1, 99), 3: CK.u("drip", 1, 77)}
		)
		var source: CombatUnit = combat.unit_at(0, 0)
		assert_eq([source.attack, source.health], [12, 16] if golden else [6, 8])
		var front: CombatUnit = combat.unit_at(1, 0)
		var back: CombatUnit = combat.unit_at(1, 4)
		front.take_damage(1)
		front.damaged = false
		combat.set_status(front, "shield", true, source)
		_start(combat, source)
		assert_eq([front.slot, back.slot], [4, 0])
		assert_eq([front.health, back.health], [80, 80] if golden else [90, 90])
		assert_eq(combat.unit_at(1, 3).health, 77, "F4 never moves or pays Health")
		assert_true(front.has_status("shield"))
		assert_true(front.is_undamaged())
		assert_eq(CK.of_type({"events": combat.events}, "health_loss").size(), 2)
		assert_true(CK.of_type({"events": combat.events}, "damage").is_empty())


func test_whirligig_dials_are_independent_and_floor_small_health_without_killing() -> void:
	kit.config.set_value("neutrals_whirligig_health_share", 0.25)
	kit.config.set_value("neutrals_golden_whirligig_health_share", 0.4)
	kit.setup(kit.config)
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: CK.u("whirligig_beetle", -1, -1, golden)},
			{0: CK.u("drip", 1, 11), 1: CK.u("drip", 1, 1)}
		)
		_start(combat, combat.unit_at(0, 0))
		assert_eq(combat.unit_at(1, 4).health, 7 if golden else 9)
		assert_eq(combat.unit_at(1, 5).health, 1)


func test_every_neutral_native_ability_is_audited_and_unknown_variants_fail_closed() -> void:
	var source: UnitLibrary = kit.library
	var input: Dictionary = {"config": kit.config._values.duplicate(true), "boards": [[], []]}
	var prepared: Dictionary = UpsetCombat.prepare(input, source)
	assert_true(prepared["supported"])
	var intact: UnitLibrary = prepared["intact_library"]
	var masked: UnitLibrary = prepared["library"]
	var observed: Dictionary = {}
	for card: Dictionary in intact.all_units():
		for entry: Dictionary in card.get("mechanics", []):
			if str(entry.get("id", "")) != "pass3_neutral":
				continue
			var ability: String = str(entry["ability"])
			observed[ability] = true
			assert_false(UpsetCombat.AUDITED_NEUTRALS[ability])
			assert_true(masked.get_unit(str(card["id"]))["mechanics"].has(entry))
	assert_eq(observed.size(), 5)
	for ability: String in ["", "future_biggest_enemy"]:
		assert_false(UpsetCombat._audited_native({"id": "pass3_neutral", "ability": ability}))
