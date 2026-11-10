extends SceneTree
## The single C repair on frozen endpoints; emits only Ooze, Hunter and Bog path rates.

const FOLDER: String = "res://docs/ideation/evidence/b9-measure/c-repair/"


func _initialize() -> void:
	var source: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://docs/ideation/evidence/a35-run1/path-source.json")
	)
	var fit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOLDER + "fit.json"))
	var steps: Dictionary = {}
	for tribe: String in fit["fits"]:
		var row: Dictionary = fit["fits"][tribe]
		steps[tribe] = row["chosen_t"]
	# Soup's B changed after run 1; Ooze t=0 must be the B measured at A4, not the older 0.3.
	var ooze: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(FOLDER + "ooze-endpoints.json")
	)
	var b_source: Dictionary = source["b"]
	var c_source: Dictionary = source["c"]
	var ooze_b: Dictionary = ooze["b"]
	var ooze_c: Dictionary = ooze["c"]
	b_source.merge(ooze_b, true)
	c_source.merge(ooze_c, true)
	Pass3Rates.defaults()
	Pass3Rates._presets["B"] = source["b"]
	Pass3Rates._presets["C"] = source["c"]
	var all_rates: Dictionary = Pass3Path.override(steps)
	var rates: Dictionary = {}
	var audit: Array = []
	var b: Dictionary = source["b"]
	var c: Dictionary = source["c"]
	for dial: Dictionary in Pass3Path.DIALS:
		var tribe: String = dial["tribe"]
		if not steps.has(tribe):
			continue
		var key: String = dial["key"]
		var rounded_value: float
		if dial.has("golden_of"):
			rounded_value = (
				(
					CoreUtil.to_float(all_rates[str(dial["golden_of"])])
					* CoreUtil.to_float(dial["times"])
				)
				+ CoreUtil.to_float(dial.get("plus", 0.0))
			)
		else:
			rounded_value = Pass3Path.snap(
				Pass3Path.path_value(
					CoreUtil.to_float(b[key]),
					CoreUtil.to_float(c[key]),
					CoreUtil.to_float(steps[tribe])
				),
				str(dial["snap"])
			)
		rates[key] = all_rates[key]
		var limits: Array = []
		for kind: String in ["min", "max"]:
			if dial.has(kind) and is_equal_approx(rounded_value, CoreUtil.to_float(dial[kind])):
				limits.append(kind)
		audit.append(
			{
				"key": key,
				"b": b[key],
				"c": c[key],
				"t": steps[tribe],
				"rounded_value": rounded_value,
				"after_limits": all_rates[key],
				"equality_limits": limits,
				"clipped": not is_equal_approx(rounded_value, CoreUtil.to_float(all_rates[key]))
			}
		)
	var file := FileAccess.open(FOLDER + "rates.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"rates": rates, "audit": audit}, "  ", true, true) + "\n")
	print("C repair: ", JSON.stringify(rates, "", true, true))
	quit()
