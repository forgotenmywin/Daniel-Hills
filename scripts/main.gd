extends Node3D

# Prototype based on the supplied Blender dimensions.
# Blender Z-up geometry is represented here in Godot's Y-up coordinates.
# A scale factor of 0.1 converts the 80x80 Blender floor into an 8x8 m room.

const ROOM_HALF := 4.0
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.12
const FLOOR_THICKNESS := 0.12

func _ready() -> void:
	_build_room()
	_build_stairs()
	_build_lighting()
	_spawn_player()

func _box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3,
		mat: Material = null, collision: bool = true) -> Node3D:
	var root: Node3D
	if collision:
		var body := StaticBody3D.new()
		body.name = node_name
		body.position = pos
		parent.add_child(body)
		root = body
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
	else:
		var mesh_node := Node3D.new()
		mesh_node.name = node_name
		mesh_node.position = pos
		parent.add_child(mesh_node)
		root = mesh_node

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	if mat != null:
		mesh_instance.material_override = mat
	root.add_child(mesh_instance)
	return root

func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _build_room() -> void:
	var floor_mat := _material(Color(0.30, 0.28, 0.25))
	var wall_mat := _material(Color(0.48, 0.46, 0.42))
	var ceiling_mat := _material(Color(0.22, 0.22, 0.24))
	var trim_mat := _material(Color(0.19, 0.16, 0.13))

	# Floor top is at Y=0. Floor collision prevents falling through.
	_box(self, "Floor", Vector3(8.0, FLOOR_THICKNESS, 8.0),
		Vector3(0, -FLOOR_THICKNESS / 2.0, 0), floor_mat, true)

	# Four walls. The fourth wall is temporary because the Blender script
	# currently only defines three walls.
	_box(self, "BackWall", Vector3(8.0, WALL_HEIGHT, WALL_THICKNESS),
		Vector3(0, WALL_HEIGHT / 2.0, -ROOM_HALF), wall_mat, true)
	_box(self, "FrontWall", Vector3(8.0, WALL_HEIGHT, WALL_THICKNESS),
		Vector3(0, WALL_HEIGHT / 2.0, ROOM_HALF), wall_mat, true)
	_box(self, "RightWall", Vector3(WALL_THICKNESS, WALL_HEIGHT, 8.0),
		Vector3(ROOM_HALF, WALL_HEIGHT / 2.0, 0), wall_mat, true)
	_box(self, "TemporaryFourthWall", Vector3(WALL_THICKNESS, WALL_HEIGHT, 8.0),
		Vector3(-ROOM_HALF, WALL_HEIGHT / 2.0, 0), wall_mat, true)

	# Ceiling is visual only; no collision so it won't obstruct the camera.
	_box(self, "Ceiling", Vector3(8.0, 0.08, 8.0),
		Vector3(0, WALL_HEIGHT + 0.04, 0), ceiling_mat, false)

	# Simple baseboards make wall/floor boundaries easier to read.
	_box(self, "BaseboardBack", Vector3(7.9, 0.08, 0.04),
		Vector3(0, 0.04, -ROOM_HALF + 0.08), trim_mat, false)
	_box(self, "BaseboardFront", Vector3(7.9, 0.08, 0.04),
		Vector3(0, 0.04, ROOM_HALF - 0.08), trim_mat, false)
	_box(self, "BaseboardLeft", Vector3(0.04, 0.08, 7.8),
		Vector3(-ROOM_HALF + 0.08, 0.04, 0), trim_mat, false)
	_box(self, "BaseboardRight", Vector3(0.04, 0.08, 7.8),
		Vector3(ROOM_HALF - 0.08, 0.04, 0), trim_mat, false)

func _build_stairs() -> void:
	# A simple collidable staircase, roughly matching the supplied Blender
	# staircase placement. Every step has its own collision body.
	var stair_mat := _material(Color(0.36, 0.30, 0.24))
	var count := 9
	var start_x := -2.7
	var start_z := -3.2
	var step_width := 0.48
	var step_depth := 0.34
	var step_height := 0.20
	for i in range(count):
		var h := step_height * float(i + 1)
		var step := _box(self, "StairStep_%02d" % i,
			Vector3(step_width, h, step_depth),
			Vector3(start_x + float(i) * 0.34, h / 2.0, start_z + float(i) * 0.34),
			stair_mat, true)
		step.add_to_group("stairs")

func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.32, 0.38)
	env.ambient_light_energy = 0.45
	world.environment = env
	add_child(world)

	var light := OmniLight3D.new()
	light.name = "RoomLight"
	light.position = Vector3(0.0, 2.55, 0.0)
	light.light_energy = 2.0
	light.omni_range = 10.0
	light.shadow_enabled = true
	add_child(light)

func _spawn_player() -> void:
	var player_scene := load("res://scripts/player.gd")
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(player_scene)
	player.position = Vector3(0, 0.0, 0)
	add_child(player)
