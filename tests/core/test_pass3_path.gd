# gdlint:disable=max-public-methods
extends GutTest
## A3.5's dial paths: B at t = 0, C at t = 1, snapped, clamped, golden kept above normal, and
## every card face on a path prints the number its rule reads at t = 0 to 3.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
## All four Hedgerow dials are required after the wave 2b merge.
const REQUIRED_HEDGEROW: PackedStringArray = [
	"hedgerow_mallow_multiplier",
	"hedgerow_dozey_wake_multiplier",
	"hedgerow_golden_dozey_wake_multiplier",
	"hedgerow_treasurer_per_gold",
]
## Build 8 B, measured on the original cca9242f paths; C remains authored.
const MEASURED_B: Dictionary = {
	"birds_chiffchaff_gain": 3,
	"birds_cuckoo_share": 0.14285714285714285,
	"birds_golden_egg_multiplier": 3.0,
	"birds_golden_homecoming_multiplier": 3.0,
	"birds_homecoming_multiplier": 2.5,
	"birds_redbreast_share": 0.16666666666666666,
	"birds_stork_gold_step": 6,
	"bog_golden_soak_keep": 6,
	"bog_golden_tiddy_share": 1.5,
	"bog_soak_keep": 3,
	"bog_tiddy_share": 0.75,
	"fairies_golden_monarch_multiplier": 4.0,
	"fairies_lob_growth": 6,
	"fairies_monarch_multiplier": 3.0,
	"fairies_ring_growth": 6,
	"fairies_silky_growth": 3,
	"hedgerow_dozey_wake_multiplier": 3.0,
	"hedgerow_golden_dozey_wake_multiplier": 3.0,
	"hedgerow_mallow_multiplier": 3.0,
	"hedgerow_treasurer_per_gold": 2.0,
	"hunters_ermeline_pelts": 3,
	"hunters_glutton_share": 1.125,
	"hunters_golden_ermeline_pelts": 6,
	"hunters_grizel_share": 0.5833333333333334,
	"hunters_lodger_share": 1.125,
	"hunters_lutra_share": 0.8333333333333334,
	"hunters_nip_share": 0.8333333333333334,
	"hunters_pelt_share": 0.5833333333333334,
	"hunters_russet_buff_share": 0.8333333333333334,
	"hunters_sable_share": 0.8333333333333334,
	"hunters_wick_share": 0.5833333333333334
}
const STEPS: Array[float] = [0.0, 0.25, 0.5, 1.0, 1.5, 1.71, 2.0, 2.5, 3.0]
## [rate key, card, field, regex, golden factor key or number]. The regex's last non-empty
## group is the printed amount; the face must equal the rate (times the factor).
const FACES: Array = [
	["birds_homecoming_multiplier", "chiffchaff", "details", "at ([\\d.]+)× permanent", 1],
	[
		"birds_golden_homecoming_multiplier",
		"chiffchaff",
		"golden_details",
		"at ([\\d.]+)× permanent",
		1
	],
	["birds_chiffchaff_gain", "chiffchaff", "text", "gain \\+(\\d+)/", 1],
	["birds_chiffchaff_gain", "chiffchaff", "golden_text", "gain \\+(\\d+)/", 2],
	[
		"birds_golden_egg_multiplier",
		"golden_egg",
		"text",
		"^(?:(Double|Triple)|Multiply) a Bird's stats(?: by (\\d+(?:\\.\\d+)?))?",
		1
	],
	["birds_redbreast_share", "mr_redbreast", "text", "gain (.*?) ?(?:of )?its stats\\.", 1],
	["birds_redbreast_share", "mr_redbreast", "golden_text", "gain (.*?) ?(?:of )?its stats\\.", 2],
	["birds_cuckoo_share", "cuckoo", "text", "Birds gain (.*?) ?(?:of )?its stats\\.", 1],
	["birds_cuckoo_share", "cuckoo", "golden_text", "Birds gain (.*?) ?(?:of )?its stats\\.", 2],
	["birds_stork_gold_step", "mrs_stork", "text", "^Every (\\d+) gold", 1],
	["fairies_ring_growth", "cluricaun", "text", "grow \\+(\\d+)/", 1],
	["fairies_ring_growth", "cluricaun", "golden_text", "grow \\+(\\d+)/", 2],
	["fairies_lob_growth", "lob_lie_by_the_fire", "text", "grow \\+(\\d+)/", 1],
	["fairies_lob_growth", "lob_lie_by_the_fire", "golden_text", "grow \\+(\\d+)/", 2],
	["fairies_silky_growth", "silky", "text", "grow \\+(\\d+)/", 1],
	["fairies_silky_growth", "silky", "golden_text", "grow \\+(\\d+)/", 2],
	[
		"fairies_monarch_multiplier",
		"fairy_monarch",
		"text",
		"(double|triple|multiply) your Ring size(?: by (\\d+(?:\\.\\d+)?))?",
		1
	],
	[
		"fairies_golden_monarch_multiplier",
		"fairy_monarch",
		"golden_text",
		"(double|triple|multiply) your Ring size(?: by (\\d+(?:\\.\\d+)?))?",
		1
	],
	["bog_soak_keep", "bridge_toad", "details", "Soak keeps \\+(\\d+)/", 1],
	["bog_golden_soak_keep", "bridge_toad", "golden_details", "Soak keeps \\+(\\d+)/", 1],
	["bog_tiddy_share", "tiddy_mun", "text", "split ?(.*?) ?(?:of )?the Toll\\.", 1],
	["bog_golden_tiddy_share", "tiddy_mun", "golden_text", "split ?(.*?) ?(?:of )?the Toll\\.", 1],
	["hunters_nip_share", "little_nip", "text", "gain ?(.*?) ?(?:of )?the quarry's", 1],
	[
		"hunters_nip_share",
		"little_nip",
		"golden_text",
		"gain ?(.*?) ?(?:of )?the quarry's",
		"hunters_golden_take_multiplier"
	],
	["hunters_sable_share", "sable", "text", "Take: gain ?(.*?) ?(?:of )?the quarry's", 1],
	["hunters_lutra_share", "old_lutra", "text", "gain ?(.*?) ?(?:of )?the quarry's", 1],
	["hunters_glutton_share", "mountain_glutton", "text", "gain ?(.*?) ?(?:of )?the quarry's", 1],
	[
		"hunters_glutton_share",
		"mountain_glutton",
		"golden_text",
		"gain ?(.*?) ?(?:of )?the quarry's",
		"hunters_golden_take_multiplier"
	],
	["hunters_lodger_share", "lodger", "text", "gain ?(.*?) ?(?:of )?the quarry's", 1],
	[
		"hunters_lodger_share",
		"lodger",
		"golden_text",
		"gain ?(.*?) ?(?:of )?the quarry's",
		"hunters_golden_take_multiplier"
	],
	["hunters_wick_share", "wick", "text", "gain ?(.*?) ?(?:of )?the target's", 1],
	["hunters_grizel_share", "grizel", "text", "gain ?(.*?) ?(?:of )?the target's", 1],
	["hunters_pelt_share", "madame_ermeline", "pelt", "Hunter ?(.*?) ?(?:of )?the prey's", 1],
	["hunters_russet_buff_share", "mistress_russet", "text", "with ?(.*?) ?(?:of )?its buffs", 1],
	[
		"hunters_golden_russet_buff_share",
		"mistress_russet",
		"golden_text",
		"with ?(.*?) ?(?:of )?its buffs",
		1
	],
	["hunters_ermeline_pelts", "madame_ermeline", "text", "get (\\w+) Pelts? of", 1],
	["hunters_golden_ermeline_pelts", "madame_ermeline", "golden_text", "get (\\w+) Pelts? of", 1],
	["oozes_soup_share", "stone_soup", "text", "gain ?(.*?) ?(?:of )?your biggest", 1],
	["oozes_elder_share", "elder_ooze", "text", "Oozes gain ?(.*?) ?(?:of )?its stats", 1],
	[
		"oozes_elder_share",
		"elder_ooze",
		"golden_text",
		"Oozes gain ?(.*?) ?(?:of )?its stats",
		"oozes_golden_elder_multiplier"
	],
	["oozes_hasty_share", "hasty_pudding", "text", "gains (.*?) of (?:it|each)\\.", 1],
	["oozes_hasty_share", "hasty_pudding", "golden_text", "gains (.*?) of each\\.", 1],
	["oozes_aspic_bonus", "aunt_aspic", "text", "gain ([\\d.]+%) more", 1],
	[
		"oozes_golden_aspic_multiplier",
		"aunt_aspic",
		"golden_text",
		"gain (double|[\\w.]+ times as many) stats",
		1
	],
	[
		"oozes_eat_printed_multiplier",
		"aunt_aspic",
		"eat",
		"printed stats (doubled|tripled|× \\d+)",
		1
	],
	[
		"hedgerow_mallow_multiplier",
		"mrs_mallow",
		"text",
		"(double|triple|multiply) your .* stats(?: by ([\\d.]+))?\\.",
		1
	],
	[
		"hedgerow_mallow_multiplier",
		"mrs_mallow",
		"golden_text",
		"(double|triple|multiply) your .* stats(?: by ([\\d.]+))?\\.",
		1
	],
	[
		"hedgerow_dozey_wake_multiplier",
		"alderman_dozey",
		"text",
		"(double|triple|multiply) its stats(?: by ([\\d.]+))?\\.",
		1
	],
	[
		"hedgerow_golden_dozey_wake_multiplier",
		"alderman_dozey",
		"golden_text",
		"(double|triple|multiply) its stats(?: by ([\\d.]+))?\\.",
		1
	],
	["hedgerow_treasurer_per_gold", "honorary_treasurer", "text", "gain \\+([\\d.]+)/", 1],
	["hedgerow_treasurer_per_gold", "honorary_treasurer", "golden_text", "gain \\+([\\d.]+)/", 2],
]
const NUMBERS: Dictionary = {
	"a": 1,
	"an": 1,
	"one": 1,
	"two": 2,
	"three": 3,
	"four": 4,
	"five": 5,
	"six": 6,
	"seven": 7,
	"eight": 8,
	"nine": 9,
	"ten": 10,
	"eleven": 11,
	"twelve": 12,
}
const DENOMINATORS: Dictionary = {
	"half": 2,
	"halves": 2,
	"third": 3,
	"thirds": 3,
	"quarter": 4,
	"quarters": 4,
	"fifth": 5,
	"fifths": 5,
	"sixth": 6,
	"sixths": 6,
	"seventh": 7,
	"sevenths": 7,
	"eighth": 8,
	"eighths": 8,
	"ninth": 9,
	"ninths": 9,
	"tenth": 10,
	"tenths": 10,
	"twelfth": 12,
	"twelfths": 12,
	"sixteenth": 16,
	"sixteenths": 16,
	"twentieth": 20,
	"twentieths": 20,
}
var kit: KIT


