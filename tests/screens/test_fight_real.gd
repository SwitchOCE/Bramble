extends GutTest
## A real tribe fight through the real fight screen: shipped cards on both boards (a badger given
## Fury by a Master-at-Arms against an outnumbering mouse board with Hand-me-down and a slot
## bonus), the core's own fight log, ViewAdapter's fight state and FightReplay, played by
## FightScreen to the end. The pills and numbers are checked against the core.

const SlotChecks := preload("res://tests/screens/slot_assertions.gd")

const CoreKit := preload("res://tests/core/core_kit.gd")
const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")

const BADGERS: Dictionary = {0: "armsbearer"}
const MICE: Dictionary = {
	0: "bell-ringer", 1: "hedgerow-scout", 2: "hedgerow-scout", 3: "bell-ringer"
}

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_a_real_badger_and_mouse_fight_plays_through_the_screen() -> void:
	if _content.tribe_name("badger") == "" or _content.tribe_name("mouse") == "":
		pass_test("no badger or mouse folder")
		return
	var flow: GameFlow = FlowFixture.live(_content, 11)
	flow.start_round()
	var session: GameSession = flow.session
	var me: PlayerState = flow.human()
	for slot: Variant in BADGERS:
		CoreKit.put(session, me, str(BADGERS[slot]), CoreUtil.to_int(slot))
	# what a Master-at-Arms gives: +1 Fury of its own, on top of any it prints
	var bearer: Unit = me.board[0]
	assert_true(bearer.grant_effect(session.registry, &"badger_fury", {"fury": 1}))
	var them: PlayerState = session.player(session.opponent_of(GameFlow.HUMAN))
	for slot: Variant in MICE:
		CoreKit.put(session, them, str(MICE[slot]), CoreUtil.to_int(slot))
	them.slots[0].renown = 2
	session.recruit.refresh_auras(me)
	session.recruit.refresh_auras(them)
	# their board stays as set: the bot has had its turn
	them.turn_ended = true
	var shop: Dictionary = ViewAdapter.recruit_state(flow)["board"][0]
	var shop_terms: Array = shop["mechanics"]
	assert_has(shop_terms, "badger_fury", "the shop shows the given Fury")
	var record: Dictionary = flow.finish_round()
	assert_false(record.is_empty(), "the human fought")
	var events: Array = record["events"]
	var you: int = CoreUtil.to_int(record["you_side"])
	var replay: FightReplay = FightReplay.build(
		ViewAdapter.fight_base(flow, record),
		events,
		ViewAdapter.catalog(_content),
		CoreUtil.to_int(record["damage"])
	)
	var screen: FightScreen = SCREEN.instantiate()
	add_child_autofree(screen)
	assert_eq(SlotChecks.check(screen), PackedStringArray(), "initial slot rows")
	screen.play(replay)
	# the first step: both boards whole, the badger's Fury pill as in the shop
	var first: Dictionary = replay.steps[0]["state"]
	var start_bearer: Dictionary = first["boards"][you][0]
	var table: Dictionary = first["display"]
	var start_words: PackedStringArray = _all_words(start_bearer, table)
	assert_true(" ".join(start_words).contains("Fury"), "Fury in the fight too: %s" % start_words)
	assert_eq(start_words, _all_words(shop, table), "the same pills in the shop and the fight")
	var outnumbered: Array = first.get("outnumbered", [])
	assert_eq(outnumbered.size(), 2, "the fight's outnumbered counts reach the screen")
	assert_gt(CoreUtil.to_int(outnumbered[you]), 0, "the badgers are outnumbered")
	assert_has(
		screen._reminders(start_bearer),
		"Outnumbered by %d." % CoreUtil.to_int(outnumbered[you]),
		"and its hover says so"
	)
	assert_null(screen.find_child("Outnumbered_*", true, false), "no label on the board")
	# to the end
	for _guard: int in 2000:
		if not screen.is_playing():
			break
		screen._process(0.1)
	assert_false(screen.is_playing(), "the fight played to its end")
	var end: Dictionary = events[events.size() - 1]
	assert_eq(str(end["type"]), "combat_end")
	var survivors: Array = end["survivors"]
	for side: int in 2:
		var drawn: Array = []
		for unit: Dictionary in replay.summary(side):
			drawn.append(CoreUtil.to_int(unit["uid"]))
		var core: Array = []
		for uid: Variant in survivors[side]:
			core.append(CoreUtil.to_int(uid))
		drawn.sort()
		core.sort()
		assert_eq(drawn, core, "side %d: the survivors the core names" % side)
	# every drawn card shows the replay's numbers, none below 0
	for target: Dictionary in screen.targets_of("board"):
		var card: GlassCard = target["node"]
		var unit: Dictionary = target["card"]
		assert_eq(card.attack, CoreUtil.to_int(unit["attack"]))
		assert_eq(card.health, maxi(0, CoreUtil.to_int(unit["health"])))
		assert_true(card.health >= 0)
	# every number drawn green or red says where it comes from, at every step
	for step: Dictionary in replay.steps:
		var view: Dictionary = step["state"]
		for row: Variant in view["boards"]:
			for value: Variant in row:
				if not value is Dictionary:
					continue
				var unit: Dictionary = value
				var changed: bool = (
					CoreUtil.to_int(unit["attack"]) != CoreUtil.to_int(unit["base_attack"])
					or CoreUtil.to_int(unit["health"]) != CoreUtil.to_int(unit["base_health"])
				)
				if changed:
					assert_false(
						CoreUtil.to_array(unit.get("sources", [])).is_empty(),
						"%s %s/%s has its reasons" % [unit["name"], unit["attack"], unit["health"]]
					)


