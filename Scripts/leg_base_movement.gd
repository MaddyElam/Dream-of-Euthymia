extends Node2D

@export var ground_detector : RayCast2D
@export var ground_connector : RayCast2D
@export var default_y : float = 0
var flat_collision_normal := Vector2(0, -1)


func _process(delta: float) -> void:
	if ground_detector.is_colliding() && !ground_connector.is_colliding():
		position.y = move_toward(position.y, ground_detector.get_collision_point().y, delta * 100)
	elif position.y != default_y && ground_detector.get_collision_normal() == flat_collision_normal:
		position.y = move_toward(position.y, default_y, delta * 100)
