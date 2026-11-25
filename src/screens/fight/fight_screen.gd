# gdlint: disable=max-file-lines
class_name FightScreen
extends GlassScreen
## The fight screen in lead and stained glass, rebuilt from fight.html: the shared window, hero,
## leaderboard and hover (GlassScreen), with the opponent's board in the shop's light, its front
## row facing yours across the transom. It draws one plain view state (show_state) and can play a
## fight log through FightReplay (play). It holds no rules.
##
## The view state (tests/screens/fixtures/fight_start.json and fight_mid.json are examples):
##   turn, health, hero, players: as the recruit screen's
##   opponent: {name, portrait, health}
##   you_side: which of the two boards is yours (the rules core's side, 0 or 1)
##   boards: [side 0, side 1], each 7 entries, unit or null, slots 0-6 in reading order
##   slots: [side 0, side 1], each 7 {keywords: [{id}], label, renown} or {}
##     (a slot's lasting bonus, as GlassScreen.slot_info reads it)
##   unit: {id, uid, name, tier, art, attack, health, max_health, text, keywords: [id],
##     mechanics: [id], amounts: {mechanic: n}, counters: [{id, value}], renown}: Health under
##     max_health is drawn red; keywords and counters are STAND-IN pills on the card (the mock-up
##     has none); `renown` is the amount shown on the unit's own Renown pill
##   moment: {lunge: {side, slot, target_side, target_slot}, splashes: [{side, slot, amount,
##     blocked}] (amount 0: destroyed; blocked: a prevented hit, drawn as a 0),
##     trigger: {side, slot} (the unit whose effect is acting),
##     result: {winner, damage}}: what is happening right now; all of it optional
##
## A fight plays from its schedule (FightTimeline, made from the replay): on a game clock, each
## step's view state shows from its frame, and every frame each card is posed from the schedule
## (where it stands plus its offset, scale, turn and light), the damage bursts, glows and stat
## gains (FightGains) are drawn, and the sound cues play (SoundCues.for_fight_cue). Late in a fight
## the clock runs faster (FightTimeline.advance, FAST). The keeper still draws the boards, the
## numbers, the deaths (FightMotion's fall) and the result. A unit dying on its own goes dark and
## sinks from the schedule (CB13 c, FightTimeline.death_pose), the number that killed it held on
## through it. After the result the winner's portrait strikes the loser's and the loser's Health
## counts down (CB12 b, FightTimeline.hero_strike, on its own game clock past the fight's end); Skip
## lands it at once. Shown on its own, a moment's lunge,
## splashes and trigger are drawn at rest, and a change of moment moves with FightMotion. Red
## Health and the result banner retain the glass mock-up's drawing.

## The fight is over and its result is showing.
signal playback_finished
## The result is on the screen (its hold has just begun): the flow may move on from here.
signal result_shown
## The player clicked the Skip button.
signal skip_requested
## The loser's Health has landed (the portrait strike's count ended, or a skip): the round's
## Health may show everywhere now.
signal health_counted

const FIGHT_READY_LINE: String = "fight_screen: ready"
## How long the attacker takes to lunge, in seconds at speed 1.
const LUNGE_TIME: float = FightMotion.ATTACK_TIME
## STAND-IN: how far a unit whose effect is acting lifts in place, and how fast.
const TRIGGER_LIFT: float = 14.0
const TRIGGER_TIME: float = 0.1
## STAND-IN: how much of the attacker's lunge a unit joining the attack moves.
const JOIN_SHARE: float = 0.6
## STAND-IN: the hover line of a unit whose terms count being outnumbered, while its side is.
const OUTNUMBERED_WORDS: String = "Outnumbered by %d."

## The burst: pop in, settle, read, fade (frames); best.md: readable to C+30, gone by C+40.
const BURST_POP_F: int = 3
const BURST_SETTLE_F: int = 5
const BURST_READ_F: int = 20
const BURST_FADE_F: int = 8

## The portrait strike over the board and the banner, the Health badge and the "-N" above the
## striker, so it never hides them (E6).
const STRIKE_PORTRAIT_Z: int = 20
const STRIKE_BADGE_Z: int = 21
const STRIKE_BURST_Z: int = 22

## Playback speed: 2 plays twice as fast.
@export var speed: float = 1.0
## The live controller shows Skip during playback. A comparison scene can also show it.
@export var show_skip: bool = false

var _skip_button: Button
var _replay: FightReplay
## The step of the replay showing now.
var _step: int = -1
## The schedule being played, from play() until the result's hold ends.
var _schedule: FightTimeline
## Game time since play(), in schedule frames (1/60 s at speed 1).
var _clock: float = 0.0
var _running: bool = false
## The next step, burst and sound cue of the schedule to show.
var _step_due: int = 0
var _burst_due: int = 0
var _cue_due: int = 0
## key -> where the card stands (its slot), from the state shown
var _rest_at: Dictionary = {}
## [{node, key, recipient, offset, from, merge}]: the bursts showing
var _bursts_on: Array[Dictionary] = []
## card instance id -> whether it is drawn glowing
var _glow_on: Dictionary = {}
## The stat gains' pieces (CB14 c), drawn from the schedule.
var _gains: FightGains
## Last visual beats: state refreshes must not replay an attack or recoil.
var _shown_lunge: Dictionary = {}
var _shown_splashes: Array = []
var _attack_start: bool = false
var _impact_start: bool = false
var _recoiled: bool = false
## CB12 b: game frames since the result showed (-1 before), and where the strike is: "" none,
## "playing", "skipped" (landed at once) or "over".
var _strike_age: float = -1.0
var _strike_mode: String = ""
var _health_landed: bool = false


func _geom() -> Dictionary:
	return GlassPieces.fight_geom()


