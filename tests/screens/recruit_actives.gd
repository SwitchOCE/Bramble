extends Control
## The recruit screen with the Pigeons' Actives, for screenshots of the gold-cost coin: Lance
## Corporals in the back row, one used this turn, and a Grenadier Guard whose Active is free.
## Hedge-layer in front keeps its Bury button. With BRAMBLE_ACTIVES_POOR=1 the gold is 0 after
## the use, so the unused Corporal can't afford its Active.
## STAND-IN: the free Grenadier Guard (the shipped one costs 1), to show a 0 coin until a card
## with a free Active ships.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = GameFlow.create(content, 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.gold = 5
	CoreKit.put(flow.session, me, "hedge-layer", 2)
	CoreKit.put(flow.session, me, "lance-corporal", 4)
	var used: Unit = CoreKit.put(flow.session, me, "lance-corporal", 5)
	var guard: Unit = CoreKit.put(flow.session, me, "grenadier-guard", 6)
	for bound: BoundMechanic in guard.mechanics:
		if bound.id == &"pigeon_grenadier":
			var errors: PackedStringArray = PackedStringArray()
			bound.params = MechanicParams.parse(
				{"cost": 0, "attack": 2, "health": 4}, bound.mechanic.param_kinds(), "", errors
			)
	var use: Dictionary = {
		"type": "ability", "uid": used.uid, "mechanic": "pigeon_lance_corporal", "target": -1
	}
	var refused: String = flow.act(use)
	assert(refused == "", refused)
	if OS.get_environment("BRAMBLE_ACTIVES_POOR") == "1":
		me.gold = 0
	var screen: RecruitScreen = SCREEN.instantiate()
	screen.state = ViewAdapter.recruit_state(flow)
	add_child(screen)
