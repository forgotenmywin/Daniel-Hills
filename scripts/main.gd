
extends Node3D

const PlayerScript = preload("res://scripts/player.gd")


func _ready() -> void:
	_build_lighting()
	_build_room()
	_build_furniture()
	_build_player()
	_show_start_message()


func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat


func _box(
	parent: Node3D,
	label: String,
	size: Vector3,
	pos: Vector3,
	mat: Material,
	collision: bool = true
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label

	var mesh := BoxMesh.new()
	mesh.size = size

	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = mat
	parent.add_child(mesh_instance)

	if collision:
		var body := StaticBody3D.new()
		body.name = label + "_Collision"
		body.position = pos

		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape

		body.add_child(shape_node)
		parent.add_child(body)

	return mesh_instance


func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.025, 0.03)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.32, 0.30, 0.28)
	environment.ambient_light_energy = 0.35

	world.environment = environment
	add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -25, 0)
	light.light_energy = 0.45
	light.shadow_enabled = false

	add_child(light)


func _build_room() -> void:
	var floor_mat := _material(Color(0.22, 0.20, 0.18))
	var wall_mat := _material(Color(0.34, 0.32, 0.29))
	var dark_mat := _material(Color(0.12, 0.11, 0.10))

	# Floor
	_box(
		self,
		"Floor",
		Vector3(10, 0.2, 10),
		Vector3(0, -0.1, 0),
		floor_mat
	)

	# Main walls
	_box(
		self,
		"BackWall",
		Vector3(10, 3, 0.2),
		Vector3(0, 1.4, -5),
		wall_mat
	)

	_box(
		self,
		"LeftWall",
		Vector3(0.2, 3, 10),
		Vector3(-5, 1.4, 0),
		wall_mat
	)

	_box(
		self,
		"RightWall",
		Vector3(0.2, 3, 10),
		Vector3(5, 1.4, 0),
		wall_mat
	)

	# Simple ceiling; no collision needed
	_box(
		self,
		"Ceiling",
		Vector3(10, 0.2, 10),
		Vector3(0, 3, 0),
		dark_mat,
		false
	)


func _build_furniture() -> void:
	var wood := _material(Color(0.25, 0.15, 0.09))
	var fabric := _material(Color(0.18, 0.19, 0.20))
	var white := _material(Color(0.58, 0.55, 0.48))
	var tv_screen := _material(Color(0.015, 0.02, 0.025))

	# Table
	_box(
		self,
		"TableTop",
		Vector3(1.5, 0.12, 0.8),
		Vector3(-2.5, 0.85, -2),
		wood
	)

	for x in [-3.1, -1.9]:
		for z in [-2.3, -1.7]:
			_box(
				self,
				"TableLeg",
				Vector3(0.1, 0.8, 0.1),
				Vector3(x, 0.4, z),
				wood
			)

	# Bed
	_box(
		self,
		"BedBase",
		Vector3(2.0, 0.35, 1.1),
		Vector3(2.8, 0.25, -3.3),
		wood
	)

	_box(
		self,
		"BedMattress",
		Vector3(1.95, 0.2, 1.05),
		Vector3(2.8, 0.52, -3.3),
		fabric
	)

	# Fridge
	_box(
		self,
		"Fridge",
		Vector3(0.8, 1.8, 0.7),
		Vector3(-4.0, 0.9, 2.2),
		white
	)

	# TV stand
	_box(
		self,
		"TVStand",
		Vector3(1.5, 0.5, 0.5),
		Vector3(2.8, 0.25, 1.8),
		wood
	)

	# TV screen
	_box(
		self,
		"TVScreen",
		Vector3(1.3, 0.8, 0.12),
		Vector3(2.8, 0.95, 1.8),
		tv_screen
	)

	# Visual door placeholder
	_box(
		self,
		"Door",
		Vector3(1.1, 2.2, 0.12),
		Vector3(0, 1.1, 4.88),
		wood,
		false
	)


func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.15, 1.0)

	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()

	shape.radius = 0.32
	shape.height = 1.65

	capsule.shape = shape
	capsule.position.y = 0.82

	player.add_child(capsule)
	add_child(player)


func _show_start_message() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var label := Label.new()
	label.position = Vector2(12, 10)

	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override(
		"font_color",
		Color(0.9, 0.88, 0.82)
	)

	label.text = (
		"DANIEL HILLS | WASD: Move | Mouse: Look | "
		+ "Space: Jump | E: Interact | Esc: Release mouse"
	)

	layer.add_child(label)