func _ready_line() -> String:
	return FIGHT_READY_LINE


func _leaderboard_key() -> String:
	return "stage.fight.leaderboard"


func _make_tips() -> GlassTips:
	var tips: GlassTips = super()
	tips.fixed_keywords = true
	return tips


func _ensure_stage() -> void:
	super()
	if not _keeper is FightMotion:
		_keeper = FightMotion.new(_cards)


func _on_new_state() -> void:
	var shown_moment: Dictionary = state.get("moment", {})
	if not shown_moment.has("result") and _strike_mode != "":
		_end_strike()
	var lunge: Dictionary = _lunge()
	_attack_start = not lunge.is_empty() and lunge != _shown_lunge
	if lunge != _shown_lunge or lunge.is_empty():
		_recoiled = false
	_shown_lunge = lunge.duplicate()
	var moment: Dictionary = state.get("moment", {})
	var splashes: Array = moment.get("splashes", [])
	_impact_start = not splashes.is_empty() and splashes != _shown_splashes
	_shown_splashes = splashes.duplicate(true)
	# A fixture opened on a single moment shows that moment at rest (including contact).
	if _keeper._kept.is_empty():
		_attack_start = false
		_impact_start = false
		return
	if not splashes.is_empty():
		_recoiled = true


# ---- playback ----


## Plays a fight from its schedule (FightTimeline; made here when the replay has none yet).
func play(replay: FightReplay) -> void:
	# a new fight starts from a clean table: no card of the last fight is left fading or popping
	if _keeper != null:
		_keeper.clear()
	_drop_bursts()
	_gain_pieces().clear()
	if replay.plan == null:
		schedule(replay)
	_replay = replay
	_schedule = replay.plan
	_shown_lunge = {}
	_shown_splashes = []
	_recoiled = false
	_step = -1
	_clock = 0.0
	_step_due = 0
	_burst_due = 0
	_cue_due = 0
	_glow_on.clear()
	_end_strike()
	(_keeper as FightMotion).drawn_deaths = _schedule.single_deaths
	_running = true
	_show_due()
	_pose_all()
	_gain_pieces().draw(_schedule, _clock)


## Makes a replay's schedule with the fight screen's own layout, from a screen never shown.
static func schedule(replay: FightReplay) -> void:
	var probe: FightScreen = FightScreen.new()
	var first: Dictionary = replay.steps[0]["state"] if not replay.steps.is_empty() else {}
	probe.state = {"you_side": _i(first.get("you_side", 0))}
	probe._g = GlassPieces.fight_geom()
	replay.schedule(probe.unit_xy)
	probe.free()


## Jumps to the end of the fight being played: the result shows at once, every card at rest,
## and the loser's Health lands with no strike (its "-N" on their portrait). Once there, a second
## skip does nothing: the result keeps its hold and then finishes. During the portrait strike it
## lands the strike at once.
func skip() -> void:
	if _strike_mode == "playing" and (not _running or _step_due >= _schedule.steps.size()):
		_settle_strike()
		return
	if not _running or _step_due >= _schedule.steps.size():
		return
	var last: int = _schedule.steps.size() - 1
	_clock = _f(_schedule.steps[last]["frame"])
	_step_due = last
	_drop_bursts()
	_gain_pieces().clear()
	_burst_due = _schedule.bursts.size()
	_shown_splashes = []
	# what was still to sound is skipped; the result's cue plays
	while _cue_due < _schedule.cues.size() and _i(_schedule.cues[_cue_due]["frame"]) < _clock:
		_cue_due += 1
	_show_due()
	_pose_all()
	_glow_cards()
	_play_cues()
	_settle_strike()


func is_playing() -> bool:
	return _running


## Whether the loser's Health has landed: no strike, or its count ended (or was skipped).
func health_landed() -> bool:
	return _health_landed or _schedule == null or _schedule.hero_strike == null


func _process(delta: float) -> void:
	super(delta)
	# game time, not drawn frames: the same fight at any frame rate; FAST moves the schedule
	# faster late in the fight (FightTimeline.advance)
	var frames: float = delta * 60.0 * speed
	if absf(frames - roundf(frames)) < 1e-6:
		frames = roundf(frames)
	if not _running:
		# the strike plays on past the fight's end, on its own game clock
		if _strike_mode == "playing":
			_strike_age += frames
			_draw_strike()
		return
	_clock = _schedule.advance(_clock, frames)
	_schedule.clock_step = maxf(1.0, frames * _schedule.speed_at(_clock))
	_show_due()
	_pose_all()
	_draw_deaths()
	_show_bursts()
	_age_bursts()
	_glow_cards()
	_gain_pieces().draw(_schedule, _clock)
	_play_cues()
	if _strike_mode == "playing":
		_strike_age = _clock - _schedule.result_frame
	_draw_strike()


## Shows every step whose frame has come; the last is the result, which then holds to the end.
func _show_due() -> void:
	var plan: Array[Dictionary] = _schedule.steps
	while _step_due < plan.size() and _i(plan[_step_due]["frame"]) <= _clock:
		var step: Dictionary = plan[_step_due]
		_step = _step_due
		_step_due += 1
		_keeper.speed = maxf(_f(step.get("speed", 1.0)) * speed, 0.01)
		var view: Dictionary = step["state"]
		show_state(view)
		_keeper.speed = maxf(speed, 0.01)
		if _step_due == plan.size():
			# the result: no dead unit still fading over its slot
			settle()
			_start_strike()
			result_shown.emit()
	if _running and _step_due >= plan.size() and _clock >= _schedule.end_frame:
		_running = false
		playback_finished.emit()


