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

var _hot_rest_z: int
var _standing_rest_z: int
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
	_layout_details(target)


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
