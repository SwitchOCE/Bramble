extends RefCounted
## Ooze rule/state descriptions stay in the reader; events use the existing bead clock.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitMotion := preload("res://src/ui/screens/recruit_motion.gd")

var shares_seen: Dictionary = {}
var soup_seen: Dictionary = {}


func render(board: BoardView, motion: RecruitMotion = null, shop_holder: Node = null) -> void:
	for card: CardView in board.cards:
		if card == null:
			continue
		var view: Dictionary = card.unit
		var iid: String = _identity(card)
		var serial: int = Data.i(view, "ooze_share_serial")
		if shares_seen.has(iid) and serial > Data.i(shares_seen, iid) and motion != null:
			# The exact result is already in the canonical view; only its beads pop.
			motion.roll_gain(card, 0, 0)
		shares_seen[iid] = serial
	if shop_holder == null:
		return
	for child: Node in shop_holder.get_children():
		var card: CardView = child as CardView
		if card == null:
			continue
		var iid: String = _identity(card)
		var bonus: Vector2i = card.unit.get("ooze_soup_bonus", Vector2i.ZERO)
		var before: Vector2i = soup_seen.get(iid, Vector2i.ZERO)
		if soup_seen.has(iid) and bonus != before and motion != null:
			var change: Vector2i = bonus - before
			motion.roll_gain(card, change.x, change.y)
		soup_seen[iid] = bonus


static func _identity(card: CardView) -> String:
	var iid: int = Data.i(card.unit, "iid", -1)
	if iid >= 0:
		return "iid:%d" % iid
	return "%s:%s:%d" % [card.zone, Data.s(card.unit, "def_id"), card.index]


## Pointer entry alone must not pulse: the screen opens a reader before showing its reach.
func hover(_board: BoardView, view: Dictionary, _slot: int, _on_board: bool) -> Dictionary:
	return view


## Dynamic selectors remain readable by identity, without reviving slot-code captions.
static func reader_view(board: BoardView, view: Dictionary) -> Dictionary:
	if Data.b(view, "_ooze_reader_notes"):
		return view
	var notes: PackedStringArray = []
	if Data.b(view, "ooze_ladle"):
		notes.append("Your biggest Ooze.")
	if view.has("ooze_nell_eaters"):
		var names: PackedStringArray = []
		for value: Variant in Data.a(view, "ooze_nell_eaters"):
			var slot: int = Data.as_int(value)
			if slot >= 0 and slot < board.cards.size() and board.cards[slot] != null:
				names.append(Data.s(board.cards[slot].unit, "name"))
		if names.is_empty():
			notes.append("No Ooze next to this.")
		else:
			notes.append(
				(
					("Current eater: " if names.size() == 1 else "Current eaters: ")
					+ " and ".join(names)
					+ "."
				)
			)
	elif Data.s(view, "def_id") == "aunt_aspic":
		var source: int = -1
		for slot: int in board.cards.size():
			if (
				board.cards[slot] != null
				and Data.i(board.cards[slot].unit, "iid", -2) == Data.i(view, "iid", -1)
			):
				source = slot
		var names: PackedStringArray = []
		for slot: int in RecruitView.related_slots(view, source):
			var card: CardView = board.cards[slot]
			if card != null and Data.a(card.unit, "tribes").has("Oozes"):
				names.append(Data.s(card.unit, "name"))
		if names.is_empty():
			notes.append("No Ooze in front of this.")
		else:
			notes.append("Serves " + " and ".join(names) + ".")
	if notes.is_empty():
		return view
	var annotated: Dictionary = view.duplicate()
	annotated["text"] = (Data.s(view, "text") + "\n" + "\n".join(notes)).strip_edges()
	annotated["_ooze_reader_notes"] = true
	return annotated