## One pill per keyword, and a used one dimmed: a Molt with no charge left and a Root that has
## returned its unit (the core's `uses` and `status` events) show one faint pill each.
func test_used_up_keywords_show_one_dimmed_pill() -> void:
	if _content.tribe_name("locust") == "" or _content.tribe_name("thorn") == "":
		pass_test("no locust or thorn folder")
		return
	var catalog: Dictionary = ViewAdapter.catalog(_content)
	var table: Dictionary = _content.display_table()
	var replay: FightReplay = FightReplay.start({"you_side": 0, "display": table}, catalog)
	var husk: Dictionary = {"uid": 1, "id": "husk-sentry", "slot": 0, "attack": 3, "health": 3}
	husk["keywords"] = ["taunt", "locust_molt"]
	var sapling: Dictionary = {
		"uid": 2, "id": "blackthorn-sapling", "slot": 1, "attack": 5, "health": 6
	}
	replay.apply({"type": "combat_start", "boards": [[husk, sapling], []]})
	var row: Array = replay.boards[0]
	var husk_now: Dictionary = row[0]
	for pill: Dictionary in CardTerms.all_pills(husk_now, table):
		assert_false(CoreUtil.to_bool(pill["spent"]), "nothing used yet")
	replay.apply({"type": "uses", "uid": 1, "side": 0, "slot": 0, "key": "locust_molt", "left": 0})
	replay.apply(
		{"type": "status", "uid": 1, "side": 0, "slot": 0, "status": "locust_molt", "on": false}
	)
	replay.apply(
		{"type": "status", "uid": 2, "side": 0, "slot": 1, "status": "thorn_root", "on": false}
	)
	for k: int in 2:
		var term: String = "Molt" if k == 0 else "Root"
		var found: int = 0
		var names: PackedStringArray = []
		var unit: Dictionary = row[k]
		for pill: Dictionary in CardTerms.all_pills(unit, table):
			names.append(str(pill["name"]))
			if str(pill["name"]).begins_with(term):
				found += 1
				assert_true(CoreUtil.to_bool(pill["spent"]), "%s dimmed once used" % term)
		assert_eq(found, 1, "one %s pill: %s" % [term, names])


static func _all_words(unit: Dictionary, table: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for pill: Dictionary in CardTerms.all_pills(unit, table):
		out.append(str(pill["words"]))
	return out
