class_name RecruitButtons
extends RefCounted
## The recruit screen's shop and board ability buttons. Each is a pointer target;
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
	RecruitShop.build_buttons(_screen)


## A board unit's ability buttons, on its card (extra's `abilities`), stacked up from
## ABILITY_DOWN. An Active's holds its gold cost as a coin: red when the gold is short (the button
## dimmed behind it, like the shop's), the whole button dimmed once used this turn or when it
## can't be used here.
static func add_ability_buttons(node: Control, abilities: Array, box: Vector2) -> void:
	for k: int in abilities.size():
		var ability: Dictionary = abilities[k]
		var used: bool = GlassPieces.as_bool(ability.get("used", false))
		var poor: bool = not used and GlassPieces.as_bool(ability.get("poor", false))
		var button: GlassBox = GlassParts.ability_button(
			str(ability["name"]), GlassPieces.as_int(ability.get("cost", 0)), poor
		)
		button.name = "Ability_" + str(ability["id"])
		if poor:
			# STAND-IN (stand-ins.html): the shop's short button, its coin left to say why
			button.self_modulate = RecruitScreen.SHORT_DIM
		elif not GlassPieces.as_bool(ability["usable"]):
			# STAND-IN (stand-ins.html): dimmed like a button whose action is not legal
			button.modulate = RecruitScreen.SHORT_DIM
		button.position = Vector2(
			(box.x - button.box_size.x) / 2.0, box.y * ABILITY_DOWN - k * (button.box_size.y + 4.0)
		)
		node.add_child(button)


## An ability button's hover: its name (an Active's unit's, as it has none), where it stands this
## turn, and what it does: an Active's own line of the card's text (its cost coin first), else
## its reminder.
static func ability_words(card: Dictionary, ability: Dictionary) -> Dictionary:
	# Only when it can't be used, and then the core's reason ("Not enough gold"); none when ready.
	var state: String = str(ability.get("why", ""))
	if state == "" and GlassPieces.as_bool(ability.get("poor", false)):
		state = "not enough gold"
	if state != "":
		state = state.left(1).to_upper() + state.substr(1)
	var text: String = str(ability.get("reminder", ""))
	var name: String = str(ability.get("name", ""))
	if name == "":
		name = str(card.get("name", ""))
		var line: RegExMatch = RegEx.create_from_string(KeywordText.COST_LEAD + ".*$").search(
			KeywordText.effect_lines(str(card.get("text", "")))
		)
		if line != null:
			text = line.get_string()
	return {
		"id": "ability:" + str(ability["id"]),
		"name": name,
		"text": text,
		"kind_line": state,
	}


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
			var words: Dictionary = ability_words(card, ability)
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
