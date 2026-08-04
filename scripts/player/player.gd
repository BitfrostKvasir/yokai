class_name Player
extends CharacterBody3D

const CAM_FORWARD := Vector3(-0.707, 0.0, -0.707)
const CAM_RIGHT   := Vector3( 0.707, 0.0, -0.707)
const CAMERA_OFFSET := Vector3(10.0, 14.0, 10.0)
const CAMERA_SMOOTH := 8.0
const GRAVITY := 9.8
const COMBO_WINDOW     := 0.5
const COMBO_HITS       := 3
const HEAVY_MULTIPLIER := 2.0
const SP_GAIN_PER_HIT  := 15.0
const ATTACK_RANGE     := 1.8
const KNOCKBACK_FORCE  := 6.0
const DODGE_SPEED     := 12.0
const DODGE_DURATION  := 0.25
const GUARD_REDUCTION := 0.5

var stats: PlayerStats
var is_invincible: bool = false
var camera: Camera3D
var combo_count: int = 0
var combo_timer: float = 0.0
var is_attacking: bool = false
var hold_timer: float = 0.0
var is_dodging: bool = false
var is_guarding: bool = false
var is_stunned: bool = false

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
	if is_stunned:
		velocity.x = 0.0
		velocity.z = 0.0
		return
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
	var final_amount := amount
	if is_guarding:
		final_amount = int(amount * GUARD_REDUCTION)
	stats.take_damage(final_amount)

func _on_weapon_changed(weapon_stats: Dictionary) -> void:
	stats.apply_weapon(weapon_stats)

func _on_died() -> void:
	set_physics_process(false)

func _process(delta: float) -> void:
	if Input.is_action_pressed("attack") and not is_attacking:
		hold_timer += delta
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0

func _unhandled_input(event: InputEvent) -> void:
	if is_stunned:
		return
	if event.is_action_pressed("attack") and not is_attacking:
		hold_timer = 0.0
	if event.is_action_released("attack") and not is_attacking:
		if hold_timer >= 0.4:
			_do_attack(true)
		else:
			_do_attack(false)
	if event.is_action_pressed("special"):
		_do_special()
	if event.is_action_pressed("dodge") and not is_dodging and not is_attacking:
		_do_dodge()
	if event.is_action_pressed("guard"):
		is_guarding = true
	if event.is_action_released("guard"):
		is_guarding = false

func _do_attack(heavy: bool) -> void:
	is_attacking = true
	_face_nearest_enemy()
	var dmg := int(stats.attack * (HEAVY_MULTIPLIER if heavy else 1.0))
	var enemies_hit := _hit_enemies_in_range(dmg, heavy)
	if enemies_hit > 0:
		stats.gain_sp(SP_GAIN_PER_HIT)
	if not heavy:
		combo_count = (combo_count % COMBO_HITS) + 1
		combo_timer = COMBO_WINDOW
	await get_tree().create_timer(0.35 if not heavy else 0.6).timeout
	is_attacking = false

func _face_nearest_enemy() -> void:
	var nearest: Node3D = null
	var nearest_dist := 999.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest:
		var look_pos := nearest.global_position
		look_pos.y = global_position.y
		if global_position.distance_to(look_pos) > 0.001:
			mesh.look_at(look_pos, Vector3.UP)

func _hit_enemies_in_range(damage: int, knockback: bool) -> int:
	var hit_count := 0
	var forward := -mesh.global_transform.basis.z
	for e in get_tree().get_nodes_in_group("enemies"):
		var dist := global_position.distance_to(e.global_position)
		if dist <= ATTACK_RANGE:
			if e.has_method("take_damage"):
				var kb := forward * KNOCKBACK_FORCE if knockback else Vector3.ZERO
				e.take_damage(damage, kb)
				hit_count += 1
	return hit_count

func _do_special() -> void:
	if not stats.use_sp():
		return
	is_attacking = true
	_hit_enemies_in_range(int(stats.attack * 3.0), true)
	await get_tree().create_timer(0.8).timeout
	is_attacking = false

func _do_dodge() -> void:
	is_dodging = true
	is_invincible = true
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (CAM_RIGHT * input_dir.x + CAM_FORWARD * -input_dir.y).normalized()
	if dir.length() < 0.1:
		dir = -mesh.global_transform.basis.z
	velocity.x = dir.x * DODGE_SPEED
	velocity.z = dir.z * DODGE_SPEED
	await get_tree().create_timer(DODGE_DURATION).timeout
	is_dodging = false
	is_invincible = false
