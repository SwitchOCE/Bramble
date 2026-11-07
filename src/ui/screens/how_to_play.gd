extends Control
## How to play: a short picture guide, shown the first time you start a game and any time from the
## menu. One idea a page, drawn with the game's own trays and tiles. Skip leaves at any point.

signal closed

const UiTheme := preload("res://src/ui/ui_theme.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const Data := preload("res://src/ui/view_data.gd")

const PAGES: Array[Dictionary] = [
	{
		"title": "Build a band, then watch them fight",
		"text":
		(
			"Each turn you spend gold on woodland folk from the shop. "
			+ "Then the fight plays by itself. You don't touch it.\n\n"
			+ "Your choices are who you buy and where you stand them. "
			+ "Last one with Health left wins the game."
		),
		"demo": "shop",
	},
	{
		"title": "Your board is a brick wall",
		"text":
		(
			"Four slots in front, three behind, staggered like bricks. "
			+ "Each back slot sits behind two front slots.\n\n"
			+ "Units stay where you put them. Nobody slides over to fill a gap, "
			+ "even in a fight."
		),
		"demo": "brick",
	},
	{
		"title": "The front row takes the hits",
		"text":
		(
			"Attackers must hit a unit in your front row while anyone is standing there. "
			+ "They pick at random.\n\n"
			+ "Only when the whole front row is gone can the back row be hit. "
			+ "So put the tough ones in front and the fragile ones behind."
		),
		"demo": "target",
	},
	{
		"title": "Who attacks when",
		"text":
		(
			"Units attack in reading order: F1 to F4, then B1 to B3. "
			+ "The two sides take turns, and the side with more units goes first.\n\n"
			+ "A hit hurts both ways: the unit that is hit strikes back with its Attack."
		),
		"demo": "order",
	},
	{
		"title": "Scout who you fight next",
		"text":
		(
			"Tap Scout, or your next opponent's plaque at the top, to see how they stood "
			+ "in their last fight, slot by slot.\n\n"
			+ "They may change it, but it's your best guess. Some cards hit whoever stands "
			+ "across from them, so place your units against what you see."
		),
		"demo": "scout",
	},
	{
		"title": "Winning and losing a fight",
		"text":
		(
			"The fight ends when one side has no units left. "
			+ "The loser loses Health, more if the winner's tier and survivors are high.\n\n"
			+ "Your board comes back whole after every fight. "
			+ "Three copies of a unit make one golden one, twice as strong. "
			+ "Play it to Discover a unit from the tier above."
		),
		"demo": "golden",
	},
	{
		"title": "Who you'll meet",
		"text":
		(
			"Four tribes share the woods, with neutral folk, spells and heroes.\n\n"
			+ "Hedgerow folk spill Acorns, a hand card you play for gold, and hoard them. "
			+ "Fairies lay Rings on slots, hex across the board and paint Rainbows. "
			+ "Oozes hold others in their Bellies. Birds fly south and come back.\n\n"
			+ "With an odd number left, one player fights a ghost: the board of the last "
			+ "player knocked out."
		),
		"demo": "folk",
	},
	{
		"title": "Bellies and birds",
		"text":
		(
			"An Ooze's Belly holds units. Drop one from the shop or your hand onto the Ooze, "
			+ "or tap a unit on the board and then Into a Belly. They wait inside, safe, and "
			+ "when the Ooze dies they come out alive, last in first, wherever there's a gap.\n\n"
			+ "Sell a bird with Fly South and you keep the gold. It comes back to your hand "
			+ "in 2 turns, and its When played fires again. Its slot holds a Nest until then: "
			+ "stand someone on it, or a 0/2 Egg fights there."
		),
		"demo": "held",
	},
]
## The units on the pages: real ones, read from the library so the pages can't go out of date.
const SAMPLE_IDS: PackedStringArray = [
	"mr_crumb", "mrs_sorrel", "hedge_witch", "nan_toadstool", "sleeping_partner"
]

## The page on show, for tests.
var page: int = 0

var _note: WoodPanel
var _title: Label
var _text: Label
var _count: Label
var _demo: Control
var _next: LeafButton
var _previous: LeafButton
var _skip: LeafButton
var _laid_out_for: float = 0.0
var _sample: Array[Dictionary] = []


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	UiTheme.add_table(self)
	_demo = Control.new()
	_demo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_demo)
	_note = WoodPanel.new(WoodPanel.Kind.PAPER)
	_note.nails = true
	add_child(_note)
	_title = UiTheme.head("", UiTheme.FONT_TITLE)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_constant_override("line_spacing", -8)
	_note.add_child(_title)
	_text = UiTheme.label("", UiTheme.FONT_BODY + 4)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.add_child(_text)
	_count = UiTheme.burned("", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_note.add_child(_count)
	_skip = _leaf("Skip", LeafButton.Colour.ACORN, _close)
	_skip.flipped = true
	_previous = _leaf("Back", LeafButton.Colour.BIRCH, _go.bind(-1))
	_previous.flipped = true
	_next = _leaf("Next", LeafButton.Colour.MOSS, _go.bind(1))
	resized.connect(_layout)
	ready.connect(_layout)
	_show_page()


func _leaf(words: String, colour: LeafButton.Colour, on_press: Callable) -> LeafButton:
	var leaf: LeafButton = LeafButton.new()
	leaf.colour = colour
	leaf.set_face(words)
	leaf.pressed.connect(on_press)
	add_child(leaf)
	return leaf


func _go(by: int) -> void:
	if page + by >= PAGES.size():
		_close()
		return
	page = clampi(page + by, 0, PAGES.size() - 1)
	_show_page()


func _close() -> void:
	closed.emit()
	queue_free()


func _show_page() -> void:
	var entry: Dictionary = PAGES[page]
	_title.text = str(entry["title"])
	_text.text = str(entry["text"])
	_count.text = "Page %d of %d" % [page + 1, PAGES.size()]
	_previous.visible = page > 0
	_next.set_face("Play on" if page == PAGES.size() - 1 else "Next")
	_skip.visible = page < PAGES.size() - 1
	for child: Node in _demo.get_children():
		_demo.remove_child(child)
		child.queue_free()
	_build_demo(str(entry["demo"]))


func _layout() -> void:
	var w: float = size.x
	var top: float = maxf(0.0, (size.y - 1080.0) / 2.0)
	var note_w: float = clampf(w * 0.4, 700.0, 900.0)
	_note.position = Vector2(w - note_w - 28.0, top + 28.0)
	_note.size = Vector2(note_w, 860)
	_title.position = Vector2(46, 56)
	_title.size = Vector2(note_w - 92.0, 150)
	_text.position = Vector2(46, 216)
	_text.size = Vector2(note_w - 92.0, 570)
	_count.position = Vector2(46, 794)
	_count.size = Vector2(note_w - 92.0, 44)
	var demo_w: float = w - note_w - 56.0
	_demo.position = Vector2(28, top + 28.0)
	_demo.size = Vector2(demo_w, 860)
	var leaf_y: float = top + 910.0
	_skip.position = Vector2(40, leaf_y)
	_skip.size = Vector2(330, 136)
	_previous.position = Vector2(w - 780.0, leaf_y)
	_previous.size = Vector2(350, 136)
	_next.position = Vector2(w - 410.0, leaf_y)
	_next.size = Vector2(380, 136)
	_show_page_demo_again()


## The demos are placed for the space they have, so a new size builds them again.
func _show_page_demo_again() -> void:
	if not is_equal_approx(_laid_out_for, _demo.size.x):
		_laid_out_for = _demo.size.x
		for child: Node in _demo.get_children():
			_demo.remove_child(child)
			child.queue_free()
		_build_demo(str(PAGES[page]["demo"]))


func _build_demo(kind: String) -> void:
	if _demo.size.x < 10.0:
		return
	match kind:
		"shop":
			_demo_shop()
		"brick":
			_demo_board(false)
		"target":
			_demo_target()
		"order":
			_demo_order()
		"scout":
			_demo_scout()
		"golden":
			_demo_golden()
		"folk":
			_demo_folk()
		"held":
			_demo_held()


## Real units from the library for the demos; any of these gone, the next that exists stands in.
func _samples() -> Array[Dictionary]:
	if not _sample.is_empty():
		return _sample
	var library: UnitLibrary = UnitLibrary.load_dir()
	for id: String in SAMPLE_IDS:
		var def: Dictionary = library.get_unit(id)
		if not def.is_empty():
			_sample.append(UnitViews.from_def(def))
	for def: Dictionary in library.pool_units("slice"):
		if _sample.size() >= SAMPLE_IDS.size():
			break
		if not SAMPLE_IDS.has(str(def["id"])):
			_sample.append(UnitViews.from_def(def))
	return _sample


## An Ooze with a unit inside, and a bird with its way home.
func _demo_held() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var width: float = minf(300.0, _demo.size.x / 2.0 - 60.0)
	var gap: float = (_demo.size.x - width * 2.0) / 3.0
	var top: float = maxf(0.0, _demo.size.y / 2.0 - width * 0.8)
	var ooze: Dictionary = UnitViews.from_def(library.get_unit("little_dollop"))
	_tile(ooze, Vector2(gap, top), width, CardView.Mode.SHOP)
	var bird: Dictionary = UnitViews.from_def(library.get_unit("one_swallow"))
	_tile(bird, Vector2(gap * 2.0 + width, top), width, CardView.Mode.SHOP)


func _tile(view: Dictionary, at: Vector2, width: float, mode: CardView.Mode) -> CardView:
	var card: CardView = CardView.new()
	card.show_unit(view.duplicate(true), mode)
	card.set_card_width(width)
	card.position = at
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_demo.add_child(card)
	return card


func _demo_shop() -> void:
	var w: float = _demo.size.x
	var width: float = minf(270.0, (w - 80.0) / 3.0 - 30.0)
	var gap: float = (w - width * 3.0) / 4.0
	for i: int in 3:
		var view: Dictionary = _samples()[i + 2]
		_tile(view, Vector2(gap + i * (width + gap), 90), width, CardView.Mode.SHOP)
	var acorn: TextureRect = TextureRect.new()
	acorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	acorn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	acorn.texture = Icons.icon("acorn", 105.0)
	acorn.position = Vector2(gap, 500)
	acorn.size = Vector2(105, 105)
	_demo.add_child(acorn)
	var words: Label = UiTheme.head("3 gold buys any unit", UiTheme.FONT_TITLE)
	words.position = Vector2(gap + 120.0, 516)
	_demo.add_child(words)


## The brick with a few units standing in it.
func _demo_board(hurt_front: bool) -> BoardView:
	var board: BoardView = BoardView.new()
	var pocket: float = minf(230.0, (_demo.size.x - 60.0) / 4.0 - 26.0)
	board.configure("guide", pocket, true, false, not hurt_front)
	_demo.add_child(board)
	var tray: Vector2 = board.tray_size()
	board.position = Vector2((_demo.size.x - tray.x) / 2.0, (_demo.size.y - tray.y) / 2.0)
	for pair: Array in [[0, 0], [1, 1], [4, 2]]:
		var slot: int = pair[0]
		var view: Dictionary = _samples()[pair[1]]
		var card: CardView = CardView.new()
		card.show_unit(view.duplicate(true), CardView.Mode.BOARD)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board.place_card(card, slot)
	for slot: Control in board.slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return board


func _demo_target() -> void:
	var board: BoardView = _demo_board(true)
	for card: CardView in [board.cards[0], board.cards[1]]:
		card.outline = UiTheme.YARN
	var words: Label = UiTheme.burned("Can be hit", UiTheme.FONT_BODY, UiTheme.CREAM)
	words.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.HEALTH, 5, 10))
	words.position = board.position + Vector2(40, -64)
	_demo.add_child(words)
	var safe: Label = UiTheme.burned("Safe for now", UiTheme.FONT_BODY)
	safe.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.BIRCH, 5, 10))
	safe.position = board.position + Vector2(150, board.tray_size().y + 12.0)
	_demo.add_child(safe)


