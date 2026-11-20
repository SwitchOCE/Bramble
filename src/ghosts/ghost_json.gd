class_name GhostJson
extends RefCounted
## Compact JSON in insertion order, with the same string escaping as serde_json, and SHA-256 ids.


static func sha256(bytes: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():
		hasher.update(bytes)
	return hasher.finish().hex_encode()


static func encode(value: Variant, sort_keys: bool = false) -> String:
	var encoded: String = JSON.stringify(value, "", sort_keys)
	# Godot uses C escapes for vertical tab and leaves some other control codes raw.
	# Skip over backslash escapes already emitted so a literal backslash-v stays literal.
	var parts: PackedStringArray = []
	var start: int = 0
	var i: int = 0
	while i < encoded.length():
		var code: int = encoded.unicode_at(i)
		if code < 32 or (code == 92 and encoded.unicode_at(i + 1) == 118):
			parts.append(encoded.substr(start, i - start))
			parts.append("\\u%04x" % (11 if code == 92 else code))
			i += 2 if code == 92 else 1
			start = i
		else:
			i += 2 if code == 92 else 1
	if start == 0:
		return encoded
	parts.append(encoded.substr(start))
	return "".join(parts)
