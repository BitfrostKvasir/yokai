class_name EnemyBase
extends CharacterBody3D

@export var max_hp: int = 30
@export var attack_damage: int = 8
@export var move_speed: float = 3.0
@export var enemy_type: String = "unknown"
@export var aggro_range: float = 6.0
@export var attack_range: float = 1.5

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
	if current_hp <= 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("enemies")
	GameState.collect_loot(enemy_type)
	died.emit(self)
	queue_free()

func _get_player_distance() -> float:
	if not player:
		return 9999.0
	return global_position.distance_to(player.global_position)

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