func _config(t: Variant) -> GameConfig:
	var config := GameConfig.full_game()
	var values: Dictionary = Pass3Path.override(t)
	for key: String in values:
		config.set_value(key, values[key])
	return config


func _kit(t: Variant) -> KIT:
	kit = KIT.new()
	kit.setup(_config(t))
	kit.player.round_number = 5
	kit.player.gold = 100
	return kit


func test_t0_is_preset_b_and_t1_is_preset_c() -> void:
	for pair: Array in [[0.0, "B"], [1.0, "C"]]:
		var preset: Dictionary = Pass3Path.preset_rates(str(pair[1]))
		var path: Dictionary = Pass3Path.override(pair[0])
		for key: String in path:
			assert_almost_eq(
				CoreUtil.to_float(path[key]), CoreUtil.to_float(preset[key]), 1e-9, key
			)
	for preset_name: String in ["B", "C"]:
		var preset: Dictionary = Pass3Path.preset_rates(preset_name)
		assert_eq(preset["fairies_monarch_multiplier"], 3.0, preset_name)
		assert_eq(preset["fairies_golden_monarch_multiplier"], 4.0, preset_name)


func test_every_dial_that_differs_between_b_and_c_is_on_a_path_or_named_off_it() -> void:
	var b: Dictionary = Pass3Path.preset_rates("B")
	var c: Dictionary = Pass3Path.preset_rates("C")
	var on_path: PackedStringArray = Pass3Path.keys()
	var described: PackedStringArray = []
	for dial: Dictionary in Pass3Path.DIALS:
		var key: String = str(dial["key"])
		described.append(key)
		assert_true(Pass3Rates.keys().has(key), key + " must have an authored rate")
		assert_true(on_path.has(key), key + " must be emitted")
	for key: String in REQUIRED_HEDGEROW:
		assert_true(described.has(key), key + " is required")
		assert_true(b.has(key) and c.has(key), key + " must exist in both presets")
	for key: String in c:
		if b.get(key) == c[key]:
			continue
		# C-only optional Bird dials hold the cards' authored 1, so B already plays them at 1.
		if not b.has(key) and key in ["birds_goose_eggs", "birds_swallow_gold", "birds_jay_acorns"]:
			assert_eq(c[key], 1.0, key)
			continue
		assert_true(on_path.has(key) or Pass3Path.OFF_PATH.has(key), key + " moves but has no path")


