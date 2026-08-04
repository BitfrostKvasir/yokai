class_name Boar
extends EnemyBase

enum State { PATROL, TELEGRAPH, CHARGE, STUN, COOLDOWN }

const TELEGRAPH_DURATION := 1.0
const CHARGE_SPEED := 10.0
const CHARGE_DURATION := 0.6
const STUN_DURATION := 1.5
const COOLDOWN_DURATION := 2.0

var state: State = State.PATROL
var state_timer: float = 0.0
var charge_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	enemy_type = "boar"
	max_hp = 50
	attack_damage = 14
	move_speed = 2.5
	aggro_range = 7.0
	super._ready()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	state_timer -= delta
	match state:
		State.PATROL:    _patrol()
		State.TELEGRAPH: _telegraph()
		State.CHARGE:    _charge()
		State.STUN:      _stun()
		State.COOLDOWN:  _cooldown()
	move_and_slide()

func _patrol() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _get_player_distance() <= aggro_range:
		_face_player()
		state = State.TELEGRAPH
		state_timer = TELEGRAPH_DURATION

func _telegraph() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_face_player()
	if state_timer <= 0.0:
		if player:
			charge_direction = (player.global_position - global_position).normalized()
			charge_direction.y = 0.0
		state = State.CHARGE
		state_timer = CHARGE_DURATION

func _charge() -> void:
	velocity.x = charge_direction.x * CHARGE_SPEED
	velocity.z = charge_direction.z * CHARGE_SPEED
	if player and _get_player_distance() <= attack_range + 0.5:
		player.take_damage(attack_damage)
		state = State.COOLDOWN
		state_timer = COOLDOWN_DURATION
		return
	if state_timer <= 0.0:
		state = State.STUN
		state_timer = STUN_DURATION
		velocity.x = 0.0
		velocity.z = 0.0

func _stun() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if state_timer <= 0.0:
		state = State.PATROL

func _cooldown() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if state_timer <= 0.0:
		state = State.PATROL
