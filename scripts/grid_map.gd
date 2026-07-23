class_name WFGridMap
extends RefCounted

## Character-grid dungeon map.

enum Cell { WALL, FLOOR, START, GOAL, ENCOUNTER }

var width: int = 0
var height: int = 0
var _cells: Array = []  # Array[Array[int]]
var start: Vector2i = Vector2i.ZERO
var goal: Vector2i = Vector2i.ZERO
var encounters: Array[Vector2i] = []


static func load_default() -> WFGridMap:
	return load_from_string(WFMapData.FLOOR_01)


static func load_from_string(text: String) -> WFGridMap:
	var m := WFGridMap.new()
	var rows: PackedStringArray = []
	for raw in text.split("\n"):
		var line := str(raw).strip_edges()
		# Comments only: empty, //..., or "# " prose (map walls are pure #.#### lines)
		if line.is_empty() or line.begins_with("//"):
			continue
		if line.begins_with("#") and line.contains(" "):
			continue
		rows.append(line)
	if rows.is_empty():
		push_error("Empty map string")
		return m
	m.height = rows.size()
	m.width = 0
	for r in rows:
		m.width = maxi(m.width, r.length())
	m._cells.clear()
	m.encounters.clear()
	for y in m.height:
		var row: Array = []
		var line: String = rows[y]
		for x in m.width:
			var ch := " "
			if x < line.length():
				ch = line[x]
			var cell := Cell.WALL
			match ch:
				"#", " ":
					cell = Cell.WALL
				".":
					cell = Cell.FLOOR
				"S":
					cell = Cell.START
					m.start = Vector2i(x, y)
				"G":
					cell = Cell.GOAL
					m.goal = Vector2i(x, y)
				"E", "M":
					cell = Cell.ENCOUNTER
					m.encounters.append(Vector2i(x, y))
				_:
					cell = Cell.WALL
			row.append(cell)
		m._cells.append(row)
	return m


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func get_cell(p: Vector2i) -> int:
	if not in_bounds(p):
		return Cell.WALL
	return _cells[p.y][p.x]


func is_walkable(p: Vector2i) -> bool:
	var c := get_cell(p)
	return c == Cell.FLOOR or c == Cell.START or c == Cell.GOAL or c == Cell.ENCOUNTER


func is_goal(p: Vector2i) -> bool:
	return get_cell(p) == Cell.GOAL


func is_encounter_cell(p: Vector2i) -> bool:
	return get_cell(p) == Cell.ENCOUNTER


func grid_to_world(p: Vector2i) -> Vector3:
	## Cell center. X east, Z south (row increases +Z).
	var cs := WFConstants.CELL_SIZE
	return Vector3((p.x + 0.5) * cs, 0.0, (p.y + 0.5) * cs)
