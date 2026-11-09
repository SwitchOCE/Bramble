extends RefCounted
## Compact stat labels; the underlying view keeps its exact integers.

const COMPACT_FROM: int = 10000
## Stat numerals may shrink below body text, as requested for the phone's fixed badges.
const MIN_FIT_FONT: int = 12


static func compact(value: int) -> String:
	if value < COMPACT_FROM:
		return str(value)
	var divisor: int = 1000
	var suffix: String = "k"
	# Promote at the rounding boundary, avoiding labels such as 1000k.
	if value >= 999950000:
		divisor = 1000000000
		suffix = "b"
	elif value >= 999950:
		divisor = 1000000
		suffix = "m"
	@warning_ignore("integer_division")
	var tenths: int = (value * 10 + divisor / 2) / divisor
	@warning_ignore("integer_division")
	var whole: int = tenths / 10
	var decimal: int = tenths % 10
	return "%d%s" % [whole, suffix] if decimal == 0 else "%d.%d%s" % [whole, decimal, suffix]


static func exact(value: int) -> String:
	var digits: String = str(absi(value))
	var out: String = ""
	for index: int in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			out += ","
		out += digits[index]
	return ("-" if value < 0 else "") + out


static func fit(label: Label, width: float, preferred: int) -> void:
	label.set_meta("stat_font_fit", true)
	var font: Font = label.get_theme_font("font")
	var fitted: int = preferred
	while (
		fitted > MIN_FIT_FONT
		and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > width
	):
		fitted -= 1
	label.add_theme_font_size_override("font_size", fitted)
