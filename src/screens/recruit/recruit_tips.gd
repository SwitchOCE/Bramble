class_name RecruitTips
extends GlassTips
## The recruit screen's card hover follows its source. Keyword reminders have their own
## fixed overlay above the scoreboard.

const PREVIEW_FIELDS: PackedStringArray = [
	"golden", "attack", "health", "base_attack", "base_health", "max_health"
]

## The hand card standing up while hovered, and where it rests: Vector3(x, y, turn in radians).
var standing: Control
var rest: Vector3 = Vector3.ZERO
## The card a click just put back: its detail shows while it settles.
var put_back: Control

var _hot_rest_z: int
var _standing_rest_z: int
var _recruit: RecruitScreen
var _keywords: Control
var _preview_node: GlassCard
var _original: Dictionary = {}
var _original_marks: Array[KeywordMark] = []


func _init(screen: GlassScreen) -> void:
	super(screen)
	fixed_keywords = true
	# Wrap reminders to the column at their usual font sizes.
	keyword_width = L1Layout.number("column.w") - L1Layout.point("left.hover").x
	_recruit = screen as RecruitScreen
	screen.tree_exiting.connect(_reset_golden)


func make_tip() -> void:
	super()
	if is_instance_valid(_keywords) and _keywords.get_parent() == _screen._front:
		return
	_keywords = Control.new()
	_keywords.name = "KeywordReminders"
	_keywords.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keywords.position = L1Layout.point("left.hover")
	_keywords.z_index = tip.z_index
	_screen._front.add_child(_keywords)


func _keyword_parent() -> Control:
	return _keywords


## The owner's choice: "Golden in place" for a hand card and a Discover option.
func _show_golden(target: Dictionary, at: Vector2) -> void:
	if str(target["kind"]) not in ["hand", "discover"]:
		super(target, at)
		return
	show(target, at)
	if hot != target["node"] or not tip.visible:
		return
	var node: GlassCard = target["node"]
	if _preview_node == node:
		return
	_preview_node = node
	for key: String in PREVIEW_FIELDS:
		_original[key] = node.get(key)
	for child: Node in node.get_children():
		if child is KeywordMark:
			_original_marks.append(child)
			node.remove_child(child)
	var card: Dictionary = target["card"]
	var golden: GlassCard = _screen._unit_card(card, node.card_height)
	for key: String in PREVIEW_FIELDS:
		node.set(key, golden.get(key))
	for child: Node in golden.get_children():
		golden.remove_child(child)
		node.add_child(child)
	node.set_numbers(golden.attack, golden.health)
	golden.free()


func _reset_golden() -> void:
	if is_instance_valid(_preview_node):
		for key: String in PREVIEW_FIELDS:
			_preview_node.set(key, _original[key])
		for child: Node in _preview_node.get_children():
			if child is KeywordMark:
				_preview_node.remove_child(child)
				child.queue_free()
		for mark: KeywordMark in _original_marks:
			_preview_node.add_child(mark)
		_preview_node.set_numbers(_preview_node.attack, _preview_node.health)
	else:
		for mark: KeywordMark in _original_marks:
			mark.queue_free()
	_preview_node = null
	_original.clear()
	_original_marks.clear()


func _pause_preview() -> void:
	if _preview_node != null:
		hide()


func hover(here: Vector2) -> void:
	if _recruit._waiting.hover(here, self):
		return
	var drop: int = GlassPieces.as_int(_recruit.state.get("tier_up_drop", 0))
	var target: Dictionary = _recruit.target_at(here, false)
	if drop > 0 and target.get("id", "") == "tier" and not _recruit.is_discovering():
		var button: Control = target["node"]
		_show_discount(button, drop)
	else:
		super(here)


