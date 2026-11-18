class_name GlassTips
extends RefCounted
## The hover detail (stage.js hoverDetail): the pane beside the pointer with a card's enlarged copy
## and its words, and the hovered ("hot") card brightened above the vignette. One per screen, made
## by GlassScreen._make_tips(); a screen with its own kinds of detail extends it (RecruitTips).
##
## A part of its screen: it draws on the screen's Front layer and reads the screen's targets,
## geometry and card makers.

## Shared across modal screens: a release in the browser also releases the screen beneath it.
static var _alt_held: bool = false

## The detail pane on the Front layer (rebuilt with every drawing), and the hovered card.
var tip: Control
var hot: Control
var details: Array[GlassBox] = []
var content: GameContent
var _icon_mark: KeywordMark
var _goldens: Dictionary = {}
var _previewing: bool = false
var _screen: GlassScreen


## Listen before focused controls consume keys, including the browser's search field.
class PreviewInput:
	extends Node
	var tips: GlassTips

	func _input(event: InputEvent) -> void:
		var key: InputEventKey = event as InputEventKey
		if key == null or key.keycode != KEY_ALT or not tips._screen.is_visible_in_tree():
			return
		get_viewport().set_input_as_handled()
		if key.echo:
			return
		tips._alt_held = key.pressed
		var screen: GlassScreen = tips._screen
		if screen._hover_allowed():
			tips.hover(screen._pointer)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_APPLICATION_FOCUS_OUT and tips != null:
			tips._alt_held = false


func _init(screen: GlassScreen) -> void:
	_screen = screen
	_alt_held = Input.is_key_pressed(KEY_ALT)
	var input: PreviewInput = PreviewInput.new()
	input.name = "GoldenPreviewInput"
	input.tips = self
	screen.add_child(input)


## A new, empty, hidden pane (each drawing of the screen makes one).
func make_tip() -> void:
	_icon_mark = null
	_previewing = false
	details.clear()
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
		return
	var node: Control = over["node"]
	var golden: Dictionary = _golden_for(over) if _alt_held else {}
	var preview: bool = not golden.is_empty()
	if preview != _previewing:
		clear()
		tip.visible = false
		_previewing = preview
	var mark: KeywordMark = null if preview else _border_at(node, here)
	if mark != null:
		if hot != node or _icon_mark != mark:
			show_keyword(over, mark, here)
		return
	if hot != node or _icon_mark != null or not tip.visible:
		if preview:
			var target: Dictionary = over.duplicate()
			target["card"] = golden
			_show_card(target, here)
		else:
			show(over, here)


func _golden_for(target: Dictionary) -> Dictionary:
	var card: Dictionary = target.get("card", {})
	if (
		str(target.get("kind", "")) in ["counter", "ability", "ability_off"]
		or GlassScreen._is_spell(card)
		or CoreUtil.to_bool(card.get("golden", false))
	):
		return {}
	var id: String = str(card.get("id", ""))
	if id.is_empty():
		return {}
	if content == null:
		content = GameContent.load_default()
	if not _goldens.has(id):
		var definition: UnitDef = content.library.get_card(StringName(id))
		_goldens[id] = (
			ViewAdapter.printed_unit(content, id, true)
			if definition != null and not definition.is_spell()
			else {}
		)
	return _goldens[id]


## The drawing wins over neighbouring padding where two enlarged aim areas touch.
func _border_at(node: Control, here: Vector2) -> KeywordMark:
	for padded: bool in [false, true]:
		for child: Node in node.get_children():
			var mark: KeywordMark = child as KeywordMark
			if mark == null or not mark.compact or str(mark.term.get("reminder", "")).is_empty():
				continue
			var rect: Rect2 = mark.hit_rect() if padded else Rect2(Vector2.ZERO, mark.size)
			if rect.has_point(_screen._to_local_of(mark, here)):
				return mark
	return null


## Follow the live card every frame; leaving it or refreshing state closes/rebuilds its panes.
func follow(pointer: Vector2) -> void:
	if tip == null or _screen.pinned_hover != "" or not _screen._hover_allowed():
		return
	if pointer.x < 0.0:
		if tip.visible:
			hide()
		return
	hover(pointer)


## The card's detail beside the pointer: the card at 1.6 x, and a pane with its name, its kind and
## its rules text. It flips to the left near the right edge and stays on the screen.
func show(target: Dictionary, at: Vector2) -> void:
	_show_card(target, at)


func _show_card(target: Dictionary, at: Vector2) -> void:
	var card: Dictionary = target["card"]
	if str(target["kind"]) == "counter":
		show_words(target, at)
		return
	var g: Dictionary = _screen._g
	var big: float = GlassPieces.number("stage.tip.big_per_h") * _screen._h()
	var big_w: float = big * GlassPieces.card_units().x / GlassPieces.card_units().y
	if hot != target["node"] or _icon_mark != null or not tip.visible:
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
		var text: GlassBox = GlassParts.tip_text(
			card, spell, _screen._reminders(card), _screen._display_table()
		)
		text.position = Vector2(shown.size.x + GlassPieces.rule_number("stage", "#tip", "gap"), 0.0)
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
	var pane: GlassBox = last_box()
	tx = clampf(tx, KeywordStyle.GAP, 1920.0 - pane.position.x - pane.box_size.x - KeywordStyle.GAP)
	ty = clampf(
		ty,
		KeywordStyle.GAP,
		1080.0 - maxf(big, pane.position.y + pane.box_size.y) - KeywordStyle.GAP
	)
	tip.position = Vector2(tx, ty)
	tip.visible = true
	var node: Control = target["node"]
	set_hot(node)
	open_details(target)


