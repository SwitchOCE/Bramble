extends Control
## A STAND-IN controller that plays a real fight from the rules core through the fight screen,
## for tools/look and the tests: the core's neutral test units (tests/core/data), each given
## mock-up art by STAND-IN choice, on two hand-built boards. When the playback ends it prints
## whether the board on screen equals the core's result. Choose the fight with the FIGHT
## environment variable or the `fight` export (0-2); SPEED plays it faster.

const CoreKit := preload("res://tests/core/core_kit.gd")
const LINE: String = "fight stand-in: %s"
## STAND-IN art for the neutral test units, by card id.
const ART: Dictionary = {
	"t1_plain": "mouse-1",
	"t1_guard": "hedgehog-1",
	"t1_herald": "hare-1",
	"t1_seed": "ooze-2",
	"tk_sprout": "fairy-2",
	"t2_shield": "badger-1",
	"t2_fighter": "stoat-1",
	"t3_twin": "otter-1",
	"t3_viper": "stoat-2",
	"t3_hunter": "owl-1",
	"t4_phoenix": "owl-2",
	"t4_cleaver": "boar-1",
	"t4_shade": "fairy-1",
	"t4_wall": "hedgehog-2",
	"t5_avenger": "boar-2",
	"t5_bomber": "ooze-1",
	"t6_titan": "stag-1",
	"t6_brood": "stag-2",
}
## Three fights between boards of neutral units: {slot: card id} for each side.
const FIGHTS: Array = [
	[
		{0: "t2_shield", 1: "t3_twin", 2: "t1_seed", 4: "t4_phoenix"},
		{0: "t1_guard", 1: "t4_cleaver", 2: "t3_viper", 5: "t1_plain"},
	],
	[
		{0: "t6_titan", 1: "t5_bomber", 3: "t2_fighter", 6: "t3_hunter"},
		{0: "t4_wall", 1: "t6_brood", 2: "t4_shade", 4: "t5_avenger", 5: "t1_seed"},
	],
	[
		{0: "t1_plain", 1: "t1_plain", 2: "t1_herald"},
		{0: "t2_shield", 1: "t3_viper"},
	],
]

@export var fight: int = 0

var screen: FightScreen
var combat: Combat
var replay: FightReplay


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var chosen: String = OS.get_environment("FIGHT")
	if chosen != "":
		fight = chosen.to_int()
	var game: GameSession = CoreKit.session(7)
	var spec: Array = FIGHTS[fight]
	var spec_a: Dictionary = spec[0]
	var spec_b: Dictionary = spec[1]
	combat = CoreKit.fight(game, CoreKit.board(game, spec_a), CoreKit.board(game, spec_b), 11)
	var base: Dictionary = RecruitScreen.load_state("res://tests/screens/fixtures/fight_start.json")
	base.erase("boards")
	base["slots"] = [[], []]
	replay = FightReplay.build(base, combat.events, catalog(game), 7)
	screen = (load("res://src/screens/fight/fight_screen.tscn") as PackedScene).instantiate()
	screen.state = (replay.steps[0] as Dictionary)["state"]
	if OS.get_environment("SPEED") != "":
		screen.speed = OS.get_environment("SPEED").to_float()
	add_child(screen)
	screen.playback_finished.connect(_on_finished)
	screen.play(replay)
	print(
		(
			LINE
			% ("fight %d: %d events, %d steps" % [fight, combat.events.size(), replay.steps.size()])
		)
	)


## What the screen needs of each card that the fight log does not carry.
static func catalog(game: GameSession) -> Dictionary:
	var out: Dictionary = {}
	for card_id: Variant in ART:
		var def: UnitDef = game.library.get_card(StringName(str(card_id)))
		out[str(card_id)] = {
			"name": def.name,
			"tier": def.tier,
			"art": ART[card_id],
			"health": def.health,
			"text": "Neutral test unit (tests/core/data).",
		}
	return out


## The core's board after the fight, as FightReplay.summary gives the screen's.
func core_summary(side: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for unit: CombatUnit in combat.units(side):
		out.append(
			{"slot": unit.slot, "uid": unit.uid, "attack": unit.attack(), "health": unit.health()}
		)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["slot"] < b["slot"])
	return out


## The board the screen shows now, read from its view state.
func screen_summary(side: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var boards: Array = screen.state.get("boards", [[], []])
	var row: Array = boards[side]
	for slot: int in row.size():
		if row[slot] is Dictionary:
			var unit: Dictionary = row[slot]
			(
				out
				. append(
					{
						"slot": slot,
						"uid": GlassPieces.as_int(unit["uid"]),
						"attack": GlassPieces.as_int(unit["attack"]),
						"health": GlassPieces.as_int(unit["health"]),
					}
				)
			)
	return out


func _on_finished() -> void:
	var same: bool = true
	for side: int in 2:
		same = same and screen_summary(side) == core_summary(side)
	print(LINE % ("result %s, winner %s" % [combat.result["reason"], combat.result["winner"]]))
	print(LINE % ("final board %s the core's" % ("matches" if same else "DIFFERS FROM")))
	if OS.get_environment("QUIT") != "":
		get_tree().quit()
	if not same:
		for side: int in 2:
			print(
				(
					LINE
					% (
						"side %d screen %s core %s"
						% [side, screen_summary(side), core_summary(side)]
					)
				)
			)
