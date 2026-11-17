class_name RecruitButtons
extends RefCounted
## The recruit screen's buttons: the shop's four (gold, upgrade, refresh, freeze), the end-turn
## portrait in the right light, and the ability buttons on board units. Each is a pointer target;
## a button whose action the state's legal_actions lacks is drawn dimmed (RecruitScreen.SHORT_DIM).
##
## A part of its screen: it draws on the screen's layers and adds the buttons to its targets.

## STAND-IN: where an ability button sits on its card, as a share of the card's height.
const ABILITY_DOWN: float = 0.62

var _screen: RecruitScreen


func _init(screen: RecruitScreen) -> void:
	_screen = screen


## The shop's buttons, either side of it: gold and upgrade on the left, refresh and freeze on the
## right.
func build_shop_buttons() -> void:
	var g: Dictionary = _screen._g
	var bw: float = GlassPieces.number("stage.recruit.button.w")
	var gap: float = GlassPieces.number("stage.recruit.button.gap")
	var shop_l: float = GlassScreen._f(g["shopL"])
	var x_left: float = shop_l - gap - bw
	var x_right: float = shop_l + GlassScreen._f(g["shopW"]) + gap
	var y1: float = (
		GlassScreen._f(g["shopTop"])
		+ _screen.card_box().y / 2.0
		- GlassPieces.number("stage.recruit.button.up")
	)
	var y2: float = y1 + GlassPieces.number("stage.recruit.button.step")
	var state: Dictionary = _screen.state
	var tier: int = GlassPieces.as_int(state.get("tier", 1))
	_add_button("gold", Vector2(x_left, y1), "gold", str(_screen._counts.gold()), "")
	# no upgrade cost in the state: the top tier, no button
	if state.get("upgrade_cost") != null:
		var upgrade: int = GlassPieces.as_int(state["upgrade_cost"])
		var tier_words: String = "%d→%d" % [tier, tier + 1]
		_add_button(
			"tier", Vector2(x_left, y2), "", tier_words, str(upgrade), _screen.is_barred("upgrade")
		)
	var refresh: int = GlassPieces.as_int(state.get("refresh_cost", 0))
	_add_button("refresh", Vector2(x_right, y1), "", "", str(refresh), _screen.is_barred("refresh"))
	_add_button("freeze", Vector2(x_right, y2), "freeze", "", "", _screen.is_barred("freeze"))


## A .btn: its pane, then the icon, the words and the pip in a centred row (flex, gap 8).
func _add_button(
	icon: String, at: Vector2, variant: String, words: String, pip: String, short: bool = false
) -> void:
	var box: GlassBox = GlassBox.new()
	box.name = "Button_" + icon
	box.box_size = Vector2(
		GlassPieces.number("stage.recruit.button.w"),
		GlassPieces.rule_number("stage", ".btn", "height")
	)
	box.use_css("stage", ".btn")
	if variant == "gold":
		box.use_css("stage", ".btn.gold")
	box.radii = GlassBox.css_radii(GlassPieces.rule("stage", ".btn", "border-radius"), box.box_size)
	box.position = at
	box.refresh()
	_screen._back.add_child(box)
	if variant == "freeze" and GlassPieces.as_bool(_screen.state.get("frozen", false)):
		GlassParts.add_frost(box, GlassParts.round_poly(box.box_size))
	if short:
		# STAND-IN can't-afford look: the button dimmed (no mock-up)
		box.name += "_short"
		box.modulate = RecruitScreen.SHORT_DIM
	var font: Dictionary = GlassPieces.rule_font("stage", ".btn")
	var items: Array[Control] = []
	var stroke_rule: String = ".btn.%s svg" % variant if variant != "" else ".btn svg"
	var icon_colour: Color = GlassPieces.rule_colour("stage", stroke_rule, "stroke")
	var icon_px: int = GlassPieces.as_int(GlassPieces.rule_number("stage", ".btn svg", "width"))
	var icon_node: TextureRect = TextureRect.new()
	icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_node.texture = GlassPieces.icon(
		icon, icon_colour, icon_px, GlassPieces.rule_number("stage", ".btn svg", "stroke-width")
	)
	icon_node.size = Vector2(icon_px, icon_px)
	items.append(icon_node)
	if words != "":
		var label: GlassText
		if variant == "gold":
			label = GlassText.from_rule("stage", ".btn.gold b", words)
			label.use_font(font)
			label.weight = GlassPieces.as_int(
				GlassPieces.rule("stage", ".btn.gold b", "font-weight")
			)
		else:
			label = GlassText.new()
			label.words = words
			label.use_font(font)
			label.colour = GlassPieces.rule_colour("stage", ".btn", "color")
		items.append(label.refresh())
	if pip != "":
		items.append(GlassParts.make_pip(pip, GlassScreen._f(font["size"])))
	var content: Vector2 = box.padding_rect().size
	var gap: float = GlassPieces.rule_number("stage", ".btn", "gap")
	var total: float = -gap
	for item: Control in items:
		total += item.size.x + gap
	var x: float = box.border_width + (content.x - total) / 2.0
	for item: Control in items:
		item.position = Vector2(x, box.border_width + (content.y - item.size.y) / 2.0).round()
		box.add_child(item)
		x += item.size.x + gap
	_screen._targets.append(
		{
			"kind": "button",
			"index": 0,
			"id": icon,
			"node": box,
			"poly": GlassParts.rect_poly(box.box_size)
		}
	)


