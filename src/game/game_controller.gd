class_name GameController
extends Control
## One game on screen: the recruit screen while the human recruits, the fight screen for the
## human's fight, then the next round, until the human is out or wins. It owns a GameFlow and
## draws its state through ViewAdapter; the screens hold no rules.
##   recruit: the player acts at their own pace; no turn timer in this build; End turn ends it
##   fight: Skip or Space shows the result. The result advances with Space,
##     or after AFTER_FIGHT seconds. Both phases guard against skipping in their first
##     RESULT_GUARD seconds. Escape opens the pause panel. The result's leaderboard shows
##     everyone's Health and your counters after the round
##   end: once the human is out, the ghosts finish the game, and game_finished gives the places
## Autoplay (F8 in a debug build, or `autoplay` set): a test bot plays the human's turns and
## fights are skipped, to reach the end quickly when testing.

signal game_finished(standings: Array[Dictionary], round_number: int)
signal cards_requested

enum Phase { NONE, RECRUIT, PAST_BOARDS, FIGHT, AFTER_FIGHT, PLAY_OUT, OVER }

const RECRUIT_SCENE: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const FIGHT_SCENE: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")
## How long the result and the round's leaderboard stay without a key press.
const AFTER_FIGHT: float = 2.5
## How long the result stays on screen before an input may move on, in seconds.
const RESULT_GUARD: float = 0.4
## The keys that skip a fight or move on from its result.
const SKIP_KEYS: Array[Key] = [KEY_SPACE]
## Words while the ghosts finish a game the human is out of.
const PLAY_OUT_WORDS: String = "The others play on"
## How long the ghosts may play on in one frame, in milliseconds.
const PLAY_OUT_BUDGET: int = 25

var flow: GameFlow
var autoplay: bool = false
var phase: Phase = Phase.NONE
var recruit: RecruitScreen
var fight: FightScreen
var _hint: Control
var _catalog: Dictionary = {}
var _after_wait: float = 0.0
## Seconds since the result came on screen.
var _result_age: float = 0.0
## How long the fight has played, for the same guard at its start.
var _fight_age: float = 0.0
var _autoplayer: SimpleBot
var _auto_wait: float = 0.0
var _past_boards: Array[Dictionary] = []
var _past_screen: FightScreen
var _past_controls: Control
var _past_button: Control
## A notice for the next recruit turn (gold the last fight earned), "" for none.
var _notice: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Starts the matched game once the controller is in the tree.
func start(matched: GameFlow) -> void:
	flow = matched
	print("game seed: %d" % flow.game_seed)
	_catalog.clear()
	recruit = RECRUIT_SCENE.instantiate()
	recruit.name = "Recruit"
	add_child(recruit)
	# sized now, not at the next layout pass: the screen centres its stage on its size
	recruit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# the contract's one signal, in the core's action format; the screen draws Discover itself
	recruit.action_requested.connect(request)
	recruit.cards_requested.connect(cards_requested.emit)
	fight = FIGHT_SCENE.instantiate()
	fight.name = "Fight"
	fight.visible = false
	add_child(fight)
	fight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fight.result_shown.connect(_on_playback_finished)
	fight.playback_finished.connect(_on_playback_finished)
	fight.health_counted.connect(_on_health_counted)
	fight.skip_requested.connect(_skip_fight)
	var tools: Control = GlassUi.stage(self)
	tools.z_index = 8
	_past_button = GlassUi.button(tools, "Past boards", Vector2(38, 218), 170, _open_past_boards)
	_show_only(recruit)
	_next_round()


## An action from the player, in the core's format. A refusal is shown as the message.
func request(action: Dictionary) -> void:
	if phase != Phase.RECRUIT:
		return
	var first: int = flow.session.events.size()
	var reason: String = flow.act(action)
	if reason == "" and str(action.get("type", "")) == "end_turn":
		_end_round()
		return
	_show_recruit(reason, flow.session.events.slice(first))


func _next_round() -> void:
	flow.start_round()
	phase = Phase.RECRUIT
	_show_only(recruit)
	_set_hint(false)
	_show_recruit(_notice)
	_notice = ""


func _show_recruit(message: String, events: Array = []) -> void:
	recruit.show_state(ViewAdapter.recruit_state(flow, message, events))


