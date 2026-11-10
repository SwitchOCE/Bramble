extends "res://tests/ui/shots/look_live.gd"
## Fixed-frame movie entry point. Custom clips can extend this and override _movie_actions.

const PlayerDriver := preload("res://tests/ui/player_driver.gd")


func _play_until(combat: CombatScreen, _index: int) -> void:
	# Movies restart the fight below; do not spend recording time staging a still.
	combat.playing = false


func _shoot(window_size: Vector2i, ready_path: String) -> void:
	await super._shoot(window_size, ready_path)
	var app: App = root.get_child(root.get_child_count() - 1) as App
	# Shot builders often freeze mid-fight. Record the whole fight from its first event.
	for child: Node in app.get_children():
		if child is CombatScreen:
			(child as CombatScreen).restart()
	var marker: FileAccess = FileAccess.open(ready_path, FileAccess.WRITE)
	marker.store_string(str(Engine.get_frames_drawn()))
	marker.close()
	@warning_ignore("missing_await")
	_movie_actions(app)
	await _movie_frames(OS.get_environment("BRAMBLE_LOOK_FRAMES").to_int())
	quit(0)


func _movie_frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _movie_actions(app: App) -> void:
	if OS.get_environment("BRAMBLE_LOOK_DRIVER") != "1":
		return
	var driver: PlayerDriver = PlayerDriver.new(SEED)
	driver.viewport = root
	var recruit: RecruitScreen = app.current as RecruitScreen
	var beat: int = maxi(1, OS.get_environment("BRAMBLE_LOOK_FPS").to_int())
	await _movie_frames(beat)
	driver.call("_buy_at", recruit, PlayerDriver._first_shop_unit(recruit.state))
	await _movie_frames(beat)
	driver.call("_play_hand", recruit)
	await _movie_frames(beat)
	driver.end_turn(recruit)
	print("look driver: ", driver.counts)
	if not driver.missed_taps.is_empty() or not driver.drop_mismatches.is_empty():
		printerr("look driver: failed ", driver.missed_taps, driver.drop_mismatches)
		quit(1)
