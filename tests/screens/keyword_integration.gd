extends Control
## Frozen views of the real shared components, for the keyword integration screenshots.
const CoreKit := preload("res://tests/core/core_kit.gd")
@export_enum("fight", "dupes", "gather", "golden", "browser_alt") var which: String = "fight"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mode: String = OS.get_environment("BRAMBLE_KEYWORD_INTEGRATION")
	if mode != "":
		which = mode
	if which == "browser_alt":
		await _browser_alt()
	elif which == "fight":
		_fight()
	elif which == "dupes":
		var review: Control = (
			(load("res://tests/screens/shop_review.tscn") as PackedScene).instantiate()
		)
		add_child(review)
		var screen: RecruitScreen = review.get_child(0)
		screen.settle()
		screen.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		_triple()
	print("keyword_integration: ready ", which)


func _triple() -> void:
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = GameFlow.create(content, 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.gold = 30
	CoreKit.put(flow.session, me, "brock-cub", 0)
	me.hand.append(CoreKit.unit(flow.session, "brock-cub"))
	CoreKit.set_shop(flow.session, me, ["brock-cub"] as Array[String])
	var screen: RecruitScreen = (
		(load("res://src/screens/recruit/recruit_screen.tscn") as PackedScene).instantiate()
	)
	screen.state = ViewAdapter.recruit_state(flow)
	add_child(screen)
	screen.settle()
	var first: int = flow.session.events.size()
	assert(flow.act({"type": "buy", "spell": false, "index": 0}) == "")
	screen.show_state(ViewAdapter.recruit_state(flow, "", flow.session.events.slice(first)))
	screen._triple.set_process(false)
	screen._triple._process(0.6 if which == "gather" else 1.0)
	screen.process_mode = Node.PROCESS_MODE_DISABLED
	var run: Dictionary = screen._triple._runs[0]
	for value: Variant in run["sources"]:
		var source: Dictionary = value
		var copy: Control = source["node"]
		print("keyword_integration: source ", source["origin"], " ", _marks(copy))
	var reveal: Control = run["reveal"]
	print("keyword_integration: golden ", _marks(reveal))


func _fight() -> void:
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = GameFlow.create(content, 11)
	flow.start_round()
	var me: PlayerState = flow.human()
	var them: PlayerState = flow.session.player(flow.session.opponent_of(GameFlow.HUMAN))
	for item: Array in [["hedge-knight", 0], ["nettle-skirmisher", 1], ["husk-sentry", 4]]:
		CoreKit.put(flow.session, me, str(item[0]), GlassPieces.as_int(item[1]))
	for item: Array in [["brock-cub", 0], ["needle-pikeman", 1], ["flying-ace", 4]]:
		CoreKit.put(flow.session, them, str(item[0]), GlassPieces.as_int(item[1]))
	flow.session.recruit.refresh_auras(me)
	flow.session.recruit.refresh_auras(them)
	them.turn_ended = true
	var record: Dictionary = flow.finish_round()
	var events: Array = record["events"]
	var replay: FightReplay = FightReplay.build(
		ViewAdapter.fight_base(flow, record),
		events,
		ViewAdapter.catalog(content),
		GlassPieces.as_int(record["damage"])
	)
	var screen: FightScreen = (
		(load("res://src/screens/fight/fight_screen.tscn") as PackedScene).instantiate()
	)
	screen.state = replay.steps[0]["state"]
	add_child(screen)
	screen.settle()
	screen.process_mode = Node.PROCESS_MODE_DISABLED
	for target: Dictionary in screen.targets_of("board"):
		var card: Control = target["node"]
		print("keyword_integration: fight ", _marks(card))


func _browser_alt() -> void:
	var browser: CardBrowser = CardBrowser.new()
	add_child(browser)
	await get_tree().process_frame
	await get_tree().process_frame
	for target: Dictionary in browser._targets:
		var card: Dictionary = target["card"]
		if str(card["id"]) != "hedge-knight":
			continue
		var node: Control = target["node"]
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = node.get_global_transform_with_canvas() * (node.size / 2.0)
		get_viewport().push_input(motion, true)
		var key: InputEventKey = InputEventKey.new()
		key.keycode = KEY_ALT
		key.pressed = true
		get_viewport().push_input(key, true)
		for child: Node in browser._tips.tip.get_node("Words").find_children(
			"*", "KeywordMark", true, false
		):
			var mark: KeywordMark = child
			if CardTerms.key_of(str(mark.term["name"])) == "fury":
				motion.position = mark.get_global_transform_with_canvas() * (mark.size / 2.0)
				get_viewport().push_input(motion, true)
				break
		assert(browser._tips.frozen and browser._tips.details.size() == 1)
		print(
			"keyword_integration: browser frozen=",
			browser._tips.frozen,
			" details=",
			browser._tips.details.size()
		)
		break


static func _marks(node: Control) -> PackedStringArray:
	var words: PackedStringArray = PackedStringArray()
	for child: Node in node.get_children():
		if child is KeywordMark:
			words.append((child as KeywordMark).words)
	return words
