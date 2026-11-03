extends RefCounted
## The looks the owner can switch between (main menu, dev panel). Each direction is plain data:
## colour roles, tribe colours, fonts and shape choices. UiTheme reads the active one and builds
## the Theme from it; screens take colours and shapes only from UiTheme. Adding a direction is one
## more entry here (plus its fonts under assets/fonts/).
##
## Folk Print is the design lab's round 2 direction (Bramble-design, docs/design-lab/r2/folk-print):
## three printing inks on unbleached paper, palette.json word for word. Woodcraft is Hedgerow
## Woodcraft, round 2 (r2/woodcraft, combat from r3/woodcraft): painted wood on a limewood table,
## flat fills only (no grain), palette.json word for word except the stand-ins marked below.

const PLAIN: String = "plain"
const FOLK_PRINT: String = "folk_print"
const WOODCRAFT: String = "woodcraft"
## Switch order and the names shown on the switch.
const ORDER: PackedStringArray = [PLAIN, FOLK_PRINT, WOODCRAFT]
const TITLES: Dictionary[String, String] = {
	PLAIN: "Plain", FOLK_PRINT: "Folk Print", WOODCRAFT: "Woodcraft"
}

## Shape keys (all absent in Plain, which keeps round badges and rounded cards):
##   attack_shape, health_shape, tier_shape  ShapeBadge shapes ("shield", "nut", "heart",
##                "rosehip", "star"; "circle" when absent)
##   frame        "arch": arched card, tribe-ink band, art clipped to an arched window;
##                "tile": a cream tile with an ink edge, the art inset with a cream mat
##   name_ribbon  card name on a swallowtail ribbon
##   names_in_display  card names in the display font (else the bold body font)
##   tray         board drawn on a tray cut to the 4-3 shape, joined back to front
##   stitch       how the tray joins back to front: "dashes" (default) or "dots" (grooves)
##   slot_chips   each slot's name (F1, B2) on an ink chip on its bottom edge, over the card
##   slot_notes   empty slots say where they are: "front row" / "behind F3 · F4", or with
##                slot_note_words "pockets": "in front of B1 & B2" / "behind F3 & F4"
##   fight_note   "then fight <opponent>" under End turn
##   paper_inputs text boxes, spin boxes and drop-downs in the look's colours (Plain keeps Godot's)
##   frost_rim    frozen shop cards get a frost rim; the face and stats stay at full contrast
##   lobby_tier   each lobby row starts with the player's tier on a knot
##   primary_leaf the main action's button is leaf-shaped (two big opposite corners)
## Optional colour roles fall back to Plain's rule when a look leaves them out (UiTheme.use).
const DIRECTIONS: Dictionary = {
	PLAIN:
	{
		"colours":
		{
			"BG": Color("1c2a1d"),
			"PANEL": Color("2a3b29"),
			"PANEL_LIGHT": Color("3a4f38"),
			"PANEL_BORDER": Color("55704f"),
			"TEXT": Color("f1eee2"),
			"TEXT_DIM": Color("b9c2ac"),
			"INK": Color("1d1d1b"),
			"PARCHMENT": Color("f4efe1"),
			"GOLD": Color("f2c14e"),
			"HEADING": Color("f2c14e"),
			"GOLDEN_FRAME": Color("ffcf3f"),
			"ATTACK": Color("f2b53c"),
			"HEALTH": Color("d9443a"),
			# HEALTH.lightened(0.35), the value Plain used before looks were data.
			"HEALTH_TEXT": Color(0.90313727, 0.52333333, 0.49784314),
			"HEALTH_DAMAGED": Color("7d1f1a"),
			"STAT_TEXT": Color.WHITE,
			"TIER_FILL": Color("1d1d1b"),
			"TIER_TEXT": Color("f2c14e"),
			"TIER_BORDER": Color("f2c14e"),
			"BUFF": Color("7fd36b"),
			"DAMAGE": Color("ff5a4a"),
			"NIGHTSHADE": Color("9b4fd1"),
			"FROZEN": Color("8fd3ff"),
			"FROZEN_FILL": Color("24384a"),
			"SELECT": Color("ffe680"),
			"DROP_OK": Color("9cf08a"),
			"SELL": Color("ff8a6a"),
			"SELL_FILL": Color("3d2620"),
			"WIN": Color("8be07a"),
			"LOSS": Color("ff7a6a"),
			"TIE": Color("d9d3b5"),
			"EMPTY_FILL": Color(0, 0, 0, 0.18),
			"SLOT_FILL": Color(0, 0, 0, 0.22),
			"SLOT_BORDER": Color("55704f"),
			"DEV_FILL": Color("2b2433"),
			"OUT_FILL": Color("232823"),
			"BAR_BACK": Color("161a16"),
			"BAR_OUT": Color("555555"),
			"NOT_BUILT": Color("8a3b32"),
			"SHADE": Color(0, 0, 0, 0.45),
			"PORTRAIT_TEXT": Color(1, 1, 1, 0.85),
			"PILL_BORDER": Color.WHITE,
			"PILL_TEXT": Color.WHITE,
			"BUTTON": Color("e8dfc4"),
			"BUTTON_BORDER": Color("8c7f5c"),
			"BUTTON_HOVER": Color("fff4d6"),
			"BUTTON_HOVER_BORDER": Color("c9a94f"),
			"BUTTON_PRESSED": Color("d2c49b"),
			"BUTTON_DISABLED": Color("a7a28f"),
			"BUTTON_DISABLED_BORDER": Color("77735f"),
			"BUTTON_TEXT": Color("1d1d1b"),
			"BUTTON_TEXT_DISABLED": Color("6d6d66"),
			"PRIMARY": Color("f2c14e"),
			"PRIMARY_TEXT": Color("1d1d1b"),
			"SHADOW": Color.TRANSPARENT,
			"TRAY": Color.TRANSPARENT,
			"TRAY_SHADOW": Color.TRANSPARENT,
			"STITCH": Color.TRANSPARENT,
			"LOG_SIDE_0": Color("e8dfc4"),
			"LOG_SIDE_1": Color("f3b9a6"),
			"REMINDER": Color("9a9f8c"),
			"LOG_NIGHTSHADE": Color("c9a0f0"),
			"NOTE_WARN": Color("ff9a8a"),
			"NOTE_GOLDEN": Color("ffcf3f"),
		},
		"tribes":
		{
			"Fairies": Color("9a86cf"),
			"Oozes": Color("6aa84f"),
			"Hedgerow folk": Color("c98a52"),
			"Hunters": Color("d9653b"),
			"Birds": Color("4a90c2"),
			"Bog folk": Color("3f8a7e"),
			"Hive": Color("e1b530"),
		},
		"neutral": Color("9a9a8e"),
		"body_font": "",
		"display_font": "",
		"button_radius": [10, 10],
		"button_shadow": Vector2.ZERO,
		"shapes": {},
	},
	FOLK_PRINT:
	{
		"colours":
		{
			"BG": Color("F3EAD6"),
			"PANEL": Color("E3D1AE"),
			"PANEL_LIGHT": Color("E9DBBB"),
			"PANEL_BORDER": Color("1D1A1E"),
			"TEXT": Color("1D1A1E"),
			"TEXT_DIM": Color("615950"),
			"INK": Color("1D1A1E"),
			"PARCHMENT": Color("F3EAD6"),
			"GOLD": Color("DEA526"),
			"HEADING": Color("BF2F1B"),
			"GOLDEN_FRAME": Color("DEA526"),
			"ATTACK": Color("1D1A1E"),
			"HEALTH": Color("BF2F1B"),
			"HEALTH_TEXT": Color("BF2F1B"),
			"HEALTH_DAMAGED": Color("6E1A0F"),
			"STAT_TEXT": Color("F3EAD6"),
			"TIER_FILL": Color("DEA526"),
			"TIER_TEXT": Color("1D1A1E"),
			"TIER_BORDER": Color("1D1A1E"),
			"BUFF": Color("22684A"),
			"DAMAGE": Color("BF2F1B"),
			"NIGHTSHADE": Color("5D2A6B"),
			"FROZEN": Color("24479A"),
			"FROZEN_FILL": Color("C6D9EB"),
			"SELECT": Color("24479A"),
			"DROP_OK": Color("22684A"),
			"SELL": Color("BF2F1B"),
			"SELL_FILL": Color("F3EAD6"),
			"WIN": Color("22684A"),
			"LOSS": Color("BF2F1B"),
			"TIE": Color("615950"),
			"EMPTY_FILL": Color("F3EAD6"),
			"SLOT_FILL": Color("F3EAD6"),
			"SLOT_BORDER": Color(0.114, 0.102, 0.118, 0.5),
			"DEV_FILL": Color("F3EAD6"),
			"OUT_FILL": Color("E3D1AE"),
			"BAR_BACK": Color("F3EAD6"),
			"BAR_OUT": Color("615950"),
			"NOT_BUILT": Color("615950"),
			"SHADE": Color(0.114, 0.102, 0.118, 0.35),
			"PORTRAIT_TEXT": Color("F3EAD6"),
			"PILL_BORDER": Color("1D1A1E"),
			"PILL_TEXT": Color("F3EAD6"),
			"BUTTON": Color("F3EAD6"),
			"BUTTON_BORDER": Color("1D1A1E"),
			"BUTTON_HOVER": Color("FFF8E8"),
			"BUTTON_HOVER_BORDER": Color("1D1A1E"),
			"BUTTON_PRESSED": Color("E3D1AE"),
			"BUTTON_DISABLED": Color("E3D1AE"),
			"BUTTON_DISABLED_BORDER": Color("615950"),
			"BUTTON_TEXT": Color("1D1A1E"),
			"BUTTON_TEXT_DISABLED": Color("615950"),
			"PRIMARY": Color("BF2F1B"),
			"PRIMARY_TEXT": Color("F3EAD6"),
			"SHADOW": Color("1D1A1E"),
			"TRAY": Color("E9DBBB"),
			"TRAY_SHADOW": Color("BF2F1B"),
			"STITCH": Color("BF2F1B"),
			"LOG_SIDE_0": Color("24479A"),
			"LOG_SIDE_1": Color("BF2F1B"),
			"REMINDER": Color("615950"),
			"LOG_NIGHTSHADE": Color("5D2A6B"),
			"NOTE_WARN": Color("BF2F1B"),
			"NOTE_GOLDEN": Color("1D1A1E"),
		},
		"tribes":
		{
			"Fairies": Color("5D2A6B"),
			# A stand-in: palette.json gives Oozes no ink. Not one of the palette's colours.
			"Oozes": Color("2F6F6A"),
			"Hedgerow folk": Color("22684A"),
			"Hunters": Color("1D1A1E"),
			"Birds": Color("24479A"),
			"Bog folk": Color("5A6A2A"),
			"Hive": Color("DEA526"),
		},
		"neutral": Color("B89C6B"),
		"body_font": "res://assets/fonts/Alegreya-Variable.ttf",
		"display_font": "res://assets/fonts/AlfaSlabOne-Regular.ttf",
		"button_radius": [22, 8],
		"button_shadow": Vector2(4, 5),
		"shapes":
		{
			"attack_shape": "shield",
			"health_shape": "heart",
			"tier_shape": "star",
			"frame": "arch",
			"name_ribbon": true,
			"tray": true,
			"slot_notes": true,
			"fight_note": true,
			"paper_inputs": true,
		},
	},
	WOODCRAFT:
	{
		"colours":
		{
			"BG": Color("E6D3AB"),
			# Stand-in: a lighter oak for panels that hold text (the log, the inspector), so log
			# colours pass 4.5:1; the board tray keeps oak #C08A52.
			"PANEL": Color("D4A773"),
			"PANEL_LIGHT": Color("F7ECD4"),
			"PANEL_BORDER": Color("2B1A0F"),
			"TEXT": Color("2B1A0F"),
			# Walnut, not burned label #5A3A20: secondary text sits on oak panels here (4.8:1).
			"TEXT_DIM": Color("3B2416"),
			"INK": Color("2B1A0F"),
			"PARCHMENT": Color("FBF3E2"),
			"GOLD": Color("D9A441"),
			"HEADING": Color("2B1A0F"),
			"GOLDEN_FRAME": Color("F0C14B"),
			"ATTACK": Color("F2A43A"),
			"ATTACK_TEXT": Color("2B1A0F"),
			"HEALTH": Color("A52A21"),
			"HEALTH_TEXT": Color("A52A21"),
			"LOBBY_HEALTH": Color("A52A21"),
			# Stand-in: a darker rosehip for damaged Health; palette.json has none.
			"HEALTH_DAMAGED": Color("6B1A14"),
			"STAT_TEXT": Color("F7ECD4"),
			"TIER_FILL": Color("F7ECD4"),
			"TIER_TEXT": Color("2B1A0F"),
			"TIER_BORDER": Color("2B1A0F"),
			"TYPE_TEXT": Color("5A3A20"),
			"BUFF": Color("41662C"),
			"DAMAGE": Color("A52A21"),
			"NIGHTSHADE": Color("5E3A86"),
			# Stand-in: a darker rime for frozen text on the frost glaze (5.7:1); rime #2F6680
			# itself is "not used for text".
			"FROZEN": Color("1F4A5E"),
			# The shelf stays wood when frozen; the frost glaze is the rim round each offer.
			"FROZEN_FILL": Color("D4A773"),
			"FROST_GLAZE": Color("A8D4E6"),
			"FROST_RIM": Color("2F6680"),
			"SELECT": Color("41662C"),
			"DROP_OK": Color("2F6680"),
			"SELL": Color("A52A21"),
			"SELL_FILL": Color("FBF3E2"),
			"WIN": Color("41662C"),
			"LOSS": Color("A52A21"),
			"TIE": Color("3B2416"),
			"EMPTY_FILL": Color("8C5A2E"),
			"SLOT_FILL": Color("8C5A2E"),
			"SLOT_BORDER": Color("2B1A0F"),
			"SLOT_TEXT": Color("F7ECD4"),
			"SLOT_CHIP": Color("2B1A0F"),
			"SLOT_CHIP_TEXT": Color("F7ECD4"),
			"DEV_FILL": Color("F7ECD4"),
			"OUT_FILL": Color("CDB283"),
			"BAR_BACK": Color("8C5A2E"),
			"BAR_OUT": Color("3B2416"),
			"NOT_BUILT": Color("3B2416"),
			"SHADE": Color(0.169, 0.102, 0.059, 0.35),
			"PORTRAIT_TEXT": Color("F7ECD4"),
			"PILL_BORDER": Color("2B1A0F"),
			"PILL_TEXT": Color("F7ECD4"),
			"BUTTON": Color("F7ECD4"),
			"BUTTON_BORDER": Color("2B1A0F"),
			"BUTTON_HOVER": Color("FBF3E2"),
			"BUTTON_HOVER_BORDER": Color("2B1A0F"),
			"BUTTON_PRESSED": Color("CDB283"),
			"BUTTON_DISABLED": Color("CDB283"),
			"BUTTON_DISABLED_BORDER": Color("5A3A20"),
			"BUTTON_TEXT": Color("2B1A0F"),
			"BUTTON_TEXT_DISABLED": Color("5A3A20"),
			"PRIMARY": Color("41662C"),
			"PRIMARY_TEXT": Color("F7ECD4"),
			"SHADOW": Color("8C5A2E"),
			"TRAY": Color("C08A52"),
			"TRAY_SHADOW": Color("8C5A2E"),
			"STITCH": Color("2B1A0F"),
			# Stand-ins: darker rime and rosehip, readable on the panels.
			"LOG_SIDE_0": Color("1F4A5E"),
			"LOG_SIDE_1": Color("7A1E17"),
			"REMINDER": Color("5A3A20"),
			"LOG_NIGHTSHADE": Color("5E3A86"),
			"NOTE_WARN": Color("A52A21"),
			"NOTE_GOLDEN": Color("2B1A0F"),
		},
		"tribes":
		{
			"Fairies": Color("5E3A86"),
			# Stand-ins: palette.json gives Oozes and Bog folk no colour.
			"Oozes": Color("5C7A2E"),
			"Bog folk": Color("6B5A2A"),
			"Hedgerow folk": Color("41662C"),
			"Hunters": Color("A52A21"),
			"Birds": Color("2F6680"),
			"Hive": Color("D9A441"),
		},
		"neutral": Color("8C5A2E"),
		"body_font": "res://assets/fonts/AlegreyaSans-Regular.ttf",
		"bold_font": "res://assets/fonts/AlegreyaSans-Bold.ttf",
		"display_font": "res://assets/fonts/Grenze-Variable.ttf",
		"display_weight": 800,
		"number_font": "res://assets/fonts/Bitter-Variable.ttf",
		"number_weight": 900,
		"button_radius": [12, 12],
		"button_shadow": Vector2(0, 4),
		"tray_shadow": Vector2(0, 7),
		"shapes":
		{
			"attack_shape": "nut",
			"health_shape": "rosehip",
			"tier_shape": "circle",
			"frame": "tile",
			"names_in_display": true,
			"tray": true,
			"stitch": "dots",
			"slot_chips": true,
			"slot_notes": true,
			"slot_note_words": "pockets",
			"fight_note": true,
			"paper_inputs": true,
			"frost_rim": true,
			"lobby_tier": true,
			"primary_leaf": true,
		},
	},
}
