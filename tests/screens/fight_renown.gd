extends Control
## A real fight on the fight screen, held on one frame for screenshots: a Sky-darkener's Hoppers
## have landed in back-row Renown slots (summons: no Renown, so no pill), and the Sentry that
## started in the Renown slot at the front has died, so a Territorial from the hand has stepped
## in (a reservist: the pill). A Padre shows its Charge pips, one dimmed for the use it spent.

const CoreKit := preload("res://tests/core/core_kit.gd")
const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")
## Your slots' Renown: the front's Sentry, the Sky-darkener's and the two its Hoppers land in.
const RENOWN: Dictionary = {0: 3, 4: 1, 5: 2, 6: 1}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var replay: FightReplay = make_replay()
	var screen: FightScreen = SCREEN.instantiate()
	screen.state = replay.steps[maxi(0, frame(replay))]["state"]
	add_child(screen)


## The fight's replay, the same game every time.
static func make_replay() -> FightReplay:
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = FlowFixture.live(content, 11)
	flow.start_round()
	var session: GameSession = flow.session
	var me: PlayerState = flow.human()
	CoreKit.put(session, me, "sentry", 0)
	CoreKit.put(session, me, "padre", 2)
	CoreKit.put(session, me, "sky-darkener", 4)
	for slot: int in RENOWN:
		me.slots[slot].renown = RENOWN[slot]
	me.hand.append(CoreKit.unit(session, "territorial"))
	session.recruit.refresh_auras(me)
	var them: PlayerState = session.player(session.opponent_of(GameFlow.HUMAN))
	CoreKit.put(session, them, "regimental-sergeant-major", 0)
	CoreKit.put(session, them, "regimental-sergeant-major", 1)
	them.turn_ended = true
	var record: Dictionary = flow.finish_round()
	var events: Array = record["events"]
	return FightReplay.build(
		ViewAdapter.fight_base(flow, record),
		events,
		ViewAdapter.catalog(content),
		CoreUtil.to_int(record["damage"])
	)


## The first step with a Territorial in slot 0 and a Hopper in slot 5 on your side; -1 for none.
static func frame(replay: FightReplay) -> int:
	for i: int in replay.steps.size():
		var view: Dictionary = replay.steps[i]["state"]
		var yours: Array = view["boards"][CoreUtil.to_int(view["you_side"])]
		var front: Dictionary = yours[0] if yours[0] is Dictionary else {}
		var back: Dictionary = yours[5] if yours[5] is Dictionary else {}
		if str(front.get("id", "")) == "territorial" and str(back.get("id", "")) == "hopper":
			return i
	return -1
