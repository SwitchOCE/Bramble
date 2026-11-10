extends GutTest
@warning_ignore_start("unsafe_call_argument")
## Fixed authored faces and explicit B/C values pin the provisional Hedgerow contract.

const FACES: Dictionary = {
	"mrs_burdock":
	[
		"When played: summon a 1/1 Kit behind this. Spill.",
		"When played: summon two 1/1 Kits behind this. Spill."
	],
	"mr_crumb":
	[
		"When played: Pass +1/+1. When sold: Pass its stats.",
		"When played: Pass +2/+2. When sold: Pass twice its stats."
	],
	"sleeping_partner":
	[
		"Every 3 turns in this slot: get two Acorns per Hedgerow unit touching this.",
		"Every 3 turns in this slot: get four Acorns per Hedgerow unit touching this."
	],
	"mrs_clover":
	[
		"After you summon a Hedgerow unit: give it all this unit's stats.",
		"After you summon a Hedgerow unit: give it twice this unit's stats."
	],
	"mr_pym": ["After you get a Stash: Pass +3/+3.", "After you get a Stash: Pass +6/+6."],
	"mrs_sorrel":
	[
		"After this attacks: summon a 1/1 Shrewlet behind this. Spill.",
		"After this attacks: summon two 1/1 Shrewlets behind this. Spill."
	],
	"mrs_mallow":
	[
		"End of Turn: triple your two smallest other Hedgerow units' stats.",
		"End of Turn: triple your four smallest other Hedgerow units' stats."
	],
	"dr_urchin":
	[
		"Bristle 2. Your last other Hedgerow unit has Hunker.",
		"Bristle 4. Your last two other Hedgerow units have Hunker."
	],
	"sergeant_at_conkers":
	[
		(
			"Start of Combat: throw your smallest Larder item across. That enemy loses "
			+ "a tenth of its stats per gold."
		),
		(
			"Start of Combat: throw your two smallest Larder items across. That enemy "
			+ "loses a tenth of its stats per gold."
		)
	],
	"alderman_dozey":
	[
		"Larder items played on this: +2/+2 per gold. Every 3 turns in this slot: triple its stats.",
		"Larder items played on this: +4/+4 per gold. Every 3 turns in this slot: triple its stats."
	],
	"beadle_warrenby":
	["After you get an Acorn: Pass +2/+2.", "After you get an Acorn: Pass +4/+4."],
	"honorary_treasurer":
	[
		"End of Turn: gain +2/+2 per gold in your Larder.",
		"End of Turn: gain +4/+4 per gold in your Larder."
	],
	"goodman_hayward":
	[
		"After you play a Larder item: your Hedgerow folk have +1/+1 per gold this game.",
		"After you play a Larder item: your Hedgerow folk have +2/+2 per gold this game."
	],
	"standing_committee":
	[
		"End of Turn: Hedgerow folk touching this gain a quarter of the smallest one's stats.",
		"End of Turn: Hedgerow folk touching this gain half the smallest one's stats."
	],
	"squire_lollop":
	[
		"Start of Turn: Hedgerow folk touching this, except your biggest, gain a tenth of its stats.",
		"Start of Turn: Hedgerow folk touching this, except your biggest, gain a fifth of its stats."
	],
	"old_mother_mast":
	[
		"Start of Turn: get an Acorn per 5 gold in your Larder. Up to 5.",
		"Start of Turn: get two Acorns per 5 gold in your Larder. Up to 10."
	]
}
const B_RATES: Dictionary = {
	"hedgerow_dozey_wake_multiplier": 3.0,
	"hedgerow_golden_dozey_wake_multiplier": 3.0,
	"hedgerow_dozey_period": 3,
	"hedgerow_dozey_food_per_gold": 2.0,
	"hedgerow_partner_period": 3,
	"hedgerow_partner_acorns": 2,
	"hedgerow_crumb_pass": 1,
	"hedgerow_crumb_sell_share": 1.0,
	"hedgerow_clover_share": 1.0,
	"hedgerow_pym_pass": 3,
	"hedgerow_sorrel_summons": 1,
	"hedgerow_burdock_kits": 1,
	"hedgerow_mallow_multiplier": 3.0,
	"hedgerow_mallow_targets": 2,
	"hedgerow_urchin_bristle": 2,
	"hedgerow_urchin_hunker_targets": 1,
	"hedgerow_sergeant_share_per_gold": 0.1,
	"hedgerow_sergeant_throws": 1,
	"hedgerow_beadle_pass": 2,
	"hedgerow_treasurer_per_gold": 2.0,
	"hedgerow_hayward_per_gold": 1.0,
	"hedgerow_committee_share": 0.25,
	"hedgerow_lollop_share": 0.1,
	"hedgerow_mast_gold_step": 5,
	"hedgerow_mast_cap": 5,
	"hedgerow_larder_gold": [1, 5, 16]
}
const C_CHANGES: Dictionary = {
	"hedgerow_dozey_wake_multiplier": 4.0,
	"hedgerow_golden_dozey_wake_multiplier": 4.0,
	"hedgerow_mallow_multiplier": 4.0,
	"hedgerow_treasurer_per_gold": 3.0
}
var config: GameConfig


