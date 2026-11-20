extends GutTest
## Kin interactions through live fights.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const Kit := preload("res://tests/content/mouse/mouse_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	p = game.player(0)
	q = game.player(1)


## The Scout (3/10) attacks a 10/1000 wall and dies to the strike back.
func _scout_falls() -> Combat:
	CoreKit.put(game, p, "hedgerow-scout", 0)
	Kit.wall(game, q, 0, 10, 1000)
	game.config.attack_limit = 1
	return Kit.fight(game)


func test_bell_ringers_add_to_the_same_gift() -> void:
	CoreKit.put(game, p, "bell-ringer", 1)
	CoreKit.put(game, p, "bell-ringer", 6)
	var combat: Combat = _scout_falls()
	assert_eq(combat.unit_at(0, 1).stats.combat_attack, 3 + 3 + 3)


func test_widow_gives_the_full_attack_to_each_of_the_two_nearest() -> void:
	for slot: int in [1, 2, 4]:
		CoreKit.put(game, p, "needle-page", slot)
	CoreKit.put(game, p, "widow-thimble", 6)
	var combat: Combat = _scout_falls()
	assert_eq(combat.unit_at(0, 1).attack(), 7)
	assert_eq(combat.unit_at(0, 4).attack(), 7)
	assert_eq(combat.unit_at(0, 2).attack(), 4)
	assert_eq(combat.unit_at(0, 6).attack(), 5)


func test_standard_bearer_keeps_its_start_count_and_its_buff_passes() -> void:
	CoreKit.put(game, p, "needle-page", 1)
	CoreKit.put(game, p, "parish-standard-bearer", 6)
	var combat: Combat = _scout_falls()
	assert_eq(combat.unit_at(0, 1).attack(), 4 + 9 + (3 + 9))
	assert_eq(combat.unit_at(0, 6).attack(), 6 + 9)


func test_hob_gives_the_heir_permanent_attack() -> void:
	var heir: Unit = CoreKit.put(game, p, "needle-page", 1)
	CoreKit.put(game, p, "grandmother-hob", 4)
	var combat: Combat = _scout_falls()
	assert_eq(heir.stats.perm_attack, 4)
	assert_eq(combat.unit_at(0, 1).attack(), 4 + 3 + 4)


func test_sister_attacks_immediately_with_the_inherited_attack() -> void:
	CoreKit.put(game, p, "hedgerow-scout", 0)
	CoreKit.put(game, p, "needle-sister", 1)
	Kit.wall(game, q, 0, 10, 1000)
	game.config.attack_limit = 2
	var combat: Combat = Kit.fight(game)
	var sister: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.where(combat, "trigger", "mechanic", "mouse_sister").size(), 1)
	assert_eq(Kit.damage_by(combat, sister), [7] as Array[int])
	assert_eq(CoreKit.events_of(combat, "attack")[1]["uid"], sister)


func test_old_mother_makes_only_the_first_three_gifts_permanent() -> void:
	for slot: int in 4:
		CoreKit.put(game, p, "cousin", slot)
	CoreKit.put(game, p, "old-mother-needle", 5)
	Kit.wall(game, q, 0, 2, 1000)
	var combat: Combat = Kit.fight(game)
	var gifts: Array = CoreKit.events_of(combat, "buff").map(
		func(event: Dictionary) -> bool: return event["permanent"]
	)
	assert_eq(gifts, [true, true, true, false])


func test_sentinel_guards_then_hands_down_its_attack() -> void:
	CoreKit.put(game, p, "needle-page", 0)
	CoreKit.put(game, p, "thimble-sentinel", 1)
	for slot: int in 3:
		Kit.wall(game, q, slot, 24, 100)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game)
	assert_eq(CoreKit.events_of(combat, "attack")[0]["target_uid"], Kit.uid_at(combat, 0, 1))
	assert_eq(combat.unit_at(0, 0).attack(), 7)


func test_simultaneous_cleave_deaths_skip_the_dying_cousin() -> void:
	CoreKit.put(game, p, "thimble-sentinel", 0)
	CoreKit.put(game, p, "cousin", 1)
	CoreKit.put(game, p, "hedgerow-scout", 6)
	var cleaver: Unit = Kit.wall(game, q, 0, 24, 100)
	assert_true(cleaver.grant(game.registry, &"cleave"))
	for slot: int in [1, 2, 3]:
		Kit.wall(game, q, slot, 0, 5)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game)
	assert_null(combat.unit_at(0, 0))
	assert_null(combat.unit_at(0, 1))
	var heir: CombatUnit = combat.unit_at(0, 6)
	assert_eq(heir.stats.combat_attack, 3 + 2)
	var buffs: Array[Dictionary] = CoreKit.events_of(combat, "buff")
	assert_eq(buffs.size(), 2)
	assert_true(buffs.all(func(event: Dictionary) -> bool: return event["uid"] == heir.uid))


func test_widows_share_the_largest_heir_count_and_one_mother_charge() -> void:
	for slot: int in [1, 2, 4]:
		CoreKit.put(game, p, "needle-page", slot)
	Kit.golden(game, p, "widow-thimble", 3)
	CoreKit.put(game, p, "widow-thimble", 5)
	CoreKit.put(game, p, "old-mother-needle", 6)
	var combat: Combat = _scout_falls()
	var uses: Array[Dictionary] = Kit.where(combat, "uses", "key", "mouse_charge_left")
	assert_eq(uses.size(), 1)
	assert_eq(uses[0]["left"], 2)
	for slot: int in [1, 2, 4]:
		assert_eq(p.board[slot].stats.perm_attack, 3)
	for slot: int in [3, 5, 6]:
		assert_eq(p.board[slot].stats.perm_attack, 0)
