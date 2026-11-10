class_name Pass3Path
extends RefCounted
## A3.5's dial paths: d(t) = B × (C / B)^t per tribe, snapped to a printable value toward
## generous (09h), clamped at each dial's limit, with golden twins derived from their normal.
## B and C come from the presets in rates.json, so t = 0 is B and t = 1 is C.

## Snap kinds: "int" rounds up; "half" and "pct5" round up to 0.5 and 0.05; "frac_*" rounds up
## to the smallest fraction its printer can name (FRACTION_SETS).
const DIALS: Array[Dictionary] = [
	{"key": "birds_homecoming_multiplier", "tribe": "birds", "snap": "half"},
	{
		"key": "birds_golden_homecoming_multiplier",
		"tribe": "birds",
		"snap": "half",
		"at_least_key": "birds_homecoming_multiplier"
	},
	{"key": "birds_chiffchaff_gain", "tribe": "birds", "snap": "int"},
	{"key": "birds_golden_egg_multiplier", "tribe": "birds", "snap": "half"},
	# Golden Birds print twice the share, which stays under 1 to t = 3.
	{"key": "birds_redbreast_share", "tribe": "birds", "snap": "frac_text", "max": 1.0},
	{"key": "birds_cuckoo_share", "tribe": "birds", "snap": "frac_text", "max": 1.0},
	{"key": "birds_stork_gold_step", "tribe": "birds", "snap": "int", "min": 1.0},
	{"key": "fairies_ring_growth", "tribe": "fairies", "snap": "int"},
	{"key": "fairies_lob_growth", "tribe": "fairies", "snap": "int"},
	{"key": "fairies_silky_growth", "tribe": "fairies", "snap": "int"},
	{"key": "bog_soak_keep", "tribe": "bog", "snap": "int"},
	{"key": "bog_golden_soak_keep", "tribe": "bog", "golden_of": "bog_soak_keep", "times": 2.0},
	# Quarters, so the golden twin (twice) prints as half, the Toll, 1.5 or twice.
	{"key": "bog_tiddy_share", "tribe": "bog", "snap": "frac_quarters", "max": 1.0},
	{
		"key": "bog_golden_tiddy_share",
		"tribe": "bog",
		"golden_of": "bog_tiddy_share",
		"times": 2.0,
		"max": 2.0
	},
	{"key": "hunters_nip_share", "tribe": "hunters", "snap": "frac_hunt", "max": 1.0},
	{"key": "hunters_sable_share", "tribe": "hunters", "snap": "frac_hunt", "max": 1.0},
	{"key": "hunters_lutra_share", "tribe": "hunters", "snap": "frac_hunt", "max": 1.0},
	# The carry's size axis: the share cap of 1 is lifted on these two only.
	{"key": "hunters_glutton_share", "tribe": "hunters", "snap": "frac_hunt"},
	{"key": "hunters_lodger_share", "tribe": "hunters", "snap": "frac_hunt"},
	{"key": "hunters_wick_share", "tribe": "hunters", "snap": "frac_hunt", "max": 1.0},
	{"key": "hunters_grizel_share", "tribe": "hunters", "snap": "frac_hunt", "max": 1.0},
	{"key": "hunters_pelt_share", "tribe": "hunters", "snap": "frac_hunt", "max": 1.0},
	{"key": "hunters_russet_buff_share", "tribe": "hunters", "snap": "frac_hunt", "max": 1.0},
	{"key": "hunters_ermeline_pelts", "tribe": "hunters", "snap": "int", "min": 1.0},
	{
		"key": "hunters_golden_ermeline_pelts",
		"tribe": "hunters",
		"golden_of": "hunters_ermeline_pelts",
		"times": 2.0,
		"max": 10.0
	},
	{"key": "oozes_soup_share", "tribe": "oozes", "snap": "frac_text", "max": 1.0},
	{"key": "oozes_elder_share", "tribe": "oozes", "snap": "frac_text", "max": 1.0},
	{"key": "oozes_hasty_share", "tribe": "oozes", "snap": "frac_text", "max": 1.0},
	{"key": "oozes_aspic_bonus", "tribe": "oozes", "snap": "pct5"},
	{
		"key": "oozes_golden_aspic_multiplier",
		"tribe": "oozes",
		"golden_of": "oozes_aspic_bonus",
		"times": 2.0,
		"plus": 1.0
	},
	{"key": "oozes_eat_printed_multiplier", "tribe": "oozes", "snap": "int", "min": 1.0},
	# Hedgerow joins when wave 2b lands its keys in rates.json; until then these are skipped.
	{"key": "hedgerow_mallow_multiplier", "tribe": "hedgerow", "snap": "half", "above": 1.0},
	{"key": "hedgerow_dozey_wake_multiplier", "tribe": "hedgerow", "snap": "half", "above": 1.0},
	{
		"key": "hedgerow_golden_dozey_wake_multiplier",
		"tribe": "hedgerow",
		"snap": "half",
		"above": 1.0,
		"at_least_key": "hedgerow_dozey_wake_multiplier"
	},
	{"key": "hedgerow_treasurer_per_gold", "tribe": "hedgerow", "snap": "half", "above": 0.0},
]
## Off every path, but pinned for both arms of every run (DECISIONS 10 Nov, generous first).
const PINNED: Dictionary = {
	"fairies_monarch_multiplier": 3.0,
	"fairies_golden_monarch_multiplier": 4.0,
}
## Shared or held dials that take the run's own preset value and sit on no path.
const OFF_PATH: PackedStringArray = [
	"scale_hero_spell_percent",
	"fairies_initial_ring_size",
	"fairies_monarch_multiplier",
	"fairies_golden_monarch_multiplier",
]
const TRIBES: PackedStringArray = ["birds", "fairies", "bog", "hunters", "oozes", "hedgerow"]
## Denominators each printer names: Pass3Text._fraction, Pass3HunterText._portion, Bog quarters.
const FRACTION_SETS: Dictionary = {
	"frac_text": [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 16, 20],
	"frac_hunt": [2, 3, 4, 6, 8, 12],
	"frac_quarters": [4],
}
const EPSILON: float = 1e-9


