class_name LootChest
extends Node3D

var opened: bool = false

@onready var mesh: MeshInstance3D = $Mesh

func open() -> void:
	if opened:
		return
	opened = true
	var tween := create_tween()
	tween.tween_property(mesh, "rotation_degrees:x", -90.0, 0.4)
