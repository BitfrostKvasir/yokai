class_name PlayerStats
extends Resource

@export var max_hp: int = 100
@export var current_hp: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: float = 5.0
@export var sp: float = 0.0
@export var max_sp: float = 100.0

signal hp_changed(current: int, maximum: int)
signal sp_changed(current: float, maximum: float)
signal died

func take_damage(amount: int) -> void:
	var dmg: int = max(1, amount - defense)
	current_hp = max(0, current_hp - dmg)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		died.emit()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func gain_sp(amount: float) -> void:
	sp = min(max_sp, sp + amount)
	sp_changed.emit(sp, max_sp)

func use_sp() -> bool:
	if sp < max_sp:
		return false
	sp = 0.0
	sp_changed.emit(sp, max_sp)
	return true

func is_sp_full() -> bool:
	return sp >= max_sp

func is_dead() -> bool:
	return current_hp <= 0

func apply_weapon(weapon_stats: Dictionary) -> void:
	attack = int(weapon_stats.get("attack", attack))
	defense = int(weapon_stats.get("defense", defense))
	speed = float(weapon_stats.get("speed", speed))
