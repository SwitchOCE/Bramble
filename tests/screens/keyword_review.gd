extends Control
## Real shared tooltip on the approved page's card and board position. Used for shots and film.
const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
var screen: RecruitScreen
var saw_frozen: bool = false
var most_details: int = 0
var frozen_position: Vector2
var moved_while_frozen: bool = false


func _ready() -> void:
	screen = SCREEN.instantiate()
	var state: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/shop_review.json")
	var content: GameContent = GameContent.load_default()
	var ace: Dictionary = ViewAdapter.card_from_id(content, content.new_session(3), "flying-ace")
	ace["counters"] = [{"id": "pigeon_medal", "value": 2}]
	var board: Array = state["board"]
	board[3] = board[1]
	board[1] = ace
	screen.state = state
	add_child(screen)
	screen.settle()
	if OS.get_environment("BRAMBLE_KEYWORD_SHOT") == "1":
		var card: Control = screen.node_for("board", 1)
		# Same anchor as the approved page, for the side-by-side capture.
		screen._tips.show(screen.targets_of("board")[1], card.position + Vector2(card.size.x, 100))
		var event: InputEventKey = InputEventKey.new()
		event.keycode = KEY_ALT
		event.pressed = true
		screen._tips.key_input(event)
		var mark: KeywordMark = _mark("Decorated", screen._tips.tip)
		if mark != null:
			screen._tips.keyword_hover(_point(mark))


func _process(_delta: float) -> void:
	if screen == null or screen._tips == null:
		return
	var tips: GlassTips = screen._tips
	most_details = maxi(most_details, tips.details.size())
	if tips.frozen:
		if not saw_frozen:
			frozen_position = tips.tip.position
		elif frozen_position != tips.tip.position:
			moved_while_frozen = true
		saw_frozen = true


func _mark(words: String, pane: Control) -> KeywordMark:
	for node: Node in pane.find_children("*", "KeywordMark", true, false):
		var mark: KeywordMark = node
		if (
			CardTerms.key_of(str(mark.term.get("name", mark.words))) == CardTerms.key_of(words)
			and not str(mark.term.get("reminder", "")).is_empty()
		):
			return mark
	return null


func _point(mark: KeywordMark) -> Vector2:
	return (
		screen._stage.get_global_transform().affine_inverse()
		* (mark.get_global_transform() * (mark.size / 2.0))
	)


func feel_point(target: String) -> Variant:
	if target == "card":
		var card: Control = screen.node_for("board", 1)
		return card.position + card.size / 2.0
	var pane: Control = screen._tips.tip
	var words: String = target
	if target == "nested-medal":
		if screen._tips.details.is_empty():
			return null
		pane = screen._tips.details[0]
		words = "Medal"
	var mark: KeywordMark = _mark(words, pane)
	if mark != null:
		return _point(mark)
	return null


func feel_report() -> Dictionary:
	return {
		"saw_frozen": saw_frozen,
		"most_details": most_details,
		"position_stayed_frozen": not moved_while_frozen,
		"released_closed_both": not screen._tips.tip.visible and screen._tips.details.is_empty()
	}
