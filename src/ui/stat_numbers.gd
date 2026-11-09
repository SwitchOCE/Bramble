extends RefCounted
## Compact stat labels; the underlying view keeps its exact integers.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const COMPACT_FROM: int = 10000
## Smaller badges may compact thousands before the usual cutoff.
const EXACT_DETAILS_FROM: int = 1000


static func compact(value: int, decimals: int = 1, force: bool = false) -> String:
	if value < COMPACT_FROM and not force:
		return str(value)
	var divisor: int = 1000
	var suffix: String = "k"
	var rounding: int = 50 if decimals == 1 else 500
	# Promote at the rounding boundary, avoiding labels such as 1000k.
	if value >= 1000000000 - rounding * 1000:
		divisor = 1000000000
		suffix = "b"
	elif value >= 1000000 - rounding:
		divisor = 1000000
		suffix = "m"
	if decimals == 0:
		@warning_ignore("integer_division")
		var rounded: int = (value + divisor / 2) / divisor
		return "%d%s" % [rounded, suffix]
	@warning_ignore("integer_division")
	var tenths: int = (value * 10 + divisor / 2) / divisor
	@warning_ignore("integer_division")
	var whole: int = tenths / 10
	var decimal: int = tenths % 10
	return "%d%s" % [whole, suffix] if decimal == 0 else "%d.%d%s" % [whole, decimal, suffix]


## Last-resort fractions of the next suffix keep narrow badges readable: .1m, .9m, .1b.
static func candidates(value: int) -> PackedStringArray:
	var options: PackedStringArray = [compact(value)]
	if value < EXACT_DETAILS_FROM:
		return options
	options.append(compact(value, 1, true))
	options.append(compact(value, 0, true))
	# Three-digit whole-unit labels need the next suffix. Keep one/two-digit
	# million labels familiar by allowing a small badge to widen for them instead.
	if (value >= 99500 and value < 1000000) or (value >= 99500000 and value < 1000000000):
		var divisor: int = 1000000 if value < 1000000 else 1000000000
		var suffix: String = "m" if value < 1000000 else "b"
		@warning_ignore("integer_division")
		var tenths: int = (value * 10 + divisor / 2) / divisor
		if tenths > 0 and tenths < 10:
			options.append(".%d%s" % [tenths, suffix])
		elif tenths == 10:
			options.append("1" + suffix)
	return options


static func exact(value: int) -> String:
	var digits: String = str(absi(value))
	var out: String = ""
	for index: int in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			out += ","
		out += digits[index]
	return ("-" if value < 0 else "") + out


## Width of the shortest honest approximation at the minimum font size.
static func minimum_width(value: int, font: Font) -> float:
	var width: float = INF
	for text: String in candidates(value):
		width = minf(
			width, font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.MIN_FONT).x
		)
	return width


## Prefer precision over the narrowest label when a bounded badge can accommodate it.
static func preferred_width(value: int, font: Font, limit: float) -> float:
	for text: String in candidates(value):
		var width: float = (
			font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.MIN_FONT).x
		)
		if width <= limit:
			return width
	return minimum_width(value, font)


static func fit(label: Label, width: float, preferred: int, value: int) -> void:
	var font: Font = label.get_theme_font("font")
	var options: PackedStringArray = candidates(value)
	label.text = options[-1]
	for text: String in options:
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.MIN_FONT).x <= width:
			label.text = text
			break
	var fitted: int = maxi(preferred, UiTheme.MIN_FONT)
	while (
		fitted > UiTheme.MIN_FONT
		and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > width
	):
		fitted -= 1
	label.add_theme_font_size_override("font_size", fitted)
