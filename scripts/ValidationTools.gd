extends Node

static func parse_args() -> Dictionary:
	var parsed := {
		"seed": 1,
		"debug_mode": "",
		"validation_report": "",
		"capture_dir": "",
		"run_seconds": -1.0,
		"time_scale": 1.0,
		"auto_upgrade": false,
		"auto_play": false,
		"debug_overlay": false,
		"score_save_path": "",
		"score_probe_phase": ""
	}
	var args := []
	args.append_array(OS.get_cmdline_args())
	args.append_array(OS.get_cmdline_user_args())
	for raw in args:
		var arg: String = raw
		if arg.begins_with("--seed="):
			parsed.seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--debug-mode="):
			parsed.debug_mode = arg.trim_prefix("--debug-mode=")
		elif arg.begins_with("--validation-report="):
			parsed.validation_report = arg.trim_prefix("--validation-report=")
		elif arg.begins_with("--capture-dir="):
			parsed.capture_dir = arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--run-seconds="):
			parsed.run_seconds = float(arg.trim_prefix("--run-seconds="))
		elif arg.begins_with("--time-scale="):
			parsed.time_scale = max(0.1, float(arg.trim_prefix("--time-scale=")))
		elif arg.begins_with("--score-save-path="):
			parsed.score_save_path = arg.trim_prefix("--score-save-path=")
		elif arg.begins_with("--score-probe-phase="):
			parsed.score_probe_phase = arg.trim_prefix("--score-probe-phase=")
		elif arg == "--auto-upgrade":
			parsed.auto_upgrade = true
		elif arg == "--auto-play":
			parsed.auto_play = true
		elif arg == "--debug-overlay":
			parsed.debug_overlay = true
	return parsed

static func write_json(path: String, data: Dictionary) -> void:
	if path.is_empty():
		return
	var dir := path.get_base_dir()
	if not dir.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir) if dir.begins_with("res://") or dir.begins_with("user://") else dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("無法寫出驗證快照：%s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

static func ensure_dir(path: String) -> void:
	if path.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path)

static func save_viewport_png(viewport: Viewport, path: String) -> bool:
	if path.is_empty():
		return false
	if DisplayServer.get_name().to_lower().contains("headless"):
		return false
	var texture := viewport.get_texture()
	if texture == null:
		return false
	var image := texture.get_image()
	if image == null:
		return false
	return image.save_png(path) == OK