## The right light's sill: the next opponent's portrait, which ends the turn, under its words.
func build_end_turn() -> void:
	var height: float = _screen._stage.size.y
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
	_screen._front.add_child(words)
	var next: Dictionary = _screen.state.get("next_opponent", {})
	var side: float = GlassPieces.number("stage.recruit.end.port")
	var port: GlassBox = GlassParts.make_portrait(str(next.get("portrait", "")), side, [".endturn"])
	port.name = "EndTurn"
	port.position = Vector2(x, height - GlassPieces.number("stage.recruit.end.port_up"))
	_screen._front.add_child(port)
	var hp: GlassBox = GlassParts.health_badge(GlassPieces.as_int(next.get("health", 0)), [".hp"])
	hp.position = Vector2(
		x - GlassPieces.number("stage.recruit.end.hp_left"),
		height - GlassPieces.number("stage.recruit.end.hp_up")
	)
	_screen._front.add_child(hp)
	_screen._targets.append(
		{
			"kind": "button",
			"index": 0,
			"id": "end_turn",
			"node": port,
			"poly": GlassScreen._circle(port.box_size)
		}
	)


## A board unit's ability buttons, on its card (extra's `abilities`), stacked up from
## ABILITY_DOWN; one that can't be used now is dimmed.
static func add_ability_buttons(node: Control, abilities: Array, box: Vector2) -> void:
	for k: int in abilities.size():
		var ability: Dictionary = abilities[k]
		var button: GlassBox = GlassParts.ability_button(str(ability["name"]))
		button.name = "Ability_" + str(ability["id"])
		if not GlassPieces.as_bool(ability["usable"]):
			# STAND-IN (stand-ins.html): dimmed like a button whose action is not legal
			button.modulate = RecruitScreen.SHORT_DIM
		button.position = Vector2(
			(box.x - button.box_size.x) / 2.0, box.y * ABILITY_DOWN - k * (button.box_size.y + 4.0)
		)
		node.add_child(button)


## Each ability button on the board is a pointer target over its card: a usable one is pressed,
## a dimmed one only shows what it does. Its hover is its own (what it does and its cost), beside
## the card, so the card's enlarged copy never covers the button being reached for.
func add_ability_targets() -> void:
	for target: Dictionary in _screen.targets_of("board"):
		var extra: Dictionary = target["extra"]
		var card: Dictionary = target["card"]
		var node: Control = target["node"]
		for value: Variant in extra.get("abilities", []):
			var ability: Dictionary = value
			var button: GlassBox = node.get_node("Ability_" + str(ability["id"]))
			var cost: int = GlassPieces.as_int(ability.get("cost", 0))
			var words: Dictionary = {
				"id": "ability:" + str(ability["id"]),
				"name": str(ability["name"]),
				"text": str(ability.get("reminder", "")),
				"kind_line": "Ability · costs %d" % cost if cost > 0 else "Ability · free",
			}
			(
				_screen
				. _targets
				. append(
					{
						"kind":
						"ability" if GlassPieces.as_bool(ability["usable"]) else "ability_off",
						"card": words,
						"index": target["index"],
						"id": str(ability["id"]),
						"uid": GlassPieces.as_int(card.get("uid", -1)),
						"target": str(ability["target_kind"]),
						"node": button,
						"poly": GlassParts.rect_poly(button.box_size),
					}
				)
			)
