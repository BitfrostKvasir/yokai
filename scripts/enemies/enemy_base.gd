class_name EnemyBase
extends CharacterBody3D

@export var max_hp: int = 30
@export var attack_damage: int = 8
@export var move_speed: float = 3.0
@export var enemy_type: String = "unknown"
@export var aggro_range: float = 6.0
@export var attack_range: float = 2.0

var current_hp: int
var is_dead: bool = false
var player: Player

signal died(enemy: EnemyBase)
signal damaged(enemy: EnemyBase)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	current_hp = max(0, current_hp - amount)
	if knockback.length() > 0.1:
		velocity += knockback
	damaged.emit(self)
	_flash_hit()
	if current_hp <= 0:
		_die()

func _flash_hit() -> void:
	modulate = Color(2.0, 0.3, 0.3, 1.0)
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and not is_dead:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	remove_from_group("enemies")
	GameState.collect_loot(enemy_type)
	died.emit(self)
	queue_free()

func _get_player_distance() -> float:
	if not player:
		return 9999.0
	# XZ only — ignore height difference so attacks work on flat ground
	var self_xz := Vector2(global_position.x, global_position.z)
	var player_xz := Vector2(player.global_position.x, player.global_position.z)
	return self_xz.distance_to(player_xz)

func _face_player() -> void:
	if not player:
		return
	var look_pos := player.global_position
	look_pos.y = global_position.y
	if global_position.distance_to(look_pos) > 0.001:
		look_at(look_pos, Vector3.UP)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
