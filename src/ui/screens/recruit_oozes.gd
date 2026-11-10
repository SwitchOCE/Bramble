extends RefCounted
## Recruit-only transient marks. Kept apart from the screen's action and layout code.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
var shares_seen: Dictionary = {}


func render(board: BoardView) -> void:
	for card: CardView in board.cards:
		if card == null:
			continue
		var view: Dictionary = card.unit
		var iid: String = str(Data.i(view, "iid", -1))
		var serial: int = Data.i(view, "ooze_share_serial")
		if serial > Data.i(shares_seen, iid):
			card.show_ooze_share()
		shares_seen[iid] = serial


func hover(board: BoardView, view: Dictionary, slot: int, on_board: bool) -> Dictionary:
	if not on_board:
		board.show_relations([])
		return view
	if view.has("ooze_nell_eaters"):
		board.show_relations(RecruitView.related_slots(view, slot))
		var annotated: Dictionary = view.duplicate()
		annotated["text"] = Data.s(view, "text") + "\n" + RecruitView.geometry_note(view, slot)
		return annotated
	if Data.s(view, "def_id") == "aunt_aspic":
		board.show_relations(RecruitView.related_slots(view, slot))
	return view
