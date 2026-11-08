extends Control
## How to play: a short picture guide, shown the first time you start a game and any time from the
## menu. One idea a page, drawn with the game's own trays and tiles. Skip leaves at any point.

signal closed

const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")
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
			"Buy a unit for 3 gold, then drag it from your hand to an empty slot. Tap "
			+ "a card and its action buttons if you prefer.\n\nEnd turn starts an "
			+ "automatic fight. Your band returns whole afterwards. Outlast seven rivals"
			+ " to win."
		),
		"demo": "shop",
	},
	{
		"title": "A little more gold each round",
		"text":
		(
			"Round 1 gives 3 gold; then 4, 5, 6, 7, 8, 9, and 10 from round 8 onwards."
			+ " Unspent gold carries over.\n\nBuy a unit now, or save for a better shop "
			+ "tier. Cards and your hero can earn extra gold."
		),
		"demo": "income",
	},
	{
		"title": "Shape your next shop",
		"text":
		(
			"Tier up unlocks higher-tier cards and larger shops. Its price falls by 1 "
			+ "each round you wait. Upgrading leaves the current offers as they are.\n\n"
			+ "Refresh replaces the offers, usually for 1 gold. Freeze is free and keeps"
			+ " the remaining offers for next round. Sell a bought unit for 1 gold: tap "
			+ "it, then Sell."
		),
		"demo": "tools",
	},
	{
		"title": "Your hero and your spells",
		"text":
		(
			"Choose one hero at the start. Read its power: some work by themselves, "
			+ "others have a button and a gold cost.\n\nSpells sit beside units in the "
			+ "shop. Buy one into your hand, then play it for no further gold. A spell "
			+ "asking for a target lights up where it can go."
		),
		"demo": "magic",
	},
	{
		"title": "Help your favourites grow",
		"text":
		(
			"A 2/3 unit has 2 Attack and 3 Health. Permanent bonuses stay for later "
			+ "fights; bonuses marked “this fight” disappear afterwards. Rings belong to"
			+ " slots, so moving a unit can change its stats.\n\nThree ordinary copies "
			+ "combine into a golden unit, keeping permanent bonuses. Play it to "
			+ "Discover: pick one free unit from the tier above your shop (up to tier "
			+ "6)."
		),
		"demo": "golden",
	},
	{
		"title": "Your board is a brick wall",
		"text":
		(
			"Four slots in front, three behind. B1 sits behind F1 and F2; B2 behind F2"
			+ " and F3; B3 behind F3 and F4.\n\nSo “behind F2” means both B1 and B2. Units"
			+ " stay where you put them; nobody slides into a gap."
		),
		"demo": "brick",
	},
	{
		"title": "The front row takes the hits",
		"text":
		(
			"Attackers choose randomly from the enemy front row while anyone stands "
			+ "there. Only an empty front row exposes the back.\n\nPut tough units in "
			+ "front and fragile helpers behind. A hit hurts both ways: the defender "
			+ "strikes back with its Attack. Card text can change these rules."
		),
		"demo": "target",
	},
	{
		"title": "Who attacks when",
		"text":
		(
			"Units attack in reading order: F1 to F4, then B1 to B3. The two sides "
			+ "take turns; the side with more units goes first.\n\nNew keywords are "
			+ "explained when you tap the card that uses them. Try one new trick at a "
			+ "time; you do not need to learn a glossary first."
		),
		"demo": "order",
	},
	{
		"title": "Scout who you fight next",
		"text":
		(
			"Tap Scout or your next opponent’s plaque to see their last fighting "
			+ "board, slot by slot. They may change it before this fight.\n\n“Across” "
			+ "means the same slot label on their board: your F2 faces their F2. Aim "
			+ "cards and place units using what you see."
		),
		"demo": "scout",
	},
	{
		"title": "Stay standing to win",
		"text":
		(
			"40 Health. Lose: round base + 1 per winner’s own starting survivor. "
			+ "Base rises; no cap or toll. Armor absorbs first; ties deal 0.\n"
			+ "Count units before Start of Combat. Goldens count 1. Returns count; "
			+ "combat summons, copies and stolen enemies don’t.\n"
			+ "Last Blow: attacker or finishing effect wins a mutual wipe for base damage. "
			+ "Start of Combat wipes tie.\n"
			+ "Last Stand: at four or fewer living heroes, once a game a lethal loss "
			+ "from 2+ Health leaves 1. Ghosts never use it. Lobby: ready/used/locked."
		),
		"demo": "target",
	},
	{
		"title": "Make room for your tribe",
		"text":
		(
			"Each game offers five tribes. Stand Behind Me and Bread from the Back "
			+ "give more to units that share a tribe with their target.\n\n"
			+ "From tier 3, Harvest Supper gives a tribe +1/+1 permanently, up to +3/+3, once a turn. "
			+ "The bonus follows units anywhere you own them, and ones you get later; "
			+ "it excludes summons made in fights. The tribe icons show each bonus. "
			+ "With five units of one tribe on your board, Hiring Fair finds one while copies remain."
		),
		"demo": "commitment",
	},
	{
		"title": "Oozes hold; Birds travel",
		"text":
		(
			"Drop a unit into an Ooze's Belly to keep it inside. When the Ooze faints, "
			+ "its units come out, last in first. Moss Ooze shares spell stats with them.\n\n"
			+ "Fly South sends a Bird away for no sale gold. Its empty Nest fights as an "
			+ "Egg with half the Bird's Attack and Health, rounded up, and no text. "
			+ "Mother Goose's Egg "
			+ "stays 0/2. Birds return to hand and cannot fly on the turn they land. "
			+ "You can always tap a card to read its special rules."
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
		"income":
			_demo_income()
		"tools":
			_demo_tools()
		"magic":
			_demo_magic()
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
		"lanes":
			_demo_lanes()
		"held":
			_demo_held()
		"commitment":
			_demo_commitment()


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


func _demo_lanes() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var own: Array = [
		UnitViews.from_def(library.get_unit("madame_bufo")),
		UnitViews.from_def(library.get_unit("little_nip")),
		null,
		null,
		null,
		null,
		null
	]
	var enemy: Array = [
		UnitViews.from_def(library.get_unit("field_vole")),
		UnitViews.from_def(library.get_unit("mrs_sorrel")),
		null,
		null,
		null,
		null,
		null
	]
	var boards: Array = []
	for side: int in 2:
		var board: BoardView = BoardView.new()
		board.configure("guide", 130, side == 0)
		for pocket: Control in board.slots:
			pocket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_demo.add_child(board)
		board.position = Vector2((_demo.size.x - board.tray_size().x) / 2, 430 if side == 0 else 40)
		var units: Array = own if side == 0 else enemy
		for slot: int in 2:
			var card: CardView = CardView.new()
			var view: Dictionary = units[slot]
			card.show_unit(view, CardView.Mode.BOARD)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			board.place_card(card, slot)
		boards.append(board)
	var overlay: LaneOverlay = LaneOverlay.new()
	overlay.boards = boards
	overlay.bindings = LaneProjection.new().forecast([own, enemy])
	_demo.add_child(overlay)


## Short examples use the same prices and cards as recruiting.
func _example_line(words: String, y: float) -> void:
	var label: Label = UiTheme.head(words, UiTheme.FONT_BODY + 4)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(26, y)
	label.size = Vector2(_demo.size.x - 52, 130)
	_demo.add_child(label)


func _demo_income() -> void:
	_example_line("Round       1     2     3     …     8+", 140)
	_example_line("Gold          3     4     5     …     10", 290)
	_example_line("Save 2 + next round’s 4 = 6 to spend", 490)


func _demo_tools() -> void:
	var examples: Array = [
		["Refresh", "refresh", 1, "New offers"],
		["Freeze", "freeze", -1, "Keep these offers"],
		["Tier up", "tier", 5, "Better future shops"],
		["Sell", "", -1, "Free a slot, gain 1 gold"],
	]
	var width: float = minf(380, _demo.size.x * 0.46)
	for index: int in examples.size():
		var entry: Array = examples[index]
		var button: LeafButton = LeafButton.new()
		button.colour = LeafButton.Colour.FROST if index == 1 else LeafButton.Colour.ACORN
		button.set_face(str(entry[0]), str(entry[1]), CoreUtil.to_int(entry[2]))
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.position = Vector2(12, 40 + index * 190)
		button.size = Vector2(width, 144)
		_demo.add_child(button)
		var label: Label = UiTheme.head(str(entry[3]), UiTheme.FONT_BODY)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.position = Vector2(width + 30, button.position.y + 36)
		label.size = Vector2(_demo.size.x - width - 46, 130)
		_demo.add_child(label)


func _demo_magic() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var spell: Dictionary = library.get_card("pinch_of_dust")
	var item: HandItem = HandItem.make(spell, 0)
	var width: float = minf(300, (_demo.size.x - 90) / 2)
	var gap: float = (_demo.size.x - 2 * width) / 3
	_tile(item.view(), Vector2(gap, 120), width, CardView.Mode.SHOP)
	const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
	var hero: Dictionary = library.get_hero("brother_bracken").duplicate(true)
	hero["id"] = "brother_bracken"
	_tile(RecruitView.hero_card(hero), Vector2(gap * 2 + width, 120), width, CardView.Mode.SHOP)
	_example_line("Buy → hand → choose a target", 580)


func _demo_commitment() -> void:
	const TribeBonuses := preload("res://src/ui/widgets/tribe_bonuses.gd")
	var icons: TribeBonuses = TribeBonuses.new()
	icons.position = Vector2((_demo.size.x - 560) / 2, 180)
	icons.size = Vector2(560, TribeBonuses.HEIGHT)
	icons.show_bonuses(["Fairies", "Oozes", "Birds"], {"Fairies": 2, "Oozes": 1})
	_demo.add_child(icons)
	var library: UnitLibrary = UnitLibrary.load_dir()
	var supper: HandItem = HandItem.make(library.get_card("harvest_supper"), 0)
	_tile(supper.view(), Vector2((_demo.size.x - 300) / 2, 330), 300, CardView.Mode.SHOP)
	_example_line("Same tribe, a stronger new arrival", 700)