func show_state(new_state: Dictionary) -> void:
	if _running and _step >= 0 and _step < _schedule.steps.size():
		# a gain's card shows its numbers through the disc's count: no pop as it lands
		var frame: int = _i(_schedule.steps[_step]["frame"])
		for gain: Dictionary in _schedule.gains:
			if _i(gain["land"]) == frame:
				_keeper.quiet_numbers[str(gain["key"])] = true
	super(new_state)
	if _running:
		_hand_over()


## After a state shows: the keeper's own moves stop (the schedule poses every card), and where
## each card stands is read from the state. Deaths keep their fall.
func _hand_over() -> void:
	_rest_at.clear()
	for target: Dictionary in _targets:
		if str(target["kind"]) != "board":
			continue
		var index: int = target["index"]
		var side: int = floori(index / float(BOARD_SLOTS))
		var data: Dictionary = target["card"]
		var key: String = card_key("f%d_" % side, index % BOARD_SLOTS, data)
		_rest_at[key] = unit_xy(side, index % BOARD_SLOTS)
	for key: Variant in _keeper._kept:
		var entry: Dictionary = _keeper._kept[key]
		var node: Control = entry["node"]
		_keeper.stop(node)


func _pose_all() -> void:
	for key: Variant in _keeper._kept:
		var name_of: String = str(key)
		if not _rest_at.has(name_of):
			continue
		var entry: Dictionary = _keeper._kept[key]
		var node: Control = entry["node"]
		var pose: Dictionary = _schedule.pose(name_of, _clock)
		var home: Vector2 = _rest_at[name_of]
		var offset: Vector2 = pose["offset"]
		node.pivot_offset = node.size / 2.0
		node.position = home + offset
		var grown: float = _f(pose["scale"])
		node.scale = Vector2(grown, grown)
		node.rotation_degrees = _f(pose["turn"])
		var light: Color = pose["light"]
		node.modulate = light


## The schedule's bursts whose frame has come, each on its recipient.
func _show_bursts() -> void:
	var spawned: Array = []
	var all: Array[Dictionary] = _schedule.bursts
	while _burst_due < all.size():
		var burst: Dictionary = all[_burst_due]
		if _i(burst["frame"]) > _clock:
			break
		_burst_due += 1
		var key: String = burst["key"]
		var taken: bool = burst["taken"]
		var down_key: String = "taken_down_per_h" if taken else "dealt_down_per_h"
		var down: float = GlassPieces.number("stage.fight.hit." + down_key)
		var r: float = GlassPieces.number("stage.fight.hit." + ("taken_r" if taken else "dealt_r"))
		var blocked: bool = burst["blocked"]
		var merge: bool = burst.get("merge", false)
		if merge:
			_merge_burst(key)
		var hit: Control = hit_splash(_i(burst["amount"]), r, blocked)
		hit.name = "Hit_%d" % _burst_due
		hit.pivot_offset = hit.size / 2.0
		var recipient: Control = _kept_node(key)
		var offset: Vector2 = Vector2(_w() / 2.0 - r, _h() * down - r)
		var at: Vector2 = recipient.position if recipient != null else Vector2.ZERO
		hit.position = at + offset
		_front.add_child(hit)
		(
			_bursts_on
			. append(
				{
					"node": hit,
					"key": key,
					"recipient": recipient,
					"offset": offset,
					"from": _clock,
					"merge": merge,
					"hold": _f(burst.get("hold", -1.0)),
				}
			)
		)
		(
			spawned
			. append(
				{
					"side": burst["side"],
					"slot": burst["slot"],
					"amount": burst["amount"],
					"blocked": blocked,
				}
			)
		)
	# the splashes that appeared this frame (a comparison film logs them)
	_shown_splashes = spawned


## Rule 5: a card hit again in a combo keeps one burst; the old one goes as the new one pops with
## the running total.
func _merge_burst(key: String) -> void:
	var still: Array[Dictionary] = []
	for live: Dictionary in _bursts_on:
		if str(live["key"]) == key and live.get("merge", false):
			var node: Control = live["node"]
			if is_instance_valid(node):
				node.queue_free()
			continue
		still.append(live)
	_bursts_on = still


## Each burst pops in, settles, is read and fades, following its recipient upright.
func _age_bursts() -> void:
	var still: Array[Dictionary] = []
	var life: int = BURST_POP_F + BURST_SETTLE_F + BURST_READ_F + BURST_FADE_F
	for live: Dictionary in _bursts_on:
		var hit: Control = live["node"]
		var age: float = _clock - _f(live["from"])
		if _f(live.get("hold", -1.0)) >= 0.0:
			if _age_held(live, age):
				still.append(live)
			continue
		if age >= life or not is_instance_valid(hit):
			if is_instance_valid(hit):
				hit.queue_free()
			continue
		var swell: float = 1.0
		if age < BURST_POP_F:
			swell = lerpf(
				FightMotion.BURST_START, FightMotion.BURST_SCALE, float(age) / BURST_POP_F
			)
		elif age < BURST_POP_F + BURST_SETTLE_F:
			swell = lerpf(FightMotion.BURST_SCALE, 1.0, float(age - BURST_POP_F) / BURST_SETTLE_F)
		var fade: float = clampf(float(age - life + BURST_FADE_F) / BURST_FADE_F, 0.0, 1.0)
		var recipient: Control = _kept_node(str(live["key"]))
		if recipient == null:
			var was: Variant = live["recipient"]
			if is_instance_valid(was):
				recipient = was
		else:
			live["recipient"] = recipient
		if recipient != null:
			var offset: Vector2 = live["offset"]
			hit.position = recipient.position + offset + Vector2.UP * FightMotion.BURST_RISE * fade
		hit.scale = Vector2.ONE * swell
		hit.modulate.a = 1.0 - fade
		still.append(live)
	_bursts_on = still