func before_each() -> void:
	config = GameConfig.defaults()


func _raw(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://content/units/" + id + ".json"))


func _configured(id: String) -> Dictionary:
	var card: Dictionary = _raw(id)
	Pass3HedgerowText.configure(card, config)
	return card


func test_fixed_authored_normal_and_golden_faces_and_native_factors() -> void:
	var counts: Array[int] = [0, 0, 0, 0, 0, 0]
	for id: String in FACES:
		var card: Dictionary = _raw(id)
		counts[CoreUtil.to_int(card["tier"]) - 1] += 1
		var markers: int = 0
		for entry: Dictionary in card["mechanics"]:
			if str(entry["id"]) == "pass3_hedgerow":
				markers += 1
				assert_eq(entry["ability"], id)
				assert_eq(CoreUtil.to_int(entry["factor"]), 1)
		assert_eq(markers, 1, id)
		for golden: bool in [false, true]:
			var field: String = "golden_text" if golden else "text"
			var expected: String = str(FACES[id][1 if golden else 0])
			assert_eq(card[field], expected, id + " authored " + field)
			card[field] = "Stale words must never influence generation."
			assert_eq(Pass3Text.face(card, config, golden), expected, id + " generated " + field)
	assert_eq(counts, [3, 3, 3, 3, 2, 2])


func test_all_hedgerow_rates_are_registered_and_match_exact_paper_b_and_c() -> void:
	for preset: String in ["B", "C"]:
		config.set_value("pass3_preset", preset)
		var expected: Dictionary = B_RATES.duplicate(true)
		if preset == "C":
			expected.merge(C_CHANGES, true)
		for key: String in expected:
			assert_true(config._values.has(key), key + " nullable sweep dial")
			assert_null(config.get_value(key))
			assert_eq(
				FightCapture.canonical(Pass3Rates.value(config, key)),
				FightCapture.canonical(expected[key]),
				preset + " " + key
			)


func test_golden_dozey_wake_is_independent_from_food_and_normal_wake() -> void:
	config.set_value("hedgerow_dozey_wake_multiplier", 3.0)
	config.set_value("hedgerow_golden_dozey_wake_multiplier", 2.0)
	var card: Dictionary = _configured("alderman_dozey")
	assert_string_contains(card["text"], "triple its stats")
	assert_string_contains(card["golden_text"], "double its stats")
	assert_string_contains(card["text"], "+2/+2 per gold")
	assert_string_contains(card["golden_text"], "+4/+4 per gold")
	config.set_value("hedgerow_golden_dozey_wake_multiplier", 3.0)
	config.set_value("hedgerow_dozey_food_per_gold", 0.5)
	card = _configured("alderman_dozey")
	assert_string_contains(card["text"], "+0.5/+0.5 per gold")
	assert_string_contains(card["golden_text"], "+1/+1 per gold")
	assert_string_contains(card["golden_text"], "triple its stats")
	assert_string_contains(card["details"], "Feeding rounds up")


func test_rate_overrides_rewrite_faces_and_native_parameters() -> void:
	for sample: Array in [
		["hedgerow_clover_share", 0.5, "mrs_clover", "half this unit's stats", "share"],
		[
			"hedgerow_mallow_targets",
			1,
			"mrs_mallow",
			"your smallest other Hedgerow unit's",
			"targets"
		],
		["hedgerow_committee_share", 0.2, "standing_committee", "a fifth", "share"],
		["hedgerow_beadle_pass", 3, "beadle_warrenby", "+3/+3", "pass"],
		[
			"hedgerow_sergeant_share_per_gold",
			0.25,
			"sergeant_at_conkers",
			"a quarter",
			"share_per_gold"
		],
		["hedgerow_partner_period", 4, "sleeping_partner", "Every 4 turns", "period"],
		["hedgerow_mast_cap", 7, "old_mother_mast", "Up to 7", "limit"],
	]:
		config = GameConfig.defaults()
		config.set_value(str(sample[0]), sample[1])
		var card: Dictionary = _configured(str(sample[2]))
		assert_string_contains(card["text"], str(sample[3]))
		for entry: Dictionary in card["mechanics"]:
			if str(entry["id"]) == "pass3_hedgerow":
				assert_eq(entry[str(sample[4])], sample[1])


func test_reused_summon_effects_keep_tokens_normal_and_follow_count_dials() -> void:
	for sample: Array in [
		["mrs_burdock", "hedgerow_burdock_kits", "Kit"],
		["mrs_sorrel", "hedgerow_sorrel_summons", "Shrewlet"]
	]:
		config.set_value(str(sample[1]), 3)
		var card: Dictionary = _configured(str(sample[0]))
		var effect: Dictionary = card["mechanics"][0]["do"]
		assert_eq(CoreUtil.to_int(effect["copies"]), 3)
		assert_false(effect["golden"], "golden parents still summon 1/1 tokens")
		assert_string_contains(card["text"], "three 1/1 " + str(sample[2]))
		assert_string_contains(card["golden_text"], "six 1/1 " + str(sample[2]))


func test_c_wakes_and_mallow_targets_and_rate_overlay_remain_distinct() -> void:
	config.set_value("pass3_preset", "C")
	var dozey: Dictionary = _configured("alderman_dozey")
	assert_string_contains(dozey["text"], "multiply its stats by 4")
	assert_string_contains(dozey["golden_text"], "multiply its stats by 4")
	var mallow: Dictionary = _configured("mrs_mallow")
	assert_string_contains(mallow["text"], "multiply your two smallest")
	assert_string_contains(mallow["golden_text"], "multiply your four smallest")
	config.set_value("card_rate_limits", false)
	var mast: Dictionary = _configured("old_mother_mast")
	assert_false(str(mast["text"]).contains("Up to"))
	assert_eq(CoreUtil.to_int(mast["mechanics"][0]["limit"]), BoardUnit.STAT_CLAMP)


func test_legacy_definitions_are_not_configured_without_a_native_marker() -> void:
	var old: Dictionary = _raw("mrs_burdock")
	var old_mechanics: Array = old["mechanics"]
	old_mechanics.pop_back()
	old["text"] = "Legacy face."
	config.set_value("hedgerow_burdock_kits", 3)
	Pass3HedgerowText.configure(old, config)
	assert_eq(old["text"], "Legacy face.")
	assert_eq(CoreUtil.to_int(old["mechanics"][0]["do"]["copies"]), 1)


func test_larder_value_override_changes_actual_items_gold_and_reminders() -> void:
	config.set_value("pass3_content", true)
	config.set_value("hedgerow_larder_gold", [2, 7, 23])
	var ids: Array[String] = ["acorn", "stash", "great_hoard"]
	var expected: Array[int] = [2, 7, 23]
	for index: int in ids.size():
		var card: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://content/spells/" + ids[index] + ".json")
		)
		Pass3Text.configure(card, config)
		var item: HandItem = HandItem.make(card, index + 1)
		assert_eq(item.gold_value(), expected[index], "actual held Larder value")
		assert_eq(CoreUtil.to_int(card["do"]["amount"]), expected[index], "gold paid on play")
		assert_string_contains(card["text"], "Play for %d gold." % expected[index])
		assert_string_contains(
			card["keyword_text_overrides"]["Acorn"], "Acorn 2, Stash 7, Great Hoard 23"
		)
	config.set_value("pass3_content", false)
	var legacy: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/spells/great_hoard.json")
	)
	Pass3Text.configure(legacy, config)
	assert_eq(CoreUtil.to_int(legacy["gold_value"]), 16, "disabled pass 3 preserves legacy gold")
	assert_eq(CoreUtil.to_int(legacy["do"]["amount"]), 16)


func test_archived_rates_without_larder_dial_leave_the_old_items_untouched() -> void:
	var frozen := preload("res://tests/core/field_frozen_content.gd").new()
	frozen.setup("res://tests/fixtures/field/content-0946909.json")
	var acorn: Dictionary = frozen.library.get_card("acorn").duplicate(true)
	var original: Dictionary = acorn.duplicate(true)
	assert_false(Pass3HedgerowText.configure_larder_item(acorn, GameConfig.full_game()))
	assert_eq(acorn, original)
	frozen.restore()
