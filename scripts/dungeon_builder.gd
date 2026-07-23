class_name WFDungeonBuilder
extends RefCounted

## Build rough 3D meshes from WFGridMap.


static func build(parent: Node3D, map: WFGridMap) -> void:
	# Clear previous
	for c in parent.get_children():
		c.queue_free()

	var cs := WFConstants.CELL_SIZE
	var wh := WFConstants.WALL_HEIGHT

	var floor_mat := _mat(Color(0.22, 0.2, 0.18))
	var wall_mat := _mat(Color(0.32, 0.3, 0.36))
	var ceil_mat := _mat(Color(0.12, 0.11, 0.14))
	var goal_mat := _mat(Color(0.55, 0.45, 0.15))
	var enc_mat := _mat(Color(0.4, 0.15, 0.15))

	for y in map.height:
		for x in map.width:
			var p := Vector2i(x, y)
			var cell: int = map.get_cell(p)
			var center := map.grid_to_world(p)

			if cell == WFGridMap.Cell.WALL:
				var wall := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(cs, wh, cs)
				wall.mesh = box
				wall.material_override = wall_mat
				wall.position = center + Vector3(0, wh * 0.5, 0)
				parent.add_child(wall)
			else:
				# floor
				var floor_mi := MeshInstance3D.new()
				var fbox := BoxMesh.new()
				fbox.size = Vector3(cs * 0.98, 0.12, cs * 0.98)
				floor_mi.mesh = fbox
				if cell == WFGridMap.Cell.GOAL:
					floor_mi.material_override = goal_mat
				elif cell == WFGridMap.Cell.ENCOUNTER:
					floor_mi.material_override = enc_mat
				else:
					floor_mi.material_override = floor_mat
				floor_mi.position = center + Vector3(0, -0.06, 0)
				parent.add_child(floor_mi)

				# ceiling
				var ceil_mi := MeshInstance3D.new()
				var cbox := BoxMesh.new()
				cbox.size = Vector3(cs * 0.98, 0.1, cs * 0.98)
				ceil_mi.mesh = cbox
				ceil_mi.material_override = ceil_mat
				ceil_mi.position = center + Vector3(0, wh, 0)
				parent.add_child(ceil_mi)

	# Dim ambient fill via world environment is set on main scene.
	# Optional border outline lights — skip for perf.


static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	m.metallic = 0.0
	# Compatibility-friendly
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return m
