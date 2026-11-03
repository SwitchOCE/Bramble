extends GutTest
## Nightshade (library entry 75; SPEC 4.2): Belladonna Sprite's Start of Combat mark (rulebook
## 9.3) and Bitter Toad's on-hit mark; the halving when attacked (9.6.1 step 3).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func test_sprite_marks_the_highest_health_enemy_9_3() -> void:
	var mine: Array = Kit.board({4: Kit.u("belladonna_sprite"), 0: Kit.plain(0, 50)})
	var theirs: Array = Kit.board({0: Kit.plain(0, 3), 1: Kit.plain(0, 9)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_eq(Kit.status_on(result, "nightshade"), [4], "the 9-Health unit (uid 4)")
	var trigger: Dictionary = Kit.of_type(result, "trigger")[0]
	assert_eq([trigger["uid"], trigger["mechanic"]], [2, "nightshade_mark"], "the Sprite (uid 2) triggers")


func test_golden_sprite_marks_two() -> void:
	var mine: Array = Kit.board({4: Kit.u("belladonna_sprite", -1, -1, true)})
	var theirs: Array = Kit.board({0: Kit.plain(0, 3), 1: Kit.plain(0, 9), 2: Kit.plain(0, 5)})
	var marked: Array = Kit.status_on(Kit.run(mine, theirs), "nightshade")
	marked.sort()
	assert_eq(marked, [3, 4], "the two highest (9 and 5)")


func test_two_sprites_mark_two_units_pick() -> void:
	var mine: Array = Kit.board({4: Kit.u("belladonna_sprite"), 5: Kit.u("belladonna_sprite")})
	var theirs: Array = Kit.board({0: Kit.plain(0, 3), 1: Kit.plain(0, 9)})
	var marked: Array = Kit.status_on(Kit.run(mine, theirs), "nightshade")
	marked.sort()
	assert_eq(marked, [3, 4], "the second Sprite passes over the marked unit")


func test_attacked_unit_loses_half_its_health_first_9_6_1() -> void:
	var mine: Array = Kit.board({0: Kit.plain(1, 50), 4: Kit.u("belladonna_sprite")})
	var theirs: Array = Kit.board({0: Kit.plain(0, 9)})
	var result: Dictionary = Kit.run(mine, theirs)
	var at: int = Kit.index_of(result, "attack")
	assert_eq(Kit.types_from(result, at, 3), ["attack", "health_loss", "damage"], "loss first")
	var loss: Dictionary = Kit.of_type(result, "health_loss")[0]
	assert_eq([loss["target"], loss["amount"], loss["health_after"]], [3, 4, 5], "9 -> 5")
	assert_eq(loss["cause"], "nightshade", "cause")
	var hit: Dictionary = Kit.of_type(result, "damage")[0]
	assert_eq(hit["health_after"], 4, "then the 1 damage")


func test_health_loss_never_kills() -> void:
	var mine: Array = Kit.board({0: Kit.plain(0, 50), 4: Kit.u("belladonna_sprite", 0, 5)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 1)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_eq(Kit.of_type(result, "health_loss").size(), 0, "1 Health loses nothing")


func test_attacking_with_nightshade_loses_nothing() -> void:
	var mine: Array = Kit.board({4: Kit.u("belladonna_sprite", 0, 50), 0: Kit.plain(0, 50)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 40)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_eq(Kit.of_type(result, "health_loss").size(), 0, "only being attacked halves")


func test_toad_marks_what_it_damages() -> void:
	var mine: Array = Kit.board({0: Kit.u("bitter_toad", 1, 50), 1: Kit.plain(0, 50)})
	var theirs: Array = Kit.board({0: Kit.plain(0, 20)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_eq(Kit.status_on(result, "nightshade"), [3], "the enemy it hit")
	var losses: Array[Dictionary] = Kit.of_type(result, "health_loss")
	assert_eq(losses[0]["amount"], 9, "its next attack halves 19 to 10")


func test_plain_toad_doesnt_mark_its_attacker() -> void:
	var mine: Array = Kit.board({0: Kit.u("bitter_toad", 0, 50)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 20), 1: Kit.plain(0, 20)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_eq(Kit.status_on(result, "nightshade"), [], "only the golden toad does")


func test_golden_toad_marks_its_attacker() -> void:
	var mine: Array = Kit.board({0: Kit.u("bitter_toad", 0, 50, true)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 20), 1: Kit.plain(0, 20)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_eq(Kit.status_on(result, "nightshade"), [2], "the enemy that damaged it")


func test_status_text_on_the_card() -> void:
	var mine: Array = Kit.board({4: Kit.u("belladonna_sprite")})
	var theirs: Array = Kit.board({0: Kit.u("bitter_toad")})
	var result: Dictionary = Kit.run(mine, theirs)
	var start: Dictionary = Kit.events(result)[0]
	var toad: Dictionary = start["boards"][1][0]
	var entries: Array = toad["keyword_text"]
	assert_eq(entries.size(), 1, "the toad's own Nightshade text")
