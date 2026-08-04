class_name Player
extends CharacterBody3D

const CAM_FORWARD := Vector3(-0.707, 0.0, -0.707)
const CAM_RIGHT   := Vector3( 0.707, 0.0, -0.707)
const CAMERA_OFFSET := Vector3(10.0, 14.0, 10.0)
const CAMERA_SMOOTH := 8.0
const GRAVITY := 9.8

var stats: PlayerStats
var is_invincible: bool = false
var camera: Camera3D

@onready var mesh: Node3D = $Mesh

func _ready() -> void:
	stats = PlayerStats.new()
	stats.apply_weapon(GameState.current_weapon_stats)
	GameState.weapon_changed.connect(_on_weapon_changed)
	stats.died.connect(_on_died)
	add_to_group("player")
	# Find camera in parent scene
	await get_tree().process_frame
	camera = get_tree().get_first_node_in_group("main_camera")

func _physics_process(delta: float) -> void:
	_camera_follow(delta)
	_handle_gravity(delta)
	_handle_movement()
	move_and_slide()

func _camera_follow(delta: float) -> void:
	if not camera:
		return
	var target_pos := global_position + CAMERA_OFFSET
	camera.global_position = camera.global_position.lerp(target_pos, CAMERA_SMOOTH * delta)
	camera.look_at(global_position, Vector3.UP)

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func _handle_movement() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (CAM_RIGHT * input_dir.x + CAM_FORWARD * -input_dir.y)
	var spd := stats.speed
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * spd
		velocity.z = direction.z * spd
		var look_pos := global_position + direction
		look_pos.y = global_position.y
		mesh.look_at(look_pos, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, spd)
		velocity.z = move_toward(velocity.z, 0.0, spd)

func take_damage(amount: int, _from_direction: Vector3 = Vector3.ZERO) -> void:
	if is_invincible:
		return
	stats.take_damage(amount)

func _on_weapon_changed(weapon_stats: Dictionary) -> void:
	stats.apply_weapon(weapon_stats)

func _on_died() -> void:
	set_physics_process(false)
