extends Control
## Reproducible before/after shots: real purchases, board gaps, and a real fight after a death.
## Run with Compatibility/Xvfb at either requested window resolution, then -- --out=/path.

const CoreKit := preload("res://tests/core/core_kit.gd")
const StandIn := preload("res://tests/screens/fight_stand_in.gd")


func _ready() -> void:
	var out: String = "/tmp/bramble-slots"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var content: GameContent = GameContent.load_default()
	assert(content.errors.is_empty())
	var flow: GameFlow = GameFlow.create(content, 3)
	flow.start_round()
	flow.human().gold = 30
	CoreKit.put(flow.session, flow.human(), "brock-cub", 0)
	CoreKit.put(flow.session, flow.human(), "hedge-knight", 3)
	CoreKit.put(flow.session, flow.human(), "lance-corporal", 5)
	assert(flow.act({"type": "buy", "spell": false, "index": 1}) == "")
	assert(flow.act({"type": "buy", "spell": true, "index": 0}) == "")
	var recruit: RecruitScreen = RecruitScreen.new()
	recruit.size = get_viewport_rect().size
	recruit.state = ViewAdapter.recruit_state(flow)
	add_child(recruit)
	recruit.settle()
	await _shot(out, "shop-after-buy")
	var gaps: Dictionary = GlassScreen.load_state(
		"res://tests/screens/fixtures/recruit_mockup.json"
	)
	var board: Array = gaps["board"]
	board[1] = null
	board[4] = null
	recruit.show_state(gaps)
	recruit.settle()
	await _shot(out, "board-gaps")
	remove_child(recruit)
	recruit.free()
	var game: GameSession = CoreKit.session(7)
	var spec: Array = StandIn.FIGHTS[0]
	var spec_a: Dictionary = spec[0]
	var spec_b: Dictionary = spec[1]
	var combat: Combat = CoreKit.fight(
		game, CoreKit.board(game, spec_a), CoreKit.board(game, spec_b), 11
	)
	var base: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/fight_start.json")
	base["slots"] = [[], []]
	var replay: FightReplay = FightReplay.build(base, combat.events, StandIn.catalog(game), 7)
	var after_death: bool = false
	var chosen: Dictionary = {}
	for step: Dictionary in replay.steps:
		if str(step["kind"]) == "death":
			after_death = true
		var view: Dictionary = step["state"]
		var moment: Dictionary = view["moment"]
		if after_death and moment.has("lunge"):
			chosen = view
			break
	assert(not chosen.is_empty(), "a real death followed by another attack")
	var fight: FightScreen = FightScreen.new()
	fight.size = get_viewport_rect().size
	fight.state = chosen
	add_child(fight)
	fight.settle()
	await _shot(out, "fight-after-death")
	print("slots_capture: ", out, " at ", get_viewport().get_visible_rect().size)
	get_tree().quit()


func _shot(out: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var result: Error = DisplayServer.screen_get_image(0).save_png(out.path_join(label + ".png"))
	assert(result == OK)