## STAND-IN (stand-ins.html): a counter's hover is the detail pane alone (its name and reminder),
## beside the pointer and above it, kept on the screen.
func show_words(target: Dictionary, at: Vector2) -> void:
	if hot != target["node"] or _icon_mark != null:
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
	_icon_mark = null
	details.clear()
	for child: Node in tip.get_children():
		tip.remove_child(child)
		child.queue_free()


## The pane's last piece: its words.
func last_box() -> GlassBox:
	return tip.get_node("Words") as GlassBox


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
	_drop_details()
	_icon_mark = null
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


## A border mark replaces the card pane while the pointer is over its enlarged hit area.
func show_keyword(target: Dictionary, mark: KeywordMark, at: Vector2) -> void:
	clear()
	_icon_mark = mark
	var node: Control = target["node"]
	set_hot(node)
	tip.position = at + Vector2(KeywordStyle.GAP, 0)
	tip.visible = true
	_add_keywords([mark.term])
	_layout_details(target)


## Open every term in the card's rules, including granted terms/counters, then one level of
## terms named by their reminders. Roots win over references so their current numbers survive.
func open_details(target: Dictionary) -> void:
	_drop_details()
	var terms: Array[Dictionary] = []
	var pane: Control = tip.get_node_or_null("Words")
	if pane != null:
		for child: Node in pane.find_children("*", "KeywordMark", true, false):
			terms.append((child as KeywordMark).term)
	_add_keywords(terms)
	_layout_details(target)


func _add_keywords(terms: Array[Dictionary]) -> void:
	var seen: Dictionary = {}
	var nested: Array[Dictionary] = []
	for term: Dictionary in terms:
		var body: KeywordText = _add_keyword(term, seen)
		if body != null:
			for mark: KeywordMark in body.marks:
				nested.append(mark.term)
	for term: Dictionary in nested:
		_add_keyword(term, seen)


func _drop_details() -> void:
	for box: GlassBox in details:
		box.get_parent().remove_child(box)
		box.queue_free()
	details.clear()


func _add_keyword(term: Dictionary, seen: Dictionary) -> KeywordText:
	var key: String = CardTerms.key_of(str(term.get("name", term.get("words", ""))))
	if seen.has(key) or str(term.get("reminder", "")).is_empty():
		return null
	seen[key] = true
	var box: GlassBox = GlassBox.new()
	box.name = "KeywordDetail_%d" % details.size()
	box.use_css("stage", "#tip .txt")
	var pad: float = KeywordStyle.PAD
	var header: KeywordMark = KeywordMark.make(term)
	header.position = Vector2.ONE * pad
	box.add_child(header)
	var pane: GlassBox = tip.get_node_or_null("Words")
	var width: float = pane.size.x if pane != null else KeywordStyle.DETAIL_W
	var body: KeywordText = KeywordText.make(
		str(term["reminder"]), _screen._display_table(), width - 2.0 * pad, [], key
	)
	body.position = Vector2(pad, pad + header.size.y + KeywordStyle.GAP)
	box.add_child(body)
	box.box_size = Vector2(width, body.position.y + body.size.y + pad)
	box.radii = Vector4.ONE * KeywordStyle.DETAIL_RADIUS
	box.refresh()
	tip.add_child(box)
	details.append(box)
	return body


func _layout_details(target: Dictionary) -> void:
	var card: Control = tip.get_node_or_null("Card")
	var words: Control = tip.get_node_or_null("Words")
	var card_rect: Rect2 = Rect2(card.position, card.size) if card != null else Rect2()
	var words_rect: Rect2 = Rect2(words.position, words.size) if words != null else Rect2()
	var sizes: Array[Vector2] = []
	for box: GlassBox in details:
		sizes.append(box.size)
	var protected: Array[Rect2] = []
	for node_name: String in [
		"Hero", "HeroHealth", "EndTurn", "EndTurnWords", "Opponent", "OpponentHealth"
	]:
		var control: Control = _screen._front.get_node_or_null(node_name)
		if control != null and control.is_visible_in_tree():
			protected.append(_source_rect(control))
	var node: Control = target["node"]
	var places: Array[Vector2] = KeywordLayout.arrange(
		card_rect, words_rect, tip.position, _source_rect(node), sizes, protected
	)
	assert(not places.is_empty(), "Grouped keyword panes must fit clear of the card and controls")
	if places.is_empty():
		return
	tip.position = places[0]
	for i: int in details.size():
		details[i].position = places[i + 1] - tip.position


func _source_rect(node: Control) -> Rect2:
	var transform: Transform2D = (
		_screen._stage.get_global_transform().affine_inverse() * node.get_global_transform()
	)
	var rect: Rect2 = Rect2(transform * Vector2.ZERO, Vector2.ZERO)
	for corner: Vector2 in [Vector2(node.size.x, 0), node.size, Vector2(0, node.size.y)]:
		rect = rect.expand(transform * corner)
	return rect
