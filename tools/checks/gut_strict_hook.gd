extends GutHookScript
## GUT post-run hook (wired in .gutconfig.json): fails the run when any test is risky
## (ran without asserting, or its script was skipped) or pending. GUT itself exits 0 for these.
## Always prints one "gut_strict:" summary line; check.sh requires it, so a hook that never
## ran is also a failure.

const CollectedScript: GDScript = preload("res://addons/gut/collected_script.gd")
const CollectedTest: GDScript = preload("res://addons/gut/collected_test.gd")
const TestCollector: GDScript = preload("res://addons/gut/test_collector.gd")
const EXIT_FAILURE: int = 1


func run() -> void:
	var main: GutMain = gut
	var collector: TestCollector = main.get_test_collector()
	var problems: PackedStringArray = []
	for collected: CollectedScript in collector.scripts:
		problems.append_array(_script_problems(collected))
	for line: String in problems:
		print("gut_strict: %s" % line)
	if problems.is_empty():
		print("gut_strict: ok (no risky or pending tests)")
		return
	print("gut_strict: FAILED, %d risky or pending" % problems.size())
	set_exit_code(EXIT_FAILURE)


func _script_problems(collected: CollectedScript) -> PackedStringArray:
	var out: PackedStringArray = []
	var script_name: String = collected.get_full_name()
	if collected.was_skipped:
		out.append("skipped script %s (%s)" % [script_name, collected.skip_reason])
		return out
	for test: CollectedTest in collected.tests:
		if test.is_risky():
			out.append("no asserts: %s.%s" % [script_name, test.name])
		elif test.is_pending():
			out.append("pending: %s.%s" % [script_name, test.name])
	return out
