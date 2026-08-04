class_name Crow
extends EnemyBase

enum State { FLY, SWOOP, DROP_BOMB, COOLDOWN }

const FLY_HEIGHT := 4.0
const SWOOP_SPEED := 8.0
const COOLDOWN_DURATION := 2.5
const ACTION_INTERVAL := 3.0

var state: State = State.FLY
var state_timer: float = ACTION_INTERVAL
var swoop_target: Vector3 = Vector3.ZERO

@export var projectile_scene: PackedScene

func _ready() -> void:
	enemy_type = "crow"
	max_hp = 20
	attack_damage = 10
	move_speed = 4.0
	aggro_range = 10.0
	super._ready()

func _physics_process(delta: float) -> void:
	state_timer -= delta
	match state:
		State.FLY:       _fly(delta)
		State.SWOOP:     _swoop(delta)
		State.DROP_BOMB: _drop_bomb()
		State.COOLDOWN:  _cooldown(delta)
	move_and_slide()

func _fly(delta: float) -> void:
	if player:
		var target := player.global_position + Vector3(0, FLY_HEIGHT, 0)
		var dir := (target - global_position).normalized()
		velocity = dir * move_speed
	if state_timer <= 0.0 and _get_player_distance() <= aggro_range:
		var action := randi() % 2
		if action == 0:
			state = State.SWOOP
			swoop_target = player.global_position if player else global_position
		else:
			state = State.DROP_BOMB
		state_timer = COOLDOWN_DURATION

func _swoop(_delta: float) -> void:
	var dir := (swoop_target - global_position).normalized()
	velocity = dir * SWOOP_SPEED
	if global_position.distance_to(swoop_target) < 1.0:
		if player and _get_player_distance() <= attack_range + 0.5:
			player.take_damage(attack_damage)
		state = State.COOLDOWN
		state_timer = COOLDOWN_DURATION

func _drop_bomb() -> void:
	if projectile_scene and player:
		var bomb := projectile_scene.instantiate()
		get_parent().add_child(bomb)
		bomb.global_position = global_position
		bomb.set_direction((player.global_position - global_position).normalized())
		bomb.set_damage(attack_damage)
	state = State.COOLDOWN
	state_timer = COOLDOWN_DURATION

func _cooldown(delta: float) -> void:
	if player:
		var target := player.global_position + Vector3(0, FLY_HEIGHT, 0)
		var dir := (target - global_position).normalized()
		velocity = dir * move_speed
	if state_timer <= 0.0:
		state = State.FLY
		state_timer = ACTION_INTERVAL
