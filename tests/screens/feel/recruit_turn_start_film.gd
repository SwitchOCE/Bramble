extends Control
## A real fight followed by the next recruit turn, shared with the playback tests.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")

var _flow: GameFlow
var _screen: RecruitScreen


func _ready() -> void:
	_flow = after_fight(GameContent.load_default())
	_screen = SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(_flow)
	add_child(_screen)
	get_tree().create_timer(0.38).timeout.connect(_start_turn)


func _start_turn() -> void:
	_flow.start_round()
	_screen.show_state(ViewAdapter.recruit_state(_flow, "+1 gold from the last fight"))


func feel_report() -> Dictionary:
	assert(not _screen._turn_start.active())
	var effects: Array = _screen.state.get("turn_start_effects", [])
	return {
		"turn": _flow.session.round_number,
		"effects": effects,
		"gold": _flow.human().gold,
		"hand": _flow.human().hand.size(),
	}


static func after_fight(content: GameContent, full_hand: bool = false) -> GameFlow:
	var flow: GameFlow = GameFlow.create(content, 20)
	flow.start_round()
	var session: GameSession = flow.session
	var me: PlayerState = flow.human()
	CoreKit.put(session, me, "brock-cub", 0)
	CoreKit.put(session, me, "old-campaigner", 2)
	CoreKit.put(session, me, "shrew-cutpurse", 3)
	CoreKit.put(session, me, "relic-seeker", 4)
	CoreKit.put(session, me, "horde-runner", 6)
	me.slots[2].renown = 1
	if full_hand:
		for i: int in session.rules.hand_limit(me):
			me.hand.append(CoreKit.unit(session, "hopper"))
	else:
		me.hand.append(CoreKit.unit(session, "lance-corporal"))
		me.hand.append(CoreKit.unit(session, "needle-page"))
	var opponent: PlayerState = session.player(session.opponent_of(me.id))
	for i: int in 7:
		# Seven counted opponents stay on the board when end-turn settles triples.
		var target: Unit = CoreKit.unit(session, "needle-page", true)
		opponent.place(target, i)
		target.stats.set_attack = 0
		target.stats.set_health = 10
	session.recruit.refresh_auras(me)
	session.finish_round()
	return flow
