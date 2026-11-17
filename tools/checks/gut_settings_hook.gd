extends GutHookScript
## GUT pre-run hook (wired in .gutconfig.json): the tests never read the player's saved settings.
## GameSettings reads a file of the tests' own (user://test_settings.cfg, deleted first) and starts
## at its defaults (cards drop where the pointer is), whatever a person last picked on this
## machine. A test that changes a setting puts it back after itself.

const PATH: String = "user://test_settings.cfg"


func run() -> void:
	# Game fixtures never share the folder the owner exports. This lasts for this process only.
	GameRecord.directory = "res://build/test-records"
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	GameSettings.path = PATH
	GameSettings.forget()
	print("gut_settings: tests use %s" % PATH)
