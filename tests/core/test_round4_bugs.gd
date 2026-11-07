extends GutTest
## Reported round-4 wrongnesses: unique lobby identities, real paid prices, and fight logs.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const FIGHT := preload("res://tests/core/combat_kit.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const FightLog := preload("res://tools/play/play_fight_log.gd")


func test_bots_leave_every_human_hero_choice_available() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	for game_seed: int in range(1, 41):
		var session: GameSession = GameSession.create(game_seed, library, GameConfig.full_game())
		var offer: PackedStringArray = session.hero_offer_of(GameSession.HUMAN_ID)
		assert_eq(session.choose(game_seed % offer.size()), "")
		var heroes: Dictionary = {}
		for row: Dictionary in session.get_standings():
			assert_false(heroes.has(row["hero"]), "human and bots have distinct heroes")
			heroes[row["hero"]] = true


func test_discounted_spell_retains_price_paid_after_discount_expires() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	kit.put("prince_restored", 0)
	kit.player.shop_spells = [HandItem.make(kit.library.get_card("elderflower_cordial"), 900)]
	assert_eq(kit.rules.buy_spell(kit.player, 0), "")
	var bought: HandItem = kit.player.items.back()
	assert_eq(bought.cost(), 1, "printed cost still feeds rules")
	assert_eq(bought.view()["cost"], 0, "hand remembers the discounted purchase")
	kit.player.board[0] = null
	assert_eq(bought.view()["cost"], 0, "selling the Prince cannot change a price already paid")


func test_plain_mag_pye_takes_only_across_before_any_row_swap() -> void:
	for slot: int in BoardGeometry.SLOTS:
		var kit: KIT = KIT.new()
		kit.setup(GameConfig.full_game())
		kit.put("mag_pye", slot)
		var enemy: Dictionary = {}
		for other: int in BoardGeometry.SLOTS:
			enemy[other] = FIGHT.u("whirligig_beetle", 0, 100)
		var result: Dictionary = kit.fight_board(enemy, 202)
		var thefts: Array[Dictionary] = KIT.of_type(result, "text_taken")
		assert_eq(thefts.size(), 1, "plain Mag Pye fires once at %s" % BoardGeometry.LABELS[slot])
		var start: Dictionary = result["events"][0]
		var opposing: Array = start["boards"][1]
		assert_eq(
			thefts[0]["from"], opposing[slot]["uid"], "across means matching slot before swaps"
		)
		assert_lt(FIGHT.index_of(result, "text_taken"), FIGHT.index_of(result, "relocate"))


func test_golden_mag_pye_takes_across_and_next_slot() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.put("mag_pye", 1, true)
	var result: Dictionary = kit.fight_board(
		{0: FIGHT.u("hedge_witch"), 1: FIGHT.u("hedge_witch"), 2: FIGHT.u("hedge_witch")}, 202
	)
	var thefts: Array[Dictionary] = KIT.of_type(result, "text_taken")
	var opposing: Array = result["events"][0]["boards"][1]
	assert_eq(thefts.size(), 2, "two firings are the printed golden behavior")
	assert_eq([thefts[0]["from"], thefts[1]["from"]], [opposing[1]["uid"], opposing[2]["uid"]])


func test_row_swap_logs_a_slot_and_side_changes_keep_ownership() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.put("whirligig_beetle", 0)
	var result: Dictionary = kit.fight_board({0: FIGHT.u("pill_bug", 0, 100)})
	var model: CombatModel = CombatModel.new()
	var log_text: CombatLog = CombatLog.new()
	var names: Dictionary = {}
	for event: Dictionary in result["events"]:
		var ui: String = log_text.describe(event, model, false)
		var tool: String = FightLog.event_line(event, names, 0)
		if event["type"] == "relocate":
			assert_string_contains(ui, "moves to B1.")
			assert_string_contains(tool, "moves to B1")
			assert_false(tool.contains("moves to the enemy's"))
		model.apply(event)
	var moved: Dictionary = KIT.of_type(result, "relocate")[0]
	var crossing: Dictionary = {"type": "relocate", "uid": moved["uid"], "side": 0, "slot": 3}
	assert_string_contains(FightLog.event_line(crossing, names, 0), "moves to your F4")


func test_echo_card_explains_last_orders_zero_repeat() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var card: Dictionary = library.get_unit("pipistrelle_echo")
	for key: String in ["text", "golden_text"]:
		assert_string_contains(str(card[key]), "Last Orders repeats give no stats")
