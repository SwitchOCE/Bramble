class_name RecruitButtons
extends RefCounted
## The recruit screen's buttons: the shop's four (gold, upgrade, refresh, freeze), the end-turn
## portrait in the right light, and the ability buttons on board units. Each is a pointer target;
## a button whose action the state's legal_actions lacks is drawn dimmed (RecruitScreen.SHORT_DIM).
##
## A part of its screen: it draws on the screen's layers and adds the buttons to its targets.

var _screen: RecruitScreen


func _init(screen: RecruitScreen) -> void:
	_screen = screen


## The shop's buttons, either side of it: gold and upgrade on the left, refresh and freeze on the
## right.
func build_shop_buttons() -> void:
	RecruitShop.build_buttons(_screen)


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


## Keep the action words and costs visible, with the unit's slot identifying its button in the
## clear strip under the whole board. Under a front-row card would cover the back row's art.
static func add_ability_buttons(node: Control, abilities: Array, slot: int) -> void:
	for value: Variant in abilities:
		var ability: Dictionary = value
		var words: String = str(ability["name"])
		if not words.contains("("):
			var cost: int = GlassPieces.as_int(ability.get("cost", 0))
			words += " (%d)" % cost if cost > 0 else " (free)"
		var label: String = "F%d" % (slot + 1) if slot < 4 else "B%d" % (slot - 3)
		var button: GlassBox = GlassParts.ability_button(label + " · " + words)
		button.name = "Ability_" + str(ability["id"])
		button.z_index = 2
		if not GlassPieces.as_bool(ability["usable"]):
			button.modulate = RecruitScreen.SHORT_DIM
		node.add_child(button)


## Pin the action words to their strip; hide them during a carry or a card's travel so labels
## never pass across another card's art. The existing click and drag targets stay on the unit.
func place_abilities() -> void:
	for target: Dictionary in _screen.targets_of("board"):
		var node: Control = target["node"]
		var card: GlassCard = node as GlassCard
		if card == null:
			continue
		for child: Node in card.get_children():
			if not str(child.name).begins_with("Ability_"):
				continue
			var button: Control = child as Control
			button.visible = not card.is_held() and not _screen._keeper.is_busy(card)
			var at: Vector2 = button.get_meta("ability_at", Vector2.ZERO)
			button.position = _screen._to_local_of(card, at)


## Each ability button on the board is a pointer target over its card: a usable one is pressed,
## a dimmed one only shows what it does. Its hover is its own (what it does and its cost), beside
## the card, so the card's enlarged copy never covers the button being reached for.
func add_ability_targets() -> void:
	var buttons: Array[GlassBox] = []
	var width: float = -KeywordStyle.ACTION_GAP
	for target: Dictionary in _screen.targets_of("board"):
		var extra: Dictionary = target["extra"]
		var card: Dictionary = target["card"]
		var node: Control = target["node"]
		for value: Variant in extra.get("abilities", []):
			var ability: Dictionary = value
			var button: GlassBox = node.get_node("Ability_" + str(ability["id"]))
			buttons.append(button)
			width += button.box_size.x + KeywordStyle.ACTION_GAP
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

	var x: float = (1920.0 - width) / 2.0
	var y: float = GlassPieces.as_float(_screen._g["boardBot"]) + KeywordStyle.ACTION_FOOT_GAP
	for button: GlassBox in buttons:
		button.set_meta("ability_at", Vector2(x, y))
		x += button.box_size.x + KeywordStyle.ACTION_GAP
	place_abilities()