## CB13 c: the number that killed a unit dying on its own pops as any burst does, follows its
## card until the card leaves the board (D), then stands still, full to D+18 and fading over 8 f.
## False once it is gone.
func _age_held(live: Dictionary, age: float) -> bool:
	var hit: Control = live["node"]
	var alpha: float = FightTimeline.kill_number_alpha(_clock - _f(live["hold"]))
	if alpha <= 0.0 or not is_instance_valid(hit):
		if is_instance_valid(hit):
			hit.queue_free()
		return false
	var swell: float = 1.0
	if age < BURST_POP_F:
		swell = lerpf(FightMotion.BURST_START, FightMotion.BURST_SCALE, float(age) / BURST_POP_F)
	elif age < BURST_POP_F + BURST_SETTLE_F:
		swell = lerpf(FightMotion.BURST_SCALE, 1.0, float(age - BURST_POP_F) / BURST_SETTLE_F)
	var recipient: Control = _kept_node(str(live["key"]))
	if recipient != null:
		var offset: Vector2 = live["offset"]
		hit.position = recipient.position + offset
	hit.scale = Vector2.ONE * swell
	hit.modulate.a = alpha
	return true


## CB13 c: each unit dying on its own, `age` frames of the schedule after it left the board: dark,
## held, sinking along its death direction; let go once it is gone.
func _draw_deaths() -> void:
	var motion: FightMotion = _keeper as FightMotion
	for key: Variant in motion.dying.keys():
		var held: Dictionary = motion.dying[key]
		var node: Variant = held["node"]
		if not is_instance_valid(node):
			motion.dying.erase(key)
			continue
		var card: Control = node
		var age: float = _clock - _f(_schedule.single_deaths.get(key, _clock))
		var look: Dictionary = FightTimeline.death_pose(age)
		if look.is_empty():
			motion.let_go(str(key))
			continue
		var base: Vector2 = held["base"]
		var direction: Vector2 = card.get_meta("death_direction", Vector2.DOWN)
		card.position = base + direction * FightTimeline.DEATH_SINK_PX * _f(look["sink"])
		if _f(look["scale"]) >= 0.0:
			card.scale = Vector2.ONE * _f(look["scale"])
		var light: float = _f(look["light"])
		card.modulate = Color(light, light, light, _f(look["alpha"]))


func _drop_bursts() -> void:
	for live: Dictionary in _bursts_on:
		var node: Control = live["node"]
		if is_instance_valid(node):
			node.queue_free()
	_bursts_on.clear()


func _kept_node(key: String) -> Control:
	if not _keeper._kept.has(key):
		return null
	var entry: Dictionary = _keeper._kept[key]
	var node: Control = entry["node"]
	return node


## The attacker's (and a trigger source's) glow (fight.html .card.lunge), drawn above the rest.
func _glow_cards() -> void:
	if _schedule == null:
		return
	var glowing: Dictionary = _schedule.glowing(maxf(_clock, 0.0))
	var z: int = _i(GlassPieces.rule("fight", ".card.lunge", "z-index"))
	for target: Dictionary in _targets:
		var node: Variant = target.get("node")
		if not node is GlassCard or str(target["kind"]) != "board":
			continue
		var card: GlassCard = node
		var data: Dictionary = target["card"]
		var key: String = card_key("", 0, data)
		var on: bool = glowing.has(key)
		if _glow_on.get(card.get_instance_id(), not on) == on:
			continue
		_glow_on[card.get_instance_id()] = on
		if on:
			card.set_glow("fight", ".card.lunge")
			card.z_index = z
		else:
			card.set_glow("", "")
			card.z_index = 0


## The sound cues whose frame has come, each on the moment it belongs to (FightTimeline cues).
func _play_cues() -> void:
	var cues: Array[Dictionary] = _schedule.cues
	while _cue_due < cues.size() and _i(cues[_cue_due]["frame"]) <= _clock:
		Sound.fight_cue(cues[_cue_due])
		_cue_due += 1


## The stat gains' pieces, made on first use.
func _gain_pieces() -> FightGains:
	if _gains == null:
		_gains = FightGains.new(self)
	return _gains


## Keeps the bursts and the gains' pieces over a redraw of the front layer.
func _layout() -> void:
	var kept: Array[Node] = []
	for live: Dictionary in _bursts_on:
		var node: Control = live["node"]
		if is_instance_valid(node) and node.get_parent() == _front:
			_front.remove_child(node)
			kept.append(node)
	var pieces: Array[Node] = []
	if _gains != null:
		pieces = _gains.nodes()
	for node: Node in pieces:
		if node.get_parent() == _front:
			_front.remove_child(node)
	super()
	for node: Node in kept:
		_front.add_child(node)
	for node: Node in pieces:
		_front.add_child(node)
	# a redraw mid-strike (Tab, the round's Health) keeps the strike where it is
	_draw_strike()


# ---- CB12 b: the portrait strike after the result ----


## The result has shown: the strike starts, from the loser's old Health.
func _start_strike() -> void:
	_end_strike()
	if _schedule.hero_strike == null:
		return
	_strike_age = maxf(0.0, _clock - _schedule.result_frame)
	_strike_mode = "playing"
	var strike: FightStrike = _schedule.hero_strike
	var striker: Control = _strike_node(false)
	var loser: Control = _strike_node(true)
	if striker == null or loser == null:
		return
	strike.place(
		_home_of(striker) + striker.size / 2.0,
		_home_of(loser) + loser.size / 2.0,
		striker.size.x / 2.0,
		loser.size.x / 2.0,
		Vector2(960.0, (_f(_g["T0"]) + _f(_g["T1"])) / 2.0)
	)
	_draw_strike()