func _demo_order() -> void:
	var board: BoardView = _demo_board(true)
	var order: PackedStringArray = ["1", "2", "3", "4", "5", "6", "7"]
	for slot: int in BoardView.SLOTS:
		board.slots[slot].filled = true
		var number: Label = UiTheme.number(order[slot], UiTheme.FONT_BODY)
		var face: StyleBoxFlat = UiTheme.flat_box(UiTheme.ACORN, UiTheme.INK, 4, 30)
		face.set_content_margin_all(0)
		number.add_theme_stylebox_override("normal", face)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.size = Vector2(58, 58)
		number.position = (
			board.position + board.slot_position(slot) + board.pocket / 2.0 - Vector2(29, 29)
		)
		number.z_index = 5
		_demo.add_child(number)


func _demo_scout() -> void:
	var board: BoardView = _demo_board(true)
	var words: Label = UiTheme.burned("Last fight, they stood here", UiTheme.FONT_BODY)
	words.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.BIRCH, 5, 10))
	words.position = board.position + Vector2(40, -64)
	_demo.add_child(words)


func _demo_golden() -> void:
	var w: float = _demo.size.x
	var view: Dictionary = _samples()[1].duplicate(true)
	var small: float = 172.0
	for i: int in 3:
		var at: Vector2 = Vector2((w - small * 3.0 - 80.0) / 2.0 + i * (small + 40.0), 110)
		_tile(view, at, small, CardView.Mode.BOARD)
	view["golden"] = true
	view["attack"] = Data.i(view, "attack") * 2
	view["health"] = Data.i(view, "health") * 2
	_tile(view, Vector2((w - 270.0) / 2.0, 400), 270.0, CardView.Mode.SHOP)


func _demo_folk() -> void:
	var w: float = _demo.size.x
	var width: float = minf(270.0, (w - 80.0) / 2.0 - 30.0)
	var gap: float = (w - width * 2.0) / 3.0
	var views: Array[Dictionary] = _samples()
	_tile(views[0], Vector2(gap, 90), width, CardView.Mode.SHOP)
	_tile(views[3], Vector2(gap * 2.0 + width, 90), width, CardView.Mode.SHOP)
	_tile(views[4], Vector2(gap, 460), width, CardView.Mode.SHOP)
	_tile(views[2], Vector2(gap * 2.0 + width, 460), width, CardView.Mode.SHOP)