func _end_round() -> void:
	var record: Dictionary = flow.finish_round()
	_notice = ""
	if record.is_empty():
		_after_fight()
		return
	var events: Array = CoreUtil.to_array(record["events"])
	var base: Dictionary = ViewAdapter.fight_base(flow, record)
	var gold: int = ViewAdapter.fight_gold(events, CoreUtil.to_int(record["you_side"]))
	if gold > 0:
		_notice = "+%d gold from the last fight" % gold
	if autoplay:
		ViewAdapter.add_fight_cards(flow.content, [events[0]], _catalog)
		var opening: FightReplay = FightReplay.start(base, _catalog)
		opening.apply(CoreUtil.to_dict(events[0]))
		_past_boards.append(opening.steps[0]["state"])
		_after_fight()
		return
	phase = Phase.FIGHT
	_fight_age = 0.0
	ViewAdapter.add_fight_cards(flow.content, events, _catalog)
	var replay: FightReplay = FightReplay.build(
		base, events, _catalog, CoreUtil.to_int(record["damage"]), _big_loss(record)
	)
	_past_boards.append(replay.steps[0]["state"])
	_show_only(fight)
	fight.show_leaderboard = false
	fight.show_skip = true
	fight.show_state(base)
	fight.play(replay)


## Whether the human's last fight was a big loss (the session's, rulebook 10.1.2).
static func _big_loss(record: Dictionary) -> bool:
	return record.get("big", false) == true


func _on_playback_finished() -> void:
	if phase != Phase.FIGHT:
		return
	fight.show_skip = false
	phase = Phase.AFTER_FIGHT
	_after_wait = AFTER_FIGHT
	_result_age = 0.0
	# the round's Health shows once the loser's has landed (the portrait strike's count)
	if fight.health_landed():
		_show_round_health()


## The loser's Health has landed on the fight screen (the portrait strike's count, or a skip).
func _on_health_counted() -> void:
	if phase == Phase.AFTER_FIGHT:
		_show_round_health()


## The round is over: everyone's Health now, on the leaderboard.
func _show_round_health() -> void:
	var state: Dictionary = fight.state.duplicate()
	state["players"] = ViewAdapter.players(flow)
	state["health"] = maxi(0, flow.human().health)
	# the counters and heaps after the fight and its after-fight effects
	state["counters"] = ViewAdapter.counters(flow.content, flow.session.view_for(GameFlow.HUMAN))
	var opponent: Dictionary = CoreUtil.to_dict(state.get("opponent", {})).duplicate()
	var last: Dictionary = flow.last_fight
	if not last.is_empty():
		var seat: int = CoreUtil.to_int(last["opponent"])
		if seat >= 0:
			opponent["health"] = flow.opponent_health(seat)
	state["opponent"] = opponent
	fight.show_leaderboard = true
	fight.show_state(state)


func _after_fight() -> void:
	if flow.is_over() or not flow.human_alive():
		phase = Phase.OVER
		if not flow.is_over():
			# the ghost lobby finishes over several frames, with the leaderboard showing it
			phase = Phase.PLAY_OUT
			fight.show_leaderboard = true
			_set_hint(true)
			_show_play_out()
			return
		_finish()
		return
	_next_round()


## The leaderboard while the ghosts play on, with a line saying so.
func _show_play_out() -> void:
	var state: Dictionary = fight.state.duplicate()
	state["players"] = ViewAdapter.players(flow)
	var moment: Dictionary = CoreUtil.to_dict(state.get("moment", {})).duplicate()
	moment.erase("result")
	state["moment"] = moment
	fight.show_state(state)


func _finish() -> void:
	phase = Phase.OVER
	_set_hint(false)
	flow.save_player_run()
	if autoplay and flow.session.record != null:
		print("game record: %s" % flow.session.record.path)
	# the round the human went out in; the last round when they won
	var out: int = flow.out_round if flow.out_round > 0 else flow.session.round_number
	game_finished.emit(flow.standings(), out)


func _open_past_boards() -> void:
	if phase != Phase.RECRUIT or recruit.is_holding() or _past_boards.is_empty():
		return
	phase = Phase.PAST_BOARDS
	_show_only(null)
	_past_screen = FIGHT_SCENE.instantiate()
	_past_screen.name = "PastBoards"
	add_child(_past_screen)
	_show_past_board(_past_boards.size() - 1)


