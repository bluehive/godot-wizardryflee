extends Node3D

## Title / Explore / Encounter / Cleared — flee only, no combat.

enum State { TITLE, EXPLORE, ENCOUNTER, CLEARED }

var state: int = State.TITLE
var map: WFGridMap
var gx: int = 0
var gz: int = 0
var facing: int = 0  # 0=N
var busy: bool = false
var cleared_encounters: Dictionary = {}  # Vector2i -> true as string key
var current_monster: Dictionary = {}

@onready var dungeon: Node3D = $Dungeon
@onready var camera: Camera3D = $Camera3D
@onready var monster_visual: MeshInstance3D = $MonsterVisual
@onready var light: OmniLight3D = $Camera3D/OmniLight3D

@onready var title_panel: Control = $UI/Title
@onready var hud: Control = $UI/HUD
@onready var encounter_panel: Control = $UI/Encounter
@onready var clear_panel: Control = $UI/Cleared
@onready var hud_label: Label = $UI/HUD/Margin/VBox/Info
@onready var enc_title: Label = $UI/Encounter/Center/Panel/Margin/VBox/Title
@onready var enc_flavor: Label = $UI/Encounter/Center/Panel/Margin/VBox/Flavor
@onready var enc_hint: Label = $UI/Encounter/Center/Panel/Margin/VBox/Hint


func _ready() -> void:
	_apply_fonts()
	map = WFGridMap.load_default()
	if map.width == 0:
		push_error("Map failed to load")
		return
	WFDungeonBuilder.build(dungeon, map)
	gx = map.start.x
	gz = map.start.y
	facing = 0
	monster_visual.visible = false
	_snap_camera()
	_set_state(State.TITLE)


func _apply_fonts() -> void:
	var font: Font = null
	if ResourceLoader.exists(WFConstants.FONT_PATH):
		font = load(WFConstants.FONT_PATH)
	if font == null:
		return
	for n in [
		$UI/Title/Center/VBox/Title,
		$UI/Title/Center/VBox/Sub,
		$UI/Title/Center/VBox/Hint,
		hud_label,
		enc_title,
		enc_flavor,
		enc_hint,
		$UI/Cleared/Center/VBox/Title,
		$UI/Cleared/Center/VBox/Hint,
	]:
		if n is Label:
			(n as Label).add_theme_font_override("font", font)


func _process(_delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode

	match state:
		State.TITLE:
			if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				_begin_explore()
			elif key == KEY_ESCAPE:
				get_tree().quit()
		State.EXPLORE:
			if busy:
				return
			if key in [KEY_W, KEY_UP]:
				_try_step(1)
			elif key in [KEY_S, KEY_DOWN]:
				_try_step(-1)
			elif key in [KEY_A, KEY_LEFT]:
				_try_turn(-1)
			elif key in [KEY_D, KEY_RIGHT]:
				_try_turn(1)
			elif key == KEY_ESCAPE:
				_set_state(State.TITLE)
		State.ENCOUNTER:
			if key == KEY_F:
				_flee()
		State.CLEARED:
			if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				_set_state(State.TITLE)
			elif key == KEY_ESCAPE:
				get_tree().quit()


func _begin_explore() -> void:
	gx = map.start.x
	gz = map.start.y
	facing = 0
	cleared_encounters.clear()
	busy = false
	monster_visual.visible = false
	_snap_camera()
	_set_state(State.EXPLORE)
	_update_hud("探索開始。矢印/WASDで移動。")


func _set_state(s: int) -> void:
	state = s
	title_panel.visible = s == State.TITLE
	hud.visible = s == State.EXPLORE or s == State.ENCOUNTER
	encounter_panel.visible = s == State.ENCOUNTER
	clear_panel.visible = s == State.CLEARED
	if s == State.TITLE:
		monster_visual.visible = false


func _enc_key(p: Vector2i) -> String:
	return "%d,%d" % [p.x, p.y]


func _try_step(sign: int) -> void:
	var d: Vector2i = WFConstants.DIR_FORWARD[facing] * sign
	var np := Vector2i(gx, gz) + d
	if not map.is_walkable(np):
		_update_hud("壁だ。")
		return
	busy = true
	gx = np.x
	gz = np.y
	var target := _camera_target_pos()
	var tw := create_tween()
	tw.tween_property(camera, "position", target, WFConstants.MOVE_TIME)
	tw.finished.connect(_on_move_finished, CONNECT_ONE_SHOT)


func _try_turn(delta_facing: int) -> void:
	busy = true
	facing = (facing + delta_facing + 4) % 4
	var tw := create_tween()
	tw.tween_property(camera, "rotation", Vector3(0, WFConstants.DIR_YAW[facing], 0), WFConstants.TURN_TIME)
	tw.finished.connect(func () -> void:
		busy = false
		_update_hud(_status_line())
	, CONNECT_ONE_SHOT)


func _on_move_finished() -> void:
	busy = false
	var p := Vector2i(gx, gz)
	if map.is_goal(p):
		_set_state(State.CLEARED)
		return
	if map.is_encounter_cell(p) and not cleared_encounters.has(_enc_key(p)):
		_start_encounter(p)
		return
	_update_hud(_status_line())


func _start_encounter(p: Vector2i) -> void:
	var idx := absi(p.x * 17 + p.y * 31) % WFConstants.MONSTERS.size()
	current_monster = WFConstants.MONSTERS[idx]
	enc_title.text = "%s が現れた！" % str(current_monster["name"])
	enc_flavor.text = str(current_monster["flavor"])
	enc_hint.text = "[F] 逃げる　（戦えない）"
	_show_monster(current_monster["color"] as Color)
	_set_state(State.ENCOUNTER)
	_update_hud("遭遇！ 戦う手段はない。")


func _show_monster(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	monster_visual.material_override = mat
	# Place in front of camera
	var forward: Vector2i = WFConstants.DIR_FORWARD[facing]
	var world := map.grid_to_world(Vector2i(gx, gz))
	var ahead := world + Vector3(forward.x, 0, forward.y) * (WFConstants.CELL_SIZE * 0.55)
	monster_visual.position = ahead + Vector3(0, 1.0, 0)
	monster_visual.visible = true


func _flee() -> void:
	var p := Vector2i(gx, gz)
	cleared_encounters[_enc_key(p)] = true
	monster_visual.visible = false
	_set_state(State.EXPLORE)
	_update_hud("逃げ切った…（%s）" % str(current_monster.get("name", "?")))
	current_monster = {}


func _camera_target_pos() -> Vector3:
	var w := map.grid_to_world(Vector2i(gx, gz))
	return w + Vector3(0, WFConstants.EYE_HEIGHT, 0)


func _snap_camera() -> void:
	camera.position = _camera_target_pos()
	camera.rotation = Vector3(0, WFConstants.DIR_YAW[facing], 0)


func _status_line() -> String:
	var dirs := ["北", "東", "南", "西"]
	return "位置 (%d,%d) 向き:%s  |  WASD/矢印 移動  Esc タイトル" % [gx, gz, dirs[facing]]


func _update_hud(msg: String) -> void:
	hud_label.text = msg