## No strike: a new fight, or a state with no result.
func _end_strike() -> void:
	_strike_age = -1.0
	_strike_mode = ""
	_health_landed = false
	if _stage != null:
		_stage.position = Vector2.ZERO


## Skip: the strike lands at once, every portrait at rest, the loss on the loser's Health and its
## "-N" on their portrait, still.
func _settle_strike() -> void:
	if _strike_mode != "playing":
		return
	_strike_mode = "skipped"
	var strike: FightStrike = _schedule.hero_strike
	_draw_strike_pose(strike.pose(float(strike.end())))
	_draw_strike_burst({"shown": true, "scale": 1.0, "alpha": 1.0, "amount": strike.total})
	_land_health()


## The loss is on the loser's Health: the state shown says so too, and the round may show it.
func _land_health() -> void:
	if _health_landed:
		return
	_health_landed = true
	var landed: Dictionary = _schedule.hero_strike.landed
	var view: Dictionary = state.duplicate(true)
	view["health"] = landed.get("health", view.get("health", 0))
	var opponent: Dictionary = view.get("opponent", {})
	opponent["health"] = landed.get("opponent_health", opponent.get("health", 0))
	view["players"] = landed.get("players", view.get("players", []))
	state = view
	health_counted.emit()


## The strike at its age; its last frame once more as it ends.
func _draw_strike() -> void:
	if _strike_mode == "skipped" and _schedule != null and _schedule.hero_strike != null:
		_draw_strike_pose(_schedule.hero_strike.pose(float(_schedule.hero_strike.end())))
		return
	if _strike_mode != "playing":
		return
	var strike: FightStrike = _schedule.hero_strike
	var f: float = minf(_strike_age, float(strike.end()))
	var pose: Dictionary = strike.pose(f)
	_draw_strike_pose(pose)
	var burst: Dictionary = pose["burst"]
	_draw_strike_burst(burst)
	if f >= strike.count_end():
		_land_health()
	if f >= strike.end():
		_strike_mode = "over"
		var striker: Control = _strike_node(false)
		if striker != null:
			striker.z_index = 0


func _draw_strike_pose(pose: Dictionary) -> void:
	var striker: Control = _strike_node(false)
	var loser: Control = _strike_node(true)
	if striker == null or loser == null:
		return
	var moved: Dictionary = pose["striker"]
	var light: float = _f(moved["light"])
	var offset: Vector2 = moved["offset"]
	striker.pivot_offset = striker.size / 2.0
	striker.position = _home_of(striker) + offset
	var grown: float = _f(moved["scale"])
	striker.scale = Vector2(grown, grown)
	striker.rotation_degrees = _f(moved["turn"])
	striker.modulate = Color(light, light, light)
	striker.z_index = STRIKE_PORTRAIT_Z
	var hit: Dictionary = pose["loser"]
	var knocked: Vector2 = hit["offset"]
	loser.position = _home_of(loser) + knocked
	loser.modulate = hit["light"]
	_stage.position = pose["stage"]
	_draw_strike_badge(_i(pose["health"]), _f(pose["badge"]))


## The loser's Health badge showing `health`, swollen `swell` times.
func _draw_strike_badge(health: int, swell: float) -> void:
	var badge_name: String = (
		"HeroHealth" if _schedule.hero_strike.loser_is_you else "OpponentHealth"
	)
	var badge: Control = _front.get_node_or_null(badge_name)
	if badge == null:
		return
	if _badge_number(badge) != health:
		var fresh: GlassBox = GlassParts.health_badge(health, [".hp"])
		fresh.position = badge.position
		# out first, so the new badge takes its name
		_front.remove_child(badge)
		badge.queue_free()
		fresh.name = badge_name
		_front.add_child(fresh)
		badge = fresh
	badge.z_index = STRIKE_BADGE_Z
	badge.pivot_offset = badge.size / 2.0
	badge.scale = Vector2.ONE * swell


## The "-N" on the loser's portrait (ResultHit), as the strike shows it.
func _draw_strike_burst(burst: Dictionary) -> void:
	var node: Control = _front.get_node_or_null("ResultHit")
	var amount: int = _i(burst["amount"])
	if not _b(burst["shown"]):
		if node != null:
			_front.remove_child(node)
			node.queue_free()
		return
	if node != null and _i(node.get_meta("amount", -1)) != amount:
		_front.remove_child(node)
		node.queue_free()
		node = null
	if node == null:
		var r: float = GlassPieces.number("stage.fight.hit.dealt_r")
		node = hit_splash(amount, r)
		node.name = "ResultHit"
		node.set_meta("amount", amount)
		var loser: Control = _strike_node(true)
		node.position = _home_of(loser) + loser.size / 2.0 - Vector2(r, r)
		node.z_index = STRIKE_BURST_Z
		_front.add_child(node)
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2.ONE * _f(burst["scale"])
	node.modulate.a = _f(burst["alpha"])


## The winner's portrait (loser false) or the loser's, as drawn now.
func _strike_node(loser: bool) -> Control:
	var you_lost: bool = _schedule.hero_strike.loser_is_you
	var hero: bool = you_lost == loser
	return _front.get_node_or_null("Hero" if hero else "Opponent") as Control


## Where a portrait stands: where it was built (its first position, kept as it moves).
static func _home_of(node: Control) -> Vector2:
	if not node.has_meta("strike_home"):
		node.set_meta("strike_home", node.position)
	return node.get_meta("strike_home")


## The number drawn on a Health badge (its text), or -1.
static func _badge_number(badge: Node) -> int:
	for child: Node in badge.get_children():
		if child is GlassText:
			return (child as GlassText).words.to_int()
	return -1


# ---- building ----


