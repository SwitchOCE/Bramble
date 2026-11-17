class_name GlassTips
extends RefCounted
## The hover detail (stage.js hoverDetail): the pane beside the pointer with a card's enlarged copy
## and its words, and the hovered ("hot") card brightened above the vignette. One per screen, made
## by GlassScreen._make_tips(); a screen with its own kinds of detail extends it (RecruitTips).
##
## A part of its screen: it draws on the screen's Front layer and reads the screen's targets,
## geometry and card makers.

## The detail pane on the Front layer (rebuilt with every drawing), and the hovered card.
var tip: Control
var hot: Control

var _screen: GlassScreen


func _init(screen: GlassScreen) -> void:
	_screen = screen


## A new, empty, hidden pane (each drawing of the screen makes one).
func make_tip() -> void:
	tip = Control.new()
	tip.name = "Tip"
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.z_index = GlassPieces.as_int(GlassPieces.rule("stage", "#tip", "z-index"))
	tip.visible = false
	_screen._front.add_child(tip)


## The detail for a card id without a pointer (the mock-up's "Hover" switch).
func pin(card_id: String) -> void:
	for target: Dictionary in _screen._targets:
		var card: Dictionary = target.get("card", {})
		if str(card.get("id", "")) == card_id:
			var node: Control = target["node"]
			if str(target["kind"]) == "counter":
				# polish.html's heap hover: its words 220 px right of the plate's left edge, their
				# foot 40 px below the plate's top
				var x: float = (
					node.position.x
					+ GlassCounters.PLATE_TIP_X
					- GlassPieces.number("stage.tip.gap")
				)
				show(target, Vector2(x, node.position.y + GlassCounters.PLATE_TIP_DOWN))
				return
			var at: Vector2 = (
				(
					_screen._stage.get_global_transform().affine_inverse()
					* node.get_global_transform().origin
				)
				+ Vector2(
					_screen._w() * GlassPieces.number("stage.tip.pin_x_per_w"),
					_screen._h() * GlassPieces.number("stage.tip.pin_y_per_h")
				)
			)
			if node != null:
				show(target, at)
			return


## The hover detail for whatever card is under a stage point, or none.
func hover(here: Vector2) -> void:
	var over: Dictionary = _screen._target_at(here, true)
	if over.is_empty():
		if _screen.pinned_hover == "":
			hide()
	else:
		show(over, here)


## The hover follows what is under the pointer every frame, not only when the pointer moves: a
## card that slides away, or a new state, takes its detail with it.
func follow(pointer: Vector2) -> void:
	if tip == null or _screen.pinned_hover != "" or not _screen._hover_allowed():
		return
	if pointer.x < 0.0:
		if tip.visible:
			hide()
		return
	var over: Dictionary = _screen._target_at(pointer, true)
	if over.is_empty():
		if tip.visible:
			hide()
	elif not tip.visible or hot != over.get("node"):
		show(over, pointer)


## The card's detail beside the pointer: the card at 1.6 x, and a pane with its name, its kind and
## its rules text. It flips to the left near the right edge and stays on the screen.
func show(target: Dictionary, at: Vector2) -> void:
	var card: Dictionary = target["card"]
	if str(target["kind"]) == "counter":
		show_words(target, at)
		return
	var g: Dictionary = _screen._g
	var big: float = GlassPieces.number("stage.tip.big_per_h") * _screen._h()
	var big_w: float = big * GlassPieces.card_units().x / GlassPieces.card_units().y
	if hot != target["node"]:
		clear()
		var shown: Control
		var spell: bool = str(target["kind"]) == "spell" or GlassScreen._is_spell(card)
		if spell:
			var spell_h: float = big * GlassScreen._f(g["SH"]) / _screen._h()
			shown = _screen._spell_card(
				card, Vector2(spell_h * GlassScreen._f(g["SW"]) / GlassScreen._f(g["SH"]), spell_h)
			)
		else:
			shown = _screen._unit_card(card, big)
		shown.name = "Card"
		tip.add_child(shown)
		var text: GlassBox = GlassParts.tip_text(card, spell, _screen._reminders(card))
		text.position = Vector2(
			shown.size.x + GlassPieces.rule_number("stage", "#tip", "gap"),
			GlassPieces.rule_number("stage", "#tip .txt", "margin-top")
		)
		tip.add_child(text)
	var gap: float = GlassPieces.number("stage.tip.gap")
	var tx: float = at.x + gap
	var ty: float = at.y - big / 2.0
	if (
		tx + big_w + GlassPieces.number("stage.tip.flip_room")
		> GlassPieces.number("stage.tip.flip_edge")
	):
		tx = at.x - gap - big_w - GlassPieces.number("stage.tip.flip_back")
	ty = maxf(
		GlassPieces.number("stage.tip.top_min"),
		minf(GlassPieces.number("stage.tip.bottom_max") - big, ty)
	)
	tip.position = Vector2(tx, ty)
	tip.visible = true
	var node: Control = target["node"]
	set_hot(node)


## STAND-IN (stand-ins.html): a counter's hover is the detail pane alone (its name and reminder),
## beside the pointer and above it, kept on the screen.
func show_words(target: Dictionary, at: Vector2) -> void:
	if hot != target["node"]:
		clear()
		var words: Dictionary = target["card"]
		var lines: PackedStringArray = words.get("lines", PackedStringArray())
		tip.add_child(GlassParts.tip_text(words, false, lines))
	var text: GlassBox = last_box()
	var gap: float = GlassPieces.number("stage.tip.gap")
	var ty: float = minf(at.y, GlassPieces.number("stage.tip.bottom_max")) - text.box_size.y
	tip.position = Vector2(at.x + gap, maxf(GlassPieces.number("stage.tip.top_min"), ty))
	tip.visible = true
	var node: Control = target["node"]
	set_hot(node)


## Empties the pane, for new words.
func clear() -> void:
	for child: Node in tip.get_children():
		tip.remove_child(child)
		child.queue_free()


## The pane's last piece: its words.
func last_box() -> GlassBox:
	return tip.get_child(tip.get_child_count() - 1)


## The hover detail fades out over GlassScreen.TIP_FADE_TIME rather than going at once (a card
## pressed and dragged): the shown one is let go to fade and free itself, and a new empty one
## takes its place.
func fade() -> void:
	if tip == null or not tip.visible or not tip.is_inside_tree():
		hide()
		return
	var fading: Control = tip
	fading.name = "TipFading"
	make_tip()
	set_hot(null)
	var tween: Tween = fading.create_tween()
	tween.tween_property(fading, "modulate:a", 0.0, GlassScreen.TIP_FADE_TIME)
	tween.tween_callback(fading.queue_free)


func hide() -> void:
	if tip != null:
		tip.visible = false
	set_hot(null)


## .card.hot: the hovered card brightened, glowing, above the vignette.
func set_hot(node: Control) -> void:
	if hot == node:
		return
	if is_instance_valid(hot):
		if hot is GlassCard:
			(hot as GlassCard).set_hot(false)
		hot.z_index = 0
	hot = node
	if hot is GlassCard:
		(hot as GlassCard).set_hot(true)
	if hot != null and (hot is GlassCard or hot is GlassSpell):
		hot.z_index = GlassPieces.as_int(GlassPieces.rule("stage", ".card.hot", "z-index"))
