extends Control
## The recruit screen with the Pigeons' marks, for screenshots: Lance Corporal and Grenadier Guard
## with their gold-coin Actives, a Sentry with Supply partly spent, a Padre with its Charge, Renown
## on several slots (one of them empty), and a Reserve unit in hand with the reserve-limit banners.
## With BRAMBLE_MARKS_QUARTERMASTER=1 a Quartermaster stands on the board too, so three banners.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var screen: RecruitScreen = SCREEN.instantiate()
	var quartermaster: bool = OS.get_environment("BRAMBLE_MARKS_QUARTERMASTER") == "1"
	screen.state = ViewAdapter.recruit_state(make_flow(quartermaster))
	add_child(screen)


## The game behind the shot, also used by the tests.
static func make_flow(quartermaster: bool = false, reserve_in_hand: bool = true) -> GameFlow:
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = FlowFixture.live(content, 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.gold = 5
	var session: GameSession = flow.session
	var sentry: Unit = CoreKit.put(session, me, "sentry", 0)
	sentry.counters[&"supply:pigeon_sentry"] = 2
	CoreKit.put(session, me, "padre", 1)
	CoreKit.put(session, me, "lance-corporal", 4)
	CoreKit.put(session, me, "grenadier-guard", 6)
	if quartermaster:
		CoreKit.put(session, me, "quartermaster", 5)
	me.slots[0].renown = 3
	me.slots[1].renown = 1
	me.slots[2].renown = 2
	me.slots[4].renown = 1
	me.hand.append(CoreKit.unit(session, "territorial" if reserve_in_hand else "sentry"))
	session.recruit.refresh_auras(me)
	return flow
