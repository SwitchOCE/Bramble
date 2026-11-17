class_name RecruitTips
extends GlassTips
## The recruit screen's hover detail: GlassTips' card detail, plus its own kinds. STAND-IN
## (polish.html, m=recruit): a hovered hand card stands up, unturned, wholly on the screen, and its
## detail is the words alone, beside it (the card is already big enough to read). An ability
## button's detail is its words beside its card; a Discover option's is its words over its own
## text pane. No detail shows on a card still on its way somewhere until it is still.

## STAND-IN (polish.html): a hovered hand card stands up unturned, its foot this far above the
## stage's bottom, its words beside it this far to its right.
const HAND_LIFT_FOOT: float = 8.0
const HAND_TIP_GAP: float = 16.0

## The hand card standing up while hovered, and where it rests: Vector3(x, y, turn in radians).
var standing: Control
var rest: Vector3 = Vector3.ZERO
## The card a click just put back: its detail shows while it settles.
var put_back: Control

var _recruit: RecruitScreen


func _init(screen: GlassScreen) -> void:
	super(screen)
	_recruit = screen as RecruitScreen


func show(target: Dictionary, at: Vector2) -> void:
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
	if hot != node:
		clear()
		var card: Dictionary = target["card"]
		var text: GlassBox = GlassParts.tip_text(
			card, GlassScreen._is_spell(card), _recruit._reminders(card)
		)
		text.position = Vector2(0, GlassPieces.rule_number("stage", "#tip .txt", "margin-top"))
		tip.add_child(text)
	var card_node: Control = node
	set_hot(card_node)
	stand(card_node)
	# kept on the screen: a long list of reminders rises above the card's top
	var text_box: GlassBox = last_box()
	var bottom: float = 1080.0 - HAND_LIFT_FOOT - text_box.position.y - text_box.box_size.y
	tip.position = Vector2(
		card_node.position.x + card_node.size.x + HAND_TIP_GAP, minf(card_node.position.y, bottom)
	)
	tip.visible = true


func set_hot(node: Control) -> void:
	super(node)
	if node != standing:
		set_down()


## A hovered hand card stands up, unturned, its foot HAND_LIFT_FOOT above the stage's bottom.
func stand(node: Control) -> void:
	if standing == node:
		return
	set_down()
	# a card still landing (a click puts a pressed card back) is at its place first
	_recruit._keeper.finish(node)
	standing = node
	rest = Vector3(node.position.x, node.position.y, node.rotation)
	node.rotation = 0.0
	node.position.y = 1080.0 - node.size.y - HAND_LIFT_FOOT


## The standing hand card back to its rest.
func set_down() -> void:
	if is_instance_valid(standing):
		standing.position = Vector2(rest.x, rest.y)
		standing.rotation = rest.z
	standing = null


## The standing hand card is no longer this detail's (a press carries it from where it stands).
func forget_standing() -> void:
	standing = null


## STAND-IN (recruit-play.html ?abil=2): an ability button's hover is the words alone (its name,
## its cost, what it does), beside its card on the right, clear of every button on that card.
func _show_ability(target: Dictionary) -> void:
	var node: Control = target["node"]
	if hot != node:
		clear()
		var words: Dictionary = target["card"]
		tip.add_child(GlassParts.tip_text(words, false))
	var card: Control = node.get_parent()
	var box: GlassBox = last_box()
	var x: float = card.position.x + card.size.x + HAND_TIP_GAP
	if x + box.box_size.x > GlassPieces.number("stage.tip.flip_edge"):
		x = card.position.x - HAND_TIP_GAP - box.box_size.x
	tip.position = Vector2(x, card.position.y + node.position.y)
	tip.visible = true
	set_hot(node)


## A Discover option is drawn big already: its hover is the words alone, with every reminder (no
## enlarged copy over it), over the option's own text pane, which it repeats and adds to: the
## other options stay clear.
func _show_discover(target: Dictionary) -> void:
	var node: Control = target["node"]
	if hot != node:
		clear()
		var card: Dictionary = target["card"]
		var text: GlassBox = GlassParts.tip_text(
			card, GlassScreen._is_spell(card), _recruit._reminders(card)
		)
		tip.add_child(text)
	# over the option's own text pane, which it repeats and adds to: the other options stay clear
	var box: GlassBox = last_box()
	tip.position = Vector2(
		node.position.x + node.size.x / 2.0 - box.box_size.x / 2.0,
		node.position.y + node.size.y + RecruitDiscover.TEXT_DOWN
	)
	tip.visible = true
	set_hot(node)