func _show_past_board(index: int) -> void:
	_past_screen.show_state(_past_boards[index])
	_past_screen.settle()
	if _past_controls != null:
		remove_child(_past_controls)
		_past_controls.queue_free()
	_past_controls = GlassUi.stage(self)
	_past_controls.z_index = 8
	var round_number: int = CoreUtil.to_int(_past_boards[index]["turn"])
	GlassUi.title(_past_controls, "Fight from round %d" % round_number, 960, 14, 24)
	GlassUi.button(_past_controls, "Back to recruit", Vector2(810, 1000), 300, _close_past_boards)
	if index > 0:
		GlassUi.button(
			_past_controls, "Previous", Vector2(550, 1000), 240, _show_past_board.bind(index - 1)
		)
	if index + 1 < _past_boards.size():
		GlassUi.button(
			_past_controls, "Next", Vector2(1130, 1000), 240, _show_past_board.bind(index + 1)
		)


func _close_past_boards() -> void:
	remove_child(_past_screen)
	_past_screen.queue_free()
	_past_screen = null
	remove_child(_past_controls)
	_past_controls.queue_free()
	_past_controls = null
	phase = Phase.RECRUIT
	_show_only(recruit)


func _set_hint(on: bool) -> void:
	if _hint != null:
		remove_child(_hint)
		_hint.queue_free()
		_hint = null
	if not on:
		return
	_hint = GlassUi.stage(self)
	_hint.name = "PlayOutHint"
	_hint.z_index = 50
	GlassUi.title(_hint, PLAY_OUT_WORDS, 960, 1040, 22, GlassUi.MUTED)


func _process(delta: float) -> void:
	match phase:
		Phase.FIGHT:
			_fight_age += delta
		Phase.PLAY_OUT:
			var began: int = Time.get_ticks_msec()
			while Time.get_ticks_msec() - began < PLAY_OUT_BUDGET:
				if flow.play_out_round():
					_finish()
					return
			_show_play_out()
		Phase.AFTER_FIGHT:
			_result_age += delta
			_after_wait -= delta
			if _after_wait <= 0.0:
				_after_fight()
		Phase.RECRUIT:
			if autoplay:
				if _autoplayer == null:
					_autoplayer = SimpleBot.new(Rng.derive(flow.game_seed, "autoplay"))
				_auto_wait -= delta
				if _auto_wait <= 0.0:
					_auto_wait = 0.05
					request(_autoplayer.choose(flow.session, flow.human()))


func _input(event: InputEvent) -> void:
	# The Compost is a live overlay and keeps its own input.
	if (recruit != null and recruit._compost != null) or (fight != null and fight._compost != null):
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo:
		if key.keycode == KEY_ESCAPE and phase == Phase.PAST_BOARDS:
			_close_past_boards()
			get_viewport().set_input_as_handled()
			return
		if key.keycode == KEY_F8 and OS.is_debug_build():
			autoplay = not autoplay
			get_viewport().set_input_as_handled()
			return
		if key.keycode in [KEY_ESCAPE, KEY_F11, KEY_TAB]:
			return
	if key == null or not key.pressed or key.echo or key.keycode not in SKIP_KEYS:
		return
	if phase == Phase.FIGHT:
		get_viewport().set_input_as_handled()
		_skip_fight()
	elif phase == Phase.AFTER_FIGHT:
		# handled first: the game's end takes this controller out of the tree
		get_viewport().set_input_as_handled()
		if _result_age >= RESULT_GUARD:
			_after_fight()


func _skip_fight() -> void:
	if phase != Phase.FIGHT or _fight_age < RESULT_GUARD or fight._compost != null:
		return
	fight.skip()
	fight.settle()
	_on_playback_finished()


## Shows one screen. The hidden one is disabled too, so it gets no input (a hidden screen still
## hears keys such as Tab) and runs no tweens.
func _show_only(screen: Control) -> void:
	_past_button.visible = screen == recruit and not _past_boards.is_empty()
	for each: Control in [recruit, fight]:
		var on: bool = each == screen
		each.visible = on
		each.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
