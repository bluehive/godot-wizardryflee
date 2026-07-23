extends SceneTree

## Headless smoke for `godot -s` (no class_name globals — they are unreliable under -s).

const REQUIRED := [
	"res://scenes/main.tscn",
	"res://scripts/game_root.gd",
	"res://scripts/grid_map.gd",
	"res://scripts/map_data.gd",
	"res://scripts/dungeon_builder.gd",
	"res://scripts/constants.gd",
	"res://project.godot",
]


func _init() -> void:
	var pname := str(ProjectSettings.get_setting("application/config/name", ""))
	print("[smoke] project OK: ", pname)
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

	for path in REQUIRED:
		if not _exists(path):
			push_error("[smoke] missing: %s" % path)
			quit(1)
			return
		print("[smoke] found ", path)

	# Parse embedded map without class_name (read map_data.gd source).
	var map_src := FileAccess.get_file_as_string("res://scripts/map_data.gd")
	if map_src.is_empty() or not map_src.contains("FLOOR_01"):
		push_error("[smoke] map_data.gd unreadable or missing FLOOR_01")
		quit(1)
		return
	var rows := 0
	for line in map_src.split("\n"):
		var t := line.strip_edges()
		# map rows are quoted walls like ########### inside the triple-quoted block
		if t.begins_with("#") and not t.contains(" ") and t.length() >= 3 and not t.begins_with("# "):
			# skip GDScript comments that are only "#"
			pass
	# Count wall-only lines inside the string literal more simply:
	if map_src.count("###########") < 2:
		push_error("[smoke] map rows look missing in map_data.gd")
		quit(1)
		return
	print("[smoke] map_data FLOOR_01 present")
	print("[smoke] OK")
	quit(0)


func _exists(path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	return FileAccess.file_exists(path)