func _build() -> void:
	(_keeper as FightMotion).motions.clear()
	_add_window()
	var you: int = _you()
	_want_side(1 - you)
	_want_side(you)
	_place_cards()
	_light_lunge()
	_build_moment()
	_build_hero()
	_build_opponent()
	if show_leaderboard:
		_build_leaderboard()
	_add_vignette()
	_build_result()
	_update_skip_button()
	_attack_start = false
	_impact_start = false


func _update_skip_button() -> void:
	# Keep the button through replay redraws so a new beat cannot interrupt a click.
	if show_skip and _skip_button == null:
		_skip_button = FightSkipButton.new()
		_skip_button.pressed.connect(skip_requested.emit)
		_stage.add_child(_skip_button)
	if _skip_button != null:
		_skip_button.visible = show_skip


func _you() -> int:
	return _i(state.get("you_side", 0))


## Where a unit of a side stands, by slot: yours as on the recruit screen but under the transom,
## theirs mirrored above it (front row at the bottom), both reading left to right.
func unit_xy(side: int, slot: int) -> Vector2:
	var fw: float = FRONT_SLOTS * _w() + (FRONT_SLOTS - 1) * _gap()
	var fx: float = 960.0 - fw / 2.0
	var x: float = (
		fx + slot * (_w() + _gap())
		if slot < FRONT_SLOTS
		else fx + (_w() + _gap()) / 2.0 + (slot - FRONT_SLOTS) * (_w() + _gap())
	)
	var row: float = (
		GlassPieces.number("stage.fight.board.row_drop_per_h") * _h()
		+ GlassPieces.number("stage.fight.board.row_gap")
	)
	var front: bool = slot < FRONT_SLOTS
	if side == _you():
		return Vector2(x, _f(_g["boardTop"]) + (0.0 if front else row))
	return Vector2(x, _f(_g["oppTop"]) + (row if front else 0.0))


## Contact follows the actual target, including back-row/diagonal attacks. The two card centres
## overlap slightly, rather than stopping at a fixed height short of the defending row.
func lunge_xy(lunge: Dictionary) -> Vector2:
	var from: Vector2 = unit_xy(_i(lunge["side"]), _i(lunge["slot"]))
	var to: Vector2 = unit_xy(_i(lunge["target_side"]), _i(lunge["target_slot"]))
	return to - (to - from).normalized() * _h() * FightMotion.CONTACT_PER_H


func _want_side(side: int) -> void:
	var boards: Array = state.get("boards", [[], []])
	var board: Array = boards[side] if side < boards.size() else []
	var all_slots: Array = state.get("slots", [[], []])
	var slots: Array = all_slots[side] if side < all_slots.size() else []
	var places: Array[Vector2] = []
	var bonuses: Array[Dictionary] = []
	for i: int in BOARD_SLOTS:
		places.append(unit_xy(side, i))
		var raw: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		bonuses.append(slot_info(raw))
	_slots.set_row("Slot_%d_" % side, places, card_box(), bonuses)
	var lunge: Dictionary = _lunge()
	for i: int in BOARD_SLOTS:
		var unit: Variant = board[i] if i < board.size() else null
		var info: Dictionary = bonuses[i]
		# the slot's own Renown banner shows while it is empty; a unit that gets it carries it
		var banner: CanvasItem = _slots.get_node_or_null("Slot_%d_%d/Renown" % [side, i])
		if banner != null:
			banner.visible = not unit is Dictionary
		if unit is Dictionary:
			var held: Dictionary = unit
			var extra: Dictionary = {}
			if info.has("keyword"):
				extra["keyword"] = str(info["keyword"])
			# Older replay views carry only whether the unit received its slot's Renown.
			var renown: int = _i(held.get("renown", 0))
			if not held.has("renown") and _b(held.get("renowned", false)):
				renown = _i(info.get("renown", 0))
			if renown != 0:
				extra["renown"] = renown
			var at: Vector2 = unit_xy(side, i)
			var time: float = -1.0
			# An attacker waiting for its pilers winds up at home; a piler jabs out (FightMotion)
			# and holds there until the attacker lunges.
			if _is_lunger(lunge, side, i) and not _recoiled and not _b(lunge.get("waiting", false)):
				at = lunge_xy(lunge)
				time = LUNGE_TIME
			elif _joins(side, i):
				at = join_xy(side, i, lunge)
				time = LUNGE_TIME
			elif _is_lunger(_trigger(), side, i):
				at.y -= TRIGGER_LIFT if side == _you() else -TRIGGER_LIFT
				time = TRIGGER_TIME
			var key: String = card_key("f%d_" % side, i, held)
			(_keeper as FightMotion).motions[key] = _card_motion(side, i, lunge)
			_want_card(key, "board", side * BOARD_SLOTS + i, held, at, 0.0, extra, time)


func _card_motion(side: int, slot: int, lunge: Dictionary) -> Dictionary:
	var direction: Vector2 = Vector2.DOWN if side == _you() else Vector2.UP
	var attacker: bool = _is_lunger(lunge, side, slot)
	if not lunge.is_empty():
		direction = (
			(
				unit_xy(_i(lunge["target_side"]), _i(lunge["target_slot"]))
				- unit_xy(_i(lunge["side"]), _i(lunge["slot"]))
			)
			. normalized()
		)
	var hit: Dictionary = {}
	for splash: Dictionary in _shown_splashes:
		if _i(splash["side"]) == side and _i(splash["slot"]) == slot:
			hit = splash
	var joining: bool = _joins(side, slot)
	return {
		"attack": _attack_start and attacker,
		"hit": _impact_start and (not hit.is_empty() or attacker) and not joining,
		"jab": _impact_start and joining,
		"home": unit_xy(side, slot),
		"received": not hit.is_empty(),
		"blocked": _b(hit.get("blocked", false)),
		"returning": attacker,
		"direction": direction,
		"death_direction": -direction if attacker else direction,
	}


