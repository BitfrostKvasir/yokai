class_name BearBoss
extends EnemyBase

enum State { IDLE, SWIPE, GROUND_POUND, ROAR, CHARGE, DEAD }

const PHASE2_THRESHOLD := 0.5
const SWIPE_DAMAGE := 18
const POUND_DAMAGE := 22
const POUND_RADIUS := 3.0
const ROAR_STUN := 1.5
const CHARGE_SPEED := 9.0
const CHARGE_DURATION := 0.8
const ACTION_INTERVAL_P1 := 2.5
const ACTION_INTERVAL_P2 := 1.8
const SUMMON_INTERVAL := 12.0

var phase: int = 1
var state: State = State.IDLE
var action_timer: float = 2.0
var summon_timer: float = SUMMON_INTERVAL
var charge_dir: Vector3 = Vector3.ZERO
var charge_timer: float = 0.0

@export var wolf_scene: PackedScene

signal phase_changed(new_phase: int)
signal bear_killed

func _ready() -> void:
	enemy_type = "bear"
	max_hp = 400
	attack_damage = SWIPE_DAMAGE
	move_speed = 2.0
	aggro_range = 15.0
	super._ready()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if is_dead:
		return
	_check_phase_transition()
	action_timer -= delta
	if phase == 2 and state == State.IDLE:
		summon_timer -= delta
		if summon_timer <= 0.0:
			summon_timer = SUMMON_INTERVAL
			_summon_wolves()
	match state:
		State.IDLE:   _idle(delta)
		State.CHARGE: _do_charge(delta)
	move_and_slide()

func _idle(_delta: float) -> void:
	_face_player()
	if player:
		var dir := (player.global_position - global_position)
		dir.y = 0.0
		if dir.length() > attack_range:
			var move := dir.normalized() * move_speed
			velocity.x = move.x
			velocity.z = move.z
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	if action_timer <= 0.0:
		_choose_action()

func _choose_action() -> void:
	var interval := ACTION_INTERVAL_P2 if phase == 2 else ACTION_INTERVAL_P1
	action_timer = interval
	var actions := [State.SWIPE, State.GROUND_POUND, State.ROAR]
	if phase == 2:
		actions.append(State.CHARGE)
	var chosen: State = actions[randi() % actions.size()]
	state = chosen
	_execute_action(chosen)

func _execute_action(action: State) -> void:
	match action:
		State.SWIPE:
			await get_tree().create_timer(0.3).timeout
			if player and _get_player_distance() <= attack_range + 0.5:
				player.take_damage(SWIPE_DAMAGE)
			state = State.IDLE
		State.GROUND_POUND:
			velocity.x = 0.0
			velocity.z = 0.0
			await get_tree().create_timer(0.6).timeout
			if player and _get_player_distance() <= POUND_RADIUS:
				player.take_damage(POUND_DAMAGE)
			state = State.IDLE
		State.ROAR:
			velocity.x = 0.0
			velocity.z = 0.0
			await get_tree().create_timer(0.5).timeout
			if player and _get_player_distance() <= 8.0:
				player.is_invincible = true
				await get_tree().create_timer(ROAR_STUN).timeout
				player.is_invincible = false
			state = State.IDLE
		State.CHARGE:
			if player:
				charge_dir = (player.global_position - global_position).normalized()
				charge_dir.y = 0.0
			charge_timer = CHARGE_DURATION
			state = State.CHARGE

func _do_charge(delta: float) -> void:
	velocity.x = charge_dir.x * CHARGE_SPEED
	velocity.z = charge_dir.z * CHARGE_SPEED
	charge_timer -= delta
	if player and _get_player_distance() <= attack_range:
		player.take_damage(SWIPE_DAMAGE)
		state = State.IDLE
	elif charge_timer <= 0.0:
		state = State.IDLE

func _check_phase_transition() -> void:
	if phase == 1 and float(current_hp) / float(max_hp) <= PHASE2_THRESHOLD:
		phase = 2
		move_speed = 3.5
		phase_changed.emit(2)

func _die() -> void:
	is_dead = true
	remove_from_group("enemies")
	GameState.on_bear_defeated()
	GameState.collect_loot("bear")
	bear_killed.emit()
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _summon_wolves() -> void:
	if not wolf_scene:
		return
	for i in 2:
		var w := wolf_scene.instantiate()
		get_parent().add_child(w)
		w.global_position = global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
