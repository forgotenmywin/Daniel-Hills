extends Node3D

# Simple playable house prototype.
# Godot uses Y as the vertical axis.
# Room floor spans 8 x 8 metres, with a roof opening above the staircase.

const ROOM_HALF := 4.0
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.12
const FLOOR_THICKNESS := 0.12

# Roof opening: staircase travels diagonally toward the back-left corner.
const ROOF_Y := 3.05
const ROOF_THICKNESS := 0.12
const OPENING_MIN_X := -3.25
const OPENING_MAX_X := 0.30
const OPENING_MIN_Z := -3.65
const OPENING_MAX_Z := -0.10

func _ready() -> void:
	_build_room()
	_build_stairs()
	_build_rooftop()
	_build_lighting()
	_spawn_player()

func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

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

func _build_room() -> void:
	var floor_mat := _material(Color(0.30, 0.28, 0.25))
	var wall_mat := _material(Color(0.48, 0.46, 0.42))
	var ceiling_mat := _material(Color(0.22, 0.22, 0.24))
	var trim_mat := _material(Color(0.19, 0.16, 0.13))

	_box(self, "Floor", Vector3(8.0, FLOOR_THICKNESS, 8.0),
		Vector3(0, -FLOOR_THICKNESS / 2.0, 0), floor_mat, true)

	_box(self, "BackWall", Vector3(8.0, WALL_HEIGHT, WALL_THICKNESS),
		Vector3(0, WALL_HEIGHT / 2.0, -ROOM_HALF), wall_mat, true)
	_box(self, "FrontWall", Vector3(8.0, WALL_HEIGHT, WALL_THICKNESS),
		Vector3(0, WALL_HEIGHT / 2.0, ROOM_HALF), wall_mat, true)
	_box(self, "RightWall", Vector3(WALL_THICKNESS, WALL_HEIGHT, 8.0),
		Vector3(ROOM_HALF, WALL_HEIGHT / 2.0, 0), wall_mat, true)
	_box(self, "LeftWall", Vector3(WALL_THICKNESS, WALL_HEIGHT, 8.0),
		Vector3(-ROOM_HALF, WALL_HEIGHT / 2.0, 0), wall_mat, true)

	# No solid ceiling across the whole room: the roof pieces are built separately
	# around an opening so the player can climb the stairs onto the rooftop.
	_box(self, "BaseboardBack", Vector3(7.9, 0.08, 0.04),
		Vector3(0, 0.04, -ROOM_HALF + 0.08), trim_mat, false)
	_box(self, "BaseboardFront", Vector3(7.9, 0.08, 0.04),
		Vector3(0, 0.04, ROOM_HALF - 0.08), trim_mat, false)
	_box(self, "BaseboardLeft", Vector3(0.04, 0.08, 7.8),
		Vector3(-ROOM_HALF + 0.08, 0.04, 0), trim_mat, false)
	_box(self, "BaseboardRight", Vector3(0.04, 0.08, 7.8),
		Vector3(ROOM_HALF - 0.08, 0.04, 0), trim_mat, false)

func _build_stairs() -> void:
	var stair_mat := _material(Color(0.36, 0.30, 0.24))
	# Steps rise toward the back-left roof opening.
	var count := 12
	var start_x := -3.15
	var start_z := -3.50
	var step_width := 0.78
	var step_depth := 0.42
	var step_height := ROOF_Y / float(count)

	for i in range(count):
		var h := step_height * float(i + 1)
		var pos := Vector3(
			start_x + float(i) * 0.25,
			h / 2.0,
			start_z + float(i) * 0.25
		)
		_box(self, "StairStep_%02d" % i,
			Vector3(step_width, h, step_depth), pos, stair_mat, true)

	# Small landing at the top of the stairs, level with the rooftop.
	_box(self, "RooftopLanding", Vector3(1.25, 0.16, 1.25),
		Vector3(-0.30, ROOF_Y - 0.08, -0.20), stair_mat, true)

func _build_rooftop() -> void:
	var roof_mat := _material(Color(0.27, 0.28, 0.30))
	var roof_y_center := ROOF_Y
	var thickness := ROOF_THICKNESS

	# Leave a rectangular opening around the staircase. Roof collision is only
	# placed on these four sections, never over the opening.
	var opening_width := OPENING_MAX_X - OPENING_MIN_X
	var opening_depth := OPENING_MAX_Z - OPENING_MIN_Z

	# Left and right roof strips
	var left_width := OPENING_MIN_X + ROOM_HALF
	var right_width := ROOM_HALF - OPENING_MAX_X
	var left_center_x := -ROOM_HALF + left_width / 2.0
	var right_center_x := OPENING_MAX_X + right_width / 2.0
	_box(self, "RoofLeft", Vector3(left_width, thickness, 8.0),
		Vector3(left_center_x, roof_y_center, 0), roof_mat, true)
	_box(self, "RoofRight", Vector3(right_width, thickness, 8.0),
		Vector3(right_center_x, roof_y_center, 0), roof_mat, true)

	# Front/back strips across the opening's X span
	_box(self, "RoofFrontStrip", Vector3(opening_width, thickness, ROOM_HALF - OPENING_MAX_Z),
		Vector3((OPENING_MIN_X + OPENING_MAX_X) / 2.0, roof_y_center,
			(OPENING_MAX_Z + ROOM_HALF) / 2.0), roof_mat, true)
	_box(self, "RoofBackStrip", Vector3(opening_width, thickness, OPENING_MIN_Z + ROOM_HALF),
		Vector3((OPENING_MIN_X + OPENING_MAX_X) / 2.0, roof_y_center,
			(-ROOM_HALF + OPENING_MIN_Z) / 2.0), roof_mat, true)

	# The four roof sections above are both visible and collidable.
	# Intentionally do not add a full-size visual roof panel, because that
	# would cover the stair opening from the player's view.

func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.32, 0.38)
	env.ambient_light_energy = 0.55
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
	var player_script = load("res://scripts/player.gd")
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(player_script)
	player.position = Vector3(1.2, 0.05, 1.2)
	add_child(player)
