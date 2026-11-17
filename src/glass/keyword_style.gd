class_name KeywordStyle
extends RefCounted
## Brief 2: the approved six families and unique drawings, shared with the review sheet.
## Keep keyword geometry and typography here so the owner's taste calls are easy to replace.
const CARD_DIAMETER: float = 0.09
## At 1366x768 this is 15 px, including the browser's 186 px cards.
const CARD_MIN_SIDE: float = 21.1
const CARD_ROOM: float = 0.5
const CARD_Y: float = 0.925
const CARD_GAP: float = 3.0
const PANE_W: float = 340.0
const PAD: float = 23.0
const TITLE_PX: float = 27.0
const PANE_PAD_X: float = 18.0
const PANE_PAD_Y: float = 16.0
const BODY_PX: float = 21.0
const MARK_PX: float = 18.0
const TOOLTIP_MARK_H: float = 28.0
const LINE_H: float = 37.0
const DETAIL_W: float = 330.0
const GAP: float = 12.0
const DETAIL_RADIUS: float = 14.0
const MARK_BORDER: int = 2
const ICON_DISC: float = 0.36
const ICON_SIDE: float = 0.66
const NUMBER_MIN_PX: int = 24
const NUMBER_PER_SIDE: float = 0.6
const NUMBER_WEIGHT: int = 900
const NUMBER_X: float = 0.65
const NUMBER_OUTLINE: int = 5
const WORD_OUTLINE: int = 4
const WORD_PAD: float = 16.0
const WORD_GAP: float = 5.0
const HINT_PX: float = 15.0
const SPENT_ALPHA: float = 0.4
const INK: Color = Color("16120e")
const WORD: Color = Color("fbf3df")
const NUMBER: Color = Color("fff2b8")
const FROZEN: Color = Color("ffb24a")
const HINT: String = "Hold Alt for keyword details"
const HELD_HINT: String = "Alt held · Point at a keyword"

static var _data: Dictionary = {}
static var _textures: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/glass/keywords.json"))
	return _data


static func entry(title: String) -> Dictionary:
	var key: String = CardTerms.key_of(title)
	for word: String in data()["keywords"]:
		if word.to_lower() == key:
			return data()["keywords"][word]
	return {"family": "count", "icon": "uses"}


static func family(title: String) -> Dictionary:
	return data()["families"][entry(title)["family"]]


static func icon(title: String) -> Texture2D:
	var spec: Dictionary = entry(title)
	var key: String = str(spec["icon"]) + str(spec["family"])
	if not _textures.has(key):
		var svg: String = (
			'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24"'
			+ ' fill="none" stroke="#%s" stroke-width="2.3"' % family(title)["light"]
			+ (
				' stroke-linecap="round" stroke-linejoin="round">%s</svg>'
				% data()["icons"][spec["icon"]]
			)
		)
		var image: Image = Image.new()
		image.load_svg_from_string(svg)
		image.generate_mipmaps()
		_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]