func _show_discount(button: Control, drop: int) -> void:
	if hot != button or not tip.visible:
		clear()
		var pane: GlassBox = GlassBox.new()
		pane.name = "TierUpDrop"
		pane.use_css("stage", "#tip .txt")
		var words: GlassText = GlassText.from_rule("stage", "#tip .n", "−%d next turn" % drop)
		words.name = "Value"
		words.colour = GlassPieces.rule_colour("stage", "#tip .txt", "color")
		words.refresh()
		var pad: Array = GlassPieces.rule("stage", "#tip .txt", "padding")
		words.position = Vector2(GlassPieces.as_float(pad[1]), GlassPieces.as_float(pad[0]))
		words.position += Vector2.ONE * pane.border_width
		pane.box_size = words.size + words.position * 2.0
		pane.refresh()
		pane.add_child(words)
		tip.add_child(pane)
		var gap: float = GlassPieces.number("stage.tip.gap")
		tip.position = (
			button.position + Vector2(-pane.size.x - gap, (button.size.y - pane.size.y) / 2.0)
		)
	set_hot(button)
	tip.show()


func fade() -> void:
	_recruit._waiting.close()
	_drop_details()
	super()


func show(target: Dictionary, at: Vector2) -> void:
	if target["kind"] == "waiting_pile":
		_recruit._waiting.hover(at, self)
		return
	var node: Control = target.get("node")
	if node != null and node != put_back and _recruit._keeper.is_busy(node):
		# no detail on a card still on its way (just dropped, say) until it is still
		hide()
		return
	if str(target["kind"]) == "player":
		_show_player(target)
		return
	if str(target["kind"]) == "discover":
		_show_discover(target)
		return
	if str(target["kind"]) in ["ability", "ability_off"]:
		_show_ability(target)
		return
	super(target, at)


## The portrait's player name sits beside the scoreboard.
func _show_player(target: Dictionary) -> void:
	var node: Control = target["node"]
	if hot != node or not tip.visible:
		clear()
		var player: Dictionary = target["card"]
		var box: GlassBox = GlassBox.new()
		box.use_css("stage", "#tip .txt")
		var label: GlassText = GlassText.from_rule("stage", "#tip .n", str(player.get("name", "")))
		label.colour = GlassPieces.rule_colour("stage", "#tip .txt", "color")
		label.refresh()
		var pad: Array = GlassPieces.rule("stage", "#tip .txt", "padding")
		label.position = (
			Vector2(GlassPieces.as_float(pad[1]), GlassPieces.as_float(pad[0]))
			+ Vector2.ONE * box.border_width
		)
		box.box_size = label.size + 2.0 * label.position
		box.refresh()
		box.add_child(label)
		tip.add_child(box)
		tip.position = Vector2(
			L1Layout.number("left.player_tip.x"),
			clampf(node.position.y, 0.0, L1Layout.stage_size().y - box.size.y)
		)
	set_hot(node)
	tip.show()


func set_hot(node: Control) -> void:
	var previous: Control = hot
	if node != hot:
		_reset_golden()
		_hot_rest_z = node.z_index if is_instance_valid(node) else 0
	super(node)
	if previous != node:
		light_tier(previous, false)
		light_tier(node, true)
	# Discover's choices belong above its veil even after the shared hover resets their z.
	for option: Control in [previous, node]:
		if is_instance_valid(option) and option.name.begins_with("Discover_"):
			option.z_index = RecruitDiscover.Z + 1
	if node != standing:
		set_down()


## The tier on hover (buy-screen-l1.md §11 item 15, owner L3): a board or hand card pointed at
## gets its tier's light hugging it, the same light as a shop card's halo (S1). Nothing is drawn
## on the card itself.
func light_tier(node: Control, on: bool) -> void:
	if not is_instance_valid(node):
		return
	var old: Node = node.get_node_or_null("TierLight")
	if old != null:
		node.remove_child(old)
		old.queue_free()
	if not on:
		return
	var card: Dictionary = {}
	for target: Dictionary in _recruit._targets:
		if target.get("node") == node and str(target["kind"]) in ["board", "hand"]:
			card = target.get("card", {})
			break
	var face: Control = node.get_node_or_null("Face")
	if card.is_empty() or face == null or not card.has("tier"):
		return
	var light: L1Light = tier_hug(node, GlassPieces.as_int(card["tier"]))
	node.add_child(light)
	node.move_child(light, face.get_index())


