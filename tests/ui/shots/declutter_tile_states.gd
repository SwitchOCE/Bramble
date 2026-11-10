extends RefCounted
## A separate layout stress input; the pinned five production packet states stay unchanged.

const UnitViews := preload("res://src/ui/unit_views.gd")
const FAN_IDS: PackedStringArray = [
	"old_moth_annis",
	"mrs_sorrel",
	"one_swallow",
	"mrs_jay",
	"little_nip",
	"wick",
	"old_moth_annis",
	"mrs_sorrel",
	"one_swallow",
	"mrs_jay",
]


static func fan10(overview: Dictionary) -> Dictionary:
	var out: Dictionary = overview.duplicate(true)
	var library: UnitLibrary = UnitLibrary.load_dir()
	var hand: Array[Dictionary] = []
	for index: int in FAN_IDS.size():
		var definition: Dictionary = library.get_unit(FAN_IDS[index])
		assert(not definition.is_empty(), "the hand stress fixture uses real shipped definitions")
		var view: Dictionary = UnitViews.from_def(definition, index % 3 == 1, 900 + index)
		view["iid"] = 900 + index
		hand.append(view)
	out["hand"] = hand
	out["hand_items"] = []
	out["hand_limit"] = 10
	return out
