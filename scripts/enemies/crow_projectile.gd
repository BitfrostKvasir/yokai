class_name CrowProjectile
extends Area3D

const SPEED := 6.0
const DAMAGE := 10
var direction: Vector3 = Vector3.DOWN
var lifetime: float = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_direction(dir: Vector3) -> void:
	direction = dir.normalized()

func _process(delta: float) -> void:
	global_position += direction * SPEED * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(DAMAGE)
	queue_free()
