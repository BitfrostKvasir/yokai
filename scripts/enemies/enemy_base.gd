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
var _battle_emitted: bool = false
var _hit_light: OmniLight3D

signal died(enemy: EnemyBase)
signal damaged(enemy: EnemyBase)
signal battle_triggered(enemy: EnemyBase)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	_hit_light = OmniLight3D.new()
	_hit_light.light_color = Color(1.0, 0.1, 0.1)
	_hit_light.light_energy = 0.0
	_hit_light.omni_range = 3.0
	add_child(_hit_light)

func _check_battle_trigger() -> bool:
	if GameState.in_battle or _battle_emitted or is_dead:
		return false
	if _get_player_distance() <= aggro_range:
		_battle_emitted = true
		set_physics_process(false)
		battle_triggered.emit(self)
		return true
	return false

func enter_battle_mode() -> void:
	pass  # Overridden by subclasses to immediately aggro

func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	current_hp = max(0, current_hp - amount)
	if knockback.length() > 0.1:
		velocity += knockback
	damaged.emit(self)
	_show_damage_number(amount)
	_flash_hit()
	if current_hp <= 0:
		_die()

func _show_damage_number(amount: int) -> void:
	var label := Label3D.new()
	get_parent().add_child(label)
	label.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 2.0, 0.0)
	label.text = str(amount)
	label.modulate = Color(1.0, 0.9, 0.1)
	label.font_size = 64
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector3(0.0, 1.5, 0.0), 0.8)
	tween.tween_property(label, "modulate", Color(1.0, 0.9, 0.1, 0.0), 0.8)
	tween.finished.connect(label.queue_free)

func _flash_hit() -> void:
	if _hit_light:
		_hit_light.light_energy = 6.0
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and not is_dead and _hit_light:
		_hit_light.light_energy = 0.0

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	if _hit_light:
		_hit_light.light_energy = 0.0
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
