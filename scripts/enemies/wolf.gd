class_name Wolf
extends EnemyBase

enum State { PATROL, AGGRO, ATTACK, COOLDOWN }

const PATROL_SPEED := 2.0
const ATTACK_SPEED := 5.5
const ATTACK_COOLDOWN := 1.2
const COMBO_ATTACKS := 2

var state: State = State.PATROL
var patrol_target: Vector3
var cooldown_timer: float = 0.0
var combo_left: int = 0
var _combo_running: bool = false

func _ready() -> void:
	enemy_type = "wolf"
	max_hp = 25
	attack_damage = 8
	move_speed = ATTACK_SPEED
	super._ready()
	_new_patrol_target()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	match state:
		State.PATROL:   _patrol(delta)
		State.AGGRO:    _aggro(delta)
		State.ATTACK:   _attack_state(delta)
		State.COOLDOWN: _cooldown(delta)
	move_and_slide()

func _patrol(_delta: float) -> void:
	if _get_player_distance() <= aggro_range:
		state = State.AGGRO
		return
	var dir := (patrol_target - global_position)
	dir.y = 0.0
	if dir.length() < 0.5:
		_new_patrol_target()
		return
	var move := dir.normalized() * PATROL_SPEED
	velocity.x = move.x
	velocity.z = move.z

func _aggro(_delta: float) -> void:
	_face_player()
	var dist := _get_player_distance()
	if dist > aggro_range * 1.5:
		state = State.PATROL
		return
	if dist <= attack_range:
		state = State.ATTACK
		combo_left = COMBO_ATTACKS
		return
	if player:
		var dir := (player.global_position - global_position).normalized()
		dir.y = 0.0
		velocity.x = dir.x * ATTACK_SPEED
		velocity.z = dir.z * ATTACK_SPEED

func _attack_state(_delta: float) -> void:
	if _combo_running:
		return
	_combo_running = true
	velocity.x = 0.0
	velocity.z = 0.0
	while combo_left > 0:
		combo_left -= 1
		if player and _get_player_distance() <= attack_range:
			player.take_damage(attack_damage)
		await get_tree().create_timer(0.35).timeout
		if is_dead:
			return
	_combo_running = false
	cooldown_timer = ATTACK_COOLDOWN
	state = State.COOLDOWN

func _cooldown(delta: float) -> void:
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		state = State.AGGRO

func _new_patrol_target() -> void:
	patrol_target = global_position + Vector3(
		randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0)
	)