func test_measured_b_values_are_pinned_and_oozes_keep_their_promoted_b() -> void:
	var b: Dictionary = Pass3Rates._presets["B"]
	for key: String in MEASURED_B:
		assert_almost_eq(CoreUtil.to_float(b[key]), CoreUtil.to_float(MEASURED_B[key]), 1e-9, key)
	assert_eq(b["oozes_eat_printed_multiplier"], 7.0)
	assert_eq(Pass3Rates.defaults()["oozes_eat_printed_multiplier"], 1.0, "A keeps old eating")


func test_limits_snaps_and_golden_relations_hold_along_every_path() -> void:
	for t: float in STEPS:
		var path: Dictionary = Pass3Path.override(t)
		var at: String = " at t=%s" % t
		for key: String in [
			"birds_redbreast_share",
			"birds_cuckoo_share",
			"hunters_nip_share",
			"hunters_wick_share",
			"hunters_russet_buff_share",
			"oozes_soup_share",
			"oozes_elder_share",
			"oozes_hasty_share",
			"oozes_slice_share",
			"oozes_posset_loss_share",
			"bog_tiddy_share",
		]:
			assert_lte(CoreUtil.to_float(path[key]), 1.0, key + at)
		assert_lt(CoreUtil.to_float(path["birds_redbreast_share"]) * 2.0, 1.0, "golden Robin" + at)
		assert_lt(CoreUtil.to_float(path["birds_cuckoo_share"]) * 2.0, 1.0, "golden Cuckoo" + at)
		assert_gte(path["birds_stork_gold_step"], 1)
		assert_lte(path["oozes_moss_golden_reduction"], 100)
		for key: String in [
			"oozes_eat_printed_multiplier",
			"oozes_nell_meals",
			"oozes_bubble_belly",
			"oozes_dollop_belly",
			"oozes_dollop_discount",
			"oozes_slice_count",
			"oozes_hasty_swallows",
			"oozes_hasty_release_deaths",
			"oozes_golden_soup_reads",
			"oozes_bubble_splits",
			"oozes_pie_gold",
			"oozes_wobbly_drip",
			"oozes_frumenty_meals",
			"oozes_syllabub_fires",
		]:
			assert_gte(path[key], 1, key + at)
			assert_true(path[key] is int, "whole: " + key + at)
		assert_true(path["bog_soak_keep"] is int, "whole" + at)
		assert_eq(path["bog_golden_soak_keep"], 2 * path["bog_soak_keep"], at)
		assert_almost_eq(
			CoreUtil.to_float(path["bog_golden_tiddy_share"]),
			minf(2.0, 2.0 * CoreUtil.to_float(path["bog_tiddy_share"])),
			1e-9,
			at
		)
		assert_eq(
			path["hunters_golden_ermeline_pelts"], mini(10, 2 * path["hunters_ermeline_pelts"]), at
		)
		assert_almost_eq(
			CoreUtil.to_float(path["oozes_golden_aspic_multiplier"]),
			1.0 + 2.0 * CoreUtil.to_float(path["oozes_aspic_bonus"]),
			1e-9,
			at
		)
		for key: String in REQUIRED_HEDGEROW:
			var dial_value: float = CoreUtil.to_float(path[key])
			assert_gt(dial_value, 0.0 if key == "hedgerow_treasurer_per_gold" else 1.0, key + at)
			assert_eq(dial_value * 2.0, roundf(dial_value * 2.0), "half steps: " + key + at)
		for pair: Array in [
			["birds_homecoming_multiplier", "birds_golden_homecoming_multiplier"],
			["bog_soak_keep", "bog_golden_soak_keep"],
			["bog_tiddy_share", "bog_golden_tiddy_share"],
			["hunters_ermeline_pelts", "hunters_golden_ermeline_pelts"],
			["hunters_russet_buff_share", "hunters_golden_russet_buff_share"],
			["fairies_monarch_multiplier", "fairies_golden_monarch_multiplier"],
			["hedgerow_dozey_wake_multiplier", "hedgerow_golden_dozey_wake_multiplier"],
		]:
			var config: GameConfig = _config(t)
			assert_gte(
				Pass3Rates.number(config, str(pair[1])),
				Pass3Rates.number(config, str(pair[0])),
				"golden stays above normal: %s%s" % [pair[1], at]
			)
		var aspic: float = CoreUtil.to_float(path["oozes_aspic_bonus"])
		assert_gt(CoreUtil.to_float(path["oozes_golden_aspic_multiplier"]) - 1.0, aspic, at)