## The tier's light hugging a card or hand spell, behind its face (not yet added to it).
static func tier_hug(node: Control, tier: int) -> L1Light:
	var face: Control = node.get_node("Face")
	var tint: Color = L1Layout.shop_tint(tier)
	var circle: bool = node is GlassSpell
	var light: L1Light = L1Light.make(
		L1Light.Shape.CIRCLE if circle else L1Light.Shape.CARD,
		Rect2(Vector2.ZERO, node.size),
		Color(tint, 1.0),
		"TierLight"
	)
	light.show_behind_parent = face.show_behind_parent
	light.glow(
		Vector3(
			L1Layout.number("light.hover.grow"),
			L1Layout.number("light.hover.blur"),
			L1Layout.number("light.hover.share") * tint.a
		)
	)
	light.blend(L1Layout.number("light.shop.additive"))
	return light


## A hovered hand card stands up, unturned, at the L1 height for its kind.
func stand(node: Control) -> void:
	if standing == node:
		return
	set_down()
	# a card still landing (a click puts a pressed card back) is at its place first
	_recruit._keeper.finish(node)
	standing = node
	_standing_rest_z = _hot_rest_z if node == hot else node.z_index
	rest = Vector3(node.position.x, node.position.y, node.rotation)
	node.rotation = 0.0
	node.z_index = int(L1Layout.number("hand.hover_z"))
	_set_raised(true)
	node.position.y = L1Layout.number(
		"hand.spell_hover_y" if node is GlassSpell else "hand.unit_hover_y"
	)


## The standing hand card back to its rest.
func set_down() -> void:
	if is_instance_valid(standing):
		standing.position = Vector2(rest.x, rest.y)
		standing.rotation = rest.z
	_release_standing()


## The standing hand card is no longer this detail's (a press carries it from where it stands).
func forget_standing() -> void:
	_reset_golden()
	_release_standing()


func _release_standing() -> void:
	if is_instance_valid(standing):
		standing.z_index = _standing_rest_z
		_set_raised(false)
	standing = null


func _set_raised(on: bool) -> void:
	if standing is GlassCard:
		(standing as GlassCard).set_raised(on)
	elif standing is GlassSpell:
		(standing as GlassSpell).set_raised(on)


## Keep the card and its words together near their source, clear of the side columns.
func _layout_details(target: Dictionary) -> void:
	var y: float = 0.0
	for box: GlassBox in details:
		box.position.y = y
		y += box.size.y + KeywordStyle.GAP
	var words: GlassBox = tip.get_node_or_null("Words")
	if words == null:
		return
	var kind: String = str(target["kind"])
	var node: Control = target["node"]
	if kind == "hand" and not _recruit.is_aiming():
		stand(node)
	var card: Control = tip.get_node_or_null("Card")
	var art: Rect2 = card.get_rect() if card != null else Rect2()
	var source: Rect2 = _source_rect(node)
	var preferred: Vector2 = tip.position
	var middle: Rect2 = L1Layout.middle()
	var gap: float = GlassPieces.number("stage.tip.gap")
	var wall: float = L1Layout.number("room.wall.h")
	var in_shop: bool = kind in ["shop", "spell"] and source.position.y < wall
	var right_edge: float = L1Layout.number("shop.tablet.x") if in_shop else middle.end.x
	var text_rect: Rect2 = words.get_rect()
	if kind != "discover":
		if kind in ["ability", "ability_off"]:
			source = _source_rect(node.get_parent() as Control)
		preferred.x = source.end.x + gap
		if preferred.x + text_rect.end.x > right_edge - KeywordStyle.GAP:
			preferred.x = source.position.x - gap - text_rect.end.x
		if kind == "hand":
			preferred.y = source.end.y - maxf(art.end.y, text_rect.end.y)
		elif kind == "board":
			preferred.y = maxf(preferred.y, wall + KeywordStyle.GAP)
	# The repeated words must still lie over their Discover option's text pane.
	var columns: Array[Rect2] = [
		Rect2(Vector2.ZERO, Vector2(middle.position.x, middle.size.y)),
		Rect2(
			Vector2(right_edge, 0.0), Vector2(L1Layout.stage_size().x - right_edge, middle.size.y)
		),
	]
	var places: Array[Vector2] = KeywordLayout.arrange(
		art, text_rect, preferred, source, [], columns
	)
	assert(not places.is_empty(), "Recruit card detail must fit clear of its source and columns")
	if not places.is_empty():
		tip.position = places[0]
		var beside: bool = (
			tip.position.x >= source.end.x or tip.position.x + text_rect.end.x <= source.position.x
		)
		if in_shop and beside:
			_raise_shop_detail(art, text_rect, card is GlassCard)


