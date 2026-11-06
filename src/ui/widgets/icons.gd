extends RefCounted
## The look's flat icons, beads and wood grain as SVG, word for word from the design lab's mock
## (docs/design-lab/r3/woodcraft/wc.js and wc.css), rasterised once per size at run time. No image
## files, so the build stays light.

const INK: String = "#2B1A0F"

const ACORN: String = (
	'<path d="M20 4v6" stroke="#2B1A0F" stroke-width="3.5" stroke-linecap="round"/>'
	+ '<path d="M11 21h18c0 9-4 13-9 16-5-3-9-7-9-16z" fill="#D9A441" stroke="#2B1A0F"'
	+ ' stroke-width="3" stroke-linejoin="round"/>'
	+ '<path d="M21 22c0 6-1 9-3 12" stroke="#A8761E" stroke-width="3" fill="none"'
	+ ' stroke-linecap="round"/>'
	+ '<path d="M7 21c0-10 26-10 26 0z" fill="#7A4A22" stroke="#2B1A0F" stroke-width="3"'
	+ ' stroke-linejoin="round"/>'
	+ '<path d="M12 17h4M19 15h3M25 17h3" stroke="#2B1A0F" stroke-width="2"'
	+ ' stroke-linecap="round"/>'
)
const TIER: String = (
	'<path d="M4 34h32v-8H4z M10 26h20v-8H10z M16 18h8v-8h-8z" fill="#C08A52" stroke="#2B1A0F"'
	+ ' stroke-width="3" stroke-linejoin="round"/>'
)
const REFRESH: String = (
	'<g fill="none" stroke="#2B1A0F" stroke-width="4" stroke-linecap="round"'
	+ ' stroke-linejoin="round"><path d="M32 17A13 13 0 0 0 9 12"/><path d="M8 5v8h8"/>'
	+ '<path d="M8 23a13 13 0 0 0 23 5"/><path d="M32 35v-8h-8"/></g>'
)
const FREEZE: String = (
	'<g stroke="#2B1A0F" stroke-width="3.5" stroke-linecap="round">'
	+ '<path d="M20 3v34M5 11.5l30 17M5 28.5l30-17"/>'
	+ '<path d="M15 6l5 4 5-4M15 34l5-4 5 4M6 17l6-1-2-6M34 23l-6 1 2 6M6 23l6 1-2 6M34 17l-6-1'
	+ ' 2-6" fill="none"/></g>'
)
const SWORD: String = (
	'<path d="M8 32L30 10M27 7l6 6M10 24l6 6M6 34l4-4" stroke="#2B1A0F" stroke-width="4"'
	+ ' stroke-linecap="round"/>'
)
const BERRY: String = (
	'<path d="M20 4c-2 6 2 8 0 12M20 9c4-4 9-3 11-1-3 3-7 3-11 1z" stroke="#2B1A0F"'
	+ ' stroke-width="2.5" fill="#41662C" stroke-linejoin="round"/>'
	+ '<circle cx="20" cy="26" r="11" fill="#5E3A86" stroke="#2B1A0F" stroke-width="3"/>'
	+ '<path d="M14 24a6 6 0 0 1 4-5" stroke="#F7ECD4" stroke-width="2.5" fill="none"'
	+ ' stroke-linecap="round"/>'
)
const BERRY_BIG: String = (
	'<path d="M20 2c-2 6 2 8 0 12M20 7c4-4 9-3 11-1-3 3-7 3-11 1z" stroke="#2B1A0F"'
	+ ' stroke-width="2.5" fill="#41662C" stroke-linejoin="round"/>'
	+ '<circle cx="20" cy="25" r="13.5" fill="#5E3A86" stroke="#2B1A0F" stroke-width="3"/>'
)
const ATK: String = (
	'<path d="M20 2.5l15.5 8.8v17.4L20 37.5 4.5 28.7V11.3z" fill="#F2A43A" stroke="#2B1A0F"'
	+ ' stroke-width="3" stroke-linejoin="round"/>'
	+ '<path d="M20 6.5l12 6.8v13.4L20 33.5 8 26.7V13.3z" fill="none" stroke="#B86E14"'
	+ ' stroke-width="1.6" stroke-linejoin="round"/>'
)
const HP_CROWN: String = (
	'<path d="M20 10.5l-2.6-5.2 2.6 1.6 2.6-1.6zM20 10.5l-6.2-2.4 3 .2.4-2.7zM20 10.5l6.2-2.4-3'
	+ ' .2-.4-2.7z" fill="#41662C" stroke="#2B1A0F" stroke-width="2" stroke-linejoin="round"/>'
)
const HP: String = (
	'<circle cx="20" cy="23" r="15" fill="#A52A21" stroke="#2B1A0F" stroke-width="3"/>' + HP_CROWN
)
const HP_HURT: String = (
	'<circle cx="20" cy="23" r="15" fill="#7A1C16" stroke="#2B1A0F" stroke-width="3"/>' + HP_CROWN
)
const HP_OUT: String = (
	'<circle cx="20" cy="23" r="15" fill="#8C7A62" stroke="#2B1A0F" stroke-width="3"/>' + HP_CROWN
)
const GEAR: String = (
	'<g fill="none" stroke="#2B1A0F" stroke-width="4" stroke-linecap="round">'
	+ '<circle cx="20" cy="20" r="7"/>'
	+ '<path d="M20 4v6M20 30v6M4 20h6M30 20h6M8.7 8.7l4.2 4.2M27.1 27.1l4.2 4.2M8.7 31.3l4.2-4.2'
	+ 'M27.1 12.9l4.2-4.2"/></g>'
)
const SPEAKER: String = (
	'<path d="M6 16v8h6l9 7V9l-9 7z" fill="#FBF3E2" stroke="#2B1A0F" stroke-width="3"'
	+ ' stroke-linejoin="round"/><path d="M26 14a8 8 0 0 1 0 12M30 9a14 14 0 0 1 0 22"'
	+ ' stroke="#2B1A0F" stroke-width="3" fill="none" stroke-linecap="round"/>'
)
const PAUSE: String = '<path d="M12 8h6v24h-6zM23 8h6v24h-6z" fill="#2B1A0F"/>'
const PLAY: String = '<path d="M12 7l20 13-20 13z" fill="#2B1A0F"/>'
const STEP: String = (
	'<path d="M8 8l16 12-16 12z" fill="#2B1A0F"/>' + '<path d="M26 8h6v24h-6z" fill="#2B1A0F"/>'
)
const SKIP: String = '<path d="M5 8l14 12L5 32zM21 8l14 12-14 12z" fill="#F7ECD4"/>'
const STAR: String = (
	'<path d="M20 2l4.7 12.3L38 20l-13.3 5.7L20 38l-4.7-12.3L2 20l13.3-5.7z" fill="#F0C14B"'
	+ ' stroke="#2B1A0F" stroke-width="3" stroke-linejoin="round"/>'
)
const SPARK: String = (
	'<path d="M20 1l4 15 15 4-15 4-4 15-4-15-15-4 15-4z" fill="#F7ECD4" stroke="#2B1A0F"'
	+ ' stroke-width="2" stroke-linejoin="round"/>'
)
## The hit starburst, 74 x 74 in the mock; drawn on a 40 box here.
const BURST: String = (
	'<g transform="scale(0.54)"><path d="M37 2l8 18 19-9-6 20 15 8-17 8 9 19-20-5-8 13-8-13-20'
	+ ' 5 9-19-17-8 15-8-6-20 19 9z" fill="#B8322A" stroke="#2B1A0F" stroke-width="4"'
	+ ' stroke-linejoin="round"/></g>'
)
const BONES: String = (
	'<circle cx="20" cy="20" r="17" fill="#2B1A0F"/><path d="M12 12l16 16M28 12L12 28"'
	+ ' stroke="#F7ECD4" stroke-width="5" stroke-linecap="round"/>'
)
const LEAF_PUFF: String = (
	'<path d="M4 20C10 6 30 6 36 20C30 34 10 34 4 20z" fill="#41662C" stroke="#2B1A0F"'
	+ ' stroke-width="3"/>'
)