func test_snaps_round_up_toward_generous_on_the_rebased_paths() -> void:
	assert_eq(Pass3Path.snap(27.0 / 32.0, "frac_hunt"), 0.875, "Nip 7/8")
	assert_eq(Pass3Path.snap(2.0 / 9.0, "frac_text"), 2.0 / 9.0, "Soup 2/9")
	assert_eq(Pass3Path.snap(0.2963, "frac_text"), 0.3, "Soup 3/10")
	assert_eq(Pass3Path.snap(4.5, "int"), 5.0)
	assert_eq(Pass3Path.snap(4.0, "int"), 4.0)
	assert_almost_eq(Pass3Path.snap(4.0 / 3.0, "pct5"), 1.35, 1e-9)
	var t2: Dictionary = Pass3Path.override(2.0)
	var t3: Dictionary = Pass3Path.override(3.0)
	assert_eq([t2["hunters_ermeline_pelts"], t3["hunters_ermeline_pelts"]], [2, 1])
	assert_eq(t3["hunters_golden_ermeline_pelts"], 2)
	assert_eq([t2["hunters_glutton_share"], t3["hunters_glutton_share"]], [11.0 / 12.0, 5.0 / 6.0])
	assert_eq([t2["hunters_nip_share"], t3["hunters_nip_share"]], [0.75, 0.625])
	assert_eq([t2["bog_tiddy_share"], t2["bog_golden_tiddy_share"]], [0.75, 1.5])


