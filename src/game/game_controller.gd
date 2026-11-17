class_name GameController
extends Control
## One game on screen: the recruit screen while the human recruits, the fight screen for the
## human's fight, then the next round, until the human is out or wins. It owns a GameFlow and
## draws its state through ViewAdapter; the screens hold no rules.
##   recruit: the player acts at their own pace; no turn timer in this build; End turn ends it
##   fight: one rule for Space, Enter and a left click alike (other keys do nothing, so Alt+Tab
##     or a screenshot never skips): while the fight plays, the input shows the result at once;
##     with the result on screen, the next input moves on (else AFTER_FIGHT seconds). An input in
##     the first RESULT_GUARD seconds of the fight or of the result is taken and does nothing, so
##     a double click on End turn never skips the fight, and a press meant to skip never also
##     moves on unseen. Escape opens the pause panel. With the result on
##     screen the leaderboard shows everyone's Health and your counters after the round
##   end: once the human is out, the bots finish the game, and game_finished gives the places
## Autoplay (F8 in a debug build, or `autoplay` set): a FlowBot plays the human's turns and
## fights are skipped, to reach the end quickly when testing.

signal game_finished(standings: Array[Dictionary], round_number: int)

enum Phase { NONE, RECRUIT, FIGHT, AFTER_FIGHT, PLAY_OUT, OVER }

const RECRUIT_SCENE: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const FIGHT_SCENE: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")
## How long the result and the round's leaderboard stay without a click or key.
const AFTER_FIGHT: float = 2.5
## How long the result stays on screen before an input may move on, in seconds.
const RESULT_GUARD: float = 0.4
## The keys that skip a fight or move on from its result (with a left click).
const SKIP_KEYS: Array[Key] = [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
const SKIP_HINT: String = "Space or click to skip"
## STAND-IN words while the bots finish a game the human is out of.
const PLAY_OUT_WORDS: String = "The others play on"
## How long the bots may play on in one frame, in milliseconds.
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
var _autoplayer: FlowBot
var _auto_wait: float = 0.0
## A notice for the next recruit turn (gold the last fight earned), "" for none.
var _notice: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Starts a game on this content. Call once the controller is in the tree.
func start(content: GameContent, game_seed: int, tribes: PackedStringArray = []) -> void:
	flow = GameFlow.create(content, game_seed, tribes)
	print("game seed: %d (replay with: -- --seed %d)" % [game_seed, game_seed])
	_catalog = ViewAdapter.catalog(content)
	_autoplayer = FlowBot.new(Rng.derive(game_seed, "autoplay"))
	recruit = RECRUIT_SCENE.instantiate()
	recruit.name = "Recruit"
	add_child(recruit)
	# sized now, not at the next layout pass: the screen centres its stage on its size
	recruit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# the contract's one signal, in the core's action format; the screen draws Discover itself
	recruit.action_requested.connect(request)
	fight = FIGHT_SCENE.instantiate()
	fight.name = "Fight"
	fight.visible = false
	add_child(fight)
	fight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fight.result_shown.connect(_on_playback_finished)
	fight.playback_finished.connect(_on_playback_finished)
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
	if not record.is_empty():
		var events: Array = CoreUtil.to_array(record["events"])
		var gold: int = ViewAdapter.fight_gold(events, CoreUtil.to_int(record["you_side"]))
		if gold > 0:
			_notice = "+%d gold from the last fight" % gold
	if record.is_empty() or autoplay:
		_after_fight()
		return
	phase = Phase.FIGHT
	_fight_age = 0.0
	var base: Dictionary = ViewAdapter.fight_base(flow, record)
	var replay: FightReplay = FightReplay.build(
		base, CoreUtil.to_array(record["events"]), _catalog, CoreUtil.to_int(record["damage"])
	)
	_show_only(fight)
	fight.show_leaderboard = false
	fight.show_state(base)
	_set_hint(true)
	fight.play(replay)


func _on_playback_finished() -> void:
	if phase != Phase.FIGHT:
		return
	_set_hint(false)
	phase = Phase.AFTER_FIGHT
	_after_wait = AFTER_FIGHT
	_result_age = 0.0
	# the round is over: everyone's Health now, on the leaderboard
	var state: Dictionary = fight.state.duplicate()
	state["players"] = ViewAdapter.players(flow)
	state["health"] = maxi(0, flow.human().health)
	# the counters and heaps after the fight and its after-fight effects
	state["counters"] = ViewAdapter.counters(flow.content, flow.session.view_for(GameFlow.HUMAN))
	var opponent: Dictionary = CoreUtil.to_dict(state.get("opponent", {})).duplicate()
	var last: Dictionary = flow.last_fight
	if not last.is_empty():
		var them: Dictionary = flow.opponent_view(CoreUtil.to_int(last["opponent"]))
		opponent["health"] = maxi(0, CoreUtil.to_int(them.get("health", 0)))
	state["opponent"] = opponent
	fight.show_leaderboard = true
	fight.show_state(state)


func _after_fight() -> void:
	if flow.is_over() or not flow.human_alive():
		phase = Phase.OVER
		if not flow.is_over():
			# the bots finish the game a few rounds a frame, the leaderboard showing it
			phase = Phase.PLAY_OUT
			fight.show_leaderboard = true
			_set_hint(true, PLAY_OUT_WORDS)
			_show_play_out()
			return
		_finish()
		return
	_next_round()


## The leaderboard while the bots play on, with a line saying so.
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
	# the round the human went out in; the last round when they won
	var out: int = flow.out_round if flow.out_round > 0 else flow.session.round_number
	game_finished.emit(flow.standings(), out)


func _set_hint(on: bool, words: String = SKIP_HINT) -> void:
	if _hint != null:
		remove_child(_hint)
		_hint.queue_free()
		_hint = null
	if not on:
		return
	_hint = GlassUi.stage(self)
	_hint.name = "SkipHint"
	_hint.z_index = 50
	GlassUi.title(_hint, words, 960, 1040, 22, GlassUi.MUTED)


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
				_auto_wait -= delta
				if _auto_wait <= 0.0:
					_auto_wait = 0.05
					request(_autoplayer.choose(flow.session, flow.human()))


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo:
		if key.keycode == KEY_F8 and OS.is_debug_build():
			autoplay = not autoplay
			get_viewport().set_input_as_handled()
			return
		if key.keycode in [KEY_ESCAPE, KEY_F11, KEY_TAB]:
			return
	var click: InputEventMouseButton = event as InputEventMouseButton
	var skip: bool = (
		(key != null and key.pressed and not key.echo and key.keycode in SKIP_KEYS)
		or (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
	)
	if not skip:
		return
	if phase == Phase.FIGHT:
		# to the result at once, every card already in its place; the next input moves on
		get_viewport().set_input_as_handled()
		if _fight_age < RESULT_GUARD:
			return
		fight.skip()
		fight.settle()
		_on_playback_finished()
	elif phase == Phase.AFTER_FIGHT:
		# handled first: the game's end takes this controller out of the tree
		get_viewport().set_input_as_handled()
		if _result_age >= RESULT_GUARD:
			_after_fight()


## Shows one screen. The hidden one is disabled too, so it gets no input (a hidden screen still
## hears keys such as Tab) and runs no tweens.
func _show_only(screen: Control) -> void:
	for each: Control in [recruit, fight]:
		var on: bool = each == screen
		each.visible = on
		each.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
