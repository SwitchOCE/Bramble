class_name RecruitParts
extends RefCounted
## Pieces of the recruit screen built whole from its state, kept out of recruit_screen.gd.


## The right light's sill: the next opponent's portrait, which ends the turn, under its words.
static func build_end_turn(screen: RecruitScreen) -> void:
	var height: float = screen._stage.size.y
	var x: float = (
		1904.0
		- GlassPieces.number("stage.recruit.end.margin")
		- GlassPieces.number("stage.recruit.end.port_room")
		- GlassPieces.number("stage.recruit.end.inset")
	)
	var words: GlassText = GlassText.from_rule("stage", ".lbl", "End turn")
	words.name = "EndTurnWords"
	words.font_px = GlassPieces.number("stage.recruit.end.label_size")
	words.colour = GlassPieces.rule_colour("stage", ".endlbl", "color")
	words.refresh()
	words.position = Vector2(
		x - GlassPieces.number("stage.recruit.end.label_left"),
		height - GlassPieces.number("stage.recruit.end.label_up")
	)
	screen._front.add_child(words)
	var next: Dictionary = screen.state.get("next_opponent", {})
	var side: float = GlassPieces.number("stage.recruit.end.port")
	var port: GlassBox = GlassParts.make_portrait(str(next.get("portrait", "")), side, [".endturn"])
	port.name = "EndTurn"
	port.position = Vector2(x, height - GlassPieces.number("stage.recruit.end.port_up"))
	screen._front.add_child(port)
	var hp: GlassBox = GlassParts.health_badge(GlassPieces.as_int(next.get("health", 0)), [".hp"])
	hp.position = Vector2(
		x - GlassPieces.number("stage.recruit.end.hp_left"),
		height - GlassPieces.number("stage.recruit.end.hp_up")
	)
	screen._front.add_child(hp)
	screen._targets.append(
		{
			"kind": "button",
			"index": 0,
			"id": "end_turn",
			"node": port,
			"poly": RecruitScreen._circle(port.box_size)
		}
	)


## STAND-IN (recruit-play.html ?abil=2): an ability button's hover is the words alone (its name,
## its cost, what it does), beside its card on the right, clear of every button on that card.
static func show_ability_tip(screen: RecruitScreen, target: Dictionary) -> void:
	var node: Control = target["node"]
	if screen._hot != node:
		for child: Node in screen._tip.get_children():
			screen._tip.remove_child(child)
			child.queue_free()
		var words: Dictionary = target["card"]
		screen._tip.add_child(GlassParts.tip_text(words, false))
	var card: Control = node.get_parent()
	var box: GlassBox = screen._tip.get_child(screen._tip.get_child_count() - 1)
	var x: float = card.position.x + card.size.x + RecruitScreen.HAND_TIP_GAP
	if x + box.box_size.x > GlassPieces.number("stage.tip.flip_edge"):
		x = card.position.x - RecruitScreen.HAND_TIP_GAP - box.box_size.x
	screen._tip.position = Vector2(x, card.position.y + node.position.y)
	screen._tip.visible = true
	screen._set_hot(node)


## The hand's count, left of the hand: "Hand 2/7".
static func build_hand_count(screen: RecruitScreen) -> void:
	var hand: Array = screen.state.get("hand", [])
	var n: int = hand.size()
	# a card on its way to the hand counts once it is there
	var shown: int = screen._hand_held if screen._hand_held >= 0 else n
	var step: float = screen._w() * GlassPieces.number("stage.recruit.hand.step_per_w")
	var hw: float = step * (n - 1) + screen._w()
	var label: GlassText = GlassText.from_rule(
		"stage",
		".lbl",
		"Hand %d/%d" % [shown, GlassPieces.as_int(screen.state.get("hand_limit", 7))]
	)
	label.name = "HandCount"
	label.font_px = GlassPieces.number("stage.recruit.hand_label.size")
	label.colour = GlassPieces.colour("stage.recruit.hand_label.colour")
	label.refresh()
	label.position = Vector2(
		960.0 - hw / 2.0 - GlassPieces.number("stage.recruit.hand_label.left"),
		RecruitScreen._f(screen._g["handTop"]) + GlassPieces.number("stage.recruit.hand_label.down")
	)
	screen._front.add_child(label)


## A card bought onto a unit flies to the hand: the hand's count from before shows until it is
## there (CardKeeper.flown).
static func hold_hand_count(screen: RecruitScreen, before: Dictionary) -> void:
	var was_hand: Array = before.get("hand", [])
	var hand: Array = screen.state.get("hand", [])
	var was: int = was_hand.size()
	if before.is_empty() or was >= hand.size():
		return
	if not _hand_flying(screen):
		return
	screen._hand_held = was
	_show_hand_count(screen)


## A flight ended: once no card is still flying into the hand, the hand's count is the state's.
static func release_hand_count(screen: RecruitScreen) -> void:
	if screen._hand_held < 0 or _hand_flying(screen):
		return
	screen._hand_held = -1
	_show_hand_count(screen)


static func _hand_flying(screen: RecruitScreen) -> bool:
	for target: Dictionary in screen.targets_of("hand"):
		var node: Control = target.get("node")
		if node != null and screen._keeper.is_flying(node):
			return true
	return false


static func _show_hand_count(screen: RecruitScreen) -> void:
	var label: Node = screen._front.get_node_or_null("HandCount")
	if label != null:
		screen._front.remove_child(label)
		label.queue_free()
	build_hand_count(screen)
