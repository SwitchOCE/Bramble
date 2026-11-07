extends RefCounted
## Words the UI run rejects, using the actual lobby rather than the old two-tribe slice.


static func pattern(lobby_tribes: Array) -> RegEx:
	var bad: String = "\\bBot \\d|\\b[a-z]+_[a-z_]+\\b|\\bYou (has|goes)\\b"
	# Empty means every tribe. Otherwise reject only tribes absent from this lobby.
	if not lobby_tribes.is_empty():
		if not lobby_tribes.has("Oozes"):
			bad += "|\\bOozes?\\b"
		if not lobby_tribes.has("Birds"):
			bad += "|\\bBirds?\\b"
	return RegEx.create_from_string(bad)
