extends SceneTree
## Temporary module-integration entrypoint; never substitutes for the formal main scene.
func _initialize() -> void:
	var main_script: Script=load("res://scripts/scifi/ScifiMain.gd")
	if main_script==null or not main_script.can_instantiate():
		quit(2)
		return
	root.add_child.call_deferred(main_script.new())