## `t` is one float for every tribe, or a Dictionary of tribe -> t (missing tribes use 0).
static func override(t: Variant) -> Dictionary:
	var b: Dictionary = preset_rates("B")
	var c: Dictionary = preset_rates("C")
	var known: PackedStringArray = Pass3Rates.keys()
	var out: Dictionary = {}
	for dial: Dictionary in DIALS:
		var key: String = str(dial["key"])
		if not known.has(key):
			continue
		var value: float
		if dial.has("golden_of"):
			var normal: float = CoreUtil.to_float(out[str(dial["golden_of"])])
			value = (
				normal * CoreUtil.to_float(dial["times"]) + CoreUtil.to_float(dial.get("plus", 0.0))
			)
		else:
			var tribe_t: float = _tribe_t(t, str(dial["tribe"]))
			value = snap(path_value(_num(b, key), _num(c, key), tribe_t), str(dial["snap"]))
		value = _limit(dial, value, out)
		if _is_int(dial):
			out[key] = roundi(value)
		else:
			out[key] = value
	for key: String in PINNED:
		out[key] = PINNED[key]
	return out


static func path_value(b: float, c: float, t: float) -> float:
	if is_zero_approx(b) or is_equal_approx(b, c):
		return b
	return b * pow(c / b, t)


static func snap(value: float, kind: String) -> float:
	match kind:
		"int":
			return ceilf(value - EPSILON)
		"half":
			return ceilf(value * 2.0 - EPSILON) / 2.0
		"pct5":
			return ceilf(value * 20.0 - EPSILON) / 20.0
	var best: float = INF
	for denominator: int in FRACTION_SETS[kind]:
		var numerator: int = int(ceilf(value * denominator - EPSILON))
		best = minf(best, float(maxi(1, numerator)) / denominator)
	return best


static func preset_rates(preset: String) -> Dictionary:
	var config := GameConfig.defaults()
	config.set_value("pass3_preset", preset)
	return Pass3Rates.resolved(config)


## The keys the path prints, including derived golden twins and pins.
static func keys() -> PackedStringArray:
	var out: PackedStringArray = []
	for key: String in override(0.0):
		out.append(key)
	return out


static func _limit(dial: Dictionary, value: float, done: Dictionary) -> float:
	var step: float = 1.0 if _is_int(dial) else 0.5 if dial.get("snap", "") == "half" else 0.0
	if dial.has("min"):
		value = maxf(value, CoreUtil.to_float(dial["min"]))
	if dial.has("above"):
		var floor_value: float = CoreUtil.to_float(dial["above"])
		if value <= floor_value + EPSILON:
			value = floor_value + (step if step > 0.0 else 0.5)
	if dial.has("at_least_key"):
		value = maxf(value, CoreUtil.to_float(done.get(str(dial["at_least_key"]), value)))
	if dial.has("max"):
		value = minf(value, CoreUtil.to_float(dial["max"]))
	return value


static func _is_int(dial: Dictionary) -> bool:
	if dial.has("golden_of"):
		for other: Dictionary in DIALS:
			if other["key"] == dial["golden_of"]:
				return str(other.get("snap", "")) == "int"
	return str(dial.get("snap", "")) == "int"


static func _tribe_t(t: Variant, tribe: String) -> float:
	if t is Dictionary:
		var map: Dictionary = t
		return CoreUtil.to_float(map.get(tribe, 0.0))
	return CoreUtil.to_float(t)


static func _num(rates: Dictionary, key: String) -> float:
	return CoreUtil.to_float(rates.get(key, 0.0))
