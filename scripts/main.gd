
extends Node3D

const ROOM_HALF := 4.0
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.12
const FLOOR_THICKNESS := 0.12

const ROOF_Y := 3.05
const ROOF_THICKNESS := 0.12

# مسیر باز سقف برای عبور پله‌ها
const OPENING_MIN_X := -3.85
const OPENING_MAX_X := -2.80
const OPENING_MIN_Z := -3.85
const OPENING_MAX_Z := 1.20

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


func _box(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	pos: Vector3,
	mat: Material = null,
	collision: bool = true
) -> Node3D:
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
	var trim_mat := _material(Color(0.19, 0.16, 0.13))

	# کف خانه
	_box(
		self, "Floor",
		Vector3(8.0, FLOOR_THICKNESS, 8.0),
		Vector3(0, -FLOOR_THICKNESS / 2.0, 0),
		floor_mat
	)

	# دیوار عقب
	_box(
		self, "BackWall",
		Vector3(8.0, WALL_HEIGHT, WALL_THICKNESS),
		Vector3(0, WALL_HEIGHT / 2.0, -ROOM_HALF),
		wall_mat
	)

	# دیوار جلو
	_box(
		self, "FrontWall",
		Vector3(8.0, WALL_HEIGHT, WALL_THICKNESS),
		Vector3(0, WALL_HEIGHT / 2.0, ROOM_HALF),
		wall_mat
	)

	# دیوار راست
	_box(
		self, "RightWall",
		Vector3(WALL_THICKNESS, WALL_HEIGHT, 8.0),
		Vector3(ROOM_HALF, WALL_HEIGHT / 2.0, 0),
		wall_mat
	)

	# دیوار چپ
	_box(
		self, "LeftWall",
		Vector3(WALL_THICKNESS, WALL_HEIGHT, 8.0),
		Vector3(-ROOM_HALF, WALL_HEIGHT / 2.0, 0),
		wall_mat
	)

	# قرنیزها
	_box(
		self, "BackBaseboard",
		Vector3(7.8, 0.08, 0.04),
		Vector3(0, 0.04, -ROOM_HALF + 0.08),
		trim_mat, false
	)

	_box(
		self, "FrontBaseboard",
		Vector3(7.8, 0.08, 0.04),
		Vector3(0, 0.04, ROOM_HALF - 0.08),
		trim_mat, false
	)


func _build_stairs() -> void:
	var stair_mat := _material(Color(0.34, 0.25, 0.17))

	# پله‌ها در امتداد دیوار سمت چپ قرار می‌گیرند.
	# هر پله با پله قبلی هم‌پوشانی ارتفاعی ندارد.
	var step_count: int = 18
	var step_height: float = ROOF_Y / float(step_count)
	var step_depth: float = 0.25
	var stair_width: float = 0.85

	# فاصله از دیوار چپ
	var stair_x: float = -ROOM_HALF + WALL_THICKNESS + stair_width / 2.0 + 0.03

	# شروع نزدیک گوشه عقب خانه
	var start_z: float = -3.45

	for i in range(step_count):
		var top_height: float = step_height * float(i + 1)

		# هر پله از کف تا ارتفاع خودش امتداد دارد تا سطح آن قابل راه‌رفتن باشد.
		# با این روش پله‌ها پیوسته و بدون شکاف ساخته می‌شوند.
		var step_position := Vector3(
			stair_x,
			top_height / 2.0,
			start_z + float(i) * step_depth
		)

		_box(
			self,
			"StairStep_%02d" % i,
			Vector3(stair_width, top_height, step_depth),
			step_position,
			stair_mat,
			true
		)

	# پاگرد بالایی برای رسیدن به پشت‌بام
	_box(
		self,
		"StairTopLanding",
		Vector3(stair_width + 0.15, 0.14, 0.80),
		Vector3(
			stair_x,
			ROOF_Y - 0.07,
			start_z + float(step_count) * step_depth
		),
		stair_mat,
		true
	)


func _build_rooftop() -> void:
	var roof_mat := _material(Color(0.27, 0.28, 0.30))

	var opening_width: float = OPENING_MAX_X - OPENING_MIN_X
	var left_width: float = OPENING_MIN_X + ROOM_HALF
	var right_width: float = ROOM_HALF - OPENING_MAX_X

	# قسمت چپ پشت‌بام
	_box(
		self, "RoofLeft",
		Vector3(left_width, ROOF_THICKNESS, 8.0),
		Vector3(
			-ROOM_HALF + left_width / 2.0,
			ROOF_Y,
			0
		),
		roof_mat
	)

	# قسمت راست پشت‌بام
	_box(
		self, "RoofRight",
		Vector3(right_width, ROOF_THICKNESS, 8.0),
		Vector3(
			OPENING_MAX_X + right_width / 2.0,
			ROOF_Y,
			0
		),
		roof_mat
	)

	# بخش جلویی سقف، بعد از پایان بازشوی پله‌ها
	_box(
		self, "RoofFront",
		Vector3(opening_width, ROOF_THICKNESS, ROOM_HALF - OPENING_MAX_Z),
		Vector3(
			(OPENING_MIN_X + OPENING_MAX_X) / 2.0,
			ROOF_Y,
			(OPENING_MAX_Z + ROOM_HALF) / 2.0
		),
		roof_mat
	)

	# بخش پشتی سقف، قبل از شروع بازشوی پله‌ها
	_box(
		self, "RoofBack",
		Vector3(opening_width, ROOF_THICKNESS, OPENING_MIN_Z + ROOM_HALF),
		Vector3(
			(OPENING_MIN_X + OPENING_MAX_X) / 2.0,
			ROOF_Y,
			(-ROOM_HALF + OPENING_MIN_Z) / 2.0
		),
		roof_mat
	)


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
	light.position = Vector3(0, 2.55, 0)
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
