extends GutTest
## Garden Snail (library entry 4): Shell 4 caps the first damage this combat, then breaks.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func test_first_damage_capped_then_shell_breaks() -> void:
	var mine: Array = Kit.board({0: Kit.u("garden_snail", 0, 20)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(10, 50)}))
	var start: Dictionary = Kit.events(result)[0]
	var snail: Dictionary = start["boards"][0][0]
	assert_eq(snail["statuses"], [{"status": "shell", "data": {"n": 4}}], "shown at the start")
	var hits: Array[Dictionary] = Kit.of_type(result, "damage")
	assert_eq([hits[0]["amount"], hits[0]["modifiers"]], [4, ["shell"]], "10 capped at 4")
	assert_eq(hits[1]["amount"], 10, "the next hit is full")
	var at: int = Kit.index_of(result, "damage")
	var off: Dictionary = Kit.events(result)[at + 1]
	assert_eq([off["type"], off["status"], off["on"]], ["status", "shell", false], "breaks")


func test_golden_keeps_n_7_3_5() -> void:
	var mine: Array = Kit.board({0: Kit.u("garden_snail", 0, -1, true)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(10, 50)}))
	var hit: Dictionary = Kit.of_type(result, "damage")[0]
	assert_eq([hit["amount"], hit["health_after"]], [4, 2], "a golden 2/6 keeps Shell 4")


func test_shell_also_caps_effect_and_thorn_damage() -> void:
	var mine: Array = Kit.board({0: Kit.u("garden_snail", 5, 20)})
	var theirs: Array = Kit.board({0: Kit.u("hoglet_mother", 0, 50, true)})
	var result: Dictionary = Kit.run(mine, theirs)
	var thorns: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage"):
		if hit["kind"] == "thorns":
			thorns.append(hit["modifiers"])
	assert_eq(thorns.slice(0, 2), [["shell"], []], "the first damage of any kind breaks it")