func test_promoted_ooze_path_preserves_b_and_uses_clamped_arm_c() -> void:
	# Explicit authored endpoints catch missing dials as well as accidental preset changes.
	var endpoints: Dictionary = {
		"oozes_soup_share": [0.3, 0.9],
		"oozes_elder_share": [1.0, 1.0],
		"oozes_hasty_share": [1.0, 1.0],
		"oozes_aspic_bonus": [1.8, 5.4],
		"oozes_golden_aspic_multiplier": [4.6, 11.8],
		"oozes_eat_printed_multiplier": [7, 21],
		"oozes_nell_meals": [1, 3],
		"oozes_bubble_belly": [1, 3],
		"oozes_dollop_belly": [1, 3],
		"oozes_dollop_discount": [1, 3],
		"oozes_slice_share": [0.2, 0.6],
		"oozes_slice_count": [1, 3],
		"oozes_hasty_swallows": [1, 3],
		"oozes_hasty_release_deaths": [3, 1],
		"oozes_golden_soup_reads": [2, 6],
		"oozes_granny_attack_multiplier": [1.0, 3.0],
		"oozes_posset_loss_share": [0.5, 1.0],
		"oozes_moss_golden_reduction": [25, 75],
		"oozes_bubble_splits": [1, 3],
		"oozes_pie_gold": [1, 3],
		"oozes_wobbly_drip": [1, 3],
		"oozes_frumenty_meals": [1, 3],
		"oozes_syllabub_fires": [1, 3],
	}
	for t: float in [0.0, 1.0]:
		var path: Dictionary = Pass3Path.override(t)
		for key: String in endpoints:
			assert_true(path.has(key), key + " must be on the Ooze path")
			assert_almost_eq(
				CoreUtil.to_float(path.get(key, NAN)),
				CoreUtil.to_float(endpoints[key][int(t)]),
				1e-9,
				"%s at t=%s" % [key, t]
			)
		assert_eq(Pass3Rates.number(_config(t), "oozes_golden_elder_multiplier"), 2.0)
	for t: float in STEPS:
		var path: Dictionary = Pass3Path.override(t)
		for key: String in endpoints:
			var value: float = CoreUtil.to_float(path.get(key, NAN))
			var b: float = CoreUtil.to_float(endpoints[key][0])
			var c: float = CoreUtil.to_float(endpoints[key][1])
			var at: String = "%s at t=%s" % [key, t]
			if b == c:
				assert_eq(value, b, at)
			elif c > b:
				assert_gte(value, b, at)
				if t >= 1.0:
					assert_gte(value, c, at)
			else:
				assert_lte(value, b, at)
				assert_gte(value, c, at)
	var cap: Dictionary = Pass3Path.override(3.0)
	for key: String in ["oozes_soup_share", "oozes_slice_share", "oozes_posset_loss_share"]:
		assert_eq(CoreUtil.to_float(cap[key]), 1.0, key + " respects its share limit")
	assert_eq(cap["oozes_moss_golden_reduction"], 100)
	assert_eq(cap["oozes_hasty_release_deaths"], 1)


func test_per_tribe_t_moves_only_that_tribe() -> void:
	var mixed: Dictionary = Pass3Path.override({"hunters": 3.0})
	var base: Dictionary = Pass3Path.override(0.0)
	assert_eq(mixed["hunters_ermeline_pelts"], 1)
	assert_eq(mixed["oozes_eat_printed_multiplier"], base["oozes_eat_printed_multiplier"])
	assert_eq(mixed["birds_homecoming_multiplier"], base["birds_homecoming_multiplier"])
	var ooze_only: Dictionary = Pass3Path.override({"oozes": 1.0})
	var c: Dictionary = Pass3Path.override(1.0)
	for key: String in base:
		assert_eq(ooze_only[key], c[key] if key.begins_with("oozes_") else base[key], key)


func test_every_path_face_prints_its_rules_number_at_t_0_1_2_and_3() -> void:
	for t: float in [0.0, 1.0, 2.0, 3.0]:
		var config: GameConfig = _config(t)
		var library: UnitLibrary = ScaleOverlay.library_for(UnitLibrary.load_dir(), config)
		for entry: Array in FACES:
			var card: Dictionary = _card(library, str(entry[1]))
			var words: String = _field(card, str(entry[2]))
			var regex := RegEx.create_from_string(str(entry[3]))
			var found: RegExMatch = regex.search(words)
			var label: String = "%s on %s %s at t=%s: %s" % [entry[0], entry[1], entry[2], t, words]
			assert_not_null(found, label)
			if found == null:
				continue
			var phrase: String = ""
			for group: int in range(found.get_group_count(), 0, -1):
				if found.get_string(group) != "":
					phrase = found.get_string(group)
					break
			var factor: float = (
				Pass3Rates.number(config, str(entry[4]))
				if entry[4] is String
				else CoreUtil.to_float(entry[4])
			)
			var want: float = Pass3Rates.number(config, str(entry[0])) * factor
			assert_almost_eq(amount(phrase), want, 1e-6, label)