## Whether a unit joins the attack now (a mouse piling on): moment.joins [{side, slot}].
func _joins(side: int, slot: int) -> bool:
	var moment: Dictionary = state.get("moment", {})
	for value: Variant in moment.get("joins", []):
		var join: Dictionary = value if value is Dictionary else {}
		if _i(join.get("side", -1)) == side and _i(join.get("slot", -1)) == slot:
			return true
	return false


## STAND-IN (stand-ins.html ?m=fight3): where a unit joining an attack jabs to and holds: from its
## own slot JOIN_SHARE of the way along the attacker's lunge.
func join_xy(side: int, slot: int, lunge: Dictionary) -> Vector2:
	var from: Vector2 = unit_xy(side, slot)
	if lunge.is_empty():
		return from
	return from + (lunge_xy(lunge) - unit_xy(_i(lunge["side"]), _i(lunge["slot"]))) * JOIN_SHARE


## The lunge the state shows; none while a schedule plays (it poses the attacker itself).
func _lunge() -> Dictionary:
	if _running:
		return {}
	var moment: Dictionary = state.get("moment", {})
	var lunge: Dictionary = moment.get("lunge", {})
	return lunge


## The unit whose effect is acting now: {side, slot}, or {}.
func _trigger() -> Dictionary:
	var moment: Dictionary = state.get("moment", {})
	var trigger: Dictionary = moment.get("trigger", {})
	return trigger


static func _is_lunger(lunge: Dictionary, side: int, slot: int) -> bool:
	return not lunge.is_empty() and _i(lunge["side"]) == side and _i(lunge["slot"]) == slot


func _make_card(kind: String, data: Dictionary, extra: Dictionary) -> Control:
	var node: Control = super(kind, data, extra)
	if extra.has("keyword") and node is GlassCard:
		_slot_keyword_pill(node as GlassCard, str(extra["keyword"]))
	if extra.has("renown") and node is GlassCard:
		var card: GlassCard = node as GlassCard
		var banner: GlassBox = GlassSlot.renown_banner(
			_i(extra["renown"]), GlassCard.card_size(card.card_height)
		)
		banner.name = "Renown"
		card.add_child(banner)
	return node


## The attacker glows above the rest (fight.html .card.lunge); every other card has its own look.
func _light_lunge() -> void:
	if _running:
		_glow_cards()
		return
	var lunge: Dictionary = _lunge()
	for target: Dictionary in _targets:
		var node: Variant = target.get("node")
		if not node is GlassCard:
			continue
		var card: GlassCard = node
		var index: int = target["index"]
		card.name = "Unit_%d_%d" % [floori(index / float(BOARD_SLOTS)), index % BOARD_SLOTS]
		var side: int = floori(index / float(BOARD_SLOTS))
		if (
			_is_lunger(lunge, side, index % BOARD_SLOTS)
			or _is_lunger(_trigger(), side, index % BOARD_SLOTS)
			or _joins(side, index % BOARD_SLOTS)
		):
			card.set_glow("fight", ".card.lunge")
			card.z_index = _i(GlassPieces.rule("fight", ".card.lunge", "z-index"))
		else:
			card.set_glow("", "")
			card.z_index = 0


## Each splash starts at its recipient's current pose and follows its recoil upright. While a
## schedule plays, its own bursts are drawn instead (_show_bursts).
func _build_moment() -> void:
	if _running:
		return
	var moment: Dictionary = state.get("moment", {})
	var lunge: Dictionary = moment.get("lunge", {})
	var splashes: Array = moment.get("splashes", [])
	for k: int in splashes.size():
		var splash: Dictionary = splashes[k]
		var side: int = _i(splash["side"])
		var slot: int = _i(splash["slot"])
		var at: Vector2 = unit_xy(side, slot)
		var down: float = GlassPieces.number("stage.fight.hit.dealt_down_per_h")
		var r: float = GlassPieces.number("stage.fight.hit.dealt_r")
		var attacker: bool = (
			not lunge.is_empty() and _i(lunge["side"]) == side and _i(lunge["slot"]) == slot
		)
		if attacker:
			at = lunge_xy(lunge)
			down = GlassPieces.number("stage.fight.hit.taken_down_per_h")
			r = GlassPieces.number("stage.fight.hit.taken_r")
		var recipient: Control = node_for("board", side * BOARD_SLOTS + slot)
		if recipient != null:
			at = recipient.position
		var hit: Control = hit_splash(_i(splash["amount"]), r, _b(splash.get("blocked", false)))
		hit.name = "Hit_%d" % k
		hit.position = at + Vector2(_w() / 2.0 - r, _h() * down - r)
		_front.add_child(hit)
		if _impact_start:
			(_keeper as FightMotion).burst(hit, recipient)


