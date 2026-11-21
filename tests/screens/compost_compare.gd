extends GameController
## Repeatable screenshot fixture: real core entries, adapter and recruit screen.

const IDS: Array[StringName] = [
	&"bramble-runner",
	&"nettle-sprout",
	&"old-stump",
	&"sweetbriar",
	&"blackthorn-sapling",
	&"hedge-layer",
	&"ivy-climber",
	&"crab-apple",
	&"hawthorn-warden",
	&"holly-knight",
	&"leafmould-carter",
	&"elder-mother"
]

@export var card_count: int = 3


func _ready() -> void:
	super()
	start(FlowFixture.live(GameContent.load_default(), 4, ["thorn"]))
	for i: int in card_count:
		var def: UnitDef = flow.content.library.get_card(IDS[i % IDS.size()])
		flow.human().heap(&"thorn_compost").add(def.id, def.tier)
	recruit.show_state(ViewAdapter.recruit_state(flow))
	recruit.settle()
	recruit._open_compost.call_deferred()