## Keep the rules above the board. A unit's bottom point can nest between the front row's top
## points when its full-height copy is taller than the space above them.
func _raise_shop_detail(art: Rect2, words: Rect2, is_unit: bool) -> void:
	var board_top: float = _recruit.slot_xy(0).y
	var art_foot: float = board_top
	if is_unit:
		var art_center: float = tip.position.x + art.get_center().x
		var half_card: float = _recruit.card_box().x / 2.0
		var clearance: float = art.size.x / 2.0
		for slot: int in GlassScreen.FRONT_SLOTS:
			var center: float = _recruit.slot_xy(slot).x + half_card
			clearance = minf(clearance, absf(center - art_center))
		art_foot += clearance * tan(L1CardFace.point_angle())
	var max_top: float = minf(art_foot - art.end.y, board_top - words.end.y)
	tip.position.y = minf(tip.position.y, maxf(0.0, floorf(max_top - 2.0)))


func show_words(target: Dictionary, at: Vector2) -> void:
	super(target, at)
	# Counter readouts keep their existing pane in the left column.
	var column: Rect2 = L1Layout.rect("left.hover")
	var words: GlassBox = last_box()
	var fit: float = minf(1.0, minf(column.size.x / words.size.x, column.size.y / words.size.y))
	tip.position = column.position
	words.position = Vector2((column.size.x - words.size.x * fit) / 2.0, 0.0)
	words.scale = Vector2.ONE * fit


## An ability's name, cost and rules sit beside its card.
func _show_ability(target: Dictionary) -> void:
	var node: Control = target["node"]
	if hot != node or _icon_mark != null or not tip.visible:
		clear()
		var words: Dictionary = target["card"]
		tip.add_child(
			GlassParts.tip_text(words, false, PackedStringArray(), _screen._display_table())
		)
	tip.position.y = _source_rect(node).position.y
	tip.visible = true
	open_details(target)
	set_hot(node)


## A Discover option is drawn big already: its hover is the words alone, with every reminder (no
## enlarged copy over it), over the option's own text pane, which it repeats and adds to: the
## other options stay clear.
func _show_discover(target: Dictionary) -> void:
	var node: Control = target["node"]
	if hot != node or _icon_mark != null or not tip.visible:
		clear()
		var card: Dictionary = target["card"]
		var text: GlassBox = GlassParts.tip_text(
			card, GlassScreen._is_spell(card), _recruit._reminders(card), _recruit._display_table()
		)
		tip.add_child(text)
	# over the option's own text pane, which it repeats and adds to: the other options stay clear
	var box: GlassBox = last_box()
	tip.position = Vector2(
		node.position.x + node.size.x / 2.0 - box.box_size.x / 2.0,
		node.position.y + node.size.y + RecruitDiscover.TEXT_DOWN
	)
	tip.visible = true
	open_details(target)
	set_hot(node)