const GRAIN_OAK: String = (
	'<svg xmlns="http://www.w3.org/2000/svg" width="420" height="120"><g fill="none"'
	+ ' stroke="#8C5A2E" stroke-width="2.5" stroke-linecap="round" opacity=".7">'
	+ '<path d="M0 20 C80 14 150 28 230 20 S360 14 420 22"/>'
	+ '<path d="M0 62 C60 70 120 52 190 60 C240 66 270 46 310 50 C350 54 390 64 420 62"/>'
	+ '<path d="M240 40 c14 -10 38 -9 46 3 c-10 10 -34 10 -46 -3z"/>'
	+ '<path d="M0 100 C100 96 200 108 300 100 S390 96 420 102"/></g></svg>'
)
const GRAIN_LIME: String = (
	'<svg xmlns="http://www.w3.org/2000/svg" width="520" height="160"><g fill="none"'
	+ ' stroke="#B8956A" stroke-width="2.5" stroke-linecap="round" opacity=".55">'
	+ '<path d="M0 30 C90 22 160 40 260 30 S430 20 520 32"/>'
	+ '<path d="M300 66 c20 -14 52 -12 64 4 c-14 14 -46 14 -64 -4z"/>'
	+ '<path d="M0 122 C120 116 220 130 330 122 S470 116 520 124"/></g></svg>'
)
const CHIP_BAND: String = (
	'<svg xmlns="http://www.w3.org/2000/svg" width="28" height="16"><path d="M0 0h28v16H0z"'
	+ ' fill="#C08A52"/><path d="M0 0 L14 16 L0 16z" fill="#8C5A2E"/><path d="M14 16 L28 0 L28 16z"'
	+ ' fill="#8C5A2E"/><path d="M0 0 L14 16 L28 0z" fill="#D9A86E"/>'
	+ '<path d="M14 16 L14 6 L0 0z" fill="#B07A43"/></svg>'
)
const RIME_STRIPES: String = (
	'<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40">'
	+ '<path d="M0 0h40v40H0z" fill="#A8D4E6" fill-opacity=".35"/>'
	+ '<path d="M-10 30L30 -10H50L-10 50zM30 50L50 30V50z" fill="#D6EEF7" fill-opacity=".7"/>'
	+ "</svg>"
)