func test_flight_keyword_reminders_name_both_real_outcomes_in_recruit_and_combat() -> void:
	for t: float in [0.0, 1.0, 2.0, 3.0]:
		_kit(t)
		for id: String in BotPass3.FLIERS:
			var card: Dictionary = kit.library.get_unit(id)
			var normal: String = str(card["details"]).get_slice(" Flying", 0)
			var golden_words: String = str(card["golden_details"]).get_slice(" Flying", 0)
			for golden: bool in [false, true]:
				var recruit := RecruitUnit.make(card, 1, golden)
				var fighter := CombatUnit.make(card, {"golden": golden}, 1, 0)
				for view: Dictionary in [recruit.view(), fighter.view()]:
					var reminder: String = ""
					for entry: Dictionary in view["keyword_text"]:
						if str(entry["keyword"]) == "Fly South":
							reminder = str(entry["text"])
					assert_string_contains(reminder, normal, "%s at t=%s" % [id, t])
					assert_string_contains(reminder, golden_words, "%s at t=%s" % [id, t])


func test_path_faces_stay_readable_with_no_raw_decimals_or_percent_fallbacks() -> void:
	var decimals := RegEx.create_from_string("\\d\\.\\d{3,}")
	for t: float in [0.0, 1.0, 2.0, 3.0]:
		var library: UnitLibrary = ScaleOverlay.library_for(UnitLibrary.load_dir(), _config(t))
		for card: Dictionary in library.all_units() + library.all_cards():
			if not card.has("pass3_rates") and str(card.get("id", "")) != "golden_egg":
				continue
			for field: String in ["text", "golden_text", "details", "golden_details"]:
				var words: String = str(card.get(field, ""))
				var where: String = "%s %s at t=%s: %s" % [card["id"], field, t, words]
				assert_null(decimals.search(words), where)
				if str(card["id"]) not in ["aunt_aspic", "tom_tit", "moss_ooze"]:
					assert_false(words.contains("%"), where)


func test_amount_reads_word_and_numeric_fraction_numerators() -> void:
	assert_almost_eq(amount("nine tenths"), 0.9, 1e-9)
	assert_almost_eq(amount("9 tenths"), 0.9, 1e-9)
	assert_almost_eq(amount("11 twelfths"), 11.0 / 12.0, 1e-9)
	assert_almost_eq(amount("two thirds"), 2.0 / 3.0, 1e-9)
	assert_true(is_nan(amount("unknown tenths")))


## Phrases the printers use, read back into numbers.
static func amount(phrase: String) -> float:
	var words: String = phrase.strip_edges().to_lower()
	match words:
		"", "all":
			return 1.0
		"half":
			return 0.5
		"twice", "double", "doubled":
			return 2.0
		"triple", "tripled":
			return 3.0
		"one and a half times":
			return 1.5
	if words.begins_with("× "):
		return words.trim_prefix("× ").to_float()
	if words.ends_with("%"):
		return words.trim_suffix("%").to_float() / 100.0
	if words.is_valid_float():
		return words.to_float()
	var parts: PackedStringArray = words.split(" ")
	if parts.size() >= 2 and parts[1] == "times":
		return float(NUMBERS[parts[0]]) if NUMBERS.has(parts[0]) else parts[0].to_float()
	if parts.size() == 1 and NUMBERS.has(parts[0]):
		return float(NUMBERS[parts[0]])
	if parts.size() == 2 and DENOMINATORS.has(parts[1]):
		if NUMBERS.has(parts[0]):
			return float(NUMBERS[parts[0]]) / float(DENOMINATORS[parts[1]])
		if parts[0].is_valid_int():
			return parts[0].to_float() / float(DENOMINATORS[parts[1]])
	return NAN


func _card(library: UnitLibrary, id: String) -> Dictionary:
	var card: Dictionary = library.get_unit(id)
	return card if not card.is_empty() else library.get_card(id)


func _field(card: Dictionary, field: String) -> String:
	if field == "pelt":
		return str(card["keyword_text_overrides"]["Pelt"])
	if field == "eat":
		var reminder: String = str(card["keyword_text_overrides"]["Eat"])
		for entry: Dictionary in card.get("keyword_text", []):
			if str(entry["keyword"]) == "Eat":
				assert_eq(str(entry["text"]), reminder, "the shown Eat reminder is the rule's")
		return reminder
	return str(card.get(field, ""))


