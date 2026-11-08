extends GutTest
## Every card has its own portrait, or an explicitly tracked pending portrait with a tribe fallback.
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


func _assert_own_art(owner_node: Node, def_id: String, where: String) -> void:
	var frame: ArtFrame = owner_node.get("_art")
	var expected: String = UiTheme.UNIT_PORTRAIT_DIR % def_id
	if _pending.has(def_id) and not ResourceLoader.exists(expected):
		var tribes: Array = _library.get_unit(def_id).get("tribes", [])
		expected = UiTheme.portrait(tribes).resource_path
	assert_eq(frame.texture.resource_path, expected, "%s on the %s" % [def_id, where])


func _assert_on_tile_and_detail(view: Dictionary) -> void:
	var def_id: String = str(view["def_id"])
	var card: CardView = CardView.new()
	_holder.add_child(card)
	card.show_unit(view, CardView.Mode.SHOP)
	_assert_own_art(card, def_id, "tile")
	card.free()
	var detail: CardDetail = CardDetail.new()
	_holder.add_child(detail)
	detail.show_unit(view)
	_assert_own_art(detail, def_id, "detail")
	detail.free()


func test_the_slice_is_all_there() -> void:
	assert_eq(_library.pool_units(_card_set).size(), 98, "shop units")
	assert_eq(_library.pool_spells(_card_set).size(), 18, "shop spells")
	assert_eq(_library.heroes_of(_card_set).size(), 9, "heroes")


func test_every_unit_and_token_has_its_own_portrait() -> void:
	var seen: int = 0
	for def: Dictionary in _library.all_units():
		if str(def.get("set", "")) == _card_set:
			_assert_on_tile_and_detail(UnitViews.from_def(def))
			seen += 1
	assert_eq(seen, 108, "98 shop units, 9 created cards and retired Barn Owl")


func test_every_spell_and_hand_item_has_its_own_portrait() -> void:
	var seen: int = 0
	for card: Dictionary in _library.all_cards():
		var in_game: bool = str(card.get("set", "")) == _card_set
		if in_game or str(card["id"]) in RULES_ITEMS:
			_assert_on_tile_and_detail(HandItem.make(card, 1).view())
			seen += 1
	assert_eq(seen, 23, "19 spells, 3 Acorn items and the triple reward")


func test_every_hero_has_its_own_portrait() -> void:
	for hero: Dictionary in _library.heroes_of(_card_set):
		var plaque: HeroPlaque = HeroPlaque.new()
		_holder.add_child(plaque)
		plaque.show_hero({"id": hero["id"], "name": hero["name"], "kind": "passive"})
		_assert_own_art(plaque, str(hero["id"]), "plaque")
		plaque.free()
		_assert_on_tile_and_detail(RecruitView.hero_card(hero))


func test_pending_portraits_name_only_real_cards() -> void:
	var seen: Dictionary = {}
	for value: Variant in _pending:
		var id: String = str(value)
		assert_false(seen.has(id), "pending art listed once")
		seen[id] = true
		assert_false(_library.get_unit(id).is_empty(), id)
	assert_eq(seen.size(), _pending.size(), "each pending portrait names one unique real card")