## A heap of three: what three Acorns combine into.
const STASH: String = (
	'<path d="M3 37c4-4 30-4 34 0z" fill="#7A4A22" stroke="#2B1A0F" stroke-width="2"/>'
	+ '<g transform="translate(-1 14) scale(.58)">'
	+ ACORN
	+ "</g>"
	+ '<g transform="translate(18 14) scale(.58)">'
	+ ACORN
	+ "</g>"
	+ '<g transform="translate(8.5 0) scale(.58)">'
	+ ACORN
	+ "</g>"
)
## A full basket, heaped and shining: the biggest size.
const GREAT_HOARD: String = (
	'<g transform="translate(-1 2) scale(.46)">'
	+ ACORN
	+ "</g>"
	+ '<g transform="translate(22 2) scale(.46)">'
	+ ACORN
	+ "</g>"
	+ '<g transform="translate(10.5 -1) scale(.5)">'
	+ ACORN
	+ "</g>"
	+ '<g transform="translate(3 8) scale(.46)">'
	+ ACORN
	+ "</g>"
	+ '<g transform="translate(18 8) scale(.46)">'
	+ ACORN
	+ "</g>"
	+ '<path d="M2 22h36l-4 16H6z" fill="#B9822F" stroke="#2B1A0F" stroke-width="2.5"'
	+ ' stroke-linejoin="round"/>'
	+ '<path d="M4 27h32M6 32h28M12 22l2 16M20 22v16M28 22l-2 16" stroke="#2B1A0F"'
	+ ' stroke-width="1.6" fill="none"/>'
	+ '<path d="M33 3l1.5 3.5L38 8l-3.5 1.5L33 13l-1.5-3.5L28 8l3.5-1.5z" fill="#FFF3B0"'
	+ ' stroke="#2B1A0F" stroke-width="1"/>'
)

const ICONS: Dictionary[String, String] = {
	"acorn": ACORN,
	"stash": STASH,
	"great_hoard": GREAT_HOARD,
	"tier": TIER,
	"refresh": REFRESH,
	"freeze": FREEZE,
	"sword": SWORD,
	"berry": BERRY,
	"berry_big": BERRY_BIG,
	"atk": ATK,
	"hp": HP,
	"hp_hurt": HP_HURT,
	"hp_out": HP_OUT,
	"gear": GEAR,
	"speaker": SPEAKER,
	"pause": PAUSE,
	"play": PLAY,
	"step": STEP,
	"skip": SKIP,
	"star": STAR,
	"spark": SPARK,
	"burst": BURST,
	"bones": BONES,
	"leaf": LEAF_PUFF,
}
## Mock pixels on the 640 stage to our canvas.
const MOCK_SCALE: float = 1.6875
## Icons are rasterised a little over size, so they stay sharp on a 1440p window.
const OVERSAMPLE: float = 1.5

static var _cache: Dictionary[String, ImageTexture] = {}


## An Acorn item's picture and how much of its art window it fills: each size is plainly bigger.
static func acorn_item(def_id: String) -> Dictionary:
	match def_id:
		"stash":
			return {"icon": "stash", "share": 0.86}
		"great_hoard":
			return {"icon": "great_hoard", "share": 1.0}
	return {"icon": "acorn", "share": 0.56}


## The named icon on a 40 x 40 box, rasterised for `pixels` canvas units.
static func icon(icon_name: String, pixels: float) -> ImageTexture:
	var size: int = ceili(pixels * OVERSAMPLE)
	var key: String = "%s@%d" % [icon_name, size]
	if _cache.has(key):
		return _cache[key]
	var svg: String = (
		'<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">'
		+ ICONS.get(icon_name, "")
		+ "</svg>"
	)
	var texture: ImageTexture = _raster(svg, float(size) / 40.0)
	_cache[key] = texture
	return texture


## A repeating tile at mock scale: "oak", "lime", "chip" or "rime".
static func tile(tile_name: String) -> ImageTexture:
	var key: String = "tile:" + tile_name
	if _cache.has(key):
		return _cache[key]
	var svg: String = GRAIN_OAK
	match tile_name:
		"lime":
			svg = GRAIN_LIME
		"chip":
			svg = CHIP_BAND
		"rime":
			svg = RIME_STRIPES
	var texture: ImageTexture = _raster(svg, MOCK_SCALE)
	_cache[key] = texture
	return texture


static func _raster(svg: String, scale: float) -> ImageTexture:
	var image: Image = Image.new()
	var result: Error = image.load_svg_from_string(svg, scale)
	if result != OK:
		push_error("icons: can't rasterise an SVG (%s)" % svg.left(60))
		return ImageTexture.create_from_image(Image.create_empty(4, 4, false, Image.FORMAT_RGBA8))
	return ImageTexture.create_from_image(image)