# --- Behavioral checks at the authored endpoints and the end of the path (t = 3). ---


func test_tiddy_splits_its_dialled_share_at_t0_and_cap() -> void:
	for row: Array in [[0.0, false, 15], [0.0, true, 30], [3.0, false, 15], [3.0, true, 30]]:
		_kit(row[0])
		var toad: RecruitUnit = kit.put("bridge_toad", 4)
		kit.put("tiddy_mun", 5, row[1])
		kit.player.bog_toll = 20
		kit.rules.events.fire(kit.player, "start_of_turn")
		assert_eq([toad.perm_attack, toad.perm_health], [row[2], row[2]], str(row))


func test_ermeline_pays_its_dialled_pelts_at_t0_and_cap() -> void:
	for row: Array in [[0.0, false, 3], [0.0, true, 6], [3.0, false, 1], [3.0, true, 2]]:
		_kit(row[0])
		var combat: Combat = _fight(
			{0: CK.u("madame_ermeline", 1, 100, row[1]), 1: "little_nip", 4: "old_isegrim"},
			{1: CK.plain(3, 4), 6: CK.plain(90, 120)}
		)
		combat.deal_effect_damage(null, combat.unit_at(0, 0), 10000)
		combat._resolve_deaths(0)
		Pass3HunterGains.finish(combat)
		var pelts: Array = combat.carry.filter(
			func(change: Dictionary) -> bool: return str(change["op"]) == "add_card"
		)
		assert_eq(pelts.size(), 1, str(row))
		assert_eq(pelts[0]["count"], row[2], str(row))
		var share: float = 7.0 / 12.0 if row[0] == 0.0 else 3.0 / 8.0
		assert_eq(
			[pelts[0]["attack"], pelts[0]["health"]], [floori(90 * share), floori(120 * share)]
		)


func test_glutton_and_lodger_take_past_one_at_measured_b() -> void:
	for row: Array in [
		[0.0, false, [10, 13]], [3.0, false, [7, 10]], [0.0, true, [20, 27]], [3.0, true, [15, 20]]
	]:
		_kit(row[0])
		var mine: Dictionary = {
			0: CK.u("little_nip", 1, 100),
			1: CK.u("lodger", 1, 100, row[1]),
			4: CK.u("mountain_glutton", 1, 100, row[1])
		}
		for slot: int in mine:
			mine[slot]["iid"] = 91 + slot
		var combat: Combat = _fight(mine, {0: CK.plain(9, 12)})
		combat.deal_effect_damage(null, combat.unit_at(1, 0), 10000)
		combat._resolve_deaths(1)
		for slot: int in [1, 4]:
			var unit: CombatUnit = combat.unit_at(0, slot)
			assert_eq(
				[unit.pending_attack, unit.pending_health], row[2], "%s slot %d" % [row, slot]
			)
	var config: GameConfig = _config(0.0)
	var library: UnitLibrary = ScaleOverlay.library_for(UnitLibrary.load_dir(), config)
	assert_string_contains(
		library.get_unit("mountain_glutton")["text"], "nine eighths of the quarry's stats"
	)
	assert_string_contains(
		library.get_unit("mountain_glutton")["golden_text"], "nine quarters of the quarry's stats"
	)
	library = ScaleOverlay.library_for(UnitLibrary.load_dir(), _config(2.0))
	assert_string_contains(
		library.get_unit("lodger")["golden_text"], "11 sixths of the quarry's stats"
	)


func test_hasty_gives_its_dialled_share_and_swallow_count_at_endpoints_and_cap() -> void:
	for row: Array in [[0.0, [100, 130]], [1.0, [102, 132]], [3.0, [102, 132]]]:
		_kit(row[0])
		var hasty: Dictionary = CK.u("hasty_pudding", -1, -1)
		hasty["iid"] = 11
		var carry: Dictionary = CK.u("little_dollop", 60, 80)
		carry["iid"] = 12
		# At C and beyond, the second swallow also contributes the smaller enemy's stats.
		var combat: Combat = _fight({0: hasty, 4: carry}, {0: CK.plain(2, 2), 6: CK.plain(40, 50)})
		var grown: CombatUnit = combat.unit_at(0, 4)
		assert_eq([grown.attack, grown.health], row[1], str(row))


func test_hasty_bot_value_reads_the_dial() -> void:
	var values: Array[float] = []
	for t: float in [0.0, 3.0]:
		_kit(t)
		var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
		carry.add_permanent(40, 40)
		var hasty: RecruitUnit = kit.put("hasty_pudding", 0)
		kit.player.scout = {"specs": [{"attack": 50, "health": 50}, {"attack": 1, "health": 1}]}
		var brain: BotBrain = BotBrain.from_name("hard:oozes_waste_not")
		kit.rules.board_changed(kit.player)
		brain._player = kit.player
		brain.value.board_owner = kit.player
		assert_true(BotOoze.wants_hasty(kit.player))
		var size: int = (
			carry.base_attack_now()
			+ carry.perm_attack
			+ carry.base_health_now()
			+ carry.perm_health
		)
		var share: float = 1.0
		var value: float = BotOoze.text_value(hasty, kit.player, brain.value)
		assert_almost_eq(value, size * share + 16.0, 1e-6, "t=%s" % t)
		values.append(value)
	assert_eq(values[1], values[0], "the promoted Hasty share stays flat")


