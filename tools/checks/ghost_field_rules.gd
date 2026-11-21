extends SceneTree
## Print the rules identity of the imported project about to be exported.


func _initialize() -> void:
	print("ghost field rules: %s" % RecordBuild.identity()["rules_hash"])
	quit()
