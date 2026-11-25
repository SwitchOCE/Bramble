class_name RecruitTips
extends GlassTips
## The recruit screen's hover detail in the left column. Discover keeps its own preview beside
## its options, and a hand card rises in place.

const PREVIEW_FIELDS: PackedStringArray = [
	"golden", "attack", "health", "base_attack", "base_health", "max_health"
]

## The hand card standing up while hovered, and where it rests: Vector3(x, y, turn in radians).
var standing: Control
var rest: Vector3 = Vector3.ZERO
## The card a click just put back: its detail shows while it settles.
var put_back: Control

var _recruit: RecruitScreen
var _preview_node: GlassCard
var _original: Dictionary = {}
var _original_marks: Array[KeywordMark] = []


func _init(screen: GlassScreen) -> void:
	super(screen)
	fixed_keywords = true
	_recruit = screen as RecruitScreen
	screen.tree_exiting.connect(_reset_golden)


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
	if not _recruit._waiting.hover(here, self):
		super(here)


func fade() -> void:
	_recruit._waiting.close()
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
	if str(target["kind"]) == "discover":
		_show_discover(target)
		return
	if str(target["kind"]) in ["ability", "ability_off"]:
		_show_ability(target)
		return
	if str(target["kind"]) != "hand" or _recruit.is_aiming():
		super(target, at)
		return
	if hot != node or _icon_mark != null or not tip.visible:
		clear()
		var card: Dictionary = target["card"]
		var text: GlassBox = GlassParts.tip_text(
			card, GlassScreen._is_spell(card), _recruit._reminders(card), _recruit._display_table()
		)
		tip.add_child(text)
	var card_node: Control = node
	set_hot(card_node)
	stand(card_node)
	tip.visible = true
	open_details(target)


func set_hot(node: Control) -> void:
	var previous: Control = hot
	if node != hot:
		_reset_golden()
	super(node)
	# Discover's choices belong above its veil even after the shared hover resets their z.
	for option: Control in [previous, node]:
		if is_instance_valid(option) and option.name.begins_with("Discover_"):
			option.z_index = RecruitDiscover.Z + 1
	if node != standing:
		set_down()


## A hovered hand card stands up, unturned, at the L1 height for its kind.
func stand(node: Control) -> void:
	if standing == node:
		return
	set_down()
	# a card still landing (a click puts a pressed card back) is at its place first
	_recruit._keeper.finish(node)
	standing = node
	rest = Vector3(node.position.x, node.position.y, node.rotation)
	node.rotation = 0.0
	node.position.y = L1Layout.number(
		"hand.spell_hover_y" if node is GlassSpell else "hand.unit_hover_y"
	)


## The standing hand card back to its rest.
func set_down() -> void:
	if is_instance_valid(standing):
		standing.position = Vector2(rest.x, rest.y)
		standing.rotation = rest.z
	standing = null


## The standing hand card is no longer this detail's (a press carries it from where it stands).
func forget_standing() -> void:
	_reset_golden()
	standing = null


## STAND-IN: fit the existing hover artwork and text together above the scoreboard.
func _layout_details(target: Dictionary) -> void:
	if str(target["kind"]) in ["discover", "waiting_preview"]:
		super(target)
		return
	var column: Rect2 = L1Layout.rect("left.hover")
	var parts: Array[Control] = []
	for child: Node in tip.get_children():
		if child is Control and not child.is_queued_for_deletion():
			parts.append(child)
	var height: float = KeywordStyle.GAP * maxi(0, parts.size() - 1)
	for part: Control in parts:
		height += part.size.y * minf(1.0, column.size.x / part.size.x)
	var fit: float = minf(1.0, column.size.y / maxf(1.0, height))
	tip.position = column.position
	var y: float = 0.0
	for part: Control in parts:
		var scale_to_fit: float = fit * minf(1.0, column.size.x / part.size.x)
		part.scale = Vector2.ONE * scale_to_fit
		part.position = Vector2((column.size.x - part.size.x * scale_to_fit) / 2.0, y)
		y += (part.size.y * scale_to_fit + KeywordStyle.GAP * fit)


func show_words(target: Dictionary, at: Vector2) -> void:
	super(target, at)
	open_details(target)


## An ability's existing name, cost and reminder take the same column as unit details.
func _show_ability(target: Dictionary) -> void:
	var node: Control = target["node"]
	if hot != node or _icon_mark != null:
		clear()
		var words: Dictionary = target["card"]
		tip.add_child(
			GlassParts.tip_text(words, false, PackedStringArray(), _screen._display_table())
		)
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
