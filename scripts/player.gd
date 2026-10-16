extends CharacterBody3D

const WALK_SPEED := 4.0
const JUMP_VELOCITY := 4.0
const MOUSE_SENSITIVITY := 0.0022

var gravity: float = 9.8
var camera: Camera3D
var prompt_label: Label
var near_interactable := false

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    camera = Camera3D.new()
    camera.position = Vector3(0, 0.62, 0)
    camera.current = true
    add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if event.is_action_pressed("interact") and near_interactable:
        print("Interaction placeholder: add Daniel's actions here.")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
        velocity.x = direction.x * WALK_SPEED
        velocity.z = direction.z * WALK_SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED)
        velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED)
    move_and_slide()
