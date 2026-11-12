extends "res://tests/ui/shots/screenshot.gd"
## Repeatable arena evidence from a live core game. Uses the existing screenshot CLI.

const Arena := preload("res://src/ui/arena_geometry.gd")


func _run(screen_name: String, window_size: Vector2i, out_path: String) -> void:
	await process_frame
	var app := App.new()
	root.add_child(app)
	_bot_game(app, BOT_ROUNDS)
	var port: CorePort = app.port as CorePort
	var player: PlayerState = port.session._players[0]
	player.hand.clear()
	player.items.clear()
	player.gold = 30
	port.dev_set_tier(3 if screen_name == "recruit_full" else 6)
	port.refresh()
	var ids: PackedStringArray = [
		"mrs_mallow",
		"grey_agnes",
		"wee_wobbly",
		"mrs_jay",
		"lantern_man",
		"pill_bug",
		"mrs_burdock"
	]
	for slot: int in 7:
		player.board[slot] = RecruitUnit.make(port.library.get_unit(ids[slot]), 6000 + slot)
	if screen_name != "recruit_empty":
		_stage_full_hand(app)
	app.show_recruit()
	var screen: RecruitScreen = app.current as RecruitScreen
	screen.call("_clear_toast")
	if screen_name == "reader":
		screen.call("_on_tapped", "hand", 3)
	elif screen_name == "scouting":
		screen.toggle_scout()
		for key: String in ["_round_label", "_menu_token"]:
			var control: Control = screen.get(key)
			print(
				"arena scouting ",
				key,
				" visible=",
				control.is_visible_in_tree(),
				" rect=",
				control.get_global_rect(),
				" alpha=",
				control.modulate.a
			)
	elif screen_name == "fight":
		var rival: PlayerState = port.session._players[1]
		for slot: int in 7:
			rival.board[slot] = RecruitUnit.make(port.library.get_unit(ids[6 - slot]), 7000 + slot)
		port.set("_fight_standings", Data.a(port.get_state(), "standings").duplicate(true))
		port._fight_health.assign([player.health, rival.health])
		port.set("_fight_ids", [0, 1])
		port.session._fight(0, 1, port.session._damage_cap())
		app.show_game_combat()
		var fight: CombatScreen = app.current as CombatScreen
		fight.auto_return = false
		fight.playing = false
		while fight.next_index < fight.events.size():
			var event: Dictionary = Data.entry(fight.events, fight.next_index)
			fight.call("_play_event", event, false)
			fight.next_index += 1
			if Data.s(event, "type") == "combat_start":
				break
		fight.call("_set_playing", false)
	print("arena: canvas ", app.size, "; unit ", Arena.UNIT * window_size.y / 1080.0)
	await _shoot(window_size, out_path)
