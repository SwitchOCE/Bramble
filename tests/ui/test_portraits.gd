extends GutTest
## Every shipped unit has its own portrait, with no pending tribe fallbacks.
## Reached the way the screens reach it:
## the shop and board tile, the card detail, the hero plaque and the hero picker.

const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const HeroPlaque := preload("res://src/ui/widgets/hero_plaque.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")

## A hand item the rules give out with no card set: the reward for a triple.
const RULES_ITEMS: PackedStringArray = ["triple_reward"]

var _holder: Control
var _library: UnitLibrary
var _pending: Array = []
var _card_set: String


func before_each() -> void:
	_holder = Control.new()
	_holder.theme = UiTheme.get_theme()
	add_child_autofree(_holder)
	_library = UnitLibrary.load_dir()
	_card_set = GameConfig.full_game().card_set()
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/portraits_pending.json")
	)
	_pending = manifest["units"]


func _assert_own_art(
	owner_node: Node, def_id: String, where: String, portrait_id: String = ""
) -> void:
	var frame: ArtFrame = owner_node.get("_art")
	var expected: String = UiTheme.UNIT_PORTRAIT_DIR % def_id
	# Wave 1 explicitly reuses the existing Egg portrait for its created Golden Egg spell.
	if def_id == "golden_egg":
		expected = UiTheme.UNIT_PORTRAIT_DIR % "nest_egg"
	# A Pelt has no independent portrait: the created item wears its recorded prey's art.
	if def_id == "pelt":
		expected = (
			UiTheme.portrait([]).resource_path
			if portrait_id.is_empty()
			else UiTheme.UNIT_PORTRAIT_DIR % portrait_id
		)
	assert_eq(frame.texture.resource_path, expected, "%s on the %s" % [def_id, where])


func _assert_on_tile_and_detail(view: Dictionary) -> void:
	var def_id: String = str(view["def_id"])
	var card: CardView = CardView.new()
	_holder.add_child(card)
	card.show_unit(view, CardView.Mode.SHOP)
	_assert_own_art(card, def_id, "tile", str(view.get("portrait_id", "")))
	card.free()
	var detail: CardDetail = CardDetail.new()
	_holder.add_child(detail)
	detail.show_unit(view)
	_assert_own_art(detail, def_id, "detail", str(view.get("portrait_id", "")))
	detail.free()


func test_the_slice_is_all_there() -> void:
	assert_eq(_library.pool_units(_card_set).size(), 109, "shop units")
	assert_eq(_library.pool_spells(_card_set).size(), 18, "shop spells")
	assert_eq(_library.heroes_of(_card_set).size(), 9, "heroes")


func test_every_unit_and_token_has_its_own_portrait() -> void:
	var seen: int = 0
	for def: Dictionary in _library.all_units():
		if str(def.get("set", "")) == _card_set:
			_assert_on_tile_and_detail(UnitViews.from_def(def))
			seen += 1
	assert_eq(seen, 119, "109 shop units, 9 created cards and retired Barn Owl")


func test_every_spell_and_hand_item_has_its_own_portrait() -> void:
	var seen: int = 0
	for card: Dictionary in _library.all_cards():
		var in_game: bool = str(card.get("set", "")) == _card_set
		if in_game or str(card["id"]) in RULES_ITEMS:
			_assert_on_tile_and_detail(HandItem.make(card, 1).view())
			seen += 1
	assert_eq(seen, 25, "19 spells, 3 Acorn items, the triple reward, Golden Egg and Pelt")


func test_a_created_pelt_shows_its_recorded_prey_on_tile_and_reader() -> void:
	var definition: Dictionary = _library.get_card("pelt").duplicate(true)
	definition["portrait_id"] = "mrs_jay"
	_assert_on_tile_and_detail(HandItem.make(definition, 1).view())


func test_every_hero_has_its_own_portrait() -> void:
	for hero: Dictionary in _library.heroes_of(_card_set):
		var plaque: HeroPlaque = HeroPlaque.new()
		_holder.add_child(plaque)
		plaque.show_hero({"id": hero["id"], "name": hero["name"], "kind": "passive"})
		_assert_own_art(plaque, str(hero["id"]), "plaque")
		plaque.free()
		_assert_on_tile_and_detail(RecruitView.hero_card(hero))


func test_no_shipped_unit_portraits_are_pending() -> void:
	assert_eq(_pending, [], "every shipped unit has its own portrait")


func test_wave2b_slice_token_has_its_own_portrait() -> void:
	# Wave 2b's created neutral unit is not in this branch's content library yet.
	_assert_on_tile_and_detail(
		UnitViews.from_def({"id": "slice", "name": "Slice", "attack": 1, "health": 1, "tribes": []})
	)