## fight.html hit(): an eight-pointed burst in lead, its glass red, the damage on it. Amount 0 is
## a destroy (STAND-IN, stand-ins.html): the burst with no number. `blocked` (STAND-IN,
## stand-ins.html ?m=trigger): a hit that did nothing, the burst with a 0 on it.
static func hit_splash(amount: int, r: float, blocked: bool = false) -> Control:
	var outer: Rect2 = Rect2(0, 0, 2.0 * r, 2.0 * r)
	var root: Control = Control.new()
	root.size = outer.size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = GlassPieces.as_int(GlassPieces.rule("fight", ".hit", "z-index"))
	var lead_layers: Array = GlassPieces.rule("fight", ".hit i", "background")
	var lead_layer: Dictionary = lead_layers[0]
	var lead: Color = Color.html(str(lead_layer["colour"]))
	var star_outer: PackedVector2Array = _star(outer)
	root.draw.connect(func() -> void: root.draw_colored_polygon(star_outer, lead))
	var inset: float = GlassPieces.as_float(GlassPieces.rule("fight", ".hit i + i", "inset"))
	var inner: Rect2 = outer.grow(-inset)
	var mask: Control = Control.new()
	mask.name = "Glass"
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.position = inner.position
	mask.size = inner.size
	var star_inner: PackedVector2Array = _star(Rect2(Vector2.ZERO, inner.size))
	mask.draw.connect(func() -> void: mask.draw_colored_polygon(star_inner, Color.WHITE))
	root.add_child(mask)
	var glass: GlassBox = GlassBox.new()
	glass.box_size = inner.size
	glass.use_css("fight", ".hit i + i")
	glass.refresh()
	mask.add_child(glass)
	if amount <= 0 and not blocked:
		return root
	var words: GlassText = GlassText.from_rule(
		"fight", ".hit b", "0" if blocked else "-%d" % amount
	)
	words.refresh()
	words.position = ((outer.size - words.size) / 2.0).round()
	root.add_child(words)
	return root


## The burst's 16 points, as fight.html writes them (percentages to one decimal).
static func _star(rect: Rect2) -> PackedVector2Array:
	var points: int = GlassPieces.as_int(GlassPieces.number("stage.fight.hit.points"))
	var inner_k: float = GlassPieces.number("stage.fight.hit.inner_k")
	var out: PackedVector2Array = PackedVector2Array()
	for i: int in points:
		var a: float = PI * i / (points / 2.0) - PI / 2.0
		var k: float = inner_k if i % 2 == 1 else 1.0
		var px: float = snappedf(50.0 + 50.0 * k * cos(a), 0.1)
		var py: float = snappedf(50.0 + 50.0 * k * sin(a), 0.1)
		out.append(rect.position + Vector2(px, py) / 100.0 * rect.size)
	return out


## The right light: the opponent's hero at the top, its Health and name under it.
func _build_opponent() -> void:
	var opponent: Dictionary = state.get("opponent", {})
	var x: float = 1904.0 - _f(_g["sideW"]) / 2.0 - GlassPieces.number("stage.fight.opp.port_left")
	var side: float = GlassPieces.number("stage.fight.opp.port")
	var port: GlassBox = GlassBox.new()
	port.name = "Opponent"
	port.box_size = Vector2(side, side)
	port.use_css("fight", ".opphero")
	port.radii = Vector4.ONE * side / 2.0
	port.image_texture = GlassPieces.portrait(str(opponent.get("portrait", "")))
	port.layers = [{"kind": "image", "size": "cover", "position": [50.0, 50.0]}]
	port.refresh()
	port.position = Vector2(x, GlassPieces.number("stage.fight.opp.port_y"))
	_front.add_child(port)
	var hp: GlassBox = GlassParts.health_badge(_i(opponent.get("health", 0)), [".hp"])
	hp.name = "OpponentHealth"
	hp.position = Vector2(
		x + GlassPieces.number("stage.fight.opp.hp_right"),
		GlassPieces.number("stage.fight.opp.hp_y")
	)
	_front.add_child(hp)
	var words: GlassText = GlassText.from_rule("stage", ".lbl", str(opponent.get("name", "")))
	words.name = "OpponentName"
	words.font_px = GlassPieces.number("stage.fight.opp.name_size")
	words.colour = GlassPieces.rule_colour("fight", ".oppname", "color")
	words.refresh()
	words.position = Vector2(
		x - GlassPieces.number("stage.fight.opp.name_left"),
		GlassPieces.number("stage.fight.opp.name_y")
	)
	_front.add_child(words)


## Reminder lines for the hover, and for a unit whose terms count being outnumbered (Fury,
## Grudge) while its side is (combat_start's outnumbered_by, the unit's `outnumbered`): "Outnumbered
## by 2."
func _reminders(card: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = super(card)
	var n: int = _i(card.get("outnumbered", 0))
	if n <= 0:
		return lines
	for line: String in CardTerms.reminders(card, _display_table()):
		if CardTerms.mentions(line, "Outnumbered"):
			lines.append(OUTNUMBERED_WORDS % n)
			break
	return lines


## STAND-IN: the result over the transom, and the loser's damage as a splash on their portrait
## (shown on its own, or after a skip; while the portrait strike plays, it draws the "-N").
func _build_result() -> void:
	var moment: Dictionary = state.get("moment", {})
	if not moment.has("result"):
		return
	var result: Dictionary = moment["result"]
	var winner: int = _i(result.get("winner", -1))
	var words: String = "Draw"
	if winner >= 0:
		words = "Victory" if winner == _you() else "Defeat"
	var banner: GlassText = GlassText.from_rule("stage", ".lbl", words)
	banner.name = "Result"
	banner.font_px = 72.0
	banner.refresh()
	banner.z_index = 7
	banner.position = Vector2(
		960.0 - banner.size.x / 2.0, (_f(_g["T0"]) + _f(_g["T1"])) / 2.0 - banner.size.y / 2.0
	)
	_front.add_child(banner)
	var damage: int = _i(result.get("damage", 0))
	if winner < 0 or damage <= 0 or _strike_mode in ["playing", "over"]:
		# the portrait strike draws its own "-N" (_draw_strike_burst)
		return
	var r: float = GlassPieces.number("stage.fight.hit.dealt_r")
	var hit: Control = hit_splash(damage, r)
	hit.name = "ResultHit"
	hit.set_meta("amount", damage)
	var target: Control = _front.get_node("Opponent" if winner == _you() else "Hero")
	hit.position = target.position + target.size / 2.0 - Vector2(r, r)
	_front.add_child(hit)
