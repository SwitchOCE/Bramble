extends SceneTree
## Reproduce build 9's provisional non-Ooze C on the frozen run-1 endpoints.

const SOURCE: String = "res://docs/ideation/evidence/a35-run1/path-source.json"
const FIT: String = "res://docs/ideation/evidence/b9-measure/provisional-fit.json"
const OUT: String = "res://docs/ideation/evidence/b9-measure/provisional-rates.json"


func _initialize() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var fit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIT))
	var fits: Dictionary = fit["fits"]
	var steps: Dictionary = {}
	for tribe: String in fits:
		var row: Dictionary = fits[tribe]
		steps[tribe] = row["chosen_t"]
	Pass3Rates.defaults()
	Pass3Rates._presets["B"] = source["b"]
	Pass3Rates._presets["C"] = source["c"]
	var all_rates: Dictionary = Pass3Path.override(steps)
	var rates: Dictionary = {}
	var limits: Array[Dictionary] = []
	var b: Dictionary = source["b"]
	var c: Dictionary = source["c"]
	var dials: Array = source["dials"]
	for dial: Dictionary in dials:
		if dial["tribe"] == "oozes":
			continue
		var key: String = str(dial["key"])
		var value: float
		if dial.has("golden_of"):
			value = (
				(
					CoreUtil.to_float(all_rates[str(dial["golden_of"])])
					* CoreUtil.to_float(dial["times"])
				)
				+ CoreUtil.to_float(dial.get("plus", 0.0))
			)
		else:
			value = Pass3Path.snap(
				Pass3Path.path_value(
					CoreUtil.to_float(b[key]),
					CoreUtil.to_float(c[key]),
					CoreUtil.to_float(steps[str(dial["tribe"])])
				),
				str(dial["snap"])
			)
		rates[key] = all_rates[key]
		for kind: String in ["min", "max"]:
			if dial.has(kind):
				var bound: float = CoreUtil.to_float(dial[kind])
				if (
					(kind == "max" and value >= bound - 1e-9)
					or (kind == "min" and value <= bound + 1e-9)
				):
					limits.append(
						{
							"key": key,
							"limit": kind,
							"bound": bound,
							"before": value,
							"after": all_rates[key]
						}
					)
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(
		(
			JSON.stringify(
				{"provisional": true, "rates": rates, "limits": limits}, "  ", true, true
			)
			+ "\n"
		)
	)
	print("Provisional C: ", JSON.stringify(rates, "", true, true))
	quit()
