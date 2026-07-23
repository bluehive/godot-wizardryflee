extends SceneTree

func _init() -> void:
	var name := str(ProjectSettings.get_setting("application/config/name", ""))
	print("[smoke] project OK: ", name)
	var main: Variant = ProjectSettings.get_setting("application/run/main_scene", "")
	print("[smoke] main_scene: ", main)
	if main == null or str(main).is_empty():
		push_error("[smoke] main_scene missing")
		quit(1)
		return
	if not ResourceLoader.exists(str(main)):
		push_error("[smoke] main scene not found: %s" % main)
		quit(1)
		return
	var m = WFGridMap.load_default()
	if m.width < 3 or m.height < 3:
		push_error("[smoke] map parse failed")
		quit(1)
		return
	print("[smoke] map %dx%d start=%s goal=%s encounters=%d" % [
		m.width, m.height, m.start, m.goal, m.encounters.size()
	])
	print("[smoke] OK")
	quit(0)