func test_eat_multiplier_scales_only_a_non_oozes_printed_stats() -> void:
	for t: float in [0.0, 1.0, 3.0]:
		_kit(t)
		var multiplier: int = Pass3Rates.integer(kit.config, "oozes_eat_printed_multiplier")
		var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
		carry.add_permanent(30, 30)
		var meal: RecruitUnit = kit.put("field_vole")
		kit.player.hand.erase(meal)
		var printed := Vector2i(meal.base_attack_now(), meal.base_health_now())
		meal.add_permanent(5, 6)
		var before := Vector2i(carry.perm_attack, carry.perm_health)
		Pass3Oozes.eat(kit.rules, kit.player, carry, meal)
		var want: Vector2i = printed * multiplier + Vector2i(5, 6)
		assert_eq(Vector2i(carry.perm_attack, carry.perm_health) - before, want, "t=%s" % t)
		var ooze: RecruitUnit = kit.put("little_dollop")
		kit.player.hand.erase(ooze)
		ooze.add_permanent(3, 4)
		var whole := Vector2i(
			ooze.base_attack_now() + ooze.perm_attack, ooze.base_health_now() + ooze.perm_health
		)
		before = Vector2i(carry.perm_attack, carry.perm_health)
		Pass3Oozes.eat(kit.rules, kit.player, carry, ooze)
		assert_eq(
			Vector2i(carry.perm_attack, carry.perm_health) - before, whole, "Ooze meals pass whole"
		)


func test_aspic_and_golden_aspic_use_their_dials_with_the_eat_multiplier() -> void:
	for t: float in [0.0, 1.0, 3.0]:
		for golden: bool in [false, true]:
			_kit(t)
			var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
			carry.add_permanent(30, 30)
			kit.put("aunt_aspic", 4, golden)
			var meal: RecruitUnit = kit.put("field_vole")
			kit.player.hand.erase(meal)
			var printed := Vector2i(meal.base_attack_now(), meal.base_health_now())
			var before := Vector2i(carry.perm_attack, carry.perm_health)
			var stats: Vector2i = (
				printed * Pass3Rates.integer(kit.config, "oozes_eat_printed_multiplier")
			)
			var factor: float = (
				Pass3Rates.number(kit.config, "oozes_golden_aspic_multiplier")
				if golden
				else 1.0 + Pass3Rates.number(kit.config, "oozes_aspic_bonus")
			)
			var want := Vector2i(floori(stats.x * factor + 1e-9), floori(stats.y * factor + 1e-9))
			Pass3Oozes.eat(kit.rules, kit.player, carry, meal)
			assert_eq(
				Vector2i(carry.perm_attack, carry.perm_health) - before,
				want,
				"t=%s golden=%s" % [t, golden]
			)


func test_meal_bot_value_counts_the_eat_multiplier() -> void:
	for t: float in [0.0, 1.0, 3.0]:
		_kit(t)
		var multiplier: int = Pass3Rates.integer(kit.config, "oozes_eat_printed_multiplier")
		kit.put("bubble_and_squeak", 1)
		kit.put("elder_ooze", 4)
		kit.put("aunt_aspic", 6)
		var meal: RecruitUnit = kit.shop("field_vole")
		var brain: BotBrain = BotBrain.from_name("hard:oozes_waste_not")
		kit.rules.board_changed(kit.player)
		brain._player = kit.player
		brain._rules = kit.rules
		brain.value.board_owner = kit.player
		brain.value.recruit_rules = kit.rules
		brain.value.library = kit.library
		var own: int = (
			meal.base_attack_now() + meal.perm_attack + meal.base_health_now() + meal.perm_health
		)
		var soup: Vector2i = meal.get_meta("ooze_soup_bonus", Vector2i.ZERO)
		var printed: int = meal.base_attack_now() + meal.base_health_now()
		assert_eq(
			BotOoze.meal_gain(brain, meal),
			float(own + soup.x + soup.y + printed * (multiplier - 1))
		)
		assert_eq(
			Pass3Oozes.meal_stats(kit.player, meal),
			Vector2i(
				meal.base_attack_now() * multiplier + meal.perm_attack,
				meal.base_health_now() * multiplier + meal.perm_health
			)
		)


func _fight(mine: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	combat._start_of_combat()
	return combat
